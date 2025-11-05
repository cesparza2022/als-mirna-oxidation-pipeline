# --- HEATMAPS SIMPLIFICADOS VERSIÓN 2 ---
# Análisis de patrones sin dependencias gráficas complejas

# --- LIBRERÍAS ---
library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(reshape2)
library(stats)

# --- CONFIGURACIÓN ---
cat("🔥 HEATMAPS SIMPLIFICADOS VERSIÓN 2\n")
cat("====================================\n\n")

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

# --- 3. ANÁLISIS DE Z-SCORES ---
cat("🔥 3. ANÁLISIS DE Z-SCORES\n")
cat("===========================\n")

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

cat(paste0("   - SNVs con z-score calculado: ", nrow(zscore_data), "\n"))
cat(paste0("   - Z-scores > 2: ", sum(abs(zscore_data$zscore) > 2, na.rm = TRUE), "\n"))
cat(paste0("   - Z-scores > 3: ", sum(abs(zscore_data$zscore) > 3, na.rm = TRUE), "\n\n"))

# Top 20 SNVs con mayor z-score
top_zscores <- zscore_data %>%
  arrange(desc(abs(zscore))) %>%
  head(20)

cat("   - Top 20 SNVs con mayor z-score:\n")
print(top_zscores %>% select(snv_id, zscore, mean_diff))
cat("\n")

# --- 4. ANÁLISIS POR POSICIÓN ---
cat("🔥 4. ANÁLISIS POR POSICIÓN\n")
cat("=============================\n")

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

# --- 5. ANÁLISIS DE CLUSTERS ---
cat("🔥 5. ANÁLISIS DE CLUSTERS\n")
cat("===========================\n")

# Clustering jerárquico de muestras
dist_samples <- dist(vaf_matrix_matrix)
hc_samples <- hclust(dist_samples, method = "ward.D2")

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

# --- 6. ANÁLISIS DE miRNAs DIFERENCIALES ---
cat("🔥 6. ANÁLISIS DE miRNAs DIFERENCIALES\n")
cat("=======================================\n")

# Resumen por miRNA
mirna_summary <- vaf_matrix_data %>%
  group_by(miRNA_name, cohort) %>%
  summarise(
    mean_vaf = mean(vaf, na.rm = TRUE),
    n_snvs = n(),
    .groups = 'drop'
  ) %>%
  pivot_wider(names_from = cohort, values_from = c(mean_vaf, n_snvs)) %>%
  mutate(
    vaf_difference = mean_vaf_ALS - mean_vaf_Control,
    snv_difference = n_snvs_ALS - n_snvs_Control
  ) %>%
  arrange(desc(abs(vaf_difference)))

cat("   - Top 20 miRNAs con mayor diferencia en VAF:\n")
print(head(mirna_summary %>% select(miRNA_name, vaf_difference, mean_vaf_ALS, mean_vaf_Control), 20))
cat("\n")

# --- 7. GUARDAR RESULTADOS ---
cat("💾 7. GUARDANDO RESULTADOS\n")
cat("==========================\n")

# Guardar z-scores por SNV
write.csv(zscore_data, "zscore_by_snv.csv", row.names = FALSE)
cat("   - Z-scores por SNV guardados: zscore_by_snv.csv\n")

# Guardar z-scores por posición
write.csv(position_zscore, "zscore_by_position.csv", row.names = FALSE)
cat("   - Z-scores por posición guardados: zscore_by_position.csv\n")

# Guardar información de clusters
write.csv(sample_cluster_data, "sample_clusters.csv", row.names = FALSE)
cat("   - Información de clusters guardada: sample_clusters.csv\n")

# Guardar resumen de miRNAs
write.csv(mirna_summary, "mirna_summary.csv", row.names = FALSE)
cat("   - Resumen de miRNAs guardado: mirna_summary.csv\n")

# Guardar matriz de VAFs
write.csv(vaf_matrix_df, "vaf_matrix.csv", row.names = TRUE)
cat("   - Matriz de VAFs guardada: vaf_matrix.csv\n")

cat("\n✅ ANÁLISIS DE HEATMAPS SIMPLIFICADOS COMPLETADO\n")
cat("=================================================\n\n")









