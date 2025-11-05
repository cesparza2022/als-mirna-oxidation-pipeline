# Script para crear metadata automáticamente desde los nombres de columnas

library(dplyr)
library(stringr)

cat("🎯 CREANDO METADATA AUTOMÁTICAMENTE\n")
cat(paste(rep("=", 60), collapse = ""), "\n\n")

# Cargar datos
data <- read.csv("../../../final_analysis/processed_data/final_processed_data.csv")

# Extraer nombres de columnas de muestras (empiezan con "Magen")
sample_cols <- grep("^Magen", colnames(data), value = TRUE)

# Crear metadata automáticamente extrayendo grupo del nombre
metadata <- data.frame(
  Sample_ID = sample_cols,
  Group = ifelse(str_detect(sample_cols, "ALS"), "ALS", "Control"),
  stringsAsFactors = FALSE
)

# Estadísticas
cat("📊 RESUMEN:\n")
cat("  Total de muestras:", nrow(metadata), "\n")
cat("  - ALS:", sum(metadata$Group == "ALS"), "\n")
cat("  - Control:", sum(metadata$Group == "Control"), "\n\n")

# Guardar metadata
write.csv(metadata, "metadata.csv", row.names = FALSE)
cat("✅ Metadata guardado en: metadata.csv\n\n")

# Mostrar ejemplos
cat("📋 EJEMPLOS DE METADATA:\n\n")
cat("Primeras 5 muestras ALS:\n")
print(head(metadata[metadata$Group == "ALS", ], 5))
cat("\nPrimeras 5 muestras Control:\n")
print(head(metadata[metadata$Group == "Control", ], 5))

