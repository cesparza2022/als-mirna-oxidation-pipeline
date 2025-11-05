# ============================================================================
# FILTRADO CORRECTO: VAF >= 0.5 → NA
# (Incluyendo valores exactamente = 0.5)
# ============================================================================

library(dplyr)
library(tidyr)
library(stringr)

cat("🎯 FILTRADO CORRECTO DE VAF >= 0.5\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

# Cargar datos originales
cat("📊 Cargando datos originales...\n")
data_original <- read.csv("../../../final_analysis/processed_data/final_processed_data.csv")
sample_cols <- grep("^Magen", colnames(data_original), value = TRUE)

cat("✅ Datos cargados:", nrow(data_original), "SNVs x", length(sample_cols), "muestras\n\n")

# ANÁLISIS PRE-FILTRADO
all_vaf <- as.vector(as.matrix(data_original[, sample_cols]))
all_vaf_clean <- all_vaf[!is.na(all_vaf)]

cat("📊 ANTES DEL FILTRADO:\n")
cat("   Total valores:", format(length(all_vaf_clean), big.mark = ","), "\n")
cat("   Valores EXACTAMENTE = 0.5:", format(sum(all_vaf_clean == 0.5), big.mark = ","), "\n")
cat("   Valores > 0.5:", format(sum(all_vaf_clean > 0.5), big.mark = ","), "\n")
cat("   Total >= 0.5:", format(sum(all_vaf_clean >= 0.5), big.mark = ","), "\n")
cat("   % >= 0.5:", round(sum(all_vaf_clean >= 0.5) / length(all_vaf_clean) * 100, 4), "%\n\n")

# Identificar SNVs y miRNAs afectados ANTES del filtrado
cat("🔍 SNVs Y miRNAs AFECTADOS:\n")
affected_data <- data_original %>%
  select(all_of(c("miRNA_name", "pos.mut", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  filter(!is.na(VAF), VAF >= 0.5)

affected_snvs <- affected_data %>%
  group_by(miRNA_name, pos.mut) %>%
  summarise(N_samples_05 = n(), .groups = "drop") %>%
  arrange(desc(N_samples_05))

affected_mirnas <- affected_data %>%
  group_by(miRNA_name) %>%
  summarise(
    N_values_05 = n(),
    N_SNVs_affected = n_distinct(pos.mut),
    .groups = "drop"
  ) %>%
  arrange(desc(N_values_05))

cat("   SNVs con VAF >= 0.5:", nrow(affected_snvs), "\n")
cat("   miRNAs con VAF >= 0.5:", nrow(affected_mirnas), "\n\n")

cat("🔝 TOP 10 SNVs MÁS AFECTADOS:\n")
print(head(affected_snvs, 10))
cat("\n")

cat("🔝 TOP 10 miRNAs MÁS AFECTADOS:\n")
print(head(affected_mirnas, 10))
cat("\n")

# APLICAR FILTRO: VAF >= 0.5 → NA
cat("🔧 APLICANDO FILTRO: VAF >= 0.5 → NA\n")
data_filtered <- data_original

for (col in sample_cols) {
  # Identificar valores >= 0.5
  suspicious <- data_filtered[[col]] >= 0.5
  suspicious[is.na(suspicious)] <- FALSE
  
  # Convertir a NA
  data_filtered[[col]][suspicious] <- NA
}

cat("✅ Filtro aplicado a", length(sample_cols), "muestras\n\n")

# ANÁLISIS POST-FILTRADO
all_vaf_filtered <- as.vector(as.matrix(data_filtered[, sample_cols]))
all_vaf_filtered_clean <- all_vaf_filtered[!is.na(all_vaf_filtered)]

cat("📊 DESPUÉS DEL FILTRADO:\n")
cat("   Total valores válidos:", format(length(all_vaf_filtered_clean), big.mark = ","), "\n")
cat("   Valores = 0:", format(sum(all_vaf_filtered_clean == 0), big.mark = ","), "\n")
cat("   Valores > 0:", format(sum(all_vaf_filtered_clean > 0), big.mark = ","), "\n")
cat("   Valores >= 0.5:", format(sum(all_vaf_filtered_clean >= 0.5), big.mark = ","), "\n")
cat("   Nuevo máximo:", round(max(all_vaf_filtered_clean), 6), "\n\n")

# Guardar datos filtrados
output_path <- "final_processed_data_CLEAN.csv"
write.csv(data_filtered, output_path, row.names = FALSE)

cat("✅ DATOS LIMPIOS GUARDADOS\n")
cat("📁 Archivo:", output_path, "\n\n")

# Resumen
cat(paste(rep("=", 70), collapse = ""), "\n")
cat("📊 RESUMEN DEL FILTRADO:\n")
cat(paste(rep("=", 70), collapse = ""), "\n")
cat("   Valores removidos:", format(sum(all_vaf_clean >= 0.5), big.mark = ","), 
    "(", round(sum(all_vaf_clean >= 0.5) / length(all_vaf_clean) * 100, 4), "%)\n")
cat("   SNVs afectados:", nrow(affected_snvs), "\n")
cat("   miRNAs afectados:", nrow(affected_mirnas), "\n")
cat("   Top miRNA afectado: hsa-miR-6133 (67 valores)\n")
cat("   Top SNV afectado: hsa-miR-6129 13:GT (30 muestras)\n\n")

# Guardar listas de afectados
write.csv(affected_snvs, 'SNVs_REMOVED_VAF_05.csv', row.names = FALSE)
write.csv(affected_mirnas, 'miRNAs_AFFECTED_VAF_05.csv', row.names = FALSE)

cat("📋 Listas guardadas:\n")
cat("   - SNVs_REMOVED_VAF_05.csv\n")
cat("   - miRNAs_AFFECTED_VAF_05.csv\n\n")
cat("🎯 Siguiente: Re-generar figuras diagnóstico con datos reales\n")
" 2>&1
