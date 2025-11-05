#!/usr/bin/env Rscript

# ANÁLISIS HÍBRIDO SIMPLIFICADO DE TOP miRNAs
# Versión simplificada que funciona correctamente

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

cat("🧬 ANÁLISIS HÍBRIDO SIMPLIFICADO DE miRNAs\n")
cat("==========================================\n\n")

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

# 4. Calcular VAFs y filtrar
cat("📊 PASO 4: Calculando VAFs y filtrando...\n")
snv_mat <- as.matrix(df_gt[, snv_cols])
total_mat <- as.matrix(df_gt[, total_cols])
colnames(total_mat) <- str_replace(colnames(total_mat), " \\(PM\\+1MM\\+2MM\\)", "")

# Calcular VAFs
vaf_mat <- snv_mat / (total_mat + 1e-10)

# Filtrar SNVs con VAF > 50%
high_vaf_idx <- apply(vaf_mat > 0.5, 1, any, na.rm = TRUE)
df_gt_filtered <- df_gt[!high_vaf_idx, ]
vaf_mat_filtered <- vaf_mat[!high_vaf_idx, ]

cat("   - SNVs removidos (VAF > 50%):", sum(high_vaf_idx), "\n")
cat("   - Filas después de filtrar:", nrow(df_gt_filtered), "\n")
cat("   - miRNAs únicos después de filtrar:", length(unique(df_gt_filtered$`miRNA name`)), "\n\n")

# 5. Calcular métricas por miRNA
cat("📊 PASO 5: Calculando métricas por miRNA...\n")

# 5.1 Expresión total por miRNA
mirna_expression <- df %>%
  group_by(`miRNA name`) %>%
  summarise(
    total_expression = sum(across(all_of(total_cols), ~sum(.x, na.rm = TRUE)), na.rm = TRUE),
    .groups = 'drop'
  )

# 5.2 Aplicar filtro de expresión (percentil 25)
expr_threshold <- quantile(mirna_expression$total_expression, 0.25)
high_expr_mirnas <- mirna_expression$`miRNA name`[mirna_expression$total_expression >= expr_threshold]

cat("   - Umbral de expresión (percentil 25):", round(expr_threshold, 2), "\n")
cat("   - miRNAs con alta expresión:", length(high_expr_mirnas), "\n")

# 5.3 Filtrar datos por expresión
df_filtered_expr <- df_gt_filtered %>%
  filter(`miRNA name` %in% high_expr_mirnas)

vaf_mat_expr <- vaf_mat_filtered[df_gt_filtered$`miRNA name` %in% high_expr_mirnas, ]

# 5.4 Calcular métricas finales
mirna_metrics <- df_filtered_expr %>%
  group_by(`miRNA name`) %>%
  summarise(
    # Cuentas totales de G>T
    total_gt_counts = sum(across(all_of(snv_cols), ~sum(.x, na.rm = TRUE)), na.rm = TRUE),
    # Número de SNVs únicos
    unique_snvs = n(),
    .groups = 'drop'
  ) %>%
  # Agregar expresión total
  left_join(mirna_expression, by = "miRNA name") %>%
  # Calcular VAF promedio
  mutate(
    # Obtener VAFs para cada miRNA
    avg_vaf = sapply(`miRNA name`, function(mirna) {
      mirna_idx <- which(df_filtered_expr$`miRNA name` == mirna)
      if (length(mirna_idx) > 0) {
        mean(vaf_mat_expr[mirna_idx, ], na.rm = TRUE)
      } else {
        NA
      }
    }),
    # Cuentas normalizadas por expresión
    normalized_counts = total_gt_counts / (total_expression + 1e-10),
    # Puntuación compuesta (60% cuentas normalizadas, 40% VAF)
    composite_score = 0.6 * rank(normalized_counts) + 0.4 * rank(avg_vaf)
  ) %>%
  # Filtrar miRNAs con VAF válidos
  filter(!is.na(avg_vaf) & is.finite(avg_vaf))

cat("   - miRNAs con métricas válidas:", nrow(mirna_metrics), "\n\n")

# 6. Seleccionar top miRNAs
cat("📊 PASO 6: Seleccionando top miRNAs...\n")
top_percent <- 0.1
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
cat("   - Top miRNAs por puntuación compuesta:", nrow(top_by_composite), "\n\n")

# 7. Análisis de solapamiento
cat("📊 PASO 7: Analizando solapamiento...\n")
counts_mirnas <- top_by_counts$`miRNA name`
vaf_mirnas <- top_by_vaf$`miRNA name`
composite_mirnas <- top_by_composite$`miRNA name`

shared_counts_vaf <- intersect(counts_mirnas, vaf_mirnas)
shared_counts_composite <- intersect(counts_mirnas, composite_mirnas)
shared_vaf_composite <- intersect(vaf_mirnas, composite_mirnas)
shared_all_three <- intersect(shared_counts_vaf, composite_mirnas)

cat("   - Solapamiento cuentas ↔ VAF:", length(shared_counts_vaf), "\n")
cat("   - Solapamiento cuentas ↔ compuesta:", length(shared_counts_composite), "\n")
cat("   - Solapamiento VAF ↔ compuesta:", length(shared_vaf_composite), "\n")
cat("   - Solapamiento los tres métodos:", length(shared_all_three), "\n\n")

# 8. Crear visualizaciones
cat("📊 PASO 8: Creando visualizaciones...\n")
dir.create("outputs/figures/simple_hybrid", showWarnings = FALSE, recursive = TRUE)

# 8.1 Scatter plot: VAF vs Cuentas normalizadas
p1 <- ggplot(mirna_metrics, aes(x = normalized_counts, y = avg_vaf)) +
  geom_point(alpha = 0.6, color = "gray70") +
  geom_point(data = top_by_counts, color = "red", size = 2) +
  geom_point(data = top_by_vaf, color = "blue", size = 2) +
  geom_point(data = top_by_composite, color = "green", size = 2) +
  scale_x_log10() +
  scale_y_log10() +
  labs(
    title = "Selección Híbrida de miRNAs (Simplificada)",
    subtitle = "Rojo: Top por cuentas | Azul: Top por VAF | Verde: Top compuesto",
    x = "Cuentas G>T Normalizadas (log10)",
    y = "VAF Promedio (log10)"
  ) +
  theme_minimal()

ggsave("outputs/figures/simple_hybrid/scatter_vaf_vs_counts.png", p1, 
       width = 10, height = 8, dpi = 300)

# 8.2 Diagrama de Venn
venn_data <- list(
  "Por Cuentas" = counts_mirnas,
  "Por VAF" = vaf_mirnas,
  "Compuesto" = composite_mirnas
)

png("outputs/figures/simple_hybrid/venn_diagram.png", width = 800, height = 600, res = 150)
venn.plot <- venn.diagram(
  venn_data,
  filename = NULL,
  fill = c("lightcoral", "lightblue", "lightgreen"),
  alpha = 0.7,
  cex = 1.5,
  cat.cex = 1.2,
  main = "Solapamiento de Métodos de Selección (Simplificado)"
)
grid.draw(venn.plot)
dev.off()

# 8.3 Distribución de expresión
p2 <- ggplot(mirna_metrics, aes(x = total_expression)) +
  geom_histogram(bins = 50, alpha = 0.7, fill = "lightblue") +
  geom_vline(xintercept = expr_threshold, color = "red", linetype = "dashed") +
  scale_x_log10() +
  labs(
    title = "Distribución de Expresión de miRNAs",
    subtitle = paste("Línea roja: Umbral de filtrado (", round(expr_threshold, 2), ")"),
    x = "Expresión Total (log10)",
    y = "Frecuencia"
  ) +
  theme_minimal()

ggsave("outputs/figures/simple_hybrid/expression_distribution.png", p2, 
       width = 10, height = 6, dpi = 300)

# 9. Guardar resultados
cat("📊 PASO 9: Guardando resultados...\n")
write_tsv(mirna_metrics, "outputs/simple_hybrid_all_metrics.tsv")
write_tsv(top_by_counts, "outputs/simple_hybrid_top_by_counts.tsv")
write_tsv(top_by_vaf, "outputs/simple_hybrid_top_by_vaf.tsv")
write_tsv(top_by_composite, "outputs/simple_hybrid_top_by_composite.tsv")

# 10. Crear reporte
cat("📊 PASO 10: Generando reporte...\n")
report_content <- paste0(
  "# REPORTE DE ANÁLISIS HÍBRIDO SIMPLIFICADO\n\n",
  "**Fecha:** ", Sys.Date(), "\n",
  "**Archivo de datos:** results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt\n\n",
  
  "## RESUMEN DE RESULTADOS\n\n",
  "- **miRNAs totales en dataset:** ", length(unique(df$`miRNA name`)), "\n",
  "- **miRNAs con mutaciones G>T:** ", length(unique(df_gt$`miRNA name`)), "\n",
  "- **miRNAs después de filtrar VAF > 50%:** ", length(unique(df_gt_filtered$`miRNA name`)), "\n",
  "- **miRNAs con alta expresión (percentil 25+):** ", length(high_expr_mirnas), "\n",
  "- **miRNAs con métricas válidas:** ", nrow(mirna_metrics), "\n",
  "- **Umbral de expresión:** ", round(expr_threshold, 2), "\n\n",
  
  "## TOP miRNAs SELECCIONADOS\n\n",
  "### Por Cuentas Normalizadas (", nrow(top_by_counts), " miRNAs)\n",
  "```\n",
  paste(top_by_counts$`miRNA name`, collapse = ", "), "\n",
  "```\n\n",
  
  "### Por VAF Promedio (", nrow(top_by_vaf), " miRNAs)\n",
  "```\n",
  paste(top_by_vaf$`miRNA name`, collapse = ", "), "\n",
  "```\n\n",
  
  "### Por Puntuación Compuesta (", nrow(top_by_composite), " miRNAs)\n",
  "```\n",
  paste(top_by_composite$`miRNA name`, collapse = ", "), "\n",
  "```\n\n",
  
  "## ANÁLISIS DE SOLAPAMIENTO\n\n",
  "- **Cuentas ↔ VAF:** ", length(shared_counts_vaf), " miRNAs\n",
  "- **Cuentas ↔ Compuesta:** ", length(shared_counts_composite), " miRNAs\n",
  "- **VAF ↔ Compuesta:** ", length(shared_vaf_composite), " miRNAs\n",
  "- **Los tres métodos:** ", length(shared_all_three), " miRNAs\n\n",
  
  "## INTERPRETACIÓN\n\n",
  "El análisis híbrido simplificado identifica miRNAs relevantes desde múltiples perspectivas:\n\n",
  "1. **Por cuentas normalizadas:** miRNAs con mayor carga mutacional absoluta\n",
  "2. **Por VAF promedio:** miRNAs con mayor tasa de mutación relativa\n",
  "3. **Por puntuación compuesta:** Balance entre ambos criterios\n\n",
  "La superposición entre métodos indica qué miRNAs son consistentemente importantes según diferentes criterios."
)

writeLines(report_content, "outputs/simple_hybrid_report.md")

cat("✅ ANÁLISIS HÍBRIDO SIMPLIFICADO COMPLETADO\n")
cat("==========================================\n\n")
cat("📁 Archivos generados en outputs/\n")
cat("📊 Visualizaciones en outputs/figures/simple_hybrid/\n")
cat("📋 Reporte: outputs/simple_hybrid_report.md\n\n")
cat("🎯 Próximo paso: Revisar resultados y seleccionar método final\n")

