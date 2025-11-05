#!/usr/bin/env Rscript

# ============================================================================
# 🎯 SISTEMA ADAPTATIVO INTELIGENTE PARA HEATMAPS
# ============================================================================

library(ggplot2)
library(dplyr)
library(tidyr)
library(pheatmap)
library(RColorBrewer)
library(tibble)

# Función para crear escala adaptativa
create_adaptive_scale <- function(data, method = "auto") {
  
  # Estadísticas de los datos
  data_stats <- data %>%
    summarise(
      max_count = max(count, na.rm = TRUE),
      mean_count = mean(count, na.rm = TRUE),
      median_count = median(count, na.rm = TRUE),
      n_zeros = sum(count == 0, na.rm = TRUE),
      n_nonzero = sum(count > 0, na.rm = TRUE),
      pct_zeros = n_zeros / n() * 100,
      q75 = quantile(count, 0.75, na.rm = TRUE),
      q90 = quantile(count, 0.90, na.rm = TRUE),
      q95 = quantile(count, 0.95, na.rm = TRUE)
    )
  
  cat("📊 ESTADÍSTICAS DE LOS DATOS:\n")
  cat("   Máximo:", data_stats$max_count, "\n")
  cat("   Media:", round(data_stats$mean_count, 2), "\n")
  cat("   Mediana:", data_stats$median_count, "\n")
  cat("   % Ceros:", round(data_stats$pct_zeros, 1), "%\n")
  cat("   Q75:", data_stats$q75, "\n")
  cat("   Q90:", data_stats$q90, "\n")
  cat("   Q95:", data_stats$q95, "\n\n")
  
  # Decidir estrategia automáticamente
  if (method == "auto") {
    if (data_stats$pct_zeros > 80) {
      method <- "percentile"
    } else if (data_stats$max_count > 100) {
      method <- "log"
    } else {
      method <- "linear"
    }
  }
  
  cat("🎯 ESTRATEGIA SELECCIONADA:", method, "\n\n")
  
  # Crear breaks según la estrategia
  if (method == "percentile") {
    # Usar percentiles para datos con muchos ceros
    breaks <- c(0, 1, 2, 3, 5, 8, 12, 18, 25, 35, data_stats$max_count)
    breaks <- unique(breaks)
    colors <- colorRampPalette(c("white", "lightblue", "blue", "purple", "red"))(length(breaks)-1)
    
  } else if (method == "log") {
    # Escala logarítmica para datos con rango amplio
    breaks <- c(0, 1, 2, 4, 8, 16, 32, 64, 128, 256, data_stats$max_count)
    breaks <- unique(breaks)
    colors <- colorRampPalette(c("white", "yellow", "orange", "red", "darkred"))(length(breaks)-1)
    
  } else {
    # Escala lineal para datos normales
    breaks <- seq(0, data_stats$max_count, length.out = 11)
    colors <- colorRampPalette(c("white", "lightblue", "blue", "purple", "red"))(length(breaks)-1)
  }
  
  return(list(breaks = breaks, colors = colors, method = method, stats = data_stats))
}

# Cargar datos
cat("📊 Cargando datos...\n")
data <- read.csv("pipeline_1/data/analisis_posiciones.csv")

# Crear matriz para heatmap
heatmap_data <- data %>%
  select(miRNA, Position, G_T_Count) %>%
  pivot_wider(names_from = Position, values_from = G_T_Count, values_fill = 0) %>%
  column_to_rownames("miRNA") %>%
  as.matrix()

# Crear escala adaptativa
scale_info <- create_adaptive_scale(data.frame(count = as.vector(heatmap_data)))

# Generar heatmap adaptativo con pheatmap
cat("🎨 Generando heatmap adaptativo (pheatmap)...\n")

png("pipeline_1/figures/FIG_HEATMAP_ADAPTIVE_SCALE.png", width = 1400, height = 900, res = 150)

pheatmap(
  heatmap_data,
  color = scale_info$colors,
  breaks = scale_info$breaks,
  cluster_rows = TRUE,
  cluster_cols = FALSE,
  show_rownames = TRUE,
  show_colnames = TRUE,
  main = paste0("G>T Positional Distribution (", scale_info$method, " scale)"),
  fontsize = 10,
  fontsize_row = 7,
  fontsize_col = 10,
  border_color = "gray90",
  cellwidth = 22,
  cellheight = 10
)

dev.off()

# Generar versión con ggplot2 también
cat("🎨 Generando versión ggplot2...\n")

# Preparar datos para ggplot
heatmap_long <- data %>%
  select(miRNA, Position, G_T_Count) %>%
  mutate(
    miRNA = factor(miRNA),
    Position = factor(Position),
    Count = G_T_Count
  )

# Crear heatmap con ggplot2
p <- ggplot(heatmap_long, aes(x = Position, y = miRNA, fill = Count)) +
  geom_tile(color = "white", size = 0.5) +
  scale_fill_gradientn(
    colors = scale_info$colors,
    values = scales::rescale(scale_info$breaks),
    name = "G>T Count",
    guide = guide_colorbar(
      title.position = "top",
      title.hjust = 0.5,
      barwidth = 15,
      barheight = 1
    )
  ) +
  theme_minimal(base_size = 12) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
    axis.text.y = element_text(size = 7),
    axis.title = element_text(size = 13, face = "bold"),
    plot.title = element_text(size = 15, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5, color = "gray40"),
    legend.position = "right",
    panel.grid = element_blank()
  ) +
  labs(
    title = "G>T Positional Distribution (Adaptive Scale)",
    subtitle = paste0("Method: ", scale_info$method, " | Max: ", scale_info$stats$max_count, 
                     " | Mean: ", round(scale_info$stats$mean_count, 2)),
    x = "Position",
    y = "miRNA"
  )

ggsave("pipeline_1/figures/FIG_HEATMAP_ADAPTIVE_GGPLOT.png", p, width = 14, height = 9, dpi = 150)

cat("\n✅ HEATMAPS ADAPTATIVOS GENERADOS:\n")
cat("   • pipeline_1/figures/FIG_HEATMAP_ADAPTIVE_SCALE.png (pheatmap)\n")
cat("   • pipeline_1/figures/FIG_HEATMAP_ADAPTIVE_GGPLOT.png (ggplot2)\n")
cat("   • Método:", scale_info$method, "\n")
cat("   • Breaks:", length(scale_info$breaks), "\n")
cat("   • Rango:", min(scale_info$breaks), "-", max(scale_info$breaks), "\n")

