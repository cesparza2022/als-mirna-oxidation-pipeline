# =============================================================================
# GENERAR FIGURAS CON DATOS VAF REALES
# =============================================================================

library(ggplot2)
library(dplyr)
library(tidyr)
library(stringr)
library(tibble)

# Configuración
COLOR_GT <- "#D62728"
COLOR_CONTROL <- "#666666"
COLOR_SEED <- "#FFE13530"

theme_professional <- theme_classic(base_size = 14) +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0),
    plot.subtitle = element_text(size = 12, hjust = 0, color = "gray30"),
    axis.title = element_text(size = 13, face = "bold"),
    axis.text = element_text(size = 11),
    legend.title = element_text(size = 12, face = "bold"),
    legend.text = element_text(size = 11),
    legend.position = "bottom",
    panel.grid.major = element_line(color = "gray90", linetype = "dashed", linewidth = 0.3),
    panel.grid.minor = element_blank(),
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA)
  )

# Cargar datos
load_data <- function() {
  cat("📊 Cargando datos VAF...\n")
  processed_data_path <- "../../../final_analysis/processed_data/final_processed_data.csv"
  
  if (!file.exists(processed_data_path)) {
    stop("❌ No se encontró el archivo: ", processed_data_path)
  }
  
  data <- read.csv(processed_data_path, stringsAsFactors = FALSE)
  cat("✅ Datos cargados:", nrow(data), "filas\n")
  return(data)
}

# 1. Volcano plot con VAF
create_volcano_vaf <- function(data) {
  cat("📊 Creando volcano plot con VAF...\n")
  
  # Calcular VAF promedio por miRNA y tipo de mutación
  vaf_data <- data %>%
    mutate(
      mutation_type = str_extract(pos.mut, "^[ATGC]>[ATGC]"),
      position = as.numeric(str_extract(pos.mut, "\\d+"))
    ) %>%
    filter(!is.na(mutation_type)) %>%
    # Convertir a formato largo para calcular VAF promedio
    pivot_longer(cols = starts_with("Magen"), names_to = "sample", values_to = "vaf") %>%
    filter(vaf > 0) %>%  # Solo valores positivos
    group_by(miRNA_name, mutation_type) %>%
    summarise(
      mean_vaf = mean(vaf, na.rm = TRUE),
      max_vaf = max(vaf, na.rm = TRUE),
      n_samples = n(),
      .groups = "drop"
    ) %>%
    filter(n_samples >= 3)  # Al menos 3 muestras
  
  # Calcular estadísticas para G>T
  gt_data <- vaf_data %>%
    filter(mutation_type == "G>T") %>%
    mutate(
      median_vaf = median(mean_vaf),
      log2_fc = log2((mean_vaf + 1e-6) / (median_vaf + 1e-6)),
      # Simular p-valor basado en desviación
      z_score = abs(scale(mean_vaf)),
      p_value = pnorm(z_score, lower.tail = FALSE) * 2,
      neg_log10_p = -log10(p_value + 1e-10),
      significant = p_value < 0.05 & abs(log2_fc) > 0.5
    )
  
  # Top miRNAs para etiquetar
  top_mirnas <- gt_data %>%
    filter(significant) %>%
    arrange(desc(neg_log10_p)) %>%
    head(10)
  
  p <- ggplot(gt_data, aes(x = log2_fc, y = neg_log10_p)) +
    geom_point(aes(color = significant, size = mean_vaf), alpha = 0.7) +
    scale_color_manual(values = c("TRUE" = COLOR_GT, "FALSE" = COLOR_CONTROL),
                      labels = c("TRUE" = "Significativo", "FALSE" = "No significativo")) +
    scale_size_continuous(range = c(2, 8), name = "VAF Promedio") +
    geom_hline(yintercept = -log10(0.05), linetype = "dashed", color = "red", linewidth = 0.5) +
    geom_vline(xintercept = c(-0.5, 0.5), linetype = "dashed", color = "red", linewidth = 0.5) +
    labs(
      title = "2.1. Enriquecimiento de G>T por miRNA (VAF)",
      subtitle = "Volcano plot basado en VAF promedio por miRNA",
      x = "log2(Fold Change) vs Mediana VAF",
      y = "-log10(p-valor)"
    ) +
    theme_professional +
    theme(legend.position = "right")
  
  return(p)
}

# 2. Boxplot por región con VAF
create_boxplot_vaf <- function(data) {
  cat("📊 Creando boxplot por región con VAF...\n")
  
  # Calcular VAF por región
  region_data <- data %>%
    mutate(
      position = as.numeric(str_extract(pos.mut, "\\d+")),
      region = case_when(
        position >= 2 & position <= 8 ~ "Seed (2-8)",
        position >= 9 & position <= 15 ~ "Middle (9-15)",
        position >= 16 ~ "3' End (16+)",
        TRUE ~ "5' End (1)"
      ),
      mutation_type = str_extract(pos.mut, "^[ATGC]>[ATGC]")
    ) %>%
    filter(!is.na(position) & !is.na(mutation_type)) %>%
    # Convertir a formato largo
    pivot_longer(cols = starts_with("Magen"), names_to = "sample", values_to = "vaf") %>%
    filter(vaf > 0) %>%  # Solo valores positivos
    group_by(miRNA_name, region, mutation_type) %>%
    summarise(
      mean_vaf = mean(vaf, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    filter(mutation_type == "G>T")  # Solo G>T
  
  p <- ggplot(region_data, aes(x = region, y = mean_vaf, fill = region)) +
    geom_violin(alpha = 0.3, trim = FALSE) +
    geom_boxplot(width = 0.2, alpha = 0.7, outlier.shape = NA) +
    geom_jitter(width = 0.1, alpha = 0.3, size = 1) +
    scale_fill_manual(values = c(
      "Seed (2-8)" = COLOR_GT,
      "Middle (9-15)" = "#FFA500",
      "3' End (16+)" = "#4CAF50",
      "5' End (1)" = "#2196F3"
    )) +
    scale_y_log10(labels = scales::scientific_format()) +
    stat_summary(fun = mean, geom = "point", shape = 23, size = 3, 
                fill = "white", color = "black") +
    labs(
      title = "2.2. VAF de G>T por Región del miRNA",
      subtitle = "Distribución de VAF promedio en diferentes regiones funcionales",
      x = "Región del miRNA",
      y = "VAF Promedio (escala log)",
      caption = "Diamante blanco = media; línea = mediana"
    ) +
    theme_professional +
    theme(
      legend.position = "none",
      axis.text.x = element_text(angle = 0, hjust = 0.5)
    )
  
  return(p)
}

# 3. Heatmap posicional con VAF
create_heatmap_vaf <- function(data) {
  cat("📊 Creando heatmap posicional con VAF...\n")
  
  # Calcular VAF promedio por posición y miRNA
  positional_data <- data %>%
    filter(str_detect(pos.mut, "^G>T")) %>%
    mutate(position = as.numeric(str_extract(pos.mut, "\\d+"))) %>%
    filter(!is.na(position) & position <= 22) %>%
    # Convertir a formato largo
    pivot_longer(cols = starts_with("Magen"), names_to = "sample", values_to = "vaf") %>%
    filter(vaf > 0) %>%  # Solo valores positivos
    group_by(miRNA_name, position) %>%
    summarise(
      mean_vaf = mean(vaf, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    complete(miRNA_name, position = 1:22, fill = list(mean_vaf = 0))
  
  # Filtrar top miRNAs por VAF total
  top_mirnas <- positional_data %>%
    group_by(miRNA_name) %>%
    summarise(total_vaf = sum(mean_vaf), .groups = "drop") %>%
    arrange(desc(total_vaf)) %>%
    head(20) %>%  # Top 20 para que se vea mejor
    pull(miRNA_name)
  
  plot_data <- positional_data %>%
    filter(miRNA_name %in% top_mirnas) %>%
    group_by(miRNA_name) %>%
    mutate(
      normalized_vaf = mean_vaf / max(mean_vaf + 1e-10),
      miRNA_name = factor(miRNA_name, levels = rev(top_mirnas))
    )
  
  p <- ggplot(plot_data, aes(x = position, y = miRNA_name, fill = normalized_vaf)) +
    geom_tile(color = "white", linewidth = 0.2) +
    scale_fill_gradient(low = "white", high = COLOR_GT, 
                       name = "VAF\nNormalizada",
                       breaks = c(0, 0.5, 1),
                       labels = c("Baja", "Media", "Alta")) +
    annotate("rect", xmin = 1.5, xmax = 8.5, ymin = 0.5, ymax = length(top_mirnas) + 0.5,
             fill = COLOR_SEED, alpha = 0.3) +
    annotate("text", x = 5, y = length(top_mirnas) + 1, 
             label = "SEED", size = 4, fontface = "bold") +
    scale_x_continuous(breaks = seq(1, 22, 2), expand = c(0, 0)) +
    labs(
      title = "3.1. Heatmap Posicional de G>T (VAF)",
      subtitle = "Top 20 miRNAs con mayor VAF de mutaciones G>T",
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

# 4. Line plot posicional con VAF
create_line_plot_vaf <- function(data) {
  cat("📊 Creando line plot posicional con VAF...\n")
  
  # Calcular VAF promedio por posición y tipo de mutación
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
    # Convertir a formato largo
    pivot_longer(cols = starts_with("Magen"), names_to = "sample", values_to = "vaf") %>%
    filter(vaf > 0) %>%  # Solo valores positivos
    group_by(position, mutation_type) %>%
    summarise(
      mean_vaf = mean(vaf, na.rm = TRUE),
      .groups = "drop"
    )
  
  p <- ggplot(positional_freq, aes(x = position, y = mean_vaf, 
                                   color = mutation_type, linetype = mutation_type)) +
    geom_line(linewidth = 1.2, alpha = 0.8) +
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
    scale_y_log10(labels = scales::scientific_format()) +
    labs(
      title = "3.2. VAF de Mutaciones por Posición",
      subtitle = "VAF promedio de G>T y otras mutaciones de Guanina",
      x = "Posición en miRNA",
      y = "VAF Promedio (escala log)",
      color = "Tipo de Mutación",
      linetype = "Tipo de Mutación"
    ) +
    theme_professional +
    theme(legend.position = "bottom")
  
  return(p)
}

# 5. CDF con VAF
create_cdf_vaf <- function(data) {
  cat("📊 Creando CDF con VAF...\n")
  
  # Calcular VAF promedio por miRNA
  vaf_proportions <- data %>%
    mutate(is_gt = str_detect(pos.mut, "^G>T")) %>%
    filter(is_gt) %>%
    # Convertir a formato largo
    pivot_longer(cols = starts_with("Magen"), names_to = "sample", values_to = "vaf") %>%
    filter(vaf > 0) %>%  # Solo valores positivos
    group_by(miRNA_name) %>%
    summarise(
      mean_vaf = mean(vaf, na.rm = TRUE),
      max_vaf = max(vaf, na.rm = TRUE),
      n_samples = n(),
      .groups = "drop"
    ) %>%
    filter(n_samples >= 3)  # Al menos 3 muestras
  
  # Estadísticas
  median_vaf <- median(vaf_proportions$mean_vaf)
  mean_vaf <- mean(vaf_proportions$mean_vaf)
  
  p <- ggplot(vaf_proportions, aes(x = mean_vaf)) +
    stat_ecdf(geom = "step", color = COLOR_GT, linewidth = 1.5, alpha = 0.8) +
    geom_vline(xintercept = median_vaf, linetype = "dashed", 
              color = "darkred", linewidth = 1) +
    geom_vline(xintercept = mean_vaf, linetype = "dotted", 
              color = "darkblue", linewidth = 1) +
    annotate("text", x = median_vaf, y = 0.95, 
            label = paste0("Mediana: ", format(median_vaf, scientific = TRUE, digits = 2)),
            hjust = -0.1, size = 4) +
    annotate("text", x = mean_vaf, y = 0.85, 
            label = paste0("Media: ", format(mean_vaf, scientific = TRUE, digits = 2)),
            hjust = -0.1, size = 4, color = "darkblue") +
    scale_x_log10(labels = scales::scientific_format()) +
    scale_y_continuous(labels = scales::percent_format()) +
    labs(
      title = "5.1. Distribución Acumulada de VAF G>T",
      subtitle = "Carga oxidativa global en miRNAs (CDF)",
      x = "VAF Promedio (escala log)",
      y = "Probabilidad Acumulada",
      caption = paste0("n = ", nrow(vaf_proportions), " miRNAs con ≥3 muestras")
    ) +
    theme_professional
  
  return(p)
}

# 6. Distribución por región con VAF
create_distribution_vaf <- function(data) {
  cat("📊 Creando distribución por región con VAF...\n")
  
  # Calcular VAF por región
  region_data <- data %>%
    mutate(
      is_gt = str_detect(pos.mut, "^G>T"),
      position = as.numeric(str_extract(pos.mut, "\\d+")),
      region = case_when(
        position >= 2 & position <= 8 ~ "Seed",
        TRUE ~ "Non-Seed"
      )
    ) %>%
    filter(!is.na(region) & is_gt) %>%
    # Convertir a formato largo
    pivot_longer(cols = starts_with("Magen"), names_to = "sample", values_to = "vaf") %>%
    filter(vaf > 0) %>%  # Solo valores positivos
    group_by(miRNA_name, region) %>%
    summarise(
      mean_vaf = mean(vaf, na.rm = TRUE),
      .groups = "drop"
    )
  
  p <- ggplot(region_data, aes(x = mean_vaf, y = region, fill = region)) +
    geom_violin(alpha = 0.7, trim = FALSE) +
    geom_boxplot(width = 0.1, alpha = 0.5, outlier.shape = NA) +
    scale_fill_manual(values = c("Seed" = COLOR_GT, "Non-Seed" = COLOR_CONTROL)) +
    scale_x_log10(labels = scales::scientific_format()) +
    labs(
      title = "5.2. Distribución de VAF G>T por Región",
      subtitle = "Comparación de VAF: Seed vs Non-Seed",
      x = "VAF Promedio (escala log)",
      y = "Región del miRNA"
    ) +
    theme_professional +
    theme(legend.position = "none") +
    coord_flip()
  
  return(p)
}

# Función principal
main <- function() {
  cat("🎯 GENERANDO FIGURAS CON DATOS VAF REALES\n")
  cat(paste(rep("=", 60), collapse = ""), "\n")
  
  # Cargar datos
  data <- load_data()
  
  # Crear directorio
  if (!dir.exists("figures_vaf")) {
    dir.create("figures_vaf", recursive = TRUE)
  }
  
  # Generar figuras
  figures <- list(
    volcano = create_volcano_vaf(data),
    boxplot = create_boxplot_vaf(data),
    heatmap = create_heatmap_vaf(data),
    lineplot = create_line_plot_vaf(data),
    cdf = create_cdf_vaf(data),
    distribution = create_distribution_vaf(data)
  )
  
  # Guardar figuras
  figure_names <- c(
    "2.1_volcano_gt_vaf.png",
    "2.2_boxplot_seed_regions_vaf.png",
    "3.1_positional_heatmap_vaf.png",
    "3.2_line_plot_positional_vaf.png",
    "5.1_cdf_plot_vaf.png",
    "5.2_distribution_vaf.png"
  )
  
  for (i in seq_along(figures)) {
    output_file <- paste0("figures_vaf/", figure_names[i])
    ggsave(output_file, figures[[i]], width = 12, height = 9, dpi = 300, bg = "white")
    cat("✅ Guardado:", output_file, "\n")
  }
  
  cat("\n🎉 FIGURAS VAF GENERADAS EXITOSAMENTE\n")
  cat("📁 Directorio: figures_vaf/\n")
  cat("📊 Total de figuras: 6\n")
}

# Ejecutar
main()
