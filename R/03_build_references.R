#' Build references.bib for the studies in the extraction workbook.
#'
#' The workbook holds only study_id, first author and year, so bibliographic
#' metadata is matched from the project's RIS exports and the Covidence CSV by
#' normalised first-author surname + year. Records with a DOI/journal/volume are
#' preferred; ambiguous or unmatched studies are logged in references_review.csv.
#'
#' Output: references.bib (citation key = study_id) and references_review.csv

suppressPackageStartupMessages({
  library(dplyr); library(stringr); library(readr); library(readxl)
})

src_dir <- "/Users/russelllewis/ttp_meta_new/new_ttp_metaanalysis"
xlsx    <- "data/TTP_MetaAnalysis_Extraction_Complete_v4.xlsx"

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0 || all(is.na(a))) b else a
first_chr <- function(recs, f) vapply(recs, \(r) {
  v <- f(r); if (is.null(v) || length(v) == 0) NA_character_ else as.character(v[1])
}, character(1))
norm <- function(x) x |> iconv(to = "ASCII//TRANSLIT") |> str_to_lower() |> str_remove_all("[^a-z]")

read_ris <- function(path) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8") |> str_remove("^\ufeff")
  recs <- list(); cur <- list(); last <- NULL
  for (l in lines) {
    m <- str_match(l, "^([A-Z][A-Z0-9])  - ?(.*)$")
    if (!is.na(m[1, 1])) {
      tag <- m[1, 2]; val <- m[1, 3]
      if (tag == "TY") cur <- list()
      if (tag == "ER") { recs[[length(recs) + 1]] <- cur; cur <- list(); last <- NULL; next }
      cur[[tag]] <- c(cur[[tag]], val); last <- tag
    } else if (!is.null(last) && nzchar(str_trim(l))) {
      n <- length(cur[[last]]); cur[[last]][n] <- paste(cur[[last]][n], str_trim(l))
    }
  }
  tibble(
    title   = first_chr(recs, \(r) r$TI %||% r$T1),
    authors = lapply(recs, \(r) c(r$AU, r$A1)),
    year    = first_chr(recs, \(r) str_extract(r$PY %||% r$Y1 %||% r$DA %||% "", "\\d{4}")),
    journal = first_chr(recs, \(r) r$JO %||% r$JF %||% r$T2 %||% r$JA),
    volume  = first_chr(recs, \(r) r$VL),
    issue   = first_chr(recs, \(r) r$IS),
    pages   = first_chr(recs, \(r) {
      sp <- r$SP; ep <- r$EP
      if (is.null(sp)) NULL else if (is.null(ep)) sp else paste0(sp, "--", ep)
    }),
    doi     = first_chr(recs, \(r) str_remove(r$DO %||% str_extract(paste(r$UR, collapse = " "), "10\\.\\d{4,}/\\S+"),
                                              "^https?://(dx\\.)?doi\\.org/")),
    source  = basename(path)
  )
}

ris <- list.files(src_dir, pattern = "\\.ris$", full.names = TRUE) |>
  lapply(read_ris) |> bind_rows()

cov <- read_csv(file.path(src_dir, "review_22.05.05csv.csv"), show_col_types = FALSE) |>
  transmute(title = Title, authors = str_split(Authors, ";\\s*"),
            year = as.character(`Published Year`), journal = Journal,
            volume = as.character(Volume), issue = as.character(Issue),
            pages = str_replace(as.character(Pages), "-", "--"),
            doi = DOI, source = "review_22.05.05csv.csv")

pool <- bind_rows(ris, cov) |>
  filter(!is.na(title), !is.na(year)) |>
  mutate(surname = vapply(authors, \(a) if (length(a)) norm(str_split_1(a[1], ",")[1]) else NA_character_, character(1)),
         has_meta = (!is.na(doi)) + (!is.na(journal)) + (!is.na(volume)),
         title_key = str_to_lower(str_remove_all(title, "[^A-Za-z0-9]")))

study <- read_excel(xlsx, "tbl_study") |>
  transmute(study_id, first_author, pub_year = as.character(pub_year), surname = norm(first_author))

# Titles recovered from PDF file names ("Author et al. 2021 - Title.pdf") are used to
# disambiguate several records sharing an author-year; otherwise fall back to a
# TTP/bacteremia keyword score.
pdfs <- list.files(c(file.path(src_dir, "new_ttp_pdfs"), file.path(src_dir, "publications")),
                   pattern = "\\.pdf$", full.names = FALSE)
pdf_tbl <- tibble(file = pdfs) |>
  mutate(year = str_extract(file, "(19|20)\\d{2}"),
         surname = norm(str_extract(file, "^[^ ]+")),
         ptitle = str_remove(file, "^.*?(19|20)\\d{2}\\s*-\\s*") |> str_remove("\\.pdf$"))
words <- \(x) if (is.na(x)) character() else unique(str_split(str_to_lower(str_replace_all(x, "[^A-Za-z0-9 ]", " ")), "\\s+")[[1]])
words <- Vectorize(words, SIMPLIFY = FALSE)
kw <- "positiv|time.to|blood culture|bacter|candid|fung|bloodstream|sepsis|catheter"

cands <- study |>
  left_join(pool, by = c("surname", "pub_year" = "year"), relationship = "many-to-many") |>
  group_by(study_id, title_key) |>
  slice_max(has_meta, n = 1, with_ties = FALSE) |>
  ungroup()

score_title <- function(sid, surname, year, title) {
  if (is.na(title)) return(NA_real_)
  pt <- pdf_tbl$ptitle[pdf_tbl$surname == surname & pdf_tbl$year == year]
  tw <- setdiff(words(title)[[1]], c("", "the", "of", "in", "and", "a", "with", "for", "to"))
  pt <- pt[!is.na(pt)]
  ov <- if (length(pt)) max(vapply(pt, \(p) mean(setdiff(words(p)[[1]], "") %in% tw), numeric(1))) else 0
  ov * 10 + as.numeric(str_detect(str_to_lower(title), kw))
}

resolved <- cands |>
  rowwise() |>
  mutate(score = score_title(study_id, surname, pub_year, title)) |>
  ungroup() |>
  group_by(study_id) |>
  arrange(desc(score), desc(has_meta), .by_group = TRUE) |>
  mutate(n_candidates = sum(!is.na(title_key)),
         margin = score - coalesce(nth(score, 2), -Inf)) |>
  slice(1) |> ungroup()

esc <- function(x) str_replace_all(x, c("&" = "\\\\&", "%" = "\\\\%"))
field <- function(name, val) if (is.na(val) || !nzchar(val)) NULL else sprintf("  %s = {%s},", name, esc(val))

entries <- vapply(seq_len(nrow(resolved)), \(i) {
  r <- resolved[i, ]
  if (is.na(r$title)) return(NA_character_)
  au <- r$authors[[1]]
  paste(c(sprintf("@article{%s,", r$study_id),
          if (length(au)) field("author", paste(au, collapse = " and ")),
          field("title", paste0("{", str_remove_all(r$title, "</?[a-z]+>"), "}")),
          field("journal", r$journal), field("year", r$pub_year),
          field("volume", r$volume), field("number", r$issue),
          field("pages", r$pages), field("doi", r$doi), "}"), collapse = "\n")
}, character(1))
writeLines(na.omit(entries), "references.bib")

review <- resolved |>
  mutate(status = case_when(is.na(title) ~ "unmatched",
                            n_candidates > 1 & margin < 5 ~ "ambiguous",
                            is.na(doi) & is.na(journal) ~ "sparse",
                            TRUE ~ "ok")) |>
  select(study_id, first_author, pub_year, status, n_candidates, title, journal, doi, source)
write_csv(review, "references_review.csv")
print(count(review, status))
