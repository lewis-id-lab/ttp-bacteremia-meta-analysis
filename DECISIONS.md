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

## 2026-11-20: Fixed seed added to the `clinical_failure` fits; supersedes the "untested" note above

**Supersedes** the interpretation in the first 2026-11-20 entry ("Cache rebuilt on a restored renv library…"), which called the missing-seed explanation untested, and the abstract figures of 1.74 (1.09 to 2.78) recorded there.

**What changed.** `seed = 6382` was added to the three `brm()` calls in `notebooks/clinical_failure.qmd` (`fit_pb`, `fit_pb_defgroup`, `fit_clr`). Their cached `.rds` files were deleted, and the notebook was then rendered twice, deleting the three files again before the second render.

**What was seen.** For all three fits the posterior draws were identical in the two runs (maximum absolute difference 0 across the shared parameters), with the same sampler diagnostics in both runs:

| Fit | Divergences | Treedepth hits (limit 10) | Max R-hat | Estimate (both runs) |
|---|---|---|---|---|
| `fit_pb` | 0 | 5 of 12,000 | 1.0019 | OR 1.72 (1.06 to 2.80) |
| `fit_pb_defgroup` | 0 | 0 | 1.0030 | intercept 0.357; endocarditis 0.598; other 0.254 |
| `fit_clr` | 2 of 12,000 | 0 | 1.0037 | OR 1.63 (0.24 to 9.55) |

The unseeded refit earlier the same day had given persistent bacteremia 1.74 (1.09 to 2.78), clearance 1.66 (0.24 to 9.41), definition-group coefficients 0.366 and 0.587 (intercept and endocarditis), and warnings of 3 treedepth hits and 9 divergences across the notebook's fits. The seeded fits do not reproduce those figures.

**Interpretation (assistant inference, not a human check; moderate confidence).** The missing seed is the most likely reason the `clinical_failure` estimates changed between refits while the mortality fits, which are seeded in `R/02_fit_models.R`, reproduced exactly. This is now supported by the exact reproduction under a fixed seed. It is not proven, because the unseeded fits were not rerun to confirm that they differ from each other. Reproduction across different machines or toolchains was not tested, so seeded draws may still differ there.

**Decision.** The persistent-bacteremia figures in the abstract of `index.qmd` were changed from 1.74 (1.09 to 2.78) to 1.72 (1.06 to 2.80). The Results text from the most recent partial render (persistent bacteremia 1.72 [1.06 to 2.80], clearance 1.63 [0.24 to 9.55]) was checked first and agrees with the seeded fits. The clearance figure appears only in the inline-computed text.

**Not yet done.** The complete `index.qmd` re-render did not finish. Two attempts stopped with `NotFound ... index-preview.html`, while a `quarto preview index.qmd` process (started 18:39 in a terminal) held `.quarto/preview/lock`. That link is an assistant inference with moderate confidence; the preview was not stopped. The rendered `_manuscript/index.html` and `index.docx` therefore contain the seeded Results text but the old abstract, and `index.pdf` pre-dates both. The frozen outputs and changes are not committed.

## 2026-11-23: Search, selection route and PRISMA flow rewritten after Covidence showed zero screening

**What was seen.** The Covidence PRISMA panel (author screenshot, 2026-11-21) shows 6,014 studies imported (Embase 2,877; Scopus 1,649; PubMed 1,250; Web of Science 237; ClinicalTrials.gov 1), 1,409 duplicates identified by Covidence and 0 manually, and **0 studies screened, 0 irrelevant, 0 full-text studies assessed**. Before that, `index.qmd`, `notebooks/methods.qmd`, `notebooks/abstract.qmd` and `R/04_prisma_flow.R` described a flow in which 4,605 database records led to 3,196 unique records, 2,841 excluded at title and abstract, and 355 reports sought. The author's search summary of 2026-11-21 listed Cochrane CENTRAL as not run and ClinicalTrials.gov as run, and gave 4,605 records "entering title/abstract screening" with 2,841 excluded, which is internally inconsistent (4,605 - 355 = 4,250).

**Where the 355 reports came from.** `TTP_Update_Screening_Pool.xlsx` (README and Source column, in `ttp_meta_new/new_ttp_metaanalysis`) shows the pool of 355 was made of 323 candidates from a new Elicit search (445 rows, 348 unique DOIs, after removing the 57 already extracted) and 32 from keyword tiering of the database records with PubMed abstract enrichment (19 Priority A and 13 Priority B). No title and abstract screening of the 4,605 records is recorded anywhere in the project.

**Numbers that changed or were withdrawn.**

| Item | Earlier text and figure | Now |
|---|---|---|
| Databases and registers | PubMed, Embase, Scopus, Cochrane Library, Web of Science | PubMed, Embase, Scopus, Web of Science, ClinicalTrials.gov |
| Records identified | 4,605 | 6,014 (4,605 after 1,409 duplicates) |
| Records screened | 3,196 (a short-lived assistant edit on 2026-11-21 said 4,605) | Not applicable: nothing was screened in Covidence. Both figures are withdrawn |
| Records excluded at title and abstract | 2,841 | Withdrawn (it was 3,196 - 355, not a count) |
| Trial registers | "not searched" | ClinicalTrials.gov searched (1 record, a duplicate) |
| Reference-list searching | "none" | None for the update; the two hand-searched studies (Alvarez 2012, Peri 2026) belong to the 57 baseline studies |

Unchanged: 355 sought, 53 not retrieved, 302 assessed, 259 excluded, 43 new strict inclusions, 57 baseline, 100 in the primary pool, 40 inclusive-only, 140 in the sensitivity pool.

**Decision.** The Methods, abstract, both notebooks, appendix section 1 and the figure caption were rewritten to describe the route as it happened. `R/04_prisma_flow.R` now draws the flow with Graphviz, because the PRISMA2020 template assumes screening of every database record; it checks that the counts add up. The new figure replaces `data/PRISMA_v4_prisma2020.{png,svg,pdf}`.

**Deviation from the protocol.** `PROSPERO_TTP_protocol.md` planned title/abstract screening and full-text review by two independent reviewers in Covidence with kappa reported, plus CINAHL, Cochrane CENTRAL, trial registers, preprint servers and citation tracking. The first was not done at the screening stage (candidates were selected by keyword tiering and Elicit ranking, and full texts were assessed by an LLM agent with a second agent verifying extractions), and the others were not carried out. The manuscript now says so. Whether the PROSPERO record needs an amendment, and how the deviation is worded in the Discussion, are not decided.

**Priority candidates (44 or 45).** `RESUME.md` and `TTP_Prioritized_Review_List.xlsx` count 45 (31 Priority A, 14 Priority B). The pool has 44 (30 A, 14 B). The one Priority A paper missing from the pool has DOI 10.1007/s40121-025-01274-4 (a *Pseudomonas aeruginosa* anaerobic-bottle TTP study, listed with year 2026), and the baseline database has a study `Marco2025`. *Assistant inference, moderate confidence:* it is that baseline study and was removed from the pool for that reason. It has not been checked against the DOI in the extraction workbook. The figure and text use 44.

**Still open.** The verbatim Scopus string (saved search in the author's Scopus account) and the Elicit search date and query were not available and remain bracketed in `index.qmd` and the appendix.

## 2026-11-23: Outcome block in the executed search strategies disclosed as a deviation (addendum to the entry above)

**What was seen.** An updated working copy of `search_strategies.md` (outside the repository) records that the PubMed, Embase, Web of Science and ClinicalTrials.gov strategies combined a time-to-positivity block with clinical-outcome and severity blocks, while `PROSPERO_TTP_protocol.md` and the PROSPERO draft specify two concept blocks and no outcome block, to preserve sensitivity. The same file records that the single ClinicalTrials.gov record was uploaded to Covidence as `Cochrane.xml`, and that Cochrane CENTRAL was not searched.

**Decision.** One sentence was added to the Methods in `index.qmd` and to the parameters table in appendix section 1 stating the deviation. Nothing else changed.

**Not adopted.** That file also says the Embase, Web of Science and ClinicalTrials.gov strings are parsed with unintended operator precedence, and that this explains the very different yields. This is an inference by the earlier assistant session and has not been tested on those platforms, so it was not put in the manuscript. The file's sections 4 and 5 still give 3,196 screened and 2,841 excluded, which are the withdrawn figures above.

**Scopus string added (2026-11-23).** The author supplied the verbatim Scopus query, which was added to appendix section 1.5. It has two TITLE-ABS-KEY blocks combined with AND (time to positivity terms; outcome, mortality and sepsis terms), so it also carries an outcome block.

## 2026-11-23: Correction: the single register record was Cochrane CENTRAL, not ClinicalTrials.gov

**Points back to** the first entry of 2026-11-23 and its addendum, and to the search summary of 2026-11-21.

**What was seen.** Covidence labels the one-record import `Cochrane.xml` as "ClinicalTrials.gov" (it infers the source from the file schema). The author confirmed on 2026-11-23 that the record came from Cochrane CENTRAL. The earlier search summary, and the edits made from it, had therefore stated the wrong source.

**What changed.** Sources searched are PubMed (1,250), Embase (2,877), Scopus (1,649), Web of Science (237) and Cochrane CENTRAL (1; a duplicate, so 0 retained), total 6,014. ClinicalTrials.gov was not searched; no trial register was. The string previously labelled ClinicalTrials.gov is the Cochrane CENTRAL string. `index.qmd` (abstract and Methods), `notebooks/methods.qmd`, `notebooks/abstract.qmd`, appendix section 1, `R/04_prisma_flow.R` and the figure were corrected. The first entry of 2026-11-23 still says Cochrane was dropped and ClinicalTrials.gov added; that statement is withdrawn here.

**Open.** A yield of 1 record from CENTRAL for this query is very low. *Assistant inference, low confidence:* the string may have been run in a narrow Cochrane subset or parsed differently. This has not been tested. Whether the executed string contained "bactermeia" (as in the author's source document) or "bacteraemia" is unresolved; the appendix currently shows "bacteraemia".

**Elicit query added (2026-11-23).** The author supplied the Elicit question and criteria ("Option #2: Does TTP predict the risk of antibiotic failure?"), now in appendix section 1.8. The search date was not supplied; the text says it was not recorded and that the export was in the project by May 22, 2026 (the date of the triage workbook built from it). The spelling of the Cochrane string ("bactermeia" or "bacteraemia") is still unresolved.

**Cochrane spelling resolved (2026-11-23).** The author confirmed the Cochrane CENTRAL string contained "persistent bacteremia". Appendix section 1.7 now shows that spelling. The "bactermeia" typo in the author's source documents and the "bacteraemia" in the search summary were both wrong. The unbalanced closing parenthesis in the string is kept as run.

**Elicit search date added (2026-11-23).** The author gave the Elicit search date as May 25, 2026. It replaces the earlier wording that the date was not recorded and that the export was in the project by May 22, which was an inference from a triage-workbook date and was wrong. May 25, 2026 agrees with `RESUME.md` (updated 2026-05-25), which lists the 445-row export as uploaded.
