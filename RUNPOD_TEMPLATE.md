# RunPod Template Configuration
# ==============================
# Use these settings when creating a RunPod Template at:
# https://www.runpod.io/console/user/templates

## Template Settings

| Field | Value |
|---|---|
| **Template Name** | `ComfyUI-Trellis2-Blackwell` |
| **Container Image** | `youruser/comfyui-trellis2-blackwell:latest` |
| **Docker Command** | *(leave empty)* |
| **Container Disk** | `30 GB` (minimum) |
| **Volume Disk** | `50 GB` (for models — TRELLIS.2-4B is ~16GB) |
| **Volume Mount Path** | `/workspace` |
| **Expose HTTP Ports** | `8188, 8080` |
| **Expose TCP Ports** | `22` |

## Environment Variables

| Variable | Value | Description |
|---|---|---|
| `ATTN_BACKEND` | `sdpa` | Attention backend (sdpa/flash_attn/xformers) |
| `PUBLIC_KEY` | *(your SSH pubkey)* | SSH public key (optional if RunPod injects authorized_keys) |
| `HF_TOKEN` | *(your HF token)* | HuggingFace token for gated models |

## Compatible GPUs

| GPU | SM | Status |
|---|---|---|
| **RTX 5090** | 12.0 | Primary target |
| **RTX 5080** | 12.0 | Compatible |
| **RTX 5070 Ti** | 12.0 | Compatible |
| **RTX 5070** | 12.0 | Compatible |

> **Note:** This image is compiled exclusively for SM 12.0 (Blackwell).
> It will NOT work on Ampere (SM 8.x), Ada Lovelace (SM 8.9), or Hopper (SM 9.0).

## Ports

| Port | Service |
|---|---|
| 8188 | ComfyUI Web UI |
| 8080 | FileBrowser |
| 22 | SSH |

## What's included

- **ComfyUI** (latest)
- **ComfyUI-Trellis2** (visualbruno) — 3D mesh generation
- **ComfyUI-Manager** — node management
- **ComfyUI-KJNodes** — utility nodes
- **Civicomfy** — CivitAI integration
- **ComfyUI-RunpodDirect** — RunPod direct access

### CUDA extensions (compiled on first run, cached on volume)
- nvdiffrast
- CuMesh
- FlexGEMM (flex_gemm)
- o_voxel

### Models (downloaded on first run)
- `microsoft/TRELLIS-image-large` (~145 MB)
- `microsoft/TRELLIS.2-4B` (~16 GB)

## First Run

1. Create a pod with this template on an **RTX 5090** GPU
2. TRELLIS.2-4B and TRELLIS-image-large download automatically on first start
3. Access ComfyUI at `https://<pod-id>-8188.proxy.runpod.net`
4. Load a Trellis2 workflow from the example_workflows folder
