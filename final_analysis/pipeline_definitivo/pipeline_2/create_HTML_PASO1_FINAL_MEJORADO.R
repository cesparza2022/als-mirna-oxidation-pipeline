# =============================================================================
# CREAR HTML FINAL MEJORADO DEL PASO 1
# =============================================================================

# Figuras base seleccionadas
figuras_base <- c(
  "figures/panel_a_overview.png",
  "figures/panel_a_overview_CORRECTED.png", 
  "figures/panel_c_spectrum_CORRECTED.png",
  "figures/panel_c_seed_interaction_CORRECTED.png",
  "figures/panel_d_positional_fraction_CORRECTED.png",
  "figures/panel_f_ultra_clean_spectrum_BACKUP_20251016_203451.png"
)

# Figuras avanzadas mejoradas
figuras_avanzadas <- c(
  "figures_advanced/2.1_volcano_gt_enrichment_improved.png",
  "figures_advanced/2.2_boxplot_seed_regions_improved.png",
  "figures_advanced/3.1_positional_heatmap_improved.png",
  "figures_advanced/3.2_line_plot_positional_improved.png",
  "figures_advanced/5.1_cdf_plot_improved.png",
  "figures_advanced/5.2_ridge_plot_improved.png"
)

# Verificar existencia
figuras_base_ok <- figuras_base[file.exists(figuras_base)]
figuras_avanzadas_ok <- figuras_avanzadas[file.exists(figuras_avanzadas)]

cat("✅ Figuras base:", length(figuras_base_ok), "\n")
cat("✅ Figuras avanzadas:", length(figuras_avanzadas_ok), "\n")

# Crear HTML
html_content <- paste0("
<!DOCTYPE html>
<html>
<head>
  <title>PASO 1 COMPLETO: Análisis Inicial Mejorado</title>
  <style>
    body { font-family: 'Helvetica Neue', Arial, sans-serif; margin: 0; padding: 20px; background: linear-gradient(to bottom, #f5f7fa 0%, #c3cfe2 100%); }
    .container { max-width: 1400px; margin: auto; background: white; padding: 40px; border-radius: 15px; box-shadow: 0 5px 20px rgba(0,0,0,0.1); }
    h1 { text-align: center; color: #2c3e50; font-size: 2.5em; margin-bottom: 10px; }
    .subtitle { text-align: center; color: #7f8c8d; font-size: 1.2em; margin-bottom: 30px; }
    h2 { color: #34495e; border-bottom: 3px solid #3498db; padding-bottom: 10px; margin-top: 40px; }
    .section { margin: 40px 0; padding: 30px; border-radius: 10px; }
    .base { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); }
    .advanced { background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); }
    .section h2 { color: white; border-bottom: 2px solid rgba(255,255,255,0.3); }
    .section p { color: rgba(255,255,255,0.9); font-size: 1.1em; }
    .figure-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(500px, 1fr)); gap: 25px; margin: 30px 0; }
    .figure-item { background: white; border-radius: 10px; overflow: hidden; box-shadow: 0 4px 15px rgba(0,0,0,0.1); transition: transform 0.3s ease; }
    .figure-item:hover { transform: translateY(-5px); box-shadow: 0 8px 25px rgba(0,0,0,0.15); }
    .figure-item img { width: 100%; height: auto; }
    .figure-item .caption { padding: 15px; text-align: center; background-color: #34495e; color: white; font-size: 0.95em; font-weight: 600; }
    .figure-item .desc { padding: 12px 15px; font-size: 0.9em; color: #555; background-color: #ecf0f1; }
    .stats { background: linear-gradient(135deg, #ffeaa7 0%, #fdcb6e 100%); border-radius: 10px; padding: 25px; margin: 30px 0; box-shadow: 0 3px 10px rgba(0,0,0,0.1); }
    .stats h3 { color: #2d3436; margin-top: 0; }
    .stats ul { color: #2d3436; line-height: 1.8; }
    .highlight { background-color: white; padding: 3px 8px; border-radius: 5px; font-weight: bold; color: #e74c3c; }
    .footer { text-align: center; margin-top: 50px; padding: 30px; background: #34495e; color: white; border-radius: 10px; }
  </style>
</head>
<body>
  <div class='container'>
    <h1>🎯 PASO 1 COMPLETO</h1>
    <div class='subtitle'>Análisis Inicial del Pipeline de miRNA con Figuras Mejoradas</div>
    
    <div class='stats'>
      <h3>📊 Resumen del Análisis Completo</h3>
      <ul>
        <li><strong>Figuras Base Seleccionadas:</strong> <span class='highlight'>", length(figuras_base_ok), "</span> visualizaciones fundamentales</li>
        <li><strong>Figuras Avanzadas Mejoradas:</strong> <span class='highlight'>", length(figuras_avanzadas_ok), "</span> análisis especializados profesionales</li>
        <li><strong>Total de Visualizaciones:</strong> <span class='highlight'>", length(figuras_base_ok) + length(figuras_avanzadas_ok), "</span> figuras de alta calidad</li>
        <li><strong>Objetivo Principal:</strong> Caracterización exhaustiva de mutaciones G>T como firma de estrés oxidativo en miRNAs</li>
      </ul>
    </div>

    <div class='section base'>
      <h2>🔍 FIGURAS BASE - Análisis Inicial Seleccionado</h2>
      <p>Visualizaciones fundamentales seleccionadas por su calidad y relevancia para responder las preguntas clave del análisis inicial.</p>
      <div class='figure-grid'>")

# Agregar figuras base
for (fig_path in figuras_base_ok) {
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
      <h2>🚀 FIGURAS AVANZADAS - Análisis Mejorados con Datos Reales</h2>
      <p>Análisis avanzados con estilo profesional, datos reales del pipeline y visualizaciones de alta calidad científica.</p>
      <div class='figure-grid'>")

# Agregar figuras avanzadas con descripciones
descripciones <- c(
  "2.1_volcano" = "Volcano plot de enriquecimiento G>T: Identifica miRNAs significativamente afectados por estrés oxidativo",
  "2.2_boxplot" = "Distribución de G>T por región funcional: Violin + Boxplot mostrando carga oxidativa en Seed, Middle y 3' End",
  "3.1_positional" = "Heatmap posicional: Top 30 miRNAs mostrando frecuencia normalizada de G>T por posición (región seed resaltada)",
  "3.2_line_plot" = "Frecuencia por posición: Comparación de G>T vs otras mutaciones de Guanina a lo largo del miRNA",
  "5.1_cdf" = "Distribución acumulada (CDF): Carga oxidativa global con mediana y media anotadas",
  "5.2_ridge" = "Comparación Seed vs Non-Seed: Distribuciones de proporción G>T entre regiones funcionales"
)

for (fig_path in figuras_avanzadas_ok) {
  fig_name <- basename(fig_path)
  fig_key <- sub("_improved.png", "", sub("figures_advanced/", "", fig_path))
  fig_desc <- if (fig_key %in% names(descripciones)) descripciones[[fig_key]] else "Análisis avanzado profesional"
  
  html_content <- paste0(html_content, "
        <div class='figure-item'>
          <img src='", fig_path, "' alt='", fig_name, "'>
          <div class='caption'>", fig_name, "</div>
          <div class='desc'>", fig_desc, "</div>
        </div>")
}

html_content <- paste0(html_content, "
      </div>
    </div>

    <div class='stats'>
      <h3>🎯 Siguientes Pasos del Pipeline</h3>
      <p><strong>Con este análisis inicial completo y mejorado, el pipeline está preparado para:</strong></p>
      <ul>
        <li><strong>Paso 2:</strong> Análisis de VAF (Variant Allele Frequency) y profundización en heterogeneidad</li>
        <li><strong>Paso 3:</strong> Comparaciones estadísticas rigurosas entre grupos (ALS vs Control)</li>
        <li><strong>Paso 4:</strong> Análisis funcional de targets y enriquecimiento de pathways</li>
        <li><strong>Paso 5:</strong> Integración con datos clínicos y validación experimental</li>
      </ul>
    </div>

    <div class='footer'>
      <p style='font-size: 1.3em; font-weight: bold;'>Pipeline de Análisis de miRNA - UCSD</p>
      <p>Generado: ", Sys.time(), "</p>
      <p>Total: ", length(figuras_base_ok) + length(figuras_avanzadas_ok), " figuras | Base: ", length(figuras_base_ok), " | Avanzadas Mejoradas: ", length(figuras_avanzadas_ok), "</p>
    </div>
  </div>
</body>
</html>")

# Guardar
output_file <- "PASO_1_COMPLETO_MEJORADO_FINAL.html"
writeLines(html_content, output_file)

cat("✅ HTML MEJORADO CREADO:", output_file, "\n")
cat("📊 Total de figuras:", length(figuras_base_ok) + length(figuras_avanzadas_ok), "\n")

# Abrir
system(paste("open", output_file))
cat("🌐 HTML abierto en navegador\n")
