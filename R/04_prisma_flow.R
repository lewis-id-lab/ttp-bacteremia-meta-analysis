#' PRISMA 2020 flow diagram (PRISMA2020 package), "updated review" template.
#'
#' Counts are the strict-criterion flow reported in index.qmd (Methods, "Search
#' strategy and study selection"). The inclusive re-screen (40 further studies,
#' sensitivity pool) is not part of the PRISMA2020 template; it is stated in the
#' figure caption in index.qmd.
#'
#' Usage: source("R/04_prisma_flow.R"); writes data/PRISMA_v4_prisma2020.{png,svg,pdf}

suppressPackageStartupMessages(library(PRISMA2020))

prisma_counts <- list(
  previous_studies         = 57,
  previous_reports         = 57,
  database_results         = 4605,
  register_results         = 0,
  duplicates               = 1409,
  excluded_automatic       = 0,
  excluded_other           = 0,
  records_screened         = 3196,
  records_excluded         = 2841,
  dbr_sought_reports       = 355,
  dbr_notretrieved_reports = 53,
  dbr_assessed             = 302,
  dbr_excluded             = paste("Ineligible design, 104; No TTP measured, 65;",
                                   "No quantitative TTP-outcome association, 54;",
                                   "No clinical outcome, 29; Duplicate, 5;",
                                   "Not bloodstream infection, 2"),
  new_studies              = 43,
  new_reports              = 43,
  total_studies            = 100,
  total_reports            = 100
)

prisma_data <- function(counts = prisma_counts) {
  d <- read.csv(system.file("extdata", "PRISMA.csv", package = "PRISMA2020"))
  d$n <- as.character(d$n)
  idx <- match(names(counts), d$data)
  stopifnot(!anyNA(idx))
  d$n[idx] <- as.character(unlist(counts))
  # Template rows we do not use are blanked so their boxes are omitted
  d$n[d$data %in% c("other_sought_reports", "other_notretrieved_reports",
                    "other_assessed", "other_excluded",
                    "website_results", "organisation_results", "citations_results",
                    "register_specific_results", "database_specific_results")] <- "0"
  PRISMA_data(d)
}

make_prisma_flow <- function(out_dir = "data", stem = "PRISMA_v4_prisma2020") {
  fd <- PRISMA_flowdiagram(prisma_data(), previous = TRUE, other = FALSE,
                           detail_databases = FALSE, detail_registers = FALSE,
                           interactive = FALSE, fontsize = 11)
  for (ext in c("png", "svg", "pdf"))
    PRISMA_save(fd, filename = file.path(out_dir, paste0(stem, ".", ext)),
                filetype = ext, overwrite = TRUE)
  invisible(fd)
}

if (sys.nframe() == 0 || identical(Sys.getenv("MAKE_PRISMA"), "1")) make_prisma_flow()