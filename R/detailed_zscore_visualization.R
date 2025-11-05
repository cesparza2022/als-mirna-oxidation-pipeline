#!/usr/bin/env Rscript

# Script para visualizaciones detalladas de patrones de oxidación con Z-scores
# miRNAs y Oxidación - Análisis ALS

library(dplyr)
library(readr)
library(stringr)
library(ggplot2)
library(ComplexHeatmap)
library(circlize)
library(reshape2)
library(gridExtra)
library(pheatmap)
library(tibble)
library(tidyr)
library(RColorBrewer)
library(viridis)
library(ggrepel)
library(cowplot)

cat("🎨 VISUALIZACIONES DETALLADAS DE PATRONES DE OXIDACIÓN CON Z-SCORES\n")
cat("================================================================\n\n")

# Cargar datos procesados
cat("📂 Cargando datos procesados...\n")
df <- read_tsv("outputs/processed_snv_data_vaf_filtered.tsv", show_col_types = FALSE)

# Obtener columnas de muestras (solo las de conteos, no las de totales)
sample_names <- colnames(df)[grep("Magen-", colnames(df))]
sample_names <- sample_names[!grepl("\\(PM\\+1MM\\+2MM\\)", sample_names)]  # Solo conteos, no totales

# Clasificar muestras
is_control <- grepl("control", sample_names, ignore.case = TRUE)
is_als_enrolment <- grepl("ALS-enrolment", sample_names, ignore.case = TRUE)
is_als_longitudinal <- grepl("ALS-longitudinal", sample_names, ignore.case = TRUE)

# Crear metadata de muestras
sample_metadata <- data.frame(
  sample = sample_names,
  group = case_when(
    is_control ~ "Control",
    is_als_enrolment ~ "ALS_Enrolment", 
    is_als_longitudinal ~ "ALS_Longitudinal",
    TRUE ~ "Other"
  ),
  is_control = is_control,
  is_als = is_als_enrolment | is_als_longitudinal
)

cat("📊 DISTRIBUCIÓN DE MUESTRAS:\n")
print(table(sample_metadata$group))
cat("\n")

# --- EXPLICACIÓN DEL CÁLCULO DE Z-SCORE ---
cat("🧮 EXPLICACIÓN DEL CÁLCULO DE Z-SCORE\n")
cat("=====================================\n")
cat("El Z-score se calcula de la siguiente manera:\n")
cat("1. Para cada SNV G>T, calculamos VAF promedio en cada grupo (ALS vs Control)\n")
cat("2. Calculamos la desviación estándar combinada (pooled standard deviation)\n")
cat("3. Z-score = (VAF_ALS - VAF_Control) / pooled_sd\n")
cat("4. Esto nos da la diferencia estandarizada entre grupos\n")
cat("5. Z-score > 0: Mayor oxidación en ALS\n")
cat("6. Z-score < 0: Mayor oxidación en Control\n")
cat("7. |Z-score| > 1.5: Diferencia significativa\n")
cat("8. |Z-score| > 2.0: Diferencia altamente significativa\n\n")

# --- 1. ANÁLISIS DE MUTACIONES GT EN REGIÓN SEMILLA ---
cat("🎯 1. ANÁLISIS DE MUTACIONES GT EN REGIÓN SEMILLA\n")
cat("=================================================\n")

# Filtrar mutaciones GT en región semilla (posiciones 2-8)
gt_seed_mutations <- df %>%
  filter(
    str_detect(`pos:mut`, ":GT$"),
    as.numeric(str_extract(`pos:mut`, "^[0-9]+")) %in% 2:8
  ) %>%
  mutate(
    position = as.numeric(str_extract(`pos:mut`, "^[0-9]+")),
    mutation = str_extract(`pos:mut`, "[A-Z][A-Z]$")
  )

cat("🧬 MUTACIONES GT EN REGIÓN SEMILLA IDENTIFICADAS:\n")
cat("   - Total SNVs GT en semilla:", nrow(gt_seed_mutations), "\n")
cat("   - miRNAs únicos afectados:", length(unique(gt_seed_mutations$`miRNA name`)), "\n")
cat("   - Posiciones cubiertas:", paste(sort(unique(gt_seed_mutations$position)), collapse = ", "), "\n\n")

# --- 2. CALCULAR Z-SCORE DETALLADO ---
cat("📊 2. CALCULANDO Z-SCORE DETALLADO\n")
cat("==================================\n")

# Calcular z-score para cada SNV comparando ALS vs Control
zscore_analysis <- gt_seed_mutations %>%
  select(`miRNA name`, `pos:mut`, position, all_of(sample_names)) %>%
  melt(id.vars = c("miRNA name", "pos:mut", "position"), 
       variable.name = "sample", value.name = "vaf") %>%
  mutate(vaf = as.numeric(vaf)) %>%
  left_join(sample_metadata, by = "sample") %>%
  filter(!is.na(vaf), vaf > 0) %>% # Solo VAFs presentes
  group_by(`miRNA name`, `pos:mut`, position) %>%
  summarise(
    # Estadísticas por grupo
    control_mean = mean(vaf[is_control], na.rm = TRUE),
    control_sd = sd(vaf[is_control], na.rm = TRUE),
    control_n = sum(is_control, na.rm = TRUE),
    control_median = median(vaf[is_control], na.rm = TRUE),
    als_mean = mean(vaf[is_als], na.rm = TRUE),
    als_sd = sd(vaf[is_als], na.rm = TRUE),
    als_n = sum(is_als, na.rm = TRUE),
    als_median = median(vaf[is_als], na.rm = TRUE),
    
    # Diferencia absoluta y relativa
    mean_difference = als_mean - control_mean,
    median_difference = als_median - control_median,
    fold_change = ifelse(control_mean > 0, als_mean / control_mean, NA),
    log2_fold_change = ifelse(control_mean > 0, log2(als_mean / control_mean), NA),
    
    # Z-score (diferencia estandarizada)
    pooled_sd = sqrt(((control_n - 1) * control_sd^2 + (als_n - 1) * als_sd^2) / (control_n + als_n - 2)),
    zscore = ifelse(pooled_sd > 0, mean_difference / pooled_sd, 0),
    
    # Significancia estadística
    t_stat = ifelse(pooled_sd > 0, mean_difference / (pooled_sd * sqrt(1/control_n + 1/als_n)), 0),
    p_value = 2 * (1 - pt(abs(t_stat), control_n + als_n - 2)),
    
    .groups = "drop"
  ) %>%
  mutate(
    # Categorizar significancia
    significance = case_when(
      p_value < 0.001 & abs(zscore) > 2 ~ "Highly Significant",
      p_value < 0.01 & abs(zscore) > 1.5 ~ "Significant", 
      p_value < 0.05 & abs(zscore) > 1 ~ "Moderately Significant",
      TRUE ~ "Not Significant"
    ),
    # Dirección del cambio
    direction = case_when(
      zscore > 1 ~ "ALS Higher",
      zscore < -1 ~ "Control Higher",
      TRUE ~ "No Clear Difference"
    ),
    # Magnitud del efecto
    effect_size = case_when(
      abs(zscore) > 2 ~ "Large",
      abs(zscore) > 1.5 ~ "Medium",
      abs(zscore) > 1 ~ "Small",
      TRUE ~ "Negligible"
    )
  ) %>%
  arrange(desc(abs(zscore)))

cat("📈 TOP 10 SNVs CON MAYOR Z-SCORE (DIFERENCIAS MÁS SIGNIFICATIVAS):\n")
print(head(zscore_analysis, 10))
cat("\n")

# --- 3. ANÁLISIS POR POSICIÓN DETALLADO ---
cat("🎯 3. ANÁLISIS POR POSICIÓN DETALLADO\n")
cat("=====================================\n")

position_analysis <- zscore_analysis %>%
  group_by(position) %>%
  summarise(
    n_snvs = n(),
    mean_zscore = mean(zscore, na.rm = TRUE),
    median_zscore = median(zscore, na.rm = TRUE),
    sd_zscore = sd(zscore, na.rm = TRUE),
    max_abs_zscore = max(abs(zscore), na.rm = TRUE),
    significant_snvs = sum(abs(zscore) > 1.5 & p_value < 0.01, na.rm = TRUE),
    highly_significant_snvs = sum(abs(zscore) > 2 & p_value < 0.001, na.rm = TRUE),
    als_higher_snvs = sum(zscore > 1, na.rm = TRUE),
    control_higher_snvs = sum(zscore < -1, na.rm = TRUE),
    mean_fold_change = mean(fold_change, na.rm = TRUE),
    mean_control_vaf = mean(control_mean, na.rm = TRUE),
    mean_als_vaf = mean(als_mean, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(abs(mean_zscore)))

cat("📊 ANÁLISIS DETALLADO POR POSICIÓN:\n")
print(position_analysis)
cat("\n")

# --- 4. VISUALIZACIONES DETALLADAS ---
cat("🎨 4. GENERANDO VISUALIZACIONES DETALLADAS\n")
cat("==========================================\n")

# --- GRÁFICO 1: Z-score por posición con barras de error ---
pdf("outputs/detailed_zscore_by_position.pdf", width = 12, height = 8)
p1 <- ggplot(position_analysis, aes(x = as.factor(position), y = mean_zscore, fill = mean_zscore)) +
  geom_col(alpha = 0.8, width = 0.7) +
  geom_errorbar(aes(ymin = mean_zscore - sd_zscore, ymax = mean_zscore + sd_zscore), 
                width = 0.2, alpha = 0.7) +
  geom_hline(yintercept = c(-2, -1.5, 0, 1.5, 2), linetype = c("dashed", "dotted", "solid", "dotted", "dashed"), 
             color = c("red", "orange", "black", "orange", "red"), alpha = 0.7) +
  scale_fill_gradient2(low = "blue", mid = "white", high = "red", midpoint = 0, 
                       name = "Z-Score") +
  labs(
    title = "Z-Score Promedio por Posición en Región Semilla",
    subtitle = "Comparación ALS vs Control con barras de error (desviación estándar)\nLíneas: ±2 (roja, altamente significativo), ±1.5 (naranja, significativo)",
    x = "Posición en miRNA",
    y = "Z-Score Promedio",
    caption = "Z-score > 0: Mayor oxidación en ALS\nZ-score < 0: Mayor oxidación en Control"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold"),
    plot.subtitle = element_text(size = 12),
    axis.text.x = element_text(size = 14),
    axis.text.y = element_text(size = 12),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )
print(p1)
dev.off()
cat("✅ Gráfico detallado Z-score por posición guardado en: outputs/detailed_zscore_by_position.pdf\n")

# --- GRÁFICO 2: Distribución de Z-scores con densidad ---
pdf("outputs/detailed_zscore_distribution.pdf", width = 12, height = 8)
p2 <- ggplot(zscore_analysis, aes(x = zscore, fill = significance)) +
  geom_histogram(bins = 50, alpha = 0.7, color = "white", size = 0.3) +
  geom_density(aes(y = ..count..), alpha = 0.3, color = "black", size = 1) +
  geom_vline(xintercept = c(-2, -1.5, 0, 1.5, 2), linetype = c("dashed", "dotted", "solid", "dotted", "dashed"), 
             color = c("red", "orange", "black", "orange", "red"), alpha = 0.8) +
  scale_fill_manual(values = c("Highly Significant" = "red", 
                               "Significant" = "orange",
                               "Moderately Significant" = "yellow",
                               "Not Significant" = "gray80"),
                    name = "Significancia") +
  labs(
    title = "Distribución de Z-Scores: ALS vs Control",
    subtitle = "Histograma con curva de densidad superpuesta\nLíneas: ±2 (roja), ±1.5 (naranja), 0 (negro)",
    x = "Z-Score",
    y = "Frecuencia",
    caption = "Z-score = (VAF_ALS - VAF_Control) / pooled_sd"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold"),
    plot.subtitle = element_text(size = 12),
    legend.position = "bottom"
  )
print(p2)
dev.off()
cat("✅ Gráfico detallado distribución Z-score guardado en: outputs/detailed_zscore_distribution.pdf\n")

# --- GRÁFICO 3: Fold change vs Z-score con etiquetas ---
pdf("outputs/detailed_fold_change_vs_zscore.pdf", width = 14, height = 10)
# Filtrar datos para etiquetar solo los más significativos
top_snvs <- zscore_analysis %>%
  filter(abs(zscore) > 1.5 | abs(log2_fold_change) > 1) %>%
  head(20)

p3 <- ggplot(zscore_analysis, aes(x = log2_fold_change, y = zscore, color = significance, size = effect_size)) +
  geom_point(alpha = 0.6) +
  geom_hline(yintercept = c(-2, -1.5, 0, 1.5, 2), linetype = c("dashed", "dotted", "solid", "dotted", "dashed"), 
             color = c("red", "orange", "black", "orange", "red"), alpha = 0.7) +
  geom_vline(xintercept = c(-1, 0, 1), linetype = c("dotted", "solid", "dotted"), 
             color = c("blue", "black", "blue"), alpha = 0.7) +
  geom_text_repel(data = top_snvs, 
                  aes(label = paste(`miRNA name`, position, sep = " pos ")),
                  size = 3, max.overlaps = 15, force = 2) +
  scale_color_manual(values = c("Highly Significant" = "red", 
                                "Significant" = "orange",
                                "Moderately Significant" = "yellow",
                                "Not Significant" = "gray70"),
                     name = "Significancia") +
  scale_size_manual(values = c("Large" = 3, "Medium" = 2.5, "Small" = 2, "Negligible" = 1.5),
                    name = "Tamaño del Efecto") +
  labs(
    title = "Fold Change vs Z-Score: Patrones de Oxidación Diferencial",
    subtitle = "Cada punto representa un SNV G>T en región semilla\nEtiquetas: Top 20 SNVs más significativos",
    x = "Log2 Fold Change (ALS/Control)",
    y = "Z-Score",
    caption = "Líneas verticales: ±1 (azul, 2x fold change)\nLíneas horizontales: ±1.5 (naranja), ±2 (roja)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold"),
    plot.subtitle = element_text(size = 12),
    legend.position = "bottom",
    legend.box = "horizontal"
  )
print(p3)
dev.off()
cat("✅ Gráfico detallado fold change vs Z-score guardado en: outputs/detailed_fold_change_vs_zscore.pdf\n")

# --- GRÁFICO 4: VAF promedio por grupo y posición ---
pdf("outputs/detailed_vaf_by_group_position.pdf", width = 14, height = 10)
vaf_summary <- zscore_analysis %>%
  select(position, control_mean, als_mean, `miRNA name`) %>%
  pivot_longer(cols = c(control_mean, als_mean), names_to = "group", values_to = "vaf_mean") %>%
  mutate(group = case_when(
    group == "control_mean" ~ "Control",
    group == "als_mean" ~ "ALS"
  ))

p4 <- ggplot(vaf_summary, aes(x = as.factor(position), y = vaf_mean, fill = group)) +
  geom_boxplot(alpha = 0.7, position = position_dodge(width = 0.8)) +
  geom_violin(alpha = 0.3, position = position_dodge(width = 0.8)) +
  scale_fill_manual(values = c("Control" = "blue", "ALS" = "red"),
                    name = "Grupo") +
  labs(
    title = "Distribución de VAF Promedio por Posición y Grupo",
    subtitle = "Boxplot y violín superpuestos mostrando distribución de VAF\npor posición en región semilla",
    x = "Posición en miRNA",
    y = "VAF Promedio",
    caption = "VAF = Variant Allele Frequency (frecuencia alélica variante)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold"),
    plot.subtitle = element_text(size = 12),
    legend.position = "bottom"
  )
print(p4)
dev.off()
cat("✅ Gráfico detallado VAF por grupo y posición guardado en: outputs/detailed_vaf_by_group_position.pdf\n")

# --- GRÁFICO 5: Heatmap de Z-scores mejorado ---
pdf("outputs/detailed_zscore_heatmap.pdf", width = 16, height = 12)
# Crear matriz de Z-scores para heatmap
zscore_matrix <- zscore_analysis %>%
  select(`miRNA name`, position, zscore) %>%
  pivot_wider(names_from = position, values_from = zscore, values_fill = 0) %>%
  as.data.frame() %>%
  column_to_rownames("miRNA name") %>%
  as.matrix()

# Filtrar miRNAs con al menos un Z-score significativo
significant_mirnas <- zscore_analysis %>%
  filter(abs(zscore) > 1.5) %>%
  pull(`miRNA name`) %>%
  unique()

if (length(significant_mirnas) > 0) {
  zscore_matrix_filtered <- zscore_matrix[rownames(zscore_matrix) %in% significant_mirnas, ]
  
  # Crear anotaciones
  row_annotation <- data.frame(
    miRNA = rownames(zscore_matrix_filtered),
    max_zscore = apply(zscore_matrix_filtered, 1, function(x) max(abs(x), na.rm = TRUE)),
    direction = apply(zscore_matrix_filtered, 1, function(x) {
      if (max(x, na.rm = TRUE) > 1.5) "ALS Higher" else if (min(x, na.rm = TRUE) < -1.5) "Control Higher" else "Mixed"
    })
  )
  
  # Definir colores
  col_fun <- colorRamp2(c(-3, -1.5, 0, 1.5, 3), c("darkblue", "blue", "white", "red", "darkred"))
  
  # Crear heatmap
  ht <- Heatmap(
    zscore_matrix_filtered,
    name = "Z-Score",
    col = col_fun,
    cluster_rows = TRUE,
    cluster_columns = FALSE,
    show_row_names = TRUE,
    show_column_names = TRUE,
    column_title = "Posición en Región Semilla",
    row_title = "miRNAs con Diferencias Significativas",
    row_names_gp = gpar(fontsize = 8),
    column_names_gp = gpar(fontsize = 12),
    heatmap_legend_param = list(
      title = "Z-Score\n(ALS vs Control)",
      at = c(-3, -1.5, 0, 1.5, 3),
      labels = c("-3", "-1.5", "0", "1.5", "3")
    )
  )
  
  draw(ht)
}
dev.off()
cat("✅ Heatmap detallado de Z-scores guardado en: outputs/detailed_zscore_heatmap.pdf\n")

# --- GRÁFICO 6: Análisis de significancia por posición ---
pdf("outputs/detailed_significance_by_position.pdf", width = 12, height = 8)
significance_summary <- zscore_analysis %>%
  group_by(position, significance) %>%
  summarise(count = n(), .groups = "drop") %>%
  group_by(position) %>%
  mutate(percentage = count / sum(count) * 100)

p6 <- ggplot(significance_summary, aes(x = as.factor(position), y = percentage, fill = significance)) +
  geom_col(alpha = 0.8) +
  scale_fill_manual(values = c("Highly Significant" = "red", 
                               "Significant" = "orange",
                               "Moderately Significant" = "yellow",
                               "Not Significant" = "gray80"),
                    name = "Significancia") +
  labs(
    title = "Distribución de Significancia por Posición",
    subtitle = "Porcentaje de SNVs por nivel de significancia en cada posición",
    x = "Posición en miRNA",
    y = "Porcentaje de SNVs",
    caption = "Basado en Z-score y p-value"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold"),
    plot.subtitle = element_text(size = 12),
    legend.position = "bottom"
  )
print(p6)
dev.off()
cat("✅ Gráfico detallado significancia por posición guardado en: outputs/detailed_significance_by_position.pdf\n")

# --- 5. GUARDANDO RESULTADOS DETALLADOS ---
cat("💾 5. GUARDANDO RESULTADOS DETALLADOS\n")
cat("=====================================\n")
write_tsv(zscore_analysis, "outputs/detailed_zscore_analysis_results.tsv")
cat("✅ Análisis detallado de Z-score guardado en: outputs/detailed_zscore_analysis_results.tsv\n")
write_tsv(position_analysis, "outputs/detailed_position_zscore_analysis.tsv")
cat("✅ Análisis detallado por posición guardado en: outputs/detailed_position_zscore_analysis.tsv\n\n")

# --- 6. RESUMEN FINAL DETALLADO ---
cat("🎯 RESUMEN FINAL - VISUALIZACIONES DETALLADAS DE Z-SCORE\n")
cat("=======================================================\n")
cat("📊 Total SNVs GT analizados:", nrow(zscore_analysis), "\n")
cat("🎯 SNVs con diferencias altamente significativas (|z| > 2, p < 0.001):", 
    sum(abs(zscore_analysis$zscore) > 2 & zscore_analysis$p_value < 0.001, na.rm = TRUE), "\n")
cat("📈 SNVs con diferencias significativas (|z| > 1.5, p < 0.01):", 
    sum(abs(zscore_analysis$zscore) > 1.5 & zscore_analysis$p_value < 0.01, na.rm = TRUE), "\n")
cat("🔴 SNVs con mayor VAF en ALS:", sum(zscore_analysis$zscore > 1, na.rm = TRUE), "\n")
cat("🔵 SNVs con mayor VAF en Control:", sum(zscore_analysis$zscore < -1, na.rm = TRUE), "\n")
cat("🎨 Gráficos detallados generados: 6\n")
cat("💾 Archivos de datos: 2\n\n")

# Mostrar los SNVs más significativos con detalles
cat("🏆 TOP 5 SNVs CON MAYORES DIFERENCIAS (DETALLADO):\n")
top_5_detailed <- head(zscore_analysis, 5)
for (i in 1:nrow(top_5_detailed)) {
  cat(sprintf("   %d. %s (pos %d):\n", i, top_5_detailed$`miRNA name`[i], top_5_detailed$position[i]))
  cat(sprintf("      - Z-score: %.2f (p = %.2e)\n", top_5_detailed$zscore[i], top_5_detailed$p_value[i]))
  cat(sprintf("      - VAF Control: %.2f ± %.2f (n=%d)\n", top_5_detailed$control_mean[i], top_5_detailed$control_sd[i], top_5_detailed$control_n[i]))
  cat(sprintf("      - VAF ALS: %.2f ± %.2f (n=%d)\n", top_5_detailed$als_mean[i], top_5_detailed$als_sd[i], top_5_detailed$als_n[i]))
  cat(sprintf("      - Fold change: %.2f (log2: %.2f)\n", top_5_detailed$fold_change[i], top_5_detailed$log2_fold_change[i]))
  cat(sprintf("      - Dirección: %s\n", top_5_detailed$direction[i]))
  cat(sprintf("      - Significancia: %s\n\n", top_5_detailed$significance[i]))
}

cat("✅ VISUALIZACIONES DETALLADAS DE PATRONES DE OXIDACIÓN COMPLETADAS\n")
cat("================================================================\n")










