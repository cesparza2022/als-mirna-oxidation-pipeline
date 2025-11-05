#!/usr/bin/env Rscript

# CLEAN HEATMAP ANALYSIS
# Creates a clean, publication-ready heatmap with clustering

library(dplyr)
library(stringr)
library(readr)
library(tidyr)
library(tibble)
library(ggplot2)
library(pheatmap)
library(RColorBrewer)
library(viridis)

cat("🔥 CLEAN HEATMAP ANALYSIS\n")
cat("========================\n\n")

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
df_filtered <- df %>%
  filter(`miRNA name` %in% top_mirnas) %>%
  filter(str_detect(`pos:mut`, ":GT"))

cat("   - Rows after filtering:", nrow(df_filtered), "\n")
cat("   - Unique miRNAs in filtered data:", length(unique(df_filtered$`miRNA name`)), "\n\n")

# 5. Calculate VAFs
cat("📊 STEP 5: Calculating VAFs...\n")
snv_mat <- as.matrix(df_filtered[, snv_cols])
total_mat <- as.matrix(df_filtered[, total_cols])
colnames(total_mat) <- str_replace(colnames(total_mat), " \\(PM\\+1MM\\+2MM\\)", "")

vaf_mat <- snv_mat / (total_mat + 1e-10)
colnames(vaf_mat) <- str_replace(colnames(vaf_mat), "Magen-ALS-enrolment-bloodplasma-", "")

cat("   - VAF matrix dimensions:", dim(vaf_mat), "\n")
cat("   - VAF range:", round(range(vaf_mat, na.rm = TRUE), 4), "\n\n")

# 6. Filter SNVs with VAF > 50%
cat("📊 STEP 6: Filtering SNVs with VAF > 50%...\n")
high_vaf_idx <- apply(vaf_mat > 0.5, 1, any, na.rm = TRUE)
df_clean <- df_filtered[!high_vaf_idx, ]
vaf_clean <- vaf_mat[!high_vaf_idx, ]

cat("   - SNVs removed (VAF > 50%):", sum(high_vaf_idx), "\n")
cat("   - Rows after VAF filtering:", nrow(df_clean), "\n")
cat("   - Unique miRNAs after filtering:", length(unique(df_clean$`miRNA name`)), "\n\n")

# 7. Select most interesting SNVs
cat("📊 STEP 7: Selecting most interesting SNVs...\n")

# Calculate average VAF per SNV
snv_avg_vaf <- rowMeans(vaf_clean, na.rm = TRUE)
snv_vaf_df <- data.frame(
  snv_id = paste(df_clean$`miRNA name`, df_clean$`pos:mut`, sep = "_"),
  avg_vaf = snv_avg_vaf,
  max_vaf = apply(vaf_clean, 1, max, na.rm = TRUE),
  n_samples = apply(vaf_clean > 0, 1, sum, na.rm = TRUE)
)

# Select top SNVs by average VAF (top 20% or max 100)
top_snv_percent <- 0.20
max_snvs <- 100
n_top_snvs <- min(max_snvs, max(1, floor(nrow(snv_vaf_df) * top_snv_percent)))

top_snvs <- snv_vaf_df %>%
  arrange(desc(avg_vaf)) %>%
  head(n_top_snvs)

cat("   - Top SNVs selected:", nrow(top_snvs), "\n")
cat("   - VAF range in top SNVs:", round(range(top_snvs$avg_vaf), 4), "\n\n")

# 8. Create final VAF matrix for heatmap
cat("📊 STEP 8: Creating final VAF matrix...\n")
top_snv_indices <- which(paste(df_clean$`miRNA name`, df_clean$`pos:mut`, sep = "_") %in% top_snvs$snv_id)
vaf_heatmap <- vaf_clean[top_snv_indices, ]

# Clean up row names
rownames(vaf_heatmap) <- str_replace(rownames(vaf_heatmap), "Magen-ALS-enrolment-bloodplasma-", "")

cat("   - Heatmap matrix dimensions:", dim(vaf_heatmap), "\n")
cat("   - Samples in heatmap:", ncol(vaf_heatmap), "\n\n")

# 9. Create sample annotation (ALS vs Control)
cat("📊 STEP 9: Creating sample annotations...\n")
sample_names <- colnames(vaf_heatmap)

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

# 10. Create heatmap
cat("📊 STEP 10: Creating clean heatmap...\n")
dir.create("outputs/figures/clean_heatmap", showWarnings = FALSE, recursive = TRUE)

# Define color palette (white to red)
color_palette <- colorRampPalette(c("white", "lightpink", "red", "darkred"))(100)

# Create heatmap
png("outputs/figures/clean_heatmap/clean_vaf_heatmap.png", 
    width = 1400, height = 1000, res = 150)

pheatmap(
  vaf_heatmap,
  clustering_distance_rows = "euclidean",
  clustering_distance_cols = "euclidean", 
  clustering_method = "ward.D2",
  color = color_palette,
  annotation_col = sample_annotation,
  annotation_colors = list(Group = c("ALS" = "#E31A1C", "Control" = "#1F78B4")),
  show_rownames = FALSE,
  show_colnames = FALSE,
  main = "G>T Mutation VAF Heatmap\n(Top miRNAs by RPM)",
  fontsize = 12,
  fontsize_main = 16,
  border_color = NA,
  gaps_col = NULL,
  cluster_rows = TRUE,
  cluster_cols = TRUE,
  scale = "none",
  breaks = seq(0, max(vaf_heatmap, na.rm = TRUE), length.out = 101),
  legend_breaks = c(0, 0.1, 0.2, 0.3, 0.4, 0.5),
  legend_labels = c("0.0", "0.1", "0.2", "0.3", "0.4", "0.5"),
  legend_title = "VAF"
)

dev.off()

# 11. Create additional visualizations
cat("📊 STEP 11: Creating additional visualizations...\n")

# 11.1 VAF distribution
p1 <- ggplot(data.frame(vaf = as.vector(vaf_heatmap)), aes(x = vaf)) +
  geom_histogram(bins = 50, alpha = 0.7, fill = "lightcoral", color = "white") +
  labs(
    title = "VAF Distribution in Heatmap",
    x = "Variant Allele Frequency (VAF)",
    y = "Count"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    axis.title = element_text(size = 12)
  )

ggsave("outputs/figures/clean_heatmap/vaf_distribution.png", p1, 
       width = 10, height = 6, dpi = 300)

# 11.2 Sample group comparison
group_vaf <- data.frame(
  vaf = as.vector(vaf_heatmap),
  group = rep(sample_groups, each = nrow(vaf_heatmap))
)

p2 <- ggplot(group_vaf, aes(x = group, y = vaf, fill = group)) +
  geom_boxplot(alpha = 0.7) +
  scale_fill_manual(values = c("ALS" = "#E31A1C", "Control" = "#1F78B4")) +
  labs(
    title = "VAF Distribution by Sample Group",
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

ggsave("outputs/figures/clean_heatmap/group_comparison.png", p2, 
       width = 10, height = 6, dpi = 300)

# 11.3 Top SNVs by VAF
top_snvs_plot <- top_snvs %>%
  head(20) %>%
  mutate(snv_id = str_replace(snv_id, "_", "\n"))

p3 <- ggplot(top_snvs_plot, aes(x = reorder(snv_id, avg_vaf), y = avg_vaf)) +
  geom_col(fill = "darkred", alpha = 0.7) +
  coord_flip() +
  labs(
    title = "Top 20 SNVs by Average VAF",
    x = "SNV (miRNA_Position:Mutation)",
    y = "Average VAF"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    axis.title = element_text(size = 12),
    axis.text.y = element_text(size = 8)
  )

ggsave("outputs/figures/clean_heatmap/top_snvs.png", p3, 
       width = 12, height = 8, dpi = 300)

# 12. Save results
cat("📊 STEP 12: Saving results...\n")

# Save VAF matrix
write_tsv(
  as.data.frame(vaf_heatmap) %>% rownames_to_column("snv_id"),
  "outputs/clean_heatmap_vaf_matrix.tsv"
)

# Save sample annotation
write_tsv(
  sample_annotation %>% rownames_to_column("sample_id"),
  "outputs/clean_heatmap_sample_annotation.tsv"
)

# Save top SNVs info
write_tsv(top_snvs, "outputs/clean_heatmap_top_snvs.tsv")

# 13. Create report
cat("📊 STEP 13: Creating report...\n")
report_content <- paste0(
  "# CLEAN HEATMAP ANALYSIS REPORT\n\n",
  "**Date:** ", Sys.Date(), "\n",
  "**Data file:** results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt\n",
  "**Top miRNAs:** ", length(top_mirnas), " miRNAs selected by RPM\n\n",
  
  "## ANALYSIS SUMMARY\n\n",
  "- **Total miRNAs in dataset:** ", length(unique(df$`miRNA name`)), "\n",
  "- **Top miRNAs selected:** ", length(top_mirnas), "\n",
  "- **G>T mutations in top miRNAs:** ", nrow(df_filtered), "\n",
  "- **SNVs after VAF filtering:** ", nrow(df_clean), "\n",
  "- **SNVs selected for heatmap:** ", nrow(vaf_heatmap), "\n",
  "- **Samples in heatmap:** ", ncol(vaf_heatmap), "\n\n",
  
  "## SAMPLE GROUPS\n\n",
  paste(sapply(names(group_counts), function(group) {
    paste0("- **", group, ":** ", group_counts[group], " samples")
  }), collapse = "\n"), "\n\n",
  
  "## CLUSTERING METHOD\n\n",
  "**Ward.D2** - Minimizes intra-cluster variance, creating compact clusters ideal for identifying similar mutation patterns.\n\n",
  
  "## HEATMAP FEATURES\n\n",
  "- **Color palette:** White to red (intuitive for VAF)\n",
  "- **VAF scale:** 0.0 to ", round(max(vaf_heatmap, na.rm = TRUE), 2), "\n",
  "- **Sample annotation:** Color-coded by group (ALS vs Control)\n",
  "- **SNV selection:** Top ", nrow(top_snvs), " by average VAF\n",
  "- **Clustering:** Hierarchical clustering on both rows and columns\n\n",
  
  "## FILES GENERATED\n\n",
  "- `clean_vaf_heatmap.png`: Main heatmap visualization\n",
  "- `vaf_distribution.png`: VAF distribution histogram\n",
  "- `group_comparison.png`: Box plot comparison by group\n",
  "- `top_snvs.png`: Bar plot of top SNVs\n",
  "- `clean_heatmap_vaf_matrix.tsv`: VAF matrix data\n",
  "- `clean_heatmap_sample_annotation.tsv`: Sample group annotations\n",
  "- `clean_heatmap_top_snvs.tsv`: Top SNVs information\n\n",
  
  "## INTERPRETATION\n\n",
  "The heatmap shows G>T mutation patterns in the most highly expressed miRNAs. Clustering reveals:\n\n",
  "1. **Sample clusters:** Groups of samples with similar mutation patterns\n",
  "2. **SNV clusters:** Groups of mutations that co-occur\n",
  "3. **Group differences:** Visual comparison between ALS and Control samples\n",
  "4. **Mutation hotspots:** High VAF regions in the heatmap\n\n",
  "This visualization is ideal for identifying patterns of oxidative damage in miRNAs associated with ALS."
)

writeLines(report_content, "outputs/clean_heatmap_report.md")

cat("✅ CLEAN HEATMAP ANALYSIS COMPLETED\n")
cat("===================================\n\n")
cat("📁 Files generated in outputs/\n")
cat("📊 Visualizations in outputs/figures/clean_heatmap/\n")
cat("📋 Report: outputs/clean_heatmap_report.md\n\n")
cat("🔥 Heatmap features:\n")
cat("   - Clustering method: Ward.D2\n")
cat("   - Color palette: White to red\n")
cat("   - Sample groups: Color-coded (ALS vs Control)\n")
cat("   - SNVs selected:", nrow(vaf_heatmap), "\n")
cat("   - Samples:", ncol(vaf_heatmap), "\n")

