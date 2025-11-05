#!/usr/bin/env Rscript
# ============================================================================
# PANEL F: Seed vs Non-seed Comparison
# ============================================================================
# Purpose: Compare mutation patterns in seed (2-8) vs non-seed
# Input: final_processed_data_CLEAN.csv
# Output: step1_panelF_seed_interaction.png
# Tables: TABLE_1.F_seed_vs_nonseed.csv

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
  library(readr)
  library(stringr)
  library(scales)
})

seed_min <- 2; seed_max <- 8

cat("\n═══════════════════════════════════════════════════════════════════\n")
cat("  PANEL F: Seed vs Non-seed Comparison\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

# Load data (path relative to step1/scripts/)
root <- normalizePath(file.path(getwd(), "../.."))
data_path <- file.path(root, "pipeline_2", "final_processed_data_CLEAN.csv")
data <- read_csv(data_path, show_col_types = FALSE)
sample_cols <- setdiff(names(data), c("miRNA_name", "pos.mut"))

# Any SNV row with d:XY
snv <- data %>%
  filter(str_detect(pos.mut, "^\\d+:[ACGT][ACGT]$")) %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^\\d+"))) %>%
  filter(!is.na(position), position >= 1, position <= 23) %>%
  rowwise() %>%
  mutate(total_row_count = sum(c_across(all_of(sample_cols)), na.rm = TRUE)) %>%
  ungroup() %>%
  mutate(region = ifelse(position >= seed_min & position <= seed_max, "Seed", "Non-seed"))

summary_tbl <- snv %>%
  group_by(region) %>%
  summarise(
    total_mutations = sum(total_row_count, na.rm = TRUE),
    n_SNVs = n(),
    .groups = 'drop'
  ) %>%
  mutate(fraction = total_mutations / sum(total_mutations) * 100)

# Export table
table_dir <- file.path("..", "outputs", "tables")
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)
write_csv(summary_tbl, file.path(table_dir, "TABLE_1.F_seed_vs_nonseed.csv"))

# Figure
prof_theme <- theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5, color = "gray30"),
    axis.title = element_text(size = 13, face = "bold"),
    axis.text = element_text(size = 11),
    panel.grid.minor = element_blank(),
    panel.border = element_rect(fill = NA, color = "gray80"),
    plot.margin = margin(10, 10, 10, 10)
  )

p <- ggplot(summary_tbl, aes(x = region, y = total_mutations, fill = region)) +
  geom_col(width = 0.6, alpha = 0.9) +
  scale_fill_manual(values = c("Seed" = "#FFD700", "Non-seed" = "#6c757d")) +
  scale_y_continuous(labels = scales::comma) +
  labs(title = "Seed vs Non-seed: Mutation Burden",
       subtitle = "Absolute burden (summed counts across samples)",
       x = "Region", y = "Total Mutation Burden (counts)",
       caption = "Combined analysis (ALS + Control, no VAF filtering)") +
  prof_theme


figure_dir <- file.path("..", "outputs", "figures")
dir.create(figure_dir, showWarnings = FALSE, recursive = TRUE)

ggsave(file.path(figure_dir, "step1_panelF_seed_interaction.png"), p, width = 10, height = 7, dpi = 300, bg = "white")

cat("✅ Figure saved: step1_panelF_seed_interaction.png\n")



cat("✅ Figure saved: step1_panelF_seed_interaction.png\n")



cat("✅ Figure saved: step1_panelF_seed_interaction.png\n")


