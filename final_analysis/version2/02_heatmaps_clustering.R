# --- HEATMAPS Y CLUSTERING VERSIÓN 2 ---
# Análisis de patrones de oxidación con clustering jerárquico

# --- LIBRERÍAS ---
library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(ComplexHeatmap)
library(circlize)
library(viridis)
library(RColorBrewer)
library(reshape2)
library(stats)

# --- CONFIGURACIÓN ---
cat("🔥 HEATMAPS Y CLUSTERING VERSIÓN 2\n")
cat("===================================\n\n")

# --- 1. CARGANDO DATOS ---
cat("📊 1. CARGANDO DATOS\n")
cat("====================\n")

# Cargar datos del análisis anterior
source("01_analysis_v2.R")

# Preparar datos para heatmaps
vaf_matrix_data <- vaf_data %>%
  select(miRNA_name, position, sample, vaf, cohort) %>%
  mutate(snv_id = paste(miRNA_name, position, sep = "_")) %>%
  filter(!is.na(vaf))

cat(paste0("   - SNVs con VAF válido: ", nrow(vaf_matrix_data), "\n"))
cat(paste0("   - miRNAs únicos: ", length(unique(vaf_matrix_data$miRNA_name)), "\n"))
cat(paste0("   - Muestras: ", length(unique(vaf_matrix_data$sample)), "\n\n"))

# --- 2. MATRIZ DE VAFs (MUESTRAS x SNVs) ---
cat("🔥 2. CREANDO MATRIZ DE VAFs\n")
cat("=============================\n")

# Crear matriz muestras x SNVs usando reshape2
vaf_matrix_wide <- dcast(vaf_matrix_data, sample ~ snv_id, value.var = "vaf", fill = 0)

# Convertir a matriz
vaf_matrix_df <- as.data.frame(vaf_matrix_wide)
rownames(vaf_matrix_df) <- vaf_matrix_df$sample
vaf_matrix_matrix <- as.matrix(vaf_matrix_df[, -1])

# Reemplazar NAs con 0 para el clustering
vaf_matrix_matrix[is.na(vaf_matrix_matrix)] <- 0

cat(paste0("   - Dimensiones matriz: ", nrow(vaf_matrix_matrix), " x ", ncol(vaf_matrix_matrix), "\n"))
cat(paste0("   - VAFs no-cero: ", sum(vaf_matrix_matrix > 0), "\n\n"))

# --- 3. HEATMAP PRINCIPAL (MUESTRAS x SNVs) ---
cat("🔥 3. HEATMAP PRINCIPAL\n")
cat("=======================\n")

# Preparar metadatos para anotaciones
sample_metadata_ordered <- vaf_matrix_df %>%
  select(sample) %>%
  left_join(sample_metadata, by = "sample") %>%
  filter(!is.na(cohort))

# Anotación de filas (muestras)
ha_samples <- rowAnnotation(
  Cohort = sample_metadata_ordered$cohort,
  col = list(
    Cohort = c("ALS" = "red", "Control" = "blue")
  )
)

# Crear heatmap
ht_main <- Heatmap(
  vaf_matrix_matrix,
  name = "VAF",
  col = colorRamp2(c(0, max(vaf_matrix_matrix, na.rm = TRUE)), c("white", "red")),
  cluster_rows = TRUE,
  cluster_columns = TRUE,
  show_row_names = FALSE,
  show_column_names = FALSE,
  left_annotation = ha_samples,
  row_title = "Muestras",
  column_title = "SNVs",
  heatmap_legend_param = list(
    title = "VAF",
    at = c(0, 0.1, 0.2, 0.3, 0.4, 0.5),
    labels = c("0", "0.1", "0.2", "0.3", "0.4", "0.5")
  )
)

# Guardar heatmap
pdf("heatmap_main_samples_vs_snvs.pdf", width = 12, height = 8)
draw(ht_main)
dev.off()

cat("   - Heatmap principal guardado: heatmap_main_samples_vs_snvs.pdf\n\n")

# --- 4. HEATMAP DE Z-SCORES ---
cat("🔥 4. HEATMAP DE Z-SCORES\n")
cat("==========================\n")

# Calcular z-scores por SNV (comparando ALS vs Control)
zscore_data <- vaf_matrix_data %>%
  group_by(snv_id, cohort) %>%
  summarise(mean_vaf = mean(vaf, na.rm = TRUE), .groups = 'drop') %>%
  pivot_wider(names_from = cohort, values_from = mean_vaf) %>%
  mutate(
    mean_diff = ALS - Control,
    pooled_sd = sqrt((var(ALS, na.rm = TRUE) + var(Control, na.rm = TRUE)) / 2),
    zscore = mean_diff / pooled_sd
  ) %>%
  filter(!is.na(zscore))

# Crear matriz de z-scores
zscore_matrix <- vaf_matrix_data %>%
  select(sample, snv_id, vaf) %>%
  left_join(zscore_data %>% select(snv_id, zscore), by = "snv_id") %>%
  pivot_wider(names_from = snv_id, values_from = zscore, values_fill = 0)

zscore_matrix_df <- as.data.frame(zscore_matrix)
rownames(zscore_matrix_df) <- zscore_matrix_df$sample
zscore_matrix_matrix <- as.matrix(zscore_matrix_df[, -1])

# Heatmap de z-scores
ht_zscore <- Heatmap(
  zscore_matrix_matrix,
  name = "Z-score",
  col = colorRamp2(c(-3, 0, 3), c("blue", "white", "red")),
  cluster_rows = TRUE,
  cluster_columns = TRUE,
  show_row_names = FALSE,
  show_column_names = FALSE,
  left_annotation = ha_samples,
  row_title = "Muestras",
  column_title = "SNVs (Z-scores)",
  heatmap_legend_param = list(
    title = "Z-score",
    at = c(-3, -2, -1, 0, 1, 2, 3),
    labels = c("-3", "-2", "-1", "0", "1", "2", "3")
  )
)

# Guardar heatmap de z-scores
pdf("heatmap_zscores_samples_vs_snvs.pdf", width = 12, height = 8)
draw(ht_zscore)
dev.off()

cat("   - Heatmap de z-scores guardado: heatmap_zscores_samples_vs_snvs.pdf\n\n")

# --- 5. ANÁLISIS POR POSICIÓN ---
cat("🔥 5. ANÁLISIS POR POSICIÓN\n")
cat("============================\n")

# Z-scores por posición
position_zscore <- vaf_matrix_data %>%
  group_by(position, cohort) %>%
  summarise(mean_vaf = mean(vaf, na.rm = TRUE), .groups = 'drop') %>%
  pivot_wider(names_from = cohort, values_from = mean_vaf) %>%
  mutate(
    mean_diff = ALS - Control,
    pooled_sd = sqrt((var(ALS, na.rm = TRUE) + var(Control, na.rm = TRUE)) / 2),
    zscore = mean_diff / pooled_sd
  ) %>%
  filter(!is.na(zscore)) %>%
  arrange(desc(abs(zscore)))

cat("   - Top 10 posiciones con mayor diferencia (z-score):\n")
print(head(position_zscore, 10))
cat("\n")

# Gráfico de z-scores por posición
p_position <- ggplot(position_zscore, aes(x = position, y = zscore, color = abs(zscore))) +
  geom_point(size = 3) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray") +
  geom_hline(yintercept = c(-2, 2), linetype = "dashed", color = "red", alpha = 0.5) +
  scale_color_viridis_c(name = "|Z-score|") +
  labs(
    title = "Z-scores por Posición (ALS vs Control)",
    x = "Posición en miRNA",
    y = "Z-score",
    subtitle = "Líneas rojas: Z-score = ±2 (significativo)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
    plot.subtitle = element_text(hjust = 0.5, size = 12),
    axis.text = element_text(size = 10),
    axis.title = element_text(size = 12)
  )

ggsave("zscore_by_position.pdf", p_position, width = 10, height = 6)
cat("   - Gráfico de z-scores por posición guardado: zscore_by_position.pdf\n\n")

# --- 6. HEATMAP DE POSICIONES ---
cat("🔥 6. HEATMAP DE POSICIONES\n")
cat("=============================\n")

# Matriz posición x muestra
position_sample_data <- vaf_matrix_data %>%
  group_by(sample, position) %>%
  summarise(mean_vaf = mean(vaf, na.rm = TRUE), .groups = 'drop')

position_sample_matrix <- dcast(position_sample_data, sample ~ position, value.var = "mean_vaf", fill = 0)

position_sample_df <- as.data.frame(position_sample_matrix)
rownames(position_sample_df) <- position_sample_df$sample
position_sample_matrix_final <- as.matrix(position_sample_df[, -1])

# Heatmap posición x muestra
ht_position <- Heatmap(
  position_sample_matrix_final,
  name = "VAF",
  col = colorRamp2(c(0, max(position_sample_matrix_final, na.rm = TRUE)), c("white", "red")),
  cluster_rows = TRUE,
  cluster_columns = FALSE,
  show_row_names = FALSE,
  show_column_names = TRUE,
  left_annotation = ha_samples,
  row_title = "Muestras",
  column_title = "Posiciones en miRNA",
  heatmap_legend_param = list(
    title = "VAF medio"
  )
)

# Guardar heatmap de posiciones
pdf("heatmap_positions_vs_samples.pdf", width = 10, height = 8)
draw(ht_position)
dev.off()

cat("   - Heatmap de posiciones guardado: heatmap_positions_vs_samples.pdf\n\n")

# --- 7. ANÁLISIS DE CLUSTERS ---
cat("🔥 7. ANÁLISIS DE CLUSTERS\n")
cat("===========================\n")

# Clustering jerárquico de muestras
dist_samples <- dist(vaf_matrix_matrix)
hc_samples <- hclust(dist_samples, method = "ward.D2")

# Clustering jerárquico de SNVs
dist_snvs <- dist(t(vaf_matrix_matrix))
hc_snvs <- hclust(dist_snvs, method = "ward.D2")

# Identificar clusters de muestras
sample_clusters <- cutree(hc_samples, k = 2)
sample_cluster_data <- data.frame(
  sample = names(sample_clusters),
  cluster = sample_clusters
) %>%
  left_join(sample_metadata, by = "sample")

cat("   - Distribución de clusters por cohorte:\n")
cluster_table <- table(sample_cluster_data$cluster, sample_cluster_data$cohort)
print(cluster_table)
cat("\n")

# Guardar información de clusters
write.csv(sample_cluster_data, "sample_clusters.csv", row.names = FALSE)
cat("   - Información de clusters guardada: sample_clusters.csv\n\n")

cat("✅ ANÁLISIS DE HEATMAPS Y CLUSTERING COMPLETADO\n")
cat("===============================================\n\n")
