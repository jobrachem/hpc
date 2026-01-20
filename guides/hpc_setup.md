# Setup

This setup guide describes how to prepare this repository for parallel runs on the High 
Performance Computing (HPC) cluster of the Gesellschaft für Wissenschaftliche Datenverarbeitung (GWDG). 

The steps to go through will usually be the same for other clusters, although the specific commands may differ. If you are working with a cluster that does not conduct resource management via slurm, you will need to make bigger changes to the submission scripts.

This guide is long and detailed, but even that may not be sufficient to prevent 
problems in setup, since it admittedly is quite elaborate. Please make sure you have
plenty of time for setup, maybe ~4 hours in total.

If you are working on Windows, you may have to adjust some or many


## Setup SSH for connecting to the HPC

Follow the HPC documentation to establish a workflow for connecting to the HPC via
SSH: [Link](https://docs.hpc.gwdg.de).

After you have generally set up SSH connection, you should define an alias in your
`~/.ssh/config`:

I am using the following configuration:

```text
Host SCC
	Hostname login-mdc.hpc.gwdg.de
	User <your_username>
	ProxyJump jumphost
```

This will allow you to connect to the server via the terminal by writing:

```shell
ssh SCC
```

## Create .env file

To make the ssh alias (defined as `SCC` by the line `Host SCC`) available to the scripts
in this repository, create a file named `.env` in the project root directory of your
local machine. This is where we will store project-specific environment variables.
The `.env` file should be the place where you store any sensitive information. 
It is not tracked via git and should never be committed to the git repository.


First, confirm that you are in the correct working directory:

```shell
LOCAL> pwd # prints working directory
```
This should be your local project directory.

If not, move to the project directory. The following is just a boilerplate example.
The command `cd` is for "change directory", `~/projects/hpc` is the path. Change it
to reflect the actual project path you are using.

```shell
LOCAL> cd ~/projects/hpc
```

> Note that I am prefixing the command here by `LOCAL>`, and in other places by 
> `HPC>`. This is just to signal to the reader, where a command should be executed:
> in a local terminal session, or on the remote HPC server. Both of these prefixes 
> should be omitted when you copy & paste code from this guide into the terminal, so
> for example, in the line above, you should only paste `pwd # prints working directory`.


Next, create the .env file:

```shell
LOCAL> touch .env # create .env file (locally in project root directory)
```

Next, open it and set the SSH alias you defined above:

```bash
HPC_SSH_ALIAS="SCC"
```

Replace `SCC` with the alias you defined above in `~/.ssh/config

If you are working in VS Code or Positron, you can add the following settings to
`.vscode/settings.json` to ensure that the environment variables defined in
`.env` are available to the scripts in this project:

```json
# content of .vscode/settings.json (in your local project directory)
{
    "python.envFile": "${workspaceFolder}/.env",
    "python.terminal.useEnvFile": true,
    "code-runner.runInTerminal": true,
}
```

If you work with a different IDE, you need to figure out how to make these environment
variables yourself. This guide assumes use of VS Code or Positron.


## Connect to HPC and clone the Git repository

The next step is to clone your git repository on the remote HPC.
This guide assumes that git is already installed, which is the case on the GWDG HPC.

First, connect to the server using SSH in a terminal. As before, replace `SCC` with
the concrete alias you defined above.

```shell
LOCAL> ssh SCC
```

I highly recommend using the VS Code Remote Explorer to connect to the server using
SSH. This allows you to work in a well-known environment that almost feels as if you are
working on your own machine. See here: https://code.visualstudio.com/docs/remote/ssh

Next, create and navigate to your desired project directory. 
Let us assume it is called `projects`.

```shell
HPC> mkdir projects # creates the projects directory
```

```shell
HPC> cd projects
```

Next, clone this repository. If your repository is publicly hosted on GitHub, cloning 
is easy:

```shell
HPC> git clone https://github.com/jobrachem/hpc.git
```

Replace `https://github.com/jobrachem/hpc.git` with your concrete project repository.
If you are working with a private repository, you may have to use a personal access
token. This guide does not cover using a personal access token.

Now navigate your shell to the cloned repository. In the case of this guide, since the 
repository is called simply `hpc`, the directory is called `hpc`, so I write:

```shell
HPC> cd hpc
```

Now we want to find out the relative directory path. Run this to print the directory
path:

```shell
HPC> pwd # returns /user/brachem1/u15629/projects/hpc in my case
```

and run this to print the home directory:

```shell
HPC> echo $HOME # returns /user/brachem1/u15629 in my case
```

What we need is the directory path relative to the home directory, in this case:

```text
projects/hpc
```

You now must add this information to `.env` on your LOCAL machine:

```bash
HPC_SSH_ALIAS="SCC"
HPC_PROJECT_DIR="projects/hpc"
```

## Add compute project account name to .env

Your LOCAL `.env` needs one more piece of information: The name of the HPC compute
project you are a part of. 

```bash
HPC_SSH_ALIAS="SCC"
HPC_PROJECT_DIR="projects/hpc"
HPC_PROJECT_ACCOUNT_NAME="<project_account_name>"
```

## Ensure that an R installation is available

### Why is R required (even for pure Python projects)?

This repository is intended to support projects that rely on R and Python, and even
projects that mix R and Python in Quarto notebooks. To keep dependency management of
R and Python packages as simple as possible, it defaults to using the R package 
[`renv`](https://rstudio.github.io/renv/). So if you are directly following the workflow
of this repository, you need R even for pure Python projects, because the Python 
dependencies are managed by an R package. If you want to manage your dependencies 
otherwise, you will need to update multiple places in this repository, and that process
is not described in this guide.

### How to make R available on the HPC

There are usually multiple ways to make R available. 
This is one particular way to achieve the goal on the GWDG HPC.

First, install micromamba, which is something like a very light-weight and fast version
of conda. We will use micromamba to manage R installations. 

```shell
HPC> "${SHELL}" <(curl -L micro.mamba.pm/install.sh)
```

This command should work on most clusters. Confirm the default paths with enter.

For details, see the installation 
[instructions from their documentation](https://mamba.readthedocs.io/en/latest/installation/micromamba-installation.html):


Next, create an environment, specifying that we want it to contain R and the version
of R we need:

```shell
HPC> micromamba create -n r-4.5 -c conda-forge r-base=4.5
```

**Note that currently, this repository hard-codes the name of the R environment to `r-4.5`.**
You can use a different name. For that, you mainly need to change the line 
`micromamba activate r-4.5` in the `template.sh.j2` and `submit.py` files to use the correct name.

Next, activate this environment:

```shell
HPC> micromamba activate r-4.5
```

### Install some R packages

Next, we install some dependencies. For your particular use case, it may not be
necessary to install these, but in the projects I commonly work with, I found these
dependencies to matter.

```shell
HPC> (r-4.5) micromamba install -c conda-forge zlib r-arrow r-svglite r-mgcv r-knitr r-rmarkdown
```

- knitr and rmarkdown are for rendering .qmd notebooks.
- zlib may need to be installed for some other R dependencies to be installed successfully
- mgcv is a dependency of liesel_gam, and usually included in many R installations by
  default. This is not the case for the R installed via micromamba, so we install it
  here by default in order to avoid bad surprises.
- arrow and svglite are dependencies of the Python library `ryp`, which makes them 
  dependencies of `liesel_gam`. It can be problematic to try and manage an arrow 
  installation via renv by installing it from CRAN, because that often involves building
  arrow from source, which is fragile on the HPC. 

### Make the libraries of the r environment available to the renv project environment

Generally, this repository is set up to manage R packages via 
[`renv`](https://rstudio.github.io/renv/) for 
environment isolation, reproducibility and convenience. This is nice and works almost
always, but for some more complex dependencies, additional steps may be required. The R
package `arrow` mentioned above is such a case. Also, renv may not discover all dependencies, I found it sometimes misses knitr and rmarkdown, which are implicitly depended on to render the .qmd notebooks.

 Installation via `renv` fails. So, as a
fix, we install it via micromamba as described above. To make this installation 
available to the renv environment in our jobs, we need to add it to the 
`.libPaths()` recognized by R. This works as follows:

In your activated R environment, run

```r
(r-4.5) Rscript -e ".libPaths()"
```

This returns the library path, in my case

```r
[1] "/mnt/vast-standard/home/brachem1/u15629/micromamba/envs/r-4.5/lib/R/library"
```

Now update your project's `.Rprofile` file as follows:

```r
hpc_lib <- "/mnt/vast-standard/home/brachem1/u15629/micromamba/envs/r-4.5/lib/R/library"
if (dir.exists(hpc_lib)) {
  .libPaths(c(hpc_lib, .libPaths()))
}
```

The `.Rprofile` should be tracked in the repository. There may be more elegant ways to
achieve the same result, but this should work.

*Note that installing R packages directly in the `r-4.5` environment should be the
exception, not the rule. The rule should be to install R packages via `renv`, which
in this repository is set up to happen automatically. The reason for this is: renv keeps
the lock file `renv.lock`, which tracks the exact versions of all packages that are
used in your project. This is immensely helpful for reproducibility.* 


## Prepare R and Python environments

As part of the setup, we want to initialize the R and Python project environments
on the HPC once. This will ensure everything is in place and ready for work.

First, ensure that your micromamba environment with the R installation is activated. If it is
not, run:

```shell
HPC> micromamba activate r-4.5
```

Next, navigate to the project directory on the HPC and simply open the R console in the 
terminal:

```shell
HPC> (r-4.5) cd ~/projects/hpc
```

```shell
HPC> (r-4.5) R
```

This will automatically set up `renv` for this project.

Next, in this R session, you can call `renv::restore()` to download and install the
R packages listed in `renv.lock` and the Python packages listed in `requirements.txt`.

```r
HPC (R)> renv::restore()
```

I sometimes encounter installation problems for individual R packages in this step. 
Often they can be solved quickly when copy-pasting the error messages to an LLM.
For some packages, it may be necessary to install additional packages in your 
`r-4.5` micromamba environment (see the section on R dependencies above).

## Install Quarto

This repository uses [Quarto](https://quarto.org) to execute R and Python notebooks
(`run.qmd`) and Jupyter notebooks (`run.ipynb`), so Quarto must be installed on the
HPC.

TO install Quarto, follow this guide: https://quarto.org/docs/download/tarball.html

## Render test notebook on the HPC

To generally test the programming environments and Quarto installation on the HPC,
we now render the first demo notebook.
*You should be absolutely sure that this contains no heavy computation, 
since, if you are operating on GWDG HPC, you are most likely currently working on a 
login node, not a compute node.*

Your working directory should now be the project directory. If it is not, you can change
to it:

```shell
HPC> (r-4.5) cd ~/projects/hpc
```

First, activate the Python virtual environment created by `renv`:

```shell
HPC> (r-4.5) source .venv/bin/activate
```

Next, render the quarto notebook of the first demo job:

```shell
HPC> (.venv) (r-4.5) quarto render jobs/001-demo-knitr/run.qmd --to ipynb
```

This should run the code in the demo notebook and compile it to a Jupyter notebook
that is placed in

```text
~/projects/hpc/_output/jobs/001-demo-knitr/run.ipynb
```

Logs will be available in 

```text
~/projects/hpc/jobs/001-demo-knitr/log
```

## Configure environment variables on the HPC

To finalize the setup, we also need to configure one environment variable on the HPC:

For this, edit the content of the `.dotenv` file in your home directory. This works
a little different from the `.env` file we are using locally, but it is not a big deal.

```shell
# content of ~/.dotenv
export HPC_PROJECT_ACCOUNT_NAME="<project_account_name>"
```

The `HPC_PROJECT_DIR` and `HPC_SSH_ALIAS` environment variables are not required on the 
HPC.


## Submit test job

The moment has finally arrived: We will submit our first test job from our local project
directory to the server.

Your local working directory should now be the project directory. If it is not, you can change
to it:

```shell
LOCAL> cd ~/projects/hpc
```

To ensure that your local R and Python environments are in order, let `renv` update
them:

```shell
LOCAL> R
```

This will automatically set up `renv` for this project.

Next, in this R session, you can call `renv::restore()` to download and install the
R packages listed in `renv.lock` and the Python packages listed in `requirements.txt`.

```r
LOCAL (R)> renv::restore()
```

Now we execute the submit script for job `001-demo-knitr`.

```shell 
LOCAL> python jobs/001-demo-knitr/hpc/submit.py
```

Once this has succeeded, your setup is complete. You can now simply work with your
repository.