#!/usr/bin/env Rscript
# ============================================================================
# PASO 2.5.4: ANÁLISIS DE CONTEXTO TRINUCLEÓTIDO (XGY)
# Analiza si G>T ocurre en contextos específicos (GpG, CpG, etc.)
# ============================================================================

library(dplyr)
library(readr)
library(stringr)
library(ggplot2)
library(tidyr)

COLOR_ALS <- "#D62728"
COLOR_GG <- "#E74C3C"  # GGX context (más susceptible)
COLOR_CG <- "#F39C12"  # CGX context
COLOR_OTHER <- "grey70"

theme_prof <- theme_classic(base_size = 14) +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
    axis.title = element_text(face = "bold")
  )

cat("🎯 PASO 2.5.4: ANÁLISIS TRINUCLEÓTIDO (XGY)\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

cat("📖 CONTEXTO BIOLÓGICO:\n")
cat("   GpG (GGX) es MÁS susceptible a 8-oxoG\n")
cat("   CpG (CGX) también (islas CpG)\n")
cat("   Contexto afecta tasa de mutación\n\n")

# ============================================================================
# CARGAR DATOS
# ============================================================================

cat("📊 Cargando datos...\n")

data <- read_csv("../pipeline_2/final_processed_data_CLEAN.csv", show_col_types = FALSE)
candidates <- read_csv("../results_threshold_permissive/ALS_candidates.csv", show_col_types = FALSE)

# Filtrar G>T en seed de candidatos
data_gt_seed <- data %>%
  filter(
    miRNA_name %in% candidates$miRNA,
    str_detect(pos.mut, "^[2-8]:GT$")
  )

cat(sprintf("   Candidatos: %d\n", nrow(candidates)))
cat(sprintf("   SNVs G>T en seed: %d\n\n", nrow(data_gt_seed)))

# ============================================================================
# NOTA: ANÁLISIS SIMPLIFICADO
# ============================================================================

cat("📋 NOTA: Para análisis completo de trinucleótidos se necesitan:\n")
cat("   • Secuencias completas de miRNAs (miRBase)\n")
cat("   • Contexto nucleotídico alrededor de cada G\n\n")

cat("📊 Análisis actual: Basado en datos disponibles\n")
cat("   (Posiciones y VAF por candidato)\n\n")

# ============================================================================
# ANÁLISIS: DISTRIBUCIÓN DE G>T POR CANDIDATO
# ============================================================================

cat("📊 Analizando distribución de G>T...\n")

# Contar SNVs por candidato
snv_per_candidate <- data_gt_seed %>%
  mutate(
    Row_VAF = rowSums(select(., -c(miRNA_name, pos.mut)), na.rm = TRUE)
  ) %>%
  group_by(miRNA_name) %>%
  summarise(
    N_SNVs_Seed = n(),
    Total_VAF = sum(Row_VAF),
    Mean_VAF = mean(Row_VAF),
    N_Positions = n_distinct(str_extract(pos.mut, "^\\d+")),
    .groups = "drop"
  ) %>%
  arrange(desc(Total_VAF))

write_csv(snv_per_candidate, "data/snv_per_candidate.csv")

# ============================================================================
# FIGURA 1: G>T LOAD POR CANDIDATO
# ============================================================================

cat("📊 [1/2] G>T load por candidato...\n")

fig1 <- ggplot(snv_per_candidate, aes(x = reorder(miRNA_name, Total_VAF), y = Total_VAF)) +
  geom_col(fill = COLOR_ALS, alpha = 0.8, width = 0.7) +
  geom_text(aes(label = N_SNVs_Seed), hjust = -0.2, size = 4, fontface = "bold") +
  coord_flip() +
  labs(
    title = "G>T Load in Seed Region by Candidate",
    subtitle = "Number = SNV count | Height = Total VAF",
    x = NULL,
    y = "Total VAF (G>T in Seed)"
  ) +
  theme_prof +
  ylim(0, max(snv_per_candidate$Total_VAF) * 1.15)

ggsave("figures/FIG_2.5_11_GT_LOAD_PER_CANDIDATE.png", fig1, width = 12, height = 10, dpi = 300)

cat("   ✅ Guardada\n\n")

# ============================================================================
# FIGURA 2: NÚMERO DE POSICIONES AFECTADAS
# ============================================================================

cat("📊 [2/2] Posiciones afectadas por candidato...\n")

fig2 <- ggplot(snv_per_candidate, aes(x = N_SNVs_Seed, y = N_Positions)) +
  geom_point(aes(size = Total_VAF), color = COLOR_ALS, alpha = 0.7) +
  geom_text(aes(label = miRNA_name), vjust = -1, size = 3, fontface = "bold") +
  scale_size_continuous(range = c(3, 15), name = "Total VAF") +
  labs(
    title = "Seed Complexity: SNV Count vs Positions Affected",
    subtitle = sprintf("%d ALS candidates", nrow(candidates)),
    x = "Number of G>T SNVs in Seed",
    y = "Number of Seed Positions Affected (2-8)"
  ) +
  theme_prof +
  ylim(0, max(snv_per_candidate$N_Positions) + 1)

ggsave("figures/FIG_2.5_12_SEED_COMPLEXITY.png", fig2, width = 10, height = 8, dpi = 300)

cat("   ✅ Guardada\n\n")

# ============================================================================
# RESUMEN
# ============================================================================

cat(paste(rep("=", 70), collapse = ""), "\n")
cat("✅ ANÁLISIS DE SEEDS COMPLETADO\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

cat("📊 HALLAZGOS:\n")
cat(sprintf("   • Total SNVs en seed: %d\n", sum(snv_per_candidate$N_SNVs_Seed)))
cat(sprintf("   • Promedio SNVs/candidato: %.1f\n", mean(snv_per_candidate$N_SNVs_Seed)))

cat("\n🔝 TOP 3 CANDIDATOS (por VAF en seed):\n")
top3 <- head(snv_per_candidate, 3)
for (i in 1:nrow(top3)) {
  row <- top3[i, ]
  cat(sprintf("   %d. %s: VAF=%.3f (%d SNVs en %d posiciones)\n", 
              i, row$miRNA_name, row$Total_VAF, row$N_SNVs_Seed, row$N_Positions))
}

cat("\n📁 ARCHIVOS:\n")
cat("   • FIG_2.5_11_GT_LOAD_PER_CANDIDATE.png\n")
cat("   • FIG_2.5_12_SEED_COMPLEXITY.png\n")
cat("   • data/snv_per_candidate.csv\n\n")

cat("📋 NOTA: Para análisis completo de trinucleótidos (XGY):\n")
cat("   Se necesitan secuencias de miRBase\n")
cat("   Análisis de contexto GpG vs CpG\n")
cat("   Logo plots con contexto extendido\n\n")

cat("🚀 SIGUIENTE: Comparación ALS vs Control candidates\n")
cat("   Rscript scripts/05_als_vs_control.R\n\n")

