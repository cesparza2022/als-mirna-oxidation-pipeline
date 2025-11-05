# =============================================================================
# PASO 2B: ANÁLISIS DETALLADO DE G>T POR POSICIÓN
# =============================================================================
# Autor: César Esparza
# Fecha: 2024
# Descripción: Análisis específico de posiciones con más mutaciones G>T
# =============================================================================

# Cargar librerías
library(tidyverse)
library(ggplot2)

cat("=== PASO 2B: ANÁLISIS DETALLADO DE G>T POR POSICIÓN ===\n")
cat("Fecha:", Sys.time(), "\n\n")

# =============================================================================
# CARGAR DATOS PROCESADOS
# =============================================================================

cat("Cargando datos procesados...\n")
processed_data <- read_csv("tables/datos_procesados_split_collapse.csv")
gt_mutations <- read_csv("tables/mutaciones_gt_detalladas.csv")

cat("Datos cargados:\n")
cat("  - Total SNVs:", nrow(processed_data), "\n")
cat("  - Mutaciones G>T:", nrow(gt_mutations), "\n")

# =============================================================================
# ANÁLISIS DETALLADO POR POSICIÓN
# =============================================================================

cat("\nAnalizando G>T por posición específica...\n")

# Análisis detallado por posición
gt_position_detailed <- gt_mutations %>%
  group_by(position) %>%
  summarise(
    total_gt = n(),
    mirnas_afectados = n_distinct(`miRNA name`),
    mutaciones_unicas = n_distinct(`pos:mut`),
    porcentaje_gt = round(n() / nrow(gt_mutations) * 100, 2),
    .groups = "drop"
  ) %>%
  arrange(desc(total_gt))

cat("Top 10 posiciones con más mutaciones G>T:\n")
print(head(gt_position_detailed, 10))

# =============================================================================
# ANÁLISIS DE HOTSPOTS DE OXIDACIÓN
# =============================================================================

cat("\nIdentificando hotspots de oxidación...\n")

# Definir hotspots (posiciones con >100 mutaciones G>T)
hotspots <- gt_position_detailed %>%
  filter(total_gt >= 100) %>%
  arrange(desc(total_gt))

cat("Hotspots de oxidación (≥100 mutaciones G>T):\n")
print(hotspots)

# =============================================================================
# ANÁLISIS COMPARATIVO G>T vs OTRAS MUTACIONES
# =============================================================================

cat("\nComparando G>T vs otras mutaciones por posición...\n")

# Análisis comparativo por posición
position_comparison <- processed_data %>%
  mutate(
    position = as.numeric(str_extract(`pos:mut`, "^\\d+")),
    is_gt = grepl(":GT", `pos:mut`)
  ) %>%
  filter(!is.na(position)) %>%
  group_by(position) %>%
  summarise(
    total_snvs = n(),
    gt_mutations = sum(is_gt),
    other_mutations = sum(!is_gt),
    gt_percentage = round(sum(is_gt) / n() * 100, 2),
    .groups = "drop"
  ) %>%
  arrange(desc(gt_mutations))

cat("Top 10 posiciones con más mutaciones G>T (comparativo):\n")
print(head(position_comparison, 10))

# =============================================================================
# ANÁLISIS DE miRNAs POR POSICIÓN
# =============================================================================

cat("\nAnalizando miRNAs más afectados por posición...\n")

# Top miRNAs por posición (para las 5 posiciones con más G>T)
top_positions <- head(gt_position_detailed$position, 5)
mirna_by_position <- list()

for (pos in top_positions) {
  mirna_by_position[[as.character(pos)]] <- gt_mutations %>%
    filter(position == pos) %>%
    group_by(`miRNA name`) %>%
    summarise(
      gt_count = n(),
      .groups = "drop"
    ) %>%
    arrange(desc(gt_count)) %>%
    head(10)
}

# =============================================================================
# GUARDAR RESULTADOS
# =============================================================================

cat("\nGuardando resultados...\n")
write_csv(gt_position_detailed, "tables/gt_analisis_detallado_por_posicion.csv")
write_csv(hotspots, "tables/gt_hotspots_oxidacion.csv")
write_csv(position_comparison, "tables/gt_comparacion_por_posicion.csv")

# Guardar análisis de miRNAs por posición
for (pos in top_positions) {
  filename <- paste0("tables/gt_mirnas_posicion_", pos, ".csv")
  write_csv(mirna_by_position[[as.character(pos)]], filename)
}

# =============================================================================
# GENERAR VISUALIZACIONES
# =============================================================================

cat("\nGenerando visualizaciones...\n")

# 1. Top 15 posiciones con más mutaciones G>T
top_15_gt_positions <- head(gt_position_detailed, 15)
p1 <- ggplot(top_15_gt_positions, aes(x = position, y = total_gt, fill = total_gt)) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = paste0(total_gt, "\n(", porcentaje_gt, "%)")), 
            vjust = -0.5, size = 3) +
  labs(title = "Top 15 Posiciones con más Mutaciones G>T",
       x = "Posición en miRNA", y = "Número de Mutaciones G>T") +
  theme_minimal() +
  scale_fill_gradient(low = "lightgreen", high = "darkgreen") +
  scale_x_continuous(breaks = top_15_gt_positions$position)

ggsave("figures/gt_top_15_posiciones_detallado.png", p1, width = 12, height = 6, dpi = 300)

# 2. Comparación G>T vs Otras mutaciones (Top 10 posiciones)
top_10_comparison <- head(position_comparison, 10)
comparison_long <- top_10_comparison %>%
  select(position, gt_mutations, other_mutations) %>%
  pivot_longer(cols = c(gt_mutations, other_mutations), 
               names_to = "tipo", values_to = "cantidad") %>%
  mutate(tipo = ifelse(tipo == "gt_mutations", "G>T", "Otras"))

p2 <- ggplot(comparison_long, aes(x = position, y = cantidad, fill = tipo)) +
  geom_col(position = "dodge", alpha = 0.8) +
  labs(title = "Comparación G>T vs Otras Mutaciones por Posición (Top 10)",
       x = "Posición en miRNA", y = "Número de Mutaciones") +
  theme_minimal() +
  scale_fill_manual(values = c("G>T" = "darkgreen", "Otras" = "lightblue")) +
  scale_x_continuous(breaks = top_10_comparison$position)

ggsave("figures/gt_comparacion_por_posicion.png", p2, width = 12, height = 6, dpi = 300)

# 3. Porcentaje de G>T por posición (Top 15)
top_15_percentage <- head(position_comparison, 15)
p3 <- ggplot(top_15_percentage, aes(x = position, y = gt_percentage, fill = gt_percentage)) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = paste0(gt_percentage, "%")), 
            vjust = -0.5, size = 3) +
  labs(title = "Porcentaje de Mutaciones G>T por Posición (Top 15)",
       x = "Posición en miRNA", y = "Porcentaje de G>T") +
  theme_minimal() +
  scale_fill_gradient(low = "lightyellow", high = "darkorange") +
  scale_x_continuous(breaks = top_15_percentage$position)

ggsave("figures/gt_porcentaje_por_posicion.png", p3, width = 12, height = 6, dpi = 300)

# =============================================================================
# RESUMEN
# =============================================================================

cat("\n=== PASO 2B COMPLETADO ===\n")
cat("Archivos generados:\n")
cat("  - 3 archivos CSV principales\n")
cat("  - 5 archivos CSV de miRNAs por posición\n")
cat("  - 3 archivos PNG con visualizaciones\n")
cat("\nResumen de análisis por posición:\n")
cat("  - Posición con más G>T:", gt_position_detailed$position[1], "(", gt_position_detailed$total_gt[1], "mutaciones)\n")
cat("  - Hotspots identificados:", nrow(hotspots), "posiciones\n")
cat("  - Posición con mayor % G>T:", position_comparison$position[which.max(position_comparison$gt_percentage)], 
    "(", max(position_comparison$gt_percentage), "%)\n")
cat("\nPaso 2B completado exitosamente!\n")








