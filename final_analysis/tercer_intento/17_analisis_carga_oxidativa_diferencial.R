# =============================================================================
# ANÁLISIS DE CARGA OXIDATIVA DIFERENCIAL - ALS vs CONTROL
# =============================================================================
# Enfoque: Carga oxidativa total por muestra (métricas robustas)
# Objetivo: Identificar diferencias en carga oxidativa entre grupos
# Metodología: Análisis estadístico simple y robusto
# =============================================================================

# Cargar librerías
library(dplyr)
library(ggplot2)
library(tidyr)
library(stringr)
library(reshape2)
library(gridExtra)
library(corrplot)
library(RColorBrewer)
library(viridis)

# Configurar directorio de trabajo
setwd("/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/tercer_intento")

# =============================================================================
# 1. CARGA DE DATOS Y PREPARACIÓN
# =============================================================================

cat("=== ANÁLISIS DE CARGA OXIDATIVA DIFERENCIAL ===\n\n")

# Cargar datos preprocesados
cat("1. Cargando datos preprocesados...\n")

# Cargar datos finales desde archivo procesado
final_data <- read.csv("../processed_data/final_processed_data.csv", stringsAsFactors = FALSE)

# Verificar que tenemos los datos necesarios
if (nrow(final_data) == 0) {
  stop("Error: No se encontraron los datos preprocesados.")
}

# Usar final_data como vaf_data_final_heatmap para compatibilidad
vaf_data_final_heatmap <- final_data

# Extraer columnas de muestras
sample_cols <- grep("^Magen\\.", names(vaf_data_final_heatmap), value = TRUE)
sample_cols <- sample_cols[!grepl("\\.\\.PM\\.1MM\\.2MM\\.$", sample_cols)]

cat("   - Muestras identificadas:", length(sample_cols), "\n")
cat("   - SNVs analizados:", nrow(vaf_data_final_heatmap), "\n\n")

# =============================================================================
# 2. CLASIFICACIÓN DE MUESTRAS POR GRUPO
# =============================================================================

cat("2. Clasificando muestras por grupo...\n")

# Función para clasificar muestras
classify_samples <- function(sample_names) {
  groups <- character(length(sample_names))
  
  for (i in seq_along(sample_names)) {
    name <- sample_names[i]
    
    if (grepl("control", name, ignore.case = TRUE)) {
      groups[i] <- "Control"
    } else if (grepl("ALS", name, ignore.case = TRUE)) {
      groups[i] <- "ALS"
    } else {
      groups[i] <- "Unknown"
    }
  }
  
  return(groups)
}

# Clasificar muestras
sample_groups <- classify_samples(sample_cols)
group_counts <- table(sample_groups)

cat("   - Distribución de grupos:\n")
print(group_counts)
cat("\n")

# =============================================================================
# 3. CÁLCULO DE MÉTRICAS DE CARGA OXIDATIVA
# =============================================================================

cat("3. Calculando métricas de carga oxidativa...\n")

# Función para calcular métricas por muestra
calculate_oxidative_metrics <- function(vaf_data, sample_cols, sample_groups) {
  metrics <- data.frame(
    sample_id = sample_cols,
    group = sample_groups,
    total_vaf = NA,
    n_snvs = NA,
    avg_vaf = NA,
    max_vaf = NA,
    oxidative_score = NA,
    stringsAsFactors = FALSE
  )
  
  for (i in seq_along(sample_cols)) {
    col <- sample_cols[i]
    sample_vafs <- vaf_data[[col]]
    
    # Filtrar NAs y valores válidos
    valid_vafs <- sample_vafs[!is.na(sample_vafs) & sample_vafs > 0]
    
    if (length(valid_vafs) > 0) {
      metrics$total_vaf[i] <- sum(valid_vafs, na.rm = TRUE)
      metrics$n_snvs[i] <- length(valid_vafs)
      metrics$avg_vaf[i] <- mean(valid_vafs, na.rm = TRUE)
      metrics$max_vaf[i] <- max(valid_vafs, na.rm = TRUE)
      
      # Score de carga oxidativa (combinación de métricas)
      # Peso: total_vaf (0.4) + n_snvs (0.3) + avg_vaf (0.3)
      metrics$oxidative_score[i] <- 
        (0.4 * metrics$total_vaf[i]) + 
        (0.3 * metrics$n_snvs[i]) + 
        (0.3 * metrics$avg_vaf[i])
    } else {
      metrics$total_vaf[i] <- 0
      metrics$n_snvs[i] <- 0
      metrics$avg_vaf[i] <- 0
      metrics$max_vaf[i] <- 0
      metrics$oxidative_score[i] <- 0
    }
  }
  
  return(metrics)
}

# Calcular métricas
oxidative_metrics <- calculate_oxidative_metrics(vaf_data_final_heatmap, sample_cols, sample_groups)

cat("   - Métricas calculadas para", nrow(oxidative_metrics), "muestras\n")
cat("   - Rango de score oxidativo:", round(range(oxidative_metrics$oxidative_score, na.rm = TRUE), 3), "\n\n")

# =============================================================================
# 4. ANÁLISIS ESTADÍSTICO
# =============================================================================

cat("4. Realizando análisis estadístico...\n")

# Filtrar solo grupos conocidos
known_groups <- oxidative_metrics[oxidative_metrics$group %in% c("ALS", "Control"), ]

# Estadísticas descriptivas por grupo
desc_stats <- known_groups %>%
  group_by(group) %>%
  summarise(
    n_samples = n(),
    mean_total_vaf = mean(total_vaf, na.rm = TRUE),
    sd_total_vaf = sd(total_vaf, na.rm = TRUE),
    mean_n_snvs = mean(n_snvs, na.rm = TRUE),
    sd_n_snvs = sd(n_snvs, na.rm = TRUE),
    mean_avg_vaf = mean(avg_vaf, na.rm = TRUE),
    sd_avg_vaf = sd(avg_vaf, na.rm = TRUE),
    mean_oxidative_score = mean(oxidative_score, na.rm = TRUE),
    sd_oxidative_score = sd(oxidative_score, na.rm = TRUE),
    .groups = 'drop'
  )

cat("   - Estadísticas descriptivas por grupo:\n")
print(desc_stats)
cat("\n")

# Tests estadísticos
cat("   - Tests estadísticos (ALS vs Control):\n")

# Test t para score oxidativo
t_test_score <- t.test(oxidative_score ~ group, data = known_groups)
cat("     * Score oxidativo - t-test p-value:", round(t_test_score$p.value, 6), "\n")

# Test t para total VAF
t_test_total <- t.test(total_vaf ~ group, data = known_groups)
cat("     * Total VAF - t-test p-value:", round(t_test_total$p.value, 6), "\n")

# Test t para número de SNVs
t_test_nsnvs <- t.test(n_snvs ~ group, data = known_groups)
cat("     * Número de SNVs - t-test p-value:", round(t_test_nsnvs$p.value, 6), "\n")

# Test t para VAF promedio
t_test_avg <- t.test(avg_vaf ~ group, data = known_groups)
cat("     * VAF promedio - t-test p-value:", round(t_test_avg$p.value, 6), "\n\n")

# =============================================================================
# 5. IDENTIFICACIÓN DE OUTLIERS
# =============================================================================

cat("5. Identificando outliers oxidativos...\n")

# Calcular percentiles para score oxidativo
score_percentiles <- quantile(known_groups$oxidative_score, probs = c(0.25, 0.5, 0.75, 0.9, 0.95), na.rm = TRUE)

# Identificar outliers (percentil 95+)
outlier_threshold <- score_percentiles["95%"]
outliers <- known_groups[known_groups$oxidative_score >= outlier_threshold, ]

cat("   - Umbral de outlier (percentil 95):", round(outlier_threshold, 3), "\n")
cat("   - Número de outliers:", nrow(outliers), "\n")
cat("   - Distribución de outliers por grupo:\n")
print(table(outliers$group))
cat("\n")

# =============================================================================
# 6. VISUALIZACIONES
# =============================================================================

cat("6. Generando visualizaciones...\n")

# Crear directorio para figuras
if (!dir.exists("figures_oxidative_load")) {
  dir.create("figures_oxidative_load")
}

# 6.1 Boxplot de score oxidativo por grupo
p1 <- ggplot(known_groups, aes(x = group, y = oxidative_score, fill = group)) +
  geom_boxplot(alpha = 0.7, outlier.shape = NA) +
  geom_jitter(width = 0.2, alpha = 0.6, size = 1) +
  scale_fill_manual(values = c("ALS" = "#D62728", "Control" = "#2E8B57")) +
  labs(
    title = "Carga Oxidativa por Grupo",
    subtitle = paste("ALS vs Control (n =", nrow(known_groups), "muestras)"),
    x = "Grupo",
    y = "Score de Carga Oxidativa",
    fill = "Grupo"
  ) +
  theme_classic(base_size = 14) +
  theme(
    legend.position = "none",
    plot.title = element_text(hjust = 0.5, face = "bold"),
    plot.subtitle = element_text(hjust = 0.5)
  )

# Agregar significancia estadística
if (t_test_score$p.value < 0.05) {
  p1 <- p1 + 
    annotate("text", x = 1.5, y = max(known_groups$oxidative_score, na.rm = TRUE) * 1.1, 
             label = paste("p =", round(t_test_score$p.value, 4)), size = 4)
}

ggsave("figures_oxidative_load/01_boxplot_oxidative_score.png", p1, width = 8, height = 6, dpi = 300)

# 6.2 Scatter plot: Total VAF vs Número de SNVs
p2 <- ggplot(known_groups, aes(x = n_snvs, y = total_vaf, color = group)) +
  geom_point(alpha = 0.7, size = 2) +
  geom_smooth(method = "lm", se = TRUE, alpha = 0.3) +
  scale_color_manual(values = c("ALS" = "#D62728", "Control" = "#2E8B57")) +
  labs(
    title = "Relación entre Número de SNVs y Total VAF",
    subtitle = "Cada punto representa una muestra",
    x = "Número de SNVs",
    y = "Total VAF",
    color = "Grupo"
  ) +
  theme_classic(base_size = 14) +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    plot.subtitle = element_text(hjust = 0.5)
  )

ggsave("figures_oxidative_load/02_scatter_snvs_vs_total_vaf.png", p2, width = 10, height = 6, dpi = 300)

# 6.3 Histograma de distribución de score oxidativo
p3 <- ggplot(known_groups, aes(x = oxidative_score, fill = group)) +
  geom_histogram(alpha = 0.7, bins = 30, position = "identity") +
  geom_vline(xintercept = outlier_threshold, linetype = "dashed", color = "red", size = 1) +
  scale_fill_manual(values = c("ALS" = "#D62728", "Control" = "#2E8B57")) +
  labs(
    title = "Distribución de Score de Carga Oxidativa",
    subtitle = paste("Línea roja: umbral de outlier (percentil 95)"),
    x = "Score de Carga Oxidativa",
    y = "Frecuencia",
    fill = "Grupo"
  ) +
  theme_classic(base_size = 14) +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    plot.subtitle = element_text(hjust = 0.5)
  )

ggsave("figures_oxidative_load/03_histogram_oxidative_score.png", p3, width = 10, height = 6, dpi = 300)

# 6.4 Heatmap de correlaciones entre métricas
correlation_data <- known_groups[, c("total_vaf", "n_snvs", "avg_vaf", "oxidative_score")]
correlation_matrix <- cor(correlation_data, use = "complete.obs")

png("figures_oxidative_load/04_correlation_heatmap.png", width = 800, height = 600)
corrplot(correlation_matrix, 
         method = "color", 
         type = "upper", 
         order = "hclust",
         tl.cex = 1.2,
         cl.cex = 1.2,
         title = "Correlaciones entre Métricas de Carga Oxidativa",
         mar = c(0,0,2,0))
dev.off()

# =============================================================================
# 7. ANÁLISIS DE OUTLIERS
# =============================================================================

cat("7. Análisis detallado de outliers...\n")

if (nrow(outliers) > 0) {
  cat("   - Características de outliers:\n")
  outlier_summary <- outliers %>%
    group_by(group) %>%
    summarise(
      n_outliers = n(),
      mean_score = mean(oxidative_score, na.rm = TRUE),
      mean_total_vaf = mean(total_vaf, na.rm = TRUE),
      mean_n_snvs = mean(n_snvs, na.rm = TRUE),
      .groups = 'drop'
    )
  print(outlier_summary)
  
  # Identificar SNVs más frecuentes en outliers
  outlier_samples <- outliers$sample_id
  outlier_snv_data <- vaf_data_final_heatmap[, c("miRNA_name", "pos.mut", outlier_samples)]
  
  # Calcular frecuencia de SNVs en outliers
  snv_frequency <- data.frame(
    miRNA_name = vaf_data_final_heatmap$miRNA_name,
    pos_mut = vaf_data_final_heatmap$pos.mut,
    frequency_in_outliers = rowSums(!is.na(outlier_snv_data[, -c(1,2)]) & 
                                   outlier_snv_data[, -c(1,2)] > 0, na.rm = TRUE),
    stringsAsFactors = FALSE
  )
  
  # Top SNVs en outliers
  top_outlier_snvs <- snv_frequency %>%
    filter(frequency_in_outliers > 0) %>%
    arrange(desc(frequency_in_outliers)) %>%
    head(10)
  
  cat("\n   - Top 10 SNVs más frecuentes en outliers:\n")
  print(top_outlier_snvs)
  
} else {
  cat("   - No se identificaron outliers significativos\n")
}

# =============================================================================
# 8. RESUMEN EJECUTIVO
# =============================================================================

cat("\n8. RESUMEN EJECUTIVO\n")
cat("===================\n\n")

cat("📊 DATOS ANALIZADOS:\n")
cat("   - Total de muestras:", nrow(oxidative_metrics), "\n")
cat("   - ALS:", sum(oxidative_metrics$group == "ALS"), "muestras\n")
cat("   - Control:", sum(oxidative_metrics$group == "Control"), "muestras\n")
cat("   - SNVs analizados:", nrow(vaf_data_final_heatmap), "\n\n")

cat("📈 RESULTADOS PRINCIPALES:\n")
cat("   - Score oxidativo promedio ALS:", round(mean(known_groups$oxidative_score[known_groups$group == "ALS"], na.rm = TRUE), 3), "\n")
cat("   - Score oxidativo promedio Control:", round(mean(known_groups$oxidative_score[known_groups$group == "Control"], na.rm = TRUE), 3), "\n")
cat("   - Diferencia absoluta:", round(abs(mean(known_groups$oxidative_score[known_groups$group == "ALS"], na.rm = TRUE) - 
                                          mean(known_groups$oxidative_score[known_groups$group == "Control"], na.rm = TRUE)), 3), "\n")
cat("   - Significancia estadística (p-value):", round(t_test_score$p.value, 6), "\n\n")

cat("🎯 OUTLIERS IDENTIFICADOS:\n")
cat("   - Número de outliers:", nrow(outliers), "\n")
cat("   - Umbral de outlier:", round(outlier_threshold, 3), "\n")
if (nrow(outliers) > 0) {
  cat("   - Distribución por grupo:\n")
  print(table(outliers$group))
}

cat("\n📁 ARCHIVOS GENERADOS:\n")
cat("   - figures_oxidative_load/01_boxplot_oxidative_score.png\n")
cat("   - figures_oxidative_load/02_scatter_snvs_vs_total_vaf.png\n")
cat("   - figures_oxidative_load/03_histogram_oxidative_score.png\n")
cat("   - figures_oxidative_load/04_correlation_heatmap.png\n")

cat("\n✅ ANÁLISIS COMPLETADO\n")
cat("=====================\n")

# Guardar resultados
save(oxidative_metrics, desc_stats, outliers, t_test_score, 
     file = "oxidative_load_analysis_results.RData")

cat("\n💾 Resultados guardados en: oxidative_load_analysis_results.RData\n")
