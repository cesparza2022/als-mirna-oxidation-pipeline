#!/usr/bin/env Rscript
# ============================================================================
# BUILD STEP 3 VIEWER HTML
# ============================================================================
# Generates HTML viewer for Step 3 clustering analysis results
# ============================================================================

suppressPackageStartupMessages({
  library(readr)
  library(stringr)
})

if (requireNamespace("base64enc", quietly = TRUE)) {
  library(base64enc)
  encode_image <- function(image_path) {
    if (!file.exists(image_path)) return("")
    con <- file(image_path, "rb")
    img_data <- readBin(con, "raw", file.info(image_path)$size)
    close(con)
    base64_data <- base64encode(img_data)
    paste0("data:image/png;base64,", base64_data)
  }
} else {
  encode_image <- function(image_path) {
    if (!file.exists(image_path)) return("")
    image_path
  }
}

# Get Snakemake inputs
cluster_heatmap <- snakemake@input[["cluster_heatmap"]]
cluster_dendrogram <- snakemake@input[["cluster_dendrogram"]]

output_html <- snakemake@output[["html"]]
figures_dir <- snakemake@params[["figures_dir"]]
tables_dir <- snakemake@params[["tables_dir"]]

# Load clustering summaries
cluster_assignments_file <- file.path(tables_dir, "clusters", "S3_cluster_assignments.csv")
cluster_summary_file <- file.path(tables_dir, "clusters", "S3_cluster_summary.csv")

o_safe_read <- function(path) {
  if (!file.exists(path)) return(NULL)
  read_csv(path, show_col_types = FALSE)
}

assignments <- o_safe_read(cluster_assignments_file)
summary_df <- o_safe_read(cluster_summary_file)

n_miRNAs <- if (!is.null(assignments)) nrow(assignments) else 0
n_clusters <- if (!is.null(summary_df)) nrow(summary_df) else 0
cluster_sizes <- if (!is.null(summary_df)) paste(summary_df$n_miRNAs, collapse = ", ") else "N/A"

# Generate HTML
html_content <- paste0('<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <title>Step 3 Viewer · Clustering Analysis</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
    .container { max-width: 1400px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
    h1 { color: #D62728; border-bottom: 3px solid #D62728; padding-bottom: 10px; }
    h2 { color: #2E86AB; margin-top: 30px; }
    .figure { margin: 25px 0; text-align: center; }
    .figure img { max-width: 100%; height: auto; border: 1px solid #ddd; border-radius: 4px; }
    .figure-caption { margin-top: 10px; font-style: italic; color: #666; }
    .summary { background: #f9f9f9; padding: 18px; border-radius: 4px; margin: 20px 0; }
    .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 18px; margin-top: 15px; }
    .stat-box { background: #e8f4f8; padding: 18px; border-radius: 4px; text-align: center; }
    .stat-number { font-size: 24px; font-weight: bold; color: #D62728; }
    .stat-label { color: #666; margin-top: 6px; }
    ul { line-height: 1.6; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Step 3 · Clustering Analysis</h1>

    <div class="summary">
      <h2>📊 Summary</h2>
      <div class="stats">
        <div class="stat-box">
          <div class="stat-number">', n_miRNAs, '</div>
          <div class="stat-label">miRNAs Clustered</div>
        </div>
        <div class="stat-box">
          <div class="stat-number">', n_clusters, '</div>
          <div class="stat-label">Clusters Identified</div>
        </div>
        <div class="stat-box">
          <div class="stat-number">', cluster_sizes, '</div>
          <div class="stat-label">Cluster Sizes (miRNAs)</div>
        </div>
      </div>
    </div>

    <h2>🔥 Clustering Panels</h2>
    <div class="figure">
      <img src="', encode_image(cluster_heatmap), '" alt="Cluster Heatmap">
      <div class="figure-caption">Panel A · Heatmap of miRNA clusters (seed-region G>T VAF)</div>
    </div>
    <div class="figure">
      <img src="', encode_image(cluster_dendrogram), '" alt="Cluster Dendrogram">
      <div class="figure-caption">Panel B · Hierarchical dendrogram (Ward.D2)</div>
    </div>


    <div class="summary" style="margin-top: 40px;">
      <h2>📁 Recursos Disponibles</h2>
      <ul>
        <li><strong>clusters/S3_cluster_assignments.csv</strong> – asignaciones por miRNA</li>
        <li><strong>clusters/S3_cluster_summary.csv</strong> – tamaños y estadísticos por cluster</li>
      </ul>
    </div>
  </div>
</body>
</html>')

writeLines(html_content, output_html)
cat("✅ Step 3 viewer generated:", output_html, "\n")



