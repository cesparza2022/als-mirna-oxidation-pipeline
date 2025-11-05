#!/usr/bin/env Rscript
# ==============================================================================
# VALIDACIÓN PASO 3: VALIDAR PARADOJA miR-4500 SIN OUTLIERS
# ==============================================================================

library(tidyverse)
library(jsonlite)

cat("╔════════════════════════════════════════════════════════════════════════╗\n")
cat("║        VALIDACIÓN PASO 3: PARADOJA miR-4500                           ║\n")
cat("╚════════════════════════════════════════════════════════════════════════╝\n\n")

output_dir <- "outputs"
figures_dir <- "figures"

# Cargar datos
cat("📂 Cargando datos...\n")
datos <- readRDS(file.path(output_dir, "datos_sin_outliers.rds"))
cat("  ✓ Datos cargados\n\n")

# ------------------------------------------------------------------------------
# miR-4500 vs let-7
# ------------------------------------------------------------------------------

cat("🔬 Comparando miR-4500 vs let-7...\n")

vaf_cols <- grep("^VAF_", colnames(datos), value = TRUE)

# miR-4500
mir4500_data <- datos %>%
  filter(`miRNA name` == "hsa-miR-4500")

mir4500_stats <- mir4500_data %>%
  summarise(
    n_snvs = n(),
    n_gt_seed = sum(mutation_type == "G>T" & region == "Seed"),
    n_otras_seed = sum(mutation_type != "G>T" & region == "Seed")
  )

mir4500_vaf <- mir4500_data %>%
  rowwise() %>%
  mutate(mean_vaf = mean(c_across(all_of(vaf_cols)), na.rm = TRUE)) %>%
  ungroup() %>%
  summarise(vaf_promedio = mean(mean_vaf, na.rm = TRUE))

# let-7
let7_data <- datos %>%
  filter(str_detect(`miRNA name`, "let-7"))

let7_vaf <- let7_data %>%
  rowwise() %>%
  mutate(mean_vaf = mean(c_across(all_of(vaf_cols)), na.rm = TRUE)) %>%
  ungroup() %>%
  summarise(vaf_promedio = mean(mean_vaf, na.rm = TRUE))

# Ratio
ratio_vaf <- mir4500_vaf$vaf_promedio / let7_vaf$vaf_promedio

cat("\n📊 RESULTADOS:\n")
cat("  miR-4500:\n")
cat("    - SNVs totales:", mir4500_stats$n_snvs, "\n")
cat("    - G>T en semilla:", mir4500_stats$n_gt_seed, "\n")
cat("    - Otras en semilla:", mir4500_stats$n_otras_seed, "\n")
cat("    - VAF promedio:", round(mir4500_vaf$vaf_promedio, 5), "\n\n")

cat("  let-7:\n")
cat("    - VAF promedio:", round(let7_vaf$vaf_promedio, 5), "\n\n")

cat("  Ratio VAF (miR-4500 / let-7):", round(ratio_vaf, 1), "x\n\n")

# Comparación
comparacion <- tibble(
  Metrica = c(
    "VAF miR-4500",
    "VAF let-7",
    "Ratio (miR-4500/let-7)",
    "G>T semilla miR-4500"
  ),
  Con_outliers = c(0.0237, 0.000889, 26.6, 0),  # Del paso 10A
  Sin_outliers = c(
    mir4500_vaf$vaf_promedio,
    let7_vaf$vaf_promedio,
    ratio_vaf,
    mir4500_stats$n_gt_seed
  )
) %>%
  mutate(
    Diferencia = Sin_outliers - Con_outliers,
    Perc_cambio = round((Diferencia / Con_outliers) * 100, 1)
  )

cat("📈 COMPARACIÓN:\n\n")
print(comparacion)

write_csv(comparacion, file.path(output_dir, "val_paso3_comparacion_mir4500.csv"))

# Resumen
resumen <- list(
  mir4500_gt_seed = mir4500_stats$n_gt_seed,
  ratio_vaf = round(ratio_vaf, 1),
  paradoja_persiste = (mir4500_stats$n_gt_seed == 0 && ratio_vaf > 10)
)

write_json(resumen, file.path(output_dir, "val_paso3_resumen.json"), pretty = TRUE)

cat("\n╔════════════════════════════════════════════════════════════════════════╗\n")
cat("║                  RESUMEN - VAL PASO 3                                 ║\n")
cat("╚════════════════════════════════════════════════════════════════════════╝\n\n")

if (resumen$paradoja_persiste) {
  cat("✅ PARADOJA miR-4500 ES ROBUSTA ⭐⭐⭐⭐⭐\n\n")
  cat("  • Ratio VAF:", resumen$ratio_vaf, "x\n")
  cat("  • G>T en semilla:", resumen$mir4500_gt_seed, "\n")
  cat("  • Paradoja VALIDADA\n")
  cat("  • NO dependiente de outliers\n\n")
} else {
  cat("⚠️ PARADOJA CAMBIÓ\n\n")
}

cat("✅ SIGUIENTE: val_paso4_resumen_final.R\n\n")
cat("════════════════════════════════════════════════════════════════════════\n")








