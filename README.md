# ComfyUI Trellis2 RunPod Template

FR (Francais)
------------

Ce depot contient une image Docker et une configuration de template RunPod pour ComfyUI + Trellis2 (SM 12.0 / Blackwell).

Contenu
- Dockerfile: image CUDA + Python 3.12 compile, ComfyUI et extensions.
- start.sh: demarrage du pod, SSH, FileBrowser, telechargements modeles, compilation CUDA au premier run.
- RUNPOD_TEMPLATE.md: parametres a copier dans RunPod.

Pre-requis
- Docker Desktop ou Docker Engine
- Acces a Docker Hub (ou autre registry) pour push l image

Build et push (PowerShell)
1) Definir le tag
   docker build --network=host -t docker.io/<user>/comfyui-trellis2-blackwell:latest -f Dockerfile .
2) Push
   docker push docker.io/<user>/comfyui-trellis2-blackwell:latest

RunPod
- Voir RUNPOD_TEMPLATE.md pour les champs a renseigner.
- Ports: 8188 (ComfyUI), 8080 (FileBrowser), 22 (SSH).

SSH
- Si RunPod injecte deja une cle dans ~/.ssh/authorized_keys, pas besoin de PUBLIC_KEY.
- Sinon, definir PUBLIC_KEY ou recuperer le mot de passe root depuis les logs du pod.

Modeles (premier run)
- TRELLIS.2-4B et TRELLIS-image-large sont telecharges au premier demarrage.
- Pour eviter HF_TOKEN, upload manuel possible dans:
  - /workspace/runpod-slim/ComfyUI/models/microsoft/TRELLIS.2-4B
  - /workspace/runpod-slim/ComfyUI/models/microsoft/TRELLIS-image-large

Compilation CUDA (premier run)
- Les extensions CUDA (nvdiffrast, CuMesh, FlexGEMM, o_voxel) sont compilees au premier demarrage.
- Le cache est conserve sur le volume.

---

EN (English)
------------

This repository provides a Docker image and a RunPod template for ComfyUI + Trellis2 (SM 12.0 / Blackwell).

Contents
- Dockerfile: CUDA base image + Python 3.12 (built from source), ComfyUI and dependencies.
- start.sh: pod startup, SSH, FileBrowser, model downloads, CUDA compilation on first run.
- RUNPOD_TEMPLATE.md: copy/paste settings for RunPod.

Prerequisites
- Docker Desktop or Docker Engine
- Access to Docker Hub (or another registry) to push the image

Build and push (PowerShell)
1) Build
   docker build --network=host -t docker.io/<user>/comfyui-trellis2-blackwell:latest -f Dockerfile .
2) Push
   docker push docker.io/<user>/comfyui-trellis2-blackwell:latest

RunPod
- Use RUNPOD_TEMPLATE.md for template fields.
- Ports: 8188 (ComfyUI), 8080 (FileBrowser), 22 (SSH).

SSH
- If RunPod injects your key into ~/.ssh/authorized_keys, you can omit PUBLIC_KEY.
- Otherwise, set PUBLIC_KEY or retrieve the root password from pod logs.

Models (first run)
- TRELLIS.2-4B and TRELLIS-image-large are downloaded on first start.
- If you already have the models, upload them to:
  - /workspace/runpod-slim/ComfyUI/models/microsoft/TRELLIS.2-4B
  - /workspace/runpod-slim/ComfyUI/models/microsoft/TRELLIS-image-large

CUDA compilation (first run)
- CUDA extensions (nvdiffrast, CuMesh, FlexGEMM, o_voxel) are compiled on first start.
- Cache is stored on the volume.
