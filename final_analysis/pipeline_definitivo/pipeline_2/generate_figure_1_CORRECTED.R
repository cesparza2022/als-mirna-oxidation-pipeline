# 🎨 FIGURA 1 CORRECTED - ROJO G>T + LABELS CLAROS
# Implementando feedback del usuario: G>T = ROJO, labels explícitos

rm(list = ls())

library(ggplot2)
library(dplyr)
library(tidyr)
library(stringr)
library(patchwork)
library(viridis)
library(scales)
library(readr)

source("config/config_pipeline_2.R")
source("functions/data_transformation.R")

cat("\n🎨 FIGURA 1 CORRECTED - ROJO G>T + LABELS CLAROS\n")
cat("═══════════════════════════════════════════════════════════\n\n")

# --- Load and Process Data ---
raw_data_path <- file.path(data_dir, "miRNA_count.Q33.txt")
raw_data <- read_tsv(raw_data_path, show_col_types = FALSE)

processed_data <- raw_data %>%
  separate_rows(`pos:mut`, sep = ",") %>%
  filter(`pos:mut` != "PM") %>%
  separate(`pos:mut`, into = c("position", "mutation_type_raw"), sep = ":", remove = FALSE) %>%
  mutate(
    position = as.numeric(position),
    mutation_type = str_replace_all(mutation_type_raw, c("TC" = "T>C", "AG" = "A>G", "GA" = "G>A", "CT" = "C>T",
                                                         "TA" = "T>A", "GT" = "G>T", "TG" = "T>G", "AT" = "A>T",
                                                         "CA" = "C>A", "CG" = "C>G", "GC" = "G>C", "AC" = "A>C"))
  ) %>%
  filter(position >= 1 & position <= 22)

cat("✅ Data processed\n\n")

# --- CORRECTED COLORS - G>T = ROJO ---
COLOR_GT_CORRECTED <- "#D62728"  # ROJO para G>T (oxidación)

# --- Professional theme ---
professional_theme <- theme_classic(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 13, hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5, color = "gray40"),
    axis.text = element_text(size = 10),
    panel.grid.major = element_line(color = "grey90", linewidth = 0.3),
    legend.position = "right",
    legend.title = element_text(face = "bold", size = 10),
    legend.text = element_text(size = 9)
  )

# --- PANEL A: Dataset Evolution & Overall Mutation Types ---
cat("🎨 Panel A: Dataset evolution + mutation types (ROJO G>T)...\n")

# Dataset evolution
evolution_data <- data.frame(
  step = factor(c("Original File", "Individual SNVs"), levels = c("Original File", "Individual SNVs")),
  snvs = c(nrow(raw_data), nrow(raw_data %>% separate_rows(`pos:mut`, sep = ","))),
  mirnas = c(length(unique(raw_data$`miRNA name`)),
             length(unique(processed_data$`miRNA name`)))
)

p_evolution <- ggplot(evolution_data, aes(x = step, y = snvs)) +
  geom_col(aes(fill = step), alpha = 0.85, width = 0.6) +
  geom_text(aes(label = paste0(format(snvs, big.mark=","), "\nSNVs\n",
                               format(mirnas, big.mark=","), " miRNAs")),
            vjust = -0.3, size = 3.5, fontface = "bold", color = "black") +
  scale_fill_manual(values = c("Original File" = "grey70", "Individual SNVs" = "grey40"), guide = "none") +
  scale_y_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.15))) +
  labs(title = "Dataset Processing Steps", 
       x = NULL, 
       y = "Number of entries") +
  professional_theme +
  theme(plot.title = element_text(face = "bold", hjust = 0.5, size = 12))

# Mutation types - CORRECTED: G>T = ROJO
mutation_types_data <- processed_data %>%
  count(mutation_type) %>%
  mutate(fraction = n / sum(n)) %>%
  arrange(desc(n)) %>%
  head(10)

p_mutation_types <- ggplot(mutation_types_data, aes(x = reorder(mutation_type, n), y = n)) +
  geom_col(aes(fill = mutation_type), alpha = 0.8, width = 0.7) +
  geom_text(aes(label = paste0(format(n, big.mark=","), "\n(", sprintf("%.1f%%", fraction*100), ")")),
            hjust = -0.1, size = 3.5, fontface = "bold") +
  scale_fill_manual(values = c("G>T" = COLOR_GT_CORRECTED,  # ROJO para G>T
                               "T>C" = "grey60", "A>G" = "grey60", "G>A" = "grey60", 
                               "C>T" = "grey60", "T>A" = "grey60", "T>G" = "grey60", 
                               "A>T" = "grey60", "C>A" = "grey60", "C>G" = "grey60", 
                               "G>C" = "grey60", "A>C" = "grey60"),
                    guide = "none") +
  scale_y_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.2))) +
  labs(title = "Mutation Types Distribution (Top 10)", 
       x = NULL, 
       y = "Count of mutations") +
  coord_flip() +
  professional_theme +
  theme(plot.title = element_text(face = "bold", hjust = 0.5, size = 12),
        axis.text.y = element_text(size = 10, face = "bold"),
        panel.grid.major.y = element_blank())

panel_a <- (p_evolution + p_mutation_types) +
  plot_annotation(title = "A. Dataset Overview & Mutation Types",
                  theme = theme(plot.title = element_text(size = 14, face = "bold", hjust = 0.5)))
ggsave(file.path(figures_dir, "panel_a_overview_CORRECTED.png"), plot = panel_a, width = 12, height = 6, dpi = 300, bg = "white")
cat("✅ Panel A CORRECTED (ROJO G>T)\n\n")

# --- PANEL B: G>T Positional Frequency ---
cat("🎨 Panel B: G>T positional (ROJO)...\n")
gt_position_data <- processed_data %>%
  filter(mutation_type == "G>T") %>%
  count(position, `miRNA name`, name = "gt_count") %>%
  group_by(position) %>%
  mutate(total_gt_at_pos = sum(gt_count)) %>%
  ungroup() %>%
  mutate(position_label = factor(position, levels = 1:22))

panel_b <- ggplot(gt_position_data, aes(x = position_label, y = `miRNA name`, fill = gt_count)) +
  geom_tile(color = "white", linewidth = 0.5) +
  scale_fill_gradient(low = "white", high = COLOR_GT_CORRECTED, name = "G>T count\n(at position)") +
  labs(title = "B. G>T Positional Distribution Across miRNAs",
       subtitle = "Heatmap: Count of G>T mutations at each position (1-22)",
       x = "Position in miRNA",
       y = "miRNA Name") +
  professional_theme +
  theme(axis.text.y = element_blank(),
        axis.ticks.y = element_blank(),
        plot.title = element_text(size = 13, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 10, hjust = 0.5, color = "gray40"))

ggsave(file.path(figures_dir, "panel_b_positional_CORRECTED.png"), plot = panel_b, width = 12, height = 8, dpi = 300, bg = "white")
cat("✅ Panel B CORRECTED (ROJO)\n\n")

# --- PANEL C: G>X Mutation Spectrum ---
cat("🎨 Panel C: G>X spectrum (ROJO G>T)...\n")
gx_spectrum_data <- processed_data %>%
  filter(str_detect(mutation_type, "^G>")) %>%
  count(position, mutation_type) %>%
  group_by(position) %>%
  mutate(percentage = n / sum(n) * 100) %>%
  ungroup() %>%
  mutate(
    position_label = factor(position, levels = 1:22),
    mutation_type = factor(mutation_type, levels = c("G>C", "G>A", "G>T"))
  )

panel_c <- ggplot(gx_spectrum_data, aes(x = position_label, y = percentage, fill = mutation_type)) +
  geom_col(position = "stack", color = "white", linewidth = 0.3) +
  scale_fill_manual(values = c("G>T" = COLOR_GT_CORRECTED,  # ROJO
                               "G>A" = "grey60", 
                               "G>C" = "grey40"), 
                    name = "Mutation Type") +
  labs(title = "C. G>X Mutation Spectrum by Position",
       subtitle = "Percentage of G>T, G>A, G>C mutations at each miRNA position",
       x = "Position in miRNA",
       y = "Percentage of G>X mutations (%)") +
  professional_theme +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        plot.title = element_text(size = 13, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 10, hjust = 0.5, color = "gray40"))

ggsave(file.path(figures_dir, "panel_c_spectrum_CORRECTED.png"), plot = panel_c, width = 12, height = 6, dpi = 300, bg = "white")
cat("✅ Panel C CORRECTED (ROJO G>T)\n\n")

# --- PANEL D: Top miRNAs with G>T ---
cat("🎨 Panel D: Top miRNAs (ROJO G>T)...\n")
top_mirnas_data <- processed_data %>%
  filter(mutation_type == "G>T") %>%
  count(`miRNA name`, name = "gt_count") %>%
  arrange(desc(gt_count)) %>%
  head(15) %>%
  mutate(
    `miRNA name` = factor(`miRNA name`, levels = rev(`miRNA name`)),
    percentage = gt_count / sum(gt_count) * 100
  )

panel_d <- ggplot(top_mirnas_data, aes(x = `miRNA name`, y = gt_count)) +
  geom_col(fill = COLOR_GT_CORRECTED, alpha = 0.8, width = 0.7) +  # ROJO
  geom_text(aes(label = paste0(gt_count, " (", sprintf("%.1f%%", percentage), ")")),
            hjust = -0.1, size = 3.5, fontface = "bold") +
  labs(title = "D. Top 15 miRNAs with G>T Mutations",
       subtitle = "Count of G>T mutations per miRNA (total dataset)",
       x = NULL,
       y = "Count of G>T mutations") +
  coord_flip() +
  professional_theme +
  theme(plot.title = element_text(size = 13, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 10, hjust = 0.5, color = "gray40"),
        panel.grid.major.y = element_blank())

ggsave(file.path(figures_dir, "panel_d_top_mirnas_CORRECTED.png"), plot = panel_d, width = 12, height = 7, dpi = 300, bg = "white")
cat("✅ Panel D CORRECTED (ROJO G>T)\n\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("  🎉 FIGURA 1 CORRECTED - COMPLETE\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

cat("📁 OUTPUTS CORRECTED:\n")
cat("   • panel_a_overview_CORRECTED.png (ROJO G>T)\n")
cat("   • panel_b_positional_CORRECTED.png (ROJO gradient)\n")
cat("   • panel_c_spectrum_CORRECTED.png (ROJO G>T)\n")
cat("   • panel_d_top_mirnas_CORRECTED.png (ROJO bars)\n\n")

cat("🎨 CORRECTIONS APPLIED:\n")
cat("   ✅ G>T = ROJO (#D62728) en todos los paneles\n")
cat("   ✅ Labels explícitos: 'Count of mutations', 'Number of entries'\n")
cat("   ✅ Subtítulos explicativos en cada panel\n")
cat("   ✅ Professional theme consistente\n\n")
