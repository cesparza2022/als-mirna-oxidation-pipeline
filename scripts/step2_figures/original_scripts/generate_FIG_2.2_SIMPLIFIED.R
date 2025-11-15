#!/usr/bin/env Rscript
# ============================================================================
# FIGURE 2.2 SIMPLIFIED - DENSITY PLOT ONLY
# Comparison LINEAR vs LOG scale
# ============================================================================

library(ggplot2)
library(dplyr)
library(tidyr)
library(readr)
library(stringr)

# Colors
COLOR_ALS <- "#D62728"
COLOR_CONTROL <- "#666666"

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  FIGURE 2.2 - G>T VAF DENSITY PLOT\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# ============================================================================
# LOAD DATA
# ============================================================================

cat("📂 Loading data...\n")
data <- read_csv("final_processed_data_CLEAN.csv", show_col_types = FALSE)
metadata <- read_csv("metadata.csv", show_col_types = FALSE)
sample_cols <- metadata$Sample_ID

# Filter only G>T
vaf_gt_all <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  select(all_of(c("miRNA_name", "pos.mut", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  left_join(metadata, by = "Sample_ID")

# Total G>T VAF per sample
vaf_summary <- vaf_gt_all %>%
  group_by(Sample_ID, Group) %>%
  summarise(Total_GT_VAF = sum(VAF, na.rm = TRUE), .groups = "drop")

cat("   ✅ Data loaded and processed\n")
cat("   ✅ ALS samples:", sum(vaf_summary$Group == "ALS"), "\n")
cat("   ✅ Control samples:", sum(vaf_summary$Group == "Control"), "\n\n")

# ============================================================================
# WHAT DOES THIS PLOT TELL US?
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("💡 WHAT DOES THE DENSITY PLOT TELL US?\n")
cat("\n")
cat("INFORMATION IT PROVIDES:\n")
cat("\n")
cat("1. DISTRIBUTION SHAPE:\n")
cat("   • Is it normal (bell-shaped)?\n")
cat("   • Is it skewed?\n")
cat("   • Does it have multiple peaks (bimodal)?\n")
cat("   • Example: If Control is bimodal → May have subgroups\n")
cat("\n")
cat("2. PEAK POSITION:\n")
cat("   • Where is the peak for each group?\n")
cat("   • Does ALS have a higher or lower peak than Control?\n")
cat("   • Example: ALS peak to the left → Lower values\n")
cat("\n")
cat("3. SPREAD:\n")
cat("   • Which group has a wider distribution?\n")
cat("   • Greater spread → Greater variability between samples\n")
cat("   • Example: Control wider → Control more heterogeneous\n")
cat("\n")
cat("4. OVERLAP:\n")
cat("   • How much do the two distributions overlap?\n")
cat("   • High overlap → Similar groups\n")
cat("   • Low overlap → Well-separated groups\n")
cat("   • Example: 50% overlap → Some separation but not total\n")
cat("\n")
cat("DIFFERENCE WITH BOXPLOT (Fig 2.1 Panel B):\n")
cat("   • Boxplot: Shows median, quartiles, outliers\n")
cat("   • Density: Shows the ENTIRE shape of the distribution\n")
cat("   • Density detects: bimodality, asymmetry, tails\n")
cat("   • Boxplot is simpler, Density is more informative\n")
cat("\n")
cat("QUESTION IT ANSWERS:\n")
cat("   'Are the G>T VAF distributions DIFFERENT between ALS and Control?'\n")
cat("   'And in what aspects do they differ: position, shape, or spread?'\n")
cat("\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")

# ============================================================================
# STATISTICS
# ============================================================================

cat("📊 STATISTICS:\n\n")

# By group
stats_by_group <- vaf_summary %>%
  group_by(Group) %>%
  summarise(
    N = n(),
    Mean = mean(Total_GT_VAF),
    Median = median(Total_GT_VAF),
    SD = sd(Total_GT_VAF),
    Min = min(Total_GT_VAF),
    Max = max(Total_GT_VAF),
    Q25 = quantile(Total_GT_VAF, 0.25),
    Q75 = quantile(Total_GT_VAF, 0.75),
    .groups = "drop"
  )
print(stats_by_group)
cat("\n")

# Test
test_result <- wilcox.test(Total_GT_VAF ~ Group, data = vaf_summary)
cat("📊 Wilcoxon test: p =", format.pval(test_result$p.value, digits = 3), "\n\n")

# Calculate overlap (approximate)
als_vals <- vaf_summary %>% filter(Group == "ALS") %>% pull(Total_GT_VAF)
ctrl_vals <- vaf_summary %>% filter(Group == "Control") %>% pull(Total_GT_VAF)

overlap_min <- max(min(als_vals), min(ctrl_vals))
overlap_max <- min(max(als_vals), max(ctrl_vals))
overlap_prop <- (overlap_max - overlap_min) / (max(max(als_vals), max(ctrl_vals)) - min(min(als_vals), min(ctrl_vals)))

cat("📊 Approximate overlap:", round(overlap_prop * 100, 1), "%\n\n")

# ============================================================================
# PROFESSIONAL THEME
# ============================================================================

theme_prof <- theme_classic(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5, color = "gray40"),
    axis.title = element_text(face = "bold", size = 12),
    axis.text = element_text(size = 11),
    legend.position = c(0.85, 0.85),
    legend.background = element_rect(fill = "white", color = "gray80"),
    legend.title = element_text(face = "bold", size = 11),
    legend.text = element_text(size = 10),
    panel.grid.major = element_line(color = "gray90", linewidth = 0.3)
  )

# ============================================================================
# VERSION 1: LINEAR SCALE
# ============================================================================

cat("🎨 Generating LINEAR version...\n")

fig_linear <- ggplot(vaf_summary, aes(x = Total_GT_VAF, fill = Group, color = Group)) +
  geom_density(alpha = 0.4, linewidth = 1) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  scale_color_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  labs(
    title = "Distribution of Total G>T VAF per Sample",
    subtitle = paste0("Wilcoxon p = ", format.pval(test_result$p.value, digits = 3)),
    x = "Total G>T VAF (linear scale)",
    y = "Density",
    fill = "Group",
    color = "Group"
  ) +
  theme_prof +
  annotate("text", x = max(vaf_summary$Total_GT_VAF) * 0.7, 
           y = Inf, vjust = 1.5,
           label = paste0("Overlap: ~", round(overlap_prop * 100, 0), "%"),
           size = 4, color = "gray30")

ggsave("figures_step2_CLEAN/FIG_2.2_DENSITY_LINEAR.png", fig_linear, 
       width = 10, height = 6, dpi = 300, bg = "white")
cat("   ✅ LINEAR version saved\n\n")

# ============================================================================
# VERSION 2: LOG SCALE
# ============================================================================

cat("🎨 Generating LOG version...\n")

fig_log <- ggplot(vaf_summary, aes(x = Total_GT_VAF, fill = Group, color = Group)) +
  geom_density(alpha = 0.4, linewidth = 1) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  scale_color_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  scale_x_log10(labels = scales::comma) +
  labs(
    title = "Distribution of Total G>T VAF per Sample",
    subtitle = paste0("Wilcoxon p = ", format.pval(test_result$p.value, digits = 3)),
    x = "Total G>T VAF (LOG scale)",
    y = "Density",
    fill = "Group",
    color = "Group"
  ) +
  theme_prof +
  annotate("text", x = max(vaf_summary$Total_GT_VAF) * 0.3, 
           y = Inf, vjust = 1.5,
           label = paste0("Overlap: ~", round(overlap_prop * 100, 0), "%"),
           size = 4, color = "gray30")

ggsave("figures_step2_CLEAN/FIG_2.2_DENSITY_LOG.png", fig_log, 
       width = 10, height = 6, dpi = 300, bg = "white")
cat("   ✅ LOG version saved\n\n")

# ============================================================================
# SHAPE ANALYSIS
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("📊 DISTRIBUTION SHAPE ANALYSIS:\n\n")

# Skewness (asymmetry)
library(e1071)

skew_als <- skewness(als_vals)
skew_ctrl <- skewness(ctrl_vals)

cat("SKEWNESS:\n")
cat("   ALS:", round(skew_als, 3), ifelse(skew_als > 0, "(right-skewed)", "(left-skewed)"), "\n")
cat("   Control:", round(skew_ctrl, 3), ifelse(skew_ctrl > 0, "(right-skewed)", "(left-skewed)"), "\n")
cat("   Interpretation: >0 = long right tail, <0 = long left tail\n\n")

# Kurtosis (peak shape)
kurt_als <- kurtosis(als_vals)
kurt_ctrl <- kurtosis(ctrl_vals)

cat("KURTOSIS:\n")
cat("   ALS:", round(kurt_als, 3), "\n")
cat("   Control:", round(kurt_ctrl, 3), "\n")
cat("   Interpretation: >0 = sharp peaks, <0 = flat peaks\n\n")

# Coefficient of variation
cv_als <- sd(als_vals) / mean(als_vals) * 100
cv_ctrl <- sd(ctrl_vals) / mean(ctrl_vals) * 100

cat("COEFFICIENT OF VARIATION:\n")
cat("   ALS:", round(cv_als, 1), "%\n")
cat("   Control:", round(cv_ctrl, 1), "%\n")
cat("   Interpretation: Higher % = greater relative variability\n\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")

# ============================================================================
# COMPARISON AND RECOMMENDATION
# ============================================================================

cat("📊 LINEAR vs LOG COMPARISON:\n\n")

range_vals <- range(vaf_summary$Total_GT_VAF)
fold_diff <- range_vals[2] / range_vals[1]

cat("RANGE:", sprintf("%.3f to %.2f", range_vals[1], range_vals[2]), "\n")
cat("Fold difference:", sprintf("%.0f-fold", fold_diff), "\n\n")

if (fold_diff > 100) {
  cat("✅ RECOMMENDATION: LOG SCALE\n")
  cat("   Reason: Very wide range (>100-fold)\n")
} else if (fold_diff > 10) {
  cat("⚠️  LOG SCALE probably better\n")
  cat("   Reason: Moderate range (10-100 fold)\n")
} else {
  cat("✅ RECOMMENDATION: LINEAR SCALE\n")
  cat("   Reason: Small range (<10-fold)\n")
}

cat("\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("✅ TWO VERSIONS GENERATED:\n")
cat("   1. FIG_2.2_DENSITY_LINEAR.png\n")
cat("   2. FIG_2.2_DENSITY_LOG.png\n")
cat("\n")
cat("📊 Compare both and decide!\n")
cat("\n")
