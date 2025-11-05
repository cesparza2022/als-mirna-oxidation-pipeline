# 🧪 TEST: GENERATE FIGURE 1 V3 (CORRECTED DATA PROCESSING)

## 📋 SETUP
rm(list = ls())
cat("🧪 Generating Figure 1 v3 with CORRECTED data processing...\n\n")

## 📦 LOAD LIBRARIES
suppressPackageStartupMessages({
  library(tidyverse)
  library(patchwork)
  library(viridis)
})

## ⚙️ CONFIGURATION
source("config/config_pipeline_2.R")
source("functions/visualization_functions_v3.R")

## 📥 LOAD DATA
cat("📥 Loading data from original pipeline...\n")

data_path <- "/Users/cesaresparza/New_Desktop/UCSD/8OG/results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt"

if (!file.exists(data_path)) {
  stop("❌ File not found: ", data_path)
}

raw_data <- read_tsv(data_path, show_col_types = FALSE)
cat("✅ Data loaded:", format(nrow(raw_data), big.mark=","), "rows\n")

## 🔧 PROCESS DATA (CORRECTED)
cat("🔧 Processing data (separate_rows + filter PM)...\n")

processed_data <- raw_data %>%
  separate_rows(`pos:mut`, sep = ",") %>%
  filter(!is.na(`pos:mut`), `pos:mut` != "")

cat("✅ Data processed:", format(nrow(processed_data), big.mark=","), "rows\n")
cat("📊 Unique miRNAs:", format(n_distinct(processed_data$`miRNA name`), big.mark=","), "\n")

# Check mutation types
cat("\n🔍 MUTATION TYPES ANALYSIS:\n")
mutation_analysis <- processed_data %>%
  filter(`pos:mut` != "PM") %>%
  mutate(
    position = as.numeric(str_extract(`pos:mut`, "^[0-9]+")),
    mutation_type = str_extract(`pos:mut`, "[ATCG]>[ATCG]")
  ) %>%
  filter(!is.na(mutation_type))

cat("📊 Valid mutations (no PM):", format(nrow(mutation_analysis), big.mark=","), "\n")
cat("📊 G>T mutations:", format(sum(str_detect(mutation_analysis$mutation_type, "G>T")), big.mark=","), "\n")

# Show top mutation types
top_mutations <- mutation_analysis %>%
  count(mutation_type, sort = TRUE) %>%
  head(10)

cat("\n📈 TOP 10 MUTATION TYPES:\n")
print(top_mutations)

## 📊 PREPARE DATA
data_list <- list(
  raw = raw_data,
  processed = processed_data
)

## 🎨 GENERATE FIGURE 1 V3
cat("\n🎨 Generating Figure 1 v3 (corrected processing)...\n\n")

dir.create(figures_dir, showWarnings = FALSE, recursive = TRUE)

figure_1 <- create_figure_1_v3_corrected(data_list, figures_dir)

cat("\n✅ Figure 1 v3 generated successfully\n")
cat("📁 Main figure: figures/figure_1_initial_analysis_v3.png\n")
cat("📁 Individual panels also saved for inspection\n")
cat("\n🎉 Process completed - Ready to view in HTML\n")

