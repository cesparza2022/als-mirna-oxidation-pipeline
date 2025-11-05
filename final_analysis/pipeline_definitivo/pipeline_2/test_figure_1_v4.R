# 🧪 TESTING SCRIPT FOR FIGURE 1 V4 (CORRECTED MUTATION FORMAT)

# 1. 🧹 Clean environment
rm(list = ls())

## 📦 LOAD LIBRARIES
library(tidyverse)
library(patchwork)
library(viridis)

## ⚙️ CONFIGURATION
source("config/config_pipeline_2.R")
source("functions/visualization_functions_v4.R") # Load v4 visualization functions

## 📥 LOAD DATA FROM CORRECT PATH
cat("📥 Loading data from correct path...\n")

# Use the correct data path
data_path <- "/Users/cesaresparza/New_Desktop/UCSD/8OG/results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt"
raw_data <- read_tsv(data_path, show_col_types = FALSE)
cat("✅ Data loaded:", nrow(raw_data), "rows\n")

## 🔧 PROCESS DATA (CORRECTED FORMAT)
cat("🔧 Processing data (separate_rows + filter PM)...\n")

# Count original SNVs (before split-collapse)
original_snvs_count <- nrow(raw_data)

# Apply split-collapse and filter out "PM" (Perfect Match) entries
processed_data <- raw_data %>%
  separate_rows(`pos:mut`, sep = ",") %>%
  filter(`pos:mut` != "PM") # Filter out "PM" entries

# Count SNVs after split-collapse and filtering
processed_snvs_count <- nrow(processed_data)

# Count unique miRNAs
unique_mirnas_count <- processed_data %>%
  distinct(`miRNA name`) %>%
  nrow()

cat("✅ Data processed:", processed_snvs_count, "rows\n")
cat("📊 Unique miRNAs:", unique_mirnas_count, "\n\n")

# Debugging: Check mutation types and G>T counts
cat("🔍 MUTATION TYPES ANALYSIS:\n")
valid_mutations_count <- nrow(processed_data)
gt_mutations_count <- processed_data %>% 
  separate(`pos:mut`, into = c("position", "mutation_type"), sep = ":", remove = FALSE) %>%
  filter(mutation_type == "GT") %>% nrow()
cat("📊 Valid mutations (no PM):", valid_mutations_count, "\n")
cat("📊 G>T mutations (GT format):", gt_mutations_count, "\n\n")

cat("📈 TOP 10 MUTATION TYPES (original format):\n")
top_10_overall_muts_debug <- processed_data %>%
  separate(`pos:mut`, into = c("position", "mutation_type"), sep = ":", remove = FALSE) %>%
  filter(!is.na(mutation_type), mutation_type != "") %>%
  count(mutation_type, sort = TRUE) %>%
  head(10)
print(top_10_overall_muts_debug)
cat("\n")

# Create data list for visualization functions
data_list <- list(
  raw = raw_data,
  processed = processed_data
)

## 🎨 GENERATE FIGURE 1 V4
cat("🎨 Generating Figure 1 v4 (corrected mutation format)...\n\n")

dir.create(figures_dir, showWarnings = FALSE, recursive = TRUE)

tryCatch({
  figure_1_v4 <- create_figure_1_corrected(data_list, figures_dir)
  cat("✅ Figure 1 v4 generated successfully\n\n")
  cat("📁 Main figure: figures/figure_1_corrected.png\n")
  cat("📁 Individual panels also saved for inspection\n\n")
}, error = function(e) {
  cat("❌ Error generating Figure 1 v4:\n")
  cat("   ", e$message, "\n")
  cat("\n📊 Data structure for debug:\n")
  cat("   Columns available in processed_data:", paste(names(processed_data)[1:10], collapse = ", "), "...\n")
  cat("   First rows of processed_data:\n")
  print(head(processed_data[,1:5], 3))
})

cat("\n🎉 Process completed - Ready to view in HTML\n")

