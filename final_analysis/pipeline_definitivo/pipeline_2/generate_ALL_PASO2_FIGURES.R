# ============================================================================
# PASO 2: GENERACIÓN COMPLETA DE LAS 12 FIGURAS
# Análisis comparativo ALS vs Control con datos VAF reales
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

# Configuración de colores
COLOR_ALS <- "#D62728"
COLOR_CONTROL <- "#666666"
COLOR_SEED <- "#FFE135"

# Tema profesional
theme_professional <- theme_minimal() +
  theme(
    text = element_text(size = 14, family = "Helvetica"),
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray40"),
    axis.title = element_text(size = 14, face = "bold"),
    axis.text = element_text(size = 12),
    panel.grid.major = element_line(color = "gray90", linewidth = 0.5),
    panel.grid.minor = element_blank(),
    panel.border = element_rect(color = "gray30", fill = NA, linewidth = 1)
  )

cat("🎯 PASO 2: GENERANDO TODAS LAS FIGURAS\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

# Cargar datos
cat("📊 Cargando datos y metadata...\n")
data <- read.csv("../../../final_analysis/processed_data/final_processed_data.csv")
metadata <- read.csv("metadata.csv")
sample_cols <- metadata$Sample_ID

cat("✅ Datos cargados:\n")
cat("   - SNVs:", nrow(data), "\n")
cat("   - Muestras:", length(sample_cols), "(ALS:", sum(metadata$Group == "ALS"), 
    "| Control:", sum(metadata$Group == "Control"), ")\n\n")

# Crear directorio de salida
output_dir <- "figures_paso2"
if (!dir.exists(output_dir)) {
  dir.create(output_dir)
}

# ============================================================================
# FUNCIONES AUXILIARES
# ============================================================================

# Calcular VAF por muestra y grupo
calculate_vaf_by_group <- function(data, metadata, sample_cols) {
  vaf_data <- data %>%
    select(all_of(c("miRNA_name", "pos.mut", sample_cols))) %>%
    pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
    left_join(metadata, by = "Sample_ID")
  return(vaf_data)
}

# Extraer posición y tipo de mutación
extract_mutation_info <- function(pos_mut) {
  position <- as.numeric(str_extract(pos_mut, "^\\d+"))
  mut_type <- str_extract(pos_mut, ":\\w+$") %>% str_remove(":")
  return(data.frame(position = position, mutation_type = mut_type))
}

# ============================================================================
# GRUPO A: COMPARACIONES GLOBALES
# ============================================================================

cat("📊 GRUPO A: COMPARACIONES GLOBALES\n")
cat(paste(rep("-", 70), collapse = ""), "\n\n")

# ---- FIGURA 2.1: Ya generada anteriormente ----
cat("✅ Figura 2.1 ya generada\n\n")

# ---- FIGURA 2.2: DISTRIBUCIONES VAF ----
cat("📊 Generando Figura 2.2: Distribuciones VAF...\n")

vaf_long <- calculate_vaf_by_group(data, metadata, sample_cols)

# Filtrar solo G>T
vaf_gt <- vaf_long %>%
  filter(str_detect(pos.mut, ":GT$"))

# VAF total por muestra
vaf_summary <- vaf_gt %>%
  group_by(Sample_ID, Group) %>%
  summarise(Total_GT_VAF = sum(VAF, na.rm = TRUE), .groups = "drop")

# Panel A: Violin plot
panel_2_2_a <- ggplot(vaf_summary, aes(x = Group, y = Total_GT_VAF, fill = Group)) +
  geom_violin(alpha = 0.7, trim = FALSE) +
  geom_boxplot(width = 0.1, alpha = 0.5, outlier.shape = NA) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  scale_y_log10(labels = scales::comma) +
  labs(title = "A. G>T VAF Distribution", y = "Total G>T VAF (log scale)", x = NULL) +
  theme_professional +
  theme(legend.position = "none")

# Panel B: Density plot
panel_2_2_b <- ggplot(vaf_summary, aes(x = Total_GT_VAF, fill = Group)) +
  geom_density(alpha = 0.5) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  scale_x_log10(labels = scales::comma) +
  labs(title = "B. G>T VAF Density", x = "Total G>T VAF (log scale)", y = "Density") +
  theme_professional +
  theme(legend.position = "bottom")

# Panel C: CDF
vaf_summary <- vaf_summary %>%
  arrange(Group, Total_GT_VAF) %>%
  group_by(Group) %>%
  mutate(cdf = row_number() / n())

panel_2_2_c <- ggplot(vaf_summary, aes(x = Total_GT_VAF, y = cdf, color = Group)) +
  geom_line(linewidth = 1.5) +
  scale_color_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  scale_x_log10(labels = scales::comma) +
  labs(title = "C. Cumulative Distribution", x = "Total G>T VAF (log scale)", y = "CDF") +
  theme_professional +
  theme(legend.position = "bottom")

# Panel D: Tabla de estadísticas
stats_table <- vaf_summary %>%
  group_by(Group) %>%
  summarise(
    N = n(),
    Mean = mean(Total_GT_VAF, na.rm = TRUE),
    Median = median(Total_GT_VAF, na.rm = TRUE),
    SD = sd(Total_GT_VAF, na.rm = TRUE),
    Q1 = quantile(Total_GT_VAF, 0.25, na.rm = TRUE),
    Q3 = quantile(Total_GT_VAF, 0.75, na.rm = TRUE)
  )

# Crear visualización de tabla
panel_2_2_d <- ggplot() +
  annotate("text", x = 0.5, y = 0.9, 
           label = "Statistical Summary", 
           size = 6, fontface = "bold", hjust = 0.5) +
  annotate("text", x = 0.5, y = 0.75,
           label = paste0("ALS: Mean=", round(stats_table$Mean[1], 2),
                         " | Median=", round(stats_table$Median[1], 2)),
           size = 4, hjust = 0.5) +
  annotate("text", x = 0.5, y = 0.6,
           label = paste0("Control: Mean=", round(stats_table$Mean[2], 2),
                         " | Median=", round(stats_table$Median[2], 2)),
           size = 4, hjust = 0.5) +
  annotate("text", x = 0.5, y = 0.45,
           label = paste0("KS test p = ", 
                         format.pval(ks.test(vaf_summary$Total_GT_VAF[vaf_summary$Group == "ALS"],
                                            vaf_summary$Total_GT_VAF[vaf_summary$Group == "Control"])$p.value,
                                    digits = 3)),
           size = 4, hjust = 0.5, color = "red") +
  xlim(0, 1) + ylim(0, 1) +
  theme_void()

# Combinar
figure_2_2 <- (panel_2_2_a | panel_2_2_b) / (panel_2_2_c | panel_2_2_d)
ggsave(file.path(output_dir, "FIGURA_2.2_VAF_DISTRIBUTIONS.png"), 
       plot = figure_2_2, width = 12, height = 10, dpi = 300)
cat("✅ Figura 2.2 guardada\n\n")

# ---- FIGURA 2.3: VOLCANO PLOT ----
cat("📊 Generando Figura 2.3: Volcano Plot...\n")

# Calcular VAF promedio por miRNA y grupo
vaf_by_mirna <- vaf_gt %>%
  group_by(miRNA_name, Group) %>%
  summarise(Mean_VAF = mean(VAF, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = Group, values_from = Mean_VAF, values_fill = 0)

# Calcular Fold Change y p-value por miRNA
volcano_data <- data.frame()
for (mirna in unique(vaf_by_mirna$miRNA_name)) {
  mirna_data <- vaf_gt %>% filter(miRNA_name == mirna)
  
  als_vals <- mirna_data %>% filter(Group == "ALS") %>% pull(VAF)
  ctrl_vals <- mirna_data %>% filter(Group == "Control") %>% pull(VAF)
  
  if (length(als_vals) > 5 && length(ctrl_vals) > 5) {
    mean_als <- mean(als_vals, na.rm = TRUE)
    mean_ctrl <- mean(ctrl_vals, na.rm = TRUE)
    
    # Evitar log2(0)
    if (mean_als == 0) mean_als <- 0.001
    if (mean_ctrl == 0) mean_ctrl <- 0.001
    
    fc <- log2(mean_als / mean_ctrl)
    
    # Wilcoxon test
    test_result <- tryCatch({
      wilcox.test(als_vals, ctrl_vals)
    }, error = function(e) {
      list(p.value = 1)
    })
    
    volcano_data <- rbind(volcano_data, data.frame(
      miRNA = mirna,
      log2FC = fc,
      pvalue = test_result$p.value
    ))
  }
}

# Ajustar p-values (FDR)
volcano_data$padj <- p.adjust(volcano_data$pvalue, method = "fdr")
volcano_data$neg_log10_padj <- -log10(volcano_data$padj)

# Clasificar miRNAs
volcano_data$Significance <- "NS"
volcano_data$Significance[volcano_data$log2FC > 0.58 & volcano_data$padj < 0.05] <- "ALS enriched"
volcano_data$Significance[volcano_data$log2FC < -0.58 & volcano_data$padj < 0.05] <- "Control enriched"

# Top miRNAs para etiquetar
top_mirnas <- volcano_data %>%
  filter(Significance != "NS") %>%
  arrange(padj) %>%
  head(10)

figure_2_3 <- ggplot(volcano_data, aes(x = log2FC, y = neg_log10_padj, color = Significance)) +
  geom_point(alpha = 0.6, size = 2) +
  geom_hline(yintercept = -log10(0.05), linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = c(-0.58, 0.58), linetype = "dashed", color = "gray50") +
  scale_color_manual(values = c("ALS enriched" = COLOR_ALS, 
                                "Control enriched" = "steelblue",
                                "NS" = "gray70")) +
  labs(
    title = "Volcano Plot: Differentially Affected miRNAs",
    subtitle = "G>T VAF comparison (ALS vs Control)",
    x = "log2(Fold Change)",
    y = "-log10(FDR-adjusted p-value)"
  ) +
  theme_professional +
  theme(legend.position = "bottom")

# Añadir labels para top miRNAs (simplificado)
if (nrow(top_mirnas) > 0) {
  figure_2_3 <- figure_2_3 +
    geom_text(data = top_mirnas, aes(label = miRNA), 
              size = 3, hjust = -0.1, vjust = 0.5, color = "black", check_overlap = TRUE)
}

ggsave(file.path(output_dir, "FIGURA_2.3_VOLCANO_PLOT.png"), 
       plot = figure_2_3, width = 12, height = 10, dpi = 300)
cat("✅ Figura 2.3 guardada\n\n")

# ============================================================================
# GRUPO B: ANÁLISIS POSICIONAL
# ============================================================================

cat("📊 GRUPO B: ANÁLISIS POSICIONAL\n")
cat(paste(rep("-", 70), collapse = ""), "\n\n")

# ---- FIGURA 2.4: HEATMAP VAF POR POSICIÓN ----
cat("📊 Generando Figura 2.4: Heatmap VAF por posición...\n")

# Extraer posición
vaf_positional <- vaf_gt %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^\\d+"))) %>%
  filter(!is.na(position), position <= 22)

# VAF promedio por miRNA, posición y grupo
vaf_matrix_data <- vaf_positional %>%
  group_by(miRNA_name, position, Group) %>%
  summarise(Mean_VAF = mean(VAF, na.rm = TRUE), .groups = "drop")

# Seleccionar top 30 miRNAs con mayor diferencia entre grupos
top_mirnas_diff <- vaf_matrix_data %>%
  pivot_wider(names_from = Group, values_from = Mean_VAF, values_fill = 0) %>%
  mutate(Diff = abs(ALS - Control)) %>%
  group_by(miRNA_name) %>%
  summarise(Max_Diff = max(Diff, na.rm = TRUE), .groups = "drop") %>%
  arrange(desc(Max_Diff)) %>%
  head(30) %>%
  pull(miRNA_name)

# Crear matrices para cada grupo
create_heatmap_matrix <- function(group_name) {
  matrix_data <- vaf_matrix_data %>%
    filter(Group == group_name, miRNA_name %in% top_mirnas_diff) %>%
    select(miRNA_name, position, Mean_VAF) %>%
    pivot_wider(names_from = position, values_from = Mean_VAF, values_fill = 0) %>%
    column_to_rownames("miRNA_name")
  
  # Completar posiciones faltantes
  all_positions <- as.character(1:22)
  missing_positions <- setdiff(all_positions, colnames(matrix_data))
  for (pos in missing_positions) {
    matrix_data[[pos]] <- 0
  }
  
  matrix_data <- matrix_data[, as.character(1:22)]
  return(as.matrix(matrix_data))
}

# Crear heatmaps para ALS y Control
png(file.path(output_dir, "FIGURA_2.4_HEATMAP_POSITIONAL.png"), 
    width = 14, height = 10, units = "in", res = 300)

par(mfrow = c(1, 2))

# ALS
heatmap_als <- create_heatmap_matrix("ALS")
pheatmap(heatmap_als, 
         main = "ALS: G>T VAF by Position",
         color = colorRampPalette(c("white", COLOR_ALS))(100),
         cluster_cols = FALSE,
         fontsize = 10,
         silent = TRUE)

# Control
heatmap_ctrl <- create_heatmap_matrix("Control")
pheatmap(heatmap_ctrl,
         main = "Control: G>T VAF by Position",
         color = colorRampPalette(c("white", COLOR_CONTROL))(100),
         cluster_cols = FALSE,
         fontsize = 10,
         silent = TRUE)

dev.off()
cat("✅ Figura 2.4 guardada\n\n")

# ---- FIGURA 2.5: HEATMAP Z-SCORE ----
cat("📊 Generando Figura 2.5: Heatmap Z-score...\n")

# Calcular Z-scores por fila
heatmap_combined <- rbind(
  cbind(heatmap_als, Group = "ALS"),
  cbind(heatmap_ctrl, Group = "Control")
)

# Z-score por fila
heatmap_zscore <- t(scale(t(heatmap_combined[, -ncol(heatmap_combined)])))

png(file.path(output_dir, "FIGURA_2.5_HEATMAP_ZSCORE.png"), 
    width = 12, height = 10, units = "in", res = 300)

pheatmap(heatmap_zscore,
         main = "G>T VAF Z-score by Position",
         color = colorRampPalette(c("blue", "white", "red"))(100),
         breaks = seq(-3, 3, length.out = 101),
         cluster_cols = FALSE,
         fontsize = 10)

dev.off()
cat("✅ Figura 2.5 guardada\n\n")

# ---- FIGURA 2.6: PERFILES POSICIONALES CON SIGNIFICANCIA ----
cat("📊 Generando Figura 2.6: Perfiles posicionales...\n")

# VAF promedio por posición y grupo
positional_profile <- vaf_positional %>%
  group_by(position, Group) %>%
  summarise(
    Mean_VAF = mean(VAF, na.rm = TRUE),
    SE_VAF = sd(VAF, na.rm = TRUE) / sqrt(n()),
    .groups = "drop"
  )

# Test de significancia por posición
significance_by_position <- data.frame()
for (pos in 1:22) {
  pos_data <- vaf_positional %>% filter(position == pos)
  
  als_vals <- pos_data %>% filter(Group == "ALS") %>% pull(VAF)
  ctrl_vals <- pos_data %>% filter(Group == "Control") %>% pull(VAF)
  
  if (length(als_vals) > 5 && length(ctrl_vals) > 5) {
    test_result <- wilcox.test(als_vals, ctrl_vals)
    significance_by_position <- rbind(significance_by_position, data.frame(
      position = pos,
      pvalue = test_result$p.value
    ))
  }
}

# Ajustar p-values
significance_by_position$padj <- p.adjust(significance_by_position$pvalue, method = "fdr")

# Panel A: Line plot con CI
panel_2_6_a <- ggplot(positional_profile, aes(x = position, y = Mean_VAF, color = Group, fill = Group)) +
  geom_ribbon(aes(ymin = Mean_VAF - SE_VAF, ymax = Mean_VAF + SE_VAF), alpha = 0.2, color = NA) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2) +
  annotate("rect", xmin = 2, xmax = 8, ymin = -Inf, ymax = Inf, fill = COLOR_SEED, alpha = 0.2) +
  scale_color_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  labs(title = "A. G>T VAF by Position", x = "Position", y = "Mean VAF") +
  theme_professional +
  theme(legend.position = "bottom")

# Panel B: log2(FC)
fc_by_position <- positional_profile %>%
  select(position, Group, Mean_VAF) %>%
  pivot_wider(names_from = Group, values_from = Mean_VAF) %>%
  mutate(
    log2FC = log2((ALS + 0.001) / (Control + 0.001))
  )

panel_2_6_b <- ggplot(fc_by_position, aes(x = position, y = log2FC)) +
  geom_col(aes(fill = log2FC > 0), width = 0.7) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  annotate("rect", xmin = 2, xmax = 8, ymin = -Inf, ymax = Inf, fill = COLOR_SEED, alpha = 0.2) +
  scale_fill_manual(values = c("TRUE" = COLOR_ALS, "FALSE" = "steelblue")) +
  labs(title = "B. log2(FC) by Position", x = "Position", y = "log2(ALS / Control)") +
  theme_professional +
  theme(legend.position = "none")

# Panel C: -log10(p-value)
panel_2_6_c <- ggplot(significance_by_position, aes(x = position, y = -log10(padj))) +
  geom_col(fill = "gray40", width = 0.7) +
  geom_hline(yintercept = -log10(0.05), linetype = "dashed", color = "red") +
  annotate("rect", xmin = 2, xmax = 8, ymin = -Inf, ymax = Inf, fill = COLOR_SEED, alpha = 0.2) +
  labs(title = "C. Significance by Position", x = "Position", y = "-log10(FDR p-value)") +
  theme_professional

# Combinar
figure_2_6 <- panel_2_6_a / panel_2_6_b / panel_2_6_c
ggsave(file.path(output_dir, "FIGURA_2.6_POSITIONAL_PROFILES.png"), 
       plot = figure_2_6, width = 12, height = 14, dpi = 300)
cat("✅ Figura 2.6 guardada\n\n")

# ============================================================================
# Continuar con Grupos C y D...
# ============================================================================

cat("\n✅ PRIMERAS 6 FIGURAS GENERADAS\n")
cat("📁 Guardadas en:", output_dir, "\n")
cat("\n🔄 Generando figuras restantes (Grupos C y D)...\n\n")

# El script continuará generando las figuras 2.7 a 2.12 en la siguiente parte...
cat("⏸️  Script pausado. Continuar con Grupos C y D? [Enter para continuar]\n")

