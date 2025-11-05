# =============================================================================
# DIAGNÓSTICO DETALLADO DE TRANSFORMACIÓN DE DATOS
# =============================================================================
# 
# Objetivo: Desglosar paso a paso cómo se transforman los datos para entender
# el input final de las gráficas del análisis global de patrones de oxidación
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
cat("🔍 DIAGNÓSTICO DETALLADO DE TRANSFORMACIÓN DE DATOS\n")
cat("==================================================\n\n")

# --- 1. CARGAR DATOS INICIALES ---
cat("📊 1. ESTADO INICIAL DE LOS DATOS\n")
cat("=================================\n")

# Cargar datos principales
df_main <- read.csv("outputs/tables/df_block_heatmap_clean.csv", stringsAsFactors = FALSE)
df_vaf <- read.csv("outputs/tables/VAF_df.csv", stringsAsFactors = FALSE)

# Cargar datos de RPM si están disponibles
if (file.exists("outputs/tables/mirna_rpm_summary.csv")) {
  df_rpm <- read.csv("outputs/tables/mirna_rpm_summary.csv", stringsAsFactors = FALSE)
  cat("✅ Datos de RPM cargados\n")
} else {
  cat("⚠️ Datos de RPM no encontrados, usando datos principales\n")
  df_rpm <- df_main
}

# Extraer nombres de muestras
sample_cols <- names(df_main)[!names(df_main) %in% c("feature")]

cat("📈 DATOS INICIALES:\n")
cat("   - Filas principales:", nrow(df_main), "\n")
cat("   - Filas VAF:", nrow(df_vaf), "\n")
cat("   - Filas RPM:", nrow(df_rpm), "\n")
cat("   - Muestras:", length(sample_cols), "\n")
cat("   - Columnas de muestra:", paste(head(sample_cols, 3), collapse = ", "), "...\n\n")

# --- 2. ANÁLISIS INICIAL DE MUTACIONES ---
cat("🔍 2. ANÁLISIS INICIAL DE MUTACIONES\n")
cat("====================================\n")

# Contar tipos de mutaciones
mutation_analysis <- df_main %>%
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
    pos = as.integer(str_extract(feature, "_([0-9]+)_[A-Z]+>$", group = 1))
  ) %>%
  group_by(mutation_type) %>%
  summarise(
    count = n(),
    unique_miRNAs = n_distinct(miRNA_name),
    .groups = "drop"
  ) %>%
  arrange(desc(count))

cat("📊 MUTACIONES POR TIPO:\n")
print(mutation_analysis)

# Análisis específico de G>T
gt_analysis <- df_main %>%
  filter(str_detect(feature, "_GT$")) %>%
  mutate(
    miRNA_name = str_extract(feature, "^[^_]+"),
    pos = as.integer(str_extract(feature, "_([0-9]+)_GT$", group = 1))
  )

cat("\n🎯 MUTACIONES G>T:\n")
cat("   - Total SNVs G>T:", nrow(gt_analysis), "\n")
cat("   - miRNAs únicos con G>T:", n_distinct(gt_analysis$miRNA_name), "\n")
cat("   - Posiciones únicas:", n_distinct(gt_analysis$pos), "\n")

# Análisis de miRNAs con más G>T
miRNA_gt_counts <- gt_analysis %>%
  group_by(miRNA_name) %>%
  summarise(
    gt_count = n(),
    positions = n_distinct(pos),
    .groups = "drop"
  ) %>%
  arrange(desc(gt_count))

cat("\n📈 TOP 10 miRNAs CON MÁS MUTACIONES G>T:\n")
print(head(miRNA_gt_counts, 10))

# --- 3. ANÁLISIS DE REGIÓN SEMILLA ---
cat("\n🌱 3. ANÁLISIS DE REGIÓN SEMILLA (posiciones 2-8)\n")
cat("==================================================\n")

# Definir región semilla (posiciones 2-8)
seed_region_gt <- gt_analysis %>%
  filter(pos >= 2 & pos <= 8) %>%
  group_by(miRNA_name) %>%
  summarise(
    seed_gt_count = n(),
    seed_positions = n_distinct(pos),
    .groups = "drop"
  ) %>%
  arrange(desc(seed_gt_count))

cat("📊 MUTACIONES G>T EN REGIÓN SEMILLA:\n")
cat("   - SNVs en región semilla:", sum(seed_region_gt$seed_gt_count), "\n")
cat("   - miRNAs con G>T en semilla:", nrow(seed_region_gt), "\n")

cat("\n📈 TOP 10 miRNAs CON MÁS G>T EN REGIÓN SEMILLA:\n")
print(head(seed_region_gt, 10))

# --- 4. FUNCIONES DE TRANSFORMACIÓN ---
cat("\n🔧 4. FUNCIONES DE TRANSFORMACIÓN\n")
cat("==================================\n")

# Función para manejar VAFs > 50%
handle_vaf_threshold <- function(data, threshold = 0.5) {
  data %>%
    mutate(across(all_of(sample_cols), ~ifelse(. > threshold, NA, .)))
}

# Función split para separar mutaciones por tipo
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

cat("✅ Funciones definidas\n")

# --- 5. APLICAR SPLIT ---
cat("\n🔄 5. APLICANDO SPLIT\n")
cat("=====================\n")

df_split <- split_mutations(df_main)

cat("📊 DESPUÉS DEL SPLIT:\n")
cat("   - Filas totales:", nrow(df_split), "\n")
cat("   - Mutaciones G>T:", sum(df_split$mutation_type == "G>T", na.rm = TRUE), "\n")
cat("   - miRNAs únicos:", n_distinct(df_split$miRNA_name), "\n")

# Verificar si hay SNVs con múltiples mutaciones (esto sería raro pero verificar)
multi_mutation_check <- df_split %>%
  group_by(miRNA_name, pos) %>%
  summarise(
    mutation_count = n(),
    mutation_types = paste(unique(mutation_type), collapse = ", "),
    .groups = "drop"
  ) %>%
  filter(mutation_count > 1)

if (nrow(multi_mutation_check) > 0) {
  cat("⚠️ SNVs con múltiples tipos de mutación en la misma posición:\n")
  print(multi_mutation_check)
} else {
  cat("✅ No hay SNVs con múltiples tipos de mutación en la misma posición\n")
}

# --- 6. APLICAR COLLAPSE ---
cat("\n🔄 6. APLICANDO COLLAPSE\n")
cat("========================\n")

df_collapsed <- collapse_by_position(df_split)

cat("📊 DESPUÉS DEL COLLAPSE:\n")
cat("   - Filas totales:", nrow(df_collapsed), "\n")
cat("   - Mutaciones G>T:", sum(df_collapsed$mutation_type == "G>T", na.rm = TRUE), "\n")
cat("   - Posiciones únicas:", n_distinct(df_collapsed$pos), "\n")

# Mostrar resumen por tipo de mutación
collapse_summary <- df_collapsed %>%
  group_by(mutation_type) %>%
  summarise(
    positions = n(),
    total_count = sum(count),
    total_vaf = sum(total_vaf),
    .groups = "drop"
  ) %>%
  arrange(desc(total_vaf))

cat("\n📈 RESUMEN POR TIPO DE MUTACIÓN (COLLAPSED):\n")
print(collapse_summary)

# --- 7. APLICAR FILTRO VAF > 50% ---
cat("\n🔄 7. APLICANDO FILTRO VAF > 50%\n")
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

cat("\n📊 DISTRIBUCIÓN DE NaNs POR SNV:\n")
nan_distribution <- nan_per_snv %>%
  group_by(nan_count) %>%
  summarise(snv_count = n(), .groups = "drop") %>%
  arrange(desc(nan_count))

print(nan_distribution)

# --- 8. ANÁLISIS DE miRNAs CON MÁS G>T ---
cat("\n🎯 8. ANÁLISIS DE miRNAs CON MÁS G>T\n")
cat("=====================================\n")

# Combinar información de G>T con región semilla
miRNA_analysis <- gt_analysis %>%
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

cat("📈 TOP 15 miRNAs CON MÁS MUTACIONES G>T:\n")
print(head(miRNA_analysis, 15))

# Seleccionar miRNAs con más G>T (top 20)
top_miRNAs <- head(miRNA_analysis$miRNA_name, 20)
cat("\n🎯 miRNAs SELECCIONADOS (TOP 20):\n")
cat("   - miRNAs seleccionados:", length(top_miRNAs), "\n")
cat("   - Total G>T en seleccionados:", sum(miRNA_analysis$total_gt[1:20]), "\n")
cat("   - G>T en semilla en seleccionados:", sum(miRNA_analysis$seed_gt[1:20]), "\n")

# --- 9. ANÁLISIS DE RPM ---
cat("\n📊 9. ANÁLISIS DE RPM\n")
cat("=====================\n")

# Identificar columnas RPM
rpm_cols <- grep("_RPM$", names(df_rpm), value = TRUE)
if (length(rpm_cols) == 0) {
  rpm_cols <- sample_cols
  cat("⚠️ No se encontraron columnas RPM, usando columnas de muestra\n")
}

cat("📊 Columnas RPM identificadas:", length(rpm_cols), "\n")

# Calcular RPM promedio
df_rpm_analysis <- df_rpm %>%
  filter(str_detect(feature, "_GT$")) %>%
  mutate(
    miRNA_name = str_extract(feature, "^[^_]+"),
    pos = as.integer(str_extract(feature, "_([0-9]+)_GT$", group = 1)),
    avr_raw = rowMeans(across(all_of(rpm_cols)), na.rm = TRUE)
  ) %>%
  filter(!is.na(avr_raw))

cat("📈 ESTADÍSTICAS RPM:\n")
cat("   - SNVs G>T con datos RPM:", nrow(df_rpm_analysis), "\n")
cat("   - RPM mínimo:", round(min(df_rpm_analysis$avr_raw, na.rm = TRUE), 4), "\n")
cat("   - RPM máximo:", round(max(df_rpm_analysis$avr_raw, na.rm = TRUE), 4), "\n")
cat("   - RPM mediano:", round(median(df_rpm_analysis$avr_raw, na.rm = TRUE), 4), "\n")

# Análisis de filtro RPM > 1
rpm_filter_analysis <- df_rpm_analysis %>%
  mutate(
    passes_rpm_1 = avr_raw > 1,
    passes_rpm_0_5 = avr_raw > 0.5,
    passes_rpm_0_1 = avr_raw > 0.1
  ) %>%
  summarise(
    total_snvs = n(),
    rpm_gt_1 = sum(passes_rpm_1),
    rpm_gt_0_5 = sum(passes_rpm_0_5),
    rpm_gt_0_1 = sum(passes_rpm_0_1),
    pct_rpm_gt_1 = round((sum(passes_rpm_1) / n()) * 100, 2),
    pct_rpm_gt_0_5 = round((sum(passes_rpm_0_5) / n()) * 100, 2),
    pct_rpm_gt_0_1 = round((sum(passes_rpm_0_1) / n()) * 100, 2)
  )

cat("\n📊 FILTROS RPM:\n")
cat("   - Total SNVs:", rpm_filter_analysis$total_snvs, "\n")
cat("   - RPM > 1:", rpm_filter_analysis$rpm_gt_1, "(", rpm_filter_analysis$pct_rpm_gt_1, "%)\n")
cat("   - RPM > 0.5:", rpm_filter_analysis$rpm_gt_0_5, "(", rpm_filter_analysis$pct_rpm_gt_0_5, "%)\n")
cat("   - RPM > 0.1:", rpm_filter_analysis$rpm_gt_0_1, "(", rpm_filter_analysis$pct_rpm_gt_0_1, "%)\n")

# Recomendación de filtro
if (rpm_filter_analysis$pct_rpm_gt_1 < 10) {
  cat("⚠️ RECOMENDACIÓN: Usar filtro RPM > 0.5 (", rpm_filter_analysis$pct_rpm_gt_0_5, "% de datos)\n")
} else if (rpm_filter_analysis$pct_rpm_gt_1 < 20) {
  cat("⚠️ RECOMENDACIÓN: Usar filtro RPM > 0.5 (", rpm_filter_analysis$pct_rpm_gt_0_5, "% de datos)\n")
} else {
  cat("✅ RECOMENDACIÓN: Usar filtro RPM > 1 (", rpm_filter_analysis$pct_rpm_gt_1, "% de datos)\n")
}

# --- 10. ESTADO FINAL PARA GRÁFICAS ---
cat("\n🎨 10. ESTADO FINAL PARA GRÁFICAS\n")
cat("==================================\n")

# Aplicar todas las transformaciones
df_final <- df_main %>%
  handle_vaf_threshold() %>%
  split_mutations()

# Filtrar por miRNAs seleccionados
df_final_filtered <- df_final %>%
  filter(miRNA_name %in% top_miRNAs)

# Aplicar filtro RPM si es recomendado
if (rpm_filter_analysis$pct_rpm_gt_1 >= 20) {
  df_rpm_final <- df_rpm %>%
    filter(str_detect(feature, "_GT$")) %>%
    mutate(avr_raw = rowMeans(across(all_of(rpm_cols)), na.rm = TRUE)) %>%
    filter(avr_raw > 1) %>%
    mutate(avr = log2(avr_raw + 1))
  cat("✅ Aplicando filtro RPM > 1\n")
} else {
  df_rpm_final <- df_rpm %>%
    filter(str_detect(feature, "_GT$")) %>%
    mutate(avr_raw = rowMeans(across(all_of(rpm_cols)), na.rm = TRUE)) %>%
    filter(avr_raw > 0.5) %>%
    mutate(avr = log2(avr_raw + 1))
  cat("✅ Aplicando filtro RPM > 0.5\n")
}

cat("\n📊 DATOS FINALES PARA GRÁFICAS:\n")
cat("   - SNVs G>T totales:", sum(df_final$mutation_type == "G>T", na.rm = TRUE), "\n")
cat("   - SNVs G>T en miRNAs seleccionados:", sum(df_final_filtered$mutation_type == "G>T", na.rm = TRUE), "\n")
cat("   - SNVs G>T que pasan filtro RPM:", nrow(df_rpm_final), "\n")
cat("   - miRNAs únicos en datos finales:", n_distinct(df_rpm_final$miRNA_name), "\n")

# --- 11. RESUMEN EJECUTIVO ---
cat("\n📋 11. RESUMEN EJECUTIVO\n")
cat("========================\n")

cat("🎯 TRANSFORMACIONES APLICADAS:\n")
cat("   ✅ Split: Separación de mutaciones por tipo\n")
cat("   ✅ Collapse: Agrupación por posición\n")
cat("   ✅ Filtro VAF > 50%: ", vaf_stats$nan_percentage, "% de valores convertidos a NaN\n")
cat("   ✅ Selección miRNAs: Top 20 con más G>T\n")
cat("   ✅ Filtro RPM: ", ifelse(rpm_filter_analysis$pct_rpm_gt_1 >= 20, "> 1", "> 0.5"), "\n")

cat("\n📊 IMPACTO EN DATOS:\n")
cat("   - Datos iniciales:", nrow(df_main), "SNVs\n")
cat("   - Después de filtros:", nrow(df_rpm_final), "SNVs G>T\n")
cat("   - Reducción:", round((1 - nrow(df_rpm_final)/nrow(df_main)) * 100, 2), "%\n")
cat("   - miRNAs finales:", n_distinct(df_rpm_final$miRNA_name), "\n")

cat("\n✅ DIAGNÓSTICO COMPLETADO\n")
cat("==========================\n")









