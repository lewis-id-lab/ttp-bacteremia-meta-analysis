#' Sensitivity analyses for the primary mortality model (supplementary appendix).
#'
#' These refit the primary model (fit_base) and leave the primary analysis
#' unchanged. Requires R/02_fit_models.R (fit_one() and the default priors).
#'
#' - Prior sensitivity: same data, alternative priors for mu and tau.
#' - Subset sensitivity: same model and priors, restricted to low risk of bias,
#'   low or moderate risk of bias, or adjusted reported estimates.

.base_formula <- bf(yi | se(sei) ~ 1 + (1 | study_id))

prior_specs <- list(
  tau_halfnormal_0.5 = list(
    label  = "tau ~ Half-Normal(0, 0.5)",
    priors = c(.prior_intercept, prior(normal(0, 0.5), class = "sd"))),
  tau_halfcauchy_1 = list(
    label  = "tau ~ Half-Cauchy(0, 1) (wider)",
    priors = c(.prior_intercept, prior(cauchy(0, 1), class = "sd"))),
  mu_vague = list(
    label  = "mu ~ Normal(0, 10) (vague)",
    priors = c(prior(normal(0, 10), class = "Intercept"), .prior_tau)),
  mu_skeptical = list(
    label  = "mu ~ Normal(0, 0.35) (skeptical; 95% prior OR 0.5 to 2)",
    priors = c(prior(normal(0, 0.35), class = "Intercept"), .prior_tau))
)

fit_prior_sensitivity <- function(es_mort, cache_dir = "_brms_cache/sensitivity_priors") {
  dir.create(cache_dir, showWarnings = FALSE, recursive = TRUE)
  lapply(setNames(names(prior_specs), names(prior_specs)), function(nm)
    fit_one(es_mort, formula = .base_formula, priors = prior_specs[[nm]]$priors,
            name = paste0("fit_", nm), cache_dir = cache_dir))
}

subset_specs <- list(
  rob_low      = list(label = "Low risk of bias only",
                      keep  = function(d) d$rob_overall %in% "low"),
  rob_low_mod  = list(label = "Low or moderate risk of bias (high and critical excluded)",
                      keep  = function(d) d$rob_overall %in% c("low", "moderate")),
  adjusted     = list(label = "Adjusted reported estimates only",
                      keep  = function(d) d$es_source %in% "reported_adjusted")
)

fit_subset_sensitivity <- function(es_mort, cache_dir = "_brms_cache/sensitivity_subsets") {
  dir.create(cache_dir, showWarnings = FALSE, recursive = TRUE)
  fits <- lapply(setNames(names(subset_specs), names(subset_specs)), function(nm) {
    d <- es_mort[subset_specs[[nm]]$keep(es_mort), ]
    if (nrow(d) < 3) return(NULL)
    fit_one(d, formula = .base_formula, priors = c(.prior_intercept, .prior_tau),
            name = paste0("fit_", nm), cache_dir = cache_dir)
  })
  Filter(Negate(is.null), fits)
}
