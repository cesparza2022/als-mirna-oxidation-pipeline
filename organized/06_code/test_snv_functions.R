#!/usr/bin/env Rscript

# =============================================================================
# SCRIPT DE PRUEBA PARA FUNCIONES DE PROCESAMIENTO DE SNVs
# =============================================================================
# 
# Este script prueba las funciones de procesamiento de SNVs
# para verificar que funcionen correctamente
#
# Autor: Análisis 8OG
# Fecha: 2025-01-23
# =============================================================================

# Cargar funciones
source("R/snv_processing_functions.R")

# Cargar datos
cat("📁 Cargando datos...\n")
df <- read.delim('/Users/cesaresparza/New_Desktop/UCSD/8OG/results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt', 
                 sep = '\t', header = TRUE)

# Identificar columnas
meta_cols <- c('miRNA name', 'pos:mut')
# Las columnas 3-417 son de conteos de SNVs (400 muestras)
snv_cols <- names(df)[3:417]
# Las columnas 418-832 son de totales (400 muestras con sufijo PM+1MM+2MM)
total_cols <- names(df)[418:832]

cat("📊 Estructura del dataset:\n")
cat("   📋 Filas:", nrow(df), "\n")
cat("   📋 Columnas SNV:", length(snv_cols), "\n")
cat("   📋 Columnas totales:", length(total_cols), "\n")
cat("   📋 miRNAs únicos:", length(unique(df$`miRNA name`)), "\n\n")

# Verificar estructura de pos:mut
cat("🔍 Analizando estructura de pos:mut...\n")
pos_mut_values <- unique(df$`pos:mut`)
cat("   📊 Valores únicos en pos:mut:", length(pos_mut_values), "\n")

# Contar tipos de mutaciones
pm_count <- sum(df$`pos:mut` == "PM")
single_snv_count <- sum(str_detect(df$`pos:mut`, "^[0-9]+:[A-Z]{2}$"))
multiple_snv_count <- sum(str_detect(df$`pos:mut`, ","))

cat("   📊 PM (Perfect Match):", pm_count, "\n")
cat("   📊 SNVs simples:", single_snv_count, "\n")
cat("   📊 SNVs múltiples:", multiple_snv_count, "\n\n")

# Mostrar ejemplos de SNVs múltiples
if (multiple_snv_count > 0) {
  cat("📋 Ejemplos de SNVs múltiples:\n")
  examples <- df %>%
    filter(str_detect(`pos:mut`, ",")) %>%
    select(`miRNA name`, `pos:mut`) %>%
    head(5)
  print(examples)
  cat("\n")
}

# Probar función de separación
cat("🧪 Probando función de separación de SNVs múltiples...\n")
df_separated <- separate_multiple_snvs(df, snv_cols, total_cols)

# Verificar que se separaron correctamente
cat("   📊 Filas después de separar:", nrow(df_separated), "\n")
cat("   📊 Incremento de filas:", nrow(df_separated) - nrow(df), "\n\n")

# Probar función de suma
cat("🧪 Probando función de suma de conteos...\n")
df_summed <- sum_snv_counts_by_mirna(df_separated, snv_cols, total_cols)

# Verificar que se sumaron correctamente
cat("   📊 miRNAs después de sumar:", nrow(df_summed), "\n")
cat("   📊 Reducción de filas:", nrow(df_separated) - nrow(df_summed), "\n\n")

# Verificar integridad
cat("🔍 Verificando integridad de datos...\n")
stats <- verify_data_integrity(df, df_summed, snv_cols, total_cols)

# Probar análisis completo
cat("🧪 Probando análisis completo...\n")
results <- complete_analysis(df, snv_cols, total_cols, rpm_threshold = 1, vaf_threshold = 0.5)

if (!is.null(results)) {
  cat("   📊 Resultados del análisis:\n")
  cat("      - miRNAs procesados:", results$stats$total_mirnas, "\n")
  cat("      - miRNAs con G>T en región semilla:", results$stats$gt_seed_mirnas, "\n")
  cat("      - miRNAs después de filtros:", results$stats$filtered_mirnas, "\n\n")
  
  # Mostrar top miRNAs
  if (nrow(results$summary_data) > 0) {
    cat("📋 Top 10 miRNAs por conteos G>T:\n")
    top_mirnas <- results$summary_data %>%
      select(`miRNA name`, `pos:mut`, total_gt_counts, mean_rpm, mean_vaf) %>%
      head(10)
    print(top_mirnas)
  }
} else {
  cat("   ⚠️  No se pudieron obtener resultados del análisis\n")
}

cat("\n✅ Pruebas completadas\n")
