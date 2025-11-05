# 🧪 TEST: GENERAR FIGURA 1 CON DATOS REALES

## 📋 LIMPIAR Y CONFIGURAR
rm(list = ls())
cat("🧪 Generando Figura 1 con datos reales...\n\n")

## 📦 CARGAR LIBRERÍAS
library(tidyverse)
library(patchwork)
library(viridis)

## ⚙️ CONFIGURACIÓN
source("config/config_pipeline_2.R")
source("functions/visualization_functions_simple.R")

## 📥 CARGAR DATOS DEL PIPELINE ORIGINAL
cat("📥 Cargando datos procesados del pipeline original...\n")

# Ruta a los datos originales procesados
data_path <- "/Users/cesaresparza/New_Desktop/UCSD/8OG/results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt"

if (!file.exists(data_path)) {
  stop("❌ Archivo no encontrado: ", data_path)
}

# Cargar datos
raw_data <- read_tsv(data_path, show_col_types = FALSE)
cat("✅ Datos cargados:", nrow(raw_data), "filas\n")
cat("📊 Columnas:", paste(names(raw_data)[1:10], collapse = ", "), "...\n\n")

## 🔧 PROCESAR DATOS (SIMPLIFICADO)
cat("🔧 Procesando datos...\n")

# Extraer datos de mutaciones
# Asumiendo estructura: miRNA name, pos:mut, muestras...
processed_data <- raw_data %>%
  # Separar mutaciones múltiples
  separate_rows(`pos:mut`, sep = ",") %>%
  # Filtrar filas vacías
  filter(!is.na(`pos:mut`), `pos:mut` != "")

cat("✅ Datos procesados:", nrow(processed_data), "filas\n")
cat("📊 miRNAs únicos:", n_distinct(processed_data$`miRNA name`), "\n\n")

## 🎨 GENERAR FIGURA 1
cat("🎨 Generando Figura 1...\n\n")

# Preparar datos para funciones
data_list <- list(
  raw = raw_data,
  processed = processed_data
)

# Crear directorios si no existen
dir.create(figures_dir, showWarnings = FALSE, recursive = TRUE)

# Generar figura
tryCatch({
  figure_1 <- create_figure_1_simple(data_list, figures_dir)
  cat("✅ Figura 1 generada exitosamente\n\n")
}, error = function(e) {
  cat("❌ Error generando Figura 1:\n")
  cat("   ", e$message, "\n")
  cat("\n📊 Estructura de datos para debug:\n")
  cat("   Columnas disponibles:", paste(names(processed_data)[1:10], collapse = ", "), "\n")
  cat("   Primeras filas:\n")
  print(head(processed_data[,1:5], 3))
})

cat("\n🎉 Proceso completado\n")
