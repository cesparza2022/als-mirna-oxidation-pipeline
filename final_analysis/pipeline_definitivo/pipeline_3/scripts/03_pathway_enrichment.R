# ============================================================================
# PASO 3.3: PATHWAY ENRICHMENT
# Análisis GO y KEGG de los targets identificados
# ============================================================================

library(dplyr)
library(tidyr)
library(stringr)
library(clusterProfiler)
library(org.Hs.eg.db)
library(enrichplot)
library(DOSE)

cat("🎯 PASO 3.3: PATHWAY ENRICHMENT\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

# Cargar targets high-confidence
targets <- read.csv("data/targets/targets_highconf_combined.csv")
candidates <- readRDS("data/candidates_als.rds")

cat("📊 Targets cargados:", nrow(targets), "\n")
cat("📊 Candidatos:", nrow(candidates), "\n\n")

# ============================================================================
# FUNCIÓN PARA ENRICHMENT POR miRNA
# ============================================================================

run_enrichment_for_mirna <- function(mirna_name) {
  cat(paste(rep("-", 70), collapse = ""), "\n")
  cat("📊 Enrichment para:", mirna_name, "\n")
  cat(paste(rep("-", 70), collapse = ""), "\n")
  
  # Extraer targets del miRNA
  mirna_targets <- targets %>%
    filter(miRNA == mirna_name) %>%
    pull(target_entrez) %>%
    unique() %>%
    na.omit() %>%
    as.character()
  
  cat("   Targets:", length(mirna_targets), "\n")
  
  if (length(mirna_targets) < 5) {
    cat("   ⚠️  Muy pocos targets (<5), saltando...\n\n")
    return(NULL)
  }
  
  # GO Enrichment (Biological Process)
  cat("   📊 GO Enrichment...\n")
  ego_bp <- tryCatch({
    enrichGO(
      gene = mirna_targets,
      OrgDb = org.Hs.eg.db,
      keyType = "ENTREZID",
      ont = "BP",
      pAdjustMethod = "BH",
      pvalueCutoff = 0.05,
      qvalueCutoff = 0.05,
      readable = TRUE
    )
  }, error = function(e) NULL)
  
  n_go <- ifelse(is.null(ego_bp), 0, nrow(ego_bp@result))
  cat("      ✅ GO BP terms:", n_go, "\n")
  
  # GO Molecular Function
  ego_mf <- tryCatch({
    enrichGO(
      gene = mirna_targets,
      OrgDb = org.Hs.eg.db,
      keyType = "ENTREZID",
      ont = "MF",
      pAdjustMethod = "BH",
      pvalueCutoff = 0.05,
      qvalueCutoff = 0.05,
      readable = TRUE
    )
  }, error = function(e) NULL)
  
  n_mf <- ifelse(is.null(ego_mf), 0, nrow(ego_mf@result))
  cat("      ✅ GO MF terms:", n_mf, "\n")
  
  # KEGG Pathways
  cat("   📊 KEGG Enrichment...\n")
  kegg <- tryCatch({
    enrichKEGG(
      gene = mirna_targets,
      organism = "hsa",
      keyType = "ncbi-geneid",
      pAdjustMethod = "BH",
      pvalueCutoff = 0.05,
      qvalueCutoff = 0.05
    )
  }, error = function(e) NULL)
  
  n_kegg <- ifelse(is.null(kegg), 0, nrow(kegg@result))
  cat("      ✅ KEGG pathways:", n_kegg, "\n\n")
  
  return(list(
    GO_BP = ego_bp,
    GO_MF = ego_mf,
    KEGG = kegg
  ))
}

# ============================================================================
# RUN ENRICHMENT PARA CADA CANDIDATO
# ============================================================================

enrichment_results <- list()

for (i in 1:nrow(candidates)) {
  mirna <- candidates$miRNA[i]
  result <- run_enrichment_for_mirna(mirna)
  
  if (!is.null(result)) {
    enrichment_results[[mirna]] <- result
    
    # Guardar resultados
    safe_name <- str_replace_all(mirna, "-", "_")
    
    if (!is.null(result$GO_BP) && nrow(result$GO_BP@result) > 0) {
      write.csv(result$GO_BP@result, 
                paste0("data/pathways/GO_BP_", safe_name, ".csv"), 
                row.names = FALSE)
    }
    
    if (!is.null(result$GO_MF) && nrow(result$GO_MF@result) > 0) {
      write.csv(result$GO_MF@result, 
                paste0("data/pathways/GO_MF_", safe_name, ".csv"), 
                row.names = FALSE)
    }
    
    if (!is.null(result$KEGG) && nrow(result$KEGG@result) > 0) {
      write.csv(result$KEGG@result, 
                paste0("data/pathways/KEGG_", safe_name, ".csv"), 
                row.names = FALSE)
    }
  }
}

# ============================================================================
# IDENTIFICAR PATHWAYS COMPARTIDOS
# ============================================================================

cat(paste(rep("=", 70), collapse = ""), "\n")
cat("📊 IDENTIFICANDO PATHWAYS COMPARTIDOS\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

# Consolidar GO BP
all_go_bp <- lapply(names(enrichment_results), function(m) {
  if (!is.null(enrichment_results[[m]]$GO_BP)) {
    enrichment_results[[m]]$GO_BP@result %>%
      mutate(miRNA = m) %>%
      dplyr::select(miRNA, ID, Description, p.adjust, Count)
  }
}) %>% bind_rows()

if (nrow(all_go_bp) > 0) {
  shared_go <- all_go_bp %>%
    group_by(Description) %>%
    summarise(
      N_miRNAs = n(),
      miRNAs = paste(unique(miRNA), collapse = ", "),
      Min_padj = min(p.adjust),
      .groups = "drop"
    ) %>%
    filter(N_miRNAs >= 2) %>%
    arrange(desc(N_miRNAs), Min_padj)
  
  cat("🔗 GO terms compartidos:", nrow(shared_go), "\n")
  if (nrow(shared_go) > 0) {
    cat("\n🔝 TOP 10 SHARED GO TERMS:\n")
    print(head(shared_go, 10))
    write.csv(shared_go, "data/pathways/GO_shared.csv", row.names = FALSE)
  }
}

cat("\n")

# Filtrar por oxidación
if (nrow(all_go_bp) > 0) {
  oxidative_terms <- all_go_bp %>%
    filter(str_detect(Description, 
      regex("oxidativ|antioxid|reactive oxygen|ROS|redox|DNA damage|repair", ignore_case = TRUE))) %>%
    arrange(p.adjust)
  
  cat("🔥 GO terms relacionados con OXIDACIÓN:", nrow(oxidative_terms), "\n")
  if (nrow(oxidative_terms) > 0) {
    cat("\n🔝 TOP OXIDATIVE TERMS:\n")
    print(head(oxidative_terms, 10))
    write.csv(oxidative_terms, "data/pathways/GO_oxidative.csv", row.names = FALSE)
  }
}

cat("\n")

# ============================================================================
# RESUMEN
# ============================================================================

cat(paste(rep("=", 70), collapse = ""), "\n")
cat("✅ PATHWAY ENRICHMENT COMPLETADO\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

cat("📁 ARCHIVOS GENERADOS:\n")
for (mirna in names(enrichment_results)) {
  safe_name <- str_replace_all(mirna, "-", "_")
  cat(sprintf("   • GO_BP_%s.csv\n", safe_name))
  cat(sprintf("   • GO_MF_%s.csv\n", safe_name))
  cat(sprintf("   • KEGG_%s.csv\n", safe_name))
}
cat("   • GO_shared.csv\n")
if (exists("oxidative_terms") && nrow(oxidative_terms) > 0) {
  cat("   • GO_oxidative.csv\n")
}

cat("\n📊 RESUMEN:\n")
cat("   Total GO BP terms:", nrow(all_go_bp), "\n")
if (exists("shared_go")) cat("   GO terms compartidos:", nrow(shared_go), "\n")
if (exists("oxidative_terms")) cat("   GO terms oxidativos:", nrow(oxidative_terms), "\n")

cat("\n🚀 SIGUIENTE: Network Analysis\n")
cat("   Rscript scripts/04_network_analysis.R\n\n")

# Guardar resultados para siguiente paso
saveRDS(enrichment_results, "data/pathways/enrichment_results.rds")
cat("💾 Resultados guardados en RDS\n")

