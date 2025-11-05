# ============================================================================
# PASO 3.6: CREAR HTML VIEWER
# Genera viewer interactivo con todas las figuras y resultados
# ============================================================================

library(rmarkdown)

cat("🎯 PASO 3.6: CREAR HTML VIEWER\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

# Verificar figuras disponibles
figuras <- c(
  "figures/FIG_3.1_TARGETS_VENN.png",
  "figures/FIG_3.2_TARGETS_BARPLOT.png",
  "figures/FIG_3.3_TARGETS_NETWORK.png",
  "figures/FIG_3.4_GO_DOTPLOT.png",
  "figures/FIG_3.5_PATHWAYS_HEATMAP.png",
  "figures/FIG_3.6_NETWORK_FULL.png",
  "figures/FIG_3.7_NETWORK_SIMPLE.png",
  "figures/FIG_3.8_SHARED_TARGETS.png",
  "figures/FIG_3.9_SUMMARY_STATS.png"
)

figs_exist <- file.exists(figuras)
cat("📊 Figuras disponibles:", sum(figs_exist), "/", length(figuras), "\n\n")

# Cargar estadísticas
candidates <- readRDS("data/candidates_als.rds")
summary_mirna <- read.csv("data/targets/summary_by_mirna.csv")
shared_targets <- read.csv("data/targets/targets_shared.csv")

# HTML content
html_content <- paste0("---
title: \"PASO 3: Análisis Funcional de Candidatos ALS\"
output: html_document
---

<style>
  body { font-family: 'Helvetica Neue', Arial, sans-serif; background: #f5f5f5; padding: 20px; color: #333; }
  .container { max-width: 1400px; margin: auto; background: #fff; padding: 40px; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }
  h1 { text-align: center; color: #2c3e50; font-size: 2.5em; border-bottom: 4px solid #3498db; padding-bottom: 20px; }
  h2 { color: white; margin-top: 50px; padding: 15px 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); border-radius: 8px; }
  .highlight { background: #fff3cd; border-left: 5px solid #ffc107; padding: 20px; margin: 30px 0; border-radius: 5px; }
  .figura { background: white; border: 2px solid #ddd; border-radius: 10px; padding: 20px; margin: 30px 0; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
  .figura h3 { color: #2c3e50; margin-top: 0; padding-bottom: 10px; border-bottom: 2px solid #eee; }
  .figura img { max-width: 100%; height: auto; display: block; margin: 20px auto; border-radius: 5px; }
  .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin: 30px 0; }
  .stat-card { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 25px; border-radius: 10px; text-align: center; }
  .stat-number { font-size: 3em; font-weight: bold; }
</style>

<div class=\"container\">
  <h1>📊 PASO 3: Análisis Funcional</h1>
  <p style=\"text-align: center; font-size: 1.2em; color: #555;\">Targets, Pathways y Networks de los 3 Candidatos ALS</p>
  
  <div class=\"stats-grid\">
    <div class=\"stat-card\">
      <div class=\"stat-number\">", nrow(candidates), "</div>
      <div>Candidatos ALS<br/>Analizados</div>
    </div>
    <div class=\"stat-card\">
      <div class=\"stat-number\">", sum(summary_mirna$N_Targets), "</div>
      <div>Total Targets<br/>(High-Confidence)</div>
    </div>
    <div class=\"stat-card\">
      <div class=\"stat-number\">", nrow(shared_targets), "</div>
      <div>Targets<br/>Compartidos</div>
    </div>
    <div class=\"stat-card\">
      <div class=\"stat-number\">", sum(figs_exist), "</div>
      <div>Figuras<br/>Generadas</div>
    </div>
  </div>

  <div class=\"highlight\">
    <h3>🎯 CANDIDATOS ALS</h3>
    <ol>")

for (i in 1:nrow(candidates)) {
  html_content <- paste0(html_content,
    "<li><strong>", candidates$miRNA[i], "</strong> (FC ", 
    round(2^candidates$log2FC[i], 2), "x, p = ", 
    format.pval(candidates$padj[i], digits = 2), ")</li>")
}

html_content <- paste0(html_content,
    "</ol>
  </div>

  <h2>📊 Target Prediction</h2>")

# Añadir figuras 3.1-3.3
for (i in 1:3) {
  if (figs_exist[i]) {
    titles <- c("Venn Diagram: Target Overlap", 
                "Number of Targets per miRNA",
                "Network: miRNA → Targets")
    html_content <- paste0(html_content,
      "<div class=\"figura\">
        <h3>Figura 3.", i, ": ", titles[i], "</h3>
        <img src=\"", figuras[i], "\">
      </div>")
  }
}

html_content <- paste0(html_content,
  "<h2>📊 Pathway Enrichment</h2>")

# Figuras 3.4-3.5
for (i in 4:5) {
  if (figs_exist[i]) {
    titles <- c("GO Terms Enrichment", "Shared Pathways Heatmap")
    html_content <- paste0(html_content,
      "<div class=\"figura\">
        <h3>Figura 3.", i, ": ", titles[i - 3], "</h3>
        <img src=\"", figuras[i], "\">
      </div>")
  }
}

html_content <- paste0(html_content,
  "<h2>📊 Integrated Networks</h2>")

# Figuras 3.6-3.9
for (i in 6:9) {
  if (figs_exist[i]) {
    titles <- c("Network: Complete", "Network: Simplified (Hubs)", 
                "Shared Targets", "Summary Statistics")
    html_content <- paste0(html_content,
      "<div class=\"figura\">
        <h3>Figura 3.", i, ": ", titles[i - 5], "</h3>
        <img src=\"", figuras[i], "\">
      </div>")
  }
}

html_content <- paste0(html_content,
  "<div style=\"text-align: center; margin-top: 60px; padding: 30px; border-top: 3px solid #e0e0e0;\">
    <p style=\"font-size: 1.2em; font-weight: bold; color: #2c3e50;\">🎉 PASO 3 COMPLETO</p>
    <p>Generado: ", Sys.time(), "</p>
    <p>Pipeline de Análisis de miRNA | UCSD</p>
  </div>
</div>")

# Guardar y renderizar
temp_md <- "temp_paso3.md"
writeLines(html_content, temp_md)

output_html <- "PASO_3_ANALISIS_FUNCIONAL.html"
rmarkdown::render(temp_md, output_file = output_html, quiet = TRUE)
file.remove(temp_md)

cat("✅ HTML GENERADO\n")
cat("📁 Archivo:", output_html, "\n\n")

cat("🌐 Abriendo en navegador...\n")
system(paste("open", output_html))

cat("\n✅ PASO 3 COMPLETADO\n")

