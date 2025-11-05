# =============================================================================
# CORE PREPROCESSING FUNCTIONS - Auto-detectable Data Processing
# =============================================================================
# Autor: César Esparza
# Fecha: Octubre 15, 2025
# Descripción: Funciones core para procesamiento de datos (split-collapse, VAF, filtrado)
# =============================================================================

# Cargar librerías necesarias
library(tidyverse)
library(stringr)
library(dplyr)

# =============================================================================
# FUNCIÓN 1: SPLIT-COLLAPSE (Separar múltiples mutaciones)
# =============================================================================

#' Apply Split-Collapse Operation
#'
#' Separates multiple mutations in pos:mut column and collapses duplicates
#' 
#' @param data data.frame with miRNA data
#' @param structure list from auto_detect_input_structure
#' @param verbose logical, print progress
#' 
#' @return data.frame with split-collapse applied
#' 
#' @export
apply_split_collapse <- function(data, structure, verbose = TRUE) {
  
  if (verbose) cat("=== APPLYING SPLIT-COLLAPSE ===\n\n")
  
  # Verificar columnas requeridas
  required_cols <- c("miRNA name", "pos:mut")
  if (!all(required_cols %in% colnames(data))) {
    stop("Error: Missing required columns: miRNA name, pos:mut")
  }
  
  # Identificar tipos de columnas
  count_cols <- structure$count_cols
  total_cols <- structure$total_cols
  
  if (verbose) {
    cat("Count columns:", length(count_cols), "\n")
    cat("Total columns:", length(total_cols), "\n")
    cat("Original rows:", nrow(data), "\n")
  }
  
  # PASO 1: Separar mutaciones múltiples
  if (verbose) cat("Step 1: Separating multiple mutations...\n")
  
  split_data <- data %>%
    separate_rows(`pos:mut`, sep = ",") %>%
    mutate(`pos:mut` = str_trim(`pos:mut`))
  
  if (verbose) cat("Rows after split:", nrow(split_data), "\n")
  
  # PASO 2: Aplicar collapse (sumar cuentas por miRNA + posición + mutación)
  if (verbose) cat("Step 2: Applying collapse...\n")
  
  collapsed_data <- split_data %>%
    group_by(`miRNA name`, `pos:mut`) %>%
    summarise(
      across(all_of(count_cols), ~sum(as.numeric(.x), na.rm = TRUE)),
      across(all_of(total_cols), ~first(.x)),  # Mantener el primer total (deberían ser iguales)
      .groups = "drop"
    )
  
  if (verbose) {
    cat("Rows after collapse:", nrow(collapsed_data), "\n")
    cat("Unique SNVs:", nrow(collapsed_data), "\n")
    cat("Unique miRNAs:", length(unique(collapsed_data$`miRNA name`)), "\n")
  }
  
  return(collapsed_data)
}

# =============================================================================
# FUNCIÓN 2: CALCULAR VAFs (Variant Allele Frequencies)
# =============================================================================

#' Calculate Variant Allele Frequencies
#'
#' Calculates VAF for each SNV in each sample
#' 
#' @param data data.frame with miRNA data (after split-collapse)
#' @param structure list from auto_detect_input_structure
#' @param verbose logical, print progress
#' 
#' @return data.frame with VAF columns added
#' 
#' @export
calculate_vafs <- function(data, structure, verbose = TRUE) {
  
  if (verbose) cat("=== CALCULATING VAFs ===\n\n")
  
  # Crear copia de datos
  vaf_data <- data
  
  # Calcular VAF para cada par (count, total)
  for (i in 1:nrow(structure$pairs)) {
    count_col <- structure$pairs$count_col[i]
    total_col <- structure$pairs$total_col[i]
    vaf_col <- paste0(count_col, "_VAF")
    
    if (verbose && i <= 3) {
      cat("Calculating VAF for:", count_col, "\n")
    }
    
    # VAF = Count / Total (con manejo de división por cero)
    vaf_data[[vaf_col]] <- ifelse(
      vaf_data[[total_col]] > 0,
      vaf_data[[count_col]] / vaf_data[[total_col]],
      NA
    )
  }
  
  if (verbose) {
    cat("VAF columns added:", nrow(structure$pairs), "\n")
    cat("Total columns:", ncol(vaf_data), "\n")
    
    # Estadísticas de VAF
    vaf_cols <- paste0(structure$pairs$count_col, "_VAF")
    all_vafs <- unlist(vaf_data[vaf_cols])
    all_vafs <- all_vafs[!is.na(all_vafs)]
    
    cat("VAF statistics:\n")
    cat("  Min VAF:    ", sprintf("%.6f", min(all_vafs)), "\n")
    cat("  Max VAF:    ", sprintf("%.6f", max(all_vafs)), "\n")
    cat("  Mean VAF:   ", sprintf("%.6f", mean(all_vafs)), "\n")
    cat("  Median VAF: ", sprintf("%.6f", median(all_vafs)), "\n")
  }
  
  return(vaf_data)
}

# =============================================================================
# FUNCIÓN 3: FILTRAR VAFs ALTAS
# =============================================================================

#' Filter High VAFs
#'
#' Converts VAFs above threshold to NaN (for isoforms, not oxidation)
#' 
#' @param vaf_data data.frame with VAF columns
#' @param structure list from auto_detect_input_structure
#' @param threshold numeric, VAF threshold (default 0.5)
#' @param verbose logical, print progress
#' 
#' @return data.frame with high VAFs converted to NaN
#' 
#' @export
filter_high_vafs <- function(vaf_data, structure, threshold = 0.5, verbose = TRUE) {
  
  if (verbose) cat("=== FILTERING HIGH VAFs ===\n\n")
  
  # Crear copia de datos
  filtered_data <- vaf_data
  
  # Identificar columnas VAF
  vaf_cols <- paste0(structure$pairs$count_col, "_VAF")
  
  # Contar VAFs altas antes del filtrado
  high_vaf_count_before <- 0
  for (vaf_col in vaf_cols) {
    high_vaf_count_before <- high_vaf_count_before + 
      sum(filtered_data[[vaf_col]] > threshold, na.rm = TRUE)
  }
  
  # Convertir VAFs altas a NaN
  for (vaf_col in vaf_cols) {
    filtered_data[[vaf_col]] <- ifelse(
      filtered_data[[vaf_col]] > threshold,
      NaN,
      filtered_data[[vaf_col]]
    )
  }
  
  # Contar VAFs altas después del filtrado
  high_vaf_count_after <- 0
  for (vaf_col in vaf_cols) {
    high_vaf_count_after <- high_vaf_count_after + 
      sum(is.nan(filtered_data[[vaf_col]]))
  }
  
  if (verbose) {
    cat("VAF threshold:", threshold, "(", threshold*100, "%)\n")
    cat("High VAFs before filtering:", high_vaf_count_before, "\n")
    cat("High VAFs after filtering:", high_vaf_count_after, "\n")
    cat("High VAFs converted to NaN:", high_vaf_count_after, "\n")
    
    # Estadísticas de VAFs válidas (no NaN)
    all_vafs <- unlist(filtered_data[vaf_cols])
    valid_vafs <- all_vafs[!is.na(all_vafs) & !is.nan(all_vafs)]
    
    if (length(valid_vafs) > 0) {
      cat("\nValid VAF statistics (after filtering):\n")
      cat("  Min VAF:    ", sprintf("%.6f", min(valid_vafs)), "\n")
      cat("  Max VAF:    ", sprintf("%.6f", max(valid_vafs)), "\n")
      cat("  Mean VAF:   ", sprintf("%.6f", mean(valid_vafs)), "\n")
      cat("  Median VAF: ", sprintf("%.6f", median(valid_vafs)), "\n")
    }
  }
  
  return(filtered_data)
}

# =============================================================================
# FUNCIÓN 4: PARSING DE METADATOS DE MUESTRAS
# =============================================================================

#' Parse Sample Metadata
#'
#' Extracts metadata from sample names (cohort, timepoint, etc.)
#' 
#' @param sample_names character vector of sample names
#' @param verbose logical, print progress
#' 
#' @return data.frame with parsed metadata
#' 
#' @export
parse_sample_metadata <- function(sample_names, verbose = TRUE) {
  
  if (verbose) cat("=== PARSING SAMPLE METADATA ===\n\n")
  
  metadata <- data.frame(
    sample_name = sample_names,
    dataset = character(length(sample_names)),
    cohort = character(length(sample_names)),
    timepoint = character(length(sample_names)),
    tissue = character(length(sample_names)),
    seq_id = character(length(sample_names)),
    stringsAsFactors = FALSE
  )
  
  for (i in seq_along(sample_names)) {
    sample_name <- sample_names[i]
    
    # Split por guiones
    parts <- str_split(sample_name, "-")[[1]]
    
    if (length(parts) >= 5) {
      metadata$dataset[i] <- parts[1]
      metadata$cohort[i] <- parts[2]
      metadata$timepoint[i] <- parts[3]
      metadata$tissue[i] <- parts[4]
      metadata$seq_id[i] <- parts[5]
    } else {
      if (verbose) {
        warning("Sample name format not recognized: ", sample_name)
      }
      metadata$dataset[i] <- "unknown"
      metadata$cohort[i] <- "unknown"
      metadata$timepoint[i] <- "unknown"
      metadata$tissue[i] <- "unknown"
      metadata$seq_id[i] <- "unknown"
    }
  }
  
  if (verbose) {
    cat("Samples parsed:", nrow(metadata), "\n")
    cat("Cohorts found:", paste(unique(metadata$cohort), collapse = ", "), "\n")
    cat("Timepoints found:", paste(unique(metadata$timepoint), collapse = ", "), "\n")
    cat("Tissues found:", paste(unique(metadata$tissue), collapse = ", "), "\n")
  }
  
  return(metadata)
}

# =============================================================================
# FUNCIÓN 5: PARSING DE POS:MUT
# =============================================================================

#' Parse Position and Mutation Information
#'
#' Extracts position, original nucleotide, and mutated nucleotide from pos:mut
#' 
#' @param posmut_string character vector of pos:mut strings
#' 
#' @return data.frame with parsed mutation information
#' 
#' @export
parse_posmut <- function(posmut_string) {
  
  result <- data.frame(
    is_pm = logical(length(posmut_string)),
    position = integer(length(posmut_string)),
    original = character(length(posmut_string)),
    mutated = character(length(posmut_string)),
    mutation_type = character(length(posmut_string)),
    stringsAsFactors = FALSE
  )
  
  for (i in seq_along(posmut_string)) {
    posmut <- posmut_string[i]
    
    if (posmut == "PM") {
      result$is_pm[i] <- TRUE
      result$position[i] <- NA
      result$original[i] <- NA
      result$mutated[i] <- NA
      result$mutation_type[i] <- "PM"
    } else {
      result$is_pm[i] <- FALSE
      
      # Extraer posición
      position_match <- str_extract(posmut, "^\\d+")
      if (!is.na(position_match)) {
        result$position[i] <- as.integer(position_match)
      } else {
        result$position[i] <- NA
      }
      
      # Extraer mutación (2 letras después de ":")
      mutation_match <- str_extract(posmut, "(?<=:)[A-Z]{2}")
      if (!is.na(mutation_match) && nchar(mutation_match) == 2) {
        result$original[i] <- substr(mutation_match, 1, 1)
        result$mutated[i] <- substr(mutation_match, 2, 2)
        result$mutation_type[i] <- paste0(result$original[i], ">", result$mutated[i])
      } else {
        result$original[i] <- NA
        result$mutated[i] <- NA
        result$mutation_type[i] <- NA
      }
    }
  }
  
  return(result)
}

# =============================================================================
# FUNCIÓN 6: PIPELINE COMPLETO DE PREPROCESSING
# =============================================================================

#' Complete Preprocessing Pipeline
#'
#' Applies all preprocessing steps: split-collapse, VAF calculation, filtering
#' 
#' @param file_path character, path to input TSV file
#' @param vaf_threshold numeric, VAF threshold for filtering (default 0.5)
#' @param validate logical, perform validation
#' @param verbose logical, print progress
#' 
#' @return list with processed data and metadata
#' 
#' @export
complete_preprocessing <- function(file_path, vaf_threshold = 0.5, validate = TRUE, verbose = TRUE) {
  
  if (verbose) cat("=== COMPLETE PREPROCESSING PIPELINE ===\n\n")
  
  # 1. CARGAR Y VALIDAR DATOS
  structure <- load_and_validate_data(file_path, validate = validate, verbose = verbose)
  data <- structure$data
  
  # 2. APLICAR SPLIT-COLLAPSE
  split_collapsed_data <- apply_split_collapse(data, structure, verbose = verbose)
  
  # 3. CALCULAR VAFs
  vaf_data <- calculate_vafs(split_collapsed_data, structure, verbose = verbose)
  
  # 4. FILTRAR VAFs ALTAS
  filtered_data <- filter_high_vafs(vaf_data, structure, threshold = vaf_threshold, verbose = verbose)
  
  # 5. PARSING DE METADATOS
  sample_metadata <- parse_sample_metadata(structure$count_cols, verbose = verbose)
  
  # 6. PARSING DE POS:MUT
  mutation_metadata <- parse_posmut(filtered_data$`pos:mut`)
  
  # 7. COMBINAR METADATOS CON DATOS
  final_data <- cbind(filtered_data, mutation_metadata)
  
  # 8. RESUMEN FINAL
  if (verbose) {
    cat("\n=== PREPROCESSING COMPLETE ===\n")
    cat("Original SNVs:        ", structure$n_snvs, "\n")
    cat("Final SNVs:           ", nrow(final_data), "\n")
    cat("Samples:              ", structure$n_samples, "\n")
    cat("miRNAs:               ", structure$n_mirnas, "\n")
    cat("VAF threshold:        ", vaf_threshold, "\n")
    cat("Columns in final data:", ncol(final_data), "\n")
  }
  
  return(list(
    data = final_data,
    structure = structure,
    sample_metadata = sample_metadata,
    mutation_metadata = mutation_metadata,
    preprocessing_summary = list(
      original_snvs = structure$n_snvs,
      final_snvs = nrow(final_data),
      n_samples = structure$n_samples,
      n_mirnas = structure$n_mirnas,
      vaf_threshold = vaf_threshold
    )
  ))
}






