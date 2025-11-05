# 🔬 COMPARISON FUNCTIONS - GROUP COMPARISON FOR FIGURE 3
# Generic functions for comparing 2 groups (e.g., ALS vs Control)

library(dplyr)
library(tidyr)
library(stringr)

source("functions/statistical_tests.R")

## ═══════════════════════════════════════════════════════════════════════════
## EXTRACT GROUPS FROM DATA
## ═══════════════════════════════════════════════════════════════════════════

#' Extract Sample Groups from Column Names
#' 
#' For datasets where group info is in column names (e.g., "Magen-ALS-...", "Magen-control-...")
#' 
#' @param data Raw data with sample columns
#' @param group_pattern Regex pattern to extract group (default: "ALS|control")
#' @return Data frame with sample_id and group
extract_groups_from_colnames <- function(data, group_pattern = "ALS|control") {
  
  # Get column names (excluding miRNA name and pos:mut)
  sample_cols <- names(data)[!names(data) %in% c("miRNA name", "pos:mut")]
  
  # Extract groups
  groups_df <- tibble(sample_id = sample_cols) %>%
    mutate(
      group = case_when(
        str_detect(sample_id, "ALS") ~ "ALS",
        str_detect(sample_id, "control") ~ "Control",
        TRUE ~ NA_character_
      )
    ) %>%
    filter(!is.na(group))
  
  cat("📊 Groups extracted from column names:\n")
  cat("   • ALS samples:", sum(groups_df$group == "ALS"), "\n")
  cat("   • Control samples:", sum(groups_df$group == "Control"), "\n")
  
  return(groups_df)
}

#' Load Sample Groups from File (User-Provided)
#' 
#' @param groups_file Path to CSV with sample_id and group columns
#' @return Data frame with validated groups
load_sample_groups <- function(groups_file) {
  
  if (!file.exists(groups_file)) {
    stop("Groups file not found: ", groups_file)
  }
  
  groups <- read.csv(groups_file)
  
  # Validate format
  required_cols <- c("sample_id", "group")
  if (!all(required_cols %in% names(groups))) {
    stop("Groups file must have columns: ", paste(required_cols, collapse = ", "))
  }
  
  # Check for 2 groups
  unique_groups <- unique(groups$group)
  if (length(unique_groups) != 2) {
    stop("Currently supports 2-group comparison only. Found: ", 
         paste(unique_groups, collapse = ", "))
  }
  
  cat("📊 Groups loaded from file:\n")
  for (grp in unique_groups) {
    cat("   •", grp, ":", sum(groups$group == grp), "samples\n")
  }
  
  return(groups)
}

## ═══════════════════════════════════════════════════════════════════════════
## GLOBAL G>T BURDEN COMPARISON
## ═══════════════════════════════════════════════════════════════════════════

#' Compare Global G>T Burden Between Groups
#' 
#' @param processed_data Processed mutation data (long format after separate_rows)
#' @param groups Data frame with sample_id and group
#' @return List with statistics and plot data
compare_global_gt_burden <- function(processed_data, groups) {
  
  cat("📊 Comparing global G>T burden...\n")
  
  # Calculate per-sample G>T count
  # Note: This is simplified - real implementation would need to map
  # back to original wide format with sample columns
  
  # For now, return structure showing what would be calculated
  cat("   ⚠️  Note: Requires wide-format data with sample columns\n")
  cat("   💡 Will calculate per-sample G>T count and compare groups\n")
  
  result <- list(
    method = "wilcoxon",
    groups_compared = unique(groups$group),
    note = "Implementation requires sample-level data structure"
  )
  
  return(result)
}

## ═══════════════════════════════════════════════════════════════════════════
## POSITION-SPECIFIC COMPARISON (CRITICAL FOR PANEL B)
## ═══════════════════════════════════════════════════════════════════════════

#' Compare G>T Frequency by Position Between Groups
#' 
#' This is the CRITICAL function for Panel B (position delta curve with stars)
#' 
#' @param processed_data Processed data with position and mutation_type
#' @param groups Sample grouping (can be extracted or user-provided)
#' @return Data frame with position-wise statistics
compare_positions_by_group <- function(processed_data, groups) {
  
  cat("📊 Comparing positions by group...\n")
  
  # Calculate G>T frequency per position overall (simplified for now)
  position_stats <- processed_data %>%
    filter(`pos:mut` != "PM") %>%
    separate(`pos:mut`, into = c("position", "mutation_type"), sep = ":", remove = FALSE) %>%
    mutate(position = as.numeric(position)) %>%
    filter(position >= 1 & position <= 22) %>%
    count(position, mutation_type) %>%
    group_by(position) %>%
    mutate(
      total_at_pos = sum(n),
      is_gt = mutation_type == "GT",
      gt_fraction = ifelse(is_gt, n / total_at_pos * 100, 0)
    ) %>%
    ungroup() %>%
    filter(is_gt) %>%
    select(position, gt_fraction, n_gt = n)
  
  # Complete missing positions
  all_positions <- tibble(position = 1:22)
  position_stats <- all_positions %>%
    left_join(position_stats, by = "position") %>%
    mutate(
      gt_fraction = replace_na(gt_fraction, 0),
      n_gt = replace_na(n_gt, 0)
    )
  
  # Add dummy group comparison (for demonstration)
  # Real implementation would calculate this per group from sample-level data
  position_stats <- position_stats %>%
    mutate(
      freq_ALS = gt_fraction * runif(n(), 0.8, 1.2),  # Dummy: slightly higher
      freq_Control = gt_fraction * runif(n(), 0.7, 1.0),  # Dummy: slightly lower
      pvalue = runif(n(), 0.001, 0.3),  # Dummy p-values
      qvalue = p.adjust(pvalue, method = "BH"),
      significant = qvalue < 0.05,
      stars = get_significance_stars(qvalue),
      in_seed = position >= 2 & position <= 8
    )
  
  cat("   ⚠️  Using simulated group differences (dummy data)\n")
  cat("   💡 Real implementation needs sample-level grouping\n")
  cat("   📊 Positions analyzed: 22\n")
  cat("   ⭐ Significant positions (dummy):", sum(position_stats$significant), "\n")
  
  return(position_stats)
}

## ═══════════════════════════════════════════════════════════════════════════
## SEED VS NON-SEED BY GROUP
## ═══════════════════════════════════════════════════════════════════════════

#' Compare Seed vs Non-Seed Enrichment Between Groups
#' 
#' Tests if seed region is MORE affected in one group (interaction)
#' 
#' @param processed_data Processed mutation data
#' @param groups Sample grouping
#' @return Fisher's exact test results for interaction
compare_seed_by_group <- function(processed_data, groups) {
  
  cat("📊 Comparing seed vs non-seed by group...\n")
  
  # Simplified: Calculate overall seed vs non-seed
  gt_data <- processed_data %>%
    filter(`pos:mut` != "PM") %>%
    separate(`pos:mut`, into = c("position", "mutation_type"), sep = ":", remove = FALSE) %>%
    filter(mutation_type == "GT") %>%
    mutate(
      position = as.numeric(position),
      region = ifelse(position >= 2 & position <= 8, "Seed", "Non-Seed")
    ) %>%
    filter(position >= 1 & position <= 22)
  
  # Count by region
  region_counts <- gt_data %>%
    count(region)
  
  # Dummy group comparison
  result <- list(
    seed_count = region_counts %>% filter(region == "Seed") %>% pull(n),
    nonseed_count = region_counts %>% filter(region == "Non-Seed") %>% pull(n),
    note = "Real implementation requires 2×2 table (Region × Group)"
  )
  
  cat("   • Seed G>T:", result$seed_count, "\n")
  cat("   • Non-Seed G>T:", result$nonseed_count, "\n")
  cat("   ⚠️  Group comparison requires sample-level data\n")
  
  return(result)
}

## ═══════════════════════════════════════════════════════════════════════════
## DIFFERENTIAL miRNAs
## ═══════════════════════════════════════════════════════════════════════════

#' Identify Differential miRNAs Between Groups
#' 
#' @param processed_data Processed mutation data
#' @param groups Sample grouping
#' @param min_mirna_count Minimum G>T count to include miRNA
#' @return Data frame with per-miRNA statistics
identify_differential_mirnas <- function(processed_data, groups, min_mirna_count = 5) {
  
  cat("📊 Identifying differential miRNAs...\n")
  
  # Count G>T per miRNA
  mirna_gt_counts <- processed_data %>%
    filter(`pos:mut` != "PM") %>%
    separate(`pos:mut`, into = c("position", "mutation_type"), sep = ":", remove = FALSE) %>%
    filter(mutation_type == "GT") %>%
    count(`miRNA name`, name = "gt_count") %>%
    filter(gt_count >= min_mirna_count) %>%
    arrange(desc(gt_count))
  
  # Add dummy statistics for demonstration
  mirna_stats <- mirna_gt_counts %>%
    mutate(
      log2fc = rnorm(n(), mean = 0, sd = 0.5),  # Dummy fold-change
      pvalue = runif(n(), 0.001, 0.5),  # Dummy p-values
      qvalue = p.adjust(pvalue, method = "BH"),
      significant = qvalue < 0.05 & abs(log2fc) > 0.5
    )
  
  cat("   • miRNAs analyzed:", nrow(mirna_stats), "\n")
  cat("   • Significant (dummy):", sum(mirna_stats$significant), "\n")
  cat("   ⚠️  Using simulated statistics (dummy data)\n")
  
  return(mirna_stats)
}

## ═══════════════════════════════════════════════════════════════════════════
## HELPER: Create Dummy Groups for Testing
## ═══════════════════════════════════════════════════════════════════════════

#' Create Dummy Sample Groups for Testing
#' 
#' Useful when testing pipeline without real metadata
#' 
#' @param data Raw data to extract sample names from
#' @return Data frame with sample_id and group (extracted or simulated)
create_dummy_groups_from_data <- function(data) {
  
  # Extract from column names if pattern exists
  sample_cols <- names(data)[!names(data) %in% c("miRNA name", "pos:mut")]
  
  groups_df <- tibble(sample_id = sample_cols) %>%
    mutate(
      group = case_when(
        str_detect(sample_id, "ALS") ~ "ALS",
        str_detect(sample_id, "control") ~ "Control",
        TRUE ~ sample(c("ALS", "Control"), n(), replace = TRUE)  # Random if no pattern
      )
    )
  
  return(groups_df)
}
