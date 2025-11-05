# =============================================================================
# SCRIPT PARA EJECUTAR ANÁLISIS INICIAL DEL PIPELINE
# =============================================================================
# Autor: César Esparza
# Fecha: 2024
# Descripción: Script principal para ejecutar el análisis inicial completo
# =============================================================================

# Limpiar ambiente
rm(list = ls())

# Cargar configuración
source("../config_pipeline.R")

# Cargar funciones del pipeline
source("functions_pipeline.R")

# Cargar librerías adicionales
library(ggplot2)
library(gridExtra)
library(knitr)
library(DT)

# =============================================================================
# CONFIGURACIÓN
# =============================================================================

# Usar ruta de la configuración
data_path <- config$data_paths$raw_data

# Verificar que el archivo existe
if (!file.exists(data_path)) {
  cat("ERROR: No se encontró el archivo de datos en:", data_path, "\n")
  cat("Por favor, verificar la configuración en config_pipeline.R\n")
  stop("Archivo de datos no encontrado")
}

# =============================================================================
# EJECUTAR ANÁLISIS INICIAL
# =============================================================================

cat("=== INICIANDO ANÁLISIS INICIAL DEL PIPELINE ===\n")
cat("Fecha:", Sys.time(), "\n")
cat("Archivo de datos:", data_path, "\n\n")

# Ejecutar pipeline completo
results <- run_initial_analysis(data_path)

# =============================================================================
# GENERAR GRÁFICAS ADICIONALES
# =============================================================================

cat("\n=== GENERANDO GRÁFICAS ADICIONALES ===\n")

# Configurar tema para gráficas
theme_set(theme_minimal() + 
          theme(axis.text.x = element_text(angle = 45, hjust = 1),
                plot.title = element_text(size = 14, face = "bold"),
                plot.subtitle = element_text(size = 12),
                legend.position = "bottom"))

# 1. Gráfica de distribución de tipos de mutación
mutation_types <- results$processed_data %>%
  mutate(mutation_type = str_extract(pos.mut, ":[A-Z]{2}")) %>%
  count(mutation_type, sort = TRUE)

p1 <- ggplot(mutation_types, aes(x = reorder(mutation_type, -n), y = n)) +
  geom_col(fill = "steelblue", alpha = 0.7) +
  labs(title = "Distribución de Tipos de Mutación",
       x = "Tipo de Mutación", y = "Número de SNVs") +
  theme_minimal()

ggsave("figures/01_mutation_types_distribution.png", p1, width = 10, height = 6, dpi = 300)

# 2. Gráfica de distribución de NaNs
p2 <- ggplot(results$nan_summary, aes(x = n_nans)) +
  geom_histogram(bins = 30, fill = "coral", alpha = 0.7) +
  labs(title = "Distribución de NaNs por Muestra",
       subtitle = "Después de filtrar VAFs > 50%",
       x = "Número de NaNs", y = "Frecuencia") +
  theme_minimal()

ggsave("figures/02_nans_distribution.png", p2, width = 10, height = 6, dpi = 300)

# 3. Gráfica de cobertura de SNVs
p3 <- ggplot(results$snv_coverage, aes(x = coverage_pct)) +
  geom_histogram(bins = 30, fill = "lightgreen", alpha = 0.7) +
  labs(title = "Distribución de Cobertura de SNVs",
       subtitle = "Porcentaje de muestras sin NaNs",
       x = "Cobertura (%)", y = "Número de SNVs") +
  theme_minimal()

ggsave("figures/03_snv_coverage_distribution.png", p3, width = 10, height = 6, dpi = 300)

# 4. Gráfica de top miRNAs
p4 <- ggplot(head(results$mirna_analysis$snv_counts, 20), 
             aes(x = reorder(miRNA.name, n), y = n)) +
  geom_col(fill = "steelblue", alpha = 0.7) +
  coord_flip() +
  labs(title = "Top 20 miRNAs con Más SNVs",
       x = "miRNA", y = "Número de SNVs") +
  theme_minimal()

p5 <- ggplot(head(results$mirna_analysis$gt_counts, 20), 
             aes(x = reorder(miRNA.name, n), y = n)) +
  geom_col(fill = "red", alpha = 0.7) +
  coord_flip() +
  labs(title = "Top 20 miRNAs con Más Mutaciones G>T",
       x = "miRNA", y = "Número de Mutaciones G>T") +
  theme_minimal()

ggsave("figures/04_top_mirnas_comparison.png", 
       grid.arrange(p4, p5, ncol = 2), width = 15, height = 8, dpi = 300)

# 5. Gráfica de análisis por posición
p6 <- ggplot(head(results$position_analysis$position_counts, 20), 
             aes(x = position, y = n)) +
  geom_col(fill = "purple", alpha = 0.7) +
  labs(title = "Distribución de SNVs por Posición",
       x = "Posición en miRNA", y = "Número de SNVs") +
  theme_minimal()

p7 <- ggplot(head(results$position_analysis$position_gt_counts, 20), 
             aes(x = position, y = n)) +
  geom_col(fill = "orange", alpha = 0.7) +
  labs(title = "Distribución de Mutaciones G>T por Posición",
       x = "Posición en miRNA", y = "Número de Mutaciones G>T") +
  theme_minimal()

ggsave("figures/05_position_analysis.png", 
       grid.arrange(p6, p7, ncol = 2), width = 15, height = 6, dpi = 300)

# =============================================================================
# MOSTRAR RESUMEN FINAL
# =============================================================================

cat("\n=== RESUMEN FINAL DEL ANÁLISIS ===\n")

# Mostrar estadísticas principales
cat("Datos originales:\n")
cat("  - SNVs:", nrow(results$raw_data), "\n")
cat("  - miRNAs:", length(unique(results$raw_data$miRNA.name)), "\n")
cat("  - Muestras:", ncol(results$raw_data) - 3, "\n\n")

cat("Después de split-collapse:\n")
cat("  - SNVs:", nrow(results$processed_data), "\n")
cat("  - miRNAs:", length(unique(results$processed_data$miRNA.name)), "\n")
cat("  - Muestras:", ncol(results$processed_data) - 3, "\n\n")

cat("Después de filtrado VAF:\n")
cat("  - SNVs:", nrow(results$filtered_data), "\n")
cat("  - Total NaNs:", sum(results$nan_summary$n_nans), "\n")
cat("  - Promedio NaNs/muestra:", round(mean(results$nan_summary$n_nans), 2), "\n")
cat("  - Máximo NaNs/muestra:", max(results$nan_summary$n_nans), "\n\n")

cat("Top miRNAs:\n")
cat("  - Más SNVs:", results$mirna_analysis$snv_counts$miRNA.name[1], 
    "(", results$mirna_analysis$snv_counts$n[1], "SNVs)\n")
cat("  - Más G>T:", results$mirna_analysis$gt_counts$miRNA.name[1], 
    "(", results$mirna_analysis$gt_counts$n[1], "mutaciones G>T)\n\n")

cat("Top posiciones:\n")
cat("  - Más SNVs: Posición", results$position_analysis$position_counts$position[1], 
    "(", results$position_analysis$position_counts$n[1], "SNVs)\n")
cat("  - Más G>T: Posición", results$position_analysis$position_gt_counts$position[1], 
    "(", results$position_analysis$position_gt_counts$n[1], "mutaciones G>T)\n\n")

cat("Archivos generados:\n")
cat("  - Datos procesados: outputs/\n")
cat("  - Gráficas: figures/\n")
cat("  - Tablas: tables/\n\n")

cat("=== ANÁLISIS INICIAL COMPLETADO ===\n")
cat("Fecha de finalización:", Sys.time(), "\n")

# =============================================================================
# FIN DEL SCRIPT
# =============================================================================
