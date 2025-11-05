#!/usr/bin/env Rscript
# ============================================================================
# PANEL F: Seed vs Non-seed Comparison (Snakemake version)
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
  library(readr)
  library(stringr)
  library(scales)
})

source(snakemake@params[["functions"]], local = TRUE)

# Load configuration
config <- snakemake@config
fig_width <- if (!is.null(config$analysis$figure$width)) config$analysis$figure$width else 12
fig_height <- if (!is.null(config$analysis$figure$height)) config$analysis$figure$height else 10
fig_dpi <- if (!is.null(config$analysis$figure$dpi)) config$analysis$figure$dpi else 300

# Initialize logging
log_file <- if (length(snakemake@log) > 0) snakemake@log[[1]] else {
  file.path(dirname(snakemake@output[[1]]), "..", "logs", "panel_f.log")
}
initialize_logging(log_file, context = "Panel F")

log_section("PANEL F: Seed vs Non-seed Comparison")

input_file <- snakemake@input[["data"]]
output_figure <- snakemake@output[["figure"]]
output_table <- snakemake@output[["table"]]

log_info(paste("Input file:", input_file))
log_info(paste("Output figure:", output_figure))
log_info(paste("Output table:", output_table))

ensure_output_dir(dirname(output_figure))
ensure_output_dir(dirname(output_table))

# ============================================================================
# VALIDATE INPUT
# ============================================================================

# Basic validation only - file will be processed by load_and_process_raw_data
if (!file.exists(input_file)) {
  stop(paste("Input file not found:", input_file))
}
log_info(paste("Input file validated:", basename(input_file)))

# ============================================================================
# LOAD DATA
# ============================================================================

log_subsection("Loading data")
data <- tryCatch({
  # Process raw data (split-collapse) to get processed format
  result <- load_and_process_raw_data(input_file)
  log_success(paste("Data loaded:", nrow(result), "rows,", ncol(result), "columns"))
  result
}, error = function(e) {
  handle_error(e, context = "Panel F - Data Loading", exit_code = 1, log_file = log_file)
})

# Rename pos:mut to pos.mut for consistency with script logic
if ("pos:mut" %in% names(data) && !"pos.mut" %in% names(data)) {
  data <- data %>% rename(`pos.mut` = `pos:mut`)
}
if (!"miRNA_name" %in% names(data) && "miRNA name" %in% names(data)) {
  data <- data %>% rename(`miRNA_name` = `miRNA name`)
}

# Exclude metadata columns from sample columns
# load_and_process_raw_data adds: position, mutation_type_raw, mutation_type, pos:mut
# Keep only actual sample columns (numeric counts)
metadata_cols <- c("miRNA_name", "miRNA name", "pos.mut", "pos:mut", 
                   "position", "mutation_type_raw", "mutation_type")
sample_cols <- setdiff(names(data), metadata_cols)
# Filter to numeric columns only (sample counts)
sample_cols <- sample_cols[sapply(data[sample_cols], is.numeric)]

log_subsection("Processing seed vs non-seed comparison")

seed_min <- 2; seed_max <- 8

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

write_csv(summary_tbl, output_table)
log_success(paste("Table exported:", output_table))

p <- ggplot(summary_tbl, aes(x = region, y = total_mutations, fill = region)) +
  geom_col(width = 0.6, alpha = 0.9) +
  scale_fill_manual(values = c("Seed" = "#FFD700", "Non-seed" = "#6c757d")) +
  scale_y_continuous(labels = scales::comma) +
  labs(title = "Seed vs Non-seed: Mutation Burden",
       subtitle = "Absolute burden (summed counts across samples)",
       x = "Region", y = "Total Mutation Burden (counts)",
       caption = "Combined analysis (ALS + Control, no VAF filtering)") +
  theme_professional

log_subsection("Generating figure")
ggsave(output_figure, p, width = fig_width, height = fig_height, dpi = fig_dpi, bg = "white")
log_success(paste("Figure saved:", output_figure))

log_success("Panel F completed successfully")
log_info(paste("Execution completed at", get_timestamp()))

