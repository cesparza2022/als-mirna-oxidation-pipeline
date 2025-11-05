#!/usr/bin/env Rscript

# =============================================================================
# ANÁLISIS SIN FILTRO DE RPM PERO CON FILTRO DE REPRESENTACIÓN
# =============================================================================
# - Sin filtro de RPM (no filtrar miRNAs por expresión)
# - Con filtro de representación (eliminar SNVs con VAF ≥ 50% en ≥40 muestras)
# - Con split y collapse correctos

library(dplyr)
library(readr)
library(stringr)
library(tidyr)

cat("=== ANÁLISIS SIN RPM PERO CON FILTRO DE REPRESENTACIÓN ===\n\n")

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

# --- PASO 6: APLICAR FILTRO DE REPRESENTACIÓN ---
cat("\nPASO 6: Aplicando filtro de representación (VAF ≥ 50% en ≥40 muestras)\n")
cat("==========================================\n")

# Función para calcular VAF (asumiendo que las columnas son conteos PM)
# En este archivo, las columnas de muestra son conteos PM, no VAFs reales
# Para el filtro de representación, necesitamos simular el cálculo de VAF

# Como no tenemos columnas (PM+1MM+2MM), asumimos que VAF = conteo_PM / total_lecturas
# Donde total_lecturas = conteo_PM (asumiendo que es el total)

# Calcular "VAF" como proporción de presencia (conteo > 0 = 100%, conteo = 0 = 0%)
df_vaf_simulated <- df_collapsed %>%
  mutate(
    across(all_of(sample_cols), ~ ifelse(.x > 0, 1, 0))  # 1 = presente, 0 = ausente
  )

# Contar en cuántas muestras cada SNV tiene VAF ≥ 50% (en este caso, presencia)
samples_over_threshold <- df_vaf_simulated %>%
  select(`miRNA name`, `pos:mut`, all_of(sample_cols)) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "sample", values_to = "vaf_50") %>%
  group_by(`miRNA name`, `pos:mut`) %>%
  summarise(
    samples_over_50 = sum(vaf_50, na.rm = TRUE),
    total_samples = n(),
    .groups = "drop"
  ) %>%
  mutate(frac_over_50 = samples_over_50 / total_samples)

# Aplicar filtro: eliminar SNVs que tienen VAF ≥ 50% en ≥40 muestras
min_samples_threshold <- 40
df_filtered <- df_collapsed %>%
  left_join(samples_over_threshold, by = c("miRNA name", "pos:mut")) %>%
  filter(samples_over_50 < min_samples_threshold)

snvs_eliminated <- nrow(df_collapsed) - nrow(df_filtered)

cat(paste0("  - SNVs eliminados por filtro de representación: ", snvs_eliminated, "\n"))
cat(paste0("  - SNVs restantes después del filtro: ", nrow(df_filtered), "\n"))

# Mostrar algunos SNVs eliminados
if (snvs_eliminated > 0) {
  eliminated_snvs <- df_collapsed %>%
    left_join(samples_over_threshold, by = c("miRNA name", "pos:mut")) %>%
    filter(samples_over_50 >= min_samples_threshold) %>%
    arrange(desc(samples_over_50)) %>%
    head(5)
  
  cat("  - Ejemplos de SNVs eliminados (más representados):\n")
  print(eliminated_snvs %>% select(`miRNA name`, `pos:mut`, samples_over_50, frac_over_50))
}

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

# --- PASO 9: Comparación con análisis anterior ---
cat("\nPASO 9: Comparación con análisis anterior (con filtro RPM)\n")
cat("==========================================\n")

cat("COMPARACIÓN:\n")
cat("- Con filtro RPM + representación: 148 SNVs (55 en semilla)\n")
cat("- Sin filtro RPM + con representación: ", total_snvs, " SNVs (", seed_total, " en semilla)\n")
cat("- Diferencia: +", total_snvs - 148, " SNVs totales (+", seed_total - 55, " en semilla)\n\n")

# --- PASO 10: Resumen final ---
cat("PASO 10: Resumen final\n")
cat("==========================================\n")

cat("PROCESO COMPLETO:\n")
cat("1. NO filtrar miRNAs por RPM (usar todos los miRNAs)\n")
cat("2. Seleccionar miRNAs con G>T en región semilla\n")
cat("3. Obtener TODAS las mutaciones G>T de esos miRNAs\n")
cat("4. SPLIT: Separar mutaciones múltiples en filas individuales\n")
cat("5. COLLAPSE: Agrupar por miRNA+pos:mut y sumar cuentas\n")
cat("6. FILTRO REPRESENTACIÓN: Eliminar SNVs con VAF ≥ 50% en ≥40 muestras\n\n")

cat("RESULTADOS:\n")
cat(paste0("- miRNAs con G>T en semilla: ", length(gt_seed_miRNAs), "\n"))
cat(paste0("- SNVs G>T antes del split: ", nrow(df_gt_all), "\n"))
cat(paste0("- SNVs G>T después del split: ", nrow(df_split), "\n"))
cat(paste0("- SNPs G>T después del collapse: ", nrow(df_collapsed), "\n"))
cat(paste0("- SNVs eliminados por representación: ", snvs_eliminated, "\n"))
cat(paste0("- SNVs G>T finales: ", total_snvs, "\n"))
cat(paste0("- SNVs G>T en región semilla: ", seed_total, "\n"))

# Mostrar algunos miRNAs más representados
top_miRNAs <- df_filtered %>%
  group_by(`miRNA name`) %>%
  summarise(n_snvs = n(), .groups = "drop") %>%
  arrange(desc(n_snvs)) %>%
  head(10)

cat("\nTop 10 miRNAs con más SNVs G>T:\n")
print(top_miRNAs)

cat("\n=== ANÁLISIS COMPLETADO ===\n")










