#!/usr/bin/env Rscript

# =============================================================================
# CONTEO DE SNVs G>T DESPUÉS DE APLICAR FILTROS
# =============================================================================
# Este script cuenta cuántos SNVs G>T quedan después de aplicar los filtros
# que se usaron en los análisis de heatmaps.

library(dplyr)
library(readr)
library(stringr)
library(tidyr)

cat("=== CONTEO DE SNVs G>T DESPUÉS DE FILTROS ===\n\n")

# --- PASO 1: Cargar datos ---
cat("PASO 1: Cargando datos\n")
cat("==========================================\n")

# Cargar datos principales
df_main <- read_tsv("results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt", show_col_types = FALSE)
cat(paste0("  - Archivo cargado: miRNA_count.Q33.txt\n"))
cat(paste0("  - Dimensiones originales: ", nrow(df_main), " filas x ", ncol(df_main), " columnas\n"))

# Remover primera fila (metadatos)
df_main <- df_main[-1, ]
cat(paste0("  - Después de remover metadatos: ", nrow(df_main), " filas x ", ncol(df_main), " columnas\n"))

# Identificar columnas
sample_cols <- names(df_main)[!names(df_main) %in% c("miRNA name", "pos:mut")]
als_samples <- sample_cols[str_detect(sample_cols, "Magen-ALS")]
control_samples <- sample_cols[str_detect(sample_cols, "Magen-control")]

cat(paste0("  - Muestras totales: ", length(sample_cols), "\n"))
cat(paste0("  - Muestras ALS: ", length(als_samples), "\n"))
cat(paste0("  - Muestras Control: ", length(control_samples), "\n\n"))

# --- PASO 2: Filtrar solo SNVs G>T ---
cat("PASO 2: Filtrando SNVs G>T\n")
cat("==========================================\n")

df_gt <- df_main %>%
  filter(str_detect(`pos:mut`, "GT"))

total_gt_snvs <- nrow(df_gt)
cat(paste0("  - SNVs G>T totales (sin filtros): ", total_gt_snvs, "\n"))

# Mostrar distribución por posición
pos_dist <- df_gt %>%
  mutate(pos = as.numeric(str_extract(`pos:mut`, "^[0-9]+"))) %>%
  count(pos, name = "count") %>%
  arrange(pos)

cat("  - Distribución por posición:\n")
print(pos_dist)
cat("\n")

# --- PASO 3: Aplicar filtro de región semilla (posiciones 2-8) ---
cat("PASO 3: Aplicando filtro de región semilla (posiciones 2-8)\n")
cat("==========================================\n")

df_gt_seed <- df_gt %>%
  mutate(pos = as.numeric(str_extract(`pos:mut`, "^[0-9]+"))) %>%
  filter(pos >= 2 & pos <= 8)

seed_gt_snvs <- nrow(df_gt_seed)
cat(paste0("  - SNVs G>T en región semilla (pos 2-8): ", seed_gt_snvs, "\n"))
cat(paste0("  - Reducción: ", total_gt_snvs - seed_gt_snvs, " SNVs eliminados (", 
           round(100 * (total_gt_snvs - seed_gt_snvs) / total_gt_snvs, 1), "%)\n"))

# Distribución en región semilla
seed_pos_dist <- df_gt_seed %>%
  count(pos, name = "count") %>%
  arrange(pos)

cat("  - Distribución en región semilla:\n")
print(seed_pos_dist)
cat("\n")

# --- PASO 4: Simular filtros de cobertura (min_total) ---
cat("PASO 4: Simulando filtros de cobertura\n")
cat("==========================================\n")

# Nota: Como no tenemos columnas (PM+1MM+2MM) en este archivo,
# simularemos el filtro basado en los conteos PM disponibles

# Umbrales típicos usados en los análisis
min_total_values <- c(0, 10, 200, 500)

for (min_total in min_total_values) {
  # Para cada SNV, contar en cuántas muestras tiene conteo >= min_total
  snv_coverage <- df_gt_seed %>%
    select(`miRNA name`, `pos:mut`, all_of(sample_cols)) %>%
    pivot_longer(cols = all_of(sample_cols), names_to = "sample", values_to = "count") %>%
    mutate(count = as.numeric(count)) %>%
    group_by(`miRNA name`, `pos:mut`) %>%
    summarise(
      samples_with_coverage = sum(count >= min_total, na.rm = TRUE),
      total_samples = n(),
      .groups = "drop"
    ) %>%
    filter(samples_with_coverage > 0)  # Al menos una muestra con cobertura suficiente
  
  snvs_after_coverage <- nrow(snv_coverage)
  cat(paste0("  - Con min_total = ", min_total, ": ", snvs_after_coverage, " SNVs restantes\n"))
}

cat("\n")

# --- PASO 5: Simular filtros de VAF ---
cat("PASO 5: Simulando filtros de VAF\n")
cat("==========================================\n")

# Como no tenemos VAFs reales, usaremos los conteos PM como proxy
# y simularemos diferentes umbrales de "detección"

vaf_thresholds <- c(0, 0.001, 0.005, 0.01)  # 0%, 0.1%, 0.5%, 1%

for (vaf_thresh in vaf_thresholds) {
  # Simular VAF usando conteos PM (asumiendo que son proporcionales)
  snv_detection <- df_gt_seed %>%
    select(`miRNA name`, `pos:mut`, all_of(sample_cols)) %>%
    pivot_longer(cols = all_of(sample_cols), names_to = "sample", values_to = "count") %>%
    mutate(
      count = as.numeric(count),
      # Simular VAF como conteo normalizado (muy simplificado)
      simulated_vaf = count / (count + 1000)  # Normalización arbitraria
    ) %>%
    group_by(`miRNA name`, `pos:mut`) %>%
    summarise(
      samples_detected = sum(simulated_vaf >= vaf_thresh, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    filter(samples_detected > 0)
  
  snvs_after_vaf <- nrow(snv_detection)
  cat(paste0("  - Con VAF >= ", vaf_thresh, " (", vaf_thresh*100, "%): ", snvs_after_vaf, " SNVs restantes\n"))
}

cat("\n")

# --- PASO 6: Resumen final ---
cat("PASO 6: Resumen final\n")
cat("==========================================\n")

cat("FILTROS APLICADOS EN LOS ANÁLISIS:\n")
cat("1. Tipo de mutación: G>T únicamente\n")
cat("2. Región: Semilla (posiciones 2-8)\n")
cat("3. Cobertura: min_total = 500 (típico en heatmaps)\n")
cat("4. VAF: >= 0.5% (vaf_min = 0.005)\n")
cat("5. RPM: >= 1.0 (rpm_gate = 1.0)\n")
cat("6. Prevalencia: >= 20% de muestras (prev_gate = 0.20)\n\n")

# Estimación conservadora basada en los filtros típicos
estimated_remaining <- df_gt_seed %>%
  select(`miRNA name`, `pos:mut`, all_of(sample_cols)) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "sample", values_to = "count") %>%
  mutate(count = as.numeric(count)) %>%
  group_by(`miRNA name`, `pos:mut`) %>%
  summarise(
    samples_with_high_coverage = sum(count >= 500, na.rm = TRUE),
    total_samples = n(),
    max_count = max(count, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(
    samples_with_high_coverage >= 1,  # Al menos una muestra con cobertura suficiente
    max_count >= 5  # Al menos 5 conteos en alguna muestra (proxy para VAF)
  )

final_count <- nrow(estimated_remaining)
cat(paste0("ESTIMACIÓN CONSERVADORA DE SNVs G>T RESTANTES: ", final_count, "\n"))
cat(paste0("Reducción total: ", total_gt_snvs - final_count, " SNVs eliminados (", 
           round(100 * (total_gt_snvs - final_count) / total_gt_snvs, 1), "%)\n"))

# Mostrar algunos ejemplos de SNVs que pasan los filtros
if (final_count > 0) {
  cat("\nEjemplos de SNVs que pasan los filtros:\n")
  print(head(estimated_remaining, 10))
}

cat("\n=== ANÁLISIS COMPLETADO ===\n")










