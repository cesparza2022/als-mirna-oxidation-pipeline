#!/usr/bin/env Rscript
# ============================================================================
# STEP 0: DATASET OVERVIEW
# ============================================================================
# Purpose: Produce descriptive statistics and visualizations of the processed
# miRNA dataset prior to any oxidation-specific filtering.
# Outputs:
#   - Sample-level summary table and histogram facets
#   - miRNA-level summary table and histogram
#   - Mutation-type counts table and bar chart (all mutation types)
#   - Positional density chart for all SNVs (positions 1-23)
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(readr)
  library(stringr)
  library(RColorBrewer)
})

# Load shared helpers / logging utilities
source(snakemake@params[["functions"]], local = TRUE)

# Initialise logging ---------------------------------------------------------
log_file <- if (length(snakemake@log) > 0) snakemake@log[[1]] else {
  file.path(tempdir(), "step0_overview.log")
}
ensure_output_dir(dirname(log_file))
initialize_logging(log_file, context = "Step 0 - Dataset Overview")
log_section("STEP 0: Dataset Overview")

# I/O ------------------------------------------------------------------------
input_data <- snakemake@input[["data"]]
output_fig_samples   <- snakemake@output[["fig_samples"]]
output_fig_samples_box <- snakemake@output[["fig_samples_box"]]
output_fig_samples_group <- snakemake@output[["fig_samples_group"]]
output_fig_miRNA     <- snakemake@output[["fig_miRNA"]]
output_fig_top_miRNA <- snakemake@output[["fig_top_miRNA"]]
output_fig_mutation_bar  <- snakemake@output[["fig_mutation_bar"]]
output_fig_mutation_pie_snvs <- snakemake@output[["fig_mutation_pie_snvs"]]
output_fig_mutation_pie_counts <- snakemake@output[["fig_mutation_pie_counts"]]
output_fig_position  <- snakemake@output[["fig_position"]]
output_table_samples <- snakemake@output[["table_samples"]]
output_table_sample_group <- snakemake@output[["table_sample_group"]]
output_table_miRNA   <- snakemake@output[["table_miRNA"]]
output_table_top_miRNA <- snakemake@output[["table_top_miRNA"]]
output_table_mutation <- snakemake@output[["table_mutation"]]

ensure_output_dir(dirname(output_fig_samples))
ensure_output_dir(dirname(output_table_samples))

log_info(paste("Input file:", input_data))

# Load dataset ---------------------------------------------------------------
log_subsection("Loading processed dataset")
processed <- read_csv(input_data, show_col_types = FALSE)
log_success(paste("Loaded", nrow(processed), "rows and", ncol(processed), "columns"))

required_cols <- c("miRNA_name", "pos.mut")
missing_cols <- setdiff(required_cols, names(processed))
if (length(missing_cols) > 0) {
  handle_error(paste("Missing required columns:", paste(missing_cols, collapse = ", ")), 
               context = "Step 0 - Dataset Overview", exit_code = 1, log_file = log_file)
}

# Separate counts vs VAF columns --------------------------------------------
count_cols <- names(processed)[
  !(names(processed) %in% required_cols) &
    !str_detect(names(processed), "^VAF_")
]

vaf_cols <- names(processed)[str_detect(names(processed), "^VAF_")]

if (length(count_cols) == 0) {
  handle_error("No count columns detected (columns without VAF_ prefix).", 
               context = "Step 0 - Dataset Overview", exit_code = 1, log_file = log_file)
}

log_info(paste("Detected", length(count_cols), "count columns and", length(vaf_cols), "VAF columns"))

counts_matrix <- as.matrix(processed[count_cols])
counts_matrix[is.na(counts_matrix)] <- 0

# Helper to infer sample groups from column names ---------------------------
infer_sample_group <- function(sample_ids) {
  dplyr::case_when(
    str_detect(sample_ids, regex("longitudinal", ignore_case = TRUE)) ~ "ALS_longitudinal",
    str_detect(sample_ids, regex("ALS", ignore_case = TRUE)) ~ "ALS",
    str_detect(sample_ids, regex("control", ignore_case = TRUE)) ~ "Control",
    TRUE ~ "Unknown"
  )
}

group_labels <- infer_sample_group(count_cols)

# Sample-level summary ------------------------------------------------------
log_subsection("Computing sample-level summary")

sample_summary <- tibble(
  sample_id = count_cols,
  group = group_labels,
  total_counts = colSums(counts_matrix, na.rm = TRUE),
  snvs_detected = colSums(counts_matrix > 0, na.rm = TRUE),
  mirnas_detected = apply(counts_matrix, 2, function(col) {
    sum(tapply(col > 0, processed$miRNA_name, any))
  })
)

write_csv(sample_summary, output_table_samples)
log_success(paste("Sample summary table written:", output_table_samples))

sample_group_summary <- sample_summary %>%
  group_by(group) %>%
  summarise(
    n_samples = n(),
    total_counts = sum(total_counts, na.rm = TRUE),
    mean_snvs = mean(snvs_detected, na.rm = TRUE),
    mean_miRNAs = mean(mirnas_detected, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(n_samples))

write_csv(sample_group_summary, output_table_sample_group)
log_success(paste("Sample group summary table written:", output_table_sample_group))

# Create histogram facets (log scale for readability)
sample_summary_long <- sample_summary %>%
  pivot_longer(cols = c(total_counts, snvs_detected, mirnas_detected),
               names_to = "metric", values_to = "value") %>%
  mutate(metric = recode(metric,
                         total_counts = "Total read counts",
                         snvs_detected = "SNVs detected",
                         mirnas_detected = "miRNAs with SNVs"),
         value = value + 1)  # offset for log scale

fig_samples <- ggplot(sample_summary_long, aes(x = value, fill = group)) +
  geom_histogram(alpha = 0.75, bins = 40, position = "identity") +
  scale_x_log10(labels = scales::comma) +
  facet_wrap(~metric, scales = "free_y", ncol = 1) +
  labs(
    title = "Sample-level summary",
    subtitle = "Distributions of total counts, SNVs detected, and affected miRNAs",
    x = "Value (log10)",
    y = "Number of samples",
    fill = "Group"
  ) +
  theme_professional

ggsave(output_fig_samples, fig_samples, width = 10, height = 12, dpi = 300, bg = "white")
log_success(paste("Sample summary figure saved:", output_fig_samples))

fig_samples_box <- sample_summary %>%
  mutate(group = forcats::fct_infreq(group), snvs_plot = snvs_detected + 1) %>%
  ggplot(aes(x = group, y = snvs_plot, fill = group)) +
  geom_boxplot(alpha = 0.75, outlier.alpha = 0.4) +
  scale_y_log10(labels = scales::comma) +
  labs(
    title = "SNVs per sample (by group)",
    subtitle = "Log10 scale with +1 offset to avoid zero values",
    x = "Group",
    y = "SNVs detected (log10)",
    fill = "Group"
  ) +
  theme_professional +
  theme(legend.position = "none")

ggsave(output_fig_samples_box, fig_samples_box, width = 8, height = 6, dpi = 300, bg = "white")
log_success(paste("Sample boxplot figure saved:", output_fig_samples_box))

fig_samples_group <- sample_group_summary %>%
  mutate(prop = n_samples / sum(n_samples)) %>%
  ggplot(aes(x = "", y = prop, fill = group)) +
  geom_col(width = 1, color = "white") +
  coord_polar(theta = "y") +
  scale_fill_brewer(palette = "Set2") +
  labs(
    title = "Proportion of samples by group",
    fill = "Group"
  ) +
  theme_void()

ggsave(output_fig_samples_group, fig_samples_group, width = 6, height = 6, dpi = 300, bg = "white")
log_success(paste("Sample group pie chart saved:", output_fig_samples_group))

# miRNA-level summary -------------------------------------------------------
log_subsection("Computing miRNA-level summary")
row_indices <- split(seq_len(nrow(processed)), processed$miRNA_name)

mirna_summary <- tibble(
  miRNA_name = names(row_indices),
  n_snvs = lengths(row_indices),
  total_counts = vapply(row_indices, function(idx) {
    sum(counts_matrix[idx, , drop = FALSE], na.rm = TRUE)
  }, numeric(1)),
  samples_with_mutation = vapply(row_indices, function(idx) {
    sum(colSums(counts_matrix[idx, , drop = FALSE] > 0) > 0)
  }, numeric(1))
) %>%
  arrange(desc(n_snvs))

write_csv(mirna_summary, output_table_miRNA)
log_success(paste("miRNA summary table written:", output_table_miRNA))

fig_miRNA <- mirna_summary %>%
  mutate(n_snvs = n_snvs + 1) %>%
  ggplot(aes(x = n_snvs)) +
  geom_histogram(fill = COLOR_GT, alpha = 0.8, bins = 40) +
  scale_x_log10(breaks = scales::trans_breaks("log10", function(x) 10^x),
                labels = scales::trans_format("log10", scales::math_format(10^.x))) +
  labs(
    title = "Distribution of SNVs per miRNA",
    subtitle = "Total SNVs before filtering by mutation type",
    x = "Number of SNVs per miRNA (log10)",
    y = "Number of miRNAs"
  ) +
  theme_professional

ggsave(output_fig_miRNA, fig_miRNA, width = 10, height = 6, dpi = 300, bg = "white")
log_success(paste("miRNA summary figure saved:", output_fig_miRNA))

top_miRNA <- mirna_summary %>%
  slice_max(order_by = n_snvs, n = 20, with_ties = FALSE)

write_csv(top_miRNA, output_table_top_miRNA)
log_success(paste("Top miRNA table written:", output_table_top_miRNA))

fig_top_miRNA <- top_miRNA %>%
  mutate(miRNA_name = forcats::fct_reorder(miRNA_name, n_snvs)) %>%
  ggplot(aes(x = miRNA_name, y = n_snvs)) +
  geom_col(fill = COLOR_CONTROL) +
  coord_flip() +
  labs(
    title = "Top 20 miRNAs by number of SNVs",
    x = "miRNA",
    y = "SNVs"
  ) +
  theme_professional

ggsave(output_fig_top_miRNA, fig_top_miRNA, width = 8, height = 8, dpi = 300, bg = "white")
log_success(paste("Top miRNA figure saved:", output_fig_top_miRNA))

# Mutation-type counts ------------------------------------------------------
log_subsection("Computing mutation-type distribution")
mutation_counts <- processed %>%
  mutate(
    mutation = str_to_upper(str_replace_na(str_extract(pos.mut, "(?<=:)[A-Z>]+"))),
    mutation = if_else(mutation == "PM", NA_character_, mutation),
    position = suppressWarnings(as.numeric(str_extract(pos.mut, "^[0-9]+")))
  )

row_total_counts <- rowSums(counts_matrix, na.rm = TRUE)

mutation_summary <- tibble(
  mutation = mutation_counts$mutation,
  total_counts = row_total_counts
) %>%
  filter(!is.na(mutation)) %>%
  group_by(mutation) %>%
  summarise(
    n_snvs = n(),
    total_counts = sum(total_counts, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(n_snvs))

write_csv(mutation_summary, output_table_mutation)
log_success(paste("Mutation summary table written:", output_table_mutation))

fig_mutation_bar <- mutation_summary %>%
  mutate(mutation = fct_reorder(mutation, n_snvs)) %>%
  ggplot(aes(x = mutation, y = n_snvs)) +
  geom_col(fill = COLOR_CONTROL) +
  coord_flip() +
  labs(
    title = "Distribution of mutations (all transitions/transversions)",
    x = "Mutation type",
    y = "Number of SNVs"
  ) +
  theme_professional

ggsave(output_fig_mutation_bar, fig_mutation_bar, width = 10, height = 8, dpi = 300, bg = "white")
log_success(paste("Mutation distribution figure saved:", output_fig_mutation_bar))

fig_mutation_pie_snvs <- mutation_summary %>%
  mutate(prop = n_snvs / sum(n_snvs)) %>%
  ggplot(aes(x = "", y = prop, fill = mutation)) +
  geom_col(width = 1, color = "white") +
  coord_polar(theta = "y") +
  scale_fill_brewer(palette = "Set3") +
  labs(title = "Proportion of SNVs by mutation type", fill = "Mutation") +
  theme_void()

ggsave(output_fig_mutation_pie_snvs, fig_mutation_pie_snvs, width = 6, height = 6, dpi = 300, bg = "white")
log_success(paste("Mutation SNV pie chart saved:", output_fig_mutation_pie_snvs))

fig_mutation_pie_counts <- mutation_summary %>%
  mutate(prop = total_counts / sum(total_counts)) %>%
  ggplot(aes(x = "", y = prop, fill = mutation)) +
  geom_col(width = 1, color = "white") +
  coord_polar(theta = "y") +
  scale_fill_brewer(palette = "Pastel1") +
  labs(title = "Proportion of reads by mutation type", fill = "Mutation") +
  theme_void()

ggsave(output_fig_mutation_pie_counts, fig_mutation_pie_counts, width = 6, height = 6, dpi = 300, bg = "white")
log_success(paste("Mutation count pie chart saved:", output_fig_mutation_pie_counts))

# Positional density --------------------------------------------------------
log_subsection("Computing positional density")
position_summary <- processed %>%
  mutate(position = suppressWarnings(as.numeric(str_extract(pos.mut, "^[0-9]+")))) %>%
  filter(!is.na(position)) %>%
  group_by(position) %>%
  summarise(
    n_snvs = n(),
    .groups = "drop"
  ) %>%
  arrange(position)

fig_position <- position_summary %>%
  ggplot(aes(x = position, y = n_snvs)) +
  geom_col(fill = COLOR_GT, alpha = 0.8) +
  geom_vline(xintercept = c(2, 8), linetype = "dashed", color = "grey40") +
  annotate("text", x = 5, y = max(position_summary$n_snvs) * 0.95,
           label = "Seed (2-8)", color = "grey30", fontface = "bold") +
  labs(
    title = "SNV density by position",
    subtitle = "Count of SNVs at each position (1-23) before specific filtering",
    x = "Position",
    y = "Number of SNVs"
  ) +
  theme_professional

ggsave(output_fig_position, fig_position, width = 10, height = 6, dpi = 300, bg = "white")
log_success(paste("Position density figure saved:", output_fig_position))

# Summary log ---------------------------------------------------------------
summary_samples <- sample_summary %>% summarise(
  total_samples = n(),
  total_reads = sum(total_counts, na.rm = TRUE),
  median_snvs = median(snvs_detected, na.rm = TRUE),
  median_miRNAs = median(mirnas_detected, na.rm = TRUE)
)

total_miRNAs <- nrow(mirna_summary)
total_snvs <- sum(mirna_summary$n_snvs, na.rm = TRUE)

log_subsection("Summary statistics")
log_info(paste("Total samples:", summary_samples$total_samples[1]))
log_info(paste("Total miRNAs:", total_miRNAs))
log_info(paste("Total SNVs:", total_snvs))
log_success("Step 0 overview completed")
