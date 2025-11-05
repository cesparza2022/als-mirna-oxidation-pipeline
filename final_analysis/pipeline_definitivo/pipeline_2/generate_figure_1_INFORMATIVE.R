# 🎨 FIGURA 1 INFORMATIVE - ENFOCADA EN CUENTAS Y CANTIDADES
# Rediseño para mostrar claramente: cuentas de SNVs, cuentas por miRNA, cantidades absolutas

rm(list = ls())

library(ggplot2)
library(dplyr)
library(tidyr)
library(stringr)
library(patchwork)
library(readr)
library(purrr)
library(scales)

source("config/config_pipeline_2.R")

cat("\n🎨 FIGURA 1 INFORMATIVE - CUENTAS Y CANTIDADES\n")
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

# --- COLORS ---
COLOR_GT <- "#D62728"  # ROJO para G>T

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

# ═══════════════════════════════════════════════════════════════════
# PANEL A: Dataset Evolution & Mutation Type COUNTS
# ═══════════════════════════════════════════════════════════════════
cat("🎨 Panel A: Dataset evolution + mutation COUNTS...\n")

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

# Mutation types - COUNTS
mutation_types_data <- processed_data %>%
  count(mutation_type) %>%
  mutate(fraction = n / sum(n)) %>%
  arrange(desc(n)) %>%
  head(10)

p_mutation_types <- ggplot(mutation_types_data, aes(x = reorder(mutation_type, n), y = n)) +
  geom_col(aes(fill = mutation_type), alpha = 0.8, width = 0.7) +
  geom_text(aes(label = paste0(format(n, big.mark=","), "\n(", sprintf("%.1f%%", fraction*100), ")")),
            hjust = -0.1, size = 3.5, fontface = "bold") +
  scale_fill_manual(values = c("G>T" = COLOR_GT,  # ROJO para G>T
                               "T>C" = "grey60", "A>G" = "grey60", "G>A" = "grey60", 
                               "C>T" = "grey60", "T>A" = "grey60", "T>G" = "grey60", 
                               "A>T" = "grey60", "C>A" = "grey60", "C>G" = "grey60", 
                               "G>C" = "grey60", "A>C" = "grey60"),
                    guide = "none") +
  scale_y_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.2))) +
  labs(title = "Mutation Types - COUNTS", 
       x = NULL, 
       y = "Count of SNVs") +
  coord_flip() +
  professional_theme +
  theme(plot.title = element_text(face = "bold", hjust = 0.5, size = 12),
        axis.text.y = element_text(size = 10, face = "bold"),
        panel.grid.major.y = element_blank())

panel_a <- (p_evolution + p_mutation_types) +
  plot_annotation(title = "A. Dataset Overview & SNV Counts by Mutation Type",
                  theme = theme(plot.title = element_text(size = 14, face = "bold", hjust = 0.5)))
ggsave(file.path(figures_dir, "panel_a_overview_INFORMATIVE.png"), plot = panel_a, width = 12, height = 6, dpi = 300, bg = "white")
cat("✅ Panel A INFORMATIVE (SNV COUNTS)\n\n")

# ═══════════════════════════════════════════════════════════════════
# PANEL B: G>T COUNT by Position (NO HEATMAP - BAR CHART)
# ═══════════════════════════════════════════════════════════════════
cat("🎨 Panel B: G>T COUNT by position (bar chart)...\n")

gt_by_position <- processed_data %>%
  filter(mutation_type == "G>T") %>%
  count(position, name = "gt_count") %>%
  mutate(
    position_label = factor(position, levels = 1:22),
    region = ifelse(position >= 2 & position <= 8, "Seed", "Non-Seed")
  )

panel_b <- ggplot(gt_by_position, aes(x = position_label, y = gt_count)) +
  geom_col(aes(fill = region), alpha = 0.8, width = 0.7) +
  geom_text(aes(label = gt_count), vjust = -0.3, size = 3.5, fontface = "bold") +
  scale_fill_manual(values = c("Seed" = "#FFD700", "Non-Seed" = "grey60"), name = "Region") +
  labs(
    title = "B. G>T Mutation COUNT by Position",
    subtitle = "Absolute number of G>T mutations at each miRNA position (1-22)",
    x = "Position in miRNA",
    y = "Count of G>T mutations"
  ) +
  professional_theme +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        plot.title = element_text(size = 13, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 10, hjust = 0.5, color = "gray40"))

ggsave(file.path(figures_dir, "panel_b_gt_count_by_position_INFORMATIVE.png"), 
       plot = panel_b, width = 12, height = 6, dpi = 300, bg = "white")
cat("✅ Panel B INFORMATIVE (COUNT by position)\n\n")

# ═══════════════════════════════════════════════════════════════════
# PANEL C: Total SNV Count by Position (ALL mutation types)
# ═══════════════════════════════════════════════════════════════════
cat("🎨 Panel C: Total SNV COUNT by position...\n")

all_by_position <- processed_data %>%
  count(position, name = "total_snv_count") %>%
  mutate(
    position_label = factor(position, levels = 1:22),
    region = ifelse(position >= 2 & position <= 8, "Seed", "Non-Seed")
  )

panel_c <- ggplot(all_by_position, aes(x = position_label, y = total_snv_count)) +
  geom_col(aes(fill = region), alpha = 0.8, width = 0.7) +
  geom_text(aes(label = format(total_snv_count, big.mark=",")), 
            vjust = -0.3, size = 3.5, fontface = "bold") +
  scale_fill_manual(values = c("Seed" = "#FFD700", "Non-Seed" = "grey60"), name = "Region") +
  labs(
    title = "C. Total SNV COUNT by Position",
    subtitle = "Absolute number of ALL SNVs at each miRNA position (1-22)",
    x = "Position in miRNA",
    y = "Count of ALL SNVs"
  ) +
  professional_theme +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        plot.title = element_text(size = 13, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 10, hjust = 0.5, color = "gray40"))

ggsave(file.path(figures_dir, "panel_c_total_snv_by_position_INFORMATIVE.png"), 
       plot = panel_c, width = 12, height = 6, dpi = 300, bg = "white")
cat("✅ Panel C INFORMATIVE (TOTAL SNV COUNT)\n\n")

# ═══════════════════════════════════════════════════════════════════
# PANEL D: SNV Count per miRNA (Top 20)
# ═══════════════════════════════════════════════════════════════════
cat("🎨 Panel D: SNV COUNT per miRNA...\n")

snv_per_mirna <- processed_data %>%
  count(`miRNA name`, name = "total_snv_count") %>%
  arrange(desc(total_snv_count)) %>%
  head(20) %>%
  mutate(
    `miRNA name` = factor(`miRNA name`, levels = rev(`miRNA name`)),
    percentage = total_snv_count / sum(total_snv_count) * 100
  )

panel_d <- ggplot(snv_per_mirna, aes(x = `miRNA name`, y = total_snv_count)) +
  geom_col(fill = "steelblue", alpha = 0.8, width = 0.7) +
  geom_text(aes(label = paste0(format(total_snv_count, big.mark=","), 
                               " (", sprintf("%.1f%%", percentage), ")")),
            hjust = -0.1, size = 3.5, fontface = "bold") +
  labs(
    title = "D. Total SNV COUNT per miRNA (Top 20)",
    subtitle = "miRNAs with highest total SNV counts (all mutation types)",
    x = NULL,
    y = "Count of ALL SNVs"
  ) +
  coord_flip() +
  professional_theme +
  theme(plot.title = element_text(size = 13, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 10, hjust = 0.5, color = "gray40"),
        panel.grid.major.y = element_blank())

ggsave(file.path(figures_dir, "panel_d_snv_per_mirna_INFORMATIVE.png"), 
       plot = panel_d, width = 12, height = 8, dpi = 300, bg = "white")
cat("✅ Panel D INFORMATIVE (SNV COUNT per miRNA)\n\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("  🎉 FIGURA 1 INFORMATIVE - COMPLETE\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

cat("📁 OUTPUTS INFORMATIVE:\n")
cat("   • panel_a_overview_INFORMATIVE.png (SNV COUNTS)\n")
cat("   • panel_b_gt_count_by_position_INFORMATIVE.png (G>T COUNT by position)\n")
cat("   • panel_c_total_snv_by_position_INFORMATIVE.png (TOTAL SNV COUNT)\n")
cat("   • panel_d_snv_per_mirna_INFORMATIVE.png (SNV COUNT per miRNA)\n\n")

cat("🎨 IMPROVEMENTS:\n")
cat("   ✅ Panel B: Bar chart instead of unreadable heatmap\n")
cat("   ✅ Panel C: NEW - Total SNV count by position\n")
cat("   ✅ Panel D: Total SNV count per miRNA (not just G>T)\n")
cat("   ✅ All panels show EXPLICIT COUNTS\n")
cat("   ✅ Clear labels: 'Count of SNVs', 'Count of G>T mutations'\n")
cat("   ✅ Numbers displayed on bars for clarity\n\n")

cat("📊 NOW SHOWS:\n")
cat("   • Total SNV counts (not just fractions)\n")
cat("   • G>T counts by position (clear numbers)\n")
cat("   • SNV counts per miRNA (all mutation types)\n")
cat("   • Seed vs Non-Seed regions highlighted\n\n")

