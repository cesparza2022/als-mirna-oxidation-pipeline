# =============================================================================
# CREAR HTML SIMPLE DEL PASO 1 COMPLETO
# =============================================================================

# Definir las figuras
figuras_base <- c(
  "figures/panel_a_overview.png",
  "figures/panel_a_overview_CORRECTED.png", 
  "figures/panel_c_spectrum_CORRECTED.png",
  "figures/panel_c_seed_interaction_CORRECTED.png",
  "figures/panel_d_positional_fraction_CORRECTED.png",
  "figures/panel_f_ultra_clean_spectrum_BACKUP_20251016_203451.png"
)

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

# Verificar existencia
figuras_base_existentes <- figuras_base[file.exists(figuras_base)]
figuras_avanzadas_existentes <- figuras_avanzadas[file.exists(figuras_avanzadas)]

cat("✅ Figuras base encontradas:", length(figuras_base_existentes), "\n")
cat("✅ Figuras avanzadas encontradas:", length(figuras_avanzadas_existentes), "\n")

# Crear HTML simple
html_content <- paste0("
<!DOCTYPE html>
<html>
<head>
  <title>PASO 1 COMPLETO: Análisis Inicial + Figuras Avanzadas</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
    .container { max-width: 1200px; margin: auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
    h1 { text-align: center; color: #2c3e50; }
    h2 { color: #3498db; border-bottom: 2px solid #3498db; padding-bottom: 10px; }
    .section { margin: 30px 0; padding: 20px; border-radius: 8px; }
    .base { background-color: #e8f4f8; border-left: 5px solid #3498db; }
    .advanced { background-color: #f0f8e8; border-left: 5px solid #27ae60; }
    .figure-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(400px, 1fr)); gap: 20px; margin: 20px 0; }
    .figure-item { background: white; border: 1px solid #ddd; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
    .figure-item img { width: 100%; height: auto; }
    .figure-item .caption { padding: 10px; text-align: center; background-color: #f8f9fa; font-size: 0.9em; color: #555; }
    .stats { background-color: #fff3cd; border: 1px solid #ffeaa7; border-radius: 5px; padding: 15px; margin: 20px 0; }
  </style>
</head>
<body>
  <div class='container'>
    <h1>🎯 PASO 1 COMPLETO: Análisis Inicial + Figuras Avanzadas</h1>
    
    <div class='stats'>
      <h3>📊 Resumen del Análisis</h3>
      <ul>
        <li><strong>Figuras Base:</strong> ", length(figuras_base_existentes), " figuras seleccionadas</li>
        <li><strong>Figuras Avanzadas:</strong> ", length(figuras_avanzadas_existentes), " análisis especializados</li>
        <li><strong>Total de Visualizaciones:</strong> ", length(figuras_base_existentes) + length(figuras_avanzadas_existentes), "</li>
        <li><strong>Enfoque Principal:</strong> Caracterización de mutaciones G>T como firma de estrés oxidativo</li>
      </ul>
    </div>

    <div class='section base'>
      <h2>🔍 FIGURAS BASE - Análisis Inicial Seleccionado</h2>
      <p>Estas son las figuras que forman la base del análisis inicial, seleccionadas por su calidad y relevancia.</p>
      <div class='figure-grid'>")

# Agregar figuras base
for (fig_path in figuras_base_existentes) {
  fig_name <- basename(fig_path)
  html_content <- paste0(html_content, "
        <div class='figure-item'>
          <img src='", fig_path, "' alt='", fig_name, "'>
          <div class='caption'>", fig_name, "</div>
        </div>")
}

html_content <- paste0(html_content, "
      </div>
    </div>

    <div class='section advanced'>
      <h2>🚀 FIGURAS AVANZADAS - Análisis Especializados</h2>
      <p>Estas figuras implementan análisis avanzados basados en las ideas propuestas.</p>
      <div class='figure-grid'>")

# Agregar figuras avanzadas
for (fig_path in figuras_avanzadas_existentes) {
  fig_name <- basename(fig_path)
  html_content <- paste0(html_content, "
        <div class='figure-item'>
          <img src='", fig_path, "' alt='", fig_name, "'>
          <div class='caption'>", fig_name, "</div>
        </div>")
}

html_content <- paste0(html_content, "
      </div>
    </div>

    <div class='stats'>
      <h3>🎯 Próximos Pasos</h3>
      <p>Con este análisis inicial completo, el pipeline está listo para avanzar a las siguientes fases:</p>
      <ul>
        <li><strong>Paso 2:</strong> Análisis de VAF (Variant Allele Frequency)</li>
        <li><strong>Paso 3:</strong> Comparaciones entre grupos (ALS vs Control)</li>
        <li><strong>Paso 4:</strong> Análisis funcional y de pathways</li>
      </ul>
    </div>

    <div style='text-align: center; margin-top: 40px; padding-top: 20px; border-top: 2px solid #eee; color: #777;'>
      <p><strong>Pipeline de Análisis de miRNA - UCSD</strong></p>
      <p>Generado el: ", Sys.time(), "</p>
      <p>Total de figuras: ", length(figuras_base_existentes) + length(figuras_avanzadas_existentes), "</p>
    </div>
  </div>
</body>
</html>")

# Guardar el archivo
output_file <- "PASO_1_COMPLETO_FINAL.html"
writeLines(html_content, output_file)

cat("✅ HTML COMPLETO DEL PASO 1 CREADO:\n")
cat("📁 Archivo:", output_file, "\n")
cat("📊 Figuras base:", length(figuras_base_existentes), "\n")
cat("📊 Figuras avanzadas:", length(figuras_avanzadas_existentes), "\n")
cat("📊 Total de figuras:", length(figuras_base_existentes) + length(figuras_avanzadas_existentes), "\n")

# Abrir el HTML
system(paste("open", output_file))
cat("🌐 HTML abierto en navegador\n")
