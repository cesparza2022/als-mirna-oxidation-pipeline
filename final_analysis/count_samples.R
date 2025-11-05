library(dplyr)

# Cargar los datos procesados
vaf_df <- read.csv("processed_data/vaf_data.csv", stringsAsFactors = FALSE)

# Obtener las columnas de muestras (excluyendo miRNA_name y pos.mut)
sample_cols <- colnames(vaf_df)[!colnames(vaf_df) %in% c("miRNA_name", "pos.mut")]

cat("Total de columnas de muestras:", length(sample_cols), "\n\n")

# Identificar grupos por nombre de columna
identify_cohort <- function(col_name) {
  if (grepl("control", col_name, ignore.case = TRUE)) {
    return("Control")
  } else if (grepl("ALS", col_name, ignore.case = TRUE)) {
    return("ALS")
  } else {
    return("Unknown")
  }
}

# Aplicar la función a todas las columnas de muestras
cohorts <- sapply(sample_cols, identify_cohort)

# Contar por grupo
cohort_counts <- table(cohorts)

cat("Distribución de muestras por grupo:\n")
print(cohort_counts)

cat("\nDetalles por grupo:\n")
cat("===================\n")

# Mostrar algunos ejemplos de cada grupo
control_samples <- sample_cols[cohorts == "Control"]
als_samples <- sample_cols[cohorts == "ALS"]

cat("Muestras Control (primeras 5):\n")
print(head(control_samples, 5))

cat("\nMuestras ALS (primeras 5):\n")
print(head(als_samples, 5))

# Verificar si hay muestras longitudinales
longitudinal_samples <- sample_cols[grepl("longitudinal", sample_cols, ignore.case = TRUE)]
if (length(longitudinal_samples) > 0) {
  cat("\nMuestras longitudinales encontradas:", length(longitudinal_samples), "\n")
  print(head(longitudinal_samples, 5))
}









