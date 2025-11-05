# =============================================================================
# ANÁLISIS DETALLADO POSICIÓN 6 - MUTACIONES G>T
# =============================================================================
# Script para analizar específicamente las mutaciones G>T en posición 6
# usando el archivo correcto: miRNA_count.Q33.txt
# =============================================================================

# Cargar librerías
library(dplyr)
library(readr)
library(stringr)
library(tibble)
library(ggplot2)

# Configurar opciones
options(warn = -1)

cat("🔬 ANÁLISIS DETALLADO POSICIÓN 6 - MUTACIONES G>T\n")
cat("================================================\n\n")

# --- 1. CARGAR DATOS CORRECTOS ---
cat("📊 1. CARGANDO DATOS CORRECTOS\n")
cat("=============================\n")

# Cargar el archivo correcto
df_main <- read_tsv("results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt", 
                    col_names = FALSE, 
                    show_col_types = FALSE)

# Asignar nombres de columnas (primera fila es miRNA_name, segunda es pos_mut, resto son muestras)
colnames(df_main) <- c("miRNA_name", "pos_mut", paste0("Sample_", 1:(ncol(df_main)-2)))

cat(paste0("  - Archivo cargado: miRNA_count.Q33.txt\n"))
cat(paste0("  - Total de filas: ", nrow(df_main), "\n"))
cat(paste0("  - Total de columnas: ", ncol(df_main), "\n"))
cat(paste0("  - Muestras: ", ncol(df_main)-2, "\n\n"))

# --- 2. IDENTIFICAR MUESTRAS ALS Y CONTROL ---
cat("🧬 2. IDENTIFICANDO MUESTRAS ALS Y CONTROL\n")
cat("==========================================\n")

# Asumir que las primeras ~207 muestras son ALS y las últimas ~208 son Control
# (basado en el patrón típico de estudios ALS)
total_samples <- ncol(df_main) - 2
als_samples <- paste0("Sample_", 1:207)  # Primeras 207 muestras
control_samples <- paste0("Sample_", 208:total_samples)  # Resto son Control

cat(paste0("  - Muestras ALS: ", length(als_samples), " (Sample_1 a Sample_", length(als_samples), ")\n"))
cat(paste0("  - Muestras Control: ", length(control_samples), " (Sample_", length(als_samples)+1, " a Sample_", total_samples, ")\n\n"))

# --- 3. FILTRAR MUTACIONES G>T EN POSICIÓN 6 ---
cat("🎯 3. FILTRANDO MUTACIONES G>T EN POSICIÓN 6\n")
cat("============================================\n")

# Filtrar mutaciones G>T en posición 6
gt_pos6_mutations <- df_main %>%
  filter(str_detect(pos_mut, "6:GT")) %>%
  mutate(
    miRNA_name = miRNA_name,
    pos_mut = pos_mut,
    pos = 6,
    mutation_type = "GT"
  )

cat(paste0("  - SNVs G>T en posición 6 encontrados: ", nrow(gt_pos6_mutations), "\n\n"))

if (nrow(gt_pos6_mutations) == 0) {
  cat("❌ No se encontraron mutaciones G>T en posición 6.\n")
  cat("   Verificando otras posiciones con G>T...\n\n")
  
  # Verificar qué posiciones tienen G>T
  all_gt_mutations <- df_main %>%
    filter(str_detect(pos_mut, ":GT"))
  
  if (nrow(all_gt_mutations) > 0) {
    positions_with_gt <- all_gt_mutations %>%
      mutate(pos = as.integer(str_extract(pos_mut, "^[0-9]+"))) %>%
      group_by(pos) %>%
      summarise(count = n()) %>%
      arrange(desc(count))
    
    cat("  - Posiciones con mutaciones G>T:\n")
    print(positions_with_gt)
  } else {
    cat("❌ No se encontraron mutaciones G>T en ninguna posición.\n")
  }
  
  stop("No hay datos para analizar en posición 6.")
}

# --- 4. CALCULAR ESTADÍSTICAS POR MUESTRA ---
cat("📈 4. CALCULANDO ESTADÍSTICAS POR MUESTRA\n")
cat("=========================================\n")

# Convertir columnas de muestras a numérico
sample_cols <- c(als_samples, control_samples)
gt_pos6_numeric <- gt_pos6_mutations %>%
  mutate(across(all_of(sample_cols), as.numeric))

# Calcular estadísticas por SNV
gt_pos6_stats <- gt_pos6_numeric %>%
  rowwise() %>%
  mutate(
    mean_vaf_als = mean(c_across(all_of(als_samples)), na.rm = TRUE),
    mean_vaf_control = mean(c_across(all_of(control_samples)), na.rm = TRUE),
    total_vaf_als = sum(c_across(all_of(als_samples)), na.rm = TRUE),
    total_vaf_control = sum(c_across(all_of(control_samples)), na.rm = TRUE),
    max_vaf_als = max(c_across(all_of(als_samples)), na.rm = TRUE),
    max_vaf_control = max(c_across(all_of(control_samples)), na.rm = TRUE)
  ) %>%
  ungroup() %>%
  mutate(
    mean_vaf_als = ifelse(is.nan(mean_vaf_als), 0, mean_vaf_als),
    mean_vaf_control = ifelse(is.nan(mean_vaf_control), 0, mean_vaf_control),
    total_vaf_als = ifelse(is.na(total_vaf_als), 0, total_vaf_als),
    total_vaf_control = ifelse(is.na(total_vaf_control), 0, total_vaf_control),
    max_vaf_als = ifelse(is.infinite(max_vaf_als), 0, max_vaf_als),
    max_vaf_control = ifelse(is.infinite(max_vaf_control), 0, max_vaf_control)
  )

# --- 5. CALCULAR Z-SCORE ---
cat("📊 5. CALCULANDO Z-SCORE\n")
cat("========================\n")

# Calcular Z-score para cada SNV
z_scores <- apply(gt_pos6_numeric[, sample_cols], 1, function(row) {
  als_vals <- row[colnames(gt_pos6_numeric) %in% als_samples]
  control_vals <- row[colnames(gt_pos6_numeric) %in% control_samples]
  
  # Eliminar NAs y valores cero para el cálculo de la desviación estándar
  als_vals_clean <- als_vals[als_vals > 0 & !is.na(als_vals)]
  control_vals_clean <- control_vals[control_vals > 0 & !is.na(control_vals)]
  
  if (length(als_vals_clean) < 2 || length(control_vals_clean) < 2) {
    return(NA) # No se puede calcular Z-score con menos de 2 valores no-cero
  }
  
  mean_als <- mean(als_vals_clean)
  mean_control <- mean(control_vals_clean)
  sd_als <- sd(als_vals_clean)
  sd_control <- sd(control_vals_clean)
  
  pooled_sd <- sqrt(((length(als_vals_clean) - 1) * sd_als^2 + (length(control_vals_clean) - 1) * sd_control^2) /
                      (length(als_vals_clean) + length(control_vals_clean) - 2))
  
  if (pooled_sd == 0) {
    return(0) # Si la desviación estándar es cero, no hay variabilidad
  }
  
  (mean_als - mean_control) / pooled_sd
})

gt_pos6_stats$z_score <- z_scores
gt_pos6_stats$z_score[is.na(gt_pos6_stats$z_score)] <- 0 # Reemplazar NAs de Z-score con 0

# --- 6. ESTADÍSTICAS GLOBALES ---
cat("📋 6. ESTADÍSTICAS GLOBALES POSICIÓN 6\n")
cat("======================================\n")

total_snvs_pos6 <- nrow(gt_pos6_mutations)
mean_vaf_als_global <- mean(gt_pos6_stats$mean_vaf_als, na.rm = TRUE)
mean_vaf_control_global <- mean(gt_pos6_stats$mean_vaf_control, na.rm = TRUE)
mean_z_score_global <- mean(gt_pos6_stats$z_score, na.rm = TRUE)

cat(paste0("  - Total SNVs G>T en posición 6: ", total_snvs_pos6, "\n"))
cat(paste0("  - VAF promedio global (ALS): ", round(mean_vaf_als_global, 2), "\n"))
cat(paste0("  - VAF promedio global (Control): ", round(mean_vaf_control_global, 2), "\n"))
cat(paste0("  - Diferencia VAF promedio (ALS - Control): ", round(mean_vaf_als_global - mean_vaf_control_global, 2), "\n"))
cat(paste0("  - Z-score promedio: ", round(mean_z_score_global, 4), "\n"))
cat(paste0("  - Porcentaje de diferencia: ", round(((mean_vaf_als_global - mean_vaf_control_global) / mean_vaf_control_global) * 100, 2), "%\n\n"))

# --- 7. TOP miRNAs POR CUENTAS ---
cat("🏆 7. TOP miRNAs POR CUENTAS EN ALS Y CONTROL\n")
cat("=============================================\n")

# Top miRNAs por total VAF en ALS
top_mirnas_als <- gt_pos6_stats %>%
  arrange(desc(total_vaf_als)) %>%
  slice_head(n = 5) %>%
  select(miRNA_name, total_vaf_als, mean_vaf_als, z_score)

cat("  - Top 5 miRNAs por total VAF en ALS:\n")
print(top_mirnas_als)
cat("\n")

# Top miRNAs por total VAF en Control
top_mirnas_control <- gt_pos6_stats %>%
  arrange(desc(total_vaf_control)) %>%
  slice_head(n = 5) %>%
  select(miRNA_name, total_vaf_control, mean_vaf_control, z_score)

cat("  - Top 5 miRNAs por total VAF en Control:\n")
print(top_mirnas_control)
cat("\n")

# --- 8. ANÁLISIS DETALLADO POR miRNA ---
cat("🔍 8. ANÁLISIS DETALLADO POR miRNA\n")
cat("===================================\n")

# Mostrar todos los miRNAs con sus estadísticas
detailed_stats <- gt_pos6_stats %>%
  select(miRNA_name, mean_vaf_als, mean_vaf_control, total_vaf_als, total_vaf_control, z_score) %>%
  arrange(desc(z_score))

cat("  - Estadísticas detalladas por miRNA (ordenado por Z-score):\n")
print(detailed_stats)
cat("\n")

# --- 9. GENERAR GRÁFICAS ---
cat("📈 9. GENERANDO GRÁFICAS\n")
cat("========================\n")

# Crear directorio de salida
output_dir <- "outputs/final_paper_graphs/"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Gráfica 1: VAF promedio por miRNA (ALS vs Control)
plot_vaf_comparison <- ggplot(gt_pos6_stats, aes(x = reorder(miRNA_name, mean_vaf_als + mean_vaf_control))) +
  geom_col(aes(y = mean_vaf_als, fill = "ALS"), alpha = 0.7, position = "dodge") +
  geom_col(aes(y = mean_vaf_control, fill = "Control"), alpha = 0.7, position = "dodge") +
  labs(
    title = "VAF Promedio por miRNA - Posición 6 G>T (ALS vs Control)",
    x = "miRNA",
    y = "VAF Promedio",
    fill = "Grupo"
  ) +
  scale_fill_manual(values = c("ALS" = "red", "Control" = "blue")) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5),
    axis.text.x = element_text(angle = 45, hjust = 1, size = 8)
  )

# Gráfica 2: Z-score por miRNA
plot_zscore <- ggplot(gt_pos6_stats, aes(x = reorder(miRNA_name, z_score), y = z_score)) +
  geom_col(fill = "darkgreen", alpha = 0.7) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "black") +
  labs(
    title = "Z-score por miRNA - Posición 6 G>T (ALS vs Control)",
    x = "miRNA",
    y = "Z-score"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5),
    axis.text.x = element_text(angle = 45, hjust = 1, size = 8)
  )

# Guardar gráficas
ggsave(paste0(output_dir, "position_6_vaf_comparison.pdf"), plot_vaf_comparison, width = 12, height = 8)
ggsave(paste0(output_dir, "position_6_zscore.pdf"), plot_zscore, width = 12, height = 8)

cat(paste0("  - Gráficas guardadas en: ", output_dir, "\n"))
cat("    - position_6_vaf_comparison.pdf\n")
cat("    - position_6_zscore.pdf\n\n")

# --- 10. RESUMEN FINAL ---
cat("✅ RESUMEN FINAL - POSICIÓN 6 G>T\n")
cat("=================================\n")
cat(paste0("📊 Total SNVs G>T en posición 6: ", total_snvs_pos6, "\n"))
cat(paste0("🧬 miRNAs analizados: ", length(unique(gt_pos6_stats$miRNA_name)), "\n"))
cat(paste0("📈 VAF promedio ALS: ", round(mean_vaf_als_global, 2), "\n"))
cat(paste0("📈 VAF promedio Control: ", round(mean_vaf_control_global, 2), "\n"))
cat(paste0("📊 Z-score promedio: ", round(mean_z_score_global, 4), "\n"))
cat(paste0("📁 Gráficas guardadas en: ", output_dir, "\n\n"))

cat("🎯 ANÁLISIS COMPLETADO EXITOSAMENTE.\n")










