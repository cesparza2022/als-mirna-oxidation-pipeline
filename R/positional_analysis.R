#' Positional Analysis of miRNA Oxidation
#' 
#' This script analyzes positional differences in G>T oxidation between ALS and Control groups
#' and generates comprehensive visualizations.

# Load required libraries
library(dplyr)
library(ggplot2)
library(tidyr)
library(stringr)
library(purrr)
library(scales)
library(viridisLite)

#' Extract position information from mutation strings
#' @param mutation_string Character vector of mutation strings (e.g., "2:GT", "1:TC,2:GT")
#' @return Data frame with position and mutation type information
extract_position_info <- function(mutation_string) {
  # Split by comma for multiple mutations
  mutations <- str_split(mutation_string, ",")[[1]]
  
  # Extract position and mutation type for each
  position_data <- map_dfr(mutations, function(mut) {
    if (str_detect(mut, ":")) {
      parts <- str_split(mut, ":")[[1]]
      data.frame(
        position = as.numeric(parts[1]),
        mutation_type = parts[2],
        stringsAsFactors = FALSE
      )
    } else {
      data.frame(
        position = NA,
        mutation_type = NA,
        stringsAsFactors = FALSE
      )
    }
  })
  
  return(position_data)
}

#' Analyze positional G>T oxidation patterns
#' @param mirna_data List containing miRNA data and metadata
#' @return List with positional analysis results
analyze_positional_oxidation <- function(mirna_data) {
  cat("Analyzing positional G>T oxidation patterns...\n")
  
  # Get G>T mutations
  gt_mutations <- mirna_data$gt_analysis$gt_mutations
  sample_metadata <- mirna_data$filtered_data$sample_metadata
  
  # Extract position information for all G>T mutations
  cat("Extracting position information from G>T mutations...\n")
  
  position_data <- map_dfr(1:nrow(gt_mutations), function(i) {
    mutation_info <- extract_position_info(gt_mutations$mutation[i])
    if (nrow(mutation_info) > 0) {
      mutation_info$miRNA <- gt_mutations$miRNA[i]
      mutation_info$mutation_string <- gt_mutations$mutation[i]
      return(mutation_info)
    } else {
      return(data.frame(
        position = NA,
        mutation_type = NA,
        miRNA = gt_mutations$miRNA[i],
        mutation_string = gt_mutations$mutation[i],
        stringsAsFactors = FALSE
      ))
    }
  })
  
  # Remove rows with missing position data
  position_data <- position_data[!is.na(position_data$position), ]
  
  cat("Found", nrow(position_data), "positional G>T mutations\n")
  
  # Get sample counts for each position by group
  sample_cols <- names(mirna_data$gt_analysis$gt_count_matrix)
  
  # Create position-sample matrix
  position_sample_data <- map_dfr(1:nrow(position_data), function(i) {
    pos <- position_data$position[i]
    mirna <- position_data$miRNA[i]
    
    # Find the corresponding row in gt_count_matrix
    row_idx <- which(gt_mutations$miRNA == mirna & 
                     gt_mutations$mutation == position_data$mutation_string[i])
    
    if (length(row_idx) > 0) {
      counts <- mirna_data$gt_analysis$gt_count_matrix[row_idx, ]
      
      # Create data frame with position, sample, and count
      data.frame(
        position = rep(pos, length(sample_cols)),
        miRNA = rep(mirna, length(sample_cols)),
        sample_id = sample_cols,
        count = as.numeric(counts),
        stringsAsFactors = FALSE
      )
    } else {
      return(NULL)
    }
  })
  
  # Add group information
  position_sample_data$group <- sample_metadata$group[match(
    gsub("\\.", "-", position_sample_data$sample_id), 
    sample_metadata$sample_id
  )]
  
  # Remove samples without group assignment
  position_sample_data <- position_sample_data[!is.na(position_sample_data$group), ]
  
  # Calculate position-level statistics
  position_stats <- position_sample_data %>%
    group_by(position, group) %>%
    summarise(
      n_samples = n(),
      total_count = sum(count, na.rm = TRUE),
      mean_count = mean(count, na.rm = TRUE),
      median_count = median(count, na.rm = TRUE),
      sd_count = sd(count, na.rm = TRUE),
      .groups = "drop"
    )
  
  # Calculate position-level rates (count per sample)
  position_rates <- position_sample_data %>%
    group_by(position, group) %>%
    summarise(
      n_samples = n(),
      samples_with_mutation = sum(count > 0, na.rm = TRUE),
      mutation_rate = sum(count > 0, na.rm = TRUE) / n(),
      mean_count_per_sample = mean(count, na.rm = TRUE),
      .groups = "drop"
    )
  
  # Identify seed region positions (positions 2-8)
  position_stats$is_seed_region <- position_stats$position >= 2 & position_stats$position <= 8
  position_rates$is_seed_region <- position_rates$position >= 2 & position_rates$position <= 8
  
  return(list(
    position_data = position_data,
    position_sample_data = position_sample_data,
    position_stats = position_stats,
    position_rates = position_rates
  ))
}

#' Create positional analysis plots
#' @param positional_results List from analyze_positional_oxidation
#' @param output_dir Directory to save plots
#' @return List of plot objects
create_positional_plots <- function(positional_results, output_dir = "outputs/figures") {
  cat("Creating positional analysis plots...\n")
  
  plots <- list()
  
  # 1. G>T Count by Position and Group
  p1 <- ggplot(positional_results$position_stats, 
               aes(x = position, y = total_count, fill = group)) +
    geom_bar(stat = "identity", position = "dodge", alpha = 0.8) +
    geom_vline(xintercept = c(2, 8), linetype = "dashed", color = "red", alpha = 0.7) +
    annotate("text", x = 5, y = max(positional_results$position_stats$total_count) * 0.9, 
             label = "Seed Region", color = "red", size = 4) +
    labs(
      title = "G>T Mutation Counts by Position and Group",
      subtitle = "Red dashed lines indicate seed region (positions 2-8)",
      x = "Position in miRNA",
      y = "Total G>T Count",
      fill = "Group"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      plot.subtitle = element_text(size = 12),
      axis.text.x = element_text(angle = 45, hjust = 1),
      legend.position = "bottom"
    ) +
    scale_fill_manual(values = c("ALS" = "#1f77b4", "Control" = "#ff7f0e"))
  
  plots$count_by_position <- p1
  
  # 2. G>T Rate by Position and Group
  p2 <- ggplot(positional_results$position_rates, 
               aes(x = position, y = mutation_rate, color = group)) +
    geom_line(size = 1.2, alpha = 0.8) +
    geom_point(size = 2, alpha = 0.8) +
    geom_vline(xintercept = c(2, 8), linetype = "dashed", color = "red", alpha = 0.7) +
    annotate("text", x = 5, y = max(positional_results$position_rates$mutation_rate) * 0.9, 
             label = "Seed Region", color = "red", size = 4) +
    labs(
      title = "G>T Mutation Rate by Position and Group",
      subtitle = "Proportion of samples with G>T mutations at each position",
      x = "Position in miRNA",
      y = "Mutation Rate",
      color = "Group"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      plot.subtitle = element_text(size = 12),
      axis.text.x = element_text(angle = 45, hjust = 1),
      legend.position = "bottom"
    ) +
    scale_color_manual(values = c("ALS" = "#1f77b4", "Control" = "#ff7f0e")) +
    scale_y_continuous(labels = percent_format())
  
  plots$rate_by_position <- p2
  
  # 3. Seed Region vs Non-Seed Region Comparison
  seed_comparison <- positional_results$position_rates %>%
    group_by(group, is_seed_region) %>%
    summarise(
      mean_rate = mean(mutation_rate, na.rm = TRUE),
      se_rate = sd(mutation_rate, na.rm = TRUE) / sqrt(n()),
      .groups = "drop"
    )
  
  p3 <- ggplot(seed_comparison, 
               aes(x = is_seed_region, y = mean_rate, fill = group)) +
    geom_bar(stat = "identity", position = "dodge", alpha = 0.8) +
    geom_errorbar(aes(ymin = mean_rate - se_rate, ymax = mean_rate + se_rate),
                  position = position_dodge(0.9), width = 0.2) +
    labs(
      title = "G>T Mutation Rate: Seed Region vs Non-Seed Region",
      subtitle = "Comparison of mutation rates in functional seed region (positions 2-8)",
      x = "Region",
      y = "Mean Mutation Rate",
      fill = "Group"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      plot.subtitle = element_text(size = 12),
      legend.position = "bottom"
    ) +
    scale_fill_manual(values = c("ALS" = "#1f77b4", "Control" = "#ff7f0e")) +
    scale_x_discrete(labels = c("FALSE" = "Non-Seed Region", "TRUE" = "Seed Region")) +
    scale_y_continuous(labels = percent_format())
  
  plots$seed_comparison <- p3
  
  # 4. Position Distribution Heatmap
  position_heatmap_data <- positional_results$position_sample_data %>%
    group_by(position, group) %>%
    summarise(
      mean_count = mean(count, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    pivot_wider(names_from = group, values_from = mean_count, values_fill = 0)
  
  # Convert to matrix for heatmap
  heatmap_matrix <- as.matrix(position_heatmap_data[, -1])
  rownames(heatmap_matrix) <- position_heatmap_data$position
  
  p4 <- ggplot(positional_results$position_sample_data %>%
                 group_by(position, group) %>%
                 summarise(mean_count = mean(count, na.rm = TRUE), .groups = "drop"),
               aes(x = group, y = position, fill = mean_count)) +
    geom_tile() +
    scale_fill_viridis_c(name = "Mean Count", option = "plasma") +
    labs(
      title = "G>T Mutation Heatmap by Position and Group",
      subtitle = "Mean mutation count across samples",
      x = "Group",
      y = "Position in miRNA"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      plot.subtitle = element_text(size = 12),
      axis.text.x = element_text(angle = 45, hjust = 1)
    )
  
  plots$position_heatmap <- p4
  
  # 5. Statistical comparison by position
  position_tests <- map_dfr(unique(positional_results$position_rates$position), function(pos) {
    pos_data <- positional_results$position_rates[positional_results$position_rates$position == pos, ]
    
    if (nrow(pos_data) == 2) {
      als_rate <- pos_data$mutation_rate[pos_data$group == "ALS"]
      control_rate <- pos_data$mutation_rate[pos_data$group == "Control"]
      
      # Simple comparison (could be enhanced with proper statistical test)
      data.frame(
        position = pos,
        als_rate = als_rate,
        control_rate = control_rate,
        difference = als_rate - control_rate,
        fold_change = ifelse(control_rate > 0, als_rate / control_rate, NA),
        stringsAsFactors = FALSE
      )
    } else {
      return(NULL)
    }
  })
  
  p5 <- ggplot(position_tests, aes(x = position, y = difference, fill = difference > 0)) +
    geom_bar(stat = "identity", alpha = 0.8) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "black") +
    geom_vline(xintercept = c(2, 8), linetype = "dashed", color = "red", alpha = 0.7) +
    labs(
      title = "G>T Rate Difference by Position (ALS - Control)",
      subtitle = "Positive values indicate higher ALS rates",
      x = "Position in miRNA",
      y = "Rate Difference",
      fill = "Higher in ALS"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      plot.subtitle = element_text(size = 12),
      axis.text.x = element_text(angle = 45, hjust = 1),
      legend.position = "bottom"
    ) +
    scale_fill_manual(values = c("FALSE" = "#ff7f0e", "TRUE" = "#1f77b4")) +
    scale_y_continuous(labels = percent_format())
  
  plots$position_difference <- p5
  
  # Save plots
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  
  ggsave(file.path(output_dir, "positional_gt_counts.png"), p1, 
         width = 12, height = 8, dpi = 300)
  ggsave(file.path(output_dir, "positional_gt_rates.png"), p2, 
         width = 12, height = 8, dpi = 300)
  ggsave(file.path(output_dir, "seed_region_comparison.png"), p3, 
         width = 10, height = 8, dpi = 300)
  ggsave(file.path(output_dir, "position_heatmap.png"), p4, 
         width = 8, height = 10, dpi = 300)
  ggsave(file.path(output_dir, "position_differences.png"), p5, 
         width = 12, height = 8, dpi = 300)
  
  cat("Positional analysis plots saved to", output_dir, "\n")
  
  return(list(
    plots = plots,
    position_tests = position_tests,
    seed_comparison = seed_comparison
  ))
}

#' Run complete positional analysis
#' @param output_dir Directory to save results
#' @return List with all analysis results
run_positional_analysis <- function(output_dir = "outputs") {
  cat("=== POSITIONAL ANALYSIS OF miRNA OXIDATION ===\n")
  
  # Load data
  source("R/load_mirna_data.R")
  mirna_data <- load_and_prepare_data()
  
  # Run positional analysis
  positional_results <- analyze_positional_oxidation(mirna_data)
  
  # Create plots
  plot_results <- create_positional_plots(positional_results, file.path(output_dir, "figures"))
  
  # Save results
  if (!dir.exists(file.path(output_dir, "tables"))) {
    dir.create(file.path(output_dir, "tables"), recursive = TRUE)
  }
  
  write.csv(positional_results$position_stats, 
            file.path(output_dir, "tables", "positional_stats.csv"), 
            row.names = FALSE)
  write.csv(positional_results$position_rates, 
            file.path(output_dir, "tables", "positional_rates.csv"), 
            row.names = FALSE)
  write.csv(plot_results$position_tests, 
            file.path(output_dir, "tables", "position_tests.csv"), 
            row.names = FALSE)
  write.csv(plot_results$seed_comparison, 
            file.path(output_dir, "tables", "seed_region_comparison.csv"), 
            row.names = FALSE)
  
  cat("Positional analysis results saved to", output_dir, "\n")
  
  # Print summary
  cat("\n=== POSITIONAL ANALYSIS SUMMARY ===\n")
  cat("Total positional G>T mutations analyzed:", nrow(positional_results$position_data), "\n")
  cat("Positions with mutations:", length(unique(positional_results$position_data$position)), "\n")
  cat("Range of positions:", min(positional_results$position_data$position), "-", 
      max(positional_results$position_data$position), "\n")
  
  # Seed region summary
  seed_data <- positional_results$position_rates[positional_results$position_rates$is_seed_region, ]
  cat("\nSeed Region (positions 2-8) Summary:\n")
  seed_summary <- seed_data %>%
    group_by(group) %>%
    summarise(
      mean_rate = mean(mutation_rate, na.rm = TRUE),
      total_mutations = sum(n_samples * mutation_rate, na.rm = TRUE),
      .groups = "drop"
    )
  print(seed_summary)
  
  return(list(
    positional_results = positional_results,
    plot_results = plot_results,
    summary = list(
      total_mutations = nrow(positional_results$position_data),
      positions_covered = length(unique(positional_results$position_data$position)),
      position_range = range(positional_results$position_data$position),
      seed_summary = seed_summary
    )
  ))
}

# Run the analysis if called directly
if (!interactive()) {
  results <- run_positional_analysis()
}
