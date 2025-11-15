#!/usr/bin/env Rscript
# ============================================================================
# FIGURE 2.1 - COMPARISON LOG vs LINEAR SCALE
# Also: Clarify differences between Panel B and Panel C
# ============================================================================

library(ggplot2)
library(dplyr)
library(tidyr)
library(stringr)
library(patchwork)
library(readr)

# Colors
COLOR_ALS <- "#D62728"
COLOR_CONTROL <- "#666666"

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  FIGURE 2.1 - CLARIFICATION AND COMPARISON\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# ============================================================================
# LOAD DATA
# ============================================================================

cat("📂 Loading data...\n")
data <- read_csv("final_processed_data_CLEAN.csv", show_col_types = FALSE)
metadata <- read_csv("metadata.csv", show_col_types = FALSE)

sample_cols <- metadata$Sample_ID

cat("   ✅ Data loaded\n")
cat("   ✅ ALS samples:", sum(metadata$Group == "ALS"), "\n")
cat("   ✅ Control samples:", sum(metadata$Group == "Control"), "\n\n")

# ============================================================================
# CALCULATE METRICS
# ============================================================================

cat("🔢 Calculating metrics...\n\n")

# Total VAF per sample (ALL mutations)
cat("   PANEL A: Total VAF (sum of ALL VAFs)\n")
vaf_total <- data %>%
  select(all_of(c("miRNA_name", "pos.mut", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  group_by(Sample_ID) %>%
  summarise(Total_VAF = sum(VAF, na.rm = TRUE), .groups = "drop") %>%
  left_join(metadata, by = "Sample_ID")

cat("   ✅ Total VAF calculated\n")
cat("      Example: If a sample has 100 SNVs with average VAF 0.01\n")
cat("               Total_VAF = 100 × 0.01 = 1.0\n\n")

# G>T VAF per sample
cat("   PANEL B: G>T VAF (sum of VAF only from G>T mutations)\n")
vaf_gt <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%  # ONLY G>T
  select(all_of(c("miRNA_name", "pos.mut", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  group_by(Sample_ID) %>%
  summarise(GT_VAF = sum(VAF, na.rm = TRUE), .groups = "drop")

cat("   ✅ G>T VAF calculated\n")
cat("      Example: If a sample has 50 G>T SNVs with average VAF 0.01\n")
cat("               GT_VAF = 50 × 0.01 = 0.5\n\n")

# Combine
combined_data <- vaf_total %>%
  left_join(vaf_gt, by = "Sample_ID") %>%
  replace_na(list(GT_VAF = 0)) %>%
  mutate(
    GT_Ratio = GT_VAF / Total_VAF,
    GT_Ratio = replace_na(GT_Ratio, 0)
  )

cat("   PANEL C: G>T Ratio (G>T_VAF / Total_VAF)\n")
cat("   ✅ Ratio calculated\n")
cat("      Example: If Total_VAF = 1.0 and GT_VAF = 0.5\n")
cat("               GT_Ratio = 0.5 / 1.0 = 0.5 (50%)\n\n")

# ============================================================================
# CLARIFICATION: What each metric means
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("💡 METRIC CLARIFICATION:\n")
cat("\n")
cat("PANEL A: Total_VAF = Sum of ALL VAFs\n")
cat("   • Includes: GT, GC, GA, CT, CA, TA, etc. (12 types)\n")
cat("   • Unit: Sum of proportions (NOT a percentage from 0-100%)\n")
cat("   • Typical range: 0.1 to 10+ (depends on how many SNVs)\n")
cat("   • Interpretation: TOTAL burden of mutations in the sample\n")
cat("\n")
cat("PANEL B: GT_VAF = Sum of VAF only from G>T\n")
cat("   • Includes: ONLY G>T mutations\n")
cat("   • Unit: Sum of proportions\n")
cat("   • Typical range: 0.05 to 5+ (subset of Panel A)\n")
cat("   • Interpretation: Specific OXIDATION burden\n")
cat("   • Relationship: GT_VAF ≤ Total_VAF (always)\n")
cat("\n")
cat("PANEL C: GT_Ratio = GT_VAF / Total_VAF\n")
cat("   • Calculation: Proportion of G>T relative to total\n")
cat("   • Unit: Fraction (0 to 1, or 0% to 100%)\n")
cat("   • Typical range: 0.3 to 0.9 (30% to 90%)\n")
cat("   • Interpretation: OXIDATION specificity\n")
cat("   • Difference with individual VAF: This is NOT the VAF of a single SNV,\n")
cat("     it is the SUM of G>T VAFs divided by TOTAL sum of VAFs\n")
cat("\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")

# ============================================================================
# CLARIFICATION 2: Panel B vs Panel C
# ============================================================================

cat("🤔 DIFFERENCE BETWEEN PANEL B vs PANEL C:\n")
cat("\n")
cat("PANEL B: GT_VAF (absolute value)\n")
cat("   • Question: How much G>T is there in the sample? (sum)\n")
cat("   • Unit: Sum of VAF (can be 0.5, 1.0, 5.0, etc.)\n")
cat("   • Depends on: Number of G>T SNVs AND their frequencies\n")
cat("   • Example: Sample with 100 G>T SNVs (VAF=0.01 each) → GT_VAF = 1.0\n")
cat("\n")
cat("PANEL C: GT_Ratio (relative value)\n")
cat("   • Question: What PROPORTION of total mutations is G>T?\n")
cat("   • Unit: Fraction (0-1 or 0%-100%)\n")
cat("   • Independent of: Total number of SNVs\n")
cat("   • Example: Sample with GT_VAF=1.0 and Total_VAF=2.0 → GT_Ratio = 0.5 (50%)\n")
cat("\n")
cat("WHY THEY ARE DIFFERENT:\n")
cat("   • Panel B can be HIGH simply because there are many SNVs\n")
cat("   • Panel C normalizes by total → Shows SELECTIVITY\n")
cat("\n")
cat("CONCRETE EXAMPLE:\n")
cat("   Sample A: Total_VAF=10, GT_VAF=8  → GT_Ratio=0.8 (80% is G>T)\n")
cat("   Sample B: Total_VAF=2,  GT_VAF=1.5 → GT_Ratio=0.75 (75% is G>T)\n")
cat("\n")
cat("   • Sample A has MORE absolute G>T (Panel B: 8 vs 1.5)\n")
cat("   • But Sample A also has GREATER specificity (Panel C: 80% vs 75%)\n")
cat("\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")

# Stats
cat("📊 STATISTICS BY GROUP:\n\n")
stats_summary <- combined_data %>%
  group_by(Group) %>%
  summarise(
    N = n(),
    Mean_Total_VAF = mean(Total_VAF),
    Median_Total_VAF = median(Total_VAF),
    Mean_GT_VAF = mean(GT_VAF),
    Median_GT_VAF = median(GT_VAF),
    Mean_GT_Ratio = mean(GT_Ratio),
    Median_GT_Ratio = median(GT_Ratio),
    .groups = "drop"
  )
print(stats_summary)
cat("\n")

# Tests
test_total <- wilcox.test(Total_VAF ~ Group, data = combined_data)
test_gt <- wilcox.test(GT_VAF ~ Group, data = combined_data)
test_ratio <- wilcox.test(GT_Ratio ~ Group, data = combined_data)

cat("📊 TESTS (Wilcoxon):\n")
cat("   Panel A (Total VAF): p =", format.pval(test_total$p.value, digits = 3), "\n")
cat("   Panel B (G>T VAF): p =", format.pval(test_gt$p.value, digits = 3), "\n")
cat("   Panel C (G>T Ratio): p =", format.pval(test_ratio$p.value, digits = 3), "\n\n")

# ============================================================================
# VERSION 1: LINEAR SCALE
# ============================================================================

cat("🎨 Version 1: LINEAR SCALE...\n")

theme_prof <- theme_classic(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5, color = "gray40"),
    axis.title = element_text(face = "bold", size = 11),
    axis.text = element_text(size = 10),
    legend.position = "none",
    panel.grid.major.y = element_line(color = "gray90", linewidth = 0.3)
  )

# Panel A - Linear
panel_a_linear <- ggplot(combined_data, aes(x = Group, y = Total_VAF, fill = Group)) +
  geom_boxplot(alpha = 0.7, outlier.shape = NA, width = 0.6) +
  geom_jitter(width = 0.15, alpha = 0.3, size = 1.2) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  labs(
    title = "A. Total VAF per Sample",
    subtitle = paste0("Wilcoxon p = ", format.pval(test_total$p.value, digits = 3)),
    x = NULL,
    y = "Total VAF (linear scale)"
  ) +
  theme_prof +
  annotate("text", x = 1.5, y = max(combined_data$Total_VAF, na.rm = TRUE) * 0.95,
           label = ifelse(test_total$p.value < 0.05, "***", "ns"),
           size = 6, color = ifelse(test_total$p.value < 0.05, "red", "gray50"))

# Panel B - Linear
panel_b_linear <- ggplot(combined_data, aes(x = Group, y = GT_VAF, fill = Group)) +
  geom_boxplot(alpha = 0.7, outlier.shape = NA, width = 0.6) +
  geom_jitter(width = 0.15, alpha = 0.3, size = 1.2) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  labs(
    title = "B. G>T VAF per Sample",
    subtitle = paste0("Wilcoxon p = ", format.pval(test_gt$p.value, digits = 3)),
    x = NULL,
    y = "G>T VAF (linear scale)"
  ) +
  theme_prof +
  annotate("text", x = 1.5, y = max(combined_data$GT_VAF, na.rm = TRUE) * 0.95,
           label = ifelse(test_gt$p.value < 0.05, "***", "ns"),
           size = 6, color = ifelse(test_gt$p.value < 0.05, "red", "gray50"))

# Panel C - Already linear (ratio 0-1)
panel_c_linear <- ggplot(combined_data, aes(x = Group, y = GT_Ratio, fill = Group)) +
  geom_boxplot(alpha = 0.7, outlier.shape = NA, width = 0.6) +
  geom_jitter(width = 0.15, alpha = 0.3, size = 1.2) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  scale_y_continuous(labels = scales::percent) +
  labs(
    title = "C. G>T Specificity (Fraction)",
    subtitle = paste0("Wilcoxon p = ", format.pval(test_ratio$p.value, digits = 3)),
    x = NULL,
    y = "G>T / Total VAF (%)"
  ) +
  theme_prof +
  annotate("text", x = 1.5, y = max(combined_data$GT_Ratio, na.rm = TRUE) * 0.95,
           label = ifelse(test_ratio$p.value < 0.05, "***", "ns"),
           size = 6, color = ifelse(test_ratio$p.value < 0.05, "red", "gray50"))

# Combine
fig_linear <- (panel_a_linear | panel_b_linear | panel_c_linear)
ggsave("figures_step2_CLEAN/FIG_2.1_LINEAR_SCALE.png", fig_linear, width = 15, height = 5, dpi = 300, bg = "white")
cat("   ✅ LINEAR version saved\n\n")

# ============================================================================
# VERSION 2: LOG SCALE
# ============================================================================

cat("🎨 Version 2: LOG SCALE...\n")

# Panel A - Log
panel_a_log <- ggplot(combined_data, aes(x = Group, y = Total_VAF, fill = Group)) +
  geom_boxplot(alpha = 0.7, outlier.shape = NA, width = 0.6) +
  geom_jitter(width = 0.15, alpha = 0.3, size = 1.2) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  scale_y_log10(labels = scales::comma) +
  labs(
    title = "A. Total VAF per Sample",
    subtitle = paste0("Wilcoxon p = ", format.pval(test_total$p.value, digits = 3)),
    x = NULL,
    y = "Total VAF (LOG scale)"
  ) +
  theme_prof +
  annotate("text", x = 1.5, y = max(combined_data$Total_VAF, na.rm = TRUE) * 0.7,
           label = ifelse(test_total$p.value < 0.05, "***", "ns"),
           size = 6, color = ifelse(test_total$p.value < 0.05, "red", "gray50"))

# Panel B - Log
panel_b_log <- ggplot(combined_data, aes(x = Group, y = GT_VAF, fill = Group)) +
  geom_boxplot(alpha = 0.7, outlier.shape = NA, width = 0.6) +
  geom_jitter(width = 0.15, alpha = 0.3, size = 1.2) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  scale_y_log10(labels = scales::comma) +
  labs(
    title = "B. G>T VAF per Sample",
    subtitle = paste0("Wilcoxon p = ", format.pval(test_gt$p.value, digits = 3)),
    x = NULL,
    y = "G>T VAF (LOG scale)"
  ) +
  theme_prof +
  annotate("text", x = 1.5, y = max(combined_data$GT_VAF, na.rm = TRUE) * 0.7,
           label = ifelse(test_gt$p.value < 0.05, "***", "ns"),
           size = 6, color = ifelse(test_gt$p.value < 0.05, "red", "gray50"))

# Panel C - Same (already linear)
panel_c_log <- panel_c_linear

# Combine
fig_log <- (panel_a_log | panel_b_log | panel_c_log)
ggsave("figures_step2_CLEAN/FIG_2.1_LOG_SCALE.png", fig_log, width = 15, height = 5, dpi = 300, bg = "white")
cat("   ✅ LOG version saved\n\n")

# ============================================================================
# COMPARISON AND RECOMMENDATION
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("📊 LOG vs LINEAR COMPARISON:\n")
cat("\n")

# Calculate value ranges
range_total <- range(combined_data$Total_VAF, na.rm = TRUE)
range_gt <- range(combined_data$GT_VAF, na.rm = TRUE)
fold_diff_total <- range_total[2] / range_total[1]
fold_diff_gt <- range_gt[2] / range_gt[1]

cat("VALUE RANGES:\n")
cat("   Panel A (Total VAF):", sprintf("%.4f to %.2f", range_total[1], range_total[2]), "\n")
cat("   Panel B (G>T VAF):", sprintf("%.4f to %.2f", range_gt[1], range_gt[2]), "\n")
cat("   Fold difference Total:", sprintf("%.0f-fold", fold_diff_total), "\n")
cat("   Fold difference G>T:", sprintf("%.0f-fold", fold_diff_gt), "\n")
cat("\n")

cat("RECOMMENDATION:\n")
if (fold_diff_total > 100 | fold_diff_gt > 100) {
  cat("   ✅ USE LOG SCALE\n")
  cat("   Reason: Value range > 100-fold\n")
  cat("   With linear scale, low values would not be visible\n")
} else if (fold_diff_total > 10 | fold_diff_gt > 10) {
  cat("   ⚠️  LOG SCALE RECOMMENDED but not essential\n")
  cat("   Reason: Range 10-100 fold\n")
  cat("   Linear would work but log is clearer\n")
} else {
  cat("   ✅ USE LINEAR SCALE\n")
  cat("   Reason: Value range < 10-fold\n")
  cat("   Linear scale is more intuitive\n")
}
cat("\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("✅ TWO VERSIONS GENERATED:\n")
cat("   1. FIG_2.1_LINEAR_SCALE.png (linear scale)\n")
cat("   2. FIG_2.1_LOG_SCALE.png (log scale)\n")
cat("\n")
cat("📊 Compare both and decide which communicates better!\n")
cat("\n")
