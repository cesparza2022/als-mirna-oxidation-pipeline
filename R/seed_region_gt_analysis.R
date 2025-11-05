# Seed Region G>T Analysis - Corrected Approach
# Filter by 50% representation, then rank miRNAs by G>T counts in seed region

library(ggplot2)
library(dplyr)
library(readr)
library(stringr)
library(gridExtra)
library(RColorBrewer)
library(reshape2)
library(ComplexHeatmap)
library(circlize)
library(tibble)

# Set working directory
setwd("/Users/cesaresparza/New_Desktop/UCSD/8OG")

# Read the main data file
vaf_zscore_data <- read_tsv("outputs/simple_final_vaf_data.tsv")

# Output directory for figures and tables
output_dir <- "outputs/figures/seed_region_analysis"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}
output_table_dir <- "outputs/tables/seed_region_analysis"
if (!dir.exists(output_table_dir)) {
  dir.create(output_table_dir, recursive = TRUE)
}

cat("🧬 SEED REGION G>T ANALYSIS\n")
cat("===========================\n\n")

# --- STEP 1: FILTER BY 50% REPRESENTATION ---
cat("📊 STEP 1: Filtering by 50% representation\n")
cat("==========================================\n")

# Get sample columns (excluding miRNA.name, pos.mut, position, mean_vaf, max_vaf, mean_rpm)
sample_cols <- colnames(vaf_zscore_data)[!grepl("miRNA.name|pos.mut|position|mean_vaf|max_vaf|mean_rpm", colnames(vaf_zscore_data))]
# Filter for actual sample columns (not total counts)
sample_cols_clean <- sample_cols[!grepl("\\(PM\\+1MM\\+2MM\\)$", sample_cols)]

# Get numeric columns for filtering
numeric_cols_all <- sapply(vaf_zscore_data, is.numeric)
sample_numeric_cols_all <- names(numeric_cols_all)[numeric_cols_all & !names(numeric_cols_all) %in% c("position", "mean_vaf", "max_vaf", "mean_rpm")]

# Count total samples (excluding total count columns)
total_count_cols <- grep("\\(PM\\+1MM\\+2MM\\)$", sample_numeric_cols_all, value = TRUE)
snv_count_cols <- setdiff(sample_numeric_cols_all, total_count_cols)

# Each sample has 2 columns: one for SNV counts and one for total counts
# So the actual number of samples is half of the SNV count columns
total_samples <- length(snv_count_cols)
cat("Total SNV count columns:", length(snv_count_cols), "\n")
cat("Total count columns:", length(total_count_cols), "\n")
cat("Actual number of samples:", total_samples, "\n")

# Calculate 50% threshold
threshold_50_percent <- ceiling(total_samples * 0.5)
cat("50% representation threshold:", threshold_50_percent, "samples\n\n")

# Filter SNVs that appear in at least 50% of samples
filtered_data <- vaf_zscore_data %>%
  rowwise() %>%
  mutate(
    # Count non-zero values across SNV count columns only (not total count columns)
    non_zero_count = sum(c_across(all_of(snv_count_cols)) > 0, na.rm = TRUE),
    # Check if it meets 50% threshold
    passes_50_percent = non_zero_count >= threshold_50_percent
  ) %>%
  ungroup() %>%
  filter(passes_50_percent == TRUE)

cat("SNVs before 50% filter:", nrow(vaf_zscore_data), "\n")
cat("SNVs after 50% filter:", nrow(filtered_data), "\n")
cat("Percentage retained:", round(nrow(filtered_data)/nrow(vaf_zscore_data)*100, 1), "%\n\n")

# --- STEP 2: FILTER BY SEED REGION (POSITIONS 2-8) ---
cat("🌱 STEP 2: Filtering by seed region (positions 2-8)\n")
cat("===================================================\n")

seed_region_data <- filtered_data %>%
  mutate(
    position = as.numeric(str_extract(`pos.mut`, "^[0-9]+")),
    mutation = str_extract(`pos.mut`, "[A-Z]+$")
  ) %>%
  filter(
    position >= 2 & position <= 8,  # Seed region
    mutation == "GT"  # Only G>T mutations
  )

cat("SNVs in seed region with G>T:", nrow(seed_region_data), "\n")
cat("Unique miRNAs with G>T in seed region:", length(unique(seed_region_data$miRNA.name)), "\n\n")

# --- STEP 3: RANK miRNAs BY G>T COUNTS IN SEED REGION ---
cat("🏆 STEP 3: Ranking miRNAs by G>T counts in seed region\n")
cat("=====================================================\n")

# Calculate total G>T counts per miRNA in seed region
# First, let's get only the numeric columns for sample data
numeric_cols <- sapply(seed_region_data, is.numeric)
sample_numeric_cols <- names(numeric_cols)[numeric_cols & !names(numeric_cols) %in% c("position", "mean_vaf", "max_vaf", "mean_rpm")]

cat("Numeric columns found:", length(sample_numeric_cols), "\n")
cat("First 5 numeric columns:", head(sample_numeric_cols, 5), "\n")

# Let's check the data types of the first few columns
cat("Data types of first 5 columns:\n")
for(i in 1:min(5, length(sample_numeric_cols))) {
  col_name <- sample_numeric_cols[i]
  cat(col_name, ":", class(seed_region_data[[col_name]]), "\n")
}

# Calculate total G>T counts per miRNA in seed region using SNV count columns only
mirna_gt_counts <- seed_region_data %>%
  group_by(miRNA.name) %>%
  summarise(
    total_gt_seed = sum(across(all_of(snv_count_cols), ~ sum(.x, na.rm = TRUE)), na.rm = TRUE),
    snv_count = n(),
    .groups = 'drop'
  ) %>%
  arrange(desc(total_gt_seed))

cat("Top 10 miRNAs by G>T counts in seed region:\n")
print(head(mirna_gt_counts, 10))
cat("\n")

# --- STEP 4: GET RPM DATA FOR EACH miRNA ---
cat("📈 STEP 4: Getting RPM data for each miRNA\n")
cat("==========================================\n")

# Get RPM data from the original data (mean_rpm column already exists)
mirna_rpm_data <- vaf_zscore_data %>%
  group_by(miRNA.name) %>%
  summarise(
    mean_rpm = mean(mean_rpm, na.rm = TRUE),
    .groups = 'drop'
  )

# Combine G>T counts with RPM data
mirna_analysis <- mirna_gt_counts %>%
  left_join(mirna_rpm_data, by = "miRNA.name") %>%
  arrange(desc(total_gt_seed))

cat("Top 10 miRNAs with G>T counts and RPM:\n")
print(head(mirna_analysis, 10))
cat("\n")

# --- STEP 5: ANALYSIS AND VISUALIZATION ---
cat("📊 STEP 5: Analysis and Visualization\n")
cat("====================================\n")

# 1. Bar chart of top miRNAs by G>T counts in seed region
top_15_mirnas <- head(mirna_analysis, 15)

p1 <- ggplot(top_15_mirnas, aes(x = reorder(miRNA.name, total_gt_seed), y = total_gt_seed, fill = miRNA.name)) +
  geom_bar(stat = "identity", show.legend = FALSE) +
  geom_text(aes(label = total_gt_seed), hjust = -0.1, size = 3, fontface = "bold") +
  scale_fill_brewer(palette = "Set3") +
  coord_flip() +
  labs(
    title = "Top 15 miRNAs by G>T Counts in Seed Region",
    subtitle = "After 50% representation filter",
    x = "miRNA Name",
    y = "Total G>T Counts in Seed Region",
    caption = "Seed region: positions 2-8"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 12, color = "gray60"),
    axis.text = element_text(size = 10),
    axis.title = element_text(size = 11, face = "bold"),
    plot.caption = element_text(size = 9, color = "gray50", hjust = 0)
  )

ggsave(file.path(output_dir, "top_mirnas_gt_seed_region.png"), p1, width = 12, height = 8, dpi = 300)

# 2. Scatter plot: G>T counts vs RPM
p2 <- ggplot(mirna_analysis, aes(x = mean_rpm, y = total_gt_seed)) +
  geom_point(aes(color = total_gt_seed), size = 3, alpha = 0.7) +
  geom_smooth(method = "lm", se = TRUE, color = "red", linetype = "dashed") +
  scale_color_gradient(low = "blue", high = "red", name = "G>T Counts") +
  labs(
    title = "G>T Counts in Seed Region vs Mean RPM",
    subtitle = "Correlation between oxidative damage and expression level",
    x = "Mean RPM (Reads Per Million)",
    y = "Total G>T Counts in Seed Region",
    caption = "Each point represents one miRNA"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 12, color = "gray60"),
    axis.text = element_text(size = 10),
    axis.title = element_text(size = 11, face = "bold"),
    legend.position = "right",
    plot.caption = element_text(size = 9, color = "gray50", hjust = 0)
  )

ggsave(file.path(output_dir, "gt_counts_vs_rpm.png"), p2, width = 10, height = 6, dpi = 300)

# 3. Calculate correlation
correlation_result <- cor.test(mirna_analysis$mean_rpm, mirna_analysis$total_gt_seed, method = "pearson")
cat("Correlation between G>T counts and RPM:\n")
cat("Pearson r =", round(correlation_result$estimate, 3), "\n")
cat("P-value =", format(correlation_result$p.value, scientific = TRUE), "\n")
cat("Significant:", ifelse(correlation_result$p.value < 0.05, "Yes", "No"), "\n\n")

# 4. Summary statistics
cat("📊 SUMMARY STATISTICS\n")
cat("====================\n")
cat("Total miRNAs with G>T in seed region:", nrow(mirna_analysis), "\n")
cat("Mean G>T counts per miRNA:", round(mean(mirna_analysis$total_gt_seed), 0), "\n")
cat("Median G>T counts per miRNA:", round(median(mirna_analysis$total_gt_seed), 0), "\n")
cat("Mean RPM across all miRNAs:", round(mean(mirna_analysis$mean_rpm, na.rm = TRUE), 1), "\n")
cat("Median RPM across all miRNAs:", round(median(mirna_analysis$mean_rpm, na.rm = TRUE), 1), "\n\n")

# 5. Save results
write_tsv(mirna_analysis, file.path(output_table_dir, "mirna_gt_seed_region_analysis.tsv"))

cat("✅ ANALYSIS COMPLETE\n")
cat("===================\n")
cat("Generated files:\n")
cat("- top_mirnas_gt_seed_region.png: Bar chart of top miRNAs\n")
cat("- gt_counts_vs_rpm.png: Scatter plot of G>T vs RPM\n")
cat("- mirna_gt_seed_region_analysis.tsv: Complete analysis table\n\n")

cat("🎯 KEY FINDINGS\n")
cat("===============\n")
cat("1. After 50% representation filter:", nrow(filtered_data), "SNVs retained\n")
cat("2. G>T mutations in seed region:", nrow(seed_region_data), "SNVs\n")
cat("3. miRNAs with G>T in seed region:", nrow(mirna_analysis), "miRNAs\n")
cat("4. Top miRNA by G>T counts:", mirna_analysis$miRNA.name[1], "with", mirna_analysis$total_gt_seed[1], "counts\n")
cat("5. Correlation G>T vs RPM: r =", round(correlation_result$estimate, 3), "\n\n")
