# 🧪 TEST DATA TRANSFORMATION

rm(list = ls())

library(tidyverse)

source("functions/data_transformation.R")

cat("🧪 TESTING DATA TRANSFORMATION\n")
cat("════════════════════════════════════════════════════════════\n\n")

## 1. Load raw data
cat("📥 Step 1: Loading raw data...\n")
data_path <- "/Users/cesaresparza/New_Desktop/UCSD/8OG/results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt"
raw_data <- read_tsv(data_path, show_col_types = FALSE)
cat("   ✅ Loaded:", nrow(raw_data), "rows,", ncol(raw_data), "columns\n\n")

## 2. Extract groups from column names
cat("📥 Step 2: Extracting groups...\n")
groups <- extract_groups_from_colnames(raw_data)

## 3. Transform to long format
cat("📥 Step 3: Transforming WIDE → LONG...\n")
data_long <- transform_wide_to_long_with_groups(raw_data, groups)

## 4. Validate
cat("📥 Step 4: Validating transformation...\n")
valid <- validate_transformed_data(data_long)

## 5. Quick exploration
cat("\n🔍 QUICK EXPLORATION OF TRANSFORMED DATA:\n")
cat("════════════════════════════════════════════════════════════\n\n")

# First rows
cat("📊 First 10 rows:\n")
print(head(data_long, 10))

# G>T by group
cat("\n📊 G>T mutations by group:\n")
gt_by_group <- data_long %>%
  filter(mutation_type == "G>T") %>%
  group_by(group) %>%
  summarise(
    n_samples = n_distinct(sample_id),
    n_mutations = n(),
    n_mirnas = n_distinct(`miRNA name`),
    mean_vaf = mean(vaf, na.rm = TRUE),
    .groups = "drop"
  )
print(gt_by_group)

# Per-sample G>T count
cat("\n📊 Per-sample G>T distribution:\n")
per_sample_gt <- data_long %>%
  filter(mutation_type == "G>T") %>%
  group_by(sample_id, group) %>%
  summarise(gt_count = n(), .groups = "drop")

per_sample_summary <- per_sample_gt %>%
  group_by(group) %>%
  summarise(
    n_samples = n(),
    median_gt = median(gt_count),
    mean_gt = mean(gt_count),
    sd_gt = sd(gt_count),
    min_gt = min(gt_count),
    max_gt = max(gt_count),
    .groups = "drop"
  )
print(per_sample_summary)

cat("\n✅ TRANSFORMATION TEST SUCCESSFUL\n")
cat("════════════════════════════════════════════════════════════\n")
cat("📁 Data ready for group comparisons\n")
cat("🎯 Next: Implement REAL comparison functions\n")

