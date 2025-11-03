#!/usr/bin/env Rscript
# ============================================================================
# STEP 4.2: Biomarker Signature Heatmap
# ============================================================================
# Purpose: Create comprehensive heatmap showing biomarker signatures
# 
# This figure shows:
# 1. Heatmap of top biomarkers across samples
# 2. Sample clustering (ALS vs Control)
# 3. Biomarker performance metrics
# 4. Combined signature visualization
#
# Snakemake parameters:
#   input: ROC results and VAF-filtered data
#   output: Comprehensive biomarker heatmap
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
  library(readr)
  library(pheatmap)
  library(RColorBrewer)
})

# Load common functions
source(snakemake@params[["functions"]], local = TRUE)

# Initialize logging
log_file <- if (length(snakemake@log) > 0) snakemake@log[[1]] else {
  file.path(dirname(snakemake@output[[1]]), "biomarker_signature_heatmap.log")
}
initialize_logging(log_file, context = "Step 4.2 - Biomarker Signature Heatmap")

log_section("STEP 4.2: Biomarker Signature Heatmap")

# ============================================================================
# GET SNAKEMAKE PARAMETERS
# ============================================================================

input_roc <- snakemake@input[["roc_table"]]
input_vaf_filtered <- snakemake@input[["vaf_filtered"]]
output_heatmap <- snakemake@output[["heatmap"]]

config <- snakemake@config
color_gt <- if (!is.null(config$analysis$colors$gt)) config$analysis$colors$gt else "#D62728"
color_control <- if (!is.null(config$analysis$colors$control)) config$analysis$colors$control else "grey60"

log_info(paste("Input ROC:", input_roc))
log_info(paste("Input VAF filtered:", input_vaf_filtered))
ensure_output_dir(dirname(output_heatmap))

# ============================================================================
# LOAD DATA
# ============================================================================

log_subsection("Loading data")

roc_table <- read_csv(input_roc, show_col_types = FALSE)
vaf_data <- read_csv(input_vaf_filtered, show_col_types = FALSE)

# Extract sample groups
sample_cols <- setdiff(names(vaf_data), c("miRNA_name", "pos.mut"))
sample_groups <- tibble(sample_id = sample_cols) %>%
  mutate(
    group = case_when(
      str_detect(sample_id, regex("ALS", ignore_case = TRUE)) ~ "ALS",
      str_detect(sample_id, regex("control|Control|CTRL", ignore_case = TRUE)) ~ "Control",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(group))

# Select top 15 biomarkers
top_biomarkers <- roc_table %>%
  filter(AUC >= 0.7) %>%  # Only good biomarkers
  arrange(desc(AUC)) %>%
  head(15)

log_info(paste("Top biomarkers selected:", nrow(top_biomarkers)))

# ============================================================================
# PREPARE HEATMAP DATA
# ============================================================================

log_subsection("Preparing heatmap data")

# Extract data for top biomarkers
heatmap_matrix_list <- list()

for (i in 1:nrow(top_biomarkers)) {
  snv_id <- top_biomarkers$SNV_id[i]
  mirna <- top_biomarkers$miRNA_name[i]
  
  snv_data <- vaf_data %>%
    filter(paste(miRNA_name, pos.mut, sep = "|") == snv_id) %>%
    select(all_of(sample_cols))
  
  if (nrow(snv_data) > 0) {
    values <- as.numeric(snv_data[1, sample_cols])
    names(values) <- sample_cols
    heatmap_matrix_list[[paste0(mirna, "|", snv_id)]] <- values
  }
}

# Combine into matrix
if (length(heatmap_matrix_list) > 0) {
  heatmap_df <- bind_cols(heatmap_matrix_list) %>%
    mutate(sample_id = sample_cols) %>%
    left_join(sample_groups, by = "sample_id") %>%
    arrange(group)  # Sort by group
  
  # Remove samples with too many NAs
  heatmap_df <- heatmap_df %>%
    filter(rowSums(is.na(select(., -sample_id, -group))) / (ncol(.) - 2) < 0.5)
  
  # Prepare matrix (transpose for pheatmap: rows = biomarkers, cols = samples)
  heatmap_matrix <- heatmap_df %>%
    select(-sample_id, -group) %>%
    t() %>%
    as.matrix()
  
  colnames(heatmap_matrix) <- heatmap_df$sample_id
  
  # Normalize by row (z-score)
  heatmap_matrix_norm <- t(scale(t(heatmap_matrix)))
  
  # Create annotation for samples
  sample_annotation <- heatmap_df %>%
    select(sample_id, Group = group) %>%
    column_to_rownames("sample_id")
  
  # Create annotation for biomarkers (AUC values)
  biomarker_annotation <- top_biomarkers %>%
    head(nrow(heatmap_matrix_norm)) %>%
    mutate(
      Biomarker = paste(miRNA_name, pos.mut, sep = "|"),
      AUC_category = case_when(
        AUC >= 0.9 ~ "Excellent",
        AUC >= 0.8 ~ "Good",
        TRUE ~ "Fair"
      )
    ) %>%
    select(Biomarker, AUC, AUC_category) %>%
    column_to_rownames("Biomarker")
  
  # Match row names
  rownames(heatmap_matrix_norm) <- rownames(biomarker_annotation)
  
  # Color schemes
  group_colors <- c("ALS" = color_gt, "Control" = color_control)
  auc_colors <- colorRampPalette(c("white", color_gt))(100)
  
  # ============================================================================
  # GENERATE HEATMAP
  # ============================================================================
  
  log_subsection("Generating comprehensive heatmap")
  
  png(output_heatmap, width = 16, height = 12, units = "in", res = 300)
  
  pheatmap(
    heatmap_matrix_norm,
    color = colorRampPalette(c("#2E86AB", "white", color_gt))(100),
    cluster_rows = TRUE,
    cluster_cols = TRUE,
    show_colnames = FALSE,
    show_rownames = TRUE,
    annotation_col = sample_annotation,
    annotation_row = biomarker_annotation %>% select(AUC_category),
    annotation_colors = list(
      Group = group_colors,
      AUC_category = c("Excellent" = "#D62728", "Good" = "#FF7F0E", "Fair" = "#2CA02C")
    ),
    main = "Biomarker Signature Heatmap\nTop Performing miRNA Oxidation Patterns",
    fontsize = 10,
    fontsize_row = 9,
    fontsize_col = 6,
    angle_col = 90,
    border_color = "grey60",
    gaps_col = sum(sample_annotation$Group == "Control"),  # Gap between groups
    legend = TRUE,
    legend_breaks = c(min(heatmap_matrix_norm, na.rm = TRUE), 
                     0, 
                     max(heatmap_matrix_norm, na.rm = TRUE)),
    legend_labels = c("Low", "0 (mean)", "High"),
    display_numbers = FALSE,
    treeheight_row = 50,
    treeheight_col = 50
  )
  
  dev.off()
  
  log_success(paste("Heatmap saved:", output_heatmap))
} else {
  log_warning("No biomarkers found for heatmap")
  # Create empty placeholder
  png(output_heatmap, width = 10, height = 8, units = "in", res = 300)
  plot.new()
  text(0.5, 0.5, "No biomarkers with AUC >= 0.7 found", cex = 1.5)
  dev.off()
}

log_success("Step 4.2 completed successfully")

