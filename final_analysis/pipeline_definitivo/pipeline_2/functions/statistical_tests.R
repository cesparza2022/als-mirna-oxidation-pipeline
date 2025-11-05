# 📊 STATISTICAL TESTS - GENERIC FUNCTIONS FOR GROUP COMPARISON
# Generic, reusable statistical functions for any 2-group comparison

library(dplyr)
library(tidyr)
library(broom)

## ═══════════════════════════════════════════════════════════════════════════
## WILCOXON RANK-SUM TEST (Non-parametric)
## ═══════════════════════════════════════════════════════════════════════════

#' Wilcoxon Rank-Sum Test (Mann-Whitney U)
#' 
#' Generic 2-group comparison
#' 
#' @param values Numeric vector of values
#' @param groups Factor or character vector of group labels
#' @return List with test results
wilcoxon_test_generic <- function(values, groups) {
  
  # Remove NAs
  valid_idx <- !is.na(values) & !is.na(groups)
  values <- values[valid_idx]
  groups <- groups[valid_idx]
  
  # Get unique groups
  unique_groups <- unique(groups)
  if (length(unique_groups) != 2) {
    stop("Wilcoxon test requires exactly 2 groups")
  }
  
  # Perform test
  test_result <- wilcox.test(values ~ groups, exact = FALSE)
  
  # Calculate medians
  group_a_vals <- values[groups == unique_groups[1]]
  group_b_vals <- values[groups == unique_groups[2]]
  
  median_a <- median(group_a_vals, na.rm = TRUE)
  median_b <- median(group_b_vals, na.rm = TRUE)
  
  # Return results
  list(
    statistic = test_result$statistic,
    pvalue = test_result$p.value,
    median_groupA = median_a,
    median_groupB = median_b,
    n_groupA = length(group_a_vals),
    n_groupB = length(group_b_vals),
    group_labels = unique_groups
  )
}

## ═══════════════════════════════════════════════════════════════════════════
## FISHER'S EXACT TEST (Categorical)
## ═══════════════════════════════════════════════════════════════════════════

#' Fisher's Exact Test for 2×2 Tables
#' 
#' @param counts_a Vector of counts for group A (c(success, failure))
#' @param counts_b Vector of counts for group B (c(success, failure))
#' @return List with test results including OR
fisher_test_generic <- function(counts_a, counts_b) {
  
  # Create contingency table
  contingency <- matrix(c(counts_a, counts_b), nrow = 2, byrow = TRUE)
  
  # Perform test
  test_result <- fisher.test(contingency)
  
  # Return results
  list(
    pvalue = test_result$p.value,
    odds_ratio = test_result$estimate,
    ci_lower = test_result$conf.int[1],
    ci_upper = test_result$conf.int[2],
    contingency_table = contingency
  )
}

## ═══════════════════════════════════════════════════════════════════════════
## FDR CORRECTION (Multiple Testing)
## ═══════════════════════════════════════════════════════════════════════════

#' FDR Correction (Benjamini-Hochberg)
#' 
#' @param pvalues Vector of p-values
#' @param method FDR method (default: "BH")
#' @return Vector of adjusted p-values (q-values)
fdr_correction <- function(pvalues, method = "BH") {
  p.adjust(pvalues, method = method)
}

## ═══════════════════════════════════════════════════════════════════════════
## EFFECT SIZES
## ═══════════════════════════════════════════════════════════════════════════

#' Cohen's d Effect Size
#' 
#' @param group_a Numeric vector for group A
#' @param group_b Numeric vector for group B
#' @return Cohen's d value
cohens_d <- function(group_a, group_b) {
  
  # Remove NAs
  group_a <- group_a[!is.na(group_a)]
  group_b <- group_b[!is.na(group_b)]
  
  # Calculate means
  mean_a <- mean(group_a)
  mean_b <- mean(group_b)
  
  # Calculate pooled SD
  n_a <- length(group_a)
  n_b <- length(group_b)
  
  var_a <- var(group_a)
  var_b <- var(group_b)
  
  pooled_sd <- sqrt(((n_a - 1) * var_a + (n_b - 1) * var_b) / (n_a + n_b - 2))
  
  # Cohen's d
  d <- (mean_a - mean_b) / pooled_sd
  
  return(d)
}

#' Odds Ratio Calculation
#' 
#' @param a,b,c,d Cells of 2×2 table
#' @return OR with CI
calculate_odds_ratio <- function(a, b, c, d) {
  
  # OR = (a*d) / (b*c)
  or <- (a * d) / (b * c)
  
  # Log(OR) SE
  log_or_se <- sqrt(1/a + 1/b + 1/c + 1/d)
  
  # 95% CI
  ci_lower <- exp(log(or) - 1.96 * log_or_se)
  ci_upper <- exp(log(or) + 1.96 * log_or_se)
  
  list(
    odds_ratio = or,
    ci_lower = ci_lower,
    ci_upper = ci_upper,
    log_or = log(or),
    log_or_se = log_or_se
  )
}

## ═══════════════════════════════════════════════════════════════════════════
## SIGNIFICANCE LABELS
## ═══════════════════════════════════════════════════════════════════════════

#' Get Significance Stars
#' 
#' @param qvalue FDR-adjusted p-value
#' @return Character string with stars
get_significance_stars <- function(qvalue) {
  case_when(
    is.na(qvalue) ~ "",
    qvalue < 0.001 ~ "***",
    qvalue < 0.01 ~ "**",
    qvalue < 0.05 ~ "*",
    TRUE ~ ""
  )
}

## ═══════════════════════════════════════════════════════════════════════════
## SUMMARY STATISTICS
## ═══════════════════════════════════════════════════════════════════════════

#' Calculate Summary Statistics by Group
#' 
#' @param values Numeric vector
#' @param groups Group labels
#' @return Data frame with summary stats
summary_stats_by_group <- function(values, groups) {
  
  data.frame(values = values, group = groups) %>%
    group_by(group) %>%
    summarise(
      n = n(),
      mean = mean(values, na.rm = TRUE),
      median = median(values, na.rm = TRUE),
      sd = sd(values, na.rm = TRUE),
      q25 = quantile(values, 0.25, na.rm = TRUE),
      q75 = quantile(values, 0.75, na.rm = TRUE),
      min = min(values, na.rm = TRUE),
      max = max(values, na.rm = TRUE),
      .groups = "drop"
    )
}

#' Format P-value for Display
#' 
#' @param pvalue Numeric p-value
#' @return Formatted string
format_pvalue <- function(pvalue) {
  case_when(
    is.na(pvalue) ~ "NA",
    pvalue < 0.001 ~ "< 0.001",
    pvalue < 0.01 ~ sprintf("= %.3f", pvalue),
    TRUE ~ sprintf("= %.2f", pvalue)
  )
}

## ═══════════════════════════════════════════════════════════════════════════
## EXPORT
## ═══════════════════════════════════════════════════════════════════════════

# All functions exported automatically when sourced

