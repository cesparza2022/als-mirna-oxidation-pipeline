# --- LIBRERÍAS ---
library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(corrplot)
library(reshape2)

# --- CONFIGURACIÓN ---
cat("🔬 ANÁLISIS DE CONFOUNDERS\n")
cat("==========================\n\n")

# --- 1. CARGANDO DATOS PROCESADOS ---
cat("📊 1. CARGANDO DATOS PROCESADOS\n")
cat("===============================\n")

processed_data_path <- "final_analysis/processed_data/processed_snvs_gt.csv"
df_processed <- read.csv(processed_data_path, stringsAsFactors = FALSE)

# Cargar metadatos de muestras
sample_metadata <- read.csv("final_analysis/tables/sample_metadata.csv", stringsAsFactors = FALSE)

# Cargar métricas globales
global_metrics <- read.csv("final_analysis/tables/global_metrics.csv", stringsAsFactors = FALSE)

cat(paste0("   - SNVs procesados: ", nrow(df_processed), "\n"))
cat(paste0("   - miRNAs únicos: ", length(unique(df_processed$miRNA.name)), "\n"))
cat(paste0("   - Muestras: ", nrow(sample_metadata), "\n\n"))

# --- 2. USANDO METADATOS EXISTENTES ---
cat("🔍 2. USANDO METADATOS EXISTENTES\n")
cat("=================================\n")

# Los metadatos ya están disponibles en sample_metadata
detailed_metadata <- sample_metadata %>%
  mutate(
    sample_name = sample,
    sample_id = str_extract(sample, "SRR[0-9]+"),
    tissue = case_when(
      str_detect(sample, "bloodplasma") ~ "Blood Plasma",
      str_detect(sample, "blood") ~ "Blood",
      str_detect(sample, "plasma") ~ "Plasma",
      TRUE ~ "Unknown"
    )
  )

cat("   - Metadatos disponibles:\n")
cat(paste0("     - Cohortes: ", paste(unique(detailed_metadata$cohort), collapse = ", "), "\n"))
cat(paste0("     - Timepoints: ", paste(unique(detailed_metadata$timepoint), collapse = ", "), "\n"))
cat(paste0("     - Batches: ", length(unique(detailed_metadata$batch)), "\n"))
cat(paste0("     - Tejidos: ", paste(unique(detailed_metadata$tissue), collapse = ", "), "\n\n"))

# --- 3. ANÁLISIS DE DISTRIBUCIÓN POR BATCH ---
cat("📈 3. ANÁLISIS DE DISTRIBUCIÓN POR BATCH\n")
cat("========================================\n")

# Usar directamente global_metrics que ya tiene los metadatos
batch_analysis <- global_metrics %>%
  filter(!is.na(cohort))

# Análisis por batch
batch_summary <- batch_analysis %>%
  group_by(batch, cohort) %>%
  summarise(
    n_samples = n(),
    mean_vaf = mean(mean_vaf, na.rm = TRUE),
    mean_snvs_detected = mean(snvs_detected, na.rm = TRUE),
    mean_high_vaf_snvs = mean(high_vaf_snvs, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  arrange(batch, cohort)

cat("   - Resumen por batch y cohorte:\n")
print(batch_summary)
cat("\n")

# --- 4. TESTS ESTADÍSTICOS POR BATCH ---
cat("📊 4. TESTS ESTADÍSTICOS POR BATCH\n")
cat("==================================\n")

# Test ANOVA para VAF medio por batch
anova_vaf_batch <- aov(mean_vaf ~ batch, data = batch_analysis)
anova_summary_vaf <- summary(anova_vaf_batch)
cat("   - ANOVA para VAF medio por batch:\n")
cat(paste0("     - F = ", round(anova_summary_vaf[[1]]$F[1], 3), "\n"))
cat(paste0("     - p-value = ", round(anova_summary_vaf[[1]]$`Pr(>F)`[1], 5), "\n"))
cat(paste0("     - Significativo: ", ifelse(anova_summary_vaf[[1]]$`Pr(>F)`[1] < 0.05, "SÍ", "NO"), "\n\n"))

# Test ANOVA para SNVs detectados por batch
anova_snvs_batch <- aov(snvs_detected ~ batch, data = batch_analysis)
anova_summary_snvs <- summary(anova_snvs_batch)
cat("   - ANOVA para SNVs detectados por batch:\n")
cat(paste0("     - F = ", round(anova_summary_snvs[[1]]$F[1], 3), "\n"))
cat(paste0("     - p-value = ", round(anova_summary_snvs[[1]]$`Pr(>F)`[1], 5), "\n"))
cat(paste0("     - Significativo: ", ifelse(anova_summary_snvs[[1]]$`Pr(>F)`[1] < 0.05, "SÍ", "NO"), "\n\n"))

# --- 5. ANÁLISIS DE CORRELACIÓN ENTRE VARIABLES ---
cat("🔗 5. ANÁLISIS DE CORRELACIÓN ENTRE VARIABLES\n")
cat("=============================================\n")

# Crear matriz de correlación
correlation_vars <- batch_analysis %>%
  select(mean_vaf, snvs_detected, high_vaf_snvs) %>%
  cor(use = "complete.obs")

cat("   - Matriz de correlación:\n")
print(round(correlation_vars, 3))
cat("\n")

# --- 6. ANÁLISIS DE INTERACCIÓN COHORTE x BATCH ---
cat("🔄 6. ANÁLISIS DE INTERACCIÓN COHORTE x BATCH\n")
cat("=============================================\n")

# Test de interacción
interaction_test <- aov(mean_vaf ~ cohort * batch, data = batch_analysis)
interaction_summary <- summary(interaction_test)
cat("   - Test de interacción cohorte x batch:\n")
cat(paste0("     - F = ", round(interaction_summary[[1]]$F[2], 3), "\n"))
cat(paste0("     - p-value = ", round(interaction_summary[[1]]$`Pr(>F)`[2], 5), "\n"))
cat(paste0("     - Significativo: ", ifelse(interaction_summary[[1]]$`Pr(>F)`[2] < 0.05, "SÍ", "NO"), "\n\n"))

# --- 7. ANÁLISIS DE OUTLIERS POR BATCH ---
cat("🎯 7. ANÁLISIS DE OUTLIERS POR BATCH\n")
cat("====================================\n")

# Identificar outliers por batch
outlier_analysis <- batch_analysis %>%
  group_by(batch) %>%
  mutate(
    vaf_outlier = abs(mean_vaf - mean(mean_vaf, na.rm = TRUE)) > 2 * sd(mean_vaf, na.rm = TRUE),
    snvs_outlier = abs(snvs_detected - mean(snvs_detected, na.rm = TRUE)) > 2 * sd(snvs_detected, na.rm = TRUE)
  ) %>%
  ungroup()

outliers_summary <- outlier_analysis %>%
  group_by(batch) %>%
  summarise(
    vaf_outliers = sum(vaf_outlier, na.rm = TRUE),
    snvs_outliers = sum(snvs_outlier, na.rm = TRUE),
    .groups = 'drop'
  )

cat("   - Outliers por batch:\n")
print(outliers_summary)
cat("\n")

# --- 8. CREANDO VISUALIZACIONES ---
cat("📊 8. CREANDO VISUALIZACIONES\n")
cat("=============================\n")

figures_dir <- "final_analysis/figures"
if (!dir.exists(figures_dir)) {
  dir.create(figures_dir, recursive = TRUE)
}

# Boxplot de VAF por batch y cohorte
p_vaf_batch <- ggplot(batch_analysis, aes(x = batch, y = mean_vaf, fill = cohort)) +
  geom_boxplot() +
  labs(title = "VAF Medio por Batch y Cohorte", x = "Batch", y = "VAF Medio") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
ggsave(file.path(figures_dir, "vaf_by_batch_cohort.png"), p_vaf_batch)

# Boxplot de SNVs detectados por batch y cohorte
p_snvs_batch <- ggplot(batch_analysis, aes(x = batch, y = snvs_detected, fill = cohort)) +
  geom_boxplot() +
  labs(title = "SNVs Detectados por Batch y Cohorte", x = "Batch", y = "SNVs Detectados") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
ggsave(file.path(figures_dir, "snvs_by_batch_cohort.png"), p_snvs_batch)

# Heatmap de correlación
p_correlation <- corrplot(correlation_vars, method = "color", type = "upper", 
                         order = "hclust", tl.cex = 0.8, tl.col = "black")
ggsave(file.path(figures_dir, "correlation_heatmap.png"), p_correlation)

# Scatter plot de VAF vs SNVs detectados
p_scatter <- ggplot(batch_analysis, aes(x = snvs_detected, y = mean_vaf, color = cohort)) +
  geom_point(alpha = 0.7) +
  geom_smooth(method = "lm", se = TRUE) +
  labs(title = "VAF vs SNVs Detectados", x = "SNVs Detectados", y = "VAF Medio") +
  theme_minimal()
ggsave(file.path(figures_dir, "vaf_vs_snvs_scatter.png"), p_scatter)

cat(paste0("   - Figuras guardadas en: ", figures_dir, "\n\n"))

# --- 9. GUARDAR RESULTADOS ---
cat("💾 9. GUARDAR RESULTADOS\n")
cat("========================\n")

tables_dir <- "final_analysis/tables"
if (!dir.exists(tables_dir)) {
  dir.create(tables_dir, recursive = TRUE)
}

write.csv(batch_analysis, file.path(tables_dir, "batch_analysis_detailed.csv"), row.names = FALSE)
write.csv(batch_summary, file.path(tables_dir, "batch_summary.csv"), row.names = FALSE)
write.csv(outliers_summary, file.path(tables_dir, "outliers_by_batch.csv"), row.names = FALSE)
write.csv(as.data.frame(correlation_vars), file.path(tables_dir, "correlation_matrix.csv"), row.names = TRUE)

cat(paste0("   - Tablas guardadas en: ", tables_dir, "\n\n"))

# --- 10. RESUMEN FINAL ---
cat("📋 10. RESUMEN FINAL\n")
cat("====================\n")
cat("📊 ANÁLISIS DE BATCH:\n")
cat(paste0("   - Batches identificados: ", length(unique(detailed_metadata$batch)), "\n"))
cat(paste0("   - VAF por batch significativo: ", ifelse(anova_summary_vaf[[1]]$`Pr(>F)`[1] < 0.05, "SÍ", "NO"), "\n"))
cat(paste0("   - SNVs por batch significativo: ", ifelse(anova_summary_snvs[[1]]$`Pr(>F)`[1] < 0.05, "SÍ", "NO"), "\n"))
cat(paste0("   - Interacción cohorte x batch: ", ifelse(interaction_summary[[1]]$`Pr(>F)`[2] < 0.05, "SÍ", "NO"), "\n\n"))

cat("🔍 CORRELACIONES:\n")
cat(paste0("   - VAF vs SNVs detectados: ", round(correlation_vars[1,2], 3), "\n"))
cat(paste0("   - VAF vs SNVs VAF > 0.1: ", round(correlation_vars[1,3], 3), "\n"))
cat(paste0("   - SNVs detectados vs SNVs VAF > 0.1: ", round(correlation_vars[2,3], 3), "\n\n"))

cat("🎯 OUTLIERS:\n")
cat(paste0("   - Total outliers VAF: ", sum(outlier_analysis$vaf_outlier, na.rm = TRUE), "\n"))
cat(paste0("   - Total outliers SNVs: ", sum(outlier_analysis$snvs_outlier, na.rm = TRUE), "\n\n"))

cat("✅ VERIFICACIONES:\n")
cat("   - Metadatos detallados extraídos: ✓\n")
cat("   - Análisis de batch completado: ✓\n")
cat("   - Tests estadísticos realizados: ✓\n")
cat("   - Visualizaciones creadas: ✓\n")
cat("   - Resultados guardados: ✓\n\n")

cat("🎯 PRÓXIMOS PASOS:\n")
cat("   - Ejecutar análisis posicional detallado\n")
cat("   - Realizar tests diferenciales por posición\n")
cat("   - Crear heatmaps de patrones posicionales\n\n")
