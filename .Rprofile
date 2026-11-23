source("renv/activate.R")

# Use the project-local CmdStan installation when available.
cmdstan_dir <- file.path(getwd(), ".cmdstan", "cmdstan-2.40.0")
if (dir.exists(cmdstan_dir)) Sys.setenv(CMDSTAN = cmdstan_dir)
