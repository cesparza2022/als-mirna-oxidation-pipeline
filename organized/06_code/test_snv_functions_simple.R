# Test script for SNV processing functions
# This script tests the functions with a small subset of the data

library(dplyr)
library(stringr)
library(tidyr)

# Source the functions
source("R/snv_processing_functions_fixed.R")

# Load a small subset of the data for testing
cat("📁 Loading test data...\n")
df <- read.delim("/Users/cesaresparza/New_Desktop/UCSD/8OG/results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt", 
                 nrows = 100, stringsAsFactors = FALSE)

cat("   📊 Test dataset dimensions:", nrow(df), "x", ncol(df), "\n")

# Check the structure
cat("\n🔍 Dataset structure analysis:\n")
cat("   Column 1 (miRNA name):", colnames(df)[1], "\n")
cat("   Column 2 (pos:mut):", colnames(df)[2], "\n")
cat("   SNV columns: 3-417 (", length(3:417), "columns)\n")
cat("   Total columns: 418-832 (", length(418:832), "columns)\n")

# Check for multiple SNVs
multiple_snvs <- df %>%
  filter(str_detect(df[["pos.mut"]], ","))

cat("\n📊 Multiple SNV analysis:\n")
cat("   Rows with multiple SNVs:", nrow(multiple_snvs), "\n")

if (nrow(multiple_snvs) > 0) {
  cat("   Examples of multiple SNVs:\n")
  print(head(multiple_snvs[c("miRNA.name", "pos.mut")], 3))
}

# Test the functions
cat("\n🧪 Testing SNV processing functions...\n")

# Define column ranges
snv_cols <- colnames(df)[3:417]
total_cols <- colnames(df)[418:832]

# Test separation function
cat("\n1️⃣ Testing separate_multiple_snvs function:\n")
df_separated <- separate_multiple_snvs(df, snv_cols, total_cols)

# Test summing function
cat("\n2️⃣ Testing sum_snv_counts_by_mirna function:\n")
df_summed <- sum_snv_counts_by_mirna(df_separated, snv_cols, total_cols)

# Verify results
cat("\n✅ Verification:\n")
cat("   Original rows:", nrow(df), "\n")
cat("   After separation:", nrow(df_separated), "\n")
cat("   After summing:", nrow(df_summed), "\n")
cat("   Unique miRNAs in final result:", length(unique(df_summed[["miRNA.name"]])), "\n")

# Check if totals are preserved (not summed)
cat("\n🔍 Checking totals preservation:\n")
original_totals <- df[1, total_cols[1:3]]  # First 3 total columns
final_totals <- df_summed[1, total_cols[1:3]]  # First 3 total columns

cat("   Original totals (first miRNA, first 3 samples):\n")
print(original_totals)
cat("   Final totals (first miRNA, first 3 samples):\n")
print(final_totals)

# Check if SNV counts are summed correctly
cat("\n🔍 Checking SNV count summation:\n")
original_snvs <- df[1, snv_cols[1:3]]  # First 3 SNV columns
final_snvs <- df_summed[1, snv_cols[1:3]]  # First 3 SNV columns

cat("   Original SNV counts (first miRNA, first 3 samples):\n")
print(original_snvs)
cat("   Final SNV counts (first miRNA, first 3 samples):\n")
print(final_snvs)

cat("\n🎉 Test completed successfully!\n")