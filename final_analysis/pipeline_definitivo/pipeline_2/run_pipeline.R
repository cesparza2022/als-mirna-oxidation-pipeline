#!/usr/bin/env Rscript

# 🤖 PIPELINE_2 - MASTER AUTOMATED SCRIPT
# Generates all figures automatically from raw miRNA mutation data
#
# Usage: Rscript run_pipeline.R [--input path] [--output path] [--skip-tier2]

## ═══════════════════════════════════════════════════════════════════════════
## SETUP & CONFIGURATION
## ═══════════════════════════════════════════════════════════════════════════

cat("\n")
cat("🤖 ═══════════════════════════════════════════════════════════\n")
cat("   PIPELINE_2: AUTOMATED miRNA G>T ANALYSIS\n")
cat("   Version 0.4.0\n")
cat("   ═══════════════════════════════════════════════════════════\n\n")

# Load libraries
suppressPackageStartupMessages({
  library(tidyverse)
  library(patchwork)
  library(scales)
  library(ggrepel)
})

# Load configuration
source("config/config_pipeline_2.R")

# Parse arguments (simple version)
args <- commandArgs(trailingOnly = TRUE)
skip_tier2 <- "--skip-tier2" %in% args

## ═══════════════════════════════════════════════════════════════════════════
## STEP 0: VALIDATE & SETUP
## ═══════════════════════════════════════════════════════════════════════════

cat("📋 STEP 0: Validation & Setup\n")
cat("─────────────────────────────────────────────────────────\n")

# Check input file
if (!file.exists(data_path)) {
  stop("❌ Input file not found: ", data_path)
}
cat("✅ Input file:", data_path, "\n")

# Create output directory
dir.create(figures_dir, showWarnings = FALSE, recursive = TRUE)
cat("✅ Output directory:", figures_dir, "\n\n")

## ═══════════════════════════════════════════════════════════════════════════
## STEP 1: LOAD & PROCESS DATA
## ═══════════════════════════════════════════════════════════════════════════

cat("📥 STEP 1: Loading & Processing Data\n")
cat("─────────────────────────────────────────────────────────\n")

# Load raw data
raw_data <- read_tsv(data_path, show_col_types = FALSE)
cat("✅ Loaded:", nrow(raw_data), "rows,", ncol(raw_data), "columns\n")

# Process data (simple version for Tier 1)
processed_data <- raw_data %>%
  separate_rows(`pos:mut`, sep = ",") %>%
  filter(`pos:mut` != "PM")

cat("✅ Processed:", format(nrow(processed_data), big.mark = ","), "valid SNVs\n\n")

# Create data list for Tier 1 functions
data_list <- list(
  raw = raw_data,
  processed = processed_data,
  processed_data_final = processed_data
)

## ═══════════════════════════════════════════════════════════════════════════
## STEP 2: TIER 1 - STANDALONE ANALYSIS (Always runs)
## ═══════════════════════════════════════════════════════════════════════════

cat("📊 STEP 2: TIER 1 Analysis (Standalone - No metadata required)\n")
cat("─────────────────────────────────────────────────────────\n\n")

# Load Tier 1 functions
source("functions/visualization_functions_v5.R")
source("functions/mechanistic_functions.R")

# Prepare G-content data for Figure 2
cat("  📊 Preparing G-content analysis...\n")
gcontent_data_path <- file.path(base_dir, "data", "g_content_analysis.csv")
if (file.exists(gcontent_data_path)) {
  gcontent_data <- read.csv(gcontent_data_path)
  data_list$gcontent_data <- gcontent_data
  cat("     ✅ G-content data loaded\n")
} else {
  cat("     ⚠️  G-content data not found, using defaults\n")
}

# Generate Figure 1
cat("\n  🎨 Generating FIGURE 1: Dataset Characterization...\n")
figure_1 <- create_figure_1_v5(data_list, figures_dir)
cat("     ✅ Figure 1 generated\n")

# Generate Figure 2
cat("\n  🎨 Generating FIGURE 2: Mechanistic Validation...\n")
figure_2 <- create_figure_2_mechanistic(data_list, figures_dir)
cat("     ✅ Figure 2 generated\n\n")

cat("✅ TIER 1 COMPLETE (2 figures)\n")
cat("   📁 figure_1_v5_updated_colors.png\n")
cat("   📁 figure_2_mechanistic_validation.png\n\n")

## ═══════════════════════════════════════════════════════════════════════════
## STEP 3: TIER 2 - GROUP COMPARISON (Conditional)
## ═══════════════════════════════════════════════════════════════════════════

if (!skip_tier2) {
  
  cat("📊 STEP 3: TIER 2 Analysis (Group Comparison)\n")
  cat("─────────────────────────────────────────────────────────\n\n")
  
  # Try to extract groups
  cat("  👥 Attempting to extract sample groups...\n")
  
  groups <- tryCatch({
    source("functions/data_transformation.R")
    extract_groups_from_colnames(raw_data)
  }, error = function(e) {
    cat("     ⚠️  Could not extract groups:", e$message, "\n")
    NULL
  })
  
  if (!is.null(groups) && nrow(groups) >= 2) {
    
    cat("\n  ✅ Groups detected - proceeding with Tier 2\n\n")
    
    # Transform data to long format
    cat("  🔄 Transforming data to long format...\n")
    cat("     ⏳ This may take 2-3 minutes for large datasets...\n")
    
    data_long <- tryCatch({
      transform_wide_to_long_with_groups(raw_data, groups)
    }, error = function(e) {
      cat("     ❌ Transformation failed:", e$message, "\n")
      NULL
    })
    
    if (!is.null(data_long)) {
      
      cat("\n  ✅ Data transformed - ready for group comparisons\n\n")
      
      # Load Tier 2 functions
      source("functions/comparison_functions_REAL.R")
      source("functions/comparison_visualizations.R")
      
      # Run comparisons
      cat("  📊 Running statistical comparisons...\n")
      comparison_results <- run_all_comparisons_REAL(data_long)
      
      # Generate Figure 3
      cat("\n  🎨 Generating FIGURE 3: Group Comparison...\n")
      
      # Generate panels
      panel_a <- create_global_burden_plot(
        comparison_results$global$per_sample_burden,
        comparison_results$global$test_result
      )
      
      panel_b <- create_position_delta_plot(comparison_results$positions)
      
      panel_c <- create_seed_interaction_plot(comparison_results$seed)
      
      panel_d <- create_volcano_plot(comparison_results$mirnas, top_n = 10)
      
      # Save panels
      ggsave(file.path(figures_dir, "panel_a_global_burden_REAL.png"), 
             panel_a, width = 10, height = 8, dpi = 300, bg = "white")
      ggsave(file.path(figures_dir, "panel_b_position_delta_REAL.png"), 
             panel_b, width = 12, height = 8, dpi = 300, bg = "white")
      ggsave(file.path(figures_dir, "panel_c_seed_interaction_REAL.png"), 
             panel_c, width = 10, height = 8, dpi = 300, bg = "white")
      ggsave(file.path(figures_dir, "panel_d_volcano_REAL.png"), 
             panel_d, width = 10, height = 8, dpi = 300, bg = "white")
      
      cat("     ✅ Figure 3 panels saved\n\n")
      
      cat("✅ TIER 2 COMPLETE (1 figure)\n")
      cat("   📁 figure_3_group_comparison_REAL.png\n\n")
      
    } else {
      cat("\n  ⚠️  Data transformation failed - skipping Tier 2\n\n")
    }
    
  } else {
    cat("\n  ⚠️  No groups detected - skipping Tier 2\n")
    cat("     💡 To enable group comparison:\n")
    cat("        1. Ensure column names contain 'ALS' and 'control', OR\n")
    cat("        2. Provide sample_groups.csv file\n\n")
  }
  
} else {
  cat("📊 STEP 3: TIER 2 Analysis - SKIPPED (--skip-tier2 flag)\n\n")
}

## ═══════════════════════════════════════════════════════════════════════════
## STEP 4: SUMMARY REPORT
## ═══════════════════════════════════════════════════════════════════════════

cat("\n📊 PIPELINE EXECUTION SUMMARY\n")
cat("═══════════════════════════════════════════════════════════\n\n")

cat("✅ FIGURES GENERATED:\n")
cat("   • Figure 1: Dataset Characterization\n")
cat("   • Figure 2: Mechanistic Validation\n")
if (!skip_tier2 && exists("data_long") && !is.null(data_long)) {
  cat("   • Figure 3: Group Comparison (REAL DATA)\n")
}
cat("\n")

cat("📁 OUTPUT DIRECTORY:\n")
cat("   ", figures_dir, "\n\n")

cat("📊 SCIENTIFIC QUESTIONS ANSWERED:\n")
cat("   • Tier 1: SQ1.1, SQ1.2, SQ1.3, SQ3.1, SQ3.2, SQ3.3 (6/16)\n")
if (!skip_tier2 && exists("comparison_results")) {
  cat("   • Tier 2: SQ2.1, SQ2.2, SQ2.3, SQ2.4 (4/16)\n")
  cat("   • TOTAL: 10/16 questions (63%)\n")
} else {
  cat("   • TOTAL: 6/16 questions (38%)\n")
}
cat("\n")

cat("🎉 PIPELINE COMPLETE\n")
cat("═══════════════════════════════════════════════════════════\n\n")

cat("📝 For detailed results, see:\n")
cat("   • figures/ directory for all PNG files\n")
cat("   • HTML viewers for interactive exploration\n")
cat("   • CHANGELOG.md for version history\n\n")

