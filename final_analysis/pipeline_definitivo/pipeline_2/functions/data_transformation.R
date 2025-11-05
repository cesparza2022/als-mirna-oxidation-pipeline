# 🔄 DATA TRANSFORMATION - WIDE TO LONG WITH GROUPS
# Critical function for enabling per-sample group comparisons

library(dplyr)
library(tidyr)
library(stringr)

## ═══════════════════════════════════════════════════════════════════════════
## MAIN TRANSFORMATION: WIDE → LONG
## ═══════════════════════════════════════════════════════════════════════════

#' Transform Wide Format Data to Long Format with Group Assignment
#' 
#' This is the CRITICAL function that enables all Tier 2 (group comparison) analyses.
#' 
#' Transforms from:
#'   miRNA | pos:mut | Sample1 | Sample2 | ...
#'   let-7a | 3:GT    | 0.15    | 0.23    | ...
#' 
#' To:
#'   miRNA | sample_id | group | position | mutation_type | vaf
#'   let-7a | Sample1  | ALS   | 3        | G>T          | 0.15
#'   let-7a | Sample2  | ALS   | 3        | G>T          | 0.23
#' 
#' @param raw_data Raw data in wide format (samples as columns)
#' @param groups Data frame with sample_id and group columns
#' @return Data in long format ready for group comparisons
#' @export
transform_wide_to_long_with_groups <- function(raw_data, groups) {
  
  cat("🔄 Transforming data: WIDE → LONG with groups...\n")
  
  # 1. Identify sample columns (all except miRNA name and pos:mut)
  metadata_cols <- c("miRNA name", "pos:mut")
  sample_cols <- setdiff(names(raw_data), metadata_cols)
  
  cat("   📊 Detected", length(sample_cols), "sample columns\n")
  
  # 2. Pivot to long format (samples → rows)
  cat("   🔄 Pivoting to long format...\n")
  data_long <- raw_data %>%
    pivot_longer(
      cols = all_of(sample_cols),
      names_to = "sample_id",
      values_to = "vaf"
    )
  
  cat("   ✅ Pivoted:", format(nrow(data_long), big.mark = ","), "rows\n")
  
  # 3. Join with group assignments
  cat("   👥 Joining with groups...\n")
  data_long <- data_long %>%
    left_join(groups, by = "sample_id")
  
  # Check for unmatched samples
  n_unmatched <- sum(is.na(data_long$group))
  if (n_unmatched > 0) {
    cat("   ⚠️  Warning:", n_unmatched, "rows with unmatched samples (removed)\n")
    data_long <- data_long %>% filter(!is.na(group))
  }
  
  cat("   ✅ Groups assigned\n")
  
  # 4. Separate rows for multiple mutations (split by comma)
  cat("   🔄 Separating concatenated mutations...\n")
  data_long <- data_long %>%
    separate_rows(`pos:mut`, sep = ",")
  
  cat("   ✅ Separated:", format(nrow(data_long), big.mark = ","), "mutation entries\n")
  
  # 5. Filter out Perfect Matches
  cat("   🧹 Filtering PM (Perfect Match) entries...\n")
  data_long <- data_long %>%
    filter(`pos:mut` != "PM")
  
  cat("   ✅ Filtered:", format(nrow(data_long), big.mark = ","), "valid entries\n")
  
  # 6. Extract position and mutation type
  cat("   🔍 Extracting position and mutation type...\n")
  data_long <- data_long %>%
    separate(`pos:mut`, into = c("position", "mutation_type_raw"), 
             sep = ":", remove = FALSE) %>%
    mutate(
      position = as.numeric(position),
      # Convert mutation format: GT → G>T, TC → T>C, etc.
      mutation_type = case_when(
        mutation_type_raw == "GT" ~ "G>T",
        mutation_type_raw == "GA" ~ "G>A",
        mutation_type_raw == "GC" ~ "G>C",
        mutation_type_raw == "TC" ~ "T>C",
        mutation_type_raw == "AG" ~ "A>G",
        mutation_type_raw == "CT" ~ "C>T",
        mutation_type_raw == "TA" ~ "T>A",
        mutation_type_raw == "TG" ~ "T>G",
        mutation_type_raw == "AT" ~ "A>T",
        mutation_type_raw == "CA" ~ "C>A",
        mutation_type_raw == "CG" ~ "C>G",
        mutation_type_raw == "AC" ~ "A>C",
        TRUE ~ mutation_type_raw
      )
    )
  
  cat("   ✅ Position and mutation type extracted\n")
  
  # 7. Filter valid positions (1-22 for miRNAs)
  cat("   🧹 Filtering valid positions (1-22)...\n")
  data_long <- data_long %>%
    filter(position >= 1 & position <= 22, !is.na(position))
  
  cat("   ✅ Final:", format(nrow(data_long), big.mark = ","), "valid mutations\n")
  
  # 8. Add region annotation (seed vs non-seed)
  data_long <- data_long %>%
    mutate(
      region = ifelse(position >= 2 & position <= 8, "Seed", "Non-Seed")
    )
  
  # Summary statistics
  cat("\n📊 TRANSFORMATION SUMMARY:\n")
  cat("   • Total mutations:", format(nrow(data_long), big.mark = ","), "\n")
  cat("   • Unique miRNAs:", length(unique(data_long$`miRNA name`)), "\n")
  cat("   • Unique samples:", length(unique(data_long$sample_id)), "\n")
  
  group_summary <- data_long %>%
    group_by(group) %>%
    summarise(
      n_samples = n_distinct(sample_id),
      n_mutations = n(),
      n_gt = sum(mutation_type == "G>T"),
      .groups = "drop"
    )
  
  for (i in 1:nrow(group_summary)) {
    cat("   •", group_summary$group[i], ":\n")
    cat("      - Samples:", group_summary$n_samples[i], "\n")
    cat("      - Mutations:", format(group_summary$n_mutations[i], big.mark = ","), "\n")
    cat("      - G>T:", format(group_summary$n_gt[i], big.mark = ","), 
        sprintf("(%.1f%%)", group_summary$n_gt[i]/group_summary$n_mutations[i]*100), "\n")
  }
  
  cat("\n✅ TRANSFORMATION COMPLETE - Ready for group comparisons\n\n")
  
  return(data_long)
}

## ═══════════════════════════════════════════════════════════════════════════
## HELPER: Extract Groups from Column Names
## ═══════════════════════════════════════════════════════════════════════════

#' Extract Sample Groups from Column Names
#' 
#' For datasets where group info is embedded in column names
#' (e.g., "Magen-ALS-...", "Magen-control-...")
#' 
#' @param raw_data Raw data with sample columns
#' @param als_pattern Pattern to identify ALS samples (default: "ALS")
#' @param control_pattern Pattern to identify Control samples (default: "control")
#' @return Data frame with sample_id and group
#' @export
extract_groups_from_colnames <- function(raw_data, 
                                         als_pattern = "ALS", 
                                         control_pattern = "control") {
  
  cat("👥 Extracting sample groups from column names...\n")
  
  # Get column names (excluding metadata columns)
  sample_cols <- names(raw_data)[!names(raw_data) %in% c("miRNA name", "pos:mut")]
  
  # Extract groups based on patterns
  groups_df <- tibble(sample_id = sample_cols) %>%
    mutate(
      group = case_when(
        str_detect(sample_id, regex(als_pattern, ignore_case = TRUE)) ~ "ALS",
        str_detect(sample_id, regex(control_pattern, ignore_case = TRUE)) ~ "Control",
        TRUE ~ NA_character_
      )
    )
  
  # Remove unmatched samples
  n_unmatched <- sum(is.na(groups_df$group))
  if (n_unmatched > 0) {
    cat("   ⚠️  Warning:", n_unmatched, "samples without group assignment (removed)\n")
    groups_df <- groups_df %>% filter(!is.na(group))
  }
  
  # Summary
  cat("   ✅ Groups extracted:\n")
  for (grp in unique(groups_df$group)) {
    n <- sum(groups_df$group == grp)
    cat("      •", grp, ":", n, "samples\n")
  }
  
  # Validate: need at least 2 groups
  n_groups <- length(unique(groups_df$group))
  if (n_groups < 2) {
    stop("Need at least 2 groups for comparison. Found: ", n_groups)
  }
  
  cat("\n")
  return(groups_df)
}

## ═══════════════════════════════════════════════════════════════════════════
## QUALITY CHECKS
## ═══════════════════════════════════════════════════════════════════════════

#' Validate Transformed Data
#' 
#' @param data_long Transformed long-format data
#' @return Logical indicating if data is valid
#' @export
validate_transformed_data <- function(data_long) {
  
  cat("🔍 Validating transformed data...\n")
  
  required_cols <- c("miRNA name", "sample_id", "group", "position", 
                     "mutation_type", "vaf", "region")
  
  missing_cols <- setdiff(required_cols, names(data_long))
  if (length(missing_cols) > 0) {
    cat("   ❌ Missing columns:", paste(missing_cols, collapse = ", "), "\n")
    return(FALSE)
  }
  
  # Check for NAs in critical columns
  critical_na_checks <- data_long %>%
    summarise(
      na_group = sum(is.na(group)),
      na_position = sum(is.na(position)),
      na_mutation = sum(is.na(mutation_type))
    )
  
  if (critical_na_checks$na_group > 0) {
    cat("   ⚠️  Warning:", critical_na_checks$na_group, "rows with NA group\n")
  }
  
  # Check position range
  invalid_positions <- sum(data_long$position < 1 | data_long$position > 22, na.rm = TRUE)
  if (invalid_positions > 0) {
    cat("   ⚠️  Warning:", invalid_positions, "rows with invalid positions\n")
  }
  
  cat("   ✅ Data validation passed\n\n")
  return(TRUE)
}

