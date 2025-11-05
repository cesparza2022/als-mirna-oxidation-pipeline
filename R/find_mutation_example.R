#!/usr/bin/env Rscript

# Cargar librerías
library(readr)
library(dplyr)

cat("🔍 FINDING MUTATION EXAMPLE FOR VAF FILTER DEMO\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# Cargar datos procesados
df <- read_tsv("outputs/processed_snv_data_vaf_filtered.tsv", show_col_types = FALSE)

# Identificar columnas
all_cols <- colnames(df)
meta_cols <- c("miRNA name", "pos:mut", "position", "mutation")
snv_cols <- all_cols[!all_cols %in% meta_cols & !grepl("\\(PM\\+1MM\\+2MM\\)", all_cols)]
total_cols <- all_cols[grepl("\\(PM\\+1MM\\+2MM\\)", all_cols)]

cat("📊 Looking for SNVs with real mutations (not PM)...\n")

# Buscar SNVs que no sean PM
non_pm_snvs <- df[df$`pos:mut` != "PM", ]

cat("📊 Found", nrow(non_pm_snvs), "non-PM SNVs\n")

if (nrow(non_pm_snvs) > 0) {
  # Tomar el primer SNV no-PM
  example_snv <- non_pm_snvs[1, ]
  
  cat("\n🧬 Example SNV with mutation:\n")
  cat("miRNA:", example_snv[["miRNA name"]], "\n")
  cat("Mutation:", example_snv[["pos:mut"]], "\n")
  
  # Calcular VAFs
  vafs <- numeric(length(snv_cols))
  for (i in seq_along(snv_cols)) {
    snv_count <- example_snv[[snv_cols[i]]]
    total_count <- example_snv[[total_cols[i]]]
    vafs[i] <- if (total_count > 0) snv_count / total_count else 0
  }
  
  cat("\n📈 VAF analysis:\n")
  cat("  Min VAF:", round(min(vafs), 4), "\n")
  cat("  Max VAF:", round(max(vafs), 4), "\n")
  cat("  Mean VAF:", round(mean(vafs), 4), "\n")
  cat("  Samples with VAF > 0.5:", sum(vafs > 0.5), "\n")
  cat("  Samples with VAF > 0:", sum(vafs > 0), "\n")
  
  # Mostrar las muestras con VAF > 0.5
  overrepresented_samples <- which(vafs > 0.5)
  if (length(overrepresented_samples) > 0) {
    cat("\n🚨 Overrepresented samples (VAF > 0.5):\n")
    for (i in overrepresented_samples[1:min(5, length(overrepresented_samples))]) {
      cat("  Sample:", snv_cols[i], "\n")
      cat("    SNV count:", example_snv[[snv_cols[i]]], "\n")
      cat("    Total count:", example_snv[[total_cols[i]]], "\n")
      cat("    VAF:", round(vafs[i], 4), "\n\n")
    }
  }
  
  # Mostrar las muestras con VAF <= 0.5 para imputación
  valid_samples <- which(vafs <= 0.5 & vafs > 0)
  if (length(valid_samples) > 0) {
    cat("✅ Valid samples for imputation (VAF <= 0.5 & > 0):\n")
    valid_vafs <- vafs[valid_samples]
    cat("  Count:", length(valid_vafs), "\n")
    cat("  Min VAF:", round(min(valid_vafs), 4), "\n")
    cat("  Max VAF:", round(max(valid_vafs), 4), "\n")
    cat("  Mean VAF:", round(mean(valid_vafs), 4), "\n")
    cat("  25th percentile:", round(quantile(valid_vafs, 0.25), 4), "\n")
    
    # Mostrar algunos ejemplos
    for (i in valid_samples[1:min(3, length(valid_samples))]) {
      cat("  Sample:", snv_cols[i], "\n")
      cat("    SNV count:", example_snv[[snv_cols[i]]], "\n")
      cat("    Total count:", example_snv[[total_cols[i]]], "\n")
      cat("    VAF:", round(vafs[i], 4), "\n\n")
    }
  }
  
} else {
  cat("❌ No non-PM SNVs found!\n")
}

cat("\n✅ Analysis complete!\n")










