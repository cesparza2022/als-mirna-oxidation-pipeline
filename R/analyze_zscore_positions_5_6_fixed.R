#!/usr/bin/env Rscript

# Script para analizar z-score de mutaciones G>T en posiciones 5 y 6 (versión corregida)
# miRNAs y Oxidación - Análisis ALS

library(dplyr)
library(readr)
library(stringr)
library(ComplexHeatmap)
library(circlize)
library(ggplot2)

cat("🧬 ANÁLISIS DE Z-SCORE PARA POSICIONES 5 Y 6 (HOTSPOTS G>T) - VERSIÓN CORREGIDA\n")
cat("================================================================================\n\n")

# Cargar datos procesados
df <- read_tsv("outputs/processed_snv_data_vaf_filtered.tsv", show_col_types = FALSE)

# Identificar columnas de muestras
sample_cols <- colnames(df)[!grepl("(PM\\+1MM\\+2MM|miRNA name|pos:mut|position|mutation)", colnames(df))]
total_cols <- colnames(df)[grepl("\\(PM\\+1MM\\+2MM\\)", colnames(df))]

# Filtrar solo mutaciones G>T en posiciones 5 y 6
gt_positions_5_6 <- df %>%
  filter(mutation == "GT", position %in% c(5, 6))

cat("📊 DATOS FILTRADOS:\n")
cat("   - SNVs G>T en posiciones 5-6:", nrow(gt_positions_5_6), "\n")
cat("   - miRNAs únicos:", length(unique(gt_positions_5_6$`miRNA name`)), "\n")
cat("   - Posiciones:", paste(sort(unique(gt_positions_5_6$position)), collapse = ", "), "\n\n")

# Crear matriz VAF
vaf_matrix <- as.matrix(gt_positions_5_6[, sample_cols] / gt_positions_5_6[, total_cols])
rownames(vaf_matrix) <- gt_positions_5_6$`pos:mut`
colnames(vaf_matrix) <- sample_cols
vaf_matrix[is.nan(vaf_matrix)] <- 0

# Calcular z-score por miRNA (normalizar por miRNA)
cat("📈 CALCULANDO Z-SCORE POR miRNA...\n")
zscore_matrix <- matrix(NA, nrow = nrow(vaf_matrix), ncol = ncol(vaf_matrix))
rownames(zscore_matrix) <- rownames(vaf_matrix)
colnames(zscore_matrix) <- colnames(vaf_matrix)

# Agrupar por miRNA para calcular z-score
for(mirna in unique(gt_positions_5_6$`miRNA name`)) {
  mirna_indices <- which(gt_positions_5_6$`miRNA name` == mirna)
  if(length(mirna_indices) > 1) {
    mirna_vaf <- vaf_matrix[mirna_indices, ]
    mirna_mean <- mean(mirna_vaf, na.rm = TRUE)
    mirna_sd <- sd(mirna_vaf, na.rm = TRUE)
    
    if(mirna_sd > 0) {
      zscore_matrix[mirna_indices, ] <- (mirna_vaf - mirna_mean) / mirna_sd
    } else {
      zscore_matrix[mirna_indices, ] <- 0
    }
  }
}

# Reemplazar NaN con 0
zscore_matrix[is.nan(zscore_matrix)] <- 0

cat("✅ Z-score calculado:\n")
cat("   - Dimensiones:", nrow(zscore_matrix), "x", ncol(zscore_matrix), "\n")
cat("   - Z-score promedio:", round(mean(zscore_matrix, na.rm = TRUE), 4), "\n")
cat("   - Z-score mediano:", round(median(zscore_matrix, na.rm = TRUE), 4), "\n")
cat("   - Z-score máximo:", round(max(zscore_matrix, na.rm = TRUE), 4), "\n")
cat("   - Z-score mínimo:", round(min(zscore_matrix, na.rm = TRUE), 4), "\n\n")

# Análisis por posición
cat("🎯 ANÁLISIS DE Z-SCORE POR POSICIÓN:\n")
for(pos in c(5, 6)) {
  pos_indices <- which(gt_positions_5_6$position == pos)
  if(length(pos_indices) > 0) {
    pos_zscore <- as.vector(zscore_matrix[pos_indices, ])
    pos_zscore <- pos_zscore[!is.na(pos_zscore)]
    
    cat("   Posición", pos, ":\n")
    cat("     - SNVs:", length(pos_indices), "\n")
    cat("     - Z-score promedio:", round(mean(pos_zscore), 4), "\n")
    cat("     - Z-score mediano:", round(median(pos_zscore), 4), "\n")
    cat("     - Z-score > 2 (significativo):", sum(pos_zscore > 2), "(", round(sum(pos_zscore > 2) / length(pos_zscore) * 100, 2), "%)\n")
    cat("     - Z-score > 1.96 (p<0.05):", sum(pos_zscore > 1.96), "(", round(sum(pos_zscore > 1.96) / length(pos_zscore) * 100, 2), "%)\n")
    cat("     - Z-score < -2 (significativo):", sum(pos_zscore < -2), "(", round(sum(pos_zscore < -2) / length(pos_zscore) * 100, 2), "%)\n\n")
  }
}

# Identificar SNVs con z-score más extremos
cat("🔥 TOP SNVs CON Z-SCORE MÁS EXTREMOS:\n")
zscore_values <- as.vector(zscore_matrix)
zscore_values <- zscore_values[!is.na(zscore_values)]

# Top 10 z-scores más altos
top_high_indices <- order(zscore_values, decreasing = TRUE)[1:min(10, length(zscore_values))]
top_high_values <- zscore_values[top_high_indices]

cat("   Z-scores más altos:\n")
for(i in 1:length(top_high_values)) {
  cat("     ", i, ". Z-score =", round(top_high_values[i], 3), "\n")
}

# Top 10 z-scores más bajos
top_low_indices <- order(zscore_values)[1:min(10, length(zscore_values))]
top_low_values <- zscore_values[top_low_indices]

cat("   Z-scores más bajos:\n")
for(i in 1:length(top_low_values)) {
  cat("     ", i, ". Z-score =", round(top_low_values[i], 3), "\n")
}
cat("\n")

# Crear heatmap de z-score (sin clustering problemático)
cat("🔥 Creando heatmap de z-score...\n")
pdf("outputs/zscore_heatmap_positions_5_6_fixed.pdf", width = 12, height = 10)

# Definir colores para z-score
col_fun_zscore = colorRamp2(c(-3, -1.96, 0, 1.96, 3),
                           c("blue", "lightblue", "white", "orange", "red"))

# Crear el heatmap sin clustering automático
ht_zscore <- Heatmap(zscore_matrix,
                     name = "Z-score",
                     col = col_fun_zscore,
                     cluster_rows = FALSE,  # Desactivar clustering de filas
                     cluster_columns = FALSE,  # Desactivar clustering de columnas
                     show_row_names = FALSE,
                     show_column_names = FALSE,
                     row_split = gt_positions_5_6$`miRNA name`,
                     row_title_rot = 0,
                     row_title_gp = gpar(fontsize = 8),
                     heatmap_legend_param = list(
                       title = "Z-score",
                       at = c(-3, -1.96, 0, 1.96, 3),
                       labels = c("-3", "-1.96", "0", "1.96", "3")
                     )
)

# Agregar anotación de posición
position_annotation <- gt_positions_5_6$position
names(position_annotation) <- rownames(zscore_matrix)

pos_annotation <- rowAnnotation(
  Position = position_annotation,
  col = list(Position = colorRamp2(c(5, 6), c("lightgreen", "darkgreen"))),
  annotation_legend_param = list(
    Position = list(title = "Posición")
  )
)

ht_with_annotation <- ht_zscore + pos_annotation
draw(ht_with_annotation)
dev.off()

cat("✅ Heatmap guardado en: outputs/zscore_heatmap_positions_5_6_fixed.pdf\n\n")

# Crear histograma de distribución de z-score
pdf("outputs/zscore_distribution_positions_5_6.pdf", width = 10, height = 7)
ggplot(data.frame(Z_score = zscore_values), aes(x = Z_score)) +
  geom_histogram(binwidth = 0.1, fill = "steelblue", color = "black", alpha = 0.7) +
  geom_vline(xintercept = c(-1.96, 1.96), linetype = "dashed", color = "red", size = 1) +
  geom_vline(xintercept = c(-2, 2), linetype = "dashed", color = "darkred", size = 1) +
  labs(title = "Distribución de Z-score para SNVs G>T en Posiciones 5-6",
       x = "Z-score",
       y = "Frecuencia") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold"))
dev.off()

cat("✅ Gráfico de distribución guardado en: outputs/zscore_distribution_positions_5_6.pdf\n\n")

# Análisis de miRNAs con z-score más extremos
cat("🧬 TOP miRNAs CON Z-SCORE MÁS EXTREMOS:\n")
mirna_zscore_stats <- gt_positions_5_6 %>%
  group_by(`miRNA name`) %>%
  summarise(
    snv_count = n(),
    positions = paste(sort(unique(position)), collapse = ", "),
    .groups = "drop"
  )

# Calcular estadísticas de z-score por miRNA
mirna_zscore_means <- c()
mirna_zscore_max <- c()
mirna_zscore_min <- c()
mirna_significant_high <- c()
mirna_significant_low <- c()

for(i in 1:nrow(mirna_zscore_stats)) {
  mirna_name <- mirna_zscore_stats$`miRNA name`[i]
  mirna_indices <- which(gt_positions_5_6$`miRNA name` == mirna_name)
  
  if(length(mirna_indices) > 0) {
    mirna_zscore <- as.vector(zscore_matrix[mirna_indices, ])
    mirna_zscore <- mirna_zscore[!is.na(mirna_zscore)]
    
    mirna_zscore_means <- c(mirna_zscore_means, round(mean(mirna_zscore), 4))
    mirna_zscore_max <- c(mirna_zscore_max, round(max(mirna_zscore), 4))
    mirna_zscore_min <- c(mirna_zscore_min, round(min(mirna_zscore), 4))
    mirna_significant_high <- c(mirna_significant_high, sum(mirna_zscore > 1.96))
    mirna_significant_low <- c(mirna_significant_low, sum(mirna_zscore < -1.96))
  } else {
    mirna_zscore_means <- c(mirna_zscore_means, 0)
    mirna_zscore_max <- c(mirna_zscore_max, 0)
    mirna_zscore_min <- c(mirna_zscore_min, 0)
    mirna_significant_high <- c(mirna_significant_high, 0)
    mirna_significant_low <- c(mirna_significant_low, 0)
  }
}

mirna_zscore_stats$mean_zscore <- mirna_zscore_means
mirna_zscore_stats$max_zscore <- mirna_zscore_max
mirna_zscore_stats$min_zscore <- mirna_zscore_min
mirna_zscore_stats$significant_high <- mirna_significant_high
mirna_zscore_stats$significant_low <- mirna_significant_low

# Ordenar por z-score máximo absoluto
mirna_zscore_stats$max_abs_zscore <- pmax(abs(mirna_zscore_stats$max_zscore), abs(mirna_zscore_stats$min_zscore))
mirna_zscore_stats <- mirna_zscore_stats %>% arrange(desc(max_abs_zscore))

cat("   Top 10 miRNAs con z-score más extremos:\n")
top_mirnas <- head(mirna_zscore_stats, 10)
for(i in 1:nrow(top_mirnas)) {
  cat("     ", i, ".", top_mirnas$`miRNA name`[i], "\n")
  cat("         - Posiciones:", top_mirnas$positions[i], "\n")
  cat("         - Z-score promedio:", top_mirnas$mean_zscore[i], "\n")
  cat("         - Z-score máximo:", top_mirnas$max_zscore[i], "\n")
  cat("         - Z-score mínimo:", top_mirnas$min_zscore[i], "\n")
  cat("         - Z-scores > 1.96:", top_mirnas$significant_high[i], "\n")
  cat("         - Z-scores < -1.96:", top_mirnas$significant_low[i], "\n\n")
}

# Análisis específico de los SNVs con z-score más extremos
cat("🔍 ANÁLISIS DETALLADO DE SNVs CON Z-SCORE MÁS EXTREMOS:\n")
extreme_snvs <- which(zscore_matrix > 10, arr.ind = TRUE)
if(nrow(extreme_snvs) > 0) {
  cat("   SNVs con Z-score > 10:\n")
  for(i in 1:min(5, nrow(extreme_snvs))) {
    snv_idx <- extreme_snvs[i, 1]
    sample_idx <- extreme_snvs[i, 2]
    snv_name <- rownames(zscore_matrix)[snv_idx]
    sample_name <- colnames(zscore_matrix)[sample_idx]
    zscore_val <- zscore_matrix[snv_idx, sample_idx]
    
    cat("     - SNV:", snv_name, "\n")
    cat("       - Muestra:", sample_name, "\n")
    cat("       - Z-score:", round(zscore_val, 3), "\n")
    cat("       - VAF original:", round(vaf_matrix[snv_idx, sample_idx], 4), "\n")
    cat("       - miRNA:", gt_positions_5_6$`miRNA name`[snv_idx], "\n")
    cat("       - Posición:", gt_positions_5_6$position[snv_idx], "\n\n")
  }
}

cat("🎯 ANÁLISIS DE Z-SCORE COMPLETADO\n")










