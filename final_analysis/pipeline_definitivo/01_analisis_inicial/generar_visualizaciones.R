# =============================================================================
# GENERACIÓN DE VISUALIZACIONES Y TABLAS - ANÁLISIS INICIAL
# =============================================================================
# Autor: César Esparza
# Fecha: 2024
# Descripción: Genera todas las figuras y tablas para describir el dataset
# =============================================================================

# Cargar librerías
library(tidyverse)
library(ggplot2)
library(gridExtra)
library(knitr)
library(DT)
library(reshape2)
library(RColorBrewer)

# Cargar configuración y funciones
source("../config_pipeline.R")
source("functions_pipeline.R")

cat("=== GENERANDO VISUALIZACIONES Y TABLAS ===\n")
cat("Fecha:", Sys.time(), "\n\n")

# Crear directorios de salida
dir.create("figures", showWarnings = FALSE)
dir.create("tables", showWarnings = FALSE)

# =============================================================================
# PASO 1: CARGAR Y PROCESAR DATOS
# =============================================================================

cat("Cargando datos...\n")
raw_data <- read_tsv(config$data_paths$raw_data, 
                     col_types = cols(.default = "c"))

# Aplicar split-collapse
cat("Aplicando split-collapse...\n")
processed_data <- apply_split_collapse(raw_data)

# Calcular VAFs
cat("Calculando VAFs...\n")
vaf_data <- calculate_vafs(processed_data)

# Filtrar VAFs altas
cat("Filtrando VAFs > 50%...\n")
filtered_data <- filter_high_vafs(vaf_data, threshold = 0.5)

# =============================================================================
# PASO 2: ANÁLISIS DE ESTRUCTURA DEL DATASET
# =============================================================================

cat("Generando análisis de estructura...\n")

# Identificar tipos de columnas
meta_cols <- c("miRNA name", "pos:mut")
count_cols <- names(raw_data)[!names(raw_data) %in% meta_cols]
total_cols <- names(raw_data)[grepl("\\(PM\\+1MM\\+2MM\\)$", names(raw_data))]

# 1. Resumen general del dataset
summary_stats <- data.frame(
  Metrica = c("SNVs originales", "SNVs despues split-collapse", "miRNAs unicos", 
              "Muestras", "Columnas totales", "Columnas de cuentas", "Columnas de totales"),
  Valor = c(
    nrow(raw_data),
    nrow(processed_data),
    length(unique(processed_data$`miRNA name`)),
    length(count_cols),
    ncol(raw_data),
    length(count_cols),
    length(total_cols)
  )
)

# Guardar tabla
write_csv(summary_stats, "tables/01_resumen_general_dataset.csv")

# 2. Distribución de SNVs por miRNA
mirna_counts <- processed_data %>%
  count(`miRNA name`, sort = TRUE) %>%
  head(20)

# Gráfica de SNVs por miRNA (top 20)
p1 <- ggplot(mirna_counts, aes(x = reorder(`miRNA name`, n), y = n)) +
  geom_col(fill = "steelblue", alpha = 0.7) +
  coord_flip() +
  labs(title = "Top 20 miRNAs con más SNVs",
       x = "miRNA", y = "Número de SNVs") +
  theme_minimal() +
  theme(axis.text.y = element_text(size = 8))

ggsave("figures/01_snvs_por_mirna.png", p1, width = 10, height = 8, dpi = 300)

# 3. Distribución de posiciones mutadas
position_counts <- processed_data %>%
  mutate(position = as.numeric(str_extract(`pos:mut`, "^\\d+"))) %>%
  count(position, sort = TRUE) %>%
  head(20)

# Gráfica de posiciones más mutadas
p2 <- ggplot(position_counts, aes(x = position, y = n)) +
  geom_col(fill = "darkred", alpha = 0.7) +
  labs(title = "Top 20 posiciones más mutadas en miRNAs",
       x = "Posición en miRNA", y = "Número de SNVs") +
  theme_minimal() +
  scale_x_continuous(breaks = position_counts$position)

ggsave("figures/02_posiciones_mas_mutadas.png", p2, width = 10, height = 6, dpi = 300)

# =============================================================================
# PASO 3: ANÁLISIS DE MUTACIONES G>T
# =============================================================================

cat("Analizando mutaciones G>T...\n")

# Filtrar solo mutaciones G>T
gt_mutations <- processed_data[grepl(":GT", processed_data$`pos:mut`), ]

# Estadísticas de G>T
gt_stats <- data.frame(
  Métrica = c("Total SNVs", "SNVs G>T", "Porcentaje G>T", "miRNAs con G>T"),
  Valor = c(
    nrow(processed_data),
    nrow(gt_mutations),
    round(nrow(gt_mutations) / nrow(processed_data) * 100, 2),
    length(unique(gt_mutations$`miRNA name`))
  )
)

write_csv(gt_stats, "tables/02_estadisticas_GT.csv")

# Top miRNAs con más mutaciones G>T
gt_mirna_counts <- gt_mutations %>%
  count(`miRNA name`, sort = TRUE) %>%
  head(20)

# Gráfica de G>T por miRNA
p3 <- ggplot(gt_mirna_counts, aes(x = reorder(`miRNA name`, n), y = n)) +
  geom_col(fill = "orange", alpha = 0.7) +
  coord_flip() +
  labs(title = "Top 20 miRNAs con más mutaciones G>T",
       x = "miRNA", y = "Número de mutaciones G>T") +
  theme_minimal() +
  theme(axis.text.y = element_text(size = 8))

ggsave("figures/03_gt_por_mirna.png", p3, width = 10, height = 8, dpi = 300)

# =============================================================================
# PASO 4: ANÁLISIS DE VAFs
# =============================================================================

cat("Analizando VAFs...\n")

# Identificar columnas VAF
vaf_cols <- colnames(vaf_data)[str_detect(colnames(vaf_data), "^VAF_")]

# Calcular estadísticas de VAF
vaf_stats <- vaf_data %>%
  select(all_of(vaf_cols)) %>%
  summarise(
    VAF_media = mean(as.numeric(unlist(.)), na.rm = TRUE),
    VAF_mediana = median(as.numeric(unlist(.)), na.rm = TRUE),
    VAF_max = max(as.numeric(unlist(.)), na.rm = TRUE),
    VAF_min = min(as.numeric(unlist(.)), na.rm = TRUE),
    VAF_std = sd(as.numeric(unlist(.)), na.rm = TRUE)
  )

write_csv(vaf_stats, "tables/03_estadisticas_vaf.csv")

# Distribución de VAFs
vaf_values <- as.numeric(unlist(vaf_data[, vaf_cols]))
vaf_values <- vaf_values[!is.na(vaf_values) & vaf_values > 0]

# Histograma de VAFs
p4 <- ggplot(data.frame(VAF = vaf_values), aes(x = VAF)) +
  geom_histogram(bins = 50, fill = "lightblue", alpha = 0.7, color = "black") +
  geom_vline(xintercept = 0.5, color = "red", linetype = "dashed", size = 1) +
  labs(title = "Distribución de VAFs",
       x = "Variant Allele Frequency (VAF)", y = "Frecuencia") +
  theme_minimal() +
  scale_x_continuous(limits = c(0, 1))

ggsave("figures/04_distribucion_vafs.png", p4, width = 10, height = 6, dpi = 300)

# =============================================================================
# PASO 5: ANÁLISIS DE FILTRADO VAF > 50%
# =============================================================================

cat("Analizando filtrado VAF > 50%...\n")

# Contar NaNs por muestra
nan_counts <- filtered_data %>%
  select(all_of(vaf_cols)) %>%
  summarise(across(everything(), ~sum(is.na(.x)))) %>%
  pivot_longer(everything(), names_to = "Muestra", values_to = "NaNs") %>%
  mutate(Muestra = str_remove(Muestra, "VAF_"))

# Gráfica de NaNs por muestra
p5 <- ggplot(nan_counts, aes(x = reorder(Muestra, NaNs), y = NaNs)) +
  geom_col(fill = "red", alpha = 0.7) +
  coord_flip() +
  labs(title = "NaNs generados por filtrado VAF > 50%",
       x = "Muestra", y = "Número de NaNs") +
  theme_minimal() +
  theme(axis.text.y = element_text(size = 6))

ggsave("figures/05_nans_por_muestra.png", p5, width = 12, height = 8, dpi = 300)

# Estadísticas de filtrado
filtering_stats <- data.frame(
  Métrica = c("Total VAFs", "VAFs > 50%", "Porcentaje filtrado", "VAFs restantes"),
  Valor = c(
    length(vaf_values),
    sum(vaf_values > 0.5),
    round(sum(vaf_values > 0.5) / length(vaf_values) * 100, 2),
    sum(vaf_values <= 0.5)
  )
)

write_csv(filtering_stats, "tables/04_estadisticas_filtrado.csv")

# =============================================================================
# PASO 6: ANÁLISIS COMPARATIVO ALS vs CONTROL
# =============================================================================

cat("Generando análisis comparativo...\n")

# Identificar muestras ALS y Control (asumiendo que están en los nombres)
# Esto es un ejemplo - ajustar según la nomenclatura real
als_samples <- count_cols[str_detect(count_cols, "ALS|als")]
control_samples <- count_cols[str_detect(count_cols, "Control|control|CTRL|ctrl")]

if (length(als_samples) > 0 && length(control_samples) > 0) {
  
  # Calcular VAFs promedio por grupo
  als_vafs <- vaf_data %>%
    select(all_of(paste0("VAF_", als_samples))) %>%
    rowMeans(na.rm = TRUE)
  
  control_vafs <- vaf_data %>%
    select(all_of(paste0("VAF_", control_samples))) %>%
    rowMeans(na.rm = TRUE)
  
  # Crear dataframe para comparación
  comparison_data <- data.frame(
    Grupo = c(rep("ALS", length(als_vafs)), rep("Control", length(control_vafs))),
    VAF = c(als_vafs, control_vafs)
  )
  
  # Boxplot comparativo
  p6 <- ggplot(comparison_data, aes(x = Grupo, y = VAF, fill = Grupo)) +
    geom_boxplot(alpha = 0.7) +
    labs(title = "Comparación de VAFs: ALS vs Control",
         x = "Grupo", y = "VAF promedio") +
    theme_minimal() +
    scale_fill_brewer(palette = "Set2")
  
  ggsave("figures/06_comparacion_als_control.png", p6, width = 8, height = 6, dpi = 300)
  
  # Estadísticas comparativas
  comparison_stats <- comparison_data %>%
    group_by(Grupo) %>%
    summarise(
      n = n(),
      VAF_media = mean(VAF, na.rm = TRUE),
      VAF_mediana = median(VAF, na.rm = TRUE),
      VAF_std = sd(VAF, na.rm = TRUE)
    )
  
  write_csv(comparison_stats, "tables/05_comparacion_als_control.csv")
}

# =============================================================================
# PASO 7: ANÁLISIS DE REGIONES SEMILLA
# =============================================================================

cat("Analizando regiones semilla...\n")

# Definir regiones semilla (posiciones 2-8)
seed_data <- processed_data %>%
  mutate(position = as.numeric(str_extract(`pos:mut`, "^\\d+"))) %>%
  mutate(region = ifelse(position >= 2 & position <= 8, "Semilla", "No-semilla"))

# Contar SNVs por región
region_counts <- seed_data %>%
  count(region)

# Gráfica de SNVs por región
p7 <- ggplot(region_counts, aes(x = region, y = n, fill = region)) +
  geom_col(alpha = 0.7) +
  labs(title = "Distribución de SNVs por región",
       x = "Región", y = "Número de SNVs") +
  theme_minimal() +
  scale_fill_brewer(palette = "Set1") +
  theme(legend.position = "none")

ggsave("figures/07_snvs_por_region.png", p7, width = 8, height = 6, dpi = 300)

# Estadísticas de regiones
region_stats <- seed_data %>%
  group_by(region) %>%
  summarise(
    n = n(),
    porcentaje = round(n / nrow(seed_data) * 100, 2)
  )

write_csv(region_stats, "tables/06_estadisticas_regiones.csv")

# =============================================================================
# PASO 8: RESUMEN FINAL
# =============================================================================

cat("Generando resumen final...\n")

# Crear resumen ejecutivo
resumen_ejecutivo <- data.frame(
  Análisis = c("Dataset original", "Después split-collapse", "Mutaciones G>T", 
               "VAFs calculadas", "Filtrado VAF > 50%", "Región semilla"),
  Resultado = c(
    paste(nrow(raw_data), "SNVs"),
    paste(nrow(processed_data), "SNVs"),
    paste(nrow(gt_mutations), "SNVs G>T"),
    paste(length(vaf_cols), "muestras"),
    paste(sum(vaf_values > 0.5), "VAFs filtradas"),
    paste(region_counts$n[region_counts$region == "Semilla"], "SNVs en semilla")
  )
)

write_csv(resumen_ejecutivo, "tables/07_resumen_ejecutivo.csv")

# =============================================================================
# FINALIZACIÓN
# =============================================================================

cat("\n=== ANÁLISIS COMPLETADO ===\n")
cat("Figuras generadas en: figures/\n")
cat("Tablas generadas en: tables/\n")
cat("Total de archivos generados:\n")
cat("  - Figuras:", length(list.files("figures/")), "\n")
cat("  - Tablas:", length(list.files("tables/")), "\n")
cat("\nAnálisis inicial del dataset completado exitosamente!\n")
