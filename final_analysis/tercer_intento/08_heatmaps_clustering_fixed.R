library(dplyr)
library(stringr)
library(ComplexHeatmap)
library(circlize)
library(RColorBrewer)
library(viridis)

# =============================================================================
# HEATMAPS CON CLUSTERING JERÁRQUICO - POSICIONES SIGNIFICATIVAS (CORREGIDO)
# =============================================================================

cat("=== HEATMAPS CON CLUSTERING JERÁRQUICO (CORREGIDO) ===\n\n")

# 1. CARGAR DATOS PROCESADOS
# =============================================================================
cat("1. CARGANDO DATOS PROCESADOS\n")
cat("============================\n")

final_data <- read.csv("../processed_data/final_processed_data.csv", stringsAsFactors = FALSE)

cat("Datos cargados:\n")
cat("  - SNVs totales:", nrow(final_data), "\n")
cat("  - miRNAs únicos:", length(unique(final_data$miRNA_name)), "\n\n")

# 2. IDENTIFICAR POSICIONES SIGNIFICATIVAS (INCLUYENDO POSICIÓN 6)
# =============================================================================
cat("2. IDENTIFICANDO POSICIONES SIGNIFICATIVAS\n")
cat("===========================================\n")

# Incluir posiciones 1-6 (1-5 muy significativas, 6 con más datos)
significant_positions <- c(1, 2, 3, 4, 5, 6)

cat("Posiciones significativas seleccionadas:", paste(significant_positions, collapse = ", "), "\n")

# Filtrar SNVs de posiciones significativas
significant_snvs <- final_data %>%
  mutate(pos = as.integer(str_extract(pos.mut, "^[0-9]+"))) %>%
  filter(pos %in% significant_positions) %>%
  select(-pos)

cat("SNVs en posiciones significativas:", nrow(significant_snvs), "\n\n")

# 3. IDENTIFICAR MUESTRAS Y GRUPOS
# =============================================================================
cat("3. IDENTIFICANDO MUESTRAS Y GRUPOS\n")
cat("==================================\n")

sample_cols <- colnames(significant_snvs)[!colnames(significant_snvs) %in% c("miRNA_name", "pos.mut")]

# Identificar grupos
identify_cohort <- function(col_name) {
  if (grepl("control", col_name, ignore.case = TRUE)) {
    return("Control")
  } else if (grepl("ALS", col_name, ignore.case = TRUE)) {
    return("ALS")
  } else {
    return("Unknown")
  }
}

cohorts <- sapply(sample_cols, identify_cohort)
control_cols <- sample_cols[cohorts == "Control"]
als_cols <- sample_cols[cohorts == "ALS"]

cat("Distribución de muestras:\n")
cat("  - Control:", length(control_cols), "muestras\n")
cat("  - ALS:", length(als_cols), "muestras\n")
cat("  - Total:", length(sample_cols), "muestras\n\n")

# 4. FILTRAR SNVs CON SUFICIENTES DATOS VÁLIDOS (FILTRO MÁS PERMISIVO)
# =============================================================================
cat("4. FILTRANDO SNVs CON SUFICIENTES DATOS VÁLIDOS\n")
cat("===============================================\n")

# Calcular el número de VAFs válidos por SNV
snv_validity <- significant_snvs %>%
  rowwise() %>%
  mutate(
    n_valid = sum(!is.na(c_across(all_of(sample_cols))) & c_across(all_of(sample_cols)) > 0),
    pct_valid = n_valid / length(sample_cols) * 100
  ) %>%
  ungroup()

# Usar filtro más permisivo: al menos 5% de muestras válidas
min_valid_threshold <- ceiling(length(sample_cols) * 0.05)
filtered_snvs <- snv_validity %>%
  filter(n_valid >= min_valid_threshold) %>%
  select(-n_valid, -pct_valid)

cat("Filtrado aplicado:\n")
cat("  - Umbral mínimo:", min_valid_threshold, "muestras válidas (5%)\n")
cat("  - SNVs antes del filtrado:", nrow(significant_snvs), "\n")
cat("  - SNVs después del filtrado:", nrow(filtered_snvs), "\n")
cat("  - SNVs eliminados:", nrow(significant_snvs) - nrow(filtered_snvs), "\n\n")

# Verificar que tenemos datos suficientes
if (nrow(filtered_snvs) == 0) {
  cat("ERROR: No hay SNVs después del filtrado. Usando filtro aún más permisivo...\n")
  
  # Usar filtro muy permisivo: al menos 1% de muestras válidas
  min_valid_threshold <- max(1, ceiling(length(sample_cols) * 0.01))
  filtered_snvs <- snv_validity %>%
    filter(n_valid >= min_valid_threshold) %>%
    select(-n_valid, -pct_valid)
  
  cat("Filtro muy permisivo aplicado:\n")
  cat("  - Umbral mínimo:", min_valid_threshold, "muestras válidas (1%)\n")
  cat("  - SNVs después del filtrado:", nrow(filtered_snvs), "\n\n")
}

# Si aún no hay datos, usar los top SNVs
if (nrow(filtered_snvs) == 0) {
  cat("ERROR: Aún no hay SNVs. Seleccionando top 50 SNVs con más datos válidos...\n")
  
  filtered_snvs <- snv_validity %>%
    arrange(desc(n_valid)) %>%
    head(50) %>%
    select(-n_valid, -pct_valid)
  
  cat("Top 50 SNVs seleccionados:", nrow(filtered_snvs), "\n\n")
}

# 5. PREPARAR MATRIZ DE VAFs PARA HEATMAP
# =============================================================================
cat("5. PREPARANDO MATRIZ DE VAFs PARA HEATMAP\n")
cat("=========================================\n")

# Crear matriz de VAFs
vaf_matrix <- as.matrix(filtered_snvs[, sample_cols])
rownames(vaf_matrix) <- paste(filtered_snvs$miRNA_name, filtered_snvs$pos.mut, sep = "_")

# Reemplazar NAs con 0 para el clustering
vaf_matrix_clean <- vaf_matrix
vaf_matrix_clean[is.na(vaf_matrix_clean)] <- 0

cat("Matriz de VAFs preparada:\n")
cat("  - Dimensiones:", nrow(vaf_matrix_clean), "x", ncol(vaf_matrix_clean), "\n")
cat("  - Rango de VAFs:", round(min(vaf_matrix_clean, na.rm = TRUE), 6), "a", round(max(vaf_matrix_clean, na.rm = TRUE), 6), "\n")
cat("  - VAFs no-cero:", sum(vaf_matrix_clean > 0), "de", length(vaf_matrix_clean), "(", round(sum(vaf_matrix_clean > 0)/length(vaf_matrix_clean)*100, 2), "%)\n\n")

# 6. CALCULAR Z-SCORES POR SNV
# =============================================================================
cat("6. CALCULANDO Z-SCORES POR SNV\n")
cat("===============================\n")

# Calcular z-scores por fila (SNV)
zscore_matrix <- t(apply(vaf_matrix_clean, 1, function(x) {
  if (sd(x, na.rm = TRUE) == 0) {
    return(rep(0, length(x)))
  } else {
    return(scale(x)[,1])
  }
}))

colnames(zscore_matrix) <- colnames(vaf_matrix_clean)

# Reemplazar NAs en z-scores con 0
zscore_matrix[is.na(zscore_matrix)] <- 0

cat("Matriz de Z-scores preparada:\n")
cat("  - Dimensiones:", nrow(zscore_matrix), "x", ncol(zscore_matrix), "\n")
cat("  - Rango de Z-scores:", round(min(zscore_matrix, na.rm = TRUE), 3), "a", round(max(zscore_matrix, na.rm = TRUE), 3), "\n\n")

# 7. PREPARAR ANOTACIONES DE COLUMNAS
# =============================================================================
cat("7. PREPARANDO ANOTACIONES DE COLUMNAS\n")
cat("=====================================\n")

# Crear anotación de grupos
col_annotation <- data.frame(
  Sample = colnames(vaf_matrix_clean),
  Group = cohorts[colnames(vaf_matrix_clean)],
  stringsAsFactors = FALSE
)

# Colores para los grupos
group_colors <- c("Control" = "#2E86AB", "ALS" = "#A23B72")

# Crear objeto de anotación
column_ha <- HeatmapAnnotation(
  Group = col_annotation$Group,
  col = list(Group = group_colors),
  annotation_name_gp = gpar(fontsize = 10),
  annotation_legend_param = list(
    Group = list(title = "Cohort", title_gp = gpar(fontsize = 12))
  )
)

cat("Anotaciones preparadas:\n")
cat("  - Control:", sum(col_annotation$Group == "Control"), "muestras\n")
cat("  - ALS:", sum(col_annotation$Group == "ALS"), "muestras\n\n")

# 8. CREAR HEATMAP 1: VAFs CON CLUSTERING
# =============================================================================
cat("8. CREANDO HEATMAP 1: VAFs CON CLUSTERING\n")
cat("=========================================\n")

# Definir paleta de colores para VAFs (ajustada al rango real)
max_vaf <- max(vaf_matrix_clean, na.rm = TRUE)
vaf_colors <- colorRamp2(
  c(0, max_vaf * 0.1, max_vaf * 0.3, max_vaf * 0.6, max_vaf),
  c("white", "#FFF2CC", "#FFE599", "#FF9900", "#CC7700")
)

# Crear heatmap de VAFs
heatmap_vaf <- Heatmap(
  vaf_matrix_clean,
  name = "VAF",
  
  # Colores
  col = vaf_colors,
  
  # Clustering
  clustering_distance_rows = "euclidean",
  clustering_method_rows = "ward.D2",
  clustering_distance_columns = "euclidean",
  clustering_method_columns = "ward.D2",
  
  # Mostrar dendrogramas
  show_row_dend = TRUE,
  show_column_dend = TRUE,
  
  # Anotaciones
  top_annotation = column_ha,
  
  # Etiquetas
  show_row_names = TRUE,
  show_column_names = FALSE,
  row_names_gp = gpar(fontsize = 6),
  
  # Título y leyenda
  column_title = "Heatmap de VAFs - Posiciones Significativas (1-6)",
  column_title_gp = gpar(fontsize = 14, fontface = "bold"),
  
  # Configuración de la leyenda
  heatmap_legend_param = list(
    title = "VAF",
    title_gp = gpar(fontsize = 12),
    labels_gp = gpar(fontsize = 10),
    legend_height = unit(4, "cm")
  )
)

# Guardar heatmap de VAFs
pdf("heatmap_vafs_posiciones_significativas.pdf", width = 20, height = 14)
draw(heatmap_vaf, heatmap_legend_side = "right", annotation_legend_side = "right")
dev.off()

cat("Heatmap de VAFs guardado: heatmap_vafs_posiciones_significativas.pdf\n\n")

# 9. CREAR HEATMAP 2: Z-SCORES CON CLUSTERING
# =============================================================================
cat("9. CREANDO HEATMAP 2: Z-SCORES CON CLUSTERING\n")
cat("=============================================\n")

# Definir paleta de colores para Z-scores
max_z <- max(abs(zscore_matrix), na.rm = TRUE)
zscore_colors <- colorRamp2(
  c(-max_z, -max_z*0.5, 0, max_z*0.5, max_z),
  c("#2166AC", "#92C5DE", "white", "#F4A582", "#B2182B")
)

# Crear heatmap de Z-scores
heatmap_zscore <- Heatmap(
  zscore_matrix,
  name = "Z-score",
  
  # Colores
  col = zscore_colors,
  
  # Clustering
  clustering_distance_rows = "euclidean",
  clustering_method_rows = "ward.D2",
  clustering_distance_columns = "euclidean",
  clustering_method_columns = "ward.D2",
  
  # Mostrar dendrogramas
  show_row_dend = TRUE,
  show_column_dend = TRUE,
  
  # Anotaciones
  top_annotation = column_ha,
  
  # Etiquetas
  show_row_names = TRUE,
  show_column_names = FALSE,
  row_names_gp = gpar(fontsize = 6),
  
  # Título y leyenda
  column_title = "Heatmap de Z-scores - Posiciones Significativas (1-6)",
  column_title_gp = gpar(fontsize = 14, fontface = "bold"),
  
  # Configuración de la leyenda
  heatmap_legend_param = list(
    title = "Z-score",
    title_gp = gpar(fontsize = 12),
    labels_gp = gpar(fontsize = 10),
    legend_height = unit(4, "cm")
  )
)

# Guardar heatmap de Z-scores
pdf("heatmap_zscores_posiciones_significativas.pdf", width = 20, height = 14)
draw(heatmap_zscore, heatmap_legend_side = "right", annotation_legend_side = "right")
dev.off()

cat("Heatmap de Z-scores guardado: heatmap_zscores_posiciones_significativas.pdf\n\n")

# 10. ANÁLISIS DE CLUSTERING
# =============================================================================
cat("10. ANÁLISIS DE CLUSTERING\n")
cat("==========================\n")

# Extraer clustering de muestras del heatmap de VAFs
vaf_col_order <- column_order(heatmap_vaf)
vaf_row_order <- row_order(heatmap_vaf)

# Analizar agrupación de muestras
clustered_samples <- colnames(vaf_matrix_clean)[vaf_col_order]
clustered_groups <- cohorts[clustered_samples]

cat("Análisis de clustering de muestras (VAFs):\n")
cat("Orden de clustering (primeras 20 muestras):\n")
for (i in 1:min(20, length(clustered_samples))) {
  cat(sprintf("  %d. %s (%s)\n", i, clustered_samples[i], clustered_groups[i]))
}

# Calcular pureza de clusters
# Dividir en dos clusters principales
mid_point <- ceiling(length(clustered_samples) / 2)
cluster1_groups <- clustered_groups[1:mid_point]
cluster2_groups <- clustered_groups[(mid_point+1):length(clustered_groups)]

cluster1_purity <- max(table(cluster1_groups)) / length(cluster1_groups)
cluster2_purity <- max(table(cluster2_groups)) / length(cluster2_groups)

cat("\nPureza de clusters:\n")
cat("  - Cluster 1:", round(cluster1_purity * 100, 1), "%\n")
cat("  - Cluster 2:", round(cluster2_purity * 100, 1), "%\n\n")

# 11. GUARDAR DATOS DE CLUSTERING
# =============================================================================
cat("11. GUARDANDO DATOS DE CLUSTERING\n")
cat("==================================\n")

# Guardar orden de clustering
clustering_results <- data.frame(
  Sample = clustered_samples,
  Group = clustered_groups,
  Cluster_Order = 1:length(clustered_samples),
  stringsAsFactors = FALSE
)

write.csv(clustering_results, "clustering_results_samples.csv", row.names = FALSE)

# Guardar SNVs ordenados por clustering
clustered_snvs <- rownames(vaf_matrix_clean)[vaf_row_order]
snv_clustering <- data.frame(
  SNV = clustered_snvs,
  Cluster_Order = 1:length(clustered_snvs),
  stringsAsFactors = FALSE
)

write.csv(snv_clustering, "clustering_results_snvs.csv", row.names = FALSE)

cat("Archivos guardados:\n")
cat("  - clustering_results_samples.csv\n")
cat("  - clustering_results_snvs.csv\n")
cat("  - heatmap_vafs_posiciones_significativas.pdf\n")
cat("  - heatmap_zscores_posiciones_significativas.pdf\n\n")

# 12. RESUMEN DE RESULTADOS
# =============================================================================
cat("12. RESUMEN DE RESULTADOS\n")
cat("=========================\n")

cat("DATOS ANALIZADOS:\n")
cat("  - SNVs en posiciones significativas (1-6):", nrow(filtered_snvs), "\n")
cat("  - Muestras analizadas:", ncol(vaf_matrix_clean), "\n")
cat("  - Grupos: Control (", length(control_cols), "), ALS (", length(als_cols), ")\n")
cat("  - Densidad de datos: ", round(sum(vaf_matrix_clean > 0)/length(vaf_matrix_clean)*100, 2), "% VAFs no-cero\n\n")

cat("HEATMAPS GENERADOS:\n")
cat("  1. Heatmap de VAFs con clustering jerárquico\n")
cat("     - Muestra valores absolutos de VAFs\n")
cat("     - Clustering de muestras y SNVs\n")
cat("     - Anotación por cohorte (Control/ALS)\n\n")

cat("  2. Heatmap de Z-scores con clustering jerárquico\n")
cat("     - Muestra diferencias relativas (z-scores)\n")
cat("     - Mismo clustering que VAFs\n")
cat("     - Resalta patrones de desviación\n\n")

cat("CLUSTERING DE MUESTRAS:\n")
cat("  - Pureza Cluster 1:", round(cluster1_purity * 100, 1), "%\n")
cat("  - Pureza Cluster 2:", round(cluster2_purity * 100, 1), "%\n")
cat("  - Interpretación: Valores altos indican buena separación entre grupos\n\n")

cat("=== ANÁLISIS DE HEATMAPS COMPLETADO ===\n")









