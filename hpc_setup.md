# Setup

This setup file describes how to prepare this repository for parallel runs on the High Performance Cluster of the Gesellschaft für Wissenschaftliche Datenverarbeitung (GWD). 

The steps to go through will usually be the same for other clusters, although the specific commands may differ. If you are working with a cluster that does not conduct resource management via slurm, you will need to make bigger changes to the submission scripts.

## SSH into the server

```
ssh SCC
```

Navigate to your project directory, I just use `git/`:

```
cd git
```

## Clone the Git repository

Assumes that git is already installed.

```
git clone https://$GITHUB_PAT@github.com/jobrachem/hpc.git
```

```
cd git
```

## Ensure that an R installation is available

There are usually multiple ways to make R available. This is one particular way to achieve the goal on the GWDG HPC.

First, install Conda miniforge:

```bash
# download and install miniforge
cd ~
wget -O Miniforge3.sh "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
CUSTOM_CONDA_ROOT="$HOME/conda"
# comment in the following line if you want to install conda in the project-specific data store instead of your home directory
# CUSTOM_CONDA_ROOT="$HOME/.project/dir.project/conda_$USER" 
MAMBA_ROOT_PREFIX="$CUSTOM_CONDA_ROOT" CONDA_ROOT_PREFIX="$CUSTOM_CONDA_ROOT" bash Miniforge3.sh -b -p "$CUSTOM_CONDA_ROOT"
rm Miniforge3.sh

# create .condarc file for some basic configurations
cat > "$HOME/.condarc" <<EOF
channels:
  - conda-forge
channel_priority: flexible
EOF

# initialize conda in shell
source "$CUSTOM_CONDA_ROOT/etc/profile.d/conda.sh"
conda init
```

Next, create a conda environment:

```
conda create -n r-4.5 -c conda-forge r-base=4.5
```

```
conda activate r-4.5
```

```
conda install -c conda-forge zlib r-arrow r-svglite
```

- zlib may need to be installed for some R dependencies to work
- arrow and svglite are dependencies of the Python library `ryp`

## Prepare R and Python environments

First, simply open the R REPL once:

```
R
```

This will bootstrap `renv` 

Then call

```
renv::restore()
```

This will download and install all required packages in the R and Python environments.

## Install Quarto

Follow this guide: https://quarto.org/docs/download/tarball.html


## Upload data

## Submit test job