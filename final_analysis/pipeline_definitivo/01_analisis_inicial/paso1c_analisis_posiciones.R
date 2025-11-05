# =============================================================================
# PASO 1C: ANÁLISIS DETALLADO DE POSICIONES
# =============================================================================
# Autor: César Esparza
# Fecha: 2024
# Descripción: Análisis detallado de posiciones en miRNAs
# =============================================================================

# Cargar librerías
library(tidyverse)
library(ggplot2)

cat("=== PASO 1C: ANÁLISIS DETALLADO DE POSICIONES ===\n")
cat("Fecha:", Sys.time(), "\n\n")

# =============================================================================
# CARGAR DATOS PROCESADOS
# =============================================================================

cat("Cargando datos procesados...\n")
processed_data <- read_csv("tables/datos_procesados_split_collapse.csv")

cat("Datos cargados:\n")
cat("  - Filas:", nrow(processed_data), "\n")

# =============================================================================
# ANÁLISIS POR POSICIÓN
# =============================================================================

cat("\nAnalizando posiciones...\n")

# Análisis por posición
position_analysis <- processed_data %>%
  mutate(position = as.numeric(str_extract(`pos:mut`, "^\\d+"))) %>%
  filter(!is.na(position)) %>%
  group_by(position) %>%
  summarise(
    total_snvs = n(),
    mirnas_unicos = n_distinct(`miRNA name`),
    mutaciones_unicas = n_distinct(`pos:mut`),
    gt_mutations = sum(grepl(":GT", `pos:mut`)),
    gt_percentage = round(sum(grepl(":GT", `pos:mut`)) / n() * 100, 2),
    .groups = "drop"
  ) %>%
  arrange(desc(total_snvs))

cat("Análisis por posición completado:\n")
cat("  - Posiciones analizadas:", nrow(position_analysis), "\n")
cat("  - Posición más mutada:", position_analysis$position[1], "(", position_analysis$total_snvs[1], "SNVs)\n")

# =============================================================================
# ANÁLISIS DE POSICIONES CON MÁS MUTACIONES G>T
# =============================================================================

cat("\nAnalizando posiciones con más mutaciones G>T...\n")

# Top posiciones con G>T
gt_position_analysis <- position_analysis %>%
  filter(gt_mutations > 0) %>%
  arrange(desc(gt_mutations))

cat("Posiciones con mutaciones G>T:\n")
cat("  - Posiciones con G>T:", nrow(gt_position_analysis), "\n")
cat("  - Posición con más G>T:", gt_position_analysis$position[1], "(", gt_position_analysis$gt_mutations[1], "mutaciones)\n")

# =============================================================================
# ANÁLISIS POR REGIÓN Y POSICIÓN
# =============================================================================

cat("\nAnalizando por región y posición...\n")

# Análisis detallado por región y posición
region_position_analysis <- processed_data %>%
  mutate(
    position = as.numeric(str_extract(`pos:mut`, "^\\d+")),
    region = case_when(
      position >= 2 & position <= 8 ~ "Semilla",
      position >= 9 & position <= 15 ~ "Central",
      position >= 16 & position <= 22 ~ "3'",
      TRUE ~ "Otro"
    )
  ) %>%
  filter(!is.na(position)) %>%
  group_by(region, position) %>%
  summarise(
    total_snvs = n(),
    mirnas_afectados = n_distinct(`miRNA name`),
    gt_mutations = sum(grepl(":GT", `pos:mut`)),
    gt_percentage = round(sum(grepl(":GT", `pos:mut`)) / n() * 100, 2),
    .groups = "drop"
  ) %>%
  arrange(region, desc(total_snvs))

cat("Análisis por región y posición completado:\n")
cat("  - Combinaciones región-posición:", nrow(region_position_analysis), "\n")

# =============================================================================
# GUARDAR RESULTADOS
# =============================================================================

cat("\nGuardando resultados...\n")
write_csv(position_analysis, "tables/analisis_posiciones_detallado.csv")
write_csv(gt_position_analysis, "tables/analisis_posiciones_gt.csv")
write_csv(region_position_analysis, "tables/analisis_region_posicion.csv")

# =============================================================================
# GENERAR VISUALIZACIONES
# =============================================================================

cat("\nGenerando visualizaciones...\n")

# 1. Top 15 posiciones más mutadas
top_positions <- head(position_analysis, 15)
p1 <- ggplot(top_positions, aes(x = position, y = total_snvs, fill = total_snvs)) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = paste0(total_snvs, "\n(", gt_percentage, "% G>T)")), 
            vjust = -0.5, size = 3) +
  labs(title = "Top 15 Posiciones más Mutadas en miRNAs",
       x = "Posición en miRNA", y = "Número de SNVs") +
  theme_minimal() +
  scale_fill_gradient(low = "lightcoral", high = "darkred") +
  scale_x_continuous(breaks = top_positions$position)

ggsave("figures/top_15_posiciones_mutadas.png", p1, width = 12, height = 6, dpi = 300)

# 2. Top 10 posiciones con más mutaciones G>T
top_gt_positions <- head(gt_position_analysis, 10)
p2 <- ggplot(top_gt_positions, aes(x = position, y = gt_mutations, fill = gt_mutations)) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = paste0(gt_mutations, "\n(", gt_percentage, "%)")), 
            vjust = -0.5, size = 3) +
  labs(title = "Top 10 Posiciones con más Mutaciones G>T",
       x = "Posición en miRNA", y = "Número de Mutaciones G>T") +
  theme_minimal() +
  scale_fill_gradient(low = "lightgreen", high = "darkgreen") +
  scale_x_continuous(breaks = top_gt_positions$position)

ggsave("figures/top_10_posiciones_gt.png", p2, width = 10, height = 6, dpi = 300)

# 3. Distribución de SNVs por posición (todas las posiciones)
p3 <- ggplot(position_analysis, aes(x = position, y = total_snvs)) +
  geom_line(color = "blue", alpha = 0.7) +
  geom_point(color = "red", size = 2) +
  labs(title = "Distribución de SNVs por Posición en miRNAs",
       x = "Posición en miRNA", y = "Número de SNVs") +
  theme_minimal() +
  scale_x_continuous(breaks = seq(1, max(position_analysis$position), by = 2))

ggsave("figures/distribucion_snvs_por_posicion.png", p3, width = 12, height = 6, dpi = 300)

# =============================================================================
# RESUMEN
# =============================================================================

cat("\n=== PASO 1C COMPLETADO ===\n")
cat("Archivos generados:\n")
cat("  - 3 archivos CSV con análisis\n")
cat("  - 3 archivos PNG con visualizaciones\n")
cat("\nResumen de posiciones:\n")
cat("  - Total posiciones:", nrow(position_analysis), "\n")
cat("  - Posición más mutada:", position_analysis$position[1], "(", position_analysis$total_snvs[1], "SNVs)\n")
cat("  - Posición con más G>T:", gt_position_analysis$position[1], "(", gt_position_analysis$gt_mutations[1], "mutaciones G>T)\n")
cat("\nPaso 1C completado exitosamente!\n")








