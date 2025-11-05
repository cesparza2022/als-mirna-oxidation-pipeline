#!/usr/bin/env Rscript
# ==============================================================================
# VALIDACIÓN PASO 2: VALIDAR PATRÓN let-7 (2, 4, 5) SIN OUTLIERS
# ==============================================================================

library(tidyverse)
library(jsonlite)

cat("╔════════════════════════════════════════════════════════════════════════╗\n")
cat("║        VALIDACIÓN PASO 2: PATRÓN let-7 (2, 4, 5)                      ║\n")
cat("╚════════════════════════════════════════════════════════════════════════╝\n\n")

output_dir <- "outputs"
figures_dir <- "figures"

# Cargar datos sin outliers
cat("📂 Cargando datos sin outliers...\n")
datos <- readRDS(file.path(output_dir, "datos_sin_outliers.rds"))
cat("  ✓ Datos cargados:", nrow(datos), "SNVs\n\n")

# ------------------------------------------------------------------------------
# let-7 con G>T en semilla
# ------------------------------------------------------------------------------

cat("🎯 Analizando let-7 family...\n")

let7_members <- c("hsa-let-7a-5p", "hsa-let-7b-5p", "hsa-let-7c-5p", 
                  "hsa-let-7d-5p", "hsa-let-7e-5p", "hsa-let-7f-5p",
                  "hsa-let-7g-5p", "hsa-let-7i-5p", "hsa-miR-98-5p")

let7_gt_seed <- datos %>%
  filter(
    `miRNA name` %in% let7_members,
    mutation_type == "G>T",
    region == "Seed"
  )

cat("  ✓ let-7 con G>T en semilla:", nrow(let7_gt_seed), "SNVs\n\n")

# Patrón por posición
let7_pattern <- let7_gt_seed %>%
  group_by(`miRNA name`) %>%
  summarise(
    tiene_pos2 = 2 %in% position,
    tiene_pos4 = 4 %in% position,
    tiene_pos5 = 5 %in% position,
    patron = paste(sort(unique(position)), collapse = ","),
    .groups = "drop"
  )

cat("📊 PATRÓN POR miRNA:\n\n")
print(let7_pattern)

# Comparación con original
comparacion_let7 <- tibble(
  Metrica = c(
    "N let-7 members",
    "N con G>T semilla",
    "N con pos 2",
    "N con pos 4", 
    "N con pos 5",
    "N con patron 2,4,5"
  ),
  Con_outliers = c(9, 9, 9, 9, 8, 8),  # Del paso 10A
  Sin_outliers = c(
    length(let7_members),
    nrow(let7_pattern),
    sum(let7_pattern$tiene_pos2),
    sum(let7_pattern$tiene_pos4),
    sum(let7_pattern$tiene_pos5),
    sum(let7_pattern$patron == "2,4,5")
  )
) %>%
  mutate(Diferencia = Sin_outliers - Con_outliers)

cat("\n📈 COMPARACIÓN CON vs SIN OUTLIERS:\n\n")
print(comparacion_let7)

write_csv(let7_pattern, file.path(output_dir, "val_paso2_let7_patron.csv"))
write_csv(comparacion_let7, file.path(output_dir, "val_paso2_comparacion.csv"))

# Resumen
resumen <- list(
  patron_245_persiste = all(comparacion_let7$Sin_outliers == comparacion_let7$Con_outliers),
  n_con_patron = sum(let7_pattern$patron == "2,4,5"),
  penetrancia = round(sum(let7_pattern$patron == "2,4,5") / nrow(let7_pattern) * 100, 1)
)

write_json(resumen, file.path(output_dir, "val_paso2_resumen.json"), pretty = TRUE)

cat("\n╔════════════════════════════════════════════════════════════════════════╗\n")
cat("║                  RESUMEN - VAL PASO 2                                 ║\n")
cat("╚════════════════════════════════════════════════════════════════════════╝\n\n")

if (resumen$patron_245_persiste) {
  cat("✅ PATRÓN let-7 (2,4,5) ES ROBUSTO ⭐⭐⭐⭐⭐\n\n")
  cat("  • Patrón IDÉNTICO con y sin outliers\n")
  cat("  • 100% reproducible\n")
  cat("  • NO dependiente de outliers\n")
  cat("  • Hallazgo VALIDADO\n\n")
} else {
  cat("⚠️ PATRÓN let-7 CAMBIÓ\n\n")
  cat("  • Diferencias detectadas\n")
  cat("  • Requiere investigación\n\n")
}

cat("✅ SIGUIENTE: val_paso3_validar_mir4500.R\n\n")
cat("════════════════════════════════════════════════════════════════════════\n")








