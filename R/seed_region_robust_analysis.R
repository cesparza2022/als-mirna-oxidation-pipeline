#!/usr/bin/env Rscript

# SEED REGION ROBUST ANALYSIS
# Focus on G>T mutations in seed region (positions 2-8) of selected miRNAs

library(dplyr)
library(stringr)
library(readr)
library(tidyr)
library(tibble)
library(ggplot2)
library(pheatmap)
library(RColorBrewer)
library(viridis)

cat("🌱 SEED REGION ROBUST ANALYSIS\n")
cat("==============================\n\n")

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

# 4. Filter for top miRNAs and G>T mutations in seed region
cat("📊 STEP 4: Filtering for top miRNAs and G>T mutations in seed region...\n")

# First filter for top miRNAs and G>T mutations
df_gt <- df %>%
  filter(`miRNA name` %in% top_mirnas) %>%
  filter(str_detect(`pos:mut`, ":GT"))

cat("   - G>T mutations in top miRNAs:", nrow(df_gt), "\n")

# Extract position from pos:mut column and filter for seed region (positions 2-8)
df_seed <- df_gt %>%
  mutate(
    position = as.numeric(str_extract(`pos:mut`, "^\\d+")),
    mutation = str_extract(`pos:mut`, ":GT$")
  ) %>%
  filter(position >= 2 & position <= 8) %>%
  filter(!is.na(position))

cat("   - G>T mutations in seed region (pos 2-8):", nrow(df_seed), "\n")
cat("   - Unique miRNAs with seed G>T:", length(unique(df_seed$`miRNA name`)), "\n")
cat("   - Position distribution:\n")
pos_dist <- table(df_seed$position)
for (pos in names(pos_dist)) {
  cat("     - Position", pos, ":", pos_dist[pos], "mutations\n")
}
cat("\n")

# 5. Calculate VAFs for seed region
cat("📊 STEP 5: Calculating VAFs for seed region...\n")
snv_mat <- as.matrix(df_seed[, snv_cols])
total_mat <- as.matrix(df_seed[, total_cols])
colnames(total_mat) <- str_replace(colnames(total_mat), " \\(PM\\+1MM\\+2MM\\)", "")

vaf_mat <- snv_mat / (total_mat + 1e-10)
colnames(vaf_mat) <- str_replace(colnames(vaf_mat), "Magen-ALS-enrolment-bloodplasma-", "")

cat("   - VAF matrix dimensions:", dim(vaf_mat), "\n")
cat("   - VAF range:", round(range(vaf_mat, na.rm = TRUE), 4), "\n\n")

# 6. Filter SNVs with VAF > 50%
cat("📊 STEP 6: Filtering SNVs with VAF > 50%...\n")
high_vaf_idx <- apply(vaf_mat > 0.5, 1, any, na.rm = TRUE)
df_seed_clean <- df_seed[!high_vaf_idx, ]
vaf_clean <- vaf_mat[!high_vaf_idx, ]

cat("   - SNVs removed (VAF > 50%):", sum(high_vaf_idx), "\n")
cat("   - Rows after VAF filtering:", nrow(df_seed_clean), "\n\n")

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

# 8. Robust statistical comparison for seed region SNVs
cat("📊 STEP 8: Performing robust statistical comparison for seed region...\n")

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
comparison_df$snv_id <- paste(df_seed_clean$`miRNA name`, df_seed_clean$`pos:mut`, sep = "_")
comparison_df$position <- df_seed_clean$position
comparison_df$miRNA <- df_seed_clean$`miRNA name`

# Filter for valid comparisons
valid_comparisons <- comparison_df %>% filter(valid == TRUE)

cat("   - SNVs analyzed:", nrow(comparison_df), "\n")
cat("   - SNVs with valid comparisons:", nrow(valid_comparisons), "\n\n")

# 9. Select most relevant seed region SNVs
cat("📊 STEP 9: Selecting most relevant seed region SNVs...\n")

# Filter for SNVs with significant differences and reasonable effect sizes
relevant_snvs <- valid_comparisons %>%
  filter(
    t_test_p < 0.05 | wilcoxon_p < 0.05,  # At least one test significant
    abs(log2_fold_change) > 0.3,  # At least 1.2-fold change (more lenient for seed)
    n_als >= 3 & n_control >= 3,  # Minimum sample size (more lenient)
    mean_als > 0.0005 | mean_control > 0.0005  # At least one group has meaningful VAF
  ) %>%
  mutate(
    abs_log2_fc = abs(log2_fold_change),
    min_p = pmin(t_test_p, wilcoxon_p, na.rm = TRUE),
    effect_size = abs_log2_fc * (-log10(min_p))  # Combined effect size and significance
  ) %>%
  arrange(desc(effect_size), desc(abs_log2_fc))  # Sort by combined score

cat("   - SNVs with significant differences:", nrow(relevant_snvs), "\n")
cat("   - SNVs with |Log2FC| > 0.5:", sum(abs(relevant_snvs$log2_fold_change) > 0.5, na.rm = TRUE), "\n")
cat("   - SNVs with |Log2FC| > 1:", sum(abs(relevant_snvs$log2_fold_change) > 1, na.rm = TRUE), "\n\n")

# 10. Create visualizations
cat("📊 STEP 10: Creating visualizations...\n")
dir.create("outputs/figures/seed_region_robust", showWarnings = FALSE, recursive = TRUE)

# 10.1 Position distribution of all seed mutations
p1 <- ggplot(df_seed_clean, aes(x = factor(position))) +
  geom_bar(fill = "steelblue", alpha = 0.7) +
  labs(
    title = "Distribution of G>T Mutations in Seed Region (Positions 2-8)",
    x = "Position in miRNA",
    y = "Number of Mutations"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    axis.title = element_text(size = 12)
  )

ggsave("outputs/figures/seed_region_robust/position_distribution.png", p1, 
       width = 10, height = 6, dpi = 300)

# 10.2 VAF distribution by position
vaf_long <- vaf_clean %>%
  as.data.frame() %>%
  mutate(snv_id = paste(df_seed_clean$`miRNA name`, df_seed_clean$`pos:mut`, sep = "_"),
         position = df_seed_clean$position) %>%
  pivot_longer(cols = -c(snv_id, position), names_to = "sample", values_to = "vaf") %>%
  filter(!is.na(vaf) & vaf > 0)

p2 <- ggplot(vaf_long, aes(x = factor(position), y = vaf)) +
  geom_boxplot(aes(fill = factor(position)), alpha = 0.7) +
  scale_y_log10() +
  labs(
    title = "VAF Distribution by Position in Seed Region",
    x = "Position in miRNA",
    y = "VAF (log10 scale)",
    fill = "Position"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    axis.title = element_text(size = 12),
    legend.position = "none"
  )

ggsave("outputs/figures/seed_region_robust/vaf_by_position.png", p2, 
       width = 10, height = 6, dpi = 300)

# 10.3 Heatmap of all seed region SNVs (if not too many)
if (nrow(vaf_clean) <= 100) {
  # Create sample annotation
  sample_annotation <- data.frame(
    Group = sample_groups,
    row.names = sample_names
  )
  
  # Define color palette
  color_palette <- colorRampPalette(c("white", "lightpink", "red", "darkred"))(100)
  
  png("outputs/figures/seed_region_robust/seed_region_heatmap.png", 
      width = 1400, height = 1000, res = 150)
  
  pheatmap(
    vaf_clean,
    clustering_distance_rows = "euclidean",
    clustering_distance_cols = "euclidean", 
    clustering_method = "ward.D2",
    color = color_palette,
    annotation_col = sample_annotation,
    annotation_colors = list(Group = c("ALS" = "#E31A1C", "Control" = "#1F78B4")),
    show_rownames = FALSE,
    show_colnames = FALSE,
    main = "G>T Mutations in Seed Region (Positions 2-8)\nALS vs Control Comparison",
    fontsize = 12,
    fontsize_main = 16,
    border_color = NA,
    cluster_rows = TRUE,
    cluster_cols = TRUE,
    scale = "none",
    breaks = seq(0, max(vaf_clean, na.rm = TRUE), length.out = 101),
    legend_breaks = c(0, 0.1, 0.2, 0.3, 0.4, 0.5),
    legend_labels = c("0.0", "0.1", "0.2", "0.3", "0.4", "0.5"),
    legend_title = "VAF"
  )
  
  dev.off()
}

# 10.4 Volcano plot for seed region
if (nrow(relevant_snvs) > 0) {
  p3 <- ggplot(relevant_snvs, aes(x = log2_fold_change, y = -log10(min_p))) +
    geom_point(aes(color = abs_log2_fc > 0.5), alpha = 0.7) +
    geom_hline(yintercept = -log10(0.05), linetype = "dashed", color = "red") +
    geom_vline(xintercept = c(-0.5, 0.5), linetype = "dashed", color = "blue") +
    scale_color_manual(values = c("FALSE" = "gray", "TRUE" = "red")) +
    labs(
      title = "Volcano Plot: Seed Region G>T Mutations (ALS vs Control)",
      x = "Log2 Fold Change (ALS/Control)",
      y = "-Log10 P-value",
      color = "|Log2FC| > 0.5"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      axis.title = element_text(size = 12)
    )
  
  ggsave("outputs/figures/seed_region_robust/seed_volcano_plot.png", p3, 
         width = 10, height = 6, dpi = 300)
}

# 10.5 Top SNVs by effect size
if (nrow(relevant_snvs) > 0) {
  top_effect_snvs <- relevant_snvs %>%
    head(20) %>%
    mutate(snv_id = str_replace(snv_id, "_", "\n"))
  
  p4 <- ggplot(top_effect_snvs, aes(x = reorder(snv_id, effect_size), y = effect_size)) +
    geom_col(aes(fill = log2_fold_change > 0), alpha = 0.7) +
    coord_flip() +
    scale_fill_manual(values = c("FALSE" = "blue", "TRUE" = "red")) +
    labs(
      title = "Top Seed Region SNVs by Combined Effect Size",
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
  
  ggsave("outputs/figures/seed_region_robust/top_seed_effect_snvs.png", p4, 
         width = 12, height = 8, dpi = 300)
}

# 10.6 Position-specific analysis
position_summary <- df_seed_clean %>%
  group_by(position) %>%
  summarise(
    n_mutations = n(),
    n_mirnas = length(unique(`miRNA name`)),
    mean_vaf = mean(apply(vaf_clean[df_seed_clean$position == position[1], ], 1, mean, na.rm = TRUE)),
    .groups = "drop"
  )

p5 <- ggplot(position_summary, aes(x = factor(position), y = n_mutations)) +
  geom_col(fill = "darkgreen", alpha = 0.7) +
  geom_text(aes(label = n_mutations), vjust = -0.5) +
  labs(
    title = "Number of G>T Mutations by Position in Seed Region",
    x = "Position in miRNA",
    y = "Number of Mutations"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    axis.title = element_text(size = 12)
  )

ggsave("outputs/figures/seed_region_robust/mutations_by_position.png", p5, 
       width = 10, height = 6, dpi = 300)

# 11. Save results
cat("📊 STEP 11: Saving results...\n")

# Save comparison results
write_tsv(relevant_snvs, "outputs/seed_region_robust_results.tsv")

# Save position summary
write_tsv(position_summary, "outputs/seed_region_position_summary.tsv")

# Save VAF matrix
write_tsv(
  as.data.frame(vaf_clean) %>% 
    mutate(snv_id = paste(df_seed_clean$`miRNA name`, df_seed_clean$`pos:mut`, sep = "_"),
           position = df_seed_clean$position) %>%
    select(snv_id, position, everything()),
  "outputs/seed_region_vaf_matrix.tsv"
)

# 12. Create report
cat("📊 STEP 12: Creating report...\n")
report_content <- paste0(
  "# SEED REGION ROBUST ANALYSIS REPORT\n\n",
  "**Date:** ", Sys.Date(), "\n",
  "**Data file:** results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt\n",
  "**Focus:** G>T mutations in seed region (positions 2-8) of selected miRNAs\n",
  "**Top miRNAs:** ", length(top_mirnas), " miRNAs selected by RPM\n\n",
  
  "## ANALYSIS SUMMARY\n\n",
  "- **Total G>T mutations in top miRNAs:** ", nrow(df_gt), "\n",
  "- **G>T mutations in seed region:** ", nrow(df_seed), "\n",
  "- **SNVs after VAF filtering:** ", nrow(df_seed_clean), "\n",
  "- **SNVs with valid comparisons:** ", nrow(valid_comparisons), "\n",
  "- **SNVs with significant differences:** ", nrow(relevant_snvs), "\n",
  "- **Unique miRNAs with seed mutations:** ", length(unique(df_seed$`miRNA name`)), "\n\n",
  
  "## SAMPLE GROUPS\n\n",
  paste(sapply(names(group_counts), function(group) {
    paste0("- **", group, ":** ", group_counts[group], " samples")
  }), collapse = "\n"), "\n\n",
  
  "## POSITION DISTRIBUTION\n\n",
  "| Position | Mutations | miRNAs |\n",
  "|----------|-----------|--------|\n",
  paste(apply(position_summary, 1, function(x) {
    paste0("| ", x[1], " | ", x[2], " | ", x[3], " |")
  }), collapse = "\n"), "\n\n",
  
  "## ROBUST STATISTICAL CRITERIA\n\n",
  "- **Minimum sample size:** 3 per group (lenient for seed region)\n",
  "- **Significance threshold:** p < 0.05 (t-test or Wilcoxon)\n",
  "- **Effect size threshold:** |Log2FC| > 0.3 (1.2-fold change)\n",
  "- **VAF threshold:** At least one group > 0.0005\n",
  "- **Pseudocount:** 1e-6 to avoid infinite fold changes\n",
  "- **SNVs with |Log2FC| > 0.5:** ", sum(abs(relevant_snvs$log2_fold_change) > 0.5, na.rm = TRUE), "\n",
  "- **SNVs with |Log2FC| > 1:** ", sum(abs(relevant_snvs$log2_fold_change) > 1, na.rm = TRUE), "\n\n",
  
  "## TOP BIOLOGICALLY RELEVANT SEED SNVs\n\n",
  if (nrow(relevant_snvs) > 0) {
    paste0(
      "| Rank | SNV | Position | Log2FC | T-test P | Wilcoxon P | Mean ALS | Mean Control | Effect Size |\n",
      "|------|-----|----------|--------|----------|------------|----------|--------------|-------------|\n",
      paste(apply(head(relevant_snvs, 15), 1, function(x) {
        paste0("| ", which(relevant_snvs$snv_id == x[1]), " | ", x[1], " | ", x[2], " | ", 
               round(as.numeric(x[4]), 2), " | ", round(as.numeric(x[6]), 4), " | ", 
               round(as.numeric(x[7]), 4), " | ", round(as.numeric(x[2]), 4), " | ", 
               round(as.numeric(x[3]), 4), " | ", round(as.numeric(x[11]), 2), " |")
      }), collapse = "\n")
    )
  } else {
    "No SNVs met the criteria for biological relevance in the seed region."
  }, "\n\n",
  
  "## FILES GENERATED\n\n",
  "- `position_distribution.png`: Distribution of mutations by position\n",
  "- `vaf_by_position.png`: VAF distribution by position\n",
  "- `seed_region_heatmap.png`: Heatmap of all seed region SNVs\n",
  "- `seed_volcano_plot.png`: Volcano plot for seed region\n",
  "- `top_seed_effect_snvs.png`: Top SNVs by effect size\n",
  "- `mutations_by_position.png`: Number of mutations by position\n",
  "- `seed_region_robust_results.tsv`: Complete comparison results\n",
  "- `seed_region_position_summary.tsv`: Position summary\n",
  "- `seed_region_vaf_matrix.tsv`: VAF matrix for seed region\n\n",
  
  "## INTERPRETATION\n\n",
  "This analysis focuses on the most functionally relevant region of miRNAs:\n\n",
  "1. **Seed region specificity:** Positions 2-8 are critical for target recognition\n",
  "2. **Functional impact:** Mutations here directly affect miRNA function\n",
  "3. **Biological relevance:** Only statistically significant differences are considered\n",
  "4. **Position analysis:** Shows which positions are most affected\n",
  "5. **Group comparison:** Identifies differences between ALS and Control\n\n",
  "This approach identifies the most functionally significant mutations in the most critical region of miRNAs."
)

writeLines(report_content, "outputs/seed_region_robust_report.md")

cat("✅ SEED REGION ROBUST ANALYSIS COMPLETED\n")
cat("=======================================\n\n")
cat("📁 Files generated in outputs/\n")
cat("📊 Visualizations in outputs/figures/seed_region_robust/\n")
cat("📋 Report: outputs/seed_region_robust_report.md\n\n")
cat("🌱 Seed region findings:\n")
cat("   - Total seed mutations:", nrow(df_seed), "\n")
cat("   - After VAF filtering:", nrow(df_seed_clean), "\n")
cat("   - Significant differences:", nrow(relevant_snvs), "\n")
cat("   - Unique miRNAs affected:", length(unique(df_seed$`miRNA name`)), "\n")
cat("   - Most affected position:", names(pos_dist)[which.max(pos_dist)], "\n")











