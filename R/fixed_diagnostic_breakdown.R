# =============================================================================
# DIAGNÓSTICO CORREGIDO DE TRANSFORMACIÓN DE DATOS
# =============================================================================
# 
# Objetivo: Desglosar paso a paso cómo se transforman los datos con correcciones
#
# Autor: César Esparza
# Fecha: 2025
# =============================================================================

# --- LIBRERÍAS ---
library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)

# --- CONFIGURACIÓN ---
cat("🔍 DIAGNÓSTICO CORREGIDO DE TRANSFORMACIÓN DE DATOS\n")
cat("==================================================\n\n")

# --- 1. CARGAR DATOS INICIALES ---
cat("📊 1. ESTADO INICIAL DE LOS DATOS\n")
cat("=================================\n")

# Cargar datos principales
df_main <- read.csv("outputs/tables/df_block_heatmap_clean.csv", stringsAsFactors = FALSE)
df_vaf <- read.csv("outputs/tables/VAF_df.csv", stringsAsFactors = FALSE)

# Extraer nombres de muestras
sample_cols <- names(df_main)[!names(df_main) %in% c("feature")]

cat("📈 DATOS INICIALES:\n")
cat("   - Filas principales:", nrow(df_main), "\n")
cat("   - Filas VAF:", nrow(df_vaf), "\n")
cat("   - Muestras:", length(sample_cols), "\n\n")

# Mostrar ejemplos de features
cat("📋 EJEMPLOS DE FEATURES:\n")
print(head(df_main$feature, 10))

# --- 2. ANÁLISIS DETALLADO DE FEATURES ---
cat("\n🔍 2. ANÁLISIS DETALLADO DE FEATURES\n")
cat("=====================================\n")

# Analizar patrones en los nombres de features
feature_patterns <- df_main %>%
  mutate(
    has_gt = str_detect(feature, "_GT$"),
    has_tc = str_detect(feature, "_TC$"),
    has_ag = str_detect(feature, "_AG$"),
    has_ga = str_detect(feature, "_GA$"),
    has_ct = str_detect(feature, "_CT$"),
    has_ta = str_detect(feature, "_TA$"),
    has_tg = str_detect(feature, "_TG$"),
    has_at = str_detect(feature, "_AT$"),
    has_pm = str_detect(feature, "_PM$")
  ) %>%
  summarise(
    total = n(),
    gt_count = sum(has_gt),
    tc_count = sum(has_tc),
    ag_count = sum(has_ag),
    ga_count = sum(has_ga),
    ct_count = sum(has_ct),
    ta_count = sum(has_ta),
    tg_count = sum(has_tg),
    at_count = sum(has_at),
    pm_count = sum(has_pm)
  )

cat("📊 PATRONES DE MUTACIONES:\n")
print(feature_patterns)

# Analizar estructura de features G>T
gt_features <- df_main %>%
  filter(str_detect(feature, "_GT$")) %>%
  mutate(
    miRNA_name = str_extract(feature, "^[^_]+"),
    # Corregir regex para capturar posición
    pos = as.integer(str_extract(feature, "_([0-9]+)_GT$", group = 1))
  )

cat("\n🎯 MUTACIONES G>T DETALLADAS:\n")
print(gt_features %>% select(feature, miRNA_name, pos))

# --- 3. FUNCIONES CORREGIDAS ---
cat("\n🔧 3. FUNCIONES CORREGIDAS\n")
cat("===========================\n")

# Función para manejar VAFs > 50%
handle_vaf_threshold <- function(data, threshold = 0.5) {
  data %>%
    mutate(across(all_of(sample_cols), ~ifelse(. > threshold, NA, .)))
}

# Función split corregida
split_mutations <- function(data) {
  data %>%
    mutate(
      mutation_type = case_when(
        str_detect(feature, "_GT$") ~ "G>T",
        str_detect(feature, "_TC$") ~ "T>C", 
        str_detect(feature, "_AG$") ~ "A>G",
        str_detect(feature, "_GA$") ~ "G>A",
        str_detect(feature, "_CT$") ~ "C>T",
        str_detect(feature, "_TA$") ~ "T>A",
        str_detect(feature, "_TG$") ~ "T>G",
        str_detect(feature, "_AT$") ~ "A>T",
        str_detect(feature, "_PM$") ~ "PM",
        TRUE ~ "Other"
      ),
      miRNA_name = str_extract(feature, "^[^_]+"),
      # Corregir regex para capturar posición correctamente
      pos = as.integer(str_extract(feature, "_([0-9]+)_[A-Z]+>$", group = 1))
    )
}

# Función collapse para agrupar por posición
collapse_by_position <- function(data) {
  data %>%
    group_by(pos, mutation_type) %>%
    summarise(
      mean_vaf = mean(rowMeans(across(all_of(sample_cols)), na.rm = TRUE), na.rm = TRUE),
      total_vaf = sum(rowMeans(across(all_of(sample_cols)), na.rm = TRUE), na.rm = TRUE),
      count = n(),
      .groups = "drop"
    )
}

cat("✅ Funciones corregidas\n")

# --- 4. APLICAR SPLIT CORREGIDO ---
cat("\n🔄 4. APLICANDO SPLIT CORREGIDO\n")
cat("================================\n")

df_split <- split_mutations(df_main)

cat("📊 DESPUÉS DEL SPLIT CORREGIDO:\n")
cat("   - Filas totales:", nrow(df_split), "\n")
cat("   - Mutaciones G>T:", sum(df_split$mutation_type == "G>T", na.rm = TRUE), "\n")
cat("   - miRNAs únicos:", n_distinct(df_split$miRNA_name), "\n")
cat("   - Posiciones únicas:", n_distinct(df_split$pos), "\n")

# Mostrar datos G>T después del split
gt_split <- df_split %>%
  filter(mutation_type == "G>T") %>%
  select(feature, miRNA_name, pos, mutation_type)

cat("\n📋 MUTACIONES G>T DESPUÉS DEL SPLIT:\n")
print(gt_split)

# --- 5. APLICAR COLLAPSE ---
cat("\n🔄 5. APLICANDO COLLAPSE\n")
cat("========================\n")

df_collapsed <- collapse_by_position(df_split)

cat("📊 DESPUÉS DEL COLLAPSE:\n")
cat("   - Filas totales:", nrow(df_collapsed), "\n")
cat("   - Mutaciones G>T:", sum(df_collapsed$mutation_type == "G>T", na.rm = TRUE), "\n")
cat("   - Posiciones únicas:", n_distinct(df_collapsed$pos), "\n")

# Mostrar datos collapsed
cat("\n📋 DATOS COLLAPSED:\n")
print(df_collapsed)

# --- 6. APLICAR FILTRO VAF > 50% ---
cat("\n🔄 6. APLICANDO FILTRO VAF > 50%\n")
cat("==================================\n")

# Aplicar filtro VAF > 50%
df_vaf_filtered <- handle_vaf_threshold(df_main)

# Calcular estadísticas de NaN
vaf_stats <- df_vaf_filtered %>%
  select(all_of(sample_cols)) %>%
  summarise(
    total_values = nrow(.) * ncol(.),
    nan_values = sum(is.na(.)),
    nan_percentage = round((sum(is.na(.)) / (nrow(.) * ncol(.))) * 100, 2)
  )

cat("📊 ESTADÍSTICAS VAF > 50%:\n")
cat("   - Valores totales:", vaf_stats$total_values, "\n")
cat("   - Valores convertidos a NaN:", vaf_stats$nan_values, "\n")
cat("   - Porcentaje de NaN:", vaf_stats$nan_percentage, "%\n")

# Análisis por SNV
nan_per_snv <- df_vaf_filtered %>%
  rowwise() %>%
  mutate(
    nan_count = sum(is.na(c_across(all_of(sample_cols)))),
    nan_percentage = round((nan_count / length(sample_cols)) * 100, 2)
  ) %>%
  ungroup() %>%
  select(feature, nan_count, nan_percentage) %>%
  arrange(desc(nan_count))

cat("\n📈 TOP 10 SNVs CON MÁS NaNs:\n")
print(head(nan_per_snv, 10))

# --- 7. ANÁLISIS DE miRNAs CON MÁS G>T ---
cat("\n🎯 7. ANÁLISIS DE miRNAs CON MÁS G>T\n")
cat("=====================================\n")

# Análisis de miRNAs con G>T
miRNA_analysis <- gt_split %>%
  mutate(
    in_seed = pos >= 2 & pos <= 8,
    in_seed = ifelse(is.na(in_seed), FALSE, in_seed)
  ) %>%
  group_by(miRNA_name) %>%
  summarise(
    total_gt = n(),
    seed_gt = sum(in_seed, na.rm = TRUE),
    positions = n_distinct(pos),
    seed_positions = n_distinct(ifelse(in_seed, pos, NA), na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(total_gt))

cat("📈 miRNAs CON MUTACIONES G>T:\n")
print(miRNA_analysis)

# --- 8. ANÁLISIS DE RPM (USANDO DATOS PRINCIPALES) ---
cat("\n📊 8. ANÁLISIS DE RPM (USANDO DATOS PRINCIPALES)\n")
cat("==================================================\n")

# Usar datos principales como proxy para RPM
df_rpm_analysis <- df_main %>%
  filter(str_detect(feature, "_GT$")) %>%
  mutate(
    miRNA_name = str_extract(feature, "^[^_]+"),
    pos = as.integer(str_extract(feature, "_([0-9]+)_GT$", group = 1)),
    # Usar promedio de todas las muestras como proxy de abundancia
    avr_raw = rowMeans(across(all_of(sample_cols)), na.rm = TRUE)
  ) %>%
  filter(!is.na(avr_raw))

cat("📈 ESTADÍSTICAS DE ABUNDANCIA (PROXY RPM):\n")
cat("   - SNVs G>T con datos:", nrow(df_rpm_analysis), "\n")
cat("   - Abundancia mínima:", round(min(df_rpm_analysis$avr_raw, na.rm = TRUE), 6), "\n")
cat("   - Abundancia máxima:", round(max(df_rpm_analysis$avr_raw, na.rm = TRUE), 6), "\n")
cat("   - Abundancia mediana:", round(median(df_rpm_analysis$avr_raw, na.rm = TRUE), 6), "\n")

# Análisis de filtros de abundancia
abundance_thresholds <- c(0.001, 0.005, 0.01, 0.05, 0.1)
abundance_analysis <- data.frame(
  threshold = abundance_thresholds,
  snvs_passing = sapply(abundance_thresholds, function(t) sum(df_rpm_analysis$avr_raw > t)),
  percentage = sapply(abundance_thresholds, function(t) round((sum(df_rpm_analysis$avr_raw > t) / nrow(df_rpm_analysis)) * 100, 2))
)

cat("\n📊 FILTROS DE ABUNDANCIA:\n")
print(abundance_analysis)

# Recomendar umbral
recommended_threshold <- abundance_thresholds[max(which(abundance_analysis$percentage >= 20))]
if (is.na(recommended_threshold)) {
  recommended_threshold <- min(abundance_thresholds)
}

cat("\n✅ UMBRAL RECOMENDADO:", recommended_threshold, "\n")

# --- 9. ESTADO FINAL PARA GRÁFICAS ---
cat("\n🎨 9. ESTADO FINAL PARA GRÁFICAS\n")
cat("==================================\n")

# Aplicar todas las transformaciones
df_final <- df_main %>%
  handle_vaf_threshold() %>%
  split_mutations()

# Filtrar por abundancia
df_final_filtered <- df_final %>%
  filter(mutation_type == "G>T") %>%
  mutate(avr_raw = rowMeans(across(all_of(sample_cols)), na.rm = TRUE)) %>%
  filter(avr_raw > recommended_threshold)

cat("📊 DATOS FINALES PARA GRÁFICAS:\n")
cat("   - SNVs G>T totales:", sum(df_final$mutation_type == "G>T", na.rm = TRUE), "\n")
cat("   - SNVs G>T que pasan filtro abundancia:", nrow(df_final_filtered), "\n")
cat("   - miRNAs únicos en datos finales:", n_distinct(df_final_filtered$miRNA_name), "\n")
cat("   - Posiciones únicas en datos finales:", n_distinct(df_final_filtered$pos), "\n")

# Mostrar datos finales
cat("\n📋 DATOS FINALES:\n")
print(df_final_filtered %>% select(feature, miRNA_name, pos, avr_raw))

# --- 10. RESUMEN EJECUTIVO ---
cat("\n📋 10. RESUMEN EJECUTIVO\n")
cat("=========================\n")

cat("🎯 TRANSFORMACIONES APLICADAS:\n")
cat("   ✅ Split: Separación de mutaciones por tipo (CORREGIDO)\n")
cat("   ✅ Collapse: Agrupación por posición\n")
cat("   ✅ Filtro VAF > 50%: ", vaf_stats$nan_percentage, "% de valores convertidos a NaN\n")
cat("   ✅ Filtro abundancia: > ", recommended_threshold, "\n")

cat("\n📊 IMPACTO EN DATOS:\n")
cat("   - Datos iniciales:", nrow(df_main), "SNVs\n")
cat("   - Después de filtros:", nrow(df_final_filtered), "SNVs G>T\n")
cat("   - Reducción:", round((1 - nrow(df_final_filtered)/nrow(df_main)) * 100, 2), "%\n")
cat("   - miRNAs finales:", n_distinct(df_final_filtered$miRNA_name), "\n")

cat("\n✅ DIAGNÓSTICO CORREGIDO COMPLETADO\n")
cat("=====================================\n")









