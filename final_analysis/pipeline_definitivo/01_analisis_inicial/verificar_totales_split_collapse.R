# Verificar específicamente qué pasa con las columnas de totales en split-collapse
library(tidyverse)

# Cargar configuración
source("../config_pipeline.R")

# Cargar datos
raw_data <- read_tsv(config$data_paths$raw_data, 
                     col_types = cols(.default = "c"))

cat("=== VERIFICACIÓN ESPECÍFICA DE TOTALES EN SPLIT-COLLAPSE ===\n")

# Identificar columnas de totales (las que terminan en (PM+1MM+2MM))
total_cols <- names(raw_data)[grepl("\\(PM\\+1MM\\+2MM\\)$", names(raw_data))]
count_cols <- names(raw_data)[!names(raw_data) %in% c("miRNA name", "pos:mut") & 
                              !names(raw_data) %in% total_cols]

cat("Columnas de totales:", length(total_cols), "\n")
cat("Columnas de cuentas:", length(count_cols), "\n")

# Tomar un ejemplo específico para verificar
example_mirna <- "hsa-let-7a-2-3p"
example_data <- raw_data[raw_data$`miRNA name` == example_mirna, ]

cat("\n=== EJEMPLO ESPECÍFICO: miRNA", example_mirna, "===\n")
cat("Filas originales:", nrow(example_data), "\n")

# Mostrar las primeras filas del ejemplo
cat("\nFilas originales:\n")
print(example_data[, c("miRNA name", "pos:mut", count_cols[1:3], total_cols[1:3])])

# Buscar filas con múltiples mutaciones
multiple_mut <- example_data[grepl(",", example_data$`pos:mut`), ]
cat("\nFilas con múltiples mutaciones:", nrow(multiple_mut), "\n")

if (nrow(multiple_mut) > 0) {
  cat("Ejemplo de fila con múltiples mutaciones:\n")
  print(multiple_mut[1, c("miRNA name", "pos:mut", count_cols[1:3], total_cols[1:3])])
  
  # Aplicar split
  cat("\n=== APLICANDO SPLIT ===\n")
  split_example <- multiple_mut[1, ] %>%
    separate_rows(`pos:mut`, sep = ",") %>%
    mutate(`pos:mut` = str_trim(`pos:mut`))
  
  cat("Después del split:\n")
  print(split_example[, c("miRNA name", "pos:mut", count_cols[1:3], total_cols[1:3])])
  
  # Verificar que los totales se mantienen igual
  cat("\n=== VERIFICACIÓN DE TOTALES ===\n")
  original_totals <- as.numeric(multiple_mut[1, total_cols[1:3]])
  split_totals_1 <- as.numeric(split_example[1, total_cols[1:3]])
  split_totals_2 <- as.numeric(split_example[2, total_cols[1:3]])
  
  cat("Totales originales:", paste(original_totals, collapse = ", "), "\n")
  cat("Totales después del split (fila 1):", paste(split_totals_1, collapse = ", "), "\n")
  cat("Totales después del split (fila 2):", paste(split_totals_2, collapse = ", "), "\n")
  
  # Verificar si son iguales
  cat("¿Totales se mantienen igual? (fila 1):", all(original_totals == split_totals_1), "\n")
  cat("¿Totales se mantienen igual? (fila 2):", all(original_totals == split_totals_2), "\n")
}

# Ahora verificar el collapse
cat("\n=== VERIFICACIÓN DEL COLLAPSE ===\n")

# Buscar duplicados después del split
all_split <- raw_data %>%
  separate_rows(`pos:mut`, sep = ",") %>%
  mutate(`pos:mut` = str_trim(`pos:mut`))

# Buscar duplicados en el ejemplo
example_split <- all_split[all_split$`miRNA name` == example_mirna, ]
duplicates <- example_split %>%
  group_by(`miRNA name`, `pos:mut`) %>%
  summarise(n = n(), .groups = "drop") %>%
  filter(n > 1)

cat("Duplicados encontrados en", example_mirna, ":", nrow(duplicates), "\n")

if (nrow(duplicates) > 0) {
  # Tomar el primer duplicado
  dup_example <- duplicates[1, ]
  dup_rows <- example_split[example_split$`miRNA name` == dup_example$`miRNA name` & 
                           example_split$`pos:mut` == dup_example$`pos:mut`, ]
  
  cat("\nEjemplo de duplicado:\n")
  cat("miRNA:", dup_example$`miRNA name`, "\n")
  cat("Posición:", dup_example$`pos:mut`, "\n")
  cat("Número de filas duplicadas:", nrow(dup_rows), "\n")
  
  cat("\nFilas duplicadas (primeras 3 columnas de cuentas y totales):\n")
  print(dup_rows[, c("miRNA name", "pos:mut", count_cols[1:3], total_cols[1:3])])
  
  # Aplicar collapse
  cat("\n=== APLICANDO COLLAPSE ===\n")
  collapsed_example <- dup_rows %>%
    group_by(`miRNA name`, `pos:mut`) %>%
    summarise(
      across(all_of(count_cols), ~sum(as.numeric(.x), na.rm = TRUE)),
      across(all_of(total_cols), ~first(.x)),  # Mantener el primer total
      .groups = "drop"
    )
  
  cat("Después del collapse:\n")
  print(collapsed_example[, c("miRNA name", "pos:mut", count_cols[1:3], total_cols[1:3])])
  
  # Verificar totales
  original_totals_dup <- as.numeric(dup_rows[1, total_cols[1:3]])
  collapsed_totals <- as.numeric(collapsed_example[1, total_cols[1:3]])
  
  cat("\nTotales originales (primera fila duplicada):", paste(original_totals_dup, collapse = ", "), "\n")
  cat("Totales después del collapse:", paste(collapsed_totals, collapse = ", "), "\n")
  cat("¿Totales se mantienen igual?:", all(original_totals_dup == collapsed_totals), "\n")
  
  # Verificar cuentas
  original_counts_1 <- as.numeric(dup_rows[1, count_cols[1:3]])
  original_counts_2 <- as.numeric(dup_rows[2, count_cols[1:3]])
  collapsed_counts <- as.numeric(collapsed_example[1, count_cols[1:3]])
  expected_counts <- original_counts_1 + original_counts_2
  
  cat("\nCuentas originales (fila 1):", paste(original_counts_1, collapse = ", "), "\n")
  cat("Cuentas originales (fila 2):", paste(original_counts_2, collapse = ", "), "\n")
  cat("Cuentas esperadas (suma):", paste(expected_counts, collapse = ", "), "\n")
  cat("Cuentas después del collapse:", paste(collapsed_counts, collapse = ", "), "\n")
  cat("¿Cuentas se suman correctamente?:", all(expected_counts == collapsed_counts), "\n")
}








