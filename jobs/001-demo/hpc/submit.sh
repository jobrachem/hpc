#!/bin/bash
set -euo pipefail

# ==============================================================================
# USER CONFIG (update these when you move servers/repos/projects)
# ==============================================================================
REMOTE_REPO_DIR="git/hpc"  # Path on the remote machine to the repo root
SERVER="SCC"                 # SSH host / alias

# Job-specific file layout
TESTING=False # True / False

# Slurm resources / account
SBATCH_ACCOUNT="scc_uwvn_kneib"
SBATCH_PARTITION="scc-cpu" # alternative: medium
SBATCH_CPUS_PER_TASK="1"
SBATCH_MEM="10G"
SBATCH_TIME="2-00:00:00"


# ==============================================================================
# STABLE SCRIPT LOGIC (usually leave untouched)
# ==============================================================================
SCRIPT_DIR_ABS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JOB_DIR="$(realpath "$SCRIPT_DIR_ABS/..")"
JOB_NAME="$(basename "$JOB_DIR")"

# Relative paths (so remote 'cd' works if the same repo layout exists there)
SCRIPT_DIR_REL="${SCRIPT_DIR_ABS#"$PWD"/}"
JOB_DIR_REL="${JOB_DIR#"$PWD"/}"

# Where to write Slurm stdout/stderr *relative to the directory you submit from*
SLURM_STDOUT_DIR="slurm-out"
SLURM_STDERR_DIR="slurm-error"

# Ensure Slurm output directories exist (relative to root)
mkdir -p "$SCRIPT_DIR/../$SLURM_STDOUT_DIR" "$SCRIPT_DIR/../$SLURM_STDERR_DIR"

# Job bookkeeping / outputs (inside JOBDIR)
FINISHED_DIR_NAME="finished"
LOG_DIR_NAME="log"
OUT_DIR_NAME="out"

# bookkeeping dirs
FINISHED_DIR="$JOBDIR/$FINISHED_DIR_NAME"
LOG_DIR="$JOBDIR/$LOG_DIR_NAME"
OUTPUT_DIR="$JOBDIR/$OUT_DIR_NAME"
mkdir -p "$FINISHED_DIR"
mkdir -p "$LOG_DIR"
mkdir -p "$OUTPUT_DIR"

GIT_CHECK_SCRIPT="scripts/check_git_status.sh"
REMOTE_SETUP=(
  "source ~/.bashrc"
  "source ~/.dotenv"
)
REMOTE_RUN_CMD="bash hpc/run.sh"  # What to execute from the job directory

echo "Submitting job ${JOB_NAME}. Server: ${SERVER}"

# ------------------------------------------------------------------------------
# Check git repo status (local)
# ------------------------------------------------------------------------------

if bash "$GIT_CHECK_SCRIPT"; then
  echo "Git repo status was checked. Continuing."
else
  echo "Git repo status check failed. Aborting." >&2
  exit 1
fi

# ------------------------------------------------------------------------------
# Parse params.csv and finished/ directory
# ------------------------------------------------------------------------------

PARAMS_PATH="$JOBDIR/params.csv"
if [[ ! -f "$PARAMS_PATH" ]]; then
  echo "ERROR: Params file not found: $PARAMS_PATH" >&2
  exit 1
fi

# number of conditions = number of lines minus header lines
TOTAL_LINES="$(wc -l < "$PARAMS_PATH")"
if (( TOTAL_LINES <= 1 )); then
  echo "ERROR: Params file has fewer lines ($TOTAL_LINES) than header (1)." >&2
  exit 1
fi
N_CONDITIONS=$(( TOTAL_LINES - 2 ))

# Determine which condition indices are not finished yet
FINISHED_LIST="$(cd "$FINISHED_DIR" && ls -1 2>/dev/null || true)"

# Conditions are assumed to be indexed 0..N_CONDITIONS; 
# N_CONDITIONS already has 1 subtracted
CONDITION_INDICES="$(
  seq 0 "$N_CONDITIONS" | grep -vxF -f <(printf '%s\n' $FINISHED_LIST) || true
)"

N_REMAINING="$(printf '%s\n' "$CONDITION_INDICES" | sed '/^$/d' | wc -l | tr -d ' ')"

if (( N_REMAINING == 0 )); then
  echo "Nothing to submit: all conditions appear finished."
  exit 0
fi


echo "========================================"
echo " Job submission summary"
echo "========================================"

printf "  %-15s %s\n" "JOBDIR:"      "$JOBDIR"
printf "  %-15s %s\n" "TESTING:"     "$TESTING"
printf "  %-15s %s\n" "JOB:"         "$JOB"
printf "  %-15s %s\n" "REMAINING:"   "$N_REMAINING"

echo "----------------------------------------"
echo "Submitting job…"

# ------------------------------------------------------------------------------
# Submit job (remote)
# ------------------------------------------------------------------------------

echo "Connecting to the server"

ssh -q "$SERVER" <<EOF
set -eo pipefail

cd "$REMOTE_REPO_DIR"
git pull

$(printf '%s\n' "${REMOTE_SETUP[@]}")

cd "$JOB_DIR_REL"
$REMOTE_RUN_CMD
EOF