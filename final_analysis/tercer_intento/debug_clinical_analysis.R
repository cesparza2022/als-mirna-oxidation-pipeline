# Script para debuggear el análisis clínico
library(dplyr)

# Cargar datos
load("oxidative_load_analysis_results.RData")

# Ver qué hay en oxidative_metrics
cat("Estructura de oxidative_metrics:\n")
str(oxidative_metrics)
cat("\nPrimeras filas:\n")
head(oxidative_metrics)

# Ver nombres de columnas
cat("\nNombres de columnas:\n")
colnames(oxidative_metrics)

# Ver si hay columna sample_id
if ("sample_id" %in% colnames(oxidative_metrics)) {
  cat("\nColumna sample_id encontrada\n")
  cat("Primeros sample_ids:\n")
  head(oxidative_metrics$sample_id)
} else {
  cat("\nColumna sample_id NO encontrada\n")
  cat("Columnas disponibles:\n")
  print(colnames(oxidative_metrics))
}









