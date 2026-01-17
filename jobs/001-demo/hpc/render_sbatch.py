import os
from pathlib import Path

import pandas as pd
from jinja2 import Environment, FileSystemLoader, StrictUndefined

REMOTE_REPO_DIR = "git/hpc"


def render_template(
    template_dir: Path,
    template_name: str,
    output_path: Path,
    context: dict,
) -> None:
    """
    Render a Jinja2 template to a file.

    Parameters
    ----------
    template_dir : Path
        Directory containing the Jinja template.
    template_name : str
        Filename of the template (e.g. 'slurm_job.sh.j2').
    output_path : Path
        Where to write the rendered script.
    context : dict
        Mapping of template variables to values.
    """
    env = Environment(
        loader=FileSystemLoader(template_dir),
        undefined=StrictUndefined,  # fail loudly if something is missing
        trim_blocks=True,
        lstrip_blocks=True,
    )

    template = env.get_template(template_name)
    rendered = template.render(**context)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(rendered)

    # Make script executable (optional but usually useful)
    output_path.chmod(0o755)


TEMPLATE_NAME = "sbatch_template.sh.j2"
SCRIPT_NAME = "sbatch.sh"


def render_submit_script(jobdir: Path):
    hpc_dir = jobdir / "hpc"
    finished_dir = jobdir / "finished"

    params = pd.read_csv(jobdir / "params.csv")

    all_rows = list(range(params.shape[0]))
    finished_rows = [int(f.name) for f in finished_dir.iterdir()]
    remaining_rows = [str(i) for i in all_rows if i not in finished_rows]

    context = {
        # ---------------------------------------------
        # Job-specific resource demand
        "SBATCH_PARTITION": "scc-cpu",
        "SBATCH_CPUS_PER_TASK": 1,
        "SBATCH_MEM": "4G",
        "SBATCH_TIME": "01:00:00",
        "SBATCH_ARRAY_MAX_CONCURRENT": 10,
        # ---------------------------------------------
        # constant or automatically inferred settings
        "N_REMAINING": len(remaining_rows),
        "CONDITION_INDICES": "\n".join(remaining_rows),
        "JOBDIR": str(jobdir),
        "LOG_DIR": str(jobdir / "log"),
        "FINISHED_DIR": str(finished_dir),
        "SBATCH_ACCOUNT": os.environ.get("SBATCH_CLUSTER_ACCOUNT_NAME"),
        "SLURM_STDOUT_DIR": str(jobdir / "slurm-out"),
        "SLURM_STDERR_DIR": str(jobdir / "slurm-err"),
        # assumes this script is executed on the server in the right working directory
        "REMOTE_REPO_DIR": Path.cwd(),
    }

    render_template(
        template_dir=hpc_dir,
        template_name=TEMPLATE_NAME,
        output_path=hpc_dir / SCRIPT_NAME,
        context=context,
    )


if __name__ == "__main__":
    jobdir = (Path(__file__).parent / "..").resolve()
    basedir = (jobdir / ".." / "..").resolve()
    if basedir != Path.cwd():
        raise RuntimeError(
            f"The working directory ({Path.cwd()}) is different from the guessed "
            f"base directory ({basedir}). This is unexpected."
        )

    print(jobdir.relative_to(basedir))
    render_submit_script(jobdir.relative_to(basedir))
