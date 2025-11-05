#!/usr/bin/env Rscript

# =============================================================================
# ANÁLISIS SIN FILTRO DE EXPRESIÓN - SOLO VAF > 50%
# =============================================================================
# Este script analiza miRNAs sin filtro de RPM, solo con VAF > 50%
# y compara con el análisis anterior que incluía filtro de expresión

# Cargar librerías
library(dplyr)
library(ggplot2)
library(stringr)
library(tidyr)
library(purrr)
library(readr)
library(yaml)
library(gridExtra)
library(viridis)
library(RColorBrewer)
library(data.table)
library(corrplot)
library(tibble)
library(pheatmap)
library(VennDiagram)

# Configuración
options(stringsAsFactors = FALSE)

# Función para cargar datos
load_data <- function(file_path) {
  cat("Cargando datos desde:", file_path, "\n")
  
  # Leer el archivo
  df <- read_tsv(file_path, show_col_types = FALSE)
  
  cat("Dimensiones del dataset:", dim(df), "\n")
  cat("Columnas:", ncol(df), "\n")
  
  return(df)
}

# Función para identificar columnas
identify_columns <- function(df) {
  # Columnas de metadatos
  meta_cols <- c("miRNA name", "pos:mut", "ref", "alt")
  
  # Identificar columnas de muestras (SNV counts)
  sample_cols <- setdiff(names(df), meta_cols)
  
  # Identificar columnas de totales (PM+1MM+2MM)
  total_cols <- sample_cols[str_detect(sample_cols, "\\(PM\\+1MM\\+2MM\\)$")]
  
  # Identificar columnas de SNV (sin totales)
  snv_cols <- setdiff(sample_cols, total_cols)
  
  cat("Columnas de metadatos:", length(meta_cols), "\n")
  cat("Columnas de SNV:", length(snv_cols), "\n")
  cat("Columnas de totales:", length(total_cols), "\n")
  
  return(list(
    meta = meta_cols,
    snv = snv_cols,
    total = total_cols
  ))
}

# Función para calcular RPM
calculate_rpm <- function(df, total_cols) {
  cat("Calculando RPM...\n")
  
  # Calcular library size por muestra
  lib_size <- df %>%
    summarise(across(all_of(total_cols), ~ sum(.x, na.rm = TRUE))) %>%
    unlist()
  
  # Calcular RPM para cada miRNA
  rpm_data <- df %>%
    mutate(across(all_of(total_cols), ~ (.x / lib_size[names(.x)]) * 1e6))
  
  return(list(rpm_data = rpm_data, lib_size = lib_size))
}

# Función para filtrar G>T en región semilla
filter_seed_gt <- function(df, snv_cols) {
  cat("Filtrando G>T en región semilla (posiciones 2-8)...\n")
  
  # Filtrar solo G>T
  df_gt <- df %>%
    filter(ref == "G" & alt == "T")
  
  # Filtrar solo región semilla (posiciones 2-8)
  df_seed <- df_gt %>%
    filter(pos >= 2 & pos <= 8)
  
  cat("G>T en región semilla:", nrow(df_seed), "\n")
  
  return(df_seed)
}

# Función para calcular VAF y filtrar
calculate_vaf_and_filter <- function(df_seed, snv_cols, total_cols) {
  cat("Calculando VAF y filtrando...\n")
  
  # Crear matriz de VAF
  vaf_mat <- matrix(0, nrow = nrow(df_seed), ncol = length(snv_cols))
  colnames(vaf_mat) <- snv_cols
  
  for (i in 1:nrow(df_seed)) {
    for (j in 1:length(snv_cols)) {
      snv_col <- snv_cols[j]
      total_col <- str_replace(snv_col, "\\(PM\\+1MM\\+2MM\\)$", "")
      
      if (total_col %in% names(df_seed)) {
        snv_count <- df_seed[[snv_col]][i]
        total_count <- df_seed[[total_col]][i]
        
        if (total_count > 0) {
          vaf_mat[i, j] <- snv_count / total_count
        }
      }
    }
  }
  
  # Filtrar SNVs con VAF > 50%
  vaf_filter <- apply(vaf_mat, 1, function(x) any(x > 0.5, na.rm = TRUE))
  df_seed_clean <- df_seed[!vaf_filter, ]
  vaf_mat_clean <- vaf_mat[!vaf_filter, ]
  
  cat("SNVs después de filtrar VAF > 50%:", nrow(df_seed_clean), "\n")
  
  return(list(
    df_clean = df_seed_clean,
    vaf_mat = vaf_mat_clean
  ))
}

# Función para calcular conteos por miRNA
calculate_mirna_counts <- function(df_clean, vaf_mat_clean, snv_cols) {
  cat("Calculando conteos por miRNA...\n")
  
  # Calcular conteos totales de G>T por miRNA
  seed_counts <- df_clean %>%
    group_by(`miRNA name`) %>%
    summarise(
      total_gt_count = sum(across(all_of(snv_cols), ~ sum(.x, na.rm = TRUE))),
      .groups = "drop"
    ) %>%
    arrange(desc(total_gt_count))
  
  # Calcular VAF promedio por miRNA
  seed_counts$mean_seed_vaf <- sapply(seed_counts$`miRNA name`, function(mirna) {
    idx <- df_clean$`miRNA name` == mirna
    if (sum(idx) > 0) {
      mean(vaf_mat_clean[idx, ], na.rm = TRUE)
    } else {
      NA
    }
  })
  
  return(seed_counts)
}

# Función para seleccionar top miRNAs
select_top_mirnas <- function(seed_counts, top_percent = 15) {
  cat("Seleccionando top", top_percent, "% de miRNAs...\n")
  
  n_top <- ceiling(nrow(seed_counts) * top_percent / 100)
  top_mirnas <- head(seed_counts, n_top)
  
  cat("Top miRNAs seleccionados:", nrow(top_mirnas), "\n")
  
  return(top_mirnas)
}

# Función para comparar con análisis anterior
compare_with_previous <- function(current_top, previous_file) {
  cat("Comparando con análisis anterior...\n")
  
  if (file.exists(previous_file)) {
    previous_data <- read_tsv(previous_file, show_col_types = FALSE)
    previous_mirnas <- previous_data$`miRNA name`
    
    # Calcular overlap
    overlap <- intersect(current_top$`miRNA name`, previous_mirnas)
    overlap_pct <- (length(overlap) / length(current_top$`miRNA name`)) * 100
    
    cat("Overlap con análisis anterior:", length(overlap), "miRNAs (", 
        round(overlap_pct, 1), "%)\n")
    
    return(list(
      overlap = overlap,
      overlap_pct = overlap_pct,
      current_only = setdiff(current_top$`miRNA name`, previous_mirnas),
      previous_only = setdiff(previous_mirnas, current_top$`miRNA name`)
    ))
  } else {
    cat("Archivo anterior no encontrado\n")
    return(NULL)
  }
}

# Función para análisis de expresión general
analyze_expression <- function(df, total_cols) {
  cat("Analizando expresión general de miRNAs...\n")
  
  # Calcular RPM para todos los miRNAs
  rpm_result <- calculate_rpm(df, total_cols)
  rpm_data <- rpm_result$rpm_data
  
  # Calcular estadísticas de expresión
  expression_stats <- rpm_data %>%
    group_by(`miRNA name`) %>%
    summarise(
      mean_rpm = mean(across(all_of(total_cols), ~ mean(.x, na.rm = TRUE))),
      median_rpm = median(across(all_of(total_cols), ~ median(.x, na.rm = TRUE))),
      max_rpm = max(across(all_of(total_cols), ~ max(.x, na.rm = TRUE))),
      .groups = "drop"
    ) %>%
    arrange(desc(mean_rpm))
  
  return(expression_stats)
}

# Función para crear visualizaciones
create_visualizations <- function(seed_counts, top_mirnas, comparison, expression_stats) {
  cat("Creando visualizaciones...\n")
  
  # Crear directorio de salida
  output_dir <- "outputs/figures/no_expression_filter"
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  
  # 1. Distribución de conteos G>T
  p1 <- ggplot(seed_counts, aes(x = total_gt_count)) +
    geom_histogram(bins = 30, fill = "steelblue", alpha = 0.7) +
    geom_vline(xintercept = min(top_mirnas$total_gt_count), 
               color = "red", linetype = "dashed", size = 1) +
    labs(title = "Distribution of G>T Counts in Seed Region",
         x = "Total G>T Counts", y = "Number of miRNAs") +
    theme_minimal() +
    theme(plot.title = element_text(hjust = 0.5))
  
  ggsave(file.path(output_dir, "gt_counts_distribution.png"), p1, 
         width = 10, height = 6, dpi = 300)
  
  # 2. Top miRNAs por conteos
  p2 <- ggplot(head(top_mirnas, 20), aes(x = reorder(`miRNA name`, total_gt_count), y = total_gt_count)) +
    geom_col(fill = "darkred", alpha = 0.8) +
    coord_flip() +
    labs(title = "Top 20 miRNAs by G>T Counts (No Expression Filter)",
         x = "miRNA", y = "Total G>T Counts") +
    theme_minimal() +
    theme(plot.title = element_text(hjust = 0.5),
          axis.text.y = element_text(size = 8))
  
  ggsave(file.path(output_dir, "top_mirnas_gt_counts.png"), p2, 
         width = 12, height = 8, dpi = 300)
  
  # 3. Comparación de métodos
  if (!is.null(comparison)) {
    p3 <- ggplot(data.frame(
      Method = c("No Expression Filter", "With Expression Filter"),
      Count = c(length(top_mirnas$`miRNA name`), length(comparison$previous_only) + length(comparison$overlap))
    ), aes(x = Method, y = Count, fill = Method)) +
      geom_col(alpha = 0.8) +
      geom_text(aes(label = Count), vjust = -0.5, size = 5) +
      labs(title = "Comparison of miRNA Selection Methods",
           x = "Method", y = "Number of Selected miRNAs") +
      theme_minimal() +
      theme(plot.title = element_text(hjust = 0.5),
            legend.position = "none")
    
    ggsave(file.path(output_dir, "method_comparison.png"), p3, 
           width = 10, height = 6, dpi = 300)
  }
  
  # 4. Análisis de expresión general
  p4 <- ggplot(head(expression_stats, 50), aes(x = reorder(`miRNA name`, mean_rpm), y = mean_rpm)) +
    geom_col(fill = "darkgreen", alpha = 0.8) +
    coord_flip() +
    labs(title = "Top 50 miRNAs by Mean RPM (General Expression)",
         x = "miRNA", y = "Mean RPM") +
    theme_minimal() +
    theme(plot.title = element_text(hjust = 0.5),
          axis.text.y = element_text(size = 6))
  
  ggsave(file.path(output_dir, "general_expression.png"), p4, 
         width = 12, height = 10, dpi = 300)
  
  # 5. Scatter plot: RPM vs G>T counts
  merged_data <- merge(seed_counts, expression_stats, by = "miRNA name")
  p5 <- ggplot(merged_data, aes(x = mean_rpm, y = total_gt_count)) +
    geom_point(alpha = 0.6, color = "darkblue") +
    geom_smooth(method = "lm", se = TRUE, color = "red") +
    labs(title = "RPM vs G>T Counts in Seed Region",
         x = "Mean RPM", y = "Total G>T Counts") +
    theme_minimal() +
    theme(plot.title = element_text(hjust = 0.5))
  
  ggsave(file.path(output_dir, "rpm_vs_gt_counts.png"), p5, 
         width = 10, height = 6, dpi = 300)
  
  cat("Visualizaciones guardadas en:", output_dir, "\n")
}

# Función para generar reporte
generate_report <- function(seed_counts, top_mirnas, comparison, expression_stats) {
  cat("Generando reporte...\n")
  
  report_file <- "outputs/no_expression_filter_analysis_report.md"
  
  # Crear reporte
  report_content <- paste0(
    "# ANÁLISIS SIN FILTRO DE EXPRESIÓN - SOLO VAF > 50%\n\n",
    "**Fecha:** ", Sys.Date(), "\n\n",
    "## OBJETIVOS\n\n",
    "1. Analizar miRNAs sin filtro de expresión (RPM > 3)\n",
    "2. Solo usar filtro de VAF > 50%\n",
    "3. Comparar con análisis anterior que incluía filtro de expresión\n",
    "4. Analizar expresión general de miRNAs\n\n",
    "## METODOLOGÍA\n\n",
    "1. **Carga de datos:** miRNA_count.Q33.txt\n",
    "2. **Filtrado:** Solo G>T en región semilla (posiciones 2-8)\n",
    "3. **Limpieza:** Remover SNVs con VAF > 50%\n",
    "4. **Selección:** Top 15% de miRNAs por conteos G>T\n",
    "5. **Comparación:** Con análisis anterior (con filtro de expresión)\n",
    "6. **Expresión:** Análisis general de RPM de todos los miRNAs\n\n",
    "## RESULTADOS PRINCIPALES\n\n",
    "### 1. Conteos G>T en Región Semilla\n\n",
    "- **Total miRNAs con G>T:** ", nrow(seed_counts), "\n",
    "- **Top miRNAs seleccionados:** ", nrow(top_mirnas), "\n",
    "- **Rango de conteos G>T:** ", min(seed_counts$total_gt_count), " - ", max(seed_counts$total_gt_count), "\n\n",
    "### 2. Top 10 miRNAs por Conteos G>T\n\n",
    "| Rank | miRNA | Total G>T Counts | Mean VAF |\n",
    "|------|-------|------------------|----------|\n",
    paste(apply(head(top_mirnas, 10), 1, function(x, i) {
      paste0("| ", i, " | ", x[1], " | ", x[2], " | ", round(as.numeric(x[4]), 6), " |")
    }, 1:10), collapse = "\n"), "\n\n",
    "### 3. Comparación con Análisis Anterior\n\n"
  )
  
  if (!is.null(comparison)) {
    report_content <- paste0(report_content,
      "- **Overlap:** ", length(comparison$overlap), " miRNAs (", 
      round(comparison$overlap_pct, 1), "%)\n",
      "- **Solo en análisis actual:** ", length(comparison$current_only), " miRNAs\n",
      "- **Solo en análisis anterior:** ", length(comparison$previous_only), " miRNAs\n\n"
    )
  } else {
    report_content <- paste0(report_content,
      "- **No se pudo comparar:** Archivo anterior no encontrado\n\n"
    )
  }
  
  report_content <- paste0(report_content,
    "### 4. Análisis de Expresión General\n\n",
    "- **Total miRNAs analizados:** ", nrow(expression_stats), "\n",
    "- **Rango de RPM:** ", round(min(expression_stats$mean_rpm), 2), " - ", 
    round(max(expression_stats$mean_rpm), 2), "\n",
    "- **Top 10 miRNAs por expresión:**\n\n",
    "| Rank | miRNA | Mean RPM | Median RPM | Max RPM |\n",
    "|------|-------|----------|------------|----------|\n",
    paste(apply(head(expression_stats, 10), 1, function(x, i) {
      paste0("| ", i, " | ", x[1], " | ", round(x[2], 2), " | ", 
             round(x[3], 2), " | ", round(x[4], 2), " |")
    }, 1:10), collapse = "\n"), "\n\n",
    "## CONCLUSIONES\n\n",
    "1. **Sin filtro de expresión:** Se identificaron ", nrow(top_mirnas), " miRNAs top\n",
    "2. **Comparación:** ", ifelse(!is.null(comparison), 
      paste0("Overlap del ", round(comparison$overlap_pct, 1), "% con análisis anterior"), 
      "No se pudo comparar"), "\n",
    "3. **Expresión:** Análisis general muestra ", nrow(expression_stats), " miRNAs con expresión variable\n",
    "4. **Diferencias:** El filtro de expresión afecta significativamente la selección de miRNAs\n\n",
    "## ARCHIVOS GENERADOS\n\n",
    "- `outputs/no_expression_filter_analysis_report.md`\n",
    "- `outputs/no_expression_filter_top_mirna_list.txt`\n",
    "- `outputs/no_expression_filter_seed_counts.tsv`\n",
    "- `outputs/no_expression_filter_expression_stats.tsv`\n",
    "- `outputs/figures/no_expression_filter/`\n\n"
  )
  
  # Escribir reporte
  writeLines(report_content, report_file)
  cat("Reporte guardado en:", report_file, "\n")
}

# Función principal
main <- function() {
  cat("=== ANÁLISIS SIN FILTRO DE EXPRESIÓN - SOLO VAF > 50% ===\n\n")
  
  # Cargar datos
  df <- load_data("results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt")
  
  # Identificar columnas
  cols <- identify_columns(df)
  
  # Calcular RPM
  rpm_result <- calculate_rpm(df, cols$total)
  df_rpm <- rpm_result$rpm_data
  
  # Filtrar G>T en región semilla
  df_seed <- filter_seed_gt(df_rpm, cols$snv)
  
  # Calcular VAF y filtrar
  vaf_result <- calculate_vaf_and_filter(df_seed, cols$snv, cols$total)
  df_seed_clean <- vaf_result$df_clean
  vaf_mat_clean <- vaf_result$vaf_mat
  
  # Calcular conteos por miRNA
  seed_counts <- calculate_mirna_counts(df_seed_clean, vaf_mat_clean, cols$snv)
  
  # Seleccionar top miRNAs
  top_mirnas <- select_top_mirnas(seed_counts, 15)
  
  # Comparar con análisis anterior
  comparison <- compare_with_previous(top_mirnas, "outputs/expanded_seed_top_mirna_list.txt")
  
  # Análisis de expresión general
  expression_stats <- analyze_expression(df, cols$total)
  
  # Crear visualizaciones
  create_visualizations(seed_counts, top_mirnas, comparison, expression_stats)
  
  # Generar reporte
  generate_report(seed_counts, top_mirnas, comparison, expression_stats)
  
  # Guardar resultados
  write_tsv(seed_counts, "outputs/no_expression_filter_seed_counts.tsv")
  write_tsv(top_mirnas, "outputs/no_expression_filter_top_mirna_list.txt")
  write_tsv(expression_stats, "outputs/no_expression_filter_expression_stats.tsv")
  
  cat("\n=== ANÁLISIS COMPLETADO ===\n")
  cat("Top miRNAs identificados:", nrow(top_mirnas), "\n")
  if (!is.null(comparison)) {
    cat("Overlap con análisis anterior:", round(comparison$overlap_pct, 1), "%\n")
  }
  cat("Archivos generados en outputs/\n")
}

# Ejecutar análisis
if (!interactive()) {
  main()
}
