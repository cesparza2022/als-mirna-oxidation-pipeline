# ============================================================================
# FIGURAS DE DIAGNÓSTICO - FILTRO VAF > 0.5
# Documenta el control de calidad y distribución de VAF
# ============================================================================

library(ggplot2)
library(dplyr)
library(tidyr)
library(stringr)
library(patchwork)
library(scales)

# Configuración
COLOR_REMOVED <- "#e74c3c"
COLOR_KEPT <- "#27ae60"
COLOR_ZERO <- "#95a5a6"

theme_diagnostic <- theme_minimal() +
  theme(
    text = element_text(size = 13, family = "Helvetica"),
    plot.title = element_text(size = 15, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5, color = "gray40"),
    axis.title = element_text(size = 13, face = "bold"),
    axis.text = element_text(size = 11),
    panel.grid.major = element_line(color = "gray90", linewidth = 0.5),
    panel.grid.minor = element_blank(),
    panel.border = element_rect(color = "gray30", fill = NA, linewidth = 1),
    legend.position = "bottom"
  )

cat("🎯 GENERANDO FIGURAS DE DIAGNÓSTICO - FILTRO VAF\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

# Cargar datos originales
cat("📊 Cargando datos originales...\n")
data <- read.csv("../../../final_analysis/processed_data/final_processed_data.csv")
metadata <- read.csv("metadata.csv")
sample_cols <- metadata$Sample_ID

# ============================================================================
# PANEL 1: DISTRIBUCIÓN GLOBAL DE VAF
# ============================================================================

cat("📊 Panel 1: Distribución global de VAF...\n")

# Extraer todos los valores VAF
vaf_values <- data %>%
  select(all_of(sample_cols)) %>%
  as.matrix() %>%
  as.vector()

vaf_df <- data.frame(VAF = vaf_values) %>%
  filter(!is.na(VAF)) %>%
  mutate(
    Category = case_when(
      VAF == 0 ~ "Zero (0)",
      VAF > 0 & VAF <= 0.1 ~ "Low (0-0.1)",
      VAF > 0.1 & VAF <= 0.3 ~ "Medium (0.1-0.3)",
      VAF > 0.3 & VAF <= 0.5 ~ "High (0.3-0.5)",
      VAF > 0.5 ~ "Very High (>0.5)"
    ),
    Would_Remove = VAF > 0.5
  )

# Resumen por categoría
category_summary <- vaf_df %>%
  group_by(Category) %>%
  summarise(
    Count = n(),
    Percentage = n() / nrow(vaf_df) * 100
  ) %>%
  arrange(desc(Count))

cat("📋 Categorías de VAF:\n")
print(category_summary)
cat("\n")

# Panel A: Histograma de distribución
panel_1a <- ggplot(vaf_df %>% filter(VAF > 0, VAF <= 0.6), aes(x = VAF)) +
  geom_histogram(aes(fill = Would_Remove), bins = 100, color = "white", linewidth = 0.3) +
  geom_vline(xintercept = 0.5, linetype = "dashed", color = "red", linewidth = 1.2) +
  scale_fill_manual(values = c("FALSE" = COLOR_KEPT, "TRUE" = COLOR_REMOVED),
                    labels = c("Kept (≤0.5)", "Removed (>0.5)")) +
  annotate("text", x = 0.52, y = Inf, label = "Threshold = 0.5", 
           color = "red", hjust = 0, vjust = 1.5, fontface = "bold") +
  labs(
    title = "A. Distribution of VAF Values",
    subtitle = paste0("Total non-zero values: ", format(sum(vaf_df$VAF > 0), big.mark = ",")),
    x = "Variant Allele Frequency (VAF)",
    y = "Count",
    fill = "Status"
  ) +
  theme_diagnostic

# Panel B: Barplot de categorías
panel_1b <- ggplot(category_summary, aes(x = reorder(Category, -Count), y = Count, fill = Category)) +
  geom_col(width = 0.7) +
  geom_text(aes(label = paste0(format(Count, big.mark = ","), "\n(",
                               round(Percentage, 2), "%)")),
            vjust = -0.5, size = 3.5) +
  scale_fill_manual(values = c(
    "Zero (0)" = COLOR_ZERO,
    "Low (0-0.1)" = "#3498db",
    "Medium (0.1-0.3)" = "#f39c12",
    "High (0.3-0.5)" = "#e67e22",
    "Very High (>0.5)" = COLOR_REMOVED
  )) +
  scale_y_continuous(labels = comma) +
  labs(
    title = "B. VAF Categories",
    subtitle = "Distribution of values across quality categories",
    x = "VAF Category",
    y = "Count"
  ) +
  theme_diagnostic +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "none")

figure_1 <- panel_1a / panel_1b
ggsave("figures_diagnostico/DIAGNOSTICO_1_DISTRIBUCION_VAF.png", 
       plot = figure_1, width = 12, height = 11, dpi = 300)
cat("✅ Figura 1 guardada\n\n")

# ============================================================================
# PANEL 2: IMPACTO POR miRNA Y SNV
# ============================================================================

cat("📊 Panel 2: Impacto del filtro por miRNA y SNV...\n")

# Análisis por SNV
vaf_by_snv <- data %>%
  select(all_of(c("miRNA_name", "pos.mut", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  filter(!is.na(VAF), VAF > 0) %>%
  mutate(
    Above_Threshold = VAF > 0.5,
    SNV_ID = paste(miRNA_name, pos.mut, sep = "_")
  )

# Resumen por SNV
snv_impact <- vaf_by_snv %>%
  group_by(SNV_ID, miRNA_name, pos.mut) %>%
  summarise(
    Total_Observations = n(),
    N_Above_50 = sum(Above_Threshold),
    Percent_Above_50 = N_Above_50 / Total_Observations * 100,
    Max_VAF = max(VAF, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(N_Above_50), desc(Percent_Above_50))

cat("🔝 SNVs con más valores > 0.5:\n")
print(head(snv_impact %>% filter(N_Above_50 > 0) %>% select(-SNV_ID), 10))
cat("\n")

# Si NO hay valores > 0.5, crear datos sintéticos para demostración
if (sum(snv_impact$N_Above_50) == 0) {
  cat("⚠️ No hay valores > 0.5. Creando visualización de ejemplo...\n\n")
  
  # Resumen general
  snv_summary <- data.frame(
    Category = c("SNVs con observaciones", "SNVs sin valores > 0.5"),
    Count = c(nrow(snv_impact), nrow(snv_impact))
  )
  
  panel_2a <- ggplot(snv_summary, aes(x = Category, y = Count, fill = Category)) +
    geom_col(width = 0.6) +
    geom_text(aes(label = format(Count, big.mark = ",")), vjust = -0.5, size = 5) +
    scale_fill_manual(values = c(COLOR_KEPT, COLOR_KEPT)) +
    labs(
      title = "A. SNV Quality Check",
      subtitle = "No SNVs would be affected by VAF > 0.5 filter",
      x = NULL,
      y = "Number of SNVs"
    ) +
    theme_diagnostic +
    theme(legend.position = "none") +
    annotate("text", x = 1.5, y = max(snv_summary$Count) * 0.5,
             label = "✓ All SNVs Pass Quality Filter",
             size = 6, color = COLOR_KEPT, fontface = "bold")
  
} else {
  # Panel A: Top SNVs afectados
  top_affected_snvs <- head(snv_impact %>% filter(N_Above_50 > 0), 20)
  
  panel_2a <- ggplot(top_affected_snvs, aes(x = reorder(pos.mut, N_Above_50), y = N_Above_50)) +
    geom_col(fill = COLOR_REMOVED, width = 0.7) +
    geom_text(aes(label = N_Above_50), hjust = -0.2, size = 3) +
    coord_flip() +
    labs(
      title = "A. SNVs Most Affected by Filter",
      subtitle = "Top 20 SNVs with most observations > 0.5",
      x = "SNV (position:mutation)",
      y = "Number of observations > 0.5"
    ) +
    theme_diagnostic
}

# Panel B: Distribución de Max VAF por SNV
panel_2b <- ggplot(snv_impact, aes(x = Max_VAF)) +
  geom_histogram(aes(fill = Max_VAF > 0.5), bins = 50, color = "white", linewidth = 0.3) +
  geom_vline(xintercept = 0.5, linetype = "dashed", color = "red", linewidth = 1.2) +
  scale_fill_manual(values = c("FALSE" = COLOR_KEPT, "TRUE" = COLOR_REMOVED),
                    labels = c("Max VAF ≤0.5", "Max VAF >0.5")) +
  labs(
    title = "B. Maximum VAF per SNV",
    subtitle = paste0("Distribution across ", format(nrow(snv_impact), big.mark = ","), " unique SNVs"),
    x = "Maximum VAF observed",
    y = "Number of SNVs",
    fill = "Quality"
  ) +
  theme_diagnostic

figure_2 <- panel_2a / panel_2b
ggsave("figures_diagnostico/DIAGNOSTICO_2_IMPACTO_POR_SNV.png", 
       plot = figure_2, width = 12, height = 11, dpi = 300)
cat("✅ Figura 2 guardada\n\n")

# ============================================================================
# PANEL 3: IMPACTO POR miRNA
# ============================================================================

cat("📊 Panel 3: Impacto del filtro por miRNA...\n")

# Análisis por miRNA
mirna_impact <- vaf_by_snv %>%
  group_by(miRNA_name) %>%
  summarise(
    Total_Observations = n(),
    N_Above_50 = sum(Above_Threshold),
    Percent_Above_50 = N_Above_50 / Total_Observations * 100,
    N_SNVs = n_distinct(pos.mut),
    Max_VAF = max(VAF, na.rm = TRUE),
    Mean_VAF = mean(VAF, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(N_Above_50), desc(Percent_Above_50))

cat("🔝 miRNAs con más valores > 0.5:\n")
print(head(mirna_impact %>% filter(N_Above_50 > 0), 10))
cat("\n")

# Panel A: Top miRNAs afectados (o mensaje de calidad)
if (sum(mirna_impact$N_Above_50) == 0) {
  mirna_summary <- data.frame(
    Category = c("miRNAs analyzed", "miRNAs with values > 0.5"),
    Count = c(nrow(mirna_impact), 0)
  )
  
  panel_3a <- ggplot(mirna_summary, aes(x = Category, y = Count, fill = Category)) +
    geom_col(width = 0.6) +
    geom_text(aes(label = format(Count, big.mark = ",")), vjust = -0.5, size = 5) +
    scale_fill_manual(values = c(COLOR_KEPT, COLOR_ZERO)) +
    labs(
      title = "A. miRNA Quality Check",
      subtitle = "No miRNAs have observations > 0.5",
      x = NULL,
      y = "Number of miRNAs"
    ) +
    theme_diagnostic +
    theme(legend.position = "none") +
    annotate("text", x = 1.5, y = max(mirna_summary$Count) * 0.5,
             label = "✓ All miRNAs Pass Quality Control",
             size = 6, color = COLOR_KEPT, fontface = "bold")
} else {
  top_affected_mirnas <- head(mirna_impact %>% filter(N_Above_50 > 0), 20)
  
  panel_3a <- ggplot(top_affected_mirnas, aes(x = reorder(miRNA_name, N_Above_50), y = N_Above_50)) +
    geom_col(fill = COLOR_REMOVED, width = 0.7) +
    geom_text(aes(label = N_Above_50), hjust = -0.2, size = 3) +
    coord_flip() +
    labs(
      title = "A. miRNAs Most Affected by Filter",
      subtitle = "Top 20 miRNAs with most observations > 0.5",
      x = "miRNA",
      y = "Number of observations > 0.5"
    ) +
    theme_diagnostic
}

# Panel B: Distribución de Mean VAF por miRNA
panel_3b <- ggplot(mirna_impact, aes(x = Mean_VAF)) +
  geom_histogram(aes(fill = Max_VAF > 0.5), bins = 50, color = "white", linewidth = 0.3) +
  geom_vline(xintercept = 0.5, linetype = "dashed", color = "red", linewidth = 1.2) +
  scale_fill_manual(values = c("FALSE" = COLOR_KEPT, "TRUE" = COLOR_REMOVED),
                    labels = c("Max ≤0.5", "Max >0.5")) +
  scale_x_continuous(limits = c(0, 0.6), breaks = seq(0, 0.6, 0.1)) +
  labs(
    title = "B. Mean VAF per miRNA",
    subtitle = paste0("Distribution across ", format(nrow(mirna_impact), big.mark = ","), " miRNAs"),
    x = "Mean VAF",
    y = "Number of miRNAs",
    fill = "Quality"
  ) +
  theme_diagnostic

# Panel C: Scatter plot - N observations vs Max VAF
panel_3c <- ggplot(mirna_impact, aes(x = Total_Observations, y = Max_VAF, color = Max_VAF > 0.5)) +
  geom_point(alpha = 0.5, size = 2) +
  geom_hline(yintercept = 0.5, linetype = "dashed", color = "red", linewidth = 1) +
  scale_color_manual(values = c("FALSE" = COLOR_KEPT, "TRUE" = COLOR_REMOVED),
                     labels = c("Pass filter", "Fail filter")) +
  scale_x_log10(labels = comma) +
  labs(
    title = "C. Observations vs Max VAF",
    subtitle = "Relationship between sample size and maximum VAF",
    x = "Total observations (log scale)",
    y = "Maximum VAF",
    color = "Filter"
  ) +
  theme_diagnostic

figure_3 <- panel_3a / (panel_3b | panel_3c)
ggsave("figures_diagnostico/DIAGNOSTICO_3_IMPACTO_POR_miRNA.png", 
       plot = figure_3, width = 14, height = 12, dpi = 300)
cat("✅ Figura 3 guardada\n\n")

# ============================================================================
# PANEL 4: IMPACTO POR MUESTRA
# ============================================================================

cat("📊 Panel 4: Impacto del filtro por muestra...\n")

# Análisis por muestra
sample_impact <- data %>%
  select(all_of(c("miRNA_name", "pos.mut", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  filter(!is.na(VAF)) %>%
  left_join(metadata, by = "Sample_ID") %>%
  group_by(Sample_ID, Group) %>%
  summarise(
    Total_Observations = n(),
    N_Above_50 = sum(VAF > 0.5),
    Percent_Above_50 = N_Above_50 / Total_Observations * 100,
    N_Zero = sum(VAF == 0),
    N_Positive = sum(VAF > 0),
    Mean_VAF = mean(VAF[VAF > 0], na.rm = TRUE),
    Max_VAF = max(VAF, na.rm = TRUE),
    .groups = "drop"
  )

cat("📊 Resumen por grupo:\n")
sample_group_summary <- sample_impact %>%
  group_by(Group) %>%
  summarise(
    N_Samples = n(),
    Mean_Observations = mean(Total_Observations),
    Mean_Above_50 = mean(N_Above_50),
    Mean_Percent_Above_50 = mean(Percent_Above_50),
    .groups = "drop"
  )
print(sample_group_summary)
cat("\n")

# Panel A: Boxplot de % valores > 0.5 por grupo
panel_4a <- ggplot(sample_impact, aes(x = Group, y = Percent_Above_50, fill = Group)) +
  geom_boxplot(alpha = 0.7, outlier.shape = NA) +
  geom_jitter(width = 0.2, alpha = 0.3, size = 1) +
  scale_fill_manual(values = c("ALS" = "#D62728", "Control" = "#666666")) +
  labs(
    title = "A. Percent of Values > 0.5 per Sample",
    subtitle = "Distribution by group (ALS vs Control)",
    x = NULL,
    y = "% of observations > 0.5"
  ) +
  theme_diagnostic +
  theme(legend.position = "none")

# Panel B: Mean VAF por muestra y grupo
panel_4b <- ggplot(sample_impact, aes(x = Group, y = Mean_VAF, fill = Group)) +
  geom_violin(alpha = 0.7, trim = FALSE) +
  geom_boxplot(width = 0.1, alpha = 0.8, outlier.shape = NA) +
  scale_fill_manual(values = c("ALS" = "#D62728", "Control" = "#666666")) +
  labs(
    title = "B. Mean VAF per Sample",
    subtitle = "Average VAF of non-zero values",
    x = NULL,
    y = "Mean VAF (non-zero values)"
  ) +
  theme_diagnostic +
  theme(legend.position = "none")

# Panel C: Max VAF por muestra
panel_4c <- ggplot(sample_impact, aes(x = Group, y = Max_VAF, fill = Group)) +
  geom_boxplot(alpha = 0.7) +
  geom_jitter(width = 0.2, alpha = 0.3, size = 1.5) +
  geom_hline(yintercept = 0.5, linetype = "dashed", color = "red", linewidth = 1) +
  scale_fill_manual(values = c("ALS" = "#D62728", "Control" = "#666666")) +
  labs(
    title = "C. Maximum VAF per Sample",
    subtitle = "Highest VAF value observed in each sample",
    x = NULL,
    y = "Maximum VAF"
  ) +
  theme_diagnostic +
  theme(legend.position = "none") +
  annotate("text", x = 1.5, y = 0.52, label = "Threshold = 0.5",
           color = "red", fontface = "bold")

figure_4 <- panel_4a / (panel_4b | panel_4c)
ggsave("figures_diagnostico/DIAGNOSTICO_4_IMPACTO_POR_MUESTRA.png", 
       plot = figure_4, width = 14, height = 12, dpi = 300)
cat("✅ Figura 4 guardada\n\n")

# ============================================================================
# PANEL 5: TABLA RESUMEN GENERAL
# ============================================================================

cat("📊 Panel 5: Tabla resumen general...\n")

# Crear tabla visual con estadísticas clave
total_values <- length(vaf_values)
values_above_50 <- sum(vaf_values > 0.5, na.rm = TRUE)
values_zero <- sum(vaf_values == 0, na.rm = TRUE)
values_positive <- sum(vaf_values > 0 & vaf_values <= 0.5, na.rm = TRUE)
values_na <- sum(is.na(vaf_values))

summary_stats <- data.frame(
  Metric = c(
    "Total VAF values",
    "Values = 0",
    "Values > 0 and ≤ 0.5 (KEPT)",
    "Values > 0.5 (REMOVED)",
    "NA values",
    "Percent removed",
    "Percent kept (non-zero)",
    "",
    "Unique miRNAs analyzed",
    "Unique SNVs analyzed",
    "Total samples",
    "ALS samples",
    "Control samples"
  ),
  Value = c(
    format(total_values, big.mark = ","),
    format(values_zero, big.mark = ","),
    format(values_positive, big.mark = ","),
    format(values_above_50, big.mark = ","),
    format(values_na, big.mark = ","),
    paste0(round(values_above_50/total_values*100, 4), "%"),
    paste0(round(values_positive/total_values*100, 2), "%"),
    "",
    format(length(unique(data$miRNA_name)), big.mark = ","),
    format(nrow(data), big.mark = ","),
    "415",
    "313",
    "102"
  )
)

# Crear visualización de tabla
y_positions <- seq(0.95, 0.05, length.out = nrow(summary_stats))

panel_5 <- ggplot() +
  annotate("rect", xmin = 0.05, xmax = 0.95, ymin = 0.92, ymax = 1, 
           fill = "#3498db", alpha = 0.9) +
  annotate("text", x = 0.5, y = 0.96, 
           label = "QUALITY CONTROL SUMMARY - VAF FILTER",
           size = 6, fontface = "bold", color = "white") +
  xlim(0, 1) + ylim(0, 1) +
  theme_void()

for (i in 1:nrow(summary_stats)) {
  if (summary_stats$Metric[i] == "") next
  
  color_text <- if (i <= 7) "black" else "gray30"
  font_face <- if (i <= 7) "bold" else "plain"
  
  panel_5 <- panel_5 +
    annotate("text", x = 0.1, y = y_positions[i], 
             label = summary_stats$Metric[i],
             hjust = 0, size = 4, fontface = font_face, color = color_text) +
    annotate("text", x = 0.9, y = y_positions[i],
             label = summary_stats$Value[i],
             hjust = 1, size = 4, fontface = font_face, color = color_text)
  
  # Línea divisoria
  if (i == 7) {
    panel_5 <- panel_5 +
      annotate("segment", x = 0.1, xend = 0.9, y = y_positions[i] - 0.02, yend = y_positions[i] - 0.02,
               color = "gray50", linewidth = 1)
  }
}

ggsave("figures_diagnostico/DIAGNOSTICO_5_TABLA_RESUMEN.png", 
       plot = panel_5, width = 12, height = 10, dpi = 300)
cat("✅ Figura 5 guardada\n\n")

# ============================================================================
# RESUMEN
# ============================================================================

cat("\n", paste(rep("=", 70), collapse = ""), "\n")
cat("✅ FIGURAS DE DIAGNÓSTICO GENERADAS\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

cat("📊 RESUMEN DEL FILTRO VAF > 0.5:\n")
cat("   ✓ Valores > 0.5 encontrados:", format(values_above_50, big.mark = ","), "\n")
cat("   ✓ Porcentaje del total:", round(values_above_50/total_values*100, 4), "%\n")
cat("   ✓ Valores conservados (>0, ≤0.5):", format(values_positive, big.mark = ","), "\n")
cat("   ✓ Conclusión: ", ifelse(values_above_50 == 0, 
                                "Dataset de ALTA CALIDAD - Sin valores sospechosos",
                                "Filtro necesario aplicado"), "\n\n")

cat("📁 FIGURAS GENERADAS:\n")
cat("   ✓ DIAGNOSTICO_1_DISTRIBUCION_VAF.png\n")
cat("   ✓ DIAGNOSTICO_2_IMPACTO_POR_SNV.png\n")
cat("   ✓ DIAGNOSTICO_3_IMPACTO_POR_miRNA.png\n")
cat("   ✓ DIAGNOSTICO_5_TABLA_RESUMEN.png\n\n")

cat("📂 Directorio: figures_diagnostico/\n")
cat("🎉 DIAGNÓSTICO COMPLETADO\n")

