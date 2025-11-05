library(dplyr)
library(stringr)
library(tidyr)
library(readr)
library(pheatmap)
library(RColorBrewer)
library(ggplot2)
library(gridExtra)
library(corrplot)

cat("🔍 ANÁLISIS DETALLADO DE CLUSTERING JERÁRQUICO\n")
cat(paste(rep("=", 50), collapse=""), "\n")

# Load the processed dataset
cat("📁 Cargando dataset procesado...\n")
df_processed <- read_tsv("outputs/processed_mirna_dataset_simple.tsv")

cat("   📊 Dataset procesado:", nrow(df_processed), "x", ncol(df_processed), "\n")

# Define column ranges
snv_cols <- colnames(df_processed)[3:417]
total_cols <- colnames(df_processed)[418:832]

cat("   📊 Columnas SNV:", length(snv_cols), "\n")
cat("   📊 Columnas TOTAL:", length(total_cols), "\n")

# Calculate library size for each sample
cat("\n🔧 Calculando library size por muestra...\n")
library_sizes <- df_processed %>%
  select(all_of(total_cols)) %>%
  summarise(across(everything(), ~ sum(.x, na.rm = TRUE))) %>%
  unlist()

# Filter for G>T mutations in seed region (positions 2-8)
cat("\n🔧 Filtrando mutaciones G>T en región semilla...\n")
seed_gt_mutations <- df_processed %>%
  filter(str_detect(pos.mut, "GT")) %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^\\d+"))) %>%
  filter(position >= 2 & position <= 8)

cat("   📊 Mutaciones G>T en región semilla:", nrow(seed_gt_mutations), "\n")

# Calculate VAF for each mutation
cat("\n🔧 Calculando VAF por mutación...\n")
vaf_data <- seed_gt_mutations

# Calculate VAF matrix using base R
vaf_matrix <- matrix(0, nrow = nrow(vaf_data), ncol = length(snv_cols))
for (i in 1:nrow(vaf_data)) {
  for (j in 1:length(snv_cols)) {
    snv_count <- as.numeric(vaf_data[i, snv_cols[j]])
    total_count <- as.numeric(vaf_data[i, total_cols[j]])
    if (total_count > 0) {
      vaf_matrix[i, j] <- snv_count / total_count
    }
  }
}

# Add VAF statistics
vaf_data$mean_vaf <- rowMeans(vaf_matrix, na.rm = TRUE)
vaf_data$max_vaf <- apply(vaf_matrix, 1, max, na.rm = TRUE)

# Filter out high VAF mutations (>50%)
cat("\n🔧 Filtrando mutaciones con VAF > 50%...\n")
vaf_filtered <- vaf_data %>%
  filter(max_vaf <= 0.5)

cat("   📊 Mutaciones después de filtrar VAF > 50%:", nrow(vaf_filtered), "\n")

# Calculate RPM for each miRNA
cat("\n🔧 Calculando RPM por miRNA...\n")
rpm_matrix <- matrix(0, nrow = nrow(vaf_filtered), ncol = length(total_cols))
for (i in 1:nrow(vaf_filtered)) {
  for (j in 1:length(total_cols)) {
    total_count <- as.numeric(vaf_filtered[i, total_cols[j]])
    lib_size <- library_sizes[total_cols[j]]
    if (lib_size > 0) {
      rpm_matrix[i, j] <- (total_count / lib_size) * 1e6
    }
  }
}

vaf_filtered$mean_rpm <- rowMeans(rpm_matrix, na.rm = TRUE)

# Select top miRNAs by G>T counts in seed region
cat("\n🔧 Seleccionando top miRNAs por cuentas G>T en región semilla...\n")
top_mirnas_by_counts <- vaf_filtered %>%
  group_by(miRNA.name) %>%
  summarise(total_gt_counts = sum(across(all_of(snv_cols), ~ sum(.x, na.rm = TRUE))), .groups = "drop") %>%
  arrange(desc(total_gt_counts))

# Select top 10% of miRNAs
num_top_mirnas <- ceiling(nrow(top_mirnas_by_counts) * 0.10)
top_mirnas_list <- head(top_mirnas_by_counts, num_top_mirnas)

cat("   📊 Top", num_top_mirnas, "miRNAs seleccionados\n")

# Filter data for top miRNAs
top_snvs <- vaf_filtered %>%
  filter(miRNA.name %in% top_mirnas_list$miRNA.name)

cat("   📊 SNVs de top miRNAs:", nrow(top_snvs), "\n")

# Create VAF matrix for clustering analysis
cat("\n🔧 Creando matriz VAF para análisis de clustering...\n")
vaf_heatmap_data <- matrix(0, nrow = length(snv_cols), ncol = nrow(top_snvs))
colnames(vaf_heatmap_data) <- paste0(top_snvs$miRNA.name, "_", top_snvs$pos.mut)
rownames(vaf_heatmap_data) <- snv_cols

for (i in 1:nrow(top_snvs)) {
  for (j in 1:length(snv_cols)) {
    snv_count <- as.numeric(top_snvs[i, snv_cols[j]])
    total_count <- as.numeric(top_snvs[i, total_cols[j]])
    if (total_count > 0) {
      vaf_heatmap_data[j, i] <- snv_count / total_count
    }
  }
}

# Perform hierarchical clustering
cat("\n🔧 Realizando clustering jerárquico...\n")

# Cluster samples (rows)
sample_dist <- dist(vaf_heatmap_data, method = "euclidean")
sample_clust <- hclust(sample_dist, method = "ward.D2")

# Cluster SNVs (columns)
snv_dist <- dist(t(vaf_heatmap_data), method = "euclidean")
snv_clust <- hclust(snv_dist, method = "ward.D2")

# Cut trees to get clusters
cat("\n🔧 Cortando árboles para obtener clusters...\n")

# Determine optimal number of clusters using elbow method
# For samples
sample_wss <- numeric(10)
for (k in 1:10) {
  sample_clusters <- cutree(sample_clust, k = k)
  sample_wss[k] <- sum(sapply(1:k, function(i) {
    cluster_data <- vaf_heatmap_data[sample_clusters == i, , drop = FALSE]
    if (nrow(cluster_data) > 1) {
      sum(dist(cluster_data)^2)
    } else {
      0
    }
  }))
}

# For SNVs
snv_wss <- numeric(10)
for (k in 1:10) {
  snv_clusters <- cutree(snv_clust, k = k)
  snv_wss[k] <- sum(sapply(1:k, function(i) {
    cluster_data <- t(vaf_heatmap_data)[snv_clusters == i, , drop = FALSE]
    if (nrow(cluster_data) > 1) {
      sum(dist(cluster_data)^2)
    } else {
      0
    }
  }))
}

# Find elbow points
sample_elbow <- which.min(diff(diff(sample_wss))) + 1
snv_elbow <- which.min(diff(diff(snv_wss))) + 1

cat("   📊 Número óptimo de clusters para muestras:", sample_elbow, "\n")
cat("   📊 Número óptimo de clusters para SNVs:", snv_elbow, "\n")

# Cut trees at optimal points
sample_clusters <- cutree(sample_clust, k = sample_elbow)
snv_clusters <- cutree(snv_clust, k = snv_elbow)

# Create sample annotation
cat("\n🔧 Creando anotación de muestras...\n")
sample_annotation <- data.frame(
  group = ifelse(str_detect(snv_cols, "Control"), "Control", "ALS"),
  cluster = paste0("Sample_C", sample_clusters),
  stringsAsFactors = FALSE
)
rownames(sample_annotation) <- snv_cols

# Create SNV annotation
snv_annotation <- data.frame(
  cluster = paste0("SNV_C", snv_clusters),
  stringsAsFactors = FALSE
)
rownames(snv_annotation) <- colnames(vaf_heatmap_data)

# Create color mappings
group_colors <- c("ALS" = "#E31A1C", "Control" = "#1F78B4")
sample_cluster_colors <- rainbow(sample_elbow)
names(sample_cluster_colors) <- paste0("Sample_C", 1:sample_elbow)
snv_cluster_colors <- rainbow(snv_elbow)
names(snv_cluster_colors) <- paste0("SNV_C", 1:snv_elbow)

annotation_colors <- list(
  group = group_colors,
  cluster = c(sample_cluster_colors, snv_cluster_colors)
)

# Create enhanced heatmap with cluster annotations
cat("\n🎨 Creando heatmap con anotaciones de clusters...\n")
png("outputs/figures/clustering_analysis_heatmap.png", width = 1400, height = 900)
pheatmap(
  vaf_heatmap_data,
  cluster_rows = sample_clust,
  cluster_cols = snv_clust,
  clustering_method = "ward.D2",
  color = colorRampPalette(c("white", "red"))(100),
  annotation_row = sample_annotation,
  annotation_col = snv_annotation,
  annotation_colors = annotation_colors,
  show_rownames = FALSE,
  show_colnames = FALSE,
  main = "VAF Clustering Analysis - G>T Mutations in Seed Region",
  fontsize = 12,
  border_color = NA
)
dev.off()

# Analyze cluster characteristics
cat("\n🔧 Analizando características de clusters...\n")

# Sample cluster analysis
sample_cluster_summary <- data.frame(
  sample = snv_cols,
  group = sample_annotation$group,
  cluster = sample_annotation$cluster,
  stringsAsFactors = FALSE
) %>%
  group_by(cluster, group) %>%
  summarise(count = n(), .groups = "drop") %>%
  pivot_wider(names_from = group, values_from = count, values_fill = 0)

# Add total column if both ALS and Control exist
if ("ALS" %in% colnames(sample_cluster_summary) && "Control" %in% colnames(sample_cluster_summary)) {
  sample_cluster_summary$total <- sample_cluster_summary$ALS + sample_cluster_summary$Control
} else if ("ALS" %in% colnames(sample_cluster_summary)) {
  sample_cluster_summary$total <- sample_cluster_summary$ALS
} else if ("Control" %in% colnames(sample_cluster_summary)) {
  sample_cluster_summary$total <- sample_cluster_summary$Control
} else {
  sample_cluster_summary$total <- 0
}

cat("\n📊 Resumen de clusters de muestras:\n")
print(sample_cluster_summary)

# SNV cluster analysis
snv_cluster_summary <- data.frame(
  snv = colnames(vaf_heatmap_data),
  cluster = snv_clusters,
  stringsAsFactors = FALSE
) %>%
  separate(snv, into = c("miRNA", "mutation"), sep = "_", extra = "merge") %>%
  group_by(cluster) %>%
  summarise(
    count = n(),
    unique_mirnas = n_distinct(miRNA),
    .groups = "drop"
  )

cat("\n📊 Resumen de clusters de SNVs:\n")
print(snv_cluster_summary)

# Create cluster visualization plots
cat("\n🎨 Creando visualizaciones de clusters...\n")

# Plot 1: Sample cluster distribution
p1 <- ggplot(sample_cluster_summary, aes(x = cluster, y = total, fill = cluster)) +
  geom_bar(stat = "identity") +
  geom_text(aes(label = total), vjust = -0.5) +
  scale_fill_manual(values = sample_cluster_colors) +
  labs(title = "Sample Cluster Distribution",
       x = "Cluster", y = "Number of Samples") +
  theme_minimal() +
  theme(legend.position = "none")

# Plot 2: ALS vs Control in each cluster
if ("ALS" %in% colnames(sample_cluster_summary) && "Control" %in% colnames(sample_cluster_summary)) {
  p2 <- ggplot(sample_cluster_summary, aes(x = cluster)) +
    geom_bar(aes(y = ALS), stat = "identity", fill = "#E31A1C", alpha = 0.7) +
    geom_bar(aes(y = -Control), stat = "identity", fill = "#1F78B4", alpha = 0.7) +
    geom_hline(yintercept = 0, color = "black") +
    labs(title = "ALS vs Control Distribution by Cluster",
         x = "Cluster", y = "Number of Samples") +
    theme_minimal()
} else {
  p2 <- ggplot(sample_cluster_summary, aes(x = cluster, y = total, fill = cluster)) +
    geom_bar(stat = "identity") +
    geom_text(aes(label = total), vjust = -0.5) +
    scale_fill_manual(values = sample_cluster_colors) +
    labs(title = "Sample Distribution by Cluster",
         x = "Cluster", y = "Number of Samples") +
    theme_minimal() +
    theme(legend.position = "none")
}

# Plot 3: SNV cluster distribution
p3 <- ggplot(snv_cluster_summary, aes(x = factor(cluster), y = count, fill = factor(cluster))) +
  geom_bar(stat = "identity") +
  geom_text(aes(label = count), vjust = -0.5) +
  scale_fill_manual(values = snv_cluster_colors) +
  labs(title = "SNV Cluster Distribution",
       x = "Cluster", y = "Number of SNVs") +
  theme_minimal() +
  theme(legend.position = "none")

# Plot 4: Unique miRNAs per SNV cluster
p4 <- ggplot(snv_cluster_summary, aes(x = factor(cluster), y = unique_mirnas, fill = factor(cluster))) +
  geom_bar(stat = "identity") +
  geom_text(aes(label = unique_mirnas), vjust = -0.5) +
  scale_fill_manual(values = snv_cluster_colors) +
  labs(title = "Unique miRNAs per SNV Cluster",
       x = "Cluster", y = "Number of Unique miRNAs") +
  theme_minimal() +
  theme(legend.position = "none")

# Combine plots
png("outputs/figures/clustering_analysis_plots.png", width = 1200, height = 800)
grid.arrange(p1, p2, p3, p4, ncol = 2)
dev.off()

# Create detailed cluster analysis
cat("\n🔧 Creando análisis detallado de clusters...\n")

# Analyze VAF patterns within clusters
cluster_vaf_analysis <- data.frame(
  sample = rep(snv_cols, each = nrow(top_snvs)),
  snv = rep(colnames(vaf_heatmap_data), length(snv_cols)),
  vaf = as.vector(vaf_heatmap_data),
  sample_cluster = rep(sample_clusters, each = nrow(top_snvs)),
  snv_cluster = rep(snv_clusters, length(snv_cols)),
  group = rep(ifelse(str_detect(snv_cols, "Control"), "Control", "ALS"), each = nrow(top_snvs))
) %>%
  filter(vaf > 0) %>%  # Only non-zero VAFs
  group_by(sample_cluster, snv_cluster, group) %>%
  summarise(
    mean_vaf = mean(vaf, na.rm = TRUE),
    median_vaf = median(vaf, na.rm = TRUE),
    max_vaf = max(vaf, na.rm = TRUE),
    count = n(),
    .groups = "drop"
  )

cat("\n📊 Análisis de VAF por clusters:\n")
print(cluster_vaf_analysis)

# Save results
cat("\n💾 Guardando resultados de clustering...\n")

write.table(sample_cluster_summary, "outputs/clustering_sample_summary.tsv", 
            sep = "\t", row.names = FALSE, quote = FALSE)
write.table(snv_cluster_summary, "outputs/clustering_snv_summary.tsv", 
            sep = "\t", row.names = FALSE, quote = FALSE)
write.table(cluster_vaf_analysis, "outputs/clustering_vaf_analysis.tsv", 
            sep = "\t", row.names = FALSE, quote = FALSE)

# Create comprehensive report
cat("\n📋 Creando reporte de clustering...\n")

report_content <- paste0(
"# ANÁLISIS DE CLUSTERING JERÁRQUICO POR VAF

## Resumen del Análisis
- **Método de clustering**: Ward.D2
- **Métrica de distancia**: Euclidiana
- **SNVs analizados**: ", nrow(top_snvs), "
- **Muestras analizadas**: ", length(snv_cols), "

## Clusters de Muestras
- **Número óptimo de clusters**: ", sample_elbow, "
- **Método de selección**: Elbow method

## Clusters de SNVs
- **Número óptimo de clusters**: ", snv_elbow, "
- **Método de selección**: Elbow method

## Archivos Generados
- `outputs/figures/clustering_analysis_heatmap.png`: Heatmap con clusters
- `outputs/figures/clustering_analysis_plots.png`: Gráficos de análisis
- `outputs/clustering_sample_summary.tsv`: Resumen de clusters de muestras
- `outputs/clustering_snv_summary.tsv`: Resumen de clusters de SNVs
- `outputs/clustering_vaf_analysis.tsv`: Análisis de VAF por clusters

## Interpretación
Los clusters identificados permiten:
1. **Identificar patrones de oxidación** en grupos de muestras
2. **Agrupar SNVs** con patrones similares de VAF
3. **Comparar ALS vs Control** dentro de cada cluster
4. **Identificar miRNAs** con patrones de oxidación consistentes
"
)

writeLines(report_content, "outputs/clustering_analysis_report.md")

cat("\n🎉 Análisis de clustering completado!\n")
cat("   📊 Archivos generados:\n")
cat("   - outputs/figures/clustering_analysis_heatmap.png\n")
cat("   - outputs/figures/clustering_analysis_plots.png\n")
cat("   - outputs/clustering_*_summary.tsv\n")
cat("   - outputs/clustering_analysis_report.md\n")
