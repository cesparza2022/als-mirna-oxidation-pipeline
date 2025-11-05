#!/usr/bin/env Rscript

# Script para analizar la relación entre expresión (RPM) y oxidación G>T en región semilla
# miRNAs y Oxidación - Análisis ALS

library(dplyr)
library(readr)
library(stringr)
library(ggplot2)
library(corrplot)

cat("🔬 ANÁLISIS RELACIÓN EXPRESIÓN-OXIDACIÓN\n")
cat("=======================================\n\n")

# Cargar datos procesados
cat("📂 Cargando datos procesados...\n")
df <- read_tsv("outputs/processed_snv_data_vaf_filtered.tsv", show_col_types = FALSE)

# Obtener columnas de muestras (solo las de conteos, no las de totales)
sample_names <- colnames(df)[grep("Magen-", colnames(df))]
sample_names <- sample_names[!grepl("\\(PM\\+1MM\\+2MM\\)", sample_names)]  # Solo conteos, no totales
total_cols <- colnames(df)[grep("\\(PM\\+1MM\\+2MM\\)", colnames(df))]

cat("📊 DATOS CARGADOS:\n")
cat("   - Total SNVs:", nrow(df), "\n")
cat("   - Muestras:", length(sample_names), "\n")
cat("   - miRNAs únicos:", length(unique(df$`miRNA name`)), "\n\n")

# --- 1. CALCULAR RPM POR miRNA ---
cat("📈 1. CALCULANDO RPM POR miRNA\n")
cat("==============================\n")

# Calcular RPM promedio por miRNA
rpm_data <- df %>%
  select(`miRNA name`, all_of(total_cols)) %>%
  group_by(`miRNA name`) %>%
  summarise(
    total_reads = sum(across(all_of(total_cols), ~ sum(.x, na.rm = TRUE))),
    avg_rpm = total_reads / length(sample_names),
    .groups = "drop"
  ) %>%
  arrange(desc(avg_rpm))

cat("📊 TOP 10 miRNAs POR RPM:\n")
print(head(rpm_data, 10))
cat("\n")

# --- 2. CALCULAR OXIDACIÓN G>T EN REGIÓN SEMILLA ---
cat("🧬 2. CALCULANDO OXIDACIÓN G>T EN REGIÓN SEMILLA\n")
cat("===============================================\n")

# Filtrar mutaciones GT en región semilla (posiciones 2-8)
gt_seed_mutations <- df %>%
  filter(
    str_detect(`pos:mut`, ":GT$"),
    as.numeric(str_extract(`pos:mut`, "^[0-9]+")) %in% 2:8
  ) %>%
  mutate(
    position = as.numeric(str_extract(`pos:mut`, "^[0-9]+")),
    mutation = str_extract(`pos:mut`, "[A-Z][A-Z]$")
  )

cat("🎯 MUTACIONES G>T EN REGIÓN SEMILLA:\n")
cat("   - Total SNVs G>T en semilla:", nrow(gt_seed_mutations), "\n")
cat("   - miRNAs únicos con G>T en semilla:", length(unique(gt_seed_mutations$`miRNA name`)), "\n")
cat("   - Posiciones cubiertas:", paste(sort(unique(gt_seed_mutations$position)), collapse = ", "), "\n\n")

# Calcular oxidación total por miRNA
oxidation_data <- gt_seed_mutations %>%
  select(`miRNA name`, all_of(sample_names)) %>%
  group_by(`miRNA name`) %>%
  summarise(
    total_gt_counts = sum(across(all_of(sample_names), ~ sum(.x, na.rm = TRUE))),
    mean_gt_vaf = mean(across(all_of(sample_names), ~ mean(.x, na.rm = TRUE))),
    max_gt_vaf = max(across(all_of(sample_names), ~ max(.x, na.rm = TRUE))),
    .groups = "drop"
  ) %>%
  arrange(desc(total_gt_counts))

cat("📊 TOP 10 miRNAs POR OXIDACIÓN G>T EN SEMILLA:\n")
print(head(oxidation_data, 10))
cat("\n")

# --- 3. COMBINAR DATOS Y ANÁLISIS DE CORRELACIÓN ---
cat("🔗 3. ANÁLISIS DE CORRELACIÓN EXPRESIÓN-OXIDACIÓN\n")
cat("================================================\n")

# Combinar datos
combined_data <- rpm_data %>%
  inner_join(oxidation_data, by = "miRNA name") %>%
  filter(total_gt_counts > 0)  # Solo miRNAs con oxidación G>T

cat("📊 DATOS COMBINADOS:\n")
cat("   - miRNAs con expresión y oxidación G>T:", nrow(combined_data), "\n")
cat("   - Rango RPM:", round(min(combined_data$avg_rpm), 2), "-", round(max(combined_data$avg_rpm), 2), "\n")
cat("   - Rango oxidación G>T:", min(combined_data$total_gt_counts), "-", max(combined_data$total_gt_counts), "\n\n")

# Análisis de correlación
correlation_result <- cor.test(combined_data$avg_rpm, combined_data$total_gt_counts, method = "pearson")

cat("🔬 RESULTADOS DE CORRELACIÓN:\n")
cat("   - Coeficiente de correlación (r):", round(correlation_result$estimate, 4), "\n")
cat("   - P-value:", format(correlation_result$p.value, scientific = TRUE), "\n")
cat("   - Significancia:", ifelse(correlation_result$p.value < 0.001, "Altamente significativa (p < 0.001)", 
                                 ifelse(correlation_result$p.value < 0.01, "Muy significativa (p < 0.01)",
                                        ifelse(correlation_result$p.value < 0.05, "Significativa (p < 0.05)", "No significativa"))), "\n\n")

# --- 4. ANÁLISIS POR CATEGORÍAS DE EXPRESIÓN ---
cat("📊 4. ANÁLISIS POR CATEGORÍAS DE EXPRESIÓN\n")
cat("==========================================\n")

# Categorizar miRNAs por nivel de expresión
combined_data <- combined_data %>%
  mutate(
    expression_category = case_when(
      avg_rpm >= quantile(avg_rpm, 0.8) ~ "Alta expresión (top 20%)",
      avg_rpm >= quantile(avg_rpm, 0.6) ~ "Expresión media-alta (60-80%)",
      avg_rpm >= quantile(avg_rpm, 0.4) ~ "Expresión media (40-60%)",
      avg_rpm >= quantile(avg_rpm, 0.2) ~ "Expresión baja-media (20-40%)",
      TRUE ~ "Baja expresión (bottom 20%)"
    )
  )

# Estadísticas por categoría
category_stats <- combined_data %>%
  group_by(expression_category) %>%
  summarise(
    n_mirnas = n(),
    mean_rpm = mean(avg_rpm),
    mean_oxidation = mean(total_gt_counts),
    median_oxidation = median(total_gt_counts),
    .groups = "drop"
  ) %>%
  arrange(desc(mean_rpm))

cat("📊 ESTADÍSTICAS POR CATEGORÍA DE EXPRESIÓN:\n")
print(category_stats)
cat("\n")

# --- 5. VISUALIZACIONES ---
cat("🎨 5. GENERANDO VISUALIZACIONES\n")
cat("===============================\n")

# Gráfico 1: Correlación expresión-oxidación
pdf("outputs/expression_oxidation_correlation.pdf", width = 10, height = 8)
p_correlation <- ggplot(combined_data, aes(x = avg_rpm, y = total_gt_counts)) +
  geom_point(alpha = 0.6, color = "steelblue") +
  geom_smooth(method = "lm", se = TRUE, color = "red") +
  scale_x_log10() +
  scale_y_log10() +
  labs(
    title = "Correlación entre Expresión (RPM) y Oxidación G>T en Región Semilla",
    subtitle = paste("r =", round(correlation_result$estimate, 4), 
                     ", p =", format(correlation_result$p.value, scientific = TRUE)),
    x = "RPM Promedio (log10)",
    y = "Conteos G>T en Región Semilla (log10)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 12, color = "gray50")
  )
print(p_correlation)
dev.off()
cat("✅ Gráfico de correlación guardado en: outputs/expression_oxidation_correlation.pdf\n")

# Gráfico 2: Boxplot por categorías de expresión
pdf("outputs/oxidation_by_expression_category.pdf", width = 12, height = 8)
p_boxplot <- ggplot(combined_data, aes(x = expression_category, y = total_gt_counts, fill = expression_category)) +
  geom_boxplot() +
  geom_jitter(width = 0.2, alpha = 0.5) +
  scale_y_log10() +
  labs(
    title = "Oxidación G>T en Región Semilla por Categoría de Expresión",
    x = "Categoría de Expresión",
    y = "Conteos G>T en Región Semilla (log10)"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "none",
    plot.title = element_text(size = 14, face = "bold")
  )
print(p_boxplot)
dev.off()
cat("✅ Boxplot por categorías guardado en: outputs/oxidation_by_expression_category.pdf\n")

# Gráfico 3: Top miRNAs con alta expresión y oxidación
top_high_expr_ox <- combined_data %>%
  filter(expression_category == "Alta expresión (top 20%)") %>%
  arrange(desc(total_gt_counts)) %>%
  head(15)

pdf("outputs/top_high_expression_oxidation.pdf", width = 12, height = 8)
p_top <- ggplot(top_high_expr_ox, aes(x = reorder(`miRNA name`, total_gt_counts), y = total_gt_counts)) +
  geom_col(fill = "darkred", alpha = 0.8) +
  coord_flip() +
  labs(
    title = "Top 15 miRNAs con Alta Expresión y Mayor Oxidación G>T en Semilla",
    x = "miRNA",
    y = "Conteos G>T en Región Semilla"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    axis.text.y = element_text(size = 10)
  )
print(p_top)
dev.off()
cat("✅ Gráfico de top miRNAs guardado en: outputs/top_high_expression_oxidation.pdf\n")

# --- 6. GUARDAR RESULTADOS ---
cat("💾 6. GUARDANDO RESULTADOS\n")
cat("==========================\n")

# Guardar datos combinados
write_tsv(combined_data, "outputs/expression_oxidation_combined_data.tsv")
cat("✅ Datos combinados guardados en: outputs/expression_oxidation_combined_data.tsv\n")

# Guardar estadísticas por categoría
write_tsv(category_stats, "outputs/expression_category_stats.tsv")
cat("✅ Estadísticas por categoría guardadas en: outputs/expression_category_stats.tsv\n")

# --- 7. RESUMEN FINAL ---
cat("\n🎯 RESUMEN FINAL\n")
cat("================\n")
cat("📊 miRNAs analizados:", nrow(combined_data), "\n")
cat("🔗 Correlación expresión-oxidación:", round(correlation_result$estimate, 4), "\n")
cat("📈 Significancia:", ifelse(correlation_result$p.value < 0.001, "Altamente significativa", "No significativa"), "\n")
cat("🎨 Gráficos generados: 3\n")
cat("💾 Archivos de datos: 2\n\n")

cat("✅ ANÁLISIS RELACIÓN EXPRESIÓN-OXIDACIÓN COMPLETADO\n")
cat("==================================================\n")
