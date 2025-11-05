#!/usr/bin/env Rscript

# Cargar librerías
library(readr)
library(dplyr)

cat("🔍 FINDING OVERREPRESENTED SNV EXAMPLE\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# Cargar datos procesados
df <- read_tsv("outputs/processed_snv_data_vaf_filtered.tsv", show_col_types = FALSE)

# Identificar columnas
all_cols <- colnames(df)
meta_cols <- c("miRNA name", "pos:mut", "position", "mutation")
snv_cols <- all_cols[!all_cols %in% meta_cols & !grepl("\\(PM\\+1MM\\+2MM\\)", all_cols)]
total_cols <- all_cols[grepl("\\(PM\\+1MM\\+2MM\\)", all_cols)]

cat("📊 Looking for SNVs with overrepresented samples (VAF > 0.5)...\n")

# Buscar SNVs que no sean PM
non_pm_snvs <- df[df$`pos:mut` != "PM", ]

# Función para calcular VAFs de un SNV
calculate_vafs <- function(snv_row) {
  vafs <- numeric(length(snv_cols))
  for (i in seq_along(snv_cols)) {
    snv_count <- snv_row[[snv_cols[i]]]
    total_count <- snv_row[[total_cols[i]]]
    vafs[i] <- if (total_count > 0) snv_count / total_count else 0
  }
  return(vafs)
}

# Buscar SNVs con muestras sobrerepresentadas
overrepresented_found <- FALSE
example_idx <- 0

for (i in 1:min(100, nrow(non_pm_snvs))) {  # Revisar los primeros 100
  vafs <- calculate_vafs(non_pm_snvs[i, ])
  overrepresented_count <- sum(vafs > 0.5)
  
  if (overrepresented_count > 0) {
    overrepresented_found <- TRUE
    example_idx <- i
    break
  }
}

if (overrepresented_found) {
  example_snv <- non_pm_snvs[example_idx, ]
  vafs <- calculate_vafs(example_snv)
  
  cat("\n🧬 Found overrepresented SNV example:\n")
  cat("miRNA:", example_snv[["miRNA name"]], "\n")
  cat("Mutation:", example_snv[["pos:mut"]], "\n")
  
  cat("\n📈 VAF analysis:\n")
  cat("  Min VAF:", round(min(vafs), 4), "\n")
  cat("  Max VAF:", round(max(vafs), 4), "\n")
  cat("  Mean VAF:", round(mean(vafs), 4), "\n")
  cat("  Samples with VAF > 0.5:", sum(vafs > 0.5), "\n")
  cat("  Samples with VAF > 0:", sum(vafs > 0), "\n")
  
  # Mostrar las muestras sobrerepresentadas
  overrepresented_samples <- which(vafs > 0.5)
  cat("\n🚨 Overrepresented samples (VAF > 0.5):\n")
  for (i in overrepresented_samples) {
    cat("  Sample:", snv_cols[i], "\n")
    cat("    SNV count:", example_snv[[snv_cols[i]]], "\n")
    cat("    Total count:", example_snv[[total_cols[i]]], "\n")
    cat("    VAF:", round(vafs[i], 4), "\n\n")
  }
  
  # Mostrar las muestras válidas para imputación
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
    
    # Simular la imputación
    cat("🔄 Simulating imputation process:\n")
    imputed_vaf <- quantile(valid_vafs, 0.25, na.rm = TRUE)
    cat("  Imputation value (25th percentile):", round(imputed_vaf, 4), "\n")
    
    for (i in overrepresented_samples[1:min(2, length(overrepresented_samples))]) {
      original_count <- example_snv[[snv_cols[i]]]
      total_count <- example_snv[[total_cols[i]]]
      original_vaf <- vafs[i]
      imputed_count <- round(imputed_vaf * total_count)
      
      cat("  Sample:", snv_cols[i], "\n")
      cat("    Original count:", original_count, "→ Imputed count:", imputed_count, "\n")
      cat("    Original VAF:", round(original_vaf, 4), "→ Imputed VAF:", round(imputed_vaf, 4), "\n\n")
    }
  }
  
} else {
  cat("❌ No overrepresented SNVs found in first 100 non-PM SNVs\n")
  cat("This suggests the VAF filter is working correctly!\n")
}

cat("\n✅ Analysis complete!\n")










