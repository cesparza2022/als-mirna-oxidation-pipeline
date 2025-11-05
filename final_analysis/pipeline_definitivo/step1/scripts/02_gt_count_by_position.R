#!/usr/bin/env Rscript
# ============================================================================
# PANEL B: G>T Count by Position
# ============================================================================
# Purpose: Show absolute count of G>T mutations across all positions (1-23)
# Input: final_processed_data_CLEAN.csv (from pipeline_2/)
# Output: step1_panelB_gt_count_by_position.png
# Tables: TABLE_1.B_gt_counts_by_position.csv

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
  library(readr)
  library(stringr)
  library(scales)
})

# Professional colors (consistent with pipeline)
COLOR_GT <- "#D62728"  # Red for G>T (oxidation)

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  PANEL B: G>T Count by Position\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# ============================================================================
# LOAD DATA
# ============================================================================

cat("📂 Loading data...\n")

# Path relative to step1/scripts/ (go up 2 levels to root, then to pipeline_2)
root <- normalizePath(file.path(getwd(), "../.."))
data_path <- file.path(root, "pipeline_2", "final_processed_data_CLEAN.csv")

data <- read_csv(data_path, show_col_types = FALSE)
sample_cols <- setdiff(names(data), c("miRNA_name", "pos.mut"))

cat("   ✅ Data loaded:", nrow(data), "rows\n")
cat("   ✅ Samples:", length(sample_cols), "\n\n")

# ============================================================================
# PROCESS DATA: Extract G>T mutations by position
# ============================================================================

cat("📊 Processing G>T mutations...\n")

# Filter G>T mutations only
gt_data <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  mutate(
    position = as.numeric(str_extract(pos.mut, "^\\d+"))
  ) %>%
  filter(!is.na(position), position >= 1, position <= 23)

cat("   ✅ G>T mutations found:", nrow(gt_data), "SNVs\n")

# Calculate total counts per position (sum across all samples)
position_counts <- gt_data %>%
  rowwise() %>%
  mutate(
    total_count = sum(c_across(all_of(sample_cols)), na.rm = TRUE)
  ) %>%
  ungroup() %>%
  group_by(position) %>%
  summarise(
    total_GT_count = sum(total_count, na.rm = TRUE),
    n_SNVs = n(),
    n_miRNAs = n_distinct(miRNA_name),
    .groups = "drop"
  ) %>%
  arrange(position)

cat("   ✅ Positions analyzed:", nrow(position_counts), "\n")
cat("   ✅ Total G>T counts:", sum(position_counts$total_GT_count), "\n\n")

# ============================================================================
# EXPORT TABLE
# ============================================================================

# Output to step1/outputs/tables/ (go up 1 level from scripts/)
output_dir <- file.path("..", "outputs", "tables")
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

write_csv(position_counts, 
          file.path(output_dir, "TABLE_1.B_gt_counts_by_position.csv"))

cat("   💾 Exported: TABLE_1.B_gt_counts_by_position.csv\n")
cat("      • Columns: position, total_GT_count, n_SNVs, n_miRNAs\n\n")

# ============================================================================
# GENERATE FIGURE
# ============================================================================

cat("🎨 Generating Panel B figure...\n")

# Professional theme (consistent with pipeline)
theme_prof <- theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5, color = "gray30"),
    axis.title = element_text(size = 13, face = "bold"),
    axis.text = element_text(size = 11),
    legend.position = "none",
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    panel.border = element_rect(fill = NA, color = "gray80"),
    plot.margin = margin(10, 10, 10, 10)
  )

# Seed region annotation
seed_min <- 2
seed_max <- 8

# Create bar plot
fig_panelB <- ggplot(position_counts, aes(x = position, y = total_GT_count)) +
  # Seed region background
  annotate("rect", xmin = seed_min - 0.5, xmax = seed_max + 0.5, 
           ymin = -Inf, ymax = Inf, 
           fill = "#e3f2fd", alpha = 0.5) +
  annotate("text", x = (seed_min + seed_max) / 2, 
           y = max(position_counts$total_GT_count) * 0.95, 
           label = "SEED", color = "gray40", size = 4, fontface = "bold") +
  
  # Bars
  geom_bar(stat = "identity", fill = COLOR_GT, alpha = 0.85, width = 0.7) +
  
  # Scales
  scale_x_continuous(breaks = seq(1, 23, by = 2)) +
  scale_y_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.1))) +
  
  # Labels
  labs(
    title = "G>T Mutation Count by Position",
    subtitle = "Absolute count of G>T mutations across miRNA positions | Shaded region = seed (2-8)",
    x = "Position in miRNA",
    y = "Total G>T Count",
    caption = "Combined analysis (ALS + Control, no VAF filtering)"
  ) +
  theme_prof

# Save figure (to step1/outputs/figures/)
figure_dir <- file.path("..", "outputs", "figures")
dir.create(figure_dir, showWarnings = FALSE, recursive = TRUE)

ggsave(
  file.path(figure_dir, "step1_panelB_gt_count_by_position.png"),
  fig_panelB,
  width = 14,
  height = 8,
  dpi = 300,
  bg = "white"
)

cat("   ✅ Figure saved: step1_panelB_gt_count_by_position.png\n\n")

# ============================================================================
# SUMMARY
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("📊 PANEL B SUMMARY:\n\n")

cat("TOP 5 POSITIONS (highest G>T count):\n")
top5 <- position_counts %>% 
  arrange(desc(total_GT_count)) %>% 
  head(5)
print(top5)
cat("\n")

cat("SEED vs NON-SEED:\n")
seed_stats <- position_counts %>%
  mutate(region = ifelse(position >= seed_min & position <= seed_max, "Seed", "Non-seed")) %>%
  group_by(region) %>%
  summarise(
    total_count = sum(total_GT_count),
    n_positions = n(),
    .groups = "drop"
  )
print(seed_stats)
cat("\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("✅ PANEL B COMPLETE\n\n")



cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("✅ PANEL B COMPLETE\n\n")



cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("✅ PANEL B COMPLETE\n\n")

