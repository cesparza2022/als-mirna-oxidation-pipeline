# Verificar estructura del dataset
library(tidyverse)

# Cargar configuración
source("../config_pipeline.R")

# Cargar datos
raw_data <- read_tsv(config$data_paths$raw_data, 
                     col_types = cols(.default = "c"))

cat("=== ESTRUCTURA DEL DATASET ===\n")
cat("Dimensiones:", dim(raw_data), "\n")
cat("Nombres de columnas (primeras 10):\n")
print(head(names(raw_data), 10))

cat("\nPrimeras 3 filas:\n")
print(head(raw_data, 3))

cat("\nTipos de columnas:\n")
str(raw_data[,1:10])








