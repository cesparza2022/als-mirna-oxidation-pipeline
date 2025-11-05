# =============================================================================
# CREAR HTML CON MÚLTIPLES FIGURAS - PASO 1 COMPLETO
# =============================================================================

library(rmarkdown)
library(knitr)

# Función para crear HTML con múltiples figuras
create_multiple_figures_html <- function() {
  
  # Definir las mejores figuras seleccionadas (basado en nombres y tamaños)
  best_figures <- list(
    
    # FIGURA 1: EVOLUCIÓN DEL DATASET
    figure_1 = list(
      title = "Figura 1: Evolución del Dataset",
      subtitle = "Cambios en SNVs y miRNAs después del procesamiento",
      panels = c(
        "panel_a_overview_PROFESSIONAL.png",
        "panel_a_global_burden_PROFESSIONAL.png"
      ),
      description = "Muestra cómo el dataset cambia desde los datos crudos (split) hasta los procesados (collapse), incluyendo la reducción de SNVs y el análisis de carga global."
    ),
    
    # FIGURA 2: DISTRIBUCIÓN DE MUTACIONES
    figure_2 = list(
      title = "Figura 2: Distribución de Tipos de Mutación",
      subtitle = "Análisis global de patrones de mutación",
      panels = c(
        "panel_b_gt_analysis_v5.png",
        "panel_b_positional_PROFESSIONAL.png"
      ),
      description = "Presenta la distribución de todos los tipos de mutación, con énfasis especial en G>T como firma de estrés oxidativo, y análisis posicional."
    ),
    
    # FIGURA 3: G>X SPECTRUM (Tu figura favorita)
    figure_3 = list(
      title = "Figura 3: G>X Mutation Spectrum por Posición",
      subtitle = "Distribución de mutaciones G en el miRNA",
      panels = c(
        "panel_c_spectrum_COMPLETE.png",
        "panel_c_spectrum_PROFESSIONAL.png"
      ),
      description = "Tu figura favorita: muestra la distribución de mutaciones G>A, G>C y G>T por cada posición del miRNA, con la región semilla resaltada y G>T en rojo."
    ),
    
    # FIGURA 4: ANÁLISIS AVANZADO
    figure_4 = list(
      title = "Figura 4: Análisis Avanzado de Patrones",
      subtitle = "Correlaciones y análisis mecanístico",
      panels = c(
        "panel_c_advanced_correlation_matrix.png",
        "panel_d_balanced_3d_scatter.png"
      ),
      description = "Análisis avanzado incluyendo matriz de correlación entre métricas G>T y scatter plot 3D mostrando relaciones complejas entre posición, G-content y mutaciones."
    ),
    
    # FIGURA 5: COMPARACIÓN SEED VS NO-SEED
    figure_5 = list(
      title = "Figura 5: Comparación Seed vs No-Seed",
      subtitle = "Diferencias entre regiones funcionales",
      panels = c(
        "panel_b_improved_seed_vs_nonseed_stats.png",
        "panel_e_ultra_clean_boxplot_jitter.png"
      ),
      description = "Comparación directa entre la región semilla (posiciones 2-8) y el resto del miRNA, mostrando diferencias en distribución de SNVs y G>T."
    ),
    
    # FIGURA 6: ANÁLISIS DETALLADO
    figure_6 = list(
      title = "Figura 6: Análisis Detallado por miRNA",
      subtitle = "Patrones específicos por miRNA y posición",
      panels = c(
        "panel_d_top_mirnas_PROFESSIONAL.png",
        "panel_f_snv_per_mirna_COMPLETE.png"
      ),
      description = "Análisis detallado mostrando los miRNAs más afectados, distribución de SNVs por miRNA, y patrones específicos de mutación."
    )
  )
  
  # Crear contenido HTML
  html_content <- paste0(
    "<!DOCTYPE html>
    <html lang='es'>
    <head>
        <meta charset='UTF-8'>
        <meta name='viewport' content='width=device-width, initial-scale=1.0'>
        <title>Paso 1: Análisis Inicial Completo - Múltiples Figuras</title>
        <style>
            body { 
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
                margin: 0; 
                padding: 20px; 
                background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
                line-height: 1.6;
            }
            .container { 
                max-width: 1400px; 
                margin: 0 auto; 
                background: white; 
                border-radius: 15px; 
                box-shadow: 0 10px 30px rgba(0,0,0,0.1);
                overflow: hidden;
            }
            .header { 
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white; 
                padding: 30px; 
                text-align: center; 
            }
            .header h1 { margin: 0; font-size: 2.5em; }
            .header p { margin: 10px 0 0 0; font-size: 1.2em; opacity: 0.9; }
            .figure-section { 
                margin: 40px 30px; 
                border: 2px solid #e1e8ed; 
                border-radius: 12px; 
                overflow: hidden;
                box-shadow: 0 5px 15px rgba(0,0,0,0.08);
            }
            .figure-header { 
                background: #f8f9fa; 
                padding: 20px; 
                border-bottom: 2px solid #e1e8ed;
            }
            .figure-header h2 { 
                margin: 0; 
                color: #2c3e50; 
                font-size: 1.8em;
            }
            .figure-header h3 { 
                margin: 5px 0; 
                color: #7f8c8d; 
                font-size: 1.1em;
                font-weight: normal;
            }
            .figure-content { 
                padding: 30px; 
            }
            .panels-grid { 
                display: grid; 
                grid-template-columns: 1fr 1fr; 
                gap: 30px; 
                margin-bottom: 20px;
            }
            .panel { 
                text-align: center; 
                border: 1px solid #ddd; 
                border-radius: 8px; 
                padding: 15px;
                background: #fafafa;
            }
            .panel img { 
                max-width: 100%; 
                height: auto; 
                border-radius: 6px; 
                box-shadow: 0 3px 10px rgba(0,0,0,0.1);
            }
            .description { 
                background: #e8f4fd; 
                padding: 20px; 
                border-radius: 8px; 
                border-left: 4px solid #3498db;
                font-size: 1.1em;
            }
            .single-panel { 
                text-align: center; 
                border: 1px solid #ddd; 
                border-radius: 8px; 
                padding: 20px;
                background: #fafafa;
                margin: 20px 0;
            }
            .navigation { 
                text-align: center; 
                padding: 30px; 
                background: #f8f9fa; 
                border-top: 2px solid #e1e8ed;
            }
            .nav-button { 
                display: inline-block; 
                padding: 12px 25px; 
                margin: 0 10px; 
                background: #3498db; 
                color: white; 
                text-decoration: none; 
                border-radius: 25px; 
                font-weight: bold;
                transition: all 0.3s ease;
            }
            .nav-button:hover { 
                background: #2980b9; 
                transform: translateY(-2px);
            }
        </style>
    </head>
    <body>
        <div class='container'>
            <div class='header'>
                <h1>🎯 Paso 1: Análisis Inicial Completo</h1>
                <p>Análisis Exploratorio de miRNAs y Patrones de Estrés Oxidativo</p>
            </div>"
  )
  
  # Agregar cada figura
  for (i in seq_along(best_figures)) {
    fig <- best_figures[[i]]
    fig_num <- i
    
    html_content <- paste0(html_content,
      "<div class='figure-section'>
          <div class='figure-header'>
              <h2>", fig$title, "</h2>
              <h3>", fig$subtitle, "</h3>
          </div>
          <div class='figure-content'>"
    )
    
    # Si hay 2 paneles, usar grid
    if (length(fig$panels) == 2) {
      html_content <- paste0(html_content,
        "<div class='panels-grid'>"
      )
      for (panel in fig$panels) {
        if (file.exists(paste0("figures/", panel))) {
          html_content <- paste0(html_content,
            "<div class='panel'>
                <img src='figures/", panel, "' alt='", panel, "'>
                <p><strong>", basename(panel), "</strong></p>
            </div>"
          )
        }
      }
      html_content <- paste0(html_content, "</div>")
    } else {
      # Panel único
      for (panel in fig$panels) {
        if (file.exists(paste0("figures/", panel))) {
          html_content <- paste0(html_content,
            "<div class='single-panel'>
                <img src='figures/", panel, "' alt='", panel, "'>
                <p><strong>", basename(panel), "</strong></p>
            </div>"
          )
        }
      }
    }
    
    # Agregar descripción
    html_content <- paste0(html_content,
      "<div class='description'>
          <strong>Descripción:</strong> ", fig$description, "
      </div>
      </div>
      </div>"
    )
  }
  
  # Agregar navegación y cierre
  html_content <- paste0(html_content,
    "<div class='navigation'>
        <h3>🚀 Próximos Pasos del Pipeline</h3>
        <p>Después de completar este análisis inicial, el pipeline continuará con:</p>
        <ul style='text-align: left; display: inline-block;'>
            <li><strong>Paso 2:</strong> Análisis Mecanístico (G-content, contexto de secuencia)</li>
            <li><strong>Paso 3:</strong> Comparaciones entre Grupos (ALS vs Control)</li>
            <li><strong>Paso 4:</strong> Análisis Estadístico Avanzado</li>
        </ul>
        <br>
        <a href='#' class='nav-button'>📊 Ver Figura 2</a>
        <a href='#' class='nav-button'>📈 Ver Figura 3</a>
        <a href='#' class='nav-button'>📋 Ver Resumen</a>
    </div>
        </div>
    </body>
    </html>"
  )
  
  # Guardar HTML
  html_file <- "PASO_1_MULTIPLES_FIGURAS.html"
  writeLines(html_content, html_file)
  
  cat("✅ HTML con múltiples figuras creado:", html_file, "\n")
  cat("📊 Figuras incluidas:", length(best_figures), "\n")
  cat("🎨 Layout: Responsive con CSS Grid\n")
  
  return(html_file)
}

# Ejecutar
html_file <- create_multiple_figures_html()

# Abrir en navegador
system(paste("open", html_file))

cat("🌐 HTML abierto en navegador\n")
