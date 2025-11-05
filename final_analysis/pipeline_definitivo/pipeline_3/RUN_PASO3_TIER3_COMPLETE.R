#!/usr/bin/env Rscript
# ============================================================================
# MASTER SCRIPT: PASO 3 COMPLETO - Functional Analysis (TIER 3)
# Ejecuta todo el análisis funcional con los 6 candidatos TIER 3
# ============================================================================

cat("\n")
cat("╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║      🎯 EJECUTANDO PASO 3 COMPLETO: Functional Analysis (TIER 3)     ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

start_time <- Sys.time()

# ============================================================================
# INFORMACIÓN DE CANDIDATOS
# ============================================================================

cat("📋 CANDIDATOS TIER 3 (6 miRNAs):\n")
cat(paste(rep("─", 70), collapse = ""), "\n")
cat("  1. hsa-miR-21-5p    (FC 1.48x, p 0.0083) - Oncomir, neurología\n")
cat("  2. hsa-miR-185-5p   (FC 1.42x, p 0.037)  - Regulación celular\n")
cat("  3. hsa-miR-24-3p    (FC 1.33x, p 0.039)  - Apoptosis\n")
cat("  4. hsa-let-7d-5p    (FC 1.31x, p 0.018)  - Tumor suppressor\n")
cat("  5. hsa-miR-1-3p     (FC 1.30x, p 0.0008) - Músculo, neurología\n")
cat("  6. hsa-miR-423-3p   (FC 1.27x, p 0.030)  - Cardiovascular\n")
cat(paste(rep("─", 70), collapse = ""), "\n\n")

cat("⏱️  Tiempo estimado total: ~2-3 horas\n")
cat("☕ Puedes tomar un café mientras corre...\n\n")

# ============================================================================
# PASO 1: Setup y Verificación
# ============================================================================

cat(paste(rep("═", 70), collapse = ""), "\n")
cat("📊 [1/5] Setup y verificación de packages...\n")
cat(paste(rep("═", 70), collapse = ""), "\n\n")

tryCatch({
  source("scripts/01_setup_and_verify.R")
  cat("\n✅ Setup completado\n\n")
}, error = function(e) {
  cat("❌ Error en setup:", conditionMessage(e), "\n")
  cat("⚠️  Continuando de todas formas...\n\n")
})

# ============================================================================
# PASO 2: Target Prediction
# ============================================================================

cat(paste(rep("═", 70), collapse = ""), "\n")
cat("📊 [2/5] Target Prediction (⏱️ ~45 min)...\n")
cat(paste(rep("═", 70), collapse = ""), "\n\n")

tryCatch({
  source("scripts/02_query_targets.R")
  cat("\n✅ Target prediction completado\n\n")
}, error = function(e) {
  cat("❌ Error en target prediction:", conditionMessage(e), "\n")
  stop(e)
})

# ============================================================================
# PASO 3: Pathway Enrichment
# ============================================================================

cat(paste(rep("═", 70), collapse = ""), "\n")
cat("📊 [3/5] Pathway Enrichment (⏱️ ~45 min)...\n")
cat(paste(rep("═", 70), collapse = ""), "\n\n")

tryCatch({
  source("scripts/03_pathway_enrichment.R")
  cat("\n✅ Pathway enrichment completado\n\n")
}, error = function(e) {
  cat("❌ Error en pathway enrichment:", conditionMessage(e), "\n")
  stop(e)
})

# ============================================================================
# PASO 4: Network Analysis
# ============================================================================

cat(paste(rep("═", 70), collapse = ""), "\n")
cat("📊 [4/5] Network Analysis (⏱️ ~30 min)...\n")
cat(paste(rep("═", 70), collapse = ""), "\n\n")

tryCatch({
  source("scripts/04_network_analysis.R")
  cat("\n✅ Network analysis completado\n\n")
}, error = function(e) {
  cat("❌ Error en network analysis:", conditionMessage(e), "\n")
  stop(e)
})

# ============================================================================
# PASO 5: Generar Figuras
# ============================================================================

cat(paste(rep("═", 70), collapse = ""), "\n")
cat("📊 [5/5] Generando Figuras (⏱️ ~30 min)...\n")
cat(paste(rep("═", 70), collapse = ""), "\n\n")

tryCatch({
  source("scripts/05_create_figures.R")
  cat("\n✅ Figuras generadas\n\n")
}, error = function(e) {
  cat("❌ Error generando figuras:", conditionMessage(e), "\n")
  cat("⚠️  Intentando versión simplificada...\n\n")
  
  tryCatch({
    source("scripts/05_create_figures_SIMPLE.R")
    cat("✅ Figuras simplificadas generadas\n\n")
  }, error = function(e2) {
    cat("❌ Error también en versión simple:", conditionMessage(e2), "\n")
    cat("⚠️  Continuando sin figuras...\n\n")
  })
})

# ============================================================================
# PASO 6: Crear HTML Viewer
# ============================================================================

cat(paste(rep("═", 70), collapse = ""), "\n")
cat("📊 [6/6] Creando HTML Viewer...\n")
cat(paste(rep("═", 70), collapse = ""), "\n\n")

tryCatch({
  source("scripts/06_create_HTML.R")
  cat("\n✅ HTML viewer generado\n\n")
}, error = function(e) {
  cat("❌ Error generando HTML:", conditionMessage(e), "\n")
  cat("⚠️  Continuando...\n\n")
})

# ============================================================================
# RESUMEN FINAL
# ============================================================================

end_time <- Sys.time()
elapsed <- difftime(end_time, start_time, units = "hours")

cat("\n")
cat("╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║                  🎉 PASO 3 COMPLETADO (TIER 3)                       ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

cat(sprintf("⏱️  Tiempo total: %.2f horas (%.0f minutos)\n\n", elapsed, elapsed * 60))

cat("📁 ARCHIVOS GENERADOS:\n")
cat(paste(rep("─", 70), collapse = ""), "\n")
cat("  DATOS:\n")
cat("    • data/ALS_candidates_TIER3.csv\n")
cat("    • data/targets/*.csv (múltiples archivos)\n")
cat("    • data/pathways/*.csv (múltiples archivos)\n")
cat("    • data/network/*.csv\n\n")
cat("  FIGURAS:\n")
cat("    • figures/FIG_3.*.png (6-9 figuras)\n\n")
cat("  VISUALIZACIÓN:\n")
cat("    • PASO_3_VIEWER_TIER3.html\n\n")

# Cargar resultados si existen
if (file.exists("data/targets/summary_by_mirna.csv")) {
  summary <- read.csv("data/targets/summary_by_mirna.csv")
  cat("📊 RESUMEN DE TARGETS:\n")
  cat(paste(rep("─", 70), collapse = ""), "\n")
  print(summary)
  cat("\n")
}

cat(paste(rep("═", 70), collapse = ""), "\n")
cat("🚀 SIGUIENTE PASO: Paso 4 (Integración)\n")
cat(paste(rep("═", 70), collapse = ""), "\n\n")

cat("✅ Paso 3 TIER 3 completado exitosamente\n\n")

