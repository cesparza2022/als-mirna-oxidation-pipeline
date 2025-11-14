#!/usr/bin/env Rscript
# ============================================================================
# BUILD STEP 0 VIEWER HTML
# ============================================================================
# Creates an HTML summary for the dataset overview (Step 0), embedding the
# generated figures and highlighting key descriptive statistics.
# ============================================================================

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(stringr)
  library(scales)
})

fig_inputs <- list(
  samples_hist = snakemake@input[["fig_samples"]],
  samples_box = snakemake@input[["fig_samples_box"]],
  samples_group = snakemake@input[["fig_samples_group"]],
  miRNA_hist = snakemake@input[["fig_miRNA"]],
  miRNA_top = snakemake@input[["fig_top_miRNA"]],
  mutation_bar = snakemake@input[["fig_mutation_bar"]],
  mutation_pie_snvs = snakemake@input[["fig_mutation_pie_snvs"]],
  mutation_pie_counts = snakemake@input[["fig_mutation_pie_counts"]],
  position_density = snakemake@input[["fig_position"]]
)

table_samples_path <- snakemake@input[["table_samples"]]
table_sample_group_path <- snakemake@input[["table_sample_group"]]
table_miRNA_path <- snakemake@input[["table_miRNA"]]
table_top_miRNA_path <- snakemake@input[["table_top_miRNA"]]
table_mutation_path <- snakemake@input[["table_mutation"]]

output_html <- snakemake@output[["html"]]
asset_dir <- file.path(dirname(output_html), "step0_assets")
dir.create(asset_dir, recursive = TRUE, showWarnings = FALSE)

# Copy figures into viewers directory
asset_files <- lapply(fig_inputs, function(path) {
  dest <- file.path(asset_dir, basename(path))
  file.copy(path, dest, overwrite = TRUE)
  basename(dest)
})

# Load tables for summary blocks
sample_summary <- read_csv(table_samples_path, show_col_types = FALSE)
sample_group_summary <- read_csv(table_sample_group_path, show_col_types = FALSE)
miRNA_summary <- read_csv(table_miRNA_path, show_col_types = FALSE)
top_miRNA_summary <- read_csv(table_top_miRNA_path, show_col_types = FALSE)
mutation_summary <- read_csv(table_mutation_path, show_col_types = FALSE)

html_escape <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x
}

# Summary metrics ------------------------------------------------------------
summary_samples <- sample_summary %>% summarise(
  total_samples = n(),
  total_reads = sum(total_counts, na.rm = TRUE),
  median_snvs = median(snvs_detected, na.rm = TRUE),
  median_miRNAs = median(mirnas_detected, na.rm = TRUE)
)

group_breakdown <- sample_summary %>%
  count(group, name = "n") %>%
  mutate(label = paste0(group, " (", comma(n), ")")) %>%
  pull(label)

total_miRNAs <- nrow(miRNA_summary)

total_snvs <- sum(miRNA_summary$n_snvs, na.rm = TRUE)

mutation_top <- mutation_summary %>%
  arrange(desc(n_snvs)) %>%
  slice_head(n = 3) %>%
  mutate(label = paste0(mutation, " (", comma(n_snvs), ")")) %>%
  pull(label)

group_table_rows <- apply(sample_group_summary, 1, function(row) {
  sprintf(
    "<tr><td>%s</td><td class='num'>%s</td><td class='num'>%s</td><td class='num'>%s</td><td class='num'>%s</td></tr>",
    html_escape(row[["group"]]),
    comma(as.numeric(row[["n_samples"]])),
    comma(as.numeric(row[["total_counts"]])),
    comma(as.numeric(row[["mean_snvs"]]), accuracy = 0.1),
    comma(as.numeric(row[["mean_miRNAs"]]), accuracy = 0.1)
  )
})

top_miRNA_rows <- top_miRNA_summary %>%
  slice_head(n = 10) %>%
  mutate(miRNA_name = html_escape(miRNA_name)) %>%
  mutate(row_html = sprintf(
    "<tr><td>%s</td><td class='num'>%s</td><td class='num'>%s</td><td class='num'>%s</td></tr>",
                             miRNA_name,
                             comma(n_snvs),
                             comma(total_counts),
                             comma(samples_with_mutation))) %>%
  pull(row_html)

# Build HTML -----------------------------------------------------------------
writeLines(c(
  "<!DOCTYPE html>",
  "<html><head><meta charset='utf-8'><title>Step 0 · Dataset Overview</title>",
  "<style>",
  "body{font-family:Arial,Helvetica,sans-serif;background:#f5f5f5;margin:20px;}",
  "h1{color:#d62728;}",
  "h2{color:#2E86AB;margin-top:30px;}",
  "ul{line-height:1.6;}",
  ".grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(360px,1fr));gap:24px;margin-top:20px;}",
  "figure{background:#fff;padding:16px;border-radius:8px;box-shadow:0 2px 6px rgba(0,0,0,0.1);}",
  "figure img{max-width:100%;height:auto;border-radius:4px;}",
  "figcaption{margin-top:10px;color:#555;font-style:italic;}",
  "table.data{width:100%;border-collapse:collapse;margin-top:15px;}",
  "table.data th{background:#f0f4f8;text-align:left;}",
  "table.data th,table.data td{padding:8px;border:1px solid #dcdcdc;}",
  "table.data td.num{text-align:right;}",
  "</style>",
  "</head><body>",
  "<h1>Step 0 · Dataset Overview</h1>",
  "<section>",
  "  <h2>General Summary</h2>",
  "  <ul>",
  sprintf("    <li>Total samples: <strong>%s</strong> (groups: %s)</li>",
          comma(summary_samples$total_samples[1]),
          paste(group_breakdown, collapse = ", ")),
  sprintf("    <li>Total reads (sum of counts): <strong>%s</strong></li>",
          comma(summary_samples$total_reads[1])),
  sprintf("    <li>Median SNVs per sample: <strong>%s</strong></li>",
          comma(summary_samples$median_snvs[1])),
  sprintf("    <li>Median affected miRNAs per sample: <strong>%s</strong></li>",
          comma(summary_samples$median_miRNAs[1])),
  sprintf("    <li>Unique miRNAs: <strong>%s</strong> | Total SNVs: <strong>%s</strong></li>",
          comma(total_miRNAs), comma(total_snvs)),
  sprintf("    <li>Most frequent mutations: %s</li>", paste(mutation_top, collapse = ", ")), 
  "  </ul>",
  "</section>",
  "<section>",
  "  <h2>Sample Distribution</h2>",
  "  <div class='grid'>"
), output_html)

con <- file(output_html, open = "a")
figure_titles <- c(
  samples_hist = "Histogram of SNVs and miRNAs per sample",
  samples_box = "SNVs per sample by group",
  samples_group = "Proportion of samples by group",
  miRNA_hist = "Distribution of SNVs per miRNA",
  miRNA_top = "Top 20 miRNAs with most SNVs",
  mutation_bar = "Count of SNVs by mutation type",
  mutation_pie_snvs = "Proportion of SNVs by type",
  mutation_pie_counts = "Proportion of reads by type",
  position_density = "SNV density by position"
)

sample_figs <- c("samples_hist", "samples_box", "samples_group")
for (name in sample_figs) {
  img_name <- asset_files[[name]]
  caption <- figure_titles[[name]]
  writeLines(c(
    "    <figure>",
    sprintf("      <img src='step0_assets/%s' alt='%s'>", img_name, caption),
    sprintf("      <figcaption>%s</figcaption>", caption),
    "    </figure>"
  ), con)
}

writeLines(c(
  "  </div>",
  "  <h3>Summary by Group</h3>",
  "  <table class='data'>",
  "    <tr><th>Group</th><th>Samples</th><th>Total reads</th><th>Mean SNVs</th><th>Mean miRNAs</th></tr>",
  paste(group_table_rows, collapse = "\n"),
  "  </table>",
  "</section>",
  "<section>",
  "  <h2>miRNA Distribution</h2>",
  "  <div class='grid'>"
), con)

for (name in c("miRNA_hist", "miRNA_top")) {
  img_name <- asset_files[[name]]
  caption <- figure_titles[[name]]
  writeLines(c(
    "    <figure>",
    sprintf("      <img src='step0_assets/%s' alt='%s'>", img_name, caption),
    sprintf("      <figcaption>%s</figcaption>", caption),
    "    </figure>"
  ), con)
}

writeLines(c(
  "  </div>",
  "  <h3>Top 10 miRNAs</h3>",
  "  <table class='data'>",
  "    <tr><th>miRNA</th><th>SNVs</th><th>Total reads</th><th>Samples with mutation</th></tr>",
  paste(top_miRNA_rows, collapse = "\n"),
  "  </table>",
  "</section>",
  "<section>",
  "  <h2>Mutations and Positions</h2>",
  "  <div class='grid'>"
), con)

for (name in c("mutation_bar", "mutation_pie_snvs", "mutation_pie_counts", "position_density")) {
  img_name <- asset_files[[name]]
  caption <- figure_titles[[name]]
  writeLines(c(
    "    <figure>",
    sprintf("      <img src='step0_assets/%s' alt='%s'>", img_name, caption),
    sprintf("      <figcaption>%s</figcaption>", caption),
    "    </figure>"
  ), con)
}

writeLines(c(
  "  </div>",
  "</section>",
  "</body></html>"
), con)
close(con)

cat("✅ Step 0 viewer generated:", output_html, "\n")
