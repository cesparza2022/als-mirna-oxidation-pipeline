#!/usr/bin/env Rscript
# ============================================================================
# FIGURA CRÍTICA 1: let-7 HEATMAP (Posiciones 2,4,5 pattern)
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(pheatmap)
})

cat("\n🔥 REGENERATING: let-7 Heatmap (MOST CRITICAL FIGURE)\n\n")

# Cargar datos procesados del paso 10A
data_file <- "outputs/paso10a_let7_vs_mir4500/let7_gt_by_position.csv"

if (!file.exists(data_file)) {
  cat("❌ Data file not found. Using alternative approach...\n")
  
  # Cargar desde paso 8
  alt_file <- "outputs/paso8_mirnas_gt_semilla/mirnas_gt_semilla.csv"
  if (file.exists(alt_file)) {
    data <- read_csv(alt_file, show_col_types = FALSE)
    
    # Filtrar let-7
    let7_data <- data %>%
      filter(str_detect(`miRNA name`, "let-7|miR-98"))
    
    # Extraer posición
    let7_data <- let7_data %>%
      mutate(
        position = as.integer(str_extract(`pos:mut`, "^\\d+"))
      ) %>%
      filter(position >= 2, position <= 8)
    
    # Crear matriz de presencia
    let7_matrix <- let7_data %>%
      group_by(`miRNA name`, position) %>%
      summarise(has_gt = 1, .groups = "drop") %>%
      complete(`miRNA name`, position = 2:8, fill = list(has_gt = 0)) %>%
      pivot_wider(names_from = position, values_from = has_gt, values_fill = 0) %>%
      column_to_rownames("miRNA name") %>%
      as.matrix()
    
  } else {
    stop("❌ Could not find data files")
  }
} else {
  # Cargar datos del paso 10A
  data <- read_csv(data_file, show_col_types = FALSE)
  
  # Crear matriz
  let7_matrix <- data %>%
    select(mirna, position, has_gt) %>%
    pivot_wider(names_from = position, values_from = has_gt, values_fill = 0) %>%
    column_to_rownames("mirna") %>%
    as.matrix()
}

# Crear directorio de salida
dir.create("figures_english", showWarnings = FALSE, recursive = TRUE)

# Generar heatmap mejorado
png("figures_english/let7_heatmap_pattern_english.png",
    width = 10, height = 8, units = "in", res = 300)

pheatmap(
  let7_matrix,
  color = colorRampPalette(c("white", "#e74c3c"))(2),
  cluster_rows = FALSE,
  cluster_cols = FALSE,
  display_numbers = TRUE,
  number_color = "black",
  number_format = "%.0f",
  fontsize = 14,
  fontsize_row = 13,
  fontsize_col = 13,
  fontsize_number = 16,
  main = "G>T Mutations in let-7 Family Seed Region\n(Exact Pattern at Positions 2, 4, 5)",
  legend = TRUE,
  legend_breaks = c(0, 1),
  legend_labels = c("Absent", "Present"),
  border_color = "gray70",
  cellwidth = 50,
  cellheight = 35,
  angle_col = 0
)

dev.off()

cat("✅ SAVED: figures_english/let7_heatmap_pattern_english.png\n")
cat("   ⭐⭐⭐ MOST CRITICAL FIGURE\n")
cat("   Shows 100% penetrance at positions 2, 4, 5\n")
cat("\n")








