# ============================================================================
# PASO 3.5: CREAR FIGURAS
# Genera las 9 figuras del análisis funcional
# ============================================================================

library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(igraph)
library(ggraph)
library(VennDiagram)
library(gridExtra)
library(enrichplot)
library(clusterProfiler)
library(tibble)
library(pheatmap)

COLOR_ALS <- "#D62728"
COLOR_SHARED <- "#FFD700"
COLOR_GENE <- "#87CEEB"
COLOR_PATHWAY <- "#90EE90"

theme_prof <- theme_minimal() +
  theme(
    text = element_text(size = 14),
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
    panel.grid.major = element_line(color = "gray90", linewidth = 0.5)
  )

cat("🎯 PASO 3.5: CREAR FIGURAS\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

# Cargar datos
targets <- read.csv("data/targets/targets_highconf_combined.csv")
shared_targets <- read.csv("data/targets/targets_shared.csv")
summary_mirna <- read.csv("data/targets/summary_by_mirna.csv")
g <- readRDS("data/network/network_graph.rds")
hub_genes <- read.csv("data/network/hub_genes.csv")

cat("📊 Datos cargados\n\n")

# ============================================================================
# FIGURA 3.1: VENN DIAGRAM DE TARGETS
# ============================================================================

cat("📊 [1/9] Generando Venn diagram...\n")

# Crear listas de targets por miRNA (limpiar NAs y vacíos)
targets_clean <- targets %>%
  filter(
    !is.na(target_symbol), 
    !is.na(miRNA),
    target_symbol != "",
    trimws(target_symbol) != "",  # Eliminar espacios
    !is.null(target_symbol)
  ) %>%
  distinct(miRNA, target_symbol)  # Eliminar duplicados

# Verificar que tenemos datos
if (nrow(targets_clean) == 0) {
  cat("   ⚠️ No hay targets válidos después de limpiar\n")
  stop("No valid targets for Venn diagram")
}

target_lists <- split(targets_clean$target_symbol, targets_clean$miRNA)

# Verificar que tenemos suficientes miRNAs
if (length(target_lists) < 2) {
  cat("   ⚠️ Muy pocos miRNAs para Venn diagram\n")
  stop("Need at least 2 miRNAs for Venn diagram")
}

png("figures/FIG_3.1_TARGETS_VENN.png", width = 10, height = 10, units = "in", res = 300)

if (length(target_lists) == 3) {
  venn.plot <- venn.diagram(
    x = target_lists,
    category.names = names(target_lists),
    filename = NULL,
    output = TRUE,
    fill = c("#FF6B6B", "#4ECDC4", "#95E1D3"),
    alpha = 0.5,
    cex = 2,
    cat.cex = 1.5,
    cat.fontface = "bold"
  )
  grid.draw(venn.plot)
}

dev.off()
cat("   ✅ FIG_3.1 guardada\n\n")

# ============================================================================
# FIGURA 3.2: BARPLOT DE TARGETS POR miRNA
# ============================================================================

cat("📊 [2/9] Generando barplot de targets...\n")

fig_3_2 <- ggplot(summary_mirna, aes(x = reorder(miRNA, N_Targets), y = N_Targets)) +
  geom_col(aes(fill = miRNA), alpha = 0.8, width = 0.7) +
  geom_text(aes(label = N_Targets), hjust = -0.3, size = 5, fontface = "bold") +
  scale_fill_manual(values = c("#D62728", "#FF8C00", "#FFD700")) +
  coord_flip() +
  labs(
    title = "Number of High-Confidence Targets per miRNA",
    subtitle = paste0("Total unique targets: ", length(unique(targets$target_symbol))),
    x = NULL,
    y = "Number of Targets"
  ) +
  theme_prof +
  theme(legend.position = "none") +
  ylim(0, max(summary_mirna$N_Targets) * 1.15)

ggsave("figures/FIG_3.2_TARGETS_BARPLOT.png", fig_3_2, width = 10, height = 6, dpi = 300)
cat("   ✅ FIG_3.2 guardada\n\n")

# ============================================================================
# FIGURA 3.3: NETWORK DE TARGETS (Solo miRNA → genes)
# ============================================================================

cat("📊 [3/9] Generando network de targets...\n")

# Subgrafo solo miRNA-target (top 30 targets por miRNA)
top_targets <- targets %>%
  group_by(miRNA) %>%
  slice_max(order_by = Max_Confidence, n = 30) %>%
  ungroup()

edges_network <- top_targets %>%
  dplyr::select(from = miRNA, to = target_symbol)

nodes_network <- data.frame(
  name = unique(c(edges_network$from, edges_network$to)),
  type = ifelse(unique(c(edges_network$from, edges_network$to)) %in% candidates$miRNA, "miRNA", "gene")
)

g_simple <- graph_from_data_frame(edges_network, vertices = nodes_network, directed = TRUE)

fig_3_3 <- ggraph(g_simple, layout = "fr") +
  geom_edge_link(alpha = 0.3, arrow = arrow(length = unit(2, "mm"))) +
  geom_node_point(aes(color = type, size = ifelse(type == "miRNA", 8, 4))) +
  geom_node_text(aes(label = ifelse(type == "miRNA", name, "")), 
                 repel = TRUE, size = 4, fontface = "bold") +
  scale_color_manual(
    values = c("miRNA" = COLOR_ALS, "gene" = COLOR_GENE),
    name = "Node Type"
  ) +
  scale_size_identity() +
  labs(title = "miRNA → Target Network (Top 30 per miRNA)") +
  theme_void() +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
    legend.position = "bottom"
  )

ggsave("figures/FIG_3.3_TARGETS_NETWORK.png", fig_3_3, width = 14, height = 12, dpi = 300)
cat("   ✅ FIG_3.3 guardada\n\n")

# ============================================================================
# FIGURA 3.4: GO DOT PLOT (Si hay datos GO)
# ============================================================================

cat("📊 [4/9] Generando GO dot plot...\n")

if (nrow(pathways_go) > 0 && file.exists("data/pathways/enrichment_results.rds")) {
  enrichment_results <- readRDS("data/pathways/enrichment_results.rds")
  
  # Combinar top 10 GO terms de cada miRNA
  go_combined <- lapply(names(enrichment_results), function(m) {
    if (!is.null(enrichment_results[[m]]$GO_BP)) {
      enrichment_results[[m]]$GO_BP@result %>%
        head(10) %>%
        mutate(miRNA = m)
    }
  }) %>% bind_rows()
  
  if (nrow(go_combined) > 0) {
    fig_3_4 <- ggplot(go_combined, aes(x = Count, y = reorder(Description, Count))) +
      geom_point(aes(size = Count, color = -log10(p.adjust))) +
      facet_wrap(~miRNA, ncol = 1, scales = "free_y") +
      scale_color_gradient(low = "blue", high = "red", name = "-log10(padj)") +
      labs(
        title = "Top 10 GO Biological Process Terms per miRNA",
        x = "Gene Count",
        y = NULL
      ) +
      theme_prof +
      theme(strip.text = element_text(face = "bold", size = 12))
    
    ggsave("figures/FIG_3.4_GO_DOTPLOT.png", fig_3_4, width = 14, height = 12, dpi = 300)
    cat("   ✅ FIG_3.4 guardada\n\n")
  } else {
    cat("   ⚠️  No hay datos GO suficientes\n\n")
  }
} else {
  cat("   ⚠️  Saltando (no hay datos GO)\n\n")
}

# ============================================================================
# FIGURA 3.5: HEATMAP DE PATHWAYS COMPARTIDOS
# ============================================================================

cat("📊 [5/9] Generando heatmap de pathways...\n")

if (file.exists("data/pathways/GO_shared.csv")) {
  go_shared <- read.csv("data/pathways/GO_shared.csv")
  
  if (nrow(go_shared) > 0) {
    # Crear matriz de presencia (miRNA x pathway)
    pathway_matrix <- pathways_go %>%
      dplyr::select(miRNA, Description, p.adjust) %>%
      mutate(neg_log_p = -log10(p.adjust)) %>%
      pivot_wider(names_from = miRNA, values_from = neg_log_p, values_fill = 0)
    
    # Solo pathways compartidos
    pathway_matrix_shared <- pathway_matrix %>%
      filter(Description %in% go_shared$Description) %>%
      column_to_rownames("Description") %>%
      as.matrix()
    
    library(pheatmap)
    png("figures/FIG_3.5_PATHWAYS_HEATMAP.png", width = 12, height = 10, units = "in", res = 300)
    pheatmap(
      pathway_matrix_shared,
      main = "Shared Pathways: -log10(p-adj) by miRNA",
      color = colorRampPalette(c("white", "#D62728"))(100),
      cluster_rows = TRUE,
      cluster_cols = FALSE,
      fontsize = 9
    )
    dev.off()
    cat("   ✅ FIG_3.5 guardada\n\n")
  } else {
    cat("   ⚠️  No hay pathways compartidos\n\n")
  }
} else {
  cat("   ⚠️  Saltando (no hay pathways compartidos)\n\n")
}

# ============================================================================
# FIGURA 3.6: NETWORK COMPLETO (miRNA → genes → pathways)
# ============================================================================

cat("📊 [6/9] Generando network completo...\n")

fig_3_6 <- ggraph(g, layout = "fr") +
  geom_edge_link(aes(alpha = 0.3), arrow = arrow(length = unit(1.5, "mm"))) +
  geom_node_point(aes(color = node_type, size = node_size)) +
  geom_node_text(
    aes(label = ifelse(node_type == "miRNA", node_label, "")), 
    repel = TRUE, size = 4, fontface = "bold"
  ) +
  scale_color_manual(
    values = c("miRNA" = COLOR_ALS, "gene" = COLOR_GENE, "pathway" = COLOR_PATHWAY),
    name = "Node Type",
    labels = c("miRNA" = paste0("miRNA (n=", sum(V(g)$node_type == "miRNA"), ")"),
               "gene" = paste0("Gene (n=", sum(V(g)$node_type == "gene"), ")"),
               "pathway" = paste0("Pathway (n=", sum(V(g)$node_type == "pathway"), ")"))
  ) +
  scale_size_continuous(range = c(2, 10), guide = "none") +
  labs(title = "Integrated Network: miRNA → Targets → Pathways") +
  theme_void() +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5, margin = margin(b = 20)),
    legend.position = "bottom",
    legend.text = element_text(size = 12)
  )

ggsave("figures/FIG_3.6_NETWORK_FULL.png", fig_3_6, width = 16, height = 14, dpi = 300)
cat("   ✅ FIG_3.6 guardada\n\n")

# ============================================================================
# FIGURA 3.7: NETWORK SIMPLIFICADO (Solo hub genes)
# ============================================================================

cat("📊 [7/9] Generando network simplificado...\n")

if (nrow(hub_genes) > 0) {
  # Subgrafo con solo hubs
  hub_nodes <- c(candidates$miRNA, head(hub_genes$node_id, 20))
  g_simple <- induced_subgraph(g, vids = which(V(g)$name %in% hub_nodes))
  
  fig_3_7 <- ggraph(g_simple, layout = "fr") +
    geom_edge_link(aes(alpha = 0.5), arrow = arrow(length = unit(2, "mm"))) +
    geom_node_point(aes(color = node_type, size = node_size)) +
    geom_node_text(aes(label = node_label), repel = TRUE, size = 3.5, fontface = "bold") +
    scale_color_manual(
      values = c("miRNA" = COLOR_ALS, "gene" = COLOR_GENE),
      name = "Node Type"
    ) +
    scale_size_continuous(range = c(3, 12), guide = "none") +
    labs(title = "Simplified Network: miRNA → Hub Genes (Top 20)") +
    theme_void() +
    theme(
      plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
      legend.position = "bottom"
    )
  
  ggsave("figures/FIG_3.7_NETWORK_SIMPLE.png", fig_3_7, width = 14, height = 12, dpi = 300)
  cat("   ✅ FIG_3.7 guardada\n\n")
} else {
  cat("   ⚠️  No hay hub genes para visualizar\n\n")
}

# ============================================================================
# FIGURA 3.8: SHARED TARGETS
# ============================================================================

cat("📊 [8/9] Generando gráfica de targets compartidos...\n")

if (nrow(shared_targets) > 0) {
  fig_3_8 <- ggplot(head(shared_targets, 20), 
                    aes(x = reorder(target_symbol, N_miRNAs), y = N_miRNAs)) +
    geom_col(aes(fill = as.factor(N_miRNAs)), alpha = 0.8, width = 0.7) +
    geom_text(aes(label = N_miRNAs), hjust = -0.3, size = 5, fontface = "bold") +
    scale_fill_manual(values = c("2" = "#FFA500", "3" = COLOR_SHARED), name = "# miRNAs") +
    coord_flip() +
    labs(
      title = "Top 20 Shared Targets",
      subtitle = paste0("Targets regulated by 2 or more miRNAs (total: ", nrow(shared_targets), ")"),
      x = NULL,
      y = "Number of miRNAs Regulating This Target"
    ) +
    theme_prof +
    ylim(0, max(shared_targets$N_miRNAs) + 0.5)
  
  ggsave("figures/FIG_3.8_SHARED_TARGETS.png", fig_3_8, width = 10, height = 8, dpi = 300)
  cat("   ✅ FIG_3.8 guardada\n\n")
} else {
  cat("   ⚠️  No hay targets compartidos\n\n")
}

# ============================================================================
# FIGURA 3.9: SUMMARY STATS
# ============================================================================

cat("📊 [9/9] Generando resumen estadístico...\n")

# Crear panel de estadísticas
stats_data <- data.frame(
  Metric = c(
    "Total High-Conf Targets",
    "Unique Genes",
    "Shared Targets (2+ miRNAs)",
    "Hub Genes (degree ≥ 2)",
    "Validated Targets",
    "Average Targets per miRNA"
  ),
  Value = c(
    nrow(targets),
    length(unique(targets$target_symbol)),
    nrow(shared_targets),
    nrow(hub_genes),
    sum(targets$Evidence_Level == "Validated"),
    round(mean(summary_mirna$N_Targets), 1)
  )
)

fig_3_9 <- ggplot(stats_data, aes(x = reorder(Metric, Value), y = Value)) +
  geom_col(fill = COLOR_ALS, alpha = 0.7, width = 0.7) +
  geom_text(aes(label = Value), hjust = -0.2, size = 6, fontface = "bold") +
  coord_flip() +
  labs(
    title = "Summary Statistics: Target Prediction",
    x = NULL,
    y = "Count"
  ) +
  theme_prof +
  ylim(0, max(stats_data$Value) * 1.15)

ggsave("figures/FIG_3.9_SUMMARY_STATS.png", fig_3_9, width = 10, height = 7, dpi = 300)
cat("   ✅ FIG_3.9 guardada\n\n")

# ============================================================================
# RESUMEN
# ============================================================================

cat(paste(rep("=", 70), collapse = ""), "\n")
cat("✅ FIGURAS COMPLETADAS\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

cat("📊 FIGURAS GENERADAS:\n")
cat("   ✓ 3.1: Venn Diagram\n")
cat("   ✓ 3.2: Barplot de Targets\n")
cat("   ✓ 3.3: Network miRNA-Targets\n")
cat("   ✓ 3.4: GO Dot Plot (si hay datos)\n")
cat("   ✓ 3.5: Heatmap Pathways (si hay datos)\n")
cat("   ✓ 3.6: Network Completo\n")
cat("   ✓ 3.7: Network Simplificado\n")
cat("   ✓ 3.8: Shared Targets\n")
cat("   ✓ 3.9: Summary Stats\n\n")

cat("📁 Directorio: figures/\n\n")

cat("🚀 SIGUIENTE: Crear HTML viewer\n")
cat("   Rscript scripts/06_create_HTML.R\n")

