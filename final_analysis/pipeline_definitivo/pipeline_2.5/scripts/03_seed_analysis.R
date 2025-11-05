#!/usr/bin/env Rscript
# ============================================================================
# PASO 2.5.3: ANÁLISIS DE SEED SEQUENCES
# Analiza motivos conservados y posiciones afectadas en seeds
# ============================================================================

library(dplyr)
library(readr)
library(stringr)
library(ggplot2)
library(tidyr)
library(pheatmap)

COLOR_ALS <- "#D62728"
COLOR_GT <- "#FF6B6B"

theme_prof <- theme_classic(base_size = 14) +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
    axis.title = element_text(face = "bold")
  )

cat("🎯 PASO 2.5.3: ANÁLISIS DE SEED SEQUENCES\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

# ============================================================================
# CARGAR DATOS
# ============================================================================

cat("📊 Cargando datos...\n")

# Datos
data <- read_csv("../pipeline_2/final_processed_data_CLEAN.csv", show_col_types = FALSE)
candidates <- read_csv("../results_threshold_permissive/ALS_candidates.csv", show_col_types = FALSE)

# Filtrar G>T en seed de candidatos
data_candidates_seed <- data %>%
  filter(
    miRNA_name %in% candidates$miRNA,
    str_detect(pos.mut, "^[2-8]:GT$")
  )

cat(sprintf("   Candidatos: %d\n", nrow(candidates)))
cat(sprintf("   SNVs G>T en seed: %d\n\n", nrow(data_candidates_seed)))

# ============================================================================
# ANÁLISIS DE POSICIONES AFECTADAS
# ============================================================================

cat("📊 Analizando posiciones afectadas en seed...\n")

# Extraer posición de cada SNV
position_data <- data_candidates_seed %>%
  mutate(
    Position = as.integer(str_extract(pos.mut, "^\\d+"))
  ) %>%
  group_by(miRNA_name, Position) %>%
  summarise(
    N_SNVs = n(),
    .groups = "drop"
  )

# ============================================================================
# FIGURA 1: HEATMAP CANDIDATO x POSICIÓN
# ============================================================================

cat("📊 [1/3] Heatmap posiciones afectadas...\n")

# Matriz: Candidato x Posición (2-8)
library(tibble)
pos_matrix <- position_data %>%
  select(miRNA_name, Position, N_SNVs) %>%
  pivot_wider(names_from = Position, values_from = N_SNVs, values_fill = 0) %>%
  column_to_rownames("miRNA_name") %>%
  as.matrix()

# Asegurar que tenemos columnas 2-8
all_positions <- as.character(2:8)
missing_pos <- setdiff(all_positions, colnames(pos_matrix))
for (p in missing_pos) {
  pos_matrix <- cbind(pos_matrix, 0)
  colnames(pos_matrix)[ncol(pos_matrix)] <- p
}
pos_matrix <- pos_matrix[, all_positions]

png("figures/FIG_2.5_8_SEED_POSITIONS_HEATMAP.png", width = 10, height = 12, units = "in", res = 300)
pheatmap(
  pos_matrix,
  color = colorRampPalette(c("white", "#fee5d9", "#fc9272", COLOR_GT))(100),
  cluster_rows = TRUE,
  cluster_cols = FALSE,
  display_numbers = FALSE,
  main = sprintf("G>T Distribution Across Seed Positions (%d Candidates)", nrow(candidates)),
  fontsize = 12,
  angle_col = 0
)
dev.off()

cat("   ✅ Guardada\n\n")

# ============================================================================
# FIGURA 2: BARPLOT POSICIONES GLOBALES
# ============================================================================

cat("📊 [2/3] Barplot frecuencia por posición...\n")

# Sumar por posición
position_summary <- position_data %>%
  group_by(Position) %>%
  summarise(
    Total_SNVs = sum(N_SNVs),
    N_miRNAs = n_distinct(miRNA_name),
    .groups = "drop"
  )

fig2 <- ggplot(position_summary, aes(x = factor(Position), y = Total_SNVs)) +
  geom_col(fill = COLOR_GT, alpha = 0.8, width = 0.7) +
  geom_text(aes(label = Total_SNVs), vjust = -0.5, size = 6, fontface = "bold") +
  labs(
    title = "G>T Frequency by Seed Position",
    subtitle = sprintf("%d ALS candidates", nrow(candidates)),
    x = "Seed Position",
    y = "Number of G>T SNVs"
  ) +
  theme_prof +
  ylim(0, max(position_summary$Total_SNVs) * 1.15)

ggsave("figures/FIG_2.5_9_POSITIONS_BARPLOT.png", fig2, width = 10, height = 7, dpi = 300)

cat("   ✅ Guardada\n\n")

# ============================================================================
# FIGURA 3: HEATMAP CANDIDATOS x SNVs (Detallado)
# ============================================================================

cat("📊 [3/3] Heatmap detallado SNVs...\n")

# Crear ID único para cada SNV
snv_detailed <- data_candidates_seed %>%
  mutate(
    SNV_ID = paste0(miRNA_name, "_", pos.mut),
    Mean_VAF = rowMeans(select(., -c(miRNA_name, pos.mut)), na.rm = TRUE)
  ) %>%
  select(SNV_ID, miRNA_name, pos.mut, Mean_VAF) %>%
  arrange(miRNA_name, desc(Mean_VAF))

# Top SNVs
snv_matrix <- snv_detailed %>%
  select(SNV_ID, miRNA_name, Mean_VAF)

# Top 50 SNVs
top_snvs <- head(snv_matrix, 50)

fig3 <- ggplot(top_snvs, aes(x = reorder(SNV_ID, Mean_VAF), y = Mean_VAF)) +
  geom_col(aes(fill = miRNA_name), alpha = 0.8, width = 0.7) +
  coord_flip() +
  labs(
    title = "Top 50 G>T SNVs in Seed Region",
    subtitle = sprintf("%d ALS candidates", nrow(candidates)),
    x = NULL,
    y = "Mean VAF",
    fill = "miRNA"
  ) +
  theme_prof +
  theme(axis.text.y = element_text(size = 8))

ggsave("figures/FIG_2.5_10_TOP_SNVS.png", fig3, width = 12, height = 14, dpi = 300)

cat("   ✅ Guardada\n\n")

# ============================================================================
# GUARDAR RESULTADOS
# ============================================================================

write_csv(position_summary, "data/position_summary.csv")
write_csv(snv_matrix, "data/snv_details.csv")

# ============================================================================
# RESUMEN
# ============================================================================

cat(paste(rep("=", 70), collapse = ""), "\n")
cat("✅ ANÁLISIS DE SEEDS COMPLETADO\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

cat("📊 HALLAZGOS:\n")
cat(sprintf("   • Total SNVs G>T en seed: %d\n", nrow(data_candidates_seed)))
cat(sprintf("   • Posiciones afectadas: %s\n", paste(position_summary$Position, collapse = ", ")))

cat("\n🔝 POSICIONES MÁS AFECTADAS:\n")
top_pos <- head(arrange(position_summary, desc(Total_SNVs)), 3)
for (i in 1:nrow(top_pos)) {
  row <- top_pos[i, ]
  cat(sprintf("   %d. Posición %d: %d SNVs (%d miRNAs)\n", 
              i, row$Position, row$Total_SNVs, row$N_miRNAs))
}

cat("\n📁 ARCHIVOS:\n")
cat("   • FIG_2.5_8_SEED_POSITIONS_HEATMAP.png\n")
cat("   • FIG_2.5_9_POSITIONS_BARPLOT.png\n")
cat("   • FIG_2.5_10_TOP_SNVS.png\n")
cat("   • data/position_summary.csv\n")
cat("   • data/snv_details.csv\n\n")

cat("🚀 SIGUIENTE: Análisis trinucleótidos\n")
cat("   Rscript scripts/04_trinucleotide_analysis.R\n\n")

