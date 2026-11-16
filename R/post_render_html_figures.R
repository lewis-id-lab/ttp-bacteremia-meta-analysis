# Quarto post-render step for the manuscript project.
#
# With html, docx and pdf formats rendered together, Quarto 1.9.35 places the
# article's embedded notebook figures under _manuscript/_tex/index_files/ but
# not under _manuscript/index_files/, where index.html links to them, so the
# figures are missing from the HTML article. Rendering html alone does not show
# the problem. This copies the HTML figures to where index.html expects them.
# Remove once a Quarto release no longer needs it.

out_dir <- Sys.getenv("QUARTO_PROJECT_OUTPUT_DIR", "_manuscript")
html_path <- file.path(out_dir, "index.html")
if (!file.exists(html_path)) quit(save = "no")

html <- readLines(html_path, warn = FALSE, encoding = "UTF-8")
srcs <- unique(unlist(regmatches(html, gregexpr('index_files/figure-html/[^"]+', html))))
missing <- srcs[!file.exists(file.path(out_dir, srcs))]
if (length(missing) == 0) quit(save = "no")

sources <- list(
  tex    = file.path(out_dir, "_tex", missing),
  freeze = file.path("_freeze/index", sub("^index_files/", "", missing))
)
use <- names(sources)[vapply(sources, \(f) all(file.exists(f)), TRUE)][1]
if (is.na(use)) {
  warning("post-render: cannot find a source for ", length(missing), " HTML figure(s), e.g. ", missing[1])
  quit(save = "no")
}
from_root <- use
from <- sources[[use]]
to <- file.path(out_dir, missing)
for (d in unique(dirname(to))) dir.create(d, recursive = TRUE, showWarnings = FALSE)
ok <- file.copy(from, to, overwrite = TRUE)
message("post-render: copied ", sum(ok), " of ", length(missing), " missing HTML figure(s) from ", from_root)
if (!all(ok)) warning("post-render: could not copy ", paste(missing[!ok], collapse = ", "))
