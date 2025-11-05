library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)

# =============================================================================
# ANÁLISIS DETALLADO DE SNVs EN POSICIÓN 6
# =============================================================================

cat("=== ANÁLISIS DETALLADO DE SNVs EN POSICIÓN 6 ===\n\n")

# 1. CARGAR DATOS PROCESADOS
# =============================================================================
cat("1. CARGANDO DATOS PROCESADOS\n")
cat("============================\n")

final_data <- read.csv("../processed_data/final_processed_data.csv", stringsAsFactors = FALSE)

cat("Datos cargados:\n")
cat("  - SNVs totales:", nrow(final_data), "\n")
cat("  - miRNAs únicos:", length(unique(final_data$miRNA_name)), "\n\n")

# 2. FILTRAR SNVs DE POSICIÓN 6
# =============================================================================
cat("2. FILTRANDO SNVs DE POSICIÓN 6\n")
cat("===============================\n")

# Extraer posición y filtrar posición 6
pos6_data <- final_data %>%
  mutate(
    pos = as.integer(str_extract(pos.mut, "^[0-9]+")),
    mutation_type = str_extract(pos.mut, "[A-Z]+$")
  ) %>%
  filter(pos == 6)

cat("SNVs en posición 6:\n")
cat("  - Total SNVs posición 6:", nrow(pos6_data), "\n")
cat("  - miRNAs únicos con SNVs en pos 6:", length(unique(pos6_data$miRNA_name)), "\n\n")

# 3. ANÁLISIS DE TIPOS DE MUTACIÓN EN POSICIÓN 6
# =============================================================================
cat("3. ANÁLISIS DE TIPOS DE MUTACIÓN EN POSICIÓN 6\n")
cat("==============================================\n")

# Contar tipos de mutación
mutation_types <- pos6_data %>%
  count(mutation_type, name = "count") %>%
  arrange(desc(count))

cat("Tipos de mutación en posición 6:\n")
print(mutation_types)

# Verificar que solo tenemos G>T
gt_only <- pos6_data %>%
  filter(mutation_type == "GT")

cat("\nVerificación G>T:\n")
cat("  - SNVs G>T en pos 6:", nrow(gt_only), "\n")
cat("  - % G>T:", round(nrow(gt_only) / nrow(pos6_data) * 100, 2), "%\n\n")

# 4. IDENTIFICAR GRUPOS DE MUESTRAS
# =============================================================================
cat("4. IDENTIFICANDO GRUPOS DE MUESTRAS\n")
cat("===================================\n")

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
control_cols <- sample_cols[cohorts == "Control"]
als_cols <- sample_cols[cohorts == "ALS"]

cat("Distribución de muestras:\n")
cat("  - Control:", length(control_cols), "muestras\n")
cat("  - ALS:", length(als_cols), "muestras\n")
cat("  - Total:", length(sample_cols), "muestras\n\n")

# 5. ANÁLISIS DETALLADO POR MUESTRA - POSICIÓN 6
# =============================================================================
cat("5. ANÁLISIS DETALLADO POR MUESTRA - POSICIÓN 6\n")
cat("==============================================\n")

# Crear dataframe largo para análisis por muestra
pos6_long <- pos6_data %>%
  pivot_longer(
    cols = all_of(sample_cols),
    names_to = "sample",
    values_to = "vaf"
  ) %>%
  mutate(
    cohort = case_when(
      grepl("control", sample, ignore.case = TRUE) ~ "Control",
      grepl("ALS", sample, ignore.case = TRUE) ~ "ALS",
      TRUE ~ "Unknown"
    )
  ) %>%
  filter(cohort %in% c("Control", "ALS"))

cat("Datos en formato largo para posición 6:\n")
cat("  - Filas totales:", nrow(pos6_long), "\n")
cat("  - SNVs únicos:", length(unique(pos6_long$miRNA_name)), "\n")
cat("  - Muestras:", length(unique(pos6_long$sample)), "\n\n")

# 6. ANÁLISIS DE VAFs VÁLIDOS vs NAs
# =============================================================================
cat("6. ANÁLISIS DE VAFs VÁLIDOS vs NAs\n")
cat("==================================\n")

# Contar VAFs válidos vs NAs por cohorte
vaf_analysis <- pos6_long %>%
  group_by(cohort) %>%
  summarise(
    total_measurements = n(),
    valid_vafs = sum(!is.na(vaf) & vaf > 0),
    na_vafs = sum(is.na(vaf)),
    zero_vafs = sum(!is.na(vaf) & vaf == 0),
    valid_pct = round(valid_vafs / total_measurements * 100, 2),
    na_pct = round(na_vafs / total_measurements * 100, 2),
    .groups = 'drop'
  )

cat("Análisis de VAFs por cohorte en posición 6:\n")
print(vaf_analysis)

# 7. ANÁLISIS DE SNVs POR COHORTE
# =============================================================================
cat("\n7. ANÁLISIS DE SNVs POR COHORTE\n")
cat("================================\n")

# Contar SNVs únicos por cohorte
snv_analysis <- pos6_long %>%
  filter(!is.na(vaf) & vaf > 0) %>%  # Solo VAFs válidos
  group_by(cohort) %>%
  summarise(
    unique_snvs = n_distinct(paste(miRNA_name, pos.mut)),
    unique_mirnas = n_distinct(miRNA_name),
    total_measurements = n(),
    mean_vaf = round(mean(vaf, na.rm = TRUE), 6),
    median_vaf = round(median(vaf, na.rm = TRUE), 6),
    .groups = 'drop'
  )

cat("SNVs únicos por cohorte en posición 6:\n")
print(snv_analysis)

# 8. ANÁLISIS DETALLADO POR miRNA
# =============================================================================
cat("\n8. ANÁLISIS DETALLADO POR miRNA\n")
cat("===============================\n")

# Análisis por miRNA individual
mirna_analysis <- pos6_long %>%
  filter(!is.na(vaf) & vaf > 0) %>%
  group_by(miRNA_name, cohort) %>%
  summarise(
    n_samples = n(),
    mean_vaf = mean(vaf, na.rm = TRUE),
    median_vaf = median(vaf, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  pivot_wider(
    names_from = cohort,
    values_from = c(n_samples, mean_vaf, median_vaf),
    names_sep = "_"
  ) %>%
  mutate(
    n_samples_Control = ifelse(is.na(n_samples_Control), 0, n_samples_Control),
    n_samples_ALS = ifelse(is.na(n_samples_ALS), 0, n_samples_ALS),
    mean_vaf_Control = ifelse(is.na(mean_vaf_Control), 0, mean_vaf_Control),
    mean_vaf_ALS = ifelse(is.na(mean_vaf_ALS), 0, mean_vaf_ALS),
    median_vaf_Control = ifelse(is.na(median_vaf_Control), 0, median_vaf_Control),
    median_vaf_ALS = ifelse(is.na(median_vaf_ALS), 0, median_vaf_ALS)
  )

cat("Top 10 miRNAs con más SNVs en posición 6:\n")
top_mirnas <- mirna_analysis %>%
  mutate(total_samples = n_samples_Control + n_samples_ALS) %>%
  arrange(desc(total_samples)) %>%
  head(10)

print(top_mirnas)

# 9. ANÁLISIS ESTADÍSTICO DETALLADO
# =============================================================================
cat("\n9. ANÁLISIS ESTADÍSTICO DETALLADO\n")
cat("==================================\n")

# Test t para VAFs entre grupos
control_vafs <- pos6_long$vaf[pos6_long$cohort == "Control" & !is.na(pos6_long$vaf) & pos6_long$vaf > 0]
als_vafs <- pos6_long$vaf[pos6_long$cohort == "ALS" & !is.na(pos6_long$vaf) & pos6_long$vaf > 0]

if (length(control_vafs) > 1 && length(als_vafs) > 1) {
  t_test <- t.test(als_vafs, control_vafs)
  
  cat("Test t para VAFs en posición 6:\n")
  cat("  - p-value:", round(t_test$p.value, 6), "\n")
  cat("  - t-statistic:", round(t_test$statistic, 4), "\n")
  cat("  - VAF medio Control:", round(mean(control_vafs), 6), "±", round(sd(control_vafs), 6), "\n")
  cat("  - VAF medio ALS:", round(mean(als_vafs), 6), "±", round(sd(als_vafs), 6), "\n")
  cat("  - Diferencia de medias:", round(mean(als_vafs) - mean(control_vafs), 6), "\n\n")
}

# Test de Fisher para número de SNVs
control_snvs <- sum(snv_analysis$unique_snvs[snv_analysis$cohort == "Control"])
als_snvs <- sum(snv_analysis$unique_snvs[snv_analysis$cohort == "ALS"])

fisher_test <- fisher.test(
  matrix(
    c(als_snvs, control_snvs, 
      length(als_cols), length(control_cols)),
    nrow = 2
  )
)

cat("Test de Fisher para número de SNVs en posición 6:\n")
cat("  - p-value:", round(fisher_test$p.value, 6), "\n")
cat("  - OR:", round(fisher_test$estimate, 4), "\n")
cat("  - SNVs Control:", control_snvs, "\n")
cat("  - SNVs ALS:", als_snvs, "\n\n")

# 10. ANÁLISIS DE DISTRIBUCIÓN DE VAFs
# =============================================================================
cat("10. ANÁLISIS DE DISTRIBUCIÓN DE VAFs\n")
cat("====================================\n")

# Crear histograma de VAFs
p1 <- ggplot(pos6_long %>% filter(!is.na(vaf) & vaf > 0), 
             aes(x = vaf, fill = cohort)) +
  geom_histogram(alpha = 0.7, bins = 50, position = "identity") +
  facet_wrap(~cohort, scales = "free_y") +
  labs(title = "Distribución de VAFs en Posición 6",
       x = "VAF", y = "Frecuencia") +
  theme_minimal()

ggsave("histograma_vafs_posicion_6.pdf", p1, width = 10, height = 6)

# Boxplot de VAFs
p2 <- ggplot(pos6_long %>% filter(!is.na(vaf) & vaf > 0), 
             aes(x = cohort, y = vaf, fill = cohort)) +
  geom_boxplot() +
  geom_jitter(width = 0.2, alpha = 0.3) +
  labs(title = "Boxplot de VAFs en Posición 6",
       x = "Cohorte", y = "VAF") +
  theme_minimal()

ggsave("boxplot_vafs_posicion_6.pdf", p2, width = 8, height = 6)

cat("Gráficos guardados:\n")
cat("  - histograma_vafs_posicion_6.pdf\n")
cat("  - boxplot_vafs_posicion_6.pdf\n\n")

# 11. ANÁLISIS DE SNVs MÁS ABUNDANTES
# =============================================================================
cat("11. ANÁLISIS DE SNVs MÁS ABUNDANTES\n")
cat("===================================\n")

# SNVs más abundantes por cohorte
top_snvs_control <- pos6_long %>%
  filter(cohort == "Control" & !is.na(vaf) & vaf > 0) %>%
  group_by(miRNA_name, pos.mut) %>%
  summarise(
    n_samples = n(),
    mean_vaf = mean(vaf),
    .groups = 'drop'
  ) %>%
  arrange(desc(n_samples)) %>%
  head(10)

top_snvs_als <- pos6_long %>%
  filter(cohort == "ALS" & !is.na(vaf) & vaf > 0) %>%
  group_by(miRNA_name, pos.mut) %>%
  summarise(
    n_samples = n(),
    mean_vaf = mean(vaf),
    .groups = 'drop'
  ) %>%
  arrange(desc(n_samples)) %>%
  head(10)

cat("Top 10 SNVs más abundantes en Control:\n")
print(top_snvs_control)

cat("\nTop 10 SNVs más abundantes en ALS:\n")
print(top_snvs_als)

# 12. GUARDAR RESULTADOS DETALLADOS
# =============================================================================
cat("\n12. GUARDANDO RESULTADOS DETALLADOS\n")
cat("====================================\n")

# Guardar análisis por miRNA
write.csv(mirna_analysis, "analisis_mirnas_posicion_6.csv", row.names = FALSE)

# Guardar análisis de VAFs
write.csv(vaf_analysis, "analisis_vafs_posicion_6.csv", row.names = FALSE)

# Guardar análisis de SNVs
write.csv(snv_analysis, "analisis_snvs_posicion_6.csv", row.names = FALSE)

# Guardar datos completos de posición 6
write.csv(pos6_long, "datos_completos_posicion_6.csv", row.names = FALSE)

cat("Archivos guardados:\n")
cat("  - analisis_mirnas_posicion_6.csv\n")
cat("  - analisis_vafs_posicion_6.csv\n")
cat("  - analisis_snvs_posicion_6.csv\n")
cat("  - datos_completos_posicion_6.csv\n")
cat("  - histograma_vafs_posicion_6.pdf\n")
cat("  - boxplot_vafs_posicion_6.pdf\n\n")

cat("=== ANÁLISIS DETALLADO DE POSICIÓN 6 COMPLETADO ===\n")









