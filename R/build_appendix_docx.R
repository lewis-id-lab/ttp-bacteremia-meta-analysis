# Builds downloads/appendix.docx from appendix.qmd.
#
# Inside this manuscript project Quarto treats appendix.qmd as a notebook and
# writes only the HTML preview, so the Word version is rendered from a copy in a
# temporary folder with no _quarto.yml. Run from the project root after the
# models are fitted (it reads _brms_cache/), and again after any refit so the
# Word file does not go stale:
#   source("R/build_appendix_docx.R")

stopifnot(file.exists("appendix.qmd"), dir.exists("_brms_cache"))
root <- normalizePath(".")
work <- file.path(tempdir(), "appendix_docx")
unlink(work, recursive = TRUE)
dir.create(work)

files <- c("appendix.qmd", "appendix-reference.docx", "references.bib",
           "packages.bib", "asm.csl", "renv.lock", ".Rprofile")
stopifnot(all(file.copy(file.path(root, files), work)))
file.copy(file.path(root, c("R", "data")), work, recursive = TRUE)
# Large directories are linked, not copied
file.symlink(file.path(root, c("_brms_cache", "renv")), file.path(work, c("_brms_cache", "renv")))

status <- system(sprintf("cd %s && quarto render appendix.qmd --to docx", shQuote(work)))
docx <- file.path(work, "appendix.docx")
if (status != 0 || !file.exists(docx)) stop("quarto render failed; see output above")

dir.create(file.path(root, "downloads"), showWarnings = FALSE)
file.copy(docx, file.path(root, "downloads", "appendix.docx"), overwrite = TRUE)
message("Wrote downloads/appendix.docx")
