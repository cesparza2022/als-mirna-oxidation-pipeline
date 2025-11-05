#!/usr/bin/env Rscript

# Script para verificar conteos de SNVs y proporciones por tipo de mutación
# miRNAs y Oxidación - Análisis ALS

library(dplyr)
library(readr)

cat("🔍 VERIFICACIÓN DE CONTEOS DE SNVs Y PROPORCIONES POR TIPO DE MUTACIÓN\n")
cat("================================================================\n\n")

# Cargar datos procesados
cat("📂 Cargando datos procesados...\n")
df <- read_tsv("outputs/processed_snv_data_vaf_filtered.tsv", show_col_types = FALSE)

cat("✅ Datos cargados exitosamente\n")
cat("   - Filas:", nrow(df), "\n")
cat("   - Columnas:", ncol(df), "\n\n")

# Verificar estructura de columnas
sample_cols <- colnames(df)[!grepl("(PM\\+1MM\\+2MM|miRNA name|pos:mut|position|mutation)", colnames(df))]
total_cols <- colnames(df)[grepl("\\(PM\\+1MM\\+2MM\\)", colnames(df))]

cat("📊 ESTRUCTURA DE DATOS:\n")
cat("   - Columnas de muestras (SNV counts):", length(sample_cols), "\n")
cat("   - Columnas de totales (PM+1MM+2MM):", length(total_cols), "\n")
cat("   - Total de muestras:", length(sample_cols), "\n\n")

# Extraer posición y mutación
df$position <- as.numeric(gsub(":.*", "", df$`pos:mut`))
df$mutation <- gsub(".*:", "", df$`pos:mut`)

# Conteos generales
cat("📈 CONTEOS GENERALES:\n")
cat("   - Total de SNVs:", nrow(df), "\n")
cat("   - miRNAs únicos:", length(unique(df$`miRNA name`)), "\n")
cat("   - SNVs únicos (pos:mut):", length(unique(df$`pos:mut`)), "\n")
cat("   - Posiciones únicas:", length(unique(df$position)), "\n")
cat("   - Tipos de mutación únicos:", length(unique(df$mutation)), "\n\n")

# Conteos por tipo de mutación
cat("🧬 CONTEOS POR TIPO DE MUTACIÓN:\n")
mutation_counts <- table(df$mutation)
mutation_props <- prop.table(mutation_counts) * 100

mutation_summary <- data.frame(
  Mutation = names(mutation_counts),
  Count = as.numeric(mutation_counts),
  Percentage = round(as.numeric(mutation_props), 2)
) %>%
  arrange(desc(Count))

print(mutation_summary)
cat("\n")

# Verificar mutaciones G>T específicamente
gt_mutations <- sum(df$mutation == "GT", na.rm = TRUE)
gt_percentage <- round((gt_mutations / nrow(df)) * 100, 2)

cat("🔬 ANÁLISIS ESPECÍFICO DE MUTACIONES G>T:\n")
cat("   - Total mutaciones G>T:", gt_mutations, "\n")
cat("   - Porcentaje de mutaciones G>T:", gt_percentage, "%\n\n")

# Conteos por posición
cat("📍 TOP 10 POSICIONES MÁS MUTADAS:\n")
position_counts <- table(df$position)
position_summary <- data.frame(
  Position = names(position_counts),
  Count = as.numeric(position_counts)
) %>%
  arrange(desc(Count)) %>%
  head(10)

print(position_summary)
cat("\n")

# Verificar algunos ejemplos de datos
cat("🔍 EJEMPLOS DE DATOS (primeras 5 filas):\n")
examples <- df %>%
  select(`miRNA name`, `pos:mut`, position, mutation) %>%
  head(5)
print(examples)
cat("\n")

# Verificar distribución de conteos por muestra
cat("📊 ESTADÍSTICAS DE CONTEOS POR MUESTRA:\n")
sample_counts <- df %>%
  select(all_of(sample_cols)) %>%
  summarise_all(sum, na.rm = TRUE)

cat("   - Conteo total mínimo por muestra:", min(sample_counts, na.rm = TRUE), "\n")
cat("   - Conteo total máximo por muestra:", max(sample_counts, na.rm = TRUE), "\n")
cat("   - Conteo total promedio por muestra:", round(mean(as.numeric(sample_counts), na.rm = TRUE), 2), "\n\n")

# Verificar si hay valores NA
na_count <- sum(is.na(df[, sample_cols]))
cat("⚠️  VALORES NA EN CONTEOS DE MUESTRAS:", na_count, "\n")

if (na_count > 0) {
  cat("   - Esto es esperado debido al filtro VAF aplicado\n")
} else {
  cat("   - No hay valores NA (todos los valores fueron imputados)\n")
}
cat("\n")

# Resumen final
cat("✅ RESUMEN FINAL:\n")
cat("   - Pipeline aplicado: Split → Collapse → Filtro VAF (50%)\n")
cat("   - SNVs procesados:", nrow(df), "\n")
cat("   - Muestras:", length(sample_cols), "\n")
cat("   - Mutaciones G>T:", gt_mutations, "(", gt_percentage, "%)\n")
cat("   - Tipos de mutación:", length(unique(df$mutation)), "\n\n")

cat("🎯 VERIFICACIÓN COMPLETADA\n")










