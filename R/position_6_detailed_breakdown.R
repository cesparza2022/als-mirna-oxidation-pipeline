#!/usr/bin/env Rscript

# =============================================================================
# ANÁLISIS DETALLADO PASO A PASO - POSICIÓN 6
# =============================================================================
# Este script desglosa cada paso del análisis de posición 6 para entender
# por qué se concluye que no es importante estadísticamente.

cat("=== ANÁLISIS DETALLADO PASO A PASO - POSICIÓN 6 ===\n\n")

# Cargar librerías
library(dplyr)
library(readr)
library(stringr)
library(ggplot2)

cat("PASO 1: Cargando datos\n")
cat("==========================================\n")

# Cargar datos
df_main <- read_tsv("results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt")
cat(paste0("  - Archivo cargado: miRNA_count.Q33.txt\n"))
cat(paste0("  - Dimensiones originales: ", nrow(df_main), " filas x ", ncol(df_main), " columnas\n"))

# Remover primera fila (metadatos)
df_main <- df_main[-1, ]
cat(paste0("  - Después de remover metadatos: ", nrow(df_main), " filas x ", ncol(df_main), " columnas\n"))

# Identificar columnas
sample_cols <- names(df_main)[!names(df_main) %in% c("miRNA name", "pos:mut")]
cat(paste0("  - Columnas de muestras: ", length(sample_cols), "\n"))

# Identificar muestras ALS y Control
als_samples <- sample_cols[str_detect(sample_cols, "Magen-ALS")]
control_samples <- sample_cols[str_detect(sample_cols, "Magen-control")]

cat(paste0("  - Muestras ALS: ", length(als_samples), "\n"))
cat(paste0("  - Muestras Control: ", length(control_samples), "\n\n"))

cat("PASO 2: Filtrando mutaciones G>T en posición 6\n")
cat("==========================================\n")

# Filtrar para posición 6 con mutación GT
pos6_gt <- df_main %>% 
  filter(str_detect(`pos:mut`, "^6:GT"))

cat(paste0("  - SNVs G>T en posición 6 encontrados: ", nrow(pos6_gt), "\n"))

if (nrow(pos6_gt) > 0) {
  cat("  - Primeros 5 SNVs encontrados:\n")
  print(head(pos6_gt[, c("miRNA name", "pos:mut")], 5))
  
  # Mostrar miRNAs únicos
  unique_mirnas <- unique(pos6_gt$`miRNA name`)
  cat(paste0("  - miRNAs únicos con G>T en posición 6: ", length(unique_mirnas), "\n"))
  cat("  - Primeros 10 miRNAs:\n")
  print(head(unique_mirnas, 10))
} else {
  cat("  - ERROR: No se encontraron mutaciones G>T en posición 6\n")
  stop("No hay datos para analizar")
}

cat("\nPASO 3: Calculando VAFs por muestra\n")
cat("==========================================\n")

# Función para calcular VAF
calculate_vaf <- function(counts) {
  # Convertir a numérico
  counts <- as.numeric(counts)
  # Calcular VAF = (PM + 1MM + 2MM) / Total
  pm <- counts[1]
  mm1 <- counts[2] 
  mm2 <- counts[3]
  total <- pm + mm1 + mm2
  
  if (total == 0) return(0)
  return((pm + mm1 + mm2) / total)
}

# Aplicar función VAF a cada muestra
vaf_results <- list()

for (sample in sample_cols) {
  # Obtener columnas para esta muestra
  sample_cols_subset <- grep(paste0("^", sample, "_"), names(df_main), value = TRUE)
  
  if (length(sample_cols_subset) >= 3) {
    # Calcular VAF para cada fila
    vafs <- apply(pos6_gt[, sample_cols_subset], 1, calculate_vaf)
    vaf_results[[sample]] <- vafs
  }
}

cat(paste0("  - VAFs calculados para ", length(vaf_results), " muestras\n"))

# Crear matriz de VAFs
vaf_matrix <- do.call(cbind, vaf_results)
rownames(vaf_matrix) <- paste(pos6_gt$`miRNA name`, pos6_gt$`pos:mut`, sep = "_")

cat("  - Dimensiones de matriz VAF: ", nrow(vaf_matrix), " x ", ncol(vaf_matrix), "\n")

cat("\nPASO 4: Separando VAFs por grupo (ALS vs Control)\n")
cat("==========================================\n")

# Identificar columnas ALS y Control en la matriz
als_cols_matrix <- colnames(vaf_matrix)[str_detect(colnames(vaf_matrix), "Magen-ALS")]
control_cols_matrix <- colnames(vaf_matrix)[str_detect(colnames(vaf_matrix), "Magen-control")]

cat(paste0("  - Columnas ALS en matriz: ", length(als_cols_matrix), "\n"))
cat(paste0("  - Columnas Control en matriz: ", length(control_cols_matrix), "\n"))

# Extraer VAFs por grupo
als_vafs <- vaf_matrix[, als_cols_matrix, drop = FALSE]
control_vafs <- vaf_matrix[, control_cols_matrix, drop = FALSE]

cat("  - Dimensiones VAFs ALS: ", nrow(als_vafs), " x ", ncol(als_vafs), "\n")
cat("  - Dimensiones VAFs Control: ", nrow(control_vafs), " x ", ncol(control_vafs), "\n")

cat("\nPASO 5: Calculando estadísticas por miRNA\n")
cat("==========================================\n")

# Función para calcular estadísticas de un grupo
calc_group_stats <- function(vaf_matrix_group) {
  data.frame(
    mean_vaf = rowMeans(vaf_matrix_group, na.rm = TRUE),
    median_vaf = apply(vaf_matrix_group, 1, median, na.rm = TRUE),
    sd_vaf = apply(vaf_matrix_group, 1, sd, na.rm = TRUE),
    n_samples = rowSums(!is.na(vaf_matrix_group))
  )
}

# Calcular estadísticas para cada grupo
als_stats <- calc_group_stats(als_vafs)
control_stats <- calc_group_stats(control_vafs)

cat("  - Estadísticas ALS calculadas para ", nrow(als_stats), " miRNAs\n")
cat("  - Estadísticas Control calculadas para ", nrow(control_stats), " miRNAs\n")

# Mostrar estadísticas resumidas
cat("\n  - Resumen estadísticas ALS:\n")
print(summary(als_stats$mean_vaf))

cat("\n  - Resumen estadísticas Control:\n")
print(summary(control_stats$mean_vaf))

cat("\nPASO 6: Calculando Z-score\n")
cat("==========================================\n")

# Calcular Z-score para cada miRNA
z_scores <- (als_stats$mean_vaf - control_stats$mean_vaf) / 
  sqrt((als_stats$sd_vaf^2 / als_stats$n_samples) + (control_stats$sd_vaf^2 / control_stats$n_samples))

# Crear dataframe con resultados
results_df <- data.frame(
  mirna = rownames(als_stats),
  als_mean_vaf = als_stats$mean_vaf,
  control_mean_vaf = control_stats$mean_vaf,
  als_sd = als_stats$sd_vaf,
  control_sd = control_stats$sd_vaf,
  als_n = als_stats$n_samples,
  control_n = control_stats$n_samples,
  z_score = z_scores,
  abs_z_score = abs(z_scores)
)

# Ordenar por Z-score absoluto
results_df <- results_df[order(results_df$abs_z_score, decreasing = TRUE), ]

cat("  - Z-scores calculados para ", nrow(results_df), " miRNAs\n")
cat("  - Rango de Z-scores: ", round(min(z_scores, na.rm = TRUE), 3), " a ", round(max(z_scores, na.rm = TRUE), 3), "\n")

# Mostrar top 10 miRNAs por Z-score
cat("\n  - Top 10 miRNAs por Z-score absoluto:\n")
print(head(results_df[, c("mirna", "als_mean_vaf", "control_mean_vaf", "z_score")], 10))

cat("\nPASO 7: Análisis de significancia estadística\n")
cat("==========================================\n")

# Contar miRNAs con Z-score significativo (|z| > 1.96 para p < 0.05)
significant_mirnas <- sum(abs(z_scores) > 1.96, na.rm = TRUE)
total_mirnas <- length(z_scores)

cat(paste0("  - miRNAs con |Z-score| > 1.96: ", significant_mirnas, " de ", total_mirnas, " (", 
           round(100 * significant_mirnas / total_mirnas, 1), "%)\n"))

# Contar miRNAs con Z-score muy significativo (|z| > 2.58 para p < 0.01)
highly_significant_mirnas <- sum(abs(z_scores) > 2.58, na.rm = TRUE)
cat(paste0("  - miRNAs con |Z-score| > 2.58: ", highly_significant_mirnas, " de ", total_mirnas, " (", 
           round(100 * highly_significant_mirnas / total_mirnas, 1), "%)\n"))

# Análisis de diferencias en VAF promedio
mean_als_vaf <- mean(als_stats$mean_vaf, na.rm = TRUE)
mean_control_vaf <- mean(control_stats$mean_vaf, na.rm = TRUE)
vaf_difference <- mean_als_vaf - mean_control_vaf

cat(paste0("  - VAF promedio ALS: ", round(mean_als_vaf, 4), "\n"))
cat(paste0("  - VAF promedio Control: ", round(mean_control_vaf, 4), "\n"))
cat(paste0("  - Diferencia promedio: ", round(vaf_difference, 4), "\n"))

cat("\nPASO 8: Análisis por posición específica\n")
cat("==========================================\n")

# Verificar que todas las mutaciones son realmente posición 6
positions <- str_extract(pos6_gt$`pos:mut`, "^[0-9]+")
unique_positions <- unique(positions)
cat(paste0("  - Posiciones encontradas: ", paste(unique_positions, collapse = ", "), "\n"))

if (length(unique_positions) == 1 && unique_positions == "6") {
  cat("  - ✓ Confirmado: Todas las mutaciones son de posición 6\n")
} else {
  cat("  - ⚠ ADVERTENCIA: Se encontraron mutaciones de otras posiciones\n")
}

cat("\nPASO 9: Resumen final y conclusiones\n")
cat("==========================================\n")

cat("CONCLUSIONES:\n")
cat("1. Se encontraron ", nrow(pos6_gt), " mutaciones G>T en posición 6\n")
cat("2. Estas mutaciones afectan ", length(unique_mirnas), " miRNAs únicos\n")
cat("3. Solo ", significant_mirnas, " miRNAs (", round(100 * significant_mirnas / total_mirnas, 1), 
    "%) muestran diferencias significativas (|Z-score| > 1.96)\n")
cat("4. La diferencia promedio en VAF entre ALS y Control es ", round(vaf_difference, 4), "\n")

if (significant_mirnas < 5) {
  cat("5. ⚠ CONCLUSIÓN: La posición 6 NO muestra diferencias estadísticamente significativas\n")
  cat("   entre grupos ALS y Control en términos de mutaciones G>T\n")
} else {
  cat("5. ✓ CONCLUSIÓN: La posición 6 SÍ muestra diferencias estadísticamente significativas\n")
  cat("   entre grupos ALS y Control en términos de mutaciones G>T\n")
}

cat("\n=== FIN DEL ANÁLISIS DETALLADO ===\n")










