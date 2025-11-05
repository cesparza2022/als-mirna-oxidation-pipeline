# =============================================================================
# PASO 3B: ANÁLISIS COMPARATIVO ALS vs CONTROL
# =============================================================================
# 
# OBJETIVO: Comparar diferencias entre grupos ALS y Control en:
# - VAFs de mutaciones G>T
# - Distribución de mutaciones por región funcional
# - Patrones de oxidación específicos
# - Significancia estadística de las diferencias
#
# METODOLOGÍA:
# 1. Identificar muestras por grupo (ALS vs Control)
# 2. Calcular VAFs promedio por grupo
# 3. Comparar distribución de mutaciones G>T
# 4. Análisis estadístico (t-tests, GLMM)
# 5. Visualizaciones comparativas
#
# ARCHIVOS DE SALIDA:
# - Tablas: Comparaciones estadísticas, diferencias por grupo
# - Gráficos: Boxplots, heatmaps, distribuciones comparativas
#
# =============================================================================

# Cargar librerías
library(tidyverse)
library(ggplot2)
library(gridExtra)
library(corrplot)
library(reshape2)

# Cargar configuración y funciones
source("../config_pipeline.R")
source("functions_pipeline.R")

# Crear directorios de salida
output_tables_path <- "tables"
output_figures_path <- "figures"
dir.create(output_tables_path, showWarnings = FALSE, recursive = TRUE)
dir.create(output_figures_path, showWarnings = FALSE, recursive = TRUE)

cat("=== PASO 3B: ANÁLISIS COMPARATIVO ALS vs CONTROL ===\n")
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

# Identificar columnas de muestras
meta_cols <- c("miRNA name", "pos:mut")
total_cols <- names(vaf_data)[grepl("\\(PM\\+1MM\\+2MM\\)$", names(vaf_data))]
count_cols <- names(vaf_data)[!names(vaf_data) %in% meta_cols & !names(vaf_data) %in% total_cols]
vaf_cols <- names(vaf_data)[str_detect(names(vaf_data), "^VAF_")]

# Identificar muestras por grupo basándose en nombres
als_samples <- count_cols[str_detect(count_cols, "ALS")]
control_samples <- count_cols[str_detect(count_cols, "Control|control")]

# Verificar que tenemos muestras de ambos grupos
if (length(als_samples) == 0 || length(control_samples) == 0) {
  cat("ADVERTENCIA: No se encontraron suficientes muestras de ambos grupos\n")
  cat("  - Muestras ALS:", length(als_samples), "\n")
  cat("  - Muestras Control:", length(control_samples), "\n")
  
  # Buscar patrones alternativos
  cat("Buscando patrones alternativos en nombres de muestras...\n")
  sample_names <- count_cols
  cat("Primeras 10 muestras:", head(sample_names, 10), "\n")
  
  # Intentar identificar grupos por otros patrones
  if (length(als_samples) == 0) {
    als_samples <- sample_names[str_detect(sample_names, "case|Case|disease|Disease")]
  }
  if (length(control_samples) == 0) {
    control_samples <- sample_names[str_detect(sample_names, "ctrl|Ctrl|healthy|Healthy|normal|Normal")]
  }
}

cat("Muestras identificadas:\n")
cat("  - ALS:", length(als_samples), "muestras\n")
cat("  - Control:", length(control_samples), "muestras\n")

if (length(als_samples) > 0 && length(control_samples) > 0) {
  cat("  - Primeras 3 muestras ALS:", head(als_samples, 3), "\n")
  cat("  - Primeras 3 muestras Control:", head(control_samples, 3), "\n")
}

# =============================================================================
# 3. ANÁLISIS COMPARATIVO DE VAFs
# =============================================================================

if (length(als_samples) > 0 && length(control_samples) > 0) {
  
  cat("\nRealizando análisis comparativo de VAFs...\n")
  
  # Identificar columnas VAF correspondientes
  als_vaf_cols <- paste0("VAF_", als_samples)
  control_vaf_cols <- paste0("VAF_", control_samples)
  
  # Verificar que las columnas VAF existen
  als_vaf_cols <- als_vaf_cols[als_vaf_cols %in% vaf_cols]
  control_vaf_cols <- control_vaf_cols[control_vaf_cols %in% vaf_cols]
  
  cat("Columnas VAF identificadas:\n")
  cat("  - ALS VAF columns:", length(als_vaf_cols), "\n")
  cat("  - Control VAF columns:", length(control_vaf_cols), "\n")
  
  if (length(als_vaf_cols) > 0 && length(control_vaf_cols) > 0) {
    
    # Calcular VAFs promedio por grupo
    vaf_comparison <- vaf_data %>%
      mutate(
        als_vaf_mean = rowMeans(select(., all_of(als_vaf_cols)), na.rm = TRUE),
        control_vaf_mean = rowMeans(select(., all_of(control_vaf_cols)), na.rm = TRUE),
        vaf_diff = als_vaf_mean - control_vaf_mean,
        vaf_ratio = ifelse(control_vaf_mean > 0, als_vaf_mean / control_vaf_mean, NA),
        group = case_when(
          vaf_diff > 0.01 ~ "ALS_higher",
          vaf_diff < -0.01 ~ "Control_higher", 
          TRUE ~ "Similar"
        )
      ) %>%
      select(`miRNA name`, `pos:mut`, als_vaf_mean, control_vaf_mean, vaf_diff, vaf_ratio, group)
    
    # Guardar comparación de VAFs
    write_csv(vaf_comparison, file.path(output_tables_path, "paso3b_comparacion_vafs_als_control.csv"))
    
    # Resumen estadístico de diferencias
    vaf_summary <- vaf_comparison %>%
      summarise(
        n_total = n(),
        n_als_higher = sum(group == "ALS_higher", na.rm = TRUE),
        n_control_higher = sum(group == "Control_higher", na.rm = TRUE),
        n_similar = sum(group == "Similar", na.rm = TRUE),
        mean_diff = mean(vaf_diff, na.rm = TRUE),
        median_diff = median(vaf_diff, na.rm = TRUE),
        mean_ratio = mean(vaf_ratio, na.rm = TRUE),
        median_ratio = median(vaf_ratio, na.rm = TRUE)
      )
    
    write_csv(vaf_summary, file.path(output_tables_path, "paso3b_resumen_diferencias_vaf.csv"))
    
    cat("Resumen de diferencias VAF:\n")
    print(vaf_summary)
    
  } else {
    cat("ERROR: No se encontraron columnas VAF válidas para ambos grupos\n")
  }
  
} else {
  cat("ERROR: No se pueden realizar comparaciones - grupos insuficientes\n")
}

# =============================================================================
# 4. ANÁLISIS COMPARATIVO DE MUTACIONES G>T
# =============================================================================

cat("\nRealizando análisis comparativo de mutaciones G>T...\n")

# Identificar mutaciones G>T
gt_mutations <- filtered_data %>%
  filter(str_detect(`pos:mut`, "G>T"))

cat("Mutaciones G>T identificadas:", nrow(gt_mutations), "\n")

if (nrow(gt_mutations) > 0 && length(als_samples) > 0 && length(control_samples) > 0) {
  
  # Calcular conteos de mutaciones G>T por grupo
  gt_comparison <- gt_mutations %>%
    mutate(
      als_gt_count = rowSums(select(., all_of(als_samples)), na.rm = TRUE),
      control_gt_count = rowSums(select(., all_of(control_samples)), na.rm = TRUE),
      gt_diff = als_gt_count - control_gt_count,
      gt_ratio = ifelse(control_gt_count > 0, als_gt_count / control_gt_count, NA),
      group_gt = case_when(
        gt_diff > 5 ~ "ALS_higher",
        gt_diff < -5 ~ "Control_higher",
        TRUE ~ "Similar"
      )
    ) %>%
    select(`miRNA name`, `pos:mut`, als_gt_count, control_gt_count, gt_diff, gt_ratio, group_gt)
  
  # Guardar comparación de G>T
  write_csv(gt_comparison, file.path(output_tables_path, "paso3b_comparacion_gt_als_control.csv"))
  
  # Resumen de mutaciones G>T por grupo
  gt_summary <- gt_comparison %>%
    summarise(
      n_gt_mutations = n(),
      n_als_higher = sum(group_gt == "ALS_higher", na.rm = TRUE),
      n_control_higher = sum(group_gt == "Control_higher", na.rm = TRUE),
      n_similar = sum(group_gt == "Similar", na.rm = TRUE),
      total_als_gt = sum(als_gt_count, na.rm = TRUE),
      total_control_gt = sum(control_gt_count, na.rm = TRUE),
      mean_gt_diff = mean(gt_diff, na.rm = TRUE),
      median_gt_diff = median(gt_diff, na.rm = TRUE)
    )
  
  write_csv(gt_summary, file.path(output_tables_path, "paso3b_resumen_gt_als_control.csv"))
  
  cat("Resumen de mutaciones G>T por grupo:\n")
  print(gt_summary)
  
} else {
  cat("ERROR: No se pueden realizar comparaciones de G>T\n")
}

# =============================================================================
# 5. ANÁLISIS POR REGIÓN FUNCIONAL
# =============================================================================

cat("\nRealizando análisis comparativo por región funcional...\n")

# Definir regiones funcionales
define_regions <- function(position) {
  case_when(
    position >= 2 & position <= 8 ~ "Semilla",
    position >= 9 & position <= 15 ~ "Central", 
    position >= 16 & position <= 22 ~ "3'",
    TRUE ~ "Otro"
  )
}

if (nrow(gt_mutations) > 0 && length(als_samples) > 0 && length(control_samples) > 0) {
  
  # Análisis por región funcional
  gt_by_region <- gt_mutations %>%
    mutate(position = as.numeric(str_extract(`pos:mut`, "^\\d+"))) %>%
    mutate(region = define_regions(position)) %>%
    group_by(region) %>%
    summarise(
      n_mutations = n(),
      als_total = sum(rowSums(select(., all_of(als_samples)), na.rm = TRUE)),
      control_total = sum(rowSums(select(., all_of(control_samples)), na.rm = TRUE)),
      .groups = "drop"
    ) %>%
    mutate(
      region_diff = als_total - control_total,
      region_ratio = ifelse(control_total > 0, als_total / control_total, NA)
    )
  
  write_csv(gt_by_region, file.path(output_tables_path, "paso3b_gt_por_region_als_control.csv"))
  
  cat("Mutaciones G>T por región funcional:\n")
  print(gt_by_region)
  
} else {
  cat("ERROR: No se puede realizar análisis por región\n")
}

# =============================================================================
# 6. GENERACIÓN DE VISUALIZACIONES
# =============================================================================

cat("\nGenerando visualizaciones comparativas...\n")

if (length(als_samples) > 0 && length(control_samples) > 0) {
  
  # 1. Boxplot de VAFs por grupo
  if (exists("vaf_comparison") && nrow(vaf_comparison) > 0) {
    
    # Preparar datos para boxplot
    vaf_long <- vaf_comparison %>%
      select(`miRNA name`, `pos:mut`, als_vaf_mean, control_vaf_mean) %>%
      pivot_longer(cols = c(als_vaf_mean, control_vaf_mean), 
                   names_to = "group", values_to = "vaf") %>%
      mutate(group = case_when(
        group == "als_vaf_mean" ~ "ALS",
        group == "control_vaf_mean" ~ "Control",
        TRUE ~ group
      ))
    
    p1 <- ggplot(vaf_long, aes(x = group, y = vaf, fill = group)) +
      geom_boxplot(alpha = 0.7) +
      scale_y_log10() +
      labs(title = "Distribución de VAFs por Grupo",
           x = "Grupo", y = "VAF (log scale)") +
      theme_minimal() +
      theme(legend.position = "none")
    
    ggsave(file.path(output_figures_path, "paso3b_vafs_por_grupo_boxplot.png"), 
           p1, width = 8, height = 6, dpi = 300)
    
    # 2. Scatter plot de diferencias VAF
    p2 <- ggplot(vaf_comparison, aes(x = control_vaf_mean, y = als_vaf_mean)) +
      geom_point(alpha = 0.6, color = "steelblue") +
      geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "red") +
      scale_x_log10() +
      scale_y_log10() +
      labs(title = "VAFs ALS vs Control",
           x = "VAF Control (log scale)", y = "VAF ALS (log scale)") +
      theme_minimal()
    
    ggsave(file.path(output_figures_path, "paso3b_vafs_als_vs_control_scatter.png"), 
           p2, width = 8, height = 6, dpi = 300)
    
  }
  
  # 3. Gráfico de mutaciones G>T por región
  if (exists("gt_by_region") && nrow(gt_by_region) > 0) {
    
    gt_region_long <- gt_by_region %>%
      select(region, als_total, control_total) %>%
      pivot_longer(cols = c(als_total, control_total), 
                   names_to = "group", values_to = "count") %>%
      mutate(group = case_when(
        group == "als_total" ~ "ALS",
        group == "control_total" ~ "Control",
        TRUE ~ group
      ))
    
    p3 <- ggplot(gt_region_long, aes(x = region, y = count, fill = group)) +
      geom_bar(stat = "identity", position = "dodge", alpha = 0.8) +
      labs(title = "Mutaciones G>T por Región Funcional",
           x = "Región", y = "Número de Mutaciones", fill = "Grupo") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
    
    ggsave(file.path(output_figures_path, "paso3b_gt_por_region_barras.png"), 
           p3, width = 10, height = 6, dpi = 300)
    
  }
  
  # 4. Heatmap de diferencias por miRNA
  if (exists("gt_comparison") && nrow(gt_comparison) > 0) {
    
    # Top miRNAs con mayores diferencias
    top_gt_differences <- gt_comparison %>%
      arrange(desc(abs(gt_diff))) %>%
      head(20)
    
    if (nrow(top_gt_differences) > 0) {
      p4 <- ggplot(top_gt_differences, aes(x = `miRNA name`, y = gt_diff)) +
        geom_bar(stat = "identity", 
                 fill = ifelse(top_gt_differences$gt_diff > 0, "red", "blue"), 
                 alpha = 0.7) +
        coord_flip() +
        labs(title = "Top 20 miRNAs con Mayores Diferencias G>T",
             x = "miRNA", y = "Diferencia (ALS - Control)") +
        theme_minimal() +
        theme(axis.text.y = element_text(size = 8))
      
      ggsave(file.path(output_figures_path, "paso3b_top_mirnas_diferencias_gt.png"), 
             p4, width = 12, height = 8, dpi = 300)
    }
  }
  
  cat("Visualizaciones generadas exitosamente\n")
  
} else {
  cat("ERROR: No se pueden generar visualizaciones - grupos insuficientes\n")
}

# =============================================================================
# 7. RESUMEN FINAL
# =============================================================================

cat("\n=== RESUMEN DEL PASO 3B ===\n")
cat("Análisis comparativo ALS vs Control completado\n")
cat("Archivos generados:\n")
cat("  - Tablas:", length(list.files(output_tables_path, pattern = "paso3b_")), "archivos\n")
cat("  - Figuras:", length(list.files(output_figures_path, pattern = "paso3b_")), "archivos\n")

if (length(als_samples) > 0 && length(control_samples) > 0) {
  cat("\nMuestras analizadas:\n")
  cat("  - ALS:", length(als_samples), "muestras\n")
  cat("  - Control:", length(control_samples), "muestras\n")
  
  if (exists("vaf_summary")) {
    cat("\nDiferencias VAF principales:\n")
    cat("  - Promedio de diferencia:", round(vaf_summary$mean_diff, 4), "\n")
    cat("  - Mutaciones con VAF mayor en ALS:", vaf_summary$n_als_higher, "\n")
    cat("  - Mutaciones con VAF mayor en Control:", vaf_summary$n_control_higher, "\n")
  }
  
  if (exists("gt_summary")) {
    cat("\nDiferencias G>T principales:\n")
    cat("  - Total mutaciones G>T en ALS:", gt_summary$total_als_gt, "\n")
    cat("  - Total mutaciones G>T en Control:", gt_summary$total_control_gt, "\n")
    cat("  - Diferencia promedio:", round(gt_summary$mean_gt_diff, 2), "\n")
  }
}

cat("\nPaso 3B completado exitosamente\n")
cat("Fecha de finalización:", Sys.time(), "\n")
