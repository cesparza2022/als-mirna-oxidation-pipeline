# 🧪 TESTING SCRIPT FOR FIGURE 1 V5 (UPDATED COLOR SCHEME)

# 1. 🧹 Clean environment
rm(list = ls())

## 📦 LOAD LIBRARIES
library(tidyverse)
library(patchwork)
library(viridis)
library(scales)

## ⚙️ CONFIGURATION
source("config/config_pipeline_2.R")
source("functions/visualization_functions_v5.R")

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

# Create data list
data_list <- list(
  raw = raw_data,
  processed = processed_data
)

## 🎨 GENERATE FIGURE 1 V5
cat("🎨 Generating Figure 1 v5 (updated color scheme)...\n")

dir.create(figures_dir, showWarnings = FALSE, recursive = TRUE)

tryCatch({
  figure_1_v5 <- create_figure_1_v5(data_list, figures_dir)
  
  cat("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
  cat("  🎉 FIGURE 1 V5 COMPLETED SUCCESSFULLY\n")
  cat("  🎨 NEW COLOR SCHEME APPLIED\n")
  cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")
  
  cat("📊 KEY CHANGES:\n")
  cat("   • 🟠 Orange for G>T (neutral, oxidative)\n")
  cat("   • 🟡 Gold for Seed region (functional)\n")
  cat("   • 🔴 Red RESERVED for ALS (Figure 3+)\n\n")
  
  cat("📁 OUTPUTS:\n")
  cat("   • Main: figures/figure_1_v5_updated_colors.png\n")
  cat("   • Panels: figures/panel_[a-d]_*_v5.png\n\n")
  
}, error = function(e) {
  cat("❌ Error:\n")
  cat("   ", e$message, "\n")
})

cat("🎉 Process completed\n")

