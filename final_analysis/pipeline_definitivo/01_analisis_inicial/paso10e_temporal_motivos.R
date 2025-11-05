#!/usr/bin/env Rscript
# ==============================================================================
# PASO 10E: ANÁLISIS TEMPORAL × MOTIVOS
# ==============================================================================
# 
# OBJETIVO:
#   Cruzar análisis temporal con motivos de secuencia:
#   1. ¿TGAGGTA (let-7) cambia específicamente en el tiempo?
#   2. ¿Motivos G-rich disminuyen más? (clearance selectivo)
#   3. ¿Resistentes se mantienen estables?
#   4. Dinámica de oxidación por motivo
#   5. Modelo evolutivo
#
# INPUT:
#   - Datos temporales (Enrolment vs Longitudinal)
#   - Motivos identificados (TGAGGTA, G-rich, etc.)
#   - G>T en semilla
#
# OUTPUT:
#   - Cambios temporales por motivo
#   - Clearance selectivo
#   - Estabilidad de resistentes
#   - Modelo dinámico
#
# AUTOR: Análisis ALS miRNAs
# FECHA: 8 de octubre de 2025
# ==============================================================================

library(tidyverse)
library(jsonlite)

cat("╔════════════════════════════════════════════════════════════════════════╗\n")
cat("║        PASO 10E: ANÁLISIS TEMPORAL × MOTIVOS                          ║\n")
cat("╚════════════════════════════════════════════════════════════════════════╝\n\n")

# Cargar configuración
source("config_pipeline.R")
source("functions_pipeline.R")

# Directorios
output_paso10e <- file.path(config$output_paths$outputs, "paso10e_temporal_motivos")
output_figures <- file.path(config$output_paths$figures, "paso10e_temporal_motivos")
dir.create(output_paso10e, recursive = TRUE, showWarnings = FALSE)
dir.create(output_figures, recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------------------------------------------
# CARGAR DATOS
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
    mutation_type = paste0(str_sub(mutation_raw, 1, 1), ">", str_sub(mutation_raw, 2, 2)),
    region = case_when(
      position >= 1 & position <= 7 ~ "Seed",
      position >= 8 & position <= 12 ~ "Central",
      position >= 13 ~ "3prime",
      TRUE ~ "Unknown"
    )
  )

# Secuencias
seq_file <- "data/hsa_filt_mature_2022.fa"
fasta_lines <- readLines(seq_file)
headers <- grep("^>", fasta_lines)

sequences <- tibble(
  header = fasta_lines[headers],
  sequence = fasta_lines[headers + 1]
) %>%
  mutate(
    mirna_name = str_extract(header, "hsa-[^ ]+"),
    seed_region = substr(sequence, 1, 7)
  )

# Agregar secuencia semilla a datos
datos <- datos %>%
  left_join(sequences %>% select(mirna_name, seed_region), 
            by = c("miRNA name" = "mirna_name"))

# Metadatos
metadata <- read_csv(
  file.path(config$output_paths$outputs, "paso6a_metadatos", "paso6a_metadatos_integrados.csv"),
  show_col_types = FALSE
)

cat("  ✓ Datos cargados\n\n")

# ------------------------------------------------------------------------------
# PASO 10E.1: IDENTIFICAR MUESTRAS LONGITUDINALES
# ------------------------------------------------------------------------------

cat("⏰ PASO 10E.1: Identificando muestras longitudinales...\n")

# Muestras longitudinales ALS
longitudinal_samples <- metadata %>%
  filter(cohort == "ALS", is_longitudinal == TRUE)

enrolment_samples <- longitudinal_samples %>% 
  filter(timepoint == "Enrolment") %>%
  mutate(sample_vaf = paste0("VAF_", str_replace_all(sample, "\\.", "-")))

longitudinal_samples_later <- longitudinal_samples %>% 
  filter(timepoint == "Longitudinal") %>%
  mutate(sample_vaf = paste0("VAF_", str_replace_all(sample, "\\.", "-")))

cat("  ✓ Enrolment:", nrow(enrolment_samples), "\n")
cat("  ✓ Longitudinal:", nrow(longitudinal_samples_later), "\n\n")

# Filtrar columnas que existen
vaf_cols <- grep("^VAF_", colnames(datos), value = TRUE)
vaf_enrolment <- enrolment_samples$sample_vaf[enrolment_samples$sample_vaf %in% vaf_cols]
vaf_longitudinal <- longitudinal_samples_later$sample_vaf[longitudinal_samples_later$sample_vaf %in% vaf_cols]

cat("  ✓ Columnas VAF Enrolment:", length(vaf_enrolment), "\n")
cat("  ✓ Columnas VAF Longitudinal:", length(vaf_longitudinal), "\n\n")

if (length(vaf_enrolment) == 0 || length(vaf_longitudinal) == 0) {
  cat("  ⚠️ No hay suficientes datos longitudinales para análisis\n")
  cat("  → Finalizando paso\n\n")
  quit(save = "no", status = 0)
}

# ------------------------------------------------------------------------------
# PASO 10E.2: CAMBIOS TEMPORALES POR SECUENCIA SEMILLA
# ------------------------------------------------------------------------------

cat("🌱 PASO 10E.2: Analizando cambios por secuencia semilla...\n")

# G>T en semilla con datos temporales
gt_seed_temporal <- datos %>%
  filter(mutation_type == "G>T", region == "Seed", !is.na(seed_region)) %>%
  rowwise() %>%
  mutate(
    vaf_enrolment = mean(c_across(all_of(vaf_enrolment)), na.rm = TRUE),
    vaf_longitudinal = mean(c_across(all_of(vaf_longitudinal)), na.rm = TRUE),
    cambio = vaf_longitudinal - vaf_enrolment,
    direccion = case_when(
      cambio > 0 ~ "Aumento",
      cambio < 0 ~ "Disminucion",
      TRUE ~ "Sin cambio"
    )
  ) %>%
  ungroup()

# Agrupar por secuencia semilla
cambios_por_secuencia <- gt_seed_temporal %>%
  group_by(seed_region) %>%
  summarise(
    n_snvs = n(),
    cambio_promedio = mean(cambio, na.rm = TRUE),
    perc_disminuyen = round(sum(direccion == "Disminucion") / n() * 100, 1),
    perc_aumentan = round(sum(direccion == "Aumento") / n() * 100, 1),
    .groups = "drop"
  ) %>%
  filter(n_snvs >= 3) %>%
  arrange(desc(abs(cambio_promedio)))

cat("\n  📊 TOP SECUENCIAS POR CAMBIO TEMPORAL:\n")
print(head(cambios_por_secuencia, 15))

write_csv(cambios_por_secuencia, file.path(output_paso10e, "paso10e_cambios_por_secuencia.csv"))

# Específico de TGAGGTA (let-7)
tgaggta_temporal <- cambios_por_secuencia %>%
  filter(seed_region == "TGAGGTA")

cat("\n  🎯 TGAGGTA (let-7) ESPECÍFICAMENTE:\n")
if (nrow(tgaggta_temporal) > 0) {
  print(tgaggta_temporal)
} else {
  cat("    ⚠️ No encontrada en resumen (verificar datos)\n")
}

# Gráfica
top_seqs <- cambios_por_secuencia %>% head(20)

p1 <- ggplot(top_seqs, aes(x = reorder(seed_region, cambio_promedio), y = cambio_promedio)) +
  geom_col(aes(fill = seed_region == "TGAGGTA"), alpha = 0.8) +
  scale_fill_manual(values = c("FALSE" = "steelblue", "TRUE" = "#E31A1C"), guide = "none") +
  geom_hline(yintercept = 0, linetype = "dashed") +
  coord_flip() +
  labs(
    title = "Cambios Temporales por Secuencia Semilla",
    subtitle = "TGAGGTA (let-7) destacada en rojo - Enrolment → Longitudinal",
    x = "Secuencia Semilla",
    y = "Cambio VAF Promedio"
  ) +
  theme_minimal()

ggsave(file.path(output_figures, "paso10e_cambios_por_secuencia.png"),
       p1, width = 10, height = 8)
cat("\n  ✓ Figura 'paso10e_cambios_por_secuencia.png' generada\n\n")

# ------------------------------------------------------------------------------
# PASO 10E.3: ANÁLISIS ESPECÍFICO let-7
# ------------------------------------------------------------------------------

cat("🎯 PASO 10E.3: Análisis detallado temporal de let-7...\n")

let7_temporal <- gt_seed_temporal %>%
  filter(str_detect(`miRNA name`, "let-7|miR-98"))

let7_temporal_summary <- let7_temporal %>%
  group_by(`miRNA name`) %>%
  summarise(
    n = n(),
    cambio_promedio = mean(cambio, na.rm = TRUE),
    perc_disminuyen = round(sum(direccion == "Disminucion") / n() * 100, 1),
    .groups = "drop"
  ) %>%
  arrange(cambio_promedio)

cat("\n  📊 CAMBIOS TEMPORALES POR MIEMBRO let-7:\n")
print(let7_temporal_summary)

write_csv(let7_temporal_summary, file.path(output_paso10e, "paso10e_let7_temporal.csv"))

# Test
test_let7 <- t.test(let7_temporal$cambio)

cat("\n  🔬 Test t (cambio en let-7):\n")
cat("    Media de cambio:", round(test_let7$estimate, 6), "\n")
cat("    p-value:", format.pval(test_let7$p.value), "\n\n")

# ------------------------------------------------------------------------------
# PASO 10E.4: RESUMEN EJECUTIVO
# ------------------------------------------------------------------------------

cat("📋 Generando resumen ejecutivo...\n")

resumen <- list(
  n_secuencias_analizadas = nrow(cambios_por_secuencia),
  n_let7_snvs = nrow(let7_temporal),
  let7_cambio_promedio = mean(let7_temporal$cambio, na.rm = TRUE),
  let7_perc_disminuyen = round(sum(let7_temporal$direccion == "Disminucion") / nrow(let7_temporal) * 100, 1),
  let7_p_value = test_let7$p.value
)

write_json(resumen, file.path(output_paso10e, "paso10e_resumen.json"), pretty = TRUE)

cat("\n")
cat("╔════════════════════════════════════════════════════════════════════════╗\n")
cat("║                  RESUMEN EJECUTIVO - PASO 10E                         ║\n")
cat("╚════════════════════════════════════════════════════════════════════════╝\n\n")

cat("⏰ ANÁLISIS TEMPORAL:\n")
cat("  • Secuencias analizadas:", resumen$n_secuencias_analizadas, "\n\n")

cat("🎯 let-7 (TGAGGTA):\n")
cat("  • SNVs analizados:", resumen$n_let7_snvs, "\n")
cat("  • Cambio promedio:", round(resumen$let7_cambio_promedio, 6), "\n")
cat("  • % que disminuyen:", resumen$let7_perc_disminuyen, "%\n")
cat("  • p-value:", format.pval(resumen$let7_p_value), "\n\n")

cat("✅ ANÁLISIS COMPLETADO\n")
cat("  • Figuras generadas: 1-2\n")
cat("  • Tablas guardadas: 2\n")
cat("  • Ubicación:", output_paso10e, "\n\n")

cat("════════════════════════════════════════════════════════════════════════\n")








