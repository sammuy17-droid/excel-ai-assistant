
from __future__ import annotations
import os, uuid, time, json
from pathlib import Path
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.responses import StreamingResponse, HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from openpyxl.writer.excel import save_virtual_workbook
from .services.excel_engine import process

BASE_DIR = Path(__file__).resolve().parent.parent
STORAGE = BASE_DIR / "storage"
UPLOADS = STORAGE / "uploads"
RESULTS = STORAGE / "results"
UPLOADS.mkdir(parents=True, exist_ok=True)
RESULTS.mkdir(parents=True, exist_ok=True)

app = FastAPI(title="Excel AI Assistant Engine", version="1.0.0")

# Serve the web UI if present
WEB_DIR = BASE_DIR / "web"
if WEB_DIR.exists():
    app.mount("/web", StaticFiles(directory=str(WEB_DIR), html=True), name="web")

@app.get("/", response_class=HTMLResponse)
def root():
    if WEB_DIR.exists():
        return HTMLResponse('<meta http-equiv="refresh" content="0; url=/web/index.html" />')
    return HTMLResponse("Excel AI Assistant Engine is running. Visit /docs")

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/process")
async def process_excel(
    teacher_fullname: str = Form(...),
    template_file: UploadFile = File(...),
    data_files: list[UploadFile] = File(...)
):
    if len(data_files) == 0:
        raise HTTPException(status_code=400, detail="At least one data file is required.")
    if len(data_files) > 20:
        raise HTTPException(status_code=400, detail="Max 20 data files allowed.")

    job_id = uuid.uuid4().hex

    tpl_path = UPLOADS / f"{job_id}__template.xlsx"
    with open(tpl_path, "wb") as f:
        f.write(await template_file.read())

    data_paths = []
    for i, df in enumerate(data_files, start=1):
        p = UPLOADS / f"{job_id}__data_{i}.xlsx"
        with open(p, "wb") as f:
            f.write(await df.read())
        data_paths.append(str(p))

    wb, report = process(str(tpl_path), data_paths, teacher_fullname)

    out_bytes = save_virtual_workbook(wb)

    # Filename suggestion
    safe = "".join([c for c in report["teacher_short"] if c.isalnum() or c in (" ", ".", "_", "-")]).strip().replace(" ", "_")
    filename = f"{safe or 'result'}.xlsx"

    # Save result + report
    res_path = RESULTS / f"{job_id}__{filename}"
    with open(res_path, "wb") as f:
        f.write(out_bytes)
    with open(RESULTS / f"{job_id}__report.json", "w", encoding="utf-8") as f:
        json.dump(report, f, ensure_ascii=False, indent=2)

    def iterfile():
        yield out_bytes

    headers = {
        "Content-Disposition": f'attachment; filename="{filename}"',
        "X-Report": json.dumps(report, ensure_ascii=False)
    }
    return StreamingResponse(iterfile(), media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", headers=headers)

@app.get("/report/{job_id}")
def get_report(job_id: str):
    p = RESULTS / f"{job_id}__report.json"
    if not p.exists():
        raise HTTPException(status_code=404, detail="Report not found")
    return JSONResponse(content=json.loads(p.read_text(encoding="utf-8")))
