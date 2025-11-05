#!/usr/bin/env Rscript

# =============================================================================
# FUNCIONES PARA PROCESAMIENTO DE SNVs EN DATASET DE miRNAs
# =============================================================================
# 
# Este script contiene funciones para:
# 1. Separar SNVs múltiples en filas individuales
# 2. Sumar conteos de SNVs del mismo miRNA en la misma muestra
# 3. Mantener totales sin sumar
#
# Autor: Análisis 8OG
# Fecha: 2025-01-23
# =============================================================================

library(dplyr)
library(stringr)
library(tidyr)

# =============================================================================
# FUNCIÓN 1: SEPARAR SNVs MÚLTIPLES
# =============================================================================
# 
# Convierte filas con múltiples SNVs (ej: "1:TC,2:GT") en filas separadas
# Mantiene las cuentas y totales intactos
#
# Parámetros:
#   df: data.frame con columnas miRNA name, pos:mut, y columnas de conteos
#   snv_cols: vector con nombres de columnas de conteos de SNVs
#   total_cols: vector con nombres de columnas de totales
#
# Retorna:
#   data.frame expandido con una fila por SNV individual
# =============================================================================

separate_multiple_snvs <- function(df, snv_cols, total_cols) {
  cat("🔧 Separando SNVs múltiples...\n")
  
  # Filtrar solo filas con SNVs (no PM)
  df_snvs <- df %>% 
    filter(df[["pos:mut"]] != "PM")
  
  # Identificar filas con múltiples SNVs (contienen coma)
  multiple_snv_rows <- df_snvs %>% 
    filter(str_detect(df[["pos:mut"]], ","))
  
  cat("   📊 Filas con SNVs múltiples encontradas:", nrow(multiple_snv_rows), "\n")
  
  if (nrow(multiple_snv_rows) == 0) {
    cat("   ✅ No hay SNVs múltiples para separar\n")
    return(df_snvs)
  }
  
  # Separar SNVs múltiples
  separated_rows <- multiple_snv_rows %>%
    separate_rows(df[["pos:mut"]], sep = ",") %>%
    mutate(df[["pos:mut"]] = str_trim(df[["pos:mut"]]))  # Limpiar espacios
  
  # Filas con SNVs simples (sin coma)
  simple_snv_rows <- df_snvs %>% 
    filter(!str_detect(df[["pos:mut"]], ","))
  
  # Combinar filas simples y separadas
  result <- bind_rows(simple_snv_rows, separated_rows) %>%
    arrange(df[["miRNA name"]], df[["pos:mut"]])
  
  cat("   ✅ SNVs separados exitosamente\n")
  cat("   📊 Total de filas después de separar:", nrow(result), "\n")
  
  return(result)
}

# =============================================================================
# FUNCIÓN 2: SUMAR CONTEOS DE SNVs POR miRNA Y MUESTRA
# =============================================================================
# 
# Suma los conteos de SNVs del mismo miRNA en la misma muestra
# NO suma los totales (columnas con sufijo PM+1MM+2MM)
#
# Parámetros:
#   df: data.frame con SNVs separados
#   snv_cols: vector con nombres de columnas de conteos de SNVs
#   total_cols: vector con nombres de columnas de totales
#
# Retorna:
#   data.frame con conteos sumados por miRNA y muestra
# =============================================================================

sum_snv_counts_by_mirna <- function(df, snv_cols, total_cols) {
  cat("🔧 Sumando conteos de SNVs por miRNA y muestra...\n")
  
  # Agrupar por miRNA y sumar solo las columnas de SNVs
  result <- df %>%
    group_by(df[["miRNA name"]]) %>%
    summarise(
      # Sumar columnas de SNVs
      across(all_of(snv_cols), ~ sum(.x, na.rm = TRUE)),
      # Tomar el primer valor de totales (no sumar)
      across(all_of(total_cols), ~ first(.x)),
      .groups = "drop"
    )
  
  cat("   ✅ Conteos sumados exitosamente\n")
  cat("   📊 miRNAs únicos:", nrow(result), "\n")
  
  return(result)
}

# =============================================================================
# FUNCIÓN 3: PROCESAMIENTO COMPLETO DE SNVs
# =============================================================================
# 
# Ejecuta el pipeline completo:
# 1. Separa SNVs múltiples
# 2. Suma conteos por miRNA y muestra
# 3. Mantiene totales sin sumar
#
# Parámetros:
#   df: data.frame original
#   snv_cols: vector con nombres de columnas de conteos de SNVs
#   total_cols: vector con nombres de columnas de totales
#
# Retorna:
#   data.frame procesado
# =============================================================================

process_snv_data <- function(df, snv_cols, total_cols) {
  cat("🚀 Iniciando procesamiento completo de SNVs...\n")
  cat("   📊 Filas iniciales:", nrow(df), "\n")
  cat("   📊 Columnas SNV:", length(snv_cols), "\n")
  cat("   📊 Columnas totales:", length(total_cols), "\n")
  
  # Paso 1: Separar SNVs múltiples
  df_separated <- separate_multiple_snvs(df, snv_cols, total_cols)
  
  # Paso 2: Sumar conteos por miRNA
  df_summed <- sum_snv_counts_by_mirna(df_separated, snv_cols, total_cols)
  
  cat("   ✅ Procesamiento completado\n")
  cat("   📊 Filas finales:", nrow(df_summed), "\n")
  
  return(df_summed)
}

# =============================================================================
# FUNCIÓN 4: VERIFICAR INTEGRIDAD DE DATOS
# =============================================================================
# 
# Verifica que las funciones estén funcionando correctamente:
# - Los totales no se suman
# - Los conteos de SNVs se suman correctamente
# - No se pierden miRNAs
#
# Parámetros:
#   df_original: data.frame original
#   df_processed: data.frame procesado
#   snv_cols: vector con nombres de columnas de conteos de SNVs
#   total_cols: vector con nombres de columnas de totales
#
# Retorna:
#   Lista con estadísticas de verificación
# =============================================================================

verify_data_integrity <- function(df_original, df_processed, snv_cols, total_cols) {
  cat("🔍 Verificando integridad de datos...\n")
  
  # Contar miRNAs únicos
  mirnas_original <- unique(df_original$`miRNA name`)
  mirnas_processed <- unique(df_processed$`miRNA name`)
  
  # Verificar que no se perdieron miRNAs
  lost_mirnas <- setdiff(mirnas_original, mirnas_processed)
  gained_mirnas <- setdiff(mirnas_processed, mirnas_original)
  
  # Verificar totales (no deberían cambiar)
  total_original <- df_original %>%
    filter(`pos:mut` != "PM") %>%
    group_by(`miRNA name`) %>%
    summarise(across(all_of(total_cols), ~ first(.x)), .groups = "drop")
  
  total_processed <- df_processed %>%
    select(`miRNA name`, all_of(total_cols))
  
  # Comparar totales
  total_comparison <- all.equal(
    total_original[order(total_original$`miRNA name`), total_cols],
    total_processed[order(total_processed$`miRNA name`), total_cols]
  )
  
  # Estadísticas
  stats <- list(
    mirnas_original = length(mirnas_original),
    mirnas_processed = length(mirnas_processed),
    lost_mirnas = length(lost_mirnas),
    gained_mirnas = length(gained_mirnas),
    totales_consistentes = isTRUE(total_comparison),
    filas_originales = nrow(df_original),
    filas_procesadas = nrow(df_processed)
  )
  
  # Reportar resultados
  cat("   📊 miRNAs originales:", stats$mirnas_original, "\n")
  cat("   📊 miRNAs procesados:", stats$mirnas_processed, "\n")
  cat("   📊 miRNAs perdidos:", stats$lost_mirnas, "\n")
  cat("   📊 miRNAs ganados:", stats$gained_mirnas, "\n")
  cat("   📊 Totales consistentes:", ifelse(stats$totales_consistentes, "✅", "❌"), "\n")
  cat("   📊 Filas originales:", stats$filas_originales, "\n")
  cat("   📊 Filas procesadas:", stats$filas_procesadas, "\n")
  
  if (stats$lost_mirnas > 0) {
    cat("   ⚠️  miRNAs perdidos:", paste(lost_mirnas, collapse = ", "), "\n")
  }
  
  if (stats$gained_mirnas > 0) {
    cat("   ⚠️  miRNAs ganados:", paste(gained_mirnas, collapse = ", "), "\n")
  }
  
  return(stats)
}

# =============================================================================
# FUNCIÓN 5: EJEMPLO DE USO
# =============================================================================
# 
# Ejemplo de cómo usar las funciones con el dataset
#
# =============================================================================

example_usage <- function() {
  cat("📚 EJEMPLO DE USO DE LAS FUNCIONES:\n")
  cat("=====================================\n\n")
  
  cat("1. Cargar datos:\n")
  cat("   df <- read.delim('miRNA_count.Q33.txt', sep = '\\t', header = TRUE)\n\n")
  
  cat("2. Identificar columnas:\n")
  cat("   snv_cols <- grep('^[A-Z]{2}[0-9]+', names(df), value = TRUE)\n")
  cat("   total_cols <- grep('\\\\(PM\\\\+1MM\\\\+2MM\\\\)', names(df), value = TRUE)\n\n")
  
  cat("3. Procesar datos:\n")
  cat("   df_processed <- process_snv_data(df, snv_cols, total_cols)\n\n")
  
  cat("4. Verificar integridad:\n")
  cat("   stats <- verify_data_integrity(df, df_processed, snv_cols, total_cols)\n\n")
  
  cat("5. Guardar resultados:\n")
  cat("   write.table(df_processed, 'miRNA_processed.txt', sep = '\\t', row.names = FALSE)\n\n")
}

# =============================================================================
# FUNCIÓN 6: ANÁLISIS DE SNVs G>T EN REGIÓN SEMILLA
# =============================================================================
# 
# Filtra y analiza específicamente SNVs G>T en la región semilla (posiciones 2-8)
#
# Parámetros:
#   df: data.frame procesado
#   snv_cols: vector con nombres de columnas de conteos de SNVs
#   total_cols: vector con nombres de columnas de totales
#
# Retorna:
#   data.frame con solo SNVs G>T en región semilla
# =============================================================================

filter_gt_seed_snvs <- function(df, snv_cols, total_cols) {
  cat("🔍 Filtrando SNVs G>T en región semilla (posiciones 2-8)...\n")
  
  # Filtrar SNVs G>T en región semilla
  df_gt_seed <- df %>%
    filter(str_detect(`pos:mut`, "^[2-8]:GT$"))
  
  cat("   📊 SNVs G>T en región semilla encontrados:", nrow(df_gt_seed), "\n")
  
  if (nrow(df_gt_seed) > 0) {
    cat("   📊 miRNAs con G>T en región semilla:", length(unique(df_gt_seed$`miRNA name`)), "\n")
    
    # Mostrar algunos ejemplos
    examples <- df_gt_seed %>%
      select(`miRNA name`, `pos:mut`) %>%
      head(5)
    
    cat("   📋 Ejemplos de SNVs G>T en región semilla:\n")
    print(examples)
  } else {
    cat("   ⚠️  No se encontraron SNVs G>T en región semilla\n")
  }
  
  return(df_gt_seed)
}

# =============================================================================
# FUNCIÓN 7: CALCULAR RPM Y VAF
# =============================================================================
# 
# Calcula RPM (Reads Per Million) y VAF (Variant Allele Frequency)
# para los SNVs procesados
#
# Parámetros:
#   df: data.frame procesado
#   snv_cols: vector con nombres de columnas de conteos de SNVs
#   total_cols: vector con nombres de columnas de totales
#
# Retorna:
#   data.frame con columnas RPM y VAF añadidas
# =============================================================================

calculate_rpm_and_vaf <- function(df, snv_cols, total_cols) {
  cat("🔧 Calculando RPM y VAF...\n")
  
  # Calcular library size por muestra
  lib_size <- df %>%
    summarise(across(all_of(total_cols), ~ sum(.x, na.rm = TRUE))) %>%
    unlist()
  
  # Calcular RPM para cada muestra
  df_rpm <- df
  for (col in snv_cols) {
    # Encontrar la columna de totales correspondiente
    total_col <- str_replace(col, "^([A-Z]{2}[0-9]+)", "\\1(PM+1MM+2MM)")
    if (total_col %in% total_cols) {
      df_rpm[[paste0(col, "_RPM")]] <- (df_rpm[[col]] / lib_size[total_col]) * 1e6
    }
  }
  
  # Calcular VAF para cada muestra
  df_vaf <- df_rpm
  for (col in snv_cols) {
    total_col <- str_replace(col, "^([A-Z]{2}[0-9]+)", "\\1(PM+1MM+2MM)")
    if (total_col %in% total_cols) {
      df_vaf[[paste0(col, "_VAF")]] <- df_vaf[[col]] / df_vaf[[total_col]]
    }
  }
  
  cat("   ✅ RPM y VAF calculados exitosamente\n")
  
  return(df_vaf)
}

# =============================================================================
# FUNCIÓN 8: ANÁLISIS COMPLETO CON FILTROS
# =============================================================================
# 
# Ejecuta el análisis completo con filtros de RPM y VAF
#
# Parámetros:
#   df: data.frame original
#   snv_cols: vector con nombres de columnas de conteos de SNVs
#   total_cols: vector con nombres de columnas de totales
#   rpm_threshold: umbral mínimo de RPM (default: 1)
#   vaf_threshold: umbral máximo de VAF (default: 0.5)
#
# Retorna:
#   Lista con resultados del análisis
# =============================================================================

complete_analysis <- function(df, snv_cols, total_cols, rpm_threshold = 1, vaf_threshold = 0.5) {
  cat("🚀 Iniciando análisis completo...\n")
  cat("   📊 Umbral RPM:", rpm_threshold, "\n")
  cat("   📊 Umbral VAF:", vaf_threshold, "\n\n")
  
  # Paso 1: Procesar SNVs
  df_processed <- process_snv_data(df, snv_cols, total_cols)
  
  # Paso 2: Filtrar G>T en región semilla
  df_gt_seed <- filter_gt_seed_snvs(df_processed, snv_cols, total_cols)
  
  if (nrow(df_gt_seed) == 0) {
    cat("   ⚠️  No hay SNVs G>T en región semilla para analizar\n")
    return(NULL)
  }
  
  # Paso 3: Calcular RPM y VAF
  df_with_metrics <- calculate_rpm_and_vaf(df_gt_seed, snv_cols, total_cols)
  
  # Paso 4: Aplicar filtros
  rpm_cols <- paste0(snv_cols, "_RPM")
  vaf_cols <- paste0(snv_cols, "_VAF")
  
  # Filtrar por RPM
  df_filtered <- df_with_metrics
  for (col in rpm_cols) {
    df_filtered <- df_filtered %>%
      filter(!!sym(col) >= rpm_threshold | is.na(!!sym(col)))
  }
  
  # Filtrar por VAF
  for (col in vaf_cols) {
    df_filtered <- df_filtered %>%
      filter(!!sym(col) <= vaf_threshold | is.na(!!sym(col)))
  }
  
  cat("   📊 SNVs después de filtros:", nrow(df_filtered), "\n")
  
  # Paso 5: Calcular métricas agregadas
  df_summary <- df_filtered %>%
    mutate(
      total_gt_counts = rowSums(select(., all_of(snv_cols)), na.rm = TRUE),
      mean_rpm = rowMeans(select(., all_of(rpm_cols)), na.rm = TRUE),
      mean_vaf = rowMeans(select(., all_of(vaf_cols)), na.rm = TRUE)
    ) %>%
    arrange(desc(total_gt_counts))
  
  # Resultados
  results <- list(
    processed_data = df_processed,
    gt_seed_data = df_gt_seed,
    filtered_data = df_filtered,
    summary_data = df_summary,
    stats = list(
      total_mirnas = nrow(df_processed),
      gt_seed_mirnas = nrow(df_gt_seed),
      filtered_mirnas = nrow(df_filtered),
      rpm_threshold = rpm_threshold,
      vaf_threshold = vaf_threshold
    )
  )
  
  cat("   ✅ Análisis completado\n")
  
  return(results)
}

# =============================================================================
# FIN DEL SCRIPT
# =============================================================================

cat("📚 Funciones de procesamiento de SNVs cargadas exitosamente\n")
cat("   🔧 separate_multiple_snvs()\n")
cat("   🔧 sum_snv_counts_by_mirna()\n")
cat("   🔧 process_snv_data()\n")
cat("   🔧 verify_data_integrity()\n")
cat("   🔧 filter_gt_seed_snvs()\n")
cat("   🔧 calculate_rpm_and_vaf()\n")
cat("   🔧 complete_analysis()\n")
cat("   📚 example_usage()\n\n")
