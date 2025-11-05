# =============================================================================
# DIAGNÓSTICO COMPLETO DE TRANSFORMACIÓN DE DATOS (CORREGIDO)
# =============================================================================
# 
# Objetivo: Desglosar paso a paso cómo se transforman los datos usando los
# archivos correctos de RPM y VAF para entender el input final de las gráficas
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
cat("🔍 DIAGNÓSTICO COMPLETO DE TRANSFORMACIÓN DE DATOS\n")
cat("==================================================\n\n")

# --- 1. CARGAR DATOS INICIALES ---
cat("📊 1. ESTADO INICIAL DE LOS DATOS\n")
cat("=================================\n")

# Cargar datos principales (VAF)
df_main <- read.csv("outputs/tables/df_block_heatmap_clean.csv", stringsAsFactors = FALSE)
cat("📈 Datos VAF cargados:", nrow(df_main), "SNVs\n")
cat("📋 Columnas VAF:", length(grep("_VAF$", names(df_main))), "\n")

# Cargar datos de RPM
df_rpm <- read.csv("organized/04_results/positional_analysis/als_rpm_data_processed.csv", stringsAsFactors = FALSE)
cat("📈 Datos RPM cargados:", nrow(df_rpm), "SNVs\n")
cat("📋 Columnas RPM:", length(grep("_RPM$", names(df_rpm))), "\n")

# Identificar columnas de muestra
sample_cols_vaf <- grep("_VAF$", names(df_main), value = TRUE)
sample_cols_rpm <- grep("_RPM$", names(df_rpm), value = TRUE)

cat("🔍 Muestras VAF:", length(sample_cols_vaf), "\n")
cat("🔍 Muestras RPM:", length(sample_cols_rpm), "\n\n")

# --- 2. ANÁLISIS INICIAL DE SNVs G>T ---
cat("🎯 2. ANÁLISIS INICIAL DE SNVs G>T\n")
cat("==================================\n")

# Filtrar solo mutaciones G>T en VAF
gt_vaf <- df_main %>% filter(str_detect(feature, "_GT$"))
cat("📊 SNVs G>T en VAF:", nrow(gt_vaf), "\n")

# Filtrar solo mutaciones G>T en RPM (usando el nombre correcto de la columna)
gt_rpm <- df_rpm %>% filter(str_detect(miRNA.name, ":GT$"))
cat("📊 SNVs G>T en RPM:", nrow(gt_rpm), "\n")

# Verificar coincidencia de miRNAs
mirnas_vaf <- unique(str_extract(gt_vaf$feature, "^[^_]+"))
mirnas_rpm <- unique(gt_rpm$miRNA.name)
cat("🧬 miRNAs únicos en VAF:", length(mirnas_vaf), "\n")
cat("🧬 miRNAs únicos en RPM:", length(mirnas_rpm), "\n")

# Intersección de miRNAs
common_mirnas <- intersect(mirnas_vaf, mirnas_rpm)
cat("🧬 miRNAs comunes:", length(common_mirnas), "\n\n")

# --- 3. FUNCIONES AUXILIARES ---
cat("🔧 3. FUNCIONES AUXILIARES\n")
cat("=========================\n")

# Función para manejar VAFs > 50% (convertir a NaN)
handle_vaf_threshold <- function(data, threshold = 0.5) {
  data %>%
    mutate(across(all_of(sample_cols_vaf), ~ifelse(. > threshold, NA, .)))
}

# Función split para separar mutaciones por tipo
split_mutations <- function(data) {
  data %>%
    mutate(
      mutation_type = case_when(
        str_detect(feature, "_GT$") ~ "G>T",
        str_detect(feature, "_TC$") ~ "T>C", 
        str_detect(feature, "_GA$") ~ "G>A",
        str_detect(feature, "_CT$") ~ "C>T",
        str_detect(feature, "_AC$") ~ "A>C",
        str_detect(feature, "_TG$") ~ "T>G",
        TRUE ~ "Other"
      ),
      miRNA_name = str_extract(feature, "^[^_]+"),
      pos = as.integer(str_extract(feature, "_([0-9]+)_[A-Z]+>$", group = 1))
    )
}

# Función collapse para agrupar por posición
collapse_by_position <- function(data) {
  data %>%
    group_by(pos, mutation_type) %>%
    summarise(
      across(all_of(sample_cols_vaf), ~sum(., na.rm = TRUE)),
      count = n(),
      .groups = "drop"
    )
}

cat("✅ Funciones auxiliares definidas\n\n")

# --- 4. APLICAR SPLIT ---
cat("🔄 4. APLICANDO SPLIT\n")
cat("====================\n")

# Aplicar split a datos VAF
gt_vaf_split <- split_mutations(gt_vaf)
cat("📊 SNVs G>T después del split:", nrow(gt_vaf_split), "\n")
cat("📍 Posiciones únicas:", length(unique(gt_vaf_split$pos)), "\n")
cat("🧬 miRNAs únicos:", length(unique(gt_vaf_split$miRNA_name)), "\n")

# Verificar que las posiciones se extrajeron correctamente
pos_na_count <- sum(is.na(gt_vaf_split$pos))
cat("⚠️ Posiciones NA:", pos_na_count, "\n")

if (pos_na_count > 0) {
  cat("🔍 Ejemplos de features problemáticos:\n")
  problem_features <- gt_vaf_split$feature[is.na(gt_vaf_split$pos)][1:5]
  for (f in problem_features) {
    cat("   -", f, "\n")
  }
}

cat("\n")

# --- 5. APLICAR COLLAPSE ---
cat("🔄 5. APLICANDO COLLAPSE\n")
cat("========================\n")

# Aplicar collapse solo si el split funcionó correctamente
if (pos_na_count == 0) {
  gt_vaf_collapsed <- collapse_by_position(gt_vaf_split)
  cat("📊 SNVs G>T después del collapse:", nrow(gt_vaf_collapsed), "\n")
  cat("📍 Posiciones únicas:", length(unique(gt_vaf_collapsed$pos)), "\n")
} else {
  cat("❌ No se puede aplicar collapse debido a posiciones NA\n")
  gt_vaf_collapsed <- gt_vaf_split
}

cat("\n")

# --- 6. APLICAR FILTRO VAF > 50% ---
cat("🔄 6. APLICANDO FILTRO VAF > 50%\n")
cat("================================\n")

# Aplicar filtro VAF > 50%
gt_vaf_filtered <- handle_vaf_threshold(gt_vaf_collapsed)

# Calcular estadísticas de NaN
total_values <- nrow(gt_vaf_filtered) * length(sample_cols_vaf)
nan_values <- sum(is.na(gt_vaf_filtered[sample_cols_vaf]))
nan_percentage <- (nan_values / total_values) * 100

cat("📊 SNVs G>T después del filtro VAF:", nrow(gt_vaf_filtered), "\n")
cat("🔢 Valores totales:", total_values, "\n")
cat("❌ Valores convertidos a NaN:", nan_values, "\n")
cat("📈 Porcentaje de NaN:", round(nan_percentage, 2), "%\n")

# Calcular NaN por SNV
nan_per_snv <- gt_vaf_filtered %>%
  rowwise() %>%
  mutate(nan_count = sum(is.na(c_across(all_of(sample_cols_vaf))))) %>%
  ungroup()

cat("📊 Estadísticas de NaN por SNV:\n")
cat("   - Promedio:", round(mean(nan_per_snv$nan_count), 2), "\n")
cat("   - Mediana:", median(nan_per_snv$nan_count), "\n")
cat("   - Máximo:", max(nan_per_snv$nan_count), "\n")
cat("   - Mínimo:", min(nan_per_snv$nan_count), "\n\n")

# --- 7. ANÁLISIS DE miRNAs CON MÁS G>T ---
cat("🧬 7. ANÁLISIS DE miRNAs CON MÁS G>T\n")
cat("====================================\n")

# Contar G>T por miRNA
mirna_gt_counts <- gt_vaf_split %>%
  group_by(miRNA_name) %>%
  summarise(
    gt_count = n(),
    unique_positions = length(unique(pos)),
    .groups = "drop"
  ) %>%
  arrange(desc(gt_count))

cat("📊 Top 10 miRNAs con más G>T:\n")
print(head(mirna_gt_counts, 10))

# Identificar miRNAs con G>T en región semilla (posiciones 2-8)
seed_region_gt <- gt_vaf_split %>%
  filter(pos >= 2 & pos <= 8) %>%
  group_by(miRNA_name) %>%
  summarise(
    seed_gt_count = n(),
    seed_positions = paste(sort(unique(pos)), collapse = ", "),
    .groups = "drop"
  ) %>%
  arrange(desc(seed_gt_count))

cat("\n📊 Top 10 miRNAs con más G>T en región semilla (pos 2-8):\n")
print(head(seed_region_gt, 10))

cat("\n")

# --- 8. ANÁLISIS DE FILTRO RPM > 1 ---
cat("📈 8. ANÁLISIS DE FILTRO RPM > 1\n")
cat("================================\n")

# Verificar datos de RPM
rpm_summary <- gt_rpm %>%
  select(all_of(sample_cols_rpm)) %>%
  summarise(
    mean_rpm = mean(rowMeans(across(all_of(sample_cols_rpm)), na.rm = TRUE), na.rm = TRUE),
    median_rpm = median(rowMeans(across(all_of(sample_cols_rpm)), na.rm = TRUE), na.rm = TRUE),
    max_rpm = max(rowMeans(across(all_of(sample_cols_rpm)), na.rm = TRUE), na.rm = TRUE),
    min_rpm = min(rowMeans(across(all_of(sample_cols_rpm)), na.rm = TRUE), na.rm = TRUE)
  )

cat("📊 Estadísticas de RPM:\n")
cat("   - Promedio:", round(rpm_summary$mean_rpm, 4), "\n")
cat("   - Mediana:", round(rpm_summary$median_rpm, 4), "\n")
cat("   - Máximo:", round(rpm_summary$max_rpm, 4), "\n")
cat("   - Mínimo:", round(rpm_summary$min_rpm, 4), "\n")

# Aplicar filtro RPM > 1
gt_rpm_filtered <- gt_rpm %>%
  mutate(mean_rpm = rowMeans(across(all_of(sample_cols_rpm)), na.rm = TRUE)) %>%
  filter(mean_rpm > 1)

cat("📊 SNVs G>T con RPM > 1:", nrow(gt_rpm_filtered), "\n")
cat("📈 Porcentaje que pasa el filtro:", round((nrow(gt_rpm_filtered) / nrow(gt_rpm)) * 100, 2), "%\n")

# Análisis de miRNAs que pasan el filtro RPM
mirnas_rpm_filtered <- unique(gt_rpm_filtered$miRNA.name)
cat("🧬 miRNAs que pasan filtro RPM:", length(mirnas_rpm_filtered), "\n")

cat("\n")

# --- 9. ESTADO FINAL PARA GRÁFICAS ---
cat("🎨 9. ESTADO FINAL PARA GRÁFICAS\n")
cat("===============================\n")

# Combinar datos VAF y RPM
final_data <- gt_vaf_filtered %>%
  left_join(
    gt_rpm_filtered %>% 
      select(miRNA.name, all_of(sample_cols_rpm)) %>%
      rename(miRNA_name = miRNA.name),
    by = "miRNA_name"
  )

cat("📊 Datos finales combinados:", nrow(final_data), "SNVs\n")
cat("🧬 miRNAs finales:", length(unique(final_data$miRNA_name)), "\n")
cat("📍 Posiciones finales:", length(unique(final_data$pos)), "\n")

# Verificar integridad de los datos
missing_rpm <- sum(is.na(final_data[sample_cols_rpm]))
cat("❌ Valores RPM faltantes:", missing_rpm, "\n")

cat("\n")

# --- 10. RESUMEN FINAL ---
cat("📋 10. RESUMEN FINAL\n")
cat("===================\n")

cat("📊 FLUJO DE DATOS:\n")
cat("   1. Datos VAF iniciales:", nrow(df_main), "SNVs\n")
cat("   2. SNVs G>T VAF:", nrow(gt_vaf), "SNVs\n")
cat("   3. Después del split:", nrow(gt_vaf_split), "SNVs\n")
cat("   4. Después del collapse:", nrow(gt_vaf_collapsed), "SNVs\n")
cat("   5. Después del filtro VAF > 50%:", nrow(gt_vaf_filtered), "SNVs\n")
cat("   6. SNVs G>T RPM:", nrow(gt_rpm), "SNVs\n")
cat("   7. SNVs RPM > 1:", nrow(gt_rpm_filtered), "SNVs\n")
cat("   8. Datos finales:", nrow(final_data), "SNVs\n\n")

cat("🧬 miRNAs:\n")
cat("   - VAF únicos:", length(mirnas_vaf), "\n")
cat("   - RPM únicos:", length(mirnas_rpm), "\n")
cat("   - Comunes:", length(common_mirnas), "\n")
cat("   - Finales:", length(unique(final_data$miRNA_name)), "\n\n")

cat("📈 CALIDAD DE DATOS:\n")
cat("   - VAFs convertidos a NaN:", round(nan_percentage, 2), "%\n")
cat("   - SNVs que pasan filtro RPM:", round((nrow(gt_rpm_filtered) / nrow(gt_rpm)) * 100, 2), "%\n")
cat("   - Valores RPM faltantes en datos finales:", missing_rpm, "\n\n")

cat("✅ DIAGNÓSTICO COMPLETADO\n")
cat("========================\n")
