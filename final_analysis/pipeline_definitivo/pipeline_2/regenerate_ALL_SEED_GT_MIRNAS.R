# ============================================================================
# RE-GENERAR FIGURAS USANDO **TODOS** LOS miRNAs CON G>T EN SEED
# (No solo top 30, sino los 301 completos)
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
library(ggrepel)

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

cat("🎯 RE-GENERANDO CON TODOS LOS miRNAs SEED G>T\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

# Cargar datos (ya filtrados si existe, sino usar original)
cat("📊 Cargando datos...\n")
if (file.exists("final_processed_data_FILTERED_VAF50.csv")) {
  data <- read.csv("final_processed_data_FILTERED_VAF50.csv")
  cat("✅ Usando datos FILTRADOS (VAF < 0.5)\n")
} else {
  data <- read.csv("../../../final_analysis/processed_data/final_processed_data.csv")
  cat("✅ Usando datos ORIGINALES\n")
}

metadata <- read.csv("metadata.csv")
sample_cols <- metadata$Sample_ID

output_dir <- "figures_paso2_ALL_SEED"
if (!dir.exists(output_dir)) {
  dir.create(output_dir)
}

# ============================================================================
# IDENTIFICAR **TODOS** LOS miRNAs CON G>T EN SEED
# ============================================================================

cat("\n🎯 IDENTIFICANDO TODOS LOS miRNAs CON G>T EN SEED (2-8)...\n")

seed_gt_data <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^[0-9]+"))) %>%
  filter(position >= 2, position <= 8)

# Lista completa de miRNAs con G>T en seed
all_seed_gt_mirnas <- unique(seed_gt_data$miRNA_name)

cat("\n📊 RESULTADOS:\n")
cat("   ✅ Total miRNAs con G>T en seed:", length(all_seed_gt_mirnas), "\n")
cat("   ✅ Usaremos TODOS estos miRNAs (no solo top 30)\n\n")

# Calcular VAF por miRNA para ordenamiento
seed_gt_summary <- seed_gt_data %>%
  select(all_of(c("miRNA_name", "pos.mut", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  group_by(miRNA_name) %>%
  summarise(
    Total_Seed_GT_VAF = sum(VAF, na.rm = TRUE),
    Mean_Seed_GT_VAF = mean(VAF, na.rm = TRUE),
    N_Seed_GT_SNVs = n_distinct(pos.mut),
    .groups = "drop"
  ) %>%
  arrange(desc(Total_Seed_GT_VAF))

cat("🔝 TOP 10 miRNAs (de los", length(all_seed_gt_mirnas), "totales):\n")
print(head(seed_gt_summary, 10))
cat("\n")

# Guardar lista completa
write.csv(seed_gt_summary, "ALL_SEED_GT_miRNAs_COMPLETE.csv", row.names = FALSE)
cat("📋 Lista completa guardada en: ALL_SEED_GT_miRNAs_COMPLETE.csv\n\n")

# ============================================================================
# PREPARAR DATOS PARA FIGURAS
# ============================================================================

cat("📊 Preparando datos de G>T para análisis...\n")

# Todos los G>T (no solo seed)
vaf_gt_all <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  select(all_of(c("miRNA_name", "pos.mut", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  left_join(metadata, by = "Sample_ID") %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^[0-9]+")))

# Solo miRNAs con G>T en seed (pero datos de todas las posiciones)
vaf_gt_seed_mirnas <- vaf_gt_all %>%
  filter(miRNA_name %in% all_seed_gt_mirnas)

cat("✅ Datos preparados:\n")
cat("   - Total SNVs G>T:", nrow(vaf_gt_all), "\n")
cat("   - SNVs G>T de miRNAs con seed G>T:", nrow(vaf_gt_seed_mirnas), "\n\n")

# ============================================================================
# FIGURA 2.3: VOLCANO PLOT (TODOS los miRNAs seed G>T)
# ============================================================================

cat("📊 Generando Figura 2.3: Volcano Plot (", length(all_seed_gt_mirnas), " miRNAs)...\n")

volcano_data <- data.frame()
for (mirna in all_seed_gt_mirnas) {
  mirna_data <- vaf_gt_all %>% filter(miRNA_name == mirna)
  
  als_vals <- mirna_data %>% filter(Group == "ALS") %>% pull(VAF)
  ctrl_vals <- mirna_data %>% filter(Group == "Control") %>% pull(VAF)
  
  als_vals <- als_vals[!is.na(als_vals)]
  ctrl_vals <- ctrl_vals[!is.na(ctrl_vals)]
  
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

top_labels <- volcano_data %>%
  filter(Significance != "NS") %>%
  arrange(padj) %>%
  head(15)

figure_2_3 <- ggplot(volcano_data, aes(x = log2FC, y = neg_log10_padj, color = Significance)) +
  geom_point(alpha = 0.6, size = 2.5) +
  geom_hline(yintercept = -log10(0.05), linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = c(-0.58, 0.58), linetype = "dashed", color = "gray50") +
  scale_color_manual(values = c("ALS enriched" = COLOR_ALS, 
                                "Control enriched" = "steelblue",
                                "NS" = "gray70")) +
  labs(
    title = "Volcano Plot: ALL miRNAs with G>T in SEED Region",
    subtitle = paste0("G>T VAF comparison (ALS vs Control) | n=", nrow(volcano_data), " miRNAs"),
    x = "log2(Fold Change)",
    y = "-log10(FDR-adjusted p-value)"
  ) +
  theme_professional +
  theme(legend.position = "bottom")

if (nrow(top_labels) > 0) {
  figure_2_3 <- figure_2_3 +
    geom_text_repel(data = top_labels, aes(label = miRNA), 
                    size = 3, max.overlaps = 20, color = "black")
}

ggsave(file.path(output_dir, "FIGURA_2.3_VOLCANO_ALL_SEED_GT.png"), 
       plot = figure_2_3, width = 14, height = 11, dpi = 300)
cat("✅ Figura 2.3 guardada (n =", nrow(volcano_data), "miRNAs)\n\n")

# ============================================================================
# FIGURA 2.7: PCA (TODOS los miRNAs seed G>T)
# ============================================================================

cat("📊 Generando Figura 2.7: PCA (", length(all_seed_gt_mirnas), " miRNAs)...\n")

pca_matrix <- vaf_gt_all %>%
  filter(miRNA_name %in% all_seed_gt_mirnas) %>%
  group_by(Sample_ID, miRNA_name) %>%
  summarise(Total_VAF = sum(VAF, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = miRNA_name, values_from = Total_VAF, values_fill = 0)

pca_samples <- pca_matrix$Sample_ID
pca_data <- as.matrix(pca_matrix[, -1])
rownames(pca_data) <- pca_samples

# Filtrar columnas con varianza muy baja
col_vars <- apply(pca_data, 2, var, na.rm = TRUE)
pca_data <- pca_data[, col_vars > 0.001]

cat("   - miRNAs usados en PCA:", ncol(pca_data), "\n")

pca_result <- prcomp(pca_data, scale. = TRUE, center = TRUE)

pca_coords <- data.frame(
  Sample_ID = pca_samples,
  PC1 = pca_result$x[, 1],
  PC2 = pca_result$x[, 2]
) %>%
  left_join(metadata, by = "Sample_ID")

total_vaf_per_sample <- vaf_gt_all %>%
  filter(miRNA_name %in% all_seed_gt_mirnas) %>%
  group_by(Sample_ID) %>%
  summarise(Total_VAF = sum(VAF, na.rm = TRUE), .groups = "drop")

pca_coords <- pca_coords %>%
  left_join(total_vaf_per_sample, by = "Sample_ID")

var_explained <- summary(pca_result)$importance[2, ] * 100

figure_2_7 <- ggplot(pca_coords, aes(x = PC1, y = PC2, color = Group, size = Total_VAF)) +
  geom_point(alpha = 0.6) +
  stat_ellipse(aes(fill = Group, group = Group), geom = "polygon", alpha = 0.1, level = 0.95, show.legend = FALSE) +
  scale_color_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  scale_size_continuous(range = c(1, 5), name = "Total G>T VAF") +
  labs(
    title = "PCA: Samples by ALL Seed G>T miRNAs",
    subtitle = paste0("Using ALL ", length(all_seed_gt_mirnas), " miRNAs with G>T in seed region (2-8)"),
    x = paste0("PC1 (", round(var_explained[1], 1), "%)"),
    y = paste0("PC2 (", round(var_explained[2], 1), "%)")
  ) +
  theme_professional +
  theme(legend.position = "right")

ggsave(file.path(output_dir, "FIGURA_2.7_PCA_ALL_SEED_GT.png"), 
       plot = figure_2_7, width = 13, height = 10, dpi = 300)
cat("✅ Figura 2.7 guardada\n\n")

# ============================================================================
# FIGURA 2.8: CLUSTERING (TODOS los miRNAs seed G>T)
# ============================================================================

cat("📊 Generando Figura 2.8: Clustering (", length(all_seed_gt_mirnas), " miRNAs)...\n")

# Usar TODOS los miRNAs seed G>T
heatmap_data <- pca_data  # Ya tiene todos los miRNAs seed

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

png(file.path(output_dir, "FIGURA_2.8_HEATMAP_ALL_SEED_GT.png"), 
    width = 18, height = 14, units = "in", res = 300)

pheatmap(heatmap_zscore,
         main = paste0("Hierarchical Clustering: ALL ", ncol(heatmap_zscore), " miRNAs with Seed G>T"),
         color = colorRampPalette(c("blue", "white", "red"))(100),
         breaks = seq(-3, 3, length.out = 101),
         annotation_row = annotation_row,
         annotation_colors = annotation_colors,
         show_rownames = FALSE,
         show_colnames = FALSE,  # Demasiados miRNAs para mostrar nombres
         fontsize = 8,
         clustering_method = "ward.D2")

dev.off()
cat("✅ Figura 2.8 guardada\n\n")

# ============================================================================
# FIGURA 2.4: HEATMAP POSICIONAL (Top 50 de TODOS los seed G>T)
# ============================================================================

cat("📊 Generando Figura 2.4: Heatmap posicional (top 50 de ", length(all_seed_gt_mirnas), ")...\n")

# Seleccionar top 50 para visualización (de los 301)
top50_for_viz <- head(seed_gt_summary, 50)$miRNA_name

vaf_gt_positional <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^[0-9]+"))) %>%
  filter(!is.na(position), position <= 22) %>%
  filter(miRNA_name %in% top50_for_viz)

vaf_matrix_data <- vaf_gt_positional %>%
  select(all_of(c("miRNA_name", "position", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  left_join(metadata, by = "Sample_ID") %>%
  group_by(miRNA_name, position, Group) %>%
  summarise(Mean_VAF = mean(VAF, na.rm = TRUE), .groups = "drop")

create_heatmap_matrix <- function(group_name) {
  matrix_data <- vaf_matrix_data %>%
    filter(Group == group_name) %>%
    select(miRNA_name, position, Mean_VAF) %>%
    pivot_wider(names_from = position, values_from = Mean_VAF, values_fill = 0) %>%
    column_to_rownames("miRNA_name")
  
  all_positions <- as.character(1:22)
  for (pos in setdiff(all_positions, colnames(matrix_data))) {
    matrix_data[[pos]] <- 0
  }
  
  matrix_data <- matrix_data[, all_positions]
  return(as.matrix(matrix_data))
}

png(file.path(output_dir, "FIGURA_2.4_HEATMAP_TOP50_ALL_SEED_GT.png"), 
    width = 14, height = 14, units = "in", res = 300)

par(mfrow = c(1, 2))

mat_als <- create_heatmap_matrix("ALS")
pheatmap(mat_als,
         main = paste0("ALS: Top 50 miRNAs (of ", length(all_seed_gt_mirnas), " with seed G>T)"),
         color = colorRampPalette(c("white", COLOR_ALS))(100),
         cluster_cols = FALSE,
         fontsize = 8,
         silent = TRUE)

mat_ctrl <- create_heatmap_matrix("Control")
pheatmap(mat_ctrl,
         main = paste0("Control: Top 50 miRNAs (of ", length(all_seed_gt_mirnas), " with seed G>T)"),
         color = colorRampPalette(c("white", COLOR_CONTROL))(100),
         cluster_cols = FALSE,
         fontsize = 8,
         silent = TRUE)

dev.off()
cat("✅ Figura 2.4 guardada\n\n")

# ============================================================================
# FIGURA 2.5: HEATMAP Z-SCORE (Top 50)
# ============================================================================

cat("📊 Generando Figura 2.5: Heatmap Z-score (top 50)...\n")

combined_matrix <- rbind(mat_als, mat_ctrl)
zscore_matrix <- t(scale(t(combined_matrix)))
zscore_matrix[is.na(zscore_matrix) | is.infinite(zscore_matrix)] <- 0

png(file.path(output_dir, "FIGURA_2.5_HEATMAP_ZSCORE_TOP50.png"), 
    width = 12, height = 14, units = "in", res = 300)

pheatmap(zscore_matrix,
         main = paste0("Z-score: Top 50 miRNAs (of ", length(all_seed_gt_mirnas), " with seed G>T)"),
         color = colorRampPalette(c("blue", "white", "red"))(100),
         breaks = seq(-3, 3, length.out = 101),
         cluster_cols = FALSE,
         fontsize = 8)

dev.off()
cat("✅ Figura 2.5 guardada\n\n")

# ============================================================================
# RESUMEN
# ============================================================================

cat("\n", paste(rep("=", 70), collapse = ""), "\n")
cat("✅ FIGURAS RE-GENERADAS CON TODOS LOS miRNAs SEED G>T\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

cat("📊 RESUMEN:\n")
cat("   ✓ Total miRNAs con G>T en seed:", length(all_seed_gt_mirnas), "\n")
cat("   ✓ Usados en Volcano Plot:", nrow(volcano_data), "\n")
cat("   ✓ Usados en PCA:", ncol(pca_data), "\n")
cat("   ✓ Usados en Clustering:", ncol(heatmap_zscore), "\n")
cat("   ✓ Mostrados en heatmaps posicionales: Top 50\n\n")

cat("📁 ARCHIVOS GENERADOS:\n")
cat("   ✓ ALL_SEED_GT_miRNAs_COMPLETE.csv (lista de", length(all_seed_gt_mirnas), "miRNAs)\n")
cat("   ✓ FIGURA_2.3_VOLCANO_ALL_SEED_GT.png\n")
cat("   ✓ FIGURA_2.4_HEATMAP_TOP50_ALL_SEED_GT.png\n")
cat("   ✓ FIGURA_2.5_HEATMAP_ZSCORE_TOP50.png\n")
cat("   ✓ FIGURA_2.7_PCA_ALL_SEED_GT.png\n")
cat("   ✓ FIGURA_2.8_HEATMAP_ALL_SEED_GT.png\n\n")

cat("📊 Directorio:", output_dir, "\n")
cat("🎉 GENERACIÓN COMPLETADA\n")

