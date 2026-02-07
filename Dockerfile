# =============================================================================
# ComfyUI + Trellis2 — RunPod Template (SM 12.0 / Blackwell / RTX 5090)
# PyTorch 2.10 + CUDA 12.8 + Python 3.12
# =============================================================================
FROM nvidia/cuda:12.8.1-devel-ubuntu22.04

LABEL maintainer="comfyui-trellis2-runpod"
LABEL description="ComfyUI with Trellis2 (visualbruno) - SM 12.0 Blackwell ready"

# --------------------------------------------------------------------------
# Environment
# --------------------------------------------------------------------------
ENV DEBIAN_FRONTEND=noninteractive \
    SHELL=/bin/bash \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    TORCH_CUDA_ARCH_LIST="12.0" \
    ATTN_BACKEND=sdpa \
    NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility,graphics \
    CUDA_HOME=/usr/local/cuda

# --------------------------------------------------------------------------
# System packages
# --------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl wget openssh-server \
    build-essential cmake ninja-build \
    libegl1-mesa-dev libgles2-mesa-dev libgl1-mesa-dev \
    libeigen3-dev \
    libglib2.0-0 libsm6 libxrender1 libxext6 libfontconfig1 \
    ffmpeg \
    ca-certificates \
    libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev \
    libffi-dev liblzma-dev tk-dev uuid-dev \
    && rm -rf /var/lib/apt/lists/*

# --------------------------------------------------------------------------
# Python 3.12 (build from source on Ubuntu 22.04)
# --------------------------------------------------------------------------
ARG PYTHON_VERSION=3.12.8
RUN set -eux; \
    curl -fsSL https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz -o /tmp/Python.tgz; \
    tar -xzf /tmp/Python.tgz -C /tmp; \
    cd /tmp/Python-${PYTHON_VERSION}; \
    ./configure --enable-optimizations --with-ensurepip=install; \
    make -j"$(nproc)"; \
    make altinstall; \
    ln -sf /usr/local/bin/python3.12 /usr/bin/python3; \
    ln -sf /usr/bin/python3 /usr/bin/python; \
    /usr/local/bin/python3.12 -m pip install --upgrade pip setuptools wheel; \
    cd /; \
    rm -rf /tmp/Python-${PYTHON_VERSION} /tmp/Python.tgz

# FileBrowser (apt package not available on jammy)
RUN curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash

# --------------------------------------------------------------------------
# Pip basics + PyTorch 2.10 cu128
# --------------------------------------------------------------------------
RUN pip install --upgrade pip setuptools wheel && \
    pip install torch==2.10.0+cu128 torchvision==0.25.0+cu128 torchaudio==2.10.0+cu128 \
    --index-url https://download.pytorch.org/whl/cu128

# --------------------------------------------------------------------------
# CUDA symlinks (pip-installed CUDA libs → system paths for compilation)
# --------------------------------------------------------------------------
RUN CUDA_SITE=$(python3 -c "import nvidia.cuda_runtime; import os; print(os.path.dirname(nvidia.cuda_runtime.__file__))") && \
    CUDA_INC=$(dirname $CUDA_SITE)/cuda_runtime/include && \
    CUDA_LIB=$(dirname $CUDA_SITE)/cuda_runtime/lib && \
    find $(dirname $CUDA_SITE) -name "*.h" -path "*/include/*" -exec dirname {} \; | sort -u | while read d; do \
        ln -sf "$d"/*.h /usr/local/cuda/include/ 2>/dev/null || true; \
    done && \
    find $(dirname $CUDA_SITE) -name "*.so*" -path "*/lib/*" | while read f; do \
        ln -sf "$f" /usr/local/cuda/lib64/ 2>/dev/null || true; \
    done && \
    ldconfig

# --------------------------------------------------------------------------
# Clone ComfyUI + custom nodes
# --------------------------------------------------------------------------
WORKDIR /workspace/runpod-slim
RUN git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git && \
    cd ComfyUI && pip install -r requirements.txt

WORKDIR /workspace/runpod-slim/ComfyUI/custom_nodes
RUN git clone https://github.com/visualbruno/ComfyUI-Trellis2.git && \
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git && \
    git clone https://github.com/kijai/ComfyUI-KJNodes.git && \
    git clone https://github.com/MoonGoblinDev/Civicomfy.git && \
    git clone https://github.com/MadiatorLabs/ComfyUI-RunpodDirect.git

# --------------------------------------------------------------------------
# Python dependencies (Trellis2 + custom nodes)
# --------------------------------------------------------------------------
RUN pip install \
    pillow scipy numpy trimesh open3d imageio opencv-python-headless \
    safetensors transformers accelerate huggingface_hub einops tqdm \
    "rembg[gpu]" onnxruntime-gpu torchsde \
    && cd /workspace/runpod-slim/ComfyUI/custom_nodes/ComfyUI-Trellis2 \
    && pip install -r requirements.txt 2>/dev/null || true

# --------------------------------------------------------------------------
# CUDA extensions are compiled at first container start (see /start.sh)
# --------------------------------------------------------------------------

# --------------------------------------------------------------------------
# Patch Trellis2: SDPA as default backend (no flash_attn compilation needed)
# --------------------------------------------------------------------------
RUN sed -i "s/BACKEND = 'flash_attn'/BACKEND = 'sdpa'/" \
    /workspace/runpod-slim/ComfyUI/custom_nodes/ComfyUI-Trellis2/trellis2/modules/attention/config.py && \
    sed -i 's/\["flash_attn","xformers"\],{"default":"xformers"}/["sdpa","flash_attn","xformers"],{"default":"sdpa"}/' \
    /workspace/runpod-slim/ComfyUI/custom_nodes/ComfyUI-Trellis2/nodes.py

# --------------------------------------------------------------------------
# Download models (baked into image for fast cold start)
# --------------------------------------------------------------------------
WORKDIR /workspace/runpod-slim/ComfyUI/models

# TRELLIS.2-4B (large ~16GB — will download on first run if not baked)
# Uncomment below to bake into image (increases image size by ~16GB):
# RUN mkdir -p microsoft && \
#     python3 -c " \
# from huggingface_hub import snapshot_download; \
# snapshot_download('microsoft/TRELLIS.2-4B', \
#     local_dir='microsoft/TRELLIS.2-4B') \
# "

# --------------------------------------------------------------------------
# ComfyUI args file
# --------------------------------------------------------------------------
RUN echo "# Add your custom ComfyUI arguments here (one per line)" \
    > /workspace/runpod-slim/comfyui_args.txt

# --------------------------------------------------------------------------
# Startup script
# --------------------------------------------------------------------------
COPY start.sh /start.sh
RUN chmod +x /start.sh

# --------------------------------------------------------------------------
# Ports: ComfyUI=8188, FileBrowser=8080, SSH=22
# --------------------------------------------------------------------------
EXPOSE 8188 8080 22

WORKDIR /workspace/runpod-slim/ComfyUI
CMD ["/start.sh"]
