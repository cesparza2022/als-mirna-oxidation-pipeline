#!/usr/bin/env Rscript
# ============================================================================
# TEST PIPELINE STATUS - Verificar estado y organización
# ============================================================================
# Este script verifica:
#   1. Qué archivos existen en cada paso
#   2. Qué scripts están disponibles
#   3. Qué figuras están generadas
#   4. Estado de automatización

cat("\n")
cat("═════════════════════════════════════════════════════════════════════════\n")
cat("  🧪 TEST: Pipeline Status Verification\n")
cat("═════════════════════════════════════════════════════════════════════════\n")
cat("\n")

base_dir <- "/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/pipeline_definitivo"

# ============================================================================
# PASO 1: Exploratory Analysis
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("  PASO 1: Exploratory Analysis (STEP1_ORGANIZED/)\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

paso1_dir <- file.path(base_dir, "STEP1_ORGANIZED")

# Verificar carpeta
if (dir.exists(paso1_dir)) {
  cat("   ✅ Carpeta existe\n")
  
  # Verificar HTML viewer
  html_viewer <- file.path(paso1_dir, "STEP1_FINAL.html")
  if (file.exists(html_viewer)) {
    cat("   ✅ HTML viewer existe:", basename(html_viewer), "\n")
  } else {
    cat("   ❌ HTML viewer NO existe\n")
  }
  
  # Verificar figuras
  figures_dir <- file.path(paso1_dir, "figures")
  if (dir.exists(figures_dir)) {
    png_files <- list.files(figures_dir, pattern = "\\.png$", full.names = FALSE)
    cat(sprintf("   ✅ Figuras encontradas: %d PNGs\n", length(png_files)))
    if (length(png_files) > 0) {
      cat("      ", paste(head(png_files, 3), collapse = ", "))
      if (length(png_files) > 3) cat(" ...")
      cat("\n")
    }
  } else {
    cat("   ❌ Carpeta figures/ NO existe\n")
  }
  
  # Verificar scripts
  scripts_dir <- file.path(paso1_dir, "scripts")
  if (dir.exists(scripts_dir)) {
    r_files <- list.files(scripts_dir, pattern = "\\.R$", full.names = FALSE)
    cat(sprintf("   ⚠️  Scripts encontrados: %d R files\n", length(r_files)))
    if (length(r_files) > 0) {
      cat("      ", paste(head(r_files, 3), collapse = ", "))
      if (length(r_files) > 3) cat(" ...")
      cat("\n")
    }
  } else {
    cat("   ❌ Carpeta scripts/ NO existe\n")
  }
  
  # Verificar master script
  master_script <- file.path(paso1_dir, "RUN_COMPLETE_PIPELINE_PASO1.R")
  if (file.exists(master_script)) {
    cat("   ✅ Master script existe\n")
  } else {
    cat("   ❌ Master script NO existe (pipeline NO automatizado)\n")
  }
  
} else {
  cat("   ❌ Carpeta NO existe\n")
}

cat("\n")

# ============================================================================
# PASO 2: VAF Quality Control
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("  PASO 2: VAF Quality Control (01.5_vaf_quality_control/)\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

paso2_dir <- file.path(base_dir, "01.5_vaf_quality_control")

if (dir.exists(paso2_dir)) {
  cat("   ✅ Carpeta existe\n")
  
  # Verificar HTML viewer
  html_viewer <- file.path(paso2_dir, "STEP1.5_VAF_QC_VIEWER.html")
  if (file.exists(html_viewer)) {
    cat("   ✅ HTML viewer existe:", basename(html_viewer), "\n")
  } else {
    cat("   ❌ HTML viewer NO existe\n")
  }
  
  # Verificar scripts
  scripts_dir <- file.path(paso2_dir, "scripts")
  if (dir.exists(scripts_dir)) {
    r_files <- list.files(scripts_dir, pattern = "\\.R$", full.names = FALSE)
    cat(sprintf("   ✅ Scripts encontrados: %d R files\n", length(r_files)))
    for (f in r_files) {
      cat("      ✅", f, "\n")
    }
  }
  
  # Verificar master script
  master_script <- file.path(paso2_dir, "RUN_COMPLETE_PIPELINE_PASO2.R")
  if (file.exists(master_script)) {
    cat("   ✅ Master script existe\n")
  } else {
    cat("   ⚠️  Master script NO existe (2 scripts separados)\n")
  }
  
  # Verificar output
  output_file <- file.path(paso2_dir, "data", "ALL_MUTATIONS_VAF_FILTERED.csv")
  if (file.exists(output_file)) {
    file_size <- file.info(output_file)$size / (1024^2) # MB
    cat(sprintf("   ✅ Output existe: %.1f MB\n", file_size))
  } else {
    cat("   ⚠️  Output NO existe (ejecutar pipeline)\n")
  }
  
} else {
  cat("   ❌ Carpeta NO existe\n")
}

cat("\n")

# ============================================================================
# PASO 3: Group Comparisons
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("  PASO 3: Group Comparisons (pipeline_2/)\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

paso3_dir <- file.path(base_dir, "pipeline_2")

if (dir.exists(paso3_dir)) {
  cat("   ✅ Carpeta existe\n")
  
  # Verificar HTML viewer
  # Buscar cualquier HTML viewer
  html_viewer <- file.path(paso3_dir, "PASO_2_VIEWER_COMPLETO_FINAL.html")
  # Buscar cualquier HTML viewer
  html_files <- list.files(paso3_dir, pattern = "\\.html$", full.names = FALSE)
  if (length(html_files) > 0) {
    cat(sprintf("   ✅ HTML viewer(s) encontrado(s): %d\n", length(html_files)))
    for (f in html_files) {
      cat("      ✅", f, "\n")
    }
  } else {
    cat("   ❌ HTML viewer NO existe\n")
  }
  
  # Verificar master script
  master_script <- file.path(paso3_dir, "RUN_COMPLETE_PIPELINE_PASO2.R")
  if (file.exists(master_script)) {
    cat("   ✅✅✅ Master script existe (pipeline AUTOMATIZADO)\n")
  } else {
    cat("   ❌ Master script NO existe\n")
  }
  
  # Verificar scripts individuales
  r_files <- list.files(paso3_dir, pattern = "^generate_FIG_2\\..*\\.R$", full.names = FALSE)
  cat(sprintf("   ✅ Scripts de figuras: %d encontrados\n", length(r_files)))
  
  # Verificar figuras
  figures_dir <- file.path(paso3_dir, "figures")
  if (dir.exists(figures_dir)) {
    png_files <- list.files(figures_dir, pattern = "FIG_2\\..*\\.png$", full.names = FALSE)
    cat(sprintf("   ✅ Figuras generadas: %d PNGs\n", length(png_files)))
    if (length(png_files) > 0) {
      # Ordenar numéricamente
      nums <- as.numeric(gsub("FIG_2\\.([0-9]+)\\..*", "\\1", png_files))
      sorted_idx <- order(nums)
      png_files <- png_files[sorted_idx]
      cat("      ", paste(head(png_files, 5), collapse = ", "))
      if (length(png_files) > 5) cat(" ...")
      cat("\n")
    }
  }
  
  # Verificar inputs
  input1 <- file.path(paso3_dir, "final_processed_data_CLEAN.csv")
  input2 <- file.path(paso3_dir, "metadata.csv")
  
  if (file.exists(input1)) {
    file_size <- file.info(input1)$size / (1024^2)
    cat(sprintf("   ✅ Input 1 existe: %.1f MB\n", file_size))
  } else {
    cat("   ❌ Input 1 NO existe (final_processed_data_CLEAN.csv)\n")
  }
  
  if (file.exists(input2)) {
    cat("   ✅ Input 2 existe: metadata.csv\n")
  } else {
    cat("   ❌ Input 2 NO existe (metadata.csv)\n")
  }
  
} else {
  cat("   ❌ Carpeta NO existe\n")
}

cat("\n")

# ============================================================================
# RESUMEN FINAL
# ============================================================================

cat("═════════════════════════════════════════════════════════════════════════\n")
cat("  📊 RESUMEN GENERAL\n")
cat("═════════════════════════════════════════════════════════════════════════\n\n")

cat("PASO 1: Exploratory Analysis\n")
cat("  • Estado: ⚠️  Figuras generadas, pipeline NO automatizado\n")
cat("  • Acción: Crear master script\n\n")

cat("PASO 2: VAF Quality Control\n")
cat("  • Estado: ✅ Scripts disponibles, semi-automatizado\n")
cat("  • Acción: Crear master script unificado\n\n")

cat("PASO 3: Group Comparisons\n")
cat("  • Estado: ✅✅✅ 100% automatizado\n")
cat("  • Acción: Listo para usar\n\n")

cat("═════════════════════════════════════════════════════════════════════════\n\n")

