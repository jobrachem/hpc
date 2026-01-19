import shutil
from pathlib import Path

JOBS_DIRECTORY: str = "jobs"
DELETE_OUT = True

if __name__ == "__main__":
    wd = Path.cwd()
    jobs = wd / JOBS_DIRECTORY

    for dir in jobs.iterdir():
        print(f"Clearing {dir}")

        if (dir / "log").exists():
            print("\t deleting logs")
            shutil.rmtree(dir / "log")

        if (dir / "finished").exists():
            print("\t deleting finished")
            shutil.rmtree(dir / "finished")

        if (dir / "out-test").exists():
            print("\t deleting out-test")
            shutil.rmtree(dir / "out-test")

        if DELETE_OUT:
            if (dir / "out").exists():
                print("\t deleting out")
                shutil.rmtree(dir / "out")
