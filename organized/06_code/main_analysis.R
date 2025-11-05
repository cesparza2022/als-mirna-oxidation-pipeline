# Main Analysis Script for ALS miRNA Oxidation Research
# This script demonstrates the complete analysis pipeline using modular functions

# Load required libraries
library(tidyverse)
library(data.table)
library(ggplot2)
library(pheatmap)
library(UpSetR)
library(viridis)

# Source all modules
source("R/io.R")
source("R/qc.R")
source("R/normalize.R")
source("R/stats.R")
source("R/plots.R")
source("R/load_mirna_data.R")

#' Run complete ALS miRNA oxidation analysis
#'
#' Executes the complete analysis pipeline from data loading to visualization.
#' This is the main function that orchestrates all analysis steps.
#'
#' @param config_file Path to configuration file (default: "config.yaml")
#' @param output_dir Output directory for results (default: "results")
#' @return List containing all analysis results
#' @examples
#' \dontrun{
#' results <- run_complete_analysis()
#' }
#' @export
run_complete_analysis <- function(config_file = "config.yaml", output_dir = "results") {
  cat("=== Starting ALS miRNA Oxidation Analysis ===\n")
  
  # Load and prepare data
  cat("1. Loading and preparing data...\n")
  data_results <- load_and_prepare_data(config_file)
  
  # Extract components
  mirna_data <- data_results$filtered_data
  sample_metadata <- mirna_data$sample_metadata
  count_matrix <- mirna_data$count_matrix
  mirna_info <- mirna_data$mirna_info
  
  # Identify sample groups
  cat("2. Identifying sample groups...\n")
  sample_cols <- colnames(count_matrix)
  sample_groups <- identify_sample_groups(sample_cols)
  df_groups <- create_sample_group_df(sample_groups)
  
  # Create sample distribution plot
  cat("3. Creating sample distribution plot...\n")
  sample_counts <- c(
    "ALS-Longitudinal" = length(sample_groups$ALS_longitudinal),
    "ALS-Enrolment" = length(sample_groups$ALS_enrolment),
    "Control" = length(sample_groups$control)
  )
  
  p_sample_dist <- plot_sample_distribution(sample_counts)
  
  # Calculate total counts and create distribution plot
  cat("4. Analyzing total counts distribution...\n")
  df_long <- data.frame(
    sample = sample_cols,
    total_counts = colSums(count_matrix),
    group = sample_metadata$group[match(sample_cols, sample_metadata$sample_id)]
  )
  
  p_counts_dist <- plot_total_counts_distribution(df_long)
  
  # Calculate group statistics
  group_stats <- calculate_group_stats(df_long)
  print(group_stats)
  
  # Analyze SNV presence
  cat("5. Analyzing SNV presence...\n")
  df_presence <- data.frame(
    miRNA = mirna_info$mirna_name,
    mut = mirna_info$mutation,
    count_matrix
  )
  
  df_presence_counts <- calculate_group_presence(df_presence, sample_groups)
  
  # Create SNV prevalence plots
  df_counts_long <- df_presence_counts %>%
    select(miRNA, mut, n_long, n_enrol, n_ctrl) %>%
    pivot_longer(
      cols = c(n_long, n_enrol, n_ctrl),
      names_to = "group_code",
      values_to = "n_samples"
    ) %>%
    mutate(group = recode(
      group_code,
      n_long = "ALS-Longitudinal",
      n_enrol = "ALS-Enrolment",
      n_ctrl = "Control"
    ))
  
  p_snv_prev <- plot_snv_prevalence_histogram(df_counts_long, facet_by_group = TRUE)
  
  # Create UpSet plot
  snv_lists <- list(
    `ALS-Longitudinal` = df_presence_counts$id[df_presence_counts$has_long],
    `ALS-Enrolment` = df_presence_counts$id[df_presence_counts$has_enrol],
    `Control` = df_presence_counts$id[df_presence_counts$has_ctrl]
  )
  
  p_upset <- plot_snv_upset(snv_lists)
  
  # Calculate frequencies
  cat("6. Calculating mutation frequencies...\n")
  total_counts <- colSums(count_matrix)
  df_freq <- calculate_frequency_percentages(df_presence, total_counts, sample_cols)
  
  # Convert to long format for analysis
  df_freq_long <- df_freq %>%
    pivot_longer(
      all_of(sample_cols),
      names_to = "sample",
      values_to = "freq_pct"
    ) %>%
    mutate(group = sample_metadata$group[match(sample, sample_metadata$sample_id)])
  
  # Calculate group means
  df_snv_means <- calculate_snv_group_means(df_freq_long)
  
  # Get top SNVs by group
  top_snvs <- get_top_snvs_by_group(df_snv_means, n_top = 5, 
                                   group_names = c("ALS.Enrolment", "ALS.Longitudinal", "Control"))
  
  # Identify G>T mutations
  cat("7. Analyzing G>T mutations...\n")
  gt_analysis <- identify_gt_mutations(df_presence)
  
  if (!is.null(gt_analysis)) {
    # Add group information to G>T summary
    gt_analysis$gt_summary$group <- sample_metadata$group[match(
      gt_analysis$gt_summary$sample_id, sample_metadata$sample_id
    )]
    
    p_gt_mutations <- plot_gt_mutations(gt_analysis)
  } else {
    p_gt_mutations <- NULL
  }
  
  # Calculate mutation burden
  cat("8. Calculating mutation burden...\n")
  burden_df <- calculate_mutation_burden(df_freq, sample_cols)
  p_burden <- plot_mutation_burden(burden_df, n_top = 20)
  
  # Create heatmap of top SNVs
  cat("9. Creating SNV heatmap...\n")
  df_wide <- df_freq %>%
    mutate(mean_freq = rowMeans(select(., all_of(sample_cols)), na.rm = TRUE)) %>%
    arrange(desc(mean_freq)) %>%
    slice(1:50)  # Top 50 SNVs
  
  p_heatmap <- plot_snv_heatmap(df_wide, sample_cols, n_top = 50)
  
  # Calculate correlations between groups
  cat("10. Calculating group correlations...\n")
  cor_matrix <- calculate_group_correlation(df_snv_means, 
                                          group_names = c("ALS.Enrolment", "ALS.Longitudinal", "Control"))
  p_correlation <- plot_correlation_heatmap(cor_matrix)
  
  # Save results
  cat("11. Saving results...\n")
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  
  # Save plots
  ggsave(file.path(output_dir, "sample_distribution.png"), p_sample_dist, 
         width = 10, height = 8, dpi = 300)
  ggsave(file.path(output_dir, "total_counts_distribution.png"), p_counts_dist, 
         width = 10, height = 8, dpi = 300)
  ggsave(file.path(output_dir, "snv_prevalence.png"), p_snv_prev, 
         width = 12, height = 8, dpi = 300)
  ggsave(file.path(output_dir, "mutation_burden.png"), p_burden, 
         width = 10, height = 8, dpi = 300)
  ggsave(file.path(output_dir, "correlation_heatmap.png"), p_correlation, 
         width = 8, height = 6, dpi = 300)
  
  if (!is.null(p_gt_mutations)) {
    ggsave(file.path(output_dir, "gt_mutations.png"), p_gt_mutations, 
           width = 10, height = 8, dpi = 300)
  }
  
  # Save data tables
  write.csv(df_snv_means, file.path(output_dir, "snv_group_means.csv"), row.names = FALSE)
  write.csv(burden_df, file.path(output_dir, "mutation_burden.csv"), row.names = FALSE)
  write.csv(group_stats, file.path(output_dir, "group_statistics.csv"), row.names = FALSE)
  
  if (!is.null(gt_analysis)) {
    write.csv(gt_analysis$gt_summary, file.path(output_dir, "gt_mutation_summary.csv"), row.names = FALSE)
  }
  
  # Compile results
  results <- list(
    data = data_results,
    sample_groups = sample_groups,
    group_stats = group_stats,
    snv_means = df_snv_means,
    top_snvs = top_snvs,
    gt_analysis = gt_analysis,
    burden_df = burden_df,
    correlation_matrix = cor_matrix,
    plots = list(
      sample_distribution = p_sample_dist,
      counts_distribution = p_counts_dist,
      snv_prevalence = p_snv_prev,
      gt_mutations = p_gt_mutations,
      mutation_burden = p_burden,
      correlation = p_correlation
    )
  )
  
  cat("=== Analysis Complete ===\n")
  cat("Results saved to:", output_dir, "\n")
  
  return(results)
}

# Run analysis if script is executed directly
if (interactive()) {
  cat("Running ALS miRNA Oxidation Analysis...\n")
  results <- run_complete_analysis()
  
  # Print summary
  cat("\n=== ANALYSIS SUMMARY ===\n")
  cat("Total samples:", nrow(results$data$sample_metadata), "\n")
  cat("Total mutations:", nrow(results$data$mirna_info), "\n")
  cat("Selected miRNAs:", length(results$data$filtered_data$summary$selected_miRNAs), "\n")
  
  if (!is.null(results$gt_analysis)) {
    cat("G>T mutations found:", nrow(results$gt_analysis$gt_mutations), "\n")
  }
  
  cat("Analysis complete! Check the 'results' directory for outputs.\n")
}

