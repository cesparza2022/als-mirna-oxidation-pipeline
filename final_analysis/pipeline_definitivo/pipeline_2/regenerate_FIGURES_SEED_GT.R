# ============================================================================
# RE-GENERAR FIGURAS CON SELECCIÓN MEJORADA DE miRNAs
# Criterio: miRNAs con G>T SNVs en la región SEMILLA (posiciones 2-8)
# ============================================================================

library(ggplot2)
library(dplyr)
library(tidyr)
library(stringr)
library(patchwork)
library(viridis)
library(pheatmap)
library(tibble)
library(FactoMineR)
library(factoextra)

# Configuración
COLOR_ALS <- "#D62728"
COLOR_CONTROL <- "#666666"
COLOR_SEED <- "#FFE135"

theme_professional <- theme_minimal() +
  theme(
    text = element_text(size = 14, family = "Helvetica"),
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray40"),
    axis.title = element_text(size = 14, face = "bold"),
    axis.text = element_text(size = 12),
    panel.grid.major = element_line(color = "gray90", linewidth = 0.5),
    panel.grid.minor = element_blank()
  )

cat("🎯 RE-GENERANDO FIGURAS CON CRITERIO SEED G>T\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

# Cargar datos
cat("📊 Cargando datos...\n")
data <- read.csv("../../../final_analysis/processed_data/final_processed_data.csv")
metadata <- read.csv("metadata.csv")
sample_cols <- metadata$Sample_ID

output_dir <- "figures_paso2"

# ============================================================================
# IDENTIFICAR miRNAs CON G>T EN LA REGIÓN SEMILLA
# ============================================================================

cat("\n🎯 IDENTIFICANDO miRNAs CON G>T EN REGIÓN SEMILLA (2-8)...\n")

# Extraer G>T en seed
seed_gt_data <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^[0-9]+"))) %>%
  filter(position >= 2, position <= 8)  # REGIÓN SEMILLA

# Calcular VAF total de G>T en seed por miRNA
seed_gt_mirnas <- seed_gt_data %>%
  select(all_of(c("miRNA_name", "pos.mut", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  group_by(miRNA_name) %>%
  summarise(
    Total_Seed_GT_VAF = sum(VAF, na.rm = TRUE),
    N_Seed_GT_SNVs = n_distinct(pos.mut),
    .groups = "drop"
  ) %>%
  arrange(desc(Total_Seed_GT_VAF))

cat("\n📊 RESULTADOS DE SELECCIÓN:\n")
cat("   - Total miRNAs con G>T en seed:", nrow(seed_gt_mirnas), "\n")
cat("   - Top 20 miRNAs seleccionados por VAF en seed\n")
cat("   - Top 30 para heatmaps más grandes\n\n")

# Mostrar top 10
cat("🔝 TOP 10 miRNAs con Mayor G>T VAF en Región Semilla:\n")
print(head(seed_gt_mirnas, 10))
cat("\n")

# Seleccionar tops
top20_seed_gt <- head(seed_gt_mirnas, 20)$miRNA_name
top30_seed_gt <- head(seed_gt_mirnas, 30)$miRNA_name

# ============================================================================
# RE-GENERAR FIGURAS CLAVE CON NUEVA SELECCIÓN
# ============================================================================

# ---- FIGURA 2.3: VOLCANO PLOT (Actualizado) ----
cat("📊 Re-generando Figura 2.3: Volcano Plot (miRNAs con G>T en seed)...\n")

vaf_gt_all <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  select(all_of(c("miRNA_name", "pos.mut", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  left_join(metadata, by = "Sample_ID")

# Calcular FC y p-value solo para miRNAs con G>T en seed
volcano_data <- data.frame()
for (mirna in top30_seed_gt) {  # Solo miRNAs relevantes
  mirna_data <- vaf_gt_all %>% filter(miRNA_name == mirna)
  
  als_vals <- mirna_data %>% filter(Group == "ALS") %>% pull(VAF)
  ctrl_vals <- mirna_data %>% filter(Group == "Control") %>% pull(VAF)
  
  if (length(als_vals) > 5 && length(ctrl_vals) > 5) {
    mean_als <- mean(als_vals, na.rm = TRUE)
    mean_ctrl <- mean(ctrl_vals, na.rm = TRUE)
    
    if (mean_als == 0) mean_als <- 0.001
    if (mean_ctrl == 0) mean_ctrl <- 0.001
    
    fc <- log2(mean_als / mean_ctrl)
    
    test_result <- tryCatch({
      wilcox.test(als_vals, ctrl_vals)
    }, error = function(e) list(p.value = 1))
    
    volcano_data <- rbind(volcano_data, data.frame(
      miRNA = mirna,
      log2FC = fc,
      pvalue = test_result$p.value,
      Mean_ALS = mean_als,
      Mean_Control = mean_ctrl
    ))
  }
}

volcano_data$padj <- p.adjust(volcano_data$pvalue, method = "fdr")
volcano_data$neg_log10_padj <- -log10(volcano_data$padj)

volcano_data$Significance <- "NS"
volcano_data$Significance[volcano_data$log2FC > 0.58 & volcano_data$padj < 0.05] <- "ALS enriched"
volcano_data$Significance[volcano_data$log2FC < -0.58 & volcano_data$padj < 0.05] <- "Control enriched"

# Top para etiquetar
top_labels <- volcano_data %>%
  filter(Significance != "NS") %>%
  arrange(padj) %>%
  head(10)

figure_2_3 <- ggplot(volcano_data, aes(x = log2FC, y = neg_log10_padj, color = Significance)) +
  geom_point(alpha = 0.6, size = 3) +
  geom_hline(yintercept = -log10(0.05), linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = c(-0.58, 0.58), linetype = "dashed", color = "gray50") +
  scale_color_manual(values = c("ALS enriched" = COLOR_ALS, 
                                "Control enriched" = "steelblue",
                                "NS" = "gray70")) +
  labs(
    title = "Volcano Plot: miRNAs with G>T in SEED Region",
    subtitle = paste0("G>T VAF comparison (ALS vs Control) | n=", nrow(volcano_data), " miRNAs with seed G>T"),
    x = "log2(Fold Change)",
    y = "-log10(FDR-adjusted p-value)"
  ) +
  theme_professional +
  theme(legend.position = "bottom")

if (nrow(top_labels) > 0) {
  figure_2_3 <- figure_2_3 +
    ggrepel::geom_text_repel(data = top_labels, aes(label = miRNA), 
                             size = 3, max.overlaps = 20, color = "black")
}

ggsave(file.path(output_dir, "FIGURA_2.3_VOLCANO_PLOT_SEED_GT.png"), 
       plot = figure_2_3, width = 12, height = 10, dpi = 300)
cat("✅ Figura 2.3 actualizada\n\n")

# ---- FIGURA 2.4: HEATMAP POSICIONAL (Top 30 con G>T en seed) ----
cat("📊 Re-generando Figura 2.4: Heatmap posicional (top 30 seed G>T)...\n")

# Datos de todos los G>T
vaf_gt_positional <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^[0-9]+"))) %>%
  filter(!is.na(position), position <= 22) %>%
  filter(miRNA_name %in% top30_seed_gt)  # FILTRO CLAVE

# VAF promedio por miRNA, posición y grupo
vaf_matrix_data <- vaf_gt_positional %>%
  select(all_of(c("miRNA_name", "position", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  left_join(metadata, by = "Sample_ID") %>%
  group_by(miRNA_name, position, Group) %>%
  summarise(Mean_VAF = mean(VAF, na.rm = TRUE), .groups = "drop")

# Crear matrices por grupo
create_heatmap_matrix <- function(group_name) {
  matrix_data <- vaf_matrix_data %>%
    filter(Group == group_name) %>%
    select(miRNA_name, position, Mean_VAF) %>%
    pivot_wider(names_from = position, values_from = Mean_VAF, values_fill = 0) %>%
    column_to_rownames("miRNA_name")
  
  # Completar posiciones faltantes
  all_positions <- as.character(1:22)
  for (pos in setdiff(all_positions, colnames(matrix_data))) {
    matrix_data[[pos]] <- 0
  }
  
  matrix_data <- matrix_data[, all_positions]
  return(as.matrix(matrix_data))
}

# Crear heatmaps
png(file.path(output_dir, "FIGURA_2.4_HEATMAP_POSITIONAL_SEED_GT.png"), 
    width = 14, height = 12, units = "in", res = 300)

par(mfrow = c(1, 2))

# ALS
mat_als <- create_heatmap_matrix("ALS")
pheatmap(mat_als,
         main = "ALS: G>T VAF by Position (miRNAs with seed G>T)",
         color = colorRampPalette(c("white", COLOR_ALS))(100),
         cluster_cols = FALSE,
         fontsize = 9,
         silent = TRUE)

# Control
mat_ctrl <- create_heatmap_matrix("Control")
pheatmap(mat_ctrl,
         main = "Control: G>T VAF by Position (miRNAs with seed G>T)",
         color = colorRampPalette(c("white", COLOR_CONTROL))(100),
         cluster_cols = FALSE,
         fontsize = 9,
         silent = TRUE)

dev.off()
cat("✅ Figura 2.4 actualizada\n\n")

# ---- FIGURA 2.5: HEATMAP Z-SCORE (Top 30 con G>T en seed) ----
cat("📊 Re-generando Figura 2.5: Heatmap Z-score (top 30 seed G>T)...\n")

# Combinar matrices y calcular Z-score
combined_matrix <- rbind(mat_als, mat_ctrl)
zscore_matrix <- t(scale(t(combined_matrix)))
zscore_matrix[is.na(zscore_matrix) | is.infinite(zscore_matrix)] <- 0

png(file.path(output_dir, "FIGURA_2.5_HEATMAP_ZSCORE_SEED_GT.png"), 
    width = 12, height = 12, units = "in", res = 300)

pheatmap(zscore_matrix,
         main = "G>T VAF Z-score by Position (miRNAs with seed G>T)",
         color = colorRampPalette(c("blue", "white", "red"))(100),
         breaks = seq(-3, 3, length.out = 101),
         cluster_cols = FALSE,
         fontsize = 9)

dev.off()
cat("✅ Figura 2.5 actualizada\n\n")

# ---- FIGURA 2.7: PCA (Solo miRNAs con G>T en seed) ----
cat("📊 Re-generando Figura 2.7: PCA (muestras usando miRNAs seed G>T)...\n")

# Crear matriz de VAF por muestra usando SOLO miRNAs con G>T en seed
pca_matrix <- vaf_gt_all %>%
  filter(miRNA_name %in% top30_seed_gt) %>%  # FILTRO CLAVE
  group_by(Sample_ID, miRNA_name) %>%
  summarise(Total_VAF = sum(VAF, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = miRNA_name, values_from = Total_VAF, values_fill = 0)

pca_samples <- pca_matrix$Sample_ID
pca_data <- as.matrix(pca_matrix[, -1])
rownames(pca_data) <- pca_samples

# PCA
pca_result <- prcomp(pca_data, scale. = TRUE, center = TRUE)

pca_coords <- data.frame(
  Sample_ID = pca_samples,
  PC1 = pca_result$x[, 1],
  PC2 = pca_result$x[, 2]
) %>%
  left_join(metadata, by = "Sample_ID")

# Total VAF para tamaño de punto
total_vaf_per_sample <- vaf_gt_all %>%
  filter(miRNA_name %in% top30_seed_gt) %>%
  group_by(Sample_ID) %>%
  summarise(Total_VAF = sum(VAF, na.rm = TRUE), .groups = "drop")

pca_coords <- pca_coords %>%
  left_join(total_vaf_per_sample, by = "Sample_ID")

var_explained <- summary(pca_result)$importance[2, ] * 100

figure_2_7 <- ggplot(pca_coords, aes(x = PC1, y = PC2, color = Group, size = Total_VAF)) +
  geom_point(alpha = 0.6) +
  stat_ellipse(aes(fill = Group), geom = "polygon", alpha = 0.1, level = 0.95) +
  scale_color_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  scale_size_continuous(range = c(1, 5), name = "Total G>T VAF\n(seed miRNAs)") +
  labs(
    title = "PCA: Samples by Seed G>T VAF Profile",
    subtitle = paste0("Using ", length(top30_seed_gt), " miRNAs with G>T in seed region (2-8)"),
    x = paste0("PC1 (", round(var_explained[1], 1), "%)"),
    y = paste0("PC2 (", round(var_explained[2], 1), "%)")
  ) +
  theme_professional +
  theme(legend.position = "right")

ggsave(file.path(output_dir, "FIGURA_2.7_PCA_SAMPLES_SEED_GT.png"), 
       plot = figure_2_7, width = 12, height = 9, dpi = 300)
cat("✅ Figura 2.7 actualizada\n\n")

# ---- FIGURA 2.8: HEATMAP CLUSTERING (miRNAs con G>T en seed) ----
cat("📊 Re-generando Figura 2.8: Clustering jerárquico (seed G>T miRNAs)...\n")

# Usar los top 30 miRNAs con G>T en seed
heatmap_data <- pca_data[, colnames(pca_data) %in% top30_seed_gt]

# Z-score por columna
heatmap_zscore <- scale(heatmap_data)
heatmap_zscore[is.na(heatmap_zscore) | is.infinite(heatmap_zscore)] <- 0

# Anotaciones
annotation_row <- data.frame(
  Group = metadata$Group[match(rownames(heatmap_zscore), metadata$Sample_ID)]
)
rownames(annotation_row) <- rownames(heatmap_zscore)

annotation_colors <- list(
  Group = c(ALS = COLOR_ALS, Control = COLOR_CONTROL)
)

png(file.path(output_dir, "FIGURA_2.8_HEATMAP_CLUSTERING_SEED_GT.png"), 
    width = 14, height = 12, units = "in", res = 300)

pheatmap(heatmap_zscore,
         main = paste0("Hierarchical Clustering: Samples by Seed G>T miRNAs (n=", ncol(heatmap_zscore), ")"),
         color = colorRampPalette(c("blue", "white", "red"))(100),
         breaks = seq(-3, 3, length.out = 101),
         annotation_row = annotation_row,
         annotation_colors = annotation_colors,
         show_rownames = FALSE,
         show_colnames = TRUE,
         fontsize = 8,
         fontsize_col = 7,
         clustering_method = "ward.D2")

dev.off()
cat("✅ Figura 2.8 actualizada\n\n")

# ============================================================================
# RESUMEN
# ============================================================================

cat("\n", paste(rep("=", 70), collapse = ""), "\n")
cat("✅ FIGURAS RE-GENERADAS CON CRITERIO SEED G>T\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

cat("📊 CRITERIO DE SELECCIÓN:\n")
cat("   ✓ Solo miRNAs con SNVs G>T en región semilla (posiciones 2-8)\n")
cat("   ✓ Ordenados por VAF total de G>T en seed (mayor a menor)\n")
cat("   ✓ Top 20 para análisis detallado\n")
cat("   ✓ Top 30 para PCA y clustering\n\n")

cat("📁 FIGURAS ACTUALIZADAS:\n")
cat("   ✓ FIGURA_2.3_VOLCANO_PLOT_SEED_GT.png\n")
cat("   ✓ FIGURA_2.4_HEATMAP_POSITIONAL_SEED_GT.png\n")
cat("   ✓ FIGURA_2.5_HEATMAP_ZSCORE_SEED_GT.png\n")
cat("   ✓ FIGURA_2.7_PCA_SAMPLES_SEED_GT.png\n")
cat("   ✓ FIGURA_2.8_HEATMAP_CLUSTERING_SEED_GT.png\n\n")

cat("🎯 SIGUIENTE PASO: Crear HTML viewer actualizado\n")

# Guardar lista de miRNAs seleccionados
write.csv(seed_gt_mirnas, "TOP_miRNAs_SEED_GT.csv", row.names = FALSE)
cat("📋 Lista de miRNAs guardada en: TOP_miRNAs_SEED_GT.csv\n")

