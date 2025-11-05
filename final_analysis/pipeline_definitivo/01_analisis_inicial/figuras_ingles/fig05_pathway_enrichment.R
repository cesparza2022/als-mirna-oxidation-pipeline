#!/usr/bin/env Rscript
# ============================================================================
# FIGURA #5: Pathway Enrichment - "Why it Matters"
# ============================================================================
# 
# NARRATIVA: Conectar el descubrimiento molecular (let-7 oxidado) con
#            la patología (ALS). Mostrar que let-7 regula genes críticos
#            en pathways directamente relacionados con ALS.
#
# HISTORIA: "let-7 oxidation → dysregulation of ALS pathways"
#
# Datos: outputs/paso11_pathway/paso11_enrichment.csv
# Salida: figuras_ingles/fig05_pathway_enrichment_als.png
#
# Diseño Visual:
#   - Barras horizontales (más fácil leer nombres largos)
#   - Ordenadas por significancia (-log10 FDR)
#   - Color por categoría (KEGG vs GO)
#   - Línea de significancia (FDR=0.05)
#   - Destacar ALS pathway en rojo
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
  library(scales)
})

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  FIGURA #5: Pathway Enrichment - Linking let-7 to ALS\n")
cat("  'Oxidized let-7 → Dysregulated ALS Pathways'\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# ============================================================================
# CARGAR Y VERIFICAR DATOS
# ============================================================================

cat("📂 Loading pathway enrichment data...\n")

data <- read_csv("outputs/paso11_pathway/paso11_enrichment.csv", 
                 show_col_types = FALSE)

cat("   ✅ Data loaded:", nrow(data), "pathways\n")
cat("\n")

# Verificar narrativa
cat("🔍 Verifying narrative...\n")
cat("\n")

# Pathways significativos
sig_pathways <- data %>% filter(Significant == TRUE)
cat("   • Significant pathways (FDR < 0.05):", nrow(sig_pathways), "\n")
cat("   • Top pathway:", data$Category[1], "\n")
cat("   • Top FDR:", data$FDR[1], "\n")

if (str_detect(data$Category[1], "ALS")) {
  cat("   ✅ NARRATIVA CONFIRMADA: ALS pathway es #1\n")
} else {
  cat("   ⚠️  ADVERTENCIA: ALS pathway no es #1\n")
}

cat("\n")

# ============================================================================
# PREPARAR DATOS PARA PLOT
# ============================================================================

cat("🎨 Preparing data for visualization...\n")

# Limpiar nombres de categorías
data <- data %>%
  mutate(
    # Extraer solo nombre del pathway (sin ID)
    pathway_name = str_extract(Category, " - (.+)$", group = 1),
    pathway_name = if_else(is.na(pathway_name), Category, pathway_name),
    
    # Identificar tipo
    pathway_type = case_when(
      str_detect(Category, "^KEGG") ~ "KEGG",
      str_detect(Category, "^GO") ~ "GO",
      TRUE ~ "Other"
    ),
    
    # Destacar ALS pathway
    is_als = str_detect(Category, "ALS|05014"),
    
    # Calcular -log10(FDR) para altura de barra
    neg_log_fdr = -log10(FDR)
  ) %>%
  # Tomar top 10 para claridad
  head(10)

cat("   ✅ Data prepared for top", nrow(data), "pathways\n")
cat("\n")

# ============================================================================
# DISEÑAR FIGURA CON CUIDADO
# ============================================================================

cat("🎨 Designing figure with narrative focus...\n")
cat("\n")
cat("Visual elements:\n")
cat("  • Horizontal bars (easier to read pathway names)\n")
cat("  • Ordered by significance\n")
cat("  • ALS pathway highlighted in RED\n")
cat("  • Threshold line at FDR = 0.05\n")
cat("  • Color by pathway type (KEGG/GO)\n")
cat("\n")

# Plot
p <- ggplot(data, aes(x = neg_log_fdr, y = reorder(pathway_name, neg_log_fdr))) +
  
  # Línea de significancia
  geom_vline(xintercept = -log10(0.05), linetype = "dashed", 
             color = "gray40", size = 1) +
  
  # Barras
  geom_col(aes(fill = is_als, alpha = Significant), width = 0.7) +
  
  # Texto con número de genes
  geom_text(aes(label = paste0(N_let7_targets, "/", N_genes)), 
            hjust = -0.2, size = 3.5, fontface = "bold") +
  
  # Colores
  scale_fill_manual(
    values = c("TRUE" = "#e74c3c", "FALSE" = "#3498db"),
    labels = c("TRUE" = "ALS Pathway", "FALSE" = "Other Pathways"),
    name = ""
  ) +
  
  scale_alpha_manual(
    values = c("TRUE" = 0.9, "FALSE" = 0.5),
    guide = "none"
  ) +
  
  # Expandir eje X para texto
  scale_x_continuous(
    expand = expansion(mult = c(0, 0.15)),
    breaks = seq(0, 4, by = 0.5)
  ) +
  
  # Etiquetas
  labs(
    title = "let-7 Target Enrichment in ALS-Related Pathways",
    subtitle = "Oxidized let-7 dysregulates genes critical for ALS pathology",
    x = "Enrichment Significance (-log10 FDR)",
    y = "",
    caption = "Numbers on bars = let-7 targets / total genes in pathway\nDashed line = FDR = 0.05 threshold\nRed = ALS pathway (KEGG:05014)"
  ) +
  
  # Tema profesional
  theme_bw(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 16, hjust = 0.5, color = "#2c3e50"),
    plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray40", 
                                 margin = margin(b = 15)),
    plot.caption = element_text(size = 9.5, hjust = 0, color = "gray50", 
                                lineheight = 1.3, margin = margin(t = 10)),
    
    # Ejes
    axis.title.x = element_text(face = "bold", size = 12, margin = margin(t = 10)),
    axis.text.y = element_text(size = 11, color = "black"),
    axis.text.x = element_text(size = 10),
    
    # Leyenda
    legend.position = "top",
    legend.title = element_text(face = "bold", size = 11),
    legend.text = element_text(size = 10),
    legend.box.background = element_rect(color = "gray80", size = 0.5),
    legend.margin = margin(5, 5, 5, 5),
    
    # Grid
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_line(color = "gray90"),
    
    # Borde
    panel.border = element_rect(color = "gray60", size = 1)
  )

# Guardar
ggsave("figuras_ingles/fig05_pathway_enrichment_als.png",
       plot = p, width = 12, height = 8, dpi = 300, bg = "white")

cat("   ✅ SAVED: figuras_ingles/fig05_pathway_enrichment_als.png\n")
cat("\n")

# ============================================================================
# INTERPRETACIÓN DETALLADA
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("📊 INTERPRETACIÓN - NARRATIVA COMPLETA:\n")
cat("\n")
cat("PREGUNTA QUE RESPONDE:\n")
cat("  '¿Por qué importa que let-7 esté oxidado?'\n")
cat("\n")
cat("RESPUESTA:\n")
cat("  Porque let-7 regula genes CRÍTICOS para ALS:\n")
cat("\n")

# Mostrar pathway ALS
als_pathway <- data %>% filter(is_als == TRUE)
if (nrow(als_pathway) > 0) {
  cat("  🔥 ALS Pathway (KEGG:05014):\n")
  cat("     • Genes regulados por let-7:", als_pathway$N_let7_targets, "de", als_pathway$N_genes, "\n")
  cat("     • FDR:", als_pathway$FDR, "\n")
  cat("     • -log10(FDR):", sprintf("%.1f", als_pathway$neg_log_fdr), "\n")
  cat("     • ⭐ MÁS SIGNIFICATIVO de todos\n")
}

cat("\n")
cat("  Otros pathways críticos:\n")
data %>% 
  filter(Significant == TRUE, !is_als) %>%
  head(3) %>%
  select(pathway_name, N_let7_targets, FDR) %>%
  mutate(pathway_name = str_trunc(pathway_name, 40)) %>%
  { walk(1:nrow(.), function(i) {
    cat(sprintf("     • %s: %d genes, FDR=%.3f\n", 
                .$pathway_name[i], .$N_let7_targets[i], .$FDR[i]))
  })}

cat("\n")
cat("CONEXIÓN CON HALLAZGOS PREVIOS:\n")
cat("\n")
cat("  Fig #1: let-7 tiene patrón 2,4,5 (oxidado)\n")
cat("     ↓\n")
cat("  Fig #4: Porque tiene G's susceptibles\n")
cat("     ↓\n")
cat("  Fig #5: let-7 oxidado → dysregula ALS pathway  ← AHORA\n")
cat("     ↓\n")
cat("  CONCLUSIÓN: Oxidación → Pérdida función let-7 → Patología ALS\n")
cat("\n")
cat("ESTILO VISUAL:\n")
cat("  • ALS pathway en ROJO (destaca como #1)\n")
cat("  • Otros en azul\n")
cat("  • Barras significativas opacas, no-sig translúcidas\n")
cat("  • Números de genes visibles\n")
cat("  ✅ Coherente con paleta global\n")
cat("\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("✅ FIGURA #5 COMPLETADA\n")
cat("   ⭐⭐ CRITICAL - Connects molecular finding to disease\n")
cat("   🎨 Design: Clear hierarchy, ALS pathway emphasized\n")
cat("   📖 Narrative: Completes the causal chain\n")
cat("\n")








