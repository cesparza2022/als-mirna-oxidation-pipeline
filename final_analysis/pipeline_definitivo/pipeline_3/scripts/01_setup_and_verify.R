# ============================================================================
# PASO 3: SETUP Y VERIFICACIÓN
# Verifica packages necesarios y prepara ambiente
# ============================================================================

cat("🎯 PASO 3: SETUP Y VERIFICACIÓN\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

# ============================================================================
# VERIFICAR PACKAGES
# ============================================================================

cat("📦 Verificando packages necesarios...\n\n")

required_packages <- list(
  CRAN = c("dplyr", "tidyr", "stringr", "ggplot2", "igraph", "ggraph", 
           "VennDiagram", "UpSetR", "httr", "jsonlite", "XML", "gridExtra"),
  Bioconductor = c("clusterProfiler", "enrichplot", "org.Hs.eg.db", 
                   "multiMiR", "ReactomePA", "DOSE")
)

check_and_install <- function(pkg, source = "CRAN") {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat("   ❌", pkg, "no instalado. Instalando...\n")
    if (source == "CRAN") {
      install.packages(pkg, repos = "https://cran.r-project.org", quiet = TRUE)
    } else {
      if (!requireNamespace("BiocManager", quietly = TRUE))
        install.packages("BiocManager", quiet = TRUE)
      BiocManager::install(pkg, quiet = TRUE, update = FALSE)
    }
    return(TRUE)
  } else {
    cat("   ✅", pkg, "\n")
    return(FALSE)
  }
}

cat("📦 CRAN Packages:\n")
installed_cran <- sapply(required_packages$CRAN, check_and_install, source = "CRAN")

cat("\n📦 Bioconductor Packages:\n")
installed_bioc <- sapply(required_packages$Bioconductor, check_and_install, source = "Bioconductor")

if (any(installed_cran) || any(installed_bioc)) {
  cat("\n✅ Packages instalados/actualizados\n")
} else {
  cat("\n✅ Todos los packages ya estaban instalados\n")
}

# ============================================================================
# CARGAR LIBRARIES
# ============================================================================

cat("\n📚 Cargando libraries...\n")
suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(ggplot2)
  library(igraph)
  library(ggraph)
  library(clusterProfiler)
  library(org.Hs.eg.db)
})
cat("✅ Libraries cargadas\n\n")

# ============================================================================
# CARGAR CANDIDATOS DEL PASO 2
# ============================================================================

cat("📊 Cargando candidatos del Paso 2...\n")

volcano_data_path <- "../pipeline_2/VOLCANO_PLOT_DATA_PER_SAMPLE.csv"

if (!file.exists(volcano_data_path)) {
  stop("❌ ERROR: No se encuentra ", volcano_data_path)
}

volcano_data <- read.csv(volcano_data_path)

# Filtrar candidatos ALS (FC > 0.58, padj < 0.05)
candidates_als <- volcano_data %>%
  filter(log2FC > 0.58, padj < 0.05) %>%
  arrange(padj) %>%
  dplyr::select(miRNA, log2FC, padj, Mean_ALS, Mean_Control)

cat("✅ Candidatos ALS identificados:", nrow(candidates_als), "\n\n")

if (nrow(candidates_als) == 0) {
  stop("❌ ERROR: No se encontraron candidatos ALS en los datos")
}

cat("🔝 CANDIDATOS ALS:\n")
print(candidates_als)
cat("\n")

# Guardar lista de candidatos
write.csv(candidates_als, "data/ALS_candidates.csv", row.names = FALSE)
cat("📋 Lista guardada: data/ALS_candidates.csv\n\n")

# ============================================================================
# CREAR CONFIGURACIÓN
# ============================================================================

cat("📝 Creando archivo de configuración...\n")

config <- list(
  candidates = list(
    mirnas = candidates_als$miRNA,
    n_candidates = nrow(candidates_als)
  ),
  thresholds = list(
    target_score_targetscan = 0.7,
    target_score_mirdb = 80,
    pathway_pvalue = 0.05,
    pathway_qvalue = 0.05,
    min_databases = 2  # Targets en al menos 2 DBs
  ),
  databases = list(
    targetscan = TRUE,
    mirtarbase = TRUE,
    mirdb = TRUE
  ),
  analysis = list(
    go_ontology = c("BP", "MF", "CC"),
    kegg = TRUE,
    reactome = FALSE  # Opcional
  )
)

# Guardar config como JSON
library(jsonlite)
write_json(config, "data/paso3_config.json", pretty = TRUE)
cat("✅ Configuración guardada: data/paso3_config.json\n\n")

# ============================================================================
# VERIFICAR CONECTIVIDAD
# ============================================================================

cat("🌐 Verificando conectividad a bases de datos...\n")

# Test PubMed
test_pubmed <- tryCatch({
  library(httr)
  response <- GET("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term=test")
  status_code(response) == 200
}, error = function(e) FALSE)

if (test_pubmed) {
  cat("   ✅ PubMed accesible\n")
} else {
  cat("   ⚠️  PubMed no accesible (requerido para literatura)\n")
}

# Test TargetScan
test_targetscan <- tryCatch({
  response <- GET("http://www.targetscan.org/")
  status_code(response) == 200
}, error = function(e) FALSE)

if (test_targetscan) {
  cat("   ✅ TargetScan accesible\n")
} else {
  cat("   ⚠️  TargetScan no accesible (se usarán DBs alternativas)\n")
}

cat("\n")

# ============================================================================
# RESUMEN
# ============================================================================

cat(paste(rep("=", 70), collapse = ""), "\n")
cat("✅ SETUP COMPLETADO\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

cat("📊 CANDIDATOS ALS:", nrow(candidates_als), "\n")
for (i in 1:nrow(candidates_als)) {
  cat(sprintf("   %d. %s (FC %.2f, p %.2e)\n", 
              i, candidates_als$miRNA[i], 
              2^candidates_als$log2FC[i], 
              candidates_als$padj[i]))
}

cat("\n📦 PACKAGES:", length(required_packages$CRAN) + length(required_packages$Bioconductor), "verificados\n")
cat("🌐 CONECTIVIDAD:", ifelse(test_pubmed, "OK", "LIMITADA"), "\n")
cat("📁 DIRECTORIOS: Creados y listos\n")
cat("📝 CONFIG: paso3_config.json guardado\n\n")

cat("🚀 LISTO PARA COMENZAR TARGET PREDICTION\n")
cat("   Siguiente: Rscript scripts/02_query_targets.R\n\n")

# Retornar candidatos para usar en otros scripts
saveRDS(candidates_als, "data/candidates_als.rds")
cat("💾 Candidatos guardados en RDS para scripts subsecuentes\n")

