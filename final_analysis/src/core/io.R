# =============================================================================
# CORE I/O FUNCTIONS - Auto-detectable Input Processing
# =============================================================================
# Autor: César Esparza
# Fecha: Octubre 15, 2025
# Descripción: Funciones core para lectura y validación de datos de entrada
# =============================================================================

# Cargar librerías necesarias
library(tidyverse)
library(stringr)
library(dplyr)

# =============================================================================
# FUNCIÓN 1: AUTO-DETECTAR ESTRUCTURA DEL INPUT
# =============================================================================

#' Auto-Detect Input File Structure
#'
#' Automatically identifies metadata, count, and total columns
#' Works with ANY number of samples, ANY number of SNVs
#'
#' @param file_path character, path to input TSV file
#' @param verbose logical, print detection summary
#' 
#' @return list with structure information
#' 
#' @export
auto_detect_input_structure <- function(file_path, verbose = TRUE) {
  
  if (verbose) cat("=== AUTO-DETECTING INPUT STRUCTURE ===\n\n")
  
  # 1. LEER HEADER
  header <- readLines(file_path, n = 1)
  cols <- str_split(header, "\t")[[1]]
  
  if (verbose) cat("Total columns detected:", length(cols), "\n")
  
  # 2. VALIDAR COLUMNAS METADATA
  if (cols[1] != "miRNA name") {
    stop("Column 1 must be 'miRNA name', found: ", cols[1])
  }
  if (cols[2] != "pos:mut") {
    stop("Column 2 must be 'pos:mut', found: ", cols[2])
  }
  
  metadata_cols <- cols[1:2]
  
  # 3. IDENTIFICAR TOTALES (por sufijo)
  total_pattern <- "\\(PM\\+1MM\\+2MM\\)$"
  total_cols <- cols[grepl(total_pattern, cols)]
  
  if (length(total_cols) == 0) {
    stop("No total columns found with pattern '(PM+1MM+2MM)'")
  }
  
  if (verbose) cat("Total columns found:", length(total_cols), "\n")
  
  # 4. IDENTIFICAR COUNTS (resto)
  count_cols <- setdiff(cols, c(metadata_cols, total_cols))
  
  if (length(count_cols) == 0) {
    stop("No count columns found")
  }
  
  if (verbose) cat("Count columns found:", length(count_cols), "\n")
  
  # 5. VALIDAR NÚMERO DE COLUMNAS
  expected_total <- 2 + length(count_cols) + length(total_cols)
  if (length(cols) != expected_total) {
    warning("Column count mismatch: expected ", expected_total, ", found ", length(cols))
  }
  
  # 6. VALIDAR PARIDAD
  if (length(count_cols) != length(total_cols)) {
    warning("Mismatch: ", length(count_cols), " counts vs ", length(total_cols), " totals")
  }
  
  # 7. EMPAREJAR COUNT-TOTAL
  pairs <- pair_count_total_columns(count_cols, total_cols)
  
  if (verbose) {
    cat("Successfully paired:  ", nrow(pairs), "/", length(count_cols), "\n")
    
    if (nrow(pairs) < length(count_cols)) {
      unpaired_counts <- setdiff(count_cols, pairs$count_col)
      cat("Unpaired counts:      ", length(unpaired_counts), "\n")
    }
  }
  
  # 8. LEER DATASET COMPLETO
  if (verbose) cat("\nReading full dataset...\n")
  data <- read.delim(file_path, stringsAsFactors = FALSE, check.names = FALSE)
  
  if (verbose) {
    cat("Data dimensions:      ", nrow(data), "×", ncol(data), "\n")
    cat("Unique miRNAs:        ", length(unique(data$`miRNA name`)), "\n")
    cat("Unique SNVs:          ", nrow(data), "\n")
  }
  
  # 9. RETORNAR ESTRUCTURA
  return(list(
    data = data,
    metadata_cols = metadata_cols,
    count_cols = count_cols,
    total_cols = total_cols,
    pairs = pairs,
    n_samples = nrow(pairs),
    n_snvs = nrow(data),
    n_mirnas = length(unique(data$`miRNA name`))
  ))
}

# =============================================================================
# FUNCIÓN 2: EMPAREJAR COUNT-TOTAL COLUMNS
# =============================================================================

#' Pair Count and Total Columns
#'
#' Matches each count column with its corresponding total column
#'
#' @param count_cols character vector of count column names
#' @param total_cols character vector of total column names
#' 
#' @return data.frame with count_col and total_col pairs
#' 
#' @export
pair_count_total_columns <- function(count_cols, total_cols) {
  
  pairs <- data.frame(
    count_col = character(),
    total_col = character(),
    stringsAsFactors = FALSE
  )
  
  for (count_col in count_cols) {
    # Construir nombre esperado de total
    expected_total <- paste0(count_col, " (PM+1MM+2MM)")
    
    # Buscar en total_cols
    if (expected_total %in% total_cols) {
      pairs <- rbind(pairs, data.frame(
        count_col = count_col,
        total_col = expected_total,
        stringsAsFactors = FALSE
      ))
    } else {
      warning("No se encontró total para count column: ", count_col)
    }
  }
  
  # Verificar que todos los totales fueron emparejados
  unpaired_totals <- setdiff(total_cols, pairs$total_col)
  if (length(unpaired_totals) > 0) {
    warning("Totales sin emparejar: ", length(unpaired_totals))
  }
  
  return(pairs)
}

# =============================================================================
# FUNCIÓN 3: VALIDAR ESTRUCTURA DE DATOS
# =============================================================================

#' Validate Data Structure
#'
#' Performs comprehensive validation of the input data structure
#'
#' @param data data.frame with miRNA data
#' @param structure list from auto_detect_input_structure
#' @param verbose logical, print validation details
#' 
#' @return list with validation results
#' 
#' @export
validate_data_structure <- function(data, structure, verbose = TRUE) {
  
  if (verbose) cat("=== VALIDATING DATA STRUCTURE ===\n\n")
  
  validation_results <- list(
    passed = TRUE,
    warnings = character(),
    errors = character()
  )
  
  # 1. VALIDAR DIMENSIONES
  expected_cols <- 2 + 2 * structure$n_samples
  actual_cols <- ncol(data)
  
  if (actual_cols != expected_cols) {
    validation_results$errors <- c(validation_results$errors, 
      paste("Column count mismatch: expected", expected_cols, "found", actual_cols))
    validation_results$passed <- FALSE
  }
  
  # 2. VALIDAR COLUMNAS METADATA
  if (!all(structure$metadata_cols %in% colnames(data))) {
    validation_results$errors <- c(validation_results$errors, 
      "Missing metadata columns")
    validation_results$passed <- FALSE
  }
  
  # 3. VALIDAR TIPOS DE DATOS
  # Count columns should be numeric
  for (col in structure$count_cols) {
    if (!is.numeric(data[[col]])) {
      validation_results$warnings <- c(validation_results$warnings, 
        paste("Count column", col, "is not numeric"))
    }
  }
  
  # Total columns should be numeric
  for (col in structure$total_cols) {
    if (!is.numeric(data[[col]])) {
      validation_results$warnings <- c(validation_results$warnings, 
        paste("Total column", col, "is not numeric"))
    }
  }
  
  # 4. VALIDAR VALORES NEGATIVOS
  for (col in c(structure$count_cols, structure$total_cols)) {
    if (any(data[[col]] < 0, na.rm = TRUE)) {
      validation_results$warnings <- c(validation_results$warnings, 
        paste("Negative values found in", col))
    }
  }
  
  # 5. VALIDAR CONSISTENCIA COUNT vs TOTAL
  for (i in 1:nrow(structure$pairs)) {
    count_col <- structure$pairs$count_col[i]
    total_col <- structure$pairs$total_col[i]
    
    # Count should not exceed total
    invalid_rows <- which(data[[count_col]] > data[[total_col]] & data[[total_col]] > 0)
    if (length(invalid_rows) > 0) {
      validation_results$warnings <- c(validation_results$warnings, 
        paste("Count exceeds total in", length(invalid_rows), "rows for", count_col))
    }
  }
  
  # 6. REPORTAR RESULTADOS
  if (verbose) {
    if (validation_results$passed) {
      cat("✅ Validation PASSED\n")
    } else {
      cat("❌ Validation FAILED\n")
    }
    
    if (length(validation_results$errors) > 0) {
      cat("\nERRORS:\n")
      for (error in validation_results$errors) {
        cat("  ❌", error, "\n")
      }
    }
    
    if (length(validation_results$warnings) > 0) {
      cat("\nWARNINGS:\n")
      for (warning in validation_results$warnings) {
        cat("  ⚠️", warning, "\n")
      }
    }
  }
  
  return(validation_results)
}

# =============================================================================
# FUNCIÓN 4: CARGAR Y VALIDAR DATOS
# =============================================================================

#' Load and Validate Input Data
#'
#' Complete pipeline for loading and validating input data
#'
#' @param file_path character, path to input TSV file
#' @param validate logical, perform validation
#' @param verbose logical, print progress
#' 
#' @return list with data and structure information
#' 
#' @export
load_and_validate_data <- function(file_path, validate = TRUE, verbose = TRUE) {
  
  if (verbose) cat("=== LOADING AND VALIDATING DATA ===\n\n")
  
  # 1. AUTO-DETECTAR ESTRUCTURA
  structure <- auto_detect_input_structure(file_path, verbose = verbose)
  
  # 2. VALIDAR (si se solicita)
  if (validate) {
    validation <- validate_data_structure(structure$data, structure, verbose = verbose)
    
    if (!validation$passed) {
      stop("Data validation failed. Check errors above.")
    }
  }
  
  # 3. RESUMEN FINAL
  if (verbose) {
    cat("\n=== LOADING COMPLETE ===\n")
    cat("File:                ", basename(file_path), "\n")
    cat("Samples:             ", structure$n_samples, "\n")
    cat("SNVs:                ", structure$n_snvs, "\n")
    cat("miRNAs:              ", structure$n_mirnas, "\n")
    cat("Columns:             ", ncol(structure$data), "\n")
    cat("Validation:          ", ifelse(validate, "PASSED", "SKIPPED"), "\n")
  }
  
  return(structure)
}

# =============================================================================
# FUNCIÓN 5: GUARDAR DATOS PROCESADOS
# =============================================================================

#' Save Processed Data
#'
#' Saves processed data with metadata
#'
#' @param data data.frame to save
#' @param file_path character, output file path
#' @param metadata list, additional metadata to save
#' @param format character, output format ("csv", "tsv", "rds")
#' 
#' @export
save_processed_data <- function(data, file_path, metadata = NULL, format = "csv") {
  
  # Crear directorio si no existe
  dir.create(dirname(file_path), recursive = TRUE, showWarnings = FALSE)
  
  # Guardar datos
  if (format == "csv") {
    write.csv(data, file_path, row.names = FALSE)
  } else if (format == "tsv") {
    write.table(data, file_path, sep = "\t", row.names = FALSE, quote = FALSE)
  } else if (format == "rds") {
    saveRDS(data, file_path)
  } else {
    stop("Unsupported format: ", format)
  }
  
  # Guardar metadata si se proporciona
  if (!is.null(metadata)) {
    metadata_path <- str_replace(file_path, "\\.[^.]+$", "_metadata.json")
    jsonlite::write_json(metadata, metadata_path, pretty = TRUE)
  }
  
  cat("Data saved to:", file_path, "\n")
  if (!is.null(metadata)) {
    cat("Metadata saved to:", metadata_path, "\n")
  }
}






