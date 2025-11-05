# =============================================================================
# DEMOSTRACIÓN DEL SPLIT-COLLAPSE
# =============================================================================
# Autor: César Esparza
# Fecha: 2024
# Descripción: Demostración paso a paso del proceso split-collapse
# =============================================================================

# Cargar librerías
library(tidyverse)
library(dplyr)
library(stringr)

# Cargar configuración y funciones
source("../config_pipeline.R")
source("functions_pipeline.R")

cat("=== DEMOSTRACIÓN DEL SPLIT-COLLAPSE ===\n")
cat("Fecha:", Sys.time(), "\n\n")

# =============================================================================
# PASO 1: CARGAR DATOS ORIGINALES
# =============================================================================

cat("PASO 1: Cargando datos originales...\n")
raw_data <- read_tsv(config$data_paths$raw_data, 
                     col_types = cols(.default = "c"))

cat("Datos originales cargados:\n")
cat("  - Filas (SNVs):", nrow(raw_data), "\n")
cat("  - Columnas:", ncol(raw_data), "\n")
cat("  - miRNAs únicos:", length(unique(raw_data$`miRNA name`)), "\n\n")

# Mostrar ejemplos de datos originales
cat("EJEMPLOS DE DATOS ORIGINALES:\n")
cat("Primeras 3 filas:\n")
print(head(raw_data[,1:6], 3))
cat("\n")

# =============================================================================
# PASO 2: IDENTIFICAR ESTRUCTURA DEL DATASET
# =============================================================================

cat("PASO 2: Identificando estructura del dataset...\n")

# Identificar tipos de columnas (nombres reales del dataset)
meta_cols <- c("miRNA name", "pos:mut")
count_cols <- names(raw_data)[!names(raw_data) %in% meta_cols]
total_cols <- c()  # Este dataset no tiene columnas de totales separadas

cat("Estructura identificada:\n")
cat("  - Columnas de metadatos:", length(meta_cols), "\n")
cat("  - Columnas de cuentas SNV:", length(count_cols), "\n")
cat("  - Columnas de totales miRNA:", length(total_cols), "\n")
cat("  - Total de muestras:", length(count_cols), "\n\n")

# =============================================================================
# PASO 3: MOSTRAR EJEMPLOS DE MUTACIONES MÚLTIPLES
# =============================================================================

cat("PASO 3: Identificando mutaciones múltiples...\n")

# Buscar filas con múltiples mutaciones (contienen comas)
multiple_mutations <- raw_data[grepl(",", raw_data$`pos:mut`), ]

cat("Filas con múltiples mutaciones:", nrow(multiple_mutations), "\n")
cat("Porcentaje del total:", round(nrow(multiple_mutations)/nrow(raw_data)*100, 2), "%\n\n")

if (nrow(multiple_mutations) > 0) {
  cat("EJEMPLOS DE MUTACIONES MÚLTIPLES:\n")
  examples <- head(multiple_mutations[,1:6], 5)
  print(examples)
  cat("\n")
}

# =============================================================================
# PASO 4: APLICAR SPLIT (SEPARAR MUTACIONES MÚLTIPLES)
# =============================================================================

cat("PASO 4: Aplicando SPLIT (separando mutaciones múltiples)...\n")

# Aplicar split
split_data <- raw_data %>%
  separate_rows(`pos:mut`, sep = ",") %>%
  mutate(`pos:mut` = str_trim(`pos:mut`))

cat("Después del SPLIT:\n")
cat("  - Filas (SNVs):", nrow(split_data), "\n")
cat("  - Incremento:", nrow(split_data) - nrow(raw_data), "filas\n")
cat("  - miRNAs únicos:", length(unique(split_data$`miRNA name`)), "\n\n")

# Mostrar ejemplos después del split
cat("EJEMPLOS DESPUÉS DEL SPLIT:\n")
# Buscar un miRNA que tenía múltiples mutaciones
if (nrow(multiple_mutations) > 0) {
  example_mirna <- multiple_mutations$`miRNA name`[1]
  split_examples <- split_data[split_data$`miRNA name` == example_mirna, ]
  cat("miRNA:", example_mirna, "\n")
  print(head(split_examples[,1:6], 3))
  cat("\n")
}

# =============================================================================
# PASO 5: APLICAR COLLAPSE (SUMAR DUPLICADOS)
# =============================================================================

cat("PASO 5: Aplicando COLLAPSE (sumando duplicados)...\n")

# Aplicar collapse
collapsed_data <- split_data %>%
  group_by(`miRNA name`, `pos:mut`) %>%
  summarise(
    across(all_of(count_cols), ~sum(as.numeric(.x), na.rm = TRUE)),
    .groups = "drop"
  )

cat("Después del COLLAPSE:\n")
cat("  - Filas (SNVs):", nrow(collapsed_data), "\n")
cat("  - Reducción:", nrow(split_data) - nrow(collapsed_data), "filas\n")
cat("  - miRNAs únicos:", length(unique(collapsed_data$`miRNA name`)), "\n\n")

# =============================================================================
# PASO 6: RESUMEN FINAL
# =============================================================================

cat("PASO 6: RESUMEN FINAL DEL SPLIT-COLLAPSE\n")
cat("==========================================\n")
cat("Datos originales:\n")
cat("  - SNVs:", nrow(raw_data), "\n")
cat("  - miRNAs:", length(unique(raw_data$`miRNA name`)), "\n")
cat("  - Muestras:", length(count_cols), "\n\n")

cat("Después del SPLIT:\n")
cat("  - SNVs:", nrow(split_data), "\n")
cat("  - Incremento:", nrow(split_data) - nrow(raw_data), "SNVs\n\n")

cat("Después del COLLAPSE:\n")
cat("  - SNVs:", nrow(collapsed_data), "\n")
cat("  - Reducción:", nrow(split_data) - nrow(collapsed_data), "SNVs\n")
cat("  - Neto:", nrow(collapsed_data) - nrow(raw_data), "SNVs\n\n")

# =============================================================================
# PASO 7: MOSTRAR EJEMPLOS DE DUPLICADOS QUE SE COLAPSARON
# =============================================================================

cat("PASO 7: Ejemplos de duplicados que se colapsaron...\n")

# Buscar duplicados en split_data
duplicates <- split_data %>%
  group_by(`miRNA name`, `pos:mut`) %>%
  summarise(n = n(), .groups = "drop") %>%
  filter(n > 1) %>%
  arrange(desc(n))

if (nrow(duplicates) > 0) {
  cat("SNVs que tenían duplicados:\n")
  print(head(duplicates, 5))
  cat("\n")
  
  # Mostrar ejemplo detallado
  if (nrow(duplicates) > 0) {
    example_dup <- duplicates[1,]
    cat("Ejemplo detallado - miRNA:", example_dup$`miRNA name`, 
        ", posición:", example_dup$`pos:mut`, "\n")
    
    # Mostrar las filas duplicadas antes del collapse
    dup_rows <- split_data[split_data$`miRNA name` == example_dup$`miRNA name` & 
                          split_data$`pos:mut` == example_dup$`pos:mut`, ]
    cat("Filas duplicadas antes del collapse:\n")
    print(dup_rows[,1:6])
    
    # Mostrar la fila resultante después del collapse
    collapsed_row <- collapsed_data[collapsed_data$`miRNA name` == example_dup$`miRNA name` & 
                                   collapsed_data$`pos:mut` == example_dup$`pos:mut`, ]
    cat("\nFila resultante después del collapse:\n")
    print(collapsed_row[,1:6])
  }
}

cat("\n=== DEMOSTRACIÓN COMPLETADA ===\n")
cat("Fecha de finalización:", Sys.time(), "\n")
