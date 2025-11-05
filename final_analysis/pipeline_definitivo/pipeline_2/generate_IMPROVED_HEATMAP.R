# 🎨 HEATMAP MEJORADO - Con claridad de métricas y contexto biológico

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

cat("\n🎨 HEATMAP MEJORADO - Claridad de métricas y contexto biológico\n")
cat("═══════════════════════════════════════════════════════════\n\n")

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

# --- COLORS & THEME ---
COLOR_GT <- "#D62728"
COLOR_SEED <- "#FFD700"

improved_theme <- theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray40"),
    plot.caption = element_text(size = 10, hjust = 0.5, color = "gray60"),
    axis.text = element_text(size = 11),
    axis.text.y = element_text(size = 10, face = "bold"),
    panel.grid = element_blank(),
    legend.position = "right",
    legend.title = element_text(face = "bold", size = 12),
    legend.text = element_text(size = 11)
  )

# ═══════════════════════════════════════════════════════════════════
# CALCULAR MÉTRICAS CLARAS Y DEFINIDAS
# ═══════════════════════════════════════════════════════════════════
cat("📊 Calculando métricas claras y definidas...\n")

# Top miRNAs with G>T for heatmap
top_mirnas_for_heatmap <- processed_data %>%
  filter(mutation_type == "G>T") %>%
  count(`miRNA name`, name = "gt_count") %>%
  arrange(desc(gt_count)) %>%
  head(20) %>%
  mutate(
    miRNA_short = str_extract(`miRNA name`, "miR-[0-9]+[a-z]*"),
    miRNA_short = ifelse(is.na(miRNA_short), `miRNA name`, miRNA_short)
  )

# Calculate CLEAR metrics for heatmap
heatmap_data <- processed_data %>%
  filter(
    mutation_type == "G>T",
    `miRNA name` %in% top_mirnas_for_heatmap$`miRNA name`
  ) %>%
  count(`miRNA name`, position, name = "gt_count") %>%
  group_by(`miRNA name`) %>%
  mutate(
    # MÉTRICA CLARA: Proporción de G>T en cada posición relativa al total de G>T en ese miRNA
    gt_proportion = gt_count / sum(gt_count),
    # MÉTRICA ALTERNATIVA: Frecuencia absoluta normalizada por el máximo
    gt_frequency_norm = gt_count / max(gt_count),
    # MÉTRICA DE CONTEXTO: Si la posición está en seed region
    in_seed = position >= 2 & position <= 8,
    miRNA_short = str_extract(`miRNA name`, "miR-[0-9]+[a-z]*"),
    miRNA_short = ifelse(is.na(miRNA_short), `miRNA name`, miRNA_short)
  ) %>%
  ungroup()

# Calculate statistics for annotations
seed_stats <- heatmap_data %>%
  group_by(in_seed) %>%
  summarise(
    mean_proportion = mean(gt_proportion),
    median_proportion = median(gt_proportion),
    n_positions = n(),
    .groups = "drop"
  )

cat("✅ Métricas calculadas:\n")
cat("   • gt_proportion: Proporción de G>T en cada posición relativa al total del miRNA\n")
cat("   • gt_frequency_norm: Frecuencia absoluta normalizada por el máximo\n")
cat("   • Seed region: posiciones 2-8\n\n")

# ═══════════════════════════════════════════════════════════════════
# HEATMAP MEJORADO CON MÉTRICAS CLARAS
# ═══════════════════════════════════════════════════════════════════
cat("🎨 Generando heatmap mejorado...\n")

# Create improved heatmap
panel_improved <- ggplot(heatmap_data, aes(x = position, y = miRNA_short, fill = gt_proportion)) +
  geom_tile(color = "white", linewidth = 0.3) +
  scale_fill_viridis_c(
    name = "G>T\nProportion", 
    option = "plasma",
    breaks = c(0, 0.1, 0.2, 0.3, 0.4, 0.5),
    labels = c("0%", "10%", "20%", "30%", "40%", "50%"),
    guide = guide_colorbar(
      title.position = "top",
      title.hjust = 0.5,
      barwidth = 8,
      barheight = 0.8
    )
  ) +
  # Seed region highlighting
  geom_vline(xintercept = c(1.5, 8.5), color = COLOR_SEED, linewidth = 2, alpha = 0.8) +
  annotate("rect", xmin = 2, xmax = 8, ymin = -Inf, ymax = Inf, 
           fill = COLOR_SEED, alpha = 0.15) +
  annotate("text", x = 5, y = 0.5, label = "SEED REGION\n(positions 2-8)", 
           color = "black", fontface = "bold", size = 4, hjust = 0.5) +
  # Position labels
  scale_x_continuous(
    breaks = c(1, 5, 10, 15, 20, 22),
    labels = c("1", "5", "10", "15", "20", "22"),
    expand = c(0, 0)
  ) +
  labs(
    title = "A. G>T Mutation Distribution Across miRNA Positions",
    subtitle = "Proportion of G>T mutations per position relative to total G>T in each miRNA",
    caption = paste0(
      "Data: Top 20 miRNAs with highest G>T counts | ",
      "Metric: Proportion = G>T at position / Total G>T in miRNA | ",
      "Seed region: positions 2-8 (critical for target recognition) | ",
      "White cells: No G>T mutations detected at that position"
    ),
    x = "Position in miRNA (5' → 3')",
    y = NULL
  ) +
  improved_theme +
  theme(
    axis.text.x = element_text(size = 11, face = "bold"),
    plot.caption = element_text(size = 9, hjust = 0.5, color = "gray50")
  )

ggsave(file.path(figures_dir, "panel_a_improved_heatmap_gt_distribution.png"), 
       plot = panel_improved, width = 14, height = 10, dpi = 300, bg = "white")
cat("✅ Heatmap mejorado generado\n\n")

# ═══════════════════════════════════════════════════════════════════
# PANEL ADICIONAL: ESTADÍSTICAS DE SEED VS NON-SEED
# ═══════════════════════════════════════════════════════════════════
cat("📊 Generando panel de estadísticas...\n")

# Create summary statistics panel
summary_data <- heatmap_data %>%
  group_by(position, in_seed) %>%
  summarise(
    mean_proportion = mean(gt_proportion),
    median_proportion = median(gt_proportion),
    n_mirnas = n(),
    .groups = "drop"
  ) %>%
  mutate(
    region = ifelse(in_seed, "Seed Region", "Non-Seed Region"),
    region = factor(region, levels = c("Seed Region", "Non-Seed Region"))
  )

panel_stats <- ggplot(summary_data, aes(x = position, y = mean_proportion, fill = region)) +
  geom_col(alpha = 0.8, width = 0.8) +
  scale_fill_manual(values = c("Seed Region" = COLOR_SEED, "Non-Seed Region" = "steelblue")) +
  geom_vline(xintercept = c(2, 8), color = "red", linetype = "dashed", alpha = 0.7) +
  annotate("rect", xmin = 2, xmax = 8, ymin = 0, ymax = max(summary_data$mean_proportion), 
           fill = COLOR_SEED, alpha = 0.1) +
  annotate("text", x = 5, y = max(summary_data$mean_proportion) * 0.9, 
           label = "SEED REGION", color = "black", fontface = "bold", size = 4) +
  scale_x_continuous(breaks = 1:22, labels = 1:22) +
  labs(
    title = "B. Mean G>T Proportion by Position and Region",
    subtitle = "Average proportion of G>T mutations across top 20 miRNAs",
    x = "Position in miRNA",
    y = "Mean G>T Proportion",
    fill = "Region"
  ) +
  improved_theme +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
    legend.position = "bottom"
  )

ggsave(file.path(figures_dir, "panel_b_improved_seed_vs_nonseed_stats.png"), 
       plot = panel_stats, width = 14, height = 8, dpi = 300, bg = "white")
cat("✅ Panel de estadísticas generado\n\n")

# ═══════════════════════════════════════════════════════════════════
# COMBINAR PANELES MEJORADOS
# ═══════════════════════════════════════════════════════════════════
cat("🎨 Combinando paneles mejorados...\n")

combined_improved <- panel_improved / panel_stats +
  plot_annotation(
    title = "IMPROVED G>T ANALYSIS - Clear Metrics & Biological Context",
    subtitle = "Peer reviewer feedback addressed: Clear metrics, biological context, and statistical interpretation",
    theme = theme(
      plot.title = element_text(size = 18, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray50")
    )
  )

ggsave(file.path(figures_dir, "FIGURE_IMPROVED_HEATMAP_COMPLETE.png"), 
       plot = combined_improved, width = 16, height = 20, dpi = 300, bg = "white")

# ═══════════════════════════════════════════════════════════════════
# GENERAR TABLA DE ESTADÍSTICAS
# ═══════════════════════════════════════════════════════════════════
cat("📋 Generando tabla de estadísticas...\n")

# Create detailed statistics table
detailed_stats <- heatmap_data %>%
  group_by(miRNA_short, in_seed) %>%
  summarise(
    total_gt = sum(gt_count),
    mean_proportion = mean(gt_proportion),
    max_proportion = max(gt_proportion),
    positions_with_gt = n(),
    .groups = "drop"
  ) %>%
  pivot_wider(
    names_from = in_seed,
    values_from = c(total_gt, mean_proportion, max_proportion, positions_with_gt),
    names_sep = "_"
  ) %>%
  mutate(
    seed_gt = total_gt_TRUE,
    nonseed_gt = total_gt_FALSE,
    seed_proportion = mean_proportion_TRUE,
    nonseed_proportion = mean_proportion_FALSE,
    seed_positions = positions_with_gt_TRUE,
    nonseed_positions = positions_with_gt_FALSE
  ) %>%
  select(miRNA_short, seed_gt, nonseed_gt, seed_proportion, nonseed_proportion, 
         seed_positions, nonseed_positions) %>%
  arrange(desc(seed_gt + nonseed_gt))

write_csv(detailed_stats, file.path(figures_dir, "tabla_improved_heatmap_stats.csv"))
cat("✅ Tabla de estadísticas generada\n\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("  🎉 HEATMAP MEJORADO COMPLETE\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

cat("📁 OUTPUTS MEJORADOS:\n")
cat("   • panel_a_improved_heatmap_gt_distribution.png\n")
cat("   • panel_b_improved_seed_vs_nonseed_stats.png\n")
cat("   • FIGURE_IMPROVED_HEATMAP_COMPLETE.png\n")
cat("   • tabla_improved_heatmap_stats.csv\n\n")

cat("🔬 MEJORAS IMPLEMENTADAS (Peer Reviewer Feedback):\n")
cat("   ✅ MÉTRICA CLARA: 'G>T Proportion' = G>T at position / Total G>T in miRNA\n")
cat("   ✅ ESCALA CONTINUA: 0% to 50% con breaks claros\n")
cat("   ✅ CONTEXTO BIOLÓGICO: Seed region explicada y destacada\n")
cat("   ✅ CELDAS BLANCAS: Explicadas como 'No G>T detected'\n")
cat("   ✅ ESTADÍSTICAS: Panel B con comparación Seed vs Non-Seed\n")
cat("   ✅ CAPTION: Explicación completa de métricas y contexto\n")
cat("   ✅ TABLA: Estadísticas detalladas por miRNA y región\n\n")

cat("📊 MÉTRICAS DEFINIDAS:\n")
cat("   • gt_proportion: Proporción relativa (0-1)\n")
cat("   • gt_frequency_norm: Frecuencia normalizada\n")
cat("   • Seed region: posiciones 2-8 (crítico para reconocimiento)\n")
cat("   • White cells: Sin mutaciones G>T detectadas\n\n")

