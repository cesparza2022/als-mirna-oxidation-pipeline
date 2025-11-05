# Script para procesar el dataset completo con las funciones de SNV
# Aplicar separación de SNVs múltiples y suma de cuentas por miRNA

library(dplyr)
library(stringr)
library(tidyr)
library(readr)

# Source the functions
source("R/snv_processing_functions_fixed.R")

cat("🚀 PROCESANDO DATASET COMPLETO\n")
cat(paste(rep("=", 50), collapse=""), "\n")

# Load the complete dataset
cat("📁 Cargando dataset completo...\n")
df <- read.delim("/Users/cesaresparza/New_Desktop/UCSD/8OG/results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt", 
                 stringsAsFactors = FALSE)

cat("   📊 Dataset original:", nrow(df), "x", ncol(df), "\n")

# Define column ranges
snv_cols <- colnames(df)[3:417]
total_cols <- colnames(df)[418:832]

cat("   📊 Columnas SNV:", length(snv_cols), "\n")
cat("   📊 Columnas TOTAL:", length(total_cols), "\n")

# Check for multiple SNVs in the complete dataset
multiple_snvs <- df %>%
  filter(str_detect(df[["pos.mut"]], ","))

cat("\n📊 Análisis de SNVs múltiples en dataset completo:\n")
cat("   Filas con SNVs múltiples:", nrow(multiple_snvs), "\n")
cat("   Porcentaje del total:", round(nrow(multiple_snvs)/nrow(df)*100, 2), "%\n")

if (nrow(multiple_snvs) > 0) {
  cat("   Ejemplos de SNVs múltiples:\n")
  print(head(multiple_snvs[c("miRNA.name", "pos.mut")], 5))
}

# Process the complete dataset
cat("\n🔧 Procesando dataset completo...\n")
df_processed <- process_mirna_snvs(df)

cat("\n✅ Procesamiento completado!\n")
cat("   📊 Filas originales:", nrow(df), "\n")
cat("   📊 Filas procesadas:", nrow(df_processed), "\n")
cat("   📊 miRNAs únicos:", length(unique(df_processed[["miRNA.name"]])), "\n")

# Save the processed dataset
cat("\n💾 Guardando dataset procesado...\n")
write_tsv(df_processed, "outputs/processed_mirna_dataset.tsv")

# Create a summary of the processing
cat("\n📋 Creando resumen del procesamiento...\n")

# Count SNVs by type
snv_counts <- df_processed %>%
  group_by(df_processed[["pos.mut"]]) %>%
  summarise(count = n(), .groups = "drop") %>%
  arrange(desc(count))

# Count miRNAs with mutations
mirna_mutation_counts <- df_processed %>%
  group_by(df_processed[["miRNA.name"]]) %>%
  summarise(
    total_snvs = n(),
    total_counts = sum(across(all_of(snv_cols), ~ sum(.x, na.rm = TRUE))),
    .groups = "drop"
  ) %>%
  arrange(desc(total_counts))

# Save summaries
write_tsv(snv_counts, "outputs/snv_type_summary.tsv")
write_tsv(mirna_mutation_counts, "outputs/mirna_mutation_summary.tsv")

cat("   📊 Tipos de SNVs únicos:", nrow(snv_counts), "\n")
cat("   📊 miRNAs con mutaciones:", nrow(mirna_mutation_counts), "\n")

# Show top SNVs
cat("\n🔝 Top 10 SNVs más frecuentes:\n")
print(head(snv_counts, 10))

# Show top miRNAs by mutation counts
cat("\n🔝 Top 10 miRNAs por cuentas de mutación:\n")
print(head(mirna_mutation_counts, 10))

cat("\n🎉 Procesamiento del dataset completo finalizado!\n")
cat("   Archivos generados:\n")
cat("   - outputs/processed_mirna_dataset.tsv\n")
cat("   - outputs/snv_type_summary.tsv\n")
cat("   - outputs/mirna_mutation_summary.tsv\n")
