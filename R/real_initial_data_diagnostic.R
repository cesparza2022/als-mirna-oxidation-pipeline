# --- LIBRERÍAS ---
library(dplyr)
library(tidyr)
library(stringr)

# --- CONFIGURACIÓN ---
cat("🔍 DIAGNÓSTICO CON DATOS INICIALES REALES\n")
cat("==========================================\n\n")

# --- 1. CARGAR DATOS INICIALES REALES ---
cat("📊 1. DATOS INICIALES REALES\n")
cat("============================\n")

# Cargar datos principales
df_main <- read.csv("results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt", sep="\t", stringsAsFactors = FALSE)

# Filtrar solo mutaciones G>T
df_gt <- df_main[grepl(':GT$', df_main$pos.mut), ]

sample_cols <- names(df_gt)[!names(df_gt) %in% c("miRNA.name", "pos.mut")]

cat(paste0("   - Filas iniciales (SNVs G>T): ", nrow(df_gt), "\n"))
cat(paste0("   - miRNAs únicos iniciales: ", length(unique(df_gt$miRNA.name)), "\n"))
cat(paste0("   - Muestras: ", length(sample_cols), "\n"))
cat(paste0("   - Valores > 0: ", sum(df_gt[, sample_cols] > 0, na.rm=TRUE), "\n"))
cat(paste0("   - Valores > 50: ", sum(df_gt[, sample_cols] > 50, na.rm=TRUE), "\n"))
cat("\n")

# --- 2. FUNCIÓN SPLIT ---
cat("✂️ 2. DESPUÉS DE LA FUNCIÓN SPLIT\n")
cat("================================\n")

split_mutations <- function(data) {
  data %>%
    mutate(
      miRNA_name = miRNA.name,
      pos = as.integer(str_extract(pos.mut, "^([0-9]+):", group = 1)),
      mutation_type = str_extract(pos.mut, ":([A-Z]+)$", group = 1)
    ) %>%
    filter(!is.na(pos))
}

df_split <- split_mutations(df_gt)

cat(paste0("   - Filas después del split (SNVs): ", nrow(df_split), "\n"))
cat(paste0("   - miRNAs únicos después del split: ", length(unique(df_split$miRNA_name)), "\n"))
cat(paste0("   - Posiciones únicas: ", length(unique(df_split$pos)), "\n"))
cat(paste0("   - Posiciones: ", paste(sort(unique(df_split$pos)), collapse = ", "), "\n"))
cat("\n")

# --- 3. FUNCIÓN COLLAPSE ---
cat("🔄 3. DESPUÉS DE LA FUNCIÓN COLLAPSE\n")
cat("===================================\n")

collapse_by_position <- function(data) {
  data %>%
    group_by(miRNA_name, pos, mutation_type) %>%
    summarise(
      across(all_of(sample_cols), ~sum(., na.rm = TRUE)),
      count = n(),
      .groups = "drop"
    )
}

df_collapsed <- collapse_by_position(df_split)

cat(paste0("   - Filas después del collapse (SNVs): ", nrow(df_collapsed), "\n"))
cat(paste0("   - miRNAs únicos después del collapse: ", length(unique(df_collapsed$miRNA_name)), "\n"))
cat("\n")

# --- 4. ANÁLISIS DEL COLLAPSE ---
cat("🔍 4. ANÁLISIS DEL COLLAPSE\n")
cat("===========================\n")

# Ver cuántos SNVs se colapsaron
collapse_analysis <- df_split %>%
  group_by(miRNA_name, pos, mutation_type) %>%
  summarise(
    original_snvs = n(),
    .groups = "drop"
  ) %>%
  arrange(desc(original_snvs))

cat("SNVs que se colapsaron (top 10):\n")
print(head(collapse_analysis, 10))
cat("\n")

# --- 5. FILTRO VAF > 50% ---
cat("🚫 5. FILTRO VAF > 50%\n")
cat("======================\n")

# Convertir a VAF (asumiendo que los valores son counts, necesitamos normalizar)
# Por ahora solo mostramos valores > 50
high_values <- df_collapsed[, sample_cols] > 50
high_count <- sum(high_values, na.rm = TRUE)

cat(paste0("   - Valores > 50: ", high_count, "\n"))
cat(paste0("   - Porcentaje de valores > 50: ", round(high_count / (nrow(df_collapsed) * length(sample_cols)) * 100, 2), "%\n"))
cat("\n")

# --- 6. RESUMEN FINAL ---
cat("📋 6. RESUMEN FINAL\n")
cat("===================\n")
cat("   - Datos iniciales: ", nrow(df_gt), " SNVs G>T de ", length(unique(df_gt$miRNA.name)), " miRNAs\n")
cat("   - Después del split: ", nrow(df_split), " SNVs\n")
cat("   - Después del collapse: ", nrow(df_collapsed), " SNVs\n")
cat("   - Reducción por collapse: ", round((1 - nrow(df_collapsed)/nrow(df_split)) * 100, 2), "%\n")
cat("\n")

cat("✅ DIAGNÓSTICO COMPLETADO\n")
cat("=========================\n")









