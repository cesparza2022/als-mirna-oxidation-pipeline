# =============================================================================
# HTML PARA FIGURAS SELECCIONADAS POR EL USUARIO
# =============================================================================

library(rmarkdown)
library(knitr)

# Función para crear HTML con las figuras seleccionadas
create_selected_figures_html <- function() {
  
  # Figuras seleccionadas por el usuario
  selected_figures <- c(
    "panel_f_ultra_clean_spectrum_BACKUP_20251016_203451.png",
    "panel_d_positional_fraction_CORRECTED.png", 
    "panel_c_spectrum_CORRECTED.png",
    "panel_c_seed_interaction_CORRECTED.png",
    "panel_a_overview_CORRECTED.png",
    "panel_a_overview.png"
  )
  
  # Verificar que las figuras existen
  existing_figures <- c()
  missing_figures <- c()
  
  for (fig in selected_figures) {
    if (file.exists(paste0("figures/", fig))) {
      existing_figures <- c(existing_figures, fig)
    } else {
      missing_figures <- c(missing_figures, fig)
    }
  }
  
  cat("✅ Figuras encontradas:", length(existing_figures), "\n")
  if (length(missing_figures) > 0) {
    cat("❌ Figuras faltantes:", length(missing_figures), "\n")
    for (fig in missing_figures) {
      cat("   -", fig, "\n")
    }
  }
  
  # Crear HTML
  html_content <- paste0(
    "<!DOCTYPE html>
    <html lang='es'>
    <head>
        <meta charset='UTF-8'>
        <meta name='viewport' content='width=device-width, initial-scale=1.0'>
        <title>🎯 Figuras Seleccionadas - Análisis Paso 1</title>
        <style>
            body { 
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
                margin: 0; 
                padding: 20px; 
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                line-height: 1.6;
            }
            .container { 
                max-width: 1400px; 
                margin: 0 auto; 
                background: white; 
                border-radius: 15px; 
                box-shadow: 0 15px 35px rgba(0,0,0,0.1);
                overflow: hidden;
            }
            .header { 
                background: linear-gradient(135deg, #2c3e50 0%, #34495e 100%);
                color: white; 
                padding: 40px; 
                text-align: center; 
            }
            .header h1 { margin: 0; font-size: 2.5em; }
            .header p { margin: 15px 0 0 0; font-size: 1.2em; opacity: 0.9; }
            .stats { 
                background: rgba(255,255,255,0.1); 
                padding: 20px; 
                border-radius: 10px; 
                margin-top: 20px;
                display: inline-block;
            }
            .analysis-section { 
                margin: 30px; 
                border: 2px solid #e1e8ed; 
                border-radius: 12px; 
                overflow: hidden;
                box-shadow: 0 5px 15px rgba(0,0,0,0.08);
            }
            .analysis-header { 
                background: linear-gradient(135deg, #3498db 0%, #2980b9 100%);
                color: white; 
                padding: 20px; 
            }
            .analysis-header h2 { 
                margin: 0; 
                font-size: 1.8em;
            }
            .figures-grid { 
                display: grid; 
                grid-template-columns: repeat(auto-fit, minmax(500px, 1fr)); 
                gap: 30px; 
                padding: 30px;
            }
            .figure-item { 
                border: 2px solid #ddd; 
                border-radius: 10px; 
                padding: 20px;
                background: #fafafa;
                text-align: center;
                transition: all 0.3s ease;
            }
            .figure-item:hover { 
                border-color: #3498db; 
                transform: translateY(-5px);
                box-shadow: 0 10px 25px rgba(0,0,0,0.15);
            }
            .figure-item img { 
                max-width: 100%; 
                height: auto; 
                border-radius: 8px; 
                box-shadow: 0 3px 10px rgba(0,0,0,0.1);
                margin-bottom: 15px;
            }
            .figure-name { 
                font-weight: bold; 
                color: #2c3e50; 
                margin-bottom: 10px;
                font-size: 1.1em;
            }
            .figure-info { 
                color: #7f8c8d; 
                font-size: 0.9em;
                margin-bottom: 15px;
            }
            .figure-description { 
                background: #e8f4fd; 
                padding: 15px; 
                border-radius: 8px; 
                border-left: 4px solid #3498db;
                font-size: 0.95em;
                text-align: left;
            }
            .recommendations { 
                background: #f8f9fa; 
                padding: 30px; 
                border-top: 2px solid #e1e8ed;
            }
            .recommendations h3 { 
                color: #2c3e50; 
                margin-bottom: 20px;
            }
            .recommendation-item { 
                background: white; 
                padding: 15px; 
                margin: 10px 0; 
                border-radius: 8px; 
                border-left: 4px solid #f39c12;
                box-shadow: 0 2px 5px rgba(0,0,0,0.1);
            }
            .missing-notice { 
                background: #fdf2f2; 
                border: 2px solid #fecaca; 
                border-radius: 8px; 
                padding: 20px; 
                margin: 20px 30px;
                color: #dc2626;
            }
        </style>
    </head>
    <body>
        <div class='container'>
            <div class='header'>
                <h1>🎯 Figuras Seleccionadas</h1>
                <p>Análisis del Paso 1 - Figuras Favoritas del Usuario</p>
                <div class='stats'>
                    <strong>Figuras seleccionadas:</strong> ", length(existing_figures), " | 
                    <strong>Faltantes:</strong> ", length(missing_figures), "
                </div>
            </div>"
  )
  
  # Agregar aviso de figuras faltantes si las hay
  if (length(missing_figures) > 0) {
    html_content <- paste0(html_content,
      "<div class='missing-notice'>
          <h3>⚠️ Figuras Faltantes</h3>
          <p>Las siguientes figuras no se encontraron en el directorio:</p>
          <ul>"
    )
    for (fig in missing_figures) {
      html_content <- paste0(html_content, "<li>", fig, "</li>")
    }
    html_content <- paste0(html_content,
      "</ul>
      </div>"
    )
  }
  
  # Agregar análisis de las figuras existentes
  html_content <- paste0(html_content,
    "<div class='analysis-section'>
        <div class='analysis-header'>
            <h2>📊 Análisis de las Figuras Seleccionadas</h2>
        </div>
        <div class='figures-grid'>"
  )
  
  # Agregar cada figura existente
  for (fig in existing_figures) {
    file_size <- round(file.size(paste0("figures/", fig)) / 1024, 1)
    file_date <- format(file.info(paste0("figures/", fig))$mtime, "%Y-%m-%d %H:%M")
    
    # Determinar descripción basada en el nombre
    description <- get_figure_description(fig)
    
    html_content <- paste0(html_content,
      "<div class='figure-item'>
          <img src='figures/", fig, "' alt='", fig, "'>
          <div class='figure-name'>", basename(fig), "</div>
          <div class='figure-info'>
              📏 ", file_size, " KB | 📅 ", file_date, "
          </div>
          <div class='figure-description'>
              <strong>Descripción:</strong> ", description, "
          </div>
      </div>"
    )
  }
  
  html_content <- paste0(html_content,
    "</div>
    </div>"
  )
  
  # Agregar recomendaciones
  html_content <- paste0(html_content,
    "<div class='recommendations'>
        <h3>💡 Recomendaciones para Completar el Análisis</h3>
        
        <div class='recommendation-item'>
            <strong>🎨 Panel C - G>X Spectrum:</strong> Tienes la versión CORRECTED, pero podrías agregar la versión COMPLETE o PROFESSIONAL para comparar.
        </div>
        
        <div class='recommendation-item'>
            <strong>📊 Panel A - Overview:</strong> Tienes tanto la versión básica como la CORRECTED. Podrías agregar la versión PROFESSIONAL para tener la mejor calidad.
        </div>
        
        <div class='recommendation-item'>
            <strong>🔬 Panel B - Análisis G>T:</strong> No tienes ningún panel B. Podrías agregar 'panel_b_gt_analysis_v5.png' o 'panel_b_positional_PROFESSIONAL.png'.
        </div>
        
        <div class='recommendation-item'>
            <strong>📈 Panel D - Análisis Avanzado:</strong> Tienes 'positional_fraction_CORRECTED'. Podrías agregar 'panel_d_top_mirnas_PROFESSIONAL.png' o 'panel_d_balanced_3d_scatter.png'.
        </div>
        
        <div class='recommendation-item'>
            <strong>⚖️ Panel E - Seed vs No-Seed:</strong> No tienes ningún panel E. Podrías agregar 'panel_e_ultra_clean_boxplot_jitter.png'.
        </div>
        
        <div class='recommendation-item'>
            <strong>📋 Panel F - Análisis Final:</strong> Tienes 'ultra_clean_spectrum_BACKUP'. Podrías agregar 'panel_f_snv_per_mirna_COMPLETE.png'.
        </div>
        
        <div class='recommendation-item'>
            <strong>🎯 Panel G - Seed vs No-Seed:</strong> No tienes ningún panel G. Podrías agregar 'panel_g_ultra_clean_seed_vs_nonseed.png'.
        </div>
    </div>"
  )
  
  # Cerrar HTML
  html_content <- paste0(html_content,
    "</div>
    </body>
    </html>"
  )
  
  # Guardar HTML
  html_file <- "FIGURAS_SELECCIONADAS_ANALISIS.html"
  writeLines(html_content, html_file)
  
  cat("✅ HTML de figuras seleccionadas creado:", html_file, "\n")
  cat("📊 Figuras incluidas:", length(existing_figures), "\n")
  cat("❌ Figuras faltantes:", length(missing_figures), "\n")
  
  return(html_file)
}

# Función para obtener descripción de cada figura
get_figure_description <- function(fig_name) {
  descriptions <- list(
    "panel_a_overview" = "Vista general del dataset mostrando estadísticas básicas y evolución de los datos.",
    "panel_a_overview_CORRECTED" = "Vista general corregida con mejoras en la presentación y datos actualizados.",
    "panel_c_spectrum_CORRECTED" = "Espectro de mutaciones G>X por posición, versión corregida con mejor visualización.",
    "panel_c_seed_interaction_CORRECTED" = "Análisis de interacciones en la región semilla, versión corregida.",
    "panel_d_positional_fraction_CORRECTED" = "Fracción posicional de mutaciones, versión corregida con mejor precisión.",
    "panel_f_ultra_clean_spectrum" = "Espectro ultra limpio con diseño profesional y colores optimizados."
  )
  
  # Buscar descripción por patrón
  for (pattern in names(descriptions)) {
    if (grepl(pattern, fig_name)) {
      return(descriptions[[pattern]])
    }
  }
  
  return("Análisis específico del dataset de miRNAs y patrones de mutación.")
}

# Ejecutar
html_file <- create_selected_figures_html()

# Abrir en navegador
system(paste("open", html_file))

cat("🌐 HTML de figuras seleccionadas abierto en navegador\n")
