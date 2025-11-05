# =============================================================================
# PASO 2: ANÁLISIS PROFUNDO DE MUTACIONES G>T (OXIDACIÓN)
# =============================================================================
# Autor: César Esparza
# Fecha: 2024
# Descripción: Análisis exhaustivo de mutaciones G>T como biomarcadores de daño oxidativo
# =============================================================================

# Cargar librerías
library(tidyverse)
library(ggplot2)

# Cargar configuración y funciones
source("../config_pipeline.R")
source("functions_pipeline.R")

cat("=== PASO 2: ANÁLISIS PROFUNDO DE MUTACIONES G>T (OXIDACIÓN) ===\n")
cat("Fecha:", Sys.time(), "\n\n")

# =============================================================================
# CARGAR Y PROCESAR DATOS
# =============================================================================

cat("Cargando y procesando datos...\n")
raw_data <- read_tsv(config$data_paths$raw_data, 
                     col_types = cols(.default = "c"))

# Aplicar transformaciones
processed_data <- apply_split_collapse(raw_data)
vaf_data <- calculate_vafs(processed_data)
filtered_data <- filter_high_vafs(vaf_data, threshold = 0.5)

# =============================================================================
# ANÁLISIS DE MUTACIONES G>T
# =============================================================================

cat("Analizando mutaciones G>T en detalle...\n")

# 1. Identificar todas las mutaciones G>T
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

# Estadísticas generales de G>T
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

write_csv(gt_general_stats, "tables/paso2_estadisticas_gt_generales.csv")

# =============================================================================
# ANÁLISIS DE G>T POR REGIÓN FUNCIONAL
# =============================================================================

cat("Analizando G>T por región funcional...\n")

# Análisis detallado por región
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

write_csv(gt_region_analysis, "tables/paso2_gt_por_region.csv")

# Análisis por posición específica dentro de cada región
gt_position_region <- gt_mutations %>%
  group_by(region, position) %>%
  summarise(
    gt_count = n(),
    mirnas_afectados = n_distinct(`miRNA name`),
    .groups = "drop"
  ) %>%
  arrange(region, desc(gt_count))

write_csv(gt_position_region, "tables/paso2_gt_por_region_posicion.csv")

# =============================================================================
# ANÁLISIS DE G>T POR POSICIÓN ESPECÍFICA
# =============================================================================

cat("Analizando G>T por posición específica...\n")

# Análisis por posición (todas las regiones)
gt_position_analysis <- gt_mutations %>%
  group_by(position) %>%
  summarise(
    total_gt = n(),
    mirnas_afectados = n_distinct(`miRNA name`),
    regiones_afectadas = n_distinct(region),
    porcentaje_gt = round(n() / nrow(gt_mutations) * 100, 2),
    .groups = "drop"
  ) %>%
  arrange(desc(total_gt))

write_csv(gt_position_analysis, "tables/paso2_gt_por_posicion.csv")

# =============================================================================
# ANÁLISIS DE miRNAs CON MÁS MUTACIONES G>T
# =============================================================================

cat("Analizando miRNAs con más mutaciones G>T...\n")

# Top miRNAs con más mutaciones G>T
gt_mirna_analysis <- gt_mutations %>%
  group_by(`miRNA name`) %>%
  summarise(
    total_gt = n(),
    posiciones_afectadas = n_distinct(position),
    regiones_afectadas = n_distinct(region),
    gt_percentage = round(n() / nrow(gt_mutations) * 100, 2),
    .groups = "drop"
  ) %>%
  arrange(desc(total_gt))

write_csv(gt_mirna_analysis, "tables/paso2_gt_por_mirna.csv")

# =============================================================================
# COMPARACIÓN G>T vs OTRAS MUTACIONES
# =============================================================================

cat("Comparando G>T con otras mutaciones...\n")

# Clasificar todas las mutaciones
all_mutations <- processed_data %>%
  mutate(
    mutation_type = case_when(
      grepl(":GT", `pos:mut`) ~ "G>T",
      grepl(":AT", `pos:mut`) ~ "A>T",
      grepl(":CT", `pos:mut`) ~ "C>T",
      grepl(":GC", `pos:mut`) ~ "G>C",
      grepl(":AC", `pos:mut`) ~ "A>C",
      grepl(":AG", `pos:mut`) ~ "A>G",
      grepl(":CG", `pos:mut`) ~ "C>G",
      grepl(":GA", `pos:mut`) ~ "G>A",
      grepl(":CA", `pos:mut`) ~ "C>A",
      grepl(":TC", `pos:mut`) ~ "T>C",
      grepl(":TG", `pos:mut`) ~ "T>G",
      grepl(":TA", `pos:mut`) ~ "T>A",
      TRUE ~ "Otro"
    )
  )

# Análisis de tipos de mutación
mutation_type_analysis <- all_mutations %>%
  group_by(mutation_type) %>%
  summarise(
    total = n(),
    porcentaje = round(n() / nrow(all_mutations) * 100, 2),
    .groups = "drop"
  ) %>%
  arrange(desc(total))

write_csv(mutation_type_analysis, "tables/paso2_tipos_mutacion.csv")

# =============================================================================
# ANÁLISIS DE VAFs EN MUTACIONES G>T
# =============================================================================

cat("Analizando VAFs en mutaciones G>T...\n")

# Identificar columnas VAF
vaf_cols <- colnames(vaf_data)[str_detect(colnames(vaf_data), "^VAF_")]

# Calcular VAFs promedio para mutaciones G>T
gt_vaf_analysis <- vaf_data %>%
  filter(grepl(":GT", `pos:mut`)) %>%
  select(all_of(vaf_cols)) %>%
  summarise(
    vaf_mean = mean(as.numeric(unlist(.)), na.rm = TRUE),
    vaf_median = median(as.numeric(unlist(.)), na.rm = TRUE),
    vaf_max = max(as.numeric(unlist(.)), na.rm = TRUE),
    vaf_min = min(as.numeric(unlist(.)), na.rm = TRUE),
    vaf_std = sd(as.numeric(unlist(.)), na.rm = TRUE),
    n_vafs = length(unlist(.)[!is.na(unlist(.)) & unlist(.) > 0])
  )

write_csv(gt_vaf_analysis, "tables/paso2_vafs_gt.csv")

# =============================================================================
# GENERACIÓN DE VISUALIZACIONES
# =============================================================================

cat("Generando visualizaciones del paso 2...\n")

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

ggsave("figures/paso2_gt_por_region.png", p1, width = 10, height = 6, dpi = 300)

# 2. Top 15 posiciones con más mutaciones G>T
top_gt_positions <- head(gt_position_analysis, 15)
p2 <- ggplot(top_gt_positions, aes(x = position, y = total_gt, fill = total_gt)) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = paste0(total_gt, "\n(", porcentaje_gt, "%)")), 
            vjust = -0.5, size = 3) +
  labs(title = "Top 15 Posiciones con más Mutaciones G>T",
       x = "Posición en miRNA", y = "Número de Mutaciones G>T") +
  theme_minimal() +
  scale_fill_gradient(low = "lightgreen", high = "darkgreen") +
  scale_x_continuous(breaks = top_gt_positions$position)

ggsave("figures/paso2_gt_por_posicion.png", p2, width = 12, height = 6, dpi = 300)

# 3. Top 15 miRNAs con más mutaciones G>T
top_gt_mirnas <- head(gt_mirna_analysis, 15)
p3 <- ggplot(top_gt_mirnas, aes(x = reorder(`miRNA name`, total_gt), y = total_gt, fill = total_gt)) +
  geom_col(alpha = 0.8) +
  coord_flip() +
  geom_text(aes(label = paste0(total_gt, "\n(", gt_percentage, "%)")), 
            hjust = -0.1, size = 3) +
  labs(title = "Top 15 miRNAs con más Mutaciones G>T",
       x = "miRNA", y = "Número de Mutaciones G>T") +
  theme_minimal() +
  theme(axis.text.y = element_text(size = 8)) +
  scale_fill_gradient(low = "lightgreen", high = "darkgreen")

ggsave("figures/paso2_gt_por_mirna.png", p3, width = 10, height = 8, dpi = 300)

# 4. Comparación de tipos de mutación
p4 <- ggplot(mutation_type_analysis, aes(x = reorder(mutation_type, total), y = total, fill = mutation_type)) +
  geom_col(alpha = 0.8) +
  coord_flip() +
  geom_text(aes(label = paste0(total, "\n(", porcentaje, "%)")), 
            hjust = -0.1, size = 3) +
  labs(title = "Distribución de Tipos de Mutación",
       x = "Tipo de Mutación", y = "Número de SNVs") +
  theme_minimal() +
  theme(legend.position = "none") +
  scale_fill_brewer(palette = "Set3")

ggsave("figures/paso2_tipos_mutacion.png", p4, width = 12, height = 8, dpi = 300)

# =============================================================================
# RESUMEN DEL PASO 2
# =============================================================================

cat("\n=== PASO 2 COMPLETADO ===\n")
cat("Archivos generados:\n")
cat("  - Tablas: 6 archivos CSV\n")
cat("  - Figuras: 4 archivos PNG\n")
cat("\nResumen de mutaciones G>T:\n")
print(gt_general_stats)
cat("\nResumen por región:\n")
print(gt_region_analysis)
cat("\nPaso 2 completado exitosamente!\n")








