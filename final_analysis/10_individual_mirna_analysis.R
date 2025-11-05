# --- LIBRERÍAS ---
library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(reshape2)
library(stats) # Para p.adjust

# --- CONFIGURACIÓN ---
cat("🔬 ANÁLISIS POR miRNA INDIVIDUAL\n")
cat("================================\n\n")

# --- 1. CARGANDO DATOS PROCESADOS ---
cat("📊 1. CARGANDO DATOS PROCESADOS\n")
cat("===============================\n")

processed_data_path <- "final_analysis/processed_data/processed_snvs_gt.csv"
df_processed <- read.csv(processed_data_path, stringsAsFactors = FALSE)

# Cargar métricas globales
global_metrics <- read.csv("final_analysis/tables/global_metrics.csv", stringsAsFactors = FALSE)

# Cargar metadatos de muestras
sample_metadata <- read.csv("final_analysis/tables/sample_metadata.csv", stringsAsFactors = FALSE)

cat(paste0("   - SNVs procesados: ", nrow(df_processed), "\n"))
cat(paste0("   - miRNAs únicos: ", length(unique(df_processed$miRNA_name)), "\n"))
cat(paste0("   - Muestras: ", nrow(global_metrics), "\n\n"))

# --- 2. PREPARANDO DATOS CON POSICIONES ---
cat("🔍 2. PREPARANDO DATOS CON POSICIONES\n")
cat("=====================================\n")

df_with_positions <- df_processed %>%
  filter(!is.na(pos), !is.na(mutation_type)) %>%
  rename(position = pos) %>%
  mutate(
    region = ifelse(position >= 2 & position <= 8, "Seed", "Non-seed"),
    region_detailed = case_when(
      position >= 2 & position <= 8 ~ "Seed region",
      position >= 1 & position <= 1 ~ "5' end",
      position >= 9 & position <= 12 ~ "Central region",
      position >= 13 & position <= 16 ~ "3' region",
      position >= 17 & position <= 23 ~ "3' end",
      TRUE ~ "Unknown"
    )
  )

cat(paste0("   - SNVs con posiciones: ", nrow(df_with_positions), "\n"))
cat(paste0("   - miRNAs únicos: ", length(unique(df_with_positions$miRNA_name)), "\n"))
cat(paste0("   - Posiciones únicas: ", length(unique(df_with_positions$position)), "\n\n"))

# --- 3. CALCULANDO VAFs POR miRNA Y MUESTRA ---
cat("🧮 3. CALCULANDO VAFs POR miRNA Y MUESTRA\n")
cat("=========================================\n")

# Cargar las columnas originales para el cálculo de VAF
df_original_cols <- read.csv("results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt", sep="\t", stringsAsFactors = FALSE)
total_cols_original <- names(df_original_cols)[grepl('..PM.1MM.2MM.', names(df_original_cols), fixed=TRUE)]
count_cols_original <- names(df_original_cols)[!grepl('..PM.1MM.2MM.', names(df_original_cols), fixed=TRUE) & !names(df_original_cols) %in% c('miRNA.name', 'pos.mut')]

sample_names_in_data <- names(df_with_positions)[!names(df_with_positions) %in% c("miRNA_name", "pos", "mutation_type", "position", "region", "region_detailed")]
count_sample_cols_processed <- intersect(sample_names_in_data, gsub("..PM.1MM.2MM.", "", count_cols_original, fixed=TRUE))
total_sample_cols_processed <- intersect(sample_names_in_data, total_cols_original)

vaf_by_mirna <- data.frame()

for (i in 1:length(count_sample_cols_processed)) {
  sample_count_col <- count_sample_cols_processed[i]
  sample_total_col <- total_sample_cols_processed[i]

  if (sample_count_col %in% names(df_with_positions) && sample_total_col %in% names(df_with_positions)) {
    temp_df <- df_with_positions %>%
      select(miRNA_name, position, region, region_detailed, !!sym(sample_count_col), !!sym(sample_total_col)) %>%
      mutate(
        sample = sample_count_col,
        snv_count = .data[[sample_count_col]],
        total_mirna_count = .data[[sample_total_col]],
        vaf = ifelse(total_mirna_count > 0, snv_count / total_mirna_count, 0)
      ) %>%
      select(miRNA_name, position, region, region_detailed, sample, snv_count, total_mirna_count, vaf)
    vaf_by_mirna <- bind_rows(vaf_by_mirna, temp_df)
  }
}

# Reemplazar VAFs > 0.5 con NA
vaf_by_mirna <- vaf_by_mirna %>%
  mutate(vaf = ifelse(vaf > 0.5, NA, vaf))

# Agregar metadatos de cohorte
vaf_by_mirna <- vaf_by_mirna %>%
  left_join(sample_metadata, by = "sample") %>%
  filter(!is.na(cohort))

cat(paste0("   - VAFs calculados: ", nrow(vaf_by_mirna), "\n"))
cat(paste0("   - VAFs válidos (>0): ", sum(vaf_by_mirna$vaf > 0, na.rm = TRUE), "\n"))
cat(paste0("   - VAFs > 0.5 (convertidos a NA): ", sum(vaf_by_mirna$vaf > 0.5, na.rm = TRUE), "\n\n"))

# --- 4. ANÁLISIS POR miRNA INDIVIDUAL ---
cat("📊 4. ANÁLISIS POR miRNA INDIVIDUAL\n")
cat("===================================\n")

# Resumen por miRNA
mirna_summary <- vaf_by_mirna %>%
  group_by(miRNA_name) %>%
  summarise(
    n_snvs = n(),
    n_positions = length(unique(position)),
    n_samples = length(unique(sample)),
    mean_vaf = mean(vaf, na.rm = TRUE),
    median_vaf = median(vaf, na.rm = TRUE),
    sd_vaf = sd(vaf, na.rm = TRUE),
    n_seed_snvs = sum(region == "Seed", na.rm = TRUE),
    n_non_seed_snvs = sum(region == "Non-seed", na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  arrange(desc(n_snvs))

cat("   - Top 10 miRNAs con más SNVs:\n")
print(head(mirna_summary, 10))
cat("\n")

# --- 5. TESTS DIFERENCIALES POR miRNA ---
cat("📊 5. TESTS DIFERENCIALES POR miRNA\n")
cat("===================================\n")

unique_mirnas <- unique(vaf_by_mirna$miRNA_name)
mirna_test_results <- data.frame()

for (mirna in unique_mirnas) {
  mirna_data <- vaf_by_mirna %>% filter(miRNA_name == mirna)
  
  # Asegurarse de que haya al menos dos grupos en la cohorte para el t-test
  if (length(unique(mirna_data$cohort)) < 2 || sum(mirna_data$cohort == "ALS") < 2 || sum(mirna_data$cohort == "Control") < 2) {
    next
  }
  
  # Test t para VAF medio
  t_test_vaf <- tryCatch({
    t.test(vaf ~ cohort, data = mirna_data)
  }, error = function(e) {
    list(p.value = NA, statistic = NA, estimate = c(NA, NA))
  })
  
  # Test t para número de SNVs detectados
  snv_counts <- mirna_data %>%
    group_by(sample, cohort) %>%
    summarise(n_snvs = n(), .groups = 'drop')
  
  t_test_snvs <- tryCatch({
    t.test(n_snvs ~ cohort, data = snv_counts)
  }, error = function(e) {
    list(p.value = NA, statistic = NA, estimate = c(NA, NA))
  })
  
  # Resumen por miRNA
  mirna_stats <- mirna_data %>%
    group_by(cohort) %>%
    summarise(
      mean_vaf = mean(vaf, na.rm = TRUE),
      median_vaf = median(vaf, na.rm = TRUE),
      n_snvs = n(),
      n_positions = length(unique(position)),
      .groups = 'drop'
    )
  
  # Crear fila de resultados
  result_row <- data.frame(
    miRNA_name = mirna,
    n_snvs_total = nrow(mirna_data),
    n_positions = length(unique(mirna_data$position)),
    n_samples = length(unique(mirna_data$sample)),
    mean_vaf_als = mirna_stats$mean_vaf[mirna_stats$cohort == "ALS"],
    mean_vaf_control = mirna_stats$mean_vaf[mirna_stats$cohort == "Control"],
    n_snvs_als = mirna_stats$n_snvs[mirna_stats$cohort == "ALS"],
    n_snvs_control = mirna_stats$n_snvs[mirna_stats$cohort == "Control"],
    t_statistic_vaf = t_test_vaf$statistic,
    p_value_vaf = t_test_vaf$p.value,
    t_statistic_snvs = t_test_snvs$statistic,
    p_value_snvs = t_test_snvs$p.value,
    stringsAsFactors = FALSE
  )
  
  mirna_test_results <- bind_rows(mirna_test_results, result_row)
}

# Aplicar corrección FDR
mirna_test_results <- mirna_test_results %>%
  mutate(
    fdr_vaf = p.adjust(p_value_vaf, method = "fdr"),
    fdr_snvs = p.adjust(p_value_snvs, method = "fdr"),
    significant_vaf = fdr_vaf < 0.05,
    significant_snvs = fdr_snvs < 0.05
  ) %>%
  arrange(desc(n_snvs_total))

cat(paste0("   - miRNAs analizados: ", nrow(mirna_test_results), "\n"))
cat(paste0("   - miRNAs significativos en VAF: ", sum(mirna_test_results$significant_vaf, na.rm = TRUE), "\n"))
cat(paste0("   - miRNAs significativos en SNVs: ", sum(mirna_test_results$significant_snvs, na.rm = TRUE), "\n\n"))

# --- 6. ANÁLISIS DE PATRONES POSICIONALES POR miRNA ---
cat("🎯 6. ANÁLISIS DE PATRONES POSICIONALES POR miRNA\n")
cat("================================================\n")

# Análisis de distribución por posición para cada miRNA
positional_patterns <- vaf_by_mirna %>%
  group_by(miRNA_name, position, region) %>%
  summarise(
    mean_vaf = mean(vaf, na.rm = TRUE),
    median_vaf = median(vaf, na.rm = TRUE),
    n_snvs = n(),
    n_samples = length(unique(sample)),
    .groups = 'drop'
  ) %>%
  arrange(miRNA_name, position)

# Identificar miRNAs con patrones posicionales interesantes
interesting_mirnas <- mirna_test_results %>%
  filter(significant_vaf | significant_snvs) %>%
  arrange(desc(n_snvs_total)) %>%
  head(10)

cat("   - Top 10 miRNAs con patrones interesantes:\n")
print(interesting_mirnas[, c("miRNA_name", "n_snvs_total", "mean_vaf_als", "mean_vaf_control", "significant_vaf", "significant_snvs")])
cat("\n")

# --- 7. ANÁLISIS DE REGIÓN SEED vs NON-SEED POR miRNA ---
cat("🌱 7. ANÁLISIS DE REGIÓN SEED vs NON-SEED POR miRNA\n")
cat("==================================================\n")

# Análisis simplificado por región - separar Seed y Non-seed
seed_data <- vaf_by_mirna %>%
  filter(region == "Seed") %>%
  group_by(miRNA_name, cohort) %>%
  summarise(
    mean_vaf = mean(vaf, na.rm = TRUE),
    n_snvs = n(),
    .groups = 'drop'
  ) %>%
  pivot_wider(names_from = cohort, values_from = c(mean_vaf, n_snvs), names_sep = "_") %>%
  mutate(
    seed_vaf_ratio = ifelse(!is.na(mean_vaf_ALS) & !is.na(mean_vaf_Control) & mean_vaf_Control > 0, 
                           mean_vaf_ALS / mean_vaf_Control, NA),
    seed_snv_ratio = ifelse(!is.na(n_snvs_ALS) & !is.na(n_snvs_Control) & n_snvs_Control > 0, 
                           n_snvs_ALS / n_snvs_Control, NA)
  ) %>%
  arrange(desc(seed_vaf_ratio))

non_seed_data <- vaf_by_mirna %>%
  filter(region == "Non-seed") %>%
  group_by(miRNA_name, cohort) %>%
  summarise(
    mean_vaf = mean(vaf, na.rm = TRUE),
    n_snvs = n(),
    .groups = 'drop'
  ) %>%
  pivot_wider(names_from = cohort, values_from = c(mean_vaf, n_snvs), names_sep = "_") %>%
  mutate(
    non_seed_vaf_ratio = ifelse(!is.na(mean_vaf_ALS) & !is.na(mean_vaf_Control) & mean_vaf_Control > 0, 
                               mean_vaf_ALS / mean_vaf_Control, NA),
    non_seed_snv_ratio = ifelse(!is.na(n_snvs_ALS) & !is.na(n_snvs_Control) & n_snvs_Control > 0, 
                               n_snvs_ALS / n_snvs_Control, NA)
  ) %>%
  arrange(desc(non_seed_vaf_ratio))

# Combinar resultados
seed_analysis_simple <- seed_data %>%
  left_join(non_seed_data %>% select(miRNA_name, non_seed_vaf_ratio, non_seed_snv_ratio), by = "miRNA_name") %>%
  arrange(desc(seed_vaf_ratio))

cat("   - Top 10 miRNAs con mayor ratio VAF en región Seed (ALS/Control):\n")
print(head(seed_analysis_simple[, c("miRNA_name", "seed_vaf_ratio", "non_seed_vaf_ratio", "seed_snv_ratio", "non_seed_snv_ratio")], 10))
cat("\n")

# --- 8. CREANDO VISUALIZACIONES ---
cat("📊 8. CREANDO VISUALIZACIONES\n")
cat("=============================\n")

figures_dir <- "final_analysis/figures"
if (!dir.exists(figures_dir)) {
  dir.create(figures_dir, recursive = TRUE)
}

# Boxplot de VAF por miRNA (top 20)
top_mirnas <- head(mirna_summary$miRNA_name, 20)
vaf_top_mirnas <- vaf_by_mirna %>% filter(miRNA_name %in% top_mirnas)

p_vaf_by_mirna <- ggplot(vaf_top_mirnas, aes(x = reorder(miRNA_name, vaf, median), y = vaf, fill = cohort)) +
  geom_boxplot() +
  labs(title = "VAF por miRNA (Top 20)", x = "miRNA", y = "VAF") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
ggsave(file.path(figures_dir, "vaf_by_mirna_boxplot.png"), p_vaf_by_mirna, width = 12, height = 8)

# Heatmap de VAF por miRNA y posición
vaf_heatmap_data <- vaf_by_mirna %>%
  group_by(miRNA_name, position) %>%
  summarise(mean_vaf = mean(vaf, na.rm = TRUE), .groups = 'drop') %>%
  pivot_wider(names_from = position, values_from = mean_vaf, names_prefix = "pos_")

# Crear matriz para heatmap - reemplazar NA con 0
mirna_names <- vaf_heatmap_data$miRNA_name
vaf_matrix <- as.matrix(vaf_heatmap_data[, -1])
vaf_matrix[is.na(vaf_matrix)] <- 0
rownames(vaf_matrix) <- mirna_names

# Heatmap simple
png(file.path(figures_dir, "vaf_heatmap_by_mirna_position.png"), width = 12, height = 8, units = "in", res = 300)
heatmap(vaf_matrix, 
        main = "VAF por miRNA y Posición",
        xlab = "Posición",
        ylab = "miRNA",
        col = colorRampPalette(c("white", "red"))(100),
        na.rm = TRUE)
dev.off()

# Gráfico de barras de SNVs por miRNA
p_snvs_by_mirna <- ggplot(head(mirna_summary, 20), aes(x = reorder(miRNA_name, n_snvs), y = n_snvs)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  labs(title = "Número de SNVs por miRNA (Top 20)", x = "miRNA", y = "Número de SNVs") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
ggsave(file.path(figures_dir, "snvs_by_mirna_bar.png"), p_snvs_by_mirna, width = 12, height = 8)

# Scatter plot de VAF vs número de SNVs por miRNA
p_vaf_vs_snvs <- ggplot(mirna_summary, aes(x = n_snvs, y = mean_vaf, size = n_positions)) +
  geom_point(alpha = 0.7) +
  geom_smooth(method = "lm", se = TRUE) +
  labs(title = "VAF vs Número de SNVs por miRNA", 
       x = "Número de SNVs", 
       y = "VAF Medio",
       size = "Posiciones") +
  theme_minimal()
ggsave(file.path(figures_dir, "vaf_vs_snvs_scatter.png"), p_vaf_vs_snvs)

cat(paste0("   - Figuras guardadas en: ", figures_dir, "\n\n"))

# --- 9. GUARDAR RESULTADOS ---
cat("💾 9. GUARDAR RESULTADOS\n")
cat("========================\n")

tables_dir <- "final_analysis/tables"
if (!dir.exists(tables_dir)) {
  dir.create(tables_dir, recursive = TRUE)
}

write.csv(mirna_summary, file.path(tables_dir, "individual_mirna_summary.csv"), row.names = FALSE)
write.csv(mirna_test_results, file.path(tables_dir, "individual_mirna_tests.csv"), row.names = FALSE)
write.csv(seed_analysis_simple, file.path(tables_dir, "individual_mirna_seed_analysis.csv"), row.names = FALSE)
write.csv(positional_patterns, file.path(tables_dir, "individual_mirna_positional_patterns.csv"), row.names = FALSE)
cat(paste0("   - Tablas guardadas en: ", tables_dir, "\n\n"))

# --- 10. RESUMEN FINAL ---
cat("📋 10. RESUMEN FINAL\n")
cat("====================\n")
cat("📊 ANÁLISIS POR miRNA:\n")
cat(paste0("   - miRNAs analizados: ", nrow(mirna_test_results), "\n"))
cat(paste0("   - miRNAs significativos en VAF: ", sum(mirna_test_results$significant_vaf, na.rm = TRUE), "\n"))
cat(paste0("   - miRNAs significativos en SNVs: ", sum(mirna_test_results$significant_snvs, na.rm = TRUE), "\n"))
cat(paste0("   - miRNAs con más SNVs: ", mirna_summary$miRNA_name[1], " (", mirna_summary$n_snvs[1], " SNVs)\n"))
cat(paste0("   - miRNAs con mayor VAF medio: ", mirna_summary$miRNA_name[which.max(mirna_summary$mean_vaf)], " (", round(max(mirna_summary$mean_vaf), 4), ")\n\n"))

cat("🌱 ANÁLISIS DE REGIÓN SEED:\n")
cat(paste0("   - miRNAs con mayor ratio VAF Seed: ", seed_analysis_simple$miRNA_name[1], " (", round(seed_analysis_simple$seed_vaf_ratio[1], 2), ")\n"))
cat(paste0("   - miRNAs con mayor ratio SNV Seed: ", seed_analysis_simple$miRNA_name[which.max(seed_analysis_simple$seed_snv_ratio)], " (", round(max(seed_analysis_simple$seed_snv_ratio, na.rm = TRUE), 2), ")\n\n"))

cat("✅ VERIFICACIONES:\n")
cat("   - VAFs calculados por miRNA: ✓\n")
cat("   - Tests diferenciales realizados: ✓\n")
cat("   - Análisis posicional completado: ✓\n")
cat("   - Visualizaciones creadas: ✓\n")
cat("   - Resultados guardados: ✓\n\n")

cat("🎯 PRÓXIMOS PASOS:\n")
cat("   - Ejecutar análisis de clustering de patrones\n")
cat("   - Realizar análisis funcional de miRNAs\n")
cat("   - Interpretar resultados inesperados\n")
cat("   - Escribir paper con interpretación correcta\n\n")
