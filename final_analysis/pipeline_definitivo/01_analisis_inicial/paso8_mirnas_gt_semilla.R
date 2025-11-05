#!/usr/bin/env Rscript
# ==============================================================================
# PASO 8: ANÁLISIS DE miRNAs CON G>T EN REGIÓN SEMILLA
# ==============================================================================
# 
# OBJETIVO:
#   Filtrar y analizar en profundidad los miRNAs que tienen mutaciones G>T
#   específicamente en la región semilla (posiciones 1-7), ya que esta región
#   es crítica para el reconocimiento de targets.
#
# INPUT:
#   - datos_con_vafs.csv (del Paso 1A)
#   - paso5a_outliers_consolidado.csv
#   - metadatos integrados (Paso 6A)
#
# OUTPUT:
#   - Figuras:
#       * Lista de miRNAs con G>T en semilla
#       * Distribución de posiciones afectadas
#       * VAFs en estos miRNAs específicos
#       * Comparación ALS vs Control
#       * Cambios temporales en estos miRNAs
#   - Tablas:
#       * miRNAs con G>T en semilla (detallado)
#       * Top miRNAs por número de G>T en semilla
#       * Análisis estadístico (significancia)
#
# AUTOR: Análisis ALS miRNAs
# FECHA: 8 de octubre de 2025
# ==============================================================================

library(tidyverse)
library(DT)
library(jsonlite)

# ------------------------------------------------------------------------------
# CONFIGURACIÓN
# ------------------------------------------------------------------------------

cat("╔════════════════════════════════════════════════════════════════════════╗\n")
cat("║       PASO 8: ANÁLISIS DE miRNAs CON G>T EN REGIÓN SEMILLA            ║\n")
cat("╚════════════════════════════════════════════════════════════════════════╝\n\n")

# Cargar configuración central
source("config_pipeline.R")
source("functions_pipeline.R")

# Crear directorios de salida
output_paso8 <- file.path(config$output_paths$outputs, "paso8_mirnas_gt_semilla")
output_figures_path <- file.path(config$output_paths$figures, "paso8_mirnas_gt_semilla")
dir.create(output_paso8, recursive = TRUE, showWarnings = FALSE)
dir.create(output_figures_path, recursive = TRUE, showWarnings = FALSE)

cat("📁 Directorios de salida creados:\n")
cat("  - Outputs:", output_paso8, "\n")
cat("  - Figuras:", output_figures_path, "\n\n")

# ------------------------------------------------------------------------------
# CARGAR DATOS
# ------------------------------------------------------------------------------

cat("📂 Cargando datos...\n")

# Cargar datos raw y procesarlos (igual que otros pasos)
raw_data_file <- config$data_paths$raw_data
datos_raw <- read_tsv(raw_data_file, show_col_types = FALSE)

cat("  ✓ Datos raw cargados:", nrow(datos_raw), "filas\n")

# Aplicar split-collapse
cat("  → Aplicando split-collapse...\n")
datos_split <- apply_split_collapse(datos_raw)
cat("  ✓ Datos después de split-collapse:", nrow(datos_split), "filas\n")

# Calcular VAFs
cat("  → Calculando VAFs...\n")
datos <- calculate_vafs(datos_split)
cat("  ✓ VAFs calculados\n")

# Filtrar VAFs > 0.5
cat("  → Filtrando VAFs > 0.5...\n")
datos <- filter_high_vafs(datos, threshold = 0.5)
cat("  ✓ Datos filtrados:", nrow(datos), "filas\n")

# Outliers (Paso 5A)
outliers_file <- file.path(config$output_paths$outputs, "paso5a_outliers_muestras", "paso5a_outliers_consolidado.csv")
outliers_data <- read_csv(outliers_file, show_col_types = FALSE)

cat("  ✓ Outliers cargados:", sum(outliers_data$any_outlier), "outliers identificados\n")

# Metadatos (Paso 6A)
metadata_file <- file.path(config$output_paths$outputs, "paso6a_metadatos", "paso6a_metadatos_integrados.csv")
metadata <- read_csv(metadata_file, show_col_types = FALSE)

cat("  ✓ Metadatos cargados:", nrow(metadata), "muestras\n\n")

# ------------------------------------------------------------------------------
# PASO 8.1: FILTRAR miRNAs CON G>T EN REGIÓN SEMILLA
# ------------------------------------------------------------------------------

cat("🌱 PASO 8.1: Filtrando miRNAs con G>T en región semilla...\n")

# Debug: Ver las primeras columnas
cat("  [DEBUG] Columnas disponibles:", paste(head(colnames(datos), 10), collapse = ", "), "\n")
cat("  [DEBUG] ¿Existe 'pos:mut'?:", "pos:mut" %in% colnames(datos), "\n")
cat("  [DEBUG] Primeros valores de 'pos:mut':\n")
print(head(datos$`pos:mut`, 20))

# Extraer mutación y región
# Formato de pos:mut es "18:TC" (posición:mutación_desde_hasta)
datos <- datos %>%
  mutate(
    position = as.integer(str_extract(`pos:mut`, "^\\d+")),
    mutation_raw = str_extract(`pos:mut`, "(?<=:)[ACGT]{2}"),
    from_base = str_sub(mutation_raw, 1, 1),
    to_base = str_sub(mutation_raw, 2, 2),
    mutation_type = paste0(from_base, ">", to_base),
    region = case_when(
      position >= 1 & position <= 7 ~ "Seed",
      position >= 8 & position <= 12 ~ "Central",
      position >= 13 ~ "3prime",
      TRUE ~ "Unknown"
    )
  )

# Debug: Ver distribución de mutation_type
cat("  [DEBUG] Tipos de mutación detectados:\n")
print(table(datos$mutation_type, useNA = "ifany"))

# Filtrar G>T en semilla
gt_seed <- datos %>%
  filter(
    mutation_type == "G>T",
    region == "Seed"
  )

cat("  ✓ SNVs G>T en región semilla:", nrow(gt_seed), "\n")

# Contar miRNAs únicos con G>T en semilla
mirnas_gt_seed <- gt_seed %>%
  distinct(`miRNA name`) %>%
  pull(`miRNA name`)

cat("  ✓ miRNAs únicos con G>T en semilla:", length(mirnas_gt_seed), "\n\n")

# Filtrar dataset completo para estos miRNAs
datos_mirnas_gt_seed <- datos %>%
  filter(`miRNA name` %in% mirnas_gt_seed)

cat("  ✓ Total SNVs en estos miRNAs:", nrow(datos_mirnas_gt_seed), "\n")
cat("    - G>T en semilla:", sum(datos_mirnas_gt_seed$mutation_type == "G>T" & datos_mirnas_gt_seed$region == "Seed"), "\n")
cat("    - Otras mutaciones:", sum(!(datos_mirnas_gt_seed$mutation_type == "G>T" & datos_mirnas_gt_seed$region == "Seed")), "\n\n")

# ------------------------------------------------------------------------------
# PASO 8.2: CARACTERIZAR miRNAs CON G>T EN SEMILLA
# ------------------------------------------------------------------------------

cat("📊 PASO 8.2: Caracterizando miRNAs con G>T en semilla...\n")

# Resumen por miRNA
mirna_summary <- gt_seed %>%
  group_by(`miRNA name`) %>%
  summarise(
    n_gt_seed = n(),
    posiciones_afectadas = paste(sort(unique(position)), collapse = ", "),
    n_posiciones = n_distinct(position),
    tiene_pos6 = 6 %in% position,
    .groups = "drop"
  ) %>%
  arrange(desc(n_gt_seed))

cat("  ✓ Resumen por miRNA generado\n")
cat("    - miRNA con más G>T en semilla:", mirna_summary$`miRNA name`[1], 
    "(", mirna_summary$n_gt_seed[1], "mutaciones)\n")
cat("    - Promedio de G>T por miRNA:", round(mean(mirna_summary$n_gt_seed), 2), "\n")
cat("    - miRNAs con G>T en posición 6:", sum(mirna_summary$tiene_pos6), "\n\n")

# Guardar tabla
write_csv(mirna_summary, file.path(output_paso8, "paso8_mirnas_summary.csv"))

# Tabla interactiva
dt_mirnas <- datatable(
  mirna_summary,
  caption = "miRNAs con mutaciones G>T en región semilla",
  options = list(pageLength = 20, scrollX = TRUE),
  rownames = FALSE
) %>%
  formatStyle(
    'tiene_pos6',
    backgroundColor = styleEqual(c(TRUE, FALSE), c('#ffcccc', 'white'))
  )

saveWidget(dt_mirnas, file.path(output_paso8, "paso8_mirnas_summary_interactive.html"))
cat("  ✓ Tabla interactiva guardada\n\n")

# ------------------------------------------------------------------------------
# PASO 8.3: ANÁLISIS DE POSICIONES AFECTADAS
# ------------------------------------------------------------------------------

cat("📍 PASO 8.3: Analizando posiciones afectadas en semilla...\n")

# Distribución por posición
posiciones_summary <- gt_seed %>%
  group_by(position) %>%
  summarise(
    n_mutations = n(),
    n_mirnas = n_distinct(`miRNA name`),
    .groups = "drop"
  ) %>%
  arrange(position)

cat("  ✓ Distribución por posición:\n")
print(posiciones_summary)

# Gráfica de posiciones
p_posiciones <- ggplot(posiciones_summary, aes(x = factor(position), y = n_mutations)) +
  geom_col(aes(fill = position == 6), show.legend = FALSE) +
  scale_fill_manual(values = c("steelblue", "red")) +
  geom_text(aes(label = n_mutations), vjust = -0.5, size = 4) +
  geom_text(aes(label = paste0(n_mirnas, " miRNAs")), vjust = 1.5, size = 3, color = "white") +
  labs(
    title = "Distribución de G>T en Región Semilla por Posición",
    subtitle = "Posición 6 destacada en rojo",
    x = "Posición en miRNA",
    y = "Número de Mutaciones G>T"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    axis.text = element_text(size = 10)
  )

ggsave(file.path(output_figures_path, "paso8_posiciones_gt_semilla.png"),
       p_posiciones, width = 10, height = 6)
cat("  ✓ Figura 'paso8_posiciones_gt_semilla.png' generada\n\n")

# ------------------------------------------------------------------------------
# PASO 8.4: TOP miRNAs CON G>T EN SEMILLA
# ------------------------------------------------------------------------------

cat("🏆 PASO 8.4: Top miRNAs con más G>T en semilla...\n")

# Top 20 miRNAs
top_mirnas <- mirna_summary %>%
  head(20)

p_top_mirnas <- ggplot(top_mirnas, aes(x = reorder(`miRNA name`, n_gt_seed), y = n_gt_seed)) +
  geom_col(aes(fill = tiene_pos6), show.legend = TRUE) +
  scale_fill_manual(
    values = c("steelblue", "red"),
    labels = c("Sin pos. 6", "Con pos. 6"),
    name = "Posición 6"
  ) +
  geom_text(aes(label = n_gt_seed), hjust = -0.2, size = 3) +
  coord_flip() +
  labs(
    title = "Top 20 miRNAs con más mutaciones G>T en Región Semilla",
    subtitle = "Rojo = contiene mutación en posición 6",
    x = "miRNA",
    y = "Número de G>T en Semilla"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 12),
    axis.text.y = element_text(size = 8)
  )

ggsave(file.path(output_figures_path, "paso8_top20_mirnas_gt_semilla.png"),
       p_top_mirnas, width = 10, height = 8)
cat("  ✓ Figura 'paso8_top20_mirnas_gt_semilla.png' generada\n\n")

# ------------------------------------------------------------------------------
# PASO 8.5: ANÁLISIS DE VAFs EN ESTOS miRNAs
# ------------------------------------------------------------------------------

cat("📊 PASO 8.5: Analizando VAFs en miRNAs con G>T en semilla...\n")

# Identificar columnas VAF
vaf_cols <- grep("^VAF_", colnames(gt_seed), value = TRUE)

# Calcular VAF promedio por SNV
gt_seed_vaf <- gt_seed %>%
  rowwise() %>%
  mutate(
    mean_vaf = mean(c_across(all_of(vaf_cols)), na.rm = TRUE),
    median_vaf = median(c_across(all_of(vaf_cols)), na.rm = TRUE)
  ) %>%
  ungroup()

cat("  ✓ VAF promedio general:", round(mean(gt_seed_vaf$mean_vaf, na.rm = TRUE), 4), "\n")
cat("  ✓ VAF mediana general:", round(median(gt_seed_vaf$median_vaf, na.rm = TRUE), 4), "\n\n")

# Distribución de VAFs
p_vaf_dist <- ggplot(gt_seed_vaf, aes(x = mean_vaf)) +
  geom_histogram(bins = 50, fill = "steelblue", alpha = 0.7) +
  geom_vline(xintercept = mean(gt_seed_vaf$mean_vaf, na.rm = TRUE), 
             color = "red", linetype = "dashed", linewidth = 1) +
  annotate("text", 
           x = mean(gt_seed_vaf$mean_vaf, na.rm = TRUE), 
           y = Inf, 
           label = paste0("Media = ", round(mean(gt_seed_vaf$mean_vaf, na.rm = TRUE), 4)),
           hjust = -0.1, vjust = 2, color = "red", size = 4) +
  labs(
    title = "Distribución de VAFs en G>T de Región Semilla",
    subtitle = paste0("N = ", nrow(gt_seed_vaf), " mutaciones G>T en semilla"),
    x = "VAF Promedio",
    y = "Frecuencia"
  ) +
  theme_minimal()

ggsave(file.path(output_figures_path, "paso8_distribucion_vafs_gt_semilla.png"),
       p_vaf_dist, width = 10, height = 6)
cat("  ✓ Figura 'paso8_distribucion_vafs_gt_semilla.png' generada\n\n")

# VAF por posición
vaf_by_position <- gt_seed_vaf %>%
  group_by(position) %>%
  summarise(
    mean_vaf = mean(mean_vaf, na.rm = TRUE),
    median_vaf = median(median_vaf, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  )

p_vaf_position <- ggplot(vaf_by_position, aes(x = factor(position), y = mean_vaf)) +
  geom_col(aes(fill = position == 6), show.legend = FALSE) +
  scale_fill_manual(values = c("steelblue", "red")) +
  geom_text(aes(label = round(mean_vaf, 4)), vjust = -0.5, size = 3.5) +
  labs(
    title = "VAF Promedio de G>T en Región Semilla por Posición",
    subtitle = "Posición 6 destacada en rojo",
    x = "Posición en miRNA",
    y = "VAF Promedio"
  ) +
  theme_minimal()

ggsave(file.path(output_figures_path, "paso8_vaf_por_posicion_semilla.png"),
       p_vaf_position, width = 10, height = 6)
cat("  ✓ Figura 'paso8_vaf_por_posicion_semilla.png' generada\n\n")

# ------------------------------------------------------------------------------
# PASO 8.6: COMPARACIÓN ALS vs CONTROL
# ------------------------------------------------------------------------------

cat("🔬 PASO 8.6: Comparando ALS vs Control en miRNAs con G>T en semilla...\n")

# Preparar datos para comparación
# Identificar cohort de cada muestra
sample_to_cohort <- metadata %>%
  select(sample, cohort) %>%
  mutate(sample = str_replace_all(sample, "\\.", "-"))

# Crear mapping para columnas VAF
vaf_to_cohort <- tibble(vaf_col = vaf_cols) %>%
  mutate(
    sample = str_replace(vaf_col, "^VAF_", ""),
    sample = str_replace_all(sample, "\\.", "-")
  ) %>%
  left_join(sample_to_cohort, by = "sample")

# Separar columnas por cohort
vaf_als <- vaf_to_cohort %>% filter(cohort == "ALS") %>% pull(vaf_col)
vaf_control <- vaf_to_cohort %>% filter(cohort == "Control") %>% pull(vaf_col)

cat("  ✓ Columnas ALS:", length(vaf_als), "\n")
cat("  ✓ Columnas Control:", length(vaf_control), "\n\n")

# Calcular VAF promedio por grupo
gt_seed_comparison <- gt_seed %>%
  rowwise() %>%
  mutate(
    vaf_als = mean(c_across(all_of(vaf_als)), na.rm = TRUE),
    vaf_control = mean(c_across(all_of(vaf_control)), na.rm = TRUE),
    fold_change = log2(vaf_als / vaf_control)
  ) %>%
  ungroup() %>%
  select(`miRNA name`, `pos:mut`, position, vaf_als, vaf_control, fold_change)

# Scatter plot ALS vs Control
p_als_control <- ggplot(gt_seed_comparison, aes(x = vaf_control, y = vaf_als)) +
  geom_point(aes(color = position == 6), alpha = 0.6, size = 2) +
  scale_color_manual(
    values = c("steelblue", "red"),
    labels = c("Otras posiciones", "Posición 6"),
    name = ""
  ) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "gray30") +
  labs(
    title = "VAFs de G>T en Semilla: ALS vs Control",
    subtitle = paste0("N = ", nrow(gt_seed_comparison), " mutaciones"),
    x = "VAF Promedio Control",
    y = "VAF Promedio ALS"
  ) +
  theme_minimal()

ggsave(file.path(output_figures_path, "paso8_als_vs_control_scatter.png"),
       p_als_control, width = 10, height = 8)
cat("  ✓ Figura 'paso8_als_vs_control_scatter.png' generada\n\n")

# Resumen estadístico
cat("  📈 Resumen ALS vs Control:\n")
cat("    - VAF ALS (media):", round(mean(gt_seed_comparison$vaf_als, na.rm = TRUE), 4), "\n")
cat("    - VAF Control (media):", round(mean(gt_seed_comparison$vaf_control, na.rm = TRUE), 4), "\n")
cat("    - Mayor en ALS:", sum(gt_seed_comparison$vaf_als > gt_seed_comparison$vaf_control, na.rm = TRUE), "\n")
cat("    - Mayor en Control:", sum(gt_seed_comparison$vaf_control > gt_seed_comparison$vaf_als, na.rm = TRUE), "\n\n")

# Guardar comparación
write_csv(gt_seed_comparison, file.path(output_paso8, "paso8_als_vs_control_comparison.csv"))

# ------------------------------------------------------------------------------
# PASO 8.7: ANÁLISIS TEMPORAL (si hay datos longitudinales)
# ------------------------------------------------------------------------------

cat("⏰ PASO 8.7: Analizando cambios temporales en G>T de semilla...\n")

# Identificar muestras longitudinales ALS
longitudinal_samples <- metadata %>%
  filter(cohort == "ALS", is_longitudinal == TRUE)

cat("  ✓ Muestras longitudinales ALS:", nrow(longitudinal_samples), "\n")

if (nrow(longitudinal_samples) > 0) {
  
  # Separar por timepoint
  enrolment_samples <- longitudinal_samples %>% 
    filter(timepoint == "Enrolment") %>%
    mutate(sample_vaf = paste0("VAF_", str_replace_all(sample, "\\.", "-")))
  
  longitudinal_samples_later <- longitudinal_samples %>% 
    filter(timepoint == "Longitudinal") %>%
    mutate(sample_vaf = paste0("VAF_", str_replace_all(sample, "\\.", "-")))
  
  cat("  ✓ Enrolment:", nrow(enrolment_samples), "\n")
  cat("  ✓ Longitudinal:", nrow(longitudinal_samples_later), "\n\n")
  
  # Preparar datos temporales
  vaf_enrolment_cols <- enrolment_samples$sample_vaf
  vaf_longitudinal_cols <- longitudinal_samples_later$sample_vaf
  
  # Filtrar columnas que existen
  vaf_enrolment_cols <- vaf_enrolment_cols[vaf_enrolment_cols %in% colnames(gt_seed)]
  vaf_longitudinal_cols <- vaf_longitudinal_cols[vaf_longitudinal_cols %in% colnames(gt_seed)]
  
  if (length(vaf_enrolment_cols) > 0 & length(vaf_longitudinal_cols) > 0) {
    
    gt_seed_temporal <- gt_seed %>%
      rowwise() %>%
      mutate(
        vaf_enrolment = mean(c_across(all_of(vaf_enrolment_cols)), na.rm = TRUE),
        vaf_longitudinal = mean(c_across(all_of(vaf_longitudinal_cols)), na.rm = TRUE),
        cambio = vaf_longitudinal - vaf_enrolment,
        direccion = case_when(
          cambio > 0 ~ "Aumento",
          cambio < 0 ~ "Disminucion",
          TRUE ~ "Sin cambio"
        )
      ) %>%
      ungroup()
    
    # Scatter plot temporal
    p_temporal <- ggplot(gt_seed_temporal, aes(x = vaf_enrolment, y = vaf_longitudinal)) +
      geom_point(aes(color = position == 6), alpha = 0.6, size = 2) +
      scale_color_manual(
        values = c("steelblue", "red"),
        labels = c("Otras posiciones", "Posición 6"),
        name = ""
      ) +
      geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "gray30") +
      labs(
        title = "Cambios Temporales en G>T de Semilla (ALS)",
        subtitle = "Enrolment vs Longitudinal",
        x = "VAF Enrolment",
        y = "VAF Longitudinal"
      ) +
      theme_minimal()
    
    ggsave(file.path(output_figures_path, "paso8_cambios_temporales_scatter.png"),
           p_temporal, width = 10, height = 8)
    cat("  ✓ Figura 'paso8_cambios_temporales_scatter.png' generada\n")
    
    # Resumen de cambios
    cambios_summary <- gt_seed_temporal %>%
      group_by(direccion) %>%
      summarise(n = n(), .groups = "drop") %>%
      mutate(perc = round(n / sum(n) * 100, 1))
    
    cat("\n  📊 Dirección de cambios temporales:\n")
    print(cambios_summary)
    
    # Guardar datos temporales
    write_csv(gt_seed_temporal %>% select(`miRNA name`, `pos:mut`, position, 
                                          vaf_enrolment, vaf_longitudinal, cambio, direccion),
              file.path(output_paso8, "paso8_cambios_temporales.csv"))
    
  } else {
    cat("  ⚠️ No hay suficientes columnas VAF para análisis temporal\n")
  }
  
} else {
  cat("  ⚠️ No hay muestras longitudinales suficientes para análisis temporal\n")
}

cat("\n")

# ------------------------------------------------------------------------------
# PASO 8.8: RESUMEN EJECUTIVO
# ------------------------------------------------------------------------------

cat("📋 PASO 8.8: Generando resumen ejecutivo...\n")

resumen_ejecutivo <- list(
  total_gt_semilla = nrow(gt_seed),
  n_mirnas = length(mirnas_gt_seed),
  posiciones_afectadas = paste(sort(unique(gt_seed$position)), collapse = ", "),
  n_posiciones = n_distinct(gt_seed$position),
  pos6_mutations = sum(gt_seed$position == 6),
  top_mirna = mirna_summary$`miRNA name`[1],
  top_mirna_n = mirna_summary$n_gt_seed[1],
  vaf_mean = round(mean(gt_seed_vaf$mean_vaf, na.rm = TRUE), 4),
  vaf_median = round(median(gt_seed_vaf$median_vaf, na.rm = TRUE), 4),
  als_mean = round(mean(gt_seed_comparison$vaf_als, na.rm = TRUE), 4),
  control_mean = round(mean(gt_seed_comparison$vaf_control, na.rm = TRUE), 4)
)

# Guardar resumen
write_json(resumen_ejecutivo, 
           file.path(output_paso8, "paso8_resumen_ejecutivo.json"),
           pretty = TRUE)

cat("\n")
cat("╔════════════════════════════════════════════════════════════════════════╗\n")
cat("║                    RESUMEN EJECUTIVO - PASO 8                         ║\n")
cat("╚════════════════════════════════════════════════════════════════════════╝\n\n")

cat("🌱 REGIÓN SEMILLA - G>T:\n")
cat("  • Total G>T en semilla:", resumen_ejecutivo$total_gt_semilla, "\n")
cat("  • miRNAs afectados:", resumen_ejecutivo$n_mirnas, "\n")
cat("  • Posiciones afectadas:", resumen_ejecutivo$posiciones_afectadas, "\n")
cat("  • G>T en posición 6:", resumen_ejecutivo$pos6_mutations, "\n\n")

cat("🏆 TOP miRNA:\n")
cat("  •", resumen_ejecutivo$top_mirna, "con", resumen_ejecutivo$top_mirna_n, "mutaciones\n\n")

cat("📊 VAFs:\n")
cat("  • VAF promedio:", resumen_ejecutivo$vaf_mean, "\n")
cat("  • VAF mediana:", resumen_ejecutivo$vaf_median, "\n\n")

cat("🔬 ALS vs CONTROL:\n")
cat("  • VAF ALS:", resumen_ejecutivo$als_mean, "\n")
cat("  • VAF Control:", resumen_ejecutivo$control_mean, "\n\n")

cat("✅ ANÁLISIS COMPLETADO\n")
cat("  • Figuras generadas: 6-7\n")
cat("  • Tablas guardadas: 3\n")
cat("  • Ubicación:", output_paso8, "\n\n")

cat("════════════════════════════════════════════════════════════════════════\n")

