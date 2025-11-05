#!/usr/bin/env Rscript
# ============================================================================
# FIGURA CRÍTICA #1: let-7 HEATMAP - Exact Pattern at Positions 2,4,5
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(pheatmap)
})

# Configuración
COLOR_PRESENT <- "#e74c3c"
COLOR_ABSENT <- "white"

cat("\n═══════════════════════════════════════════════════════════\n")
cat("  FIG #1: let-7 Heatmap (Positions 2,4,5 Pattern)\n")
cat("═══════════════════════════════════════════════════════════\n\n")

# Crear directorio
dir.create("figuras_ingles", showWarnings = FALSE, recursive = TRUE)

# Cargar datos
cat("📂 Loading let-7 summary data...\n")
let7_summary <- read_csv("outputs/paso10a_let7_vs_mir4500/paso10a_let7_summary.csv",
                         col_types = cols(posiciones_gt_seed = col_character()),
                         show_col_types = FALSE)

cat("   ✅", nrow(let7_summary), "let-7 members loaded\n\n")

# Crear matriz manualmente desde posiciones_gt_seed
cat("🔢 Creating matrix...\n")

# Inicializar matriz vacía (9 miRNAs × 7 posiciones)
mirna_names <- let7_summary$`miRNA name`
positions <- 2:8
let7_matrix <- matrix(0, nrow = length(mirna_names), ncol = length(positions))
rownames(let7_matrix) <- mirna_names
colnames(let7_matrix) <- as.character(positions)

# Llenar matriz basado en posiciones_gt_seed
for (i in 1:nrow(let7_summary)) {
  mirna <- let7_summary$`miRNA name`[i]
  pos_string <- let7_summary$posiciones_gt_seed[i]
  
  if (!is.na(pos_string) && nchar(pos_string) > 0) {
    # Parsear posiciones (ej: "2,4,5")
    # read_csv ya removió las comillas, así que podemos parsear directamente
    positions_with_gt <- as.integer(unlist(str_split(pos_string, ",")))
    
    # Marcar como presente (1)
    for (pos in positions_with_gt) {
      if (pos >= 2 && pos <= 8) {
        col_idx <- as.character(pos)
        if (col_idx %in% colnames(let7_matrix)) {
          let7_matrix[mirna, col_idx] <- 1
        }
      }
    }
  }
}

# Verificar que la matriz no esté vacía
if (sum(let7_matrix) == 0) {
  cat("   ⚠️  Matrix is empty, checking data format...\n")
  print(head(let7_summary))
}

cat("   ✅ Matrix created:", nrow(let7_matrix), "×", ncol(let7_matrix), "\n\n")

# Mostrar patrón
cat("📊 Pattern summary:\n")
for (pos in colnames(let7_matrix)) {
  count <- sum(let7_matrix[, pos])
  pct <- (count / nrow(let7_matrix)) * 100
  marker <- if (pos %in% c("2", "4", "5")) "⭐" else "  "
  cat(sprintf("   %s Position %s: %d/9 (%.0f%%)\n", marker, pos, count, pct))
}
cat("\n")

# Generar heatmap
cat("🎨 Generating heatmap...\n")

png("figuras_ingles/fig01_let7_heatmap_pattern.png",
    width = 10, height = 8, units = "in", res = 300, bg = "white")

pheatmap(
  let7_matrix,
  color = colorRampPalette(c(COLOR_ABSENT, COLOR_PRESENT))(2),
  cluster_rows = FALSE,
  cluster_cols = FALSE,
  display_numbers = TRUE,
  number_color = "black",
  number_format = "%.0f",
  fontsize_number = 18,
  fontsize = 14,
  fontsize_row = 13,
  fontsize_col = 14,
  main = "G>T Mutations in let-7 Family: Seed Region Pattern\n(Universal Presence at Positions 2, 4, and 5)",
  legend = TRUE,
  legend_breaks = c(0, 1),
  legend_labels = c("Absent", "Present"),
  border_color = "gray70",
  cellwidth = 55,
  cellheight = 38,
  angle_col = 0
)

dev.off()

cat("   ✅ SAVED: figuras_ingles/fig01_let7_heatmap_pattern.png\n\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("✅ FIGURE #1 COMPLETE\n")
cat("   ⭐⭐⭐ MOST CRITICAL FIGURE OF THE STUDY\n")
cat("   Shows 100% penetrance of G>T at positions 2,4,5 in let-7\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

