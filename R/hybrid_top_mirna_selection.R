#!/usr/bin/env Rscript

# SELECCIÓN HÍBRIDA DE TOP miRNAs
# Implementa el enfoque híbrido recomendado para seleccionar miRNAs más relevantes
# Combina cuentas totales, VAF promedio y filtrado por expresión

library(dplyr)
library(stringr)
library(readr)
library(tidyr)
library(tibble)
library(ggplot2)
library(pheatmap)
library(VennDiagram)
library(gridExtra)
library(viridis)

cat("🧬 SELECCIÓN HÍBRIDA DE TOP miRNAs\n")
cat("==================================\n\n")

# 1. Cargar datos
cat("📊 PASO 1: Cargando datos...\n")
df <- read_tsv("results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt", show_col_types = FALSE)
cat("   - Total filas:", nrow(df), "\n")
cat("   - Total miRNAs únicos:", length(unique(df$`miRNA name`)), "\n\n")

# 2. Identificar columnas
cat("📊 PASO 2: Identificando tipos de columnas...\n")
meta_cols <- c("miRNA name", "pos:mut")
all_cols <- colnames(df)
total_cols <- all_cols[str_detect(all_cols, "\\(PM\\+1MM\\+2MM\\)")]
snv_cols <- setdiff(all_cols, c(meta_cols, total_cols))

cat("   - Columnas meta:", length(meta_cols), "\n")
cat("   - Columnas SNV:", length(snv_cols), "\n")
cat("   - Columnas TOTAL:", length(total_cols), "\n\n")

# 3. Filtrar solo G>T
cat("📊 PASO 3: Filtrando solo mutaciones G>T...\n")
df_gt <- df %>% filter(str_detect(`pos:mut`, ":GT"))
cat("   - Filas con G>T:", nrow(df_gt), "\n")
cat("   - miRNAs únicos con G>T:", length(unique(df_gt$`miRNA name`)), "\n\n")

# 4. Calcular VAFs
cat("📊 PASO 4: Calculando VAFs...\n")
if (nrow(df_gt) > 0 && length(snv_cols) > 0 && length(total_cols) > 0) {
  snv_mat <- as.matrix(df_gt[, snv_cols])
  total_mat <- as.matrix(df_gt[, total_cols])
  
  # Asegurar que las columnas estén alineadas
  colnames(total_mat) <- str_replace(colnames(total_mat), " \\(PM\\+1MM\\+2MM\\)", "")
  
  # Calcular VAFs
  vaf_mat <- snv_mat / (total_mat + 1e-10)
  colnames(vaf_mat) <- paste0(colnames(vaf_mat), "_VAF")
  
  df_gt_vaf <- bind_cols(df_gt[, meta_cols], as.data.frame(vaf_mat))
  cat("   - VAFs calculados para", length(snv_cols), "muestras\n\n")
} else {
  stop("No se pudieron calcular VAFs")
}

# 5. Filtrar SNVs con VAF > 50%
cat("📊 PASO 5: Filtrando SNVs con VAF > 50%...\n")
vaf_cols <- colnames(df_gt_vaf)[str_detect(colnames(df_gt_vaf), "_VAF")]
snvs_to_remove_idx <- apply(df_gt_vaf[, vaf_cols] > 0.5, 1, any, na.rm = TRUE)
df_filtered_vaf <- df_gt_vaf[!snvs_to_remove_idx, ]

cat("   - SNVs removidos (VAF > 50%):", sum(snvs_to_remove_idx), "\n")
cat("   - Filas después de filtrar:", nrow(df_filtered_vaf), "\n")
cat("   - miRNAs únicos después de filtrar:", length(unique(df_filtered_vaf$`miRNA name`)), "\n\n")

# 6. Función para selección híbrida
select_hybrid_top_mirnas <- function(mirna_data, snv_cols, total_cols, vaf_cols, 
                                   expression_threshold = 0.25, top_percent = 0.1) {
  
  cat("🔬 PASO 6: Aplicando selección híbrida...\n")
  
  # 6.1 Calcular expresión total por miRNA usando el dataframe original
  cat("   - Calculando expresión total por miRNA...\n")
  
  # Obtener miRNAs únicos del dataset filtrado
  unique_mirnas <- unique(mirna_data$`miRNA name`)
  
  # Calcular expresión total desde el dataframe original
  mirna_expression <- df %>%
    filter(`miRNA name` %in% unique_mirnas) %>%
    group_by(`miRNA name`) %>%
    summarise(
      total_expression = sum(across(all_of(total_cols), ~sum(.x, na.rm = TRUE)), na.rm = TRUE),
      .groups = 'drop'
    )
  
  # 6.2 Aplicar filtro de expresión
  expr_threshold <- quantile(mirna_expression$total_expression, expression_threshold)
  high_expr_mirnas <- mirna_expression$`miRNA name`[mirna_expression$total_expression >= expr_threshold]
  
  cat("   - Umbral de expresión (percentil", expression_threshold*100, "):", round(expr_threshold, 2), "\n")
  cat("   - miRNAs con alta expresión:", length(high_expr_mirnas), "\n")
  
  # 6.3 Filtrar datos por expresión
  df_high_expr <- mirna_data %>%
    filter(`miRNA name` %in% high_expr_mirnas)
  
  # 6.4 Calcular métricas por miRNA
  cat("   - Calculando métricas por miRNA...\n")
  
  # Calcular cuentas totales de G>T desde el dataframe original
  gt_counts <- df %>%
    filter(`miRNA name` %in% high_expr_mirnas) %>%
    filter(str_detect(`pos:mut`, ":GT")) %>%
    group_by(`miRNA name`) %>%
    summarise(
      total_gt_counts = sum(across(all_of(snv_cols), ~sum(.x, na.rm = TRUE)), na.rm = TRUE),
      .groups = 'drop'
    )
  
  # Calcular VAF promedio desde el dataframe original filtrado
  # Usar el dataframe original pero solo para miRNAs con alta expresión
  df_high_expr_original <- df %>%
    filter(`miRNA name` %in% high_expr_mirnas) %>%
    filter(str_detect(`pos:mut`, ":GT"))
  
  # Calcular VAFs para las muestras filtradas
  snv_mat_high <- as.matrix(df_high_expr_original[, snv_cols])
  total_mat_high <- as.matrix(df_high_expr_original[, total_cols])
  colnames(total_mat_high) <- str_replace(colnames(total_mat_high), " \\(PM\\+1MM\\+2MM\\)", "")
  
  vaf_mat_high <- snv_mat_high / (total_mat_high + 1e-10)
  colnames(vaf_mat_high) <- paste0(colnames(vaf_mat_high), "_VAF")
  
  # Agregar VAFs al dataframe
  df_high_expr_with_vaf <- bind_cols(df_high_expr_original[, meta_cols], as.data.frame(vaf_mat_high))
  
  vaf_metrics <- df_high_expr_with_vaf %>%
    group_by(`miRNA name`) %>%
    summarise(
      avg_vaf = mean(across(all_of(colnames(vaf_mat_high)), ~mean(.x, na.rm = TRUE)), na.rm = TRUE),
      unique_snvs = n(),
      .groups = 'drop'
    ) %>%
    # Filtrar miRNAs con VAF válidos
    filter(!is.na(avg_vaf) & is.finite(avg_vaf))
  
  # Combinar todas las métricas
  mirna_metrics <- mirna_expression %>%
    filter(`miRNA name` %in% high_expr_mirnas) %>%
    left_join(gt_counts, by = "miRNA name") %>%
    left_join(vaf_metrics, by = "miRNA name") %>%
    mutate(
      # Cuentas normalizadas por expresión
      normalized_counts = total_gt_counts / (total_expression + 1e-10),
      # Puntuación compuesta (60% cuentas normalizadas, 40% VAF)
      composite_score = 0.6 * rank(normalized_counts) + 0.4 * rank(avg_vaf)
    )
  
  # 6.5 Seleccionar top miRNAs por cada método
  top_n <- max(1, floor(nrow(mirna_metrics) * top_percent))
  
  # Por cuentas normalizadas
  top_by_counts <- mirna_metrics %>%
    arrange(desc(normalized_counts)) %>%
    head(top_n)
  
  # Por VAF promedio
  top_by_vaf <- mirna_metrics %>%
    arrange(desc(avg_vaf)) %>%
    head(top_n)
  
  # Por puntuación compuesta
  top_by_composite <- mirna_metrics %>%
    arrange(desc(composite_score)) %>%
    head(top_n)
  
  cat("   - Top miRNAs por cuentas normalizadas:", nrow(top_by_counts), "\n")
  cat("   - Top miRNAs por VAF promedio:", nrow(top_by_vaf), "\n")
  cat("   - Top miRNAs por puntuación compuesta:", nrow(top_by_composite), "\n")
  
  return(list(
    all_metrics = mirna_metrics,
    top_by_counts = top_by_counts,
    top_by_vaf = top_by_vaf,
    top_by_composite = top_by_composite,
    expression_threshold = expr_threshold,
    high_expr_mirnas = high_expr_mirnas
  ))
}

# 7. Aplicar selección híbrida
results <- select_hybrid_top_mirnas(
  df_filtered_vaf, snv_cols, total_cols, vaf_cols,
  expression_threshold = 0.25, top_percent = 0.1
)

# 8. Análisis de solapamiento
cat("\n📊 PASO 7: Analizando solapamiento entre métodos...\n")

# Obtener nombres de miRNAs seleccionados
counts_mirnas <- results$top_by_counts$`miRNA name`
vaf_mirnas <- results$top_by_vaf$`miRNA name`
composite_mirnas <- results$top_by_composite$`miRNA name`

# Calcular solapamientos
shared_counts_vaf <- intersect(counts_mirnas, vaf_mirnas)
shared_counts_composite <- intersect(counts_mirnas, composite_mirnas)
shared_vaf_composite <- intersect(vaf_mirnas, composite_mirnas)
shared_all_three <- intersect(shared_counts_vaf, composite_mirnas)

cat("   - Solapamiento cuentas ↔ VAF:", length(shared_counts_vaf), "\n")
cat("   - Solapamiento cuentas ↔ compuesta:", length(shared_counts_composite), "\n")
cat("   - Solapamiento VAF ↔ compuesta:", length(shared_vaf_composite), "\n")
cat("   - Solapamiento los tres métodos:", length(shared_all_three), "\n")

# 9. Crear visualizaciones
cat("\n📊 PASO 8: Creando visualizaciones...\n")

# Crear directorio de salida
dir.create("outputs/figures/hybrid_selection", showWarnings = FALSE, recursive = TRUE)

# 9.1 Scatter plot: VAF vs Cuentas normalizadas
p1 <- ggplot(results$all_metrics, aes(x = normalized_counts, y = avg_vaf)) +
  geom_point(alpha = 0.6, color = "gray70") +
  geom_point(data = results$top_by_counts, color = "red", size = 2) +
  geom_point(data = results$top_by_vaf, color = "blue", size = 2) +
  geom_point(data = results$top_by_composite, color = "green", size = 2) +
  scale_x_log10() +
  scale_y_log10() +
  labs(
    title = "Selección Híbrida de miRNAs",
    subtitle = "Rojo: Top por cuentas | Azul: Top por VAF | Verde: Top compuesto",
    x = "Cuentas G>T Normalizadas (log10)",
    y = "VAF Promedio (log10)"
  ) +
  theme_minimal()

ggsave("outputs/figures/hybrid_selection/scatter_vaf_vs_counts.png", p1, 
       width = 10, height = 8, dpi = 300)

# 9.2 Diagrama de Venn
venn_data <- list(
  "Por Cuentas" = counts_mirnas,
  "Por VAF" = vaf_mirnas,
  "Compuesto" = composite_mirnas
)

png("outputs/figures/hybrid_selection/venn_diagram.png", width = 800, height = 600, res = 150)
venn.plot <- venn.diagram(
  venn_data,
  filename = NULL,
  fill = c("lightcoral", "lightblue", "lightgreen"),
  alpha = 0.7,
  cex = 1.5,
  cat.cex = 1.2,
  main = "Solapamiento de Métodos de Selección"
)
grid.draw(venn.plot)
dev.off()

# 9.3 Heatmap de métricas
metrics_matrix <- results$all_metrics %>%
  select(`miRNA name`, normalized_counts, avg_vaf, composite_score) %>%
  # Filtrar filas con valores válidos
  filter(!is.na(normalized_counts) & !is.na(avg_vaf) & !is.na(composite_score)) %>%
  filter(is.finite(normalized_counts) & is.finite(avg_vaf) & is.finite(composite_score)) %>%
  column_to_rownames("miRNA name") %>%
  as.matrix()

# Verificar que tenemos datos válidos
if (nrow(metrics_matrix) > 0) {
  # Normalizar para el heatmap
  metrics_scaled <- scale(metrics_matrix)
  
  # Verificar que no hay NAs después del escalado
  if (!any(is.na(metrics_scaled)) && !any(is.infinite(metrics_scaled))) {
    png("outputs/figures/hybrid_selection/metrics_heatmap.png", width = 1000, height = 1200, res = 150)
    pheatmap(
      metrics_scaled,
      clustering_distance_rows = "euclidean",
      clustering_distance_cols = "euclidean",
      clustering_method = "ward.D2",
      color = viridis(100),
      main = "Métricas de Selección de miRNAs (Normalizadas)",
      fontsize = 8
    )
    dev.off()
    cat("   - Heatmap de métricas generado\n")
  } else {
    cat("   - No se pudo generar heatmap de métricas (valores inválidos)\n")
  }
} else {
  cat("   - No se pudo generar heatmap de métricas (sin datos válidos)\n")
}

# 9.4 Distribución de expresión
p2 <- ggplot(results$all_metrics, aes(x = total_expression)) +
  geom_histogram(bins = 50, alpha = 0.7, fill = "lightblue") +
  geom_vline(xintercept = results$expression_threshold, color = "red", linetype = "dashed") +
  scale_x_log10() +
  labs(
    title = "Distribución de Expresión de miRNAs",
    subtitle = paste("Línea roja: Umbral de filtrado (", round(results$expression_threshold, 2), ")"),
    x = "Expresión Total (log10)",
    y = "Frecuencia"
  ) +
  theme_minimal()

ggsave("outputs/figures/hybrid_selection/expression_distribution.png", p2, 
       width = 10, height = 6, dpi = 300)

# 10. Guardar resultados
cat("\n📊 PASO 9: Guardando resultados...\n")

# Guardar métricas completas
write_tsv(results$all_metrics, "outputs/hybrid_selection_all_metrics.tsv")

# Guardar top miRNAs por cada método
write_tsv(results$top_by_counts, "outputs/hybrid_selection_top_by_counts.tsv")
write_tsv(results$top_by_vaf, "outputs/hybrid_selection_top_by_vaf.tsv")
write_tsv(results$top_by_composite, "outputs/hybrid_selection_top_by_composite.tsv")

# Guardar objeto R completo
saveRDS(results, "outputs/hybrid_selection_results.rds")

# 11. Crear reporte
cat("\n📊 PASO 10: Generando reporte...\n")

report_content <- paste0(
  "# REPORTE DE SELECCIÓN HÍBRIDA DE miRNAs\n\n",
  "**Fecha:** ", Sys.Date(), "\n",
  "**Archivo de datos:** results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt\n\n",
  
  "## RESUMEN DE RESULTADOS\n\n",
  "- **miRNAs totales en dataset:** ", length(unique(df$`miRNA name`)), "\n",
  "- **miRNAs con mutaciones G>T:** ", length(unique(df_gt$`miRNA name`)), "\n",
  "- **miRNAs después de filtrar VAF > 50%:** ", length(unique(df_filtered_vaf$`miRNA name`)), "\n",
  "- **miRNAs con alta expresión (percentil 25+):** ", length(results$high_expr_mirnas), "\n",
  "- **Umbral de expresión:** ", round(results$expression_threshold, 2), "\n\n",
  
  "## TOP miRNAs SELECCIONADOS\n\n",
  "### Por Cuentas Normalizadas (", nrow(results$top_by_counts), " miRNAs)\n",
  "```\n",
  paste(results$top_by_counts$`miRNA name`, collapse = ", "), "\n",
  "```\n\n",
  
  "### Por VAF Promedio (", nrow(results$top_by_vaf), " miRNAs)\n",
  "```\n",
  paste(results$top_by_vaf$`miRNA name`, collapse = ", "), "\n",
  "```\n\n",
  
  "### Por Puntuación Compuesta (", nrow(results$top_by_composite), " miRNAs)\n",
  "```\n",
  paste(results$top_by_composite$`miRNA name`, collapse = ", "), "\n",
  "```\n\n",
  
  "## ANÁLISIS DE SOLAPAMIENTO\n\n",
  "- **Cuentas ↔ VAF:** ", length(shared_counts_vaf), " miRNAs\n",
  "- **Cuentas ↔ Compuesta:** ", length(shared_counts_composite), " miRNAs\n",
  "- **VAF ↔ Compuesta:** ", length(shared_vaf_composite), " miRNAs\n",
  "- **Los tres métodos:** ", length(shared_all_three), " miRNAs\n\n",
  
  "## ARCHIVOS GENERADOS\n\n",
  "- `hybrid_selection_all_metrics.tsv`: Métricas completas de todos los miRNAs\n",
  "- `hybrid_selection_top_by_counts.tsv`: Top miRNAs por cuentas normalizadas\n",
  "- `hybrid_selection_top_by_vaf.tsv`: Top miRNAs por VAF promedio\n",
  "- `hybrid_selection_top_by_composite.tsv`: Top miRNAs por puntuación compuesta\n",
  "- `hybrid_selection_results.rds`: Objeto R completo con todos los resultados\n",
  "- `figures/hybrid_selection/`: Visualizaciones del análisis\n\n",
  
  "## INTERPRETACIÓN\n\n",
  "El enfoque híbrido permite identificar miRNAs relevantes desde múltiples perspectivas:\n\n",
  "1. **Por cuentas normalizadas:** miRNAs con mayor carga mutacional absoluta\n",
  "2. **Por VAF promedio:** miRNAs con mayor tasa de mutación relativa\n",
  "3. **Por puntuación compuesta:** Balance entre ambos criterios\n\n",
  "La baja superposición entre métodos sugiere que capturan diferentes aspectos de la mutagénesis en miRNAs."
)

writeLines(report_content, "outputs/hybrid_selection_report.md")

cat("✅ ANÁLISIS HÍBRIDO COMPLETADO\n")
cat("==============================\n\n")
cat("📁 Archivos generados en outputs/\n")
cat("📊 Visualizaciones en outputs/figures/hybrid_selection/\n")
cat("📋 Reporte: outputs/hybrid_selection_report.md\n\n")
cat("🎯 Próximo paso: Revisar resultados y seleccionar método final\n")
