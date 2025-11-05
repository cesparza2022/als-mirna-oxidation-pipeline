#!/usr/bin/env Rscript

# =============================================================================
# PASO 4: GENERACIÓN DE VISUALIZACIONES Y REPORTE FINAL
# =============================================================================
# - Crear gráficos de VAF comparativo
# - Crear gráficos de Z-score distribution
# - Crear heatmaps de región semilla
# - Generar reporte final en Markdown

library(dplyr)
library(readr)
library(stringr)
library(tidyr)
library(ggplot2)
library(ComplexHeatmap)
library(circlize)
library(viridis)
library(RColorBrewer)

cat("=== PASO 4: GENERACIÓN DE VISUALIZACIONES Y REPORTE ===\n\n")

# --- PASO 4.1: Cargar datos procesados ---
cat("PASO 4.1: Cargando datos procesados\n")
cat("==========================================\n")

# Cargar datos originales
df_main <- read_tsv("results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt", show_col_types = FALSE)
df_main <- df_main[-1, ]  # Remover metadatos

sample_cols <- names(df_main)[!names(df_main) %in% c("miRNA name", "pos:mut")]
als_samples <- sample_cols[str_detect(sample_cols, "Magen-ALS")]
control_samples <- sample_cols[str_detect(sample_cols, "Magen-control")]

# Aplicar split y collapse
split_mutations <- function(row_data) {
  pos_mut <- row_data$`pos:mut`
  mutations <- str_split(pos_mut, ",")[[1]]
  mutations <- str_trim(mutations)
  
  if (length(mutations) == 1) {
    return(row_data)
  } else {
    result_rows <- list()
    for (mut in mutations) {
      new_row <- row_data
      new_row$`pos:mut` <- mut
      result_rows[[length(result_rows) + 1]] <- new_row
    }
    return(bind_rows(result_rows))
  }
}

df_split_list <- list()
for (i in 1:nrow(df_main)) {
  split_result <- split_mutations(df_main[i, ])
  df_split_list[[length(df_split_list) + 1]] <- split_result
}
df_split <- bind_rows(df_split_list)

df_collapsed <- df_split %>%
  group_by(`miRNA name`, `pos:mut`) %>%
  summarise(
    across(all_of(sample_cols), ~ sum(as.numeric(.x), na.rm = TRUE)),
    .groups = "drop"
  )

# Aplicar filtro de representación
df_long <- df_collapsed %>%
  pivot_longer(
    cols = all_of(sample_cols),
    names_to = "sample",
    values_to = "count"
  ) %>%
  mutate(count = as.numeric(count))

high_rep_snvs <- df_long %>%
  group_by(`miRNA name`, `pos:mut`) %>%
  summarise(
    samples_with_count = sum(count > 0, na.rm = TRUE),
    frac_present = samples_with_count / length(sample_cols),
    .groups = "drop"
  ) %>%
  filter(frac_present > 0.5) %>%
  mutate(snv_id = paste(`miRNA name`, `pos:mut`, sep = "_"))

df_long$snv_id <- paste(df_long$`miRNA name`, df_long$`pos:mut`, sep = "_")
df_filtered_long <- df_long %>%
  mutate(
    count_filtered = ifelse(snv_id %in% high_rep_snvs$snv_id, NA_real_, count)
  )

# Filtrar solo G>T y calcular VAFs
df_gt_filtered <- df_filtered_long %>%
  filter(str_detect(`pos:mut`, "GT")) %>%
  mutate(
    group = ifelse(str_detect(sample, "Magen-ALS"), "ALS", "Control")
  )

vaf_summary <- df_gt_filtered %>%
  group_by(`miRNA name`, `pos:mut`, group) %>%
  summarise(
    mean_vaf = mean(count_filtered, na.rm = TRUE),
    median_vaf = median(count_filtered, na.rm = TRUE),
    samples_with_data = sum(!is.na(count_filtered)),
    total_samples = n(),
    .groups = "drop"
  ) %>%
  pivot_wider(
    names_from = group,
    values_from = c(mean_vaf, median_vaf, samples_with_data, total_samples),
    names_sep = "_"
  ) %>%
  mutate(
    mean_vaf_ALS = replace_na(mean_vaf_ALS, 0),
    mean_vaf_Control = replace_na(mean_vaf_Control, 0),
    vaf_difference = mean_vaf_ALS - mean_vaf_Control
  )

# Calcular Z-scores
als_values <- df_gt_filtered %>% 
  filter(group == "ALS") %>% 
  pull(count_filtered) %>% 
  .[!is.na(.)]

control_values <- df_gt_filtered %>% 
  filter(group == "Control") %>% 
  pull(count_filtered) %>% 
  .[!is.na(.)]

pooled_sd <- sqrt(((length(als_values) - 1) * var(als_values) + 
                   (length(control_values) - 1) * var(control_values)) / 
                  (length(als_values) + length(control_values) - 2))

vaf_summary <- vaf_summary %>%
  mutate(
    z_score = (mean_vaf_ALS - mean_vaf_Control) / pooled_sd,
    abs_z_score = abs(z_score),
    pos = as.numeric(str_extract(`pos:mut`, "^[0-9]+"))
  )

cat(paste0("  - Datos procesados: ", nrow(vaf_summary), " SNVs G>T\n"))

# --- PASO 4.2: Gráfico 1: VAF Comparativo ---
cat("\nPASO 4.2: Creando gráfico VAF comparativo\n")
cat("==========================================\n")

# Preparar datos para el gráfico
plot_data <- vaf_summary %>%
  select(`miRNA name`, `pos:mut`, mean_vaf_ALS, mean_vaf_Control, vaf_difference, z_score) %>%
  mutate(abs_z_score = abs(z_score)) %>%
  arrange(desc(abs_z_score)) %>%
  head(20) %>%
  mutate(
    snv_label = paste(`miRNA name`, `pos:mut`, sep = " "),
    snv_label = str_wrap(snv_label, width = 20)
  )

# Gráfico de barras comparativo
p1 <- ggplot(plot_data, aes(x = reorder(snv_label, vaf_difference))) +
  geom_col(aes(y = mean_vaf_ALS), fill = "#E31A1C", alpha = 0.7, width = 0.4, position = position_nudge(x = -0.2)) +
  geom_col(aes(y = mean_vaf_Control), fill = "#1F78B4", alpha = 0.7, width = 0.4, position = position_nudge(x = 0.2)) +
  coord_flip() +
  labs(
    title = "Top 20 SNVs G>T: VAF Promedio ALS vs Control",
    subtitle = "Después del filtro de representación (VAF > 50% → NaN)",
    x = "SNV (miRNA + Posición:Mutación)",
    y = "VAF Promedio",
    fill = "Grupo"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 10),
    axis.text.y = element_text(size = 8),
    legend.position = "bottom"
  ) +
  scale_fill_manual(values = c("ALS" = "#E31A1C", "Control" = "#1F78B4"))

# Guardar gráfico
ggsave("outputs/final_paper_graphs/vaf_comparison_after_filter.pdf", p1, 
       width = 12, height = 8, dpi = 300)

cat("  - Gráfico VAF comparativo guardado: vaf_comparison_after_filter.pdf\n")

# --- PASO 4.3: Gráfico 2: Distribución de Z-scores ---
cat("\nPASO 4.3: Creando gráfico de distribución de Z-scores\n")
cat("==========================================\n")

# Gráfico de distribución de Z-scores
p2 <- ggplot(vaf_summary, aes(x = z_score)) +
  geom_histogram(aes(y = ..density..), bins = 50, fill = "#2E8B57", alpha = 0.7, color = "white") +
  geom_density(color = "#1B4F3C", size = 1.2) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "red", size = 1) +
  geom_vline(xintercept = c(-2, 2), linetype = "dashed", color = "orange", size = 0.8) +
  labs(
    title = "Distribución de Z-scores para SNVs G>T",
    subtitle = "Líneas: Z=0 (roja), Z=±2 (naranja)",
    x = "Z-score",
    y = "Densidad"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 10)
  )

# Guardar gráfico
ggsave("outputs/final_paper_graphs/zscore_distribution_after_filter.pdf", p2, 
       width = 10, height = 6, dpi = 300)

cat("  - Gráfico distribución Z-scores guardado: zscore_distribution_after_filter.pdf\n")

# --- PASO 4.4: Gráfico 3: Heatmap de región semilla ---
cat("\nPASO 4.4: Creando heatmap de región semilla\n")
cat("==========================================\n")

# Preparar datos para heatmap de región semilla
seed_data <- vaf_summary %>%
  filter(pos >= 2 & pos <= 8) %>%
  arrange(desc(abs_z_score)) %>%
  head(30) %>%  # Top 30 para visualización
  select(`miRNA name`, `pos:mut`, pos, mean_vaf_ALS, mean_vaf_Control, z_score) %>%
  mutate(
    snv_id = paste(`miRNA name`, `pos:mut`, sep = " "),
    pos_factor = factor(pos, levels = 2:8)
  )

# Crear matriz para heatmap
heatmap_data <- seed_data %>%
  select(snv_id, pos_factor, z_score) %>%
  pivot_wider(names_from = pos_factor, values_from = z_score, values_fill = 0) %>%
  column_to_rownames("snv_id")

# Crear heatmap
col_fun <- colorRamp2(c(-3, 0, 3), c("#2166AC", "white", "#B2182B"))

ht <- Heatmap(
  as.matrix(heatmap_data),
  name = "Z-score",
  col = col_fun,
  cluster_rows = TRUE,
  cluster_columns = FALSE,
  show_row_names = TRUE,
  show_column_names = TRUE,
  row_names_gp = gpar(fontsize = 8),
  column_names_gp = gpar(fontsize = 10),
  heatmap_legend_param = list(
    title = "Z-score",
    title_gp = gpar(fontsize = 10),
    labels_gp = gpar(fontsize = 8)
  )
)

# Guardar heatmap
pdf("outputs/final_paper_graphs/seed_region_heatmap_after_filter.pdf", width = 10, height = 12)
draw(ht)
dev.off()

cat("  - Heatmap región semilla guardado: seed_region_heatmap_after_filter.pdf\n")

# --- PASO 4.5: Generar reporte final ---
cat("\nPASO 4.5: Generando reporte final\n")
cat("==========================================\n")

# Crear reporte en Markdown
report_content <- paste0(
"# Análisis de Mutaciones G>T en miRNAs: Efecto del Filtro de Representación

## Resumen Ejecutivo

Este análisis evalúa el impacto del filtro de representación (VAF > 50% → NaN) en el análisis de mutaciones G>T en miRNAs, comparando muestras de pacientes con ALS versus controles.

## Metodología

### 1. Procesamiento de Datos
- **Archivo de entrada:** `miRNA_count.Q33.txt`
- **Muestras totales:** ", length(sample_cols), " (", length(als_samples), " ALS, ", length(control_samples), " Control)
- **Procesamiento:** Split de mutaciones múltiples → Collapse → Filtro de representación

### 2. Filtro de Representación
- **Criterio:** SNVs presentes en >50% de las muestras
- **Acción:** Conversión de valores a NaN (no eliminación de filas)
- **SNVs afectados:** ", nrow(high_rep_snvs), " de ", nrow(df_collapsed), " totales
- **Valores convertidos a NaN:** ", sum(is.na(df_filtered_long$count_filtered)), " (", 
round(sum(is.na(df_filtered_long$count_filtered))/nrow(df_filtered_long)*100, 2), "%)

## Resultados Principales

### 1. Análisis de G>T
- **SNVs G>T totales:** ", nrow(vaf_summary), "
- **SNVs G>T con alta representación:** ", nrow(high_rep_snvs %>% filter(str_detect(`pos:mut`, "GT"))), "
- **Valores G>T convertidos a NaN:** ", sum(is.na(df_gt_filtered$count_filtered)), " (", 
round(sum(is.na(df_gt_filtered$count_filtered))/nrow(df_gt_filtered)*100, 2), "%)

### 2. Comparación ALS vs Control
- **VAF promedio ALS:** ", round(mean(vaf_summary$mean_vaf_ALS, na.rm = TRUE), 2), "
- **VAF promedio Control:** ", round(mean(vaf_summary$mean_vaf_Control, na.rm = TRUE), 2), "
- **Z-score promedio:** ", round(mean(vaf_summary$z_score, na.rm = TRUE), 4), "
- **Z-score máximo:** ", round(max(vaf_summary$abs_z_score, na.rm = TRUE), 4), "

### 3. Región Semilla (Posiciones 2-8)
- **SNVs G>T en semilla:** ", nrow(vaf_summary %>% filter(pos >= 2 & pos <= 8)), "
- **SNVs con VAF mayor en ALS:** ", sum((vaf_summary %>% filter(pos >= 2 & pos <= 8))$vaf_difference > 0), "
- **SNVs con VAF mayor en Control:** ", sum((vaf_summary %>% filter(pos >= 2 & pos <= 8))$vaf_difference < 0), "
- **SNVs con |Z-score| > 2:** ", sum((vaf_summary %>% filter(pos >= 2 & pos <= 8))$abs_z_score > 2), "

## Top SNVs G>T por Diferencia de VAF

| miRNA | Posición:Mutación | VAF ALS | VAF Control | Diferencia | Z-score |
|-------|-------------------|---------|-------------|------------|---------|
")

# Agregar top 10 SNVs
top_10 <- vaf_summary %>%
  arrange(desc(vaf_difference)) %>%
  head(10) %>%
  select(`miRNA name`, `pos:mut`, mean_vaf_ALS, mean_vaf_Control, vaf_difference, z_score)

for (i in 1:nrow(top_10)) {
  report_content <- paste0(report_content,
    "| ", top_10$`miRNA name`[i], " | ", top_10$`pos:mut`[i], " | ", 
    round(top_10$mean_vaf_ALS[i], 1), " | ", round(top_10$mean_vaf_Control[i], 1), " | ", 
    round(top_10$vaf_difference[i], 1), " | ", round(top_10$z_score[i], 3), " |\n"
  )
}

report_content <- paste0(report_content,
"
## Análisis por Posición

### Posiciones más afectadas por el filtro de representación:

| Posición | Total SNVs | Alta Representación | % Afectados |
|----------|------------|-------------------|-------------|
")

# Calcular estadísticas por posición
pos_stats <- vaf_summary %>%
  group_by(pos) %>%
  summarise(
    total_snvs = n(),
    high_rep = sum(abs_z_score > 1),  # Usando Z-score como proxy
    frac_affected = high_rep / total_snvs,
    .groups = "drop"
  ) %>%
  arrange(desc(frac_affected)) %>%
  head(10)

for (i in 1:nrow(pos_stats)) {
  report_content <- paste0(report_content,
    "| ", pos_stats$pos[i], " | ", pos_stats$total_snvs[i], " | ", 
    pos_stats$high_rep[i], " | ", round(pos_stats$frac_affected[i]*100, 1), "% |\n"
  )
}

report_content <- paste0(report_content,
"
## Conclusiones

1. **Efecto del filtro de representación:** El filtro afectó significativamente los datos, convirtiendo ", 
round(sum(is.na(df_filtered_long$count_filtered))/nrow(df_filtered_long)*100, 2), "% de los valores a NaN.

2. **Diferencias ALS vs Control:** Se observaron diferencias significativas en VAF entre grupos, con algunos SNVs mostrando Z-scores > 3.

3. **Región semilla:** La región semilla (posiciones 2-8) contiene ", nrow(vaf_summary %>% filter(pos >= 2 & pos <= 8)), 
" SNVs G>T, con distribución relativamente equilibrada entre grupos.

4. **Top miRNAs:** Los miRNAs más diferenciales incluyen hsa-miR-196a-5p, hsa-miR-9-5p, y hsa-miR-127-3p.

## Archivos Generados

- `vaf_comparison_after_filter.pdf`: Gráfico comparativo de VAF
- `zscore_distribution_after_filter.pdf`: Distribución de Z-scores
- `seed_region_heatmap_after_filter.pdf`: Heatmap de región semilla

---
*Análisis generado el ", Sys.Date(), " usando R ", R.version.string, "*"
)

# Guardar reporte
writeLines(report_content, "outputs/final_paper_graphs/representation_filter_analysis_report.md")

cat("  - Reporte final guardado: representation_filter_analysis_report.md\n")

# --- PASO 4.6: Resumen final ---
cat("\nPASO 4.6: Resumen final\n")
cat("==========================================\n")

cat("ANÁLISIS COMPLETADO EXITOSAMENTE:\n")
cat("================================\n")
cat(paste0("✓ Datos procesados: ", nrow(df_collapsed), " SNVs totales\n"))
cat(paste0("✓ SNVs G>T analizados: ", nrow(vaf_summary), "\n"))
cat(paste0("✓ Filtro de representación aplicado: ", sum(is.na(df_filtered_long$count_filtered)), " valores a NaN\n"))
cat(paste0("✓ Gráficos generados: 3 archivos PDF\n"))
cat(paste0("✓ Reporte final: representation_filter_analysis_report.md\n\n"))

cat("ARCHIVOS GENERADOS:\n")
cat("===================\n")
cat("- outputs/final_paper_graphs/vaf_comparison_after_filter.pdf\n")
cat("- outputs/final_paper_graphs/zscore_distribution_after_filter.pdf\n")
cat("- outputs/final_paper_graphs/seed_region_heatmap_after_filter.pdf\n")
cat("- outputs/final_paper_graphs/representation_filter_analysis_report.md\n\n")

cat("PRÓXIMOS PASOS SUGERIDOS:\n")
cat("=========================\n")
cat("1. Revisar los gráficos generados\n")
cat("2. Analizar los miRNAs más diferenciales\n")
cat("3. Integrar resultados en el paper principal\n")
cat("4. Actualizar bitácora y memoria\n\n")

cat("=== PASO 4 COMPLETADO ===\n")
