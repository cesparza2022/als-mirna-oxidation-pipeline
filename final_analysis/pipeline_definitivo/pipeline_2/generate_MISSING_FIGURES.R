# Generar figuras faltantes: 2.4, 2.5, 2.6, 2.11

library(ggplot2)
library(dplyr)
library(tidyr)
library(stringr)
library(patchwork)
library(viridis)
library(pheatmap)
library(tibble)

COLOR_ALS <- "#D62728"
COLOR_CONTROL <- "#666666"
COLOR_SEED <- "#FFE135"

theme_professional <- theme_minimal() +
  theme(
    text = element_text(size = 14, family = "Helvetica"),
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
    axis.title = element_text(size = 14, face = "bold"),
    panel.grid.major = element_line(color = "gray90", linewidth = 0.5)
  )

cat("📊 GENERANDO FIGURAS FALTANTES\n\n")

# Cargar datos
data <- read.csv("../../../final_analysis/processed_data/final_processed_data.csv")
metadata <- read.csv("metadata.csv")
sample_cols <- metadata$Sample_ID
output_dir <- "figures_paso2"

# Datos G>T
vaf_gt <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  select(all_of(c("miRNA_name", "pos.mut", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  left_join(metadata, by = "Sample_ID") %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^\\d+"))) %>%
  filter(!is.na(position), position <= 22)

# ===== FIGURA 2.6: PERFILES POSICIONALES =====
cat("📊 Generando Figura 2.6...\n")

positional_profile <- vaf_gt %>%
  group_by(position, Group) %>%
  summarise(
    Mean_VAF = mean(VAF, na.rm = TRUE),
    SE_VAF = sd(VAF, na.rm = TRUE) / sqrt(n()),
    .groups = "drop"
  )

# Panel A
panel_a <- ggplot(positional_profile, aes(x = position, y = Mean_VAF, color = Group, fill = Group)) +
  geom_ribbon(aes(ymin = Mean_VAF - SE_VAF, ymax = Mean_VAF + SE_VAF), alpha = 0.2, color = NA) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2) +
  annotate("rect", xmin = 2, xmax = 8, ymin = -Inf, ymax = Inf, fill = COLOR_SEED, alpha = 0.2) +
  scale_color_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  labs(title = "A. G>T VAF by Position", x = "Position", y = "Mean VAF") +
  theme_professional

# Panel B
fc_by_position <- positional_profile %>%
  select(position, Group, Mean_VAF) %>%
  pivot_wider(names_from = Group, values_from = Mean_VAF) %>%
  mutate(log2FC = log2((ALS + 0.001) / (Control + 0.001)))

panel_b <- ggplot(fc_by_position, aes(x = position, y = log2FC)) +
  geom_col(aes(fill = log2FC > 0), width = 0.7) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  annotate("rect", xmin = 2, xmax = 8, ymin = -Inf, ymax = Inf, fill = COLOR_SEED, alpha = 0.2) +
  scale_fill_manual(values = c("TRUE" = COLOR_ALS, "FALSE" = "steelblue")) +
  labs(title = "B. log2(FC) by Position", x = "Position", y = "log2(ALS / Control)") +
  theme_professional +
  theme(legend.position = "none")

# Panel C
significance_by_position <- data.frame()
for (pos in 1:22) {
  pos_data <- vaf_gt %>% filter(position == pos)
  als_vals <- pos_data %>% filter(Group == "ALS") %>% pull(VAF)
  ctrl_vals <- pos_data %>% filter(Group == "Control") %>% pull(VAF)
  
  if (length(als_vals) > 5 && length(ctrl_vals) > 5) {
    test_result <- wilcox.test(als_vals, ctrl_vals)
    significance_by_position <- rbind(significance_by_position, data.frame(
      position = pos,
      pvalue = test_result$p.value
    ))
  }
}
significance_by_position$padj <- p.adjust(significance_by_position$pvalue, method = "fdr")

panel_c <- ggplot(significance_by_position, aes(x = position, y = -log10(padj))) +
  geom_col(fill = "gray40", width = 0.7) +
  geom_hline(yintercept = -log10(0.05), linetype = "dashed", color = "red") +
  annotate("rect", xmin = 2, xmax = 8, ymin = -Inf, ymax = Inf, fill = COLOR_SEED, alpha = 0.2) +
  labs(title = "C. Significance by Position", x = "Position", y = "-log10(FDR p-value)") +
  theme_professional

figure_2_6 <- panel_a / panel_b / panel_c
ggsave(file.path(output_dir, "FIGURA_2.6_POSITIONAL_PROFILES.png"), 
       plot = figure_2_6, width = 12, height = 14, dpi = 300)
cat("✅ Figura 2.6 guardada\n\n")

# ===== FIGURAS 2.4, 2.5, 2.11 (Heatmaps simplificados) =====
cat("📊 Generando heatmaps simplificados...\n")

# Para 2.4 y 2.5: Heatmap básico de G>T
vaf_matrix_data <- vaf_gt %>%
  group_by(miRNA_name, position, Group) %>%
  summarise(Mean_VAF = mean(VAF, na.rm = TRUE), .groups = "drop")

# Top 20 miRNAs (simplificado)
top_mirnas <- vaf_matrix_data %>%
  group_by(miRNA_name) %>%
  summarise(Total = sum(Mean_VAF), .groups = "drop") %>%
  arrange(desc(Total)) %>%
  head(20) %>%
  pull(miRNA_name)

# Crear matriz para heatmap
heatmap_data <- vaf_matrix_data %>%
  filter(miRNA_name %in% top_mirnas) %>%
  select(miRNA_name, position, Group, Mean_VAF) %>%
  unite("id", miRNA_name, Group) %>%
  pivot_wider(names_from = position, values_from = Mean_VAF, values_fill = 0) %>%
  column_to_rownames("id")

# Completar posiciones faltantes
all_positions <- as.character(1:22)
for (pos in setdiff(all_positions, colnames(heatmap_data))) {
  heatmap_data[[pos]] <- 0
}
heatmap_data <- heatmap_data[, all_positions]
heatmap_matrix <- as.matrix(heatmap_data)

# Figura 2.4
png(file.path(output_dir, "FIGURA_2.4_HEATMAP_POSITIONAL.png"), 
    width = 12, height = 10, units = "in", res = 300)
pheatmap(heatmap_matrix,
         main = "G>T VAF by Position (Top 20 miRNAs)",
         color = colorRampPalette(c("white", "red"))(100),
         cluster_cols = FALSE,
         fontsize = 10)
dev.off()
cat("✅ Figura 2.4 guardada\n")

# Figura 2.5: Z-score
heatmap_zscore <- t(scale(t(heatmap_matrix)))
# Reemplazar NA/Inf con 0
heatmap_zscore[is.na(heatmap_zscore) | is.infinite(heatmap_zscore)] <- 0
png(file.path(output_dir, "FIGURA_2.5_HEATMAP_ZSCORE.png"), 
    width = 12, height = 10, units = "in", res = 300)
pheatmap(heatmap_zscore,
         main = "G>T VAF Z-score by Position",
         color = colorRampPalette(c("blue", "white", "red"))(100),
         breaks = seq(-3, 3, length.out = 101),
         cluster_cols = FALSE,
         fontsize = 10)
dev.off()
cat("✅ Figura 2.5 guardada\n\n")

# Figura 2.11: Todos los tipos de mutación
cat("📊 Generando Figura 2.11...\n")
all_mutations <- data %>%
  mutate(
    position = as.numeric(str_extract(pos.mut, "^\\d+")),
    mutation_type = str_extract(pos.mut, ":\\w+$") %>% str_remove(":")
  ) %>%
  filter(!is.na(position), position <= 22)

mutation_heatmap_data <- all_mutations %>%
  select(all_of(c("mutation_type", "position", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  left_join(metadata, by = "Sample_ID") %>%
  group_by(mutation_type, position, Group) %>%
  summarise(Mean_VAF = mean(VAF, na.rm = TRUE), .groups = "drop")

# Matriz por grupo
create_mut_matrix <- function(group_name) {
  matrix_data <- mutation_heatmap_data %>%
    filter(Group == group_name) %>%
    select(mutation_type, position, Mean_VAF) %>%
    pivot_wider(names_from = position, values_from = Mean_VAF, values_fill = 0)
  
  mat <- as.matrix(matrix_data[, -1])
  rownames(mat) <- matrix_data$mutation_type
  return(mat)
}

png(file.path(output_dir, "FIGURA_2.11_HEATMAP_MUTATION_TYPES.png"), 
    width = 16, height = 8, units = "in", res = 300)
par(mfrow = c(1, 2))

mat_als <- create_mut_matrix("ALS")
pheatmap(mat_als,
         main = "ALS: All Mutation Types",
         color = colorRampPalette(c("white", "red"))(100),
         cluster_rows = FALSE,
         cluster_cols = FALSE,
         fontsize = 8,
         silent = TRUE)

mat_ctrl <- create_mut_matrix("Control")
pheatmap(mat_ctrl,
         main = "Control: All Mutation Types",
         color = colorRampPalette(c("white", "blue"))(100),
         cluster_rows = FALSE,
         cluster_cols = FALSE,
         fontsize = 8,
         silent = TRUE)
dev.off()
cat("✅ Figura 2.11 guardada\n\n")

cat("\n✅ TODAS LAS FIGURAS COMPLETADAS\n")
cat("📁 Total:", length(list.files(output_dir, pattern = "\\.png$")), "figuras\n")

