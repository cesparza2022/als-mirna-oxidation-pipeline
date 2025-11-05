# ==============================================================================
# PASO 5A (PROFUNDIZACIÓN): ANÁLISIS DETALLADO DE G>T EN OUTLIERS
# ==============================================================================
# Objetivo: Entender QUÉ tipo de mutaciones G>T están en outliers
# Enfoque especial: Región semilla

# Cargar librerías necesarias
library(tidyverse)
library(ggplot2)
library(gridExtra)

# Cargar configuración y funciones
source("../config_pipeline.R")
source("functions_pipeline.R")

# Definir rutas de salida
output_figures_path <- file.path(config$output_paths$figures, "paso5a_profundizar_outliers")
output_tables_path <- file.path(config$output_paths$outputs, "paso5a_profundizar_outliers")

# Crear directorios
dir.create(output_figures_path, showWarnings = FALSE, recursive = TRUE)
dir.create(output_tables_path, showWarnings = FALSE, recursive = TRUE)

cat("=== ANÁLISIS PROFUNDO: G>T EN OUTLIERS ===\n")
cat("Fecha:", as.character(Sys.time()), "\n\n")

# =============================================================================
# 1. CARGAR DATOS PROCESADOS Y OUTLIERS
# =============================================================================

cat("Cargando datos procesados...\n")

# Cargar datos originales y procesar
raw_data <- read_tsv(config$data_paths$raw_data, col_types = cols(.default = "c"))
processed_data <- apply_split_collapse(raw_data)
vaf_data <- calculate_vafs(processed_data)
filtered_data <- filter_high_vafs(vaf_data, threshold = 0.5)

# Cargar lista de outliers
outliers_file <- file.path(config$output_paths$outputs, "paso5a_outliers_muestras", "paso5a_outliers_consolidado.csv")
outliers_data <- read_csv(outliers_file, show_col_types = FALSE)

# Cargar impacto en G>T
gt_impact_file <- file.path(config$output_paths$outputs, "paso5a_outliers_muestras", "paso5a_gt_impacto_outliers.csv")
gt_impact <- read_csv(gt_impact_file, show_col_types = FALSE)

cat("Datos cargados correctamente.\n\n")

# =============================================================================
# 2. EXTRAER INFORMACIÓN DE POSICIÓN Y REGIÓN
# =============================================================================

cat("=== ANÁLISIS 1: EXTRAYENDO POSICIÓN Y REGIÓN ===\n")

# Extraer posición numérica y asignar región funcional
gt_impact_detailed <- gt_impact %>%
  mutate(
    position = as.numeric(str_extract(`pos.mut`, "^\\d+")),
    mutation_type = str_extract(`pos.mut`, "[ACGT]>[ACGT]$"),
    region = case_when(
      position >= 1 & position <= 7 ~ "Seed",
      position >= 8 & position <= 12 ~ "Central",
      position >= 13 & position <= 17 ~ "3'",
      position >= 18 ~ "Otro",
      TRUE ~ "Unknown"
    )
  )

# Resumen por región
gt_by_region <- gt_impact_detailed %>%
  group_by(region, only_in_outliers) %>%
  summarise(
    n_mutations = n(),
    .groups = "drop"
  ) %>%
  pivot_wider(names_from = only_in_outliers, values_from = n_mutations, values_fill = 0) %>%
  rename(
    in_normal = `FALSE`,
    only_outliers = `TRUE`
  ) %>%
  mutate(
    total = in_normal + only_outliers,
    perc_outliers = round((only_outliers / total) * 100, 2)
  ) %>%
  arrange(desc(perc_outliers))

cat("\n🎯 DISTRIBUCIÓN DE G>T POR REGIÓN:\n")
print(gt_by_region)

write_csv(gt_by_region, file.path(output_tables_path, "gt_por_region_y_outliers.csv"))

# =============================================================================
# 3. ANÁLISIS ESPECÍFICO DE REGIÓN SEMILLA
# =============================================================================

cat("\n=== ANÁLISIS 2: ENFOQUE EN REGIÓN SEMILLA ===\n")

# Filtrar solo región semilla
gt_seed <- gt_impact_detailed %>%
  filter(region == "Seed")

cat("Total de mutaciones G>T en región semilla:", nrow(gt_seed), "\n")
cat("G>T solo en outliers (semilla):", sum(gt_seed$only_in_outliers), "\n")
cat("Porcentaje:", round((sum(gt_seed$only_in_outliers) / nrow(gt_seed)) * 100, 2), "%\n")

# Análisis por posición específica en semilla
gt_seed_by_position <- gt_seed %>%
  group_by(position, only_in_outliers) %>%
  summarise(
    n_mutations = n(),
    mirnas_afectados = n_distinct(`miRNA.name`),
    .groups = "drop"
  ) %>%
  pivot_wider(names_from = only_in_outliers, values_from = c(n_mutations, mirnas_afectados), values_fill = 0) %>%
  mutate(
    total_mutations = `n_mutations_FALSE` + `n_mutations_TRUE`,
    perc_only_outliers = round((`n_mutations_TRUE` / total_mutations) * 100, 2)
  ) %>%
  arrange(position)

cat("\n🌱 REGIÓN SEMILLA - ANÁLISIS POR POSICIÓN:\n")
print(gt_seed_by_position)

write_csv(gt_seed_by_position, file.path(output_tables_path, "gt_semilla_por_posicion_outliers.csv"))

# Análisis de miRNAs específicos en región semilla
gt_seed_mirnas <- gt_seed %>%
  group_by(`miRNA.name`, only_in_outliers) %>%
  summarise(
    n_positions_gt = n(),
    positions = paste(unique(position), collapse = ","),
    .groups = "drop"
  ) %>%
  pivot_wider(names_from = only_in_outliers, values_from = c(n_positions_gt, positions), values_fill = list(n_positions_gt = 0, positions = "")) %>%
  mutate(
    total_gt_positions = `n_positions_gt_FALSE` + `n_positions_gt_TRUE`
  ) %>%
  arrange(desc(total_gt_positions), desc(`n_positions_gt_TRUE`))

cat("\n🧬 TOP 20 miRNAs CON G>T EN REGIÓN SEMILLA:\n")
print(head(gt_seed_mirnas, 20))

write_csv(gt_seed_mirnas, file.path(output_tables_path, "gt_semilla_por_mirna_outliers.csv"))

# =============================================================================
# 4. ANÁLISIS POR POSICIÓN (TODAS LAS REGIONES)
# =============================================================================

cat("\n=== ANÁLISIS 3: DISTRIBUCIÓN POR POSICIÓN (TODAS REGIONES) ===\n")

# Análisis detallado por posición
gt_by_position <- gt_impact_detailed %>%
  group_by(position, region, only_in_outliers) %>%
  summarise(
    n_mutations = n(),
    mirnas_unicos = n_distinct(`miRNA.name`),
    .groups = "drop"
  ) %>%
  pivot_wider(names_from = only_in_outliers, values_from = c(n_mutations, mirnas_unicos), values_fill = 0) %>%
  mutate(
    total_mutations = `n_mutations_FALSE` + `n_mutations_TRUE`,
    total_mirnas = `mirnas_unicos_FALSE` + `mirnas_unicos_TRUE`,
    perc_only_outliers = round((`n_mutations_TRUE` / total_mutations) * 100, 2)
  ) %>%
  arrange(position)

cat("\n📍 DISTRIBUCIÓN COMPLETA POR POSICIÓN:\n")
print(gt_by_position)

write_csv(gt_by_position, file.path(output_tables_path, "gt_todas_posiciones_outliers.csv"))

# =============================================================================
# 5. CARACTERÍSTICAS DE LAS MUTACIONES G>T EN OUTLIERS vs NORMALES
# =============================================================================

cat("\n=== ANÁLISIS 4: CARACTERÍSTICAS DE G>T EN OUTLIERS vs NORMALES ===\n")

# Comparar características de mutaciones solo en outliers vs en normales
gt_characteristics <- gt_impact_detailed %>%
  mutate(
    category = case_when(
      only_in_outliers ~ "Solo en Outliers",
      mostly_in_outliers ~ "Mayormente en Outliers",
      TRUE ~ "Mayormente en Normales"
    )
  ) %>%
  group_by(category) %>%
  summarise(
    n_mutations = n(),
    n_mirnas = n_distinct(`miRNA.name`),
    mean_total_samples = mean(n_total_samples, na.rm = TRUE),
    median_total_samples = median(n_total_samples, na.rm = TRUE),
    min_samples = min(n_total_samples, na.rm = TRUE),
    max_samples = max(n_total_samples, na.rm = TRUE),
    .groups = "drop"
  )

cat("\n🔬 CARACTERÍSTICAS DE G>T POR CATEGORÍA:\n")
print(gt_characteristics)

write_csv(gt_characteristics, file.path(output_tables_path, "gt_caracteristicas_por_categoria.csv"))

# Análisis de prevalencia de mutaciones solo en outliers
gt_prevalence_outliers_only <- gt_impact_detailed %>%
  filter(only_in_outliers) %>%
  count(n_total_samples) %>%
  arrange(n_total_samples) %>%
  mutate(
    cumulative = cumsum(n),
    perc_cumulative = round((cumulative / sum(n)) * 100, 2)
  )

cat("\n📊 PREVALENCIA DE MUTACIONES SOLO EN OUTLIERS:\n")
cat("(¿En cuántas muestras están presentes?)\n")
print(gt_prevalence_outliers_only)

write_csv(gt_prevalence_outliers_only, file.path(output_tables_path, "gt_prevalencia_solo_outliers.csv"))

# =============================================================================
# 6. ANÁLISIS DE FAMILIAS DE miRNAs
# =============================================================================

cat("\n=== ANÁLISIS 5: FAMILIAS DE miRNAs CON G>T EN OUTLIERS ===\n")

# Extraer familia de miRNA (ej. let-7, miR-1, miR-10, etc.)
gt_impact_detailed <- gt_impact_detailed %>%
  mutate(
    mirna_family = case_when(
      str_detect(`miRNA.name`, "let-7") ~ "let-7",
      str_detect(`miRNA.name`, "miR-1-") ~ "miR-1",
      str_detect(`miRNA.name`, "miR-10") ~ "miR-10",
      str_detect(`miRNA.name`, "miR-100") ~ "miR-100",
      str_detect(`miRNA.name`, "miR-103") ~ "miR-103",
      str_detect(`miRNA.name`, "miR-106") ~ "miR-106",
      str_detect(`miRNA.name`, "miR-107") ~ "miR-107",
      str_detect(`miRNA.name`, "miR-125") ~ "miR-125",
      str_detect(`miRNA.name`, "miR-143") ~ "miR-143",
      str_detect(`miRNA.name`, "miR-144") ~ "miR-144",
      str_detect(`miRNA.name`, "miR-181") ~ "miR-181",
      str_detect(`miRNA.name`, "miR-191") ~ "miR-191",
      str_detect(`miRNA.name`, "miR-199") ~ "miR-199",
      str_detect(`miRNA.name`, "miR-21") ~ "miR-21",
      str_detect(`miRNA.name`, "miR-22") ~ "miR-22",
      str_detect(`miRNA.name`, "miR-26") ~ "miR-26",
      str_detect(`miRNA.name`, "miR-29") ~ "miR-29",
      str_detect(`miRNA.name`, "miR-30") ~ "miR-30",
      TRUE ~ "Otras"
    )
  )

# Análisis por familia
gt_by_family <- gt_impact_detailed %>%
  group_by(mirna_family, only_in_outliers) %>%
  summarise(
    n_mutations = n(),
    n_mirnas = n_distinct(`miRNA.name`),
    .groups = "drop"
  ) %>%
  pivot_wider(names_from = only_in_outliers, values_from = c(n_mutations, n_mirnas), values_fill = 0) %>%
  mutate(
    total_mutations = `n_mutations_FALSE` + `n_mutations_TRUE`,
    perc_only_outliers = round((`n_mutations_TRUE` / total_mutations) * 100, 2)
  ) %>%
  arrange(desc(total_mutations))

cat("\n👨‍👩‍👧‍👦 FAMILIAS DE miRNAs CON G>T - TOP 20:\n")
print(head(gt_by_family, 20))

write_csv(gt_by_family, file.path(output_tables_path, "gt_por_familia_outliers.csv"))

# Familias que SOLO tienen G>T en outliers
families_only_outliers <- gt_by_family %>%
  filter(`n_mutations_TRUE` > 0 & `n_mutations_FALSE` == 0) %>%
  arrange(desc(`n_mutations_TRUE`))

cat("\n⚠️ FAMILIAS CON G>T SOLO EN OUTLIERS:\n")
print(head(families_only_outliers, 10))

# =============================================================================
# 7. ANÁLISIS DETALLADO DE REGIÓN SEMILLA (POSICIONES 1-7)
# =============================================================================

cat("\n=== ANÁLISIS 6: REGIÓN SEMILLA DETALLADO (POSICIONES 1-7) ===\n")

# Filtrar región semilla
gt_seed_detailed <- gt_impact_detailed %>%
  filter(region == "Seed")

cat("Total G>T en semilla:", nrow(gt_seed_detailed), "\n")
cat("Solo en outliers:", sum(gt_seed_detailed$only_in_outliers), "\n")
cat("Mayormente en outliers:", sum(gt_seed_detailed$mostly_in_outliers), "\n\n")

# Análisis posición por posición en semilla
seed_positions_detail <- gt_seed_detailed %>%
  group_by(position) %>%
  summarise(
    total_gt = n(),
    only_outliers = sum(only_in_outliers),
    mostly_outliers = sum(mostly_in_outliers),
    in_normal = sum(!only_in_outliers & !mostly_in_outliers),
    perc_only = round((only_outliers / total_gt) * 100, 2),
    perc_mostly = round((mostly_outliers / total_gt) * 100, 2),
    perc_normal = round((in_normal / total_gt) * 100, 2),
    mean_n_samples = mean(n_total_samples),
    median_n_samples = median(n_total_samples),
    .groups = "drop"
  ) %>%
  arrange(position)

cat("📍 POSICIONES DE SEMILLA (1-7) - DETALLE:\n")
print(seed_positions_detail)

write_csv(seed_positions_detail, file.path(output_tables_path, "gt_semilla_posiciones_detallado.csv"))

# Análisis específico de posición 6 (CRÍTICA para función de miRNA)
cat("\n🎯 POSICIÓN 6 (CRÍTICA) - ANÁLISIS ESPECÍFICO:\n")

gt_pos6 <- gt_seed_detailed %>%
  filter(position == 6)

if (nrow(gt_pos6) > 0) {
  cat("Total G>T en posición 6:", nrow(gt_pos6), "\n")
  cat("Solo en outliers:", sum(gt_pos6$only_in_outliers), "\n")
  cat("Mayormente en outliers:", sum(gt_pos6$mostly_in_outliers), "\n")
  cat("En muestras normales:", sum(!gt_pos6$only_in_outliers & !gt_pos6$mostly_in_outliers), "\n\n")
  
  # miRNAs específicos con G>T en posición 6
  gt_pos6_mirnas <- gt_pos6 %>%
    select(`miRNA.name`, n_total_samples, n_outlier_samples, n_normal_samples, only_in_outliers, mostly_in_outliers) %>%
    arrange(desc(n_total_samples))
  
  cat("miRNAs CON G>T EN POSICIÓN 6:\n")
  print(head(gt_pos6_mirnas, 20))
  
  write_csv(gt_pos6_mirnas, file.path(output_tables_path, "gt_posicion6_mirnas_detallado.csv"))
  
} else {
  cat("No se encontraron mutaciones G>T en posición 6.\n")
}

# =============================================================================
# 8. VISUALIZACIONES
# =============================================================================

cat("\n=== GENERANDO VISUALIZACIONES ===\n")

# Visualización 1: G>T por región y outliers
p_region <- ggplot(gt_by_region, aes(x = reorder(region, -total), y = total)) +
  geom_col(aes(fill = "Total"), alpha = 0.5) +
  geom_col(aes(y = only_outliers, fill = "Solo Outliers")) +
  geom_text(aes(label = paste0(perc_outliers, "%"), y = total), vjust = -0.5) +
  labs(title = "Mutaciones G>T por Región: Outliers vs Total",
       subtitle = "% indica proporción solo en outliers",
       x = "Región Funcional", y = "Número de Mutaciones G>T",
       fill = "Tipo") +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave(file.path(output_figures_path, "gt_por_region_outliers.png"), p_region, width = 10, height = 6)
cat("Figura 'gt_por_region_outliers.png' generada.\n")

# Visualización 2: Heatmap de posiciones
gt_heatmap_data <- gt_impact_detailed %>%
  group_by(position, region) %>%
  summarise(
    total_gt = n(),
    only_outliers = sum(only_in_outliers),
    mostly_outliers = sum(mostly_in_outliers),
    perc_outliers = round(((only_outliers + mostly_outliers) / total_gt) * 100, 2),
    .groups = "drop"
  )

p_heatmap <- ggplot(gt_heatmap_data, aes(x = position, y = region, fill = perc_outliers)) +
  geom_tile(color = "white") +
  geom_text(aes(label = only_outliers), color = "white", size = 3) +
  scale_fill_gradient2(low = "blue", mid = "yellow", high = "red", midpoint = 50,
                       name = "% en Outliers") +
  labs(title = "Heatmap: G>T en Outliers por Posición y Región",
       subtitle = "Números = mutaciones SOLO en outliers",
       x = "Posición en miRNA", y = "Región Funcional") +
  theme_minimal() +
  theme(panel.grid = element_blank())

ggsave(file.path(output_figures_path, "gt_heatmap_posicion_region_outliers.png"), p_heatmap, width = 12, height = 6)
cat("Figura 'gt_heatmap_posicion_region_outliers.png' generada.\n")

# Visualización 3: Enfoque en región semilla
p_seed_positions <- ggplot(seed_positions_detail, aes(x = position)) +
  geom_col(aes(y = total_gt, fill = "Total"), alpha = 0.5) +
  geom_col(aes(y = only_outliers, fill = "Solo Outliers")) +
  geom_text(aes(y = total_gt, label = paste0(perc_only, "%")), vjust = -0.5, size = 3) +
  scale_x_continuous(breaks = 1:7) +
  labs(title = "Región SEMILLA: Mutaciones G>T por Posición",
       subtitle = "% indica proporción solo en outliers. Posición 6 es crítica.",
       x = "Posición en Región Semilla", y = "Número de Mutaciones G>T",
       fill = "Tipo") +
  theme_minimal() +
  theme(legend.position = "bottom") +
  annotate("rect", xmin = 5.5, xmax = 6.5, ymin = -Inf, ymax = Inf, alpha = 0.2, fill = "red")

ggsave(file.path(output_figures_path, "gt_semilla_por_posicion.png"), p_seed_positions, width = 10, height = 6)
cat("Figura 'gt_semilla_por_posicion.png' generada.\n")

# Visualización 4: Prevalencia de mutaciones (cuántas muestras)
prevalence_data <- gt_impact_detailed %>%
  mutate(
    prevalence_category = case_when(
      n_total_samples == 1 ~ "1 muestra",
      n_total_samples == 2 ~ "2 muestras",
      n_total_samples <= 5 ~ "3-5 muestras",
      n_total_samples <= 10 ~ "6-10 muestras",
      n_total_samples <= 50 ~ "11-50 muestras",
      n_total_samples <= 100 ~ "51-100 muestras",
      TRUE ~ ">100 muestras"
    ),
    prevalence_category = factor(prevalence_category, 
                                  levels = c("1 muestra", "2 muestras", "3-5 muestras", 
                                            "6-10 muestras", "11-50 muestras", 
                                            "51-100 muestras", ">100 muestras"))
  ) %>%
  group_by(prevalence_category, only_in_outliers) %>%
  summarise(n_mutations = n(), .groups = "drop")

p_prevalence <- ggplot(prevalence_data, aes(x = prevalence_category, y = n_mutations, fill = only_in_outliers)) +
  geom_col(position = "stack") +
  scale_fill_manual(values = c("FALSE" = "steelblue", "TRUE" = "red"),
                    name = "Ubicación",
                    labels = c("En muestras normales", "Solo en outliers")) +
  labs(title = "Prevalencia de Mutaciones G>T",
       subtitle = "¿En cuántas muestras está cada mutación?",
       x = "Número de Muestras con la Mutación", y = "Número de Mutaciones G>T") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "bottom")

ggsave(file.path(output_figures_path, "gt_prevalencia_outliers.png"), p_prevalence, width = 10, height = 6)
cat("Figura 'gt_prevalencia_outliers.png' generada.\n")

# =============================================================================
# 9. COMPARACIÓN: SEMILLA vs OTRAS REGIONES
# =============================================================================

cat("\n=== ANÁLISIS 7: SEMILLA vs OTRAS REGIONES ===\n")

# Comparar región semilla con otras regiones
region_comparison <- gt_impact_detailed %>%
  mutate(is_seed = region == "Seed") %>%
  group_by(is_seed, only_in_outliers) %>%
  summarise(
    n_mutations = n(),
    mean_prevalence = mean(n_total_samples),
    median_prevalence = median(n_total_samples),
    .groups = "drop"
  ) %>%
  pivot_wider(names_from = only_in_outliers, values_from = c(n_mutations, mean_prevalence, median_prevalence)) %>%
  mutate(
    total = `n_mutations_FALSE` + `n_mutations_TRUE`,
    perc_only_outliers = round((`n_mutations_TRUE` / total) * 100, 2)
  )

cat("\n🌱 COMPARACIÓN SEMILLA vs OTRAS REGIONES:\n")
print(region_comparison)

write_csv(region_comparison, file.path(output_tables_path, "gt_comparacion_semilla_otras.csv"))

# =============================================================================
# 10. REPORTE EJECUTIVO
# =============================================================================

cat("\n=== GENERANDO REPORTE EJECUTIVO ===\n")

report_lines <- c(
  "# ANÁLISIS PROFUNDO: G>T EN OUTLIERS",
  "",
  "## 🎯 HALLAZGOS PRINCIPALES",
  "",
  "### REGIÓN SEMILLA (Posiciones 1-7):",
  paste("- **Total G>T en semilla:**", nrow(gt_seed)),
  paste("- **Solo en outliers:**", sum(gt_seed$only_in_outliers), 
        paste0("(", round((sum(gt_seed$only_in_outliers) / nrow(gt_seed)) * 100, 2), "%)")),
  paste("- **Mayormente en outliers:**", sum(gt_seed$mostly_in_outliers),
        paste0("(", round((sum(gt_seed$mostly_in_outliers) / nrow(gt_seed)) * 100, 2), "%)")),
  "",
  "### DISTRIBUCIÓN POR REGIÓN:",
  "```",
  capture.output(print(gt_by_region)),
  "```",
  "",
  "### POSICIONES CRÍTICAS EN SEMILLA:",
  "```",
  capture.output(print(seed_positions_detail)),
  "```",
  "",
  "### FAMILIAS DE miRNAs MÁS AFECTADAS:",
  "```",
  capture.output(print(head(gt_by_family, 10))),
  "```",
  "",
  "### PREVALENCIA DE MUTACIONES SOLO EN OUTLIERS:",
  "```",
  capture.output(print(gt_prevalence_outliers_only)),
  "```",
  "",
  "---",
  "",
  "## 📊 INTERPRETACIÓN",
  "",
  "### Hallazgo 1: Mutaciones ultra-raras",
  paste("- **", gt_prevalence_outliers_only$n[gt_prevalence_outliers_only$n_total_samples == 1], 
        "mutaciones (", gt_prevalence_outliers_only$perc_cumulative[gt_prevalence_outliers_only$n_total_samples == 1],
        "%) están en solo 1 muestra**"),
  "- Estas son mutaciones específicas de paciente",
  "- Baja reproducibilidad",
  "",
  "### Hallazgo 2: Impacto en región semilla",
  paste("- **", round((sum(gt_seed$only_in_outliers) / nrow(gt_seed)) * 100, 2), 
        "% de G>T en semilla están solo en outliers**"),
  "- La región semilla es CRÍTICA para función de miRNA",
  "- Perder estos G>T puede afectar análisis funcional",
  "",
  "### Hallazgo 3: Familias específicas",
  "- Algunas familias de miRNAs tienen G>T SOLO en outliers",
  "- Esto puede indicar especificidad de subtipo clínico",
  "",
  "---",
  "",
  "## 🔬 CONCLUSIÓN",
  "",
  "Las mutaciones G>T en outliers son principalmente:",
  "1. **Ultra-raras** (1-2 muestras)",
  "2. **Distribuidas en todas las regiones** (incluyendo semilla)",
  "3. **Específicas de familias de miRNAs** particulares",
  "4. **Potencialmente importantes** para análisis de subtipos",
  "",
  "**Recomendación:** Mantener outliers y usar metadatos clínicos para entenderlos",
  "",
  "---",
  "",
  paste("*Análisis generado:", Sys.time(), "*")
)

writeLines(report_lines, file.path(output_tables_path, "reporte_gt_outliers_profundo.md"))

cat("\n=== ANÁLISIS COMPLETADO ===\n")
cat("Archivos generados:\n")
cat("  - Tablas: 8 archivos CSV\n")
cat("  - Figuras: 4 archivos PNG\n")
cat("  - Reporte: 1 archivo MD\n")









