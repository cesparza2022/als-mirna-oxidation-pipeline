#!/usr/bin/env Rscript

# =============================================================================
# PASO 2: ANÁLISIS ESPECÍFICO DE G>T DESPUÉS DEL FILTRO DE REPRESENTACIÓN
# =============================================================================
# - Usar los datos ya procesados del PASO 1
# - Filtrar solo mutaciones G>T
# - Analizar distribución por posición
# - Comparar con análisis anterior (sin filtro)

library(dplyr)
library(readr)
library(stringr)
library(tidyr)

cat("=== PASO 2: ANÁLISIS ESPECÍFICO DE G>T DESPUÉS DEL FILTRO ===\n\n")

# --- PASO 2.1: Cargar datos procesados del PASO 1 ---
cat("PASO 2.1: Cargando datos procesados\n")
cat("==========================================\n")

# Cargar datos originales
df_main <- read_tsv("results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt", show_col_types = FALSE)
df_main <- df_main[-1, ]  # Remover metadatos

sample_cols <- names(df_main)[!names(df_main) %in% c("miRNA name", "pos:mut")]

# Aplicar split y collapse (mismo proceso del PASO 1)
split_mutations <- function(row_data) {
  pos_mut <- row_data$`pos:mut`
  mutations <- str_split(pos_mut, ",")[[1]]
  mutations <- str_trim(mutations)
  
  if (length(mutations) == 1) {
    return(row_data)
  } else {
    result_rows <- list()
    for (mut in mutations) {
      new_row <- row_data
      new_row$`pos:mut` <- mut
      result_rows[[length(result_rows) + 1]] <- new_row
    }
    return(bind_rows(result_rows))
  }
}

# Aplicar split
df_split_list <- list()
for (i in 1:nrow(df_main)) {
  split_result <- split_mutations(df_main[i, ])
  df_split_list[[length(df_split_list) + 1]] <- split_result
}
df_split <- bind_rows(df_split_list)

# Aplicar collapse
df_collapsed <- df_split %>%
  group_by(`miRNA name`, `pos:mut`) %>%
  summarise(
    across(all_of(sample_cols), ~ sum(as.numeric(.x), na.rm = TRUE)),
    .groups = "drop"
  )

cat(paste0("  - Datos procesados: ", nrow(df_collapsed), " SNVs únicos\n"))

# --- PASO 2.2: Filtrar solo mutaciones G>T ---
cat("\nPASO 2.2: Filtrando mutaciones G>T\n")
cat("==========================================\n")

df_gt <- df_collapsed %>%
  filter(str_detect(`pos:mut`, "GT"))

cat(paste0("  - SNVs G>T totales: ", nrow(df_gt), "\n"))

# --- PASO 2.3: Aplicar filtro de representación a G>T ---
cat("\nPASO 2.3: Aplicando filtro de representación a G>T\n")
cat("==========================================\n")

# Convertir a formato largo
df_gt_long <- df_gt %>%
  pivot_longer(
    cols = all_of(sample_cols),
    names_to = "sample",
    values_to = "count"
  ) %>%
  mutate(count = as.numeric(count))

# Calcular estadísticas por SNV G>T
gt_stats <- df_gt_long %>%
  group_by(`miRNA name`, `pos:mut`) %>%
  summarise(
    total_samples = n(),
    samples_with_count = sum(count > 0, na.rm = TRUE),
    frac_present = samples_with_count / total_samples,
    max_count = max(count, na.rm = TRUE),
    mean_count = mean(count, na.rm = TRUE),
    .groups = "drop"
  )

# Identificar SNVs G>T con alta representación
gt_high_rep <- gt_stats %>%
  filter(frac_present > 0.5) %>%
  select(`miRNA name`, `pos:mut`)

cat(paste0("  - SNVs G>T con alta representación: ", nrow(gt_high_rep), "\n"))

# Aplicar filtro NaN
df_gt_long$snv_id <- paste(df_gt_long$`miRNA name`, df_gt_long$`pos:mut`, sep = "_")
gt_high_rep$snv_id <- paste(gt_high_rep$`miRNA name`, gt_high_rep$`pos:mut`, sep = "_")

df_gt_filtered_long <- df_gt_long %>%
  mutate(
    count_filtered = ifelse(snv_id %in% gt_high_rep$snv_id, NA_real_, count)
  )

# Contar valores NaN para G>T
gt_total_values <- nrow(df_gt_filtered_long)
gt_nan_values <- sum(is.na(df_gt_filtered_long$count_filtered))
cat(paste0("  - Valores G>T convertidos a NaN: ", gt_nan_values, " de ", gt_total_values, " (", 
           round(gt_nan_values/gt_total_values*100, 2), "%)\n"))

# --- PASO 2.4: Análisis por posición para G>T ---
cat("\nPASO 2.4: Análisis por posición para G>T\n")
cat("==========================================\n")

# Contar SNVs G>T por posición
gt_position_counts <- df_gt %>%
  mutate(pos = as.numeric(str_extract(`pos:mut`, "^[0-9]+"))) %>%
  count(pos, name = "count") %>%
  arrange(pos)

cat("  - Distribución de SNVs G>T por posición:\n")
print(gt_position_counts)

# Estadísticas G>T
gt_total_snvs <- nrow(df_gt)
gt_total_positions <- nrow(gt_position_counts)
gt_most_abundant_pos <- gt_position_counts$pos[which.max(gt_position_counts$count)]

cat(paste0("\n  - Total de SNVs G>T: ", gt_total_snvs, "\n"))
cat(paste0("  - Posiciones con SNVs G>T: ", gt_total_positions, "\n"))
cat(paste0("  - Posición más abundante: ", gt_most_abundant_pos, " (", max(gt_position_counts$count), " SNVs)\n"))

# --- PASO 2.5: Análisis de región semilla para G>T ---
cat("\nPASO 2.5: Análisis de región semilla para G>T\n")
cat("==========================================\n")

gt_seed_counts <- df_gt %>%
  mutate(pos = as.numeric(str_extract(`pos:mut`, "^[0-9]+"))) %>%
  filter(pos >= 2 & pos <= 8) %>%
  count(pos, name = "count") %>%
  arrange(pos)

cat("  - SNVs G>T en región semilla por posición:\n")
print(gt_seed_counts)

gt_seed_total <- sum(gt_seed_counts$count)
cat(paste0("  - Total de SNVs G>T en región semilla: ", gt_seed_total, "\n"))

# --- PASO 2.6: Análisis de representación por posición para G>T ---
cat("\nPASO 2.6: Análisis de representación por posición para G>T\n")
cat("==========================================\n")

gt_rep_by_position <- df_gt %>%
  mutate(pos = as.numeric(str_extract(`pos:mut`, "^[0-9]+"))) %>%
  left_join(gt_stats, by = c("miRNA name", "pos:mut")) %>%
  group_by(pos) %>%
  summarise(
    total_snvs = n(),
    high_rep_snvs = sum(frac_present > 0.5, na.rm = TRUE),
    frac_high_rep = high_rep_snvs / total_snvs,
    .groups = "drop"
  ) %>%
  arrange(pos)

cat("  - Representación alta por posición (G>T):\n")
print(gt_rep_by_position)

# --- PASO 2.7: Comparación con análisis anterior ---
cat("\nPASO 2.7: Comparación con análisis anterior\n")
cat("==========================================\n")

cat("COMPARACIÓN DE MÉTODOS PARA G>T:\n")
cat("- Sin filtro de representación: 2193 SNVs G>T\n")
cat("- Con filtro de representación (NaN): ", gt_total_snvs, " SNVs G>T\n")
cat("- SNVs G>T eliminados por alta representación: ", nrow(gt_high_rep), "\n")
cat("- Valores convertidos a NaN: ", gt_nan_values, " (", round(gt_nan_values/gt_total_values*100, 2), "%)\n\n")

cat("COMPARACIÓN DE REGIÓN SEMILLA:\n")
cat("- Sin filtro: 480 SNVs G>T en semilla\n")
cat("- Con filtro: ", gt_seed_total, " SNVs G>T en semilla\n\n")

# --- PASO 2.8: Resumen final ---
cat("PASO 2.8: Resumen final para G>T\n")
cat("==========================================\n")

cat("RESULTADOS DEL FILTRO DE REPRESENTACIÓN PARA G>T:\n")
cat(paste0("- SNVs G>T totales: ", gt_total_snvs, "\n"))
cat(paste0("- SNVs G>T con alta representación: ", nrow(gt_high_rep), "\n"))
cat(paste0("- Valores convertidos a NaN: ", gt_nan_values, " (", round(gt_nan_values/gt_total_values*100, 2), "%)\n"))
cat(paste0("- SNVs G>T en región semilla: ", gt_seed_total, "\n"))
cat(paste0("- Posición más abundante: ", gt_most_abundant_pos, "\n\n"))

cat("TOP 5 POSICIONES G>T MÁS AFECTADAS POR EL FILTRO:\n")
print(head(gt_rep_by_position %>% arrange(desc(frac_high_rep)), 5))

cat("\n=== PASO 2 COMPLETADO ===\n")










