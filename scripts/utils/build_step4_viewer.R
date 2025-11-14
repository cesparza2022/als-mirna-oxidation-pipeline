#!/usr/bin/env Rscript
# ============================================================================
# BUILD STEP 4 VIEWER HTML
# ============================================================================
# Generates HTML viewer for Step 4 functional analysis results
# ============================================================================

suppressPackageStartupMessages({
  library(readr)
  library(stringr)
  library(dplyr)
})

if (requireNamespace("base64enc", quietly = TRUE)) {
  library(base64enc)
  encode_image <- function(image_path) {
    if (is.null(image_path) || image_path == "") return("")
    if (!file.exists(image_path)) return("")
    con <- file(image_path, "rb")
    img_data <- readBin(con, "raw", file.info(image_path)$size)
    close(con)
    paste0("data:image/png;base64,", base64encode(img_data))
  }
} else {
  encode_image <- function(image_path) {
    if (is.null(image_path) || image_path == "") return("")
    if (!file.exists(image_path)) return("")
    image_path
  }
}

pathway_heatmap <- snakemake@input[["pathway_heatmap"]]
functional_panel_a <- snakemake@input[["functional_panel_a"]]
functional_panel_b <- snakemake@input[["functional_panel_b"]]
functional_panel_c <- snakemake@input[["functional_panel_c"]]
functional_panel_d <- snakemake@input[["functional_panel_d"]]

output_html <- snakemake@output[["html"]]
figures_dir <- snakemake@params[["figures_dir"]]
tables_dir <- snakemake@params[["tables_dir"]]

# Load functional summaries
functional_table <- file.path(tables_dir, "functional", "S4_target_analysis.csv")
go_file <- file.path(tables_dir, "functional", "S4_go_enrichment.csv")
kegg_file <- file.path(tables_dir, "functional", "S4_kegg_enrichment.csv")

o_safe_read <- function(path) {
  if (!file.exists(path)) return(NULL)
  read_csv(path, show_col_types = FALSE)
}

functional_targets <- o_safe_read(functional_table)
go_enrichment <- o_safe_read(go_file)
kegg_enrichment <- o_safe_read(kegg_file)

n_targets <- if (!is.null(functional_targets)) nrow(functional_targets) else 0
n_go <- if (!is.null(go_enrichment)) sum(go_enrichment$p.adjust < 0.1, na.rm = TRUE) else 0
n_kegg <- if (!is.null(kegg_enrichment)) sum(kegg_enrichment$p.adjust < 0.1, na.rm = TRUE) else 0

html_content <- paste0('<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <title>Step 4 Viewer · Functional Analysis</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
    .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
    h1 { color: #D62728; border-bottom: 3px solid #D62728; padding-bottom: 10px; }
    h2 { color: #2E86AB; margin-top: 30px; }
    .summary { background: #f9f9f9; padding: 18px; border-radius: 4px; margin: 20px 0; }
    .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 18px; margin-top: 15px; }
    .stat-box { background: #e8f4f8; padding: 18px; border-radius: 4px; text-align: center; }
    .stat-number { font-size: 24px; font-weight: bold; color: #D62728; }
    .stat-label { color: #666; margin-top: 6px; }
    .figure { margin: 25px 0; text-align: center; }
    .figure img { max-width: 100%; height: auto; border: 1px solid #ddd; border-radius: 4px; }
    .figure-caption { margin-top: 10px; font-style: italic; color: #666; }
    ul { line-height: 1.6; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Step 4 · Functional Analysis</h1>

    <div class="summary">
      <h2>📊 Summary</h2>
      <div class="stats">
        <div class="stat-box">
          <div class="stat-number">', n_targets, '</div>
          <div class="stat-label">Targets Analyzed</div>
        </div>
        <div class="stat-box">
          <div class="stat-number">', n_go, '</div>
          <div class="stat-label">Significant GO Terms</div>
        </div>
        <div class="stat-box">
          <div class="stat-number">', n_kegg, '</div>
          <div class="stat-label">Significant KEGG Pathways</div>
        </div>
      </div>
    </div>

    <h2>🧬 Pathway Enrichment</h2>
    <div class="figure">
      <img src="', encode_image(pathway_heatmap), '" alt="Pathway Heatmap">
      <div class="figure-caption">Heatmap of GO/KEGG pathways enriched in oxidized miRNA targets</div>
    </div>

    <h2>🧠 Functional Panels</h2>
    <div class="figure">
      <img src="', encode_image(functional_panel_a), '" alt="Target Network">
      <div class="figure-caption">Panel A · Target network overview</div>
    </div>
    <div class="figure">
      <img src="', encode_image(functional_panel_b), '" alt="GO Enrichment">
      <div class="figure-caption">Panel B · GO enrichment (top biological processes)</div>
    </div>
    <div class="figure">
      <img src="', encode_image(functional_panel_c), '" alt="KEGG Enrichment">
      <div class="figure-caption">Panel C · KEGG pathway enrichment</div>
    </div>
    <div class="figure">
      <img src="', encode_image(functional_panel_d), '" alt="ALS Pathways">
      <div class="figure-caption">Panel D · ALS-relevant pathways and functional impact</div>
    </div>

    <div class="summary" style="margin-top: 40px;">
      <h2>📁 Available Resources</h2>
      <ul>
        <li><strong>functional/S4_target_analysis.csv</strong> – miRNA-target analysis</li>
        <li><strong>functional/S4_go_enrichment.csv</strong> – GO enrichment results</li>
        <li><strong>functional/S4_kegg_enrichment.csv</strong> – KEGG enrichment results</li>
        <li><strong>functional/S4_als_pathways.csv</strong> – ALS-specific pathways</li>
      </ul>
    </div>
  </div>
</body>
</html>')

writeLines(html_content, output_html)
cat("✅ Step 4 viewer generated:", output_html, "\n")

