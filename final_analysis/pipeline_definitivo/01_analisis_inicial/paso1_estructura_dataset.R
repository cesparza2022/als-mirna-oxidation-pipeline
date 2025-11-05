# =============================================================================
# PASO 1: ANÁLISIS DETALLADO DE ESTRUCTURA DEL DATASET
# =============================================================================
# Autor: César Esparza
# Fecha: 2024
# Descripción: Análisis exhaustivo de la estructura del dataset después de transformaciones
# =============================================================================

# Cargar librerías
library(tidyverse)
library(ggplot2)

# Cargar configuración y funciones
source("../config_pipeline.R")
source("functions_pipeline.R")

cat("=== PASO 1: ANÁLISIS DE ESTRUCTURA DEL DATASET ===\n")
cat("Fecha:", Sys.time(), "\n\n")

# Crear directorios de salida
dir.create("figures", showWarnings = FALSE)
dir.create("tables", showWarnings = FALSE)

# =============================================================================
# CARGAR Y PROCESAR DATOS
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
# ANÁLISIS DE TRANSFORMACIONES
# =============================================================================

cat("Analizando transformaciones del dataset...\n")

# Calcular split data para comparación
split_data_temp <- raw_data %>% 
  separate_rows(`pos:mut`, sep = ",") %>% 
  mutate(`pos:mut` = str_trim(`pos:mut`))

# Crear tabla de transformaciones
transformacion_stats <- data.frame(
  Transformacion = c("Dataset original", "Despues split", "Despues collapse", 
                     "Despues calculo VAFs", "Despues filtrado VAF > 50%"),
  Filas = c(nrow(raw_data), 
            nrow(split_data_temp),
            nrow(processed_data),
            nrow(vaf_data),
            nrow(filtered_data)),
  Columnas = c(ncol(raw_data), ncol(raw_data), ncol(processed_data), ncol(vaf_data), ncol(filtered_data)),
  SNVs_unicos = c(nrow(raw_data), 
                  nrow(split_data_temp),
                  nrow(processed_data),
                  nrow(vaf_data),
                  nrow(filtered_data)),
  miRNAs_unicos = c(length(unique(raw_data$`miRNA name`)),
                    length(unique(split_data_temp$`miRNA name`)),
                    length(unique(processed_data$`miRNA name`)),
                    length(unique(vaf_data$`miRNA name`)),
                    length(unique(filtered_data$`miRNA name`)))
)

write_csv(transformacion_stats, "tables/paso1_transformaciones.csv")

# =============================================================================
# ANÁLISIS DETALLADO DE miRNAs
# =============================================================================

cat("Analizando miRNAs en detalle...\n")

# Análisis por miRNA
mirna_analysis <- processed_data %>%
  group_by(`miRNA name`) %>%
  summarise(
    total_snvs = n(),
    posiciones_unicas = n_distinct(str_extract(`pos:mut`, "^\\d+")),
    mutaciones_unicas = n_distinct(`pos:mut`),
    gt_mutations = sum(grepl(":GT", `pos:mut`)),
    gt_percentage = round(sum(grepl(":GT", `pos:mut`)) / n() * 100, 2),
    .groups = "drop"
  ) %>%
  arrange(desc(total_snvs))

write_csv(mirna_analysis, "tables/paso1_analisis_mirnas.csv")

# =============================================================================
# ANÁLISIS DETALLADO DE POSICIONES
# =============================================================================

cat("Analizando posiciones en detalle...\n")

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

write_csv(position_analysis, "tables/paso1_analisis_posiciones.csv")

# =============================================================================
# ANÁLISIS DE REGIONES FUNCIONALES
# =============================================================================

cat("Analizando regiones funcionales...\n")

# Definir regiones funcionales
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
  ) %>%
  mutate(porcentaje_total = round(total_snvs / sum(total_snvs) * 100, 2))

write_csv(region_analysis, "tables/paso1_analisis_regiones.csv")

# =============================================================================
# GENERACIÓN DE VISUALIZACIONES
# =============================================================================

cat("Generando visualizaciones del paso 1...\n")

# 1. Evolución del dataset
p1 <- ggplot(transformacion_stats, aes(x = Transformacion, y = Filas, fill = Transformacion)) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = paste0(Filas, "\n(", miRNAs_unicos, " miRNAs)")), 
            vjust = -0.5, size = 3) +
  labs(title = "Evolución del Dataset a través de las Transformaciones",
       x = "Transformación", y = "Número de Filas") +
  theme_minimal() +
  theme(legend.position = "none", axis.text.x = element_text(angle = 45, hjust = 1)) +
  scale_fill_brewer(palette = "Set2")

ggsave("figures/paso1_evolucion_dataset.png", p1, width = 12, height = 8, dpi = 300)

# 2. Distribución por regiones funcionales
p2 <- ggplot(region_analysis, aes(x = region, y = total_snvs, fill = region)) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = paste0(total_snvs, "\n(", porcentaje_total, "%)")), 
            vjust = -0.5, size = 4) +
  labs(title = "Distribución de SNVs por Región Funcional",
       x = "Región", y = "Número de SNVs") +
  theme_minimal() +
  theme(legend.position = "none") +
  scale_fill_brewer(palette = "Set1")

ggsave("figures/paso1_snvs_por_region.png", p2, width = 10, height = 6, dpi = 300)

# 3. Top 15 miRNAs con más SNVs
top_mirnas <- head(mirna_analysis, 15)
p3 <- ggplot(top_mirnas, aes(x = reorder(`miRNA name`, total_snvs), y = total_snvs, fill = total_snvs)) +
  geom_col(alpha = 0.8) +
  coord_flip() +
  labs(title = "Top 15 miRNAs con más SNVs",
       x = "miRNA", y = "Número de SNVs") +
  theme_minimal() +
  theme(axis.text.y = element_text(size = 8)) +
  scale_fill_gradient(low = "lightblue", high = "darkblue")

ggsave("figures/paso1_top_mirnas.png", p3, width = 10, height = 8, dpi = 300)

# 4. Top 15 posiciones más mutadas
top_positions <- head(position_analysis, 15)
p4 <- ggplot(top_positions, aes(x = position, y = total_snvs, fill = total_snvs)) +
  geom_col(alpha = 0.8) +
  labs(title = "Top 15 Posiciones más Mutadas en miRNAs",
       x = "Posición en miRNA", y = "Número de SNVs") +
  theme_minimal() +
  scale_fill_gradient(low = "lightcoral", high = "darkred") +
  scale_x_continuous(breaks = top_positions$position)

ggsave("figures/paso1_top_posiciones.png", p4, width = 12, height = 6, dpi = 300)

# =============================================================================
# RESUMEN DEL PASO 1
# =============================================================================

cat("\n=== PASO 1 COMPLETADO ===\n")
cat("Archivos generados:\n")
cat("  - Tablas: 4 archivos CSV\n")
cat("  - Figuras: 4 archivos PNG\n")
cat("\nResumen de transformaciones:\n")
print(transformacion_stats)
cat("\nResumen de regiones:\n")
print(region_analysis)
cat("\nPaso 1 completado exitosamente!\n")








