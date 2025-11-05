#!/usr/bin/env Rscript

# =============================================================================
# PASO 1: ANÁLISIS DE FILTRO DE REPRESENTACIÓN PARA TODOS LOS SNVs
# =============================================================================
# - Aplicar split y collapse a TODOS los SNVs (no solo G>T)
# - Aplicar filtro de representación (VAF > 50% → NaN)
# - Calcular porcentajes de valores convertidos a NaN

library(dplyr)
library(readr)
library(stringr)
library(tidyr)

cat("=== PASO 1: ANÁLISIS DE FILTRO DE REPRESENTACIÓN PARA TODOS LOS SNVs ===\n\n")

# --- PASO 1.1: Cargar datos ---
cat("PASO 1.1: Cargando datos\n")
cat("==========================================\n")

df_main <- read_tsv("results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt", show_col_types = FALSE)
df_main <- df_main[-1, ]  # Remover metadatos

sample_cols <- names(df_main)[!names(df_main) %in% c("miRNA name", "pos:mut")]
als_samples <- sample_cols[str_detect(sample_cols, "Magen-ALS")]
control_samples <- sample_cols[str_detect(sample_cols, "Magen-control")]

cat(paste0("  - Muestras totales: ", length(sample_cols), "\n"))
cat(paste0("  - Muestras ALS: ", length(als_samples), "\n"))
cat(paste0("  - Muestras Control: ", length(control_samples), "\n"))
cat(paste0("  - Filas originales: ", nrow(df_main), "\n\n"))

# --- PASO 1.2: SPLIT - Separar mutaciones múltiples ---
cat("PASO 1.2: SPLIT - Separando mutaciones múltiples\n")
cat("==========================================\n")

# Función para hacer split correcto
split_mutations <- function(row_data) {
  pos_mut <- row_data$`pos:mut`
  miRNA_name <- row_data$`miRNA name`
  
  # Dividir por comas
  mutations <- str_split(pos_mut, ",")[[1]]
  mutations <- str_trim(mutations)
  
  if (length(mutations) == 1) {
    # Solo una mutación, devolver la fila original
    return(row_data)
  } else {
    # Múltiples mutaciones, crear una fila para cada una
    result_rows <- list()
    for (mut in mutations) {
      new_row <- row_data
      new_row$`pos:mut` <- mut
      result_rows[[length(result_rows) + 1]] <- new_row
    }
    return(bind_rows(result_rows))
  }
}

# Aplicar split a todas las filas
df_split_list <- list()
for (i in 1:nrow(df_main)) {
  split_result <- split_mutations(df_main[i, ])
  df_split_list[[length(df_split_list) + 1]] <- split_result
}

df_split <- bind_rows(df_split_list)
cat(paste0("  - Filas después del SPLIT: ", nrow(df_split), "\n"))
cat(paste0("  - Incremento: +", nrow(df_split) - nrow(df_main), " filas\n\n"))

# --- PASO 1.3: COLLAPSE - Agrupar por miRNA + pos:mut y sumar cuentas ---
cat("PASO 1.3: COLLAPSE - Agrupando y sumando cuentas\n")
cat("==========================================\n")

df_collapsed <- df_split %>%
  group_by(`miRNA name`, `pos:mut`) %>%
  summarise(
    across(all_of(sample_cols), ~ sum(as.numeric(.x), na.rm = TRUE)),
    .groups = "drop"
  )

cat(paste0("  - Filas después del COLLAPSE: ", nrow(df_collapsed), "\n"))
cat(paste0("  - Reducción: -", nrow(df_split) - nrow(df_collapsed), " filas\n\n"))

# --- PASO 1.4: APLICAR FILTRO DE REPRESENTACIÓN COMO NaN ---
cat("PASO 1.4: Aplicando filtro de representación (VAF > 50% → NaN)\n")
cat("==========================================\n")

# Convertir a formato largo
df_long <- df_collapsed %>%
  pivot_longer(
    cols = all_of(sample_cols),
    names_to = "sample",
    values_to = "count"
  ) %>%
  mutate(count = as.numeric(count))

# Calcular estadísticas por SNV
snv_stats <- df_long %>%
  group_by(`miRNA name`, `pos:mut`) %>%
  summarise(
    total_samples = n(),
    samples_with_count = sum(count > 0, na.rm = TRUE),
    frac_present = samples_with_count / total_samples,
    max_count = max(count, na.rm = TRUE),
    mean_count = mean(count, na.rm = TRUE),
    .groups = "drop"
  )

# Identificar SNVs con alta representación (>50% de muestras)
high_rep_snvs <- snv_stats %>%
  filter(frac_present > 0.5) %>%
  select(`miRNA name`, `pos:mut`)

cat(paste0("  - SNVs con alta representación (>50% muestras): ", nrow(high_rep_snvs), "\n"))

# Crear un identificador único para cada SNV
df_long$snv_id <- paste(df_long$`miRNA name`, df_long$`pos:mut`, sep = "_")
high_rep_snvs$snv_id <- paste(high_rep_snvs$`miRNA name`, high_rep_snvs$`pos:mut`, sep = "_")

# Aplicar filtro: convertir a NaN los conteos de SNVs con alta representación
df_filtered_long <- df_long %>%
  mutate(
    count_filtered = ifelse(snv_id %in% high_rep_snvs$snv_id, NA_real_, count)
  )

# Contar valores NaN
total_values <- nrow(df_filtered_long)
nan_values <- sum(is.na(df_filtered_long$count_filtered))
cat(paste0("  - Valores convertidos a NaN: ", nan_values, " de ", total_values, " (", 
           round(nan_values/total_values*100, 2), "%)\n"))

# --- PASO 1.5: Análisis por tipo de mutación ---
cat("\nPASO 1.5: Análisis por tipo de mutación\n")
cat("==========================================\n")

# Extraer tipos de mutación
df_mutation_types <- df_collapsed %>%
  mutate(
    mutation_type = str_extract(`pos:mut`, "[A-Z]{2}$"),
    position = as.numeric(str_extract(`pos:mut`, "^[0-9]+"))
  ) %>%
  filter(!is.na(mutation_type))  # Excluir "PM"

# Contar por tipo de mutación
mutation_counts <- df_mutation_types %>%
  count(mutation_type, name = "total_snvs") %>%
  arrange(desc(total_snvs))

cat("  - Distribución por tipo de mutación:\n")
print(mutation_counts)

# Análisis de representación por tipo de mutación
rep_by_mutation <- df_mutation_types %>%
  left_join(snv_stats, by = c("miRNA name", "pos:mut")) %>%
  group_by(mutation_type) %>%
  summarise(
    total_snvs = n(),
    high_rep_snvs = sum(frac_present > 0.5, na.rm = TRUE),
    frac_high_rep = high_rep_snvs / total_snvs,
    .groups = "drop"
  ) %>%
  arrange(desc(frac_high_rep))

cat("\n  - Representación alta por tipo de mutación:\n")
print(rep_by_mutation)

# --- PASO 1.6: Análisis por posición ---
cat("\nPASO 1.6: Análisis por posición\n")
cat("==========================================\n")

# Análisis de representación por posición
rep_by_position <- df_mutation_types %>%
  left_join(snv_stats, by = c("miRNA name", "pos:mut")) %>%
  group_by(position) %>%
  summarise(
    total_snvs = n(),
    high_rep_snvs = sum(frac_present > 0.5, na.rm = TRUE),
    frac_high_rep = high_rep_snvs / total_snvs,
    .groups = "drop"
  ) %>%
  arrange(position)

cat("  - Representación alta por posición:\n")
print(rep_by_position)

# --- PASO 1.7: Resumen final ---
cat("\nPASO 1.7: Resumen final\n")
cat("==========================================\n")

cat("RESULTADOS DEL FILTRO DE REPRESENTACIÓN:\n")
cat(paste0("- Filas originales: ", nrow(df_main), "\n"))
cat(paste0("- Filas después del SPLIT: ", nrow(df_split), "\n"))
cat(paste0("- Filas después del COLLAPSE: ", nrow(df_collapsed), "\n"))
cat(paste0("- SNVs con alta representación: ", nrow(high_rep_snvs), "\n"))
cat(paste0("- Valores convertidos a NaN: ", nan_values, " (", round(nan_values/total_values*100, 2), "%)\n"))
cat(paste0("- Tipos de mutación únicos: ", nrow(mutation_counts), "\n"))
cat(paste0("- Posiciones con SNVs: ", nrow(rep_by_position), "\n\n"))

cat("TOP 5 TIPOS DE MUTACIÓN MÁS AFECTADOS POR EL FILTRO:\n")
print(head(rep_by_mutation, 5))

cat("\nTOP 5 POSICIONES MÁS AFECTADAS POR EL FILTRO:\n")
print(head(rep_by_position %>% arrange(desc(frac_high_rep)), 5))

cat("\n=== PASO 1 COMPLETADO ===\n")










