#!/usr/bin/env Rscript

# =============================================================================
# ANÁLISIS COMPREHENSIVO DE FILTROS DE EXPRESIÓN
# =============================================================================

# Cargar librerías
library(dplyr)
library(ggplot2)
library(stringr)
library(readr)
library(tidyr)
library(purrr)

# Configuración
options(stringsAsFactors = FALSE)

# Función principal
main <- function() {
  cat("=== ANÁLISIS COMPREHENSIVO DE FILTROS DE EXPRESIÓN ===\n\n")
  
  # Cargar datos
  cat("Cargando datos...\n")
  df <- read_tsv("results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt", show_col_types = FALSE)
  cat("Dimensiones del dataset:", dim(df), "\n")
  
  # Identificar columnas
  meta_cols <- c("miRNA name", "pos:mut")
  sample_cols <- setdiff(names(df), meta_cols)
  total_cols <- sample_cols[str_detect(sample_cols, "\\(PM\\+1MM\\+2MM\\)")]
  snv_cols <- setdiff(sample_cols, total_cols)
  
  cat("Columnas totales:", length(total_cols), "\n")
  cat("Columnas SNV:", length(snv_cols), "\n")
  
  # Filtrar solo G>T
  cat("\nFiltrando mutaciones G>T...\n")
  df_gt <- df %>%
    filter(str_detect(`pos:mut`, "G>T"))
  
  cat("SNVs G>T encontrados:", nrow(df_gt), "\n")
  
  # Calcular RPM para diferentes umbrales
  rpm_thresholds <- c(0, 1, 3, 5, 10)
  methods <- c("mean", "median", "max")
  
  results <- list()
  
  for (threshold in rpm_thresholds) {
    for (method in methods) {
      cat(sprintf("\n--- RPM > %d (%s) ---\n", threshold, method))
      
      # Calcular RPM
      rpm_result <- calculate_rpm(df_gt, total_cols, method)
      rpm_data <- rpm_result$rpm_data
      
      # Filtrar por umbral
      if (threshold > 0) {
        rpm_filtered <- filter_by_rpm_threshold(rpm_data, snv_cols, threshold, method)
        cat("miRNAs después del filtro RPM:", nrow(rpm_filtered), "\n")
      } else {
        rpm_filtered <- rpm_data
        cat("Sin filtro de RPM\n")
      }
      
      # Filtrar VAF > 50%
      vaf_filtered <- filter_by_vaf(rpm_filtered, snv_cols, total_cols)
      cat("SNVs después del filtro VAF:", nrow(vaf_filtered), "\n")
      
      # Contar G>T en región semilla
      seed_counts <- count_seed_mutations(vaf_filtered, snv_cols)
      cat("miRNAs con mutaciones en región semilla:", nrow(seed_counts), "\n")
      
      # Seleccionar top 10%
      top_mirnas <- select_top_mirnas(seed_counts, 0.1)
      cat("Top miRNAs seleccionados:", nrow(top_mirnas), "\n")
      
      # Guardar resultados
      results[[paste0("rpm_", threshold, "_", method)]] <- list(
        threshold = threshold,
        method = method,
        total_mirnas = nrow(rpm_filtered),
        snvs_after_vaf = nrow(vaf_filtered),
        seed_mirnas = nrow(seed_counts),
        top_mirnas = nrow(top_mirnas),
        top_mirna_list = top_mirnas$`miRNA name`
      )
    }
  }
  
  # Generar reporte comparativo
  generate_comparative_report(results)
  
  # Crear visualizaciones
  create_visualizations(results)
  
  cat("\n=== ANÁLISIS COMPLETADO ===\n")
}

# Función para calcular RPM
calculate_rpm <- function(df, total_cols, method = "mean") {
  cat("Calculando RPM...\n")
  
  # Calcular library size por muestra
  lib_size <- df %>%
    summarise(across(all_of(total_cols), ~ sum(.x, na.rm = TRUE))) %>%
    unlist()
  
  # Calcular RPM manualmente
  rpm_data <- df
  for (col in total_cols) {
    rpm_data[[col]] <- (rpm_data[[col]] / lib_size[col]) * 1e6
  }
  
  return(list(rpm_data = rpm_data, lib_size = lib_size))
}

# Función para filtrar por umbral de RPM
filter_by_rpm_threshold <- function(df, snv_cols, threshold, method = "mean") {
  # Calcular RPM promedio por miRNA
  rpm_cols <- paste0(snv_cols, "_RPM")
  
  if (method == "mean") {
    df$mean_rpm <- rowMeans(select(df, all_of(rpm_cols)), na.rm = TRUE)
  } else if (method == "median") {
    df$mean_rpm <- apply(select(df, all_of(rpm_cols)), 1, median, na.rm = TRUE)
  } else if (method == "max") {
    df$mean_rpm <- apply(select(df, all_of(rpm_cols)), 1, max, na.rm = TRUE)
  }
  
  # Filtrar por umbral
  filtered <- df %>%
    filter(mean_rpm > threshold) %>%
    select(-mean_rpm)
  
  return(filtered)
}

# Función para filtrar por VAF
filter_by_vaf <- function(df, snv_cols, total_cols) {
  cat("Aplicando filtro VAF > 50%...\n")
  
  # Calcular VAF para cada SNV
  vaf_data <- df
  for (i in 1:length(snv_cols)) {
    snv_col <- snv_cols[i]
    total_col <- total_cols[i]
    
    # Calcular VAF
    vaf_data[[paste0(snv_col, "_VAF")]] <- vaf_data[[snv_col]] / vaf_data[[total_col]]
  }
  
  # Filtrar SNVs con VAF > 50%
  vaf_cols <- paste0(snv_cols, "_VAF")
  vaf_data$max_vaf <- apply(select(vaf_data, all_of(vaf_cols)), 1, max, na.rm = TRUE)
  
  filtered <- vaf_data %>%
    filter(max_vaf <= 0.5) %>%
    select(-all_of(vaf_cols), -max_vaf)
  
  return(filtered)
}

# Función para contar mutaciones en región semilla
count_seed_mutations <- function(df, snv_cols) {
  cat("Contando mutaciones en región semilla...\n")
  
  # Filtrar solo posiciones 2-8 (región semilla)
  seed_data <- df %>%
    filter(str_detect(`pos:mut`, "G>T")) %>%
    mutate(position = as.numeric(str_extract(`pos:mut`, "\\d+"))) %>%
    filter(position >= 2 & position <= 8)
  
  if (nrow(seed_data) == 0) {
    return(data.frame(`miRNA name` = character(0), seed_count = numeric(0)))
  }
  
  # Contar por miRNA
  seed_counts <- seed_data %>%
    group_by(`miRNA name`) %>%
    summarise(
      seed_count = sum(across(all_of(snv_cols), ~ sum(.x, na.rm = TRUE)), na.rm = TRUE),
      .groups = "drop"
    ) %>%
    filter(seed_count > 0) %>%
    arrange(desc(seed_count))
  
  return(seed_counts)
}

# Función para seleccionar top miRNAs
select_top_mirnas <- function(seed_counts, top_percent = 0.1) {
  n_top <- max(1, round(nrow(seed_counts) * top_percent))
  top_mirnas <- head(seed_counts, n_top)
  return(top_mirnas)
}

# Función para generar reporte comparativo
generate_comparative_report <- function(results) {
  cat("\nGenerando reporte comparativo...\n")
  
  # Crear tabla de comparación
  comparison_df <- map_dfr(results, function(x) {
    data.frame(
      threshold = x$threshold,
      method = x$method,
      total_mirnas = x$total_mirnas,
      snvs_after_vaf = x$snvs_after_vaf,
      seed_mirnas = x$seed_mirnas,
      top_mirnas = x$top_mirnas
    )
  }, .id = "strategy")
  
  # Guardar reporte
  write_tsv(comparison_df, "outputs/filter_comparison_analysis.tsv")
  
  # Crear reporte markdown
  report_content <- paste0(
    "# ANÁLISIS COMPREHENSIVO DE FILTROS DE EXPRESIÓN\n\n",
    "**Fecha:** ", Sys.Date(), "\n\n",
    "## RESUMEN EJECUTIVO\n\n",
    "Este análisis compara diferentes estrategias de filtrado de miRNAs para mutaciones G>T en región semilla.\n\n",
    "## ESTRATEGIAS EVALUADAS\n\n",
    "### 1. Umbrales de RPM\n",
    "- **0**: Sin filtro de expresión\n",
    "- **1**: RPM > 1\n",
    "- **3**: RPM > 3\n",
    "- **5**: RPM > 5\n",
    "- **10**: RPM > 10\n\n",
    "### 2. Métodos de Cálculo de RPM\n",
    "- **mean**: RPM promedio\n",
    "- **median**: RPM mediano\n",
    "- **max**: RPM máximo\n\n",
    "## RESULTADOS COMPARATIVOS\n\n",
    "| Estrategia | Total miRNAs | SNVs VAF | Semilla | Top 10% |\n",
    "|------------|--------------|----------|---------|----------|\n",
    paste(apply(comparison_df, 1, function(x) {
      paste0("| ", x[1], " | ", x[3], " | ", x[4], " | ", x[5], " | ", x[6], " |")
    }), collapse = "\n"), "\n\n",
    "## ANÁLISIS DE OVERLAP\n\n"
  )
  
  # Calcular overlaps
  strategies <- names(results)
  overlap_matrix <- matrix(0, nrow = length(strategies), ncol = length(strategies))
  rownames(overlap_matrix) <- strategies
  colnames(overlap_matrix) <- strategies
  
  for (i in 1:length(strategies)) {
    for (j in 1:length(strategies)) {
      if (i != j) {
        set1 <- results[[strategies[i]]]$top_mirna_list
        set2 <- results[[strategies[j]]]$top_mirna_list
        overlap <- length(intersect(set1, set2))
        overlap_matrix[i, j] <- overlap
      }
    }
  }
  
  # Agregar matriz de overlap al reporte
  report_content <- paste0(report_content,
    "### Matriz de Overlap (Top miRNAs)\n\n",
    "```\n",
    paste(apply(overlap_matrix, 1, function(x) paste(x, collapse = "\t")), collapse = "\n"),
    "\n```\n\n"
  )
  
  # Agregar conclusiones
  report_content <- paste0(report_content,
    "## CONCLUSIONES\n\n",
    "### 1. Impacto del Umbral de RPM\n",
    "- **RPM 0**: Máximo número de miRNAs, posible ruido\n",
    "- **RPM 1**: Balance entre selectividad y cobertura\n",
    "- **RPM 3**: Selectividad moderada\n",
    "- **RPM 5+**: Alta selectividad, posible pérdida de información\n\n",
    "### 2. Método de Cálculo de RPM\n",
    "- **Mean**: Más conservador, incluye miRNAs con expresión variable\n",
    "- **Median**: Resistente a outliers\n",
    "- **Max**: Más permisivo, incluye miRNAs con picos de expresión\n\n",
    "### 3. Recomendaciones\n",
    "- **Para análisis exploratorio**: RPM > 1 (mean)\n",
    "- **Para análisis robusto**: RPM > 3 (mean)\n",
    "- **Para análisis conservador**: RPM > 5 (median)\n\n"
  )
  
  # Guardar reporte
  writeLines(report_content, "outputs/filter_comparison_report.md")
  
  cat("Reporte guardado en: outputs/filter_comparison_report.md\n")
}

# Función para crear visualizaciones
create_visualizations <- function(results) {
  cat("Creando visualizaciones...\n")
  
  # Crear directorio de figuras
  dir.create("outputs/figures/filter_analysis", recursive = TRUE, showWarnings = FALSE)
  
  # 1. Gráfico de comparación de estrategias
  comparison_df <- map_dfr(results, function(x) {
    data.frame(
      threshold = x$threshold,
      method = x$method,
      total_mirnas = x$total_mirnas,
      snvs_after_vaf = x$snvs_after_vaf,
      seed_mirnas = x$seed_mirnas,
      top_mirnas = x$top_mirnas
    )
  }, .id = "strategy")
  
  # Gráfico de barras comparativo
  p1 <- ggplot(comparison_df, aes(x = factor(threshold), y = top_mirnas, fill = method)) +
    geom_bar(stat = "identity", position = "dodge") +
    labs(
      title = "Top miRNAs por Estrategia de Filtrado",
      x = "Umbral de RPM",
      y = "Número de Top miRNAs",
      fill = "Método RPM"
    ) +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  ggsave("outputs/figures/filter_analysis/strategy_comparison.png", p1, width = 10, height = 6, dpi = 300)
  
  # 2. Gráfico de distribución de conteos
  p2 <- ggplot(comparison_df, aes(x = total_mirnas, y = top_mirnas, color = method)) +
    geom_point(size = 3) +
    geom_smooth(method = "lm", se = FALSE) +
    labs(
      title = "Relación entre Total miRNAs y Top miRNAs",
      x = "Total miRNAs",
      y = "Top miRNAs",
      color = "Método RPM"
    ) +
    theme_minimal()
  
  ggsave("outputs/figures/filter_analysis/correlation_plot.png", p2, width = 10, height = 6, dpi = 300)
  
  # 3. Heatmap de overlap
  strategies <- names(results)
  overlap_matrix <- matrix(0, nrow = length(strategies), ncol = length(strategies))
  rownames(overlap_matrix) <- strategies
  colnames(overlap_matrix) <- strategies
  
  for (i in 1:length(strategies)) {
    for (j in 1:length(strategies)) {
      if (i != j) {
        set1 <- results[[strategies[i]]]$top_mirna_list
        set2 <- results[[strategies[j]]]$top_mirna_list
        overlap <- length(intersect(set1, set2))
        overlap_matrix[i, j] <- overlap
      }
    }
  }
  
  # Convertir a data frame para ggplot
  overlap_df <- expand.grid(strategy1 = strategies, strategy2 = strategies)
  overlap_df$overlap <- as.vector(overlap_matrix)
  
  p3 <- ggplot(overlap_df, aes(x = strategy1, y = strategy2, fill = overlap)) +
    geom_tile() +
    geom_text(aes(label = overlap), color = "white", size = 3) +
    scale_fill_gradient(low = "white", high = "red") +
    labs(
      title = "Matriz de Overlap entre Estrategias",
      x = "Estrategia 1",
      y = "Estrategia 2",
      fill = "Overlap"
    ) +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  ggsave("outputs/figures/filter_analysis/overlap_heatmap.png", p3, width = 10, height = 8, dpi = 300)
  
  cat("Visualizaciones guardadas en: outputs/figures/filter_analysis/\n")
}

# Ejecutar análisis
if (!interactive()) {
  main()
}
