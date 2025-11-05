#!/usr/bin/env Rscript

# SEED REGION HEATMAP ANALYSIS
# Focus on mutations in seed region (positions 2-8) of top miRNAs

library(dplyr)
library(stringr)
library(readr)
library(tidyr)
library(tibble)
library(ggplot2)
library(pheatmap)
library(RColorBrewer)
library(viridis)

cat("🌱 SEED REGION HEATMAP ANALYSIS\n")
cat("===============================\n\n")

# 1. Load data
cat("📊 STEP 1: Loading data...\n")
df <- read_tsv("results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt", show_col_types = FALSE)
cat("   - Total rows:", nrow(df), "\n")
cat("   - Total unique miRNAs:", length(unique(df$`miRNA name`)), "\n\n")

# 2. Load top miRNAs list
cat("📊 STEP 2: Loading top miRNAs list...\n")
top_mirnas <- readLines("outputs/rpm_based_top_mirna_list.txt")
cat("   - Top miRNAs loaded:", length(top_mirnas), "\n\n")

# 3. Identify columns
cat("📊 STEP 3: Identifying column types...\n")
meta_cols <- c("miRNA name", "pos:mut")
all_cols <- colnames(df)
total_cols <- all_cols[str_detect(all_cols, "\\(PM\\+1MM\\+2MM\\)")]
snv_cols <- setdiff(all_cols, c(meta_cols, total_cols))

cat("   - Meta columns:", length(meta_cols), "\n")
cat("   - SNV columns:", length(snv_cols), "\n")
cat("   - Total columns:", length(total_cols), "\n\n")

# 4. Filter for top miRNAs and G>T mutations
cat("📊 STEP 4: Filtering for top miRNAs and G>T mutations...\n")
df_gt <- df %>%
  filter(`miRNA name` %in% top_mirnas) %>%
  filter(str_detect(`pos:mut`, ":GT"))

cat("   - G>T mutations in top miRNAs:", nrow(df_gt), "\n")
cat("   - Unique miRNAs with G>T:", length(unique(df_gt$`miRNA name`)), "\n\n")

# 5. Extract position information and filter for seed region
cat("📊 STEP 5: Filtering for seed region mutations (positions 2-8)...\n")

# Extract position from pos:mut column
df_gt <- df_gt %>%
  mutate(
    position = as.numeric(str_extract(`pos:mut`, "^\\d+")),
    mutation = str_extract(`pos:mut`, ":\\w+$")
  )

# Filter for seed region (positions 2-8)
df_seed <- df_gt %>%
  filter(position >= 2 & position <= 8)

cat("   - Seed region mutations:", nrow(df_seed), "\n")
cat("   - Unique miRNAs with seed mutations:", length(unique(df_seed$`miRNA name`)), "\n")
cat("   - Position range in seed region:", range(df_seed$position, na.rm = TRUE), "\n\n")

# 6. Calculate VAFs for seed region
cat("📊 STEP 6: Calculating VAFs for seed region...\n")
snv_mat <- as.matrix(df_seed[, snv_cols])
total_mat <- as.matrix(df_seed[, total_cols])
colnames(total_mat) <- str_replace(colnames(total_mat), " \\(PM\\+1MM\\+2MM\\)", "")

vaf_mat <- snv_mat / (total_mat + 1e-10)
colnames(vaf_mat) <- str_replace(colnames(vaf_mat), "Magen-ALS-enrolment-bloodplasma-", "")

cat("   - VAF matrix dimensions:", dim(vaf_mat), "\n")
cat("   - VAF range:", round(range(vaf_mat, na.rm = TRUE), 4), "\n\n")

# 7. Filter SNVs with VAF > 50%
cat("📊 STEP 7: Filtering SNVs with VAF > 50%...\n")
high_vaf_idx <- apply(vaf_mat > 0.5, 1, any, na.rm = TRUE)
df_seed_clean <- df_seed[!high_vaf_idx, ]
vaf_seed_clean <- vaf_mat[!high_vaf_idx, ]

cat("   - SNVs removed (VAF > 50%):", sum(high_vaf_idx), "\n")
cat("   - Rows after VAF filtering:", nrow(df_seed_clean), "\n")
cat("   - Unique miRNAs after filtering:", length(unique(df_seed_clean$`miRNA name`)), "\n\n")

# 8. Select most interesting SNVs for heatmap
cat("📊 STEP 8: Selecting most interesting seed region SNVs...\n")

# Calculate average VAF per SNV
snv_avg_vaf <- rowMeans(vaf_seed_clean, na.rm = TRUE)
snv_vaf_df <- data.frame(
  snv_id = paste(df_seed_clean$`miRNA name`, df_seed_clean$`pos:mut`, sep = "_"),
  position = df_seed_clean$position,
  avg_vaf = snv_avg_vaf,
  max_vaf = apply(vaf_seed_clean, 1, max, na.rm = TRUE),
  n_samples = apply(vaf_seed_clean > 0, 1, sum, na.rm = TRUE)
)

# Select top SNVs by average VAF (all available or max 50 for seed region)
max_snvs_seed <- min(50, nrow(snv_vaf_df))
top_snvs_seed <- snv_vaf_df %>%
  arrange(desc(avg_vaf)) %>%
  head(max_snvs_seed)

cat("   - Seed region SNVs selected:", nrow(top_snvs_seed), "\n")
cat("   - VAF range in selected SNVs:", round(range(top_snvs_seed$avg_vaf), 4), "\n\n")

# 9. Create final VAF matrix for heatmap
cat("📊 STEP 9: Creating final seed region VAF matrix...\n")
top_snv_indices <- which(paste(df_seed_clean$`miRNA name`, df_seed_clean$`pos:mut`, sep = "_") %in% top_snvs_seed$snv_id)
vaf_heatmap_seed <- vaf_seed_clean[top_snv_indices, ]

# Clean up row names
rownames(vaf_heatmap_seed) <- str_replace(rownames(vaf_heatmap_seed), "Magen-ALS-enrolment-bloodplasma-", "")

cat("   - Heatmap matrix dimensions:", dim(vaf_heatmap_seed), "\n")
cat("   - Samples in heatmap:", ncol(vaf_heatmap_seed), "\n\n")

# 10. Create sample annotation (ALS vs Control)
cat("📊 STEP 10: Creating sample annotations...\n")
sample_names <- colnames(vaf_heatmap_seed)

# Determine sample groups based on naming pattern
sample_groups <- ifelse(
  str_detect(sample_names, "control|Control|CTRL|ctrl"),
  "Control",
  "ALS"
)

# Create annotation data frame
sample_annotation <- data.frame(
  Group = sample_groups,
  row.names = sample_names
)

# Count samples by group
group_counts <- table(sample_groups)
cat("   - Sample groups:\n")
for (group in names(group_counts)) {
  cat("     -", group, ":", group_counts[group], "samples\n")
}
cat("\n")

# 11. Create seed region heatmap
cat("📊 STEP 11: Creating seed region heatmap...\n")
dir.create("outputs/figures/seed_region_heatmap", showWarnings = FALSE, recursive = TRUE)

# Define color palette (white to red)
color_palette <- colorRampPalette(c("white", "lightpink", "red", "darkred"))(100)

# Create heatmap
png("outputs/figures/seed_region_heatmap/seed_region_vaf_heatmap.png", 
    width = 1400, height = 1000, res = 150)

pheatmap(
  vaf_heatmap_seed,
  clustering_distance_rows = "euclidean",
  clustering_distance_cols = "euclidean", 
  clustering_method = "ward.D2",
  color = color_palette,
  annotation_col = sample_annotation,
  annotation_colors = list(Group = c("ALS" = "#E31A1C", "Control" = "#1F78B4")),
  show_rownames = FALSE,
  show_colnames = FALSE,
  main = "Seed Region G>T Mutation VAF Heatmap\n(Top miRNAs by RPM, Positions 2-8)",
  fontsize = 12,
  fontsize_main = 16,
  border_color = NA,
  gaps_col = NULL,
  cluster_rows = TRUE,
  cluster_cols = TRUE,
  scale = "none",
  breaks = seq(0, max(vaf_heatmap_seed, na.rm = TRUE), length.out = 101),
  legend_breaks = c(0, 0.1, 0.2, 0.3, 0.4, 0.5),
  legend_labels = c("0.0", "0.1", "0.2", "0.3", "0.4", "0.5"),
  legend_title = "VAF"
)

dev.off()

# 12. Create additional visualizations
cat("📊 STEP 12: Creating additional visualizations...\n")

# 12.1 VAF distribution
p1 <- ggplot(data.frame(vaf = as.vector(vaf_heatmap_seed)), aes(x = vaf)) +
  geom_histogram(bins = 30, alpha = 0.7, fill = "darkgreen", color = "white") +
  labs(
    title = "Seed Region VAF Distribution",
    x = "Variant Allele Frequency (VAF)",
    y = "Count"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    axis.title = element_text(size = 12)
  )

ggsave("outputs/figures/seed_region_heatmap/seed_vaf_distribution.png", p1, 
       width = 10, height = 6, dpi = 300)

# 12.2 Sample group comparison
group_vaf_seed <- data.frame(
  vaf = as.vector(vaf_heatmap_seed),
  group = rep(sample_groups, each = nrow(vaf_heatmap_seed))
)

p2 <- ggplot(group_vaf_seed, aes(x = group, y = vaf, fill = group)) +
  geom_boxplot(alpha = 0.7) +
  scale_fill_manual(values = c("ALS" = "#E31A1C", "Control" = "#1F78B4")) +
  labs(
    title = "Seed Region VAF Distribution by Sample Group",
    x = "Sample Group",
    y = "Variant Allele Frequency (VAF)",
    fill = "Group"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    axis.title = element_text(size = 12),
    legend.position = "bottom"
  )

ggsave("outputs/figures/seed_region_heatmap/seed_group_comparison.png", p2, 
       width = 10, height = 6, dpi = 300)

# 12.3 Top SNVs by VAF
top_snvs_plot_seed <- top_snvs_seed %>%
  head(20) %>%
  mutate(snv_id = str_replace(snv_id, "_", "\n"))

p3 <- ggplot(top_snvs_plot_seed, aes(x = reorder(snv_id, avg_vaf), y = avg_vaf)) +
  geom_col(fill = "darkgreen", alpha = 0.7) +
  coord_flip() +
  labs(
    title = "Top 20 Seed Region SNVs by Average VAF",
    x = "SNV (miRNA_Position:Mutation)",
    y = "Average VAF"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    axis.title = element_text(size = 12),
    axis.text.y = element_text(size = 8)
  )

ggsave("outputs/figures/seed_region_heatmap/seed_top_snvs.png", p3, 
       width = 12, height = 8, dpi = 300)

# 12.4 Position distribution
p4 <- ggplot(df_seed_clean, aes(x = position)) +
  geom_histogram(bins = 7, alpha = 0.7, fill = "darkgreen", color = "white") +
  scale_x_continuous(breaks = 2:8) +
  labs(
    title = "Distribution of Mutations by Seed Region Position",
    x = "Position in Seed Region (2-8)",
    y = "Number of Mutations"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    axis.title = element_text(size = 12)
  )

ggsave("outputs/figures/seed_region_heatmap/position_distribution.png", p4, 
       width = 10, height = 6, dpi = 300)

# 13. Statistical comparison
cat("📊 STEP 13: Performing statistical comparison...\n")

# Compare VAF between groups
als_vaf <- group_vaf_seed$vaf[group_vaf_seed$group == "ALS"]
control_vaf <- group_vaf_seed$vaf[group_vaf_seed$group == "Control"]

# Perform t-test
t_test_result <- t.test(als_vaf, control_vaf)
wilcox_result <- wilcox.test(als_vaf, control_vaf)

cat("   - T-test p-value:", round(t_test_result$p.value, 6), "\n")
cat("   - Wilcoxon p-value:", round(wilcox_result$p.value, 6), "\n")
cat("   - Mean VAF ALS:", round(mean(als_vaf, na.rm = TRUE), 4), "\n")
cat("   - Mean VAF Control:", round(mean(control_vaf, na.rm = TRUE), 4), "\n\n")

# 14. Save results
cat("📊 STEP 14: Saving results...\n")

# Save VAF matrix
write_tsv(
  as.data.frame(vaf_heatmap_seed) %>% rownames_to_column("snv_id"),
  "outputs/seed_region_vaf_matrix.tsv"
)

# Save sample annotation
write_tsv(
  sample_annotation %>% rownames_to_column("sample_id"),
  "outputs/seed_region_sample_annotation.tsv"
)

# Save top SNVs info
write_tsv(top_snvs_seed, "outputs/seed_region_top_snvs.tsv")

# Save position analysis
position_summary <- df_seed_clean %>%
  group_by(position) %>%
  summarise(
    n_mutations = n(),
    mean_vaf = mean(rowMeans(vaf_seed_clean[df_seed_clean$position == position, ], na.rm = TRUE), na.rm = TRUE),
    .groups = 'drop'
  )

write_tsv(position_summary, "outputs/seed_region_position_summary.tsv")

# 15. Create report
cat("📊 STEP 15: Creating report...\n")
report_content <- paste0(
  "# SEED REGION HEATMAP ANALYSIS REPORT\n\n",
  "**Date:** ", Sys.Date(), "\n",
  "**Data file:** results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt\n",
  "**Focus:** Seed region mutations (positions 2-8)\n",
  "**Top miRNAs:** ", length(top_mirnas), " miRNAs selected by RPM\n\n",
  
  "## ANALYSIS SUMMARY\n\n",
  "- **Total G>T mutations in top miRNAs:** ", nrow(df_gt), "\n",
  "- **Seed region mutations:** ", nrow(df_seed), "\n",
  "- **SNVs after VAF filtering:** ", nrow(df_seed_clean), "\n",
  "- **SNVs selected for heatmap:** ", nrow(vaf_heatmap_seed), "\n",
  "- **Samples in heatmap:** ", ncol(vaf_heatmap_seed), "\n",
  "- **Position range:** 2-8 (seed region)\n\n",
  
  "## SAMPLE GROUPS\n\n",
  paste(sapply(names(group_counts), function(group) {
    paste0("- **", group, ":** ", group_counts[group], " samples")
  }), collapse = "\n"), "\n\n",
  
  "## STATISTICAL COMPARISON\n\n",
  "- **T-test p-value:** ", round(t_test_result$p.value, 6), "\n",
  "- **Wilcoxon p-value:** ", round(wilcox_result$p.value, 6), "\n",
  "- **Mean VAF ALS:** ", round(mean(als_vaf, na.rm = TRUE), 4), "\n",
  "- **Mean VAF Control:** ", round(mean(control_vaf, na.rm = TRUE), 4), "\n\n",
  
  "## TOP SEED REGION SNVs\n\n",
  "| Rank | SNV | Position | Avg VAF | Max VAF | Samples |\n",
  "|------|-----|----------|---------|---------|----------|\n",
  paste(apply(head(top_snvs_seed, 10), 1, function(x) {
    paste0("| ", which(top_snvs_seed$snv_id == x[1]), " | ", x[1], " | ", x[2], " | ", 
           round(as.numeric(x[3]), 4), " | ", round(as.numeric(x[4]), 4), " | ", x[5], " |")
  }), collapse = "\n"), "\n\n",
  
  "## POSITION ANALYSIS\n\n",
  "| Position | Mutations | Mean VAF |\n",
  "|----------|-----------|----------|\n",
  paste(apply(position_summary, 1, function(x) {
    paste0("| ", x[1], " | ", x[2], " | ", round(x[3], 4), " |")
  }), collapse = "\n"), "\n\n",
  
  "## FILES GENERATED\n\n",
  "- `seed_region_vaf_heatmap.png`: Main heatmap visualization\n",
  "- `seed_vaf_distribution.png`: VAF distribution histogram\n",
  "- `seed_group_comparison.png`: Box plot comparison by group\n",
  "- `seed_top_snvs.png`: Bar plot of top SNVs\n",
  "- `position_distribution.png`: Mutation distribution by position\n",
  "- `seed_region_vaf_matrix.tsv`: VAF matrix data\n",
  "- `seed_region_sample_annotation.tsv`: Sample group annotations\n",
  "- `seed_region_top_snvs.tsv`: Top SNVs information\n",
  "- `seed_region_position_summary.tsv`: Position analysis\n\n",
  
  "## INTERPRETATION\n\n",
  "The seed region heatmap shows G>T mutations in the most functionally important region of miRNAs:\n\n",
  "1. **Functional impact:** Mutations in positions 2-8 directly affect target recognition\n",
  "2. **Sample clusters:** Groups of samples with similar seed region mutation patterns\n",
  "3. **SNV clusters:** Groups of mutations that co-occur in the seed region\n",
  "4. **Group differences:** Visual comparison between ALS and Control samples\n",
  "5. **Position hotspots:** Specific positions with higher mutation frequency\n\n",
  "This analysis is crucial for understanding the functional impact of oxidative damage in miRNA targeting."
)

writeLines(report_content, "outputs/seed_region_heatmap_report.md")

cat("✅ SEED REGION HEATMAP ANALYSIS COMPLETED\n")
cat("=========================================\n\n")
cat("📁 Files generated in outputs/\n")
cat("📊 Visualizations in outputs/figures/seed_region_heatmap/\n")
cat("📋 Report: outputs/seed_region_heatmap_report.md\n\n")
cat("🌱 Seed region features:\n")
cat("   - Positions: 2-8 (seed region)\n")
cat("   - SNVs selected:", nrow(vaf_heatmap_seed), "\n")
cat("   - Samples:", ncol(vaf_heatmap_seed), "\n")
cat("   - Statistical comparison: p =", round(t_test_result$p.value, 4), "\n")











