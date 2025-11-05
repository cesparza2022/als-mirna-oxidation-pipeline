# 🎨 FUNCIONES DE VISUALIZACIÓN SIMPLIFICADAS - PIPELINE_2

library(ggplot2)
library(dplyr)
library(tidyr)
library(stringr)
library(patchwork)
library(viridis)

## 📊 FIGURA 1: CARACTERIZACIÓN DEL DATASET (VERSIÓN SIMPLIFICADA)

### **Panel A: Evolución del Dataset**
create_dataset_evolution_panel_simple <- function(data) {
  # Contar SNVs y miRNAs en diferentes etapas
  stats <- data.frame(
    step = c("Original", "Procesado"),
    snvs = c(nrow(data$raw), nrow(data$processed)),
    mirnas = c(length(unique(data$raw$`miRNA name`)), 
               length(unique(data$processed$`miRNA name`)))
  )
  
  # Crear gráfica
  p <- ggplot(stats, aes(x = step, y = snvs)) +
    geom_col(aes(fill = step), alpha = 0.8, width = 0.6) +
    geom_text(aes(label = paste0(format(snvs, big.mark=","), "\nSNVs\n", 
                                  format(mirnas, big.mark=","), " miRNAs")), 
              vjust = -0.3, size = 4, fontface = "bold") +
    scale_fill_viridis_d(begin = 0.3, end = 0.7) +
    scale_y_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.15))) +
    labs(title = "A. Evolución del Dataset",
         subtitle = "Transformación de datos crudos a procesados",
         x = NULL,
         y = "Número de SNVs") +
    theme_minimal(base_size = 12) +
    theme(legend.position = "none",
          plot.title = element_text(face = "bold", size = 14),
          plot.subtitle = element_text(size = 10, color = "gray30"),
          axis.text.x = element_text(size = 11, face = "bold"),
          panel.grid.major.x = element_blank())
  
  return(p)
}

### **Panel B: Heatmap Posicional de SNVs G>T**
create_positional_heatmap_panel_simple <- function(data) {
  # Filtrar solo mutaciones G>T
  gt_data <- data$processed %>%
    filter(str_detect(`pos:mut`, "G>T")) %>%
    mutate(position = as.numeric(str_extract(`pos:mut`, "^[0-9]+"))) %>%
    filter(!is.na(position), position >= 1, position <= 22)
  
  # Calcular conteos por posición
  position_counts <- gt_data %>%
    group_by(position) %>%
    summarise(
      total_snvs = n(),
      unique_mirnas = n_distinct(`miRNA name`),
      .groups = "drop"
    )
  
  # Crear heatmap
  p <- ggplot(position_counts, aes(x = position, y = 1)) +
    geom_tile(aes(fill = total_snvs), color = "white", size = 0.5) +
    geom_text(aes(label = paste0(total_snvs, "\n(", unique_mirnas, ")")), 
              color = "white", size = 3, fontface = "bold") +
    scale_fill_viridis_c(name = "SNVs G>T", option = "plasma") +
    scale_x_continuous(breaks = 1:22, labels = 1:22, expand = c(0,0)) +
    labs(title = "B. Distribución Posicional de Mutaciones G>T",
         subtitle = "Número de SNVs y miRNAs únicos por posición (1-22)",
         x = "Posición en miRNA",
         y = NULL) +
    theme_minimal(base_size = 12) +
    theme(axis.text.y = element_blank(),
          axis.ticks.y = element_blank(),
          panel.grid = element_blank(),
          plot.title = element_text(face = "bold", size = 14),
          plot.subtitle = element_text(size = 10, color = "gray30"),
          legend.position = "right")
  
  return(p)
}

### **Panel C: Tipos de Mutación G→X por Posición**
create_mutation_types_panel_simple <- function(data) {
  # Extraer tipos de mutación G→X
  g_mutations <- data$processed %>%
    filter(str_detect(`pos:mut`, "G>")) %>%
    mutate(
      position = as.numeric(str_extract(`pos:mut`, "^[0-9]+")),
      mutation_type = str_extract(`pos:mut`, "G>[ATCG]")
    ) %>%
    filter(!is.na(position), !is.na(mutation_type), 
           position >= 1, position <= 22)
  
  # Calcular fracciones por posición
  mutation_fractions <- g_mutations %>%
    group_by(position, mutation_type) %>%
    summarise(count = n(), .groups = "drop") %>%
    group_by(position) %>%
    mutate(
      total = sum(count),
      fraction = count / total
    ) %>%
    ungroup()
  
  # Crear gráfica
  p <- ggplot(mutation_fractions, aes(x = position, y = fraction, fill = mutation_type)) +
    geom_col(position = "stack", width = 0.8) +
    scale_fill_brewer(name = "Tipo", palette = "Set2",
                      labels = c("G>A", "G>C", "G>T")) +
    scale_x_continuous(breaks = seq(2, 22, 2), labels = seq(2, 22, 2)) +
    scale_y_continuous(labels = scales::percent, expand = c(0,0)) +
    labs(title = "C. Tipos de Mutación G→X por Posición",
         subtitle = "Fracción relativa de cada tipo de mutación",
         x = "Posición en miRNA",
         y = "Fracción de Mutaciones") +
    theme_minimal(base_size = 12) +
    theme(plot.title = element_text(face = "bold", size = 14),
          plot.subtitle = element_text(size = 10, color = "gray30"),
          legend.position = "right",
          panel.grid.major.x = element_blank())
  
  return(p)
}

### **Panel D: Top miRNAs con Más Mutaciones G>T**
create_top_mirnas_panel_simple <- function(data, top_n = 15) {
  # Calcular top miRNAs
  top_mirnas <- data$processed %>%
    filter(str_detect(`pos:mut`, "G>T")) %>%
    group_by(`miRNA name`) %>%
    summarise(
      total_gt_mutations = n(),
      unique_positions = n_distinct(str_extract(`pos:mut`, "^[0-9]+")),
      .groups = "drop"
    ) %>%
    arrange(desc(total_gt_mutations)) %>%
    head(top_n)
  
  # Crear gráfica
  p <- ggplot(top_mirnas, aes(x = reorder(`miRNA name`, total_gt_mutations), 
                               y = total_gt_mutations)) +
    geom_col(aes(fill = unique_positions), alpha = 0.9) +
    geom_text(aes(label = paste0(total_gt_mutations)), 
              hjust = -0.2, size = 3.5, fontface = "bold") +
    scale_fill_viridis_c(name = "Posiciones\nÚnicas", option = "viridis") +
    scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
    labs(title = paste0("D. Top ", top_n, " miRNAs con Más Mutaciones G>T"),
         subtitle = "Número de mutaciones y posiciones únicas afectadas",
         x = NULL,
         y = "Número de Mutaciones G>T") +
    coord_flip() +
    theme_minimal(base_size = 12) +
    theme(plot.title = element_text(face = "bold", size = 14),
          plot.subtitle = element_text(size = 10, color = "gray30"),
          axis.text.y = element_text(size = 9),
          legend.position = "right")
  
  return(p)
}

### **Función Principal: Crear Figura 1 Completa (SIMPLIFICADA)**
create_figure_1_simple <- function(data, output_dir) {
  cat("📊 Generando paneles de Figura 1...\n")
  
  # Crear cada panel
  panel_a <- create_dataset_evolution_panel_simple(data)
  cat("  ✅ Panel A generado\n")
  
  panel_b <- create_positional_heatmap_panel_simple(data)
  cat("  ✅ Panel B generado\n")
  
  panel_c <- create_mutation_types_panel_simple(data)
  cat("  ✅ Panel C generado\n")
  
  panel_d <- create_top_mirnas_panel_simple(data)
  cat("  ✅ Panel D generado\n")
  
  # Combinar paneles
  figure_1 <- (panel_a | panel_b) / (panel_c | panel_d)
  
  # Agregar título general
  figure_1 <- figure_1 + 
    plot_annotation(
      title = "FIGURA 1: CARACTERIZACIÓN DEL DATASET",
      subtitle = "Análisis de estructura, distribución posicional y miRNAs más afectados por estrés oxidativo (G>T)",
      theme = theme(plot.title = element_text(size = 18, face = "bold", hjust = 0.5),
                    plot.subtitle = element_text(size = 13, hjust = 0.5, color = "gray30"))
    )
  
  # Guardar figura
  output_file <- file.path(output_dir, "figura_1_caracterizacion_dataset.png")
  ggsave(output_file, figure_1, width = 18, height = 14, dpi = 300, bg = "white")
  cat("\n💾 Figura guardada en:", output_file, "\n")
  
  return(figure_1)
}

