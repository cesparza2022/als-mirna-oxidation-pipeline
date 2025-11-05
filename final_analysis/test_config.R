# Test simple para verificar la configuración YAML
library(yaml)

cat("Testing YAML configuration...\n")

# Intentar cargar la configuración
tryCatch({
  config <- read_yaml("config/default_config.yaml")
  cat("✅ YAML loaded successfully\n")
  cat("Output directory:", config$paths$outputs$step_01_prep, "\n")
  cat("VAF threshold:", config$filtering$vaf_filtering$threshold, "\n")
}, error = function(e) {
  cat("❌ Error loading YAML:", e$message, "\n")
})

# Verificar si el archivo existe
if (file.exists("config/default_config.yaml")) {
  cat("✅ Config file exists\n")
  cat("File size:", file.size("config/default_config.yaml"), "bytes\n")
} else {
  cat("❌ Config file does not exist\n")
}






