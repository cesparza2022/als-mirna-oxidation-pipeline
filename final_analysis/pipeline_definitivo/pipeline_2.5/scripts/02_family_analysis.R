#!/usr/bin/env Rscript
# ============================================================================
# PASO 2.5.2: ANÁLISIS DE FAMILIAS miRNA
# Identifica si candidatos pertenecen a familias específicas
# ============================================================================

library(dplyr)
library(readr)
library(stringr)
library(ggplot2)
library(tidyr)

COLOR_ALS <- "#D62728"

theme_prof <- theme_classic(base_size = 14) +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
    axis.title = element_text(face = "bold")
  )

cat("🎯 PASO 2.5.2: ANÁLISIS DE FAMILIAS miRNA\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

# ============================================================================
# CARGAR DATOS
# ============================================================================

# Candidatos
candidates <- read_csv("../results_threshold_permissive/ALS_candidates.csv", show_col_types = FALSE)

# Todos los 301 con G>T en seed (background)
all_301 <- read_csv("../pipeline_2/SEED_GT_miRNAs_CLEAN_RANKING.csv", show_col_types = FALSE)

cat(sprintf("📊 Candidatos ALS: %d\n", nrow(candidates)))
cat(sprintf("📊 Background (301): %d\n\n", nrow(all_301)))

# ============================================================================
# EXTRAER FAMILIAS
# ============================================================================

cat("📊 Extrayendo familias...\n")

extract_family <- function(mirna) {
  # Extraer familia del nombre
  # ej: hsa-miR-196a-5p → miR-196
  # ej: hsa-let-7d-5p → let-7
  
  if (str_detect(mirna, "let-\\d+")) {
    return("let-7")
  } else if (str_detect(mirna, "miR-(\\d+)")) {
    family_num <- str_extract(mirna, "miR-(\\d+)") %>% str_remove("miR-")
    return(paste0("miR-", family_num))
  } else {
    return("Other")
  }
}

# Aplicar a candidatos
candidates$Family <- sapply(candidates$miRNA, extract_family)

# Aplicar a background
all_301$Family <- sapply(all_301$miRNA_name, extract_family)

cat("   ✅ Familias extraídas\n\n")

# ============================================================================
# CONTAR FAMILIAS
# ============================================================================

# Familias en candidatos
family_counts_candidates <- candidates %>%
  count(Family, name = "N_Candidates") %>%
  arrange(desc(N_Candidates))

# Familias en background
family_counts_background <- all_301 %>%
  count(Family, name = "N_Background") %>%
  arrange(desc(N_Background))

# Unir
family_comparison <- family_counts_candidates %>%
  left_join(family_counts_background, by = "Family") %>%
  mutate(
    N_Background = replace_na(N_Background, 0),
    Pct_Candidates = round(100 * N_Candidates / sum(N_Candidates), 1),
    Pct_Background = round(100 * N_Background / nrow(all_301), 1),
    Enrichment = Pct_Candidates / Pct_Background
  ) %>%
  arrange(desc(Enrichment))

cat("🔝 TOP FAMILIAS EN CANDIDATOS:\n")
print(family_comparison)
cat("\n")

write_csv(family_comparison, "data/family_enrichment.csv")

# ============================================================================
# FIGURA 1: BARPLOT FAMILIAS EN CANDIDATOS
# ============================================================================

cat("📊 [1/3] Barplot familias...\n")

fig1 <- ggplot(family_counts_candidates, aes(x = reorder(Family, N_Candidates), y = N_Candidates)) +
  geom_col(fill = COLOR_ALS, alpha = 0.8, width = 0.7) +
  geom_text(aes(label = N_Candidates), hjust = -0.3, size = 5, fontface = "bold") +
  coord_flip() +
  labs(
    title = sprintf("miRNA Families in %d ALS Candidates", nrow(candidates)),
    x = NULL,
    y = "Number of Candidates"
  ) +
  theme_prof +
  ylim(0, max(family_counts_candidates$N_Candidates) * 1.15)

ggsave("figures/FIG_2.5_5_FAMILIES_BARPLOT.png", fig1, width = 10, height = 8, dpi = 300)

cat("   ✅ Guardada\n\n")

# ============================================================================
# FIGURA 2: ENRICHMENT PLOT
# ============================================================================

cat("📊 [2/3] Enrichment plot...\n")

# Solo familias con al menos 2 candidatos
family_enriched <- family_comparison %>%
  filter(N_Candidates >= 2, Family != "Other") %>%
  arrange(desc(Enrichment))

if (nrow(family_enriched) > 0) {
  fig2 <- ggplot(family_enriched, aes(x = reorder(Family, Enrichment), y = Enrichment)) +
    geom_col(aes(fill = Enrichment), alpha = 0.8, width = 0.7) +
    geom_hline(yintercept = 1, linetype = "dashed", color = "red", size = 1) +
    geom_text(aes(label = sprintf("%.1fx", Enrichment)), hjust = -0.2, size = 5, fontface = "bold") +
    scale_fill_gradient(low = "#fee5d9", high = COLOR_ALS) +
    coord_flip() +
    labs(
      title = "miRNA Family Enrichment in ALS Candidates",
      subtitle = "Enrichment = (% in Candidates) / (% in Background)",
      x = NULL,
      y = "Enrichment Factor"
    ) +
    theme_prof +
    theme(legend.position = "none") +
    ylim(0, max(family_enriched$Enrichment) * 1.15)
  
  ggsave("figures/FIG_2.5_6_FAMILY_ENRICHMENT.png", fig2, width = 10, height = 6, dpi = 300)
  cat("   ✅ Guardada\n\n")
} else {
  cat("   ⚠️ No hay familias con 2+ candidatos\n\n")
}

# ============================================================================
# FIGURA 3: VOLCANO PLOT ANOTADO CON FAMILIAS
# ============================================================================

cat("📊 [3/3] Volcano plot con familias...\n")

# Cargar datos del Volcano
volcano <- read_csv("../pipeline_2/VOLCANO_PLOT_DATA_PER_SAMPLE.csv", show_col_types = FALSE)

# Añadir familias
volcano$Family <- sapply(volcano$miRNA, extract_family)

# Clasificar
volcano <- volcano %>%
  mutate(
    Significance = case_when(
      log2FC > 0.32 & padj < 0.10 ~ "ALS Candidate",
      log2FC < -0.32 & padj < 0.10 ~ "Control Candidate",
      TRUE ~ "Not Significant"
    )
  )

# Plot con familias destacadas
fig3 <- ggplot(volcano, aes(x = log2FC, y = -log10(padj))) +
  geom_point(aes(color = Significance), alpha = 0.5, size = 2) +
  geom_vline(xintercept = c(-0.32, 0.32), linetype = "dashed", color = "grey40") +
  geom_hline(yintercept = -log10(0.10), linetype = "dashed", color = "grey40") +
  geom_text(data = volcano %>% filter(Significance == "ALS Candidate"),
            aes(label = Family), size = 3, vjust = -0.5, fontface = "bold") +
  scale_color_manual(values = c(
    "ALS Candidate" = COLOR_ALS,
    "Control Candidate" = "grey60",
    "Not Significant" = "grey80"
  )) +
  labs(
    title = "Volcano Plot Annotated with miRNA Families",
    subtitle = sprintf("%d ALS candidates | Colored by family", nrow(candidates)),
    x = "log2(Fold Change) ALS vs Control",
    y = "-log10(p-value)"
  ) +
  theme_prof

ggsave("figures/FIG_2.5_7_VOLCANO_FAMILIES.png", fig3, width = 12, height = 10, dpi = 300)

cat("   ✅ Guardada\n\n")

# ============================================================================
# RESUMEN
# ============================================================================

cat(paste(rep("=", 70), collapse = ""), "\n")
cat("✅ ANÁLISIS DE FAMILIAS COMPLETADO\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

cat("📊 HALLAZGOS:\n")
cat(sprintf("   • Total familias en candidatos: %d\n", nrow(family_counts_candidates)))
cat(sprintf("   • Familias enriquecidas (2+ candidates): %d\n", 
            sum(family_counts_candidates$N_Candidates >= 2)))

if (nrow(family_enriched) > 0) {
  cat("\n🔝 FAMILIAS MÁS ENRIQUECIDAS:\n")
  for (i in 1:min(3, nrow(family_enriched))) {
    row <- family_enriched[i, ]
    cat(sprintf("   %d. %s: %dx enriched (%d candidates)\n", 
                i, row$Family, round(row$Enrichment, 1), row$N_Candidates))
  }
}

cat("\n📁 ARCHIVOS:\n")
cat("   • FIG_2.5_5_FAMILIES_BARPLOT.png\n")
cat("   • FIG_2.5_6_FAMILY_ENRICHMENT.png\n")
cat("   • FIG_2.5_7_VOLCANO_FAMILIES.png\n")
cat("   • data/family_enrichment.csv\n\n")

cat("🚀 SIGUIENTE: Análisis de seed sequences\n")
cat("   Rscript scripts/03_seed_analysis.R\n\n")

