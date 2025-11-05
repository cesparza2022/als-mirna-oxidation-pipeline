# ⚙️ CONFIGURACIÓN PIPELINE_2

## 📁 RUTAS Y DIRECTORIOS
base_dir <- "/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/pipeline_definitivo/pipeline_2"
data_dir <- "/Users/cesaresparza/New_Desktop/UCSD/8OG/results/Magen_ALS-bloodplasma"

## 📊 DATOS DE ENTRADA
raw_data_path <- file.path(data_dir, "miRNA_count.Q33.txt")

## 📤 DIRECTORIOS DE SALIDA
outputs_dir <- file.path(base_dir, "outputs")
figures_dir <- file.path(base_dir, "figures")
tables_dir <- file.path(base_dir, "tables")
reports_dir <- file.path(base_dir, "reports")

## 🔧 PARÁMETROS DE PROCESAMIENTO
processing_params <- list(
  vaf_threshold = 0.5,           # VAFs > 50% se convierten a NaN
  min_coverage = 10,             # Cobertura mínima
  min_mutations = 3,             # Mínimo de mutaciones por miRNA
  max_position = 22              # Posición máxima en miRNA
)

## 📊 PARÁMETROS DE VISUALIZACIÓN
viz_params <- list(
  figure_width = 16,
  figure_height = 12,
  dpi = 300,
  theme = "minimal",
  color_palette = "viridis",
  top_n_mirnas = 15
)

## 📈 PARÁMETROS ESTADÍSTICOS
stats_params <- list(
  alpha = 0.05,
  fdr_method = "BH",
  test_type = "wilcoxon",
  min_samples_per_group = 5
)

## 🎯 CONFIGURACIÓN DE GRUPOS
group_config <- list(
  als_pattern = "ALS",
  control_pattern = "Control",
  group_column = "sample_name"
)

## 📋 INICIALIZACIÓN DE DIRECTORIOS
initialize_pipeline_2 <- function() {
  # Crear directorios si no existen
  dirs_to_create <- c(outputs_dir, figures_dir, tables_dir, reports_dir)
  
  for (dir in dirs_to_create) {
    if (!dir.exists(dir)) {
      dir.create(dir, recursive = TRUE)
      cat("✅ Directorio creado:", dir, "\n")
    }
  }
  
  cat("🚀 Pipeline_2 inicializado correctamente\n")
}

## 📊 CARGAR DATOS
load_data <- function() {
  if (!file.exists(raw_data_path)) {
    stop("❌ Archivo de datos no encontrado: ", raw_data_path)
  }
  
  cat("📥 Cargando datos desde:", raw_data_path, "\n")
  
  # Cargar datos (ajustar según formato real)
  data <- readr::read_tsv(raw_data_path)
  
  cat("✅ Datos cargados:", nrow(data), "filas,", ncol(data), "columnas\n")
  
  return(data)
}

## 🎯 CONFIGURACIÓN COMPLETA
pipeline_2_config <- list(
  base_dir = base_dir,
  data_dir = data_dir,
  raw_data_path = raw_data_path,
  outputs_dir = outputs_dir,
  figures_dir = figures_dir,
  tables_dir = tables_dir,
  reports_dir = reports_dir,
  processing_params = processing_params,
  viz_params = viz_params,
  stats_params = stats_params,
  group_config = group_config
)

