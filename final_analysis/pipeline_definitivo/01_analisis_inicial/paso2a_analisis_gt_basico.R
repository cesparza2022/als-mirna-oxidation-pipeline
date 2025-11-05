# =============================================================================
# PASO 2A: ANÁLISIS BÁSICO DE MUTACIONES G>T
# =============================================================================
# Autor: César Esparza
# Fecha: 2024
# Descripción: Análisis básico de mutaciones G>T como biomarcadores de oxidación
# =============================================================================

# Cargar librerías
library(tidyverse)
library(ggplot2)

cat("=== PASO 2A: ANÁLISIS BÁSICO DE MUTACIONES G>T ===\n")
cat("Fecha:", Sys.time(), "\n\n")

# =============================================================================
# CARGAR DATOS PROCESADOS
# =============================================================================

cat("Cargando datos procesados...\n")
processed_data <- read_csv("tables/datos_procesados_split_collapse.csv")

cat("Datos cargados:\n")
cat("  - Filas:", nrow(processed_data), "\n")
cat("  - miRNAs únicos:", length(unique(processed_data$`miRNA name`)), "\n")

# =============================================================================
# IDENTIFICAR MUTACIONES G>T
# =============================================================================

cat("\nIdentificando mutaciones G>T...\n")

# Filtrar solo mutaciones G>T
gt_mutations <- processed_data %>%
  filter(grepl(":GT", `pos:mut`)) %>%
  mutate(
    position = as.numeric(str_extract(`pos:mut`, "^\\d+")),
    region = case_when(
      position >= 2 & position <= 8 ~ "Semilla",
      position >= 9 & position <= 15 ~ "Central",
      position >= 16 & position <= 22 ~ "3'",
      TRUE ~ "Otro"
    )
  )

cat("Mutaciones G>T identificadas:\n")
cat("  - Total mutaciones G>T:", nrow(gt_mutations), "\n")
cat("  - miRNAs con G>T:", length(unique(gt_mutations$`miRNA name`)), "\n")
cat("  - Posiciones con G>T:", length(unique(gt_mutations$position)), "\n")
cat("  - Regiones afectadas:", length(unique(gt_mutations$region)), "\n")

# =============================================================================
# ESTADÍSTICAS GENERALES DE G>T
# =============================================================================

cat("\nCalculando estadísticas generales de G>T...\n")

# Estadísticas generales
gt_general_stats <- data.frame(
  Metrica = c("Total SNVs", "Total G>T", "Porcentaje G>T", "miRNAs con G>T", 
              "Posiciones con G>T", "Regiones afectadas"),
  Valor = c(
    nrow(processed_data),
    nrow(gt_mutations),
    round(nrow(gt_mutations) / nrow(processed_data) * 100, 2),
    length(unique(gt_mutations$`miRNA name`)),
    length(unique(gt_mutations$position)),
    length(unique(gt_mutations$region))
  )
)

cat("Estadísticas generales de G>T:\n")
print(gt_general_stats)

# =============================================================================
# ANÁLISIS DE G>T POR REGIÓN
# =============================================================================

cat("\nAnalizando G>T por región funcional...\n")

# Análisis por región
gt_region_analysis <- gt_mutations %>%
  group_by(region) %>%
  summarise(
    total_gt = n(),
    mirnas_afectados = n_distinct(`miRNA name`),
    posiciones_unicas = n_distinct(position),
    porcentaje_gt = round(n() / nrow(gt_mutations) * 100, 2),
    .groups = "drop"
  ) %>%
  arrange(desc(total_gt))

cat("Análisis por región:\n")
print(gt_region_analysis)

# =============================================================================
# GUARDAR RESULTADOS
# =============================================================================

cat("\nGuardando resultados...\n")
write_csv(gt_general_stats, "tables/gt_estadisticas_generales.csv")
write_csv(gt_region_analysis, "tables/gt_analisis_por_region.csv")
write_csv(gt_mutations, "tables/mutaciones_gt_detalladas.csv")

# =============================================================================
# GENERAR VISUALIZACIONES BÁSICAS
# =============================================================================

cat("\nGenerando visualizaciones básicas...\n")

# 1. Distribución de G>T por región
p1 <- ggplot(gt_region_analysis, aes(x = region, y = total_gt, fill = region)) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = paste0(total_gt, "\n(", porcentaje_gt, "%)")), 
            vjust = -0.5, size = 4) +
  labs(title = "Distribución de Mutaciones G>T por Región Funcional",
       x = "Región", y = "Número de Mutaciones G>T") +
  theme_minimal() +
  theme(legend.position = "none") +
  scale_fill_brewer(palette = "Set2")

ggsave("figures/gt_distribucion_por_region.png", p1, width = 10, height = 6, dpi = 300)

# 2. Comparación G>T vs Total SNVs
comparison_data <- data.frame(
  Tipo = c("Total SNVs", "Mutaciones G>T"),
  Cantidad = c(nrow(processed_data), nrow(gt_mutations))
)

p2 <- ggplot(comparison_data, aes(x = Tipo, y = Cantidad, fill = Tipo)) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = paste0(Cantidad, "\n(", round(Cantidad/sum(Cantidad)*100, 1), "%)")), 
            vjust = -0.5, size = 5) +
  labs(title = "Comparación: Total SNVs vs Mutaciones G>T",
       x = "Tipo", y = "Cantidad") +
  theme_minimal() +
  theme(legend.position = "none") +
  scale_fill_brewer(palette = "Set1")

ggsave("figures/gt_comparacion_total.png", p2, width = 8, height = 6, dpi = 300)

# =============================================================================
# RESUMEN
# =============================================================================

cat("\n=== PASO 2A COMPLETADO ===\n")
cat("Archivos generados:\n")
cat("  - 3 archivos CSV con análisis\n")
cat("  - 2 archivos PNG con visualizaciones\n")
cat("\nResumen de mutaciones G>T:\n")
cat("  - Total G>T:", nrow(gt_mutations), "de", nrow(processed_data), "SNVs (", 
      round(nrow(gt_mutations) / nrow(processed_data) * 100, 2), "%)\n")
cat("  - miRNAs afectados:", length(unique(gt_mutations$`miRNA name`)), "\n")
cat("  - Región con más G>T:", gt_region_analysis$region[1], "(", gt_region_analysis$total_gt[1], "mutaciones)\n")
cat("\nPaso 2A completado exitosamente!\n")








