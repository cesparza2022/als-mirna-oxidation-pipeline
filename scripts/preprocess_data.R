#!/usr/bin/env Rscript
# ============================================================================
# PREPROCESS DATA FOR SNAKEMAKE PIPELINE
# ============================================================================
# This script processes raw miRNA data to create the files needed by the pipeline:
# 1. processed_clean.csv - For Step 1 (after split-collapse, VAF calculated)
# 2. step1_original_data.csv - For Step 1.5 (original format with SNV + total counts)
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(readr)
  library(stringr)
})

# ============================================================================
# CONFIGURATION
# ============================================================================

# Get command line arguments or use defaults
args <- commandArgs(trailingOnly = TRUE)

if (length(args) >= 1) {
  RAW_DATA_PATH <- args[1]
} else {
  RAW_DATA_PATH <- "/Users/cesaresparza/New_Desktop/UCSD/8OG/organized/02_data/Magen_ALS-bloodplasma/miRNA_count.Q33.txt"
}

if (length(args) >= 2) {
  OUTPUT_DIR <- args[2]
} else {
  OUTPUT_DIR <- "/Users/cesaresparza/New_Desktop/UCSD/8OG/data/processed"
}

# Create output directory
dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)

cat("============================================================================\n")
cat("PREPROCESSING DATA FOR SNAKEMAKE PIPELINE\n")
cat("============================================================================\n")
cat("Raw data:", RAW_DATA_PATH, "\n")
cat("Output directory:", OUTPUT_DIR, "\n")
cat("Started at:", Sys.time(), "\n\n")

# ============================================================================
# STEP 1: LOAD RAW DATA
# ============================================================================

cat("STEP 1: Loading raw data...\n")
raw_data <- read_tsv(RAW_DATA_PATH, 
                     col_types = cols(.default = "c"),
                     show_col_types = FALSE)

cat("  ✓ Loaded:", nrow(raw_data), "rows,", ncol(raw_data), "columns\n")
cat("  ✓ miRNAs:", length(unique(raw_data$`miRNA name`)), "unique\n\n")

# ============================================================================
# STEP 2: IDENTIFY COLUMNS
# ============================================================================

cat("STEP 2: Identifying column structure...\n")

# Metadata columns
metadata_cols <- c("miRNA name", "pos:mut")

# Identify sample columns (SNV counts)
# Pattern: Sample names without " (PM+1MM+2MM)" suffix
all_cols <- colnames(raw_data)
sample_snv_cols <- all_cols[!all_cols %in% metadata_cols & 
                           !str_detect(all_cols, " \\(PM\\+1MM\\+2MM\\)$")]

# Identify total columns (PM+1MM+2MM)
sample_total_cols <- all_cols[str_detect(all_cols, " \\(PM\\+1MM\\+2MM\\)$")]

# Match SNV columns with total columns
sample_names <- str_replace(sample_total_cols, " \\(PM\\+1MM\\+2MM\\)$", "")
matched_snv_cols <- paste0(sample_names, "_SNV")

cat("  ✓ Sample SNV columns:", length(sample_snv_cols), "\n")
cat("  ✓ Sample total columns:", length(sample_total_cols), "\n")
cat("  ✓ Samples identified:", length(sample_names), "\n\n")

# ============================================================================
# STEP 3: SAVE ORIGINAL DATA FOR STEP 1.5
# ============================================================================

cat("STEP 3: Saving original data for Step 1.5...\n")

# Rename columns to standardize format
original_data <- raw_data %>%
  rename(
    `miRNA_name` = `miRNA name`,
    `pos.mut` = `pos:mut`
  )

# Rename sample columns to have _SNV suffix
for (i in seq_along(sample_names)) {
  if (sample_names[i] %in% colnames(original_data)) {
    colnames(original_data)[colnames(original_data) == sample_names[i]] <- paste0(sample_names[i], "_SNV")
  }
}

# Rename total columns to remove spaces and parentheses
for (i in seq_along(sample_total_cols)) {
  if (sample_total_cols[i] %in% colnames(original_data)) {
    new_name <- paste0(sample_names[i], "_Total")
    colnames(original_data)[colnames(original_data) == sample_total_cols[i]] <- new_name
  }
}

output_original <- file.path(OUTPUT_DIR, "step1_original_data.csv")
write_csv(original_data, output_original)
cat("  ✓ Saved:", output_original, "\n")
cat("  ✓ Rows:", nrow(original_data), "\n\n")

# ============================================================================
# STEP 3.5: SAVE ORIGINAL DATA FOR STEP 1.5 (BEFORE SPLIT-COLLAPSE)
# ============================================================================

cat("STEP 3.5: Saving original data for Step 1.5 (with all columns including totals)...\n")
output_original <- file.path(OUTPUT_DIR, "step1_original_data.csv")
write_csv(raw_data, output_original)
cat("  ✓ Saved:", output_original, "\n")
cat("  ✓ Rows:", nrow(raw_data), "\n")
cat("  ✓ Columns:", ncol(raw_data), "\n")
cat("  ✓ Total columns:", length(sample_total_cols), "\n\n")

# ============================================================================
# STEP 4: APPLY SPLIT-COLLAPSE
# ============================================================================

cat("STEP 4: Applying split-collapse...\n")

# Split: Separate multiple mutations (comma-separated)
cat("  4.1 Splitting multiple mutations...\n")
data_split <- raw_data %>%
  separate_rows(`pos:mut`, sep = ",") %>%
  mutate(`pos:mut` = str_trim(`pos:mut`)) %>%
  filter(`pos:mut` != "PM")  # Remove perfect match entries

cat("    ✓ After split:", nrow(data_split), "rows\n")

# Collapse: Group by miRNA and mutation, sum counts
cat("  4.2 Collapsing identical mutations...\n")

# Get all sample columns (both SNV and total)
all_sample_cols <- c(sample_snv_cols, sample_total_cols)

data_collapsed <- data_split %>%
  group_by(`miRNA name`, `pos:mut`) %>%
  summarise(
    across(all_of(sample_snv_cols), ~ sum(as.numeric(.x), na.rm = TRUE)),
    across(all_of(sample_total_cols), ~ first(.x)),  # Total counts are the same
    .groups = "drop"
  )

cat("    ✓ After collapse:", nrow(data_collapsed), "unique mutations\n\n")

# ============================================================================
# STEP 5: CALCULATE VAFs
# ============================================================================

cat("STEP 5: Calculating VAFs (Variant Allele Frequencies)...\n")

# Convert to numeric
data_collapsed <- data_collapsed %>%
  mutate(across(all_of(c(sample_snv_cols, sample_total_cols)), as.numeric))

# Calculate VAF for each sample
vaf_data <- data_collapsed

for (i in seq_along(sample_names)) {
  snv_col <- sample_snv_cols[i]
  total_col <- sample_total_cols[i]
  vaf_col <- paste0("VAF_", sample_names[i])
  
  vaf_data[[vaf_col]] <- ifelse(
    vaf_data[[total_col]] > 0,
    vaf_data[[snv_col]] / vaf_data[[total_col]],
    NA_real_
  )
}

# Filter VAF > 50% (set to NaN for technical artifacts)
vaf_threshold <- 0.5
vaf_cols <- paste0("VAF_", sample_names)

for (vaf_col in vaf_cols) {
  sample_name <- str_replace(vaf_col, "VAF_", "")
  snv_col <- paste0(sample_name, "_SNV")
  
  # Set VAF to NaN where VAF > threshold
  high_vaf_mask <- !is.na(vaf_data[[vaf_col]]) & vaf_data[[vaf_col]] > vaf_threshold
  vaf_data[[vaf_col]][high_vaf_mask] <- NA_real_
  
  # Also set corresponding SNV count to NaN
  if (snv_col %in% colnames(vaf_data)) {
    vaf_data[[snv_col]][high_vaf_mask] <- NA_real_
  }
}

cat("  ✓ VAFs calculated for", length(vaf_cols), "samples\n")
cat("  ✓ VAFs > 50% filtered (set to NaN)\n\n")

# ============================================================================
# STEP 6: PREPARE PROCESSED CLEAN DATA FOR STEP 1
# ============================================================================

cat("STEP 6: Preparing processed clean data for Step 1...\n")

# Standardize column names (use dots instead of spaces)
processed_clean <- vaf_data %>%
  rename(
    `miRNA_name` = `miRNA name`,
    `pos.mut` = `pos:mut`
  )

# Keep metadata + VAF columns + SNV columns (for reference)
keep_cols <- c("miRNA_name", "pos.mut", 
               sample_snv_cols, 
               vaf_cols)

processed_clean <- processed_clean %>%
  select(all_of(keep_cols))

output_processed <- file.path(OUTPUT_DIR, "processed_clean.csv")
write_csv(processed_clean, output_processed)

cat("  ✓ Saved:", output_processed, "\n")
cat("  ✓ Rows:", nrow(processed_clean), "\n")
cat("  ✓ Columns:", ncol(processed_clean), "\n\n")

# ============================================================================
# SUMMARY
# ============================================================================

cat("============================================================================\n")
cat("PREPROCESSING COMPLETE\n")
cat("============================================================================\n")
cat("Output files:\n")
cat("  1. step1_original_data.csv:", output_original, "\n")
cat("  2. processed_clean.csv:", output_processed, "\n")
cat("\n")
cat("Statistics:\n")
cat("  - Original rows:", nrow(raw_data), "\n")
cat("  - After split:", nrow(data_split), "\n")
cat("  - After collapse:", nrow(data_collapsed), "\n")
cat("  - Final processed:", nrow(processed_clean), "\n")
cat("  - Samples:", length(sample_names), "\n")
cat("\n")
cat("Next steps:\n")
cat("  1. Update config/config.yaml with these paths:\n")
cat("     - processed_clean:", output_processed, "\n")
cat("     - step1_original:", output_original, "\n")
cat("  2. Run: snakemake -j 1 all_step1\n")
cat("\n")
cat("Completed at:", Sys.time(), "\n")

