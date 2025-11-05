# =============================================================================
# CONFIGURACIÓN DEL PIPELINE DEFINITIVO
# =============================================================================
# Autor: César Esparza
# Fecha: 2024
# Descripción: Configuración centralizada para el pipeline de análisis
# =============================================================================

# =============================================================================
# CONFIGURACIÓN DE RUTAS
# =============================================================================

# Rutas principales
config <- list(
  
  # Rutas de datos
  data_paths = list(
    raw_data = "/Users/cesaresparza/New_Desktop/UCSD/8OG/results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt",
    metadata = "../../processed_data/metadata.txt",  # Si existe
    processed_data = "outputs/"
  ),
  
  # Rutas de salida
  output_paths = list(
    outputs = "outputs/",
    figures = "figures/",
    tables = "tables/",
    reports = "reports/"
  ),
  
  # Rutas de análisis por paso
  step_paths = list(
    step1 = "01_analisis_inicial/",
    step2 = "02_preprocesamiento/",
    step3 = "03_analisis_exploratorio/",
    step4 = "04_analisis_estadistico/",
    step5 = "05_analisis_funcional/",
    step6 = "06_presentacion_final/"
  )
)

# =============================================================================
# CONFIGURACIÓN DE PARÁMETROS
# =============================================================================

# Parámetros de filtrado
filtering_params <- list(
  
  # Filtrado VAF
  vaf_threshold = 0.5,  # VAFs > 50% se convierten a NaN
  
  # Filtrado de cobertura
  min_coverage = 0.1,   # Mínimo 10% de muestras sin NaN
  min_samples = 10,     # Mínimo 10 muestras por SNV
  
  # Filtrado de miRNAs
  min_mirna_snvs = 5,   # Mínimo 5 SNVs por miRNA
  
  # Filtrado de posiciones
  min_position_snvs = 3 # Mínimo 3 SNVs por posición
)

# Parámetros estadísticos
statistical_params <- list(
  
  # Tests estadísticos
  alpha = 0.05,         # Nivel de significancia
  multiple_correction = "BH",  # Corrección de Benjamini-Hochberg
  
  # Análisis de potencia
  power_threshold = 0.8,
  
  # Bootstrap
  n_bootstrap = 1000,
  
  # Clustering
  n_clusters = 5,
  distance_method = "euclidean",
  clustering_method = "ward.D2"
)

# Parámetros de visualización
visualization_params <- list(
  
  # Tamaños de gráficas
  fig_width = 10,
  fig_height = 6,
  fig_dpi = 300,
  
  # Colores
  colors = list(
    als = "#E31A1C",      # Rojo para ALS
    control = "#1F78B4",  # Azul para Control
    gt = "#FF7F00",       # Naranja para G>T
    other = "#33A02C"     # Verde para otros
  ),
  
  # Temas
  theme = "minimal",
  base_size = 12
)

# =============================================================================
# CONFIGURACIÓN DE ANÁLISIS
# =============================================================================

# Configuración de análisis específicos
analysis_config <- list(
  
  # Análisis de mutaciones G>T
  gt_analysis = list(
    enabled = TRUE,
    focus_positions = c(6, 7, 8),  # Región seed
    min_gt_frequency = 0.01
  ),
  
  # Análisis por posición
  position_analysis = list(
    enabled = TRUE,
    positions_range = 1:23,
    seed_region = 2:8,
    focus_positions = c(6, 7, 8)
  ),
  
  # Análisis de miRNAs
  mirna_analysis = list(
    enabled = TRUE,
    top_n = 20,
    min_expression = 0.1
  ),
  
  # Análisis comparativo
  comparative_analysis = list(
    enabled = TRUE,
    groups = c("ALS", "Control"),
    tests = c("t.test", "wilcox.test", "anova")
  )
)

# =============================================================================
# CONFIGURACIÓN DE CALIDAD
# =============================================================================

# Parámetros de control de calidad
quality_control <- list(
  
  # Detección de outliers
  outlier_detection = list(
    method = "iqr",  # IQR, zscore, mahalanobis
    threshold = 3
  ),
  
  # Detección de batch effects
  batch_detection = list(
    enabled = TRUE,
    method = "pca",
    threshold = 0.05
  ),
  
  # Validación de datos
  data_validation = list(
    check_na_proportions = TRUE,
    check_zero_counts = TRUE,
    check_duplicates = TRUE
  )
)

# =============================================================================
# CONFIGURACIÓN DE REPORTES
# =============================================================================

# Configuración de reportes
reporting_config <- list(
  
  # Formato de reportes
  format = "html",
  theme = "flatly",
  toc = TRUE,
  toc_float = TRUE,
  code_folding = "show",
  
  # Contenido de reportes
  include_code = TRUE,
  include_plots = TRUE,
  include_tables = TRUE,
  include_summary = TRUE,
  
  # Metadatos
  author = "César Esparza",
  title = "Análisis de SNVs en miRNAs para ALS",
  subtitle = "Pipeline Definitivo"
)

# =============================================================================
# FUNCIONES DE CONFIGURACIÓN
# =============================================================================

# Función para crear directorios
create_directories <- function() {
  
  cat("=== CREANDO DIRECTORIOS ===\n")
  
  # Crear directorios principales
  dirs_to_create <- c(
    config$output_paths$outputs,
    config$output_paths$figures,
    config$output_paths$tables,
    config$output_paths$reports
  )
  
  # Crear directorios por paso
  for (step in names(config$step_paths)) {
    step_dir <- config$step_paths[[step]]
    dirs_to_create <- c(dirs_to_create, 
                       paste0(step_dir, "outputs/"),
                       paste0(step_dir, "figures/"),
                       paste0(step_dir, "tables/"))
  }
  
  # Crear directorios
  for (dir in dirs_to_create) {
    if (!dir.exists(dir)) {
      dir.create(dir, recursive = TRUE, showWarnings = FALSE)
      cat("Creado:", dir, "\n")
    }
  }
  
  cat("Directorios creados exitosamente\n")
}

# Función para validar configuración
validate_config <- function() {
  
  cat("=== VALIDANDO CONFIGURACIÓN ===\n")
  
  # Validar rutas de datos
  if (!file.exists(config$data_paths$raw_data)) {
    warning("Archivo de datos no encontrado: ", config$data_paths$raw_data)
  }
  
  # Validar parámetros
  if (filtering_params$vaf_threshold < 0 || filtering_params$vaf_threshold > 1) {
    stop("vaf_threshold debe estar entre 0 y 1")
  }
  
  if (statistical_params$alpha < 0 || statistical_params$alpha > 1) {
    stop("alpha debe estar entre 0 y 1")
  }
  
  cat("Configuración validada exitosamente\n")
}

# Función para mostrar configuración
show_config <- function() {
  
  cat("=== CONFIGURACIÓN DEL PIPELINE ===\n")
  
  cat("Rutas de datos:\n")
  for (path in names(config$data_paths)) {
    cat("  ", path, ":", config$data_paths[[path]], "\n")
  }
  
  cat("\nParámetros de filtrado:\n")
  for (param in names(filtering_params)) {
    cat("  ", param, ":", filtering_params[[param]], "\n")
  }
  
  cat("\nParámetros estadísticos:\n")
  for (param in names(statistical_params)) {
    cat("  ", param, ":", statistical_params[[param]], "\n")
  }
  
  cat("\nAnálisis habilitados:\n")
  for (analysis in names(analysis_config)) {
    cat("  ", analysis, ":", analysis_config[[analysis]]$enabled, "\n")
  }
}

# =============================================================================
# INICIALIZACIÓN
# =============================================================================

# Función para inicializar el pipeline
initialize_pipeline <- function() {
  
  cat("=== INICIALIZANDO PIPELINE ===\n")
  
  # Crear directorios
  create_directories()
  
  # Validar configuración
  validate_config()
  
  # Mostrar configuración
  show_config()
  
  cat("\nPipeline inicializado exitosamente\n")
}

# =============================================================================
# EXPORTAR CONFIGURACIÓN
# =============================================================================

# Exportar configuración para uso en otros scripts
export_config <- function() {
  
  config_list <- list(
    config = config,
    filtering_params = filtering_params,
    statistical_params = statistical_params,
    visualization_params = visualization_params,
    analysis_config = analysis_config,
    quality_control = quality_control,
    reporting_config = reporting_config
  )
  
  # Guardar como RDS
  saveRDS(config_list, "config_pipeline.rds")
  
  # Guardar como JSON
  jsonlite::write_json(config_list, "config_pipeline.json", pretty = TRUE)
  
  cat("Configuración exportada a config_pipeline.rds y config_pipeline.json\n")
}

# =============================================================================
# FIN DEL ARCHIVO
# =============================================================================
