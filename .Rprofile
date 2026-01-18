source("renv/activate.R")

# the following is a fix for having the R package arrow available
# this is a dependency of liesel_gam (through ryp)
# but I could not install it via CRAN on the server
# however, it could be installed via conda in the r-4.5 environment
# so what this code does is, it makes the basic library of this conda
# environment available after initializing renv.
# if I were not using renv here, this would probably not be necessary.
hpc_lib <- "/mnt/vast-standard/home/brachem1/u18549/conda/envs/r-4.5/lib/R/library"
if (dir.exists(hpc_lib)) {
    .libPaths(c(hpc_lib, .libPaths()))
}
