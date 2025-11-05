#!/usr/bin/env Rscript

# Script para análisis de significancia REAL de mutaciones GT en región semilla
# Enfoque: VAF, conteos reales, y significancia biológica - NO número de SNVs

library(dplyr)
library(readr)
library(stringr)
library(ggplot2)
library(ComplexHeatmap)
library(circlize)
library(tidyr)

cat("🔬 ANÁLISIS DE SIGNIFICANCIA REAL - GT MUTATIONS EN REGIÓN SEMILLA\n")
cat("===============================================================\n\n")

# Cargar datos procesados
cat("📂 Cargando datos procesados...\n")
df <- read_tsv("outputs/processed_snv_data_vaf_filtered.tsv", show_col_types = FALSE)

# Obtener columnas de muestras (solo conteos, no totales)
sample_names <- colnames(df)[grep("Magen-", colnames(df))]
sample_names <- sample_names[!grepl("\\(PM\\+1MM\\+2MM\\)", sample_names)]
total_cols <- colnames(df)[grep("\\(PM\\+1MM\\+2MM\\)", colnames(df))]

cat("📊 DATOS CARGADOS:\n")
cat("   - Total SNVs:", nrow(df), "\n")
cat("   - Muestras:", length(sample_names), "\n")
cat("   - miRNAs únicos:", length(unique(df$`miRNA name`)), "\n\n")

# --- 1. FILTRAR MUTACIONES GT EN REGIÓN SEMILLA ---
cat("🎯 1. IDENTIFICANDO MUTACIONES GT EN REGIÓN SEMILLA\n")
cat("=================================================\n")

gt_seed_mutations <- df %>%
  filter(
    str_detect(`pos:mut`, ":GT$"),
    as.numeric(str_extract(`pos:mut`, "^[0-9]+")) %in% 2:8
  ) %>%
  mutate(
    position = as.numeric(str_extract(`pos:mut`, "^[0-9]+")),
    mutation = str_extract(`pos:mut`, "[A-Z][A-Z]$")
  )

cat("🧬 MUTACIONES GT EN REGIÓN SEMILLA IDENTIFICADAS:\n")
cat("   - Total SNVs GT en semilla:", nrow(gt_seed_mutations), "\n")
cat("   - miRNAs únicos afectados:", length(unique(gt_seed_mutations$`miRNA name`)), "\n")
cat("   - Posiciones cubiertas:", paste(sort(unique(gt_seed_mutations$position)), collapse = ", "), "\n\n")

# --- 2. ANÁLISIS DE VAF REAL POR POSICIÓN ---
cat("📊 2. ANÁLISIS DE VAF REAL POR POSICIÓN\n")
cat("=======================================\n")

# Calcular VAF real por posición
vaf_by_position <- gt_seed_mutations %>%
  select(`miRNA name`, `pos:mut`, position, all_of(sample_names)) %>%
  pivot_longer(cols = all_of(sample_names), names_to = "sample", values_to = "vaf") %>%
  mutate(vaf = as.numeric(vaf)) %>%
  filter(vaf > 0) %>%  # Solo muestras con mutación presente
  group_by(position) %>%
  summarise(
    n_samples_with_mutation = n(),
    mean_vaf = mean(vaf, na.rm = TRUE),
    median_vaf = median(vaf, na.rm = TRUE),
    sd_vaf = sd(vaf, na.rm = TRUE),
    max_vaf = max(vaf, na.rm = TRUE),
    q75_vaf = quantile(vaf, 0.75, na.rm = TRUE),
    q25_vaf = quantile(vaf, 0.25, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(mean_vaf))

cat("📈 VAF REAL POR POSICIÓN EN REGIÓN SEMILLA:\n")
print(vaf_by_position)
cat("\n")

# --- 3. ANÁLISIS DE CONTEOS REALES POR POSICIÓN ---
cat("🔢 3. ANÁLISIS DE CONTEOS REALES POR POSICIÓN\n")
cat("=============================================\n")

# Los datos ya están en formato VAF, así que analizamos la distribución de VAF
vaf_distribution_by_position <- gt_seed_mutations %>%
  select(`miRNA name`, `pos:mut`, position, all_of(sample_names)) %>%
  pivot_longer(cols = all_of(sample_names), names_to = "sample", values_to = "vaf") %>%
  mutate(vaf = as.numeric(vaf)) %>%
  filter(vaf > 0) %>%
  group_by(position) %>%
  summarise(
    total_vaf_sum = sum(vaf, na.rm = TRUE),
    mean_vaf = mean(vaf, na.rm = TRUE),
    median_vaf = median(vaf, na.rm = TRUE),
    max_vaf = max(vaf, na.rm = TRUE),
    n_samples_with_mutation = n(),
    vaf_above_10_percent = sum(vaf >= 0.1, na.rm = TRUE),
    vaf_above_50_percent = sum(vaf >= 0.5, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(total_vaf_sum))

cat("🔢 DISTRIBUCIÓN VAF POR POSICIÓN:\n")
print(vaf_distribution_by_position)
cat("\n")

# --- 4. ANÁLISIS DE SIGNIFICANCIA BIOLÓGICA ---
cat("🧬 4. ANÁLISIS DE SIGNIFICANCIA BIOLÓGICA\n")
cat("=========================================\n")

# Usar solo vaf_distribution_by_position que tiene toda la información
significance_analysis <- vaf_distribution_by_position %>%
  mutate(
    biological_impact_score = mean_vaf * log10(total_vaf_sum + 1),
    functional_importance = case_when(
      position %in% c(2, 3) ~ "Critical seed start",
      position %in% c(4, 5) ~ "Core seed region", 
      position %in% c(6, 7) ~ "Seed end region",
      position == 8 ~ "Seed boundary"
    ),
    significance_level = case_when(
      mean_vaf >= 0.1 & vaf_above_10_percent >= 10 ~ "High",
      mean_vaf >= 0.05 & vaf_above_10_percent >= 5 ~ "Medium",
      mean_vaf >= 0.01 & vaf_above_10_percent >= 1 ~ "Low",
      TRUE ~ "Very Low"
    )
  ) %>%
  arrange(desc(biological_impact_score))

cat("🎯 ANÁLISIS DE SIGNIFICANCIA BIOLÓGICA:\n")
print(significance_analysis)
cat("\n")

# --- 5. ANÁLISIS POR miRNA CON MAYOR IMPACTO REAL ---
cat("📈 5. TOP miRNAs POR IMPACTO REAL\n")
cat("===============================\n")

# Calcular impacto real por miRNA
mirna_impact <- gt_seed_mutations %>%
  select(`miRNA name`, `pos:mut`, position, all_of(sample_names)) %>%
  pivot_longer(cols = all_of(sample_names), names_to = "sample", values_to = "vaf") %>%
  mutate(vaf = as.numeric(vaf)) %>%
  filter(vaf > 0) %>%
  group_by(`miRNA name`) %>%
  summarise(
    total_vaf_sum = sum(vaf, na.rm = TRUE),
    mean_vaf = mean(vaf, na.rm = TRUE),
    max_vaf = max(vaf, na.rm = TRUE),
    n_positions_affected = n_distinct(position),
    positions = paste(sort(unique(position)), collapse = ", "),
    biological_impact = total_vaf_sum * mean_vaf,
    high_vaf_samples = sum(vaf >= 0.1, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(biological_impact)) %>%
  head(20)

cat("🏆 TOP 20 miRNAs POR IMPACTO BIOLÓGICO REAL:\n")
print(mirna_impact)
cat("\n")

# --- 6. VISUALIZACIONES ---
cat("🎨 6. GENERANDO VISUALIZACIONES\n")
cat("===============================\n")

# Gráfico 1: VAF real por posición
pdf("outputs/real_vaf_by_position.pdf", width = 10, height = 8)
p_vaf <- ggplot(significance_analysis, aes(x = as.factor(position), y = mean_vaf, fill = significance_level)) +
  geom_col(alpha = 0.8) +
  labs(
    title = "VAF Real Promedio por Posición en Región Semilla",
    subtitle = "Basado en muestras con mutaciones GT presentes (VAF > 0)",
    x = "Posición en miRNA",
    y = "VAF Promedio",
    fill = "Nivel de Significancia"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    axis.text.x = element_text(size = 12),
    legend.position = "bottom"
  )
print(p_vaf)
dev.off()
cat("✅ Gráfico VAF real guardado en: outputs/real_vaf_by_position.pdf\n")

# Gráfico 2: Distribución VAF por posición
pdf("outputs/vaf_distribution_by_position.pdf", width = 10, height = 8)
p_dist <- ggplot(significance_analysis, aes(x = as.factor(position), y = total_vaf_sum, fill = functional_importance)) +
  geom_col(alpha = 0.8) +
  scale_y_log10() +
  labs(
    title = "Suma Total de VAF por Posición en Región Semilla",
    subtitle = "Suma de todos los VAF > 0 (escala log10)",
    x = "Posición en miRNA",
    y = "Suma Total de VAF (log10)",
    fill = "Importancia Funcional"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    axis.text.x = element_text(size = 12),
    legend.position = "bottom"
  )
print(p_dist)
dev.off()
cat("✅ Gráfico distribución VAF guardado en: outputs/vaf_distribution_by_position.pdf\n")

# Gráfico 3: Score de impacto biológico
pdf("outputs/biological_impact_score.pdf", width = 10, height = 8)
p_impact <- ggplot(significance_analysis, aes(x = as.factor(position), y = biological_impact_score, fill = significance_level)) +
  geom_col(alpha = 0.8) +
  labs(
    title = "Score de Impacto Biológico por Posición",
    subtitle = "mean_vaf × log10(total_real_counts + 1)",
    x = "Posición en miRNA",
    y = "Score de Impacto Biológico",
    fill = "Nivel de Significancia"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    axis.text.x = element_text(size = 12),
    legend.position = "bottom"
  )
print(p_impact)
dev.off()
cat("✅ Gráfico impacto biológico guardado en: outputs/biological_impact_score.pdf\n")

# Gráfico 4: Top miRNAs por impacto real
pdf("outputs/top_mirnas_real_impact.pdf", width = 12, height = 8)
p_top_mirnas <- ggplot(head(mirna_impact, 15), aes(x = reorder(`miRNA name`, biological_impact), y = biological_impact)) +
  geom_col(fill = "darkred", alpha = 0.8) +
  coord_flip() +
  labs(
    title = "Top 15 miRNAs por Impacto Biológico Real",
    subtitle = "total_real_counts × mean_vaf",
    x = "miRNA",
    y = "Impacto Biológico"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    axis.text.y = element_text(size = 10)
  )
print(p_top_mirnas)
dev.off()
cat("✅ Gráfico top miRNAs guardado en: outputs/top_mirnas_real_impact.pdf\n")

# --- 7. GUARDAR RESULTADOS ---
cat("💾 7. GUARDANDO RESULTADOS\n")
cat("==========================\n")

write_tsv(significance_analysis, "outputs/real_significance_analysis.tsv")
cat("✅ Análisis de significancia guardado en: outputs/real_significance_analysis.tsv\n")

write_tsv(mirna_impact, "outputs/mirna_real_impact.tsv")
cat("✅ Impacto por miRNA guardado en: outputs/mirna_real_impact.tsv\n")

# --- 8. RESUMEN FINAL ---
cat("\n🎯 RESUMEN FINAL - ENFOQUE EN SIGNIFICANCIA REAL\n")
cat("===============================================\n")
cat("📊 Posiciones analizadas:", nrow(significance_analysis), "\n")
cat("🧬 miRNAs con impacto real:", nrow(mirna_impact), "\n")
cat("🎯 Posición más significativa:", significance_analysis$position[1], 
    "(VAF medio:", round(significance_analysis$mean_vaf[1], 4), 
    ", Suma VAF:", format(significance_analysis$total_vaf_sum[1], scientific = TRUE), ")\n")
cat("🏆 miRNA más impactado:", mirna_impact$`miRNA name`[1], 
    "(Impacto:", format(mirna_impact$biological_impact[1], scientific = TRUE), ")\n")
cat("🎨 Gráficos generados: 4\n")
cat("💾 Archivos de datos: 2\n\n")

cat("✅ ANÁLISIS DE SIGNIFICANCIA REAL COMPLETADO\n")
cat("===========================================\n")
