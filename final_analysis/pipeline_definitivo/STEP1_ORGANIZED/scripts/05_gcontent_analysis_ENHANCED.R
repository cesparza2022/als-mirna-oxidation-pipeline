#!/usr/bin/env Rscript
# ============================================================================
# PANEL E: G-Content Analysis - ENHANCED VERSION with Multiple Dimensions
# ============================================================================
# 
# PURPOSE: Show comprehensive G-content landscape with multiple layers:
#   1. Number of miRNAs with G at each position (bar height)
#   2. Total G>T mutations at each position (bubble size)
#   3. G>T specificity at each position (color intensity)
#   4. Seed region highlighting
#
# This creates a MULTI-DIMENSIONAL visualization showing:
#   - G substrate availability (how many Gs exist)
#   - G>T mutation burden (how many G>T mutations occur)
#   - G>T selectivity (what % of G mutations are G>T)
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
cat("  PANEL E: G-Content Landscape - ENHANCED MULTI-DIMENSIONAL\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# ============================================================================
# LOAD DATA
# ============================================================================

cat("📂 Loading data...\n")

data_file <- "../../pipeline_2/final_processed_data_CLEAN.csv"

if (!file.exists(data_file)) {
  stop("❌ Data file not found: ", data_file)
}

data <- read_csv(data_file, show_col_types = FALSE)

cat("   ✅ Data loaded:", nrow(data), "rows\n")
cat("   ✅ Unique miRNAs:", length(unique(data$miRNA_name)), "\n\n")

# ============================================================================
# CALCULATE MULTI-DIMENSIONAL G-CONTENT METRICS
# ============================================================================

cat("🔢 Calculating G-content landscape metrics...\n\n")

# For each position, calculate:
# 1. Number of miRNAs with G (substrate availability)
# 2. Total G>T mutations (oxidation product)
# 3. Total G mutations (all G>X)
# 4. G>T specificity (% of G mutations that are G>T)

g_landscape <- data %>%
  mutate(Position = as.numeric(str_extract(pos.mut, "^\\d+"))) %>%
  filter(!is.na(Position), Position >= 1, Position <= 22) %>%
  mutate(
    is_G_mutation = str_detect(pos.mut, "^\\d+:G[TCAG]"),
    is_GT_mutation = str_detect(pos.mut, "^\\d+:GT$"),
    is_GC_mutation = str_detect(pos.mut, "^\\d+:GC$"),
    is_GA_mutation = str_detect(pos.mut, "^\\d+:GA$")
  ) %>%
  group_by(Position) %>%
  summarise(
    # Dimension 1: G-content (substrate)
    miRNAs_with_G = n_distinct(miRNA_name[is_G_mutation]),
    
    # Dimension 2: Mutation burden
    total_GT_mutations = sum(is_GT_mutation),
    total_GC_mutations = sum(is_GC_mutation),
    total_GA_mutations = sum(is_GA_mutation),
    total_G_mutations = sum(is_G_mutation),
    
    # Dimension 3: Specificity
    GT_specificity = ifelse(total_G_mutations > 0, 
                            (total_GT_mutations / total_G_mutations) * 100, 
                            0),
    
    .groups = 'drop'
  ) %>%
  mutate(
    # Classify positions
    is_seed = Position >= 2 & Position <= 8,
    region = ifelse(is_seed, "Seed (2-8)", "Non-Seed")
  )

cat("📊 G-content landscape metrics:\n")
print(g_landscape, n = Inf)
cat("\n")

# ============================================================================
# CREATE ENHANCED MULTI-DIMENSIONAL FIGURE
# ============================================================================

cat("🎨 Creating enhanced multi-dimensional figure...\n\n")

COLOR_G <- "#2E7D32"  # Green for G-content
COLOR_GT <- "#D62728"  # Red for G>T
COLOR_SEED <- "#FFF9C4"  # Light yellow for seed

# Calculate max values for scaling
max_mirnas <- max(g_landscape$miRNAs_with_G)
max_gt <- max(g_landscape$total_GT_mutations)

panel_e_enhanced <- ggplot(g_landscape, aes(x = Position)) +
  
  # 1. SEED REGION HIGHLIGHTING (background)
  annotate("rect", 
           xmin = 1.5, xmax = 8.5,  
           ymin = -5, ymax = Inf,
           fill = COLOR_SEED, alpha = 0.3) +
  
  # 2. BAR: miRNAs with G (substrate availability)
  geom_col(aes(y = miRNAs_with_G), 
           fill = COLOR_G, alpha = 0.6, width = 0.7) +
  
  # 3. BUBBLES: G>T mutations (oxidation product)
  # Positioned at 80% of bar height for visibility
  geom_point(aes(y = miRNAs_with_G * 0.8, 
                 size = total_GT_mutations,
                 fill = GT_specificity),
             shape = 21, color = "black", alpha = 0.85, stroke = 1.5) +
  
  # 4. VALUE LABELS on bars
  geom_text(aes(y = miRNAs_with_G, label = miRNAs_with_G), 
            vjust = -0.5, size = 3, fontface = "bold", color = "gray30") +
  
  # 5. G>T COUNT LABELS on bubbles
  geom_text(aes(y = miRNAs_with_G * 0.8, label = total_GT_mutations), 
            size = 2.5, fontface = "bold", color = "white") +
  
  # 6. SEED ANNOTATION
  annotate("text", x = 5, y = max_mirnas * 1.05,
           label = "SEED REGION\n(positions 2-8)", 
           size = 4, fontface = "bold", color = "gray40") +
  
  # Scales
  scale_x_continuous(breaks = 1:22, minor_breaks = NULL) +
  scale_y_continuous(
    expand = expansion(mult = c(0.05, 0.15)),
    breaks = seq(0, max_mirnas, by = 25)
  ) +
  
  # Bubble size scale
  scale_size_continuous(
    name = "G>T Mutation\nCount",
    range = c(2, 18),
    breaks = c(25, 50, 100, 150),
    labels = comma
  ) +
  
  # Bubble color scale (G>T specificity)
  scale_fill_gradient2(
    low = "#4CAF50",      # Green (low specificity)
    mid = "#FFC107",      # Yellow (medium)
    high = "#D62728",     # Red (high specificity)
    midpoint = 50,
    limits = c(0, 100),
    name = "G>T Specificity\n(% of G muts)",
    labels = function(x) paste0(x, "%")
  ) +
  
  # Labels
  labs(
    title = "E. Multi-Dimensional G-Content Landscape",
    subtitle = "Substrate availability (bars), Mutation burden (bubble size), and G>T selectivity (bubble color)",
    x = "Position in miRNA (1-22)",
    y = "Number of miRNAs with G nucleotide",
    caption = "Bars: miRNAs with G at each position (substrate) | Bubbles: G>T mutation count (product) | Color: % of G mutations that are G>T (specificity)\nSeed region (2-8) highlighted in yellow. Higher G-content → More potential oxidation sites."
  ) +
  
  # Theme
  theme_classic(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 16, hjust = 0.5, color = "#2c3e50"),
    plot.subtitle = element_text(size = 11, hjust = 0.5, color = "gray40", lineheight = 1.2),
    plot.caption = element_text(size = 9, hjust = 0, color = "gray50", lineheight = 1.3, margin = margin(t = 10)),
    axis.title = element_text(face = "bold", size = 12),
    axis.text = element_text(size = 11),
    axis.text.x = element_text(size = 10),
    legend.position = "right",
    legend.title = element_text(face = "bold", size = 10),
    legend.text = element_text(size = 9),
    legend.box = "vertical",
    legend.spacing.y = unit(0.3, "cm"),
    panel.grid.major.y = element_line(color = "grey90", linewidth = 0.3),
    panel.grid.minor = element_blank(),
    panel.border = element_rect(color = "gray60", linewidth = 1.2, fill = NA)
  )

# Save
output_file <- "../figures/step1_panelE_gcontent_ENHANCED.png"
ggsave(output_file, plot = panel_e_enhanced, width = 14, height = 9, dpi = 300, bg = "white")

cat("   ✅ SAVED:", output_file, "\n\n")

# ============================================================================
# PRINT SUMMARY STATISTICS
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("📊 ENHANCED PANEL E - WHAT IT SHOWS:\n")
cat("\n")
cat("✅ DIMENSION 1: G-Content (Substrate Availability)\n")
cat("   • Bar Height = Number of miRNAs with G at each position\n")
cat("   • Highest: Position", g_landscape$Position[which.max(g_landscape$miRNAs_with_G)], 
    "with", max(g_landscape$miRNAs_with_G), "miRNAs\n")
cat("   • Lowest: Position", g_landscape$Position[which.min(g_landscape$miRNAs_with_G)], 
    "with", min(g_landscape$miRNAs_with_G), "miRNAs\n")
cat("\n")

cat("✅ DIMENSION 2: G>T Mutation Burden (Product)\n")
cat("   • Bubble Size = Total G>T mutations at each position\n")
cat("   • Highest: Position", g_landscape$Position[which.max(g_landscape$total_GT_mutations)], 
    "with", max(g_landscape$total_GT_mutations), "G>T mutations\n")
cat("   • Total G>T across all positions:", sum(g_landscape$total_GT_mutations), "\n")
cat("\n")

cat("✅ DIMENSION 3: G>T Specificity (Selectivity)\n")
cat("   • Bubble Color = % of G mutations that are G>T\n")
cat("   • Red = High G>T specificity (oxidative damage signature)\n")
cat("   • Green = Low G>T specificity (other G mutations)\n")
cat("   • Mean G>T specificity:", sprintf("%.1f%%", mean(g_landscape$GT_specificity)), "\n")
cat("\n")

# Seed vs Non-Seed comparison
seed_stats <- g_landscape %>%
  group_by(region) %>%
  summarise(
    mean_G_content = mean(miRNAs_with_G),
    total_GT = sum(total_GT_mutations),
    mean_GT_spec = mean(GT_specificity),
    .groups = 'drop'
  )

cat("🌱 SEED REGION (2-8) vs NON-SEED:\n")
cat("\n")
print(seed_stats)
cat("\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("💡 KEY INSIGHTS:\n")
cat("\n")
cat("1. SUBSTRATE-PRODUCT RELATIONSHIP:\n")
cat("   Can compare if high G-content positions → high G>T burden\n")
cat("\n")
cat("2. POSITIONAL SPECIFICITY:\n")
cat("   Red bubbles = positions with HIGH oxidative selectivity\n")
cat("\n")
cat("3. SEED REGION IMPORTANCE:\n")
cat("   Highlighted region shows functional critical zone\n")
cat("\n")
cat("4. MULTI-LAYER INFORMATION:\n")
cat("   • Bars alone: Simple G distribution\n")
cat("   • + Bubbles: Adds mutation burden context\n")
cat("   • + Color: Adds specificity (oxidation signature)\n")
cat("\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("✅ PANEL E ENHANCED - MULTI-DIMENSIONAL G-CONTENT LANDSCAPE\n")
cat("   📊 Bars: G substrate\n")
cat("   🔵 Bubbles: G>T product (size)\n")
cat("   🌈 Color: G>T specificity\n")
cat("   🌱 Yellow: Seed region\n")
cat("\n")

