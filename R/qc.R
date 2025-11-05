# Quality Control Functions for ALS miRNA Oxidation Research
# This module contains functions for data annotation and quality control

#' Annotate total counts from data frame
#'
#' Extracts total count data (PM rows) from the main data frame.
#' Filters for perfect match (PM) rows and selects specified columns.
#'
#' @param df Main data frame containing miRNA data
#' @param cols Vector of column names containing total counts (default: total_cols)
#' @param miRNA_col Name of the miRNA column (default: "miRNA name")
#' @param mut_col Name of the mutation column (default: "pos:mut")
#' @return Data frame with total counts for each miRNA
#' @examples
#' \dontrun{
#' df_pm <- Annotate_total_counts(df, cols = total_cols)
#' }
#' @export
Annotate_total_counts <- function(df, 
                                  cols = total_cols,
                                  miRNA_col = "miRNA name",
                                  mut_col = "pos:mut") {
  stopifnot(is.data.frame(df))
  stopifnot(miRNA_col %in% names(df))
  stopifnot(mut_col %in% names(df))
  stopifnot(all(cols %in% names(df)))
  
  df %>%
    filter(.data[[mut_col]] == "PM") %>%
    select(all_of(c(miRNA_col, cols))) %>%
    rename(miRNA = !!rlang::sym(miRNA_col))
}

#' Annotate SNV counts from data frame
#'
#' Extracts SNV count data (PM rows) from the main data frame.
#' Similar to Annotate_total_counts but for SNV-specific columns.
#'
#' @param df Main data frame containing miRNA data
#' @param cols Vector of column names containing SNV counts (default: snv_cols)
#' @param miRNA_col Name of the miRNA column (default: "miRNA name")
#' @param mut_col Name of the mutation column (default: "pos:mut")
#' @return Data frame with SNV counts for each miRNA
#' @examples
#' \dontrun{
#' df_snv <- Annotate_SNV_counts(df, cols = snv_cols)
#' }
#' @export
Annotate_SNV_counts <- function(df,
                                cols = snv_cols,
                                miRNA_col = "miRNA name",
                                mut_col = "pos:mut") {
  stopifnot(is.data.frame(df))
  stopifnot(miRNA_col %in% names(df))
  stopifnot(mut_col %in% names(df))
  stopifnot(all(cols %in% names(df)))
  
  df %>%
    filter(.data[[mut_col]] == "PM") %>%
    select(miRNA = .data[[miRNA_col]], all_of(cols))
}

#' Annotate SNV presence from data frame
#'
#' Extracts SNV presence data (non-PM rows) from the main data frame.
#' This includes all mutation variants and their counts across samples.
#'
#' @param df Main data frame containing miRNA data
#' @param cols Vector of column names containing SNV counts (default: snv_cols)
#' @param miRNA_col Name of the miRNA column (default: "miRNA name")
#' @param mut_col Name of the mutation column (default: "pos:mut")
#' @return Data frame with SNV presence data
#' @examples
#' \dontrun{
#' df_presence <- Annotate_SNV_presence(df, cols = snv_cols)
#' }
#' @export
Annotate_SNV_presence <- function(df,
                                  cols = snv_cols,
                                  miRNA_col = "miRNA name",
                                  mut_col = "pos:mut") {
  stopifnot(is.data.frame(df))
  stopifnot(miRNA_col %in% names(df))
  stopifnot(mut_col %in% names(df))
  stopifnot(all(cols %in% names(df)))
  
  df %>%
    filter(.data[[mut_col]] != "PM") %>%
    select(miRNA = .data[[miRNA_col]], mut = .data[[mut_col]], all_of(cols))
}

#' Calculate sample group presence counts
#'
#' Counts how many samples in each group contain each SNV.
#' Useful for understanding SNV prevalence across experimental conditions.
#'
#' @param df_presence Data frame from Annotate_SNV_presence()
#' @param sample_groups List of sample groups from identify_sample_groups()
#' @return Data frame with presence counts by group
#' @examples
#' \dontrun{
#' groups <- identify_sample_groups(snv_cols)
#' df_counts <- calculate_group_presence(df_presence, groups)
#' }
#' @export
calculate_group_presence <- function(df_presence, sample_groups) {
  stopifnot(is.data.frame(df_presence))
  stopifnot(is.list(sample_groups))
  stopifnot(all(c("ALS_longitudinal", "ALS_enrolment", "control") %in% names(sample_groups)))
  
  df_presence %>%
    mutate(
      n_long  = rowSums(select(., matches("ALS[-_]longitudinal")) > 0),
      n_enrol = rowSums(select(., matches("ALS[-_]enrolment"))    > 0),
      n_ctrl  = rowSums(select(., matches("-control-"))          > 0)
    ) %>%
    mutate(
      has_long  = n_long  > 0,
      has_enrol = n_enrol > 0,
      has_ctrl  = n_ctrl  > 0,
      id        = paste(miRNA, mut, sep = "_")
    )
}

#' Calculate sample statistics by group
#'
#' Computes summary statistics (mean, median, SD) for total counts by sample group.
#' Useful for quality control and understanding data distribution.
#'
#' @param df_long Long-format data frame with sample and count information
#' @param group_col Name of the group column (default: "group")
#' @param count_col Name of the count column (default: "total_counts")
#' @return Data frame with summary statistics by group
#' @examples
#' \dontrun{
#' stats <- calculate_group_stats(df_long, group_col = "group", count_col = "total_counts")
#' }
#' @export
calculate_group_stats <- function(df_long, group_col = "group", count_col = "total_counts") {
  stopifnot(is.data.frame(df_long))
  stopifnot(group_col %in% names(df_long))
  stopifnot(count_col %in% names(df_long))
  
  df_long %>%
    group_by(.data[[group_col]]) %>%
    summarise(
      n            = n(),
      mean_total   = mean(.data[[count_col]]),
      median_total = median(.data[[count_col]]),
      sd_total     = sd(.data[[count_col]]),
      .groups = "drop"
    )
}

#' Validate data integrity
#'
#' Performs basic validation checks on the loaded data to ensure quality.
#' Checks for missing values, data types, and expected structure.
#'
#' @param df Main data frame to validate
#' @param required_cols Vector of required column names
#' @param expected_groups Vector of expected group names
#' @return List with validation results and any issues found
#' @examples
#' \dontrun{
#' validation <- validate_data_integrity(df, required_cols = c("miRNA name", "pos:mut"))
#' }
#' @export
validate_data_integrity <- function(df, required_cols, expected_groups = NULL) {
  stopifnot(is.data.frame(df))
  stopifnot(is.character(required_cols))
  
  issues <- list()
  
  # Check required columns
  missing_cols <- setdiff(required_cols, names(df))
  if (length(missing_cols) > 0) {
    issues$missing_columns <- missing_cols
  }
  
  # Check for missing values in key columns
  key_cols <- intersect(required_cols, names(df))
  for (col in key_cols) {
    na_count <- sum(is.na(df[[col]]))
    if (na_count > 0) {
      issues[[paste0("na_in_", col)]] <- na_count
    }
  }
  
  # Check data types
  if ("miRNA name" %in% names(df)) {
    if (!is.character(df[["miRNA name"]])) {
      issues$miRNA_name_type <- "Expected character, got different type"
    }
  }
  
  # Check for empty data frame
  if (nrow(df) == 0) {
    issues$empty_dataframe <- "Data frame has no rows"
  }
  
  return(list(
    is_valid = length(issues) == 0,
    issues = issues,
    n_rows = nrow(df),
    n_cols = ncol(df)
  ))
}











