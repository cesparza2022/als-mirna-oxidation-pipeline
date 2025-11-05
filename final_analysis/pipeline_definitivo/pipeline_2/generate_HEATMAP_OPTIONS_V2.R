#!/usr/bin/env Rscript
# ============================================================================
# GENERAR OPCIONES DE HEATMAP CON GGPLOT (más control)
# ============================================================================

library(ggplot2)
library(dplyr)
library(tidyr)
library(readr)
library(stringr)
library(patchwork)

COLOR_ALS <- "#D62728"
COLOR_CONTROL <- "#404040"

cat("\n🎨 Generando opciones de heatmap...\n\n")

# Cargar datos
data <- read_csv("final_processed_data_CLEAN.csv", show_col_types = FALSE)
metadata <- read_csv("metadata.csv", show_col_types = FALSE)
sample_cols <- metadata$Sample_ID

# Filtrar y rankear
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

# Preparar datos de TODOS los G>T (1-22)
vaf_gt_all <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^[0-9]+"))) %>%
  filter(!is.na(position), position <= 22) %>%
  select(all_of(c("miRNA_name", "position", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  left_join(metadata, by = "Sample_ID")

# ============================================================================
# OPCIÓN A: TOP 30
# ============================================================================

cat("📊 Opción A: Top 30...\n")

top30 <- head(seed_gt_summary, 30)$miRNA_name

data_top30 <- vaf_gt_all %>%
  filter(miRNA_name %in% top30) %>%
  group_by(miRNA_name, position, Group) %>%
  summarise(Mean_VAF = mean(VAF, na.rm = TRUE), .groups = "drop") %>%
  mutate(
    position = factor(position, levels = 1:22),
    miRNA_name = factor(miRNA_name, levels = top30)  # Mantener orden de ranking
  )

plot_a <- ggplot(data_top30, aes(x = position, y = miRNA_name, fill = Mean_VAF)) +
  geom_tile(color = "white", linewidth = 0.3) +
  facet_wrap(~Group, ncol = 2) +
  scale_fill_gradient(low = "white", high = COLOR_ALS, name = "Mean VAF") +
  labs(
    title = "Top 30 miRNAs: G>T VAF by Position",
    subtitle = "Ordered by total G>T burden",
    x = "Position in miRNA",
    y = "miRNA"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold", hjust = 0.5),
    axis.text.y = element_text(size = 8),
    axis.text.x = element_text(size = 9),
    strip.text = element_text(face = "bold", size = 12),
    panel.grid = element_blank()
  )

ggsave("figures_paso2_CLEAN/OPCION_A_HEATMAP_TOP30.png", plot_a, 
       width = 12, height = 10, dpi = 300, bg = "white")
cat("   ✅ Guardada\n\n")

# ============================================================================
# OPCIÓN B: TOP 50
# ============================================================================

cat("📊 Opción B: Top 50...\n")

top50 <- head(seed_gt_summary, 50)$miRNA_name

data_top50 <- vaf_gt_all %>%
  filter(miRNA_name %in% top50) %>%
  group_by(miRNA_name, position, Group) %>%
  summarise(Mean_VAF = mean(VAF, na.rm = TRUE), .groups = "drop") %>%
  mutate(
    position = factor(position, levels = 1:22),
    miRNA_name = factor(miRNA_name, levels = top50)
  )

plot_b <- ggplot(data_top50, aes(x = position, y = miRNA_name, fill = Mean_VAF)) +
  geom_tile(color = "white", linewidth = 0.2) +
  facet_wrap(~Group, ncol = 2) +
  scale_fill_gradient(low = "white", high = COLOR_ALS, name = "Mean VAF") +
  labs(
    title = "Top 50 miRNAs: G>T VAF by Position",
    subtitle = "Ordered by total G>T burden",
    x = "Position in miRNA",
    y = "miRNA"
  ) +
  theme_minimal(base_size = 10) +
  theme(
    plot.title = element_text(face = "bold", hjust = 0.5),
    axis.text.y = element_text(size = 6),
    axis.text.x = element_text(size = 8),
    strip.text = element_text(face = "bold", size = 11),
    panel.grid = element_blank()
  )

ggsave("figures_paso2_CLEAN/OPCION_B_HEATMAP_TOP50.png", plot_b, 
       width = 12, height = 14, dpi = 300, bg = "white")
cat("   ✅ Guardada\n\n")

# ============================================================================
# OPCIÓN C: TODOS (sin nombres)
# ============================================================================

cat("📊 Opción C: TODOS (301) sin nombres...\n")

all_mirnas <- seed_gt_summary$miRNA_name

data_all <- vaf_gt_all %>%
  filter(miRNA_name %in% all_mirnas) %>%
  group_by(miRNA_name, position, Group) %>%
  summarise(Mean_VAF = mean(VAF, na.rm = TRUE), .groups = "drop") %>%
  mutate(
    position = factor(position, levels = 1:22),
    miRNA_name = factor(miRNA_name, levels = all_mirnas)
  )

plot_c <- ggplot(data_all, aes(x = position, y = miRNA_name, fill = Mean_VAF)) +
  geom_tile(color = NA) +  # Sin bordes (demasiados)
  facet_wrap(~Group, ncol = 2) +
  scale_fill_gradient(low = "white", high = COLOR_ALS, name = "Mean VAF") +
  labs(
    title = "ALL 301 miRNAs: G>T VAF by Position",
    subtitle = "Pattern visualization (miRNA names omitted for clarity)",
    x = "Position in miRNA",
    y = paste0("miRNAs (n=", length(all_mirnas), ", ranked by burden)")
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold", hjust = 0.5),
    axis.text.y = element_blank(),  # Sin nombres
    axis.ticks.y = element_blank(),
    axis.text.x = element_text(size = 9),
    strip.text = element_text(face = "bold", size = 12),
    panel.grid = element_blank()
  )

ggsave("figures_paso2_CLEAN/OPCION_C_HEATMAP_ALL301_NO_LABELS.png", plot_c, 
       width = 12, height = 16, dpi = 300, bg = "white")
cat("   ✅ Guardada\n\n")

# ============================================================================
# OPCIÓN D: Ya se generó antes (resumen agregado)
# ============================================================================

cat("✅ Opción D ya generada (OPCION_D_HEATMAP_SUMMARY_ALL.png)\n\n")

# ============================================================================
# RESUMEN
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")
cat("✅ CUATRO OPCIONES LISTAS PARA COMPARAR:\n\n")
cat("   A. Top 30 - Más legible, miRNAs identificables\n")
cat("   B. Top 50 - Balance, más detalle\n")
cat("   C. ALL 301 - Patrón completo, sin identificar miRNAs\n")
cat("   D. Summary - 2 filas (ALS y Control), TODOS los datos ⭐\n\n")
cat("📁 Todas en: figures_paso2_CLEAN/\n\n")

