## export_svg_figures.R
## Exports every figure shown in the manuscript (index.qmd) as SVG to
## figures/manuscript_svg/, numbered in manuscript order.
##
## The figures are produced by knitting the same notebook chunks the manuscript
## embeds, with an svglite device, so they match the rendered manuscript exactly.
## Requires the cached brms fits (render the notebooks first).
##
## Usage (from project root):  source("R/export_svg_figures.R")
## Runs in a separate R process so it does not modify the global environment.

export_svg_figures <- function(out_dir = "figures/manuscript_svg") {
  root <- normalizePath(".")
  out_dir <- file.path(root, out_dir)
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

  # Manuscript figure order: label -> source notebook
  figs <- list(
    list(n = 2, label = "fig-forest",              nb = "notebooks/mortality-analysis.qmd", name = "forest_mortality"),
    list(n = 3, label = "fig-pathogen-posteriors", nb = "notebooks/mortality-analysis.qmd", name = "pathogen_posteriors"),
    list(n = 4, label = "fig-cutpoint",            nb = "notebooks/mortality-analysis.qmd", name = "cutpoint_metaregression"),
    list(n = 5, label = "fig-funnel",              nb = "notebooks/mortality-analysis.qmd", name = "funnel"),
    list(n = 6, label = "fig-sens-inc",            nb = "notebooks/mortality-analysis.qmd", name = "sensitivity_pool"),
    list(n = 7, label = "fig-pb",                  nb = "notebooks/clinical_failure.qmd",   name = "persistent_bacteremia")
  )

  knit_dir <- file.path(out_dir, ".knit")
  dir.create(knit_dir, showWarnings = FALSE)
  on.exit(unlink(knit_dir, recursive = TRUE), add = TRUE)
  for (nb in unique(vapply(figs, `[[`, "", "nb"))) {
    callr::r(function(root, nb, knit_dir) {
      setwd(root)
      knitr::opts_knit$set(root.dir = root)
      knitr::opts_chunk$set(dev = "svglite", fig.width = 10, fig.height = 6,
                            fig.path = paste0(knit_dir, "/"), echo = FALSE,
                            message = FALSE, warning = FALSE)
      knitr::knit(file.path(root, nb), output = file.path(knit_dir, "knit.md"), quiet = TRUE,
                  envir = new.env())
    }, args = list(root = root, nb = nb, knit_dir = knit_dir), show = FALSE)
  }

  written <- character()
  for (f in figs) {
    src <- file.path(knit_dir, paste0(f$label, "-1.svg"))
    if (!file.exists(src)) { warning("No SVG produced for ", f$label); next }
    dest <- file.path(out_dir, sprintf("Figure%d_%s.svg", f$n, f$name))
    file.copy(src, dest, overwrite = TRUE)
    written <- c(written, dest)
  }

  # Figure 1, the PRISMA flow diagram, is already a vector file
  prisma <- file.path(out_dir, "Figure1_prisma_flow.svg")
  file.copy(file.path(root, "data/PRISMA_v4_prisma2020.svg"), prisma, overwrite = TRUE)

  invisible(sort(c(prisma, written)))
}

if (sys.nframe() == 0L || identical(environment(), globalenv())) {
  message("SVG figures written:\n", paste(basename(export_svg_figures()), collapse = "\n"))
}
