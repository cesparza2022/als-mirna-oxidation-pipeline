#!/usr/bin/env Rscript
# ============================================================================
# PASO 2.5.5: COMPARACIÓN CANDIDATOS ALS vs CONTROL
# Analiza los 22 miRNAs enriquecidos en Control
# ============================================================================

library(dplyr)
library(readr)
library(stringr)
library(ggplot2)
library(VennDiagram)
library(gridExtra)

COLOR_ALS <- "#D62728"
COLOR_CTRL <- "grey60"

theme_prof <- theme_classic(base_size = 14) +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
    axis.title = element_text(face = "bold")
  )

cat("🎯 PASO 2.5.5: CANDIDATOS ALS vs CONTROL\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

# ============================================================================
# CARGAR DATOS
# ============================================================================

# Volcano data
volcano <- read_csv("../pipeline_2/VOLCANO_PLOT_DATA_PER_SAMPLE.csv", show_col_types = FALSE)

# Candidatos ALS (permissive)
als_cand <- read_csv("../results_threshold_permissive/ALS_candidates.csv", show_col_types = FALSE)

# Candidatos Control (FC < -1.25x, p < 0.10)
ctrl_cand <- volcano %>%
  filter(log2FC < -0.32, padj < 0.10) %>%
  arrange(padj)

cat(sprintf("📊 Candidatos ALS: %d\n", nrow(als_cand)))
cat(sprintf("📊 Candidatos Control: %d\n\n", nrow(ctrl_cand)))

# ============================================================================
# EXTRAER CARACTERÍSTICAS
# ============================================================================

cat("📊 Extrayendo características...\n")

extract_family <- function(mirna) {
  if (str_detect(mirna, "let-\\d+")) {
    return("let-7")
  } else if (str_detect(mirna, "miR-(\\d+)")) {
    family_num <- str_extract(mirna, "miR-(\\d+)") %>% str_remove("miR-")
    return(paste0("miR-", family_num))
  } else {
    return("Other")
  }
}

als_cand$Family <- sapply(als_cand$miRNA, extract_family)
ctrl_cand$Family <- sapply(ctrl_cand$miRNA, extract_family)
ctrl_cand$Group <- "Control"
als_cand$Group <- "ALS"

# Combinar
all_candidates <- bind_rows(
  als_cand %>% select(miRNA, log2FC, padj, Mean_ALS, Mean_Control, Family, Group),
  ctrl_cand %>% select(miRNA, log2FC, padj, Mean_ALS, Mean_Control, Family, Group)
)

write_csv(all_candidates, "data/als_vs_control_candidates.csv")
write_csv(ctrl_cand, "data/control_candidates.csv")

cat("   ✅ Características extraídas\n\n")

# ============================================================================
# FIGURA 1: VENN DIAGRAM
# ============================================================================

cat("📊 [1/3] Venn diagram...\n")

# Listas
all_301 <- read_csv("../pipeline_2/SEED_GT_miRNAs_CLEAN_RANKING.csv", show_col_types = FALSE)
als_list <- als_cand$miRNA
ctrl_list <- ctrl_cand$miRNA
no_sig_list <- setdiff(all_301$miRNA_name, c(als_list, ctrl_list))

png("figures/FIG_2.5_13_VENN_ALS_CTRL.png", width = 10, height = 10, units = "in", res = 300)

venn_sets <- list(
  "ALS\nEnriched" = als_list,
  "Control\nEnriched" = ctrl_list
)

venn.plot <- venn.diagram(
  x = venn_sets,
  category.names = names(venn_sets),
  filename = NULL,
  fill = c(COLOR_ALS, COLOR_CTRL),
  alpha = 0.5,
  cex = 2.5,
  cat.cex = 2,
  cat.fontface = "bold",
  margin = 0.1
)

grid::grid.draw(venn.plot)
dev.off()

cat("   ✅ Guardada\n\n")

# ============================================================================
# FIGURA 2: COMPARACIÓN DE CARACTERÍSTICAS
# ============================================================================

cat("📊 [2/3] Comparación características...\n")

# Comparar familias
family_comparison <- all_candidates %>%
  count(Group, Family) %>%
  pivot_wider(names_from = Group, values_from = n, values_fill = 0)

fig2 <- ggplot(all_candidates, aes(x = Group, fill = Family)) +
  geom_bar(position = "fill", alpha = 0.8, width = 0.6) +
  scale_fill_brewer(palette = "Set3") +
  scale_y_continuous(labels = scales::percent) +
  labs(
    title = "Family Distribution: ALS vs Control Candidates",
    x = NULL,
    y = "Percentage",
    fill = "miRNA Family"
  ) +
  theme_prof +
  theme(legend.position = "right")

ggsave("figures/FIG_2.5_14_FAMILIES_ALS_VS_CTRL.png", fig2, width = 10, height = 7, dpi = 300)

cat("   ✅ Guardada\n\n")

# ============================================================================
# FIGURA 3: VOLCANO PLOT ANOTADO
# ============================================================================

cat("📊 [3/3] Volcano plot anotado...\n")

# Volcano con regiones
volcano_annotated <- volcano %>%
  mutate(
    Category = case_when(
      miRNA %in% als_cand$miRNA ~ "ALS Enriched",
      miRNA %in% ctrl_cand$miRNA ~ "Control Enriched",
      TRUE ~ "Not Significant"
    )
  )

# Top 5 de cada grupo para etiquetar
top_als <- head(als_cand$miRNA, 5)
top_ctrl <- head(ctrl_cand$miRNA, 5)

fig3 <- ggplot(volcano_annotated, aes(x = log2FC, y = -log10(padj))) +
  geom_point(aes(color = Category), alpha = 0.6, size = 2.5) +
  geom_vline(xintercept = c(-0.32, 0.32), linetype = "dashed", color = "grey40") +
  geom_hline(yintercept = -log10(0.10), linetype = "dashed", color = "grey40") +
  geom_text(data = volcano_annotated %>% filter(miRNA %in% c(top_als, top_ctrl)),
            aes(label = miRNA), size = 3, vjust = -0.7, fontface = "bold") +
  scale_color_manual(values = c(
    "ALS Enriched" = COLOR_ALS,
    "Control Enriched" = COLOR_CTRL,
    "Not Significant" = "grey85"
  )) +
  labs(
    title = "Volcano Plot: ALS vs Control Candidates",
    subtitle = sprintf("ALS: %d | Control: %d | Not Sig: %d", 
                      nrow(als_cand), nrow(ctrl_cand), 
                      nrow(volcano) - nrow(als_cand) - nrow(ctrl_cand)),
    x = "log2(Fold Change) ALS vs Control",
    y = "-log10(p-value)",
    color = "Category"
  ) +
  theme_prof +
  theme(legend.position = "bottom")

ggsave("figures/FIG_2.5_15_VOLCANO_ANNOTATED.png", fig3, width = 12, height = 10, dpi = 300)

cat("   ✅ Guardada\n\n")

# ============================================================================
# RESUMEN
# ============================================================================

cat(paste(rep("=", 70), collapse = ""), "\n")
cat("✅ COMPARACIÓN ALS vs CONTROL COMPLETADA\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

cat("📊 HALLAZGOS:\n")
cat(sprintf("   • Candidatos ALS: %d\n", nrow(als_cand)))
cat(sprintf("   • Candidatos Control: %d\n", nrow(ctrl_cand)))
cat(sprintf("   • No significativos: %d\n", nrow(volcano) - nrow(als_cand) - nrow(ctrl_cand)))

cat("\n🔝 TOP 5 CONTROL (más enriquecidos):\n")
top5_ctrl <- head(ctrl_cand, 5)
for (i in 1:nrow(top5_ctrl)) {
  row <- top5_ctrl[i, ]
  fc <- round(2^row$log2FC, 2)
  cat(sprintf("   %d. %s (FC %.2fx, p %.4f)\n", i, row$miRNA, fc, row$padj))
}

cat("\n💡 INTERPRETACIÓN:\n")
cat("   • Control tiene MÁS G>T en 22 miRNAs\n")
cat("   • ¿Mecanismo protector o compensatorio?\n")
cat("   • ¿Diferentes procesos biológicos?\n")

cat("\n📁 ARCHIVOS:\n")
cat("   • FIG_2.5_13_VENN_ALS_CTRL.png\n")
cat("   • FIG_2.5_14_FAMILIES_ALS_VS_CTRL.png\n")
cat("   • FIG_2.5_15_VOLCANO_ANNOTATED.png\n")
cat("   • data/als_vs_control_candidates.csv\n")
cat("   • data/control_candidates.csv\n\n")

cat("🚀 SIGUIENTE: Crear HTML integrado\n")
cat("   Rscript scripts/06_create_HTML.R\n\n")

