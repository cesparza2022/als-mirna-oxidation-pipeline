# 🎯 FIGURA 1.5 - ANÁLISIS PRELIMINARES EXTRAS
# SNVs por miRNAs, GT en muestras, cuentas detalladas, estadísticas avanzadas

rm(list = ls())

library(ggplot2)
library(dplyr)
library(tidyr)
library(stringr)
library(patchwork)
library(readr)
library(purrr)
library(scales)
# library(knitr)  # Not needed for CSV tables
# library(kableExtra)  # Not available, using CSV instead

source("config/config_pipeline_2.R")

cat("\n🎯 FIGURA 1.5 - ANÁLISIS PRELIMINARES EXTRAS\n")
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
# PANEL A: SNVs por miRNA - TOP 25 con ESTADÍSTICAS
# ═══════════════════════════════════════════════════════════════════
cat("🎯 Panel A: SNVs por miRNA - TOP 25 con ESTADÍSTICAS...\n")

snv_per_mirna_detailed <- processed_data %>%
  count(`miRNA name`, name = "total_snv_count") %>%
  arrange(desc(total_snv_count)) %>%
  head(25) %>%
  mutate(
    `miRNA name` = factor(`miRNA name`, levels = rev(`miRNA name`)),
    percentage = total_snv_count / sum(total_snv_count) * 100,
    rank = row_number()
  )

# Calculate statistics
total_snv_all <- sum(snv_per_mirna_detailed$total_snv_count)
mean_snv_per_mirna <- mean(snv_per_mirna_detailed$total_snv_count)
sd_snv_per_mirna <- sd(snv_per_mirna_detailed$total_snv_count)
top_10_contribution <- sum(snv_per_mirna_detailed$total_snv_count[1:10]) / total_snv_all * 100
total_all_mirnas <- processed_data %>% count(`miRNA name`) %>% nrow()
top_25_contribution <- nrow(snv_per_mirna_detailed) / total_all_mirnas * 100

panel_a <- ggplot(snv_per_mirna_detailed, aes(x = `miRNA name`, y = total_snv_count)) +
  geom_col(fill = "steelblue", alpha = 0.8, width = 0.7) +
  geom_text(aes(label = paste0(format(total_snv_count, big.mark=","), 
                               " (", sprintf("%.1f%%", percentage), ")")),
            hjust = -0.1, size = 3.2, fontface = "bold") +
  labs(
    title = "A. SNV COUNT per miRNA - TOP 25 (DETAILED)",
    subtitle = sprintf("Total SNVs: %s | Mean±SD: %.0f±%.0f | Top 10: %.1f%% | Top 25: %.1f%% of all miRNAs",
                       format(total_snv_all, big.mark=","),
                       mean_snv_per_mirna, sd_snv_per_mirna,
                       top_10_contribution, top_25_contribution),
    x = NULL,
    y = "Count of ALL SNVs"
  ) +
  coord_flip() +
  professional_theme +
  theme(plot.title = element_text(size = 13, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 9, hjust = 0.5, color = "gray50"),
        panel.grid.major.y = element_blank())

ggsave(file.path(figures_dir, "panel_a_snv_per_mirna_detailed_1_5.png"), 
       plot = panel_a, width = 12, height = 10, dpi = 300, bg = "white")
cat("✅ Panel A COMPLETE (SNV per miRNA TOP 25)\n\n")

# ═══════════════════════════════════════════════════════════════════
# PANEL B: G>T SNVs por miRNA - TOP 20 con ESTADÍSTICAS
# ═══════════════════════════════════════════════════════════════════
cat("🎯 Panel B: G>T SNVs por miRNA - TOP 20...\n")

gt_per_mirna_detailed <- processed_data %>%
  filter(mutation_type == "G>T") %>%
  count(`miRNA name`, name = "gt_count") %>%
  arrange(desc(gt_count)) %>%
  head(20) %>%
  mutate(
    `miRNA name` = factor(`miRNA name`, levels = rev(`miRNA name`)),
    percentage = gt_count / sum(gt_count) * 100,
    rank = row_number()
  )

# Calculate statistics
total_gt_all <- sum(gt_per_mirna_detailed$gt_count)
mean_gt_per_mirna <- mean(gt_per_mirna_detailed$gt_count)
sd_gt_per_mirna <- sd(gt_per_mirna_detailed$gt_count)
top_5_gt_contribution <- sum(gt_per_mirna_detailed$gt_count[1:5]) / total_gt_all * 100
top_10_gt_contribution <- sum(gt_per_mirna_detailed$gt_count[1:10]) / total_gt_all * 100

panel_b <- ggplot(gt_per_mirna_detailed, aes(x = `miRNA name`, y = gt_count)) +
  geom_col(fill = COLOR_GT, alpha = 0.8, width = 0.7) +
  geom_text(aes(label = paste0(format(gt_count, big.mark=","), 
                               " (", sprintf("%.1f%%", percentage), ")")),
            hjust = -0.1, size = 3.2, fontface = "bold") +
  labs(
    title = "B. G>T SNV COUNT per miRNA - TOP 20",
    subtitle = sprintf("Total G>T: %s | Mean±SD: %.0f±%.0f | Top 5: %.1f%% | Top 10: %.1f%%",
                       format(total_gt_all, big.mark=","),
                       mean_gt_per_mirna, sd_gt_per_mirna,
                       top_5_gt_contribution, top_10_gt_contribution),
    x = NULL,
    y = "Count of G>T SNVs"
  ) +
  coord_flip() +
  professional_theme +
  theme(plot.title = element_text(size = 13, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 9, hjust = 0.5, color = "gray50"),
        panel.grid.major.y = element_blank())

ggsave(file.path(figures_dir, "panel_b_gt_per_mirna_detailed_1_5.png"), 
       plot = panel_b, width = 12, height = 8, dpi = 300, bg = "white")
cat("✅ Panel B COMPLETE (G>T per miRNA TOP 20)\n\n")

# ═══════════════════════════════════════════════════════════════════
# PANEL C: G>T en muestras - DISTRIBUCIÓN por muestra
# ═══════════════════════════════════════════════════════════════════
cat("🎯 Panel C: G>T en muestras - DISTRIBUCIÓN...\n")

# Get sample columns (excluding metadata)
sample_cols <- names(raw_data)[!names(raw_data) %in% c("miRNA name", "pos:mut")]

# Calculate G>T count per sample using processed data
gt_per_sample <- processed_data %>%
  filter(mutation_type == "G>T") %>%
  select(`miRNA name`, position, all_of(sample_cols)) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "sample", values_to = "count") %>%
  filter(!is.na(count), count > 0) %>%
  group_by(sample) %>%
  summarise(gt_total = sum(count, na.rm = TRUE), .groups = "drop") %>%
  arrange(desc(gt_total))

# Calculate statistics
total_samples <- nrow(gt_per_sample)
mean_gt_per_sample <- mean(gt_per_sample$gt_total)
sd_gt_per_sample <- sd(gt_per_sample$gt_total)
median_gt_per_sample <- median(gt_per_sample$gt_total)
max_gt_sample <- max(gt_per_sample$gt_total)
samples_with_gt <- sum(gt_per_sample$gt_total > 0)

# Top 15 samples with most G>T
top_samples_gt <- gt_per_sample %>%
  head(15) %>%
  mutate(
    sample = factor(sample, levels = rev(sample)),
    percentage = gt_total / sum(gt_total) * 100
  )

panel_c <- ggplot(top_samples_gt, aes(x = sample, y = gt_total)) +
  geom_col(fill = COLOR_GT, alpha = 0.8, width = 0.7) +
  geom_text(aes(label = paste0(format(gt_total, big.mark=","), 
                               " (", sprintf("%.1f%%", percentage), ")")),
            hjust = -0.1, size = 3.2, fontface = "bold") +
  labs(
    title = "C. G>T SNV COUNT per Sample - TOP 15",
    subtitle = sprintf("Samples with G>T: %d/%d (%.1f%%) | Mean±SD: %.0f±%.0f | Median: %.0f | Max: %s",
                       samples_with_gt, total_samples, samples_with_gt/total_samples*100,
                       mean_gt_per_sample, sd_gt_per_sample, median_gt_per_sample,
                       format(max_gt_sample, big.mark=",")),
    x = NULL,
    y = "Count of G>T SNVs"
  ) +
  coord_flip() +
  professional_theme +
  theme(plot.title = element_text(size = 13, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 9, hjust = 0.5, color = "gray50"),
        panel.grid.major.y = element_blank())

ggsave(file.path(figures_dir, "panel_c_gt_per_sample_detailed_1_5.png"), 
       plot = panel_c, width = 12, height = 8, dpi = 300, bg = "white")
cat("✅ Panel C COMPLETE (G>T per sample TOP 15)\n\n")

# ═══════════════════════════════════════════════════════════════════
# PANEL D: Cuentas por posición - TODAS las mutaciones vs G>T
# ═══════════════════════════════════════════════════════════════════
cat("🎯 Panel D: Cuentas por posición - TODAS vs G>T...\n")

all_by_position_detailed <- processed_data %>%
  count(position, name = "total_snv_count") %>%
  mutate(position_label = factor(position, levels = 1:22))

gt_by_position_detailed <- processed_data %>%
  filter(mutation_type == "G>T") %>%
  count(position, name = "gt_count") %>%
  mutate(position_label = factor(position, levels = 1:22))

# Merge data
position_comparison <- all_by_position_detailed %>%
  left_join(gt_by_position_detailed, by = c("position", "position_label")) %>%
  replace_na(list(gt_count = 0)) %>%
  mutate(
    gt_percentage = gt_count / total_snv_count * 100,
    region = ifelse(position >= 2 & position <= 8, "Seed", "Non-Seed")
  ) %>%
  pivot_longer(cols = c(total_snv_count, gt_count), 
               names_to = "mutation_type", 
               values_to = "count") %>%
  mutate(
    mutation_type = ifelse(mutation_type == "total_snv_count", "All SNVs", "G>T only"),
    mutation_type = factor(mutation_type, levels = c("All SNVs", "G>T only"))
  )

# Calculate statistics
seed_all <- sum(position_comparison$count[position_comparison$region == "Seed" & position_comparison$mutation_type == "All SNVs"])
seed_gt <- sum(position_comparison$count[position_comparison$region == "Seed" & position_comparison$mutation_type == "G>T only"])
seed_gt_percentage <- seed_gt / seed_all * 100

panel_d <- ggplot(position_comparison, aes(x = position_label, y = count, fill = mutation_type)) +
  geom_col(position = "dodge", alpha = 0.8, width = 0.7) +
  scale_fill_manual(values = c("All SNVs" = "steelblue", "G>T only" = COLOR_GT), name = "Mutation Type") +
  labs(
    title = "D. SNV COUNT by Position - ALL vs G>T",
    subtitle = sprintf("Seed region: %s total SNVs, %s G>T (%.1f%%) | Shows position-specific G>T contribution",
                       format(seed_all, big.mark=","), format(seed_gt, big.mark=","), seed_gt_percentage),
    x = "Position in miRNA",
    y = "Count of SNVs"
  ) +
  professional_theme +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        plot.title = element_text(size = 13, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 9, hjust = 0.5, color = "gray50"))

ggsave(file.path(figures_dir, "panel_d_position_comparison_detailed_1_5.png"), 
       plot = panel_d, width = 12, height = 6, dpi = 300, bg = "white")
cat("✅ Panel D COMPLETE (Position comparison ALL vs G>T)\n\n")

# ═══════════════════════════════════════════════════════════════════
# GENERAR TABLAS DETALLADAS
# ═══════════════════════════════════════════════════════════════════
cat("📊 Generando TABLAS DETALLADAS...\n")

# Tabla 1: Top 25 miRNAs con más SNVs
tabla_top_mirnas <- snv_per_mirna_detailed %>%
  select(rank, `miRNA name`, total_snv_count, percentage) %>%
  mutate(
    percentage = round(percentage, 2),
    total_snv_count = format(total_snv_count, big.mark = ",")
  ) %>%
  rename(
    Rank = rank,
    miRNA = `miRNA name`,
    `Total SNVs` = total_snv_count,
    `Percentage (%)` = percentage
  )

write_csv(tabla_top_mirnas, file.path(figures_dir, "tabla_top_25_mirnas_snv_1_5.csv"))
cat("✅ Tabla 1: Top 25 miRNAs con más SNVs\n")

# Tabla 2: Top 20 miRNAs con más G>T
tabla_top_gt <- gt_per_mirna_detailed %>%
  select(rank, `miRNA name`, gt_count, percentage) %>%
  mutate(
    percentage = round(percentage, 2),
    gt_count = format(gt_count, big.mark = ",")
  ) %>%
  rename(
    Rank = rank,
    miRNA = `miRNA name`,
    `G>T Count` = gt_count,
    `Percentage (%)` = percentage
  )

write_csv(tabla_top_gt, file.path(figures_dir, "tabla_top_20_mirnas_gt_1_5.csv"))
cat("✅ Tabla 2: Top 20 miRNAs con más G>T\n")

# Tabla 3: Top 15 muestras con más G>T
tabla_top_samples <- top_samples_gt %>%
  select(sample, gt_total, percentage) %>%
  mutate(
    percentage = round(percentage, 2),
    gt_total = format(gt_total, big.mark = ",")
  ) %>%
  rename(
    Sample = sample,
    `G>T Count` = gt_total,
    `Percentage (%)` = percentage
  )

write_csv(tabla_top_samples, file.path(figures_dir, "tabla_top_15_samples_gt_1_5.csv"))
cat("✅ Tabla 3: Top 15 muestras con más G>T\n")

# Tabla 4: Estadísticas por posición
tabla_posicion_stats <- position_comparison %>%
  filter(mutation_type == "All SNVs") %>%
  left_join(
    position_comparison %>%
      filter(mutation_type == "G>T only") %>%
      select(position, count),
    by = "position",
    suffix = c("_all", "_gt")
  ) %>%
  select(position, count_all, count_gt) %>%
  mutate(
    gt_percentage = round(count_gt / count_all * 100, 2),
    count_all = format(count_all, big.mark = ","),
    count_gt = format(count_gt, big.mark = ","),
    region = ifelse(position >= 2 & position <= 8, "Seed", "Non-Seed")
  ) %>%
  rename(
    Position = position,
    `Total SNVs` = count_all,
    `G>T Count` = count_gt,
    `G>T %` = gt_percentage,
    Region = region
  )

write_csv(tabla_posicion_stats, file.path(figures_dir, "tabla_position_stats_1_5.csv"))
cat("✅ Tabla 4: Estadísticas por posición\n\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("  🎉 FIGURA 1.5 COMPLETE - ANÁLISIS PRELIMINARES\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

cat("📁 OUTPUTS FIGURA 1.5:\n")
cat("   • panel_a_snv_per_mirna_detailed_1_5.png\n")
cat("   • panel_b_gt_per_mirna_detailed_1_5.png\n")
cat("   • panel_c_gt_per_sample_detailed_1_5.png\n")
cat("   • panel_d_position_comparison_detailed_1_5.png\n\n")

cat("📊 TABLAS GENERADAS:\n")
cat("   • tabla_top_25_mirnas_snv_1_5.csv\n")
cat("   • tabla_top_20_mirnas_gt_1_5.csv\n")
cat("   • tabla_top_15_samples_gt_1_5.csv\n")
cat("   • tabla_position_stats_1_5.csv\n\n")

cat("🎯 ANÁLISIS INCLUIDOS:\n")
cat("   ✅ SNVs por miRNA (TOP 25) con estadísticas\n")
cat("   ✅ G>T SNVs por miRNA (TOP 20) con estadísticas\n")
cat("   ✅ G>T en muestras (TOP 15) con distribución\n")
cat("   ✅ Comparación ALL vs G>T por posición\n")
cat("   ✅ 4 tablas detalladas con estadísticas\n")
cat("   ✅ Mean, SD, median, percentages en todo\n\n")
