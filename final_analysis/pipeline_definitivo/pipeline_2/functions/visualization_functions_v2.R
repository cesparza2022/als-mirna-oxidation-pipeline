# 🎨 VISUALIZATION FUNCTIONS V2 - COMPLEX & DATA-DENSE

library(ggplot2)
library(dplyr)
library(tidyr)
library(stringr)
library(patchwork)
library(viridis)
library(RColorBrewer)

## 📊 FIGURE 1: DATASET CHARACTERIZATION & G>T LANDSCAPE

### **Panel A: Dataset Evolution + Mutation Type Distribution (COMBINED)**
create_dataset_overview_complex <- function(data) {
  
  # Parte 1: Evolución del dataset
  evolution <- data.frame(
    step = factor(c("Raw", "Processed"), levels = c("Raw", "Processed")),
    snvs = c(nrow(data$raw), nrow(data$processed)),
    mirnas = c(length(unique(data$raw$`miRNA name`)), 
               length(unique(data$processed$`miRNA name`)))
  )
  
  # Parte 2: Tipos de mutación global
  mutation_types <- data$processed %>%
    mutate(mutation_type = case_when(
      str_detect(`pos:mut`, "G>T") ~ "G>T",
      str_detect(`pos:mut`, "G>A") ~ "G>A",
      str_detect(`pos:mut`, "G>C") ~ "G>C",
      str_detect(`pos:mut`, "A>") ~ "A>X",
      str_detect(`pos:mut`, "T>") ~ "T>X",
      str_detect(`pos:mut`, "C>") ~ "C>X",
      TRUE ~ "Other"
    )) %>%
    count(mutation_type) %>%
    mutate(fraction = n / sum(n))
  
  # Gráfica de evolución
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
  
  # Gráfica de tipos de mutación
  p2 <- ggplot(mutation_types, aes(x = "", y = fraction, fill = mutation_type)) +
    geom_col(width = 1, color = "white", size = 0.5) +
    geom_text(aes(label = paste0(mutation_type, "\n", 
                                  scales::percent(fraction, accuracy = 0.1))), 
              position = position_stack(vjust = 0.5), size = 3, fontface = "bold") +
    scale_fill_brewer(palette = "Set2", guide = "none") +
    coord_polar(theta = "y") +
    labs(title = "Mutation Types") +
    theme_void(base_size = 11) +
    theme(plot.title = element_text(face = "bold", hjust = 0.5))
  
  # Combinar
  combined <- p1 | p2
  combined <- combined + plot_annotation(
    title = "A. Dataset Overview",
    theme = theme(plot.title = element_text(size = 13, face = "bold"))
  )
  
  return(combined)
}

### **Panel B: Positional G>T Heatmap + Regional Distribution (INTEGRATED)**
create_positional_landscape_complex <- function(data) {
  
  # Filtrar G>T y extraer posición
  gt_data <- data$processed %>%
    filter(str_detect(`pos:mut`, "G>T")) %>%
    mutate(position = as.numeric(str_extract(`pos:mut`, "^[0-9]+"))) %>%
    filter(!is.na(position), position >= 1, position <= 22) %>%
    mutate(region = ifelse(position >= 2 & position <= 8, "Seed (2-8)", "Non-seed (9-22)"))
  
  # Conteos por posición
  position_counts <- gt_data %>%
    group_by(position, region) %>%
    summarise(total_snvs = n(), unique_mirnas = n_distinct(`miRNA name`), .groups = "drop")
  
  # Heatmap posicional
  p1 <- ggplot(position_counts, aes(x = position, y = 1)) +
    geom_tile(aes(fill = total_snvs), color = "white", size = 0.8) +
    geom_text(aes(label = total_snvs), color = "white", size = 2.8, fontface = "bold") +
    scale_fill_viridis_c(name = "SNVs", option = "plasma") +
    scale_x_continuous(breaks = c(2, 5, 8, 11, 14, 17, 20, 22), expand = c(0,0)) +
    annotate("rect", xmin = 1.5, xmax = 8.5, ymin = 0.5, ymax = 1.5, 
             fill = NA, color = "red", size = 1.5, linetype = "dashed") +
    annotate("text", x = 5, y = 1.7, label = "SEED", color = "red", 
             size = 3.5, fontface = "bold") +
    labs(x = "Position in miRNA", y = NULL) +
    theme_minimal(base_size = 10) +
    theme(axis.text.y = element_blank(),
          axis.ticks.y = element_blank(),
          panel.grid = element_blank(),
          legend.position = "right",
          plot.margin = margin(5, 5, 5, 5))
  
  # Distribución por región
  region_summary <- gt_data %>%
    group_by(region) %>%
    summarise(snvs = n(), mirnas = n_distinct(`miRNA name`), .groups = "drop")
  
  p2 <- ggplot(region_summary, aes(x = region, y = snvs)) +
    geom_col(aes(fill = region), alpha = 0.85, width = 0.6) +
    geom_text(aes(label = paste0(format(snvs, big.mark=","), "\n", mirnas, " miRNAs")), 
              vjust = -0.2, size = 3.5, fontface = "bold") +
    scale_fill_manual(values = c("Seed (2-8)" = "#E74C3C", "Non-seed (9-22)" = "#3498DB"), 
                      guide = "none") +
    scale_y_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.15))) +
    labs(x = NULL, y = "G>T SNVs") +
    theme_minimal(base_size = 10) +
    theme(axis.text.x = element_text(size = 9, face = "bold"),
          panel.grid.major.x = element_blank())
  
  # Combinar
  combined <- p1 / p2 + plot_layout(heights = c(1, 1.5))
  combined <- combined + plot_annotation(
    title = "B. G>T Positional Landscape",
    theme = theme(plot.title = element_text(size = 13, face = "bold"))
  )
  
  return(combined)
}

### **Panel C: G→X Mutation Spectrum by Position (COMPLEX INTEGRATED)**
create_mutation_spectrum_complex <- function(data) {
  
  # Extraer todas las mutaciones con posición
  mutations <- data$processed %>%
    mutate(
      position = as.numeric(str_extract(`pos:mut`, "^[0-9]+")),
      base_from = str_extract(`pos:mut`, "[ATCG]>"),
      base_to = str_extract(`pos:mut`, ">[ATCG]"),
      mutation_type = paste0(str_remove(base_from, ">"), "→", str_remove(base_to, ">"))
    ) %>%
    filter(!is.na(position), position >= 1, position <= 22,
           !is.na(mutation_type)) %>%
    mutate(
      region = ifelse(position >= 2 & position <= 8, "Seed", "Non-seed"),
      is_gt = str_detect(mutation_type, "G→T")
    )
  
  # Fracciones por posición
  position_fractions <- mutations %>%
    group_by(position, is_gt) %>%
    summarise(count = n(), .groups = "drop") %>%
    group_by(position) %>%
    mutate(fraction = count / sum(count)) %>%
    filter(is_gt == TRUE)
  
  # Gráfica principal: Fracción de G>T por posición
  p1 <- ggplot(position_fractions, aes(x = position, y = fraction)) +
    geom_line(color = "#E74C3C", size = 1.2) +
    geom_point(aes(size = count), color = "#E74C3C", alpha = 0.7) +
    geom_hline(yintercept = 0.5, linetype = "dashed", color = "gray50", alpha = 0.7) +
    annotate("rect", xmin = 1.5, xmax = 8.5, ymin = 0, ymax = 1, 
             fill = "red", alpha = 0.05) +
    scale_size_continuous(name = "SNVs", range = c(2, 8)) +
    scale_y_continuous(labels = scales::percent, limits = c(0, 1)) +
    scale_x_continuous(breaks = seq(2, 22, 2)) +
    labs(title = "G>T Fraction by Position",
         x = "Position", y = "Fraction G>T") +
    theme_minimal(base_size = 10) +
    theme(plot.title = element_text(face = "bold", size = 11),
          legend.position = c(0.85, 0.85),
          legend.background = element_rect(fill = "white", color = "gray80"),
          panel.grid.minor = element_blank())
  
  # Distribución de todos los tipos de mutación
  all_types <- mutations %>%
    count(mutation_type) %>%
    arrange(desc(n)) %>%
    head(10)
  
  p2 <- ggplot(all_types, aes(x = reorder(mutation_type, n), y = n)) +
    geom_col(aes(fill = str_detect(mutation_type, "G→T")), alpha = 0.85) +
    geom_text(aes(label = format(n, big.mark=",")), hjust = -0.1, size = 3) +
    scale_fill_manual(values = c("TRUE" = "#E74C3C", "FALSE" = "gray60"), guide = "none") +
    scale_y_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.12))) +
    labs(title = "Top 10 Mutation Types", x = NULL, y = "Count") +
    coord_flip() +
    theme_minimal(base_size = 10) +
    theme(plot.title = element_text(face = "bold", size = 11),
          axis.text.y = element_text(size = 9))
  
  # Combinar
  combined <- p1 / p2 + plot_layout(heights = c(1.3, 1))
  combined <- combined + plot_annotation(
    title = "C. G→X Mutation Spectrum",
    theme = theme(plot.title = element_text(size = 13, face = "bold"))
  )
  
  return(combined)
}

### **Panel D: Top miRNAs + Positional Profile (INTEGRATED)**
create_mirna_profile_complex <- function(data, top_n = 12) {
  
  # Top miRNAs con mutaciones G>T
  top_mirnas <- data$processed %>%
    filter(str_detect(`pos:mut`, "G>T")) %>%
    group_by(`miRNA name`) %>%
    summarise(
      total_gt = n(),
      unique_pos = n_distinct(str_extract(`pos:mut`, "^[0-9]+")),
      .groups = "drop"
    ) %>%
    arrange(desc(total_gt)) %>%
    head(top_n)
  
  # Gráfica de top miRNAs
  p1 <- ggplot(top_mirnas, aes(x = reorder(`miRNA name`, total_gt), y = total_gt)) +
    geom_col(aes(fill = unique_pos), alpha = 0.9) +
    geom_text(aes(label = total_gt), hjust = -0.2, size = 3, fontface = "bold") +
    scale_fill_viridis_c(name = "Unique\nPositions", option = "viridis") +
    scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
    labs(title = paste0("Top ", top_n, " miRNAs"), x = NULL, y = "G>T SNVs") +
    coord_flip() +
    theme_minimal(base_size = 10) +
    theme(plot.title = element_text(face = "bold", size = 11),
          axis.text.y = element_text(size = 8, face = "italic"),
          legend.position = "right")
  
  # Perfil posicional de top miRNAs
  top_names <- top_mirnas$`miRNA name`
  
  position_profile <- data$processed %>%
    filter(`miRNA name` %in% top_names,
           str_detect(`pos:mut`, "G>T")) %>%
    mutate(position = as.numeric(str_extract(`pos:mut`, "^[0-9]+"))) %>%
    filter(!is.na(position), position >= 1, position <= 22) %>%
    count(`miRNA name`, position) %>%
    group_by(`miRNA name`) %>%
    mutate(fraction = n / sum(n)) %>%
    ungroup()
  
  # Heatmap de perfil posicional
  p2 <- ggplot(position_profile, aes(x = position, y = `miRNA name`, fill = fraction)) +
    geom_tile(color = "white", size = 0.3) +
    scale_fill_viridis_c(name = "Fraction", option = "magma") +
    scale_x_continuous(breaks = c(2, 5, 8, 11, 14, 17, 20, 22), expand = c(0,0)) +
    annotate("rect", xmin = 1.5, xmax = 8.5, ymin = 0.5, ymax = top_n + 0.5,
             fill = NA, color = "red", size = 0.8, linetype = "dashed") +
    labs(title = "Positional Profile", x = "Position", y = NULL) +
    theme_minimal(base_size = 10) +
    theme(plot.title = element_text(face = "bold", size = 11),
          axis.text.y = element_text(size = 7, face = "italic"),
          panel.grid = element_blank(),
          legend.position = "right")
  
  # Combinar
  combined <- p1 | p2
  combined <- combined + plot_annotation(
    title = "D. Top miRNAs & Positional Profile",
    theme = theme(plot.title = element_text(size = 13, face = "bold"))
  )
  
  return(combined)
}

### **MAIN FUNCTION: Create Complete Figure 1 (2x2 GRID)**
create_figure_1_v2 <- function(data, output_dir) {
  cat("📊 Generating Figure 1 panels (v2 - complex & dense)...\n")
  
  # Panel A: Dataset overview + mutation types
  panel_a <- create_dataset_overview_complex(data)
  cat("  ✅ Panel A generated (complex overview)\n")
  
  # Panel B: Positional landscape
  panel_b <- create_positional_landscape_complex(data)
  cat("  ✅ Panel B generated (positional landscape)\n")
  
  # Panel C: Mutation spectrum
  panel_c <- create_mutation_spectrum_complex(data)
  cat("  ✅ Panel C generated (mutation spectrum)\n")
  
  # Panel D: Top miRNAs + profile
  panel_d <- create_mirna_profile_complex(data)
  cat("  ✅ Panel D generated (miRNA profile)\n")
  
  # Combine all panels in 2x2 grid
  figure_1 <- (panel_a | panel_b) / (panel_c | panel_d)
  
  # Add main title
  figure_1 <- figure_1 + 
    plot_annotation(
      title = "FIGURE 1: Dataset Characterization & G>T Oxidative Stress Landscape",
      theme = theme(plot.title = element_text(size = 16, face = "bold", hjust = 0.5))
    )
  
  # Save figure
  output_file <- file.path(output_dir, "figure_1_dataset_characterization_v2.png")
  ggsave(output_file, figure_1, width = 20, height = 16, dpi = 300, bg = "white")
  cat("\n💾 Figure saved:", output_file, "\n")
  
  # Save individual panels for inspection
  ggsave(file.path(output_dir, "panel_a_overview.png"), panel_a, 
         width = 10, height = 5, dpi = 300, bg = "white")
  ggsave(file.path(output_dir, "panel_b_landscape.png"), panel_b, 
         width = 10, height = 8, dpi = 300, bg = "white")
  ggsave(file.path(output_dir, "panel_c_spectrum.png"), panel_c, 
         width = 10, height = 8, dpi = 300, bg = "white")
  ggsave(file.path(output_dir, "panel_d_profile.png"), panel_d, 
         width = 10, height = 8, dpi = 300, bg = "white")
  cat("💾 Individual panels saved for inspection\n")
  
  return(figure_1)
}

