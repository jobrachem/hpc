# A Template for Reproducible Experimentation

This repository is designed to hold reproducible experimentation code for 
research in statistics/machine learning.

## Contents

## How to reproduce computations

1. Execute an individual job locally.
1. Execute all runs of one or more jobs locally.
1. Execute runs on a high-performance compute cluster.

## Principles

1. Each job consists of a single `run.qmd` file.
1. Each .qmd file is stand-alone executable.
1. Experimentation parameters are defined in `.csv` files.
1. All raw data is stored in `./data/`.
1. R and Python environments are managed via `{renv}`.
1. All `run.qmd` files use the project root as the working directory.

## Experimentation Workflow

## Publishing Workflow

1. Archive jobs that are irrelevant to publication and remove them from the published repository.
1. If necessary, add specific comments to help researchers reproduce your results or adjust the existing instructions to reflect any additions or changes to the default repository design.
1. Test that the relevant jobs: Do they run without error?
