# 🎨 FUNCIONES DE VISUALIZACIÓN - PIPELINE_2

library(ggplot2)
library(dplyr)
library(tidyr)
library(patchwork)
library(viridis)
library(RColorBrewer)

## 📊 FIGURA 1: CARACTERIZACIÓN DEL DATASET

### **Panel A: Evolución del Dataset**
create_dataset_evolution_panel <- function(raw_data, processed_data) {
  # Calcular estadísticas de evolución
  stats <- data.frame(
    step = c("Original", "Split-Collapse", "VAF Filter", "Final"),
    snvs = c(nrow(raw_data), 
             nrow(processed_data),
             nrow(processed_data %>% filter(vaf <= 0.5)),
             nrow(processed_data %>% filter(vaf <= 0.5, coverage >= 10))),
    mirnas = c(length(unique(raw_data$`miRNA name`)),
               length(unique(processed_data$`miRNA name`)),
               length(unique(processed_data %>% filter(vaf <= 0.5) %>% pull(`miRNA name`))),
               length(unique(processed_data %>% filter(vaf <= 0.5, coverage >= 10) %>% pull(`miRNA name`))))
  )
  
  # Crear gráfica
  p <- ggplot(stats, aes(x = step, y = snvs)) +
    geom_col(aes(fill = step), alpha = 0.8) +
    geom_text(aes(label = paste0(snvs, "\n(", mirnas, " miRNAs)")), 
              vjust = -0.5, size = 3) +
    scale_fill_viridis_d() +
    labs(title = "Evolución del Dataset",
         x = "Paso de Procesamiento",
         y = "Número de SNVs",
         fill = "Paso") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  return(p)
}

### **Panel B: Heatmap Posicional de SNVs G>T (Inspirado en Paper)**
create_positional_heatmap_panel <- function(data) {
  # Filtrar solo mutaciones G>T
  gt_data <- data %>% 
    filter(str_detect(`pos:mut`, "G>T")) %>%
    mutate(position = as.numeric(str_extract(`pos:mut`, "^[0-9]+")))
  
  # Calcular conteos por posición
  position_counts <- gt_data %>%
    group_by(position, `miRNA name`) %>%
    summarise(count = n(), .groups = "drop") %>%
    group_by(position) %>%
    summarise(
      total_snvs = sum(count),
      unique_mirnas = n(),
      .groups = "drop"
    ) %>%
    filter(!is.na(position), position <= 22)
  
  # Crear heatmap
  p <- ggplot(position_counts, aes(x = position, y = 1)) +
    geom_tile(aes(fill = total_snvs), color = "white") +
    geom_text(aes(label = paste0(total_snvs, "\n(", unique_mirnas, ")")), 
              color = "white", size = 3) +
    scale_fill_viridis_c(name = "SNVs G>T") +
    scale_x_continuous(breaks = 1:22, labels = 1:22) +
    labs(title = "Distribución Posicional de SNVs G>T",
         x = "Posición en miRNA",
         y = "") +
    theme_minimal() +
    theme(axis.text.y = element_blank(),
          axis.ticks.y = element_blank(),
          panel.grid = element_blank())
  
  return(p)
}

### **Panel C: Tipos de Mutación G→X por Posición (Inspirado en Paper)**
create_mutation_types_panel <- function(data) {
  # Extraer tipos de mutación G→X
  g_mutations <- data %>%
    filter(str_detect(`pos:mut`, "G>")) %>%
    mutate(
      position = as.numeric(str_extract(`pos:mut`, "^[0-9]+")),
      mutation_type = str_extract(`pos:mut`, "G>[ATCG]")
    ) %>%
    filter(!is.na(position), !is.na(mutation_type), position <= 22)
  
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
    geom_col(position = "stack") +
    scale_fill_brewer(name = "Tipo de Mutación", palette = "Set2") +
    scale_x_continuous(breaks = 1:22, labels = 1:22) +
    scale_y_continuous(labels = scales::percent) +
    labs(title = "Tipos de Mutación G→X por Posición",
         x = "Posición en miRNA",
         y = "Fracción de Mutaciones") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  return(p)
}

### **Panel D: Top miRNAs con Más Mutaciones G>T**
create_top_mirnas_panel <- function(data, top_n = 15) {
  # Calcular top miRNAs
  top_mirnas <- data %>%
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
  p <- ggplot(top_mirnas, aes(x = reorder(`miRNA name`, total_gt_mutations), y = total_gt_mutations)) +
    geom_col(aes(fill = unique_positions), alpha = 0.8) +
    geom_text(aes(label = paste0(total_gt_mutations, "\n(", unique_positions, " pos)")), 
              hjust = -0.1, size = 3) +
    scale_fill_viridis_c(name = "Posiciones Únicas") +
    labs(title = paste0("Top ", top_n, " miRNAs con Más Mutaciones G>T"),
         x = "miRNA",
         y = "Número de Mutaciones G>T") +
    coord_flip() +
    theme_minimal()
  
  return(p)
}

### **Función Principal: Crear Figura 1 Completa**
create_figure_1_dataset_characterization <- function(data, output_dir) {
  # Crear cada panel
  panel_a <- create_dataset_evolution_panel(data$raw, data$processed)
  panel_b <- create_positional_heatmap_panel(data$processed)
  panel_c <- create_mutation_types_panel(data$processed)
  panel_d <- create_top_mirnas_panel(data$processed)
  
  # Combinar paneles
  figure_1 <- (panel_a | panel_b) / (panel_c | panel_d)
  
  # Agregar título general
  figure_1 <- figure_1 + 
    plot_annotation(
      title = "FIGURA 1: CARACTERIZACIÓN DEL DATASET",
      subtitle = "Análisis de estructura, distribución posicional y miRNAs más afectados por estrés oxidativo",
      theme = theme(plot.title = element_text(size = 16, face = "bold"),
                    plot.subtitle = element_text(size = 12))
    )
  
  # Guardar figura
  ggsave(file.path(output_dir, "figura_1_caracterizacion_dataset.png"), 
         figure_1, width = 16, height = 12, dpi = 300)
  
  return(figure_1)
}

