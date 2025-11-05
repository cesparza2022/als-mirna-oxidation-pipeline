# 🎨 FIGURA 2 - CORREGIR PANEL A (que se ve rara)
# Hacer la correlación G-content más clara e interpretable

rm(list = ls())

library(ggplot2)
library(dplyr)
library(tidyr)
library(stringr)
library(readr)
library(purrr)
library(scales)

source("config/config_pipeline_2.R")

cat("\n🎨 FIGURA 2 - CORREGIR PANEL A (G-content correlation)\n")
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
# PANEL A: G-Content vs Oxidation - SIMPLIFIED AND CLEAR
# ═══════════════════════════════════════════════════════════════════
cat("🎨 Panel A: G-content correlation (SIMPLIFIED)...\n")

# Calculate G-content in seed region for each miRNA
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

# Aggregate by n_g_in_seed for cleaner visualization
gcontent_summary <- mirna_g_content %>%
  group_by(n_g_in_seed) %>%
  summarise(
    n_mirnas = n(),
    mean_perc_oxidados = mean(perc_oxidados, na.rm = TRUE),
    median_perc_oxidados = median(perc_oxidados, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  filter(n_mirnas >= 5) %>%  # Only groups with at least 5 miRNAs
  arrange(n_g_in_seed)

cat("📊 G-content summary:\n")
print(gcontent_summary)

# Create CLEAR and SIMPLE Panel A
panel_a <- ggplot(gcontent_summary, aes(x = n_g_in_seed, y = mean_perc_oxidados)) +
  # Points sized by number of miRNAs
  geom_point(aes(size = n_mirnas), color = COLOR_GT, alpha = 0.8, stroke = 1.5) +
  
  # Simple linear trend line (more interpretable)
  geom_smooth(method = "lm", se = TRUE, color = COLOR_GT, fill = "grey80", alpha = 0.3, linewidth = 1.5) +
  
  # Labels on points
  geom_text(aes(label = paste0("n=", n_mirnas)), 
            vjust = -1.2, size = 3.5, fontface = "bold", color = "black") +
  
  # Scales
  scale_size_continuous(name = "Number of\nmiRNAs", range = c(4, 12)) +
  scale_x_continuous(breaks = 0:max(gcontent_summary$n_g_in_seed), 
                     limits = c(-0.5, max(gcontent_summary$n_g_in_seed) + 0.5)) +
  scale_y_continuous(limits = c(0, max(gcontent_summary$mean_perc_oxidados) * 1.2)) +
  
  # Labels
  labs(
    title = "A. G-Content vs Oxidation Susceptibility",
    subtitle = "Mean % of G>T mutations vs Number of G nucleotides in seed region (positions 2-8)",
    x = "Number of G nucleotides in seed region (positions 2-8)",
    y = "Mean % of G>T mutations (%)"
  ) +
  
  professional_theme +
  theme(
    plot.title = element_text(size = 13, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5, color = "gray40")
  )

ggsave(file.path(figures_dir, "panel_a_gcontent_CLEAR.png"), 
       plot = panel_a, width = 10, height = 8, dpi = 300, bg = "white")

# Calculate correlation for subtitle
correlation <- cor(gcontent_summary$n_g_in_seed, gcontent_summary$mean_perc_oxidados)
cat("📊 Correlation coefficient:", correlation, "\n")

cat("✅ Panel A CORRECTED (clear and simple)\n\n")

# ═══════════════════════════════════════════════════════════════════
# ALTERNATIVE PANEL A: Bar chart (even clearer)
# ═══════════════════════════════════════════════════════════════════
cat("🎨 Alternative Panel A: Bar chart version...\n")

panel_a_bar <- ggplot(gcontent_summary, aes(x = factor(n_g_in_seed), y = mean_perc_oxidados)) +
  geom_col(fill = COLOR_GT, alpha = 0.8, width = 0.7) +
  geom_text(aes(label = paste0(sprintf("%.1f%%", mean_perc_oxidados), "\n(n=", n_mirnas, ")")), 
            vjust = -0.3, size = 3.5, fontface = "bold") +
  labs(
    title = "A. G-Content vs Oxidation Susceptibility (Bar Chart)",
    subtitle = "Mean % of G>T mutations vs Number of G nucleotides in seed region",
    x = "Number of G nucleotides in seed region (positions 2-8)",
    y = "Mean % of G>T mutations (%)"
  ) +
  professional_theme +
  theme(axis.text.x = element_text(size = 10, face = "bold"),
        plot.title = element_text(size = 13, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 10, hjust = 0.5, color = "gray40"))

ggsave(file.path(figures_dir, "panel_a_gcontent_BAR_CHART.png"), 
       plot = panel_a_bar, width = 10, height = 8, dpi = 300, bg = "white")

cat("✅ Alternative Panel A (bar chart) saved\n\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("  🎉 FIGURA 2 PANEL A CORRECTED\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

cat("📁 OUTPUTS:\n")
cat("   • panel_a_gcontent_CLEAR.png (scatter plot - clearer)\n")
cat("   • panel_a_gcontent_BAR_CHART.png (bar chart - simplest)\n\n")

cat("🎨 IMPROVEMENTS:\n")
cat("   ✅ Simplified scatter plot with linear trend\n")
cat("   ✅ Points sized by number of miRNAs (clearer)\n")
cat("   ✅ Labels on points showing sample sizes\n")
cat("   ✅ Alternative bar chart version (even clearer)\n")
cat("   ✅ Both versions show EXPLICIT NUMBERS\n")
cat("   ✅ Correlation coefficient calculated\n\n")

cat("📊 NOW SHOWS:\n")
cat("   • Mean % of G>T mutations per G-content group\n")
cat("   • Sample sizes (n=) for each point/bar\n")
cat("   • Clear trend (linear fit)\n")
cat("   • Numbers on bars for bar chart version\n\n")

