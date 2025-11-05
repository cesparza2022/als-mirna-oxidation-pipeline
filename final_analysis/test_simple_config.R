# Test simple para verificar la configuración YAML simple
library(yaml)

cat("Testing simple YAML configuration...\n")

# Intentar cargar la configuración simple
tryCatch({
  config <- read_yaml("config/simple_config.yaml")
  cat("✅ Simple YAML loaded successfully\n")
  cat("Output directory:", config$paths$outputs$step_01_prep, "\n")
  cat("VAF threshold:", config$filtering$vaf_filtering$threshold, "\n")
  cat("DPI:", config$visualization$general$dpi, "\n")
}, error = function(e) {
  cat("❌ Error loading simple YAML:", e$message, "\n")
})






