# Decision record

Dated entries, newest last. Earlier entries are not rewritten; corrections are added as new entries that point back.

## 2026-11-16: Full refit of brms models; RcppParallel pinned to 5.1.11

**What happened.** `index.qmd` stopped rendering: compiled rstan models failed to load (`symbol not found ... tbb::task_scheduler_init::initialize`). The R library had RcppParallel 6.2.1, whose bundled oneTBB removed that API, with rstan 2.32.7 and StanHeaders 2.39.1. `_brms_cache/` was empty, so every model had to be refitted.

**Decision.** Keep the rstan backend (as stated in the appendix) and downgrade RcppParallel to 5.1.11 instead of switching models to cmdstanr. Refit all models with unchanged code, priors, seeds and sampler settings.

**What had been seen when this was decided.** Only the render error and the empty cache; no refitted results had been inspected. After the refit, the hard-coded estimates in the abstract and the Figure 1 caption (`notebooks/mortality-analysis.qmd`, `fig-pathogen-posteriors`) no longer matched the inline-computed body text, and were updated to the refitted values:

| Estimate | Before | After refit |
|---|---|---|
| Pooled mortality OR (95% CrI) | 2.06 (1.66 to 2.54) | 2.05 (1.66 to 2.57) |
| 95% prediction interval | 0.51 to 8.40 | 0.51 to 8.50 |
| Gram-negative OR | 2.65 (1.77 to 4.07) | 2.67 (1.75 to 4.11) |
| Gram-positive OR | 1.47 (0.81 to 2.60) | 1.47 (0.83 to 2.50) |
| Persistent bacteremia OR | 1.72 (1.07 to 2.84) | 1.72 (1.09 to 2.79) |

Median I² (62%) and the frequentist trim-and-fill estimate (1.51; 1.23 to 1.86) were unchanged. No conclusion changed.

**Interpretation (assistant inference, not a human check; moderate confidence).** The differences are Monte Carlo variation: seeds are fixed, but the Stan toolchain differs from the one that produced the earlier fits, so draws are not reproduced exactly. Refitting under the earlier toolchain would settle this, but its versions were not recorded. Package versions should be pinned (for example with renv) so that future refits reproduce exactly.
