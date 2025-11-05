# ============================================================================
# PASO 3.4: NETWORK ANALYSIS
# Construye red integrada: miRNA → targets → pathways
# ============================================================================

library(dplyr)
library(tidyr)
library(stringr)
library(igraph)
library(ggraph)
library(ggplot2)

cat("🎯 PASO 3.4: NETWORK ANALYSIS\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

# Cargar datos
targets <- read.csv("data/targets/targets_highconf_combined.csv")
candidates <- readRDS("data/candidates_als.rds")

# Intentar cargar pathways (puede no existir si enrichment falló)
pathways_go <- tryCatch({
  files <- list.files("data/pathways", pattern = "GO_BP.*\\.csv", full.names = TRUE)
  lapply(files, function(f) {
    df <- read.csv(f)
    # Extraer nombre del miRNA del filename
    mirna_name <- basename(f) %>%
      str_remove("GO_BP_") %>%
      str_remove(".csv") %>%
      str_replace_all("_", "-")
    df$miRNA <- mirna_name
    return(df)
  }) %>% bind_rows()
}, error = function(e) data.frame())

cat("📊 Datos cargados:\n")
cat("   Targets:", nrow(targets), "\n")
cat("   Candidatos:", nrow(candidates), "\n")
cat("   GO terms:", nrow(pathways_go), "\n\n")

# ============================================================================
# CREAR EDGES PARA LA RED
# ============================================================================

cat("📊 Creando edges de la red...\n\n")

# EDGES 1: miRNA → Target
edges_mirna_target <- targets %>%
  filter(!is.na(miRNA), !is.na(target_symbol), target_symbol != "") %>%
  dplyr::select(from = miRNA, to = target_symbol, 
         weight = Max_Confidence, n_databases = N_Databases) %>%
  mutate(
    edge_type = "miRNA_to_target",
    from_type = "miRNA",
    to_type = "gene"
  )

cat("   ✅ Edges miRNA → target:", nrow(edges_mirna_target), "\n")

# EDGES 2: Target → Pathway (si hay datos GO)
# SIMPLIFICAR: Solo top 50 pathways por miRNA
edges_target_pathway <- data.frame()

if (nrow(pathways_go) > 0) {
  # Seleccionar solo top pathways
  top_pathways <- pathways_go %>%
    group_by(miRNA) %>%
    slice_min(order_by = p.adjust, n = 50) %>%
    ungroup()
  
  cat("   📊 Usando top 50 pathways por miRNA (total:", nrow(top_pathways), ")\n")
  
  edges_target_pathway <- top_pathways %>%
    separate_rows(geneID, sep = "/") %>%
    filter(!is.na(geneID), geneID != "", !is.na(Description), Description != "") %>%
    dplyr::select(from = geneID, to = Description, padj = p.adjust, miRNA) %>%
    mutate(
      edge_type = "target_to_pathway",
      from_type = "gene",
      to_type = "pathway",
      weight = -log10(padj)
    )
  
  cat("   ✅ Edges target → pathway:", nrow(edges_target_pathway), "\n")
}

# Combinar edges (SIMPLIFICADO: solo miRNA-target para evitar red masiva)
cat("   📊 Simplificando red (solo miRNA → target)...\n")
all_edges <- edges_mirna_target  # Solo miRNA-target por ahora
cat("   ✅ Total edges:", nrow(all_edges), "\n\n")

# ============================================================================
# CREAR NODOS
# ============================================================================

cat("📊 Creando nodos...\n")

# Nodos miRNA
nodes_mirna <- candidates %>%
  mutate(
    node_id = miRNA,
    node_type = "miRNA",
    node_label = miRNA,
    node_size = abs(log2FC) * 10,  # Tamaño por FC
    node_color = "#D62728"  # Rojo ALS
  ) %>%
  dplyr::select(node_id, node_type, node_label, node_size, node_color, log2FC, padj)

# Nodos target
nodes_target <- targets %>%
  filter(!is.na(target_symbol), target_symbol != "") %>%
  group_by(target_symbol) %>%
  summarise(
    n_mirnas = n(),
    max_conf = max(Max_Confidence),
    .groups = "drop"
  ) %>%
  mutate(
    node_id = target_symbol,
    node_type = "gene",
    node_label = target_symbol,
    node_size = n_mirnas * 3,  # Tamaño por # de miRNAs
    node_color = case_when(
      n_mirnas == 3 ~ "#FFD700",  # Oro si es target de los 3
      n_mirnas == 2 ~ "#FFA500",  # Naranja si es de 2
      TRUE ~ "#87CEEB"  # Azul claro si es de 1
    )
  )

# Combinar nodos (SIMPLIFICADO: solo miRNA y genes)
all_nodes <- bind_rows(
  nodes_mirna,
  nodes_target %>% dplyr::select(node_id, node_type, node_label, node_size, node_color)
)

cat("   ✅ Total nodos:", nrow(all_nodes), "\n")
cat("      miRNAs:", sum(all_nodes$node_type == "miRNA"), "\n")
cat("      Genes:", sum(all_nodes$node_type == "gene"), "\n\n")

# ============================================================================
# CREAR GRAFO
# ============================================================================

cat("🕸️  Creando grafo...\n")

# Filtrar edges para que solo incluyan nodos que existen
valid_nodes <- all_nodes$node_id
edges_filtered <- all_edges %>%
  filter(from %in% valid_nodes, to %in% valid_nodes)

cat("   📊 Edges filtrados:", nrow(edges_filtered), "(de", nrow(all_edges), ")\n")

# Crear grafo dirigido
g <- graph_from_data_frame(
  d = edges_filtered %>% dplyr::select(from, to, weight, edge_type),
  vertices = all_nodes,
  directed = TRUE
)

cat("   ✅ Nodos:", vcount(g), "\n")
cat("   ✅ Edges:", ecount(g), "\n\n")

# Calcular métricas de red
cat("📊 Calculando métricas de red...\n")

# Degree (número de conexiones)
node_metrics <- data.frame(
  node_id = V(g)$name,
  degree = degree(g),
  degree_in = degree(g, mode = "in"),
  degree_out = degree(g, mode = "out"),
  betweenness = betweenness(g),
  node_type = V(g)$node_type
)

# Identificar hubs (genes con muchas conexiones)
hub_genes <- node_metrics %>%
  filter(node_type == "gene", degree >= 2) %>%
  arrange(desc(degree))

cat("   ✅ Hub genes (degree >= 2):", nrow(hub_genes), "\n")
if (nrow(hub_genes) > 0) {
  cat("\n🔝 TOP 10 HUB GENES:\n")
  print(head(hub_genes, 10))
}

cat("\n")

# Guardar métricas
write.csv(node_metrics, "data/network/node_metrics.csv", row.names = FALSE)
write.csv(hub_genes, "data/network/hub_genes.csv", row.names = FALSE)

# ============================================================================
# GUARDAR RED
# ============================================================================

cat("💾 Guardando red...\n")

# Edges para export
write.csv(all_edges, "data/network/network_edges.csv", row.names = FALSE)
write.csv(all_nodes, "data/network/network_nodes.csv", row.names = FALSE)

# Formato GraphML (para Cytoscape)
write_graph(g, "data/network/network.graphml", format = "graphml")

cat("   ✅ network_edges.csv\n")
cat("   ✅ network_nodes.csv\n")
cat("   ✅ network.graphml (Cytoscape)\n\n")

# ============================================================================
# RESUMEN
# ============================================================================

cat(paste(rep("=", 70), collapse = ""), "\n")
cat("✅ NETWORK ANALYSIS COMPLETADO\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

cat("🕸️  RED CREADA:\n")
cat("   Nodos:", vcount(g), "(", sum(V(g)$node_type == "miRNA"), "miRNAs +",
    sum(V(g)$node_type == "gene"), "genes +", 
    sum(V(g)$node_type == "pathway"), "pathways )\n")
cat("   Edges:", ecount(g), "\n")
cat("   Hub genes:", nrow(hub_genes), "\n\n")

cat("📁 ARCHIVOS GENERADOS:\n")
cat("   • network_edges.csv\n")
cat("   • network_nodes.csv\n")
cat("   • network.graphml\n")
cat("   • node_metrics.csv\n")
cat("   • hub_genes.csv\n\n")

cat("🚀 SIGUIENTE: Generar figuras\n")
cat("   Rscript scripts/05_create_figures.R\n\n")

# Guardar grafo para siguiente paso
saveRDS(g, "data/network/network_graph.rds")
cat("💾 Grafo guardado en RDS\n")

