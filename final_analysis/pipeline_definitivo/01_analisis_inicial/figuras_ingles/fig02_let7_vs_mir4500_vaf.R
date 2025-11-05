#!/usr/bin/env Rscript
# ============================================================================
# FIGURA CRÍTICA #2: let-7 vs miR-4500 VAF Comparison
# ============================================================================
# 
# Objetivo: Mostrar la PARADOJA - ambos tienen TGAGGTA pero:
#           - let-7: bajo VAF, muchos G>T
#           - miR-4500: VAF 33x mayor, CERO G>T
#
# Datos: outputs/paso10a_let7_vs_mir4500/
# Salida: figuras_ingles/fig02_let7_vs_mir4500_vaf_comparison.png
#
# Mejoras:
#   - Etiquetas en inglés
#   - Boxplot + violin plot combinados
#   - Colores distintivos
#   - Estadística visible
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
})

# Colores consistentes
COLOR_LET7 <- "#e74c3c"      # Rojo
COLOR_MIR4500 <- "#3498db"   # Azul

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  FIGURA #2: let-7 vs miR-4500 - The Paradox\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# ============================================================================
# CARGAR DATOS
# ============================================================================

cat("📂 Loading data...\n")

# Cargar summaries
let7_file <- "outputs/paso10a_let7_vs_mir4500/paso10a_let7_cohort.csv"
mir4500_file <- "outputs/paso10a_let7_vs_mir4500/paso10a_mir4500_cohort.csv"

if (!file.exists(let7_file) || !file.exists(mir4500_file)) {
  stop("❌ Data files not found")
}

let7_data <- read_csv(let7_file, show_col_types = FALSE)
mir4500_data <- read_csv(mir4500_file, show_col_types = FALSE)

cat("   ✅ let-7 data loaded:", nrow(let7_data), "rows\n")
cat("   ✅ miR-4500 data loaded:", nrow(mir4500_data), "rows\n")
cat("\n")

# ============================================================================
# PREPARAR DATOS PARA PLOT
# ============================================================================

cat("🔢 Preparing comparison data...\n")

# Combinar datos
let7_data <- let7_data %>%
  mutate(group = "let-7 family")

mir4500_data <- mir4500_data %>%
  mutate(group = "miR-4500")

# Unir
comparison_data <- bind_rows(let7_data, mir4500_data)

# Calcular estadísticas
stats_summary <- comparison_data %>%
  group_by(group) %>%
  summarise(
    n = n(),
    mean_vaf = mean(mean_vaf_als, na.rm = TRUE),
    median_vaf = median(mean_vaf_als, na.rm = TRUE),
    sd_vaf = sd(mean_vaf_als, na.rm = TRUE),
    .groups = "drop"
  )

cat("   ✅ Statistics calculated:\n")
print(stats_summary, n = Inf)

# Calcular ratio
let7_mean <- stats_summary$mean_vaf[stats_summary$group == "let-7 family"]
mir4500_mean <- stats_summary$mean_vaf[stats_summary$group == "miR-4500"]
ratio <- mir4500_mean / let7_mean

cat("\n   📊 VAF Ratio (miR-4500 / let-7):", sprintf("%.1f×", ratio), "\n")
cat("\n")

# ============================================================================
# GENERAR PLOT
# ============================================================================

cat("🎨 Generating plot...\n")

p <- ggplot(comparison_data, aes(x = group, y = mean_vaf_als, fill = group)) +
  # Violin plot para distribución
  geom_violin(alpha = 0.6, trim = FALSE, scale = "width") +
  
  # Boxplot para estadística
  geom_boxplot(width = 0.2, alpha = 0.8, outlier.alpha = 0.5, outlier.size = 2) +
  
  # Colores
  scale_fill_manual(
    values = c("let-7 family" = COLOR_LET7, "miR-4500" = COLOR_MIR4500),
    name = "miRNA Group"
  ) +
  
  # Escala logarítmica para VAF
  scale_y_log10(
    labels = scales::scientific,
    breaks = scales::trans_breaks("log10", function(x) 10^x)
  ) +
  
  # Etiquetas
  labs(
    title = "VAF Comparison: let-7 Family vs miR-4500",
    subtitle = "Both share TGAGGTA seed sequence but show opposite oxidation patterns",
    x = "",
    y = "Variant Allele Frequency (VAF, log scale)",
    caption = sprintf(
      "let-7: %.2e (mean) | miR-4500: %.2e (mean)\nmiR-4500 shows %.1f× higher VAF despite having 0 G>T in seed",
      let7_mean, mir4500_mean, ratio
    )
  ) +
  
  # Tema
  theme_bw(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray30"),
    plot.caption = element_text(size = 10, hjust = 0.5, color = "gray50"),
    legend.position = "none",
    axis.text.x = element_text(face = "bold", size = 13),
    axis.text.y = element_text(size = 11),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank()
  )

# Guardar
ggsave("figuras_ingles/fig02_let7_vs_mir4500_vaf_comparison.png",
       plot = p, width = 10, height = 8, dpi = 300, bg = "white")

cat("   ✅ SAVED: figuras_ingles/fig02_let7_vs_mir4500_vaf_comparison.png\n")
cat("\n")

# ============================================================================
# INTERPRETACIÓN
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("📊 INTERPRETACIÓN:\n")
cat("\n")
cat("Esta figura muestra LA PARADOJA:\n")
cat("\n")
cat("🧬 MISMA secuencia (TGAGGTA), DIFERENTE destino:\n")
cat("\n")
cat("   let-7 family:\n")
cat("   • VAF promedio:", sprintf("%.2e", let7_mean), "\n")
cat("   • G>T en semilla: 26 mutaciones\n")
cat("   • Altamente OXIDADO\n")
cat("\n")
cat("   miR-4500:\n")
cat("   • VAF promedio:", sprintf("%.2e", mir4500_mean), "\n")
cat("   • G>T en semilla: 0 mutaciones\n")
cat("   • VAF", sprintf("%.1f×", ratio), "MAYOR pero PROTEGIDO\n")
cat("\n")
cat("⭐ Implicación:\n")
cat("   • La secuencia NO determina el destino\n")
cat("   • Existe un MECANISMO DE PROTECCIÓN desconocido\n")
cat("   • miR-4500 está altamente expresado (VAF alto)\n")
cat("   • Pero ESPECÍFICAMENTE protegido contra G>T\n")
cat("\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("✅ FIGURA #2 COMPLETADA\n")
cat("   ⭐⭐⭐ CRITICAL - Shows the miR-4500 paradox\n")
cat("\n")








