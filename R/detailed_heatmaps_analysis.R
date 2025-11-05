# =============================================================================
# ANÁLISIS DETALLADO DE HEATMAPS - G>T MUTATIONS
# =============================================================================
# Script para generar heatmaps específicos con:
# 1. Heatmap de VAF con anotaciones ALS/Control
# 2. Heatmap de Z-score con anotaciones ALS/Control
# 3. Análisis detallado de filtros y resultados
# =============================================================================

# Cargar librerías
library(dplyr)
library(readr)
library(stringr)
library(ComplexHeatmap)
library(circlize)
library(RColorBrewer)
library(viridis)

# Configurar opciones
ht_opt$message = FALSE
options(warn = -1)

cat("🔬 ANÁLISIS DETALLADO DE HEATMAPS G>T\n")
cat("=====================================\n\n")

# --- 1. CARGAR DATOS ---
cat("📊 1. CARGANDO DATOS\n")
cat("===================\n")

# Cargar datos principales
df_main <- read.csv("organized/04_results/alex_df.csv", stringsAsFactors = FALSE)
cat("✅ Datos principales cargados:", nrow(df_main), "filas\n")

# Cargar datos de VAF
df_vaf <- read.csv("organized/04_results/VAF_df.csv", stringsAsFactors = FALSE)
cat("✅ Datos VAF cargados:", nrow(df_vaf), "filas\n")

# --- 2. IDENTIFICAR MUESTRAS ALS vs CONTROL ---
cat("\n🔍 2. IDENTIFICANDO MUESTRAS ALS vs CONTROL\n")
cat("==========================================\n")

# Extraer columnas de muestras (excluyendo columnas de metadatos)
sample_cols <- names(df_main)[!names(df_main) %in% c("", "miRNA name", "pos:mut")]

# Identificar muestras ALS vs Control basado en nombres
als_samples <- sample_cols[grepl("ALS", sample_cols, ignore.case = TRUE)]
control_samples <- sample_cols[grepl("Control", sample_cols, ignore.case = TRUE)]

cat("📋 Muestras identificadas:\n")
cat("   - ALS:", length(als_samples), "muestras\n")
cat("   - Control:", length(control_samples), "muestras\n")
cat("   - Total:", length(sample_cols), "muestras\n")

# Crear anotación de muestras
sample_annotation <- data.frame(
  sample = sample_cols,
  group = ifelse(sample_cols %in% als_samples, "ALS", "Control"),
  stringsAsFactors = FALSE
)

# --- 3. FILTRAR MUTACIONES G>T ---
cat("\n🧬 3. FILTRANDO MUTACIONES G>T\n")
cat("==============================\n")

# Separar mutaciones G>T (TODAS, no solo región semilla)
gt_mutations <- df_main %>%
  filter(str_detect(`pos:mut`, "GT$")) %>%
  mutate(
    miRNA_name = `miRNA name`,
    pos = as.integer(str_extract(`pos:mut`, "^([0-9]+):", group = 1)),
    mutation_type = "G>T",
    is_seed_region = pos >= 2 & pos <= 8,
    feature = paste(miRNA_name, pos, "GT", sep = "_")
  )

cat("📊 Mutaciones G>T iniciales:", nrow(gt_mutations), "\n")
cat("   - Región semilla:", sum(gt_mutations$is_seed_region), "\n")
cat("   - Región no-semilla:", sum(!gt_mutations$is_seed_region), "\n")

# --- 4. APLICAR FILTROS DE CALIDAD ---
cat("\n🔍 4. APLICANDO FILTROS DE CALIDAD\n")
cat("==================================\n")

# Aplicar filtro de representación (VAF > 50% en al menos una muestra)
gt_mutations_final <- gt_mutations %>%
  rowwise() %>%
  mutate(
    max_vaf = max(across(all_of(sample_cols)), na.rm = TRUE),
    has_representation = max_vaf > 0.5
  ) %>%
  ungroup() %>%
  filter(has_representation)

cat("📊 Después de filtro VAF>50%:", nrow(gt_mutations_final), "SNVs\n")
cat("   - Región semilla:", sum(gt_mutations_final$is_seed_region), "\n")
cat("   - Región no-semilla:", sum(!gt_mutations_final$is_seed_region), "\n")

# --- 5. PREPARAR MATRICES ---
cat("\n📊 5. PREPARANDO MATRICES\n")
cat("=========================\n")

# Matriz de VAF
vaf_matrix <- gt_mutations_final %>%
  select(feature, all_of(sample_cols)) %>%
  column_to_rownames("feature") %>%
  as.matrix()

cat("📊 Matriz VAF:", nrow(vaf_matrix), "SNVs ×", ncol(vaf_matrix), "muestras\n")

# Calcular Z-score
cat("📊 Calculando Z-score...\n")

# Función para calcular z-score con desviación estándar agrupada
calculate_zscore <- function(vaf_matrix, sample_annotation) {
  zscore_matrix <- matrix(NA, nrow = nrow(vaf_matrix), ncol = ncol(vaf_matrix))
  rownames(zscore_matrix) <- rownames(vaf_matrix)
  colnames(zscore_matrix) <- colnames(vaf_matrix)
  
  for (i in 1:nrow(vaf_matrix)) {
    # Obtener VAFs para este SNV
    vaf_values <- vaf_matrix[i, ]
    
    # Separar por grupo
    als_vafs <- vaf_values[sample_annotation$group == "ALS"]
    control_vafs <- vaf_values[sample_annotation$group == "Control"]
    
    # Calcular estadísticas
    als_mean <- mean(als_vafs, na.rm = TRUE)
    control_mean <- mean(control_vafs, na.rm = TRUE)
    
    # Calcular desviación estándar agrupada
    als_var <- var(als_vafs, na.rm = TRUE)
    control_var <- var(control_vafs, na.rm = TRUE)
    als_n <- sum(!is.na(als_vafs))
    control_n <- sum(!is.na(control_vafs))
    
    if (als_n > 1 && control_n > 1) {
      pooled_sd <- sqrt(((als_n - 1) * als_var + (control_n - 1) * control_var) / 
                        (als_n + control_n - 2))
      
      if (pooled_sd > 0) {
        # Calcular z-score para cada muestra
        for (j in 1:length(vaf_values)) {
          sample_group <- sample_annotation$group[j]
          if (sample_group == "ALS") {
            zscore_matrix[i, j] <- (vaf_values[j] - control_mean) / pooled_sd
          } else {
            zscore_matrix[i, j] <- (vaf_values[j] - als_mean) / pooled_sd
          }
        }
      }
    }
  }
  
  return(zscore_matrix)
}

zscore_matrix <- calculate_zscore(vaf_matrix, sample_annotation)
cat("✅ Z-score calculado\n")

# --- 6. CREAR ANOTACIONES ---
cat("\n🎨 6. CREANDO ANOTACIONES\n")
cat("=========================\n")

# Anotación de columnas (muestras)
col_ha <- HeatmapAnnotation(
  "Group" = sample_annotation$group,
  col = list("Group" = c("ALS" = "#E74C3C", "Control" = "#3498DB")),
  show_annotation_name = TRUE,
  annotation_name_gp = gpar(fontsize = 12, fontface = "bold")
)

# Anotación de filas (SNVs)
row_annotations <- gt_mutations_final %>%
  mutate(
    miRNA_family = case_when(
      str_detect(miRNA_name, "let-7") ~ "let-7",
      str_detect(miRNA_name, "miR-1") ~ "miR-1",
      str_detect(miRNA_name, "miR-16") ~ "miR-16",
      str_detect(miRNA_name, "miR-122") ~ "miR-122",
      str_detect(miRNA_name, "miR-191") ~ "miR-191",
      str_detect(miRNA_name, "miR-423") ~ "miR-423",
      str_detect(miRNA_name, "miR-103") ~ "miR-103",
      str_detect(miRNA_name, "miR-486") ~ "miR-486",
      str_detect(miRNA_name, "miR-93") ~ "miR-93",
      TRUE ~ "Other"
    ),
    position_group = case_when(
      pos <= 3 ~ "Early",
      pos <= 5 ~ "Middle",
      pos <= 8 ~ "Late",
      TRUE ~ "Outside"
    ),
    region_type = ifelse(is_seed_region, "Seed", "Non-Seed")
  ) %>%
  select(feature, miRNA_family, position_group, pos, region_type) %>%
  column_to_rownames("feature")

# Colores para familias de miRNA
family_colors <- c(
  "let-7" = "#FF6B6B", "miR-1" = "#4ECDC4", "miR-16" = "#45B7D1",
  "miR-122" = "#96CEB4", "miR-191" = "#FFEAA7", "miR-423" = "#DDA0DD",
  "miR-103" = "#98D8C8", "miR-486" = "#F7DC6F", "miR-93" = "#BB8FCE",
  "Other" = "#95A5A6"
)

row_ha <- rowAnnotation(
  "miRNA Family" = row_annotations$miRNA_family,
  "Position Group" = row_annotations$position_group,
  "Region Type" = row_annotations$region_type,
  "Position" = row_annotations$pos,
  col = list(
    "miRNA Family" = family_colors,
    "Position Group" = c("Early" = "#FF6B6B", "Middle" = "#4ECDC4", "Late" = "#45B7D1", "Outside" = "#95A5A6"),
    "Region Type" = c("Seed" = "#E74C3C", "Non-Seed" = "#3498DB"),
    "Position" = colorRamp2(c(1, 22), c("lightblue", "darkblue"))
  ),
  show_annotation_name = TRUE,
  annotation_name_gp = gpar(fontsize = 10, fontface = "bold")
)

# --- 7. CREAR HEATMAPS ---
cat("\n🎨 7. CREANDO HEATMAPS\n")
cat("======================\n")

# Crear directorio de salida
if (!dir.exists("outputs/final_paper_graphs")) {
  dir.create("outputs/final_paper_graphs", recursive = TRUE)
}

# HEATMAP 1: VAF
cat("📊 Generando heatmap de VAF...\n")

pdf("outputs/final_paper_graphs/vaf_heatmap_detailed.pdf", width = 16, height = 10)

ht_vaf <- Heatmap(
  vaf_matrix,
  name = "VAF",
  col = colorRamp2(c(0, 0.25, 0.5, 0.75, 1), c("white", "lightblue", "lightgreen", "orange", "red")),
  cluster_rows = TRUE,
  cluster_columns = TRUE,
  show_row_dend = TRUE,
  show_column_dend = TRUE,
  row_dend_width = unit(3, "cm"),
  column_dend_height = unit(3, "cm"),
  
  # Apariencia
  show_row_names = TRUE,
  show_column_names = FALSE,
  row_names_gp = gpar(fontsize = 8),
  column_title = "VAF Heatmap - G>T Mutations (All SNVs, Filtered)",
  row_title = "G>T SNVs (RPM>1, VAF>50%)",
  
  # Anotaciones
  top_annotation = col_ha,
  left_annotation = row_ha,
  
  # Configuración adicional
  use_raster = FALSE
)

draw(ht_vaf)
dev.off()

# HEATMAP 2: Z-SCORE
cat("📊 Generando heatmap de Z-score...\n")

pdf("outputs/final_paper_graphs/zscore_heatmap_detailed.pdf", width = 16, height = 10)

ht_zscore <- Heatmap(
  zscore_matrix,
  name = "Z-score",
  col = colorRamp2(c(-3, -1.5, 0, 1.5, 3), c("blue", "lightblue", "white", "lightcoral", "red")),
  cluster_rows = TRUE,
  cluster_columns = TRUE,
  show_row_dend = TRUE,
  show_column_dend = TRUE,
  row_dend_width = unit(3, "cm"),
  column_dend_height = unit(3, "cm"),
  
  # Apariencia
  show_row_names = TRUE,
  show_column_names = FALSE,
  row_names_gp = gpar(fontsize = 8),
  column_title = "Z-score Heatmap - G>T Mutations (All SNVs, Filtered)",
  row_title = "G>T SNVs (RPM>1, VAF>50%)",
  
  # Anotaciones
  top_annotation = col_ha,
  left_annotation = row_ha,
  
  # Configuración adicional
  use_raster = FALSE
)

draw(ht_zscore)
dev.off()

# --- 8. ANÁLISIS ESTADÍSTICO ---
cat("\n📊 8. ANÁLISIS ESTADÍSTICO\n")
cat("==========================\n")

# Estadísticas por grupo
als_vaf_mean <- mean(vaf_matrix[, sample_annotation$group == "ALS"], na.rm = TRUE)
control_vaf_mean <- mean(vaf_matrix[, sample_annotation$group == "Control"], na.rm = TRUE)

als_zscore_mean <- mean(zscore_matrix[, sample_annotation$group == "ALS"], na.rm = TRUE)
control_zscore_mean <- mean(zscore_matrix[, sample_annotation$group == "Control"], na.rm = TRUE)

cat("📈 ESTADÍSTICAS VAF:\n")
cat("   - ALS (promedio):", round(als_vaf_mean, 4), "\n")
cat("   - Control (promedio):", round(control_vaf_mean, 4), "\n")
cat("   - Diferencia:", round(als_vaf_mean - control_vaf_mean, 4), "\n\n")

cat("📈 ESTADÍSTICAS Z-SCORE:\n")
cat("   - ALS (promedio):", round(als_zscore_mean, 4), "\n")
cat("   - Control (promedio):", round(control_zscore_mean, 4), "\n")
cat("   - Diferencia:", round(als_zscore_mean - control_zscore_mean, 4), "\n\n")

# Análisis por posición
position_stats <- gt_mutations_final %>%
  group_by(pos, is_seed_region) %>%
  summarise(
    count = n(),
    mean_vaf = mean(rowMeans(across(all_of(sample_cols)), na.rm = TRUE)),
    .groups = "drop"
  ) %>%
  arrange(pos)

cat("📊 ESTADÍSTICAS POR POSICIÓN:\n")
print(position_stats)

# --- 9. RESUMEN FINAL ---
cat("\n✅ RESUMEN FINAL\n")
cat("================\n")
cat("📁 Archivos generados:\n")
cat("   - outputs/final_paper_graphs/vaf_heatmap_detailed.pdf\n")
cat("   - outputs/final_paper_graphs/zscore_heatmap_detailed.pdf\n\n")

cat("📊 Datos procesados:\n")
cat("   - SNVs G>T iniciales:", nrow(gt_mutations), "\n")
cat("   - SNVs finales (VAF>50%):", nrow(gt_mutations_final), "\n")
cat("   - Muestras analizadas:", ncol(vaf_matrix), "\n")
cat("   - Muestras ALS:", length(als_samples), "\n")
cat("   - Muestras Control:", length(control_samples), "\n\n")

cat("🎯 Filtros aplicados:\n")
cat("   1. VAF > 50% (representación en al menos una muestra)\n")
cat("   2. Solo mutaciones G>T\n\n")

cat("✅ Análisis completado exitosamente!\n")
