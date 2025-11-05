# =============================================================================
# FUNCIONES DEL PIPELINE DEFINITIVO - Análisis de SNVs en miRNAs para ALS
# =============================================================================
# Autor: César Esparza
# Fecha: 2024
# Descripción: Funciones auxiliares para el pipeline de análisis de miRNAs
# =============================================================================

# Cargar librerías necesarias
library(tidyverse)
library(stringr)
library(dplyr)

# =============================================================================
# FUNCIÓN 1: SPLIT-COLLAPSE
# =============================================================================
# Descripción: Separa mutaciones múltiples y colapsa duplicados
# Input: data.frame con columnas miRNA.name, pos.mut, y columnas de muestras
# Output: data.frame procesado con split-collapse aplicado

apply_split_collapse <- function(data) {
  
  cat("=== APLICANDO SPLIT-COLLAPSE ===\n")
  
  # Verificar columnas requeridas
  required_cols <- c("miRNA name", "pos:mut")
  if (!all(required_cols %in% colnames(data))) {
    stop("Error: Faltan columnas requeridas: miRNA name, pos:mut")
  }
  
  # Identificar tipos de columnas según la estructura real del dataset
  meta_cols <- c("miRNA name", "pos:mut")
  total_cols <- names(data)[grepl("\\(PM\\+1MM\\+2MM\\)$", names(data))]
  count_cols <- names(data)[!names(data) %in% meta_cols & !names(data) %in% total_cols]
  
  cat("Columnas identificadas:\n")
  cat("  - Count columns (SNV counts):", length(count_cols), "\n")
  cat("  - Total columns (miRNA totals):", length(total_cols), "\n")
  
  cat("Paso 1: Separando mutaciones múltiples...\n")
  cat("Filas originales:", nrow(data), "\n")
  
  # Separar filas con múltiples mutaciones
  split_data <- data %>%
    separate_rows(`pos:mut`, sep = ",") %>%
    mutate(`pos:mut` = str_trim(`pos:mut`))
  
  cat("Filas después del split:", nrow(split_data), "\n")
  
  cat("Paso 2: Aplicando collapse...\n")
  
  # Aplicar collapse: sumar cuentas por miRNA + posición + mutación
  # NO recalcular totales - mantener los originales
  collapsed_data <- split_data %>%
    group_by(`miRNA name`, `pos:mut`) %>%
    summarise(
      across(all_of(count_cols), ~sum(as.numeric(.x), na.rm = TRUE)),
      across(all_of(total_cols), ~first(.x)),  # Mantener el primer total (deberían ser iguales)
      .groups = "drop"
    )
  
  cat("Filas después del collapse:", nrow(collapsed_data), "\n")
  cat("SNVs únicos:", nrow(collapsed_data), "\n")
  cat("miRNAs únicos:", length(unique(collapsed_data$`miRNA name`)), "\n")
  
  return(collapsed_data)
}

# =============================================================================
# FUNCIÓN 2: CÁLCULO DE VAFs
# =============================================================================
# Descripción: Calcula Variant Allele Frequency para cada muestra
# Input: data.frame con columnas de muestras y total
# Output: data.frame con VAFs calculadas

calculate_vafs <- function(data) {
  
  cat("=== CALCULANDO VAFs ===\n")
  
  # Identificar tipos de columnas según la estructura real del dataset
  meta_cols <- c("miRNA name", "pos:mut")
  total_cols <- names(data)[grepl("\\(PM\\+1MM\\+2MM\\)$", names(data))]
  count_cols <- names(data)[!names(data) %in% meta_cols & !names(data) %in% total_cols]
  
  cat("Columnas identificadas:\n")
  cat("  - Count columns (SNV counts):", length(count_cols), "\n")
  cat("  - Total columns (miRNA totals):", length(total_cols), "\n")
  
  # Verificar que tenemos columnas de totales
  if (length(total_cols) == 0) {
    stop("Error: No se encontraron columnas de totales (PM+1MM+2MM)")
  }
  
  # Verificar que tenemos columnas de cuentas
  if (length(count_cols) == 0) {
    stop("Error: No se encontraron columnas de cuentas de SNVs")
  }
  
  cat("Calculando VAFs para", length(count_cols), "muestras...\n")
  
  # Calcular VAFs: count / total para cada muestra
  vaf_data <- data
  
  for (i in 1:length(count_cols)) {
    count_col <- count_cols[i]
    total_col <- total_cols[i]
    
    if (total_col %in% names(data)) {
      # Convertir a numérico y manejar valores faltantes
      count_values <- as.numeric(data[[count_col]])
      total_values <- as.numeric(data[[total_col]])
      
      # Reemplazar NA con 0
      count_values[is.na(count_values)] <- 0
      total_values[is.na(total_values)] <- 0
      
      vaf_col <- paste0("VAF_", count_col)
      vaf_data[[vaf_col]] <- ifelse(
        total_values > 0, 
        count_values / total_values, 
        0
      )
    } else {
      warning(paste("No se encontró columna de total correspondiente para", count_col))
    }
  }
  
  cat("VAFs calculados para", nrow(vaf_data), "SNVs\n")
  
  return(vaf_data)
}

# =============================================================================
# FUNCIÓN 3: FILTRADO DE VAFs ALTAS
# =============================================================================
# Descripción: Convierte VAFs > threshold a NaN
# Input: data.frame con VAFs, threshold (default 0.5)
# Output: data.frame con VAFs filtradas

filter_high_vafs <- function(vaf_data, threshold = 0.5) {
  
  cat("=== FILTRANDO VAFs >", threshold, "===\n")
  
  # Identificar columnas VAF
  vaf_cols <- colnames(vaf_data)[str_detect(colnames(vaf_data), "^VAF_")]
  
  if (length(vaf_cols) == 0) {
    stop("Error: No se encontraron columnas VAF")
  }
  
  cat("Filtrando", length(vaf_cols), "columnas VAF\n")
  
  # Aplicar filtro VAF > threshold (convertir a NaN)
  filtered_data <- vaf_data %>%
    mutate(across(all_of(vaf_cols), 
                  ~ifelse(.x > threshold, NA, .x)))
  
  # Cuantificar NaNs
  nan_summary <- filtered_data %>%
    summarise(
      across(all_of(vaf_cols), 
             ~sum(is.na(.x)), 
             .names = "NaN_{str_remove(.col, 'VAF_')}")
    ) %>%
    pivot_longer(everything(), names_to = "sample", values_to = "n_nans") %>%
    mutate(sample = str_remove(sample, "NaN_"))
  
  cat("Total de NaNs generados:", sum(nan_summary$n_nans), "\n")
  cat("Promedio de NaNs por muestra:", round(mean(nan_summary$n_nans), 2), "\n")
  cat("Máximo de NaNs en una muestra:", max(nan_summary$n_nans), "\n")
  
  return(filtered_data)
}

# =============================================================================
# FUNCIÓN 4: ANÁLISIS DE COBERTURA DE SNVs
# =============================================================================
# Descripción: Calcula cobertura de cada SNV (número de muestras sin NaN)
# Input: data.frame con VAFs filtradas
# Output: data.frame con métricas de cobertura

analyze_snv_coverage <- function(filtered_data) {
  
  cat("=== ANALIZANDO COBERTURA DE SNVs ===\n")
  
  # Identificar columnas VAF
  vaf_cols <- colnames(filtered_data)[str_detect(colnames(filtered_data), "^VAF_")]
  
  # Calcular cobertura por SNV
  snv_coverage <- filtered_data %>%
    mutate(
      n_samples = rowSums(!is.na(select(., all_of(vaf_cols)))),
      coverage_pct = (n_samples / length(vaf_cols)) * 100
    ) %>%
    select(miRNA.name, pos.mut, n_samples, coverage_pct) %>%
    arrange(desc(n_samples))
  
  cat("SNVs analizados:", nrow(snv_coverage), "\n")
  cat("Cobertura promedio:", round(mean(snv_coverage$coverage_pct), 2), "%\n")
  cat("SNVs con cobertura > 80%:", sum(snv_coverage$coverage_pct > 80), "\n")
  
  return(snv_coverage)
}

# =============================================================================
# FUNCIÓN 5: ANÁLISIS DE miRNAs MÁS MUTADOS
# =============================================================================
# Descripción: Identifica miRNAs con más SNVs y más mutaciones G>T
# Input: data.frame procesado
# Output: list con conteos de miRNAs

analyze_top_mirnas <- function(data) {
  
  cat("=== ANALIZANDO miRNAs MÁS MUTADOS ===\n")
  
  # miRNAs con más SNVs
  mirna_snv_count <- data %>%
    count(miRNA.name, sort = TRUE)
  
  # miRNAs con más mutaciones G>T
  mirna_gt_count <- data %>%
    filter(str_detect(pos.mut, ":GT")) %>%
    count(miRNA.name, sort = TRUE)
  
  cat("miRNAs únicos con SNVs:", nrow(mirna_snv_count), "\n")
  cat("miRNAs únicos con mutaciones G>T:", nrow(mirna_gt_count), "\n")
  cat("Top miRNA por SNVs:", mirna_snv_count$miRNA.name[1], "(", mirna_snv_count$n[1], "SNVs)\n")
  cat("Top miRNA por G>T:", mirna_gt_count$miRNA.name[1], "(", mirna_gt_count$n[1], "mutaciones G>T)\n")
  
  return(list(
    snv_counts = mirna_snv_count,
    gt_counts = mirna_gt_count
  ))
}

# =============================================================================
# FUNCIÓN 6: ANÁLISIS POR POSICIONES
# =============================================================================
# Descripción: Analiza distribución de mutaciones por posición
# Input: data.frame procesado
# Output: list con análisis por posición

analyze_positions <- function(data) {
  
  cat("=== ANALIZANDO POSICIONES ===\n")
  
  # Extraer posiciones
  position_data <- data %>%
    mutate(position = as.numeric(str_extract(pos.mut, "^\\d+"))) %>%
    filter(!is.na(position))
  
  # Posiciones más mutadas
  position_counts <- position_data %>%
    count(position, sort = TRUE)
  
  # Posiciones con más mutaciones G>T
  position_gt_counts <- position_data %>%
    filter(str_detect(pos.mut, ":GT")) %>%
    count(position, sort = TRUE)
  
  cat("Posiciones únicas:", nrow(position_counts), "\n")
  cat("Rango de posiciones:", min(position_data$position), "-", max(position_data$position), "\n")
  cat("Top posición por SNVs:", position_counts$position[1], "(", position_counts$n[1], "SNVs)\n")
  cat("Top posición por G>T:", position_gt_counts$position[1], "(", position_gt_counts$n[1], "mutaciones G>T)\n")
  
  return(list(
    position_data = position_data,
    position_counts = position_counts,
    position_gt_counts = position_gt_counts
  ))
}

# =============================================================================
# FUNCIÓN 7: ANÁLISIS POR POSICIÓN Y miRNA
# =============================================================================
# Descripción: Para cada posición, identifica miRNAs con más mutaciones
# Input: data.frame con información de posición
# Output: data.frame con análisis por posición-miRNA

analyze_position_mirna <- function(position_data) {
  
  cat("=== ANALIZANDO POSICIÓN-MIRNA ===\n")
  
  # Para cada posición, identificar miRNAs con más mutaciones
  position_mirna_analysis <- position_data %>%
    group_by(position) %>%
    count(miRNA.name, sort = TRUE) %>%
    slice_head(n = 5) %>%
    ungroup()
  
  # Análisis específico para mutaciones G>T por posición
  position_gt_mirna <- position_data %>%
    filter(str_detect(pos.mut, ":GT")) %>%
    group_by(position) %>%
    count(miRNA.name, sort = TRUE) %>%
    slice_head(n = 3) %>%
    ungroup()
  
  cat("Combinaciones posición-miRNA analizadas:", nrow(position_mirna_analysis), "\n")
  cat("Combinaciones posición-miRNA G>T:", nrow(position_gt_mirna), "\n")
  
  return(list(
    position_mirna = position_mirna_analysis,
    position_gt_mirna = position_gt_mirna
  ))
}

# =============================================================================
# FUNCIÓN 8: IDENTIFICACIÓN DE GRUPOS
# =============================================================================
# Descripción: Identifica grupos ALS vs Control basado en nombres de muestras
# Input: vector de nombres de muestras
# Output: data.frame con grupos asignados

identify_groups <- function(sample_names) {
  
  cat("=== IDENTIFICANDO GRUPOS ===\n")
  
  # Función para identificar grupos (ajustar según metadatos reales)
  groups <- case_when(
    str_detect(sample_names, "ALS|als") ~ "ALS",
    str_detect(sample_names, "Control|control|CTRL|ctrl") ~ "Control",
    TRUE ~ "Unknown"
  )
  
  # Crear data.frame con grupos
  group_data <- data.frame(
    sample = sample_names,
    group = groups
  )
  
  # Mostrar distribución de grupos
  group_summary <- group_data %>%
    count(group, sort = TRUE)
  
  cat("Distribución de grupos:\n")
  print(group_summary)
  
  return(group_data)
}

# =============================================================================
# FUNCIÓN 9: COMPARACIONES ALS vs CONTROL
# =============================================================================
# Descripción: Calcula estadísticas comparativas entre grupos
# Input: data.frame con VAFs y grupos
# Output: data.frame con comparaciones

compare_groups <- function(filtered_data, group_data) {
  
  cat("=== COMPARANDO GRUPOS ALS vs CONTROL ===\n")
  
  # Identificar columnas VAF
  vaf_cols <- colnames(filtered_data)[str_detect(colnames(filtered_data), "^VAF_")]
  
  # Calcular estadísticas por grupo
  group_stats <- filtered_data %>%
    select(miRNA.name, pos.mut, all_of(vaf_cols)) %>%
    pivot_longer(cols = all_of(vaf_cols), 
                 names_to = "sample", 
                 values_to = "vaf") %>%
    mutate(sample = str_remove(sample, "VAF_")) %>%
    left_join(group_data, by = "sample") %>%
    filter(group != "Unknown") %>%
    group_by(miRNA.name, pos.mut, group) %>%
    summarise(
      mean_vaf = mean(vaf, na.rm = TRUE),
      median_vaf = median(vaf, na.rm = TRUE),
      sd_vaf = sd(vaf, na.rm = TRUE),
      n_samples = sum(!is.na(vaf)),
      .groups = "drop"
    )
  
  cat("Comparaciones calculadas para", nrow(group_stats), "SNVs\n")
  cat("Grupos incluidos:", unique(group_stats$group), "\n")
  
  return(group_stats)
}

# =============================================================================
# FUNCIÓN 10: RESUMEN EJECUTIVO
# =============================================================================
# Descripción: Genera resumen ejecutivo del análisis
# Input: múltiples objetos de análisis
# Output: list con resumen

generate_summary <- function(raw_data, processed_data, filtered_data, nan_summary) {
  
  cat("=== GENERANDO RESUMEN EJECUTIVO ===\n")
  
  summary_stats <- list(
    "Datos originales" = list(
      "SNVs" = nrow(raw_data),
      "miRNAs" = length(unique(raw_data$miRNA.name)),
      "Muestras" = ncol(raw_data) - 3
    ),
    "Después de split-collapse" = list(
      "SNVs" = nrow(processed_data),
      "miRNAs" = length(unique(processed_data$miRNA.name)),
      "Muestras" = ncol(processed_data) - 3
    ),
    "Después de filtrado VAF" = list(
      "SNVs" = nrow(filtered_data),
      "Total NaNs" = sum(nan_summary$n_nans),
      "Promedio NaNs/muestra" = round(mean(nan_summary$n_nans), 2),
      "Máximo NaNs/muestra" = max(nan_summary$n_nans)
    )
  )
  
  return(summary_stats)
}

# =============================================================================
# FUNCIÓN 11: GUARDAR RESULTADOS
# =============================================================================
# Descripción: Guarda todos los resultados del análisis
# Input: múltiples objetos de análisis
# Output: archivos guardados

save_analysis_results <- function(processed_data, filtered_data, nan_summary, 
                                 snv_coverage, mirna_analysis, position_analysis, 
                                 group_stats, summary_stats) {
  
  cat("=== GUARDANDO RESULTADOS ===\n")
  
  # Crear directorios si no existen
  dir.create("outputs", showWarnings = FALSE)
  dir.create("figures", showWarnings = FALSE)
  dir.create("tables", showWarnings = FALSE)
  
  # Guardar datos procesados
  write_tsv(processed_data, "outputs/01_data_after_split_collapse.tsv")
  write_tsv(filtered_data, "outputs/02_data_after_vaf_filtering.tsv")
  write_tsv(nan_summary, "outputs/03_nan_summary.tsv")
  write_tsv(snv_coverage, "outputs/04_snv_coverage.tsv")
  write_tsv(mirna_analysis$snv_counts, "outputs/05_mirna_snv_counts.tsv")
  write_tsv(mirna_analysis$gt_counts, "outputs/06_mirna_gt_counts.tsv")
  write_tsv(position_analysis$position_counts, "outputs/07_position_counts.tsv")
  write_tsv(position_analysis$position_gt_counts, "outputs/08_position_gt_counts.tsv")
  write_tsv(group_stats, "outputs/09_group_comparisons.tsv")
  
  # Guardar resumen como JSON
  jsonlite::write_json(summary_stats, "outputs/10_summary_stats.json", pretty = TRUE)
  
  cat("Archivos guardados en carpeta 'outputs/'\n")
  cat("Total de archivos:", length(list.files("outputs/")), "\n")
}

# =============================================================================
# FUNCIÓN PRINCIPAL: PIPELINE COMPLETO
# =============================================================================
# Descripción: Ejecuta el pipeline completo de análisis inicial
# Input: ruta al archivo de datos
# Output: análisis completo ejecutado

run_initial_analysis <- function(data_path) {
  
  cat("=== INICIANDO PIPELINE DE ANÁLISIS INICIAL ===\n")
  cat("Archivo de datos:", data_path, "\n\n")
  
  # Cargar datos
  raw_data <- read_tsv(data_path, col_types = cols(.default = "c"))
  
  # Aplicar pipeline
  processed_data <- apply_split_collapse(raw_data)
  vaf_data <- calculate_vafs(processed_data)
  filter_results <- filter_high_vafs(vaf_data)
  filtered_data <- filter_results$filtered_data
  nan_summary <- filter_results$nan_summary
  
  # Análisis adicionales
  snv_coverage <- analyze_snv_coverage(filtered_data)
  mirna_analysis <- analyze_top_mirnas(filtered_data)
  position_analysis <- analyze_positions(filtered_data)
  position_mirna_analysis <- analyze_position_mirna(position_analysis$position_data)
  
  # Identificar grupos y comparar
  sample_names <- str_remove(colnames(filtered_data)[str_detect(colnames(filtered_data), "^VAF_")], "VAF_")
  group_data <- identify_groups(sample_names)
  group_stats <- compare_groups(filtered_data, group_data)
  
  # Generar resumen
  summary_stats <- generate_summary(raw_data, processed_data, filtered_data, nan_summary)
  
  # Guardar resultados
  save_analysis_results(processed_data, filtered_data, nan_summary, 
                       snv_coverage, mirna_analysis, position_analysis, 
                       group_stats, summary_stats)
  
  cat("\n=== PIPELINE COMPLETADO ===\n")
  
  return(list(
    raw_data = raw_data,
    processed_data = processed_data,
    filtered_data = filtered_data,
    nan_summary = nan_summary,
    snv_coverage = snv_coverage,
    mirna_analysis = mirna_analysis,
    position_analysis = position_analysis,
    position_mirna_analysis = position_mirna_analysis,
    group_data = group_data,
    group_stats = group_stats,
    summary_stats = summary_stats
  ))
}

# =============================================================================
# FIN DEL ARCHIVO
# =============================================================================
