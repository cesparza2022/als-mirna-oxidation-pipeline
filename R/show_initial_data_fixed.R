# =============================================================================
# MOSTRAR DATOS INICIALES (CORREGIDO)
# =============================================================================
# 
# Objetivo: Mostrar cómo se ven los datos iniciales de forma clara
#
# Autor: César Esparza
# Fecha: 2025
# =============================================================================

# --- LIBRERÍAS ---
library(dplyr)
library(tidyr)
library(stringr)

# --- CONFIGURACIÓN ---
cat("📊 DATOS INICIALES DETALLADOS\n")
cat("=============================\n\n")

# --- 1. CARGAR Y MOSTRAR DATOS INICIALES ---
cat("📋 1. ESTRUCTURA DE LOS DATOS INICIALES\n")
cat("======================================\n")

# Cargar datos principales
df_main <- read.csv("outputs/tables/df_block_heatmap_clean.csv", stringsAsFactors = FALSE)

cat("📈 Información general:\n")
cat("   - Filas (SNVs):", nrow(df_main), "\n")
cat("   - Columnas:", ncol(df_main), "\n")
cat("   - Muestras:", ncol(df_main) - 1, "\n\n")

# --- 2. MOSTRAR FEATURES ---
cat("📋 2. FEATURES (SNVs)\n")
cat("=====================\n")

cat("📋 Todos los features:\n")
for (i in 1:length(df_main$feature)) {
  cat(sprintf("%2d. %s\n", i, df_main$feature[i]))
}

# --- 3. ANÁLISIS DE FEATURES ---
cat("\n📋 3. ANÁLISIS DE FEATURES\n")
cat("==========================\n")

# Extraer información de los features
feature_analysis <- df_main %>%
  mutate(
    miRNA_name = str_extract(feature, "^[^_]+"),
    pos = as.integer(str_extract(feature, "_([0-9]+)_GT$", group = 1)),
    mutation_type = str_extract(feature, "_([A-Z]+)$", group = 1)
  )

cat("📊 Análisis de features:\n")
print(feature_analysis %>% select(feature, miRNA_name, pos, mutation_type))

# --- 4. ANÁLISIS POR miRNA ---
cat("\n📋 4. ANÁLISIS POR miRNA\n")
cat("========================\n")

mirna_summary <- feature_analysis %>%
  group_by(miRNA_name) %>%
  summarise(
    snv_count = n(),
    positions = paste(sort(unique(pos)), collapse = ", "),
    .groups = "drop"
  ) %>%
  arrange(desc(snv_count))

cat("📊 Resumen por miRNA:\n")
print(mirna_summary)

# --- 5. ANÁLISIS POR POSICIÓN ---
cat("\n📋 5. ANÁLISIS POR POSICIÓN\n")
cat("===========================\n")

position_summary <- feature_analysis %>%
  group_by(pos) %>%
  summarise(
    snv_count = n(),
    mirnas = paste(sort(unique(miRNA_name)), collapse = ", "),
    .groups = "drop"
  ) %>%
  arrange(pos)

cat("📊 Resumen por posición:\n")
print(position_summary)

# --- 6. MOSTRAR DATOS DE MUESTRAS ---
cat("\n📋 6. DATOS DE MUESTRAS (PRIMERAS 5 MUESTRAS)\n")
cat("=============================================\n")

# Mostrar datos de las primeras 5 muestras
sample_cols <- names(df_main)[!names(df_main) %in% c("feature")]
first_5_samples <- sample_cols[1:5]

cat("📊 Datos de las primeras 5 muestras:\n")
sample_data <- df_main %>%
  select(feature, all_of(first_5_samples)) %>%
  head(10)

print(sample_data)

# --- 7. ESTADÍSTICAS DE LOS DATOS ---
cat("\n📋 7. ESTADÍSTICAS DE LOS DATOS\n")
cat("===============================\n")

# Calcular estadísticas básicas de forma segura
sample_data_numeric <- df_main %>%
  select(all_of(sample_cols)) %>%
  mutate_all(as.numeric)

stats <- sample_data_numeric %>%
  summarise(
    min_value = min(., na.rm = TRUE),
    max_value = max(., na.rm = TRUE),
    mean_value = mean(., na.rm = TRUE),
    median_value = median(., na.rm = TRUE),
    na_count = sum(is.na(.)),
    total_values = nrow(.) * ncol(.)
  )

cat("📊 Estadísticas de los datos:\n")
cat("   - Valor mínimo:", round(stats$min_value, 6), "\n")
cat("   - Valor máximo:", round(stats$max_value, 6), "\n")
cat("   - Valor promedio:", round(stats$mean_value, 6), "\n")
cat("   - Valor mediano:", round(stats$median_value, 6), "\n")
cat("   - Valores NA:", stats$na_count, "\n")
cat("   - Total de valores:", stats$total_values, "\n")
cat("   - Porcentaje de NA:", round((stats$na_count / stats$total_values) * 100, 2), "%\n")

# --- 8. MOSTRAR EJEMPLOS DE DATOS ---
cat("\n📋 8. EJEMPLOS DE DATOS COMPLETOS\n")
cat("=================================\n")

# Mostrar algunos ejemplos completos
cat("📊 Ejemplo 1 - hsa-let-7i-5p_4_GT (primeras 10 muestras):\n")
example1 <- df_main %>%
  filter(feature == "hsa-let-7i-5p_4_GT") %>%
  select(feature, all_of(first_5_samples))

print(example1)

cat("\n📊 Ejemplo 2 - hsa-miR-122-5p_2_GT (primeras 10 muestras):\n")
example2 <- df_main %>%
  filter(feature == "hsa-miR-122-5p_2_GT") %>%
  select(feature, all_of(first_5_samples))

print(example2)

# --- 9. ANÁLISIS DE VALORES ALTOS ---
cat("\n📋 9. ANÁLISIS DE VALORES ALTOS\n")
cat("===============================\n")

# Encontrar valores altos (posiblemente VAF > 50%)
high_values <- sample_data_numeric %>%
  mutate(feature = df_main$feature) %>%
  pivot_longer(cols = -feature, names_to = "sample", values_to = "value") %>%
  filter(value > 0.5) %>%
  arrange(desc(value))

cat("📊 Valores > 0.5 (posiblemente VAF > 50%):\n")
if (nrow(high_values) > 0) {
  print(head(high_values, 10))
  cat("   - Total de valores > 0.5:", nrow(high_values), "\n")
} else {
  cat("   - No hay valores > 0.5\n")
}

cat("\n✅ ANÁLISIS DE DATOS INICIALES COMPLETADO\n")
cat("=========================================\n")









