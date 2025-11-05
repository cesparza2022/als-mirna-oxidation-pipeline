# --- ANÁLISIS INDIVIDUAL DE miRNAs VERSIÓN 2 ---
# Análisis detallado por miRNA individual

# --- LIBRERÍAS ---
library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(ComplexHeatmap)
library(circlize)
library(viridis)
library(RColorBrewer)
library(reshape2)
library(stats)

# --- CONFIGURACIÓN ---
cat("🔬 ANÁLISIS INDIVIDUAL DE miRNAs VERSIÓN 2\n")
cat("==========================================\n\n")

# --- 1. CARGANDO DATOS ---
cat("📊 1. CARGANDO DATOS\n")
cat("====================\n")

# Cargar datos del análisis anterior
source("01_analysis_v2.R")

# Preparar datos para análisis por miRNA
vaf_by_mirna <- vaf_data %>%
  group_by(miRNA_name, sample, cohort) %>%
  summarise(
    n_snvs = n(),
    mean_vaf = mean(vaf, na.rm = TRUE),
    median_vaf = median(vaf, na.rm = TRUE),
    n_seed_snvs = sum(region == "Seed", na.rm = TRUE),
    n_non_seed_snvs = sum(region == "Non-seed", na.rm = TRUE),
    .groups = 'drop'
  )

cat(paste0("   - miRNAs analizados: ", length(unique(vaf_by_mirna$miRNA_name)), "\n"))
cat(paste0("   - Observaciones miRNA-muestra: ", nrow(vaf_by_mirna), "\n\n"))

# --- 2. TESTS DIFERENCIALES POR miRNA ---
cat("📊 2. TESTS DIFERENCIALES POR miRNA\n")
cat("===================================\n")

unique_mirnas <- unique(vaf_by_mirna$miRNA_name)
mirna_test_results <- data.frame()

for (mirna in unique_mirnas) {
  mirna_data <- vaf_by_mirna %>% filter(miRNA_name == mirna)
  
  # Verificar que haya datos para ambos grupos
  if (length(unique(mirna_data$cohort)) < 2 || 
      sum(mirna_data$cohort == "ALS") < 1 || 
      sum(mirna_data$cohort == "Control") < 1) {
    next
  }
  
  # Test t para VAF medio
  t_test_vaf <- tryCatch({
    t.test(mean_vaf ~ cohort, data = mirna_data)
  }, error = function(e) {
    list(p.value = NA, statistic = NA, estimate = c(NA, NA))
  })
  
  # Test t para número de SNVs
  t_test_snvs <- tryCatch({
    t.test(n_snvs ~ cohort, data = mirna_data)
  }, error = function(e) {
    list(p.value = NA, statistic = NA, estimate = c(NA, NA))
  })
  
  # Resumen por miRNA
  mirna_stats <- mirna_data %>%
    group_by(cohort) %>%
    summarise(
      mean_vaf = mean(mean_vaf, na.rm = TRUE),
      median_vaf = median(median_vaf, na.rm = TRUE),
      n_snvs = mean(n_snvs, na.rm = TRUE),
      n_seed_snvs = mean(n_seed_snvs, na.rm = TRUE),
      n_non_seed_snvs = mean(n_non_seed_snvs, na.rm = TRUE),
      .groups = 'drop'
    )
  
  # Crear fila de resultados
  result_row <- data.frame(
    miRNA_name = mirna,
    n_samples_als = sum(mirna_data$cohort == "ALS"),
    n_samples_control = sum(mirna_data$cohort == "Control"),
    mean_vaf_als = mirna_stats$mean_vaf[mirna_stats$cohort == "ALS"],
    mean_vaf_control = mirna_stats$mean_vaf[mirna_stats$cohort == "Control"],
    mean_snvs_als = mirna_stats$n_snvs[mirna_stats$cohort == "ALS"],
    mean_snvs_control = mirna_stats$n_snvs[mirna_stats$cohort == "Control"],
    mean_seed_snvs_als = mirna_stats$n_seed_snvs[mirna_stats$cohort == "ALS"],
    mean_seed_snvs_control = mirna_stats$n_seed_snvs[mirna_stats$cohort == "Control"],
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
    significant_snvs = fdr_snvs < 0.05,
    vaf_difference = mean_vaf_als - mean_vaf_control,
    snv_difference = mean_snvs_als - mean_snvs_control
  ) %>%
  arrange(desc(abs(vaf_difference)))

cat(paste0("   - miRNAs analizados: ", nrow(mirna_test_results), "\n"))
cat(paste0("   - miRNAs significativos en VAF: ", sum(mirna_test_results$significant_vaf, na.rm = TRUE), "\n"))
cat(paste0("   - miRNAs significativos en SNVs: ", sum(mirna_test_results$significant_snvs, na.rm = TRUE), "\n\n"))

# --- 3. TOP miRNAs DIFERENCIALES ---
cat("📊 3. TOP miRNAs DIFERENCIALES\n")
cat("===============================\n")

# Top 20 miRNAs con mayor diferencia en VAF
top_vaf_diff <- mirna_test_results %>%
  arrange(desc(abs(vaf_difference))) %>%
  head(20)

cat("   - Top 20 miRNAs con mayor diferencia en VAF:\n")
print(top_vaf_diff %>% select(miRNA_name, vaf_difference, fdr_vaf, significant_vaf))
cat("\n")

# Top 20 miRNAs con mayor diferencia en número de SNVs
top_snv_diff <- mirna_test_results %>%
  arrange(desc(abs(snv_difference))) %>%
  head(20)

cat("   - Top 20 miRNAs con mayor diferencia en SNVs:\n")
print(top_snv_diff %>% select(miRNA_name, snv_difference, fdr_snvs, significant_snvs))
cat("\n")

# --- 4. ANÁLISIS DE REGIÓN SEED ---
cat("🌱 4. ANÁLISIS DE REGIÓN SEED\n")
cat("=============================\n")

# Análisis de ratio Seed/Non-seed
seed_analysis <- mirna_test_results %>%
  mutate(
    seed_ratio_als = mean_seed_snvs_als / (mean_seed_snvs_als + (mean_snvs_als - mean_seed_snvs_als)),
    seed_ratio_control = mean_seed_snvs_control / (mean_seed_snvs_control + (mean_snvs_control - mean_seed_snvs_control)),
    seed_ratio_diff = seed_ratio_als - seed_ratio_control
  ) %>%
  arrange(desc(abs(seed_ratio_diff)))

cat("   - Top 10 miRNAs con mayor diferencia en ratio Seed:\n")
print(head(seed_analysis %>% select(miRNA_name, seed_ratio_als, seed_ratio_control, seed_ratio_diff), 10))
cat("\n")

# --- 5. VISUALIZACIONES ---
cat("📊 5. CREANDO VISUALIZACIONES\n")
cat("=============================\n")

# Gráfico de VAFs por miRNA (top 20)
top_mirnas <- head(mirna_test_results$miRNA_name, 20)
vaf_plot_data <- vaf_by_mirna %>%
  filter(miRNA_name %in% top_mirnas) %>%
  mutate(miRNA_name = factor(miRNA_name, levels = top_mirnas))

p_vaf <- ggplot(vaf_plot_data, aes(x = miRNA_name, y = mean_vaf, fill = cohort)) +
  geom_boxplot(alpha = 0.7) +
  scale_fill_manual(values = c("ALS" = "red", "Control" = "blue")) +
  labs(
    title = "VAFs por miRNA (Top 20 más diferenciales)",
    x = "miRNA",
    y = "VAF medio",
    fill = "Cohorte"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
    axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
    axis.text.y = element_text(size = 10),
    axis.title = element_text(size = 12),
    legend.position = "bottom"
  )

ggsave("vaf_by_mirna_top20.pdf", p_vaf, width = 14, height = 8)
cat("   - Gráfico de VAFs por miRNA guardado: vaf_by_mirna_top20.pdf\n")

# Gráfico de número de SNVs por miRNA
p_snvs <- ggplot(vaf_plot_data, aes(x = miRNA_name, y = n_snvs, fill = cohort)) +
  geom_boxplot(alpha = 0.7) +
  scale_fill_manual(values = c("ALS" = "red", "Control" = "blue")) +
  labs(
    title = "Número de SNVs por miRNA (Top 20 más diferenciales)",
    x = "miRNA",
    y = "Número de SNVs",
    fill = "Cohorte"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
    axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
    axis.text.y = element_text(size = 10),
    axis.title = element_text(size = 12),
    legend.position = "bottom"
  )

ggsave("snvs_by_mirna_top20.pdf", p_snvs, width = 14, height = 8)
cat("   - Gráfico de SNVs por miRNA guardado: snvs_by_mirna_top20.pdf\n")

# --- 6. HEATMAP DE miRNAs DIFERENCIALES ---
cat("🔥 6. HEATMAP DE miRNAs DIFERENCIALES\n")
cat("=====================================\n")

# Seleccionar miRNAs significativos
significant_mirnas <- mirna_test_results %>%
  filter(significant_vaf | significant_snvs) %>%
  arrange(desc(abs(vaf_difference))) %>%
  head(50)

if (nrow(significant_mirnas) > 0) {
  # Crear matriz para heatmap
  heatmap_data <- vaf_by_mirna %>%
    filter(miRNA_name %in% significant_mirnas$miRNA_name) %>%
    select(miRNA_name, sample, mean_vaf) %>%
    pivot_wider(names_from = sample, values_from = mean_vaf, values_fill = 0)
  
  heatmap_df <- as.data.frame(heatmap_data)
  rownames(heatmap_df) <- heatmap_df$miRNA_name
  heatmap_matrix <- as.matrix(heatmap_df[, -1])
  
  # Metadatos de muestras
  sample_metadata_heatmap <- data.frame(sample = colnames(heatmap_matrix)) %>%
    left_join(sample_metadata, by = "sample")
  
  # Anotación de columnas
  ha_samples <- HeatmapAnnotation(
    Cohort = sample_metadata_heatmap$cohort,
    col = list(
      Cohort = c("ALS" = "red", "Control" = "blue")
    )
  )
  
  # Heatmap
  ht_mirnas <- Heatmap(
    heatmap_matrix,
    name = "VAF",
    col = colorRamp2(c(0, max(heatmap_matrix, na.rm = TRUE)), c("white", "red")),
    cluster_rows = TRUE,
    cluster_columns = TRUE,
    show_row_names = TRUE,
    show_column_names = FALSE,
    top_annotation = ha_samples,
    row_title = "miRNAs",
    column_title = "Muestras",
    heatmap_legend_param = list(
      title = "VAF medio"
    )
  )
  
  # Guardar heatmap
  pdf("heatmap_significant_mirnas.pdf", width = 12, height = 10)
  draw(ht_mirnas)
  dev.off()
  
  cat("   - Heatmap de miRNAs significativos guardado: heatmap_significant_mirnas.pdf\n")
} else {
  cat("   - No hay miRNAs significativos para crear heatmap\n")
}

# --- 7. GUARDAR RESULTADOS ---
cat("💾 7. GUARDANDO RESULTADOS\n")
cat("==========================\n")

# Guardar resultados de tests
write.csv(mirna_test_results, "mirna_test_results.csv", row.names = FALSE)
cat("   - Resultados de tests guardados: mirna_test_results.csv\n")

# Guardar análisis de seed
write.csv(seed_analysis, "seed_analysis.csv", row.names = FALSE)
cat("   - Análisis de región seed guardado: seed_analysis.csv\n")

cat("\n✅ ANÁLISIS INDIVIDUAL DE miRNAs COMPLETADO\n")
cat("===========================================\n\n")
