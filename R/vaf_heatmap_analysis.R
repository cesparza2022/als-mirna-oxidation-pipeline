#!/usr/bin/env Rscript

# ANÁLISIS DE HEATMAP CON VAFs Y CLUSTERING JERÁRQUICO
# Crear matriz de VAFs para miRNAs del top 10% con clustering jerárquico

library(dplyr)
library(stringr)
library(readr)
library(tibble)
library(tidyr)  # Para pivot_wider y pivot_longer
library(pheatmap)
library(RColorBrewer)
library(viridis)

cat("🔥 ANÁLISIS DE HEATMAP CON VAFs Y CLUSTERING JERÁRQUICO\n")
cat("=====================================================\n\n")

# 1. Cargar datos
cat("📊 PASO 1: Cargando datos...\n")
df <- read_tsv("results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt", show_col_types = FALSE)
cat("   - Total filas:", nrow(df), "\n")
cat("   - Total miRNAs únicos:", length(unique(df$`miRNA name`)), "\n\n")

# 2. Identificar columnas
cat("📊 PASO 2: Identificando tipos de columnas...\n")
meta_cols <- c("miRNA name", "pos:mut")
all_cols <- colnames(df)
total_cols <- all_cols[str_detect(all_cols, "\\(PM\\+1MM\\+2MM\\)")]
snv_cols <- setdiff(all_cols, c(meta_cols, total_cols))

cat("   - Columnas SNV:", length(snv_cols), "\n")
cat("   - Columnas TOTAL:", length(total_cols), "\n")
cat("   - Nombres SNV:", paste(snv_cols, collapse = ", "), "\n\n")

# 3. Filtrar solo mutaciones G>T
cat("📊 PASO 3: Filtrando solo mutaciones G>T...\n")
df_gt <- df %>% filter(str_detect(`pos:mut`, ":GT"))
cat("   - Filas con G>T:", nrow(df_gt), "\n")
cat("   - miRNAs únicos con G>T:", length(unique(df_gt$`miRNA name`)), "\n\n")

# 4. Calcular VAFs
cat("📊 PASO 4: Calculando VAFs...\n")
snv_mat <- as.matrix(df_gt[, snv_cols])
total_mat <- as.matrix(df_gt[, total_cols])

# Calcular VAFs: SNV counts / Total counts
vaf_mat <- snv_mat / (total_mat + 1e-10)  # Evitar división por cero
colnames(vaf_mat) <- paste0(colnames(vaf_mat), "_VAF")

# Crear dataframe con VAFs
df_vaf <- bind_cols(df_gt[, meta_cols], as.data.frame(vaf_mat))
cat("   - VAFs calculados para", ncol(vaf_mat), "muestras\n")
cat("   - Filas con VAFs:", nrow(df_vaf), "\n\n")

# 5. Filtrar SNVs con VAF > 50%
cat("📊 PASO 5: Filtrando SNVs con VAF > 50%...\n")
vaf_cols <- colnames(vaf_mat)

# Identificar SNVs donde CUALQUIER VAF sea > 0.5
snvs_to_remove_idx <- apply(df_vaf[, vaf_cols] > 0.5, 1, any, na.rm = TRUE)
df_filtered_vaf <- df_vaf[!snvs_to_remove_idx, ]

cat("   - SNVs con VAF > 50% (removidos):", sum(snvs_to_remove_idx), "\n")
cat("   - Filas después de filtrar VAF > 50%:", nrow(df_filtered_vaf), "\n")
cat("   - miRNAs únicos después de filtrar VAF:", length(unique(df_filtered_vaf$`miRNA name`)), "\n\n")

# 6. Crear matriz de cuentas por miRNA (para top 10% por cuentas)
cat("📊 PASO 6: Creando matriz de cuentas por miRNA...\n")
df_counts_for_top <- df_gt %>%
  semi_join(df_filtered_vaf, by = c("miRNA name", "pos:mut")) %>%
  select(all_of(meta_cols), all_of(snv_cols)) %>%
  pivot_longer(
    cols = all_of(snv_cols),
    names_to = "sample",
    values_to = "count"
  ) %>%
  group_by(`miRNA name`, sample) %>%
  summarise(total_gt_counts = sum(count, na.rm = TRUE), .groups = 'drop') %>%
  pivot_wider(
    names_from = sample,
    values_from = total_gt_counts,
    values_fill = 0
  ) %>%
  column_to_rownames("miRNA name")

cat("   - Dimensiones de la matriz de cuentas (miRNA x muestra):", dim(df_counts_for_top), "\n")
cat("   - miRNAs en la matriz de cuentas:", nrow(df_counts_for_top), "\n\n")

# 7. Crear matriz de VAF promedio por miRNA (para top 10% por VAF)
cat("📊 PASO 7: Creando matriz de VAF promedio por miRNA...\n")
df_vaf_for_top <- df_filtered_vaf %>%
  select(all_of(meta_cols), all_of(vaf_cols)) %>%
  pivot_longer(
    cols = all_of(vaf_cols),
    names_to = "sample_vaf",
    values_to = "vaf"
  ) %>%
  mutate(sample = str_replace(sample_vaf, "_VAF", "")) %>%
  group_by(`miRNA name`, sample) %>%
  summarise(avg_gt_vaf = mean(vaf, na.rm = TRUE), .groups = 'drop') %>%
  pivot_wider(
    names_from = sample,
    values_from = avg_gt_vaf,
    values_fill = 0
  ) %>%
  column_to_rownames("miRNA name")

cat("   - Dimensiones de la matriz de VAFs (miRNA x muestra):", dim(df_vaf_for_top), "\n")
cat("   - miRNAs en la matriz de VAFs:", nrow(df_vaf_for_top), "\n\n")

# 8. Identificar top 10% por cuentas
cat("📊 PASO 8: Identificando top 10% por cuentas...\n")
count_scores <- rowSums(df_counts_for_top, na.rm = TRUE)
count_scores <- count_scores[count_scores > 0]
top_10_percent_count <- max(1, floor(length(count_scores) * 0.10))
top_counts <- head(sort(count_scores, decreasing = TRUE), top_10_percent_count)
top_mirnas_by_counts <- names(top_counts)

cat("   - miRNAs con mutaciones > 0:", length(count_scores), "\n")
cat("   - Top 10% por cuentas:", length(top_mirnas_by_counts), "\n")
cat("   - Top 5 por cuentas:", paste(head(top_mirnas_by_counts, 5), collapse = ", "), "\n\n")

# 9. Identificar top 10% por VAF
cat("📊 PASO 9: Identificando top 10% por VAF...\n")
vaf_scores <- rowMeans(df_vaf_for_top, na.rm = TRUE)
vaf_scores <- vaf_scores[vaf_scores > 0]
top_10_percent_vaf <- max(1, floor(length(vaf_scores) * 0.10))
top_vaf <- head(sort(vaf_scores, decreasing = TRUE), top_10_percent_vaf)
top_mirnas_by_vaf <- names(top_vaf)

cat("   - miRNAs con VAF > 0:", length(vaf_scores), "\n")
cat("   - Top 10% por VAF:", length(top_mirnas_by_vaf), "\n")
cat("   - Top 5 por VAF:", paste(head(top_mirnas_by_vaf, 5), collapse = ", "), "\n\n")

# 10. Crear matriz de VAFs para heatmap (SNVs de miRNAs seleccionados)
cat("📊 PASO 10: Creando matriz de VAFs para heatmap...\n")

# Función para crear matriz de VAFs para un conjunto de miRNAs
create_vaf_matrix_for_mirnas <- function(mirna_list, method_name) {
  cat("   - Creando matriz para", method_name, "con", length(mirna_list), "miRNAs...\n")
  
  # Filtrar SNVs de los miRNAs seleccionados
  df_selected <- df_filtered_vaf %>%
    filter(`miRNA name` %in% mirna_list)
  
  cat("     - SNVs encontrados:", nrow(df_selected), "\n")
  
  if (nrow(df_selected) == 0) {
    cat("     - ADVERTENCIA: No se encontraron SNVs para estos miRNAs\n")
    return(NULL)
  }
  
  # Crear matriz de VAFs: SNVs x Muestras
  vaf_matrix <- df_selected %>%
    select(`miRNA name`, `pos:mut`, all_of(vaf_cols)) %>%
    mutate(
      snv_id = paste(`miRNA name`, `pos:mut`, sep = "_"),
      .before = 1
    ) %>%
    select(snv_id, all_of(vaf_cols)) %>%
    column_to_rownames("snv_id") %>%
    as.matrix()
  
  # Limpiar nombres de columnas (quitar _VAF)
  colnames(vaf_matrix) <- str_replace(colnames(vaf_matrix), "_VAF", "")
  
  cat("     - Dimensiones de la matriz VAF:", dim(vaf_matrix), "\n")
  cat("     - SNVs únicos:", nrow(vaf_matrix), "\n")
  cat("     - Muestras:", ncol(vaf_matrix), "\n")
  
  return(vaf_matrix)
}

# Crear matrices para ambos métodos
vaf_matrix_counts <- create_vaf_matrix_for_mirnas(top_mirnas_by_counts, "Top 10% por cuentas")
vaf_matrix_vaf <- create_vaf_matrix_for_mirnas(top_mirnas_by_vaf, "Top 10% por VAF")

# 11. Crear heatmaps con clustering jerárquico
cat("📊 PASO 11: Creando heatmaps con clustering jerárquico...\n")

# Función para crear heatmap
create_heatmap <- function(vaf_matrix, title, filename) {
  if (is.null(vaf_matrix) || nrow(vaf_matrix) == 0) {
    cat("   - No se puede crear heatmap para", title, "(matriz vacía)\n")
    return(NULL)
  }
  
  cat("   - Creando heatmap para", title, "...\n")
  
  # Configurar colores
  colors <- viridis(100, option = "plasma")
  
  # Crear heatmap con clustering jerárquico
  png(filename, width = 1200, height = 800, res = 150)
  
  pheatmap(
    vaf_matrix,
    color = colors,
    cluster_rows = TRUE,    # Clustering jerárquico en SNVs
    cluster_cols = TRUE,    # Clustering jerárquico en muestras
    clustering_distance_rows = "euclidean",
    clustering_distance_cols = "euclidean",
    clustering_method = "ward.D2",
    show_rownames = TRUE,
    show_colnames = TRUE,
    fontsize = 8,
    fontsize_row = 6,
    fontsize_col = 10,
    main = title,
    border_color = NA,
    na_col = "grey90"
  )
  
  dev.off()
  
  cat("     - Heatmap guardado en:", filename, "\n")
}

# Crear directorio de salida
dir.create("outputs/figures/vaf_heatmaps", recursive = TRUE, showWarnings = FALSE)

# Crear heatmaps
create_heatmap(
  vaf_matrix_counts, 
  "Heatmap VAFs - Top 10% miRNAs por Cuentas G>T", 
  "outputs/figures/vaf_heatmaps/heatmap_vaf_top_counts.png"
)

create_heatmap(
  vaf_matrix_vaf, 
  "Heatmap VAFs - Top 10% miRNAs por VAF Promedio", 
  "outputs/figures/vaf_heatmaps/heatmap_vaf_top_vaf.png"
)

# 12. Análisis de solapamiento
cat("📊 PASO 12: Análisis de solapamiento...\n")
shared_mirnas <- intersect(top_mirnas_by_counts, top_mirnas_by_vaf)
counts_only <- setdiff(top_mirnas_by_counts, top_mirnas_by_vaf)
vaf_only <- setdiff(top_mirnas_by_vaf, top_mirnas_by_counts)

cat("   - miRNAs compartidos:", length(shared_mirnas), "\n")
cat("   - Solo en top cuentas:", length(counts_only), "\n")
cat("   - Solo en top VAF:", length(vaf_only), "\n")

if (length(shared_mirnas) > 0) {
  cat("   - miRNAs compartidos:", paste(head(shared_mirnas, 5), collapse = ", "), "\n")
}

# 13. Crear matriz combinada si hay solapamiento
if (length(shared_mirnas) > 0) {
  cat("📊 PASO 13: Creando heatmap para miRNAs compartidos...\n")
  vaf_matrix_shared <- create_vaf_matrix_for_mirnas(shared_mirnas, "miRNAs compartidos")
  
  create_heatmap(
    vaf_matrix_shared, 
    "Heatmap VAFs - miRNAs Compartidos (Top 10% por ambos métodos)", 
    "outputs/figures/vaf_heatmaps/heatmap_vaf_shared.png"
  )
}

# 14. Guardar resultados
cat("📊 PASO 14: Guardando resultados...\n")

results <- list(
  top_mirnas_by_counts = top_mirnas_by_counts,
  top_mirnas_by_vaf = top_mirnas_by_vaf,
  shared_mirnas = shared_mirnas,
  counts_only = counts_only,
  vaf_only = vaf_only,
  vaf_matrix_counts = vaf_matrix_counts,
  vaf_matrix_vaf = vaf_matrix_vaf,
  vaf_matrix_shared = if (length(shared_mirnas) > 0) vaf_matrix_shared else NULL
)

saveRDS(results, "outputs/vaf_heatmap_results.rds")

# 15. Crear reporte
cat("📊 PASO 15: Creando reporte...\n")

report <- paste0(
  "# REPORTE DE ANÁLISIS DE HEATMAP CON VAFs\n\n",
  "## Resumen del Análisis\n",
  "- **miRNAs originales**: ", length(unique(df$`miRNA name`)), "\n",
  "- **miRNAs con G>T**: ", length(unique(df_gt$`miRNA name`)), "\n",
  "- **miRNAs después de filtrar VAF > 50%**: ", length(unique(df_filtered_vaf$`miRNA name`)), "\n",
  "- **Top 10% por cuentas**: ", length(top_mirnas_by_counts), " miRNAs\n",
  "- **Top 10% por VAF**: ", length(top_mirnas_by_vaf), " miRNAs\n",
  "- **miRNAs compartidos**: ", length(shared_mirnas), "\n\n",
  "## Top 5 miRNAs por Cuentas\n",
  paste(paste0(1:5, ". ", head(top_mirnas_by_counts, 5)), collapse = "\n"), "\n\n",
  "## Top 5 miRNAs por VAF\n",
  paste(paste0(1:5, ". ", head(top_mirnas_by_vaf, 5)), collapse = "\n"), "\n\n",
  "## Archivos Generados\n",
  "- `outputs/figures/vaf_heatmaps/heatmap_vaf_top_counts.png`\n",
  "- `outputs/figures/vaf_heatmaps/heatmap_vaf_top_vaf.png`\n",
  if (length(shared_mirnas) > 0) "- `outputs/figures/vaf_heatmaps/heatmap_vaf_shared.png`\n" else "",
  "- `outputs/vaf_heatmap_results.rds`\n"
)

writeLines(report, "outputs/vaf_heatmap_report.md")

cat("✅ ANÁLISIS COMPLETADO!\n")
cat("=======================\n")
cat("📁 Archivos generados en outputs/figures/vaf_heatmaps/\n")
cat("📊 Reporte guardado en outputs/vaf_heatmap_report.md\n")
cat("💾 Resultados guardados en outputs/vaf_heatmap_results.rds\n")
