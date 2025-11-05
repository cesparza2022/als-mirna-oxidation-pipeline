# 🎨 FIGURA 2 CORRECTED - ROJO G>T + LABELS CLAROS + PANEL D MEJORADO
# Implementando feedback del usuario: G>T = ROJO, labels explícitos, Panel D = positional fraction

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
source("functions/mechanistic_functions.R")

cat("\n🎨 FIGURA 2 CORRECTED - ROJO G>T + LABELS CLAROS\n")
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

# --- PANEL A: G-Content vs Oxidation Susceptibility ---
cat("🎨 Panel A: G-content correlation (CLARIFIED LABELS)...\n")

# Calculate gcontent_data
mirna_g_content <- processed_data %>%
  filter(str_detect(mutation_type, "^G>")) %>% # Only G mutations
  group_by(`miRNA name`) %>%
  summarise(
    n_g_in_seed = sum(position >= 2 & position <= 8 & str_detect(mutation_type, "^G>")),
    total_gt_mutations = sum(mutation_type == "G>T"),
    total_g_mutations = n(),
    .groups = 'drop'
  ) %>%
  mutate(
    perc_oxidados = (total_gt_mutations / total_g_mutations) * 100
  )

gcontent_data <- mirna_g_content %>%
  group_by(n_g_in_seed) %>%
  summarise(
    n_mirnas = n(),
    perc_oxidados = mean(perc_oxidados, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  arrange(n_g_in_seed)

# Create Panel A with clarified labels
panel_a <- ggplot(gcontent_data, aes(x = n_g_in_seed, y = perc_oxidados)) +
  geom_point(aes(size = n_mirnas), alpha = 0.7, color = COLOR_GT_CORRECTED) +
  geom_smooth(method = "loess", se = TRUE, color = COLOR_GT_CORRECTED, fill = "grey80", alpha = 0.3) +
  scale_size_continuous(name = "Number of\nmiRNAs", range = c(2, 8)) +
  scale_x_continuous(breaks = 0:7) +
  labs(
    title = "A. G-Content Determines Oxidation Susceptibility",
    subtitle = "Hypothesis: More G nucleotides in seed region (positions 2-8) → Higher G>T mutation rate",
    x = "Number of G nucleotides in seed region (positions 2-8)",
    y = "Percentage of miRNAs with ≥1 G>T mutation (%)"
  ) +
  professional_theme

ggsave(file.path(figures_dir, "panel_a_gcontent_CORRECTED.png"), plot = panel_a, width = 10, height = 8, dpi = 300, bg = "white")
cat("✅ Panel A CORRECTED (clarified G's in seed region)\n\n")

# --- PANEL B: Sequence Context (Placeholder) ---
cat("🎨 Panel B: Sequence context (placeholder)...\n")
panel_b <- ggplot() +
  annotate("text", x = 0.5, y = 0.5, 
           label = "Sequence Context Analysis\n(Requires miRNA reference sequences)",
           size = 6, fontface = "bold", color = "gray50") +
  theme_void() +
  labs(title = "B. Sequence Context Around G>T Sites",
       subtitle = "Placeholder: Requires miRNA reference sequences for detailed analysis")

ggsave(file.path(figures_dir, "panel_b_context_CORRECTED.png"), plot = panel_b, width = 10, height = 8, dpi = 300, bg = "white")
cat("✅ Panel B (placeholder)\n\n")

# --- PANEL C: G>T Specificity ---
cat("🎨 Panel C: G>T specificity (ROJO)...\n")
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
  labs(
    title = "C. G>T Specificity: Proportion of G>X Mutations",
    subtitle = "What percentage of G>X mutations are specifically G>T at each position?",
    x = "Position in miRNA",
    y = "Proportion of G>X mutations (%)"
  ) +
  professional_theme +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        plot.title = element_text(size = 13, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 10, hjust = 0.5, color = "gray40"))

ggsave(file.path(figures_dir, "panel_c_specificity_CORRECTED.png"), plot = panel_c, width = 10, height = 8, dpi = 300, bg = "white")
cat("✅ Panel C CORRECTED (ROJO G>T)\n\n")

# --- PANEL D: Positional Fraction (IMPROVED - NO LONGER DUPLICATE) ---
cat("🎨 Panel D: Positional fraction (IMPROVED)...\n")

# Calculate positional fraction: (G>T at position X) / (Total G>T) * 100
positional_fraction_data <- processed_data %>%
  filter(mutation_type == "G>T") %>%
  count(position, name = "gt_count") %>%
  mutate(
    total_gt = sum(gt_count),
    positional_fraction = gt_count / total_gt * 100,
    position_label = factor(position, levels = 1:22),
    region = ifelse(position >= 2 & position <= 8, "Seed", "Non-Seed")
  )

panel_d <- ggplot(positional_fraction_data, aes(x = position_label, y = positional_fraction)) +
  geom_col(aes(fill = region), alpha = 0.8, width = 0.7) +
  scale_fill_manual(values = c("Seed" = "#FFD700", "Non-Seed" = "grey60"), name = "Region") +
  geom_text(aes(label = sprintf("%.1f%%", positional_fraction)), 
            vjust = -0.3, size = 3.5, fontface = "bold") +
  labs(
    title = "D. Positional Fraction of G>T Mutations",
    subtitle = "What percentage of ALL G>T mutations occur at each position?",
    x = "Position in miRNA",
    y = "Percentage of total G>T mutations (%)"
  ) +
  professional_theme +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        plot.title = element_text(size = 13, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 10, hjust = 0.5, color = "gray40"))

ggsave(file.path(figures_dir, "panel_d_positional_fraction_CORRECTED.png"), plot = panel_d, width = 10, height = 8, dpi = 300, bg = "white")
cat("✅ Panel D IMPROVED (positional fraction - no longer duplicate)\n\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("  🎉 FIGURA 2 CORRECTED - COMPLETE\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

cat("📁 OUTPUTS CORRECTED:\n")
cat("   • panel_a_gcontent_CORRECTED.png (clarified G's in seed)\n")
cat("   • panel_b_context_CORRECTED.png (placeholder)\n")
cat("   • panel_c_specificity_CORRECTED.png (ROJO G>T)\n")
cat("   • panel_d_positional_fraction_CORRECTED.png (IMPROVED - no duplicate)\n\n")

cat("🎨 CORRECTIONS APPLIED:\n")
cat("   ✅ G>T = ROJO (#D62728) en todos los paneles\n")
cat("   ✅ Panel A: Clarified 'Number of G nucleotides in seed region (2-8)'\n")
cat("   ✅ Panel D: Changed to positional fraction (more informative)\n")
cat("   ✅ Labels explícitos y subtítulos explicativos\n")
cat("   ✅ Professional theme consistente\n\n")

