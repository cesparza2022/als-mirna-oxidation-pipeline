# --- LIBRERÍAS ---
library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(corrplot)
library(reshape2)

# --- CONFIGURACIÓN ---
cat("🔬 ANÁLISIS DE CONFOUNDERS (VERSIÓN SIMPLIFICADA)\n")
cat("==================================================\n\n")

# --- 1. CARGANDO DATOS PROCESADOS ---
cat("📊 1. CARGANDO DATOS PROCESADOS\n")
cat("===============================\n")

processed_data_path <- "final_analysis/processed_data/processed_snvs_gt.csv"
df_processed <- read.csv(processed_data_path, stringsAsFactors = FALSE)

# Cargar métricas globales
global_metrics <- read.csv("final_analysis/tables/global_metrics.csv", stringsAsFactors = FALSE)

cat(paste0("   - SNVs procesados: ", nrow(df_processed), "\n"))
cat(paste0("   - miRNAs únicos: ", length(unique(df_processed$miRNA.name)), "\n"))
cat(paste0("   - Muestras: ", nrow(global_metrics), "\n\n"))

# --- 2. ANÁLISIS DE DISTRIBUCIÓN POR BATCH ---
cat("📈 2. ANÁLISIS DE DISTRIBUCIÓN POR BATCH\n")
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
print(head(batch_summary, 20))
cat("\n")

# --- 3. ANÁLISIS DE CORRELACIÓN ENTRE VARIABLES ---
cat("🔗 3. ANÁLISIS DE CORRELACIÓN ENTRE VARIABLES\n")
cat("=============================================\n")

# Crear matriz de correlación
correlation_vars <- batch_analysis %>%
  select(mean_vaf, snvs_detected, high_vaf_snvs) %>%
  cor(use = "complete.obs")

cat("   - Matriz de correlación:\n")
print(round(correlation_vars, 3))
cat("\n")

# --- 4. ANÁLISIS DE OUTLIERS ---
cat("🎯 4. ANÁLISIS DE OUTLIERS\n")
cat("==========================\n")

# Identificar outliers globales
outlier_analysis <- batch_analysis %>%
  mutate(
    vaf_outlier = abs(mean_vaf - mean(mean_vaf, na.rm = TRUE)) > 2 * sd(mean_vaf, na.rm = TRUE),
    snvs_outlier = abs(snvs_detected - mean(snvs_detected, na.rm = TRUE)) > 2 * sd(snvs_detected, na.rm = TRUE)
  )

outliers_summary <- outlier_analysis %>%
  summarise(
    vaf_outliers = sum(vaf_outlier, na.rm = TRUE),
    snvs_outliers = sum(snvs_outlier, na.rm = TRUE),
    total_samples = n()
  )

cat("   - Outliers globales:\n")
print(outliers_summary)
cat("\n")

# --- 5. ANÁLISIS DE DISTRIBUCIÓN POR COHORTE ---
cat("📊 5. ANÁLISIS DE DISTRIBUCIÓN POR COHORTE\n")
cat("==========================================\n")

cohort_summary <- batch_analysis %>%
  group_by(cohort) %>%
  summarise(
    n_samples = n(),
    mean_vaf = mean(mean_vaf, na.rm = TRUE),
    median_vaf = median(mean_vaf, na.rm = TRUE),
    sd_vaf = sd(mean_vaf, na.rm = TRUE),
    mean_snvs_detected = mean(snvs_detected, na.rm = TRUE),
    median_snvs_detected = median(snvs_detected, na.rm = TRUE),
    sd_snvs_detected = sd(snvs_detected, na.rm = TRUE),
    .groups = 'drop'
  )

cat("   - Resumen por cohorte:\n")
print(cohort_summary)
cat("\n")

# --- 6. TESTS ESTADÍSTICOS SIMPLES ---
cat("📊 6. TESTS ESTADÍSTICOS SIMPLES\n")
cat("================================\n")

# Test t para VAF medio (ALS vs Control)
t_test_vaf <- t.test(mean_vaf ~ cohort, data = batch_analysis)
cat("   - Test t para VAF medio (ALS vs Control):\n")
cat(paste0("     - t = ", round(t_test_vaf$statistic, 3), "\n"))
cat(paste0("     - p-value = ", round(t_test_vaf$p.value, 5), "\n"))
cat(paste0("     - Significativo: ", ifelse(t_test_vaf$p.value < 0.05, "SÍ", "NO"), "\n\n"))

# Test t para SNVs detectados (ALS vs Control)
t_test_snvs <- t.test(snvs_detected ~ cohort, data = batch_analysis)
cat("   - Test t para SNVs detectados (ALS vs Control):\n")
cat(paste0("     - t = ", round(t_test_snvs$statistic, 3), "\n"))
cat(paste0("     - p-value = ", round(t_test_snvs$p.value, 5), "\n"))
cat(paste0("     - Significativo: ", ifelse(t_test_snvs$p.value < 0.05, "SÍ", "NO"), "\n\n"))

# --- 7. CREANDO VISUALIZACIONES ---
cat("📊 7. CREANDO VISUALIZACIONES\n")
cat("=============================\n")

figures_dir <- "final_analysis/figures"
if (!dir.exists(figures_dir)) {
  dir.create(figures_dir, recursive = TRUE)
}

# Boxplot de VAF por cohorte
p_vaf_cohort <- ggplot(batch_analysis, aes(x = cohort, y = mean_vaf, fill = cohort)) +
  geom_boxplot() +
  labs(title = "VAF Medio por Cohorte", x = "Cohorte", y = "VAF Medio") +
  theme_minimal()
ggsave(file.path(figures_dir, "vaf_by_cohort.png"), p_vaf_cohort)

# Boxplot de SNVs detectados por cohorte
p_snvs_cohort <- ggplot(batch_analysis, aes(x = cohort, y = snvs_detected, fill = cohort)) +
  geom_boxplot() +
  labs(title = "SNVs Detectados por Cohorte", x = "Cohorte", y = "SNVs Detectados") +
  theme_minimal()
ggsave(file.path(figures_dir, "snvs_by_cohort.png"), p_snvs_cohort)

# Scatter plot de VAF vs SNVs detectados
p_scatter <- ggplot(batch_analysis, aes(x = snvs_detected, y = mean_vaf, color = cohort)) +
  geom_point(alpha = 0.7) +
  geom_smooth(method = "lm", se = TRUE) +
  labs(title = "VAF vs SNVs Detectados", x = "SNVs Detectados", y = "VAF Medio") +
  theme_minimal()
ggsave(file.path(figures_dir, "vaf_vs_snvs_scatter.png"), p_scatter)

# Histograma de VAF por cohorte
p_hist_vaf <- ggplot(batch_analysis, aes(x = mean_vaf, fill = cohort)) +
  geom_histogram(alpha = 0.7, bins = 30) +
  facet_wrap(~cohort) +
  labs(title = "Distribución de VAF Medio por Cohorte", x = "VAF Medio", y = "Frecuencia") +
  theme_minimal()
ggsave(file.path(figures_dir, "vaf_histogram_by_cohort.png"), p_hist_vaf)

cat(paste0("   - Figuras guardadas en: ", figures_dir, "\n\n"))

# --- 8. GUARDAR RESULTADOS ---
cat("💾 8. GUARDAR RESULTADOS\n")
cat("========================\n")

tables_dir <- "final_analysis/tables"
if (!dir.exists(tables_dir)) {
  dir.create(tables_dir, recursive = TRUE)
}

write.csv(batch_analysis, file.path(tables_dir, "batch_analysis_detailed.csv"), row.names = FALSE)
write.csv(batch_summary, file.path(tables_dir, "batch_summary.csv"), row.names = FALSE)
write.csv(outliers_summary, file.path(tables_dir, "outliers_summary.csv"), row.names = FALSE)
write.csv(cohort_summary, file.path(tables_dir, "cohort_summary.csv"), row.names = FALSE)
write.csv(as.data.frame(correlation_vars), file.path(tables_dir, "correlation_matrix.csv"), row.names = TRUE)

cat(paste0("   - Tablas guardadas en: ", tables_dir, "\n\n"))

# --- 9. RESUMEN FINAL ---
cat("📋 9. RESUMEN FINAL\n")
cat("===================\n")
cat("📊 MÉTRICAS POR COHORTE:\n")
cat(paste0("   - VAF medio ALS: ", round(cohort_summary$mean_vaf[cohort_summary$cohort == "ALS"], 4), "\n"))
cat(paste0("   - VAF medio Control: ", round(cohort_summary$mean_vaf[cohort_summary$cohort == "Control"], 4), "\n"))
cat(paste0("   - SNVs detectados ALS: ", round(cohort_summary$mean_snvs_detected[cohort_summary$cohort == "ALS"], 1), "\n"))
cat(paste0("   - SNVs detectados Control: ", round(cohort_summary$mean_snvs_detected[cohort_summary$cohort == "Control"], 1), "\n\n"))

cat("📈 TESTS ESTADÍSTICOS:\n")
cat(paste0("   - VAF medio significativo: ", ifelse(t_test_vaf$p.value < 0.05, "SÍ", "NO"), " (p = ", round(t_test_vaf$p.value, 5), ")\n"))
cat(paste0("   - SNVs detectados significativo: ", ifelse(t_test_snvs$p.value < 0.05, "SÍ", "NO"), " (p = ", round(t_test_snvs$p.value, 5), ")\n\n"))

cat("🔍 CORRELACIONES:\n")
cat(paste0("   - VAF vs SNVs detectados: ", round(correlation_vars[1,2], 3), "\n"))
cat(paste0("   - VAF vs SNVs VAF > 0.1: ", round(correlation_vars[1,3], 3), "\n"))
cat(paste0("   - SNVs detectados vs SNVs VAF > 0.1: ", round(correlation_vars[2,3], 3), "\n\n"))

cat("🎯 OUTLIERS:\n")
cat(paste0("   - Total outliers VAF: ", outliers_summary$vaf_outliers, "\n"))
cat(paste0("   - Total outliers SNVs: ", outliers_summary$snvs_outliers, "\n"))
cat(paste0("   - Total muestras: ", outliers_summary$total_samples, "\n\n"))

cat("✅ VERIFICACIONES:\n")
cat("   - Análisis de cohorte completado: ✓\n")
cat("   - Tests estadísticos realizados: ✓\n")
cat("   - Visualizaciones creadas: ✓\n")
cat("   - Resultados guardados: ✓\n\n")

cat("🎯 PRÓXIMOS PASOS:\n")
cat("   - Ejecutar análisis posicional detallado\n")
cat("   - Realizar tests diferenciales por posición\n")
cat("   - Crear heatmaps de patrones posicionales\n\n")









