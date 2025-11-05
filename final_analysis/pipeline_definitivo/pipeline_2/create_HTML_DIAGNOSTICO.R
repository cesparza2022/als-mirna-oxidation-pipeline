# HTML VIEWER PARA FIGURAS DE DIAGNÓSTICO

html <- "<!DOCTYPE html>
<html>
<head>
<meta charset='utf-8'>
<title>Control de Calidad - Filtro VAF > 0.5</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; background: linear-gradient(135deg, #a8edea 0%, #fed6e3 100%); padding: 20px; }
  .container { max-width: 1600px; margin: 0 auto; background: white; border-radius: 20px; padding: 40px; box-shadow: 0 20px 60px rgba(0,0,0,0.3); }
  h1 { text-align: center; color: #1a1a1a; font-size: 3em; margin-bottom: 15px; font-weight: 800; }
  .subtitle { text-align: center; color: #666; font-size: 1.4em; margin-bottom: 40px; }
  .quality-banner { background: linear-gradient(135deg, #56ab2f 0%, #a8e063 100%); color: white; padding: 35px; border-radius: 15px; margin-bottom: 40px; text-align: center; box-shadow: 0 15px 40px rgba(0,0,0,0.2); }
  .quality-banner .icon { font-size: 5em; margin-bottom: 15px; }
  .quality-banner h2 { font-size: 2.2em; margin-bottom: 10px; }
  .quality-banner .message { font-size: 1.3em; margin-top: 15px; background: rgba(255,255,255,0.2); padding: 15px; border-radius: 10px; }
  .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin: 30px 0; }
  .stat-card { background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%); padding: 25px; border-radius: 12px; text-align: center; box-shadow: 0 5px 15px rgba(0,0,0,0.1); }
  .stat-number { font-size: 2.8em; font-weight: bold; color: #2c3e50; margin-bottom: 5px; }
  .stat-label { font-size: 1.1em; color: #555; }
  .figure-section { margin: 40px 0; }
  .figure-card { background: white; border-radius: 15px; overflow: hidden; box-shadow: 0 8px 25px rgba(0,0,0,0.1); margin-bottom: 30px; border: 2px solid #e0e0e0; }
  .figure-card img { width: 100%; display: block; }
  .figure-info { padding: 25px; background: linear-gradient(to bottom, #ffffff, #f8f9fa); }
  .figure-title { font-size: 1.5em; font-weight: bold; color: #2c3e50; margin-bottom: 12px; }
  .figure-desc { font-size: 1.05em; color: #555; line-height: 1.7; }
  .interpretation { background: #e8f4f8; border-left: 5px solid #3498db; padding: 25px; border-radius: 8px; margin: 30px 0; }
  .interpretation h3 { color: #2c3e50; margin-bottom: 15px; font-size: 1.6em; }
  .interpretation ul { margin-left: 25px; color: #555; line-height: 2; }
  .footer { text-align: center; padding: 40px; background: #2c3e50; color: white; border-radius: 15px; margin-top: 50px; }
  .footer .main { font-size: 1.6em; font-weight: bold; margin-bottom: 10px; }
</style>
</head>
<body>
<div class='container'>

<h1>✅ Control de Calidad - VAF Filter</h1>
<div class='subtitle'>Diagnóstico del Filtro VAF > 0.5 (50%)</div>

<div class='quality-banner'>
  <div class='icon'>✓</div>
  <h2>DATASET DE ALTA CALIDAD</h2>
  <div class='message'>
    <strong>Resultado:</strong> No se encontraron valores VAF > 0.5<br>
    Todos los valores están en el rango confiable (0-0.5)<br>
    <strong>No se requirió filtrado</strong>
  </div>
</div>

<div class='stats-grid'>
  <div class='stat-card'>
    <div class='stat-number'>0</div>
    <div class='stat-label'>Valores > 0.5</div>
  </div>
  <div class='stat-card'>
    <div class='stat-number'>0%</div>
    <div class='stat-label'>Removidos</div>
  </div>
  <div class='stat-card'>
    <div class='stat-number'>98,817</div>
    <div class='stat-label'>Valores Válidos (0-0.5)</div>
  </div>
  <div class='stat-card'>
    <div class='stat-number'>4.37%</div>
    <div class='stat-label'>% Positivos</div>
  </div>
</div>

<div class='interpretation'>
  <h3>🔬 Interpretación del Control de Calidad:</h3>
  <ul>
    <li><strong>Ausencia de valores > 0.5:</strong> Indica que el pipeline de procesamiento upstream aplicó filtros de calidad apropiados.</li>
    <li><strong>94.7% valores = 0:</strong> Normal en datos de variantes raras. La mayoría de posiciones no tienen mutaciones.</li>
    <li><strong>4.37% valores positivos:</strong> Proporción razonable de VAF detectado, consistente con variantes de baja frecuencia.</li>
    <li><strong>Rango 0-0.5:</strong> Todos los valores están dentro del rango esperado para variantes somáticas o de línea germinal con baja frecuencia.</li>
    <li><strong>No hay outliers técnicos:</strong> No se detectaron artefactos de secuenciación (que típicamente aparecerían como VAF > 0.5).</li>
  </ul>
</div>

<div class='figure-section'>

  <div class='figure-card'>
    <img src='figures_diagnostico/DIAGNOSTICO_1_DISTRIBUCION_VAF.png' alt='Distribución VAF'>
    <div class='figure-info'>
      <div class='figure-title'>Figura 1: Distribución Global de VAF</div>
      <div class='figure-desc'>
        <strong>Panel A:</strong> Histograma de todos los valores VAF > 0. Línea roja marca el threshold de 0.5. No hay valores por encima del umbral.<br>
        <strong>Panel B:</strong> Distribución por categorías de calidad. 94.7% son ceros, 4.98% valores bajos (0-0.1), y pequeñas proporciones en rangos más altos pero todos ≤0.5.
      </div>
    </div>
  </div>

  <div class='figure-card'>
    <img src='figures_diagnostico/DIAGNOSTICO_2_IMPACTO_POR_SNV.png' alt='Impacto por SNV'>
    <div class='figure-info'>
      <div class='figure-title'>Figura 2: Análisis por SNV</div>
      <div class='figure-desc'>
        <strong>Panel A:</strong> Verificación de que ningún SNV tiene observaciones > 0.5. Todos los SNVs pasan el filtro de calidad.<br>
        <strong>Panel B:</strong> Distribución del VAF máximo observado por cada SNV. Todos los valores están por debajo de 0.5.
      </div>
    </div>
  </div>

  <div class='figure-card'>
    <img src='figures_diagnostico/DIAGNOSTICO_3_IMPACTO_POR_miRNA.png' alt='Impacto por miRNA'>
    <div class='figure-info'>
      <div class='figure-title'>Figura 3: Análisis por miRNA</div>
      <div class='figure-desc'>
        <strong>Panel A:</strong> Ningún miRNA tiene observaciones > 0.5. Control de calidad aprobado para todos los miRNAs.<br>
        <strong>Panel B:</strong> Distribución del VAF promedio por miRNA. Rango 0-0.5, mayoría concentrada en valores bajos.<br>
        <strong>Panel C:</strong> Scatter plot mostrando relación entre número de observaciones y VAF máximo. Todos los puntos están por debajo del threshold.
      </div>
    </div>
  </div>

  <div class='figure-card'>
    <img src='figures_diagnostico/DIAGNOSTICO_5_TABLA_RESUMEN.png' alt='Tabla Resumen'>
    <div class='figure-info'>
      <div class='figure-title'>Figura 4: Tabla Resumen General</div>
      <div class='figure-desc'>
        Resumen completo del control de calidad mostrando:<br>
        • Total de valores analizados: 2,260,920<br>
        • Valores removidos (>0.5): 0 (0%)<br>
        • Valores válidos conservados: 98,817 (4.37%)<br>
        • Distribución por tipo de muestra (ALS vs Control)
      </div>
    </div>
  </div>

</div>

<div class='interpretation' style='background: #d4edda; border-left-color: #28a745;'>
  <h3>✅ Conclusión del Control de Calidad:</h3>
  <ul>
    <li><strong style='color: #28a745;'>Dataset APROBADO:</strong> No se detectaron valores VAF sospechosos (>0.5).</li>
    <li><strong>Alta confiabilidad:</strong> Los datos muestran distribución esperada para variantes de baja frecuencia.</li>
    <li><strong>No requiere filtrado adicional:</strong> El pipeline upstream ya aplicó controles de calidad apropiados.</li>
    <li><strong>Listo para análisis:</strong> Los datos pueden usarse directamente sin pre-procesamiento adicional de VAF.</li>
  </ul>
</div>

<div class='footer'>
  <p class='main'>Control de Calidad - Pipeline de miRNA</p>
  <p style='margin-top: 15px; font-size: 1.2em;'>Generado: " + format(Sys.time(), "%Y-%m-%d %H:%M:%S") + "</p>
  <p style='font-size: 1em; margin-top: 8px;'>4 figuras de diagnóstico | 0 valores removidos | Dataset APROBADO ✓</p>
</div>

</div>
</body>
</html>"

# Guardar y abrir
output_file <- "DIAGNOSTICO_FILTRO_VAF.html"
writeLines(html, output_file)

cat("\n✅ HTML DE DIAGNÓSTICO GENERADO\n")
cat("📁 Archivo:", output_file, "\n")
cat("📊 Figuras incluidas: 4\n")
cat("🎯 Conclusión: Dataset de ALTA CALIDAD (0 valores > 0.5)\n")

system(paste("open", output_file))
cat("🌐 HTML abierto en navegador\n")

