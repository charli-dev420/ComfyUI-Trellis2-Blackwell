#!/bin/bash
# =============================================================================
# Build & Push — ComfyUI + Trellis2 RunPod Image
# =============================================================================
#
# Prerequisites:
#   - Docker with NVIDIA Container Toolkit (for GPU build steps)
#   - DockerHub or GHCR account
#
# Usage:
#   ./build.sh                          # build only
#   ./build.sh push                     # build + push
#   REGISTRY=ghcr.io/user ./build.sh    # custom registry
# =============================================================================

set -e

IMAGE_NAME="${IMAGE_NAME:-comfyui-trellis2-blackwell}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
REGISTRY="${REGISTRY:-docker.io/youruser}"  # ← Change this

FULL_TAG="$REGISTRY/$IMAGE_NAME:$IMAGE_TAG"

echo "=== Building: $FULL_TAG ==="
echo "This will take 30-60 minutes (CUDA compilation for SM 12.0)"

docker build \
    --network=host \
    -t "$FULL_TAG" \
    -f Dockerfile \
    .

echo "=== Build complete: $FULL_TAG ==="
echo "Image size: $(docker image ls $FULL_TAG --format '{{.Size}}')"

if [ "$1" = "push" ]; then
    echo "=== Pushing to $REGISTRY ==="
    docker push "$FULL_TAG"
    echo "=== Push complete ==="
    echo ""
    echo "RunPod Template settings:"
    echo "  Container Image: $FULL_TAG"
    echo "  Docker Command:  (leave empty — uses CMD from Dockerfile)"
    echo "  Expose HTTP Ports: 8188,8888,8080"
    echo "  Expose TCP Ports:  22"
fi
