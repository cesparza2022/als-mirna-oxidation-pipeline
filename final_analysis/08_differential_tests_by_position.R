# --- LIBRERÍAS ---
library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(reshape2)

# --- CONFIGURACIÓN ---
cat("🔬 TESTS DIFERENCIALES POR POSICIÓN ESPECÍFICA\n")
cat("==============================================\n\n")

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

# --- 2. PREPARANDO DATOS CON POSICIONES ---
cat("🔍 2. PREPARANDO DATOS CON POSICIONES\n")
cat("=====================================\n")

# Los datos ya tienen las columnas pos y mutation_type separadas
df_with_positions <- df_processed %>%
  filter(!is.na(pos), !is.na(mutation_type)) %>%
  rename(position = pos)

# Clasificar por región seed (posiciones 2-8)
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
      position >= 13 & position <= 18 ~ "3' region",
      position >= 19 ~ "3' end"
    )
  )

cat(paste0("   - SNVs con posiciones: ", nrow(df_with_positions), "\n"))
cat(paste0("   - Posiciones únicas: ", length(unique(df_with_positions$position)), "\n"))
cat(paste0("   - Rango de posiciones: ", min(df_with_positions$position), " - ", max(df_with_positions$position), "\n\n"))

# --- 3. CARGANDO METADATOS DE MUESTRAS ---
cat("📋 3. CARGANDO METADATOS DE MUESTRAS\n")
cat("====================================\n")

# Cargar metadatos de muestras
sample_metadata <- read.csv("final_analysis/tables/sample_metadata.csv", stringsAsFactors = FALSE)

# Identificar columnas de cuentas y totales
df_original_cols <- read.csv("results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt", sep="\t", stringsAsFactors = FALSE)
total_cols_original <- names(df_original_cols)[grepl('..PM.1MM.2MM.', names(df_original_cols), fixed=TRUE)]
count_cols_original <- names(df_original_cols)[!grepl('..PM.1MM.2MM.', names(df_original_cols), fixed=TRUE) & !names(df_original_cols) %in% c('miRNA.name', 'pos.mut')]

# Asegurarse de que las columnas de muestra en df_with_regions coincidan
sample_names_in_data <- names(df_with_regions)[!names(df_with_regions) %in% c("miRNA_name", "pos", "mutation_type", "position", "region", "region_detailed")]
count_sample_cols_processed <- intersect(sample_names_in_data, gsub("..PM.1MM.2MM.", "", count_cols_original, fixed=TRUE))
total_sample_cols_processed <- intersect(sample_names_in_data, total_cols_original)

cat(paste0("   - Muestras con datos: ", length(count_sample_cols_processed), "\n"))
cat(paste0("   - Muestras ALS: ", sum(sample_metadata$cohort == "ALS"), "\n"))
cat(paste0("   - Muestras Control: ", sum(sample_metadata$cohort == "Control"), "\n\n"))

# --- 4. CALCULANDO VAFs POR POSICIÓN Y MUESTRA ---
cat("🧮 4. CALCULANDO VAFs POR POSICIÓN Y MUESTRA\n")
cat("============================================\n")

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

# Agregar metadatos de cohorte
vaf_by_position <- vaf_by_position %>%
  left_join(sample_metadata, by = "sample") %>%
  filter(!is.na(cohort))

cat(paste0("   - VAFs calculados: ", nrow(vaf_by_position), "\n"))
cat(paste0("   - VAFs válidos (>0): ", sum(vaf_by_position$vaf > 0, na.rm = TRUE), "\n"))
cat(paste0("   - VAFs > 0.5 (convertidos a NA): ", sum(vaf_by_position$vaf > 0.5, na.rm = TRUE), "\n\n"))

# --- 5. TESTS DIFERENCIALES POR POSICIÓN ---
cat("📊 5. TESTS DIFERENCIALES POR POSICIÓN\n")
cat("======================================\n")

# Calcular métricas por posición y muestra
position_metrics <- vaf_by_position %>%
  group_by(sample, position, region, region_detailed) %>%
  summarise(
    mean_vaf = mean(vaf, na.rm = TRUE),
    total_snvs = sum(snv_count > 0, na.rm = TRUE),
    high_vaf_snvs = sum(vaf > 0.1, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  left_join(sample_metadata, by = "sample") %>%
  filter(!is.na(cohort))

# Tests por posición individual
position_tests <- data.frame()

for (pos in unique(position_metrics$position)) {
  pos_data <- position_metrics %>% filter(position == pos)
  
  if (nrow(pos_data) > 0 && length(unique(pos_data$cohort)) == 2) {
    # Test t para VAF medio
    t_test_vaf <- tryCatch({
      t.test(mean_vaf ~ cohort, data = pos_data)
    }, error = function(e) {
      list(statistic = NA, p.value = NA)
    })
    
    # Test t para SNVs detectados
    t_test_snvs <- tryCatch({
      t.test(total_snvs ~ cohort, data = pos_data)
    }, error = function(e) {
      list(statistic = NA, p.value = NA)
    })
    
    # Test t para SNVs con VAF > 0.1
    t_test_high_vaf <- tryCatch({
      t.test(high_vaf_snvs ~ cohort, data = pos_data)
    }, error = function(e) {
      list(statistic = NA, p.value = NA)
    })
    
    # Calcular medias por cohorte
    means_by_cohort <- pos_data %>%
      group_by(cohort) %>%
      summarise(
        mean_vaf = mean(mean_vaf, na.rm = TRUE),
        mean_snvs = mean(total_snvs, na.rm = TRUE),
        mean_high_vaf_snvs = mean(high_vaf_snvs, na.rm = TRUE),
        n_samples = n(),
        .groups = 'drop'
      )
    
    # Crear fila de resultados
    result_row <- data.frame(
      position = pos,
      region = unique(pos_data$region),
      region_detailed = unique(pos_data$region_detailed),
      n_samples_als = means_by_cohort$n_samples[means_by_cohort$cohort == "ALS"],
      n_samples_control = means_by_cohort$n_samples[means_by_cohort$cohort == "Control"],
      mean_vaf_als = means_by_cohort$mean_vaf[means_by_cohort$cohort == "ALS"],
      mean_vaf_control = means_by_cohort$mean_vaf[means_by_cohort$cohort == "Control"],
      mean_snvs_als = means_by_cohort$mean_snvs[means_by_cohort$cohort == "ALS"],
      mean_snvs_control = means_by_cohort$mean_snvs[means_by_cohort$cohort == "Control"],
      mean_high_vaf_snvs_als = means_by_cohort$mean_high_vaf_snvs[means_by_cohort$cohort == "ALS"],
      mean_high_vaf_snvs_control = means_by_cohort$mean_high_vaf_snvs[means_by_cohort$cohort == "Control"],
      t_stat_vaf = ifelse(is.na(t_test_vaf$statistic), NA, t_test_vaf$statistic),
      p_value_vaf = ifelse(is.na(t_test_vaf$p.value), NA, t_test_vaf$p.value),
      t_stat_snvs = ifelse(is.na(t_test_snvs$statistic), NA, t_test_snvs$statistic),
      p_value_snvs = ifelse(is.na(t_test_snvs$p.value), NA, t_test_snvs$p.value),
      t_stat_high_vaf = ifelse(is.na(t_test_high_vaf$statistic), NA, t_test_high_vaf$statistic),
      p_value_high_vaf = ifelse(is.na(t_test_high_vaf$p.value), NA, t_test_high_vaf$p.value)
    )
    
    position_tests <- bind_rows(position_tests, result_row)
  }
}

# Aplicar corrección de FDR
position_tests <- position_tests %>%
  mutate(
    p_value_vaf_fdr = p.adjust(p_value_vaf, method = "fdr"),
    p_value_snvs_fdr = p.adjust(p_value_snvs, method = "fdr"),
    p_value_high_vaf_fdr = p.adjust(p_value_high_vaf, method = "fdr"),
    significant_vaf = p_value_vaf_fdr < 0.05,
    significant_snvs = p_value_snvs_fdr < 0.05,
    significant_high_vaf = p_value_high_vaf_fdr < 0.05
  )

cat(paste0("   - Posiciones analizadas: ", nrow(position_tests), "\n"))
cat(paste0("   - Posiciones significativas (VAF): ", sum(position_tests$significant_vaf, na.rm = TRUE), "\n"))
cat(paste0("   - Posiciones significativas (SNVs): ", sum(position_tests$significant_snvs, na.rm = TRUE), "\n"))
cat(paste0("   - Posiciones significativas (High VAF): ", sum(position_tests$significant_high_vaf, na.rm = TRUE), "\n\n"))

# --- 6. ANÁLISIS DE POSICIONES SIGNIFICATIVAS ---
cat("🎯 6. ANÁLISIS DE POSICIONES SIGNIFICATIVAS\n")
cat("===========================================\n")

# Posiciones significativas por VAF
significant_vaf_positions <- position_tests %>%
  filter(significant_vaf) %>%
  arrange(p_value_vaf_fdr)

cat("   - Posiciones significativas por VAF (FDR < 0.05):\n")
if (nrow(significant_vaf_positions) > 0) {
  print(significant_vaf_positions %>% select(position, region, mean_vaf_als, mean_vaf_control, p_value_vaf_fdr))
} else {
  cat("     Ninguna posición significativa por VAF\n")
}
cat("\n")

# Posiciones significativas por SNVs detectados
significant_snvs_positions <- position_tests %>%
  filter(significant_snvs) %>%
  arrange(p_value_snvs_fdr)

cat("   - Posiciones significativas por SNVs detectados (FDR < 0.05):\n")
if (nrow(significant_snvs_positions) > 0) {
  print(significant_snvs_positions %>% select(position, region, mean_snvs_als, mean_snvs_control, p_value_snvs_fdr))
} else {
  cat("     Ninguna posición significativa por SNVs detectados\n")
}
cat("\n")

# --- 7. ANÁLISIS POR REGIÓN DETALLADA ---
cat("🌱 7. ANÁLISIS POR REGIÓN DETALLADA\n")
cat("===================================\n")

# Tests por región detallada
region_tests <- position_metrics %>%
  group_by(sample, region_detailed) %>%
  summarise(
    mean_vaf = mean(mean_vaf, na.rm = TRUE),
    total_snvs = sum(total_snvs, na.rm = TRUE),
    high_vaf_snvs = sum(high_vaf_snvs, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  left_join(sample_metadata, by = "sample") %>%
  filter(!is.na(cohort))

region_summary <- region_tests %>%
  group_by(region_detailed, cohort) %>%
  summarise(
    n_samples = n(),
    mean_vaf = mean(mean_vaf, na.rm = TRUE),
    mean_snvs = mean(total_snvs, na.rm = TRUE),
    mean_high_vaf_snvs = mean(high_vaf_snvs, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  pivot_wider(names_from = cohort, values_from = c(n_samples, mean_vaf, mean_snvs, mean_high_vaf_snvs))

cat("   - Resumen por región detallada:\n")
print(region_summary)
cat("\n")

# --- 8. CREANDO VISUALIZACIONES ---
cat("📊 8. CREANDO VISUALIZACIONES\n")
cat("=============================\n")

figures_dir <- "final_analysis/figures"
if (!dir.exists(figures_dir)) {
  dir.create(figures_dir, recursive = TRUE)
}

# Gráfico de p-values por posición
p_values_long <- position_tests %>%
  select(position, region, p_value_vaf, p_value_snvs, p_value_high_vaf) %>%
  pivot_longer(cols = c(p_value_vaf, p_value_snvs, p_value_high_vaf), 
               names_to = "test_type", values_to = "p_value") %>%
  mutate(test_type = case_when(
    test_type == "p_value_vaf" ~ "VAF",
    test_type == "p_value_snvs" ~ "SNVs Detected",
    test_type == "p_value_high_vaf" ~ "High VAF SNVs"
  ))

p_pvalues <- ggplot(p_values_long, aes(x = position, y = -log10(p_value), color = test_type)) +
  geom_point(alpha = 0.7) +
  geom_hline(yintercept = -log10(0.05), linetype = "dashed", color = "red") +
  facet_wrap(~test_type, scales = "free_y") +
  labs(title = "P-values por Posición", x = "Posición", y = "-log10(p-value)") +
  theme_minimal() +
  theme(legend.position = "none")
ggsave(file.path(figures_dir, "pvalues_by_position.png"), p_pvalues, width = 10, height = 6)

# Gráfico de diferencias de medias por posición
differences_long <- position_tests %>%
  select(position, region, mean_vaf_als, mean_vaf_control, mean_snvs_als, mean_snvs_control) %>%
  mutate(
    vaf_diff = mean_vaf_als - mean_vaf_control,
    snvs_diff = mean_snvs_als - mean_snvs_control
  ) %>%
  pivot_longer(cols = c(vaf_diff, snvs_diff), 
               names_to = "metric", values_to = "difference") %>%
  mutate(metric = case_when(
    metric == "vaf_diff" ~ "VAF Difference",
    metric == "snvs_diff" ~ "SNVs Difference"
  ))

p_differences <- ggplot(differences_long, aes(x = position, y = difference, color = region)) +
  geom_point(alpha = 0.7) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "black") +
  facet_wrap(~metric, scales = "free_y") +
  labs(title = "Diferencias de Medias por Posición (ALS - Control)", 
       x = "Posición", y = "Diferencia") +
  theme_minimal()
ggsave(file.path(figures_dir, "differences_by_position.png"), p_differences, width = 10, height = 6)

cat(paste0("   - Figuras guardadas en: ", figures_dir, "\n\n"))

# --- 9. GUARDAR RESULTADOS ---
cat("💾 9. GUARDAR RESULTADOS\n")
cat("========================\n")

tables_dir <- "final_analysis/tables"
if (!dir.exists(tables_dir)) {
  dir.create(tables_dir, recursive = TRUE)
}

write.csv(position_tests, file.path(tables_dir, "differential_tests_by_position.csv"), row.names = FALSE)
write.csv(region_summary, file.path(tables_dir, "region_summary.csv"), row.names = FALSE)
write.csv(position_metrics, file.path(tables_dir, "position_metrics.csv"), row.names = FALSE)

cat(paste0("   - Tablas guardadas en: ", tables_dir, "\n\n"))

# --- 10. RESUMEN FINAL ---
cat("📋 10. RESUMEN FINAL\n")
cat("====================\n")

cat("📊 TESTS DIFERENCIALES POR POSICIÓN:\n")
cat(paste0("   - Posiciones analizadas: ", nrow(position_tests), "\n"))
cat(paste0("   - Posiciones significativas (VAF): ", sum(position_tests$significant_vaf, na.rm = TRUE), "\n"))
cat(paste0("   - Posiciones significativas (SNVs): ", sum(position_tests$significant_snvs, na.rm = TRUE), "\n"))
cat(paste0("   - Posiciones significativas (High VAF): ", sum(position_tests$significant_high_vaf, na.rm = TRUE), "\n\n"))

cat("🎯 POSICIONES MÁS SIGNIFICATIVAS:\n")
if (nrow(significant_vaf_positions) > 0) {
  cat("   - VAF: Posiciones", paste(head(significant_vaf_positions$position, 5), collapse = ", "), "\n")
}
if (nrow(significant_snvs_positions) > 0) {
  cat("   - SNVs: Posiciones", paste(head(significant_snvs_positions$position, 5), collapse = ", "), "\n")
}
cat("\n")

cat("✅ VERIFICACIONES:\n")
cat("   - Tests diferenciales por posición: ✓\n")
cat("   - Corrección FDR aplicada: ✓\n")
cat("   - Análisis por región detallada: ✓\n")
cat("   - Visualizaciones creadas: ✓\n")
cat("   - Resultados guardados: ✓\n\n")

cat("🎯 PRÓXIMOS PASOS:\n")
cat("   - Ejecutar análisis por miRNA individual\n")
cat("   - Crear heatmaps de patrones posicionales\n")
cat("   - Realizar análisis de clustering\n\n")
