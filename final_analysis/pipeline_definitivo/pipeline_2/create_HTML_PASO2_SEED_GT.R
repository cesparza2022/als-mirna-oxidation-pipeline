# HTML ACTUALIZADO - PASO 2 CON CRITERIO SEED G>T

# Definir figuras (mezclando originales y actualizadas)
figuras <- data.frame(
  file = c(
    "FIGURA_2.1_VAF_GLOBAL_COMPARISON.png",
    "FIGURA_2.2_VAF_DISTRIBUTIONS.png",
    "FIGURA_2.3_VOLCANO_PLOT_SEED_GT.png",  # ACTUALIZADA
    "FIGURA_2.4_HEATMAP_POSITIONAL_SEED_GT.png",  # ACTUALIZADA
    "FIGURA_2.5_HEATMAP_ZSCORE_SEED_GT.png",  # ACTUALIZADA
    "FIGURA_2.6_POSITIONAL_PROFILES.png",
    "FIGURA_2.7_PCA_SAMPLES_SEED_GT.png",  # ACTUALIZADA
    "FIGURA_2.8_HEATMAP_CLUSTERING_SEED_GT.png",  # ACTUALIZADA
    "FIGURA_2.9_COEFFICIENT_VARIATION.png",
    "FIGURA_2.10_RATIO_GT_GA.png",
    "FIGURA_2.11_HEATMAP_MUTATION_TYPES.png",
    "FIGURA_2.12_GT_ENRICHMENT_REGIONS.png"
  ),
  numero = c("2.1", "2.2", "2.3", "2.4", "2.5", "2.6", "2.7", "2.8", "2.9", "2.10", "2.11", "2.12"),
  nombre = c(
    "Comparación VAF Global",
    "Distribuciones VAF",
    "Volcano Plot (Seed G>T miRNAs)",
    "Heatmap Posicional (Seed G>T)",
    "Heatmap Z-score (Seed G>T)",
    "Perfiles Posicionales + Significancia",
    "PCA de Muestras (Seed G>T)",
    "Clustering Jerárquico (Seed G>T)",
    "Coeficiente de Variación",
    "Ratio G>T / G>A",
    "Heatmap de Tipos de Mutación",
    "Enriquecimiento por Región"
  ),
  descripcion = c(
    "3 paneles comparando Total VAF, G>T VAF y G>T Ratio entre ALS y Control. Tests de Wilcoxon muestran diferencias altamente significativas (p < 1e-6). <strong>Control muestra mayor VAF que ALS.</strong>",
    "Violin plots, density plots y CDF mostrando distribución completa de G>T VAF. Incluye tabla con estadísticas descriptivas. KS-test para comparar distribuciones.",
    "<strong>ACTUALIZADO:</strong> Volcano plot usando SOLO los 30 miRNAs con mayor G>T VAF en región semilla. Identifica miRNAs diferencialmente afectados con FDR < 0.05.",
    "<strong>ACTUALIZADO:</strong> Heatmaps lado a lado (ALS | Control) de top 30 miRNAs con G>T en seed. VAF por posición 1-22. Clustering jerárquico revela patrones comunes.",
    "<strong>ACTUALIZADO:</strong> Mismos 30 miRNAs normalizados por Z-score. Escala divergente (azul-blanco-rojo) destaca posiciones con VAF inusualmente alto/bajo.",
    "3 paneles: (A) Line plot de VAF promedio por posición con intervalos de confianza, (B) log2(FC) por posición, (C) Significancia estadística con corrección FDR. Región semilla resaltada.",
    "<strong>ACTUALIZADO:</strong> PCA basado SOLO en los 30 miRNAs con G>T en seed. Puntos coloreados por grupo, tamaño = Total VAF. Elipses de confianza 95%. Evalúa separación de grupos.",
    "<strong>ACTUALIZADO:</strong> Clustering jerárquico usando los 30 miRNAs con G>T en seed. Valores = Z-score de VAF. Anotación lateral por grupo. Método Ward.D2.",
    "CV (Coeficiente de Variación) por grupo. Panel A: CV promedio, Panel B: Distribución de CV, Panel C: F-test. Evalúa heterogeneidad intra-grupo.",
    "3 paneles evaluando especificidad de G>T vs G>A. (A) Scatter plot con línea diagonal 1:1, (B) Boxplot del ratio por grupo, (C) Density plot del ratio.",
    "Heatmaps comparativos (ALS | Control) de los 12 tipos de mutación por posición 1-22. ALS en rojo, Control en azul. Sin clustering para comparar directamente.",
    "Comparación de G>T VAF entre región Seed (2-8) y Non-Seed. Panel A: Barras agrupadas con asteriscos de significancia. Panel B: Tabla con estadísticas detalladas."
  ),
  grupo = c("A", "A", "A", "B", "B", "B", "C", "C", "C", "D", "D", "D"),
  stringsAsFactors = FALSE
)

# HTML
html <- paste0("<!DOCTYPE html>
<html>
<head>
<meta charset='utf-8'>
<title>PASO 2 - Análisis ALS vs Control (Seed G>T miRNAs)</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 20px; }
  .container { max-width: 1800px; margin: 0 auto; background: white; border-radius: 20px; padding: 40px; box-shadow: 0 20px 60px rgba(0,0,0,0.3); }
  h1 { text-align: center; color: #1a1a1a; font-size: 3em; margin-bottom: 10px; font-weight: 800; }
  .subtitle { text-align: center; color: #666; font-size: 1.4em; margin-bottom: 50px; font-weight: 300; }
  .highlight-box { background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); color: white; padding: 30px; border-radius: 15px; margin-bottom: 40px; text-align: center; }
  .highlight-box h2 { font-size: 2em; margin-bottom: 15px; }
  .highlight-box .big { font-size: 4em; font-weight: bold; margin: 10px 0; }
  .highlight-box .note { font-size: 1.2em; margin-top: 15px; background: rgba(255,255,255,0.2); padding: 15px; border-radius: 10px; }
  .key-findings { background: #fff3cd; border-left: 5px solid #ffc107; padding: 25px; margin: 30px 0; border-radius: 8px; }
  .key-findings h3 { color: #856404; margin-bottom: 15px; font-size: 1.5em; }
  .key-findings ul { margin-left: 25px; color: #856404; line-height: 2; }
  .grupo-section { margin-bottom: 60px; }
  .grupo-header { padding: 25px; border-radius: 12px; margin-bottom: 20px; color: white; }
  .grupo-a .grupo-header { background: linear-gradient(to right, #667eea, #764ba2); }
  .grupo-b .grupo-header { background: linear-gradient(to right, #f093fb, #f5576c); }
  .grupo-c .grupo-header { background: linear-gradient(to right, #4facfe, #00f2fe); }
  .grupo-d .grupo-header { background: linear-gradient(to right, #43e97b, #38f9d7); }
  .grupo-header h2 { font-size: 2em; margin-bottom: 10px; }
  .grupo-header .description { font-size: 1.1em; opacity: 0.95; }
  .figure-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(700px, 1fr)); gap: 30px; }
  .figure-card { background: white; border-radius: 15px; overflow: hidden; box-shadow: 0 8px 25px rgba(0,0,0,0.1); transition: all 0.3s ease; border: 2px solid #f0f0f0; }
  .figure-card:hover { transform: translateY(-10px); box-shadow: 0 15px 45px rgba(0,0,0,0.2); border-color: #3498db; }
  .figure-card img { width: 100%; display: block; }
  .figure-info { padding: 25px; background: linear-gradient(to bottom, #ffffff, #f8f9fa); }
  .figure-number { font-size: 1.5em; font-weight: bold; color: #3498db; margin-bottom: 10px; }
  .figure-desc { font-size: 1em; color: #555; line-height: 1.7; }
  .updated-badge { background: #28a745; color: white; padding: 5px 12px; border-radius: 20px; font-size: 0.8em; font-weight: bold; margin-left: 10px; }
  .footer { text-align: center; padding: 40px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; border-radius: 15px; margin-top: 50px; }
  .footer .main { font-size: 1.6em; font-weight: bold; margin-bottom: 10px; }
</style>
</head>
<body>
<div class='container'>

<h1>🔬 PASO 2 COMPLETO</h1>
<div class='subtitle'>Análisis Comparativo: ALS vs Control (VAF)</div>

<div class='highlight-box'>
  <div class='big'>12</div>
  <h2>Figuras Profesionales</h2>
  <p style='font-size: 1.3em; margin-top: 10px;'>415 muestras | 313 ALS | 102 Control</p>
  <div class='note'>
    <strong>🎯 NUEVO CRITERIO:</strong> Figuras enfocadas en los <strong>301 miRNAs con G>T en región SEED (2-8)</strong><br>
    Top 30 miRNAs seleccionados por mayor VAF de G>T en seed
  </div>
</div>

<div class='key-findings'>
  <h3>🔥 Hallazgos Clave del Paso 2:</h3>
  <ul>
    <li><strong>301 miRNAs tienen G>T en la región semilla</strong> - Crítico para función regulatoria</li>
    <li><strong>Control tiene MAYOR VAF que ALS</strong> (p < 1e-9) - Sugiere diferencias técnicas o efecto batch</li>
    <li><strong>Top miRNA: hsa-miR-6129</strong> con VAF seed G>T = 14.6</li>
    <li><strong>Diferencias significativas en G>T VAF</strong> (p < 1e-11) entre grupos</li>
    <li><strong>Patrones posicionales conservados</strong> con diferencias cuantitativas</li>
    <li><strong>PCA muestra separación parcial</strong> usando miRNAs seed G>T</li>
  </ul>
</div>
")

# Añadir figuras por grupo
for (grupo_letra in c("A", "B", "C", "D")) {
  grupo_figuras <- figuras[figuras$grupo == grupo_letra, ]
  
  grupo_titulo <- c(
    "A" = "Comparaciones Globales",
    "B" = "Análisis Posicional",
    "C" = "Heterogeneidad y Clustering",
    "D" = "Especificidad G>T"
  )[grupo_letra]
  
  grupo_desc <- c(
    "A" = "Diferencias en carga VAF total y G>T entre grupos ALS y Control",
    "B" = "Patrones de G>T VAF a lo largo de las 22 posiciones del miRNA (usando miRNAs seed G>T)",
    "C" = "Variabilidad inter e intra-grupo, agrupamiento de muestras (usando miRNAs seed G>T)",
    "D" = "Especificidad de G>T vs otras mutaciones y transversiones"
  )[grupo_letra]
  
  html <- paste0(html, "
<div class='grupo-section grupo-", tolower(grupo_letra), "'>
  <div class='grupo-header'>
    <h2>Grupo ", grupo_letra, ": ", grupo_titulo, "</h2>
    <div class='description'>", grupo_desc, "</div>
  </div>
  <div class='figure-grid'>")
  
  for (i in 1:nrow(grupo_figuras)) {
    fig <- grupo_figuras[i, ]
    is_updated <- grepl("SEED_GT", fig$file)
    badge <- if (is_updated) "<span class='updated-badge'>ACTUALIZADO</span>" else ""
    
    html <- paste0(html, "
    <div class='figure-card'>
      <img src='figures_paso2/", fig$file, "' alt='", fig$nombre, "'>
      <div class='figure-info'>
        <div class='figure-number'>Figura ", fig$numero, ": ", fig$nombre, badge, "</div>
        <div class='figure-desc'>", fig$descripcion, "</div>
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
  <p style='font-size: 1em; margin-top: 5px; opacity: 0.9;'><strong>12 figuras</strong> | 5 actualizadas con criterio Seed G>T | 301 miRNAs con G>T en seed</p>
</div>

</div>
</body>
</html>")

# Guardar
output_file <- "PASO_2_COMPLETO_SEED_GT.html"
writeLines(html, output_file)

cat("✅ HTML ACTUALIZADO CON CRITERIO SEED G>T\n")
cat("📁 Archivo:", output_file, "\n")
cat("📊 Total de figuras: 12\n")
cat("   - 5 actualizadas con criterio Seed G>T\n")
cat("   - 7 originales (no requieren actualización)\n")
cat("🎯 Criterio: miRNAs con G>T en región semilla (posiciones 2-8)\n")

system(paste("open", output_file))
cat("🌐 HTML abierto en navegador\n")

