#!/usr/bin/env Rscript

# =============================================================================
# ANÁLISIS CORRECTO CON SPLIT Y COLLAPSE BIEN IMPLEMENTADOS
# =============================================================================
# SPLIT: Separar "2:GT,4:TG" en dos filas con mismas cuentas
# COLLAPSE: Agrupar por miRNA + pos:mut y sumar cuentas

library(dplyr)
library(readr)
library(stringr)
library(tidyr)

cat("=== ANÁLISIS CORRECTO CON SPLIT Y COLLAPSE ===\n\n")

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

# --- PASO 2: Calcular RPMs y filtrar miRNAs ---
cat("PASO 2: Calculando RPMs y filtrando miRNAs\n")
cat("==========================================\n")

# Calcular library size por muestra
library_sizes <- df_main %>%
  select(all_of(sample_cols)) %>%
  summarise(across(everything(), ~ sum(as.numeric(.x), na.rm = TRUE))) %>%
  pivot_longer(everything(), names_to = "sample", values_to = "library_size")

# Calcular RPM para cada miRNA
rpm_data <- df_main %>%
  select(`miRNA name`, all_of(sample_cols)) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "sample", values_to = "count") %>%
  mutate(count = as.numeric(count)) %>%
  left_join(library_sizes, by = "sample") %>%
  mutate(rpm = (count / library_size) * 1e6) %>%
  group_by(`miRNA name`) %>%
  summarise(median_rpm = median(rpm, na.rm = TRUE), .groups = "drop")

# Filtrar miRNAs con RPM >= 1.0
miRNAs_high_rpm <- rpm_data %>%
  filter(median_rpm >= 1.0) %>%
  pull(`miRNA name`)

cat(paste0("  - miRNAs con RPM >= 1.0: ", length(miRNAs_high_rpm), "\n"))

# --- PASO 3: Identificar miRNAs con G>T en región semilla ---
cat("\nPASO 3: Identificando miRNAs con G>T en región semilla\n")
cat("==========================================\n")

gt_seed_miRNAs <- df_main %>%
  filter(str_detect(`pos:mut`, "GT")) %>%
  mutate(pos = as.numeric(str_extract(`pos:mut`, "^[0-9]+"))) %>%
  filter(pos >= 2 & pos <= 8) %>%
  pull(`miRNA name`) %>%
  unique()

cat(paste0("  - miRNAs con G>T en región semilla: ", length(gt_seed_miRNAs), "\n"))

# Intersección: miRNAs con RPM alto Y con G>T en semilla
selected_miRNAs <- intersect(miRNAs_high_rpm, gt_seed_miRNAs)
cat(paste0("  - miRNAs seleccionados: ", length(selected_miRNAs), "\n"))

# --- PASO 4: Obtener TODAS las mutaciones G>T de miRNAs seleccionados ---
cat("\nPASO 4: Obteniendo TODAS las mutaciones G>T\n")
cat("==========================================\n")

df_gt_all <- df_main %>%
  filter(`miRNA name` %in% selected_miRNAs) %>%
  filter(str_detect(`pos:mut`, "GT"))

cat(paste0("  - SNVs G>T totales antes del split: ", nrow(df_gt_all), "\n"))

# Mostrar algunos ejemplos de mutaciones múltiples
multi_mut_examples <- df_gt_all %>%
  filter(str_detect(`pos:mut`, ",")) %>%
  head(5)

if (nrow(multi_mut_examples) > 0) {
  cat("  - Ejemplos de mutaciones múltiples:\n")
  print(multi_mut_examples %>% select(`miRNA name`, `pos:mut`))
}

# --- PASO 5: SPLIT - Separar mutaciones múltiples ---
cat("\nPASO 5: SPLIT - Separando mutaciones múltiples\n")
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

# Mostrar ejemplos del split
split_examples <- df_split %>%
  group_by(`miRNA name`) %>%
  filter(n() > 1) %>%
  head(10)

if (nrow(split_examples) > 0) {
  cat("  - Ejemplos después del split:\n")
  print(split_examples %>% select(`miRNA name`, `pos:mut`))
}

# --- PASO 6: COLLAPSE - Agrupar por miRNA + pos:mut y sumar cuentas ---
cat("\nPASO 6: COLLAPSE - Agrupando y sumando cuentas\n")
cat("==========================================\n")

df_collapsed <- df_split %>%
  group_by(`miRNA name`, `pos:mut`) %>%
  summarise(
    across(all_of(sample_cols), ~ sum(as.numeric(.x), na.rm = TRUE)),
    .groups = "drop"
  )

cat(paste0("  - SNPs G>T después del COLLAPSE: ", nrow(df_collapsed), "\n"))

# --- PASO 7: Contar SNVs por posición ---
cat("\nPASO 7: Contando SNVs por posición\n")
cat("==========================================\n")

position_counts <- df_collapsed %>%
  mutate(pos = as.numeric(str_extract(`pos:mut`, "^[0-9]+"))) %>%
  count(pos, name = "count") %>%
  arrange(pos)

cat("  - Distribución de SNVs G>T por posición:\n")
print(position_counts)

# Estadísticas
total_snvs <- nrow(df_collapsed)
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

seed_counts <- df_collapsed %>%
  mutate(pos = as.numeric(str_extract(`pos:mut`, "^[0-9]+"))) %>%
  filter(pos >= 2 & pos <= 8) %>%
  count(pos, name = "count") %>%
  arrange(pos)

cat("  - SNVs G>T en región semilla por posición:\n")
print(seed_counts)

seed_total <- sum(seed_counts$count)
cat(paste0("  - Total de SNVs G>T en región semilla: ", seed_total, "\n"))

# --- PASO 9: Resumen final ---
cat("\nPASO 9: Resumen final\n")
cat("==========================================\n")

cat("PROCESO COMPLETO:\n")
cat("1. Filtrar miRNAs por RPM >= 1.0\n")
cat("2. Seleccionar miRNAs con G>T en región semilla\n")
cat("3. Obtener TODAS las mutaciones G>T de esos miRNAs\n")
cat("4. SPLIT: Separar mutaciones múltiples en filas individuales\n")
cat("5. COLLAPSE: Agrupar por miRNA+pos:mut y sumar cuentas\n\n")

cat("RESULTADOS:\n")
cat(paste0("- miRNAs seleccionados: ", length(selected_miRNAs), "\n"))
cat(paste0("- SNVs G>T antes del split: ", nrow(df_gt_all), "\n"))
cat(paste0("- SNVs G>T después del split: ", nrow(df_split), "\n"))
cat(paste0("- SNPs G>T después del collapse: ", total_snvs, "\n"))
cat(paste0("- SNVs G>T en región semilla: ", seed_total, "\n"))

# Mostrar algunos miRNAs seleccionados
cat("\nEjemplos de miRNAs seleccionados:\n")
print(head(selected_miRNAs, 10))

cat("\n=== ANÁLISIS COMPLETADO ===\n")










