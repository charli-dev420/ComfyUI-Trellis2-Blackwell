#!/bin/bash
set -e

COMFYUI_DIR="/workspace/runpod-slim/ComfyUI"
ARGS_FILE="/workspace/runpod-slim/comfyui_args.txt"
FILEBROWSER_DB="/workspace/runpod-slim/filebrowser.db"
CUDA_EXT_MARKER="/workspace/runpod-slim/.cuda_extensions_built"

# --------------------------------------------------------------------------
# SSH
# --------------------------------------------------------------------------
setup_ssh() {
    mkdir -p /run/sshd
    mkdir -p ~/.ssh
    for type in rsa dsa ecdsa ed25519; do
        [ -f "/etc/ssh/ssh_host_${type}_key" ] || \
            ssh-keygen -t ${type} -f "/etc/ssh/ssh_host_${type}_key" -q -N ''
    done
    if [[ $PUBLIC_KEY ]]; then
        echo "$PUBLIC_KEY" >> ~/.ssh/authorized_keys
        chmod 700 -R ~/.ssh
    elif [ -s ~/.ssh/authorized_keys ]; then
        chmod 700 -R ~/.ssh
        echo "Using existing SSH authorized_keys."
    else
        RANDOM_PASS=$(openssl rand -base64 12)
        echo "root:${RANDOM_PASS}" | chpasswd
        echo "SSH password: ${RANDOM_PASS}"
    fi
    echo "PermitUserEnvironment yes" >> /etc/ssh/sshd_config
    /usr/sbin/sshd
}

# --------------------------------------------------------------------------
# Environment export (for SSH sessions)
# --------------------------------------------------------------------------
export_env_vars() {
    mkdir -p /root/.ssh
    printenv | grep -E '^RUNPOD_|^PATH=|^CUDA|^LD_LIBRARY_PATH|^PYTHONPATH|^ATTN_BACKEND|^HF_' | \
    while IFS= read -r line; do
        name="${line%%=*}"
        value="${line#*=}"
        echo "export $name=\"$value\"" >> /etc/rp_environment
    done
    grep -q 'rp_environment' ~/.bashrc 2>/dev/null || echo 'source /etc/rp_environment 2>/dev/null' >> ~/.bashrc
}

# --------------------------------------------------------------------------
# FileBrowser
# --------------------------------------------------------------------------
start_filebrowser() {
    if command -v filebrowser &>/dev/null; then
        if [ ! -f "$FILEBROWSER_DB" ]; then
            filebrowser config init
            filebrowser config set --address 0.0.0.0 --port 8080 --root /workspace
            filebrowser config set --auth.method=json
            filebrowser users add admin adminadmin12 --perm.admin
        fi
        echo "Starting FileBrowser on port 8080..."
        nohup filebrowser &>/filebrowser.log &
    fi
}

# --------------------------------------------------------------------------
# Download TRELLIS.2-4B on first run (if not baked into image)
# --------------------------------------------------------------------------
download_trellis_model() {
    MODEL_DIR_4B="$COMFYUI_DIR/models/microsoft/TRELLIS.2-4B"
    MODEL_DIR_IMAGE="$COMFYUI_DIR/models/microsoft/TRELLIS-image-large"

    if [ ! -d "$MODEL_DIR_4B" ] || [ -z "$(ls -A $MODEL_DIR_4B 2>/dev/null)" ]; then
        echo "Downloading TRELLIS.2-4B model (first run only, ~16GB)..."
        python3 -c "
from huggingface_hub import snapshot_download
snapshot_download('microsoft/TRELLIS.2-4B',
    local_dir='$MODEL_DIR_4B')
"
        echo "TRELLIS.2-4B download complete."
    fi

    if [ ! -d "$MODEL_DIR_IMAGE" ] || [ -z "$(ls -A $MODEL_DIR_IMAGE 2>/dev/null)" ]; then
        echo "Downloading TRELLIS-image-large model (first run only, ~145MB)..."
        python3 -c "
from huggingface_hub import snapshot_download
snapshot_download('microsoft/TRELLIS-image-large',
    local_dir='$MODEL_DIR_IMAGE')
"
        echo "TRELLIS-image-large download complete."
    fi
}

# --------------------------------------------------------------------------
# Main
# --------------------------------------------------------------------------
setup_ssh
export_env_vars
start_filebrowser

# Ensure args file exists
[ -f "$ARGS_FILE" ] || echo "# Add your custom ComfyUI arguments here (one per line)" > "$ARGS_FILE"

# Download model if needed (background)
download_trellis_model &

# --------------------------------------------------------------------------
# Compile CUDA extensions on first run (cached on volume)
# --------------------------------------------------------------------------
compile_cuda_extensions() {
    if [ -f "$CUDA_EXT_MARKER" ]; then
        echo "CUDA extensions already compiled."
        return
    fi

    echo "Compiling CUDA extensions (first run only)..."
    mkdir -p /tmp/cuda_build
    pushd /tmp/cuda_build >/dev/null

    # nvdiffrast
    git clone --depth 1 https://github.com/NVlabs/nvdiffrast.git
    (cd nvdiffrast && TORCH_CUDA_ARCH_LIST="12.0" pip install . --no-build-isolation)
    rm -rf nvdiffrast

    # CuMesh
    git clone --depth 1 https://github.com/visualbruno/CuMesh.git
    (cd CuMesh && TORCH_CUDA_ARCH_LIST="12.0" CPLUS_INCLUDE_PATH="/usr/include/eigen3:$CPLUS_INCLUDE_PATH" \
        CMAKE_BUILD_PARALLEL_LEVEL=1 MAX_JOBS=1 pip install . --no-build-isolation)
    rm -rf CuMesh

    # FlexGEMM
    git clone --depth 1 https://github.com/JeffreyXiang/FlexGEMM.git
    (cd FlexGEMM && TORCH_CUDA_ARCH_LIST="12.0" CMAKE_BUILD_PARALLEL_LEVEL=1 MAX_JOBS=1 \
        pip install . --no-build-isolation)
    rm -rf FlexGEMM

    # o_voxel
    git clone --depth 1 https://github.com/visualbruno/TRELLIS.2.git
    (cd TRELLIS.2/extensions/o-voxel && TORCH_CUDA_ARCH_LIST="12.0" CMAKE_BUILD_PARALLEL_LEVEL=1 MAX_JOBS=1 \
        pip install . --no-build-isolation)
    rm -rf TRELLIS.2

    popd >/dev/null
    rm -rf /tmp/cuda_build

    touch "$CUDA_EXT_MARKER"
    echo "CUDA extensions compiled."
}

# Set attention backend
export ATTN_BACKEND="${ATTN_BACKEND:-sdpa}"
export PYTORCH_CUDA_ALLOC_CONF="expandable_segments:True"

compile_cuda_extensions

# Start ComfyUI
cd "$COMFYUI_DIR"
FIXED_ARGS="--listen 0.0.0.0 --port 8188"
CUSTOM_ARGS=""
if [ -s "$ARGS_FILE" ]; then
    CUSTOM_ARGS=$(grep -v '^#' "$ARGS_FILE" | tr '\n' ' ')
fi

echo "Starting ComfyUI (backend=$ATTN_BACKEND)..."
echo "Args: $FIXED_ARGS $CUSTOM_ARGS"
exec python3 main.py $FIXED_ARGS $CUSTOM_ARGS
