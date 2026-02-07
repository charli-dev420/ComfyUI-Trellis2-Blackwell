# RunPod Template Guide (ComfyUI Trellis2)

FR (Francais)
------------

Ce guide decrit comment creer le template RunPod pour cette image.

Etapes
1) Ouvrir RunPod: https://www.runpod.io/console/user/templates
2) Creer un nouveau template et copier les champs du fichier RUNPOD_TEMPLATE.md
3) Renseigner l image docker (ex: docker.io/<user>/comfyui-trellis2-blackwell:latest)
4) Sauvegarder puis creer un pod avec une RTX 5090

Variables d environnement
- ATTN_BACKEND: sdpa (par defaut)
- PUBLIC_KEY: optionnel si RunPod injecte deja authorized_keys
- HF_TOKEN: optionnel si tu uploades les modeles manuellement

SSH
- Si RunPod injecte la cle, connexion SSH directe possible.
- Sinon, le conteneur genere un mot de passe root dans les logs.

Modeles
- Telechargement automatique au premier run si HF_TOKEN est disponible.
- Upload manuel possible pour eviter HF_TOKEN:
  - /workspace/runpod-slim/ComfyUI/models/microsoft/TRELLIS.2-4B
  - /workspace/runpod-slim/ComfyUI/models/microsoft/TRELLIS-image-large

Compilation CUDA
- Les extensions CUDA sont compilees au premier run.
- Le cache est conserve sur le volume.

---

EN (English)
------------

This guide explains how to create the RunPod template for this image.

Steps
1) Open RunPod: https://www.runpod.io/console/user/templates
2) Create a new template and copy fields from RUNPOD_TEMPLATE.md
3) Set the Docker image (ex: docker.io/<user>/comfyui-trellis2-blackwell:latest)
4) Save and create a pod with an RTX 5090

Environment variables
- ATTN_BACKEND: sdpa (default)
- PUBLIC_KEY: optional if RunPod already injects authorized_keys
- HF_TOKEN: optional if you upload models manually

SSH
- If RunPod injects the key, SSH works immediately.
- Otherwise the container prints a random root password in logs.

Models
- Auto-download on first start if HF_TOKEN is set.
- Manual upload avoids HF_TOKEN:
  - /workspace/runpod-slim/ComfyUI/models/microsoft/TRELLIS.2-4B
  - /workspace/runpod-slim/ComfyUI/models/microsoft/TRELLIS-image-large

CUDA compilation
- CUDA extensions compile on first start.
- Cache is stored on the volume.
