#!/usr/bin/env Rscript
# ============================================================================
# PANEL B: G>T Count by Position (Snakemake version)
# ============================================================================
# Purpose: Show absolute count of G>T mutations across all positions (1-23)
# 
# Snakemake parameters:
#   input: Path to processed data CSV
#   output_figure: Path to output figure PNG
#   output_table: Path to output table CSV
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
  library(readr)
  library(stringr)
  library(scales)
})

# Load common functions
source(snakemake@params[["functions"]], local = TRUE)

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  PANEL B: G>T Count by Position\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# ============================================================================
# GET SNAKEMAKE PARAMETERS
# ============================================================================

input_file <- snakemake@input[["data"]]
output_figure <- snakemake@output[["figure"]]
output_table <- snakemake@output[["table"]]

cat("📋 Parameters:\n")
cat("   Input:", input_file, "\n")
cat("   Output figure:", output_figure, "\n")
cat("   Output table:", output_table, "\n\n")

# Ensure output directories exist
ensure_output_dir(dirname(output_figure))
ensure_output_dir(dirname(output_table))

# ============================================================================
# LOAD DATA
# ============================================================================

data <- load_processed_data(input_file)
sample_cols <- setdiff(names(data), c("miRNA_name", "pos.mut"))

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

write_csv(position_counts, output_table)
cat("   💾 Exported:", output_table, "\n\n")

# ============================================================================
# GENERATE FIGURE
# ============================================================================

cat("🎨 Generating Panel B figure...\n")

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
  theme_professional

# Save figure
ggsave(
  output_figure,
  fig_panelB,
  width = 14,
  height = 8,
  dpi = 300,
  bg = "white"
)

cat("   ✅ Figure saved:", output_figure, "\n\n")

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

