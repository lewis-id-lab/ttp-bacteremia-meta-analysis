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

## 2026-11-16: Appendix published as a manuscript notebook; extraction workbook confirmed study-level before republishing

**Appendix.** `appendix.qmd` was added to the manuscript notebooks in `_quarto.yml` (commit `3a84e8e`), so the site now has an HTML version (`appendix-preview.html`) that the article links to. Its Word output (`appendix.docx`) is unchanged. A new section 6 lists the R packages used, with versions taken from `renv.lock` (`c29ceda`). Citations for brms, rstan, metafor, posterior, loo, lme4, tidyverse and PRISMA2020 come from `citation()`. They are kept in `packages.bib`, because `R/03_build_references.R` regenerates `references.bib` in full.

**Extraction workbook on the public site.** `data/` is a manuscript resource, so `data/TTP_MetaAnalysis_Extraction_Complete_v4.xlsx` is published on GitHub Pages. Before the site was republished, the workbook was checked in two steps:

- *Assistant check (automated, not a human review).* Every sheet holds study-, arm- or outcome-level aggregates: counts, means, percentages and effect estimates. The smallest arm has n = 11. The 1,716 distinct free-text values summarise what published reports say. No reviewer names, initials or contact details were found; update rows record the extractor as "Cowork agent".
- *Human confirmation.* The project lead confirmed that the workbook contains only study-level data from published reports.

`data/` was therefore kept in the site resources. The site was published with `quarto publish gh-pages --no-render` (gh-pages `267ef38`), and the live appendix page was checked.

## 2026-11-16: Workaround for missing figures on the HTML article page

**What was seen.** After the site was republished (gh-pages `267ef38`), six of the seven figures on the live article page returned 404: all the figures embedded from notebooks under `index_files/figure-html/`. The PRISMA diagram, which is served from `data/`, loaded. The October site (gh-pages `6ded9aa`) had these files.

**Diagnosis.** When html, docx and pdf are rendered together, Quarto 1.9.35 writes the article's embedded figures to `_manuscript/_tex/index_files/` but not to `_manuscript/index_files/`, where `index.html` links to them. Rendering html alone puts them in the right place. The root cause inside Quarto was not established. quarto-cli issue #14613 shows the same symptom, but it was Windows-specific and fixed for 1.10, so this may be a different problem. Putting `html` last in the format list did not help and was reverted.

**Workaround.** `R/post_render_html_figures.R` runs as a project `post-render` script. It copies any `index_files/figure-html/` image that `index.html` links to but that is missing, taking it from `_manuscript/_tex/` or `_freeze/index/`. When nothing is missing it does nothing, so it can be removed once a Quarto release no longer needs it. Check by rendering, deleting the script, and confirming the figures are still present.

**Related changes.** While debugging, the appendix notebook page stopped being produced, and its package citations were unresolved when its frozen results were reused. Two changes fixed this:

- `packages.bib` was added to the project-level `bibliography` in `_quarto.yml`.
- Quarto's `.quarto/` cache was cleared; it had accumulated many stale session folders. This is an assistant inference with moderate confidence; it is not confirmed which of the two changes was needed.

After both, a full render produced all article figures and the appendix page with no warnings. Committed in `81c36f4`.

**Known leftover.** A small `_freeze/` folder of old PRISMA `.svg` copies, about 200 KB, is copied into the site output. It comes from the `../data/` image path in `notebooks/methods.qmd`; it is harmless and was not changed.

## 2026-11-20: Cache rebuilt on a restored renv library; persistent-bacteremia and clearance estimates differ slightly from the 2026-11-16 refit

**Points back to** the first entry of 2026-11-16 (full refit) and its table of refitted estimates.

**What happened.** `_brms_cache/` was empty again, so `index.qmd` did not render. `renv::restore()` was run for the project (183 packages). Compiling `systemfonts` and `textshaping` needed the Homebrew freetype library on the linker path; this was set for one R session only, through a temporary `R_MAKEVARS_USER` file outside the project. No project or home-directory settings were changed. cmdstanr 0.9.0 and CmdStan 2.40.0 were found. Following the order in `README.md`, `notebooks/mortality-analysis.qmd`, `notebooks/clinical_failure.qmd` and then `index.qmd` were rendered (the last also rendered the other notebook previews and the PDF). All three renders exited with code 0 and the logs showed no render warnings.

**What had been seen when this was decided.** The regenerated frozen outputs were compared with the committed ones.

| Estimate | 2026-11-16 refit (committed) | 2026-11-20 refit |
|---|---|---|
| Persistent bacteremia OR (95% CrI) | 1.72 (1.09 to 2.79) | 1.74 (1.09 to 2.78) |
| Microbiological clearance OR (95% CrI) | 1.66 (0.23 to 9.83) | 1.66 (0.24 to 9.41) |
| Persistent-bacteremia definition-group meta-regression: intercept; endocarditis versus duration | 0.356; 0.596 | 0.366; 0.587 |

- The mortality results were unchanged at the precision printed: pooled OR 2.05 (1.66 to 2.57), median I² 62%, 95% prediction interval 0.51 to 8.50, Gram-negative OR 2.67 (1.75 to 4.11), Gram-positive OR 1.47 (0.83 to 2.50), trim-and-fill 1.51 (1.23 to 1.86), Egger t = 6.19. In the mortality-analysis frozen output the only differences were the `sessionInfo()` package listing, random gt table IDs, and a dropped "package built under R version" warning. That file was reverted to its committed version.
- The `clinical_failure` output has two Stan warnings that the committed version does not: 3 of 12,000 post-warm-up transitions hit the maximum treedepth limit of 10, and 9 of 12,000 ended with a divergence. They have not been matched to individual fits.

**Decision.** The persistent-bacteremia figures in the abstract of `index.qmd` were changed from 1.72 (1.09 to 2.79) to 1.74 (1.09 to 2.78), to agree with the inline-computed Results and Discussion. No other hard-coded estimate in `index.qmd` needed changing. The new `clinical_failure` and `index` frozen outputs have not yet been committed.

**Interpretation (assistant inference, not a human check; low to moderate confidence).** The cause of the shift is not established. One observation bears on it. The mortality fits go through `R/02_fit_models.R`, which passes a fixed seed, and they reproduced exactly. The three `brm()` calls in `notebooks/clinical_failure.qmd` (`fit_pb`, `fit_pb_defgroup`, `fit_clr`) set no `seed`, so their draws would be expected to differ on every refit whatever the toolchain. If that is the cause, the statement above that "seeds are fixed" holds for the mortality fits only. This has not been tested. Adding a seed to those calls, refitting twice and checking that the estimates agree would settle it. It would also show whether the treedepth and divergence warnings persist. Until then, treat the persistent-bacteremia and clearance estimates as dependent on the run, and note that the abstract hard-codes the persistent-bacteremia figures, so they can fall out of step with the Results after any refit.

**Open, not decided.** The leftover PRISMA `.svg` copies noted above recurred: each render writes a new `_freeze/index/figure-{docx,html,ipynb}/<uuid>-1-../data/` folder. No frozen output or `index.html` refers to them. Whether to delete them and untrack the 10 already-committed ones is not yet decided.

## 2026-11-20: Stray PRISMA `.svg` copies under `_freeze/` untracked and ignored (reverses the "known leftover" note of 2026-11-16)

**Reverses** the "Known leftover" paragraph of the 2026-11-16 entry "Workaround for missing figures on the HTML article page", which left these copies in place as harmless. That entry is not rewritten, and the "Open, not decided" item in the entry above is now decided.

**What was seen.** Every render of `index.qmd` writes a new UUID-named folder `_freeze/index/figure-{docx,html,ipynb}/<uuid>-1-../data/` holding a copy of a PRISMA `.svg`. Ten such files were tracked in git (3 of `PRISMA_v4_prisma2020.svg`, 7 of `PRISMA_v4_update.svg`), and the render of 2026-11-20 added three untracked ones. No `_freeze` JSON file and no `_manuscript/index.html` refers to them. The three new copies are byte-identical to `data/PRISMA_v4_prisma2020.svg`. The tracked `PRISMA_v4_update.svg` copies were not compared with anything, because `data/` no longer holds that file. The cause is not established beyond the earlier attribution to the `../data/` image path in `notebooks/methods.qmd`.

**Decision.** The three untracked folders were deleted. The ten tracked files were removed from the git index with `git rm --cached` (they stay on disk, and git history keeps them). `_freeze/index/figure-*/*-1-..` was added to `.gitignore`. This affects git only: the site output still receives whichever copies exist on disk at render time. The staged removals have not been committed.
