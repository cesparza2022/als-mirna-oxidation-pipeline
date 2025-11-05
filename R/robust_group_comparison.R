#!/usr/bin/env Rscript

# ROBUST GROUP COMPARISON ANALYSIS
# Handle extreme fold changes and focus on biologically meaningful differences

library(dplyr)
library(stringr)
library(readr)
library(tidyr)
library(tibble)
library(ggplot2)
library(pheatmap)
library(RColorBrewer)
library(viridis)

cat("🔬 ROBUST GROUP COMPARISON ANALYSIS\n")
cat("==================================\n\n")

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

# 5. Calculate VAFs
cat("📊 STEP 5: Calculating VAFs...\n")
snv_mat <- as.matrix(df_gt[, snv_cols])
total_mat <- as.matrix(df_gt[, total_cols])
colnames(total_mat) <- str_replace(colnames(total_mat), " \\(PM\\+1MM\\+2MM\\)", "")

vaf_mat <- snv_mat / (total_mat + 1e-10)
colnames(vaf_mat) <- str_replace(colnames(vaf_mat), "Magen-ALS-enrolment-bloodplasma-", "")

cat("   - VAF matrix dimensions:", dim(vaf_mat), "\n")
cat("   - VAF range:", round(range(vaf_mat, na.rm = TRUE), 4), "\n\n")

# 6. Filter SNVs with VAF > 50%
cat("📊 STEP 6: Filtering SNVs with VAF > 50%...\n")
high_vaf_idx <- apply(vaf_mat > 0.5, 1, any, na.rm = TRUE)
df_gt_clean <- df_gt[!high_vaf_idx, ]
vaf_clean <- vaf_mat[!high_vaf_idx, ]

cat("   - SNVs removed (VAF > 50%):", sum(high_vaf_idx), "\n")
cat("   - Rows after VAF filtering:", nrow(df_gt_clean), "\n\n")

# 7. Create sample groups
cat("📊 STEP 7: Creating sample groups...\n")
sample_names <- colnames(vaf_clean)
sample_groups <- ifelse(
  str_detect(sample_names, "control|Control|CTRL|ctrl"),
  "Control",
  "ALS"
)

# Count samples by group
group_counts <- table(sample_groups)
cat("   - Sample groups:\n")
for (group in names(group_counts)) {
  cat("     -", group, ":", group_counts[group], "samples\n")
}
cat("\n")

# 8. Robust statistical comparison for each SNV
cat("📊 STEP 8: Performing robust statistical comparison...\n")

# Function to compare groups with robust handling
compare_groups_robust <- function(vaf_row, groups) {
  als_vaf <- vaf_row[groups == "ALS"]
  control_vaf <- vaf_row[groups == "Control"]
  
  # Remove NA values
  als_vaf <- als_vaf[!is.na(als_vaf)]
  control_vaf <- control_vaf[!is.na(control_vaf)]
  
  if (length(als_vaf) < 3 || length(control_vaf) < 3) {
    return(data.frame(
      mean_als = mean(als_vaf, na.rm = TRUE),
      mean_control = mean(control_vaf, na.rm = TRUE),
      fold_change = NA,
      log2_fold_change = NA,
      t_test_p = NA,
      wilcoxon_p = NA,
      n_als = length(als_vaf),
      n_control = length(control_vaf),
      valid = FALSE
    ))
  }
  
  # Calculate statistics
  mean_als <- mean(als_vaf, na.rm = TRUE)
  mean_control <- mean(control_vaf, na.rm = TRUE)
  
  # Add pseudocount to avoid infinite fold changes
  pseudocount <- 1e-6
  fold_change <- (mean_als + pseudocount) / (mean_control + pseudocount)
  log2_fold_change <- log2(fold_change)
  
  # Perform tests
  t_test_result <- try(t.test(als_vaf, control_vaf), silent = TRUE)
  wilcoxon_result <- try(wilcox.test(als_vaf, control_vaf), silent = TRUE)
  
  t_p <- ifelse(inherits(t_test_result, "try-error"), NA, t_test_result$p.value)
  w_p <- ifelse(inherits(wilcoxon_result, "try-error"), NA, wilcoxon_result$p.value)
  
  return(data.frame(
    mean_als = mean_als,
    mean_control = mean_control,
    fold_change = fold_change,
    log2_fold_change = log2_fold_change,
    t_test_p = t_p,
    wilcoxon_p = w_p,
    n_als = length(als_vaf),
    n_control = length(control_vaf),
    valid = TRUE
  ))
}

# Apply comparison to each SNV
comparison_results <- apply(vaf_clean, 1, function(row) {
  compare_groups_robust(row, sample_groups)
})

# Combine results
comparison_df <- do.call(rbind, comparison_results)
comparison_df$snv_id <- paste(df_gt_clean$`miRNA name`, df_gt_clean$`pos:mut`, sep = "_")

# Filter for valid comparisons
valid_comparisons <- comparison_df %>% filter(valid == TRUE)

cat("   - SNVs analyzed:", nrow(comparison_df), "\n")
cat("   - SNVs with valid comparisons:", nrow(valid_comparisons), "\n\n")

# 9. Select most relevant SNVs with robust criteria
cat("📊 STEP 9: Selecting most relevant SNVs...\n")

# Filter for SNVs with significant differences and reasonable effect sizes
relevant_snvs <- valid_comparisons %>%
  filter(
    t_test_p < 0.05 | wilcoxon_p < 0.05,  # At least one test significant
    abs(log2_fold_change) > 0.5,  # At least 1.4-fold change
    n_als >= 5 & n_control >= 5,  # Minimum sample size
    mean_als > 0.001 | mean_control > 0.001  # At least one group has meaningful VAF
  ) %>%
  mutate(
    abs_log2_fc = abs(log2_fold_change),
    min_p = pmin(t_test_p, wilcoxon_p, na.rm = TRUE),
    effect_size = abs_log2_fc * (-log10(min_p))  # Combined effect size and significance
  ) %>%
  arrange(desc(effect_size), desc(abs_log2_fc))  # Sort by combined score

cat("   - SNVs with significant differences:", nrow(relevant_snvs), "\n")
cat("   - SNVs with |Log2FC| > 1:", sum(abs(relevant_snvs$log2_fold_change) > 1, na.rm = TRUE), "\n")
cat("   - SNVs with |Log2FC| > 2:", sum(abs(relevant_snvs$log2_fold_change) > 2, na.rm = TRUE), "\n\n")

# 10. Create heatmaps
cat("📊 STEP 10: Creating heatmaps...\n")
dir.create("outputs/figures/robust_comparison", showWarnings = FALSE, recursive = TRUE)

# Select top SNVs for heatmap (max 50)
max_snvs <- min(50, nrow(relevant_snvs))
top_relevant_snvs <- head(relevant_snvs, max_snvs)

# Get indices for heatmap
top_indices <- which(comparison_df$snv_id %in% top_relevant_snvs$snv_id)
vaf_heatmap <- vaf_clean[top_indices, ]

# Create sample annotation
sample_annotation <- data.frame(
  Group = sample_groups,
  row.names = sample_names
)

# Define color palette
color_palette <- colorRampPalette(c("white", "lightpink", "red", "darkred"))(100)

# 10.1 Heatmap of most relevant SNVs
png("outputs/figures/robust_comparison/robust_relevant_snvs_heatmap.png", 
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
  main = "Most Biologically Relevant G>T Mutations\n(Robust ALS vs Control Comparison)",
  fontsize = 12,
  fontsize_main = 16,
  border_color = NA,
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

# 11.1 Volcano plot (robust)
p1 <- ggplot(relevant_snvs, aes(x = log2_fold_change, y = -log10(min_p))) +
  geom_point(aes(color = abs_log2_fc > 1), alpha = 0.7) +
  geom_hline(yintercept = -log10(0.05), linetype = "dashed", color = "red") +
  geom_vline(xintercept = c(-1, 1), linetype = "dashed", color = "blue") +
  scale_color_manual(values = c("FALSE" = "gray", "TRUE" = "red")) +
  labs(
    title = "Volcano Plot: Robust ALS vs Control VAF Comparison",
    x = "Log2 Fold Change (ALS/Control)",
    y = "-Log10 P-value",
    color = "|Log2FC| > 1"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    axis.title = element_text(size = 12)
  )

ggsave("outputs/figures/robust_comparison/robust_volcano_plot.png", p1, 
       width = 10, height = 6, dpi = 300)

# 11.2 Top SNVs by effect size
top_effect_snvs <- relevant_snvs %>%
  head(20) %>%
  mutate(snv_id = str_replace(snv_id, "_", "\n"))

p2 <- ggplot(top_effect_snvs, aes(x = reorder(snv_id, effect_size), y = effect_size)) +
  geom_col(aes(fill = log2_fold_change > 0), alpha = 0.7) +
  coord_flip() +
  scale_fill_manual(values = c("FALSE" = "blue", "TRUE" = "red")) +
  labs(
    title = "Top 20 SNVs by Combined Effect Size",
    x = "SNV (miRNA_Position:Mutation)",
    y = "Effect Size (|Log2FC| × -Log10(P))",
    fill = "Higher in ALS"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    axis.title = element_text(size = 12),
    axis.text.y = element_text(size = 8)
  )

ggsave("outputs/figures/robust_comparison/top_effect_size_snvs.png", p2, 
       width = 12, height = 8, dpi = 300)

# 11.3 Fold change distribution (robust)
p3 <- ggplot(relevant_snvs, aes(x = log2_fold_change)) +
  geom_histogram(bins = 30, alpha = 0.7, fill = "darkgreen", color = "white") +
  geom_vline(xintercept = c(-1, 1), linetype = "dashed", color = "red") +
  labs(
    title = "Distribution of Log2 Fold Change (Robust)",
    x = "Log2 Fold Change (ALS/Control)",
    y = "Count"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    axis.title = element_text(size = 12)
  )

ggsave("outputs/figures/robust_comparison/robust_fold_change_distribution.png", p3, 
       width = 10, height = 6, dpi = 300)

# 11.4 Effect size vs significance
p4 <- ggplot(relevant_snvs, aes(x = abs_log2_fc, y = -log10(min_p))) +
  geom_point(aes(color = effect_size), alpha = 0.7) +
  scale_color_viridis() +
  labs(
    title = "Effect Size vs Significance",
    x = "|Log2 Fold Change|",
    y = "-Log10 P-value",
    color = "Combined\nEffect Size"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    axis.title = element_text(size = 12)
  )

ggsave("outputs/figures/robust_comparison/effect_size_vs_significance.png", p4, 
       width = 10, height = 6, dpi = 300)

# 12. Save results
cat("📊 STEP 12: Saving results...\n")

# Save comparison results
write_tsv(relevant_snvs, "outputs/robust_comparison_results.tsv")

# Save VAF matrix
write_tsv(
  as.data.frame(vaf_heatmap) %>% rownames_to_column("snv_id"),
  "outputs/robust_comparison_vaf_matrix.tsv"
)

# Save sample annotation
write_tsv(
  sample_annotation %>% rownames_to_column("sample_id"),
  "outputs/robust_comparison_sample_annotation.tsv"
)

# 13. Create report
cat("📊 STEP 13: Creating report...\n")
report_content <- paste0(
  "# ROBUST GROUP COMPARISON ANALYSIS REPORT\n\n",
  "**Date:** ", Sys.Date(), "\n",
  "**Data file:** results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt\n",
  "**Focus:** Robust biological relevance through ALS vs Control comparison\n",
  "**Top miRNAs:** ", length(top_mirnas), " miRNAs selected by RPM\n\n",
  
  "## ANALYSIS SUMMARY\n\n",
  "- **Total G>T mutations in top miRNAs:** ", nrow(df_gt), "\n",
  "- **SNVs after VAF filtering:** ", nrow(df_gt_clean), "\n",
  "- **SNVs with valid comparisons:** ", nrow(valid_comparisons), "\n",
  "- **SNVs with significant differences:** ", nrow(relevant_snvs), "\n",
  "- **SNVs in heatmap:** ", nrow(vaf_heatmap), "\n",
  "- **Samples in heatmap:** ", ncol(vaf_heatmap), "\n\n",
  
  "## SAMPLE GROUPS\n\n",
  paste(sapply(names(group_counts), function(group) {
    paste0("- **", group, ":** ", group_counts[group], " samples")
  }), collapse = "\n"), "\n\n",
  
  "## ROBUST STATISTICAL CRITERIA\n\n",
  "- **Minimum sample size:** 5 per group\n",
  "- **Significance threshold:** p < 0.05 (t-test or Wilcoxon)\n",
  "- **Effect size threshold:** |Log2FC| > 0.5 (1.4-fold change)\n",
  "- **VAF threshold:** At least one group > 0.001\n",
  "- **Pseudocount:** 1e-6 to avoid infinite fold changes\n",
  "- **SNVs with |Log2FC| > 1:** ", sum(abs(relevant_snvs$log2_fold_change) > 1, na.rm = TRUE), "\n",
  "- **SNVs with |Log2FC| > 2:** ", sum(abs(relevant_snvs$log2_fold_change) > 2, na.rm = TRUE), "\n\n",
  
  "## TOP BIOLOGICALLY RELEVANT SNVs\n\n",
  "| Rank | SNV | Log2FC | T-test P | Wilcoxon P | Mean ALS | Mean Control | Effect Size |\n",
  "|------|-----|--------|----------|------------|----------|--------------|-------------|\n",
  paste(apply(head(relevant_snvs, 15), 1, function(x) {
    paste0("| ", which(relevant_snvs$snv_id == x[1]), " | ", x[1], " | ", 
           round(as.numeric(x[4]), 2), " | ", round(as.numeric(x[6]), 4), " | ", 
           round(as.numeric(x[7]), 4), " | ", round(as.numeric(x[2]), 4), " | ", 
           round(as.numeric(x[3]), 4), " | ", round(as.numeric(x[11]), 2), " |")
  }), collapse = "\n"), "\n\n",
  
  "## FILES GENERATED\n\n",
  "- `robust_relevant_snvs_heatmap.png`: Heatmap of most relevant SNVs\n",
  "- `robust_volcano_plot.png`: Volcano plot of fold change vs p-value\n",
  "- `top_effect_size_snvs.png`: Top SNVs by combined effect size\n",
  "- `robust_fold_change_distribution.png`: Distribution of fold changes\n",
  "- `effect_size_vs_significance.png`: Effect size vs significance plot\n",
  "- `robust_comparison_results.tsv`: Complete comparison results\n",
  "- `robust_comparison_vaf_matrix.tsv`: VAF matrix for heatmap\n",
  "- `robust_comparison_sample_annotation.tsv`: Sample annotations\n\n",
  
  "## INTERPRETATION\n\n",
  "This robust analysis focuses on biologically meaningful differences:\n\n",
  "1. **Statistical significance:** Only SNVs with p < 0.05 are considered\n",
  "2. **Effect size:** Combined score of fold change and significance\n",
  "3. **Sample size:** Minimum 5 samples per group for reliability\n",
  "4. **VAF threshold:** At least one group has meaningful VAF (>0.001)\n",
  "5. **Robust fold change:** Pseudocount prevents infinite values\n",
  "6. **Biological relevance:** SNVs with |Log2FC| > 0.5 are most relevant\n\n",
  "This approach identifies mutations that are truly different and biologically meaningful between disease states."
)

writeLines(report_content, "outputs/robust_comparison_report.md")

cat("✅ ROBUST GROUP COMPARISON ANALYSIS COMPLETED\n")
cat("============================================\n\n")
cat("📁 Files generated in outputs/\n")
cat("📊 Visualizations in outputs/figures/robust_comparison/\n")
cat("📋 Report: outputs/robust_comparison_report.md\n\n")
cat("🔬 Robust biologically relevant features:\n")
cat("   - SNVs with significant differences:", nrow(relevant_snvs), "\n")
cat("   - SNVs with |Log2FC| > 1:", sum(abs(relevant_snvs$log2_fold_change) > 1, na.rm = TRUE), "\n")
cat("   - SNVs with |Log2FC| > 2:", sum(abs(relevant_snvs$log2_fold_change) > 2, na.rm = TRUE), "\n")
cat("   - Heatmap SNVs:", nrow(vaf_heatmap), "\n")











