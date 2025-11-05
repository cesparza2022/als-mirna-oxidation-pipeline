#!/usr/bin/env Rscript

# ============================================================================
# 🎯 FIGURAS AVANZADAS: TODAS LAS DIMENSIONES (SNVs + Counts + Stats)
# ============================================================================
# Objetivo: Visualizaciones multidimensionales que capturen TODO
# - Heatmaps, bubble plots, faceted plots
# - SNVs, Counts, Media, SD, Max todo integrado

library(ggplot2)
library(dplyr)
library(tidyr)
library(patchwork)
library(tibble)
library(scales)

cat("╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║     🎯 FIGURAS AVANZADAS MULTIDIMENSIONALES                         ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

output_dir <- "/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/pipeline_definitivo/01_analisis_inicial/figures"

# ============================================================================
# 1. CARGAR DATOS CALCULADOS
# ============================================================================

cat("📊 Cargando datos calculados...\n")

sample_metrics <- read.csv("/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/pipeline_definitivo/01_analisis_inicial/tables/ALL_MUTATIONS_sample_metrics.csv")

position_metrics <- read.csv("/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/pipeline_definitivo/01_analisis_inicial/tables/ALL_MUTATIONS_position_metrics.csv")

cat(sprintf("   ✅ Sample metrics: %d filas\n", nrow(sample_metrics)))
cat(sprintf("   ✅ Position metrics: %d filas\n", nrow(position_metrics)))

# Agregar categoría para G>T
sample_metrics <- sample_metrics %>%
  mutate(Category = ifelse(Mutation_Type == "GT", "G>T (Oxidación)", "Otras"))

position_metrics <- position_metrics %>%
  mutate(Category = ifelse(Mutation_Type == "GT", "G>T (Oxidación)", "Otras"))

# ============================================================================
# 2. FIGURA AVANZADA 1: HEATMAP POR MUESTRA (TIPO x MÉTRICA)
# ============================================================================

cat("\n🎨 Generando Figura Avanzada 1: Heatmap por Muestra...\n")

# Calcular promedios por tipo (across all samples)
sample_summary <- sample_metrics %>%
  group_by(Mutation_Type, Category) %>%
  summarise(
    Mean_SNVs = mean(N_SNVs),
    SD_SNVs = sd(N_SNVs),
    Mean_Counts = mean(Mean_Count),
    SD_Counts = sd(Mean_Count),
    Mean_Max = mean(Max_Count),
    Total_Samples = n(),
    .groups = "drop"
  ) %>%
  arrange(desc(Mean_SNVs))

# Formato largo para heatmap
sample_heatmap_data <- sample_summary %>%
  select(Mutation_Type, Category, Mean_SNVs, Mean_Counts, Mean_Max) %>%
  pivot_longer(
    cols = c(Mean_SNVs, Mean_Counts, Mean_Max),
    names_to = "Metric",
    values_to = "Value"
  ) %>%
  mutate(
    Metric = factor(Metric, 
                   levels = c("Mean_SNVs", "Mean_Counts", "Mean_Max"),
                   labels = c("Media SNVs", "Media Counts", "Max Counts"))
  )

# Heatmap
p_heat1 <- ggplot(sample_heatmap_data, aes(x = Metric, y = reorder(Mutation_Type, Value), fill = Value)) +
  geom_tile(color = "white", size = 1) +
  geom_text(aes(label = round(Value, 1)), color = "white", fontface = "bold", size = 3.5) +
  scale_fill_gradient2(
    low = "#1F77B4", mid = "#FF7F0E", high = "#D62728",
    midpoint = median(sample_heatmap_data$Value),
    name = "Valor",
    labels = comma
  ) +
  theme_minimal(base_size = 13) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold"),
    axis.text.y = element_text(face = "bold", color = ifelse(
      levels(reorder(sample_heatmap_data$Mutation_Type, sample_heatmap_data$Value)) == "GT",
      "#D62728", "black"
    )),
    axis.title = element_text(face = "bold", size = 14),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 15),
    panel.grid = element_blank(),
    legend.position = "right"
  ) +
  labs(
    title = "Heatmap: Métricas por Tipo de Mutación (Promedio por Muestra)",
    x = "Métrica",
    y = "Tipo de Mutación"
  )

ggsave(file.path(output_dir, "FIG_ADV1_HEATMAP_SAMPLE_METRICS.png"), 
       p_heat1, width = 10, height = 8, dpi = 150)
cat("   ✅ Guardado: FIG_ADV1_HEATMAP_SAMPLE_METRICS.png\n")

# ============================================================================
# 3. FIGURA AVANZADA 2: BUBBLE PLOT (TIPO x MUESTRA)
# ============================================================================

cat("\n🎨 Generando Figura Avanzada 2: Bubble Plot...\n")

# Top 6 tipos
top6_types <- sample_summary %>% slice(1:6) %>% pull(Mutation_Type)

sample_bubble <- sample_metrics %>%
  filter(Mutation_Type %in% top6_types) %>%
  group_by(Mutation_Type) %>%
  summarise(
    Mean_SNVs = mean(N_SNVs),
    SD_SNVs = sd(N_SNVs),
    Mean_Counts = mean(Total_Counts),
    SD_Counts = sd(Total_Counts),
    N_Samples = n(),
    .groups = "drop"
  ) %>%
  mutate(Category = ifelse(Mutation_Type == "GT", "G>T", "Otras"))

p_bubble <- ggplot(sample_bubble, aes(x = Mean_SNVs, y = Mean_Counts, size = N_Samples, color = Category)) +
  geom_point(alpha = 0.7) +
  geom_text(aes(label = Mutation_Type), vjust = -1.5, fontface = "bold", size = 5, show.legend = FALSE) +
  scale_size_continuous(range = c(10, 30), name = "N° Muestras") +
  scale_color_manual(values = c("G>T" = "#D62728", "Otras" = "gray50"), name = "") +
  scale_x_continuous(labels = comma) +
  scale_y_continuous(labels = comma) +
  theme_classic(base_size = 14) +
  theme(
    axis.title = element_text(face = "bold", size = 14),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 16),
    plot.subtitle = element_text(hjust = 0.5, size = 12, color = "gray40"),
    legend.position = "bottom"
  ) +
  labs(
    title = "Bubble Plot: SNVs vs Counts por Tipo de Mutación",
    subtitle = "Tamaño = N° Muestras | Top 6 tipos más frecuentes",
    x = "Media de SNVs por Muestra",
    y = "Media de Counts Totales por Muestra"
  )

ggsave(file.path(output_dir, "FIG_ADV2_BUBBLE_PLOT_SAMPLE.png"), 
       p_bubble, width = 12, height = 10, dpi = 150)
cat("   ✅ Guardado: FIG_ADV2_BUBBLE_PLOT_SAMPLE.png\n")

# ============================================================================
# 4. FIGURA AVANZADA 3: HEATMAP POR POSICIÓN (TIPO x POSICIÓN)
# ============================================================================

cat("\n🎨 Generando Figura Avanzada 3: Heatmap Posicional...\n")

# Top 10 tipos
top10_types <- sample_summary %>% slice(1:10) %>% pull(Mutation_Type)

position_top10 <- position_metrics %>%
  filter(Mutation_Type %in% top10_types)

# Heatmap de SNVs
p_heat_pos_snvs <- ggplot(position_top10, aes(x = factor(Position), y = Mutation_Type, fill = N_SNVs)) +
  geom_tile(color = "white", size = 0.5) +
  geom_text(aes(label = ifelse(N_SNVs > 100, round(N_SNVs, 0), "")), 
            color = "white", fontface = "bold", size = 2.5) +
  scale_fill_gradient2(
    low = "white", mid = "#FF7F0E", high = "#D62728",
    midpoint = median(position_top10$N_SNVs),
    name = "N° SNVs",
    labels = comma
  ) +
  theme_minimal(base_size = 11) +
  theme(
    axis.text.x = element_text(angle = 0, hjust = 0.5, face = "bold"),
    axis.text.y = element_text(face = "bold", color = ifelse(
      unique(position_top10$Mutation_Type) == "GT", "#D62728", "black"
    )),
    axis.title = element_text(face = "bold", size = 12),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 13),
    panel.grid = element_blank(),
    legend.position = "bottom"
  ) +
  labs(
    title = "A. SNVs por Posición y Tipo",
    x = "Posición",
    y = "Tipo de Mutación"
  )

# Heatmap de Counts
p_heat_pos_counts <- ggplot(position_top10, aes(x = factor(Position), y = Mutation_Type, fill = log10(Total_Counts + 1))) +
  geom_tile(color = "white", size = 0.5) +
  scale_fill_gradient2(
    low = "white", mid = "#9467BD", high = "#D62728",
    midpoint = median(log10(position_top10$Total_Counts + 1)),
    name = "log10(Counts)",
    labels = comma
  ) +
  theme_minimal(base_size = 11) +
  theme(
    axis.text.x = element_text(angle = 0, hjust = 0.5, face = "bold"),
    axis.text.y = element_text(face = "bold", color = ifelse(
      unique(position_top10$Mutation_Type) == "GT", "#D62728", "black"
    )),
    axis.title = element_text(face = "bold", size = 12),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 13),
    panel.grid = element_blank(),
    legend.position = "bottom"
  ) +
  labs(
    title = "B. Counts Totales por Posición y Tipo (log scale)",
    x = "Posición",
    y = "Tipo de Mutación"
  )

# Combinar
fig_pos_heat <- p_heat_pos_snvs / p_heat_pos_counts +
  plot_annotation(
    title = "FIGURA 4: Heatmaps Posicionales - Todos los Tipos de Mutación",
    subtitle = "Top 10 tipos | G>T destacado en el eje Y",
    theme = theme(
      plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray40")
    )
  )

ggsave(file.path(output_dir, "FIG_ADV3_HEATMAP_POSITIONAL.png"), 
       fig_pos_heat, width = 14, height = 10, dpi = 150)
cat("   ✅ Guardado: FIG_ADV3_HEATMAP_POSITIONAL.png\n")

# ============================================================================
# 5. FIGURA AVANZADA 4: FACETED PLOT (Tipo x Métrica)
# ============================================================================

cat("\n🎨 Generando Figura Avanzada 4: Faceted Multi-Metric...\n")

# Preparar datos para faceting
sample_facet <- sample_metrics %>%
  filter(Mutation_Type %in% top10_types) %>%
  select(Mutation_Type, Category, N_SNVs, Mean_Count, Max_Count, SD_Count) %>%
  pivot_longer(
    cols = c(N_SNVs, Mean_Count, Max_Count, SD_Count),
    names_to = "Metric",
    values_to = "Value"
  ) %>%
  mutate(
    Metric = factor(Metric,
                   levels = c("N_SNVs", "Mean_Count", "SD_Count", "Max_Count"),
                   labels = c("N° SNVs", "Media Counts", "SD Counts", "Max Counts"))
  )

p_facet <- ggplot(sample_facet, aes(x = reorder(Mutation_Type, -Value), y = Value, fill = Category)) +
  geom_boxplot(alpha = 0.8, outlier.size = 0.5) +
  facet_wrap(~ Metric, scales = "free_y", ncol = 2) +
  scale_fill_manual(values = c("G>T (Oxidación)" = "#D62728", "Otras" = "gray60"), name = "") +
  theme_classic(base_size = 11) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold", size = 9),
    axis.title = element_text(face = "bold"),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 15),
    plot.subtitle = element_text(hjust = 0.5, size = 11, color = "gray40"),
    strip.text = element_text(face = "bold", size = 12),
    strip.background = element_rect(fill = "#667eea", color = "white"),
    legend.position = "top"
  ) +
  labs(
    title = "FIGURA 5: Multi-Métrica por Tipo de Mutación",
    subtitle = "4 métricas clave | Top 10 tipos | G>T destacado",
    x = "Tipo de Mutación",
    y = "Valor"
  )

ggsave(file.path(output_dir, "FIG_ADV4_FACETED_MULTIMETRIC_SAMPLE.png"), 
       p_facet, width = 14, height = 10, dpi = 150)
cat("   ✅ Guardado: FIG_ADV4_FACETED_MULTIMETRIC_SAMPLE.png\n")

# ============================================================================
# 6. FIGURA AVANZADA 5: RIBBON PLOT POSICIONAL (SNVs + SD)
# ============================================================================

cat("\n🎨 Generando Figura Avanzada 5: Ribbon Plot Posicional...\n")

# Top 6 tipos para claridad
top6 <- sample_summary %>% slice(1:6) %>% pull(Mutation_Type)

position_ribbon <- position_metrics %>%
  filter(Mutation_Type %in% top6) %>%
  group_by(Mutation_Type) %>%
  arrange(Position) %>%
  ungroup()

p_ribbon <- ggplot(position_ribbon, aes(x = Position, y = N_SNVs, color = Mutation_Type, fill = Mutation_Type)) +
  geom_line(size = 1.2, alpha = 0.8) +
  geom_ribbon(aes(ymin = pmax(0, N_SNVs - SD_Count), ymax = N_SNVs + SD_Count), 
              alpha = 0.2, color = NA) +
  geom_point(size = 2, alpha = 0.8) +
  scale_color_manual(
    values = c("GT" = "#D62728", "TC" = "#1F77B4", "AG" = "#2CA02C",
               "GA" = "#FF7F0E", "CT" = "#9467BD", "TA" = "#8C564B"),
    name = "Tipo"
  ) +
  scale_fill_manual(
    values = c("GT" = "#D62728", "TC" = "#1F77B4", "AG" = "#2CA02C",
               "GA" = "#FF7F0E", "CT" = "#9467BD", "TA" = "#8C564B"),
    name = "Tipo"
  ) +
  theme_classic(base_size = 13) +
  theme(
    axis.title = element_text(face = "bold", size = 14),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 15),
    plot.subtitle = element_text(hjust = 0.5, size = 11, color = "gray40"),
    legend.position = "bottom",
    legend.title = element_text(face = "bold")
  ) +
  labs(
    title = "FIGURA 6: Patrón Posicional de SNVs (Top 6 Tipos)",
    subtitle = "Línea = Media | Ribbon = ± SD | G>T en rojo",
    x = "Posición",
    y = "N° SNVs ± SD"
  )

ggsave(file.path(output_dir, "FIG_ADV5_RIBBON_POSITIONAL.png"), 
       p_ribbon, width = 14, height = 8, dpi = 150)
cat("   ✅ Guardado: FIG_ADV5_RIBBON_POSITIONAL.png\n")

# ============================================================================
# 7. FIGURA AVANZADA 6: SUMMARY PANEL (Integrado)
# ============================================================================

cat("\n🎨 Generando Figura Avanzada 6: Summary Panel Integrado...\n")

# Panel A: Top tipos (bar chart de SNVs y counts)
summary_data <- sample_summary %>%
  slice(1:10) %>%
  mutate(
    Mean_SNVs_scaled = Mean_SNVs,
    Mean_Counts_scaled = Mean_Counts / 1000  # Escalar para visualizar juntos
  )

p_sum1 <- ggplot(summary_data, aes(x = reorder(Mutation_Type, -Mean_SNVs))) +
  geom_bar(aes(y = Mean_SNVs, fill = "SNVs"), stat = "identity", alpha = 0.7, position = "dodge") +
  geom_point(aes(y = Mean_Counts_scaled, color = "Counts/1000"), size = 4) +
  geom_line(aes(y = Mean_Counts_scaled, group = 1, color = "Counts/1000"), size = 1.2) +
  scale_fill_manual(values = c("SNVs" = "#667eea"), name = "") +
  scale_color_manual(values = c("Counts/1000" = "#D62728"), name = "") +
  theme_classic(base_size = 12) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold"),
    axis.title = element_text(face = "bold"),
    plot.title = element_text(face = "bold", hjust = 0.5),
    legend.position = "top"
  ) +
  labs(
    title = "A. SNVs y Counts por Tipo (Top 10)",
    x = "Tipo de Mutación",
    y = "Valor"
  )

# Panel B: Destacar G>T específicamente
gt_comparison <- sample_summary %>%
  slice(1:10) %>%
  mutate(
    Fold_vs_GT_SNVs = Mean_SNVs / (sample_summary %>% filter(Mutation_Type == "GT") %>% pull(Mean_SNVs)),
    Fold_vs_GT_Counts = Mean_Counts / (sample_summary %>% filter(Mutation_Type == "GT") %>% pull(Mean_Counts))
  )

p_sum2 <- ggplot(gt_comparison, aes(x = reorder(Mutation_Type, -Fold_vs_GT_SNVs), y = Fold_vs_GT_SNVs, fill = Category)) +
  geom_bar(stat = "identity", alpha = 0.85) +
  geom_hline(yintercept = 1, linetype = "dashed", color = "#D62728", size = 1.2) +
  annotate("text", x = 8, y = 1.15, label = "Nivel G>T", color = "#D62728", fontface = "bold", size = 4) +
  scale_fill_manual(values = c("G>T (Oxidación)" = "#D62728", "Otras" = "gray60"), name = "") +
  theme_classic(base_size = 12) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold"),
    axis.title = element_text(face = "bold"),
    plot.title = element_text(face = "bold", hjust = 0.5),
    legend.position = "none"
  ) +
  labs(
    title = "B. Fold Change vs G>T (SNVs)",
    x = "Tipo de Mutación",
    y = "Fold vs G>T"
  )

# Combinar
fig_summary <- (p_sum1 | p_sum2) +
  plot_annotation(
    title = "FIGURA 7: Resumen Comparativo - G>T en Contexto",
    theme = theme(plot.title = element_text(size = 16, face = "bold", hjust = 0.5))
  )

ggsave(file.path(output_dir, "FIG_ADV6_SUMMARY_COMPARISON.png"), 
       fig_summary, width = 16, height = 7, dpi = 150)
cat("   ✅ Guardado: FIG_ADV6_SUMMARY_COMPARISON.png\n")

# ============================================================================
# 8. RESUMEN FINAL
# ============================================================================

cat("\n╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║          ✅ FIGURAS AVANZADAS COMPLETADAS                           ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

cat("📊 FIGURAS MULTIDIMENSIONALES GENERADAS:\n\n")

cat("1. FIG_ADV1_HEATMAP_SAMPLE_METRICS.png\n")
cat("   → Heatmap: Tipo x Métrica (SNVs, Counts promedio, Max)\n")
cat("   → Muestra TODAS las dimensiones en una sola gráfica\n\n")

cat("2. FIG_ADV2_BUBBLE_PLOT_SAMPLE.png\n")
cat("   → Bubble: SNVs vs Counts (tamaño = N° muestras)\n")
cat("   → Relación entre 3 dimensiones\n\n")

cat("3. FIG_ADV3_HEATMAP_POSITIONAL.png\n")
cat("   → 2 Heatmaps: SNVs y Counts por Posición x Tipo\n")
cat("   → Visualiza patrones posicionales de TODOS los tipos\n\n")

cat("4. FIG_ADV4_FACETED_MULTIMETRIC_SAMPLE.png\n")
cat("   → 4 paneles: SNVs, Media, SD, Max\n")
cat("   → Comparación completa de estadísticas\n\n")

cat("5. FIG_ADV5_RIBBON_POSITIONAL.png\n")
cat("   → Ribbon plot: SNVs ± SD por posición\n")
cat("   → Muestra variabilidad posicional\n\n")

cat("6. FIG_ADV6_SUMMARY_COMPARISON.png\n")
cat("   → Panel comparativo: SNVs+Counts + Fold vs G>T\n")
cat("   → Contexto de G>T respecto a otros tipos\n\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

