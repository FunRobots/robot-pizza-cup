"""Fine-tune a LeRobot policy and optionally upload the checkpoint to S3."""

from __future__ import annotations

import os
import subprocess
import sys
from datetime import UTC, datetime
from pathlib import Path
from typing import Literal

import typer
from pydantic import BaseModel, Field, ValidationError, field_validator
from rich.console import Console
from rich.panel import Panel
from rich.table import Table

try:
    import boto3
    from botocore.config import Config as BotoConfig

    _BOTO3_AVAILABLE = True
except ImportError:
    _BOTO3_AVAILABLE = False

console = Console(force_terminal=True)
app = typer.Typer(add_completion=False, no_args_is_help=True)

PolicyName = Literal["act", "diffusion", "smolvla", "pi0", "pi05"]


class TrainConfig(BaseModel):
    policy: PolicyName = "act"
    dataset: str = Field(default="lerobot/pusht", min_length=1)
    env: str | None = None
    steps: int = Field(default=5000, gt=0)
    batch_size: int = Field(default=8, gt=0)
    eval_episodes: int = Field(default=0, ge=0)
    output_dir: Path | None = None
    pretrained_path: str | None = None

    @property
    def dataset_slug(self) -> str:
        return self.dataset.replace("/", "-")


class S3Config(BaseModel):
    bucket: str
    prefix: str = "pizza-robo-hack"
    endpoint_url: str | None = None
    region: str = "eu-north1"
    access_key: str
    secret_key: str

    @field_validator("prefix")
    @classmethod
    def _normalize_prefix(cls, value: str) -> str:
        return value.rstrip("/")

    @classmethod
    def from_env(cls) -> S3Config | None:
        access_key = os.environ.get("AWS_ACCESS_KEY_ID")
        secret_key = os.environ.get("AWS_SECRET_ACCESS_KEY")
        bucket = os.environ.get("S3_BUCKET")
        if not all([access_key, secret_key, bucket]):
            return None
        return cls(
            bucket=bucket,
            prefix=os.environ.get("S3_PREFIX", "pizza-robo-hack"),
            endpoint_url=os.environ.get("S3_ENDPOINT_URL"),
            region=os.environ.get("AWS_DEFAULT_REGION", "eu-north1"),
            access_key=access_key,
            secret_key=secret_key,
        )


def _detect_device() -> str:
    if os.environ.get("TRAIN_DEVICE"):
        return os.environ["TRAIN_DEVICE"]
    try:
        import torch

        if torch.cuda.is_available():
            return "cuda"
        if torch.backends.mps.is_available():
            return "mps"
    except ImportError:
        pass
    return "cpu"


def _build_train_cmd(
    cfg: TrainConfig,
    output_dir: Path,
    *,
    job_name: str | None = None,
    wandb_project: str | None = None,
    wandb_entity: str | None = None,
) -> list[str]:
    venv_bin = Path(sys.executable).parent
    lerobot_train = venv_bin / "lerobot-train"
    if lerobot_train.is_file():
        base: list[str] = [str(lerobot_train)]
    else:
        base = [sys.executable, "-m", "lerobot.scripts.lerobot_train"]

    wandb_on = bool(os.environ.get("WANDB_API_KEY"))
    device = _detect_device()
    flags: list[str] = [
        f"--policy.type={cfg.policy}",
        "--policy.push_to_hub=false",
        f"--policy.device={device}",
        f"--dataset.repo_id={cfg.dataset}",
        f"--steps={cfg.steps}",
        f"--batch_size={cfg.batch_size}",
        f"--output_dir={output_dir}",
        f"--wandb.enable={'true' if wandb_on else 'false'}",
    ]
    if cfg.pretrained_path:
        flags.append(f"--policy.path={cfg.pretrained_path}")
    elif cfg.policy == "smolvla":
        flags.append("--policy.path=lerobot/smolvla_base")
        flags.append("--policy.freeze_vision_encoder=false")
        flags.append("--policy.train_expert_only=false")
    if cfg.env:
        flags.append(f"--env.type={cfg.env}")
    if cfg.eval_episodes > 0 and cfg.env:
        flags.append(f"--eval.n_episodes={cfg.eval_episodes}")
    if wandb_on:
        if job_name:
            flags.append(f"--job_name={job_name}")
        if wandb_project:
            flags.append(f"--wandb.project={wandb_project}")
        if wandb_entity:
            flags.append(f"--wandb.entity={wandb_entity}")
    return base + flags


def _make_s3_client(cfg: S3Config | None):
    if cfg is None:
        console.print("[yellow]S3 upload skipped — missing env vars.[/yellow]")
        return None
    if not _BOTO3_AVAILABLE:
        console.print("[yellow]boto3 not installed — S3 upload skipped.[/yellow]")
        return None
    return boto3.client(
        "s3",
        aws_access_key_id=cfg.access_key,
        aws_secret_access_key=cfg.secret_key,
        region_name=cfg.region,
        endpoint_url=cfg.endpoint_url,
        config=BotoConfig(region_name=cfg.region),
    )


def _upload_checkpoint(output_dir: Path, cfg: S3Config | None) -> bool:
    client = _make_s3_client(cfg)
    if client is None:
        return False
    try:
        client.head_bucket(Bucket=cfg.bucket)
    except Exception as exc:
        console.print(f"[yellow]Cannot access bucket '{cfg.bucket}': {exc}[/yellow]")
        return False

    files = [p for p in output_dir.rglob("*") if p.is_file()]
    console.print(
        f"\nUploading {len(files)} files to s3://{cfg.bucket}/{cfg.prefix}/{output_dir.name}/"
    )
    for local_path in files:
        key = f"{cfg.prefix}/{output_dir.name}/{local_path.relative_to(output_dir).as_posix()}"
        client.upload_file(str(local_path), cfg.bucket, key)
        console.print(f"  {local_path.relative_to(output_dir)}")

    s3_path = f"s3://{cfg.bucket}/{cfg.prefix}/{output_dir.name}/"
    console.print(f"\nCheckpoint saved to {s3_path}")
    return True


def _print_summary(cfg: TrainConfig, output_dir: Path, s3_cfg: S3Config | None) -> None:
    table = Table(show_header=False, box=None, pad_edge=False)
    table.add_row("Policy", cfg.policy)
    table.add_row("Dataset", cfg.dataset)
    table.add_row("Steps", str(cfg.steps))
    table.add_row("Batch size", str(cfg.batch_size))
    table.add_row("Device", _detect_device())
    if cfg.env:
        table.add_row("Env", cfg.env)
    table.add_row("Output", str(output_dir))
    if s3_cfg:
        table.add_row("S3 bucket", s3_cfg.bucket)
        table.add_row("S3 prefix", s3_cfg.prefix)
    console.print(Panel(table, title="LeRobot Fine-tuning Job", expand=False))


@app.command()
def main(
    policy: PolicyName = typer.Option("act", "--policy", help="Policy architecture."),
    dataset: str = typer.Option("lerobot/pusht", "--dataset", help="HuggingFace dataset repo_id."),
    env: str | None = typer.Option(None, "--env", help="Optional env for in-training eval."),
    steps: int = typer.Option(5000, "--steps", help="Offline training steps.", min=1),
    batch_size: int = typer.Option(8, "--batch-size", help="Batch size per device.", min=1),
    eval_episodes: int = typer.Option(
        0, "--eval-episodes", help="Eval episodes (needs --env).", min=0
    ),
    output_dir: Path | None = typer.Option(None, "--output-dir", help="Checkpoint directory."),
    pretrained_path: str | None = typer.Option(
        None, "--pretrained-path", help="Override --policy.path (e.g. lerobot/smolvla_base)."
    ),
    label: str | None = typer.Option(None, "--label", help="Optional run-name suffix."),
    wandb_project: str | None = typer.Option(None, "--wandb-project"),
    wandb_entity: str | None = typer.Option(None, "--wandb-entity"),
) -> None:
    try:
        cfg = TrainConfig(
            policy=policy,
            dataset=dataset,
            env=env,
            steps=steps,
            batch_size=batch_size,
            eval_episodes=eval_episodes,
            output_dir=output_dir,
            pretrained_path=pretrained_path,
        )
    except ValidationError as exc:
        console.print(f"[red]Invalid input:[/red] {exc}")
        raise typer.Exit(code=1) from exc

    hf_token = os.environ.get("HF_TOKEN")
    if hf_token:
        os.environ["HUGGING_FACE_HUB_TOKEN"] = hf_token

    run_id = datetime.now(tz=UTC).strftime("%Y%m%dT%H%M%S")
    base_run_name = f"lerobot-{cfg.policy}-{cfg.dataset_slug}-{run_id}"
    run_name = f"{base_run_name}-{label}" if label else base_run_name
    target_dir = cfg.output_dir if cfg.output_dir else Path("outputs") / "train" / run_name
    target_dir.parent.mkdir(parents=True, exist_ok=True)

    s3_cfg = S3Config.from_env()
    _print_summary(cfg, target_dir, s3_cfg)

    wandb_project = wandb_project or os.environ.get("WANDB_PROJECT")
    wandb_entity = wandb_entity or os.environ.get("WANDB_ENTITY")
    cmd = _build_train_cmd(
        cfg,
        target_dir,
        job_name=run_name,
        wandb_project=wandb_project,
        wandb_entity=wandb_entity,
    )
    console.print(f"[cyan]Running:[/cyan] {' '.join(cmd)}")
    result = subprocess.run(cmd, text=True, check=False)
    if result.returncode != 0:
        console.print(f"[red]Training failed (exit {result.returncode}).[/red]")
        raise typer.Exit(code=result.returncode)

    if _upload_checkpoint(target_dir, s3_cfg):
        console.print("[green]S3 upload complete.[/green]")
    else:
        console.print("[yellow]S3 upload skipped.[/yellow]")


if __name__ == "__main__":
    app()
