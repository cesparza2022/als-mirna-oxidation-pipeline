#!/usr/bin/env Rscript
# ============================================================================
# PANEL E: G-Content Landscape - FINAL VERSION (User Specifications)
# ============================================================================
# 
# EXACT SPECIFICATIONS:
#
# X-axis: Position (1-22)
#
# Y-axis (height): Total copies of miRNAs with G at that position
#   - For each miRNA that has G at position X:
#     Sum ALL counts of that miRNA (all its rows, all samples)
#   - This gives total G "material" at each position
#
# Bubble SIZE: Number of unique miRNAs with G at that position
#   - How many different miRNAs have G there
#
# Bubble COLOR (red intensity): Sum of SNV G>T counts at that SPECIFIC position
#   - ONLY counts from rows "Pos:GT" at that specific position
#   - NOT all G>T from those miRNAs, ONLY that position
#
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
  library(readr)
  library(stringr)
  library(scales)
})

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  PANEL E: G-Content Landscape - FINAL BUBBLE PLOT\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# ============================================================================
# LOAD DATA
# ============================================================================

cat("📂 Loading data...\n")

# Path relative to step1/scripts/ (go up 2 levels to root, then to pipeline_2)
root <- normalizePath(file.path(getwd(), "../.."))
data_path <- file.path(root, "pipeline_2", "final_processed_data_CLEAN.csv")

data <- read_csv(data_path, show_col_types = FALSE)
sample_cols <- setdiff(names(data), c("miRNA_name", "pos.mut"))

cat("   ✅ Data loaded:", nrow(data), "rows\n")
cat("   ✅ Samples:", length(sample_cols), "\n\n")

# ============================================================================
# CALCULATE METRIC 1: Total copies of miRNAs with G at each position
# ============================================================================

cat("📊 MÉTRICA 1: Total copias de miRNAs con G en cada posición...\n")

# Step 1: Identify which miRNAs have G at each position
mirnas_with_G_by_pos <- data %>%
  filter(str_detect(pos.mut, "^\\d+:G[TCAG]")) %>%  # Any G mutation
  mutate(Position = as.numeric(str_extract(pos.mut, "^\\d+"))) %>%
  select(Position, miRNA_name) %>%
  distinct()

cat("   ✅ Identified miRNAs with G at each position\n")

# Step 2: For each position-miRNA pair, sum ALL counts of that miRNA
total_copies_by_position <- mirnas_with_G_by_pos %>%
  left_join(
    data %>% 
      group_by(miRNA_name) %>%
      summarise(total_miRNA_counts = sum(across(all_of(sample_cols)), na.rm = TRUE)),
    by = "miRNA_name"
  ) %>%
  group_by(Position) %>%
  summarise(
    total_G_copies = sum(total_miRNA_counts, na.rm = TRUE),
    .groups = 'drop'
  )

cat("   📊 Total G copies calculated\n")
cat("   Example - Position 6:", comma(total_copies_by_position$total_G_copies[total_copies_by_position$Position == 6]), "copies\n\n")

# ============================================================================
# CALCULATE METRIC 2: Sum of SNV G>T counts at SPECIFIC position
# ============================================================================

cat("🔴 MÉTRICA 2: Suma de SNVs G>T en posición específica...\n")

# Only sum counts from rows with "Pos:GT" at that specific position
gt_counts_specific <- data %>%
  filter(str_detect(pos.mut, "^\\d+:GT$")) %>%  # ONLY G>T
  mutate(Position = as.numeric(str_extract(pos.mut, "^\\d+"))) %>%
  group_by(Position) %>%
  summarise(
    GT_counts_at_position = sum(across(all_of(sample_cols)), na.rm = TRUE),
    .groups = 'drop'
  )

cat("   🔴 G>T counts at specific positions calculated\n")
cat("   Example - Position 6:", comma(gt_counts_specific$GT_counts_at_position[gt_counts_specific$Position == 6]), "G>T counts\n\n")

# ============================================================================
# CALCULATE METRIC 3: Number of unique miRNAs with G at each position
# ============================================================================

cat("🧬 MÉTRICA 3: Número de miRNAs únicos con G...\n")

unique_mirnas_by_pos <- data %>%
  filter(str_detect(pos.mut, "^\\d+:G[TCAG]")) %>%
  mutate(Position = as.numeric(str_extract(pos.mut, "^\\d+"))) %>%
  group_by(Position) %>%
  summarise(
    n_unique_miRNAs = n_distinct(miRNA_name),
    .groups = 'drop'
  )

cat("   🧬 Unique miRNAs calculated\n")
cat("   Example - Position 6:", unique_mirnas_by_pos$n_unique_miRNAs[unique_mirnas_by_pos$Position == 6], "miRNAs\n\n")

# ============================================================================
# COMBINE ALL METRICS
# ============================================================================

panel_e_final <- total_copies_by_position %>%
  left_join(gt_counts_specific, by = "Position") %>%
  left_join(unique_mirnas_by_pos, by = "Position") %>%
  replace_na(list(GT_counts_at_position = 0, n_unique_miRNAs = 0)) %>%
  mutate(
    is_seed = Position >= 2 & Position <= 8
  )

cat("📊 Combined final data:\n")
print(panel_e_final, n = Inf)
cat("\n")

# ============================================================================
# CREATE FINAL BUBBLE PLOT
# ============================================================================

cat("🎨 Creating final bubble plot...\n\n")

COLOR_SEED <- "#FFF9C4"  # Light yellow for seed

# Create the plot
panel_e <- ggplot(panel_e_final, aes(x = Position, y = total_G_copies)) +
  
  # Seed region background
  annotate("rect", 
           xmin = 1.5, xmax = 8.5,  
           ymin = 0, ymax = Inf,
           fill = COLOR_SEED, alpha = 0.35) +
  
  # Seed region label (moved to bottom to avoid bubble overlap)
  annotate("text", x = 5, y = min(panel_e_final$total_G_copies) * 0.5,
           label = "SEED REGION\n(positions 2-8)", 
           size = 4.5, fontface = "bold", color = "gray40") +
  
  # BUBBLES with 3 dimensions:
  # - X: Position
  # - Y: Total G copies (MÉTRICA 1)
  # - Size: Unique miRNAs (MÉTRICA 3)
  # - Color: G>T counts (MÉTRICA 2)
  geom_point(aes(size = n_unique_miRNAs, 
                 fill = GT_counts_at_position),
             shape = 21, color = "black", alpha = 0.85, stroke = 1.8) +
  
  # Add value labels (optional - can remove if too crowded)
  geom_text(aes(label = n_unique_miRNAs), 
            size = 3, fontface = "bold", color = "white") +
  
  # Scales
  scale_x_continuous(breaks = 1:23, minor_breaks = NULL) +
  
  scale_y_continuous(
    labels = comma,
    trans = "log10",  # Log scale for better visibility
    breaks = c(0.1, 1, 10, 100, 1000)
  ) +
  
  # Bubble size scale
  scale_size_continuous(
    name = "Number of\nUnique miRNAs\nwith G",
    range = c(3, 20),
    breaks = c(25, 50, 100, 150)
  ) +
  
  # Bubble color scale (red intensity for G>T)
  scale_fill_gradient(
    low = "#FFEBEE",       # Very light red (low G>T)
    high = "#B71C1C",      # Dark red (high G>T)
    name = "G>T SNV Counts\nat Position",
    labels = comma,
    trans = "log10"
  ) +
  
  # Labels
  labs(
    title = "E. G-Content Landscape: Substrate, Diversity, and Oxidation Burden",
    subtitle = "Y-axis: Total miRNA copies with G | Bubble size: Unique miRNAs | Bubble color: G>T mutation counts",
    x = "Position in miRNA (1-23)",
    y = "Total copies of miRNAs with G at position (log scale)",
    caption = "Each bubble represents a position. Y-position = total G substrate availability (sum of all miRNA copies with G).\nBubble size = miRNA diversity (how many different miRNAs). Bubble color intensity = G>T oxidation burden (darker red = more G>T).\nSeed region (2-8) highlighted in yellow. Log scale for better visualization of wide value ranges."
  ) +
  
  # Theme
  theme_classic(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 16, hjust = 0.5, color = "#2c3e50"),
    plot.subtitle = element_text(size = 11, hjust = 0.5, color = "gray40", lineheight = 1.3),
    plot.caption = element_text(size = 9.5, hjust = 0, color = "gray50", lineheight = 1.4, margin = margin(t = 15)),
    axis.title = element_text(face = "bold", size = 12),
    axis.title.y = element_text(size = 11),
    axis.text = element_text(size = 10),
    axis.text.x = element_text(size = 10),
    legend.position = "right",
    legend.title = element_text(face = "bold", size = 10),
    legend.text = element_text(size = 9),
    legend.box = "vertical",
    legend.spacing.y = unit(0.4, "cm"),
    panel.grid.major = element_line(color = "grey92", linewidth = 0.3),
    panel.grid.minor = element_blank(),
    panel.border = element_rect(color = "gray60", linewidth = 1.2, fill = NA)
  )

# Save (to step1/outputs/figures/)
figure_dir <- file.path("..", "outputs", "figures")
dir.create(figure_dir, showWarnings = FALSE, recursive = TRUE)
output_file <- file.path(figure_dir, "step1_panelE_FINAL_BUBBLE.png")
ggsave(output_file, plot = panel_e, width = 14, height = 9, dpi = 300, bg = "white")

cat("   ✅ SAVED:", output_file, "\n\n")

# ============================================================================
# SUMMARY AND INTERPRETATION
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("📊 PANEL E FINAL - WHAT IT SHOWS:\n")
cat("\n")

cat("🎯 3 DIMENSIONS IN ONE PLOT:\n")
cat("\n")
cat("1️⃣  Y-AXIS (Bubble height):\n")
cat("    Total copies of miRNAs with G at position\n")
cat("    • Highest:", panel_e_final$Position[which.max(panel_e_final$total_G_copies)],
    "with", comma(round(max(panel_e_final$total_G_copies), 1)), "copies\n")
cat("    • Shows: SUBSTRATE availability (how much G material exists)\n")
cat("\n")

cat("2️⃣  BUBBLE SIZE:\n")
cat("    Number of unique miRNAs with G\n")
cat("    • Highest:", panel_e_final$Position[which.max(panel_e_final$n_unique_miRNAs)],
    "with", max(panel_e_final$n_unique_miRNAs), "unique miRNAs\n")
cat("    • Shows: DIVERSITY (how many different miRNAs affected)\n")
cat("\n")

cat("3️⃣  BUBBLE COLOR (Red intensity):\n")
cat("    G>T SNV counts at SPECIFIC position\n")
cat("    • Highest:", panel_e_final$Position[which.max(panel_e_final$GT_counts_at_position)],
    "with", comma(round(max(panel_e_final$GT_counts_at_position), 1)), "G>T counts\n")
cat("    • Shows: OXIDATION burden (how much G>T at that position)\n")
cat("\n")

# Calculate correlations
cor_G_vs_GT <- cor(panel_e_final$total_G_copies, panel_e_final$GT_counts_at_position, 
                   method = "spearman")
cor_G_vs_miRNAs <- cor(panel_e_final$total_G_copies, panel_e_final$n_unique_miRNAs, 
                       method = "spearman")

cat("🔬 CORRELATIONS:\n")
cat("   • G copies vs G>T counts:", sprintf("r = %.3f", cor_G_vs_GT), 
    ifelse(cor_G_vs_GT > 0.7, "✅ STRONG", "⚠️  WEAK"), "\n")
cat("   • G copies vs unique miRNAs:", sprintf("r = %.3f", cor_G_vs_miRNAs),
    ifelse(cor_G_vs_miRNAs > 0.7, "✅ STRONG", "⚠️  WEAK"), "\n")
cat("\n")

# Identify hotspots (high in all 3 metrics)
hotspots <- panel_e_final %>%
  mutate(
    rank_G = rank(-total_G_copies),
    rank_GT = rank(-GT_counts_at_position),
    rank_miRNAs = rank(-n_unique_miRNAs),
    combined_rank = rank_G + rank_GT + rank_miRNAs
  ) %>%
  arrange(combined_rank) %>%
  head(5)

cat("🔥 TOP 5 HOTSPOTS (high in all 3 metrics):\n")
cat("\n")
print(hotspots %>% select(Position, total_G_copies, GT_counts_at_position, n_unique_miRNAs, is_seed))
cat("\n")

# Seed vs Non-Seed
seed_summary <- panel_e_final %>%
  group_by(is_seed) %>%
  summarise(
    mean_G_copies = mean(total_G_copies),
    total_GT = sum(GT_counts_at_position),
    mean_miRNAs = mean(n_unique_miRNAs),
    .groups = 'drop'
  ) %>%
  mutate(Region = ifelse(is_seed, "Seed (2-8)", "Non-Seed"))

cat("🌱 SEED vs NON-SEED:\n")
print(seed_summary)
cat("\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("💡 INTERPRETATION GUIDE:\n")
cat("\n")
cat("🔍 HOW TO READ THE PLOT:\n")
cat("\n")
cat("  • HIGH bubble (Y-axis) = Many G copies (substrate)\n")
cat("  • LARGE bubble (size) = Many different miRNAs (diversity)\n")
cat("  • DARK RED bubble (color) = Many G>T mutations (oxidation)\n")
cat("\n")
cat("  🔥 HOTSPOT = High + Large + Dark Red\n")
cat("  ❄️  COLD SPOT = Low + Small + Light Red\n")
cat("\n")
cat("🎯 KEY QUESTIONS THIS ANSWERS:\n")
cat("\n")
cat("  1. ¿Dónde hay más Gs? → Y-axis height\n")
cat("  2. ¿Cuántos miRNAs afectados? → Bubble size\n")
cat("  3. ¿Cuánta oxidación en esa posición? → Bubble color\n")
cat("  4. ¿Seed es diferente? → Yellow region\n")
cat("  5. ¿G-content predice G>T? → Compare Y-height with color\n")
cat("\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("✅ PANEL E FINAL GENERATED\n")
cat("   📁 File: step1_panelE_FINAL_BUBBLE.png\n")
cat("   📊 3 metrics integrated\n")
cat("   🎨 Bubble plot with optimal information density\n")
cat("\n")


cat("   📊 3 metrics integrated\n")
cat("   🎨 Bubble plot with optimal information density\n")
cat("\n")


cat("   📊 3 metrics integrated\n")
cat("   🎨 Bubble plot with optimal information density\n")
cat("\n")

