#!/bin/bash
set -euo pipefail

# ==============================================================================
# USER CONFIG (update these when you move servers/repos/projects)
# ==============================================================================

# Change if your local scripts live elsewhere
GIT_CHECK_SCRIPT="scripts/check_git_status.sh"

# ==============================================================================
# STABLE SCRIPT LOGIC (usually leave untouched)
# ==============================================================================

SERVER="SCC"                 # SSH host / alias
SCRIPT_DIR_ABS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JOB_DIR="$(realpath "$SCRIPT_DIR_ABS/..")"
SCRIPT_DIR_REL="${SCRIPT_DIR_ABS#"$PWD"/}"
JOB_DIR_REL="${JOB_DIR#"$PWD"/}"

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
# Submit job (remote)
# ------------------------------------------------------------------------------

echo "Connecting to the server"

ssh -q "$SERVER" <<EOF
# set -eo pipefail

cd "$REMOTE_REPO_DIR"
rm -rv $JOB_DIR_REL/finished
rm -rv $JOB_DIR_REL/log
rm -rv $JOB_DIR_REL/slurm-err
rm -rv $JOB_DIR_REL/slurm-out
rm -rv $JOB_DIR_REL/out-test
# rm -rv $JOB_DIR_REL/out

EOF