# Script para crear el HTML viewer para la Figura 1 Simple y Limpia

library(rmarkdown)
library(knitr)

# Definir la ruta de la figura
figure_path <- "figures/FIGURE_1_SIMPLE_CLEAN.png"

# Contenido Markdown para el HTML
markdown_content <- paste0(
"---
title: \"Figura 1: Análisis Inicial Simple y Limpio\"
output: html_document
---

# Figura 1: Análisis Inicial Simple y Limpio

Esta figura presenta un análisis exploratorio inicial del dataset de manera clara y legible, respondiendo a las preguntas clave sobre la evolución de los datos, la distribución de mutaciones y los patrones de estrés oxidativo.

## 🎯 Preguntas Respondidas:

### **Panel A: Evolución del Dataset**
- **Pregunta:** ¿Cómo cambia el dataset después de los pasos de `split` y `collapse`?
- **Respuesta:** Muestra la reducción dramática de SNVs (de 68,968 a 5,448 = 92.1% de reducción)
- **Hallazgo:** El procesamiento elimina ~92% de los datos, manteniendo solo los más relevantes

### **Panel B: Distribución de Tipos de Mutación**
- **Pregunta:** ¿Qué tipos de mutación son más frecuentes?
- **Respuesta:** Lista ordenada de todos los tipos de mutación con sus frecuencias
- **Hallazgo:** G>T se destaca en rojo como firma de estrés oxidativo

### **Panel C: G>X Spectrum por Posición**
- **Pregunta:** ¿Dónde ocurren las mutaciones G>X en los miRNAs?
- **Respuesta:** Distribución de G>A, G>C y G>T por cada posición del miRNA
- **Hallazgo:** La región semilla (posiciones 2-8) está resaltada en amarillo

### **Panel D: Comparación Seed vs No-Seed**
- **Pregunta:** ¿Hay diferencias entre la región semilla y el resto?
- **Respuesta:** Comparación directa de SNVs totales y fracción de G>T
- **Hallazgo:** Estadísticas clave por región funcional

---

## 📊 Visualización:

<img src=\"", figure_path, "\" alt=\"Figura 1 Simple y Limpia\" style=\"width:100%; border: 2px solid #ddd; border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);\">

---

## ✨ Mejoras en Esta Versión:

- **Layout 2x2:** Más espacioso y legible
- **4 paneles esenciales:** Sin redundancia ni sobrecarga
- **Datos reales:** Todos los gráficos muestran información real del dataset
- **Colores consistentes:** G>T siempre en rojo, región semilla en amarillo
- **Texto legible:** Tamaños apropiados y sin superposición
- **Información clara:** Cada panel responde una pregunta específica

---

## 🚀 Próximos Pasos:

1. **Figura 2:** Análisis mecanístico (G-content, contexto de secuencia)
2. **Figura 3:** Comparaciones entre grupos (ALS vs Control)
3. **Análisis estadístico:** Tests de significancia y correlaciones
"
)

# Guardar el contenido Markdown en un archivo temporal
temp_md_file <- "temp_viewer_simple_clean.md"
writeLines(markdown_content, temp_md_file)

# Renderizar el archivo Markdown a HTML
rmarkdown::render(temp_md_file, output_file = "VIEWER_FIGURA_1_SIMPLE_CLEAN.html", quiet = TRUE)

# Eliminar el archivo temporal
file.remove(temp_md_file)

cat("✅ HTML viewer para Figura 1 Simple y Limpia generado: VIEWER_FIGURA_1_SIMPLE_CLEAN.html\n")
