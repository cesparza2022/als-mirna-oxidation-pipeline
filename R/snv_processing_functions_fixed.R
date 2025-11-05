# SNV Processing Functions for miRNA Dataset
# Functions to handle multiple SNVs in pos:mut column and sum counts by miRNA

library(dplyr)
library(stringr)
library(tidyr)

#' Separate multiple SNVs in pos:mut column into individual rows
#' 
#' @param df Data frame with miRNA data
#' @param snv_cols Vector of SNV count column names
#' @param total_cols Vector of total count column names
#' @return Data frame with separated SNVs
separate_multiple_snvs <- function(df, snv_cols, total_cols) {
  cat("🔧 Separating multiple SNVs...\n")
  
  # Filter only rows with SNVs (not PM)
  df_snvs <- df %>%
    filter(df[["pos.mut"]] != "PM")
  
  # Identify rows with multiple SNVs (contain comma)
  multiple_snv_rows <- df_snvs %>%
    filter(str_detect(df_snvs[["pos.mut"]], ","))
  
  cat("   📊 Rows with multiple SNVs found:", nrow(multiple_snv_rows), "\n")
  
  if (nrow(multiple_snv_rows) == 0) {
    cat("   ✅ No multiple SNVs to separate\n")
    return(df_snvs)
  }
  
  # Separate multiple SNVs
  separated_rows <- multiple_snv_rows %>%
    separate_rows(!!sym("pos.mut"), sep = ",") %>%
    mutate(!!sym("pos.mut") := str_trim(!!sym("pos.mut")))  # Clean spaces
  
  # Rows with single SNVs (no comma)
  single_snv_rows <- df_snvs %>%
    filter(!str_detect(df_snvs[["pos.mut"]], ","))
  
  # Combine single and separated rows
  result <- bind_rows(single_snv_rows, separated_rows) %>%
    arrange(!!sym("miRNA.name"), !!sym("pos.mut"))
  
  cat("   ✅ SNVs separated successfully\n")
  cat("   📊 Total rows after separation:", nrow(result), "\n")
  
  return(result)
}

#' Sum SNV counts by miRNA and sample (without summing totals)
#' 
#' @param df Data frame with separated SNVs
#' @param snv_cols Vector of SNV count column names
#' @param total_cols Vector of total count column names
#' @return Data frame with summed SNV counts per miRNA
sum_snv_counts_by_mirna <- function(df, snv_cols, total_cols) {
  cat("🔧 Summing SNV counts by miRNA and sample...\n")
  
  # Group by miRNA and sum only SNV columns
  result <- df %>%
    group_by(!!sym("miRNA.name")) %>%
    summarise(
      # Sum SNV columns
      across(all_of(snv_cols), ~ sum(.x, na.rm = TRUE)),
      # Take first value of totals (don't sum)
      across(all_of(total_cols), ~ first(.x)),
      .groups = "drop"
    )
  
  cat("   ✅ Counts summed successfully\n")
  cat("   📊 Unique miRNAs:", nrow(result), "\n")
  
  return(result)
}

#' Process miRNA dataset: separate SNVs and sum counts
#' 
#' @param df Original data frame
#' @return Processed data frame
process_mirna_snvs <- function(df) {
  cat("🚀 Starting miRNA SNV processing...\n")
  
  # Define column ranges based on dataset structure
  snv_cols <- colnames(df)[3:417]  # SNV counts
  total_cols <- colnames(df)[418:832]  # Total counts
  
  cat("   📊 SNV columns:", length(snv_cols), "\n")
  cat("   📊 Total columns:", length(total_cols), "\n")
  
  # Step 1: Separate multiple SNVs
  df_separated <- separate_multiple_snvs(df, snv_cols, total_cols)
  
  # Step 2: Sum SNV counts by miRNA
  df_summed <- sum_snv_counts_by_mirna(df_separated, snv_cols, total_cols)
  
  cat("✅ Processing completed successfully!\n")
  
  return(df_summed)
}