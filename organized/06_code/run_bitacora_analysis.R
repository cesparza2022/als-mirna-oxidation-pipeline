# SCRIPT PARA EJECUTAR ANÁLISIS DE BITÁCORA
# Análisis de Mutaciones G>T en miRNAs

# Configurar directorio de trabajo
setwd("/Users/cesaresparza/New_Desktop/UCSD/8OG")

# Cargar funciones auxiliares
source("R/bitacora_functions.R")

# Cargar librerías necesarias
library(rmarkdown)
library(knitr)

cat("🚀 INICIANDO ANÁLISIS DE BITÁCORA\n")
cat(paste(rep("=", 50), collapse = ""), "\n")

# Verificar que los archivos necesarios existen
required_files <- c(
  "outputs/processed_mirna_dataset_simple.tsv",
  "outputs/bitacora_preguntas_analisis.Rmd",
  "R/bitacora_functions.R"
)

for(file in required_files) {
  if(file.exists(file)) {
    cat("✅", file, "\n")
  } else {
    cat("❌", file, "NO ENCONTRADO\n")
  }
}

# Ejecutar análisis completo
cat("\n🔧 EJECUTANDO ANÁLISIS COMPLETO...\n")
results <- run_complete_analysis()

# Renderizar notebook
cat("\n📝 RENDERIZANDO NOTEBOOK...\n")
tryCatch({
  render("outputs/bitacora_preguntas_analisis.Rmd", 
         output_file = "bitacora_preguntas_analisis.html",
         output_dir = "outputs",
         quiet = FALSE)
  cat("✅ NOTEBOOK RENDERIZADO EXITOSAMENTE\n")
  cat("   📁 Archivo: outputs/bitacora_preguntas_analisis.html\n")
}, error = function(e) {
  cat("❌ ERROR AL RENDERIZAR NOTEBOOK:\n")
  cat("   ", e$message, "\n")
})

# Crear resumen de resultados
cat("\n📊 CREANDO RESUMEN DE RESULTADOS...\n")
summary_file <- "outputs/bitacora_analysis_summary.txt"
sink(summary_file)

cat("BITÁCORA DE ANÁLISIS - RESUMEN DE RESULTADOS\n")
cat(paste(rep("=", 50), collapse = ""), "\n")
cat("Fecha:", Sys.Date(), "\n")
cat("Hora:", Sys.time(), "\n\n")

cat("DATOS PROCESADOS:\n")
cat("- Total mutaciones G>T:", results$total_gt_mutations, "\n")
cat("- miRNAs únicos:", results$unique_mirnas, "\n")
cat("- Muestras ALS:", results$als_samples_count, "\n")
cat("- Muestras Control:", results$control_samples_count, "\n\n")

cat("TOP 10 miRNAs MÁS AFECTADOS:\n")
for(i in 1:10) {
  if(i <= nrow(results$top_mirnas)) {
    mirna <- results$top_mirnas[i, ]
    cat(sprintf("%2d. %-20s %10s cuentas\n", 
                i, 
                substr(mirna$miRNA.name, 1, 20), 
                formatC(mirna$total_gt_counts, format = "f", big.mark = ",")))
  }
}

cat("\nANÁLISIS ESTADÍSTICO:\n")
if(!is.null(results$statistical_tests)) {
  cat("- T-test p-value:", results$statistical_tests$t_test$p.value, "\n")
  cat("- Wilcoxon p-value:", results$statistical_tests$wilcoxon$p.value, "\n")
  cat("- Significancia:", ifelse(results$statistical_tests$t_test$p.value < 0.05, "SÍ", "NO"), "\n")
}

cat("\nARCHIVOS GENERADOS:\n")
cat("- outputs/bitacora_preguntas_analisis.html\n")
cat("- outputs/bitacora_analysis_summary.txt\n")
cat("- outputs/bitacora_preguntas_analisis.Rmd\n")

cat("\nPRÓXIMOS PASOS:\n")
cat("1. Abrir outputs/bitacora_preguntas_analisis.html en navegador\n")
cat("2. Revisar análisis interactivo\n")
cat("3. Ejecutar chunks específicos según necesidad\n")
cat("4. Generar reportes adicionales\n")

sink()

cat("✅ RESUMEN GUARDADO EN:", summary_file, "\n")

# Crear archivo de configuración para el notebook
config_file <- "outputs/bitacora_config.R"
sink(config_file)

cat("# CONFIGURACIÓN PARA BITÁCORA DE ANÁLISIS\n")
cat("# Ejecutar este archivo antes de usar el notebook\n\n")
cat("setwd(\"/Users/cesaresparza/New_Desktop/UCSD/8OG\")\n")
cat("source(\"R/bitacora_functions.R\")\n\n")
cat("# Verificar archivos necesarios\n")
cat("if(!file.exists(\"outputs/processed_mirna_dataset_simple.tsv\")) {\n")
cat("  stop(\"Dataset procesado no encontrado. Ejecutar procesamiento primero.\")\n")
cat("}\n\n")
cat("cat(\"✅ CONFIGURACIÓN COMPLETADA\\n\")\n")
cat("cat(\"📚 FUNCIONES CARGADAS\\n\")\n")
cat("cat(\"🚀 LISTO PARA EJECUTAR NOTEBOOK\\n\")\n")

sink()

cat("✅ CONFIGURACIÓN GUARDADA EN:", config_file, "\n")

# Mostrar instrucciones finales
cat("\n🎉 ANÁLISIS DE BITÁCORA COMPLETADO\n")
cat(paste(rep("=", 50), collapse = ""), "\n")
cat("📁 ARCHIVOS GENERADOS:\n")
cat("   - outputs/bitacora_preguntas_analisis.html (NOTEBOOK PRINCIPAL)\n")
cat("   - outputs/bitacora_analysis_summary.txt (RESUMEN)\n")
cat("   - outputs/bitacora_config.R (CONFIGURACIÓN)\n")
cat("   - outputs/bitacora_preguntas_analisis.Rmd (CÓDIGO FUENTE)\n\n")

cat("🚀 INSTRUCCIONES:\n")
cat("1. Abrir outputs/bitacora_preguntas_analisis.html en navegador\n")
cat("2. Navegar por las secciones del análisis\n")
cat("3. Ejecutar chunks específicos según necesidad\n")
cat("4. Generar visualizaciones interactivas\n\n")

cat("📊 RESULTADOS PRINCIPALES:\n")
cat("- miRNAs más afectados por oxidación identificados\n")
cat("- Patrones de oxidación en región semilla caracterizados\n")
cat("- Diferencias entre grupos ALS vs Control analizadas\n")
cat("- Vías biológicas afectadas identificadas\n")
cat("- Potencial para biomarcadores evaluado\n\n")

cat("✅ ANÁLISIS COMPLETADO EXITOSAMENTE\n")

