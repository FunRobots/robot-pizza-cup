# SO-101 — DevLab (recommended GPU environment)

Interactive GPU workspace for dataset checks, fine-tuning, and a checkpoint check. A JupyterLab DevLab is the recommended place to run that work. A short CPU smoke still runs on a laptop ([Train on CPU](train-and-deploy.md#cpu-training)), and an unattended run can be a [Job](train-and-deploy.md#cloud-training).

The arm stays on the laptop (USB). Record and teleop stay there. This page is commands in a **JupyterLab terminal** or a **notebook** on the DevLab.

Default GPU is **RTX PRO 6000**. L40S and H100 are the closest alternatives when that platform is not in the project. Preset must match the platform ([platforms](https://docs.nebius.com/compute/virtual-machines/types)):

| GPU | Platform | 1-GPU preset | Regions |
| --- | --- | --- | --- |
| RTX PRO 6000 (default) | `gpu-rtx6000-a` | `1gpu-24vcpu-218gb` | `uk-south2`, `eu-south1` |
| RTX PRO 6000 | `gpu-rtx6000` | `1gpu-24vcpu-218gb` | `us-central1` |
| L40S | `gpu-l40s-a` | `1gpu-24vcpu-96gb` | `eu-north1` |
| H100 | `gpu-h100-sxm` | `1gpu-16vcpu-200gb` | `eu-north1` |

`gpu-l40s-d` in `eu-north1` uses `1gpu-16vcpu-96gb`, not the `gpu-l40s-a` preset.

## Access

Accept the Nebius invitation for your team project. Example console names from the hackathon invite: tenant `gtc-berlin-2026-hackathon-68a`, project `group09-project`. Do not attach a credit card. Use the project for hackathon work.

## Create a DevLab

1. Nebius Console → **Serverless AI → Devlabs** → **Create Devlab**.
2. Template: **JupyterLab**.
3. Platform: **RTX PRO 6000** when the project lists it. Otherwise pick **L40S** or **H100** from the table above.
4. Container disk size: **500 GiB**.
5. Save the generated access token, then create the DevLab.

When status is **Running**, open the DevLab HTTPS address and sign in. Launcher → **Terminal**.

```bash
nvidia-smi
python --version
```

Stop the DevLab in the console when you are not using it.

## Install this repo

Image Python is `/usr/bin/python3.12` and has no `Python.h`. LeRobot on Linux builds `evdev` from source, so `uv` must use its own CPython 3.13. Same steps as [SO-101 setup](../README.md#1-install-local-uv-environment):

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
source "$HOME/.local/bin/env"
git clone <YOUR_FORK_OR_REPO_URL> pizza-robo-hack
cd pizza-robo-hack/so101
unset UV_PYTHON
rm -rf .venv
uv python install 3.13
uv sync --managed-python --python 3.13
uv run hf auth login
```

Create `.env` from the DevLab template, in this terminal, from the repo root. Do not save it from the Jupyter file browser: that writes `/.env`, which the container cannot create.

```bash
cd ~/pizza-robo-hack
cp .env-devlab.example .env
```

Open `.env` in the terminal and fill `WANDB_API_KEY`. Fill `HF_TOKEN` (or `HUGGING_FACE_HUB_TOKEN`) if `hf auth login` above was skipped. `WANDB_ENTITY` is optional. The fine-tune dataset is already `robotpizzacup/robot-pizza-cup-1`.

```bash
nano .env
```

The sync log must name an interpreter under `~/.local/share/uv/python`. Then, from `so101`, check CUDA and run a 20-step smoke test on the 40-episode pizza sample:

```bash
cd ~/pizza-robo-hack/so101
uv run python -c "import torch; print(torch.cuda.is_available(), torch.cuda.get_device_name(0))"
bash training/scripts/train_local.sh act robotpizzacup/robot-pizza-cup-1-ep0-39 20
```

A notebook uses the same venv.

## Fine-tune

From `so101`, on the DevLab. Checkpoints land under `outputs/train/` on the container disk. Steps and batch size come from the policy YAML (ACT 30k / 16, SmolVLA 60k / 16, diffusion 60k / 32).

```bash
cd so101
set -a && source ../.env && set +a

uv run lerobot-train \
  --config_path=training/policy/act/config.yaml \
  --policy.device=cuda \
  --policy.push_to_hub=false \
  --dataset.repo_id=robotpizzacup/robot-pizza-cup-1
```

To push the final checkpoint to Hugging Face Hub at the end of training, pass both `--policy.push_to_hub=true` and `--policy.repo_id` (LeRobot requires `--policy.repo_id` whenever `push_to_hub=true`):

```bash
uv run lerobot-train \
  --config_path=training/policy/act/config.yaml \
  --policy.device=cuda \
  --policy.push_to_hub=true \
  --policy.type=act \
  --policy.repo_id="${HF_USER}/pizza-act" \
  --dataset.repo_id=robotpizzacup/robot-pizza-cup-1
```

SmolVLA: pass `--config_path=training/policy/smolvla/config.yaml --policy.type=smolvla --dataset.repo_id=robotpizzacup/robot-pizza-cup-1` (`--policy.type=smolvla` is required when overriding `--policy.*` flags on the CLI).

After the run:

```bash
uv run python -m training.eval \
  outputs/train/<run>/checkpoints/last/pretrained_model
```

That command checks `config.json` and `model.safetensors` are present. It does not score the arm. Physical scoring is the 10-episode rollout in [Train and deploy](train-and-deploy.md#evaluation), on the laptop, from a Hub checkpoint or a copied `pretrained_model` directory.

## Policy server on the DevLab (optional)

Use this when the policy should run on the DevLab GPU while the laptop holds the arm. A small ACT policy can skip this and run `bash scripts/rollout.sh <hub-or-local-checkpoint>` on the laptop.

```text
Laptop client -- WSS + Jupyter token --> Jupyter Server Proxy (:8888)
                                         /proxy/8000/
                                              |
                                    Policy server 127.0.0.1:8000
                                              |
                                             GPU
```

This repo does not ship a policy-server command. Start the server your framework documents, on port **8000**, bound to `127.0.0.1` when it allows that. Leave that terminal open.

```bash
ss -ltn | grep 8000
curl -i http://127.0.0.1:8000/healthz
```

Replace `/healthz` with the route your server actually exposes.

Install Jupyter Server Proxy into **Jupyter’s** Python, not the LeRobot venv. On the current DevLab image that interpreter is `/opt/conda/bin/python`:

```bash
ps -ef | grep '[j]upyter'
/opt/conda/bin/python -m pip install jupyter-server-proxy
jupyter server extension enable jupyter_server_proxy --user
jupyter server extension list
```

`jupyter_server_proxy` should show as enabled. Restart the DevLab from the Nebius Console so the route loads. Save notebooks first; keep files on the container disk. Start the policy server again after the restart.

In the browser where you are signed in to Jupyter, open:

```text
https://YOUR-NEBIUS-HOST/proxy/8000/healthz
```

`YOUR-NEBIUS-HOST` is the host in the JupyterLab URL (`…/lab` removed). The `/proxy/8000/` prefix selects the port.

On the laptop, Jupyter’s browser login is not shared with Python. Read the token from the DevLab (`jupyter server list` when token auth is on). Keep it out of git, screenshots, and logged URLs.

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip websockets
read -rsp "Jupyter token: " JUPYTER_TOKEN; echo
export JUPYTER_TOKEN
```

`test_connection.py` (handshake only):

```python
import os
from urllib.parse import quote

from websockets.sync.client import connect

base = "wss://YOUR-NEBIUS-HOST/proxy/8000/"
token = quote(os.environ["JUPYTER_TOKEN"], safe="")
url = f"{base}?token={token}"
with connect(url, open_timeout=15):
    print("WebSocket connected")
```

An HTTP policy server uses `https://YOUR-NEBIUS-HOST/proxy/8000/` with the same token query. Measure latency with your framework’s client after a few untimed warm-up calls. Do not send actions to the arm until the action format and safety checks are validated.

After a DevLab restart: open JupyterLab, `nvidia-smi`, start the policy server on port 8000, confirm the proxy health URL, export the token, then run the WebSocket test. Reinstall the proxy only if the image was rebuilt.
