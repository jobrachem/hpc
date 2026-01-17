import os
from pathlib import Path
from subprocess import run

submit_script_template = """set -eo pipefail
source ~/.bashrc
source ~/.dotenv

cd {remote_repo_dir}
git pull

source .venv/bin/activate
# Rscript -e 'renv::status()'
# Rscript -e 'renv::restore()'
# Rscript -e 'renv::status()'

python {jobdir}/hpc/render.py

sbatch --job-name={jobname} {jobdir}/hpc/sbatch.sh
"""

if __name__ == "__main__":
    jobdir = (Path(__file__).parent / "..").resolve()
    basedir = (jobdir / ".." / "..").resolve()
    if basedir != Path.cwd():
        raise RuntimeError(
            f"The working directory ({Path.cwd()}) is different from the guessed "
            f"base directory ({basedir}). This is unexpected."
        )

    print(jobdir.relative_to(basedir))

    submit = submit_script_template.format(
        remote_repo_dir=os.environ.get("REMOTE_REPO_DIR"),
        jobdir=str(jobdir.relative_to(basedir)),
        jobname=jobdir.name,
    )

    run(
        [str(basedir / "scripts/check_git_status.sh")],
        check=True,
    )

    run(["ssh", "-q", "SCC", "bash", "-s"], input=submit, text=True)
