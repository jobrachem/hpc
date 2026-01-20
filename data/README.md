# Data

This directory should hold the data for your experiments.

- `data/in` should hold data that serves as input to your experiments.
- `data/out` should hold data was produced as output of your experiments.

Directly in `data`, you can also place data curation scripts that prepare the
data in `data/in` for use in your experiments. **As a general rule, never overwrite the
raw data.** Instead, save the curated data alongside the raw data and the curation code.


By default, `data/in` and `data/out` are ignored in this repository via `.gitignore` to
prevent you from committing large files to Git. You can change this based on your own judgement, as it makes experimentation on an HPC and reproducibility after publication easier. However, sharing large amounts of data is better done by a dedicated data repository like Zenodo: https://zenodo.org.
