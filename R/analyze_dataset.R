# Dataset Analysis Script for ALS miRNA Oxidation Research
# This script analyzes the structure and content of the miRNA_count.Q33.txt dataset

# Load required libraries
library(data.table)
library(dplyr)
library(ggplot2)
library(stringr)

# Function to analyze dataset structure
analyze_dataset <- function(file_path) {
  cat("=== Dataset Analysis: miRNA_count.Q33.txt ===\n")
  cat("File path:", file_path, "\n\n")
  
  # Check file size
  file_info <- file.info(file_path)
  cat("File size:", round(file_info$size / (1024^2), 2), "MB\n")
  
  # Read first few rows to understand structure
  cat("\n--- Reading dataset structure ---\n")
  sample_data <- fread(file_path, nrows = 10)
  
  cat("Dataset dimensions (first 10 rows):", nrow(sample_data), "x", ncol(sample_data), "\n")
  cat("Column names (first 10):", paste(names(sample_data)[1:10], collapse = ", "), "\n")
  
  # Analyze sample names
  cat("\n--- Sample Analysis ---\n")
  sample_names <- names(sample_data)[3:ncol(sample_data)]  # Skip miRNA name and pos:mut columns
  
  # Count samples by group
  als_samples <- sum(str_detect(sample_names, "ALS"))
  control_samples <- sum(str_detect(sample_names, "control"))
  longitudinal_samples <- sum(str_detect(sample_names, "longitudinal"))
  
  cat("Total samples:", length(sample_names), "\n")
  cat("ALS samples:", als_samples, "\n")
  cat("Control samples:", control_samples, "\n")
  cat("Longitudinal samples:", longitudinal_samples, "\n")
  
  # Analyze mutation types
  cat("\n--- Mutation Type Analysis ---\n")
  mutation_col <- sample_data$`pos:mut`
  unique_mutations <- unique(mutation_col)
  cat("Unique mutation types:", length(unique_mutations), "\n")
  cat("Mutation types:", paste(unique_mutations, collapse = ", "), "\n")
  
  # Analyze miRNA names
  cat("\n--- miRNA Analysis ---\n")
  unique_mirnas <- unique(sample_data$`miRNA name`)
  cat("Unique miRNAs (first 10 rows):", length(unique_mirnas), "\n")
  cat("miRNA names:", paste(unique_mirnas, collapse = ", "), "\n")
  
  # Check data types and ranges
  cat("\n--- Data Type Analysis ---\n")
  numeric_cols <- names(sample_data)[3:ncol(sample_data)]
  sample_values <- sample_data[, ..numeric_cols]
  
  # Convert to numeric and check ranges
  sample_values_numeric <- sample_values[, lapply(.SD, as.numeric)]
  
  cat("Data range (first 10 samples):\n")
  for(i in 1:min(5, ncol(sample_values_numeric))) {
    col_name <- names(sample_values_numeric)[i]
    col_data <- sample_values_numeric[[i]]
    cat(sprintf("  %s: min=%.1f, max=%.1f, mean=%.2f\n", 
                col_name, min(col_data, na.rm=TRUE), max(col_data, na.rm=TRUE), mean(col_data, na.rm=TRUE)))
  }
  
  # Check for missing values
  cat("\n--- Missing Value Analysis ---\n")
  missing_count <- sum(is.na(sample_values_numeric))
  total_values <- nrow(sample_values_numeric) * ncol(sample_values_numeric)
  cat("Missing values:", missing_count, "out of", total_values, "(", round(100*missing_count/total_values, 2), "%)\n")
  
  # Analyze zero values
  zero_count <- sum(sample_values_numeric == 0, na.rm=TRUE)
  cat("Zero values:", zero_count, "out of", total_values, "(", round(100*zero_count/total_values, 2), "%)\n")
  
  return(list(
    file_size_mb = round(file_info$size / (1024^2), 2),
    total_samples = length(sample_names),
    als_samples = als_samples,
    control_samples = control_samples,
    longitudinal_samples = longitudinal_samples,
    unique_mutations = length(unique_mutations),
    unique_mirnas = length(unique_mirnas),
    missing_pct = round(100*missing_count/total_values, 2),
    zero_pct = round(100*zero_count/total_values, 2)
  ))
}

# Function to create sample metadata from column names
create_sample_metadata <- function(file_path) {
  cat("\n--- Creating Sample Metadata ---\n")
  
  # Read just the header
  header <- fread(file_path, nrows = 0)
  sample_names <- names(header)[3:length(names(header))]  # Skip miRNA name and pos:mut
  
  # Parse sample information
  sample_metadata <- data.table(
    sample_id = sample_names,
    group = ifelse(str_detect(sample_names, "control"), "Control", 
                   ifelse(str_detect(sample_names, "ALS"), "ALS", "Unknown")),
    timepoint = ifelse(str_detect(sample_names, "longitudinal"), 
                       str_extract(sample_names, "longitudinal_[0-9]+"), "enrolment"),
    tissue = "bloodplasma",
    srr_id = str_extract(sample_names, "SRR[0-9]+")
  )
  
  # Add batch information
  sample_metadata[, batch := str_extract(sample_names, "batch_[0-9]+")]
  sample_metadata[is.na(batch), batch := "unknown"]
  
  # Count samples by group
  group_counts <- sample_metadata[, .N, by = group]
  cat("Sample distribution:\n")
  print(group_counts)
  
  return(sample_metadata)
}

# Main analysis
if (interactive()) {
  # Run analysis
  dataset_info <- analyze_dataset("results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt")
  
  # Create sample metadata
  sample_metadata <- create_sample_metadata("results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt")
  
  # Save sample metadata
  fwrite(sample_metadata, "sample_metadata.tsv", sep = "\t")
  cat("\nSample metadata saved to: sample_metadata.tsv\n")
  
  # Print summary
  cat("\n=== DATASET SUMMARY ===\n")
  cat("File size:", dataset_info$file_size_mb, "MB\n")
  cat("Total samples:", dataset_info$total_samples, "\n")
  cat("  - ALS samples:", dataset_info$als_samples, "\n")
  cat("  - Control samples:", dataset_info$control_samples, "\n")
  cat("  - Longitudinal samples:", dataset_info$longitudinal_samples, "\n")
  cat("Unique mutations:", dataset_info$unique_mutations, "\n")
  cat("Unique miRNAs:", dataset_info$unique_mirnas, "\n")
  cat("Missing data:", dataset_info$missing_pct, "%\n")
  cat("Zero values:", dataset_info$zero_pct, "%\n")
}











