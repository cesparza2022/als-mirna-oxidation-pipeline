#!/usr/bin/env Rscript

# =============================================================================
# ANÁLISIS DETALLADO PASO A PASO - POSICIÓN 6 (CORREGIDO)
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

# Identificar columnas (todas excepto miRNA name y pos:mut)
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

cat("\nPASO 3: Analizando estructura de columnas\n")
cat("==========================================\n")

# Verificar estructura de las primeras columnas de muestra
first_sample_cols <- head(sample_cols, 3)
cat("  - Primeras 3 columnas de muestra:\n")
for (col in first_sample_cols) {
  cat(paste0("    - ", col, "\n"))
}

# Verificar si hay columnas PM, 1MM, 2MM para cada muestra
sample_base <- "Magen-ALS-enrolment-bloodplasma-SRR13934430"
pm_col <- paste0(sample_base, "_PM")
mm1_col <- paste0(sample_base, "_1MM") 
mm2_col <- paste0(sample_base, "_2MM")

cat(paste0("  - Columna PM: ", pm_col, " - Existe: ", pm_col %in% names(df_main), "\n"))
cat(paste0("  - Columna 1MM: ", mm1_col, " - Existe: ", mm1_col %in% names(df_main), "\n"))
cat(paste0("  - Columna 2MM: ", mm2_col, " - Existe: ", mm2_col %in% names(df_main), "\n"))

# Verificar estructura real de columnas
cat("\n  - Estructura real de columnas (primeras 10):\n")
print(head(names(df_main), 10))

cat("\nPASO 4: Calculando VAFs correctamente\n")
cat("==========================================\n")

# Función para calcular VAF de una fila
calculate_vaf_row <- function(row_data, sample_name) {
  pm_col <- paste0(sample_name, "_PM")
  mm1_col <- paste0(sample_name, "_1MM")
  mm2_col <- paste0(sample_name, "_2MM")
  
  if (all(c(pm_col, mm1_col, mm2_col) %in% names(row_data))) {
    pm <- as.numeric(row_data[[pm_col]])
    mm1 <- as.numeric(row_data[[mm1_col]])
    mm2 <- as.numeric(row_data[[mm2_col]])
    total <- pm + mm1 + mm2
    
    if (total == 0) return(0)
    return((pm + mm1 + mm2) / total)
  } else {
    return(NA)
  }
}

# Calcular VAFs para cada muestra
vaf_results <- list()
samples_processed <- 0

for (sample in sample_cols) {
  # Verificar que existen las columnas PM, 1MM, 2MM para esta muestra
  pm_col <- paste0(sample, "_PM")
  mm1_col <- paste0(sample, "_1MM")
  mm2_col <- paste0(sample, "_2MM")
  
  if (all(c(pm_col, mm1_col, mm2_col) %in% names(df_main))) {
    vafs <- apply(pos6_gt, 1, function(row) calculate_vaf_row(row, sample))
    vaf_results[[sample]] <- vafs
    samples_processed <- samples_processed + 1
  }
}

cat(paste0("  - VAFs calculados para ", samples_processed, " muestras\n"))

if (samples_processed == 0) {
  cat("  - ERROR: No se pudieron calcular VAFs para ninguna muestra\n")
  cat("  - Verificando estructura de columnas...\n")
  
  # Mostrar algunas columnas para debug
  cat("  - Columnas que contienen 'PM':\n")
  pm_cols <- names(df_main)[str_detect(names(df_main), "_PM$")]
  print(head(pm_cols, 5))
  
  cat("  - Columnas que contienen '1MM':\n")
  mm1_cols <- names(df_main)[str_detect(names(df_main), "_1MM$")]
  print(head(mm1_cols, 5))
  
  stop("No se encontraron columnas PM/1MM/2MM")
}

cat("\nPASO 5: Creando matriz de VAFs\n")
cat("==========================================\n")

# Crear matriz de VAFs
vaf_matrix <- do.call(cbind, vaf_results)
rownames(vaf_matrix) <- paste(pos6_gt$`miRNA name`, pos6_gt$`pos:mut`, sep = "_")

cat("  - Dimensiones de matriz VAF: ", nrow(vaf_matrix), " x ", ncol(vaf_matrix), "\n")

# Mostrar estadísticas de la matriz
cat("  - Estadísticas de VAFs:\n")
cat(paste0("    - Mínimo: ", round(min(vaf_matrix, na.rm = TRUE), 4), "\n"))
cat(paste0("    - Máximo: ", round(max(vaf_matrix, na.rm = TRUE), 4), "\n"))
cat(paste0("    - Promedio: ", round(mean(vaf_matrix, na.rm = TRUE), 4), "\n"))
cat(paste0("    - Valores NA: ", sum(is.na(vaf_matrix)), "\n"))

cat("\nPASO 6: Separando por grupos ALS vs Control\n")
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

cat("\nPASO 7: Calculando estadísticas por miRNA\n")
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

cat("\nPASO 8: Calculando Z-score\n")
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

cat("\nPASO 9: Análisis de significancia estadística\n")
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

cat("\nPASO 10: Resumen final y conclusiones\n")
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










