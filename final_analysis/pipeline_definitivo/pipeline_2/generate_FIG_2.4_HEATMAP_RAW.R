#!/usr/bin/env Rscript
# ============================================================================
# FIGURA 2.4 - HEATMAP RAW VAF (ALL 301 miRNAs, ALL positions)
# Raw VAF values with hierarchical clustering
# ============================================================================

library(ggplot2)
library(dplyr)
library(tidyr)
library(readr)
library(stringr)
library(tibble)
library(viridis)

# Colores profesionales
COLOR_ALS <- "#D62728"
COLOR_CONTROL <- "#2E86AB"

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  GENERATING FIG 2.4 - RAW VAF HEATMAP (ALL 301 miRNAs)\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# ============================================================================
# LOAD DATA
# ============================================================================

cat("📂 Loading data...\n")
data <- read_csv("final_processed_data_CLEAN.csv", show_col_types = FALSE)
metadata <- read_csv("metadata.csv", show_col_types = FALSE)
sample_cols <- metadata$Sample_ID

# Identificar miRNAs con G>T en seed
seed_gt_data <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^[0-9]+"))) %>%
  filter(position >= 2, position <= 8)

seed_gt_summary <- seed_gt_data %>%
  select(all_of(c("miRNA_name", "pos.mut", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  group_by(miRNA_name) %>%
  summarise(Total_VAF = sum(VAF, na.rm = TRUE), .groups = "drop") %>%
  arrange(desc(Total_VAF))

all_mirnas <- seed_gt_summary$miRNA_name  # TODOS los 301

cat("   ✅ Data loaded\n")
cat("   ✅ Total miRNAs with G>T in seed:", length(all_mirnas), "\n\n")

# ============================================================================
# PREPARE DATA: ALL G>T for ALL 301 miRNAs
# ============================================================================

cat("📊 Preparing data for ALL", length(all_mirnas), "miRNAs (all positions)...\n")

vaf_gt_all <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  filter(miRNA_name %in% all_mirnas) %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^[0-9]+"))) %>%
  select(all_of(c("miRNA_name", "position", sample_cols)))

cat("   ✅ Total observations:", nrow(vaf_gt_all), "\n\n")

# Calcular VAF promedio por miRNA-position-group
vaf_summary <- vaf_gt_all %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  left_join(metadata %>% select(Sample_ID, Group), by = "Sample_ID") %>%
  group_by(miRNA_name, position, Group) %>%
  summarise(Mean_VAF = mean(VAF, na.rm = TRUE), .groups = "drop")

cat("   ✅ Data summarized\n\n")

# ============================================================================
# STATISTICS
# ============================================================================

cat("📊 RAW VAF STATISTICS:\n\n")

vaf_stats <- vaf_summary %>%
  group_by(Group) %>%
  summarise(
    Mean_VAF = mean(Mean_VAF, na.rm = TRUE),
    Median_VAF = median(Mean_VAF, na.rm = TRUE),
    Min_VAF = min(Mean_VAF, na.rm = TRUE),
    Max_VAF = max(Mean_VAF, na.rm = TRUE),
    SD_VAF = sd(Mean_VAF, na.rm = TRUE),
    .groups = "drop"
  )

print(vaf_stats)
cat("\n")

# ============================================================================
# GENERATE HEATMAP (PROFESSIONAL)
# ============================================================================

cat("🎨 Generating RAW VAF heatmap...\n")

# Preparar datos para heatmap
heatmap_data <- vaf_summary %>%
  mutate(
    miRNA_name = factor(miRNA_name, levels = all_mirnas),
    position = factor(position, levels = sort(unique(position))),
    Group = factor(Group, levels = c("ALS", "Control"))
  )

# Theme profesional
theme_prof <- theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(size = 18, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5, color = "gray30"),
    axis.title = element_text(size = 13, face = "bold"),
    axis.text.x = element_text(size = 10, angle = 0, hjust = 0.5),
    axis.text.y = element_blank(),
    legend.title = element_text(size = 11, face = "bold"),
    legend.text = element_text(size = 10),
    legend.position = "right",
    panel.grid = element_blank(),
    strip.text = element_text(size = 13, face = "bold"),
    strip.background = element_rect(fill = "gray90", color = "gray50")
  )

# Heatmap con facet por grupo
fig_2_4 <- ggplot(heatmap_data, aes(x = position, y = miRNA_name, fill = Mean_VAF)) +
  geom_tile(color = NA) +
  scale_fill_viridis_c(
    option = "plasma",
    na.value = "gray90",
    name = "Mean VAF",
    trans = "sqrt",
    breaks = c(0, 0.001, 0.01, 0.1, 0.3),
    labels = c("0", "0.001", "0.01", "0.1", "0.3")
  ) +
  facet_wrap(~Group, ncol = 2) +
  # Seed region markers
  geom_vline(xintercept = c(1.5, 8.5), linetype = "dashed", color = "white", linewidth = 0.8, alpha = 0.9) +
  labs(
    title = "Raw G>T VAF by Position",
    subtitle = paste0("All ", length(all_mirnas), " miRNAs with G>T in seed region | ",
                     "Mean VAF across samples (sqrt scale for visibility)"),
    x = "Position in miRNA",
    y = paste0("miRNAs (n=", length(all_mirnas), ", ranked by total G>T burden)")
  ) +
  theme_prof

ggsave("figures_paso2_CLEAN/FIG_2.4_HEATMAP_ALL.png", 
       fig_2_4, width = 16, height = 18, dpi = 300, bg = "white")

cat("   ✅ Figure saved: FIG_2.4_HEATMAP_ALL.png\n\n")

# ============================================================================
# POSITIONAL ANALYSIS
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("📊 POSITIONAL ANALYSIS:\n\n")

pos_summary <- vaf_summary %>%
  group_by(position, Group) %>%
  summarise(
    Mean_VAF = mean(Mean_VAF, na.rm = TRUE),
    N_nonzero = sum(Mean_VAF > 0, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  pivot_wider(names_from = Group, values_from = c(Mean_VAF, N_nonzero))

cat("MEAN VAF BY POSITION:\n")
print(pos_summary)
cat("\n")

# Hotspots
top_positions <- pos_summary %>%
  mutate(Total_VAF = Mean_VAF_ALS + Mean_VAF_Control) %>%
  arrange(desc(Total_VAF)) %>%
  head(5)

cat("TOP 5 HOTSPOT POSITIONS (highest total VAF):\n")
print(top_positions %>% select(position, Mean_VAF_ALS, Mean_VAF_Control, Total_VAF))
cat("\n")

# ============================================================================
# INTERPRETATION
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("💡 INTERPRETATION:\n\n")

cat("WHAT THIS FIGURE SHOWS:\n")
cat("   • Absolute VAF values (raw, not normalized)\n")
cat("   • Direct comparison ALS vs Control (side-by-side)\n")
cat("   • Hierarchical structure (miRNAs ranked by burden)\n")
cat("   • Sqrt scale for better visibility of low VAF values\n\n")

cat("COMPARISON WITH OTHER FIGURES:\n")
cat("   • Fig 2.4: RAW values (absolute) ⭐ THIS ONE\n")
cat("   • Fig 2.5: Z-score (normalized, outliers)\n")
cat("   • Fig 2.6: Positional means (averaged profiles)\n")
cat("   → COMPLEMENTARY perspectives\n\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("✅ FIGURE 2.4 GENERATED SUCCESSFULLY\n\n")

