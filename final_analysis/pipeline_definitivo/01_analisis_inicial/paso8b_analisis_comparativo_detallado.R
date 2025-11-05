#!/usr/bin/env Rscript
# ==============================================================================
# PASO 8B: ANÁLISIS COMPARATIVO DETALLADO - GT vs RESTO en miRNAs con GT semilla
# ==============================================================================
# 
# OBJETIVO:
#   Analizar en profundidad los 12,914 SNVs de los 270 miRNAs con G>T en semilla:
#   1. Comparar G>T vs otras mutaciones (características, VAFs, distribución)
#   2. Analizar distribución ALS vs Control en ambos grupos
#   3. Comparar por región funcional
#
# INPUT:
#   - Datos del Paso 8 (270 miRNAs con G>T en semilla)
#
# OUTPUT:
#   - Figuras comparativas
#   - Tablas de estadísticas
#   - Resumen ejecutivo
#
# AUTOR: Análisis ALS miRNAs
# FECHA: 8 de octubre de 2025
# ==============================================================================

library(tidyverse)
library(jsonlite)

cat("╔════════════════════════════════════════════════════════════════════════╗\n")
cat("║    PASO 8B: ANÁLISIS COMPARATIVO GT vs RESTO (miRNAs con GT semilla)  ║\n")
cat("╚════════════════════════════════════════════════════════════════════════╝\n\n")

# Cargar configuración
source("config_pipeline.R")
source("functions_pipeline.R")

# Directorios
output_paso8b <- file.path(config$output_paths$outputs, "paso8b_comparativo_detallado")
output_figures <- file.path(config$output_paths$figures, "paso8b_comparativo_detallado")
dir.create(output_paso8b, recursive = TRUE, showWarnings = FALSE)
dir.create(output_figures, recursive = TRUE, showWarnings = FALSE)

cat("📁 Directorios creados\n\n")

# ------------------------------------------------------------------------------
# CARGAR DATOS
# ------------------------------------------------------------------------------

cat("📂 Cargando datos procesados...\n")

# Datos raw
raw_data <- read_tsv(config$data_paths$raw_data, show_col_types = FALSE)
datos_split <- apply_split_collapse(raw_data)
datos <- calculate_vafs(datos_split)
datos <- filter_high_vafs(datos, threshold = 0.5)

# Procesar para análisis
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

# Metadatos
metadata <- read_csv(
  file.path(config$output_paths$outputs, "paso6a_metadatos", "paso6a_metadatos_integrados.csv"),
  show_col_types = FALSE
)

# Filtrar por los 270 miRNAs con G>T en semilla
mirnas_gt_seed <- datos %>%
  filter(mutation_type == "G>T", region == "Seed") %>%
  distinct(`miRNA name`) %>%
  pull(`miRNA name`)

datos_270 <- datos %>%
  filter(`miRNA name` %in% mirnas_gt_seed)

cat("  ✓ 270 miRNAs con G>T en semilla\n")
cat("  ✓ Total SNVs en estos miRNAs:", nrow(datos_270), "\n\n")

# ------------------------------------------------------------------------------
# PASO 8B.1: CLASIFICAR SNVs (G>T vs RESTO)
# ------------------------------------------------------------------------------

cat("📊 PASO 8B.1: Clasificando SNVs por tipo...\n")

# Clasificar G>T vs resto
datos_270 <- datos_270 %>%
  mutate(
    snv_class = case_when(
      mutation_type == "G>T" ~ "G>T",
      TRUE ~ "Otras"
    )
  )

# Resumen general
resumen_tipos <- datos_270 %>%
  group_by(snv_class) %>%
  summarise(
    n_snvs = n(),
    n_mirnas = n_distinct(`miRNA name`),
    .groups = "drop"
  ) %>%
  mutate(perc = round(n_snvs / sum(n_snvs) * 100, 1))

cat("\n  📈 DISTRIBUCIÓN DE SNVs:\n")
print(resumen_tipos)

# Por región
resumen_region <- datos_270 %>%
  group_by(region, snv_class) %>%
  summarise(n = n(), .groups = "drop") %>%
  pivot_wider(names_from = snv_class, values_from = n, values_fill = 0) %>%
  mutate(
    total = `G>T` + Otras,
    perc_gt = round(`G>T` / total * 100, 1)
  )

cat("\n  📍 POR REGIÓN:\n")
print(resumen_region)

# Gráfica de distribución
p1 <- ggplot(datos_270, aes(x = region, fill = snv_class)) +
  geom_bar(position = "dodge") +
  scale_fill_manual(
    values = c("G>T" = "#E31A1C", "Otras" = "#1F78B4"),
    name = "Tipo de SNV"
  ) +
  labs(
    title = "Distribución de SNVs por Región",
    subtitle = "En 270 miRNAs con G>T en semilla",
    x = "Región Funcional",
    y = "Número de SNVs"
  ) +
  theme_minimal()

ggsave(file.path(output_figures, "paso8b_snvs_por_region.png"),
       p1, width = 10, height = 6)
cat("\n  ✓ Figura 'paso8b_snvs_por_region.png' generada\n\n")

# ------------------------------------------------------------------------------
# PASO 8B.2: ANÁLISIS DE VAFs (G>T vs RESTO)
# ------------------------------------------------------------------------------

cat("📊 PASO 8B.2: Comparando VAFs entre G>T y otras mutaciones...\n")

# Identificar columnas VAF
vaf_cols <- grep("^VAF_", colnames(datos_270), value = TRUE)

# Calcular VAF promedio por SNV
datos_270_vaf <- datos_270 %>%
  rowwise() %>%
  mutate(
    mean_vaf = mean(c_across(all_of(vaf_cols)), na.rm = TRUE),
    median_vaf = median(c_across(all_of(vaf_cols)), na.rm = TRUE),
    n_valid = sum(!is.na(c_across(all_of(vaf_cols))))
  ) %>%
  ungroup()

# Estadísticas por tipo
vaf_stats <- datos_270_vaf %>%
  group_by(snv_class) %>%
  summarise(
    n = n(),
    mean_vaf = mean(mean_vaf, na.rm = TRUE),
    median_vaf = median(median_vaf, na.rm = TRUE),
    sd_vaf = sd(mean_vaf, na.rm = TRUE),
    .groups = "drop"
  )

cat("\n  📈 VAFs POR TIPO:\n")
print(vaf_stats)

# Test estadístico
test_vaf <- wilcox.test(
  mean_vaf ~ snv_class,
  data = datos_270_vaf %>% filter(snv_class %in% c("G>T", "Otras"))
)

cat("\n  🔬 Test Wilcoxon G>T vs Otras:\n")
cat("    p-value =", format.pval(test_vaf$p.value), "\n\n")

# Boxplot comparativo
p2 <- ggplot(datos_270_vaf, aes(x = snv_class, y = mean_vaf, fill = snv_class)) +
  geom_boxplot(alpha = 0.7, outlier.size = 0.5) +
  scale_fill_manual(
    values = c("G>T" = "#E31A1C", "Otras" = "#1F78B4"),
    name = ""
  ) +
  labs(
    title = "Comparación de VAFs: G>T vs Otras Mutaciones",
    subtitle = sprintf("p-value = %s (Wilcoxon)", format.pval(test_vaf$p.value)),
    x = "Tipo de Mutación",
    y = "VAF Promedio"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

ggsave(file.path(output_figures, "paso8b_vaf_gt_vs_otras.png"),
       p2, width = 8, height = 6)
cat("  ✓ Figura 'paso8b_vaf_gt_vs_otras.png' generada\n\n")

# ------------------------------------------------------------------------------
# PASO 8B.3: DISTRIBUCIÓN ALS vs CONTROL (por tipo de SNV)
# ------------------------------------------------------------------------------

cat("📊 PASO 8B.3: Analizando distribución ALS vs Control...\n")

# Mapping de muestras a cohort
sample_to_cohort <- metadata %>%
  select(sample, cohort) %>%
  mutate(sample = str_replace_all(sample, "\\.", "-"))

vaf_to_cohort <- tibble(vaf_col = vaf_cols) %>%
  mutate(
    sample = str_replace(vaf_col, "^VAF_", ""),
    sample = str_replace_all(sample, "\\.", "-")
  ) %>%
  left_join(sample_to_cohort, by = "sample")

vaf_als <- vaf_to_cohort %>% filter(cohort == "ALS") %>% pull(vaf_col)
vaf_control <- vaf_to_cohort %>% filter(cohort == "Control") %>% pull(vaf_col)

# Calcular VAF por cohort y tipo
datos_als_control <- datos_270 %>%
  rowwise() %>%
  mutate(
    vaf_als = mean(c_across(all_of(vaf_als)), na.rm = TRUE),
    vaf_control = mean(c_across(all_of(vaf_control)), na.rm = TRUE),
    diff_als_control = vaf_als - vaf_control,
    mayor_en = case_when(
      vaf_als > vaf_control ~ "ALS",
      vaf_control > vaf_als ~ "Control",
      TRUE ~ "Igual"
    )
  ) %>%
  ungroup()

# Resumen por tipo de SNV
resumen_cohort <- datos_als_control %>%
  group_by(snv_class, mayor_en) %>%
  summarise(n = n(), .groups = "drop") %>%
  pivot_wider(names_from = mayor_en, values_from = n, values_fill = 0) %>%
  mutate(
    total = ALS + Control + Igual,
    perc_als = round(ALS / total * 100, 1),
    perc_control = round(Control / total * 100, 1)
  )

cat("\n  📈 DISTRIBUCIÓN ALS vs CONTROL:\n")
print(resumen_cohort)

# Gráfica comparativa
p3 <- ggplot(datos_als_control, aes(x = vaf_control, y = vaf_als)) +
  geom_point(aes(color = snv_class), alpha = 0.5, size = 1.5) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "gray30") +
  scale_color_manual(
    values = c("G>T" = "#E31A1C", "Otras" = "#1F78B4"),
    name = "Tipo de SNV"
  ) +
  facet_wrap(~snv_class, ncol = 2) +
  labs(
    title = "VAFs: ALS vs Control por Tipo de SNV",
    subtitle = "En 270 miRNAs con G>T en semilla",
    x = "VAF Promedio Control",
    y = "VAF Promedio ALS"
  ) +
  theme_minimal()

ggsave(file.path(output_figures, "paso8b_als_vs_control_por_tipo.png"),
       p3, width = 12, height = 6)
cat("  ✓ Figura 'paso8b_als_vs_control_por_tipo.png' generada\n\n")

# ------------------------------------------------------------------------------
# PASO 8B.4: ANÁLISIS POR REGIÓN (G>T vs RESTO, ALS vs CONTROL)
# ------------------------------------------------------------------------------

cat("📊 PASO 8B.4: Análisis por región funcional...\n")

# VAF promedio por región, tipo y cohort
vaf_region <- datos_als_control %>%
  group_by(region, snv_class) %>%
  summarise(
    n = n(),
    vaf_als = mean(vaf_als, na.rm = TRUE),
    vaf_control = mean(vaf_control, na.rm = TRUE),
    diff = vaf_als - vaf_control,
    .groups = "drop"
  )

cat("\n  📍 VAFs POR REGIÓN Y TIPO:\n")
print(vaf_region)

# Heatmap
p4 <- ggplot(vaf_region, aes(x = snv_class, y = region, fill = diff)) +
  geom_tile(color = "white") +
  geom_text(aes(label = round(diff, 4)), size = 3) +
  scale_fill_gradient2(
    low = "#1F78B4", mid = "white", high = "#E31A1C",
    midpoint = 0,
    name = "Diff\n(ALS-Control)"
  ) +
  labs(
    title = "Diferencia VAF (ALS - Control) por Región y Tipo",
    subtitle = "Valores positivos = mayor en ALS",
    x = "Tipo de SNV",
    y = "Región"
  ) +
  theme_minimal()

ggsave(file.path(output_figures, "paso8b_heatmap_region_tipo.png"),
       p4, width = 8, height = 6)
cat("  ✓ Figura 'paso8b_heatmap_region_tipo.png' generada\n\n")

# ------------------------------------------------------------------------------
# PASO 8B.5: RESUMEN EJECUTIVO
# ------------------------------------------------------------------------------

cat("📋 PASO 8B.5: Generando resumen ejecutivo...\n")

resumen <- list(
  total_snvs = nrow(datos_270),
  n_gt = sum(datos_270$snv_class == "G>T"),
  n_otras = sum(datos_270$snv_class == "Otras"),
  perc_gt = round(sum(datos_270$snv_class == "G>T") / nrow(datos_270) * 100, 1),
  
  vaf_gt_mean = vaf_stats$mean_vaf[vaf_stats$snv_class == "G>T"],
  vaf_otras_mean = vaf_stats$mean_vaf[vaf_stats$snv_class == "Otras"],
  test_pvalue = test_vaf$p.value,
  
  gt_perc_als = resumen_cohort$perc_als[resumen_cohort$snv_class == "G>T"],
  gt_perc_control = resumen_cohort$perc_control[resumen_cohort$snv_class == "G>T"],
  otras_perc_als = resumen_cohort$perc_als[resumen_cohort$snv_class == "Otras"],
  otras_perc_control = resumen_cohort$perc_control[resumen_cohort$snv_class == "Otras"]
)

write_json(resumen, file.path(output_paso8b, "paso8b_resumen.json"), pretty = TRUE)

# Guardar tablas
write_csv(resumen_tipos, file.path(output_paso8b, "paso8b_tipos_snv.csv"))
write_csv(resumen_region, file.path(output_paso8b, "paso8b_region_tipo.csv"))
write_csv(resumen_cohort, file.path(output_paso8b, "paso8b_cohort_tipo.csv"))
write_csv(vaf_region, file.path(output_paso8b, "paso8b_vaf_region_tipo_cohort.csv"))

cat("\n")
cat("╔════════════════════════════════════════════════════════════════════════╗\n")
cat("║                    RESUMEN EJECUTIVO - PASO 8B                        ║\n")
cat("╚════════════════════════════════════════════════════════════════════════╝\n\n")

cat("📊 COMPOSICIÓN DE SNVs:\n")
cat("  • Total SNVs:", resumen$total_snvs, "\n")
cat("  • G>T:", resumen$n_gt, sprintf("(%.1f%%)", resumen$perc_gt), "\n")
cat("  • Otras:", resumen$n_otras, sprintf("(%.1f%%)", 100 - resumen$perc_gt), "\n\n")

cat("📈 VAFs:\n")
cat("  • G>T promedio:", round(resumen$vaf_gt_mean, 4), "\n")
cat("  • Otras promedio:", round(resumen$vaf_otras_mean, 4), "\n")
cat("  • p-value (Wilcoxon):", format.pval(resumen$test_pvalue), "\n\n")

cat("🔬 DISTRIBUCIÓN ALS vs CONTROL:\n")
cat("\n  G>T:\n")
cat("    - Mayor en ALS:", sprintf("%.1f%%", resumen$gt_perc_als), "\n")
cat("    - Mayor en Control:", sprintf("%.1f%%", resumen$gt_perc_control), "\n")
cat("\n  Otras mutaciones:\n")
cat("    - Mayor en ALS:", sprintf("%.1f%%", resumen$otras_perc_als), "\n")
cat("    - Mayor en Control:", sprintf("%.1f%%", resumen$otras_perc_control), "\n\n")

cat("✅ ANÁLISIS COMPLETADO\n")
cat("  • Figuras: 4\n")
cat("  • Tablas: 4\n")
cat("  • Ubicación:", output_paso8b, "\n\n")

cat("════════════════════════════════════════════════════════════════════════\n")









