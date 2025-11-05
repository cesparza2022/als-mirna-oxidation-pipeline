# =============================================================================
# ANÁLISIS DETALLADO DE FILTROS - G>T MUTATIONS
# =============================================================================
# Script para analizar el efecto de los filtros RPM>1 y VAF>50%
# y generar estadísticas detalladas por posición
# =============================================================================

# Cargar librerías
library(dplyr)
library(readr)
library(stringr)
library(tibble)
library(ggplot2)
library(ComplexHeatmap)
library(circlize)

# Configurar opciones
ht_opt$message = FALSE
options(warn = -1)

cat("🔬 ANÁLISIS DETALLADO DE FILTROS G>T\n")
cat("====================================\n\n")

# --- 1. CARGAR DATOS ---
cat("📊 1. CARGANDO DATOS\n")
cat("===================\n")

# Cargar datos principales
df_main <- read.csv("organized/04_results/alex_df.csv", stringsAsFactors = FALSE)
cat("✅ Datos principales cargados:", nrow(df_main), "filas\n")

# Cargar datos RPM si existen
if (file.exists("outputs/tables/df_rpm_processed.csv")) {
  df_rpm <- read.csv("outputs/tables/df_rpm_processed.csv", stringsAsFactors = FALSE)
  cat("✅ Datos RPM cargados:", nrow(df_rpm), "filas\n")
} else {
  cat("⚠️ Datos RPM no encontrados, saltando filtro RPM>1\n")
  df_rpm <- NULL
}

# --- 2. IDENTIFICAR MUESTRAS ---
cat("\n🔍 2. IDENTIFICANDO MUESTRAS\n")
cat("=============================\n")

# Extraer columnas de muestras
sample_cols <- names(df_main)[!names(df_main) %in% c("X", "miRNA.name", "pos.mut")]

# Identificar muestras ALS vs Control
als_samples <- sample_cols[grepl("ALS", sample_cols, ignore.case = TRUE)]
control_samples <- sample_cols[grepl("Control", sample_cols, ignore.case = TRUE)]

cat("📋 Muestras identificadas:\n")
cat("   - ALS:", length(als_samples), "muestras\n")
cat("   - Control:", length(control_samples), "muestras\n")
cat("   - Total:", length(sample_cols), "muestras\n")

# --- 3. FILTRAR MUTACIONES G>T INICIALES ---
cat("\n🧬 3. MUTACIONES G>T INICIALES\n")
cat("===============================\n")

# Separar mutaciones G>T
gt_mutations_initial <- df_main %>%
  filter(str_detect(pos.mut, "GT$")) %>%
  mutate(
    miRNA_name = miRNA.name,
    pos = as.integer(str_extract(pos.mut, "^([0-9]+):", group = 1)),
    mutation_type = "G>T",
    is_seed_region = pos >= 2 & pos <= 8,
    feature = paste(miRNA_name, pos, "GT", sep = "_")
  )

cat("📊 Mutaciones G>T iniciales:", nrow(gt_mutations_initial), "\n")
cat("   - Región semilla:", sum(gt_mutations_initial$is_seed_region), "\n")
cat("   - Región no-semilla:", sum(!gt_mutations_initial$is_seed_region), "\n")

# Estadísticas por posición iniciales
initial_position_stats <- gt_mutations_initial %>%
  group_by(pos, is_seed_region) %>%
  summarise(
    count = n(),
    mean_vaf = mean(rowMeans(across(all_of(sample_cols)), na.rm = TRUE)),
    max_vaf = max(rowMeans(across(all_of(sample_cols)), na.rm = TRUE)),
    .groups = "drop"
  ) %>%
  arrange(pos)

cat("\n📊 ESTADÍSTICAS POR POSICIÓN (INICIALES):\n")
print(initial_position_stats)

# --- 4. APLICAR FILTRO RPM>1 (SI DISPONIBLE) ---
cat("\n🔍 4. APLICANDO FILTRO RPM>1\n")
cat("=============================\n")

if (!is.null(df_rpm)) {
  # Aplicar filtro RPM>1
  rpm_cols <- grep("_RPM$", names(df_rpm), value = TRUE)
  df_rpm_filtered <- df_rpm %>%
    mutate(
      mean_rpm = rowMeans(across(all_of(rpm_cols)), na.rm = TRUE)
    ) %>%
    filter(mean_rpm > 1) %>%
    select(feature)
  
  # Filtrar mutaciones G>T por RPM>1
  gt_mutations_rpm <- gt_mutations_initial %>%
    filter(feature %in% df_rpm_filtered$feature)
  
  cat("📊 Después de filtro RPM>1:", nrow(gt_mutations_rpm), "SNVs\n")
  cat("   - Región semilla:", sum(gt_mutations_rpm$is_seed_region), "\n")
  cat("   - Región no-semilla:", sum(!gt_mutations_rpm$is_seed_region), "\n")
  
  # Estadísticas por posición después de RPM>1
  rpm_position_stats <- gt_mutations_rpm %>%
    group_by(pos, is_seed_region) %>%
    summarise(
      count = n(),
      mean_vaf = mean(rowMeans(across(all_of(sample_cols)), na.rm = TRUE)),
      max_vaf = max(rowMeans(across(all_of(sample_cols)), na.rm = TRUE)),
      .groups = "drop"
    ) %>%
    arrange(pos)
  
  cat("\n📊 ESTADÍSTICAS POR POSICIÓN (RPM>1):\n")
  print(rpm_position_stats)
  
} else {
  cat("⚠️ Saltando filtro RPM>1 (datos no disponibles)\n")
  gt_mutations_rpm <- gt_mutations_initial
  rpm_position_stats <- initial_position_stats
}

# --- 5. APLICAR FILTRO VAF>50% ---
cat("\n🔍 5. APLICANDO FILTRO VAF>50%\n")
cat("===============================\n")

# Aplicar filtro de representación (VAF > 50% en al menos una muestra)
gt_mutations_final <- gt_mutations_rpm %>%
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

# Estadísticas por posición finales
final_position_stats <- gt_mutations_final %>%
  group_by(pos, is_seed_region) %>%
  summarise(
    count = n(),
    mean_vaf = mean(rowMeans(across(all_of(sample_cols)), na.rm = TRUE)),
    max_vaf = max(rowMeans(across(all_of(sample_cols)), na.rm = TRUE)),
    .groups = "drop"
  ) %>%
  arrange(pos)

cat("\n📊 ESTADÍSTICAS POR POSICIÓN (FINALES):\n")
print(final_position_stats)

# --- 6. CALCULAR Z-SCORES ---
cat("\n📊 6. CALCULANDO Z-SCORES\n")
cat("=========================\n")

# Preparar matriz de VAF
vaf_matrix <- gt_mutations_final %>%
  mutate(feature_unique = paste(feature, row_number(), sep = "_")) %>%
  select(feature_unique, all_of(sample_cols)) %>%
  column_to_rownames("feature_unique") %>%
  as.matrix()

# Crear anotación de muestras
sample_annotation <- data.frame(
  sample = sample_cols,
  group = ifelse(sample_cols %in% als_samples, "ALS", "Control"),
  stringsAsFactors = FALSE
)

# Función para calcular z-score
calculate_zscore <- function(vaf_matrix, sample_annotation) {
  zscore_matrix <- matrix(NA, nrow = nrow(vaf_matrix), ncol = ncol(vaf_matrix))
  rownames(zscore_matrix) <- rownames(vaf_matrix)
  colnames(zscore_matrix) <- colnames(vaf_matrix)
  
  for (i in 1:nrow(vaf_matrix)) {
    vaf_values <- vaf_matrix[i, ]
    als_vafs <- vaf_values[sample_annotation$group == "ALS"]
    control_vafs <- vaf_values[sample_annotation$group == "Control"]
    
    als_mean <- mean(als_vafs, na.rm = TRUE)
    control_mean <- mean(control_vafs, na.rm = TRUE)
    
    als_var <- var(als_vafs, na.rm = TRUE)
    control_var <- var(control_vafs, na.rm = TRUE)
    als_n <- sum(!is.na(als_vafs))
    control_n <- sum(!is.na(control_vafs))
    
    if (als_n > 1 && control_n > 1) {
      pooled_sd <- sqrt(((als_n - 1) * als_var + (control_n - 1) * control_var) / 
                        (als_n + control_n - 2))
      
      if (pooled_sd > 0) {
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

# --- 7. ANÁLISIS ESTADÍSTICO DETALLADO ---
cat("\n📊 7. ANÁLISIS ESTADÍSTICO DETALLADO\n")
cat("=====================================\n")

# Estadísticas por grupo
als_vaf_mean <- mean(vaf_matrix[, sample_annotation$group == "ALS"], na.rm = TRUE)
control_vaf_mean <- mean(vaf_matrix[, sample_annotation$group == "Control"], na.rm = TRUE)

als_zscore_mean <- mean(zscore_matrix[, sample_annotation$group == "ALS"], na.rm = TRUE)
control_zscore_mean <- mean(zscore_matrix[, sample_annotation$group == "Control"], na.rm = TRUE)

cat("📈 ESTADÍSTICAS VAF:\n")
cat("   - ALS (promedio):", round(als_vaf_mean, 4), "\n")
cat("   - Control (promedio):", round(control_vaf_mean, 4), "\n")
cat("   - Diferencia:", round(als_vaf_mean - control_vaf_mean, 4), "\n")
cat("   - % Diferencia:", round((als_vaf_mean - control_vaf_mean) / control_vaf_mean * 100, 2), "%\n\n")

cat("📈 ESTADÍSTICAS Z-SCORE:\n")
cat("   - ALS (promedio):", round(als_zscore_mean, 4), "\n")
cat("   - Control (promedio):", round(control_zscore_mean, 4), "\n")
cat("   - Diferencia:", round(als_zscore_mean - control_zscore_mean, 4), "\n\n")

# Análisis por posición con Z-scores
position_zscore_stats <- gt_mutations_final %>%
  mutate(feature_unique = paste(feature, row_number(), sep = "_")) %>%
  left_join(
    data.frame(
      feature_unique = rownames(zscore_matrix),
      mean_zscore = rowMeans(zscore_matrix, na.rm = TRUE),
      max_zscore = apply(zscore_matrix, 1, max, na.rm = TRUE)
    ),
    by = "feature_unique"
  ) %>%
  group_by(pos, is_seed_region) %>%
  summarise(
    count = n(),
    mean_vaf = mean(rowMeans(across(all_of(sample_cols)), na.rm = TRUE)),
    max_vaf = max(rowMeans(across(all_of(sample_cols)), na.rm = TRUE)),
    mean_zscore = mean(mean_zscore, na.rm = TRUE),
    max_zscore = max(max_zscore, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(mean_vaf))

cat("📊 ESTADÍSTICAS POR POSICIÓN (VAF + Z-SCORE):\n")
print(position_zscore_stats)

# --- 8. GENERAR GRÁFICAS ---
cat("\n🎨 8. GENERANDO GRÁFICAS\n")
cat("=========================\n")

# Crear directorio de salida
if (!dir.exists("outputs/final_paper_graphs")) {
  dir.create("outputs/final_paper_graphs", recursive = TRUE)
}

# Gráfica 1: Comparación de filtros
pdf("outputs/final_paper_graphs/filter_comparison_analysis.pdf", width = 12, height = 8)

# Preparar datos para gráfica
filter_data <- data.frame(
  Stage = c("Inicial", "RPM>1", "VAF>50%"),
  Total_SNVs = c(nrow(gt_mutations_initial), nrow(gt_mutations_rpm), nrow(gt_mutations_final)),
  Seed_Region = c(sum(gt_mutations_initial$is_seed_region), 
                  sum(gt_mutations_rpm$is_seed_region), 
                  sum(gt_mutations_final$is_seed_region)),
  Non_Seed_Region = c(sum(!gt_mutations_initial$is_seed_region), 
                      sum(!gt_mutations_rpm$is_seed_region), 
                      sum(!gt_mutations_final$is_seed_region))
)

# Gráfica de barras
p1 <- ggplot(filter_data, aes(x = Stage)) +
  geom_bar(aes(y = Total_SNVs), stat = "identity", fill = "steelblue", alpha = 0.7) +
  geom_text(aes(y = Total_SNVs, label = Total_SNVs), vjust = -0.5, size = 4) +
  labs(title = "Efecto de Filtros en SNVs G>T",
       x = "Etapa de Filtrado",
       y = "Número de SNVs") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold"))

print(p1)

# Gráfica 2: VAF por posición
p2 <- ggplot(final_position_stats, aes(x = pos, y = mean_vaf, fill = is_seed_region)) +
  geom_bar(stat = "identity", alpha = 0.8) +
  geom_text(aes(label = count), vjust = -0.5, size = 3) +
  scale_fill_manual(values = c("TRUE" = "#E74C3C", "FALSE" = "#3498DB"),
                    labels = c("TRUE" = "Seed Region", "FALSE" = "Non-Seed Region"),
                    name = "Region Type") +
  labs(title = "VAF Promedio por Posición (Después de Filtros)",
       x = "Posición en miRNA",
       y = "VAF Promedio") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold"))

print(p2)

# Gráfica 3: Z-score por posición
p3 <- ggplot(position_zscore_stats, aes(x = pos, y = mean_zscore, fill = is_seed_region)) +
  geom_bar(stat = "identity", alpha = 0.8) +
  geom_text(aes(label = count), vjust = -0.5, size = 3) +
  scale_fill_manual(values = c("TRUE" = "#E74C3C", "FALSE" = "#3498DB"),
                    labels = c("TRUE" = "Seed Region", "FALSE" = "Non-Seed Region"),
                    name = "Region Type") +
  labs(title = "Z-score Promedio por Posición (Después de Filtros)",
       x = "Posición en miRNA",
       y = "Z-score Promedio") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold"))

print(p3)

dev.off()

# --- 9. RESUMEN FINAL ---
cat("\n✅ RESUMEN FINAL\n")
cat("================\n")

cat("📁 Archivos generados:\n")
cat("   - outputs/final_paper_graphs/filter_comparison_analysis.pdf\n\n")

cat("📊 RESUMEN DE FILTROS:\n")
cat("   - SNVs G>T iniciales:", nrow(gt_mutations_initial), "\n")
if (!is.null(df_rpm)) {
  cat("   - Después de RPM>1:", nrow(gt_mutations_rpm), "\n")
  cat("   - Pérdida por RPM>1:", nrow(gt_mutations_initial) - nrow(gt_mutations_rpm), 
      "(", round((nrow(gt_mutations_initial) - nrow(gt_mutations_rpm)) / nrow(gt_mutations_initial) * 100, 1), "%)\n")
}
cat("   - Después de VAF>50%:", nrow(gt_mutations_final), "\n")
cat("   - Pérdida por VAF>50%:", nrow(gt_mutations_rpm) - nrow(gt_mutations_final), 
    "(", round((nrow(gt_mutations_rpm) - nrow(gt_mutations_final)) / nrow(gt_mutations_rpm) * 100, 1), "%)\n")
cat("   - Pérdida total:", nrow(gt_mutations_initial) - nrow(gt_mutations_final), 
    "(", round((nrow(gt_mutations_initial) - nrow(gt_mutations_final)) / nrow(gt_mutations_initial) * 100, 1), "%)\n\n")

cat("🎯 POSICIÓN CON MAYOR VAF:", position_zscore_stats$pos[1], 
    "(VAF =", round(position_zscore_stats$mean_vaf[1], 4), ")\n")
cat("🎯 POSICIÓN CON MAYOR Z-SCORE:", position_zscore_stats$pos[which.max(position_zscore_stats$mean_zscore)], 
    "(Z-score =", round(max(position_zscore_stats$mean_zscore, na.rm = TRUE), 4), ")\n\n")

cat("✅ Análisis completado exitosamente!\n")










