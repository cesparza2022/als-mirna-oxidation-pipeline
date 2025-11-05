#!/usr/bin/env Rscript
# ============================================================================
# VOLCANO PLOT MEJORADO: Multi-Métrico con Anotación Posicional
# 
# Combina:
#   • FC y p-value (eje X, Y tradicional)
#   • VAF (color intensity)
#   • Counts (tamaño)
#   • Posición enriquecida (shape/border)
# ============================================================================

library(dplyr)
library(readr)
library(ggplot2)
library(ggrepel)
library(stringr)

COLOR_ALS <- "#D62728"
COLOR_POS_ENRICHED <- "#E74C3C"  # Rojo más intenso para pos 2,3,5

cat("\n")
cat("╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║     🎯 VOLCANO MEJORADO: Multi-Métrico + Anotación Posicional       ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

# ============================================================================
# CARGAR DATOS
# ============================================================================

cat("📊 Cargando datos...\n")

# Volcano completo (301 miRNAs)
volcano <- read_csv("pipeline_2/VOLCANO_PLOT_DATA_PER_SAMPLE.csv", show_col_types = FALSE)

# Datos raw para calcular counts
data <- read_csv("pipeline_2/final_processed_data_CLEAN.csv", show_col_types = FALSE)
metadata <- read_csv("pipeline_2/metadata.csv", show_col_types = FALSE)

cat(sprintf("✅ Volcano: %d miRNAs\n", nrow(volcano)))
cat(sprintf("✅ Datos: %d SNVs\n\n", nrow(data)))

# ============================================================================
# IDENTIFICAR POSICIONES DE CADA miRNA
# ============================================================================

cat("📊 Identificando posiciones afectadas...\n")

# Para cada miRNA, ver en qué posiciones tiene G>T
mirna_positions <- data %>%
  filter(str_detect(pos.mut, "^[2-8]:GT$")) %>%
  mutate(Position = as.integer(str_extract(pos.mut, "^\\d+"))) %>%
  group_by(miRNA_name) %>%
  summarise(
    Positions = paste(sort(unique(Position)), collapse = ","),
    N_Positions = n_distinct(Position),
    Has_Pos_2_3_5 = any(Position %in% c(2, 3, 5)),
    Only_Pos_2_3_5 = all(Position %in% c(2, 3, 5)),
    .groups = "drop"
  )

cat(sprintf("✅ %d miRNAs con posiciones identificadas\n\n", nrow(mirna_positions)))

# ============================================================================
# CALCULAR COUNTS POR miRNA
# ============================================================================

cat("📊 Calculando counts...\n")

# Filtrar primero
data_gt_seed <- data %>%
  filter(str_detect(pos.mut, "^[2-8]:GT$"))

# Luego pivot
data_long <- data_gt_seed %>%
  tidyr::pivot_longer(cols = -c(miRNA_name, pos.mut), 
                      names_to = "Sample_ID", 
                      values_to = "VAF")

# Filtrar y join
data_long <- data_long %>%
  filter(!is.na(VAF), VAF > 0) %>%
  left_join(metadata, by = "Sample_ID")

mirna_counts_long <- data_long %>%
  group_by(miRNA_name, Group) %>%
  summarise(
    N_Observations = n(),
    N_Samples = n_distinct(Sample_ID),
    .groups = "drop"
  )

library(tidyr)  # Asegurar que está cargado

mirna_counts <- mirna_counts_long %>%
  pivot_wider(
    names_from = Group,
    values_from = c(N_Observations, N_Samples),
    values_fill = 0
  ) %>%
  mutate(
    Total_Counts = N_Observations_ALS + N_Observations_Control,
    Pct_ALS_Samples = 100 * N_Samples_ALS / 313,
    Pct_Control_Samples = 100 * N_Samples_Control / 102
  )

cat(sprintf("✅ Counts calculados\n\n", nrow(mirna_counts)))

# ============================================================================
# INTEGRAR TODO
# ============================================================================

cat("📊 Integrando métricas...\n")

volcano_enhanced <- volcano %>%
  left_join(mirna_positions, by = c("miRNA" = "miRNA_name")) %>%
  left_join(mirna_counts, by = c("miRNA" = "miRNA_name")) %>%
  mutate(
    # Clasificación mejorada
    Category = case_when(
      # ALS candidatos con pos enriquecidas
      log2FC > 0.58 & padj < 0.05 & Has_Pos_2_3_5 ~ "ALS (Pos 2,3,5) - High Conf",
      log2FC > 0.32 & padj < 0.10 & Has_Pos_2_3_5 ~ "ALS (Pos 2,3,5) - Moderate",
      
      # ALS candidatos sin pos enriquecidas
      log2FC > 0.58 & padj < 0.05 ~ "ALS (Other Pos) - High Conf",
      log2FC > 0.32 & padj < 0.10 ~ "ALS (Other Pos) - Moderate",
      
      # Control
      log2FC < -0.32 & padj < 0.10 ~ "Control Enriched",
      
      # No significativo
      TRUE ~ "Not Significant"
    ),
    
    # Shape por posición
    Shape_Category = ifelse(Has_Pos_2_3_5, "Contains Pos 2,3,5", "Other Positions"),
    
    # Reemplazar NAs en counts
    Total_Counts = replace_na(Total_Counts, 0),
    Pct_ALS_Samples = replace_na(Pct_ALS_Samples, 0)
  )

cat(sprintf("✅ Datos integrados: %d miRNAs\n\n", nrow(volcano_enhanced)))

# ============================================================================
# FIGURA PRINCIPAL: VOLCANO MULTI-MÉTRICO
# ============================================================================

cat("📊 Generando Volcano Plot multi-métrico...\n")

# Top candidatos para etiquetar
top_labels <- volcano_enhanced %>%
  filter(
    (log2FC > 0.58 & padj < 0.10) |  # ALS significativos
    (log2FC < -0.32 & padj < 0.10) |  # Control significativos
    (abs(log2FC) > 1.5)  # FC extremos
  ) %>%
  arrange(desc(abs(log2FC))) %>%
  head(20)

# Crear figura
fig_volcano <- ggplot(volcano_enhanced, aes(x = log2FC, y = -log10(padj))) +
  
  # Puntos base
  geom_point(
    aes(
      color = Mean_ALS,           # Color por VAF
      size = Total_Counts,        # Tamaño por counts
      shape = Shape_Category      # Shape por posición
    ),
    alpha = 0.7
  ) +
  
  # Escalas
  scale_color_gradient(
    low = "#fee5d9",
    high = COLOR_ALS,
    trans = "log10",
    name = "Mean VAF\n(ALS)",
    labels = scales::scientific,
    na.value = "grey90"
  ) +
  
  scale_size_continuous(
    range = c(1, 10),
    name = "Total\nCounts",
    breaks = c(10, 50, 100, 200)
  ) +
  
  scale_shape_manual(
    values = c("Contains Pos 2,3,5" = 17, "Other Positions" = 16),  # Triángulo vs círculo
    name = "Position\nType"
  ) +
  
  # Líneas de referencia
  geom_vline(xintercept = c(-0.58, 0.58), linetype = "dashed", color = "grey50", alpha = 0.6) +
  geom_hline(yintercept = -log10(0.05), linetype = "dashed", color = "grey50", alpha = 0.6) +
  geom_vline(xintercept = 0, linetype = "solid", color = "grey30", alpha = 0.3) +
  
  # Etiquetas
  geom_text_repel(
    data = top_labels,
    aes(label = miRNA),
    size = 3,
    fontface = "bold",
    max.overlaps = 20,
    box.padding = 0.5,
    segment.color = "grey40",
    segment.size = 0.3
  ) +
  
  # Anotaciones
  annotate("text", x = 2.5, y = 0.3, 
           label = sprintf("Pos 2,3,5: %d miRNAs (▲)", sum(volcano_enhanced$Has_Pos_2_3_5, na.rm=TRUE)), 
           color = COLOR_POS_ENRICHED, size = 4, fontface = "bold") +
  
  annotate("text", x = 2.5, y = 0.1, 
           label = sprintf("Other Pos: %d miRNAs (●)", sum(!volcano_enhanced$Has_Pos_2_3_5, na.rm=TRUE)), 
           color = "grey60", size = 4, fontface = "bold") +
  
  labs(
    title = "Enhanced Volcano Plot: Multi-Metric miRNA Selection",
    subtitle = "X = Fold Change | Y = Significance | Color = VAF | Size = Counts | Shape = Position",
    x = "log2(Fold Change) ALS vs Control",
    y = "-log10(p-value adjusted)",
    caption = "Triangle (▲) = Has G>T in positions 2,3,5 (enriched)\nCircle (●) = G>T only in positions 4,6,7,8\nDashed lines: FC 1.5x, p 0.05"
  ) +
  
  theme_classic(base_size = 14) +
  theme(
    plot.title = element_text(size = 18, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5, color = "grey40"),
    legend.position = "right",
    panel.grid.major = element_line(color = "grey95", size = 0.3),
    plot.caption = element_text(hjust = 0, size = 10, color = "grey50")
  )

ggsave("FIG_VOLCANO_ENHANCED_MULTI_METRIC.png", fig_volcano, width = 18, height = 12, dpi = 300)

cat("   ✅ Guardada\n\n")

# ============================================================================
# TABLA RESUMEN DE CANDIDATOS
# ============================================================================

cat("📊 Generando tabla resumen...\n")

# Candidatos ALS
als_candidates_enhanced <- volcano_enhanced %>%
  filter(log2FC > 0.32, padj < 0.10) %>%
  arrange(desc(log2FC)) %>%
  select(
    miRNA,
    log2FC,
    padj,
    Mean_ALS,
    Mean_Control,
    Total_Counts,
    Pct_ALS_Samples,
    Has_Pos_2_3_5,
    Positions,
    Category
  ) %>%
  mutate(
    FC = round(2^log2FC, 2),
    Priority = case_when(
      Has_Pos_2_3_5 & padj < 0.05 ~ "HIGH",
      Has_Pos_2_3_5 & padj < 0.10 ~ "MEDIUM",
      padj < 0.05 ~ "MEDIUM",
      TRUE ~ "LOW"
    )
  )

write_csv(als_candidates_enhanced, "ALS_CANDIDATES_ENHANCED.csv")

cat("   ✅ Tabla guardada\n\n")

# ============================================================================
# RESUMEN
# ============================================================================

cat(paste(rep("═", 70), collapse = ""), "\n")
cat("✅ VOLCANO MULTI-MÉTRICO COMPLETADO\n")
cat(paste(rep("═", 70), collapse = ""), "\n\n")

cat("📊 CANDIDATOS ALS (FC > 1.25x, p < 0.10):\n")
cat(paste(rep("─", 70), collapse = ""), "\n\n")

als_summary <- als_candidates_enhanced %>%
  count(Priority, Has_Pos_2_3_5) %>%
  arrange(Priority)

cat("Por PRIORIDAD y POSICIÓN:\n")
print(als_summary)
cat("\n")

cat("🔝 TOP 10 CANDIDATOS:\n")
cat(paste(rep("─", 70), collapse = ""), "\n\n")

top10 <- head(als_candidates_enhanced, 10)
for (i in 1:min(10, nrow(top10))) {
  row <- top10[i, ]
  pos_marker <- ifelse(row$Has_Pos_2_3_5, "▲", "●")
  cat(sprintf("%d. %s %s [%s]\n", i, pos_marker, row$miRNA, row$Priority))
  cat(sprintf("   FC: %.2fx | p: %.4f | VAF: %.5f | Counts: %d\n", 
              row$FC, row$padj, row$Mean_ALS, row$Total_Counts))
  cat(sprintf("   Positions: %s | Prevalence: %.1f%% ALS\n", 
              row$Positions, row$Pct_ALS_Samples))
  cat("\n")
}

cat(paste(rep("═", 70), collapse = ""), "\n")
cat("💡 INTERPRETACIÓN DE LA FIGURA:\n")
cat(paste(rep("═", 70), collapse = ""), "\n\n")

cat("EJES:\n")
cat("   X (log2FC): Fold Change ALS vs Control\n")
cat("   Y (-log10p): Significancia estadística\n\n")

cat("COLOR (Intensidad de rojo):\n")
cat("   • Rojo oscuro: VAF alto en ALS\n")
cat("   • Rojo claro: VAF bajo en ALS\n")
cat("   → Indica INTENSIDAD del fenómeno\n\n")

cat("TAMAÑO (Círculo/Triángulo):\n")
cat("   • Grande: Muchas observaciones (counts)\n")
cat("   • Pequeño: Pocas observaciones\n")
cat("   → Indica ROBUSTEZ/FRECUENCIA\n\n")

cat("FORMA:\n")
cat("   ▲ Triángulo: Tiene G>T en pos 2,3,5 (enriquecidas)\n")
cat("   ● Círculo: Solo G>T en pos 4,6,7,8\n")
cat("   → Indica ESPECIFICIDAD POSICIONAL\n\n")

cat(paste(rep("═", 70), collapse = ""), "\n")
cat("🎯 FILTROS SUGERIDOS:\n")
cat(paste(rep("═", 70), collapse = ""), "\n\n")

# Contar por diferentes filtros
cat("TIER 1 (ULTRA-ROBUSTOS):\n")
cat("   FC > 1.5x AND p < 0.05 AND Pos 2,3,5:\n")
tier1 <- volcano_enhanced %>%
  filter(log2FC > 0.58, padj < 0.05, Has_Pos_2_3_5)
cat(sprintf("   → %d candidatos\n", nrow(tier1)))
if (nrow(tier1) > 0) {
  cat("   ", paste(tier1$miRNA, collapse = ", "), "\n")
}
cat("\n")

cat("TIER 2 (ROBUSTOS):\n")
cat("   FC > 1.5x AND p < 0.05 (cualquier posición):\n")
tier2 <- volcano_enhanced %>%
  filter(log2FC > 0.58, padj < 0.05)
cat(sprintf("   → %d candidatos\n", nrow(tier2)))
if (nrow(tier2) > 0) {
  cat("   ", paste(tier2$miRNA, collapse = ", "), "\n")
}
cat("\n")

cat("TIER 3 (PROMETEDORES):\n")
cat("   FC > 1.25x AND p < 0.10 AND Pos 2,3,5:\n")
tier3 <- volcano_enhanced %>%
  filter(log2FC > 0.32, padj < 0.10, Has_Pos_2_3_5)
cat(sprintf("   → %d candidatos\n", nrow(tier3)))
cat("\n")

cat("TIER 4 (EXPLORATORIOS):\n")
cat("   FC > 1.25x AND p < 0.10 (cualquier posición):\n")
tier4 <- volcano_enhanced %>%
  filter(log2FC > 0.32, padj < 0.10)
cat(sprintf("   → %d candidatos (ACTUAL)\n", nrow(tier4)))
cat("\n")

cat(paste(rep("═", 70), collapse = ""), "\n")
cat("🚀 RECOMENDACIÓN:\n")
cat(paste(rep("═", 70), collapse = ""), "\n\n")

if (nrow(tier1) > 0) {
  cat("✅ TIER 1 tiene candidatos → Usar esos para Paso 3\n")
  cat(sprintf("   %d miRNAs con FC > 1.5x, p < 0.05, pos 2,3,5\n\n", nrow(tier1)))
} else if (nrow(tier2) > 0) {
  cat("✅ TIER 2 tiene candidatos → Priorizar los con pos 2,3,5\n")
  cat(sprintf("   %d miRNAs con FC > 1.5x, p < 0.05\n", nrow(tier2)))
  tier2_with_pos <- sum(tier2$Has_Pos_2_3_5, na.rm=TRUE)
  cat(sprintf("   De estos, %d tienen pos 2,3,5 → PRIORIZAR\n\n", tier2_with_pos))
} else {
  cat("⚠️ No hay candidatos en TIER 1 o 2\n")
  cat("   Opciones:\n")
  cat("   A) Usar TIER 3 (pos 2,3,5 con p < 0.10)\n")
  cat("   B) Relajar umbrales\n")
  cat("   C) Considerar que el dataset es débil\n\n")
}

cat(paste(rep("═", 70), collapse = ""), "\n")
cat("📁 ARCHIVOS GENERADOS:\n")
cat("   • FIG_VOLCANO_ENHANCED_MULTI_METRIC.png\n")
cat("   • ALS_CANDIDATES_ENHANCED.csv\n")
cat(paste(rep("═", 70), collapse = ""), "\n\n")

