#' PRISMA-style flow diagram of the 2026 update, drawn with Graphviz.
#'
#' The PRISMA2020 template assumes title/abstract screening of every database
#' record. Here the database records were not screened in Covidence: they were
#' tiered by keyword and enriched with PubMed abstracts, and most candidates came
#' from a separate Elicit search, so the flow is drawn by hand to show that route.
#'
#' Counts are the strict-criterion flow reported in index.qmd (Methods, "Search
#' strategy and study selection"). The inclusive re-screen (40 further studies,
#' sensitivity pool) is stated in the figure caption in index.qmd, not drawn.
#'
#' Sources of the counts: Covidence imports panel (6,014 imported, 1,409
#' duplicates); TTP_Update_Screening_Pool.xlsx README (pool of 355: 323 from the
#' Elicit search, 32 from database tiering only).
#'
#' Usage: source("R/04_prisma_flow.R"); writes data/PRISMA_v4_prisma2020.{png,svg,pdf}

flow_counts <- list(
  identified     = 6014,
  embase         = 2877,
  scopus         = 1649,
  pubmed         = 1250,
  wos            = 237,
  cochrane       = 1,
  duplicates     = 1409,
  unique         = 4605,
  priority_total = 44,
  elicit_rows    = 445,
  elicit_dois    = 348,
  elicit_kept    = 323,
  tier_only      = 32,
  sought         = 355,
  not_retrieved  = 53,
  assessed       = 302,
  excluded       = 259,
  new_included   = 43,
  previous       = 57,
  total_included = 100
)

flow_dot <- function(n = flow_counts) {
  f <- function(x) format(x, big.mark = ",")
  stopifnot(n$identified == n$embase + n$scopus + n$pubmed + n$wos + n$cochrane,
            n$unique == n$identified - n$duplicates,
            n$sought == n$elicit_kept + n$tier_only,
            n$assessed == n$sought - n$not_retrieved,
            n$total_included == n$new_included + n$previous,
            n$new_included == n$assessed - n$excluded)
  sprintf('digraph prisma {
  graph [rankdir=TB, nodesep=0.45, ranksep=0.5, fontname="Helvetica"]
  node  [shape=box, style="rounded", fontname="Helvetica", fontsize=11, margin="0.18,0.10"]
  edge  [arrowsize=0.7]

  db   [label="Records identified from databases\\n(n = %s)\\nEmbase %s; Scopus %s; PubMed %s;\\nWeb of Science %s; Cochrane CENTRAL %s"]
  dup  [label="Duplicates removed in Covidence\\n(n = %s)"]
  eli  [label="Records identified by Elicit search\\n(n = %s rows; %s unique DOIs)"]
  { rank=same; db; dup; eli }
  db -> dup
  dup -> eli [style=invis]

  uniq [label="Unique database records\\n(n = %s)\\nNot screened in Covidence"]
  eli2 [label="Elicit candidates after removing studies\\nalready in the previous review\\n(n = %s)"]
  { rank=same; uniq; eli2 }
  db -> uniq
  eli -> eli2
  uniq -> eli2 [style=invis]

  tier [label="Keyword tiering and PubMed abstract enrichment\\nof database records\\nPriority candidates (n = %s;\\n%s not found by Elicit)"]
  uniq -> tier

  pool [label="Candidate reports sought for full-text retrieval\\n(n = %s)\\n%s from Elicit; %s from database tiering only"]
  tier -> pool
  eli2 -> pool

  nr   [label="Reports not retrieved\\n(n = %s)\\nMainly conference abstracts,\\nnon-English papers, methods-only papers"]
  { rank=same; pool; nr }
  pool -> nr

  ass  [label="Reports assessed for eligibility\\n(n = %s)"]
  ex   [label="Reports excluded (n = %s)\\nIneligible design, 104\\nNo TTP measured, 65\\nNo quantitative TTP-outcome association, 54\\nNo clinical outcome, 29\\nDuplicate, 5\\nNot bloodstream infection, 2"]
  { rank=same; ass; ex }
  pool -> ass
  ass -> ex

  prev [label="Previous review\\nStudies included (n = %s)"]
  inc  [label="New studies included (n = %s)\\nTotal studies included (n = %s)"]
  { rank=same; prev; inc }
  ass -> inc
  prev -> inc
}',
    f(n$identified), f(n$embase), f(n$scopus), f(n$pubmed), f(n$wos), f(n$cochrane),
    f(n$duplicates), f(n$elicit_rows), f(n$elicit_dois),
    f(n$unique), f(n$elicit_kept),
    f(n$priority_total), f(n$tier_only),
    f(n$sought), f(n$elicit_kept), f(n$tier_only),
    f(n$not_retrieved), f(n$assessed), f(n$excluded),
    f(n$previous), f(n$new_included), f(n$total_included))
}

make_prisma_flow <- function(out_dir = "data", stem = "PRISMA_v4_prisma2020") {
  svg <- DiagrammeRsvg::export_svg(DiagrammeR::grViz(flow_dot()))
  base <- file.path(out_dir, stem)
  writeLines(svg, paste0(base, ".svg"))
  rsvg::rsvg_png(charToRaw(svg), paste0(base, ".png"), width = 2200)
  rsvg::rsvg_pdf(charToRaw(svg), paste0(base, ".pdf"))
  invisible(svg)
}

if (sys.nframe() == 0 || identical(Sys.getenv("MAKE_PRISMA"), "1")) make_prisma_flow()
