# =============================================================================
# MÓDULO 1: DATA LOADING AND INITIAL PROCESSING
# =============================================================================
# Autor: César Esparza
# Fecha: Octubre 15, 2025
# Descripción: Carga, valida y procesa datos iniciales del pipeline
# =============================================================================

# Cargar librerías necesarias
library(tidyverse)
library(yaml)
library(jsonlite)

# Cargar funciones core
source("src/core/io.R")
source("src/core/preprocessing.R")

# =============================================================================
# CONFIGURACIÓN DEL MÓDULO
# =============================================================================

#' Load Module Configuration
#'
#' Loads configuration for Module 1
#'
#' @param config_path character, path to config file
#' 
#' @return list with module configuration
#' 
#' @export
load_module_config <- function(config_path = "config/default_config.yaml") {
  
  # Cargar configuración general
  config <- read_yaml(config_path)
  
  # Configuración específica del módulo
  module_config <- list(
    # Parámetros de filtrado
    vaf_threshold = config$filtering$vaf_filtering$threshold,
    min_coverage = config$filtering$coverage_filtering$min_coverage,
    min_samples = config$filtering$coverage_filtering$min_samples,
    
    # Rutas de salida
    output_dir = config$paths$outputs$step_01_prep,
    figures_dir = file.path(config$paths$outputs$step_01_prep, config$paths$subdirs$figures),
    tables_dir = file.path(config$paths$outputs$step_01_prep, config$paths$subdirs$tables),
    reports_dir = file.path(config$paths$outputs$step_01_prep, config$paths$subdirs$reports),
    
    # Configuración de visualización
    dpi = config$visualization$general$dpi,
    width = config$visualization$general$width,
    height = config$visualization$general$height,
    
    # Configuración de logging
    verbose = config$logging$level %in% c("DEBUG", "INFO"),
    
    # Configuración de desarrollo
    debug = config$development$debug$enabled,
    save_intermediate = config$development$debug$save_intermediate
  )
  
  return(module_config)
}

# =============================================================================
# FUNCIÓN PRINCIPAL DEL MÓDULO
# =============================================================================

#' Module 1: Data Loading and Initial Processing
#'
#' Main function for Module 1 - loads, validates, and processes input data
#'
#' @param input_file character, path to input TSV file
#' @param config_path character, path to config file
#' @param output_dir character, output directory (optional, overrides config)
#' 
#' @return list with processed data and metadata
#' 
#' @export
run_module_01_data_loading <- function(input_file, config_path = "config/default_config.yaml", output_dir = NULL) {
  
  cat("=== MODULE 1: DATA LOADING AND INITIAL PROCESSING ===\n\n")
  cat("Started at:", Sys.time(), "\n\n")
  
  # 1. CARGAR CONFIGURACIÓN
  module_config <- load_module_config(config_path)
  
  # Override output directory si se especifica
  if (!is.null(output_dir)) {
    module_config$output_dir <- output_dir
    module_config$figures_dir <- file.path(output_dir, "figures")
    module_config$tables_dir <- file.path(output_dir, "tables")
    module_config$reports_dir <- file.path(output_dir, "reports")
  }
  
  # 2. CREAR DIRECTORIOS DE SALIDA
  dir.create(module_config$output_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(module_config$figures_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(module_config$tables_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(module_config$reports_dir, recursive = TRUE, showWarnings = FALSE)
  
  cat("Output directories created:\n")
  cat("  Main:", module_config$output_dir, "\n")
  cat("  Figures:", module_config$figures_dir, "\n")
  cat("  Tables:", module_config$tables_dir, "\n")
  cat("  Reports:", module_config$reports_dir, "\n\n")
  
  # 3. PROCESAMIENTO COMPLETO DE DATOS
  cat("Starting data processing...\n")
  processed_data <- complete_preprocessing(
    file_path = input_file,
    vaf_threshold = module_config$vaf_threshold,
    validate = TRUE,
    verbose = module_config$verbose
  )
  
  # 4. ANÁLISIS DE CALIDAD BÁSICO
  cat("\nPerforming basic quality analysis...\n")
  quality_analysis <- perform_basic_quality_analysis(processed_data, module_config)
  
  # 5. GENERAR FIGURAS DE DISTRIBUCIÓN
  cat("\nGenerating distribution plots...\n")
  distribution_plots <- generate_distribution_plots(processed_data, module_config)
  
  # 6. GUARDAR DATOS PROCESADOS
  cat("\nSaving processed data...\n")
  save_processed_data(
    data = processed_data$data,
    file_path = file.path(module_config$tables_dir, "processed_data.csv"),
    metadata = list(
      preprocessing_summary = processed_data$preprocessing_summary,
      quality_analysis = quality_analysis,
      config = module_config
    ),
    format = "csv"
  )
  
  # 7. GUARDAR METADATOS DE MUESTRAS
  write.csv(
    processed_data$sample_metadata,
    file.path(module_config$tables_dir, "sample_metadata.csv"),
    row.names = FALSE
  )
  
  # 8. GENERAR REPORTE DE RESUMEN
  cat("\nGenerating summary report...\n")
  summary_report <- generate_summary_report(processed_data, quality_analysis, module_config)
  
  # 9. GUARDAR REPORTE
  writeLines(summary_report, file.path(module_config$reports_dir, "summary.txt"))
  
  # 10. RESUMEN FINAL
  cat("\n=== MODULE 1 COMPLETED ===\n")
  cat("Completed at:", Sys.time(), "\n")
  cat("Output directory:", module_config$output_dir, "\n")
  cat("Files generated:\n")
  cat("  - Processed data: processed_data.csv\n")
  cat("  - Sample metadata: sample_metadata.csv\n")
  cat("  - Quality analysis: quality_analysis.json\n")
  cat("  - Distribution plots: ", length(distribution_plots), " figures\n")
  cat("  - Summary report: summary.txt\n")
  
  return(list(
    processed_data = processed_data,
    quality_analysis = quality_analysis,
    distribution_plots = distribution_plots,
    config = config,
    summary_report = summary_report
  ))
}

# =============================================================================
# FUNCIONES AUXILIARES
# =============================================================================

#' Perform Basic Quality Analysis
#'
#' Performs basic quality control analysis on processed data
#'
#' @param processed_data list from complete_preprocessing
#' @param config list with module configuration
#' 
#' @return list with quality analysis results
#' 
#' @export
perform_basic_quality_analysis <- function(processed_data, module_config) {
  
  data <- processed_data$data
  structure <- processed_data$structure
  
  # Identificar columnas VAF
  vaf_cols <- paste0(structure$pairs$count_col, "_VAF")
  
  # 1. ANÁLISIS DE COBERTURA
  coverage_analysis <- list()
  
  # Cobertura por muestra
  total_cols <- structure$total_cols
  sample_coverage <- data %>%
    select(all_of(total_cols)) %>%
    summarise_all(list(
      mean = ~mean(.x, na.rm = TRUE),
      median = ~median(.x, na.rm = TRUE),
      min = ~min(.x, na.rm = TRUE),
      max = ~max(.x, na.rm = TRUE),
      zero_prop = ~mean(.x == 0, na.rm = TRUE)
    ))
  
  coverage_analysis$sample_coverage <- sample_coverage
  
  # 2. ANÁLISIS DE VAFs
  vaf_analysis <- list()
  
  # Estadísticas de VAF
  all_vafs <- unlist(data[vaf_cols])
  valid_vafs <- all_vafs[!is.na(all_vafs) & !is.nan(all_vafs)]
  
  vaf_analysis$statistics <- list(
    total_vafs = length(all_vafs),
    valid_vafs = length(valid_vafs),
    na_vafs = sum(is.na(all_vafs)),
    nan_vafs = sum(is.nan(all_vafs)),
    min_vaf = ifelse(length(valid_vafs) > 0, min(valid_vafs), NA),
    max_vaf = ifelse(length(valid_vafs) > 0, max(valid_vafs), NA),
    mean_vaf = ifelse(length(valid_vafs) > 0, mean(valid_vafs), NA),
    median_vaf = ifelse(length(valid_vafs) > 0, median(valid_vafs), NA)
  )
  
  # 3. ANÁLISIS DE MUTACIONES
  mutation_analysis <- list()
  
  # Distribución de tipos de mutación
  mutation_counts <- table(data$mutation_type, useNA = "ifany")
  mutation_analysis$mutation_distribution <- as.list(mutation_counts)
  
  # Análisis de posiciones
  position_analysis <- data %>%
    filter(!is_pm) %>%
    group_by(position) %>%
    summarise(
      n_mutations = n(),
      mean_vaf = mean(unlist(select(., all_of(vaf_cols))), na.rm = TRUE),
      .groups = "drop"
    )
  
  mutation_analysis$position_analysis <- position_analysis
  
  # 4. ANÁLISIS DE miRNAs
  mirna_analysis <- list()
  
  # Top miRNAs por número de SNVs
  top_mirnas <- data %>%
    group_by(`miRNA name`) %>%
    summarise(
      n_snvs = n(),
      n_gt_mutations = sum(mutation_type == "G>T", na.rm = TRUE),
      mean_vaf = mean(unlist(select(., all_of(vaf_cols))), na.rm = TRUE),
      .groups = "drop"
    ) %>%
    arrange(desc(n_snvs)) %>%
    head(20)
  
  mirna_analysis$top_mirnas <- top_mirnas
  
  # 5. GUARDAR ANÁLISIS DE CALIDAD
  quality_results <- list(
    coverage_analysis = coverage_analysis,
    vaf_analysis = vaf_analysis,
    mutation_analysis = mutation_analysis,
    mirna_analysis = mirna_analysis,
    timestamp = Sys.time()
  )
  
  # Guardar como JSON
  write_json(quality_results, file.path(module_config$tables_dir, "quality_analysis.json"), pretty = TRUE)
  
  return(quality_results)
}

#' Generate Distribution Plots
#'
#' Generates distribution plots for VAFs and other metrics
#'
#' @param processed_data list from complete_preprocessing
#' @param config list with module configuration
#' 
#' @return list with plot file paths
#' 
#' @export
generate_distribution_plots <- function(processed_data, module_config) {
  
  data <- processed_data$data
  structure <- processed_data$structure
  
  # Identificar columnas VAF
  vaf_cols <- paste0(structure$pairs$count_col, "_VAF")
  
  plots <- list()
  
  # 1. DISTRIBUCIÓN DE VAFs
  all_vafs <- unlist(data[vaf_cols])
  valid_vafs <- all_vafs[!is.na(all_vafs) & !is.nan(all_vafs)]
  
  if (length(valid_vafs) > 0) {
    p1 <- ggplot(data.frame(VAF = valid_vafs), aes(x = VAF)) +
      geom_histogram(bins = 50, fill = "steelblue", alpha = 0.7) +
      scale_x_log10() +
      labs(
        title = "Distribution of Variant Allele Frequencies (VAFs)",
        subtitle = paste("Valid VAFs:", length(valid_vafs), "| Threshold:", module_config$vaf_threshold),
        x = "VAF (log10 scale)",
        y = "Count"
      ) +
      theme_minimal() +
      geom_vline(xintercept = module_config$vaf_threshold, color = "red", linetype = "dashed")
    
    ggsave(
      file.path(module_config$figures_dir, "vaf_distribution.png"),
      p1, width = module_config$width, height = module_config$height, dpi = module_config$dpi
    )
    plots$vaf_distribution <- "vaf_distribution.png"
  }
  
  # 2. DISTRIBUCIÓN DE TIPOS DE MUTACIÓN
  mutation_counts <- table(data$mutation_type, useNA = "ifany")
  mutation_df <- data.frame(
    Mutation_Type = names(mutation_counts),
    Count = as.numeric(mutation_counts)
  )
  
  p2 <- ggplot(mutation_df, aes(x = reorder(Mutation_Type, Count), y = Count)) +
    geom_bar(stat = "identity", fill = "darkgreen", alpha = 0.7) +
    coord_flip() +
    labs(
      title = "Distribution of Mutation Types",
      x = "Mutation Type",
      y = "Count"
    ) +
    theme_minimal()
  
  ggsave(
    file.path(module_config$figures_dir, "mutation_type_distribution.png"),
    p2, width = module_config$width, height = module_config$height, dpi = module_config$dpi
  )
  plots$mutation_distribution <- "mutation_type_distribution.png"
  
  # 3. DISTRIBUCIÓN POR POSICIÓN
  position_data <- data %>%
    filter(!is_pm) %>%
    group_by(position) %>%
    summarise(
      n_mutations = n(),
      .groups = "drop"
    )
  
  if (nrow(position_data) > 0) {
    p3 <- ggplot(position_data, aes(x = position, y = n_mutations)) +
      geom_bar(stat = "identity", fill = "orange", alpha = 0.7) +
      geom_vline(xintercept = c(2, 8), color = "red", linetype = "dashed", alpha = 0.5) +
      annotate("text", x = 5, y = max(position_data$n_mutations) * 0.9, 
               label = "Seed Region (2-8)", color = "red") +
      labs(
        title = "Distribution of Mutations by Position",
        subtitle = "Red lines indicate seed region boundaries",
        x = "Position in miRNA",
        y = "Number of Mutations"
      ) +
      theme_minimal()
    
    ggsave(
      file.path(module_config$figures_dir, "position_distribution.png"),
      p3, width = module_config$width, height = module_config$height, dpi = module_config$dpi
    )
    plots$position_distribution <- "position_distribution.png"
  }
  
  return(plots)
}

#' Generate Summary Report
#'
#' Generates a text summary report for Module 1
#'
#' @param processed_data list from complete_preprocessing
#' @param quality_analysis list from perform_basic_quality_analysis
#' @param config list with module configuration
#' 
#' @return character vector with summary report
#' 
#' @export
generate_summary_report <- function(processed_data, quality_analysis, module_config) {
  
  data <- processed_data$data
  structure <- processed_data$structure
  
  report <- c(
    "=============================================================================",
    "MODULE 1: DATA LOADING AND INITIAL PROCESSING - SUMMARY REPORT",
    "=============================================================================",
    "",
    paste("Generated at:", Sys.time()),
    paste("Input file: [processed from original dataset]"),
    "",
    "=== DATASET OVERVIEW ===",
    paste("Total samples:", structure$n_samples),
    paste("Total SNVs:", nrow(data)),
    paste("Unique miRNAs:", structure$n_mirnas),
    paste("Total columns:", ncol(data)),
    "",
    "=== PREPROCESSING SUMMARY ===",
    paste("Original SNVs:", processed_data$preprocessing_summary$original_snvs),
    paste("Final SNVs:", processed_data$preprocessing_summary$final_snvs),
    paste("VAF threshold applied:", processed_data$preprocessing_summary$vaf_threshold),
    "",
    "=== QUALITY ANALYSIS ===",
    paste("Valid VAFs:", quality_analysis$vaf_analysis$statistics$valid_vafs),
    paste("NA VAFs:", quality_analysis$vaf_analysis$statistics$na_vafs),
    paste("NaN VAFs (filtered):", quality_analysis$vaf_analysis$statistics$nan_vafs),
    "",
    "=== MUTATION DISTRIBUTION ===",
    paste("Perfect Matches (PM):", quality_analysis$mutation_analysis$mutation_distribution$PM),
    paste("G>T mutations:", quality_analysis$mutation_analysis$mutation_distribution$`G>T`),
    paste("Other mutations:", sum(quality_analysis$mutation_analysis$mutation_distribution[!names(quality_analysis$mutation_analysis$mutation_distribution) %in% c("PM", "G>T")])),
    "",
    "=== TOP 10 miRNAs BY SNV COUNT ===",
    ""
  )
  
  # Agregar top miRNAs
  top_mirnas <- quality_analysis$mirna_analysis$top_mirnas
  for (i in 1:min(10, nrow(top_mirnas))) {
    report <- c(report, 
      paste(sprintf("%2d.", i), top_mirnas$`miRNA name`[i], 
            "- SNVs:", top_mirnas$n_snvs[i], 
            "- G>T:", top_mirnas$n_gt_mutations[i]))
  }
  
  report <- c(report,
    "",
    "=== FILES GENERATED ===",
    "  - processed_data.csv: Main processed dataset",
    "  - sample_metadata.csv: Sample metadata and parsing",
    "  - quality_analysis.json: Detailed quality analysis",
    paste("  -", length(quality_analysis), "distribution plots"),
    "  - summary.txt: This summary report",
    "",
    "=== NEXT STEPS ===",
    "Ready for Module 2: General Overview Analysis",
    "",
    "============================================================================="
  )
  
  return(report)
}
