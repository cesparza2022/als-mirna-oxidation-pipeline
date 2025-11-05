# =============================================================================
# ANÁLISIS DETALLADO TODAS LAS POSICIONES - G>T MUTATIONS
# =============================================================================
# Script para analizar todas las posiciones con mutaciones G>T
# Incluye estadísticas, VAF, Z-score, miRNAs más afectados, etc.
# =============================================================================

# Cargar librerías
library(dplyr)
library(readr)
library(stringr)
library(tibble)
library(ggplot2)
library(ComplexHeatmap)
library(circlize)
library(gridExtra)

# Configurar opciones
ht_opt$message = FALSE
options(warn = -1)

cat("🔬 ANÁLISIS DETALLADO TODAS LAS POSICIONES - G>T MUTATIONS\n")
cat("=========================================================\n\n")

# --- 1. CARGAR DATOS ---
cat("📊 1. CARGANDO DATOS\n")
cat("===================\n")

# Cargar datos principales
df_main <- read.csv("organized/04_results/alex_df.csv", stringsAsFactors = FALSE)
df_vaf <- read.csv("organized/04_results/VAF_df.csv", stringsAsFactors = FALSE)

cat("✅ Datos cargados:\n")
cat("   - df_main:", nrow(df_main), "filas\n")
cat("   - df_vaf:", nrow(df_vaf), "filas\n\n")

# --- 2. ANÁLISIS DE POSICIONES DISPONIBLES ---
cat("🎯 2. ANÁLISIS DE POSICIONES DISPONIBLES\n")
cat("=======================================\n")

# Extraer columnas de muestras (excluir columnas de metadatos)
sample_cols <- names(df_main)[!names(df_main) %in% c("X", "miRNA.name", "pos.mut")]

# Filtrar solo mutaciones G>T
gt_mutations <- df_main %>%
  filter(str_detect(pos.mut, "G>T$"))

cat("✅ Total mutaciones G>T encontradas:", nrow(gt_mutations), "\n")

# Extraer posiciones
gt_mutations <- gt_mutations %>%
  mutate(
    position = as.numeric(str_extract(pos.mut, "^[0-9]+")),
    miRNA_name = str_extract(miRNA.name, "^[^-]+")
  )

# Análisis por posición
position_summary <- gt_mutations %>%
  group_by(position) %>%
  summarise(
    count = n(),
    .groups = 'drop'
  ) %>%
  arrange(desc(count))

cat("\n📊 DISTRIBUCIÓN POR POSICIÓN:\n")
print(position_summary)

# --- 3. ANÁLISIS DETALLADO DE LAS TOP 5 POSICIONES ---
cat("\n🔍 3. ANÁLISIS DETALLADO TOP 5 POSICIONES\n")
cat("==========================================\n")

# Separar grupos
als_cols <- sample_cols[str_detect(sample_cols, "ALS")]
control_cols <- sample_cols[str_detect(sample_cols, "Control")]

# Función para analizar una posición específica
analyze_position <- function(pos_num) {
  cat("\n📍 ANÁLISIS POSICIÓN", pos_num, "\n")
  cat("========================\n")
  
  # Filtrar posición específica
  pos_data <- gt_mutations %>%
    filter(position == pos_num)
  
  if (nrow(pos_data) == 0) {
    cat("❌ No hay mutaciones G>T en posición", pos_num, "\n")
    return(NULL)
  }
  
  # Calcular estadísticas básicas
  pos_stats <- pos_data %>%
    select(all_of(sample_cols)) %>%
    summarise(
      total_snvs = n(),
      vaf_als = mean(select(., all_of(als_cols)) %>% rowMeans(na.rm = TRUE)),
      vaf_control = mean(select(., all_of(control_cols)) %>% rowMeans(na.rm = TRUE)),
      vaf_difference = vaf_als - vaf_control,
      vaf_percentage_diff = (vaf_difference / vaf_control) * 100
    )
  
  # Calcular Z-score
  pos_vaf_data <- pos_data %>%
    select(all_of(sample_cols)) %>%
    as.matrix()
  
  als_means <- rowMeans(pos_vaf_data[, als_cols], na.rm = TRUE)
  control_means <- rowMeans(pos_vaf_data[, control_cols], na.rm = TRUE)
  
  pooled_sd <- sqrt(((length(als_cols) - 1) * var(als_means) + 
                     (length(control_cols) - 1) * var(control_means)) / 
                    (length(als_cols) + length(control_cols) - 2))
  
  z_score <- (mean(als_means) - mean(control_means)) / pooled_sd
  
  # Análisis por miRNA
  mirna_analysis <- pos_data %>%
    mutate(
      vaf_als = rowMeans(select(., all_of(als_cols)), na.rm = TRUE),
      vaf_control = rowMeans(select(., all_of(control_cols)), na.rm = TRUE),
      vaf_difference = vaf_als - vaf_control
    ) %>%
    group_by(miRNA_name) %>%
    summarise(
      count_als = sum(vaf_als > 0),
      count_control = sum(vaf_control > 0),
      total_count = n(),
      vaf_als_avg = mean(vaf_als),
      vaf_control_avg = mean(vaf_control),
      vaf_difference_avg = mean(vaf_difference),
      .groups = 'drop'
    ) %>%
    arrange(desc(total_count))
  
  # Imprimir resultados
  cat("📊 ESTADÍSTICAS POSICIÓN", pos_num, ":\n")
  cat("   - Total SNVs G>T: ", pos_stats$total_snvs, "\n")
  cat("   - VAF promedio ALS: ", round(pos_stats$vaf_als, 2), "\n")
  cat("   - VAF promedio Control: ", round(pos_stats$vaf_control, 2), "\n")
  cat("   - Diferencia VAF: ", round(pos_stats$vaf_difference, 2), "\n")
  cat("   - % Diferencia: ", round(pos_stats$vaf_percentage_diff, 2), "%\n")
  cat("   - Z-score: ", round(z_score, 6), "\n")
  cat("   - Significancia: ", ifelse(abs(z_score) > 1.96, "SÍ (p<0.05)", "NO"), "\n")
  
  cat("\n🧬 TOP 5 miRNAs MÁS AFECTADOS:\n")
  for (i in 1:min(5, nrow(mirna_analysis))) {
    mirna <- mirna_analysis[i, ]
    cat("   ", i, ". ", mirna$miRNA_name, " (", mirna$total_count, " SNVs, VAF diff: ", round(mirna$vaf_difference_avg, 2), ")\n")
  }
  
  return(list(
    position = pos_num,
    stats = pos_stats,
    z_score = z_score,
    mirna_analysis = mirna_analysis,
    data = pos_data
  ))
}

# Analizar las top 5 posiciones
top_positions <- position_summary$position[1:5]
position_results <- list()

for (pos in top_positions) {
  result <- analyze_position(pos)
  if (!is.null(result)) {
    position_results[[as.character(pos)]] <- result
  }
}

# --- 4. CREAR VISUALIZACIONES COMPARATIVAS ---
cat("\n📊 4. CREANDO VISUALIZACIONES COMPARATIVAS\n")
cat("==========================================\n")

# Crear directorio de salida
if (!dir.exists("outputs/final_paper_graphs")) {
  dir.create("outputs/final_paper_graphs", recursive = TRUE)
}

# 4.1 Gráfica comparativa de VAF por posición
comparison_data <- data.frame()
for (pos in names(position_results)) {
  result <- position_results[[pos]]
  comparison_data <- rbind(comparison_data, data.frame(
    Position = as.numeric(pos),
    Group = "ALS",
    VAF = result$stats$vaf_als,
    Z_Score = result$z_score
  ))
  comparison_data <- rbind(comparison_data, data.frame(
    Position = as.numeric(pos),
    Group = "Control", 
    VAF = result$stats$vaf_control,
    Z_Score = result$z_score
  ))
}

p1 <- ggplot(comparison_data, aes(x = factor(Position), y = VAF, fill = Group)) +
  geom_col(position = "dodge", alpha = 0.8) +
  scale_fill_manual(values = c("ALS" = "#FF6B6B", "Control" = "#4ECDC4")) +
  labs(
    title = "VAF Comparison: Top 5 Positions with G>T Mutations",
    subtitle = "ALS vs Control by Position",
    x = "Position",
    y = "VAF (Variant Allele Frequency)",
    fill = "Group"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    legend.position = "bottom"
  )

# 4.2 Gráfica de Z-scores por posición
zscore_data <- data.frame(
  Position = as.numeric(names(position_results)),
  Z_Score = sapply(position_results, function(x) x$z_score),
  Significance = sapply(position_results, function(x) abs(x$z_score) > 1.96)
)

p2 <- ggplot(zscore_data, aes(x = factor(Position), y = Z_Score, fill = Significance)) +
  geom_col(alpha = 0.8) +
  geom_hline(yintercept = c(-1.96, 1.96), linetype = "dashed", color = "red", alpha = 0.7) +
  scale_fill_manual(values = c("FALSE" = "#4ECDC4", "TRUE" = "#FF6B6B")) +
  labs(
    title = "Z-Score Analysis: Top 5 Positions with G>T Mutations",
    subtitle = "Statistical Significance (p<0.05 threshold: ±1.96)",
    x = "Position",
    y = "Z-Score",
    fill = "Significant"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    legend.position = "bottom"
  )

# 4.3 Gráfica de distribución por posición
p3 <- ggplot(position_summary[1:10, ], aes(x = factor(position), y = count)) +
  geom_col(fill = "#45B7D1", alpha = 0.8) +
  labs(
    title = "Distribution of G>T Mutations by Position",
    subtitle = "Top 10 Positions with Most G>T Mutations",
    x = "Position",
    y = "Number of G>T Mutations"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

# Guardar gráficas
ggsave("outputs/final_paper_graphs/position_vaf_comparison.pdf", p1, 
       width = 10, height = 6, dpi = 300)
ggsave("outputs/final_paper_graphs/position_zscore_analysis.pdf", p2, 
       width = 10, height = 6, dpi = 300)
ggsave("outputs/final_paper_graphs/position_distribution.pdf", p3, 
       width = 10, height = 6, dpi = 300)

cat("✅ Gráficas guardadas:\n")
cat("   - position_vaf_comparison.pdf\n")
cat("   - position_zscore_analysis.pdf\n")
cat("   - position_distribution.pdf\n\n")

# --- 5. RESUMEN FINAL ---
cat("📋 5. RESUMEN FINAL TODAS LAS POSICIONES\n")
cat("========================================\n")

cat("🎯 HALLAZGOS PRINCIPALES:\n")
cat("   - Total mutaciones G>T: ", nrow(gt_mutations), "\n")
cat("   - Posiciones con mutaciones G>T: ", nrow(position_summary), "\n")
cat("   - Posición con más mutaciones: ", position_summary$position[1], " (", position_summary$count[1], " SNVs)\n\n")

cat("📊 TOP 5 POSICIONES MÁS AFECTADAS:\n")
for (i in 1:5) {
  pos <- position_summary$position[i]
  count <- position_summary$count[i]
  if (pos %in% names(position_results)) {
    result <- position_results[[as.character(pos)]]
    cat("   ", i, ". Posición ", pos, ": ", count, " SNVs, VAF ALS: ", round(result$stats$vaf_als, 2), 
        ", VAF Control: ", round(result$stats$vaf_control, 2), ", Z-score: ", round(result$z_score, 4), "\n")
  } else {
    cat("   ", i, ". Posición ", pos, ": ", count, " SNVs\n")
  }
}

cat("\n✅ Análisis completado exitosamente!\n")










