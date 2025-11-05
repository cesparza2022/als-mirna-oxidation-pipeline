#' Análisis Estadístico Simplificado - ALS vs Control
#' 
#' Este script realiza análisis estadísticos básicos para comparar
#' mutaciones G>T entre grupos ALS y Control

# Load required libraries
library(dplyr)
library(ggplot2)
library(tidyr)
library(stringr)
library(purrr)
library(scales)
library(gridExtra)

#' Función para análisis estadístico simplificado
run_simple_statistical_analysis <- function() {
  cat("=== ANÁLISIS ESTADÍSTICO SIMPLIFICADO - ALS vs CONTROL ===\n")
  
  # Cargar datos
  source("R/load_mirna_data.R")
  mirna_data <- load_and_prepare_data()
  
  # Crear directorios de salida
  if (!dir.exists("outputs/statistics")) dir.create("outputs/statistics", recursive = TRUE)
  if (!dir.exists("outputs/figures/statistics")) dir.create("outputs/figures/statistics", recursive = TRUE)
  
  # Preparar datos para análisis
  gt_summary <- mirna_data$gt_analysis$gt_summary %>%
    left_join(mirna_data$filtered_data$sample_metadata, by = "sample_id")
  
  # Usar la columna group correcta
  group_col <- if("group.x" %in% names(gt_summary)) "group.x" else "group"
  
  cat("\n=== 1. ANÁLISIS DESCRIPTIVO ===\n")
  
  # Estadísticas descriptivas por grupo
  descriptive_stats <- gt_summary %>%
    group_by(!!sym(group_col)) %>%
    summarise(
      n = n(),
      mean_gt = mean(gt_count, na.rm = TRUE),
      median_gt = median(gt_count, na.rm = TRUE),
      sd_gt = sd(gt_count, na.rm = TRUE),
      se_gt = sd(gt_count, na.rm = TRUE) / sqrt(n()),
      min_gt = min(gt_count, na.rm = TRUE),
      max_gt = max(gt_count, na.rm = TRUE),
      q25 = quantile(gt_count, 0.25, na.rm = TRUE),
      q75 = quantile(gt_count, 0.75, na.rm = TRUE),
      .groups = "drop"
    )
  
  cat("📊 ESTADÍSTICAS DESCRIPTIVAS POR GRUPO:\n")
  print(descriptive_stats)
  
  # Calcular tasas de G>T (normalizadas por cobertura total)
  total_coverage <- colSums(mirna_data$filtered_data$count_matrix, na.rm = TRUE)
  coverage_df <- data.frame(
    sample_id = names(total_coverage),
    total_coverage = as.numeric(total_coverage),
    stringsAsFactors = FALSE
  )
  
  gt_summary <- gt_summary %>%
    left_join(coverage_df, by = "sample_id") %>%
    mutate(gt_rate = gt_count / total_coverage)
  
  # Estadísticas de tasas G>T
  rate_stats <- gt_summary %>%
    group_by(!!sym(group_col)) %>%
    summarise(
      n = n(),
      mean_rate = mean(gt_rate, na.rm = TRUE),
      median_rate = median(gt_rate, na.rm = TRUE),
      sd_rate = sd(gt_rate, na.rm = TRUE),
      se_rate = sd(gt_rate, na.rm = TRUE) / sqrt(n()),
      .groups = "drop"
    )
  
  cat("\n📈 ESTADÍSTICAS DE TASAS G>T (NORMALIZADAS):\n")
  print(rate_stats)
  
  cat("\n=== 2. PRUEBAS DE COMPARACIÓN DE GRUPOS ===\n")
  
  # t-test paramétrico
  t_test <- t.test(gt_count ~ as.factor(gt_summary[[group_col]]), data = gt_summary)
  cat("📊 T-TEST PARAMÉTRICO (Conteos G>T):\n")
  cat("   - t =", round(t_test$statistic, 4), ", df =", round(t_test$parameter, 2), "\n")
  cat("   - p-value =", format(t_test$p.value, scientific = TRUE), "\n")
  cat("   - 95% CI: [", round(t_test$conf.int[1], 2), ",", round(t_test$conf.int[2], 2), "]\n")
  
  # Wilcoxon rank-sum test (no paramétrico)
  wilcox_test <- wilcox.test(gt_count ~ as.factor(gt_summary[[group_col]]), data = gt_summary)
  cat("\n📊 WILCOXON RANK-SUM TEST (No paramétrico):\n")
  cat("   - W =", round(wilcox_test$statistic, 4), ", p =", format(wilcox_test$p.value, scientific = TRUE), "\n")
  
  # t-test para tasas normalizadas
  t_test_rates <- t.test(gt_rate ~ as.factor(gt_summary[[group_col]]), data = gt_summary)
  cat("\n📊 T-TEST PARA TASAS G>T NORMALIZADAS:\n")
  cat("   - t =", round(t_test_rates$statistic, 4), ", df =", round(t_test_rates$parameter, 2), "\n")
  cat("   - p-value =", format(t_test_rates$p.value, scientific = TRUE), "\n")
  cat("   - 95% CI: [", round(t_test_rates$conf.int[1], 6), ",", round(t_test_rates$conf.int[2], 6), "]\n")
  
  cat("\n=== 3. ANÁLISIS DE TAMAÑO DEL EFECTO ===\n")
  
  # Obtener datos por grupo
  als_data <- gt_summary$gt_count[gt_summary[[group_col]] == "ALS"]
  control_data <- gt_summary$gt_count[gt_summary[[group_col]] == "Control"]
  
  # Cohen's d
  pooled_sd <- sqrt(((length(als_data) - 1) * var(als_data) + (length(control_data) - 1) * var(control_data)) / 
                    (length(als_data) + length(control_data) - 2))
  cohens_d <- (mean(als_data) - mean(control_data)) / pooled_sd
  
  cat("📏 COHEN'S D (Tamaño del efecto):\n")
  cat("   - d =", round(cohens_d, 4), "\n")
  cat("   - Interpretación:", interpret_cohens_d(cohens_d), "\n")
  
  # Glass's delta
  glass_delta <- (mean(als_data) - mean(control_data)) / sd(control_data)
  cat("\n📏 GLASS'S DELTA:\n")
  cat("   - Δ =", round(glass_delta, 4), "\n")
  
  # Hedges' g (corrección para muestras pequeñas)
  hedges_g <- cohens_d * (1 - (3 / (4 * (length(als_data) + length(control_data)) - 9)))
  cat("\n📏 HEDGES' G (Corregido):\n")
  cat("   - g =", round(hedges_g, 4), "\n")
  
  cat("\n=== 4. ANÁLISIS DE OUTLIERS ===\n")
  
  # Detectar outliers usando IQR
  als_q1 <- quantile(als_data, 0.25)
  als_q3 <- quantile(als_data, 0.75)
  als_iqr <- als_q3 - als_q1
  als_outliers <- sum(als_data < (als_q1 - 1.5 * als_iqr) | als_data > (als_q3 + 1.5 * als_iqr))
  
  control_q1 <- quantile(control_data, 0.25)
  control_q3 <- quantile(control_data, 0.75)
  control_iqr <- control_q3 - control_q1
  control_outliers <- sum(control_data < (control_q1 - 1.5 * control_iqr) | control_data > (control_q3 + 1.5 * control_iqr))
  
  cat("🔍 DETECCIÓN DE OUTLIERS (Método IQR):\n")
  cat("   - Outliers ALS:", als_outliers, "(", round(als_outliers/length(als_data)*100, 2), "%)\n")
  cat("   - Outliers Control:", control_outliers, "(", round(control_outliers/length(control_data)*100, 2), "%)\n")
  
  cat("\n=== 5. CREANDO VISUALIZACIONES ESTADÍSTICAS ===\n")
  
  # 1. Boxplot comparativo
  p1 <- ggplot(gt_summary, aes(x = !!sym(group_col), y = gt_count, fill = !!sym(group_col))) +
    geom_boxplot(alpha = 0.7, outlier.alpha = 0.5) +
    scale_y_log10(labels = comma_format()) +
    labs(
      title = "Distribución de Mutaciones G>T por Grupo",
      subtitle = "Escala logarítmica",
      x = "Grupo",
      y = "Conteo de Mutaciones G>T (log10)",
      fill = "Grupo"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      legend.position = "none"
    ) +
    scale_fill_manual(values = c("ALS" = "#1f77b4", "Control" = "#ff7f0e"))
  
  ggsave("outputs/figures/statistics/01_boxplot_gt_counts.png", p1, width = 8, height = 6, dpi = 300)
  
  # 2. Histogramas superpuestos
  p2 <- ggplot(gt_summary, aes(x = gt_count, fill = !!sym(group_col))) +
    geom_histogram(alpha = 0.6, position = "identity", bins = 50) +
    scale_x_log10(labels = comma_format()) +
    labs(
      title = "Distribución de Mutaciones G>T por Grupo",
      subtitle = "Histogramas superpuestos",
      x = "Conteo de Mutaciones G>T (log10)",
      y = "Frecuencia",
      fill = "Grupo"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold")
    ) +
    scale_fill_manual(values = c("ALS" = "#1f77b4", "Control" = "#ff7f0e"))
  
  ggsave("outputs/figures/statistics/02_histogram_gt_counts.png", p2, width = 10, height = 6, dpi = 300)
  
  # 3. Boxplot de tasas normalizadas
  p3 <- ggplot(gt_summary, aes(x = !!sym(group_col), y = gt_rate, fill = !!sym(group_col))) +
    geom_boxplot(alpha = 0.7, outlier.alpha = 0.5) +
    scale_y_log10(labels = scientific_format()) +
    labs(
      title = "Distribución de Tasas G>T Normalizadas por Grupo",
      subtitle = "Escala logarítmica",
      x = "Grupo",
      y = "Tasa G>T (log10)",
      fill = "Grupo"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      legend.position = "none"
    ) +
    scale_fill_manual(values = c("ALS" = "#1f77b4", "Control" = "#ff7f0e"))
  
  ggsave("outputs/figures/statistics/03_boxplot_gt_rates.png", p3, width = 8, height = 6, dpi = 300)
  
  # 4. Violin plot
  p4 <- ggplot(gt_summary, aes(x = !!sym(group_col), y = gt_count, fill = !!sym(group_col))) +
    geom_violin(alpha = 0.7) +
    geom_boxplot(width = 0.1, alpha = 0.8) +
    scale_y_log10(labels = comma_format()) +
    labs(
      title = "Distribución de Densidad de Mutaciones G>T",
      subtitle = "Violin plot con boxplot superpuesto",
      x = "Grupo",
      y = "Conteo de Mutaciones G>T (log10)",
      fill = "Grupo"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      legend.position = "none"
    ) +
    scale_fill_manual(values = c("ALS" = "#1f77b4", "Control" = "#ff7f0e"))
  
  ggsave("outputs/figures/statistics/04_violin_plot.png", p4, width = 8, height = 6, dpi = 300)
  
  # 5. Scatter plot con jitter
  p5 <- ggplot(gt_summary, aes(x = !!sym(group_col), y = gt_count, color = !!sym(group_col))) +
    geom_jitter(width = 0.2, alpha = 0.6, size = 2) +
    geom_boxplot(alpha = 0.3, width = 0.5) +
    scale_y_log10(labels = comma_format()) +
    labs(
      title = "Distribución de Mutaciones G>T por Muestra",
      subtitle = "Scatter plot con jitter + boxplot",
      x = "Grupo",
      y = "Conteo de Mutaciones G>T (log10)",
      color = "Grupo"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      legend.position = "none"
    ) +
    scale_color_manual(values = c("ALS" = "#1f77b4", "Control" = "#ff7f0e"))
  
  ggsave("outputs/figures/statistics/05_scatter_plot.png", p5, width = 8, height = 6, dpi = 300)
  
  cat("\n=== 6. GUARDANDO RESULTADOS ESTADÍSTICOS ===\n")
  
  # Crear resumen de resultados estadísticos
  statistical_summary <- data.frame(
    Test = c("T-test (conteos)", "Wilcoxon (conteos)", "T-test (tasas)"),
    Statistic = c(
      round(t_test$statistic, 4),
      round(wilcox_test$statistic, 4),
      round(t_test_rates$statistic, 4)
    ),
    P_value = c(
      format(t_test$p.value, scientific = TRUE),
      format(wilcox_test$p.value, scientific = TRUE),
      format(t_test_rates$p.value, scientific = TRUE)
    ),
    Significant = c(
      t_test$p.value < 0.05,
      wilcox_test$p.value < 0.05,
      t_test_rates$p.value < 0.05
    )
  )
  
  # Guardar tablas
  write.csv(descriptive_stats, "outputs/statistics/descriptive_statistics.csv", row.names = FALSE)
  write.csv(rate_stats, "outputs/statistics/rate_statistics.csv", row.names = FALSE)
  write.csv(statistical_summary, "outputs/statistics/statistical_tests_summary.csv", row.names = FALSE)
  
  # Crear reporte estadístico
  create_simple_statistical_report(descriptive_stats, rate_stats, statistical_summary, 
                                  t_test, wilcox_test, cohens_d)
  
  cat("\n=== RESUMEN FINAL ===\n")
  cat("📊 Análisis estadístico completado exitosamente!\n")
  cat("📁 Resultados guardados en:\n")
  cat("   - Gráficos: outputs/figures/statistics/\n")
  cat("   - Tablas: outputs/statistics/\n")
  cat("📈 Total de gráficos generados: 5\n")
  cat("📋 Total de tablas generadas: 3\n")
  
  return(list(
    descriptive_stats = descriptive_stats,
    rate_stats = rate_stats,
    statistical_summary = statistical_summary,
    t_test = t_test,
    wilcox_test = wilcox_test,
    cohens_d = cohens_d
  ))
}

#' Función para interpretar Cohen's d
interpret_cohens_d <- function(d) {
  abs_d <- abs(d)
  if (abs_d < 0.2) return("Efecto pequeño")
  if (abs_d < 0.5) return("Efecto mediano")
  if (abs_d < 0.8) return("Efecto grande")
  return("Efecto muy grande")
}

#' Función para crear reporte estadístico simplificado
create_simple_statistical_report <- function(descriptive_stats, rate_stats, statistical_summary, 
                                            t_test, wilcox_test, cohens_d) {
  cat("\n📝 Creando reporte estadístico...\n")
  
  report_content <- paste0(
    "# Análisis Estadístico Simplificado - ALS vs Control\n\n",
    "## Resumen Ejecutivo\n\n",
    "Este reporte presenta un análisis estadístico básico comparando mutaciones G>T ",
    "entre muestras de pacientes con ALS y controles.\n\n",
    "## Resultados Principales\n\n",
    "### 1. Comparación de Grupos\n",
    "- **T-test paramétrico**: t = ", round(t_test$statistic, 4), ", p = ", format(t_test$p.value, scientific = TRUE), "\n",
    "- **Wilcoxon rank-sum**: W = ", round(wilcox_test$statistic, 4), ", p = ", format(wilcox_test$p.value, scientific = TRUE), "\n",
    "- **Significancia**: ", ifelse(t_test$p.value < 0.05, "SIGNIFICATIVO", "No significativo"), "\n\n",
    "### 2. Tamaño del Efecto\n",
    "- **Cohen's d**: ", round(cohens_d, 4), " (", interpret_cohens_d(cohens_d), ")\n\n",
    "### 3. Estadísticas Descriptivas\n\n",
    "#### Conteos G>T por Grupo:\n",
    "| Grupo | n | Media | Mediana | SD | SE |\n",
    "|-------|---|-------|---------|----|----|\n",
    "| ALS | ", descriptive_stats$n[1], " | ", round(descriptive_stats$mean_gt[1], 2), " | ", round(descriptive_stats$median_gt[1], 2), " | ", round(descriptive_stats$sd_gt[1], 2), " | ", round(descriptive_stats$se_gt[1], 2), " |\n",
    "| Control | ", descriptive_stats$n[2], " | ", round(descriptive_stats$mean_gt[2], 2), " | ", round(descriptive_stats$median_gt[2], 2), " | ", round(descriptive_stats$sd_gt[2], 2), " | ", round(descriptive_stats$se_gt[2], 2), " |\n\n",
    "#### Tasas G>T Normalizadas por Grupo:\n",
    "| Grupo | n | Media | Mediana | SD | SE |\n",
    "|-------|---|-------|---------|----|----|\n",
    "| ALS | ", rate_stats$n[1], " | ", round(rate_stats$mean_rate[1], 6), " | ", round(rate_stats$median_rate[1], 6), " | ", round(rate_stats$sd_rate[1], 6), " | ", round(rate_stats$se_rate[1], 6), " |\n",
    "| Control | ", rate_stats$n[2], " | ", round(rate_stats$mean_rate[2], 6), " | ", round(rate_stats$median_rate[2], 6), " | ", round(rate_stats$sd_rate[2], 6), " | ", round(rate_stats$se_rate[2], 6), " |\n\n",
    "## Archivos Generados\n\n",
    "### Gráficos Estadísticos (outputs/figures/statistics/)\n",
    "1. `01_boxplot_gt_counts.png` - Boxplot de conteos G>T\n",
    "2. `02_histogram_gt_counts.png` - Histogramas superpuestos\n",
    "3. `03_boxplot_gt_rates.png` - Boxplot de tasas normalizadas\n",
    "4. `04_violin_plot.png` - Violin plot de densidad\n",
    "5. `05_scatter_plot.png` - Scatter plot con jitter\n\n",
    "### Tablas Estadísticas (outputs/statistics/)\n",
    "1. `descriptive_statistics.csv` - Estadísticas descriptivas\n",
    "2. `rate_statistics.csv` - Estadísticas de tasas\n",
    "3. `statistical_tests_summary.csv` - Resumen de pruebas estadísticas\n\n",
    "## Interpretación de Resultados\n\n",
    "### Significancia Estadística\n",
    ifelse(t_test$p.value < 0.05, 
           "**Los grupos ALS y Control muestran diferencias estadísticamente significativas en las mutaciones G>T.**",
           "**No se encontraron diferencias estadísticamente significativas entre los grupos ALS y Control.**"),
    "\n\n",
    "### Tamaño del Efecto\n",
    "El tamaño del efecto (Cohen's d = ", round(cohens_d, 4), ") indica un ", 
    tolower(interpret_cohens_d(cohens_d)), " entre los grupos.\n\n",
    "## Recomendaciones\n\n",
    "1. **Interpretación cautelosa**: Considerar tanto la significancia estadística como el tamaño del efecto\n",
    "2. **Análisis adicional**: Realizar análisis de subgrupos si es apropiado\n",
    "3. **Validación**: Confirmar resultados con análisis independientes\n",
    "4. **Replicación**: Considerar estudios de replicación con muestras independientes\n\n",
    "---\n",
    "*Reporte estadístico generado el ", Sys.Date(), "*\n"
  )
  
  writeLines(report_content, "outputs/statistics/simple_statistical_analysis_report.md")
  cat("   - Reporte guardado en: outputs/statistics/simple_statistical_analysis_report.md\n")
}

# Ejecutar análisis si se llama directamente
if (!interactive()) {
  results <- run_simple_statistical_analysis()
}

