#' Análisis Completo Simplificado de Datos miRNA - ALS vs Control
#' 
#' Este script realiza un análisis completo y organizado desde la caracterización inicial
#' hasta el análisis posicional de mutaciones G>T

# Load required libraries
library(dplyr)
library(ggplot2)
library(tidyr)
library(stringr)
library(purrr)
library(scales)

#' Función principal para análisis completo simplificado
run_simple_comprehensive_analysis <- function() {
  cat("=== ANÁLISIS COMPLETO SIMPLIFICADO DE DATOS miRNA - ALS vs CONTROL ===\n")
  
  # Cargar datos
  source("R/load_mirna_data.R")
  mirna_data <- load_and_prepare_data()
  
  # Crear directorios de salida
  if (!dir.exists("outputs/figures")) dir.create("outputs/figures", recursive = TRUE)
  if (!dir.exists("outputs/tables")) dir.create("outputs/tables", recursive = TRUE)
  if (!dir.exists("outputs/data_analysis")) dir.create("outputs/data_analysis", recursive = TRUE)
  
  cat("\n=== 1. CARACTERIZACIÓN INICIAL DE DATOS ===\n")
  
  # Información básica del dataset
  cat("\n📊 INFORMACIÓN BÁSICA DEL DATASET:\n")
  cat("   - Total de mutaciones:", nrow(mirna_data$raw_data$mirna_info), "\n")
  cat("   - Total de muestras:", ncol(mirna_data$raw_data$count_matrix), "\n")
  cat("   - miRNAs únicos:", length(unique(rownames(mirna_data$raw_data$mirna_info))), "\n")
  cat("   - Tipos de mutación únicos:", length(unique(mirna_data$raw_data$mirna_info$mutation)), "\n")
  
  # Información de grupos
  sample_metadata <- mirna_data$raw_data$sample_metadata
  cat("\n👥 DISTRIBUCIÓN DE GRUPOS:\n")
  group_summary <- sample_metadata %>%
    group_by(group) %>%
    summarise(
      n_samples = n(),
      percentage = round(n() / nrow(sample_metadata) * 100, 2),
      .groups = "drop"
    )
  print(group_summary)
  
  # Análisis de cobertura
  cat("\n📈 ANÁLISIS DE COBERTURA:\n")
  count_matrix <- mirna_data$raw_data$count_matrix
  total_counts <- colSums(count_matrix, na.rm = TRUE)
  
  coverage_stats <- data.frame(
    sample_id = names(total_counts),
    total_reads = as.numeric(total_counts),
    stringsAsFactors = FALSE
  ) %>%
    left_join(sample_metadata, by = "sample_id") %>%
    group_by(group) %>%
    summarise(
      mean_reads = mean(total_reads, na.rm = TRUE),
      median_reads = median(total_reads, na.rm = TRUE),
      sd_reads = sd(total_reads, na.rm = TRUE),
      min_reads = min(total_reads, na.rm = TRUE),
      max_reads = max(total_reads, na.rm = TRUE),
      .groups = "drop"
    )
  print(coverage_stats)
  
  # Análisis de mutaciones
  cat("\n🧬 ANÁLISIS DE MUTACIONES:\n")
  mutation_info <- mirna_data$raw_data$mirna_info
  
  # Contar mutaciones por tipo
  mutation_counts <- mutation_info %>%
    group_by(mutation) %>%
    summarise(count = n(), .groups = "drop") %>%
    arrange(desc(count))
  
  cat("   - Top 10 mutaciones más frecuentes:\n")
  print(head(mutation_counts, 10))
  
  # Análisis de miRNAs (extraer de nombres de filas)
  mirna_names <- rownames(mutation_info)
  mirna_counts <- data.frame(
    miRNA = mirna_names,
    stringsAsFactors = FALSE
  ) %>%
    group_by(miRNA) %>%
    summarise(n_mutations = n(), .groups = "drop") %>%
    arrange(desc(n_mutations))
  
  cat("\n   - Top 10 miRNAs con más mutaciones:\n")
  print(head(mirna_counts, 10))
  
  cat("\n=== 2. ANÁLISIS DE LIMPIEZA DE DATOS ===\n")
  
  # Comparar datos antes y después del filtrado
  raw_data <- mirna_data$raw_data
  filtered_data <- mirna_data$filtered_data
  
  cat("\n🔄 COMPARACIÓN ANTES Y DESPUÉS DEL FILTRADO:\n")
  
  # Estadísticas de cobertura
  raw_coverage <- colSums(raw_data$count_matrix, na.rm = TRUE)
  filtered_coverage <- colSums(filtered_data$count_matrix, na.rm = TRUE)
  
  coverage_comparison <- data.frame(
    sample_id = names(raw_coverage),
    raw_reads = as.numeric(raw_coverage),
    filtered_reads = as.numeric(filtered_coverage),
    stringsAsFactors = FALSE
  ) %>%
    mutate(
      reads_retained = filtered_reads / raw_reads * 100,
      reads_lost = raw_reads - filtered_reads
    ) %>%
    left_join(raw_data$sample_metadata, by = "sample_id")
  
  # Resumen por grupo
  cleaning_summary <- coverage_comparison %>%
    group_by(group) %>%
    summarise(
      mean_reads_retained = mean(reads_retained, na.rm = TRUE),
      median_reads_retained = median(reads_retained, na.rm = TRUE),
      mean_reads_lost = mean(reads_lost, na.rm = TRUE),
      .groups = "drop"
    )
  
  cat("   - Porcentaje de reads retenidos por grupo:\n")
  print(cleaning_summary)
  
  # Análisis de valores cero
  raw_zeros <- sum(raw_data$count_matrix == 0, na.rm = TRUE)
  filtered_zeros <- sum(filtered_data$count_matrix == 0, na.rm = TRUE)
  total_values <- length(raw_data$count_matrix)
  
  cat("\n📊 ANÁLISIS DE VALORES CERO:\n")
  cat("   - Valores cero en datos crudos:", raw_zeros, "(", round(raw_zeros/total_values*100, 2), "%)\n")
  cat("   - Valores cero en datos filtrados:", filtered_zeros, "(", round(filtered_zeros/total_values*100, 2), "%)\n")
  
  cat("\n=== 3. ANÁLISIS DE MUTACIONES G>T ===\n")
  
  gt_analysis <- mirna_data$gt_analysis
  
  # Estadísticas básicas de G>T
  cat("\n🔬 ESTADÍSTICAS BÁSICAS DE MUTACIONES G>T:\n")
  cat("   - Total de mutaciones G>T:", nrow(gt_analysis$gt_mutations), "\n")
  cat("   - Muestras con mutaciones G>T:", sum(colSums(gt_analysis$gt_count_matrix) > 0), "\n")
  
  # Análisis por grupo - usar la columna group correcta
  gt_summary <- gt_analysis$gt_summary %>%
    left_join(sample_metadata, by = "sample_id")
  
  # Verificar columnas disponibles
  cat("   - Columnas en gt_summary:", names(gt_summary), "\n")
  
  # Usar la columna group correcta (puede ser group.x o group.y)
  group_col <- if("group.x" %in% names(gt_summary)) "group.x" else "group"
  
  group_gt_stats <- gt_summary %>%
    group_by(!!sym(group_col)) %>%
    summarise(
      n_samples = n(),
      samples_with_gt = sum(gt_count > 0),
      mean_gt_count = mean(gt_count, na.rm = TRUE),
      median_gt_count = median(gt_count, na.rm = TRUE),
      sd_gt_count = sd(gt_count, na.rm = TRUE),
      .groups = "drop"
    )
  
  cat("\n📊 ESTADÍSTICAS G>T POR GRUPO:\n")
  print(group_gt_stats)
  
  # Análisis de miRNAs con más mutaciones G>T
  gt_mirna_stats <- gt_analysis$gt_mutations %>%
    group_by(mirna_name) %>%
    summarise(n_gt_mutations = n(), .groups = "drop") %>%
    arrange(desc(n_gt_mutations))
  
  cat("\n🧬 TOP 10 miRNAs CON MÁS MUTACIONES G>T:\n")
  print(head(gt_mirna_stats, 10))
  
  cat("\n=== 4. ANÁLISIS POSICIONAL DE MUTACIONES G>T ===\n")
  
  # Extraer posiciones de las mutaciones
  extract_positions <- function(mutation_string) {
    if (grepl("^[0-9]+:", mutation_string)) {
      pos <- as.numeric(gsub(":.*", "", mutation_string))
      mut_type <- gsub("^[0-9]+:", "", mutation_string)
      return(data.frame(position = pos, mutation_type = mut_type))
    } else if (grepl(",", mutation_string)) {
      parts <- strsplit(mutation_string, ",")[[1]]
      positions <- map_dfr(parts, function(part) {
        if (grepl(":", part)) {
          pos <- as.numeric(gsub(":.*", "", part))
          mut_type <- gsub("^[0-9]+:", "", part)
          return(data.frame(position = pos, mutation_type = mut_type))
        }
        return(data.frame(position = NA, mutation_type = NA))
      })
      return(positions[!is.na(positions$position), ])
    }
    return(data.frame(position = NA, mutation_type = NA))
  }
  
  # Extraer posiciones para todas las mutaciones G>T
  position_data <- map_dfr(1:nrow(gt_analysis$gt_mutations), function(i) {
    positions <- extract_positions(gt_analysis$gt_mutations$mutation[i])
    if (nrow(positions) > 0) {
      positions$miRNA <- gt_analysis$gt_mutations$mirna_name[i]
      positions$mutation_string <- gt_analysis$gt_mutations$mutation[i]
      return(positions)
    }
    return(data.frame(position = NA, mutation_type = NA, miRNA = gt_analysis$gt_mutations$mirna_name[i], 
                     mutation_string = gt_analysis$gt_mutations$mutation[i]))
  })
  
  # Remover filas con datos faltantes
  position_data <- position_data[!is.na(position_data$position), ]
  
  cat("\n📍 ESTADÍSTICAS POSICIONALES:\n")
  cat("   - Total de mutaciones G>T posicionales:", nrow(position_data), "\n")
  cat("   - Posiciones únicas:", length(unique(position_data$position)), "\n")
  cat("   - Rango de posiciones:", min(position_data$position), "-", max(position_data$position), "\n")
  
  # Análisis por posición
  position_stats <- position_data %>%
    group_by(position) %>%
    summarise(
      n_mutations = n(),
      n_mirnas = length(unique(miRNA)),
      .groups = "drop"
    ) %>%
    arrange(desc(n_mutations))
  
  cat("\n🎯 TOP 10 POSICIONES CON MÁS MUTACIONES G>T:\n")
  print(head(position_stats, 10))
  
  # Análisis de región seed
  position_stats$is_seed_region <- position_stats$position >= 2 & position_stats$position <= 8
  
  seed_analysis <- position_stats %>%
    group_by(is_seed_region) %>%
    summarise(
      total_mutations = sum(n_mutations),
      mean_mutations_per_position = mean(n_mutations),
      .groups = "drop"
    )
  
  cat("\n🌱 ANÁLISIS DE REGIÓN SEED (posiciones 2-8):\n")
  print(seed_analysis)
  
  cat("\n=== 5. CREANDO VISUALIZACIONES ===\n")
  
  # 1. Distribución de grupos
  p1 <- ggplot(group_summary, aes(x = group, y = n_samples, fill = group)) +
    geom_bar(stat = "identity", alpha = 0.8) +
    geom_text(aes(label = paste0(n_samples, " (", percentage, "%)")), 
              vjust = -0.5, size = 4) +
    labs(
      title = "Distribución de Muestras por Grupo",
      x = "Grupo",
      y = "Número de Muestras",
      fill = "Grupo"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      legend.position = "none"
    ) +
    scale_fill_manual(values = c("ALS" = "#1f77b4", "Control" = "#ff7f0e"))
  
  ggsave("outputs/figures/01_group_distribution.png", p1, width = 8, height = 6, dpi = 300)
  
  # 2. Distribución de cobertura
  p2 <- ggplot(coverage_comparison, aes(x = group, y = raw_reads, fill = group)) +
    geom_boxplot(alpha = 0.7) +
    scale_y_log10(labels = comma_format()) +
    labs(
      title = "Distribución de Cobertura por Grupo (Datos Crudos)",
      x = "Grupo",
      y = "Total de Reads (log10)",
      fill = "Grupo"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      legend.position = "none"
    ) +
    scale_fill_manual(values = c("ALS" = "#1f77b4", "Control" = "#ff7f0e"))
  
  ggsave("outputs/figures/02_coverage_distribution.png", p2, width = 8, height = 6, dpi = 300)
  
  # 3. Comparación antes/después del filtrado
  p3 <- ggplot(coverage_comparison, aes(x = raw_reads, y = filtered_reads, color = group)) +
    geom_point(alpha = 0.6) +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "red") +
    scale_x_log10(labels = comma_format()) +
    scale_y_log10(labels = comma_format()) +
    labs(
      title = "Comparación de Cobertura: Antes vs Después del Filtrado",
      x = "Reads Crudos (log10)",
      y = "Reads Filtrados (log10)",
      color = "Grupo"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold")
    ) +
    scale_color_manual(values = c("ALS" = "#1f77b4", "Control" = "#ff7f0e"))
  
  ggsave("outputs/figures/03_filtering_comparison.png", p3, width = 10, height = 6, dpi = 300)
  
  # 4. Distribución de mutaciones G>T por grupo
  p4 <- ggplot(group_gt_stats, aes(x = !!sym(group_col), y = mean_gt_count, fill = !!sym(group_col))) +
    geom_bar(stat = "identity", alpha = 0.8) +
    geom_errorbar(aes(ymin = mean_gt_count - sd_gt_count, ymax = mean_gt_count + sd_gt_count),
                  width = 0.2) +
    labs(
      title = "Promedio de Mutaciones G>T por Grupo",
      x = "Grupo",
      y = "Promedio de Mutaciones G>T",
      fill = "Grupo"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      legend.position = "none"
    ) +
    scale_fill_manual(values = c("ALS" = "#1f77b4", "Control" = "#ff7f0e"))
  
  ggsave("outputs/figures/04_gt_mutations_by_group.png", p4, width = 8, height = 6, dpi = 300)
  
  # 5. Distribución de mutaciones por posición
  p5 <- ggplot(position_stats, aes(x = position, y = n_mutations)) +
    geom_bar(stat = "identity", fill = "#2ca02c", alpha = 0.8) +
    geom_vline(xintercept = c(2, 8), linetype = "dashed", color = "red", alpha = 0.7) +
    annotate("text", x = 5, y = max(position_stats$n_mutations) * 0.9, 
             label = "Región Seed", color = "red", size = 4) +
    labs(
      title = "Distribución de Mutaciones G>T por Posición",
      subtitle = "Líneas rojas indican la región seed (posiciones 2-8)",
      x = "Posición en miRNA",
      y = "Número de Mutaciones"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      plot.subtitle = element_text(size = 12)
    )
  
  ggsave("outputs/figures/05_mutations_by_position.png", p5, width = 12, height = 6, dpi = 300)
  
  # 6. Comparación región seed vs no-seed
  p6 <- ggplot(seed_analysis, aes(x = is_seed_region, y = total_mutations, fill = is_seed_region)) +
    geom_bar(stat = "identity", alpha = 0.8) +
    scale_x_discrete(labels = c("FALSE" = "No-Seed", "TRUE" = "Seed")) +
    labs(
      title = "Mutaciones G>T: Región Seed vs No-Seed",
      x = "Región",
      y = "Total de Mutaciones",
      fill = "Región"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      legend.position = "none"
    ) +
    scale_fill_manual(values = c("FALSE" = "#ff7f0e", "TRUE" = "#1f77b4"))
  
  ggsave("outputs/figures/06_seed_vs_nonseed.png", p6, width = 8, height = 6, dpi = 300)
  
  cat("\n=== 6. GUARDANDO RESULTADOS ===\n")
  
  # Guardar tablas
  write.csv(group_summary, "outputs/tables/group_summary.csv", row.names = FALSE)
  write.csv(coverage_comparison, "outputs/tables/coverage_comparison.csv", row.names = FALSE)
  write.csv(group_gt_stats, "outputs/tables/gt_stats_by_group.csv", row.names = FALSE)
  write.csv(position_stats, "outputs/tables/positional_stats.csv", row.names = FALSE)
  write.csv(seed_analysis, "outputs/tables/seed_analysis.csv", row.names = FALSE)
  write.csv(mutation_counts, "outputs/tables/mutation_type_counts.csv", row.names = FALSE)
  write.csv(gt_mirna_stats, "outputs/tables/gt_mirna_stats.csv", row.names = FALSE)
  
  cat("\n=== RESUMEN FINAL ===\n")
  cat("📊 Análisis completado exitosamente!\n")
  cat("📁 Resultados guardados en:\n")
  cat("   - Gráficos: outputs/figures/\n")
  cat("   - Tablas: outputs/tables/\n")
  cat("📈 Total de gráficos generados: 6\n")
  cat("📋 Total de tablas generadas: 7\n")
  
  # Crear reporte de resumen
  create_summary_report(group_summary, coverage_stats, group_gt_stats, position_stats, seed_analysis, gt_analysis)
  
  return(list(
    group_summary = group_summary,
    coverage_stats = coverage_stats,
    group_gt_stats = group_gt_stats,
    position_stats = position_stats,
    seed_analysis = seed_analysis
  ))
}

#' Crear reporte de resumen
create_summary_report <- function(group_summary, coverage_stats, group_gt_stats, position_stats, seed_analysis, gt_analysis) {
  cat("\n📝 Creando reporte de resumen...\n")
  
  report_content <- paste0(
    "# Análisis Completo de Datos miRNA - ALS vs Control\n\n",
    "## Resumen Ejecutivo\n\n",
    "Este reporte presenta un análisis completo de los datos de mutaciones miRNA ",
    "comparando muestras de pacientes con ALS versus controles.\n\n",
    "## Hallazgos Principales\n\n",
    "### 1. Distribución de Muestras\n",
    "- **Total de muestras**: ", sum(group_summary$n_samples), "\n",
    "- **Muestras ALS**: ", group_summary$n_samples[group_summary$group == "ALS"], " (", 
    group_summary$percentage[group_summary$group == "ALS"], "%)\n",
    "- **Muestras Control**: ", group_summary$n_samples[group_summary$group == "Control"], " (", 
    group_summary$percentage[group_summary$group == "Control"], "%)\n\n",
    "### 2. Análisis de Mutaciones G>T\n",
    "- **Total de mutaciones G>T**: ", nrow(gt_analysis$gt_mutations), "\n",
    "- **Promedio ALS**: ", round(group_gt_stats$mean_gt_count[group_gt_stats$group.x == "ALS"], 2), "\n",
    "- **Promedio Control**: ", round(group_gt_stats$mean_gt_count[group_gt_stats$group.x == "Control"], 2), "\n\n",
    "### 3. Análisis Posicional\n",
    "- **Posiciones únicas con mutaciones G>T**: ", length(unique(position_stats$position)), "\n",
    "- **Rango de posiciones**: ", min(position_stats$position), "-", max(position_stats$position), "\n",
    "- **Mutaciones en región seed**: ", seed_analysis$total_mutations[seed_analysis$is_seed_region == TRUE], "\n",
    "- **Mutaciones fuera de región seed**: ", seed_analysis$total_mutations[seed_analysis$is_seed_region == FALSE], "\n\n",
    "## Archivos Generados\n\n",
    "### Gráficos (outputs/figures/)\n",
    "1. `01_group_distribution.png` - Distribución de muestras por grupo\n",
    "2. `02_coverage_distribution.png` - Distribución de cobertura por grupo\n",
    "3. `03_filtering_comparison.png` - Comparación antes/después del filtrado\n",
    "4. `04_gt_mutations_by_group.png` - Mutaciones G>T por grupo\n",
    "5. `05_mutations_by_position.png` - Distribución por posición\n",
    "6. `06_seed_vs_nonseed.png` - Comparación región seed\n\n",
    "### Tablas (outputs/tables/)\n",
    "1. `group_summary.csv` - Resumen por grupo\n",
    "2. `coverage_comparison.csv` - Comparación de cobertura\n",
    "3. `gt_stats_by_group.csv` - Estadísticas G>T por grupo\n",
    "4. `positional_stats.csv` - Estadísticas por posición\n",
    "5. `seed_analysis.csv` - Análisis de región seed\n",
    "6. `mutation_type_counts.csv` - Conteos por tipo de mutación\n",
    "7. `gt_mirna_stats.csv` - Estadísticas G>T por miRNA\n\n",
    "## Próximos Pasos Recomendados\n\n",
    "1. **Análisis estadístico detallado**: Realizar pruebas estadísticas para comparar grupos\n",
    "2. **Análisis funcional**: Evaluar el impacto funcional de las mutaciones en región seed\n",
    "3. **Análisis longitudinal**: Si hay datos temporales, analizar cambios a lo largo del tiempo\n",
    "4. **Validación experimental**: Confirmar hallazgos con experimentos adicionales\n\n",
    "---\n",
    "*Reporte generado automáticamente el ", Sys.Date(), "*\n"
  )
  
  writeLines(report_content, "outputs/data_analysis/comprehensive_analysis_report.md")
  cat("   - Reporte guardado en: outputs/data_analysis/comprehensive_analysis_report.md\n")
}

# Ejecutar análisis si se llama directamente
if (!interactive()) {
  results <- run_simple_comprehensive_analysis()
}
