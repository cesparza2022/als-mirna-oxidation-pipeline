#!/usr/bin/env Rscript
# ============================================================================
# PREPARAR CANDIDATOS TIER 3 PARA PASO 3
# Crea archivo con los 6 candidatos TIER 3
# ============================================================================

library(dplyr)
library(readr)

cat("\n")
cat("╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║        📋 PREPARANDO CANDIDATOS TIER 3 PARA PASO 3                   ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

# ============================================================================
# CARGAR TODOS LOS CANDIDATOS
# ============================================================================

all_candidates <- read_csv("../ALS_CANDIDATES_ENHANCED.csv", show_col_types = FALSE)

cat(sprintf("📊 Total candidatos disponibles: %d\n\n", nrow(all_candidates)))

# ============================================================================
# FILTRAR TIER 3
# ============================================================================

cat("🔍 Filtrando TIER 3 (posiciones 2,3,5 enriquecidas)...\n\n")

tier3_candidates <- all_candidates %>%
  filter(Has_Pos_2_3_5 == TRUE) %>%
  arrange(desc(FC))

cat(sprintf("✅ Candidatos TIER 3: %d\n\n", nrow(tier3_candidates)))

# Mostrar lista
cat("📋 LISTA DE CANDIDATOS TIER 3:\n")
cat(paste(rep("─", 70), collapse = ""), "\n\n")

for (i in 1:nrow(tier3_candidates)) {
  cat(sprintf("%d. %s\n", i, tier3_candidates$miRNA[i]))
  cat(sprintf("   FC: %.2fx | p: %.4f | Posiciones: %s\n", 
              tier3_candidates$FC[i], 
              tier3_candidates$padj[i],
              tier3_candidates$Positions[i]))
  
  # Agregar info conocida
  known_info <- case_when(
    tier3_candidates$miRNA[i] == "hsa-miR-21-5p" ~ "Oncomir, neurología",
    tier3_candidates$miRNA[i] == "hsa-let-7d-5p" ~ "Tumor suppressor",
    tier3_candidates$miRNA[i] == "hsa-miR-1-3p" ~ "Músculo, neurología",
    tier3_candidates$miRNA[i] == "hsa-miR-185-5p" ~ "Regulación celular",
    tier3_candidates$miRNA[i] == "hsa-miR-24-3p" ~ "Apoptosis, proliferación",
    tier3_candidates$miRNA[i] == "hsa-miR-423-3p" ~ "Cardiovascular",
    TRUE ~ ""
  )
  
  if (known_info != "") {
    cat(sprintf("   Conocido: %s ✅\n", known_info))
  }
  cat("\n")
}

# ============================================================================
# GUARDAR PARA PASO 3
# ============================================================================

# Crear directorio data si no existe
dir.create("data", showWarnings = FALSE, recursive = TRUE)

# Guardar solo columnas necesarias
tier3_for_paso3 <- tier3_candidates %>%
  select(miRNA, FC, padj, Mean_ALS, Mean_Control, Positions, Priority)

write_csv(tier3_for_paso3, "data/ALS_candidates_TIER3.csv")

cat(paste(rep("═", 70), collapse = ""), "\n")
cat("✅ CANDIDATOS TIER 3 PREPARADOS\n")
cat(paste(rep("═", 70), collapse = ""), "\n\n")

cat("📁 Archivo guardado: data/ALS_candidates_TIER3.csv\n\n")

cat("🚀 SIGUIENTE:\n")
cat("   1. Ejecutar: Rscript scripts/02_query_targets.R\n")
cat("   2. Ejecutar: Rscript scripts/03_pathway_enrichment.R\n")
cat("   3. Ejecutar: Rscript scripts/04_network_analysis.R\n")
cat("   4. Ejecutar: Rscript scripts/05_create_figures.R\n")
cat("   5. Ejecutar: Rscript scripts/06_create_HTML.R\n\n")

cat("⏱️  Tiempo total estimado: ~2-3 horas\n\n")

cat("💡 TIP: O ejecutar todo con:\n")
cat("   Rscript RUN_PASO3_TIER3_COMPLETE.R\n\n")

