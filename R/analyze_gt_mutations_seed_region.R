#!/usr/bin/env Rscript

# Script para analizar mutaciones G>T específicamente en la región semilla
# miRNAs y Oxidación - Análisis ALS

library(dplyr)
library(readr)

cat("🧬 ANÁLISIS DE MUTACIONES G>T EN REGIÓN SEMILLA (posiciones 2-8)\n")
cat("===============================================================\n\n")

# Cargar datos procesados
cat("📂 Cargando datos procesados...\n")
df <- read_tsv("outputs/processed_snv_data_vaf_filtered.tsv", show_col_types = FALSE)

cat("✅ Datos cargados exitosamente\n")
cat("   - Filas:", nrow(df), "\n")
cat("   - Columnas:", ncol(df), "\n\n")

# Identificar columnas de muestras
sample_cols <- colnames(df)[!grepl("(PM\\+1MM\\+2MM|miRNA name|pos:mut|position|mutation)", colnames(df))]

# Filtrar solo mutaciones G>T
gt_mutations <- df %>% filter(mutation == "GT")

cat("🔍 MUTACIONES G>T GENERALES:\n")
cat("   - Total mutaciones G>T:", nrow(gt_mutations), "\n")
cat("   - Porcentaje del total:", round(nrow(gt_mutations)/nrow(df)*100, 2), "%\n\n")

# Filtrar mutaciones G>T en región semilla (posiciones 2-8)
gt_seed <- gt_mutations %>% filter(position >= 2 & position <= 8)

cat("🌱 MUTACIONES G>T EN REGIÓN SEMILLA (posiciones 2-8):\n")
cat("   - Total G>T en semilla:", nrow(gt_seed), "\n")
cat("   - Porcentaje de G>T en semilla:", round(nrow(gt_seed)/nrow(gt_mutations)*100, 2), "%\n")
cat("   - Porcentaje del total de SNVs:", round(nrow(gt_seed)/nrow(df)*100, 2), "%\n\n")

# Análisis por posición en región semilla
cat("📍 DISTRIBUCIÓN DE G>T POR POSICIÓN EN REGIÓN SEMILLA:\n")
seed_positions <- gt_seed %>% 
  group_by(position) %>% 
  summarise(
    count = n(),
    percentage = round(n()/nrow(gt_seed)*100, 2),
    .groups = "drop"
  ) %>% 
  arrange(position)

print(seed_positions)
cat("\n")

# Análisis por miRNA en región semilla
cat("🧬 TOP 10 miRNAs CON MÁS MUTACIONES G>T EN REGIÓN SEMILLA:\n")
top_gt_seed_mirnas <- gt_seed %>% 
  group_by(`miRNA name`) %>% 
  summarise(
    gt_seed_count = n(),
    .groups = "drop"
  ) %>% 
  arrange(desc(gt_seed_count)) %>% 
  head(10)

print(top_gt_seed_mirnas)
cat("\n")

# Calcular RPM promedio para miRNAs con G>T en semilla
cat("📊 RPM PROMEDIO DE miRNAs CON G>T EN REGIÓN SEMILLA:\n")

# Calcular RPM para cada miRNA
rpm_data <- df %>% 
  group_by(`miRNA name`) %>% 
  summarise(
    total_reads = sum(across(all_of(sample_cols)), na.rm = TRUE),
    .groups = "drop"
  ) %>% 
  mutate(
    rpm = (total_reads / sum(total_reads, na.rm = TRUE)) * 1000000
  )

# Combinar con datos de G>T en semilla
gt_seed_with_rpm <- gt_seed %>% 
  group_by(`miRNA name`) %>% 
  summarise(
    gt_seed_count = n(),
    .groups = "drop"
  ) %>% 
  left_join(rpm_data, by = "miRNA name") %>% 
  arrange(desc(gt_seed_count))

cat("Top 10 miRNAs con G>T en semilla y su RPM:\n")
top_gt_seed_with_rpm <- gt_seed_with_rpm %>% head(10)
print(top_gt_seed_with_rpm)
cat("\n")

# Estadísticas de RPM
cat("📈 ESTADÍSTICAS DE RPM PARA miRNAs CON G>T EN SEMILLA:\n")
rpm_stats <- gt_seed_with_rpm %>% 
  summarise(
    mean_rpm = round(mean(rpm, na.rm = TRUE), 2),
    median_rpm = round(median(rpm, na.rm = TRUE), 2),
    min_rpm = round(min(rpm, na.rm = TRUE), 2),
    max_rpm = round(max(rpm, na.rm = TRUE), 2),
    .groups = "drop"
  )

print(rpm_stats)
cat("\n")

# Verificar si hay miRNAs con G>T en semilla y RPM > 1
high_rpm_gt_seed <- gt_seed_with_rpm %>% filter(rpm > 1)
cat("🎯 miRNAs CON G>T EN SEMILLA Y RPM > 1:\n")
cat("   - Cantidad:", nrow(high_rpm_gt_seed), "\n")
cat("   - Porcentaje de miRNAs con G>T en semilla:", round(nrow(high_rpm_gt_seed)/nrow(gt_seed_with_rpm)*100, 2), "%\n\n")

if(nrow(high_rpm_gt_seed) > 0) {
  cat("Top 10 miRNAs con G>T en semilla y RPM > 1:\n")
  print(high_rpm_gt_seed %>% head(10))
  cat("\n")
}

# Resumen final
cat("✅ RESUMEN FINAL:\n")
cat("   - Total SNVs:", nrow(df), "\n")
cat("   - Total G>T:", nrow(gt_mutations), "(", round(nrow(gt_mutations)/nrow(df)*100, 2), "%)\n")
cat("   - G>T en región semilla:", nrow(gt_seed), "(", round(nrow(gt_seed)/nrow(gt_mutations)*100, 2), "% de G>T)\n")
cat("   - miRNAs únicos con G>T en semilla:", nrow(gt_seed_with_rpm), "\n")
cat("   - miRNAs con G>T en semilla y RPM > 1:", nrow(high_rpm_gt_seed), "\n")
cat("   - RPM promedio de miRNAs con G>T en semilla:", rpm_stats$mean_rpm, "\n\n")

cat("🎯 ANÁLISIS COMPLETADO\n")










