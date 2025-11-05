library(dplyr)
library(tidyr)
library(stringr)

# =============================================================================
# SCRIPT DE PREPROCESAMIENTO COMPLETO
# =============================================================================

cat("=== PREPROCESAMIENTO COMPLETO DE DATOS SNV ===\n\n")

# 1. CARGAR DATOS INICIALES
# =============================================================================
cat("1. CARGANDO DATOS INICIALES\n")
cat("============================\n")

file_path <- "/Users/cesaresparza/New_Desktop/UCSD/8OG/results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt"

# Cargar datos
initial_df <- read.table(file_path, sep = "\t", header = TRUE, stringsAsFactors = FALSE)

# Renombrar columnas para consistencia
colnames(initial_df)[1] <- "miRNA_name"
colnames(initial_df)[2] <- "pos.mut"

cat("Dimensiones iniciales:", dim(initial_df), "\n")
cat("miRNAs únicos:", length(unique(initial_df$miRNA_name)), "\n")
cat("pos.mut únicos:", length(unique(initial_df$pos.mut)), "\n\n")

# Identificar columnas de conteo y total
# Las columnas de conteo son las que terminan en SRR seguido de 7 dígitos
count_cols <- grep("SRR\\d{7}$", colnames(initial_df), value = TRUE)
# Las columnas de total son las que terminan en ..PM.1MM.2MM.
total_cols <- grep("SRR\\d{7}\\.\\.PM\\.1MM\\.2MM\\.$", colnames(initial_df), value = TRUE)

# Si no encuentra las columnas con el patrón esperado, usar un patrón más general
if (length(count_cols) == 0) {
  # Buscar columnas que no sean miRNA_name, pos.mut y que no terminen en ..PM.1MM.2MM.
  all_cols <- colnames(initial_df)
  count_cols <- all_cols[!all_cols %in% c("miRNA_name", "pos.mut") & !grepl("\\.\\.PM\\.1MM\\.2MM\\.$", all_cols)]
  total_cols <- all_cols[grepl("\\.\\.PM\\.1MM\\.2MM\\.$", all_cols)]
}

cat("Columnas identificadas:\n")
cat("  - Conteo:", length(count_cols), "\n")
cat("  - Total:", length(total_cols), "\n\n")

# 2. FILTRAR MUTACIONES G>T
# =============================================================================
cat("2. FILTRANDO MUTACIONES G>T\n")
cat("============================\n")

# Filtrar solo mutaciones G>T (patrón :GT)
gt_df <- initial_df %>%
  filter(grepl(":GT", pos.mut, ignore.case = FALSE))

cat("SNVs G>T encontrados:", nrow(gt_df), "\n")
cat("miRNAs únicos con G>T:", length(unique(gt_df$miRNA_name)), "\n\n")

# 3. SPLIT DE MUTACIONES MÚLTIPLES
# =============================================================================
cat("3. SPLIT DE MUTACIONES MÚLTIPLES\n")
cat("=================================\n")

# Identificar filas con múltiples mutaciones
multiple_mutations <- gt_df %>%
  filter(grepl(",", pos.mut))

cat("Filas con múltiples mutaciones:", nrow(multiple_mutations), "\n")

# Función para hacer split de mutaciones múltiples
split_mutations <- function(df) {
  # Filas con una sola mutación
  single_mut <- df %>%
    filter(!grepl(",", pos.mut))
  
  # Filas con múltiples mutaciones - hacer split
  multi_mut <- df %>%
    filter(grepl(",", pos.mut)) %>%
    separate_rows(pos.mut, sep = ",") %>%
    mutate(pos.mut = str_trim(pos.mut))
  
  # Combinar
  rbind(single_mut, multi_mut)
}

# Aplicar split
split_df <- split_mutations(gt_df)

cat("SNVs después del split:", nrow(split_df), "\n")
cat("miRNAs únicos después del split:", length(unique(split_df$miRNA_name)), "\n\n")

# 4. COLLAPSE DE SNVs DUPLICADOS
# =============================================================================
cat("4. COLLAPSE DE SNVs DUPLICADOS\n")
cat("==============================\n")

# Función para hacer collapse
collapse_snvs <- function(df) {
  # Agrupar por miRNA_name y pos.mut
  collapsed <- df %>%
    group_by(miRNA_name, pos.mut) %>%
    summarise(
      # Sumar las cuentas de SNV
      across(all_of(count_cols), ~sum(.x, na.rm = TRUE)),
      # Tomar el primer valor de los totales (no sumar)
      across(all_of(total_cols), ~first(.x)),
      .groups = 'drop'
    )
  
  return(collapsed)
}

# Aplicar collapse
collapsed_df <- collapse_snvs(split_df)

cat("SNVs después del collapse:", nrow(collapsed_df), "\n")
cat("miRNAs únicos después del collapse:", length(unique(collapsed_df$miRNA_name)), "\n\n")

# 5. CALCULAR VAFs Y CONVERTIR VAFs > 0.5 A NaN
# =============================================================================
cat("5. CALCULANDO VAFs Y CONVIRTIENDO VAFs > 0.5 A NaN\n")
cat("==================================================\n")

# Función para calcular VAFs
calculate_vafs <- function(df) {
  # Crear matriz de VAFs
  vaf_matrix <- matrix(NA, nrow = nrow(df), ncol = length(count_cols))
  colnames(vaf_matrix) <- count_cols
  
  # Calcular VAF para cada muestra
  for (i in seq_along(count_cols)) {
    count_col <- count_cols[i]
    total_col <- total_cols[i]
    
    # VAF = count / total
    vaf_values <- df[[count_col]] / df[[total_col]]
    
    # Convertir VAFs > 0.5 a NaN
    vaf_values[vaf_values > 0.5] <- NaN
    
    vaf_matrix[, i] <- vaf_values
  }
  
  # Crear dataframe con VAFs
  vaf_df <- data.frame(
    miRNA_name = df$miRNA_name,
    pos.mut = df$pos.mut,
    vaf_matrix,
    stringsAsFactors = FALSE
  )
  
  return(vaf_df)
}

# Calcular VAFs
vaf_df <- calculate_vafs(collapsed_df)

# Contar VAFs convertidos a NaN
total_vafs <- nrow(vaf_df) * length(count_cols)
nan_vafs <- sum(is.na(vaf_df[, count_cols]))

cat("Total de VAFs calculados:", total_vafs, "\n")
cat("VAFs convertidos a NaN (>0.5):", nan_vafs, "\n")
cat("Porcentaje de VAFs > 0.5:", round(nan_vafs/total_vafs * 100, 2), "%\n\n")

# 6. FILTROS ADICIONALES
# =============================================================================
cat("6. APLICANDO FILTROS ADICIONALES\n")
cat("=================================\n")

# Filtrar miRNAs con al menos 2 muestras por grupo
# Primero, identificar grupos por nombre de columna
identify_cohort <- function(col_name) {
  if (grepl("control", col_name, ignore.case = TRUE)) {
    return("Control")
  } else if (grepl("ALS", col_name, ignore.case = TRUE)) {
    return("ALS")
  } else {
    return("Unknown")
  }
}

# Aplicar filtro de grupos
filtered_df <- vaf_df %>%
  rowwise() %>%
  mutate(
    # Contar muestras no-NaN por grupo
    control_samples = sum(!is.na(c_across(contains("control")))),
    als_samples = sum(!is.na(c_across(contains("ALS")))),
    # Mantener solo si tiene al menos 2 muestras en cada grupo
    keep = control_samples >= 2 & als_samples >= 2
  ) %>%
  filter(keep) %>%
  select(-control_samples, -als_samples, -keep)

cat("SNVs después del filtro de grupos:", nrow(filtered_df), "\n")
cat("miRNAs únicos después del filtro:", length(unique(filtered_df$miRNA_name)), "\n\n")

# 7. RESUMEN FINAL
# =============================================================================
cat("7. RESUMEN FINAL DEL PREPROCESAMIENTO\n")
cat("=====================================\n")

cat("Datos iniciales:\n")
cat("  - Filas:", nrow(initial_df), "\n")
cat("  - miRNAs:", length(unique(initial_df$miRNA_name)), "\n")
cat("  - pos.mut:", length(unique(initial_df$pos.mut)), "\n\n")

cat("Después del filtro G>T:\n")
cat("  - Filas:", nrow(gt_df), "\n")
cat("  - miRNAs:", length(unique(gt_df$miRNA_name)), "\n\n")

cat("Después del split:\n")
cat("  - Filas:", nrow(split_df), "\n")
cat("  - miRNAs:", length(unique(split_df$miRNA_name)), "\n\n")

cat("Después del collapse:\n")
cat("  - Filas:", nrow(collapsed_df), "\n")
cat("  - miRNAs:", length(unique(collapsed_df$miRNA_name)), "\n\n")

cat("Después del cálculo de VAFs:\n")
cat("  - Filas:", nrow(vaf_df), "\n")
cat("  - miRNAs:", length(unique(vaf_df$miRNA_name)), "\n")
cat("  - VAFs > 0.5 convertidos a NaN:", nan_vafs, "\n\n")

cat("Datos finales (después de todos los filtros):\n")
cat("  - Filas:", nrow(filtered_df), "\n")
cat("  - miRNAs:", length(unique(filtered_df$miRNA_name)), "\n")
cat("  - Muestras:", length(count_cols), "\n\n")

# 8. GUARDAR DATOS PROCESADOS
# =============================================================================
cat("8. GUARDANDO DATOS PROCESADOS\n")
cat("=============================\n")

# Crear directorio si no existe
if (!dir.exists("processed_data")) {
  dir.create("processed_data")
}

# Guardar datos finales
write.csv(filtered_df, "processed_data/final_processed_data.csv", row.names = FALSE)
write.csv(collapsed_df, "processed_data/collapsed_data.csv", row.names = FALSE)
write.csv(vaf_df, "processed_data/vaf_data.csv", row.names = FALSE)

cat("Datos guardados en:\n")
cat("  - processed_data/final_processed_data.csv\n")
cat("  - processed_data/collapsed_data.csv\n")
cat("  - processed_data/vaf_data.csv\n\n")

cat("=== PREPROCESAMIENTO COMPLETADO ===\n")
