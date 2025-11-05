# =============================================================================
# ANÁLISIS INICIAL DETALLADO Y PROFUNDO DEL DATASET
# =============================================================================
# Autor: César Esparza
# Fecha: 2024
# Descripción: Análisis exhaustivo del dataset después de split-collapse y VAFs
# =============================================================================

# Cargar librerías
library(tidyverse)
library(ggplot2)
library(gridExtra)
library(knitr)
library(DT)
library(reshape2)
library(RColorBrewer)
library(corrplot)

# Cargar configuración y funciones
source("../config_pipeline.R")
source("functions_pipeline.R")

cat("=== ANÁLISIS INICIAL DETALLADO Y PROFUNDO ===\n")
cat("Fecha:", Sys.time(), "\n\n")

# Crear directorios de salida
dir.create("figures", showWarnings = FALSE)
dir.create("tables", showWarnings = FALSE)

# =============================================================================
# PASO 1: CARGAR Y PROCESAR DATOS
# =============================================================================

cat("Cargando y procesando datos...\n")
raw_data <- read_tsv(config$data_paths$raw_data, 
                     col_types = cols(.default = "c"))

# Aplicar split-collapse
processed_data <- apply_split_collapse(raw_data)

# Calcular VAFs
vaf_data <- calculate_vafs(processed_data)

# Filtrar VAFs altas
filtered_data <- filter_high_vafs(vaf_data, threshold = 0.5)

# Identificar tipos de columnas
meta_cols <- c("miRNA name", "pos:mut")
count_cols <- names(raw_data)[!names(raw_data) %in% meta_cols]
total_cols <- names(raw_data)[grepl("\\(PM\\+1MM\\+2MM\\)$", names(raw_data))]
vaf_cols <- colnames(vaf_data)[str_detect(colnames(vaf_data), "^VAF_")]

# =============================================================================
# PASO 2: ANÁLISIS DETALLADO DE ESTRUCTURA DEL DATASET
# =============================================================================

cat("Realizando análisis detallado de estructura...\n")

# 1. Análisis de transformaciones
split_data_temp <- raw_data %>% separate_rows(`pos:mut`, sep = ",") %>% mutate(`pos:mut` = str_trim(`pos:mut`))

transformacion_stats <- data.frame(
  Transformacion = c("Dataset original", "Despues split", "Despues collapse", 
                     "Despues calculo VAFs", "Despues filtrado VAF > 50%"),
  Filas = c(nrow(raw_data), 
            nrow(split_data_temp),
            nrow(processed_data),
            nrow(vaf_data),
            nrow(filtered_data)),
  Columnas = c(ncol(raw_data), ncol(raw_data), ncol(processed_data), ncol(vaf_data), ncol(filtered_data))
)

write_csv(transformacion_stats, "tables/01_analisis_transformaciones.csv")

# 2. Análisis de miRNAs únicos
mirna_analysis <- processed_data %>%
  group_by(`miRNA name`) %>%
  summarise(
    total_snvs = n(),
    posiciones_unicas = n_distinct(str_extract(`pos:mut`, "^\\d+")),
    mutaciones_unicas = n_distinct(`pos:mut`),
    .groups = "drop"
  ) %>%
  arrange(desc(total_snvs))

write_csv(mirna_analysis, "tables/02_analisis_mirnas.csv")

# 3. Análisis de posiciones
position_analysis <- processed_data %>%
  mutate(position = as.numeric(str_extract(`pos:mut`, "^\\d+"))) %>%
  filter(!is.na(position)) %>%
  group_by(position) %>%
  summarise(
    total_snvs = n(),
    mirnas_unicos = n_distinct(`miRNA name`),
    mutaciones_unicas = n_distinct(`pos:mut`),
    .groups = "drop"
  ) %>%
  arrange(desc(total_snvs))

write_csv(position_analysis, "tables/03_analisis_posiciones.csv")

# =============================================================================
# PASO 3: ANÁLISIS PROFUNDO DE MUTACIONES G>T (OXIDACIÓN)
# =============================================================================

cat("Realizando análisis profundo de mutaciones G>T...\n")

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

# 2. Análisis detallado de G>T por región
gt_region_analysis <- gt_mutations %>%
  group_by(region) %>%
  summarise(
    total_gt = n(),
    mirnas_afectados = n_distinct(`miRNA name`),
    posiciones_unicas = n_distinct(position),
    .groups = "drop"
  ) %>%
  mutate(porcentaje = round(total_gt / sum(total_gt) * 100, 2))

write_csv(gt_region_analysis, "tables/04_analisis_gt_por_region.csv")

# 3. Análisis de G>T por posición específica
gt_position_analysis <- gt_mutations %>%
  group_by(position) %>%
  summarise(
    total_gt = n(),
    mirnas_afectados = n_distinct(`miRNA name`),
    .groups = "drop"
  ) %>%
  arrange(desc(total_gt))

write_csv(gt_position_analysis, "tables/05_analisis_gt_por_posicion.csv")

# 4. Comparación G>T vs otras mutaciones
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

mutation_type_analysis <- all_mutations %>%
  group_by(mutation_type) %>%
  summarise(
    total = n(),
    porcentaje = round(n() / nrow(all_mutations) * 100, 2),
    .groups = "drop"
  ) %>%
  arrange(desc(total))

write_csv(mutation_type_analysis, "tables/06_analisis_tipos_mutacion.csv")

# =============================================================================
# PASO 4: ANÁLISIS DETALLADO DE VAFs
# =============================================================================

cat("Realizando análisis detallado de VAFs...\n")

# 1. Estadísticas descriptivas por muestra
vaf_sample_stats <- vaf_data %>%
  select(all_of(vaf_cols)) %>%
  summarise(across(everything(), list(
    mean = ~mean(as.numeric(.x), na.rm = TRUE),
    median = ~median(as.numeric(.x), na.rm = TRUE),
    sd = ~sd(as.numeric(.x), na.rm = TRUE),
    max = ~max(as.numeric(.x), na.rm = TRUE),
    min = ~min(as.numeric(.x), na.rm = TRUE),
    n_gt_50 = ~sum(as.numeric(.x) > 0.5, na.rm = TRUE)
  ))) %>%
  pivot_longer(everything(), names_to = "sample_stat", values_to = "value") %>%
  separate(sample_stat, into = c("sample", "stat"), sep = "_", extra = "merge") %>%
  pivot_wider(names_from = stat, values_from = value)

write_csv(vaf_sample_stats, "tables/07_estadisticas_vaf_por_muestra.csv")

# 2. Análisis de distribución de VAFs
vaf_distribution <- vaf_data %>%
  select(all_of(vaf_cols)) %>%
  pivot_longer(everything(), names_to = "sample", values_to = "vaf") %>%
  mutate(vaf = as.numeric(vaf)) %>%
  filter(!is.na(vaf) & vaf > 0) %>%
  mutate(
    vaf_category = case_when(
      vaf <= 0.01 ~ "0-1%",
      vaf <= 0.05 ~ "1-5%",
      vaf <= 0.1 ~ "5-10%",
      vaf <= 0.2 ~ "10-20%",
      vaf <= 0.5 ~ "20-50%",
      TRUE ~ ">50%"
    )
  )

vaf_category_analysis <- vaf_distribution %>%
  count(vaf_category) %>%
  mutate(porcentaje = round(n / sum(n) * 100, 2))

write_csv(vaf_category_analysis, "tables/08_distribucion_categorias_vaf.csv")

# =============================================================================
# PASO 5: ANÁLISIS COMPARATIVO ALS vs CONTROL
# =============================================================================

cat("Realizando análisis comparativo ALS vs Control...\n")

# 1. Identificar muestras por grupo
als_samples <- count_cols[str_detect(count_cols, "ALS")]
control_samples <- count_cols[str_detect(count_cols, "Control|control")]

if (length(als_samples) > 0 && length(control_samples) > 0) {
  
  # 2. Análisis de VAFs por grupo
  als_vaf_cols <- paste0("VAF_", als_samples)
  control_vaf_cols <- paste0("VAF_", control_samples)
  
  # Verificar que las columnas VAF existen
  als_vaf_cols <- als_vaf_cols[als_vaf_cols %in% vaf_cols]
  control_vaf_cols <- control_vaf_cols[control_vaf_cols %in% vaf_cols]
  
  # Calcular VAFs promedio por grupo
  vaf_data_grouped <- vaf_data %>%
    mutate(
      als_vaf_mean = rowMeans(select(., all_of(als_vaf_cols)), na.rm = TRUE),
      control_vaf_mean = rowMeans(select(., all_of(control_vaf_cols)), na.rm = TRUE),
      vaf_difference = als_vaf_mean - control_vaf_mean
    )
  
  # 3. Análisis de diferencias por tipo de mutación
  vaf_diff_analysis <- vaf_data_grouped %>%
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
    ) %>%
    group_by(mutation_type) %>%
    summarise(
      n_mutations = n(),
      als_vaf_avg = mean(als_vaf_mean, na.rm = TRUE),
      control_vaf_avg = mean(control_vaf_mean, na.rm = TRUE),
      vaf_diff_avg = mean(vaf_difference, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    arrange(desc(abs(vaf_diff_avg)))
  
  write_csv(vaf_diff_analysis, "tables/09_diferencias_vaf_als_control.csv")
  
  # 4. Análisis específico de G>T por grupo
  gt_als_control <- vaf_data_grouped %>%
    filter(grepl(":GT", `pos:mut`)) %>%
    summarise(
      n_gt_mutations = n(),
      als_gt_vaf_avg = mean(als_vaf_mean, na.rm = TRUE),
      control_gt_vaf_avg = mean(control_vaf_mean, na.rm = TRUE),
      gt_vaf_diff = mean(vaf_difference, na.rm = TRUE)
    )
  
  write_csv(gt_als_control, "tables/10_analisis_gt_als_control.csv")
}

# =============================================================================
# PASO 6: ANÁLISIS DE REGIONES FUNCIONALES
# =============================================================================

cat("Realizando análisis de regiones funcionales...\n")

# 1. Análisis detallado por región
region_analysis <- processed_data %>%
  mutate(
    position = as.numeric(str_extract(`pos:mut`, "^\\d+")),
    region = case_when(
      position >= 2 & position <= 8 ~ "Semilla",
      position >= 9 & position <= 15 ~ "Central",
      position >= 16 & position <= 22 ~ "3'",
      TRUE ~ "Otro"
    )
  ) %>%
  group_by(region) %>%
  summarise(
    total_snvs = n(),
    mirnas_afectados = n_distinct(`miRNA name`),
    posiciones_unicas = n_distinct(position),
    gt_mutations = sum(grepl(":GT", `pos:mut`)),
    gt_percentage = round(sum(grepl(":GT", `pos:mut`)) / n() * 100, 2),
    .groups = "drop"
  )

write_csv(region_analysis, "tables/11_analisis_regiones_funcionales.csv")

# 2. Análisis de G>T por región funcional
gt_region_detailed <- processed_data %>%
  filter(grepl(":GT", `pos:mut`)) %>%
  mutate(
    position = as.numeric(str_extract(`pos:mut`, "^\\d+")),
    region = case_when(
      position >= 2 & position <= 8 ~ "Semilla",
      position >= 9 & position <= 15 ~ "Central",
      position >= 16 & position <= 22 ~ "3'",
      TRUE ~ "Otro"
    )
  ) %>%
  group_by(region, position) %>%
  summarise(
    gt_count = n(),
    mirnas_afectados = n_distinct(`miRNA name`),
    .groups = "drop"
  ) %>%
  arrange(region, desc(gt_count))

write_csv(gt_region_detailed, "tables/12_analisis_gt_por_region_posicion.csv")

# =============================================================================
# PASO 7: GENERACIÓN DE VISUALIZACIONES DETALLADAS
# =============================================================================

cat("Generando visualizaciones detalladas...\n")

# 1. Distribución de tipos de mutación
p1 <- ggplot(mutation_type_analysis, aes(x = reorder(mutation_type, total), y = total, fill = mutation_type)) +
  geom_col(alpha = 0.8) +
  coord_flip() +
  labs(title = "Distribución de Tipos de Mutación",
       x = "Tipo de Mutación", y = "Número de SNVs") +
  theme_minimal() +
  theme(legend.position = "none") +
  scale_fill_brewer(palette = "Set3")

ggsave("figures/01_distribucion_tipos_mutacion.png", p1, width = 12, height = 8, dpi = 300)

# 2. Análisis de G>T por región
p2 <- ggplot(gt_region_analysis, aes(x = region, y = total_gt, fill = region)) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = paste0(total_gt, "\n(", porcentaje, "%)")), 
            vjust = -0.5, size = 3) +
  labs(title = "Distribución de Mutaciones G>T por Región Funcional",
       x = "Región", y = "Número de Mutaciones G>T") +
  theme_minimal() +
  theme(legend.position = "none") +
  scale_fill_brewer(palette = "Set2")

ggsave("figures/02_gt_por_region.png", p2, width = 10, height = 6, dpi = 300)

# 3. Distribución de VAFs por categoría
p3 <- ggplot(vaf_category_analysis, aes(x = reorder(vaf_category, n), y = n, fill = vaf_category)) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = paste0(n, "\n(", porcentaje, "%)")), 
            hjust = -0.1, size = 3) +
  coord_flip() +
  labs(title = "Distribución de VAFs por Categoría",
       x = "Categoría de VAF", y = "Número de VAFs") +
  theme_minimal() +
  theme(legend.position = "none") +
  scale_fill_brewer(palette = "Blues")

ggsave("figures/03_distribucion_categorias_vaf.png", p3, width = 10, height = 6, dpi = 300)

# 4. Análisis de regiones funcionales
p4 <- ggplot(region_analysis, aes(x = region, y = total_snvs, fill = region)) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = paste0(total_snvs, "\nGT: ", gt_mutations, " (", gt_percentage, "%)")), 
            vjust = -0.5, size = 3) +
  labs(title = "Distribución de SNVs por Región Funcional",
       x = "Región", y = "Número de SNVs") +
  theme_minimal() +
  theme(legend.position = "none") +
  scale_fill_brewer(palette = "Set1")

ggsave("figures/04_snvs_por_region_funcional.png", p4, width = 10, height = 6, dpi = 300)

# =============================================================================
# FINALIZACIÓN
# =============================================================================

cat("\n=== ANÁLISIS DETALLADO COMPLETADO ===\n")
cat("Figuras generadas en: figures/\n")
cat("Tablas generadas en: tables/\n")
cat("Total de archivos generados:\n")
cat("  - Figuras:", length(list.files("figures/")), "\n")
cat("  - Tablas:", length(list.files("tables/")), "\n")
cat("\nAnálisis inicial detallado completado exitosamente!\n")
