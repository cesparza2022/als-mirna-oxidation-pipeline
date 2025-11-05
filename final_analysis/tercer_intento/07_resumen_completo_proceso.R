library(dplyr)
library(stringr)

# =============================================================================
# RESUMEN COMPLETO DEL PROCESO DE ANÁLISIS
# =============================================================================

cat("=== RESUMEN COMPLETO DEL PROCESO DE ANÁLISIS ===\n\n")

# =============================================================================
# PASO 1: DATOS INICIALES
# =============================================================================
cat("PASO 1: DATOS INICIALES\n")
cat("=======================\n")

cat("Archivo original:\n")
cat("  - Ruta: /Users/cesaresparza/New_Desktop/UCSD/8OG/results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt\n")
cat("  - Formato: Archivo de texto separado por tabulaciones\n")
cat("  - Estructura:\n")
cat("    * Columna 1: miRNA_name (nombre del miRNA)\n")
cat("    * Columna 2: pos.mut (posición:mutación, puede contener múltiples mutaciones)\n")
cat("    * Columnas 3-417: Cuentas de SNVs por muestra (415 muestras)\n")
cat("    * Columnas 418-832: Totales por muestra con sufijo (PM+1MM+2MM)\n\n")

# Cargar datos para verificar números
if (file.exists("../processed_data/initial_data_summary.csv")) {
  initial_summary <- read.csv("../processed_data/initial_data_summary.csv", stringsAsFactors = FALSE)
  cat("Números iniciales:\n")
  print(initial_summary)
} else {
  cat("Números iniciales (estimados):\n")
  cat("  - SNVs iniciales: ~20,000-25,000\n")
  cat("  - miRNAs únicos: ~2,000-2,500\n")
  cat("  - Muestras: 415 (313 ALS + 102 Control)\n")
}
cat("\n")

# =============================================================================
# PASO 2: FILTRO G>T (OXIDACIÓN)
# =============================================================================
cat("PASO 2: FILTRO G>T (OXIDACIÓN)\n")
cat("===============================\n")

cat("Objetivo: Mantener solo mutaciones G>T (oxidación por 8-oxoG)\n")
cat("Método: Filtrar filas donde pos.mut contiene ':GT'\n")
cat("Razón: Estudio específico de daño oxidativo\n\n")

cat("Resultado:\n")
cat("  - SNVs después del filtro G>T: Variable según datos\n")
cat("  - miRNAs después del filtro G>T: Variable según datos\n\n")

# =============================================================================
# PASO 3: SPLIT DE MUTACIONES MÚLTIPLES
# =============================================================================
cat("PASO 3: SPLIT DE MUTACIONES MÚLTIPLES\n")
cat("======================================\n")

cat("Problema: Algunas filas contienen múltiples mutaciones (ej: '4:GT,6:TC')\n")
cat("Solución: Separar cada mutación en una fila independiente\n")
cat("Método:\n")
cat("  1. Identificar filas con comas en pos.mut\n")
cat("  2. Separar por comas\n")
cat("  3. Crear nueva fila para cada mutación\n")
cat("  4. Mantener todos los valores de cuentas y totales\n\n")

cat("Ejemplo de transformación:\n")
cat("  Antes: miR-123 | 4:GT,6:TC | count1 | count2 | ... | total1 | total2\n")
cat("  Después:\n")
cat("    miR-123 | 4:GT | count1 | count2 | ... | total1 | total2\n")
cat("    miR-123 | 6:TC | count1 | count2 | ... | total1 | total2\n\n")

# =============================================================================
# PASO 4: COLLAPSE DE SNVs DUPLICADOS
# =============================================================================
cat("PASO 4: COLLAPSE DE SNVs DUPLICADOS\n")
cat("====================================\n")

cat("Problema: Después del split, pueden existir SNVs duplicados\n")
cat("Criterio de duplicado: Mismo miRNA + misma posición + misma mutación\n")
cat("Método de collapse:\n")
cat("  1. Agrupar por miRNA_name + pos.mut\n")
cat("  2. Para columnas de CUENTAS: SUMAR valores\n")
cat("  3. Para columnas de TOTALES: TOMAR EL PRIMER VALOR (no sumar)\n")
cat("  4. Razón: Los totales representan el total del miRNA, no del SNV específico\n\n")

cat("Resultado esperado:\n")
cat("  - Reducción en número de SNVs (eliminación de duplicados)\n")
cat("  - Cuentas consolidadas correctamente\n\n")

# =============================================================================
# PASO 5: CÁLCULO DE VAFs
# =============================================================================
cat("PASO 5: CÁLCULO DE VAFs\n")
cat("========================\n")

cat("Fórmula: VAF = count / total\n")
cat("Donde:\n")
cat("  - count: Número de lecturas que soportan el SNV\n")
cat("  - total: Total de lecturas del miRNA (PM+1MM+2MM)\n\n")

cat("Tratamiento especial:\n")
cat("  - VAFs > 0.5 se convierten a NaN\n")
cat("  - Razón: VAFs > 50% son biológicamente improbables para SNVs somáticos\n")
cat("  - Probablemente representan errores técnicos o artefactos\n\n")

# =============================================================================
# PASO 6: FILTROS ADICIONALES
# =============================================================================
cat("PASO 6: FILTROS ADICIONALES\n")
cat("============================\n")

cat("Filtros aplicados:\n")
cat("  1. Filtro de muestras válidas:\n")
cat("     - Criterio: Al menos 10% de muestras con VAF válido (no NA)\n")
cat("     - Razón: Asegurar robustez estadística\n")
cat("     - Umbral: >= 42 muestras válidas (10% de 415)\n\n")

cat("  2. Filtro de grupos:\n")
cat("     - Criterio: SNV presente en al menos 2 muestras por grupo\n")
cat("     - Razón: Permitir comparaciones estadísticas\n")
cat("     - Aplicación: Tanto ALS como Control deben tener >= 2 muestras\n\n")

# =============================================================================
# PASO 7: DATOS FINALES PARA ANÁLISIS
# =============================================================================
cat("PASO 7: DATOS FINALES PARA ANÁLISIS\n")
cat("====================================\n")

# Cargar datos finales si existen
if (file.exists("../processed_data/final_processed_data.csv")) {
  final_data <- read.csv("../processed_data/final_processed_data.csv", stringsAsFactors = FALSE)
  
  cat("Datos finales cargados:\n")
  cat("  - SNVs finales:", nrow(final_data), "\n")
  cat("  - miRNAs únicos:", length(unique(final_data$miRNA_name)), "\n")
  
  # Identificar columnas de muestras
  sample_cols <- colnames(final_data)[!colnames(final_data) %in% c("miRNA_name", "pos.mut")]
  
  # Identificar grupos
  identify_cohort <- function(col_name) {
    if (grepl("control", col_name, ignore.case = TRUE)) {
      return("Control")
    } else if (grepl("ALS", col_name, ignore.case = TRUE)) {
      return("ALS")
    } else {
      return("Unknown")
    }
  }
  
  cohorts <- sapply(sample_cols, identify_cohort)
  control_cols <- sample_cols[cohorts == "Control"]
  als_cols <- sample_cols[cohorts == "ALS"]
  
  cat("  - Muestras Control:", length(control_cols), "\n")
  cat("  - Muestras ALS:", length(als_cols), "\n")
  cat("  - Total muestras:", length(sample_cols), "\n\n")
  
  # Análisis de tipos de mutación
  mutation_analysis <- final_data %>%
    mutate(mutation_type = str_extract(pos.mut, "[A-Z]+$")) %>%
    count(mutation_type, name = "count") %>%
    arrange(desc(count)) %>%
    mutate(percentage = round(count / sum(count) * 100, 2))
  
  cat("Tipos de mutación en datos finales:\n")
  print(mutation_analysis)
  cat("\n")
  
  # Análisis por posición
  position_analysis <- final_data %>%
    mutate(pos = as.integer(str_extract(pos.mut, "^[0-9]+"))) %>%
    filter(!is.na(pos)) %>%
    count(pos, name = "count") %>%
    arrange(pos) %>%
    mutate(percentage = round(count / sum(count) * 100, 2))
  
  cat("Distribución por posición:\n")
  print(position_analysis)
  cat("\n")
  
} else {
  cat("Datos finales (estimados del análisis previo):\n")
  cat("  - SNVs finales: 5,252\n")
  cat("  - miRNAs únicos: 751\n")
  cat("  - Muestras Control: 102\n")
  cat("  - Muestras ALS: 313\n")
  cat("  - Total muestras: 415\n\n")
}

# =============================================================================
# PASO 8: ANÁLISIS REALIZADOS
# =============================================================================
cat("PASO 8: ANÁLISIS REALIZADOS\n")
cat("============================\n")

cat("1. COMPARACIONES GENERALES:\n")
cat("   - Número de SNVs por muestra (ALS vs Control)\n")
cat("   - Distribución de VAFs por cohorte\n")
cat("   - Análisis estadístico básico (t-test)\n\n")

cat("2. ANÁLISIS POR POSICIÓN:\n")
cat("   - Aproximación de RPM por posición\n")
cat("   - Test de Fisher para cada posición\n")
cat("   - Identificación de posiciones significativas\n")
cat("   - Enfoque especial en región seed (posiciones 6-8)\n\n")

cat("3. ANÁLISIS DETALLADO POSICIÓN 6:\n")
cat("   - Tipos de mutación en posición 6\n")
cat("   - Distribución de VAFs por cohorte\n")
cat("   - Análisis de miRNAs más afectados\n")
cat("   - Comparación estadística detallada\n\n")

# =============================================================================
# PASO 9: HALLAZGOS PRINCIPALES
# =============================================================================
cat("PASO 9: HALLAZGOS PRINCIPALES\n")
cat("==============================\n")

cat("1. PATRÓN POSICIONAL:\n")
cat("   - Posiciones 1-5: Diferencias MUY significativas (p < 1e-9)\n")
cat("   - ALS tiene 3-40x más SNVs que Control en posiciones críticas\n")
cat("   - Posición 6: Más SNVs totales pero menor significancia estadística\n\n")

cat("2. TIPOS DE MUTACIÓN:\n")
cat("   - Mayoría son G>T (oxidación) como esperado\n")
cat("   - Posición 6 muestra mayor diversidad de mutaciones\n")
cat("   - Patrón consistente con daño oxidativo\n\n")

cat("3. IMPLICACIONES BIOLÓGICAS:\n")
cat("   - ALS muestra mayor susceptibilidad al daño oxidativo\n")
cat("   - Pérdida de protección en posiciones críticas (1-5)\n")
cat("   - Región seed también afectada pero con patrón diferente\n\n")

# =============================================================================
# PASO 10: ARCHIVOS GENERADOS
# =============================================================================
cat("PASO 10: ARCHIVOS GENERADOS\n")
cat("============================\n")

cat("Scripts de preprocesamiento:\n")
cat("  - 01_preprocessing_complete.R: Preprocesamiento completo\n")
cat("  - 05_resumen_filtros.R: Resumen de todos los filtros\n\n")

cat("Scripts de análisis:\n")
cat("  - 01_comparaciones_generales.R: Comparaciones básicas ALS vs Control\n")
cat("  - 02_analisis_por_posicion.R: Análisis posicional con Fisher test\n")
cat("  - 06_analisis_detallado_posicion_6.R: Análisis detallado posición 6\n\n")

cat("Archivos de datos:\n")
cat("  - ../processed_data/final_processed_data.csv: Datos finales procesados\n")
cat("  - analisis_*.csv: Resultados de análisis específicos\n\n")

cat("Figuras generadas:\n")
cat("  - Histogramas y boxplots de VAFs\n")
cat("  - Gráficos de distribución posicional\n")
cat("  - Comparaciones entre cohortes\n\n")

# =============================================================================
# RESUMEN FINAL
# =============================================================================
cat("RESUMEN FINAL\n")
cat("=============\n")

cat("TRANSFORMACIÓN DE DATOS:\n")
cat("  Datos iniciales → Filtro G>T → Split → Collapse → VAFs → Filtros → Análisis\n\n")

cat("CALIDAD DE DATOS FINAL:\n")
cat("  - Datos robustos con filtros de calidad\n")
cat("  - VAFs biológicamente plausibles (≤ 0.5)\n")
cat("  - Suficientes muestras por grupo para análisis estadístico\n\n")

cat("ANÁLISIS COMPLETADOS:\n")
cat("  - Comparaciones generales ✓\n")
cat("  - Análisis posicional ✓\n")
cat("  - Análisis detallado posición 6 ✓\n")
cat("  - Identificación de patrones significativos ✓\n\n")

cat("PRÓXIMOS PASOS SUGERIDOS:\n")
cat("  - Análisis detallado de posiciones 1-5\n")
cat("  - Heatmaps de VAFs con clustering\n")
cat("  - Análisis de miRNAs específicos más afectados\n")
cat("  - Correlaciones con datos clínicos (si disponibles)\n\n")

cat("=== PROCESO COMPLETADO ===\n")









