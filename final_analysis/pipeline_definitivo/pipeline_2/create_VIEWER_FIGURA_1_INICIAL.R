# ============================================================================
# VIEWER HTML PARA FIGURA 1 INICIAL COMPLETA
# ============================================================================
# 
# Crea un HTML viewer interactivo para la Figura 1 inicial
# Incluye descripciones detalladas de cada panel y su propósito
#
# ============================================================================

library(htmltools)
library(glue)

create_viewer_figura_1_inicial <- function() {
  cat("🌐 Creando VIEWER HTML para Figura 1 Inicial...\n")
  
  # Verificar que existe la figura
  figure_file <- "FIGURE_1_INICIAL_COMPLETA.png"
  if (!file.exists(figure_file)) {
    stop("❌ No se encontró la figura: ", figure_file, "\n",
         "   Ejecuta primero: generate_FIGURE_1_INICIAL_COMPLETA.R")
  }
  
  # Crear contenido HTML
  html_content <- htmltools::tags$html(
    lang = "es",
    htmltools::tags$head(
      htmltools::tags$meta(charset = "UTF-8"),
      htmltools::tags$meta(name = "viewport", content = "width=device-width, initial-scale=1.0"),
      htmltools::tags$title("Figura 1: Análisis Inicial Completo - Pipeline 2"),
      htmltools::tags$style(HTML("
        body {
          font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
          line-height: 1.6;
          margin: 0;
          padding: 20px;
          background-color: #f8f9fa;
          color: #333;
        }
        .container {
          max-width: 1200px;
          margin: 0 auto;
          background: white;
          padding: 30px;
          border-radius: 10px;
          box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        .header {
          text-align: center;
          margin-bottom: 30px;
          padding-bottom: 20px;
          border-bottom: 3px solid #D62728;
        }
        .header h1 {
          color: #2c3e50;
          margin-bottom: 10px;
          font-size: 2.2em;
        }
        .header h2 {
          color: #7f8c8d;
          font-weight: normal;
          margin-bottom: 20px;
        }
        .figure-container {
          text-align: center;
          margin: 30px 0;
          padding: 20px;
          background: #f8f9fa;
          border-radius: 8px;
          border: 2px solid #e9ecef;
        }
        .figure-container img {
          max-width: 100%;
          height: auto;
          border-radius: 5px;
          box-shadow: 0 2px 8px rgba(0,0,0,0.15);
        }
        .panel-descriptions {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
          gap: 20px;
          margin: 30px 0;
        }
        .panel-card {
          background: white;
          padding: 20px;
          border-radius: 8px;
          border-left: 4px solid #D62728;
          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .panel-card h3 {
          color: #D62728;
          margin-top: 0;
          margin-bottom: 15px;
          font-size: 1.3em;
        }
        .panel-card ul {
          margin: 10px 0;
          padding-left: 20px;
        }
        .panel-card li {
          margin: 8px 0;
        }
        .stats-box {
          background: #e8f4fd;
          padding: 15px;
          border-radius: 5px;
          margin: 15px 0;
          border: 1px solid #b8daff;
        }
        .stats-box h4 {
          color: #004085;
          margin-top: 0;
          margin-bottom: 10px;
        }
        .key-findings {
          background: #fff3cd;
          padding: 20px;
          border-radius: 8px;
          border: 1px solid #ffeaa7;
          margin: 30px 0;
        }
        .key-findings h3 {
          color: #856404;
          margin-top: 0;
        }
        .navigation {
          text-align: center;
          margin: 30px 0;
          padding: 20px;
          background: #f8f9fa;
          border-radius: 8px;
        }
        .btn {
          display: inline-block;
          padding: 12px 24px;
          margin: 0 10px;
          background: #D62728;
          color: white;
          text-decoration: none;
          border-radius: 5px;
          font-weight: bold;
          transition: background 0.3s;
        }
        .btn:hover {
          background: #b21e1e;
        }
        .footer {
          text-align: center;
          margin-top: 40px;
          padding-top: 20px;
          border-top: 2px solid #e9ecef;
          color: #6c757d;
        }
      "))
    ),
    htmltools::tags$body(
      htmltools::tags$div(class = "container",
        
        # Header
        htmltools::tags$div(class = "header",
          htmltools::tags$h1("🔬 Figura 1: Análisis Inicial Completo"),
          htmltools::tags$h2("Caracterización del Dataset de miRNAs y Patrones de Estrés Oxidativo"),
          htmltools::tags$p(style = "font-size: 1.1em; color: #666;",
            "Análisis comprehensivo paso a paso del dataset procesado, respondiendo preguntas fundamentales sobre estructura, composición y patrones de mutaciones G>T.")
        ),
        
        # Figura principal
        htmltools::tags$div(class = "figure-container",
          htmltools::tags$h3("📊 Figura Completa - 6 Paneles (2x3 Grid)"),
          htmltools::tags$img(src = figure_file, alt = "Figura 1: Análisis Inicial Completo"),
          htmltools::tags$p(style = "margin-top: 15px; font-style: italic; color: #666;",
            "Haz clic en la imagen para verla en tamaño completo")
        ),
        
        # Descripciones de paneles
        htmltools::tags$div(class = "panel-descriptions",
          
          # Panel A
          htmltools::tags$div(class = "panel-card",
            htmltools::tags$h3("📈 Panel A: Evolución del Dataset"),
            htmltools::tags$p("Muestra cómo cambia el dataset durante el procesamiento:"),
            htmltools::tags$ul(
              htmltools::tags$li("Split: Datos originales sin procesar"),
              htmltools::tags$li("Collapse: Datos después de aplicar filtros"),
              htmltools::tags$li("Reducción porcentual en cada paso"),
              htmltools::tags$li("Justificación de filtros aplicados")
            ),
            htmltools::tags$div(class = "stats-box",
              htmltools::tags$h4("Información mostrada:"),
              htmltools::tags$ul(
                htmltools::tags$li("Número de SNVs en cada paso"),
                htmltools::tags$li("Número de miRNAs únicos"),
                htmltools::tags$li("Porcentaje de reducción"),
                htmltools::tags$li("Eficiencia del procesamiento")
              )
            )
          ),
          
          # Panel B
          htmltools::tags$div(class = "panel-card",
            htmltools::tags$h3("🧬 Panel B: Distribución de Tipos de Mutación"),
            htmltools::tags$p("Distribución completa de los 12 tipos de mutaciones:"),
            htmltools::tags$ul(
              htmltools::tags$li("A>C, A>G, A>T (transiciones/transversiones)"),
              htmltools::tags$li("C>A, C>G, C>T (transiciones/transversiones)"),
              htmltools::tags$li("G>A, G>C, G>T (transiciones/transversiones)"),
              htmltools::tags$li("T>A, T>C, T>G (transiciones/transversiones)")
            ),
            htmltools::tags$div(class = "stats-box",
              htmltools::tags$h4("Información mostrada:"),
              htmltools::tags$ul(
                htmltools::tags$li("Count y porcentaje de cada tipo"),
                htmltools::tags$li("Dominancia de G>T (marcador oxidativo)"),
                htmltools::tags$li("Contexto de todas las mutaciones"),
                htmltools::tags$li("Validación de calidad del dataset")
              )
            )
          ),
          
          # Panel C
          htmltools::tags$div(class = "panel-card",
            htmltools::tags$h3("🧬 Panel C: miRNAs y Familias"),
            htmltools::tags$p("Caracterización de miRNAs únicos y patrones:"),
            htmltools::tags$ul(
              htmltools::tags$li("Total de miRNAs únicos"),
              htmltools::tags$li("Distribución de longitudes"),
              htmltools::tags$li("Top miRNAs más afectados"),
              htmltools::tags$li("Identificación de familias (si aplica)")
            ),
            htmltools::tags$div(class = "stats-box",
              htmltools::tags$h4("Información mostrada:"),
              htmltools::tags$ul(
                htmltools::tags$li("Estadísticas básicas del dataset"),
                htmltools::tags$li("Top 10 miRNAs por SNV count"),
                htmltools::tags$li("Mean ± SD de longitudes"),
                htmltools::tags$li("Distribución de complejidad")
              )
            )
          ),
          
          # Panel D
          htmltools::tags$div(class = "panel-card",
            htmltools::tags$h3("📊 Panel D: G-Content por Posición"),
            htmltools::tags$p("Distribución de nucleótidos G en cada posición:"),
            htmltools::tags$ul(
              htmltools::tags$li("Count de Gs en posiciones 1-22"),
              htmltools::tags$li("Región seed destacada (2-8)"),
              htmltools::tags$li("Mean ± SD por posición"),
              htmltools::tags$li("Patrones de distribución")
            ),
            htmltools::tags$div(class = "stats-box",
              htmltools::tags$h4("Información mostrada:"),
              htmltools::tags$ul(
                htmltools::tags$li("Count exacto en cada barra"),
                htmltools::tags$li("Estadísticas descriptivas"),
                htmltools::tags$li("Identificación de hotspots"),
                htmltools::tags$li("Contexto para mutaciones G>X")
              )
            )
          ),
          
          # Panel E
          htmltools::tags$div(class = "panel-card",
            htmltools::tags$h3("🎯 Panel E: G>X Spectrum por Posición"),
            htmltools::tags$p("Distribución detallada de mutaciones G>X (basado en figura favorita):"),
            htmltools::tags$ul(
              htmltools::tags$li("G>A: Azul (transición)"),
              htmltools::tags$li("G>C: Verde (transversión)"),
              htmltools::tags$li("G>T: ROJO (marcador oxidativo)"),
              htmltools::tags$li("Región seed destacada")
            ),
            htmltools::tags$div(class = "stats-box",
              htmltools::tags$h4("Información mostrada:"),
              htmltools::tags$ul(
                htmltools::tags$li("Count de cada tipo por posición"),
                htmltools::tags$li("Proporción G>T vs otras G>X"),
                htmltools::tags$li("Patrones posicionales"),
                htmltools::tags$li("Dominancia de G>T en 3'")
              )
            )
          ),
          
          # Panel F
          htmltools::tags$div(class = "panel-card",
            htmltools::tags$h3("⚖️ Panel F: Comparación Seed vs No-Seed"),
            htmltools::tags$p("Comparación entre regiones funcionales:"),
            htmltools::tags$ul(
              htmltools::tags$li("Seed region (2-8): Región crítica"),
              htmltools::tags$li("No-Seed (9-22): Región no-crítica"),
              htmltools::tags$li("Métricas comparativas"),
              htmltools::tags$li("Test estadístico")
            ),
            htmltools::tags$div(class = "stats-box",
              htmltools::tags$h4("Información mostrada:"),
              htmltools::tags$ul(
                htmltools::tags$li("Total SNVs por región"),
                htmltools::tags$li("G>T fraction por región"),
                htmltools::tags$li("Mean SNV per position"),
                htmltools::tags$li("Significancia estadística")
              )
            )
          )
        ),
        
        # Hallazgos clave
        htmltools::tags$div(class = "key-findings",
          htmltools::tags$h3("🔍 Hallazgos Clave Esperados"),
          htmltools::tags$ul(
            htmltools::tags$li("G>T debe ser el tipo de mutación más frecuente (marcador de estrés oxidativo)"),
            htmltools::tags$li("Enriquecimiento de G>T en región 3' (posiciones 18-22)"),
            htmltools::tags$li("Seed region debe mostrar patrones específicos"),
            htmltools::tags$li("Distribución no aleatoria de mutaciones"),
            htmltools::tags$li("Correlación entre G-content y susceptibilidad oxidativa")
          )
        ),
        
        # Navegación
        htmltools::tags$div(class = "navigation",
          htmltools::tags$h3("🚀 Próximos Pasos"),
          htmltools::tags$p("Una vez revisada esta Figura 1, procederemos a:"),
          htmltools::tags$ul(style = "text-align: left; display: inline-block;",
            htmltools::tags$li("Figura 2: Comparación ALS vs Control"),
            htmltools::tags$li("Figura 3: Análisis Funcional"),
            htmltools::tags$li("Validación de hallazgos"),
            htmltools::tags$li("Interpretación biológica")
          ),
          htmltools::tags$br(),
          htmltools::tags$a(href = "CONTEXTO_COMPLETO_PIPELINE.md", class = "btn", "📋 Ver Contexto Completo"),
          htmltools::tags$a(href = "PLAN_FIGURA_1_INICIAL.md", class = "btn", "📊 Ver Plan Detallado")
        ),
        
        # Footer
        htmltools::tags$div(class = "footer",
          htmltools::tags$p("🔬 Pipeline 2 - Análisis de miRNAs y Estrés Oxidativo"),
          htmltools::tags$p("Generado el:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
        )
      )
    )
  )
  
  # Guardar HTML
  output_file <- "VIEWER_FIGURA_1_INICIAL.html"
  save_html(html_content, output_file)
  
  cat("✅ Viewer HTML creado:", output_file, "\n")
  
  # Abrir en navegador
  if (interactive()) {
    browseURL(output_file)
  }
  
  return(output_file)
}

# Ejecutar si no es interactivo
if (!interactive()) {
  create_viewer_figura_1_inicial()
}

