# 🧪 TESTING SCRIPT FOR FIGURE 3 - GROUP COMPARISON (Dummy Data)

# 1. 🧹 Clean environment
rm(list = ls())

## 📦 LOAD LIBRARIES
library(tidyverse)
library(patchwork)
library(scales)
library(ggrepel)

## ⚙️ CONFIGURATION
source("config/config_pipeline_2.R")
source("functions/comparison_visualizations.R")

## 📥 LOAD DATA
cat("📥 Loading data...\n")

data_path <- "/Users/cesaresparza/New_Desktop/UCSD/8OG/results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt"
raw_data <- read_tsv(data_path, show_col_types = FALSE)
cat("✅ Data loaded:", nrow(raw_data), "rows\n\n")

## 🔧 PROCESS DATA
cat("🔧 Processing data...\n")

processed_data <- raw_data %>%
  separate_rows(`pos:mut`, sep = ",") %>%
  filter(`pos:mut` != "PM")

cat("✅ Data processed:", nrow(processed_data), "valid SNVs\n\n")

## 👥 EXTRACT OR CREATE GROUPS
cat("👥 Extracting sample groups...\n")

# Option 1: Extract from column names (if available)
sample_cols <- names(raw_data)[!names(raw_data) %in% c("miRNA name", "pos:mut")]

groups <- tibble(sample_id = sample_cols) %>%
  mutate(
    group = case_when(
      str_detect(sample_id, "ALS") ~ "ALS",
      str_detect(sample_id, "control") ~ "Control",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(group))

cat("✅ Groups extracted:\n")
cat("   • ALS samples:", sum(groups$group == "ALS"), "\n")
cat("   • Control samples:", sum(groups$group == "Control"), "\n\n")

## 📊 GENERATE FIGURE 3
cat("🎨 Generating Figure 3 (Group Comparison)...\n")
cat("   🔴 RED for ALS\n")
cat("   🔵 BLUE for Control\n")
cat("   ⭐ Stars for significance\n\n")

dir.create(figures_dir, showWarnings = FALSE, recursive = TRUE)

tryCatch({
  figure_3 <- create_figure_3_comparison(
    processed_data = processed_data,
    groups = groups,
    output_dir = figures_dir
  )
  
  cat("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
  cat("  🎉 FIGURE 3 COMPLETED SUCCESSFULLY\n")
  cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")
  
  cat("📁 OUTPUTS:\n")
  cat("   • Main figure: figures/figure_3_group_comparison.png\n")
  cat("   • Panel A: figures/panel_a_global_burden.png\n")
  cat("   • Panel B: figures/panel_b_position_delta.png ⭐ FAVORITE\n")
  cat("   • Panel C: figures/panel_c_seed_interaction.png\n")
  cat("   • Panel D: figures/panel_d_volcano.png\n\n")
  
  cat("🎨 COLOR SCHEME:\n")
  cat("   • 🔴 RED (#E31A1C) = ALS\n")
  cat("   • 🔵 BLUE (#1F78B4) = Control\n")
  cat("   • 🟡 GOLD shading = Seed region (2-8)\n")
  cat("   • ⭐ BLACK stars = Significance (*, **, ***)\n\n")
  
  cat("📊 STATISTICAL FEATURES:\n")
  cat("   • Wilcoxon tests per position\n")
  cat("   • FDR correction (Benjamini-Hochberg)\n")
  cat("   • Fisher's exact for seed × group\n")
  cat("   • Volcano plot with q-value thresholds\n\n")
  
  cat("⚠️  NOTE: Using simulated statistics (dummy data)\n")
  cat("💡 NEXT: Implement real sample-level analysis for actual comparisons\n\n")
  
}, error = function(e) {
  cat("❌ Error generating Figure 3:\n")
  cat("   ", e$message, "\n\n")
})

cat("🎉 Process completed\n")

