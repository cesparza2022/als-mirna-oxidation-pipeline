library(dplyr)
library(tidyr)
library(stringr)

# =============================================================================
# RESUMEN DETALLADO DE FILTROS APLICADOS
# =============================================================================

cat("=== RESUMEN DETALLADO DE FILTROS APLICADOS ===\n\n")

# 1. CARGAR DATOS ORIGINALES
# =============================================================================
cat("1. DATOS ORIGINALES\n")
cat("==================\n")

# Cargar datos originales
original_data <- read.table("/Users/cesaresparza/New_Desktop/UCSD/8OG/results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt", 
                           sep = "\t", header = TRUE, stringsAsFactors = FALSE)

# Renombrar primera columna
if (colnames(original_data)[1] != "miRNA_name") {
  colnames(original_data)[1] <- "miRNA_name"
}

# Identificar columnas
count_cols <- grep("SRR\\d{7}$", colnames(original_data), value = TRUE)
total_cols <- grep("SRR\\d{7}\\.\\.PM\\.1MM\\.2MM\\.$", colnames(original_data), value = TRUE)

if (length(count_cols) == 0) {
  all_cols <- colnames(original_data)
  count_cols <- all_cols[!all_cols %in% c("miRNA_name", "pos.mut") & !grepl("\\.\\.PM\\.1MM\\.2MM\\.$", all_cols)]
  total_cols <- all_cols[grepl("\\.\\.PM\\.1MM\\.2MM\\.$", all_cols)]
}

cat("Datos originales:\n")
cat("  - Filas (SNVs):", nrow(original_data), "\n")
cat("  - miRNAs únicos:", length(unique(original_data$miRNA_name)), "\n")
cat("  - Muestras:", length(count_cols), "\n")
cat("  - Columnas de total:", length(total_cols), "\n\n")

# 2. FILTRO 1: MUTACIONES G>T
# =============================================================================
cat("2. FILTRO 1: MUTACIONES G>T\n")
cat("===========================\n")

# Filtrar solo mutaciones G>T
gt_data <- original_data %>%
  filter(grepl(":GT", pos.mut, ignore.case = FALSE))

cat("Después del filtro G>T:\n")
cat("  - SNVs:", nrow(gt_data), "\n")
cat("  - miRNAs únicos:", length(unique(gt_data$miRNA_name)), "\n")
cat("  - SNVs eliminados:", nrow(original_data) - nrow(gt_data), "\n")
cat("  - Porcentaje eliminado:", round((nrow(original_data) - nrow(gt_data)) / nrow(original_data) * 100, 2), "%\n\n")

# 3. FILTRO 2: SPLIT DE MUTACIONES MÚLTIPLES
# =============================================================================
cat("3. FILTRO 2: SPLIT DE MUTACIONES MÚLTIPLES\n")
cat("==========================================\n")

# Función para hacer split
split_mutations <- function(df) {
  # Filas con una sola mutación
  single_mut <- df %>%
    filter(!grepl(",", pos.mut)) %>%
    mutate(pos.mut = str_trim(pos.mut))
  
  # Filas con múltiples mutaciones
  multi_mut <- df %>%
    filter(grepl(",", pos.mut)) %>%
    separate_rows(pos.mut, sep = ",") %>%
    mutate(pos.mut = str_trim(pos.mut))
  
  # Combinar
  rbind(single_mut, multi_mut)
}

# Aplicar split
split_data <- split_mutations(gt_data)

cat("Después del split:\n")
cat("  - SNVs:", nrow(split_data), "\n")
cat("  - miRNAs únicos:", length(unique(split_data$miRNA_name)), "\n")
cat("  - SNVs agregados:", nrow(split_data) - nrow(gt_data), "\n")
cat("  - Porcentaje de aumento:", round((nrow(split_data) - nrow(gt_data)) / nrow(gt_data) * 100, 2), "%\n\n")

# 4. FILTRO 3: COLLAPSE DE SNVs DUPLICADOS
# =============================================================================
cat("4. FILTRO 3: COLLAPSE DE SNVs DUPLICADOS\n")
cat("========================================\n")

# Función para hacer collapse
collapse_snvs <- function(df) {
  collapsed <- df %>%
    group_by(miRNA_name, pos.mut) %>%
    summarise(
      across(all_of(count_cols), ~sum(.x, na.rm = TRUE)),
      across(all_of(total_cols), ~first(.x)),
      .groups = 'drop'
    )
  return(collapsed)
}

# Aplicar collapse
collapsed_data <- collapse_snvs(split_data)

cat("Después del collapse:\n")
cat("  - SNVs:", nrow(collapsed_data), "\n")
cat("  - miRNAs únicos:", length(unique(collapsed_data$miRNA_name)), "\n")
cat("  - SNVs eliminados:", nrow(split_data) - nrow(collapsed_data), "\n")
cat("  - Porcentaje eliminado:", round((nrow(split_data) - nrow(collapsed_data)) / nrow(split_data) * 100, 2), "%\n\n")

# 5. FILTRO 4: CÁLCULO DE VAFs Y CONVERSIÓN VAFs > 0.5 A NaN
# =============================================================================
cat("5. FILTRO 4: CÁLCULO DE VAFs Y CONVERSIÓN VAFs > 0.5 A NaN\n")
cat("==========================================================\n")

# Función para calcular VAFs
calculate_vafs <- function(df) {
  vaf_matrix <- matrix(NA, nrow = nrow(df), ncol = length(count_cols))
  colnames(vaf_matrix) <- count_cols
  
  for (i in seq_along(count_cols)) {
    count_col <- count_cols[i]
    total_col <- total_cols[i]
    
    vaf_values <- df[[count_col]] / df[[total_col]]
    vaf_values[vaf_values > 0.5] <- NaN
    
    vaf_matrix[, i] <- vaf_values
  }
  
  vaf_df <- data.frame(
    miRNA_name = df$miRNA_name,
    pos.mut = df$pos.mut,
    vaf_matrix,
    stringsAsFactors = FALSE
  )
  
  return(vaf_df)
}

# Calcular VAFs
vaf_data <- calculate_vafs(collapsed_data)

# Contar NAs por SNV
na_analysis <- vaf_data %>%
  mutate(
    total_nas = rowSums(is.na(across(all_of(count_cols)))),
    total_samples = length(count_cols),
    pct_nas = (total_nas / total_samples) * 100
  )

cat("Después del cálculo de VAFs:\n")
cat("  - SNVs:", nrow(vaf_data), "\n")
cat("  - miRNAs únicos:", length(unique(vaf_data$miRNA_name)), "\n")
cat("  - Promedio de NAs por SNV:", round(mean(na_analysis$total_nas), 2), "\n")
cat("  - Promedio de % NAs por SNV:", round(mean(na_analysis$pct_nas), 2), "%\n")
cat("  - SNVs con 0 NAs:", sum(na_analysis$total_nas == 0), "\n")
cat("  - SNVs con >50% NAs:", sum(na_analysis$pct_nas > 50), "\n")
cat("  - SNVs con >90% NAs:", sum(na_analysis$pct_nas > 90), "\n\n")

# 6. FILTRO 5: FILTRADO ESTRICTO (10% MÍNIMO DE MUESTRAS VÁLIDAS)
# =============================================================================
cat("6. FILTRO 5: FILTRADO ESTRICTO (10% MÍNIMO DE MUESTRAS VÁLIDAS)\n")
cat("================================================================\n")

# Aplicar filtrado estricto
filtered_data <- vaf_data %>%
  mutate(
    pos = as.integer(str_extract(pos.mut, "^[0-9]+")),
    total_nas = rowSums(is.na(across(all_of(count_cols)))),
    total_samples = length(count_cols),
    valid_pct = (total_samples - total_nas) / total_samples,
    n_valid = total_samples - total_nas
  ) %>%
  filter(
    !is.na(pos) &  # No es PM
    valid_pct >= 0.1 &  # Al menos 10% de muestras válidas
    n_valid >= 2  # Al menos 2 muestras válidas
  )

cat("Después del filtrado estricto:\n")
cat("  - SNVs:", nrow(filtered_data), "\n")
cat("  - miRNAs únicos:", length(unique(filtered_data$miRNA_name)), "\n")
cat("  - SNVs eliminados:", nrow(vaf_data) - nrow(filtered_data), "\n")
cat("  - Porcentaje eliminado:", round((nrow(vaf_data) - nrow(filtered_data)) / nrow(vaf_data) * 100, 2), "%\n\n")

# 7. ANÁLISIS POR GRUPO
# =============================================================================
cat("7. ANÁLISIS POR GRUPO\n")
cat("=====================\n")

# Identificar grupos
identify_cohort <- function(col_name) {
  if (grepl("control", col_name, ignore.case = TRUE)) {
    return("Control")
  } else if (grepl("ALS", col_name, ignore.case = TRUE)) {
    return("ALS")
  } else {
    return("Unknown")
  }
}

cohorts <- sapply(count_cols, identify_cohort)
control_cols <- count_cols[cohorts == "Control"]
als_cols <- count_cols[cohorts == "ALS"]

cat("Distribución de muestras:\n")
cat("  - Control:", length(control_cols), "muestras\n")
cat("  - ALS:", length(als_cols), "muestras\n")
cat("  - Total:", length(count_cols), "muestras\n\n")

# 8. RESUMEN FINAL
# =============================================================================
cat("8. RESUMEN FINAL\n")
cat("================\n")

cat("RESUMEN DE FILTROS APLICADOS:\n")
cat("==============================\n")
cat("1. Datos originales:           ", nrow(original_data), "SNVs,", length(unique(original_data$miRNA_name)), "miRNAs\n")
cat("2. Filtro G>T:                 ", nrow(gt_data), "SNVs,", length(unique(gt_data$miRNA_name)), "miRNAs\n")
cat("3. Split mutaciones:           ", nrow(split_data), "SNVs,", length(unique(split_data$miRNA_name)), "miRNAs\n")
cat("4. Collapse duplicados:        ", nrow(collapsed_data), "SNVs,", length(unique(collapsed_data$miRNA_name)), "miRNAs\n")
cat("5. Cálculo VAFs:               ", nrow(vaf_data), "SNVs,", length(unique(vaf_data$miRNA_name)), "miRNAs\n")
cat("6. Filtrado estricto:          ", nrow(filtered_data), "SNVs,", length(unique(filtered_data$miRNA_name)), "miRNAs\n\n")

cat("PÉRDIDA DE DATOS:\n")
cat("==================\n")
cat("Total SNVs eliminados:         ", nrow(original_data) - nrow(filtered_data), "(", round((nrow(original_data) - nrow(filtered_data)) / nrow(original_data) * 100, 2), "%)\n")
cat("Total miRNAs eliminados:       ", length(unique(original_data$miRNA_name)) - length(unique(filtered_data$miRNA_name)), "(", round((length(unique(original_data$miRNA_name)) - length(unique(filtered_data$miRNA_name))) / length(unique(original_data$miRNA_name)) * 100, 2), "%)\n\n")

cat("CALIDAD DE DATOS FINALES:\n")
cat("==========================\n")
cat("SNVs con al menos 10% muestras válidas:", nrow(filtered_data), "\n")
cat("Promedio de muestras válidas por SNV:  ", round(mean(filtered_data$n_valid), 2), "\n")
cat("Promedio de % muestras válidas:        ", round(mean(filtered_data$valid_pct) * 100, 2), "%\n\n")

cat("=== RESUMEN COMPLETADO ===\n")









