# Top 10% miRNAs Analysis - Clean and Statistical Approach
# Focus on SNVs for clustering by position

library(ggplot2)
library(dplyr)
library(readr)
library(gridExtra)
library(RColorBrewer)
library(reshape2)
library(ComplexHeatmap)
library(circlize)
library(tibble)

# Set working directory
setwd("/Users/cesaresparza/New_Desktop/UCSD/8OG")

# Read data
top_mirnas <- read_tsv("outputs/simple_final_top_mirnas.tsv")
position_stats <- read_csv("outputs/tables/positional_analysis/position_statistics.csv")

# Calculate top 10% (5 miRNAs from 50)
n_mirnas <- nrow(top_mirnas)
top_10_percent <- ceiling(n_mirnas * 0.1)  # 5 miRNAs

cat("📊 ANALYSIS OVERVIEW\n")
cat("===================\n")
cat("Total miRNAs analyzed:", n_mirnas, "\n")
cat("Top 10% selection:", top_10_percent, "miRNAs\n")
cat("Sample size: 415 samples (313 ALS + 102 Control)\n\n")

# Define selection criteria with clear explanations
cat("🎯 SELECTION CRITERIA EXPLANATIONS\n")
cat("===================================\n")
cat("1. G>T Counts: Total number of G>T mutations (direct measure of oxidative damage)\n")
cat("2. Mean RPM: Reads Per Million (expression level normalization)\n")
cat("3. Mean VAF: Variant Allele Frequency (mutation penetrance)\n")
cat("4. Mutation Count: Number of different mutation types (diversity)\n\n")

# Select top 10% by G>T counts (primary criterion)
top_10_mirnas <- top_mirnas %>%
  arrange(desc(total_gt_counts)) %>%
  slice_head(n = top_10_percent) %>%
  mutate(
    rank = row_number(),
    percentile = "Top 10%"
  )

cat("🏆 TOP 10% miRNAs (by G>T counts)\n")
cat("=================================\n")
print(top_10_mirnas %>% select(rank, miRNA.name, total_gt_counts, mean_rpm, mean_vaf, mutation_count))

# Create clean, professional visualizations
output_dir <- "outputs/figures/top_10_percent_analysis"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# 1. Top 10% miRNAs Bar Chart (Clean)
p1 <- ggplot(top_10_mirnas, aes(x = reorder(miRNA.name, total_gt_counts), y = total_gt_counts)) +
  geom_col(fill = "#2E86AB", alpha = 0.8) +
  geom_text(aes(label = total_gt_counts), hjust = -0.1, size = 3.5, fontface = "bold") +
  coord_flip() +
  labs(
    title = "Top 10% miRNAs by G>T Mutation Counts",
    subtitle = paste("Top", top_10_percent, "miRNAs from", n_mirnas, "total miRNAs analyzed"),
    x = "miRNA",
    y = "Total G>T Counts",
    caption = "Primary selection criterion: Total G>T mutations (oxidative damage measure)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 12, color = "gray60"),
    axis.text = element_text(size = 10),
    axis.title = element_text(size = 11, face = "bold"),
    plot.caption = element_text(size = 9, color = "gray50", hjust = 0)
  )

ggsave(file.path(output_dir, "top_10_percent_mirnas.png"), p1, width = 10, height = 6, dpi = 300)

# 2. Criteria Comparison (Clean Heatmap)
criteria_data <- top_10_mirnas %>%
  select(miRNA.name, total_gt_counts, mean_rpm, mean_vaf, mutation_count) %>%
  mutate(
    # Normalize for comparison (0-1 scale)
    gt_counts_norm = (total_gt_counts - min(total_gt_counts)) / (max(total_gt_counts) - min(total_gt_counts)),
    rpm_norm = (mean_rpm - min(mean_rpm)) / (max(mean_rpm) - min(mean_rpm)),
    vaf_norm = (mean_vaf - min(mean_vaf)) / (max(mean_vaf) - min(mean_vaf)),
    mut_count_norm = (mutation_count - min(mutation_count)) / (max(mutation_count) - min(mutation_count))
  ) %>%
  select(miRNA.name, gt_counts_norm, rpm_norm, vaf_norm, mut_count_norm) %>%
  column_to_rownames("miRNA.name")

# Create clean heatmap
col_fun <- colorRamp2(c(0, 0.5, 1), c("#E8F4FD", "#2E86AB", "#1B4F72"))
colnames(criteria_data) <- c("G>T Counts", "Mean RPM", "Mean VAF", "Mutation Count")

ht <- Heatmap(
  as.matrix(criteria_data),
  name = "Normalized\nScore",
  col = col_fun,
  cluster_rows = TRUE,
  cluster_columns = FALSE,
  show_row_names = TRUE,
  show_column_names = TRUE,
  row_names_gp = gpar(fontsize = 10),
  column_names_gp = gpar(fontsize = 11, fontface = "bold"),
  heatmap_legend_param = list(
    title = "Normalized Score",
    title_gp = gpar(fontsize = 10, fontface = "bold"),
    labels_gp = gpar(fontsize = 9)
  ),
  column_title = "Selection Criteria Comparison (Top 10% miRNAs)",
  column_title_gp = gpar(fontsize = 12, fontface = "bold")
)

png(file.path(output_dir, "criteria_comparison_heatmap.png"), width = 800, height = 600, res = 300)
draw(ht)
dev.off()

# 3. Position Analysis (General - not miRNA-specific)
# Use general position statistics
position_analysis <- position_stats %>%
  mutate(
    region = case_when(
      position >= 2 & position <= 8 ~ "Seed Region",
      position >= 9 & position <= 15 ~ "Central Region", 
      TRUE ~ "Other Region"
    )
  )

# Position distribution plot
p3 <- ggplot(position_analysis, aes(x = position, y = n_mutations, fill = region)) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = n_mutations), vjust = -0.5, size = 3, fontface = "bold") +
  scale_fill_manual(values = c("Seed Region" = "#E74C3C", "Central Region" = "#F39C12", "Other Region" = "#95A5A6")) +
  scale_x_continuous(breaks = 1:22) +
  labs(
    title = "G>T Mutations by Position (All miRNAs)",
    subtitle = "Distribution across all 50 miRNAs analyzed",
    x = "miRNA Position",
    y = "Total G>T Mutations",
    fill = "Region",
    caption = "Seed region (positions 2-8) critical for target recognition"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 12, color = "gray60"),
    axis.text = element_text(size = 10),
    axis.title = element_text(size = 11, face = "bold"),
    legend.position = "bottom",
    legend.title = element_text(size = 10, face = "bold"),
    plot.caption = element_text(size = 9, color = "gray50", hjust = 0)
  )

ggsave(file.path(output_dir, "position_distribution_top10.png"), p3, width = 12, height = 6, dpi = 300)

# 4. Summary Statistics Table
summary_stats <- top_10_mirnas %>%
  summarise(
    total_gt_mutations = sum(total_gt_counts),
    avg_gt_per_mirna = mean(total_gt_counts),
    median_gt_per_mirna = median(total_gt_counts),
    total_rpm = sum(mean_rpm),
    avg_vaf = mean(mean_vaf),
    total_mutation_types = sum(mutation_count)
  ) %>%
  mutate(
    percentage_of_total = round((total_gt_mutations / sum(top_mirnas$total_gt_counts)) * 100, 1)
  )

cat("\n📈 TOP 10% SUMMARY STATISTICS\n")
cat("==============================\n")
cat("Total G>T mutations in top 10%:", summary_stats$total_gt_mutations, "\n")
cat("Percentage of all G>T mutations:", summary_stats$percentage_of_total, "%\n")
cat("Average G>T per miRNA:", round(summary_stats$avg_gt_per_mirna, 0), "\n")
cat("Median G>T per miRNA:", summary_stats$median_gt_per_mirna, "\n")
cat("Average VAF:", format(summary_stats$avg_vaf, scientific = TRUE), "\n")

# 5. SNVs for Clustering Analysis
# Create SNV matrix for top 10% miRNAs (this will be used for clustering)
snv_summary <- top_10_mirnas %>%
  select(miRNA.name, total_gt_counts, mean_vaf) %>%
  mutate(
    snv_id = paste0(miRNA.name, "_GT"),
    cluster_group = "Top10%"
  ) %>%
  arrange(desc(total_gt_counts))

# Save SNV data for clustering
write_tsv(snv_summary, file.path(output_dir, "top_10_percent_snvs_for_clustering.tsv"))

cat("\n🎯 SNVs FOR CLUSTERING ANALYSIS\n")
cat("===============================\n")
cat("SNVs prepared for clustering:", nrow(snv_summary), "\n")
cat("File saved:", file.path(output_dir, "top_10_percent_snvs_for_clustering.tsv"), "\n")

# 6. Create comprehensive summary
cat("\n✅ ANALYSIS COMPLETE\n")
cat("===================\n")
cat("Generated files:\n")
cat("- top_10_percent_mirnas.png: Bar chart of top miRNAs\n")
cat("- criteria_comparison_heatmap.png: Criteria comparison heatmap\n")
cat("- position_distribution_top10.png: Position analysis\n")
cat("- top_10_percent_snvs_for_clustering.tsv: SNV data for clustering\n")

cat("\n🎯 NEXT STEPS FOR CLUSTERING\n")
cat("============================\n")
cat("1. Use SNV data to perform hierarchical clustering\n")
cat("2. Analyze cluster patterns by position\n")
cat("3. Identify position-specific mutation hotspots\n")
cat("4. Compare clustering patterns between ALS and Control groups\n")

# Save summary report
summary_report <- paste0(
  "# Top 10% miRNAs Analysis Summary\n\n",
  "## Selection Criteria\n",
  "- **G>T Counts**: Total number of G>T mutations (primary criterion)\n",
  "- **Mean RPM**: Reads Per Million (expression normalization)\n", 
  "- **Mean VAF**: Variant Allele Frequency (mutation penetrance)\n",
  "- **Mutation Count**: Number of different mutation types (diversity)\n\n",
  "## Top 10% miRNAs Selected\n",
  paste0(1:top_10_percent, ". ", top_10_mirnas$miRNA.name, collapse = "\n"), "\n\n",
  "## Key Statistics\n",
  "- Total miRNAs analyzed: ", n_mirnas, "\n",
  "- Top 10% selected: ", top_10_percent, " miRNAs\n",
  "- Total G>T mutations in top 10%: ", summary_stats$total_gt_mutations, "\n",
  "- Percentage of all mutations: ", summary_stats$percentage_of_total, "%\n\n",
  "## SNVs Prepared for Clustering\n",
  "- SNV count: ", nrow(snv_summary), "\n",
  "- Ready for position-based clustering analysis\n"
)

writeLines(summary_report, file.path(output_dir, "analysis_summary.md"))

cat("\n📄 Summary report saved: analysis_summary.md\n")
