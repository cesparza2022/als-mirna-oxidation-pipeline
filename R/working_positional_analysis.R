#' Working Positional Analysis of miRNA Oxidation
#' 
#' This script analyzes positional differences in G>T oxidation between ALS and Control groups

# Load required libraries
library(dplyr)
library(ggplot2)
library(tidyr)
library(stringr)
library(purrr)
library(scales)

#' Run working positional analysis
run_working_positional_analysis <- function() {
  cat("=== WORKING POSITIONAL ANALYSIS OF miRNA OXIDATION ===\n")
  
  # Load data
  source("R/load_mirna_data.R")
  mirna_data <- load_and_prepare_data()
  
  # Get G>T mutations and sample metadata
  gt_mutations <- mirna_data$gt_analysis$gt_mutations
  sample_metadata <- mirna_data$filtered_data$sample_metadata
  gt_count_matrix <- mirna_data$gt_analysis$gt_count_matrix
  
  cat("Found", nrow(gt_mutations), "G>T mutations\n")
  cat("Sample metadata rows:", nrow(sample_metadata), "\n")
  cat("GT count matrix dimensions:", dim(gt_count_matrix), "\n")
  
  # Extract position information from mutation strings
  cat("Extracting position information...\n")
  
  # Create a function to extract positions from mutation strings
  extract_positions <- function(mutation_string) {
    # Handle single mutations like "9:TG"
    if (str_detect(mutation_string, "^\\d+:")) {
      pos <- as.numeric(str_extract(mutation_string, "^\\d+"))
      mut_type <- str_extract(mutation_string, "[A-Z]+$")
      return(data.frame(position = pos, mutation_type = mut_type))
    }
    # Handle multiple mutations like "1:TC,2:GT"
    else if (str_detect(mutation_string, ",")) {
      parts <- str_split(mutation_string, ",")[[1]]
      positions <- map_dfr(parts, function(part) {
        if (str_detect(part, ":")) {
          pos <- as.numeric(str_extract(part, "\\d+"))
          mut_type <- str_extract(part, "[A-Z]+$")
          return(data.frame(position = pos, mutation_type = mut_type))
        }
        return(data.frame(position = NA, mutation_type = NA))
      })
      return(positions[!is.na(positions$position), ])
    }
    return(data.frame(position = NA, mutation_type = NA))
  }
  
  # Extract positions for all G>T mutations
  position_data <- map_dfr(1:nrow(gt_mutations), function(i) {
    positions <- extract_positions(gt_mutations$mutation[i])
    if (nrow(positions) > 0) {
      positions$miRNA <- gt_mutations$miRNA[i]
      positions$mutation_string <- gt_mutations$mutation[i]
      return(positions)
    }
    return(data.frame(position = NA, mutation_type = NA, miRNA = gt_mutations$miRNA[i], 
                     mutation_string = gt_mutations$mutation[i]))
  })
  
  # Remove rows with missing position data
  position_data <- position_data[!is.na(position_data$position), ]
  cat("Found", nrow(position_data), "positional G>T mutations\n")
  
  # Get sample columns
  sample_cols <- colnames(gt_count_matrix)
  
  # Create position-sample data
  cat("Creating position-sample matrix...\n")
  
  # For each position, get the counts across all samples
  position_sample_data <- map_dfr(1:nrow(position_data), function(i) {
    pos <- position_data$position[i]
    mirna <- position_data$miRNA[i]
    mut_string <- position_data$mutation_string[i]
    
    # Find the corresponding row in gt_count_matrix
    row_idx <- which(gt_mutations$miRNA == mirna & gt_mutations$mutation == mut_string)
    
    if (length(row_idx) > 0) {
      counts <- as.numeric(gt_count_matrix[row_idx, ])
      
      # Create data frame
      data.frame(
        position = rep(pos, length(sample_cols)),
        miRNA = rep(mirna, length(sample_cols)),
        sample_id = sample_cols,
        count = counts,
        stringsAsFactors = FALSE
      )
    } else {
      return(NULL)
    }
  })
  
  cat("Position-sample data dimensions:", dim(position_sample_data), "\n")
  
  if (nrow(position_sample_data) == 0) {
    cat("ERROR: No position-sample data created. Check data structure.\n")
    return(NULL)
  }
  
  # Add group information
  cat("Adding group information...\n")
  position_sample_data$group <- sample_metadata$group[match(
    gsub("\\.", "-", position_sample_data$sample_id), 
    sample_metadata$sample_id
  )]
  
  # Remove samples without group assignment
  position_sample_data <- position_sample_data[!is.na(position_sample_data$group), ]
  cat("After group assignment:", nrow(position_sample_data), "rows\n")
  
  # Calculate position-level statistics
  cat("Calculating position-level statistics...\n")
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
  
  # Calculate position-level rates
  position_rates <- position_sample_data %>%
    group_by(position, group) %>%
    summarise(
      n_samples = n(),
      samples_with_mutation = sum(count > 0, na.rm = TRUE),
      mutation_rate = sum(count > 0, na.rm = TRUE) / n(),
      mean_count_per_sample = mean(count, na.rm = TRUE),
      .groups = "drop"
    )
  
  # Add seed region information
  position_stats$is_seed_region <- position_stats$position >= 2 & position_stats$position <= 8
  position_rates$is_seed_region <- position_rates$position >= 2 & position_rates$position <= 8
  
  # Create output directory
  if (!dir.exists("outputs/figures")) {
    dir.create("outputs/figures", recursive = TRUE)
  }
  if (!dir.exists("outputs/tables")) {
    dir.create("outputs/tables", recursive = TRUE)
  }
  
  # Create plots
  cat("Creating plots...\n")
  
  # 1. G>T Count by Position and Group
  p1 <- ggplot(position_stats, aes(x = position, y = total_count, fill = group)) +
    geom_bar(stat = "identity", position = "dodge", alpha = 0.8) +
    geom_vline(xintercept = c(2, 8), linetype = "dashed", color = "red", alpha = 0.7) +
    annotate("text", x = 5, y = max(position_stats$total_count) * 0.9, 
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
  
  ggsave("outputs/figures/positional_gt_counts.png", p1, width = 12, height = 8, dpi = 300)
  
  # 2. G>T Rate by Position and Group
  p2 <- ggplot(position_rates, aes(x = position, y = mutation_rate, color = group)) +
    geom_line(size = 1.2, alpha = 0.8) +
    geom_point(size = 2, alpha = 0.8) +
    geom_vline(xintercept = c(2, 8), linetype = "dashed", color = "red", alpha = 0.7) +
    annotate("text", x = 5, y = max(position_rates$mutation_rate) * 0.9, 
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
  
  ggsave("outputs/figures/positional_gt_rates.png", p2, width = 12, height = 8, dpi = 300)
  
  # 3. Seed Region vs Non-Seed Region Comparison
  seed_comparison <- position_rates %>%
    group_by(group, is_seed_region) %>%
    summarise(
      mean_rate = mean(mutation_rate, na.rm = TRUE),
      se_rate = sd(mutation_rate, na.rm = TRUE) / sqrt(n()),
      .groups = "drop"
    )
  
  p3 <- ggplot(seed_comparison, aes(x = is_seed_region, y = mean_rate, fill = group)) +
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
  
  ggsave("outputs/figures/seed_region_comparison.png", p3, width = 10, height = 8, dpi = 300)
  
  # 4. Position Distribution Heatmap
  p4 <- ggplot(position_sample_data %>%
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
  
  ggsave("outputs/figures/position_heatmap.png", p4, width = 8, height = 10, dpi = 300)
  
  # 5. Statistical comparison by position
  position_tests <- map_dfr(unique(position_rates$position), function(pos) {
    pos_data <- position_rates[position_rates$position == pos, ]
    
    if (nrow(pos_data) == 2) {
      als_rate <- pos_data$mutation_rate[pos_data$group == "ALS"]
      control_rate <- pos_data$mutation_rate[pos_data$group == "Control"]
      
      data.frame(
        position = pos,
        als_rate = als_rate,
        control_rate = control_rate,
        difference = als_rate - control_rate,
        fold_change = ifelse(control_rate > 0, als_rate / control_rate, NA),
        is_seed_region = pos >= 2 & pos <= 8,
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
  
  ggsave("outputs/figures/position_differences.png", p5, width = 12, height = 8, dpi = 300)
  
  # Save results
  write.csv(position_stats, "outputs/tables/positional_stats.csv", row.names = FALSE)
  write.csv(position_rates, "outputs/tables/positional_rates.csv", row.names = FALSE)
  write.csv(seed_comparison, "outputs/tables/seed_region_comparison.csv", row.names = FALSE)
  write.csv(position_tests, "outputs/tables/position_tests.csv", row.names = FALSE)
  
  # Print summary
  cat("\n=== POSITIONAL ANALYSIS SUMMARY ===\n")
  cat("Total positional G>T mutations analyzed:", nrow(position_data), "\n")
  cat("Positions with mutations:", length(unique(position_data$position)), "\n")
  cat("Range of positions:", min(position_data$position), "-", max(position_data$position), "\n")
  
  # Seed region summary
  seed_data <- position_rates[position_rates$is_seed_region, ]
  cat("\nSeed Region (positions 2-8) Summary:\n")
  seed_summary <- seed_data %>%
    group_by(group) %>%
    summarise(
      mean_rate = mean(mutation_rate, na.rm = TRUE),
      total_mutations = sum(n_samples * mutation_rate, na.rm = TRUE),
      .groups = "drop"
    )
  print(seed_summary)
  
  # Print position test results
  cat("\nPosition-by-position comparison (ALS - Control):\n")
  print(position_tests)
  
  # Statistical tests for seed region
  cat("\n=== STATISTICAL TESTS ===\n")
  
  # Seed region comparison
  seed_als <- position_rates$mutation_rate[position_rates$is_seed_region & position_rates$group == "ALS"]
  seed_control <- position_rates$mutation_rate[position_rates$is_seed_region & position_rates$group == "Control"]
  
  if (length(seed_als) > 0 && length(seed_control) > 0) {
    seed_t_test <- t.test(seed_als, seed_control)
    cat("Seed Region T-test (ALS vs Control):\n")
    cat("  p-value:", seed_t_test$p.value, "\n")
    cat("  Mean ALS:", mean(seed_als), "\n")
    cat("  Mean Control:", mean(seed_control), "\n")
  }
  
  # Non-seed region comparison
  nonseed_als <- position_rates$mutation_rate[!position_rates$is_seed_region & position_rates$group == "ALS"]
  nonseed_control <- position_rates$mutation_rate[!position_rates$is_seed_region & position_rates$group == "Control"]
  
  if (length(nonseed_als) > 0 && length(nonseed_control) > 0) {
    nonseed_t_test <- t.test(nonseed_als, nonseed_control)
    cat("Non-Seed Region T-test (ALS vs Control):\n")
    cat("  p-value:", nonseed_t_test$p.value, "\n")
    cat("  Mean ALS:", mean(nonseed_als), "\n")
    cat("  Mean Control:", mean(nonseed_control), "\n")
  }
  
  return(list(
    position_data = position_data,
    position_stats = position_stats,
    position_rates = position_rates,
    seed_comparison = seed_comparison,
    position_tests = position_tests
  ))
}

# Run the analysis
if (!interactive()) {
  results <- run_working_positional_analysis()
}











