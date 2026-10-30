## export_figures.R
## Exports the four journal-style figures (PDF, PNG at 300 dpi, TIFF) to figures/
## in the JAMA-style blue-grey theme.
##
## Usage (from project root):  source("R/export_figures.R")

suppressPackageStartupMessages({
  library(tidyverse)
  library(brms)
  library(posterior)
  library(ggdist)
})

source("R/01_prepare_data.R")
source("R/02_fit_models.R")
source("R/theme_jama.R")

dir.create("figures", showWarnings = FALSE)

es_all  <- prepare_effect_sizes("data/TTP_MetaAnalysis_Extraction_Complete_v4.xlsx",
                                include_inclusive_pool = FALSE, drop_contaminated_ttp = TRUE)
es_mort <- es_for_outcome(es_all, "mortality")
fits    <- fit_all_models(es_mort, cache_dir = "_brms_cache/primary")
cache   <- "_brms_cache/primary"

save_jama <- function(plot, name, width, height) {
  stem <- file.path("figures", paste0(name, "_JAMA"))
  ggsave(paste0(stem, ".pdf"),  plot, width = width, height = height, device = cairo_pdf)
  ggsave(paste0(stem, ".png"),  plot, width = width, height = height, dpi = 300)
  ggsave(paste0(stem, ".tiff"), plot, width = width, height = height, dpi = 300, compression = "lzw")
}

base_theme <- theme_jama(base_size = 11) +
  theme(plot.title = element_text(size = 14), plot.subtitle = element_text(size = 10))

# ---- 1. Posterior OR by pathogen class ------------------------------------
base_post <- pooled_summary(fits$fit_base)
gneg_post <- pooled_summary(fits$fit_gram_neg)
gpos_post <- pooled_summary(fits$fit_gram_pos)

dens <- bind_rows(
  tibble(OR = base_post$OR_draws, group = "Overall"),
  tibble(OR = gneg_post$OR_draws, group = "Gram-negative"),
  tibble(OR = gpos_post$OR_draws, group = "Gram-positive")
) |> mutate(group = factor(group, levels = c("Gram-positive", "Overall", "Gram-negative")))

p_post <- ggplot(dens, aes(x = OR, y = group, fill = group)) +
  stat_halfeye(alpha = 0.8, point_color = jama_pal[["ink"]], interval_color = jama_pal[["ink"]],
               point_size = 3, interval_size = 2, .width = 0.95, normalize = "xy") +
  geom_vline(xintercept = 1, linetype = "dashed", color = jama_ref_line) +
  scale_fill_manual(values = c("Gram-positive" = jama_pal[["mist"]], "Overall" = jama_pal[["steel"]],
                               "Gram-negative" = jama_pal[["navy"]]), guide = "none") +
  scale_x_continuous(breaks = 1:6) +
  coord_cartesian(xlim = c(0.5, 6)) +
  labs(title = "Association of short time to positivity with mortality, by Gram class",
       subtitle = "Point, posterior median; bar, 95% credible interval. Dashed line, OR = 1 (no effect).",
       x = "Pooled odds ratio (short vs long time to positivity)", y = NULL) +
  base_theme + theme(panel.grid.major.y = element_blank(), axis.text.y = element_text(size = 11))
save_jama(p_post, "posterior_OR_by_pathogen", 8, 4.8)

# ---- 2/3. Cutpoint dose-response ------------------------------------------
cutpoint_plot <- function(fit, title, xlim, breaks) {
  d   <- as_draws_df(fit)
  dat <- fit$data |>
    left_join(distinct(es_mort, study_id, yi, sei, ttp_cutpoint_hours), by = c("study_id", "yi", "sei"))
  centre <- median(dat$ttp_cutpoint_hours - dat$cutpoint_c, na.rm = TRUE)
  pred <- map_dfr(seq(xlim[1], xlim[2], by = 0.5), \(cp) {
    lo <- d$b_Intercept + d$b_cutpoint_c * (cp - centre)
    tibble(cp = cp, med = median(exp(lo)), lo = quantile(exp(lo), .025), hi = quantile(exp(lo), .975))
  })
  obs <- dat |> mutate(or = exp(yi), w = 1 / sei) |> filter(!is.na(ttp_cutpoint_hours))
  slope <- d$b_cutpoint_c
  ggplot(pred, aes(cp, med)) +
    geom_ribbon(aes(ymin = lo, ymax = hi), fill = jama_pal[["mist"]], alpha = 0.3) +
    geom_hline(yintercept = 1, linetype = "dashed", color = jama_ref_line) +
    geom_point(data = obs, aes(ttp_cutpoint_hours, or, size = w), inherit.aes = FALSE,
               color = jama_pal[["slate"]], alpha = 0.55) +
    geom_line(color = jama_pal[["navy"]], linewidth = 1.3) +
    scale_size_continuous(range = c(2, 7), guide = "none") +
    scale_x_continuous(breaks = breaks) +
    scale_y_continuous(breaks = 0:6) +
    coord_cartesian(ylim = c(0, 6)) +
    labs(title = title,
         subtitle = sprintf(paste0("Slope, %.3f log-OR per hour (OR %.2f per 10 h); P(slope < 0) = %.1f%%.\n",
                                   "Line, posterior median; band, 95%% CrI; points, observed 2x2 effect sizes ",
                                   "(size proportional to precision)."),
                            median(slope), exp(10 * median(slope)), 100 * mean(slope < 0)),
         x = "TTP cutpoint (hours)", y = "Predicted OR for mortality (short vs long TTP)") +
    base_theme
}
fit_cut   <- readRDS(file.path(cache, "fit_cutpoint.rds"))
fit_le24  <- readRDS(file.path(cache, "fit_cutpoint_le24.rds"))
save_jama(cutpoint_plot(fit_cut,  "TTP cutpoint dose-response for all-cause mortality",
                        c(6, 96), seq(12, 96, 12)), "ttp_cutpoint_doseresponse", 8, 5)
save_jama(cutpoint_plot(fit_le24, "TTP cutpoint dose-response for all-cause mortality (cutpoints \u2264 24 h)",
                        c(6, 24), seq(6, 24, 3)), "ttp_cutpoint_doseresponse_le24h", 8, 5)

# ---- 4. Posterior ratio of ORs, Gram-negative / Gram-positive --------------
b     <- as_draws_df(readRDS(file.path(cache, "fit_metareg.rds")))$b_pathogen_classgram_positive
ratio <- tibble(ratio = exp(-b))
q     <- quantile(ratio$ratio, c(.5, .025, .975))
p_ratio <- ggplot(ratio, aes(x = ratio)) +
  stat_halfeye(fill = jama_pal[["steel"]], alpha = 0.85, point_color = jama_pal[["ink"]],
               interval_color = jama_pal[["ink"]], point_size = 3, interval_size = 2,
               .width = 0.95, normalize = "xy") +
  geom_vline(xintercept = 1, linetype = "dashed", color = jama_ref_line) +
  annotate("text", x = 2.55, y = 0.5, hjust = 0, size = 3.6, color = jama_pal[["ink"]],
           label = sprintf("Median ratio, %.2f (95%% CrI, %.2f-%.2f)\nP(ratio > 1) = %.0f%%",
                           q[1], q[2], q[3], 100 * mean(ratio$ratio > 1))) +
  scale_x_continuous(breaks = seq(0.5, 4, 0.5)) +
  coord_cartesian(xlim = c(0.5, 4)) +
  scale_y_continuous(breaks = NULL) +
  labs(title = "Posterior contrast: TTP-mortality association by Gram class",
       subtitle = paste0("Ratio > 1 indicates a stronger short-TTP mortality association in Gram-negative bacteremia.\n",
                         "Point, posterior median; bar, 95% credible interval. Dashed line, no difference (ratio = 1)."),
       x = "Ratio of odds ratios (Gram-negative \u00f7 Gram-positive)", y = NULL) +
  base_theme + theme(panel.grid.major.y = element_blank())
save_jama(p_ratio, "metareg_ratio_GNeg_vs_GPos", 8, 4.4)
message("Figures written to figures/")
