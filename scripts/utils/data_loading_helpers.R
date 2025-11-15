#!/usr/bin/env Rscript
# ============================================================================
# DATA LOADING HELPERS
# ============================================================================
# Utility functions to correctly separate count columns, total columns, and VAF columns
# from processed miRNA data files.
#
# These functions ensure that downstream analyses use the correct data type:
# - SNV counts: Individual mutation counts (e.g., "Magen_ALS_001")
# - Total counts: Combined counts (e.g., "Magen_ALS_001 (PM+1MM+2MM)")
# - VAF columns: Pre-calculated VAF (e.g., "VAF_Magen_ALS_001")
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(readr)
})

# ============================================================================
# CONSTANTS
# ============================================================================

# Default metadata column names (various formats supported)
DEFAULT_METADATA_COLS <- c("miRNA_name", "miRNA name", "miRNA.name", "miRNA",
                          "pos.mut", "pos:mut", "pos_mut")

# Regex patterns for column identification
PATTERN_TOTAL_COLUMNS <- "\\(PM\\+1MM\\+2MM\\)$"  # Total count columns suffix
PATTERN_VAF_COLUMNS <- "^VAF_"                     # VAF columns prefix

#' Identify SNV count columns (excluding total count columns)
#' 
#' @param data Data frame with miRNA data
#' @param metadata_cols Optional vector of metadata column names to exclude
#' @return Character vector of SNV count column names
identify_snv_count_columns <- function(data, metadata_cols = NULL) {
  # Use default metadata columns or merge with provided
  if (is.null(metadata_cols)) {
    metadata_cols <- DEFAULT_METADATA_COLS
  } else {
    metadata_cols <- unique(c(metadata_cols, DEFAULT_METADATA_COLS))
  }
  
  # Get all sample columns (exclude metadata)
  all_sample_cols <- setdiff(names(data), metadata_cols)
  
  # Identify total count columns (contain "(PM+1MM+2MM)" suffix)
  total_cols <- all_sample_cols[grepl(PATTERN_TOTAL_COLUMNS, all_sample_cols)]
  
  # SNV count columns are everything else (not metadata, not totals, not VAF)
  vaf_cols <- all_sample_cols[grepl(PATTERN_VAF_COLUMNS, all_sample_cols)]
  
  snv_cols <- setdiff(all_sample_cols, c(total_cols, vaf_cols))
  
  return(snv_cols)
}

#' Identify total count columns
#' 
#' @param data Data frame with miRNA data
#' @param metadata_cols Optional vector of metadata column names to exclude
#' @return Character vector of total count column names
identify_total_count_columns <- function(data, metadata_cols = NULL) {
  # Use default metadata columns or merge with provided
  if (is.null(metadata_cols)) {
    metadata_cols <- DEFAULT_METADATA_COLS
  } else {
    metadata_cols <- unique(c(metadata_cols, DEFAULT_METADATA_COLS))
  }
  
  # Get all sample columns (exclude metadata)
  all_sample_cols <- setdiff(names(data), metadata_cols)
  
  # Identify total count columns (contain "(PM+1MM+2MM)" suffix)
  total_cols <- all_sample_cols[grepl(PATTERN_TOTAL_COLUMNS, all_sample_cols)]
  
  return(total_cols)
}

#' Identify VAF columns
#' 
#' @param data Data frame with miRNA data
#' @param metadata_cols Optional vector of metadata column names to exclude
#' @return Character vector of VAF column names
identify_vaf_columns <- function(data, metadata_cols = NULL) {
  # Use default metadata columns or merge with provided
  if (is.null(metadata_cols)) {
    metadata_cols <- DEFAULT_METADATA_COLS
  } else {
    metadata_cols <- unique(c(metadata_cols, DEFAULT_METADATA_COLS))
  }
  
  # Get all sample columns (exclude metadata)
  all_sample_cols <- setdiff(names(data), metadata_cols)
  
  # Identify VAF columns (start with "VAF_")
  vaf_cols <- all_sample_cols[grepl(PATTERN_VAF_COLUMNS, all_sample_cols)]
  
  return(vaf_cols)
}

#' Load data and return only SNV count columns
#' 
#' @param file_path Path to CSV/TSV file
#' @param metadata_cols Optional vector of metadata column names
#' @return Data frame with only metadata and SNV count columns
load_snv_counts_only <- function(file_path, metadata_cols = NULL) {
  # Validate file exists
  if (!file.exists(file_path)) {
    stop(paste("❌ File not found:", file_path))
  }
  
  # Detect file format
  file_ext <- tolower(tools::file_ext(file_path))
  
  if (file_ext == "txt" || file_ext == "tsv") {
    data <- readr::read_delim(file_path, delim = "\t", show_col_types = FALSE)
  } else {
    data <- readr::read_csv(file_path, show_col_types = FALSE)
  }
  
  # Normalize column names
  if ("miRNA name" %in% names(data)) {
    data <- data %>% dplyr::rename(miRNA_name = `miRNA name`)
  }
  if ("pos:mut" %in% names(data)) {
    data <- data %>% dplyr::rename(pos.mut = `pos:mut`)
  }
  
  # Validate that data is not empty
  if (nrow(data) == 0) {
    stop(paste("❌ File is empty:", file_path))
  }
  if (ncol(data) == 0) {
    stop(paste("❌ File has no columns:", file_path))
  }
  
  # Get SNV columns only
  snv_cols <- identify_snv_count_columns(data, metadata_cols)
  
  # Validate that SNV columns were found
  if (length(snv_cols) == 0) {
    warning(paste("⚠️  No SNV count columns found in:", file_path))
  }
  
  # Default metadata columns
  default_metadata <- c("miRNA_name", "pos.mut")
  metadata_cols_final <- intersect(default_metadata, names(data))
  if (!is.null(metadata_cols)) {
    metadata_cols_final <- unique(c(metadata_cols_final, metadata_cols))
  }
  metadata_cols_final <- intersect(metadata_cols_final, names(data))
  
  # Return only metadata + SNV columns
  result <- data %>% dplyr::select(dplyr::all_of(c(metadata_cols_final, snv_cols)))
  
  # Validate result is not empty
  if (nrow(result) == 0) {
    warning(paste("⚠️  Resulting data frame is empty after filtering:", file_path))
  }
  
  return(result)
}

#' Load data and return only VAF columns (if available)
#' 
#' @param file_path Path to CSV/TSV file
#' @param metadata_cols Optional vector of metadata column names
#' @return Data frame with only metadata and VAF columns, or NULL if no VAF columns
load_vaf_only <- function(file_path, metadata_cols = NULL) {
  # Validate file exists
  if (!file.exists(file_path)) {
    stop(paste("❌ File not found:", file_path))
  }
  
  # Detect file format
  file_ext <- tolower(tools::file_ext(file_path))
  
  if (file_ext == "txt" || file_ext == "tsv") {
    data <- readr::read_delim(file_path, delim = "\t", show_col_types = FALSE)
  } else {
    data <- readr::read_csv(file_path, show_col_types = FALSE)
  }
  
  # Normalize column names
  if ("miRNA name" %in% names(data)) {
    data <- data %>% dplyr::rename(miRNA_name = `miRNA name`)
  }
  if ("pos:mut" %in% names(data)) {
    data <- data %>% dplyr::rename(pos.mut = `pos:mut`)
  }
  
  # Validate that data is not empty
  if (nrow(data) == 0) {
    stop(paste("❌ File is empty:", file_path))
  }
  if (ncol(data) == 0) {
    stop(paste("❌ File has no columns:", file_path))
  }
  
  # Get VAF columns
  vaf_cols <- identify_vaf_columns(data, metadata_cols)
  
  if (length(vaf_cols) == 0) {
    return(NULL)
  }
  
  # Default metadata columns
  default_metadata <- c("miRNA_name", "pos.mut")
  metadata_cols_final <- intersect(default_metadata, names(data))
  if (!is.null(metadata_cols)) {
    metadata_cols_final <- unique(c(metadata_cols_final, metadata_cols))
  }
  metadata_cols_final <- intersect(metadata_cols_final, names(data))
  
  # Return only metadata + VAF columns
  result <- data %>% dplyr::select(dplyr::all_of(c(metadata_cols_final, vaf_cols)))
  
  # Validate result is not empty
  if (nrow(result) == 0) {
    warning(paste("⚠️  Resulting data frame is empty after filtering:", file_path))
  }
  
  return(result)
}

#' Get column summary for debugging
#' 
#' @param data Data frame with miRNA data
#' @return List with counts of each column type
get_column_summary <- function(data) {
  snv_cols <- identify_snv_count_columns(data)
  total_cols <- identify_total_count_columns(data)
  vaf_cols <- identify_vaf_columns(data)
  
  metadata_cols <- intersect(DEFAULT_METADATA_COLS, names(data))
  
  return(list(
    metadata = length(metadata_cols),
    snv_counts = length(snv_cols),
    total_counts = length(total_cols),
    vaf = length(vaf_cols),
    total_columns = ncol(data),
    snv_cols = snv_cols,
    total_cols = total_cols,
    vaf_cols = vaf_cols
  ))
}

