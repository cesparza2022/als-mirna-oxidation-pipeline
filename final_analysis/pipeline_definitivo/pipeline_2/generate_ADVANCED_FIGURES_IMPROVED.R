# =============================================================================
# GENERAR FIGURAS AVANZADAS MEJORADAS PARA PASO 1
# =============================================================================

library(ggplot2)
library(dplyr)
library(tidyr)
library(stringr)
library(patchwork)
library(tibble)
library(ggrepel)
library(viridis)
library(pheatmap)
library(RColorBrewer)

# Configuración profesional
COLOR_GT <- "#D62728"
COLOR_CONTROL <- "#666666"
COLOR_SEED <- "#FFE13530"  # Amarillo transparente

theme_professional <- theme_classic(base_size = 14) +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0),
    plot.subtitle = element_text(size = 12, hjust = 0, color = "gray30"),
    axis.title = element_text(size = 13, face = "bold"),
    axis.text = element_text(size = 11),
    legend.title = element_text(size = 12, face = "bold"),
    legend.text = element_text(size = 11),
    legend.position = "bottom",
    panel.grid.major = element_line(color = "gray90", linetype = "dashed", size = 0.3),
    panel.grid.minor = element_blank(),
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA)
  )

# Cargar datos
load_data <- function() {
  cat("📊 Cargando datos...\n")
  processed_data_path <- "../../../final_analysis/processed_data/final_processed_data.csv"
  
  if (!file.exists(processed_data_path)) {
    stop("❌ No se encontró el archivo: ", processed_data_path)
  }
  
  data <- read.csv(processed_data_path, stringsAsFactors = FALSE)
  cat("✅ Datos cargados:", nrow(data), "filas\n")
  return(data)
}

# 1.1. Heatmap de correlación mejorado
create_correlation_heatmap_improved <- function(data) {
  cat("📊 Creando heatmap de correlación mejorado...\n")
  
  # Crear matriz de mutaciones por miRNA
  mutation_matrix <- data %>%
    mutate(mutation_type = str_extract(pos.mut, "^[ATGC]>[ATGC]")) %>%
    filter(!is.na(mutation_type)) %>%
    count(miRNA_name, mutation_type, name = "count") %>%
    pivot_wider(names_from = mutation_type, values_from = count, values_fill = 0) %>%
    column_to_rownames("miRNA_name")
  
  # Verificar que hay suficientes datos
  if (ncol(mutation_matrix) < 2) {
    cat("⚠️ No hay suficientes tipos de mutación para calcular correlación\n")
    return(NULL)
  }
  
  # Filtrar columnas con varianza cero
  col_vars <- apply(mutation_matrix, 2, var, na.rm = TRUE)
  mutation_matrix <- mutation_matrix[, col_vars > 0]
  
  # Calcular correlación
  cor_matrix <- cor(mutation_matrix, use = "pairwise.complete.obs", method = "pearson")
  
  # Crear heatmap con pheatmap (guardado como imagen)
  output_file <- "figures_advanced/1.1_correlation_heatmap_improved.png"
  png(output_file, width = 10, height = 9, units = "in", res = 300)
  
  pheatmap(
    cor_matrix,
    color = colorRampPalette(c("blue", "white", "red"))(100),
    breaks = seq(-1, 1, length.out = 101),
    display_numbers = TRUE,
    number_color = "black",
    fontsize_number = 10,
    fontsize = 12,
    fontsize_row = 12,
    fontsize_col = 12,
    main = "1.1. Correlación entre Tipos de Mutación",
    cluster_rows = TRUE,
    cluster_cols = TRUE,
    angle_col = 45,
    border_color = "gray80",
    cellwidth = 50,
    cellheight = 50
  )
  
  dev.off()
  cat("✅ Guardado:", output_file, "\n")
  return(output_file)
}

# 1.2. PCA mejorado
create_pca_improved <- function(data) {
  cat("📊 Creando PCA mejorado...\n")
  
  # Crear matriz de mutaciones por miRNA
  mutation_matrix <- data %>%
    mutate(mutation_type = str_extract(pos.mut, "^[ATGC]>[ATGC]")) %>%
    filter(!is.na(mutation_type)) %>%
    count(miRNA_name, mutation_type, name = "count") %>%
    pivot_wider(names_from = mutation_type, values_from = count, values_fill = 0) %>%
    column_to_rownames("miRNA_name")
  
  # Verificar dimensiones
  if (ncol(mutation_matrix) < 2 || nrow(mutation_matrix) < 3) {
    cat("⚠️ No hay suficientes datos para PCA, saltando...\n")
    return(NULL)
  }
  
  # Filtrar columnas con varianza cero
  col_vars <- apply(mutation_matrix, 2, var, na.rm = TRUE)
  mutation_matrix <- mutation_matrix[, col_vars > 0]
  
  # Verificar de nuevo después del filtrado
  if (ncol(mutation_matrix) < 2) {
    cat("⚠️ No hay suficientes variables con varianza para PCA\n")
    return(NULL)
  }
  
  # Realizar PCA
  pca_result <- prcomp(mutation_matrix, scale. = TRUE, center = TRUE)
  
  # Crear dataframe para plot
  pca_data <- data.frame(
    miRNA = rownames(mutation_matrix),
    PC1 = pca_result$x[,1],
    PC2 = if(ncol(pca_result$x) >= 2) pca_result$x[,2] else 0
  )
  
  # Calcular G>T enrichment para colorear
  gt_counts <- data %>%
    filter(str_detect(pos.mut, "^G>T")) %>%
    count(miRNA_name, name = "gt_count")
  
  pca_data <- pca_data %>%
    left_join(gt_counts, by = c("miRNA" = "miRNA_name")) %>%
    mutate(gt_count = ifelse(is.na(gt_count), 0, gt_count))
  
  # Calcular varianza explicada
  var_explained <- summary(pca_result)$importance[2,] * 100
  
  p <- ggplot(pca_data, aes(x = PC1, y = PC2, color = gt_count, size = gt_count)) +
    geom_point(alpha = 0.7) +
    scale_color_gradient(low = COLOR_CONTROL, high = COLOR_GT, name = "G>T Count") +
    scale_size_continuous(range = c(2, 8), guide = "none") +
    labs(
      title = "1.2. PCA: Perfil de Mutaciones por miRNA",
      subtitle = "Separación basada en patrones de mutación (coloreado por frecuencia G>T)",
      x = paste0("PC1 (", round(var_explained[1], 1), "% varianza)"),
      y = paste0("PC2 (", round(var_explained[2], 1), "% varianza)")
    ) +
    theme_professional +
    theme(legend.position = "right")
  
  return(p)
}

# 2.1. Volcano plot mejorado
create_volcano_improved <- function(data) {
  cat("📊 Creando volcano plot mejorado...\n")
  
  # Calcular estadísticas por miRNA
  gt_stats <- data %>%
    mutate(is_gt = str_detect(pos.mut, "^G>T")) %>%
    group_by(miRNA_name) %>%
    summarise(
      total_snvs = n(),
      gt_count = sum(is_gt),
      gt_fraction = gt_count / total_snvs,
      .groups = "drop"
    ) %>%
    filter(total_snvs >= 5) %>%  # Filtrar miRNAs con suficientes SNVs
    mutate(
      # Calcular fold change vs. mediana
      median_fraction = median(gt_fraction),
      log2_fc = log2((gt_fraction + 0.01) / (median_fraction + 0.01)),
      # Simular p-valor basado en desviación
      z_score = abs(scale(gt_fraction)),
      p_value = pnorm(z_score, lower.tail = FALSE) * 2,
      neg_log10_p = -log10(p_value + 1e-10),
      significant = p_value < 0.05 & abs(log2_fc) > 0.5
    )
  
  # Top miRNAs para etiquetar
  top_mirnas <- gt_stats %>%
    filter(significant) %>%
    arrange(desc(neg_log10_p)) %>%
    head(10)
  
  p <- ggplot(gt_stats, aes(x = log2_fc, y = neg_log10_p)) +
    geom_point(aes(color = significant, size = gt_count), alpha = 0.6) +
    scale_color_manual(values = c("TRUE" = COLOR_GT, "FALSE" = COLOR_CONTROL),
                      labels = c("TRUE" = "Significativo", "FALSE" = "No significativo")) +
    scale_size_continuous(range = c(2, 6), name = "G>T Count") +
    geom_hline(yintercept = -log10(0.05), linetype = "dashed", color = "red", size = 0.5) +
    geom_vline(xintercept = c(-0.5, 0.5), linetype = "dashed", color = "red", size = 0.5) +
    geom_text_repel(
      data = top_mirnas,
      aes(label = miRNA_name),
      size = 3,
      max.overlaps = 10,
      box.padding = 0.5
    ) +
    labs(
      title = "2.1. Enriquecimiento de G>T por miRNA",
      subtitle = "Volcano plot mostrando miRNAs con mayor enriquecimiento de mutaciones oxidativas",
      x = "log2(Fold Change) vs Mediana",
      y = "-log10(p-valor)"
    ) +
    theme_professional +
    theme(legend.position = "right")
  
  return(p)
}

# 2.2. Boxplot por región mejorado
create_boxplot_regions_improved <- function(data) {
  cat("📊 Creando boxplot por región mejorado...\n")
  
  # Calcular proporción G>T por región y miRNA
  region_data <- data %>%
    mutate(
      position = as.numeric(str_extract(pos.mut, "\\d+")),
      region = case_when(
        position >= 2 & position <= 8 ~ "Seed (2-8)",
        position >= 9 & position <= 15 ~ "Middle (9-15)",
        position >= 16 ~ "3' End (16+)",
        TRUE ~ "5' End (1)"
      ),
      is_gt = str_detect(pos.mut, "^G>T")
    ) %>%
    filter(!is.na(position)) %>%
    group_by(miRNA_name, region) %>%
    summarise(
      total_snvs = n(),
      gt_count = sum(is_gt),
      gt_fraction = gt_count / total_snvs,
      .groups = "drop"
    )
  
  # Calcular estadísticas para anotaciones
  region_stats <- region_data %>%
    group_by(region) %>%
    summarise(
      mean_fraction = mean(gt_fraction),
      median_fraction = median(gt_fraction),
      n = n(),
      .groups = "drop"
    )
  
  p <- ggplot(region_data, aes(x = region, y = gt_fraction, fill = region)) +
    geom_violin(alpha = 0.3, trim = FALSE) +
    geom_boxplot(width = 0.2, alpha = 0.7, outlier.shape = NA) +
    geom_jitter(width = 0.1, alpha = 0.3, size = 1) +
    scale_fill_manual(values = c(
      "Seed (2-8)" = COLOR_GT,
      "Middle (9-15)" = "#FFA500",
      "3' End (16+)" = "#4CAF50",
      "5' End (1)" = "#2196F3"
    )) +
    stat_summary(fun = mean, geom = "point", shape = 23, size = 3, 
                fill = "white", color = "black") +
    labs(
      title = "2.2. Proporción G>T por Región del miRNA",
      subtitle = "Distribución de mutaciones oxidativas en diferentes regiones funcionales",
      x = "Región del miRNA",
      y = "Proporción G>T / Total SNVs",
      caption = "Diamante blanco = media; línea = mediana"
    ) +
    theme_professional +
    theme(
      legend.position = "none",
      axis.text.x = element_text(angle = 0, hjust = 0.5)
    )
  
  return(p)
}

# 3.1. Heatmap posicional mejorado
create_positional_heatmap_improved <- function(data) {
  cat("📊 Creando heatmap posicional mejorado...\n")
  
  # Calcular frecuencia G>T por posición y miRNA
  positional_data <- data %>%
    filter(str_detect(pos.mut, "^G>T")) %>%
    mutate(position = as.numeric(str_extract(pos.mut, "\\d+"))) %>%
    filter(!is.na(position) & position <= 22) %>%
    count(miRNA_name, position, name = "gt_count") %>%
    complete(miRNA_name, position = 1:22, fill = list(gt_count = 0))
  
  # Filtrar top miRNAs por total de G>T
  top_mirnas <- positional_data %>%
    group_by(miRNA_name) %>%
    summarise(total_gt = sum(gt_count), .groups = "drop") %>%
    arrange(desc(total_gt)) %>%
    head(30) %>%
    pull(miRNA_name)
  
  plot_data <- positional_data %>%
    filter(miRNA_name %in% top_mirnas) %>%
    group_by(miRNA_name) %>%
    mutate(
      normalized_count = gt_count / max(gt_count + 1),
      miRNA_name = factor(miRNA_name, levels = rev(top_mirnas))
    )
  
  p <- ggplot(plot_data, aes(x = position, y = miRNA_name, fill = normalized_count)) +
    geom_tile(color = "white", size = 0.2) +
    scale_fill_gradient(low = "white", high = COLOR_GT, 
                       name = "Frecuencia\nNormalizada",
                       breaks = c(0, 0.5, 1),
                       labels = c("Baja", "Media", "Alta")) +
    annotate("rect", xmin = 1.5, xmax = 8.5, ymin = 0.5, ymax = length(top_mirnas) + 0.5,
             fill = COLOR_SEED, alpha = 0.3) +
    annotate("text", x = 5, y = length(top_mirnas) + 1, 
             label = "SEED", size = 4, fontface = "bold") +
    scale_x_continuous(breaks = seq(1, 22, 2), expand = c(0, 0)) +
    labs(
      title = "3.1. Heatmap Posicional de G>T",
      subtitle = "Top 30 miRNAs con mayor frecuencia de mutaciones oxidativas",
      x = "Posición en miRNA",
      y = "miRNA"
    ) +
    theme_professional +
    theme(
      axis.text.y = element_text(size = 8),
      legend.position = "right",
      panel.grid = element_blank()
    )
  
  return(p)
}

# 3.2. Line plot posicional mejorado
create_line_plot_improved <- function(data) {
  cat("📊 Creando line plot posicional mejorado...\n")
  
  # Calcular frecuencia por posición
  positional_freq <- data %>%
    mutate(
      position = as.numeric(str_extract(pos.mut, "\\d+")),
      mutation_type = case_when(
        str_detect(pos.mut, "^G>T") ~ "G>T (Oxidación)",
        str_detect(pos.mut, "^G>A") ~ "G>A",
        str_detect(pos.mut, "^G>C") ~ "G>C",
        TRUE ~ "Otros"
      )
    ) %>%
    filter(!is.na(position) & position <= 22) %>%
    count(position, mutation_type, name = "count")
  
  # Normalizar por posición
  positional_freq <- positional_freq %>%
    group_by(position) %>%
    mutate(
      total = sum(count),
      frequency = count / total
    ) %>%
    ungroup()
  
  p <- ggplot(positional_freq, aes(x = position, y = frequency, 
                                   color = mutation_type, linetype = mutation_type)) +
    geom_line(size = 1.2, alpha = 0.8) +
    geom_point(size = 2.5) +
    annotate("rect", xmin = 1.5, xmax = 8.5, ymin = -Inf, ymax = Inf,
             fill = COLOR_SEED, alpha = 0.3) +
    scale_color_manual(values = c(
      "G>T (Oxidación)" = COLOR_GT,
      "G>A" = "#4CAF50",
      "G>C" = "#2196F3",
      "Otros" = COLOR_CONTROL
    )) +
    scale_linetype_manual(values = c(
      "G>T (Oxidación)" = "solid",
      "G>A" = "dashed",
      "G>C" = "dotted",
      "Otros" = "dotdash"
    )) +
    scale_x_continuous(breaks = seq(1, 22, 2)) +
    scale_y_continuous(labels = scales::percent_format()) +
    labs(
      title = "3.2. Frecuencia de Mutaciones por Posición",
      subtitle = "Distribución posicional de G>T y otras mutaciones de Guanina",
      x = "Posición en miRNA",
      y = "Frecuencia Relativa",
      color = "Tipo de Mutación",
      linetype = "Tipo de Mutación"
    ) +
    theme_professional +
    theme(legend.position = "bottom")
  
  return(p)
}

# 5.1. CDF mejorado
create_cdf_improved <- function(data) {
  cat("📊 Creando CDF mejorado...\n")
  
  # Calcular proporción G>T por miRNA
  gt_proportions <- data %>%
    mutate(is_gt = str_detect(pos.mut, "^G>T")) %>%
    group_by(miRNA_name) %>%
    summarise(
      total_snvs = n(),
      gt_count = sum(is_gt),
      gt_proportion = gt_count / total_snvs,
      .groups = "drop"
    ) %>%
    filter(total_snvs >= 3)
  
  # Estadísticas
  median_prop <- median(gt_proportions$gt_proportion)
  mean_prop <- mean(gt_proportions$gt_proportion)
  
  p <- ggplot(gt_proportions, aes(x = gt_proportion)) +
    stat_ecdf(geom = "step", color = COLOR_GT, size = 1.5, alpha = 0.8) +
    geom_vline(xintercept = median_prop, linetype = "dashed", 
              color = "darkred", size = 1) +
    geom_vline(xintercept = mean_prop, linetype = "dotted", 
              color = "darkblue", size = 1) +
    annotate("text", x = median_prop, y = 0.95, 
            label = paste0("Mediana: ", round(median_prop, 3)),
            hjust = -0.1, size = 4) +
    annotate("text", x = mean_prop, y = 0.85, 
            label = paste0("Media: ", round(mean_prop, 3)),
            hjust = -0.1, size = 4, color = "darkblue") +
    scale_x_continuous(labels = scales::percent_format()) +
    scale_y_continuous(labels = scales::percent_format()) +
    labs(
      title = "5.1. Distribución Acumulada de Proporción G>T",
      subtitle = "Carga oxidativa global en miRNAs (CDF)",
      x = "Proporción G>T / Total SNVs",
      y = "Probabilidad Acumulada",
      caption = paste0("n = ", nrow(gt_proportions), " miRNAs con ≥3 SNVs")
    ) +
    theme_professional
  
  return(p)
}

# 5.2. Distribución mejorada (violin plot alternativo)
create_ridge_improved <- function(data) {
  cat("📊 Creando distribución mejorada...\n")
  
  # Calcular proporción G>T por miRNA
  gt_proportions <- data %>%
    mutate(
      is_gt = str_detect(pos.mut, "^G>T"),
      position = as.numeric(str_extract(pos.mut, "\\d+")),
      region = case_when(
        position >= 2 & position <= 8 ~ "Seed",
        TRUE ~ "Non-Seed"
      )
    ) %>%
    filter(!is.na(region)) %>%
    group_by(miRNA_name, region) %>%
    summarise(
      total_snvs = n(),
      gt_count = sum(is_gt),
      gt_proportion = gt_count / total_snvs,
      .groups = "drop"
    ) %>%
    filter(total_snvs >= 3)
  
  p <- ggplot(gt_proportions, aes(x = gt_proportion, y = region, fill = region)) +
    geom_violin(alpha = 0.7, trim = FALSE) +
    geom_boxplot(width = 0.1, alpha = 0.5, outlier.shape = NA) +
    scale_fill_manual(values = c("Seed" = COLOR_GT, "Non-Seed" = COLOR_CONTROL)) +
    scale_x_continuous(labels = scales::percent_format()) +
    labs(
      title = "5.2. Distribución de Proporción G>T por Región",
      subtitle = "Comparación de carga oxidativa: Seed vs Non-Seed",
      x = "Proporción G>T / Total SNVs",
      y = "Región del miRNA"
    ) +
    theme_professional +
    theme(legend.position = "none") +
    coord_flip()
  
  return(p)
}

# Función principal
main <- function() {
  cat("🎯 GENERANDO FIGURAS AVANZADAS MEJORADAS\n")
  cat(paste(rep("=", 60), collapse = ""), "\n")
  
  # Cargar datos
  data <- load_data()
  
  # Crear directorio
  if (!dir.exists("figures_advanced")) {
    dir.create("figures_advanced", recursive = TRUE)
  }
  
  # 1.1 Correlation heatmap (se guarda internamente como PNG)
  heatmap_result <- create_correlation_heatmap_improved(data)
  
  # Resto de figuras
  figures <- list()
  
  # Intentar crear cada figura, manejando errores
  tryCatch({
    pca_fig <- create_pca_improved(data)
    if (!is.null(pca_fig)) figures$pca <- pca_fig
  }, error = function(e) cat("⚠️ Error en PCA:", e$message, "\n"))
  
  tryCatch({
    figures$volcano <- create_volcano_improved(data)
  }, error = function(e) cat("⚠️ Error en Volcano:", e$message, "\n"))
  
  tryCatch({
    figures$boxplot <- create_boxplot_regions_improved(data)
  }, error = function(e) cat("⚠️ Error en Boxplot:", e$message, "\n"))
  
  tryCatch({
    figures$heatmap <- create_positional_heatmap_improved(data)
  }, error = function(e) cat("⚠️ Error en Heatmap:", e$message, "\n"))
  
  tryCatch({
    figures$lineplot <- create_line_plot_improved(data)
  }, error = function(e) cat("⚠️ Error en Line plot:", e$message, "\n"))
  
  tryCatch({
    figures$cdf <- create_cdf_improved(data)
  }, error = function(e) cat("⚠️ Error en CDF:", e$message, "\n"))
  
  tryCatch({
    figures$ridge <- create_ridge_improved(data)
  }, error = function(e) cat("⚠️ Error en Ridge:", e$message, "\n"))
  
  # Guardar figuras exitosas
  if (length(figures) > 0) {
    figure_mapping <- list(
      pca = "1.2_pca_profiles_improved.png",
      volcano = "2.1_volcano_gt_enrichment_improved.png",
      boxplot = "2.2_boxplot_seed_regions_improved.png",
      heatmap = "3.1_positional_heatmap_improved.png",
      lineplot = "3.2_line_plot_positional_improved.png",
      cdf = "5.1_cdf_plot_improved.png",
      ridge = "5.2_ridge_plot_improved.png"
    )
    
    for (fig_name in names(figures)) {
      if (!is.null(figures[[fig_name]])) {
        output_file <- paste0("figures_advanced/", figure_mapping[[fig_name]])
        ggsave(output_file, figures[[fig_name]], width = 12, height = 9, dpi = 300, bg = "white")
        cat("✅ Guardado:", output_file, "\n")
      }
    }
  }
  
  # Contar figuras generadas (incluir heatmap si existe)
  total_figures <- length(figures)
  if (!is.null(heatmap_result)) total_figures <- total_figures + 1
  
  cat("\n🎉 FIGURAS AVANZADAS MEJORADAS GENERADAS\n")
  cat("📁 Directorio: figures_advanced/\n")
  cat("📊 Total de figuras generadas:", total_figures, "\n")
}

# Ejecutar
main()
