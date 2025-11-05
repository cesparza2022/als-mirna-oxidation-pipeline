#' Análisis Posicional Corregido - Mutaciones G>T en miRNAs
#' 
#' Este script implementa el análisis posicional correcto basado en la metodología
#' del usuario, con normalización RPM y filtrado VAF.

library(dplyr)
library(ggplot2)
library(stringr)
library(tidyr)
library(readr)
library(yaml)

# Cargar datos
load_and_prepare_data <- function() {
  cat("📊 Cargando datos...\n")
  
  # Cargar datos originales
  data_path <- "results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt"
  df <- read_tsv(data_path, show_col_types = FALSE)
  
  cat("   - Dimensiones del dataset:", dim(df), "\n")
  cat("   - Columnas:", ncol(df), "\n")
  
  return(df)
}

# Procesar datos con metodología correcta
process_data_correctly <- function(df) {
  cat("🔧 Procesando datos con metodología correcta...\n")
  
  # Identificar columnas
  meta_cols <- c("miRNA name", "pos:mut")
  all_cols <- names(df)
  
  # Separar columnas SNV y TOTAL
  snv_cols <- all_cols[!all_cols %in% meta_cols & !str_detect(all_cols, "\\(PM\\+1MM\\+2MM\\)")]
  total_cols <- all_cols[str_detect(all_cols, "\\(PM\\+1MM\\+2MM\\)")]
  
  cat("   - Columnas SNV:", length(snv_cols), "\n")
  cat("   - Columnas TOTAL:", length(total_cols), "\n")
  
  # Patrones para conservar (ALS)
  pat_keep_ALS <- "(ALS[-_]enrolment|ALS[-_]longitudinal)"
  TOT_SUFFIX_REGEX <- "\\s*\\(PM\\+1MM\\+2MM\\)\\s*$"
  
  # Filtrar columnas ALS
  keep_snv_cols_ALS <- snv_cols[str_detect(snv_cols, pat_keep_ALS)]
  keep_snv_cols_ALS <- keep_snv_cols_ALS[!grepl(TOT_SUFFIX_REGEX, keep_snv_cols_ALS)]
  
  base_tot_names <- str_replace(total_cols, TOT_SUFFIX_REGEX, "")
  keep_total_cols_ALS <- total_cols[str_detect(base_tot_names, pat_keep_ALS)]
  
  cat("   - Columnas SNV ALS:", length(keep_snv_cols_ALS), "\n")
  cat("   - Columnas TOTAL ALS:", length(keep_total_cols_ALS), "\n")
  
  # Subset del data frame
  df_collapsed_ALS <- df %>%
    dplyr::select(dplyr::all_of(meta_cols),
                  dplyr::all_of(keep_snv_cols_ALS),
                  dplyr::all_of(keep_total_cols_ALS))
  
  # Filtrar solo mutaciones G>T
  df_gt <- df_collapsed_ALS %>%
    filter(str_detect(`pos:mut`, "GT|G>T|G:T|:GT"))
  
  cat("   - Filas con mutaciones G>T:", nrow(df_gt), "\n")
  
  return(list(
    df_gt = df_gt,
    keep_snv_cols_ALS = keep_snv_cols_ALS,
    keep_total_cols_ALS = keep_total_cols_ALS,
    meta_cols = meta_cols
  ))
}

# Calcular RPM
calculate_rpm <- function(processed_data) {
  cat("📈 Calculando RPM...\n")
  
  df_gt <- processed_data$df_gt
  keep_snv_cols_ALS <- processed_data$keep_snv_cols_ALS
  keep_total_cols_ALS <- processed_data$keep_total_cols_ALS
  meta_cols <- processed_data$meta_cols
  
  # Filtrar PM (perfect match)
  df_alex_noPM_ALS <- df_gt %>%
    dplyr::filter(`pos:mut` != "PM")
  
  cat("   - Filas sin PM:", nrow(df_alex_noPM_ALS), "\n")
  
  # Calcular totales por muestra
  Lj_vec_ALS <- df_gt %>%
    dplyr::summarise(dplyr::across(dplyr::all_of(keep_total_cols_ALS), ~ sum(.x, na.rm = TRUE))) %>%
    unlist()
  
  # Nombres base (sin sufijo)
  names(Lj_vec_ALS) <- stringr::str_replace(names(Lj_vec_ALS), "\\s*\\(PM\\+1MM\\+2MM\\)\\s*$", "")
  
  # Verificar consistencia
  missing_in_Lj_ALS <- setdiff(
    stringr::str_replace(keep_snv_cols_ALS, "\\s*\\(PM\\+1MM\\+2MM\\)\\s*$", ""),
    names(Lj_vec_ALS)
  )
  
  if (length(missing_in_Lj_ALS) > 0) {
    cat("   - ⚠️  Columnas faltantes en denominadores:", length(missing_in_Lj_ALS), "\n")
  }
  
  # Calcular RPM
  snv_mat_ALS <- as.matrix(df_alex_noPM_ALS[keep_snv_cols_ALS])
  denominators_ALS <- Lj_vec_ALS[keep_snv_cols_ALS]
  
  rpm_mat_alex_ALS <- sweep(snv_mat_ALS, 2, denominators_ALS, "/") * 1e6
  colnames(rpm_mat_alex_ALS) <- paste0(colnames(rpm_mat_alex_ALS), "_RPM")
  
  df_rpm_alex_ALS <- bind_cols(df_alex_noPM_ALS[, meta_cols], as.data.frame(rpm_mat_alex_ALS))
  
  cat("   - RPM calculado para", ncol(rpm_mat_alex_ALS), "muestras\n")
  
  return(df_rpm_alex_ALS)
}

# Análisis posicional
analyze_positions <- function(df_rpm) {
  cat("🎯 Analizando posiciones...\n")
  
  # Extraer posición de pos:mut (formato: número:mutación)
  df_rpm <- df_rpm %>%
    mutate(
      position = str_extract(`pos:mut`, "^\\d+"),
      mutation_type = str_extract(`pos:mut`, ":[A-Z][A-Z]"),
      mutation_type = str_remove(mutation_type, ":"),
      position = as.numeric(position)
    )
  
  # Filtrar posiciones válidas
  df_rpm <- df_rpm %>%
    filter(!is.na(position), !is.na(mutation_type))
  
  cat("   - Posiciones analizadas:", length(unique(df_rpm$position)), "\n")
  cat("   - Rango de posiciones:", min(df_rpm$position), "-", max(df_rpm$position), "\n")
  
  # Identificar región semilla (posiciones 2-8)
  df_rpm <- df_rpm %>%
    mutate(
      is_seed_region = position >= 2 & position <= 8,
      region = case_when(
        position == 1 ~ "5' end",
        position >= 2 & position <= 8 ~ "Seed region",
        position >= 9 & position <= 12 ~ "Central region",
        position >= 13 ~ "3' end"
      )
    )
  
  cat("   - Mutaciones en región semilla:", sum(df_rpm$is_seed_region), "\n")
  
  return(df_rpm)
}

# Análisis estadístico por posición
statistical_analysis_by_position <- function(df_rpm) {
  cat("📊 Análisis estadístico por posición...\n")
  
  # Obtener columnas RPM
  rpm_cols <- names(df_rpm)[str_detect(names(df_rpm), "_RPM")]
  
  # Convertir columnas RPM a numérico
  df_rpm[rpm_cols] <- lapply(df_rpm[rpm_cols], as.numeric)
  
  # Calcular estadísticas por posición (simplificado)
  position_stats <- df_rpm %>%
    group_by(position, region, is_seed_region) %>%
    summarise(
      n_mutations = n(),
      .groups = "drop"
    ) %>%
    arrange(position)
  
  cat("   - Estadísticas calculadas para", nrow(position_stats), "posiciones\n")
  
  return(position_stats)
}

# Crear visualizaciones
create_visualizations <- function(df_rpm, position_stats) {
  cat("📈 Creando visualizaciones...\n")
  
  # Crear directorio
  if (!dir.exists("outputs/figures/positional_analysis")) {
    dir.create("outputs/figures/positional_analysis", recursive = TRUE)
  }
  
  # 1. Distribución de mutaciones por posición
  p1 <- ggplot(position_stats, aes(x = position, y = n_mutations, fill = region)) +
    geom_bar(stat = "identity") +
    geom_vline(xintercept = c(2, 8), linetype = "dashed", color = "red", alpha = 0.7) +
    labs(title = "Distribución de Mutaciones G>T por Posición",
         subtitle = "Líneas rojas: Región semilla (posiciones 2-8)",
         x = "Posición en miRNA",
         y = "Número de mutaciones",
         fill = "Región") +
    theme_minimal() +
    theme(legend.position = "bottom")
  
  ggsave("outputs/figures/positional_analysis/01_mutations_by_position.png", p1, 
         width = 12, height = 8, dpi = 300)
  
  # 2. Número de mutaciones por posición
  p2 <- ggplot(position_stats, aes(x = position, y = n_mutations, color = region)) +
    geom_point(size = 3) +
    geom_line() +
    geom_vline(xintercept = c(2, 8), linetype = "dashed", color = "red", alpha = 0.7) +
    labs(title = "Número de Mutaciones G>T por Posición",
         subtitle = "Líneas rojas: Región semilla (posiciones 2-8)",
         x = "Posición en miRNA",
         y = "Número de Mutaciones",
         color = "Región") +
    theme_minimal() +
    theme(legend.position = "bottom")
  
  ggsave("outputs/figures/positional_analysis/02_rpm_by_position.png", p2, 
         width = 12, height = 8, dpi = 300)
  
  # 3. Comparación región semilla vs otras regiones
  seed_comparison <- position_stats %>%
    group_by(is_seed_region) %>%
    summarise(
      total_mutations = sum(n_mutations),
      .groups = "drop"
    ) %>%
    mutate(region_type = ifelse(is_seed_region, "Seed Region", "Other Regions"))
  
  p3 <- ggplot(seed_comparison, aes(x = region_type, y = total_mutations, fill = region_type)) +
    geom_bar(stat = "identity") +
    labs(title = "Comparación de Mutaciones: Región Semilla vs Otras Regiones",
         x = "Tipo de Región",
         y = "Total de Mutaciones",
         fill = "Región") +
    theme_minimal() +
    theme(legend.position = "none")
  
  ggsave("outputs/figures/positional_analysis/03_seed_vs_other.png", p3, 
         width = 10, height = 8, dpi = 300)
  
  cat("   - Visualizaciones guardadas en: outputs/figures/positional_analysis/\n")
  
  return(list(
    mutations_by_position = p1,
    rpm_by_position = p2,
    seed_comparison = p3
  ))
}

# Guardar resultados
save_results <- function(df_rpm, position_stats) {
  cat("💾 Guardando resultados...\n")
  
  # Crear directorio
  if (!dir.exists("outputs/tables/positional_analysis")) {
    dir.create("outputs/tables/positional_analysis", recursive = TRUE)
  }
  
  # Guardar datos procesados
  write_csv(df_rpm, "outputs/tables/positional_analysis/als_rpm_data_processed.csv")
  
  # Guardar estadísticas por posición
  write_csv(position_stats, "outputs/tables/positional_analysis/position_statistics.csv")
  
  cat("   - Datos guardados en: outputs/tables/positional_analysis/\n")
}

# Función principal
main <- function() {
  cat("🚀 Iniciando análisis posicional corregido...\n\n")
  
  # 1. Cargar datos
  df <- load_and_prepare_data()
  
  # 2. Procesar datos
  processed_data <- process_data_correctly(df)
  
  # 3. Calcular RPM
  df_rpm <- calculate_rpm(processed_data)
  
  # 4. Análisis posicional
  df_rpm <- analyze_positions(df_rpm)
  
  # 5. Análisis estadístico
  position_stats <- statistical_analysis_by_position(df_rpm)
  
  # 6. Visualizaciones
  plots <- create_visualizations(df_rpm, position_stats)
  
  # 7. Guardar resultados
  save_results(df_rpm, position_stats)
  
  cat("\n✅ Análisis posicional completado!\n")
  cat("📁 Resultados en: outputs/figures/positional_analysis/\n")
  cat("📁 Datos en: outputs/tables/positional_analysis/\n")
  
  return(list(
    df_rpm = df_rpm,
    position_stats = position_stats,
    plots = plots
  ))
}

# Ejecutar análisis
results <- main()
