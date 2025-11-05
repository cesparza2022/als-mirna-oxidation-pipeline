# =============================================================================
# FIGURA 1 SIMPLE Y LIMPIA - ANÁLISIS INICIAL
# =============================================================================

library(ggplot2)
library(dplyr)
library(tidyr)
library(stringr)
library(patchwork)

# Configuración de colores y tema
COLOR_GT <- "#D62728"  # Rojo para G>T (oxidación)
COLOR_SEED <- "#FFE135"  # Amarillo claro para región semilla
COLOR_CONTROL <- "#666666"  # Gris para control

theme_clean <- theme_classic() +
  theme(
    text = element_text(size = 12),
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 10),
    axis.title = element_text(size = 11),
    axis.text = element_text(size = 10),
    legend.position = "bottom",
    legend.title = element_blank(),
    plot.margin = margin(10, 10, 10, 10)
  )

# Función para cargar y procesar datos
load_and_process_data <- function() {
  cat("📊 Cargando datos...\n")
  
  # Rutas de archivos
  raw_data_path <- "../../../final_analysis/data/raw/miRNA_count.Q33.txt"
  processed_data_path <- "../../../final_analysis/processed_data/final_processed_data.csv"
  
  # Verificar que los archivos existan
  if (!file.exists(raw_data_path)) {
    stop("❌ No se encontró el archivo: ", raw_data_path)
  }
  if (!file.exists(processed_data_path)) {
    stop("❌ No se encontró el archivo: ", processed_data_path)
  }
  
  # Cargar datos
  raw_data <- read.table(raw_data_path, header = TRUE, sep = "\t", stringsAsFactors = FALSE)
  processed_data <- read.csv(processed_data_path, stringsAsFactors = FALSE)
  
  cat("✅ Datos cargados:\n")
  cat("   - Raw data:", nrow(raw_data), "filas\n")
  cat("   - Processed data:", nrow(processed_data), "filas\n")
  
  return(list(raw = raw_data, processed = processed_data))
}

# PANEL 1: Evolución del Dataset
create_panel_evolution <- function(data) {
  cat("📊 Creando Panel 1: Evolución del Dataset...\n")
  
  # Calcular estadísticas
  raw_snvs <- nrow(data$raw)
  processed_snvs <- nrow(data$processed)
  raw_mirnas <- length(unique(data$raw$miRNA_name))
  processed_mirnas <- length(unique(data$processed$miRNA_name))
  
  # Crear datos para el gráfico
  evolution_data <- data.frame(
    Step = c("Raw (Split)", "Processed (Collapse)"),
    SNVs = c(raw_snvs, processed_snvs),
    miRNAs = c(raw_mirnas, processed_mirnas)
  )
  
  # Gráfico de SNVs
  p_snvs <- ggplot(evolution_data, aes(x = Step, y = SNVs)) +
    geom_col(fill = c("steelblue", "darkgreen"), alpha = 0.8) +
    geom_text(aes(label = paste0(SNVs, "\n(", round((SNVs/raw_snvs)*100, 1), "%)")), 
              vjust = -0.5, size = 4) +
    labs(title = "A. Dataset Evolution",
         subtitle = "SNV count after processing steps",
         x = "Processing Step", y = "Number of SNVs") +
    theme_clean +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  return(p_snvs)
}

# PANEL 2: Distribución de Tipos de Mutación
create_panel_mutations <- function(data) {
  cat("📊 Creando Panel 2: Tipos de Mutación...\n")
  
  # Calcular tipos de mutación
  mutation_counts <- data$processed %>%
    mutate(mutation_type = str_extract(pos.mut, "^[ATGC]>[ATGC]")) %>%
    count(mutation_type, name = "count") %>%
    arrange(desc(count)) %>%
    mutate(
      percentage = round((count/sum(count))*100, 1),
      label = paste0(count, " (", percentage, "%)")
    )
  
  # Crear gráfico
  p_mutations <- ggplot(mutation_counts, aes(x = reorder(mutation_type, count), y = count)) +
    geom_col(fill = ifelse(mutation_counts$mutation_type == "G>T", COLOR_GT, "steelblue"), alpha = 0.8) +
    geom_text(aes(label = label), hjust = -0.1, size = 3) +
    labs(title = "B. Mutation Type Distribution",
         subtitle = paste("Total SNVs:", sum(mutation_counts$count)),
         x = "Mutation Type", y = "Count") +
    theme_clean +
    coord_flip()
  
  return(p_mutations)
}

# PANEL 3: G>X Spectrum por Posición (Figura favorita del usuario)
create_panel_spectrum <- function(data) {
  cat("📊 Creando Panel 3: G>X Spectrum...\n")
  
  # Calcular G>X mutations por posición
  spectrum_data <- data$processed %>%
    filter(str_detect(pos.mut, "^G>[ATGC]")) %>%
    mutate(
      mutation_type = str_extract(pos.mut, "^G>[ATGC]"),
      position = as.numeric(str_extract(pos.mut, "\\d+"))
    ) %>%
    count(position, mutation_type, name = "count") %>%
    complete(position = 1:22, mutation_type = c("G>A", "G>C", "G>T"), fill = list(count = 0))
  
  # Crear gráfico
  p_spectrum <- ggplot(spectrum_data, aes(x = position, y = count, fill = mutation_type)) +
    # Resaltar región semilla
    annotate("rect", xmin = 2, xmax = 8, ymin = -Inf, ymax = Inf,
             fill = COLOR_SEED, alpha = 0.2) +
    geom_col(position = "dodge", width = 0.7) +
    scale_fill_manual(values = c("G>A" = "steelblue", "G>C" = "darkgreen", "G>T" = COLOR_GT)) +
    labs(title = "C. G>X Mutation Spectrum by Position",
         subtitle = "Distribution of G mutations across miRNA positions",
         x = "Position in miRNA", y = "Mutation Count") +
    theme_clean +
    theme(legend.position = "bottom")
  
  return(p_spectrum)
}

# PANEL 4: Comparación Seed vs No-Seed
create_panel_seed_comparison <- function(data) {
  cat("📊 Creando Panel 4: Seed vs No-Seed...\n")
  
  # Calcular estadísticas por región
  region_stats <- data$processed %>%
    mutate(
      position = as.numeric(str_extract(pos.mut, "\\d+")),
      region = ifelse(position >= 2 & position <= 8, "Seed (2-8)", "No-Seed (9-22)"),
      is_gt = str_detect(pos.mut, "^G>T")
    ) %>%
    group_by(region) %>%
    summarise(
      total_snvs = n(),
      gt_snvs = sum(is_gt),
      gt_fraction = round((sum(is_gt)/n())*100, 1),
      .groups = "drop"
    )
  
  # Crear gráfico
  p_seed <- ggplot(region_stats, aes(x = region, y = total_snvs)) +
    geom_col(fill = c("darkgreen", "steelblue"), alpha = 0.8) +
    geom_text(aes(label = paste0(total_snvs, "\nG>T: ", gt_fraction, "%")), 
              vjust = -0.5, size = 4) +
    labs(title = "D. Seed vs No-Seed Comparison",
         subtitle = "SNV distribution and G>T fraction by region",
         x = "miRNA Region", y = "Total SNV Count") +
    theme_clean +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  return(p_seed)
}

# Función principal
main <- function() {
  cat("🎯 INICIANDO GENERACIÓN DE FIGURA 1 SIMPLE Y LIMPIA\n")
  cat(paste(rep("=", 60), collapse = ""), "\n")
  
  # Cargar datos
  data <- load_and_process_data()
  
  # Crear paneles
  panel_1 <- create_panel_evolution(data)
  panel_2 <- create_panel_mutations(data)
  panel_3 <- create_panel_spectrum(data)
  panel_4 <- create_panel_seed_comparison(data)
  
  # Combinar paneles en layout 2x2
  combined_figure <- (panel_1 | panel_2) / (panel_3 | panel_4)
  
  # Agregar título general
  combined_figure <- combined_figure + 
    plot_annotation(
      title = "FIGURE 1: INITIAL DATASET CHARACTERIZATION",
      subtitle = "miRNA mutation patterns and oxidative stress signatures",
      theme = theme(plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
                   plot.subtitle = element_text(size = 12, hjust = 0.5))
    )
  
  # Crear directorio si no existe
  if (!dir.exists("figures")) {
    dir.create("figures", recursive = TRUE)
  }
  
  # Guardar figura
  output_file <- "figures/FIGURE_1_SIMPLE_CLEAN.png"
  ggsave(output_file, combined_figure, width = 12, height = 10, dpi = 300, bg = "white")
  
  cat("✅ FIGURA GENERADA EXITOSAMENTE:\n")
  cat("   📁 Archivo:", output_file, "\n")
  cat("   📏 Dimensiones: 12x10 pulgadas\n")
  cat("   🎨 Layout: 2x2 (4 paneles limpios)\n")
  
  return(output_file)
}

# Ejecutar
if (interactive()) {
  main()
} else {
  main()
}
