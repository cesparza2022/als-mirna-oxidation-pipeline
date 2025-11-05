#!/usr/bin/env Rscript
# ============================================================================
# PANEL C: G>X Mutation Spectrum by Position
# ============================================================================
# Purpose: Show distribution of G mutations (G>T, G>C, G>A) by position
# Input: Raw data (miRNA_count.Q33.txt) - counts SNVs, not sample counts
# Output: step1_panelC_gx_spectrum.png
# Tables: TABLE_1.C_gx_spectrum_by_position.csv

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
  library(readr)
  library(stringr)
  library(scales)
})

# Colors (professional)
COLOR_GT <- "#D62728"  # Red for G>T (oxidation)
COLOR_GC <- "#2E86AB"  # Blue
COLOR_GA <- "#7D3C98"  # Purple

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  PANEL C: G>X Mutation Spectrum by Position\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# Load RAW data (path relative to step1/scripts/)
root <- normalizePath(file.path(getwd(), "../.."))
# Try multiple possible locations
raw_data_path <- file.path(root, "..", "data", "raw", "miRNA_count.Q33.txt")
if (!file.exists(raw_data_path)) {
  raw_data_path <- file.path(root, "UCSD", "8OG", "results", "Magen_ALS-bloodplasma", "miRNA_count.Q33.txt")
}
if (!file.exists(raw_data_path)) {
  stop("ERROR: Cannot find miRNA_count.Q33.txt. Searched: ", raw_data_path)
}
raw_data <- read_tsv(raw_data_path, show_col_types = FALSE)

# Process data (same as generate_figure_1_COMPLETE.R)
processed_data <- raw_data %>%
  separate_rows(`pos:mut`, sep = ",") %>%
  filter(`pos:mut` != "PM") %>%
  separate(`pos:mut`, into = c("position", "mutation_type_raw"), sep = ":", remove = FALSE) %>%
  mutate(
    position = as.numeric(position),
    mutation_type = str_replace_all(mutation_type_raw, c("TC" = "T>C", "AG" = "A>G", "GA" = "G>A", "CT" = "C>T",
                                                         "TA" = "T>A", "GT" = "G>T", "TG" = "T>G", "AT" = "A>T",
                                                         "CA" = "C>A", "CG" = "C>G", "GC" = "G>C", "AC" = "A>C"))
  ) %>%
  filter(position >= 1 & position <= 22)

cat("   ✅ Data loaded and processed:", nrow(processed_data), "SNVs\n\n")

# Filter G mutations and COUNT SNVs (not sum counts)
gx_spectrum_data <- processed_data %>%
  filter(str_detect(mutation_type, "^G>")) %>%
  count(position, mutation_type) %>%
  group_by(position) %>%
  mutate(
    percentage = n / sum(n) * 100,
    total_gx_at_pos = sum(n)
  ) %>%
  ungroup() %>%
  mutate(
    position_label = factor(position, levels = 1:22),
    mutation_type = factor(mutation_type, levels = c("G>C", "G>A", "G>T"))
  )

# Calculate statistics
gt_percentage_overall <- sum(gx_spectrum_data$n[gx_spectrum_data$mutation_type == "G>T"]) / sum(gx_spectrum_data$n) * 100

seed_min <- 2; seed_max <- 8

# Figure
theme_prof <- theme_classic(base_size = 14) +
  theme(
    plot.title = element_text(size = 13, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5, color = "gray40"),
    axis.text = element_text(size = 10),
    panel.grid.major = element_line(color = "grey90", linewidth = 0.3),
    legend.position = "right",
    legend.title = element_text(face = "bold", size = 10),
    legend.text = element_text(size = 9),
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

p <- ggplot(gx_spectrum_data, aes(x = position_label, y = percentage, fill = mutation_type)) +
  annotate("rect", xmin = seed_min - 0.5, xmax = seed_max + 0.5, ymin = -Inf, ymax = Inf, fill = "#e3f2fd", alpha = 0.5) +
  geom_col(position = "stack", color = "white", linewidth = 0.3) +
  scale_fill_manual(values = c("G>C" = COLOR_GC, "G>A" = COLOR_GA, "G>T" = COLOR_GT), name = "Mutation Type") +
  scale_y_continuous(limits = c(0, 100), expand = expansion(mult = c(0, 0.02))) +
  labs(title = "C. G>X Mutation Spectrum by Position",
       subtitle = sprintf("G>T represents %.1f%% of all G>X mutations", gt_percentage_overall),
       x = "Position in miRNA", y = "Percentage of G>X mutations (%)",
       caption = "Combined analysis (ALS + Control, no VAF filtering)") +
  theme_prof

figure_dir <- file.path("..", "outputs", "figures")
dir.create(figure_dir, showWarnings = FALSE, recursive = TRUE)
ggsave(file.path(figure_dir, "step1_panelC_gx_spectrum.png"), p, width = 12, height = 6, dpi = 300, bg = "white")

# Export table
table_dir <- file.path("..", "outputs", "tables")
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)
write_csv(gx_spectrum_data %>% mutate(position_label = as.character(position_label)), 
          file.path(table_dir, "TABLE_1.C_gx_spectrum_by_position.csv"))
cat("   💾 Exported: TABLE_1.C_gx_spectrum_by_position.csv\n")
cat("✅ Figure saved: step1_panelC_gx_spectrum.png\n\n")

dir.create(figure_dir, showWarnings = FALSE, recursive = TRUE)
ggsave(file.path(figure_dir, "step1_panelC_gx_spectrum.png"), p, width = 12, height = 6, dpi = 300, bg = "white")

# Export table
table_dir <- file.path("..", "outputs", "tables")
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)
write_csv(gx_spectrum_data %>% mutate(position_label = as.character(position_label)), 
          file.path(table_dir, "TABLE_1.C_gx_spectrum_by_position.csv"))
cat("   💾 Exported: TABLE_1.C_gx_spectrum_by_position.csv\n")
cat("✅ Figure saved: step1_panelC_gx_spectrum.png\n\n")

dir.create(figure_dir, showWarnings = FALSE, recursive = TRUE)
ggsave(file.path(figure_dir, "step1_panelC_gx_spectrum.png"), p, width = 12, height = 6, dpi = 300, bg = "white")

# Export table
table_dir <- file.path("..", "outputs", "tables")
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)
write_csv(gx_spectrum_data %>% mutate(position_label = as.character(position_label)), 
          file.path(table_dir, "TABLE_1.C_gx_spectrum_by_position.csv"))
cat("   💾 Exported: TABLE_1.C_gx_spectrum_by_position.csv\n")
cat("✅ Figure saved: step1_panelC_gx_spectrum.png\n\n")
