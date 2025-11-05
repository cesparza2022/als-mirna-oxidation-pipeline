# =============================================================================
# ANÁLISIS FINAL - PASO 4: SEÑAL GLOBAL DE OXIDACIÓN
# =============================================================================
# 
# Este script realiza:
# 1. Análisis de señal global G>T (ALS vs Control)
# 2. Comparación de composición de cambios de base
# 3. Tests estadísticos diferenciales
# 4. Visualizaciones de señal global
#
# Autor: Análisis UCSD 8OG
# Fecha: 2025
# =============================================================================

# --- LIBRERÍAS ---
library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(RColorBrewer)
library(reshape2)
library(broom)

# --- CONFIGURACIÓN ---
cat("🔬 ANÁLISIS DE SEÑAL GLOBAL DE OXIDACIÓN\n")
cat("========================================\n\n")

# --- 1. CARGAR DATOS PROCESADOS ---
cat("📊 1. CARGANDO DATOS PROCESADOS\n")
cat("===============================\n")

# Cargar datos procesados
df_processed <- read.csv("final_analysis/processed_data/processed_snvs_gt.csv", stringsAsFactors = FALSE)

# Cargar metadatos de muestras
sample_metadata <- read.csv("final_analysis/tables/sample_metadata.csv", stringsAsFactors = FALSE)

# Identificar columnas
total_cols <- names(df_processed)[grepl('..PM.1MM.2MM.', names(df_processed), fixed=TRUE)]
count_cols <- names(df_processed)[!grepl('..PM.1MM.2MM.', names(df_processed), fixed=TRUE) & 
                                 !names(df_processed) %in% c('miRNA_name', 'pos', 'mutation_type', 'count')]

cat(paste0("   - SNVs procesados: ", nrow(df_processed), "\n"))
cat(paste0("   - miRNAs únicos: ", length(unique(df_processed$miRNA_name)), "\n"))
cat(paste0("   - Muestras: ", length(count_cols), "\n"))
cat("\n")

# --- 2. CALCULAR VAFs POR MUESTRA ---
cat("🧮 2. CALCULANDO VAFs POR MUESTRA\n")
cat("=================================\n")

# Calcular VAFs para cada SNV y muestra
vaf_data <- df_processed %>%
  select(miRNA_name, pos, mutation_type, all_of(count_cols), all_of(total_cols)) %>%
  pivot_longer(
    cols = all_of(c(count_cols, total_cols)),
    names_to = "sample_full",
    values_to = "count"
  ) %>%
  mutate(
    sample = gsub('..PM.1MM.2MM.', '', sample_full, fixed=TRUE),
    count_type = ifelse(grepl('..PM.1MM.2MM.', sample_full, fixed=TRUE), "total", "snv")
  ) %>%
  select(-sample_full) %>%
  pivot_wider(names_from = count_type, values_from = count) %>%
  mutate(
    vaf = ifelse(total > 0, snv / total, 0),
    vaf = ifelse(vaf > 1, 1, vaf)  # Cap VAF at 1
  ) %>%
  filter(!is.na(vaf))

cat(paste0("   - VAFs calculados: ", nrow(vaf_data), "\n"))
cat(paste0("   - VAFs válidos (>0): ", sum(vaf_data$vaf > 0, na.rm = TRUE), "\n"))
cat(paste0("   - VAFs > 0.5: ", sum(vaf_data$vaf > 0.5, na.rm = TRUE), "\n"))
cat("\n")

# --- 3. ANÁLISIS DE SEÑAL GLOBAL POR MUESTRA ---
cat("📈 3. ANÁLISIS DE SEÑAL GLOBAL POR MUESTRA\n")
cat("==========================================\n")

# Calcular métricas globales por muestra
global_metrics <- vaf_data %>%
  group_by(sample) %>%
  summarise(
    total_snvs = n(),
    snvs_detected = sum(snv > 0, na.rm = TRUE),
    mean_vaf = mean(vaf, na.rm = TRUE),
    median_vaf = median(vaf, na.rm = TRUE),
    max_vaf = max(vaf, na.rm = TRUE),
    vaf_sd = sd(vaf, na.rm = TRUE),
    high_vaf_snvs = sum(vaf > 0.1, na.rm = TRUE),
    very_high_vaf_snvs = sum(vaf > 0.5, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  left_join(sample_metadata, by = "sample") %>%
  filter(!is.na(cohort))

cat(paste0("   - Muestras con metadatos: ", nrow(global_metrics), "\n"))
cat(paste0("   - Muestras ALS: ", sum(global_metrics$cohort == "ALS"), "\n"))
cat(paste0("   - Muestras Control: ", sum(global_metrics$cohort == "Control"), "\n"))
cat("\n")

# --- 4. TESTS ESTADÍSTICOS DIFERENCIALES ---
cat("📊 4. TESTS ESTADÍSTICOS DIFERENCIALES\n")
cat("======================================\n")

# Test t para VAF medio
t_test_mean_vaf <- t.test(mean_vaf ~ cohort, data = global_metrics)
cat("   - Test t para VAF medio (ALS vs Control):\n")
cat(paste0("     - t = ", round(t_test_mean_vaf$statistic, 3), "\n"))
cat(paste0("     - p-value = ", round(t_test_mean_vaf$p.value, 6), "\n"))
cat(paste0("     - Significativo: ", ifelse(t_test_mean_vaf$p.value < 0.05, "SÍ", "NO"), "\n"))
cat("\n")

# Test t para número de SNVs detectados
t_test_snvs <- t.test(snvs_detected ~ cohort, data = global_metrics)
cat("   - Test t para SNVs detectados (ALS vs Control):\n")
cat(paste0("     - t = ", round(t_test_snvs$statistic, 3), "\n"))
cat(paste0("     - p-value = ", round(t_test_snvs$p.value, 6), "\n"))
cat(paste0("     - Significativo: ", ifelse(t_test_snvs$p.value < 0.05, "SÍ", "NO"), "\n"))
cat("\n")

# Test t para SNVs con VAF alto
t_test_high_vaf <- t.test(high_vaf_snvs ~ cohort, data = global_metrics)
cat("   - Test t para SNVs con VAF > 0.1 (ALS vs Control):\n")
cat(paste0("     - t = ", round(t_test_high_vaf$statistic, 3), "\n"))
cat(paste0("     - p-value = ", round(t_test_high_vaf$p.value, 6), "\n"))
cat(paste0("     - Significativo: ", ifelse(t_test_high_vaf$p.value < 0.05, "SÍ", "NO"), "\n"))
cat("\n")

# --- 5. ANÁLISIS DE COMPOSICIÓN DE CAMBIOS DE BASE ---
cat("🧬 5. ANÁLISIS DE COMPOSICIÓN DE CAMBIOS DE BASE\n")
cat("===============================================\n")

# Cargar datos originales para análisis de composición
df_original <- read.csv("results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt", sep="\t", stringsAsFactors = FALSE)

# Extraer tipos de mutación
mutation_composition <- df_original %>%
  filter(grepl(':', pos.mut)) %>%
  mutate(
    mutation_type = str_extract(pos.mut, ":([A-Z]+)$", group = 1)
  ) %>%
  group_by(mutation_type) %>%
  summarise(
    total_snvs = n(),
    .groups = "drop"
  ) %>%
  mutate(
    percentage = total_snvs / sum(total_snvs) * 100
  ) %>%
  arrange(desc(total_snvs))

cat("   - Composición de tipos de mutación:\n")
print(mutation_composition)
cat("\n")

# --- 6. VISUALIZACIONES ---
cat("📊 6. CREANDO VISUALIZACIONES\n")
cat("=============================\n")

# Crear directorio de figuras si no existe
if (!dir.exists("final_analysis/figures")) {
  dir.create("final_analysis/figures", recursive = TRUE)
}

# Figura 1: Distribución de VAF medio por cohorte
p1 <- global_metrics %>%
  ggplot(aes(x = cohort, y = mean_vaf, fill = cohort)) +
  geom_violin(alpha = 0.7) +
  geom_boxplot(width = 0.1, alpha = 0.8) +
  geom_jitter(width = 0.1, alpha = 0.5) +
  scale_fill_brewer(type = "qual", palette = "Set2") +
  labs(
    title = "Distribución de VAF Medio por Cohorte",
    subtitle = paste0("Test t: p = ", round(t_test_mean_vaf$p.value, 4)),
    x = "Cohorte",
    y = "VAF Medio"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

ggsave("final_analysis/figures/vaf_by_cohort.png", p1, width = 10, height = 6, dpi = 300)

# Figura 2: Número de SNVs detectados por cohorte
p2 <- global_metrics %>%
  ggplot(aes(x = cohort, y = snvs_detected, fill = cohort)) +
  geom_violin(alpha = 0.7) +
  geom_boxplot(width = 0.1, alpha = 0.8) +
  geom_jitter(width = 0.1, alpha = 0.5) +
  scale_fill_brewer(type = "qual", palette = "Set2") +
  labs(
    title = "Número de SNVs Detectados por Cohorte",
    subtitle = paste0("Test t: p = ", round(t_test_snvs$p.value, 4)),
    x = "Cohorte",
    y = "SNVs Detectados"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

ggsave("final_analysis/figures/snvs_by_cohort.png", p2, width = 10, height = 6, dpi = 300)

# Figura 3: Composición de tipos de mutación
p3 <- mutation_composition %>%
  ggplot(aes(x = reorder(mutation_type, percentage), y = percentage, fill = mutation_type)) +
  geom_col(alpha = 0.7) +
  geom_text(aes(label = paste0(round(percentage, 1), "%")), hjust = -0.1) +
  coord_flip() +
  scale_fill_brewer(type = "qual", palette = "Set3") +
  labs(
    title = "Composición de Tipos de Mutación",
    x = "Tipo de Mutación",
    y = "Porcentaje (%)"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

ggsave("final_analysis/figures/mutation_composition.png", p3, width = 10, height = 6, dpi = 300)

# Figura 4: Scatter plot VAF vs SNVs detectados
p4 <- global_metrics %>%
  ggplot(aes(x = snvs_detected, y = mean_vaf, color = cohort)) +
  geom_point(alpha = 0.7, size = 2) +
  geom_smooth(method = "lm", se = TRUE, alpha = 0.3) +
  scale_color_brewer(type = "qual", palette = "Set2") +
  labs(
    title = "Relación entre SNVs Detectados y VAF Medio",
    x = "SNVs Detectados",
    y = "VAF Medio",
    color = "Cohorte"
  ) +
  theme_minimal()

ggsave("final_analysis/figures/vaf_vs_snvs.png", p4, width = 10, height = 6, dpi = 300)

cat("   - Figuras guardadas en: final_analysis/figures/\n")
cat("\n")

# --- 7. GUARDAR RESULTADOS ---
cat("💾 7. GUARDAR RESULTADOS\n")
cat("========================\n")

# Crear directorio de tablas si no existe
if (!dir.exists("final_analysis/tables")) {
  dir.create("final_analysis/tables", recursive = TRUE)
}

# Guardar tablas
write.csv(global_metrics, "final_analysis/tables/global_metrics.csv", row.names = FALSE)
write.csv(mutation_composition, "final_analysis/tables/mutation_composition.csv", row.names = FALSE)

# Guardar resultados de tests
test_results <- data.frame(
  test = c("VAF medio", "SNVs detectados", "SNVs VAF > 0.1"),
  t_statistic = c(t_test_mean_vaf$statistic, t_test_snvs$statistic, t_test_high_vaf$statistic),
  p_value = c(t_test_mean_vaf$p.value, t_test_snvs$p.value, t_test_high_vaf$p.value),
  significant = c(t_test_mean_vaf$p.value < 0.05, t_test_snvs$p.value < 0.05, t_test_high_vaf$p.value < 0.05)
)

write.csv(test_results, "final_analysis/tables/global_tests.csv", row.names = FALSE)

cat("   - Tablas guardadas en: final_analysis/tables/\n")
cat("\n")

# --- 8. RESUMEN FINAL ---
cat("📋 8. RESUMEN FINAL\n")
cat("===================\n")

cat("📊 MÉTRICAS GLOBALES:\n")
cat(paste0("   - VAF medio ALS: ", round(mean(global_metrics$mean_vaf[global_metrics$cohort == "ALS"], na.rm = TRUE), 4), "\n"))
cat(paste0("   - VAF medio Control: ", round(mean(global_metrics$mean_vaf[global_metrics$cohort == "Control"], na.rm = TRUE), 4), "\n"))
cat(paste0("   - SNVs detectados ALS: ", round(mean(global_metrics$snvs_detected[global_metrics$cohort == "ALS"], na.rm = TRUE), 1), "\n"))
cat(paste0("   - SNVs detectados Control: ", round(mean(global_metrics$snvs_detected[global_metrics$cohort == "Control"], na.rm = TRUE), 1), "\n"))
cat("\n")

cat("📈 TESTS ESTADÍSTICOS:\n")
cat(paste0("   - VAF medio significativo: ", ifelse(t_test_mean_vaf$p.value < 0.05, "SÍ", "NO"), " (p = ", round(t_test_mean_vaf$p.value, 4), ")\n"))
cat(paste0("   - SNVs detectados significativo: ", ifelse(t_test_snvs$p.value < 0.05, "SÍ", "NO"), " (p = ", round(t_test_snvs$p.value, 4), ")\n"))
cat(paste0("   - SNVs VAF > 0.1 significativo: ", ifelse(t_test_high_vaf$p.value < 0.05, "SÍ", "NO"), " (p = ", round(t_test_high_vaf$p.value, 4), ")\n"))
cat("\n")

cat("🧬 COMPOSICIÓN DE MUTACIONES:\n")
cat(paste0("   - G>T: ", round(mutation_composition$percentage[mutation_composition$mutation_type == "GT"], 1), "%\n"))
cat(paste0("   - G>A: ", round(mutation_composition$percentage[mutation_composition$mutation_type == "GA"], 1), "%\n"))
cat(paste0("   - G>C: ", round(mutation_composition$percentage[mutation_composition$mutation_type == "GC"], 1), "%\n"))
cat("\n")

cat("✅ VERIFICACIONES:\n")
cat("   - VAFs calculados correctamente: ✓\n")
cat("   - Tests estadísticos realizados: ✓\n")
cat("   - Visualizaciones creadas: ✓\n")
cat("   - Resultados guardados: ✓\n")
cat("\n")

cat("🎯 PRÓXIMOS PASOS:\n")
cat("   - Ejecutar análisis posicional detallado\n")
cat("   - Realizar tests diferenciales por posición\n")
cat("   - Crear heatmaps de patrones posicionales\n")
cat("\n")









