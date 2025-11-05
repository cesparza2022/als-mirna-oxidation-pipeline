#!/usr/bin/env Rscript
# ============================================================================
# PANEL G: G>T Specificity (Overall)
# ============================================================================
# Purpose: Quantify oxidative damage specificity (G>T vs other G transversions)
# Input: final_processed_data_CLEAN.csv
# Output: step1_panelG_gt_specificity.png
# Tables: TABLE_1.G_gt_specificity.csv

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
  library(readr)
  library(stringr)
  library(scales)
})

COLOR_GT <- "#D62728"; COLOR_OTHERS <- "#6c757d"

cat("\n═══════════════════════════════════════════════════════════════════\n")
cat("  PANEL G: G>T Specificity (Overall)\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

# Load data
data <- read_csv("../pipeline_2/final_processed_data_CLEAN.csv", show_col_types = FALSE)
sample_cols <- setdiff(names(data), c("miRNA_name", "pos.mut"))

# Filter G mutations and compute total counts per row
g_mut <- data %>%
  filter(str_detect(pos.mut, "^\\d+:G[TCAG]$")) %>%
  rowwise() %>%
  mutate(total_row_count = sum(c_across(all_of(sample_cols)), na.rm = TRUE)) %>%
  ungroup() %>%
  mutate(type = case_when(
    str_ends(pos.mut, ":GT") ~ "G>T",
    str_ends(pos.mut, ":GC") ~ "G>C",
    str_ends(pos.mut, ":GA") ~ "G>A",
    TRUE ~ NA_character_
  )) %>%
  filter(!is.na(type))

spec_tbl <- g_mut %>%
  group_by(type) %>%
  summarise(total = sum(total_row_count, na.rm = TRUE), .groups = 'drop') %>%
  mutate(category = ifelse(type == "G>T", "G>T", "Other G transversions")) %>%
  group_by(category) %>%
  summarise(total = sum(total), .groups = 'drop') %>%
  mutate(percentage = total / sum(total) * 100)

# Export table
dir.create("data", showWarnings = FALSE, recursive = TRUE)
write_csv(spec_tbl, file.path("data", "TABLE_1.G_gt_specificity.csv"))

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

p <- ggplot(spec_tbl, aes(x = category, y = percentage, fill = category)) +
  geom_col(width = 0.6, alpha = 0.9) +
  scale_fill_manual(values = c("G>T" = COLOR_GT, "Other G transversions" = COLOR_OTHERS)) +
  scale_y_continuous(limits = c(0, 100), expand = expansion(mult = c(0, 0.02))) +
  labs(title = "G>T Specificity (Overall)",
       subtitle = "Percentage of G mutations that are G>T vs other G transversions",
       x = NULL, y = "Percentage (%)",
       caption = "Combined analysis (ALS + Control, no VAF filtering)") +
  prof_theme +
  theme(legend.position = "none")


dir.create("figures", showWarnings = FALSE)

ggsave(file.path("figures", "step1_panelG_gt_specificity.png"), p, width = 9, height = 7, dpi = 300, bg = "white")

cat("✅ Figure saved: step1_panelG_gt_specificity.png\n")


