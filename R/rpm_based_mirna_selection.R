#!/usr/bin/env Rscript

# SELECCIÓN DE miRNAs BASADA EN RPM
# Filtra por RPM mínimo, presencia de G>T, y selecciona top miRNAs

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

cat("🧬 SELECCIÓN DE miRNAs BASADA EN RPM\n")
cat("====================================\n\n")

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

# 3. Calcular RPM por miRNA
cat("📊 PASO 3: Calculando RPM por miRNA...\n")

# 3.1 Calcular library size por muestra
lib_sizes <- df %>%
  group_by(`miRNA name`) %>%
  summarise(
    across(all_of(total_cols), ~sum(.x, na.rm = TRUE)),
    .groups = 'drop'
  ) %>%
  # Sumar todas las columnas totales para obtener library size por muestra
  summarise(
    across(all_of(total_cols), ~sum(.x, na.rm = TRUE)),
    .groups = 'drop'
  )

# Convertir a vector
lib_size_vec <- as.numeric(lib_sizes[1, ])
names(lib_size_vec) <- str_replace(colnames(lib_sizes), " \\(PM\\+1MM\\+2MM\\)", "")

cat("   - Library sizes calculados para", length(lib_size_vec), "muestras\n")
cat("   - Rango de library sizes:", round(range(lib_size_vec), 2), "\n\n")

# 3.2 Calcular RPM por miRNA
mirna_rpm <- df %>%
  group_by(`miRNA name`) %>%
  summarise(
    across(all_of(total_cols), ~sum(.x, na.rm = TRUE)),
    .groups = 'drop'
  ) %>%
  # Calcular RPM para cada muestra
  mutate(
    across(all_of(total_cols), ~(.x / lib_size_vec[str_replace(cur_column(), " \\(PM\\+1MM\\+2MM\\)", "")]) * 1e6)
  )

# 3.3 Calcular RPM promedio por miRNA
mirna_rpm_summary <- mirna_rpm %>%
  mutate(
    rpm_mean = rowMeans(across(all_of(total_cols)), na.rm = TRUE),
    rpm_median = apply(across(all_of(total_cols)), 1, median, na.rm = TRUE),
    rpm_max = apply(across(all_of(total_cols)), 1, max, na.rm = TRUE)
  ) %>%
  select(`miRNA name`, rpm_mean, rpm_median, rpm_max)

cat("   - RPM calculados para", nrow(mirna_rpm_summary), "miRNAs\n")
cat("   - Rango de RPM promedio:", round(range(mirna_rpm_summary$rpm_mean), 2), "\n\n")

# 4. Filtrar por RPM mínimo
cat("📊 PASO 4: Filtrando por RPM mínimo...\n")
rpm_threshold <- quantile(mirna_rpm_summary$rpm_mean, 0.25)  # Percentil 25
high_rpm_mirnas <- mirna_rpm_summary$`miRNA name`[mirna_rpm_summary$rpm_mean >= rpm_threshold]

cat("   - Umbral de RPM (percentil 25):", round(rpm_threshold, 2), "\n")
cat("   - miRNAs con RPM alto:", length(high_rpm_mirnas), "\n\n")

# 5. Filtrar por presencia de G>T
cat("📊 PASO 5: Filtrando por presencia de mutaciones G>T...\n")
df_gt <- df %>% filter(str_detect(`pos:mut`, ":GT"))
gt_mirnas <- unique(df_gt$`miRNA name`)

# Intersección: miRNAs con RPM alto Y mutaciones G>T
candidate_mirnas <- intersect(high_rpm_mirnas, gt_mirnas)

cat("   - miRNAs con mutaciones G>T:", length(gt_mirnas), "\n")
cat("   - miRNAs candidatos (RPM alto + G>T):", length(candidate_mirnas), "\n\n")

# 6. Filtrar SNVs con VAF > 50%
cat("📊 PASO 6: Filtrando SNVs con VAF > 50%...\n")
df_candidates <- df_gt %>% filter(`miRNA name` %in% candidate_mirnas)

# Calcular VAFs
snv_mat <- as.matrix(df_candidates[, snv_cols])
total_mat <- as.matrix(df_candidates[, total_cols])
colnames(total_mat) <- str_replace(colnames(total_mat), " \\(PM\\+1MM\\+2MM\\)", "")

vaf_mat <- snv_mat / (total_mat + 1e-10)

# Filtrar SNVs con VAF > 50%
high_vaf_idx <- apply(vaf_mat > 0.5, 1, any, na.rm = TRUE)
df_filtered <- df_candidates[!high_vaf_idx, ]

cat("   - SNVs removidos (VAF > 50%):", sum(high_vaf_idx), "\n")
cat("   - Filas después de filtrar:", nrow(df_filtered), "\n")
cat("   - miRNAs únicos después de filtrar:", length(unique(df_filtered$`miRNA name`)), "\n\n")

# 7. Calcular total de G>T por miRNA
cat("📊 PASO 7: Calculando total de G>T por miRNA...\n")
mirna_gt_counts <- df_filtered %>%
  group_by(`miRNA name`) %>%
  summarise(
    total_gt_counts = sum(across(all_of(snv_cols), ~sum(.x, na.rm = TRUE)), na.rm = TRUE),
    unique_snvs = n(),
    .groups = 'drop'
  ) %>%
  # Agregar información de RPM
  left_join(mirna_rpm_summary, by = "miRNA name") %>%
  # Ordenar por total de G>T
  arrange(desc(total_gt_counts))

cat("   - miRNAs con métricas calculadas:", nrow(mirna_gt_counts), "\n")
cat("   - Rango de cuentas G>T:", range(mirna_gt_counts$total_gt_counts), "\n\n")

# 8. Seleccionar top miRNAs
cat("📊 PASO 8: Seleccionando top miRNAs...\n")
top_percent <- 0.15  # 15% como sugeriste
top_n <- max(1, floor(nrow(mirna_gt_counts) * top_percent))

top_mirnas <- mirna_gt_counts %>%
  head(top_n)

cat("   - Top", top_percent*100, "% seleccionados:", nrow(top_mirnas), "miRNAs\n")
cat("   - Rango de cuentas G>T en top:", range(top_mirnas$total_gt_counts), "\n\n")

# 9. Filtrar dataset original con la lista de top miRNAs
cat("📊 PASO 9: Filtrando dataset original con top miRNAs...\n")
df_top_filtered <- df %>%
  filter(`miRNA name` %in% top_mirnas$`miRNA name`) %>%
  filter(str_detect(`pos:mut`, ":GT"))

# Recalcular VAFs para el dataset filtrado
snv_mat_top <- as.matrix(df_top_filtered[, snv_cols])
total_mat_top <- as.matrix(df_top_filtered[, total_cols])
colnames(total_mat_top) <- str_replace(colnames(total_mat_top), " \\(PM\\+1MM\\+2MM\\)", "")

vaf_mat_top <- snv_mat_top / (total_mat_top + 1e-10)

# Filtrar SNVs con VAF > 50% en el dataset filtrado
high_vaf_idx_top <- apply(vaf_mat_top > 0.5, 1, any, na.rm = TRUE)
df_final <- df_top_filtered[!high_vaf_idx_top, ]

cat("   - Dataset final filtrado:", nrow(df_final), "filas\n")
cat("   - miRNAs en dataset final:", length(unique(df_final$`miRNA name`)), "\n")
cat("   - SNVs removidos en filtrado final:", sum(high_vaf_idx_top), "\n\n")

# 10. Crear visualizaciones
cat("📊 PASO 10: Creando visualizaciones...\n")
dir.create("outputs/figures/rpm_based_selection", showWarnings = FALSE, recursive = TRUE)

# 10.1 Distribución de RPM
p1 <- ggplot(mirna_rpm_summary, aes(x = rpm_mean)) +
  geom_histogram(bins = 50, alpha = 0.7, fill = "lightblue") +
  geom_vline(xintercept = rpm_threshold, color = "red", linetype = "dashed") +
  scale_x_log10() +
  labs(
    title = "Distribución de RPM por miRNA",
    subtitle = paste("Línea roja: Umbral de filtrado (", round(rpm_threshold, 2), " RPM)"),
    x = "RPM Promedio (log10)",
    y = "Frecuencia"
  ) +
  theme_minimal()

ggsave("outputs/figures/rpm_based_selection/rpm_distribution.png", p1, 
       width = 10, height = 6, dpi = 300)

# 10.2 RPM vs Cuentas G>T
p2 <- ggplot(mirna_gt_counts, aes(x = rpm_mean, y = total_gt_counts)) +
  geom_point(alpha = 0.6, color = "gray70") +
  geom_point(data = top_mirnas, color = "red", size = 2) +
  scale_x_log10() +
  scale_y_log10() +
  labs(
    title = "RPM vs Cuentas G>T por miRNA",
    subtitle = paste("Rojo: Top", top_percent*100, "% seleccionados"),
    x = "RPM Promedio (log10)",
    y = "Total Cuentas G>T (log10)"
  ) +
  theme_minimal()

ggsave("outputs/figures/rpm_based_selection/rpm_vs_gt_counts.png", p2, 
       width = 10, height = 8, dpi = 300)

# 10.3 Heatmap de top miRNAs
if (nrow(top_mirnas) > 0) {
  # Crear matriz de VAFs para heatmap
  vaf_cols <- paste0(str_replace(snv_cols, "Magen-ALS-enrolment-bloodplasma-", ""), "_VAF")
  df_heatmap <- df_final %>%
    select(`miRNA name`, `pos:mut`, all_of(snv_cols)) %>%
    pivot_longer(cols = all_of(snv_cols), names_to = "sample", values_to = "count") %>%
    left_join(
      df_final %>%
        select(`miRNA name`, `pos:mut`, all_of(total_cols)) %>%
        pivot_longer(cols = all_of(total_cols), names_to = "sample", values_to = "total") %>%
        mutate(sample = str_replace(sample, " \\(PM\\+1MM\\+2MM\\)", "")),
      by = c("miRNA name", "pos:mut", "sample")
    ) %>%
    mutate(vaf = count / (total + 1e-10)) %>%
    select(`miRNA name`, `pos:mut`, sample, vaf) %>%
    pivot_wider(names_from = sample, values_from = vaf) %>%
    unite("feature_id", `miRNA name`, `pos:mut`, sep = "_") %>%
    column_to_rownames("feature_id")
  
  # Filtrar filas con valores válidos
  df_heatmap_clean <- df_heatmap %>%
    filter(!is.na(rowSums(.))) %>%
    filter(is.finite(rowSums(.)))
  
  if (nrow(df_heatmap_clean) > 0) {
    png("outputs/figures/rpm_based_selection/heatmap_top_mirnas.png", 
        width = 1200, height = 800, res = 150)
    pheatmap(
      as.matrix(df_heatmap_clean),
      clustering_distance_rows = "euclidean",
      clustering_distance_cols = "euclidean",
      clustering_method = "ward.D2",
      color = viridis(100),
      main = paste("Heatmap de VAFs - Top", top_percent*100, "% miRNAs"),
      fontsize = 8,
      show_rownames = FALSE
    )
    dev.off()
    cat("   - Heatmap generado\n")
  }
}

# 11. Guardar resultados
cat("📊 PASO 11: Guardando resultados...\n")

# Guardar métricas completas
write_tsv(mirna_gt_counts, "outputs/rpm_based_all_metrics.tsv")

# Guardar top miRNAs
write_tsv(top_mirnas, "outputs/rpm_based_top_mirnas.tsv")

# Guardar dataset final filtrado
write_tsv(df_final, "outputs/rpm_based_final_dataset.tsv")

# Guardar lista de top miRNAs para uso posterior
writeLines(top_mirnas$`miRNA name`, "outputs/rpm_based_top_mirna_list.txt")

# 12. Crear reporte
cat("📊 PASO 12: Generando reporte...\n")
report_content <- paste0(
  "# REPORTE DE SELECCIÓN BASADA EN RPM\n\n",
  "**Fecha:** ", Sys.Date(), "\n",
  "**Archivo de datos:** results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt\n\n",
  
  "## RESUMEN DE RESULTADOS\n\n",
  "- **miRNAs totales en dataset:** ", length(unique(df$`miRNA name`)), "\n",
  "- **miRNAs con RPM alto (percentil 25+):** ", length(high_rpm_mirnas), "\n",
  "- **miRNAs con mutaciones G>T:** ", length(gt_mirnas), "\n",
  "- **miRNAs candidatos (RPM alto + G>T):** ", length(candidate_mirnas), "\n",
  "- **miRNAs después de filtrar VAF > 50%:** ", length(unique(df_filtered$`miRNA name`)), "\n",
  "- **Top miRNAs seleccionados:** ", nrow(top_mirnas), " (", top_percent*100, "%)\n",
  "- **Umbral de RPM:** ", round(rpm_threshold, 2), "\n\n",
  
  "## TOP miRNAs SELECCIONADOS\n\n",
  "```\n",
  paste(top_mirnas$`miRNA name`, collapse = ", "), "\n",
  "```\n\n",
  
  "## MÉTRICAS DE LOS TOP miRNAs\n\n",
  "| miRNA | RPM Promedio | Total G>T | SNVs Únicos |\n",
  "|-------|--------------|-----------|-------------|\n",
  paste(apply(top_mirnas, 1, function(x) {
    paste0("| ", x[1], " | ", round(as.numeric(x[2]), 2), " | ", x[3], " | ", x[4], " |")
  }), collapse = "\n"),
  "\n\n",
  
  "## ARCHIVOS GENERADOS\n\n",
  "- `rpm_based_all_metrics.tsv`: Métricas completas de todos los miRNAs\n",
  "- `rpm_based_top_mirnas.tsv`: Top miRNAs seleccionados\n",
  "- `rpm_based_final_dataset.tsv`: Dataset final filtrado\n",
  "- `rpm_based_top_mirna_list.txt`: Lista de nombres de top miRNAs\n",
  "- `figures/rpm_based_selection/`: Visualizaciones del análisis\n\n",
  
  "## INTERPRETACIÓN\n\n",
  "La selección basada en RPM proporciona una metodología más robusta:\n\n",
  "1. **Filtrado por expresión real**: RPM es más biológicamente relevante que cuentas absolutas\n",
  "2. **Presencia de mutaciones**: Solo miRNAs con mutaciones G>T son considerados\n",
  "3. **Calidad de datos**: Filtrado de SNVs con VAF > 50% elimina artefactos\n",
  "4. **Selección por carga mutacional**: Top miRNAs por total de mutaciones G>T\n\n",
  "Los miRNAs seleccionados representan los más relevantes para análisis posteriores de mutaciones G>T en ALS."
)

writeLines(report_content, "outputs/rpm_based_selection_report.md")

cat("✅ ANÁLISIS BASADO EN RPM COMPLETADO\n")
cat("====================================\n\n")
cat("📁 Archivos generados en outputs/\n")
cat("📊 Visualizaciones en outputs/figures/rpm_based_selection/\n")
cat("📋 Reporte: outputs/rpm_based_selection_report.md\n\n")
cat("🎯 Top miRNAs seleccionados:", nrow(top_mirnas), "\n")
cat("📝 Lista guardada en: outputs/rpm_based_top_mirna_list.txt\n")











