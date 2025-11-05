# 🧪 TEST: GENERATE FIGURE 1 V2 (COMPLEX & DENSE)

## 📋 SETUP
rm(list = ls())
cat("🧪 Generating Figure 1 v2 with real data...\n\n")

## 📦 LOAD LIBRARIES
suppressPackageStartupMessages({
  library(tidyverse)
  library(patchwork)
  library(viridis)
})

## ⚙️ CONFIGURATION
source("config/config_pipeline_2.R")
source("functions/visualization_functions_v2.R")

## 📥 LOAD DATA
cat("📥 Loading data from original pipeline...\n")

data_path <- "/Users/cesaresparza/New_Desktop/UCSD/8OG/results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt"

if (!file.exists(data_path)) {
  stop("❌ File not found: ", data_path)
}

raw_data <- read_tsv(data_path, show_col_types = FALSE)
cat("✅ Data loaded:", format(nrow(raw_data), big.mark=","), "rows\n")

## 🔧 PROCESS DATA
cat("🔧 Processing data (separate_rows)...\n")

processed_data <- raw_data %>%
  separate_rows(`pos:mut`, sep = ",") %>%
  filter(!is.na(`pos:mut`), `pos:mut` != "")

cat("✅ Data processed:", format(nrow(processed_data), big.mark=","), "rows\n")
cat("📊 Unique miRNAs:", format(n_distinct(processed_data$`miRNA name`), big.mark=","), "\n\n")

## 📊 PREPARE DATA
data_list <- list(
  raw = raw_data,
  processed = processed_data
)

## 🎨 GENERATE FIGURE 1 V2
cat("🎨 Generating Figure 1 v2 (complex & data-dense)...\n\n")

dir.create(figures_dir, showWarnings = FALSE, recursive = TRUE)

figure_1 <- create_figure_1_v2(data_list, figures_dir)

cat("\n✅ Figure 1 v2 generated successfully\n")
cat("📁 Main figure: figures/figure_1_dataset_characterization_v2.png\n")
cat("📁 Individual panels also saved for inspection\n")
cat("\n🎉 Process completed - Ready to view in HTML\n")

