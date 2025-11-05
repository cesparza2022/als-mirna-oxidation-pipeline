# =============================================================================
# SELECTOR DE MEJORES PANELES - FIGURA 1
# =============================================================================

library(ggplot2)
library(dplyr)
library(patchwork)

# Función para mostrar opciones de un panel específico
show_panel_options <- function(panel_letter) {
  cat("📊 PANEL", toupper(panel_letter), "- OPCIONES DISPONIBLES:\n")
  cat(paste(rep("=", 50), collapse = ""), "\n")
  
  # Buscar archivos del panel
  files <- list.files("figures/", pattern = paste0("^panel_", panel_letter, "_"), full.names = TRUE)
  
  if (length(files) == 0) {
    cat("❌ No se encontraron archivos para Panel", toupper(panel_letter), "\n")
    return(NULL)
  }
  
  # Mostrar opciones numeradas
  for (i in seq_along(files)) {
    file_name <- basename(files[i])
    file_size <- round(file.size(files[i]) / 1024, 1)  # KB
    cat(sprintf("%2d. %s (%s KB)\n", i, file_name, file_size))
  }
  
  return(files)
}

# Función para abrir una imagen específica
open_panel_image <- function(panel_letter, option_number) {
  files <- list.files("figures/", pattern = paste0("^panel_", panel_letter, "_"), full.names = TRUE)
  
  if (option_number > length(files) || option_number < 1) {
    cat("❌ Opción inválida\n")
    return(NULL)
  }
  
  selected_file <- files[option_number]
  cat("🖼️  Abriendo:", basename(selected_file), "\n")
  
  # Abrir la imagen
  system(paste("open", selected_file))
  
  return(selected_file)
}

# Función para crear HTML viewer de un panel específico
create_panel_viewer <- function(panel_letter, selected_file) {
  panel_name <- basename(selected_file)
  
  html_content <- paste0(
    "<!DOCTYPE html>
    <html>
    <head>
        <title>Panel ", toupper(panel_letter), ": ", panel_name, "</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
            .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
            .header { text-align: center; margin-bottom: 30px; }
            .image-container { text-align: center; margin: 20px 0; }
            .image-container img { max-width: 100%; height: auto; border: 2px solid #ddd; border-radius: 8px; }
            .info { background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin: 20px 0; }
        </style>
    </head>
    <body>
        <div class='container'>
            <div class='header'>
                <h1>Panel ", toupper(panel_letter), ": ", panel_name, "</h1>
                <p>Selección de panel para Figura 1</p>
            </div>
            
            <div class='image-container'>
                <img src='", selected_file, "' alt='", panel_name, "'>
            </div>
            
            <div class='info'>
                <h3>Información del Panel:</h3>
                <ul>
                    <li><strong>Archivo:</strong> ", panel_name, "</li>
                    <li><strong>Tamaño:</strong> ", round(file.size(selected_file) / 1024, 1), " KB</li>
                    <li><strong>Fecha:</strong> ", file.info(selected_file)$mtime, "</li>
                </ul>
            </div>
        </div>
    </body>
    </html>"
  )
  
  html_file <- paste0("VIEWER_PANEL_", toupper(panel_letter), ".html")
  writeLines(html_content, html_file)
  
  cat("✅ HTML viewer creado:", html_file, "\n")
  system(paste("open", html_file))
  
  return(html_file)
}

# Función principal para seleccionar paneles
select_panels_interactive <- function() {
  cat("🎯 SELECTOR DE MEJORES PANELES PARA FIGURA 1\n")
  cat(paste(rep("=", 60), collapse = ""), "\n")
  
  selected_panels <- list()
  
  # Para cada panel (A, B, C, D, E, F)
  for (panel in c("a", "b", "c", "d", "e", "f")) {
    cat("\n")
    files <- show_panel_options(panel)
    
    if (is.null(files)) {
      next
    }
    
    cat("\n¿Cuál opción prefieres para Panel", toupper(panel), "? (número): ")
    choice <- as.numeric(readline())
    
    if (!is.na(choice) && choice >= 1 && choice <= length(files)) {
      selected_file <- open_panel_image(panel, choice)
      selected_panels[[panel]] <- selected_file
      
      # Crear viewer HTML
      create_panel_viewer(panel, selected_file)
      
      cat("✅ Panel", toupper(panel), "seleccionado:", basename(selected_file), "\n")
    } else {
      cat("❌ Selección inválida para Panel", toupper(panel), "\n")
    }
  }
  
  # Guardar selección
  if (length(selected_panels) > 0) {
    saveRDS(selected_panels, "selected_panels.rds")
    cat("\n✅ Selecciones guardadas en 'selected_panels.rds'\n")
  }
  
  return(selected_panels)
}

# Función para mostrar resumen de opciones disponibles
show_all_options <- function() {
  cat("📋 RESUMEN DE TODAS LAS OPCIONES DISPONIBLES:\n")
  cat(paste(rep("=", 60), collapse = ""), "\n")
  
  for (panel in c("a", "b", "c", "d", "e", "f")) {
    cat("\n🔹 PANEL", toupper(panel), ":\n")
    files <- list.files("figures/", pattern = paste0("^panel_", panel, "_"))
    if (length(files) > 0) {
      for (i in seq_along(files)) {
        cat(sprintf("  %d. %s\n", i, files[i]))
      }
    } else {
      cat("  (No hay archivos disponibles)\n")
    }
  }
}

# Ejecutar si se llama directamente
if (interactive()) {
  show_all_options()
  selected_panels <- select_panels_interactive()
} else {
  show_all_options()
}
