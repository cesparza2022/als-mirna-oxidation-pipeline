library(dplyr)
library(ggplot2)
library(gridExtra)

# =============================================================================
# INTERPRETACIÓN DETALLADA DE LOS HEATMAPS - VAFs vs Z-SCORES
# =============================================================================

cat("=== INTERPRETACIÓN DETALLADA DE LOS HEATMAPS ===\n\n")

# 1. CARGAR Y ANALIZAR LOS DATOS USADOS EN LOS HEATMAPS
# =============================================================================
cat("1. ANÁLISIS DE LOS DATOS ORIGINALES\n")
cat("====================================\n")

final_data <- read.csv("../processed_data/final_processed_data.csv", stringsAsFactors = FALSE)

# Recrear el filtrado usado en los heatmaps
significant_snvs <- final_data %>%
  mutate(pos = as.integer(stringr::str_extract(pos.mut, "^[0-9]+"))) %>%
  filter(pos %in% c(1, 2, 3, 4, 5, 6)) %>%
  select(-pos)

sample_cols <- colnames(significant_snvs)[!colnames(significant_snvs) %in% c("miRNA_name", "pos.mut")]

# Aplicar el mismo filtrado
snv_validity <- significant_snvs %>%
  rowwise() %>%
  mutate(
    n_valid = sum(!is.na(c_across(all_of(sample_cols))) & c_across(all_of(sample_cols)) > 0),
    pct_valid = n_valid / length(sample_cols) * 100
  ) %>%
  ungroup()

min_valid_threshold <- ceiling(length(sample_cols) * 0.05)
filtered_snvs <- snv_validity %>%
  filter(n_valid >= min_valid_threshold) %>%
  select(-n_valid, -pct_valid)

# Crear la matriz de VAFs
vaf_matrix <- as.matrix(filtered_snvs[, sample_cols])
vaf_matrix_clean <- vaf_matrix
vaf_matrix_clean[is.na(vaf_matrix_clean)] <- 0

cat("CARACTERÍSTICAS DE LOS DATOS:\n")
cat("  - SNVs analizados:", nrow(vaf_matrix_clean), "\n")
cat("  - Muestras analizadas:", ncol(vaf_matrix_clean), "\n")
cat("  - Total de celdas:", nrow(vaf_matrix_clean) * ncol(vaf_matrix_clean), "\n\n")

# 2. ANÁLISIS DETALLADO DE VAFs
# =============================================================================
cat("2. ANÁLISIS DETALLADO DE VAFs\n")
cat("==============================\n")

# Estadísticas de VAFs
vaf_stats <- data.frame(
  total_cells = length(vaf_matrix_clean),
  zero_cells = sum(vaf_matrix_clean == 0),
  nonzero_cells = sum(vaf_matrix_clean > 0),
  na_cells = sum(is.na(vaf_matrix)),
  min_vaf = min(vaf_matrix_clean[vaf_matrix_clean > 0], na.rm = TRUE),
  max_vaf = max(vaf_matrix_clean, na.rm = TRUE),
  mean_vaf = mean(vaf_matrix_clean[vaf_matrix_clean > 0], na.rm = TRUE),
  median_vaf = median(vaf_matrix_clean[vaf_matrix_clean > 0], na.rm = TRUE)
)

cat("ESTADÍSTICAS DE VAFs:\n")
cat("  - Celdas totales:", vaf_stats$total_cells, "\n")
cat("  - Celdas con VAF = 0:", vaf_stats$zero_cells, "(", round(vaf_stats$zero_cells/vaf_stats$total_cells*100, 2), "%)\n")
cat("  - Celdas con VAF > 0:", vaf_stats$nonzero_cells, "(", round(vaf_stats$nonzero_cells/vaf_stats$total_cells*100, 2), "%)\n")
cat("  - Celdas NA originales:", vaf_stats$na_cells, "\n\n")

cat("RANGO DE VAFs NO-CERO:\n")
cat("  - VAF mínimo:", round(vaf_stats$min_vaf, 6), "\n")
cat("  - VAF máximo:", round(vaf_stats$max_vaf, 6), "\n")
cat("  - VAF promedio:", round(vaf_stats$mean_vaf, 6), "\n")
cat("  - VAF mediana:", round(vaf_stats$median_vaf, 6), "\n\n")

# Distribución de VAFs
vaf_distribution <- table(cut(vaf_matrix_clean[vaf_matrix_clean > 0], 
                             breaks = c(0, 0.001, 0.01, 0.05, 0.1, 0.5),
                             labels = c("0-0.001", "0.001-0.01", "0.01-0.05", "0.05-0.1", "0.1-0.5")))

cat("DISTRIBUCIÓN DE VAFs NO-CERO:\n")
for (i in 1:length(vaf_distribution)) {
  cat("  -", names(vaf_distribution)[i], ":", vaf_distribution[i], "celdas\n")
}
cat("\n")

# 3. ANÁLISIS DETALLADO DE Z-SCORES
# =============================================================================
cat("3. ANÁLISIS DETALLADO DE Z-SCORES\n")
cat("==================================\n")

# Calcular z-scores como en el heatmap
zscore_matrix <- t(apply(vaf_matrix_clean, 1, function(x) {
  if (sd(x, na.rm = TRUE) == 0) {
    return(rep(0, length(x)))
  } else {
    return(scale(x)[,1])
  }
}))

zscore_matrix[is.na(zscore_matrix)] <- 0

# Estadísticas de Z-scores
zscore_stats <- data.frame(
  total_cells = length(zscore_matrix),
  zero_cells = sum(abs(zscore_matrix) < 0.01),  # Prácticamente cero
  significant_cells = sum(abs(zscore_matrix) > 2),  # |z| > 2
  extreme_cells = sum(abs(zscore_matrix) > 3),  # |z| > 3
  min_zscore = min(zscore_matrix, na.rm = TRUE),
  max_zscore = max(zscore_matrix, na.rm = TRUE),
  mean_abs_zscore = mean(abs(zscore_matrix), na.rm = TRUE),
  median_abs_zscore = median(abs(zscore_matrix), na.rm = TRUE)
)

cat("ESTADÍSTICAS DE Z-SCORES:\n")
cat("  - Celdas totales:", zscore_stats$total_cells, "\n")
cat("  - Celdas ~0 (|z| < 0.01):", zscore_stats$zero_cells, "(", round(zscore_stats$zero_cells/zscore_stats$total_cells*100, 2), "%)\n")
cat("  - Celdas significativas (|z| > 2):", zscore_stats$significant_cells, "(", round(zscore_stats$significant_cells/zscore_stats$total_cells*100, 2), "%)\n")
cat("  - Celdas extremas (|z| > 3):", zscore_stats$extreme_cells, "(", round(zscore_stats$extreme_cells/zscore_stats$total_cells*100, 2), "%)\n\n")

cat("RANGO DE Z-SCORES:\n")
cat("  - Z-score mínimo:", round(zscore_stats$min_zscore, 3), "\n")
cat("  - Z-score máximo:", round(zscore_stats$max_zscore, 3), "\n")
cat("  - |Z-score| promedio:", round(zscore_stats$mean_abs_zscore, 3), "\n")
cat("  - |Z-score| mediana:", round(zscore_stats$median_abs_zscore, 3), "\n\n")

# 4. COMPARACIÓN VISUAL DE DISTRIBUCIONES
# =============================================================================
cat("4. CREANDO COMPARACIÓN VISUAL\n")
cat("==============================\n")

# Preparar datos para gráficos
vaf_data <- data.frame(
  value = as.vector(vaf_matrix_clean),
  type = "VAF"
)

zscore_data <- data.frame(
  value = as.vector(zscore_matrix),
  type = "Z-score"
)

# Gráfico de distribución de VAFs
p1 <- ggplot(vaf_data, aes(x = value)) +
  geom_histogram(bins = 50, fill = "#FF9900", alpha = 0.7, color = "black") +
  scale_x_continuous(limits = c(0, 0.5)) +
  labs(
    title = "Distribución de VAFs",
    subtitle = paste("86.37% de celdas = 0,", round(vaf_stats$nonzero_cells/vaf_stats$total_cells*100, 2), "% > 0"),
    x = "VAF",
    y = "Frecuencia"
  ) +
  theme_minimal() +
  theme(plot.title = element_text(size = 14, face = "bold"))

# Gráfico de distribución de Z-scores
p2 <- ggplot(zscore_data, aes(x = value)) +
  geom_histogram(bins = 50, fill = "#2166AC", alpha = 0.7, color = "black") +
  labs(
    title = "Distribución de Z-scores",
    subtitle = paste(round(zscore_stats$significant_cells/zscore_stats$total_cells*100, 2), "% con |z| > 2"),
    x = "Z-score",
    y = "Frecuencia"
  ) +
  theme_minimal() +
  theme(plot.title = element_text(size = 14, face = "bold"))

# Guardar comparación
pdf("comparacion_distribuciones_vaf_zscore.pdf", width = 12, height = 6)
grid.arrange(p1, p2, ncol = 2)
dev.off()

cat("Gráfico guardado: comparacion_distribuciones_vaf_zscore.pdf\n\n")

# 5. EXPLICACIÓN DE LAS DIFERENCIAS VISUALES
# =============================================================================
cat("5. EXPLICACIÓN DE LAS DIFERENCIAS VISUALES\n")
cat("===========================================\n")

cat("¿POR QUÉ EL HEATMAP DE VAFs SE VE 'VACÍO'?\n")
cat("------------------------------------------\n")
cat("1. SPARSITY EXTREMA:\n")
cat("   - 86.37% de las celdas tienen VAF = 0\n")
cat("   - Solo 13.63% tienen valores > 0\n")
cat("   - Esto es NORMAL para mutaciones raras\n\n")

cat("2. RANGO DE VALORES MUY PEQUEÑO:\n")
cat("   - VAFs van de", round(vaf_stats$min_vaf, 6), "a", round(vaf_stats$max_vaf, 6), "\n")
cat("   - La mayoría están entre 0.001-0.05\n")
cat("   - Diferencias muy sutiles visualmente\n\n")

cat("3. ESCALA DE COLORES:\n")
cat("   - Blanco para VAF = 0 (86.37% de celdas)\n")
cat("   - Colores muy tenues para VAFs bajos\n")
cat("   - Solo valores altos (>0.1) se ven claramente\n\n")

cat("¿POR QUÉ EL HEATMAP DE Z-SCORES SE VE MÁS 'INFORMATIVO'?\n")
cat("--------------------------------------------------------\n")
cat("1. NORMALIZACIÓN POR SNV:\n")
cat("   - Cada fila (SNV) se normaliza independientemente\n")
cat("   - Resalta desviaciones relativas al promedio de ese SNV\n")
cat("   - Amplifica diferencias sutiles\n\n")

cat("2. RANGO DINÁMICO MAYOR:\n")
cat("   - Z-scores van de", round(zscore_stats$min_zscore, 3), "a", round(zscore_stats$max_zscore, 3), "\n")
cat("   - Rango mucho más amplio que VAFs\n")
cat("   - Mejor contraste visual\n\n")

cat("3. INTERPRETACIÓN ESTADÍSTICA:\n")
cat("   -", round(zscore_stats$significant_cells/zscore_stats$total_cells*100, 2), "% de celdas con |z| > 2 (significativas)\n")
cat("   -", round(zscore_stats$extreme_cells/zscore_stats$total_cells*100, 2), "% de celdas con |z| > 3 (muy extremas)\n")
cat("   - Identifica outliers y patrones anómalos\n\n")

# 6. INTERPRETACIÓN BIOLÓGICA
# =============================================================================
cat("6. INTERPRETACIÓN BIOLÓGICA\n")
cat("============================\n")

cat("HEATMAP DE VAFs (Valores Absolutos):\n")
cat("------------------------------------\n")
cat("✓ VENTAJAS:\n")
cat("  - Muestra la intensidad real de mutaciones\n")
cat("  - Identifica SNVs con altas frecuencias alélicas\n")
cat("  - Relevante para carga mutacional total\n\n")

cat("✗ LIMITACIONES:\n")
cat("  - Dominado por ceros (mutaciones ausentes)\n")
cat("  - Diferencias sutiles no son visibles\n")
cat("  - Sesgado hacia SNVs más frecuentes\n\n")

cat("HEATMAP DE Z-SCORES (Valores Relativos):\n")
cat("----------------------------------------\n")
cat("✓ VENTAJAS:\n")
cat("  - Resalta patrones de desviación por SNV\n")
cat("  - Identifica muestras anómalas para cada SNV\n")
cat("  - Mejor para clustering y clasificación\n")
cat("  - Normaliza diferencias de escala\n\n")

cat("✗ LIMITACIONES:\n")
cat("  - Pierde información de magnitud absoluta\n")
cat("  - Puede amplificar ruido técnico\n")
cat("  - Más difícil interpretación clínica directa\n\n")

# 7. RECOMENDACIONES DE USO
# =============================================================================
cat("7. RECOMENDACIONES DE USO\n")
cat("==========================\n")

cat("CUÁNDO USAR HEATMAP DE VAFs:\n")
cat("  - Para mostrar carga mutacional absoluta\n")
cat("  - Identificar muestras con alta oxidación global\n")
cat("  - Comparar intensidades entre grupos\n")
cat("  - Análisis de dosis-respuesta\n\n")

cat("CUÁNDO USAR HEATMAP DE Z-SCORES:\n")
cat("  - Para clustering y clasificación\n")
cat("  - Identificar patrones de co-variación\n")
cat("  - Detectar outliers y subgrupos\n")
cat("  - Análisis de expresión diferencial\n\n")

cat("ESTRATEGIA COMBINADA:\n")
cat("  1. Z-scores para identificar patrones\n")
cat("  2. VAFs para validar magnitudes biológicas\n")
cat("  3. Ambos son complementarios, no excluyentes\n\n")

# 8. RESUMEN EJECUTIVO
# =============================================================================
cat("8. RESUMEN EJECUTIVO\n")
cat("====================\n")

cat("LA DIFERENCIA VISUAL ES ESPERADA Y CORRECTA:\n")
cat("  🔍 VAFs: 86.37% ceros → Heatmap 'vacío'\n")
cat("  🔍 Z-scores: Normalización → Patrones visibles\n")
cat("  🔍 Ambos son válidos para diferentes propósitos\n\n")

cat("CONCLUSIÓN CLAVE:\n")
cat("  El heatmap de Z-scores es MÁS ÚTIL para:\n")
cat("  - Identificar subgrupos de pacientes\n")
cat("  - Detectar patrones de co-mutación\n")
cat("  - Clustering y clasificación\n\n")

cat("  El heatmap de VAFs es MÁS ÚTIL para:\n")
cat("  - Cuantificar carga mutacional\n")
cat("  - Comparaciones de intensidad\n")
cat("  - Interpretación clínica directa\n\n")

cat("=== INTERPRETACIÓN COMPLETADA ===\n")









