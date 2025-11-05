# =============================================================================
# PASO 1A: CARGAR Y PROCESAR DATOS BÁSICOS
# =============================================================================
# Autor: César Esparza
# Fecha: 2024
# Descripción: Cargar datos y aplicar transformaciones básicas
# =============================================================================

# Cargar librerías
library(tidyverse)

# Cargar configuración y funciones
source("../config_pipeline.R")
source("functions_pipeline.R")

cat("=== PASO 1A: CARGAR Y PROCESAR DATOS BÁSICOS ===\n")
cat("Fecha:", Sys.time(), "\n\n")

# Crear directorios de salida
dir.create("figures", showWarnings = FALSE)
dir.create("tables", showWarnings = FALSE)

# =============================================================================
# CARGAR DATOS ORIGINALES
# =============================================================================

cat("Cargando datos originales...\n")
raw_data <- read_tsv(config$data_paths$raw_data, 
                     col_types = cols(.default = "c"))

cat("Datos cargados:\n")
cat("  - Filas:", nrow(raw_data), "\n")
cat("  - Columnas:", ncol(raw_data), "\n")
cat("  - miRNAs únicos:", length(unique(raw_data$`miRNA name`)), "\n")

# =============================================================================
# APLICAR SPLIT-COLLAPSE
# =============================================================================

cat("\nAplicando split-collapse...\n")
processed_data <- apply_split_collapse(raw_data)

cat("Después del split-collapse:\n")
cat("  - Filas:", nrow(processed_data), "\n")
cat("  - Columnas:", ncol(processed_data), "\n")
cat("  - miRNAs únicos:", length(unique(processed_data$`miRNA name`)), "\n")

# =============================================================================
# CALCULAR VAFs
# =============================================================================

cat("\nCalculando VAFs...\n")
vaf_data <- calculate_vafs(processed_data)

cat("Después del cálculo de VAFs:\n")
cat("  - Filas:", nrow(vaf_data), "\n")
cat("  - Columnas:", ncol(vaf_data), "\n")

# =============================================================================
# FILTRAR VAFs ALTAS
# =============================================================================

cat("\nFiltrando VAFs > 50%...\n")
filtered_data <- filter_high_vafs(vaf_data, threshold = 0.5)

cat("Después del filtrado:\n")
cat("  - Filas:", nrow(filtered_data), "\n")
cat("  - Columnas:", ncol(filtered_data), "\n")

# =============================================================================
# GUARDAR DATOS PROCESADOS
# =============================================================================

cat("\nGuardando datos procesados...\n")
write_csv(processed_data, "tables/datos_procesados_split_collapse.csv")
write_csv(vaf_data, "tables/datos_con_vafs.csv")
write_csv(filtered_data, "tables/datos_filtrados_vaf.csv")

# =============================================================================
# RESUMEN DE TRANSFORMACIONES
# =============================================================================

cat("\n=== RESUMEN DE TRANSFORMACIONES ===\n")
transformacion_summary <- data.frame(
  Paso = c("Original", "Split-Collapse", "Con VAFs", "Filtrado VAF>50%"),
  Filas = c(nrow(raw_data), nrow(processed_data), nrow(vaf_data), nrow(filtered_data)),
  Columnas = c(ncol(raw_data), ncol(processed_data), ncol(vaf_data), ncol(filtered_data)),
  miRNAs = c(length(unique(raw_data$`miRNA name`)), 
             length(unique(processed_data$`miRNA name`)),
             length(unique(vaf_data$`miRNA name`)),
             length(unique(filtered_data$`miRNA name`)))
)

print(transformacion_summary)
write_csv(transformacion_summary, "tables/resumen_transformaciones.csv")

cat("\nPaso 1A completado exitosamente!\n")
cat("Archivos generados:\n")
cat("  - 3 archivos CSV con datos procesados\n")
cat("  - 1 archivo CSV con resumen de transformaciones\n")








