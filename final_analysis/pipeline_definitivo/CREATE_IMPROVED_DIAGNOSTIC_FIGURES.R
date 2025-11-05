#!/usr/bin/env Rscript

# ============================================================================
# 🎯 FIGURAS MEJORADAS BASADAS EN FEEDBACK
# ============================================================================
# Mejoras:
# 1. Heatmaps con TODAS las mutaciones (no solo top 10)
# 2. Versión especial solo mutaciones de G
# 3. Eliminar boxplots, usar visualizaciones más integrales
# 4. Bubble plot con tamaño = variabilidad (SD o CV)
# 5. Figura integrada con Fold Change + otras métricas

library(ggplot2)
library(dplyr)
library(tidyr)
library(patchwork)
library(tibble)
library(scales)

cat("╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║     🎯 FIGURAS MEJORADAS - VERSIÓN 2                                ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

output_dir <- "/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/pipeline_definitivo/01_analisis_inicial/figures"

# ============================================================================
# 1. CARGAR DATOS
# ============================================================================

cat("📊 Cargando datos...\n")

sample_metrics <- read.csv("/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/pipeline_definitivo/01_analisis_inicial/tables/ALL_MUTATIONS_sample_metrics.csv")

position_metrics <- read.csv("/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/pipeline_definitivo/01_analisis_inicial/tables/ALL_MUTATIONS_position_metrics.csv")

# Agregar categorías
sample_metrics <- sample_metrics %>%
  mutate(
    Category = case_when(
      Mutation_Type == "GT" ~ "G>T (Oxidación)",
      Mutation_Type %in% c("GA", "GC") ~ "Otras transv. de G",
      TRUE ~ "Otras mutaciones"
    ),
    Is_G_mutation = Mutation_Type %in% c("GT", "GA", "GC")
  )

position_metrics <- position_metrics %>%
  mutate(
    Category = case_when(
      Mutation_Type == "GT" ~ "G>T (Oxidación)",
      Mutation_Type %in% c("GA", "GC") ~ "Otras transv. de G",
      TRUE ~ "Otras mutaciones"
    ),
    Is_G_mutation = Mutation_Type %in% c("GT", "GA", "GC")
  )

cat(sprintf("   ✅ %d tipos de mutación en samples\n", length(unique(sample_metrics$Mutation_Type))))
cat(sprintf("   ✅ %d tipos de mutación en positions\n", length(unique(position_metrics$Mutation_Type))))

# ============================================================================
# 2. FIGURA MEJORADA 1: HEATMAP POSICIONAL COMPLETO (TODAS LAS MUTACIONES)
# ============================================================================

cat("\n🎨 Generando Figura Mejorada 1: Heatmap Posicional Completo...\n")

# Ordenar tipos por frecuencia total
type_order <- position_metrics %>%
  group_by(Mutation_Type) %>%
  summarise(Total = sum(N_SNVs)) %>%
  arrange(desc(Total)) %>%
  pull(Mutation_Type)

position_metrics$Mutation_Type <- factor(position_metrics$Mutation_Type, levels = type_order)

# Panel A: SNVs (TODAS las mutaciones)
p_heat_all_snvs <- ggplot(position_metrics, aes(x = factor(Position), y = Mutation_Type, fill = N_SNVs)) +
  geom_tile(color = "white", size = 0.8) +
  geom_text(aes(label = ifelse(N_SNVs > 200, round(N_SNVs, 0), "")), 
            color = "white", fontface = "bold", size = 2.8) +
  scale_fill_gradient2(
    low = "white", mid = "#FF7F0E", high = "#D62728",
    midpoint = median(position_metrics$N_SNVs),
    name = "N° SNVs",
    labels = comma
  ) +
  theme_minimal(base_size = 12) +
  theme(
    axis.text.x = element_text(angle = 0, hjust = 0.5, face = "bold", size = 11),
    axis.text.y = element_text(face = "bold", size = 11, 
                              color = ifelse(levels(position_metrics$Mutation_Type) == "GT", "#D62728", "black")),
    axis.title = element_text(face = "bold", size = 13),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 14),
    panel.grid = element_blank(),
    legend.position = "right"
  ) +
  labs(
    title = "A. SNVs por Posición (Todas las Mutaciones)",
    x = "Posición",
    y = "Tipo de Mutación"
  )

# Panel B: Counts (log scale)
p_heat_all_counts <- ggplot(position_metrics, aes(x = factor(Position), y = Mutation_Type, fill = log10(Total_Counts + 1))) +
  geom_tile(color = "white", size = 0.8) +
  scale_fill_gradient2(
    low = "white", mid = "#9467BD", high = "#D62728",
    midpoint = median(log10(position_metrics$Total_Counts + 1)),
    name = "log10(Counts)",
    labels = comma
  ) +
  theme_minimal(base_size = 12) +
  theme(
    axis.text.x = element_text(angle = 0, hjust = 0.5, face = "bold", size = 11),
    axis.text.y = element_text(face = "bold", size = 11,
                              color = ifelse(levels(position_metrics$Mutation_Type) == "GT", "#D62728", "black")),
    axis.title = element_text(face = "bold", size = 13),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 14),
    panel.grid = element_blank(),
    legend.position = "right"
  ) +
  labs(
    title = "B. Counts Totales por Posición (log scale)",
    x = "Posición",
    y = "Tipo de Mutación"
  )

# Combinar
fig1_improved <- p_heat_all_snvs / p_heat_all_counts +
  plot_annotation(
    title = "FIGURA 1: Heatmaps Posicionales - Todas las Mutaciones",
    subtitle = "12 tipos de mutación | G>T destacado en rojo | Estilo ribbon aplicado",
    theme = theme(
      plot.title = element_text(size = 17, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray40")
    )
  )

ggsave(file.path(output_dir, "FIG1_IMPROVED_HEATMAP_ALL_MUTATIONS.png"), 
       fig1_improved, width = 16, height = 12, dpi = 150)
cat("   ✅ Guardado: FIG1_IMPROVED_HEATMAP_ALL_MUTATIONS.png\n")

# ============================================================================
# 3. FIGURA MEJORADA 2: HEATMAP SOLO MUTACIONES DE G
# ============================================================================

cat("\n🎨 Generando Figura Mejorada 2: Heatmap Solo Mutaciones de G...\n")

position_g_only <- position_metrics %>%
  filter(Mutation_Type %in% c("GT", "GA", "GC"))

# Panel A: SNVs
p_g_snvs <- ggplot(position_g_only, aes(x = factor(Position), y = Mutation_Type, fill = N_SNVs)) +
  geom_tile(color = "white", size = 1.2) +
  geom_text(aes(label = round(N_SNVs, 0)), color = "white", fontface = "bold", size = 4) +
  scale_fill_gradient2(
    low = "white", mid = "#FF7F0E", high = "#D62728",
    midpoint = median(position_g_only$N_SNVs),
    name = "N° SNVs"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    axis.text.x = element_text(angle = 0, hjust = 0.5, face = "bold", size = 12),
    axis.text.y = element_text(face = "bold", size = 14,
                              color = c("GT" = "#D62728", "GA" = "#1F77B4", "GC" = "#2CA02C")),
    axis.title = element_text(face = "bold", size = 14),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 15),
    panel.grid = element_blank(),
    legend.position = "bottom"
  ) +
  labs(
    title = "A. SNVs: G>T vs G>A vs G>C",
    x = "Posición",
    y = ""
  )

# Panel B: Counts con barras de error
p_g_counts <- ggplot(position_g_only, aes(x = factor(Position), y = Mutation_Type, fill = log10(Total_Counts + 1))) +
  geom_tile(color = "white", size = 1.2) +
  geom_text(aes(label = comma(round(Total_Counts, 0))), color = "white", fontface = "bold", size = 3) +
  scale_fill_gradient2(
    low = "white", mid = "#9467BD", high = "#D62728",
    midpoint = median(log10(position_g_only$Total_Counts + 1)),
    name = "log10(Counts)"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    axis.text.x = element_text(angle = 0, hjust = 0.5, face = "bold", size = 12),
    axis.text.y = element_text(face = "bold", size = 14,
                              color = c("GT" = "#D62728", "GA" = "#1F77B4", "GC" = "#2CA02C")),
    axis.title = element_text(face = "bold", size = 14),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 15),
    panel.grid = element_blank(),
    legend.position = "bottom"
  ) +
  labs(
    title = "B. Counts Totales: G>T vs G>A vs G>C",
    x = "Posición",
    y = ""
  )

# Panel C: Fracción de G>T
g_fractions <- position_g_only %>%
  group_by(Position) %>%
  mutate(
    Total = sum(N_SNVs),
    Fraction = N_SNVs / Total * 100
  ) %>%
  filter(Mutation_Type == "GT")

p_g_fraction <- ggplot(g_fractions, aes(x = Position, y = Fraction)) +
  geom_line(color = "#D62728", size = 1.8, alpha = 0.8) +
  geom_point(color = "#D62728", size = 4, alpha = 0.9) +
  geom_ribbon(aes(ymin = 0, ymax = Fraction), fill = "#D62728", alpha = 0.25) +
  geom_hline(yintercept = 50, linetype = "dashed", color = "gray30", size = 1) +
  geom_hline(yintercept = 33.3, linetype = "dotted", color = "gray50", size = 0.8) +
  annotate("text", x = 20, y = 53, label = "50% (mayoría)", color = "gray30", fontface = "bold", size = 4) +
  annotate("text", x = 20, y = 36, label = "33% (esperado)", color = "gray50", size = 3.5) +
  theme_classic(base_size = 13) +
  theme(
    axis.title = element_text(face = "bold", size = 14),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 15),
    plot.subtitle = element_text(hjust = 0.5, size = 11, color = "gray40")
  ) +
  labs(
    title = "C. Especificidad: % G>T de Transversiones de G",
    subtitle = "¿G>T domina sobre G>A y G>C?",
    x = "Posición",
    y = "% G>T (de GT+GA+GC)"
  ) +
  ylim(0, 100)

# Combinar
fig2_improved <- (p_g_snvs | p_g_counts) / p_g_fraction +
  plot_layout(heights = c(1, 0.8)) +
  plot_annotation(
    title = "FIGURA 2: Especificidad de Transversiones de G",
    subtitle = "Análisis enfocado en G>T vs G>A vs G>C | Estilo ribbon",
    theme = theme(
      plot.title = element_text(size = 17, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray40")
    )
  )

ggsave(file.path(output_dir, "FIG2_IMPROVED_G_MUTATIONS_ONLY.png"), 
       fig2_improved, width = 16, height = 11, dpi = 150)
cat("   ✅ Guardado: FIG2_IMPROVED_G_MUTATIONS_ONLY.png\n")

# ============================================================================
# 4. FIGURA MEJORADA 3: BUBBLE PLOT CON VARIABILIDAD
# ============================================================================

cat("\n🎨 Generando Figura Mejorada 3: Bubble Plot con Variabilidad...\n")

# Calcular métricas agregadas por tipo
bubble_data <- sample_metrics %>%
  group_by(Mutation_Type, Category) %>%
  summarise(
    Mean_SNVs = mean(N_SNVs),
    SD_SNVs = sd(N_SNVs),
    CV_SNVs = sd(N_SNVs) / mean(N_SNVs),  # Coeficiente de variación
    Mean_Counts = mean(Total_Counts),
    SD_Counts = sd(Total_Counts),
    CV_Counts = sd(Total_Counts) / mean(Total_Counts),
    N_Samples = n(),
    .groups = "drop"
  ) %>%
  mutate(
    Is_GT = Mutation_Type == "GT"
  )

# Bubble plot con tamaño = CV (variabilidad)
p_bubble_improved <- ggplot(bubble_data, aes(x = Mean_SNVs, y = Mean_Counts, 
                                              size = CV_SNVs, color = Category, shape = Is_GT)) +
  geom_point(alpha = 0.75) +
  geom_text(aes(label = Mutation_Type), vjust = -1.8, fontface = "bold", size = 4.5, show.legend = FALSE) +
  scale_size_continuous(range = c(8, 25), name = "CV de SNVs\n(Variabilidad)") +
  scale_color_manual(
    values = c("G>T (Oxidación)" = "#D62728", "Otras transv. de G" = "#FF7F0E", "Otras mutaciones" = "gray50"),
    name = "Categoría"
  ) +
  scale_shape_manual(values = c("TRUE" = 18, "FALSE" = 16), guide = "none") +  # Diamante para GT
  scale_x_continuous(labels = comma) +
  scale_y_continuous(labels = comma) +
  theme_classic(base_size = 14) +
  theme(
    axis.title = element_text(face = "bold", size = 14),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 16),
    plot.subtitle = element_text(hjust = 0.5, size = 12, color = "gray40"),
    legend.position = "bottom",
    legend.box = "vertical"
  ) +
  labs(
    title = "FIGURA 3: Bubble Plot - SNVs vs Counts por Tipo",
    subtitle = "Tamaño = Coeficiente de Variación (CV) de SNVs | G>T = Diamante rojo",
    x = "Media de SNVs por Muestra",
    y = "Media de Counts Totales por Muestra"
  )

ggsave(file.path(output_dir, "FIG3_IMPROVED_BUBBLE_WITH_CV.png"), 
       p_bubble_improved, width = 14, height = 11, dpi = 150)
cat("   ✅ Guardado: FIG3_IMPROVED_BUBBLE_WITH_CV.png\n")

# ============================================================================
# 5. FIGURA MEJORADA 4: INTEGRADA (Fold + Métricas)
# ============================================================================

cat("\n🎨 Generando Figura Mejorada 4: Panel Integrado con Fold Change...\n")

# Calcular fold changes vs G>T
gt_baseline <- bubble_data %>% filter(Mutation_Type == "GT")

fold_data <- bubble_data %>%
  mutate(
    Fold_SNVs = Mean_SNVs / gt_baseline$Mean_SNVs,
    Fold_Counts = Mean_Counts / gt_baseline$Mean_Counts
  ) %>%
  arrange(desc(Fold_SNVs))

# Panel A: Fold SNVs + Fold Counts combinados
fold_long <- fold_data %>%
  select(Mutation_Type, Category, Fold_SNVs, Fold_Counts) %>%
  pivot_longer(
    cols = c(Fold_SNVs, Fold_Counts),
    names_to = "Metric",
    values_to = "Fold"
  ) %>%
  mutate(
    Metric = factor(Metric, levels = c("Fold_SNVs", "Fold_Counts"),
                   labels = c("Fold SNVs", "Fold Counts"))
  )

p_fold <- ggplot(fold_long, aes(x = reorder(Mutation_Type, -Fold), y = Fold, fill = Metric)) +
  geom_bar(stat = "identity", position = "dodge", alpha = 0.85, width = 0.8) +
  geom_hline(yintercept = 1, linetype = "dashed", color = "#D62728", size = 1.2) +
  annotate("rect", xmin = -Inf, xmax = Inf, ymin = 0.95, ymax = 1.05, 
           fill = "#D62728", alpha = 0.1) +
  annotate("text", x = 10, y = 1.15, label = "Nivel G>T", color = "#D62728", 
           fontface = "bold", size = 4.5) +
  scale_fill_manual(values = c("Fold SNVs" = "#667eea", "Fold Counts" = "#764ba2"), name = "") +
  theme_classic(base_size = 13) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold", size = 11),
    axis.title = element_text(face = "bold", size = 14),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 15),
    legend.position = "top"
  ) +
  labs(
    title = "A. Fold Change vs G>T (SNVs y Counts)",
    x = "Tipo de Mutación",
    y = "Fold Change (vs G>T)"
  )

# Panel B: Métricas absolutas integradas
metrics_int <- fold_data %>%
  slice(1:10) %>%
  select(Mutation_Type, Category, Mean_SNVs, Mean_Counts) %>%
  mutate(Mean_Counts_scaled = Mean_Counts / 1000)

p_metrics <- ggplot(metrics_int, aes(x = reorder(Mutation_Type, -Mean_SNVs))) +
  geom_bar(aes(y = Mean_SNVs, fill = "SNVs"), stat = "identity", alpha = 0.75, width = 0.7) +
  geom_point(aes(y = Mean_Counts_scaled, color = "Counts/1000"), size = 5) +
  geom_line(aes(y = Mean_Counts_scaled, group = 1, color = "Counts/1000"), size = 1.5) +
  scale_fill_manual(values = c("SNVs" = "#667eea"), name = "") +
  scale_color_manual(values = c("Counts/1000" = "#D62728"), name = "") +
  theme_classic(base_size = 13) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold", size = 11),
    axis.title = element_text(face = "bold", size = 14),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 15),
    legend.position = "top"
  ) +
  labs(
    title = "B. Valores Absolutos: SNVs y Counts (Top 10)",
    x = "Tipo de Mutación",
    y = "Valor (SNVs | Counts/1000)"
  )

# Combinar
fig4_improved <- (p_fold | p_metrics) +
  plot_annotation(
    title = "FIGURA 4: Panel Integrado - Fold Change y Valores Absolutos",
    subtitle = "Contexto completo de G>T vs otros tipos | SNVs y Counts combinados",
    theme = theme(
      plot.title = element_text(size = 17, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray40")
    )
  )

ggsave(file.path(output_dir, "FIG4_IMPROVED_INTEGRATED_PANEL.png"), 
       fig4_improved, width = 16, height = 8, dpi = 150)
cat("   ✅ Guardado: FIG4_IMPROVED_INTEGRATED_PANEL.png\n")

# ============================================================================
# 6. FIGURA MEJORADA 5: DENSITY RIDGE (Distribuciones completas)
# ============================================================================

cat("\n🎨 Generando Figura Mejorada 5: Density Plots Integrales...\n")

# Top 8 tipos para claridad
top8 <- fold_data %>% slice(1:8) %>% pull(Mutation_Type)

sample_top8 <- sample_metrics %>%
  filter(Mutation_Type %in% top8) %>%
  mutate(
    Mutation_Type = factor(Mutation_Type, levels = rev(top8))
  )

# Violin plots con puntos y estadísticas
p_violin_snvs <- ggplot(sample_top8, aes(x = Mutation_Type, y = N_SNVs, fill = Category)) +
  geom_violin(alpha = 0.7, trim = FALSE) +
  geom_boxplot(width = 0.2, alpha = 0.8, outlier.size = 0.5) +
  stat_summary(fun = mean, geom = "point", shape = 23, size = 3, fill = "white", color = "black") +
  scale_fill_manual(
    values = c("G>T (Oxidación)" = "#D62728", "Otras transv. de G" = "#FF7F0E", "Otras mutaciones" = "gray60"),
    name = ""
  ) +
  coord_flip() +
  theme_classic(base_size = 13) +
  theme(
    axis.title = element_text(face = "bold", size = 14),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 15),
    legend.position = "top"
  ) +
  labs(
    title = "A. Distribución de SNVs por Muestra (Top 8 Tipos)",
    subtitle = "Violin + Boxplot + Media (diamante blanco)",
    y = "N° SNVs por Muestra",
    x = "Tipo de Mutación"
  )

# Violin de counts
p_violin_counts <- ggplot(sample_top8, aes(x = Mutation_Type, y = Total_Counts, fill = Category)) +
  geom_violin(alpha = 0.7, trim = FALSE) +
  geom_boxplot(width = 0.2, alpha = 0.8, outlier.size = 0.5) +
  stat_summary(fun = mean, geom = "point", shape = 23, size = 3, fill = "white", color = "black") +
  scale_fill_manual(
    values = c("G>T (Oxidación)" = "#D62728", "Otras transv. de G" = "#FF7F0E", "Otras mutaciones" = "gray60"),
    name = ""
  ) +
  scale_y_log10(labels = comma) +
  coord_flip() +
  theme_classic(base_size = 13) +
  theme(
    axis.title = element_text(face = "bold", size = 14),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 15),
    legend.position = "top"
  ) +
  labs(
    title = "B. Distribución de Counts por Muestra (log scale)",
    subtitle = "Violin + Boxplot + Media (diamante blanco)",
    y = "Total Counts por Muestra",
    x = "Tipo de Mutación"
  )

# Combinar
fig5_improved <- p_violin_snvs / p_violin_counts +
  plot_annotation(
    title = "FIGURA 5: Distribuciones Completas por Muestra",
    subtitle = "Visualización integral: distribución + cuartiles + media | Top 8 tipos",
    theme = theme(
      plot.title = element_text(size = 17, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray40")
    )
  )

ggsave(file.path(output_dir, "FIG5_IMPROVED_VIOLIN_DISTRIBUTIONS.png"), 
       fig5_improved, width = 14, height = 11, dpi = 150)
cat("   ✅ Guardado: FIG5_IMPROVED_VIOLIN_DISTRIBUTIONS.png\n")

# ============================================================================
# 7. RESUMEN
# ============================================================================

cat("\n╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║          ✅ FIGURAS MEJORADAS COMPLETADAS                           ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

cat("📊 FIGURAS GENERADAS (VERSIÓN MEJORADA):\n\n")

cat("1. FIG1_IMPROVED_HEATMAP_ALL_MUTATIONS.png\n")
cat("   → Heatmaps con TODAS las 12 mutaciones\n")
cat("   → SNVs + Counts por posición\n")
cat("   → G>T destacado en rojo\n\n")

cat("2. FIG2_IMPROVED_G_MUTATIONS_ONLY.png\n")
cat("   → Solo G>T, G>A, G>C (3 transversiones de G)\n")
cat("   → 3 paneles: SNVs, Counts, % G>T\n")
cat("   → Estilo ribbon aplicado\n\n")

cat("3. FIG3_IMPROVED_BUBBLE_WITH_CV.png\n")
cat("   → Tamaño = Coeficiente de Variación (no N° muestras)\n")
cat("   → Muestra variabilidad entre muestras\n")
cat("   → G>T = Diamante rojo\n\n")

cat("4. FIG4_IMPROVED_INTEGRATED_PANEL.png\n")
cat("   → Fold Change + Valores Absolutos INTEGRADOS\n")
cat("   → SNVs y Counts en la misma figura\n")
cat("   → Contexto completo de G>T\n\n")

cat("5. FIG5_IMPROVED_VIOLIN_DISTRIBUTIONS.png\n")
cat("   → Violin + Boxplot + Media\n")
cat("   → Distribuciones COMPLETAS (no solo boxplot)\n")
cat("   → Top 8 tipos más informativos\n\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

