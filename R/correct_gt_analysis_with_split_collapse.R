#!/usr/bin/env Rscript

# =============================================================================
# ANÁLISIS CORRECTO DE SNVs G>T CON SPLIT Y COLLAPSE
# =============================================================================
# Este script aplica la limpieza correcta:
# 1. Filtra miRNAs por RPM >= 1.0
# 2. Selecciona miRNAs con al menos un SNV G>T en región semilla
# 3. Mantiene TODAS las mutaciones G>T de esos miRNAs
# 4. Aplica split y collapse para convertir SNVs a SNPs
# 5. Cuenta SNVs por posición

library(dplyr)
library(readr)
library(stringr)
library(tidyr)

cat("=== ANÁLISIS CORRECTO DE SNVs G>T CON SPLIT Y COLLAPSE ===\n\n")

# --- PASO 1: Cargar datos ---
cat("PASO 1: Cargando datos\n")
cat("==========================================\n")

# Cargar datos principales
df_main <- read_tsv("results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt", show_col_types = FALSE)
cat(paste0("  - Archivo cargado: miRNA_count.Q33.txt\n"))
cat(paste0("  - Dimensiones originales: ", nrow(df_main), " filas x ", ncol(df_main), " columnas\n"))

# Remover primera fila (metadatos)
df_main <- df_main[-1, ]
cat(paste0("  - Después de remover metadatos: ", nrow(df_main), " filas x ", ncol(df_main), " columnas\n"))

# Identificar columnas
sample_cols <- names(df_main)[!names(df_main) %in% c("miRNA name", "pos:mut")]
als_samples <- sample_cols[str_detect(sample_cols, "Magen-ALS")]
control_samples <- sample_cols[str_detect(sample_cols, "Magen-control")]

cat(paste0("  - Muestras totales: ", length(sample_cols), "\n"))
cat(paste0("  - Muestras ALS: ", length(als_samples), "\n"))
cat(paste0("  - Muestras Control: ", length(control_samples), "\n\n"))

# --- PASO 2: Calcular RPMs para cada miRNA ---
cat("PASO 2: Calculando RPMs para cada miRNA\n")
cat("==========================================\n")

# Calcular library size por muestra (suma de todos los conteos PM)
library_sizes <- df_main %>%
  select(all_of(sample_cols)) %>%
  summarise(across(everything(), ~ sum(as.numeric(.x), na.rm = TRUE))) %>%
  pivot_longer(everything(), names_to = "sample", values_to = "library_size")

# Calcular RPM para cada miRNA en cada muestra
rpm_data <- df_main %>%
  select(`miRNA name`, all_of(sample_cols)) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "sample", values_to = "count") %>%
  mutate(count = as.numeric(count)) %>%
  left_join(library_sizes, by = "sample") %>%
  mutate(rpm = (count / library_size) * 1e6) %>%
  group_by(`miRNA name`) %>%
  summarise(
    median_rpm = median(rpm, na.rm = TRUE),
    mean_rpm = mean(rpm, na.rm = TRUE),
    .groups = "drop"
  )

cat(paste0("  - RPMs calculados para ", nrow(rpm_data), " miRNAs\n"))
cat("  - Resumen de RPMs:\n")
print(summary(rpm_data$median_rpm))

# --- PASO 3: Filtrar miRNAs por RPM >= 1.0 ---
cat("\nPASO 3: Filtrando miRNAs por RPM >= 1.0\n")
cat("==========================================\n")

miRNAs_high_rpm <- rpm_data %>%
  filter(median_rpm >= 1.0) %>%
  pull(`miRNA name`)

cat(paste0("  - miRNAs con RPM >= 1.0: ", length(miRNAs_high_rpm), "\n"))
cat(paste0("  - miRNAs eliminados por RPM bajo: ", nrow(rpm_data) - length(miRNAs_high_rpm), "\n"))

# --- PASO 4: Identificar miRNAs con al menos un SNV G>T en región semilla ---
cat("\nPASO 4: Identificando miRNAs con SNVs G>T en región semilla\n")
cat("==========================================\n")

# Filtrar SNVs G>T en región semilla
gt_seed_snvs <- df_main %>%
  filter(str_detect(`pos:mut`, "GT")) %>%
  mutate(pos = as.numeric(str_extract(`pos:mut`, "^[0-9]+"))) %>%
  filter(pos >= 2 & pos <= 8) %>%
  pull(`miRNA name`) %>%
  unique()

cat(paste0("  - miRNAs con SNVs G>T en región semilla: ", length(gt_seed_snvs), "\n"))

# Intersección: miRNAs con RPM alto Y con SNVs G>T en región semilla
selected_miRNAs <- intersect(miRNAs_high_rpm, gt_seed_snvs)
cat(paste0("  - miRNAs seleccionados (RPM >= 1.0 Y con G>T en semilla): ", length(selected_miRNAs), "\n"))

# --- PASO 5: Obtener TODAS las mutaciones G>T de los miRNAs seleccionados ---
cat("\nPASO 5: Obteniendo TODAS las mutaciones G>T de miRNAs seleccionados\n")
cat("==========================================\n")

df_gt_all <- df_main %>%
  filter(`miRNA name` %in% selected_miRNAs) %>%
  filter(str_detect(`pos:mut`, "GT"))

total_gt_snvs <- nrow(df_gt_all)
cat(paste0("  - SNVs G>T totales de miRNAs seleccionados: ", total_gt_snvs, "\n"))

# --- PASO 6: Aplicar SPLIT y COLLAPSE ---
cat("\nPASO 6: Aplicando SPLIT y COLLAPSE (SNV -> SNP)\n")
cat("==========================================\n")

# Función para hacer split de mutaciones múltiples
split_mutations <- function(pos_mut_string) {
  if (is.na(pos_mut_string) || pos_mut_string == "") return(character(0))
  
  # Dividir por comas para obtener mutaciones individuales
  mutations <- str_split(pos_mut_string, ",")[[1]]
  mutations <- str_trim(mutations)
  
  # Filtrar solo las que contienen "GT"
  gt_mutations <- mutations[str_detect(mutations, "GT")]
  
  return(gt_mutations)
}

# Aplicar split a todas las mutaciones
df_split <- df_gt_all %>%
  rowwise() %>%
  mutate(
    individual_mutations = list(split_mutations(`pos:mut`))
  ) %>%
  unnest(individual_mutations) %>%
  filter(!is.na(individual_mutations) & individual_mutations != "")

cat(paste0("  - SNVs G>T después del SPLIT: ", nrow(df_split), "\n"))

# Aplicar COLLAPSE: agrupar por miRNA y posición de mutación
df_collapsed <- df_split %>%
  mutate(
    pos = as.numeric(str_extract(individual_mutations, "^[0-9]+")),
    mut_type = str_extract(individual_mutations, "GT$")
  ) %>%
  group_by(`miRNA name`, pos, mut_type) %>%
  summarise(
    # Sumar conteos de todas las muestras para esta combinación miRNA-posición
    across(all_of(sample_cols), ~ sum(as.numeric(.x), na.rm = TRUE)),
    .groups = "drop"
  ) %>%
  mutate(
    `pos:mut` = paste0(pos, ":", mut_type)
  )

cat(paste0("  - SNPs G>T después del COLLAPSE: ", nrow(df_collapsed), "\n"))

# --- PASO 7: Contar SNVs por posición ---
cat("\nPASO 7: Contando SNVs por posición\n")
cat("==========================================\n")

position_counts <- df_collapsed %>%
  count(pos, name = "count") %>%
  arrange(pos)

cat("  - Distribución de SNVs G>T por posición:\n")
print(position_counts)

# Estadísticas adicionales
total_positions <- nrow(position_counts)
max_position <- max(position_counts$pos, na.rm = TRUE)
min_position <- min(position_counts$pos, na.rm = TRUE)
most_abundant_pos <- position_counts$pos[which.max(position_counts$count)]

cat(paste0("\n  - Posiciones con SNVs G>T: ", total_positions, "\n"))
cat(paste0("  - Rango de posiciones: ", min_position, " - ", max_position, "\n"))
cat(paste0("  - Posición más abundante: ", most_abundant_pos, " (", max(position_counts$count), " SNVs)\n"))

# --- PASO 8: Análisis específico de región semilla ---
cat("\nPASO 8: Análisis específico de región semilla (posiciones 2-8)\n")
cat("==========================================\n")

seed_counts <- df_collapsed %>%
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

cat("FILTROS APLICADOS:\n")
cat("1. miRNAs con RPM >= 1.0\n")
cat("2. miRNAs con al menos un SNV G>T en región semilla (pos 2-8)\n")
cat("3. TODAS las mutaciones G>T de esos miRNAs (no solo región semilla)\n")
cat("4. Split de mutaciones múltiples\n")
cat("5. Collapse por miRNA-posición\n\n")

cat("RESULTADOS:\n")
cat(paste0("- miRNAs seleccionados: ", length(selected_miRNAs), "\n"))
cat(paste0("- SNVs G>T totales: ", nrow(df_collapsed), "\n"))
cat(paste0("- SNVs G>T en región semilla: ", seed_total, "\n"))
cat(paste0("- Posiciones con SNVs: ", total_positions, "\n"))

# Mostrar algunos ejemplos de miRNAs seleccionados
cat("\nEjemplos de miRNAs seleccionados:\n")
print(head(selected_miRNAs, 10))

cat("\n=== ANÁLISIS COMPLETADO ===\n")










