# =============================================================================
# PASO 2C: ANÁLISIS DE miRNAs CON MAYOR OXIDACIÓN
# =============================================================================
# Autor: César Esparza
# Fecha: 2024
# Descripción: Análisis de miRNAs con más mutaciones G>T y patrones de oxidación
# =============================================================================

# Cargar librerías
library(tidyverse)
library(ggplot2)

cat("=== PASO 2C: ANÁLISIS DE miRNAs CON MAYOR OXIDACIÓN ===\n")
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
# ANÁLISIS DE miRNAs CON MÁS MUTACIONES G>T
# =============================================================================

cat("\nAnalizando miRNAs con más mutaciones G>T...\n")

# Análisis por miRNA
mirna_gt_analysis <- gt_mutations %>%
  group_by(`miRNA name`) %>%
  summarise(
    total_gt = n(),
    posiciones_afectadas = n_distinct(position),
    regiones_afectadas = n_distinct(region),
    posiciones_unicas = list(unique(position)),
    .groups = "drop"
  ) %>%
  arrange(desc(total_gt))

cat("Top 15 miRNAs con más mutaciones G>T:\n")
print(head(mirna_gt_analysis, 15))

# =============================================================================
# ANÁLISIS DE PATRONES DE OXIDACIÓN
# =============================================================================

cat("\nAnalizando patrones de oxidación por miRNA...\n")

# Análisis de patrones (miRNAs con múltiples posiciones G>T)
multi_position_gt <- mirna_gt_analysis %>%
  filter(posiciones_afectadas > 1) %>%
  arrange(desc(total_gt))

cat("miRNAs con múltiples posiciones G>T:", nrow(multi_position_gt), "\n")
cat("Top 10 miRNAs con múltiples posiciones G>T:\n")
print(head(multi_position_gt, 10))

# =============================================================================
# ANÁLISIS POR REGIÓN DE OXIDACIÓN
# =============================================================================

cat("\nAnalizando distribución de G>T por región en miRNAs...\n")

# Análisis por región
mirna_region_gt <- gt_mutations %>%
  group_by(`miRNA name`, region) %>%
  summarise(
    gt_count = n(),
    .groups = "drop"
  ) %>%
  pivot_wider(names_from = region, values_from = gt_count, values_fill = 0) %>%
  mutate(
    total_gt = rowSums(select(., -`miRNA name`)),
    regiones_afectadas = rowSums(select(., -`miRNA name`) > 0)
  ) %>%
  arrange(desc(total_gt))

cat("Top 10 miRNAs con G>T por región:\n")
print(head(mirna_region_gt, 10))

# =============================================================================
# ANÁLISIS DE miRNAs CON OXIDACIÓN EN REGIÓN SEMILLA
# =============================================================================

cat("\nAnalizando miRNAs con oxidación en región semilla...\n")

# miRNAs con G>T en región semilla
semilla_gt <- gt_mutations %>%
  filter(region == "Semilla") %>%
  group_by(`miRNA name`) %>%
  summarise(
    gt_semilla = n(),
    posiciones_semilla = list(unique(position)),
    .groups = "drop"
  ) %>%
  arrange(desc(gt_semilla))

cat("miRNAs con G>T en región semilla:", nrow(semilla_gt), "\n")
cat("Top 10 miRNAs con más G>T en semilla:\n")
print(head(semilla_gt, 10))

# =============================================================================
# ANÁLISIS COMPARATIVO: G>T vs TOTAL SNVs POR miRNA
# =============================================================================

cat("\nComparando G>T vs total SNVs por miRNA...\n")

# Análisis comparativo
mirna_comparison <- processed_data %>%
  group_by(`miRNA name`) %>%
  summarise(
    total_snvs = n(),
    gt_mutations = sum(grepl(":GT", `pos:mut`)),
    gt_percentage = round(sum(grepl(":GT", `pos:mut`)) / n() * 100, 2),
    .groups = "drop"
  ) %>%
  filter(gt_mutations > 0) %>%
  arrange(desc(gt_mutations))

cat("Top 15 miRNAs con más mutaciones G>T (comparativo):\n")
print(head(mirna_comparison, 15))

# =============================================================================
# ANÁLISIS DE miRNAs CON ALTO PORCENTAJE DE G>T
# =============================================================================

cat("\nIdentificando miRNAs con alto porcentaje de G>T...\n")

# miRNAs con alto porcentaje de G>T (≥20%)
high_gt_percentage <- mirna_comparison %>%
  filter(gt_percentage >= 20) %>%
  arrange(desc(gt_percentage))

cat("miRNAs con ≥20% de mutaciones G>T:", nrow(high_gt_percentage), "\n")
cat("Top 10 miRNAs con mayor porcentaje de G>T:\n")
print(head(high_gt_percentage, 10))

# =============================================================================
# GUARDAR RESULTADOS
# =============================================================================

cat("\nGuardando resultados...\n")
write_csv(mirna_gt_analysis, "tables/gt_analisis_mirnas_detallado.csv")
write_csv(multi_position_gt, "tables/gt_mirnas_multiples_posiciones.csv")
write_csv(mirna_region_gt, "tables/gt_mirnas_por_region.csv")
write_csv(semilla_gt, "tables/gt_mirnas_region_semilla.csv")
write_csv(mirna_comparison, "tables/gt_mirnas_comparativo.csv")
write_csv(high_gt_percentage, "tables/gt_mirnas_alto_porcentaje.csv")

# =============================================================================
# GENERAR VISUALIZACIONES
# =============================================================================

cat("\nGenerando visualizaciones...\n")

# 1. Top 15 miRNAs con más mutaciones G>T
top_15_mirnas <- head(mirna_gt_analysis, 15)
p1 <- ggplot(top_15_mirnas, aes(x = reorder(`miRNA name`, total_gt), y = total_gt, fill = total_gt)) +
  geom_col(alpha = 0.8) +
  coord_flip() +
  labs(title = "Top 15 miRNAs con más Mutaciones G>T",
       x = "miRNA", y = "Número de Mutaciones G>T") +
  theme_minimal() +
  theme(axis.text.y = element_text(size = 8)) +
  scale_fill_gradient(low = "lightgreen", high = "darkgreen")

ggsave("figures/gt_top_15_mirnas.png", p1, width = 12, height = 8, dpi = 300)

# 2. Distribución de posiciones afectadas por miRNA
p2 <- ggplot(mirna_gt_analysis, aes(x = posiciones_afectadas, fill = factor(posiciones_afectadas))) +
  geom_bar(alpha = 0.8) +
  labs(title = "Distribución de miRNAs por Número de Posiciones G>T Afectadas",
       x = "Número de Posiciones Afectadas", y = "Número de miRNAs") +
  theme_minimal() +
  theme(legend.position = "none") +
  scale_fill_brewer(palette = "Set3")

ggsave("figures/gt_distribucion_posiciones_afectadas.png", p2, width = 10, height = 6, dpi = 300)

# 3. Comparación G>T vs Total SNVs (Top 15)
top_15_comparison <- head(mirna_comparison, 15)
comparison_long <- top_15_comparison %>%
  select(`miRNA name`, gt_mutations, total_snvs) %>%
  mutate(other_mutations = total_snvs - gt_mutations) %>%
  select(`miRNA name`, gt_mutations, other_mutations) %>%
  pivot_longer(cols = c(gt_mutations, other_mutations), 
               names_to = "tipo", values_to = "cantidad") %>%
  mutate(tipo = ifelse(tipo == "gt_mutations", "G>T", "Otras"))

p3 <- ggplot(comparison_long, aes(x = reorder(`miRNA name`, cantidad), y = cantidad, fill = tipo)) +
  geom_col(position = "stack", alpha = 0.8) +
  coord_flip() +
  labs(title = "Comparación G>T vs Otras Mutaciones por miRNA (Top 15)",
       x = "miRNA", y = "Número de Mutaciones") +
  theme_minimal() +
  theme(axis.text.y = element_text(size = 8)) +
  scale_fill_manual(values = c("G>T" = "darkgreen", "Otras" = "lightblue"))

ggsave("figures/gt_comparacion_mirnas.png", p3, width = 12, height = 8, dpi = 300)

# 4. miRNAs con alto porcentaje de G>T
if (nrow(high_gt_percentage) > 0) {
  p4 <- ggplot(high_gt_percentage, aes(x = reorder(`miRNA name`, gt_percentage), y = gt_percentage, fill = gt_percentage)) +
    geom_col(alpha = 0.8) +
    coord_flip() +
    labs(title = "miRNAs con Alto Porcentaje de Mutaciones G>T (≥20%)",
         x = "miRNA", y = "Porcentaje de Mutaciones G>T") +
    theme_minimal() +
    theme(axis.text.y = element_text(size = 8)) +
    scale_fill_gradient(low = "lightyellow", high = "darkorange")
  
  ggsave("figures/gt_mirnas_alto_porcentaje.png", p4, width = 12, height = 8, dpi = 300)
}

# =============================================================================
# RESUMEN
# =============================================================================

cat("\n=== PASO 2C COMPLETADO ===\n")
cat("Archivos generados:\n")
cat("  - 6 archivos CSV con análisis\n")
cat("  - 4 archivos PNG con visualizaciones\n")
cat("\nResumen de miRNAs con oxidación:\n")
cat("  - miRNA con más G>T:", mirna_gt_analysis$`miRNA name`[1], "(", mirna_gt_analysis$total_gt[1], "mutaciones)\n")
cat("  - miRNAs con múltiples posiciones G>T:", nrow(multi_position_gt), "\n")
cat("  - miRNAs con G>T en semilla:", nrow(semilla_gt), "\n")
cat("  - miRNAs con ≥20% G>T:", nrow(high_gt_percentage), "\n")
cat("\nPaso 2C completado exitosamente!\n")








