#' PRISMA 2020 flow diagram for the 2026 update, built with the PRISMA2020 package.
#'
#' Revised 2026-11-23. Replaces a hand-drawn Graphviz flow with the official
#' PRISMA 2020 template, which now fits: the earlier script avoided the package
#' on the grounds that the template "assumes title/abstract screening of every
#' database record", but the records WERE screened — by a staged automated
#' procedure (deterministic keyword rule set, large language model adjudication
#' of abstracts for records without a detected TTP signal, then relevance
#' triage) rather than by two human reviewers in Covidence. That is a screening
#' method to describe, not an absent stage.
#'
#' Two further changes from the earlier flow:
#'
#'  1. No separate identification route is drawn (`other = FALSE`). Every one of
#'     the 355 reports sought for full text is present in the database export
#'     (333 matched on DOI, the remaining 22 on normalised title), as are all 43
#'     newly included studies, so the AI-assisted semantic search ranked records
#'     the databases had already retrieved rather than contributing any of its
#'     own. It is reported in the Methods as a prioritisation aid.
#'  2. The 57 studies carried forward from the earlier review enter through the
#'     previous-review column (`previous = TRUE`).
#'
#' The `dbr_notretrieved_reports` box is relabelled "Reports excluded at
#' retrieval triage": those 53 reports were not unobtainable, they were screened
#' out at download triage as conference abstracts, non-English papers or
#' methods-only papers. Keeping them in that slot preserves the 355 - 53 = 302
#' arithmetic while labelling them for what they were.
#'
#' Residual duplication is disclosed in the figure caption and appendix section
#' 1.2 rather than in the diagram: Covidence removed 1,409 duplicates before
#' screening and a further 1,351 duplicate records were identified only after
#' export, so 3,254 of the 4,605 screened records were unique. Screening was
#' applied to the 4,605 as exported, so the diagram is drawn on that basis and
#' every box remains arithmetically consistent with what was done.
#'
#' Sources of the counts:
#'   Covidence Imports panel ...................... 6,014 identified; 1,409 duplicates
#'   screening_ledger_4605.csv .................... 1,351 residual duplicates; 3,254 unique
#'   TTP_Update_Screening_Pool.xlsx ............... 355 reports sought
#'   PDF_Extraction_Inclusion_Exclusion_Report.md . 302 assessed; 259 excluded; 43 included
#'   Inclusive_Rescreen_Addendum.md ............... 54 re-screened; 40 added to the sensitivity pool
#'
#' Usage, from the project root:
#'   source("R/04_prisma_flow.R")          # writes the figure to all three locations
#'   MAKE_PRISMA=1 Rscript R/04_prisma_flow.R

flow_counts <- list(
  # --- Previous review --------------------------------------------------
  previous_studies = 57,
  previous_reports = 57,

  # --- Identification ---------------------------------------------------
  database_results = 6014,
  embase           = 2877,
  scopus           = 1649,
  pubmed           = 1250,
  wos              = 237,
  fifth_source     = 1,
  # TODO(author): the one-record import is recorded as Cochrane CENTRAL in
  # DECISIONS.md (2026-11-23) and as ClinicalTrials.gov in search_strategies.md
  # (2026-11-21). Resolve before submission. If it was a trial register, move
  # the count from `fifth_source` to `register_results`, drop it from
  # `database_results` (6,013) and set `detail_registers = TRUE` below.
  fifth_source_label = "Cochrane CENTRAL",
  register_results   = 0,

  duplicates          = 1409,   # removed by Covidence before screening
  duplicates_residual = 1351,   # identified only after export; see caption, not drawn
  excluded_automatic  = 0,
  excluded_other      = 0,

  # --- Screening --------------------------------------------------------
  records_screened = 4605,      # as screened; 3,254 of these were unique
  records_unique   = 3254,
  records_excluded = 4250,      # 4,605 - 355
  sought           = 355,
  triage_excluded  = 53,        # conference abstract only / non-English / methods-only

  # --- Eligibility ------------------------------------------------------
  assessed      = 302,
  excluded_ft   = 259,
  ex_design     = 104,
  ex_no_ttp     = 65,
  ex_no_assoc   = 54,
  ex_no_outcome = 29,
  ex_duplicate  = 5,
  ex_not_bsi    = 2,

  # --- Included ---------------------------------------------------------
  new_studies    = 43,
  total_studies  = 100,

  # --- Not drawn (sensitivity pool; stated in the caption) --------------
  inclusive_added  = 40,
  sensitivity_pool = 140
)

# NOTE(author): the extraction workbook reconciles the primary pool as 58
# baseline + 42 new, because Barberan2010 appears among the 43 inclusions in
# PDF_Extraction_Inclusion_Exclusion_Report.md but is absent from tbl_study and
# from the Covidence export. The total of 100 is unaffected. Resolve which split
# is correct and adjust `new_studies` / `previous_studies` if needed.

check_counts <- function(n = flow_counts) {
  stopifnot(
    n$database_results == n$embase + n$scopus + n$pubmed + n$wos + n$fifth_source,
    n$records_screened == n$database_results + n$register_results - n$duplicates -
                          n$excluded_automatic - n$excluded_other,
    n$records_unique   == n$records_screened - n$duplicates_residual,
    n$sought           == n$records_screened - n$records_excluded,
    n$assessed         == n$sought - n$triage_excluded,
    n$new_studies      == n$assessed - n$excluded_ft,
    n$excluded_ft      == n$ex_design + n$ex_no_ttp + n$ex_no_assoc +
                          n$ex_no_outcome + n$ex_duplicate + n$ex_not_bsi,
    n$total_studies    == n$new_studies + n$previous_studies,
    n$sensitivity_pool == n$total_studies + n$inclusive_added
  )
  invisible(TRUE)
}

#' Build the PRISMA2020 input table.
#'
#' The schema is taken from the package's own template (`extdata/PRISMA.csv`)
#' rather than from a CSV kept in this repository, so the table always carries
#' every column the installed version expects. PRISMA2020 1.1.5 requires `data`,
#' `node`, `box`, `description`, `boxtext`, `tooltips`, `url` and `n`; a
#' four-column table silently fails with "argument is of length zero".
prisma_rows <- function(n = flow_counts) {
  check_counts(n)

  tmpl_path <- system.file("extdata", "PRISMA.csv", package = "PRISMA2020")
  if (!nzchar(tmpl_path))
    stop("PRISMA2020 template not found; is the PRISMA2020 package installed?")
  dat <- utils::read.csv(tmpl_path, stringsAsFactors = FALSE)

  counts <- list(
    previous_studies = n$previous_studies,
    previous_reports = n$previous_reports,
    database_results = n$database_results,
    database_specific_results = sprintf(
      "Embase, %d; Scopus, %d; PubMed (MEDLINE), %d; Web of Science Core Collection, %d; %s, %d",
      n$embase, n$scopus, n$pubmed, n$wos, n$fifth_source_label, n$fifth_source),
    register_results = n$register_results,
    register_specific_results = "",
    website_results = 0, organisation_results = 0, citations_results = 0,
    duplicates = n$duplicates,
    excluded_automatic = n$excluded_automatic,
    excluded_other = n$excluded_other,
    records_screened = n$records_screened,
    records_excluded = n$records_excluded,
    dbr_sought_reports = n$sought,
    dbr_notretrieved_reports = n$triage_excluded,
    other_sought_reports = 0, other_notretrieved_reports = 0,
    dbr_assessed = n$assessed,
    dbr_excluded = paste(
      sprintf("Ineligible study design, %d", n$ex_design),
      sprintf("TTP not measured, %d", n$ex_no_ttp),
      sprintf("No quantitative TTP-outcome association, %d", n$ex_no_assoc),
      sprintf("No clinical outcome reported, %d", n$ex_no_outcome),
      sprintf("Duplicate publication, %d", n$ex_duplicate),
      sprintf("Population not bloodstream infection, %d", n$ex_not_bsi),
      sep = "; "),
    other_assessed = 0, other_excluded = "",
    new_studies = n$new_studies, new_reports = n$new_studies,
    total_studies = n$total_studies, total_reports = n$total_studies
  )

  # Box labels that differ from the PRISMA 2020 defaults, with the reason.
  labels <- list(
    duplicates = "Duplicate records removed by Covidence",
    records_excluded = "Records excluded by the staged automated screen",
    dbr_notretrieved_reports = "Reports excluded at retrieval triage"
  )

  for (k in names(counts)) {
    i <- which(dat$data == k)
    if (length(i) == 1L) dat$n[i] <- as.character(counts[[k]])
  }
  for (k in names(labels)) {
    i <- which(dat$data == k)
    if (length(i) == 1L) dat$boxtext[i] <- labels[[k]]
  }
  dat
}

#' Render the flow diagram and write it everywhere the Quarto documents read it.
#'
#' `index.qmd` loads PRISMA_v4_prisma2020.png from the project root and
#' `notebooks/methods.qmd` loads PRISMA_v4_prisma2020.svg from notebooks/, so
#' both copies are written here. Writing them from one place avoids the stale
#' copies recorded in DECISIONS.md.
make_prisma_flow <- function(stem = "PRISMA_v4_prisma2020",
                             out_dir = "data",
                             copy_png_to = ".",
                             copy_svg_to = "notebooks",
                             fontsize = 10,
                             png_width = 2600) {
  plot <- PRISMA2020::PRISMA_flowdiagram(
    PRISMA2020::PRISMA_data(prisma_rows()),
    interactive       = FALSE,
    previous          = TRUE,    # 57 studies from the earlier review
    other             = FALSE,   # no separate identification route; see header
    detail_databases  = TRUE,
    detail_registers  = FALSE,
    fontsize          = fontsize,
    font              = "Helvetica"
  )

  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
  base <- file.path(out_dir, stem)
  # PNG is rasterised, so it is written wide enough for print: 2,600 px is about
  # 400 dpi across a 6.5-inch column. The default (~890 px, ~135 dpi) is too
  # coarse for a journal figure. SVG and PDF are vector and need no width.
  PRISMA2020::PRISMA_save(plot, filename = paste0(base, ".png"),
                          filetype = "PNG", overwrite = TRUE, width = png_width)
  for (ft in c("SVG", "PDF")) {
    PRISMA2020::PRISMA_save(plot,
                            filename  = paste0(base, ".", tolower(ft)),
                            filetype  = ft,
                            overwrite = TRUE)
  }

  if (!is.null(copy_png_to))
    file.copy(paste0(base, ".png"), file.path(copy_png_to, paste0(stem, ".png")),
              overwrite = TRUE)
  if (!is.null(copy_svg_to) && dir.exists(copy_svg_to))
    file.copy(paste0(base, ".svg"), file.path(copy_svg_to, paste0(stem, ".svg")),
              overwrite = TRUE)

  invisible(plot)
}

if (sys.nframe() == 0 || identical(Sys.getenv("MAKE_PRISMA"), "1")) make_prisma_flow()
