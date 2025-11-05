#!/usr/bin/env Rscript

# Cargar librerías
library(readr)
library(dplyr)

cat("🔍 STEP-BY-STEP VAF FILTER DEBUG\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# 1. Cargar datos procesados
cat("\n📁 Loading processed data...\n")
df <- read_tsv("outputs/processed_snv_data_vaf_filtered.tsv", show_col_types = FALSE)
cat("✅ Loaded", nrow(df), "SNVs with", ncol(df), "columns\n")

# 2. Identificar columnas
cat("\n🔍 Identifying columns...\n")
all_cols <- colnames(df)
meta_cols <- c("miRNA name", "pos:mut", "position", "mutation")
snv_cols <- all_cols[!all_cols %in% meta_cols & !grepl("\\(PM\\+1MM\\+2MM\\)", all_cols)]
total_cols <- all_cols[grepl("\\(PM\\+1MM\\+2MM\\)", all_cols)]

cat("📊 Meta columns:", length(meta_cols), "\n")
cat("📊 SNV count columns:", length(snv_cols), "\n") 
cat("📊 Total count columns:", length(total_cols), "\n")

# 3. Verificar que tenemos el mismo número de columnas SNV y totales
if (length(snv_cols) != length(total_cols)) {
  cat("❌ ERROR: Mismatch between SNV and total columns!\n")
  cat("SNV columns:", length(snv_cols), "\n")
  cat("Total columns:", length(total_cols), "\n")
  stop("Column count mismatch")
}

# 4. Mostrar algunos ejemplos de columnas
cat("\n📋 Example SNV columns (first 5):\n")
for (i in 1:min(5, length(snv_cols))) {
  cat("  ", i, ":", snv_cols[i], "\n")
}

cat("\n📋 Example total columns (first 5):\n")
for (i in 1:min(5, length(total_cols))) {
  cat("  ", i, ":", total_cols[i], "\n")
}

# 5. Verificar que las columnas están emparejadas correctamente
cat("\n🔗 Checking column pairing...\n")
sample_names <- gsub(" \\(PM\\+1MM\\+2MM\\)", "", total_cols)
snv_sample_names <- snv_cols

if (all(sample_names == snv_sample_names)) {
  cat("✅ Columns are correctly paired\n")
} else {
  cat("❌ ERROR: Columns are not correctly paired!\n")
  cat("First mismatch at position:", which(sample_names != snv_sample_names)[1], "\n")
  cat("Expected:", sample_names[1], "\n")
  cat("Got:", snv_sample_names[1], "\n")
}

# 6. Analizar el primer SNV paso a paso
cat("\n🧬 Analyzing first SNV step by step...\n")
first_snv <- df[1, ]

cat("miRNA:", first_snv[["miRNA name"]], "\n")
cat("Mutation:", first_snv[["pos:mut"]], "\n")

# 7. Calcular VAFs para las primeras 5 muestras
cat("\n📊 Calculating VAFs for first 5 samples:\n")
for (i in 1:min(5, length(snv_cols))) {
  snv_count <- first_snv[[snv_cols[i]]]
  total_count <- first_snv[[total_cols[i]]]
  vaf <- if (total_count > 0) snv_count / total_count else 0
  
  cat("Sample", i, ":", snv_cols[i], "\n")
  cat("  SNV count:", snv_count, "\n")
  cat("  Total count:", total_count, "\n")
  cat("  VAF:", round(vaf, 4), "\n")
  cat("  Overrepresented (VAF > 0.5):", vaf > 0.5, "\n\n")
}

# 8. Resumen de VAFs para el primer SNV
cat("📈 VAF summary for first SNV:\n")
vafs <- numeric(length(snv_cols))
for (i in seq_along(snv_cols)) {
  snv_count <- first_snv[[snv_cols[i]]]
  total_count <- first_snv[[total_cols[i]]]
  vafs[i] <- if (total_count > 0) snv_count / total_count else 0
}

cat("  Min VAF:", round(min(vafs), 4), "\n")
cat("  Max VAF:", round(max(vafs), 4), "\n")
cat("  Mean VAF:", round(mean(vafs), 4), "\n")
cat("  Samples with VAF > 0.5:", sum(vafs > 0.5), "\n")
cat("  Samples with VAF > 0:", sum(vafs > 0), "\n")

cat("\n✅ Debug complete!\n")










