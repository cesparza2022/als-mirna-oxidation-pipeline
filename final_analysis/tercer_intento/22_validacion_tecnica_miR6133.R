# =============================================================================
# VALIDACIÓN TÉCNICA DEL hsa-miR-6133 COMO POSIBLE ARTEFACTO
# =============================================================================
# Objetivo: Determinar si hsa-miR-6133_6:GT es un artefacto técnico o hallazgo biológico
# Análisis de calidad, distribución, y características técnicas
# =============================================================================

# Cargar librerías
library(dplyr)
library(ggplot2)
library(tidyr)
library(stringr)
library(reshape2)
library(gridExtra)
library(RColorBrewer)
library(viridis)

# Configurar directorio de trabajo
setwd("/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/tercer_intento")

# =============================================================================
# 1. CARGA DE DATOS Y PREPARACIÓN
# =============================================================================

cat("=== VALIDACIÓN TÉCNICA DEL hsa-miR-6133 ===\n\n")

# Cargar datos preprocesados
cat("1. Cargando datos preprocesados...\n")
final_data <- read.csv("../processed_data/final_processed_data.csv", stringsAsFactors = FALSE)

cat("   - Datos cargados:", nrow(final_data), "SNVs\n")
cat("   - Columnas disponibles:", paste(colnames(final_data), collapse = ", "), "\n\n")

# Extraer pos y mutation_type de pos.mut para todos los datos
if ("pos.mut" %in% colnames(final_data)) {
  cat("   - Extrayendo pos y mutation_type de pos.mut para todos los datos...\n")
  final_data$pos <- as.numeric(gsub(":.*", "", final_data$pos.mut))
  final_data$mutation_type <- gsub(".*:", "", final_data$pos.mut)
  cat("   - Extracción completada\n\n")
}

# =============================================================================
# 2. ANÁLISIS ESPECÍFICO DEL hsa-miR-6133
# =============================================================================

cat("2. Analizando hsa-miR-6133 específicamente...\n")

# Filtrar solo hsa-miR-6133
mir6133_data <- final_data[final_data$miRNA_name == "hsa-miR-6133", ]

cat("   - SNVs de hsa-miR-6133 encontrados:", nrow(mir6133_data), "\n")
cat("   - Posiciones y mutaciones:\n")
print(table(mir6133_data$pos, mir6133_data$mutation_type))

# Análisis específico de la posición 6:GT
mir6133_6gt <- mir6133_data[mir6133_data$pos == 6 & mir6133_data$mutation_type == "GT", ]

if (nrow(mir6133_6gt) > 0) {
  cat("\n   - hsa-miR-6133_6:GT encontrado:", nrow(mir6133_6gt), "instancia(s)\n")
  
  # Extraer columnas de muestras
  sample_cols <- grep("^Magen\\.", names(mir6133_6gt), value = TRUE)
  sample_cols <- sample_cols[!grepl("\\.\\.PM\\.1MM\\.2MM\\.$", sample_cols)]
  
  cat("   - Muestras analizadas:", length(sample_cols), "\n")
  
  # Calcular estadísticas de VAF para hsa-miR-6133_6:GT
  vaf_data <- mir6133_6gt[, sample_cols]
  
  # Convertir a numérico y calcular estadísticas
  vaf_numeric <- as.numeric(unlist(vaf_data))
  vaf_numeric <- vaf_numeric[!is.na(vaf_numeric)]
  
  cat("   - VAFs válidos:", length(vaf_numeric), "\n")
  cat("   - VAF promedio:", round(mean(vaf_numeric), 4), "\n")
  cat("   - VAF mediana:", round(median(vaf_numeric), 4), "\n")
  cat("   - VAF máximo:", round(max(vaf_numeric), 4), "\n")
  cat("   - VAF mínimo:", round(min(vaf_numeric), 4), "\n")
  cat("   - VAF > 0:", sum(vaf_numeric > 0), "muestras\n")
  cat("   - VAF > 0.1:", sum(vaf_numeric > 0.1), "muestras\n")
  cat("   - VAF > 0.5:", sum(vaf_numeric > 0.5), "muestras\n")
  
} else {
  cat("\n   - hsa-miR-6133_6:GT NO encontrado en los datos\n")
}

# =============================================================================
# 3. ANÁLISIS COMPARATIVO CON OTROS miRNAs
# =============================================================================

cat("\n3. Análisis comparativo con otros miRNAs...\n")

# Obtener todos los miRNAs únicos
all_mirnas <- unique(final_data$miRNA_name)
cat("   - Total de miRNAs en el dataset:", length(all_mirnas), "\n")

# Análisis de distribución de SNVs por miRNA
snv_per_mirna <- final_data %>%
  group_by(miRNA_name) %>%
  summarise(
    n_snvs = n(),
    n_positions = length(unique(pos)),
    n_mutations = length(unique(mutation_type)),
    .groups = 'drop'
  ) %>%
  arrange(desc(n_snvs))

cat("   - Top 10 miRNAs con más SNVs:\n")
print(head(snv_per_mirna, 10))

# Verificar si hsa-miR-6133 está en el top
mir6133_rank <- which(snv_per_mirna$miRNA_name == "hsa-miR-6133")
if (length(mir6133_rank) > 0) {
  cat("   - hsa-miR-6133 está en la posición:", mir6133_rank, "de", nrow(snv_per_mirna), "miRNAs\n")
  cat("   - SNVs de hsa-miR-6133:", snv_per_mirna$n_snvs[mir6133_rank], "\n")
} else {
  cat("   - hsa-miR-6133 NO encontrado en el ranking\n")
}

# =============================================================================
# 4. ANÁLISIS DE CALIDAD TÉCNICA
# =============================================================================

cat("\n4. Análisis de calidad técnica...\n")

# Función para calcular métricas de calidad por SNV
calculate_quality_metrics <- function(snv_data, sample_cols) {
  vaf_data <- snv_data[, sample_cols]
  vaf_numeric <- as.numeric(unlist(vaf_data))
  vaf_numeric <- vaf_numeric[!is.na(vaf_numeric)]
  
  if (length(vaf_numeric) == 0) {
    return(data.frame(
      n_samples = 0,
      n_detected = 0,
      detection_rate = 0,
      mean_vaf = NA,
      median_vaf = NA,
      max_vaf = NA,
      vaf_variance = NA,
      high_vaf_samples = 0
    ))
  }
  
  return(data.frame(
    n_samples = length(sample_cols),
    n_detected = sum(vaf_numeric > 0),
    detection_rate = sum(vaf_numeric > 0) / length(sample_cols),
    mean_vaf = mean(vaf_numeric),
    median_vaf = median(vaf_numeric),
    max_vaf = max(vaf_numeric),
    vaf_variance = var(vaf_numeric),
    high_vaf_samples = sum(vaf_numeric > 0.1)
  ))
}

# Calcular métricas para hsa-miR-6133_6:GT
if (nrow(mir6133_6gt) > 0) {
  mir6133_quality <- calculate_quality_metrics(mir6133_6gt, sample_cols)
  cat("   - Métricas de calidad para hsa-miR-6133_6:GT:\n")
  print(mir6133_quality)
}

# Calcular métricas para otros SNVs de hsa-miR-6133
if (nrow(mir6133_data) > 0) {
  cat("\n   - Métricas de calidad para todos los SNVs de hsa-miR-6133:\n")
  mir6133_all_quality <- mir6133_data %>%
    group_by(pos, mutation_type) %>%
    do(calculate_quality_metrics(., sample_cols)) %>%
    ungroup()
  
  print(mir6133_all_quality)
}

# =============================================================================
# 5. ANÁLISIS DE DISTRIBUCIÓN ESPACIAL
# =============================================================================

cat("\n5. Análisis de distribución espacial...\n")

# Análisis de distribución por posición en hsa-miR-6133
if (nrow(mir6133_data) > 0) {
  cat("   - Distribución de SNVs por posición en hsa-miR-6133:\n")
  pos_distribution <- table(mir6133_data$pos)
  print(pos_distribution)
  
  # Verificar si la posición 6 es atípica
  if (6 %in% names(pos_distribution)) {
    pos6_count <- pos_distribution["6"]
    other_positions <- pos_distribution[names(pos_distribution) != "6"]
    max_other <- max(other_positions)
    
    cat("   - Posición 6 tiene", pos6_count, "SNVs\n")
    cat("   - Máximo en otras posiciones:", max_other, "\n")
    cat("   - ¿Posición 6 es atípica?", pos6_count > max_other * 2, "\n")
  }
}

# =============================================================================
# 6. ANÁLISIS DE CORRELACIÓN CON CARGA OXIDATIVA
# =============================================================================

cat("\n6. Análisis de correlación con carga oxidativa...\n")

# Cargar datos de carga oxidativa
load("oxidative_load_analysis_results.RData")

# Crear función para calcular carga oxidativa por muestra
calculate_sample_oxidative_load <- function(sample_id, snv_data, sample_cols) {
  # Filtrar SNVs de hsa-miR-6133_6:GT
  mir6133_6gt_snvs <- snv_data[snv_data$miRNA_name == "hsa-miR-6133" & 
                               snv_data$pos == 6 & 
                               snv_data$mutation_type == "GT", ]
  
  if (nrow(mir6133_6gt_snvs) == 0) {
    return(0)
  }
  
  # Obtener VAF para esta muestra
  sample_col <- sample_cols[grepl(sample_id, sample_cols)]
  if (length(sample_col) == 0) {
    return(0)
  }
  
  vaf <- as.numeric(mir6133_6gt_snvs[[sample_col]])
  if (is.na(vaf)) {
    return(0)
  }
  
  return(vaf)
}

# Calcular carga oxidativa específica de hsa-miR-6133_6:GT
if (nrow(mir6133_6gt) > 0) {
  cat("   - Calculando carga oxidativa específica de hsa-miR-6133_6:GT...\n")
  
  # Crear dataframe con carga oxidativa específica
  mir6133_oxidative <- data.frame(
    sample_id = sample_cols,
    mir6133_6gt_vaf = sapply(sample_cols, function(s) {
      calculate_sample_oxidative_load(s, final_data, sample_cols)
    })
  )
  
  # Unir con datos de carga oxidativa general
  mir6133_oxidative <- merge(mir6133_oxidative, oxidative_metrics, by = "sample_id", all.x = TRUE)
  
  # Calcular correlación
  correlation <- cor(mir6133_oxidative$mir6133_6gt_vaf, 
                     mir6133_oxidative$oxidative_score, 
                     use = "complete.obs")
  
  cat("   - Correlación hsa-miR-6133_6:GT vs carga oxidativa general:", round(correlation, 4), "\n")
  
  # Análisis por grupo
  mir6133_oxidative$group <- ifelse(grepl("control", mir6133_oxidative$sample_id, ignore.case = TRUE), "Control", "ALS")
  
  group_analysis <- mir6133_oxidative %>%
    group_by(group) %>%
    summarise(
      n_samples = n(),
      n_detected = sum(mir6133_6gt_vaf > 0),
      detection_rate = sum(mir6133_6gt_vaf > 0) / n(),
      mean_vaf = mean(mir6133_6gt_vaf, na.rm = TRUE),
      mean_oxidative = mean(oxidative_score, na.rm = TRUE),
      .groups = 'drop'
    )
  
  cat("   - Análisis por grupo:\n")
  print(group_analysis)
}

# =============================================================================
# 7. ANÁLISIS DE ARTEFACTOS TÉCNICOS
# =============================================================================

cat("\n7. Análisis de artefactos técnicos...\n")

# Verificar patrones que podrían indicar artefactos
if (nrow(mir6133_6gt) > 0) {
  cat("   - Verificando patrones de artefactos:\n")
  
  # 1. Verificar si hay patrones de batch
  batch_pattern <- grepl("SRR139344", sample_cols)
  if (sum(batch_pattern) > 0) {
    cat("     * Patrón de batch detectado en nombres de muestra\n")
  }
  
  # 2. Verificar distribución de VAFs
  vaf_data <- as.numeric(unlist(mir6133_6gt[, sample_cols]))
  vaf_data <- vaf_data[!is.na(vaf_data)]
  
  if (length(vaf_data) > 0) {
    # Verificar si hay muchos valores idénticos (posible artefacto)
    unique_vafs <- length(unique(vaf_data))
    total_vafs <- length(vaf_data)
    identical_ratio <- unique_vafs / total_vafs
    
    cat("     * Ratio de VAFs únicos:", round(identical_ratio, 4), "\n")
    cat("     * ¿Posible artefacto?", identical_ratio < 0.5, "\n")
    
    # Verificar distribución bimodal
    hist_data <- hist(vaf_data, plot = FALSE)
    peaks <- length(hist_data$counts[hist_data$counts > max(hist_data$counts) * 0.1])
    cat("     * Número de picos en distribución:", peaks, "\n")
    cat("     * ¿Distribución bimodal?", peaks > 2, "\n")
  }
}

# =============================================================================
# 8. GENERACIÓN DE VISUALIZACIONES
# =============================================================================

cat("\n8. Generando visualizaciones...\n")

# Crear directorio para figuras
if (!dir.exists("figures_mir6133_validation")) {
  dir.create("figures_mir6133_validation")
}

# 8.1 Distribución de VAFs de hsa-miR-6133_6:GT
if (nrow(mir6133_6gt) > 0) {
  vaf_data <- as.numeric(unlist(mir6133_6gt[, sample_cols]))
  vaf_data <- vaf_data[!is.na(vaf_data)]
  
  if (length(vaf_data) > 0) {
    p1 <- ggplot(data.frame(vaf = vaf_data), aes(x = vaf)) +
      geom_histogram(bins = 30, fill = "steelblue", alpha = 0.7) +
      labs(
        title = "Distribución de VAFs - hsa-miR-6133_6:GT",
        x = "VAF",
        y = "Frecuencia"
      ) +
      theme_classic(base_size = 14) +
      theme(plot.title = element_text(hjust = 0.5, face = "bold"))
    
    ggsave("figures_mir6133_validation/01_vaf_distribution_mir6133_6gt.png", p1, width = 10, height = 6, dpi = 300)
  }
}

# 8.2 Comparación con otros miRNAs
if (nrow(mir6133_data) > 0) {
  # Crear dataframe para comparación
  comparison_data <- data.frame(
    miRNA = "hsa-miR-6133",
    n_snvs = nrow(mir6133_data),
    n_positions = length(unique(mir6133_data$pos)),
    n_mutations = length(unique(mir6133_data$mutation_type))
  )
  
  # Agregar otros miRNAs para comparación
  other_mirnas <- snv_per_mirna[1:10, ]
  other_mirnas$miRNA <- "Otros miRNAs"
  
  comparison_plot_data <- rbind(
    comparison_data,
    data.frame(
      miRNA = "Otros miRNAs",
      n_snvs = mean(other_mirnas$n_snvs),
      n_positions = mean(other_mirnas$n_positions),
      n_mutations = mean(other_mirnas$n_mutations)
    )
  )
  
  p2 <- ggplot(comparison_plot_data, aes(x = miRNA, y = n_snvs, fill = miRNA)) +
    geom_bar(stat = "identity", alpha = 0.7) +
    scale_fill_manual(values = c("hsa-miR-6133" = "#D62728", "Otros miRNAs" = "#2E8B57")) +
    labs(
      title = "Comparación de SNVs - hsa-miR-6133 vs Otros miRNAs",
      x = "miRNA",
      y = "Número de SNVs"
    ) +
    theme_classic(base_size = 14) +
    theme(plot.title = element_text(hjust = 0.5, face = "bold"))
  
  ggsave("figures_mir6133_validation/02_comparison_other_mirnas.png", p2, width = 8, height = 6, dpi = 300)
}

# 8.3 Correlación con carga oxidativa
if (exists("mir6133_oxidative") && nrow(mir6133_oxidative) > 0) {
  p3 <- ggplot(mir6133_oxidative, aes(x = mir6133_6gt_vaf, y = oxidative_score, color = group)) +
    geom_point(alpha = 0.7) +
    geom_smooth(method = "lm", se = TRUE) +
    scale_color_manual(values = c("ALS" = "#D62728", "Control" = "#2E8B57")) +
    labs(
      title = "Correlación hsa-miR-6133_6:GT vs Carga Oxidativa",
      x = "VAF hsa-miR-6133_6:GT",
      y = "Score de Carga Oxidativa",
      color = "Grupo"
    ) +
    theme_classic(base_size = 14) +
    theme(plot.title = element_text(hjust = 0.5, face = "bold"))
  
  ggsave("figures_mir6133_validation/03_correlation_oxidative_load.png", p3, width = 10, height = 6, dpi = 300)
}

# =============================================================================
# 9. CONCLUSIÓN Y RECOMENDACIONES
# =============================================================================

cat("\n9. CONCLUSIÓN Y RECOMENDACIONES\n")
cat("===============================\n\n")

# Evaluar si es artefacto o hallazgo biológico
artefact_score <- 0
biological_score <- 0

if (nrow(mir6133_6gt) > 0) {
  # Factores que sugieren artefacto
  if (exists("identical_ratio") && identical_ratio < 0.5) {
    artefact_score <- artefact_score + 2
    cat("⚠️  ARTEACTO: Ratio de VAFs únicos muy bajo\n")
  }
  
  if (exists("peaks") && peaks > 2) {
    artefact_score <- artefact_score + 1
    cat("⚠️  ARTEACTO: Distribución bimodal detectada\n")
  }
  
  # Factores que sugieren hallazgo biológico
  if (exists("correlation") && abs(correlation) > 0.3) {
    biological_score <- biological_score + 2
    cat("✅ BIOLÓGICO: Correlación significativa con carga oxidativa\n")
  }
  
  if (exists("group_analysis") && nrow(group_analysis) > 1) {
    detection_diff <- abs(group_analysis$detection_rate[1] - group_analysis$detection_rate[2])
    if (detection_diff > 0.1) {
      biological_score <- biological_score + 1
      cat("✅ BIOLÓGICO: Diferencia en detección entre grupos\n")
    }
  }
}

cat("\n📊 EVALUACIÓN FINAL:\n")
cat("   - Puntuación de artefacto:", artefact_score, "/3\n")
cat("   - Puntuación biológica:", biological_score, "/3\n")

if (artefact_score > biological_score) {
  cat("   - CONCLUSIÓN: Probable ARTEFACTO técnico\n")
  cat("   - RECOMENDACIÓN: Excluir de análisis posteriores\n")
} else if (biological_score > artefact_score) {
  cat("   - CONCLUSIÓN: Probable HALLAZGO biológico\n")
  cat("   - RECOMENDACIÓN: Incluir en análisis posteriores\n")
} else {
  cat("   - CONCLUSIÓN: Incierto - requiere análisis adicional\n")
  cat("   - RECOMENDACIÓN: Análisis más profundo necesario\n")
}

cat("\n📁 ARCHIVOS GENERADOS:\n")
cat("   - 22_validacion_tecnica_miR6133.R - Script principal\n")
cat("   - figures_mir6133_validation/ - Visualizaciones\n")

cat("\n✅ VALIDACIÓN TÉCNICA COMPLETADA\n")
cat("================================\n\n")
