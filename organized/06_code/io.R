# Data I/O Functions for ALS miRNA Oxidation Research
# This module contains functions for reading, parsing, and converting data formats

#' Split mutations into separate rows
#'
#' Expands variant mutations from comma-separated format into separate rows.
#' This is useful for processing multi-mutation variants.
#'
#' @param df Data frame containing mutation data
#' @param mut_col Name of the column containing mutations (default: "mut")
#' @return Data frame with mutations split into separate rows
#' @examples
#' \dontrun{
#' df_split <- split_mutations(df, mut_col = "pos:mut")
#' }
#' @export
split_mutations <- function(df, mut_col = "mut") {
  stopifnot(is.data.frame(df))
  stopifnot(mut_col %in% names(df))
  
  df %>%
    separate_rows(.data[[mut_col]], sep = ",") %>%
    mutate(!!mut_col := str_trim(.data[[mut_col]]))
}

#' Collapse data after splitting mutations
#'
#' Sums count columns after mutations have been split, grouping by miRNA and mutation.
#' This is typically used after split_mutations() to aggregate counts.
#'
#' @param df Data frame with split mutations
#' @param mut_col Name of the mutation column (default: "mut")
#' @param count_cols Vector of column names containing count data
#' @return Data frame with counts summed by miRNA and mutation
#' @examples
#' \dontrun{
#' df_collapsed <- collapse_after_split(df, mut_col = "mut", count_cols = snv_cols)
#' }
#' @export
collapse_after_split <- function(df, mut_col = "mut", count_cols) {
  stopifnot(is.data.frame(df))
  stopifnot(mut_col %in% names(df))
  stopifnot(all(count_cols %in% names(df)))
  
  df %>%
    group_by(.data[["miRNA"]], .data[[mut_col]]) %>%
    summarise(across(all_of(count_cols), sum), .groups = "drop") %>%
    rename(miRNA_name = `miRNA name`)
}

#' Convert data to edgeR format
#'
#' Converts collapsed mutation data into a count matrix suitable for edgeR analysis.
#' Creates feature IDs by combining miRNA name and mutation, and ensures proper data types.
#'
#' @param df_collapsed Data frame with collapsed mutation counts
#' @param mut_col Name of the mutation column (default: "pos:mut")
#' @param count_cols Vector of column names containing count data
#' @return Matrix with counts, suitable for edgeR analysis
#' @examples
#' \dontrun{
#' count_matrix <- convert_to_edgeR(df_collapsed, mut_col = "pos:mut", count_cols = snv_cols)
#' }
#' @export
convert_to_edgeR <- function(df_collapsed, mut_col = "pos:mut", count_cols) {
  stopifnot(is.data.frame(df_collapsed))
  stopifnot(mut_col %in% names(df_collapsed))
  stopifnot(all(count_cols %in% names(df_collapsed)))
  
  df_DE <- df_collapsed %>%
    mutate(
      clean_mut  = str_replace_all(.data[[mut_col]], ":", "_"),
      featureID  = paste(miRNA_name, clean_mut, sep = "_")
    ) %>%
    select(featureID, all_of(count_cols))
  
  count_mat <- as.matrix(df_DE[count_cols])
  rownames(count_mat) <- df_DE$featureID
  mode(count_mat) <- "integer"
  
  stopifnot(exists("count_mat"))
  stopifnot(!any(is.na(count_mat)))
  cat("Dimensions of count_mat:", dim(count_mat), 
      "(rows = variants, cols = samples)\n")
  
  return(count_mat)
}

#' Identify sample groups from column names
#'
#' Categorizes sample columns into groups based on naming patterns.
#' Useful for organizing samples by experimental condition.
#'
#' @param sample_cols Vector of sample column names
#' @return List with sample groups (ALS_longitudinal, ALS_enrolment, control)
#' @examples
#' \dontrun{
#' groups <- identify_sample_groups(snv_cols)
#' }
#' @export
identify_sample_groups <- function(sample_cols) {
  stopifnot(is.character(sample_cols))
  
  list(
    ALS_longitudinal = sample_cols[str_detect(sample_cols, "ALS[-_]longitudinal")],
    ALS_enrolment    = sample_cols[str_detect(sample_cols, "ALS[-_]enrolment")],
    control          = sample_cols[str_detect(sample_cols, "-control-")]
  )
}

#' Create sample group data frame
#'
#' Creates a data frame organizing samples by group, with padding for equal length.
#' Useful for downstream analysis and visualization.
#'
#' @param sample_groups List of sample groups from identify_sample_groups()
#' @return Data frame with samples organized by group
#' @examples
#' \dontrun{
#' groups <- identify_sample_groups(snv_cols)
#' df_groups <- create_sample_group_df(groups)
#' }
#' @export
create_sample_group_df <- function(sample_groups) {
  stopifnot(is.list(sample_groups))
  stopifnot(all(c("ALS_longitudinal", "ALS_enrolment", "control") %in% names(sample_groups)))
  
  max_len <- max(length(sample_groups$ALS_longitudinal), 
                 length(sample_groups$ALS_enrolment), 
                 length(sample_groups$control))
  
  data.frame(
    ALS_longitudinal = c(sample_groups$ALS_longitudinal, rep(NA, max_len - length(sample_groups$ALS_longitudinal))),
    ALS_enrolment    = c(sample_groups$ALS_enrolment, rep(NA, max_len - length(sample_groups$ALS_enrolment))),
    control          = c(sample_groups$control, rep(NA, max_len - length(sample_groups$control))),
    stringsAsFactors = FALSE
  )
}

