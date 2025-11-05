# =============================================================================
# PASO 3: ANÁLISIS DETALLADO DE VAFs
# =============================================================================
# Autor: César Esparza
# Fecha: 2024
# Descripción: Análisis exhaustivo de Variant Allele Frequencies (VAFs)
# =============================================================================

# Cargar librerías
library(tidyverse)
library(ggplot2)

# Cargar configuración y funciones
source("../config_pipeline.R")
source("functions_pipeline.R")

cat("=== PASO 3: ANÁLISIS DETALLADO DE VAFs ===\n")
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

# Identificar columnas VAF
vaf_cols <- colnames(vaf_data)[str_detect(colnames(vaf_data), "^VAF_")]

# =============================================================================
# ANÁLISIS GENERAL DE VAFs
# =============================================================================

cat("Analizando VAFs en general...\n")

# Estadísticas generales de VAFs
vaf_general_stats <- vaf_data %>%
  select(all_of(vaf_cols)) %>%
  summarise(
    vaf_mean = mean(as.numeric(unlist(.)), na.rm = TRUE),
    vaf_median = median(as.numeric(unlist(.)), na.rm = TRUE),
    vaf_max = max(as.numeric(unlist(.)), na.rm = TRUE),
    vaf_min = min(as.numeric(unlist(.)), na.rm = TRUE),
    vaf_std = sd(as.numeric(unlist(.)), na.rm = TRUE),
    total_vafs = length(unlist(.)[!is.na(unlist(.))]),
    vafs_gt_50 = sum(as.numeric(unlist(.)) > 0.5, na.rm = TRUE),
    vafs_gt_10 = sum(as.numeric(unlist(.)) > 0.1, na.rm = TRUE),
    vafs_gt_5 = sum(as.numeric(unlist(.)) > 0.05, na.rm = TRUE),
    vafs_gt_1 = sum(as.numeric(unlist(.)) > 0.01, na.rm = TRUE)
  ) %>%
  mutate(
    porcentaje_gt_50 = round(vafs_gt_50 / total_vafs * 100, 2),
    porcentaje_gt_10 = round(vafs_gt_10 / total_vafs * 100, 2),
    porcentaje_gt_5 = round(vafs_gt_5 / total_vafs * 100, 2),
    porcentaje_gt_1 = round(vafs_gt_1 / total_vafs * 100, 2)
  )

write_csv(vaf_general_stats, "tables/paso3_estadisticas_vaf_generales.csv")

# =============================================================================
# ANÁLISIS DE DISTRIBUCIÓN DE VAFs POR CATEGORÍAS
# =============================================================================

cat("Analizando distribución de VAFs por categorías...\n")

# Crear categorías de VAF
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

# Análisis por categorías
vaf_category_analysis <- vaf_distribution %>%
  count(vaf_category) %>%
  mutate(
    porcentaje = round(n / sum(n) * 100, 2),
    categoria_orden = case_when(
      vaf_category == "0-1%" ~ 1,
      vaf_category == "1-5%" ~ 2,
      vaf_category == "5-10%" ~ 3,
      vaf_category == "10-20%" ~ 4,
      vaf_category == "20-50%" ~ 5,
      vaf_category == ">50%" ~ 6
    )
  ) %>%
  arrange(categoria_orden)

write_csv(vaf_category_analysis, "tables/paso3_distribucion_categorias_vaf.csv")

# =============================================================================
# ANÁLISIS DE VAFs POR MUESTRA
# =============================================================================

cat("Analizando VAFs por muestra...\n")

# Estadísticas por muestra
vaf_sample_stats <- vaf_data %>%
  select(all_of(vaf_cols)) %>%
  summarise(across(everything(), list(
    mean = ~mean(as.numeric(.x), na.rm = TRUE),
    median = ~median(as.numeric(.x), na.rm = TRUE),
    max = ~max(as.numeric(.x), na.rm = TRUE),
    n_gt_50 = ~sum(as.numeric(.x) > 0.5, na.rm = TRUE),
    n_gt_10 = ~sum(as.numeric(.x) > 0.1, na.rm = TRUE),
    n_gt_5 = ~sum(as.numeric(.x) > 0.05, na.rm = TRUE),
    n_gt_1 = ~sum(as.numeric(.x) > 0.01, na.rm = TRUE)
  ))) %>%
  pivot_longer(everything(), names_to = "sample_stat", values_to = "value") %>%
  separate(sample_stat, into = c("sample", "stat"), sep = "_", extra = "merge") %>%
  pivot_wider(names_from = stat, values_from = value) %>%
  mutate(sample = str_remove(sample, "VAF_"))

write_csv(vaf_sample_stats, "tables/paso3_estadisticas_vaf_por_muestra.csv")

# =============================================================================
# ANÁLISIS DE VAFs POR TIPO DE MUTACIÓN
# =============================================================================

cat("Analizando VAFs por tipo de mutación...\n")

# Clasificar mutaciones y calcular VAFs promedio por tipo
vaf_by_mutation_type <- vaf_data %>%
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
  select(mutation_type, all_of(vaf_cols)) %>%
  group_by(mutation_type) %>%
  summarise(
    n_mutations = n(),
    vaf_mean = mean(as.numeric(unlist(select(., -mutation_type))), na.rm = TRUE),
    vaf_median = median(as.numeric(unlist(select(., -mutation_type))), na.rm = TRUE),
    vaf_max = max(as.numeric(unlist(select(., -mutation_type))), na.rm = TRUE),
    vaf_std = sd(as.numeric(unlist(select(., -mutation_type))), na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(vaf_mean))

write_csv(vaf_by_mutation_type, "tables/paso3_vafs_por_tipo_mutacion.csv")

# =============================================================================
# ANÁLISIS DE VAFs EN MUTACIONES G>T ESPECÍFICAMENTE
# =============================================================================

cat("Analizando VAFs en mutaciones G>T específicamente...\n")

# VAFs específicas para mutaciones G>T
gt_vaf_analysis <- vaf_data %>%
  filter(grepl(":GT", `pos:mut`)) %>%
  select(all_of(vaf_cols)) %>%
  summarise(
    n_gt_mutations = n(),
    vaf_mean = mean(as.numeric(unlist(.)), na.rm = TRUE),
    vaf_median = median(as.numeric(unlist(.)), na.rm = TRUE),
    vaf_max = max(as.numeric(unlist(.)), na.rm = TRUE),
    vaf_min = min(as.numeric(unlist(.)), na.rm = TRUE),
    vaf_std = sd(as.numeric(unlist(.)), na.rm = TRUE),
    vafs_gt_50 = sum(as.numeric(unlist(.)) > 0.5, na.rm = TRUE),
    vafs_gt_10 = sum(as.numeric(unlist(.)) > 0.1, na.rm = TRUE),
    vafs_gt_5 = sum(as.numeric(unlist(.)) > 0.05, na.rm = TRUE),
    vafs_gt_1 = sum(as.numeric(unlist(.)) > 0.01, na.rm = TRUE)
  ) %>%
  mutate(
    total_vafs = n_gt_mutations * length(vaf_cols),
    porcentaje_gt_50 = round(vafs_gt_50 / total_vafs * 100, 2),
    porcentaje_gt_10 = round(vafs_gt_10 / total_vafs * 100, 2),
    porcentaje_gt_5 = round(vafs_gt_5 / total_vafs * 100, 2),
    porcentaje_gt_1 = round(vafs_gt_1 / total_vafs * 100, 2)
  )

write_csv(gt_vaf_analysis, "tables/paso3_vafs_gt_especificas.csv")

# =============================================================================
# ANÁLISIS DEL IMPACTO DEL FILTRADO
# =============================================================================

cat("Analizando el impacto del filtrado VAF > 50%...\n")

# Comparar antes y después del filtrado
filtrado_impact <- data.frame(
  Metrica = c("Total VAFs originales", "VAFs > 50% (filtradas)", "VAFs restantes", 
              "Porcentaje filtrado", "NaNs generados", "Promedio NaNs por muestra"),
  Valor = c(
    vaf_general_stats$total_vafs,
    vaf_general_stats$vafs_gt_50,
    vaf_general_stats$total_vafs - vaf_general_stats$vafs_gt_50,
    vaf_general_stats$porcentaje_gt_50,
    210118,  # Del output anterior
    506.31   # Del output anterior
  )
)

write_csv(filtrado_impact, "tables/paso3_impacto_filtrado.csv")

# =============================================================================
# GENERACIÓN DE VISUALIZACIONES
# =============================================================================

cat("Generando visualizaciones del paso 3...\n")

# 1. Distribución de VAFs por categoría
p1 <- ggplot(vaf_category_analysis, aes(x = reorder(vaf_category, categoria_orden), y = n, fill = vaf_category)) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = paste0(n, "\n(", porcentaje, "%)")), 
            vjust = -0.5, size = 3) +
  labs(title = "Distribución de VAFs por Categoría",
       x = "Categoría de VAF", y = "Número de VAFs") +
  theme_minimal() +
  theme(legend.position = "none") +
  scale_fill_brewer(palette = "Blues")

ggsave("figures/paso3_distribucion_categorias_vaf.png", p1, width = 10, height = 6, dpi = 300)

# 2. Histograma de VAFs
vaf_values <- as.numeric(unlist(vaf_data[, vaf_cols]))
vaf_values <- vaf_values[!is.na(vaf_values) & vaf_values > 0]

p2 <- ggplot(data.frame(VAF = vaf_values), aes(x = VAF)) +
  geom_histogram(bins = 50, fill = "lightblue", alpha = 0.7, color = "black") +
  geom_vline(xintercept = 0.5, color = "red", linetype = "dashed", linewidth = 1) +
  labs(title = "Distribución de VAFs",
       x = "Variant Allele Frequency (VAF)", y = "Frecuencia") +
  theme_minimal() +
  scale_x_continuous(limits = c(0, 1))

ggsave("figures/paso3_histograma_vafs.png", p2, width = 10, height = 6, dpi = 300)

# 3. VAFs promedio por tipo de mutación
p3 <- ggplot(vaf_by_mutation_type, aes(x = reorder(mutation_type, vaf_mean), y = vaf_mean, fill = mutation_type)) +
  geom_col(alpha = 0.8) +
  coord_flip() +
  geom_text(aes(label = paste0(round(vaf_mean, 3), "\n(n=", n_mutations, ")")), 
            hjust = -0.1, size = 3) +
  labs(title = "VAF Promedio por Tipo de Mutación",
       x = "Tipo de Mutación", y = "VAF Promedio") +
  theme_minimal() +
  theme(legend.position = "none") +
  scale_fill_brewer(palette = "Set3")

ggsave("figures/paso3_vafs_por_tipo_mutacion.png", p3, width = 12, height = 8, dpi = 300)

# 4. Top 20 muestras con más VAFs > 50%
top_samples_high_vaf <- vaf_sample_stats %>%
  arrange(desc(n_gt_50)) %>%
  head(20)

p4 <- ggplot(top_samples_high_vaf, aes(x = reorder(sample, n_gt_50), y = n_gt_50, fill = n_gt_50)) +
  geom_col(alpha = 0.8) +
  coord_flip() +
  labs(title = "Top 20 Muestras con más VAFs > 50%",
       x = "Muestra", y = "Número de VAFs > 50%") +
  theme_minimal() +
  theme(axis.text.y = element_text(size = 6)) +
  scale_fill_gradient(low = "lightcoral", high = "darkred")

ggsave("figures/paso3_muestras_altas_vafs.png", p4, width = 12, height = 8, dpi = 300)

# =============================================================================
# RESUMEN DEL PASO 3
# =============================================================================

cat("\n=== PASO 3 COMPLETADO ===\n")
cat("Archivos generados:\n")
cat("  - Tablas: 6 archivos CSV\n")
cat("  - Figuras: 4 archivos PNG\n")
cat("\nResumen de VAFs:\n")
print(vaf_general_stats)
cat("\nResumen por categorías:\n")
print(vaf_category_analysis)
cat("\nPaso 3 completado exitosamente!\n")








