#!/usr/bin/env Rscript

# ============================================================================
# 🎯 STEP 1: DIAGNOSTIC FIGURES - ALL MUTATIONS
# ============================================================================
# Purpose: Complete dataset characterization
# - All 12 mutation types (AT,AG,AC,GC,GT,GA,CG,CA,CT,TA,TG,TC)
# - SNVs and Counts analysis
# - By sample and by position
# - G>T highlighted as oxidation signature

library(ggplot2)
library(dplyr)
library(tidyr)
library(patchwork)
library(tibble)
library(scales)

cat("╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║     🎯 STEP 1: DIAGNOSTIC FIGURES - ALL MUTATIONS                   ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

# Set working directory
base_dir <- "/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/pipeline_definitivo/01_analisis_inicial"
setwd(base_dir)

output_dir <- "figures"
data_dir <- "/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/tercer_intento/step_by_step_analysis"

# ============================================================================
# 1. LOAD AND PREPARE DATA
# ============================================================================

cat("📊 Loading original data...\n")
data_path <- file.path(data_dir, "step1_original_data.csv")

data <- read.csv(data_path, check.names = FALSE)

# Clean and extract info
data_clean <- data %>%
  filter(`pos:mut` != "PM") %>%
  mutate(
    miRNA = `miRNA name`,
    pos_mut = `pos:mut`,
    Position = as.numeric(gsub(":.*", "", pos_mut)),
    Mutation_Type = gsub(".*:", "", pos_mut),
    Mutation_Type = gsub('"', '', Mutation_Type),
    Region = ifelse(Position >= 2 & Position <= 8, "Seed", "Non-Seed")
  ) %>%
  filter(!is.na(Position), Mutation_Type != "")

cat(sprintf("   ✅ Total rows: %s\n", comma(nrow(data_clean))))
cat(sprintf("   ✅ Unique mutation types: %d\n", length(unique(data_clean$Mutation_Type))))

# Get sample columns
sample_cols <- setdiff(names(data), c("miRNA name", "pos:mut"))
cat(sprintf("   ✅ Samples: %d\n", length(sample_cols)))

# Convert to long format
cat("\n📊 Converting to long format...\n")
data_long <- data_clean %>%
  select(miRNA, Position, Mutation_Type, Region, all_of(sample_cols)) %>%
  pivot_longer(
    cols = all_of(sample_cols),
    names_to = "Sample",
    values_to = "Count"
  ) %>%
  filter(!is.na(Count), Count > 0)

cat(sprintf("   ✅ Long format: %s rows\n", comma(nrow(data_long))))

# Calculate metrics by sample and type
sample_metrics <- data_long %>%
  group_by(Sample, Mutation_Type) %>%
  summarise(
    N_SNVs = n(),
    Total_Counts = sum(Count),
    Mean_Count = mean(Count),
    SD_Count = sd(Count),
    Max_Count = max(Count),
    .groups = "drop"
  )

# Calculate metrics by position and type
position_metrics <- data_long %>%
  group_by(Position, Mutation_Type) %>%
  summarise(
    N_SNVs = n(),
    Total_Counts = sum(Count),
    Mean_Count = mean(Count),
    SD_Count = sd(Count),
    .groups = "drop"
  )

cat(sprintf("   ✅ Sample metrics: %s rows\n", comma(nrow(sample_metrics))))
cat(sprintf("   ✅ Position metrics: %d rows\n", nrow(position_metrics)))

# ============================================================================
# 2. FIGURE 1: HEATMAP - SNVs BY POSITION (ALL 12 MUTATIONS)
# ============================================================================

cat("\n🎨 Generating Figure 1: Heatmap SNVs (All mutations)...\n")

# Ensure all mutations present
all_types <- c("AT", "AG", "AC", "GC", "GT", "GA", "CG", "CA", "CT", "TA", "TG", "TC")
position_all <- position_metrics %>%
  complete(Position, Mutation_Type = all_types, fill = list(N_SNVs = 0, Total_Counts = 0))

# Order by frequency
type_order <- position_all %>%
  group_by(Mutation_Type) %>%
  summarise(Total = sum(N_SNVs, na.rm = TRUE)) %>%
  arrange(desc(Total)) %>%
  pull(Mutation_Type)

position_all$Mutation_Type <- factor(position_all$Mutation_Type, levels = type_order)

fig1 <- ggplot(position_all, aes(x = factor(Position), y = Mutation_Type, fill = N_SNVs)) +
  geom_tile(color = "white", size = 0.8) +
  geom_text(aes(label = ifelse(N_SNVs > 200, round(N_SNVs, 0), "")), 
            color = "white", fontface = "bold", size = 3) +
  scale_fill_gradient2(
    low = "white", mid = "#FF7F0E", high = "#D62728",
    midpoint = median(position_all$N_SNVs[position_all$N_SNVs > 0]),
    name = "# SNVs",
    labels = comma
  ) +
  theme_minimal(base_size = 13) +
  theme(
    axis.text.x = element_text(angle = 0, hjust = 0.5, face = "bold", size = 12),
    axis.text.y = element_text(face = "bold", size = 13, 
                              color = ifelse(levels(position_all$Mutation_Type) == "GT", "#D62728", "black")),
    axis.title = element_text(face = "bold", size = 15),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 17),
    plot.subtitle = element_text(hjust = 0.5, size = 13, color = "gray40"),
    panel.grid = element_blank(),
    legend.position = "right",
    legend.title = element_text(face = "bold", size = 12)
  ) +
  labs(
    title = "FIGURE 1: SNVs by Position - All Mutations",
    subtitle = "12 mutation types | G>T highlighted in red",
    x = "Position",
    y = "Mutation Type"
  )

ggsave(file.path(output_dir, "STEP1_FIG1_HEATMAP_SNVS_ALL.png"), 
       fig1, width = 16, height = 10, dpi = 150)
cat("   ✅ Saved: STEP1_FIG1_HEATMAP_SNVS_ALL.png\n")

# ============================================================================
# 3. FIGURE 2: HEATMAP - COUNTS BY POSITION (ALL 12 MUTATIONS)
# ============================================================================

cat("\n🎨 Generating Figure 2: Heatmap Counts (All mutations)...\n")

fig2 <- ggplot(position_all, aes(x = factor(Position), y = Mutation_Type, fill = log10(Total_Counts + 1))) +
  geom_tile(color = "white", size = 0.8) +
  scale_fill_gradient2(
    low = "white", mid = "#9467BD", high = "#D62728",
    midpoint = median(log10(position_all$Total_Counts[position_all$Total_Counts > 0] + 1)),
    name = "log10(Counts)",
    labels = comma
  ) +
  theme_minimal(base_size = 13) +
  theme(
    axis.text.x = element_text(angle = 0, hjust = 0.5, face = "bold", size = 12),
    axis.text.y = element_text(face = "bold", size = 13,
                              color = ifelse(levels(position_all$Mutation_Type) == "GT", "#D62728", "black")),
    axis.title = element_text(face = "bold", size = 15),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 17),
    plot.subtitle = element_text(hjust = 0.5, size = 13, color = "gray40"),
    panel.grid = element_blank(),
    legend.position = "right",
    legend.title = element_text(face = "bold", size = 12)
  ) +
  labs(
    title = "FIGURE 2: Total Counts by Position - All Mutations",
    subtitle = "Sequencing depth | Log scale | G>T highlighted",
    x = "Position",
    y = "Mutation Type"
  )

ggsave(file.path(output_dir, "STEP1_FIG2_HEATMAP_COUNTS_ALL.png"), 
       fig2, width = 16, height = 10, dpi = 150)
cat("   ✅ Saved: STEP1_FIG2_HEATMAP_COUNTS_ALL.png\n")

# ============================================================================
# 4. FIGURE 3: G>T vs G>A vs G>C - SNVs
# ============================================================================

cat("\n🎨 Generating Figure 3: G transversions - SNVs...\n")

g_only <- position_all %>%
  filter(Mutation_Type %in% c("GT", "GA", "GC"))

fig3 <- ggplot(g_only, aes(x = factor(Position), y = N_SNVs, fill = Mutation_Type)) +
  geom_bar(stat = "identity", position = "dodge", alpha = 0.85, width = 0.8) +
  geom_text(aes(label = ifelse(N_SNVs > 100, round(N_SNVs, 0), "")), 
            position = position_dodge(width = 0.8), vjust = -0.5, 
            fontface = "bold", size = 3) +
  scale_fill_manual(
    values = c("GT" = "#D62728", "GA" = "#1F77B4", "GC" = "#2CA02C"),
    labels = c("GT" = "G>T (Oxidation)", "GA" = "G>A", "GC" = "G>C"),
    name = "Mutation Type"
  ) +
  theme_classic(base_size = 14) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold", size = 12),
    axis.title = element_text(face = "bold", size = 15),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 17),
    plot.subtitle = element_text(hjust = 0.5, size = 13, color = "gray40"),
    legend.position = "bottom",
    legend.title = element_text(face = "bold", size = 13),
    legend.text = element_text(size = 12)
  ) +
  labs(
    title = "FIGURE 3: G Transversions Comparison - SNVs by Position",
    subtitle = "G>T vs G>A vs G>C | Number of mutations",
    x = "Position",
    y = "Number of SNVs"
  )

ggsave(file.path(output_dir, "STEP1_FIG3_G_TRANSVERSIONS_SNVS.png"), 
       fig3, width = 16, height = 9, dpi = 150)
cat("   ✅ Saved: STEP1_FIG3_G_TRANSVERSIONS_SNVS.png\n")

# ============================================================================
# 5. FIGURE 4: G>T vs G>A vs G>C - COUNTS
# ============================================================================

cat("\n🎨 Generating Figure 4: G transversions - Counts...\n")

fig4 <- ggplot(g_only, aes(x = factor(Position), y = Total_Counts, fill = Mutation_Type)) +
  geom_bar(stat = "identity", position = "dodge", alpha = 0.85, width = 0.8) +
  scale_fill_manual(
    values = c("GT" = "#D62728", "GA" = "#1F77B4", "GC" = "#2CA02C"),
    labels = c("GT" = "G>T (Oxidation)", "GA" = "G>A", "GC" = "G>C"),
    name = "Mutation Type"
  ) +
  scale_y_continuous(labels = comma) +
  theme_classic(base_size = 14) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold", size = 12),
    axis.title = element_text(face = "bold", size = 15),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 17),
    plot.subtitle = element_text(hjust = 0.5, size = 13, color = "gray40"),
    legend.position = "bottom",
    legend.title = element_text(face = "bold", size = 13),
    legend.text = element_text(size = 12)
  ) +
  labs(
    title = "FIGURE 4: G Transversions Comparison - Counts by Position",
    subtitle = "G>T vs G>A vs G>C | Sequencing depth",
    x = "Position",
    y = "Total Counts"
  )

ggsave(file.path(output_dir, "STEP1_FIG4_G_TRANSVERSIONS_COUNTS.png"), 
       fig4, width = 16, height = 9, dpi = 150)
cat("   ✅ Saved: STEP1_FIG4_G_TRANSVERSIONS_COUNTS.png\n")

# ============================================================================
# 6. FIGURE 5: BUBBLE PLOT (SNVs vs Counts with Variability)
# ============================================================================

cat("\n🎨 Generating Figure 5: Bubble Plot...\n")

bubble_data <- sample_metrics %>%
  group_by(Mutation_Type) %>%
  summarise(
    Mean_SNVs = mean(N_SNVs),
    SD_SNVs = sd(N_SNVs),
    Mean_Counts = mean(Total_Counts),
    SD_Counts = sd(Total_Counts),
    N_Samples = n(),
    .groups = "drop"
  ) %>%
  mutate(
    Is_GT = Mutation_Type == "GT",
    Category = case_when(
      Mutation_Type == "GT" ~ "G>T (Oxidation)",
      Mutation_Type %in% c("GA", "GC") ~ "Other G transv.",
      TRUE ~ "Other mutations"
    )
  )

fig5 <- ggplot(bubble_data, aes(x = Mean_SNVs, y = Mean_Counts, 
                                 size = SD_SNVs, color = Category, shape = Is_GT)) +
  geom_point(alpha = 0.75) +
  geom_text(aes(label = Mutation_Type), vjust = -2, fontface = "bold", size = 5, show.legend = FALSE) +
  scale_size_continuous(range = c(8, 30), name = "SD of SNVs\n(Variability across samples)") +
  scale_color_manual(
    values = c("G>T (Oxidation)" = "#D62728", "Other G transv." = "#FF7F0E", "Other mutations" = "gray50"),
    name = "Category"
  ) +
  scale_shape_manual(values = c("TRUE" = 18, "FALSE" = 16), guide = "none") +
  scale_x_continuous(labels = comma) +
  scale_y_continuous(labels = comma) +
  theme_classic(base_size = 14) +
  theme(
    axis.title = element_text(face = "bold", size = 15),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 17),
    plot.subtitle = element_text(hjust = 0.5, size = 13, color = "gray40"),
    legend.position = "bottom",
    legend.box = "vertical",
    legend.title = element_text(face = "bold", size = 12)
  ) +
  labs(
    title = "FIGURE 5: SNVs vs Counts by Mutation Type",
    subtitle = "Size = Standard Deviation (variability across samples) | G>T = Red diamond",
    x = "Mean SNVs per Sample",
    y = "Mean Total Counts per Sample"
  )

ggsave(file.path(output_dir, "STEP1_FIG5_BUBBLE_PLOT.png"), 
       fig5, width = 14, height = 11, dpi = 150)
cat("   ✅ Saved: STEP1_FIG5_BUBBLE_PLOT.png\n")

# ============================================================================
# 7. FIGURE 6: VIOLIN PLOTS (COMPLETE DISTRIBUTIONS)
# ============================================================================

cat("\n🎨 Generating Figure 6: Violin Plots...\n")

# Top 8 types
top8 <- bubble_data %>% arrange(desc(Mean_SNVs)) %>% slice(1:8) %>% pull(Mutation_Type)

sample_top8 <- sample_metrics %>%
  filter(Mutation_Type %in% top8) %>%
  mutate(
    Mutation_Type = factor(Mutation_Type, levels = rev(top8)),
    Category = case_when(
      Mutation_Type == "GT" ~ "G>T (Oxidation)",
      Mutation_Type %in% c("GA", "GC") ~ "Other G transv.",
      TRUE ~ "Other mutations"
    )
  )

# Panel A: SNVs
p_viol_snvs <- ggplot(sample_top8, aes(x = Mutation_Type, y = N_SNVs, fill = Category)) +
  geom_violin(alpha = 0.7, trim = FALSE) +
  geom_boxplot(width = 0.2, alpha = 0.8, outlier.size = 0.5) +
  stat_summary(fun = mean, geom = "point", shape = 23, size = 3.5, fill = "white", color = "black") +
  scale_fill_manual(
    values = c("G>T (Oxidation)" = "#D62728", "Other G transv." = "#FF7F0E", "Other mutations" = "gray60"),
    name = ""
  ) +
  coord_flip() +
  theme_classic(base_size = 13) +
  theme(
    axis.title = element_text(face = "bold", size = 14),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 15),
    plot.subtitle = element_text(hjust = 0.5, size = 11, color = "gray40"),
    legend.position = "top"
  ) +
  labs(
    title = "A. SNVs Distribution per Sample (Top 8 Types)",
    subtitle = "Violin + Boxplot + Mean (white diamond)",
    y = "# SNVs per Sample",
    x = "Mutation Type"
  )

# Panel B: Counts
p_viol_counts <- ggplot(sample_top8, aes(x = Mutation_Type, y = Total_Counts, fill = Category)) +
  geom_violin(alpha = 0.7, trim = FALSE) +
  geom_boxplot(width = 0.2, alpha = 0.8, outlier.size = 0.5) +
  stat_summary(fun = mean, geom = "point", shape = 23, size = 3.5, fill = "white", color = "black") +
  scale_fill_manual(
    values = c("G>T (Oxidation)" = "#D62728", "Other G transv." = "#FF7F0E", "Other mutations" = "gray60"),
    name = ""
  ) +
  scale_y_log10(labels = comma) +
  coord_flip() +
  theme_classic(base_size = 13) +
  theme(
    axis.title = element_text(face = "bold", size = 14),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 15),
    plot.subtitle = element_text(hjust = 0.5, size = 11, color = "gray40"),
    legend.position = "top"
  ) +
  labs(
    title = "B. Counts Distribution per Sample (log scale)",
    subtitle = "Violin + Boxplot + Mean (white diamond)",
    y = "Total Counts per Sample",
    x = "Mutation Type"
  )

fig6 <- p_viol_snvs / p_viol_counts +
  plot_annotation(
    title = "FIGURE 6: Complete Distributions by Sample",
    subtitle = "Integral visualization: distribution + quartiles + mean",
    theme = theme(
      plot.title = element_text(size = 17, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray40")
    )
  )

ggsave(file.path(output_dir, "STEP1_FIG6_VIOLIN_DISTRIBUTIONS.png"), 
       fig6, width = 14, height = 11, dpi = 150)
cat("   ✅ Saved: STEP1_FIG6_VIOLIN_DISTRIBUTIONS.png\n")

# ============================================================================
# 8. FIGURE 7: FOLD CHANGE vs G>T (INTEGRATED)
# ============================================================================

cat("\n🎨 Generating Figure 7: Fold Change Integrated...\n")

# Calculate fold vs GT
gt_baseline <- bubble_data %>% filter(Mutation_Type == "GT")

fold_data <- bubble_data %>%
  mutate(
    Fold_SNVs = Mean_SNVs / gt_baseline$Mean_SNVs,
    Fold_Counts = Mean_Counts / gt_baseline$Mean_Counts
  ) %>%
  arrange(desc(Fold_SNVs))

fold_long <- fold_data %>%
  slice(1:10) %>%
  select(Mutation_Type, Category, Fold_SNVs, Fold_Counts) %>%
  pivot_longer(
    cols = c(Fold_SNVs, Fold_Counts),
    names_to = "Metric",
    values_to = "Fold"
  ) %>%
  mutate(
    Metric = factor(Metric, levels = c("Fold_SNVs", "Fold_Counts"),
                   labels = c("Fold SNVs", "Fold Counts"))
  )

fig7 <- ggplot(fold_long, aes(x = reorder(Mutation_Type, -Fold), y = Fold, fill = Metric)) +
  geom_bar(stat = "identity", position = "dodge", alpha = 0.85, width = 0.75) +
  geom_hline(yintercept = 1, linetype = "dashed", color = "#D62728", size = 1.3) +
  annotate("rect", xmin = -Inf, xmax = Inf, ymin = 0.95, ymax = 1.05, 
           fill = "#D62728", alpha = 0.12) +
  annotate("text", x = 8.5, y = 1.2, label = "G>T level (reference)", 
           color = "#D62728", fontface = "bold", size = 5) +
  scale_fill_manual(values = c("Fold SNVs" = "#667eea", "Fold Counts" = "#764ba2"), name = "") +
  theme_classic(base_size = 14) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold", size = 12),
    axis.title = element_text(face = "bold", size = 15),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 17),
    plot.subtitle = element_text(hjust = 0.5, size = 13, color = "gray40"),
    legend.position = "top",
    legend.text = element_text(size = 13)
  ) +
  labs(
    title = "FIGURE 7: Fold Change vs G>T - Relative Context",
    subtitle = "How much more/less frequent are other types compared to G>T? | Top 10 types",
    x = "Mutation Type",
    y = "Fold Change (relative to G>T)"
  )

ggsave(file.path(output_dir, "STEP1_FIG7_FOLD_CHANGE.png"), 
       fig7, width = 16, height = 9, dpi = 150)
cat("   ✅ Saved: STEP1_FIG7_FOLD_CHANGE.png\n")

# ============================================================================
# 9. SAVE SUMMARY TABLES
# ============================================================================

cat("\n💾 Saving summary tables...\n")

write.csv(sample_metrics, "tables/STEP1_sample_metrics_all_mutations.csv", row.names = FALSE)
write.csv(position_metrics, "tables/STEP1_position_metrics_all_mutations.csv", row.names = FALSE)
write.csv(bubble_data, "tables/STEP1_mutation_type_summary.csv", row.names = FALSE)

cat("   ✅ STEP1_sample_metrics_all_mutations.csv\n")
cat("   ✅ STEP1_position_metrics_all_mutations.csv\n")
cat("   ✅ STEP1_mutation_type_summary.csv\n")

# ============================================================================
# 10. FINAL SUMMARY
# ============================================================================

cat("\n╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║          ✅ STEP 1 DIAGNOSTIC FIGURES COMPLETED                     ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

cat("📊 FIGURES GENERATED:\n\n")

cat("1. STEP1_FIG1_HEATMAP_SNVS_ALL.png\n")
cat("   → Heatmap: 12 types x 23 positions (SNVs)\n\n")

cat("2. STEP1_FIG2_HEATMAP_COUNTS_ALL.png\n")
cat("   → Heatmap: 12 types x 23 positions (Counts)\n\n")

cat("3. STEP1_FIG3_G_TRANSVERSIONS_SNVS.png\n")
cat("   → G>T vs G>A vs G>C by position (SNVs)\n\n")

cat("4. STEP1_FIG4_G_TRANSVERSIONS_COUNTS.png\n")
cat("   → G>T vs G>A vs G>C by position (Counts)\n\n")

cat("5. STEP1_FIG5_BUBBLE_PLOT.png\n")
cat("   → SNVs vs Counts (size = SD)\n\n")

cat("6. STEP1_FIG6_VIOLIN_DISTRIBUTIONS.png\n")
cat("   → Complete distributions (Top 8 types)\n\n")

cat("7. STEP1_FIG7_FOLD_CHANGE.png\n")
cat("   → Fold Change vs G>T (integrated)\n\n")

cat("📊 KEY FINDINGS:\n")
cat(sprintf("   • Total mutation types: %d\n", length(unique(sample_metrics$Mutation_Type))))
cat(sprintf("   • Total samples: %d\n", length(unique(sample_metrics$Sample))))
cat(sprintf("   • Total SNVs: %s\n", comma(nrow(data_clean))))

# Calculate G>T specificity
g_total <- position_all %>% filter(Mutation_Type %in% c("GT", "GA", "GC")) %>% pull(N_SNVs) %>% sum()
gt_count <- position_all %>% filter(Mutation_Type == "GT") %>% pull(N_SNVs) %>% sum()
gt_pct <- gt_count / g_total * 100

cat(sprintf("   • G>T of G transversions: %.1f%%\n", gt_pct))

cat("\n✅ ALL FIGURES IN ENGLISH AND READY FOR PIPELINE\n\n")

