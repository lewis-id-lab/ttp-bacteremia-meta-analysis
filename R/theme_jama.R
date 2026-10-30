## JAMA-style ggplot theme with a blue-grey palette.
## Source after loading ggplot2:  source("R/theme_jama.R")

jama_pal <- c(
  navy   = "#1F3447",  # pooled estimates, Gram-negative, emphasis
  slate  = "#3F5A75",
  steel  = "#5B7A99",  # overall / studies
  mist   = "#7F9DB9",  # Gram-positive, secondary series
  pale   = "#C9D6E2",
  fog    = "#E3E9EF",  # bands and highlights
  grey   = "#6B7680",  # reference lines, annotations
  ink    = "#1A1F24"   # text
)

jama_ref_line <- unname(jama_pal["grey"])

theme_jama <- function(base_size = 10, base_family = "Helvetica") {
  ggplot2::theme_minimal(base_size = base_size, base_family = base_family) +
    ggplot2::theme(
      text               = ggplot2::element_text(colour = jama_pal[["ink"]]),
      plot.title         = ggplot2::element_text(face = "bold", size = base_size + 1, hjust = 0),
      plot.title.position = "plot",
      plot.subtitle      = ggplot2::element_text(colour = jama_pal[["grey"]]),
      plot.caption       = ggplot2::element_text(colour = jama_pal[["grey"]], hjust = 0),
      axis.title         = ggplot2::element_text(face = "bold"),
      axis.text          = ggplot2::element_text(colour = jama_pal[["ink"]]),
      axis.line          = ggplot2::element_line(colour = jama_pal[["ink"]], linewidth = 0.35),
      axis.ticks         = ggplot2::element_line(colour = jama_pal[["ink"]], linewidth = 0.35),
      panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.minor   = ggplot2::element_blank(),
      panel.grid.major.y = ggplot2::element_line(colour = "#E3E9EF", linewidth = 0.3),
      strip.text         = ggplot2::element_text(face = "bold", hjust = 0),
      legend.position    = "bottom",
      legend.title       = ggplot2::element_text(face = "bold"),
      plot.background    = ggplot2::element_rect(fill = "white", colour = NA),
      panel.background   = ggplot2::element_rect(fill = "white", colour = NA)
    )
}

jama_colours <- function(n) unname(jama_pal[c("navy", "mist", "slate", "pale", "steel", "grey")][seq_len(n)])
scale_fill_jama   <- function(...) ggplot2::scale_fill_manual(values = jama_colours(6), ...)
scale_colour_jama <- function(...) ggplot2::scale_colour_manual(values = jama_colours(6), ...)
scale_color_jama  <- scale_colour_jama

ggplot2::theme_set(theme_jama())
if (requireNamespace("bayesplot", quietly = TRUE)) {
  bayesplot::color_scheme_set(unname(jama_pal[c("pale", "mist", "steel", "slate", "navy", "ink")]))
  bayesplot::bayesplot_theme_set(theme_jama())
}
