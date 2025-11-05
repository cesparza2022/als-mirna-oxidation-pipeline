# --- LIBRERÍAS ---
library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(reshape2)
library(stats) # Para p.adjust
library(ComplexHeatmap)
library(circlize)
library(viridis)
library(RColorBrewer)

# --- CONFIGURACIÓN ---
cat("🔬 ANÁLISIS DE CLUSTERING DE PATRONES DE OXIDACIÓN\n")
cat("==================================================\n\n")

# --- 1. CARGANDO DATOS PROCESADOS ---
cat("📊 1. CARGANDO DATOS PROCESADOS\n")
cat("===============================\n")

processed_data_path <- "final_analysis/processed_data/processed_snvs_gt.csv"
df_processed <- read.csv(processed_data_path, stringsAsFactors = FALSE)

# Cargar métricas globales
global_metrics <- read.csv("final_analysis/tables/global_metrics.csv", stringsAsFactors = FALSE)

# Cargar metadatos de muestras
sample_metadata <- read.csv("final_analysis/tables/sample_metadata.csv", stringsAsFactors = FALSE)

cat(paste0("   - SNVs procesados: ", nrow(df_processed), "\n"))
cat(paste0("   - miRNAs únicos: ", length(unique(df_processed$miRNA_name)), "\n"))
cat(paste0("   - Muestras: ", nrow(global_metrics), "\n\n"))

# --- 2. PREPARANDO DATOS CON POSICIONES ---
cat("🔍 2. PREPARANDO DATOS CON POSICIONES\n")
cat("=====================================\n")

df_with_positions <- df_processed %>%
  filter(!is.na(pos), !is.na(mutation_type)) %>%
  rename(position = pos) %>%
  mutate(
    region = ifelse(position >= 2 & position <= 8, "Seed", "Non-seed"),
    region_detailed = case_when(
      position >= 2 & position <= 8 ~ "Seed region",
      position >= 1 & position <= 1 ~ "5' end",
      position >= 9 & position <= 12 ~ "Central region",
      position >= 13 & position <= 16 ~ "3' region",
      position >= 17 & position <= 23 ~ "3' end",
      TRUE ~ "Unknown"
    )
  )

cat(paste0("   - SNVs con posiciones: ", nrow(df_with_positions), "\n"))
cat(paste0("   - miRNAs únicos: ", length(unique(df_with_positions$miRNA_name)), "\n"))
cat(paste0("   - Posiciones únicas: ", length(unique(df_with_positions$position)), "\n\n"))

# --- 3. CALCULANDO VAFs POR miRNA Y MUESTRA ---
cat("🧮 3. CALCULANDO VAFs POR miRNA Y MUESTRA\n")
cat("=========================================\n")

# Cargar las columnas originales para el cálculo de VAF
df_original_cols <- read.csv("results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt", sep="\t", stringsAsFactors = FALSE)
total_cols_original <- names(df_original_cols)[grepl('..PM.1MM.2MM.', names(df_original_cols), fixed=TRUE)]
count_cols_original <- names(df_original_cols)[!grepl('..PM.1MM.2MM.', names(df_original_cols), fixed=TRUE) & !names(df_original_cols) %in% c('miRNA.name', 'pos.mut')]

sample_names_in_data <- names(df_with_positions)[!names(df_with_positions) %in% c("miRNA_name", "pos", "mutation_type", "position", "region", "region_detailed")]
count_sample_cols_processed <- intersect(sample_names_in_data, gsub("..PM.1MM.2MM.", "", count_cols_original, fixed=TRUE))
total_sample_cols_processed <- intersect(sample_names_in_data, total_cols_original)

vaf_by_mirna <- data.frame()

for (i in 1:length(count_sample_cols_processed)) {
  sample_count_col <- count_sample_cols_processed[i]
  sample_total_col <- total_sample_cols_processed[i]

  if (sample_count_col %in% names(df_with_positions) && sample_total_col %in% names(df_with_positions)) {
    temp_df <- df_with_positions %>%
      select(miRNA_name, position, region, region_detailed, !!sym(sample_count_col), !!sym(sample_total_col)) %>%
      mutate(
        sample = sample_count_col,
        snv_count = .data[[sample_count_col]],
        total_mirna_count = .data[[sample_total_col]],
        vaf = ifelse(total_mirna_count > 0, snv_count / total_mirna_count, 0)
      ) %>%
      select(miRNA_name, position, region, region_detailed, sample, snv_count, total_mirna_count, vaf)
    vaf_by_mirna <- bind_rows(vaf_by_mirna, temp_df)
  }
}

# Reemplazar VAFs > 0.5 con NA
vaf_by_mirna <- vaf_by_mirna %>%
  mutate(vaf = ifelse(vaf > 0.5, NA, vaf))

# Agregar metadatos de cohorte
vaf_by_mirna <- vaf_by_mirna %>%
  left_join(sample_metadata, by = "sample") %>%
  filter(!is.na(cohort))

cat(paste0("   - VAFs calculados: ", nrow(vaf_by_mirna), "\n"))
cat(paste0("   - VAFs válidos (>0): ", sum(vaf_by_mirna$vaf > 0, na.rm = TRUE), "\n"))
cat(paste0("   - VAFs > 0.5 (convertidos a NA): ", sum(vaf_by_mirna$vaf > 0.5, na.rm = TRUE), "\n\n"))

# --- 4. ANÁLISIS DE CLUSTERING POR MUESTRAS ---
cat("🔍 4. ANÁLISIS DE CLUSTERING POR MUESTRAS\n")
cat("=========================================\n")

# Crear matriz de VAF por muestra y miRNA
vaf_matrix_samples_df <- vaf_by_mirna %>%
  group_by(sample, miRNA_name) %>%
  summarise(mean_vaf = mean(vaf, na.rm = TRUE), .groups = 'drop') %>%
  pivot_wider(names_from = miRNA_name, values_from = mean_vaf, names_prefix = "mirna_")

# Convertir a matriz y asignar nombres de filas
vaf_matrix_samples <- as.matrix(vaf_matrix_samples_df[, -1])
rownames(vaf_matrix_samples) <- vaf_matrix_samples_df$sample

# Reemplazar NA con 0 para clustering
vaf_matrix_samples[is.na(vaf_matrix_samples)] <- 0

# Filtrar miRNAs con muy poca variación
vaf_variance <- apply(vaf_matrix_samples, 2, var, na.rm = TRUE)
vaf_matrix_samples_filtered <- vaf_matrix_samples[, vaf_variance > quantile(vaf_variance, 0.5, na.rm = TRUE)]

cat(paste0("   - Matriz de VAF: ", nrow(vaf_matrix_samples), " muestras x ", ncol(vaf_matrix_samples), " miRNAs\n"))
cat(paste0("   - Matriz filtrada: ", nrow(vaf_matrix_samples_filtered), " muestras x ", ncol(vaf_matrix_samples_filtered), " miRNAs\n\n"))

# --- 5. CLUSTERING JERÁRQUICO DE MUESTRAS ---
cat("🌳 5. CLUSTERING JERÁRQUICO DE MUESTRAS\n")
cat("=======================================\n")

# Calcular distancia y clustering
dist_samples <- dist(vaf_matrix_samples_filtered, method = "euclidean")
hc_samples <- hclust(dist_samples, method = "ward.D2")

# Obtener metadatos para colorear
sample_metadata_cluster <- sample_metadata %>%
  filter(sample %in% rownames(vaf_matrix_samples_filtered)) %>%
  arrange(match(sample, rownames(vaf_matrix_samples_filtered)))

# Crear dendrograma
png("final_analysis/figures/clustering_samples_dendrogram.png", width = 12, height = 8, units = "in", res = 300)
plot(hc_samples, main = "Clustering Jerárquico de Muestras por Patrones de VAF", 
     xlab = "Muestras", ylab = "Distancia", cex = 0.6)
dev.off()

# Identificar clusters
n_clusters <- 3
sample_clusters <- cutree(hc_samples, k = n_clusters)
sample_cluster_data <- data.frame(
  sample = names(sample_clusters),
  cluster = sample_clusters
) %>%
  left_join(sample_metadata, by = "sample")

cat(paste0("   - Clusters identificados: ", n_clusters, "\n"))
cat("   - Distribución por cluster y cohorte:\n")
print(table(sample_cluster_data$cluster, sample_cluster_data$cohort))
cat("\n")

# --- 6. ANÁLISIS DE CLUSTERING POR miRNAs ---
cat("🧬 6. ANÁLISIS DE CLUSTERING POR miRNAs\n")
cat("=======================================\n")

# Crear matriz de VAF por miRNA y muestra (transpuesta)
vaf_matrix_mirnas <- t(vaf_matrix_samples_filtered)

# Filtrar miRNAs con muy poca variación entre muestras
mirna_variance <- apply(vaf_matrix_mirnas, 1, var, na.rm = TRUE)
vaf_matrix_mirnas_filtered <- vaf_matrix_mirnas[mirna_variance > quantile(mirna_variance, 0.7, na.rm = TRUE), ]

cat(paste0("   - Matriz de miRNAs: ", nrow(vaf_matrix_mirnas_filtered), " miRNAs x ", ncol(vaf_matrix_mirnas_filtered), " muestras\n"))

# Clustering de miRNAs
dist_mirnas <- dist(vaf_matrix_mirnas_filtered, method = "euclidean")
hc_mirnas <- hclust(dist_mirnas, method = "ward.D2")

# Crear dendrograma de miRNAs
png("final_analysis/figures/clustering_mirnas_dendrogram.png", width = 12, height = 8, units = "in", res = 300)
plot(hc_mirnas, main = "Clustering Jerárquico de miRNAs por Patrones de VAF", 
     xlab = "miRNAs", ylab = "Distancia", cex = 0.6)
dev.off()

# Identificar clusters de miRNAs
mirna_clusters <- cutree(hc_mirnas, k = 4)
mirna_cluster_data <- data.frame(
  miRNA_name = names(mirna_clusters),
  cluster = mirna_clusters
)

cat(paste0("   - Clusters de miRNAs identificados: ", length(unique(mirna_clusters)), "\n"))
cat("   - Distribución por cluster:\n")
print(table(mirna_cluster_data$cluster))
cat("\n")

# --- 7. HEATMAP COMBINADO ---
cat("🔥 7. HEATMAP COMBINADO\n")
cat("======================\n")

# Crear heatmap con clustering
# Seleccionar top miRNAs más variables
top_mirnas <- names(sort(mirna_variance, decreasing = TRUE))[1:50]
vaf_matrix_heatmap <- vaf_matrix_samples_filtered[, top_mirnas]

# Asegurar que las anotaciones coincidan con las muestras en la matriz
sample_order <- rownames(vaf_matrix_heatmap)
sample_metadata_ordered <- sample_metadata_cluster[match(sample_order, sample_metadata_cluster$sample), ]

# Crear anotaciones
ha_samples <- rowAnnotation(
  Cohort = sample_metadata_ordered$cohort,
  Batch = as.character(sample_metadata_ordered$batch),
  col = list(
    Cohort = c("ALS" = "red", "Control" = "blue"),
    Batch = setNames(colorRampPalette(brewer.pal(8, "Set3"))(length(unique(sample_metadata_ordered$batch))), 
                     unique(sample_metadata_ordered$batch))
  )
)

# Crear heatmap
png("final_analysis/figures/clustering_combined_heatmap.png", width = 14, height = 10, units = "in", res = 300)
ht <- Heatmap(
  as.matrix(vaf_matrix_heatmap),
  name = "VAF",
  col = colorRamp2(c(0, max(vaf_matrix_heatmap, na.rm = TRUE)), c("white", "red")),
  cluster_rows = TRUE,
  cluster_columns = TRUE,
  show_row_names = FALSE,
  show_column_names = FALSE,
  left_annotation = ha_samples,
  row_title = "Muestras",
  column_title = "miRNAs (Top 50 más variables)"
)
draw(ht)
dev.off()

cat("   - Heatmap combinado creado\n\n")

# --- 8. ANÁLISIS DE PATRONES POR CLUSTER ---
cat("📊 8. ANÁLISIS DE PATRONES POR CLUSTER\n")
cat("======================================\n")

# Análisis de patrones por cluster de muestras
cluster_patterns <- vaf_by_mirna %>%
  left_join(sample_cluster_data, by = "sample") %>%
  group_by(cluster, miRNA_name, region) %>%
  summarise(
    mean_vaf = mean(vaf, na.rm = TRUE),
    n_snvs = n(),
    n_samples = length(unique(sample)),
    .groups = 'drop'
  ) %>%
  group_by(cluster) %>%
  summarise(
    n_mirnas = length(unique(miRNA_name)),
    mean_vaf_overall = mean(mean_vaf, na.rm = TRUE),
    n_snvs_total = sum(n_snvs, na.rm = TRUE),
    seed_vaf = mean(mean_vaf[region == "Seed"], na.rm = TRUE),
    non_seed_vaf = mean(mean_vaf[region == "Non-seed"], na.rm = TRUE),
    .groups = 'drop'
  )

cat("   - Patrones por cluster de muestras:\n")
print(cluster_patterns)
cat("\n")

# --- 9. ANÁLISIS DE CORRELACIÓN ENTRE MUESTRAS ---
cat("🔗 9. ANÁLISIS DE CORRELACIÓN ENTRE MUESTRAS\n")
cat("============================================\n")

# Calcular matriz de correlación entre muestras
correlation_matrix <- cor(t(vaf_matrix_samples_filtered), use = "complete.obs")

# Crear heatmap de correlación
png("final_analysis/figures/clustering_correlation_heatmap.png", width = 10, height = 10, units = "in", res = 300)
heatmap(correlation_matrix, 
        main = "Matriz de Correlación entre Muestras",
        xlab = "Muestras",
        ylab = "Muestras",
        col = colorRampPalette(c("blue", "white", "red"))(100))
dev.off()

# Análisis de correlación por cohorte
correlation_by_cohort <- vaf_by_mirna %>%
  group_by(sample, cohort) %>%
  summarise(mean_vaf = mean(vaf, na.rm = TRUE), .groups = 'drop') %>%
  group_by(cohort) %>%
  summarise(
    mean_correlation = mean(cor(mean_vaf, mean_vaf, use = "complete.obs")),
    sd_correlation = sd(cor(mean_vaf, mean_vaf, use = "complete.obs")),
    .groups = 'drop'
  )

cat("   - Correlación por cohorte:\n")
print(correlation_by_cohort)
cat("\n")

# --- 10. CREANDO VISUALIZACIONES ADICIONALES ---
cat("📊 10. CREANDO VISUALIZACIONES ADICIONALES\n")
cat("==========================================\n")

figures_dir <- "final_analysis/figures"
if (!dir.exists(figures_dir)) {
  dir.create(figures_dir, recursive = TRUE)
}

# Boxplot de VAF por cluster
vaf_with_clusters <- vaf_by_mirna %>% 
  left_join(sample_cluster_data, by = "sample") %>%
  filter(!is.na(cluster)) %>%
  mutate(cohort = ifelse(!is.na(cohort.x), cohort.x, cohort.y))

p_vaf_by_cluster <- ggplot(vaf_with_clusters, 
                          aes(x = factor(cluster), y = vaf, fill = cohort)) +
  geom_boxplot() +
  labs(title = "VAF por Cluster de Muestras", x = "Cluster", y = "VAF") +
  theme_minimal()
ggsave(file.path(figures_dir, "clustering_vaf_by_cluster.png"), p_vaf_by_cluster, width = 10, height = 6)

# Scatter plot de VAF vs número de SNVs por cluster
p_vaf_snvs_cluster <- vaf_by_mirna %>%
  left_join(sample_cluster_data, by = "sample") %>%
  filter(!is.na(cluster)) %>%
  mutate(cohort = ifelse(!is.na(cohort.x), cohort.x, cohort.y)) %>%
  group_by(sample, cluster, cohort) %>%
  summarise(
    mean_vaf = mean(vaf, na.rm = TRUE),
    n_snvs = n(),
    .groups = 'drop'
  ) %>%
  ggplot(aes(x = n_snvs, y = mean_vaf, color = factor(cluster), shape = cohort)) +
  geom_point(alpha = 0.7) +
  geom_smooth(method = "lm", se = TRUE) +
  labs(title = "VAF vs Número de SNVs por Cluster", 
       x = "Número de SNVs", 
       y = "VAF Medio",
       color = "Cluster",
       shape = "Cohorte") +
  theme_minimal()
ggsave(file.path(figures_dir, "clustering_vaf_vs_snvs_by_cluster.png"), p_vaf_snvs_cluster, width = 10, height = 6)

cat(paste0("   - Figuras guardadas en: ", figures_dir, "\n\n"))

# --- 11. GUARDAR RESULTADOS ---
cat("💾 11. GUARDAR RESULTADOS\n")
cat("=========================\n")

tables_dir <- "final_analysis/tables"
if (!dir.exists(tables_dir)) {
  dir.create(tables_dir, recursive = TRUE)
}

write.csv(sample_cluster_data, file.path(tables_dir, "clustering_sample_clusters.csv"), row.names = FALSE)
write.csv(mirna_cluster_data, file.path(tables_dir, "clustering_mirna_clusters.csv"), row.names = FALSE)
write.csv(cluster_patterns, file.path(tables_dir, "clustering_patterns_by_cluster.csv"), row.names = FALSE)
write.csv(as.data.frame(correlation_matrix), file.path(tables_dir, "clustering_correlation_matrix.csv"), row.names = TRUE)
cat(paste0("   - Tablas guardadas en: ", tables_dir, "\n\n"))

# --- 12. RESUMEN FINAL ---
cat("📋 12. RESUMEN FINAL\n")
cat("====================\n")
cat("🔍 CLUSTERING DE MUESTRAS:\n")
cat(paste0("   - Clusters identificados: ", n_clusters, "\n"))
cat(paste0("   - Muestras por cluster: ", paste(table(sample_cluster_data$cluster), collapse = ", "), "\n"))
cat(paste0("   - Distribución ALS/Control por cluster: ", paste(table(sample_cluster_data$cluster, sample_cluster_data$cohort), collapse = ", "), "\n\n"))

cat("🧬 CLUSTERING DE miRNAs:\n")
cat(paste0("   - miRNAs analizados: ", nrow(vaf_matrix_mirnas_filtered), "\n"))
cat(paste0("   - Clusters de miRNAs: ", length(unique(mirna_clusters)), "\n"))
cat(paste0("   - miRNAs por cluster: ", paste(table(mirna_cluster_data$cluster), collapse = ", "), "\n\n"))

cat("📊 PATRONES IDENTIFICADOS:\n")
cat("   - Cluster 1: ", cluster_patterns$n_mirnas[1], " miRNAs, VAF medio: ", round(cluster_patterns$mean_vaf_overall[1], 4), "\n")
cat("   - Cluster 2: ", cluster_patterns$n_mirnas[2], " miRNAs, VAF medio: ", round(cluster_patterns$mean_vaf_overall[2], 4), "\n")
cat("   - Cluster 3: ", cluster_patterns$n_mirnas[3], " miRNAs, VAF medio: ", round(cluster_patterns$mean_vaf_overall[3], 4), "\n\n")

cat("✅ VERIFICACIONES:\n")
cat("   - Clustering de muestras completado: ✓\n")
cat("   - Clustering de miRNAs completado: ✓\n")
cat("   - Heatmaps creados: ✓\n")
cat("   - Análisis de patrones realizado: ✓\n")
cat("   - Resultados guardados: ✓\n\n")

cat("🎯 PRÓXIMOS PASOS:\n")
cat("   - Realizar análisis funcional de miRNAs\n")
cat("   - Interpretar resultados inesperados\n")
cat("   - Escribir paper con interpretación correcta\n\n")
