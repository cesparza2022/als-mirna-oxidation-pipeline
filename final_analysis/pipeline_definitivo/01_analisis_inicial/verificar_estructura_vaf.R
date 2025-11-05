# Verificar estructura para cálculo de VAFs
library(tidyverse)

# Cargar configuración
source("../config_pipeline.R")

# Cargar datos
raw_data <- read_tsv(config$data_paths$raw_data, 
                     col_types = cols(.default = "c"))

cat("=== VERIFICACIÓN DE ESTRUCTURA PARA VAFs ===\n")

# Ver estructura de columnas
cat("Nombres de columnas (primeras 10):\n")
print(head(names(raw_data), 10))

cat("\nNombres de columnas (últimas 10):\n")
print(tail(names(raw_data), 10))

# Buscar patrones de totales
total_patterns <- c("PM\\+1MM\\+2MM", "PM\\.1MM\\.2MM", "total", "Total")
for (pattern in total_patterns) {
  matches <- names(raw_data)[grepl(pattern, names(raw_data))]
  if (length(matches) > 0) {
    cat("\nPatrón '", pattern, "' encontrado en", length(matches), "columnas:\n")
    print(head(matches, 5))
  }
}

# Ver ejemplo de datos
cat("\nPrimeras 3 filas (primeras 6 columnas):\n")
print(head(raw_data[,1:6], 3))

# Ver si hay columnas numéricas
cat("\nTipos de datos en las primeras 10 columnas:\n")
str(raw_data[,1:10])








