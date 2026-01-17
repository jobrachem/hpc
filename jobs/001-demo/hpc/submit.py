from pathlib import Path
from subprocess import run

submit_script_template = """source ~/.bashrc
source ~/.dotenv

cd {remote_repo_dir}
git pull

source .venv/bin/activate
python {jobdir}/hpc/render_sbatch.py

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
        remote_repo_dir="~/git/hpc",
        jobdir=str(jobdir.relative_to(basedir)),
        jobname=jobdir.name,
    )

    run(["ssh", "-q", "SCC", "-s"], input=submit)
