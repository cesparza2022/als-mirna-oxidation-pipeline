# --- ANÁLISIS VERSIÓN 2: 4,472 SNVs ---
# Análisis con datos preprocesados sin filtros adicionales innecesarios

# --- LIBRERÍAS ---
library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(ComplexHeatmap)
library(circlize)
library(viridis)
library(RColorBrewer)
library(reshape2)
library(stats)

# --- CONFIGURACIÓN ---
cat("🔬 ANÁLISIS VERSIÓN 2: 4,472 SNVs\n")
cat("==================================\n\n")

# --- 1. CARGANDO DATOS PREPROCESADOS ---
cat("📊 1. CARGANDO DATOS PREPROCESADOS\n")
cat("==================================\n")

# Cargar datos del preprocesamiento
processed_data_path <- "../processed_data/processed_snvs_gt.csv"
df_processed <- read.csv(processed_data_path, stringsAsFactors = FALSE)

# Cargar metadatos de muestras
sample_metadata <- read.csv("../tables/sample_metadata.csv", stringsAsFactors = FALSE)

cat(paste0("   - SNVs procesados: ", nrow(df_processed), "\n"))
cat(paste0("   - miRNAs únicos: ", length(unique(df_processed$miRNA_name)), "\n"))
cat(paste0("   - Muestras: ", nrow(sample_metadata), "\n\n"))

# --- 2. PREPARANDO DATOS CON POSICIONES ---
cat("🔍 2. PREPARANDO DATOS CON POSICIONES\n")
cat("=====================================\n")

df_with_positions <- df_processed %>%
  filter(!is.na(pos), !is.na(mutation_type)) %>%
  rename(position = pos) %>%
  mutate(
    region = ifelse(position >= 2 & position <= 8, "Seed", "Non-seed"),
    region_detailed = case_when(
      position >= 2 & position <= 8 ~ "Seed region",
      position >= 1 & position <= 1 ~ "5' end",
      position >= 9 & position <= 12 ~ "Central region",
      position >= 13 & position <= 16 ~ "3' region",
      position >= 17 & position <= 23 ~ "3' end",
      TRUE ~ "Unknown"
    )
  )

cat(paste0("   - SNVs con posiciones: ", nrow(df_with_positions), "\n"))
cat(paste0("   - miRNAs únicos: ", length(unique(df_with_positions$miRNA_name)), "\n"))
cat(paste0("   - Posiciones únicas: ", length(unique(df_with_positions$position)), "\n\n"))

# --- 3. CALCULANDO VAFs ---
cat("🧮 3. CALCULANDO VAFs\n")
cat("=====================\n")

# Cargar las columnas originales para el cálculo de VAF
df_original_cols <- read.csv("../../results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt", sep="\t", stringsAsFactors = FALSE)
total_cols_original <- names(df_original_cols)[grepl('..PM.1MM.2MM.', names(df_original_cols), fixed=TRUE)]
count_cols_original <- names(df_original_cols)[!grepl('..PM.1MM.2MM.', names(df_original_cols), fixed=TRUE) & !names(df_original_cols) %in% c('miRNA.name', 'pos.mut')]

sample_names_in_data <- names(df_with_positions)[!names(df_with_positions) %in% c("miRNA_name", "pos", "mutation_type", "position", "region", "region_detailed")]
count_sample_cols_processed <- intersect(sample_names_in_data, gsub("..PM.1MM.2MM.", "", count_cols_original, fixed=TRUE))
total_sample_cols_processed <- intersect(sample_names_in_data, total_cols_original)

vaf_data <- data.frame()

for (i in 1:length(count_sample_cols_processed)) {
  sample_count_col <- count_sample_cols_processed[i]
  sample_total_col <- total_sample_cols_processed[i]

  if (sample_count_col %in% names(df_with_positions) && sample_total_col %in% names(df_with_positions)) {
    temp_df <- df_with_positions %>%
      select(miRNA_name, position, region, region_detailed, !!sym(sample_count_col), !!sym(sample_total_col)) %>%
      mutate(
        sample = sample_count_col,
        snv_count = .data[[sample_count_col]],
        total_mirna_count = .data[[sample_total_col]],
        vaf = ifelse(total_mirna_count > 0, snv_count / total_mirna_count, 0)
      ) %>%
      select(miRNA_name, position, region, region_detailed, sample, snv_count, total_mirna_count, vaf)
    vaf_data <- bind_rows(vaf_data, temp_df)
  }
}

# Aplicar filtro VAF > 0.5 → NA
vaf_data <- vaf_data %>%
  mutate(vaf = ifelse(vaf > 0.5, NA, vaf))

# Agregar metadatos de cohorte
vaf_data <- vaf_data %>%
  left_join(sample_metadata, by = "sample") %>%
  filter(!is.na(cohort))

cat(paste0("   - VAFs calculados: ", nrow(vaf_data), "\n"))
cat(paste0("   - VAFs válidos (>0): ", sum(vaf_data$vaf > 0, na.rm = TRUE), "\n"))
cat(paste0("   - VAFs > 0.5 (convertidos a NA): ", sum(vaf_data$vaf > 0.5, na.rm = TRUE), "\n"))
cat(paste0("   - Muestras ALS: ", sum(vaf_data$cohort == "ALS", na.rm = TRUE), "\n"))
cat(paste0("   - Muestras Control: ", sum(vaf_data$cohort == "Control", na.rm = TRUE), "\n\n"))

# --- 4. ANÁLISIS GENERAL ---
cat("📊 4. ANÁLISIS GENERAL\n")
cat("=====================\n")

# Resumen por cohorte
cohort_summary <- vaf_data %>%
  group_by(cohort) %>%
  summarise(
    n_snvs = n(),
    n_mirnas = length(unique(miRNA_name)),
    n_samples = length(unique(sample)),
    mean_vaf = mean(vaf, na.rm = TRUE),
    median_vaf = median(vaf, na.rm = TRUE),
    n_seed_snvs = sum(region == "Seed", na.rm = TRUE),
    n_non_seed_snvs = sum(region == "Non-seed", na.rm = TRUE),
    .groups = 'drop'
  )

cat("   - Resumen por cohorte:\n")
print(cohort_summary)
cat("\n")

# Resumen por posición
position_summary <- vaf_data %>%
  group_by(position, region) %>%
  summarise(
    n_snvs = n(),
    mean_vaf = mean(vaf, na.rm = TRUE),
    median_vaf = median(vaf, na.rm = TRUE),
    n_als = sum(cohort == "ALS", na.rm = TRUE),
    n_control = sum(cohort == "Control", na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  arrange(position)

cat("   - Resumen por posición:\n")
print(position_summary)
cat("\n")

# --- 5. TESTS DIFERENCIALES GENERALES ---
cat("📊 5. TESTS DIFERENCIALES GENERALES\n")
cat("===================================\n")

# Test t para VAF general
vaf_als <- vaf_data$vaf[vaf_data$cohort == "ALS" & !is.na(vaf_data$vaf)]
vaf_control <- vaf_data$vaf[vaf_data$cohort == "Control" & !is.na(vaf_data$vaf)]

t_test_vaf <- t.test(vaf_als, vaf_control)
cat(paste0("   - Test t para VAF general:\n"))
cat(paste0("     - p-value: ", round(t_test_vaf$p.value, 6), "\n"))
cat(paste0("     - t-statistic: ", round(t_test_vaf$statistic, 4), "\n"))
cat(paste0("     - VAF medio ALS: ", round(mean(vaf_als), 4), "\n"))
cat(paste0("     - VAF medio Control: ", round(mean(vaf_control), 4), "\n\n"))

# Test t para número de SNVs por muestra
snv_counts <- vaf_data %>%
  group_by(sample, cohort) %>%
  summarise(n_snvs = n(), .groups = 'drop')

snv_als <- snv_counts$n_snvs[snv_counts$cohort == "ALS"]
snv_control <- snv_counts$n_snvs[snv_counts$cohort == "Control"]

# Verificar que hay variabilidad en los datos
if (var(snv_als) > 0 && var(snv_control) > 0) {
  t_test_snvs <- t.test(snv_als, snv_control)
  cat(paste0("   - Test t para número de SNVs por muestra:\n"))
  cat(paste0("     - p-value: ", round(t_test_snvs$p.value, 6), "\n"))
  cat(paste0("     - t-statistic: ", round(t_test_snvs$statistic, 4), "\n"))
  cat(paste0("     - SNVs medio ALS: ", round(mean(snv_als), 2), "\n"))
  cat(paste0("     - SNVs medio Control: ", round(mean(snv_control), 2), "\n\n"))
} else {
  cat(paste0("   - Test t para número de SNVs por muestra:\n"))
  cat(paste0("     - No se puede realizar (datos constantes)\n"))
  cat(paste0("     - SNVs medio ALS: ", round(mean(snv_als), 2), "\n"))
  cat(paste0("     - SNVs medio Control: ", round(mean(snv_control), 2), "\n\n"))
}

# --- 6. ANÁLISIS DE REGIÓN SEED ---
cat("🌱 6. ANÁLISIS DE REGIÓN SEED\n")
cat("=============================\n")

# Comparación Seed vs Non-seed
seed_analysis <- vaf_data %>%
  group_by(cohort, region) %>%
  summarise(
    n_snvs = n(),
    mean_vaf = mean(vaf, na.rm = TRUE),
    median_vaf = median(vaf, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  pivot_wider(names_from = cohort, values_from = c(n_snvs, mean_vaf, median_vaf))

cat("   - Análisis por región:\n")
print(seed_analysis)
cat("\n")

# Test t para Seed region
seed_data <- vaf_data %>% filter(region == "Seed")
seed_als <- seed_data$vaf[seed_data$cohort == "ALS" & !is.na(seed_data$vaf)]
seed_control <- seed_data$vaf[seed_data$cohort == "Control" & !is.na(seed_data$vaf)]

if (length(seed_als) > 0 && length(seed_control) > 0) {
  t_test_seed <- t.test(seed_als, seed_control)
  cat(paste0("   - Test t para región Seed:\n"))
  cat(paste0("     - p-value: ", round(t_test_seed$p.value, 6), "\n"))
  cat(paste0("     - t-statistic: ", round(t_test_seed$statistic, 4), "\n"))
  cat(paste0("     - VAF medio Seed ALS: ", round(mean(seed_als), 4), "\n"))
  cat(paste0("     - VAF medio Seed Control: ", round(mean(seed_control), 4), "\n\n"))
}

cat("✅ ANÁLISIS GENERAL COMPLETADO\n")
cat("==============================\n\n")
