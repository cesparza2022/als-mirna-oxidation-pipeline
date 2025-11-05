# Fixed Analysis Script for ALS miRNA Oxidation Research
# This script fixes the group assignment issues and implements proper G>T analysis

# Load required libraries
library(tidyverse)
library(data.table)
library(ggplot2)

# Source modules
source("R/io.R")
source("R/qc.R")
source("R/normalize.R")
source("R/stats.R")
source("R/plots.R")
source("R/load_mirna_data.R")

#' Run fixed analysis with proper group assignments and G>T rate calculations
#'
#' @param config_file Path to configuration file (default: "config.yaml")
#' @param output_dir Output directory for results (default: "outputs")
#' @return List containing analysis results
#' @export
run_fixed_analysis <- function(config_file = "config.yaml", output_dir = "outputs") {
  cat("=== Starting Fixed ALS miRNA Oxidation Analysis ===\n")
  
  # Load and prepare data
  cat("1. Loading and preparing data...\n")
  data_results <- load_and_prepare_data(config_file)
  
  # Extract components
  mirna_data <- data_results$filtered_data
  sample_metadata <- mirna_data$sample_metadata
  count_matrix <- mirna_data$count_matrix
  mirna_info <- mirna_data$mirna_info
  
  # Identify sample groups properly
  cat("2. Identifying sample groups...\n")
  sample_cols <- colnames(count_matrix)
  sample_groups <- identify_sample_groups(sample_cols)
  
  # Create proper sample metadata with group assignments
  sample_metadata_fixed <- data.frame(
    sample_id = sample_cols,
    group = case_when(
      grepl("ALS", sample_cols) ~ "ALS",
      grepl("control", sample_cols) ~ "Control",
      TRUE ~ "Unknown"
    ),
    stringsAsFactors = FALSE
  )
  
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
    group = sample_metadata_fixed$group
  )
  
  p_counts_dist <- plot_total_counts_distribution(df_long)
  
  # Calculate group statistics
  group_stats <- df_long %>%
    group_by(group) %>%
    summarise(
      n = n(),
      mean_total = mean(total_counts, na.rm = TRUE),
      median_total = median(total_counts, na.rm = TRUE),
      sd_total = sd(total_counts, na.rm = TRUE),
      .groups = "drop"
    )
  
  print("Group Statistics:")
  print(group_stats)
  
  # Analyze SNV presence
  cat("5. Analyzing SNV presence...\n")
  df_presence <- data.frame(
    miRNA = mirna_info$mirna_name,
    mut = mirna_info$mutation,
    count_matrix
  )
  
  # Calculate basic SNV statistics
  snv_stats <- df_presence %>%
    select(-miRNA, -mut) %>%
    summarise_all(~sum(. > 0, na.rm = TRUE)) %>%
    pivot_longer(everything(), names_to = "sample", values_to = "n_snvs") %>%
    mutate(group = sample_metadata_fixed$group[match(sample, sample_metadata_fixed$sample_id)])
  
  p_snv_dist <- ggplot(snv_stats, aes(x = group, y = n_snvs, fill = group)) +
    geom_violin(alpha = 0.4, color = NA) +
    geom_boxplot(width = 0.3, outlier.size = 0.8, alpha = 0.6) +
    stat_summary(
      fun = mean,
      geom = "point",
      shape = 23,
      size = 3,
      color = "black",
      fill = "yellow"
    ) +
    labs(
      title = "SNV Count Distribution by Group",
      x = "Sample Group",
      y = "Number of SNVs per Sample"
    ) +
    theme_minimal() +
    theme(legend.position = "none")
  
  # Identify G>T mutations with proper group assignment
  cat("6. Analyzing G>T mutations with proper group assignment...\n")
  gt_analysis <- identify_gt_mutations(df_presence)
  
  if (!is.null(gt_analysis)) {
    # Fix group assignment
    gt_analysis$gt_summary$group <- sample_metadata_fixed$group[match(
      gt_analysis$gt_summary$sample_id, sample_metadata_fixed$sample_id
    )]
    
    # Calculate G>T rates (G>T counts / total counts)
    gt_analysis$gt_summary$gt_rate <- gt_analysis$gt_summary$gt_count / 
      df_long$total_counts[match(gt_analysis$gt_summary$sample_id, df_long$sample)]
    
    p_gt_mutations <- plot_gt_mutations(gt_analysis)
    
    # Create G>T rate comparison plot
    p_gt_rates <- ggplot(gt_analysis$gt_summary, aes(x = group, y = gt_rate, fill = group)) +
      geom_violin(alpha = 0.4, color = NA) +
      geom_boxplot(width = 0.3, outlier.size = 0.8, alpha = 0.6) +
      stat_summary(
        fun = mean,
        geom = "point",
        shape = 23,
        size = 3,
        color = "black",
        fill = "yellow"
      ) +
      scale_y_continuous(labels = scales::percent) +
      labs(
        title = "G>T Mutation Rate by Group",
        x = "Sample Group",
        y = "G>T Rate (G>T counts / Total counts)"
      ) +
      theme_minimal() +
      theme(legend.position = "none")
    
    # Statistical test for G>T rates
    gt_test <- t.test(gt_rate ~ group, data = gt_analysis$gt_summary)
    cat("G>T Rate Comparison (t-test):\n")
    cat("p-value:", gt_test$p.value, "\n")
    cat("Mean G>T rate - ALS:", mean(gt_analysis$gt_summary$gt_rate[gt_analysis$gt_summary$group == "ALS"], na.rm = TRUE), "\n")
    cat("Mean G>T rate - Control:", mean(gt_analysis$gt_summary$gt_rate[gt_analysis$gt_summary$group == "Control"], na.rm = TRUE), "\n")
    
  } else {
    p_gt_mutations <- NULL
    p_gt_rates <- NULL
  }
  
  # Create proper mutation type distribution
  cat("7. Analyzing mutation type distribution...\n")
  mutation_types <- df_presence %>%
    select(miRNA, mut) %>%
    distinct() %>%
    mutate(
      mutation_type = case_when(
        str_detect(mut, "G>T") ~ "G>T",
        str_detect(mut, "A>T") ~ "A>T", 
        str_detect(mut, "C>T") ~ "C>T",
        str_detect(mut, "T>") ~ "T>X",
        str_detect(mut, "G>") ~ "G>X",
        str_detect(mut, "A>") ~ "A>X",
        str_detect(mut, "C>") ~ "C>X",
        TRUE ~ "Other"
      )
    )
  
  mutation_type_counts <- mutation_types %>%
    count(mutation_type) %>%
    arrange(desc(n))
  
  p_mutation_types <- ggplot(mutation_type_counts, aes(x = reorder(mutation_type, n), y = n)) +
    geom_bar(stat = "identity", fill = "steelblue", alpha = 0.7) +
    coord_flip() +
    labs(
      title = "Distribution of Mutation Types",
      x = "Mutation Type",
      y = "Count"
    ) +
    theme_minimal()
  
  # Save results
  cat("8. Saving results...\n")
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  
  # Save plots
  ggsave(file.path(output_dir, "figures", "sample_distribution_fixed.png"), p_sample_dist, 
         width = 10, height = 8, dpi = 300)
  ggsave(file.path(output_dir, "figures", "total_counts_distribution_fixed.png"), p_counts_dist, 
         width = 10, height = 8, dpi = 300)
  ggsave(file.path(output_dir, "figures", "snv_distribution_fixed.png"), p_snv_dist, 
         width = 10, height = 8, dpi = 300)
  ggsave(file.path(output_dir, "figures", "mutation_types_fixed.png"), p_mutation_types, 
         width = 10, height = 8, dpi = 300)
  
  if (!is.null(p_gt_mutations)) {
    ggsave(file.path(output_dir, "figures", "gt_mutations_fixed.png"), p_gt_mutations, 
           width = 10, height = 8, dpi = 300)
    ggsave(file.path(output_dir, "figures", "gt_rates_fixed.png"), p_gt_rates, 
           width = 10, height = 8, dpi = 300)
  }
  
  # Save data tables
  write.csv(group_stats, file.path(output_dir, "tables", "group_statistics_fixed.csv"), row.names = FALSE)
  write.csv(mutation_type_counts, file.path(output_dir, "tables", "mutation_type_counts_fixed.csv"), row.names = FALSE)
  
  if (!is.null(gt_analysis)) {
    write.csv(gt_analysis$gt_summary, file.path(output_dir, "tables", "gt_mutation_summary_fixed.csv"), row.names = FALSE)
  }
  
  # Compile results
  results <- list(
    data = data_results,
    sample_groups = sample_groups,
    group_stats = group_stats,
    snv_stats = snv_stats,
    mutation_type_counts = mutation_type_counts,
    gt_analysis = gt_analysis,
    plots = list(
      sample_distribution = p_sample_dist,
      counts_distribution = p_counts_dist,
      snv_distribution = p_snv_dist,
      mutation_types = p_mutation_types,
      gt_mutations = p_gt_mutations,
      gt_rates = p_gt_rates
    )
  )
  
  cat("=== Fixed Analysis Complete ===\n")
  cat("Results saved to:", output_dir, "\n")
  
  return(results)
}

# Run analysis if script is executed directly
if (interactive()) {
  cat("Running Fixed ALS miRNA Oxidation Analysis...\n")
  results <- run_fixed_analysis()
  
  # Print summary
  cat("\n=== ANALYSIS SUMMARY ===\n")
  cat("Total samples:", nrow(results$data$sample_metadata), "\n")
  cat("Total mutations:", nrow(results$data$mirna_info), "\n")
  
  if (!is.null(results$gt_analysis)) {
    cat("G>T mutations found:", nrow(results$gt_analysis$gt_mutations), "\n")
    cat("Mean G>T rate - ALS:", mean(results$gt_analysis$gt_summary$gt_rate[results$gt_analysis$gt_summary$group == "ALS"], na.rm = TRUE), "\n")
    cat("Mean G>T rate - Control:", mean(results$gt_analysis$gt_summary$gt_rate[results$gt_analysis$gt_summary$group == "Control"], na.rm = TRUE), "\n")
  }
  
  cat("Analysis complete! Check the 'outputs' directory for results.\n")
}

