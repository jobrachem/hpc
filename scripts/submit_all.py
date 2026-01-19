from pathlib import Path
from subprocess import run

JOBS_DIRECTORY: str = "jobs"

if __name__ == "__main__":
    wd = Path.cwd()
    jobs = wd / JOBS_DIRECTORY

    for dir in jobs.iterdir():
        run(["python", str(dir / "hpc" / "submit.py")])
