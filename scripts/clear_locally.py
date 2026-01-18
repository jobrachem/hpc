import shutil
from pathlib import Path

DELETE_OUT = False

if __name__ == "__main__":
    wd = Path.cwd()
    jobs = wd / "jobs"

    for dir in jobs.iterdir():
        if (dir / "log").exists():
            shutil.rmtree(dir / "log")

        if (dir / "finished").exists():
            shutil.rmtree(dir / "finished")

        if (dir / "out-test").exists():
            shutil.rmtree(dir / "out-test")

        if DELETE_OUT:
            if (dir / "out").exists():
                shutil.rmtree(dir / "out")
