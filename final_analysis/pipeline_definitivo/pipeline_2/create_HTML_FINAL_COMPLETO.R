# ============================================================================
# HTML FINAL: PASO 2 COMPLETO (QC + ANÁLISIS)
# Con las 12 figuras actualizadas + Volcano Plot método correcto
# ============================================================================

library(rmarkdown)

cat("🎯 CREANDO HTML FINAL DEL PASO 2 (COMPLETO)\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

# Verificar figuras
figuras_qc <- c(
  "figures_diagnostico/DIAG_1_VAF_DISTRIBUTION.png",
  "figures_diagnostico/DIAG_2_IMPACT_BY_SNV.png",
  "figures_diagnostico/DIAG_3_IMPACT_BY_MIRNA.png",
  "figures_diagnostico/DIAG_4_SUMMARY_TABLE.png"
)

figuras_paso2 <- c(
  "figures_paso2_CLEAN/FIG_2.1_VAF_GLOBAL_CLEAN.png",
  "figures_paso2_CLEAN/FIG_2.2_DISTRIBUTIONS_CLEAN.png",
  "figures_paso2_CLEAN/FIG_2.3_VOLCANO_PER_SAMPLE_METHOD.png",  # ⭐ Volcano correcto
  "figures_paso2_CLEAN/FIG_2.4_HEATMAP_TOP50_CLEAN.png",
  "figures_paso2_CLEAN/FIG_2.5_HEATMAP_ZSCORE_CLEAN.png",
  "figures_paso2_CLEAN/FIG_2.6_POSITIONAL_CLEAN.png",
  "figures_paso2_CLEAN/FIG_2.7_PCA_CLEAN.png",
  "figures_paso2_CLEAN/FIG_2.8_CLUSTERING_CLEAN.png",
  "figures_paso2_CLEAN/FIG_2.9_CV_CLEAN.png",
  "figures_paso2_CLEAN/FIG_2.10_RATIO_CLEAN.png",
  "figures_paso2_CLEAN/FIG_2.11_MUTATION_TYPES_CLEAN.png",
  "figures_paso2_CLEAN/FIG_2.12_ENRICHMENT_CLEAN.png"
)

qc_ok <- sum(file.exists(figuras_qc))
paso2_ok <- sum(file.exists(figuras_paso2))

cat("✅ Figuras QC:", qc_ok, "/", length(figuras_qc), "\n")
cat("✅ Figuras Paso 2:", paso2_ok, "/", length(figuras_paso2), "\n\n")

html_content <- "---
title: \"PASO 2 COMPLETO: Control de Calidad + Análisis Comparativo\"
output: html_document
---

<style>
  body { font-family: 'Helvetica Neue', Arial, sans-serif; background: #f5f5f5; padding: 20px; color: #333; }
  .container { max-width: 1400px; margin: auto; background: #fff; padding: 40px; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }
  h1 { text-align: center; color: #2c3e50; font-size: 2.5em; margin-bottom: 10px; border-bottom: 4px solid #3498db; padding-bottom: 20px; }
  h2 { color: #2c3e50; margin-top: 50px; padding: 15px 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; border-radius: 8px; }
  h3 { color: #34495e; margin-top: 30px; padding-left: 15px; border-left: 5px solid #3498db; }
  .highlight-box { background: #fff3cd; border: 2px solid #ffc107; border-radius: 8px; padding: 20px; margin: 30px 0; }
  .highlight-box h3 { color: #856404; margin-top: 0; border-left: none; }
  .key-finding { background: #d4edda; border-left: 5px solid #28a745; padding: 15px; margin: 20px 0; border-radius: 5px; }
  .warning-box { background: #f8d7da; border-left: 5px solid #dc3545; padding: 15px; margin: 20px 0; border-radius: 5px; }
  .figure-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(600px, 1fr)); gap: 30px; margin: 30px 0; }
  .figure-item { background: #fff; border: 2px solid #ddd; border-radius: 10px; padding: 15px; transition: transform 0.2s, box-shadow 0.2s; }
  .figure-item:hover { transform: translateY(-5px); box-shadow: 0 8px 25px rgba(0,0,0,0.15); }
  .figure-item img { width: 100%; height: auto; border-radius: 8px; }
  .figure-title { font-weight: bold; font-size: 1.1em; color: #2c3e50; margin-bottom: 10px; text-align: center; padding: 10px; background: #ecf0f1; border-radius: 5px; }
  .badge { display: inline-block; padding: 5px 10px; border-radius: 12px; font-size: 0.85em; font-weight: bold; margin-left: 10px; }
  .badge-new { background: #28a745; color: white; }
  .badge-critical { background: #dc3545; color: white; }
  .badge-method { background: #007bff; color: white; }
  .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin: 20px 0; }
  .stat-card { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 10px; text-align: center; }
  .stat-number { font-size: 2.5em; font-weight: bold; }
  .stat-label { font-size: 1em; opacity: 0.9; margin-top: 5px; }
  .footer { text-align: center; margin-top: 60px; padding-top: 30px; border-top: 3px solid #e0e0e0; color: #777; }
  ul { line-height: 1.8; }
  code { background: #f4f4f4; padding: 2px 6px; border-radius: 3px; font-family: 'Courier New', monospace; }
</style>

<div class=\"container\">
  <h1>📊 PASO 2 COMPLETO: Control de Calidad + Análisis Comparativo</h1>
  <p style=\"text-align: center; font-size: 1.2em; color: #555; margin-bottom: 40px;\">Datos limpios + Método correcto + 12 figuras completas</p>
  
  <div class=\"stats-grid\">
    <div class=\"stat-card\">
      <div class=\"stat-number\">458</div>
      <div class=\"stat-label\">Valores VAF = 0.5<br/>Removidos (Artefactos)</div>
    </div>
    <div class=\"stat-card\">
      <div class=\"stat-number\">301</div>
      <div class=\"stat-label\">miRNAs con G>T<br/>en Seed (Limpios)</div>
    </div>
    <div class=\"stat-card\">
      <div class=\"stat-number\">3</div>
      <div class=\"stat-label\">miRNAs Enriquecidos<br/>en ALS</div>
    </div>
    <div class=\"stat-card\">
      <div class=\"stat-number\">22</div>
      <div class=\"stat-label\">miRNAs Enriquecidos<br/>en Control</div>
    </div>
  </div>

  <hr style=\"margin: 50px 0; border: 2px solid #3498db;\">

  <h2>🔍 PARTE 1: CONTROL DE CALIDAD (VAF Filter)</h2>
  
  <div class=\"highlight-box\">
    <h3>⚠️ HALLAZGO CRÍTICO: Artefactos Técnicos</h3>
    <p><strong>458 valores VAF = 0.5</strong> fueron identificados como artefactos técnicos (capping).</p>
    <ul>
      <li><strong>192 SNVs afectados</strong> (3.5% del total)</li>
      <li><strong>126 miRNAs afectados</strong> (41.9% de los seed G>T)</li>
      <li><strong>Top 2 miRNAs originales</strong> eran mayormente artefactos:
        <ul>
          <li>hsa-miR-6133: 12.7 → 2.16 (<strong>83% artefacto</strong>)</li>
          <li>hsa-miR-6129: 14.6 → 7.09 (<strong>52% artefacto</strong>)</li>
        </ul>
      </li>
    </ul>
    <p><strong>Acción:</strong> Todos los valores VAF ≥ 0.5 fueron convertidos a <code>NA</code>.</p>
  </div>

  <div class=\"figure-grid\">"

# Añadir figuras QC
qc_titles <- c(
  "Distribución Global de VAF",
  "Impacto del Filtro por SNV",
  "Impacto del Filtro por miRNA",
  "Tabla Resumen"
)

for (i in seq_along(figuras_qc)) {
  if (file.exists(figuras_qc[i])) {
    html_content <- paste0(html_content,
      "<div class=\"figure-item\">
        <div class=\"figure-title\">", qc_titles[i], "</div>
        <img src=\"", figuras_qc[i], "\" alt=\"", basename(figuras_qc[i]), "\">
      </div>"
    )
  }
}

html_content <- paste0(html_content,
  "</div>

  <hr style=\"margin: 50px 0; border: 2px solid #3498db;\">

  <h2>📊 PARTE 2: ANÁLISIS COMPARATIVO (12 Figuras)</h2>

  <div class=\"key-finding\">
    <h3>✅ MÉTODO IMPLEMENTADO: Volcano Plot Correcto</h3>
    <p><strong>Método por Muestra (Opción B):</strong></p>
    <ol>
      <li>Para cada miRNA: Sumar VAF de todos sus G>T <strong>por muestra</strong></li>
      <li>Obtener 313 valores (ALS) y 102 valores (Control)</li>
      <li>Comparar: mean(313 ALS) vs mean(102 Control)</li>
      <li>Test Wilcoxon + corrección FDR</li>
    </ol>
    <p><strong>Ventaja:</strong> Cada muestra pesa igual, sin sesgo por número de SNVs.</p>
  </div>

  <div class=\"warning-box\">
    <h3>⚠️ HALLAZGO PRINCIPAL: Control > ALS</h3>
    <p>El análisis con datos limpios y método correcto confirma que:</p>
    <ul>
      <li><strong>Solo 3 miRNAs</strong> están enriquecidos en ALS</li>
      <li><strong>22 miRNAs</strong> están enriquecidos en Control</li>
      <li>Este hallazgo es <strong>robusto y consistente</strong></li>
    </ul>
    <p><strong>Top Candidatos ALS:</strong></p>
    <ul>
      <li>⭐ <strong>hsa-miR-196a-5p</strong> (ALS 3.4x > Control, p = 2.17e-03)</li>
      <li><strong>hsa-miR-9-5p</strong> (ALS 1.6x > Control, p = 5.83e-03)</li>
      <li><strong>hsa-miR-4746-5p</strong> (ALS 1.9x > Control, p = 2.92e-02)</li>
    </ul>
  </div>

  <h3>GRUPO A: Comparaciones Globales <span class=\"badge badge-critical\">CRÍTICO</span></h3>
  <div class=\"figure-grid\">"
)

grupo_a <- list(
  list(file = figuras_paso2[1], title = "2.1: VAF Global (Datos Limpios)"),
  list(file = figuras_paso2[2], title = "2.2: Distribuciones VAF"),
  list(file = figuras_paso2[3], title = "2.3: Volcano Plot (Método Correcto) ⭐", badge = "MÉTODO CORRECTO")
)

for (fig in grupo_a) {
  if (file.exists(fig$file)) {
    badge_html <- if (!is.null(fig$badge)) paste0("<span class=\"badge badge-method\">", fig$badge, "</span>") else ""
    html_content <- paste0(html_content,
      "<div class=\"figure-item\">
        <div class=\"figure-title\">", fig$title, badge_html, "</div>
        <img src=\"", fig$file, "\">
      </div>"
    )
  }
}

html_content <- paste0(html_content,
  "</div>

  <h3>GRUPO B: Análisis Posicional <span class=\"badge badge-new\">ACTUALIZADO</span></h3>
  <div class=\"figure-grid\">"
)

grupo_b <- list(
  list(file = figuras_paso2[4], title = "2.4: Heatmap Posicional (Top 50)"),
  list(file = figuras_paso2[5], title = "2.5: Heatmap Z-score (Top 50)"),
  list(file = figuras_paso2[6], title = "2.6: Perfiles Posicionales")
)

for (fig in grupo_b) {
  if (file.exists(fig$file)) {
    html_content <- paste0(html_content,
      "<div class=\"figure-item\">
        <div class=\"figure-title\">", fig$title, "</div>
        <img src=\"", fig$file, "\">
      </div>"
    )
  }
}

html_content <- paste0(html_content,
  "</div>

  <h3>GRUPO C: Heterogeneidad y Clustering <span class=\"badge badge-new\">ACTUALIZADO</span></h3>
  <div class=\"figure-grid\">"
)

grupo_c <- list(
  list(file = figuras_paso2[7], title = "2.7: PCA (28 miRNAs con varianza)"),
  list(file = figuras_paso2[8], title = "2.8: Clustering Jerárquico (28 miRNAs)"),
  list(file = figuras_paso2[9], title = "2.9: Coeficiente de Variación")
)

for (fig in grupo_c) {
  if (file.exists(fig$file)) {
    html_content <- paste0(html_content,
      "<div class=\"figure-item\">
        <div class=\"figure-title\">", fig$title, "</div>
        <img src=\"", fig$file, "\">
      </div>"
    )
  }
}

html_content <- paste0(html_content,
  "</div>

  <h3>GRUPO D: Especificidad G>T <span class=\"badge badge-new\">ACTUALIZADO</span></h3>
  <div class=\"figure-grid\">"
)

grupo_d <- list(
  list(file = figuras_paso2[10], title = "2.10: Ratio G>T/G>A"),
  list(file = figuras_paso2[11], title = "2.11: Heatmap de Tipos de Mutación"),
  list(file = figuras_paso2[12], title = "2.12: Enriquecimiento por Región")
)

for (fig in grupo_d) {
  if (file.exists(fig$file)) {
    html_content <- paste0(html_content,
      "<div class=\"figure-item\">
        <div class=\"figure-title\">", fig$title, "</div>
        <img src=\"", fig$file, "\">
      </div>"
    )
  }
}

html_content <- paste0(html_content,
  "</div>

  <div class=\"footer\">
    <p style=\"font-size: 1.1em; font-weight: bold; color: #2c3e50;\">🎉 PASO 2 COMPLETO</p>
    <p>Generado: ", Sys.time(), "</p>
    <p>Pipeline de Análisis de miRNA | UCSD</p>
    <p style=\"margin-top: 20px;\">
      <strong>Archivos de Referencia:</strong><br/>
      • METODO_VOLCANO_PLOT.md<br/>
      • HALLAZGOS_VOLCANO_CORRECTO.md<br/>
      • RESUMEN_EJECUTIVO_FINAL.md
    </p>
  </div>
</div>
"
)

# Guardar y renderizar
temp_md <- "temp_paso2_final.md"
writeLines(html_content, temp_md)

output_html <- "PASO_2_COMPLETO_FINAL.html"
rmarkdown::render(temp_md, output_file = output_html, quiet = TRUE)
file.remove(temp_md)

cat("✅ HTML FINAL COMPLETO\n")
cat("📁 Archivo:", output_html, "\n")
cat("📊 Contenido:\n")
cat("   • 4 figuras de diagnóstico QC\n")
cat("   • 12 figuras de análisis comparativo\n")
cat("   • Volcano Plot con método correcto\n")
cat("   • Hallazgos principales destacados\n\n")

system(paste("open", output_html))
cat("🌐 HTML abierto en navegador\n")

