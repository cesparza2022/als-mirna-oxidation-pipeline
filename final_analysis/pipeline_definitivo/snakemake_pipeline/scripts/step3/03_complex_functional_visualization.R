#!/usr/bin/env Rscript
# ============================================================================
# STEP 3.3: Complex Functional Visualization
# ============================================================================
# Purpose: Create comprehensive multi-panel figure showing functional impact
# 
# This figure combines:
# 1. Pathway enrichment barplot (top enriched pathways)
# 2. ALS-relevant genes network-style visualization
# 3. Target comparison (canonical vs oxidized)
# 4. Position-specific functional impact
#
# Snakemake parameters:
#   input: Multiple enrichment and target analysis results
#   output: Complex multi-panel figure
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
  library(readr)
  library(patchwork)
  library(scales)
  library(ggrepel)
})

# Load common functions and theme
source(snakemake@params[["functions"]], local = TRUE)
# Theme is loaded via functions_common.R

# Initialize logging
log_file <- if (length(snakemake@log) > 0) snakemake@log[[1]] else {
  file.path(dirname(snakemake@output[[1]]), "complex_functional_viz.log")
}
initialize_logging(log_file, context = "Step 3.3 - Complex Functional Visualization")

log_section("STEP 3.3: Complex Functional Visualization")

# ============================================================================
# GET SNAKEMAKE PARAMETERS
# ============================================================================

input_targets <- snakemake@input[["targets"]]
input_go <- snakemake@input[["go_enrichment"]]
input_kegg <- snakemake@input[["kegg_enrichment"]]
input_als_genes <- snakemake@input[["als_genes"]]
input_target_comp <- snakemake@input[["target_comparison"]]
output_figure <- snakemake@output[["figure"]]

config <- snakemake@config
color_gt <- if (!is.null(config$analysis$colors$gt)) config$analysis$colors$gt else "#D62728"
color_control <- if (!is.null(config$analysis$colors$control)) config$analysis$colors$control else "grey60"
fig_width <- if (!is.null(config$analysis$figure$width)) config$analysis$figure$width else 14
fig_height <- if (!is.null(config$analysis$figure$height)) config$analysis$figure$height else 12
fig_dpi <- if (!is.null(config$analysis$figure$dpi)) config$analysis$figure$dpi else 300

log_info(paste("Output figure:", output_figure))
ensure_output_dir(dirname(output_figure))

# ============================================================================
# LOAD DATA
# ============================================================================

log_subsection("Loading functional analysis data")

target_data <- read_csv(input_targets, show_col_types = FALSE)
go_data <- read_csv(input_go, show_col_types = FALSE)
kegg_data <- read_csv(input_kegg, show_col_types = FALSE)
als_genes_data <- read_csv(input_als_genes, show_col_types = FALSE)
target_comp <- read_csv(input_target_comp, show_col_types = FALSE)

# ============================================================================
# PANEL A: Top Enriched Pathways (Barplot)
# ============================================================================

log_subsection("Creating Panel A: Pathway Enrichment")

top_pathways <- bind_rows(
  go_data %>% mutate(Type = "GO Biological Process") %>% head(10),
  kegg_data %>% mutate(Type = "KEGG Pathway") %>% head(10)
) %>%
  arrange(p.adjust) %>%
  head(15) %>%
  mutate(
    Pathway_Label = ifelse(nchar(Description) > 40, 
                          paste0(str_sub(Description, 1, 37), "..."),
                          Description),
    Pathway_Label = ifelse(is.na(Pathway_Label), Pathway_Name, Pathway_Label)
  )

panel_a <- ggplot(top_pathways, aes(x = reorder(Pathway_Label, -log10(p.adjust)), 
                                     y = -log10(p.adjust), fill = RichFactor)) +
  geom_bar(stat = "identity", alpha = 0.85, width = 0.7) +
  scale_fill_gradient(low = "white", high = color_gt, name = "Rich\nFactor") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
  coord_flip() +
  labs(
    title = "A. Top Enriched Pathways",
    subtitle = "Targets of oxidized miRNAs | GO Biological Process & KEGG Pathways",
    x = "",
    y = "-Log10 Adjusted p-value"
  ) +
  theme_professional +
  theme(
    legend.position = "right",
    plot.title = element_text(size = 12, face = "bold", hjust = 0),
    plot.subtitle = element_text(size = 9, color = "grey50", hjust = 0)
  )

# ============================================================================
# PANEL B: ALS-Relevant Genes Impact
# ============================================================================

log_subsection("Creating Panel B: ALS-Relevant Genes")

als_summary <- als_genes_data %>%
  group_by(miRNA_name) %>%
  summarise(
    total_impact = sum(abs(functional_impact_score), na.rm = TRUE),
    n_als_genes = sum(als_genes_count, na.rm = TRUE),
    avg_position = mean(position, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(total_impact)) %>%
  head(15)

panel_b <- ggplot(als_summary, aes(x = reorder(miRNA_name, total_impact), 
                                   y = total_impact, 
                                   size = n_als_genes,
                                   color = avg_position)) +
  geom_point(alpha = 0.8) +
  scale_color_gradient(low = "#2E86AB", high = color_gt, 
                      name = "Avg\nPosition", guide = "legend") +
  scale_size_continuous(range = c(3, 10), name = "ALS\nGenes") +
  scale_y_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.1))) +
  coord_flip() +
  labs(
    title = "B. Impact on ALS-Relevant Genes",
    subtitle = "Functional impact score of oxidized miRNAs on ALS genes",
    x = "miRNA",
    y = "Functional Impact Score"
  ) +
  theme_professional +
  theme(
    legend.position = "right",
    plot.title = element_text(size = 12, face = "bold", hjust = 0),
    plot.subtitle = element_text(size = 9, color = "grey50", hjust = 0)
  )

# ============================================================================
# PANEL C: Target Comparison (Canonical vs Oxidized)
# ============================================================================

log_subsection("Creating Panel C: Target Comparison")

target_comp_long <- target_comp %>%
  select(miRNA_name, canonical_targets_estimate, oxidized_targets_estimate) %>%
  pivot_longer(cols = c(canonical_targets_estimate, oxidized_targets_estimate),
              names_to = "Target_Type", values_to = "n_targets") %>%
  mutate(
    Target_Type = case_when(
      Target_Type == "canonical_targets_estimate" ~ "Canonical",
      TRUE ~ "Oxidized (G>T)"
    )
  ) %>%
  head(30)  # Top 15 miRNAs

panel_c <- ggplot(target_comp_long, aes(x = reorder(miRNA_name, n_targets), 
                                        y = n_targets, fill = Target_Type)) +
  geom_bar(stat = "identity", position = "dodge", alpha = 0.85, width = 0.7) +
  scale_fill_manual(values = c("Canonical" = color_control, 
                               "Oxidized (G>T)" = color_gt),
                   name = "Target Type") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
  coord_flip() +
  labs(
    title = "C. Target Prediction Comparison",
    subtitle = "Estimated number of targets: Canonical vs Oxidized miRNAs",
    x = "miRNA",
    y = "Number of Predicted Targets"
  ) +
  theme_professional +
  theme(
    legend.position = "right",
    plot.title = element_text(size = 12, face = "bold", hjust = 0),
    plot.subtitle = element_text(size = 9, color = "grey50", hjust = 0)
  )

# ============================================================================
# PANEL D: Position-Specific Functional Impact
# ============================================================================

log_subsection("Creating Panel D: Position-Specific Impact")

position_impact <- target_data %>%
  group_by(position) %>%
  summarise(
    n_mutations = n(),
    avg_impact = mean(functional_impact_score, na.rm = TRUE),
    total_impact = sum(functional_impact_score, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    in_seed = position >= 2 & position <= 8
  )

panel_d <- ggplot(position_impact, aes(x = position, y = total_impact)) +
  annotate("rect", xmin = 2 - 0.5, xmax = 8 + 0.5, 
           ymin = -Inf, ymax = Inf, 
           fill = "#e3f2fd", alpha = 0.5) +
  annotate("text", x = 5, 
           y = max(position_impact$total_impact) * 0.95, 
           label = "SEED REGION", color = "gray40", size = 3.5, fontface = "bold") +
  geom_bar(stat = "identity", fill = color_gt, alpha = 0.85, width = 0.7) +
  geom_point(aes(size = n_mutations), color = "white", fill = color_gt, 
            shape = 21, stroke = 1.5) +
  scale_size_continuous(range = c(2, 8), name = "Mutations") +
  scale_x_continuous(breaks = seq(1, 23, by = 2)) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
  labs(
    title = "D. Position-Specific Functional Impact",
    subtitle = "Cumulative functional impact by position in seed region",
    x = "Position in miRNA",
    y = "Total Functional Impact Score"
  ) +
  theme_professional +
  theme(
    legend.position = "right",
    plot.title = element_text(size = 12, face = "bold", hjust = 0),
    plot.subtitle = element_text(size = 9, color = "grey50", hjust = 0)
  )

# ============================================================================
# COMBINE PANELS
# ============================================================================

log_subsection("Combining panels into final figure")

# Arrange panels
combined_figure <- (panel_a | panel_b) / (panel_c | panel_d) +
  plot_annotation(
    title = "Functional Impact Analysis: Oxidized miRNAs in ALS",
    subtitle = "Comprehensive analysis of targets, pathways, and ALS-relevant genes affected by G>T mutations in seed region",
    caption = paste("Analysis based on", nrow(target_data), "significant G>T mutations in seed region (positions 2-8)"),
    theme = theme(
      plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 11, color = "grey40", hjust = 0.5, margin = margin(b = 10)),
      plot.caption = element_text(size = 9, color = "grey60", hjust = 1)
    )
  )

# Save figure
ggsave(output_figure, combined_figure, 
       width = fig_width, height = fig_height, dpi = fig_dpi, 
       bg = "white")

log_success(paste("Complex functional visualization saved:", output_figure))
log_success("Step 3.3 completed successfully")

