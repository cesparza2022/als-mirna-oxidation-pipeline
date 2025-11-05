# ==============================================================================
# PASO 4A: ANÁLISIS DE SIGNIFICANCIA ESTADÍSTICA
# ==============================================================================

# Cargar librerías necesarias
library(tidyverse)
library(ggplot2)
library(gridExtra)
library(reshape2)
library(corrplot)
library(broom) # Para tidy de resultados estadísticos

# Cargar configuración y funciones
source("../config_pipeline.R")
source("functions_pipeline.R")

# Definir rutas de salida
output_figures_path <- file.path(config$output_paths$figures, "paso4a_significancia")
output_tables_path <- file.path(config$output_paths$outputs, "paso4a_significancia")

# Crear directorios si no existen
dir.create(output_figures_path, showWarnings = FALSE, recursive = TRUE)
dir.create(output_tables_path, showWarnings = FALSE, recursive = TRUE)

cat("=== PASO 4A: ANÁLISIS DE SIGNIFICANCIA ESTADÍSTICA ===\n")
cat("Fecha:", Sys.time(), "\n\n")

# =============================================================================
# 1. CARGA Y PROCESAMIENTO DE DATOS
# =============================================================================

cat("Cargando y procesando datos...\n")

# Cargar datos originales
raw_data <- read_tsv(config$data_paths$raw_data, col_types = cols(.default = "c"))

# Aplicar split-collapse
processed_data <- apply_split_collapse(raw_data)

# Calcular VAFs
vaf_data <- calculate_vafs(processed_data)

# Filtrar VAFs > 50%
filtered_data <- filter_high_vafs(vaf_data, threshold = 0.5)

cat("Datos procesados:\n")
cat("  - Raw data:", nrow(raw_data), "filas,", ncol(raw_data), "columnas\n")
cat("  - Processed data:", nrow(processed_data), "filas,", ncol(processed_data), "columnas\n")
cat("  - VAF data:", nrow(vaf_data), "filas,", ncol(vaf_data), "columnas\n")
cat("  - Filtered data:", nrow(filtered_data), "filas,", ncol(filtered_data), "columnas\n")

# =============================================================================
# 2. IDENTIFICACIÓN DE MUESTRAS POR GRUPO
# =============================================================================

cat("\nIdentificando muestras por grupo...\n")

# Identificar columnas de VAF y de cuentas
vaf_cols <- colnames(filtered_data)[str_detect(colnames(filtered_data), "^VAF_")]
meta_cols <- c("miRNA name", "pos:mut")
count_cols <- colnames(filtered_data)[!colnames(filtered_data) %in% meta_cols & !str_detect(colnames(filtered_data), "^VAF_")]

# Identificar muestras por grupo
als_samples_vaf <- vaf_cols[str_detect(vaf_cols, "ALS")]
control_samples_vaf <- vaf_cols[str_detect(vaf_cols, "Control|control")]

als_samples_count <- count_cols[str_detect(count_cols, "ALS")]
control_samples_count <- count_cols[str_detect(count_cols, "Control|control")]

cat("Muestras identificadas:\n")
cat("  - ALS:", length(als_samples_vaf), "muestras VAF,", length(als_samples_count), "muestras count\n")
cat("  - Control:", length(control_samples_vaf), "muestras VAF,", length(control_samples_count), "muestras count\n")

if (length(als_samples_vaf) == 0 || length(control_samples_vaf) == 0) {
  stop("No se encontraron suficientes muestras ALS o Control para el análisis estadístico.")
}

# =============================================================================
# 3. ANÁLISIS ESTADÍSTICO DE VAFs
# =============================================================================

cat("\nRealizando análisis estadístico de VAFs...\n")

# Preparar datos para análisis estadístico
vaf_statistical_data <- filtered_data %>%
  rowwise() %>%
  mutate(
    mean_vaf_als = mean(c_across(all_of(als_samples_vaf)), na.rm = TRUE),
    mean_vaf_control = mean(c_across(all_of(control_samples_vaf)), na.rm = TRUE),
    vaf_diff = mean_vaf_als - mean_vaf_control,
    vaf_ratio = ifelse(mean_vaf_control > 0, mean_vaf_als / mean_vaf_control, NA),
    # Calcular desviación estándar para cada grupo
    sd_vaf_als = sd(c_across(all_of(als_samples_vaf)), na.rm = TRUE),
    sd_vaf_control = sd(c_across(all_of(control_samples_vaf)), na.rm = TRUE),
    # Contar observaciones válidas
    n_als = sum(!is.na(c_across(all_of(als_samples_vaf)))),
    n_control = sum(!is.na(c_across(all_of(control_samples_vaf))))
  ) %>%
  ungroup() %>%
  filter(n_als >= 3 & n_control >= 3) %>% # Mínimo 3 observaciones por grupo
  select(`miRNA name`, `pos:mut`, mean_vaf_als, mean_vaf_control, vaf_diff, vaf_ratio, 
         sd_vaf_als, sd_vaf_control, n_als, n_control)

cat("SNVs con suficientes observaciones para análisis estadístico:", nrow(vaf_statistical_data), "\n")

# Realizar t-tests para cada SNV
cat("Realizando t-tests para cada SNV...\n")

t_test_results <- list()
for (i in 1:nrow(vaf_statistical_data)) {
  snv_data <- filtered_data[i, ]
  
  # Extraer VAFs para cada grupo
  als_vafs <- as.numeric(snv_data[als_samples_vaf])
  control_vafs <- as.numeric(snv_data[control_samples_vaf])
  
  # Remover NAs
  als_vafs <- als_vafs[!is.na(als_vafs)]
  control_vafs <- control_vafs[!is.na(control_vafs)]
  
  # Realizar t-test si hay suficientes observaciones
  if (length(als_vafs) >= 3 && length(control_vafs) >= 3) {
    tryCatch({
      t_result <- t.test(als_vafs, control_vafs)
      t_test_results[[i]] <- data.frame(
        miRNA_name = snv_data$`miRNA name`,
        pos_mut = snv_data$`pos:mut`,
        t_statistic = t_result$statistic,
        p_value = t_result$p.value,
        df = t_result$parameter,
        mean_als = mean(als_vafs),
        mean_control = mean(control_vafs),
        n_als = length(als_vafs),
        n_control = length(control_vafs)
      )
    }, error = function(e) {
      t_test_results[[i]] <- data.frame(
        miRNA_name = snv_data$`miRNA name`,
        pos_mut = snv_data$`pos:mut`,
        t_statistic = NA,
        p_value = NA,
        df = NA,
        mean_als = mean(als_vafs),
        mean_control = mean(control_vafs),
        n_als = length(als_vafs),
        n_control = length(control_vafs)
      )
    })
  }
}

# Combinar resultados
t_test_df <- do.call(rbind, t_test_results[!sapply(t_test_results, is.null)])

# Aplicar corrección FDR (Benjamini-Hochberg)
t_test_df$p_value_fdr <- p.adjust(t_test_df$p_value, method = "BH")

# Clasificar significancia
t_test_df$significance <- case_when(
  t_test_df$p_value_fdr < 0.001 ~ "***",
  t_test_df$p_value_fdr < 0.01 ~ "**",
  t_test_df$p_value_fdr < 0.05 ~ "*",
  TRUE ~ "ns"
)

write_csv(t_test_df, file.path(output_tables_path, "paso4a_t_test_results.csv"))
cat("Resultados de t-tests guardados en 'paso4a_t_test_results.csv'\n")

# Resumen de significancia
significance_summary <- t_test_df %>%
  group_by(significance) %>%
  summarise(
    n_snvs = n(),
    percentage = (n() / nrow(t_test_df)) * 100,
    .groups = "drop"
  ) %>%
  arrange(desc(n_snvs))

write_csv(significance_summary, file.path(output_tables_path, "paso4a_resumen_significancia.csv"))
cat("Resumen de significancia:\n")
print(significance_summary)

# =============================================================================
# 4. ANÁLISIS ESTADÍSTICO DE MUTACIONES G>T
# =============================================================================

cat("\nRealizando análisis estadístico de mutaciones G>T...\n")

# Filtrar solo mutaciones G>T
gt_data <- filtered_data %>%
  filter(str_detect(`pos:mut`, "G>T"))

if (nrow(gt_data) > 0) {
  # Análisis de conteos G>T por grupo
  gt_count_analysis <- gt_data %>%
    rowwise() %>%
    mutate(
      count_gt_als = sum(as.numeric(c_across(all_of(als_samples_count))), na.rm = TRUE),
      count_gt_control = sum(as.numeric(c_across(all_of(control_samples_count))), na.rm = TRUE),
      total_count_als = sum(as.numeric(c_across(all_of(als_samples_count))), na.rm = TRUE),
      total_count_control = sum(as.numeric(c_across(all_of(control_samples_count))), na.rm = TRUE)
    ) %>%
    ungroup() %>%
    filter(count_gt_als > 0 | count_gt_control > 0) # Solo SNVs con al menos un conteo

  # Realizar pruebas de chi-cuadrado para cada mutación G>T
  chi_square_results <- list()
  for (i in 1:nrow(gt_count_analysis)) {
    snv_data <- gt_count_analysis[i, ]
    
    # Crear tabla de contingencia
    contingency_table <- matrix(c(
      snv_data$count_gt_als, snv_data$count_gt_control,
      snv_data$total_count_als - snv_data$count_gt_als, 
      snv_data$total_count_control - snv_data$count_gt_control
    ), nrow = 2, byrow = TRUE)
    
    # Realizar chi-cuadrado si hay suficientes observaciones
    if (all(contingency_table >= 5)) {
      tryCatch({
        chi_result <- chisq.test(contingency_table)
        chi_square_results[[i]] <- data.frame(
          miRNA_name = snv_data$`miRNA name`,
          pos_mut = snv_data$`pos:mut`,
          chi_square = chi_result$statistic,
          p_value = chi_result$p.value,
          df = chi_result$parameter,
          count_gt_als = snv_data$count_gt_als,
          count_gt_control = snv_data$count_gt_control,
          total_als = snv_data$total_count_als,
          total_control = snv_data$total_count_control
        )
      }, error = function(e) {
        chi_square_results[[i]] <- data.frame(
          miRNA_name = snv_data$`miRNA name`,
          pos_mut = snv_data$`pos:mut`,
          chi_square = NA,
          p_value = NA,
          df = NA,
          count_gt_als = snv_data$count_gt_als,
          count_gt_control = snv_data$count_gt_control,
          total_als = snv_data$total_count_als,
          total_control = snv_data$total_count_control
        )
      })
    }
  }

  # Combinar resultados chi-cuadrado
  if (length(chi_square_results) > 0) {
    chi_square_df <- do.call(rbind, chi_square_results[!sapply(chi_square_results, is.null)])
    
    # Aplicar corrección FDR
    chi_square_df$p_value_fdr <- p.adjust(chi_square_df$p_value, method = "BH")
    
    # Clasificar significancia
    chi_square_df$significance <- case_when(
      chi_square_df$p_value_fdr < 0.001 ~ "***",
      chi_square_df$p_value_fdr < 0.01 ~ "**",
      chi_square_df$p_value_fdr < 0.05 ~ "*",
      TRUE ~ "ns"
    )
    
    write_csv(chi_square_df, file.path(output_tables_path, "paso4a_chi_square_gt_results.csv"))
    cat("Resultados de chi-cuadrado para G>T guardados en 'paso4a_chi_square_gt_results.csv'\n")
    
    # Resumen de significancia G>T
    gt_significance_summary <- chi_square_df %>%
      group_by(significance) %>%
      summarise(
        n_gt_mutations = n(),
        percentage = (n() / nrow(chi_square_df)) * 100,
        .groups = "drop"
      ) %>%
      arrange(desc(n_gt_mutations))
    
    write_csv(gt_significance_summary, file.path(output_tables_path, "paso4a_resumen_significancia_gt.csv"))
    cat("Resumen de significancia G>T:\n")
    print(gt_significance_summary)
  } else {
    cat("No se pudieron realizar pruebas chi-cuadrado para mutaciones G>T (insuficientes observaciones)\n")
  }
} else {
  cat("No se encontraron mutaciones G>T para análisis estadístico\n")
}

# =============================================================================
# 5. VISUALIZACIONES DE RESULTADOS ESTADÍSTICOS
# =============================================================================

cat("\nGenerando visualizaciones de resultados estadísticos...\n")

# 1. Volcano plot de t-tests
if (nrow(t_test_df) > 0) {
  p_volcano <- ggplot(t_test_df, aes(x = mean_als - mean_control, y = -log10(p_value_fdr))) +
    geom_point(aes(color = significance), alpha = 0.6) +
    geom_hline(yintercept = -log10(0.05), linetype = "dashed", color = "red") +
    geom_vline(xintercept = 0, linetype = "dashed", color = "gray") +
    scale_color_manual(values = c("***" = "red", "**" = "orange", "*" = "yellow", "ns" = "gray")) +
    labs(title = "Volcano Plot: Diferencias VAF entre ALS y Control",
         x = "Diferencia de VAF (ALS - Control)", 
         y = "-log10(p-value FDR)",
         color = "Significancia") +
    theme_minimal()
  
  ggsave(file.path(output_figures_path, "paso4a_volcano_plot_vafs.png"), p_volcano, width = 10, height = 8)
  cat("Volcano plot guardado en 'paso4a_volcano_plot_vafs.png'\n")
}

# 2. Distribución de p-values
if (nrow(t_test_df) > 0) {
  p_pvalue_dist <- ggplot(t_test_df, aes(x = p_value_fdr)) +
    geom_histogram(bins = 50, fill = "skyblue", alpha = 0.7) +
    geom_vline(xintercept = 0.05, linetype = "dashed", color = "red") +
    labs(title = "Distribución de P-values (FDR corregidos)",
         x = "P-value (FDR)", y = "Frecuencia") +
    theme_minimal()
  
  ggsave(file.path(output_figures_path, "paso4a_distribucion_pvalues.png"), p_pvalue_dist, width = 10, height = 6)
  cat("Distribución de p-values guardada en 'paso4a_distribucion_pvalues.png'\n")
}

# 3. Top SNVs más significativos
if (nrow(t_test_df) > 0) {
  top_significant <- t_test_df %>%
    filter(significance != "ns") %>%
    arrange(p_value_fdr) %>%
    head(20)
  
  if (nrow(top_significant) > 0) {
    p_top_significant <- ggplot(top_significant, aes(x = reorder(paste(`miRNA_name`, pos_mut, sep = "_"), -p_value_fdr), 
                                                    y = -log10(p_value_fdr))) +
      geom_col(aes(fill = significance)) +
      coord_flip() +
      scale_fill_manual(values = c("***" = "red", "**" = "orange", "*" = "yellow")) +
      labs(title = "Top 20 SNVs Más Significativos (ALS vs Control)",
           x = "SNV (miRNA_Posición:Mutación)", 
           y = "-log10(p-value FDR)",
           fill = "Significancia") +
      theme_minimal() +
      theme(axis.text.y = element_text(size = 8))
    
    ggsave(file.path(output_figures_path, "paso4a_top_significativos.png"), p_top_significant, width = 12, height = 8)
    cat("Top SNVs significativos guardados en 'paso4a_top_significativos.png'\n")
  }
}

# 4. Análisis de mutaciones G>T significativas
if (exists("chi_square_df") && nrow(chi_square_df) > 0) {
  gt_significant <- chi_square_df %>%
    filter(significance != "ns") %>%
    arrange(p_value_fdr)
  
  if (nrow(gt_significant) > 0) {
    p_gt_significant <- ggplot(gt_significant, aes(x = reorder(paste(`miRNA_name`, pos_mut, sep = "_"), -p_value_fdr), 
                                                  y = -log10(p_value_fdr))) +
      geom_col(aes(fill = significance)) +
      coord_flip() +
      scale_fill_manual(values = c("***" = "red", "**" = "orange", "*" = "yellow")) +
      labs(title = "Mutaciones G>T Significativas (ALS vs Control)",
           x = "SNV G>T (miRNA_Posición:Mutación)", 
           y = "-log10(p-value FDR)",
           fill = "Significancia") +
      theme_minimal() +
      theme(axis.text.y = element_text(size = 8))
    
    ggsave(file.path(output_figures_path, "paso4a_gt_significativos.png"), p_gt_significant, width = 12, height = 8)
    cat("Mutaciones G>T significativas guardadas en 'paso4a_gt_significativos.png'\n")
  }
}

cat("\n=== PASO 4A COMPLETADO ===\n")
cat("Archivos generados:\n")
cat("  - Tablas:", length(list.files(output_tables_path, pattern = "\\.csv$")), "archivos CSV\n")
cat("  - Figuras:", length(list.files(output_figures_path, pattern = "\\.png$")), "archivos PNG\n")
cat("  - Total SNVs analizados:", nrow(t_test_df), "\n")
cat("  - SNVs significativos:", sum(t_test_df$significance != "ns", na.rm = TRUE), "\n")
if (exists("chi_square_df")) {
  cat("  - Mutaciones G>T analizadas:", nrow(chi_square_df), "\n")
  cat("  - Mutaciones G>T significativas:", sum(chi_square_df$significance != "ns", na.rm = TRUE), "\n")
}








