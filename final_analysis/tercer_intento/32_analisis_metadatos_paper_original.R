# =============================================================================
# ANÁLISIS DE METADATOS DEL PAPER ORIGINAL: GSE168714
# =============================================================================

# Cargar librerías necesarias
library(dplyr)
library(ggplot2)
library(readr)
library(stringr)
library(tidyr)
library(corrplot)
library(RColorBrewer)
library(viridis)

# Configurar directorio de trabajo
setwd("/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/tercer_intento")

# Crear directorio para el análisis de metadatos
output_dir <- "metadata_analysis"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

cat("=== ANÁLISIS DE METADATOS DEL PAPER ORIGINAL ===\n")
cat("Paper: 'Circulating miR-181 is a prognostic biomarker for amyotrophic lateral sclerosis'\n")
cat("GEO: GSE168714\n\n")

# --- 1. CARGAR METADATOS ---
cat("1. Cargando metadatos del paper original...\n")

# Cargar metadatos de todas las muestras
all_samples <- read.table("metadata_analysis/GSE168714_All_samples_enrolment.txt", 
                         header = TRUE, sep = "\t", stringsAsFactors = FALSE)

# Cargar metadatos de controles
controls_only <- read.table("metadata_analysis/GSE168714_Controls_only.txt", 
                           header = TRUE, sep = "\t", stringsAsFactors = FALSE)

# Cargar datos clínicos detallados
clinical_data <- read.csv("metadata_analysis/GSE168714_Data_file_related_to_fig_2_3_5_discovery.csv", 
                         stringsAsFactors = FALSE)

cat("   - Muestras totales (All samples):", ncol(all_samples) - 1, "\n")
cat("   - Muestras control:", ncol(controls_only) - 1, "\n")
cat("   - Muestras con datos clínicos:", nrow(clinical_data), "\n\n")

# --- 2. ANÁLISIS DE ESTRUCTURA DE DATOS ---
cat("2. Analizando estructura de los metadatos...\n")

# Analizar estructura de all_samples
cat("   Estructura de All_samples:\n")
cat("   - Filas (metadatos):", nrow(all_samples), "\n")
cat("   - Columnas (muestras + sample):", ncol(all_samples), "\n")
cat("   - Metadatos disponibles:\n")
for (i in 1:nrow(all_samples)) {
  cat("     ", i, ".", all_samples[i, 1], "\n")
}

# Analizar estructura de clinical_data
cat("\n   Estructura de Clinical_data:\n")
cat("   - Columnas:", ncol(clinical_data), "\n")
cat("   - Variables clínicas principales:\n")
clinical_vars <- c("sex", "onset", "treatment", "Age_at_onset", "Age_enrolment", 
                   "diagnostic_delay", "El_escorial", "FVC", "cognitive", "C9ORF72", 
                   "ALSFRS", "slope", "NfL_numeric", "miR_181_numeric")
for (var in clinical_vars) {
  if (var %in% colnames(clinical_data)) {
    cat("     -", var, "\n")
  }
}

# --- 3. ANÁLISIS DE COHORTES Y BATCHES ---
cat("\n3. Analizando cohortes y batches...\n")

# Extraer información de batch
batch_info <- all_samples[2, -1]  # Segunda fila, excluyendo la primera columna
batch_counts <- table(batch_info)
cat("   Distribución de batches:\n")
print(batch_counts)

# Extraer información de sexo
sex_info <- all_samples[3, -1]  # Tercera fila
sex_counts <- table(sex_info)
cat("\n   Distribución por sexo:\n")
print(sex_counts)

# Extraer información de onset
onset_info <- all_samples[4, -1]  # Cuarta fila
onset_counts <- table(onset_info)
cat("\n   Distribución por tipo de onset:\n")
print(onset_counts)

# --- 4. ANÁLISIS DE DATOS CLÍNICOS ---
cat("\n4. Analizando datos clínicos detallados...\n")

# Resumen estadístico de variables numéricas
numeric_vars <- c("Age_at_onset", "Age_enrolment", "diagnostic_delay", 
                  "ALSFRS", "slope", "NfL_numeric", "miR_181_numeric")
numeric_data <- clinical_data[, numeric_vars, drop = FALSE]

cat("   Resumen estadístico de variables numéricas:\n")
summary_stats <- summary(numeric_data)
print(summary_stats)

# Análisis de miR-181 (biomarcador principal del paper)
cat("\n   Análisis de miR-181 (biomarcador principal):\n")
miR181_stats <- summary(clinical_data$miR_181_numeric)
print(miR181_stats)

# Análisis de NfL (neurofilamento ligero)
cat("\n   Análisis de NfL (neurofilamento ligero):\n")
NfL_stats <- summary(clinical_data$NfL_numeric)
print(NfL_stats)

# --- 5. COMPARACIÓN CON NUESTROS DATOS ---
cat("\n5. Comparando con nuestros datos procesados...\n")

# Cargar nuestros datos procesados
our_data <- read.csv("../processed_data/final_processed_data.csv", stringsAsFactors = FALSE)

# Extraer nombres de muestras de nuestros datos
our_samples <- colnames(our_data)[grepl("^[A-Z]{3}\\d+$|^[A-Z]{3}\\d+_\\d+$", colnames(our_data))]
cat("   Nuestras muestras:", length(our_samples), "\n")

# Extraer nombres de muestras del paper original
paper_samples <- colnames(all_samples)[-1]  # Excluir primera columna
cat("   Muestras del paper:", length(paper_samples), "\n")

# Buscar coincidencias
common_samples <- intersect(our_samples, paper_samples)
cat("   Muestras comunes:", length(common_samples), "\n")

if (length(common_samples) > 0) {
  cat("   Ejemplos de muestras comunes:\n")
  print(head(common_samples, 10))
}

# --- 6. ANÁLISIS DE miR-181 EN CONTEXTO DE NUESTROS SNVs ---
cat("\n6. Analizando miR-181 en contexto de nuestros SNVs...\n")

# Buscar SNVs relacionados con miR-181 en nuestros datos
mir181_snvs <- our_data[grepl("miR-181", our_data$miRNA_name, ignore.case = TRUE), ]
cat("   SNVs de miR-181 en nuestros datos:", nrow(mir181_snvs), "\n")

if (nrow(mir181_snvs) > 0) {
  cat("   SNVs de miR-181 encontrados:\n")
  print(mir181_snvs[, c("miRNA_name", "pos", "mutation_type")])
  
  # Analizar VAFs de miR-181
  mir181_vaf_cols <- colnames(mir181_snvs)[grepl("^[A-Z]{3}\\d+$|^[A-Z]{3}\\d+_\\d+$", colnames(mir181_snvs))]
  if (length(mir181_vaf_cols) > 0) {
    mir181_vafs <- mir181_snvs[, mir181_vaf_cols]
    mir181_vafs_clean <- as.numeric(as.matrix(mir181_vafs))
    mir181_vafs_clean <- mir181_vafs_clean[!is.na(mir181_vafs_clean)]
    
    cat("   Estadísticas de VAFs de miR-181:\n")
    print(summary(mir181_vafs_clean))
  }
}

# --- 7. ANÁLISIS DE CORRELACIONES ---
cat("\n7. Analizando correlaciones entre variables clínicas...\n")

# Crear matriz de correlación
correlation_vars <- c("Age_at_onset", "Age_enrolment", "diagnostic_delay", 
                      "ALSFRS", "slope", "NfL_numeric", "miR_181_numeric")
correlation_data <- clinical_data[, correlation_vars, drop = FALSE]

# Calcular correlaciones
correlation_matrix <- cor(correlation_data, use = "complete.obs")

cat("   Matriz de correlación (variables clínicas):\n")
print(round(correlation_matrix, 3))

# --- 8. VISUALIZACIONES ---
cat("\n8. Generando visualizaciones...\n")

# Crear directorio para figuras
fig_dir <- file.path(output_dir, "figures")
if (!dir.exists(fig_dir)) {
  dir.create(fig_dir, recursive = TRUE)
}

# 8.1. Distribución de batches
p1 <- ggplot(data.frame(batch = names(batch_counts), count = as.numeric(batch_counts)), 
             aes(x = batch, y = count)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  labs(title = "Distribución de Batches en el Dataset Original",
       x = "Batch", y = "Número de Muestras") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave(file.path(fig_dir, "01_batch_distribution.png"), p1, width = 10, height = 6, dpi = 300)

# 8.2. Distribución por sexo
p2 <- ggplot(data.frame(sex = names(sex_counts), count = as.numeric(sex_counts)), 
             aes(x = sex, y = count)) +
  geom_bar(stat = "identity", fill = c("pink", "lightblue")) +
  labs(title = "Distribución por Sexo en el Dataset Original",
       x = "Sexo", y = "Número de Muestras") +
  theme_minimal()

ggsave(file.path(fig_dir, "02_sex_distribution.png"), p2, width = 8, height = 6, dpi = 300)

# 8.3. Distribución por tipo de onset
p3 <- ggplot(data.frame(onset = names(onset_counts), count = as.numeric(onset_counts)), 
             aes(x = onset, y = count)) +
  geom_bar(stat = "identity", fill = "orange") +
  labs(title = "Distribución por Tipo de Onset en el Dataset Original",
       x = "Tipo de Onset", y = "Número de Muestras") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave(file.path(fig_dir, "03_onset_distribution.png"), p3, width = 8, height = 6, dpi = 300)

# 8.4. Correlación entre miR-181 y NfL
p4 <- ggplot(clinical_data, aes(x = miR_181_numeric, y = NfL_numeric)) +
  geom_point(alpha = 0.6, color = "steelblue") +
  geom_smooth(method = "lm", se = TRUE, color = "red") +
  labs(title = "Correlación entre miR-181 y NfL",
       x = "miR-181 (nivel)", y = "NfL (nivel)") +
  theme_minimal()

ggsave(file.path(fig_dir, "04_mir181_nfl_correlation.png"), p4, width = 8, height = 6, dpi = 300)

# 8.5. Matriz de correlación
png(file.path(fig_dir, "05_correlation_matrix.png"), width = 800, height = 600)
corrplot(correlation_matrix, method = "color", type = "upper", 
         order = "hclust", tl.cex = 0.8, tl.col = "black",
         title = "Matriz de Correlación - Variables Clínicas")
dev.off()

# 8.6. Distribución de miR-181 por grupo
if (nrow(mir181_snvs) > 0) {
  # Crear datos para el boxplot
  mir181_data <- data.frame(
    sample = rep(mir181_vaf_cols, each = nrow(mir181_snvs)),
    vaf = as.numeric(as.matrix(mir181_snvs[, mir181_vaf_cols])),
    snv = rep(paste(mir181_snvs$miRNA_name, mir181_snvs$pos, mir181_snvs$mutation_type, sep = "_"), 
              length(mir181_vaf_cols))
  )
  
  # Filtrar NAs
  mir181_data <- mir181_data[!is.na(mir181_data$vaf), ]
  
  if (nrow(mir181_data) > 0) {
    p5 <- ggplot(mir181_data, aes(x = snv, y = vaf)) +
      geom_boxplot(fill = "lightgreen") +
      labs(title = "Distribución de VAFs de miR-181 en Nuestros Datos",
           x = "SNV", y = "VAF") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
    
    ggsave(file.path(fig_dir, "06_mir181_vaf_distribution.png"), p5, width = 10, height = 6, dpi = 300)
  }
}

# --- 9. RESUMEN EJECUTIVO ---
cat("\n9. Generando resumen ejecutivo...\n")

# Crear resumen
summary_text <- paste0(
  "=== RESUMEN EJECUTIVO: ANÁLISIS DE METADATOS DEL PAPER ORIGINAL ===\n\n",
  "Paper: 'Circulating miR-181 is a prognostic biomarker for amyotrophic lateral sclerosis'\n",
  "GEO: GSE168714\n\n",
  "DATOS DEL PAPER ORIGINAL:\n",
  "- Total de muestras: ", ncol(all_samples) - 1, "\n",
  "- Muestras control: ", ncol(controls_only) - 1, "\n",
  "- Muestras con datos clínicos: ", nrow(clinical_data), "\n",
  "- Batches identificados: ", length(batch_counts), "\n",
  "- Distribución por sexo: ", paste(names(sex_counts), sex_counts, collapse = ", "), "\n",
  "- Distribución por onset: ", paste(names(onset_counts), onset_counts, collapse = ", "), "\n\n",
  "BIOMARCADORES PRINCIPALES:\n",
  "- miR-181 (rango: ", round(min(clinical_data$miR_181_numeric, na.rm = TRUE), 2), " - ", 
  round(max(clinical_data$miR_181_numeric, na.rm = TRUE), 2), ")\n",
  "- NfL (rango: ", round(min(clinical_data$NfL_numeric, na.rm = TRUE), 2), " - ", 
  round(max(clinical_data$NfL_numeric, na.rm = TRUE), 2), ")\n\n",
  "COMPARACIÓN CON NUESTROS DATOS:\n",
  "- Nuestras muestras: ", length(our_samples), "\n",
  "- Muestras del paper: ", length(paper_samples), "\n",
  "- Muestras comunes: ", length(common_samples), "\n",
  "- SNVs de miR-181 en nuestros datos: ", nrow(mir181_snvs), "\n\n",
  "CORRELACIONES CLAVE:\n",
  "- miR-181 vs NfL: ", round(correlation_matrix["miR_181_numeric", "NfL_numeric"], 3), "\n",
  "- miR-181 vs ALSFRS: ", round(correlation_matrix["miR_181_numeric", "ALSFRS"], 3), "\n",
  "- NfL vs ALSFRS: ", round(correlation_matrix["NfL_numeric", "ALSFRS"], 3), "\n\n",
  "IMPLICACIONES PARA NUESTRO ANÁLISIS:\n",
  "1. El paper original se enfoca en miR-181 como biomarcador pronóstico\n",
  "2. Nuestros datos incluyen SNVs en miR-181 que podrían ser relevantes\n",
  "3. La correlación entre miR-181 y NfL sugiere vías biológicas comunes\n",
  "4. Los datos clínicos permiten validar nuestros hallazgos de SNVs\n",
  "5. Los batches y covariables deben considerarse en nuestros análisis\n\n",
  "PRÓXIMOS PASOS RECOMENDADOS:\n",
  "1. Analizar SNVs específicos en miR-181 en contexto clínico\n",
  "2. Correlacionar nuestros SNVs con variables clínicas del paper\n",
  "3. Validar nuestros hallazgos contra los biomarcadores conocidos\n",
  "4. Considerar efectos de batch en nuestros análisis\n",
  "5. Integrar datos de supervivencia para análisis pronóstico\n"
)

# Guardar resumen
writeLines(summary_text, file.path(output_dir, "resumen_metadatos_paper_original.txt"))

cat("=== ANÁLISIS DE METADATOS COMPLETADO ===\n")
cat("Resumen guardado en:", file.path(output_dir, "resumen_metadatos_paper_original.txt"), "\n")
cat("Figuras guardadas en:", fig_dir, "/\n")
cat("Archivos generados:\n")
cat("- 01_batch_distribution.png\n")
cat("- 02_sex_distribution.png\n")
cat("- 03_onset_distribution.png\n")
cat("- 04_mir181_nfl_correlation.png\n")
cat("- 05_correlation_matrix.png\n")
if (nrow(mir181_snvs) > 0) {
  cat("- 06_mir181_vaf_distribution.png\n")
}
cat("\n✅ Análisis de metadatos del paper original completado exitosamente!\n")









