#!/usr/bin/env Rscript

# EXPANDED SEED REGION ANALYSIS
# Use more miRNAs with RPM > 3 filter, but rank by seed region G>T SNVs

library(dplyr)
library(stringr)
library(readr)
library(tidyr)
library(tibble)
library(ggplot2)
library(pheatmap)
library(RColorBrewer)
library(viridis)

cat("🌱 EXPANDED SEED REGION ANALYSIS\n")
cat("================================\n\n")

# 1. Load data
cat("📊 STEP 1: Loading data...\n")
df <- read_tsv("results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt", show_col_types = FALSE)
cat("   - Total rows:", nrow(df), "\n")
cat("   - Total unique miRNAs:", length(unique(df$`miRNA name`)), "\n\n")

# 2. Identify columns
cat("📊 STEP 2: Identifying column types...\n")
meta_cols <- c("miRNA name", "pos:mut")
all_cols <- colnames(df)
total_cols <- all_cols[str_detect(all_cols, "\\(PM\\+1MM\\+2MM\\)")]
snv_cols <- setdiff(all_cols, c(meta_cols, total_cols))

cat("   - Meta columns:", length(meta_cols), "\n")
cat("   - SNV columns:", length(snv_cols), "\n")
cat("   - Total columns:", length(total_cols), "\n\n")

# 3. Calculate library size and RPM for all miRNAs
cat("📊 STEP 3: Calculating RPM for all miRNAs...\n")

# Calculate library size per sample
lib_size <- df %>%
  summarise(across(all_of(total_cols), ~ sum(.x, na.rm = TRUE))) %>%
  unlist()

# Calculate RPM for each miRNA
rpm_data <- df %>%
  distinct(`miRNA name`, .keep_all = TRUE) %>%
  select(`miRNA name`, all_of(total_cols))

# Calculate RPM manually to avoid column name issues
for (col in total_cols) {
  rpm_data[[col]] <- (rpm_data[[col]] / lib_size[col]) * 1e6
}

# Calculate mean RPM per miRNA
mean_rpm <- rpm_data %>%
  mutate(mean_rpm = rowMeans(select(., all_of(total_cols)), na.rm = TRUE)) %>%
  select(`miRNA name`, mean_rpm)

cat("   - miRNAs with RPM > 3:", sum(mean_rpm$mean_rpm > 3, na.rm = TRUE), "\n")
cat("   - miRNAs with RPM > 1:", sum(mean_rpm$mean_rpm > 1, na.rm = TRUE), "\n")
cat("   - miRNAs with RPM > 0.1:", sum(mean_rpm$mean_rpm > 0.1, na.rm = TRUE), "\n\n")

# 4. Filter for miRNAs with RPM > 3
cat("📊 STEP 4: Filtering miRNAs with RPM > 3...\n")
high_expr_mirnas <- mean_rpm %>%
  filter(mean_rpm > 3) %>%
  pull(`miRNA name`)

cat("   - High expression miRNAs:", length(high_expr_mirnas), "\n\n")

# 5. Filter for G>T mutations in seed region (positions 2-8)
cat("📊 STEP 5: Filtering G>T mutations in seed region...\n")
df_seed <- df %>%
  filter(`miRNA name` %in% high_expr_mirnas) %>%
  filter(str_detect(`pos:mut`, ":GT")) %>%
  mutate(
    position = as.numeric(str_extract(`pos:mut`, "^\\d+")),
    mutation = str_extract(`pos:mut`, ":GT$")
  ) %>%
  filter(position >= 2 & position <= 8) %>%
  filter(!is.na(position))

cat("   - G>T mutations in seed region:", nrow(df_seed), "\n")
cat("   - Unique miRNAs with seed G>T:", length(unique(df_seed$`miRNA name`)), "\n")
cat("   - Position distribution:\n")
pos_dist <- table(df_seed$position)
for (pos in names(pos_dist)) {
  cat("     - Position", pos, ":", pos_dist[pos], "mutations\n")
}
cat("\n")

# 6. Calculate VAFs and filter high VAF SNVs
cat("📊 STEP 6: Calculating VAFs and filtering...\n")
snv_mat <- as.matrix(df_seed[, snv_cols])
total_mat <- as.matrix(df_seed[, total_cols])
colnames(total_mat) <- str_replace(colnames(total_mat), " \\(PM\\+1MM\\+2MM\\)", "")

vaf_mat <- snv_mat / (total_mat + 1e-10)
colnames(vaf_mat) <- str_replace(colnames(vaf_mat), "Magen-ALS-enrolment-bloodplasma-", "")

# Filter SNVs with VAF > 50%
high_vaf_idx <- apply(vaf_mat > 0.5, 1, any, na.rm = TRUE)
df_seed_clean <- df_seed[!high_vaf_idx, ]
vaf_clean <- vaf_mat[!high_vaf_idx, ]

cat("   - SNVs removed (VAF > 50%):", sum(high_vaf_idx), "\n")
cat("   - Rows after VAF filtering:", nrow(df_seed_clean), "\n\n")

# 7. Calculate seed region G>T counts per miRNA
cat("📊 STEP 7: Calculating seed region G>T counts per miRNA...\n")

# Calculate VAFs for seed region
snv_mat_seed <- as.matrix(df_seed_clean[, snv_cols])
total_mat_seed <- as.matrix(df_seed_clean[, total_cols])
colnames(total_mat_seed) <- str_replace(colnames(total_mat_seed), " \\(PM\\+1MM\\+2MM\\)", "")

vaf_mat_seed <- snv_mat_seed / (total_mat_seed + 1e-10)

# Calculate counts and VAFs per miRNA
seed_counts <- df_seed_clean %>%
  group_by(`miRNA name`) %>%
  summarise(
    total_seed_gt_count = sum(across(all_of(snv_cols)), na.rm = TRUE),
    n_seed_snvs = n(),
    .groups = "drop"
  ) %>%
  arrange(desc(total_seed_gt_count))

# Add mean VAF calculation
seed_counts$mean_seed_vaf <- sapply(seed_counts$`miRNA name`, function(mirna) {
  idx <- df_seed_clean$`miRNA name` == mirna
  if (sum(idx) > 0) {
    mean(vaf_mat_seed[idx, ], na.rm = TRUE)
  } else {
    NA
  }
})

cat("   - miRNAs with seed G>T counts:", nrow(seed_counts), "\n")
cat("   - Top 5 miRNAs by seed G>T count:\n")
top_5 <- head(seed_counts, 5)
for (i in 1:nrow(top_5)) {
  cat("     ", i, ".", top_5$`miRNA name`[i], ":", top_5$total_seed_gt_count[i], "counts\n")
}
cat("\n")

# 8. Select top miRNAs based on seed region G>T counts
cat("📊 STEP 8: Selecting top miRNAs by seed region G>T counts...\n")
top_percent <- 0.15  # 15% of miRNAs
num_top <- max(1, floor(nrow(seed_counts) * top_percent))
top_seed_mirnas <- head(seed_counts, num_top)$`miRNA name`

cat("   - Top", num_top, "miRNAs selected (", round(top_percent * 100), "%)\n")
cat("   - miRNAs:", paste(head(top_seed_mirnas, 10), collapse = ", "), "...\n\n")

# 9. Compare with previous top miRNAs list
cat("📊 STEP 9: Comparing with previous top miRNAs...\n")
if (file.exists("outputs/rpm_based_top_mirna_list.txt")) {
  prev_top_mirnas <- readLines("outputs/rpm_based_top_mirna_list.txt")
  
  # Calculate overlap
  shared_mirnas <- intersect(top_seed_mirnas, prev_top_mirnas)
  seed_only <- setdiff(top_seed_mirnas, prev_top_mirnas)
  prev_only <- setdiff(prev_top_mirnas, top_seed_mirnas)
  
  cat("   - Previous top miRNAs:", length(prev_top_mirnas), "\n")
  cat("   - New seed-based miRNAs:", length(top_seed_mirnas), "\n")
  cat("   - Shared miRNAs:", length(shared_mirnas), "\n")
  cat("   - Only in seed analysis:", length(seed_only), "\n")
  cat("   - Only in previous analysis:", length(prev_only), "\n")
  cat("   - Overlap percentage:", round(length(shared_mirnas) / length(prev_top_mirnas) * 100, 1), "%\n\n")
  
  # Show new miRNAs found
  if (length(seed_only) > 0) {
    cat("   - New miRNAs found in seed analysis:\n")
    for (i in 1:min(10, length(seed_only))) {
      mirna <- seed_only[i]
      count <- seed_counts$total_seed_gt_count[seed_counts$`miRNA name` == mirna]
      cat("     ", i, ".", mirna, ":", count, "seed G>T counts\n")
    }
    if (length(seed_only) > 10) {
      cat("     ... and", length(seed_only) - 10, "more\n")
    }
  }
  cat("\n")
}

# 10. Create visualizations
cat("📊 STEP 10: Creating visualizations...\n")
dir.create("outputs/figures/expanded_seed_analysis", showWarnings = FALSE, recursive = TRUE)

# 10.1 Comparison of miRNA selection methods
if (file.exists("outputs/rpm_based_top_mirna_list.txt")) {
  comparison_data <- data.frame(
    Method = c(rep("Previous RPM-based", length(prev_top_mirnas)),
               rep("Seed G>T-based", length(top_seed_mirnas))),
    Count = c(rep(1, length(prev_top_mirnas)),
              rep(1, length(top_seed_mirnas)))
  )
  
  p1 <- ggplot(comparison_data, aes(x = Method, fill = Method)) +
    geom_bar(alpha = 0.7) +
    scale_fill_manual(values = c("Previous RPM-based" = "steelblue", 
                                "Seed G>T-based" = "darkgreen")) +
    labs(
      title = "Comparison of miRNA Selection Methods",
      x = "Selection Method",
      y = "Number of miRNAs"
    ) +
    theme_minimal() +
    theme(legend.position = "none")
  
  ggsave("outputs/figures/expanded_seed_analysis/method_comparison.png", p1, 
         width = 8, height = 6, dpi = 300)
}

# 10.2 Seed G>T counts distribution
p2 <- ggplot(seed_counts, aes(x = total_seed_gt_count)) +
  geom_histogram(bins = 30, fill = "darkgreen", alpha = 0.7) +
  geom_vline(xintercept = seed_counts$total_seed_gt_count[num_top], 
             color = "red", linetype = "dashed", size = 1) +
  labs(
    title = "Distribution of Seed Region G>T Counts per miRNA",
    x = "Total Seed G>T Counts",
    y = "Number of miRNAs"
  ) +
  theme_minimal()
  
ggsave("outputs/figures/expanded_seed_analysis/seed_counts_distribution.png", p2, 
       width = 10, height = 6, dpi = 300)

# 10.3 Top miRNAs by seed G>T counts
top_20 <- head(seed_counts, 20)
p3 <- ggplot(top_20, aes(x = reorder(`miRNA name`, total_seed_gt_count), 
                        y = total_seed_gt_count)) +
  geom_col(fill = "darkgreen", alpha = 0.7) +
  coord_flip() +
  labs(
    title = "Top 20 miRNAs by Seed Region G>T Counts",
    x = "miRNA",
    y = "Total Seed G>T Counts"
  ) +
  theme_minimal() +
  theme(axis.text.y = element_text(size = 8))
  
ggsave("outputs/figures/expanded_seed_analysis/top_mirnas_seed_counts.png", p3, 
       width = 12, height = 8, dpi = 300)

# 10.4 Position distribution in seed region
p4 <- ggplot(df_seed_clean, aes(x = factor(position))) +
  geom_bar(fill = "steelblue", alpha = 0.7) +
  labs(
    title = "Distribution of G>T Mutations in Seed Region (Positions 2-8)",
    x = "Position in miRNA",
    y = "Number of Mutations"
  ) +
  theme_minimal()
  
ggsave("outputs/figures/expanded_seed_analysis/position_distribution.png", p4, 
       width = 10, height = 6, dpi = 300)

# 11. Create heatmap with new miRNA selection
cat("📊 STEP 11: Creating heatmap with seed-based miRNA selection...\n")

# Filter data for top seed miRNAs
df_heatmap <- df %>%
  filter(`miRNA name` %in% top_seed_mirnas) %>%
  filter(str_detect(`pos:mut`, ":GT")) %>%
  filter(!str_detect(`pos:mut`, "PM$"))

# Calculate VAFs
snv_mat_hm <- as.matrix(df_heatmap[, snv_cols])
total_mat_hm <- as.matrix(df_heatmap[, total_cols])
colnames(total_mat_hm) <- str_replace(colnames(total_mat_hm), " \\(PM\\+1MM\\+2MM\\)", "")

vaf_mat_hm <- snv_mat_hm / (total_mat_hm + 1e-10)
colnames(vaf_mat_hm) <- str_replace(colnames(vaf_mat_hm), "Magen-ALS-enrolment-bloodplasma-", "")

# Filter high VAF SNVs
high_vaf_idx_hm <- apply(vaf_mat_hm > 0.5, 1, any, na.rm = TRUE)
vaf_clean_hm <- vaf_mat_hm[!high_vaf_idx_hm, ]

# Select top SNVs by average VAF
top_snvs_idx <- order(rowMeans(vaf_clean_hm, na.rm = TRUE), decreasing = TRUE)[1:min(100, nrow(vaf_clean_hm))]
vaf_final <- vaf_clean_hm[top_snvs_idx, ]

# Create sample annotation
sample_names_hm <- colnames(vaf_final)
sample_groups_hm <- ifelse(
  str_detect(sample_names_hm, "control|Control|CTRL|ctrl"),
  "Control",
  "ALS"
)

sample_annotation <- data.frame(
  Group = sample_groups_hm,
  row.names = sample_names_hm
)

# Create heatmap
color_palette <- colorRampPalette(c("white", "lightpink", "red", "darkred"))(100)

png("outputs/figures/expanded_seed_analysis/seed_based_heatmap.png", 
    width = 1400, height = 1000, res = 150)

pheatmap(
  vaf_final,
  clustering_distance_rows = "euclidean",
  clustering_distance_cols = "euclidean", 
  clustering_method = "ward.D2",
  color = color_palette,
  annotation_col = sample_annotation,
  annotation_colors = list(Group = c("ALS" = "#E31A1C", "Control" = "#1F78B4")),
  show_rownames = FALSE,
  show_colnames = FALSE,
  main = "G>T Mutations - Seed-based miRNA Selection\nALS vs Control Comparison",
  fontsize = 12,
  fontsize_main = 16,
  border_color = NA,
  cluster_rows = TRUE,
  cluster_cols = TRUE,
  scale = "none",
  breaks = seq(0, max(vaf_final, na.rm = TRUE), length.out = 101),
  legend_breaks = c(0, 0.1, 0.2, 0.3, 0.4, 0.5),
  legend_labels = c("0.0", "0.1", "0.2", "0.3", "0.4", "0.5"),
  legend_title = "VAF"
)

dev.off()

# 12. Save results
cat("📊 STEP 12: Saving results...\n")

# Save top miRNAs list
writeLines(top_seed_mirnas, "outputs/expanded_seed_top_mirna_list.txt")

# Save seed counts
write_tsv(seed_counts, "outputs/expanded_seed_counts.tsv")

# Save VAF matrix
write_tsv(
  as.data.frame(vaf_final) %>% 
    mutate(snv_id = paste(df_heatmap$`miRNA name`[!high_vaf_idx_hm][top_snvs_idx], 
                         df_heatmap$`pos:mut`[!high_vaf_idx_hm][top_snvs_idx], sep = "_")) %>%
    select(snv_id, everything()),
  "outputs/expanded_seed_vaf_matrix.tsv"
)

# 13. Create report
cat("📊 STEP 13: Creating report...\n")
report_content <- paste0(
  "# EXPANDED SEED REGION ANALYSIS REPORT\n\n",
  "**Date:** ", Sys.Date(), "\n",
  "**Data file:** results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt\n",
  "**Focus:** G>T mutations in seed region (positions 2-8) with RPM > 3 filter\n",
  "**Selection method:** Rank by total seed region G>T counts\n\n",
  
  "## ANALYSIS SUMMARY\n\n",
  "- **High expression miRNAs (RPM > 3):** ", length(high_expr_mirnas), "\n",
  "- **G>T mutations in seed region:** ", nrow(df_seed), "\n",
  "- **SNVs after VAF filtering:** ", nrow(df_seed_clean), "\n",
  "- **miRNAs with seed G>T counts:** ", nrow(seed_counts), "\n",
  "- **Top miRNAs selected:** ", length(top_seed_mirnas), " (", round(top_percent * 100), "%)\n\n",
  
  "## COMPARISON WITH PREVIOUS ANALYSIS\n\n",
  if (file.exists("outputs/rpm_based_top_mirna_list.txt")) {
    paste0(
      "- **Previous top miRNAs:** ", length(prev_top_mirnas), "\n",
      "- **New seed-based miRNAs:** ", length(top_seed_mirnas), "\n",
      "- **Shared miRNAs:** ", length(shared_mirnas), "\n",
      "- **Only in seed analysis:** ", length(seed_only), "\n",
      "- **Only in previous analysis:** ", length(prev_only), "\n",
      "- **Overlap percentage:** ", round(length(shared_mirnas) / length(prev_top_mirnas) * 100, 1), "%\n\n"
    )
  } else {
    "No previous analysis to compare with.\n\n"
  },
  
  "## POSITION DISTRIBUTION IN SEED REGION\n\n",
  "| Position | Mutations | miRNAs |\n",
  "|----------|-----------|--------|\n",
  paste(apply(data.frame(position = names(pos_dist), mutations = as.numeric(pos_dist)), 1, function(x) {
    paste0("| ", x[1], " | ", x[2], " | ", length(unique(df_seed_clean$`miRNA name`[df_seed_clean$position == as.numeric(x[1])])), " |")
  }), collapse = "\n"), "\n\n",
  
  "## TOP 10 miRNAs BY SEED G>T COUNTS\n\n",
  "| Rank | miRNA | Seed G>T Counts | Mean VAF |\n",
  "|------|-------|-----------------|----------|\n",
  paste(apply(head(seed_counts, 10), 1, function(x, i) {
    paste0("| ", i, " | ", x[1], " | ", x[2], " | ", round(as.numeric(x[4]), 6), " |")
  }, 1:10), collapse = "\n"), "\n\n",
  
  "## FILES GENERATED\n\n",
  "- `method_comparison.png`: Comparison of selection methods\n",
  "- `seed_counts_distribution.png`: Distribution of seed G>T counts\n",
  "- `top_mirnas_seed_counts.png`: Top miRNAs by seed counts\n",
  "- `position_distribution.png`: Position distribution in seed region\n",
  "- `seed_based_heatmap.png`: Heatmap with seed-based selection\n",
  "- `expanded_seed_top_mirna_list.txt`: List of top miRNAs\n",
  "- `expanded_seed_counts.tsv`: Complete seed counts data\n",
  "- `expanded_seed_vaf_matrix.tsv`: VAF matrix for heatmap\n\n",
  
  "## INTERPRETATION\n\n",
  "This analysis uses a more comprehensive approach:\n\n",
  "1. **Expression filter:** Only miRNAs with RPM > 3 (high expression)\n",
  "2. **Seed region focus:** Only G>T mutations in positions 2-8\n",
  "3. **Count-based ranking:** Rank by total seed region G>T counts\n",
  "4. **Functional relevance:** Focus on the most critical region for miRNA function\n\n",
  "This approach identifies miRNAs that are both highly expressed and have significant G>T mutations in their seed region, making them the most functionally relevant for oxidative damage analysis."
)

writeLines(report_content, "outputs/expanded_seed_analysis_report.md")

cat("✅ EXPANDED SEED REGION ANALYSIS COMPLETED\n")
cat("==========================================\n\n")
cat("📁 Files generated in outputs/\n")
cat("📊 Visualizations in outputs/figures/expanded_seed_analysis/\n")
cat("📋 Report: outputs/expanded_seed_analysis_report.md\n\n")
cat("🌱 Key findings:\n")
cat("   - High expression miRNAs:", length(high_expr_mirnas), "\n")
cat("   - Seed G>T mutations:", nrow(df_seed), "\n")
cat("   - Top miRNAs selected:", length(top_seed_mirnas), "\n")
if (file.exists("outputs/rpm_based_top_mirna_list.txt")) {
  cat("   - Overlap with previous:", length(shared_mirnas), "miRNAs\n")
  cat("   - New miRNAs found:", length(seed_only), "\n")
}
cat("   - Most affected position:", names(pos_dist)[which.max(pos_dist)], "\n")
