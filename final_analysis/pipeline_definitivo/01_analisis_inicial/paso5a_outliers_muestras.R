# ==============================================================================
# PASO 5A: IDENTIFICACIÓN Y REPORTE DE OUTLIERS EN MUESTRAS
# ==============================================================================
# Objetivo: Identificar muestras outliers SIN eliminarlas
# Evaluar impacto potencial en mutaciones G>T

# Cargar librerías necesarias
library(tidyverse)
library(ggplot2)
library(gridExtra)
library(reshape2)
library(factoextra) # Para PCA mejorado
library(ggrepel)    # Para labels en PCA

# Cargar configuración y funciones
source("../config_pipeline.R")
source("functions_pipeline.R")

# Definir rutas de salida
output_figures_path <- file.path(config$output_paths$figures, "paso5a_outliers_muestras")
output_tables_path <- file.path(config$output_paths$outputs, "paso5a_outliers_muestras")

# Crear directorios si no existen
dir.create(output_figures_path, showWarnings = FALSE, recursive = TRUE)
dir.create(output_tables_path, showWarnings = FALSE, recursive = TRUE)

cat("=== PASO 5A: IDENTIFICACIÓN DE OUTLIERS EN MUESTRAS ===\n")
cat("Fecha:", as.character(Sys.time()), "\n\n")

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

cat("Datos procesados correctamente.\n\n")

# Identificar columnas
meta_cols <- c("miRNA name", "pos:mut")
total_cols <- names(filtered_data)[grepl("\\(PM\\+1MM\\+2MM\\)$", names(filtered_data))]
count_cols <- names(filtered_data)[!names(filtered_data) %in% meta_cols & 
                                    !grepl("\\(PM\\+1MM\\+2MM\\)$", names(filtered_data)) &
                                    !grepl("^VAF_", names(filtered_data))]
vaf_cols <- names(filtered_data)[grepl("^VAF_", names(filtered_data))]

cat("Columnas identificadas:\n")
cat("  - Count columns:", length(count_cols), "\n")
cat("  - Total columns:", length(total_cols), "\n")
cat("  - VAF columns:", length(vaf_cols), "\n\n")

# =============================================================================
# 2. ANÁLISIS 1: DISTRIBUCIÓN DE COUNTS TOTALES POR MUESTRA
# =============================================================================

cat("=== ANÁLISIS 1: DISTRIBUCIÓN DE COUNTS TOTALES ===\n")

# Calcular suma de counts por muestra
count_data <- filtered_data %>%
  select(all_of(count_cols))

# Convertir a numérico
count_data_numeric <- count_data %>%
  mutate(across(everything(), as.numeric))

# Calcular suma de counts por muestra (columna)
total_counts_per_sample <- colSums(count_data_numeric, na.rm = TRUE)

# Crear dataframe de estadísticas
count_stats <- data.frame(
  sample = count_cols,
  total_counts = total_counts_per_sample,
  cohort = ifelse(str_detect(count_cols, "ALS"), "ALS", "Control")
)

# Calcular percentiles
percentiles <- quantile(count_stats$total_counts, probs = c(0.05, 0.25, 0.50, 0.75, 0.95))

cat("Percentiles de counts totales:\n")
print(percentiles)

# Identificar outliers (< p5 o > p95)
count_stats <- count_stats %>%
  mutate(
    outlier_low = total_counts < percentiles[1],
    outlier_high = total_counts > percentiles[5],
    outlier = outlier_low | outlier_high,
    outlier_type = case_when(
      outlier_low ~ "Low",
      outlier_high ~ "High",
      TRUE ~ "Normal"
    )
  )

# Resumen de outliers
outliers_counts_summary <- count_stats %>%
  group_by(cohort, outlier_type) %>%
  summarise(n_samples = n(), .groups = "drop")

cat("\nResumen de outliers por counts:\n")
print(outliers_counts_summary)

write_csv(count_stats, file.path(output_tables_path, "paso5a_counts_por_muestra.csv"))
write_csv(outliers_counts_summary, file.path(output_tables_path, "paso5a_outliers_counts_resumen.csv"))

# Visualización: Boxplot de counts por cohort
p_counts_boxplot <- ggplot(count_stats, aes(x = cohort, y = total_counts, fill = cohort)) +
  geom_boxplot(outlier.colour = "red", outlier.size = 2) +
  geom_jitter(width = 0.2, alpha = 0.3, size = 0.5) +
  scale_y_log10() +
  geom_hline(yintercept = percentiles[1], linetype = "dashed", color = "blue") +
  geom_hline(yintercept = percentiles[5], linetype = "dashed", color = "blue") +
  labs(title = "Distribución de Counts Totales por Muestra",
       subtitle = "Líneas azules: percentiles 5% y 95%",
       x = "Cohort", y = "Total Counts (log10)") +
  theme_minimal()
ggsave(file.path(output_figures_path, "paso5a_distribucion_counts_boxplot.png"), 
       p_counts_boxplot, width = 10, height = 6)

cat("Figura 'paso5a_distribucion_counts_boxplot.png' generada.\n\n")

# =============================================================================
# 3. ANÁLISIS 2: DISTRIBUCIÓN DE TOTALES PROMEDIO POR MUESTRA
# =============================================================================

cat("=== ANÁLISIS 2: DISTRIBUCIÓN DE TOTALES PROMEDIO ===\n")

# Calcular promedio de totales por muestra
total_data <- filtered_data %>%
  select(all_of(total_cols))

# Convertir a numérico
total_data_numeric <- total_data %>%
  mutate(across(everything(), as.numeric))

# Calcular promedio de totales por muestra (columna)
mean_totals_per_sample <- colMeans(total_data_numeric, na.rm = TRUE)

# Crear dataframe de estadísticas
total_stats <- data.frame(
  sample = total_cols,
  mean_total = mean_totals_per_sample,
  cohort = ifelse(str_detect(total_cols, "ALS"), "ALS", "Control")
) %>%
  mutate(sample_clean = str_remove(sample, "\\(PM\\+1MM\\+2MM\\)$"))

# Calcular percentiles
percentiles_totals <- quantile(total_stats$mean_total, probs = c(0.05, 0.25, 0.50, 0.75, 0.95))

cat("Percentiles de totales promedio:\n")
print(percentiles_totals)

# Identificar outliers
total_stats <- total_stats %>%
  mutate(
    outlier_low = mean_total < percentiles_totals[1],
    outlier_high = mean_total > percentiles_totals[5],
    outlier = outlier_low | outlier_high,
    outlier_type = case_when(
      outlier_low ~ "Low",
      outlier_high ~ "High",
      TRUE ~ "Normal"
    )
  )

# Resumen de outliers
outliers_totals_summary <- total_stats %>%
  group_by(cohort, outlier_type) %>%
  summarise(n_samples = n(), .groups = "drop")

cat("\nResumen de outliers por totales:\n")
print(outliers_totals_summary)

write_csv(total_stats, file.path(output_tables_path, "paso5a_totales_por_muestra.csv"))
write_csv(outliers_totals_summary, file.path(output_tables_path, "paso5a_outliers_totales_resumen.csv"))

# Visualización: Boxplot de totales por cohort
p_totals_boxplot <- ggplot(total_stats, aes(x = cohort, y = mean_total, fill = cohort)) +
  geom_boxplot(outlier.colour = "red", outlier.size = 2) +
  geom_jitter(width = 0.2, alpha = 0.3, size = 0.5) +
  scale_y_log10() +
  geom_hline(yintercept = percentiles_totals[1], linetype = "dashed", color = "blue") +
  geom_hline(yintercept = percentiles_totals[5], linetype = "dashed", color = "blue") +
  labs(title = "Distribución de Totales Promedio por Muestra",
       subtitle = "Líneas azules: percentiles 5% y 95%",
       x = "Cohort", y = "Total Promedio (log10)") +
  theme_minimal()
ggsave(file.path(output_figures_path, "paso5a_distribucion_totales_boxplot.png"), 
       p_totals_boxplot, width = 10, height = 6)

cat("Figura 'paso5a_distribucion_totales_boxplot.png' generada.\n\n")

# =============================================================================
# 4. ANÁLISIS 3: PCA DE VAFs PARA IDENTIFICAR OUTLIERS
# =============================================================================

cat("=== ANÁLISIS 3: PCA DE VAFs ===\n")

# Preparar matriz de VAFs (muestras × SNVs)
# Transponer: necesitamos muestras en filas, SNVs en columnas
vaf_matrix <- filtered_data %>%
  select(all_of(vaf_cols)) %>%
  mutate(across(everything(), as.numeric)) %>%
  as.matrix()

# Transponer para PCA
vaf_matrix_t <- t(vaf_matrix)

# Reemplazar NAs con 0 para PCA
vaf_matrix_t[is.na(vaf_matrix_t)] <- 0

# Verificar que no hay columnas con varianza 0
vaf_matrix_t_clean <- vaf_matrix_t[, apply(vaf_matrix_t, 2, var, na.rm = TRUE) > 0]

cat("Dimensiones de matriz para PCA:\n")
cat("  - Muestras (filas):", nrow(vaf_matrix_t_clean), "\n")
cat("  - SNVs (columnas):", ncol(vaf_matrix_t_clean), "\n")

# Realizar PCA
pca_result <- prcomp(vaf_matrix_t_clean, scale. = TRUE, center = TRUE)

# Extraer scores de PC1 y PC2
pca_scores <- data.frame(
  sample = vaf_cols,
  PC1 = pca_result$x[, 1],
  PC2 = pca_result$x[, 2],
  cohort = ifelse(str_detect(vaf_cols, "ALS"), "ALS", "Control")
)

# Identificar outliers en PCA (distancia de Mahalanobis)
# Calcular distancia euclidiana al centro
pca_scores <- pca_scores %>%
  mutate(
    distance = sqrt(PC1^2 + PC2^2),
    outlier_pca = distance > quantile(distance, 0.95)
  )

# Resumen de outliers PCA
outliers_pca_summary <- pca_scores %>%
  group_by(cohort, outlier_pca) %>%
  summarise(n_samples = n(), .groups = "drop")

cat("\nResumen de outliers por PCA:\n")
print(outliers_pca_summary)

write_csv(pca_scores, file.path(output_tables_path, "paso5a_pca_scores.csv"))

# Visualización: PCA
variance_explained <- summary(pca_result)$importance[2, 1:2] * 100

p_pca <- ggplot(pca_scores, aes(x = PC1, y = PC2, color = cohort, shape = outlier_pca)) +
  geom_point(alpha = 0.6, size = 3) +
  scale_shape_manual(values = c("FALSE" = 16, "TRUE" = 17), 
                     name = "Outlier PCA",
                     labels = c("Normal", "Outlier")) +
  labs(title = "PCA de VAFs por Muestra",
       subtitle = "Identificación de muestras outliers",
       x = paste0("PC1 (", round(variance_explained[1], 1), "% varianza)"),
       y = paste0("PC2 (", round(variance_explained[2], 1), "% varianza)"),
       color = "Cohort") +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave(file.path(output_figures_path, "paso5a_pca_outliers.png"), 
       p_pca, width = 10, height = 8)

cat("Figura 'paso5a_pca_outliers.png' generada.\n\n")

# =============================================================================
# 5. ANÁLISIS 4: PERFILES DE VAFs ANÓMALOS
# =============================================================================

cat("=== ANÁLISIS 4: PERFILES DE VAFs ANÓMALOS ===\n")

# Calcular estadísticas de VAFs por muestra
vaf_stats_per_sample <- filtered_data %>%
  select(all_of(vaf_cols)) %>%
  summarise(across(everything(), 
                   list(
                     mean = ~mean(.x, na.rm = TRUE),
                     median = ~median(.x, na.rm = TRUE),
                     nvalid = ~sum(!is.na(.x) & .x > 0),
                     nna = ~sum(is.na(.x))
                   ))) %>%
  pivot_longer(everything(), names_to = "metric", values_to = "value") %>%
  separate(metric, into = c("sample", "stat"), sep = "_(?=[^_]+$)") %>%
  pivot_wider(names_from = stat, values_from = value)

# Añadir cohort
vaf_stats_per_sample <- vaf_stats_per_sample %>%
  mutate(cohort = ifelse(str_detect(sample, "ALS"), "ALS", "Control"))

# Identificar outliers de VAFs
# Criterio: VAFs promedio muy altos o muy bajos
vaf_percentiles <- quantile(vaf_stats_per_sample$mean, probs = c(0.05, 0.95), na.rm = TRUE)

vaf_stats_per_sample <- vaf_stats_per_sample %>%
  mutate(
    outlier_vaf_low = mean < vaf_percentiles[1],
    outlier_vaf_high = mean > vaf_percentiles[2],
    outlier_vaf = outlier_vaf_low | outlier_vaf_high,
    outlier_type_vaf = case_when(
      outlier_vaf_low ~ "Low_VAF",
      outlier_vaf_high ~ "High_VAF",
      TRUE ~ "Normal"
    )
  )

# Resumen de outliers VAF
outliers_vaf_summary <- vaf_stats_per_sample %>%
  group_by(cohort, outlier_type_vaf) %>%
  summarise(n_samples = n(), .groups = "drop")

cat("\nResumen de outliers por perfil de VAF:\n")
print(outliers_vaf_summary)

write_csv(vaf_stats_per_sample, file.path(output_tables_path, "paso5a_vaf_stats_por_muestra.csv"))
write_csv(outliers_vaf_summary, file.path(output_tables_path, "paso5a_outliers_vaf_resumen.csv"))

# Visualización: VAF promedio vs N de datos válidos
p_vaf_scatter <- ggplot(vaf_stats_per_sample, aes(x = nvalid, y = mean, color = cohort, shape = outlier_vaf)) +
  geom_point(alpha = 0.6, size = 3) +
  scale_shape_manual(values = c("FALSE" = 16, "TRUE" = 17)) +
  scale_y_log10() +
  geom_hline(yintercept = vaf_percentiles[1], linetype = "dashed", color = "blue") +
  geom_hline(yintercept = vaf_percentiles[2], linetype = "dashed", color = "blue") +
  labs(title = "Perfil de VAFs por Muestra",
       subtitle = "VAF promedio vs Número de SNVs válidos",
       x = "Número de VAFs válidos (VAF > 0)",
       y = "VAF Promedio (log10)",
       color = "Cohort",
       shape = "Outlier") +
  theme_minimal()

ggsave(file.path(output_figures_path, "paso5a_vaf_perfil_scatter.png"), 
       p_vaf_scatter, width = 10, height = 8)

cat("Figura 'paso5a_vaf_perfil_scatter.png' generada.\n\n")

# =============================================================================
# 6. CONSOLIDACIÓN DE OUTLIERS
# =============================================================================

cat("=== CONSOLIDACIÓN DE OUTLIERS ===\n")

# Unir todas las categorías de outliers
# Necesitamos hacer match entre count_cols, total_cols (que tienen sufijo), y vaf_cols (que tienen prefijo VAF_)

# Crear dataframe consolidado
outliers_consolidated <- data.frame(
  sample_count = count_cols,
  sample_vaf = vaf_cols,
  cohort = ifelse(str_detect(count_cols, "ALS"), "ALS", "Control")
) %>%
  left_join(
    count_stats %>% select(sample, outlier_low_counts = outlier_low, outlier_high_counts = outlier_high),
    by = c("sample_count" = "sample")
  ) %>%
  left_join(
    total_stats %>% select(sample_clean, outlier_low_totals = outlier_low, outlier_high_totals = outlier_high),
    by = c("sample_count" = "sample_clean")
  ) %>%
  left_join(
    vaf_stats_per_sample %>% select(sample, outlier_vaf_low, outlier_vaf_high),
    by = c("sample_vaf" = "sample")
  ) %>%
  left_join(
    pca_scores %>% select(sample, outlier_pca),
    by = c("sample_vaf" = "sample")
  )

# Identificar muestras que son outliers en AL MENOS un criterio
outliers_consolidated <- outliers_consolidated %>%
  mutate(
    any_outlier = outlier_low_counts | outlier_high_counts | 
                  outlier_low_totals | outlier_high_totals |
                  outlier_vaf_low | outlier_vaf_high |
                  outlier_pca,
    n_outlier_criteria = (outlier_low_counts + outlier_high_counts + 
                          outlier_low_totals + outlier_high_totals +
                          outlier_vaf_low + outlier_vaf_high +
                          outlier_pca)
  )

# Resumen consolidado
outliers_final_summary <- outliers_consolidated %>%
  group_by(cohort) %>%
  summarise(
    total_samples = n(),
    outliers_any = sum(any_outlier, na.rm = TRUE),
    outliers_multiple = sum(n_outlier_criteria >= 2, na.rm = TRUE),
    outliers_severe = sum(n_outlier_criteria >= 3, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    perc_outliers_any = round((outliers_any / total_samples) * 100, 1),
    perc_outliers_multiple = round((outliers_multiple / total_samples) * 100, 1)
  )

cat("\nResumen consolidado de outliers:\n")
print(outliers_final_summary)

write_csv(outliers_consolidated, file.path(output_tables_path, "paso5a_outliers_consolidado.csv"))
write_csv(outliers_final_summary, file.path(output_tables_path, "paso5a_outliers_resumen_final.csv"))

# =============================================================================
# 7. IMPACTO EN MUTACIONES G>T
# =============================================================================

cat("=== EVALUACIÓN DE IMPACTO EN MUTACIONES G>T ===\n")

# Identificar mutaciones G>T
# Primero verificar si la columna pos:mut tiene el patrón correcto
cat("Verificando formato de pos:mut...\n")
cat("Primeras 5 entradas de pos:mut:\n")
print(head(filtered_data$`pos:mut`, 5))

gt_data <- filtered_data %>%
  filter(str_detect(`pos:mut`, "G>T|GT"))

cat("Total de mutaciones G>T en dataset:", nrow(gt_data), "\n")

# Si no se encuentran G>T, intentar con patrón alternativo
if (nrow(gt_data) == 0) {
  cat("No se encontraron G>T con patrón 'G>T'. Intentando patrón alternativo...\n")
  # Mostrar ejemplos de pos:mut para diagnosticar
  cat("Ejemplos de pos:mut únicos (primeros 20):\n")
  print(head(unique(filtered_data$`pos:mut`), 20))
}

# Evaluar impacto si eliminamos muestras outliers
outlier_samples_count <- outliers_consolidated %>%
  filter(any_outlier) %>%
  pull(sample_count)

outlier_samples_vaf <- outliers_consolidated %>%
  filter(any_outlier) %>%
  pull(sample_vaf)

cat("Muestras identificadas como outliers:", length(outlier_samples_count), "\n")

# Calcular cuántos G>T se perderían si eliminamos estas muestras
# Un G>T se "pierde" si solo está presente en muestras outliers

# Para cada G>T, contar en cuántas muestras está presente
gt_presence <- gt_data %>%
  select(all_of(count_cols)) %>%
  mutate(across(everything(), as.numeric)) %>%
  mutate(across(everything(), ~ifelse(is.na(.x) | .x == 0, 0, 1)))

# Contar presencia en muestras normales vs outliers
gt_presence_analysis <- data.frame(
  `miRNA name` = gt_data$`miRNA name`,
  `pos:mut` = gt_data$`pos:mut`,
  n_total_samples = rowSums(gt_presence, na.rm = TRUE),
  n_outlier_samples = rowSums(gt_presence[, colnames(gt_presence) %in% outlier_samples_count], na.rm = TRUE)
) %>%
  mutate(
    n_normal_samples = n_total_samples - n_outlier_samples,
    only_in_outliers = n_normal_samples == 0,
    mostly_in_outliers = n_outlier_samples > n_normal_samples
  )

# Resumen de impacto
gt_impact_summary <- gt_presence_analysis %>%
  summarise(
    total_gt = n(),
    gt_only_in_outliers = sum(only_in_outliers, na.rm = TRUE),
    gt_mostly_in_outliers = sum(mostly_in_outliers, na.rm = TRUE),
    perc_only = round((gt_only_in_outliers / total_gt) * 100, 2),
    perc_mostly = round((gt_mostly_in_outliers / total_gt) * 100, 2)
  )

cat("\nImpacto en mutaciones G>T si eliminamos outliers:\n")
print(gt_impact_summary)

write_csv(gt_presence_analysis, file.path(output_tables_path, "paso5a_gt_impacto_outliers.csv"))
write_csv(gt_impact_summary, file.path(output_tables_path, "paso5a_gt_impacto_resumen.csv"))

# =============================================================================
# 8. IMPACTO EN SNVs SIGNIFICATIVOS
# =============================================================================

cat("=== EVALUACIÓN DE IMPACTO EN SNVs SIGNIFICATIVOS ===\n")

# Cargar resultados de t-tests del Paso 4A
t_test_file <- file.path(config$output_paths$outputs, "paso4a_significancia_estadistica", "paso4a_t_test_results.csv")

if (file.exists(t_test_file)) {
  t_test_results <- read_csv(t_test_file, show_col_types = FALSE)
  
  # Filtrar SNVs significativos
  significant_snvs <- t_test_results %>%
    filter(significance != "ns")
  
  cat("SNVs significativos del Paso 4A:", nrow(significant_snvs), "\n")
  
  # Evaluar cuántos SNVs significativos se verían afectados
  # (esto requeriría re-calcular t-tests sin outliers, por ahora solo reportamos)
  
  cat("\nNota: El impacto exacto en SNVs significativos requiere re-análisis sin outliers.\n")
  cat("Esto se hará en el Paso 5D (Reporte de impacto de filtros).\n")
  
} else {
  cat("No se encontró archivo de t-tests. Saltando análisis de impacto en SNVs significativos.\n")
}

# =============================================================================
# 9. REPORTE EJECUTIVO
# =============================================================================

cat("\n=== GENERANDO REPORTE EJECUTIVO ===\n")

# Crear reporte markdown
report_lines <- c(
  "# REPORTE - PASO 5A: OUTLIERS EN MUESTRAS",
  "",
  "## 📊 RESUMEN EJECUTIVO",
  "",
  paste("**Fecha de análisis:**", Sys.time()),
  paste("**Total de muestras analizadas:**", length(count_cols)),
  paste("**Muestras ALS:**", sum(outliers_consolidated$cohort == "ALS")),
  paste("**Muestras Control:**", sum(outliers_consolidated$cohort == "Control")),
  "",
  "---",
  "",
  "## 🎯 OUTLIERS IDENTIFICADOS",
  "",
  "### Por Counts Totales:",
  paste("- **Outliers bajos (<p5):**", sum(count_stats$outlier_low)),
  paste("- **Outliers altos (>p95):**", sum(count_stats$outlier_high)),
  paste("- **Total:**", sum(count_stats$outlier)),
  "",
  "### Por Totales Promedio:",
  paste("- **Outliers bajos (<p5):**", sum(total_stats$outlier_low)),
  paste("- **Outliers altos (>p95):**", sum(total_stats$outlier_high)),
  paste("- **Total:**", sum(total_stats$outlier)),
  "",
  "### Por PCA:",
  paste("- **Outliers (distancia >p95):**", sum(pca_scores$outlier_pca)),
  "",
  "### Por Perfil de VAFs:",
  paste("- **VAF promedio bajo (<p5):**", sum(vaf_stats_per_sample$outlier_vaf_low, na.rm = TRUE)),
  paste("- **VAF promedio alto (>p95):**", sum(vaf_stats_per_sample$outlier_vaf_high, na.rm = TRUE)),
  "",
  "### Consolidado (al menos 1 criterio):",
  paste("- **Total muestras outliers:**", sum(outliers_consolidated$any_outlier, na.rm = TRUE)),
  paste("  - ALS:", sum(outliers_consolidated$any_outlier & outliers_consolidated$cohort == "ALS", na.rm = TRUE)),
  paste("  - Control:", sum(outliers_consolidated$any_outlier & outliers_consolidated$cohort == "Control", na.rm = TRUE)),
  paste("- **Muestras con ≥2 criterios:**", sum(outliers_consolidated$n_outlier_criteria >= 2, na.rm = TRUE)),
  paste("- **Muestras con ≥3 criterios:**", sum(outliers_consolidated$n_outlier_criteria >= 3, na.rm = TRUE)),
  "",
  "---",
  "",
  "## 🔥 IMPACTO EN MUTACIONES G>T",
  "",
  paste("**Total de mutaciones G>T:**", gt_impact_summary$total_gt),
  paste("**G>T solo en muestras outliers:**", gt_impact_summary$gt_only_in_outliers, 
        "(", gt_impact_summary$perc_only, "%)"),
  paste("**G>T mayormente en outliers:**", gt_impact_summary$gt_mostly_in_outliers, 
        "(", gt_impact_summary$perc_mostly, "%)"),
  "",
  "### Interpretación:",
  "- Si eliminamos muestras outliers, perderíamos directamente **", gt_impact_summary$gt_only_in_outliers, " mutaciones G>T**",
  "- Otras **", gt_impact_summary$gt_mostly_in_outliers, " mutaciones G>T** se verían afectadas (pérdida de potencia estadística)",
  "",
  "---",
  "",
  "## ⚠️ RECOMENDACIONES",
  "",
  "### Muestras outliers:",
  if (sum(outliers_consolidated$any_outlier, na.rm = TRUE) > length(count_cols) * 0.1) {
    "- **ALTA proporción de outliers (>10%)**: Revisar si hay problema técnico o biológico"
  } else {
    "- Proporción razonable de outliers (<10%): Probablemente casos extremos legítimos"
  },
  "",
  "### Impacto en G>T:",
  if (!is.na(gt_impact_summary$perc_only) && gt_impact_summary$perc_only > 5) {
    paste("- **ALTO impacto**: Perderíamos", gt_impact_summary$perc_only, "% de mutaciones G>T")
  } else if (!is.na(gt_impact_summary$perc_only)) {
    paste("- **BAJO impacto**: Solo perderíamos", gt_impact_summary$perc_only, "% de mutaciones G>T")
  } else {
    "- No se detectaron mutaciones G>T (verificar formato de datos)"
  },
  "",
  "### Decisión sugerida:",
  "- **MANTENER todas las muestras por ahora**",
  "- Considerar análisis de sensibilidad (con/sin outliers)",
  "- Revisar outliers severos (≥3 criterios) individualmente",
  "",
  "---",
  "",
  "## 📁 ARCHIVOS GENERADOS",
  "",
  "### Tablas (CSV):",
  "1. `paso5a_counts_por_muestra.csv` - Estadísticas de counts",
  "2. `paso5a_totales_por_muestra.csv` - Estadísticas de totales",
  "3. `paso5a_pca_scores.csv` - Scores de PCA",
  "4. `paso5a_vaf_stats_por_muestra.csv` - Estadísticas de VAFs",
  "5. `paso5a_outliers_consolidado.csv` - Outliers consolidados",
  "6. `paso5a_gt_impacto_outliers.csv` - Impacto en G>T detallado",
  "7. `paso5a_outliers_counts_resumen.csv` - Resumen outliers counts",
  "8. `paso5a_outliers_totales_resumen.csv` - Resumen outliers totales",
  "9. `paso5a_outliers_vaf_resumen.csv` - Resumen outliers VAF",
  "10. `paso5a_gt_impacto_resumen.csv` - Resumen impacto G>T",
  "11. `paso5a_outliers_resumen_final.csv` - Resumen final consolidado",
  "",
  "### Figuras (PNG):",
  "1. `paso5a_distribucion_counts_boxplot.png` - Boxplot de counts",
  "2. `paso5a_distribucion_totales_boxplot.png` - Boxplot de totales",
  "3. `paso5a_pca_outliers.png` - PCA con outliers marcados",
  "4. `paso5a_vaf_perfil_scatter.png` - Perfil de VAFs",
  "",
  "---",
  "",
  "*Análisis completado sin eliminar datos*",
  "*Dataset original preservado íntegramente*"
)

writeLines(report_lines, file.path(output_tables_path, "paso5a_reporte_outliers.md"))

cat("\n=== PASO 5A COMPLETADO ===\n")
cat("Total de archivos generados:\n")
cat("  - Tablas (CSV): 11 archivos\n")
cat("  - Figuras (PNG): 4 archivos\n")
cat("  - Reporte (MD): 1 archivo\n")
cat("\nMuestras outliers identificadas:", sum(outliers_consolidated$any_outlier, na.rm = TRUE), "\n")
cat("Impacto en G>T si eliminamos outliers:", gt_impact_summary$gt_only_in_outliers, "mutaciones\n")
cat("\n⚠️  NINGUNA MUESTRA HA SIDO ELIMINADA\n")
cat("Todos los datos están preservados para análisis posteriores.\n")

