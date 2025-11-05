# ============================================================================
# PRE-PROCESAMIENTO: FILTRAR VAF > 0.5 (50%)
# Valores tan altos son poco confiables → convertir a NA
# ============================================================================

library(dplyr)
library(tidyr)

cat("🎯 PRE-PROCESAMIENTO: FILTRADO DE VAF\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

# Cargar datos originales
cat("📊 Cargando datos originales...\n")
data_original <- read.csv("../../../final_analysis/processed_data/final_processed_data.csv")

cat("✅ Datos cargados:\n")
cat("   - Filas:", nrow(data_original), "\n")
cat("   - Columnas:", ncol(data_original), "\n\n")

# Identificar columnas de muestras (VAF)
sample_cols <- grep("^Magen", colnames(data_original), value = TRUE)
cat("📊 Columnas de muestras encontradas:", length(sample_cols), "\n\n")

# Contar valores > 0.5 ANTES del filtrado
cat("📊 ANÁLISIS PRE-FILTRADO:\n")
vaf_values <- data_original %>%
  select(all_of(sample_cols)) %>%
  as.matrix() %>%
  as.vector()

total_values <- length(vaf_values)
values_above_50 <- sum(vaf_values > 0.5, na.rm = TRUE)
percent_above_50 <- (values_above_50 / total_values) * 100

cat("   - Total de valores VAF:", format(total_values, big.mark = ","), "\n")
cat("   - Valores > 0.5 (50%):", format(values_above_50, big.mark = ","), "\n")
cat("   - Porcentaje > 0.5:", round(percent_above_50, 3), "%\n\n")

# Crear copia de datos
data_filtered <- data_original

# FILTRAR: Convertir VAF > 0.5 a NA
cat("🔧 APLICANDO FILTRO: VAF > 0.5 → NA\n")

for (col in sample_cols) {
  # Identificar valores > 0.5
  high_vaf <- data_filtered[[col]] > 0.5
  high_vaf[is.na(high_vaf)] <- FALSE
  
  # Convertir a NA
  data_filtered[[col]][high_vaf] <- NA
}

cat("✅ Filtro aplicado a", length(sample_cols), "columnas de muestras\n\n")

# Contar valores DESPUÉS del filtrado
cat("📊 ANÁLISIS POST-FILTRADO:\n")
vaf_values_filtered <- data_filtered %>%
  select(all_of(sample_cols)) %>%
  as.matrix() %>%
  as.vector()

values_na <- sum(is.na(vaf_values_filtered))
values_valid <- sum(!is.na(vaf_values_filtered) & vaf_values_filtered > 0)
values_zero <- sum(vaf_values_filtered == 0, na.rm = TRUE)

cat("   - Valores NA:", format(values_na, big.mark = ","), 
    "(", round(values_na/total_values*100, 3), "%)\n")
cat("   - Valores válidos > 0:", format(values_valid, big.mark = ","),
    "(", round(values_valid/total_values*100, 3), "%)\n")
cat("   - Valores = 0:", format(values_zero, big.mark = ","),
    "(", round(values_zero/total_values*100, 3), "%)\n\n")

# Guardar datos filtrados
output_path <- "final_processed_data_FILTERED_VAF50.csv"
write.csv(data_filtered, output_path, row.names = FALSE)

cat("✅ DATOS FILTRADOS GUARDADOS\n")
cat("📁 Archivo:", output_path, "\n")
cat("📊 Dimensiones:", nrow(data_filtered), "filas x", ncol(data_filtered), "columnas\n\n")

# Crear resumen del filtrado
summary_df <- data.frame(
  Metric = c("Total values", "Values > 0.5 (removed)", "Values NA after filter", 
             "Valid values (0-0.5)", "Values = 0", "Percent removed"),
  Count = c(
    format(total_values, big.mark = ","),
    format(values_above_50, big.mark = ","),
    format(values_na, big.mark = ","),
    format(values_valid, big.mark = ","),
    format(values_zero, big.mark = ","),
    paste0(round(percent_above_50, 3), "%")
  )
)

cat("📋 RESUMEN DEL FILTRADO:\n")
print(summary_df, row.names = FALSE)

cat("\n✅ PRE-PROCESAMIENTO COMPLETADO\n")
cat("🎯 Siguiente paso: Re-generar TODAS las figuras con datos filtrados\n")

