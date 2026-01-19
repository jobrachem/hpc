from pathlib import Path
from subprocess import run

JOBS_DIRECTORY: str = "jobs"
if __name__ == "__main__":
    wd = Path.cwd()
    jobs = wd / JOBS_DIRECTORY

    for dir in jobs.iterdir():
        print(f"Running script for {dir.name}.")
        run(
            [
                "bash",
                str(dir / "hpc" / "clear.sh"),
                "--delete-out",  # uncomment to delete out directories
            ]
        )
