# Debug de transformaciones
library(tidyverse)
source("../config_pipeline.R")
source("functions_pipeline.R")

# Cargar datos
raw_data <- read_tsv(config$data_paths$raw_data, col_types = cols(.default = "c"))

# Aplicar transformaciones
processed_data <- apply_split_collapse(raw_data)
vaf_data <- calculate_vafs(processed_data)
filtered_data <- filter_high_vafs(vaf_data, threshold = 0.5)

# Verificar dimensiones
cat("Dimensiones:\n")
cat("Raw data:", nrow(raw_data), "x", ncol(raw_data), "\n")
cat("Processed data:", nrow(processed_data), "x", ncol(processed_data), "\n")
cat("VAF data:", nrow(vaf_data), "x", ncol(vaf_data), "\n")
cat("Filtered data:", nrow(filtered_data), "x", ncol(filtered_data), "\n")

# Verificar split
split_data_temp <- raw_data %>% separate_rows(`pos:mut`, sep = ",") %>% mutate(`pos:mut` = str_trim(`pos:mut`))
cat("Split data:", nrow(split_data_temp), "x", ncol(split_data_temp), "\n")

# Crear data.frame
transformacion_stats <- data.frame(
  Transformacion = c("Dataset original", "Despues split", "Despues collapse", 
                     "Despues calculo VAFs", "Despues filtrado VAF > 50%"),
  Filas = c(nrow(raw_data), 
            nrow(split_data_temp),
            nrow(processed_data),
            nrow(vaf_data),
            nrow(filtered_data)),
  Columnas = c(ncol(raw_data), ncol(raw_data), ncol(processed_data), ncol(vaf_data), ncol(filtered_data))
)

print(transformacion_stats)








