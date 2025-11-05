# Buscar un ejemplo con múltiples mutaciones para verificar
library(tidyverse)

# Cargar configuración
source("../config_pipeline.R")

# Cargar datos
raw_data <- read_tsv(config$data_paths$raw_data, 
                     col_types = cols(.default = "c"))

cat("=== BUSCANDO EJEMPLO CON MÚLTIPLES MUTACIONES ===\n")

# Buscar filas con múltiples mutaciones
multiple_mutations <- raw_data[grepl(",", raw_data$`pos:mut`), ]

cat("Total de filas con múltiples mutaciones:", nrow(multiple_mutations), "\n")

if (nrow(multiple_mutations) > 0) {
  # Tomar el primer ejemplo
  example <- multiple_mutations[1, ]
  
  cat("\n=== EJEMPLO ENCONTRADO ===\n")
  cat("miRNA:", example$`miRNA name`, "\n")
  cat("Posición/mutación:", example$`pos:mut`, "\n")
  
  # Identificar columnas
  total_cols <- names(raw_data)[grepl("\\(PM\\+1MM\\+2MM\\)$", names(raw_data))]
  count_cols <- names(raw_data)[!names(raw_data) %in% c("miRNA name", "pos:mut") & 
                                !names(raw_data) %in% total_cols]
  
  # Mostrar algunas columnas de ejemplo
  cat("\nPrimeras 3 columnas de cuentas y totales:\n")
  print(example[, c("miRNA name", "pos:mut", count_cols[1:3], total_cols[1:3])])
  
  # Aplicar split
  cat("\n=== APLICANDO SPLIT ===\n")
  split_example <- example %>%
    separate_rows(`pos:mut`, sep = ",") %>%
    mutate(`pos:mut` = str_trim(`pos:mut`))
  
  cat("Después del split:\n")
  print(split_example[, c("miRNA name", "pos:mut", count_cols[1:3], total_cols[1:3])])
  
  # Verificar totales
  cat("\n=== VERIFICACIÓN DE TOTALES ===\n")
  original_totals <- as.numeric(example[1, total_cols[1:3]])
  split_totals_1 <- as.numeric(split_example[1, total_cols[1:3]])
  split_totals_2 <- as.numeric(split_example[2, total_cols[1:3]])
  
  cat("Totales originales:", paste(original_totals, collapse = ", "), "\n")
  cat("Totales después del split (fila 1):", paste(split_totals_1, collapse = ", "), "\n")
  cat("Totales después del split (fila 2):", paste(split_totals_2, collapse = ", "), "\n")
  
  cat("¿Totales se mantienen igual? (fila 1):", all(original_totals == split_totals_1), "\n")
  cat("¿Totales se mantienen igual? (fila 2):", all(original_totals == split_totals_2), "\n")
  
  # Verificar cuentas
  cat("\n=== VERIFICACIÓN DE CUENTAS ===\n")
  original_counts <- as.numeric(example[1, count_cols[1:3]])
  split_counts_1 <- as.numeric(split_example[1, count_cols[1:3]])
  split_counts_2 <- as.numeric(split_example[2, count_cols[1:3]])
  
  cat("Cuentas originales:", paste(original_counts, collapse = ", "), "\n")
  cat("Cuentas después del split (fila 1):", paste(split_counts_1, collapse = ", "), "\n")
  cat("Cuentas después del split (fila 2):", paste(split_counts_2, collapse = ", "), "\n")
  
  cat("¿Cuentas se mantienen igual? (fila 1):", all(original_counts == split_counts_1), "\n")
  cat("¿Cuentas se mantienen igual? (fila 2):", all(original_counts == split_counts_2), "\n")
  
} else {
  cat("No se encontraron filas con múltiples mutaciones\n")
}








