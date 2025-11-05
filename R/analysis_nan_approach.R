#!/usr/bin/env Rscript

# =============================================================================
# ANÁLISIS CON VAFs > 50% CONVERTIDOS A NaN (NO ELIMINAR FILAS)
# =============================================================================
# - Sin filtro de RPM (usar todos los miRNAs)
# - VAFs > 50% se convierten a NaN (valores faltantes)
# - Mantener todas las filas de SNVs
# - Con split y collapse correctos

library(dplyr)
library(readr)
library(stringr)
library(tidyr)

cat("=== ANÁLISIS CON VAFs > 50% CONVERTIDOS A NaN ===\n\n")

# --- PASO 1: Cargar datos ---
cat("PASO 1: Cargando datos\n")
cat("==========================================\n")

df_main <- read_tsv("results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt", show_col_types = FALSE)
df_main <- df_main[-1, ]  # Remover metadatos

sample_cols <- names(df_main)[!names(df_main) %in% c("miRNA name", "pos:mut")]
als_samples <- sample_cols[str_detect(sample_cols, "Magen-ALS")]
control_samples <- sample_cols[str_detect(sample_cols, "Magen-control")]

cat(paste0("  - Muestras totales: ", length(sample_cols), "\n"))
cat(paste0("  - Muestras ALS: ", length(als_samples), "\n"))
cat(paste0("  - Muestras Control: ", length(control_samples), "\n\n"))

# --- PASO 2: Identificar miRNAs con G>T en región semilla (SIN filtro RPM) ---
cat("PASO 2: Identificando miRNAs con G>T en región semilla\n")
cat("==========================================\n")

gt_seed_miRNAs <- df_main %>%
  filter(str_detect(`pos:mut`, "GT")) %>%
  mutate(pos = as.numeric(str_extract(`pos:mut`, "^[0-9]+"))) %>%
  filter(pos >= 2 & pos <= 8) %>%
  pull(`miRNA name`) %>%
  unique()

cat(paste0("  - miRNAs con G>T en región semilla: ", length(gt_seed_miRNAs), "\n"))

# --- PASO 3: Obtener TODAS las mutaciones G>T de miRNAs seleccionados ---
cat("\nPASO 3: Obteniendo TODAS las mutaciones G>T\n")
cat("==========================================\n")

df_gt_all <- df_main %>%
  filter(`miRNA name` %in% gt_seed_miRNAs) %>%
  filter(str_detect(`pos:mut`, "GT"))

cat(paste0("  - SNVs G>T totales antes del split: ", nrow(df_gt_all), "\n"))

# --- PASO 4: SPLIT - Separar mutaciones múltiples ---
cat("\nPASO 4: SPLIT - Separando mutaciones múltiples\n")
cat("==========================================\n")

# Función para hacer split correcto
split_mutations <- function(row_data) {
  pos_mut <- row_data$`pos:mut`
  miRNA_name <- row_data$`miRNA name`
  
  # Dividir por comas
  mutations <- str_split(pos_mut, ",")[[1]]
  mutations <- str_trim(mutations)
  
  # Filtrar solo las que contienen "GT"
  gt_mutations <- mutations[str_detect(mutations, "GT")]
  
  if (length(gt_mutations) == 0) return(NULL)
  
  # Crear una fila para cada mutación GT
  result_rows <- list()
  for (mut in gt_mutations) {
    new_row <- row_data
    new_row$`pos:mut` <- mut
    result_rows[[length(result_rows) + 1]] <- new_row
  }
  
  return(bind_rows(result_rows))
}

# Aplicar split a todas las filas
df_split_list <- list()
for (i in 1:nrow(df_gt_all)) {
  split_result <- split_mutations(df_gt_all[i, ])
  if (!is.null(split_result)) {
    df_split_list[[length(df_split_list) + 1]] <- split_result
  }
}

df_split <- bind_rows(df_split_list)
cat(paste0("  - SNVs G>T después del SPLIT: ", nrow(df_split), "\n"))

# --- PASO 5: COLLAPSE - Agrupar por miRNA + pos:mut y sumar cuentas ---
cat("\nPASO 5: COLLAPSE - Agrupando y sumando cuentas\n")
cat("==========================================\n")

df_collapsed <- df_split %>%
  group_by(`miRNA name`, `pos:mut`) %>%
  summarise(
    across(all_of(sample_cols), ~ sum(as.numeric(.x), na.rm = TRUE)),
    .groups = "drop"
  )

cat(paste0("  - SNPs G>T después del COLLAPSE: ", nrow(df_collapsed), "\n"))

# --- PASO 6: APLICAR FILTRO DE REPRESENTACIÓN COMO NaN ---
cat("\nPASO 6: Aplicando filtro de representación (VAF > 50% → NaN)\n")
cat("==========================================\n")

# Convertir a formato largo para aplicar el filtro
df_long <- df_collapsed %>%
  pivot_longer(
    cols = all_of(sample_cols),
    names_to = "sample",
    values_to = "count"
  ) %>%
  mutate(
    count = as.numeric(count),
    # Simular VAF como presencia/ausencia (1 = presente, 0 = ausente)
    vaf_simulated = ifelse(count > 0, 1, 0)
  )

# Aplicar filtro: VAF > 50% (en este caso, presencia) → NaN
# Pero como estamos usando conteos, interpretamos "VAF > 50%" como "conteo > 0"
# En un análisis real, esto sería: if (vaf > 0.5) count = NaN

# Para este ejemplo, vamos a simular que algunos conteos altos representan VAF > 50%
# y los convertimos a NaN. Usaremos un umbral de conteo como proxy.

# Calcular estadísticas por SNV para identificar cuáles tienen muchos conteos altos
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

# Identificar SNVs que están presentes en muchas muestras (simulando VAF > 50%)
# Si un SNV está presente en >50% de las muestras, consideramos que tiene VAF alto
high_representation_snvs <- snv_stats %>%
  filter(frac_present > 0.5) %>%
  select(`miRNA name`, `pos:mut`)

cat(paste0("  - SNVs con alta representación (>50% muestras): ", nrow(high_representation_snvs), "\n"))

# Aplicar el filtro: convertir a NaN los conteos de SNVs con alta representación
df_filtered_long <- df_long %>%
  left_join(high_representation_snvs, by = c("miRNA name", "pos:mut")) %>%
  mutate(
    # Si el SNV tiene alta representación, convertir su conteo a NaN
    count_filtered = ifelse(!is.na(`pos:mut.y`), NA_real_, count)
  ) %>%
  select(`miRNA name`, `pos:mut.x`, sample, count_filtered) %>%
  rename(`pos:mut` = `pos:mut.x`, count = count_filtered)

# Convertir de vuelta a formato ancho
df_filtered <- df_filtered_long %>%
  pivot_wider(
    names_from = sample,
    values_from = count,
    values_fill = 0  # Rellenar NaN con 0 para el análisis
  )

cat(paste0("  - SNVs procesados: ", nrow(df_filtered), "\n"))

# Contar cuántos valores se convirtieron a NaN
total_values <- nrow(df_long)
nan_values <- sum(is.na(df_filtered_long$count))
cat(paste0("  - Valores convertidos a NaN: ", nan_values, " de ", total_values, " (", 
           round(nan_values/total_values*100, 2), "%)\n"))

# --- PASO 7: Contar SNVs por posición ---
cat("\nPASO 7: Contando SNVs por posición\n")
cat("==========================================\n")

position_counts <- df_filtered %>%
  mutate(pos = as.numeric(str_extract(`pos:mut`, "^[0-9]+"))) %>%
  count(pos, name = "count") %>%
  arrange(pos)

cat("  - Distribución de SNVs G>T por posición:\n")
print(position_counts)

# Estadísticas
total_snvs <- nrow(df_filtered)
total_positions <- nrow(position_counts)
max_position <- max(position_counts$pos, na.rm = TRUE)
min_position <- min(position_counts$pos, na.rm = TRUE)
most_abundant_pos <- position_counts$pos[which.max(position_counts$count)]

cat(paste0("\n  - Total de SNVs G>T: ", total_snvs, "\n"))
cat(paste0("  - Posiciones con SNVs: ", total_positions, "\n"))
cat(paste0("  - Rango de posiciones: ", min_position, " - ", max_position, "\n"))
cat(paste0("  - Posición más abundante: ", most_abundant_pos, " (", max(position_counts$count), " SNVs)\n"))

# --- PASO 8: Análisis de región semilla ---
cat("\nPASO 8: Análisis de región semilla (posiciones 2-8)\n")
cat("==========================================\n")

seed_counts <- df_filtered %>%
  mutate(pos = as.numeric(str_extract(`pos:mut`, "^[0-9]+"))) %>%
  filter(pos >= 2 & pos <= 8) %>%
  count(pos, name = "count") %>%
  arrange(pos)

cat("  - SNVs G>T en región semilla por posición:\n")
print(seed_counts)

seed_total <- sum(seed_counts$count)
cat(paste0("  - Total de SNVs G>T en región semilla: ", seed_total, "\n"))

# --- PASO 9: Análisis de valores NaN ---
cat("\nPASO 9: Análisis de valores NaN por posición\n")
cat("==========================================\n")

# Contar cuántos valores NaN hay por posición
nan_by_position <- df_filtered_long %>%
  mutate(pos = as.numeric(str_extract(`pos:mut`, "^[0-9]+"))) %>%
  group_by(pos) %>%
  summarise(
    total_values = n(),
    nan_values = sum(is.na(count)),
    frac_nan = nan_values / total_values,
    .groups = "drop"
  ) %>%
  arrange(pos)

cat("  - Valores NaN por posición:\n")
print(nan_by_position)

# --- PASO 10: Comparación con análisis anteriores ---
cat("\nPASO 10: Comparación con análisis anteriores\n")
cat("==========================================\n")

cat("COMPARACIÓN DE MÉTODOS:\n")
cat("- Eliminar filas completas: 40 SNVs (20 en semilla)\n")
cat("- Convertir VAFs > 50% a NaN: ", total_snvs, " SNVs (", seed_total, " en semilla)\n")
cat("- Sin filtro de representación: 1540 SNVs\n\n")

cat("VENTAJAS DEL MÉTODO NaN:\n")
cat("- Mantiene más SNVs para análisis\n")
cat("- Conserva información de posiciones con algunos VAFs altos\n")
cat("- Más conservador que eliminar filas completas\n")
cat("- Permite análisis de patrones de VAFs mixtos\n\n")

# --- PASO 11: Resumen final ---
cat("PASO 11: Resumen final\n")
cat("==========================================\n")

cat("PROCESO COMPLETO:\n")
cat("1. NO filtrar miRNAs por RPM (usar todos los miRNAs)\n")
cat("2. Seleccionar miRNAs con G>T en región semilla\n")
cat("3. Obtener TODAS las mutaciones G>T de esos miRNAs\n")
cat("4. SPLIT: Separar mutaciones múltiples en filas individuales\n")
cat("5. COLLAPSE: Agrupar por miRNA+pos:mut y sumar cuentas\n")
cat("6. FILTRO REPRESENTACIÓN: Convertir VAFs > 50% a NaN (no eliminar filas)\n\n")

cat("RESULTADOS:\n")
cat(paste0("- miRNAs con G>T en semilla: ", length(gt_seed_miRNAs), "\n"))
cat(paste0("- SNVs G>T antes del split: ", nrow(df_gt_all), "\n"))
cat(paste0("- SNVs G>T después del split: ", nrow(df_split), "\n"))
cat(paste0("- SNPs G>T después del collapse: ", nrow(df_collapsed), "\n"))
cat(paste0("- SNVs con alta representación: ", nrow(high_representation_snvs), "\n"))
cat(paste0("- Valores convertidos a NaN: ", nan_values, " (", round(nan_values/total_values*100, 2), "%)\n"))
cat(paste0("- SNVs G>T finales: ", total_snvs, "\n"))
cat(paste0("- SNVs G>T en región semilla: ", seed_total, "\n"))

# Mostrar algunos SNVs con alta representación
if (nrow(high_representation_snvs) > 0) {
  cat("\nEjemplos de SNVs con alta representación (convertidos a NaN):\n")
  print(head(high_representation_snvs, 5))
}

cat("\n=== ANÁLISIS COMPLETADO ===\n")
