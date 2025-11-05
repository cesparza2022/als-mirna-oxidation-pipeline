# ============================================================================
# GENERAR LAS 4 FIGURAS RESTANTES CON DATOS LIMPIOS
# Figuras 2.4, 2.5, 2.7, 2.8, 2.11
# ============================================================================

library(ggplot2)
library(dplyr)
library(tidyr)
library(stringr)
library(pheatmap)
library(tibble)
library(FactoMineR)
library(factoextra)

COLOR_ALS <- "#D62728"
COLOR_CONTROL <- "#666666"
COLOR_SEED <- "#FFE135"

theme_prof <- theme_minimal() +
  theme(
    text = element_text(size = 14),
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
    panel.grid.major = element_line(color = "gray90", linewidth = 0.5)
  )

cat("🎯 GENERANDO 5 FIGURAS RESTANTES (DATOS LIMPIOS)\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

# Cargar datos
cat("📊 Cargando datos limpios...\n")
data <- read.csv("final_processed_data_CLEAN.csv")
metadata <- read.csv("metadata.csv")
seed_ranking <- read.csv("SEED_GT_miRNAs_CLEAN_RANKING.csv")
sample_cols <- metadata$Sample_ID

# Top 50 para heatmaps
top50_mirnas <- head(seed_ranking$miRNA_name, 50)
all_seed_mirnas <- seed_ranking$miRNA_name

cat("✅ Datos cargados\n")
cat("   Top 50 miRNAs seed G>T seleccionados\n\n")

output_dir <- "figures_paso2_CLEAN"

# Preparar datos G>T
vaf_gt <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  select(all_of(c("miRNA_name", "pos.mut", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  left_join(metadata, by = "Sample_ID") %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^[0-9]+"))) %>%
  filter(!is.na(position), position <= 22)

# ============================================================================
# FIGURAS 2.4 y 2.5: HEATMAPS POSICIONALES (TOP 50)
# ============================================================================

cat("📊 [4-5/12] Generando heatmaps posicionales (top 50)...\n")

vaf_matrix_data <- vaf_gt %>%
  filter(miRNA_name %in% top50_mirnas) %>%
  group_by(miRNA_name, position, Group) %>%
  summarise(Mean_VAF = mean(VAF, na.rm = TRUE), .groups = "drop")

create_heatmap_mat <- function(grp) {
  mat_data <- vaf_matrix_data %>%
    filter(Group == grp) %>%
    select(miRNA_name, position, Mean_VAF) %>%
    pivot_wider(names_from = position, values_from = Mean_VAF, values_fill = 0) %>%
    column_to_rownames("miRNA_name")
  
  # Completar posiciones faltantes
  all_pos <- as.character(1:22)
  for (p in setdiff(all_pos, colnames(mat_data))) {
    mat_data[[p]] <- 0
  }
  mat_data <- mat_data[, all_pos]
  return(as.matrix(mat_data))
}

# Figura 2.4
png(file.path(output_dir, "FIG_2.4_HEATMAP_TOP50_CLEAN.png"), 
    width = 14, height = 13, units = "in", res = 300)
par(mfrow = c(1, 2))

mat_als <- create_heatmap_mat("ALS")
pheatmap(mat_als,
         main = "ALS: Top 50 Seed G>T miRNAs (CLEAN DATA)",
         color = colorRampPalette(c("white", COLOR_ALS))(100),
         cluster_cols = FALSE,
         fontsize = 8,
         silent = TRUE)

mat_ctrl <- create_heatmap_mat("Control")
pheatmap(mat_ctrl,
         main = "Control: Top 50 Seed G>T miRNAs (CLEAN DATA)",
         color = colorRampPalette(c("white", COLOR_CONTROL))(100),
         cluster_cols = FALSE,
         fontsize = 8,
         silent = TRUE)

dev.off()
cat("✅ Figura 2.4 guardada\n")

# Figura 2.5: Z-score
combined_mat <- rbind(mat_als, mat_ctrl)
zscore_mat <- t(scale(t(combined_mat)))
zscore_mat[is.na(zscore_mat) | is.infinite(zscore_mat)] <- 0

png(file.path(output_dir, "FIG_2.5_HEATMAP_ZSCORE_CLEAN.png"), 
    width = 12, height = 13, units = "in", res = 300)

pheatmap(zscore_mat,
         main = "Z-score: Top 50 Seed G>T miRNAs (CLEAN DATA)",
         color = colorRampPalette(c("blue", "white", "red"))(100),
         breaks = seq(-3, 3, length.out = 101),
         cluster_cols = FALSE,
         fontsize = 8)

dev.off()
cat("✅ Figura 2.5 guardada\n\n")

# ============================================================================
# FIGURAS 2.7 y 2.8: PCA Y CLUSTERING (TODOS los seed miRNAs)
# ============================================================================

cat("📊 [7-8/12] Generando PCA y Clustering (", length(all_seed_mirnas), " miRNAs)...\n")

# Crear matriz de VAF por muestra (método por muestra)
pca_matrix <- vaf_gt %>%
  filter(miRNA_name %in% all_seed_mirnas) %>%
  group_by(Sample_ID, miRNA_name) %>%
  summarise(Total_VAF = sum(VAF, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = miRNA_name, values_from = Total_VAF, values_fill = 0)

pca_samples <- pca_matrix$Sample_ID
pca_data <- as.matrix(pca_matrix[, -1])
rownames(pca_data) <- pca_samples

# Filtrar columnas con varianza muy baja
col_vars <- apply(pca_data, 2, var, na.rm = TRUE)
pca_data_filt <- pca_data[, col_vars > 0.001]

cat("   miRNAs con varianza suficiente:", ncol(pca_data_filt), "\n")

# PCA
pca_result <- prcomp(pca_data_filt, scale. = TRUE, center = TRUE)

pca_coords <- data.frame(
  Sample_ID = pca_samples,
  PC1 = pca_result$x[, 1],
  PC2 = pca_result$x[, 2]
) %>%
  left_join(metadata, by = "Sample_ID")

# Total VAF para tamaño
total_vaf <- vaf_gt %>%
  filter(miRNA_name %in% all_seed_mirnas) %>%
  group_by(Sample_ID) %>%
  summarise(Total_VAF = sum(VAF, na.rm = TRUE), .groups = "drop")

pca_coords <- pca_coords %>% left_join(total_vaf, by = "Sample_ID")

var_exp <- summary(pca_result)$importance[2, ] * 100

# Figura 2.7
fig_2_7 <- ggplot(pca_coords, aes(x = PC1, y = PC2, color = Group, size = Total_VAF)) +
  geom_point(alpha = 0.6) +
  stat_ellipse(aes(fill = Group, group = Group), geom = "polygon", alpha = 0.1, level = 0.95, show.legend = FALSE) +
  scale_color_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  scale_size_continuous(range = c(1, 5), name = "Total G>T VAF") +
  labs(
    title = paste0("PCA: Samples by Seed G>T Profile (", ncol(pca_data_filt), " miRNAs)"),
    subtitle = "Using CLEAN DATA (no VAF ≥ 0.5) | Per-sample method",
    x = paste0("PC1 (", round(var_exp[1], 1), "%)"),
    y = paste0("PC2 (", round(var_exp[2], 1), "%)")
  ) +
  theme_prof +
  theme(legend.position = "right")

ggsave(file.path(output_dir, "FIG_2.7_PCA_CLEAN.png"), 
       fig_2_7, width = 13, height = 10, dpi = 300)
cat("✅ Figura 2.7 guardada\n")

# Figura 2.8: Clustering
heatmap_zscore <- scale(pca_data_filt)
heatmap_zscore[is.na(heatmap_zscore) | is.infinite(heatmap_zscore)] <- 0

annotation_row <- data.frame(
  Group = metadata$Group[match(rownames(heatmap_zscore), metadata$Sample_ID)]
)
rownames(annotation_row) <- rownames(heatmap_zscore)

annotation_colors <- list(Group = c(ALS = COLOR_ALS, Control = COLOR_CONTROL))

png(file.path(output_dir, "FIG_2.8_CLUSTERING_CLEAN.png"), 
    width = 16, height = 13, units = "in", res = 300)

pheatmap(heatmap_zscore,
         main = paste0("Hierarchical Clustering: ", ncol(heatmap_zscore), " Seed G>T miRNAs (CLEAN)"),
         color = colorRampPalette(c("blue", "white", "red"))(100),
         breaks = seq(-3, 3, length.out = 101),
         annotation_row = annotation_row,
         annotation_colors = annotation_colors,
         show_rownames = FALSE,
         show_colnames = FALSE,
         fontsize = 8,
         clustering_method = "ward.D2")

dev.off()
cat("✅ Figura 2.8 guardada\n\n")

# ============================================================================
# FIGURA 2.11: HEATMAP DE TIPOS DE MUTACIÓN
# ============================================================================

cat("📊 [11/12] Generando heatmap de tipos de mutación...\n")

all_mutations <- data %>%
  mutate(
    position = as.numeric(str_extract(pos.mut, "^[0-9]+")),
    mutation_type = str_extract(pos.mut, ":[A-Z]+$") %>% str_remove(":")
  ) %>%
  filter(!is.na(position), position <= 22)

mutation_data <- all_mutations %>%
  select(all_of(c("mutation_type", "position", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  left_join(metadata, by = "Sample_ID") %>%
  group_by(mutation_type, position, Group) %>%
  summarise(Mean_VAF = mean(VAF, na.rm = TRUE), .groups = "drop")

create_mut_mat <- function(grp) {
  mat_data <- mutation_data %>%
    filter(Group == grp) %>%
    select(mutation_type, position, Mean_VAF) %>%
    pivot_wider(names_from = position, values_from = Mean_VAF, values_fill = 0)
  
  mat <- as.matrix(mat_data[, -1])
  rownames(mat) <- mat_data$mutation_type
  return(mat)
}

png(file.path(output_dir, "FIG_2.11_MUTATION_TYPES_CLEAN.png"), 
    width = 16, height = 8, units = "in", res = 300)

par(mfrow = c(1, 2))

mat_als_mut <- create_mut_mat("ALS")
pheatmap(mat_als_mut,
         main = "ALS: All Mutation Types (CLEAN DATA)",
         color = colorRampPalette(c("white", COLOR_ALS))(100),
         cluster_rows = FALSE,
         cluster_cols = FALSE,
         fontsize = 8,
         silent = TRUE)

mat_ctrl_mut <- create_mut_mat("Control")
pheatmap(mat_ctrl_mut,
         main = "Control: All Mutation Types (CLEAN DATA)",
         color = colorRampPalette(c("white", COLOR_CONTROL))(100),
         cluster_rows = FALSE,
         cluster_cols = FALSE,
         fontsize = 8,
         silent = TRUE)

dev.off()
cat("✅ Figura 2.11 guardada\n\n")

# ============================================================================
# RESUMEN
# ============================================================================

cat("\n", paste(rep("=", 70), collapse = ""), "\n")
cat("✅ TODAS LAS FIGURAS DEL PASO 2 COMPLETADAS\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

cat("📊 FIGURAS GENERADAS (12/12):\n\n")

cat("GRUPO A - Comparaciones Globales:\n")
cat("  ✓ 2.1: VAF Global (p-values mejorados)\n")
cat("  ✓ 2.2: Distribuciones\n")
cat("  ✓ 2.3: Volcano Plot (método por muestra) ⭐\n\n")

cat("GRUPO B - Análisis Posicional:\n")
cat("  ✓ 2.4: Heatmap Posicional (top 50 limpio) ⭐\n")
cat("  ✓ 2.5: Heatmap Z-score (top 50 limpio) ⭐\n")
cat("  ✓ 2.6: Perfiles Posicionales\n\n")

cat("GRUPO C - Heterogeneidad:\n")
cat("  ✓ 2.7: PCA (", ncol(pca_data_filt), " miRNAs limpios) ⭐\n")
cat("  ✓ 2.8: Clustering (", ncol(pca_data_filt), " miRNAs) ⭐\n")
cat("  ✓ 2.9: Coeficiente Variación\n\n")

cat("GRUPO D - Especificidad:\n")
cat("  ✓ 2.10: Ratio G>T/G>A\n")
cat("  ✓ 2.11: Mutation Types ⭐\n")
cat("  ✓ 2.12: Enriquecimiento Regional\n\n")

cat("📁 Directorio:", output_dir, "\n")
cat("🎉 PASO 2 100% COMPLETO\n")

