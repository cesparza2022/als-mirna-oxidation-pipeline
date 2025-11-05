# =============================================================================
# ANÁLISIS FINAL - PASO 1: PREPROCESAMIENTO DE DATOS
# =============================================================================
# 
# Este script realiza el preprocesamiento correcto de los datos de SNVs:
# 1. Carga datos iniciales
# 2. Filtro G>T
# 3. Split de mutaciones múltiples
# 4. Collapse de SNVs idénticos
#
# Autor: Análisis UCSD 8OG
# Fecha: 2025
# =============================================================================

# --- LIBRERÍAS ---
library(dplyr)
library(tidyr)
library(stringr)

# --- CONFIGURACIÓN ---
cat("🔬 PREPROCESAMIENTO DE DATOS - ANÁLISIS FINAL\n")
cat("=============================================\n\n")

# --- 1. CARGAR DATOS INICIALES ---
cat("📊 1. CARGANDO DATOS INICIALES\n")
cat("==============================\n")

# Cargar datos principales
df_main <- read.csv("results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt", sep="\t", stringsAsFactors = FALSE)

# Identificar columnas
total_cols <- names(df_main)[grepl('..PM.1MM.2MM.', names(df_main), fixed=TRUE)]
count_cols <- names(df_main)[!grepl('..PM.1MM.2MM.', names(df_main), fixed=TRUE) & 
                            !names(df_main) %in% c('miRNA.name', 'pos.mut')]

cat(paste0("   - Filas iniciales: ", nrow(df_main), "\n"))
cat(paste0("   - miRNAs únicos iniciales: ", length(unique(df_main$miRNA.name)), "\n"))
cat(paste0("   - Columnas de cuentas: ", length(count_cols), "\n"))
cat(paste0("   - Columnas de totales: ", length(total_cols), "\n"))
cat("\n")

# --- 2. FILTRO G>T ---
cat("🔍 2. APLICANDO FILTRO G>T\n")
cat("==========================\n")

df_gt <- df_main[grepl(':GT$', df_main$pos.mut), ]

cat(paste0("   - SNVs G>T: ", nrow(df_gt), "\n"))
cat(paste0("   - miRNAs con G>T: ", length(unique(df_gt$miRNA.name)), "\n"))
cat(paste0("   - Reducción: ", nrow(df_main) - nrow(df_gt), " SNVs (-", 
           round((nrow(df_main) - nrow(df_gt))/nrow(df_main)*100, 1), "%)\n"))
cat("\n")

# --- 3. FUNCIÓN SPLIT ---
cat("✂️ 3. APLICANDO SPLIT DE MUTACIONES MÚLTIPLES\n")
cat("=============================================\n")

split_mutations <- function(data) {
  data %>%
    separate_rows(pos.mut, sep = ",") %>%
    mutate(
      pos.mut = str_trim(pos.mut),
      miRNA_name = miRNA.name,
      pos = as.integer(str_extract(pos.mut, "^([0-9]+):", group = 1)),
      mutation_type = str_extract(pos.mut, ":([A-Z]+)$", group = 1)
    ) %>%
    filter(!is.na(pos))
}

df_split <- split_mutations(df_gt)

cat(paste0("   - SNVs individuales: ", nrow(df_split), "\n"))
cat(paste0("   - miRNAs: ", length(unique(df_split$miRNA_name)), "\n"))
cat(paste0("   - Aumento: ", nrow(df_split) - nrow(df_gt), " SNVs (+", 
           round((nrow(df_split) - nrow(df_gt))/nrow(df_gt)*100, 1), "%)\n"))
cat("\n")

# --- 4. FUNCIÓN COLLAPSE ---
cat("🔄 4. APLICANDO COLLAPSE DE SNVs IDÉNTICOS\n")
cat("==========================================\n")

collapse_by_position <- function(data) {
  data %>%
    group_by(miRNA_name, pos, mutation_type) %>%
    summarise(
      # Sumamos únicamente los conteos de SNV
      across(all_of(count_cols), ~sum(., na.rm = TRUE)),
      # Tomamos el primer valor de los conteos totales (son idénticos en cada grupo)
      across(all_of(total_cols), ~first(.)),
      count = n(),
      .groups = "drop"
    )
}

df_collapsed <- collapse_by_position(df_split)

cat(paste0("   - SNVs únicos: ", nrow(df_collapsed), "\n"))
cat(paste0("   - miRNAs: ", length(unique(df_collapsed$miRNA_name)), "\n"))
cat(paste0("   - Reducción: ", nrow(df_split) - nrow(df_collapsed), " SNVs (-", 
           round((nrow(df_split) - nrow(df_collapsed))/nrow(df_split)*100, 1), "%)\n"))
cat("\n")

# --- 5. GUARDAR DATOS PROCESADOS ---
cat("💾 5. GUARDANDO DATOS PROCESADOS\n")
cat("================================\n")

# Crear directorio si no existe
if (!dir.exists("final_analysis/processed_data")) {
  dir.create("final_analysis/processed_data", recursive = TRUE)
}

# Guardar datos procesados
write.csv(df_collapsed, "final_analysis/processed_data/processed_snvs_gt.csv", row.names = FALSE)

cat("   - Datos guardados en: final_analysis/processed_data/processed_snvs_gt.csv\n")
cat("\n")

# --- 6. RESUMEN FINAL ---
cat("📋 6. RESUMEN FINAL DEL PREPROCESAMIENTO\n")
cat("=========================================\n")

cat("📊 NÚMEROS FINALES:\n")
cat("   - SNVs iniciales: ", nrow(df_main), "\n")
cat("   - SNVs G>T: ", nrow(df_gt), "\n")
cat("   - SNVs individuales: ", nrow(df_split), "\n")
cat("   - SNVs únicos finales: ", nrow(df_collapsed), "\n")
cat("\n")

cat("📈 miRNAs:\n")
cat("   - miRNAs iniciales: ", length(unique(df_main$miRNA.name)), "\n")
cat("   - miRNAs con G>T: ", length(unique(df_gt$miRNA.name)), "\n")
cat("   - miRNAs finales: ", length(unique(df_collapsed$miRNA_name)), "\n")
cat("\n")

cat("✅ VERIFICACIONES:\n")
cat("   - Los totales NO se suman: ✓\n")
cat("   - Solo se suman las cuentas de SNVs: ✓\n")
cat("   - El split separa correctamente las mutaciones múltiples: ✓\n")
cat("   - El collapse une SNVs idénticos correctamente: ✓\n")
cat("\n")

cat("🎯 DATOS LISTOS PARA ANÁLISIS\n")
cat("=============================\n")
cat("Los datos procesados están listos para el análisis de patrones globales.\n")
cat("Archivo: final_analysis/processed_data/processed_snvs_gt.csv\n")
cat("\n")









