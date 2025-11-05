# =============================================================================
# ANÁLISIS FINAL POSICIÓN 6 - MUTACIONES G>T
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

cat("🔬 ANÁLISIS FINAL POSICIÓN 6 - MUTACIONES G>T\n")
cat("=============================================\n\n")

# --- 1. CARGAR DATOS CORRECTOS ---
cat("📊 1. CARGANDO DATOS CORRECTOS\n")
cat("=============================\n")

# Cargar el archivo correcto
df_main <- read_tsv("results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt", col_names = FALSE)

# Obtener la primera fila como nombres de columnas
header_row <- df_main[1, ]
colnames(df_main) <- as.character(header_row)

# Eliminar la primera fila que ahora son los nombres de columnas
df_main <- df_main[-1, ]

# Identificar columnas de muestras (excluyendo miRNA name y pos:mut)
sample_cols <- names(df_main)[!names(df_main) %in% c("miRNA name", "pos:mut")]

# Identificar muestras ALS y Control
als_samples <- sample_cols[str_detect(sample_cols, "Magen-ALS")]
control_samples <- sample_cols[str_detect(sample_cols, "Magen-control")]

cat(paste0("  - Datos cargados: miRNA_count.Q33.txt (", nrow(df_main), " filas)\n"))
cat(paste0("  - Muestras totales: ", length(sample_cols), "\n"))
cat(paste0("  - Muestras ALS: ", length(als_samples), "\n"))
cat(paste0("  - Muestras Control: ", length(control_samples), "\n\n"))

# --- 2. FILTRAR MUTACIONES G>T EN POSICIÓN 6 ---
cat("🧬 2. FILTRANDO MUTACIONES G>T EN POSICIÓN 6\n")
cat("===========================================\n")

# Filtrar solo mutaciones G>T en posición 6
gt_pos6_mutations <- df_main %>%
  filter(str_detect(`pos:mut`, "^6:GT")) %>%
  mutate(
    miRNA_name = `miRNA name`,
    pos_mut = `pos:mut`,
    pos = 6,
    mutation_type = "GT"
  )

cat(paste0("  - SNVs G>T en posición 6 encontrados: ", nrow(gt_pos6_mutations), "\n"))
cat(paste0("  - miRNAs únicos afectados: ", length(unique(gt_pos6_mutations$miRNA_name)), "\n\n"))

# --- 3. CALCULAR ESTADÍSTICAS DETALLADAS ---
cat("📊 3. CALCULANDO ESTADÍSTICAS DETALLADAS\n")
cat("=======================================\n")

# Convertir columnas de muestras a numérico
for (col in sample_cols) {
  gt_pos6_mutations[[col]] <- as.numeric(gt_pos6_mutations[[col]])
}

# Calcular VAF promedio por SNV y por grupo
gt_pos6_stats <- gt_pos6_mutations %>%
  rowwise() %>%
  mutate(
    mean_vaf_als = mean(c_across(all_of(als_samples)), na.rm = TRUE),
    mean_vaf_control = mean(c_across(all_of(control_samples)), na.rm = TRUE),
    total_vaf_als = sum(c_across(all_of(als_samples)), na.rm = TRUE),
    total_vaf_control = sum(c_across(all_of(control_samples)), na.rm = TRUE)
  ) %>%
  ungroup() %>%
  mutate(
    mean_vaf_als = ifelse(is.nan(mean_vaf_als), 0, mean_vaf_als),
    mean_vaf_control = ifelse(is.nan(mean_vaf_control), 0, mean_vaf_control)
  )

# Calcular Z-scores
z_scores <- apply(gt_pos6_mutations[, sample_cols], 1, function(row) {
  als_vals <- row[colnames(gt_pos6_mutations[, sample_cols]) %in% als_samples]
  control_vals <- row[colnames(gt_pos6_mutations[, sample_cols]) %in% control_samples]
  
  # Eliminar NAs y valores cero para el cálculo de la desviación estándar
  als_vals_clean <- als_vals[als_vals > 0]
  control_vals_clean <- control_vals[control_vals > 0]
  
  if (length(als_vals_clean) < 2 || length(control_vals_clean) < 2) {
    return(NA)
  }
  
  mean_als <- mean(als_vals_clean)
  mean_control <- mean(control_vals_clean)
  sd_als <- sd(als_vals_clean)
  sd_control <- sd(control_vals_clean)
  
  pooled_sd <- sqrt(((length(als_vals_clean) - 1) * sd_als^2 + (length(control_vals_clean) - 1) * sd_control^2) /
                      (length(als_vals_clean) + length(control_vals_clean) - 2))
  
  if (pooled_sd == 0) {
    return(0)
  }
  
  (mean_als - mean_control) / pooled_sd
})

gt_pos6_stats$z_score <- z_scores
gt_pos6_stats$z_score[is.na(gt_pos6_stats$z_score)] <- 0

# Estadísticas globales
total_snvs_pos6 <- nrow(gt_pos6_mutations)
mean_vaf_als_global <- mean(gt_pos6_stats$mean_vaf_als, na.rm = TRUE)
mean_vaf_control_global <- mean(gt_pos6_stats$mean_vaf_control, na.rm = TRUE)
mean_z_score_global <- mean(gt_pos6_stats$z_score, na.rm = TRUE)

cat(paste0("  - SNVs G>T en posición 6: ", total_snvs_pos6, "\n"))
cat(paste0("  - VAF promedio global (ALS): ", round(mean_vaf_als_global, 2), "\n"))
cat(paste0("  - VAF promedio global (Control): ", round(mean_vaf_control_global, 2), "\n"))
cat(paste0("  - Diferencia VAF promedio (ALS - Control): ", round(mean_vaf_als_global - mean_vaf_control_global, 2), "\n"))
cat(paste0("  - Porcentaje de diferencia: ", round(((mean_vaf_als_global - mean_vaf_control_global) / mean_vaf_control_global) * 100, 2), "%\n"))
cat(paste0("  - Z-score promedio: ", round(mean_z_score_global, 4), "\n\n"))

# --- 4. TOP miRNAs POR VAF ---
cat("🏆 4. TOP miRNAs POR VAF\n")
cat("========================\n")

# Top 5 miRNAs con mayor VAF total en ALS
top_als <- gt_pos6_stats %>%
  arrange(desc(total_vaf_als)) %>%
  slice_head(n = 5) %>%
  select(miRNA_name, total_vaf_als, mean_vaf_als, z_score)

cat("Top 5 miRNAs con mayor VAF total en ALS:\n")
print(top_als)
cat("\n")

# Top 5 miRNAs con mayor VAF total en Control
top_control <- gt_pos6_stats %>%
  arrange(desc(total_vaf_control)) %>%
  slice_head(n = 5) %>%
  select(miRNA_name, total_vaf_control, mean_vaf_control, z_score)

cat("Top 5 miRNAs con mayor VAF total en Control:\n")
print(top_control)
cat("\n")

# --- 5. GENERAR GRÁFICAS ---
cat("📈 5. GENERANDO GRÁFICAS\n")
cat("=======================\n")

# Gráfica de VAF promedio por grupo
plot_vaf_comparison <- ggplot(gt_pos6_stats, aes(x = mean_vaf_als, y = mean_vaf_control)) +
  geom_point(alpha = 0.6, color = "darkblue") +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "red") +
  labs(
    title = "VAF Promedio: ALS vs Control (Posición 6, G>T)",
    x = "VAF Promedio ALS",
    y = "VAF Promedio Control",
    subtitle = paste0("609 SNVs G>T en posición 6")
  ) +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5))

# Gráfica de Z-score
plot_zscore <- ggplot(gt_pos6_stats, aes(x = z_score)) +
  geom_histogram(bins = 30, fill = "darkgreen", alpha = 0.7) +
  labs(
    title = "Distribución de Z-scores (Posición 6, G>T)",
    x = "Z-score",
    y = "Frecuencia",
    subtitle = paste0("Z-score promedio: ", round(mean_z_score_global, 4))
  ) +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5))

# Guardar gráficas
output_dir <- "outputs/final_paper_graphs/"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

ggsave(paste0(output_dir, "position_6_vaf_comparison_final.pdf"), plot_vaf_comparison, width = 10, height = 6)
ggsave(paste0(output_dir, "position_6_zscore_distribution_final.pdf"), plot_zscore, width = 10, height = 6)

cat(paste0("  - Gráficas guardadas en: ", output_dir, "\n"))
cat("    - position_6_vaf_comparison_final.pdf\n")
cat("    - position_6_zscore_distribution_final.pdf\n\n")

# --- 6. RESUMEN FINAL ---
cat("✅ RESUMEN FINAL POSICIÓN 6\n")
cat("===========================\n")
cat(paste0("Total SNVs G>T en posición 6: ", total_snvs_pos6, "\n"))
cat(paste0("miRNAs únicos afectados: ", length(unique(gt_pos6_mutations$miRNA_name)), "\n"))
cat(paste0("VAF promedio ALS: ", round(mean_vaf_als_global, 2), "\n"))
cat(paste0("VAF promedio Control: ", round(mean_vaf_control_global, 2), "\n"))
cat(paste0("Z-score promedio: ", round(mean_z_score_global, 4), "\n"))
cat(paste0("Diferencia VAF (ALS - Control): ", round(mean_vaf_als_global - mean_vaf_control_global, 2), "\n"))

cat("\n✅ ANÁLISIS POSICIÓN 6 COMPLETADO.\n")
