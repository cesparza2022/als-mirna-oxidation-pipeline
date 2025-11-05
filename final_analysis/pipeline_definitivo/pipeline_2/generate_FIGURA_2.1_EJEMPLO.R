# FIGURA 2.1 EJEMPLO - COMPARACIÓN DE CARGA VAF GLOBAL (ALS vs Control)

library(ggplot2)
library(dplyr)
library(tidyr)
library(stringr)
library(patchwork)

# Colores
COLOR_ALS <- "#D62728"
COLOR_CONTROL <- "#666666"

# Tema profesional
theme_professional <- theme_minimal() +
  theme(
    text = element_text(size = 14, family = "Helvetica"),
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray40"),
    axis.title = element_text(size = 14, face = "bold"),
    axis.text = element_text(size = 12),
    legend.position = "none",
    panel.grid.major = element_line(color = "gray90", linewidth = 0.5),
    panel.grid.minor = element_blank(),
    panel.border = element_rect(color = "gray30", fill = NA, linewidth = 1)
  )

cat("🎯 GENERANDO FIGURA 2.1 - COMPARACIÓN VAF GLOBAL\n")
cat("================================================\n\n")

# Cargar datos
cat("📊 Cargando datos...\n")
data <- read.csv("../../../final_analysis/processed_data/final_processed_data.csv")
metadata <- read.csv("metadata.csv")

# Extraer columnas de muestras
sample_cols <- metadata$Sample_ID

# Calcular VAF total por muestra
cat("📊 Calculando VAF total por muestra...\n")
vaf_total <- data %>%
  select(all_of(c("miRNA_name", "pos.mut", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  group_by(Sample_ID) %>%
  summarise(
    Total_VAF = sum(VAF, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  left_join(metadata, by = "Sample_ID")

# Calcular VAF G>T por muestra
cat("📊 Calculando VAF G>T por muestra...\n")
vaf_gt <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  select(all_of(c("miRNA_name", "pos.mut", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  group_by(Sample_ID) %>%
  summarise(
    GT_VAF = sum(VAF, na.rm = TRUE),
    .groups = "drop"
  )

# Combinar datos
combined_data <- vaf_total %>%
  left_join(vaf_gt %>% select(Sample_ID, GT_VAF), by = "Sample_ID") %>%
  mutate(
    GT_Ratio = GT_VAF / Total_VAF,
    GT_Ratio = replace_na(GT_Ratio, 0)
  )

# Estadísticas
cat("\n📊 ESTADÍSTICAS DESCRIPTIVAS:\n")
stats_summary <- combined_data %>%
  group_by(Group) %>%
  summarise(
    N = n(),
    Mean_Total_VAF = mean(Total_VAF, na.rm = TRUE),
    SD_Total_VAF = sd(Total_VAF, na.rm = TRUE),
    Median_Total_VAF = median(Total_VAF, na.rm = TRUE),
    Mean_GT_VAF = mean(GT_VAF, na.rm = TRUE),
    SD_GT_VAF = sd(GT_VAF, na.rm = TRUE),
    Median_GT_VAF = median(GT_VAF, na.rm = TRUE),
    Mean_GT_Ratio = mean(GT_Ratio, na.rm = TRUE),
    SD_GT_Ratio = sd(GT_Ratio, na.rm = TRUE),
    .groups = "drop"
  )
print(stats_summary)

# Test estadístico: Wilcoxon
cat("\n📊 TESTS ESTADÍSTICOS (Wilcoxon):\n")
test_total <- wilcox.test(Total_VAF ~ Group, data = combined_data)
test_gt <- wilcox.test(GT_VAF ~ Group, data = combined_data)
test_ratio <- wilcox.test(GT_Ratio ~ Group, data = combined_data)

cat("  Total VAF: p-value =", format.pval(test_total$p.value, digits = 3), "\n")
cat("  G>T VAF: p-value =", format.pval(test_gt$p.value, digits = 3), "\n")
cat("  G>T Ratio: p-value =", format.pval(test_ratio$p.value, digits = 3), "\n\n")

# PANEL A: Total VAF por muestra
cat("📊 Creando Panel A: Total VAF...\n")
panel_a <- ggplot(combined_data, aes(x = Group, y = Total_VAF, fill = Group)) +
  geom_boxplot(alpha = 0.7, outlier.shape = NA, width = 0.6) +
  geom_jitter(width = 0.2, alpha = 0.3, size = 1.5) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  scale_y_log10(labels = scales::comma) +
  labs(
    title = "A. Total VAF per Sample",
    subtitle = paste0("Wilcoxon p = ", format.pval(test_total$p.value, digits = 3)),
    x = NULL,
    y = "Total VAF (log scale)"
  ) +
  theme_professional +
  annotate("text", x = 1.5, y = max(combined_data$Total_VAF) * 0.8,
           label = ifelse(test_total$p.value < 0.05, "***", "ns"),
           size = 8, color = "red")

# PANEL B: G>T VAF por muestra
cat("📊 Creando Panel B: G>T VAF...\n")
panel_b <- ggplot(combined_data, aes(x = Group, y = GT_VAF, fill = Group)) +
  geom_boxplot(alpha = 0.7, outlier.shape = NA, width = 0.6) +
  geom_jitter(width = 0.2, alpha = 0.3, size = 1.5) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  scale_y_log10(labels = scales::comma) +
  labs(
    title = "B. G>T VAF per Sample",
    subtitle = paste0("Wilcoxon p = ", format.pval(test_gt$p.value, digits = 3)),
    x = NULL,
    y = "G>T VAF (log scale)"
  ) +
  theme_professional +
  annotate("text", x = 1.5, y = max(combined_data$GT_VAF) * 0.8,
           label = ifelse(test_gt$p.value < 0.05, "***", "ns"),
           size = 8, color = "red")

# PANEL C: G>T Ratio
cat("📊 Creando Panel C: G>T Ratio...\n")
panel_c <- ggplot(combined_data, aes(x = Group, y = GT_Ratio, fill = Group)) +
  geom_boxplot(alpha = 0.7, outlier.shape = NA, width = 0.6) +
  geom_jitter(width = 0.2, alpha = 0.3, size = 1.5) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  labs(
    title = "C. G>T Fraction (G>T / Total)",
    subtitle = paste0("Wilcoxon p = ", format.pval(test_ratio$p.value, digits = 3)),
    x = NULL,
    y = "G>T / Total VAF"
  ) +
  theme_professional +
  annotate("text", x = 1.5, y = max(combined_data$GT_Ratio) * 0.9,
           label = ifelse(test_ratio$p.value < 0.05, "***", "ns"),
           size = 8, color = "red")

# Combinar paneles
cat("📊 Combinando paneles...\n")
combined_figure <- (panel_a | panel_b | panel_c)

# Guardar
output_dir <- "figures_paso2"
if (!dir.exists(output_dir)) {
  dir.create(output_dir)
}

output_path <- file.path(output_dir, "FIGURA_2.1_VAF_GLOBAL_COMPARISON.png")
ggsave(output_path, plot = combined_figure, width = 15, height = 5, dpi = 300)

cat("\n✅ FIGURA 2.1 GENERADA EXITOSAMENTE\n")
cat("📁 Archivo:", output_path, "\n")
cat("📏 Dimensiones: 15x5 pulgadas\n")
cat("🎨 Paneles: A (Total VAF) | B (G>T VAF) | C (G>T Ratio)\n")
cat("📊 Muestras: ALS n =", sum(combined_data$Group == "ALS"),
    "| Control n =", sum(combined_data$Group == "Control"), "\n")

