# =============================================================================
# ANÁLISIS DETALLADO POSICIÓN 6 - G>T MUTATIONS
# =============================================================================
# Script para analizar específicamente la posición 6 en miRNAs
# Incluye estadísticas, VAF, Z-score, miRNAs más afectados, etc.
# =============================================================================

# Cargar librerías
library(dplyr)
library(readr)
library(stringr)
library(tibble)
library(ggplot2)
library(ComplexHeatmap)
library(circlize)
library(gridExtra)

# Configurar opciones
ht_opt$message = FALSE
options(warn = -1)

cat("🔬 ANÁLISIS DETALLADO POSICIÓN 6 - G>T MUTATIONS\n")
cat("===============================================\n\n")

# --- 1. CARGAR DATOS ---
cat("📊 1. CARGANDO DATOS\n")
cat("===================\n")

# Cargar datos principales
df_main <- read.csv("organized/04_results/alex_df.csv", stringsAsFactors = FALSE)
df_vaf <- read.csv("organized/04_results/VAF_df.csv", stringsAsFactors = FALSE)

cat("✅ Datos cargados:\n")
cat("   - df_main:", nrow(df_main), "filas\n")
cat("   - df_vaf:", nrow(df_vaf), "filas\n\n")

# --- 2. FILTRAR POSICIÓN 6 ---
cat("🎯 2. FILTRANDO POSICIÓN 6\n")
cat("=========================\n")

# Extraer columnas de muestras (excluir columnas de metadatos)
sample_cols <- names(df_main)[!names(df_main) %in% c("X", "miRNA.name", "pos.mut")]

# Filtrar solo mutaciones G>T en posición 6
pos6_gt <- df_main %>%
  filter(str_detect(pos.mut, "^6:")) %>%
  filter(str_detect(pos.mut, "G>T$"))

cat("✅ Mutaciones G>T en posición 6 encontradas:", nrow(pos6_gt), "\n\n")

# --- 3. ANÁLISIS ESTADÍSTICO BÁSICO ---
cat("📈 3. ESTADÍSTICAS BÁSICAS POSICIÓN 6\n")
cat("====================================\n")

# Calcular VAF promedio por grupo
pos6_stats <- pos6_gt %>%
  select(all_of(sample_cols)) %>%
  summarise(
    total_snvs = n(),
    vaf_als = mean(select(., contains("ALS")) %>% rowMeans(na.rm = TRUE)),
    vaf_control = mean(select(., contains("Control")) %>% rowMeans(na.rm = TRUE)),
    vaf_difference = vaf_als - vaf_control,
    vaf_percentage_diff = (vaf_difference / vaf_control) * 100
  )

cat("📊 ESTADÍSTICAS POSICIÓN 6:\n")
cat("   - Total SNVs G>T: ", pos6_stats$total_snvs, "\n")
cat("   - VAF promedio ALS: ", round(pos6_stats$vaf_als, 2), "\n")
cat("   - VAF promedio Control: ", round(pos6_stats$vaf_control, 2), "\n")
cat("   - Diferencia VAF: ", round(pos6_stats$vaf_difference, 2), "\n")
cat("   - % Diferencia: ", round(pos6_stats$vaf_percentage_diff, 2), "%\n\n")

# --- 4. CÁLCULO DE Z-SCORE ---
cat("🧮 4. CÁLCULO DE Z-SCORE POSICIÓN 6\n")
cat("===================================\n")

# Calcular Z-score para posición 6
pos6_vaf_data <- pos6_gt %>%
  select(all_of(sample_cols)) %>%
  as.matrix()

# Separar grupos
als_cols <- sample_cols[str_detect(sample_cols, "ALS")]
control_cols <- sample_cols[str_detect(sample_cols, "Control")]

# Calcular VAF promedio por SNV en cada grupo
als_means <- rowMeans(pos6_vaf_data[, als_cols], na.rm = TRUE)
control_means <- rowMeans(pos6_vaf_data[, control_cols], na.rm = TRUE)

# Calcular Z-score usando desviación estándar agrupada
pooled_sd <- sqrt(((length(als_cols) - 1) * var(als_means) + 
                   (length(control_cols) - 1) * var(control_means)) / 
                  (length(als_cols) + length(control_cols) - 2))

z_score_pos6 <- (mean(als_means) - mean(control_means)) / pooled_sd

cat("📊 Z-SCORE POSICIÓN 6:\n")
cat("   - Z-score: ", round(z_score_pos6, 6), "\n")
cat("   - Interpretación: ", ifelse(abs(z_score_pos6) > 1.96, "Significativo (p<0.05)", "No significativo"), "\n\n")

# --- 5. ANÁLISIS POR miRNA ---
cat("🧬 5. ANÁLISIS POR miRNA POSICIÓN 6\n")
cat("===================================\n")

# Analizar miRNAs más afectados en posición 6
pos6_mirna_analysis <- pos6_gt %>%
  mutate(
    miRNA_name = str_extract(miRNA.name, "^[^-]+"),
    vaf_als = rowMeans(select(., all_of(als_cols)), na.rm = TRUE),
    vaf_control = rowMeans(select(., all_of(control_cols)), na.rm = TRUE),
    vaf_difference = vaf_als - vaf_control
  ) %>%
  group_by(miRNA_name) %>%
  summarise(
    count_als = sum(vaf_als > 0),
    count_control = sum(vaf_control > 0),
    total_count = n(),
    vaf_als_avg = mean(vaf_als),
    vaf_control_avg = mean(vaf_control),
    vaf_difference_avg = mean(vaf_difference),
    .groups = 'drop'
  ) %>%
  arrange(desc(total_count))

cat("📊 TOP 10 miRNAs MÁS AFECTADOS EN POSICIÓN 6:\n")
print(pos6_mirna_analysis[1:10, ])

# --- 6. ANÁLISIS DETALLADO POR GRUPO ---
cat("\n🔍 6. ANÁLISIS DETALLADO POR GRUPO\n")
cat("===================================\n")

# Análisis específico para ALS
als_pos6 <- pos6_gt %>%
  select(all_of(als_cols)) %>%
  summarise(
    total_snvs = n(),
    vaf_mean = mean(rowMeans(., na.rm = TRUE)),
    vaf_median = median(rowMeans(., na.rm = TRUE)),
    vaf_sd = sd(rowMeans(., na.rm = TRUE)),
    vaf_min = min(rowMeans(., na.rm = TRUE)),
    vaf_max = max(rowMeans(., na.rm = TRUE))
  )

# Análisis específico para Control
control_pos6 <- pos6_gt %>%
  select(all_of(control_cols)) %>%
  summarise(
    total_snvs = n(),
    vaf_mean = mean(rowMeans(., na.rm = TRUE)),
    vaf_median = median(rowMeans(., na.rm = TRUE)),
    vaf_sd = sd(rowMeans(., na.rm = TRUE)),
    vaf_min = min(rowMeans(., na.rm = TRUE)),
    vaf_max = max(rowMeans(., na.rm = TRUE))
  )

cat("📊 ESTADÍSTICAS DETALLADAS ALS:\n")
print(als_pos6)

cat("\n📊 ESTADÍSTICAS DETALLADAS CONTROL:\n")
print(control_pos6)

# --- 7. CREAR VISUALIZACIONES ---
cat("\n📊 7. CREANDO VISUALIZACIONES\n")
cat("=============================\n")

# Crear directorio de salida
if (!dir.exists("outputs/final_paper_graphs")) {
  dir.create("outputs/final_paper_graphs", recursive = TRUE)
}

# 7.1 Gráfica de comparación VAF ALS vs Control
p1 <- ggplot() +
  geom_boxplot(data = data.frame(
    Group = rep(c("ALS", "Control"), each = nrow(pos6_gt)),
    VAF = c(rowMeans(pos6_gt[, als_cols], na.rm = TRUE),
            rowMeans(pos6_gt[, control_cols], na.rm = TRUE))
  ), aes(x = Group, y = VAF, fill = Group)) +
  scale_fill_manual(values = c("ALS" = "#FF6B6B", "Control" = "#4ECDC4")) +
  labs(
    title = "VAF Comparison: Position 6 G>T Mutations",
    subtitle = paste("ALS vs Control (n =", nrow(pos6_gt), "SNVs)"),
    x = "Group",
    y = "VAF (Variant Allele Frequency)",
    caption = paste("Z-score:", round(z_score_pos6, 4))
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 12),
    legend.position = "none"
  )

# 7.2 Gráfica de distribución por miRNA
p2 <- pos6_mirna_analysis[1:15, ] %>%
  ggplot(aes(x = reorder(miRNA_name, total_count), y = total_count)) +
  geom_col(aes(fill = vaf_difference_avg), color = "black", size = 0.3) +
  scale_fill_gradient2(
    low = "#4ECDC4", 
    mid = "white", 
    high = "#FF6B6B",
    midpoint = 0,
    name = "VAF Difference\n(ALS - Control)"
  ) +
  labs(
    title = "Top 15 miRNAs: Position 6 G>T Mutations",
    subtitle = "Count and VAF Difference (ALS - Control)",
    x = "miRNA",
    y = "Total Count",
    caption = "Color indicates VAF difference (red = higher in ALS)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "bottom"
  )

# 7.3 Gráfica de VAF por posición (comparación)
pos6_comparison <- data.frame(
  Position = rep(6, 2),
  Group = c("ALS", "Control"),
  VAF_Mean = c(als_pos6$vaf_mean, control_pos6$vaf_mean),
  VAF_SD = c(als_pos6$vaf_sd, control_pos6$vaf_sd)
)

p3 <- ggplot(pos6_comparison, aes(x = Group, y = VAF_Mean, fill = Group)) +
  geom_col(alpha = 0.8) +
  geom_errorbar(aes(ymin = VAF_Mean - VAF_SD, ymax = VAF_Mean + VAF_SD), 
                width = 0.2, size = 1) +
  scale_fill_manual(values = c("ALS" = "#FF6B6B", "Control" = "#4ECDC4")) +
  labs(
    title = "VAF Comparison: Position 6 G>T Mutations",
    subtitle = "Mean ± Standard Deviation",
    x = "Group",
    y = "VAF (Variant Allele Frequency)",
    caption = paste("Difference:", round(pos6_stats$vaf_difference, 2))
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    legend.position = "none"
  )

# Guardar gráficas
ggsave("outputs/final_paper_graphs/position_6_vaf_comparison.pdf", p1, 
       width = 8, height = 6, dpi = 300)
ggsave("outputs/final_paper_graphs/position_6_mirna_analysis.pdf", p2, 
       width = 12, height = 8, dpi = 300)
ggsave("outputs/final_paper_graphs/position_6_statistical_comparison.pdf", p3, 
       width = 8, height = 6, dpi = 300)

cat("✅ Gráficas guardadas:\n")
cat("   - position_6_vaf_comparison.pdf\n")
cat("   - position_6_mirna_analysis.pdf\n")
cat("   - position_6_statistical_comparison.pdf\n\n")

# --- 8. RESUMEN FINAL ---
cat("📋 8. RESUMEN FINAL POSICIÓN 6\n")
cat("=============================\n")

cat("🎯 HALLAZGOS PRINCIPALES:\n")
cat("   - Total SNVs G>T en posición 6: ", pos6_stats$total_snvs, "\n")
cat("   - VAF promedio ALS: ", round(pos6_stats$vaf_als, 2), "\n")
cat("   - VAF promedio Control: ", round(pos6_stats$vaf_control, 2), "\n")
cat("   - Diferencia VAF: ", round(pos6_stats$vaf_difference, 2), " (", round(pos6_stats$vaf_percentage_diff, 2), "%)\n")
cat("   - Z-score: ", round(z_score_pos6, 6), "\n")
cat("   - Significancia estadística: ", ifelse(abs(z_score_pos6) > 1.96, "SÍ (p<0.05)", "NO"), "\n\n")

cat("🧬 miRNAs MÁS AFECTADOS:\n")
for (i in 1:5) {
  mirna <- pos6_mirna_analysis[i, ]
  cat("   ", i, ". ", mirna$miRNA_name, " (", mirna$total_count, " SNVs, VAF diff: ", round(mirna$vaf_difference_avg, 2), ")\n")
}

cat("\n✅ Análisis completado exitosamente!\n")










