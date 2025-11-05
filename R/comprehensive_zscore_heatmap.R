#!/usr/bin/env Rscript

# Script para generar heatmap comprehensivo con clustering jerárquico
# de Z-scores para mutaciones G>T en la región semilla
# miRNAs y Oxidación - Análisis ALS

library(dplyr)
library(readr)
library(stringr)
library(ggplot2)
library(ComplexHeatmap)
library(circlize)
library(reshape2)
library(gridExtra)
library(pheatmap)
library(tibble)
library(tidyr)
library(viridis)
library(RColorBrewer)

cat("🔥 HEATMAP COMPREHENSIVO CON CLUSTERING JERÁRQUICO - Z-SCORES GT SEMILLA\n")
cat("=====================================================================\n\n")

# Cargar datos de análisis Z-score detallado
cat("📂 Cargando datos de análisis Z-score...\n")
zscore_data <- read_tsv("outputs/detailed_zscore_analysis_results.tsv", show_col_types = FALSE)

cat("📊 DATOS CARGADOS:\n")
cat("   - Total SNVs G>T analizados:", nrow(zscore_data), "\n")
cat("   - miRNAs únicos:", length(unique(zscore_data$`miRNA name`)), "\n")
cat("   - Posiciones en región semilla:", paste(sort(unique(zscore_data$position)), collapse = ", "), "\n\n")

# --- 1. PREPARAR MATRIZ DE Z-SCORES ---
cat("🔢 1. PREPARANDO MATRIZ DE Z-SCORES\n")
cat("===================================\n")

# Crear matriz de Z-scores (miRNAs x posiciones)
# Primero limpiar los datos y manejar NAs
zscore_clean <- zscore_data %>%
  select(`miRNA name`, position, zscore) %>%
  filter(!is.na(zscore), !is.infinite(zscore)) %>%  # Remover NAs e infinitos
  pivot_wider(
    names_from = position, 
    values_from = zscore, 
    values_fill = 0  # Rellenar con 0 donde no hay datos
  ) %>%
  as.data.frame() %>%
  column_to_rownames("miRNA name") %>%
  as.matrix()

# Asegurar que la matriz sea numérica
zscore_matrix <- apply(zscore_clean, 2, as.numeric)
rownames(zscore_matrix) <- rownames(zscore_clean)

cat("📈 MATRIZ DE Z-SCORES CREADA:\n")
cat("   - Dimensiones:", nrow(zscore_matrix), "miRNAs x", ncol(zscore_matrix), "posiciones\n")
cat("   - Rango de Z-scores:", round(min(zscore_matrix), 3), "a", round(max(zscore_matrix), 3), "\n\n")

# --- 2. FILTRAR miRNAs SIGNIFICATIVOS ---
cat("🎯 2. FILTRANDO miRNAs SIGNIFICATIVOS\n")
cat("====================================\n")

# Identificar miRNAs con al menos un Z-score significativo
significant_mirnas <- zscore_data %>%
  filter(abs(zscore) > 1.0) %>%  # Moderadamente significativo o mayor
  pull(`miRNA name`) %>%
  unique()

cat("📊 miRNAs CON Z-SCORES SIGNIFICATIVOS (|z| > 1.0):\n")
cat("   - Total miRNAs significativos:", length(significant_mirnas), "\n")
cat("   - Porcentaje del total:", round(length(significant_mirnas) / nrow(zscore_matrix) * 100, 1), "%\n\n")

# Filtrar matriz para miRNAs significativos
if (length(significant_mirnas) > 1) {
  zscore_matrix_filtered <- zscore_matrix[rownames(zscore_matrix) %in% significant_mirnas, ]
  
  cat("📈 MATRIZ FILTRADA:\n")
  cat("   - Dimensiones:", nrow(zscore_matrix_filtered), "miRNAs x", ncol(zscore_matrix_filtered), "posiciones\n")
  cat("   - Rango de Z-scores:", round(min(zscore_matrix_filtered), 3), "a", round(max(zscore_matrix_filtered), 3), "\n\n")
} else {
  cat("⚠️ No hay suficientes miRNAs significativos. Usando todos los miRNAs.\n")
  zscore_matrix_filtered <- zscore_matrix
}

# --- 3. ANOTACIONES DE MUESTRAS ---
cat("🏷️ 3. PREPARANDO ANOTACIONES\n")
cat("============================\n")

# Crear anotaciones por posición
position_annotations <- data.frame(
  position = colnames(zscore_matrix_filtered),
  functional_region = case_when(
    as.numeric(colnames(zscore_matrix_filtered)) %in% c(2, 3) ~ "Critical seed start",
    as.numeric(colnames(zscore_matrix_filtered)) %in% c(4, 5) ~ "Core seed region",
    as.numeric(colnames(zscore_matrix_filtered)) %in% c(6, 7) ~ "Seed end region",
    as.numeric(colnames(zscore_matrix_filtered)) == 8 ~ "Seed boundary",
    TRUE ~ "Other"
  )
)

# Crear anotaciones por miRNA (top miRNAs por significancia)
mirna_annotations <- zscore_data %>%
  filter(!is.na(zscore), !is.infinite(zscore)) %>%  # Limpiar datos
  group_by(`miRNA name`) %>%
  summarise(
    max_abs_zscore = if_else(all(is.na(zscore)), 0, max(abs(zscore), na.rm = TRUE)),
    mean_zscore = if_else(all(is.na(zscore)), 0, mean(zscore, na.rm = TRUE)),
    n_significant_positions = sum(abs(zscore) > 1.0, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(`miRNA name` %in% rownames(zscore_matrix_filtered)) %>%
  mutate(
    significance_level = case_when(
      max_abs_zscore > 2.0 ~ "Highly Significant",
      max_abs_zscore > 1.5 ~ "Significant", 
      max_abs_zscore > 1.0 ~ "Moderately Significant",
      TRUE ~ "Not Significant"
    ),
    direction = if_else(mean_zscore > 0, "ALS Higher", "Control Higher")
  )

cat("📊 ANOTACIONES PREPARADAS:\n")
cat("   - miRNAs con anotaciones:", nrow(mirna_annotations), "\n")
cat("   - Niveles de significancia:", paste(unique(mirna_annotations$significance_level), collapse = ", "), "\n\n")

# --- 4. GENERAR HEATMAP PRINCIPAL ---
cat("🎨 4. GENERANDO HEATMAP PRINCIPAL\n")
cat("================================\n")

# Definir paleta de colores
# Asegurar que los valores sean finitos
zscore_range <- range(zscore_matrix_filtered, finite = TRUE)
col_fun <- colorRamp2(
  c(zscore_range[1], 0, zscore_range[2]), 
  c("#2166AC", "white", "#B2182B")  # Azul-blanco-rojo
)

# Anotaciones de columnas (posiciones)
col_ha <- HeatmapAnnotation(
  "Functional Region" = position_annotations$functional_region,
  col = list("Functional Region" = c(
    "Critical seed start" = "#E31A1C",
    "Core seed region" = "#FF7F00", 
    "Seed end region" = "#6A3D9A",
    "Seed boundary" = "#1F78B4"
  )),
  annotation_name_gp = gpar(fontsize = 10, fontface = "bold")
)

# Anotaciones de filas (miRNAs)
row_ha <- rowAnnotation(
  "Max |Z-score|" = mirna_annotations$max_abs_zscore,
  "Direction" = mirna_annotations$direction,
  col = list(
    "Max |Z-score|" = colorRamp2(c(0, 2), c("white", "red")),
    "Direction" = c("ALS Higher" = "#B2182B", "Control Higher" = "#2166AC")
  ),
  annotation_name_gp = gpar(fontsize = 10, fontface = "bold")
)

# Crear heatmap principal
pdf("outputs/comprehensive_zscore_heatmap_gt_seed.pdf", width = 14, height = 12)
ht_main <- Heatmap(
  zscore_matrix_filtered,
  name = "Z-score",
  col = col_fun,
  
  # Clustering
  cluster_rows = TRUE,
  cluster_columns = TRUE,
  clustering_distance_rows = "euclidean",
  clustering_distance_columns = "euclidean",
  clustering_method_rows = "ward.D2",
  clustering_method_columns = "ward.D2",
  
  # Apariencia
  show_row_names = TRUE,
  show_column_names = TRUE,
  row_names_gp = gpar(fontsize = 8),
  column_names_gp = gpar(fontsize = 12, fontface = "bold"),
  
  # Anotaciones
  top_annotation = col_ha,
  left_annotation = row_ha,
  
  # Títulos
  column_title = "Z-scores de Mutaciones G>T en Región Semilla por Posición",
  column_title_gp = gpar(fontsize = 14, fontface = "bold"),
  row_title = "miRNAs",
  row_title_gp = gpar(fontsize = 14, fontface = "bold"),
  
  # Leyenda
  heatmap_legend_param = list(
    title = "Z-score",
    title_gp = gpar(fontsize = 12, fontface = "bold"),
    labels_gp = gpar(fontsize = 10),
    at = c(min(zscore_matrix_filtered), 0, max(zscore_matrix_filtered)),
    labels = c(round(min(zscore_matrix_filtered), 2), "0", round(max(zscore_matrix_filtered), 2))
  )
)

# Dibujar heatmap
draw(ht_main, heatmap_legend_side = "right", annotation_legend_side = "right")
dev.off()

cat("✅ Heatmap principal guardado en: outputs/comprehensive_zscore_heatmap_gt_seed.pdf\n")

# --- 5. HEATMAP DE miRNAs MÁS SIGNIFICATIVOS ---
cat("🏆 5. HEATMAP DE miRNAs MÁS SIGNIFICATIVOS\n")
cat("==========================================\n")

# Top 20 miRNAs por significancia
top_mirnas <- mirna_annotations %>%
  arrange(desc(max_abs_zscore)) %>%
  head(20) %>%
  pull(`miRNA name`)

if (length(top_mirnas) > 1) {
  zscore_matrix_top <- zscore_matrix_filtered[rownames(zscore_matrix_filtered) %in% top_mirnas, ]
  
  # Anotaciones para top miRNAs
  top_mirna_annotations <- mirna_annotations %>%
    filter(`miRNA name` %in% top_mirnas) %>%
    arrange(match(`miRNA name`, top_mirnas))
  
  # Anotaciones de filas para top miRNAs
  row_ha_top <- rowAnnotation(
    "Max |Z-score|" = top_mirna_annotations$max_abs_zscore,
    "Significance" = top_mirna_annotations$significance_level,
    "Direction" = top_mirna_annotations$direction,
    col = list(
      "Max |Z-score|" = colorRamp2(c(0, 2), c("white", "red")),
      "Significance" = c(
        "Highly Significant" = "#E31A1C",
        "Significant" = "#FF7F00",
        "Moderately Significant" = "#6A3D9A",
        "Not Significant" = "grey"
      ),
      "Direction" = c("ALS Higher" = "#B2182B", "Control Higher" = "#2166AC")
    ),
    annotation_name_gp = gpar(fontsize = 10, fontface = "bold")
  )
  
  # Crear heatmap de top miRNAs
  pdf("outputs/top_mirnas_zscore_heatmap.pdf", width = 12, height = 10)
  ht_top <- Heatmap(
    zscore_matrix_top,
    name = "Z-score",
    col = col_fun,
    
    # Clustering
    cluster_rows = TRUE,
    cluster_columns = TRUE,
    clustering_distance_rows = "euclidean",
    clustering_distance_columns = "euclidean",
    clustering_method_rows = "ward.D2",
    clustering_method_columns = "ward.D2",
    
    # Apariencia
    show_row_names = TRUE,
    show_column_names = TRUE,
    row_names_gp = gpar(fontsize = 10),
    column_names_gp = gpar(fontsize = 12, fontface = "bold"),
    
    # Anotaciones
    top_annotation = col_ha,
    left_annotation = row_ha_top,
    
    # Títulos
    column_title = "Top 20 miRNAs - Z-scores de Mutaciones G>T en Región Semilla",
    column_title_gp = gpar(fontsize = 14, fontface = "bold"),
    row_title = "miRNAs",
    row_title_gp = gpar(fontsize = 14, fontface = "bold"),
    
    # Leyenda
    heatmap_legend_param = list(
      title = "Z-score",
      title_gp = gpar(fontsize = 12, fontface = "bold"),
      labels_gp = gpar(fontsize = 10)
    )
  )
  
  # Dibujar heatmap de top miRNAs
  draw(ht_top, heatmap_legend_side = "right", annotation_legend_side = "right")
  dev.off()
  
  cat("✅ Heatmap de top miRNAs guardado en: outputs/top_mirnas_zscore_heatmap.pdf\n")
}

# --- 6. HEATMAP POR POSICIÓN ESPECÍFICA ---
cat("🎯 6. HEATMAP POR POSICIÓN ESPECÍFICA\n")
cat("====================================\n")

# Crear heatmaps individuales para posiciones más significativas
significant_positions <- zscore_data %>%
  group_by(position) %>%
  summarise(
    max_abs_zscore = max(abs(zscore), na.rm = TRUE),
    n_significant = sum(abs(zscore) > 1.0, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(max_abs_zscore > 1.0) %>%
  arrange(desc(max_abs_zscore))

cat("📊 POSICIONES MÁS SIGNIFICATIVAS:\n")
print(significant_positions)
cat("\n")

# Generar heatmap para cada posición significativa
for (pos in significant_positions$position) {
  cat("🎨 Generando heatmap para posición", pos, "...\n")
  
  # Filtrar datos para esta posición
  pos_data <- zscore_data %>%
    filter(position == pos) %>%
    arrange(desc(abs(zscore))) %>%
    head(15)  # Top 15 miRNAs para esta posición
  
  if (nrow(pos_data) > 1) {
    # Crear matriz para esta posición
    pos_matrix <- matrix(
      pos_data$zscore, 
      nrow = 1, 
      dimnames = list("Z-score", pos_data$`miRNA name`)
    )
    
    # Verificar que no hay NAs o infinitos en la matriz
    if (any(is.na(pos_matrix)) || any(is.infinite(pos_matrix))) {
      cat("⚠️ Saltando posición", pos, "debido a valores NA o infinitos\n")
      next
    }
    
    # Anotaciones para miRNAs de esta posición
    pos_mirna_annotations <- pos_data %>%
      mutate(
        significance = case_when(
          abs(zscore) > 2.0 ~ "Highly Significant",
          abs(zscore) > 1.5 ~ "Significant",
          abs(zscore) > 1.0 ~ "Moderately Significant",
          TRUE ~ "Not Significant"
        ),
        direction = if_else(zscore > 0, "ALS Higher", "Control Higher")
      )
    
    # Anotaciones de columnas
    col_ha_pos <- HeatmapAnnotation(
      "Significance" = pos_mirna_annotations$significance,
      "Direction" = pos_mirna_annotations$direction,
      col = list(
        "Significance" = c(
          "Highly Significant" = "#E31A1C",
          "Significant" = "#FF7F00",
          "Moderately Significant" = "#6A3D9A",
          "Not Significant" = "grey"
        ),
        "Direction" = c("ALS Higher" = "#B2182B", "Control Higher" = "#2166AC")
      ),
      annotation_name_gp = gpar(fontsize = 10, fontface = "bold")
    )
    
    # Crear heatmap para esta posición
    pdf(sprintf("outputs/position_%d_zscore_heatmap.pdf", pos), width = 12, height = 4)
    ht_pos <- Heatmap(
      pos_matrix,
      name = "Z-score",
      col = col_fun,
      
      # Clustering
      cluster_rows = FALSE,
      cluster_columns = if(ncol(pos_matrix) > 1) TRUE else FALSE,
      clustering_distance_columns = "euclidean",
      clustering_method_columns = "ward.D2",
      
      # Apariencia
      show_row_names = TRUE,
      show_column_names = TRUE,
      row_names_gp = gpar(fontsize = 12, fontface = "bold"),
      column_names_gp = gpar(fontsize = 8),
      
      # Anotaciones
      top_annotation = col_ha_pos,
      
      # Títulos
      column_title = sprintf("Z-scores de Mutaciones G>T en Posición %d - Top 15 miRNAs", pos),
      column_title_gp = gpar(fontsize = 14, fontface = "bold"),
      row_title = "Posición",
      row_title_gp = gpar(fontsize = 14, fontface = "bold"),
      
      # Leyenda
      heatmap_legend_param = list(
        title = "Z-score",
        title_gp = gpar(fontsize = 12, fontface = "bold"),
        labels_gp = gpar(fontsize = 10)
      )
    )
    
    # Dibujar heatmap para esta posición
    draw(ht_pos, heatmap_legend_side = "right", annotation_legend_side = "right")
    dev.off()
    
    cat("✅ Heatmap para posición", pos, "guardado en: outputs/position_", pos, "_zscore_heatmap.pdf\n")
  }
}

# --- 7. ANÁLISIS DE CLUSTERING ---
cat("🔍 7. ANÁLISIS DE CLUSTERING\n")
cat("============================\n")

# Realizar clustering jerárquico
row_cluster <- hclust(dist(zscore_matrix_filtered), method = "ward.D2")
col_cluster <- hclust(dist(t(zscore_matrix_filtered)), method = "ward.D2")

# Identificar clusters de miRNAs
n_clusters <- 4
row_clusters <- cutree(row_cluster, k = n_clusters)

# Crear dataframe con información de clusters
cluster_info <- data.frame(
  miRNA = rownames(zscore_matrix_filtered),
  cluster = row_clusters,
  stringsAsFactors = FALSE
) %>%
  left_join(mirna_annotations, by = c("miRNA" = "miRNA name")) %>%
  arrange(cluster, desc(max_abs_zscore))

cat("📊 INFORMACIÓN DE CLUSTERS:\n")
cluster_summary <- cluster_info %>%
  group_by(cluster) %>%
  summarise(
    n_mirnas = n(),
    mean_max_zscore = mean(max_abs_zscore, na.rm = TRUE),
    mean_mean_zscore = mean(mean_zscore, na.rm = TRUE),
    als_higher = sum(direction == "ALS Higher", na.rm = TRUE),
    control_higher = sum(direction == "Control Higher", na.rm = TRUE),
    .groups = "drop"
  )

print(cluster_summary)
cat("\n")

# --- 8. GUARDAR RESULTADOS ---
cat("💾 8. GUARDANDO RESULTADOS\n")
cat("==========================\n")

# Guardar matriz de Z-scores
write_tsv(
  as.data.frame(zscore_matrix_filtered) %>% rownames_to_column("miRNA"),
  "outputs/comprehensive_zscore_matrix.tsv"
)
cat("✅ Matriz de Z-scores guardada en: outputs/comprehensive_zscore_matrix.tsv\n")

# Guardar información de clusters
write_tsv(cluster_info, "outputs/mirna_cluster_analysis.tsv")
cat("✅ Análisis de clusters guardado en: outputs/mirna_cluster_analysis.tsv\n")

# Guardar anotaciones
write_tsv(mirna_annotations, "outputs/mirna_annotations_comprehensive.tsv")
cat("✅ Anotaciones de miRNAs guardadas en: outputs/mirna_annotations_comprehensive.tsv\n")

# --- 9. RESUMEN FINAL ---
cat("\n🎯 RESUMEN FINAL - HEATMAP COMPREHENSIVO\n")
cat("========================================\n")
cat("📊 Total miRNAs analizados:", nrow(zscore_matrix), "\n")
cat("🎯 miRNAs significativos (|z| > 1.0):", nrow(zscore_matrix_filtered), "\n")
cat("🏆 Top miRNAs en heatmap específico:", length(top_mirnas), "\n")
cat("🎨 Heatmaps generados:", 2 + nrow(significant_positions), "\n")
cat("🔍 Clusters identificados:", n_clusters, "\n")
cat("💾 Archivos de datos: 3\n\n")

cat("📈 RANGO DE Z-SCORES:\n")
cat("   - Mínimo:", round(min(zscore_matrix_filtered), 3), "\n")
cat("   - Máximo:", round(max(zscore_matrix_filtered), 3), "\n")
cat("   - Media:", round(mean(zscore_matrix_filtered), 3), "\n")
cat("   - Mediana:", round(median(zscore_matrix_filtered), 3), "\n\n")

cat("🏆 TOP 5 miRNAs MÁS SIGNIFICATIVOS:\n")
top_5 <- head(mirna_annotations %>% arrange(desc(max_abs_zscore)), 5)
for (i in 1:nrow(top_5)) {
  cat(sprintf("   %d. %s: |Z-score| = %.3f, %s\n", 
              i, top_5$`miRNA name`[i], top_5$max_abs_zscore[i], top_5$direction[i]))
}

cat("\n✅ HEATMAP COMPREHENSIVO CON CLUSTERING JERÁRQUICO COMPLETADO\n")
cat("=============================================================\n\n")
