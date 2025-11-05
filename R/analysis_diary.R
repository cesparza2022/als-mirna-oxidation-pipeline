#' Análisis Diario - Mutaciones G>T en miRNAs
#' 
#' Este script mantiene un diario estructurado del análisis,
#' documentando hallazgos, metodologías y referencias bibliográficas.

library(dplyr)
library(ggplot2)
library(stringr)
library(tidyr)
library(readr)
library(yaml)

# Crear estructura del diario
create_analysis_diary <- function() {
  diary_content <- paste0(
    "# DIARIO DE ANÁLISIS - Mutaciones G>T en miRNAs\n\n",
    "## Fecha: ", Sys.Date(), "\n\n",
    "## OBJETIVO\n",
    "Analizar mutaciones G>T (oxidación) en miRNAs de pacientes con ALS vs controles,\n",
    "con enfoque en región semilla y conservación.\n\n",
    "## ESTRUCTURA DEL DATASET\n",
    "- **Total de muestras**: ~400 (no 800 como pensé inicialmente)\n",
    "- **Columnas SNV**: Cuentas de mutaciones específicas\n",
    "- **Columnas TOTAL**: Cuentas totales del miRNA (PM+1MM+2MM)\n",
    "- **Filtrado VAF**: Quitar SNVs que superan 50% de VAF\n\n",
    "## METODOLOGÍA\n",
    "1. **Normalización RPM**: Reads Per Million\n",
    "2. **Análisis posicional**: Comparar posición por posición\n",
    "3. **Región semilla**: Posiciones 2-8 del miRNA\n",
    "4. **Pruebas estadísticas**: T-test, Wilcoxon por posición\n\n",
    "## HALLAZGOS PRINCIPALES\n",
    "### Análisis Global\n",
    "- **No hay diferencias significativas** entre ALS y Control en mutaciones G>T totales\n",
    "- **Tamaño del efecto pequeño** (Cohen's d = 0.0571)\n",
    "- **ALS**: 0.147 ± 0.131 (tasa normalizada)\n",
    "- **Control**: 0.145 ± 0.131 (tasa normalizada)\n\n",
    "### Análisis Posicional (Pendiente)\n",
    "- Necesitamos implementar análisis por posición específica\n",
    "- Enfoque en región semilla (posiciones 2-8)\n",
    "- Identificar hotspots de mutación\n\n",
    "## REFERENCIAS BIBLIOGRÁFICAS\n",
    "### Papers sobre mutaciones G>T en miRNAs\n",
    "1. **Trabajos sobre oxidación en miRNAs**\n",
    "2. **Estudios de conservación de secuencias**\n",
    "3. **Impacto funcional de mutaciones en región semilla**\n\n",
    "## PRÓXIMOS PASOS\n",
    "1. Implementar análisis posicional correcto\n",
    "2. Investigar literatura sobre conservación\n",
    "3. Analizar clusters de miRNAs similares\n",
    "4. Identificar posiciones críticas\n\n",
    "---\n",
    "*Diario actualizado el: ", Sys.time(), "*\n"
  )
  
  # Guardar diario
  writeLines(diary_content, "outputs/analysis_diary.md")
  cat("✅ Diario creado en: outputs/analysis_diary.md\n")
  
  return(diary_content)
}

# Ejecutar creación del diario
diary_content <- create_analysis_diary()











