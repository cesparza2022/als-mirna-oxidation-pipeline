# =============================================================================
# GENERACION DE VISUALIZACIONES SIMPLE - ANALISIS INICIAL
# =============================================================================

# Cargar librerias
library(tidyverse)
library(ggplot2)

# Cargar configuracion y funciones
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
# PASO 2: RESUMEN GENERAL
# =============================================================================

cat("Generando resumen general...\n")

# Identificar tipos de columnas
meta_cols <- c("miRNA name", "pos:mut")
count_cols <- names(raw_data)[!names(raw_data) %in% meta_cols]
total_cols <- names(raw_data)[grepl("\\(PM\\+1MM\\+2MM\\)$", names(raw_data))]

# Resumen general
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

write_csv(summary_stats, "tables/01_resumen_general_dataset.csv")

# =============================================================================
# PASO 3: DISTRIBUCION DE SNVs POR miRNA
# =============================================================================

cat("Generando distribucion de SNVs por miRNA...\n")

# Top 20 miRNAs con mas SNVs
mirna_counts <- processed_data %>%
  count(`miRNA name`, sort = TRUE) %>%
  head(20)

# Grafica de SNVs por miRNA
p1 <- ggplot(mirna_counts, aes(x = reorder(`miRNA name`, n), y = n)) +
  geom_col(fill = "steelblue", alpha = 0.7) +
  coord_flip() +
  labs(title = "Top 20 miRNAs con mas SNVs",
       x = "miRNA", y = "Numero de SNVs") +
  theme_minimal() +
  theme(axis.text.y = element_text(size = 8))

ggsave("figures/01_snvs_por_mirna.png", p1, width = 10, height = 8, dpi = 300)

# =============================================================================
# PASO 4: DISTRIBUCION DE POSICIONES
# =============================================================================

cat("Generando distribucion de posiciones...\n")

# Posiciones mas mutadas
position_counts <- processed_data %>%
  mutate(position = as.numeric(str_extract(`pos:mut`, "^\\d+"))) %>%
  count(position, sort = TRUE) %>%
  head(20)

# Grafica de posiciones mas mutadas
p2 <- ggplot(position_counts, aes(x = position, y = n)) +
  geom_col(fill = "darkred", alpha = 0.7) +
  labs(title = "Top 20 posiciones mas mutadas en miRNAs",
       x = "Posicion en miRNA", y = "Numero de SNVs") +
  theme_minimal() +
  scale_x_continuous(breaks = position_counts$position)

ggsave("figures/02_posiciones_mas_mutadas.png", p2, width = 10, height = 6, dpi = 300)

# =============================================================================
# PASO 5: ANALISIS DE MUTACIONES G>T
# =============================================================================

cat("Analizando mutaciones G>T...\n")

# Filtrar solo mutaciones G>T
gt_mutations <- processed_data[grepl(":GT", processed_data$`pos:mut`), ]

# Estadisticas de G>T
gt_stats <- data.frame(
  Metrica = c("Total SNVs", "SNVs G>T", "Porcentaje G>T", "miRNAs con G>T"),
  Valor = c(
    nrow(processed_data),
    nrow(gt_mutations),
    round(nrow(gt_mutations) / nrow(processed_data) * 100, 2),
    length(unique(gt_mutations$`miRNA name`))
  )
)

write_csv(gt_stats, "tables/02_estadisticas_GT.csv")

# Top miRNAs con mas mutaciones G>T
gt_mirna_counts <- gt_mutations %>%
  count(`miRNA name`, sort = TRUE) %>%
  head(20)

# Grafica de G>T por miRNA
p3 <- ggplot(gt_mirna_counts, aes(x = reorder(`miRNA name`, n), y = n)) +
  geom_col(fill = "orange", alpha = 0.7) +
  coord_flip() +
  labs(title = "Top 20 miRNAs con mas mutaciones G>T",
       x = "miRNA", y = "Numero de mutaciones G>T") +
  theme_minimal() +
  theme(axis.text.y = element_text(size = 8))

ggsave("figures/03_gt_por_mirna.png", p3, width = 10, height = 8, dpi = 300)

# =============================================================================
# PASO 6: ANALISIS DE VAFs
# =============================================================================

cat("Analizando VAFs...\n")

# Identificar columnas VAF
vaf_cols <- colnames(vaf_data)[str_detect(colnames(vaf_data), "^VAF_")]

# Calcular estadisticas de VAF
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

# Distribucion de VAFs
vaf_values <- as.numeric(unlist(vaf_data[, vaf_cols]))
vaf_values <- vaf_values[!is.na(vaf_values) & vaf_values > 0]

# Histograma de VAFs
p4 <- ggplot(data.frame(VAF = vaf_values), aes(x = VAF)) +
  geom_histogram(bins = 50, fill = "lightblue", alpha = 0.7, color = "black") +
  geom_vline(xintercept = 0.5, color = "red", linetype = "dashed", size = 1) +
  labs(title = "Distribucion de VAFs",
       x = "Variant Allele Frequency (VAF)", y = "Frecuencia") +
  theme_minimal() +
  scale_x_continuous(limits = c(0, 1))

ggsave("figures/04_distribucion_vafs.png", p4, width = 10, height = 6, dpi = 300)

# =============================================================================
# PASO 7: ANALISIS DE FILTRADO VAF > 50%
# =============================================================================

cat("Analizando filtrado VAF > 50%...\n")

# Estadisticas de filtrado
filtering_stats <- data.frame(
  Metrica = c("Total VAFs", "VAFs > 50%", "Porcentaje filtrado", "VAFs restantes"),
  Valor = c(
    length(vaf_values),
    sum(vaf_values > 0.5),
    round(sum(vaf_values > 0.5) / length(vaf_values) * 100, 2),
    sum(vaf_values <= 0.5)
  )
)

write_csv(filtering_stats, "tables/04_estadisticas_filtrado.csv")

# =============================================================================
# PASO 8: ANALISIS DE REGIONES SEMILLA
# =============================================================================

cat("Analizando regiones semilla...\n")

# Definir regiones semilla (posiciones 2-8)
seed_data <- processed_data %>%
  mutate(position = as.numeric(str_extract(`pos:mut`, "^\\d+"))) %>%
  mutate(region = ifelse(position >= 2 & position <= 8, "Semilla", "No-semilla"))

# Contar SNVs por region
region_counts <- seed_data %>%
  count(region)

# Grafica de SNVs por region
p5 <- ggplot(region_counts, aes(x = region, y = n, fill = region)) +
  geom_col(alpha = 0.7) +
  labs(title = "Distribucion de SNVs por region",
       x = "Region", y = "Numero de SNVs") +
  theme_minimal() +
  scale_fill_brewer(palette = "Set1") +
  theme(legend.position = "none")

ggsave("figures/05_snvs_por_region.png", p5, width = 8, height = 6, dpi = 300)

# Estadisticas de regiones
region_stats <- seed_data %>%
  group_by(region) %>%
  summarise(
    n = n(),
    porcentaje = round(n / nrow(seed_data) * 100, 2)
  )

write_csv(region_stats, "tables/05_estadisticas_regiones.csv")

# =============================================================================
# FINALIZACION
# =============================================================================

cat("\n=== ANALISIS COMPLETADO ===\n")
cat("Figuras generadas en: figures/\n")
cat("Tablas generadas en: tables/\n")
cat("Total de archivos generados:\n")
cat("  - Figuras:", length(list.files("figures/")), "\n")
cat("  - Tablas:", length(list.files("tables/")), "\n")
cat("\nAnalisis inicial del dataset completado exitosamente!\n")








