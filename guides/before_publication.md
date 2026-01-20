# Before Publication

1. Archive jobs that are irrelevant to publication and remove them from the repository before publishing.
2. If necessary, add specific comments to `README.md` to help researchers reproduce your results or adjust the existing instructions to reflect any additions or changes to the default repository design.
3. Test the relevant jobs: Do they run without error? This is absolutely essential.
4. Test the analysis scripts: Do they run without error in a fresh environment? This, too, is absolutely essential.
5. Remove the `data/` directory from the `.gitignore` and commit the data necessary to reproduce your analyses in the `analysis/` to the repository. 
6. Also make the input data available, if legally possible. If the file size is not too large, you can commit the input data to the repository, too. Otherwise, you can make data available via Zenodo (https://zenodo.org).
