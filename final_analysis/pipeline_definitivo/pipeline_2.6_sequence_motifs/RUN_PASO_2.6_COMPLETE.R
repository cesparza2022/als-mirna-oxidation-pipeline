#!/usr/bin/env Rscript
# ============================================================================
# MASTER SCRIPT: PASO 2.6 - Análisis de Motivos de Secuencia
# Ejecuta todo el análisis de motivos en orden
# ============================================================================

cat("\n")
cat("╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║       🧬 EJECUTANDO PASO 2.6 COMPLETO: Motivos de Secuencia          ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

start_time <- Sys.time()

# ============================================================================
# PASO 1: Obtener Secuencias y Contexto Trinucleótido
# ============================================================================

cat("📊 [1/2] Obteniendo secuencias y analizando contexto trinucleótido...\n")
cat(paste(rep("═", 70), collapse = ""), "\n\n")

tryCatch({
  source("01_download_mirbase_sequences.R")
  cat("\n✅ Paso 1 completado\n\n")
}, error = function(e) {
  cat("❌ Error en Paso 1:", conditionMessage(e), "\n")
  stop(e)
})

# ============================================================================
# PASO 2: Crear Sequence Logos
# ============================================================================

cat(paste(rep("═", 70), collapse = ""), "\n")
cat("📊 [2/2] Generando sequence logos...\n")
cat(paste(rep("═", 70), collapse = ""), "\n\n")

tryCatch({
  source("02_create_sequence_logos.R")
  cat("\n✅ Paso 2 completado\n\n")
}, error = function(e) {
  cat("❌ Error en Paso 2:", conditionMessage(e), "\n")
  stop(e)
})

# ============================================================================
# RESUMEN FINAL
# ============================================================================

end_time <- Sys.time()
elapsed <- difftime(end_time, start_time, units = "mins")

cat("\n")
cat("╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║                  ✅ PASO 2.6 COMPLETADO                              ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

cat(sprintf("⏱️  Tiempo total: %.1f minutos\n\n", elapsed))

cat("📁 ARCHIVOS GENERADOS:\n")
cat(paste(rep("─", 70), collapse = ""), "\n")
cat("  DATOS:\n")
cat("    • data/candidates_with_sequences.csv\n")
cat("    • data/snv_with_sequence_context.csv\n")
cat("    • data/trinucleotide_context_summary.csv\n")
cat("    • data/conservation_analysis.csv\n\n")
cat("  FIGURAS:\n")
cat("    • figures/LOGO_Position_2.png\n")
cat("    • figures/LOGO_Position_3.png\n")
cat("    • figures/LOGO_ALL_POSITIONS_COMBINED.png\n\n")
cat("  VISUALIZACIÓN:\n")
cat("    • VIEWER_SEQUENCE_LOGOS.html\n\n")

cat("🔥 HALLAZGOS:\n")
cat(paste(rep("─", 70), collapse = ""), "\n")

# Cargar resultados finales
context_summary <- read.csv("data/trinucleotide_context_summary.csv")
conservation <- read.csv("data/conservation_analysis.csv")

cat("\n  CONTEXTO TRINUCLEÓTIDO:\n")
print(context_summary)

cat("\n  CONSERVACIÓN POSICIONAL:\n")
print(conservation)

cat("\n")
cat(paste(rep("═", 70), collapse = ""), "\n")
cat("🚀 SIGUIENTE PASO: Ejecutar Paso 3 (Functional Analysis)\n")
cat(paste(rep("═", 70), collapse = ""), "\n\n")

cat("RECOMENDACIÓN: Usar TIER 3 (6 candidatos)\n")
cat("  • miR-21-5p, let-7d-5p, miR-1-3p\n")
cat("  • miR-185-5p, miR-24-3p, miR-423-3p\n\n")

