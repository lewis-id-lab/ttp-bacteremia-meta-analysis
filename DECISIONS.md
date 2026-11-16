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

## 2026-11-16: renv set up; xfun updated to 0.62 in the project library

**What happened.** After the refit above, renv was initialised so that future refits use the same package versions. The project library was populated from the system R library (`renv::hydrate()`), so it holds the versions that produced the current cached fits and frozen outputs, including RcppParallel 5.1.11, rstan 2.32.7, StanHeaders 2.39.1, brms 2.23.0 and cmdstanr 0.9.0 (CmdStan 2.40.0, installed outside renv).

**Decisions.**

- The first `renv::snapshot()` was aborted by renv's pre-flight check: litedown 1.0 (imported by gt and markdown) requires xfun >= 0.62, but the system library had xfun 0.61. xfun was updated to 0.62 in the project library only, so the lockfile can be restored. The system library is unchanged. This is the only version in `renv.lock` that differs from the library used for the refit. xfun is a knitr/rendering utility and is not in the Stan/brms fitting chain.
- cmdstanr (used only as `backend = "cmdstanr"`) and PRISMA2020 (used by `R/04_prisma_flow.R`) were not found by renv's dependency scan. They are declared in `_dependencies.R`.
- `R/04_prisma_flow.R` did not parse: line 60 was the `![PRISMA 2020 flow diagram ...](...){#fig-prisma}` markdown from `index.qmd`, pasted into the script in commit `ef20d03`. The line was removed.

**What had been seen when this was decided.** The refitted estimates recorded in the entry above. The renv setup changed no analysis code or model settings. After the xfun update, `notebooks/clinical_failure.qmd` rendered under renv; the frozen outputs changed only in the random gt table IDs. The other notebooks and `index.qmd` have not yet been re-rendered under renv.

## 2026-11-16: Stale subgroups freeze corrected; all documents re-executed under renv

**Correction to the first entry of 2026-11-16.** The frozen results committed in `3153cb6` ("Update frozen render results after model refit") did not cover `notebooks/subgroups.qmd`. The full render that produced them used `freeze: auto`, which reuses frozen results for documents whose source has not changed, so the subgroups notebook was not re-executed and kept pre-refit estimates (for example Gram-negative OR 2.66 [1.72, 4.06], Gram-positive OR 1.48 [0.85, 2.58]). The abstract and `index.qmd` were not affected: they compute from the refitted models.

**What was done.** After R was restarted on the renv project library, every document (`notebooks/mortality-analysis.qmd`, `subgroups.qmd`, `clinical_failure.qmd`, `rob.qmd`, `methods.qmd`, then `index.qmd`) was rendered individually, which forces execution. A full `quarto render` (HTML, docx, PDF) followed. All renders succeeded with no warnings, and no models were refitted. The subgroups outputs now match the refit (Gram-negative 2.67 [1.75, 4.11], Gram-positive 1.47 [0.83, 2.50]); committed in `084b122`. In the mortality-analysis notebook, only the `sessionInfo()` output changed, which now reflects the renv library. Freeze files for `clinical_failure` and `rob` changed only in gt-generated table IDs and cell `headers` attributes, and were reverted.

**Lesson.** After a refit, re-execute each document individually (or clear `_freeze/`) before the project render; a project render alone can leave stale frozen outputs.
