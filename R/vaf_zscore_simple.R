library(dplyr)
library(stringr)
library(tidyr)
library(readr)
library(ggplot2)
library(tibble)

cat("🧬 ANÁLISIS VAF CON Z-SCORE - VERSIÓN SIMPLE\n")
cat(paste(rep("=", 60), collapse=""), "\n")

# 1. CARGAR DATOS PROCESADOS
cat("\n📁 Cargando datos procesados...\n")
df_processed <- read_tsv("outputs/processed_mirna_dataset_simple.tsv")
cat("   📊 Dataset procesado:", nrow(df_processed), "x", ncol(df_processed), "\n")

# 2. DEFINIR COLUMNAS
total_cols <- colnames(df_processed)[str_detect(colnames(df_processed), "\\.\\.PM\\.1MM\\.2MM\\.$")]
snv_cols <- setdiff(colnames(df_processed), c("miRNA.name", "pos.mut", total_cols))

# 3. PROCESAR MATRIZ VAF
cat("\n🔧 Procesando matriz VAF...\n")

# Limpiar nombres de muestras
clean_sample <- function(x) str_remove(x, fixed("..PM.1MM.2MM."))

# Procesar datos
df_proc <- df_processed %>%
  rename(miRNA_name = miRNA.name) %>%
  mutate(
    pos = as.numeric(str_extract(pos.mut, "^[0-9]+")),
    clean_mut = str_replace(pos.mut, ":", "_"),
    featureID = paste(miRNA_name, clean_mut, sep = "_")
  ) %>% 
  filter(pos >= 2 & pos <= 8)  # Región semilla completa

cat("   📊 Filas después de filtrar región semilla:", nrow(df_proc), "\n")

# Convertir a formato largo para SNVs
snv_long <- df_proc %>%
  select(featureID, miRNA_name, all_of(snv_cols)) %>%
  pivot_longer(cols = -c(featureID, miRNA_name), names_to = "sample", values_to = "snv_count") %>%
  mutate(sample_clean = clean_sample(sample))

# Convertir a formato largo para totales
tot_long <- df_proc %>%
  select(featureID, miRNA_name, all_of(total_cols)) %>%
  pivot_longer(cols = -c(featureID, miRNA_name), names_to = "sample", values_to = "total_count") %>%
  mutate(sample_clean = clean_sample(sample))

# Unir datos y calcular VAF
df_vaf <- left_join(
  snv_long, tot_long,
  by = c("featureID", "miRNA_name", "sample_clean")
) %>%
  mutate(
    total_count = replace_na(total_count, 0),
    snv_count = replace_na(snv_count, 0),
    vaf = ifelse(total_count >= 10, snv_count / total_count, 0),
    vaf = pmin(vaf, 1),
    vaf = replace_na(vaf, 0)
  )

cat("   📊 Filas en df_vaf:", nrow(df_vaf), "\n")

# Crear matriz VAF
mat_vaf <- df_vaf %>%
  select(featureID, sample_clean, vaf) %>%
  pivot_wider(names_from = sample_clean, values_from = vaf, values_fill = 0) %>%
  as.data.frame() %>%
  column_to_rownames("featureID") %>%
  as.matrix()

# Filtrar filas con VAF > 0
mat_vaf <- mat_vaf[rowMeans(mat_vaf) > 0, , drop = FALSE]

cat("   ✅ Matriz:", nrow(mat_vaf), "SNVs G>T en región semilla,", ncol(mat_vaf), "muestras\n")

# Identificar grupos
als_samples <- colnames(mat_vaf)[str_detect(colnames(mat_vaf), "ALS")]
ctrl_samples <- colnames(mat_vaf)[str_detect(colnames(mat_vaf), "control")]

cat("   📊 Muestras ALS:", length(als_samples), "\n")
cat("   📊 Muestras Control:", length(ctrl_samples), "\n")

# 4. ANÁLISIS ESTADÍSTICO
cat("\n📊 Analizando diferencias VAF entre grupos...\n")

results <- data.frame()

for (i in 1:nrow(mat_vaf)) {
  snv_name <- rownames(mat_vaf)[i]
  als_vaf <- mat_vaf[i, als_samples]
  ctrl_vaf <- mat_vaf[i, ctrl_samples]
  
  # Estadísticas descriptivas
  als_mean <- mean(als_vaf, na.rm = TRUE)
  ctrl_mean <- mean(ctrl_vaf, na.rm = TRUE)
  
  # Pruebas estadísticas
  if (length(als_vaf) > 1 && length(ctrl_vaf) > 1) {
    # T-test
    t_test <- try(t.test(als_vaf, ctrl_vaf), silent = TRUE)
    t_pvalue <- if (inherits(t_test, "try-error")) NA else t_test$p.value
    
    # Effect size (Cohen's d)
    pooled_sd <- sqrt(((length(als_vaf) - 1) * var(als_vaf, na.rm = TRUE) + 
                      (length(ctrl_vaf) - 1) * var(ctrl_vaf, na.rm = TRUE)) / 
                     (length(als_vaf) + length(ctrl_vaf) - 2))
    cohens_d <- if (pooled_sd > 0) (als_mean - ctrl_mean) / pooled_sd else 0
    
  } else {
    t_pvalue <- NA
    cohens_d <- 0
  }
  
  # Fold change
  fold_change <- if (ctrl_mean > 0) als_mean / ctrl_mean else Inf
  log2fc <- if (ctrl_mean > 0 && als_mean > 0) log2(fold_change) else 0
  
  results <- rbind(results, data.frame(
    snv = snv_name,
    als_mean = als_mean,
    ctrl_mean = ctrl_mean,
    fold_change = fold_change,
    log2fc = log2fc,
    cohens_d = cohens_d,
    t_pvalue = t_pvalue,
    stringsAsFactors = FALSE
  ))
}

# Ajustar p-values
results$t_pvalue_adj <- p.adjust(results$t_pvalue, method = "BH")

# Clasificar significancia
results$significance <- case_when(
  results$t_pvalue_adj < 0.001 ~ "***",
  results$t_pvalue_adj < 0.01 ~ "**",
  results$t_pvalue_adj < 0.05 ~ "*",
  TRUE ~ "ns"
)

# Ordenar por p-value
results <- results[order(results$t_pvalue_adj, na.last = TRUE), ]

cat("   📊 SNVs analizados:", nrow(results), "\n")
cat("   📊 SNVs significativos (p < 0.05):", sum(results$t_pvalue_adj < 0.05, na.rm = TRUE), "\n")
cat("   📊 SNVs altamente significativos (p < 0.001):", sum(results$t_pvalue_adj < 0.001, na.rm = TRUE), "\n")

# 5. TOP SNVs SIGNIFICATIVOS
top_significant <- results %>%
  filter(t_pvalue_adj < 0.05) %>%
  arrange(t_pvalue_adj) %>%
  head(20)

cat("\n🔝 Top 20 SNVs más significativos:\n")
for (i in 1:nrow(top_significant)) {
  snv_data <- top_significant[i, ]
  cat(sprintf("   %d. %s: Log2FC %.3f, Cohen's d %.3f, p-adj %.2e %s\n", 
              i, snv_data$snv, snv_data$log2fc, snv_data$cohens_d, 
              snv_data$t_pvalue_adj, snv_data$significance))
}

# 6. ANÁLISIS POR POSICIÓN
cat("\n📍 Análisis por posición en región semilla:\n")
position_analysis <- results %>%
  mutate(position = as.numeric(str_extract(snv, "\\d+"))) %>%
  group_by(position) %>%
  summarise(
    total_snvs = n(),
    significant_snvs = sum(t_pvalue_adj < 0.05, na.rm = TRUE),
    mean_log2fc = mean(log2fc, na.rm = TRUE),
    mean_cohens_d = mean(cohens_d, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(position)

for (i in 1:nrow(position_analysis)) {
  pos_data <- position_analysis[i, ]
  cat(sprintf("   Posición %d: %d SNVs total, %d significativos, Log2FC %.3f, Cohen's d %.3f\n",
              pos_data$position, pos_data$total_snvs, pos_data$significant_snvs,
              pos_data$mean_log2fc, pos_data$mean_cohens_d))
}

# 7. GUARDAR RESULTADOS
cat("\n💾 Guardando resultados...\n")

write_tsv(results, "outputs/vaf_zscore_simple_results.tsv")
write_tsv(top_significant, "outputs/vaf_zscore_top_significant.tsv")
write_tsv(position_analysis, "outputs/vaf_zscore_position_analysis.tsv")

# 8. CREAR REPORTE
cat("\n📋 Creando reporte...\n")

report_content <- c(
  "# ANÁLISIS VAF CON Z-SCORE - ALS vs CONTROL\n\n",
  "## Resumen del Análisis\n",
  paste0("- **SNVs G>T en región semilla**: ", nrow(mat_vaf), "\n"),
  paste0("- **Muestras totales**: ", ncol(mat_vaf), "\n"),
  paste0("- **Muestras ALS**: ", length(als_samples), "\n"),
  paste0("- **Muestras Control**: ", length(ctrl_samples), "\n"),
  paste0("- **SNVs significativos (p < 0.05)**: ", sum(results$t_pvalue_adj < 0.05, na.rm = TRUE), "\n"),
  paste0("- **SNVs altamente significativos (p < 0.001)**: ", sum(results$t_pvalue_adj < 0.001, na.rm = TRUE), "\n\n"),
  
  "## Metodología\n",
  "1. **Filtrado**: Solo mutaciones G>T en región semilla (posiciones 2-8)\n",
  "2. **Cálculo VAF**: Variant Allele Frequency por SNV por muestra\n",
  "3. **Análisis estadístico**: T-test, Cohen's d, corrección FDR\n",
  "4. **Análisis por posición**: Agrupación por posición en región semilla\n\n",
  
  "## Top SNVs Significativos\n",
  paste(
    sapply(1:min(10, nrow(top_significant)), function(i) {
      snv_data <- top_significant[i, ]
      paste0("- **", snv_data$snv, "**: Log2FC ", round(snv_data$log2fc, 3), 
             ", Cohen's d ", round(snv_data$cohens_d, 3), 
             ", p-adj ", formatC(snv_data$t_pvalue_adj, format = "e", digits = 2), "\n")
    }),
    collapse = ""
  ),
  "\n## Análisis por Posición\n",
  paste(
    sapply(1:nrow(position_analysis), function(i) {
      pos_data <- position_analysis[i, ]
      paste0("- **Posición ", pos_data$position, "**: ", pos_data$total_snvs, " SNVs total, ", 
             pos_data$significant_snvs, " significativos, Log2FC ", round(pos_data$mean_log2fc, 3), "\n")
    }),
    collapse = ""
  ),
  "\n## Archivos Generados\n",
  "- `outputs/vaf_zscore_simple_results.tsv`: Resultados completos\n",
  "- `outputs/vaf_zscore_top_significant.tsv`: Top SNVs significativos\n",
  "- `outputs/vaf_zscore_position_analysis.tsv`: Análisis por posición\n",
  "- `outputs/vaf_zscore_simple_report.md`: Este reporte\n"
)

writeLines(report_content, "outputs/vaf_zscore_simple_report.md")

cat("\n🎉 Análisis VAF con z-score completado!\n")
cat("   📊 Archivos generados:\n")
cat("   - outputs/vaf_zscore_simple_results.tsv\n")
cat("   - outputs/vaf_zscore_top_significant.tsv\n")
cat("   - outputs/vaf_zscore_position_analysis.tsv\n")
cat("   - outputs/vaf_zscore_simple_report.md\n")











