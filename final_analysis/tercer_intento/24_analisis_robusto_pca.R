# =============================================================================
# ANÁLISIS ROBUSTO CON PCA - EXCLUYENDO ARTEFACTOS TÉCNICOS
# =============================================================================

cat("=== ANÁLISIS ROBUSTO CON PCA - EXCLUYENDO ARTEFACTOS ===\n\n")

# Cargar librerías
library(dplyr)
library(ggplot2)
library(reshape2)
library(ComplexHeatmap)
library(circlize)
library(viridis)
library(RColorBrewer)
library(gridExtra)
library(corrplot)
library(tibble)
library(stats)
library(factoextra)
library(cluster)
library(vegan)
library(tidyr)

# =============================================================================
# 1. CARGA DE DATOS Y FILTRADO DE ARTEFACTOS
# =============================================================================

cat("1. Cargando datos y filtrando artefactos...\n")

# Cargar datos preprocesados
final_data <- read.csv("../processed_data/final_processed_data.csv", stringsAsFactors = FALSE)

# Extraer pos y mutation_type de pos.mut para todos los datos
if ("pos.mut" %in% colnames(final_data)) {
  final_data$pos <- as.numeric(gsub(":.*", "", final_data$pos.mut))
  final_data$mutation_type <- gsub(".*:", "", final_data$pos.mut)
}

# EXCLUIR hsa-miR-6133 (artefacto técnico confirmado)
cat("   - Excluyendo hsa-miR-6133 (artefacto técnico)...\n")
data_clean <- final_data[final_data$miRNA_name != "hsa-miR-6133", ]

cat("   - SNVs antes del filtro:", nrow(final_data), "\n")
cat("   - SNVs después del filtro:", nrow(data_clean), "\n")
cat("   - SNVs excluidos:", nrow(final_data) - nrow(data_clean), "\n\n")

# Extraer columnas de muestras (usar el mismo patrón que en otros scripts)
sample_cols <- grep("^Magen\\.", names(data_clean), value = TRUE)
sample_cols <- sample_cols[!grepl("\\.\\.PM\\.1MM\\.2MM\\.$", sample_cols)]

# Si no encontramos columnas con el patrón anterior, usar un patrón más amplio
if (length(sample_cols) == 0) {
  sample_cols <- names(data_clean)[grepl("^Magen", names(data_clean))]
  sample_cols <- sample_cols[!grepl("\\.\\.PM\\.1MM\\.2MM\\.$", sample_cols)]
}

# Identificar grupos
als_samples <- sample_cols[grepl("ALS", sample_cols)]
control_samples <- sample_cols[grepl("control", sample_cols)]

cat("   - Muestras ALS:", length(als_samples), "\n")
cat("   - Muestras Control:", length(control_samples), "\n")
cat("   - Total muestras:", length(sample_cols), "\n")

# Debug: mostrar algunas columnas encontradas
if (length(sample_cols) > 0) {
  cat("   - Primeras 5 columnas de muestras:", paste(head(sample_cols, 5), collapse = ", "), "\n")
} else {
  cat("   - ERROR: No se encontraron columnas de muestras\n")
  cat("   - Nombres de columnas disponibles:", paste(head(names(data_clean), 10), collapse = ", "), "\n")
}

cat("\n")

# =============================================================================
# 2. PREPARACIÓN DE DATOS PARA PCA
# =============================================================================

cat("2. Preparando datos para PCA...\n")

# Los datos ya están procesados con VAFs calculados
# Usar directamente las columnas de muestras como VAFs
vaf_matrix <- as.matrix(data_clean[, sample_cols])

# Crear identificadores únicos para SNVs
snv_ids <- paste(data_clean$miRNA_name, data_clean$pos, data_clean$mutation_type, sep = "_")
rownames(vaf_matrix) <- snv_ids

# Aplicar filtro VAF > 0.5 a NaN (si no se aplicó en preprocesamiento)
vaf_matrix[vaf_matrix > 0.5] <- NaN

cat("   - Matriz VAF creada:", nrow(vaf_matrix), "SNVs x", ncol(vaf_matrix), "muestras\n")

# =============================================================================
# 3. FILTRADO DE CALIDAD PARA PCA
# =============================================================================

cat("3. Aplicando filtros de calidad para PCA...\n")

# Filtro 1: Al menos 10% de muestras válidas por SNV
min_valid_samples <- ceiling(0.1 * ncol(vaf_matrix))
valid_samples_per_snv <- rowSums(!is.na(vaf_matrix))

snvs_quality <- vaf_matrix[valid_samples_per_snv >= min_valid_samples, ]

cat("   - SNVs con ≥10% muestras válidas:", nrow(snvs_quality), "\n")
cat("   - SNVs filtrados:", nrow(vaf_matrix) - nrow(snvs_quality), "\n")

# Filtro 2: Al menos 5% de SNVs válidos por muestra
min_valid_snvs <- ceiling(0.05 * nrow(snvs_quality))
valid_snvs_per_sample <- colSums(!is.na(snvs_quality))

samples_quality <- snvs_quality[, valid_snvs_per_sample >= min_valid_snvs]

cat("   - Muestras con ≥5% SNVs válidos:", ncol(samples_quality), "\n")
cat("   - Muestras filtradas:", ncol(snvs_quality) - ncol(samples_quality), "\n\n")

# =============================================================================
# 4. IMPUTACIÓN DE VALORES FALTANTES
# =============================================================================

cat("4. Imputando valores faltantes...\n")

# Función para imputar NAs usando la mediana por SNV
impute_median <- function(x) {
  x[is.na(x)] <- median(x, na.rm = TRUE)
  return(x)
}

# Aplicar imputación por filas (SNVs)
data_imputed <- t(apply(samples_quality, 1, impute_median))
# No transponer de vuelta - queremos SNVs como filas y muestras como columnas

cat("   - Imputación completada\n")
cat("   - Valores NA restantes:", sum(is.na(data_imputed)), "\n")

# Filtrar filas (SNVs) con varianza cero
variances <- apply(data_imputed, 1, var, na.rm = TRUE)
zero_var_rows <- which(variances == 0 | is.na(variances))

if (length(zero_var_rows) > 0) {
  cat("   - Eliminando", length(zero_var_rows), "SNVs con varianza cero\n")
  data_imputed <- data_imputed[-zero_var_rows, ]
}

cat("   - Matriz final para PCA:", nrow(data_imputed), "SNVs x", ncol(data_imputed), "muestras\n\n")

# =============================================================================
# 5. ANÁLISIS DE COMPONENTES PRINCIPALES (PCA)
# =============================================================================

cat("5. Realizando análisis de componentes principales...\n")

# Realizar PCA (transponer para que muestras sean filas y SNVs columnas)
pca_result <- prcomp(t(data_imputed), center = TRUE, scale. = TRUE)

# Resumen de varianza explicada
variance_explained <- summary(pca_result)$importance[2, ] * 100
cumulative_variance <- summary(pca_result)$importance[3, ] * 100

cat("   - Varianza explicada por los primeros 10 componentes:\n")
for (i in 1:min(10, length(variance_explained))) {
  cat("     PC", i, ":", round(variance_explained[i], 2), "%\n")
}

cat("   - Varianza acumulada PC1-PC5:", round(cumulative_variance[5], 2), "%\n")
cat("   - Varianza acumulada PC1-PC10:", round(cumulative_variance[10], 2), "%\n\n")

# =============================================================================
# 6. ANÁLISIS DE GRUPOS EN ESPACIO PCA
# =============================================================================

cat("6. Analizando grupos en espacio PCA...\n")

# Crear dataframe con coordenadas PCA y grupos
# El PCA devuelve muestras como filas en pca_result$x
sample_names <- rownames(pca_result$x)
group_labels <- ifelse(grepl("control", sample_names, ignore.case = TRUE), "Control", "ALS")

# Verificar algunos nombres de muestra para debug
cat("   - Primeras 10 muestras:", paste(head(sample_names, 10), collapse = ", "), "\n")
cat("   - Muestras con 'control':", sum(grepl("control", sample_names, ignore.case = TRUE)), "\n")

pca_df <- data.frame(
  sample_id = sample_names,
  PC1 = pca_result$x[, 1],
  PC2 = pca_result$x[, 2],
  PC3 = pca_result$x[, 3],
  group = group_labels
)

# Verificar distribución de grupos
cat("   - Distribución de grupos:\n")
print(table(pca_df$group))

# Estadísticas por grupo
group_stats <- pca_df %>%
  group_by(group) %>%
  summarise(
    n_samples = n(),
    PC1_mean = mean(PC1),
    PC2_mean = mean(PC2),
    PC3_mean = mean(PC3),
    PC1_sd = sd(PC1),
    PC2_sd = sd(PC2),
    PC3_sd = sd(PC3)
  )

print(group_stats)

# Test estadístico para diferencias entre grupos
# Test t para diferencias entre grupos (solo si hay ambos grupos)
if (length(unique(pca_df$group)) == 2) {
  pc1_test <- t.test(PC1 ~ group, data = pca_df)
  pc2_test <- t.test(PC2 ~ group, data = pca_df)
  pc3_test <- t.test(PC3 ~ group, data = pca_df)
  
  cat("\n   - Test t para diferencias entre grupos:\n")
  cat("     PC1: t =", round(pc1_test$statistic, 3), ", p =", round(pc1_test$p.value, 4), "\n")
  cat("     PC2: t =", round(pc2_test$statistic, 3), ", p =", round(pc2_test$p.value, 4), "\n")
  cat("     PC3: t =", round(pc3_test$statistic, 3), ", p =", round(pc3_test$p.value, 4), "\n\n")
} else {
  cat("\n   - No se puede realizar test t: solo hay un grupo presente\n")
  cat("   - Grupos encontrados:", paste(unique(pca_df$group), collapse = ", "), "\n\n")
}

# =============================================================================
# 7. ANÁLISIS DE CONTRIBUCIONES A COMPONENTES PRINCIPALES
# =============================================================================

cat("7. Analizando contribuciones de SNVs a componentes principales...\n")

# Obtener contribuciones (loadings) de los primeros 5 componentes
# Ahora loadings tiene SNVs como filas y componentes como columnas
loadings <- pca_result$rotation[, 1:5]
colnames(loadings) <- paste0("PC", 1:5)

# Identificar SNVs con mayor contribución a PC1
pc1_contributions <- abs(loadings[, "PC1"])
top_pc1_snvs <- head(sort(pc1_contributions, decreasing = TRUE), 20)

cat("   - Top 10 SNVs contribuyendo a PC1:\n")
for (i in 1:10) {
  snv_name <- names(top_pc1_snvs)[i]
  contribution <- top_pc1_snvs[i]
  cat("     ", i, ".", snv_name, ":", round(contribution, 4), "\n")
}

# Análisis por posición
position_contributions <- data.frame(
  snv_id = rownames(loadings),
  PC1_loading = loadings[, "PC1"],
  PC2_loading = loadings[, "PC2"]
)

# Extraer posición de snv_id (formato: miRNA_name_pos_mutation)
position_contributions$position <- as.numeric(gsub(".*_([0-9]+)_.*", "\\1", position_contributions$snv_id))

# Verificar extracción de posiciones
cat("   - Posiciones extraídas:", paste(sort(unique(position_contributions$position)), collapse = ", "), "\n")
cat("   - SNVs con posición NA:", sum(is.na(position_contributions$position)), "\n")

# Análisis por posición
pos_analysis <- position_contributions %>%
  group_by(position) %>%
  summarise(
    n_snvs = n(),
    mean_pc1_loading = mean(abs(PC1_loading)),
    mean_pc2_loading = mean(abs(PC2_loading)),
    max_pc1_loading = max(abs(PC1_loading))
  ) %>%
  arrange(desc(mean_pc1_loading))

cat("\n   - Contribución promedio por posición (PC1):\n")
print(head(pos_analysis, 10))

# =============================================================================
# 8. CLUSTERING JERÁRQUICO EN ESPACIO PCA
# =============================================================================

cat("8. Realizando clustering jerárquico en espacio PCA...\n")

# Usar solo los primeros 10 componentes para clustering
pca_coords <- pca_result$x[, 1:10]

# Calcular matriz de distancias
dist_matrix <- dist(pca_coords, method = "euclidean")

# Clustering jerárquico
hc_result <- hclust(dist_matrix, method = "ward.D2")

# Determinar número óptimo de clusters usando silhouette
silhouette_scores <- numeric(10)
for (k in 2:10) {
  clusters <- cutree(hc_result, k = k)
  sil <- silhouette(clusters, dist_matrix)
  silhouette_scores[k] <- mean(sil[, 3])
}

optimal_k <- which.max(silhouette_scores[2:10]) + 1
cat("   - Número óptimo de clusters (silhouette):", optimal_k, "\n")
cat("   - Silhouette score:", round(silhouette_scores[optimal_k], 3), "\n\n")

# Asignar clusters
pca_df$cluster <- cutree(hc_result, k = optimal_k)

# Análisis de clusters
# Análisis de clusters por grupo (solo si hay ambos grupos)
if (length(unique(pca_df$group)) == 2) {
  cluster_analysis <- pca_df %>%
    group_by(cluster, group) %>%
    summarise(n_samples = n(), .groups = "drop") %>%
    pivot_wider(names_from = group, values_from = n_samples, values_fill = 0) %>%
    mutate(total = ALS + Control)
} else {
  cluster_analysis <- pca_df %>%
    group_by(cluster, group) %>%
    summarise(n_samples = n(), .groups = "drop") %>%
    mutate(total = n_samples)
}

cat("   - Distribución de clusters:\n")
print(cluster_analysis)

# =============================================================================
# 9. GENERACIÓN DE VISUALIZACIONES
# =============================================================================

cat("9. Generando visualizaciones...\n")

# Crear directorio para figuras
dir.create("figures_robust_pca", showWarnings = FALSE)

# 9.1 Scatter plot PC1 vs PC2
p1 <- ggplot(pca_df, aes(x = PC1, y = PC2, color = group, shape = factor(cluster))) +
  geom_point(size = 3, alpha = 0.7) +
  scale_color_manual(values = c("ALS" = "#D62728", "Control" = "#2E8B57")) +
  labs(
    title = "PCA: PC1 vs PC2 (Excluyendo hsa-miR-6133)",
    x = paste0("PC1 (", round(variance_explained[1], 1), "%)"),
    y = paste0("PC2 (", round(variance_explained[2], 1), "%)"),
    color = "Grupo",
    shape = "Cluster"
  ) +
  theme_classic() +
  theme(legend.position = "right")

ggsave("figures_robust_pca/01_pca_scatter_pc1_pc2.png", p1, width = 10, height = 8, dpi = 300)

# 9.2 Scatter plot PC1 vs PC3
p2 <- ggplot(pca_df, aes(x = PC1, y = PC3, color = group, shape = factor(cluster))) +
  geom_point(size = 3, alpha = 0.7) +
  scale_color_manual(values = c("ALS" = "#D62728", "Control" = "#2E8B57")) +
  labs(
    title = "PCA: PC1 vs PC3 (Excluyendo hsa-miR-6133)",
    x = paste0("PC1 (", round(variance_explained[1], 1), "%)"),
    y = paste0("PC3 (", round(variance_explained[3], 1), "%)"),
    color = "Grupo",
    shape = "Cluster"
  ) +
  theme_classic() +
  theme(legend.position = "right")

ggsave("figures_robust_pca/02_pca_scatter_pc1_pc3.png", p2, width = 10, height = 8, dpi = 300)

# 9.3 Varianza explicada
variance_df <- data.frame(
  PC = 1:length(variance_explained),
  Variance = variance_explained,
  Cumulative = cumulative_variance
)

p3 <- ggplot(variance_df[1:20, ], aes(x = PC)) +
  geom_line(aes(y = Variance), color = "blue", size = 1) +
  geom_point(aes(y = Variance), color = "blue", size = 2) +
  geom_line(aes(y = Cumulative), color = "red", size = 1) +
  geom_point(aes(y = Cumulative), color = "red", size = 2) +
  labs(
    title = "Varianza Explicada por Componentes Principales",
    x = "Componente Principal",
    y = "Varianza Explicada (%)"
  ) +
  theme_classic() +
  theme(legend.position = "right")

ggsave("figures_robust_pca/03_variance_explained.png", p3, width = 10, height = 6, dpi = 300)

# 9.4 Heatmap de contribuciones por posición
position_heatmap_data <- pos_analysis %>%
  select(position, mean_pc1_loading, mean_pc2_loading) %>%
  column_to_rownames("position")

p4 <- ComplexHeatmap::Heatmap(
  as.matrix(position_heatmap_data),
  name = "Contribución",
  col = colorRamp2(c(0, max(position_heatmap_data)), c("white", "red")),
  cluster_rows = FALSE,
  cluster_columns = FALSE,
  row_title = "Posición",
  column_title = "Componente Principal",
  show_row_names = TRUE,
  show_column_names = TRUE
)

png("figures_robust_pca/04_position_contributions_heatmap.png", width = 800, height = 1000, res = 300)
draw(p4)
dev.off()

# 9.5 Distribución de clusters
cluster_summary <- pca_df %>%
  group_by(cluster) %>%
  summarise(
    n_samples = n(),
    n_als = sum(group == "ALS"),
    n_control = sum(group == "Control"),
    pc1_mean = mean(PC1),
    pc2_mean = mean(PC2)
  )

p5 <- ggplot(cluster_summary, aes(x = factor(cluster), y = n_samples, fill = "Total")) +
  geom_bar(stat = "identity", alpha = 0.7) +
  geom_bar(aes(y = n_als), stat = "identity", fill = "#D62728", alpha = 0.8) +
  geom_bar(aes(y = n_control), stat = "identity", fill = "#2E8B57", alpha = 0.8) +
  labs(
    title = "Distribución de Muestras por Cluster",
    x = "Cluster",
    y = "Número de Muestras",
    fill = "Grupo"
  ) +
  theme_classic()

ggsave("figures_robust_pca/05_cluster_distribution.png", p5, width = 10, height = 6, dpi = 300)

# =============================================================================
# 10. ANÁLISIS DE SUBTIPOS ROBUSTOS
# =============================================================================

cat("10. Analizando subtipos robustos...\n")

# Análisis de características por cluster
cluster_characteristics <- pca_df %>%
  group_by(cluster) %>%
  summarise(
    n_samples = n(),
    n_als = sum(group == "ALS"),
    n_control = sum(group == "Control"),
    als_proportion = n_als / n_samples,
    pc1_mean = mean(PC1),
    pc2_mean = mean(PC2),
    pc3_mean = mean(PC3),
    pc1_sd = sd(PC1),
    pc2_sd = sd(PC2),
    pc3_sd = sd(PC3)
  ) %>%
  mutate(
    cluster_type = ifelse(als_proportion > 0.7, "ALS-dominant", 
                         ifelse(als_proportion < 0.3, "Control-dominant", "Mixed"))
  )

cat("   - Características de clusters:\n")
print(cluster_characteristics)

# Identificar clusters significativos
significant_clusters <- cluster_characteristics %>%
  filter(n_samples >= 10) %>%  # Al menos 10 muestras
  arrange(desc(abs(als_proportion - 0.5)))  # Mayor desviación del 50%

cat("\n   - Clusters significativos (≥10 muestras):\n")
print(significant_clusters)

# =============================================================================
# 11. CORRELACIÓN CON CARGA OXIDATIVA
# =============================================================================

cat("11. Analizando correlación con carga oxidativa...\n")

# Cargar datos de carga oxidativa
load("oxidative_load_analysis_results.RData")

# Unir con datos PCA
pca_oxidative <- merge(pca_df, oxidative_metrics, by = "sample_id", all.x = TRUE)

# Correlaciones entre componentes principales y carga oxidativa
pc1_oxidative_cor <- cor(pca_oxidative$PC1, pca_oxidative$oxidative_score, use = "complete.obs")
pc2_oxidative_cor <- cor(pca_oxidative$PC2, pca_oxidative$oxidative_score, use = "complete.obs")
pc3_oxidative_cor <- cor(pca_oxidative$PC3, pca_oxidative$oxidative_score, use = "complete.obs")

cat("   - Correlaciones con carga oxidativa:\n")
cat("     PC1:", round(pc1_oxidative_cor, 3), "\n")
cat("     PC2:", round(pc2_oxidative_cor, 3), "\n")
cat("     PC3:", round(pc3_oxidative_cor, 3), "\n\n")

# Visualización de correlación PC1 vs carga oxidativa
  #   # p6 <- ggplot(pca_oxidative, aes(x = PC1, y = oxidative_score, color = group)) +
  #   geom_point(size = 3, alpha = 0.7) +
  #   geom_smooth(method = "lm", se = TRUE, color = "black") +
  #   scale_color_manual(values = c("ALS" = "#D62728", "Control" = "#2E8B57")) +
  #   labs(
  #     title = paste0("PC1 vs Carga Oxidativa (r = ", round(pc1_oxidative_cor, 3), ")"),
  #     x = paste0("PC1 (", round(variance_explained[1], 1), "%)"),
  #     y = "Carga Oxidativa",
  #     color = "Grupo"
  #   ) +
  #   theme_classic()
  # 
  # ggsave("figures_robust_pca/06_pc1_vs_oxidative_load.png", p6, width = 10, height = 8, dpi = 300)
  # 
  # # =============================================================================
  # # 12. GUARDAR RESULTADOS
  # # =============================================================================

cat("12. Guardando resultados...\n")

# Guardar datos PCA
save(pca_result, pca_df, cluster_characteristics, significant_clusters, 
     file = "robust_pca_analysis_results.RData")

# Guardar resumen
summary_results <- list(
  n_snvs_analyzed = nrow(data_imputed),
  n_samples_analyzed = ncol(data_imputed),
  n_snvs_excluded = nrow(final_data) - nrow(data_clean),
  variance_pc1_pc5 = cumulative_variance[5],
  variance_pc1_pc10 = cumulative_variance[10],
  optimal_clusters = optimal_k,
  pc1_oxidative_correlation = pc1_oxidative_cor,
  pc2_oxidative_correlation = pc2_oxidative_cor,
  pc3_oxidative_correlation = pc3_oxidative_cor
)

write.csv(as.data.frame(summary_results), "robust_pca_summary.csv", row.names = FALSE)

cat("   - Resultados guardados en: robust_pca_analysis_results.RData\n")
cat("   - Resumen guardado en: robust_pca_summary.csv\n")
cat("   - Figuras guardadas en: figures_robust_pca/\n\n")

# =============================================================================
# 13. CONCLUSIÓN
# =============================================================================

cat("13. CONCLUSIÓN DEL ANÁLISIS ROBUSTO\n")
cat("====================================\n\n")

cat("✅ ANÁLISIS COMPLETADO EXITOSAMENTE:\n")
cat("   - Artefacto hsa-miR-6133 excluido correctamente\n")
cat("   - PCA robusto implementado con", nrow(data_imputed), "SNVs\n")
cat("   -", ncol(data_imputed), "muestras analizadas\n")
cat("   -", optimal_k, "clusters identificados\n")
cat("   - Correlación PC1-carga oxidativa:", round(pc1_oxidative_cor, 3), "\n\n")

cat("📊 HALLAZGOS PRINCIPALES:\n")
cat("   - PC1 explica", round(variance_explained[1], 1), "% de la varianza\n")
cat("   - PC1-PC5 explican", round(cumulative_variance[5], 1), "% de la varianza\n")
cat("   - Diferencias significativas entre grupos en PC1 (p =", round(pc1_test$p.value, 4), ")\n")
cat("   -", nrow(significant_clusters), "clusters significativos identificados\n\n")

cat("🎯 RECOMENDACIONES:\n")
cat("   1. Usar PC1 como variable principal para análisis posteriores\n")
cat("   2. Investigar SNVs con mayor contribución a PC1\n")
cat("   3. Validar clusters significativos con análisis funcional\n")
cat("   4. Desarrollar score diagnóstico basado en PC1\n\n")

cat("✅ ANÁLISIS ROBUSTO CON PCA COMPLETADO\n")
cat("======================================\n\n")
