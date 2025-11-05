# =============================================================================
# CREAR HTML COMPLETO DEL PASO 1 - FIGURAS BASE + AVANZADAS
# =============================================================================

library(rmarkdown)
library(knitr)
library(stringr)

# Definir las figuras base seleccionadas por el usuario
figuras_base <- c(
  "figures/panel_a_overview.png",
  "figures/panel_a_overview_CORRECTED.png", 
  "figures/panel_c_spectrum_CORRECTED.png",
  "figures/panel_c_seed_interaction_CORRECTED.png",
  "figures/panel_d_positional_fraction_CORRECTED.png",
  "figures/panel_f_ultra_clean_spectrum_BACKUP_20251016_203451.png"
)

# Definir las figuras avanzadas generadas
figuras_avanzadas <- c(
  "figures_advanced/1.1_correlation_heatmap.png",
  "figures_advanced/1.2_pca_profiles.png",
  "figures_advanced/2.1_volcano_gt_enrichment.png",
  "figures_advanced/2.2_boxplot_seed_regions.png",
  "figures_advanced/3.1_positional_heatmap.png",
  "figures_advanced/3.2_line_plot_positional.png",
  "figures_advanced/5.1_cdf_plot.png",
  "figures_advanced/5.2_ridge_plot.png"
)

# Verificar que las figuras existen
verificar_figuras <- function(figuras) {
  existentes <- file.exists(figuras)
  cat("✅ Figuras existentes:", sum(existentes), "/", length(figuras), "\n")
  if (any(!existentes)) {
    cat("❌ Figuras faltantes:\n")
    cat(paste("  -", figuras[!existentes], collapse = "\n"), "\n")
  }
  return(figuras[existentes])
}

# Verificar figuras base
cat("🔍 Verificando figuras base...\n")
figuras_base_existentes <- verificar_figuras(figuras_base)

# Verificar figuras avanzadas
cat("\n🔍 Verificando figuras avanzadas...\n")
figuras_avanzadas_existentes <- verificar_figuras(figuras_avanzadas)

# Crear el contenido HTML
html_content <- "---
title: \"PASO 1 COMPLETO: Análisis Inicial + Figuras Avanzadas\"
output: html_document
---

<style>
  body { 
    font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; 
    line-height: 1.6; 
    color: #333; 
    background-color: #f9f9f9; 
    margin: 0; 
    padding: 20px; 
  }
  .container { 
    max-width: 1400px; 
    margin: auto; 
    background: #fff; 
    padding: 30px; 
    border-radius: 8px; 
    box-shadow: 0 2px 10px rgba(0,0,0,0.1); 
  }
  h1, h2, h3 { color: #2c3e50; }
  h1 { text-align: center; margin-bottom: 30px; }
  .section { 
    margin-bottom: 40px; 
    padding: 20px; 
    border-radius: 8px; 
    border-left: 5px solid #3498db; 
  }
  .section.base { background-color: #e8f4f8; border-left-color: #3498db; }
  .section.advanced { background-color: #f0f8e8; border-left-color: #27ae60; }
  .section h2 { margin-top: 0; }
  .figure-grid { 
    display: grid; 
    grid-template-columns: repeat(auto-fit, minmax(500px, 1fr)); 
    gap: 20px; 
    margin-top: 20px; 
  }
  .figure-item { 
    background: #fff; 
    border: 1px solid #ddd; 
    border-radius: 8px; 
    overflow: hidden; 
    box-shadow: 0 2px 8px rgba(0,0,0,0.1); 
    transition: transform 0.2s ease-in-out;
  }
  .figure-item:hover { 
    transform: translateY(-3px); 
    box-shadow: 0 4px 15px rgba(0,0,0,0.15); 
  }
  .figure-item img { 
    max-width: 100%; 
    height: auto; 
    display: block; 
    background-color: #fdfdfd; 
  }
  .figure-item .caption { 
    padding: 15px; 
    font-size: 0.9em; 
    color: #555; 
    text-align: center; 
    background-color: #fafafa; 
    border-top: 1px solid #eee; 
  }
  .figure-item .description { 
    padding: 10px 15px; 
    font-size: 0.85em; 
    color: #666; 
    background-color: #f8f9fa; 
    border-top: 1px solid #eee; 
  }
  .summary-stats { 
    background-color: #fff3cd; 
    border: 1px solid #ffeaa7; 
    border-radius: 5px; 
    padding: 15px; 
    margin: 20px 0; 
  }
  .summary-stats h3 { color: #856404; margin-top: 0; }
  .footer { 
    text-align: center; 
    margin-top: 50px; 
    padding-top: 20px; 
    border-top: 2px solid #eee; 
    color: #777; 
    font-size: 0.9em; 
  }
  .highlight { 
    background-color: #fff3cd; 
    padding: 2px 4px; 
    border-radius: 3px; 
    font-weight: bold; 
  }
</style>

<div class=\"container\">
  <h1>🎯 PASO 1 COMPLETO: Análisis Inicial + Figuras Avanzadas</h1>
  
  <p>Este documento presenta el <strong>análisis inicial completo</strong> del pipeline de miRNA, combinando las figuras base seleccionadas con análisis avanzados basados en las ideas propuestas. El objetivo es proporcionar una caracterización exhaustiva del dataset y establecer las bases para análisis posteriores.</p>

  <div class=\"summary-stats\">
    <h3>📊 Resumen del Análisis</h3>
    <ul>
      <li><strong>Figuras Base:</strong> <span class=\"highlight\">", length(figuras_base_existentes), "</span> figuras seleccionadas</li>
      <li><strong>Figuras Avanzadas:</strong> <span class=\"highlight\">", length(figuras_avanzadas_existentes), "</span> análisis especializados</li>
      <li><strong>Total de Visualizaciones:</strong> <span class=\"highlight\">", length(figuras_base_existentes) + length(figuras_avanzadas_existentes), "</span></li>
      <li><strong>Enfoque Principal:</strong> Caracterización de mutaciones G>T como firma de estrés oxidativo</li>
    </ul>
  </div>

  <hr/>

  <div class=\"section base\">
    <h2>🔍 FIGURAS BASE - Análisis Inicial Seleccionado</h2>
    <p>Estas son las figuras que forman la base del análisis inicial, seleccionadas por su calidad y relevancia para responder las preguntas fundamentales del Paso 1.</p>
    
    <div class=\"figure-grid\">"

# Agregar figuras base
for (fig_path in figuras_base_existentes) {
  fig_name <- basename(fig_path)
  fig_description <- case_when(
    str_detect(fig_name, "panel_a_overview") ~ "Vista general del dataset y evolución de los datos",
    str_detect(fig_name, "panel_c_spectrum") ~ "Espectro G>X por posición (figura favorita del usuario)",
    str_detect(fig_name, "panel_c_seed_interaction") ~ "Análisis de interacciones en la región semilla",
    str_detect(fig_name, "panel_d_positional_fraction") ~ "Fracción posicional de mutaciones",
    str_detect(fig_name, "panel_f_ultra_clean_spectrum") ~ "Espectro ultra limpio de mutaciones",
    TRUE ~ "Análisis del dataset"
  )
  
  html_content <- paste0(html_content,
    "<div class=\"figure-item\">
      <img src=\"", fig_path, "\" alt=\"", fig_name, "\">
      <div class=\"caption\">", fig_name, "</div>
      <div class=\"description\">", fig_description, "</div>
    </div>"
  )
}

html_content <- paste0(html_content,
    "</div>
  </div>

  <div class=\"section advanced\">
    <h2>🚀 FIGURAS AVANZADAS - Análisis Especializados</h2>
    <p>Estas figuras implementan análisis avanzados basados en las ideas propuestas, enfocándose en caracterización global, análisis de G>T, dimensión posicional y comparativas cuantitativas.</p>
    
    <div class=\"figure-grid\">"

# Agregar figuras avanzadas
for (fig_path in figuras_avanzadas_existentes) {
  fig_name <- basename(fig_path)
  fig_description <- case_when(
    str_detect(fig_name, "1.1_correlation") ~ "Heatmap de correlación entre tipos de mutación",
    str_detect(fig_name, "1.2_pca") ~ "PCA por perfil de mutaciones",
    str_detect(fig_name, "2.1_volcano") ~ "Volcano plot de enriquecimiento G>T por miRNA",
    str_detect(fig_name, "2.2_boxplot") ~ "Boxplot por región funcional (Seed vs Non-Seed)",
    str_detect(fig_name, "3.1_positional") ~ "Heatmap posicional de G>T por miRNA",
    str_detect(fig_name, "3.2_line_plot") ~ "Line plot ALS vs Control por posición",
    str_detect(fig_name, "5.1_cdf") ~ "Distribución acumulada de proporción G>T",
    str_detect(fig_name, "5.2_ridge") ~ "Ridge plot de distribución de G>T",
    TRUE ~ "Análisis avanzado"
  )
  
  html_content <- paste0(html_content,
    "<div class=\"figure-item\">
      <img src=\"", fig_path, "\" alt=\"", fig_name, "\">
      <div class=\"caption\">", fig_name, "</div>
      <div class=\"description\">", fig_description, "</div>
    </div>"
  )
}

html_content <- paste0(html_content,
    "</div>
  </div>

  <div class=\"summary-stats\">
    <h3>🎯 Próximos Pasos</h3>
    <p>Con este análisis inicial completo, el pipeline está listo para avanzar a las siguientes fases:</p>
    <ul>
      <li><strong>Paso 2:</strong> Análisis de VAF (Variant Allele Frequency)</li>
      <li><strong>Paso 3:</strong> Comparaciones entre grupos (ALS vs Control)</li>
      <li><strong>Paso 4:</strong> Análisis funcional y de pathways</li>
    </ul>
  </div>

  <div class=\"footer\">
    <p><strong>Pipeline de Análisis de miRNA - UCSD</strong></p>
    <p>Generado el: ", Sys.time(), "</p>
    <p>Total de figuras: ", length(figuras_base_existentes) + length(figuras_avanzadas_existentes), " | Figuras base: ", length(figuras_base_existentes), " | Figuras avanzadas: ", length(figuras_avanzadas_existentes), "</p>
  </div>
</div>
"

# Guardar el contenido HTML
output_file <- "PASO_1_COMPLETO_FIGURAS_BASE_Y_AVANZADAS.html"
writeLines(html_content, output_file)

cat("✅ HTML COMPLETO DEL PASO 1 CREADO:\n")
cat("📁 Archivo:", output_file, "\n")
cat("📊 Figuras base:", length(figuras_base_existentes), "\n")
cat("📊 Figuras avanzadas:", length(figuras_avanzadas_existentes), "\n")
cat("📊 Total de figuras:", length(figuras_base_existentes) + length(figuras_avanzadas_existentes), "\n")

# Abrir el HTML en el navegador
system(paste("open", output_file))
cat("🌐 HTML abierto en navegador\n")
