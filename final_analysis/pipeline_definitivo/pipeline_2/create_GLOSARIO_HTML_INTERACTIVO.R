# =============================================================================
# GLOSARIO HTML INTERACTIVO CON FIGURAS VISIBLES
# =============================================================================

library(rmarkdown)
library(knitr)

# Función para crear HTML interactivo con todas las figuras
create_interactive_glosario <- function() {
  
  # Obtener lista de todas las figuras
  all_figures <- list.files("figures/", pattern = "\\.png$", full.names = FALSE)
  
  # Organizar por categorías
  categories <- list(
    "Figuras Completas" = all_figures[grepl("^FIGURE_1_|^figure_1_|^figura_1_", all_figures)],
    "Panel A - Overview & Evolución" = all_figures[grepl("^panel_a_", all_figures)],
    "Panel B - Análisis G>T & Posicional" = all_figures[grepl("^panel_b_", all_figures)],
    "Panel C - Spectrum & Correlaciones" = all_figures[grepl("^panel_c_", all_figures)],
    "Panel D - Análisis Avanzado" = all_figures[grepl("^panel_d_", all_figures)],
    "Panel E - Boxplots & Distribuciones" = all_figures[grepl("^panel_e_", all_figures)],
    "Panel F - Análisis Final" = all_figures[grepl("^panel_f_", all_figures)],
    "Panel G - Seed vs No-Seed" = all_figures[grepl("^panel_g_", all_figures)],
    "Otras Figuras" = all_figures[grepl("^figure_[23]_", all_figures)]
  )
  
  # Crear HTML
  html_content <- paste0(
    "<!DOCTYPE html>
    <html lang='es'>
    <head>
        <meta charset='UTF-8'>
        <meta name='viewport' content='width=device-width, initial-scale=1.0'>
        <title>📚 Glosario Interactivo - Todas las Figuras del Paso 1</title>
        <style>
            body { 
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
                margin: 0; 
                padding: 20px; 
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                line-height: 1.6;
            }
            .container { 
                max-width: 1600px; 
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
            .header h1 { margin: 0; font-size: 3em; }
            .header p { margin: 15px 0 0 0; font-size: 1.3em; opacity: 0.9; }
            .stats { 
                background: rgba(255,255,255,0.1); 
                padding: 20px; 
                border-radius: 10px; 
                margin-top: 20px;
                display: inline-block;
            }
            .category { 
                margin: 30px; 
                border: 2px solid #e1e8ed; 
                border-radius: 12px; 
                overflow: hidden;
                box-shadow: 0 5px 15px rgba(0,0,0,0.08);
            }
            .category-header { 
                background: linear-gradient(135deg, #3498db 0%, #2980b9 100%);
                color: white; 
                padding: 20px; 
                cursor: pointer;
                transition: all 0.3s ease;
            }
            .category-header:hover { 
                background: linear-gradient(135deg, #2980b9 0%, #1f4e79 100%);
            }
            .category-header h2 { 
                margin: 0; 
                font-size: 1.8em;
                display: flex;
                justify-content: space-between;
                align-items: center;
            }
            .category-content { 
                padding: 30px; 
                display: none;
            }
            .category-content.active { 
                display: block; 
            }
            .figures-grid { 
                display: grid; 
                grid-template-columns: repeat(auto-fit, minmax(400px, 1fr)); 
                gap: 25px; 
            }
            .figure-item { 
                border: 2px solid #ddd; 
                border-radius: 10px; 
                padding: 20px;
                background: #fafafa;
                transition: all 0.3s ease;
                cursor: pointer;
            }
            .figure-item:hover { 
                border-color: #3498db; 
                transform: translateY(-5px);
                box-shadow: 0 10px 25px rgba(0,0,0,0.15);
            }
            .figure-item.selected { 
                border-color: #e74c3c; 
                background: #fdf2f2;
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
            }
            .selection-panel { 
                position: fixed; 
                top: 20px; 
                right: 20px; 
                background: white; 
                padding: 20px; 
                border-radius: 10px; 
                box-shadow: 0 5px 15px rgba(0,0,0,0.2);
                max-width: 300px;
                z-index: 1000;
            }
            .selection-panel h3 { 
                margin: 0 0 15px 0; 
                color: #2c3e50;
            }
            .selected-list { 
                max-height: 200px; 
                overflow-y: auto; 
                border: 1px solid #ddd; 
                padding: 10px; 
                border-radius: 5px;
                background: #f8f9fa;
            }
            .selected-item { 
                padding: 5px; 
                margin: 2px 0; 
                background: #e8f4fd; 
                border-radius: 3px; 
                font-size: 0.9em;
            }
            .action-buttons { 
                margin-top: 15px; 
                text-align: center;
            }
            .btn { 
                padding: 10px 20px; 
                margin: 5px; 
                border: none; 
                border-radius: 5px; 
                cursor: pointer; 
                font-weight: bold;
                transition: all 0.3s ease;
            }
            .btn-primary { 
                background: #3498db; 
                color: white; 
            }
            .btn-primary:hover { 
                background: #2980b9; 
            }
            .btn-success { 
                background: #27ae60; 
                color: white; 
            }
            .btn-success:hover { 
                background: #229954; 
            }
            .btn-danger { 
                background: #e74c3c; 
                color: white; 
            }
            .btn-danger:hover { 
                background: #c0392b; 
            }
            .favorites { 
                background: linear-gradient(135deg, #f39c12 0%, #e67e22 100%);
                color: white;
            }
            .favorites h2::after { 
                content: ' ⭐'; 
            }
        </style>
        <script>
            let selectedFigures = [];
            
            function toggleCategory(categoryId) {
                const content = document.getElementById(categoryId);
                content.classList.toggle('active');
            }
            
            function toggleSelection(figureName) {
                const item = document.querySelector(`[data-figure='${figureName}']`);
                const index = selectedFigures.indexOf(figureName);
                
                if (index > -1) {
                    selectedFigures.splice(index, 1);
                    item.classList.remove('selected');
                } else {
                    selectedFigures.push(figureName);
                    item.classList.add('selected');
                }
                
                updateSelectionPanel();
            }
            
            function updateSelectionPanel() {
                const panel = document.getElementById('selection-panel');
                const list = panel.querySelector('.selected-list');
                
                list.innerHTML = selectedFigures.map(fig => 
                    `<div class='selected-item'>${fig}</div>`
                ).join('');
                
                panel.querySelector('.count').textContent = selectedFigures.length;
            }
            
            function generateHTML() {
                if (selectedFigures.length === 0) {
                    alert('Por favor selecciona al menos una figura');
                    return;
                }
                
                // Crear HTML con las figuras seleccionadas
                const html = generateSelectedHTML();
                const blob = new Blob([html], {type: 'text/html'});
                const url = URL.createObjectURL(blob);
                const a = document.createElement('a');
                a.href = url;
                a.download = 'FIGURAS_SELECCIONADAS.html';
                a.click();
            }
            
            function generateSelectedHTML() {
                return `<!DOCTYPE html>
                <html>
                <head>
                    <title>Figuras Seleccionadas</title>
                    <style>
                        body { font-family: Arial, sans-serif; margin: 20px; }
                        .figure { margin: 30px 0; text-align: center; }
                        .figure img { max-width: 100%; height: auto; }
                        .figure h3 { color: #2c3e50; }
                    </style>
                </head>
                <body>
                    <h1>Figuras Seleccionadas (${selectedFigures.length})</h1>
                    ${selectedFigures.map(fig => 
                        `<div class='figure'>
                            <h3>${fig}</h3>
                            <img src='figures/${fig}' alt='${fig}'>
                        </div>`
                    ).join('')}
                </body>
                </html>`;
            }
        </script>
    </head>
    <body>
        <div class='container'>
            <div class='header'>
                <h1>📚 Glosario Interactivo</h1>
                <p>Todas las Figuras del Paso 1 - Análisis Inicial</p>
                <div class='stats'>
                    <strong>Total de figuras:</strong> ", length(all_figures), " | 
                    <strong>Categorías:</strong> ", length(categories), "
                </div>
            </div>
            
            <div class='selection-panel' id='selection-panel'>
                <h3>🎯 Figuras Seleccionadas (<span class='count'>0</span>)</h3>
                <div class='selected-list'></div>
                <div class='action-buttons'>
                    <button class='btn btn-success' onclick='generateHTML()'>📥 Generar HTML</button>
                    <button class='btn btn-danger' onclick='selectedFigures=[]; updateSelectionPanel(); document.querySelectorAll(\".figure-item\").forEach(el => el.classList.remove(\"selected\"))'>🗑️ Limpiar</button>
                </div>
            </div>"
  )
  
  # Agregar cada categoría
  for (i in seq_along(categories)) {
    category_name <- names(categories)[i]
    category_figures <- categories[[i]]
    category_id <- paste0("category-", i)
    
    # Determinar si es la categoría de favoritas
    is_favorites <- grepl("Spectrum|PROFESSIONAL|COMPLETE|ultra_clean", category_name)
    category_class <- if (is_favorites) "favorites" else ""
    
    html_content <- paste0(html_content,
      "<div class='category ", category_class, "'>
          <div class='category-header' onclick='toggleCategory(\"", category_id, "\")'>
              <h2>", category_name, " (", length(category_figures), " figuras)</h2>
              <span>▼</span>
          </div>
          <div class='category-content' id='", category_id, "'>"
    )
    
    if (length(category_figures) > 0) {
      html_content <- paste0(html_content, "<div class='figures-grid'>")
      
      for (fig in category_figures) {
        # Verificar si el archivo existe
        if (file.exists(paste0("figures/", fig))) {
          file_size <- round(file.size(paste0("figures/", fig)) / 1024, 1)
          file_date <- format(file.info(paste0("figures/", fig))$mtime, "%Y-%m-%d")
          
          html_content <- paste0(html_content,
            "<div class='figure-item' data-figure='", fig, "' onclick='toggleSelection(\"", fig, "\")'>
                <img src='figures/", fig, "' alt='", fig, "'>
                <div class='figure-name'>", fig, "</div>
                <div class='figure-info'>
                    📏 ", file_size, " KB | 📅 ", file_date, "
                </div>
            </div>"
          )
        }
      }
      
      html_content <- paste0(html_content, "</div>")
    } else {
      html_content <- paste0(html_content, "<p>No hay figuras en esta categoría.</p>")
    }
    
    html_content <- paste0(html_content,
      "</div>
      </div>"
    )
  }
  
  # Cerrar HTML
  html_content <- paste0(html_content,
    "</div>
    </body>
    </html>"
  )
  
  # Guardar HTML
  html_file <- "GLOSARIO_INTERACTIVO_TODAS_LAS_FIGURAS.html"
  writeLines(html_content, html_file)
  
  cat("✅ Glosario interactivo creado:", html_file, "\n")
  cat("📊 Total de figuras:", length(all_figures), "\n")
  cat("📁 Categorías:", length(categories), "\n")
  cat("🎨 Funciones: Selección, vista previa, generación de HTML\n")
  
  return(html_file)
}

# Ejecutar
html_file <- create_interactive_glosario()

# Abrir en navegador
system(paste("open", html_file))

cat("🌐 Glosario interactivo abierto en navegador\n")
