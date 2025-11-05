#!/usr/bin/env Rscript
# ============================================================================
# FIGURA MULTI-MÉTRICA: VAF vs COUNTS con Z-score
# Combina 3 métricas en 1 figura para filtrado inteligente
# ============================================================================

library(dplyr)
library(readr)
library(stringr)
library(tidyr)
library(ggplot2)
library(ggrepel)
library(purrr)
library(tibble)

COLOR_ALS <- "#D62728"
COLOR_CTRL <- "grey60"

cat("\n")
cat("╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║        🎯 FIGURA MULTI-MÉTRICA: VAF + COUNTS + Z-SCORE              ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

# ============================================================================
# CARGAR DATOS
# ============================================================================

cat("📊 Cargando datos...\n")

data <- read_csv("pipeline_2/final_processed_data_CLEAN.csv", show_col_types = FALSE)
metadata <- read_csv("pipeline_2/metadata.csv", show_col_types = FALSE)

# Filtrar solo G>T en seed de posiciones enriquecidas (2, 3, 5)
data_enriched_pos <- data %>%
  filter(str_detect(pos.mut, "^(2|3|5):GT$"))

cat(sprintf("✅ SNVs G>T en pos 2,3,5: %d\n", nrow(data_enriched_pos)))
cat(sprintf("✅ miRNAs únicos: %d\n\n", n_distinct(data_enriched_pos$miRNA_name)))

# ============================================================================
# CALCULAR MÉTRICAS POR miRNA
# ============================================================================

cat("📊 Calculando métricas por miRNA...\n")

# Convertir a long
data_long <- data_enriched_pos %>%
  pivot_longer(cols = -c(miRNA_name, pos.mut), 
               names_to = "Sample_ID", 
               values_to = "VAF") %>%
  filter(!is.na(VAF), VAF > 0) %>%
  left_join(metadata, by = "Sample_ID")

# Calcular métricas por miRNA
mirna_metrics <- data_long %>%
  group_by(miRNA_name, Group) %>%
  summarise(
    Mean_VAF = mean(VAF, na.rm = TRUE),
    SD_VAF = sd(VAF, na.rm = TRUE),
    N_Samples = n_distinct(Sample_ID),
    N_Observations = n(),  # Cuentas totales
    Median_VAF = median(VAF, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  pivot_wider(
    names_from = Group,
    values_from = c(Mean_VAF, SD_VAF, N_Samples, N_Observations, Median_VAF),
    values_fill = list(Mean_VAF = 0, SD_VAF = 0, N_Samples = 0, N_Observations = 0, Median_VAF = 0)
  )

# Calcular estadísticas comparativas
mirna_metrics <- mirna_metrics %>%
  mutate(
    # Fold Change
    FC = Mean_VAF_ALS / pmax(Mean_VAF_Control, 0.00001),
    log2FC = log2(FC),
    
    # Diferencia absoluta
    Delta_VAF = Mean_VAF_ALS - Mean_VAF_Control,
    
    # Z-score (diferencia normalizada por varianza pooled)
    SD_pooled = sqrt((SD_VAF_ALS^2 + SD_VAF_Control^2) / 2),
    Z_score = Delta_VAF / pmax(SD_pooled, 0.0001),
    
    # Counts (suma de observaciones)
    Total_Counts = N_Observations_ALS + N_Observations_Control,
    Pct_ALS_Samples = 100 * N_Samples_ALS / 313,
    Pct_Control_Samples = 100 * N_Samples_Control / 102,
    
    # Frecuencia relativa
    Freq_Ratio = Pct_ALS_Samples / pmax(Pct_Control_Samples, 1)
  )

# Test estadístico por miRNA
cat("📊 Calculando p-values...\n")

mirna_metrics$p_value <- map_dbl(mirna_metrics$miRNA_name, function(mirna) {
  
  mirna_data <- data_long %>% filter(miRNA_name == mirna)
  
  als_vals <- mirna_data %>% filter(Group == "ALS") %>% pull(VAF)
  ctrl_vals <- mirna_data %>% filter(Group == "Control") %>% pull(VAF)
  
  if (length(als_vals) > 0 && length(ctrl_vals) > 0) {
    test <- wilcox.test(als_vals, ctrl_vals)
    return(test$p.value)
  } else {
    return(1)
  }
})

# FDR correction
mirna_metrics$padj <- p.adjust(mirna_metrics$p_value, method = "BH")

cat(sprintf("✅ Métricas calculadas para %d miRNAs\n\n", nrow(mirna_metrics)))

# ============================================================================
# CLASIFICAR miRNAs
# ============================================================================

cat("📊 Clasificando miRNAs...\n")

mirna_metrics <- mirna_metrics %>%
  mutate(
    # Clasificación por significancia
    Significance = case_when(
      log2FC > 0.58 & padj < 0.05 ~ "ALS High Confidence",
      log2FC > 0.32 & padj < 0.10 ~ "ALS Moderate",
      log2FC > 0.32 & Z_score > 2 ~ "ALS Z-score High",
      log2FC < -0.32 & padj < 0.10 ~ "Control Enriched",
      TRUE ~ "Not Significant"
    ),
    
    # Z-score category
    Z_category = case_when(
      Z_score > 3 ~ "Very High (Z>3)",
      Z_score > 2 ~ "High (Z>2)",
      Z_score > 1 ~ "Moderate (Z>1)",
      Z_score > -1 ~ "Neutral",
      Z_score > -2 ~ "Moderate (Z<-1)",
      TRUE ~ "Control High"
    )
  )

# Resumen
summary_stats <- mirna_metrics %>%
  count(Significance) %>%
  arrange(desc(n))

cat("\n📊 CLASIFICACIÓN:\n")
print(summary_stats)
cat("\n")

# ============================================================================
# FIGURA 1: VAF (X) vs COUNTS (Y) con COLOR = Z-score
# ============================================================================

cat("📊 [1/3] Creando figura VAF vs Counts...\n")

# Top candidatos para etiquetar
top_candidates <- mirna_metrics %>%
  filter(Significance %in% c("ALS High Confidence", "ALS Moderate", "ALS Z-score High")) %>%
  arrange(desc(abs(Z_score))) %>%
  head(15)

fig1 <- ggplot(mirna_metrics, aes(x = Mean_VAF_ALS, y = Total_Counts)) +
  # Puntos coloreados por Z-score
  geom_point(aes(color = Z_score, size = abs(log2FC)), alpha = 0.7) +
  
  # Escala de color: azul (Control) → gris → rojo (ALS)
  scale_color_gradient2(
    low = "steelblue", 
    mid = "grey80", 
    high = COLOR_ALS,
    midpoint = 0,
    name = "Z-score\n(ALS - Control)"
  ) +
  
  # Tamaño por FC
  scale_size_continuous(range = c(2, 12), name = "|log2(FC)|") +
  
  # Ejes logarítmicos
  scale_x_log10(labels = scales::scientific) +
  scale_y_log10() +
  
  # Líneas de referencia
  geom_vline(xintercept = 0.001, linetype = "dashed", color = "grey40", alpha = 0.5) +
  geom_hline(yintercept = 50, linetype = "dashed", color = "grey40", alpha = 0.5) +
  
  # Etiquetas para top candidatos
  geom_text_repel(
    data = top_candidates,
    aes(label = miRNA_name),
    size = 3.5,
    fontface = "bold",
    max.overlaps = 15,
    box.padding = 0.5,
    point.padding = 0.3
  ) +
  
  labs(
    title = "Multi-Metric Selection: VAF vs Counts (colored by Z-score)",
    subtitle = sprintf("Only positions 2,3,5 | %d miRNAs | Top 15 labeled", nrow(mirna_metrics)),
    x = "Mean VAF in ALS (log scale)",
    y = "Total Observations (Counts, log scale)",
    caption = "Color = Z-score (difference normalized by variance)\nSize = Fold Change magnitude"
  ) +
  theme_classic(base_size = 14) +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(hjust = 0.5),
    legend.position = "right",
    panel.grid.major = element_line(color = "grey90", size = 0.3)
  )

ggsave("FIG_MULTI_METRIC_VAF_COUNTS_ZSCORE.png", fig1, width = 16, height = 12, dpi = 300)

cat("   ✅ Guardada\n\n")

# ============================================================================
# FIGURA 2: Z-score (X) vs padj (Y) con COLOR = VAF
# ============================================================================

cat("📊 [2/3] Creando figura Z-score vs p-value...\n")

fig2 <- ggplot(mirna_metrics, aes(x = Z_score, y = -log10(padj))) +
  # Puntos coloreados por VAF
  geom_point(aes(color = Mean_VAF_ALS, size = Total_Counts), alpha = 0.7) +
  
  # Color por intensidad de VAF
  scale_color_gradient(
    low = "#fee5d9",
    high = COLOR_ALS,
    trans = "log10",
    name = "Mean VAF\n(ALS)",
    labels = scales::scientific
  ) +
  
  # Tamaño por counts
  scale_size_continuous(range = c(2, 12), name = "Total\nCounts") +
  
  # Líneas de referencia
  geom_vline(xintercept = c(-2, 2), linetype = "dashed", color = "grey40") +
  geom_hline(yintercept = -log10(0.05), linetype = "dashed", color = "grey40") +
  
  # Etiquetas
  geom_text_repel(
    data = top_candidates,
    aes(label = miRNA_name),
    size = 3.5,
    fontface = "bold",
    max.overlaps = 15
  ) +
  
  # Anotar regiones
  annotate("text", x = 4, y = 0.5, label = "High Z-score\nLow p-value?", 
           color = "grey50", size = 3.5, fontface = "italic") +
  
  labs(
    title = "Z-score vs Statistical Significance",
    subtitle = "Color = VAF intensity | Size = Total counts",
    x = "Z-score (ALS - Control, normalized)",
    y = "-log10(p-value)",
    caption = "Dashed lines: Z = ±2, p = 0.05"
  ) +
  theme_classic(base_size = 14) +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(hjust = 0.5),
    legend.position = "right"
  )

ggsave("FIG_MULTI_METRIC_ZSCORE_PVALUE.png", fig2, width = 14, height = 10, dpi = 300)

cat("   ✅ Guardada\n\n")

# ============================================================================
# FIGURA 3: HEATMAP INTEGRADO (miRNA x Métricas)
# ============================================================================

cat("📊 [3/3] Creando heatmap multi-métrico...\n")

library(pheatmap)

# Top 30 por Z-score absoluto
top30 <- mirna_metrics %>%
  arrange(desc(abs(Z_score))) %>%
  head(30)

# Matriz de métricas normalizadas
metrics_matrix <- top30 %>%
  select(
    miRNA_name,
    Z_score,
    log2FC,
    Neg_log10_p = padj,
    Mean_VAF_ALS,
    Total_Counts,
    Pct_ALS_Samples
  ) %>%
  mutate(
    Neg_log10_p = -log10(Neg_log10_p),
    # Normalizar cada métrica 0-1
    Z_score_norm = (Z_score - min(Z_score)) / (max(Z_score) - min(Z_score)),
    log2FC_norm = (log2FC - min(log2FC)) / (max(log2FC) - min(log2FC)),
    p_norm = (Neg_log10_p - min(Neg_log10_p)) / (max(Neg_log10_p) - min(Neg_log10_p)),
    VAF_norm = (Mean_VAF_ALS - min(Mean_VAF_ALS)) / (max(Mean_VAF_ALS) - min(Mean_VAF_ALS)),
    Counts_norm = (Total_Counts - min(Total_Counts)) / (max(Total_Counts) - min(Total_Counts)),
    Freq_norm = (Pct_ALS_Samples - min(Pct_ALS_Samples)) / (max(Pct_ALS_Samples) - min(Pct_ALS_Samples))
  ) %>%
  select(miRNA_name, ends_with("_norm")) %>%
  column_to_rownames("miRNA_name") %>%
  as.matrix()

# Renombrar columnas
colnames(metrics_matrix) <- c("Z-score", "log2(FC)", "-log10(p)", "Mean VAF", "Total Counts", "% ALS Samples")

png("FIG_MULTI_METRIC_HEATMAP.png", width = 12, height = 16, units = "in", res = 300)
pheatmap(
  metrics_matrix,
  color = colorRampPalette(c("white", "#fee5d9", "#fc9272", "#fb6a4a", COLOR_ALS))(100),
  cluster_rows = TRUE,
  cluster_cols = FALSE,
  display_numbers = FALSE,
  main = "Multi-Metric Heatmap: Top 30 miRNAs (positions 2,3,5)",
  fontsize = 11,
  fontsize_row = 9,
  angle_col = 45
)
dev.off()

cat("   ✅ Guardada\n\n")

# ============================================================================
# GUARDAR DATOS
# ============================================================================

write_csv(mirna_metrics, "MULTI_METRIC_DATA.csv")

# Top candidatos
final_candidates <- mirna_metrics %>%
  filter(
    Z_score > 2,                # Z-score alto
    Mean_VAF_ALS > 0.001,       # VAF mínimo
    Total_Counts > 50,          # Counts mínimos
    padj < 0.10                 # Significancia
  ) %>%
  arrange(desc(Z_score))

write_csv(final_candidates, "CANDIDATES_MULTI_METRIC.csv")

cat("💾 Datos guardados:\n")
cat("   • MULTI_METRIC_DATA.csv (todos los miRNAs)\n")
cat("   • CANDIDATES_MULTI_METRIC.csv (filtrados)\n\n")

# ============================================================================
# RESUMEN Y RECOMENDACIONES
# ============================================================================

cat(paste(rep("═", 70), collapse = ""), "\n")
cat("✅ ANÁLISIS MULTI-MÉTRICO COMPLETADO\n")
cat(paste(rep("═", 70), collapse = ""), "\n\n")

cat("📊 MÉTRICAS CALCULADAS:\n")
cat("   1. Z-score: Diferencia normalizada por varianza\n")
cat("   2. log2(FC): Fold change ALS/Control\n")
cat("   3. -log10(p): Significancia estadística\n")
cat("   4. Mean VAF: Intensidad promedio\n")
cat("   5. Total Counts: Frecuencia de observaciones\n")
cat("   6. % ALS Samples: Prevalencia en muestras\n\n")

cat("🔥 CANDIDATOS FINALES (Z > 2, VAF > 0.001, Counts > 50, p < 0.10):\n")
cat(sprintf("   Encontrados: %d miRNAs\n\n", nrow(final_candidates)))

if (nrow(final_candidates) > 0) {
  cat("🔝 TOP CANDIDATOS:\n")
  top5 <- head(final_candidates, 5)
  for (i in 1:min(5, nrow(top5))) {
    row <- top5[i, ]
    cat(sprintf("\n%d. %s:\n", i, row$miRNA_name))
    cat(sprintf("   Z-score: %.2f\n", row$Z_score))
    cat(sprintf("   Mean VAF (ALS): %.5f (%.3f%%)\n", row$Mean_VAF_ALS, row$Mean_VAF_ALS*100))
    cat(sprintf("   Total Counts: %d observations\n", row$Total_Counts))
    cat(sprintf("   FC: %.2fx\n", row$FC))
    cat(sprintf("   p-value: %.4f\n", row$padj))
    cat(sprintf("   Prevalence: %.1f%% ALS samples\n", row$Pct_ALS_Samples))
  }
  cat("\n")
} else {
  cat("⚠️ No hay candidatos que cumplan TODOS los criterios\n")
  cat("   Considera relajar umbrales\n\n")
}

cat(paste(rep("═", 70), collapse = ""), "\n")
cat("📊 DISTRIBUCIÓN POR MÉTRICA:\n")
cat(paste(rep("═", 70), collapse = ""), "\n\n")

cat(sprintf("Z-score > 2: %d miRNAs\n", sum(mirna_metrics$Z_score > 2, na.rm=TRUE)))
cat(sprintf("VAF > 0.001: %d miRNAs\n", sum(mirna_metrics$Mean_VAF_ALS > 0.001, na.rm=TRUE)))
cat(sprintf("Counts > 50: %d miRNAs\n", sum(mirna_metrics$Total_Counts > 50, na.rm=TRUE)))
cat(sprintf("p < 0.05: %d miRNAs\n", sum(mirna_metrics$padj < 0.05, na.rm=TRUE)))
cat(sprintf("p < 0.10: %d miRNAs\n\n", sum(mirna_metrics$padj < 0.10, na.rm=TRUE)))

cat("🎯 FILTROS SUGERIDOS (basados en distribución):\n\n")

# Calcular umbrales adaptativos
z_90 <- quantile(mirna_metrics$Z_score, 0.90, na.rm=TRUE)
vaf_75 <- quantile(mirna_metrics$Mean_VAF_ALS, 0.75, na.rm=TRUE)
counts_median <- median(mirna_metrics$Total_Counts, na.rm=TRUE)

cat("OPCIÓN A: CONSERVADORA\n")
cat(sprintf("   • Z-score > 3.0\n"))
cat(sprintf("   • Mean VAF > 0.005\n"))
cat(sprintf("   • Total Counts > 100\n"))
cat(sprintf("   • p-value < 0.01\n"))
cat(sprintf("   → Resultado: %d candidatos\n\n", 
    sum(mirna_metrics$Z_score > 3.0 & 
        mirna_metrics$Mean_VAF_ALS > 0.005 & 
        mirna_metrics$Total_Counts > 100 & 
        mirna_metrics$padj < 0.01, na.rm=TRUE)))

cat("OPCIÓN B: BALANCEADA (Recomendada)\n")
cat(sprintf("   • Z-score > 2.0\n"))
cat(sprintf("   • Mean VAF > 0.001\n"))
cat(sprintf("   • Total Counts > 50\n"))
cat(sprintf("   • p-value < 0.05\n"))
cat(sprintf("   → Resultado: %d candidatos\n\n", 
    sum(mirna_metrics$Z_score > 2.0 & 
        mirna_metrics$Mean_VAF_ALS > 0.001 & 
        mirna_metrics$Total_Counts > 50 & 
        mirna_metrics$padj < 0.05, na.rm=TRUE)))

cat("OPCIÓN C: ADAPTATIVA (basada en percentiles)\n")
cat(sprintf("   • Z-score > %.2f (90th percentile)\n", z_90))
cat(sprintf("   • Mean VAF > %.5f (75th percentile)\n", vaf_75))
cat(sprintf("   • Total Counts > %.0f (median)\n", counts_median))
cat(sprintf("   • p-value < 0.10\n"))
cat(sprintf("   → Resultado: %d candidatos\n\n", 
    sum(mirna_metrics$Z_score > z_90 & 
        mirna_metrics$Mean_VAF_ALS > vaf_75 & 
        mirna_metrics$Total_Counts > counts_median & 
        mirna_metrics$padj < 0.10, na.rm=TRUE)))

cat(paste(rep("═", 70), collapse = ""), "\n")
cat("📁 ARCHIVOS GENERADOS:\n")
cat("   • FIG_MULTI_METRIC_VAF_COUNTS_ZSCORE.png\n")
cat("   • FIG_MULTI_METRIC_ZSCORE_PVALUE.png\n")
cat("   • FIG_MULTI_METRIC_HEATMAP.png\n")
cat("   • MULTI_METRIC_DATA.csv\n")
cat("   • CANDIDATES_MULTI_METRIC.csv\n")
cat(paste(rep("═", 70), collapse = ""), "\n\n")

