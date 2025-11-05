library(dplyr)
library(readr)
library(stringr)
library(tidyr)
library(ggplot2)
library(tibble)

# --- ANÁLISIS DETALLADO PASO A PASO - POSICIÓN 6 (CORREGIDO) ---
cat("=== ANÁLISIS DETALLADO PASO A PASO - POSICIÓN 6 (CORREGIDO) ===\n\n")

# --- PASO 1: Cargando datos ---
cat("PASO 1: Cargando datos\n")
cat("==========================================\n")
file_path <- "results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt"
df_main <- read_tsv(file_path, show_col_types = FALSE)
cat(paste0("  - Archivo cargado: ", basename(file_path), "\n"))
cat(paste0("  - Dimensiones originales: ", nrow(df_main), " filas x ", ncol(df_main), " columnas\n"))

# Remover la primera fila que contiene "PM" (metadatos)
df_main <- df_main[-1, ]
cat(paste0("  - Después de remover metadatos: ", nrow(df_main), " filas x ", ncol(df_main), " columnas\n"))

# Identificar columnas de muestras
sample_cols <- names(df_main)[!names(df_main) %in% c("miRNA name", "pos:mut")]
als_samples <- sample_cols[str_detect(sample_cols, "Magen-ALS")]
control_samples <- sample_cols[str_detect(sample_cols, "Magen-control")]

cat(paste0("  - Columnas de muestras: ", length(sample_cols), "\n"))
cat(paste0("  - Muestras ALS: ", length(als_samples), "\n"))
cat(paste0("  - Muestras Control: ", length(control_samples), "\n\n"))

# --- PASO 2: Filtrando mutaciones G>T en posición 6 ---
cat("PASO 2: Filtrando mutaciones G>T en posición 6\n")
cat("==========================================\n")
df_pos6_gt <- df_main %>%
  filter(str_detect(`pos:mut`, "^6:GT"))

cat(paste0("  - SNVs G>T en posición 6 encontrados: ", nrow(df_pos6_gt), "\n"))
cat("  - Primeros 5 SNVs encontrados:\n")
print(head(df_pos6_gt %>% select(`miRNA name`, `pos:mut`), 5))

unique_mirnas_pos6 <- unique(df_pos6_gt$`miRNA name`)
cat(paste0("  - miRNAs únicos con G>T en posición 6: ", length(unique_mirnas_pos6), "\n"))
cat("  - Primeros 10 miRNAs:\n")
print(head(unique_mirnas_pos6, 10))
cat("\n")

# --- PASO 3: Entendiendo la estructura de datos ---
cat("PASO 3: Entendiendo la estructura de datos\n")
cat("==========================================\n")
cat("  - Las columnas de muestra contienen conteos PM (Perfect Match)\n")
cat("  - Para calcular VAF necesitamos: VAF = PM / (PM + 1MM + 2MM)\n")
cat("  - Pero este archivo solo tiene PM, no 1MM ni 2MM\n")
cat("  - Por lo tanto, usaremos los conteos PM directamente como 'intensidad'\n")
cat("  - Esto es equivalente a asumir VAF = 1 para todas las mutaciones detectadas\n\n")

# --- PASO 4: Calculando 'VAFs' (usando conteos PM) ---
cat("PASO 4: Calculando 'VAFs' (usando conteos PM como proxy)\n")
cat("==========================================\n")

if (nrow(df_pos6_gt) == 0) {
  cat("  - No hay SNVs G>T en posición 6 para calcular VAFs.\n\n")
} else {
  # Transformar a formato largo
  df_long <- df_pos6_gt %>%
    pivot_longer(
      cols = all_of(sample_cols),
      names_to = "sample",
      values_to = "pm_count"
    ) %>%
    mutate(
      feature = paste(`miRNA name`, `pos:mut`, sep = "_"),
      pm_count = as.numeric(pm_count)
    ) %>%
    filter(!is.na(pm_count))  # Filtrar NAs

  # Convertir a formato ancho para la matriz
  df_vaf_wide <- df_long %>%
    select(feature, sample, pm_count) %>%
    pivot_wider(names_from = sample, values_from = pm_count, values_fill = 0)

  if (nrow(df_vaf_wide) > 0) {
    cat(paste0("  - 'VAFs' calculados para ", ncol(df_vaf_wide) - 1, " muestras\n"))
    cat("  - Primeras 5 filas de 'VAFs' (formato ancho):\n")
    print(head(df_vaf_wide, 5))
    cat("\n")

    # Convertir a matriz para cálculos
    df_vaf_wide_unique <- df_vaf_wide %>%
      mutate(feature_unique = make.unique(feature)) %>%
      column_to_rownames("feature_unique")

    vaf_matrix <- as.matrix(df_vaf_wide_unique %>% select(-feature))

    # --- PASO 5: Calculando VAFs promedio por grupo ---
    cat("PASO 5: Calculando VAFs promedio por grupo (ALS vs Control)\n")
    cat("==========================================\n")

    # Asegurarse de que las muestras existan en la matriz
    als_samples_in_matrix <- intersect(als_samples, colnames(vaf_matrix))
    control_samples_in_matrix <- intersect(control_samples, colnames(vaf_matrix))

    if (length(als_samples_in_matrix) > 0 && length(control_samples_in_matrix) > 0) {
      vaf_als <- rowMeans(vaf_matrix[, als_samples_in_matrix, drop = FALSE], na.rm = TRUE)
      vaf_control <- rowMeans(vaf_matrix[, control_samples_in_matrix, drop = FALSE], na.rm = TRUE)

      df_vaf_summary <- tibble(
        feature = rownames(vaf_matrix),
        VAF_ALS_Avg = vaf_als,
        VAF_Control_Avg = vaf_control
      )
      cat("  - VAFs promedio por grupo calculados:\n")
      print(head(df_vaf_summary, 5))
      cat("\n")

      # --- PASO 6: Calculando Z-scores ---
      cat("PASO 6: Calculando Z-scores\n")
      cat("==========================================\n")

      # Función para calcular Z-score (pooled standard deviation)
      calculate_zscore <- function(als_values, control_values) {
        mean_als <- mean(als_values, na.rm = TRUE)
        mean_control <- mean(control_values, na.rm = TRUE)
        sd_als <- sd(als_values, na.rm = TRUE)
        sd_control <- sd(control_values, na.rm = TRUE)
        n_als <- sum(!is.na(als_values))
        n_control <- sum(!is.na(control_values))

        if (n_als < 2 || n_control < 2) {
          return(NA)
        }

        pooled_sd <- sqrt(((n_als - 1) * sd_als^2 + (n_control - 1) * sd_control^2) / (n_als + n_control - 2))

        if (pooled_sd == 0) {
          return(0)
        }

        z_score <- (mean_als - mean_control) / pooled_sd
        return(z_score)
      }

      z_scores <- apply(vaf_matrix, 1, function(row_vals) {
        als_vals <- row_vals[als_samples_in_matrix]
        control_vals <- row_vals[control_samples_in_matrix]
        calculate_zscore(als_vals, control_vals)
      })

      df_zscore_summary <- tibble(
        feature = names(z_scores),
        Z_score = z_scores
      ) %>%
        left_join(df_vaf_summary, by = "feature") %>%
        arrange(desc(abs(Z_score)))

      cat("  - Z-scores calculados (primeros 5 por valor absoluto):\n")
      print(head(df_zscore_summary, 5))
      cat("\n")

      # --- PASO 7: Identificando Top miRNAs ---
      cat("PASO 7: Identificando Top miRNAs\n")
      cat("==========================================\n")

      # Top miRNAs por VAF promedio en ALS
      top_mirnas_als_vaf <- df_zscore_summary %>%
        arrange(desc(VAF_ALS_Avg)) %>%
        head(10) %>%
        select(feature, VAF_ALS_Avg)
      cat("  - Top 10 miRNAs por VAF promedio en ALS:\n")
      print(top_mirnas_als_vaf)
      cat("\n")

      # Top miRNAs por VAF promedio en Control
      top_mirnas_control_vaf <- df_zscore_summary %>%
        arrange(desc(VAF_Control_Avg)) %>%
        head(10) %>%
        select(feature, VAF_Control_Avg)
      cat("  - Top 10 miRNAs por VAF promedio en Control:\n")
      print(top_mirnas_control_vaf)
      cat("\n")

      # Top miRNAs por Z-score (mayor diferencia)
      top_mirnas_zscore <- df_zscore_summary %>%
        arrange(desc(abs(Z_score))) %>%
        head(10) %>%
        select(feature, Z_score, VAF_ALS_Avg, VAF_Control_Avg)
      cat("  - Top 10 miRNAs por Z-score (mayor diferencia entre grupos):\n")
      print(top_mirnas_zscore)
      cat("\n")

      # --- PASO 8: Resumen Final de Estadísticas para Posición 6 ---
      cat("PASO 8: Resumen Final de Estadísticas para Posición 6\n")
      cat("==========================================\n")

      total_snvs_pos6 <- nrow(df_pos6_gt)
      unique_mirnas_pos6_count <- length(unique_mirnas_pos6)
      avg_vaf_als_overall <- mean(df_zscore_summary$VAF_ALS_Avg, na.rm = TRUE)
      avg_vaf_control_overall <- mean(df_zscore_summary$VAF_Control_Avg, na.rm = TRUE)
      avg_zscore_overall <- mean(df_zscore_summary$Z_score, na.rm = TRUE)

      cat(paste0("  - Número total de SNVs G>T en posición 6: ", total_snvs_pos6, "\n"))
      cat(paste0("  - Número de miRNAs únicos con G>T en posición 6: ", unique_mirnas_pos6_count, "\n"))
      cat(paste0("  - VAF promedio general en ALS para posición 6: ", round(avg_vaf_als_overall, 4), "\n"))
      cat(paste0("  - VAF promedio general en Control para posición 6: ", round(avg_vaf_control_overall, 4), "\n"))
      cat(paste0("  - Z-score promedio general para posición 6: ", round(avg_zscore_overall, 4), "\n"))
      cat("\n")

      # --- PASO 9: Análisis de Significancia ---
      cat("PASO 9: Análisis de Significancia\n")
      cat("==========================================\n")
      
      # Contar SNVs con Z-score > 1.96 (p < 0.05, aproximadamente)
      significant_snvs <- df_zscore_summary %>%
        filter(abs(Z_score) > 1.96) %>%
        nrow()
      
      cat(paste0("  - SNVs con |Z-score| > 1.96 (significativos): ", significant_snvs, "\n"))
      cat(paste0("  - Porcentaje de SNVs significativos: ", round(100 * significant_snvs / nrow(df_zscore_summary), 2), "%\n"))
      
      # Mostrar los más significativos
      most_significant <- df_zscore_summary %>%
        filter(abs(Z_score) > 1.96) %>%
        arrange(desc(abs(Z_score))) %>%
        head(5)
      
      if (nrow(most_significant) > 0) {
        cat("  - Top 5 SNVs más significativos:\n")
        print(most_significant)
      }
      cat("\n")

    } else {
      cat("  - ERROR: No se encontraron suficientes muestras ALS o Control en la matriz VAF para calcular promedios y Z-scores.\n\n")
    }
  } else {
    cat("  - ERROR: No se pudieron calcular VAFs para ninguna muestra.\n\n")
  }
}

cat("=== ANÁLISIS COMPLETADO ===\n")
