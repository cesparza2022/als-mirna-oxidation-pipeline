#!/usr/bin/env Rscript
# ============================================================================
# PASO 2.5.1: CLUSTERING DE MUESTRAS
# Analiza si muestras ALS se separan de Control usando solo candidatos
# ============================================================================

library(dplyr)
library(tidyr)
library(readr)
library(stringr)
library(ggplot2)
library(pheatmap)
library(factoextra)
library(cluster)

COLOR_ALS <- "#D62728"
COLOR_CTRL <- "grey60"

theme_prof <- theme_classic(base_size = 14) +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
    axis.title = element_text(face = "bold")
  )

cat("🎯 PASO 2.5.1: CLUSTERING DE MUESTRAS\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

# Crear directorios
dir.create("data", showWarnings = FALSE, recursive = TRUE)
dir.create("figures", showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# CARGAR DATOS
# ============================================================================

cat("📊 Cargando datos...\n")

# Datos limpios
data <- read_csv("../pipeline_2/final_processed_data_CLEAN.csv", show_col_types = FALSE)
metadata <- read_csv("../pipeline_2/metadata.csv", show_col_types = FALSE)

# Candidatos (de results_threshold_permissive)
candidates <- read_csv("../results_threshold_permissive/ALS_candidates.csv", show_col_types = FALSE)

cat(sprintf("   Candidatos: %d\n", nrow(candidates)))
cat(sprintf("   Muestras: %d (ALS: %d, Control: %d)\n\n", 
            nrow(metadata), 
            sum(metadata$Group == "ALS"),
            sum(metadata$Group == "Control")))

# ============================================================================
# CREAR MATRIZ: MUESTRAS x CANDIDATOS
# ============================================================================

cat("📊 Creando matriz muestras x candidatos...\n")

# Filtrar solo SNVs G>T de candidatos
data_candidates <- data %>%
  filter(
    miRNA_name %in% candidates$miRNA,
    str_detect(pos.mut, ":GT$")
  )

# Convertir a long format (mantener Sample_ID completo)
data_long <- data_candidates %>%
  pivot_longer(cols = -c(miRNA_name, pos.mut), names_to = "Sample_ID", values_to = "VAF") %>%
  filter(!is.na(VAF))

# Crear matriz: Suma de VAF por miRNA por muestra
mat_wide <- data_long %>%
  group_by(Sample_ID, miRNA_name) %>%
  summarise(Total_VAF = sum(VAF, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = miRNA_name, values_from = Total_VAF, values_fill = 0)

# Unir con metadata
mat_with_meta <- mat_wide %>%
  left_join(metadata, by = "Sample_ID") %>%
  filter(!is.na(Group))

cat(sprintf("   Matriz creada: %d muestras x %d candidatos\n\n", 
            nrow(mat_with_meta), nrow(candidates)))

# ============================================================================
# FIGURA 1: HEATMAP SAMPLES x CANDIDATES
# ============================================================================

cat("📊 [1/4] Generando heatmap muestras x candidatos...\n")

# Preparar matriz para heatmap
# Verificar que tenemos datos
if (nrow(mat_with_meta) == 0) {
  cat("   ⚠️ ADVERTENCIA: Matriz vacía\n")
  cat("   Problema: Sample IDs no coinciden entre data y metadata\n")
  cat("   Saltando clustering...\n\n")
  quit(status = 0)
}

cols_to_remove <- intersect(c("Sample_ID", "Group", "Age", "Sex"), names(mat_with_meta))
mat_heatmap <- mat_with_meta %>%
  select(-all_of(cols_to_remove)) %>%
  as.matrix()

rownames(mat_heatmap) <- mat_with_meta$Sample_ID

# Anotaciones
annotation_row <- data.frame(
  Group = mat_with_meta$Group,
  row.names = mat_with_meta$Sample_ID
)

annotation_colors <- list(
  Group = c(ALS = COLOR_ALS, Control = COLOR_CTRL)
)

# Heatmap
png("figures/FIG_2.5_1_HEATMAP_SAMPLES_CANDIDATES.png", width = 14, height = 12, units = "in", res = 300)
pheatmap(
  mat_heatmap,
  annotation_row = annotation_row,
  annotation_colors = annotation_colors,
  color = colorRampPalette(c("white", "#fee5d9", "#fcae91", "#fb6a4a", COLOR_ALS))(100),
  cluster_rows = TRUE,
  cluster_cols = TRUE,
  show_rownames = FALSE,
  show_colnames = TRUE,
  main = sprintf("Sample Clustering Based on %d ALS Candidates", nrow(candidates)),
  fontsize = 12,
  fontsize_col = 10
)
dev.off()

cat("   ✅ Guardada\n\n")

# ============================================================================
# FIGURA 2: PCA DE MUESTRAS
# ============================================================================

cat("📊 [2/4] Generando PCA de muestras...\n")

# PCA
pca_result <- prcomp(mat_heatmap, scale. = TRUE, center = TRUE)

# Crear df para ggplot
pca_df <- data.frame(
  PC1 = pca_result$x[, 1],
  PC2 = pca_result$x[, 2],
  Sample_ID = rownames(pca_result$x)
) %>%
  left_join(metadata, by = "Sample_ID")

# Calcular % varianza
var_explained <- round(100 * summary(pca_result)$importance[2, 1:2], 1)

# Plot
fig2 <- ggplot(pca_df, aes(x = PC1, y = PC2, color = Group)) +
  geom_point(size = 3, alpha = 0.7) +
  stat_ellipse(aes(fill = Group), geom = "polygon", alpha = 0.1, show.legend = FALSE) +
  scale_color_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CTRL)) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CTRL)) +
  labs(
    title = sprintf("PCA: Samples Based on %d ALS Candidates", nrow(candidates)),
    x = sprintf("PC1 (%.1f%% variance)", var_explained[1]),
    y = sprintf("PC2 (%.1f%% variance)", var_explained[2])
  ) +
  theme_prof +
  theme(legend.position = "right")

ggsave("figures/FIG_2.5_2_PCA_SAMPLES.png", fig2, width = 10, height = 8, dpi = 300)

cat("   ✅ Guardada\n")
cat(sprintf("   PC1: %.1f%% | PC2: %.1f%%\n\n", var_explained[1], var_explained[2]))

# ============================================================================
# FIGURA 3: K-MEANS SUBTYPES (Solo ALS)
# ============================================================================

cat("📊 [3/4] Generando K-means subtypes (ALS)...\n")

# Solo muestras ALS
als_samples <- mat_with_meta %>%
  filter(Group == "ALS")

cols_to_remove_als <- intersect(c("Sample_ID", "Group", "Age", "Sex"), names(als_samples))
mat_als <- als_samples %>%
  select(-all_of(cols_to_remove_als)) %>%
  as.matrix()

# K-means con k=2,3,4
set.seed(123)
km2 <- kmeans(mat_als, centers = 2, nstart = 25)
km3 <- kmeans(mat_als, centers = 3, nstart = 25)

# Silhouette para k=2
sil <- silhouette(km2$cluster, dist(mat_als))
avg_sil <- mean(sil[, 3])

# PCA de ALS con clusters
pca_als <- prcomp(mat_als, scale. = TRUE, center = TRUE)
pca_als_df <- data.frame(
  PC1 = pca_als$x[, 1],
  PC2 = pca_als$x[, 2],
  Cluster = as.factor(km2$cluster),
  Sample_ID = als_samples$Sample_ID
)

var_als <- round(100 * summary(pca_als)$importance[2, 1:2], 1)

fig3 <- ggplot(pca_als_df, aes(x = PC1, y = PC2, color = Cluster)) +
  geom_point(size = 4, alpha = 0.7) +
  stat_ellipse(aes(fill = Cluster), geom = "polygon", alpha = 0.1, show.legend = FALSE) +
  scale_color_manual(values = c("1" = "#E74C3C", "2" = "#3498DB")) +
  scale_fill_manual(values = c("1" = "#E74C3C", "2" = "#3498DB")) +
  labs(
    title = "ALS Subtypes (K-means, k=2)",
    subtitle = sprintf("Avg Silhouette: %.3f | Based on %d candidates", avg_sil, nrow(candidates)),
    x = sprintf("PC1 (%.1f%%)", var_als[1]),
    y = sprintf("PC2 (%.1f%%)", var_als[2])
  ) +
  theme_prof

ggsave("figures/FIG_2.5_3_KMEANS_ALS_SUBTYPES.png", fig3, width = 10, height = 8, dpi = 300)

cat("   ✅ Guardada\n")
cat(sprintf("   Clusters ALS: k=2 (Silhouette: %.3f)\n", avg_sil))
cat(sprintf("   Cluster 1: %d samples | Cluster 2: %d samples\n\n", 
            sum(km2$cluster == 1), sum(km2$cluster == 2)))

# Guardar clusters
cluster_assignments <- data.frame(
  Sample_ID = als_samples$Sample_ID,
  Cluster_k2 = km2$cluster,
  Cluster_k3 = km3$cluster
)

write_csv(cluster_assignments, "data/als_clusters.csv")

# ============================================================================
# FIGURA 4: DENDROGRAMA
# ============================================================================

cat("📊 [4/4] Generando dendrograma...\n")

# Distancia euclidiana
dist_mat <- dist(mat_heatmap, method = "euclidean")

# Clustering jerárquico (Ward)
hc <- hclust(dist_mat, method = "ward.D2")

# Colores por grupo
sample_colors <- ifelse(mat_with_meta$Group == "ALS", COLOR_ALS, COLOR_CTRL)
names(sample_colors) <- mat_with_meta$Sample_ID

# Plot
png("figures/FIG_2.5_4_DENDROGRAMA_SAMPLES.png", width = 16, height = 10, units = "in", res = 300)
par(cex = 0.8, mar = c(5, 5, 4, 2))
plot(hc, 
     labels = FALSE,
     main = sprintf("Hierarchical Clustering: %d Samples Based on %d Candidates", 
                    nrow(mat_with_meta), nrow(candidates)),
     xlab = "Samples",
     ylab = "Height",
     sub = "Ward.D2 method | Red = ALS | Grey = Control")

# Añadir colores en las hojas
colored_labels <- ifelse(mat_with_meta$Group[hc$order] == "ALS", COLOR_ALS, COLOR_CTRL)
dev.off()

cat("   ✅ Guardada\n\n")

# ============================================================================
# RESUMEN Y ESTADÍSTICAS
# ============================================================================

cat(paste(rep("=", 70), collapse = ""), "\n")
cat("✅ CLUSTERING COMPLETADO\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

cat("📊 RESUMEN:\n")
cat(sprintf("   • Muestras analizadas: %d\n", nrow(mat_with_meta)))
cat(sprintf("   • Candidatos usados: %d\n", nrow(candidates)))
cat(sprintf("   • PCA variance (PC1+PC2): %.1f%%\n", sum(var_explained)))
cat(sprintf("   • ALS clusters (k=2): Cluster1=%d, Cluster2=%d\n", 
            sum(km2$cluster == 1), sum(km2$cluster == 2)))
cat(sprintf("   • Silhouette score: %.3f\n\n", avg_sil))

cat("📁 ARCHIVOS GENERADOS:\n")
cat("   • FIG_2.5_1_HEATMAP_SAMPLES_CANDIDATES.png\n")
cat("   • FIG_2.5_2_PCA_SAMPLES.png\n")
cat("   • FIG_2.5_3_KMEANS_ALS_SUBTYPES.png\n")
cat("   • FIG_2.5_4_DENDROGRAMA_SAMPLES.png\n")
cat("   • data/als_clusters.csv\n\n")

cat("🚀 SIGUIENTE: Análisis de familias miRNA\n")
cat("   Rscript scripts/02_family_analysis.R\n\n")

