# Normalization Functions for ALS miRNA Oxidation Research
# This module contains functions for data normalization and filtering

#' Calculate total counts per sample
#'
#' Sums all counts for each sample and appends a "totals" row.
#' This provides denominators for RPM (Reads Per Million) calculations.
#'
#' @param count_df Data frame with miRNA counts (from Annotate_total_counts)
#' @return Data frame with totals row appended
#' @examples
#' \dontrun{
#' df_tot <- Calculate_total_per_sample(df_pm)
#' }
#' @export
Calculate_total_per_sample <- function(count_df) {
  stopifnot(is.data.frame(count_df))
  stopifnot("miRNA" %in% names(count_df))
  
  totals <- count_df %>%
    select(-miRNA) %>%
    summarise(across(everything(), ~ sum(.x, na.rm = TRUE))) %>%
    mutate(miRNA = "totals") %>%
    select(miRNA, everything())
  
  bind_rows(count_df, totals)
}

#' Calculate RPM (Reads Per Million) normalization
#'
#' Normalizes counts to reads per million using the totals row as denominator.
#' This standardizes expression levels across samples with different sequencing depths.
#'
#' @param count_df Data frame with counts and totals row (from Calculate_total_per_sample)
#' @param miRNA_col Name of the miRNA column (default: "miRNA")
#' @param factor Scaling factor for normalization (default: 1e6 for RPM)
#' @return Data frame with RPM-normalized counts
#' @examples
#' \dontrun{
#' rpm_df <- Calculate_RPM(df_tot, miRNA_col = "miRNA", factor = 1e6)
#' }
#' @export
Calculate_RPM <- function(count_df,
                          miRNA_col = "miRNA",
                          factor = 1e6) {
  stopifnot(is.data.frame(count_df))
  stopifnot(miRNA_col %in% names(count_df))
  stopifnot(is.numeric(factor))
  stopifnot(factor > 0)
  
  # Extract denominators from totals row
  denom <- count_df %>%
    filter(.data[[miRNA_col]] == "totals") %>%
    select(-all_of(miRNA_col)) %>%
    unlist(use.names = TRUE)
  
  # Check for zero denominators
  if (any(denom == 0)) {
    warning("Some samples have zero total counts. These will result in NaN values.")
  }
  
  # Drop totals row and normalize
  count_df %>%
    filter(.data[[miRNA_col]] != "totals") %>%
    mutate(across(-all_of(miRNA_col),
                  ~ .x / denom[cur_column()] * factor))
}

#' Apply threshold and select miRNAs
#'
#' Converts RPM data to binary (0/1) based on threshold and selects miRNAs
#' that meet minimum presence criteria across samples.
#'
#' @param rpm_df Data frame with RPM-normalized counts
#' @param threshold RPM threshold for binary conversion (default: 1)
#' @param min_fraction Minimum fraction of samples that must meet threshold (default: 0.10)
#' @param miRNA_col Name of the miRNA column (default: "miRNA")
#' @return List containing binary matrix and selected miRNA names
#' @examples
#' \dontrun{
#' result <- Threshold_binary_and_select(rpm_df, threshold = 10, min_fraction = 0.5)
#' }
#' @export
Threshold_binary_and_select <- function(rpm_df,
                                       threshold = 1,
                                       min_fraction = 0.10,
                                       miRNA_col = "miRNA") {
  stopifnot(is.data.frame(rpm_df))
  stopifnot(miRNA_col %in% names(rpm_df))
  stopifnot(is.numeric(threshold))
  stopifnot(is.numeric(min_fraction))
  stopifnot(min_fraction >= 0 && min_fraction <= 1)
  
  samp_cols <- setdiff(names(rpm_df), miRNA_col)
  
  # Create binary matrix
  binary <- rpm_df %>%
    mutate(across(all_of(samp_cols),
                  ~ as.integer(.x >= threshold)))
  
  # Count samples meeting threshold per miRNA
  n_samps <- length(samp_cols)
  min_samps <- ceiling(n_samps * min_fraction)
  
  keep <- binary %>%
    mutate(n_ones = rowSums(select(., all_of(samp_cols)))) %>%
    filter(n_ones >= min_samps) %>%
    pull(all_of(miRNA_col))
  
  list(
    binary_matrix   = binary %>% select(miRNA, all_of(samp_cols)),
    selected_miRNAs = keep
  )
}

#' Calculate frequency percentages
#'
#' Calculates mutation frequency as percentage of total counts for each sample.
#' Useful for comparing mutation rates across samples and groups.
#'
#' @param snv_df Data frame with SNV counts
#' @param total_counts Named vector of total counts per sample
#' @param snv_cols Vector of SNV column names
#' @return Data frame with frequency percentages
#' @examples
#' \dontrun{
#' df_freq <- calculate_frequency_percentages(df_snv, total_counts, snv_cols)
#' }
#' @export
calculate_frequency_percentages <- function(snv_df, total_counts, snv_cols) {
  stopifnot(is.data.frame(snv_df))
  stopifnot(is.numeric(total_counts))
  stopifnot(all(snv_cols %in% names(snv_df)))
  stopifnot(all(names(total_counts) %in% snv_cols))
  
  # Calculate frequency matrix
  counts_mat <- snv_df %>% select(all_of(snv_cols)) %>% as.matrix()
  freq_mat   <- sweep(counts_mat, 2, total_counts, "/") * 100
  
  # Combine with metadata
  bind_cols(
    snv_df %>% select(miRNA, mut),
    as.data.frame(freq_mat)
  )
}

#' Filter data by selected miRNAs
#'
#' Filters the main data frame to include only selected miRNAs.
#' Typically used after applying quality control and filtering criteria.
#'
#' @param df Main data frame to filter
#' @param selected_miRNAs Vector of miRNA names to keep
#' @param miRNA_col Name of the miRNA column (default: "miRNA name")
#' @return Filtered data frame
#' @examples
#' \dontrun{
#' df_filtered <- filter_by_miRNAs(df, selected_miRNAs, miRNA_col = "miRNA name")
#' }
#' @export
filter_by_miRNAs <- function(df, selected_miRNAs, miRNA_col = "miRNA name") {
  stopifnot(is.data.frame(df))
  stopifnot(miRNA_col %in% names(df))
  stopifnot(is.character(selected_miRNAs))
  
  df %>%
    filter(.data[[miRNA_col]] %in% selected_miRNAs)
}

#' Apply comprehensive filtering pipeline
#'
#' Applies the complete filtering pipeline: RPM normalization, thresholding,
#' and miRNA selection. This is a convenience function that combines multiple
#' filtering steps.
#'
#' @param df Main data frame
#' @param total_cols Vector of total count column names
#' @param snv_cols Vector of SNV count column names
#' @param rpm_threshold RPM threshold for filtering (default: 10)
#' @param min_fraction Minimum fraction of samples (default: 0.5)
#' @param miRNA_col Name of the miRNA column (default: "miRNA name")
#' @return List containing filtered data and filtering results
#' @examples
#' \dontrun{
#' result <- apply_filtering_pipeline(df, total_cols, snv_cols, 
#'                                   rpm_threshold = 10, min_fraction = 0.5)
#' }
#' @export
apply_filtering_pipeline <- function(df, total_cols, snv_cols,
                                    rpm_threshold = 10,
                                    min_fraction = 0.5,
                                    miRNA_col = "miRNA name") {
  stopifnot(is.data.frame(df))
  stopifnot(is.character(total_cols))
  stopifnot(is.character(snv_cols))
  stopifnot(is.numeric(rpm_threshold))
  stopifnot(is.numeric(min_fraction))
  
  # Step 1: Calculate total counts and RPM
  df_tot_counts <- Annotate_total_counts(df, cols = total_cols) %>%
    Calculate_total_per_sample()
  
  rpm_df <- Calculate_RPM(df_tot_counts, miRNA_col = "miRNA", factor = 1e6)
  
  # Step 2: Apply threshold and select miRNAs
  thres_out <- Threshold_binary_and_select(
    rpm_df,
    threshold = rpm_threshold,
    min_fraction = min_fraction,
    miRNA_col = "miRNA"
  )
  
  # Step 3: Filter original data
  df_filtered <- filter_by_miRNAs(df, thres_out$selected_miRNAs, miRNA_col)
  
  list(
    filtered_df = df_filtered,
    selected_miRNAs = thres_out$selected_miRNAs,
    binary_matrix = thres_out$binary_matrix,
    rpm_df = rpm_df,
    n_selected = length(thres_out$selected_miRNAs)
  )
}

