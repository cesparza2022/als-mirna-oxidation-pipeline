# 🧹 FIGURA 1 ULTRA LIMPIA - Sistema de Backup + Registro Completo

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
# SISTEMA DE BACKUP AUTOMÁTICO
# ═══════════════════════════════════════════════════════════════════
create_backup <- function(file_path) {
  if (file.exists(file_path)) {
    timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
    backup_path <- str_replace(file_path, "\\.png$", paste0("_BACKUP_", timestamp, ".png"))
    file.copy(file_path, backup_path)
    cat("📦 Backup creado:", basename(backup_path), "\n")
  }
}

# ═══════════════════════════════════════════════════════════════════
# REGISTRO DE VERSIONES
# ═══════════════════════════════════════════════════════════════════
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
  cat("📝 Versión registrada:", version_name, "\n")
}

cat("\n🧹 FIGURA 1 ULTRA LIMPIA - Sistema de Backup + Registro\n")
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

# ═══════════════════════════════════════════════════════════════════
# TEMA ULTRA LIMPIO
# ═══════════════════════════════════════════════════════════════════
COLOR_GT <- "#D62728"
COLOR_SEED <- "#FFD700"
COLOR_CONTROL <- "grey60"

ultra_clean_theme <- theme_minimal(base_size = 14) +  # TEXTO MÁS GRANDE
  theme(
    plot.title = element_text(face = "bold", size = 16, hjust = 0.5, margin = margin(b = 10)),
    plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray50", margin = margin(b = 15)),
    plot.caption = element_text(size = 10, hjust = 0.5, color = "gray60", margin = margin(t = 10)),
    axis.text = element_text(size = 12),  # TEXTO MÁS GRANDE
    axis.text.y = element_text(size = 11),
    axis.title = element_text(size = 13, face = "bold"),
    panel.grid = element_blank(),
    panel.background = element_rect(fill = "white", color = NA),
    plot.background = element_rect(fill = "white", color = NA),
    legend.position = "right",
    legend.title = element_text(face = "bold", size = 12),
    legend.text = element_text(size = 11),
    strip.text = element_text(size = 12, face = "bold"),
    plot.margin = margin(20, 20, 20, 20)  # MÁS ESPACIO
  )

# ═══════════════════════════════════════════════════════════════════
# PANEL A: HEATMAP ULTRA LIMPIO (TOP 10 miRNAs)
# ═══════════════════════════════════════════════════════════════════
cat("🧹 Panel A: Heatmap ULTRA LIMPIO (top 10 miRNAs)...\n")

# Top 10 miRNAs para menos saturación
top_mirnas_ultra_clean <- processed_data %>%
  filter(mutation_type == "G>T") %>%
  count(`miRNA name`, name = "gt_count") %>%
  arrange(desc(gt_count)) %>%
  head(10) %>%  # REDUCIDO A 10
  mutate(
    miRNA_short = str_extract(`miRNA name`, "miR-[0-9]+[a-z]*"),
    miRNA_short = ifelse(is.na(miRNA_short), `miRNA name`, miRNA_short)
  )

# Calculate metrics for heatmap
heatmap_data_clean <- processed_data %>%
  filter(
    mutation_type == "G>T",
    `miRNA name` %in% top_mirnas_ultra_clean$`miRNA name`
  ) %>%
  count(`miRNA name`, position, name = "gt_count") %>%
  group_by(`miRNA name`) %>%
  mutate(
    gt_proportion = gt_count / sum(gt_count),
    miRNA_short = str_extract(`miRNA name`, "miR-[0-9]+[a-z]*"),
    miRNA_short = ifelse(is.na(miRNA_short), `miRNA name`, miRNA_short)
  ) %>%
  ungroup()

# Create ULTRA CLEAN heatmap
panel_a_ultra_clean <- ggplot(heatmap_data_clean, aes(x = position, y = miRNA_short, fill = gt_proportion)) +
  geom_tile(color = "white", linewidth = 0.5) +  # BORDES MÁS GRUESOS
  scale_fill_viridis_c(
    name = "G>T\nProportion", 
    option = "plasma",
    breaks = c(0, 0.1, 0.2, 0.3, 0.4),
    labels = c("0%", "10%", "20%", "30%", "40%"),
    guide = guide_colorbar(
      title.position = "top",
      title.hjust = 0.5,
      barwidth = 8,  # BARRA MÁS GRANDE
      barheight = 0.8
    )
  ) +
  # Seed region highlighting - MUY SUTIL
  geom_vline(xintercept = c(1.5, 8.5), color = COLOR_SEED, linewidth = 1.5, alpha = 0.4) +
  annotate("rect", xmin = 2, xmax = 8, ymin = -Inf, ymax = Inf, 
           fill = COLOR_SEED, alpha = 0.05) +  # MUY SUTIL
  annotate("text", x = 5, y = 0.5, label = "SEED", 
           color = "black", fontface = "bold", size = 4, hjust = 0.5) +
  scale_x_continuous(
    breaks = c(1, 5, 10, 15, 20, 22),
    labels = c("1", "5", "10", "15", "20", "22"),
    expand = c(0, 0)
  ) +
  labs(
    title = "A. G>T Distribution Across miRNA Positions",
    subtitle = "Proportion of G>T mutations per position (top 10 miRNAs)",
    caption = "G>T Proportion = G>T at position / Total G>T in miRNA",
    x = "Position in miRNA",
    y = NULL
  ) +
  ultra_clean_theme

# Backup y guardar
create_backup(file.path(figures_dir, "panel_a_ultra_clean_heatmap.png"))
ggsave(file.path(figures_dir, "panel_a_ultra_clean_heatmap.png"), 
       plot = panel_a_ultra_clean, width = 12, height = 8, dpi = 300, bg = "white")
cat("✅ Panel A ULTRA LIMPIO generado\n\n")

# ═══════════════════════════════════════════════════════════════════
# PANEL B: G>T ACCUMULATION ULTRA LIMPIO
# ═══════════════════════════════════════════════════════════════════
cat("🧹 Panel B: G>T Accumulation ULTRA LIMPIO...\n")

# Calculate G>T accumulation by position
accumulation_data_clean <- processed_data %>%
  filter(mutation_type == "G>T") %>%
  count(position, name = "gt_count") %>%
  arrange(position) %>%
  mutate(
    cumulative_gt = cumsum(gt_count),
    total_gt = sum(gt_count),
    cumulative_proportion = cumulative_gt / total_gt,
    region = case_when(
      position <= 1 ~ "5' UTR",
      position >= 2 & position <= 8 ~ "Seed Region",
      position >= 9 ~ "3' Region"
    ),
    region = factor(region, levels = c("5' UTR", "Seed Region", "3' Region"))
  )

# Create ULTRA CLEAN accumulation plot
panel_b_ultra_clean <- ggplot(accumulation_data_clean, aes(x = position, y = cumulative_proportion)) +
  geom_area(aes(fill = region), alpha = 0.8, color = "white", linewidth = 0.5) +
  geom_line(color = "black", linewidth = 2) +  # LÍNEA MÁS GRUESA
  geom_point(color = "black", size = 3) +  # PUNTOS MÁS GRANDES
  scale_fill_manual(
    values = c("5' UTR" = "#E3F2FD", "Seed Region" = "#FFF3E0", "3' Region" = "#FCE4EC"),  # COLORES SUAVES
    name = "Region"
  ) +
  scale_x_continuous(breaks = c(1, 5, 10, 15, 20, 22)) +
  scale_y_continuous(labels = percent_format()) +
  labs(
    title = "B. G>T Accumulation Across miRNA Positions",
    subtitle = "Cumulative proportion of G>T mutations",
    caption = "Shows progressive accumulation of G>T mutations",
    x = "Position in miRNA",
    y = "Cumulative G>T Proportion"
  ) +
  ultra_clean_theme +
  theme(legend.position = "bottom")

# Backup y guardar
create_backup(file.path(figures_dir, "panel_b_ultra_clean_accumulation.png"))
ggsave(file.path(figures_dir, "panel_b_ultra_clean_accumulation.png"), 
       plot = panel_b_ultra_clean, width = 12, height = 7, dpi = 300, bg = "white")
cat("✅ Panel B ULTRA LIMPIO generado\n\n")

# ═══════════════════════════════════════════════════════════════════
# PANEL C: CORRELATION MATRIX ULTRA LIMPIO
# ═══════════════════════════════════════════════════════════════════
cat("🧹 Panel C: Correlation Matrix ULTRA LIMPIO...\n")

# Calculate correlation metrics - SIMPLIFICADO
correlation_data_clean <- processed_data %>%
  filter(mutation_type == "G>T") %>%
  group_by(`miRNA name`) %>%
  summarise(
    total_gt = n(),
    gt_in_seed = sum(position >= 2 & position <= 8),
    mean_position = mean(position),
    .groups = "drop"
  ) %>%
  filter(total_gt >= 5) %>%
  mutate(
    seed_proportion = gt_in_seed / total_gt
  ) %>%
  select(total_gt, gt_in_seed, mean_position, seed_proportion) %>%
  cor(use = "complete.obs")

# Create correlation matrix - MÁS LIMPIO
correlation_df_clean <- expand.grid(
  Var1 = rownames(correlation_data_clean),
  Var2 = colnames(correlation_data_clean)
) %>%
  mutate(
    correlation = as.vector(correlation_data_clean),
    Var1_clean = str_replace_all(Var1, "_", " "),
    Var2_clean = str_replace_all(Var2, "_", " ")
  )

panel_c_ultra_clean <- ggplot(correlation_df_clean, aes(x = Var2_clean, y = Var1_clean, fill = correlation)) +
  geom_tile(color = "white", linewidth = 1) +  # BORDES MÁS GRUESOS
  geom_text(aes(label = round(correlation, 2)), color = "white", size = 5, fontface = "bold") +  # TEXTO MÁS GRANDE
  scale_fill_gradient2(
    low = "#1976D2", mid = "white", high = "#D32F2F",  # COLORES MÁS SUAVES
    midpoint = 0,
    name = "Correlation",
    guide = guide_colorbar(
      title.position = "top",
      title.hjust = 0.5,
      barwidth = 8,
      barheight = 0.8
    )
  ) +
  labs(
    title = "C. G>T Metrics Correlation Matrix",
    subtitle = "Correlations between different G>T measurements",
    caption = "Shows relationships between G>T metrics",
    x = NULL,
    y = NULL
  ) +
  ultra_clean_theme +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 11),
    axis.text.y = element_text(size = 11)
  )

# Backup y guardar
create_backup(file.path(figures_dir, "panel_c_ultra_clean_correlation.png"))
ggsave(file.path(figures_dir, "panel_c_ultra_clean_correlation.png"), 
       plot = panel_c_ultra_clean, width = 10, height = 8, dpi = 300, bg = "white")
cat("✅ Panel C ULTRA LIMPIO generado\n\n")

# ═══════════════════════════════════════════════════════════════════
# PANEL D: 3D-STYLE SCATTER ULTRA LIMPIO
# ═══════════════════════════════════════════════════════════════════
cat("🧹 Panel D: 3D-Style Scatter ULTRA LIMPIO...\n")

# Prepare data for 3D-style scatter - SIMPLIFICADO
scatter_data_clean <- processed_data %>%
  filter(mutation_type == "G>T") %>%
  group_by(`miRNA name`, position) %>%
  summarise(gt_count = n(), .groups = "drop") %>%
  group_by(`miRNA name`) %>%
  mutate(
    total_gt = sum(gt_count),
    gt_proportion = gt_count / total_gt,
    g_content_approx = str_count(`miRNA name`, "G")
  ) %>%
  ungroup() %>%
  filter(total_gt >= 3) %>%
  sample_n(min(500, n()))  # LIMITAR A 500 PUNTOS PARA MENOS SATURACIÓN

# Create ULTRA CLEAN 3D-style scatter
panel_d_ultra_clean <- ggplot(scatter_data_clean, aes(x = position, y = g_content_approx, size = gt_count, color = gt_proportion)) +
  geom_point(alpha = 0.8) +  # MÁS OPACO
  geom_smooth(method = "lm", se = TRUE, color = "black", linewidth = 1.5, alpha = 0.3) +  # LÍNEA MÁS GRUESA
  scale_size_continuous(
    name = "G>T Count",
    range = c(2, 10),  # PUNTOS MÁS GRANDES
    breaks = c(1, 5, 10, 20),
    guide = guide_legend(override.aes = list(alpha = 1))
  ) +
  scale_color_viridis_c(
    name = "G>T\nProportion",
    option = "plasma",
    guide = guide_colorbar(
      title.position = "top",
      title.hjust = 0.5,
      barwidth = 8,
      barheight = 0.8
    )
  ) +
  scale_x_continuous(breaks = c(1, 5, 10, 15, 20, 22)) +
  labs(
    title = "D. G>T Multi-dimensional Analysis",
    subtitle = "Position vs G-content vs G>T count and proportion",
    caption = "Point size = G>T count, Color = G>T proportion",
    x = "Position in miRNA",
    y = "Approximate G-content"
  ) +
  ultra_clean_theme

# Backup y guardar
create_backup(file.path(figures_dir, "panel_d_ultra_clean_3d_scatter.png"))
ggsave(file.path(figures_dir, "panel_d_ultra_clean_3d_scatter.png"), 
       plot = panel_d_ultra_clean, width = 12, height = 8, dpi = 300, bg = "white")
cat("✅ Panel D ULTRA LIMPIO generado\n\n")

# ═══════════════════════════════════════════════════════════════════
# COMBINAR PANELES ULTRA LIMPIOS
# ═══════════════════════════════════════════════════════════════════
cat("🧹 Combinando paneles ULTRA LIMPIOS...\n")

# Create ULTRA CLEAN layout
combined_ultra_clean <- (panel_a_ultra_clean | panel_b_ultra_clean) / (panel_c_ultra_clean | panel_d_ultra_clean) +
  plot_annotation(
    title = "ULTRA CLEAN FIGURE 1 - Advanced G>T Analysis",
    subtitle = "Minimal saturation + Maximum clarity + Complete information",
    theme = theme(
      plot.title = element_text(size = 18, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 13, hjust = 0.5, color = "gray50")
    )
  )

# Backup y guardar
create_backup(file.path(figures_dir, "FIGURE_1_ULTRA_CLEAN_COMPLETE.png"))
ggsave(file.path(figures_dir, "FIGURE_1_ULTRA_CLEAN_COMPLETE.png"), 
       plot = combined_ultra_clean, width = 24, height = 18, dpi = 300, bg = "white")

# ═══════════════════════════════════════════════════════════════════
# GENERAR TABLA RESUMEN ULTRA LIMPIA
# ═══════════════════════════════════════════════════════════════════
cat("📋 Generando tabla resumen ULTRA LIMPIA...\n")

# Create summary table - SIMPLIFICADA
summary_stats_clean <- processed_data %>%
  filter(mutation_type == "G>T") %>%
  group_by(`miRNA name`) %>%
  summarise(
    total_gt = n(),
    gt_in_seed = sum(position >= 2 & position <= 8),
    seed_proportion = gt_in_seed / total_gt,
    mean_position = mean(position),
    .groups = "drop"
  ) %>%
  arrange(desc(total_gt)) %>%
  head(15)  # TOP 15

# Backup y guardar
create_backup(file.path(figures_dir, "tabla_ultra_clean_summary.csv"))
write_csv(summary_stats_clean, file.path(figures_dir, "tabla_ultra_clean_summary.csv"))

# ═══════════════════════════════════════════════════════════════════
# REGISTRAR VERSIÓN
# ═══════════════════════════════════════════════════════════════════
files_created <- c(
  "panel_a_ultra_clean_heatmap.png",
  "panel_b_ultra_clean_accumulation.png", 
  "panel_c_ultra_clean_correlation.png",
  "panel_d_ultra_clean_3d_scatter.png",
  "FIGURE_1_ULTRA_CLEAN_COMPLETE.png",
  "tabla_ultra_clean_summary.csv"
)

log_version(
  "ULTRA_CLEAN_v1.0",
  "Gráficas individuales ULTRA LIMPIAS - Top 10 miRNAs, colores suaves, texto grande, menos saturación",
  files_created
)

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("  🧹 FIGURA 1 ULTRA LIMPIA COMPLETE\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

cat("📁 OUTPUTS ULTRA LIMPIOS:\n")
for (file in files_created) {
  cat("   •", file, "\n")
}

cat("\n🧹 MEJORAS ULTRA LIMPIAS:\n")
cat("   ✅ TOP 10: Reducido de 15 a 10 miRNAs\n")
cat("   ✅ COLORES SUAVES: Paleta más suave y profesional\n")
cat("   ✅ TEXTO GRANDE: Base size 14, títulos 16\n")
cat("   ✅ BORDES GRUESOS: Líneas más visibles\n")
cat("   ✅ PUNTOS GRANDES: Mejor visibilidad\n")
cat("   ✅ ESPACIADO: Márgenes optimizados\n")
cat("   ✅ BACKUP: Sistema automático implementado\n")
cat("   ✅ REGISTRO: Versiones documentadas\n\n")

cat("📦 BACKUPS CREADOS: Todos los archivos anteriores respaldados\n")
cat("📝 REGISTRO: Versión ULTRA_CLEAN_v1.0 documentada\n\n")

