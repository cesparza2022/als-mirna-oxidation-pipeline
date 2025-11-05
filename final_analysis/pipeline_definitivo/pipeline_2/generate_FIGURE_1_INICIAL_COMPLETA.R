# ============================================================================
# FIGURE 1: ANÁLISIS INICIAL COMPLETO - PIPELINE_2
# ============================================================================
# 
# OBJETIVO: Responder paso a paso las preguntas básicas del dataset
# ESTRUCTURA: 2x3 Grid (6 paneles)
# ESTILO: Profesional con G>T en rojo, números visibles, estadísticas
#
# PANELES:
# A: Evolución Dataset (split-collapse)
# B: Distribución Mutation Types (12 tipos)
# C: miRNAs y Familias
# D: G-Content por Posición
# E: G>X Spectrum por Posición (basado en figura favorita del usuario)
# F: Comparación Seed vs No-Seed
#
# ============================================================================

# Load required libraries
library(tidyverse)
library(ggplot2)
library(patchwork)
library(RColorBrewer)
library(viridis)
library(scales)
library(readr)

# ============================================================================
# CONFIGURACIÓN Y CONSTANTES
# ============================================================================

# Colores principales
COLOR_GT <- "#D62728"  # Rojo para G>T (oxidación)
COLOR_SEED <- "#FFF2CC"  # Amarillo claro para seed region
COLOR_NONSEED <- "#D5E8D4"  # Verde claro para no-seed
COLOR_SPLIT <- "#2166AC"  # Azul para split
COLOR_COLLAPSE <- "#5AAE61"  # Verde para collapse

# Paleta para mutation types
MUTATION_COLORS <- c(
  "G>T" = COLOR_GT,
  "G>A" = "#1F77B4",  # Azul
  "G>C" = "#2CA02C",  # Verde
  "A>C" = "#FF7F0E",  # Naranja
  "A>G" = "#9467BD",  # Morado
  "A>T" = "#8C564B",  # Marrón
  "C>A" = "#E377C2",  # Rosa
  "C>G" = "#7F7F7F",  # Gris
  "C>T" = "#BCBD22",  # Lima
  "T>A" = "#17BECF",  # Cian
  "T>C" = "#D62728",  # Rojo
  "T>G" = "#FF9896"   # Rosa claro
)

# Configuración de tema
theme_professional <- theme_classic() +
  theme(
    text = element_text(family = "Arial", size = 12),
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5),
    axis.title = element_text(size = 11, face = "bold"),
    axis.text = element_text(size = 10),
    legend.title = element_text(size = 10, face = "bold"),
    legend.text = element_text(size = 9),
    panel.grid.major = element_line(color = "grey90", size = 0.3),
    panel.grid.minor = element_blank(),
    strip.background = element_rect(fill = "grey95", color = "grey80"),
    strip.text = element_text(size = 10, face = "bold")
  )

# ============================================================================
# FUNCIONES DE CARGA Y PROCESAMIENTO
# ============================================================================

load_and_process_data <- function() {
  cat("📥 Cargando y procesando datos...\n")
  
  # Cargar datos raw
  raw_data_path <- "../../../final_analysis/data/raw/miRNA_count.Q33.txt"
  if (!file.exists(raw_data_path)) {
    stop("❌ No se encontró el archivo de datos: ", raw_data_path)
  }
  
  raw_data <- read_tsv(raw_data_path, show_col_types = FALSE)
  cat("✅ Datos raw cargados:", nrow(raw_data), "filas\n")
  
  # Cargar datos procesados (usar processed_data del directorio padre)
  processed_data_path <- "../../../final_analysis/processed_data/final_processed_data.csv"
  if (!file.exists(processed_data_path)) {
    stop("❌ No se encontró el archivo de datos procesados: ", processed_data_path)
  }
  
  processed_data <- read_csv(processed_data_path, show_col_types = FALSE)
  cat("✅ Datos procesados cargados:", nrow(processed_data), "filas\n")
  
  return(list(raw = raw_data, processed = processed_data))
}

# ============================================================================
# FUNCIONES DE PANELES INDIVIDUALES
# ============================================================================

# PANEL A: Evolución del Dataset
create_panel_a_evolution <- function(raw_data, processed_data) {
  cat("📊 Creando Panel A: Evolución del Dataset...\n")
  
  # Calcular estadísticas
  raw_snvs <- nrow(raw_data)
  raw_mirnas <- length(unique(raw_data$miRNA_name))
  
  processed_snvs <- nrow(processed_data)
  processed_mirnas <- length(unique(processed_data$miRNA_name))
  
  # Crear datos para el gráfico
  evolution_data <- data.frame(
    Step = c("Split", "Collapse"),
    SNVs = c(raw_snvs, processed_snvs),
    miRNAs = c(raw_mirnas, processed_mirnas),
    Color = c(COLOR_SPLIT, COLOR_COLLAPSE)
  )
  
  # Calcular porcentajes de reducción
  snv_reduction <- round((1 - processed_snvs/raw_snvs) * 100, 1)
  mirna_reduction <- round((1 - processed_mirnas/raw_mirnas) * 100, 1)
  
  # Crear gráfico de SNVs
  p_snvs <- ggplot(evolution_data, aes(x = Step, y = SNVs, fill = Color)) +
    geom_col(width = 0.7) +
    geom_text(aes(label = paste0(SNVs, "\n(", 
                                ifelse(Step == "Split", "", paste0("-", snv_reduction, "%")), ")")), 
              vjust = -0.5, size = 3.5, fontface = "bold") +
    scale_fill_identity() +
    labs(
      title = "A. Dataset Evolution",
      subtitle = paste0("SNV Count: ", raw_snvs, " → ", processed_snvs),
      x = "Processing Step",
      y = "Number of SNVs"
    ) +
    theme_professional +
    theme(legend.position = "none")
  
  # Crear gráfico de miRNAs
  p_mirnas <- ggplot(evolution_data, aes(x = Step, y = miRNAs, fill = Color)) +
    geom_col(width = 0.7) +
    geom_text(aes(label = paste0(miRNAs, "\n(", 
                                ifelse(Step == "Split", "", paste0("-", mirna_reduction, "%")), ")")), 
              vjust = -0.5, size = 3.5, fontface = "bold") +
    scale_fill_identity() +
    labs(
      x = "Processing Step",
      y = "Number of miRNAs"
    ) +
    theme_professional +
    theme(legend.position = "none")
  
  # Combinar subpaneles
  panel_a <- p_snvs / p_mirnas + 
    plot_layout(heights = c(1, 1))
  
  return(panel_a)
}

# PANEL B: Distribución de Tipos de Mutación
create_panel_b_mutation_types <- function(processed_data) {
  cat("📊 Creando Panel B: Distribución de Mutation Types...\n")
  
  # Extraer tipos de mutación de la columna pos.mut
  mutation_types <- processed_data %>%
    mutate(mutation_type = str_extract(pos.mut, "^[ATGC]>[ATGC]")) %>%
    filter(!is.na(mutation_type)) %>%
    count(mutation_type, name = "count") %>%
    mutate(percentage = round(count / sum(count) * 100, 1)) %>%
    arrange(desc(count))
  
  # Asegurar que tenemos los 12 tipos
  all_types <- c("A>C", "A>G", "A>T", "C>A", "C>G", "C>T", 
                 "G>A", "G>C", "G>T", "T>A", "T>C", "T>G")
  
  mutation_types <- mutation_types %>%
    complete(mutation_type = all_types, fill = list(count = 0, percentage = 0)) %>%
    arrange(desc(count))
  
  # Crear gráfico
  panel_b <- ggplot(mutation_types, aes(x = reorder(mutation_type, count), y = count, fill = mutation_type)) +
    geom_col(width = 0.8) +
    geom_text(aes(label = paste0(count, "\n(", percentage, "%)")), 
              hjust = -0.1, size = 3, fontface = "bold") +
    scale_fill_manual(values = MUTATION_COLORS, name = "Mutation Type") +
    coord_flip() +
    labs(
      title = "B. Mutation Type Distribution",
      subtitle = paste0("Total SNVs: ", sum(mutation_types$count)),
      x = "Mutation Type",
      y = "Count (Percentage)"
    ) +
    theme_professional +
    theme(
      legend.position = "none",
      axis.text.x = element_text(angle = 0)
    )
  
  return(panel_b)
}

# PANEL C: miRNAs - Características Generales del Dataset
create_panel_c_mirnas <- function(processed_data) {
  cat("📊 Creando Panel C: Características Generales de miRNAs...\n")
  
  # Calcular estadísticas básicas
  total_mirnas <- length(unique(processed_data$miRNA_name))
  mirna_lengths <- processed_data %>%
    mutate(position = as.numeric(str_extract(pos.mut, "\\d+"))) %>%
    group_by(miRNA_name) %>%
    summarise(length = max(position), .groups = "drop") %>%
    pull(length)
  
  mean_length <- round(mean(mirna_lengths), 1)
  sd_length <- round(sd(mirna_lengths), 1)
  min_length <- min(mirna_lengths)
  max_length <- max(mirna_lengths)
  
  # SNVs por miRNA
  snvs_per_mirna <- processed_data %>%
    count(miRNA_name, name = "snv_count")
  
  mean_snvs <- round(mean(snvs_per_mirna$snv_count), 1)
  sd_snvs <- round(sd(snvs_per_mirna$snv_count), 1)
  
  # Subpanel C1: Estadísticas generales (más informativo)
  p_stats <- ggplot() +
    # Cuadro superior: Total miRNAs
    annotate("rect", xmin = 0, xmax = 1, ymin = 0.7, ymax = 1, 
             fill = "#f8f9fa", color = "#e9ecef", size = 1) +
    annotate("text", x = 0.5, y = 0.88, 
             label = "Total Unique miRNAs", 
             size = 5, fontface = "bold", hjust = 0.5) +
    annotate("text", x = 0.5, y = 0.78, 
             label = total_mirnas, 
             size = 12, fontface = "bold", hjust = 0.5, color = COLOR_GT) +
    
    # Cuadro medio: Longitudes
    annotate("rect", xmin = 0, xmax = 1, ymin = 0.38, ymax = 0.65, 
             fill = "#f8f9fa", color = "#e9ecef", size = 1) +
    annotate("text", x = 0.5, y = 0.60, 
             label = "miRNA Lengths (nt)", 
             size = 4.5, fontface = "bold", hjust = 0.5) +
    annotate("text", x = 0.5, y = 0.53,
             label = paste0("Mean: ", mean_length, " ± ", sd_length),
             size = 4, hjust = 0.5) +
    annotate("text", x = 0.5, y = 0.45,
             label = paste0("Range: ", min_length, " - ", max_length),
             size = 3.5, hjust = 0.5, color = "gray30") +
    
    # Cuadro inferior: SNVs por miRNA
    annotate("rect", xmin = 0, xmax = 1, ymin = 0.05, ymax = 0.33, 
             fill = "#fff3cd", color = "#ffeaa7", size = 1) +
    annotate("text", x = 0.5, y = 0.28, 
             label = "SNVs per miRNA", 
             size = 4.5, fontface = "bold", hjust = 0.5) +
    annotate("text", x = 0.5, y = 0.20,
             label = paste0("Mean: ", mean_snvs, " ± ", sd_snvs),
             size = 4, hjust = 0.5) +
    annotate("text", x = 0.5, y = 0.11,
             label = paste0(nrow(processed_data), " total SNVs"),
             size = 3.5, hjust = 0.5, color = "gray20") +
    
    xlim(0, 1) + ylim(0, 1) +
    theme_void() +
    labs(title = "C1. Dataset Overview")
  
  # Subpanel C2: Distribución de SNVs por miRNA (histograma)
  p_dist <- ggplot(snvs_per_mirna, aes(x = snv_count)) +
    geom_histogram(bins = 30, fill = "steelblue", color = "white", alpha = 0.8) +
    geom_vline(xintercept = mean_snvs, color = COLOR_GT, 
               linetype = "dashed", size = 1) +
    annotate("text", x = mean_snvs * 1.1, y = Inf, 
             label = paste0("Mean: ", mean_snvs),
             color = COLOR_GT, hjust = 0, vjust = 1.5, size = 4, fontface = "bold") +
    labs(
      title = "C2. Distribution of SNVs per miRNA",
      x = "Number of SNVs per miRNA",
      y = "Number of miRNAs"
    ) +
    theme_professional +
    theme(
      plot.title = element_text(size = 12, face = "bold"),
      axis.title = element_text(size = 11)
    )
  
  # Combinar subpaneles (horizontalmente)
  panel_c <- p_stats + p_dist + 
    plot_layout(ncol = 2, widths = c(1, 1.5))
  
  return(panel_c)
}

# PANEL D: G-Content por Posición
create_panel_d_gcontent <- function(processed_data) {
  cat("📊 Creando Panel D: G-Content por Posición...\n")
  
  # Calcular G-content por posición (extraer posición de pos.mut)
  g_content <- processed_data %>%
    filter(str_detect(pos.mut, "^G>")) %>%
    mutate(position = as.numeric(str_extract(pos.mut, "\\d+"))) %>%
    count(position, name = "g_count") %>%
    complete(position = 1:22, fill = list(g_count = 0)) %>%
    arrange(position)
  
  # Estadísticas
  mean_g <- round(mean(g_content$g_count), 1)
  sd_g <- round(sd(g_content$g_count), 1)
  
  # Crear gráfico
  panel_d <- ggplot(g_content, aes(x = position, y = g_count)) +
    annotate("rect", xmin = 2, xmax = 8, ymin = -Inf, ymax = Inf, 
             fill = COLOR_SEED, alpha = 0.3) +
    geom_col(fill = "steelblue", width = 0.8) +
    geom_text(aes(label = g_count), vjust = -0.5, size = 3, fontface = "bold") +
    scale_x_continuous(breaks = seq(1, 22, 2)) +
    labs(
      title = paste0("D. G-Content by Position (Mean ± SD: ", mean_g, " ± ", sd_g, ")"),
      subtitle = "Number of G nucleotides per position",
      x = "Position in miRNA",
      y = "Number of G nucleotides"
    ) +
    theme_professional +
    theme(legend.position = "none")
  
  return(panel_d)
}

# PANEL E: G>X Spectrum por Posición (Basado en figura favorita del usuario)
create_panel_e_spectrum <- function(processed_data) {
  cat("📊 Creando Panel E: G>X Spectrum por Posición...\n")
  
  # Calcular G>X mutations por posición
  gx_spectrum <- processed_data %>%
    filter(str_detect(pos.mut, "^G>[ATGC]")) %>%
    mutate(
      mutation_type = str_extract(pos.mut, "^G>[ATGC]"),
      position = as.numeric(str_extract(pos.mut, "\\d+"))
    ) %>%
    count(position, mutation_type, name = "count") %>%
    complete(position = 1:22, mutation_type = c("G>A", "G>C", "G>T"), fill = list(count = 0)) %>%
    arrange(position, mutation_type)
  
  # Crear gráfico (basado en la figura favorita del usuario)
  panel_e <- ggplot(gx_spectrum, aes(x = position, y = count, fill = mutation_type)) +
    annotate("rect", xmin = 2, xmax = 8, ymin = -Inf, ymax = Inf, 
             fill = COLOR_SEED, alpha = 0.3) +
    geom_col(position = "dodge", width = 0.8) +
    geom_text(aes(label = ifelse(count > 0, count, "")), 
              position = position_dodge(width = 0.8), 
              vjust = -0.5, size = 2.5, fontface = "bold") +
    scale_x_continuous(breaks = seq(1, 22, 2)) +
    scale_fill_manual(values = c("G>A" = "#1F77B4", "G>C" = "#2CA02C", "G>T" = COLOR_GT),
                      name = "G>X Mutation") +
    labs(
      title = "E. G>X Mutation Spectrum by Position",
      subtitle = "Distribution of G>A, G>C, and G>T mutations across miRNA positions",
      x = "Position in miRNA",
      y = "Mutation Count"
    ) +
    theme_professional +
    theme(
      legend.position = "top",
      legend.direction = "horizontal"
    ) +
    guides(fill = guide_legend(title = "G>X Mutation Type", override.aes = list(size = 3)))
  
  # Agregar nota sobre G>T
  panel_e <- panel_e + 
    annotate("text", x = 22, y = max(gx_spectrum$count) * 0.9, 
             label = "G>T is highlighted as the primary oxidative stress signature", 
             size = 3, hjust = 1, fontface = "italic")
  
  return(panel_e)
}

# PANEL F: Comparación Seed vs No-Seed
create_panel_f_seed_comparison <- function(processed_data) {
  cat("📊 Creando Panel F: Comparación Seed vs No-Seed...\n")
  
  # Definir regiones
  seed_positions <- 2:8
  nonseed_positions <- 9:22
  
  # Calcular métricas por región
  processed_with_pos <- processed_data %>%
    mutate(position = as.numeric(str_extract(pos.mut, "\\d+")))
  
  seed_data <- processed_with_pos %>%
    filter(position %in% seed_positions) %>%
    summarise(
      region = "Seed (2-8)",
      total_snvs = n(),
      gt_snvs = sum(str_detect(pos.mut, "^G>T")),
      g_content = sum(str_detect(pos.mut, "^G>")),
      mean_snv_per_pos = round(total_snvs / length(seed_positions), 1)
    )
  
  nonseed_data <- processed_with_pos %>%
    filter(position %in% nonseed_positions) %>%
    summarise(
      region = "No-Seed (9-22)",
      total_snvs = n(),
      gt_snvs = sum(str_detect(pos.mut, "^G>T")),
      g_content = sum(str_detect(pos.mut, "^G>")),
      mean_snv_per_pos = round(total_snvs / length(nonseed_positions), 1)
    )
  
  comparison_data <- bind_rows(seed_data, nonseed_data) %>%
    mutate(
      gt_fraction = round(gt_snvs / total_snvs * 100, 1),
      g_fraction = round(g_content / total_snvs * 100, 1)
    )
  
  # Crear gráfico de barras comparativo
  p_comparison <- ggplot(comparison_data, aes(x = region, y = total_snvs, fill = region)) +
    geom_col(width = 0.6) +
    geom_text(aes(label = paste0(total_snvs, "\n(", mean_snv_per_pos, "/pos)")), 
              vjust = -0.5, size = 3.5, fontface = "bold") +
    scale_fill_manual(values = c("Seed (2-8)" = COLOR_SEED, "No-Seed (9-22)" = COLOR_NONSEED)) +
    labs(
      title = "F. Seed vs No-Seed Comparison",
      subtitle = "SNV distribution across functional regions",
      x = "miRNA Region",
      y = "Total SNV Count"
    ) +
    theme_professional +
    theme(legend.position = "none")
  
  # Crear tabla de estadísticas
  stats_table <- comparison_data %>%
    select(region, total_snvs, gt_snvs, gt_fraction, g_content, g_fraction) %>%
    pivot_longer(cols = -region, names_to = "metric", values_to = "value") %>%
    pivot_wider(names_from = region, values_from = value)
  
  # Test estadístico (simplificado)
  seed_gt <- seed_data$gt_fraction
  nonseed_gt <- nonseed_data$gt_fraction
  
  # Crear panel con tabla
  p_table <- ggplot() +
    annotate("text", x = 0.5, y = 0.5, 
             label = paste0(
               "Seed G>T: ", seed_data$gt_fraction, "%\n",
               "No-Seed G>T: ", nonseed_data$gt_fraction, "%\n",
               "Difference: ", abs(seed_gt - nonseed_gt), "%"
             ),
             size = 4, hjust = 0.5, vjust = 0.5) +
    labs(title = "G>T Fraction Comparison") +
    theme_void() +
    theme(plot.title = element_text(size = 12, face = "bold", hjust = 0.5))
  
  # Combinar gráfico y tabla
  panel_f <- p_comparison / p_table + 
    plot_layout(heights = c(2, 1))
  
  return(panel_f)
}

# ============================================================================
# FUNCIÓN PRINCIPAL
# ============================================================================

generate_figure_1_inicial_completa <- function() {
  cat("🚀 ═══════════════════════════════════════════════════════════\n")
  cat("   FIGURE 1: ANÁLISIS INICIAL COMPLETO\n")
  cat("   ═══════════════════════════════════════════════════════════\n")
  
  # Cargar datos
  data_list <- load_and_process_data()
  raw_data <- data_list$raw
  processed_data <- data_list$processed
  
  # Crear paneles
  cat("\n📊 Generando paneles individuales...\n")
  
  panel_a <- create_panel_a_evolution(raw_data, processed_data)
  panel_b <- create_panel_b_mutation_types(processed_data)
  panel_c <- create_panel_c_mirnas(processed_data)
  panel_d <- create_panel_d_gcontent(processed_data)
  panel_e <- create_panel_e_spectrum(processed_data)
  panel_f <- create_panel_f_seed_comparison(processed_data)
  
  # Combinar en figura final (2x3 grid)
  cat("\n🖼️  Combinando paneles en figura final...\n")
  
  figure_1 <- (panel_a | panel_b | panel_c) / 
              (panel_d | panel_e | panel_f) +
    plot_layout(ncol = 3, nrow = 2) +
    plot_annotation(
      title = "FIGURE 1: COMPREHENSIVE INITIAL DATASET ANALYSIS",
      subtitle = "Characterization of miRNA mutations and oxidative stress patterns",
      theme = theme(
        plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray60")
      )
    )
  
  # Guardar figura
  output_file <- "FIGURE_1_INICIAL_COMPLETA.png"
  ggsave(output_file, figure_1, width = 18, height = 12, dpi = 300, bg = "white")
  
  cat("✅ Figura guardada:", output_file, "\n")
  
  # Guardar datos de respaldo
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  backup_file <- paste0("FIGURE_1_INICIAL_COMPLETA_", timestamp, ".png")
  ggsave(backup_file, figure_1, width = 18, height = 12, dpi = 300, bg = "white")
  cat("✅ Backup guardado:", backup_file, "\n")
  
  # Registrar en log
  log_entry <- paste0(
    timestamp, " | FIGURE_1_INICIAL_COMPLETA | ",
    "6 panels: Evolution, Mutation Types, miRNAs, G-Content, G>X Spectrum, Seed Comparison | ",
    "Professional style with G>T in red, numbers visible, complete statistics"
  )
  
  write(log_entry, "REGISTRO_VERSIONES.txt", append = TRUE)
  
  cat("\n🎉 ═══════════════════════════════════════════════════════════\n")
  cat("   FIGURE 1 INICIAL COMPLETA GENERADA EXITOSAMENTE\n")
  cat("   ═══════════════════════════════════════════════════════════\n")
  
  return(figure_1)
}

# ============================================================================
# EJECUTAR
# ============================================================================

if (!interactive()) {
  generate_figure_1_inicial_completa()
}
