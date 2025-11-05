# Investigar formatos de datos
library(dplyr)

# Cargar datos VAF
df_main <- read.csv("outputs/tables/df_block_heatmap_clean.csv", stringsAsFactors = FALSE)
cat("=== DATOS VAF ===\n")
cat("Filas:", nrow(df_main), "\n")
cat("Columnas:", ncol(df_main), "\n")
cat("Nombres de columnas (primeras 10):\n")
print(names(df_main)[1:10])
cat("Columnas VAF:\n")
print(grep("VAF", names(df_main), value = TRUE))
cat("Features (primeras 5):\n")
print(df_main$feature[1:5])

# Cargar datos RPM
df_rpm <- read.csv("organized/04_results/positional_analysis/als_rpm_data_processed.csv", stringsAsFactors = FALSE)
cat("\n=== DATOS RPM ===\n")
cat("Filas:", nrow(df_rpm), "\n")
cat("Columnas:", ncol(df_rpm), "\n")
cat("Nombres de columnas (primeras 5):\n")
print(names(df_rpm)[1:5])
cat("Columnas RPM (primeras 5):\n")
print(grep("_RPM$", names(df_rpm), value = TRUE)[1:5])
cat("miRNA names (primeras 5):\n")
print(df_rpm$miRNA.name[1:5])
cat("pos:mut (primeras 5):\n")
print(df_rpm$pos.mut[1:5])









