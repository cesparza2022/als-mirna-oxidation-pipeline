# 🎨 VISUALIZATION FUNCTIONS V4 - CORRECTED MUTATION FORMAT

library(ggplot2)
library(dplyr)
library(tidyr)
library(stringr)
library(patchwork)
library(viridis)
library(RColorBrewer)

## 📊 FIGURE 1: INITIAL ANALYSIS ONLY (CORRECTED MUTATION FORMAT)

### **Panel A: Dataset Evolution + Mutation Types (CORRECTED)**
create_dataset_overview_corrected <- function(data) {
  
  # Parte 1: Evolución del dataset (CORRECTED LABELS - CLEARER)
  evolution <- data.frame(
    step = factor(c("Raw Entries", "Individual SNVs"), levels = c("Raw Entries", "Individual SNVs")),
    snvs = c(nrow(data$raw), nrow(data$processed)),
    mirnas = c(length(unique(data$raw$`miRNA name`)), 
               length(unique(data$processed$`miRNA name`)))
  )
  
  # Parte 2: Tipos de mutación (CORRECTED FORMAT: TC, AG, etc.)
  mutation_types <- data$processed %>%
    filter(`pos:mut` != "PM") %>%  # Remove Perfect Matches
    separate(`pos:mut`, into = c("position", "mutation_type"), sep = ":", remove = FALSE) %>%
    filter(!is.na(mutation_type), mutation_type != "") %>%
    # Convert format: TC -> T>C, AG -> A>G, etc.
    mutate(
      mutation_type_formatted = case_when(
        mutation_type == "GT" ~ "G>T",
        mutation_type == "TC" ~ "T>C", 
        mutation_type == "AG" ~ "A>G",
        mutation_type == "GA" ~ "G>A",
        mutation_type == "CT" ~ "C>T",
        mutation_type == "TA" ~ "T>A",
        mutation_type == "TG" ~ "T>G",
        mutation_type == "AT" ~ "A>T",
        mutation_type == "CA" ~ "C>A",
        mutation_type == "CG" ~ "C>G",
        mutation_type == "GC" ~ "G>C",
        mutation_type == "AC" ~ "A>C",
        TRUE ~ mutation_type
      )
    ) %>%
    count(mutation_type_formatted) %>%
    mutate(fraction = n / sum(n)) %>%
    arrange(desc(n))
  
  # Gráfica de evolución (CORRECTED)
  p1 <- ggplot(evolution, aes(x = step, y = snvs)) +
    geom_col(aes(fill = step), alpha = 0.85, width = 0.5) +
    geom_text(aes(label = paste0(format(snvs, big.mark=","), "\n", 
                                  format(mirnas, big.mark=","), " miRNAs")), 
              vjust = -0.3, size = 3.5, fontface = "bold") +
    scale_fill_viridis_d(begin = 0.3, end = 0.7, guide = "none") +
    scale_y_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.15))) +
    labs(title = "Dataset Evolution", x = NULL, y = "SNVs") +
    theme_minimal(base_size = 11) +
    theme(plot.title = element_text(face = "bold", hjust = 0.5),
          axis.text.x = element_text(size = 10, face = "bold"),
          panel.grid.major.x = element_blank())
  
  # Gráfica de tipos de mutación (STACKED BARS LIKE PAPER)
  p2 <- ggplot(mutation_types, aes(x = "", y = fraction, fill = mutation_type_formatted)) +
    geom_bar(stat = "identity", width = 1, color = "white", size = 0.5) +
    coord_polar("y", start = 0) +
    geom_text(aes(label = paste0(mutation_type_formatted, "\n", 
                                 scales::percent(fraction, accuracy = 1))), 
              position = position_stack(vjust = 0.5), 
              size = 3, color = "white", fontface = "bold") +
    scale_fill_brewer(palette = "Set3", name = "Mutation Type") +
    labs(title = "Overall Mutation Types", x = NULL, y = NULL) +
    theme_void(base_size = 11) +
    theme(plot.title = element_text(face = "bold", hjust = 0.5, size = 12),
          legend.position = "bottom",
          legend.title = element_text(size = 10),
          legend.text = element_text(size = 9))
  
  # Combinar paneles
  p1 + p2 + plot_layout(widths = c(1, 1)) + 
    plot_annotation(title = "A. Dataset Overview & Mutation Types",
                    theme = theme(plot.title = element_text(size = 14, face = "bold", hjust = 0.5)))
}

### **Panel B: G>T Positional Analysis (CORRECTED)**
create_gt_positional_analysis <- function(data) {
  
  # Procesar datos para G>T (CORRECTED FORMAT)
  gt_data <- data$processed %>%
    filter(`pos:mut` != "PM") %>%
    separate(`pos:mut`, into = c("position", "mutation_type"), sep = ":", remove = FALSE) %>%
    filter(mutation_type == "GT") %>%  # G>T en formato original
    mutate(position = as.numeric(position)) %>%
    filter(position >= 1 & position <= 22)
  
  if(nrow(gt_data) == 0) {
    return(ggplot() + 
           annotate("text", x = 0.5, y = 0.5, 
                    label = "No G>T mutations found", size = 5, color = "red") +
           labs(title = "B. G>T Positional Analysis") +
           theme_void())
  }
  
  # Heatmap de posiciones G>T
  position_counts <- gt_data %>%
    count(position) %>%
    complete(position = 1:22, fill = list(n = 0)) %>%
    mutate(frequency = n / sum(n))
  
  p1 <- ggplot(position_counts, aes(x = factor(position), y = 1, fill = frequency)) +
    geom_tile(color = "white", size = 0.5) +
    scale_fill_viridis_c(option = "C", name = "G>T Freq.", 
                        labels = scales::percent_format(accuracy = 1)) +
    labs(title = "G>T Positional Frequency", x = "Position", y = NULL) +
    theme_minimal(base_size = 11) +
    theme(axis.text.y = element_blank(),
          axis.ticks.y = element_blank(),
          plot.title = element_text(face = "bold", hjust = 0.5),
          panel.grid = element_blank(),
          axis.text.x = element_text(size = 9))
  
  # Seed vs Non-seed
  seed_data <- gt_data %>%
    mutate(region = ifelse(position >= 2 & position <= 8, "Seed", "Non-Seed")) %>%
    count(region) %>%
    mutate(fraction = n / sum(n))
  
  p2 <- ggplot(seed_data, aes(x = region, y = fraction, fill = region)) +
    geom_col(alpha = 0.8, width = 0.6) +
    geom_text(aes(label = scales::percent(fraction, accuracy = 1)), 
              vjust = -0.3, size = 4, fontface = "bold") +
    scale_fill_brewer(palette = "Set2", guide = "none") +
    scale_y_continuous(labels = scales::percent, expand = expansion(mult = c(0, 0.15))) +
    labs(title = "G>T in Seed vs Non-Seed", x = "Region", y = "Fraction") +
    theme_minimal(base_size = 11) +
    theme(plot.title = element_text(face = "bold", hjust = 0.5),
          axis.text.x = element_text(size = 10, face = "bold"))
  
  # Combinar
  p1 / p2 + plot_annotation(title = "B. G>T Positional Analysis",
                            theme = theme(plot.title = element_text(size = 14, face = "bold", hjust = 0.5)))
}

### **Panel C: Mutation Spectrum (CORRECTED)**
create_mutation_spectrum <- function(data) {
  
  # Procesar todas las mutaciones G>X (CORRECTED FORMAT)
  g_mutations <- data$processed %>%
    filter(`pos:mut` != "PM") %>%
    separate(`pos:mut`, into = c("position", "mutation_type"), sep = ":", remove = FALSE) %>%
    filter(str_detect(mutation_type, "^G")) %>%  # G>T, G>A, G>C
    mutate(
      position = as.numeric(position),
      mutation_type_formatted = case_when(
        mutation_type == "GT" ~ "G>T",
        mutation_type == "GA" ~ "G>A", 
        mutation_type == "GC" ~ "G>C",
        TRUE ~ mutation_type
      )
    ) %>%
    filter(position >= 1 & position <= 22)
  
  if(nrow(g_mutations) == 0) {
    return(ggplot() + 
           annotate("text", x = 0.5, y = 0.5, 
                    label = "No G>X mutations found", size = 5, color = "red") +
           labs(title = "C. Mutation Spectrum") +
           theme_void())
  }
  
  # Stacked bars por posición
  position_spectrum <- g_mutations %>%
    count(position, mutation_type_formatted) %>%
    group_by(position) %>%
    mutate(proportion = n / sum(n)) %>%
    ungroup()
  
  p1 <- ggplot(position_spectrum, aes(x = factor(position), y = proportion, fill = mutation_type_formatted)) +
    geom_col(position = "stack", color = "white", size = 0.3) +
    scale_fill_brewer(palette = "Set1", name = "G>X Type") +
    labs(title = "G>X Mutation Types by Position", x = "Position", y = "Proportion") +
    theme_minimal(base_size = 11) +
    theme(plot.title = element_text(face = "bold", hjust = 0.5),
          axis.text.x = element_text(angle = 45, hjust = 1, size = 9),
          legend.title = element_text(size = 10),
          legend.text = element_text(size = 9))
  
  # Top 10 mutaciones generales
  top_mutations <- data$processed %>%
    filter(`pos:mut` != "PM") %>%
    separate(`pos:mut`, into = c("position", "mutation_type"), sep = ":", remove = FALSE) %>%
    filter(!is.na(mutation_type), mutation_type != "") %>%
    mutate(
      mutation_type_formatted = case_when(
        mutation_type == "GT" ~ "G>T",
        mutation_type == "TC" ~ "T>C", 
        mutation_type == "AG" ~ "A>G",
        mutation_type == "GA" ~ "G>A",
        mutation_type == "CT" ~ "C>T",
        mutation_type == "TA" ~ "T>A",
        mutation_type == "TG" ~ "T>G",
        mutation_type == "AT" ~ "A>T",
        mutation_type == "CA" ~ "C>A",
        mutation_type == "CG" ~ "C>G",
        mutation_type == "GC" ~ "G>C",
        mutation_type == "AC" ~ "A>C",
        TRUE ~ mutation_type
      )
    ) %>%
    count(mutation_type_formatted) %>%
    arrange(desc(n)) %>%
    head(10)
  
  p2 <- ggplot(top_mutations, aes(x = reorder(mutation_type_formatted, n), y = n, fill = mutation_type_formatted)) +
    geom_col(alpha = 0.8) +
    geom_text(aes(label = scales::comma(n)), hjust = -0.2, size = 3.5, fontface = "bold") +
    scale_fill_brewer(palette = "Set3", guide = "none") +
    coord_flip() +
    labs(title = "Top 10 Overall Mutation Types", x = NULL, y = "Count") +
    theme_minimal(base_size = 11) +
    theme(plot.title = element_text(face = "bold", hjust = 0.5),
          axis.text.y = element_text(size = 9))
  
  # Combinar
  p1 + p2 + plot_annotation(title = "C. Mutation Spectrum",
                            theme = theme(plot.title = element_text(size = 14, face = "bold", hjust = 0.5)))
}

### **Panel D: Placeholder (FOCUS ON INITIAL ANALYSIS)**
create_placeholder_panel <- function() {
  ggplot() +
    annotate("text", x = 0.5, y = 0.5, 
             label = "Analysis Pending:\nFocus on Initial Characterization", 
             size = 6, color = "darkgrey", fontface = "bold") +
    labs(title = "D. Advanced Analysis (Pending)") +
    theme_void() +
    theme(plot.title = element_text(size = 14, face = "bold", hjust = 0.5))
}

### **FUNCIÓN PRINCIPAL: create_figure_1_corrected**
create_figure_1_corrected <- function(data, output_dir) {
  
  cat("🎨 Generating Figure 1 (corrected mutation format)...\n")
  
  # Crear directorio si no existe
  if(!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
  
  # Generar paneles
  panel_a <- create_dataset_overview_corrected(data)
  panel_b <- create_gt_positional_analysis(data)
  panel_c <- create_mutation_spectrum(data)
  panel_d <- create_placeholder_panel()
  
  # Combinar figura completa
  figure_1 <- (panel_a | panel_b) / (panel_c | panel_d) +
    plot_annotation(
      title = "FIGURE 1: Dataset Characterization & G>T Oxidative Stress Landscape",
      theme = theme(plot.title = element_text(size = 18, face = "bold", hjust = 0.5))
    )
  
  # Guardar
  ggsave(file.path(output_dir, "figure_1_corrected.png"), 
         plot = figure_1, width = 20, height = 16, dpi = 300)
  
  # Guardar paneles individuales
  ggsave(file.path(output_dir, "panel_a_overview.png"), plot = panel_a, width = 10, height = 8, dpi = 300)
  ggsave(file.path(output_dir, "panel_b_gt_analysis.png"), plot = panel_b, width = 10, height = 8, dpi = 300)
  ggsave(file.path(output_dir, "panel_c_spectrum.png"), plot = panel_c, width = 10, height = 8, dpi = 300)
  ggsave(file.path(output_dir, "panel_d_placeholder.png"), plot = panel_d, width = 10, height = 8, dpi = 300)
  
  cat("✅ Figure 1 generated successfully!\n")
  cat("📁 Main figure: figure_1_corrected.png\n")
  cat("📁 Individual panels also saved\n\n")
  
  return(figure_1)
}
