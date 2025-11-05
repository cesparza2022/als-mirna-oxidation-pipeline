#!/usr/bin/env Rscript

# Debug script to understand VAF filter step by step
library(dplyr)
library(readr)

# Load the processed data
input_file <- "/Users/cesaresparza/New_Desktop/UCSD/8OG/outputs/processed_snv_data_vaf_filtered.tsv"
df <- read_tsv(input_file, show_col_types = FALSE)

cat("📊 Dataset loaded:", nrow(df), "rows,", ncol(df), "columns\n")

# Identify columns
all_cols <- colnames(df)
meta_cols <- c("miRNA name", "pos:mut", "position")
total_cols <- grep("\\(PM\\+1MM\\+2MM\\)$", all_cols, value = TRUE)
snv_cols <- setdiff(all_cols, c(meta_cols, total_cols))

cat("📊 Meta columns:", length(meta_cols), "\n")
cat("📊 Total columns:", length(total_cols), "\n")
cat("📊 SNV columns:", length(snv_cols), "\n")

# Take first 3 SNVs for detailed analysis
cat("\n🔍 ANALYZING FIRST 3 SNVs STEP BY STEP:\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

for (i in 1:min(3, nrow(df))) {
  cat("\n📋 SNV", i, ":", df[i, "miRNA name"][[1]], "|", df[i, "pos:mut"][[1]], "\n")
  cat(paste(rep("-", 50), collapse = ""), "\n")
  
  # Get row data
  row_data <- df[i, ]
  
  # Calculate VAFs for this row
  vafs <- numeric(length(snv_cols))
  for (j in seq_along(snv_cols)) {
    snv_count <- row_data[[snv_cols[j]]]
    total_count <- row_data[[total_cols[j]]]
    
    if (total_count > 0) {
      vafs[j] <- snv_count / total_count
    } else {
      vafs[j] <- 0
    }
  }
  
  # Show VAF statistics
  cat("📊 VAF Statistics:\n")
  cat("  - Min VAF:", round(min(vafs), 4), "\n")
  cat("  - Max VAF:", round(max(vafs), 4), "\n")
  cat("  - Mean VAF:", round(mean(vafs), 4), "\n")
  cat("  - Samples with VAF > 0:", sum(vafs > 0), "\n")
  cat("  - Samples with VAF > 0.5:", sum(vafs > 0.5), "\n")
  
  # Check if SNV would pass the filter
  valid_samples <- sum(vafs > 0, na.rm = TRUE)
  cat("  - Valid samples (VAF > 0):", valid_samples, "\n")
  cat("  - Would pass filter (≥2 samples):", valid_samples >= 2, "\n")
  
  # Show some examples of VAFs
  cat("📊 Sample VAFs (first 10):\n")
  for (k in 1:min(10, length(vafs))) {
    cat("  -", snv_cols[k], ":", round(vafs[k], 4), 
        "(", row_data[[snv_cols[k]]], "/", row_data[[total_cols[k]]], ")\n")
  }
  
  # Show overrepresented samples
  overrepresented_idx <- which(vafs > 0.5)
  if (length(overrepresented_idx) > 0) {
    cat("🚨 Overrepresented samples (VAF > 50%):", length(overrepresented_idx), "\n")
    for (idx in overrepresented_idx[1:min(5, length(overrepresented_idx))]) {
      cat("  -", snv_cols[idx], ":", round(vafs[idx], 4), "\n")
    }
  } else {
    cat("✅ No overrepresented samples found\n")
  }
}

cat("\n", paste(rep("=", 60), collapse = ""), "\n")
cat("🔍 SUMMARY OF ALL SNVs:\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# Calculate VAFs for all SNVs
all_vafs <- matrix(0, nrow = nrow(df), ncol = length(snv_cols))
for (i in 1:nrow(df)) {
  for (j in seq_along(snv_cols)) {
    snv_count <- df[i, snv_cols[j]]
    total_count <- df[i, total_cols[j]]
    
    if (total_count > 0) {
      all_vafs[i, j] <- snv_count / total_count
    }
  }
}

# Calculate statistics
valid_samples_per_snv <- rowSums(all_vafs > 0)
overrepresented_samples_per_snv <- rowSums(all_vafs > 0.5)

cat("📊 Overall Statistics:\n")
cat("  - SNVs with ≥2 valid samples:", sum(valid_samples_per_snv >= 2), "\n")
cat("  - SNVs with <2 valid samples:", sum(valid_samples_per_snv < 2), "\n")
cat("  - SNVs with overrepresented samples:", sum(overrepresented_samples_per_snv > 0), "\n")
cat("  - Mean valid samples per SNV:", round(mean(valid_samples_per_snv), 2), "\n")
cat("  - Mean overrepresented samples per SNV:", round(mean(overrepresented_samples_per_snv), 2), "\n")

# Show distribution of valid samples
cat("\n📊 Distribution of valid samples per SNV:\n")
valid_dist <- table(valid_samples_per_snv)
for (i in 1:min(10, length(valid_dist))) {
  cat("  -", names(valid_dist)[i], "samples:", valid_dist[i], "SNVs\n")
}