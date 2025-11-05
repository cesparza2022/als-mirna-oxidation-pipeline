# HTML FINAL CON FIGURAS BASE + VAF REALES (SIN REPETICIONES)

figuras_base <- c(
  # "figures/panel_a_overview.png",  # ELIMINADO - Redundante
  "figures/panel_a_overview_CORRECTED.png",  # ✅ ÚNICO PANEL A
  "figures/panel_c_spectrum_CORRECTED.png",
  "figures/panel_c_seed_interaction_CORRECTED.png",
  "figures/panel_d_positional_fraction_CORRECTED.png",
  "figures/panel_f_ultra_clean_spectrum_BACKUP_20251016_203451.png"
)

figuras_vaf <- c(
  "figures_vaf/2.1_volcano_gt_vaf.png",
  "figures_vaf/2.2_boxplot_seed_regions_vaf.png",
  "figures_vaf/3.1_positional_heatmap_vaf.png",
  "figures_vaf/3.2_line_plot_positional_vaf.png",
  "figures_vaf/5.1_cdf_plot_vaf.png",
  "figures_vaf/5.2_distribution_vaf.png"
)

figuras_base_ok <- figuras_base[file.exists(figuras_base)]
figuras_vaf_ok <- figuras_vaf[file.exists(figuras_vaf)]

cat("✅ Figuras base (sin repeticiones):", length(figuras_base_ok), "\n")
cat("✅ Figuras VAF reales:", length(figuras_vaf_ok), "\n")

# HTML
html <- paste0("
<!DOCTYPE html>
<html>
<head>
<meta charset='utf-8'>
<title>PASO 1 COMPLETO - Figuras Base + VAF Reales</title>
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
  .section.vaf .section-header { background: linear-gradient(to right, #e74c3c, #c0392b); }
  .section.vaf .section-description { border-left-color: #e74c3c; }
  .figure-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(600px, 1fr)); gap: 30px; padding: 0 10px; }
  .figure-card { background: white; border-radius: 12px; overflow: hidden; box-shadow: 0 5px 20px rgba(0,0,0,0.08); transition: all 0.3s ease; }
  .figure-card:hover { transform: translateY(-8px); box-shadow: 0 15px 40px rgba(0,0,0,0.15); }
  .figure-card img { width: 100%; display: block; border-bottom: 3px solid #3498db; }
  .figure-card .info { padding: 20px; }
  .figure-card .title { font-size: 1.1em; font-weight: 600; color: #2c3e50; margin-bottom: 10px; }
  .figure-card .description { font-size: 0.95em; color: #666; line-height: 1.6; }
  .section.vaf .figure-card img { border-bottom-color: #e74c3c; }
  .next-steps { background: linear-gradient(135deg, #ffeaa7 0%, #fdcb6e 100%); padding: 30px; border-radius: 15px; margin-top: 50px; box-shadow: 0 5px 20px rgba(0,0,0,0.1); }
  .next-steps h2 { color: #2d3436; margin-bottom: 20px; }
  .next-steps ul { color: #2d3436; margin-left: 30px; line-height: 2; font-size: 1.05em; }
  .footer { text-align: center; padding: 40px; background: #2c3e50; color: white; border-radius: 15px; margin-top: 50px; }
  .footer p { margin: 5px 0; }
  .footer .main { font-size: 1.4em; font-weight: bold; }
  .highlight { background: #fff3cd; padding: 15px; border-radius: 8px; border-left: 4px solid #ffc107; margin: 20px 0; }
</style>
</head>
<body>
<div class='container'>

<h1>🎯 PASO 1 COMPLETO</h1>
<div class='subtitle'>Análisis Inicial del Pipeline de miRNA con Datos VAF Reales</div>

<div class='stats-banner'>
  <h2>📊 Resumen del Análisis</h2>
  <div class='stats-grid'>
    <div class='stat-item'>
      <div class='stat-number'>", length(figuras_base_ok), "</div>
      <div class='stat-label'>Figuras Base</div>
    </div>
    <div class='stat-item'>
      <div class='stat-number'>", length(figuras_vaf_ok), "</div>
      <div class='stat-label'>Figuras VAF</div>
    </div>
    <div class='stat-item'>
      <div class='stat-number'>", length(figuras_base_ok) + length(figuras_vaf_ok), "</div>
      <div class='stat-label'>Total</div>
    </div>
  </div>
</div>

<div class='highlight'>
  <strong>🔬 Datos VAF Reales:</strong> Las figuras avanzadas utilizan datos reales de Variant Allele Frequency (VAF) del pipeline, mostrando valores decimales que representan la frecuencia de variantes en las muestras. Esto proporciona una representación más precisa de la carga mutacional.
</div>

<div class='section'>
  <div class='section-header'><h2>🔍 FIGURAS BASE - Análisis Inicial Seleccionado (Sin Repeticiones)</h2></div>
  <div class='section-description'>
    <p>Visualizaciones fundamentales seleccionadas por su calidad y relevancia para responder las preguntas clave del análisis inicial. <strong>Se eliminó la redundancia del panel A, conservando solo la versión CORRECTED.</strong></p>
  </div>
  <div class='figure-grid'>")

# Descripciones para figuras base (ACTUALIZADO)
desc_base <- list(
  "panel_a_overview_CORRECTED.png" = "<strong>Panel A:</strong> Vista general corregida del dataset - Evolución y estadísticas básicas actualizadas",
  "panel_c_spectrum_CORRECTED.png" = "<strong>Panel C:</strong> Espectro G>X por posición - Tu figura favorita con región semilla resaltada",
  "panel_c_seed_interaction_CORRECTED.png" = "<strong>Panel C:</strong> Análisis de interacciones en la región semilla",
  "panel_d_positional_fraction_CORRECTED.png" = "<strong>Panel D:</strong> Fracción posicional de mutaciones G>T vs otras",
  "panel_f_ultra_clean_spectrum_BACKUP_20251016_203451.png" = "<strong>Panel F:</strong> Espectro ultra limpio de todos los tipos de mutación"
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

<div class='section vaf'>
  <div class='section-header'><h2>🧬 FIGURAS VAF - Análisis con Datos Reales</h2></div>
  <div class='section-description'>
    <p><strong>Figuras generadas con datos VAF reales:</strong> Utilizan Variant Allele Frequency (frecuencia de variantes) de las muestras del pipeline. Los valores VAF representan la proporción de reads que contienen la variante específica, proporcionando una medida cuantitativa precisa de la carga mutacional.</p>
  </div>
  <div class='figure-grid'>")

# Descripciones detalladas para VAF
desc_vaf <- list(
  "2.1_volcano_gt_vaf.png" = "<strong>Volcano Plot VAF G>T:</strong> Enriquecimiento basado en VAF promedio por miRNA. Identifica miRNAs con mayor carga oxidativa usando datos reales de frecuencia de variantes.",
  "2.2_boxplot_seed_regions_vaf.png" = "<strong>VAF G>T por Región:</strong> Distribución de VAF promedio en regiones funcionales. Escala log para visualizar rangos amplios de VAF.",
  "3.1_positional_heatmap_vaf.png" = "<strong>Heatmap Posicional VAF:</strong> Top 20 miRNAs con mayor VAF de G>T por posición. Normalización por miRNA para comparabilidad.",
  "3.2_line_plot_positional_vaf.png" = "<strong>VAF por Posición:</strong> VAF promedio de G>T vs otras mutaciones a lo largo del miRNA. Escala log para visualizar diferencias de magnitud.",
  "5.1_cdf_plot_vaf.png" = "<strong>CDF de VAF G>T:</strong> Distribución acumulada de VAF promedio por miRNA. Mediana y media anotadas en escala log.",
  "5.2_distribution_vaf.png" = "<strong>Distribución VAF por Región:</strong> Comparación de VAF entre Seed y Non-Seed. Violin plot con escala log para visualizar distribuciones."
)

for (fig in figuras_vaf_ok) {
  nombre <- basename(fig)
  desc <- if (!is.null(desc_vaf[[nombre]])) desc_vaf[[nombre]] else "Análisis VAF profesional"
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
  <p><strong>Con este análisis inicial completo usando datos VAF reales, el pipeline está preparado para:</strong></p>
  <ul>
    <li><strong>Paso 2:</strong> Análisis de heterogeneidad VAF entre muestras y clusters</li>
    <li><strong>Paso 3:</strong> Comparaciones estadísticas ALS vs Control usando VAF</li>
    <li><strong>Paso 4:</strong> Análisis funcional de targets con miRNAs de alta VAF</li>
    <li><strong>Paso 5:</strong> Correlación VAF con datos clínicos y supervivencia</li>
  </ul>
</div>

<div class='footer'>
  <p class='main'>Pipeline de Análisis de miRNA - UCSD</p>
  <p style='margin-top: 15px;'>Generado: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "</p>
  <p style='font-size: 1.1em; margin-top: 10px;'><strong>Total: ", length(figuras_base_ok) + length(figuras_vaf_ok), " figuras con datos reales</strong> | Base: ", length(figuras_base_ok), " | VAF: ", length(figuras_vaf_ok), "</p>
  <p style='font-size: 0.9em; margin-top: 10px; color: #95a5a6;'>✅ Redundancias eliminadas - Solo figuras únicas y relevantes</p>
</div>

</div>
</body>
</html>")

# Guardar y abrir
output_file <- "PASO_1_COMPLETO_VAF_FINAL.html"
writeLines(html, output_file)

cat("✅ HTML FINAL ACTUALIZADO (SIN REPETICIONES)\n")
cat("📁 Archivo:", output_file, "\n")
cat("📊 Total de figuras:", length(figuras_base_ok) + length(figuras_vaf_ok), "\n")
cat("  - Figuras base (sin repetir):", length(figuras_base_ok), "\n")
cat("  - Figuras VAF reales:", length(figuras_vaf_ok), "\n")
cat("  ✅ Redundancia del Panel A eliminada\n")

system(paste("open", output_file))
cat("🌐 HTML actualizado abierto en navegador\n")
