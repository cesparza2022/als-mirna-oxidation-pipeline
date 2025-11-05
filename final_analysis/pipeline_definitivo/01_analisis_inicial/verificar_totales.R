# Verificar qué pasa con las columnas de totales en el split-collapse
library(tidyverse)

# Cargar configuración
source("../config_pipeline.R")

# Cargar datos
raw_data <- read_tsv(config$data_paths$raw_data, 
                     col_types = cols(.default = "c"))

cat("=== VERIFICACIÓN DE COLUMNAS DE TOTALES ===\n")

# Identificar columnas de totales
total_cols <- names(raw_data)[grepl("(PM\\+1MM\\+2MM|\\.\\.PM\\.1MM\\.2MM\\.)$", names(raw_data))]

cat("Columnas de totales encontradas:", length(total_cols), "\n")
if (length(total_cols) > 0) {
  cat("Primeras 5 columnas de totales:\n")
  print(head(total_cols, 5))
} else {
  cat("NO se encontraron columnas de totales con el patrón esperado\n")
  cat("Buscando otros patrones...\n")
  
  # Buscar otros patrones posibles
  possible_totals <- names(raw_data)[grepl("(total|Total|TOTAL|PM|MM)", names(raw_data))]
  cat("Columnas que podrían ser totales:\n")
  print(possible_totals)
}

cat("\n=== ESTRUCTURA COMPLETA DEL DATASET ===\n")
cat("Total de columnas:", ncol(raw_data), "\n")
cat("Primeras 10 columnas:\n")
print(head(names(raw_data), 10))
cat("Últimas 10 columnas:\n")
print(tail(names(raw_data), 10))

# Verificar si hay columnas que contengan "PM" o "MM"
pm_cols <- names(raw_data)[grepl("PM|MM", names(raw_data))]
cat("\nColumnas que contienen 'PM' o 'MM':", length(pm_cols), "\n")
if (length(pm_cols) > 0) {
  print(head(pm_cols, 10))
}

# Verificar valores en las primeras filas
cat("\n=== VALORES EN LAS PRIMERAS FILAS ===\n")
cat("Primeras 3 filas, primeras 10 columnas:\n")
print(raw_data[1:3, 1:10])

# Buscar valores no numéricos en columnas que deberían ser numéricas
cat("\n=== VERIFICACIÓN DE VALORES NO NUMÉRICOS ===\n")
sample_cols <- names(raw_data)[3:12]  # Primeras 10 columnas de datos
for (col in sample_cols) {
  non_numeric <- raw_data[[col]][!grepl("^[0-9]+\\.?[0-9]*$", raw_data[[col]])]
  if (length(non_numeric) > 0) {
    cat("Columna", col, "tiene valores no numéricos:\n")
    print(unique(non_numeric)[1:5])
  }
}








