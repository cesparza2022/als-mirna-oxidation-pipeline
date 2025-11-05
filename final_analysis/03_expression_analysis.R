# =============================================================================
# ANÁLISIS FINAL - PASO 3: ANÁLISIS DE EXPRESIÓN Y CALIDAD DE DATOS
# =============================================================================
# 
# Este script realiza:
# 1. Análisis de expresión de miRNAs
# 2. Identificación de miRNAs suficientemente expresados
# 3. Verificación de metadatos de muestras
# 4. Análisis de calidad de datos
#
# Autor: Análisis UCSD 8OG
# Fecha: 2025
# =============================================================================

# --- LIBRERÍAS ---
library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(RColorBrewer)

# --- CONFIGURACIÓN ---
cat("🔬 ANÁLISIS DE EXPRESIÓN Y CALIDAD DE DATOS\n")
cat("===========================================\n\n")

# --- 1. CARGAR DATOS PROCESADOS ---
cat("📊 1. CARGANDO DATOS PROCESADOS\n")
cat("===============================\n")

# Cargar datos procesados
df_processed <- read.csv("final_analysis/processed_data/processed_snvs_gt.csv", stringsAsFactors = FALSE)

# Identificar columnas
total_cols <- names(df_processed)[grepl('..PM.1MM.2MM.', names(df_processed), fixed=TRUE)]
count_cols <- names(df_processed)[!grepl('..PM.1MM.2MM.', names(df_processed), fixed=TRUE) & 
                                 !names(df_processed) %in% c('miRNA_name', 'pos', 'mutation_type', 'count')]

cat(paste0("   - SNVs procesados: ", nrow(df_processed), "\n"))
cat(paste0("   - miRNAs únicos: ", length(unique(df_processed$miRNA_name)), "\n"))
cat(paste0("   - Muestras: ", length(count_cols), "\n"))
cat("\n")

# --- 2. ANÁLISIS DE EXPRESIÓN POR miRNA ---
cat("📈 2. ANÁLISIS DE EXPRESIÓN POR miRNA\n")
cat("=====================================\n")

# Calcular expresión total por miRNA y muestra
expr_summary <- df_processed %>%
  group_by(miRNA_name) %>%
  summarise(
    across(all_of(total_cols), ~sum(., na.rm = TRUE)),
    .groups = "drop"
  ) %>%
  pivot_longer(
    cols = all_of(total_cols),
    names_to = "sample",
    values_to = "total_expression"
  ) %>%
  group_by(miRNA_name) %>%
  summarise(
    mean_expression = mean(total_expression, na.rm = TRUE),
    median_expression = median(total_expression, na.rm = TRUE),
    max_expression = max(total_expression, na.rm = TRUE),
    samples_detected = sum(total_expression > 0, na.rm = TRUE),
    total_samples = n(),
    detection_rate = samples_detected / total_samples,
    .groups = "drop"
  ) %>%
  arrange(desc(mean_expression))

cat(paste0("   - miRNAs con expresión > 0: ", sum(expr_summary$mean_expression > 0), "\n"))
cat(paste0("   - miRNAs con detección > 50%: ", sum(expr_summary$detection_rate > 0.5), "\n"))
cat(paste0("   - miRNAs con detección > 90%: ", sum(expr_summary$detection_rate > 0.9), "\n"))
cat("\n")

# --- 3. IDENTIFICAR miRNAs ALTAMENTE EXPRESADOS ---
cat("🎯 3. IDENTIFICANDO miRNAs ALTAMENTE EXPRESADOS\n")
cat("===============================================\n")

# Definir umbrales de expresión
expression_floor_25 <- quantile(expr_summary$mean_expression, 0.25, na.rm = TRUE)
expression_floor_50 <- quantile(expr_summary$mean_expression, 0.50, na.rm = TRUE)
expression_floor_75 <- quantile(expr_summary$mean_expression, 0.75, na.rm = TRUE)

cat(paste0("   - Umbral 25%: ", round(expression_floor_25, 2), "\n"))
cat(paste0("   - Umbral 50%: ", round(expression_floor_50, 2), "\n"))
cat(paste0("   - Umbral 75%: ", round(expression_floor_75, 2), "\n"))

# Seleccionar miRNAs altamente expresados (umbral 75%)
top_miRNAs <- expr_summary %>%
  filter(mean_expression >= expression_floor_75) %>%
  arrange(desc(mean_expression))

cat(paste0("   - miRNAs altamente expresados (≥75%): ", nrow(top_miRNAs), "\n"))
cat("\n")

# --- 4. ANÁLISIS DE METADATOS DE MUESTRAS ---
cat("🔍 4. ANÁLISIS DE METADATOS DE MUESTRAS\n")
cat("=======================================\n")

# Extraer metadatos de nombres de muestras
sample_metadata <- data.frame(
  sample = count_cols,
  stringsAsFactors = FALSE
) %>%
  mutate(
    # Extraer cohorte (ALS vs Control)
    cohort = case_when(
      grepl("control", sample, ignore.case = TRUE) ~ "Control",
      grepl("als", sample, ignore.case = TRUE) ~ "ALS",
      TRUE ~ "Unknown"
    ),
    # Extraer timepoint si existe
    timepoint = case_when(
      grepl("enrolment", sample, ignore.case = TRUE) ~ "Enrolment",
      grepl("longitudinal", sample, ignore.case = TRUE) ~ "Longitudinal",
      TRUE ~ "Unknown"
    ),
    # Extraer batch/site si existe
    batch = str_extract(sample, "SRR[0-9]+"),
    site = case_when(
      grepl("Magen", sample, ignore.case = TRUE) ~ "Magen",
      TRUE ~ "Unknown"
    )
  )

# Resumen de metadatos
cohort_summary <- sample_metadata %>%
  group_by(cohort) %>%
  summarise(
    n_samples = n(),
    .groups = "drop"
  )

timepoint_summary <- sample_metadata %>%
  group_by(timepoint) %>%
  summarise(
    n_samples = n(),
    .groups = "drop"
  )

cat("   - Distribución por cohorte:\n")
print(cohort_summary)
cat("\n   - Distribución por timepoint:\n")
print(timepoint_summary)
cat("\n")

# --- 5. ANÁLISIS DE CALIDAD DE DATOS ---
cat("🔬 5. ANÁLISIS DE CALIDAD DE DATOS\n")
cat("===================================\n")

# Calcular métricas de calidad
qc_metrics <- df_processed %>%
  summarise(
    total_snvs = n(),
    unique_mirnas = length(unique(miRNA_name)),
    unique_positions = length(unique(pos)),
    samples_with_data = length(count_cols),
    # Calcular VAFs para análisis de calidad
    across(all_of(count_cols), ~sum(., na.rm = TRUE)),
    across(all_of(total_cols), ~sum(., na.rm = TRUE))
  ) %>%
  pivot_longer(
    cols = all_of(c(count_cols, total_cols)),
    names_to = "sample",
    values_to = "count"
  ) %>%
  mutate(
    sample_type = ifelse(grepl('..PM.1MM.2MM.', sample, fixed=TRUE), "total", "snv")
  ) %>%
  group_by(sample, sample_type) %>%
  summarise(total_count = sum(count, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = sample_type, values_from = total_count) %>%
  mutate(
    vaf_estimate = snv / total,
    sample = gsub('..PM.1MM.2MM.', '', sample, fixed=TRUE)
  )

cat(paste0("   - SNVs totales: ", qc_metrics$total_snvs[1], "\n"))
cat(paste0("   - miRNAs únicos: ", qc_metrics$unique_mirnas[1], "\n"))
cat(paste0("   - Posiciones únicas: ", qc_metrics$unique_positions[1], "\n"))
cat(paste0("   - Muestras con datos: ", qc_metrics$samples_with_data[1], "\n"))
cat("\n")

# --- 6. VISUALIZACIONES ---
cat("📊 6. CREANDO VISUALIZACIONES\n")
cat("=============================\n")

# Crear directorio de figuras
if (!dir.exists("final_analysis/figures")) {
  dir.create("final_analysis/figures", recursive = TRUE)
}

# Figura 1: Distribución de expresión de miRNAs
p1 <- expr_summary %>%
  ggplot(aes(x = mean_expression)) +
  geom_histogram(bins = 50, fill = "steelblue", alpha = 0.7) +
  geom_vline(xintercept = expression_floor_75, color = "red", linetype = "dashed") +
  scale_x_log10() +
  labs(
    title = "Distribución de Expresión de miRNAs",
    x = "Expresión Media (log10)",
    y = "Frecuencia"
  ) +
  theme_minimal()

ggsave("final_analysis/figures/expression_distribution.png", p1, width = 10, height = 6, dpi = 300)

# Figura 2: Top miRNAs más expresados
p2 <- top_miRNAs %>%
  head(20) %>%
  ggplot(aes(x = reorder(miRNA_name, mean_expression), y = mean_expression)) +
  geom_col(fill = "darkgreen", alpha = 0.7) +
  coord_flip() +
  labs(
    title = "Top 20 miRNAs Más Expresados",
    x = "miRNA",
    y = "Expresión Media"
  ) +
  theme_minimal()

ggsave("final_analysis/figures/top_mirnas.png", p2, width = 12, height = 8, dpi = 300)

# Figura 3: Distribución por cohorte
p3 <- cohort_summary %>%
  ggplot(aes(x = cohort, y = n_samples, fill = cohort)) +
  geom_col(alpha = 0.7) +
  geom_text(aes(label = n_samples), vjust = -0.5) +
  scale_fill_brewer(type = "qual", palette = "Set2") +
  labs(
    title = "Distribución de Muestras por Cohorte",
    x = "Cohorte",
    y = "Número de Muestras"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

ggsave("final_analysis/figures/cohort_distribution.png", p3, width = 8, height = 6, dpi = 300)

cat("   - Figuras guardadas en: final_analysis/figures/\n")
cat("\n")

# --- 7. GUARDAR RESULTADOS ---
cat("💾 7. GUARDANDO RESULTADOS\n")
cat("==========================\n")

# Crear directorio de tablas
if (!dir.exists("final_analysis/tables")) {
  dir.create("final_analysis/tables", recursive = TRUE)
}

# Guardar tablas
write.csv(expr_summary, "final_analysis/tables/expr_summary.csv", row.names = FALSE)
write.csv(top_miRNAs, "final_analysis/tables/top_mirnas.csv", row.names = FALSE)
write.csv(sample_metadata, "final_analysis/tables/sample_metadata.csv", row.names = FALSE)
write.csv(qc_metrics, "final_analysis/tables/qc_metrics.csv", row.names = FALSE)

cat("   - Tablas guardadas en: final_analysis/tables/\n")
cat("\n")

# --- 8. RESUMEN FINAL ---
cat("📋 8. RESUMEN FINAL\n")
cat("===================\n")

cat("📊 MÉTRICAS CLAVE:\n")
cat(paste0("   - miRNAs totales: ", length(unique(df_processed$miRNA_name)), "\n"))
cat(paste0("   - miRNAs altamente expresados: ", nrow(top_miRNAs), "\n"))
cat(paste0("   - Muestras ALS: ", sum(cohort_summary$n_samples[cohort_summary$cohort == "ALS"]), "\n"))
cat(paste0("   - Muestras Control: ", sum(cohort_summary$n_samples[cohort_summary$cohort == "Control"]), "\n"))
cat("\n")

cat("✅ VERIFICACIONES:\n")
cat("   - Datos de expresión calculados: ✓\n")
cat("   - Metadatos de muestras extraídos: ✓\n")
cat("   - Métricas de calidad calculadas: ✓\n")
cat("   - Visualizaciones creadas: ✓\n")
cat("\n")

cat("🎯 PRÓXIMOS PASOS:\n")
cat("   - Ejecutar análisis de señal global de oxidación\n")
cat("   - Realizar tests diferenciales por posición\n")
cat("   - Crear visualizaciones de patrones posicionales\n")
cat("\n")









