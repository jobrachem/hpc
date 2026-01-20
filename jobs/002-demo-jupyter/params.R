library(tidyverse)

# ..............................................................................
# ---- Specify parameter dataframe ----
# ..............................................................................
# Just one rule: Each independent model run should be defined
# by one row of the `params` dataframe.

data_seed <- 1:200
data_type <- c("abc")
nobs <- c(2000, 10000, 20000)

params <- expand_grid(data_seed, data_type, nobs)

# ..............................................................................
# ---- Save params dataframe ----
# ..............................................................................
# The following code saves the params dataframe in the same directory
# as this R script. Usually, this code does not need to be adjusted.

# Get the directory of the currently active file
current_file <- rstudioapi::getActiveDocumentContext()$path
current_dir <- dirname(current_file)

write_csv(params, fs::path(current_dir, "params.csv"))
