library(dplyr)
library(tidyr)
library(stringr)

# =============================================================================
# VERIFICAR MANEJO DE NAs EN EL PIPELINE
# =============================================================================

cat("=== VERIFICACIÓN DEL MANEJO DE NAs ===\n\n")

# 1. CARGAR DATOS PROCESADOS
# =============================================================================
cat("1. CARGANDO DATOS PROCESADOS\n")
cat("============================\n")

final_data <- read.csv("../processed_data/final_processed_data.csv", stringsAsFactors = FALSE)

cat("Datos cargados:\n")
cat("  - SNVs:", nrow(final_data), "\n")
cat("  - Muestras:", ncol(final_data) - 2, "\n\n")

# 2. IDENTIFICAR COLUMNAS DE MUESTRAS
# =============================================================================
sample_cols <- colnames(final_data)[!colnames(final_data) %in% c("miRNA_name", "pos.mut")]

# 3. ANALIZAR NAs POR SNV
# =============================================================================
cat("2. ANALIZANDO NAs POR SNV\n")
cat("=========================\n")

# Contar NAs por SNV
na_analysis <- final_data %>%
  mutate(
    total_nas = rowSums(is.na(across(all_of(sample_cols)))),
    total_samples = length(sample_cols),
    pct_nas = (total_nas / total_samples) * 100
  ) %>%
  select(miRNA_name, pos.mut, total_nas, total_samples, pct_nas)

cat("Distribución de NAs por SNV:\n")
print(summary(na_analysis$total_nas))

cat("\nSNVs con diferentes porcentajes de NAs:\n")
na_summary <- na_analysis %>%
  group_by(total_nas) %>%
  summarise(n_snvs = n(), .groups = 'drop') %>%
  arrange(desc(total_nas))

print(head(na_summary, 10))

# 4. ANALIZAR SNVs CON TODOS LOS VAFs COMO NA
# =============================================================================
cat("\n3. ANALIZANDO SNVs CON TODOS LOS VAFs COMO NA\n")
cat("=============================================\n")

all_na_snvs <- na_analysis %>%
  filter(total_nas == total_samples)

cat("SNVs con TODOS los VAFs como NA:", nrow(all_na_snvs), "\n")
cat("Porcentaje del total:", round(nrow(all_na_snvs) / nrow(final_data) * 100, 2), "%\n\n")

if (nrow(all_na_snvs) > 0) {
  cat("Ejemplos de SNVs con todos los VAFs como NA:\n")
  print(head(all_na_snvs, 5))
}

# 5. ANALIZAR SNVs CON ALGUNOS VAFs VÁLIDOS
# =============================================================================
cat("\n4. ANALIZANDO SNVs CON ALGUNOS VAFs VÁLIDOS\n")
cat("===========================================\n")

valid_snvs <- na_analysis %>%
  filter(total_nas < total_samples)

cat("SNVs con al menos un VAF válido:", nrow(valid_snvs), "\n")
cat("Porcentaje del total:", round(nrow(valid_snvs) / nrow(final_data) * 100, 2), "%\n\n")

# 6. ANALIZAR POR POSICIÓN
# =============================================================================
cat("5. ANALIZANDO NAs POR POSICIÓN\n")
cat("==============================\n")

# Extraer posición
position_na_analysis <- final_data %>%
  mutate(
    pos = as.integer(str_extract(pos.mut, "^[0-9]+")),
    total_nas = rowSums(is.na(across(all_of(sample_cols)))),
    total_samples = length(sample_cols),
    pct_nas = (total_nas / total_samples) * 100
  ) %>%
  filter(!is.na(pos)) %>%
  group_by(pos) %>%
  summarise(
    n_snvs = n(),
    mean_nas = mean(total_nas),
    mean_pct_nas = mean(pct_nas),
    snvs_all_na = sum(total_nas == total_samples),
    snvs_some_valid = sum(total_nas < total_samples),
    .groups = 'drop'
  ) %>%
  arrange(pos)

cat("Análisis por posición:\n")
print(head(position_na_analysis, 10))

# 7. VERIFICAR SI ESTAMOS FILTRANDO CORRECTAMENTE
# =============================================================================
cat("\n6. VERIFICANDO FILTRADO CORRECTO\n")
cat("=================================\n")

# Simular el filtrado que hacemos en el análisis por posición
filtered_data <- final_data %>%
  mutate(
    pos = as.integer(str_extract(pos.mut, "^[0-9]+")),
    total_nas = rowSums(is.na(across(all_of(sample_cols)))),
    total_samples = length(sample_cols)
  ) %>%
  filter(!is.na(pos) & total_nas < total_samples)  # Solo SNVs con al menos un VAF válido

cat("SNVs después del filtrado (al menos un VAF válido):", nrow(filtered_data), "\n")
cat("SNVs eliminados:", nrow(final_data) - nrow(filtered_data), "\n")
cat("Porcentaje eliminado:", round((nrow(final_data) - nrow(filtered_data)) / nrow(final_data) * 100, 2), "%\n\n")

# 8. ANÁLISIS POR POSICIÓN DESPUÉS DEL FILTRADO
# =============================================================================
cat("7. ANÁLISIS POR POSICIÓN DESPUÉS DEL FILTRADO\n")
cat("=============================================\n")

position_analysis_filtered <- filtered_data %>%
  group_by(pos) %>%
  summarise(n_snvs = n(), .groups = 'drop') %>%
  arrange(pos)

cat("SNVs por posición después del filtrado:\n")
print(head(position_analysis_filtered, 10))

cat("\n=== VERIFICACIÓN COMPLETADA ===\n")
