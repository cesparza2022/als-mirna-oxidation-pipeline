# 🎨 FIGURA 1 COMPLETE - COMBINANDO LO MEJOR DE AMBAS VERSIONES
# Cuentas + Estadísticas + Tendencias + Paneles importantes de versiones anteriores

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

cat("\n🎨 FIGURA 1 COMPLETE - CUENTAS + ESTADÍSTICAS + TENDENCIAS\n")
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
# PANEL A: Dataset Evolution & Mutation Type COUNTS (CON ESTADÍSTICAS)
# ═══════════════════════════════════════════════════════════════════
cat("🎨 Panel A: Dataset evolution + mutation COUNTS + STATISTICS...\n")

# Dataset evolution with statistics
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

# Mutation types with STATISTICS
mutation_types_data <- processed_data %>%
  count(mutation_type) %>%
  mutate(
    fraction = n / sum(n),
    percentage = fraction * 100
  ) %>%
  arrange(desc(n)) %>%
  head(10) %>%
  mutate(
    mutation_type_ordered = factor(mutation_type, levels = rev(mutation_type))
  )

# Calculate statistics
total_snvs <- sum(mutation_types_data$n)
gt_count <- mutation_types_data$n[mutation_types_data$mutation_type == "G>T"]
gt_percentage <- mutation_types_data$percentage[mutation_types_data$mutation_type == "G>T"]

p_mutation_types <- ggplot(mutation_types_data, aes(x = mutation_type_ordered, y = n)) +
  geom_col(aes(fill = mutation_type), alpha = 0.8, width = 0.7) +
  geom_text(aes(label = paste0(format(n, big.mark=","), "\n(", sprintf("%.1f%%", percentage), ")")),
            hjust = -0.1, size = 3.5, fontface = "bold") +
  scale_fill_manual(values = c("G>T" = COLOR_GT,  # ROJO para G>T
                               "T>C" = "grey60", "A>G" = "grey60", "G>A" = "grey60", 
                               "C>T" = "grey60", "T>A" = "grey60", "T>G" = "grey60", 
                               "A>T" = "grey60", "C>A" = "grey60", "C>G" = "grey60", 
                               "G>C" = "grey60", "A>C" = "grey60"),
                    guide = "none") +
  scale_y_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.2))) +
  labs(title = "Mutation Types - COUNTS & STATISTICS", 
       subtitle = sprintf("Total SNVs: %s | G>T: %s (%.1f%%)", 
                          format(total_snvs, big.mark=","),
                          format(gt_count, big.mark=","),
                          gt_percentage),
       x = NULL, 
       y = "Count of SNVs") +
  coord_flip() +
  professional_theme +
  theme(plot.title = element_text(face = "bold", hjust = 0.5, size = 12),
        plot.subtitle = element_text(size = 9, hjust = 0.5, color = "gray50"),
        axis.text.y = element_text(size = 10, face = "bold"),
        panel.grid.major.y = element_blank())

panel_a <- (p_evolution + p_mutation_types) +
  plot_annotation(title = "A. Dataset Overview & SNV Counts by Mutation Type",
                  theme = theme(plot.title = element_text(size = 14, face = "bold", hjust = 0.5)))
ggsave(file.path(figures_dir, "panel_a_overview_COMPLETE.png"), plot = panel_a, width = 12, height = 6, dpi = 300, bg = "white")
cat("✅ Panel A COMPLETE (COUNTS + STATISTICS)\n\n")

# ═══════════════════════════════════════════════════════════════════
# PANEL B: G>T COUNT by Position + STATISTICS
# ═══════════════════════════════════════════════════════════════════
cat("🎨 Panel B: G>T COUNT by position + STATISTICS...\n")

gt_by_position <- processed_data %>%
  filter(mutation_type == "G>T") %>%
  count(position, name = "gt_count") %>%
  mutate(
    position_label = factor(position, levels = 1:22),
    region = ifelse(position >= 2 & position <= 8, "Seed", "Non-Seed")
  )

# Calculate statistics
seed_gt <- sum(gt_by_position$gt_count[gt_by_position$region == "Seed"])
nonseed_gt <- sum(gt_by_position$gt_count[gt_by_position$region == "Non-Seed"])
total_gt <- sum(gt_by_position$gt_count)
max_pos <- gt_by_position$position[which.max(gt_by_position$gt_count)]
max_count <- max(gt_by_position$gt_count)

panel_b <- ggplot(gt_by_position, aes(x = position_label, y = gt_count)) +
  geom_col(aes(fill = region), alpha = 0.8, width = 0.7) +
  geom_text(aes(label = gt_count), vjust = -0.3, size = 3.5, fontface = "bold") +
  scale_fill_manual(values = c("Seed" = "#FFD700", "Non-Seed" = "grey60"), name = "Region") +
  labs(
    title = "B. G>T Mutation COUNT by Position",
    subtitle = sprintf("Total G>T: %s | Seed: %s (%.1f%%) | Non-Seed: %s (%.1f%%) | Peak: Pos %d (%s)",
                       format(total_gt, big.mark=","),
                       format(seed_gt, big.mark=","), seed_gt/total_gt*100,
                       format(nonseed_gt, big.mark=","), nonseed_gt/total_gt*100,
                       max_pos, format(max_count, big.mark=",")),
    x = "Position in miRNA",
    y = "Count of G>T mutations"
  ) +
  professional_theme +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        plot.title = element_text(size = 13, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 9, hjust = 0.5, color = "gray50"))

ggsave(file.path(figures_dir, "panel_b_gt_count_by_position_COMPLETE.png"), 
       plot = panel_b, width = 12, height = 6, dpi = 300, bg = "white")
cat("✅ Panel B COMPLETE (COUNT + STATISTICS)\n\n")

# ═══════════════════════════════════════════════════════════════════
# PANEL C: G>X Spectrum (RESTAURADO de versión anterior)
# ═══════════════════════════════════════════════════════════════════
cat("🎨 Panel C: G>X Spectrum (RESTAURADO)...\n")

gx_spectrum_data <- processed_data %>%
  filter(str_detect(mutation_type, "^G>")) %>%
  count(position, mutation_type) %>%
  group_by(position) %>%
  mutate(
    percentage = n / sum(n) * 100,
    total_gx_at_pos = sum(n)
  ) %>%
  ungroup() %>%
  mutate(
    position_label = factor(position, levels = 1:22),
    mutation_type = factor(mutation_type, levels = c("G>C", "G>A", "G>T"))
  )

# Calculate statistics
gt_percentage_overall <- sum(gx_spectrum_data$n[gx_spectrum_data$mutation_type == "G>T"]) / sum(gx_spectrum_data$n) * 100
seed_gt_percentage <- gx_spectrum_data %>%
  filter(position >= 2 & position <= 8, mutation_type == "G>T") %>%
  summarise(percentage = sum(n) / sum(gx_spectrum_data$n[gx_spectrum_data$position >= 2 & gx_spectrum_data$position <= 8]) * 100) %>%
  pull(percentage)

panel_c <- ggplot(gx_spectrum_data, aes(x = position_label, y = percentage, fill = mutation_type)) +
  geom_col(position = "stack", color = "white", linewidth = 0.3) +
  scale_fill_manual(values = c("G>T" = COLOR_GT,  # ROJO
                               "G>A" = "grey60", 
                               "G>C" = "grey40"), 
                    name = "Mutation Type") +
  labs(
    title = "C. G>X Mutation Spectrum by Position",
    subtitle = sprintf("G>T represents %.1f%% of all G>X | Seed region G>T: %.1f%%",
                       gt_percentage_overall, seed_gt_percentage),
    x = "Position in miRNA",
    y = "Percentage of G>X mutations (%)"
  ) +
  professional_theme +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        plot.title = element_text(size = 13, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 9, hjust = 0.5, color = "gray50"))

ggsave(file.path(figures_dir, "panel_c_spectrum_COMPLETE.png"), 
       plot = panel_c, width = 12, height = 6, dpi = 300, bg = "white")
cat("✅ Panel C COMPLETE (G>X SPECTRUM RESTORED)\n\n")

# ═══════════════════════════════════════════════════════════════════
# PANEL D: Top miRNAs with G>T (RESTAURADO + STATISTICS)
# ═══════════════════════════════════════════════════════════════════
cat("🎨 Panel D: Top miRNAs with G>T (RESTAURADO + STATISTICS)...\n")

top_mirnas_gt <- processed_data %>%
  filter(mutation_type == "G>T") %>%
  count(`miRNA name`, name = "gt_count") %>%
  arrange(desc(gt_count)) %>%
  head(15) %>%
  mutate(
    `miRNA name` = factor(`miRNA name`, levels = rev(`miRNA name`)),
    percentage = gt_count / sum(gt_count) * 100
  )

# Calculate statistics
total_gt_mutations <- sum(top_mirnas_gt$gt_count)
top_5_contribution <- sum(top_mirnas_gt$gt_count[1:5]) / total_gt_mutations * 100
top_mirna <- top_mirnas_gt$`miRNA name`[1]
top_count <- top_mirnas_gt$gt_count[1]

panel_d <- ggplot(top_mirnas_gt, aes(x = `miRNA name`, y = gt_count)) +
  geom_col(fill = COLOR_GT, alpha = 0.8, width = 0.7) +
  geom_text(aes(label = paste0(gt_count, " (", sprintf("%.1f%%", percentage), ")")),
            hjust = -0.1, size = 3.5, fontface = "bold") +
  labs(
    title = "D. Top 15 miRNAs with G>T Mutations",
    subtitle = sprintf("Total G>T: %s | Top miRNA: %s (%s) | Top 5 contribute %.1f%%",
                       format(total_gt_mutations, big.mark=","),
                       as.character(top_mirna), format(top_count, big.mark=","),
                       top_5_contribution),
    x = NULL,
    y = "Count of G>T mutations"
  ) +
  coord_flip() +
  professional_theme +
  theme(plot.title = element_text(size = 13, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 9, hjust = 0.5, color = "gray50"),
        panel.grid.major.y = element_blank())

ggsave(file.path(figures_dir, "panel_d_top_mirnas_gt_COMPLETE.png"), 
       plot = panel_d, width = 12, height = 7, dpi = 300, bg = "white")
cat("✅ Panel D COMPLETE (TOP miRNAs G>T RESTORED)\n\n")

# ═══════════════════════════════════════════════════════════════════
# PANEL E: Total SNV COUNT by Position (NUEVO - COMPLEMENTARIO)
# ═══════════════════════════════════════════════════════════════════
cat("🎨 Panel E: Total SNV COUNT by position (NUEVO)...\n")

all_by_position <- processed_data %>%
  count(position, name = "total_snv_count") %>%
  mutate(
    position_label = factor(position, levels = 1:22),
    region = ifelse(position >= 2 & position <= 8, "Seed", "Non-Seed")
  )

# Calculate statistics
seed_snv <- sum(all_by_position$total_snv_count[all_by_position$region == "Seed"])
nonseed_snv <- sum(all_by_position$total_snv_count[all_by_position$region == "Non-Seed"])
total_snv <- sum(all_by_position$total_snv_count)
mean_per_pos <- mean(all_by_position$total_snv_count)
sd_per_pos <- sd(all_by_position$total_snv_count)

panel_e <- ggplot(all_by_position, aes(x = position_label, y = total_snv_count)) +
  geom_col(aes(fill = region), alpha = 0.8, width = 0.7) +
  geom_text(aes(label = format(total_snv_count, big.mark=",")), 
            vjust = -0.3, size = 3.5, fontface = "bold") +
  scale_fill_manual(values = c("Seed" = "#FFD700", "Non-Seed" = "grey60"), name = "Region") +
  labs(
    title = "E. Total SNV COUNT by Position",
    subtitle = sprintf("Total SNVs: %s | Seed: %s (%.1f%%) | Non-Seed: %s (%.1f%%) | Mean±SD: %.0f±%.0f",
                       format(total_snv, big.mark=","),
                       format(seed_snv, big.mark=","), seed_snv/total_snv*100,
                       format(nonseed_snv, big.mark=","), nonseed_snv/total_snv*100,
                       mean_per_pos, sd_per_pos),
    x = "Position in miRNA",
    y = "Count of ALL SNVs"
  ) +
  professional_theme +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        plot.title = element_text(size = 13, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 9, hjust = 0.5, color = "gray50"))

ggsave(file.path(figures_dir, "panel_e_total_snv_by_position_COMPLETE.png"), 
       plot = panel_e, width = 12, height = 6, dpi = 300, bg = "white")
cat("✅ Panel E COMPLETE (TOTAL SNV COUNT)\n\n")

# ═══════════════════════════════════════════════════════════════════
# PANEL F: SNV Count per miRNA (Top 20) - ALL mutations
# ═══════════════════════════════════════════════════════════════════
cat("🎨 Panel F: SNV COUNT per miRNA (ALL mutations)...\n")

snv_per_mirna <- processed_data %>%
  count(`miRNA name`, name = "total_snv_count") %>%
  arrange(desc(total_snv_count)) %>%
  head(20) %>%
  mutate(
    `miRNA name` = factor(`miRNA name`, levels = rev(`miRNA name`)),
    percentage = total_snv_count / sum(total_snv_count) * 100
  )

# Calculate statistics
total_snv_all <- sum(snv_per_mirna$total_snv_count)
mean_snv_per_mirna <- mean(snv_per_mirna$total_snv_count)
sd_snv_per_mirna <- sd(snv_per_mirna$total_snv_count)
top_10_contribution <- sum(snv_per_mirna$total_snv_count[1:10]) / total_snv_all * 100

panel_f <- ggplot(snv_per_mirna, aes(x = `miRNA name`, y = total_snv_count)) +
  geom_col(fill = "steelblue", alpha = 0.8, width = 0.7) +
  geom_text(aes(label = paste0(format(total_snv_count, big.mark=","), 
                               " (", sprintf("%.1f%%", percentage), ")")),
            hjust = -0.1, size = 3.5, fontface = "bold") +
  labs(
    title = "F. Total SNV COUNT per miRNA (Top 20)",
    subtitle = sprintf("Total SNVs: %s | Mean±SD: %.0f±%.0f | Top 10 contribute %.1f%%",
                       format(total_snv_all, big.mark=","),
                       mean_snv_per_mirna, sd_snv_per_mirna,
                       top_10_contribution),
    x = NULL,
    y = "Count of ALL SNVs"
  ) +
  coord_flip() +
  professional_theme +
  theme(plot.title = element_text(size = 13, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 9, hjust = 0.5, color = "gray50"),
        panel.grid.major.y = element_blank())

ggsave(file.path(figures_dir, "panel_f_snv_per_mirna_COMPLETE.png"), 
       plot = panel_f, width = 12, height = 8, dpi = 300, bg = "white")
cat("✅ Panel F COMPLETE (SNV COUNT per miRNA)\n\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("  🎉 FIGURA 1 COMPLETE - COMPLETE\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

cat("📁 OUTPUTS COMPLETE:\n")
cat("   • panel_a_overview_COMPLETE.png (COUNTS + STATISTICS)\n")
cat("   • panel_b_gt_count_by_position_COMPLETE.png (G>T COUNT + STATS)\n")
cat("   • panel_c_spectrum_COMPLETE.png (G>X SPECTRUM RESTORED)\n")
cat("   • panel_d_top_mirnas_gt_COMPLETE.png (TOP miRNAs G>T RESTORED)\n")
cat("   • panel_e_total_snv_by_position_COMPLETE.png (TOTAL SNV COUNT)\n")
cat("   • panel_f_snv_per_mirna_COMPLETE.png (SNV COUNT per miRNA)\n\n")

cat("🎨 COMPLETE FEATURES:\n")
cat("   ✅ Paneles importantes RESTAURADOS (C, D)\n")
cat("   ✅ Estadísticas en TODOS los paneles (mean, SD, percentages)\n")
cat("   ✅ Tendencias mostradas (peaks, contributions)\n")
cat("   ✅ Comparaciones (seed vs non-seed, top vs others)\n")
cat("   ✅ Números explícitos en todas las barras\n")
cat("   ✅ Subtítulos con estadísticas clave\n\n")

cat("📊 SHOWS TRENDS:\n")
cat("   • Which positions have most G>T mutations\n")
cat("   • Which miRNAs contribute most to total SNVs\n")
cat("   • Seed vs Non-Seed distribution patterns\n")
cat("   • G>X mutation spectrum by position\n")
cat("   • Statistical summaries (mean, SD, percentages)\n\n")

