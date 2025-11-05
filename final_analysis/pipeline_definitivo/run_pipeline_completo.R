#!/usr/bin/env Rscript
# ============================================================================
# RUNNER: PIPELINE COMPLETO - Ejecuta Paso 1 → 1.5 → 2
# ============================================================================
# Orquestador maestro que ejecuta todos los pasos del pipeline en secuencia

cat("\n")
cat("╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║          🚀 PIPELINE COMPLETO - Ejecutando todos los pasos          ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

# Get pipeline root directory
current_dir <- normalizePath(getwd())
if (basename(current_dir) %in% c("step1", "step1_5", "step2")) {
  root <- dirname(current_dir)
} else {
  root <- current_dir
}

cat("📁 Pipeline root:", root, "\n\n")

# ============================================================================
# STEP 1: Exploratory Analysis
# ============================================================================

cat("═══════════════════════════════════════════════════════════════════\n")
cat("  PASO 1: Análisis Exploratorio\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

step1_script <- file.path(root, "step1", "run_step1.R")
if (file.exists(step1_script)) {
  cat("▶️  Ejecutando Paso 1...\n\n")
  step1_start <- Sys.time()
  
  result <- tryCatch({
    system2("Rscript", step1_script, stdout = TRUE, stderr = TRUE)
  }, error = function(e) {
    cat("❌ Error en Paso 1:", e$message, "\n")
    return(NULL)
  })
  
  step1_elapsed <- as.numeric(difftime(Sys.time(), step1_start, units = "secs"))
  cat("\n✅ Paso 1 completado en", round(step1_elapsed, 1), "segundos\n\n")
} else {
  cat("⚠️  Paso 1 no encontrado:", step1_script, "\n\n")
}

# ============================================================================
# STEP 1.5: VAF Quality Control
# ============================================================================

cat("═══════════════════════════════════════════════════════════════════\n")
cat("  PASO 1.5: Control de Calidad VAF\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

step1_5_script <- file.path(root, "step1_5", "run_step1_5.R")
if (file.exists(step1_5_script)) {
  cat("▶️  Ejecutando Paso 1.5...\n\n")
  step1_5_start <- Sys.time()
  
  result <- tryCatch({
    system2("Rscript", step1_5_script, stdout = TRUE, stderr = TRUE)
  }, error = function(e) {
    cat("❌ Error en Paso 1.5:", e$message, "\n")
    return(NULL)
  })
  
  step1_5_elapsed <- as.numeric(difftime(Sys.time(), step1_5_start, units = "secs"))
  cat("\n✅ Paso 1.5 completado en", round(step1_5_elapsed, 1), "segundos\n\n")
} else {
  cat("⚠️  Paso 1.5 no encontrado:", step1_5_script, "\n\n")
}

# ============================================================================
# STEP 2: Comparative Analysis (ALS vs Control)
# ============================================================================

cat("═══════════════════════════════════════════════════════════════════\n")
cat("  PASO 2: Análisis Comparativo (ALS vs Control)\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

step2_script <- file.path(root, "step2", "run_step2.R")
if (file.exists(step2_script)) {
  cat("▶️  Ejecutando Paso 2...\n\n")
  step2_start <- Sys.time()
  
  result <- tryCatch({
    system2("Rscript", step2_script, stdout = TRUE, stderr = TRUE)
  }, error = function(e) {
    cat("❌ Error en Paso 2:", e$message, "\n")
    return(NULL)
  })
  
  step2_elapsed <- as.numeric(difftime(Sys.time(), step2_start, units = "secs"))
  cat("\n✅ Paso 2 completado en", round(step2_elapsed, 1), "segundos\n\n")
} else {
  cat("⚠️  Paso 2 no encontrado:", step2_script, "\n\n")
}

# ============================================================================
# SUMMARY
# ============================================================================

cat("╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║                    📊 RESUMEN FINAL                                 ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

cat("✅ PIPELINE COMPLETO EJECUTADO\n\n")

cat("📁 Viewers disponibles:\n")
if (file.exists(file.path(root, "step1", "viewers", "STEP1.html"))) {
  cat("   • Paso 1:", file.path(root, "step1", "viewers", "STEP1.html"), "\n")
}
if (file.exists(file.path(root, "step1_5", "viewers", "STEP1_5.html"))) {
  cat("   • Paso 1.5:", file.path(root, "step1_5", "viewers", "STEP1_5.html"), "\n")
}
if (file.exists(file.path(root, "step2", "viewers", "STEP2_EMBED.html"))) {
  cat("   • Paso 2:", file.path(root, "step2", "viewers", "STEP2_EMBED.html"), "\n")
}
cat("\n")

cat("🎉 ¡Todos los pasos completados exitosamente!\n\n")

# ============================================================================
# RUNNER: PIPELINE COMPLETO - Ejecuta Paso 1 → 1.5 → 2
# ============================================================================
# Orquestador maestro que ejecuta todos los pasos del pipeline en secuencia

cat("\n")
cat("╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║          🚀 PIPELINE COMPLETO - Ejecutando todos los pasos          ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

# Get pipeline root directory
current_dir <- normalizePath(getwd())
if (basename(current_dir) %in% c("step1", "step1_5", "step2")) {
  root <- dirname(current_dir)
} else {
  root <- current_dir
}

cat("📁 Pipeline root:", root, "\n\n")

# ============================================================================
# STEP 1: Exploratory Analysis
# ============================================================================

cat("═══════════════════════════════════════════════════════════════════\n")
cat("  PASO 1: Análisis Exploratorio\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

step1_script <- file.path(root, "step1", "run_step1.R")
if (file.exists(step1_script)) {
  cat("▶️  Ejecutando Paso 1...\n\n")
  step1_start <- Sys.time()
  
  result <- tryCatch({
    system2("Rscript", step1_script, stdout = TRUE, stderr = TRUE)
  }, error = function(e) {
    cat("❌ Error en Paso 1:", e$message, "\n")
    return(NULL)
  })
  
  step1_elapsed <- as.numeric(difftime(Sys.time(), step1_start, units = "secs"))
  cat("\n✅ Paso 1 completado en", round(step1_elapsed, 1), "segundos\n\n")
} else {
  cat("⚠️  Paso 1 no encontrado:", step1_script, "\n\n")
}

# ============================================================================
# STEP 1.5: VAF Quality Control
# ============================================================================

cat("═══════════════════════════════════════════════════════════════════\n")
cat("  PASO 1.5: Control de Calidad VAF\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

step1_5_script <- file.path(root, "step1_5", "run_step1_5.R")
if (file.exists(step1_5_script)) {
  cat("▶️  Ejecutando Paso 1.5...\n\n")
  step1_5_start <- Sys.time()
  
  result <- tryCatch({
    system2("Rscript", step1_5_script, stdout = TRUE, stderr = TRUE)
  }, error = function(e) {
    cat("❌ Error en Paso 1.5:", e$message, "\n")
    return(NULL)
  })
  
  step1_5_elapsed <- as.numeric(difftime(Sys.time(), step1_5_start, units = "secs"))
  cat("\n✅ Paso 1.5 completado en", round(step1_5_elapsed, 1), "segundos\n\n")
} else {
  cat("⚠️  Paso 1.5 no encontrado:", step1_5_script, "\n\n")
}

# ============================================================================
# STEP 2: Comparative Analysis (ALS vs Control)
# ============================================================================

cat("═══════════════════════════════════════════════════════════════════\n")
cat("  PASO 2: Análisis Comparativo (ALS vs Control)\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

step2_script <- file.path(root, "step2", "run_step2.R")
if (file.exists(step2_script)) {
  cat("▶️  Ejecutando Paso 2...\n\n")
  step2_start <- Sys.time()
  
  result <- tryCatch({
    system2("Rscript", step2_script, stdout = TRUE, stderr = TRUE)
  }, error = function(e) {
    cat("❌ Error en Paso 2:", e$message, "\n")
    return(NULL)
  })
  
  step2_elapsed <- as.numeric(difftime(Sys.time(), step2_start, units = "secs"))
  cat("\n✅ Paso 2 completado en", round(step2_elapsed, 1), "segundos\n\n")
} else {
  cat("⚠️  Paso 2 no encontrado:", step2_script, "\n\n")
}

# ============================================================================
# SUMMARY
# ============================================================================

cat("╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║                    📊 RESUMEN FINAL                                 ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

cat("✅ PIPELINE COMPLETO EJECUTADO\n\n")

cat("📁 Viewers disponibles:\n")
if (file.exists(file.path(root, "step1", "viewers", "STEP1.html"))) {
  cat("   • Paso 1:", file.path(root, "step1", "viewers", "STEP1.html"), "\n")
}
if (file.exists(file.path(root, "step1_5", "viewers", "STEP1_5.html"))) {
  cat("   • Paso 1.5:", file.path(root, "step1_5", "viewers", "STEP1_5.html"), "\n")
}
if (file.exists(file.path(root, "step2", "viewers", "STEP2_EMBED.html"))) {
  cat("   • Paso 2:", file.path(root, "step2", "viewers", "STEP2_EMBED.html"), "\n")
}
cat("\n")

cat("🎉 ¡Todos los pasos completados exitosamente!\n\n")

# ============================================================================
# RUNNER: PIPELINE COMPLETO - Ejecuta Paso 1 → 1.5 → 2
# ============================================================================
# Orquestador maestro que ejecuta todos los pasos del pipeline en secuencia

cat("\n")
cat("╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║          🚀 PIPELINE COMPLETO - Ejecutando todos los pasos          ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

# Get pipeline root directory
current_dir <- normalizePath(getwd())
if (basename(current_dir) %in% c("step1", "step1_5", "step2")) {
  root <- dirname(current_dir)
} else {
  root <- current_dir
}

cat("📁 Pipeline root:", root, "\n\n")

# ============================================================================
# STEP 1: Exploratory Analysis
# ============================================================================

cat("═══════════════════════════════════════════════════════════════════\n")
cat("  PASO 1: Análisis Exploratorio\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

step1_script <- file.path(root, "step1", "run_step1.R")
if (file.exists(step1_script)) {
  cat("▶️  Ejecutando Paso 1...\n\n")
  step1_start <- Sys.time()
  
  result <- tryCatch({
    system2("Rscript", step1_script, stdout = TRUE, stderr = TRUE)
  }, error = function(e) {
    cat("❌ Error en Paso 1:", e$message, "\n")
    return(NULL)
  })
  
  step1_elapsed <- as.numeric(difftime(Sys.time(), step1_start, units = "secs"))
  cat("\n✅ Paso 1 completado en", round(step1_elapsed, 1), "segundos\n\n")
} else {
  cat("⚠️  Paso 1 no encontrado:", step1_script, "\n\n")
}

# ============================================================================
# STEP 1.5: VAF Quality Control
# ============================================================================

cat("═══════════════════════════════════════════════════════════════════\n")
cat("  PASO 1.5: Control de Calidad VAF\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

step1_5_script <- file.path(root, "step1_5", "run_step1_5.R")
if (file.exists(step1_5_script)) {
  cat("▶️  Ejecutando Paso 1.5...\n\n")
  step1_5_start <- Sys.time()
  
  result <- tryCatch({
    system2("Rscript", step1_5_script, stdout = TRUE, stderr = TRUE)
  }, error = function(e) {
    cat("❌ Error en Paso 1.5:", e$message, "\n")
    return(NULL)
  })
  
  step1_5_elapsed <- as.numeric(difftime(Sys.time(), step1_5_start, units = "secs"))
  cat("\n✅ Paso 1.5 completado en", round(step1_5_elapsed, 1), "segundos\n\n")
} else {
  cat("⚠️  Paso 1.5 no encontrado:", step1_5_script, "\n\n")
}

# ============================================================================
# STEP 2: Comparative Analysis (ALS vs Control)
# ============================================================================

cat("═══════════════════════════════════════════════════════════════════\n")
cat("  PASO 2: Análisis Comparativo (ALS vs Control)\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

step2_script <- file.path(root, "step2", "run_step2.R")
if (file.exists(step2_script)) {
  cat("▶️  Ejecutando Paso 2...\n\n")
  step2_start <- Sys.time()
  
  result <- tryCatch({
    system2("Rscript", step2_script, stdout = TRUE, stderr = TRUE)
  }, error = function(e) {
    cat("❌ Error en Paso 2:", e$message, "\n")
    return(NULL)
  })
  
  step2_elapsed <- as.numeric(difftime(Sys.time(), step2_start, units = "secs"))
  cat("\n✅ Paso 2 completado en", round(step2_elapsed, 1), "segundos\n\n")
} else {
  cat("⚠️  Paso 2 no encontrado:", step2_script, "\n\n")
}

# ============================================================================
# SUMMARY
# ============================================================================

cat("╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║                    📊 RESUMEN FINAL                                 ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

cat("✅ PIPELINE COMPLETO EJECUTADO\n\n")

cat("📁 Viewers disponibles:\n")
if (file.exists(file.path(root, "step1", "viewers", "STEP1.html"))) {
  cat("   • Paso 1:", file.path(root, "step1", "viewers", "STEP1.html"), "\n")
}
if (file.exists(file.path(root, "step1_5", "viewers", "STEP1_5.html"))) {
  cat("   • Paso 1.5:", file.path(root, "step1_5", "viewers", "STEP1_5.html"), "\n")
}
if (file.exists(file.path(root, "step2", "viewers", "STEP2_EMBED.html"))) {
  cat("   • Paso 2:", file.path(root, "step2", "viewers", "STEP2_EMBED.html"), "\n")
}
cat("\n")

cat("🎉 ¡Todos los pasos completados exitosamente!\n\n")

