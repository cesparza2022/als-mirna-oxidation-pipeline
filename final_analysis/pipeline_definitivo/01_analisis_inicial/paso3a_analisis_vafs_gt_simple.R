# =============================================================================
# PASO 3A: ANÁLISIS DETALLADO DE VAFs EN MUTACIONES G>T (VERSIÓN SIMPLIFICADA)
# =============================================================================
# Autor: César Esparza
# Fecha: 2024
# Descripción: Análisis específico de VAFs en mutaciones G>T vs otras mutaciones
# =============================================================================

# Cargar librerías
library(tidyverse)
library(ggplot2)

cat("=== PASO 3A: ANÁLISIS DETALLADO DE VAFs EN MUTACIONES G>T ===\n")
cat("Fecha:", Sys.time(), "\n\n")

# =============================================================================
# CARGAR DATOS PROCESADOS
# =============================================================================

cat("Cargando datos procesados...\n")
vaf_data <- read_csv("tables/datos_con_vafs.csv")
filtered_data <- read_csv("tables/datos_filtrados_vaf.csv")
gt_mutations <- read_csv("tables/mutaciones_gt_detalladas.csv")

cat("Datos cargados:\n")
cat("  - Total SNVs con VAFs:", nrow(vaf_data), "\n")
cat("  - SNVs filtrados:", nrow(filtered_data), "\n")
cat("  - Mutaciones G>T:", nrow(gt_mutations), "\n")

# =============================================================================
# IDENTIFICAR COLUMNAS VAF
# =============================================================================

cat("\nIdentificando columnas VAF...\n")
vaf_cols <- colnames(vaf_data)[str_detect(colnames(vaf_data), "^VAF_")]
cat("Columnas VAF encontradas:", length(vaf_cols), "\n")

# =============================================================================
# ANÁLISIS SIMPLE DE VAFs EN MUTACIONES G>T
# =============================================================================

cat("\nAnalizando VAFs específicamente en mutaciones G>T...\n")

# Filtrar solo mutaciones G>T
gt_vaf_data <- vaf_data %>%
  filter(str_detect(`pos:mut`, ":GT"))

cat("Mutaciones G>T con VAFs:", nrow(gt_vaf_data), "\n")

# Calcular estadísticas simples para G>T
gt_vaf_summary <- gt_vaf_data %>%
  select(all_of(vaf_cols)) %>%
  summarise(
    mean_vaf = mean(as.matrix(.), na.rm = TRUE),
    median_vaf = median(as.matrix(.), na.rm = TRUE),
    max_vaf = max(as.matrix(.), na.rm = TRUE),
    min_vaf = min(as.matrix(.), na.rm = TRUE),
    sd_vaf = sd(as.matrix(.), na.rm = TRUE),
    total_values = sum(!is.na(as.matrix(.))),
    total_nas = sum(is.na(as.matrix(.)))
  )

cat("Resumen de VAFs en mutaciones G>T:\n")
print(gt_vaf_summary)

# =============================================================================
# COMPARACIÓN G>T vs OTRAS MUTACIONES
# =============================================================================

cat("\nComparando VAFs entre G>T y otras mutaciones...\n")

# Filtrar otras mutaciones (no G>T)
other_vaf_data <- vaf_data %>%
  filter(!str_detect(`pos:mut`, ":GT"))

cat("Otras mutaciones con VAFs:", nrow(other_vaf_data), "\n")

# Calcular estadísticas simples para otras mutaciones
other_vaf_summary <- other_vaf_data %>%
  select(all_of(vaf_cols)) %>%
  summarise(
    mean_vaf = mean(as.matrix(.), na.rm = TRUE),
    median_vaf = median(as.matrix(.), na.rm = TRUE),
    max_vaf = max(as.matrix(.), na.rm = TRUE),
    min_vaf = min(as.matrix(.), na.rm = TRUE),
    sd_vaf = sd(as.matrix(.), na.rm = TRUE),
    total_values = sum(!is.na(as.matrix(.))),
    total_nas = sum(is.na(as.matrix(.)))
  )

cat("Resumen de VAFs en otras mutaciones:\n")
print(other_vaf_summary)

# =============================================================================
# ANÁLISIS DE VAFs POR REGIÓN EN G>T
# =============================================================================

cat("\nAnalizando VAFs de G>T por región funcional...\n")

# Combinar datos G>T con información de región
gt_vaf_with_region <- gt_vaf_data %>%
  left_join(gt_mutations %>% select(`miRNA name`, `pos:mut`, region), 
            by = c("miRNA name", "pos:mut"))

# Análisis por región
gt_vaf_by_region <- gt_vaf_with_region %>%
  group_by(region) %>%
  summarise(
    n_mutations = n(),
    mean_vaf = mean(as.matrix(select(., all_of(vaf_cols))), na.rm = TRUE),
    median_vaf = median(as.matrix(select(., all_of(vaf_cols))), na.rm = TRUE),
    max_vaf = max(as.matrix(select(., all_of(vaf_cols))), na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(mean_vaf))

cat("VAFs de G>T por región:\n")
print(gt_vaf_by_region)

# =============================================================================
# ANÁLISIS DE VAFs POR POSICIÓN EN G>T
# =============================================================================

cat("\nAnalizando VAFs de G>T por posición...\n")

# Análisis por posición (top 10 posiciones con más G>T)
top_gt_positions <- gt_mutations %>%
  count(position, sort = TRUE) %>%
  head(10) %>%
  pull(position)

gt_vaf_by_position <- gt_vaf_with_region %>%
  filter(position %in% top_gt_positions) %>%
  group_by(position) %>%
  summarise(
    n_mutations = n(),
    mean_vaf = mean(as.matrix(select(., all_of(vaf_cols))), na.rm = TRUE),
    median_vaf = median(as.matrix(select(., all_of(vaf_cols))), na.rm = TRUE),
    max_vaf = max(as.matrix(select(., all_of(vaf_cols))), na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(mean_vaf))

cat("VAFs de G>T por posición (top 10):\n")
print(gt_vaf_by_position)

# =============================================================================
# ANÁLISIS DE IMPACTO DEL FILTRADO VAF > 50%
# =============================================================================

cat("\nAnalizando impacto del filtrado VAF > 50% en G>T...\n")

# Calcular NaNs generados por el filtrado para G>T
gt_before_filter <- gt_vaf_data %>%
  select(all_of(vaf_cols))

gt_after_filter <- filtered_data %>%
  filter(str_detect(`pos:mut`, ":GT")) %>%
  select(all_of(vaf_cols))

# Calcular NaNs generados
gt_nans_before <- sum(is.na(as.matrix(gt_before_filter)))
gt_nans_after <- sum(is.na(as.matrix(gt_after_filter)))
gt_nans_generated <- gt_nans_after - gt_nans_before
gt_total_values <- sum(!is.na(as.matrix(gt_before_filter)))
gt_percentage_filtered <- round(gt_nans_generated / gt_total_values * 100, 2)

cat("Impacto del filtrado en mutaciones G>T:\n")
cat("  - VAFs antes del filtrado:", gt_total_values, "\n")
cat("  - NaNs generados:", gt_nans_generated, "\n")
cat("  - Porcentaje filtrado:", gt_percentage_filtered, "%\n")

# =============================================================================
# GUARDAR RESULTADOS
# =============================================================================

cat("\nGuardando resultados...\n")

# Crear resúmenes para guardar
gt_summary_df <- data.frame(
  Metrica = c("Mean_VAF", "Median_VAF", "Max_VAF", "Min_VAF", "SD_VAF", "Total_Values", "Total_NaNs"),
  Valor = c(gt_vaf_summary$mean_vaf, gt_vaf_summary$median_vaf, gt_vaf_summary$max_vaf, 
            gt_vaf_summary$min_vaf, gt_vaf_summary$sd_vaf, gt_vaf_summary$total_values, gt_vaf_summary$total_nas)
)

other_summary_df <- data.frame(
  Metrica = c("Mean_VAF", "Median_VAF", "Max_VAF", "Min_VAF", "SD_VAF", "Total_Values", "Total_NaNs"),
  Valor = c(other_vaf_summary$mean_vaf, other_vaf_summary$median_vaf, other_vaf_summary$max_vaf, 
            other_vaf_summary$min_vaf, other_vaf_summary$sd_vaf, other_vaf_summary$total_values, other_vaf_summary$total_nas)
)

filtering_impact_df <- data.frame(
  Metrica = c("VAFs_antes_filtrado", "NaNs_generados", "Porcentaje_filtrado"),
  Valor = c(gt_total_values, gt_nans_generated, gt_percentage_filtered)
)

write_csv(gt_summary_df, "tables/gt_vaf_resumen_general.csv")
write_csv(other_summary_df, "tables/gt_vaf_resumen_otras_mutaciones.csv")
write_csv(gt_vaf_by_region, "tables/gt_vaf_por_region.csv")
write_csv(gt_vaf_by_position, "tables/gt_vaf_por_posicion.csv")
write_csv(filtering_impact_df, "tables/gt_impacto_filtrado_vaf.csv")

# =============================================================================
# GENERAR VISUALIZACIONES
# =============================================================================

cat("\nGenerando visualizaciones...\n")

# 1. Comparación de VAFs G>T vs Otras mutaciones
comparison_data <- data.frame(
  Tipo = c("G>T", "Otras"),
  Mean_VAF = c(gt_vaf_summary$mean_vaf, other_vaf_summary$mean_vaf),
  Median_VAF = c(gt_vaf_summary$median_vaf, other_vaf_summary$median_vaf),
  Max_VAF = c(gt_vaf_summary$max_vaf, other_vaf_summary$max_vaf)
)

p1 <- ggplot(comparison_data, aes(x = Tipo, y = Mean_VAF, fill = Tipo)) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = round(Mean_VAF, 4)), vjust = -0.5) +
  labs(title = "Comparación de VAFs Promedio: G>T vs Otras Mutaciones",
       x = "Tipo de Mutación", y = "VAF Promedio") +
  theme_minimal() +
  scale_fill_manual(values = c("G>T" = "darkgreen", "Otras" = "lightblue")) +
  theme(legend.position = "none")

ggsave("figures/gt_comparacion_vafs_tipo_mutacion.png", p1, width = 8, height = 6, dpi = 300)

# 2. VAFs de G>T por región
p2 <- ggplot(gt_vaf_by_region, aes(x = region, y = mean_vaf, fill = region)) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = round(mean_vaf, 4)), vjust = -0.5) +
  labs(title = "VAFs Promedio de Mutaciones G>T por Región Funcional",
       x = "Región Funcional", y = "VAF Promedio") +
  theme_minimal() +
  scale_fill_brewer(palette = "Set2") +
  theme(legend.position = "none")

ggsave("figures/gt_vafs_por_region.png", p2, width = 10, height = 6, dpi = 300)

# 3. VAFs de G>T por posición (top 10)
p3 <- ggplot(gt_vaf_by_position, aes(x = position, y = mean_vaf, fill = mean_vaf)) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = round(mean_vaf, 4)), vjust = -0.5, size = 3) +
  labs(title = "VAFs Promedio de Mutaciones G>T por Posición (Top 10)",
       x = "Posición en miRNA", y = "VAF Promedio") +
  theme_minimal() +
  scale_fill_gradient(low = "lightgreen", high = "darkgreen") +
  scale_x_continuous(breaks = gt_vaf_by_position$position)

ggsave("figures/gt_vafs_por_posicion.png", p3, width = 12, height = 6, dpi = 300)

# 4. Distribución de VAFs (histograma)
# Crear datos para histograma
gt_vaf_values <- gt_vaf_data %>%
  select(all_of(vaf_cols)) %>%
  pivot_longer(everything(), names_to = "sample", values_to = "vaf") %>%
  filter(!is.na(vaf)) %>%
  mutate(tipo = "G>T")

other_vaf_values <- other_vaf_data %>%
  select(all_of(vaf_cols)) %>%
  pivot_longer(everything(), names_to = "sample", values_to = "vaf") %>%
  filter(!is.na(vaf)) %>%
  mutate(tipo = "Otras")

# Combinar datos para histograma
hist_data <- bind_rows(gt_vaf_values, other_vaf_values)

p4 <- ggplot(hist_data, aes(x = vaf, fill = tipo)) +
  geom_histogram(alpha = 0.7, bins = 50, position = "identity") +
  labs(title = "Distribución de VAFs: G>T vs Otras Mutaciones",
       x = "VAF", y = "Frecuencia") +
  theme_minimal() +
  scale_fill_manual(values = c("G>T" = "darkgreen", "Otras" = "lightblue")) +
  facet_wrap(~tipo, scales = "free_y")

ggsave("figures/gt_distribucion_vafs_histograma.png", p4, width = 12, height = 6, dpi = 300)

# =============================================================================
# RESUMEN
# =============================================================================

cat("\n=== PASO 3A COMPLETADO ===\n")
cat("Archivos generados:\n")
cat("  - 5 archivos CSV con análisis de VAFs\n")
cat("  - 4 archivos PNG con visualizaciones\n")
cat("\nResumen de VAFs en mutaciones G>T:\n")
cat("  - VAF promedio G>T:", round(gt_vaf_summary$mean_vaf, 4), "\n")
cat("  - VAF promedio otras:", round(other_vaf_summary$mean_vaf, 4), "\n")
cat("  - Región con mayor VAF G>T:", gt_vaf_by_region$region[1], "\n")
cat("  - Posición con mayor VAF G>T:", gt_vaf_by_position$position[1], "\n")
cat("  - VAFs filtrados en G>T:", gt_percentage_filtered, "%\n")
cat("\nPaso 3A completado exitosamente!\n")








