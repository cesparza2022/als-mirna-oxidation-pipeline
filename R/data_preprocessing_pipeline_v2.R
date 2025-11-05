# =============================================================================
# DATA PREPROCESSING PIPELINE V2 - SNV to SNP Conversion & VAF-based Filter
# =============================================================================
# 
# This script implements the standardized data preprocessing pipeline:
# 1. Split multiple mutations (SNV to SNP conversion)
# 2. Collapse identical mutations
# 3. Apply VAF-based representation filter (handle overrepresented SNVs)
# 4. Generate processed dataset for downstream analysis
#
# Author: Research Team
# Date: 2025-01-27
# Project: miRNAs y oxidación - ALS Analysis
# =============================================================================

# Load required libraries
library(dplyr)
library(tidyr)
library(stringr)
library(readr)

# =============================================================================
# STEP 1: SNV TO SNP CONVERSION FUNCTIONS
# =============================================================================

#' Split multiple mutations into individual SNVs
#' 
#' @param df Data frame with mutation data
#' @param mut_col Column name containing mutations (default: "pos:mut")
#' @return Data frame with separated mutations
split_mutations <- function(df, mut_col = "pos:mut") {
  cat("🔄 Splitting multiple mutations...\n")
  
  # Check if column exists
  if (!mut_col %in% colnames(df)) {
    stop("❌ Column '", mut_col, "' not found in data frame")
  }
  
  # Count rows before splitting
  rows_before <- nrow(df)
  
  # Split mutations separated by commas
  df_split <- df %>%
    separate_rows(.data[[mut_col]], sep = ",") %>%
    mutate(!!mut_col := str_trim(.data[[mut_col]]))
  
  # Count rows after splitting
  rows_after <- nrow(df_split)
  
  cat("✅ Split complete: ", rows_before, " → ", rows_after, " rows\n")
  
  return(df_split)
}

#' Collapse identical mutations after splitting
#' 
#' @param df Data frame with split mutations
#' @param mut_col Column name containing mutations (default: "pos:mut")
#' @param snv_cols Vector of SNV count column names
#' @param total_cols Vector of total count column names
#' @return Data frame with collapsed mutations
collapse_after_split <- function(df, mut_col = "pos:mut", snv_cols, total_cols) {
  cat("🔄 Collapsing identical mutations...\n")
  
  # Count unique mutations before collapsing
  unique_before <- nrow(df)
  
  # Collapse by miRNA name and mutation
  df_collapsed <- df %>%
    group_by(`miRNA name`, !!sym(mut_col)) %>%
    summarise(
      # 1) Sum SNV counts (individual mutation counts)
      across(all_of(snv_cols), ~ sum(.x, na.rm = TRUE)),
      # 2) Take first value of total counts (identical for same miRNA/sample)
      across(all_of(total_cols), ~ first(.x)),
      .groups = "drop"
    )
  
  # Count unique mutations after collapsing
  unique_after <- nrow(df_collapsed)
  
  cat("✅ Collapse complete: ", unique_before, " → ", unique_after, " unique mutations\n")
  
  return(df_collapsed)
}

# =============================================================================
# STEP 2: VAF-BASED REPRESENTATION FILTER
# =============================================================================

#' Apply VAF-based representation filter to SNVs
#' 
#' @param df Data frame with mutation data
#' @param snv_cols Vector of SNV count column names
#' @param total_cols Vector of total count column names
#' @param vaf_threshold VAF threshold for overrepresentation (default: 0.5)
#' @param imputation_method Method for handling overrepresented SNVs ("zero", "nan", "percentile", "median", "mean")
#' @return Data frame with filtered and imputed SNVs
apply_vaf_representation_filter <- function(df, snv_cols, total_cols, vaf_threshold = 0.5, imputation_method = "percentile") {
  cat("🔄 Applying VAF-based representation filter...\n")
  cat("📊 VAF threshold: ", vaf_threshold, " (", vaf_threshold * 100, "%)\n")
  cat("📊 Imputation method: ", imputation_method, "\n")
  
  # Count SNVs before filtering
  snvs_before <- nrow(df)
  
  # Process each row individually for better control
  df_processed <- df
  
  # Apply VAF filtering and imputation row by row
  for (i in 1:nrow(df_processed)) {
    row_data <- df_processed[i, ]
    
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
    
    # Check if this SNV has sufficient data (at least 2 samples with VAF > 0)
    valid_samples <- sum(vafs > 0, na.rm = TRUE)
    
    if (valid_samples >= 2) {
      # Apply imputation to overrepresented samples
      overrepresented_idx <- which(vafs > vaf_threshold)
      
      if (length(overrepresented_idx) > 0) {
        # Calculate imputation value from non-overrepresented samples
        valid_vafs <- vafs[vafs <= vaf_threshold & vafs > 0]
        
        if (length(valid_vafs) > 0) {
          if (imputation_method == "percentile") {
            imputed_vaf <- quantile(valid_vafs, 0.25, na.rm = TRUE)
          } else if (imputation_method == "median") {
            imputed_vaf <- median(valid_vafs, na.rm = TRUE)
          } else if (imputation_method == "mean") {
            imputed_vaf <- mean(valid_vafs, na.rm = TRUE)
          } else if (imputation_method == "zero") {
            imputed_vaf <- 0
          } else if (imputation_method == "nan") {
            imputed_vaf <- NA_real_
          }
          
          # Apply imputation to overrepresented samples
          for (idx in overrepresented_idx) {
            if (imputation_method == "nan") {
              df_processed[i, snv_cols[idx]] <- NA_real_
            } else {
              # Convert VAF back to count
              total_count <- row_data[[total_cols[idx]]]
              df_processed[i, snv_cols[idx]] <- round(imputed_vaf * total_count)
            }
          }
        }
      }
    } else {
      # Remove SNVs with insufficient data
      df_processed[i, ] <- NA
    }
  }
  
  # Remove rows with insufficient data
  df_final <- df_processed[complete.cases(df_processed), ]
  
  # Count SNVs after filtering
  snvs_after <- nrow(df_final)
  retention_rate <- round((snvs_after / snvs_before) * 100, 1)
  
  cat("✅ VAF filter complete: ", snvs_before, " → ", snvs_after, " SNVs (", retention_rate, "% retained)\n")
  
  return(df_final)
}

# =============================================================================
# STEP 3: MAIN PREPROCESSING PIPELINE
# =============================================================================

#' Main data preprocessing pipeline
#' 
#' @param input_file Path to input data file
#' @param output_file Path to output processed data file
#' @param vaf_threshold VAF threshold for overrepresentation filter (default: 0.5)
#' @param imputation_method Method for handling overrepresented SNVs (default: "percentile")
#' @return Processed data frame
run_preprocessing_pipeline <- function(input_file, output_file = NULL, vaf_threshold = 0.5, imputation_method = "percentile") {
  cat("🚀 STARTING DATA PREPROCESSING PIPELINE V2\n")
  cat(paste(rep("=", 50), collapse = ""), "\n")
  
  # Load data
  cat("📁 Loading data from:", input_file, "\n")
  df <- read_tsv(input_file, show_col_types = FALSE)
  cat("✅ Data loaded: ", nrow(df), " rows × ", ncol(df), " columns\n\n")
  
  # Identify column types (for original data structure)
  all_cols <- colnames(df)
  meta_cols <- c("miRNA name", "pos:mut")
  total_cols <- grep("\\(PM\\+1MM\\+2MM\\)$", all_cols, value = TRUE)
  snv_cols <- setdiff(all_cols, c(meta_cols, total_cols))
  
  cat("📊 Column identification:\n")
  cat("   - Meta columns: ", length(meta_cols), "\n")
  cat("   - SNV count columns: ", length(snv_cols), "\n")
  cat("   - Total count columns: ", length(total_cols), "\n")
  cat("   - Total samples: ", length(snv_cols), "\n\n")
  
  # Check if splitting is needed (look for commas in pos:mut)
  has_multiple_mutations <- any(str_detect(df$`pos:mut`, ","))
  
  if (has_multiple_mutations) {
    cat("🔍 Multiple mutations detected - applying SNV to SNP conversion\n")
    
    # Step 1: Split mutations
    df_split <- split_mutations(df, "pos:mut")
    
    # Step 2: Collapse identical mutations
    df_processed <- collapse_after_split(df_split, "pos:mut", snv_cols, total_cols)
    
  } else {
    cat("✅ No multiple mutations detected - skipping SNV to SNP conversion\n")
    df_processed <- df
  }
  
  # Step 3: Apply VAF-based representation filter
  df_final <- apply_vaf_representation_filter(df_processed, snv_cols, total_cols, vaf_threshold, imputation_method)
  
  # Add metadata columns
  df_final <- df_final %>%
    mutate(
      position = as.numeric(str_extract(`pos:mut`, "^[0-9]+")),
      mutation = str_extract(`pos:mut`, "[A-Z]+$")
    )
  
  # Save processed data
  if (!is.null(output_file)) {
    cat("💾 Saving processed data to:", output_file, "\n")
    write_tsv(df_final, output_file)
    cat("✅ Data saved successfully\n")
  }
  
  cat("\n🎉 PREPROCESSING PIPELINE COMPLETE\n")
  cat(paste(rep("=", 50), collapse = ""), "\n")
  cat("📊 Final dataset: ", nrow(df_final), " SNVs × ", ncol(df_final), " columns\n")
  cat("📊 Unique miRNAs: ", length(unique(df_final$`miRNA name`)), "\n")
  cat("📊 Unique mutations: ", length(unique(df_final$`pos:mut`)), "\n")
  
  return(df_final)
}

# =============================================================================
# STEP 4: EXECUTION
# =============================================================================

# Run the pipeline on our current dataset
cat("🔬 PROCESSING CURRENT DATASET\n")
cat(paste(rep("=", 50), collapse = ""), "\n")

# Input and output files
input_file <- "/Users/cesaresparza/New_Desktop/UCSD/8OG/results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt"
output_file <- "outputs/processed_snv_data_vaf_filtered.tsv"

# Execute the pipeline
processed_df <- run_preprocessing_pipeline(
  input_file = input_file,
  output_file = output_file,
  vaf_threshold = 0.5,
  imputation_method = "percentile"
)

# Display summary
cat("\n📋 PROCESSING SUMMARY\n")
cat(paste(rep("=", 30), collapse = ""), "\n")
# Check for multiple mutations in the original input file for summary
original_df_for_summary <- read_tsv(input_file, show_col_types = FALSE)
has_multiple_mutations_summary <- any(str_detect(original_df_for_summary$`pos:mut`, ","))
cat("✅ SNV to SNP conversion: ", ifelse(has_multiple_mutations_summary, "Applied", "Not needed"), "\n")
cat("✅ VAF-based representation filter: Applied (threshold: 0.5, method: percentile)\n")
cat("✅ Output file: ", output_file, "\n")
cat("✅ Ready for downstream analysis\n")










