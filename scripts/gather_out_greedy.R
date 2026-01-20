# This script will gather data from all job directories in JOBS_DIRECTORY
# It will aim to reduce the number of files as much as possible.
# Say, your output directories are structured like this:

# jobs/
#   001-demo-knitr/
#     out/
#       results/
#         results-row0000.csv
#         results-row0001.csv
#   002-demo-jupyter/
#     out/
#       results/
#         results-row0000.csv
#         results-row0001.csv

# Then this script will collect all data in the /out/results/ directories
# into a single results.csv dataframe. The resulting dataframe will be:

# data/out/jobs/results.csv

# So the assumption is that output data in subdirectories directories
# of the jobs' out/ directories follow a structure that fits together and
# thus allows this script to concatenate the dataframe row-wise.

library(tidyverse)
library(fs)

JOBS_DIRECTORY <- "jobs"

jobsdirs <- path(path_wd(), JOBS_DIRECTORY) |>
  dir_ls()
data_dir <- path(path_wd(), "data", "out", JOBS_DIRECTORY)
data_dir |> dir_create()


# ..............................................................................
# ---- Gather output directories ----
# ..............................................................................

exclude <- NULL # vector of strings (job directory starts) or NULL
include <- NULL # vector of strings (job directory starts) or NULL

out_dirs <- list()
i <- 1
for (dir in jobsdirs) {
  if (str_starts(fs::path_file(dir), "_")) {
    next
  }

  if (!is.null(exclude)) {
    if (any(str_starts(fs::path_file(dir), exclude))) {
      next
    }
  }

  if (!is.null(include)) {
    if (any(str_starts(fs::path_file(dir), include[, 1]))) {
      j <- str_which(fs::path_file(dir), include[, 1])
      out_dirs[[i]] <- path(dir, include[j, 2])
      i <- i + 1
    }
  }

  this_out_dir <- path(dir, "out")

  if (dir_exists(this_out_dir)) {
    out_dirs[[i]] <- this_out_dir
    i <- i + 1
  }
}

# ..............................................................................
# ---- Get unique output directory names ----
# ..............................................................................

# get list of unique output directory names
out_dir_names <- map(out_dirs, function(x) dir_ls(x) |> path_file()) |>
  unlist() |>
  unique()

# ..............................................................................
# ---- Load all output directories ----
# ..............................................................................

out <- list()

i <- 1
for (dir in out_dirs) {
  for (subdir in out_dir_names) {
    subdir_path <- path(dir, subdir)

    if (!dir_exists(subdir_path)) {
      cat("Does not exist: ", subdir_path, "\n")
      next
    }

    cat("Reading: ", subdir_path, "\n")
    df <- tryCatch(
      {
        tmp <- subdir_path |>
          dir_ls() |>
          read_csv(show_col_types = FALSE)

        tmp
      },
      error = function(e) {
        cat("Error. Trying more robust, but slower approach.", "\n")
        subdir_path |>
          dir_ls() |>
          map(function(x) {
            tmp <- read_csv(x, show_col_types = FALSE)
            tmp
          }) |>
          bind_rows()
      }
    )
    jobname <- jobsdirs[i] |> fs::path_file()
    out[[subdir]][[jobname]] <- df

    i <- i + 1
  }
}

out |> names()

# ..............................................................................
# ---- Save outputs ----
# ..............................................................................

choice <- utils::menu(
  c("Yes", "No"),
  title = str_glue("Do you want to OVERWRITE existing data, if it exists?")
)

cat("\n\nStarting export", "\n")
for (i in seq_along(out)) {
  out_df <- out[[i]] |> bind_rows()
  df_name <- paste0(names(out)[[i]], ".csv")
  file_name <- path(data_dir, df_name)

  cat("Data type: \t", names(out)[i], "\ndf: \t\t", df_name, "\n")

  if (fs::file_exists(file_name)) {
    if (choice == 1) {
      cat("\t\t Overwriting data.")
      write_csv(out_df, file_name)
    } else {
      cat("\t\t File exists. Did not write data.")
    }
  } else {
    cat("\t\t Writing data.")
    write_csv(out_df, file_name)
  }

  cat("\n\n")
}
