#!/usr/bin/env Rscript
# ============================================================================
# PANEL G: G>T Specificity (Overall) (Snakemake version)
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
  library(readr)
  library(stringr)
  library(scales)
})

source(snakemake@params[["functions"]], local = TRUE)

cat("\n═══════════════════════════════════════════════════════════════════\n")
cat("  PANEL G: G>T Specificity (Overall)\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

input_file <- snakemake@input[["data"]]
output_figure <- snakemake@output[["figure"]]
output_table <- snakemake@output[["table"]]

ensure_output_dir(dirname(output_figure))
ensure_output_dir(dirname(output_table))

data <- load_processed_data(input_file)
sample_cols <- setdiff(names(data), c("miRNA_name", "pos.mut"))

COLOR_OTHERS <- "#6c757d"

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

write_csv(spec_tbl, output_table)

p <- ggplot(spec_tbl, aes(x = category, y = percentage, fill = category)) +
  geom_col(width = 0.6, alpha = 0.9) +
  scale_fill_manual(values = c("G>T" = COLOR_GT, "Other G transversions" = COLOR_OTHERS)) +
  scale_y_continuous(limits = c(0, 100), expand = expansion(mult = c(0, 0.02))) +
  labs(title = "G>T Specificity (Overall)",
       subtitle = "Percentage of G mutations that are G>T vs other G transversions",
       x = NULL, y = "Percentage (%)",
       caption = "Combined analysis (ALS + Control, no VAF filtering)") +
  theme_professional +
  theme(legend.position = "none")

ggsave(output_figure, p, width = 9, height = 7, dpi = 300, bg = "white")

cat("✅ PANEL G COMPLETE\n\n")

