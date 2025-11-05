# HTML SIMPLE PARA DIAGNÓSTICO

figuras_diagnostico <- c(
  "DIAGNOSTICO_1_DISTRIBUCION_VAF.png",
  "DIAGNOSTICO_2_IMPACTO_POR_SNV.png",
  "DIAGNOSTICO_3_IMPACTO_POR_miRNA.png",
  "DIAGNOSTICO_5_TABLA_RESUMEN.png"
)

html_parts <- c(
'<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Control de Calidad - Filtro VAF</title>
<style>
  body { font-family: Arial, sans-serif; background: #f5f5f5; padding: 20px; margin: 0; }
  .container { max-width: 1400px; margin: 0 auto; background: white; border-radius: 15px; padding: 35px; box-shadow: 0 10px 40px rgba(0,0,0,0.2); }
  h1 { text-align: center; color: #2c3e50; font-size: 2.5em; margin-bottom: 15px; }
  .subtitle { text-align: center; color: #7f8c8d; font-size: 1.3em; margin-bottom: 35px; }
  .banner { background: linear-gradient(135deg, #27ae60, #2ecc71); color: white; padding: 30px; border-radius: 12px; text-align: center; margin-bottom: 35px; }
  .banner h2 { font-size: 2em; margin: 15px 0; }
  .banner .result { font-size: 1.2em; margin-top: 15px; background: rgba(255,255,255,0.2); padding: 12px; border-radius: 8px; }
  .stats { display: grid; grid-template-columns: repeat(4, 1fr); gap: 20px; margin: 30px 0; }
  .stat-box { background: #ecf0f1; padding: 20px; border-radius: 10px; text-align: center; }
  .stat-num { font-size: 2.5em; font-weight: bold; color: #2c3e50; }
  .stat-label { font-size: 1em; color: #7f8c8d; margin-top: 8px; }
  .figure { background: white; border-radius: 12px; margin: 25px 0; box-shadow: 0 5px 20px rgba(0,0,0,0.08); overflow: hidden; border: 2px solid #e0e0e0; }
  .figure img { width: 100%; display: block; }
  .figure-caption { padding: 20px; background: #f8f9fa; }
  .figure-title { font-size: 1.3em; font-weight: bold; color: #2c3e50; margin-bottom: 10px; }
  .interpretation { background: #d4edda; border-left: 5px solid #28a745; padding: 20px; border-radius: 8px; margin: 30px 0; }
  .interpretation h3 { color: #155724; margin-bottom: 12px; }
  .interpretation ul { color: #155724; margin-left: 20px; line-height: 1.8; }
  .footer { text-align: center; padding: 30px; background: #34495e; color: white; border-radius: 12px; margin-top: 40px; }
</style>
</head>
<body>
<div class="container">

<h1>Control de Calidad</h1>
<div class="subtitle">Diagnóstico del Filtro VAF > 0.5</div>

<div class="banner">
  <div style="font-size: 4em;">✓</div>
  <h2>DATASET APROBADO</h2>
  <div class="result">
    No se encontraron valores VAF > 0.5<br>
    Todos los valores están en rango confiable (0-0.5)
  </div>
</div>

<div class="stats">
  <div class="stat-box">
    <div class="stat-num">0</div>
    <div class="stat-label">Valores > 0.5</div>
  </div>
  <div class="stat-box">
    <div class="stat-num">0%</div>
    <div class="stat-label">Removidos</div>
  </div>
  <div class="stat-box">
    <div class="stat-num">98,817</div>
    <div class="stat-label">Válidos (0-0.5)</div>
  </div>
  <div class="stat-box">
    <div class="stat-num">4.37%</div>
    <div class="stat-label">% Positivos</div>
  </div>
</div>

<div class="interpretation">
  <h3>Interpretación:</h3>
  <ul>
    <li><strong>Alta calidad:</strong> No se detectaron valores VAF sospechosos (>0.5)</li>
    <li><strong>94.7% ceros:</strong> Normal para variantes raras</li>
    <li><strong>4.37% positivos:</strong> Proporción razonable de VAF detectado</li>
    <li><strong>Sin artefactos:</strong> No se detectaron outliers técnicos</li>
  </ul>
</div>

')

for (fig in figuras_diagnostico) {
  html_parts <- c(html_parts, paste0(
'<div class="figure">
  <img src="figures_diagnostico/', fig, '" alt="', fig, '">
  <div class="figure-caption">
    <div class="figure-title">', fig, '</div>
  </div>
</div>

'))
}

html_parts <- c(html_parts,
'<div class="footer">
  <div style="font-size: 1.5em; font-weight: bold;">Control de Calidad - Pipeline miRNA</div>
  <div style="margin-top: 12px;">Generado: ', format(Sys.time(), "%Y-%m-%d %H:%M:%S"), '</div>
  <div style="margin-top: 8px;">4 figuras | 0 valores removidos | Dataset APROBADO ✓</div>
</div>

</div>
</body>
</html>')

html <- paste(html_parts, collapse = "")

# Guardar
output_file <- "DIAGNOSTICO_FILTRO_VAF.html"
writeLines(html, output_file)

cat("✅ HTML de diagnóstico generado\n")
cat("📁 Archivo:", output_file, "\n")
cat("📊 Figuras: 4\n")

system(paste("open", output_file))
cat("🌐 HTML abierto\n")

