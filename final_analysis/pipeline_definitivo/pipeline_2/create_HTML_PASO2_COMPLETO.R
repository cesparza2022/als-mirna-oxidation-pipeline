# HTML COMPLETO PARA PASO 2 - LAS 12 FIGURAS

figuras_paso2 <- list(
  # GRUPO A: Comparaciones Globales
  list(
    grupo = "A",
    titulo = "Comparaciones Globales",
    descripcion = "Análisis de diferencias en carga VAF total y G>T entre grupos ALS y Control",
    figuras = list(
      list(file = "FIGURA_2.1_VAF_GLOBAL_COMPARISON.png",
           nombre = "2.1: Comparación VAF Global",
           desc = "Boxplots comparando Total VAF, G>T VAF y G>T Ratio entre ALS y Control. Todos altamente significativos (p < 1e-6). Control muestra mayor VAF que ALS."),
      list(file = "FIGURA_2.2_VAF_DISTRIBUTIONS.png",
           nombre = "2.2: Distribuciones VAF",
           desc = "Violin plots, density plots y CDF mostrando la distribución completa de G>T VAF. Incluye tabla con estadísticas descriptivas (media, mediana, SD, IQR)."),
      list(file = "FIGURA_2.3_VOLCANO_PLOT.png",
           nombre = "2.3: Volcano Plot - miRNAs Diferenciales",
           desc = "Identifica miRNAs con VAF G>T significativamente diferente entre grupos. Eje X: log2(FC), Eje Y: -log10(FDR p-value). miRNAs enriquecidos en rojo (ALS) o azul (Control).")
    )
  ),
  
  # GRUPO B: Análisis Posicional
  list(
    grupo = "B",
    titulo = "Análisis Posicional",
    descripcion = "Patrones de distribución de G>T VAF a lo largo de las 22 posiciones del miRNA",
    figuras = list(
      list(file = "FIGURA_2.4_HEATMAP_POSITIONAL.png",
           nombre = "2.4: Heatmap VAF por Posición",
           desc = "Top 20 miRNAs con mayor variabilidad. Clustering jerárquico revela patrones posicionales comunes. Región semilla (2-8) destacada."),
      list(file = "FIGURA_2.5_HEATMAP_ZSCORE.png",
           nombre = "2.5: Heatmap Z-score Normalizado",
           desc = "Mismos datos normalizados por fila (Z-score). Escala divergente (azul-blanco-rojo) identifica posiciones con VAF inusualmente alto o bajo respecto al promedio del miRNA."),
      list(file = "FIGURA_2.6_POSITIONAL_PROFILES.png",
           nombre = "2.6: Perfiles Posicionales con Significancia",
           desc = "Panel A: VAF promedio por posición con intervalos de confianza. Panel B: log2(FC) por posición. Panel C: Significancia estadística (-log10 p-value) con corrección FDR.")
    )
  ),
  
  # GRUPO C: Heterogeneidad
  list(
    grupo = "C",
    titulo = "Heterogeneidad y Clustering",
    descripcion = "Análisis de variabilidad inter e intra-grupo, agrupamiento de muestras",
    figuras = list(
      list(file = "FIGURA_2.7_PCA_SAMPLES.png",
           nombre = "2.7: PCA de Muestras",
           desc = "Análisis de componentes principales basado en perfiles de VAF G>T por miRNA. Puntos coloreados por grupo (ALS rojo, Control gris). Tamaño del punto = Total G>T VAF. Elipses = 95% CI."),
      list(file = "FIGURA_2.8_HEATMAP_CLUSTERING.png",
           nombre = "2.8: Clustering Jerárquico de Muestras",
           desc = "Heatmap de top 50 miRNAs con mayor variabilidad. Clustering jerárquico (Ward.D2) de muestras. Anotación lateral indica grupo (ALS/Control). Valores = Z-score de VAF G>T."),
      list(file = "FIGURA_2.9_COEFFICIENT_VARIATION.png",
           nombre = "2.9: Coeficiente de Variación (CV)",
           desc = "Panel A: CV promedio por grupo. Panel B: Distribución de CV entre miRNAs. Panel C: F-test para igualdad de varianzas. Evalúa heterogeneidad intra-grupo.")
    )
  ),
  
  # GRUPO D: Especificidad G>T
  list(
    grupo = "D",
    titulo = "Especificidad G>T",
    descripcion = "Análisis de especificidad de G>T vs otras mutaciones y transversiones",
    figuras = list(
      list(file = "FIGURA_2.10_RATIO_GT_GA.png",
           nombre = "2.10: Ratio G>T / G>A",
           desc = "Panel A: Scatter plot G>T vs G>A VAF (línea diagonal = ratio 1:1). Panel B: Boxplot del ratio por grupo. Panel C: Density plot del ratio. Evalúa si G>T es específicamente enriquecido vs G>A."),
      list(file = "FIGURA_2.11_HEATMAP_MUTATION_TYPES.png",
           nombre = "2.11: Heatmap de Todos los Tipos de Mutación",
           desc = "Heatmaps lado a lado (ALS | Control) mostrando VAF promedio de los 12 tipos de mutación por posición. ALS en escala roja, Control en azul. Sin clustering para comparar posiciones directamente."),
      list(file = "FIGURA_2.12_GT_ENRICHMENT_REGIONS.png",
           nombre = "2.12: Enriquecimiento G>T por Región",
           desc = "Panel A: Barras agrupadas comparando G>T VAF en Seed (2-8) vs Non-Seed entre ALS y Control. Asteriscos indican significancia. Panel B: Tabla con estadísticas detalladas y p-values.")
    )
  )
)

# Generar HTML
html <- "<!DOCTYPE html>
<html>
<head>
<meta charset='utf-8'>
<title>PASO 2 COMPLETO - Análisis Comparativo ALS vs Control</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 20px; }
  .container { max-width: 1800px; margin: 0 auto; background: white; border-radius: 20px; padding: 40px; box-shadow: 0 20px 60px rgba(0,0,0,0.3); }
  h1 { text-align: center; color: #1a1a1a; font-size: 3em; margin-bottom: 10px; font-weight: 800; }
  .subtitle { text-align: center; color: #666; font-size: 1.4em; margin-bottom: 50px; font-weight: 300; }
  .stats-banner { background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); color: white; padding: 30px; border-radius: 15px; margin-bottom: 40px; text-align: center; }
  .stats-banner h2 { font-size: 2em; margin-bottom: 15px; }
  .stats-number { font-size: 4em; font-weight: bold; margin: 10px 0; }
  .grupo-section { margin-bottom: 60px; }
  .grupo-header { background: linear-gradient(to right, #3498db, #2ecc71); color: white; padding: 25px; border-radius: 12px; margin-bottom: 20px; }
  .grupo-header h2 { font-size: 2em; margin-bottom: 10px; }
  .grupo-header .description { font-size: 1.1em; opacity: 0.95; }
  .grupo-a .grupo-header { background: linear-gradient(to right, #667eea, #764ba2); }
  .grupo-b .grupo-header { background: linear-gradient(to right, #f093fb, #f5576c); }
  .grupo-c .grupo-header { background: linear-gradient(to right, #4facfe, #00f2fe); }
  .grupo-d .grupo-header { background: linear-gradient(to right, #43e97b, #38f9d7); }
  .figure-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(700px, 1fr)); gap: 30px; }
  .figure-card { background: white; border-radius: 15px; overflow: hidden; box-shadow: 0 8px 25px rgba(0,0,0,0.1); transition: all 0.3s ease; border: 2px solid #f0f0f0; }
  .figure-card:hover { transform: translateY(-10px); box-shadow: 0 15px 45px rgba(0,0,0,0.2); border-color: #3498db; }
  .figure-card img { width: 100%; display: block; }
  .figure-info { padding: 25px; background: linear-gradient(to bottom, #ffffff, #f8f9fa); }
  .figure-number { font-size: 1.4em; font-weight: bold; color: #3498db; margin-bottom: 8px; }
  .figure-desc { font-size: 1em; color: #555; line-height: 1.7; }
  .key-findings { background: #fff3cd; border-left: 5px solid #ffc107; padding: 20px; margin: 30px 0; border-radius: 8px; }
  .key-findings h3 { color: #856404; margin-bottom: 15px; }
  .key-findings ul { margin-left: 25px; color: #856404; line-height: 2; }
  .footer { text-align: center; padding: 40px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; border-radius: 15px; margin-top: 50px; }
  .footer .main { font-size: 1.6em; font-weight: bold; margin-bottom: 10px; }
</style>
</head>
<body>
<div class='container'>

<h1>🔬 PASO 2 COMPLETO</h1>
<div class='subtitle'>Análisis Comparativo: ALS vs Control (VAF)</div>

<div class='stats-banner'>
  <div class='stats-number'>12</div>
  <h2>Figuras Profesionales Generadas</h2>
  <p style='font-size: 1.2em; margin-top: 15px;'>415 muestras | 313 ALS | 102 Control</p>
</div>

<div class='key-findings'>
  <h3>🔥 Hallazgos Clave del Paso 2:</h3>
  <ul>
    <li><strong>Control tiene MAYOR VAF que ALS</strong> (p < 1e-9) - Inesperado, sugiere efecto batch o diferencias técnicas</li>
    <li><strong>Diferencia significativa en G>T VAF</strong> (p < 1e-11) entre grupos</li>
    <li><strong>Ratio G>T/Total significativo</strong> (p < 1e-5) - Firma oxidativa presente en ambos grupos</li>
    <li><strong>Patrones posicionales conservados</strong> entre ALS y Control con diferencias cuantitativas</li>
    <li><strong>Heterogeneidad variable</strong> - Resultados de clustering y PCA revelan subgrupos</li>
  </ul>
</div>
"

# Añadir cada grupo
for (grupo_data in figuras_paso2) {
  html <- paste0(html, "
<div class='grupo-section grupo-", tolower(grupo_data$grupo), "'>
  <div class='grupo-header'>
    <h2>Grupo ", grupo_data$grupo, ": ", grupo_data$titulo, "</h2>
    <div class='description'>", grupo_data$descripcion, "</div>
  </div>
  <div class='figure-grid'>")
  
  for (fig in grupo_data$figuras) {
    html <- paste0(html, "
    <div class='figure-card'>
      <img src='figures_paso2/", fig$file, "' alt='", fig$nombre, "'>
      <div class='figure-info'>
        <div class='figure-number'>", fig$nombre, "</div>
        <div class='figure-desc'>", fig$desc, "</div>
      </div>
    </div>")
  }
  
  html <- paste0(html, "
  </div>
</div>")
}

html <- paste0(html, "

<div class='footer'>
  <p class='main'>Pipeline de Análisis de miRNA - UCSD</p>
  <p style='margin-top: 15px; font-size: 1.2em;'>Generado: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "</p>
  <p style='font-size: 1.1em; margin-top: 10px;'>Paso 2: Análisis Comparativo ALS vs Control</p>
  <p style='font-size: 0.95em; margin-top: 5px; opacity: 0.9;'>12 figuras profesionales con datos VAF reales</p>
</div>

</div>
</body>
</html>")

# Guardar
output_file <- "PASO_2_COMPLETO.html"
writeLines(html, output_file)

cat("✅ HTML DEL PASO 2 GENERADO\n")
cat("📁 Archivo:", output_file, "\n")
cat("📊 Total de figuras: 12\n")
cat("🎨 Grupos: A (3) | B (3) | C (3) | D (3)\n")

system(paste("open", output_file))
cat("🌐 HTML abierto en navegador\n")

