# Packages renv cannot detect from the code, declared so renv::snapshot() records them.
# cmdstanr: used only via brm(backend = "cmdstanr") in notebooks/clinical_failure.qmd
# PRISMA2020: used by R/04_prisma_flow.R
library(cmdstanr)
library(PRISMA2020)
