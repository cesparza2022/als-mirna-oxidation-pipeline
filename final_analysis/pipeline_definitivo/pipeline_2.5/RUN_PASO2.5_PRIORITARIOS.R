#!/usr/bin/env Rscript
# ============================================================================
# PASO 2.5: SCRIPT MAESTRO - ANÁLISIS PRIORITARIOS
# Ejecuta los 5 análisis esenciales de patrones
# ============================================================================

cat("\n")
cat("╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║     PASO 2.5: ANÁLISIS DE PATRONES (PRIORITARIOS)                    ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

start_time <- Sys.time()

# ============================================================================
# VERIFICAR INPUTS
# ============================================================================

cat("📋 Verificando inputs...\n")

if (!file.exists("../../results_threshold_permissive/ALS_candidates.csv")) {
  cat("❌ ERROR: No se encuentran candidatos\n")
  cat("   Ejecuta primero: Rscript RUN_WITH_THRESHOLDS.R permissive\n\n")
  quit(status = 1)
}

cat("   ✅ Candidatos encontrados\n\n")

# ============================================================================
# EJECUTAR ANÁLISIS
# ============================================================================

scripts <- c(
  "01_clustering_samples.R",
  "02_family_analysis.R",
  "03_seed_analysis.R",
  "04_trinucleotide_analysis.R",
  "05_als_vs_control.R"
)

for (i in seq_along(scripts)) {
  script <- scripts[i]
  cat(paste(rep("═", 70), collapse = ""), "\n")
  cat(sprintf("📊 [%d/5] Ejecutando: %s\n", i, script))
  cat(paste(rep("═", 70), collapse = ""), "\n\n")
  
  script_path <- file.path("scripts", script)
  
  if (file.exists(script_path)) {
    result <- system2("Rscript", args = script_path, stdout = TRUE, stderr = TRUE)
    cat(paste(result, collapse = "\n"))
    cat("\n\n")
  } else {
    cat(sprintf("⚠️ Script no encontrado: %s\n\n", script_path))
  }
}

# ============================================================================
# RESUMEN FINAL
# ============================================================================

end_time <- Sys.time()
elapsed <- round(as.numeric(difftime(end_time, start_time, units = "mins")), 1)

cat("\n")
cat(paste(rep("═", 70), collapse = ""), "\n")
cat("🎉 PASO 2.5 PRIORITARIOS COMPLETADO\n")
cat(paste(rep("═", 70), collapse = ""), "\n\n")

cat("⏱️  Tiempo total:", elapsed, "minutos\n\n")

cat("📊 FIGURAS GENERADAS (~12):\n")
cat("   CLUSTERING:\n")
cat("     • Heatmap samples x candidates\n")
cat("     • PCA samples\n")
cat("     • K-means ALS subtypes\n")
cat("     • Dendrograma\n")
cat("   FAMILIAS:\n")
cat("     • Familias barplot\n")
cat("     • Family enrichment\n")
cat("     • Volcano con familias\n")
cat("   SEEDS:\n")
cat("     • Seed positions heatmap\n")
cat("     • Positions barplot\n")
cat("     • Seed complexity\n")
cat("   ALS vs CONTROL:\n")
cat("     • Venn diagram\n")
cat("     • Families comparison\n")
cat("     • Volcano annotated\n\n")

cat("📁 Directorio: figures/\n\n")

cat("🚀 SIGUIENTE PASO:\n")
cat("   1. Revisar figuras y patrones\n")
cat("   2. Decidir qué candidatos usar para Paso 3\n")
cat("   3. Ejecutar: cd ../pipeline_3/ && Rscript RUN_PASO3_COMPLETE.R\n\n")

cat(paste(rep("═", 70), collapse = ""), "\n\n")

