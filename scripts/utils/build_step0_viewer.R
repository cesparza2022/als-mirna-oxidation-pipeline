#!/usr/bin/env Rscript
# ============================================================================
# BUILD STEP 0 VIEWER HTML
# ============================================================================
# Creates an HTML summary for the dataset overview (Step 0), embedding the
# generated figures and highlighting key descriptive statistics.
# 
# Key Distinctions Highlighted:
#   - "Number of SNVs" (n_snvs): Count of unique SNV events
#   - "SNV Counts" (total_read_counts): Sum of read counts
#   - G>T mutations are highlighted in red
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
  mutation_bar = snakemake@input[["fig_mutation_bar"]],
  mutation_pie_snvs = snakemake@input[["fig_mutation_pie_snvs"]],
  mutation_pie_counts = snakemake@input[["fig_mutation_pie_counts"]],
  coverage = snakemake@input[["fig_coverage"]] # Replaces positional density
)

table_samples_path <- snakemake@input[["table_samples"]]
table_sample_group_path <- snakemake@input[["table_sample_group"]]
table_miRNA_path <- snakemake@input[["table_miRNA"]]
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
mutation_summary <- read_csv(table_mutation_path, show_col_types = FALSE)

html_escape <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x
}

# Summary metrics ------------------------------------------------------------
# Handle both old and new column names for compatibility
if ("total_read_counts" %in% names(sample_summary)) {
  total_reads_col <- "total_read_counts"
  n_snvs_col <- "n_snvs_detected"
  n_mirnas_col <- "n_mirnas_affected"
} else {
  total_reads_col <- "total_counts"
  n_snvs_col <- "snvs_detected"
  n_mirnas_col <- "mirnas_detected"
}

summary_samples <- sample_summary %>% summarise(
  total_samples = n(),
  total_reads = sum(.data[[total_reads_col]], na.rm = TRUE),
  median_n_snvs = median(.data[[n_snvs_col]], na.rm = TRUE),
  median_n_mirnas = median(.data[[n_mirnas_col]], na.rm = TRUE)
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
  mutate(label = paste0(mutation, " (", comma(n_snvs), " SNVs)")) %>%
  pull(label)

# Handle column name variations in sample_group_summary
if ("total_read_counts" %in% names(sample_group_summary)) {
  group_total_col <- "total_read_counts"
  group_mean_snvs_col <- "mean_n_snvs"
  group_mean_mirnas_col <- "mean_n_mirnas"
} else {
  group_total_col <- "total_counts"
  group_mean_snvs_col <- "mean_snvs"
  group_mean_mirnas_col <- "mean_miRNAs"
}

group_table_rows <- apply(sample_group_summary, 1, function(row) {
  sprintf(
    "<tr><td>%s</td><td class='num'>%s</td><td class='num'>%s</td><td class='num'>%s</td><td class='num'>%s</td></tr>",
    html_escape(row[["group"]]),
    comma(as.numeric(row[["n_samples"]])),
    comma(as.numeric(row[[group_total_col]])),
    comma(as.numeric(row[[group_mean_snvs_col]]), accuracy = 0.1),
    comma(as.numeric(row[[group_mean_mirnas_col]]), accuracy = 0.1)
  )
})

# Build HTML -----------------------------------------------------------------
writeLines(c(
  "<!DOCTYPE html>",
  "<html><head><meta charset='utf-8'><title>Step 0 · Dataset Overview</title>",
  "<style>",
  "body{font-family:Arial,Helvetica,sans-serif;background:#f5f5f5;margin:20px;}",
  "h1{color:#d62728;}",
  "h2{color:#2E86AB;margin-top:30px;}",
  "h3{color:#555;margin-top:20px;font-size:1.1em;}",
  "ul{line-height:1.6;}",
  ".grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(360px,1fr));gap:24px;margin-top:20px;}",
  "figure{background:#fff;padding:16px;border-radius:8px;box-shadow:0 2px 6px rgba(0,0,0,0.1);}",
  "figure img{max-width:100%;height:auto;border-radius:4px;}",
  "figcaption{margin-top:10px;color:#555;font-size:0.9em;line-height:1.4;}",
  ".note-box{background:#fff3cd;border-left:4px solid #ffc107;padding:12px;margin:15px 0;border-radius:4px;}",
  ".note-box strong{color:#856404;}",
  "table.data{width:100%;border-collapse:collapse;margin-top:15px;}",
  "table.data th{background:#f0f4f8;text-align:left;font-weight:bold;}",
  "table.data th,table.data td{padding:8px;border:1px solid #dcdcdc;}",
  "table.data td.num{text-align:right;}",
  ".key-difference{background:#e7f3ff;border-left:4px solid #2196F3;padding:10px;margin:10px 0;border-radius:4px;font-size:0.9em;}",
  "</style>",
  "</head><body>",
  "<h1>Step 0 · Dataset Overview</h1>",
  "<div class='note-box'>",
  "  <strong>📊 Key Distinction:</strong> This overview distinguishes between ",
  "  <strong>\"Number of SNVs\"</strong> (count of unique SNV events) and ",
  "  <strong>\"SNV Counts\"</strong> (sum of read counts). ",
  "  <strong>G>T mutations are highlighted in red</strong> throughout.",
  "</div>",
  "<section>",
  "  <h2>General Summary</h2>",
  "  <ul>",
  sprintf("    <li>Total samples: <strong>%s</strong> (groups: %s)</li>",
          comma(summary_samples$total_samples[1]),
          paste(group_breakdown, collapse = ", ")),
  sprintf("    <li>Total read counts (sum of all reads): <strong>%s</strong></li>",
          comma(summary_samples$total_reads[1])),
  sprintf("    <li>Total unique SNVs (number of SNV events): <strong>%s</strong></li>",
          comma(total_snvs)),
  sprintf("    <li>Unique miRNAs: <strong>%s</strong></li>",
          comma(total_miRNAs)),
  sprintf("    <li>Median number of SNVs per sample: <strong>%s</strong></li>",
          comma(summary_samples$median_n_snvs[1])),
  sprintf("    <li>Median affected miRNAs per sample: <strong>%s</strong></li>",
          comma(summary_samples$median_n_mirnas[1])),
  sprintf("    <li>Most frequent mutation types (by number of SNVs): %s</li>", 
          paste(mutation_top, collapse = ", ")), 
  "  </ul>",
  "</section>",
  "<section>",
  "  <h2>Sample Distribution</h2>",
  "  <div class='grid'>"
), output_html)

con <- file(output_html, open = "a")

# Improved figure titles with clear distinctions
figure_titles <- c(
  samples_hist = "Sample-level Distribution",
  samples_box = "Number of SNVs per Sample (by Group)",
  samples_group = "Proportion of Samples by Group",
  miRNA_hist = "Distribution of Number of SNVs per miRNA",
  mutation_bar = "Number of SNVs by Mutation Type",
  mutation_pie_snvs = "Proportional Representation: SNVs vs Read Counts",
  mutation_pie_counts = "Read Counts per SNV Event",
  coverage = "Dataset Coverage: SNV Representation"
)

figure_descriptions <- c(
  samples_hist = "Distinguishes: Total read counts (sum) vs Number of SNVs (unique events) vs Affected miRNAs",
  samples_box = "Number of unique SNV events detected per sample (log10 scale). This shows the COUNT of unique SNV events, not the sum of read counts.",
  samples_group = "Distribution of samples across experimental groups",
  miRNA_hist = "Number of unique SNV events per miRNA (log10 scale). This shows the COUNT of unique SNV events, not the sum of read counts.",
  mutation_bar = "Count of unique SNV events by mutation type. G>T (oxidation) highlighted in red. This shows the COUNT of unique SNV events, not the sum of read counts.",
  mutation_pie_snvs = "Compares the percentage of total SNVs vs the percentage of total read counts that each mutation type represents. If proportions differ, the mutation is over/under-represented in read counts relative to SNV events. G>T (oxidation) highlighted in red. This shows OVERALL proportions, not per-sample analysis.",
  mutation_pie_counts = "Average number of sequencing reads per unique SNV event for each mutation type. Higher values = more reads per unique SNV event. This shows sequencing depth per mutation type. G>T (oxidation) highlighted in red. Dashed line = overall average.",
  coverage = "Shows what fraction of miRNAs and samples have detected SNVs. This provides an overview of dataset coverage - how well the dataset is represented by SNV detection. High coverage = most miRNAs/samples have SNVs. This is COMPLEMENTARY to Step 1's positional analysis."
)

sample_figs <- c("samples_hist", "samples_box", "samples_group")
for (name in sample_figs) {
  img_name <- asset_files[[name]]
  caption <- figure_titles[[name]]
  description <- figure_descriptions[[name]]
  writeLines(c(
    "    <figure>",
    sprintf("      <img src='step0_assets/%s' alt='%s'>", img_name, caption),
    sprintf("      <figcaption><strong>%s</strong><br>%s</figcaption>", caption, description),
    "    </figure>"
  ), con)
}

writeLines(c(
  "  </div>",
  "  <h3>Summary by Group</h3>",
  "  <table class='data'>",
  "    <tr><th>Group</th><th>Samples</th><th>Total read counts</th><th>Mean # SNVs</th><th>Mean # miRNAs</th></tr>",
  paste(group_table_rows, collapse = "\n"),
  "  </table>",
  "<div class='key-difference'>",
  "  <strong>Note:</strong> 'Total read counts' = sum of all reads. 'Mean # SNVs' = average number of unique SNV events per sample.",
  "</div>",
  "</section>",
  "<section>",
  "  <h2>miRNA Distribution</h2>",
  "  <div class='grid'>"
), con)

# miRNA histogram only (top miRNAs removed)
img_name <- asset_files[["miRNA_hist"]]
caption <- figure_titles[["miRNA_hist"]]
description <- figure_descriptions[["miRNA_hist"]]
writeLines(c(
  "    <figure>",
  sprintf("      <img src='step0_assets/%s' alt='%s'>", img_name, caption),
  sprintf("      <figcaption><strong>%s</strong><br>%s</figcaption>", caption, description),
  "    </figure>"
), con)

writeLines(c(
  "  </div>",
  "</section>",
  "<section>",
  "  <h2>Mutations and Positions</h2>",
  "  <div class='key-difference'>",
  "    <strong>🔴 Important:</strong> The two figures below show the relationship between 'Number of SNVs' and 'Read Counts':",
  "    <ul style='margin-top:8px;'>",
  "      <li><strong>Scatter Plot:</strong> Shows both metrics simultaneously - helps identify mutations with many SNVs but few reads (or vice versa)</li>",
  "      <li><strong>Side-by-Side Comparison:</strong> Direct comparison of both metrics for each mutation type</li>",
  "    </ul>",
  "    These visualizations reveal important differences! A mutation type can have many unique SNV events but fewer total reads, or vice versa.",
  "  </div>",
  "  <div class='grid'>"
), con)

for (name in c("mutation_bar", "mutation_pie_snvs", "mutation_pie_counts", "coverage")) {
  img_name <- asset_files[[name]]
  caption <- figure_titles[[name]]
  description <- figure_descriptions[[name]]
  writeLines(c(
    "    <figure>",
    sprintf("      <img src='step0_assets/%s' alt='%s'>", img_name, caption),
    sprintf("      <figcaption><strong>%s</strong><br>%s</figcaption>", caption, description),
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
