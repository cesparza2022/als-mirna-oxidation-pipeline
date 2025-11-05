# 🎨 FIGURA 3 - SOLO PANEL A (Global Burden)
# Para evitar trabarse - procesamos por pasos

rm(list = ls())

library(ggplot2)
library(dplyr)
library(tidyr)
library(stringr)
library(readr)
library(purrr)

source("config/config_pipeline_2.R")

cat("\n🎨 FIGURA 3 - PANEL A ONLY (rápido)\n")
cat("═══════════════════════════════════════════════════════════\n\n")

# --- Load ONLY what we need ---
raw_data_path <- file.path(data_dir, "miRNA_count.Q33.txt")
cat("📥 Loading data...\n")
raw_data <- read_tsv(raw_data_path, show_col_types = FALSE)
cat("✅ Loaded:", nrow(raw_data), "rows\n\n")

# --- Process ONLY G>T mutations (más rápido) ---
cat("🔄 Processing G>T mutations only...\n")
gt_data <- raw_data %>%
  filter(str_detect(`pos:mut`, "GT")) %>%  # Solo filas con GT
  separate_rows(`pos:mut`, sep = ",") %>%
  filter(str_detect(`pos:mut`, "GT"))  # Solo mutaciones GT

cat("✅ G>T rows:", nrow(gt_data), "\n\n")

# --- Extract groups ---
sample_cols <- names(gt_data)[3:ncol(gt_data)]
als_samples <- sample_cols[str_detect(sample_cols, regex("ALS", ignore_case = TRUE))]
control_samples <- sample_cols[str_detect(sample_cols, regex("control", ignore_case = TRUE))]

cat("👥 Groups:\n")
cat("   • ALS:", length(als_samples), "samples\n")
cat("   • Control:", length(control_samples), "samples\n\n")

# --- Calculate global burden per sample ---
cat("📊 Calculating global burden per sample...\n")

# For ALS samples
als_burden <- tibble(
  sample_name = als_samples,
  gt_count = map_dbl(als_samples, ~sum(!is.na(gt_data[[.x]]) & gt_data[[.x]] > 0)),
  group = "ALS"
)

# For Control samples
control_burden <- tibble(
  sample_name = control_samples,
  gt_count = map_dbl(control_samples, ~sum(!is.na(gt_data[[.x]]) & gt_data[[.x]] > 0)),
  group = "Control"
)

global_burden <- bind_rows(als_burden, control_burden)

cat("✅ Burden calculated\n")
cat("   • ALS median:", median(als_burden$gt_count), "\n")
cat("   • Control median:", median(control_burden$gt_count), "\n\n")

# --- Statistical test ---
wilcox_test <- wilcox.test(als_burden$gt_count, control_burden$gt_count)
p_value <- wilcox_test$p.value
effect_size <- (median(als_burden$gt_count) - median(control_burden$gt_count)) / median(control_burden$gt_count) * 100

cat("📊 Statistics:\n")
cat("   • Wilcoxon p-value:", p_value, "\n")
cat("   • Effect size:", effect_size, "%\n\n")

# --- COLORS ---
COLOR_ALS <- "#D62728"
COLOR_CONTROL <- "grey60"

# --- Create Panel A ---
cat("🎨 Creating Panel A...\n")

panel_a <- ggplot(global_burden, aes(x = group, y = gt_count, fill = group)) +
  geom_violin(alpha = 0.7, width = 0.8) +
  geom_boxplot(width = 0.3, alpha = 0.9, outlier.shape = NA) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL), guide = "none") +
  labs(
    title = "A. Global G>T Burden Comparison",
    subtitle = sprintf("Wilcoxon p = %.3f | Effect size = %.1f%%", p_value, effect_size),
    x = "Group",
    y = "Count of G>T mutations per sample"
  ) +
  theme_classic(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 13, hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5, color = "gray40"),
    axis.text = element_text(size = 10),
    panel.grid.major = element_line(color = "grey90", linewidth = 0.3)
  )

ggsave(file.path(figures_dir, "panel_a_global_burden_CORRECTED.png"), 
       plot = panel_a, width = 8, height = 6, dpi = 300, bg = "white")

cat("✅ Panel A saved!\n\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("  🎉 PANEL A COMPLETE\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")
cat("📁 Output: figures/panel_a_global_burden_CORRECTED.png\n\n")
