# ComfyUI Trellis2 RunPod Template

FR (Francais)
------------

Ce depot fournit une image Docker et un template RunPod pour ComfyUI + Trellis2 (SM 12.0 / Blackwell).

Fichiers principaux
- Dockerfile: image CUDA + Python 3.12 (compile depuis les sources), ComfyUI et dependances.
- start.sh: demarrage du pod, SSH, FileBrowser, download des modeles, compilation CUDA au premier run.
- RUNPOD_TEMPLATE.md: champs a copier dans RunPod.
- README.md: documentation generale.

Demarrage rapide (PowerShell)
1) Build
   docker build --network=host -t docker.io/<user>/comfyui-trellis2-blackwell:latest -f Dockerfile .
2) Push
   docker push docker.io/<user>/comfyui-trellis2-blackwell:latest

RunPod
- Utilise RUNPOD_TEMPLATE.md pour remplir le template.
- Ports: 8188 (ComfyUI), 8080 (FileBrowser), 22 (SSH).

SSH
- Si RunPod injecte deja la cle dans ~/.ssh/authorized_keys, PUBLIC_KEY n est pas necessaire.
- Sinon, definir PUBLIC_KEY ou recuperer le mot de passe root dans les logs.

Modeles (premier run)
- TRELLIS.2-4B et TRELLIS-image-large sont telecharges au premier demarrage.
- Upload manuel possible pour eviter HF_TOKEN:
  - /workspace/runpod-slim/ComfyUI/models/microsoft/TRELLIS.2-4B
  - /workspace/runpod-slim/ComfyUI/models/microsoft/TRELLIS-image-large

Compilation CUDA (premier run)
- Les extensions CUDA (nvdiffrast, CuMesh, FlexGEMM, o_voxel) sont compilees au premier demarrage.
- Le cache est conserve sur le volume.

Depannage rapide
- Premier run lent: compilation CUDA + download des modeles.
- Reutilise le meme volume pour garder le cache.

FAQ
- Comment acceder au FileBrowser ? Utilise le port 8080 (HTTP) et connecte-toi avec admin/adminadmin12.
- Pas de cle SSH ? Le mot de passe root est affiche dans les logs au demarrage.
- HF_TOKEN manquant ? Upload manuel des modeles dans /workspace/runpod-slim/ComfyUI/models/microsoft/.

---

EN (English)
------------

This repository provides a Docker image and a RunPod template for ComfyUI + Trellis2 (SM 12.0 / Blackwell).

Key files
- Dockerfile: CUDA base + Python 3.12 (built from source), ComfyUI and dependencies.
- start.sh: pod startup, SSH, FileBrowser, model downloads, CUDA compile on first run.
- RUNPOD_TEMPLATE.md: template fields for RunPod.
- README.md: general documentation.

Quick start (PowerShell)
1) Build
   docker build --network=host -t docker.io/<user>/comfyui-trellis2-blackwell:latest -f Dockerfile .
2) Push
   docker push docker.io/<user>/comfyui-trellis2-blackwell:latest

RunPod
- Use RUNPOD_TEMPLATE.md for template fields.
- Ports: 8188 (ComfyUI), 8080 (FileBrowser), 22 (SSH).

SSH
- If RunPod injects a key into ~/.ssh/authorized_keys, PUBLIC_KEY is not required.
- Otherwise set PUBLIC_KEY or read the root password from pod logs.

Models (first run)
- TRELLIS.2-4B and TRELLIS-image-large are downloaded on first start.
- Manual upload avoids HF_TOKEN:
  - /workspace/runpod-slim/ComfyUI/models/microsoft/TRELLIS.2-4B
  - /workspace/runpod-slim/ComfyUI/models/microsoft/TRELLIS-image-large

CUDA compilation (first run)
- CUDA extensions (nvdiffrast, CuMesh, FlexGEMM, o_voxel) compile on first start.
- Cache persists on the volume.

Quick troubleshooting
- First start is slow due to CUDA compilation and model downloads.
- Reuse the same volume to keep cache.

FAQ
- How do I access FileBrowser? Use port 8080 (HTTP) and login with admin/adminadmin12.
- No SSH key? The root password is printed in logs at startup.
- Missing HF_TOKEN? Manually upload models into /workspace/runpod-slim/ComfyUI/models/microsoft/.
