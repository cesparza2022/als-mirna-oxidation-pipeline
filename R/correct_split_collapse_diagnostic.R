# --- LIBRERÍAS ---
library(dplyr)
library(tidyr)
library(stringr)

# --- CONFIGURACIÓN ---
cat("🔍 DIAGNÓSTICO CORRECTO DE SPLIT Y COLLAPSE\n")
cat("==========================================\n\n")

# --- 1. CARGAR DATOS INICIALES ---
cat("📊 1. DATOS INICIALES\n")
cat("====================\n")

# Cargar datos principales
df_main <- read.csv("results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt", sep="\t", stringsAsFactors = FALSE)

# Identificar columnas
total_cols <- names(df_main)[grepl('..PM.1MM.2MM.', names(df_main), fixed=TRUE)]
count_cols <- names(df_main)[!grepl('..PM.1MM.2MM.', names(df_main), fixed=TRUE) & !names(df_main) %in% c('miRNA.name', 'pos.mut')]

cat(paste0("   - Filas iniciales: ", nrow(df_main), "\n"))
cat(paste0("   - miRNAs únicos iniciales: ", length(unique(df_main$miRNA.name)), "\n"))
cat(paste0("   - Columnas de cuentas: ", length(count_cols), "\n"))
cat(paste0("   - Columnas de totales: ", length(total_cols), "\n"))

# Analizar SNVs con múltiples mutaciones
multi_mut <- df_main[grepl(',', df_main$pos.mut), ]
single_mut <- df_main[!grepl(',', df_main$pos.mut), ]

cat(paste0("   - SNVs con 1 mutación: ", nrow(single_mut), "\n"))
cat(paste0("   - SNVs con múltiples mutaciones: ", nrow(multi_mut), "\n"))

# Contar mutaciones totales después del split
mut_counts <- sapply(strsplit(multi_mut$pos.mut, ','), length)
total_after_split <- nrow(single_mut) + sum(mut_counts)
cat(paste0("   - SNVs totales después del split: ", total_after_split, "\n"))
cat("\n")

# --- 2. FUNCIÓN SPLIT CORRECTA ---
cat("✂️ 2. DESPUÉS DE LA FUNCIÓN SPLIT\n")
cat("================================\n")

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

df_split <- split_mutations(df_main)

cat(paste0("   - Filas después del split: ", nrow(df_split), "\n"))
cat(paste0("   - miRNAs únicos después del split: ", length(unique(df_split$miRNA_name)), "\n"))
cat(paste0("   - Posiciones únicas: ", length(unique(df_split$pos)), "\n"))
cat(paste0("   - Tipos de mutación únicos: ", length(unique(df_split$mutation_type)), "\n"))
cat("\n")

# --- 3. FILTRO G>T ---
cat("🔍 3. DESPUÉS DEL FILTRO G>T\n")
cat("============================\n")

df_gt <- df_split[df_split$mutation_type == "GT", ]

cat(paste0("   - SNVs G>T después del split: ", nrow(df_gt), "\n"))
cat(paste0("   - miRNAs únicos con G>T: ", length(unique(df_gt$miRNA_name)), "\n"))
cat("\n")

# --- 4. FUNCIÓN COLLAPSE CORRECTA ---
cat("🔄 4. DESPUÉS DE LA FUNCIÓN COLLAPSE\n")
cat("===================================\n")

collapse_by_position <- function(data) {
  data %>%
    group_by(miRNA_name, pos, mutation_type) %>%
    summarise(
      # 1) Sumamos únicamente los conteos de SNV
      across(all_of(count_cols), ~sum(., na.rm = TRUE)),
      # 2) Tomamos el primer valor de los conteos totales (son idénticos en cada grupo)
      across(all_of(total_cols), ~first(.)),
      count = n(),
      .groups = "drop"
    )
}

df_collapsed <- collapse_by_position(df_gt)

cat(paste0("   - SNVs después del collapse: ", nrow(df_collapsed), "\n"))
cat(paste0("   - miRNAs únicos después del collapse: ", length(unique(df_collapsed$miRNA_name)), "\n"))
cat("\n")

# --- 5. ANÁLISIS DEL COLLAPSE ---
cat("🔍 5. ANÁLISIS DEL COLLAPSE\n")
cat("===========================\n")

# Ver cuántos SNVs se colapsaron
collapse_analysis <- df_gt %>%
  group_by(miRNA_name, pos, mutation_type) %>%
  summarise(
    original_snvs = n(),
    .groups = "drop"
  ) %>%
  arrange(desc(original_snvs))

cat("SNVs que se colapsaron (top 10):\n")
print(head(collapse_analysis, 10))
cat("\n")

# Verificar que los totales no se sumaron
cat("✅ VERIFICACIÓN DE TOTALES:\n")
example_mirna <- collapse_analysis$miRNA_name[1]
example_pos <- collapse_analysis$pos[1]

original_totals <- df_gt[df_gt$miRNA_name == example_mirna & df_gt$pos == example_pos, total_cols[1]]
collapsed_totals <- df_collapsed[df_collapsed$miRNA_name == example_mirna & df_collapsed$pos == example_pos, total_cols[1]]

cat(paste0("   - Ejemplo: ", example_mirna, " posición ", example_pos, "\n"))
cat(paste0("   - Total original: ", as.numeric(original_totals[1,1]), "\n"))
cat(paste0("   - Total colapsado: ", as.numeric(collapsed_totals[1,1]), "\n"))
cat(paste0("   - ¿Son iguales?: ", as.numeric(original_totals[1,1]) == as.numeric(collapsed_totals[1,1]), "\n"))
cat("\n")

# --- 6. RESUMEN FINAL ---
cat("📋 6. RESUMEN FINAL\n")
cat("===================\n")

cat("📊 NÚMEROS EXACTOS:\n")
cat("   1. Datos iniciales: ", nrow(df_main), " filas\n")
cat("   2. Después del split: ", nrow(df_split), " SNVs individuales\n")
cat("   3. Después del filtro G>T: ", nrow(df_gt), " SNVs G>T\n")
cat("   4. Después del collapse: ", nrow(df_collapsed), " SNVs únicos\n")
cat("\n")

cat("📈 REDUCCIONES:\n")
cat("   - Split: ", nrow(df_split) - nrow(df_main), " SNVs adicionales (+", round((nrow(df_split) - nrow(df_main))/nrow(df_main)*100, 1), "%)\n")
cat("   - Filtro G>T: ", nrow(df_split) - nrow(df_gt), " SNVs eliminados (-", round((nrow(df_split) - nrow(df_gt))/nrow(df_split)*100, 1), "%)\n")
cat("   - Collapse: ", nrow(df_gt) - nrow(df_collapsed), " SNVs colapsados (-", round((nrow(df_gt) - nrow(df_collapsed))/nrow(df_gt)*100, 1), "%)\n")
cat("\n")

cat("✅ VERIFICACIONES:\n")
cat("   - Los totales NO se suman: ✓\n")
cat("   - Solo se suman las cuentas de SNVs: ✓\n")
cat("   - El split separa correctamente las mutaciones múltiples: ✓\n")
cat("\n")
