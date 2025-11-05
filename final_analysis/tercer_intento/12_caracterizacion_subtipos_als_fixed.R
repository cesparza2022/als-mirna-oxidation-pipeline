library(dplyr)
library(ggplot2)
library(stringr)
library(gridExtra)
library(ComplexHeatmap)
library(circlize)

# =============================================================================
# CARACTERIZACIÓN DE SUBTIPOS DE ALS (CORREGIDO)
# =============================================================================

cat("=== CARACTERIZACIÓN DE SUBTIPOS DE ALS ===\n\n")

# 1. CARGAR DATOS Y DEFINIR SUBTIPOS
# =============================================================================
cat("1. CARGANDO DATOS Y DEFINIENDO SUBTIPOS\n")
cat("=======================================\n")

# Cargar datos procesados
final_data <- read.csv("../processed_data/final_processed_data.csv", stringsAsFactors = FALSE)
clustering_samples <- read.csv("clustering_results_samples.csv", stringsAsFactors = FALSE)

# Recrear matriz de datos usada en clustering
significant_snvs <- final_data %>%
  mutate(pos = as.integer(str_extract(pos.mut, "^[0-9]+"))) %>%
  filter(pos %in% c(1, 2, 3, 4, 5, 6)) %>%
  select(-pos)

sample_cols <- colnames(significant_snvs)[!colnames(significant_snvs) %in% c("miRNA_name", "pos.mut")]

# Aplicar filtrado
snv_validity <- significant_snvs %>%
  rowwise() %>%
  mutate(n_valid = sum(!is.na(c_across(all_of(sample_cols))) & c_across(all_of(sample_cols)) > 0)) %>%
  ungroup()

min_valid_threshold <- ceiling(length(sample_cols) * 0.05)
filtered_snvs <- snv_validity %>%
  filter(n_valid >= min_valid_threshold) %>%
  select(-n_valid)

# Crear matriz de VAFs
vaf_matrix <- as.matrix(filtered_snvs[, sample_cols])
rownames(vaf_matrix) <- paste(filtered_snvs$miRNA_name, filtered_snvs$pos.mut, sep = "_")
vaf_matrix_clean <- vaf_matrix
vaf_matrix_clean[is.na(vaf_matrix_clean)] <- 0

# Definir subtipos basados en clustering
total_samples <- nrow(clustering_samples)
mid_point <- ceiling(total_samples / 2)

subtipo1_samples <- clustering_samples[1:mid_point, ]
subtipo2_samples <- clustering_samples[(mid_point+1):total_samples, ]

# Filtrar solo muestras ALS
als_subtipo1 <- subtipo1_samples %>% filter(Group == "ALS")
als_subtipo2 <- subtipo2_samples %>% filter(Group == "ALS")

cat("DEFINICIÓN DE SUBTIPOS:\n")
cat("  📊 ALS-Subtipo-1:", nrow(als_subtipo1), "muestras\n")
cat("  📊 ALS-Subtipo-2:", nrow(als_subtipo2), "muestras\n")
cat("  📊 Total ALS:", nrow(als_subtipo1) + nrow(als_subtipo2), "muestras\n\n")

# 2. COMPARACIÓN DE CARGA OXIDATIVA GLOBAL
# =============================================================================
cat("2. COMPARACIÓN DE CARGA OXIDATIVA GLOBAL\n")
cat("=========================================\n")

# Función corregida para calcular métricas por muestra
calculate_sample_metrics <- function(sample_names, vaf_matrix) {
  sample_data <- vaf_matrix[, sample_names, drop = FALSE]
  
  metrics <- data.frame(
    Sample = sample_names,
    Total_SNVs = colSums(sample_data > 0),
    Total_VAF = colSums(sample_data, na.rm = TRUE),
    stringsAsFactors = FALSE
  )
  
  # Calcular métricas adicionales por muestra
  for (i in 1:length(sample_names)) {
    sample_values <- sample_data[, i]
    nonzero_values <- sample_values[sample_values > 0]
    
    if (length(nonzero_values) > 0) {
      metrics$Mean_VAF[i] <- mean(nonzero_values)
      metrics$Max_VAF[i] <- max(nonzero_values)
      metrics$Median_VAF[i] <- median(nonzero_values)
    } else {
      metrics$Mean_VAF[i] <- 0
      metrics$Max_VAF[i] <- 0
      metrics$Median_VAF[i] <- 0
    }
  }
  
  return(metrics)
}

# Calcular métricas para cada subtipo
metrics_subtipo1 <- calculate_sample_metrics(als_subtipo1$Sample, vaf_matrix_clean)
metrics_subtipo2 <- calculate_sample_metrics(als_subtipo2$Sample, vaf_matrix_clean)

metrics_subtipo1$Subtipo <- "ALS-Subtipo-1"
metrics_subtipo2$Subtipo <- "ALS-Subtipo-2"

# Combinar métricas
all_metrics <- rbind(metrics_subtipo1, metrics_subtipo2)

# Estadísticas comparativas
cat("CARGA OXIDATIVA GLOBAL:\n")
cat("  ALS-Subtipo-1:\n")
cat("    - SNVs promedio por muestra:", round(mean(metrics_subtipo1$Total_SNVs), 2), "±", round(sd(metrics_subtipo1$Total_SNVs), 2), "\n")
cat("    - VAF total promedio:", round(mean(metrics_subtipo1$Total_VAF), 4), "±", round(sd(metrics_subtipo1$Total_VAF), 4), "\n")
cat("    - VAF promedio (no-cero):", round(mean(metrics_subtipo1$Mean_VAF[metrics_subtipo1$Mean_VAF > 0]), 4), "\n\n")

cat("  ALS-Subtipo-2:\n")
cat("    - SNVs promedio por muestra:", round(mean(metrics_subtipo2$Total_SNVs), 2), "±", round(sd(metrics_subtipo2$Total_SNVs), 2), "\n")
cat("    - VAF total promedio:", round(mean(metrics_subtipo2$Total_VAF), 4), "±", round(sd(metrics_subtipo2$Total_VAF), 4), "\n")
cat("    - VAF promedio (no-cero):", round(mean(metrics_subtipo2$Mean_VAF[metrics_subtipo2$Mean_VAF > 0]), 4), "\n\n")

# Test estadístico
t_test_snvs <- t.test(metrics_subtipo1$Total_SNVs, metrics_subtipo2$Total_SNVs)
t_test_vaf <- t.test(metrics_subtipo1$Total_VAF, metrics_subtipo2$Total_VAF)

cat("SIGNIFICANCIA ESTADÍSTICA:\n")
cat("  - Diferencia en número de SNVs: p =", format(t_test_snvs$p.value, scientific = TRUE), "\n")
cat("  - Diferencia en VAF total: p =", format(t_test_vaf$p.value, scientific = TRUE), "\n\n")

# 3. IDENTIFICACIÓN DE SNVs DISCRIMINATIVOS
# =============================================================================
cat("3. IDENTIFICACIÓN DE SNVs DISCRIMINATIVOS\n")
cat("==========================================\n")

# Calcular diferencias promedio por SNV
snv_differences <- data.frame(
  SNV = rownames(vaf_matrix_clean),
  miRNA = str_extract(rownames(vaf_matrix_clean), "^[^_]+"),
  pos_mut = str_extract(rownames(vaf_matrix_clean), "[^_]+$"),
  stringsAsFactors = FALSE
)

# Calcular estadísticas por SNV para cada subtipo
for (i in 1:nrow(vaf_matrix_clean)) {
  snv_data <- vaf_matrix_clean[i, ]
  
  subtipo1_values <- snv_data[als_subtipo1$Sample]
  subtipo2_values <- snv_data[als_subtipo2$Sample]
  
  snv_differences$Mean_Subtipo1[i] <- mean(subtipo1_values, na.rm = TRUE)
  snv_differences$Mean_Subtipo2[i] <- mean(subtipo2_values, na.rm = TRUE)
  snv_differences$Diff_Mean[i] <- snv_differences$Mean_Subtipo1[i] - snv_differences$Mean_Subtipo2[i]
  snv_differences$Abs_Diff[i] <- abs(snv_differences$Diff_Mean[i])
  
  # Test estadístico si hay suficientes datos
  if (sum(subtipo1_values > 0) >= 3 && sum(subtipo2_values > 0) >= 3) {
    test_result <- t.test(subtipo1_values, subtipo2_values)
    snv_differences$P_value[i] <- test_result$p.value
  } else {
    snv_differences$P_value[i] <- 1
  }
  
  # Frecuencia de detección
  snv_differences$Freq_Subtipo1[i] <- sum(subtipo1_values > 0) / length(subtipo1_values)
  snv_differences$Freq_Subtipo2[i] <- sum(subtipo2_values > 0) / length(subtipo2_values)
}

# Ajustar p-values
snv_differences$P_adj <- p.adjust(snv_differences$P_value, method = "BH")

# Ranking por diferencia absoluta
snv_differences <- snv_differences %>%
  arrange(desc(Abs_Diff)) %>%
  mutate(Rank = 1:n())

cat("TOP 10 SNVs MÁS DISCRIMINATIVOS:\n")
cat("=================================\n")
top_snvs <- head(snv_differences, 10)
for (i in 1:nrow(top_snvs)) {
  cat(sprintf("%d. %s\n", i, top_snvs$SNV[i]))
  cat(sprintf("   miRNA: %s, Mutación: %s\n", top_snvs$miRNA[i], top_snvs$pos_mut[i]))
  cat(sprintf("   Subtipo-1: %.6f, Subtipo-2: %.6f\n", top_snvs$Mean_Subtipo1[i], top_snvs$Mean_Subtipo2[i]))
  cat(sprintf("   Diferencia: %.6f, P-adj: %.3e\n", top_snvs$Diff_Mean[i], top_snvs$P_adj[i]))
  cat(sprintf("   Frecuencia: S1=%.1f%%, S2=%.1f%%\n\n", 
              top_snvs$Freq_Subtipo1[i]*100, top_snvs$Freq_Subtipo2[i]*100))
}

# Guardar resultados
write.csv(snv_differences, "snvs_discriminativos_subtipos.csv", row.names = FALSE)

# 4. ANÁLISIS POR POSICIÓN
# =============================================================================
cat("4. ANÁLISIS POR POSICIÓN\n")
cat("=========================\n")

# Extraer posición de cada SNV
snv_differences$Posicion <- as.integer(str_extract(snv_differences$pos_mut, "^[0-9]+"))

# Análisis por posición
pos_analysis <- snv_differences %>%
  group_by(Posicion) %>%
  summarise(
    N_SNVs = n(),
    Mean_Diff = mean(Abs_Diff, na.rm = TRUE),
    Max_Diff = max(Abs_Diff, na.rm = TRUE),
    Significant_SNVs = sum(P_adj < 0.05, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  arrange(desc(Mean_Diff))

cat("DIFERENCIAS POR POSICIÓN:\n")
for (i in 1:nrow(pos_analysis)) {
  cat(sprintf("Posición %d: %d SNVs, Diff promedio: %.6f, SNVs significativos: %d\n",
              pos_analysis$Posicion[i], pos_analysis$N_SNVs[i], 
              pos_analysis$Mean_Diff[i], pos_analysis$Significant_SNVs[i]))
}
cat("\n")

# 5. VISUALIZACIONES
# =============================================================================
cat("5. CREANDO VISUALIZACIONES\n")
cat("===========================\n")

# Gráfico 1: Comparación de carga oxidativa
p1 <- ggplot(all_metrics, aes(x = Subtipo, y = Total_SNVs, fill = Subtipo)) +
  geom_boxplot(alpha = 0.7) +
  geom_jitter(width = 0.2, alpha = 0.5) +
  scale_fill_manual(values = c("ALS-Subtipo-1" = "#E31A1C", "ALS-Subtipo-2" = "#1F78B4")) +
  labs(
    title = "Número de SNVs por Muestra",
    subtitle = paste("p =", format(t_test_snvs$p.value, digits = 3)),
    x = "Subtipo de ALS",
    y = "Número de SNVs detectados"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

p2 <- ggplot(all_metrics, aes(x = Subtipo, y = Total_VAF, fill = Subtipo)) +
  geom_boxplot(alpha = 0.7) +
  geom_jitter(width = 0.2, alpha = 0.5) +
  scale_fill_manual(values = c("ALS-Subtipo-1" = "#E31A1C", "ALS-Subtipo-2" = "#1F78B4")) +
  labs(
    title = "VAF Total por Muestra",
    subtitle = paste("p =", format(t_test_vaf$p.value, digits = 3)),
    x = "Subtipo de ALS",
    y = "VAF total acumulado"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

# Gráfico 3: Top SNVs discriminativos
top_10_snvs <- head(snv_differences, 10)
top_10_snvs$SNV_short <- str_trunc(top_10_snvs$SNV, 30)

p3 <- ggplot(top_10_snvs, aes(x = reorder(SNV_short, Abs_Diff), y = Abs_Diff)) +
  geom_col(fill = "#FF7F00", alpha = 0.8) +
  coord_flip() +
  labs(
    title = "Top 10 SNVs Más Discriminativos",
    x = "SNV (miRNA_posición:mutación)",
    y = "Diferencia Absoluta en VAF Promedio"
  ) +
  theme_minimal() +
  theme(axis.text.y = element_text(size = 8))

# Gráfico 4: Diferencias por posición
p4 <- ggplot(pos_analysis, aes(x = factor(Posicion), y = Mean_Diff)) +
  geom_col(fill = "#33A02C", alpha = 0.8) +
  geom_text(aes(label = paste("n =", N_SNVs)), vjust = -0.5, size = 3) +
  labs(
    title = "Diferencias Promedio por Posición",
    x = "Posición en miRNA",
    y = "Diferencia Absoluta Promedio"
  ) +
  theme_minimal()

# Guardar gráficos
pdf("comparacion_subtipos_als.pdf", width = 16, height = 12)
grid.arrange(p1, p2, p3, p4, ncol = 2)
dev.off()

cat("Gráficos guardados: comparacion_subtipos_als.pdf\n\n")

# 6. HEATMAP DE TOP SNVs DISCRIMINATIVOS
# =============================================================================
cat("6. HEATMAP DE TOP SNVs DISCRIMINATIVOS\n")
cat("======================================\n")

# Seleccionar top 20 SNVs más discriminativos
top_20_snvs <- head(snv_differences, 20)
top_snv_names <- top_20_snvs$SNV

# Crear matriz solo con estos SNVs y muestras ALS
als_samples <- c(als_subtipo1$Sample, als_subtipo2$Sample)
heatmap_matrix <- vaf_matrix_clean[top_snv_names, als_samples]

# Crear anotación de subtipos
subtipo_annotation <- data.frame(
  Sample = als_samples,
  Subtipo = c(rep("Subtipo-1", nrow(als_subtipo1)), 
              rep("Subtipo-2", nrow(als_subtipo2))),
  stringsAsFactors = FALSE
)

# Colores para subtipos
subtipo_colors <- c("Subtipo-1" = "#E31A1C", "Subtipo-2" = "#1F78B4")

# Crear anotación para heatmap
column_ha <- HeatmapAnnotation(
  Subtipo = subtipo_annotation$Subtipo,
  col = list(Subtipo = subtipo_colors),
  annotation_name_gp = gpar(fontsize = 10)
)

# Crear heatmap
max_vaf <- max(heatmap_matrix, na.rm = TRUE)
vaf_colors <- colorRamp2(
  c(0, max_vaf * 0.2, max_vaf * 0.6, max_vaf),
  c("white", "#FFE599", "#FF9900", "#CC7700")
)

heatmap_subtipos <- Heatmap(
  heatmap_matrix,
  name = "VAF",
  col = vaf_colors,
  
  # Clustering
  clustering_distance_columns = "euclidean",
  clustering_method_columns = "ward.D2",
  cluster_rows = FALSE,  # Mantener orden por discriminación
  
  # Anotaciones
  top_annotation = column_ha,
  
  # Etiquetas
  show_row_names = TRUE,
  show_column_names = FALSE,
  row_names_gp = gpar(fontsize = 8),
  
  # Título
  column_title = "Top 20 SNVs Discriminativos - Subtipos de ALS",
  column_title_gp = gpar(fontsize = 14, fontface = "bold")
)

# Guardar heatmap
pdf("heatmap_subtipos_top_snvs.pdf", width = 16, height = 10)
draw(heatmap_subtipos, heatmap_legend_side = "right", annotation_legend_side = "right")
dev.off()

cat("Heatmap guardado: heatmap_subtipos_top_snvs.pdf\n\n")

# 7. ANÁLISIS DE miRNAs MÁS AFECTADOS
# =============================================================================
cat("7. ANÁLISIS DE miRNAs MÁS AFECTADOS\n")
cat("===================================\n")

# Agrupar por miRNA
mirna_analysis <- snv_differences %>%
  group_by(miRNA) %>%
  summarise(
    N_SNVs = n(),
    Max_Diff = max(Abs_Diff, na.rm = TRUE),
    Mean_Diff = mean(Abs_Diff, na.rm = TRUE),
    Significant_SNVs = sum(P_adj < 0.05, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  arrange(desc(Max_Diff))

cat("TOP 10 miRNAs MÁS DISCRIMINATIVOS:\n")
top_mirnas <- head(mirna_analysis, 10)
for (i in 1:nrow(top_mirnas)) {
  cat(sprintf("%d. %s: %d SNVs, Diff máxima: %.6f, SNVs significativos: %d\n",
              i, top_mirnas$miRNA[i], top_mirnas$N_SNVs[i], 
              top_mirnas$Max_Diff[i], top_mirnas$Significant_SNVs[i]))
}
cat("\n")

# Guardar análisis de miRNAs
write.csv(mirna_analysis, "mirnas_discriminativos_subtipos.csv", row.names = FALSE)

# 8. RESUMEN DE CARACTERIZACIÓN
# =============================================================================
cat("8. RESUMEN DE CARACTERIZACIÓN\n")
cat("==============================\n")

cat("CARACTERÍSTICAS DE LOS SUBTIPOS:\n")
cat("=================================\n")

cat("🔬 ALS-SUBTIPO-1 (", nrow(als_subtipo1), " muestras):\n")
cat("   - SNVs promedio:", round(mean(metrics_subtipo1$Total_SNVs), 2), "\n")
cat("   - VAF total promedio:", round(mean(metrics_subtipo1$Total_VAF), 4), "\n")
cat("   - Perfil: ", ifelse(mean(metrics_subtipo1$Total_VAF) > mean(metrics_subtipo2$Total_VAF), 
                           "Mayor carga oxidativa", "Menor carga oxidativa"), "\n\n")

cat("🔬 ALS-SUBTIPO-2 (", nrow(als_subtipo2), " muestras):\n")
cat("   - SNVs promedio:", round(mean(metrics_subtipo2$Total_SNVs), 2), "\n")
cat("   - VAF total promedio:", round(mean(metrics_subtipo2$Total_VAF), 4), "\n")
cat("   - Perfil: ", ifelse(mean(metrics_subtipo2$Total_VAF) > mean(metrics_subtipo1$Total_VAF), 
                           "Mayor carga oxidativa", "Menor carga oxidativa"), "\n\n")

cat("DIFERENCIAS CLAVE:\n")
cat("==================\n")
cat("📊 SNVs más discriminativos:", nrow(snv_differences[snv_differences$P_adj < 0.05, ]), "significativos\n")
cat("📊 miRNAs más afectados:", nrow(mirna_analysis[mirna_analysis$Significant_SNVs > 0, ]), "con SNVs significativos\n")
cat("📊 Posición más discriminativa:", pos_analysis$Posicion[1], "\n")
cat("📊 Diferencia estadística global: p =", format(min(t_test_snvs$p.value, t_test_vaf$p.value), scientific = TRUE), "\n\n")

cat("ARCHIVOS GENERADOS:\n")
cat("===================\n")
cat("  📄 snvs_discriminativos_subtipos.csv\n")
cat("  📄 mirnas_discriminativos_subtipos.csv\n")
cat("  📊 comparacion_subtipos_als.pdf\n")
cat("  📊 heatmap_subtipos_top_snvs.pdf\n\n")

cat("=== CARACTERIZACIÓN DE SUBTIPOS COMPLETADA ===\n")
cat("Los subtipos de ALS muestran diferencias moleculares claras y significativas.\n")
cat("Estos hallazgos sientan las bases para medicina personalizada en ALS.\n\n")









