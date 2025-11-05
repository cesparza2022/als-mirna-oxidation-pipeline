#!/usr/bin/env Rscript

# ============================================================================
# 🎯 SISTEMA ADAPTATIVO INTELIGENTE PARA HEATMAP POSICIONAL
# ============================================================================

library(ggplot2)
library(dplyr)
library(tidyr)
library(pheatmap)
library(tibble)
library(RColorBrewer)

setwd("/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/pipeline_definitivo/01_analisis_inicial")

cat("📊 Generando Heatmap Adaptativo\n")
cat("══════════════════════════════════════════════════════════════════════\n\n")

# 1. Cargar datos
cat("📊 Cargando datos...\n")
data <- read.csv("tables/mutaciones_gt_detalladas.csv")

# 2. Preparar matriz
cat("📊 Preparando matriz...\n")
heatmap_data <- data %>%
  mutate(
    miRNA = `miRNA.name`,
    Position = as.numeric(gsub(":.*", "", pos.mut))
  ) %>%
  group_by(miRNA, Position) %>%
  summarise(Count = n(), .groups = "drop") %>%
  pivot_wider(names_from = Position, values_from = Count, values_fill = 0) %>%
  column_to_rownames("miRNA") %>%
  as.matrix()

cat(sprintf("   Matriz: %d miRNAs x %d posiciones\n", nrow(heatmap_data), ncol(heatmap_data)))

# 3. Análisis estadístico
cat("\n📊 Analizando datos...\n")
stats <- list(
  max = max(heatmap_data, na.rm = TRUE),
  mean = mean(heatmap_data, na.rm = TRUE),
  median = median(heatmap_data, na.rm = TRUE),
  pct_zeros = sum(heatmap_data == 0) / length(heatmap_data) * 100,
  q75 = quantile(heatmap_data, 0.75, na.rm = TRUE),
  q90 = quantile(heatmap_data, 0.90, na.rm = TRUE),
  q95 = quantile(heatmap_data, 0.95, na.rm = TRUE)
)

cat(sprintf("   Máximo: %.0f\n", stats$max))
cat(sprintf("   Media: %.2f\n", stats$mean))
cat(sprintf("   Mediana: %.0f\n", stats$median))
cat(sprintf("   %% Ceros: %.1f%%\n", stats$pct_zeros))
cat(sprintf("   Q75: %.0f\n", stats$q75))
cat(sprintf("   Q90: %.0f\n", stats$q90))
cat(sprintf("   Q95: %.0f\n", stats$q95))

# 4. Decidir estrategia
cat("\n🎯 Decidiendo estrategia...\n")

if (stats$pct_zeros > 80) {
  method <- "percentile"
  breaks <- unique(c(0, 1, 2, 3, 5, 8, 12, 18, 25, 35, stats$max))
  colors <- colorRampPalette(c("white", "lightblue", "blue", "purple", "red"))(length(breaks)-1)
} else if (stats$max > 100) {
  method <- "logarithmic"
  breaks <- unique(c(0, 1, 2, 4, 8, 16, 32, 64, 128, 256, stats$max))
  colors <- colorRampPalette(c("white", "yellow", "orange", "red", "darkred"))(length(breaks)-1)
} else {
  method <- "linear"
  breaks <- seq(0, stats$max, length.out = 11)
  colors <- colorRampPalette(c("white", "lightblue", "blue", "purple", "red"))(length(breaks)-1)
}

cat(sprintf("   ✅ Método seleccionado: %s\n", toupper(method)))
cat(sprintf("   ✅ Breaks: %d niveles\n", length(breaks)))
cat(sprintf("   ✅ Rango: %.0f - %.0f\n", min(breaks), max(breaks)))

# 5. Generar heatmap con pheatmap
cat("\n🎨 Generando heatmap (pheatmap)...\n")

# Limitar a top 100 miRNAs si hay muchos
if (nrow(heatmap_data) > 100) {
  top_mirnas <- names(sort(rowSums(heatmap_data), decreasing = TRUE)[1:100])
  heatmap_plot <- heatmap_data[top_mirnas, ]
  note <- sprintf("Top 100 de %d miRNAs", nrow(heatmap_data))
} else {
  heatmap_plot <- heatmap_data
  note <- sprintf("Todos los %d miRNAs", nrow(heatmap_data))
}

png("figures/PANEL_B_HEATMAP_ADAPTIVE_PHEATMAP.png", width = 1400, height = 900, res = 150)

pheatmap(
  heatmap_plot,
  color = colors,
  breaks = breaks,
  cluster_rows = TRUE,
  cluster_cols = FALSE,
  show_rownames = TRUE,
  show_colnames = TRUE,
  main = sprintf("G>T Positional Distribution (%s scale)\n%s", method, note),
  fontsize = 10,
  fontsize_row = 7,
  fontsize_col = 10,
  border_color = "gray90",
  cellwidth = 22,
  cellheight = 10
)

dev.off()

cat("   ✅ Guardado: PANEL_B_HEATMAP_ADAPTIVE_PHEATMAP.png\n")

# 6. Generar versión ggplot2
cat("\n🎨 Generando versión ggplot2...\n")

# Preparar datos para ggplot
heatmap_long <- data %>%
  mutate(
    miRNA = `miRNA.name`,
    Position = as.numeric(gsub(":.*", "", pos.mut))
  ) %>%
  group_by(miRNA, Position) %>%
  summarise(Count = n(), .groups = "drop")

# Limitar a top 100 si hay muchos
if (length(unique(heatmap_long$miRNA)) > 100) {
  top_mirnas_list <- heatmap_long %>%
    group_by(miRNA) %>%
    summarise(Total = sum(Count)) %>%
    arrange(desc(Total)) %>%
    slice(1:100) %>%
    pull(miRNA)
  
  heatmap_long <- heatmap_long %>% filter(miRNA %in% top_mirnas_list)
}

p <- ggplot(heatmap_long, aes(x = factor(Position), y = miRNA, fill = Count)) +
  geom_tile(color = "white", size = 0.3) +
  scale_fill_gradientn(
    colors = colors,
    values = scales::rescale(breaks),
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
    axis.text.y = element_text(size = 6),
    axis.title = element_text(size = 13, face = "bold"),
    plot.title = element_text(size = 15, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5, color = "gray40"),
    legend.position = "right",
    panel.grid = element_blank()
  ) +
  labs(
    title = sprintf("G>T Positional Distribution (Adaptive %s Scale)", method),
    subtitle = sprintf("%s | Max: %.0f | Mean: %.2f", note, stats$max, stats$mean),
    x = "Position",
    y = "miRNA"
  )

ggsave("figures/PANEL_B_HEATMAP_ADAPTIVE_GGPLOT.png", p, width = 14, height = 9, dpi = 150)

cat("   ✅ Guardado: PANEL_B_HEATMAP_ADAPTIVE_GGPLOT.png\n")

# 7. Guardar metadatos
cat("\n💾 Guardando metadatos...\n")

metadata <- data.frame(
  metric = c("method", names(stats), "n_breaks"),
  value = c(method, unlist(stats), length(breaks))
)

write.csv(metadata, "data/heatmap_adaptive_metadata.csv", row.names = FALSE)

cat("   ✅ Guardado: heatmap_adaptive_metadata.csv\n")

# 8. Resumen final
cat("\n══════════════════════════════════════════════════════════════════════\n")
cat("✅ HEATMAP ADAPTATIVO COMPLETADO\n")
cat("══════════════════════════════════════════════════════════════════════\n\n")
cat(sprintf("📊 MÉTODO: %s\n", toupper(method)))
cat(sprintf("📊 BREAKS: %d niveles\n", length(breaks)))
cat(sprintf("📊 RANGO: %.0f - %.0f\n", min(breaks), max(breaks)))
cat(sprintf("📊 ARCHIVOS:\n"))
cat("   • PANEL_B_HEATMAP_ADAPTIVE_PHEATMAP.png\n")
cat("   • PANEL_B_HEATMAP_ADAPTIVE_GGPLOT.png\n")
cat("   • heatmap_adaptive_metadata.csv\n")
cat("\n")

