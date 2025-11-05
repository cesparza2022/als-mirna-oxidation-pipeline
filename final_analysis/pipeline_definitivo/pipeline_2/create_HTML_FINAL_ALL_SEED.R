# HTML FINAL - PASO 2 CON TODOS LOS miRNAs SEED G>T

figuras <- list(
  list(num = "2.1", file = "figures_paso2/FIGURA_2.1_VAF_GLOBAL_COMPARISON.png",
       nombre = "Comparación VAF Global (ALS vs Control)",
       desc = "Boxplots de Total VAF, G>T VAF y G>T Ratio. Tests Wilcoxon muestran diferencias altamente significativas. <strong>Control > ALS</strong> (posible efecto batch)."),
  
  list(num = "2.2", file = "figures_paso2/FIGURA_2.2_VAF_DISTRIBUTIONS.png",
       nombre = "Distribuciones VAF Completas",
       desc = "Violin plots, density plots y CDF de G>T VAF. Incluye tabla con estadísticas descriptivas (media, mediana, SD, IQR)."),
  
  list(num = "2.3", file = "figures_paso2_ALL_SEED/FIGURA_2.3_VOLCANO_ALL_SEED_GT.png",
       nombre = "Volcano Plot - TODOS los miRNAs Seed G>T (n=295)",
       desc = "<strong>ACTUALIZADO:</strong> Usa los <strong>295 miRNAs con G>T en región semilla</strong> (de 301 totales). Identifica miRNAs diferencialmente afectados con FDR < 0.05. Top 15 miRNAs etiquetados."),
  
  list(num = "2.4", file = "figures_paso2_ALL_SEED/FIGURA_2.4_HEATMAP_TOP50_ALL_SEED_GT.png",
       nombre = "Heatmap Posicional - Top 50 (de 301 Seed G>T)",
       desc = "<strong>ACTUALIZADO:</strong> Top 50 miRNAs con mayor VAF seed G>T (de los 301 totales). Heatmaps ALS|Control lado a lado. Clustering jerárquico. Posiciones 1-22."),
  
  list(num = "2.5", file = "figures_paso2_ALL_SEED/FIGURA_2.5_HEATMAP_ZSCORE_TOP50.png",
       nombre = "Heatmap Z-score - Top 50",
       desc = "<strong>ACTUALIZADO:</strong> Mismos 50 miRNAs normalizados por Z-score. Escala divergente destaca posiciones con VAF inusualmente alto/bajo."),
  
  list(num = "2.6", file = "figures_paso2/FIGURA_2.6_POSITIONAL_PROFILES.png",
       nombre = "Perfiles Posicionales + Significancia",
       desc = "3 paneles: (A) VAF promedio ± SE, (B) log2(FC), (C) -log10(p-value). Región semilla resaltada. FDR correction."),
  
  list(num = "2.7", file = "figures_paso2_ALL_SEED/FIGURA_2.7_PCA_ALL_SEED_GT.png",
       nombre = "PCA - Usando TODOS los miRNAs Seed G>T (n=41)",
       desc = "<strong>ACTUALIZADO:</strong> PCA basado en perfil VAF de <strong>41 miRNAs con varianza suficiente</strong> (de 301 con seed G>T). Elipses 95% CI. Tamaño = Total VAF."),
  
  list(num = "2.8", file = "figures_paso2_ALL_SEED/FIGURA_2.8_HEATMAP_ALL_SEED_GT.png",
       nombre = "Clustering Jerárquico - TODOS (n=41)",
       desc = "<strong>ACTUALIZADO:</strong> Clustering de 415 muestras usando <strong>41 miRNAs seed G>T</strong>. Ward.D2. Z-score. Anotación lateral por grupo."),
  
  list(num = "2.9", file = "figures_paso2/FIGURA_2.9_COEFFICIENT_VARIATION.png",
       nombre = "Coeficiente de Variación",
       desc = "CV por grupo. Panel A: Promedio, B: Distribución, C: F-test. Evalúa heterogeneidad intra-grupo."),
  
  list(num = "2.10", file = "figures_paso2/FIGURA_2.10_RATIO_GT_GA.png",
       nombre = "Ratio G>T / G>A",
       desc = "Especificidad de G>T vs G>A. Scatter plot, boxplot y density. Línea diagonal 1:1 en scatter."),
  
  list(num = "2.11", file = "figures_paso2/FIGURA_2.11_HEATMAP_MUTATION_TYPES.png",
       nombre = "Heatmap de Tipos de Mutación",
       desc = "12 tipos de mutación por posición. ALS (rojo) | Control (azul) lado a lado. Sin clustering."),
  
  list(num = "2.12", file = "figures_paso2/FIGURA_2.12_GT_ENRICHMENT_REGIONS.png",
       nombre = "Enriquecimiento G>T por Región",
       desc = "Seed (2-8) vs Non-Seed. Barras agrupadas con asteriscos de significancia. Tabla con estadísticas.")
)

# HTML
html <- paste0("<!DOCTYPE html>
<html>
<head>
<meta charset='utf-8'>
<title>PASO 2 FINAL - Análisis ALS vs Control (TODOS los Seed G>T)</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 20px; }
  .container { max-width: 1900px; margin: 0 auto; background: white; border-radius: 20px; padding: 45px; box-shadow: 0 25px 70px rgba(0,0,0,0.35); }
  h1 { text-align: center; color: #1a1a1a; font-size: 3.2em; margin-bottom: 12px; font-weight: 800; letter-spacing: -1px; }
  .subtitle { text-align: center; color: #666; font-size: 1.5em; margin-bottom: 50px; font-weight: 300; }
  .hero-banner { background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); color: white; padding: 40px; border-radius: 18px; margin-bottom: 40px; text-align: center; box-shadow: 0 15px 40px rgba(0,0,0,0.2); }
  .hero-banner .big { font-size: 5em; font-weight: 900; margin: 15px 0; text-shadow: 0 4px 8px rgba(0,0,0,0.2); }
  .hero-banner .subtitle-hero { font-size: 1.4em; margin-top: 15px; }
  .hero-banner .note { font-size: 1.15em; margin-top: 20px; background: rgba(255,255,255,0.25); padding: 18px; border-radius: 12px; line-height: 1.6; }
  .key-findings { background: linear-gradient(to right, #fff3cd, #ffeaa7); border-left: 6px solid #f39c12; padding: 30px; margin: 35px 0; border-radius: 10px; box-shadow: 0 5px 20px rgba(0,0,0,0.08); }
  .key-findings h3 { color: #856404; margin-bottom: 18px; font-size: 1.7em; }
  .key-findings ul { margin-left: 30px; color: #856404; line-height: 2.2; font-size: 1.05em; }
  .key-findings strong { color: #c0392b; }
  .figure-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(800px, 1fr)); gap: 35px; margin: 40px 0; }
  .figure-card { background: white; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.12); transition: all 0.35s ease; border: 3px solid #f0f0f0; }
  .figure-card:hover { transform: translateY(-12px) scale(1.01); box-shadow: 0 20px 50px rgba(0,0,0,0.25); border-color: #3498db; }
  .figure-card img { width: 100%; display: block; transition: all 0.3s ease; }
  .figure-card:hover img { filter: brightness(1.05); }
  .figure-info { padding: 28px; background: linear-gradient(to bottom, #ffffff, #f8f9fa); }
  .figure-number { font-size: 1.6em; font-weight: bold; color: #2c3e50; margin-bottom: 12px; }
  .figure-desc { font-size: 1.05em; color: #555; line-height: 1.8; }
  .updated-badge { background: linear-gradient(135deg, #28a745, #20c997); color: white; padding: 6px 14px; border-radius: 25px; font-size: 0.75em; font-weight: bold; margin-left: 12px; box-shadow: 0 3px 10px rgba(40,167,69,0.3); }
  .divider { height: 3px; background: linear-gradient(to right, #667eea, #764ba2); margin: 50px 0; border-radius: 2px; }
  .footer { text-align: center; padding: 45px; background: linear-gradient(135deg, #2c3e50, #34495e); color: white; border-radius: 18px; margin-top: 60px; box-shadow: 0 10px 30px rgba(0,0,0,0.3); }
  .footer .main { font-size: 1.8em; font-weight: bold; margin-bottom: 15px; }
</style>
</head>
<body>
<div class='container'>

<h1>🔬 PASO 2 - VERSIÓN FINAL</h1>
<div class='subtitle'>Análisis Comparativo ALS vs Control con TODOS los miRNAs Seed G>T</div>

<div class='hero-banner'>
  <div class='big'>301</div>
  <div class='subtitle-hero'>miRNAs con G>T en Región SEED Identificados</div>
  <div class='note'>
    <strong>🎯 CRITERIO FINAL:</strong><br>
    ✓ Usamos <strong>TODOS los 301 miRNAs</strong> con G>T en región semilla (posiciones 2-8)<br>
    ✓ <strong>41 miRNAs</strong> con varianza suficiente para PCA/Clustering<br>
    ✓ <strong>Top 50</strong> mostrados en heatmaps posicionales<br>
    ✓ <strong>295 miRNAs</strong> testeados en Volcano Plot<br>
    ✓ <strong>Sin filtro VAF > 0.5</strong> (no hay valores tan altos en el dataset)
  </div>
</div>

<div class='key-findings'>
  <h3>🔥 Hallazgos Clave del Análisis Final:</h3>
  <ul>
    <li><strong>301 miRNAs</strong> tienen G>T en región semilla → críticos para regulación génica</li>
    <li><strong>Control muestra mayor VAF que ALS</strong> (p < 1e-9) → sugiere efecto técnico/batch</li>
    <li><strong>295 miRNAs testeados</strong> estadísticamente en comparación ALS vs Control</li>
    <li><strong>41 miRNAs</strong> con varianza robusta usados en análisis multivariado (PCA/Clustering)</li>
    <li><strong>Separación parcial</strong> en PCA usando perfil completo de seed G>T miRNAs</li>
    <li><strong>Top miRNA: hsa-miR-6129</strong> (VAF seed = 14.6) → candidato para validación</li>
  </ul>
</div>

<div class='divider'></div>

<h2 style='text-align: center; margin: 40px 0; color: #2c3e50; font-size: 2em;'>📊 Las 12 Figuras del Paso 2</h2>

<div class='figure-grid'>")

for (fig in figuras) {
  is_updated <- grepl("ALL_SEED", fig$file)
  badge <- if (is_updated) "<span class='updated-badge'>ACTUALIZADO - TODOS</span>" else ""
  
  html <- paste0(html, "
  <div class='figure-card'>
    <img src='", fig$file, "' alt='Figura ", fig$num, "'>
    <div class='figure-info'>
      <div class='figure-number'>Figura ", fig$num, ": ", fig$nombre, badge, "</div>
      <div class='figure-desc'>", fig$desc, "</div>
    </div>
  </div>")
}

html <- paste0(html, "
</div>

<div class='divider'></div>

<div style='background: #e8f4f8; padding: 30px; border-radius: 12px; margin: 40px 0; border-left: 5px solid #3498db;'>
  <h3 style='color: #2c3e50; margin-bottom: 15px; font-size: 1.6em;'>📋 Archivos Generados:</h3>
  <ul style='color: #555; line-height: 2; font-size: 1.05em; margin-left: 25px;'>
    <li><strong>metadata.csv</strong> - 415 muestras clasificadas (313 ALS, 102 Control)</li>
    <li><strong>ALL_SEED_GT_miRNAs_COMPLETE.csv</strong> - Lista de 301 miRNAs con G>T en seed</li>
    <li><strong>final_processed_data_FILTERED_VAF50.csv</strong> - Datos pre-procesados (aunque no había VAF > 0.5)</li>
    <li><strong>figures_paso2/</strong> - 7 figuras originales</li>
    <li><strong>figures_paso2_ALL_SEED/</strong> - 5 figuras actualizadas con criterio ALL seed G>T</li>
  </ul>
</div>

<div class='footer'>
  <p class='main'>Pipeline de Análisis de miRNA - UCSD</p>
  <p style='margin-top: 18px; font-size: 1.3em;'>Generado: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "</p>
  <p style='font-size: 1.15em; margin-top: 12px;'><strong>Paso 2 Completo:</strong> Análisis Comparativo ALS vs Control</p>
  <p style='font-size: 1em; margin-top: 8px; opacity: 0.9;'>12 figuras | 301 miRNAs seed G>T | 415 muestras</p>
</div>

</div>
</body>
</html>")

# Guardar
output_file <- "PASO_2_FINAL_ALL_SEED_GT.html"
writeLines(html, output_file)

cat("✅ HTML FINAL GENERADO\n")
cat("📁 Archivo:", output_file, "\n")
cat("📊 Figuras totales: 12\n")
cat("   - 5 actualizadas con TODOS los seed G>T miRNAs\n")
cat("   - 7 originales (no requieren seed filtering)\n")
cat("🎯 Criterio: TODOS los 301 miRNAs con G>T en seed (2-8)\n")

system(paste("open", output_file))
cat("🌐 HTML final abierto en navegador\n")

