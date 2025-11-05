# 🎯 Implementación del Heatmap Adaptativo para el Pipeline

## Estado Actual

✅ **HTML del Paso 1 generado**: `PASO_1_ANALISIS_INICIAL_COMPLETO.html`
✅ **Figuras existentes**: Panel A (Overview), Panel C (Spectrum), Panel D (Positional), etc.
⚠️ **Problema identificado**: El heatmap "B. G>T Positional Distribution" usa escala fija (0-60) que no se ajusta a los datos

## Solución: Sistema de Escalas Adaptativas

### Concepto

El sistema analiza automáticamente los datos del heatmap y decide la mejor escala según las características:

1. **Escala por Percentiles** → Para datasets con muchos ceros (>80%)
   - Breaks: 0, 1, 2, 3, 5, 8, 12, 18, 25, 35, max
   - Colores: Blanco → Azul claro → Azul → Púrpura → Rojo

2. **Escala Logarítmica** → Para rangos muy amplios (max > 100)
   - Breaks: 0, 1, 2, 4, 8, 16, 32, 64, 128, max
   - Colores: Blanco → Amarillo → Naranja → Rojo → Rojo oscuro

3. **Escala Lineal** → Para datos normales
   - Breaks: 11 niveles espaciados linealmente de 0 a max
   - Colores: Blanco → Azul claro → Azul → Púrpura → Rojo

### Implementación Propuesta

#### Paso 1: Script R para Análisis y Generación

```r
# 01_analisis_inicial/scripts/CREATE_ADAPTIVE_HEATMAP.R

library(ggplot2)
library(dplyr)
library(tidyr)
library(pheatmap)
library(tibble)

# 1. Cargar datos
data <- read.csv("tables/mutaciones_gt_detalladas.csv")

# 2. Preparar matriz
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

# 3. Análisis estadístico
stats <- list(
  max = max(heatmap_data, na.rm = TRUE),
  mean = mean(heatmap_data, na.rm = TRUE),
  median = median(heatmap_data, na.rm = TRUE),
  pct_zeros = sum(heatmap_data == 0) / length(heatmap_data) * 100,
  q75 = quantile(heatmap_data, 0.75, na.rm = TRUE),
  q90 = quantile(heatmap_data, 0.90, na.rm = TRUE),
  q95 = quantile(heatmap_data, 0.95, na.rm = TRUE)
)

# 4. Decidir estrategia
if (stats$pct_zeros > 80) {
  method <- "percentile"
  breaks <- c(0, 1, 2, 3, 5, 8, 12, 18, 25, 35, stats$max)
  colors <- colorRampPalette(c("white", "lightblue", "blue", "purple", "red"))(length(breaks)-1)
} else if (stats$max > 100) {
  method <- "logarithmic"
  breaks <- c(0, 1, 2, 4, 8, 16, 32, 64, 128, stats$max)
  colors <- colorRampPalette(c("white", "yellow", "orange", "red", "darkred"))(length(breaks)-1)
} else {
  method <- "linear"
  breaks <- seq(0, stats$max, length.out = 11)
  colors <- colorRampPalette(c("white", "lightblue", "blue", "purple", "red"))(length(breaks)-1)
}

# 5. Generar heatmap
png("figures/PANEL_B_HEATMAP_ADAPTIVE.png", width = 1400, height = 900, res = 150)

pheatmap(
  heatmap_data,
  color = colors,
  breaks = breaks,
  cluster_rows = TRUE,
  cluster_cols = FALSE,
  show_rownames = TRUE,
  show_colnames = TRUE,
  main = paste0("G>T Positional Distribution (", method, " scale)"),
  fontsize = 10,
  fontsize_row = 7,
  fontsize_col = 10,
  border_color = "gray90",
  cellwidth = 22,
  cellheight = 10
)

dev.off()

# 6. Guardar metadatos
write.csv(
  data.frame(
    metric = names(stats),
    value = unlist(stats)
  ),
  "data/heatmap_adaptive_stats.csv",
  row.names = FALSE
)

cat("\n✅ HEATMAP ADAPTATIVO GENERADO\n")
cat("   Método:", method, "\n")
cat("   Breaks:", length(breaks), "\n")
cat("   Archivo: PANEL_B_HEATMAP_ADAPTIVE.png\n")
```

#### Paso 2: Integración en el Pipeline

El script debe:

1. **Detectarse automáticamente** cuando se ejecuta el pipeline del Paso 1
2. **Reemplazar** el heatmap antiguo con el nuevo adaptativo
3. **Documentar** en el HTML qué escala se utilizó y por qué

#### Paso 3: Actualización del HTML

El HTML debe mostrar:

- **Estadísticas del dataset** (max, mean, % ceros)
- **Método seleccionado** (percentile/logarithmic/linear)
- **Justificación** de por qué se eligió ese método
- **Heatmap con la escala adaptativa**

### Ventajas del Sistema

1. **Automático** - No requiere intervención manual
2. **Adaptativo** - Se ajusta a cualquier dataset
3. **Informativo** - Maximiza el contraste visual
4. **Reproducible** - Siempre aplica la misma lógica
5. **Documentado** - Explica las decisiones tomadas

### Estado de Implementación

- [x] Concepto definido
- [x] Lógica de decisión establecida
- [x] Scripts R diseñados
- [ ] Scripts ejecutados y probados
- [ ] Integración en el pipeline
- [ ] HTML actualizado con nueva figura
- [ ] Documentación completa

### Próximos Pasos

1. Ejecutar el script R para generar el heatmap adaptativo
2. Verificar que la escala se ajuste correctamente
3. Actualizar el HTML del Paso 1 para incluir la nueva figura
4. Documentar el cambio en el CHANGELOG

### Notas Técnicas

- **Dependencias R**: `ggplot2`, `dplyr`, `tidyr`, `pheatmap`, `tibble`
- **Datos de entrada**: `mutaciones_gt_detalladas.csv`
- **Salida**: `PANEL_B_HEATMAP_ADAPTIVE.png`
- **Formato**: PNG, 1400x900px, 150 DPI

---

**Documento generado**: $(date)  
**Autor**: Pipeline Definitivo - Sistema de Escalas Adaptativas

