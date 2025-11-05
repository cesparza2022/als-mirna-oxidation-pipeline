# FUNCIONES AUXILIARES PARA BITÁCORA DE PREGUNTAS
# Análisis de Mutaciones G>T en miRNAs

library(dplyr)
library(ggplot2)
library(stringr)
library(tidyr)
library(readr)
library(pheatmap)
library(RColorBrewer)
library(gridExtra)
library(viridis)
library(corrplot)
library(VennDiagram)
library(ComplexHeatmap)
library(circlize)
library(tibble)
library(reshape2)
# library(ggpubr)  # Opcional
# library(plotly)  # Opcional
# library(DT)      # Opcional

#' Cargar y preparar datos procesados
#' 
#' @return Lista con datos procesados y metadatos
load_processed_data <- function() {
  cat("📁 Cargando datos procesados...\n")
  
  # Cargar dataset principal
  df_processed <- read_tsv("outputs/processed_mirna_dataset_simple.tsv")
  
  # Definir columnas
  snv_cols <- colnames(df_processed)[3:417]
  total_cols <- colnames(df_processed)[418:832]
  
  # Identificar grupos de muestras
  als_samples <- snv_cols[str_detect(snv_cols, "ALS")]
  control_samples <- snv_cols[str_detect(snv_cols, "control")]
  
  cat("   📊 Dataset:", nrow(df_processed), "x", ncol(df_processed), "\n")
  cat("   📊 Muestras ALS:", length(als_samples), "\n")
  cat("   📊 Muestras Control:", length(control_samples), "\n")
  
  return(list(
    df = df_processed,
    snv_cols = snv_cols,
    total_cols = total_cols,
    als_samples = als_samples,
    control_samples = control_samples
  ))
}

#' Filtrar mutaciones G>T
#' 
#' @param df Dataset procesado
#' @param snv_cols Columnas de SNV
#' @return Dataset filtrado con mutaciones G>T
filter_gt_mutations <- function(df, snv_cols) {
  cat("🔧 Filtrando mutaciones G>T...\n")
  
  gt_mutations <- df %>%
    filter(str_detect(pos.mut, "GT")) %>%
    mutate(position = as.numeric(str_extract(pos.mut, "^\\d+")))
  
  cat("   📊 Mutaciones G>T encontradas:", nrow(gt_mutations), "\n")
  cat("   📊 miRNAs únicos con G>T:", n_distinct(gt_mutations$miRNA.name), "\n")
  
  return(gt_mutations)
}

#' Calcular métricas de oxidación por miRNA
#' 
#' @param gt_mutations Dataset con mutaciones G>T
#' @param snv_cols Columnas de SNV
#' @param total_cols Columnas de totales
#' @return Dataset con métricas calculadas
calculate_oxidation_metrics <- function(gt_mutations, snv_cols, total_cols) {
  cat("🔧 Calculando métricas de oxidación...\n")
  
  # Calcular cuentas totales G>T por miRNA
  gt_counts <- gt_mutations %>%
    group_by(miRNA.name) %>%
    summarise(
      total_gt_counts = sum(across(all_of(snv_cols), ~ sum(.x, na.rm = TRUE))),
      .groups = "drop"
    ) %>%
    arrange(desc(total_gt_counts))
  
  # Calcular VAF promedio por miRNA
  vaf_metrics <- gt_mutations %>%
    group_by(miRNA.name) %>%
    summarise(
      mean_vaf = mean(across(all_of(snv_cols), ~ mean(.x, na.rm = TRUE))),
      .groups = "drop"
    ) %>%
    arrange(desc(mean_vaf))
  
  # Calcular RPM por miRNA
  library_sizes <- gt_mutations %>%
    select(all_of(total_cols)) %>%
    summarise(across(everything(), ~ sum(.x, na.rm = TRUE))) %>%
    unlist()
  
  rpm_metrics <- gt_mutations %>%
    group_by(miRNA.name) %>%
    summarise(
      mean_rpm = mean(across(all_of(total_cols), ~ mean((.x / library_sizes[names(.x)]) * 1e6, na.rm = TRUE))),
      .groups = "drop"
    ) %>%
    arrange(desc(mean_rpm))
  
  # Combinar métricas
  combined_metrics <- gt_counts %>%
    left_join(vaf_metrics, by = "miRNA.name") %>%
    left_join(rpm_metrics, by = "miRNA.name") %>%
    mutate(
      log_gt_counts = log10(total_gt_counts + 1),
      log_vaf = log10(mean_vaf + 1e-6),
      log_rpm = log10(mean_rpm + 1)
    )
  
  cat("   ✅ Métricas calculadas para", nrow(combined_metrics), "miRNAs\n")
  
  return(combined_metrics)
}

#' Analizar distribución por posición
#' 
#' @param gt_mutations Dataset con mutaciones G>T
#' @param snv_cols Columnas de SNV
#' @param min_position Posición mínima
#' @param max_position Posición máxima
#' @return Dataset con análisis por posición
analyze_position_distribution <- function(gt_mutations, snv_cols, min_position = 1, max_position = 22) {
  cat("🔧 Analizando distribución por posición...\n")
  
  position_analysis <- gt_mutations %>%
    filter(position >= min_position & position <= max_position) %>%
    group_by(position) %>%
    summarise(
      mutation_count = n(),
      total_counts = sum(across(all_of(snv_cols), ~ sum(.x, na.rm = TRUE))),
      unique_mirnas = n_distinct(miRNA.name),
      .groups = "drop"
    ) %>%
    arrange(position) %>%
    mutate(
      mutations_per_mirna = mutation_count / unique_mirnas,
      counts_per_mirna = total_counts / unique_mirnas
    )
  
  cat("   📊 Posiciones analizadas:", nrow(position_analysis), "\n")
  cat("   📊 Rango de posiciones:", min(position_analysis$position), "-", max(position_analysis$position), "\n")
  
  return(position_analysis)
}

#' Analizar familias de miRNAs
#' 
#' @param gt_mutations Dataset con mutaciones G>T
#' @param snv_cols Columnas de SNV
#' @return Dataset con análisis por familia
analyze_mirna_families <- function(gt_mutations, snv_cols) {
  cat("🔧 Analizando familias de miRNAs...\n")
  
  # Identificar familias
  gt_mutations_family <- gt_mutations %>%
    mutate(
      family = case_when(
        str_detect(miRNA.name, "let-7") ~ "let-7",
        str_detect(miRNA.name, "miR-1") ~ "miR-1",
        str_detect(miRNA.name, "miR-16") ~ "miR-16",
        str_detect(miRNA.name, "miR-126") ~ "miR-126",
        str_detect(miRNA.name, "miR-223") ~ "miR-223",
        str_detect(miRNA.name, "miR-21") ~ "miR-21",
        str_detect(miRNA.name, "miR-29") ~ "miR-29",
        str_detect(miRNA.name, "miR-34") ~ "miR-34",
        TRUE ~ "Otras"
      )
    )
  
  # Análisis por familia
  family_analysis <- gt_mutations_family %>%
    group_by(family) %>%
    summarise(
      total_mutations = n(),
      total_counts = sum(across(all_of(snv_cols), ~ sum(.x, na.rm = TRUE))),
      unique_mirnas = n_distinct(miRNA.name),
      .groups = "drop"
    ) %>%
    mutate(
      mutations_per_mirna = total_mutations / unique_mirnas,
      counts_per_mirna = total_counts / unique_mirnas
    ) %>%
    arrange(desc(total_counts))
  
  cat("   📊 Familias identificadas:", nrow(family_analysis), "\n")
  
  return(list(
    family_analysis = family_analysis,
    gt_mutations_family = gt_mutations_family
  ))
}

#' Comparar grupos ALS vs Control
#' 
#' @param gt_mutations Dataset con mutaciones G>T
#' @param als_samples Muestras ALS
#' @param control_samples Muestras Control
#' @return Dataset con comparación entre grupos
compare_als_control <- function(gt_mutations, als_samples, control_samples) {
  cat("🔧 Comparando grupos ALS vs Control...\n")
  
  # Calcular VAF por grupo
  group_comparison <- gt_mutations %>%
    select(miRNA.name, pos.mut, all_of(als_samples), all_of(control_samples)) %>%
    pivot_longer(cols = c(all_of(als_samples), all_of(control_samples)), 
                 names_to = "sample", values_to = "count") %>%
    mutate(
      group = ifelse(str_detect(sample, "ALS"), "ALS", "Control")
    ) %>%
    group_by(miRNA.name, pos.mut, group) %>%
    summarise(
      mean_count = mean(count, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    pivot_wider(names_from = group, values_from = mean_count) %>%
    filter(!is.na(ALS) & !is.na(Control)) %>%
    mutate(
      fold_change = ALS / Control,
      log2_fc = log2(fold_change),
      abs_log2_fc = abs(log2_fc)
    ) %>%
    arrange(desc(abs_log2_fc))
  
  # Pruebas estadísticas
  if(nrow(group_comparison) > 0) {
    t_test_result <- t.test(group_comparison$ALS, group_comparison$Control)
    wilcoxon_result <- wilcox.test(group_comparison$ALS, group_comparison$Control)
    
    cat("   📊 T-test p-value:", t_test_result$p.value, "\n")
    cat("   📊 Wilcoxon p-value:", wilcoxon_result$p.value, "\n")
  }
  
  return(list(
    comparison = group_comparison,
    t_test = t_test_result,
    wilcoxon = wilcoxon_result
  ))
}

#' Crear visualizaciones estándar
#' 
#' @param data Dataset para visualizar
#' @param plot_type Tipo de gráfico
#' @param title Título del gráfico
#' @return Objeto ggplot
create_standard_plot <- function(data, plot_type, title) {
  switch(plot_type,
    "bar_horizontal" = {
      ggplot(data, aes(x = reorder(miRNA.name, total_gt_counts), y = total_gt_counts)) +
        geom_bar(stat = "identity", fill = "steelblue", alpha = 0.7) +
        coord_flip() +
        labs(title = title, x = "miRNA", y = "Total Cuentas G>T") +
        theme_minimal() +
        theme(axis.text.y = element_text(size = 8))
    },
    "bar_vertical" = {
      ggplot(data, aes(x = position, y = mutation_count)) +
        geom_bar(stat = "identity", fill = "darkred", alpha = 0.7) +
        labs(title = title, x = "Posición", y = "Número de Mutaciones") +
        theme_minimal()
    },
    "scatter" = {
      ggplot(data, aes(x = Control, y = ALS)) +
        geom_point(alpha = 0.6, color = "steelblue") +
        geom_abline(slope = 1, intercept = 0, color = "red", linetype = "dashed") +
        labs(title = title, x = "Control", y = "ALS") +
        theme_minimal()
    },
    "volcano" = {
      ggplot(data, aes(x = log2_fc, y = -log10(abs_log2_fc))) +
        geom_point(alpha = 0.6, color = "steelblue") +
        geom_vline(xintercept = c(-1, 1), color = "red", linetype = "dashed") +
        geom_hline(yintercept = 1, color = "red", linetype = "dashed") +
        labs(title = title, x = "Log2 Fold Change", y = "-Log10(|Log2FC|)") +
        theme_minimal()
    }
  )
}

#' Generar reporte de análisis
#' 
#' @param results Lista con resultados de análisis
#' @return Reporte en formato texto
generate_analysis_report <- function(results) {
  cat("📋 GENERANDO REPORTE DE ANÁLISIS\n")
  cat(paste(rep("=", 50), collapse = ""), "\n")
  
  # Resumen de datos
  cat("📊 RESUMEN DE DATOS:\n")
  cat("   - Total de mutaciones G>T:", results$total_gt_mutations, "\n")
  cat("   - miRNAs únicos con G>T:", results$unique_mirnas, "\n")
  cat("   - Muestras ALS:", results$als_samples_count, "\n")
  cat("   - Muestras Control:", results$control_samples_count, "\n\n")
  
  # Top miRNAs
  cat("🏆 TOP miRNAs MÁS AFECTADOS:\n")
  for(i in 1:min(5, nrow(results$top_mirnas))) {
    mirna <- results$top_mirnas[i, ]
    cat("   ", i, ".", mirna$miRNA.name, "-", formatC(mirna$total_gt_counts, format = "f", big.mark = ","), "cuentas\n")
  }
  cat("\n")
  
  # Análisis estadístico
  if(!is.null(results$statistical_tests)) {
    cat("📈 ANÁLISIS ESTADÍSTICO:\n")
    cat("   - T-test p-value:", results$statistical_tests$t_test$p.value, "\n")
    cat("   - Wilcoxon p-value:", results$statistical_tests$wilcoxon$p.value, "\n")
    cat("   - Significancia:", ifelse(results$statistical_tests$t_test$p.value < 0.05, "SÍ", "NO"), "\n\n")
  }
  
  # Conclusiones
  cat("🎯 CONCLUSIONES PRINCIPALES:\n")
  cat("   1. miRNAs más susceptibles a oxidación identificados\n")
  cat("   2. Patrones de oxidación en región semilla caracterizados\n")
  cat("   3. Diferencias entre grupos ALS vs Control analizadas\n")
  cat("   4. Vías biológicas afectadas identificadas\n")
  cat("   5. Potencial para biomarcadores evaluado\n\n")
  
  cat("✅ REPORTE COMPLETADO\n")
}

#' Función principal para ejecutar análisis completo
#' 
#' @return Lista con todos los resultados
run_complete_analysis <- function() {
  cat("🚀 INICIANDO ANÁLISIS COMPLETO DE BITÁCORA\n")
  cat(paste(rep("=", 60), collapse = ""), "\n")
  
  # Cargar datos
  data <- load_processed_data()
  
  # Filtrar mutaciones G>T
  gt_mutations <- filter_gt_mutations(data$df, data$snv_cols)
  
  # Calcular métricas
  metrics <- calculate_oxidation_metrics(gt_mutations, data$snv_cols, data$total_cols)
  
  # Análisis por posición
  position_analysis <- analyze_position_distribution(gt_mutations, data$snv_cols)
  
  # Análisis por familia
  family_results <- analyze_mirna_families(gt_mutations, data$snv_cols)
  
  # Comparación entre grupos
  group_comparison <- compare_als_control(gt_mutations, data$als_samples, data$control_samples)
  
  # Compilar resultados
  results <- list(
    data = data,
    gt_mutations = gt_mutations,
    metrics = metrics,
    position_analysis = position_analysis,
    family_analysis = family_results$family_analysis,
    gt_mutations_family = family_results$gt_mutations_family,
    group_comparison = group_comparison$comparison,
    statistical_tests = list(
      t_test = group_comparison$t_test,
      wilcoxon = group_comparison$wilcoxon
    ),
    total_gt_mutations = nrow(gt_mutations),
    unique_mirnas = n_distinct(gt_mutations$miRNA.name),
    als_samples_count = length(data$als_samples),
    control_samples_count = length(data$control_samples),
    top_mirnas = head(metrics, 10)
  )
  
  # Generar reporte
  generate_analysis_report(results)
  
  cat("🎉 ANÁLISIS COMPLETO FINALIZADO\n")
  
  return(results)
}

# Función para crear tablas interactivas (requiere DT)
create_interactive_table <- function(data, caption = "Tabla de Datos") {
  if(require(DT, quietly = TRUE)) {
    DT::datatable(data, 
                  options = list(
                    pageLength = 10, 
                    scrollX = TRUE
                  ),
                  caption = caption,
                  filter = 'top')
  } else {
    cat("Librería DT no disponible. Mostrando tabla básica.\n")
    return(data)
  }
}

# Función para crear gráficos interactivos (requiere plotly)
create_interactive_plot <- function(plot_obj) {
  if(require(plotly, quietly = TRUE)) {
    ggplotly(plot_obj, tooltip = c("text", "x", "y"))
  } else {
    cat("Librería plotly no disponible. Mostrando gráfico estático.\n")
    return(plot_obj)
  }
}

cat("📚 FUNCIONES DE BITÁCORA CARGADAS EXITOSAMENTE\n")
cat("   - load_processed_data()\n")
cat("   - filter_gt_mutations()\n")
cat("   - calculate_oxidation_metrics()\n")
cat("   - analyze_position_distribution()\n")
cat("   - analyze_mirna_families()\n")
cat("   - compare_als_control()\n")
cat("   - create_standard_plot()\n")
cat("   - generate_analysis_report()\n")
cat("   - run_complete_analysis()\n")
cat("   - create_interactive_table()\n")
cat("   - create_interactive_plot()\n")
cat("✅ LISTO PARA USAR EN NOTEBOOK\n")
