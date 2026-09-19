# CUDA runtime for cloud / Docker training.
# Local robot work uses `uv sync` on the host, not this image.
# Follows https://huggingface.co/docs/lerobot/installation (uv path).
FROM nvidia/cuda:12.6.3-cudnn-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    cmake \
    build-essential \
    python3-dev \
    pkg-config \
    git \
    ffmpeg \
    libevdev-dev \
    libavformat-dev \
    libavcodec-dev \
    libavdevice-dev \
    libavutil-dev \
    libswscale-dev \
    libswresample-dev \
    libavfilter-dev \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    curl \
    unzip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip && \
    unzip /tmp/awscliv2.zip -d /tmp && \
    /tmp/aws/install && \
    rm -rf /tmp/awscliv2.zip /tmp/aws

RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH"

WORKDIR /lerobot
RUN mkdir -p outputs

COPY pyproject.toml ./
COPY training/ ./training/

ENV UV_INDEX_STRATEGY=unsafe-best-match
ENV UV_EXTRA_INDEX_URL=https://download.pytorch.org/whl/cu128
ENV TRAIN_DEVICE=cuda

RUN uv python install 3.12 && uv venv --python 3.12 .venv
ENV VIRTUAL_ENV=/lerobot/.venv
ENV PATH="/lerobot/.venv/bin:$PATH"

RUN uv sync --no-dev --python 3.12 --index-strategy unsafe-best-match

ENTRYPOINT ["python", "-m", "training.run"]
