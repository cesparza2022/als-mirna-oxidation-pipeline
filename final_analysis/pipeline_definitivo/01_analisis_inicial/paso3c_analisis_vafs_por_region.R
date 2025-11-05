# ==============================================================================
# PASO 3C: ANÁLISIS DE DISTRIBUCIÓN DE VAFs POR REGIÓN
# ==============================================================================

# Cargar librerías necesarias
library(tidyverse)
library(ggplot2)
library(gridExtra)
library(reshape2)

# Cargar configuración y funciones
source("../config_pipeline.R")
source("functions_pipeline.R")

# Definir rutas de salida
output_figures_path <- file.path(config$output_paths$figures, "paso3c_vafs_region")
output_tables_path <- file.path(config$output_paths$outputs, "paso3c_vafs_region")

# Crear directorios si no existen
dir.create(output_figures_path, showWarnings = FALSE, recursive = TRUE)
dir.create(output_tables_path, showWarnings = FALSE, recursive = TRUE)

cat("=== PASO 3C: ANÁLISIS DE DISTRIBUCIÓN DE VAFs POR REGIÓN ===\n")
cat("Fecha:", Sys.time(), "\n\n")

# =============================================================================
# 1. CARGA Y PROCESAMIENTO DE DATOS
# =============================================================================

cat("Cargando y procesando datos...\n")

# Cargar datos originales
raw_data <- read_tsv(config$data_paths$raw_data, col_types = cols(.default = "c"))

# Aplicar split-collapse
processed_data <- apply_split_collapse(raw_data)

# Calcular VAFs
vaf_data <- calculate_vafs(processed_data)

# Filtrar VAFs > 50%
filtered_data <- filter_high_vafs(vaf_data, threshold = 0.5)

# Extraer posición y región funcional
filtered_data <- filtered_data %>%
  mutate(
    position = as.numeric(str_extract(`pos:mut`, "^\\d+")),
    region = case_when(
      position >= 2 & position <= 8 ~ "Seed",
      position >= 9 & position <= 12 ~ "Central",
      position >= 13 & position <= 17 ~ "3'",
      TRUE ~ "Otro"
    )
  )

cat("Datos procesados:\n")
cat("  - Raw data:", nrow(raw_data), "filas,", ncol(raw_data), "columnas\n")
cat("  - Processed data:", nrow(processed_data), "filas,", ncol(processed_data), "columnas\n")
cat("  - VAF data:", nrow(vaf_data), "filas,", ncol(vaf_data), "columnas\n")
cat("  - Filtered data:", nrow(filtered_data), "filas,", ncol(filtered_data), "columnas\n")

# =============================================================================
# 2. ANÁLISIS DE VAFs POR REGIÓN FUNCIONAL
# =============================================================================

cat("\nRealizando análisis de VAFs por región funcional...\n")

# Identificar columnas VAF
vaf_cols <- colnames(filtered_data)[str_detect(colnames(filtered_data), "^VAF_")]

# Convertir a formato largo para análisis
vaf_data_long <- filtered_data %>%
  select(`miRNA name`, `pos:mut`, position, region, all_of(vaf_cols)) %>%
  pivot_longer(cols = all_of(vaf_cols), names_to = "sample", values_to = "vaf_value") %>%
  filter(!is.na(vaf_value)) # Remover NaNs

# Análisis general de VAFs por región
vaf_by_region <- vaf_data_long %>%
  group_by(region) %>%
  summarise(
    n_mutations = n_distinct(`miRNA name`, `pos:mut`),
    n_observations = n(),
    mean_vaf = mean(vaf_value, na.rm = TRUE),
    median_vaf = median(vaf_value, na.rm = TRUE),
    max_vaf = max(vaf_value, na.rm = TRUE),
    min_vaf = min(vaf_value, na.rm = TRUE),
    std_vaf = sd(vaf_value, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(mean_vaf))

write_csv(vaf_by_region, file.path(output_tables_path, "paso3c_vafs_por_region_general.csv"))
cat("Tabla 'paso3c_vafs_por_region_general.csv' generada.\n")
cat("VAFs por región funcional:\n")
print(vaf_by_region)

# =============================================================================
# 3. ANÁLISIS DE VAFs POR REGIÓN Y TIPO DE MUTACIÓN
# =============================================================================

cat("\nRealizando análisis de VAFs por región y tipo de mutación...\n")

# Identificar tipos de mutación
vaf_data_long <- vaf_data_long %>%
  mutate(
    mutation_type = case_when(
      str_detect(`pos:mut`, "G>T") ~ "G>T",
      str_detect(`pos:mut`, "C>A") ~ "C>A",
      str_detect(`pos:mut`, "A>T") ~ "A>T",
      str_detect(`pos:mut`, "T>G") ~ "T>G",
      str_detect(`pos:mut`, "G>C") ~ "G>C",
      str_detect(`pos:mut`, "C>G") ~ "C>G",
      str_detect(`pos:mut`, "A>G") ~ "A>G",
      str_detect(`pos:mut`, "T>C") ~ "T>C",
      str_detect(`pos:mut`, "G>A") ~ "G>A",
      str_detect(`pos:mut`, "C>T") ~ "C>T",
      str_detect(`pos:mut`, "A>C") ~ "A>C",
      str_detect(`pos:mut`, "T>A") ~ "T>A",
      TRUE ~ "Otro"
    )
  )

# Análisis de VAFs por región y tipo de mutación
vaf_by_region_mutation <- vaf_data_long %>%
  group_by(region, mutation_type) %>%
  summarise(
    n_mutations = n_distinct(`miRNA name`, `pos:mut`),
    n_observations = n(),
    mean_vaf = mean(vaf_value, na.rm = TRUE),
    median_vaf = median(vaf_value, na.rm = TRUE),
    max_vaf = max(vaf_value, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(region, desc(mean_vaf))

write_csv(vaf_by_region_mutation, file.path(output_tables_path, "paso3c_vafs_por_region_tipo_mutacion.csv"))
cat("Tabla 'paso3c_vafs_por_region_tipo_mutacion.csv' generada.\n")

# =============================================================================
# 4. ANÁLISIS ESPECÍFICO DE MUTACIONES G>T POR REGIÓN
# =============================================================================

cat("\nRealizando análisis específico de mutaciones G>T por región...\n")

# Filtrar solo mutaciones G>T
gt_vaf_data <- vaf_data_long %>%
  filter(mutation_type == "G>T")

if (nrow(gt_vaf_data) > 0) {
  # Análisis de G>T por región
  gt_vaf_by_region <- gt_vaf_data %>%
    group_by(region) %>%
    summarise(
      n_mutations = n_distinct(`miRNA name`, `pos:mut`),
      n_observations = n(),
      mean_vaf = mean(vaf_value, na.rm = TRUE),
      median_vaf = median(vaf_value, na.rm = TRUE),
      max_vaf = max(vaf_value, na.rm = TRUE),
      min_vaf = min(vaf_value, na.rm = TRUE),
      std_vaf = sd(vaf_value, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    arrange(desc(mean_vaf))

  write_csv(gt_vaf_by_region, file.path(output_tables_path, "paso3c_gt_vafs_por_region.csv"))
  cat("Tabla 'paso3c_gt_vafs_por_region.csv' generada.\n")
  cat("VAFs de G>T por región funcional:\n")
  print(gt_vaf_by_region)

  # Comparación de G>T vs otras mutaciones por región
  gt_vs_other_by_region <- vaf_data_long %>%
    mutate(is_gt = mutation_type == "G>T") %>%
    group_by(region, is_gt) %>%
    summarise(
      n_mutations = n_distinct(`miRNA name`, `pos:mut`),
      mean_vaf = mean(vaf_value, na.rm = TRUE),
      median_vaf = median(vaf_value, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    pivot_wider(names_from = is_gt, values_from = c(n_mutations, mean_vaf, median_vaf), names_prefix = "gt_") %>%
    mutate(
      vaf_ratio = mean_vaf_gt_TRUE / mean_vaf_gt_FALSE,
      mutation_ratio = n_mutations_gt_TRUE / n_mutations_gt_FALSE
    )

  write_csv(gt_vs_other_by_region, file.path(output_tables_path, "paso3c_gt_vs_otras_por_region.csv"))
  cat("Tabla 'paso3c_gt_vs_otras_por_region.csv' generada.\n")
  cat("Comparación G>T vs otras mutaciones por región:\n")
  print(gt_vs_other_by_region)

} else {
  cat("No se encontraron mutaciones G>T para el análisis por región.\n")
}

# =============================================================================
# 5. ANÁLISIS DE VAFs POR REGIÓN Y POSICIÓN ESPECÍFICA
# =============================================================================

cat("\nRealizando análisis de VAFs por región y posición específica...\n")

# Análisis de VAFs por región y posición
vaf_by_region_position <- vaf_data_long %>%
  group_by(region, position) %>%
  summarise(
    n_mutations = n_distinct(`miRNA name`, `pos:mut`),
    n_observations = n(),
    mean_vaf = mean(vaf_value, na.rm = TRUE),
    median_vaf = median(vaf_value, na.rm = TRUE),
    max_vaf = max(vaf_value, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(region, desc(mean_vaf))

write_csv(vaf_by_region_position, file.path(output_tables_path, "paso3c_vafs_por_region_posicion.csv"))
cat("Tabla 'paso3c_vafs_por_region_posicion.csv' generada.\n")

# =============================================================================
# 6. GENERACIÓN DE VISUALIZACIONES
# =============================================================================

cat("\nGenerando visualizaciones...\n")

# 1. Boxplot de VAFs por región
p_vaf_region_boxplot <- ggplot(vaf_data_long, aes(x = region, y = vaf_value, fill = region)) +
  geom_boxplot(na.rm = TRUE) +
  geom_violin(alpha = 0.5, na.rm = TRUE) +
  scale_y_log10() +
  labs(title = "Distribución de VAFs por Región Funcional",
       x = "Región Funcional", y = "VAF (log10)") +
  theme_minimal() +
  theme(legend.position = "none")

ggsave(file.path(output_figures_path, "paso3c_vafs_por_region_boxplot.png"), 
       p_vaf_region_boxplot, width = 10, height = 6)
cat("Figura 'paso3c_vafs_por_region_boxplot.png' generada.\n")

# 2. Heatmap de VAFs por región y tipo de mutación
p_vaf_heatmap <- ggplot(vaf_by_region_mutation, aes(x = mutation_type, y = region, fill = mean_vaf)) +
  geom_tile() +
  scale_fill_gradient(low = "white", high = "red") +
  labs(title = "VAFs Promedio por Región y Tipo de Mutación",
       x = "Tipo de Mutación", y = "Región Funcional", fill = "VAF Promedio") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave(file.path(output_figures_path, "paso3c_vafs_heatmap_region_mutacion.png"), 
       p_vaf_heatmap, width = 12, height = 6)
cat("Figura 'paso3c_vafs_heatmap_region_mutacion.png' generada.\n")

# 3. Comparación G>T vs otras mutaciones por región
if (nrow(gt_vaf_data) > 0) {
  p_gt_vs_other <- ggplot(gt_vs_other_by_region, aes(x = region)) +
    geom_col(aes(y = mean_vaf_gt_TRUE, fill = "G>T"), alpha = 0.7, position = "dodge") +
    geom_col(aes(y = mean_vaf_gt_FALSE, fill = "Otras"), alpha = 0.7, position = "dodge") +
    labs(title = "Comparación de VAFs: G>T vs Otras Mutaciones por Región",
         x = "Región Funcional", y = "VAF Promedio", fill = "Tipo de Mutación") +
    theme_minimal() +
    theme(legend.position = "bottom")

  ggsave(file.path(output_figures_path, "paso3c_gt_vs_otras_por_region.png"), 
         p_gt_vs_other, width = 10, height = 6)
  cat("Figura 'paso3c_gt_vs_otras_por_region.png' generada.\n")
}

# 4. VAFs por región y posición
p_vaf_region_position <- ggplot(vaf_by_region_position, aes(x = position, y = mean_vaf, color = region)) +
  geom_line() +
  geom_point() +
  facet_wrap(~region, scales = "free_y") +
  labs(title = "VAFs Promedio por Región y Posición",
       x = "Posición", y = "VAF Promedio", color = "Región") +
  theme_minimal()

ggsave(file.path(output_figures_path, "paso3c_vafs_por_region_posicion.png"), 
       p_vaf_region_position, width = 12, height = 8)
cat("Figura 'paso3c_vafs_por_region_posicion.png' generada.\n")

# =============================================================================
# 7. RESUMEN DE HALLAZGOS
# =============================================================================

cat("\n=== RESUMEN DE HALLAZGOS ===\n")

# Hallazgos principales
cat("1. VAFs por región funcional:\n")
for (i in 1:nrow(vaf_by_region)) {
  cat("   -", vaf_by_region$region[i], ":", round(vaf_by_region$mean_vaf[i], 4), 
      "VAF promedio,", vaf_by_region$n_mutations[i], "mutaciones\n")
}

if (nrow(gt_vaf_data) > 0) {
  cat("\n2. VAFs de G>T por región funcional:\n")
  for (i in 1:nrow(gt_vaf_by_region)) {
    cat("   -", gt_vaf_by_region$region[i], ":", round(gt_vaf_by_region$mean_vaf[i], 4), 
        "VAF promedio,", gt_vaf_by_region$n_mutations[i], "mutaciones G>T\n")
  }
}

cat("\n3. Archivos generados:\n")
cat("   - Tablas:", length(list.files(output_tables_path, pattern = "\\.csv$")), "archivos CSV\n")
cat("   - Figuras:", length(list.files(output_figures_path, pattern = "\\.png$")), "archivos PNG\n")

cat("\n=== PASO 3C COMPLETADO ===\n")








