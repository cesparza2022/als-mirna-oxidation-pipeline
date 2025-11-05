#!/usr/bin/env Rscript
# ============================================================================
# PASO 2 - COMPLETE PIPELINE
# Master script that generates ALL 15 figures from raw data
# ============================================================================
# 
# REQUIREMENTS:
#   - final_processed_data_CLEAN.csv (main dataset)
#   - metadata.csv (sample metadata with Group column)
#
# OUTPUT:
#   - 15 publication-ready figures (FIG_2.1 to FIG_2.15)
#   - All figures saved in figures/ directory
#   - All intermediate data saved in figures_paso2_CLEAN/
# ============================================================================

library(dplyr)
library(readr)

cat("\n")
cat("═════════════════════════════════════════════════════════════════════════\n")
cat("  PASO 2 - COMPLETE PIPELINE: ALS vs Control G>T Analysis\n")
cat("═════════════════════════════════════════════════════════════════════════\n")
cat("\n")

# ============================================================================
# VALIDATE INPUT DATA
# ============================================================================

cat("📂 STEP 0: Validating input data...\n\n")

if (!file.exists("final_processed_data_CLEAN.csv")) {
  stop("❌ ERROR: final_processed_data_CLEAN.csv not found!")
}

if (!file.exists("metadata.csv")) {
  stop("❌ ERROR: metadata.csv not found!")
}

# Load and validate
data <- read_csv("final_processed_data_CLEAN.csv", show_col_types = FALSE)
metadata <- read_csv("metadata.csv", show_col_types = FALSE)

cat("   ✅ Data loaded:", nrow(data), "SNVs\n")
cat("   ✅ Metadata loaded:", nrow(metadata), "samples\n")

# Validate metadata
if (!"Group" %in% colnames(metadata)) {
  stop("❌ ERROR: metadata.csv must have 'Group' column (ALS/Control)")
}

n_als <- sum(metadata$Group == "ALS")
n_ctrl <- sum(metadata$Group == "Control")

cat("   ✅ ALS samples:", n_als, "\n")
cat("   ✅ Control samples:", n_ctrl, "\n\n")

# Create output directories
dir.create("figures", showWarnings = FALSE)
dir.create("figures_paso2_CLEAN", showWarnings = FALSE)

cat("   ✅ Output directories ready\n\n")

# ============================================================================
# PIPELINE EXECUTION
# ============================================================================

cat("═════════════════════════════════════════════════════════════════════════\n")
cat("  EXECUTING PIPELINE - 15 FIGURES\n")
cat("═════════════════════════════════════════════════════════════════════════\n\n")

# Track execution time
start_time <- Sys.time()
figure_times <- list()

# ----------------------------------------------------------------------------
# GRUPO A: GLOBAL COMPARISONS
# ----------------------------------------------------------------------------

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("  GRUPO A: Global Comparisons\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

# Figure 2.1: VAF Comparison
cat("📊 Generating Figure 2.1: VAF Comparison (Linear)...\n")
t1 <- Sys.time()
source("generate_FIG_2.1_COMPARISON_LOG_VS_LINEAR.R", local = TRUE)
figure_times[["2.1"]] <- as.numeric(difftime(Sys.time(), t1, units = "secs"))
cat("\n")

# Figure 2.2: Distributions
cat("📊 Generating Figure 2.2: VAF Distributions...\n")
t2 <- Sys.time()
source("generate_FIG_2.2_SIMPLIFIED.R", local = TRUE)
figure_times[["2.2"]] <- as.numeric(difftime(Sys.time(), t2, units = "secs"))
cat("\n")

# Figure 2.3: Volcano
cat("📊 Generating Figure 2.3: Volcano Plot (Differential miRNAs)...\n")
t3 <- Sys.time()
source("generate_FIG_2.3_CORRECTED_AND_ANALYZE.R", local = TRUE)
figure_times[["2.3"]] <- as.numeric(difftime(Sys.time(), t3, units = "secs"))
cat("\n")

# ----------------------------------------------------------------------------
# GRUPO B: POSITIONAL ANALYSIS
# ----------------------------------------------------------------------------

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("  GRUPO B: Positional Analysis\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

# Figure 2.4: Heatmap RAW
cat("📊 Generating Figure 2.4: Heatmap RAW (ALL 301 miRNAs)...\n")
t4 <- Sys.time()
source("generate_FIG_2.4_HEATMAP_RAW.R", local = TRUE)
figure_times[["2.4"]] <- as.numeric(difftime(Sys.time(), t4, units = "secs"))
cat("\n")

# Figure 2.5: Z-score Heatmap
cat("📊 Generating Figure 2.5: Z-Score Heatmap (ALL 301 miRNAs)...\n")
t5 <- Sys.time()
source("generate_FIG_2.5_ZSCORE_ALL301.R", local = TRUE)
figure_times[["2.5"]] <- as.numeric(difftime(Sys.time(), t5, units = "secs"))
cat("\n")

# Figure 2.6: Positional Analysis
cat("📊 Generating Figure 2.6: Positional Line Plots...\n")
t6 <- Sys.time()
source("generate_FIG_2.6_POSITIONAL.R", local = TRUE)
figure_times[["2.6"]] <- as.numeric(difftime(Sys.time(), t6, units = "secs"))
cat("\n")

# Figures 2.13-2.15: Density Heatmaps
cat("📊 Generating Figures 2.13-2.15: Density Heatmaps...\n")
t13 <- Sys.time()
source("generate_FIG_2.13-15_DENSITY.R", local = TRUE)
figure_times[["2.13-15"]] <- as.numeric(difftime(Sys.time(), t13, units = "secs"))
cat("\n")

# ----------------------------------------------------------------------------
# GRUPO C: HETEROGENEITY ANALYSIS
# ----------------------------------------------------------------------------

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("  GRUPO C: Heterogeneity Analysis\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

# Figure 2.7: PCA + PERMANOVA
cat("📊 Generating Figure 2.7: PCA + PERMANOVA...\n")
t7 <- Sys.time()
source("generate_FIG_2.7_IMPROVED.R", local = TRUE)
figure_times[["2.7"]] <- as.numeric(difftime(Sys.time(), t7, units = "secs"))
cat("\n")

# Figure 2.8: Clustering
cat("📊 Generating Figure 2.8: Clustering Heatmap...\n")
t8 <- Sys.time()
source("generate_FIG_2.8_CLUSTERING.R", local = TRUE)
figure_times[["2.8"]] <- as.numeric(difftime(Sys.time(), t8, units = "secs"))
cat("\n")

# Figure 2.9: CV Analysis
cat("📊 Generating Figure 2.9: Coefficient of Variation Analysis...\n")
t9 <- Sys.time()
source("generate_FIG_2.9_IMPROVED.R", local = TRUE)
figure_times[["2.9"]] <- as.numeric(difftime(Sys.time(), t9, units = "secs"))
cat("\n")

# ----------------------------------------------------------------------------
# GRUPO D: SPECIFICITY & ENRICHMENT
# ----------------------------------------------------------------------------

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("  GRUPO D: Specificity & Enrichment\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

# Figure 2.10: G>T Ratio
cat("📊 Generating Figure 2.10: G>T Ratio Analysis...\n")
t10 <- Sys.time()
source("generate_FIG_2.10_GT_RATIO.R", local = TRUE)
figure_times[["2.10"]] <- as.numeric(difftime(Sys.time(), t10, units = "secs"))
cat("\n")

# Figure 2.11: Complete Mutation Spectrum
cat("📊 Generating Figure 2.11: Complete Mutation Spectrum...\n")
t11 <- Sys.time()
source("generate_FIG_2.11_IMPROVED.R", local = TRUE)
figure_times[["2.11"]] <- as.numeric(difftime(Sys.time(), t11, units = "secs"))
cat("\n")

# Figure 2.12: Enrichment Analysis
cat("📊 Generating Figure 2.12: Enrichment & Biomarker Candidates...\n")
t12 <- Sys.time()
source("generate_FIG_2.12_ENRICHMENT.R", local = TRUE)
figure_times[["2.12"]] <- as.numeric(difftime(Sys.time(), t12, units = "secs"))
cat("\n")

# ============================================================================
# PIPELINE SUMMARY
# ============================================================================

total_time <- as.numeric(difftime(Sys.time(), start_time, units = "mins"))

cat("\n")
cat("═════════════════════════════════════════════════════════════════════════\n")
cat("  PIPELINE EXECUTION SUMMARY\n")
cat("═════════════════════════════════════════════════════════════════════════\n\n")

cat("✅ COMPLETED FIGURES:\n\n")
for (fig in names(figure_times)) {
  cat(sprintf("   Fig 2.%-2s: %.1f seconds\n", fig, figure_times[[fig]]))
}

cat("\n")
cat("✅ ALL FIGURES COMPLETED!\n\n")

cat("📊 STATISTICS:\n\n")
cat(sprintf("   Total figures generated: %d / 15\n", length(figure_times)))
cat(sprintf("   Total execution time: %.1f minutes\n", total_time))
cat(sprintf("   Average time per figure: %.1f seconds\n\n", 
    mean(unlist(figure_times))))

cat("📁 OUTPUT DIRECTORIES:\n\n")
cat("   figures/               → Final figures (for HTML viewer)\n")
cat("   figures_paso2_CLEAN/   → All intermediate outputs\n\n")

cat("═════════════════════════════════════════════════════════════════════════\n")
cat("  PIPELINE READY FOR USE\n")
cat("═════════════════════════════════════════════════════════════════════════\n\n")

cat("✅ ALL 15 FIGURES GENERATED SUCCESSFULLY!\n\n")

cat("📁 OUTPUT STRUCTURE:\n\n")
cat("   figures/\n")
cat("   ├── FIG_2.1_VAF_COMPARISON_LINEAR.png\n")
cat("   ├── FIG_2.2_DISTRIBUTIONS_LINEAR.png\n")
cat("   ├── FIG_2.3_VOLCANO_COMBINADO.png\n")
cat("   ├── FIG_2.4_HEATMAP_ALL.png\n")
cat("   ├── FIG_2.5_ZSCORE_HEATMAP.png\n")
cat("   ├── FIG_2.6_POSITIONAL_ANALYSIS.png\n")
cat("   ├── FIG_2.7_PCA_PERMANOVA.png\n")
cat("   ├── FIG_2.8_CLUSTERING.png\n")
cat("   ├── FIG_2.9_COMBINED_IMPROVED.png\n")
cat("   ├── FIG_2.10_COMBINED.png\n")
cat("   ├── FIG_2.11_COMBINED_IMPROVED.png\n")
cat("   ├── FIG_2.12_COMBINED.png\n")
cat("   ├── FIG_2.13_DENSITY_HEATMAP_ALS.png\n")
cat("   ├── FIG_2.14_DENSITY_HEATMAP_CONTROL.png\n")
cat("   └── FIG_2.15_DENSITY_COMBINED.png\n\n")

cat("TO USE WITH NEW DATA:\n")
cat("   1. Place new dataset: final_processed_data_CLEAN.csv\n")
cat("   2. Place metadata: metadata.csv\n")
cat("   3. Run: Rscript RUN_COMPLETE_PIPELINE_PASO2.R\n\n")

cat("═════════════════════════════════════════════════════════════════════════\n\n")

cat("✅ PIPELINE EXECUTION COMPLETED\n\n")

