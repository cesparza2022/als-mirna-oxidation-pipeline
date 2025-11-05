#!/usr/bin/env Rscript

# Análisis específico: RPM mean > 1 con filtros VAF > 50% y G>T en región semilla
library(dplyr)
library(stringr)

# Cargar datos
cat("Cargando datos...\n")
df <- read.delim('/Users/cesaresparza/New_Desktop/UCSD/8OG/results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt', 
                 sep = '\t', header = TRUE)

# Identificar columnas
meta_cols <- c('miRNA name', 'pos:mut')
snv_cols <- grep('^[A-Z]{2}[0-9]+', names(df), value = TRUE)
total_cols <- grep('\\(PM\\+1MM\\+2MM\\)', names(df), value = TRUE)

cat("=== ANÁLISIS ESPECÍFICO: RPM MEAN > 1 ===\n")
cat("Total miRNAs iniciales:", nrow(df), "\n")

# Filtrar solo G>T en región semilla (posiciones 2-8)
# Usar la sintaxis correcta para columnas con caracteres especiales
df_gt_seed <- df %>%
  filter(grepl('^[2-8]:G>T', df[['pos:mut']]))

cat("miRNAs con G>T en región semilla:", nrow(df_gt_seed), "\n")

# Calcular RPM
cat("Calculando RPM...\n")
lib_size <- df %>%
  summarise(across(all_of(total_cols), ~ sum(.x, na.rm = TRUE))) %>%
  unlist()

rpm_data <- df_gt_seed
for (col in total_cols) {
  rpm_data[[paste0(col, '_RPM')]] <- (rpm_data[[col]] / lib_size[col]) * 1e6
}

# Calcular RPM promedio por miRNA
rpm_cols <- paste0(total_cols, '_RPM')
rpm_data$mean_rpm <- rowMeans(select(rpm_data, all_of(rpm_cols)), na.rm = TRUE)

cat("miRNAs con RPM mean calculado:", nrow(rpm_data), "\n")

# Filtrar por RPM mean > 1
rpm_filtered <- rpm_data %>%
  filter(mean_rpm > 1)

cat("miRNAs con RPM mean > 1:", nrow(rpm_filtered), "\n")

# Aplicar filtro VAF > 50%
cat("Aplicando filtro VAF > 50%...\n")
snv_cols_rpm <- grep('^[A-Z]{2}[0-9]+', names(rpm_filtered), value = TRUE)
vaf_filtered <- rpm_filtered

for (i in 1:length(snv_cols_rpm)) {
  snv_col <- snv_cols_rpm[i]
  total_col <- total_cols[i]
  vaf_col <- paste0(snv_col, '_VAF')
  
  vaf_filtered[[vaf_col]] <- vaf_filtered[[snv_col]] / vaf_filtered[[total_col]]
}

# Filtrar SNVs con VAF > 50%
vaf_cols <- paste0(snv_cols_rpm, '_VAF')
vaf_filtered <- vaf_filtered %>%
  filter(if_all(all_of(vaf_cols), ~ .x <= 0.5 | is.na(.x)))

cat("miRNAs después de filtrar VAF > 50%:", nrow(vaf_filtered), "\n")

# Mostrar top miRNAs
if (nrow(vaf_filtered) > 0) {
  cat("\n=== TOP 10 miRNAs ===\n")
  top_mirnas <- vaf_filtered %>%
    arrange(desc(mean_rpm)) %>%
    head(10) %>%
    select('miRNA name', mean_rpm)
  
  print(top_mirnas)
  
  # Guardar lista completa
  writeLines(vaf_filtered$`miRNA name`, 
             '/Users/cesaresparza/New_Desktop/UCSD/8OG/outputs/rpm1_filtered_mirnas.txt')
  
  cat("\nLista guardada en: outputs/rpm1_filtered_mirnas.txt\n")
} else {
  cat("No hay miRNAs que cumplan todos los criterios\n")
}

# Estadísticas adicionales
cat("\n=== ESTADÍSTICAS ADICIONALES ===\n")
if (nrow(vaf_filtered) > 0) {
  cat("RPM mean range:", round(range(vaf_filtered$mean_rpm), 2), "\n")
  cat("RPM mean median:", round(median(vaf_filtered$mean_rpm), 2), "\n")
  cat("RPM mean mean:", round(mean(vaf_filtered$mean_rpm), 2), "\n")
}











