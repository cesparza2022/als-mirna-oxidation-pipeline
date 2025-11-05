# 🚀 GENERATE FIGURE 3 WITH REAL DATA - COMPLETE WORKFLOW

rm(list = ls())

library(tidyverse)
library(patchwork)
library(scales)
library(ggrepel)

## ═══════════════════════════════════════════════════════════════════════════
## LOAD ALL FUNCTIONS
## ═══════════════════════════════════════════════════════════════════════════

source("config/config_pipeline_2.R")
source("functions/data_transformation.R")
source("functions/comparison_functions_REAL.R")
source("functions/comparison_visualizations.R")

## ═══════════════════════════════════════════════════════════════════════════
## COLOR PALETTE
## ═══════════════════════════════════════════════════════════════════════════

COLOR_ALS <- "#E31A1C"           # 🔴 RED
COLOR_CONTROL <- "#1F78B4"       # 🔵 BLUE
COLOR_SEED_SHADE <- "#FFD70020"  # 🟡 GOLD transparent
COLOR_SEED <- "#FFD700"          # 🟡 GOLD

cat("\n🚀 ═══════════════════════════════════════════════════════════\n")
cat("   FIGURE 3: GROUP COMPARISON WITH REAL DATA\n")
cat("   ═══════════════════════════════════════════════════════════\n\n")

## ═══════════════════════════════════════════════════════════════════════════
## STEP 1: LOAD AND TRANSFORM DATA
## ═══════════════════════════════════════════════════════════════════════════

cat("📥 STEP 1: Loading and transforming data...\n\n")

# Load raw data
data_path <- "/Users/cesaresparza/New_Desktop/UCSD/8OG/results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt"
raw_data <- read_tsv(data_path, show_col_types = FALSE)
cat("✅ Raw data loaded:", nrow(raw_data), "rows\n\n")

# Extract groups
groups <- extract_groups_from_colnames(raw_data)

# Transform to long format
cat("⏳ Transforming data (this may take 2-3 minutes for large dataset)...\n")
data_long <- transform_wide_to_long_with_groups(raw_data, groups)

# Validate
validate_transformed_data(data_long)

## ═══════════════════════════════════════════════════════════════════════════
## STEP 2: RUN ALL COMPARISONS (REAL DATA)
## ═══════════════════════════════════════════════════════════════════════════

cat("📊 STEP 2: Running statistical comparisons...\n")

comparison_results <- run_all_comparisons_REAL(data_long)

## ═══════════════════════════════════════════════════════════════════════════
## STEP 3: GENERATE FIGURE 3 PANELS
## ═══════════════════════════════════════════════════════════════════════════

cat("🎨 STEP 3: Generating Figure 3 panels...\n\n")

dir.create(figures_dir, showWarnings = FALSE, recursive = TRUE)

# Panel A: Global burden
cat("  🎨 Panel A: Global G>T burden...\n")
panel_a <- create_global_burden_plot(
  burden_data = comparison_results$global$per_sample_burden,
  test_result = comparison_results$global$test_result
)
cat("     ✅ Panel A created\n")

# Panel B: Position delta ⭐ YOUR FAVORITE
cat("  🎨 Panel B: Position delta curve (⭐ FAVORITE - REAL DATA)...\n")
panel_b <- create_position_delta_plot(comparison_results$positions)
cat("     ✅ Panel B created with REAL statistics\n")

# Panel C: Seed interaction
cat("  🎨 Panel C: Seed vs non-seed interaction...\n")
panel_c <- create_seed_interaction_plot(comparison_results$seed)
cat("     ✅ Panel C created\n")

# Panel D: Volcano plot
cat("  🎨 Panel D: Differential miRNAs (volcano)...\n")
panel_d <- create_volcano_plot(comparison_results$mirnas, top_n = 10)
cat("     ✅ Panel D created\n\n")

## ═══════════════════════════════════════════════════════════════════════════
## STEP 4: SAVE PANELS
## ═══════════════════════════════════════════════════════════════════════════

cat("💾 STEP 4: Saving panels...\n")

# Individual panels first
ggsave(file.path(figures_dir, "panel_a_global_burden_REAL.png"), 
       plot = panel_a, width = 10, height = 8, dpi = 300, bg = "white")
cat("  ✅ Panel A saved\n")

ggsave(file.path(figures_dir, "panel_b_position_delta_REAL.png"), 
       plot = panel_b, width = 12, height = 8, dpi = 300, bg = "white")
cat("  ✅ Panel B saved (⭐ REAL DATA)\n")

ggsave(file.path(figures_dir, "panel_c_seed_interaction_REAL.png"), 
       plot = panel_c, width = 10, height = 8, dpi = 300, bg = "white")
cat("  ✅ Panel C saved\n")

ggsave(file.path(figures_dir, "panel_d_volcano_REAL.png"), 
       plot = panel_d, width = 10, height = 8, dpi = 300, bg = "white")
cat("  ✅ Panel D saved\n\n")

# Combined figure
cat("💾 Creating combined figure...\n")
tryCatch({
  figure_3 <- (panel_a | panel_b) / (panel_c | panel_d) +
    plot_annotation(
      title = "FIGURE 3: Group Comparison (ALS vs Control) - REAL DATA",
      subtitle = "🔴 Red = ALS | 🔵 Blue = Control | Statistical tests with FDR correction",
      theme = theme(
        plot.title = element_text(size = 18, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray30")
      )
    )
  
  ggsave(
    filename = file.path(figures_dir, "figure_3_group_comparison_REAL.png"),
    plot = figure_3,
    width = 20, height = 16, dpi = 300, bg = "white"
  )
  cat("  ✅ Combined figure saved\n")
}, error = function(e) {
  cat("  ⚠️  Combined figure error (panels saved individually)\n")
})

## ═══════════════════════════════════════════════════════════════════════════
## STEP 5: SUMMARY
## ═══════════════════════════════════════════════════════════════════════════

cat("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("  🎉 FIGURE 3 GENERATED WITH REAL DATA\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

cat("📁 OUTPUTS:\n")
cat("   • panel_a_global_burden_REAL.png\n")
cat("   • panel_b_position_delta_REAL.png ⭐\n")
cat("   • panel_c_seed_interaction_REAL.png\n")
cat("   • panel_d_volcano_REAL.png\n")
cat("   • figure_3_group_comparison_REAL.png (combined)\n\n")

cat("📊 STATISTICAL SUMMARY:\n")
cat("   • Global burden test: p", format_pvalue(comparison_results$global$test_result$p.value), "\n")
cat("   • Effect size (Cohen's d):", round(comparison_results$global$effect_size, 3), "\n")
cat("   • Significant positions:", sum(comparison_results$positions$significant, na.rm = TRUE), "/22\n")
cat("   • Differential miRNAs:", sum(comparison_results$mirnas$significant, na.rm = TRUE), "\n\n")

cat("🎨 COLORS USED:\n")
cat("   • 🔴 RED for ALS\n")
cat("   • 🔵 BLUE for Control\n")
cat("   • 🟡 GOLD for Seed region\n")
cat("   • ⭐ BLACK stars for significance\n\n")

cat("✅ FIGURE 3 COMPLETE - READY FOR PUBLICATION\n")
cat("📊 Questions answered: SQ2.1, SQ2.2, SQ2.3, SQ2.4\n")
cat("📈 Total progress: 10/16 questions (63%)\n\n")

