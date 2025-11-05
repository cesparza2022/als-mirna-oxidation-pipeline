# 🎨 FIGURA 1 PROFESSIONAL - IMPROVED STYLE

rm(list = ls())

library(tidyverse)
library(patchwork)
library(scales)

source("config/config_pipeline_2.R")

cat("\n🎨 FIGURA 1 PROFESSIONAL - IMPROVED STYLE\n")
cat("═══════════════════════════════════════════════════════════\n\n")

## Load data
data_path <- "/Users/cesaresparza/New_Desktop/UCSD/8OG/results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt"
raw_data <- read_tsv(data_path, show_col_types = FALSE)

processed_data <- raw_data %>%
  separate_rows(`pos:mut`, sep = ",") %>%
  filter(`pos:mut` != "PM") %>%
  separate(`pos:mut`, into = c("position", "mutation_type"), sep = ":", remove = FALSE) %>%
  mutate(
    position = as.numeric(position),
    mutation_type = case_when(
      mutation_type == "GT" ~ "G>T",
      mutation_type == "TC" ~ "T>C",
      mutation_type == "AG" ~ "A>G",
      mutation_type == "GA" ~ "G>A",
      mutation_type == "CT" ~ "C>T",
      TRUE ~ mutation_type
    )
  ) %>%
  filter(position >= 1 & position <= 22)

cat("✅ Data processed\n\n")

## ═══════════════════════════════════════════════════════════════════════════
## PANEL A: Dataset Evolution + Mutation Types (IMPROVED - BARS NOT PIE)
## ═══════════════════════════════════════════════════════════════════════════

cat("🎨 Panel A: Dataset evolution + mutation types (horizontal bars)...\n")

# Part 1: Evolution
evolution <- tibble(
  step = factor(c("Raw Entries", "Individual SNVs"), 
                levels = c("Raw Entries", "Individual SNVs")),
  snvs = c(nrow(raw_data), nrow(processed_data)),
  mirnas = c(length(unique(raw_data$`miRNA name`)), 
             length(unique(processed_data$`miRNA name`)))
)

p1a <- ggplot(evolution, aes(x = step, y = snvs)) +
  geom_col(fill = "steelblue", alpha = 0.8, width = 0.6, color = "black", linewidth = 0.3) +
  geom_text(aes(label = paste0(format(snvs, big.mark=","), "\n", 
                                format(mirnas, big.mark=","), " miRNAs")), 
            vjust = -0.3, size = 3.5, fontface = "bold") +
  scale_y_continuous(labels = comma, expand = expansion(mult = c(0, 0.15))) +
  labs(title = "Dataset evolution", x = NULL, y = "SNVs") +
  theme_classic(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold", size = 12, hjust = 0.5),
    axis.text.x = element_text(size = 10, angle = 0),
    panel.grid.major.y = element_line(color = "grey90", linewidth = 0.3)
  )

# Part 2: Mutation types (HORIZONTAL BARS - MORE PROFESSIONAL)
mutation_types <- processed_data %>%
  count(mutation_type) %>%
  arrange(desc(n)) %>%
  head(10) %>%
  mutate(
    percentage = n / sum(n) * 100,
    mutation_type = fct_reorder(mutation_type, n)
  )

p1b <- ggplot(mutation_types, aes(x = n, y = mutation_type)) +
  geom_col(aes(fill = mutation_type == "G>T"), alpha = 0.8, 
           color = "black", linewidth = 0.3, show.legend = FALSE) +
  geom_text(aes(label = paste0(comma(n), " (", round(percentage, 1), "%)")),
            hjust = -0.1, size = 3, fontface = "bold") +
  scale_fill_manual(values = c("FALSE" = "grey70", "TRUE" = "#FF7F00")) +
  scale_x_continuous(labels = comma, expand = expansion(mult = c(0, 0.2))) +
  labs(title = "Top 10 mutation types", x = "Count", y = NULL) +
  theme_classic(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold", size = 12, hjust = 0.5),
    axis.text.y = element_text(size = 10),
    panel.grid.major.x = element_line(color = "grey90", linewidth = 0.3)
  )

# Combine
panel_a <- p1a + p1b + plot_layout(widths = c(1, 1.2))

ggsave(file.path(figures_dir, "panel_a_overview_PROFESSIONAL.png"), 
       panel_a, width = 12, height = 6, dpi = 300, bg = "white")
cat("✅ Panel A (professional - PIE → HORIZONTAL BARS)\n\n")

## ═══════════════════════════════════════════════════════════════════════════
## PANEL B: G>T Positional (PROFESSIONAL STYLE)
## ═══════════════════════════════════════════════════════════════════════════

cat("🎨 Panel B: G>T positional...\n")

gt_by_pos <- processed_data %>%
  filter(mutation_type == "G>T") %>%
  count(position) %>%
  complete(position = 1:22, fill = list(n = 0)) %>%
  mutate(
    region = ifelse(position >= 2 & position <= 8, "Seed", "Non-Seed"),
    fraction = n / sum(n) * 100
  )

ymax_b <- max(gt_by_pos$n) * 1.15

panel_b <- ggplot(gt_by_pos, aes(x = position, y = n, fill = region)) +
  # Seed shading
  annotate("rect", xmin = 1.5, xmax = 8.5, ymin = 0, ymax = Inf,
           fill = "grey80", alpha = 0.2) +
  annotate("text", x = 5, y = Inf, label = "SEED",
           vjust = 2, size = 3.5, fontface = "bold", color = "grey40") +
  # Bars
  geom_col(color = "black", linewidth = 0.3, alpha = 0.85, width = 0.8) +
  scale_fill_manual(values = c("Seed" = "#FFD700", "Non-Seed" = "grey70")) +
  scale_x_continuous(breaks = 1:22, minor_breaks = NULL) +
  scale_y_continuous(labels = comma, expand = expansion(mult = c(0, 0.12))) +
  coord_cartesian(ylim = c(0, ymax_b)) +
  labs(
    title = "G>T distribution by position",
    subtitle = "Seed region (2-8) highlighted",
    x = "Position in miRNA",
    y = "G>T count",
    fill = "Region"
  ) +
  theme_classic(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 13, hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5, color = "gray40"),
    axis.text.x = element_text(size = 9),
    legend.position = c(0.15, 0.9),
    panel.grid.major.y = element_line(color = "grey90", linewidth = 0.3)
  )

ggsave(file.path(figures_dir, "panel_b_positional_PROFESSIONAL.png"), 
       panel_b, width = 12, height = 6, dpi = 300, bg = "white")
cat("✅ Panel B (professional)\n\n")

## ═══════════════════════════════════════════════════════════════════════════
## PANEL C: Mutation Spectrum (SIMPLIFIED & PROFESSIONAL)
## ═══════════════════════════════════════════════════════════════════════════

cat("🎨 Panel C: G>X mutation spectrum...\n")

gx_spectrum <- processed_data %>%
  filter(str_detect(mutation_type, "^G>")) %>%
  count(mutation_type) %>%
  arrange(desc(n)) %>%
  mutate(
    percentage = n / sum(n) * 100,
    mutation_type = fct_reorder(mutation_type, n),
    is_gt = mutation_type == "G>T"
  )

panel_c <- ggplot(gx_spectrum, aes(x = n, y = mutation_type, fill = is_gt)) +
  geom_col(alpha = 0.85, color = "black", linewidth = 0.3, show.legend = FALSE) +
  geom_text(aes(label = paste0(comma(n), " (", round(percentage, 1), "%)")),
            hjust = -0.1, size = 3.5, fontface = "bold") +
  scale_fill_manual(values = c("FALSE" = "grey70", "TRUE" = "#FF7F00")) +
  scale_x_continuous(labels = comma, expand = expansion(mult = c(0, 0.25))) +
  labs(
    title = "G>X mutation spectrum",
    subtitle = "G>T highlighted in orange",
    x = "Count",
    y = NULL
  ) +
  theme_classic(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 13, hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5, color = "gray40"),
    panel.grid.major.x = element_line(color = "grey90", linewidth = 0.3)
  )

ggsave(file.path(figures_dir, "panel_c_spectrum_PROFESSIONAL.png"), 
       panel_c, width = 9, height = 6, dpi = 300, bg = "white")
cat("✅ Panel C (professional)\n\n")

## ═══════════════════════════════════════════════════════════════════════════
## PANEL D: Top miRNAs with G>T (NEW - PROFESSIONAL)
## ═══════════════════════════════════════════════════════════════════════════

cat("🎨 Panel D: Top miRNAs with G>T (NEW)...\n")

top_mirnas <- processed_data %>%
  filter(mutation_type == "G>T") %>%
  count(`miRNA name`) %>%
  arrange(desc(n)) %>%
  head(15) %>%
  mutate(
    percentage = n / sum(n) * 100,
    `miRNA name` = fct_reorder(`miRNA name`, n)
  )

panel_d <- ggplot(top_mirnas, aes(x = n, y = `miRNA name`)) +
  geom_col(fill = "#FF7F00", alpha = 0.8, color = "black", linewidth = 0.3) +
  geom_text(aes(label = comma(n)), hjust = -0.2, size = 3, fontface = "bold") +
  scale_x_continuous(labels = comma, expand = expansion(mult = c(0, 0.2))) +
  labs(
    title = "Top 15 miRNAs with G>T mutations",
    subtitle = "Candidates for oxidative stress biomarkers",
    x = "G>T count",
    y = NULL
  ) +
  theme_classic(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 13, hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5, color = "gray40"),
    axis.text.y = element_text(size = 9),
    panel.grid.major.x = element_line(color = "grey90", linewidth = 0.3)
  )

ggsave(file.path(figures_dir, "panel_d_top_mirnas_PROFESSIONAL.png"), 
       panel_d, width = 10, height = 8, dpi = 300, bg = "white")
cat("✅ Panel D (professional - NEW with top miRNAs)\n\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("  🎉 FIGURA 1 PROFESSIONAL - COMPLETE\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

cat("📁 OUTPUTS:\n")
cat("   • panel_a_overview_PROFESSIONAL.png (PIE → BARS)\n")
cat("   • panel_b_positional_PROFESSIONAL.png\n")
cat("   • panel_c_spectrum_PROFESSIONAL.png\n")
cat("   • panel_d_top_mirnas_PROFESSIONAL.png (NEW)\n\n")

cat("🎨 IMPROVEMENTS:\n")
cat("   ✅ Pie chart → Horizontal bars (more readable)\n")
cat("   ✅ theme_classic() all panels\n")
cat("   ✅ Panel D now shows top miRNAs (useful!)\n")
cat("   ✅ Consistent professional style\n")
cat("   ✅ Grid lines subtle (grey90)\n\n")

