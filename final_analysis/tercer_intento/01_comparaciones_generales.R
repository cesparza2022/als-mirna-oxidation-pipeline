library(dplyr)
library(tidyr)
library(ggplot2)
library(reshape2)

# =============================================================================
# COMPARACIONES GENERALES ALS vs CONTROL
# =============================================================================

cat("=== COMPARACIONES GENERALES ALS vs CONTROL ===\n\n")

# 1. CARGAR DATOS PROCESADOS
# =============================================================================
cat("1. CARGANDO DATOS PROCESADOS\n")
cat("============================\n")

# Cargar datos finales procesados
final_data <- read.csv("../processed_data/final_processed_data.csv", stringsAsFactors = FALSE)

cat("Datos cargados:\n")
cat("  - SNVs:", nrow(final_data), "\n")
cat("  - miRNAs:", length(unique(final_data$miRNA_name)), "\n")
cat("  - Muestras:", ncol(final_data) - 2, "\n\n")

# 2. IDENTIFICAR GRUPOS DE MUESTRAS
# =============================================================================
cat("2. IDENTIFICANDO GRUPOS DE MUESTRAS\n")
cat("===================================\n")

# Obtener columnas de muestras
sample_cols <- colnames(final_data)[!colnames(final_data) %in% c("miRNA_name", "pos.mut")]

# Identificar grupos
identify_cohort <- function(col_name) {
  if (grepl("control", col_name, ignore.case = TRUE)) {
    return("Control")
  } else if (grepl("ALS", col_name, ignore.case = TRUE)) {
    return("ALS")
  } else {
    return("Unknown")
  }
}

cohorts <- sapply(sample_cols, identify_cohort)
cohort_counts <- table(cohorts)

cat("Distribución de muestras:\n")
print(cohort_counts)

# Separar columnas por grupo
control_cols <- sample_cols[cohorts == "Control"]
als_cols <- sample_cols[cohorts == "ALS"]

cat("  - Control:", length(control_cols), "muestras\n")
cat("  - ALS:", length(als_cols), "muestras\n\n")

# 3. CALCULAR MÉTRICAS POR MUESTRA
# =============================================================================
cat("3. CALCULANDO MÉTRICAS POR MUESTRA\n")
cat("==================================\n")

# Función para calcular métricas por muestra
calculate_sample_metrics <- function(data, sample_cols, group_name) {
  metrics <- data.frame(
    sample = sample_cols,
    group = group_name,
    n_snvs = 0,
    mean_vaf = 0,
    median_vaf = 0,
    n_snvs_with_vaf = 0,
    stringsAsFactors = FALSE
  )
  
  for (i in seq_along(sample_cols)) {
    col_name <- sample_cols[i]
    vaf_values <- data[[col_name]]
    
    # Contar SNVs totales (no NaN)
    n_snvs <- sum(!is.na(vaf_values))
    
    # Calcular VAFs promedio y mediana (excluyendo NaN)
    mean_vaf <- mean(vaf_values, na.rm = TRUE)
    median_vaf <- median(vaf_values, na.rm = TRUE)
    
    # Contar SNVs con VAF válido
    n_snvs_with_vaf <- sum(!is.na(vaf_values) & vaf_values > 0)
    
    metrics[i, "n_snvs"] <- n_snvs
    metrics[i, "mean_vaf"] <- mean_vaf
    metrics[i, "median_vaf"] <- median_vaf
    metrics[i, "n_snvs_with_vaf"] <- n_snvs_with_vaf
  }
  
  return(metrics)
}

# Calcular métricas para cada grupo
control_metrics <- calculate_sample_metrics(final_data, control_cols, "Control")
als_metrics <- calculate_sample_metrics(final_data, als_cols, "ALS")

# Combinar métricas
all_metrics <- rbind(control_metrics, als_metrics)

cat("Métricas calculadas para", nrow(all_metrics), "muestras\n\n")

# 4. COMPARACIONES ESTADÍSTICAS
# =============================================================================
cat("4. COMPARACIONES ESTADÍSTICAS\n")
cat("=============================\n")

# Test t para número de SNVs por muestra
snv_control <- control_metrics$n_snvs
snv_als <- als_metrics$n_snvs

if (var(snv_control) > 0 && var(snv_als) > 0) {
  t_test_snvs <- t.test(snv_als, snv_control)
  cat("Test t para número de SNVs por muestra:\n")
  cat("  - p-value:", round(t_test_snvs$p.value, 6), "\n")
  cat("  - t-statistic:", round(t_test_snvs$statistic, 4), "\n")
  cat("  - SNVs medio ALS:", round(mean(snv_als), 2), "±", round(sd(snv_als), 2), "\n")
  cat("  - SNVs medio Control:", round(mean(snv_control), 2), "±", round(sd(snv_control), 2), "\n\n")
} else {
  cat("Test t para número de SNVs por muestra:\n")
  cat("  - No se puede realizar (datos constantes)\n")
  cat("  - SNVs medio ALS:", round(mean(snv_als), 2), "\n")
  cat("  - SNVs medio Control:", round(mean(snv_control), 2), "\n\n")
}

# Test t para VAF promedio por muestra
vaf_control <- control_metrics$mean_vaf
vaf_als <- als_metrics$mean_vaf

if (var(vaf_control) > 0 && var(vaf_als) > 0) {
  t_test_vaf <- t.test(vaf_als, vaf_control)
  cat("Test t para VAF promedio por muestra:\n")
  cat("  - p-value:", round(t_test_vaf$p.value, 6), "\n")
  cat("  - t-statistic:", round(t_test_vaf$statistic, 4), "\n")
  cat("  - VAF medio ALS:", round(mean(vaf_als), 4), "±", round(sd(vaf_als), 4), "\n")
  cat("  - VAF medio Control:", round(mean(vaf_control), 4), "±", round(sd(vaf_control), 4), "\n\n")
} else {
  cat("Test t para VAF promedio por muestra:\n")
  cat("  - No se puede realizar (datos constantes)\n")
  cat("  - VAF medio ALS:", round(mean(vaf_als), 4), "\n")
  cat("  - VAF medio Control:", round(mean(vaf_control), 4), "\n\n")
}

# 5. ANÁLISIS DE OXIDACIÓN GENERAL
# =============================================================================
cat("5. ANÁLISIS DE OXIDACIÓN GENERAL\n")
cat("================================\n")

# Calcular métricas de oxidación por grupo
oxidation_summary <- all_metrics %>%
  group_by(group) %>%
  summarise(
    n_samples = n(),
    mean_snvs = mean(n_snvs, na.rm = TRUE),
    sd_snvs = sd(n_snvs, na.rm = TRUE),
    mean_vaf = mean(mean_vaf, na.rm = TRUE),
    sd_vaf = sd(mean_vaf, na.rm = TRUE),
    median_vaf = median(mean_vaf, na.rm = TRUE),
    total_snvs = sum(n_snvs, na.rm = TRUE),
    .groups = 'drop'
  )

cat("Resumen de oxidación por grupo:\n")
print(oxidation_summary)

# 6. CREAR GRÁFICOS
# =============================================================================
cat("\n6. CREANDO GRÁFICOS\n")
cat("===================\n")

# Gráfico 1: Distribución de SNVs por muestra
p1 <- ggplot(all_metrics, aes(x = group, y = n_snvs, fill = group)) +
  geom_boxplot(alpha = 0.7) +
  geom_jitter(width = 0.2, alpha = 0.5) +
  labs(
    title = "Distribución de SNVs por Muestra",
    x = "Grupo",
    y = "Número de SNVs",
    fill = "Grupo"
  ) +
  theme_minimal() +
  scale_fill_manual(values = c("Control" = "lightblue", "ALS" = "lightcoral"))

ggsave("distribucion_snvs_por_muestra.pdf", p1, width = 8, height = 6)

# Gráfico 2: Distribución de VAF promedio por muestra
p2 <- ggplot(all_metrics, aes(x = group, y = mean_vaf, fill = group)) +
  geom_boxplot(alpha = 0.7) +
  geom_jitter(width = 0.2, alpha = 0.5) +
  labs(
    title = "Distribución de VAF Promedio por Muestra",
    x = "Grupo",
    y = "VAF Promedio",
    fill = "Grupo"
  ) +
  theme_minimal() +
  scale_fill_manual(values = c("Control" = "lightblue", "ALS" = "lightcoral"))

ggsave("distribucion_vaf_promedio_por_muestra.pdf", p2, width = 8, height = 6)

# Gráfico 3: Scatter plot SNVs vs VAF promedio
p3 <- ggplot(all_metrics, aes(x = n_snvs, y = mean_vaf, color = group)) +
  geom_point(alpha = 0.7, size = 2) +
  geom_smooth(method = "lm", se = TRUE) +
  labs(
    title = "Relación entre Número de SNVs y VAF Promedio",
    x = "Número de SNVs",
    y = "VAF Promedio",
    color = "Grupo"
  ) +
  theme_minimal() +
  scale_color_manual(values = c("Control" = "blue", "ALS" = "red"))

ggsave("scatter_snvs_vs_vaf.pdf", p3, width = 10, height = 6)

cat("Gráficos guardados:\n")
cat("  - distribucion_snvs_por_muestra.pdf\n")
cat("  - distribucion_vaf_promedio_por_muestra.pdf\n")
cat("  - scatter_snvs_vs_vaf.pdf\n\n")

# 7. GUARDAR RESULTADOS
# =============================================================================
cat("7. GUARDANDO RESULTADOS\n")
cat("=======================\n")

# Guardar métricas por muestra
write.csv(all_metrics, "metricas_por_muestra.csv", row.names = FALSE)

# Guardar resumen de oxidación
write.csv(oxidation_summary, "resumen_oxidacion_por_grupo.csv", row.names = FALSE)

cat("Archivos guardados:\n")
cat("  - metricas_por_muestra.csv\n")
cat("  - resumen_oxidacion_por_grupo.csv\n\n")

cat("=== ANÁLISIS COMPLETADO ===\n")









