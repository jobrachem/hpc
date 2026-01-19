from pathlib import Path
from subprocess import run

if __name__ == "__main__":
    wd = Path.cwd()
    jobs = wd / "jobs"

    for dir in jobs.iterdir():
        print(f"Running script for {dir.name}.")
        run(
            [
                "bash",
                str(dir / "hpc" / "clear.sh"),
                "--delete-out",  # uncomment to delete out directories
            ]
        )
