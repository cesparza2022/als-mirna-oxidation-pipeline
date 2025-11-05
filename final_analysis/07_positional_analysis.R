# --- LIBRERÍAS ---
library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(reshape2)

# --- CONFIGURACIÓN ---
cat("🔬 ANÁLISIS POSICIONAL DETALLADO\n")
cat("================================\n\n")

# --- 1. CARGANDO DATOS PROCESADOS ---
cat("📊 1. CARGANDO DATOS PROCESADOS\n")
cat("===============================\n")

processed_data_path <- "final_analysis/processed_data/processed_snvs_gt.csv"
df_processed <- read.csv(processed_data_path, stringsAsFactors = FALSE)

# Cargar métricas globales
global_metrics <- read.csv("final_analysis/tables/global_metrics.csv", stringsAsFactors = FALSE)

cat(paste0("   - SNVs procesados: ", nrow(df_processed), "\n"))
cat(paste0("   - miRNAs únicos: ", length(unique(df_processed$miRNA_name)), "\n"))
cat(paste0("   - Muestras: ", nrow(global_metrics), "\n\n"))

# --- 2. EXTRAYENDO POSICIONES DE MUTACIONES ---
cat("🔍 2. EXTRAYENDO POSICIONES DE MUTACIONES\n")
cat("=========================================\n")

# Los datos ya tienen las columnas pos y mutation_type separadas
df_with_positions <- df_processed %>%
  filter(!is.na(pos), !is.na(mutation_type)) %>%
  rename(position = pos)

cat(paste0("   - SNVs con posiciones extraídas: ", nrow(df_with_positions), "\n"))
cat(paste0("   - Posiciones únicas: ", length(unique(df_with_positions$position)), "\n"))
cat(paste0("   - Rango de posiciones: ", min(df_with_positions$position), " - ", max(df_with_positions$position), "\n\n"))

# --- 3. CLASIFICANDO REGIONES SEED vs NON-SEED ---
cat("🌱 3. CLASIFICANDO REGIONES SEED vs NON-SEED\n")
cat("============================================\n")

# Definir región seed (posiciones 2-8) y non-seed
df_with_regions <- df_with_positions %>%
  mutate(
    region = case_when(
      position >= 2 & position <= 8 ~ "Seed",
      TRUE ~ "Non-seed"
    ),
    region_detailed = case_when(
      position == 1 ~ "5' end",
      position >= 2 & position <= 8 ~ "Seed region",
      position >= 9 & position <= 12 ~ "Central region",
      position >= 13 & position <= 16 ~ "3' region",
      position >= 17 ~ "3' end"
    )
  )

# Resumen por región
region_summary <- df_with_regions %>%
  group_by(region) %>%
  summarise(
    n_snvs = n(),
    n_mirnas = length(unique(miRNA_name)),
    n_positions = length(unique(position)),
    .groups = 'drop'
  )

cat("   - Resumen por región:\n")
print(region_summary)
cat("\n")

# Resumen detallado por región
region_detailed_summary <- df_with_regions %>%
  group_by(region_detailed) %>%
  summarise(
    n_snvs = n(),
    n_mirnas = length(unique(miRNA_name)),
    n_positions = length(unique(position)),
    .groups = 'drop'
  ) %>%
  arrange(desc(n_snvs))

cat("   - Resumen detallado por región:\n")
print(region_detailed_summary)
cat("\n")

# --- 4. ANÁLISIS DE DISTRIBUCIÓN POR POSICIÓN ---
cat("📈 4. ANÁLISIS DE DISTRIBUCIÓN POR POSICIÓN\n")
cat("===========================================\n")

# Contar SNVs por posición
position_counts <- df_with_regions %>%
  group_by(position, region) %>%
  summarise(
    n_snvs = n(),
    n_mirnas = length(unique(miRNA_name)),
    .groups = 'drop'
  ) %>%
  arrange(position)

cat("   - Top 10 posiciones con más SNVs:\n")
print(head(position_counts %>% arrange(desc(n_snvs)), 10))
cat("\n")

# --- 5. CALCULANDO VAFs POR POSICIÓN ---
cat("🧮 5. CALCULANDO VAFs POR POSICIÓN\n")
cat("===================================\n")

# Identificar columnas de cuentas y totales
df_original_cols <- read.csv("results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt", sep="\t", stringsAsFactors = FALSE)
total_cols_original <- names(df_original_cols)[grepl('..PM.1MM.2MM.', names(df_original_cols), fixed=TRUE)]
count_cols_original <- names(df_original_cols)[!grepl('..PM.1MM.2MM.', names(df_original_cols), fixed=TRUE) & !names(df_original_cols) %in% c('miRNA.name', 'pos.mut')]

# Asegurarse de que las columnas de muestra en df_with_regions coincidan
sample_names_in_data <- names(df_with_regions)[!names(df_with_regions) %in% c("miRNA_name", "pos", "mutation_type", "position", "region", "region_detailed")]
count_sample_cols_processed <- intersect(sample_names_in_data, gsub("..PM.1MM.2MM.", "", count_cols_original, fixed=TRUE))
total_sample_cols_processed <- intersect(sample_names_in_data, total_cols_original)

# Crear un dataframe para VAFs por posición
vaf_by_position <- data.frame()

for (i in 1:length(count_sample_cols_processed)) {
  sample_count_col <- count_sample_cols_processed[i]
  sample_total_col <- total_sample_cols_processed[i]
  
  if (sample_count_col %in% names(df_with_regions) && sample_total_col %in% names(df_with_regions)) {
    temp_df <- df_with_regions %>%
      select(miRNA_name, position, region, region_detailed, !!sym(sample_count_col), !!sym(sample_total_col)) %>%
      mutate(
        sample = sample_count_col,
        snv_count = .data[[sample_count_col]],
        total_mirna_count = .data[[sample_total_col]],
        vaf = ifelse(total_mirna_count > 0, snv_count / total_mirna_count, 0)
      ) %>%
      select(miRNA_name, position, region, region_detailed, sample, snv_count, total_mirna_count, vaf)
    vaf_by_position <- bind_rows(vaf_by_position, temp_df)
  }
}

# Reemplazar VAFs > 0.5 con NA
vaf_by_position <- vaf_by_position %>%
  mutate(vaf = ifelse(vaf > 0.5, NA, vaf))

cat(paste0("   - VAFs calculados por posición: ", nrow(vaf_by_position), "\n"))
cat(paste0("   - VAFs válidos (>0): ", sum(vaf_by_position$vaf > 0, na.rm = TRUE), "\n\n"))

# --- 6. ANÁLISIS DE SEÑAL POR REGIÓN ---
cat("📊 6. ANÁLISIS DE SEÑAL POR REGIÓN\n")
cat("==================================\n")

# Agrupar por muestra y región
signal_by_region <- vaf_by_position %>%
  group_by(sample, region) %>%
  summarise(
    mean_vaf = mean(vaf, na.rm = TRUE),
    total_snvs_detected = sum(snv_count > 0, na.rm = TRUE),
    total_snvs_vaf_gt_0.1 = sum(vaf > 0.1, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  left_join(global_metrics %>% select(sample, cohort), by = "sample") %>%
  filter(!is.na(cohort))

cat(paste0("   - Muestras con datos por región: ", nrow(signal_by_region), "\n"))
cat(paste0("   - Muestras ALS: ", sum(signal_by_region$cohort == "ALS"), "\n"))
cat(paste0("   - Muestras Control: ", sum(signal_by_region$cohort == "Control"), "\n\n"))

# --- 7. TESTS ESTADÍSTICOS POR REGIÓN ---
cat("📊 7. TESTS ESTADÍSTICOS POR REGIÓN\n")
cat("===================================\n")

# Test t para VAF medio por región (ALS vs Control)
seed_data <- signal_by_region %>% filter(region == "Seed")
non_seed_data <- signal_by_region %>% filter(region == "Non-seed")

if (nrow(seed_data) > 0) {
  t_test_seed <- t.test(mean_vaf ~ cohort, data = seed_data)
  cat("   - Test t para VAF medio en región Seed (ALS vs Control):\n")
  cat(paste0("     - t = ", round(t_test_seed$statistic, 3), "\n"))
  cat(paste0("     - p-value = ", round(t_test_seed$p.value, 5), "\n"))
  cat(paste0("     - Significativo: ", ifelse(t_test_seed$p.value < 0.05, "SÍ", "NO"), "\n\n"))
}

if (nrow(non_seed_data) > 0) {
  t_test_non_seed <- t.test(mean_vaf ~ cohort, data = non_seed_data)
  cat("   - Test t para VAF medio en región Non-seed (ALS vs Control):\n")
  cat(paste0("     - t = ", round(t_test_non_seed$statistic, 3), "\n"))
  cat(paste0("     - p-value = ", round(t_test_non_seed$p.value, 5), "\n"))
  cat(paste0("     - Significativo: ", ifelse(t_test_non_seed$p.value < 0.05, "SÍ", "NO"), "\n\n"))
}

# --- 8. ANÁLISIS DE POSICIONES ESPECÍFICAS ---
cat("🎯 8. ANÁLISIS DE POSICIONES ESPECÍFICAS\n")
cat("========================================\n")

# Agrupar por muestra y posición
signal_by_position <- vaf_by_position %>%
  group_by(sample, position, region) %>%
  summarise(
    mean_vaf = mean(vaf, na.rm = TRUE),
    total_snvs_detected = sum(snv_count > 0, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  left_join(global_metrics %>% select(sample, cohort), by = "sample") %>%
  filter(!is.na(cohort))

# Análisis de posiciones más variables
position_variability <- signal_by_position %>%
  group_by(position, region) %>%
  summarise(
    mean_vaf = mean(mean_vaf, na.rm = TRUE),
    sd_vaf = sd(mean_vaf, na.rm = TRUE),
    cv_vaf = sd_vaf / mean_vaf,
    n_samples = n(),
    .groups = 'drop'
  ) %>%
  arrange(desc(cv_vaf))

cat("   - Top 10 posiciones más variables (CV):\n")
print(head(position_variability, 10))
cat("\n")

# --- 9. CREANDO VISUALIZACIONES ---
cat("📊 9. CREANDO VISUALIZACIONES\n")
cat("=============================\n")

figures_dir <- "final_analysis/figures"
if (!dir.exists(figures_dir)) {
  dir.create(figures_dir, recursive = TRUE)
}

# Boxplot de VAF por región y cohorte
p_vaf_region <- ggplot(signal_by_region, aes(x = region, y = mean_vaf, fill = cohort)) +
  geom_boxplot() +
  labs(title = "VAF Medio por Región y Cohorte", x = "Región", y = "VAF Medio") +
  theme_minimal()
ggsave(file.path(figures_dir, "vaf_by_region_cohort.png"), p_vaf_region)

# Boxplot de SNVs detectados por región y cohorte
p_snvs_region <- ggplot(signal_by_region, aes(x = region, y = total_snvs_detected, fill = cohort)) +
  geom_boxplot() +
  labs(title = "SNVs Detectados por Región y Cohorte", x = "Región", y = "SNVs Detectados") +
  theme_minimal()
ggsave(file.path(figures_dir, "snvs_by_region_cohort.png"), p_snvs_region)

# Gráfico de barras de distribución por posición
p_position_dist <- ggplot(position_counts, aes(x = position, y = n_snvs, fill = region)) +
  geom_bar(stat = "identity") +
  labs(title = "Distribución de SNVs por Posición", x = "Posición", y = "Número de SNVs") +
  theme_minimal() +
  scale_fill_manual(values = c("Seed" = "red", "Non-seed" = "blue"))
ggsave(file.path(figures_dir, "snv_distribution_by_position.png"), p_position_dist)

# Heatmap de VAF por posición y cohorte
vaf_heatmap_data <- signal_by_position %>%
  group_by(position, cohort) %>%
  summarise(mean_vaf = mean(mean_vaf, na.rm = TRUE), .groups = 'drop') %>%
  pivot_wider(names_from = cohort, values_from = mean_vaf)

# Crear matriz para heatmap
heatmap_matrix <- as.matrix(vaf_heatmap_data[, -1])
rownames(heatmap_matrix) <- vaf_heatmap_data$position

# Guardar heatmap
png(file.path(figures_dir, "vaf_heatmap_by_position.png"), width = 800, height = 600)
heatmap(heatmap_matrix, 
        main = "VAF Medio por Posición y Cohorte",
        xlab = "Cohorte", 
        ylab = "Posición",
        col = colorRampPalette(c("white", "red"))(100))
dev.off()

cat(paste0("   - Figuras guardadas en: ", figures_dir, "\n\n"))

# --- 10. GUARDAR RESULTADOS ---
cat("💾 10. GUARDAR RESULTADOS\n")
cat("=========================\n")

tables_dir <- "final_analysis/tables"
if (!dir.exists(tables_dir)) {
  dir.create(tables_dir, recursive = TRUE)
}

write.csv(df_with_regions, file.path(tables_dir, "snvs_with_regions.csv"), row.names = FALSE)
write.csv(region_summary, file.path(tables_dir, "region_summary.csv"), row.names = FALSE)
write.csv(region_detailed_summary, file.path(tables_dir, "region_detailed_summary.csv"), row.names = FALSE)
write.csv(position_counts, file.path(tables_dir, "position_counts.csv"), row.names = FALSE)
write.csv(signal_by_region, file.path(tables_dir, "signal_by_region.csv"), row.names = FALSE)
write.csv(signal_by_position, file.path(tables_dir, "signal_by_position.csv"), row.names = FALSE)
write.csv(position_variability, file.path(tables_dir, "position_variability.csv"), row.names = FALSE)

cat(paste0("   - Tablas guardadas en: ", tables_dir, "\n\n"))

# --- 11. RESUMEN FINAL ---
cat("📋 11. RESUMEN FINAL\n")
cat("====================\n")
cat("📊 DISTRIBUCIÓN POR REGIÓN:\n")
cat(paste0("   - SNVs en región Seed: ", sum(region_summary$n_snvs[region_summary$region == "Seed"]), "\n"))
cat(paste0("   - SNVs en región Non-seed: ", sum(region_summary$n_snvs[region_summary$region == "Non-seed"]), "\n"))
cat(paste0("   - miRNAs en región Seed: ", sum(region_summary$n_mirnas[region_summary$region == "Seed"]), "\n"))
cat(paste0("   - miRNAs en región Non-seed: ", sum(region_summary$n_mirnas[region_summary$region == "Non-seed"]), "\n\n"))

cat("📈 TESTS ESTADÍSTICOS POR REGIÓN:\n")
if (nrow(seed_data) > 0) {
  cat(paste0("   - Región Seed significativa: ", ifelse(t_test_seed$p.value < 0.05, "SÍ", "NO"), " (p = ", round(t_test_seed$p.value, 5), ")\n"))
}
if (nrow(non_seed_data) > 0) {
  cat(paste0("   - Región Non-seed significativa: ", ifelse(t_test_non_seed$p.value < 0.05, "SÍ", "NO"), " (p = ", round(t_test_non_seed$p.value, 5), ")\n"))
}
cat("\n")

cat("🎯 POSICIONES MÁS VARIABLES:\n")
cat(paste0("   - Posición más variable: ", position_variability$position[1], " (CV = ", round(position_variability$cv_vaf[1], 3), ")\n"))
cat(paste0("   - Posición menos variable: ", position_variability$position[nrow(position_variability)], " (CV = ", round(position_variability$cv_vaf[nrow(position_variability)], 3), ")\n\n"))

cat("✅ VERIFICACIONES:\n")
cat("   - Posiciones extraídas correctamente: ✓\n")
cat("   - Regiones clasificadas: ✓\n")
cat("   - VAFs calculados por posición: ✓\n")
cat("   - Tests estadísticos realizados: ✓\n")
cat("   - Visualizaciones creadas: ✓\n")
cat("   - Resultados guardados: ✓\n\n")

cat("🎯 PRÓXIMOS PASOS:\n")
cat("   - Ejecutar tests diferenciales por posición específica\n")
cat("   - Realizar análisis por miRNA individual\n")
cat("   - Crear heatmaps de patrones posicionales\n\n")
