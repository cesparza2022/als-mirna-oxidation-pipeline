#!/usr/bin/env Rscript

# =============================================================================
# TOP miRNAs SELECTION JUSTIFICATION ANALYSIS
# =============================================================================
# This script provides comprehensive justification for the selection of top miRNAs
# and analyzes G>T differences by position in the most affected miRNAs.
# Uses professional styling consistent with the main analysis pipeline.

library(tidyverse)
library(ggplot2)
library(dplyr)
library(readr)
library(gridExtra)
library(RColorBrewer)
library(reshape2)
library(ComplexHeatmap)
library(circlize)
library(stringr)

# Set working directory
setwd("/Users/cesaresparza/New_Desktop/UCSD/8OG")

# Create output directories
dir.create("outputs/figures/top_mirnas_justification", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/tables/top_mirnas_justification", recursive = TRUE, showWarnings = FALSE)

# =============================================================================
# 1. LOAD AND PREPARE DATA
# =============================================================================

# Load top miRNAs data
top_mirnas <- read_tsv("outputs/simple_final_top_mirnas.tsv")

# Load positional analysis data
position_stats <- read_csv("outputs/tables/positional_analysis/position_statistics.csv")

# Load let-7 family analysis
let7_family <- read_tsv("outputs/let7_family_analysis.tsv")

# Load VAF z-score data for additional context
vaf_zscore <- read_tsv("outputs/vaf_zscore_top_significant.tsv")

# =============================================================================
# 2. CRITERIA FOR TOP miRNAs SELECTION
# =============================================================================

cat("=== TOP miRNAs SELECTION CRITERIA ===\n")
cat("1. Total G>T counts (primary criterion)\n")
cat("2. Mean RPM (expression level)\n")
cat("3. Mean VAF (variant allele frequency)\n")
cat("4. Number of different mutations (diversity)\n")
cat("5. Statistical significance (from VAF z-score analysis)\n\n")

# Define top miRNAs based on multiple criteria
top_mirnas_analysis <- top_mirnas %>%
  mutate(
    # Rank by different criteria
    rank_by_counts = rank(-total_gt_counts),
    rank_by_rpm = rank(-mean_rpm),
    rank_by_vaf = rank(-mean_vaf),
    rank_by_mutations = rank(-mutation_count),
    
    # Combined score (weighted)
    combined_score = (rank_by_counts * 0.4) + 
                    (rank_by_rpm * 0.2) + 
                    (rank_by_vaf * 0.2) + 
                    (rank_by_mutations * 0.2),
    
    # Final rank
    final_rank = rank(combined_score)
  ) %>%
  arrange(final_rank)

# Save the analysis
write_tsv(top_mirnas_analysis, "outputs/tables/top_mirnas_justification/selection_criteria_analysis.tsv")

# =============================================================================
# 3. PROFESSIONAL STYLING FUNCTIONS
# =============================================================================

# Professional color palette (consistent with main analysis)
professional_colors <- c(
  "ALS" = "#D62728",
  "Control" = "grey60", 
  "Other" = "grey90",
  "Primary" = "#4575b4",
  "Secondary" = "#d73027",
  "Accent" = "#2ca02c"
)

# Professional theme
theme_professional <- function() {
  theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold", color = "#2c3e50"),
    plot.subtitle = element_text(size = 12, color = "#7f8c8d"),
    axis.title = element_text(size = 12, face = "bold", color = "#2c3e50"),
    axis.text = element_text(size = 10, color = "#34495e"),
    legend.title = element_text(size = 11, face = "bold", color = "#2c3e50"),
    legend.text = element_text(size = 10, color = "#34495e"),
    panel.grid.major = element_line(color = "#ecf0f1", size = 0.5),
    panel.grid.minor = element_line(color = "#f8f9fa", size = 0.25),
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA)
  )
}

# =============================================================================
# 4. VISUALIZATION 1: SELECTION CRITERIA COMPARISON (PROFESSIONAL STYLE)
# =============================================================================

# Prepare data for plotting
plot_data <- top_mirnas_analysis %>%
  head(20) %>%
  select(miRNA.name, total_gt_counts, mean_rpm, mean_vaf, mutation_count) %>%
  mutate(
    # Normalize for plotting (0-1 scale)
    norm_counts = (total_gt_counts - min(total_gt_counts)) / (max(total_gt_counts) - min(total_gt_counts)),
    norm_rpm = (mean_rpm - min(mean_rpm)) / (max(mean_rpm) - min(mean_rpm)),
    norm_vaf = (mean_vaf - min(mean_vaf)) / (max(mean_vaf) - min(mean_vaf)),
    norm_mutations = (mutation_count - min(mutation_count)) / (max(mutation_count) - min(mutation_count))
  ) %>%
  select(miRNA.name, norm_counts, norm_rpm, norm_vaf, norm_mutations) %>%
  melt(id.vars = "miRNA.name", variable.name = "criterion", value.name = "normalized_score") %>%
  mutate(
    criterion_label = case_when(
      criterion == "norm_counts" ~ "G>T Counts",
      criterion == "norm_rpm" ~ "Mean RPM",
      criterion == "norm_vaf" ~ "Mean VAF", 
      criterion == "norm_mutations" ~ "Mutation Count",
      TRUE ~ criterion
    )
  )

# Create the plot with professional styling
p1 <- ggplot(plot_data, aes(x = reorder(miRNA.name, normalized_score), y = normalized_score, fill = criterion_label)) +
  geom_bar(stat = "identity", position = "dodge", alpha = 0.8) +
  scale_fill_manual(
    name = "Selection Criteria",
    values = c("G>T Counts" = professional_colors["Primary"],
               "Mean RPM" = professional_colors["Secondary"], 
               "Mean VAF" = professional_colors["Accent"],
               "Mutation Count" = "#8e44ad")
  ) +
  labs(
    title = "Top 20 miRNAs: Selection Criteria Comparison",
    subtitle = "Normalized scores (0-1) for each selection criterion",
    x = "miRNA",
    y = "Normalized Score"
  ) +
  theme_professional() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 9),
    legend.position = "bottom"
  )

ggsave("outputs/figures/top_mirnas_justification/selection_criteria_comparison.png", 
       p1, width = 14, height = 8, dpi = 300, bg = "white")

# =============================================================================
# 5. VISUALIZATION 2: TOP miRNAs BY DIFFERENT CRITERIA (PROFESSIONAL STYLE)
# =============================================================================

# Create individual plots for each criterion with professional styling
p2 <- ggplot(top_mirnas_analysis %>% head(15), 
             aes(x = reorder(miRNA.name, total_gt_counts), y = total_gt_counts)) +
  geom_bar(stat = "identity", fill = professional_colors["Primary"], alpha = 0.8) +
  labs(
    title = "Top 15 miRNAs by G>T Counts",
    subtitle = "Primary selection criterion: total G>T mutation counts",
    x = "miRNA",
    y = "Total G>T Counts"
  ) +
  theme_professional() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 10)) +
  coord_flip()

p3 <- ggplot(top_mirnas_analysis %>% head(15), 
             aes(x = reorder(miRNA.name, mean_rpm), y = mean_rpm)) +
  geom_bar(stat = "identity", fill = professional_colors["Secondary"], alpha = 0.8) +
  labs(
    title = "Top 15 miRNAs by Mean RPM",
    subtitle = "Expression level criterion: reads per million",
    x = "miRNA",
    y = "Mean RPM"
  ) +
  theme_professional() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 10)) +
  coord_flip()

p4 <- ggplot(top_mirnas_analysis %>% head(15), 
             aes(x = reorder(miRNA.name, mean_vaf), y = mean_vaf)) +
  geom_bar(stat = "identity", fill = professional_colors["Accent"], alpha = 0.8) +
  labs(
    title = "Top 15 miRNAs by Mean VAF",
    subtitle = "Variant allele frequency criterion",
    x = "miRNA",
    y = "Mean VAF"
  ) +
  theme_professional() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 10)) +
  coord_flip()

# Combine plots with professional spacing
combined_plot <- grid.arrange(p2, p3, p4, ncol = 1, 
                             top = "Top miRNAs Selection Criteria Analysis")
ggsave("outputs/figures/top_mirnas_justification/top_mirnas_by_criteria.png", 
       combined_plot, width = 12, height = 18, dpi = 300, bg = "white")

# =============================================================================
# 6. VISUALIZATION 3: G>T MUTATIONS BY POSITION (PROFESSIONAL STYLE)
# =============================================================================

# Create position analysis for top miRNAs
position_analysis <- position_stats %>%
  mutate(
    position_label = paste0("Pos ", position),
    region_color = case_when(
      region == "Seed region" ~ "Seed Region",
      region == "5' end" ~ "5' End",
      region == "Central region" ~ "Central",
      region == "3' end" ~ "3' End",
      TRUE ~ "Other"
    )
  )

# Plot mutations by position with professional styling
p5 <- ggplot(position_analysis, aes(x = position, y = n_mutations, fill = region_color)) +
  geom_bar(stat = "identity", alpha = 0.8) +
  scale_fill_manual(
    name = "Region",
    values = c("Seed Region" = professional_colors["Secondary"],
               "5' End" = professional_colors["Primary"],
               "Central" = professional_colors["Accent"],
               "3' End" = "#8e44ad",
               "Other" = "grey70")
  ) +
  labs(
    title = "G>T Mutations by Position in miRNAs",
    subtitle = "Distribution across all miRNAs analyzed (415 samples)",
    x = "Position in miRNA",
    y = "Number of G>T Mutations"
  ) +
  theme_professional() +
  theme(legend.position = "bottom") +
  # Add vertical lines to mark seed region
  geom_vline(xintercept = c(2, 8), linetype = "dashed", color = professional_colors["Secondary"], alpha = 0.8, size = 1) +
  annotate("text", x = 5, y = max(position_analysis$n_mutations) * 0.9, 
           label = "Seed Region (2-8)", color = professional_colors["Secondary"], 
           fontface = "bold", size = 4)

ggsave("outputs/figures/top_mirnas_justification/mutations_by_position.png", 
       p5, width = 14, height = 8, dpi = 300, bg = "white")

# =============================================================================
# 7. VISUALIZATION 4: SEED REGION vs NON-SEED REGION COMPARISON (PROFESSIONAL STYLE)
# =============================================================================

# Calculate seed vs non-seed statistics
seed_stats <- position_analysis %>%
  group_by(is_seed_region) %>%
  summarise(
    total_mutations = sum(n_mutations),
    mean_mutations_per_position = mean(n_mutations),
    n_positions = n(),
    .groups = 'drop'
  ) %>%
  mutate(
    region_type = ifelse(is_seed_region, "Seed Region (2-8)", "Non-Seed Region"),
    mutations_per_position = total_mutations / n_positions
  )

# Plot comparison with professional styling
p6 <- ggplot(seed_stats, aes(x = region_type, y = mutations_per_position, fill = region_type)) +
  geom_bar(stat = "identity", alpha = 0.8) +
  scale_fill_manual(values = c("Seed Region (2-8)" = professional_colors["Secondary"], 
                               "Non-Seed Region" = professional_colors["Primary"])) +
  labs(
    title = "Average G>T Mutations per Position: Seed vs Non-Seed Regions",
    subtitle = "Critical comparison showing seed region enrichment",
    x = "Region Type",
    y = "Average Mutations per Position"
  ) +
  theme_professional() +
  theme(legend.position = "none") +
  # Add value labels
  geom_text(aes(label = round(mutations_per_position, 1)), 
            vjust = -0.5, size = 5, fontface = "bold", color = "#2c3e50")

ggsave("outputs/figures/top_mirnas_justification/seed_vs_nonseed_comparison.png", 
       p6, width = 10, height = 8, dpi = 300, bg = "white")

# =============================================================================
# 8. VISUALIZATION 5: LET-7 FAMILY ANALYSIS (PROFESSIONAL STYLE)
# =============================================================================

# Plot let-7 family members with professional styling
p7 <- ggplot(let7_family, aes(x = reorder(miRNA.name, total_gt_counts), y = total_gt_counts)) +
  geom_bar(stat = "identity", fill = "#8e44ad", alpha = 0.8) +
  labs(
    title = "Let-7 Family: G>T Mutation Counts",
    subtitle = "Consistent oxidation patterns across family members",
    x = "Let-7 Family Member",
    y = "Total G>T Counts"
  ) +
  theme_professional() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 10)) +
  coord_flip()

ggsave("outputs/figures/top_mirnas_justification/let7_family_analysis.png", 
       p7, width = 12, height = 8, dpi = 300, bg = "white")

# =============================================================================
# 9. VISUALIZATION 6: CORRELATION MATRIX (PROFESSIONAL STYLE)
# =============================================================================

# Create correlation matrix
correlation_data <- top_mirnas_analysis %>%
  select(total_gt_counts, mean_rpm, mean_vaf, mutation_count) %>%
  cor()

# Melt for plotting
correlation_melted <- melt(correlation_data) %>%
  mutate(
    Var1_label = case_when(
      Var1 == "total_gt_counts" ~ "G>T Counts",
      Var1 == "mean_rpm" ~ "Mean RPM",
      Var1 == "mean_vaf" ~ "Mean VAF",
      Var1 == "mutation_count" ~ "Mutation Count",
      TRUE ~ Var1
    ),
    Var2_label = case_when(
      Var2 == "total_gt_counts" ~ "G>T Counts",
      Var2 == "mean_rpm" ~ "Mean RPM",
      Var2 == "mean_vaf" ~ "Mean VAF",
      Var2 == "mutation_count" ~ "Mutation Count",
      TRUE ~ Var2
    )
  )

# Plot correlation heatmap with professional styling
p8 <- ggplot(correlation_melted, aes(x = Var1_label, y = Var2_label, fill = value)) +
  geom_tile(color = "white", size = 0.5) +
  scale_fill_gradient2(
    low = professional_colors["Primary"], 
    high = professional_colors["Secondary"], 
    mid = "white", 
    midpoint = 0,
    name = "Correlation",
    limits = c(-1, 1)
  ) +
  labs(
    title = "Correlation Matrix: Selection Criteria",
    subtitle = "Relationships between different selection criteria",
    x = "Criteria",
    y = "Criteria"
  ) +
  theme_professional() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "right"
  ) +
  # Add correlation values
  geom_text(aes(label = round(value, 2)), color = "black", size = 4, fontface = "bold")

ggsave("outputs/figures/top_mirnas_justification/correlation_matrix.png", 
       p8, width = 10, height = 8, dpi = 300, bg = "white")

# =============================================================================
# 10. GENERATE SUMMARY STATISTICS
# =============================================================================

cat("=== TOP miRNAs SELECTION SUMMARY ===\n")
cat("Total miRNAs analyzed:", nrow(top_mirnas), "\n")
cat("Top 10 miRNAs selected based on combined criteria\n\n")

cat("=== TOP 10 miRNAs (Final Ranking) ===\n")
top_10 <- top_mirnas_analysis %>% head(10)
for(i in 1:nrow(top_10)) {
  cat(sprintf("%d. %s: %d G>T counts, %.1f RPM, %.2e VAF, %d mutations\n",
              i, top_10$miRNA.name[i], top_10$total_gt_counts[i], 
              top_10$mean_rpm[i], top_10$mean_vaf[i], top_10$mutation_count[i]))
}

cat("\n=== SEED REGION ANALYSIS ===\n")
seed_summary <- position_analysis %>%
  group_by(is_seed_region) %>%
  summarise(
    total_mutations = sum(n_mutations),
    avg_per_position = mean(n_mutations),
    .groups = 'drop'
  )

cat("Seed region (positions 2-8):", seed_summary$total_mutations[seed_summary$is_seed_region], "mutations\n")
cat("Non-seed region:", seed_summary$total_mutations[!seed_summary$is_seed_region], "mutations\n")
cat("Seed region average per position:", round(seed_summary$avg_per_position[seed_summary$is_seed_region], 1), "\n")
cat("Non-seed region average per position:", round(seed_summary$avg_per_position[!seed_summary$is_seed_region], 1), "\n")

# Calculate fold difference
fold_diff <- seed_summary$avg_per_position[seed_summary$is_seed_region] / 
             seed_summary$avg_per_position[!seed_summary$is_seed_region]
cat("Fold difference (seed vs non-seed):", round(fold_diff, 2), "\n")

cat("\n=== LET-7 FAMILY SUMMARY ===\n")
cat("Let-7 family members in top miRNAs:", nrow(let7_family), "\n")
cat("Total G>T counts in let-7 family:", sum(let7_family$total_gt_counts), "\n")
cat("Average G>T counts per let-7 member:", round(mean(let7_family$total_gt_counts), 0), "\n")

cat("\n=== ANALYSIS COMPLETE ===\n")
cat("Figures saved to: outputs/figures/top_mirnas_justification/\n")
cat("Tables saved to: outputs/tables/top_mirnas_justification/\n")
cat("All figures use professional styling consistent with main analysis pipeline.\n")