#!/usr/bin/env Rscript

# Script para análisis de Z-SCORE y diferencias ALS vs Control
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
library(tibble)  # Para column_to_rownames
library(tidyr)   # Para pivot_wider

cat("🔬 ANÁLISIS Z-SCORE Y DIFERENCIAS ALS vs CONTROL\n")
cat("===============================================\n\n")

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

# --- 2. CALCULAR Z-SCORE POR SNV ---
cat("📊 2. CALCULANDO Z-SCORE POR SNV\n")
cat("================================\n")

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
    als_mean = mean(vaf[is_als], na.rm = TRUE),
    als_sd = sd(vaf[is_als], na.rm = TRUE),
    als_n = sum(is_als, na.rm = TRUE),
    
    # Diferencia absoluta y relativa
    mean_difference = als_mean - control_mean,
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
    )
  ) %>%
  arrange(desc(abs(zscore)))

cat("📈 TOP 20 SNVs CON MAYOR Z-SCORE (DIFERENCIAS MÁS SIGNIFICATIVAS):\n")
print(head(zscore_analysis, 20))
cat("\n")

# --- 3. ANÁLISIS POR POSICIÓN ---
cat("🎯 3. ANÁLISIS POR POSICIÓN EN REGIÓN SEMILLA\n")
cat("=============================================\n")

position_analysis <- zscore_analysis %>%
  group_by(position) %>%
  summarise(
    n_snvs = n(),
    mean_zscore = mean(zscore, na.rm = TRUE),
    median_zscore = median(zscore, na.rm = TRUE),
    sd_zscore = sd(zscore, na.rm = TRUE),
    max_abs_zscore = max(abs(zscore), na.rm = TRUE),
    significant_snvs = sum(abs(zscore) > 1.5 & p_value < 0.01, na.rm = TRUE),
    als_higher_snvs = sum(zscore > 1, na.rm = TRUE),
    control_higher_snvs = sum(zscore < -1, na.rm = TRUE),
    mean_fold_change = mean(fold_change, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(abs(mean_zscore)))

cat("📊 ANÁLISIS POR POSICIÓN:\n")
print(position_analysis)
cat("\n")

# --- 4. ANÁLISIS POR miRNA ---
cat("🧬 4. ANÁLISIS POR miRNA\n")
cat("========================\n")

mirna_analysis <- zscore_analysis %>%
  group_by(`miRNA name`) %>%
  summarise(
    n_snvs = n(),
    mean_zscore = mean(zscore, na.rm = TRUE),
    max_abs_zscore = max(abs(zscore), na.rm = TRUE),
    significant_snvs = sum(abs(zscore) > 1.5 & p_value < 0.01, na.rm = TRUE),
    als_higher_snvs = sum(zscore > 1, na.rm = TRUE),
    control_higher_snvs = sum(zscore < -1, na.rm = TRUE),
    mean_fold_change = mean(fold_change, na.rm = TRUE),
    positions_affected = paste(sort(unique(position)), collapse = ", "),
    .groups = "drop"
  ) %>%
  arrange(desc(max_abs_zscore)) %>%
  head(20)

cat("🏆 TOP 20 miRNAs CON MAYORES DIFERENCIAS (Z-SCORE):\n")
print(mirna_analysis)
cat("\n")

# --- 5. VISUALIZACIONES ---
cat("🎨 5. GENERANDO VISUALIZACIONES\n")
cat("===============================\n")

# Gráfico 1: Z-score por posición
pdf("outputs/zscore_by_position.pdf", width = 10, height = 8)
p_zscore_pos <- ggplot(position_analysis, aes(x = as.factor(position), y = mean_zscore, fill = mean_zscore)) +
  geom_col(alpha = 0.8) +
  geom_hline(yintercept = c(-1.5, 1.5), linetype = "dashed", color = "red", alpha = 0.7) +
  scale_fill_gradient2(low = "blue", mid = "white", high = "red", midpoint = 0) +
  labs(
    title = "Z-Score Promedio por Posición en Región Semilla",
    subtitle = "Comparación ALS vs Control (líneas rojas = ±1.5, umbral de significancia)",
    x = "Posición en miRNA",
    y = "Z-Score Promedio",
    fill = "Z-Score"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    axis.text.x = element_text(size = 12),
    legend.position = "bottom"
  )
print(p_zscore_pos)
dev.off()
cat("✅ Gráfico Z-score por posición guardado en: outputs/zscore_by_position.pdf\n")

# Gráfico 2: Distribución de Z-scores
pdf("outputs/zscore_distribution.pdf", width = 10, height = 8)
p_zscore_dist <- ggplot(zscore_analysis, aes(x = zscore, fill = significance)) +
  geom_histogram(bins = 50, alpha = 0.7) +
  geom_vline(xintercept = c(-1.5, 1.5), linetype = "dashed", color = "red", alpha = 0.7) +
  scale_fill_manual(values = c("Highly Significant" = "red", 
                               "Significant" = "orange",
                               "Moderately Significant" = "yellow",
                               "Not Significant" = "gray")) +
  labs(
    title = "Distribución de Z-Scores: ALS vs Control",
    subtitle = "Líneas rojas = ±1.5 (umbral de significancia)",
    x = "Z-Score",
    y = "Frecuencia",
    fill = "Significancia"
  ) +
  theme_minimal()
print(p_zscore_dist)
dev.off()
cat("✅ Gráfico distribución Z-score guardado en: outputs/zscore_distribution.pdf\n")

# Gráfico 3: Fold change vs Z-score
pdf("outputs/fold_change_vs_zscore.pdf", width = 10, height = 8)
p_fold_zscore <- ggplot(zscore_analysis, aes(x = log2_fold_change, y = zscore, color = significance)) +
  geom_point(alpha = 0.6) +
  geom_hline(yintercept = c(-1.5, 1.5), linetype = "dashed", color = "red", alpha = 0.7) +
  geom_vline(xintercept = c(-1, 1), linetype = "dashed", color = "blue", alpha = 0.7) +
  scale_color_manual(values = c("Highly Significant" = "red", 
                                "Significant" = "orange",
                                "Moderately Significant" = "yellow",
                                "Not Significant" = "gray")) +
  labs(
    title = "Fold Change vs Z-Score: ALS vs Control",
    subtitle = "Líneas rojas = Z-score ±1.5, Líneas azules = Fold change ±2",
    x = "Log2 Fold Change (ALS/Control)",
    y = "Z-Score",
    color = "Significancia"
  ) +
  theme_minimal()
print(p_fold_zscore)
dev.off()
cat("✅ Gráfico fold change vs Z-score guardado en: outputs/fold_change_vs_zscore.pdf\n")

# Gráfico 4: Top miRNAs con diferencias significativas
top_significant_mirnas <- mirna_analysis %>%
  filter(significant_snvs > 0) %>%
  head(15)

if (nrow(top_significant_mirnas) > 0) {
  pdf("outputs/top_significant_mirnas.pdf", width = 12, height = 8)
  p_top_mirnas <- ggplot(top_significant_mirnas, aes(x = reorder(`miRNA name`, max_abs_zscore), y = max_abs_zscore, fill = mean_zscore)) +
    geom_col(alpha = 0.8) +
    geom_hline(yintercept = c(-1.5, 1.5), linetype = "dashed", color = "red", alpha = 0.7) +
    scale_fill_gradient2(low = "blue", mid = "white", high = "red", midpoint = 0) +
    labs(
      title = "Top miRNAs con Diferencias Significativas (Z-Score)",
      subtitle = "Líneas rojas = ±1.5 (umbral de significancia)",
      x = "miRNA",
      y = "Z-Score Máximo",
      fill = "Z-Score Promedio"
    ) +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  print(p_top_mirnas)
  dev.off()
  cat("✅ Gráfico top miRNAs significativos guardado en: outputs/top_significant_mirnas.pdf\n")
}

# --- 6. HEATMAP DE Z-SCORES ---
cat("🔥 6. GENERANDO HEATMAP DE Z-SCORES\n")
cat("===================================\n")

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
  
  # Crear heatmap
  pdf("outputs/zscore_heatmap.pdf", width = 12, height = 10)
  
  # Definir colores
  col_fun <- colorRamp2(c(-3, 0, 3), c("blue", "white", "red"))
  
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
    heatmap_legend_param = list(
      title = "Z-Score\n(ALS vs Control)",
      at = c(-3, -1.5, 0, 1.5, 3),
      labels = c("-3", "-1.5", "0", "1.5", "3")
    )
  )
  
  draw(ht)
  dev.off()
  cat("✅ Heatmap de Z-scores guardado en: outputs/zscore_heatmap.pdf\n")
}

# --- 7. GUARDANDO RESULTADOS ---
cat("💾 7. GUARDANDO RESULTADOS\n")
cat("==========================\n")
write_tsv(zscore_analysis, "outputs/zscore_analysis_results.tsv")
cat("✅ Análisis de Z-score guardado en: outputs/zscore_analysis_results.tsv\n")
write_tsv(position_analysis, "outputs/position_zscore_analysis.tsv")
cat("✅ Análisis por posición guardado en: outputs/position_zscore_analysis.tsv\n")
write_tsv(mirna_analysis, "outputs/mirna_zscore_analysis.tsv")
cat("✅ Análisis por miRNA guardado en: outputs/mirna_zscore_analysis.tsv\n\n")

# --- 8. RESUMEN FINAL ---
cat("🎯 RESUMEN FINAL - ANÁLISIS Z-SCORE ALS vs CONTROL\n")
cat("=================================================\n")
cat("📊 Total SNVs GT analizados:", nrow(zscore_analysis), "\n")
cat("🎯 SNVs con diferencias altamente significativas (|z| > 2, p < 0.001):", 
    sum(abs(zscore_analysis$zscore) > 2 & zscore_analysis$p_value < 0.001), "\n")
cat("📈 SNVs con diferencias significativas (|z| > 1.5, p < 0.01):", 
    sum(abs(zscore_analysis$zscore) > 1.5 & zscore_analysis$p_value < 0.01), "\n")
cat("🔴 SNVs con mayor VAF en ALS:", sum(zscore_analysis$zscore > 1), "\n")
cat("🔵 SNVs con mayor VAF en Control:", sum(zscore_analysis$zscore < -1), "\n")
cat("🎨 Gráficos generados: 4-5\n")
cat("💾 Archivos de datos: 3\n\n")

# Mostrar los SNVs más significativos
cat("🏆 TOP 5 SNVs CON MAYORES DIFERENCIAS:\n")
top_5 <- head(zscore_analysis, 5)
for (i in 1:nrow(top_5)) {
  cat(sprintf("   %d. %s (pos %d): Z-score = %.2f, p = %.2e, %s\n", 
              i, top_5$`miRNA name`[i], top_5$position[i], 
              top_5$zscore[i], top_5$p_value[i], top_5$direction[i]))
}

cat("\n✅ ANÁLISIS Z-SCORE ALS vs CONTROL COMPLETADO\n")
cat("=============================================\n")
