# HTML FINAL CON FIGURAS BASE + AVANZADAS MEJORADAS

figuras_base <- c(
  "figures/panel_a_overview.png",
  "figures/panel_a_overview_CORRECTED.png", 
  "figures/panel_c_spectrum_CORRECTED.png",
  "figures/panel_c_seed_interaction_CORRECTED.png",
  "figures/panel_d_positional_fraction_CORRECTED.png",
  "figures/panel_f_ultra_clean_spectrum_BACKUP_20251016_203451.png"
)

figuras_avanzadas <- c(
  "figures_advanced/2.1_volcano_gt_enrichment_improved.png",
  "figures_advanced/2.2_boxplot_seed_regions_improved.png",
  "figures_advanced/3.1_positional_heatmap_improved.png",
  "figures_advanced/3.2_line_plot_positional_improved.png",
  "figures_advanced/5.1_cdf_plot_improved.png",
  "figures_advanced/5.2_ridge_plot_improved.png"
)

figuras_base_ok <- figuras_base[file.exists(figuras_base)]
figuras_avanzadas_ok <- figuras_avanzadas[file.exists(figuras_avanzadas)]

cat("✅ Figuras base:", length(figuras_base_ok), "\n")
cat("✅ Figuras avanzadas mejoradas:", length(figuras_avanzadas_ok), "\n")

# HTML
html <- paste0("
<!DOCTYPE html>
<html>
<head>
<meta charset='utf-8'>
<title>PASO 1 COMPLETO - Figuras Base + Avanzadas Mejoradas</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; background: #f0f2f5; }
  .container { max-width: 1600px; margin: 0 auto; padding: 40px 20px; }
  h1 { text-align: center; color: #1a1a1a; font-size: 2.8em; margin-bottom: 15px; font-weight: 700; }
  .subtitle { text-align: center; color: #666; font-size: 1.3em; margin-bottom: 40px; }
  .stats-banner { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 15px; margin-bottom: 40px; box-shadow: 0 10px 30px rgba(0,0,0,0.2); }
  .stats-banner h2 { margin-bottom: 20px; font-size: 1.8em; }
  .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-top: 20px; }
  .stat-item { background: rgba(255,255,255,0.15); padding: 15px; border-radius: 10px; text-align: center; }
  .stat-number { font-size: 2.5em; font-weight: bold; }
  .stat-label { font-size: 1em; opacity: 0.9; margin-top: 5px; }
  .section { margin-bottom: 50px; }
  .section-header { background: linear-gradient(to right, #3498db, #2980b9); color: white; padding: 20px 30px; border-radius: 10px 10px 0 0; margin-bottom: 0; }
  .section-header h2 { font-size: 1.8em; }
  .section-description { background: white; padding: 20px 30px; border-left: 5px solid #3498db; margin-bottom: 30px; }
  .section.advanced .section-header { background: linear-gradient(to right, #27ae60, #229954); }
  .section.advanced .section-description { border-left-color: #27ae60; }
  .figure-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(600px, 1fr)); gap: 30px; padding: 0 10px; }
  .figure-card { background: white; border-radius: 12px; overflow: hidden; box-shadow: 0 5px 20px rgba(0,0,0,0.08); transition: all 0.3s ease; }
  .figure-card:hover { transform: translateY(-8px); box-shadow: 0 15px 40px rgba(0,0,0,0.15); }
  .figure-card img { width: 100%; display: block; border-bottom: 3px solid #3498db; }
  .figure-card .info { padding: 20px; }
  .figure-card .title { font-size: 1.1em; font-weight: 600; color: #2c3e50; margin-bottom: 10px; }
  .figure-card .description { font-size: 0.95em; color: #666; line-height: 1.6; }
  .section.advanced .figure-card img { border-bottom-color: #27ae60; }
  .next-steps { background: linear-gradient(135deg, #ffeaa7 0%, #fdcb6e 100%); padding: 30px; border-radius: 15px; margin-top: 50px; box-shadow: 0 5px 20px rgba(0,0,0,0.1); }
  .next-steps h2 { color: #2d3436; margin-bottom: 20px; }
  .next-steps ul { color: #2d3436; margin-left: 30px; line-height: 2; font-size: 1.05em; }
  .footer { text-align: center; padding: 40px; background: #2c3e50; color: white; border-radius: 15px; margin-top: 50px; }
  .footer p { margin: 5px 0; }
  .footer .main { font-size: 1.4em; font-weight: bold; }
</style>
</head>
<body>
<div class='container'>

<h1>🎯 PASO 1 COMPLETO</h1>
<div class='subtitle'>Análisis Inicial del Pipeline de miRNA con Figuras Mejoradas</div>

<div class='stats-banner'>
  <h2>📊 Resumen del Análisis</h2>
  <div class='stats-grid'>
    <div class='stat-item'>
      <div class='stat-number'>", length(figuras_base_ok), "</div>
      <div class='stat-label'>Figuras Base</div>
    </div>
    <div class='stat-item'>
      <div class='stat-number'>", length(figuras_avanzadas_ok), "</div>
      <div class='stat-label'>Figuras Avanzadas</div>
    </div>
    <div class='stat-item'>
      <div class='stat-number'>", length(figuras_base_ok) + length(figuras_avanzadas_ok), "</div>
      <div class='stat-label'>Total</div>
    </div>
  </div>
</div>

<div class='section'>
  <div class='section-header'><h2>🔍 FIGURAS BASE - Análisis Inicial Seleccionado</h2></div>
  <div class='section-description'>
    <p>Visualizaciones fundamentales seleccionadas por su calidad y relevancia para responder las preguntas clave del análisis inicial: evolución del dataset, espectro de mutaciones G>X, análisis de la región semilla y fracción posicional.</p>
  </div>
  <div class='figure-grid'>")

# Descripciones para figuras base
desc_base <- list(
  "panel_a_overview.png" = "Vista general del dataset: evolución y estadísticas básicas",
  "panel_a_overview_CORRECTED.png" = "Vista general corregida con métricas actualizadas",
  "panel_c_spectrum_CORRECTED.png" = "Espectro G>X por posición - Figura favorita del usuario",
  "panel_c_seed_interaction_CORRECTED.png" = "Análisis de interacciones en la región semilla",
  "panel_d_positional_fraction_CORRECTED.png" = "Fracción posicional de mutaciones",
  "panel_f_ultra_clean_spectrum_BACKUP_20251016_203451.png" = "Espectro ultra limpio de tipos de mutación"
)

for (fig in figuras_base_ok) {
  nombre <- basename(fig)
  desc <- if (!is.null(desc_base[[nombre]])) desc_base[[nombre]] else "Análisis del dataset"
  html <- paste0(html, "
    <div class='figure-card'>
      <img src='", fig, "' alt='", nombre, "'>
      <div class='info'>
        <div class='title'>", nombre, "</div>
        <div class='description'>", desc, "</div>
      </div>
    </div>")
}

html <- paste0(html, "
  </div>
</div>

<div class='section advanced'>
  <div class='section-header'><h2>🚀 FIGURAS AVANZADAS - Análisis Profesionales Mejorados</h2></div>
  <div class='section-description'>
    <p><strong>Figuras regeneradas con mejoras profesionales:</strong> datos reales del pipeline, estadísticas integradas, estilo científico de alta calidad y visualizaciones especializadas para caracterización global, análisis posicional y distribuciones cuantitativas.</p>
  </div>
  <div class='figure-grid'>")

# Descripciones detalladas
desc_avanzadas <- list(
  "2.1_volcano_gt_enrichment_improved.png" = "<strong>Volcano Plot de Enriquecimiento G>T:</strong> Identifica miRNAs significativamente afectados por estrés oxidativo. Top 10 miRNAs etiquetados, líneas de significancia estadística (p < 0.05, |FC| > 0.5).",
  "2.2_boxplot_seed_regions_improved.png" = "<strong>Distribución G>T por Región Funcional:</strong> Violin + Boxplot mostrando la carga oxidativa en Seed, Middle, 3' End y 5' End. Incluye jitter para distribución completa y media marcada.",
  "3.1_positional_heatmap_improved.png" = "<strong>Heatmap Posicional de G>T:</strong> Top 30 miRNAs con mayor frecuencia de mutaciones oxidativas. Normalización por miRNA, región seed resaltada, gradiente blanco-rojo profesional.",
  "3.2_line_plot_positional_improved.png" = "<strong>Frecuencia de Mutaciones por Posición:</strong> Comparación de G>T vs G>A, G>C y otras mutaciones a lo largo del miRNA. Región seed sombreada, frecuencias relativas (%).",
  "5.1_cdf_plot_improved.png" = "<strong>Distribución Acumulada (CDF):</strong> Carga oxidativa global en miRNAs. Líneas de mediana y media anotadas, escala de porcentajes profesional.",
  "5.2_ridge_plot_improved.png" = "<strong>Comparación Seed vs Non-Seed:</strong> Distribución de proporción G>T entre regiones funcionales. Violin plot horizontal con mediana integrada."
)

for (fig in figuras_avanzadas_ok) {
  nombre <- basename(fig)
  desc <- if (!is.null(desc_avanzadas[[nombre]])) desc_avanzadas[[nombre]] else "Análisis avanzado profesional"
  html <- paste0(html, "
    <div class='figure-card'>
      <img src='", fig, "' alt='", nombre, "'>
      <div class='info'>
        <div class='title'>", nombre, "</div>
        <div class='description'>", desc, "</div>
      </div>
    </div>")
}

html <- paste0(html, "
  </div>
</div>

<div class='next-steps'>
  <h2>🎯 Próximos Pasos del Pipeline</h2>
  <p><strong>Con este análisis inicial completo y mejorado, el pipeline está preparado para:</strong></p>
  <ul>
    <li><strong>Paso 2:</strong> Análisis de VAF (Variant Allele Frequency) y heterogeneidad entre muestras</li>
    <li><strong>Paso 3:</strong> Comparaciones estadísticas rigurosas ALS vs Control</li>
    <li><strong>Paso 4:</strong> Análisis funcional de targets y pathways enriquecidos</li>
    <li><strong>Paso 5:</strong> Integración con datos clínicos y validación experimental</li>
  </ul>
</div>

<div class='footer'>
  <p class='main'>Pipeline de Análisis de miRNA - UCSD</p>
  <p style='margin-top: 15px;'>Generado: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "</p>
  <p style='font-size: 1.1em; margin-top: 10px;'><strong>Total: ", length(figuras_base_ok) + length(figuras_avanzadas_ok), " figuras profesionales</strong> | Base: ", length(figuras_base_ok), " | Avanzadas: ", length(figuras_avanzadas_ok), "</p>
</div>

</div>
</body>
</html>")

# Guardar y abrir
output_file <- "PASO_1_COMPLETO_MEJORADO_V2.html"
writeLines(html, output_file)

cat("✅ HTML FINAL MEJORADO V2 CREADO\n")
cat("📁 Archivo:", output_file, "\n")
cat("📊 Total de figuras:", length(figuras_base_ok) + length(figuras_avanzadas_ok), "\n")
cat("  - Figuras base:", length(figuras_base_ok), "\n")
cat("  - Figuras avanzadas mejoradas:", length(figuras_avanzadas_ok), "\n")

system(paste("open", output_file))
cat("🌐 HTML abierto en navegador\n")
