#!/bin/bash
set -eo pipefail

# ==============================================================================
# USER CONFIG (update these when cluster/account/resources/layout change)
# ==============================================================================

# Job-specific file layout
TESTING="0" # 0/1

# Slurm resources / account
SBATCH_PARTITION="scc-cpu"
SBATCH_CPUS_PER_TASK="1"
SBATCH_MEM="10G"
SBATCH_TIME="2-00:00:00"


SBATCH_ACCOUNT="scc_uwvn_kneib"

# ==============================================================================
# STABLE SCRIPT LOGIC (usually leave untouched)
# ==============================================================================

# Array throttling (max concurrent tasks)
SBATCH_ARRAY_MAX_CONCURRENT="100"

# Repo / environment on the cluster node
REMOTE_REPO_DIR="git/hpc"
ENV_SETUP=(
  "source ~/.bashrc"
  # add e.g. "source ~/.dotenv" if needed
)

# Where to write Slurm stdout/stderr *relative to the directory you submit from*
SLURM_STDOUT_DIR="slurm-out"
SLURM_STDERR_DIR="slurm-error"

# Job bookkeeping / outputs (inside JOBDIR)
FINISHED_DIR="finished"
LOG_DIR_NAME="log"
OUT_DIR_NAME="out"



# Resolve directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ensure Slurm output directories exist (relative to project root)
mkdir -p "$SCRIPT_DIR/../$SLURM_STDOUT_DIR" "$SCRIPT_DIR/../$SLURM_STDERR_DIR"

JOBDIR="$(realpath "$SCRIPT_DIR/..")"
JOB="$(basename "$JOBDIR")"

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

# bookkeeping dirs
mkdir -p "$JOBDIR/$FINISHED_DIR"
LOG_DIR="$JOBDIR/$LOG_DIR_NAME"
OUTPUT_DIR="$JOBDIR/$OUT_DIR_NAME"
mkdir -p "$LOG_DIR" "$OUTPUT_DIR"

# Determine which condition indices are not finished yet
FINISHED_LIST="$(cd "$JOBDIR/$FINISHED_DIR" && ls -1 2>/dev/null || true)"

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

sbatch --job-name="$JOB" <<SBATCH
#!/bin/bash
#SBATCH --partition=$SBATCH_PARTITION
#SBATCH --cpus-per-task=$SBATCH_CPUS_PER_TASK
#SBATCH --mem=$SBATCH_MEM
#SBATCH -A $SBATCH_ACCOUNT
#SBATCH -t $SBATCH_TIME
#SBATCH --output=$SLURM_STDOUT_DIR/%A_%a.out
#SBATCH --error=$SLURM_STDERR_DIR/%A_%a.err
#SBATCH --array=1-${N_REMAINING}%$SBATCH_ARRAY_MAX_CONCURRENT
#SBATCH --mail-type=all

set -eo pipefail

$(printf '%s\n' "${ENV_SETUP[@]}")

cd "\$HOME/$REMOTE_REPO_DIR"

IDX="\$SLURM_ARRAY_TASK_ID"
JOBROW=\$(printf '%s\n' "$CONDITION_INDICES" | sed -n "\${IDX}p")
LOGFILE="$LOG_DIR/j\${JOBROW}.log"

# Optional: skip if already finished
if [ -e "$JOBDIR/$FINISHED_DIR/\$JOBROW" ]; then
  echo "Condition \$JOBROW already finished. Skipping."
  exit 0
fi

".venv/bin/python" -u "$JOBDIR/run.py" \
  --jobdir "$JOBDIR" --jobrow "\$JOBROW" --testing "$TESTING" >> "\$LOGFILE" 2>&1

# mark done
: > "$JOBDIR/$FINISHED_DIR/\$JOBROW"
SBATCH