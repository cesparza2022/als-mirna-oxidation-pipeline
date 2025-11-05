#!/usr/bin/env Rscript
# ============================================================================
# HEATMAP FINAL - VERSIÓN PROFESIONAL
# Opción C (ALL 301) + Opción D (Summary) - Professional Style
# ============================================================================

library(ggplot2)
library(dplyr)
library(tidyr)
library(readr)
library(stringr)
library(patchwork)

# Colores profesionales
COLOR_ALS <- "#D62728"
COLOR_CONTROL <- "#404040"
COLOR_SEED_MARK <- "#2E86AB"

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  GENERATING PROFESSIONAL HEATMAPS\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# ============================================================================
# LOAD DATA
# ============================================================================

cat("📂 Loading data...\n")
data <- read_csv("final_processed_data_CLEAN.csv", show_col_types = FALSE)
metadata <- read_csv("metadata.csv", show_col_types = FALSE)
sample_cols <- metadata$Sample_ID

# Filter and rank
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

# All G>T (1-22)
vaf_gt_all <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^[0-9]+"))) %>%
  filter(!is.na(position), position <= 22) %>%
  select(all_of(c("miRNA_name", "position", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  left_join(metadata, by = "Sample_ID")

cat("   ✅ Data loaded\n")
cat("   ✅ miRNAs with G>T in seed:", nrow(seed_gt_summary), "\n\n")

# Professional theme
theme_prof <- theme_classic(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray40", margin = margin(b = 10)),
    axis.title = element_text(face = "bold", size = 13),
    axis.text = element_text(size = 11),
    axis.text.x = element_text(size = 11),
    strip.background = element_rect(fill = "gray95", color = "gray70", linewidth = 0.8),
    strip.text = element_text(face = "bold", size = 13, color = "gray20"),
    legend.position = "right",
    legend.title = element_text(face = "bold", size = 12),
    legend.text = element_text(size = 11),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    panel.border = element_rect(color = "gray70", fill = NA, linewidth = 0.8)
  )

# ============================================================================
# OPCIÓN C: ALL 301 miRNAs (PROFESSIONAL)
# ============================================================================

cat("🎨 [1/2] Generating ALL 301 miRNAs heatmap (professional)...\n")

all_mirnas <- seed_gt_summary$miRNA_name

data_all <- vaf_gt_all %>%
  filter(miRNA_name %in% all_mirnas) %>%
  group_by(miRNA_name, position, Group) %>%
  summarise(Mean_VAF = mean(VAF, na.rm = TRUE), .groups = "drop") %>%
  mutate(
    position = factor(position, levels = 1:22),
    miRNA_name = factor(miRNA_name, levels = all_mirnas)
  )

# Calcular estadísticas para subtítulo
stats_summary <- data_all %>%
  group_by(Group) %>%
  summarise(
    Mean_VAF = mean(Mean_VAF, na.rm = TRUE),
    Max_VAF = max(Mean_VAF, na.rm = TRUE),
    .groups = "drop"
  )

plot_all <- ggplot(data_all, aes(x = position, y = miRNA_name, fill = Mean_VAF)) +
  geom_tile(color = NA) +
  # Marcar región seed con líneas verticales
  geom_vline(xintercept = c(1.5, 8.5), color = COLOR_SEED_MARK, 
             linewidth = 1.2, linetype = "dashed", alpha = 0.7) +
  facet_wrap(~Group, ncol = 2) +
  scale_fill_gradient(
    low = "white", 
    high = COLOR_ALS,
    name = "Mean VAF",
    limits = c(0, max(data_all$Mean_VAF, na.rm = TRUE)),
    labels = function(x) sprintf("%.4f", x)
  ) +
  labs(
    title = "G>T Distribution Across Positions: All miRNAs",
    subtitle = paste0("All ", length(all_mirnas), " miRNAs with G>T in seed region | ",
                     "Seed region (positions 2-8) marked with dashed lines"),
    x = "Position in miRNA",
    y = paste0("miRNAs (n=", length(all_mirnas), ", ranked by G>T burden)")
  ) +
  theme_prof +
  theme(
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank()
  ) +
  # Anotación de seed region
  annotate("text", x = 5, y = length(all_mirnas) * 0.95, 
           label = "SEED", color = COLOR_SEED_MARK, 
           fontface = "bold", size = 5, alpha = 0.8)

ggsave("figures_paso2_CLEAN/FIG_2.4A_HEATMAP_ALL_PROFESSIONAL.png", 
       plot_all, width = 14, height = 14, dpi = 300, bg = "white")

cat("   ✅ FIG_2.4A saved (ALL 301 miRNAs - PROFESSIONAL)\n\n")

# ============================================================================
# OPCIÓN D: SUMMARY AGREGADO (PROFESSIONAL)
# ============================================================================

cat("🎨 [2/2] Generating Summary heatmap (professional)...\n")

# Calcular promedio por posición y grupo (TODOS)
summary_data <- vaf_gt_all %>%
  filter(miRNA_name %in% all_mirnas) %>%
  group_by(position, Group) %>%
  summarise(Mean_VAF = mean(VAF, na.rm = TRUE), .groups = "drop") %>%
  mutate(position = factor(position, levels = 1:22))

# Calcular estadísticas globales
global_stats <- summary_data %>%
  group_by(Group) %>%
  summarise(
    Overall_Mean = mean(Mean_VAF, na.rm = TRUE),
    Seed_Mean = mean(Mean_VAF[as.numeric(as.character(position)) >= 2 & 
                               as.numeric(as.character(position)) <= 8], na.rm = TRUE),
    NonSeed_Mean = mean(Mean_VAF[as.numeric(as.character(position)) < 2 | 
                                  as.numeric(as.character(position)) > 8], na.rm = TRUE),
    .groups = "drop"
  )

cat("\n📊 GLOBAL STATISTICS:\n")
print(global_stats)
cat("\n")

# Test seed vs no-seed
seed_vals_als <- summary_data %>% 
  filter(Group == "ALS", as.numeric(as.character(position)) >= 2, 
         as.numeric(as.character(position)) <= 8) %>% 
  pull(Mean_VAF)

nonseed_vals_als <- summary_data %>% 
  filter(Group == "ALS", as.numeric(as.character(position)) < 2 | 
         as.numeric(as.character(position)) > 8) %>% 
  pull(Mean_VAF)

test_seed_nonseed <- wilcox.test(seed_vals_als, nonseed_vals_als)

plot_summary <- ggplot(summary_data, aes(x = position, y = Group, fill = Mean_VAF)) +
  geom_tile(color = "white", linewidth = 1) +
  geom_text(aes(label = sprintf("%.5f", Mean_VAF)), 
            size = 3, color = "gray20", fontface = "bold") +
  # Marcar región seed
  annotate("rect", xmin = 1.5, xmax = 8.5, ymin = 0.5, ymax = 2.5,
           fill = NA, color = COLOR_SEED_MARK, linewidth = 1.5, linetype = "solid") +
  annotate("text", x = 5, y = 2.65, label = "SEED REGION (2-8)", 
           color = COLOR_SEED_MARK, fontface = "bold", size = 5) +
  scale_fill_gradient2(
    low = "white",
    mid = "#FFA07A",
    high = COLOR_ALS,
    midpoint = max(summary_data$Mean_VAF) * 0.4,
    name = "Mean VAF",
    labels = function(x) sprintf("%.5f", x)
  ) +
  scale_y_discrete(expand = c(0.15, 0.15)) +
  labs(
    title = "Positional Distribution of G>T Mutations",
    subtitle = paste0("Average across all ", length(all_mirnas), 
                     " miRNAs with G>T in seed region | ",
                     "Seed vs Non-seed p = ", format.pval(test_seed_nonseed$p.value, digits = 3)),
    x = "Position in miRNA",
    y = NULL
  ) +
  theme_prof +
  theme(
    axis.text.y = element_text(face = "bold", size = 14, color = "gray20"),
    legend.key.height = unit(1.5, "cm"),
    legend.key.width = unit(0.6, "cm")
  )

ggsave("figures_paso2_CLEAN/FIG_2.4B_HEATMAP_SUMMARY_PROFESSIONAL.png", 
       plot_summary, width = 15, height = 6, dpi = 300, bg = "white")

cat("   ✅ FIG_2.4B saved (SUMMARY - PROFESSIONAL)\n\n")

# ============================================================================
# ANÁLISIS ADICIONAL
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("📊 POSITIONAL ANALYSIS:\n")
cat("\n")

# Encontrar posición con mayor VAF
max_pos_als <- summary_data %>% filter(Group == "ALS") %>% arrange(desc(Mean_VAF)) %>% head(1)
max_pos_ctrl <- summary_data %>% filter(Group == "Control") %>% arrange(desc(Mean_VAF)) %>% head(1)

cat("HIGHEST VAF POSITIONS:\n")
cat("   ALS: Position", max_pos_als$position, "= VAF", round(max_pos_als$Mean_VAF, 6), "\n")
cat("   Control: Position", max_pos_ctrl$position, "= VAF", round(max_pos_ctrl$Mean_VAF, 6), "\n\n")

# Comparar seed vs non-seed
cat("SEED vs NON-SEED COMPARISON:\n")
print(global_stats %>% select(Group, Seed_Mean, NonSeed_Mean))
cat("\n")

cat("   Seed vs Non-seed test (ALS): p =", format.pval(test_seed_nonseed$p.value, digits = 3), "\n\n")

# Ratio seed/non-seed
ratio_als <- global_stats$Seed_Mean[global_stats$Group == "ALS"] / 
             global_stats$NonSeed_Mean[global_stats$Group == "ALS"]
ratio_ctrl <- global_stats$Seed_Mean[global_stats$Group == "Control"] / 
              global_stats$NonSeed_Mean[global_stats$Group == "Control"]

cat("SEED ENRICHMENT (Seed/Non-seed ratio):\n")
cat("   ALS:", round(ratio_als, 2), "x\n")
cat("   Control:", round(ratio_ctrl, 2), "x\n\n")

if (ratio_als > 1 & ratio_ctrl > 1) {
  cat("   ✅ SEED ENRICHED in both groups\n")
} else {
  cat("   ⚠️  No clear seed enrichment\n")
}

cat("\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("✅ TWO PROFESSIONAL FIGURES GENERATED:\n")
cat("\n")
cat("   FIG_2.4A_HEATMAP_ALL_PROFESSIONAL.png\n")
cat("      → All 301 miRNAs (complete pattern)\n")
cat("      → No labels (too many for readability)\n")
cat("      → Seed region marked with dashed lines\n")
cat("      → Professional color scheme\n")
cat("      → English labels\n\n")

cat("   FIG_2.4B_HEATMAP_SUMMARY_PROFESSIONAL.png ⭐\n")
cat("      → Summary of ALL 301 miRNAs\n")
cat("      → 2 rows (ALS and Control)\n")
cat("      → Numeric values shown\n")
cat("      → Seed region highlighted (blue box)\n")
cat("      → Statistical test included\n")
cat("      → Professional color scheme\n")
cat("      → English labels\n\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")

