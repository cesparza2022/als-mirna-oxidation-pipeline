#!/usr/bin/env Rscript
# ==============================================================================
# VALIDACIÓN PASO 1: PREPARAR DATOS SIN OUTLIERS
# ==============================================================================

library(tidyverse)
library(jsonlite)

cat("╔════════════════════════════════════════════════════════════════════════╗\n")
cat("║        VALIDACIÓN PASO 1: PREPARAR DATOS SIN OUTLIERS                 ║\n")
cat("╚════════════════════════════════════════════════════════════════════════╝\n\n")

# Cargar configuración
source("../config_pipeline.R")
source("../functions_pipeline.R")

# Directorios
output_dir <- "outputs"
figures_dir <- "figures"
dir.create(output_dir, showWarnings = FALSE)
dir.create(figures_dir, showWarnings = FALSE)

# ------------------------------------------------------------------------------
# CARGAR Y FILTRAR DATOS
# ------------------------------------------------------------------------------

cat("📂 Cargando datos y excluyendo outliers...\n")

raw_data <- read_tsv(config$data_paths$raw_data, show_col_types = FALSE)

# Outliers a excluir (identificados en paso5a)
outliers_samples <- c(
  "Magen-ALS-enrolment-bloodplasma-SRR13934430",
  "Magen-ALS-longitudinal-bloodplasma-SRR13934435",
  "Magen-ALS-longitudinal-bloodplasma-SRR13934446",
  "Magen-ALS-longitudinal-bloodplasma-SRR13934453",
  "Magen-ALS-longitudinal-bloodplasma-SRR13934457",
  "Magen-ALS-longitudinal-bloodplasma-SRR13934461",
  "Magen-Control-enrolment-bloodplasma-SRR13934468"
)

# Buscar columnas de outliers (ambas versiones: guiones y puntos)
all_cols <- colnames(raw_data)
cols_to_remove <- character()

for (sample in outliers_samples) {
  matching <- grep(sample, all_cols, value = TRUE, fixed = TRUE)
  sample_dots <- str_replace_all(sample, "-", "\\.")
  matching_dots <- grep(sample_dots, all_cols, value = TRUE, fixed = TRUE)
  cols_to_remove <- c(cols_to_remove, matching, matching_dots)
}
cols_to_remove <- unique(cols_to_remove)

cat("  ✓ Outliers a excluir:", length(outliers_samples), "\n")
cat("  ✓ Columnas a remover:", length(cols_to_remove), "\n\n")

# Filtrar
datos_filtrados <- raw_data %>%
  select(-all_of(cols_to_remove))

# ------------------------------------------------------------------------------
# APLICAR PIPELINE
# ------------------------------------------------------------------------------

cat("🔄 Aplicando pipeline completo...\n\n")

datos_split <- apply_split_collapse(datos_filtrados)
datos_vaf <- calculate_vafs(datos_split)
datos_final <- filter_high_vafs(datos_vaf, threshold = 0.5)

# Anotaciones
datos_final <- datos_final %>%
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

cat("  ✓ Pipeline completado\n\n")

# ------------------------------------------------------------------------------
# RESUMEN COMPARATIVO
# ------------------------------------------------------------------------------

cat("📊 Generando resumen comparativo...\n")

# Valores del análisis original (con outliers) - de documentación
comparacion <- tibble(
  Metrica = c(
    "N muestras",
    "N miRNAs únicos", 
    "N SNVs únicos",
    "N G>T totales",
    "N G>T en semilla"
  ),
  Con_outliers = c(415, 1728, 29254, 2091, 397),
  Sin_outliers = c(
    ncol(datos_filtrados) / 2 - 1,  # count + total, -2 meta cols
    n_distinct(datos_final$`miRNA name`),
    nrow(datos_final),
    sum(datos_final$mutation_type == "G>T", na.rm = TRUE),
    sum(datos_final$mutation_type == "G>T" & datos_final$region == "Seed", na.rm = TRUE)
  )
) %>%
  mutate(
    Diferencia = Sin_outliers - Con_outliers,
    Perc_cambio = round((Diferencia / Con_outliers) * 100, 1)
  )

cat("\n  📈 COMPARACIÓN:\n\n")
print(comparacion)

write_csv(comparacion, file.path(output_dir, "val_paso1_comparacion.csv"))

# ------------------------------------------------------------------------------
# GUARDAR DATOS
# ------------------------------------------------------------------------------

cat("\n💾 Guardando datos procesados...\n")

saveRDS(datos_final, file.path(output_dir, "datos_sin_outliers.rds"))
write_csv(datos_final, file.path(output_dir, "datos_sin_outliers.csv"))

resumen <- list(
  n_outliers_excluidos = 7,
  n_columnas_removidas = length(cols_to_remove),
  n_muestras_final = round(ncol(datos_filtrados) / 2 - 1),
  n_mirnas = n_distinct(datos_final$`miRNA name`),
  n_snvs = nrow(datos_final),
  n_gt_total = sum(datos_final$mutation_type == "G>T", na.rm = TRUE),
  n_gt_seed = sum(datos_final$mutation_type == "G>T" & datos_final$region == "Seed", na.rm = TRUE)
)

write_json(resumen, file.path(output_dir, "val_paso1_resumen.json"), pretty = TRUE)

cat("  ✓ Datos guardados\n\n")

# ------------------------------------------------------------------------------
# RESUMEN EJECUTIVO
# ------------------------------------------------------------------------------

cat("╔════════════════════════════════════════════════════════════════════════╗\n")
cat("║                  RESUMEN EJECUTIVO - VAL PASO 1                       ║\n")
cat("╚════════════════════════════════════════════════════════════════════════╝\n\n")

cat("✅ DATOS PREPARADOS SIN OUTLIERS\n\n")
cat("📊 CAMBIOS:\n")
cat("  • Muestras: 415 → ~", resumen$n_muestras_final, "(-", 7, ")\n")
cat("  • Columnas removidas:", resumen$n_columnas_removidas, "\n")
cat("  • SNVs:", comparacion$Sin_outliers[3], "(", comparacion$Perc_cambio[3], "%)\n")
cat("  • G>T totales:", comparacion$Sin_outliers[4], "(", comparacion$Perc_cambio[4], "%)\n")
cat("  • G>T semilla:", comparacion$Sin_outliers[5], "(", comparacion$Perc_cambio[5], "%)\n\n")

cat("✅ SIGUIENTE: val_paso2_validar_let7.R\n\n")
cat("════════════════════════════════════════════════════════════════════════\n")
