from pathlib import Path
from subprocess import run

SUBMIT = ["001"]

if __name__ == "__main__":
    wd = Path.cwd()
    jobs = wd / "jobs"

    for dir in jobs.iterdir():
        if dir.name[:3] in SUBMIT:
            run(["python", str(dir / "hpc" / "submit.py")])
