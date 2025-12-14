# Excel AI Assistant Suite (Web + Windows + Android)

This repo contains:
- `backend_fastapi/` : the Excel processing engine + serves `/web` UI
- `windows_electron/`: Windows desktop app (wraps the web UI)
- `android_flutter/` : Android app (native file picking + upload)

## Get a public web link (fast)
### Option A — Render (recommended)
1) Create a free Render account
2) New > Blueprint
3) Point it to this repo (or upload)
4) Render will read `render.yaml` and deploy
Your link will look like: `https://excel-ai-assistant.onrender.com`

Then:
- Windows app: set env `BACKEND_URL` to that link
- Android app: set Backend URL field in the app

### Option B — Any VPS
Run:
```bash
cd backend_fastapi
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000
```
Use Nginx to expose HTTPS.

## Build ready installers automatically (no local build)
Push to GitHub, then:
- Actions > **Build Android APK** > Run workflow → download artifact APK
- Actions > **Build Windows Installer** > Run workflow → download installer from artifacts
