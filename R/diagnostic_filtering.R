#!/usr/bin/env Rscript

# DIAGNÓSTICO DE FILTRADO DE miRNAs
# Analizar paso a paso dónde se van perdiendo los miRNAs

library(dplyr)
library(stringr)
library(readr)
library(tibble) # Para column_to_rownames

cat("🔍 DIAGNÓSTICO DE FILTRADO DE miRNAs\n")
cat("=====================================\n\n")

# 1. Cargar datos originales
cat("📊 PASO 1: Cargando datos originales...\n")
# Usar el archivo principal que contiene más miRNAs y mutaciones G>T
df <- read_tsv("results/miRNA_count.Q38.txt", show_col_types = FALSE)
cat("   - Total filas originales:", nrow(df), "\n")
cat("   - Total miRNAs únicos:", length(unique(df$`miRNA name`)), "\n\n")

# 2. Identificar columnas
cat("📊 PASO 2: Identificando tipos de columnas...\n")
meta_cols <- c("miRNA name", "pos:mut")
# Las columnas SNV son las que NO tienen (PM+1MM+2MM) y no son meta
all_cols <- colnames(df)
total_cols <- all_cols[str_detect(all_cols, "\\(PM\\+1MM\\+2MM\\)")]
snv_cols <- setdiff(all_cols, c(meta_cols, total_cols))

cat("   - Columnas meta:", length(meta_cols), "\n")
cat("   - Columnas SNV:", length(snv_cols), "\n")
cat("   - Columnas TOTAL:", length(total_cols), "\n")
cat("   - Nombres SNV:", paste(snv_cols, collapse = ", "), "\n")
cat("   - Nombres TOTAL:", paste(total_cols, collapse = ", "), "\n\n")

# 3. Filtrar solo G>T (formato: posición:GT, ej: 10:GT)
cat("📊 PASO 3: Filtrando solo mutaciones G>T...\n")
df_gt <- df %>% filter(str_detect(`pos:mut`, ":GT"))
cat("   - Filas después de filtrar G>T:", nrow(df_gt), "\n")
cat("   - miRNAs únicos con G>T:", length(unique(df_gt$`miRNA name`)), "\n\n")

# 4. Calcular VAFs
cat("📊 PASO 4: Calculando VAFs...\n")
# Crear matrices para cálculo de VAF
snv_mat <- as.matrix(df_gt[snv_cols])
total_mat <- as.matrix(df_gt[total_cols])

# Calcular VAFs
vaf_mat <- snv_mat / (total_mat + 1e-10)  # Evitar división por cero
colnames(vaf_mat) <- paste0(colnames(vaf_mat), "_VAF")

# Crear dataframe con VAFs
df_vaf <- bind_cols(df_gt[, meta_cols], as.data.frame(vaf_mat))

cat("   - VAFs calculados para", ncol(vaf_mat), "muestras\n")
cat("   - Filas con VAFs:", nrow(df_vaf), "\n\n")

# 5. Filtrar VAF > 50%
cat("📊 PASO 5: Filtrando SNVs con VAF > 50%...\n")
vaf_cols <- colnames(vaf_mat)

# Contar SNVs que serán removidos
high_vaf_count <- 0
for (col in vaf_cols) {
  high_vaf_count <- high_vaf_count + sum(df_vaf[[col]] > 0.5, na.rm = TRUE)
}

cat("   - SNVs con VAF > 50%:", high_vaf_count, "\n")

# Filtrar
df_filtered <- df_vaf
for (col in vaf_cols) {
  df_filtered <- df_filtered %>% filter(!!sym(col) <= 0.5 | is.na(!!sym(col)))
}

cat("   - Filas después de filtrar VAF > 50%:", nrow(df_filtered), "\n")
cat("   - miRNAs únicos después de filtrar VAF:", length(unique(df_filtered$`miRNA name`)), "\n\n")

# 6. Crear matriz de cuentas por miRNA
cat("📊 PASO 6: Creando matriz de cuentas por miRNA...\n")
# Necesitamos las cuentas originales de SNV para los miRNAs filtrados
# Unir df_filtered con df_gt para obtener las cuentas originales de SNV
df_counts_for_matrix <- df_gt %>%
  semi_join(df_filtered, by = c("miRNA name", "pos:mut")) %>%
  select(`miRNA name`, all_of(snv_cols)) %>%
  group_by(`miRNA name`) %>%
  summarise(across(all_of(snv_cols), ~sum(.x, na.rm = TRUE)), .groups = "drop") %>%
  column_to_rownames("miRNA name") %>%
  as.matrix()

cat("   - Matriz de cuentas:", nrow(df_counts_for_matrix), "miRNAs x", ncol(df_counts_for_matrix), "muestras\n")
cat("   - miRNAs con al menos 1 mutación:", sum(rowSums(df_counts_for_matrix, na.rm = TRUE) > 0), "\n\n")

# 7. Crear matriz de VAF promedio por miRNA
cat("📊 PASO 7: Creando matriz de VAF promedio por miRNA...\n")
vaf_matrix <- df_filtered %>%
  select(`miRNA name`, all_of(vaf_cols)) %>%
  group_by(`miRNA name`) %>%
  summarise(across(all_of(vaf_cols), ~mean(.x, na.rm = TRUE)), .groups = "drop") %>%
  column_to_rownames("miRNA name") %>%
  as.matrix()

cat("   - Matriz de VAF:", nrow(vaf_matrix), "miRNAs x", ncol(vaf_matrix), "muestras\n")
cat("   - miRNAs con VAF > 0:", sum(rowSums(vaf_matrix, na.rm = TRUE) > 0), "\n\n")

# 8. Top 10% por cuentas
cat("📊 PASO 8: Identificando top 10% por cuentas...\n")
count_scores <- rowSums(df_counts_for_matrix, na.rm = TRUE)
count_scores <- count_scores[count_scores > 0]  # Solo miRNAs con mutaciones
top_10_percent_count <- max(1, floor(length(count_scores) * 0.10))
top_counts <- head(sort(count_scores, decreasing = TRUE), top_10_percent_count)

cat("   - miRNAs con mutaciones > 0:", length(count_scores), "\n")
cat("   - Top 10% por cuentas:", length(top_counts), "\n")
cat("   - Top 5 por cuentas:", paste(names(head(top_counts, 5)), collapse = ", "), "\n\n")

# 9. Top 10% por VAF
cat("📊 PASO 9: Identificando top 10% por VAF...\n")
vaf_scores <- rowMeans(vaf_matrix, na.rm = TRUE)
vaf_scores <- vaf_scores[vaf_scores > 0]  # Solo miRNAs con VAF > 0
top_10_percent_vaf <- max(1, floor(length(vaf_scores) * 0.10))
top_vaf <- head(sort(vaf_scores, decreasing = TRUE), top_10_percent_vaf)

cat("   - miRNAs con VAF > 0:", length(vaf_scores), "\n")
cat("   - Top 10% por VAF:", length(top_vaf), "\n")
cat("   - Top 5 por VAF:", paste(names(head(top_vaf, 5)), collapse = ", "), "\n\n")

# 10. Resumen final
cat("📊 RESUMEN FINAL:\n")
cat("==================\n")
cat("1. miRNAs originales:", length(unique(df$`miRNA name`)), "\n")
cat("2. miRNAs con G>T:", length(unique(df_gt$`miRNA name`)), "\n")
cat("3. miRNAs después de filtrar VAF > 50%:", length(unique(df_filtered$`miRNA name`)), "\n")
cat("4. miRNAs con mutaciones > 0:", length(count_scores), "\n")
cat("5. miRNAs con VAF > 0:", length(vaf_scores), "\n")
cat("6. Top 10% por cuentas:", length(top_counts), "\n")
cat("7. Top 10% por VAF:", length(top_vaf), "\n\n")

# 11. Pérdidas por paso
cat("📊 PÉRDIDAS POR PASO:\n")
cat("=====================\n")
original_mirnas <- length(unique(df$`miRNA name`))
gt_mirnas <- length(unique(df_gt$`miRNA name`))
filtered_mirnas <- length(unique(df_filtered$`miRNA name`))
count_mirnas <- length(count_scores)
vaf_mirnas <- length(vaf_scores)

cat("1. Original → G>T:", original_mirnas - gt_mirnas, "miRNAs perdidos\n")
cat("2. G>T → VAF filtrado:", gt_mirnas - filtered_mirnas, "miRNAs perdidos\n")
cat("3. VAF filtrado → Con mutaciones:", filtered_mirnas - count_mirnas, "miRNAs perdidos\n")
cat("4. VAF filtrado → Con VAF > 0:", filtered_mirnas - vaf_mirnas, "miRNAs perdidos\n\n")

cat("✅ Diagnóstico completado!\n")
