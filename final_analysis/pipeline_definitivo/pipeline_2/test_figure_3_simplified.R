# 🧪 SIMPLIFIED TEST FOR FIGURE 3 - PANEL BY PANEL

rm(list = ls())

library(tidyverse)
library(patchwork)
library(scales)

source("config/config_pipeline_2.R")
source("functions/statistical_tests.R")
source("functions/comparison_functions.R")

# Colors
COLOR_ALS <- "#E31A1C"
COLOR_CONTROL <- "#1F78B4"
COLOR_SEED_SHADE <- "#FFD70020"
COLOR_GT <- "#FF7F00"
COLOR_SEED <- "#FFD700"
COLOR_NONSEED <- "#B0B0B0"

cat("🎨 Generating Figure 3 Panels Individually...\n\n")

## Load data
data_path <- "/Users/cesaresparza/New_Desktop/UCSD/8OG/results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt"
raw_data <- read_tsv(data_path, show_col_types = FALSE)

processed_data <- raw_data %>%
  separate_rows(`pos:mut`, sep = ",") %>%
  filter(`pos:mut` != "PM")

# Extract groups
sample_cols <- names(raw_data)[!names(raw_data) %in% c("miRNA name", "pos:mut")]
groups <- tibble(sample_id = sample_cols) %>%
  mutate(group = case_when(
    str_detect(sample_id, "ALS") ~ "ALS",
    str_detect(sample_id, "control") ~ "Control",
    TRUE ~ NA_character_
  )) %>%
  filter(!is.na(group))

cat("📊 Groups: ALS=", sum(groups$group=="ALS"), ", Control=", sum(groups$group=="Control"), "\n\n")

## PANEL B: Position Delta (THE FAVORITE)
cat("🎨 Creating Panel B (Position Delta - FAVORITE)...\n")

position_stats <- compare_positions_by_group(processed_data, groups)

# Create position delta plot data
plot_data_b <- position_stats %>%
  pivot_longer(cols = c(freq_ALS, freq_Control), 
               names_to = "group", values_to = "frequency") %>%
  mutate(
    group = str_replace(group, "freq_", ""),
    group = factor(group, levels = c("ALS", "Control"))
  )

panel_b <- ggplot(plot_data_b, aes(x = factor(position), y = frequency, fill = group)) +
  annotate("rect", xmin = 1.5, xmax = 8.5, ymin = 0, ymax = Inf,
           fill = COLOR_SEED_SHADE, alpha = 0.3) +
  annotate("text", x = 5, y = Inf, label = "SEED", 
           vjust = 2, size = 3.5, fontface = "bold", color = "#DAA520") +
  geom_col(position = "dodge", color = "black", linewidth = 0.3, alpha = 0.85) +
  scale_fill_manual(
    values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL),
    name = "Group"
  ) +
  scale_y_continuous(
    breaks = seq(0, 20, by = 2),
    labels = function(x) paste0(x, "%"),
    expand = expansion(mult = c(0, 0.15)),
    limits = c(0, NA)
  ) +
  scale_x_discrete() +  # Explicitly use discrete scale for factor positions
  labs(
    title = "Position-Specific G>T Differences (ALS vs Control)",
    subtitle = "Seed region (2-8) shaded | ⚠️ Using simulated data for demonstration",
    x = "Position in miRNA",
    y = "G>T Frequency (%)"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold", size = 12, hjust = 0.5),
    plot.subtitle = element_text(size = 9, hjust = 0.5, color = "gray40"),
    legend.position = "right"
  )

# Save Panel B
ggsave(file.path(figures_dir, "panel_b_position_delta.png"), 
       plot = panel_b, width = 12, height = 8, dpi = 300, bg = "white")

cat("✅ Panel B saved (panel_b_position_delta.png)\n")
cat("   🔴 RED for ALS\n")
cat("   🔵 BLUE for Control\n")
cat("   🟡 GOLD shading for seed\n\n")

cat("🎉 Panel B (Position Delta Curve) created successfully!\n")
cat("📁 Location: figures/panel_b_position_delta.png\n\n")

cat("⚠️  NOTE: Using simulated group differences\n")
cat("💡 Real implementation requires sample-level analysis\n")
cat("📊 This demonstrates the visualization style for when real metadata is available\n")
