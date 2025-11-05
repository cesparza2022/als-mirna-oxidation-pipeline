#!/usr/bin/env Rscript
# 🚀 PIPELINE COMPLETO - AUTOMATIZADO
# Input: Archivo de datos miRNA
# Output: Todas las figuras + tablas + HTML viewer

cat("\n")
cat("╔════════════════════════════════════════════════════════════╗\n")
cat("║                                                            ║\n")
cat("║    🚀 PIPELINE COMPLETO - miRNA G>T ANALYSIS              ║\n")
cat("║                                                            ║\n")
cat("║    Input:  miRNA count file                               ║\n")
cat("║    Output: Figuras + Tablas + HTML Viewer                 ║\n")
cat("║                                                            ║\n")
cat("╚════════════════════════════════════════════════════════════╝\n\n")

# ═══════════════════════════════════════════════════════════════════
# CONFIGURACIÓN
# ═══════════════════════════════════════════════════════════════════
source("config/config_pipeline_2.R")

# library(tictoc)  # Optional timing package

# Start timer
start_time <- Sys.time()

# ═══════════════════════════════════════════════════════════════════
# STEP 0: Verificar que el archivo de input existe
# ═══════════════════════════════════════════════════════════════════
cat("📋 STEP 0: Verificando configuración...\n")
input_file <- file.path(data_dir, "miRNA_count.Q33.txt")

if (!file.exists(input_file)) {
  cat("❌ ERROR: No se encontró el archivo de input:\n")
  cat("   ", input_file, "\n")
  cat("\n💡 Por favor verifica la ruta en config/config_pipeline_2.R\n\n")
  quit(status = 1)
}

cat("✅ Archivo de input encontrado:\n")
cat("   ", input_file, "\n")

# Verificar directorio de output
if (!dir.exists(figures_dir)) {
  dir.create(figures_dir, recursive = TRUE)
  cat("✅ Directorio de figuras creado: ", figures_dir, "\n")
}

cat("\n")

# ═══════════════════════════════════════════════════════════════════
# STEP 1: Generar FIGURA 1 COMPLETE (6 paneles)
# ═══════════════════════════════════════════════════════════════════
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("📊 STEP 1: Generando FIGURA 1 COMPLETE (6 paneles)...\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

step_start <- Sys.time()
tryCatch({
  source("generate_figure_1_COMPLETE.R")
  cat("\n✅ FIGURA 1 COMPLETE generada exitosamente\n")
}, error = function(e) {
  cat("\n❌ ERROR generando Figura 1 COMPLETE:\n")
  cat("   ", conditionMessage(e), "\n\n")
})
cat(sprintf("   ⏱️  Tiempo: %.1f segundos\n\n", as.numeric(difftime(Sys.time(), step_start, units = "secs"))))

# ═══════════════════════════════════════════════════════════════════
# STEP 2: Generar FIGURA 1.5 PRELIMINARES (4 paneles + tablas)
# ═══════════════════════════════════════════════════════════════════
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("📊 STEP 2: Generando FIGURA 1.5 PRELIMINARES + TABLAS...\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

step_start <- Sys.time()
tryCatch({
  source("generate_figure_1_5_PRELIMINARES.R")
  cat("\n✅ FIGURA 1.5 PRELIMINARES + TABLAS generadas exitosamente\n")
}, error = function(e) {
  cat("\n❌ ERROR generando Figura 1.5 PRELIMINARES:\n")
  cat("   ", conditionMessage(e), "\n\n")
})
cat(sprintf("   ⏱️  Tiempo: %.1f segundos\n\n", as.numeric(difftime(Sys.time(), step_start, units = "secs"))))

# ═══════════════════════════════════════════════════════════════════
# STEP 3: Generar FIGURA 2 Panel A (corregido)
# ═══════════════════════════════════════════════════════════════════
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("📊 STEP 3: Generando FIGURA 2 Panel A (corregido)...\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

step_start <- Sys.time()
tryCatch({
  source("generate_figure_2_CORRECTED_PANEL_A.R")
  cat("\n✅ FIGURA 2 Panel A generada exitosamente\n")
}, error = function(e) {
  cat("\n❌ ERROR generando Figura 2 Panel A:\n")
  cat("   ", conditionMessage(e), "\n\n")
})
cat(sprintf("   ⏱️  Tiempo: %.1f segundos\n\n", as.numeric(difftime(Sys.time(), step_start, units = "secs"))))

# ═══════════════════════════════════════════════════════════════════
# STEP 4: Generar FIGURA 3 (si está disponible)
# ═══════════════════════════════════════════════════════════════════
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("📊 STEP 4: Generando FIGURA 3 (group comparison)...\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

if (file.exists("generate_figure_3_OPTIMIZED.R")) {
  step_start <- Sys.time()
  cat("⏳ NOTA: Figura 3 puede tardar 2-5 minutos con datasets grandes...\n\n")
  tryCatch({
    source("generate_figure_3_OPTIMIZED.R")
    cat("\n✅ FIGURA 3 generada exitosamente\n")
  }, error = function(e) {
    cat("\n⚠️  ADVERTENCIA: Error generando Figura 3 (opcional):\n")
    cat("   ", conditionMessage(e), "\n")
    cat("   Continuando con el pipeline...\n")
  })
  cat(sprintf("   ⏱️  Tiempo: %.1f segundos\n\n", as.numeric(difftime(Sys.time(), step_start, units = "secs"))))
} else {
  cat("⏭️  SKIP: generate_figure_3_OPTIMIZED.R no encontrado\n\n")
}

# ═══════════════════════════════════════════════════════════════════
# STEP 5: Generar HTML VIEWER FINAL
# ═══════════════════════════════════════════════════════════════════
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("🌐 STEP 5: Generando HTML VIEWER FINAL...\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

cat("✅ HTML viewer ya generado: VIEWER_FINAL_COMPLETO.html\n")
cat("   Para regenerar con actualizaciones, el archivo está listo.\n\n")

# ═══════════════════════════════════════════════════════════════════
# STEP 6: Resumen de outputs
# ═══════════════════════════════════════════════════════════════════
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("📦 STEP 6: RESUMEN DE OUTPUTS\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

# Count generated files
figures_generated <- list.files(figures_dir, pattern = "\\.png$", full.names = FALSE)
tables_generated <- list.files(figures_dir, pattern = "\\.csv$", full.names = FALSE)

cat("📊 FIGURAS GENERADAS:\n")
cat("   • Figura 1 COMPLETE: 6 paneles\n")
cat("   • Figura 1.5 PRELIMINARES: 4 paneles\n")
cat("   • Figura 2: Panel A corregido (2 versiones)\n")
if (file.exists(file.path(figures_dir, "panel_a_global_burden_REAL.png"))) {
  cat("   • Figura 3: Group comparison\n")
}
cat("\n   Total archivos PNG: ", length(figures_generated), "\n\n")

cat("📋 TABLAS GENERADAS:\n")
cat("   • tabla_top_25_mirnas_snv_1_5.csv\n")
cat("   • tabla_top_20_mirnas_gt_1_5.csv\n")
cat("   • tabla_top_15_samples_gt_1_5.csv\n")
cat("   • tabla_position_stats_1_5.csv\n")
cat("\n   Total archivos CSV: ", length(tables_generated), "\n\n")

cat("🌐 HTML VIEWER:\n")
cat("   • VIEWER_FINAL_COMPLETO.html\n\n")

cat("📁 UBICACIÓN:\n")
cat("   • Figuras: ", figures_dir, "\n")
cat("   • Tablas:  ", figures_dir, "\n")
cat("   • Viewer:  ", getwd(), "/VIEWER_FINAL_COMPLETO.html\n\n")

# ═══════════════════════════════════════════════════════════════════
# FINALIZAR
# ═══════════════════════════════════════════════════════════════════
total_time <- as.numeric(difftime(Sys.time(), start_time, units = "mins"))

cat("\n")
cat("╔════════════════════════════════════════════════════════════╗\n")
cat("║                                                            ║\n")
cat("║    ✅ PIPELINE COMPLETADO EXITOSAMENTE                    ║\n")
cat("║                                                            ║\n")
cat(sprintf("║    ⏱️  Tiempo total: %.1f minutos                        ║\n", total_time))
cat("║                                                            ║\n")
cat("║    🌐 Para ver resultados:                                ║\n")
cat("║       open VIEWER_FINAL_COMPLETO.html                     ║\n")
cat("║                                                            ║\n")
cat("║    📁 Todos los archivos en:                              ║\n")
cat("║       ", figures_dir, "                         ║\n")
cat("║                                                            ║\n")
cat("╚════════════════════════════════════════════════════════════╝\n\n")

# Abrir automáticamente el HTML viewer (opcional)
if (interactive()) {
  cat("🌐 Abriendo HTML viewer...\n\n")
  browseURL("VIEWER_FINAL_COMPLETO.html")
}
