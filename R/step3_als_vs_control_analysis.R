#!/usr/bin/env Rscript

# =============================================================================
# PASO 3: ANÁLISIS COMPARATIVO ALS vs CONTROL DESPUÉS DEL FILTRO
# =============================================================================
# - Usar datos procesados con filtro de representación
# - Calcular VAFs promedio para ALS y Control
# - Calcular Z-scores
# - Identificar top miRNAs con diferencias significativas

library(dplyr)
library(readr)
library(stringr)
library(tidyr)

cat("=== PASO 3: ANÁLISIS COMPARATIVO ALS vs CONTROL ===\n\n")

# --- PASO 3.1: Cargar y procesar datos ---
cat("PASO 3.1: Cargando y procesando datos\n")
cat("==========================================\n")

# Cargar datos originales
df_main <- read_tsv("results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt", show_col_types = FALSE)
df_main <- df_main[-1, ]  # Remover metadatos

sample_cols <- names(df_main)[!names(df_main) %in% c("miRNA name", "pos:mut")]
als_samples <- sample_cols[str_detect(sample_cols, "Magen-ALS")]
control_samples <- sample_cols[str_detect(sample_cols, "Magen-control")]

cat(paste0("  - Muestras ALS: ", length(als_samples), "\n"))
cat(paste0("  - Muestras Control: ", length(control_samples), "\n"))

# Aplicar split y collapse
split_mutations <- function(row_data) {
  pos_mut <- row_data$`pos:mut`
  mutations <- str_split(pos_mut, ",")[[1]]
  mutations <- str_trim(mutations)
  
  if (length(mutations) == 1) {
    return(row_data)
  } else {
    result_rows <- list()
    for (mut in mutations) {
      new_row <- row_data
      new_row$`pos:mut` <- mut
      result_rows[[length(result_rows) + 1]] <- new_row
    }
    return(bind_rows(result_rows))
  }
}

df_split_list <- list()
for (i in 1:nrow(df_main)) {
  split_result <- split_mutations(df_main[i, ])
  df_split_list[[length(df_split_list) + 1]] <- split_result
}
df_split <- bind_rows(df_split_list)

df_collapsed <- df_split %>%
  group_by(`miRNA name`, `pos:mut`) %>%
  summarise(
    across(all_of(sample_cols), ~ sum(as.numeric(.x), na.rm = TRUE)),
    .groups = "drop"
  )

# --- PASO 3.2: Aplicar filtro de representación ---
cat("\nPASO 3.2: Aplicando filtro de representación\n")
cat("==========================================\n")

# Convertir a formato largo
df_long <- df_collapsed %>%
  pivot_longer(
    cols = all_of(sample_cols),
    names_to = "sample",
    values_to = "count"
  ) %>%
  mutate(count = as.numeric(count))

# Identificar SNVs con alta representación
high_rep_snvs <- df_long %>%
  group_by(`miRNA name`, `pos:mut`) %>%
  summarise(
    samples_with_count = sum(count > 0, na.rm = TRUE),
    frac_present = samples_with_count / length(sample_cols),
    .groups = "drop"
  ) %>%
  filter(frac_present > 0.5) %>%
  mutate(snv_id = paste(`miRNA name`, `pos:mut`, sep = "_"))

# Aplicar filtro NaN
df_long$snv_id <- paste(df_long$`miRNA name`, df_long$`pos:mut`, sep = "_")
df_filtered_long <- df_long %>%
  mutate(
    count_filtered = ifelse(snv_id %in% high_rep_snvs$snv_id, NA_real_, count)
  )

cat(paste0("  - SNVs con alta representación: ", nrow(high_rep_snvs), "\n"))
cat(paste0("  - Valores convertidos a NaN: ", sum(is.na(df_filtered_long$count_filtered)), "\n"))

# --- PASO 3.3: Filtrar solo G>T y calcular VAFs ---
cat("\nPASO 3.3: Filtrando G>T y calculando VAFs\n")
cat("==========================================\n")

# Filtrar solo G>T
df_gt_filtered <- df_filtered_long %>%
  filter(str_detect(`pos:mut`, "GT")) %>%
  mutate(
    group = ifelse(str_detect(sample, "Magen-ALS"), "ALS", "Control")
  )

# Calcular VAFs promedio por grupo
vaf_summary <- df_gt_filtered %>%
  group_by(`miRNA name`, `pos:mut`, group) %>%
  summarise(
    mean_vaf = mean(count_filtered, na.rm = TRUE),
    median_vaf = median(count_filtered, na.rm = TRUE),
    samples_with_data = sum(!is.na(count_filtered)),
    total_samples = n(),
    .groups = "drop"
  ) %>%
  pivot_wider(
    names_from = group,
    values_from = c(mean_vaf, median_vaf, samples_with_data, total_samples),
    names_sep = "_"
  ) %>%
  mutate(
    mean_vaf_ALS = replace_na(mean_vaf_ALS, 0),
    mean_vaf_Control = replace_na(mean_vaf_Control, 0),
    vaf_difference = mean_vaf_ALS - mean_vaf_Control
  )

cat(paste0("  - SNVs G>T analizados: ", nrow(vaf_summary), "\n"))

# --- PASO 3.4: Calcular Z-scores ---
cat("\nPASO 3.4: Calculando Z-scores\n")
cat("==========================================\n")

# Calcular estadísticas para Z-score
als_values <- df_gt_filtered %>% 
  filter(group == "ALS") %>% 
  pull(count_filtered) %>% 
  .[!is.na(.)]

control_values <- df_gt_filtered %>% 
  filter(group == "Control") %>% 
  pull(count_filtered) %>% 
  .[!is.na(.)]

# Calcular Z-scores usando desviación estándar combinada
pooled_sd <- sqrt(((length(als_values) - 1) * var(als_values) + 
                   (length(control_values) - 1) * var(control_values)) / 
                  (length(als_values) + length(control_values) - 2))

vaf_summary <- vaf_summary %>%
  mutate(
    z_score = (mean_vaf_ALS - mean_vaf_Control) / pooled_sd,
    abs_z_score = abs(z_score)
  )

cat(paste0("  - Desviación estándar combinada: ", round(pooled_sd, 4), "\n"))
cat(paste0("  - Z-scores calculados para ", nrow(vaf_summary), " SNVs G>T\n"))

# --- PASO 3.5: Identificar top miRNAs ---
cat("\nPASO 3.5: Identificando top miRNAs\n")
cat("==========================================\n")

# Top por VAF promedio
top_vaf_als <- vaf_summary %>%
  arrange(desc(mean_vaf_ALS)) %>%
  head(10)

top_vaf_control <- vaf_summary %>%
  arrange(desc(mean_vaf_Control)) %>%
  head(10)

# Top por diferencia de VAF
top_vaf_diff <- vaf_summary %>%
  arrange(desc(vaf_difference)) %>%
  head(10)

# Top por Z-score absoluto
top_zscore <- vaf_summary %>%
  arrange(desc(abs_z_score)) %>%
  head(10)

cat("TOP 10 SNVs G>T POR VAF PROMEDIO ALS:\n")
print(top_vaf_als %>% select(`miRNA name`, `pos:mut`, mean_vaf_ALS, mean_vaf_Control, vaf_difference, z_score))

cat("\nTOP 10 SNVs G>T POR VAF PROMEDIO CONTROL:\n")
print(top_vaf_control %>% select(`miRNA name`, `pos:mut`, mean_vaf_ALS, mean_vaf_Control, vaf_difference, z_score))

cat("\nTOP 10 SNVs G>T POR DIFERENCIA DE VAF (ALS - Control):\n")
print(top_vaf_diff %>% select(`miRNA name`, `pos:mut`, mean_vaf_ALS, mean_vaf_Control, vaf_difference, z_score))

cat("\nTOP 10 SNVs G>T POR Z-SCORE ABSOLUTO:\n")
print(top_zscore %>% select(`miRNA name`, `pos:mut`, mean_vaf_ALS, mean_vaf_Control, vaf_difference, z_score))

# --- PASO 3.6: Análisis de región semilla ---
cat("\nPASO 3.6: Análisis de región semilla\n")
cat("==========================================\n")

# Filtrar región semilla (posiciones 2-8)
seed_analysis <- vaf_summary %>%
  mutate(pos = as.numeric(str_extract(`pos:mut`, "^[0-9]+"))) %>%
  filter(pos >= 2 & pos <= 8) %>%
  arrange(desc(abs_z_score))

cat("TOP 10 SNVs G>T EN REGIÓN SEMILLA POR Z-SCORE:\n")
print(seed_analysis %>% 
      select(`miRNA name`, `pos:mut`, pos, mean_vaf_ALS, mean_vaf_Control, vaf_difference, z_score) %>%
      head(10))

# Estadísticas de región semilla
seed_stats <- seed_analysis %>%
  summarise(
    total_seed_snvs = n(),
    als_higher = sum(vaf_difference > 0),
    control_higher = sum(vaf_difference < 0),
    high_zscore = sum(abs_z_score > 2),
    .groups = "drop"
  )

cat("\nESTADÍSTICAS DE REGIÓN SEMILLA:\n")
cat(paste0("  - Total SNVs G>T en semilla: ", seed_stats$total_seed_snvs, "\n"))
cat(paste0("  - SNVs con VAF mayor en ALS: ", seed_stats$als_higher, "\n"))
cat(paste0("  - SNVs con VAF mayor en Control: ", seed_stats$control_higher, "\n"))
cat(paste0("  - SNVs con |Z-score| > 2: ", seed_stats$high_zscore, "\n"))

# --- PASO 3.7: Resumen final ---
cat("\nPASO 3.7: Resumen final\n")
cat("==========================================\n")

cat("RESULTADOS DEL ANÁLISIS COMPARATIVO ALS vs CONTROL:\n")
cat(paste0("- SNVs G>T analizados: ", nrow(vaf_summary), "\n"))
cat(paste0("- SNVs G>T en región semilla: ", nrow(seed_analysis), "\n"))
cat(paste0("- VAF promedio ALS: ", round(mean(vaf_summary$mean_vaf_ALS, na.rm = TRUE), 4), "\n"))
cat(paste0("- VAF promedio Control: ", round(mean(vaf_summary$mean_vaf_Control, na.rm = TRUE), 4), "\n"))
cat(paste0("- Z-score promedio: ", round(mean(vaf_summary$z_score, na.rm = TRUE), 4), "\n"))
cat(paste0("- Z-score máximo: ", round(max(vaf_summary$abs_z_score, na.rm = TRUE), 4), "\n\n"))

cat("SNV G>T CON MAYOR DIFERENCIA (ALS - Control):\n")
top_diff <- vaf_summary %>% arrange(desc(vaf_difference)) %>% head(1)
print(top_diff %>% select(`miRNA name`, `pos:mut`, mean_vaf_ALS, mean_vaf_Control, vaf_difference, z_score))

cat("\nSNV G>T CON MAYOR Z-SCORE ABSOLUTO:\n")
top_z <- vaf_summary %>% arrange(desc(abs_z_score)) %>% head(1)
print(top_z %>% select(`miRNA name`, `pos:mut`, mean_vaf_ALS, mean_vaf_Control, vaf_difference, z_score))

cat("\n=== PASO 3 COMPLETADO ===\n")










