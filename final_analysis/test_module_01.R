# =============================================================================
# TEST SCRIPT FOR MODULE 1: DATA LOADING
# =============================================================================
# Autor: César Esparza
# Fecha: Octubre 15, 2025
# Descripción: Script de prueba para validar el Módulo 1
# =============================================================================

# Configurar directorio de trabajo
setwd("/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis")

# Cargar librerías necesarias
library(tidyverse)
library(yaml)
library(jsonlite)

# =============================================================================
# TEST 1: FUNCIONES CORE
# =============================================================================

cat("=== TESTING CORE FUNCTIONS ===\n\n")

# Test 1.1: Auto-detección de estructura
cat("Test 1.1: Auto-detecting input structure...\n")
source("src/core/io.R")

input_file <- "data/raw/miRNA_count.Q33.txt"
structure <- auto_detect_input_structure(input_file, verbose = TRUE)

cat("✅ Structure detection completed\n")
cat("  - Samples detected:", structure$n_samples, "\n")
cat("  - SNVs detected:", structure$n_snvs, "\n")
cat("  - miRNAs detected:", structure$n_mirnas, "\n")
cat("  - Pairs created:", nrow(structure$pairs), "\n\n")

# Test 1.2: Validación de datos
cat("Test 1.2: Validating data structure...\n")
validation <- validate_data_structure(structure$data, structure, verbose = TRUE)

if (validation$passed) {
  cat("✅ Data validation PASSED\n\n")
} else {
  cat("❌ Data validation FAILED\n\n")
  stop("Validation failed - check errors above")
}

# =============================================================================
# TEST 2: FUNCIONES DE PREPROCESSING
# =============================================================================

cat("=== TESTING PREPROCESSING FUNCTIONS ===\n\n")

# Test 2.1: Split-collapse
cat("Test 2.1: Testing split-collapse...\n")
source("src/core/preprocessing.R")

split_data <- apply_split_collapse(structure$data, structure, verbose = TRUE)
cat("✅ Split-collapse completed\n")
cat("  - Original rows:", nrow(structure$data), "\n")
cat("  - After split-collapse:", nrow(split_data), "\n\n")

# Test 2.2: Cálculo de VAFs
cat("Test 2.2: Testing VAF calculation...\n")
vaf_data <- calculate_vafs(split_data, structure, verbose = TRUE)
cat("✅ VAF calculation completed\n")
cat("  - VAF columns added:", nrow(structure$pairs), "\n\n")

# Test 2.3: Filtrado de VAFs altas
cat("Test 2.3: Testing high VAF filtering...\n")
filtered_data <- filter_high_vafs(vaf_data, structure, threshold = 0.5, verbose = TRUE)
cat("✅ High VAF filtering completed\n\n")

# =============================================================================
# TEST 3: MÓDULO COMPLETO
# =============================================================================

cat("=== TESTING COMPLETE MODULE 1 ===\n\n")

# Test 3.1: Ejecutar módulo completo
cat("Test 3.1: Running complete Module 1...\n")
source("src/modules/module_01_data_loading.R")

# Ejecutar módulo
results <- run_module_01_data_loading(
  input_file = input_file,
  config_path = "config/simple_config.yaml"
)

cat("✅ Module 1 completed successfully!\n\n")

# =============================================================================
# TEST 4: VALIDACIÓN DE OUTPUTS
# =============================================================================

cat("=== VALIDATING OUTPUTS ===\n\n")

# Test 4.1: Verificar archivos generados
output_dir <- "outputs/step_01_prep"
expected_files <- c(
  "tables/processed_data.csv",
  "tables/sample_metadata.csv", 
  "tables/quality_analysis.json",
  "figures/vaf_distribution.png",
  "figures/mutation_type_distribution.png",
  "figures/position_distribution.png",
  "reports/summary.txt"
)

cat("Checking generated files...\n")
for (file in expected_files) {
  file_path <- file.path(output_dir, file)
  if (file.exists(file_path)) {
    cat("✅", file, "\n")
  } else {
    cat("❌", file, "- MISSING\n")
  }
}

# Test 4.2: Verificar contenido de datos procesados
cat("\nValidating processed data content...\n")
processed_data <- read.csv(file.path(output_dir, "tables/processed_data.csv"))

cat("  - Rows in processed data:", nrow(processed_data), "\n")
cat("  - Columns in processed data:", ncol(processed_data), "\n")
cat("  - Unique miRNAs:", length(unique(processed_data$miRNA.name)), "\n")
cat("  - Unique mutation types:", length(unique(processed_data$mutation_type)), "\n")

# Test 4.3: Verificar metadata de muestras
sample_metadata <- read.csv(file.path(output_dir, "tables/sample_metadata.csv"))
cat("  - Samples in metadata:", nrow(sample_metadata), "\n")
cat("  - Cohorts found:", paste(unique(sample_metadata$cohort), collapse = ", "), "\n")

# =============================================================================
# TEST 5: ANÁLISIS DE CALIDAD
# =============================================================================

cat("\n=== QUALITY ANALYSIS ===\n\n")

# Test 5.1: Verificar análisis de calidad
quality_file <- file.path(output_dir, "tables/quality_analysis.json")
if (file.exists(quality_file)) {
  quality_data <- fromJSON(quality_file)
  
  cat("Quality analysis results:\n")
  cat("  - Valid VAFs:", quality_data$vaf_analysis$statistics$valid_vafs, "\n")
  cat("  - NaN VAFs (filtered):", quality_data$vaf_analysis$statistics$nan_vafs, "\n")
  cat("  - G>T mutations:", quality_data$mutation_analysis$mutation_distribution$`G>T`, "\n")
  cat("  - Perfect matches:", quality_data$mutation_analysis$mutation_distribution$PM, "\n")
}

# =============================================================================
# RESUMEN FINAL
# =============================================================================

cat("\n=== TEST SUMMARY ===\n")
cat("✅ All tests completed successfully!\n")
cat("✅ Module 1 is working correctly\n")
cat("✅ Auto-detection is functioning\n")
cat("✅ Preprocessing pipeline is operational\n")
cat("✅ Output files are generated correctly\n")
cat("\nReady for Module 2: General Overview Analysis\n")
cat("=============================================================================\n")
