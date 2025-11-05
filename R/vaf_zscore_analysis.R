library(dplyr)
library(stringr)
library(tidyr)
library(readr)
library(ggplot2)
library(gridExtra)
library(RColorBrewer)
library(pheatmap)
library(ComplexHeatmap)
library(circlize)
library(tibble)

cat("🧬 ANÁLISIS VAF CON Z-SCORE - ALS vs CONTROL\n")
cat(paste(rep("=", 60), collapse=""), "\n")

# 1. CARGAR DATOS PROCESADOS
cat("\n📁 Cargando datos procesados...\n")
df_processed <- read_tsv("outputs/processed_mirna_dataset_simple.tsv")
cat("   📊 Dataset procesado:", nrow(df_processed), "x", ncol(df_processed), "\n")

# 2. DEFINIR COLUMNAS
# Identificar columnas de totales por el sufijo
total_cols <- colnames(df_processed)[str_detect(colnames(df_processed), "\\.\\.PM\\.1MM\\.2MM\\.$")]
snv_cols <- setdiff(colnames(df_processed), c("miRNA.name", "pos.mut", total_cols))

# 3. FUNCIÓN PARA PROCESAR MATRIZ VAF
process_vaf_matrix <- function(df, min_total = 500,
                               pat_ALS = "(ALS[-_]enrolment|ALS[-_]longitudinal)",
                               pat_CTRL = "(?i)control") {
  
  cat("\n🔧 Procesando matriz VAF...\n")
  
  # Limpiar nombres de muestras
  clean_sample <- function(x) str_remove(x, fixed("..PM.1MM.2MM."))
  
  # Procesar datos
  df_proc <- df %>%
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
      vaf = ifelse(total_count >= min_total, snv_count / total_count, 0),
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
  cat("   📊 Matriz antes de filtrar VAF > 0:", nrow(mat_vaf), "x", ncol(mat_vaf), "\n")
  mat_vaf <- mat_vaf[rowMeans(mat_vaf) > 0, , drop = FALSE]
  cat("   📊 Matriz después de filtrar VAF > 0:", nrow(mat_vaf), "x", ncol(mat_vaf), "\n")
  
  if (nrow(mat_vaf) == 0 || ncol(mat_vaf) == 0) {
    cat("   ⚠️ Matriz vacía después de filtrado. Revisando datos...\n")
    cat("   📊 VAF máximo en datos:", max(df_vaf$vaf, na.rm = TRUE), "\n")
    cat("   📊 VAF promedio en datos:", mean(df_vaf$vaf, na.rm = TRUE), "\n")
    cat("   📊 Filas con VAF > 0:", sum(df_vaf$vaf > 0, na.rm = TRUE), "\n")
    stop("❌ Matriz vacía después de filtrado. No hay SNVs o muestras que pasen los umbrales.")
  }
  
  cat("   ✅ Matriz:", nrow(mat_vaf), "SNVs G>T en región semilla,", ncol(mat_vaf), "muestras\n")
  
  # Identificar grupos
  als_samples <- colnames(mat_vaf)[str_detect(colnames(mat_vaf), "ALS")]
  ctrl_samples <- colnames(mat_vaf)[str_detect(colnames(mat_vaf), "control")]
  
  cat("   📊 Muestras ALS:", length(als_samples), "\n")
  cat("   📊 Muestras Control:", length(ctrl_samples), "\n")
  
  list(
    matrix = mat_vaf,
    df_vaf = df_vaf,
    als_samples = als_samples,
    ctrl_samples = ctrl_samples,
    pat_ALS = pat_ALS,
    pat_CTRL = pat_CTRL
  )
}

# 4. FUNCIÓN PARA PLOTEAR HEATMAP VAF
plot_vaf_heatmap <- function(mat_vaf, zscore = TRUE,
                             pat_ALS = "(ALS[-_]enrolment|ALS[-_]longitudinal)",
                             pat_CTRL = "(?i)control") {
  
  cat("\n🎨 Creando heatmap VAF...\n")
  
  if (zscore) {
    # Calcular z-score por fila (SNV)
    mat_scaled <- t(scale(t(mat_vaf)))
    mat_scaled[is.na(mat_scaled)] <- 0
    mat_plot <- mat_scaled
    title_label <- "VAF Z-Score: ALS vs Control"
    color_palette <- colorRampPalette(c("#4575b4", "white", "#d73027"))(100)
  } else {
    mat_plot <- mat_vaf * 100
    title_label <- "VAF Proportion (%)"
    color_palette <- colorRampPalette(c("white", "#fcae91", "red"))(100)
  }
  
  # Crear anotación de grupos
  col_group <- case_when(
    str_detect(colnames(mat_plot), "ALS") ~ "ALS",
    str_detect(colnames(mat_plot), "control") ~ "Control",
    TRUE ~ "Other"
  )
  
  # Crear data frame de anotación
  annotation_df <- data.frame(
    Group = col_group,
    row.names = colnames(mat_plot)
  )
  
  # Colores para anotación
  annotation_colors <- list(
    Group = c("ALS" = "#D62728", "Control" = "grey60", "Other" = "grey90")
  )
  
  # Crear heatmap con pheatmap
  pheatmap(
    mat_plot,
    color = color_palette,
    annotation_col = annotation_df,
    annotation_colors = annotation_colors,
    cluster_rows = TRUE,
    cluster_cols = TRUE,
    show_rownames = FALSE,
    show_colnames = FALSE,
    main = paste0(title_label, ": G>T Mutations in Seed Region"),
    scale = "none"
  )
}

# 5. FUNCIÓN PARA ANÁLISIS ESTADÍSTICO
analyze_vaf_differences <- function(mat_vaf, pat_ALS, pat_CTRL) {
  cat("\n📊 Analizando diferencias VAF entre grupos...\n")
  
  # Identificar grupos
  als_samples <- colnames(mat_vaf)[str_detect(colnames(mat_vaf), "ALS")]
  ctrl_samples <- colnames(mat_vaf)[str_detect(colnames(mat_vaf), "control")]
  
  if (length(als_samples) == 0 || length(ctrl_samples) == 0) {
    cat("   ⚠️ No se encontraron muestras de ambos grupos\n")
    return(NULL)
  }
  
  # Calcular estadísticas por SNV
  results <- data.frame()
  
  for (i in 1:nrow(mat_vaf)) {
    snv_name <- rownames(mat_vaf)[i]
    als_vaf <- mat_vaf[i, als_samples]
    ctrl_vaf <- mat_vaf[i, ctrl_samples]
    
    # Estadísticas descriptivas
    als_mean <- mean(als_vaf, na.rm = TRUE)
    ctrl_mean <- mean(ctrl_vaf, na.rm = TRUE)
    als_median <- median(als_vaf, na.rm = TRUE)
    ctrl_median <- median(ctrl_vaf, na.rm = TRUE)
    
    # Pruebas estadísticas
    if (length(als_vaf) > 1 && length(ctrl_vaf) > 1) {
      # T-test
      t_test <- try(t.test(als_vaf, ctrl_vaf), silent = TRUE)
      t_pvalue <- if (inherits(t_test, "try-error")) NA else t_test$p.value
      t_statistic <- if (inherits(t_test, "try-error")) NA else t_test$statistic
      
      # Wilcoxon test
      wilcox_test <- try(wilcox.test(als_vaf, ctrl_vaf), silent = TRUE)
      wilcox_pvalue <- if (inherits(wilcox_test, "try-error")) NA else wilcox_test$p.value
      
      # Effect size (Cohen's d)
      pooled_sd <- sqrt(((length(als_vaf) - 1) * var(als_vaf, na.rm = TRUE) + 
                        (length(ctrl_vaf) - 1) * var(ctrl_vaf, na.rm = TRUE)) / 
                       (length(als_vaf) + length(ctrl_vaf) - 2))
      cohens_d <- if (pooled_sd > 0) (als_mean - ctrl_mean) / pooled_sd else 0
      
    } else {
      t_pvalue <- NA
      t_statistic <- NA
      wilcox_pvalue <- NA
      cohens_d <- 0
    }
    
    # Fold change
    fold_change <- if (ctrl_mean > 0) als_mean / ctrl_mean else Inf
    
    # Log2 fold change
    log2fc <- if (ctrl_mean > 0 && als_mean > 0) log2(fold_change) else 0
    
    results <- rbind(results, data.frame(
      snv = snv_name,
      als_mean = als_mean,
      ctrl_mean = ctrl_mean,
      als_median = als_median,
      ctrl_median = ctrl_median,
      fold_change = fold_change,
      log2fc = log2fc,
      cohens_d = cohens_d,
      t_statistic = t_statistic,
      t_pvalue = t_pvalue,
      wilcox_pvalue = wilcox_pvalue,
      stringsAsFactors = FALSE
    ))
  }
  
  # Ajustar p-values
  results$t_pvalue_adj <- p.adjust(results$t_pvalue, method = "BH")
  results$wilcox_pvalue_adj <- p.adjust(results$wilcox_pvalue, method = "BH")
  
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
  
  return(results)
}

# 6. EJECUTAR ANÁLISIS
cat("\n🚀 Iniciando análisis VAF con z-score...\n")

# Procesar matriz VAF (reducir umbral mínimo)
vaf_data <- process_vaf_matrix(df_processed, min_total = 10)

# Análisis estadístico
statistical_results <- analyze_vaf_differences(vaf_data$matrix, vaf_data$pat_ALS, vaf_data$pat_CTRL)

# 7. CREAR VISUALIZACIONES
cat("\n🎨 Creando visualizaciones...\n")

# Heatmap con z-score
png("outputs/figures/vaf_zscore_heatmap.png", width = 1200, height = 800)
plot_vaf_heatmap(vaf_data$matrix, zscore = TRUE)
dev.off()
cat("   ✅ Heatmap z-score guardado: outputs/figures/vaf_zscore_heatmap.png\n")

# Heatmap sin z-score
png("outputs/figures/vaf_proportion_heatmap.png", width = 1200, height = 800)
plot_vaf_heatmap(vaf_data$matrix, zscore = FALSE)
dev.off()
cat("   ✅ Heatmap proporción guardado: outputs/figures/vaf_proportion_heatmap.png\n")

# 8. GRÁFICOS DE ANÁLISIS ESTADÍSTICO
if (!is.null(statistical_results)) {
  # Plot 1: Volcano plot
  p1 <- ggplot(statistical_results, aes(x = log2fc, y = -log10(t_pvalue_adj))) +
    geom_point(aes(color = significance), alpha = 0.7) +
    scale_color_manual(values = c("***" = "#E31A1C", "**" = "#FF7F00", "*" = "#1F78B4", "ns" = "#33A02C")) +
    geom_hline(yintercept = -log10(0.05), linetype = "dashed", color = "red") +
    geom_vline(xintercept = c(-1, 1), linetype = "dashed", color = "blue") +
    labs(title = "Volcano Plot: VAF Differences (ALS vs Control)",
         x = "Log2 Fold Change", y = "-Log10 Adjusted P-value",
         color = "Significance") +
    theme_minimal()
  ggsave("outputs/figures/vaf_volcano_plot.png", p1, width = 10, height = 8)
  
  # Plot 2: Top SNVs por significancia
  top_snvs <- head(statistical_results, 20)
  p2 <- ggplot(top_snvs, aes(x = reorder(snv, -t_pvalue_adj), y = -log10(t_pvalue_adj))) +
    geom_bar(stat = "identity", fill = "steelblue", alpha = 0.7) +
    coord_flip() +
    labs(title = "Top 20 SNVs by Statistical Significance",
         x = "SNV", y = "-Log10 Adjusted P-value") +
    theme_minimal()
  ggsave("outputs/figures/vaf_top_significant_snvs.png", p2, width = 12, height = 8)
  
  # Plot 3: Distribución de effect sizes
  p3 <- ggplot(statistical_results, aes(x = cohens_d)) +
    geom_histogram(bins = 30, fill = "darkgreen", alpha = 0.7) +
    geom_vline(xintercept = c(-0.2, 0.2), linetype = "dashed", color = "red") +
    labs(title = "Distribution of Effect Sizes (Cohen's d)",
         x = "Cohen's d", y = "Frequency") +
    theme_minimal()
  ggsave("outputs/figures/vaf_effect_size_distribution.png", p3, width = 10, height = 6)
  
  # Plot 4: Fold change vs significancia
  p4 <- ggplot(statistical_results, aes(x = log2fc, y = cohens_d, color = significance)) +
    geom_point(alpha = 0.7) +
    scale_color_manual(values = c("***" = "#E31A1C", "**" = "#FF7F00", "*" = "#1F78B4", "ns" = "#33A02C")) +
    labs(title = "Effect Size vs Fold Change",
         x = "Log2 Fold Change", y = "Cohen's d", color = "Significance") +
    theme_minimal()
  ggsave("outputs/figures/vaf_effect_vs_foldchange.png", p4, width = 10, height = 6)
}

# 9. GUARDAR RESULTADOS
cat("\n💾 Guardando resultados...\n")

write_tsv(vaf_data$df_vaf, "outputs/vaf_zscore_data.tsv")

if (!is.null(statistical_results)) {
  write_tsv(statistical_results, "outputs/vaf_statistical_results.tsv")
  
  # Top SNVs significativos
  top_significant <- statistical_results %>%
    filter(t_pvalue_adj < 0.05) %>%
    arrange(t_pvalue_adj)
  
  if (nrow(top_significant) > 0) {
    write_tsv(top_significant, "outputs/vaf_top_significant_snvs.tsv")
    cat("   📊 Top SNVs significativos guardados:", nrow(top_significant), "\n")
  }
}

# 10. CREAR REPORTE
cat("\n📋 Creando reporte...\n")

report_content <- c(
  "# ANÁLISIS VAF CON Z-SCORE - ALS vs CONTROL\n\n",
  "## Resumen del Análisis\n",
  paste0("- **SNVs G>T en región semilla**: ", nrow(vaf_data$matrix), "\n"),
  paste0("- **Muestras totales**: ", ncol(vaf_data$matrix), "\n"),
  paste0("- **Muestras ALS**: ", length(vaf_data$als_samples), "\n"),
  paste0("- **Muestras Control**: ", length(vaf_data$ctrl_samples), "\n"),
  if (!is.null(statistical_results)) {
    paste0("- **SNVs significativos (p < 0.05)**: ", sum(statistical_results$t_pvalue_adj < 0.05, na.rm = TRUE), "\n"),
    paste0("- **SNVs altamente significativos (p < 0.001)**: ", sum(statistical_results$t_pvalue_adj < 0.001, na.rm = TRUE), "\n")
  } else {
    "- **Análisis estadístico**: No disponible (grupos insuficientes)\n"
  },
  "\n## Metodología\n",
  "1. **Filtrado**: Solo mutaciones G>T en región semilla (posiciones 2-8)\n",
  "2. **Cálculo VAF**: Variant Allele Frequency por SNV por muestra\n",
  "3. **Z-score**: Normalización por fila (SNV) para comparación entre grupos\n",
  "4. **Análisis estadístico**: T-test, Wilcoxon, Cohen's d\n",
  "5. **Corrección múltiple**: Benjamini-Hochberg (FDR)\n\n",
  
  if (!is.null(statistical_results) && nrow(top_significant) > 0) {
    c(
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
      "\n"
    )
  } else {
    "## SNVs Significativos\n- No se encontraron SNVs significativamente diferentes entre grupos\n\n"
  },
  
  "## Archivos Generados\n",
  "- `outputs/vaf_zscore_data.tsv`: Datos VAF completos\n",
  "- `outputs/vaf_statistical_results.tsv`: Resultados estadísticos\n",
  "- `outputs/vaf_top_significant_snvs.tsv`: Top SNVs significativos\n",
  "- `outputs/figures/vaf_zscore_heatmap.png`: Heatmap con z-score\n",
  "- `outputs/figures/vaf_proportion_heatmap.png`: Heatmap con proporciones\n",
  "- `outputs/figures/vaf_volcano_plot.png`: Volcano plot\n",
  "- `outputs/figures/vaf_*`: Otros gráficos de análisis\n",
  "- `outputs/vaf_zscore_report.md`: Este reporte\n"
)

writeLines(report_content, "outputs/vaf_zscore_report.md")

cat("\n🎉 Análisis VAF con z-score completado!\n")
cat("   📊 Archivos generados:\n")
cat("   - outputs/vaf_zscore_data.tsv\n")
cat("   - outputs/vaf_statistical_results.tsv\n")
cat("   - outputs/vaf_zscore_report.md\n")
cat("   - outputs/figures/vaf_*\n")
