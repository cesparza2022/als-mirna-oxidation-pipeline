# =============================================================================
# DIAGNÓSTICO ESPECÍFICO DE SPLIT Y COLLAPSE
# =============================================================================
# 
# Objetivo: Analizar paso a paso el split y collapse para entender exactamente
# qué está pasando con los miRNAs y SNVs
#
# Autor: César Esparza
# Fecha: 2025
# =============================================================================

# --- LIBRERÍAS ---
library(dplyr)
library(tidyr)
library(stringr)

# --- CONFIGURACIÓN ---
cat("🔍 DIAGNÓSTICO ESPECÍFICO DE SPLIT Y COLLAPSE\n")
cat("=============================================\n\n")

# --- 1. CARGAR DATOS INICIALES ---
cat("📊 1. DATOS INICIALES\n")
cat("====================\n")

# Cargar datos principales
df_main <- read.csv("outputs/tables/df_block_heatmap_clean.csv", stringsAsFactors = FALSE)
cat("📈 Datos iniciales:", nrow(df_main), "SNVs\n")
cat("📋 Columnas:", ncol(df_main), "\n")

# Mostrar ejemplos de features
cat("📋 Ejemplos de features:\n")
print(df_main$feature[1:10])

# Identificar columnas de muestra
sample_cols <- names(df_main)[!names(df_main) %in% c("feature")]
cat("🔍 Muestras:", length(sample_cols), "\n\n")

# --- 2. ANÁLISIS INICIAL DE MUTACIONES ---
cat("🎯 2. ANÁLISIS INICIAL DE MUTACIONES\n")
cat("====================================\n")

# Contar tipos de mutaciones
mutation_counts <- df_main %>%
  mutate(
    mutation_type = case_when(
      str_detect(feature, "_GT$") ~ "G>T",
      str_detect(feature, "_TC$") ~ "T>C", 
      str_detect(feature, "_GA$") ~ "G>A",
      str_detect(feature, "_CT$") ~ "C>T",
      str_detect(feature, "_AC$") ~ "A>C",
      str_detect(feature, "_TG$") ~ "T>G",
      TRUE ~ "Other"
    )
  ) %>%
  count(mutation_type, sort = TRUE)

cat("📊 Tipos de mutaciones:\n")
print(mutation_counts)

# Análisis específico de G>T
gt_initial <- df_main %>% filter(str_detect(feature, "_GT$"))
cat("\n🎯 MUTACIONES G>T INICIALES:\n")
cat("   - Total SNVs G>T:", nrow(gt_initial), "\n")
cat("   - miRNAs únicos:", length(unique(str_extract(gt_initial$feature, "^[^_]+"))), "\n")

# Mostrar todos los SNVs G>T
cat("\n📋 Todos los SNVs G>T:\n")
gt_details <- gt_initial %>%
  mutate(
    miRNA_name = str_extract(feature, "^[^_]+"),
    pos = as.integer(str_extract(feature, "_([0-9]+)_GT$", group = 1))
  ) %>%
  select(feature, miRNA_name, pos)

print(gt_details)

cat("\n")

# --- 3. FUNCIÓN SPLIT ---
cat("🔄 3. APLICANDO SPLIT\n")
cat("====================\n")

# Función split
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
      pos = as.integer(str_extract(feature, "_([0-9]+)_GT$", group = 1))
    )
}

# Aplicar split
df_split <- split_mutations(df_main)

cat("📊 DESPUÉS DEL SPLIT:\n")
cat("   - Total SNVs:", nrow(df_split), "\n")
cat("   - SNVs G>T:", sum(df_split$mutation_type == "G>T", na.rm = TRUE), "\n")
cat("   - miRNAs únicos:", length(unique(df_split$miRNA_name)), "\n")
cat("   - Posiciones únicas:", length(unique(df_split$pos)), "\n")

# Verificar posiciones extraídas
pos_na_count <- sum(is.na(df_split$pos))
cat("   - Posiciones NA:", pos_na_count, "\n")

if (pos_na_count > 0) {
  cat("❌ PROBLEMA: Hay posiciones NA\n")
  cat("🔍 Ejemplos de features problemáticos:\n")
  problem_features <- df_split$feature[is.na(df_split$pos)][1:5]
  for (f in problem_features) {
    cat("   -", f, "\n")
  }
} else {
  cat("✅ Posiciones extraídas correctamente\n")
}

# Mostrar datos G>T después del split
gt_split <- df_split %>% filter(mutation_type == "G>T")
cat("\n📋 SNVs G>T DESPUÉS DEL SPLIT:\n")
print(gt_split %>% select(feature, miRNA_name, pos, mutation_type))

cat("\n")

# --- 4. FUNCIÓN COLLAPSE ---
cat("🔄 4. APLICANDO COLLAPSE\n")
cat("========================\n")

# Función collapse
collapse_by_position <- function(data) {
  data %>%
    group_by(pos, mutation_type) %>%
    summarise(
      across(all_of(sample_cols), ~sum(., na.rm = TRUE)),
      count = n(),
      miRNA_name = first(miRNA_name),  # Mantener el primer miRNA_name
      .groups = "drop"
    )
}

# Aplicar collapse solo si el split funcionó
if (pos_na_count == 0) {
  df_collapsed <- collapse_by_position(df_split)
  
  cat("📊 DESPUÉS DEL COLLAPSE:\n")
  cat("   - Total SNVs:", nrow(df_collapsed), "\n")
  cat("   - SNVs G>T:", sum(df_collapsed$mutation_type == "G>T", na.rm = TRUE), "\n")
  cat("   - Posiciones únicas:", length(unique(df_collapsed$pos)), "\n")
  cat("   - miRNAs únicos:", length(unique(df_collapsed$miRNA_name)), "\n")
  
  # Mostrar datos collapsed
  gt_collapsed <- df_collapsed %>% filter(mutation_type == "G>T")
  cat("\n📋 SNVs G>T DESPUÉS DEL COLLAPSE:\n")
  print(gt_collapsed %>% select(pos, mutation_type, count, miRNA_name))
  
} else {
  cat("❌ No se puede aplicar collapse debido a posiciones NA\n")
}

cat("\n")

# --- 5. ANÁLISIS DETALLADO DE SPLIT/COLLAPSE ---
cat("🔍 5. ANÁLISIS DETALLADO DE SPLIT/COLLAPSE\n")
cat("==========================================\n")

if (pos_na_count == 0) {
  # Análisis de qué pasó con cada miRNA
  mirna_analysis <- gt_split %>%
    group_by(miRNA_name) %>%
    summarise(
      snvs_before = n(),
      positions = paste(sort(unique(pos)), collapse = ", "),
      .groups = "drop"
    ) %>%
    arrange(desc(snvs_before))
  
  cat("📊 ANÁLISIS POR miRNA (ANTES DEL COLLAPSE):\n")
  print(mirna_analysis)
  
  # Análisis de qué pasó con cada posición
  position_analysis <- gt_split %>%
    group_by(pos) %>%
    summarise(
      snvs_before = n(),
      mirnas = paste(sort(unique(miRNA_name)), collapse = ", "),
      .groups = "drop"
    ) %>%
    arrange(pos)
  
  cat("\n📊 ANÁLISIS POR POSICIÓN (ANTES DEL COLLAPSE):\n")
  print(position_analysis)
  
  # Análisis de qué pasó después del collapse
  if (nrow(df_collapsed) > 0) {
    cat("\n📊 ANÁLISIS DESPUÉS DEL COLLAPSE:\n")
    collapse_analysis <- df_collapsed %>%
      filter(mutation_type == "G>T") %>%
      select(pos, count, miRNA_name) %>%
      arrange(pos)
    
    print(collapse_analysis)
    
    # Calcular reducción
    total_before <- nrow(gt_split)
    total_after <- nrow(gt_collapsed)
    reduction <- ((total_before - total_after) / total_before) * 100
    
    cat("\n📈 IMPACTO DEL COLLAPSE:\n")
    cat("   - SNVs antes:", total_before, "\n")
    cat("   - SNVs después:", total_after, "\n")
    cat("   - Reducción:", round(reduction, 2), "%\n")
  }
}

cat("\n")

# --- 6. RESUMEN FINAL ---
cat("📋 6. RESUMEN FINAL\n")
cat("==================\n")

cat("📊 FLUJO DE DATOS:\n")
cat("   1. Datos iniciales:", nrow(df_main), "SNVs\n")
cat("   2. Después del split:", nrow(df_split), "SNVs\n")
if (pos_na_count == 0) {
  cat("   3. Después del collapse:", nrow(df_collapsed), "SNVs\n")
} else {
  cat("   3. Collapse: NO APLICADO (posiciones NA)\n")
}

cat("\n🧬 miRNAs:\n")
cat("   - Iniciales:", length(unique(str_extract(df_main$feature, "^[^_]+"))), "\n")
cat("   - Después del split:", length(unique(df_split$miRNA_name)), "\n")
if (pos_na_count == 0) {
  cat("   - Después del collapse:", length(unique(df_collapsed$miRNA_name)), "\n")
}

cat("\n📍 Posiciones:\n")
cat("   - Después del split:", length(unique(df_split$pos)), "\n")
if (pos_na_count == 0) {
  cat("   - Después del collapse:", length(unique(df_collapsed$pos)), "\n")
}

cat("\n✅ DIAGNÓSTICO DE SPLIT/COLLAPSE COMPLETADO\n")
cat("============================================\n")









