# --- LIBRERÍAS ---
library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(reshape2)
library(ComplexHeatmap)
library(circlize)
library(viridis)
library(RColorBrewer)
library(tibble)

# --- CONFIGURACIÓN ---
cat("🔬 HEATMAPS DE PATRONES POSICIONALES\n")
cat("====================================\n\n")

# --- 1. CARGANDO DATOS PROCESADOS ---
cat("📊 1. CARGANDO DATOS PROCESADOS\n")
cat("===============================\n")

processed_data_path <- "final_analysis/processed_data/processed_snvs_gt.csv"
df_processed <- read.csv(processed_data_path, stringsAsFactors = FALSE)

# Cargar métricas globales
global_metrics <- read.csv("final_analysis/tables/global_metrics.csv", stringsAsFactors = FALSE)

# Cargar metadatos de muestras
sample_metadata <- read.csv("final_analysis/tables/sample_metadata.csv", stringsAsFactors = FALSE)

cat(paste0("   - SNVs procesados: ", nrow(df_processed), "\n"))
cat(paste0("   - miRNAs únicos: ", length(unique(df_processed$miRNA_name)), "\n"))
cat(paste0("   - Muestras: ", nrow(global_metrics), "\n\n"))

# --- 2. PREPARANDO DATOS CON POSICIONES ---
cat("🔍 2. PREPARANDO DATOS CON POSICIONES\n")
cat("=====================================\n")

# Los datos ya tienen las columnas pos y mutation_type separadas
df_with_positions <- df_processed %>%
  filter(!is.na(pos), !is.na(mutation_type)) %>%
  rename(position = pos)

# Clasificar por región seed (posiciones 2-8)
df_with_regions <- df_with_positions %>%
  mutate(
    region = case_when(
      position >= 2 & position <= 8 ~ "Seed",
      TRUE ~ "Non-seed"
    ),
    region_detailed = case_when(
      position == 1 ~ "5' end",
      position >= 2 & position <= 8 ~ "Seed region",
      position >= 9 & position <= 12 ~ "Central region",
      position >= 13 & position <= 18 ~ "3' region",
      position >= 19 ~ "3' end"
    )
  )

cat(paste0("   - SNVs con posiciones: ", nrow(df_with_positions), "\n"))
cat(paste0("   - Posiciones únicas: ", length(unique(df_with_positions$position)), "\n"))
cat(paste0("   - Rango de posiciones: ", min(df_with_positions$position), " - ", max(df_with_positions$position), "\n\n"))

# --- 3. CALCULANDO VAFs POR POSICIÓN Y MUESTRA ---
cat("🧮 3. CALCULANDO VAFs POR POSICIÓN Y MUESTRA\n")
cat("============================================\n")

# Identificar columnas de cuentas y totales
df_original_cols <- read.csv("results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt", sep="\t", stringsAsFactors = FALSE)
total_cols_original <- names(df_original_cols)[grepl('..PM.1MM.2MM.', names(df_original_cols), fixed=TRUE)]
count_cols_original <- names(df_original_cols)[!grepl('..PM.1MM.2MM.', names(df_original_cols), fixed=TRUE) & !names(df_original_cols) %in% c('miRNA.name', 'pos.mut')]

# Asegurarse de que las columnas de muestra en df_with_regions coincidan
sample_names_in_data <- names(df_with_regions)[!names(df_with_regions) %in% c("miRNA_name", "pos", "mutation_type", "position", "region", "region_detailed")]
count_sample_cols_processed <- intersect(sample_names_in_data, gsub("..PM.1MM.2MM.", "", count_cols_original, fixed=TRUE))
total_sample_cols_processed <- intersect(sample_names_in_data, total_cols_original)

# Crear un dataframe para VAFs por posición
vaf_by_position <- data.frame()

for (i in 1:length(count_sample_cols_processed)) {
  sample_count_col <- count_sample_cols_processed[i]
  sample_total_col <- total_sample_cols_processed[i]
  
  if (sample_count_col %in% names(df_with_regions) && sample_total_col %in% names(df_with_regions)) {
    temp_df <- df_with_regions %>%
      select(miRNA_name, position, region, region_detailed, !!sym(sample_count_col), !!sym(sample_total_col)) %>%
      mutate(
        sample = sample_count_col,
        snv_count = .data[[sample_count_col]],
        total_mirna_count = .data[[sample_total_col]],
        vaf = ifelse(total_mirna_count > 0, snv_count / total_mirna_count, 0)
      ) %>%
      select(miRNA_name, position, region, region_detailed, sample, snv_count, total_mirna_count, vaf)
    vaf_by_position <- bind_rows(vaf_by_position, temp_df)
  }
}

# Reemplazar VAFs > 0.5 con NA
vaf_by_position <- vaf_by_position %>%
  mutate(vaf = ifelse(vaf > 0.5, NA, vaf))

# Agregar metadatos de cohorte
vaf_by_position <- vaf_by_position %>%
  left_join(sample_metadata, by = "sample") %>%
  filter(!is.na(cohort))

cat(paste0("   - VAFs calculados: ", nrow(vaf_by_position), "\n"))
cat(paste0("   - VAFs válidos (>0): ", sum(vaf_by_position$vaf > 0, na.rm = TRUE), "\n\n"))

# --- 4. CREANDO MATRICES PARA HEATMAPS ---
cat("📊 4. CREANDO MATRICES PARA HEATMAPS\n")
cat("====================================\n")

# Matriz de VAF medio por posición y muestra
vaf_matrix <- vaf_by_position %>%
  group_by(sample, position) %>%
  summarise(mean_vaf = mean(vaf, na.rm = TRUE), .groups = 'drop') %>%
  pivot_wider(names_from = sample, values_from = mean_vaf) %>%
  column_to_rownames("position")

# Matriz de SNVs detectados por posición y muestra
snvs_matrix <- vaf_by_position %>%
  group_by(sample, position) %>%
  summarise(total_snvs = sum(snv_count > 0, na.rm = TRUE), .groups = 'drop') %>%
  pivot_wider(names_from = sample, values_from = total_snvs) %>%
  column_to_rownames("position")

# Matriz de SNVs con VAF > 0.1 por posición y muestra
high_vaf_matrix <- vaf_by_position %>%
  group_by(sample, position) %>%
  summarise(high_vaf_snvs = sum(vaf > 0.1, na.rm = TRUE), .groups = 'drop') %>%
  pivot_wider(names_from = sample, values_from = high_vaf_snvs) %>%
  column_to_rownames("position")

cat(paste0("   - Matriz VAF: ", nrow(vaf_matrix), " x ", ncol(vaf_matrix), "\n"))
cat(paste0("   - Matriz SNVs: ", nrow(snvs_matrix), " x ", ncol(snvs_matrix), "\n"))
cat(paste0("   - Matriz High VAF: ", nrow(high_vaf_matrix), " x ", ncol(high_vaf_matrix), "\n\n"))

# --- 5. CREANDO ANOTACIONES DE MUESTRAS ---
cat("🎨 5. CREANDO ANOTACIONES DE MUESTRAS\n")
cat("=====================================\n")

# Crear anotaciones de cohorte
sample_annotations <- sample_metadata %>%
  filter(sample %in% colnames(vaf_matrix)) %>%
  select(sample, cohort, timepoint) %>%
  arrange(sample)

# Crear anotaciones de posición
position_annotations <- data.frame(
  position = rownames(vaf_matrix),
  region = case_when(
    as.numeric(rownames(vaf_matrix)) >= 2 & as.numeric(rownames(vaf_matrix)) <= 8 ~ "Seed",
    TRUE ~ "Non-seed"
  )
)

cat(paste0("   - Anotaciones de muestras: ", nrow(sample_annotations), "\n"))
cat(paste0("   - Anotaciones de posiciones: ", nrow(position_annotations), "\n\n"))

# --- 6. CREANDO HEATMAPS ---
cat("🔥 6. CREANDO HEATMAPS\n")
cat("======================\n")

figures_dir <- "final_analysis/figures"
if (!dir.exists(figures_dir)) {
  dir.create(figures_dir, recursive = TRUE)
}

# Definir colores
cohort_colors <- c("ALS" = "#E31A1C", "Control" = "#1F78B4")
region_colors <- c("Seed" = "#FF7F00", "Non-seed" = "#33A02C")

# Crear anotaciones
ha_samples <- HeatmapAnnotation(
  Cohort = sample_annotations$cohort,
  col = list(Cohort = cohort_colors),
  annotation_name_gp = gpar(fontsize = 10)
)

ha_positions <- rowAnnotation(
  Region = position_annotations$region,
  col = list(Region = region_colors),
  annotation_name_gp = gpar(fontsize = 10)
)

# Heatmap 1: VAF medio por posición y muestra
cat("   - Creando heatmap de VAF medio...\n")
ht_vaf <- Heatmap(
  as.matrix(vaf_matrix),
  name = "VAF",
  col = colorRamp2(c(0, max(vaf_matrix, na.rm = TRUE)), c("white", "red")),
  top_annotation = ha_samples,
  left_annotation = ha_positions,
  cluster_rows = FALSE,
  cluster_columns = TRUE,
  show_row_names = TRUE,
  show_column_names = FALSE,
  row_names_gp = gpar(fontsize = 8),
  column_title = "VAF Medio por Posición y Muestra",
  column_title_gp = gpar(fontsize = 12, fontface = "bold")
)

# Heatmap 2: SNVs detectados por posición y muestra
cat("   - Creando heatmap de SNVs detectados...\n")
ht_snvs <- Heatmap(
  as.matrix(snvs_matrix),
  name = "SNVs",
  col = colorRamp2(c(0, max(snvs_matrix, na.rm = TRUE)), c("white", "blue")),
  top_annotation = ha_samples,
  left_annotation = ha_positions,
  cluster_rows = FALSE,
  cluster_columns = TRUE,
  show_row_names = TRUE,
  show_column_names = FALSE,
  row_names_gp = gpar(fontsize = 8),
  column_title = "SNVs Detectados por Posición y Muestra",
  column_title_gp = gpar(fontsize = 12, fontface = "bold")
)

# Heatmap 3: SNVs con VAF > 0.1 por posición y muestra
cat("   - Creando heatmap de SNVs con VAF > 0.1...\n")
ht_high_vaf <- Heatmap(
  as.matrix(high_vaf_matrix),
  name = "High VAF SNVs",
  col = colorRamp2(c(0, max(high_vaf_matrix, na.rm = TRUE)), c("white", "purple")),
  top_annotation = ha_samples,
  left_annotation = ha_positions,
  cluster_rows = FALSE,
  cluster_columns = TRUE,
  show_row_names = TRUE,
  show_column_names = FALSE,
  row_names_gp = gpar(fontsize = 8),
  column_title = "SNVs con VAF > 0.1 por Posición y Muestra",
  column_title_gp = gpar(fontsize = 12, fontface = "bold")
)

# Guardar heatmaps individuales
png(file.path(figures_dir, "heatmap_vaf_by_position.png"), width = 1200, height = 800)
draw(ht_vaf)
dev.off()

png(file.path(figures_dir, "heatmap_snvs_by_position.png"), width = 1200, height = 800)
draw(ht_snvs)
dev.off()

png(file.path(figures_dir, "heatmap_high_vaf_by_position.png"), width = 1200, height = 800)
draw(ht_high_vaf)
dev.off()

# Heatmap combinado
cat("   - Creando heatmap combinado...\n")
ht_combined <- ht_vaf + ht_snvs + ht_high_vaf

png(file.path(figures_dir, "heatmap_combined_by_position.png"), width = 1800, height = 800)
draw(ht_combined)
dev.off()

cat(paste0("   - Heatmaps guardados en: ", figures_dir, "\n\n"))

# --- 7. CREANDO HEATMAPS POR COHORTE ---
cat("👥 7. CREANDO HEATMAPS POR COHORTE\n")
cat("===================================\n")

# Separar por cohorte
als_samples <- sample_annotations$sample[sample_annotations$cohort == "ALS"]
control_samples <- sample_annotations$sample[sample_annotations$cohort == "Control"]

# Matrices por cohorte
vaf_matrix_als <- vaf_matrix[, als_samples]
vaf_matrix_control <- vaf_matrix[, control_samples]

snvs_matrix_als <- snvs_matrix[, als_samples]
snvs_matrix_control <- snvs_matrix[, control_samples]

# Heatmap ALS
cat("   - Creando heatmap para cohorte ALS...\n")
ht_vaf_als <- Heatmap(
  as.matrix(vaf_matrix_als),
  name = "VAF",
  col = colorRamp2(c(0, max(vaf_matrix_als, na.rm = TRUE)), c("white", "red")),
  left_annotation = ha_positions,
  cluster_rows = FALSE,
  cluster_columns = TRUE,
  show_row_names = TRUE,
  show_column_names = FALSE,
  row_names_gp = gpar(fontsize = 8),
  column_title = "VAF Medio - Cohorte ALS",
  column_title_gp = gpar(fontsize = 12, fontface = "bold")
)

# Heatmap Control
cat("   - Creando heatmap para cohorte Control...\n")
ht_vaf_control <- Heatmap(
  as.matrix(vaf_matrix_control),
  name = "VAF",
  col = colorRamp2(c(0, max(vaf_matrix_control, na.rm = TRUE)), c("white", "red")),
  left_annotation = ha_positions,
  cluster_rows = FALSE,
  cluster_columns = TRUE,
  show_row_names = TRUE,
  show_column_names = FALSE,
  row_names_gp = gpar(fontsize = 8),
  column_title = "VAF Medio - Cohorte Control",
  column_title_gp = gpar(fontsize = 12, fontface = "bold")
)

# Guardar heatmaps por cohorte
png(file.path(figures_dir, "heatmap_vaf_als.png"), width = 1200, height = 800)
draw(ht_vaf_als)
dev.off()

png(file.path(figures_dir, "heatmap_vaf_control.png"), width = 1200, height = 800)
draw(ht_vaf_control)
dev.off()

# Heatmap comparativo
cat("   - Creando heatmap comparativo...\n")
ht_comparative <- ht_vaf_als + ht_vaf_control

png(file.path(figures_dir, "heatmap_comparative_cohorts.png"), width = 1800, height = 800)
draw(ht_comparative)
dev.off()

cat(paste0("   - Heatmaps por cohorte guardados en: ", figures_dir, "\n\n"))

# --- 8. CREANDO HEATMAPS DE DIFERENCIAS ---
cat("📊 8. CREANDO HEATMAPS DE DIFERENCIAS\n")
cat("=====================================\n")

# Calcular diferencias de medias por posición
vaf_differences <- vaf_by_position %>%
  group_by(position, cohort) %>%
  summarise(mean_vaf = mean(vaf, na.rm = TRUE), .groups = 'drop') %>%
  pivot_wider(names_from = cohort, values_from = mean_vaf) %>%
  mutate(difference = ALS - Control) %>%
  select(position, difference) %>%
  column_to_rownames("position")

snvs_differences <- vaf_by_position %>%
  group_by(position, cohort) %>%
  summarise(mean_snvs = sum(snv_count > 0, na.rm = TRUE), .groups = 'drop') %>%
  pivot_wider(names_from = cohort, values_from = mean_snvs) %>%
  mutate(difference = ALS - Control) %>%
  select(position, difference) %>%
  column_to_rownames("position")

# Heatmap de diferencias VAF
cat("   - Creando heatmap de diferencias VAF...\n")
ht_vaf_diff <- Heatmap(
  as.matrix(vaf_differences),
  name = "VAF Difference\n(ALS - Control)",
  col = colorRamp2(c(min(vaf_differences, na.rm = TRUE), 0, max(vaf_differences, na.rm = TRUE)), 
                   c("blue", "white", "red")),
  left_annotation = ha_positions,
  cluster_rows = FALSE,
  show_row_names = TRUE,
  show_column_names = FALSE,
  row_names_gp = gpar(fontsize = 8),
  column_title = "Diferencias de VAF Medio (ALS - Control)",
  column_title_gp = gpar(fontsize = 12, fontface = "bold")
)

# Heatmap de diferencias SNVs
cat("   - Creando heatmap de diferencias SNVs...\n")
ht_snvs_diff <- Heatmap(
  as.matrix(snvs_differences),
  name = "SNVs Difference\n(ALS - Control)",
  col = colorRamp2(c(min(snvs_differences, na.rm = TRUE), 0, max(snvs_differences, na.rm = TRUE)), 
                   c("blue", "white", "red")),
  left_annotation = ha_positions,
  cluster_rows = FALSE,
  show_row_names = TRUE,
  show_column_names = FALSE,
  row_names_gp = gpar(fontsize = 8),
  column_title = "Diferencias de SNVs Detectados (ALS - Control)",
  column_title_gp = gpar(fontsize = 12, fontface = "bold")
)

# Guardar heatmaps de diferencias
png(file.path(figures_dir, "heatmap_vaf_differences.png"), width = 800, height = 800)
draw(ht_vaf_diff)
dev.off()

png(file.path(figures_dir, "heatmap_snvs_differences.png"), width = 800, height = 800)
draw(ht_snvs_diff)
dev.off()

# Heatmap combinado de diferencias
cat("   - Creando heatmap combinado de diferencias...\n")
ht_differences_combined <- ht_vaf_diff + ht_snvs_diff

png(file.path(figures_dir, "heatmap_differences_combined.png"), width = 1200, height = 800)
draw(ht_differences_combined)
dev.off()

cat(paste0("   - Heatmaps de diferencias guardados en: ", figures_dir, "\n\n"))

# --- 9. GUARDAR RESULTADOS ---
cat("💾 9. GUARDAR RESULTADOS\n")
cat("========================\n")

tables_dir <- "final_analysis/tables"
if (!dir.exists(tables_dir)) {
  dir.create(tables_dir, recursive = TRUE)
}

write.csv(vaf_matrix, file.path(tables_dir, "vaf_matrix_by_position.csv"), row.names = TRUE)
write.csv(snvs_matrix, file.path(tables_dir, "snvs_matrix_by_position.csv"), row.names = TRUE)
write.csv(high_vaf_matrix, file.path(tables_dir, "high_vaf_matrix_by_position.csv"), row.names = TRUE)
write.csv(vaf_differences, file.path(tables_dir, "vaf_differences_by_position.csv"), row.names = TRUE)
write.csv(snvs_differences, file.path(tables_dir, "snvs_differences_by_position.csv"), row.names = TRUE)

cat(paste0("   - Matrices guardadas en: ", tables_dir, "\n\n"))

# --- 10. RESUMEN FINAL ---
cat("📋 10. RESUMEN FINAL\n")
cat("====================\n")

cat("🔥 HEATMAPS CREADOS:\n")
cat("   - VAF medio por posición y muestra: ✓\n")
cat("   - SNVs detectados por posición y muestra: ✓\n")
cat("   - SNVs con VAF > 0.1 por posición y muestra: ✓\n")
cat("   - Heatmaps por cohorte (ALS vs Control): ✓\n")
cat("   - Heatmaps de diferencias (ALS - Control): ✓\n")
cat("   - Heatmaps combinados: ✓\n\n")

cat("📊 MÉTRICAS DE MATRICES:\n")
cat(paste0("   - Posiciones analizadas: ", nrow(vaf_matrix), "\n"))
cat(paste0("   - Muestras analizadas: ", ncol(vaf_matrix), "\n"))
cat(paste0("   - Muestras ALS: ", length(als_samples), "\n"))
cat(paste0("   - Muestras Control: ", length(control_samples), "\n\n"))

cat("✅ VERIFICACIONES:\n")
cat("   - Matrices de datos creadas: ✓\n")
cat("   - Anotaciones de muestras y posiciones: ✓\n")
cat("   - Heatmaps individuales creados: ✓\n")
cat("   - Heatmaps por cohorte creados: ✓\n")
cat("   - Heatmaps de diferencias creados: ✓\n")
cat("   - Resultados guardados: ✓\n\n")

cat("🎯 PRÓXIMOS PASOS:\n")
cat("   - Ejecutar análisis por miRNA individual\n")
cat("   - Realizar análisis de clustering\n")
cat("   - Crear análisis funcional\n\n")
