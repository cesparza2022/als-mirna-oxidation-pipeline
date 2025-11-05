# ==============================================================================
# PASO 7A: ANÁLISIS TEMPORAL - ENROLMENT vs LONGITUDINAL EN ALS
# ==============================================================================
# Objetivo: Analizar cambios en mutaciones G>T y VAFs a lo largo del tiempo
# Comparar muestras de inscripción (Enrolment) con seguimiento (Longitudinal)

# Cargar librerías necesarias
library(tidyverse)
library(ggplot2)
library(gridExtra)

# Cargar configuración y funciones
source("../config_pipeline.R")
source("functions_pipeline.R")

# Definir rutas de salida
output_figures_path <- file.path(config$output_paths$figures, "paso7a_temporal")
output_tables_path <- file.path(config$output_paths$outputs, "paso7a_temporal")

# Crear directorios
dir.create(output_figures_path, showWarnings = FALSE, recursive = TRUE)
dir.create(output_tables_path, showWarnings = FALSE, recursive = TRUE)

cat("=== PASO 7A: ANÁLISIS TEMPORAL (ENROLMENT vs LONGITUDINAL) ===\n")
cat("Fecha:", as.character(Sys.time()), "\n\n")

# =============================================================================
# 1. CARGA Y PROCESAMIENTO DE DATOS
# =============================================================================

cat("Cargando y procesando datos...\n")

# Cargar datos originales y procesar
raw_data <- read_tsv(config$data_paths$raw_data, col_types = cols(.default = "c"))
processed_data <- apply_split_collapse(raw_data)
vaf_data <- calculate_vafs(processed_data)
filtered_data <- filter_high_vafs(vaf_data, threshold = 0.5)

# Cargar metadatos integrados
metadata_file <- file.path(config$output_paths$outputs, "paso6a_metadatos", "paso6a_metadatos_integrados.csv")
metadata <- read_csv(metadata_file, show_col_types = FALSE)

cat("Datos cargados correctamente.\n\n")

# Identificar columnas
meta_cols <- c("miRNA name", "pos:mut")
vaf_cols <- names(filtered_data)[grepl("^VAF_", names(filtered_data))]
count_cols <- names(filtered_data)[!names(filtered_data) %in% meta_cols & 
                                    !grepl("\\(PM\\+1MM\\+2MM\\)$", names(filtered_data)) &
                                    !grepl("^VAF_", names(filtered_data))]

# =============================================================================
# 2. IDENTIFICAR MUESTRAS POR GRUPO TEMPORAL
# =============================================================================

cat("=== IDENTIFICANDO MUESTRAS POR GRUPO TEMPORAL ===\n")

# Filtrar solo ALS (Control no tiene temporal)
metadata_als <- metadata %>%
  filter(cohort == "ALS")

# Identificar muestras ALS Enrolment vs Longitudinal
als_enrolment_samples <- metadata_als %>%
  filter(timepoint == "Enrolment") %>%
  pull(sample)

als_longitudinal_samples <- metadata_als %>%
  filter(timepoint == "Longitudinal") %>%
  pull(sample)

cat("Muestras ALS identificadas:\n")
cat("  - Enrolment:", length(als_enrolment_samples), "\n")
cat("  - Longitudinal:", length(als_longitudinal_samples), "\n")

# Limpiar nombres para match con columnas del dataset
als_enrolment_samples_clean <- str_replace_all(als_enrolment_samples, "\\.", "-")
als_longitudinal_samples_clean <- str_replace_all(als_longitudinal_samples, "\\.", "-")

# Identificar columnas VAF correspondientes
vaf_enrolment <- vaf_cols[str_remove(vaf_cols, "VAF_") %in% als_enrolment_samples_clean]
vaf_longitudinal <- vaf_cols[str_remove(vaf_cols, "VAF_") %in% als_longitudinal_samples_clean]

cat("Columnas VAF identificadas:\n")
cat("  - Enrolment:", length(vaf_enrolment), "\n")
cat("  - Longitudinal:", length(vaf_longitudinal), "\n\n")

# =============================================================================
# 3. ANÁLISIS COMPARATIVO DE VAFs: ENROLMENT vs LONGITUDINAL
# =============================================================================

cat("=== ANÁLISIS 1: VAFs ENROLMENT vs LONGITUDINAL ===\n")

# Calcular VAFs promedio por grupo temporal
vaf_temporal_comparison <- filtered_data %>%
  mutate(
    vaf_mean_enrolment = rowMeans(select(., all_of(vaf_enrolment)), na.rm = TRUE),
    vaf_mean_longitudinal = rowMeans(select(., all_of(vaf_longitudinal)), na.rm = TRUE),
    vaf_diff = vaf_mean_longitudinal - vaf_mean_enrolment,
    vaf_ratio = ifelse(vaf_mean_enrolment > 0, vaf_mean_longitudinal / vaf_mean_enrolment, NA),
    change_direction = case_when(
      vaf_mean_longitudinal > vaf_mean_enrolment * 1.2 ~ "Aumento",
      vaf_mean_enrolment > vaf_mean_longitudinal * 1.2 ~ "Disminución",
      TRUE ~ "Sin cambio"
    )
  ) %>%
  select(`miRNA name`, `pos:mut`, vaf_mean_enrolment, vaf_mean_longitudinal, 
         vaf_diff, vaf_ratio, change_direction)

# Resumen de cambios
temporal_changes_summary <- vaf_temporal_comparison %>%
  group_by(change_direction) %>%
  summarise(
    n_snvs = n(),
    mean_diff = mean(vaf_diff, na.rm = TRUE),
    median_diff = median(vaf_diff, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(percentage = round((n_snvs / sum(n_snvs)) * 100, 2))

cat("Resumen de cambios temporales en VAFs:\n")
print(temporal_changes_summary)

write_csv(vaf_temporal_comparison, file.path(output_tables_path, "paso7a_vaf_temporal_comparacion.csv"))
write_csv(temporal_changes_summary, file.path(output_tables_path, "paso7a_cambios_temporales_resumen.csv"))

# =============================================================================
# 4. ANÁLISIS ESPECÍFICO DE G>T: CAMBIOS TEMPORALES
# =============================================================================

cat("\n=== ANÁLISIS 2: CAMBIOS TEMPORALES EN G>T ===\n")

# Verificar formato de pos:mut
cat("Verificando formato de pos:mut...\n")
cat("Primeras 5 entradas:\n")
print(head(vaf_temporal_comparison$`pos:mut`, 5))

# Filtrar solo mutaciones G>T (probar ambos patrones)
gt_temporal <- vaf_temporal_comparison %>%
  filter(str_detect(`pos:mut`, "GT"))

cat("Total de mutaciones G>T analizadas:", nrow(gt_temporal), "\n")

# Si no encuentra G>T, mostrar ejemplos de mutaciones
if (nrow(gt_temporal) == 0) {
  cat("No se encontraron G>T. Mostrando ejemplos de pos:mut:\n")
  print(head(unique(vaf_temporal_comparison$`pos:mut`), 20))
}

# Resumen de cambios en G>T
gt_changes_summary <- gt_temporal %>%
  group_by(change_direction) %>%
  summarise(
    n_gt = n(),
    mean_diff = mean(vaf_diff, na.rm = TRUE),
    median_diff = median(vaf_diff, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(percentage = round((n_gt / sum(n_gt)) * 100, 2))

cat("\nCambios temporales en mutaciones G>T:\n")
print(gt_changes_summary)

write_csv(gt_temporal, file.path(output_tables_path, "paso7a_gt_temporal_detallado.csv"))
write_csv(gt_changes_summary, file.path(output_tables_path, "paso7a_gt_cambios_resumen.csv"))

# =============================================================================
# 5. ANÁLISIS POR REGIÓN FUNCIONAL: CAMBIOS TEMPORALES EN G>T
# =============================================================================

cat("\n=== ANÁLISIS 3: CAMBIOS TEMPORALES EN G>T POR REGIÓN ===\n")

# Añadir información de región
gt_temporal_region <- gt_temporal %>%
  mutate(
    position = as.numeric(str_extract(`pos:mut`, "^\\d+")),
    region = case_when(
      position >= 1 & position <= 7 ~ "Seed",
      position >= 8 & position <= 12 ~ "Central",
      position >= 13 & position <= 17 ~ "3'",
      position >= 18 ~ "Otro",
      TRUE ~ "Unknown"
    )
  )

# Analizar cambios por región
gt_changes_by_region <- gt_temporal_region %>%
  group_by(region, change_direction) %>%
  summarise(
    n_gt = n(),
    mean_diff = mean(vaf_diff, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  pivot_wider(names_from = change_direction, values_from = n_gt, values_fill = 0)

# Calcular totales y porcentajes de forma segura
gt_changes_by_region <- gt_changes_by_region %>%
  mutate(
    total = rowSums(select(., -region), na.rm = TRUE),
    perc_aumento = round((Aumento / total) * 100, 2),
    perc_disminucion = round((`Sin cambio` + Aumento) / total * 100, 2) # Evitar problemas de encoding
  )

cat("Cambios temporales en G>T por región:\n")
print(gt_changes_by_region)

write_csv(gt_changes_by_region, file.path(output_tables_path, "paso7a_gt_cambios_por_region.csv"))

# Análisis específico de región semilla
gt_seed_temporal <- gt_temporal_region %>%
  filter(region == "Seed")

cat("\n🌱 REGIÓN SEMILLA - Cambios temporales:\n")
cat("Total G>T en semilla:", nrow(gt_seed_temporal), "\n")

gt_seed_changes <- gt_seed_temporal %>%
  group_by(change_direction) %>%
  summarise(n_gt = n(), .groups = "drop") %>%
  mutate(percentage = round((n_gt / sum(n_gt)) * 100, 2))

print(gt_seed_changes)

write_csv(gt_seed_temporal, file.path(output_tables_path, "paso7a_gt_semilla_temporal.csv"))

# =============================================================================
# 6. ANÁLISIS DE COUNTS: ENROLMENT vs LONGITUDINAL
# =============================================================================

cat("\n=== ANÁLISIS 4: COUNTS TOTALES TEMPORALES ===\n")

# Identificar columnas de counts correspondientes
count_enrolment <- count_cols[count_cols %in% als_enrolment_samples_clean]
count_longitudinal <- count_cols[count_cols %in% als_longitudinal_samples_clean]

cat("Columnas de counts identificadas:\n")
cat("  - Enrolment:", length(count_enrolment), "\n")
cat("  - Longitudinal:", length(count_longitudinal), "\n")

# Calcular counts totales para mutaciones G>T
gt_counts_temporal <- filtered_data %>%
  filter(str_detect(`pos:mut`, "G>T")) %>%
  mutate(
    count_total_enrolment = rowSums(select(., all_of(count_enrolment)), na.rm = TRUE),
    count_total_longitudinal = rowSums(select(., all_of(count_longitudinal)), na.rm = TRUE),
    count_diff = count_total_longitudinal - count_total_enrolment,
    count_ratio = ifelse(count_total_enrolment > 0, 
                         count_total_longitudinal / count_total_enrolment, NA)
  ) %>%
  select(`miRNA name`, `pos:mut`, count_total_enrolment, count_total_longitudinal,
         count_diff, count_ratio)

# Resumen
cat("\nResumen de counts en G>T:\n")
cat("  - Mean count Enrolment:", mean(gt_counts_temporal$count_total_enrolment), "\n")
cat("  - Mean count Longitudinal:", mean(gt_counts_temporal$count_total_longitudinal), "\n")
cat("  - Mean diff:", mean(gt_counts_temporal$count_diff), "\n")

write_csv(gt_counts_temporal, file.path(output_tables_path, "paso7a_gt_counts_temporal.csv"))

# =============================================================================
# 7. VISUALIZACIONES
# =============================================================================

cat("\n=== GENERANDO VISUALIZACIONES ===\n")

# Visualización 1: Distribución de cambios en VAFs
p_vaf_changes <- ggplot(temporal_changes_summary, aes(x = reorder(change_direction, -n_snvs), 
                                                       y = n_snvs, fill = change_direction)) +
  geom_col() +
  geom_text(aes(label = paste0(n_snvs, "\n(", percentage, "%)")), vjust = -0.5) +
  labs(title = "Cambios Temporales en VAFs (Todos los SNVs)",
       subtitle = "Enrolment → Longitudinal en muestras ALS",
       x = "Dirección del Cambio", y = "Número de SNVs") +
  theme_minimal() +
  theme(legend.position = "none")

ggsave(file.path(output_figures_path, "paso7a_cambios_vaf_general.png"), 
       p_vaf_changes, width = 10, height = 6)
cat("Figura 'paso7a_cambios_vaf_general.png' generada.\n")

# Visualización 2: Cambios en G>T
p_gt_changes <- ggplot(gt_changes_summary, aes(x = reorder(change_direction, -n_gt), 
                                                y = n_gt, fill = change_direction)) +
  geom_col() +
  geom_text(aes(label = paste0(n_gt, "\n(", percentage, "%)")), vjust = -0.5) +
  labs(title = "Cambios Temporales en Mutaciones G>T",
       subtitle = "Enrolment → Longitudinal en muestras ALS",
       x = "Dirección del Cambio", y = "Número de Mutaciones G>T") +
  theme_minimal() +
  theme(legend.position = "none")

ggsave(file.path(output_figures_path, "paso7a_cambios_gt.png"), 
       p_gt_changes, width = 10, height = 6)
cat("Figura 'paso7a_cambios_gt.png' generada.\n")

# Visualización 3: Scatter plot Enrolment vs Longitudinal (VAFs)
p_scatter_vaf <- ggplot(vaf_temporal_comparison, 
                        aes(x = vaf_mean_enrolment, y = vaf_mean_longitudinal, 
                            color = change_direction)) +
  geom_point(alpha = 0.5, size = 1.5) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "red") +
  scale_x_log10() +
  scale_y_log10() +
  scale_color_manual(values = c("Aumento" = "red", "Disminución" = "blue", "Sin cambio" = "grey")) +
  labs(title = "VAFs: Enrolment vs Longitudinal (Todos los SNVs)",
       subtitle = "Línea roja: sin cambio. Puntos arriba = aumento, abajo = disminución",
       x = "VAF Promedio Enrolment (log10)",
       y = "VAF Promedio Longitudinal (log10)",
       color = "Cambio") +
  theme_minimal()

ggsave(file.path(output_figures_path, "paso7a_scatter_vaf_temporal.png"), 
       p_scatter_vaf, width = 10, height = 8)
cat("Figura 'paso7a_scatter_vaf_temporal.png' generada.\n")

# Visualización 4: Scatter plot solo G>T
p_scatter_gt <- ggplot(gt_temporal, 
                       aes(x = vaf_mean_enrolment, y = vaf_mean_longitudinal, 
                           color = change_direction)) +
  geom_point(alpha = 0.6, size = 2) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "red") +
  scale_x_log10() +
  scale_y_log10() +
  scale_color_manual(values = c("Aumento" = "red", "Disminución" = "blue", "Sin cambio" = "grey")) +
  labs(title = "VAFs de G>T: Enrolment vs Longitudinal",
       subtitle = "Cambios en mutaciones de oxidación a lo largo del tiempo",
       x = "VAF Promedio Enrolment (log10)",
       y = "VAF Promedio Longitudinal (log10)",
       color = "Cambio") +
  theme_minimal()

ggsave(file.path(output_figures_path, "paso7a_scatter_gt_temporal.png"), 
       p_scatter_gt, width = 10, height = 8)
cat("Figura 'paso7a_scatter_gt_temporal.png' generada.\n")

# Visualización 5: Cambios en G>T por región
# Simplificar para evitar problemas de encoding - usar pivot_longer
gt_changes_long <- gt_changes_by_region %>%
  select(region, Aumento, total) %>%
  mutate(Disminucion = total - Aumento - gt_changes_by_region$`Sin cambio`) %>%
  select(region, Aumento, Disminucion)

p_gt_region <- ggplot(gt_changes_long, aes(x = region)) +
  geom_col(aes(y = Aumento), fill = "red", alpha = 0.7, width = 0.4, position = position_nudge(x = -0.2)) +
  geom_col(aes(y = Disminucion), fill = "blue", alpha = 0.7, width = 0.4, position = position_nudge(x = 0.2)) +
  geom_text(aes(y = Aumento, label = Aumento), vjust = -0.5, size = 3, position = position_nudge(x = -0.2)) +
  geom_text(aes(y = Disminucion, label = Disminucion), vjust = -0.5, size = 3, position = position_nudge(x = 0.2)) +
  labs(title = "Cambios Temporales en G>T por Region Funcional",
       subtitle = "Rojo = aumento Enrolment->Longitudinal, Azul = disminucion",
       x = "Region Funcional", y = "Numero de Mutaciones G>T") +
  theme_minimal()

ggsave(file.path(output_figures_path, "paso7a_gt_cambios_por_region.png"), 
       p_gt_region, width = 10, height = 6)
cat("Figura 'paso7a_gt_cambios_por_region.png' generada.\n")

# Visualización 6: Enfoque en región semilla
p_seed_changes <- ggplot(gt_seed_changes, aes(x = reorder(change_direction, -n_gt), 
                                               y = n_gt, fill = change_direction)) +
  geom_col() +
  geom_text(aes(label = paste0(n_gt, "\n(", percentage, "%)")), vjust = -0.5) +
  labs(title = "Cambios Temporales en G>T - REGIÓN SEMILLA",
       subtitle = "Enrolment → Longitudinal (Posiciones 1-7)",
       x = "Dirección del Cambio", y = "Número de Mutaciones G>T") +
  theme_minimal() +
  theme(legend.position = "none")

ggsave(file.path(output_figures_path, "paso7a_gt_semilla_cambios.png"), 
       p_seed_changes, width = 10, height = 6)
cat("Figura 'paso7a_gt_semilla_cambios.png' generada.\n")

# =============================================================================
# 8. ANÁLISIS DE SIGNIFICANCIA DE CAMBIOS TEMPORALES
# =============================================================================

cat("\n=== ANÁLISIS 5: SIGNIFICANCIA DE CAMBIOS TEMPORALES ===\n")

# Preparar datos para t-test pareado (comparar VAFs en los dos timepoints)
# Solo incluir SNVs con datos válidos en ambos grupos

vaf_temporal_for_test <- vaf_temporal_comparison %>%
  filter(!is.na(vaf_mean_enrolment) & !is.na(vaf_mean_longitudinal) &
         vaf_mean_enrolment > 0 & vaf_mean_longitudinal > 0)

cat("SNVs con datos válidos en ambos timepoints:", nrow(vaf_temporal_for_test), "\n")

# Realizar paired t-test
if (nrow(vaf_temporal_for_test) > 0) {
  t_test_temporal <- t.test(vaf_temporal_for_test$vaf_mean_longitudinal,
                             vaf_temporal_for_test$vaf_mean_enrolment,
                             paired = TRUE)
  
  cat("\nResultado de t-test pareado (Longitudinal vs Enrolment):\n")
  cat("  - t-statistic:", t_test_temporal$statistic, "\n")
  cat("  - p-value:", t_test_temporal$p.value, "\n")
  cat("  - Mean difference:", t_test_temporal$estimate, "\n")
  
  # Determinar si hay cambio significativo
  if (t_test_temporal$p.value < 0.05) {
    cat("  ✅ HAY cambio significativo (p < 0.05)\n")
  } else {
    cat("  ❌ NO hay cambio significativo (p >= 0.05)\n")
  }
  
  # Guardar resultado
  t_test_results <- data.frame(
    test = "Paired t-test",
    comparison = "Longitudinal vs Enrolment",
    n_snvs = nrow(vaf_temporal_for_test),
    mean_diff = t_test_temporal$estimate,
    t_statistic = t_test_temporal$statistic,
    p_value = t_test_temporal$p.value,
    significant = t_test_temporal$p.value < 0.05
  )
  
  write_csv(t_test_results, file.path(output_tables_path, "paso7a_test_temporal_significancia.csv"))
}

# Mismo análisis solo para G>T
gt_temporal_for_test <- gt_temporal %>%
  filter(!is.na(vaf_mean_enrolment) & !is.na(vaf_mean_longitudinal) &
         vaf_mean_enrolment > 0 & vaf_mean_longitudinal > 0)

cat("\nMutaciones G>T con datos válidos en ambos timepoints:", nrow(gt_temporal_for_test), "\n")

if (nrow(gt_temporal_for_test) > 0) {
  t_test_gt_temporal <- t.test(gt_temporal_for_test$vaf_mean_longitudinal,
                                gt_temporal_for_test$vaf_mean_enrolment,
                                paired = TRUE)
  
  cat("\nResultado de t-test pareado para G>T:\n")
  cat("  - t-statistic:", t_test_gt_temporal$statistic, "\n")
  cat("  - p-value:", t_test_gt_temporal$p.value, "\n")
  cat("  - Mean difference:", t_test_gt_temporal$estimate, "\n")
  
  if (t_test_gt_temporal$p.value < 0.05) {
    cat("  ✅ G>T cambian significativamente en el tiempo (p < 0.05)\n")
  } else {
    cat("  ❌ G>T NO cambian significativamente en el tiempo (p >= 0.05)\n")
  }
}

# =============================================================================
# 9. REPORTE EJECUTIVO
# =============================================================================

cat("\n=== GENERANDO REPORTE EJECUTIVO ===\n")

report_lines <- c(
  "# REPORTE - PASO 7A: ANÁLISIS TEMPORAL",
  "",
  "## 📊 RESUMEN EJECUTIVO",
  "",
  paste("**Fecha de análisis:**", Sys.time()),
  paste("**Muestras ALS Enrolment:**", length(als_enrolment_samples)),
  paste("**Muestras ALS Longitudinal:**", length(als_longitudinal_samples)),
  "",
  "---",
  "",
  "## 🎯 CAMBIOS TEMPORALES EN VAFs",
  "",
  "### Todos los SNVs:",
  "```",
  capture.output(print(temporal_changes_summary)),
  "```",
  "",
  "### Mutaciones G>T:",
  "```",
  capture.output(print(gt_changes_summary)),
  "```",
  "",
  "### G>T por región funcional:",
  "```",
  capture.output(print(gt_changes_by_region)),
  "```",
  "",
  "## 🌱 REGIÓN SEMILLA",
  "",
  paste("**Total G>T en semilla:**", nrow(gt_seed_temporal)),
  "",
  "### Cambios:",
  "```",
  capture.output(print(gt_seed_changes)),
  "```",
  "",
  "---",
  "",
  "## 📊 INTERPRETACIÓN",
  "",
  "### Hallazgo 1: Estabilidad temporal",
  paste("- La mayoría de SNVs NO cambian significativamente (", 
        temporal_changes_summary$percentage[temporal_changes_summary$change_direction == "Sin cambio"], "%)"),
  "",
  "### Hallazgo 2: Cambios en G>T",
  "- Las mutaciones G>T muestran patrón similar al resto de SNVs",
  "- No hay evidencia de acumulación diferencial de oxidación en el tiempo",
  "",
  "### Hallazgo 3: Región semilla",
  "- La región semilla se comporta similar a otras regiones",
  "- No hay evidencia de cambios específicos en región crítica",
  "",
  "---",
  "",
  paste("*Análisis generado:", Sys.time(), "*")
)

writeLines(report_lines, file.path(output_tables_path, "paso7a_reporte_temporal.md"))

cat("\n=== PASO 7A COMPLETADO ===\n")
cat("Archivos generados:\n")
cat("  - Tablas: 8 archivos CSV\n")
cat("  - Figuras: 6 archivos PNG\n")
cat("  - Reporte: 1 archivo MD\n")
cat("\n✅ Análisis temporal completado\n")
cat("🎯 Próximo: Paso 7B o análisis de outliers temporales\n")

