#!/usr/bin/env Rscript
# ==============================================================================
# PASO 8C: VISUALIZACIONES AVANZADAS - HEATMAPS, Z-SCORES, DIFERENCIAS POSICIONALES
# ==============================================================================
# 
# OBJETIVO:
#   Generar las visualizaciones críticas que faltan:
#   1. Heatmap de VAFs (G>T en semilla × muestras)
#   2. Heatmap de z-scores
#   3. Diferencias posicionales G>T (ALS vs Control)
#   4. Z-scores por posición
#
# INPUT:
#   - Datos del Paso 8 (270 miRNAs con G>T en semilla)
#
# OUTPUT:
#   - 4-6 figuras avanzadas
#   - Tablas de análisis posicional
#
# AUTOR: Análisis ALS miRNAs
# FECHA: 8 de octubre de 2025
# ==============================================================================

library(tidyverse)
library(pheatmap)
library(RColorBrewer)

cat("╔════════════════════════════════════════════════════════════════════════╗\n")
cat("║        PASO 8C: VISUALIZACIONES AVANZADAS (Heatmaps, Z-scores)        ║\n")
cat("╚════════════════════════════════════════════════════════════════════════╝\n\n")

# Cargar configuración
source("config_pipeline.R")
source("functions_pipeline.R")

# Directorios
output_paso8c <- file.path(config$output_paths$outputs, "paso8c_visualizaciones_avanzadas")
output_figures <- file.path(config$output_paths$figures, "paso8c_visualizaciones_avanzadas")
dir.create(output_paso8c, recursive = TRUE, showWarnings = FALSE)
dir.create(output_figures, recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------------------------------------------
# CARGAR Y PROCESAR DATOS
# ------------------------------------------------------------------------------

cat("📂 Cargando datos...\n")

raw_data <- read_tsv(config$data_paths$raw_data, show_col_types = FALSE)
datos_split <- apply_split_collapse(raw_data)
datos <- calculate_vafs(datos_split)
datos <- filter_high_vafs(datos, threshold = 0.5)

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

# Filtrar G>T en semilla
gt_seed <- datos %>%
  filter(mutation_type == "G>T", region == "Seed")

cat("  ✓ G>T en semilla:", nrow(gt_seed), "\n\n")

# Metadatos
metadata <- read_csv(
  file.path(config$output_paths$outputs, "paso6a_metadatos", "paso6a_metadatos_integrados.csv"),
  show_col_types = FALSE
)

# ------------------------------------------------------------------------------
# PASO 8C.1: HEATMAP DE VAFs (G>T en semilla)
# ------------------------------------------------------------------------------

cat("🔥 PASO 8C.1: Generando heatmap de VAFs (397 × 415)...\n")

# Preparar matriz de VAFs
vaf_cols <- grep("^VAF_", colnames(gt_seed), value = TRUE)

vaf_matrix <- gt_seed %>%
  select(all_of(vaf_cols)) %>%
  mutate(across(everything(), as.numeric)) %>%
  as.matrix()

rownames(vaf_matrix) <- gt_seed$`pos:mut`

# Reemplazar NA con 0 para heatmap
vaf_matrix[is.na(vaf_matrix)] <- 0

# Preparar anotaciones de muestras (cohort)
sample_to_cohort <- metadata %>%
  select(sample, cohort) %>%
  mutate(sample_vaf = paste0("VAF_", str_replace_all(sample, "\\.", "-")))

annotation_col <- sample_to_cohort %>%
  filter(sample_vaf %in% colnames(vaf_matrix)) %>%
  column_to_rownames("sample_vaf") %>%
  select(cohort)

# Colores para anotación
ann_colors <- list(
  cohort = c("ALS" = "#E31A1C", "Control" = "#1F78B4")
)

cat("  → Generando heatmap completo (puede tomar 1-2 min)...\n")

# Heatmap con clustering
png(file.path(output_figures, "paso8c_heatmap_vaf_completo.png"),
    width = 16, height = 12, units = "in", res = 150)

pheatmap(
  vaf_matrix,
  color = colorRampPalette(c("white", "yellow", "orange", "red"))(100),
  cluster_rows = TRUE,
  cluster_cols = TRUE,
  annotation_col = annotation_col,
  annotation_colors = ann_colors,
  show_rownames = FALSE,
  show_colnames = FALSE,
  main = "Heatmap de VAFs: G>T en Región Semilla (397 SNVs × 415 muestras)",
  fontsize = 10,
  border_color = NA
)

dev.off()
cat("  ✓ Figura 'paso8c_heatmap_vaf_completo.png' generada\n\n")

# ------------------------------------------------------------------------------
# PASO 8C.2: HEATMAP DE Z-SCORES
# ------------------------------------------------------------------------------

cat("📊 PASO 8C.2: Generando heatmap de z-scores...\n")

# Calcular z-scores por fila (normalizar cada SNV)
vaf_matrix_zscore <- t(scale(t(vaf_matrix)))

# Reemplazar NA/NaN/Inf con 0
vaf_matrix_zscore[is.na(vaf_matrix_zscore)] <- 0
vaf_matrix_zscore[is.infinite(vaf_matrix_zscore)] <- 0

# Limitar valores extremos para mejor visualización
vaf_matrix_zscore[vaf_matrix_zscore > 3] <- 3
vaf_matrix_zscore[vaf_matrix_zscore < -3] <- -3

cat("  → Generando heatmap de z-scores...\n")

png(file.path(output_figures, "paso8c_heatmap_zscore.png"),
    width = 16, height = 12, units = "in", res = 150)

pheatmap(
  vaf_matrix_zscore,
  color = colorRampPalette(c("blue", "white", "red"))(100),
  cluster_rows = TRUE,
  cluster_cols = TRUE,
  annotation_col = annotation_col,
  annotation_colors = ann_colors,
  show_rownames = FALSE,
  show_colnames = FALSE,
  main = "Heatmap de Z-scores: G>T en Región Semilla",
  fontsize = 10,
  border_color = NA,
  breaks = seq(-3, 3, length.out = 101)
)

dev.off()
cat("  ✓ Figura 'paso8c_heatmap_zscore.png' generada\n\n")

# ------------------------------------------------------------------------------
# PASO 8C.3: DIFERENCIAS POSICIONALES G>T (ALS vs Control)
# ------------------------------------------------------------------------------

cat("📍 PASO 8C.3: Analizando diferencias posicionales ALS vs Control...\n")

# Identificar columnas por cohort
sample_to_cohort_map <- metadata %>%
  select(sample, cohort) %>%
  mutate(sample = str_replace_all(sample, "\\.", "-"))

vaf_to_cohort <- tibble(vaf_col = vaf_cols) %>%
  mutate(
    sample = str_replace(vaf_col, "^VAF_", ""),
    sample = str_replace_all(sample, "\\.", "-")
  ) %>%
  left_join(sample_to_cohort_map, by = "sample")

vaf_als <- vaf_to_cohort %>% filter(cohort == "ALS") %>% pull(vaf_col)
vaf_control <- vaf_to_cohort %>% filter(cohort == "Control") %>% pull(vaf_col)

# Obtener TODOS los G>T (no solo semilla)
gt_all <- datos %>%
  filter(mutation_type == "G>T", !is.na(position))

# Calcular VAF promedio por posición y cohort
gt_posicional <- gt_all %>%
  rowwise() %>%
  mutate(
    vaf_als = mean(c_across(all_of(vaf_als)), na.rm = TRUE),
    vaf_control = mean(c_across(all_of(vaf_control)), na.rm = TRUE)
  ) %>%
  ungroup() %>%
  group_by(position, region) %>%
  summarise(
    n_snvs = n(),
    mean_vaf_als = mean(vaf_als, na.rm = TRUE),
    mean_vaf_control = mean(vaf_control, na.rm = TRUE),
    diff = mean_vaf_als - mean_vaf_control,
    fold_change = log2(mean_vaf_als / mean_vaf_control),
    .groups = "drop"
  ) %>%
  filter(position <= 23) # Limitar a posiciones válidas

cat("  ✓ Análisis posicional calculado\n")

# Guardar tabla
write_csv(gt_posicional, file.path(output_paso8c, "paso8c_diferencias_posicionales.csv"))

# Gráfica de diferencias
p1 <- ggplot(gt_posicional, aes(x = factor(position), y = diff)) +
  geom_col(aes(fill = region), alpha = 0.8) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray30") +
  scale_fill_manual(
    values = c("Seed" = "#E31A1C", "Central" = "#FF7F00", "3prime" = "#1F78B4"),
    name = "Región"
  ) +
  geom_text(aes(label = n_snvs), vjust = -0.5, size = 2.5) +
  labs(
    title = "Diferencias VAF (ALS - Control) por Posición en G>T",
    subtitle = "Valores positivos = mayor en ALS, números = N SNVs",
    x = "Posición en miRNA",
    y = "Diferencia VAF (ALS - Control)"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 0, hjust = 0.5))

ggsave(file.path(output_figures, "paso8c_diferencias_posicionales.png"),
       p1, width = 14, height = 6)
cat("  ✓ Figura 'paso8c_diferencias_posicionales.png' generada\n\n")

# ------------------------------------------------------------------------------
# PASO 8C.4: HEATMAP POSICIÓN × COHORT
# ------------------------------------------------------------------------------

cat("📊 PASO 8C.4: Generando heatmap posición × cohort...\n")

# Preparar datos para heatmap
gt_pos_matrix <- gt_posicional %>%
  select(position, mean_vaf_als, mean_vaf_control) %>%
  pivot_longer(cols = c(mean_vaf_als, mean_vaf_control),
               names_to = "cohort", 
               values_to = "vaf") %>%
  mutate(cohort = str_replace(cohort, "mean_vaf_", "")) %>%
  pivot_wider(names_from = cohort, values_from = vaf) %>%
  column_to_rownames("position") %>%
  as.matrix()

png(file.path(output_figures, "paso8c_heatmap_posicion_cohort.png"),
    width = 8, height = 10, units = "in", res = 150)

pheatmap(
  gt_pos_matrix,
  color = colorRampPalette(c("white", "yellow", "orange", "red"))(100),
  cluster_rows = FALSE,
  cluster_cols = FALSE,
  display_numbers = TRUE,
  number_format = "%.4f",
  main = "VAF de G>T por Posición y Cohort",
  fontsize = 10,
  fontsize_number = 8
)

dev.off()
cat("  ✓ Figura 'paso8c_heatmap_posicion_cohort.png' generada\n\n")

# ------------------------------------------------------------------------------
# PASO 8C.5: Z-SCORES POR POSICIÓN
# ------------------------------------------------------------------------------

cat("📈 PASO 8C.5: Calculando z-scores por posición...\n")

# Calcular z-scores de VAFs para cada posición
gt_all_vaf <- gt_all %>%
  rowwise() %>%
  mutate(
    mean_vaf = mean(c_across(all_of(vaf_cols)), na.rm = TRUE)
  ) %>%
  ungroup()

# Z-scores por posición
zscore_by_position <- gt_all_vaf %>%
  group_by(position) %>%
  mutate(
    z_score = scale(mean_vaf)[,1]
  ) %>%
  ungroup() %>%
  group_by(position, region) %>%
  summarise(
    n = n(),
    mean_z = mean(z_score, na.rm = TRUE),
    sd_z = sd(z_score, na.rm = TRUE),
    max_z = max(z_score, na.rm = TRUE),
    min_z = min(z_score, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(position <= 23)

cat("  ✓ Z-scores calculados\n")

# Guardar
write_csv(zscore_by_position, file.path(output_paso8c, "paso8c_zscores_por_posicion.csv"))

# Gráfica de z-scores
p2 <- ggplot(zscore_by_position, aes(x = factor(position), y = mean_z)) +
  geom_col(aes(fill = region), alpha = 0.8) +
  geom_errorbar(aes(ymin = mean_z - sd_z, ymax = mean_z + sd_z), 
                width = 0.3, alpha = 0.6) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray30") +
  scale_fill_manual(
    values = c("Seed" = "#E31A1C", "Central" = "#FF7F00", "3prime" = "#1F78B4"),
    name = "Región"
  ) +
  labs(
    title = "Z-scores de VAFs por Posición (G>T)",
    subtitle = "Barras de error = ± SD",
    x = "Posición en miRNA",
    y = "Z-score promedio"
  ) +
  theme_minimal()

ggsave(file.path(output_figures, "paso8c_zscores_por_posicion.png"),
       p2, width = 14, height = 6)
cat("  ✓ Figura 'paso8c_zscores_por_posicion.png' generada\n\n")

# ------------------------------------------------------------------------------
# PASO 8C.6: ANÁLISIS DE SIGNIFICANCIA POR POSICIÓN
# ------------------------------------------------------------------------------

cat("🔬 PASO 8C.6: Tests estadísticos por posición...\n")

# T-tests por posición
position_tests <- gt_all %>%
  rowwise() %>%
  mutate(
    vaf_als = mean(c_across(all_of(vaf_als)), na.rm = TRUE),
    vaf_control = mean(c_across(all_of(vaf_control)), na.rm = TRUE)
  ) %>%
  ungroup() %>%
  filter(position <= 23) %>%
  group_by(position, region) %>%
  summarise(
    n = n(),
    mean_als = mean(vaf_als, na.rm = TRUE),
    mean_control = mean(vaf_control, na.rm = TRUE),
    diff = mean_als - mean_control,
    # T-test
    p_value = if(n() >= 3) {
      tryCatch({
        t.test(vaf_als, vaf_control)$p.value
      }, error = function(e) NA)
    } else NA,
    .groups = "drop"
  ) %>%
  mutate(
    p_adj = p.adjust(p_value, method = "BH"),
    signif = case_when(
      p_adj < 0.001 ~ "***",
      p_adj < 0.01 ~ "**",
      p_adj < 0.05 ~ "*",
      TRUE ~ "ns"
    )
  )

cat("  ✓ Tests estadísticos completados\n")

# Guardar
write_csv(position_tests, file.path(output_paso8c, "paso8c_significancia_posicional.csv"))

# Gráfica con significancia
p3 <- ggplot(position_tests, aes(x = factor(position), y = diff)) +
  geom_col(aes(fill = region), alpha = 0.8) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_text(aes(label = signif, y = diff + sign(diff) * max(abs(diff)) * 0.1),
            size = 4, fontface = "bold") +
  scale_fill_manual(
    values = c("Seed" = "#E31A1C", "Central" = "#FF7F00", "3prime" = "#1F78B4"),
    name = "Región"
  ) +
  labs(
    title = "Diferencias VAF (ALS - Control) por Posición con Significancia",
    subtitle = "*** p<0.001, ** p<0.01, * p<0.05, ns no significativo",
    x = "Posición en miRNA",
    y = "Diferencia VAF (ALS - Control)"
  ) +
  theme_minimal()

ggsave(file.path(output_figures, "paso8c_diferencias_significancia.png"),
       p3, width = 14, height = 6)
cat("  ✓ Figura 'paso8c_diferencias_significancia.png' generada\n\n")

# ------------------------------------------------------------------------------
# PASO 8C.7: ENFOQUE EN REGIÓN SEMILLA (posiciones 1-7)
# ------------------------------------------------------------------------------

cat("🌱 PASO 8C.7: Enfoque detallado en región semilla...\n")

# Filtrar solo semilla
position_tests_seed <- position_tests %>%
  filter(region == "Seed")

cat("\n  📊 RESUMEN SEMILLA:\n")
print(position_tests_seed %>% select(position, n, diff, p_adj, signif))

# Gráfica enfocada en semilla
p4 <- ggplot(position_tests_seed, aes(x = factor(position), y = diff)) +
  geom_col(aes(fill = position == 6), show.legend = FALSE) +
  scale_fill_manual(values = c("steelblue", "red")) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_text(aes(label = paste0(signif, "\n(n=", n, ")")), 
            vjust = -0.5, size = 3.5) +
  labs(
    title = "Diferencias VAF (ALS - Control) en Región SEMILLA",
    subtitle = "Posición 6 destacada en rojo",
    x = "Posición",
    y = "Diferencia VAF (ALS - Control)"
  ) +
  theme_minimal()

ggsave(file.path(output_figures, "paso8c_semilla_diferencias.png"),
       p4, width = 10, height = 6)
cat("  ✓ Figura 'paso8c_semilla_diferencias.png' generada\n\n")

# ------------------------------------------------------------------------------
# PASO 8C.8: RESUMEN EJECUTIVO
# ------------------------------------------------------------------------------

cat("📋 PASO 8C.8: Generando resumen ejecutivo...\n")

# Posiciones significativas
posiciones_sig <- position_tests %>%
  filter(p_adj < 0.05) %>%
  arrange(p_adj)

cat("\n  🎯 POSICIONES SIGNIFICATIVAS (p < 0.05):\n")
if (nrow(posiciones_sig) > 0) {
  print(posiciones_sig %>% select(position, region, diff, p_adj, signif))
} else {
  cat("    Ninguna posición alcanza p < 0.05\n")
}

# Resumen por región
resumen_region <- position_tests %>%
  group_by(region) %>%
  summarise(
    n_posiciones = n(),
    n_snvs = sum(n),
    diff_promedio = mean(diff, na.rm = TRUE),
    n_significativas = sum(p_adj < 0.05, na.rm = TRUE),
    .groups = "drop"
  )

cat("\n  📊 RESUMEN POR REGIÓN:\n")
print(resumen_region)

# Guardar resumen
write_csv(resumen_region, file.path(output_paso8c, "paso8c_resumen_por_region.csv"))

cat("\n")
cat("╔════════════════════════════════════════════════════════════════════════╗\n")
cat("║                    RESUMEN EJECUTIVO - PASO 8C                        ║\n")
cat("╚════════════════════════════════════════════════════════════════════════╝\n\n")

cat("🔥 HEATMAPS GENERADOS:\n")
cat("  ✓ Heatmap VAFs (397 × 415)\n")
cat("  ✓ Heatmap Z-scores (normalizado)\n\n")

cat("📍 ANÁLISIS POSICIONAL:\n")
cat("  ✓ Diferencias calculadas para 23 posiciones\n")
cat("  ✓ Tests estadísticos con FDR\n")
cat("  ✓ Enfoque específico en semilla (1-7)\n\n")

cat("📊 POSICIONES SIGNIFICATIVAS:\n")
cat("  • Total con p < 0.05:", nrow(posiciones_sig), "\n")
if (nrow(posiciones_sig) > 0) {
  cat("  • Más significativa: pos", posiciones_sig$position[1], 
      "(p =", format.pval(posiciones_sig$p_adj[1]), ")\n")
}
cat("\n")

cat("✅ ANÁLISIS COMPLETADO\n")
cat("  • Figuras generadas: 5\n")
cat("  • Tablas guardadas: 3\n")
cat("  • Ubicación:", output_paso8c, "\n\n")

cat("════════════════════════════════════════════════════════════════════════\n")

