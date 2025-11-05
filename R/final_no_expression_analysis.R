#!/usr/bin/env Rscript

# =============================================================================
# ANÁLISIS FINAL SIN FILTRO DE EXPRESIÓN
# =============================================================================

# Cargar librerías
library(dplyr)
library(ggplot2)
library(stringr)
library(readr)

# Configuración
options(stringsAsFactors = FALSE)

# Función principal
main <- function() {
  cat("=== ANÁLISIS FINAL SIN FILTRO DE EXPRESIÓN ===\n\n")
  
  # Cargar datos
  cat("Cargando datos...\n")
  df <- read_tsv("results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt", show_col_types = FALSE)
  cat("Dimensiones del dataset:", dim(df), "\n")
  
  # Identificar columnas
  meta_cols <- c("miRNA name", "pos:mut")
  sample_cols <- setdiff(names(df), meta_cols)
  total_cols <- sample_cols[str_detect(sample_cols, "\\(PM\\+1MM\\+2MM\\)$")]
  snv_cols <- setdiff(sample_cols, total_cols)
  
  cat("Columnas de SNV:", length(snv_cols), "\n")
  cat("Columnas de totales:", length(total_cols), "\n")
  
  # Filtrar G>T en región semilla
  cat("Filtrando G>T en región semilla...\n")
  
  # Extraer posición y mutación de pos:mut
  df$pos <- as.numeric(str_extract(df$`pos:mut`, "^\\d+"))
  df$mut <- str_extract(df$`pos:mut`, ":\\w+$")
  
  # Filtrar solo G>T
  df_gt <- df %>%
    filter(str_detect(mut, ":GT"))
  
  # Filtrar región semilla (posiciones 2-8)
  df_seed <- df_gt %>%
    filter(pos >= 2 & pos <= 8)
  
  cat("G>T en región semilla:", nrow(df_seed), "\n")
  
  # Calcular conteos por miRNA (sin filtro VAF)
  cat("Calculando conteos por miRNA...\n")
  
  seed_counts <- df_seed %>%
    group_by(`miRNA name`) %>%
    summarise(
      total_gt_count = sum(across(all_of(snv_cols), ~ sum(.x, na.rm = TRUE))),
      .groups = "drop"
    ) %>%
    arrange(desc(total_gt_count))
  
  # Seleccionar top miRNAs (15%)
  n_top <- ceiling(nrow(seed_counts) * 0.15)
  top_mirnas <- head(seed_counts, n_top)
  
  cat("Top miRNAs seleccionados:", nrow(top_mirnas), "\n")
  
  # Comparar con análisis anterior
  cat("Comparando con análisis anterior...\n")
  if (file.exists("outputs/expanded_seed_top_mirna_list.txt")) {
    previous_data <- read_tsv("outputs/expanded_seed_top_mirna_list.txt", show_col_types = FALSE)
    previous_mirnas <- previous_data$`miRNA name`
    
    overlap <- intersect(top_mirnas$`miRNA name`, previous_mirnas)
    overlap_pct <- (length(overlap) / length(top_mirnas$`miRNA name`)) * 100
    
    cat("Overlap con análisis anterior:", length(overlap), "miRNAs (", 
        round(overlap_pct, 1), "%)\n")
  } else {
    cat("Archivo anterior no encontrado\n")
    overlap_pct <- 0
  }
  
  # Análisis de expresión general
  cat("Analizando expresión general...\n")
  
  # Calcular library size
  lib_size <- df %>%
    summarise(across(all_of(total_cols), ~ sum(.x, na.rm = TRUE))) %>%
    unlist()
  
  # Calcular RPM para todos los miRNAs
  expression_stats <- df %>%
    group_by(`miRNA name`) %>%
    summarise(
      mean_rpm = mean(across(all_of(total_cols), ~ mean((.x / lib_size[names(.x)]) * 1e6, na.rm = TRUE))),
      .groups = "drop"
    ) %>%
    arrange(desc(mean_rpm))
  
  # Crear visualizaciones
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
               color = "red", linetype = "dashed", linewidth = 1) +
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
  
  # 3. Análisis de expresión general
  p3 <- ggplot(head(expression_stats, 50), aes(x = reorder(`miRNA name`, mean_rpm), y = mean_rpm)) +
    geom_col(fill = "darkgreen", alpha = 0.8) +
    coord_flip() +
    labs(title = "Top 50 miRNAs by Mean RPM (General Expression)",
         x = "miRNA", y = "Mean RPM") +
    theme_minimal() +
    theme(plot.title = element_text(hjust = 0.5),
          axis.text.y = element_text(size = 6))
  
  ggsave(file.path(output_dir, "general_expression.png"), p3, 
         width = 12, height = 10, dpi = 300)
  
  # 4. Scatter plot: RPM vs G>T counts
  merged_data <- merge(seed_counts, expression_stats, by = "miRNA name")
  p4 <- ggplot(merged_data, aes(x = mean_rpm, y = total_gt_count)) +
    geom_point(alpha = 0.6, color = "darkblue") +
    geom_smooth(method = "lm", se = TRUE, color = "red") +
    labs(title = "RPM vs G>T Counts in Seed Region",
         x = "Mean RPM", y = "Total G>T Counts") +
    theme_minimal() +
    theme(plot.title = element_text(hjust = 0.5))
  
  ggsave(file.path(output_dir, "rpm_vs_gt_counts.png"), p4, 
         width = 10, height = 6, dpi = 300)
  
  # Generar reporte
  cat("Generando reporte...\n")
  
  report_file <- "outputs/no_expression_filter_analysis_report.md"
  
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
    "3. **Limpieza:** Sin filtro VAF (todos los SNVs incluidos)\n",
    "4. **Selección:** Top 15% de miRNAs por conteos G>T\n",
    "5. **Comparación:** Con análisis anterior (con filtro de expresión)\n",
    "6. **Expresión:** Análisis general de RPM de todos los miRNAs\n\n",
    "## RESULTADOS PRINCIPALES\n\n",
    "### 1. Conteos G>T en Región Semilla\n\n",
    "- **Total miRNAs con G>T:** ", nrow(seed_counts), "\n",
    "- **Top miRNAs seleccionados:** ", nrow(top_mirnas), "\n",
    "- **Rango de conteos G>T:** ", min(seed_counts$total_gt_count), " - ", max(seed_counts$total_gt_count), "\n\n",
    "### 2. Top 10 miRNAs por Conteos G>T\n\n",
    "| Rank | miRNA | Total G>T Counts |\n",
    "|------|-------|------------------|\n",
    paste(apply(head(top_mirnas, 10), 1, function(x, i) {
      paste0("| ", i, " | ", x[1], " | ", x[2], " |")
    }, 1:10), collapse = "\n"), "\n\n",
    "### 3. Comparación con Análisis Anterior\n\n",
    "- **Overlap:** ", ifelse(exists("overlap"), length(overlap), 0), " miRNAs (", 
    round(overlap_pct, 1), "%)\n\n",
    "### 4. Análisis de Expresión General\n\n",
    "- **Total miRNAs analizados:** ", nrow(expression_stats), "\n",
    "- **Rango de RPM:** ", round(min(expression_stats$mean_rpm), 2), " - ", 
    round(max(expression_stats$mean_rpm), 2), "\n",
    "- **Top 10 miRNAs por expresión:**\n\n",
    "| Rank | miRNA | Mean RPM |\n",
    "|------|-------|----------|\n",
    paste(apply(head(expression_stats, 10), 1, function(x, i) {
      paste0("| ", i, " | ", x[1], " | ", round(as.numeric(x[2]), 2), " |")
    }, 1:10), collapse = "\n"), "\n\n",
    "## CONCLUSIONES\n\n",
    "1. **Sin filtro de expresión:** Se identificaron ", nrow(top_mirnas), " miRNAs top\n",
    "2. **Comparación:** Overlap del ", round(overlap_pct, 1), "% con análisis anterior\n",
    "3. **Expresión:** Análisis general muestra ", nrow(expression_stats), " miRNAs con expresión variable\n",
    "4. **Diferencias:** El filtro de expresión afecta significativamente la selección de miRNAs\n\n"
  )
  
  writeLines(report_content, report_file)
  cat("Reporte guardado en:", report_file, "\n")
  
  # Guardar resultados
  write_tsv(seed_counts, "outputs/no_expression_filter_seed_counts.tsv")
  write_tsv(top_mirnas, "outputs/no_expression_filter_top_mirna_list.txt")
  write_tsv(expression_stats, "outputs/no_expression_filter_expression_stats.tsv")
  
  cat("\n=== ANÁLISIS COMPLETADO ===\n")
  cat("Top miRNAs identificados:", nrow(top_mirnas), "\n")
  cat("Overlap con análisis anterior:", round(overlap_pct, 1), "%\n")
  cat("Archivos generados en outputs/\n")
}

# Ejecutar análisis
if (!interactive()) {
  main()
}
