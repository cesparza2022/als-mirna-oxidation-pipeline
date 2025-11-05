# ============================================================================
# COMMON FUNCTIONS FOR SNAKEMAKE PIPELINE
# ============================================================================
# Shared utility functions used across all pipeline steps

suppressPackageStartupMessages({
  library(tidyverse)
  library(readr)
  library(stringr)
})

# Source logging functions (robust method)
# NOTE: getwd() is used here as a fallback when snakemake@config is not available
# In Snakemake context, working directory is set to pipeline root, so this is safe
if (!exists("log_info")) {
  # Try to get snakemake_dir from config if available (Snakemake context)
  if (exists("snakemake") && !is.null(snakemake@config) && 
      !is.null(snakemake@config[["paths"]]) && 
      !is.null(snakemake@config[["paths"]][["snakemake_dir"]])) {
    script_dir <- snakemake@config[["paths"]][["snakemake_dir"]]
  } else {
    # Fallback: use getwd() (safe when executed via Snakemake or Rscript from pipeline root)
    script_dir <- getwd()
  }
  utils_dir <- file.path(script_dir, "scripts", "utils")
  
  logging_paths <- c(
    file.path(utils_dir, "logging.R"),
    "scripts/utils/logging.R"
  )
  
  for (log_path in logging_paths) {
    if (file.exists(log_path)) {
      source(log_path, local = TRUE)
      break
    }
  }
}

# Source error handling functions (standardized error handling)
if (!exists("safe_execute")) {
  # Try to get snakemake_dir from config if available (Snakemake context)
  if (exists("snakemake") && !is.null(snakemake@config) && 
      !is.null(snakemake@config[["paths"]]) && 
      !is.null(snakemake@config[["paths"]][["snakemake_dir"]])) {
    script_dir <- snakemake@config[["paths"]][["snakemake_dir"]]
  } else {
    # Fallback: use getwd() (safe when executed via Snakemake or Rscript from pipeline root)
    script_dir <- getwd()
  }
  utils_dir <- file.path(script_dir, "scripts", "utils")
  
  error_handling_paths <- c(
    file.path(utils_dir, "error_handling.R"),
    "scripts/utils/error_handling.R"
  )
  
  for (error_path in error_handling_paths) {
    if (file.exists(error_path)) {
      source(error_path, local = TRUE)
      break
    }
  }
  
  # If still not found, warn but don't fail (error handling is optional but recommended)
  if (!exists("safe_execute")) {
    cat("⚠️  Warning: error_handling.R not found. Standardized error handling unavailable.\n")
    cat("   Continuing without standardized error handling...\n")
  }
}

# Source pipeline input validation (standardized input validation)
if (!exists("validate_pipeline_inputs")) {
  # Try to get snakemake_dir from config if available (Snakemake context)
  if (exists("snakemake") && !is.null(snakemake@config) && 
      !is.null(snakemake@config[["paths"]]) && 
      !is.null(snakemake@config[["paths"]][["snakemake_dir"]])) {
    script_dir <- snakemake@config[["paths"]][["snakemake_dir"]]
  } else {
    # Fallback: use getwd() (safe when executed via Snakemake or Rscript from pipeline root)
    script_dir <- getwd()
  }
  utils_dir <- file.path(script_dir, "scripts", "utils")
  
  validation_paths <- c(
    file.path(utils_dir, "validate_pipeline_inputs.R"),
    "scripts/utils/validate_pipeline_inputs.R"
  )
  
  for (validation_path in validation_paths) {
    if (file.exists(validation_path)) {
      source(validation_path, local = TRUE)
      break
    }
  }
  
  # If still not found, warn but don't fail (validation is optional but recommended)
  if (!exists("validate_pipeline_inputs")) {
    cat("⚠️  Warning: validate_pipeline_inputs.R not found. Standardized input validation unavailable.\n")
    cat("   Continuing without standardized input validation...\n")
  }
}

# Source validation functions (robust method that works with Rscript/Snakemake)
# Try multiple methods to find validate_input.R
if (!exists("validate_input")) {
  # Try to get snakemake_dir from config if available (Snakemake context)
  if (exists("snakemake") && !is.null(snakemake@config) && 
      !is.null(snakemake@config[["paths"]]) && 
      !is.null(snakemake@config[["paths"]][["snakemake_dir"]])) {
    script_dir <- snakemake@config[["paths"]][["snakemake_dir"]]
  } else {
    # Fallback: use getwd() (Snakemake sets working directory to pipeline root)
    script_dir <- getwd()
  }
  utils_dir <- file.path(script_dir, "scripts", "utils")
  
  # Try multiple possible paths
  possible_paths <- c(
    file.path(utils_dir, "validate_input.R"),           # Most common case
    "scripts/utils/validate_input.R"                    # Relative from any location
  )
  
  # Try each path
  for (validate_path in possible_paths) {
    if (file.exists(validate_path)) {
      source(validate_path, local = TRUE)
      cat("✅ Loaded validation functions from:", validate_path, "\n")
      break
    }
  }
  
  # If still not found, warn but don't fail (validation is optional)
  if (!exists("validate_input")) {
    cat("⚠️  Warning: validate_input.R not found. Validation functions unavailable.\n")
    cat("   Searched in:", paste(possible_paths, collapse = ", "), "\n")
    cat("   Continuing without input validation...\n")
  }
}

# Professional colors (consistent across pipeline)
COLOR_GT <- "#D62728"  # Red for G>T (oxidation)
COLOR_CONTROL <- "grey60"
COLOR_ALS <- "#D62728"

# Load professional theme if available
# Try to get snakemake_dir from config if available (Snakemake context)
if (exists("snakemake") && !is.null(snakemake@config) && 
    !is.null(snakemake@config[["paths"]]) && 
    !is.null(snakemake@config[["paths"]][["snakemake_dir"]])) {
  theme_script_dir <- snakemake@config[["paths"]][["snakemake_dir"]]
} else {
  # Fallback: use getwd() (Snakemake sets working directory to pipeline root)
  theme_script_dir <- getwd()
}

theme_paths <- c(
  file.path(theme_script_dir, "scripts", "utils", "theme_professional.R"),
  "scripts/utils/theme_professional.R",
  file.path(dirname(theme_script_dir), "scripts/utils/theme_professional.R")
)

theme_loaded <- FALSE
for (theme_path in theme_paths) {
  if (file.exists(theme_path)) {
    source(theme_path, local = TRUE)
    theme_loaded <- TRUE
    break
  }
}

if (!theme_loaded) {
  # Fallback: try with getwd() as last resort
  if (file.exists("scripts/utils/theme_professional.R")) {
    source("scripts/utils/theme_professional.R", local = TRUE)
    theme_loaded <- TRUE
  } else {
    # Fallback theme
    theme_professional <- theme_minimal(base_size = 11) +
      theme(
        plot.title = element_text(size = 13, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 10, color = "grey40", hjust = 0.5),
        axis.title = element_text(size = 11, face = "bold"),
        axis.text = element_text(size = 10, color = "grey30"),
        panel.grid.major = element_line(color = "grey90", linewidth = 0.5),
        panel.grid.minor = element_line(color = "grey95", linewidth = 0.25)
      )
  }
}

# ============================================================================
# DATA LOADING FUNCTIONS
# ============================================================================

#' Load processed data from CSV file
#' 
#' @param input_file Path to the processed data CSV
#' @return Data frame with miRNA data
load_processed_data <- function(input_file) {
  if (!file.exists(input_file)) {
    stop(paste("❌ Input file not found:", input_file))
  }
  
  cat("📂 Loading data from:", input_file, "\n")
  data <- read_csv(input_file, show_col_types = FALSE)
  
  # Verify expected columns exist
  if (!"miRNA_name" %in% names(data) || !"pos.mut" %in% names(data)) {
    stop("❌ Input file missing required columns: 'miRNA_name' or 'pos.mut'")
  }
  
  sample_cols <- setdiff(names(data), c("miRNA_name", "pos.mut"))
  
  cat("   ✅ Data loaded:", nrow(data), "rows\n")
  cat("   ✅ Samples:", length(sample_cols), "\n")
  
  return(data)
}

#' Load and process raw data (TSV format with pos:mut column)
#' 
#' @param raw_file Path to raw TSV file (miRNA_count.Q33.txt)
#' @return Processed data frame with separated mutations
load_and_process_raw_data <- function(raw_file) {
  if (!file.exists(raw_file)) {
    stop(paste("❌ Raw file not found:", raw_file))
  }
  
  cat("📂 Loading raw data from:", raw_file, "\n")
  raw_data <- read_tsv(raw_file, show_col_types = FALSE)
  
  cat("   ✅ Raw data loaded:", nrow(raw_data), "rows\n")
  
  # Process data: separate rows and extract mutations
  processed_data <- raw_data %>%
    separate_rows(`pos:mut`, sep = ",") %>%
    filter(`pos:mut` != "PM") %>%
    separate(`pos:mut`, into = c("position", "mutation_type_raw"), sep = ":", remove = FALSE) %>%
    mutate(
      position = as.numeric(position),
      mutation_type = str_replace_all(mutation_type_raw, c(
        "TC" = "T>C", "AG" = "A>G", "GA" = "G>A", "CT" = "C>T",
        "TA" = "T>A", "GT" = "G>T", "TG" = "T>G", "AT" = "A>T",
        "CA" = "C>A", "CG" = "C>G", "GC" = "G>C", "AC" = "A>C"
      ))
    ) %>%
    filter(position >= 1 & position <= 22)
  
  cat("   ✅ Data processed:", nrow(processed_data), "SNVs\n")
  
  return(processed_data)
}

# ============================================================================
# OUTPUT DIRECTORIES
# ============================================================================

#' Ensure output directory exists
#' 
#' @param output_dir Path to output directory
ensure_output_dir <- function(output_dir) {
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
    cat("   📁 Created output directory:", output_dir, "\n")
  }
}

#' Validate that output file was created successfully
#' 
#' @param output_file Path to output file
#' @param min_size_bytes Minimum file size in bytes (default: 1000)
#' @param context Context string for error messages
#' @return TRUE if file exists and has minimum size, stops execution otherwise
validate_output_file <- function(output_file, min_size_bytes = 1000, context = "Output validation") {
  if (!file.exists(output_file)) {
    stop(paste("❌", context, "- Output file not created:", output_file))
  }
  
  file_size <- file.info(output_file)$size
  if (file_size < min_size_bytes) {
    stop(paste("❌", context, "- Output file too small (", file_size, "bytes):", output_file, 
               "\n   Expected at least", min_size_bytes, "bytes"))
  }
  
  if (exists("log_success")) {
    log_success(paste("Output file validated:", output_file, "(", file_size, "bytes)"))
  } else {
    cat("   ✅ Output file validated:", output_file, "(", file_size, "bytes)\n")
  }
  
  return(TRUE)
}

# ============================================================================
# PROFESSIONAL THEME FOR GGPLOT
# ============================================================================

theme_professional <- theme_classic() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5),
    axis.title = element_text(size = 11),
    axis.text = element_text(size = 10),
    legend.title = element_text(size = 11),
    legend.text = element_text(size = 10),
    strip.text = element_text(size = 11, face = "bold")
  )

# ============================================================================
# HEATMAP FILTERING FUNCTION
# ============================================================================
# Filters miRNAs based on configurable thresholds for heatmap generation
# This replaces hardcoded "top 50" or "all 301" approaches
# 
# Parameters:
#   - data: Data frame with miRNA data
#   - metadata: Sample metadata with Group column
#   - config: Configuration list with heatmap_filtering section
#   - sample_cols: Vector of sample column names
#   - statistical_results: Optional data frame with statistical test results
#   - rpm_data: Optional data frame with RPM (expression) data
#
# Returns:
#   - Vector of miRNA names that pass all filters
# ============================================================================

filter_mirnas_for_heatmap <- function(
  data,
  metadata,
  config,
  sample_cols,
  statistical_results = NULL,
  rpm_data = NULL
) {
  
  # Extract filtering thresholds from config
  filters <- config$analysis$heatmap_filtering
  
  cat("🔍 FILTERING miRNAs FOR HEATMAP:\n")
  cat("   Starting with:", length(unique(data$miRNA_name)), "miRNAs\n\n")
  
  # ============================================================================
  # FILTER 1: Require G>T in seed region
  # ============================================================================
  
  if (isTRUE(filters$require_seed_gt)) {
    seed_positions <- filters$seed_positions
    seed_pattern <- paste0("^(", paste(seed_positions, collapse = "|"), "):GT$")
    
    seed_gt_mirnas <- data %>%
      filter(str_detect(pos.mut, seed_pattern)) %>%
      distinct(miRNA_name) %>%
      pull(miRNA_name)
    
    data <- data %>% filter(miRNA_name %in% seed_gt_mirnas)
    cat("   ✅ Filter 1 (Seed G>T):", length(seed_gt_mirnas), "miRNAs\n")
  } else {
    cat("   ⏭️  Filter 1 (Seed G>T): SKIPPED\n")
  }
  
  # ============================================================================
  # FILTER 2: RPM threshold (if available)
  # ============================================================================
  
  if (!is.null(filters$min_rpm_mean) && !is.null(rpm_data) && 
      !is.na(filters$min_rpm_mean) && filters$min_rpm_mean > 0) {
    
    # Calculate mean RPM per miRNA
    rpm_summary <- rpm_data %>%
      group_by(miRNA_name) %>%
      summarise(
        mean_rpm = mean(estimated_rpm, na.rm = TRUE),
        median_rpm = median(estimated_rpm, na.rm = TRUE),
        .groups = "drop"
      )
    
    # Use mean or median based on config
    rpm_col <- if (!is.null(filters$min_rpm_median) && !is.na(filters$min_rpm_median)) {
      "median_rpm"
    } else {
      "mean_rpm"
    }
    
    rpm_threshold <- if (!is.null(filters$min_rpm_median) && !is.na(filters$min_rpm_median)) {
      filters$min_rpm_median
    } else {
      filters$min_rpm_mean
    }
    
    rpm_filtered <- rpm_summary %>%
      filter(.data[[rpm_col]] >= rpm_threshold) %>%
      pull(miRNA_name)
    
    data <- data %>% filter(miRNA_name %in% rpm_filtered)
    cat("   ✅ Filter 2 (RPM >=", rpm_threshold, "):", length(rpm_filtered), "miRNAs\n")
  } else {
    cat("   ⏭️  Filter 2 (RPM): SKIPPED (not available or disabled)\n")
  }
  
  # ============================================================================
  # FILTER 3: VAF thresholds
  # ============================================================================
  
  # Calculate VAF statistics per miRNA
  vaf_stats <- data %>%
    filter(str_detect(pos.mut, ":GT$")) %>%
    select(all_of(c("miRNA_name", "pos.mut", sample_cols))) %>%
    pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
    filter(!is.na(VAF), VAF > 0) %>%
    group_by(miRNA_name) %>%
    summarise(
      mean_vaf = mean(VAF, na.rm = TRUE),
      n_samples_with_vaf = n_distinct(Sample_ID),
      .groups = "drop"
    )
  
  # Apply VAF filters
  vaf_filtered <- vaf_stats %>%
    filter(
      mean_vaf >= filters$min_mean_vaf,
      n_samples_with_vaf >= filters$min_samples_with_vaf
    ) %>%
    pull(miRNA_name)
  
  data <- data %>% filter(miRNA_name %in% vaf_filtered)
  cat("   ✅ Filter 3 (VAF):", length(vaf_filtered), "miRNAs\n")
  cat("      - Mean VAF >=", filters$min_mean_vaf, "\n")
  cat("      - Detected in >=", filters$min_samples_with_vaf, "samples\n")
  
  # ============================================================================
  # FILTER 4: Statistical significance (if required)
  # ============================================================================
  
  if (isTRUE(filters$require_significance) && !is.null(statistical_results)) {
    alpha <- config$analysis$alpha
    
    if (filters$significance_method == "fdr") {
      # Filter by FDR
      sig_col <- if ("t_test_fdr" %in% names(statistical_results)) {
        "t_test_fdr"
      } else if ("wilcoxon_fdr" %in% names(statistical_results)) {
        "wilcoxon_fdr"
      } else {
        NULL
      }
      
      if (!is.null(sig_col)) {
        sig_mirnas <- statistical_results %>%
          filter(.data[[sig_col]] < alpha) %>%
          distinct(miRNA_name) %>%
          pull(miRNA_name)
        
        data <- data %>% filter(miRNA_name %in% sig_mirnas)
        cat("   ✅ Filter 4 (FDR <", alpha, "):", length(sig_mirnas), "miRNAs\n")
      } else {
        cat("   ⚠️  Filter 4 (Significance): FDR column not found, SKIPPED\n")
      }
    } else {
      # Filter by p-value
      pval_col <- if ("t_test_pvalue" %in% names(statistical_results)) {
        "t_test_pvalue"
      } else if ("wilcoxon_pvalue" %in% names(statistical_results)) {
        "wilcoxon_pvalue"
      } else {
        NULL
      }
      
      if (!is.null(pval_col)) {
        sig_mirnas <- statistical_results %>%
          filter(.data[[pval_col]] < alpha) %>%
          distinct(miRNA_name) %>%
          pull(miRNA_name)
        
        data <- data %>% filter(miRNA_name %in% sig_mirnas)
        cat("   ✅ Filter 4 (p-value <", alpha, "):", length(sig_mirnas), "miRNAs\n")
      } else {
        cat("   ⚠️  Filter 4 (Significance): p-value column not found, SKIPPED\n")
      }
    }
  } else {
    cat("   ⏭️  Filter 4 (Significance): SKIPPED\n")
  }
  
  # ============================================================================
  # FILTER 5: Position range (if specified)
  # ============================================================================
  
  if (!is.null(filters$position_range) && length(filters$position_range) == 2) {
    pos_min <- filters$position_range[1]
    pos_max <- filters$position_range[2]
    
    position_filtered <- data %>%
      mutate(position = as.numeric(str_extract(pos.mut, "^[0-9]+"))) %>%
      filter(position >= pos_min, position <= pos_max) %>%
      distinct(miRNA_name) %>%
      pull(miRNA_name)
    
    data <- data %>% filter(miRNA_name %in% position_filtered)
    cat("   ✅ Filter 5 (Positions", pos_min, "-", pos_max, "):", length(position_filtered), "miRNAs\n")
  } else {
    cat("   ⏭️  Filter 5 (Position range): SKIPPED (all positions)\n")
  }
  
  # ============================================================================
  # FILTER 6: Log2FC threshold (if doing differential analysis)
  # ============================================================================
  
  if (!is.null(filters$min_log2_fold_change) && !is.null(statistical_results) &&
      !is.na(filters$min_log2_fold_change)) {
    
    if ("log2_fold_change" %in% names(statistical_results)) {
      log2fc_filtered <- statistical_results %>%
        filter(abs(log2_fold_change) >= filters$min_log2_fold_change) %>%
        distinct(miRNA_name) %>%
        pull(miRNA_name)
      
      data <- data %>% filter(miRNA_name %in% log2fc_filtered)
      cat("   ✅ Filter 6 (|Log2FC| >=", filters$min_log2_fold_change, "):", length(log2fc_filtered), "miRNAs\n")
    } else {
      cat("   ⚠️  Filter 6 (Log2FC): log2_fold_change column not found, SKIPPED\n")
    }
  } else {
    cat("   ⏭️  Filter 6 (Log2FC): SKIPPED\n")
  }
  
  # ============================================================================
  # FINAL RESULT
  # ============================================================================
  
  final_mirnas <- unique(data$miRNA_name)
  
  cat("\n")
  cat("   ✅ FINAL:", length(final_mirnas), "miRNAs pass all filters\n")
  cat("\n")
  
  return(final_mirnas)
}
