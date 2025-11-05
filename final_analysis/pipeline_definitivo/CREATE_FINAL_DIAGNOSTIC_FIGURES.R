#!/usr/bin/env Rscript

# ============================================================================
# 🎯 FIGURAS DIAGNÓSTICAS FINALES - VERSIÓN CORREGIDA
# ============================================================================
# Correcciones:
# 1. TODAS las 12 mutaciones (AT,AG,AC,GC,GT,GA,CG,CA,CT,TA,TG,TC)
# 2. Todo en ESPAÑOL
# 3. Bubble plot con tamaño más claro (SD absoluto)
# 4. Heatmaps de G separados (una figura por métrica)
# 5. GT vs GA vs GC en la misma gráfica

library(ggplot2)
library(dplyr)
library(tidyr)
library(patchwork)
library(tibble)
library(scales)

cat("╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║     🎯 FIGURAS DIAGNÓSTICAS FINALES - VERSIÓN CORREGIDA            ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

output_dir <- "/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/pipeline_definitivo/01_analisis_inicial/figures"

# ============================================================================
# 1. CARGAR DATOS
# ============================================================================

cat("📊 Cargando datos...\n")

sample_metrics <- read.csv("/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/pipeline_definitivo/01_analisis_inicial/tables/ALL_MUTATIONS_sample_metrics.csv")

position_metrics <- read.csv("/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/pipeline_definitivo/01_analisis_inicial/tables/ALL_MUTATIONS_position_metrics.csv")

# Verificar que tengamos TODAS las mutaciones
all_types <- c("AT", "AG", "AC", "GC", "GT", "GA", "CG", "CA", "CT", "TA", "TG", "TC")
cat(sprintf("   ✅ Tipos esperados: %d\n", length(all_types)))
cat(sprintf("   ✅ Tipos encontrados: %d\n", length(unique(sample_metrics$Mutation_Type))))
cat("   Tipos: ", paste(sort(unique(sample_metrics$Mutation_Type)), collapse = ", "), "\n\n")

# ============================================================================
# 2. FIGURA 1: HEATMAP POSICIONAL - TODAS LAS 12 MUTACIONES (SNVs)
# ============================================================================

cat("🎨 Generando Figura 1: Heatmap Posicional SNVs (12 tipos)...\n")

# Asegurar que estén todas las mutaciones
position_all <- position_metrics %>%
  complete(Position, Mutation_Type = all_types, fill = list(N_SNVs = 0, Total_Counts = 0))

# Ordenar por frecuencia total
type_order <- position_all %>%
  group_by(Mutation_Type) %>%
  summarise(Total = sum(N_SNVs, na.rm = TRUE)) %>%
  arrange(desc(Total)) %>%
  pull(Mutation_Type)

position_all$Mutation_Type <- factor(position_all$Mutation_Type, levels = type_order)

# Heatmap de SNVs
fig1 <- ggplot(position_all, aes(x = factor(Position), y = Mutation_Type, fill = N_SNVs)) +
  geom_tile(color = "white", size = 0.8) +
  geom_text(aes(label = ifelse(N_SNVs > 200, round(N_SNVs, 0), "")), 
            color = "white", fontface = "bold", size = 3) +
  scale_fill_gradient2(
    low = "white", mid = "#FF7F0E", high = "#D62728",
    midpoint = median(position_all$N_SNVs[position_all$N_SNVs > 0]),
    name = "N° SNVs",
    labels = comma
  ) +
  theme_minimal(base_size = 13) +
  theme(
    axis.text.x = element_text(angle = 0, hjust = 0.5, face = "bold", size = 12),
    axis.text.y = element_text(face = "bold", size = 13, 
                              color = ifelse(levels(position_all$Mutation_Type) == "GT", "#D62728", "black")),
    axis.title = element_text(face = "bold", size = 15),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 17),
    plot.subtitle = element_text(hjust = 0.5, size = 13, color = "gray40"),
    panel.grid = element_blank(),
    legend.position = "right",
    legend.title = element_text(face = "bold", size = 12)
  ) +
  labs(
    title = "FIGURA 1: SNVs por Posición - Todas las Mutaciones",
    subtitle = "12 tipos de mutación | G>T destacado en rojo",
    x = "Posición",
    y = "Tipo de Mutación"
  )

ggsave(file.path(output_dir, "FIG1_FINAL_HEATMAP_SNVS_TODAS.png"), 
       fig1, width = 16, height = 10, dpi = 150)
cat("   ✅ Guardado: FIG1_FINAL_HEATMAP_SNVS_TODAS.png\n")

# ============================================================================
# 3. FIGURA 2: HEATMAP POSICIONAL - TODAS LAS 12 MUTACIONES (Counts)
# ============================================================================

cat("\n🎨 Generando Figura 2: Heatmap Posicional Counts (12 tipos)...\n")

fig2 <- ggplot(position_all, aes(x = factor(Position), y = Mutation_Type, fill = log10(Total_Counts + 1))) +
  geom_tile(color = "white", size = 0.8) +
  scale_fill_gradient2(
    low = "white", mid = "#9467BD", high = "#D62728",
    midpoint = median(log10(position_all$Total_Counts[position_all$Total_Counts > 0] + 1)),
    name = "log10(Counts)",
    labels = comma
  ) +
  theme_minimal(base_size = 13) +
  theme(
    axis.text.x = element_text(angle = 0, hjust = 0.5, face = "bold", size = 12),
    axis.text.y = element_text(face = "bold", size = 13,
                              color = ifelse(levels(position_all$Mutation_Type) == "GT", "#D62728", "black")),
    axis.title = element_text(face = "bold", size = 15),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 17),
    plot.subtitle = element_text(hjust = 0.5, size = 13, color = "gray40"),
    panel.grid = element_blank(),
    legend.position = "right",
    legend.title = element_text(face = "bold", size = 12)
  ) +
  labs(
    title = "FIGURA 2: Counts Totales por Posición - Todas las Mutaciones",
    subtitle = "Profundidad de secuenciación | Escala logarítmica | G>T destacado",
    x = "Posición",
    y = "Tipo de Mutación"
  )

ggsave(file.path(output_dir, "FIG2_FINAL_HEATMAP_COUNTS_TODAS.png"), 
       fig2, width = 16, height = 10, dpi = 150)
cat("   ✅ Guardado: FIG2_FINAL_HEATMAP_COUNTS_TODAS.png\n")

# ============================================================================
# 4. FIGURA 3: GT vs GA vs GC - SNVs (Una sola gráfica)
# ============================================================================

cat("\n🎨 Generando Figura 3: GT vs GA vs GC - SNVs...\n")

g_only <- position_all %>%
  filter(Mutation_Type %in% c("GT", "GA", "GC"))

fig3 <- ggplot(g_only, aes(x = factor(Position), y = N_SNVs, fill = Mutation_Type)) +
  geom_bar(stat = "identity", position = "dodge", alpha = 0.85, width = 0.8) +
  geom_text(aes(label = ifelse(N_SNVs > 100, round(N_SNVs, 0), "")), 
            position = position_dodge(width = 0.8), vjust = -0.5, 
            fontface = "bold", size = 3) +
  scale_fill_manual(
    values = c("GT" = "#D62728", "GA" = "#1F77B4", "GC" = "#2CA02C"),
    labels = c("GT" = "G>T (Oxidación)", "GA" = "G>A", "GC" = "G>C"),
    name = "Tipo de Mutación"
  ) +
  theme_classic(base_size = 14) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold", size = 12),
    axis.title = element_text(face = "bold", size = 15),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 17),
    plot.subtitle = element_text(hjust = 0.5, size = 13, color = "gray40"),
    legend.position = "bottom",
    legend.title = element_text(face = "bold", size = 13),
    legend.text = element_text(size = 12)
  ) +
  labs(
    title = "FIGURA 3: Comparación de Transversiones de G - SNVs por Posición",
    subtitle = "G>T vs G>A vs G>C | Cantidad de mutaciones",
    x = "Posición",
    y = "Número de SNVs"
  )

ggsave(file.path(output_dir, "FIG3_FINAL_G_MUTATIONS_SNVS.png"), 
       fig3, width = 16, height = 9, dpi = 150)
cat("   ✅ Guardado: FIG3_FINAL_G_MUTATIONS_SNVS.png\n")

# ============================================================================
# 5. FIGURA 4: GT vs GA vs GC - Counts (Una sola gráfica)
# ============================================================================

cat("\n🎨 Generando Figura 4: GT vs GA vs GC - Counts...\n")

fig4 <- ggplot(g_only, aes(x = factor(Position), y = Total_Counts, fill = Mutation_Type)) +
  geom_bar(stat = "identity", position = "dodge", alpha = 0.85, width = 0.8) +
  scale_fill_manual(
    values = c("GT" = "#D62728", "GA" = "#1F77B4", "GC" = "#2CA02C"),
    labels = c("GT" = "G>T (Oxidación)", "GA" = "G>A", "GC" = "G>C"),
    name = "Tipo de Mutación"
  ) +
  scale_y_continuous(labels = comma) +
  theme_classic(base_size = 14) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold", size = 12),
    axis.title = element_text(face = "bold", size = 15),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 17),
    plot.subtitle = element_text(hjust = 0.5, size = 13, color = "gray40"),
    legend.position = "bottom",
    legend.title = element_text(face = "bold", size = 13),
    legend.text = element_text(size = 12)
  ) +
  labs(
    title = "FIGURA 4: Comparación de Transversiones de G - Counts por Posición",
    subtitle = "G>T vs G>A vs G>C | Profundidad de secuenciación",
    x = "Posición",
    y = "Counts Totales"
  )

ggsave(file.path(output_dir, "FIG4_FINAL_G_MUTATIONS_COUNTS.png"), 
       fig4, width = 16, height = 9, dpi = 150)
cat("   ✅ Guardado: FIG4_FINAL_G_MUTATIONS_COUNTS.png\n")

# ============================================================================
# 6. FIGURA 5: BUBBLE PLOT MEJORADO (tamaño = SD absoluto)
# ============================================================================

cat("\n🎨 Generando Figura 5: Bubble Plot (tamaño = Desviación Estándar)...\n")

# Calcular métricas por tipo
bubble_data <- sample_metrics %>%
  group_by(Mutation_Type) %>%
  summarise(
    Media_SNVs = mean(N_SNVs),
    SD_SNVs = sd(N_SNVs),
    Media_Counts = mean(Total_Counts),
    SD_Counts = sd(Total_Counts),
    N_Muestras = n(),
    .groups = "drop"
  ) %>%
  mutate(
    Is_GT = Mutation_Type == "GT",
    Categoria = case_when(
      Mutation_Type == "GT" ~ "G>T (Oxidación)",
      Mutation_Type %in% c("GA", "GC") ~ "Otras transv. de G",
      TRUE ~ "Otras mutaciones"
    )
  )

fig5 <- ggplot(bubble_data, aes(x = Media_SNVs, y = Media_Counts, 
                                 size = SD_SNVs, color = Categoria, shape = Is_GT)) +
  geom_point(alpha = 0.75) +
  geom_text(aes(label = Mutation_Type), vjust = -2, fontface = "bold", size = 5, show.legend = FALSE) +
  scale_size_continuous(range = c(8, 30), name = "Desviación Estándar\nde SNVs por Muestra") +
  scale_color_manual(
    values = c("G>T (Oxidación)" = "#D62728", "Otras transv. de G" = "#FF7F0E", "Otras mutaciones" = "gray50"),
    name = "Categoría"
  ) +
  scale_shape_manual(values = c("TRUE" = 18, "FALSE" = 16), guide = "none") +
  scale_x_continuous(labels = comma) +
  scale_y_continuous(labels = comma) +
  theme_classic(base_size = 14) +
  theme(
    axis.title = element_text(face = "bold", size = 15),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 17),
    plot.subtitle = element_text(hjust = 0.5, size = 13, color = "gray40"),
    legend.position = "bottom",
    legend.box = "vertical",
    legend.title = element_text(face = "bold", size = 12)
  ) +
  labs(
    title = "FIGURA 5: SNVs vs Counts por Tipo de Mutación",
    subtitle = "Tamaño = Desviación Estándar (variabilidad entre muestras) | G>T = Diamante rojo",
    x = "Media de SNVs por Muestra",
    y = "Media de Counts Totales por Muestra"
  )

ggsave(file.path(output_dir, "FIG5_FINAL_BUBBLE_SD.png"), 
       fig5, width = 14, height = 11, dpi = 150)
cat("   ✅ Guardado: FIG5_FINAL_BUBBLE_SD.png\n")

# ============================================================================
# 7. FIGURA 6: VIOLIN PLOTS EN ESPAÑOL
# ============================================================================

cat("\n🎨 Generando Figura 6: Distribuciones por Muestra (Violin)...\n")

# Top 8 tipos
top8 <- bubble_data %>% arrange(desc(Media_SNVs)) %>% slice(1:8) %>% pull(Mutation_Type)

sample_top8 <- sample_metrics %>%
  filter(Mutation_Type %in% top8) %>%
  mutate(
    Mutation_Type = factor(Mutation_Type, levels = rev(top8)),
    Categoria = case_when(
      Mutation_Type == "GT" ~ "G>T (Oxidación)",
      Mutation_Type %in% c("GA", "GC") ~ "Otras transv. de G",
      TRUE ~ "Otras mutaciones"
    )
  )

# Panel A: SNVs
p_viol_snvs <- ggplot(sample_top8, aes(x = Mutation_Type, y = N_SNVs, fill = Categoria)) +
  geom_violin(alpha = 0.7, trim = FALSE) +
  geom_boxplot(width = 0.2, alpha = 0.8, outlier.size = 0.5) +
  stat_summary(fun = mean, geom = "point", shape = 23, size = 3.5, fill = "white", color = "black") +
  scale_fill_manual(
    values = c("G>T (Oxidación)" = "#D62728", "Otras transv. de G" = "#FF7F0E", "Otras mutaciones" = "gray60"),
    name = ""
  ) +
  coord_flip() +
  theme_classic(base_size = 13) +
  theme(
    axis.title = element_text(face = "bold", size = 14),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 15),
    plot.subtitle = element_text(hjust = 0.5, size = 11, color = "gray40"),
    legend.position = "top"
  ) +
  labs(
    title = "A. Distribución de SNVs por Muestra (Top 8 Tipos)",
    subtitle = "Violin + Boxplot + Media (diamante blanco)",
    y = "Número de SNVs por Muestra",
    x = "Tipo de Mutación"
  )

# Panel B: Counts
p_viol_counts <- ggplot(sample_top8, aes(x = Mutation_Type, y = Total_Counts, fill = Categoria)) +
  geom_violin(alpha = 0.7, trim = FALSE) +
  geom_boxplot(width = 0.2, alpha = 0.8, outlier.size = 0.5) +
  stat_summary(fun = mean, geom = "point", shape = 23, size = 3.5, fill = "white", color = "black") +
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
    plot.subtitle = element_text(hjust = 0.5, size = 11, color = "gray40"),
    legend.position = "top"
  ) +
  labs(
    title = "B. Distribución de Counts por Muestra (escala log)",
    subtitle = "Violin + Boxplot + Media (diamante blanco)",
    y = "Counts Totales por Muestra",
    x = "Tipo de Mutación"
  )

fig6 <- p_viol_snvs / p_viol_counts +
  plot_annotation(
    title = "FIGURA 6: Distribuciones Completas por Muestra",
    subtitle = "Visualización integral: distribución + cuartiles + media",
    theme = theme(
      plot.title = element_text(size = 17, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray40")
    )
  )

ggsave(file.path(output_dir, "FIG6_FINAL_VIOLIN_DISTRIBUTIONS.png"), 
       fig6, width = 14, height = 11, dpi = 150)
cat("   ✅ Guardado: FIG6_FINAL_VIOLIN_DISTRIBUTIONS.png\n")

# ============================================================================
# 8. FIGURA 7: PANEL INTEGRADO (Fold + Contexto)
# ============================================================================

cat("\n🎨 Generando Figura 7: Panel Integrado...\n")

# Calcular fold vs GT
gt_baseline <- bubble_data %>% filter(Mutation_Type == "GT")

fold_data <- bubble_data %>%
  mutate(
    Fold_SNVs = Media_SNVs / gt_baseline$Media_SNVs,
    Fold_Counts = Media_Counts / gt_baseline$Media_Counts
  ) %>%
  arrange(desc(Fold_SNVs))

# Panel integrado
fold_long <- fold_data %>%
  slice(1:10) %>%
  select(Mutation_Type, Categoria, Fold_SNVs, Fold_Counts) %>%
  pivot_longer(
    cols = c(Fold_SNVs, Fold_Counts),
    names_to = "Metrica",
    values_to = "Fold"
  ) %>%
  mutate(
    Metrica = factor(Metrica, levels = c("Fold_SNVs", "Fold_Counts"),
                   labels = c("Fold SNVs", "Fold Counts"))
  )

fig7 <- ggplot(fold_long, aes(x = reorder(Mutation_Type, -Fold), y = Fold, fill = Metrica)) +
  geom_bar(stat = "identity", position = "dodge", alpha = 0.85, width = 0.75) +
  geom_hline(yintercept = 1, linetype = "dashed", color = "#D62728", size = 1.3) +
  annotate("rect", xmin = -Inf, xmax = Inf, ymin = 0.95, ymax = 1.05, 
           fill = "#D62728", alpha = 0.12) +
  annotate("text", x = 8.5, y = 1.2, label = "Nivel G>T (referencia)", 
           color = "#D62728", fontface = "bold", size = 5) +
  scale_fill_manual(values = c("Fold SNVs" = "#667eea", "Fold Counts" = "#764ba2"), name = "") +
  theme_classic(base_size = 14) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold", size = 12),
    axis.title = element_text(face = "bold", size = 15),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 17),
    plot.subtitle = element_text(hjust = 0.5, size = 13, color = "gray40"),
    legend.position = "top",
    legend.text = element_text(size = 13)
  ) +
  labs(
    title = "FIGURA 7: Fold Change vs G>T - Contexto Relativo",
    subtitle = "¿Cuánto más/menos frecuentes son otros tipos comparados con G>T? | Top 10 tipos",
    x = "Tipo de Mutación",
    y = "Fold Change (relativo a G>T)"
  )

ggsave(file.path(output_dir, "FIG7_FINAL_FOLD_CHANGE_INTEGRATED.png"), 
       fig7, width = 16, height = 9, dpi = 150)
cat("   ✅ Guardado: FIG7_FINAL_FOLD_CHANGE_INTEGRATED.png\n")

# ============================================================================
# 9. RESUMEN FINAL
# ============================================================================

cat("\n╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║          ✅ FIGURAS FINALES COMPLETADAS                             ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

cat("📊 FIGURAS GENERADAS (VERSIÓN FINAL):\n\n")

cat("1. FIG1_FINAL_HEATMAP_SNVS_TODAS.png\n")
cat("   → Heatmap: 12 tipos x 23 posiciones (SNVs)\n")
cat("   → TODAS las mutaciones incluidas\n")
cat("   → En ESPAÑOL\n\n")

cat("2. FIG2_FINAL_HEATMAP_COUNTS_TODAS.png\n")
cat("   → Heatmap: 12 tipos x 23 posiciones (Counts)\n")
cat("   → Figura SEPARADA (no combinada)\n")
cat("   → En ESPAÑOL\n\n")

cat("3. FIG3_FINAL_G_MUTATIONS_SNVS.png\n")
cat("   → GT vs GA vs GC por posición (SNVs)\n")
cat("   → UNA SOLA gráfica\n")
cat("   → Barras agrupadas\n\n")

cat("4. FIG4_FINAL_G_MUTATIONS_COUNTS.png\n")
cat("   → GT vs GA vs GC por posición (Counts)\n")
cat("   → UNA SOLA gráfica\n")
cat("   → Barras agrupadas\n\n")

cat("5. FIG5_FINAL_BUBBLE_SD.png\n")
cat("   → Tamaño = Desviación Estándar de SNVs\n")
cat("   → Más claro que CV (Coeficiente de Variación)\n")
cat("   → En ESPAÑOL\n\n")

cat("6. FIG6_FINAL_VIOLIN_DISTRIBUTIONS.png\n")
cat("   → Violin plots de SNVs y Counts\n")
cat("   → En ESPAÑOL\n\n")

cat("7. FIG7_FINAL_FOLD_CHANGE_INTEGRATED.png\n")
cat("   → Fold SNVs + Fold Counts en una gráfica\n")
cat("   → En ESPAÑOL\n\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

cat("✅ CORRECCIONES APLICADAS:\n")
cat("   ✅ 12 tipos de mutación (todas incluidas)\n")
cat("   ✅ Todo en español\n")
cat("   ✅ Bubble plot con SD (más claro)\n")
cat("   ✅ Heatmaps de G separados por métrica\n")
cat("   ✅ GT vs GA vs GC en una sola gráfica\n\n")

