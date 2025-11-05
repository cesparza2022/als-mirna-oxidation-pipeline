#!/usr/bin/env Rscript
# ============================================================================
# PANEL E: G-Content Analysis - MULTIPLE VISUALIZATION OPTIONS
# ============================================================================
# 
# PURPOSE: Generate 4 DIFFERENT visualizations of the same 3 metrics
#          to compare which communicates best
#
# METRICS:
#   1. Total G counts (sum of all reads from miRNAs with G at position)
#   2. Total G>T counts (sum of all G>T mutation reads)
#   3. Number of unique miRNAs with G at position
#
# OPTIONS TO COMPARE:
#   A. Dual-axis bar chart (bars + line)
#   B. Bubble plot (bars + bubbles)
#   C. Stacked/grouped bars
#   D. Heatmap-style with multiple panels
#
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
  library(readr)
  library(stringr)
  library(scales)
  library(patchwork)
})

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  PANEL E: G-Content - COMPARING 4 VISUALIZATION OPTIONS\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# ============================================================================
# LOAD AND PREPARE DATA
# ============================================================================

cat("📂 Loading data...\n")

data <- read_csv("../../pipeline_2/final_processed_data_CLEAN.csv", show_col_types = FALSE)

# Get sample columns (all except miRNA_name and pos.mut)
sample_cols <- setdiff(names(data), c("miRNA_name", "pos.mut"))

cat("   ✅ Data loaded:", nrow(data), "rows\n")
cat("   ✅ Sample columns:", length(sample_cols), "\n\n")

# ============================================================================
# CALCULATE THE 3 METRICS
# ============================================================================

cat("🔢 Calculating 3 metrics for each position...\n\n")

# METRIC 1: Total G counts (sum of all reads from miRNAs with G at position)
cat("   📊 Metric 1: Total G counts...\n")
g_counts <- data %>%
  filter(str_detect(pos.mut, "^\\d+:G[TCAG]")) %>%  # miRNAs with G mutations
  mutate(Position = as.numeric(str_extract(pos.mut, "^\\d+"))) %>%
  group_by(Position) %>%
  summarise(
    total_G_counts = sum(across(all_of(sample_cols)), na.rm = TRUE),
    .groups = 'drop'
  )

# METRIC 2: Total G>T counts
cat("   🔴 Metric 2: Total G>T counts...\n")
gt_counts <- data %>%
  filter(str_detect(pos.mut, "^\\d+:GT$")) %>%  # Only G>T
  mutate(Position = as.numeric(str_extract(pos.mut, "^\\d+"))) %>%
  group_by(Position) %>%
  summarise(
    total_GT_counts = sum(across(all_of(sample_cols)), na.rm = TRUE),
    .groups = 'drop'
  )

# METRIC 3: Number of unique miRNAs with G
cat("   🧬 Metric 3: Unique miRNAs with G...\n")
unique_mirnas <- data %>%
  filter(str_detect(pos.mut, "^\\d+:G[TCAG]")) %>%
  mutate(Position = as.numeric(str_extract(pos.mut, "^\\d+"))) %>%
  group_by(Position) %>%
  summarise(
    n_unique_miRNAs = n_distinct(miRNA_name),
    .groups = 'drop'
  )

# Combine all metrics
panel_e_data <- g_counts %>%
  left_join(gt_counts, by = "Position") %>%
  left_join(unique_mirnas, by = "Position") %>%
  replace_na(list(total_GT_counts = 0)) %>%
  mutate(
    is_seed = Position >= 2 & Position <= 8,
    GT_fraction = total_GT_counts / total_G_counts * 100  # % of G counts that are G>T
  )

cat("\n📊 Combined metrics:\n")
print(panel_e_data, n = Inf)
cat("\n")

# Colors
COLOR_G <- "#2E7D32"     # Green for G-content
COLOR_GT <- "#D62728"    # Red for G>T
COLOR_SEED <- "#FFF9C4"  # Light yellow for seed

# Professional theme
theme_prof <- theme_classic(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5, color = "gray40"),
    axis.title = element_text(face = "bold", size = 12),
    axis.text = element_text(size = 10),
    legend.position = "right",
    panel.grid.major.y = element_line(color = "grey90", linewidth = 0.3)
  )

# ============================================================================
# OPTION A: DUAL-AXIS BAR + LINE
# ============================================================================

cat("🎨 OPTION A: Dual-axis (bars + line)...\n")

# Scale factor for second axis
scale_factor <- max(panel_e_data$total_G_counts) / max(panel_e_data$total_GT_counts)

option_a <- ggplot(panel_e_data, aes(x = Position)) +
  # Seed region
  annotate("rect", xmin = 1.5, xmax = 8.5, ymin = 0, ymax = Inf,
           fill = COLOR_SEED, alpha = 0.3) +
  
  # BARS: G counts (primary axis)
  geom_col(aes(y = total_G_counts), fill = COLOR_G, alpha = 0.7, width = 0.7) +
  
  # LINE: G>T counts (secondary axis, scaled)
  geom_line(aes(y = total_GT_counts * scale_factor), 
            color = COLOR_GT, linewidth = 1.5) +
  geom_point(aes(y = total_GT_counts * scale_factor), 
             color = COLOR_GT, size = 3) +
  
  # Labels for unique miRNAs
  geom_text(aes(y = total_G_counts, label = n_unique_miRNAs),
            vjust = -0.5, size = 3, fontface = "bold", color = "gray30") +
  
  # Dual Y-axis
  scale_y_continuous(
    name = "Total G counts (substrate)",
    labels = comma,
    sec.axis = sec_axis(~ . / scale_factor, 
                        name = "Total G>T counts (product)",
                        labels = comma)
  ) +
  scale_x_continuous(breaks = 1:22) +
  
  labs(
    title = "E. G-Content Landscape (Option A: Dual-Axis)",
    subtitle = "Green bars: Total G counts | Red line: G>T counts | Numbers: Unique miRNAs with G",
    x = "Position in miRNA (1-22)",
    caption = "Seed region (2-8) highlighted. Numbers above bars = unique miRNAs with G at position."
  ) +
  theme_prof +
  theme(
    axis.title.y.left = element_text(color = COLOR_G, face = "bold"),
    axis.title.y.right = element_text(color = COLOR_GT, face = "bold"),
    axis.text.y.left = element_text(color = COLOR_G),
    axis.text.y.right = element_text(color = COLOR_GT)
  )

ggsave("../figures/option_A_dual_axis.png", option_a, width = 14, height = 8, dpi = 300, bg = "white")
cat("   ✅ SAVED: option_A_dual_axis.png\n\n")

# ============================================================================
# OPTION B: BUBBLE PLOT (bars + sized bubbles + colored by miRNA diversity)
# ============================================================================

cat("🎨 OPTION B: Bubble plot (bars + bubbles with color)...\n")

option_b <- ggplot(panel_e_data, aes(x = Position)) +
  # Seed region
  annotate("rect", xmin = 1.5, xmax = 8.5, ymin = 0, ymax = Inf,
           fill = COLOR_SEED, alpha = 0.3) +
  
  # BARS: G counts
  geom_col(aes(y = total_G_counts), fill = COLOR_G, alpha = 0.6, width = 0.7) +
  
  # BUBBLES: G>T counts (size) + miRNA diversity (color)
  geom_point(aes(y = total_G_counts * 0.65, 
                 size = total_GT_counts,
                 fill = n_unique_miRNAs),
             shape = 21, color = "black", alpha = 0.85, stroke = 1.5) +
  
  # Labels: G>T counts inside bubbles
  geom_text(aes(y = total_G_counts * 0.65, 
                label = comma(round(total_GT_counts, 0))),
            size = 2.5, fontface = "bold", color = "white") +
  
  # Scales
  scale_y_continuous(
    name = "Total G counts (substrate)",
    labels = comma,
    trans = "log10"  # Log scale for better visibility
  ) +
  scale_x_continuous(breaks = 1:22) +
  
  scale_size_continuous(
    name = "G>T Counts",
    range = c(3, 18),
    labels = comma
  ) +
  
  scale_fill_gradient(
    low = "#BBDEFB",     # Light blue (low diversity)
    high = "#0D47A1",    # Dark blue (high diversity)
    name = "Unique\nmiRNAs",
    labels = comma
  ) +
  
  labs(
    title = "E. G-Content Landscape (Option B: Bubble Plot)",
    subtitle = "Bars: Total G counts (log scale) | Bubble size: G>T counts | Bubble color: miRNA diversity",
    x = "Position in miRNA (1-22)",
    caption = "Seed region (2-8) highlighted. Numbers in bubbles = G>T counts. Bubble color intensity = number of unique miRNAs."
  ) +
  theme_prof

ggsave("../figures/option_B_bubble_plot.png", option_b, width = 14, height = 9, dpi = 300, bg = "white")
cat("   ✅ SAVED: option_B_bubble_plot.png\n\n")

# ============================================================================
# OPTION C: GROUPED BARS (3 metrics side by side, normalized)
# ============================================================================

cat("🎨 OPTION C: Grouped bars (3 metrics normalized)...\n")

# Normalize all 3 metrics to 0-100 scale for comparison
panel_e_normalized <- panel_e_data %>%
  mutate(
    norm_G = (total_G_counts / max(total_G_counts)) * 100,
    norm_GT = (total_GT_counts / max(total_GT_counts)) * 100,
    norm_miRNAs = (n_unique_miRNAs / max(n_unique_miRNAs)) * 100
  ) %>%
  pivot_longer(
    cols = c(norm_G, norm_GT, norm_miRNAs),
    names_to = "Metric",
    values_to = "Normalized_Value"
  ) %>%
  mutate(
    Metric = recode(Metric,
                    norm_G = "Total G counts",
                    norm_GT = "G>T counts", 
                    norm_miRNAs = "Unique miRNAs")
  )

option_c <- ggplot(panel_e_normalized, aes(x = Position, y = Normalized_Value, fill = Metric)) +
  # Seed region
  annotate("rect", xmin = 1.5, xmax = 8.5, ymin = 0, ymax = Inf,
           fill = COLOR_SEED, alpha = 0.2) +
  
  geom_col(position = position_dodge(width = 0.8), width = 0.7, alpha = 0.8) +
  
  scale_fill_manual(
    values = c("Total G counts" = COLOR_G,
               "G>T counts" = COLOR_GT,
               "Unique miRNAs" = "#1976D2")
  ) +
  
  scale_x_continuous(breaks = 1:22) +
  scale_y_continuous(breaks = seq(0, 100, 25)) +
  
  labs(
    title = "E. G-Content Landscape (Option C: Grouped Bars)",
    subtitle = "All 3 metrics normalized to 0-100% for direct comparison",
    x = "Position in miRNA (1-22)",
    y = "Normalized value (% of maximum)",
    fill = "Metric",
    caption = "All metrics scaled to 0-100% for comparison. Grouped bars show relative patterns across positions."
  ) +
  theme_prof

ggsave("../figures/option_C_grouped_bars.png", option_c, width = 14, height = 8, dpi = 300, bg = "white")
cat("   ✅ SAVED: option_C_grouped_bars.png\n\n")

# ============================================================================
# OPTION D: THREE-PANEL LAYOUT (separate plots stacked)
# ============================================================================

cat("🎨 OPTION D: Three-panel layout (stacked)...\n")

# Panel 1: G counts
p1 <- ggplot(panel_e_data, aes(x = Position, y = total_G_counts)) +
  annotate("rect", xmin = 1.5, xmax = 8.5, ymin = 0, ymax = Inf,
           fill = COLOR_SEED, alpha = 0.2) +
  geom_col(fill = COLOR_G, alpha = 0.8, width = 0.7) +
  geom_text(aes(label = comma(round(total_G_counts, 0))), 
            vjust = -0.3, size = 2.5, angle = 45) +
  scale_x_continuous(breaks = 1:22) +
  scale_y_continuous(labels = comma, trans = "log10") +
  labs(
    title = "Total G Counts (Substrate)",
    x = NULL,
    y = "Counts (log scale)"
  ) +
  theme_prof +
  theme(axis.text.x = element_blank())

# Panel 2: G>T counts
p2 <- ggplot(panel_e_data, aes(x = Position, y = total_GT_counts)) +
  annotate("rect", xmin = 1.5, xmax = 8.5, ymin = 0, ymax = Inf,
           fill = COLOR_SEED, alpha = 0.2) +
  geom_col(fill = COLOR_GT, alpha = 0.8, width = 0.7) +
  geom_text(aes(label = comma(round(total_GT_counts, 0))), 
            vjust = -0.3, size = 2.5, angle = 45) +
  scale_x_continuous(breaks = 1:22) +
  scale_y_continuous(labels = comma, trans = "log10") +
  labs(
    title = "Total G>T Counts (Product)",
    x = NULL,
    y = "Counts (log scale)"
  ) +
  theme_prof +
  theme(axis.text.x = element_blank())

# Panel 3: Unique miRNAs
p3 <- ggplot(panel_e_data, aes(x = Position, y = n_unique_miRNAs)) +
  annotate("rect", xmin = 1.5, xmax = 8.5, ymin = 0, ymax = Inf,
           fill = COLOR_SEED, alpha = 0.2) +
  geom_col(fill = "#1976D2", alpha = 0.8, width = 0.7) +
  geom_text(aes(label = n_unique_miRNAs), vjust = -0.3, size = 3, fontface = "bold") +
  scale_x_continuous(breaks = 1:22) +
  scale_y_continuous(breaks = seq(0, max(panel_e_data$n_unique_miRNAs), 25)) +
  labs(
    title = "Unique miRNAs with G (Diversity)",
    x = "Position in miRNA (1-22)",
    y = "Number of miRNAs"
  ) +
  theme_prof

# Combine with patchwork
option_d <- p1 / p2 / p3 +
  plot_annotation(
    title = "E. G-Content Landscape (Option D: Three-Panel Layout)",
    subtitle = "Separate visualization of each metric for clarity",
    caption = "Seed region (2-8) highlighted in yellow. Log scale for counts. Direct comparison of patterns.",
    theme = theme(
      plot.title = element_text(face = "bold", size = 18, hjust = 0.5),
      plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray40")
    )
  )

ggsave("../figures/option_D_three_panel.png", option_d, width = 14, height = 12, dpi = 300, bg = "white")
cat("   ✅ SAVED: option_D_three_panel.png\n\n")

# ============================================================================
# OPTION E: HEATMAP-STYLE (color intensity for each metric)
# ============================================================================

cat("🎨 OPTION E: Heatmap-style visualization...\n")

panel_e_long <- panel_e_data %>%
  select(Position, total_G_counts, total_GT_counts, n_unique_miRNAs) %>%
  pivot_longer(
    cols = c(total_G_counts, total_GT_counts, n_unique_miRNAs),
    names_to = "Metric",
    values_to = "Value"
  ) %>%
  mutate(
    Metric = recode(Metric,
                    total_G_counts = "G Counts\n(Substrate)",
                    total_GT_counts = "G>T Counts\n(Product)",
                    n_unique_miRNAs = "Unique miRNAs\n(Diversity)"),
    Metric = factor(Metric, levels = c("G Counts\n(Substrate)", 
                                       "G>T Counts\n(Product)", 
                                       "Unique miRNAs\n(Diversity)"))
  ) %>%
  group_by(Metric) %>%
  mutate(
    norm_value = (Value / max(Value)) * 100  # Normalize within each metric
  ) %>%
  ungroup()

option_e <- ggplot(panel_e_long, aes(x = Position, y = Metric, fill = norm_value)) +
  geom_tile(color = "white", linewidth = 1) +
  geom_text(aes(label = comma(round(Value, 0))), 
            size = 2.5, fontface = "bold", color = "white") +
  
  # Seed region vertical lines
  geom_vline(xintercept = c(1.5, 8.5), linetype = "dashed", color = "yellow", linewidth = 1) +
  
  scale_fill_gradient(
    low = "#E3F2FD",
    high = "#0D47A1",
    name = "Normalized\nIntensity (%)",
    labels = function(x) paste0(x, "%")
  ) +
  
  scale_x_continuous(breaks = 1:22, expand = c(0, 0)) +
  
  labs(
    title = "E. G-Content Landscape (Option E: Heatmap Style)",
    subtitle = "Color intensity shows normalized values (0-100%) for each metric",
    x = "Position in miRNA (1-22)",
    y = NULL,
    caption = "Seed region (2-8) marked by yellow dashed lines. Numbers = actual values. Color = normalized intensity."
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5, color = "gray40"),
    axis.text.x = element_text(size = 10),
    axis.text.y = element_text(size = 11, face = "bold"),
    panel.grid = element_blank(),
    legend.position = "right"
  )

ggsave("../figures/option_E_heatmap.png", option_e, width = 14, height = 6, dpi = 300, bg = "white")
cat("   ✅ SAVED: option_E_heatmap.png\n\n")

# ============================================================================
# SUMMARY STATISTICS
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("📊 SUMMARY STATISTICS:\n")
cat("\n")

cat("🟢 TOTAL G COUNTS (Substrate):\n")
cat("   • Total across all positions:", comma(sum(panel_e_data$total_G_counts)), "\n")
cat("   • Mean per position:", comma(round(mean(panel_e_data$total_G_counts), 0)), "\n")
cat("   • Position with most G:", panel_e_data$Position[which.max(panel_e_data$total_G_counts)], 
    "(", comma(max(panel_e_data$total_G_counts)), "counts )\n")
cat("\n")

cat("🔴 TOTAL G>T COUNTS (Product):\n")
cat("   • Total across all positions:", comma(sum(panel_e_data$total_GT_counts)), "\n")
cat("   • Mean per position:", comma(round(mean(panel_e_data$total_GT_counts), 0)), "\n")
cat("   • Position with most G>T:", panel_e_data$Position[which.max(panel_e_data$total_GT_counts)], 
    "(", comma(max(panel_e_data$total_GT_counts)), "counts )\n")
cat("\n")

cat("🧬 UNIQUE miRNAs (Diversity):\n")
cat("   • Mean miRNAs per position:", round(mean(panel_e_data$n_unique_miRNAs), 1), "\n")
cat("   • Position with most miRNAs:", panel_e_data$Position[which.max(panel_e_data$n_unique_miRNAs)], 
    "(", max(panel_e_data$n_unique_miRNAs), "miRNAs )\n")
cat("\n")

# Seed vs Non-seed comparison
seed_comparison <- panel_e_data %>%
  group_by(is_seed) %>%
  summarise(
    mean_G_counts = mean(total_G_counts),
    mean_GT_counts = mean(total_GT_counts),
    mean_unique_miRNAs = mean(n_unique_miRNAs),
    .groups = 'drop'
  ) %>%
  mutate(Region = ifelse(is_seed, "Seed (2-8)", "Non-Seed"))

cat("🌱 SEED vs NON-SEED COMPARISON:\n")
print(seed_comparison)
cat("\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("✅ 4 VISUALIZATION OPTIONS GENERATED:\n")
cat("\n")
cat("   A. option_A_dual_axis.png     - Dual Y-axis (bars + line)\n")
cat("   B. option_B_bubble_plot.png   - Bubble plot (bars + sized/colored bubbles)\n")
cat("   C. option_C_grouped_bars.png  - Grouped bars (normalized metrics)\n")
cat("   D. option_D_three_panel.png   - Three separate panels (stacked)\n")
cat("   E. option_E_heatmap.png       - Heatmap style (color intensity)\n")
cat("\n")
cat("📊 NEXT STEP: Review all 5 options and decide which communicates best!\n")
cat("\n")

