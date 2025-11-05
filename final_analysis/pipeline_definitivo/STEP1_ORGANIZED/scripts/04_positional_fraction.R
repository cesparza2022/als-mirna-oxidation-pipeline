#!/usr/bin/env Rscript
# ============================================================================
# PANEL D: Positional Fraction of Mutations
# ============================================================================
# Purpose: Proportion of ALL SNVs occurring at each position (relative to total)
# Note: According to STEP1 README consolidated, Panel D shows ALL mutations
# Input: Raw data (miRNA_count.Q33.txt) - counts SNVs, not sample counts
# Output: step1_panelD_positional_fraction.png
# Tables: TABLE_1.D_positional_fractions.csv

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
  library(readr)
  library(stringr)
  library(scales)
})

cat("\n═══════════════════════════════════════════════════════════════════\n")
cat("  PANEL D: Positional Fraction of Mutations\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

# Load RAW data (same method as original working scripts)
raw_data_path <- "/Users/cesaresparza/New_Desktop/UCSD/8OG/results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt"
raw_data <- read_tsv(raw_data_path, show_col_types = FALSE)

# Process data (EXACTLY as generate_figure_1_COMPLETE.R)
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

# COUNT SNVs by position (NOT sum counts) - ALL mutations (as per STEP1 README)
pos_counts <- processed_data %>%
  count(position, name = "snv_count") %>%
  arrange(position)

total_mut <- sum(pos_counts$snv_count)

pos_frac <- pos_counts %>%
  mutate(
    fraction = snv_count / total_mut * 100,
    position_label = factor(position, levels = 1:22),
    region = ifelse(position >= 2 & position <= 8, "Seed", "Non-Seed")
  )

# Export table (without factor, convert to character for CSV)
dir.create("data", showWarnings = FALSE, recursive = TRUE)
pos_frac_export <- pos_frac %>%
  mutate(position_label = as.character(position_label)) %>%
  select(position, snv_count, fraction, position_label, region)
write_csv(pos_frac_export, file.path("data", "TABLE_1.D_positional_fractions.csv"))
cat("   💾 Exported: TABLE_1.D_positional_fractions.csv\n")
cat("   📊 Total SNVs:", format(total_mut, big.mark=","), "| Fractions sum to:", round(sum(pos_frac$fraction), 2), "%\n")

# Figure - Using EXACT style from generate_figure_2_CORRECTED.R
professional_theme <- theme_classic(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 13, hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5, color = "gray40"),
    axis.text = element_text(size = 10),
    panel.grid.major = element_line(color = "grey90", linewidth = 0.3),
    legend.position = "right",
    legend.title = element_text(face = "bold", size = 10),
    legend.text = element_text(size = 9)
  )

panel_d <- ggplot(pos_frac, aes(x = position_label, y = fraction)) +
  geom_col(aes(fill = region), alpha = 0.8, width = 0.7) +
  scale_fill_manual(values = c("Seed" = "#FFD700", "Non-Seed" = "grey60"), name = "Region") +
  geom_text(aes(label = sprintf("%.1f%%", fraction)), 
            vjust = -0.3, size = 3.5, fontface = "bold") +
  labs(
    title = "D. Positional Fraction of Mutations",
    subtitle = sprintf("What percentage of ALL mutations occur at each position? (Total: %s SNVs)", 
                       format(total_mut, big.mark=",")),
    x = "Position in miRNA",
    y = "Percentage of total mutations (%)"
  ) +
  professional_theme +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

dir.create("figures", showWarnings = FALSE, recursive = TRUE)
ggsave(file.path("figures", "step1_panelD_positional_fraction.png"), 
       plot = panel_d, width = 10, height = 8, dpi = 300, bg = "white")

cat("✅ Figure saved: step1_panelD_positional_fraction.png\n\n")
