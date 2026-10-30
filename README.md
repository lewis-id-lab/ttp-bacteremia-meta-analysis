# Blood culture time to positivity and mortality in bacteremia

Quarto manuscript project (systematic review and Bayesian meta-analysis) prepared for submission to *Journal of Clinical Microbiology*.

## Structure

- `index.qmd` - the manuscript (abstract, Introduction, Methods, Results, Discussion)
- `notebooks/` - analysis notebooks embedded in or linked from the article (mortality, subgroups, clinical failure, risk of bias, methods and PRISMA)
- `R/` - data preparation (`01_prepare_data.R`), model fitting (`02_fit_models.R`), reference building (`03_build_references.R`)
- `data/` - extraction workbook (v4) and PRISMA flow diagram
- `references.bib`, `asm.csl` - bibliography and ASM citation style

## Rendering

```
quarto render
```

Notebooks run from the project root (`execute-dir: project`). Fitted brms models are cached in `_brms_cache/` (not in the repository); the first render refits them, which is slow. The clinical failure notebook uses the cmdstanr backend, which needs CmdStan installed.

Several fields in `index.qmd` are marked with square brackets and need confirmation before submission (search dates and counts, AI-use statement, registration number).
