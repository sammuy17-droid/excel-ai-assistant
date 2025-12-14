# Backend (FastAPI) — Excel AI Assistant Engine

## Run locally
```bash
cd backend_fastapi
python -m venv venv
# Windows:
venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Health check: http://localhost:8000/health

## Main endpoint
`POST /process`

Form fields:
- `teacher_fullname`: text
- `template_file`: .xlsx (single)
- `data_files`: .xlsx (multiple, max 20)

Returns:
- `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet` as a download.

## Retention
Saved uploads/results are stored under `storage/`. A cleanup script exists:
```bash
python scripts/cleanup.py --days 120
```
(You can schedule it daily via Task Scheduler / cron.)
