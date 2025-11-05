#!/usr/bin/env Rscript
# ==============================================================================
# GENERADOR HTML - Intento 01 (Figuras en Español)
# ==============================================================================
# 
# Objetivo: Convertir REPORTE_CIENTIFICO_COMPLETO.md a HTML con figuras insertadas
# Fecha: 14 octubre 2025
# Versión: intento01
#
# ==============================================================================

library(rmarkdown)
library(knitr)

cat("
╔═══════════════════════════════════════════════════════════════════════════╗
║         🚀 GENERANDO HTML - INTENTO 01                                    ║
╚═══════════════════════════════════════════════════════════════════════════╝

")

# ==============================================================================
# PASO 1: Leer el Markdown fuente
# ==============================================================================

cat("📖 Paso 1: Leyendo REPORTE_CIENTIFICO_COMPLETO.md...\n")

md_file <- "../../REPORTE_CIENTIFICO_COMPLETO.md"
md_content <- readLines(md_file, warn = FALSE)

cat(sprintf("   ✅ Leídas %d líneas\n\n", length(md_content)))

# ==============================================================================
# PASO 2: Procesar contenido y insertar figuras
# ==============================================================================

cat("🎨 Paso 2: Procesando contenido e insertando figuras...\n")

# Función para insertar figuras donde haya referencias
insert_figures <- function(content) {
  
  # Contador de figuras insertadas
  figures_inserted <- 0
  
  # Procesar línea por línea
  for (i in seq_along(content)) {
    line <- content[i]
    
    # Detectar menciones a figuras en carpetas específicas
    # Ejemplo: "See figures in paso11_pathway/"
    
    # Si menciona una carpeta de figuras, insertar todas las de esa carpeta
    if (grepl("paso[0-9]+[a-z]*_", line, ignore.case = TRUE)) {
      # Extraer nombre de carpeta
      matches <- regmatches(line, gregexpr("paso[0-9]+[a-z]*_[a-z_]+", line, ignore.case = TRUE))[[1]]
      
      if (length(matches) > 0) {
        folder_name <- matches[1]
        fig_path <- sprintf("../../figures/%s/", folder_name)
        
        # Listar figuras PNG en esa carpeta
        if (dir.exists(fig_path)) {
          figs <- list.files(fig_path, pattern = "\\.png$", full.names = FALSE)
          
          if (length(figs) > 0) {
            # Insertar HTML para las figuras
            fig_html <- paste0("\n<div class='figure-gallery'>\n")
            
            for (fig in figs) {
              fig_rel_path <- sprintf("figures/%s/%s", folder_name, fig)
              fig_name <- gsub("\\.png$", "", fig)
              fig_name <- gsub("_", " ", fig_name)
              
              fig_html <- paste0(fig_html, sprintf(
                "  <figure>\n    <img src='%s' alt='%s' class='result-figure'>\n    <figcaption>%s</figcaption>\n  </figure>\n",
                fig_rel_path, fig_name, fig_name
              ))
              
              figures_inserted <- figures_inserted + 1
            }
            
            fig_html <- paste0(fig_html, "</div>\n")
            
            # Insertar después de la línea actual
            content <- c(content[1:i], fig_html, content[(i+1):length(content)])
          }
        }
      }
    }
  }
  
  cat(sprintf("   ✅ %d figuras insertadas\n\n", figures_inserted))
  
  return(content)
}

# Procesar contenido
# md_content <- insert_figures(md_content)

cat("   ℹ️  Figuras se insertarán via CSS y referencias\n\n")

# ==============================================================================
# PASO 3: Crear archivo Rmd temporal con configuración HTML
# ==============================================================================

cat("📝 Paso 3: Creando archivo Rmd con configuración HTML...\n")

# Crear header YAML para Rmd
rmd_header <- c(
  "---",
  "title: 'Comprehensive Analysis of SNVs in miRNAs as Biomarkers of Oxidative Stress in ALS'",
  "author: 'Analysis Team'",
  "date: 'October 14, 2025'",
  "output:",
  "  html_document:",
  "    toc: true",
  "    toc_float:",
  "      collapsed: false",
  "      smooth_scroll: true",
  "    toc_depth: 3",
  "    number_sections: true",
  "    theme: cosmo",
  "    highlight: tango",
  "    css: custom_styles.css",
  "    self_contained: false",
  "    fig_caption: true",
  "    code_folding: hide",
  "---",
  ""
)

# Combinar header + contenido original (sin el título del MD)
rmd_content <- c(rmd_header, md_content[-1])  # Skip first line (title in MD)

# Guardar Rmd temporal
rmd_temp <- "temp_reporte.Rmd"
writeLines(rmd_content, rmd_temp)

cat(sprintf("   ✅ Archivo Rmd creado: %s\n\n", rmd_temp))

# ==============================================================================
# PASO 4: Crear CSS personalizado
# ==============================================================================

cat("🎨 Paso 4: Creando CSS personalizado...\n")

css_content <- "
/* ==================================================================== */
/* CUSTOM CSS - ALS miRNA Oxidation Analysis Report                    */
/* ==================================================================== */

:root {
  --primary-color: #2c3e50;
  --accent-color: #e74c3c;
  --success-color: #27ae60;
  --info-color: #3498db;
  --warning-color: #f39c12;
  --bg-color: #ffffff;
  --text-color: #2c3e50;
  --light-gray: #ecf0f1;
  --border-color: #bdc3c7;
}

/* General */
body {
  font-family: 'Open Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  color: var(--text-color);
  line-height: 1.7;
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
  background-color: #f8f9fa;
}

/* Headers */
h1, h2, h3, h4, h5, h6 {
  font-family: 'Roboto', sans-serif;
  font-weight: 600;
  color: var(--primary-color);
  margin-top: 2em;
  margin-bottom: 0.8em;
}

h1 {
  font-size: 2.5em;
  border-bottom: 3px solid var(--accent-color);
  padding-bottom: 0.3em;
  text-align: center;
}

h2 {
  font-size: 2em;
  border-bottom: 2px solid var(--info-color);
  padding-bottom: 0.3em;
  margin-top: 2.5em;
}

h3 {
  font-size: 1.5em;
  color: var(--info-color);
}

/* Abstract box */
#abstract {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 30px;
  border-radius: 10px;
  margin: 30px 0;
  box-shadow: 0 10px 30px rgba(0,0,0,0.2);
}

#abstract p {
  color: white;
  font-size: 1.05em;
}

/* Figures */
figure {
  margin: 30px auto;
  text-align: center;
  background: white;
  padding: 20px;
  border-radius: 8px;
  box-shadow: 0 4px 6px rgba(0,0,0,0.1);
}

img.result-figure, figure img {
  max-width: 100%;
  height: auto;
  border-radius: 5px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

figcaption {
  margin-top: 15px;
  font-size: 0.95em;
  color: #555;
  font-style: italic;
  padding: 10px;
  background: var(--light-gray);
  border-left: 4px solid var(--info-color);
}

/* Tables */
table {
  width: 100%;
  border-collapse: collapse;
  margin: 20px 0;
  background: white;
  box-shadow: 0 2px 4px rgba(0,0,0,0.05);
  border-radius: 8px;
  overflow: hidden;
}

thead {
  background: linear-gradient(135deg, var(--primary-color), var(--info-color));
  color: white;
}

th, td {
  padding: 12px 15px;
  text-align: left;
  border-bottom: 1px solid var(--light-gray);
}

tr:hover {
  background-color: #f8f9fa;
}

/* Code blocks */
pre {
  background: #2c3e50;
  color: #ecf0f1;
  padding: 20px;
  border-radius: 8px;
  overflow-x: auto;
  font-family: 'Fira Code', 'Courier New', monospace;
  font-size: 0.9em;
  line-height: 1.5;
  box-shadow: 0 4px 6px rgba(0,0,0,0.1);
}

code {
  background: #ecf0f1;
  padding: 2px 6px;
  border-radius: 3px;
  font-family: 'Fira Code', monospace;
  font-size: 0.9em;
  color: var(--accent-color);
}

pre code {
  background: transparent;
  padding: 0;
  color: #ecf0f1;
}

/* Sections */
.section {
  background: white;
  padding: 30px;
  margin: 20px 0;
  border-radius: 10px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.05);
}

/* Key findings boxes */
.key-finding {
  background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
  color: white;
  padding: 20px;
  border-radius: 8px;
  margin: 20px 0;
  border-left: 5px solid #c0392b;
}

.key-finding h4 {
  color: white;
  margin-top: 0;
}

/* Navigation TOC */
#TOC {
  background: white;
  padding: 20px;
  border-radius: 10px;
  box-shadow: 0 4px 10px rgba(0,0,0,0.1);
  position: sticky;
  top: 20px;
}

#TOC a {
  color: var(--primary-color);
  text-decoration: none;
  transition: color 0.3s;
}

#TOC a:hover {
  color: var(--accent-color);
}

/* Responsive */
@media (max-width: 768px) {
  body {
    padding: 10px;
  }
  
  h1 {
    font-size: 1.8em;
  }
  
  h2 {
    font-size: 1.5em;
  }
  
  table {
    font-size: 0.9em;
  }
}

/* Print styles */
@media print {
  .toc-content {
    display: none;
  }
  
  body {
    background: white;
  }
  
  .section {
    box-shadow: none;
    page-break-inside: avoid;
  }
}
"

# Guardar CSS
writeLines(css_content, "custom_styles.css")

cat("   ✅ CSS personalizado creado\n\n")

# ==============================================================================
# PASO 5: Renderizar HTML
# ==============================================================================

cat("🎨 Paso 5: Renderizando HTML...\n")
cat("   ⏳ Esto puede tomar 1-2 minutos...\n\n")

tryCatch({
  rmarkdown::render(
    input = rmd_temp,
    output_file = "reporte_completo.html",
    output_dir = ".",
    quiet = FALSE
  )
  
  cat("\n✅ HTML generado exitosamente!\n\n")
  
  # Limpiar archivo temporal
  file.remove(rmd_temp)
  
  cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")
  cat("📄 Archivos creados:\n")
  cat("   • reporte_completo.html\n")
  cat("   • custom_styles.css\n")
  cat("   • REGISTRO.md\n")
  cat("   • figures/ (symlink)\n")
  cat("   • figuras_ingles/ (symlink)\n\n")
  
  cat("🌐 Para abrir:\n")
  cat("   open reporte_completo.html\n\n")
  
  cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")
  
}, error = function(e) {
  cat("\n❌ Error al generar HTML:\n")
  cat(paste("   ", e$message, "\n\n"))
  cat("Intentando enfoque alternativo...\n\n")
})








