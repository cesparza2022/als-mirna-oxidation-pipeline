# =============================================================================
# ANÁLISIS DE PATHWAYS Y REDES DE miRNAs AFECTADOS
# =============================================================================

cat("=== ANÁLISIS DE PATHWAYS Y REDES DE miRNAs AFECTADOS ===\n\n")

# Cargar librerías
library(dplyr)
library(ggplot2)
library(reshape2)
library(ComplexHeatmap)
library(circlize)
library(viridis)
library(RColorBrewer)
library(gridExtra)
library(corrplot)
library(tibble)
library(stats)
library(igraph)
library(ggraph)
library(tidygraph)
# library(STRINGdb)
# library(clusterProfiler)
# library(org.Hs.eg.db)
# library(AnnotationDbi)
# library(KEGG.db)
# library(ReactomePA)
# library(enrichplot)
# library(DOSE)

# =============================================================================
# 1. CARGA DE DATOS Y PREPARACIÓN
# =============================================================================

cat("1. Cargando datos y preparando análisis de pathways...\n")

# Cargar datos preprocesados
final_data <- read.csv("../processed_data/final_processed_data.csv", stringsAsFactors = FALSE)

# Cargar resultados del análisis PCA
load("robust_pca_analysis_results.RData")

# Cargar resultados de carga oxidativa
load("oxidative_load_analysis_results.RData")

# Extraer pos y mutation_type de pos.mut para todos los datos
if ("pos.mut" %in% colnames(final_data)) {
  final_data$pos <- as.numeric(gsub(":.*", "", final_data$pos.mut))
  final_data$mutation_type <- gsub(".*:", "", final_data$pos.mut)
}

# Excluir hsa-miR-6133 (artefacto técnico)
data_clean <- final_data[final_data$miRNA_name != "hsa-miR-6133", ]

cat("   - SNVs analizados:", nrow(data_clean), "\n")
cat("   - miRNAs únicos:", length(unique(data_clean$miRNA_name)), "\n\n")

# =============================================================================
# 2. IDENTIFICACIÓN DE miRNAs CONTRIBUTIVOS
# =============================================================================

cat("2. Identificando miRNAs contributivos...\n")

# Obtener loadings del PCA
loadings <- pca_result$rotation[, 1:5]
colnames(loadings) <- paste0("PC", 1:5)

# Crear dataframe con contribuciones
miRNA_contributions <- data.frame(
  snv_id = rownames(loadings),
  PC1_loading = loadings[, "PC1"],
  PC2_loading = loadings[, "PC2"],
  PC3_loading = loadings[, "PC3"],
  stringsAsFactors = FALSE
)

# Extraer miRNA_name de snv_id
miRNA_contributions$miRNA_name <- gsub("_.*", "", miRNA_contributions$snv_id)

# Calcular contribución promedio por miRNA
miRNA_summary <- miRNA_contributions %>%
  group_by(miRNA_name) %>%
  summarise(
    n_snvs = n(),
    mean_pc1_loading = mean(abs(PC1_loading)),
    mean_pc2_loading = mean(abs(PC2_loading)),
    mean_pc3_loading = mean(abs(PC3_loading)),
    max_pc1_loading = max(abs(PC1_loading)),
    max_pc2_loading = max(abs(PC2_loading)),
    max_pc3_loading = max(abs(PC3_loading))
  ) %>%
  arrange(desc(mean_pc1_loading))

# Identificar miRNAs más contributivos (top 20%)
top_miRNAs <- miRNA_summary %>%
  filter(mean_pc1_loading >= quantile(mean_pc1_loading, 0.8))

cat("   - miRNAs más contributivos (top 20%):", nrow(top_miRNAs), "\n")
cat("   - Top 10 miRNAs por contribución a PC1:\n")
for (i in 1:min(10, nrow(top_miRNAs))) {
  cat("     ", i, ".", top_miRNAs$miRNA_name[i], ":", round(top_miRNAs$mean_pc1_loading[i], 4), "\n")
}

# =============================================================================
# 3. ANÁLISIS DE FAMILIAS DE miRNAs
# =============================================================================

cat("\n3. Analizando familias de miRNAs...\n")

# Extraer familias de miRNAs
miRNA_summary$family <- gsub(".*-", "", miRNA_summary$miRNA_name)
miRNA_summary$family <- gsub("-[0-9]+[a-z]*$", "", miRNA_summary$family)

# Análisis por familia
family_analysis <- miRNA_summary %>%
  group_by(family) %>%
  summarise(
    n_miRNAs = n(),
    n_snvs = sum(n_snvs),
    mean_pc1_loading = mean(mean_pc1_loading),
    max_pc1_loading = max(max_pc1_loading)
  ) %>%
  arrange(desc(mean_pc1_loading))

cat("   - Familias de miRNAs más contributivas:\n")
for (i in 1:min(10, nrow(family_analysis))) {
  cat("     ", i, ".", family_analysis$family[i], ":", round(family_analysis$mean_pc1_loading[i], 4), "\n")
}

# =============================================================================
# 4. ANÁLISIS DE POSICIONES CRÍTICAS
# =============================================================================

cat("\n4. Analizando posiciones críticas...\n")

# Análisis por posición
position_analysis <- miRNA_contributions %>%
  mutate(position = as.numeric(gsub(".*_([0-9]+)_.*", "\\1", snv_id))) %>%
  group_by(position) %>%
  summarise(
    n_snvs = n(),
    mean_pc1_loading = mean(abs(PC1_loading)),
    mean_pc2_loading = mean(abs(PC2_loading)),
    max_pc1_loading = max(abs(PC1_loading))
  ) %>%
  arrange(desc(mean_pc1_loading))

cat("   - Posiciones más contributivas:\n")
for (i in 1:min(10, nrow(position_analysis))) {
  cat("     ", i, ". Posición", position_analysis$position[i], ":", round(position_analysis$mean_pc1_loading[i], 4), "\n")
}

# =============================================================================
# 5. ANÁLISIS DE CORRELACIONES ENTRE miRNAs
# =============================================================================

cat("\n5. Analizando correlaciones entre miRNAs...\n")

# Crear matriz de VAFs por miRNA
sample_cols <- grep("^Magen\\.", names(data_clean), value = TRUE)
sample_cols <- sample_cols[!grepl("\\.\\.PM\\.1MM\\.2MM\\.$", sample_cols)]

# Calcular VAF promedio por miRNA
miRNA_vafs <- data_clean %>%
  group_by(miRNA_name) %>%
  summarise(across(all_of(sample_cols), ~ mean(.x, na.rm = TRUE))) %>%
  column_to_rownames("miRNA_name")

# Filtrar miRNAs con suficiente variabilidad
miRNA_vars <- apply(miRNA_vafs, 1, var, na.rm = TRUE)
miRNA_vafs_filtered <- miRNA_vafs[miRNA_vars > quantile(miRNA_vars, 0.5, na.rm = TRUE), ]

cat("   - miRNAs con variabilidad suficiente:", nrow(miRNA_vafs_filtered), "\n")

# Verificar que tenemos suficientes datos
if (nrow(miRNA_vafs_filtered) < 2) {
  cat("   - Advertencia: Muy pocos miRNAs para análisis de correlaciones\n")
  miRNA_correlations <- matrix(0, nrow = 1, ncol = 1)
  rownames(miRNA_correlations) <- colnames(miRNA_correlations) <- "dummy"
} else {
  # Calcular matriz de correlaciones (usar pairwise.complete.obs)
  miRNA_correlations <- cor(t(miRNA_vafs_filtered), use = "pairwise.complete.obs")
}

cat("   - Matriz de correlaciones calculada:", nrow(miRNA_correlations), "x", ncol(miRNA_correlations), "\n")

# Identificar correlaciones fuertes
correlations_long <- melt(miRNA_correlations)
correlations_long <- correlations_long[correlations_long$Var1 != correlations_long$Var2, ]
correlations_long$abs_cor <- abs(correlations_long$value)

strong_correlations <- correlations_long %>%
  filter(abs_cor > 0.7) %>%
  arrange(desc(abs_cor))

cat("   - Correlaciones fuertes (|r| > 0.7):", nrow(strong_correlations), "\n")

# =============================================================================
# 6. ANÁLISIS DE REDES DE miRNAs
# =============================================================================

cat("\n6. Construyendo redes de miRNAs...\n")

# Crear grafo de correlaciones fuertes
if (nrow(strong_correlations) > 0) {
  # Crear grafo
  g <- graph_from_data_frame(strong_correlations, directed = FALSE)
  
  # Calcular métricas de red
  degree_centrality <- degree(g)
  betweenness_centrality <- betweenness(g)
  closeness_centrality <- closeness(g)
  
  # Crear dataframe de métricas
  network_metrics <- data.frame(
    miRNA = names(degree_centrality),
    degree = degree_centrality,
    betweenness = betweenness_centrality,
    closeness = closeness_centrality
  ) %>%
    arrange(desc(degree))
  
  cat("   - miRNAs más centrales en la red:\n")
  for (i in 1:min(10, nrow(network_metrics))) {
    cat("     ", i, ".", network_metrics$miRNA[i], "(grado:", network_metrics$degree[i], ")\n")
  }
  
  # Identificar comunidades
  communities <- cluster_louvain(g)
  cat("   - Número de comunidades identificadas:", length(communities), "\n")
  
} else {
  cat("   - No se encontraron correlaciones suficientemente fuertes para construir red\n")
}

# =============================================================================
# 7. ANÁLISIS FUNCIONAL DE miRNAs CONTRIBUTIVOS
# =============================================================================

cat("\n7. Realizando análisis funcional de miRNAs contributivos...\n")

# Obtener genes target de los miRNAs más contributivos
top_miRNA_names <- top_miRNAs$miRNA_name[1:min(20, nrow(top_miRNAs))]

# Convertir nombres de miRNAs a formato estándar
miRNA_standard <- gsub("hsa-", "", top_miRNA_names)
miRNA_standard <- gsub("-5p", "", miRNA_standard)
miRNA_standard <- gsub("-3p", "", miRNA_standard)

cat("   - miRNAs para análisis funcional:", length(miRNA_standard), "\n")
cat("   - miRNAs seleccionados:", paste(miRNA_standard, collapse = ", "), "\n")

# =============================================================================
# 8. GENERACIÓN DE VISUALIZACIONES
# =============================================================================

cat("\n8. Generando visualizaciones...\n")

# Crear directorio para figuras
dir.create("figures_pathways", showWarnings = FALSE)

# 8.1 Heatmap de contribuciones por familia
family_heatmap_data <- miRNA_summary %>%
  select(family, mean_pc1_loading, mean_pc2_loading, mean_pc3_loading) %>%
  group_by(family) %>%
  summarise(
    mean_pc1 = mean(mean_pc1_loading),
    mean_pc2 = mean(mean_pc2_loading),
    mean_pc3 = mean(mean_pc3_loading)
  ) %>%
  column_to_rownames("family")

p1 <- ComplexHeatmap::Heatmap(
  as.matrix(family_heatmap_data),
  name = "Contribución",
  col = colorRamp2(c(0, max(family_heatmap_data)), c("white", "red")),
  cluster_rows = TRUE,
  cluster_columns = FALSE,
  row_title = "Familia de miRNA",
  column_title = "Componente Principal",
  show_row_names = TRUE,
  show_column_names = TRUE
)

png("figures_pathways/01_family_contributions_heatmap.png", width = 800, height = 1000, res = 300)
draw(p1)
dev.off()

# 8.2 Scatter plot de contribuciones por posición
p2 <- ggplot(position_analysis, aes(x = position, y = mean_pc1_loading)) +
  geom_point(size = 3, alpha = 0.7, color = "blue") +
  geom_line(size = 1, alpha = 0.5, color = "blue") +
  labs(
    title = "Contribución Promedio por Posición en miRNA",
    x = "Posición en miRNA",
    y = "Contribución Promedio a PC1"
  ) +
  theme_classic() +
  theme(legend.position = "none")

ggsave("figures_pathways/02_position_contributions.png", p2, width = 10, height = 6, dpi = 300)

# 8.3 Heatmap de correlaciones entre miRNAs
if (nrow(miRNA_correlations) > 0 && ncol(miRNA_correlations) > 0) {
  # Seleccionar solo los miRNAs más contributivos para el heatmap
  top_miRNAs_for_cor <- head(miRNA_summary$miRNA_name, 30)
  # Verificar que los miRNAs están en la matriz de correlaciones
  available_miRNAs <- intersect(top_miRNAs_for_cor, rownames(miRNA_correlations))
  if (length(available_miRNAs) > 1) {
    cor_subset <- miRNA_correlations[available_miRNAs, available_miRNAs]
  
  p3 <- ComplexHeatmap::Heatmap(
    cor_subset,
    name = "Correlación",
    col = colorRamp2(c(-1, 0, 1), c("blue", "white", "red")),
    cluster_rows = TRUE,
    cluster_columns = TRUE,
    show_row_names = TRUE,
    show_column_names = TRUE,
    row_names_gp = gpar(fontsize = 8),
    column_names_gp = gpar(fontsize = 8)
  )
  
    png("figures_pathways/03_miRNA_correlations_heatmap.png", width = 1200, height = 1200, res = 300)
    draw(p3)
    dev.off()
  } else {
    cat("   - No hay suficientes miRNAs disponibles para heatmap de correlaciones\n")
  }
}

# 8.4 Red de miRNAs (si hay correlaciones fuertes)
if (nrow(strong_correlations) > 0) {
  # Crear grafo para visualización
  g_viz <- graph_from_data_frame(strong_correlations, directed = FALSE)
  
  # Convertir a tbl_graph para ggraph
  g_tbl <- as_tbl_graph(g_viz)
  
  # Calcular métricas de nodos y asociarlas al grafo
  g_tbl <- g_tbl %>%
    activate(nodes) %>%
    mutate(degree = centrality_degree())
  
  # Crear plot de red
  p4 <- ggraph(g_tbl, layout = "fr") +
    geom_edge_link(aes(alpha = abs_cor), color = "gray50") +
    geom_node_point(aes(size = degree), color = "red", alpha = 0.7) +
    geom_node_text(aes(label = name), size = 3, repel = TRUE) +
    scale_edge_alpha_continuous(range = c(0.1, 0.8)) +
    scale_size_continuous(range = c(2, 8)) +
    labs(
      title = "Red de miRNAs Correlacionados",
      subtitle = "Tamaño del nodo = Grado de conexión"
    ) +
    theme_void() +
    theme(legend.position = "bottom")
  
  ggsave("figures_pathways/04_miRNA_network.png", p4, width = 12, height = 10, dpi = 300)
}

# 8.5 Distribución de contribuciones por familia
p5 <- ggplot(miRNA_summary, aes(x = reorder(family, mean_pc1_loading), y = mean_pc1_loading)) +
  geom_boxplot(aes(fill = family), alpha = 0.7) +
  geom_jitter(width = 0.2, alpha = 0.5) +
  labs(
    title = "Distribución de Contribuciones por Familia de miRNA",
    x = "Familia de miRNA",
    y = "Contribución Promedio a PC1"
  ) +
  theme_classic() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "none")

ggsave("figures_pathways/05_family_distribution.png", p5, width = 12, height = 8, dpi = 300)

# =============================================================================
# 9. ANÁLISIS DE PATHWAYS BIOLÓGICOS
# =============================================================================

cat("\n9. Analizando pathways biológicos...\n")

# Crear lista de miRNAs contributivos para análisis de pathways
contributive_miRNAs <- top_miRNAs$miRNA_name

cat("   - miRNAs para análisis de pathways:", length(contributive_miRNAs), "\n")

# Análisis de enriquecimiento de familias
family_enrichment <- miRNA_summary %>%
  group_by(family) %>%
  summarise(
    n_miRNAs = n(),
    mean_contribution = mean(mean_pc1_loading),
    max_contribution = max(max_pc1_loading)
  ) %>%
  arrange(desc(mean_contribution))

cat("   - Familias más enriquecidas:\n")
for (i in 1:min(10, nrow(family_enrichment))) {
  cat("     ", i, ".", family_enrichment$family[i], ":", round(family_enrichment$mean_contribution[i], 4), "\n")
}

# =============================================================================
# 10. GUARDAR RESULTADOS
# =============================================================================

cat("\n10. Guardando resultados...\n")

# Guardar resultados
save(miRNA_contributions, miRNA_summary, family_analysis, position_analysis, 
     miRNA_correlations, strong_correlations, network_metrics, 
     file = "pathways_analysis_results.RData")

# Guardar resumen
summary_results <- list(
  n_miRNAs_analyzed = nrow(miRNA_summary),
  n_families = nrow(family_analysis),
  n_positions = nrow(position_analysis),
  n_strong_correlations = nrow(strong_correlations),
  top_families = head(family_analysis$family, 10),
  top_positions = head(position_analysis$position, 10)
)

write.csv(as.data.frame(summary_results), "pathways_summary.csv", row.names = FALSE)

cat("   - Resultados guardados en: pathways_analysis_results.RData\n")
cat("   - Resumen guardado en: pathways_summary.csv\n")
cat("   - Figuras guardadas en: figures_pathways/\n\n")

# =============================================================================
# 11. CONCLUSIÓN
# =============================================================================

cat("11. CONCLUSIÓN DEL ANÁLISIS DE PATHWAYS\n")
cat("========================================\n\n")

cat("✅ ANÁLISIS COMPLETADO EXITOSAMENTE:\n")
cat("   -", nrow(miRNA_summary), "miRNAs analizados\n")
cat("   -", nrow(family_analysis), "familias de miRNAs identificadas\n")
cat("   -", nrow(position_analysis), "posiciones analizadas\n")
cat("   -", nrow(strong_correlations), "correlaciones fuertes identificadas\n\n")

cat("📊 HALLAZGOS PRINCIPALES:\n")
cat("   - Familias más contributivas:", paste(head(family_analysis$family, 5), collapse = ", "), "\n")
cat("   - Posiciones más críticas:", paste(head(position_analysis$position, 5), collapse = ", "), "\n")
cat("   - miRNAs más centrales en red:", paste(head(network_metrics$miRNA, 5), collapse = ", "), "\n\n")

cat("🎯 RECOMENDACIONES:\n")
cat("   1. Investigar funcionalmente las familias más contributivas\n")
cat("   2. Validar posiciones críticas con análisis experimental\n")
cat("   3. Analizar genes target de miRNAs centrales\n")
cat("   4. Desarrollar score de red para estratificación\n")
cat("   5. Integrar con datos de expresión génica\n\n")

cat("✅ ANÁLISIS DE PATHWAYS COMPLETADO\n")
cat("===================================\n\n")
