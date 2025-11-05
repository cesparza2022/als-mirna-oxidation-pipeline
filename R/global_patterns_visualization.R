# =============================================================================
# GLOBAL PATTERNS OF miRNA OXIDATION - VISUALIZATION SCRIPT
# =============================================================================
# 
# Objetivo: Crear visualizaciones comprehensivas para la sección 3.2 del paper
# - Gráfica de mutaciones por tipo (VAF-based)
# - Heatmap de SNVs G>T por posición (RPM-based)
# - Distribución de VAFs por posición
# - Análisis de acumulación de mutaciones
#
# Autor: César Esparza
# Fecha: 2025
# =============================================================================

# --- LIBRERÍAS ---
library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(ComplexHeatmap)
library(circlize)
library(grid)
library(viridis)
library(RColorBrewer)
library(reshape2)

# --- VARIABLES GLOBALES ---
# Para evitar warnings de R CMD check
if (getRversion() >= "2.15.1") {
  utils::globalVariables(c("feature", "pos", "mutation_type", "avr_raw"))
}

# --- CONFIGURACIÓN ---
cat("🎨 GLOBAL PATTERNS OF miRNA OXIDATION - VISUALIZATION\n")
cat("====================================================\n\n")

# --- 1. CARGAR DATOS PROCESADOS ---
cat("📊 1. CARGANDO DATOS PROCESADOS\n")
cat("===============================\n")

# Cargar datos principales
df_main <- read.csv("outputs/tables/df_block_heatmap_clean.csv", stringsAsFactors = FALSE)
df_vaf <- read.csv("outputs/tables/VAF_df.csv", stringsAsFactors = FALSE)

# Cargar datos de RPM si están disponibles
if (file.exists("outputs/tables/mirna_rpm_summary.csv")) {
  df_rpm <- read.csv("outputs/tables/mirna_rpm_summary.csv", stringsAsFactors = FALSE)
  cat("✅ Datos de RPM cargados\n")
} else {
  cat("⚠️ Datos de RPM no encontrados, usando datos principales\n")
  df_rpm <- df_main
}

cat("📈 Datos cargados:\n")
cat("   - Filas principales:", nrow(df_main), "\n")
cat("   - Filas VAF:", nrow(df_vaf), "\n")
cat("   - Filas RPM:", nrow(df_rpm), "\n\n")

# --- 2. FUNCIONES AUXILIARES ---
cat("🔧 2. FUNCIONES AUXILIARES\n")
cat("=========================\n")

# Función para manejar VAFs > 50% (convertir a NaN)
handle_vaf_threshold <- function(data, threshold = 0.5) {
  data %>%
    mutate(across(all_of(sample_cols), ~ifelse(. > threshold, NA, .)))
}

# Función split para separar mutaciones por tipo
split_mutations <- function(data) {
  data %>%
    mutate(
      mutation_type = case_when(
        str_detect(feature, "_GT$") ~ "G>T",
        str_detect(feature, "_TC$") ~ "T>C", 
        str_detect(feature, "_AG$") ~ "A>G",
        str_detect(feature, "_GA$") ~ "G>A",
        str_detect(feature, "_CT$") ~ "C>T",
        str_detect(feature, "_TA$") ~ "T>A",
        str_detect(feature, "_TG$") ~ "T>G",
        str_detect(feature, "_AT$") ~ "A>T",
        str_detect(feature, "_PM$") ~ "PM",
        TRUE ~ "Other"
      ),
      miRNA_name = str_extract(feature, "^[^_]+"),
      pos = as.integer(str_extract(feature, "_([0-9]+)_[A-Z]+>$", group = 1))
    )
}

# Función collapse para agrupar por posición
collapse_by_position <- function(data) {
  data %>%
    group_by(pos, mutation_type) %>%
    summarise(
      mean_vaf = mean(rowMeans(across(all_of(sample_cols)), na.rm = TRUE), na.rm = TRUE),
      total_vaf = sum(rowMeans(across(all_of(sample_cols)), na.rm = TRUE), na.rm = TRUE),
      count = n(),
      .groups = "drop"
    )
}

# Función para filtrar por RPM > 1
filter_rpm_threshold <- function(data, threshold = 1) {
  data %>%
    filter(avr_raw > threshold)
}

cat("✅ Funciones auxiliares definidas\n\n")

# --- 3. PREPARAR DATOS PARA ANÁLISIS GLOBAL ---
cat("🔧 3. PREPARANDO DATOS PARA ANÁLISIS GLOBAL\n")
cat("===========================================\n")

# Extraer nombres de muestras (excluyendo columnas de metadatos)
sample_cols <- names(df_main)[!names(df_main) %in% c("feature")]
cat("📊 Muestras identificadas:", length(sample_cols), "\n")

# Aplicar manejo de VAFs > 50%
df_main_processed <- handle_vaf_threshold(df_main)
df_vaf_processed <- handle_vaf_threshold(df_vaf)

cat("✅ VAFs > 50% convertidos a NaN\n")

# Aplicar split a los datos procesados
df_split <- split_mutations(df_main_processed)

# Separar mutaciones G>T
gt_mutations <- df_split %>%
  filter(mutation_type == "G>T")

cat("🎯 Mutaciones G>T identificadas:", nrow(gt_mutations), "\n")
cat("📍 Posiciones únicas:", length(unique(gt_mutations$pos)), "\n\n")

# --- 4. ANÁLISIS DE MUTACIONES POR TIPO (VAF-BASED) ---
cat("📊 4. ANÁLISIS DE MUTACIONES POR TIPO (VAF-BASED)\n")
cat("================================================\n")

# Calcular VAF promedio por tipo de mutación usando datos procesados
mutation_types <- df_split %>%
  select(mutation_type, all_of(sample_cols)) %>%
  group_by(mutation_type) %>%
  summarise(
    total_count = n(),
    mean_vaf = mean(rowMeans(across(all_of(sample_cols)), na.rm = TRUE), na.rm = TRUE),
    total_vaf = sum(rowMeans(across(all_of(sample_cols)), na.rm = TRUE), na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    percentage = round((total_count / sum(total_count)) * 100, 2),
    vaf_percentage = round((total_vaf / sum(total_vaf)) * 100, 2)
  ) %>%
  arrange(desc(total_vaf))

cat("📈 MUTACIONES POR TIPO (VAF-BASED):\n")
print(mutation_types)

# Crear gráfica de barras para mutaciones por tipo
p1 <- mutation_types %>%
  ggplot(aes(x = reorder(mutation_type, total_vaf), y = total_vaf, fill = mutation_type)) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = paste0(round(vaf_percentage, 1), "%")), 
            hjust = -0.1, size = 3.5, fontface = "bold") +
  scale_fill_viridis_d(option = "plasma", alpha = 0.8) +
  coord_flip() +
  labs(
    title = "Global Mutation Patterns by Type (VAF-Based)",
    subtitle = "Total VAF Sum Across All Samples",
    x = "Mutation Type",
    y = "Total VAF Sum",
    fill = "Mutation Type"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 12, color = "gray60"),
    axis.text = element_text(size = 11),
    axis.title = element_text(size = 12, face = "bold"),
    legend.position = "none",
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank()
  )

# Guardar gráfica
ggsave("outputs/final_paper_graphs/global_mutation_types_vaf_based.pdf", p1, width = 12, height = 8, dpi = 300)
cat("✅ Gráfica guardada: outputs/final_paper_graphs/global_mutation_types_vaf_based.pdf\n\n")

# --- 5. HEATMAP DE SNVs G>T POR POSICIÓN (RPM-BASED) ---
cat("🎨 5. CREANDO HEATMAP DE SNVs G>T POR POSICIÓN (RPM-BASED)\n")
cat("=========================================================\n")

# Preparar datos para heatmap (siguiendo el código proporcionado)
df_rpm_processed <- df_rpm %>%
  filter(str_detect(feature, "_GT$")) %>%  # Solo mutaciones G>T
  mutate(
    miRNA_name = str_extract(feature, "^[^_]+"),
    clean_mut = str_extract(feature, "_[0-9]+_GT$"),
    featureID = feature,
    pos = as.integer(str_extract(feature, "_([0-9]+)_GT$", group = 1))
  )

# Identificar columnas RPM
rpm_cols <- grep("_RPM$", names(df_rpm_processed), value = TRUE)
if (length(rpm_cols) == 0) {
  # Si no hay columnas RPM, usar columnas de muestra como proxy
  rpm_cols <- sample_cols
  cat("⚠️ No se encontraron columnas RPM, usando columnas de muestra\n")
}

cat("📊 Columnas RPM identificadas:", length(rpm_cols), "\n")

# Calcular RPM promedio (avr) y aplicar filtro RPM > 1
df_avr <- df_rpm_processed %>%
  mutate(avr_raw = rowMeans(across(all_of(rpm_cols)), na.rm = TRUE)) %>%
  filter_rpm_threshold(threshold = 1) %>%  # Aplicar filtro RPM > 1
  mutate(avr = log2(avr_raw + 1)) %>%
  select(featureID, miRNA_name, pos, avr, avr_raw)

cat("📈 miRNAs con RPM > 1:", nrow(df_avr), "\n")

# Ordenar por posición y RPM
df_ranked <- df_avr %>%
  group_by(pos) %>%
  arrange(desc(avr), .by_group = TRUE) %>%
  mutate(order_within_pos = row_number()) %>%
  ungroup()

# Crear matriz para heatmap
df_summary <- df_ranked %>%
  group_by(pos) %>%
  summarise(total_snvs = n()) %>%
  ungroup()

max_snvs <- max(df_summary$total_snvs)
positions <- sort(unique(df_ranked$pos))

cat("📊 Posiciones únicas:", length(positions), "\n")
cat("📈 Máximo SNVs por posición:", max_snvs, "\n")

# Crear matrices
matrix_list <- list()
for (p in positions) {
  snvs_for_pos <- df_ranked %>%
    filter(pos == p) %>%
    arrange(desc(avr)) %>%
    pull(avr)
  
  n <- length(snvs_for_pos)
  if (n < max_snvs) {
    snvs_for_pos <- c(snvs_for_pos, rep(NA, max_snvs - n))
  }
  
  mat_col <- matrix(snvs_for_pos, ncol = 1)
  colnames(mat_col) <- as.character(p)
  matrix_list[[as.character(p)]] <- mat_col
}

# Combinar matrices
mat <- do.call(cbind, matrix_list)
mat[is.na(mat)] <- 0

cat("📊 Matriz creada:", nrow(mat), "x", ncol(mat), "\n")

# Definir escala de colores
col_fun <- colorRamp2(
  c(0, 2, 4, 6, 8),
  c("#FFFFFF", "#FFCCCC", "#FF9999", "#FF6666", "#CC0000")
)

# Crear heatmap
ht <- Heatmap(
  mat,
  na_col = "white",
  name = "log2(RPM+1)",
  cluster_rows = FALSE,
  cluster_columns = FALSE,
  col = col_fun,
  show_row_names = FALSE,
  show_column_names = TRUE,
  column_title = "G>T Mutations by Position (RPM-Based)",
  row_title = paste0("SNVs (", nrow(df_avr), ")"),
  use_raster = FALSE,
  column_names_rot = 0,
  column_names_centered = TRUE,
  bottom_annotation = HeatmapAnnotation(
    "SNV Count" = anno_barplot(
      df_summary$total_snvs,
      bar_width = 0.8,
      gp = gpar(fill = "grey50"),
      annotation_name_rot = 0,
      height = unit(2, "cm")
    )
  )
)

# Guardar heatmap
pdf("outputs/final_paper_graphs/gt_mutations_by_position_rpm_heatmap.pdf", width = 12, height = 8)
draw(ht)
dev.off()
cat("✅ Heatmap guardado: outputs/final_paper_graphs/gt_mutations_by_position_rpm_heatmap.pdf\n\n")

# --- 6. DISTRIBUCIÓN DE VAFs POR POSICIÓN ---
cat("📊 6. CREANDO DISTRIBUCIÓN DE VAFs POR POSICIÓN\n")
cat("==============================================\n")

# Usar la función collapse para calcular VAF por posición
vaf_by_position <- collapse_by_position(gt_mutations) %>%
  filter(mutation_type == "G>T") %>%
  select(-mutation_type) %>%
  arrange(pos)

cat("📈 VAF POR POSICIÓN:\n")
print(vaf_by_position)

# Crear gráfica de VAF por posición
p2 <- vaf_by_position %>%
  ggplot(aes(x = pos, y = mean_vaf, size = count, color = total_vaf)) +
  geom_point(alpha = 0.7) +
  geom_line(aes(group = 1), alpha = 0.5, color = "gray50") +
  scale_size_continuous(range = c(2, 8), name = "Count") +
  scale_color_viridis_c(name = "Total VAF") +
  labs(
    title = "G>T Mutation VAF Distribution by Position",
    subtitle = "Mean VAF vs Position (Size = Count, Color = Total VAF)",
    x = "Position",
    y = "Mean VAF"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 12, color = "gray60"),
    axis.text = element_text(size = 11),
    axis.title = element_text(size = 12, face = "bold"),
    legend.position = "right"
  )

# Guardar gráfica
ggsave("outputs/final_paper_graphs/vaf_distribution_by_position.pdf", p2, width = 12, height = 8, dpi = 300)
cat("✅ Gráfica guardada: outputs/final_paper_graphs/vaf_distribution_by_position.pdf\n\n")

# --- 7. ANÁLISIS DE ACUMULACIÓN DE MUTACIONES ---
cat("📊 7. ANÁLISIS DE ACUMULACIÓN DE MUTACIONES\n")
cat("==========================================\n")

# Calcular acumulación por posición
accumulation <- vaf_by_position %>%
  mutate(
    cumulative_vaf = cumsum(total_vaf),
    cumulative_count = cumsum(count),
    vaf_percentage = (total_vaf / sum(total_vaf)) * 100,
    cumulative_percentage = (cumulative_vaf / sum(total_vaf)) * 100
  )

cat("📈 ACUMULACIÓN POR POSICIÓN:\n")
print(accumulation)

# Crear gráfica de acumulación
p3 <- accumulation %>%
  ggplot(aes(x = pos)) +
  geom_col(aes(y = vaf_percentage), alpha = 0.6, fill = "steelblue") +
  geom_line(aes(y = cumulative_percentage), color = "red", size = 1.2) +
  geom_point(aes(y = cumulative_percentage), color = "red", size = 2) +
  labs(
    title = "G>T Mutation Accumulation by Position",
    subtitle = "Blue bars = VAF percentage per position, Red line = Cumulative percentage",
    x = "Position",
    y = "Percentage (%)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 12, color = "gray60"),
    axis.text = element_text(size = 11),
    axis.title = element_text(size = 12, face = "bold")
  )

# Guardar gráfica
ggsave("outputs/final_paper_graphs/mutation_accumulation_by_position.pdf", p3, width = 12, height = 8, dpi = 300)
cat("✅ Gráfica guardada: outputs/final_paper_graphs/mutation_accumulation_by_position.pdf\n\n")

# --- 8. RESUMEN FINAL ---
cat("📋 8. RESUMEN FINAL\n")
cat("==================\n")

cat("🎨 GRÁFICAS GENERADAS:\n")
cat("   1. outputs/final_paper_graphs/global_mutation_types_vaf_based.pdf - Mutaciones por tipo (VAF-based)\n")
cat("   2. outputs/final_paper_graphs/gt_mutations_by_position_rpm_heatmap.pdf - Heatmap G>T por posición (RPM-based)\n")
cat("   3. outputs/final_paper_graphs/vaf_distribution_by_position.pdf - Distribución VAF por posición\n")
cat("   4. outputs/final_paper_graphs/mutation_accumulation_by_position.pdf - Acumulación de mutaciones\n\n")

cat("📊 ESTADÍSTICAS CLAVE:\n")
cat("   - Total mutaciones G>T:", nrow(gt_mutations), "\n")
cat("   - Posiciones únicas:", length(unique(gt_mutations$pos)), "\n")
cat("   - Posición con más mutaciones:", accumulation$pos[which.max(accumulation$count)], "\n")
cat("   - Posición con mayor VAF:", accumulation$pos[which.max(accumulation$total_vaf)], "\n")
cat("   - Porcentaje de mutaciones G>T:", round((nrow(gt_mutations) / nrow(df_main)) * 100, 2), "%\n")
cat("   - miRNAs con RPM > 1:", nrow(df_avr), "\n")
cat("   - VAFs > 50% convertidos a NaN: Aplicado\n\n")

cat("🔧 MEJORAS IMPLEMENTADAS:\n")
cat("   ✅ Manejo de VAFs > 50% (convertidos a NaN)\n")
cat("   ✅ Funciones split y collapse para análisis modular\n")
cat("   ✅ Filtro de RPM > 1 para heatmap\n")
cat("   ✅ Análisis mejorado por posición\n")
cat("   ✅ Heatmaps optimizados con mejor visualización\n\n")

cat("✅ ANÁLISIS COMPLETADO EXITOSAMENTE\n")
cat("===================================\n")
