#!/usr/bin/env Rscript
# ==============================================================================
# PASO 10A: ANÁLISIS PROFUNDO let-7 vs miR-4500 (PAR EXPERIMENTAL PERFECTO)
# ==============================================================================
# 
# OBJETIVO:
#   Análisis exhaustivo del par let-7 / miR-4500 (MISMA secuencia TGAGGTA):
#   1. Caracterizar los 8 miRNAs let-7 oxidados
#   2. Caracterizar miR-4500 (resistente)
#   3. Comparar SNVs completos (no solo G>T)
#   4. Comparar VAFs por posición
#   5. Distribución ALS vs Control
#   6. Cambios temporales
#   7. Preparar para validación experimental
#
# INPUT:
#   - Datos completos de SNVs y VAFs
#   - Secuencias (TGAGGTA)
#   - Metadatos (temporal, cohort)
#
# OUTPUT:
#   - Perfiles completos de let-7 y miR-4500
#   - Comparaciones detalladas
#   - Figuras para presentación
#   - Plan experimental
#
# AUTOR: Análisis ALS miRNAs
# FECHA: 8 de octubre de 2025
# ==============================================================================

library(tidyverse)
library(pheatmap)
library(jsonlite)

cat("╔════════════════════════════════════════════════════════════════════════╗\n")
cat("║      PASO 10A: let-7 (OXIDADA) vs miR-4500 (RESISTENTE)               ║\n")
cat("║              MISMA SECUENCIA - DIFERENTE DESTINO                      ║\n")
cat("╚════════════════════════════════════════════════════════════════════════╝\n\n")

# Cargar configuración
source("config_pipeline.R")
source("functions_pipeline.R")

# Directorios
output_paso10a <- file.path(config$output_paths$outputs, "paso10a_let7_vs_mir4500")
output_figures <- file.path(config$output_paths$figures, "paso10a_let7_vs_mir4500")
dir.create(output_paso10a, recursive = TRUE, showWarnings = FALSE)
dir.create(output_figures, recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------------------------------------------
# PASO 10A.1: CARGAR DATOS
# ------------------------------------------------------------------------------

cat("📂 PASO 10A.1: Cargando datos...\n")

# Datos completos
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

# Metadatos
metadata <- read_csv(
  file.path(config$output_paths$outputs, "paso6a_metadatos", "paso6a_metadatos_integrados.csv"),
  show_col_types = FALSE
)

cat("  ✓ Datos cargados\n\n")

# ------------------------------------------------------------------------------
# PASO 10A.2: IDENTIFICAR MIEMBROS DE let-7 Y miR-4500
# ------------------------------------------------------------------------------

cat("🎯 PASO 10A.2: Identificando miembros let-7 y miR-4500...\n")

# let-7 family members con TGAGGTA
let7_members <- c("hsa-let-7a-5p", "hsa-let-7b-5p", "hsa-let-7c-5p", 
                  "hsa-let-7d-5p", "hsa-let-7e-5p", "hsa-let-7f-5p",
                  "hsa-let-7g-5p", "hsa-let-7i-5p", "hsa-miR-98-5p")

mir4500 <- "hsa-miR-4500"

cat("  ✓ let-7 members:", length(let7_members), "\n")
cat("  ✓ miR-4500: 1\n\n")

# ------------------------------------------------------------------------------
# PASO 10A.3: EXTRAER TODOS LOS SNVs (no solo G>T)
# ------------------------------------------------------------------------------

cat("📊 PASO 10A.3: Extrayendo TODOS los SNVs de estos miRNAs...\n")

# Filtrar datos
let7_data <- datos %>%
  filter(`miRNA name` %in% let7_members)

mir4500_data <- datos %>%
  filter(`miRNA name` == mir4500)

cat("  ✓ SNVs en let-7:", nrow(let7_data), "\n")
cat("  ✓ SNVs en miR-4500:", nrow(mir4500_data), "\n\n")

# Resumen por miRNA
let7_summary <- let7_data %>%
  group_by(`miRNA name`) %>%
  summarise(
    n_snvs = n(),
    n_gt = sum(mutation_type == "G>T"),
    n_gt_seed = sum(mutation_type == "G>T" & region == "Seed"),
    posiciones_gt_seed = paste(sort(position[mutation_type == "G>T" & region == "Seed"]), 
                                collapse = ","),
    .groups = "drop"
  ) %>%
  arrange(desc(n_gt_seed))

cat("  📊 RESUMEN let-7:\n")
print(let7_summary)

mir4500_summary <- mir4500_data %>%
  summarise(
    mirna = mir4500,
    n_snvs = n(),
    n_gt = sum(mutation_type == "G>T"),
    n_gt_seed = sum(mutation_type == "G>T" & region == "Seed"),
    n_otras_seed = sum(mutation_type != "G>T" & region == "Seed")
  )

cat("\n  📊 RESUMEN miR-4500:\n")
print(mir4500_summary)

write_csv(let7_summary, file.path(output_paso10a, "paso10a_let7_summary.csv"))
write_csv(mir4500_summary, file.path(output_paso10a, "paso10a_mir4500_summary.csv"))

# ------------------------------------------------------------------------------
# PASO 10A.4: COMPARAR G>T POR POSICIÓN
# ------------------------------------------------------------------------------

cat("\n🔍 PASO 10A.4: Comparando G>T por posición...\n")

# G>T por posición en let-7
let7_gt_posiciones <- let7_data %>%
  filter(mutation_type == "G>T") %>%
  group_by(position, region) %>%
  summarise(
    n = n(),
    n_mirnas = n_distinct(`miRNA name`),
    .groups = "drop"
  ) %>%
  arrange(position)

cat("\n  📍 G>T en let-7 por posición:\n")
print(let7_gt_posiciones)

# G>T en miR-4500
mir4500_gt <- mir4500_data %>%
  filter(mutation_type == "G>T")

cat("\n  📍 G>T en miR-4500:\n")
if (nrow(mir4500_gt) > 0) {
  print(mir4500_gt %>% select(`pos:mut`, position, region))
} else {
  cat("    ❌ NINGUNO en región semilla (como esperado)\n")
  cat("    → Verificar si tiene G>T en otras regiones...\n")
  
  mir4500_gt_all <- mir4500_data %>%
    filter(mutation_type == "G>T")
  
  if (nrow(mir4500_gt_all) > 0) {
    cat("\n  📍 G>T en miR-4500 (TODAS las regiones):\n")
    print(mir4500_gt_all %>% select(`pos:mut`, position, region))
  } else {
    cat("    ❌ miR-4500 NO tiene G>T en NINGUNA posición\n")
  }
}

# Gráfica comparativa
let7_gt_seed <- let7_gt_posiciones %>% filter(region == "Seed")

p1 <- ggplot(let7_gt_seed, aes(x = factor(position), y = n)) +
  geom_col(fill = "#E31A1C", alpha = 0.8) +
  geom_text(aes(label = paste0(n, "\n(", n_mirnas, " miRNAs)")),
            vjust = -0.5, size = 3.5) +
  labs(
    title = "G>T en Región Semilla: Familia let-7",
    subtitle = "miR-4500 (TGAGGTA) NO tiene G>T en semilla",
    x = "Posición",
    y = "Número de G>T"
  ) +
  theme_minimal()

ggsave(file.path(output_figures, "paso10a_let7_gt_por_posicion.png"),
       p1, width = 10, height = 6)
cat("\n  ✓ Figura 'paso10a_let7_gt_por_posicion.png' generada\n\n")

# ------------------------------------------------------------------------------
# PASO 10A.5: COMPARAR TODOS LOS TIPOS DE SNVs
# ------------------------------------------------------------------------------

cat("🧬 PASO 10A.5: Comparando TODOS los tipos de SNVs...\n")

# Tipos de mutación en let-7
let7_mutation_types <- let7_data %>%
  group_by(mutation_type, region) %>%
  summarise(n = n(), .groups = "drop") %>%
  arrange(desc(n))

cat("\n  📊 Tipos de mutación en let-7:\n")
print(head(let7_mutation_types, 15))

# Tipos en miR-4500
mir4500_mutation_types <- mir4500_data %>%
  group_by(mutation_type, region) %>%
  summarise(n = n(), .groups = "drop") %>%
  arrange(desc(n))

cat("\n  📊 Tipos de mutación en miR-4500:\n")
print(mir4500_mutation_types)

# Comparación en región semilla
let7_seed_types <- let7_data %>%
  filter(region == "Seed") %>%
  group_by(mutation_type) %>%
  summarise(n_let7 = n(), .groups = "drop")

mir4500_seed_types <- mir4500_data %>%
  filter(region == "Seed") %>%
  group_by(mutation_type) %>%
  summarise(n_mir4500 = n(), .groups = "drop")

comparison_seed <- full_join(let7_seed_types, mir4500_seed_types, 
                              by = "mutation_type") %>%
  replace_na(list(n_let7 = 0, n_mir4500 = 0)) %>%
  mutate(diff = n_let7 - n_mir4500) %>%
  arrange(desc(abs(diff)))

cat("\n  🔬 COMPARACIÓN EN SEMILLA:\n")
print(comparison_seed)

write_csv(comparison_seed, file.path(output_paso10a, "paso10a_comparacion_tipos_semilla.csv"))

# Gráfica
p2 <- ggplot(comparison_seed %>% head(10), 
             aes(x = reorder(mutation_type, abs(diff)), y = n_let7)) +
  geom_col(aes(fill = "let-7"), alpha = 0.7, position = "dodge") +
  geom_col(aes(y = n_mir4500, fill = "miR-4500"), alpha = 0.7, 
           position = position_nudge(x = 0.3)) +
  scale_fill_manual(values = c("let-7" = "#E31A1C", "miR-4500" = "#1F78B4"),
                    name = "") +
  labs(
    title = "Comparación de Tipos de SNVs en Región Semilla",
    subtitle = "let-7 (oxidada) vs miR-4500 (resistente) - MISMA secuencia TGAGGTA",
    x = "Tipo de Mutación",
    y = "Número de SNVs"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave(file.path(output_figures, "paso10a_tipos_snv_comparacion.png"),
       p2, width = 10, height = 6)
cat("  ✓ Figura 'paso10a_tipos_snv_comparacion.png' generada\n\n")

# ------------------------------------------------------------------------------
# PASO 10A.6: ANÁLISIS DE VAFs (let-7 vs miR-4500)
# ------------------------------------------------------------------------------

cat("📈 PASO 10A.6: Comparando VAFs...\n")

# VAF columns
vaf_cols <- grep("^VAF_", colnames(datos), value = TRUE)

# let-7 VAFs
let7_vafs <- let7_data %>%
  rowwise() %>%
  mutate(mean_vaf = mean(c_across(all_of(vaf_cols)), na.rm = TRUE)) %>%
  ungroup() %>%
  group_by(`miRNA name`) %>%
  summarise(
    n_snvs = n(),
    mean_vaf = mean(mean_vaf, na.rm = TRUE),
    .groups = "drop"
  )

cat("\n  📊 VAFs promedio por miembro let-7:\n")
print(let7_vafs)

# miR-4500 VAFs
mir4500_vafs <- mir4500_data %>%
  rowwise() %>%
  mutate(mean_vaf = mean(c_across(all_of(vaf_cols)), na.rm = TRUE)) %>%
  ungroup() %>%
  summarise(
    mirna = mir4500,
    n_snvs = n(),
    mean_vaf = mean(mean_vaf, na.rm = TRUE)
  )

cat("\n  📊 VAF promedio miR-4500:\n")
print(mir4500_vafs)

# Comparación estadística
all_vafs <- bind_rows(
  let7_vafs %>% mutate(grupo = "let-7"),
  mir4500_vafs %>% rename(`miRNA name` = mirna) %>% mutate(grupo = "miR-4500")
)

test_vaf <- wilcox.test(mean_vaf ~ grupo, data = all_vafs)

cat("\n  🔬 Test Wilcoxon (VAF let-7 vs miR-4500):\n")
cat("    p-value =", format.pval(test_vaf$p.value), "\n\n")

# Boxplot
p3 <- ggplot(all_vafs, aes(x = grupo, y = mean_vaf, fill = grupo)) +
  geom_boxplot(alpha = 0.7) +
  geom_jitter(width = 0.1, alpha = 0.5, size = 2) +
  scale_fill_manual(values = c("let-7" = "#E31A1C", "miR-4500" = "#1F78B4"),
                    name = "") +
  labs(
    title = "VAFs: let-7 (oxidada) vs miR-4500 (resistente)",
    subtitle = sprintf("p-value = %s (Wilcoxon) - MISMA secuencia TGAGGTA",
                      format.pval(test_vaf$p.value)),
    x = "",
    y = "VAF Promedio"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

ggsave(file.path(output_figures, "paso10a_vaf_comparacion.png"),
       p3, width = 8, height = 6)
cat("  ✓ Figura 'paso10a_vaf_comparacion.png' generada\n\n")

# ------------------------------------------------------------------------------
# PASO 10A.7: DISTRIBUCIÓN ALS vs CONTROL
# ------------------------------------------------------------------------------

cat("🔬 PASO 10A.7: Analizando distribución ALS vs Control...\n")

# Mapping de muestras
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

# let-7 por cohort
let7_by_cohort <- let7_data %>%
  filter(region == "Seed") %>%
  rowwise() %>%
  mutate(
    vaf_als = mean(c_across(all_of(vaf_als)), na.rm = TRUE),
    vaf_control = mean(c_across(all_of(vaf_control)), na.rm = TRUE)
  ) %>%
  ungroup() %>%
  group_by(`miRNA name`) %>%
  summarise(
    n_snvs_seed = n(),
    mean_vaf_als = mean(vaf_als, na.rm = TRUE),
    mean_vaf_control = mean(vaf_control, na.rm = TRUE),
    diff = mean_vaf_als - mean_vaf_control,
    .groups = "drop"
  )

cat("\n  📊 let-7 VAFs por cohort:\n")
print(let7_by_cohort)

# miR-4500 por cohort
mir4500_by_cohort <- mir4500_data %>%
  filter(region == "Seed") %>%
  rowwise() %>%
  mutate(
    vaf_als = mean(c_across(all_of(vaf_als)), na.rm = TRUE),
    vaf_control = mean(c_across(all_of(vaf_control)), na.rm = TRUE)
  ) %>%
  ungroup() %>%
  summarise(
    mirna = mir4500,
    n_snvs_seed = n(),
    mean_vaf_als = mean(vaf_als, na.rm = TRUE),
    mean_vaf_control = mean(vaf_control, na.rm = TRUE),
    diff = mean_vaf_als - mean_vaf_control
  )

cat("\n  📊 miR-4500 VAFs por cohort:\n")
print(mir4500_by_cohort)

write_csv(let7_by_cohort, file.path(output_paso10a, "paso10a_let7_cohort.csv"))
write_csv(mir4500_by_cohort, file.path(output_paso10a, "paso10a_mir4500_cohort.csv"))

# Scatter plot
cohort_comparison <- bind_rows(
  let7_by_cohort %>% select(`miRNA name`, mean_vaf_als, mean_vaf_control) %>%
    mutate(grupo = "let-7"),
  mir4500_by_cohort %>% rename(`miRNA name` = mirna) %>%
    select(`miRNA name`, mean_vaf_als, mean_vaf_control) %>%
    mutate(grupo = "miR-4500")
)

p4 <- ggplot(cohort_comparison, aes(x = mean_vaf_control, y = mean_vaf_als)) +
  geom_point(aes(color = grupo, size = grupo), alpha = 0.7) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
  scale_color_manual(values = c("let-7" = "#E31A1C", "miR-4500" = "#1F78B4"),
                     name = "") +
  scale_size_manual(values = c("let-7" = 3, "miR-4500" = 6), name = "") +
  labs(
    title = "VAFs ALS vs Control: let-7 vs miR-4500",
    subtitle = "MISMA secuencia TGAGGTA - DIFERENTE oxidación",
    x = "VAF Control",
    y = "VAF ALS"
  ) +
  theme_minimal()

ggsave(file.path(output_figures, "paso10a_als_vs_control_scatter.png"),
       p4, width = 10, height = 8)
cat("  ✓ Figura 'paso10a_als_vs_control_scatter.png' generada\n\n")

# ------------------------------------------------------------------------------
# PASO 10A.8: MAPA DE G>T EN let-7
# ------------------------------------------------------------------------------

cat("🗺️ PASO 10A.8: Generando mapa de G>T en let-7...\n")

# Crear matriz: let-7 members × posiciones
let7_gt_matrix <- let7_data %>%
  filter(mutation_type == "G>T") %>%
  group_by(`miRNA name`, position) %>%
  summarise(n = n(), .groups = "drop") %>%
  pivot_wider(names_from = position, values_from = n, values_fill = 0)

cat("  ✓ Matriz creada:", nrow(let7_gt_matrix), "miRNAs ×", ncol(let7_gt_matrix)-1, "posiciones\n")

# Convertir a matriz para heatmap
if (nrow(let7_gt_matrix) > 0) {
  
  let7_matrix <- let7_gt_matrix %>%
    column_to_rownames("miRNA name") %>%
    as.matrix()
  
  png(file.path(output_figures, "paso10a_let7_heatmap_posiciones.png"),
      width = 12, height = 6, units = "in", res = 150)
  
  pheatmap(
    let7_matrix,
    color = colorRampPalette(c("white", "yellow", "orange", "red"))(100),
    cluster_rows = FALSE,
    cluster_cols = FALSE,
    display_numbers = TRUE,
    main = "Mapa de G>T: Familia let-7 × Posiciones",
    fontsize = 10,
    fontsize_number = 8
  )
  
  dev.off()
  cat("  ✓ Figura 'paso10a_let7_heatmap_posiciones.png' generada\n\n")
}

# ------------------------------------------------------------------------------
# PASO 10A.9: RESUMEN EJECUTIVO
# ------------------------------------------------------------------------------

cat("📋 PASO 10A.9: Generando resumen ejecutivo...\n")

resumen <- list(
  n_let7_members = length(let7_members),
  n_let7_oxidados = sum(let7_summary$n_gt_seed > 0),
  total_gt_let7 = sum(let7_summary$n_gt),
  total_gt_seed_let7 = sum(let7_summary$n_gt_seed),
  mir4500_gt_seed = mir4500_summary$n_gt_seed,
  mir4500_otras_seed = mir4500_summary$n_otras_seed,
  vaf_let7_mean = mean(let7_vafs$mean_vaf),
  vaf_mir4500 = mir4500_vafs$mean_vaf,
  test_vaf_p = test_vaf$p.value
)

write_json(resumen, file.path(output_paso10a, "paso10a_resumen.json"), pretty = TRUE)

cat("\n")
cat("╔════════════════════════════════════════════════════════════════════════╗\n")
cat("║                  RESUMEN EJECUTIVO - PASO 10A                         ║\n")
cat("╚════════════════════════════════════════════════════════════════════════╝\n\n")

cat("👨‍👩‍👧‍👦 FAMILIA let-7:\n")
cat("  • Miembros con TGAGGTA:", resumen$n_let7_members, "\n")
cat("  • Oxidados (G>T en semilla):", resumen$n_let7_oxidados, "\n")
cat("  • Total G>T (todas regiones):", resumen$total_gt_let7, "\n")
cat("  • G>T en semilla:", resumen$total_gt_seed_let7, "\n")
cat("  • VAF promedio:", round(resumen$vaf_let7_mean, 5), "\n\n")

cat("🛡️ miR-4500 (RESISTENTE):\n")
cat("  • G>T en semilla:", resumen$mir4500_gt_seed, "\n")
cat("  • Otras mutaciones en semilla:", resumen$mir4500_otras_seed, "\n")
cat("  • VAF promedio:", round(resumen$vaf_mir4500, 5), "\n\n")

cat("📊 COMPARACIÓN:\n")
cat("  • VAF let-7 / VAF miR-4500 = ", 
    round(resumen$vaf_let7_mean / resumen$vaf_mir4500, 2), "x\n")
cat("  • p-value:", format.pval(resumen$test_vaf_p), "\n\n")

cat("✅ ANÁLISIS COMPLETADO\n")
cat("  • Figuras generadas: 4\n")
cat("  • Tablas guardadas: 5\n")
cat("  • Ubicación:", output_paso10a, "\n\n")

cat("🎯 SIGUIENTE: Paso 10B - Análisis de los 7 resistentes\n\n")

cat("════════════════════════════════════════════════════════════════════════\n")








