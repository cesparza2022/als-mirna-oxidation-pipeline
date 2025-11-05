#!/usr/bin/env Rscript
# ============================================================================
# SCRIPT MAESTRO: EJECUTAR PIPELINE CON DIFERENTES UMBRALES
# Permite ajustar FC, p-value para explorar más o menos candidatos
# ============================================================================

library(jsonlite)
library(dplyr)
library(readr)
library(stringr)

# ============================================================================
# CARGAR CONFIGURACIÓN
# ============================================================================

cat("\n")
cat("╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║     PIPELINE AJUSTABLE - SELECCIÓN DE CANDIDATOS ALS                 ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

# Leer configuración
config <- fromJSON("CONFIG_THRESHOLDS.json")

# Argumentos de línea de comandos
args <- commandArgs(trailingOnly = TRUE)

# Determinar preset a usar
if (length(args) > 0) {
  preset_name <- args[1]
} else {
  preset_name <- config$paso2_volcano_thresholds$current_preset
}

cat("📊 PRESET SELECCIONADO:", preset_name, "\n")

# Obtener umbrales
if (preset_name == "custom") {
  thresholds <- config$paso2_volcano_thresholds$custom
} else {
  thresholds <- config$paso2_volcano_thresholds$presets[[preset_name]]
}

cat("📋 UMBRALES:\n")
cat(sprintf("   • Fold Change: > %.2fx (log2FC > %.2f)\n", 
            thresholds$fc_threshold, thresholds$log2FC_threshold))
cat(sprintf("   • p-value: < %.2f\n", thresholds$pvalue_threshold))
cat(sprintf("   • Candidatos esperados: %s\n\n", thresholds$expected_candidates))

# ============================================================================
# PASO 2: RE-ANALIZAR VOLCANO PLOT CON NUEVOS UMBRALES
# ============================================================================

cat("🔬 PASO 2: RE-ANALIZANDO CON NUEVOS UMBRALES...\n")
cat(paste(rep("─", 70), collapse = ""), "\n\n")

# Cargar datos del Volcano Plot original
volcano_data <- read_csv("pipeline_2/VOLCANO_PLOT_DATA_PER_SAMPLE.csv", 
                         show_col_types = FALSE)

# Aplicar nuevos umbrales
candidates_als <- volcano_data %>%
  filter(
    log2FC > thresholds$log2FC_threshold,
    padj < thresholds$pvalue_threshold
  ) %>%
  arrange(padj)

cat(sprintf("✅ CANDIDATOS ALS IDENTIFICADOS: %d\n\n", nrow(candidates_als)))

if (nrow(candidates_als) == 0) {
  cat("⚠️ ADVERTENCIA: No se encontraron candidatos con estos umbrales\n")
  cat("   Sugerencia: Usar preset 'permissive' o 'exploratory'\n\n")
  quit(status = 0)
}

# Mostrar candidatos
cat("🔝 CANDIDATOS SELECCIONADOS:\n")
cat(paste(rep("─", 70), collapse = ""), "\n\n")

for (i in 1:min(nrow(candidates_als), 20)) {
  row <- candidates_als[i, ]
  fc <- round(2^row$log2FC, 2)
  
  cat(sprintf("[%d] %s\n", i, row$miRNA))
  cat(sprintf("    FC: %.2fx (log2 = %.2f)\n", fc, row$log2FC))
  cat(sprintf("    p-value: %.4f\n", row$padj))
  cat(sprintf("    ALS: %.4f | Control: %.4f\n\n", row$Mean_ALS, row$Mean_Control))
}

if (nrow(candidates_als) > 20) {
  cat(sprintf("... y %d más\n\n", nrow(candidates_als) - 20))
}

# Guardar candidatos
output_dir <- sprintf("results_threshold_%s", preset_name)
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

output_file <- file.path(output_dir, "ALS_candidates.csv")
write_csv(candidates_als, output_file)

cat(sprintf("💾 Candidatos guardados en: %s\n", output_file))

# ============================================================================
# COMPARACIÓN CON OTROS PRESETS
# ============================================================================

cat("\n")
cat(paste(rep("═", 70), collapse = ""), "\n")
cat("📊 COMPARACIÓN ENTRE PRESETS\n")
cat(paste(rep("═", 70), collapse = ""), "\n\n")

presets <- names(config$paso2_volcano_thresholds$presets)
comparison <- data.frame()

for (p in presets) {
  thresh <- config$paso2_volcano_thresholds$presets[[p]]
  n_candidates <- volcano_data %>%
    filter(
      log2FC > thresh$log2FC_threshold,
      padj < thresh$pvalue_threshold
    ) %>%
    nrow()
  
  comparison <- bind_rows(
    comparison,
    data.frame(
      Preset = p,
      FC_Threshold = sprintf("%.2f", thresh$fc_threshold),
      P_Threshold = sprintf("%.2f", thresh$pvalue_threshold),
      N_Candidates = n_candidates,
      Expected = thresh$expected_candidates
    )
  )
}

print(comparison)

# ============================================================================
# GENERAR FIGURA COMPARATIVA
# ============================================================================

cat("\n📊 Generando figura comparativa de presets...\n")

library(ggplot2)

fig <- ggplot(comparison, aes(x = reorder(Preset, N_Candidates), y = N_Candidates)) +
  geom_col(aes(fill = Preset), alpha = 0.8, width = 0.7) +
  geom_text(aes(label = N_Candidates), hjust = -0.3, size = 6, fontface = "bold") +
  coord_flip() +
  scale_fill_manual(values = c(
    "strict" = "#DC3545",
    "moderate" = "#FFC107", 
    "permissive" = "#28A745",
    "exploratory" = "#17A2B8"
  )) +
  labs(
    title = "Número de Candidatos ALS por Preset",
    subtitle = sprintf("Preset actual: %s", preset_name),
    x = NULL,
    y = "Número de Candidatos ALS"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
    legend.position = "none"
  ) +
  ylim(0, max(comparison$N_Candidates) * 1.15)

ggsave(file.path(output_dir, "COMPARACION_PRESETS.png"), fig, 
       width = 10, height = 6, dpi = 300)

cat("✅ Figura guardada\n\n")

# ============================================================================
# RECOMENDACIONES
# ============================================================================

cat(paste(rep("═", 70), collapse = ""), "\n")
cat("💡 RECOMENDACIONES\n")
cat(paste(rep("═", 70), collapse = ""), "\n\n")

n_current <- nrow(candidates_als)

cat(sprintf("Con el preset '%s' obtuviste %d candidatos.\n\n", preset_name, n_current))

if (n_current < 3) {
  cat("⚠️ MUY POCOS candidatos\n")
  cat("   → Sugerencia: Prueba 'permissive' o 'exploratory'\n")
  cat("   → Comando: Rscript RUN_WITH_THRESHOLDS.R permissive\n\n")
} else if (n_current >= 3 && n_current <= 10) {
  cat("✅ NÚMERO MANEJABLE de candidatos\n")
  cat("   → Bueno para análisis detallado\n")
  cat("   → Paso 3 tomará ~20-30 minutos\n\n")
} else if (n_current > 10 && n_current <= 30) {
  cat("⚠️ MUCHOS candidatos\n")
  cat("   → Paso 3 tomará 1-2 horas\n")
  cat("   → Considera 'moderate' o analizar en grupos\n\n")
} else {
  cat("❌ DEMASIADOS candidatos\n")
  cat("   → Paso 3 será muy lento (2+ horas)\n")
  cat("   → Usa 'moderate' o 'strict'\n\n")
}

# ============================================================================
# SIGUIENTE PASO
# ============================================================================

cat(paste(rep("═", 70), collapse = ""), "\n")
cat("🚀 SIGUIENTE PASO\n")
cat(paste(rep("═", 70), collapse = ""), "\n\n")

cat("Para ejecutar Paso 3 con estos candidatos:\n\n")
cat(sprintf("  cd pipeline_3/\n"))
cat(sprintf("  # Copiar candidatos a pipeline_3/data/\n"))
cat(sprintf("  cp ../%s/ALS_candidates.csv data/\n", output_dir))
cat(sprintf("  # Ejecutar pipeline completo\n"))
cat(sprintf("  Rscript RUN_PASO3_COMPLETE.R\n\n"))

cat("O para probar otro preset:\n\n")
cat("  Rscript RUN_WITH_THRESHOLDS.R permissive\n")
cat("  Rscript RUN_WITH_THRESHOLDS.R exploratory\n")
cat("  Rscript RUN_WITH_THRESHOLDS.R strict\n\n")

cat(paste(rep("═", 70), collapse = ""), "\n")
cat(sprintf("✅ ANÁLISIS COMPLETADO - Preset: %s\n", preset_name))
cat(sprintf("📁 Resultados en: %s/\n", output_dir))
cat(paste(rep("═", 70), collapse = ""), "\n\n")

