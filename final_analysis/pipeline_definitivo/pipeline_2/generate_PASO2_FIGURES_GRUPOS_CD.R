# ============================================================================
# PASO 2: GRUPOS C y D (Figuras 2.7 a 2.12)
# Heterogeneidad, Clustering y Especificidad G>T
# ============================================================================

library(ggplot2)
library(dplyr)
library(tidyr)
library(stringr)
library(patchwork)
library(viridis)
library(pheatmap)
library(FactoMineR)
library(factoextra)
library(tibble)

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

cat("🎯 GENERANDO FIGURAS GRUPOS C y D\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

# Cargar datos
cat("📊 Cargando datos...\n")
data <- read.csv("../../../final_analysis/processed_data/final_processed_data.csv")
metadata <- read.csv("metadata.csv")
sample_cols <- metadata$Sample_ID

output_dir <- "figures_paso2"
if (!dir.exists(output_dir)) {
  dir.create(output_dir)
}

# Preparar datos G>T
vaf_gt <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  select(all_of(c("miRNA_name", "pos.mut", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  left_join(metadata, by = "Sample_ID")

# ============================================================================
# GRUPO C: HETEROGENEIDAD Y CLUSTERING
# ============================================================================

cat("\n📊 GRUPO C: HETEROGENEIDAD Y CLUSTERING\n")
cat(paste(rep("-", 70), collapse = ""), "\n\n")

# ---- FIGURA 2.7: PCA DE MUESTRAS ----
cat("📊 Generando Figura 2.7: PCA de muestras...\n")

# Crear matriz de VAF por muestra y miRNA
pca_matrix <- vaf_gt %>%
  group_by(Sample_ID, miRNA_name) %>%
  summarise(Total_VAF = sum(VAF, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = miRNA_name, values_from = Total_VAF, values_fill = 0)

# Separar IDs y matriz
pca_samples <- pca_matrix$Sample_ID
pca_data <- as.matrix(pca_matrix[, -1])
rownames(pca_data) <- pca_samples

# Filtrar columnas con poca variabilidad
col_vars <- apply(pca_data, 2, var, na.rm = TRUE)
pca_data <- pca_data[, col_vars > quantile(col_vars, 0.5, na.rm = TRUE)]

# PCA
pca_result <- prcomp(pca_data, scale. = TRUE, center = TRUE)

# Extraer coordenadas
pca_coords <- data.frame(
  Sample_ID = pca_samples,
  PC1 = pca_result$x[, 1],
  PC2 = pca_result$x[, 2]
) %>%
  left_join(metadata, by = "Sample_ID")

# Calcular VAF total para tamaño de punto
total_vaf_per_sample <- vaf_gt %>%
  group_by(Sample_ID) %>%
  summarise(Total_VAF = sum(VAF, na.rm = TRUE), .groups = "drop")

pca_coords <- pca_coords %>%
  left_join(total_vaf_per_sample, by = "Sample_ID")

# Varianza explicada
var_explained <- summary(pca_result)$importance[2, ] * 100

figure_2_7 <- ggplot(pca_coords, aes(x = PC1, y = PC2, color = Group, size = Total_VAF)) +
  geom_point(alpha = 0.6) +
  stat_ellipse(aes(fill = Group), geom = "polygon", alpha = 0.1, level = 0.95) +
  scale_color_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  scale_size_continuous(range = c(1, 5), name = "Total G>T VAF") +
  labs(
    title = "PCA: Samples by G>T VAF Profile",
    subtitle = paste0("Separation of ALS vs Control samples"),
    x = paste0("PC1 (", round(var_explained[1], 1), "%)"),
    y = paste0("PC2 (", round(var_explained[2], 1), "%)")
  ) +
  theme_professional +
  theme(legend.position = "right")

ggsave(file.path(output_dir, "FIGURA_2.7_PCA_SAMPLES.png"), 
       plot = figure_2_7, width = 12, height = 9, dpi = 300)
cat("✅ Figura 2.7 guardada\n\n")

# ---- FIGURA 2.8: HEATMAP CON CLUSTERING JERÁRQUICO ----
cat("📊 Generando Figura 2.8: Heatmap de muestras...\n")

# Seleccionar top 50 miRNAs con mayor variabilidad
mirna_var <- apply(pca_data, 2, var, na.rm = TRUE)
top50_mirnas <- names(sort(mirna_var, decreasing = TRUE)[1:min(50, length(mirna_var))])

# Crear matriz para heatmap
heatmap_data <- pca_data[, top50_mirnas]

# Z-score por columna (miRNA)
heatmap_zscore <- scale(heatmap_data)

# Crear anotaciones
annotation_row <- data.frame(
  Group = metadata$Group[match(rownames(heatmap_zscore), metadata$Sample_ID)]
)
rownames(annotation_row) <- rownames(heatmap_zscore)

annotation_colors <- list(
  Group = c(ALS = COLOR_ALS, Control = COLOR_CONTROL)
)

# Guardar heatmap
png(file.path(output_dir, "FIGURA_2.8_HEATMAP_CLUSTERING.png"), 
    width = 14, height = 12, units = "in", res = 300)

pheatmap(heatmap_zscore,
         main = "Hierarchical Clustering: Samples by G>T VAF Profile",
         color = colorRampPalette(c("blue", "white", "red"))(100),
         breaks = seq(-3, 3, length.out = 101),
         annotation_row = annotation_row,
         annotation_colors = annotation_colors,
         show_rownames = FALSE,
         show_colnames = TRUE,
         fontsize = 8,
         fontsize_col = 6,
         clustering_method = "ward.D2")

dev.off()
cat("✅ Figura 2.8 guardada\n\n")

# ---- FIGURA 2.9: COEFICIENTE DE VARIACIÓN ----
cat("📊 Generando Figura 2.9: Coeficiente de variación...\n")

# CV por miRNA y grupo
cv_data <- vaf_gt %>%
  group_by(miRNA_name, Group) %>%
  summarise(
    Mean_VAF = mean(VAF, na.rm = TRUE),
    SD_VAF = sd(VAF, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(CV = SD_VAF / Mean_VAF * 100) %>%
  filter(!is.infinite(CV), !is.nan(CV))

# Panel A: CV promedio por grupo
cv_summary <- cv_data %>%
  group_by(Group) %>%
  summarise(
    Mean_CV = mean(CV, na.rm = TRUE),
    SE_CV = sd(CV, na.rm = TRUE) / sqrt(n()),
    .groups = "drop"
  )

panel_2_9_a <- ggplot(cv_summary, aes(x = Group, y = Mean_CV, fill = Group)) +
  geom_col(width = 0.6) +
  geom_errorbar(aes(ymin = Mean_CV - SE_CV, ymax = Mean_CV + SE_CV), width = 0.2) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  labs(
    title = "A. Mean Coefficient of Variation",
    subtitle = "G>T VAF heterogeneity within groups",
    x = NULL,
    y = "Mean CV (%)"
  ) +
  theme_professional +
  theme(legend.position = "none")

# Panel B: Distribución de CV
panel_2_9_b <- ggplot(cv_data, aes(x = Group, y = CV, fill = Group)) +
  geom_boxplot(alpha = 0.7, outlier.shape = NA) +
  geom_jitter(width = 0.2, alpha = 0.1, size = 0.5) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  coord_cartesian(ylim = c(0, quantile(cv_data$CV, 0.95, na.rm = TRUE))) +
  labs(
    title = "B. CV Distribution Across miRNAs",
    x = NULL,
    y = "CV (%)"
  ) +
  theme_professional +
  theme(legend.position = "none")

# Test F
f_test <- var.test(CV ~ Group, data = cv_data)

panel_2_9_c <- ggplot() +
  annotate("text", x = 0.5, y = 0.7,
           label = paste0("F-test for variance equality:\np = ",
                         format.pval(f_test$p.value, digits = 3)),
           size = 5, hjust = 0.5) +
  annotate("text", x = 0.5, y = 0.4,
           label = ifelse(f_test$p.value < 0.05,
                         "Significant difference in heterogeneity",
                         "No significant difference"),
           size = 4, hjust = 0.5, fontface = "italic") +
  xlim(0, 1) + ylim(0, 1) +
  theme_void()

figure_2_9 <- (panel_2_9_a | panel_2_9_b) / panel_2_9_c
ggsave(file.path(output_dir, "FIGURA_2.9_COEFFICIENT_VARIATION.png"), 
       plot = figure_2_9, width = 12, height = 10, dpi = 300)
cat("✅ Figura 2.9 guardada\n\n")

# ============================================================================
# GRUPO D: ESPECIFICIDAD G>T
# ============================================================================

cat("\n📊 GRUPO D: ESPECIFICIDAD G>T\n")
cat(paste(rep("-", 70), collapse = ""), "\n\n")

# ---- FIGURA 2.10: RATIO G>T / G>A ----
cat("📊 Generando Figura 2.10: Ratio G>T/G>A...\n")

# Calcular VAF para G>T y G>A por muestra
vaf_ga <- data %>%
  filter(str_detect(pos.mut, ":GA$")) %>%
  select(all_of(c("miRNA_name", "pos.mut", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  group_by(Sample_ID) %>%
  summarise(GA_VAF = sum(VAF, na.rm = TRUE), .groups = "drop")

vaf_gt_total <- vaf_gt %>%
  group_by(Sample_ID, Group) %>%
  summarise(GT_VAF = sum(VAF, na.rm = TRUE), .groups = "drop")

ratio_data <- vaf_gt_total %>%
  left_join(vaf_ga, by = "Sample_ID") %>%
  mutate(
    GA_VAF = replace_na(GA_VAF, 0),
    Ratio = GT_VAF / (GA_VAF + 0.001)  # Evitar división por cero
  )

# Panel A: Scatter plot
panel_2_10_a <- ggplot(ratio_data, aes(x = GA_VAF, y = GT_VAF, color = Group)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "gray50") +
  geom_point(alpha = 0.5, size = 2) +
  annotate("text", x = max(ratio_data$GA_VAF) * 0.7, y = max(ratio_data$GT_VAF) * 0.9,
           label = "G>T enriched zone", color = "red", fontface = "italic") +
  scale_color_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  scale_x_log10(labels = scales::comma) +
  scale_y_log10(labels = scales::comma) +
  labs(
    title = "A. G>T vs G>A VAF",
    x = "G>A VAF (log scale)",
    y = "G>T VAF (log scale)"
  ) +
  theme_professional +
  theme(legend.position = "bottom")

# Panel B: Boxplot de ratio
panel_2_10_b <- ggplot(ratio_data, aes(x = Group, y = Ratio, fill = Group)) +
  geom_boxplot(alpha = 0.7, outlier.shape = NA) +
  geom_jitter(width = 0.2, alpha = 0.3, size = 1.5) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  scale_y_log10() +
  labs(
    title = "B. G>T / G>A Ratio",
    subtitle = paste0("Wilcoxon p = ",
                     format.pval(wilcox.test(Ratio ~ Group, data = ratio_data)$p.value, digits = 3)),
    x = NULL,
    y = "G>T / G>A Ratio (log scale)"
  ) +
  theme_professional +
  theme(legend.position = "none")

# Panel C: Density
panel_2_10_c <- ggplot(ratio_data, aes(x = Ratio, fill = Group)) +
  geom_density(alpha = 0.5) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  scale_x_log10() +
  labs(
    title = "C. Ratio Distribution",
    x = "G>T / G>A Ratio (log scale)",
    y = "Density"
  ) +
  theme_professional +
  theme(legend.position = "bottom")

figure_2_10 <- panel_2_10_a / (panel_2_10_b | panel_2_10_c)
ggsave(file.path(output_dir, "FIGURA_2.10_RATIO_GT_GA.png"), 
       plot = figure_2_10, width = 12, height = 12, dpi = 300)
cat("✅ Figura 2.10 guardada\n\n")

# ---- FIGURA 2.11: HEATMAP DE TIPOS DE MUTACIÓN ----
cat("📊 Generando Figura 2.11: Heatmap de tipos de mutación...\n")

# Extraer todos los tipos de mutación
all_mutations <- data %>%
  mutate(
    position = as.numeric(str_extract(pos.mut, "^\\d+")),
    mutation_type = str_extract(pos.mut, ":\\w+$") %>% str_remove(":")
  ) %>%
  filter(!is.na(position), position <= 22)

# VAF por tipo de mutación, posición y grupo
mutation_heatmap_data <- all_mutations %>%
  select(all_of(c("mutation_type", "position", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  left_join(metadata, by = "Sample_ID") %>%
  group_by(mutation_type, position, Group) %>%
  summarise(Mean_VAF = mean(VAF, na.rm = TRUE), .groups = "drop")

# Crear matrices para cada grupo
create_mutation_matrix <- function(group_name) {
  matrix_data <- mutation_heatmap_data %>%
    filter(Group == group_name) %>%
    select(mutation_type, position, Mean_VAF) %>%
    pivot_wider(names_from = position, values_from = Mean_VAF, values_fill = 0)
  
  # Reordenar tipos de mutación
  mutation_order <- c("GT", "GA", "GC", "AT", "AG", "AC", "TC", "TG", "TA", "CT", "CG", "CA")
  matrix_data <- matrix_data %>%
    filter(mutation_type %in% mutation_order) %>%
    arrange(match(mutation_type, mutation_order))
  
  mat <- as.matrix(matrix_data[, -1])
  rownames(mat) <- matrix_data$mutation_type
  colnames(mat) <- names(matrix_data)[-1]
  
  return(mat)
}

# Crear heatmaps
png(file.path(output_dir, "FIGURA_2.11_HEATMAP_MUTATION_TYPES.png"), 
    width = 16, height = 10, units = "in", res = 300)

par(mfrow = c(1, 2))

# ALS
mat_als <- create_mutation_matrix("ALS")
pheatmap(mat_als,
         main = "ALS: All Mutation Types by Position",
         color = colorRampPalette(c("white", "orange", "red"))(100),
         cluster_rows = FALSE,
         cluster_cols = FALSE,
         fontsize = 10,
         silent = TRUE)

# Control
mat_ctrl <- create_mutation_matrix("Control")
pheatmap(mat_ctrl,
         main = "Control: All Mutation Types by Position",
         color = colorRampPalette(c("white", "skyblue", "darkblue"))(100),
         cluster_rows = FALSE,
         cluster_cols = FALSE,
         fontsize = 10,
         silent = TRUE)

dev.off()
cat("✅ Figura 2.11 guardada\n\n")

# ---- FIGURA 2.12: ENRIQUECIMIENTO G>T POR REGIÓN ----
cat("📊 Generando Figura 2.12: Enriquecimiento G>T por región...\n")

# Clasificar posiciones en Seed (2-8) y Non-Seed (resto)
vaf_gt_regions <- vaf_gt %>%
  mutate(
    position = as.numeric(str_extract(pos.mut, "^\\d+")),
    Region = ifelse(position >= 2 & position <= 8, "Seed", "Non-Seed")
  ) %>%
  filter(!is.na(position))

# VAF total por muestra, región y grupo
vaf_by_region <- vaf_gt_regions %>%
  group_by(Sample_ID, Group, Region) %>%
  summarise(Total_VAF = sum(VAF, na.rm = TRUE), .groups = "drop")

# Panel A: Grouped barplot
summary_by_region <- vaf_by_region %>%
  group_by(Group, Region) %>%
  summarise(
    Mean_VAF = mean(Total_VAF, na.rm = TRUE),
    SE_VAF = sd(Total_VAF, na.rm = TRUE) / sqrt(n()),
    .groups = "drop"
  )

# Tests estadísticos
test_seed <- wilcox.test(Total_VAF ~ Group, 
                        data = vaf_by_region %>% filter(Region == "Seed"))
test_nonseed <- wilcox.test(Total_VAF ~ Group, 
                           data = vaf_by_region %>% filter(Region == "Non-Seed"))

panel_2_12_a <- ggplot(summary_by_region, aes(x = Region, y = Mean_VAF, fill = Group)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.7) +
  geom_errorbar(aes(ymin = Mean_VAF - SE_VAF, ymax = Mean_VAF + SE_VAF),
                position = position_dodge(width = 0.8), width = 0.3) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  labs(
    title = "A. G>T VAF by Region",
    subtitle = "Seed (2-8) vs Non-Seed (rest)",
    x = "miRNA Region",
    y = "Mean G>T VAF"
  ) +
  theme_professional +
  theme(legend.position = "bottom")

# Añadir asteriscos de significancia
y_max <- max(summary_by_region$Mean_VAF + summary_by_region$SE_VAF) * 1.1
panel_2_12_a <- panel_2_12_a +
  annotate("text", x = 1, y = y_max, 
           label = ifelse(test_nonseed$p.value < 0.05, "***", "ns"),
           size = 6, color = "red") +
  annotate("text", x = 2, y = y_max,
           label = ifelse(test_seed$p.value < 0.05, "***", "ns"),
           size = 6, color = "red")

# Panel B: Tabla de estadísticas
stats_text <- paste0(
  "Statistical Summary:\n\n",
  "Seed Region:\n",
  "  ALS: ", round(summary_by_region$Mean_VAF[summary_by_region$Group == "ALS" & summary_by_region$Region == "Seed"], 2),
  " ± ", round(summary_by_region$SE_VAF[summary_by_region$Group == "ALS" & summary_by_region$Region == "Seed"], 2), "\n",
  "  Control: ", round(summary_by_region$Mean_VAF[summary_by_region$Group == "Control" & summary_by_region$Region == "Seed"], 2),
  " ± ", round(summary_by_region$SE_VAF[summary_by_region$Group == "Control" & summary_by_region$Region == "Seed"], 2), "\n",
  "  p = ", format.pval(test_seed$p.value, digits = 3), "\n\n",
  "Non-Seed Region:\n",
  "  ALS: ", round(summary_by_region$Mean_VAF[summary_by_region$Group == "ALS" & summary_by_region$Region == "Non-Seed"], 2),
  " ± ", round(summary_by_region$SE_VAF[summary_by_region$Group == "ALS" & summary_by_region$Region == "Non-Seed"], 2), "\n",
  "  Control: ", round(summary_by_region$Mean_VAF[summary_by_region$Group == "Control" & summary_by_region$Region == "Non-Seed"], 2),
  " ± ", round(summary_by_region$SE_VAF[summary_by_region$Group == "Control" & summary_by_region$Region == "Non-Seed"], 2), "\n",
  "  p = ", format.pval(test_nonseed$p.value, digits = 3)
)

panel_2_12_b <- ggplot() +
  annotate("text", x = 0.5, y = 0.5, label = stats_text, 
           size = 4, hjust = 0.5, vjust = 0.5, family = "mono") +
  xlim(0, 1) + ylim(0, 1) +
  labs(title = "B. Statistical Tests") +
  theme_void() +
  theme(plot.title = element_text(size = 14, face = "bold", hjust = 0.5))

figure_2_12 <- panel_2_12_a | panel_2_12_b
ggsave(file.path(output_dir, "FIGURA_2.12_GT_ENRICHMENT_REGIONS.png"), 
       plot = figure_2_12, width = 14, height = 6, dpi = 300)
cat("✅ Figura 2.12 guardada\n\n")

# ============================================================================
# RESUMEN FINAL
# ============================================================================

cat("\n", paste(rep("=", 70), collapse = ""), "\n")
cat("✅ TODAS LAS FIGURAS DEL PASO 2 COMPLETADAS\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

cat("📁 Directorio de salida:", output_dir, "\n\n")

cat("📊 FIGURAS GENERADAS:\n")
cat("   GRUPO A - Comparaciones Globales:\n")
cat("     ✓ 2.1: Comparación VAF Global\n")
cat("     ✓ 2.2: Distribuciones VAF\n")
cat("     ✓ 2.3: Volcano Plot\n\n")
cat("   GRUPO B - Análisis Posicional:\n")
cat("     ✓ 2.4: Heatmap VAF por Posición\n")
cat("     ✓ 2.5: Heatmap Z-score\n")
cat("     ✓ 2.6: Perfiles Posicionales\n\n")
cat("   GRUPO C - Heterogeneidad:\n")
cat("     ✓ 2.7: PCA de Muestras\n")
cat("     ✓ 2.8: Clustering Jerárquico\n")
cat("     ✓ 2.9: Coeficiente de Variación\n\n")
cat("   GRUPO D - Especificidad G>T:\n")
cat("     ✓ 2.10: Ratio G>T/G>A\n")
cat("     ✓ 2.11: Heatmap de Tipos de Mutación\n")
cat("     ✓ 2.12: Enriquecimiento por Región\n\n")

cat("🎉 PASO 2 COMPLETADO EXITOSAMENTE\n")

