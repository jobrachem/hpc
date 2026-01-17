library(tidyverse)
library(fs)

jobsdirs <- path(path_wd(), "jobs") |>
  dir_ls()
data_dir <- path(path_wd(), "data", "out")
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
    out[[subdir]][[i]] <- df

    i <- i + 1
  }
}

out |> names()

# ..............................................................................
# ---- Save outputs ----
# ..............................................................................

for (i in seq_along(out)) {
  out_df <- out[[i]] |> bind_rows()
  df_name <- paste0(names(out)[[i]], ".csv")
  write_csv(out_df, path(data_dir, df_name))
}
