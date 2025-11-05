# HTML INTEGRADO - PASO 2 COMPLETO
# Parte 1: Diagnóstico + Parte 2: Análisis Comparativo

# Lista de figuras con su información
figuras_diagnostico <- list(
  list(num = "D1", file = "figures_diagnostico/DIAG_1_DISTRIBUCION_REAL.png",
       nombre = "Distribución Global de VAF",
       desc = "Histograma y categorías de VAF. Línea roja marca threshold = 0.5. Se identificaron 458 valores exactamente = 0.5 (artefactos)."),
  list(num = "D2", file = "figures_diagnostico/DIAG_2_IMPACTO_SNV_REAL.png",
       nombre = "Impacto por SNV",
       desc = "192 SNVs afectados. Top: hsa-miR-6129 13:GT (30 muestras), hsa-miR-6133 17:GA (26 muestras)."),
  list(num = "D3", file = "figures_diagnostico/DIAG_3_IMPACTO_miRNA_REAL.png",
       nombre = "Impacto por miRNA",
       desc = "126 miRNAs afectados. Top: hsa-miR-6133 (67 valores), hsa-miR-6129 (61 valores). Scatter muestra correlación entre SNVs y valores removidos."),
  list(num = "D4", file = "figures_diagnostico/DIAG_4_TABLA_RESUMEN_REAL.png",
       nombre = "Tabla Resumen del Filtrado",
       desc = "Estadísticas completas: 458 valores removidos (0.024% del total). Dataset limpio listo para análisis.")
)

figuras_analisis <- list(
  list(num = "2.1", file = "figures_paso2_CLEAN/FIG_2.1_VAF_GLOBAL_CLEAN.png",
       nombre = "Comparación VAF Global (CLEAN)",
       desc = "<strong>DATOS LIMPIOS:</strong> Boxplots de Total VAF, G>T VAF y G>T Ratio. Nueva p-value Total: 2.23e-11 (más significativo). Nueva p-value G>T: 2.50e-13."),
  list(num = "2.2", file = "figures_paso2_CLEAN/FIG_2.2_DISTRIBUTIONS_CLEAN.png",
       nombre = "Distribuciones VAF (CLEAN)",
       desc = "Violin plots y density plots con datos limpios. Sin valores capeados = 0.5."),
  list(num = "2.3", file = "figures_paso2_CLEAN/FIG_2.3_VOLCANO_CLEAN.png",
       nombre = "Volcano Plot (CLEAN - 301 Seed G>T miRNAs)",
       desc = "<strong>NUEVO RANKING:</strong> Usa los 301 miRNAs con G>T en seed. hsa-miR-378g es ahora #2 (sin artefactos). hsa-miR-6133 cayó a #4."),
  list(num = "2.4-2.5", file = "figures_paso2/FIGURA_2.4_HEATMAP_POSITIONAL.png",
       nombre = "Heatmaps Posicionales (pendiente actualizar)",
       desc = "Se actualizará con top 50 del nuevo ranking limpio."),
  list(num = "2.6", file = "figures_paso2_CLEAN/FIG_2.6_POSITIONAL_CLEAN.png",
       nombre = "Perfiles Posicionales",
       desc = "Line plots, log2(FC) y -log10(p-value) por posición. Región semilla resaltada."),
  list(num = "2.7-2.8", file = "figures_paso2/FIGURA_2.7_PCA_SAMPLES.png",
       nombre = "PCA y Clustering (pendiente actualizar)",
       desc = "Se actualizará con perfil de seed miRNAs limpios."),
  list(num = "2.9", file = "figures_paso2_CLEAN/FIG_2.9_CV_CLEAN.png",
       nombre = "Coeficiente de Variación",
       desc = "CV por grupo. Evalúa heterogeneidad intra-grupo."),
  list(num = "2.10", file = "figures_paso2_CLEAN/FIG_2.10_RATIO_CLEAN.png",
       nombre = "Ratio G>T / G>A",
       desc = "Especificidad de G>T vs G>A. Scatter, boxplot y density."),
  list(num = "2.11", file = "figures_paso2/FIGURA_2.8_HEATMAP_CLUSTERING.png",
       nombre = "Heatmap Mutation Types (placeholder)",
       desc = "Pendiente generar con datos limpios."),
  list(num = "2.12", file = "figures_paso2_CLEAN/FIG_2.12_ENRICHMENT_CLEAN.png",
       nombre = "Enriquecimiento por Región",
       desc = "Seed vs Non-Seed. Barras agrupadas con asteriscos de significancia.")
)

# Generar HTML
html <- '<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>PASO 2 COMPLETO - QC + Análisis ALS vs Control</title>
<style>
body { font-family: Arial, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 20px; margin: 0; }
.container { max-width: 1900px; margin: 0 auto; background: white; border-radius: 20px; padding: 45px; box-shadow: 0 25px 70px rgba(0,0,0,0.4); }
h1 { text-align: center; color: #1a1a1a; font-size: 3.5em; margin-bottom: 12px; font-weight: 900; }
.subtitle { text-align: center; color: #666; font-size: 1.5em; margin-bottom: 50px; }
.part-divider { background: linear-gradient(to right, #667eea, #764ba2); height: 4px; margin: 60px 0; border-radius: 2px; }
.part-header { background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); color: white; padding: 35px; border-radius: 15px; text-align: center; margin-bottom: 40px; }
.part-header h2 { font-size: 2.5em; margin-bottom: 15px; }
.part-header .desc { font-size: 1.3em; line-height: 1.6; }
.qc-banner { background: linear-gradient(135deg, #e74c3c, #c0392b); color: white; padding: 30px; border-radius: 12px; margin-bottom: 30px; text-align: center; }
.qc-banner .big { font-size: 4.5em; font-weight: bold; margin: 10px 0; }
.analysis-banner { background: linear-gradient(135deg, #27ae60, #2ecc71); color: white; padding: 30px; border-radius: 12px; margin-bottom: 30px; text-align: center; }
.analysis-banner .big { font-size: 4.5em; font-weight: bold; margin: 10px 0; }
.key-findings { background: #fff3cd; border-left: 6px solid #f39c12; padding: 25px; border-radius: 10px; margin: 30px 0; }
.key-findings h3 { color: #856404; margin-bottom: 15px; font-size: 1.7em; }
.key-findings ul { color: #856404; margin-left: 25px; line-height: 2; font-size: 1.05em; }
.figure-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(700px, 1fr)); gap: 30px; margin: 35px 0; }
.figure-card { background: white; border-radius: 14px; overflow: hidden; box-shadow: 0 8px 25px rgba(0,0,0,0.12); border: 2px solid #e0e0e0; transition: all 0.3s; }
.figure-card:hover { transform: translateY(-8px); box-shadow: 0 15px 40px rgba(0,0,0,0.25); border-color: #3498db; }
.figure-card img { width: 100%; display: block; }
.figure-info { padding: 25px; background: linear-gradient(to bottom, #fff, #f8f9fa); }
.figure-num { font-size: 1.5em; font-weight: bold; color: #2c3e50; margin-bottom: 10px; }
.figure-desc { font-size: 1em; color: #555; line-height: 1.7; }
.footer { text-align: center; padding: 40px; background: linear-gradient(135deg, #2c3e50, #34495e); color: white; border-radius: 15px; margin-top: 50px; }
</style>
</head>
<body>
<div class="container">

<h1>🔬 PASO 2 COMPLETO</h1>
<div class="subtitle">Control de Calidad + Análisis Comparativo ALS vs Control</div>

<div class="part-divider"></div>

<!-- PARTE 1: DIAGNÓSTICO -->
<div class="part-header">
  <h2>🛡️ PARTE 1: CONTROL DE CALIDAD</h2>
  <div class="desc">Identificación y remoción de artefactos técnicos (VAF ≥ 0.5)</div>
</div>

<div class="qc-banner">
  <div class="big">458</div>
  <h3>Valores Removidos (VAF = 0.5)</h3>
  <p style="font-size: 1.2em; margin-top: 15px;">192 SNVs afectados | 126 miRNAs afectados | 0.024% del total</p>
</div>

<div class="key-findings">
  <h3>🔍 Hallazgos del Control de Calidad:</h3>
  <ul>
    <li><strong>458 valores exactamente = 0.5</strong> - Artefactos técnicos (capping)</li>
    <li><strong>hsa-miR-6133:</strong> 67 valores removidos (83% de su VAF era artefacto)</li>
    <li><strong>hsa-miR-6129:</strong> 61 valores removidos (52% de su VAF era artefacto)</li>
    <li><strong>Top SNV removido:</strong> hsa-miR-6129 13:GT (30 muestras con VAF = 0.5)</li>
    <li><strong>Nuevo máximo VAF:</strong> 0.498 (todos los valores ahora < 0.5)</li>
  </ul>
</div>

<div class="figure-grid">'

for (fig in figuras_diagnostico) {
  html <- paste0(html, '
  <div class="figure-card">
    <img src="', fig$file, '" alt="', fig$nombre, '">
    <div class="figure-info">
      <div class="figure-num">Diagnóstico ', fig$num, ': ', fig$nombre, '</div>
      <div class="figure-desc">', fig$desc, '</div>
    </div>
  </div>')
}

html <- paste0(html, '
</div>

<div class="part-divider"></div>

<!-- PARTE 2: ANÁLISIS -->
<div class="part-header" style="background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);">
  <h2>📊 PARTE 2: ANÁLISIS COMPARATIVO</h2>
  <div class="desc">Comparación ALS vs Control usando DATOS LIMPIOS (301 miRNAs seed G>T)</div>
</div>

<div class="analysis-banner">
  <div class="big">301</div>
  <h3>miRNAs con G>T en Región SEED</h3>
  <p style="font-size: 1.2em; margin-top: 15px;">NUEVO RANKING sin artefactos | hsa-miR-378g es ahora #2</p>
</div>

<div class="key-findings" style="background: #d4edda; border-left-color: #28a745;">
  <h3 style="color: #155724;">✅ Hallazgos con Datos Limpios:</h3>
  <ul style="color: #155724;">
    <li><strong>NUEVO TOP 3:</strong> hsa-miR-6129 (7.09), hsa-miR-378g (4.92), hsa-miR-30b-3p (2.97)</li>
    <li><strong>hsa-miR-378g SUBIÓ a #2</strong> - Sin artefactos, candidato REAL para validación</li>
    <li><strong>Significancia MEJORÓ:</strong> p-value Total VAF = 2.23e-11 (vs 6.81e-10 antes)</li>
    <li><strong>Significancia MEJORÓ:</strong> p-value G>T VAF = 2.50e-13 (vs 9.75e-12 antes)</li>
    <li><strong>Control sigue > ALS</strong> pero diferencia más confiable sin artefactos</li>
  </ul>
</div>

<div class="figure-grid">')

for (fig in figuras_analisis) {
  html <- paste0(html, '
  <div class="figure-card">
    <img src="', fig$file, '" alt="', fig$nombre, '">
    <div class="figure-info">
      <div class="figure-num">Figura ', fig$num, ': ', fig$nombre, '</div>
      <div class="figure-desc">', fig$desc, '</div>
    </div>
  </div>')
}

html <- paste0(html, '
</div>

<div class="footer">
  <div style="font-size: 1.8em; font-weight: bold; margin-bottom: 12px;">Pipeline de Análisis de miRNA - UCSD</div>
  <div style="font-size: 1.2em; margin-top: 15px;">Generado: ', format(Sys.time(), "%Y-%m-%d %H:%M:%S"), '</div>
  <div style="font-size: 1.1em; margin-top: 10px;">Paso 2: QC + Análisis Comparativo</div>
  <div style="font-size: 1em; margin-top: 8px; opacity: 0.9;">4 figuras QC | 12 figuras análisis | 458 valores removidos | 301 miRNAs seed G>T</div>
</div>

</div>
</body>
</html>')

# Guardar
output_file <- "PASO_2_INTEGRADO_QC_ANALISIS.html"
writeLines(html, output_file)

cat("✅ HTML INTEGRADO CREADO\n")
cat("📁 Archivo:", output_file, "\n")
cat("📊 Estructura:\n")
cat("   PARTE 1: Control de Calidad (4 figuras)\n")
cat("   PARTE 2: Análisis Comparativo (12 figuras, 7 listas)\n")

system(paste("open", output_file))
cat("🌐 HTML abierto en navegador\n")

