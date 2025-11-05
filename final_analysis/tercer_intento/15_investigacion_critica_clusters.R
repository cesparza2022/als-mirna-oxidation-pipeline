library(dplyr)
library(ggplot2)
library(stringr)
library(ComplexHeatmap)
library(circlize)
library(corrplot)

# =============================================================================
# INVESTIGACIÓN CRÍTICA DE CLUSTERS - ¿ES SOLO UN SNV?
# =============================================================================

cat("=== INVESTIGACIÓN CRÍTICA DE CLUSTERS ===\n\n")

# 1. CARGAR DATOS Y RECREAR ANÁLISIS
# =============================================================================
cat("1. ANÁLISIS CRÍTICO DEL CLUSTERING\n")
cat("===================================\n")

# Cargar datos
final_data <- read.csv("../processed_data/final_processed_data.csv", stringsAsFactors = FALSE)
snv_comparison <- read.csv("comparacion_clusters_detallada.csv", stringsAsFactors = FALSE)

# Recrear matriz
significant_snvs <- final_data %>%
  mutate(pos = as.integer(str_extract(pos.mut, "^[0-9]+"))) %>%
  filter(pos %in% c(1, 2, 3, 4, 5, 6)) %>%
  select(-pos)

sample_cols <- colnames(significant_snvs)[!colnames(significant_snvs) %in% c("miRNA_name", "pos.mut")]

snv_validity <- significant_snvs %>%
  rowwise() %>%
  mutate(n_valid = sum(!is.na(c_across(all_of(sample_cols))) & c_across(all_of(sample_cols)) > 0)) %>%
  ungroup()

min_valid_threshold <- ceiling(length(sample_cols) * 0.05)
filtered_snvs <- snv_validity %>%
  filter(n_valid >= min_valid_threshold) %>%
  select(-n_valid)

vaf_matrix <- as.matrix(filtered_snvs[, sample_cols])
rownames(vaf_matrix) <- paste(filtered_snvs$miRNA_name, filtered_snvs$pos.mut, sep = "_")
vaf_matrix_clean <- vaf_matrix
vaf_matrix_clean[is.na(vaf_matrix_clean)] <- 0

cat("MATRIZ ANALIZADA:\n")
cat("  - SNVs:", nrow(vaf_matrix_clean), "\n")
cat("  - Muestras:", ncol(vaf_matrix_clean), "\n\n")

# 2. ANÁLISIS DEL SNV DOMINANTE
# =============================================================================
cat("2. ANÁLISIS DEL SNV DOMINANTE: hsa-miR-6133_6:GT\n")
cat("=================================================\n")

# Extraer datos del SNV dominante
dominant_snv <- "hsa-miR-6133_6:GT"
dominant_values <- vaf_matrix_clean[dominant_snv, ]

# Estadísticas del SNV dominante
cat("ESTADÍSTICAS DEL SNV DOMINANTE:\n")
cat("  - Muestras con VAF > 0:", sum(dominant_values > 0), "/", length(dominant_values), 
    "(", round(sum(dominant_values > 0) / length(dominant_values) * 100, 1), "%)\n")
cat("  - VAF mínimo (>0):", min(dominant_values[dominant_values > 0]), "\n")
cat("  - VAF máximo:", max(dominant_values), "\n")
cat("  - VAF mediano (>0):", median(dominant_values[dominant_values > 0]), "\n")
cat("  - VAF promedio (>0):", mean(dominant_values[dominant_values > 0]), "\n\n")

# Distribución de valores
high_vaf_samples <- names(dominant_values[dominant_values > 0.1])
medium_vaf_samples <- names(dominant_values[dominant_values > 0.01 & dominant_values <= 0.1])
low_vaf_samples <- names(dominant_values[dominant_values > 0 & dominant_values <= 0.01])
zero_vaf_samples <- names(dominant_values[dominant_values == 0])

cat("DISTRIBUCIÓN DE VAFs:\n")
cat("  - VAF > 0.1 (alto):", length(high_vaf_samples), "muestras\n")
cat("  - VAF 0.01-0.1 (medio):", length(medium_vaf_samples), "muestras\n")
cat("  - VAF 0-0.01 (bajo):", length(low_vaf_samples), "muestras\n")
cat("  - VAF = 0:", length(zero_vaf_samples), "muestras\n\n")

# 3. ¿EL CLUSTERING SE BASA SOLO EN ESTE SNV?
# =============================================================================
cat("3. ¿EL CLUSTERING SE BASA SOLO EN ESTE SNV?\n")
cat("============================================\n")

# Recrear clustering
sample_distances <- dist(t(vaf_matrix_clean), method = "euclidean")
hclust_result <- hclust(sample_distances, method = "ward.D2")
cluster_assignments <- cutree(hclust_result, k = 2)

# Comparar clustering con presencia del SNV dominante
cluster_df <- data.frame(
  Sample = names(cluster_assignments),
  Cluster = cluster_assignments,
  Dominant_VAF = dominant_values[names(cluster_assignments)],
  Has_Dominant = dominant_values[names(cluster_assignments)] > 0,
  stringsAsFactors = FALSE
)

# Tabla de contingencia
contingency_table <- table(cluster_df$Cluster, cluster_df$Has_Dominant)
cat("TABLA DE CONTINGENCIA (Cluster vs Presencia SNV dominante):\n")
print(contingency_table)
cat("\n")

# Calcular concordancia
total_samples <- nrow(cluster_df)
concordant_samples <- sum(
  (cluster_df$Cluster == 1 & cluster_df$Has_Dominant) |
  (cluster_df$Cluster == 2 & !cluster_df$Has_Dominant)
)
concordance <- concordant_samples / total_samples

cat("CONCORDANCIA CLUSTERING vs SNV DOMINANTE:\n")
cat("  - Muestras concordantes:", concordant_samples, "/", total_samples, "\n")
cat("  - Porcentaje de concordancia:", round(concordance * 100, 1), "%\n\n")

# Test de Fisher para independencia
fisher_test <- fisher.test(contingency_table)
cat("TEST DE FISHER (independencia):\n")
cat("  - p-value:", format(fisher_test$p.value, scientific = TRUE), "\n")
cat("  - Odds ratio:", round(fisher_test$estimate, 2), "\n\n")

# 4. CLUSTERING SIN EL SNV DOMINANTE
# =============================================================================
cat("4. CLUSTERING SIN EL SNV DOMINANTE\n")
cat("===================================\n")

# Crear matriz sin el SNV dominante
vaf_matrix_no_dominant <- vaf_matrix_clean[rownames(vaf_matrix_clean) != dominant_snv, ]

cat("MATRIZ SIN SNV DOMINANTE:\n")
cat("  - SNVs restantes:", nrow(vaf_matrix_no_dominant), "\n")
cat("  - Sparsity:", round((1 - sum(vaf_matrix_no_dominant > 0) / length(vaf_matrix_no_dominant)) * 100, 2), "%\n\n")

# Clustering sin el SNV dominante
sample_distances_no_dom <- dist(t(vaf_matrix_no_dominant), method = "euclidean")
hclust_no_dom <- hclust(sample_distances_no_dom, method = "ward.D2")
cluster_no_dom <- cutree(hclust_no_dom, k = 2)

# Comparar clusterings
cluster_comparison <- data.frame(
  Sample = names(cluster_assignments),
  Original_Cluster = cluster_assignments,
  No_Dominant_Cluster = cluster_no_dom[names(cluster_assignments)],
  stringsAsFactors = FALSE
)

# Concordancia entre clusterings
cluster_concordance <- sum(cluster_comparison$Original_Cluster == cluster_comparison$No_Dominant_Cluster) / nrow(cluster_comparison)

cat("COMPARACIÓN DE CLUSTERINGS:\n")
cat("  - Concordancia entre clusterings:", round(cluster_concordance * 100, 1), "%\n")

# Tabla de contingencia entre clusterings
cluster_contingency <- table(cluster_comparison$Original_Cluster, cluster_comparison$No_Dominant_Cluster)
cat("  - Tabla de contingencia:\n")
print(cluster_contingency)
cat("\n")

# 5. ANÁLISIS DE OTROS SNVs DISCRIMINATIVOS
# =============================================================================
cat("5. ANÁLISIS DE OTROS SNVs DISCRIMINATIVOS\n")
cat("==========================================\n")

# Identificar otros SNVs con diferencias significativas
other_discriminative <- snv_comparison %>%
  filter(SNV != dominant_snv) %>%
  arrange(desc(Abs_VAF_Diff)) %>%
  head(10)

cat("TOP 10 SNVs MÁS DISCRIMINATIVOS (excluyendo dominante):\n")
for (i in 1:nrow(other_discriminative)) {
  snv <- other_discriminative$SNV[i]
  cat(sprintf("%d. %s\n", i, snv))
  cat(sprintf("   Diferencia VAF: %.6f\n", other_discriminative$Abs_VAF_Diff[i]))
  cat(sprintf("   Frecuencia C1: %.1f%%, C2: %.1f%%\n\n", 
              other_discriminative$Freq_C1[i] * 100,
              other_discriminative$Freq_C2[i] * 100))
}

# 6. ANÁLISIS DE CORRELACIONES ENTRE SNVs
# =============================================================================
cat("6. ANÁLISIS DE CORRELACIONES ENTRE SNVs\n")
cat("========================================\n")

# Seleccionar top SNVs para análisis de correlación
top_snvs <- c(dominant_snv, head(other_discriminative$SNV, 9))
correlation_matrix <- cor(t(vaf_matrix_clean[top_snvs, ]), method = "spearman")

cat("CORRELACIONES ENTRE TOP 10 SNVs:\n")
cat("  - Correlación promedio con SNV dominante:", 
    round(mean(correlation_matrix[dominant_snv, -which(rownames(correlation_matrix) == dominant_snv)]), 3), "\n")
cat("  - Correlación máxima con SNV dominante:", 
    round(max(correlation_matrix[dominant_snv, -which(rownames(correlation_matrix) == dominant_snv)]), 3), "\n")
cat("  - Correlación mínima con SNV dominante:", 
    round(min(correlation_matrix[dominant_snv, -which(rownames(correlation_matrix) == dominant_snv)]), 3), "\n\n")

# Guardar matriz de correlación
pdf("correlaciones_top_snvs.pdf", width = 12, height = 10)
corrplot(correlation_matrix, method = "color", type = "upper", 
         order = "hclust", tl.cex = 0.8, tl.col = "black")
title("Correlaciones entre Top 10 SNVs Discriminativos")
dev.off()

cat("Matriz de correlaciones guardada: correlaciones_top_snvs.pdf\n\n")

# 7. ANÁLISIS DE ROBUSTEZ DEL CLUSTERING
# =============================================================================
cat("7. ANÁLISIS DE ROBUSTEZ DEL CLUSTERING\n")
cat("=======================================\n")

# Clustering con diferentes números de clusters
silhouette_scores <- c()
for (k in 2:6) {
  clusters_k <- cutree(hclust_result, k = k)
  if (require(cluster, quietly = TRUE)) {
    sil <- silhouette(clusters_k, sample_distances)
    silhouette_scores[k-1] <- mean(sil[, 3])
  }
}

if (length(silhouette_scores) > 0) {
  cat("ANÁLISIS DE SILHOUETTE:\n")
  for (i in 1:length(silhouette_scores)) {
    cat(sprintf("  - k=%d: %.3f\n", i+1, silhouette_scores[i]))
  }
  cat("  - Mejor k:", which.max(silhouette_scores) + 1, "\n\n")
}

# 8. EVALUACIÓN CRÍTICA
# =============================================================================
cat("8. EVALUACIÓN CRÍTICA\n")
cat("======================\n")

cat("HALLAZGOS CRÍTICOS:\n")
cat("  🔍 Concordancia clustering vs SNV dominante:", round(concordance * 100, 1), "%\n")
cat("  🔍 Concordancia entre clusterings:", round(cluster_concordance * 100, 1), "%\n")
cat("  🔍 P-value independencia:", format(fisher_test$p.value, scientific = TRUE), "\n")
cat("  🔍 Otros SNVs discriminativos: diferencias <", round(max(other_discriminative$Abs_VAF_Diff), 6), "\n\n")

# Interpretación
if (concordance > 0.9) {
  cat("⚠️ ALERTA: EL CLUSTERING SE BASA PRINCIPALMENTE EN UN SOLO SNV\n")
  cat("   - Concordancia >90% indica dependencia casi total\n")
  cat("   - Los 'subtipos' son simplemente muestras con/sin esta mutación\n")
  cat("   - No hay evidencia de patrones moleculares complejos\n\n")
} else if (concordance > 0.7) {
  cat("⚠️ PRECAUCIÓN: EL CLUSTERING ESTÁ FUERTEMENTE INFLUENCIADO POR UN SNV\n")
  cat("   - Concordancia >70% indica dependencia significativa\n")
  cat("   - Otros SNVs contribuyen pero de manera menor\n")
  cat("   - Interpretar 'subtipos' con cautela\n\n")
} else {
  cat("✅ EL CLUSTERING REFLEJA PATRONES MÚLTIPLES\n")
  cat("   - Concordancia <70% indica múltiples factores\n")
  cat("   - Los subtipos son genuinamente complejos\n\n")
}

if (cluster_concordance < 0.6) {
  cat("✅ CLUSTERING ROBUSTO: Persiste sin el SNV dominante\n")
} else {
  cat("⚠️ CLUSTERING FRÁGIL: Cambia significativamente sin el SNV dominante\n")
}

# 9. RECOMENDACIONES
# =============================================================================
cat("\n9. RECOMENDACIONES\n")
cat("==================\n")

if (concordance > 0.8) {
  cat("🎯 RECOMENDACIONES CRÍTICAS:\n")
  cat("  1. NO interpretar como 'subtipos moleculares complejos'\n")
  cat("  2. Enfocar análisis en hsa-miR-6133 como biomarcador individual\n")
  cat("  3. Investigar por qué este miRNA específico está tan oxidado\n")
  cat("  4. Validar funcionalmente hsa-miR-6133 en ALS\n")
  cat("  5. Buscar otros métodos de estratificación más robustos\n\n")
  
  cat("📊 ANÁLISIS ALTERNATIVOS SUGERIDOS:\n")
  cat("  - Análisis de componentes principales (PCA)\n")
  cat("  - Clustering basado en perfiles de miRNAs (no SNVs individuales)\n")
  cat("  - Análisis de pathways en lugar de mutaciones puntuales\n")
  cat("  - Estratificación por carga oxidativa total\n\n")
} else {
  cat("✅ EL CLUSTERING ES VÁLIDO:\n")
  cat("  - Proceder con análisis de subtipos\n")
  cat("  - Investigar patrones moleculares complejos\n")
  cat("  - Validar biomarcadores múltiples\n\n")
}

cat("ARCHIVOS GENERADOS:\n")
cat("  📊 correlaciones_top_snvs.pdf\n\n")

cat("=== INVESTIGACIÓN CRÍTICA COMPLETADA ===\n")
cat("La validez del clustering ha sido evaluada objetivamente.\n\n")









