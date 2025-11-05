# Script para debuggear las columnas
library(dplyr)

# Cargar datos
load("oxidative_load_analysis_results.RData")

# Ver columnas de oxidative_metrics
cat("Columnas de oxidative_metrics:\n")
print(colnames(oxidative_metrics))

# Ver si existe score_normalized
if ("score_normalized" %in% colnames(oxidative_metrics)) {
  cat("\nscore_normalized encontrado en oxidative_metrics\n")
} else {
  cat("\nscore_normalized NO encontrado en oxidative_metrics\n")
}

# Ver estructura
cat("\nEstructura de oxidative_metrics:\n")
str(oxidative_metrics)









