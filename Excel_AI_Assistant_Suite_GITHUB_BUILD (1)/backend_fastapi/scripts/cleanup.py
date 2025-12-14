
import argparse
from pathlib import Path
from datetime import datetime, timedelta

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--days", type=int, default=120)
    ap.add_argument("--root", type=str, default=str(Path(__file__).resolve().parent.parent / "storage"))
    args = ap.parse_args()

    root = Path(args.root)
    cutoff = datetime.now() - timedelta(days=args.days)
    deleted = 0

    for folder in ["uploads", "results"]:
        p = root / folder
        if not p.exists():
            continue
        for fp in p.glob("*"):
            try:
                mtime = datetime.fromtimestamp(fp.stat().st_mtime)
                if mtime < cutoff:
                    fp.unlink(missing_ok=True)
                    deleted += 1
            except Exception:
                pass
    print(f"Deleted {deleted} files older than {args.days} days.")

if __name__ == "__main__":
    main()
