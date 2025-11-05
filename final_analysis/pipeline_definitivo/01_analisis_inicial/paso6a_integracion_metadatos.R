# ==============================================================================
# PASO 6A: PREPARACIÓN E INTEGRACIÓN DE METADATOS CLÍNICOS
# ==============================================================================
# Objetivo: Integrar metadatos clínicos del estudio original (GSE168714)
# Caracterizar los 84 outliers con datos clínicos

# Cargar librerías necesarias
library(tidyverse)
library(readxl)  # Para leer archivos .xls
library(ggplot2)
library(gridExtra)

# Cargar configuración y funciones
source("../config_pipeline.R")
source("functions_pipeline.R")

# Definir rutas de salida
output_figures_path <- file.path(config$output_paths$figures, "paso6a_metadatos")
output_tables_path <- file.path(config$output_paths$outputs, "paso6a_metadatos")

# Crear directorios
dir.create(output_figures_path, showWarnings = FALSE, recursive = TRUE)
dir.create(output_tables_path, showWarnings = FALSE, recursive = TRUE)

cat("=== PASO 6A: INTEGRACIÓN DE METADATOS CLÍNICOS ===\n")
cat("Fecha:", as.character(Sys.time()), "\n\n")

# =============================================================================
# 1. CARGAR METADATOS BÁSICOS
# =============================================================================

cat("=== CARGANDO METADATOS BÁSICOS ===\n")

# Metadatos básicos (cohort, batch, timepoint)
metadata_basic_file <- "/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/tables/sample_metadata.csv"
metadata_basic <- read_csv(metadata_basic_file, show_col_types = FALSE)

cat("Metadatos básicos cargados:\n")
cat("  - Muestras:", nrow(metadata_basic), "\n")
cat("  - Variables:", ncol(metadata_basic), "\n")
print(head(metadata_basic, 3))

# =============================================================================
# 2. CARGAR METADATOS CLÍNICOS DEL ESTUDIO ORIGINAL
# =============================================================================

cat("\n=== CARGANDO METADATOS CLÍNICOS (GSE168714) ===\n")

# Archivo 1: All samples enrolment (onset, riluzole, batch, sex)
metadata_enrolment_file <- "/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/tercer_intento/metadata_analysis/GSE168714_All_samples_enrolment.txt"
metadata_enrolment <- read_tsv(metadata_enrolment_file, show_col_types = FALSE)

cat("Metadatos de enrolment cargados:\n")
cat("  - Filas:", nrow(metadata_enrolment), "\n")
cat("  - Columnas:", ncol(metadata_enrolment), "\n")
cat("  - Variables:\n")
print(head(names(metadata_enrolment), 20))

# Archivo 2: Clinical data (discovery cohort con datos de supervivencia)
metadata_clinical_file <- "/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/tercer_intento/metadata_analysis/GSE168714_Data_file_related_to_fig_2_3_5_discovery.csv"
metadata_clinical <- read_csv(metadata_clinical_file, show_col_types = FALSE)

cat("\nMetadatos clínicos cargados:\n")
cat("  - Pacientes:", nrow(metadata_clinical), "\n")
cat("  - Variables:", ncol(metadata_clinical), "\n")
cat("  - Variables clave:\n")
print(names(metadata_clinical)[1:20])

# =============================================================================
# 3. PROCESAR Y LIMPIAR METADATOS
# =============================================================================

cat("\n=== PROCESANDO METADATOS ===\n")

# El archivo de enrolment tiene estructura especial (transpuesta)
# Fila 1: sample names
# Fila 2: Batch
# Fila 3: sex
# Fila 4: Onset
# Fila 5: Riluzole

# Extraer headers (nombres de muestra) de la primera fila
sample_names <- as.character(metadata_enrolment[1, -1])

# Extraer variables (transponer)
metadata_enrolment_clean <- data.frame(
  index_case = sample_names,
  batch = as.numeric(metadata_enrolment[2, -1]),
  sex = as.character(metadata_enrolment[3, -1]),
  onset = as.character(metadata_enrolment[4, -1]),
  riluzole = as.character(metadata_enrolment[5, -1])
) %>%
  mutate(
    sex_clean = ifelse(sex == "M", "Male", "Female"),
    onset_clean = ifelse(onset == "1", "Non_bulbar", "Bulbar"),
    riluzole_clean = ifelse(riluzole == "Yes", "Yes", "No")
  )

cat("Metadatos de enrolment procesados:\n")
cat("  - Muestras procesadas:", nrow(metadata_enrolment_clean), "\n")
print(head(metadata_enrolment_clean, 5))

# =============================================================================
# 4. MAPEAR IDs DE MUESTRAS
# =============================================================================

cat("\n=== MAPEO DE IDs DE MUESTRAS ===\n")

# Los metadatos usan códigos como BLT00002, BUH00001, etc.
# Nuestros datos usan códigos como Magen-ALS-enrolment-bloodplasma-SRR13934430
# Necesitamos mapear usando el archivo básico que ya vincula los dos

# Extraer batch/SRR ID de metadata_basic
metadata_basic_mapped <- metadata_basic %>%
  mutate(
    srr_id = batch,
    # Intentar extraer código de paciente del sample name si existe
    patient_code = str_extract(sample, "(?<=bloodplasma-)SRR\\d+")
  )

cat("Muestras en dataset actual:", nrow(metadata_basic_mapped), "\n")
cat("Primeras 5:\n")
print(head(metadata_basic_mapped, 5))

# =============================================================================
# 5. CREAR DATASET INTEGRADO DE METADATOS
# =============================================================================

cat("\n=== CREANDO DATASET INTEGRADO ===\n")

# Por ahora, trabajar con los metadatos básicos que ya están vinculados
# Los metadatos clínicos avanzados (ALSFRS, slope, survival) solo están 
# disponibles para la cohorte de descubrimiento (126 pacientes)

# Añadir información básica de metadatos
metadata_integrated <- metadata_basic_mapped %>%
  select(sample, cohort, timepoint, batch, site) %>%
  mutate(
    sample_clean = str_remove_all(sample, "Magen-|-bloodplasma"),
    is_longitudinal = timepoint == "Longitudinal"
  )

cat("Dataset integrado creado:\n")
cat("  - Muestras totales:", nrow(metadata_integrated), "\n")
cat("  - ALS:", sum(metadata_integrated$cohort == "ALS"), "\n")
cat("  - Control:", sum(metadata_integrated$cohort == "Control"), "\n")
cat("  - Longitudinal:", sum(metadata_integrated$is_longitudinal), "\n")

write_csv(metadata_integrated, file.path(output_tables_path, "paso6a_metadatos_integrados.csv"))

# =============================================================================
# 6. CARACTERIZAR OUTLIERS CON METADATOS
# =============================================================================

cat("\n=== CARACTERIZANDO OUTLIERS CON METADATOS ===\n")

# Cargar lista de outliers (ya tiene cohort incluido)
outliers_file <- file.path(config$output_paths$outputs, "paso5a_outliers_muestras", "paso5a_outliers_consolidado.csv")
outliers_data <- read_csv(outliers_file, show_col_types = FALSE)

# Filtrar solo outliers
outliers_only <- outliers_data %>%
  filter(any_outlier == TRUE)

cat("Outliers a caracterizar:", nrow(outliers_only), "\n")

# Limpiar nombres de muestra y vincular con metadatos para obtener timepoint
outliers_only <- outliers_only %>%
  mutate(sample_count_clean = str_replace_all(sample_count, "-", "."))

# Hacer join para obtener timepoint
outliers_characterized <- outliers_only %>%
  left_join(
    metadata_integrated %>% select(sample, timepoint, is_longitudinal),
    by = c("sample_count_clean" = "sample")
  )

cat("Outliers caracterizados:\n")
cat("  - Total outliers:", nrow(outliers_characterized), "\n")
cat("  - ALS:", sum(outliers_characterized$cohort == "ALS", na.rm = TRUE), "\n")
cat("  - Control:", sum(outliers_characterized$cohort == "Control", na.rm = TRUE), "\n")
cat("  - Longitudinal:", sum(outliers_characterized$is_longitudinal, na.rm = TRUE), "\n")
cat("  - Enrolment:", sum(outliers_characterized$timepoint == "Enrolment", na.rm = TRUE), "\n")

# Resumen de outliers por cohort y timepoint
outliers_by_timepoint <- outliers_characterized %>%
  group_by(cohort, timepoint) %>%
  summarise(
    n_outliers = n(),
    .groups = "drop"
  )

cat("\nOUTLIERS por TIMEPOINT:\n")
print(outliers_by_timepoint)

write_csv(outliers_characterized, file.path(output_tables_path, "paso6a_outliers_caracterizados.csv"))
write_csv(outliers_by_timepoint, file.path(output_tables_path, "paso6a_outliers_por_timepoint.csv"))

# =============================================================================
# 7. ANÁLISIS DE DISTRIBUCIÓN DE BATCH
# =============================================================================

cat("\n=== ANÁLISIS DE BATCH ===\n")

# Analizar distribución de batches
batch_distribution <- metadata_integrated %>%
  group_by(cohort) %>%
  summarise(
    n_samples = n(),
    n_batches_unique = n_distinct(batch),
    .groups = "drop"
  )

cat("Distribución de batches:\n")
print(batch_distribution)

# Tabla de contingencia batch vs cohort
batch_cohort_table <- metadata_integrated %>%
  count(batch, cohort) %>%
  pivot_wider(names_from = cohort, values_from = n, values_fill = 0)

cat("\nPrimeros 10 batches:\n")
print(head(batch_cohort_table, 10))

write_csv(batch_cohort_table, file.path(output_tables_path, "paso6a_batch_cohort_tabla.csv"))

# Verificar si hay confusión batch-cohort
# (¿algunos batches son solo ALS o solo Control?)
batch_confounding <- batch_cohort_table %>%
  mutate(
    total = ALS + Control,
    only_als = Control == 0,
    only_control = ALS == 0,
    balanced = !only_als & !only_control
  )

n_only_als <- sum(batch_confounding$only_als)
n_only_control <- sum(batch_confounding$only_control)
n_balanced <- sum(batch_confounding$balanced)

cat("\nConfusión batch-cohort:\n")
cat("  - Batches solo ALS:", n_only_als, "\n")
cat("  - Batches solo Control:", n_only_control, "\n")
cat("  - Batches balanceados:", n_balanced, "\n")

if (n_only_als > 0 | n_only_control > 0) {
  cat("\n⚠️ HAY CONFUSIÓN BATCH-COHORT\n")
  cat("Algunos batches contienen solo un grupo (ALS o Control)\n")
  cat("Esto puede generar batch effects confundidos con efectos biológicos\n")
} else {
  cat("\n✅ NO hay confusión batch-cohort\n")
}

# =============================================================================
# 8. ANÁLISIS EXPLORATORIO DE METADATOS
# =============================================================================

cat("\n=== ANÁLISIS EXPLORATORIO ===\n")

# Distribución de muestras
sample_summary <- metadata_integrated %>%
  group_by(cohort, timepoint) %>%
  summarise(n_samples = n(), .groups = "drop") %>%
  mutate(percentage = round((n_samples / sum(n_samples)) * 100, 2))

cat("Distribución de muestras:\n")
print(sample_summary)

write_csv(sample_summary, file.path(output_tables_path, "paso6a_distribucion_muestras.csv"))

# =============================================================================
# 9. PREPARAR DATASET PARA ANÁLISIS CLÍNICOS
# =============================================================================

cat("\n=== PREPARANDO DATASET PARA ANÁLISIS CLÍNICOS ===\n")

# Identificar columnas de counts y VAFs
count_cols <- names(metadata_integrated)[!names(metadata_integrated) %in% 
                                          c("sample", "cohort", "timepoint", "batch", "site", 
                                            "sample_clean", "is_longitudinal")]

# Crear estructura para vincular con datos de SNVs
# Guardar metadatos en formato que se pueda usar en análisis posteriores
metadata_for_analysis <- metadata_integrated %>%
  select(sample, cohort, timepoint, batch, is_longitudinal) %>%
  mutate(
    group_numeric = ifelse(cohort == "ALS", 1, 0),
    timepoint_numeric = ifelse(is_longitudinal, 1, 0)
  )

write_csv(metadata_for_analysis, file.path(output_tables_path, "paso6a_metadatos_para_analisis.csv"))

cat("Dataset preparado para análisis clínicos.\n")
cat("Variables disponibles para análisis:\n")
cat("  - cohort (ALS/Control)\n")
cat("  - timepoint (Enrolment/Longitudinal)\n")
cat("  - batch (ID de lote)\n")
cat("  - is_longitudinal (TRUE/FALSE)\n")

# =============================================================================
# 10. VINCULAR CON METADATOS CLÍNICOS AVANZADOS (Discovery Cohort)
# =============================================================================

cat("\n=== VINCULANDO CON METADATOS CLÍNICOS AVANZADOS ===\n")

# Los metadatos clínicos avanzados usan códigos de paciente (BLT, BUH, etc.)
# Necesitamos mapear estos códigos con nuestros SRR IDs

# Primero, intentar mapear usando el archivo de survival study
# que contiene códigos de paciente
cat("Metadatos clínicos (discovery cohort):\n")
cat("  - Pacientes:", nrow(metadata_clinical), "\n")
cat("  - Variables clínicas:\n")
clinical_vars <- names(metadata_clinical)[c(1:10, 14:20)]
print(clinical_vars)

# Guardar metadatos clínicos para referencia
write_csv(metadata_clinical, file.path(output_tables_path, "paso6a_metadatos_clinicos_discovery.csv"))

cat("\n⚠️ NOTA: Los metadatos clínicos avanzados (ALSFRS, slope, survival)\n")
cat("solo están disponibles para la cohorte de descubrimiento (126 pacientes).\n")
cat("Necesitamos mapear los códigos de paciente (BLT, BUH, etc.) con los SRR IDs.\n")

# =============================================================================
# 11. ANÁLISIS DE OUTLIERS CON METADATOS DISPONIBLES
# =============================================================================

cat("\n=== ANÁLISIS DE OUTLIERS CON METADATOS ===\n")

# Análisis de outliers por timepoint
outliers_timepoint_summary <- outliers_characterized %>%
  group_by(cohort, timepoint) %>%
  summarise(
    n_outliers = n(),
    .groups = "drop"
  )

cat("OUTLIERS por cohort y timepoint:\n")
print(outliers_timepoint_summary)

# Calcular proporción de outliers en cada grupo
total_samples_by_group <- metadata_integrated %>%
  group_by(cohort, timepoint) %>%
  summarise(total_samples = n(), .groups = "drop")

outliers_proportion <- outliers_timepoint_summary %>%
  left_join(total_samples_by_group, by = c("cohort", "timepoint")) %>%
  mutate(
    proportion = round((n_outliers / total_samples) * 100, 2)
  )

cat("\nProporción de outliers por grupo:\n")
print(outliers_proportion)

write_csv(outliers_proportion, file.path(output_tables_path, "paso6a_outliers_proporcion_por_grupo.csv"))

# =============================================================================
# 12. VISUALIZACIONES
# =============================================================================

cat("\n=== GENERANDO VISUALIZACIONES ===\n")

# Visualización 1: Distribución de muestras
p_samples <- ggplot(sample_summary, aes(x = cohort, y = n_samples, fill = timepoint)) +
  geom_col(position = "dodge") +
  geom_text(aes(label = n_samples), position = position_dodge(width = 0.9), vjust = -0.5) +
  labs(title = "Distribución de Muestras por Cohort y Timepoint",
       x = "Cohort", y = "Número de Muestras",
       fill = "Timepoint") +
  theme_minimal()

ggsave(file.path(output_figures_path, "paso6a_distribucion_muestras.png"), p_samples, width = 10, height = 6)
cat("Figura 'paso6a_distribucion_muestras.png' generada.\n")

# Visualización 2: Outliers por timepoint
p_outliers_timepoint <- ggplot(outliers_proportion, aes(x = paste(cohort, timepoint), y = proportion, fill = cohort)) +
  geom_col() +
  geom_text(aes(label = paste0(proportion, "%\n(", n_outliers, "/", total_samples, ")")), 
            vjust = -0.5, size = 3) +
  labs(title = "Proporción de Outliers por Grupo",
       x = "Grupo (Cohort + Timepoint)", y = "% Outliers",
       fill = "Cohort") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave(file.path(output_figures_path, "paso6a_outliers_por_grupo.png"), p_outliers_timepoint, width = 10, height = 6)
cat("Figura 'paso6a_outliers_por_grupo.png' generada.\n")

# Visualización 3: Distribución de batches
batch_summary <- metadata_integrated %>%
  count(cohort) %>%
  mutate(percentage = round((n / sum(n)) * 100, 1))

p_batch <- ggplot(batch_summary, aes(x = cohort, y = n, fill = cohort)) +
  geom_col() +
  geom_text(aes(label = paste0(n, " (", percentage, "%)")), vjust = -0.5) +
  labs(title = "Distribución Total de Muestras por Cohort",
       x = "Cohort", y = "Número de Muestras") +
  theme_minimal()

ggsave(file.path(output_figures_path, "paso6a_cohort_distribucion.png"), p_batch, width = 8, height = 6)
cat("Figura 'paso6a_cohort_distribucion.png' generada.\n")

# =============================================================================
# 13. PREPARAR MAPEO PARA METADATOS CLÍNICOS AVANZADOS
# =============================================================================

cat("\n=== PREPARANDO MAPEO PARA METADATOS AVANZADOS ===\n")

# Crear tabla de mapeo básica
# Necesitaremos hacer esto manualmente o con información adicional
# Por ahora, documentar qué necesitamos

mapping_needed <- data.frame(
  variable = c("index_case (BLT, BUH, etc.)", "SRR ID", "Muestra actual"),
  available = c("En metadata_clinical", "En metadata_basic", "En filtered_data"),
  status = c("Necesita mapeo", "Disponible", "Disponible")
)

cat("Estado del mapeo de IDs:\n")
print(mapping_needed)

write_csv(mapping_needed, file.path(output_tables_path, "paso6a_mapeo_pendiente.csv"))

# =============================================================================
# 14. RESUMEN DE METADATOS DISPONIBLES
# =============================================================================

cat("\n=== RESUMEN DE METADATOS DISPONIBLES ===\n")

metadata_summary <- data.frame(
  variable = c(
    "cohort", "timepoint", "batch", "site",
    "onset (Bulbar/Non-bulbar)", "sex", "ALSFRS", "slope",
    "Age_at_onset", "survival", "status", "miR_181"
  ),
  n_samples = c(
    nrow(metadata_integrated), 
    nrow(metadata_integrated),
    nrow(metadata_integrated),
    nrow(metadata_integrated),
    nrow(metadata_enrolment_clean),
    nrow(metadata_enrolment_clean),
    nrow(metadata_clinical),
    nrow(metadata_clinical),
    nrow(metadata_clinical),
    nrow(metadata_clinical),
    nrow(metadata_clinical),
    nrow(metadata_clinical)
  ),
  available_for = c(
    "Todas (415)", "Todas (415)", "Todas (415)", "Todas (415)",
    paste0("Enrolment (~", nrow(metadata_enrolment_clean), ")"),
    paste0("Enrolment (~", nrow(metadata_enrolment_clean), ")"),
    paste0("Discovery cohort (", nrow(metadata_clinical), ")"),
    paste0("Discovery cohort (", nrow(metadata_clinical), ")"),
    paste0("Discovery cohort (", nrow(metadata_clinical), ")"),
    paste0("Discovery cohort (", nrow(metadata_clinical), ")"),
    paste0("Discovery cohort (", nrow(metadata_clinical), ")"),
    paste0("Discovery cohort (", nrow(metadata_clinical), ")")
  ),
  priority = c(
    "Alta", "Alta", "Alta", "Baja",
    "CRÍTICA", "Alta", "CRÍTICA", "CRÍTICA",
    "Media", "CRÍTICA", "CRÍTICA", "Alta"
  )
)

cat("\nRESUMEN DE VARIABLES DISPONIBLES:\n")
print(metadata_summary)

write_csv(metadata_summary, file.path(output_tables_path, "paso6a_resumen_variables_disponibles.csv"))

# =============================================================================
# 15. REPORTE EJECUTIVO
# =============================================================================

cat("\n=== GENERANDO REPORTE EJECUTIVO ===\n")

report_lines <- c(
  "# REPORTE - PASO 6A: INTEGRACIÓN DE METADATOS",
  "",
  "## 📊 RESUMEN EJECUTIVO",
  "",
  paste("**Fecha de análisis:**", Sys.time()),
  paste("**Total de muestras:**", nrow(metadata_integrated)),
  paste("**Outliers caracterizados:**", nrow(outliers_characterized)),
  "",
  "---",
  "",
  "## 🎯 METADATOS INTEGRADOS",
  "",
  "### Variables disponibles para TODAS las muestras (415):",
  "- ✅ cohort (ALS/Control)",
  "- ✅ timepoint (Enrolment/Longitudinal)",
  "- ✅ batch (ID de lote de secuenciación)",
  "- ✅ site (Magen)",
  "",
  "### Variables disponibles para SUBSET de muestras:",
  paste("- 🔶 onset (Bulbar/Non-bulbar) - ~", nrow(metadata_enrolment_clean), "muestras"),
  paste("- 🔶 sex (M/F) - ~", nrow(metadata_enrolment_clean), "muestras"),
  paste("- 🔶 riluzole (Yes/No) - ~", nrow(metadata_enrolment_clean), "muestras"),
  "",
  paste("- 🔥 ALSFRS (severidad) -", nrow(metadata_clinical), "pacientes (discovery cohort)"),
  paste("- 🔥 slope (progresión) -", nrow(metadata_clinical), "pacientes (discovery cohort)"),
  paste("- 🔥 survival -", nrow(metadata_clinical), "pacientes (discovery cohort)"),
  paste("- 🔥 status (vivo/fallecido) -", nrow(metadata_clinical), "pacientes (discovery cohort)"),
  "",
  "---",
  "",
  "## 🔍 CARACTERIZACIÓN DE OUTLIERS",
  "",
  paste("**Total outliers:**", nrow(outliers_characterized)),
  paste("- ALS:", sum(outliers_characterized$cohort == "ALS")),
  paste("- Control:", sum(outliers_characterized$cohort == "Control")),
  "",
  "### Por timepoint:",
  "```",
  capture.output(print(outliers_by_timepoint)),
  "```",
  "",
  "### Proporción de outliers:",
  "```",
  capture.output(print(outliers_proportion)),
  "```",
  "",
  "---",
  "",
  "## ⚠️ LIMITACIONES",
  "",
  "### Mapeo de IDs pendiente:",
  "- Los metadatos clínicos usan códigos de paciente (BLT, BUH, UCH, TST)",
  "- Nuestros datos usan códigos SRR (secuenciación)",
  "- **Necesitamos mapeo para vincular metadatos avanzados**",
  "",
  "### Variables disponibles por subgrupo:",
  paste("- **Todas las muestras (415):** cohort, timepoint, batch"),
  paste("- **Enrolment (~", nrow(metadata_enrolment_clean), "):** onset, sex, riluzole"),
  paste("- **Discovery cohort (", nrow(metadata_clinical), "):** ALSFRS, slope, survival"),
  "",
  "---",
  "",
  "## 🎯 PRÓXIMOS PASOS",
  "",
  "### Paso 6B: Mapeo de IDs y expansión de metadatos",
  "- Mapear códigos de paciente (BLT, etc.) con SRR IDs",
  "- Expandir metadatos clínicos a todas las muestras posibles",
  "- Vincular onset, sex, ALSFRS, slope con outliers",
  "",
  "### Paso 6C: Análisis exploratorio de metadatos clínicos",
  "- Distribuciones de ALSFRS, slope, age",
  "- Correlaciones entre variables",
  "- Balance de grupos",
  "",
  "### Paso 6D: Caracterización clínica de outliers",
  "- ¿Outliers son Bulbar?",
  "- ¿Outliers tienen peor ALSFRS?",
  "- ¿Outliers tienen progresión más rápida?",
  "- Validación biológica de la decisión de mantener outliers",
  "",
  "---",
  "",
  "## 📁 ARCHIVOS GENERADOS",
  "",
  "### Tablas (CSV):",
  "1. `paso6a_metadatos_integrados.csv` - Metadatos básicos integrados",
  "2. `paso6a_outliers_caracterizados.csv` - ⭐ Outliers con metadatos",
  "3. `paso6a_metadatos_para_analisis.csv` - Para análisis posteriores",
  "4. `paso6a_batch_cohort_tabla.csv` - Tabla de contingencia batch-cohort",
  "5. `paso6a_distribucion_muestras.csv` - Distribución por grupo",
  "6. `paso6a_metadatos_clinicos_discovery.csv` - Metadatos avanzados",
  "7. `paso6a_outliers_por_timepoint.csv` - Outliers por timepoint",
  "8. `paso6a_outliers_proporcion_por_grupo.csv` - Proporción de outliers",
  "",
  "### Figuras (PNG):",
  "1. `paso6a_distribucion_muestras.png` - Distribución por cohort/timepoint",
  "2. `paso6a_outliers_por_grupo.png` - Outliers por grupo",
  "3. `paso6a_cohort_distribucion.png` - Distribución general",
  "",
  "---",
  "",
  paste("*Análisis generado:", Sys.time(), "*"),
  "*Metadatos básicos integrados - Metadatos avanzados requieren mapeo*"
)

writeLines(report_lines, file.path(output_tables_path, "paso6a_reporte_metadatos.md"))

cat("\n=== PASO 6A COMPLETADO ===\n")
cat("Archivos generados:\n")
cat("  - Tablas: 8 archivos CSV\n")
cat("  - Figuras: 3 archivos PNG\n")
cat("  - Reporte: 1 archivo MD\n")
cat("\n✅ Metadatos básicos integrados\n")
cat("⏳ Pendiente: Mapeo de IDs para metadatos clínicos avanzados (Paso 6B)\n")

