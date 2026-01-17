"""
Runs jobs locally in sequence.

If parallelization is desired, the handling of finished runs has to be refactored.
The current logic relies on sequential execution for avoiding re-running finished
runs.

This file should be executed via the command line::

    python scripts/run_jobs_locally.py
"""

import shutil
from pathlib import Path
from subprocess import run

import pandas as pd

# --------------------------------------------------------------------------------------
# Update your settings here
# --------------------------------------------------------------------------------------
JOB_PREFIXES = ["001"]
SAVE_RENDERED_NOTEBOOK = False

# --------------------------------------------------------------------------------------
# The following code usually does not need to be touched
# --------------------------------------------------------------------------------------
JOBS = Path.cwd() / "jobs"


def run_one_job(prefix: str):
    job = [d for d in JOBS.iterdir() if d.name.startswith(prefix)][0]
    if (job / "finished").exists():
        finished = [int(fin.name) for fin in (job / "finished").iterdir()]
    else:
        finished = []

    params = pd.read_csv(job / "params.csv")
    for i in range(params.shape[0]):
        if i in finished:
            print(f"Skipping {i}: It is already finished.")
            continue

        job_row = i
        output_dir = f"_output/jobs/{job.name}/row{job_row:04d}"
        command = [
            "quarto",
            "render",
            str((job / "run.qmd")),
            "--to",
            "ipynb",
            "--output-dir",
            output_dir,
            "-P",
            f"JOB_ROW:{job_row}",
            "-P",
            f'JOB_DIR:"{str(job)}"',
            "-P",
            "JOB_TESTING:False",
        ]

        run(command)

        if not SAVE_RENDERED_NOTEBOOK:
            print(
                "Removing rendered output dir (does not affect output saved in the "
                "notebook manually)."
            )
            shutil.rmtree(output_dir)


if __name__ == "__main__":
    for prefix in JOB_PREFIXES:
        run_one_job(prefix)
