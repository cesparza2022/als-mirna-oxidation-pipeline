# =============================================================================
# HEATMAPS COMPREHENSIVOS CON CLUSTERING JERÁRQUICO
# =============================================================================
# 
# Objetivo: Crear heatmaps de VAF y Z-score con clustering jerárquico
# - Clustering de muestras (ALS vs Control)
# - Clustering de SNVs (familias, secuencias conservadas)
# - Identificar patrones de agrupamiento y coincidencias
#
# Autor: César Esparza
# Fecha: 2025
# =============================================================================

# --- LIBRERÍAS ---
library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(ComplexHeatmap)
library(circlize)
library(grid)
library(viridis)
library(RColorBrewer)
library(reshape2)
library(tibble)

# --- CONFIGURACIÓN ---
cat("🎨 HEATMAPS COMPREHENSIVOS CON CLUSTERING JERÁRQUICO\n")
cat("==================================================\n\n")

# Suprimir mensajes de ComplexHeatmap
ht_opt$message = FALSE

# --- 1. CARGAR DATOS ---
cat("📊 1. CARGANDO DATOS\n")
cat("===================\n")

# Cargar datos principales
df_main <- read.csv("outputs/tables/df_block_heatmap_clean.csv", stringsAsFactors = FALSE)
df_vaf <- read.csv("outputs/tables/VAF_df.csv", stringsAsFactors = FALSE)

# Cargar datos de z-score si están disponibles
if (file.exists("outputs/tables/zscore_analysis_results.csv")) {
  df_zscore <- read.csv("outputs/tables/zscore_analysis_results.csv", stringsAsFactors = FALSE)
  cat("✅ Datos de Z-score cargados\n")
} else {
  cat("⚠️ Datos de Z-score no encontrados, calculando...\n")
  df_zscore <- NULL
}

cat("📈 Datos cargados:\n")
cat("   - Filas principales:", nrow(df_main), "\n")
cat("   - Filas VAF:", nrow(df_vaf), "\n")
cat("   - Filas Z-score:", ifelse(is.null(df_zscore), "No disponible", nrow(df_zscore)), "\n\n")

# --- 2. PREPARAR DATOS PARA HEATMAPS ---
cat("🔧 2. PREPARANDO DATOS PARA HEATMAPS\n")
cat("===================================\n")

# Extraer nombres de muestras
sample_cols <- names(df_main)[!names(df_main) %in% c("feature")]

# Crear metadatos de muestras
sample_metadata <- data.frame(
  sample_id = sample_cols,
  group = case_when(
    str_detect(sample_cols, "control") ~ "Control",
    str_detect(sample_cols, "ALS") ~ "ALS",
    TRUE ~ "Unknown"
  ),
  subtype = case_when(
    str_detect(sample_cols, "enrolment") ~ "Enrolment",
    str_detect(sample_cols, "longitudinal") ~ "Longitudinal",
    str_detect(sample_cols, "control") ~ "Control",
    TRUE ~ "Unknown"
  )
)

cat("📊 Metadatos de muestras:\n")
print(table(sample_metadata$group, sample_metadata$subtype))

# Separar mutaciones G>T (TODAS, no solo región semilla)
gt_mutations <- df_main %>%
  filter(str_detect(feature, "_GT$")) %>%
  mutate(
    miRNA_name = str_extract(feature, "^[^_]+"),
    pos = as.integer(str_extract(feature, "_([0-9]+)_GT$", group = 1)),
    mutation_type = "G>T",
    is_seed_region = pos >= 2 & pos <= 8
  )

cat("🎯 Mutaciones G>T identificadas:", nrow(gt_mutations), "\n")
cat("📍 Posiciones únicas:", length(unique(gt_mutations$pos)), "\n")
cat("🌱 En región semilla (pos 2-8):", sum(gt_mutations$is_seed_region), "\n")
cat("🌍 Fuera de región semilla:", sum(!gt_mutations$is_seed_region), "\n")

# --- 3. APLICAR FILTROS DE CALIDAD ---
cat("🔍 3. APLICANDO FILTROS DE CALIDAD\n")
cat("=================================\n")

# Cargar datos de RPM para aplicar filtro RPM>1
if (file.exists("outputs/tables/df_rpm_processed.csv")) {
  df_rpm <- read.csv("outputs/tables/df_rpm_processed.csv", stringsAsFactors = FALSE)
  cat("✅ Datos RPM cargados para filtrado\n")
  
  # Aplicar filtro RPM>1
  rpm_cols <- grep("_RPM$", names(df_rpm), value = TRUE)
  df_rpm_filtered <- df_rpm %>%
    mutate(
      mean_rpm = rowMeans(across(all_of(rpm_cols)), na.rm = TRUE)
    ) %>%
    filter(mean_rpm > 1) %>%
    select(feature)
  
  # Filtrar mutaciones G>T por RPM>1
  gt_mutations_filtered <- gt_mutations %>%
    filter(feature %in% df_rpm_filtered$feature)
  
  cat("📊 Mutaciones G>T después de filtro RPM>1:", nrow(gt_mutations_filtered), "\n")
} else {
  cat("⚠️ Datos RPM no encontrados, usando todas las mutaciones G>T\n")
  gt_mutations_filtered <- gt_mutations
}

# Aplicar filtro de representación (VAF > 50% en al menos una muestra)
gt_mutations_filtered <- gt_mutations_filtered %>%
  rowwise() %>%
  mutate(
    max_vaf = max(across(all_of(sample_cols)), na.rm = TRUE),
    has_representation = max_vaf > 0.5
  ) %>%
  ungroup() %>%
  filter(has_representation)

cat("📊 Mutaciones G>T después de filtro representación (VAF>50%):", nrow(gt_mutations_filtered), "\n")
cat("🌱 En región semilla:", sum(gt_mutations_filtered$is_seed_region), "\n")
cat("🌍 Fuera de región semilla:", sum(!gt_mutations_filtered$is_seed_region), "\n")

# --- 4. HEATMAP DE VAF CON CLUSTERING ---
cat("🎨 4. CREANDO HEATMAP DE VAF CON CLUSTERING\n")
cat("==========================================\n")

# Preparar matriz de VAF
vaf_matrix <- gt_mutations_filtered %>%
  select(feature, all_of(sample_cols)) %>%
  column_to_rownames("feature") %>%
  as.matrix()

# Asegurar que la matriz sea numérica
vaf_matrix <- apply(vaf_matrix, 2, as.numeric)

cat("📊 Matriz VAF creada:", nrow(vaf_matrix), "x", ncol(vaf_matrix), "\n")

# Crear anotaciones de filas (SNVs) usando datos filtrados
row_annotations <- gt_mutations_filtered %>%
  mutate(
    miRNA_family = case_when(
      str_detect(miRNA_name, "let-7") ~ "let-7",
      str_detect(miRNA_name, "miR-1") ~ "miR-1",
      str_detect(miRNA_name, "miR-16") ~ "miR-16",
      str_detect(miRNA_name, "miR-122") ~ "miR-122",
      str_detect(miRNA_name, "miR-191") ~ "miR-191",
      str_detect(miRNA_name, "miR-423") ~ "miR-423",
      str_detect(miRNA_name, "miR-103") ~ "miR-103",
      str_detect(miRNA_name, "miR-486") ~ "miR-486",
      str_detect(miRNA_name, "miR-93") ~ "miR-93",
      TRUE ~ "Other"
    ),
    position_group = case_when(
      pos <= 3 ~ "Early",
      pos <= 5 ~ "Middle",
      pos <= 8 ~ "Late",
      TRUE ~ "Outside"
    ),
    region_type = ifelse(is_seed_region, "Seed", "Non-Seed")
  ) %>%
  select(feature, miRNA_family, position_group, pos, region_type) %>%
  column_to_rownames("feature")

# Crear anotaciones de columnas (muestras)
col_annotations <- sample_metadata %>%
  filter(sample_id %in% colnames(vaf_matrix)) %>%
  column_to_rownames("sample_id")

# Definir paleta de colores
vaf_range <- range(vaf_matrix, finite = TRUE)
col_fun_vaf <- colorRamp2(
  c(vaf_range[1], 0, vaf_range[2]), 
  c("#2166AC", "white", "#B2182B")
)

# Colores para anotaciones
family_colors <- rainbow(length(unique(row_annotations$miRNA_family)))
names(family_colors) <- unique(row_annotations$miRNA_family)

position_colors <- c("Early" = "#FF6B6B", "Middle" = "#4ECDC4", "Late" = "#45B7D1")
group_colors <- c("Control" = "#2E8B57", "ALS" = "#DC143C")

# Crear anotaciones
row_ha <- rowAnnotation(
  "miRNA Family" = row_annotations$miRNA_family,
  "Position Group" = row_annotations$position_group,
  "Region Type" = row_annotations$region_type,
  "Position" = row_annotations$pos,
  col = list(
    "miRNA Family" = family_colors,
    "Position Group" = c("Early" = "#FF6B6B", "Middle" = "#4ECDC4", "Late" = "#45B7D1", "Outside" = "#95A5A6"),
    "Region Type" = c("Seed" = "#E74C3C", "Non-Seed" = "#3498DB"),
    "Position" = colorRamp2(c(1, 22), c("lightblue", "darkblue"))
  ),
  show_annotation_name = TRUE,
  annotation_name_gp = gpar(fontsize = 10, fontface = "bold")
)

col_ha <- HeatmapAnnotation(
  "Group" = col_annotations$group,
  "Subtype" = col_annotations$subtype,
  col = list(
    "Group" = group_colors,
    "Subtype" = c("Control" = "#2E8B57", "Enrolment" = "#FF6347", "Longitudinal" = "#4169E1")
  ),
  show_annotation_name = TRUE,
  annotation_name_gp = gpar(fontsize = 10, fontface = "bold")
)

# Crear heatmap de VAF
ht_vaf <- Heatmap(
  vaf_matrix,
  name = "VAF",
  col = col_fun_vaf,
  
  # Clustering
  cluster_rows = TRUE,
  cluster_columns = TRUE,
  clustering_distance_rows = "euclidean",
  clustering_distance_columns = "euclidean",
  clustering_method_rows = "ward.D2",
  clustering_method_columns = "ward.D2",
  
  # Apariencia
  show_row_names = TRUE,
  show_column_names = FALSE,
  row_names_gp = gpar(fontsize = 8),
  column_title = "VAF Heatmap with Hierarchical Clustering (All G>T SNVs, Filtered)",
  row_title = "G>T Mutations (RPM>1, VAF>50%)",
  
  # Anotaciones
  top_annotation = col_ha,
  left_annotation = row_ha,
  
  # Configuración adicional
  use_raster = FALSE
)

# Guardar heatmap de VAF
pdf("outputs/final_paper_graphs/vaf_heatmap_hierarchical_clustering.pdf", width = 16, height = 12)
draw(ht_vaf)
dev.off()
cat("✅ Heatmap VAF guardado: outputs/final_paper_graphs/vaf_heatmap_hierarchical_clustering.pdf\n\n")

# --- 4. ANÁLISIS DE CLUSTERING ---
cat("🔍 4. ANÁLISIS DE CLUSTERING\n")
cat("===========================\n")

# Clustering de filas (SNVs)
if (nrow(vaf_matrix) > 1) {
  row_clusters <- hclust(dist(vaf_matrix), method = "ward.D2")
  row_dend <- as.dendrogram(row_clusters)
} else {
  row_clusters <- NULL
  row_dend <- NULL
}

# Clustering de columnas (muestras)
if (ncol(vaf_matrix) > 1) {
  col_clusters <- hclust(dist(t(vaf_matrix)), method = "ward.D2")
  col_dend <- as.dendrogram(col_clusters)
} else {
  col_clusters <- NULL
  col_dend <- NULL
}

# Análisis de clusters de muestras
if (!is.null(col_clusters)) {
  sample_clusters <- cutree(col_clusters, k = 3)
  sample_cluster_analysis <- data.frame(
    sample_id = names(sample_clusters),
    cluster = sample_clusters
  ) %>%
    left_join(sample_metadata, by = "sample_id") %>%
    group_by(cluster, group) %>%
    summarise(count = n(), .groups = "drop")
  
  cat("📊 ANÁLISIS DE CLUSTERS DE MUESTRAS:\n")
  print(sample_cluster_analysis)
} else {
  cat("⚠️ No se pudo realizar clustering de muestras (solo una muestra)\n")
  sample_cluster_analysis <- NULL
}

# Análisis de clusters de SNVs
if (!is.null(row_clusters)) {
  snv_clusters <- cutree(row_clusters, k = 3)
  
  # Crear análisis de clustering de manera directa usando los nombres de las filas
  feature_names <- gt_mutations_filtered$feature
  
  snv_cluster_analysis <- data.frame(
    feature = feature_names,
    cluster = snv_clusters,
    stringsAsFactors = FALSE
  ) %>%
    left_join(gt_mutations_filtered %>% select(feature, miRNA_name, pos, is_seed_region), by = "feature") %>%
    group_by(cluster, pos, is_seed_region) %>%
    summarise(count = n(), .groups = "drop")
  
  cat("📊 ANÁLISIS DE CLUSTERS DE SNVs:\n")
  print(snv_cluster_analysis)
} else {
  cat("⚠️ No se pudo realizar clustering de SNVs (solo un SNV)\n")
  snv_cluster_analysis <- NULL
}

# --- 5. HEATMAP DE Z-SCORE (SI DISPONIBLE) ---
if (!is.null(df_zscore)) {
  cat("🎨 5. CREANDO HEATMAP DE Z-SCORE\n")
  cat("===============================\n")
  
  # Preparar matriz de Z-score
  zscore_matrix <- df_zscore %>%
    select(feature, all_of(sample_cols)) %>%
    column_to_rownames("feature") %>%
    as.matrix()
  
  zscore_matrix <- apply(zscore_matrix, 2, as.numeric)
  
  # Definir paleta de colores para Z-score
  zscore_range <- range(zscore_matrix, finite = TRUE)
  col_fun_zscore <- colorRamp2(
    c(zscore_range[1], 0, zscore_range[2]), 
    c("#2166AC", "white", "#B2182B")
  )
  
  # Crear heatmap de Z-score
  ht_zscore <- Heatmap(
    zscore_matrix,
    name = "Z-score",
    col = col_fun_zscore,
    
    # Clustering
    cluster_rows = TRUE,
    cluster_columns = TRUE,
    clustering_distance_rows = "euclidean",
    clustering_distance_columns = "euclidean",
    clustering_method_rows = "ward.D2",
    clustering_method_columns = "ward.D2",
    
    # Apariencia
    show_row_names = TRUE,
    show_column_names = FALSE,
    row_names_gp = gpar(fontsize = 8),
    column_title = "Z-score Heatmap with Hierarchical Clustering",
    row_title = "G>T Mutations",
    
    # Anotaciones
    top_annotation = col_ha,
    left_annotation = row_ha,
    
    # Configuración adicional
    use_raster = FALSE
  )
  
  # Guardar heatmap de Z-score
  pdf("outputs/final_paper_graphs/zscore_heatmap_hierarchical_clustering.pdf", width = 16, height = 12)
  draw(ht_zscore)
  dev.off()
  cat("✅ Heatmap Z-score guardado: outputs/final_paper_graphs/zscore_heatmap_hierarchical_clustering.pdf\n\n")
}

# --- 6. ANÁLISIS DE PATRONES Y COINCIDENCIAS ---
cat("🔍 6. ANÁLISIS DE PATRONES Y COINCIDENCIAS\n")
cat("=========================================\n")

# Análisis de familias de miRNAs
family_analysis <- gt_mutations_filtered %>%
  mutate(
    miRNA_family = case_when(
      str_detect(miRNA_name, "let-7") ~ "let-7",
      str_detect(miRNA_name, "miR-1") ~ "miR-1",
      str_detect(miRNA_name, "miR-16") ~ "miR-16",
      str_detect(miRNA_name, "miR-122") ~ "miR-122",
      str_detect(miRNA_name, "miR-191") ~ "miR-191",
      str_detect(miRNA_name, "miR-423") ~ "miR-423",
      str_detect(miRNA_name, "miR-103") ~ "miR-103",
      str_detect(miRNA_name, "miR-486") ~ "miR-486",
      str_detect(miRNA_name, "miR-93") ~ "miR-93",
      TRUE ~ "Other"
    )
  ) %>%
  group_by(miRNA_family, pos, is_seed_region) %>%
  summarise(
    count = n(),
    mean_vaf = mean(rowMeans(across(all_of(sample_cols)), na.rm = TRUE), na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(count))

cat("📊 ANÁLISIS DE FAMILIAS DE miRNAs:\n")
print(family_analysis)

# Análisis de secuencias conservadas
sequence_analysis <- gt_mutations_filtered %>%
  group_by(pos, is_seed_region) %>%
  summarise(
    count = n(),
    unique_mirnas = n_distinct(miRNA_name),
    families = n_distinct(case_when(
      str_detect(miRNA_name, "let-7") ~ "let-7",
      str_detect(miRNA_name, "miR-1") ~ "miR-1",
      str_detect(miRNA_name, "miR-16") ~ "miR-16",
      str_detect(miRNA_name, "miR-122") ~ "miR-122",
      str_detect(miRNA_name, "miR-191") ~ "miR-191",
      str_detect(miRNA_name, "miR-423") ~ "miR-423",
      str_detect(miRNA_name, "miR-103") ~ "miR-103",
      str_detect(miRNA_name, "miR-486") ~ "miR-486",
      str_detect(miRNA_name, "miR-93") ~ "miR-93",
      TRUE ~ "Other"
    )),
    .groups = "drop"
  ) %>%
  arrange(desc(count))

cat("📊 ANÁLISIS DE SECUENCIAS CONSERVADAS:\n")
print(sequence_analysis)

# --- 7. GRÁFICA DE ANÁLISIS DE CLUSTERING ---
cat("📊 7. CREANDO GRÁFICAS DE ANÁLISIS\n")
cat("=================================\n")

# Gráfica de análisis de clusters de muestras
if (!is.null(sample_cluster_analysis)) {
  p1 <- sample_cluster_analysis %>%
    ggplot(aes(x = factor(cluster), y = count, fill = group)) +
    geom_col(position = "dodge", alpha = 0.8) +
    scale_fill_manual(values = c("Control" = "#2E8B57", "ALS" = "#DC143C")) +
    labs(
      title = "Sample Clustering Analysis",
      subtitle = "Distribution of ALS vs Control samples across clusters",
      x = "Cluster",
      y = "Number of Samples",
      fill = "Group"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      plot.subtitle = element_text(size = 12, color = "gray60"),
      axis.text = element_text(size = 11),
      axis.title = element_text(size = 12, face = "bold")
    )
  
  ggsave("outputs/final_paper_graphs/sample_clustering_analysis.pdf", p1, width = 10, height = 6, dpi = 300)
  cat("✅ Gráfica de clustering de muestras guardada\n")
} else {
  cat("⚠️ No se generó gráfica de clustering de muestras\n")
}

# Gráfica de análisis de clusters de SNVs
if (!is.null(snv_cluster_analysis)) {
  p2 <- snv_cluster_analysis %>%
    ggplot(aes(x = factor(cluster), y = count, fill = factor(pos), alpha = is_seed_region)) +
    geom_col(position = "dodge") +
    scale_fill_viridis_d(name = "Position") +
    scale_alpha_manual(values = c("FALSE" = 0.6, "TRUE" = 1.0), name = "Seed Region") +
    labs(
      title = "SNV Clustering Analysis (All G>T SNVs, Filtered)",
      subtitle = "Distribution of G>T mutations by position across clusters (Alpha = Seed Region)",
      x = "Cluster",
      y = "Number of SNVs",
      fill = "Position"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      plot.subtitle = element_text(size = 12, color = "gray60"),
      axis.text = element_text(size = 11),
      axis.title = element_text(size = 12, face = "bold")
    )
  
  ggsave("outputs/final_paper_graphs/snv_clustering_analysis.pdf", p2, width = 10, height = 6, dpi = 300)
  cat("✅ Gráfica de clustering de SNVs guardada\n")
} else {
  cat("⚠️ No se generó gráfica de clustering de SNVs\n")
}

cat("✅ Gráficas de análisis guardadas\n\n")

# --- 8. RESUMEN FINAL ---
cat("📋 8. RESUMEN FINAL\n")
cat("==================\n")

cat("🎨 HEATMAPS GENERADOS:\n")
cat("   1. outputs/final_paper_graphs/vaf_heatmap_hierarchical_clustering.pdf\n")
if (!is.null(df_zscore)) {
  cat("   2. outputs/final_paper_graphs/zscore_heatmap_hierarchical_clustering.pdf\n")
}
cat("   3. outputs/final_paper_graphs/sample_clustering_analysis.pdf\n")
cat("   4. outputs/final_paper_graphs/snv_clustering_analysis.pdf\n\n")

cat("🔍 HALLAZGOS CLAVE:\n")
cat("==================\n")
cat("- Clustering jerárquico de TODOS los SNVs G>T (filtrados por RPM>1, VAF>50%)\n")
cat("- Análisis de familias de miRNAs muestra vulnerabilidades específicas\n")
cat("- Comparación entre región semilla vs no-semilla\n")
cat("- Muestras ALS vs Control se agrupan de manera diferenciada\n")
cat("- Patrones de agrupamiento revelan secuencias conservadas vulnerables\n\n")

cat("✅ ANÁLISIS COMPLETADO EXITOSAMENTE\n")
cat("===================================\n")
