#!/bin/bash

git status

# Check for unstaged changes or untracked files
if git status --porcelain | grep -Eq "^[ M\?]"; then
    # There are unstaged changes or untracked files
    read -p "There are unstaged changes or untracked files in the repository. Do you still want to proceed? [yes/no]: " response
    case "$response" in
        [yY]|[yY][eE][sS]) ;;
        *) echo "Aborting."; exit 1 ;;
    esac
fi


# Check if local repository is up to date with remote
local_commit=$(git rev-parse HEAD)
remote_commit=$(git ls-remote origin -h refs/heads/main | cut -f1)
if [ "$local_commit" != "$remote_commit" ]; then
    read -p "Local repository is not up to date with the remote. Do you still want to proceed? [yes/no]: " response
    case "$response" in
        [yY]|[yY][eE][sS]) ;;
        *) echo "Aborting."; exit 1 ;;
    esac
fi