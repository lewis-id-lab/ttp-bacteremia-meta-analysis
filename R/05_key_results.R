#' Key results quoted in the abstract and Importance statement of index.qmd.
#'
#' index.qmd sources this file from inline R inside its YAML front matter, which
#' runs before the setup chunk, and then reads values with kr("key"). Results are
#' taken from the cached brms fits, so render the analysis notebooks first.

if (!exists("prepare_effect_sizes", mode = "function")) source("R/01_prepare_data.R")
if (!exists("pooled_summary", mode = "function")) source("R/02_fit_models.R")

.kr_values <- local({
  es_all <- suppressMessages(prepare_effect_sizes(
    "data/TTP_MetaAnalysis_Extraction_Complete_v4.xlsx",
    include_inclusive_pool = FALSE, drop_contaminated_ttp = TRUE))
  es_mort <- es_for_outcome(es_all, "mortality")

  post <- function(name, dir = "_brms_cache/primary")
    pooled_summary(readRDS(file.path(dir, paste0(name, ".rds"))))
  base <- post("fit_base")
  gneg <- post("fit_gram_neg")
  gpos <- post("fit_gram_pos")
  pb   <- post("fit_pb")

  rma_mort <- metafor::rma(yi = yi, sei = sei, data = es_mort, method = "REML")
  tf <- metafor::trimfill(rma_mort)

  ci <- function(p) sprintf("%.2f to %.2f", p$ci_OR[1], p$ci_OR[2])
  or_cri <- function(p) sprintf("OR %.2f; 95%% CrI, %s", p$median_OR, ci(p))

  list(
    n_studies      = attr(es_all, "n_studies"),
    n_mort_studies = dplyr::n_distinct(es_mort$study_id),
    n_es           = nrow(es_mort),
    base_or        = sprintf("%.2f", base$median_OR),
    base_ci        = ci(base),
    base_i2        = sprintf("%.0f%%", base$median_i2),
    base_pi        = sprintf("%.2f to %.2f", base$pi_OR[1], base$pi_OR[2]),
    gneg           = or_cri(gneg),
    gpos           = or_cri(gpos),
    pb             = or_cri(pb),
    tf             = sprintf("%.2f (95%% CI, %.2f to %.2f)",
                             exp(tf$beta[1]), exp(tf$ci.lb), exp(tf$ci.ub))
  )
})

kr <- function(key) {
  if (!key %in% names(.kr_values)) stop("Unknown key-result name: ", key)
  .kr_values[[key]]
}
