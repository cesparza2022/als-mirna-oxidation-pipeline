# 🎨 GENERAR PANELES ULTRA CLEAN FALTANTES + FIGURA HÍBRIDA

rm(list = ls())

library(ggplot2)
library(dplyr)
library(tidyr)
library(stringr)
library(patchwork)
library(readr)
library(purrr)
library(scales)
library(viridis)

source("config/config_pipeline_2.R")

# ═══════════════════════════════════════════════════════════════════
# SISTEMA DE BACKUP Y REGISTRO
# ═══════════════════════════════════════════════════════════════════
create_backup <- function(file_path) {
  if (file.exists(file_path)) {
    timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
    backup_path <- str_replace(file_path, "\\.png$", paste0("_BACKUP_", timestamp, ".png"))
    file.copy(file_path, backup_path)
    cat("📦 Backup:", basename(backup_path), "\n")
  }
}

log_version <- function(version_name, description, files_created) {
  log_entry <- paste0(
    "\n=== VERSIÓN: ", version_name, " ===\n",
    "Fecha: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n",
    "Descripción: ", description, "\n",
    "Archivos creados:\n",
    paste("  •", files_created, collapse = "\n"),
    "\n"
  )
  write(log_entry, file = "REGISTRO_VERSIONES.txt", append = TRUE)
}

cat("\n🎨 GENERAR PANELES ULTRA CLEAN FALTANTES + FIGURA HÍBRIDA\n")
cat("═══════════════════════════════════════════════════════════════\n\n")

# --- Load and Process Data ---
raw_data_path <- file.path(data_dir, "miRNA_count.Q33.txt")
raw_data <- read_tsv(raw_data_path, show_col_types = FALSE)

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

cat("✅ Data processed\n\n")

# ═══════════════════════════════════════════════════════════════════
# TEMA ULTRA LIMPIO
# ═══════════════════════════════════════════════════════════════════
COLOR_GT <- "#D62728"
COLOR_SEED <- "#FFD700"
COLOR_CONTROL <- "grey60"

ultra_clean_theme <- theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 16, hjust = 0.5, margin = margin(b = 10)),
    plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray50", margin = margin(b = 15)),
    plot.caption = element_text(size = 10, hjust = 0.5, color = "gray60", margin = margin(t = 10)),
    axis.text = element_text(size = 12),
    axis.text.y = element_text(size = 11),
    axis.title = element_text(size = 13, face = "bold"),
    panel.grid = element_blank(),
    panel.background = element_rect(fill = "white", color = NA),
    plot.background = element_rect(fill = "white", color = NA),
    legend.position = "right",
    legend.title = element_text(face = "bold", size = 12),
    legend.text = element_text(size = 11),
    strip.text = element_text(size = 12, face = "bold"),
    plot.margin = margin(20, 20, 20, 20)
  )

# ═══════════════════════════════════════════════════════════════════
# PANEL E: BOX PLOT + JITTER ULTRA LIMPIO
# ═══════════════════════════════════════════════════════════════════
cat("🎨 Panel E: Box Plot + Jitter ULTRA LIMPIO...\n")

# Calculate G>T by region - SIMPLIFIED VERSION WITHOUT SAMPLES
boxplot_data <- processed_data %>%
  filter(mutation_type == "G>T") %>%
  mutate(
    region = case_when(
      position <= 1 ~ "5' UTR",
      position >= 2 & position <= 8 ~ "Seed",
      position >= 9 ~ "3' Region"
    ),
    region = factor(region, levels = c("5' UTR", "Seed", "3' Region"))
  ) %>%
  group_by(`miRNA name`, region) %>%
  summarise(
    gt_count = n(),
    .groups = "drop"
  ) %>%
  group_by(`miRNA name`) %>%
  mutate(
    total_count = sum(gt_count),
    gt_fraction = gt_count / total_count
  ) %>%
  ungroup()

panel_e_ultra_clean <- ggplot(boxplot_data, aes(x = region, y = gt_fraction, fill = region)) +
  geom_boxplot(alpha = 0.7, outlier.shape = NA, linewidth = 1) +
  geom_jitter(width = 0.2, alpha = 0.4, size = 2) +
  scale_fill_manual(
    values = c("5' UTR" = "#E3F2FD", "Seed" = "#FFF3E0", "3' Region" = "#FCE4EC"),
    name = "miRNA Region"
  ) +
  scale_y_continuous(labels = percent_format()) +
  labs(
    title = "E. G>T Distribution by miRNA Region",
    subtitle = "Fraction of G>T mutations per miRNA in each region",
    caption = "Box plot shows median and quartiles, points show individual miRNAs",
    x = "miRNA Region",
    y = "G>T Fraction per miRNA"
  ) +
  ultra_clean_theme +
  theme(legend.position = "none")

create_backup(file.path(figures_dir, "panel_e_ultra_clean_boxplot_jitter.png"))
ggsave(file.path(figures_dir, "panel_e_ultra_clean_boxplot_jitter.png"), 
       plot = panel_e_ultra_clean, width = 10, height = 7, dpi = 300, bg = "white")
cat("✅ Panel E ULTRA LIMPIO generado\n\n")

# ═══════════════════════════════════════════════════════════════════
# PANEL F: G>X SPECTRUM ULTRA LIMPIO
# ═══════════════════════════════════════════════════════════════════
cat("🎨 Panel F: G>X Spectrum ULTRA LIMPIO...\n")

# Calculate G>X spectrum by position - SIMPLIFIED
spectrum_data <- processed_data %>%
  filter(mutation_type %in% c("G>T", "G>A", "G>C")) %>%
  count(position, mutation_type, name = "count") %>%
  group_by(position) %>%
  mutate(
    total = sum(count),
    proportion = count / total
  ) %>%
  ungroup()

# Calculate summary stats for seed region
seed_stats <- spectrum_data %>%
  filter(position >= 2 & position <= 8) %>%
  group_by(mutation_type) %>%
  summarise(
    total_count = sum(count),
    mean_proportion = mean(proportion),
    .groups = "drop"
  )

panel_f_ultra_clean <- ggplot(spectrum_data, aes(x = position, y = count, fill = mutation_type)) +
  geom_col(position = "dodge", width = 0.8) +
  # Seed region highlighting - SUTIL
  annotate("rect", xmin = 1.5, xmax = 8.5, ymin = -Inf, ymax = Inf, 
           fill = COLOR_SEED, alpha = 0.05) +
  geom_vline(xintercept = c(1.5, 8.5), color = COLOR_SEED, linewidth = 1, alpha = 0.4) +
  scale_fill_manual(
    values = c("G>T" = COLOR_GT, "G>A" = "#1976D2", "G>C" = "#388E3C"),
    name = "Mutation Type"
  ) +
  scale_x_continuous(breaks = c(1, 5, 10, 15, 20, 22)) +
  labs(
    title = "F. G>X Mutation Spectrum by Position",
    subtitle = "Distribution of G>T, G>A, and G>C mutations across miRNA positions",
    caption = "G>T is highlighted as the primary oxidative stress signature",
    x = "Position in miRNA",
    y = "Mutation Count"
  ) +
  ultra_clean_theme +
  theme(legend.position = "bottom")

create_backup(file.path(figures_dir, "panel_f_ultra_clean_spectrum.png"))
ggsave(file.path(figures_dir, "panel_f_ultra_clean_spectrum.png"), 
       plot = panel_f_ultra_clean, width = 12, height = 7, dpi = 300, bg = "white")
cat("✅ Panel F ULTRA LIMPIO generado\n\n")

# ═══════════════════════════════════════════════════════════════════
# PANEL G: SEED VS NON-SEED STATS ULTRA LIMPIO
# ═══════════════════════════════════════════════════════════════════
cat("🎨 Panel G: Seed vs Non-Seed Stats ULTRA LIMPIO...\n")

# Calculate seed vs non-seed stats
seed_nonseed_data <- processed_data %>%
  filter(mutation_type == "G>T") %>%
  mutate(
    region_type = ifelse(position >= 2 & position <= 8, "Seed\n(pos 2-8)", "Non-Seed\n(other)")
  ) %>%
  count(region_type, name = "gt_count")

# Calculate proportions
total_gt <- sum(seed_nonseed_data$gt_count)
seed_nonseed_data <- seed_nonseed_data %>%
  mutate(
    proportion = gt_count / total_gt,
    percentage = proportion * 100
  )

panel_g_ultra_clean <- ggplot(seed_nonseed_data, aes(x = region_type, y = gt_count, fill = region_type)) +
  geom_col(width = 0.6, alpha = 0.8) +
  geom_text(aes(label = paste0(round(percentage, 1), "%\n(n=", scales::comma(gt_count), ")")),
            vjust = -0.5, size = 5, fontface = "bold") +
  scale_fill_manual(
    values = c("Seed\n(pos 2-8)" = "#FFF3E0", "Non-Seed\n(other)" = "#E3F2FD"),
    name = "Region Type"
  ) +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "G. Seed vs Non-Seed G>T Distribution",
    subtitle = "Comparison of G>T mutation burden in seed and non-seed regions",
    caption = "Seed region (positions 2-8) is critical for miRNA function",
    x = "Region Type",
    y = "G>T Mutation Count"
  ) +
  ultra_clean_theme +
  theme(legend.position = "none")

create_backup(file.path(figures_dir, "panel_g_ultra_clean_seed_vs_nonseed.png"))
ggsave(file.path(figures_dir, "panel_g_ultra_clean_seed_vs_nonseed.png"), 
       plot = panel_g_ultra_clean, width = 10, height = 7, dpi = 300, bg = "white")
cat("✅ Panel G ULTRA LIMPIO generado\n\n")

# ═══════════════════════════════════════════════════════════════════
# FIGURA HÍBRIDA: COMBINANDO MEJORES ELEMENTOS
# ═══════════════════════════════════════════════════════════════════
cat("🎨 Creando FIGURA EXTENDIDA (paneles complementarios)...\n")

# Create 3-panel extended version with the new panels
extended_hybrid <- (panel_e_ultra_clean | panel_f_ultra_clean) / 
                   panel_g_ultra_clean +
  plot_annotation(
    title = "ULTRA CLEAN FIGURE 1 - Extended Analysis",
    subtitle = "Distribution + Spectrum + Seed vs Non-Seed Statistics",
    theme = theme(
      plot.title = element_text(size = 18, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 13, hjust = 0.5, color = "gray50")
    )
  )

create_backup(file.path(figures_dir, "FIGURE_1_EXTENDED_ULTRA_CLEAN.png"))
ggsave(file.path(figures_dir, "FIGURE_1_EXTENDED_ULTRA_CLEAN.png"), 
       plot = extended_hybrid, width = 24, height = 16, dpi = 300, bg = "white")
cat("✅ Figura Extendida generada\n\n")

# ═══════════════════════════════════════════════════════════════════
# REGISTRAR VERSIÓN
# ═══════════════════════════════════════════════════════════════════
files_created <- c(
  "panel_e_ultra_clean_boxplot_jitter.png",
  "panel_f_ultra_clean_spectrum.png",
  "panel_g_ultra_clean_seed_vs_nonseed.png",
  "FIGURE_1_EXTENDED_ULTRA_CLEAN.png"
)

log_version(
  "EXTENDED_ULTRA_CLEAN_v1.0",
  "Paneles faltantes ULTRA LIMPIOS + Figura extendida - Box Plot, Spectrum, Seed vs Non-Seed",
  files_created
)

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("  🎨 PANELES FALTANTES + FIGURA HÍBRIDA COMPLETE\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

cat("📁 NUEVOS OUTPUTS:\n")
for (file in files_created) {
  cat("   •", file, "\n")
}

cat("\n🎨 PANELES FALTANTES CREADOS:\n")
cat("   ✅ PANEL E: Box Plot + Jitter (distribución por región)\n")
cat("   ✅ PANEL F: G>X Spectrum (contexto mutacional)\n")
cat("   ✅ PANEL G: Seed vs Non-Seed (estadísticas comparativas)\n")
cat("   ✅ FIGURA EXTENDIDA: Combinación de nuevos paneles\n\n")

cat("📦 BACKUPS: Todos los archivos anteriores respaldados\n")
cat("📝 REGISTRO: Versión EXTENDED_ULTRA_CLEAN_v1.0 documentada\n\n")
