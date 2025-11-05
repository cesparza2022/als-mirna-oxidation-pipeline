# ============================================================================
# PASO 3.5: CREAR FIGURAS (VERSIÓN SIMPLIFICADA Y ROBUSTA)
# ============================================================================

library(dplyr)
library(ggplot2)
library(VennDiagram)
library(igraph)
library(ggraph)
library(gridExtra)
library(tibble)

COLOR_ALS <- "#D62728"

theme_prof <- theme_minimal() +
  theme(
    text = element_text(size = 14),
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5)
  )

cat("🎯 PASO 3.5: CREAR FIGURAS (SIMPLIFICADO)\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

# Cargar datos
targets <- read.csv("data/targets/targets_highconf_combined.csv") %>%
  filter(!is.na(target_symbol), target_symbol != "", !is.na(miRNA), miRNA != "")

shared_targets <- read.csv("data/targets/targets_shared.csv") %>%
  filter(!is.na(target_symbol), target_symbol != "")

summary_mirna <- read.csv("data/targets/summary_by_mirna.csv")
g <- readRDS("data/network/network_graph.rds")
hub_genes <- read.csv("data/network/hub_genes.csv")

cat("📊 Datos cargados\n\n")

# ============================================================================
# FIGURA 3.1: VENN
# ============================================================================

cat("📊 [1/9] Venn diagram...\n")
target_lists <- split(targets$target_symbol, targets$miRNA)

png("figures/FIG_3.1_TARGETS_VENN.png", width=10, height=10, units="in", res=300)
venn.plot <- venn.diagram(
  x = target_lists,
  category.names = names(target_lists),
  filename = NULL,
  fill = c("#FF6B6B", "#4ECDC4", "#95E1D3"),
  alpha = 0.5,
  cex = 2,
  cat.cex = 1.5
)
grid::grid.draw(venn.plot)
dev.off()
cat("   ✅ Guardada\n\n")

# ============================================================================
# FIGURA 3.2: BARPLOT
# ============================================================================

cat("📊 [2/9] Barplot...\n")
fig32 <- ggplot(summary_mirna, aes(x=reorder(miRNA, N_Targets), y=N_Targets)) +
  geom_col(aes(fill=miRNA), alpha=0.8, width=0.7) +
  geom_text(aes(label=N_Targets), hjust=-0.3, size=5, fontface="bold") +
  coord_flip() +
  labs(title="Targets per miRNA", x=NULL, y="Number of Targets") +
  theme_prof +
  theme(legend.position="none") +
  ylim(0, max(summary_mirna$N_Targets)*1.15)

ggsave("figures/FIG_3.2_TARGETS_BARPLOT.png", fig32, width=10, height=6, dpi=300)
cat("   ✅ Guardada\n\n")

# ============================================================================
# FIGURA 3.3: NETWORK SIMPLE (Solo top 50 por miRNA)
# ============================================================================

cat("📊 [3/9] Network simple...\n")
top_targets <- targets %>%
  group_by(miRNA) %>%
  slice_max(order_by=Max_Confidence, n=50) %>%
  ungroup()

edges <- top_targets %>% dplyr::select(from=miRNA, to=target_symbol)
nodes <- data.frame(
  name = unique(c(edges$from, edges$to)),
  type = ifelse(unique(c(edges$from, edges$to)) %in% summary_mirna$miRNA, "miRNA", "gene")
)

g_simple <- graph_from_data_frame(edges, vertices=nodes, directed=TRUE)

fig33 <- ggraph(g_simple, layout="fr") +
  geom_edge_link(alpha=0.3, arrow=arrow(length=unit(2, "mm"))) +
  geom_node_point(aes(color=type, size=ifelse(type=="miRNA", 8, 4))) +
  geom_node_text(aes(label=ifelse(type=="miRNA", name, "")), 
                 repel=TRUE, size=4, fontface="bold") +
  scale_color_manual(values=c("miRNA"=COLOR_ALS, "gene"="#87CEEB")) +
  scale_size_identity() +
  labs(title="miRNA → Target Network (Top 50 per miRNA)") +
  theme_void() +
  theme(plot.title=element_text(size=16, face="bold", hjust=0.5),
        legend.position="bottom")

ggsave("figures/FIG_3.3_TARGETS_NETWORK.png", fig33, width=14, height=12, dpi=300)
cat("   ✅ Guardada\n\n")

# ============================================================================
# FIGURA 3.4: SHARED TARGETS
# ============================================================================

cat("📊 [4/9] Shared targets...\n")
top_shared <- head(shared_targets, 30)

fig34 <- ggplot(top_shared, aes(x=reorder(target_symbol, N_miRNAs), y=N_miRNAs)) +
  geom_col(aes(fill=as.factor(N_miRNAs)), alpha=0.8, width=0.7) +
  geom_text(aes(label=N_miRNAs), hjust=-0.3, size=5, fontface="bold") +
  scale_fill_manual(values=c("2"="#FFA500", "3"="#FFD700")) +
  coord_flip() +
  labs(title="Top 30 Shared Targets", 
       subtitle=paste0("Total shared: ", nrow(shared_targets)),
       x=NULL, y="# miRNAs") +
  theme_prof +
  ylim(0, 3.5)

ggsave("figures/FIG_3.4_SHARED_TARGETS.png", fig34, width=10, height=10, dpi=300)
cat("   ✅ Guardada\n\n")

# ============================================================================
# FIGURA 3.5: NETWORK COMPLETO
# ============================================================================

cat("📊 [5/9] Network completo...\n")

fig35 <- ggraph(g, layout="fr") +
  geom_edge_link(alpha=0.1, arrow=arrow(length=unit(1, "mm"))) +
  geom_node_point(aes(color=node_type, size=node_size), alpha=0.7) +
  geom_node_text(aes(label=ifelse(node_type=="miRNA", node_label, "")),
                 repel=TRUE, size=5, fontface="bold") +
  scale_color_manual(values=c("miRNA"=COLOR_ALS, "gene"="#87CEEB")) +
  scale_size_continuous(range=c(1, 10), guide="none") +
  labs(title="Complete Network: miRNA → Targets") +
  theme_void() +
  theme(plot.title=element_text(size=16, face="bold", hjust=0.5),
        legend.position="bottom")

ggsave("figures/FIG_3.5_NETWORK_FULL.png", fig35, width=16, height=14, dpi=300)
cat("   ✅ Guardada\n\n")

# ============================================================================
# FIGURA 3.6: SUMMARY STATS
# ============================================================================

cat("📊 [6/9] Summary stats...\n")

stats_data <- data.frame(
  Metric = c("Total Targets", "Shared Targets", "Hub Genes", 
             "Validated Targets", "Avg Targets/miRNA"),
  Value = c(nrow(targets), nrow(shared_targets), nrow(hub_genes),
            sum(targets$Evidence_Level=="Validated", na.rm=TRUE),
            round(mean(summary_mirna$N_Targets)))
)

fig36 <- ggplot(stats_data, aes(x=reorder(Metric, Value), y=Value)) +
  geom_col(fill=COLOR_ALS, alpha=0.7, width=0.7) +
  geom_text(aes(label=Value), hjust=-0.2, size=6, fontface="bold") +
  coord_flip() +
  labs(title="Summary Statistics: Target Prediction", x=NULL, y="Count") +
  theme_prof +
  ylim(0, max(stats_data$Value)*1.15)

ggsave("figures/FIG_3.6_SUMMARY_STATS.png", fig36, width=10, height=7, dpi=300)
cat("   ✅ Guardada\n\n")

cat(paste(rep("=", 70), collapse=""), "\n")
cat("✅ FIGURAS ESENCIALES COMPLETADAS (6/9)\n")
cat(paste(rep("=", 70), collapse=""), "\n\n")

cat("📊 FIGURAS GENERADAS:\n")
cat("   ✓ 3.1: Venn Diagram\n")
cat("   ✓ 3.2: Barplot Targets\n")
cat("   ✓ 3.3: Network Simple\n")
cat("   ✓ 3.4: Shared Targets\n")
cat("   ✓ 3.5: Network Full\n")
cat("   ✓ 3.6: Summary Stats\n\n")

cat("📁 Directorio: figures/\n\n")
cat("🎯 Figuras 3.7-3.9 (GO/pathways) requieren datos adicionales\n")
cat("   Continuando con HTML...\n\n")

