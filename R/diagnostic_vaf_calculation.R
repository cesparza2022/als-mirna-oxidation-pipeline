#!/usr/bin/env Rscript

# DIAGNÓSTICO DEL CÁLCULO DE VAFs
# Para entender por qué los VAFs están apareciendo como NA

library(dplyr)
library(stringr)
library(readr)

cat("🔍 DIAGNÓSTICO DE CÁLCULO DE VAFs\n")
cat("==================================\n\n")

# 1. Cargar datos
cat("📊 PASO 1: Cargando datos...\n")
df <- read_tsv("results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt", show_col_types = FALSE)
cat("   - Total filas:", nrow(df), "\n")
cat("   - Total miRNAs únicos:", length(unique(df$`miRNA name`)), "\n\n")

# 2. Identificar columnas
cat("📊 PASO 2: Identificando tipos de columnas...\n")
meta_cols <- c("miRNA name", "pos:mut")
all_cols <- colnames(df)
total_cols <- all_cols[str_detect(all_cols, "\\(PM\\+1MM\\+2MM\\)")]
snv_cols <- setdiff(all_cols, c(meta_cols, total_cols))

cat("   - Columnas meta:", length(meta_cols), "\n")
cat("   - Columnas SNV:", length(snv_cols), "\n")
cat("   - Columnas TOTAL:", length(total_cols), "\n\n")

# 3. Filtrar solo G>T
cat("📊 PASO 3: Filtrando solo mutaciones G>T...\n")
df_gt <- df %>% filter(str_detect(`pos:mut`, ":GT"))
cat("   - Filas con G>T:", nrow(df_gt), "\n")
cat("   - miRNAs únicos con G>T:", length(unique(df_gt$`miRNA name`)), "\n\n")

# 4. Examinar una muestra específica
cat("📊 PASO 4: Examinando una muestra específica...\n")
sample_mirna <- "hsa-let-7a-5p"
sample_data <- df_gt %>% filter(`miRNA name` == sample_mirna)

if (nrow(sample_data) > 0) {
  cat("   - Examinando miRNA:", sample_mirna, "\n")
  cat("   - Filas para este miRNA:", nrow(sample_data), "\n")
  
  # Mostrar algunas columnas SNV y TOTAL
  snv_sample <- sample_data[1, snv_cols[1:5]]
  total_sample <- sample_data[1, total_cols[1:5]]
  
  cat("   - Primeras 5 columnas SNV:\n")
  print(snv_sample)
  cat("   - Primeras 5 columnas TOTAL:\n")
  print(total_sample)
  
  # Verificar si hay valores no numéricos
  cat("   - Tipos de datos en columnas SNV:\n")
  print(sapply(snv_sample, class))
  cat("   - Tipos de datos en columnas TOTAL:\n")
  print(sapply(total_sample, class))
  
  # Verificar valores específicos
  cat("   - Valores en primera columna SNV:\n")
  print(snv_sample[1,1])
  cat("   - Valores en primera columna TOTAL:\n")
  print(total_sample[1,1])
  
} else {
  cat("   - No se encontraron datos para", sample_mirna, "\n")
}

# 5. Intentar calcular VAFs manualmente
cat("\n📊 PASO 5: Calculando VAFs manualmente...\n")
if (nrow(sample_data) > 0) {
  # Tomar solo las primeras 5 columnas para prueba
  snv_test <- as.numeric(sample_data[1, snv_cols[1:5]])
  total_test <- as.numeric(sample_data[1, total_cols[1:5]])
  
  cat("   - Valores SNV (primeras 5):", snv_test, "\n")
  cat("   - Valores TOTAL (primeras 5):", total_test, "\n")
  
  # Calcular VAF
  vaf_test <- snv_test / (total_test + 1e-10)
  cat("   - VAF calculado:", vaf_test, "\n")
  
  # Verificar si hay NAs
  cat("   - ¿Hay NAs en SNV?", any(is.na(snv_test)), "\n")
  cat("   - ¿Hay NAs en TOTAL?", any(is.na(total_test)), "\n")
  cat("   - ¿Hay NAs en VAF?", any(is.na(vaf_test)), "\n")
}

# 6. Verificar el problema con el cálculo de VAFs en el script original
cat("\n📊 PASO 6: Verificando cálculo de VAFs en el script original...\n")

# Intentar el mismo cálculo que en el script híbrido
snv_mat <- as.matrix(df_gt[, snv_cols])
total_mat <- as.matrix(df_gt[, total_cols])

# Asegurar que las columnas estén alineadas
colnames(total_mat) <- str_replace(colnames(total_mat), " \\(PM\\+1MM\\+2MM\\)", "")

# Calcular VAFs
vaf_mat <- snv_mat / (total_mat + 1e-10)

cat("   - Dimensiones de snv_mat:", dim(snv_mat), "\n")
cat("   - Dimensiones de total_mat:", dim(total_mat), "\n")
cat("   - Dimensiones de vaf_mat:", dim(vaf_mat), "\n")

# Verificar NAs
cat("   - ¿Hay NAs en snv_mat?", any(is.na(snv_mat)), "\n")
cat("   - ¿Hay NAs en total_mat?", any(is.na(total_mat)), "\n")
cat("   - ¿Hay NAs en vaf_mat?", any(is.na(vaf_mat)), "\n")

# Mostrar algunos valores de VAF
if (nrow(vaf_mat) > 0) {
  cat("   - Primeros valores de VAF:\n")
  print(vaf_mat[1, 1:5])
}

cat("\n✅ DIAGNÓSTICO COMPLETADO\n")
cat("========================\n")











