# --- LIBRERÍAS ---
library(dplyr)
library(tidyr)
library(stringr)

# --- CONFIGURACIÓN ---
cat("🔍 DIAGNÓSTICO COMPLETO DE SPLIT Y COLLAPSE\n")
cat("============================================\n\n")

# --- 1. CARGAR DATOS INICIALES ---
cat("📊 1. DATOS INICIALES\n")
cat("====================\n")

# Cargar datos principales
df_main <- read.csv("results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt", sep="\t", stringsAsFactors = FALSE)

# Identificar columnas
total_cols <- names(df_main)[grepl('..PM.1MM.2MM.', names(df_main), fixed=TRUE)]
count_cols <- names(df_main)[!grepl('..PM.1MM.2MM.', names(df_main), fixed=TRUE) & !names(df_main) %in% c('miRNA.name', 'pos.mut')]

cat(paste0("   - Filas iniciales (SNVs): ", nrow(df_main), "\n"))
cat(paste0("   - miRNAs únicos iniciales: ", length(unique(df_main$miRNA.name)), "\n"))
cat(paste0("   - Columnas de cuentas: ", length(count_cols), "\n"))
cat(paste0("   - Columnas de totales: ", length(total_cols), "\n"))
cat("\n")

# --- 2. FILTRAR SOLO MUTACIONES G>T ---
cat("🧬 2. FILTRAR MUTACIONES G>T\n")
cat("============================\n")

# Filtrar solo mutaciones G>T (que terminan en GT)
df_gt <- df_main[grepl(':GT$', df_main$pos.mut), ]

cat(paste0("   - SNVs G>T iniciales: ", nrow(df_gt), "\n"))
cat(paste0("   - miRNAs únicos con G>T: ", length(unique(df_gt$miRNA.name)), "\n"))
cat(paste0("   - Reducción por filtro G>T: ", round((1 - nrow(df_gt)/nrow(df_main)) * 100, 2), "%\n"))
cat("\n")

# --- 3. FUNCIÓN SPLIT ---
cat("✂️ 3. DESPUÉS DE LA FUNCIÓN SPLIT\n")
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

cat(paste0("   - SNVs después del split: ", nrow(df_split), "\n"))
cat(paste0("   - miRNAs únicos después del split: ", length(unique(df_split$miRNA_name)), "\n"))
cat(paste0("   - Posiciones únicas: ", length(unique(df_split$pos)), "\n"))
cat(paste0("   - Posiciones: ", paste(sort(unique(df_split$pos)), collapse = ", "), "\n"))
cat(paste0("   - Reducción por split: ", round((1 - nrow(df_split)/nrow(df_gt)) * 100, 2), "%\n"))
cat("\n")

# --- 4. FUNCIÓN COLLAPSE CORREGIDA ---
cat("🔄 4. DESPUÉS DE LA FUNCIÓN COLLAPSE (CORREGIDA)\n")
cat("===============================================\n")

collapse_by_position <- function(data) {
  data %>%
    group_by(miRNA_name, pos, mutation_type) %>%
    summarise(
      # 1) Sumamos únicamente los conteos de SNV
      across(all_of(count_cols), ~sum(., na.rm = TRUE)),
      # 2) Tomamos el primer valor de los conteos totales (son idénticos en cada split)
      across(all_of(total_cols), ~first(.)),
      count = n(),
      .groups = "drop"
    )
}

df_collapsed <- collapse_by_position(df_split)

cat(paste0("   - SNVs después del collapse: ", nrow(df_collapsed), "\n"))
cat(paste0("   - miRNAs únicos después del collapse: ", length(unique(df_collapsed$miRNA_name)), "\n"))
cat(paste0("   - Reducción por collapse: ", round((1 - nrow(df_collapsed)/nrow(df_split)) * 100, 2), "%\n"))
cat("\n")

# --- 5. ANÁLISIS DEL COLLAPSE ---
cat("🔍 5. ANÁLISIS DEL COLLAPSE\n")
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

# --- 6. VERIFICACIÓN DE TOTALES ---
cat("🔍 6. VERIFICACIÓN DE TOTALES\n")
cat("=============================\n")

# Verificar que los totales no se sumaron incorrectamente
example_mirna <- collapse_analysis$miRNA_name[1]
example_pos <- collapse_analysis$pos[1]

# Obtener datos originales para este miRNA y posición
original_data <- df_split[df_split$miRNA_name == example_mirna & df_split$pos == example_pos, ]
collapsed_data <- df_collapsed[df_collapsed$miRNA_name == example_mirna & df_collapsed$pos == example_pos, ]

cat(paste0("Ejemplo: ", example_mirna, " posición ", example_pos, "\n"))
cat(paste0("   - SNVs originales: ", nrow(original_data), "\n"))
cat(paste0("   - SNVs colapsados: ", nrow(collapsed_data), "\n"))
cat(paste0("   - Total original (primera muestra): ", original_data[1, total_cols[1]], "\n"))
cat(paste0("   - Total colapsado (primera muestra): ", collapsed_data[1, total_cols[1]], "\n"))
cat(paste0("   - ¿Totales iguales? ", original_data[1, total_cols[1]] == collapsed_data[1, total_cols[1]], "\n"))
cat("\n")

# --- 7. FILTRO VAF > 50% ---
cat("🚫 7. FILTRO VAF > 50%\n")
cat("======================\n")

# Calcular VAF para cada muestra
vaf_data <- df_collapsed
for(i in 1:length(count_cols)) {
  count_col <- count_cols[i]
  total_col <- total_cols[i]
  vaf_col <- paste0("VAF_", i)
  
  # Calcular VAF = cuenta / total
  vaf_data[[vaf_col]] <- vaf_data[[count_col]] / vaf_data[[total_col]]
  
  # Convertir VAF > 50% a NaN
  vaf_data[[vaf_col]][vaf_data[[vaf_col]] > 0.5] <- NA
}

# Contar VAFs > 50%
high_vaf_count <- 0
for(i in 1:length(count_cols)) {
  vaf_col <- paste0("VAF_", i)
  high_vaf_count <- high_vaf_count + sum(vaf_data[[vaf_col]] > 0.5, na.rm = TRUE)
}

cat(paste0("   - VAFs > 50% convertidos a NaN: ", high_vaf_count, "\n"))
cat(paste0("   - Porcentaje de VAFs > 50%: ", round(high_vaf_count / (nrow(df_collapsed) * length(count_cols)) * 100, 2), "%\n"))
cat("\n")

# --- 8. RESUMEN FINAL ---
cat("📋 8. RESUMEN FINAL\n")
cat("===================\n")
cat("   - Datos iniciales: ", nrow(df_main), " SNVs de ", length(unique(df_main$miRNA.name)), " miRNAs\n")
cat("   - Después del filtro G>T: ", nrow(df_gt), " SNVs de ", length(unique(df_gt$miRNA.name)), " miRNAs\n")
cat("   - Después del split: ", nrow(df_split), " SNVs de ", length(unique(df_split$miRNA_name)), " miRNAs\n")
cat("   - Después del collapse: ", nrow(df_collapsed), " SNVs de ", length(unique(df_collapsed$miRNA_name)), " miRNAs\n")
cat("   - Reducción total: ", round((1 - nrow(df_collapsed)/nrow(df_main)) * 100, 2), "%\n")
cat("   - VAFs > 50%: ", high_vaf_count, " (", round(high_vaf_count / (nrow(df_collapsed) * length(count_cols)) * 100, 2), "%)\n")
cat("\n")

cat("✅ DIAGNÓSTICO COMPLETADO\n")
cat("=========================\n")
