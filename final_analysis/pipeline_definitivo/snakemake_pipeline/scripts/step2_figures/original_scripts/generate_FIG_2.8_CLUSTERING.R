#!/usr/bin/env Rscript
# ============================================================================
# FIGURA 2.8 - HIERARCHICAL CLUSTERING HEATMAP
# Clustering of samples by G>T mutational profile
# ============================================================================

library(ggplot2)
library(dplyr)
library(tidyr)
library(readr)
library(stringr)
library(tibble)
library(pheatmap)
library(viridis)

# Colores profesionales
COLOR_ALS <- "#D62728"
COLOR_CONTROL <- "#2E86AB"

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  GENERATING FIG 2.8 - CLUSTERING HEATMAP\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# ============================================================================
# LOAD DATA
# ============================================================================

cat("📂 Loading data...\n")
data <- read_csv("final_processed_data_CLEAN.csv", show_col_types = FALSE)
metadata <- read_csv("metadata.csv", show_col_types = FALSE)
sample_cols <- metadata$Sample_ID

cat("   ✅ Data loaded:", nrow(data), "SNVs,", length(sample_cols), "samples\n\n")

# ============================================================================
# PREPARE MATRIX FOR CLUSTERING
# ============================================================================

cat("📊 Preparing matrix for clustering...\n")

# Get all G>T mutations
vaf_gt <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  mutate(SNV_ID = paste(miRNA_name, pos.mut, sep = "_")) %>%
  select(SNV_ID, all_of(sample_cols))

# Transform to matrix (SNV_ID × samples)
vaf_matrix <- vaf_gt %>%
  column_to_rownames("SNV_ID") %>%
  as.matrix()

# Replace NA with 0 for clustering
vaf_matrix[is.na(vaf_matrix)] <- 0

cat("   ✅ Matrix prepared:", nrow(vaf_matrix), "SNVs ×", ncol(vaf_matrix), "samples\n")
cat("   ✅ Non-zero values:", sum(vaf_matrix > 0), "\n\n")

# ============================================================================
# FILTER TO TOP VARIABLE SNVs (for visualization)
# ============================================================================

cat("📊 Selecting top 100 most variable SNVs for visualization...\n")

# Calculate variance per SNV
snv_variance <- apply(vaf_matrix, 1, var, na.rm = TRUE)
top_snvs <- names(sort(snv_variance, decreasing = TRUE)[1:100])

vaf_matrix_top <- vaf_matrix[top_snvs, ]

cat("   ✅ Selected top 100 SNVs\n\n")

# ============================================================================
# PREPARE ANNOTATION
# ============================================================================

cat("📊 Preparing sample annotations...\n")

annotation_col <- data.frame(
  Group = metadata$Group,
  row.names = metadata$Sample_ID
)

annotation_colors <- list(
  Group = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)
)

cat("   ✅ Annotations ready\n\n")

# ============================================================================
# GENERATE HEATMAP WITH CLUSTERING
# ============================================================================

cat("🎨 Generating clustering heatmap...\n")

# Save as PNG
png("figures_paso2_CLEAN/FIG_2.8_CLUSTERING.png", 
    width = 14, height = 10, units = "in", res = 300)

pheatmap(
  vaf_matrix_top,
  
  # Clustering
  cluster_rows = TRUE,
  cluster_cols = TRUE,
  clustering_distance_rows = "euclidean",
  clustering_distance_cols = "euclidean",
  clustering_method = "ward.D2",
  
  # Display
  show_rownames = FALSE,
  show_colnames = FALSE,
  
  # Colors
  color = viridis(100, option = "plasma"),
  
  # Annotations
  annotation_col = annotation_col,
  annotation_colors = annotation_colors,
  
  # Scale
  scale = "row",
  
  # Gaps
  gaps_col = NULL,
  
  # Borders
  border_color = NA,
  
  # Legend
  legend = TRUE,
  
  # Main title
  main = "Hierarchical Clustering of Samples by G>T Profile\n(Top 100 most variable SNVs, scaled by row)",
  fontsize = 12,
  fontsize_row = 8,
  fontsize_col = 8
)

dev.off()

cat("   ✅ Figure saved: FIG_2.8_CLUSTERING.png\n\n")

# ============================================================================
# CLUSTERING ANALYSIS
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("📊 CLUSTERING ANALYSIS:\n\n")

# Perform clustering on samples
sample_dist <- dist(t(vaf_matrix_top), method = "euclidean")
sample_hclust <- hclust(sample_dist, method = "ward.D2")

# Cut tree to get clusters
clusters_k3 <- cutree(sample_hclust, k = 3)
clusters_k4 <- cutree(sample_hclust, k = 4)

# Analyze cluster composition
cluster_composition_k3 <- data.frame(
  Sample_ID = names(clusters_k3),
  Cluster = clusters_k3
) %>%
  left_join(metadata %>% select(Sample_ID, Group), by = "Sample_ID") %>%
  group_by(Cluster, Group) %>%
  summarise(N = n(), .groups = "drop") %>%
  pivot_wider(names_from = Group, values_from = N, values_fill = 0)

cat("CLUSTER COMPOSITION (k=3):\n")
print(cluster_composition_k3)
cat("\n")

cluster_composition_k4 <- data.frame(
  Sample_ID = names(clusters_k4),
  Cluster = clusters_k4
) %>%
  left_join(metadata %>% select(Sample_ID, Group), by = "Sample_ID") %>%
  group_by(Cluster, Group) %>%
  summarise(N = n(), .groups = "drop") %>%
  pivot_wider(names_from = Group, values_from = N, values_fill = 0)

cat("CLUSTER COMPOSITION (k=4):\n")
print(cluster_composition_k4)
cat("\n")

# ============================================================================
# INTERPRETATION
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("💡 INTERPRETATION:\n\n")

cat("WHAT THIS FIGURE SHOWS:\n")
cat("   • Hierarchical clustering of samples by G>T profile\n")
cat("   • Both row (SNVs) and column (samples) dendrograms\n")
cat("   • Top 100 most variable SNVs (for clarity)\n")
cat("   • Row-scaled (z-score) for comparability\n\n")

cat("EXPECTED PATTERN:\n")
cat("   • If groups differ: ALS and Control samples cluster separately\n")
cat("   • If heterogeneous: Mixed clustering (consistent with PCA)\n\n")

cat("CONSISTENCY CHECK:\n")
cat("   • Should align with Fig 2.7 (PCA: R² = 2%, no clear separation)\n")
cat("   • Should align with Fig 2.9 (high CV in ALS)\n\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("✅ FIGURE 2.8 GENERATED SUCCESSFULLY\n\n")

