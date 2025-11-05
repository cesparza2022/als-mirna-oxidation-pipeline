# ============================================================================
# HEATMAP DE DENSIDAD G>T POR POSICIÓN
# Inspirado en análisis de densidad posicional
# Cada columna = 1 posición, cada fila = 1 SNV (ordenado por VAF)
# ============================================================================

library(dplyr)
library(tidyr)
library(stringr)
library(ComplexHeatmap)
library(circlize)
library(grid)

COLOR_ALS <- "#D62728"
COLOR_CONTROL <- "#666666"

cat("🎯 GENERANDO HEATMAP DE DENSIDAD G>T POR POSICIÓN\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

# Cargar datos
data <- read.csv("final_processed_data_CLEAN.csv")
metadata <- read.csv("metadata.csv")
sample_cols <- metadata$Sample_ID

cat("📊 Cargando datos...\n")

# Extraer G>T data
gt_data <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^[0-9]+"))) %>%
  filter(!is.na(position), position <= 22) %>%
  select(all_of(c("miRNA_name", "pos.mut", "position", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  left_join(metadata, by = "Sample_ID") %>%
  filter(!is.na(VAF), VAF > 0)

cat("✅ Datos G>T cargados:", nrow(gt_data), "observaciones\n\n")

# ============================================================================
# FUNCIÓN PARA CREAR HEATMAP POR GRUPO
# ============================================================================

create_density_heatmap <- function(group_name, color_scheme) {
  cat("📊 Creando heatmap para", group_name, "...\n")
  
  # Filtrar por grupo
  group_data <- gt_data %>% filter(Group == group_name)
  
  # Calcular VAF promedio por SNV único (pos.mut)
  df_ranked <- group_data %>%
    group_by(miRNA_name, pos.mut, position) %>%
    summarise(avr = mean(VAF, na.rm = TRUE), .groups = "drop") %>%
    arrange(position, desc(avr))
  
  cat("   SNVs únicos:", nrow(df_ranked), "\n")
  cat("   Posiciones:", length(unique(df_ranked$position)), "\n")
  
  # Paso 1: Encontrar máximo número de SNVs por posición
  df_summary <- df_ranked %>%
    group_by(position) %>%
    summarise(total_snvs = n(), .groups = "drop") %>%
    arrange(position)
  
  max_snvs <- max(df_summary$total_snvs)
  cat("   Max SNVs en una posición:", max_snvs, "\n")
  
  # Paso 2: Crear matrices con el mismo número de filas
  matrix_list <- list()
  positions <- sort(unique(df_ranked$position))
  
  for (p in positions) {
    snvs_for_pos <- df_ranked %>%
      filter(position == p) %>%
      arrange(desc(avr)) %>%
      pull(avr)
    
    n <- length(snvs_for_pos)
    # Rellenar con NA
    if (n < max_snvs) {
      snvs_for_pos <- c(snvs_for_pos, rep(NA, max_snvs - n))
    }
    
    mat_col <- matrix(snvs_for_pos, ncol = 1)
    colnames(mat_col) <- as.character(p)
    matrix_list[[as.character(p)]] <- mat_col
  }
  
  # Paso 3: Combinar matrices
  mat <- do.call(cbind, matrix_list)
  
  # Convertir NAs a 0 para visualización
  mat[is.na(mat)] <- 0
  
  cat("   Matriz creada:", nrow(mat), "filas x", ncol(mat), "columnas\n")
  
  # Escala de colores (adaptada a nuestro rango de VAF)
  max_vaf <- max(mat, na.rm = TRUE)
  col_fun <- colorRamp2(
    c(0, max_vaf * 0.25, max_vaf * 0.5, max_vaf * 0.75, max_vaf),
    c("#FFFFFF", paste0(color_scheme, "33"), paste0(color_scheme, "66"), 
      paste0(color_scheme, "99"), color_scheme)
  )
  
  # Crear heatmap
  ht <- Heatmap(
    mat,
    name = "VAF",
    cluster_rows = FALSE,
    cluster_columns = FALSE,
    col = col_fun,
    show_row_names = FALSE,
    show_column_names = TRUE,
    column_title = paste0("Positional G>T Density: ", group_name, " (n=", nrow(df_ranked), " unique SNVs)"),
    row_title = paste0("SNVs (ranked by VAF, max=", max_snvs, " per position)"),
    column_names_rot = 0,
    column_names_centered = TRUE,
    column_title_gp = gpar(fontsize = 16, fontface = "bold"),
    row_title_gp = gpar(fontsize = 14),
    heatmap_legend_param = list(
      title = "Mean VAF",
      direction = "horizontal",
      title_position = "topcenter",
      legend_width = unit(6, "cm")
    ),
    bottom_annotation = HeatmapAnnotation(
      "SNV Count" = anno_barplot(
        df_summary$total_snvs,
        bar_width = 0.8,
        gp = gpar(fill = color_scheme),
        annotation_name_rot = 0,
        height = unit(2.5, "cm")
      ),
      annotation_name_side = "left",
      annotation_name_gp = gpar(fontsize = 12)
    )
  )
  
  cat("   ✅ Heatmap creado\n\n")
  return(ht)
}

# ============================================================================
# GENERAR HEATMAPS PARA ALS Y CONTROL
# ============================================================================

# ALS
cat("🔴 GENERANDO HEATMAP ALS...\n")
png("figures_paso2_CLEAN/FIG_2.13_DENSITY_HEATMAP_ALS.png", 
    width = 16, height = 12, units = "in", res = 300)
ht_als <- create_density_heatmap("ALS", COLOR_ALS)
draw(ht_als, heatmap_legend_side = "bottom")
dev.off()
cat("✅ Figura 2.13 (ALS) guardada\n\n")

# Control
cat("🔵 GENERANDO HEATMAP CONTROL...\n")
png("figures_paso2_CLEAN/FIG_2.14_DENSITY_HEATMAP_CONTROL.png", 
    width = 16, height = 12, units = "in", res = 300)
ht_ctrl <- create_density_heatmap("Control", COLOR_CONTROL)
draw(ht_ctrl, heatmap_legend_side = "bottom")
dev.off()
cat("✅ Figura 2.14 (Control) guardada\n\n")

# ============================================================================
# COMBINADO (Lado a Lado)
# ============================================================================

cat("📊 GENERANDO HEATMAP COMBINADO...\n")
png("figures_paso2_CLEAN/FIG_2.15_DENSITY_COMBINED.png", 
    width = 20, height = 12, units = "in", res = 300)

# Re-crear para combinados
grid.newpage()
pushViewport(viewport(layout = grid.layout(1, 2)))

# ALS
pushViewport(viewport(layout.pos.row = 1, layout.pos.col = 1))
ht_als <- create_density_heatmap("ALS", COLOR_ALS)
draw(ht_als, newpage = FALSE, heatmap_legend_side = "bottom")
upViewport()

# Control
pushViewport(viewport(layout.pos.row = 1, layout.pos.col = 2))
ht_ctrl <- create_density_heatmap("Control", COLOR_CONTROL)
draw(ht_ctrl, newpage = FALSE, heatmap_legend_side = "bottom")
upViewport()

dev.off()
cat("✅ Figura 2.15 (Combinado) guardada\n\n")

cat(paste(rep("=", 70), collapse = ""), "\n")
cat("✅ HEATMAPS DE DENSIDAD COMPLETADOS\n")
cat(paste(rep("=", 70), collapse = ""), "\n")
cat("📁 Figuras generadas:\n")
cat("   • FIG_2.13_DENSITY_HEATMAP_ALS.png\n")
cat("   • FIG_2.14_DENSITY_HEATMAP_CONTROL.png\n")
cat("   • FIG_2.15_DENSITY_COMBINED.png\n\n")

cat("🎯 Esta figura muestra:\n")
cat("   • Densidad de SNVs G>T por posición\n")
cat("   • SNVs ordenados por VAF (de mayor a menor)\n")
cat("   • Barplot inferior: total de SNVs por posición\n")
cat("   • Ideal para ver hotspots posicionales\n\n")

cat("📊 Siguiente: Añadir al HTML y proceder con Paso 3\n")

