#!/usr/bin/env Rscript

# =============================================================================
# COMPREHENSIVE INITIAL ANALYSIS - miRNAs y Oxidación ALS
# =============================================================================
# Análisis descriptivo completo de los datos procesados
# Incluye: contabilidad, proporciones, mutaciones más presentes, posiciones,
# número de miRNAs/SNVs, miRNAs más presentes (RPMs), más mutados (VAFs)
# =============================================================================

# Cargar librerías
library(readr)
library(dplyr)
library(ggplot2)
library(ComplexHeatmap)
library(circlize)
library(RColorBrewer)
library(viridis)
library(reshape2)
library(stringr)

# Configurar directorio de trabajo
setwd("/Users/cesaresparza/New_Desktop/UCSD/8OG")

cat("🔬 COMPREHENSIVE INITIAL ANALYSIS - miRNAs y Oxidación ALS\n")
cat(paste(rep("=", 80), collapse = ""), "\n")
cat("📅 Date:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n")

# =============================================================================
# 1. CARGA DE DATOS PROCESADOS
# =============================================================================

cat("📁 Loading processed data...\n")
df <- read_tsv("outputs/processed_snv_data_vaf_filtered.tsv", show_col_types = FALSE)

# Identificar columnas
all_cols <- colnames(df)
meta_cols <- c("miRNA name", "pos:mut", "position", "mutation")
snv_cols <- all_cols[!all_cols %in% meta_cols & !grepl("\\(PM\\+1MM\\+2MM\\)", all_cols)]
total_cols <- all_cols[grepl("\\(PM\\+1MM\\+2MM\\)", all_cols)]

cat("✅ Data loaded successfully\n")
cat("   📊 Total SNVs:", nrow(df), "\n")
cat("   📊 Total samples:", length(snv_cols), "\n")

# Identificar mutaciones G>T específicamente
df$is_gt_mutation <- df$mutation == "GT"
cat("   📊 Meta columns:", length(meta_cols), "\n")
cat("   📊 SNV count columns:", length(snv_cols), "\n")
cat("   📊 Total count columns:", length(total_cols), "\n\n")

# =============================================================================
# 2. ANÁLISIS DESCRIPTIVO BÁSICO
# =============================================================================

cat("📊 BASIC DESCRIPTIVE STATISTICS\n")
cat(paste(rep("-", 50), collapse = ""), "\n")

# Número de miRNAs únicos
unique_mirnas <- length(unique(df$`miRNA name`))
cat("🧬 Unique miRNAs:", unique_mirnas, "\n")

# Número de SNVs únicos
unique_snvs <- length(unique(df$`pos:mut`))
cat("🔬 Unique SNVs:", unique_snvs, "\n")

# Número de posiciones únicas
unique_positions <- length(unique(df$position))
cat("📍 Unique positions:", unique_positions, "\n")

# Número de mutaciones únicas
unique_mutations <- length(unique(df$mutation))
cat("⚡ Unique mutations:", unique_mutations, "\n")

# Separar SNVs PM vs no-PM
pm_snvs <- sum(df$`pos:mut` == "PM")
non_pm_snvs <- sum(df$`pos:mut` != "PM")
cat("✅ Perfect Match (PM) SNVs:", pm_snvs, "\n")
cat("🔄 Non-PM (mutated) SNVs:", non_pm_snvs, "\n")
cat("📈 Mutation rate:", round((non_pm_snvs / nrow(df)) * 100, 1), "%\n")

# Contar mutaciones G>T
gt_mutations <- sum(df$is_gt_mutation, na.rm = TRUE)
cat("🧬 G>T mutations:", gt_mutations, "\n\n")

# =============================================================================
# 3. ANÁLISIS DE MUTACIONES MÁS FRECUENTES
# =============================================================================

cat("🔥 MOST FREQUENT MUTATIONS\n")
cat(paste(rep("-", 50), collapse = ""), "\n")

# Top mutaciones por frecuencia
mutation_counts <- table(df$mutation)
mutation_freq <- sort(mutation_counts, decreasing = TRUE)

cat("Top 10 most frequent mutations:\n")
for (i in 1:min(10, length(mutation_freq))) {
  mut <- names(mutation_freq)[i]
  count <- mutation_freq[i]
  pct <- round((count / nrow(df)) * 100, 1)
  cat(sprintf("  %2d. %s: %d occurrences (%.1f%%)\n", i, mut, count, pct))
}

# Análisis específico de mutaciones G>T
gt_mutations <- df[grepl("G>T", df$mutation), ]
gt_count <- nrow(gt_mutations)
gt_pct <- round((gt_count / nrow(df)) * 100, 1)
cat("\n🧬 G>T mutations:", gt_count, "(", gt_pct, "% of all SNVs)\n")

# Top mutaciones G>T
gt_mutation_counts <- table(gt_mutations$mutation)
gt_mutation_freq <- sort(gt_mutation_counts, decreasing = TRUE)

cat("Top 10 G>T mutations:\n")
for (i in 1:min(10, length(gt_mutation_freq))) {
  mut <- names(gt_mutation_freq)[i]
  count <- gt_mutation_freq[i]
  pct <- round((count / gt_count) * 100, 1)
  cat(sprintf("  %2d. %s: %d occurrences (%.1f%% of G>T)\n", i, mut, count, pct))
}

cat("\n")

# =============================================================================
# 4. ANÁLISIS DE POSICIONES MÁS AFECTADAS
# =============================================================================

cat("📍 POSITION ANALYSIS\n")
cat(paste(rep("-", 50), collapse = ""), "\n")

# Top posiciones por frecuencia de mutación
position_counts <- table(df$position)
position_freq <- sort(position_counts, decreasing = TRUE)

cat("Top 15 most mutated positions:\n")
for (i in 1:min(15, length(position_freq))) {
  pos <- names(position_freq)[i]
  count <- position_freq[i]
  pct <- round((count / nrow(df)) * 100, 1)
  cat(sprintf("  %2d. Position %s: %d mutations (%.1f%%)\n", i, pos, count, pct))
}

# Análisis de región semilla (posiciones 2-8)
seed_positions <- c("2", "3", "4", "5", "6", "7", "8")
seed_mutations <- df[df$position %in% seed_positions, ]
seed_count <- nrow(seed_mutations)
seed_pct <- round((seed_count / nrow(df)) * 100, 1)

cat("\n🌱 Seed region mutations (positions 2-8):", seed_count, "(", seed_pct, "%)\n")

# Distribución por posición en región semilla
seed_pos_counts <- table(seed_mutations$position)
cat("Seed region position distribution:\n")
for (pos in seed_positions) {
  count <- seed_pos_counts[pos]
  if (is.na(count)) count <- 0
  pct <- round((count / seed_count) * 100, 1)
  cat(sprintf("  Position %s: %d mutations (%.1f%% of seed region)\n", pos, count, pct))
}

cat("\n")

# =============================================================================
# 5. ANÁLISIS DE miRNAs MÁS AFECTADOS
# =============================================================================

cat("🧬 miRNA ANALYSIS\n")
cat(paste(rep("-", 50), collapse = ""), "\n")

# Top miRNAs por número de SNVs
mirna_snv_counts <- table(df$`miRNA name`)
mirna_snv_freq <- sort(mirna_snv_counts, decreasing = TRUE)

cat("Top 15 miRNAs with most SNVs:\n")
for (i in 1:min(15, length(mirna_snv_freq))) {
  mirna <- names(mirna_snv_freq)[i]
  count <- mirna_snv_freq[i]
  pct <- round((count / nrow(df)) * 100, 1)
  cat(sprintf("  %2d. %s: %d SNVs (%.1f%%)\n", i, mirna, count, pct))
}

# Top miRNAs por número de mutaciones (no-PM)
non_pm_mirna_counts <- table(df$`miRNA name`[df$`pos:mut` != "PM"])
non_pm_mirna_freq <- sort(non_pm_mirna_counts, decreasing = TRUE)

cat("\nTop 15 miRNAs with most mutations (non-PM):\n")
for (i in 1:min(15, length(non_pm_mirna_freq))) {
  mirna <- names(non_pm_mirna_freq)[i]
  count <- non_pm_mirna_freq[i]
  pct <- round((count / non_pm_snvs) * 100, 1)
  cat(sprintf("  %2d. %s: %d mutations (%.1f%% of mutations)\n", i, mirna, count, pct))
}

cat("\n")

# =============================================================================
# 6. ANÁLISIS DE RPM (Reads Per Million)
# =============================================================================

cat("📊 RPM ANALYSIS (miRNAs más presentes)\n")
cat(paste(rep("-", 50), collapse = ""), "\n")

# Calcular RPM promedio por miRNA
rpm_data <- data.frame(
  miRNA = character(),
  total_reads = numeric(),
  avg_rpm = numeric(),
  stringsAsFactors = FALSE
)

for (i in 1:nrow(df)) {
  mirna <- df$`miRNA name`[i]
  total_reads <- sum(df[i, total_cols], na.rm = TRUE)
  avg_rpm <- total_reads / length(total_cols) * 1000000  # RPM calculation
  
  rpm_data <- rbind(rpm_data, data.frame(
    miRNA = mirna,
    total_reads = total_reads,
    avg_rpm = avg_rpm
  ))
}

# Agrupar por miRNA y calcular estadísticas
rpm_summary <- rpm_data %>%
  group_by(miRNA) %>%
  summarise(
    total_reads = sum(total_reads),
    avg_rpm = mean(avg_rpm),
    max_rpm = max(avg_rpm),
    snv_count = n(),
    .groups = "drop"
  ) %>%
  arrange(desc(avg_rpm))

cat("Top 15 miRNAs by average RPM (most abundant):\n")
for (i in 1:min(15, nrow(rpm_summary))) {
  mirna <- rpm_summary$miRNA[i]
  avg_rpm <- round(rpm_summary$avg_rpm[i], 1)
  total_reads <- rpm_summary$total_reads[i]
  snv_count <- rpm_summary$snv_count[i]
  cat(sprintf("  %2d. %s: %.1f RPM (%.0f total reads, %.0f SNVs)\n", 
              i, mirna, avg_rpm, total_reads, snv_count))
}

cat("\n")

# =============================================================================
# 7. ANÁLISIS DE VAF (Variant Allele Frequency)
# =============================================================================

cat("🔬 VAF ANALYSIS (miRNAs más mutados)\n")
cat(paste(rep("-", 50), collapse = ""), "\n")

# Calcular VAF promedio por miRNA
vaf_data <- data.frame(
  miRNA = character(),
  total_vaf = numeric(),
  avg_vaf = numeric(),
  max_vaf = numeric(),
  samples_with_mutation = numeric(),
  stringsAsFactors = FALSE
)

for (i in 1:nrow(df)) {
  mirna <- df$`miRNA name`[i]
  
  # Calcular VAFs para este SNV
  vafs <- numeric(length(snv_cols))
  for (j in seq_along(snv_cols)) {
    snv_count <- df[i, snv_cols[j]][[1]]
    total_count <- df[i, total_cols[j]][[1]]
    
    if (total_count > 0) {
      vafs[j] <- snv_count / total_count
    } else {
      vafs[j] <- 0
    }
  }
  
  total_vaf <- sum(vafs, na.rm = TRUE)
  avg_vaf <- mean(vafs, na.rm = TRUE)
  max_vaf <- max(vafs, na.rm = TRUE)
  samples_with_mutation <- sum(vafs > 0, na.rm = TRUE)
  
  vaf_data <- rbind(vaf_data, data.frame(
    miRNA = mirna,
    total_vaf = total_vaf,
    avg_vaf = avg_vaf,
    max_vaf = max_vaf,
    samples_with_mutation = samples_with_mutation
  ))
}

# Agrupar por miRNA y calcular estadísticas
vaf_summary <- vaf_data %>%
  group_by(miRNA) %>%
  summarise(
    total_vaf = sum(total_vaf),
    avg_vaf = mean(avg_vaf),
    max_vaf = max(max_vaf),
    total_samples_with_mutation = sum(samples_with_mutation),
    snv_count = n(),
    .groups = "drop"
  ) %>%
  arrange(desc(total_vaf))

cat("Top 15 miRNAs by total VAF (most mutated):\n")
for (i in 1:min(15, nrow(vaf_summary))) {
  mirna <- vaf_summary$miRNA[i]
  total_vaf <- round(vaf_summary$total_vaf[i], 1)
  avg_vaf <- round(vaf_summary$avg_vaf[i], 3)
  max_vaf <- round(vaf_summary$max_vaf[i], 3)
  samples <- vaf_summary$total_samples_with_mutation[i]
  snv_count <- vaf_summary$snv_count[i]
  cat(sprintf("  %2d. %s: %.1f total VAF (%.3f avg, %.3f max, %.0f samples, %.0f SNVs)\n", 
              i, mirna, total_vaf, avg_vaf, max_vaf, samples, snv_count))
}

cat("\n")

# =============================================================================
# 8. ANÁLISIS DE G>T MUTATIONS EN REGIÓN SEMILLA
# =============================================================================

cat("🌱 G>T MUTATIONS IN SEED REGION\n")
cat(paste(rep("-", 50), collapse = ""), "\n")

# Filtrar G>T mutations en región semilla
gt_seed <- df[grepl("G>T", df$mutation) & df$position %in% seed_positions, ]
gt_seed_count <- nrow(gt_seed)
gt_seed_pct <- round((gt_seed_count / nrow(df)) * 100, 1)

cat("G>T mutations in seed region:", gt_seed_count, "(", gt_seed_pct, "% of all SNVs)\n")

if (gt_seed_count > 0) {
  # Top miRNAs con G>T en región semilla
  gt_seed_mirna_counts <- table(gt_seed$`miRNA name`)
  gt_seed_mirna_freq <- sort(gt_seed_mirna_counts, decreasing = TRUE)
  
  cat("\nTop 10 miRNAs with G>T mutations in seed region:\n")
  for (i in 1:min(10, length(gt_seed_mirna_freq))) {
    mirna <- names(gt_seed_mirna_freq)[i]
    count <- gt_seed_mirna_freq[i]
    pct <- round((count / gt_seed_count) * 100, 1)
    cat(sprintf("  %2d. %s: %d G>T seed mutations (%.1f%%)\n", i, mirna, count, pct))
  }
  
  # Distribución por posición en región semilla para G>T
  gt_seed_pos_counts <- table(gt_seed$position)
  cat("\nG>T mutations by seed region position:\n")
  for (pos in seed_positions) {
    count <- gt_seed_pos_counts[pos]
    if (is.na(count)) count <- 0
    pct <- round((count / gt_seed_count) * 100, 1)
    cat(sprintf("  Position %s: %d G>T mutations (%.1f%%)\n", pos, count, pct))
  }
}

cat("\n")

# =============================================================================
# 9. CREAR GRÁFICAS DESCRIPTIVAS
# =============================================================================

cat("📊 CREATING DESCRIPTIVE PLOTS\n")
cat(paste(rep("-", 50), collapse = ""), "\n")

# Crear directorio para gráficas
if (!dir.exists("outputs/plots/initial_analysis")) {
  dir.create("outputs/plots/initial_analysis", recursive = TRUE)
}

# 1. Distribución de mutaciones
# Take only the available mutations (not more than exist)
n_mutations <- min(20, length(mutation_freq))
p1 <- ggplot(data.frame(mutation = names(mutation_freq)[1:n_mutations], 
                       count = as.numeric(mutation_freq)[1:n_mutations]), 
             aes(x = reorder(mutation, count), y = count)) +
  geom_bar(stat = "identity", fill = "steelblue", alpha = 0.7) +
  coord_flip() +
  labs(title = paste("Top", n_mutations, "Most Frequent Mutations"),
       x = "Mutation Type", y = "Count") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold"))

ggsave("outputs/plots/initial_analysis/mutation_distribution.png", p1, 
       width = 10, height = 8, dpi = 300)

# 2. Distribución de posiciones
# Take only the available positions (not more than exist)
n_positions <- min(20, length(position_freq))
p2 <- ggplot(data.frame(position = names(position_freq)[1:n_positions], 
                       count = as.numeric(position_freq)[1:n_positions]), 
             aes(x = reorder(position, count), y = count)) +
  geom_bar(stat = "identity", fill = "darkgreen", alpha = 0.7) +
  coord_flip() +
  labs(title = "Top 20 Most Mutated Positions",
       x = "Position", y = "Count") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold"))

ggsave("outputs/plots/initial_analysis/position_distribution.png", p2, 
       width = 10, height = 8, dpi = 300)

# 3. Top miRNAs por RPM
p3 <- ggplot(rpm_summary[1:15, ], aes(x = reorder(miRNA, avg_rpm), y = avg_rpm)) +
  geom_bar(stat = "identity", fill = "purple", alpha = 0.7) +
  coord_flip() +
  labs(title = "Top 15 miRNAs by Average RPM (Most Abundant)",
       x = "miRNA", y = "Average RPM") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
        axis.text.y = element_text(size = 8))

ggsave("outputs/plots/initial_analysis/top_mirnas_rpm.png", p3, 
       width = 12, height = 8, dpi = 300)

# 4. Top miRNAs por VAF total
p4 <- ggplot(vaf_summary[1:15, ], aes(x = reorder(miRNA, total_vaf), y = total_vaf)) +
  geom_bar(stat = "identity", fill = "red", alpha = 0.7) +
  coord_flip() +
  labs(title = "Top 15 miRNAs by Total VAF (Most Mutated)",
       x = "miRNA", y = "Total VAF") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
        axis.text.y = element_text(size = 8))

ggsave("outputs/plots/initial_analysis/top_mirnas_vaf.png", p4, 
       width = 12, height = 8, dpi = 300)

# 5. Distribución de G>T en región semilla
if (gt_seed_count > 0) {
  gt_seed_pos_df <- data.frame(
    position = names(gt_seed_pos_counts),
    count = as.numeric(gt_seed_pos_counts)
  )
  
  p5 <- ggplot(gt_seed_pos_df, aes(x = position, y = count)) +
    geom_bar(stat = "identity", fill = "orange", alpha = 0.7) +
    labs(title = "G>T Mutations by Seed Region Position",
         x = "Position", y = "Count") +
    theme_minimal() +
    theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold"))
  
  ggsave("outputs/plots/initial_analysis/gt_seed_region_distribution.png", p5, 
         width = 10, height = 6, dpi = 300)
}

cat("✅ Plots saved to outputs/plots/initial_analysis/\n")

# =============================================================================
# 10. GUARDAR RESULTADOS EN ARCHIVOS
# =============================================================================

cat("💾 SAVING RESULTS TO FILES\n")
cat(paste(rep("-", 50), collapse = ""), "\n")

# Crear directorio para resultados
if (!dir.exists("outputs/initial_analysis")) {
  dir.create("outputs/initial_analysis", recursive = TRUE)
}

# Guardar estadísticas descriptivas
write_csv(rpm_summary, "outputs/initial_analysis/mirna_rpm_summary.csv")
write_csv(vaf_summary, "outputs/initial_analysis/mirna_vaf_summary.csv")

# Guardar conteos de mutaciones
mutation_summary <- data.frame(
  mutation = names(mutation_freq),
  count = as.numeric(mutation_freq),
  percentage = round(as.numeric(mutation_freq) / nrow(df) * 100, 2)
)
write_csv(mutation_summary, "outputs/initial_analysis/mutation_frequency_summary.csv")

# Guardar conteos de posiciones
position_summary <- data.frame(
  position = names(position_freq),
  count = as.numeric(position_freq),
  percentage = round(as.numeric(position_freq) / nrow(df) * 100, 2)
)
write_csv(position_summary, "outputs/initial_analysis/position_frequency_summary.csv")

# Guardar conteos de miRNAs
mirna_summary <- data.frame(
  mirna = names(mirna_snv_freq),
  snv_count = as.numeric(mirna_snv_freq),
  percentage = round(as.numeric(mirna_snv_freq) / nrow(df) * 100, 2)
)
write_csv(mirna_summary, "outputs/initial_analysis/mirna_snv_summary.csv")

cat("✅ Results saved to outputs/initial_analysis/\n")

# =============================================================================
# 11. RESUMEN FINAL
# =============================================================================

cat("\n🎯 COMPREHENSIVE INITIAL ANALYSIS COMPLETE\n")
cat(paste(rep("=", 80), collapse = ""), "\n")

cat("📊 DATASET OVERVIEW:\n")
cat("   • Total SNVs:", nrow(df), "\n")
cat("   • Total samples:", length(snv_cols), "\n")
cat("   • Unique miRNAs:", unique_mirnas, "\n")
cat("   • Unique positions:", unique_positions, "\n")
cat("   • Unique mutations:", unique_mutations, "\n")
cat("   • Perfect Match SNVs:", pm_snvs, "\n")
cat("   • Mutated SNVs:", non_pm_snvs, "\n")
cat("   • Mutation rate:", round((non_pm_snvs / nrow(df)) * 100, 1), "%\n")

cat("\n🔥 KEY FINDINGS:\n")
cat("   • Most frequent mutation:", names(mutation_freq)[1], "(", mutation_freq[1], "occurrences)\n")
cat("   • Most mutated position:", names(position_freq)[1], "(", position_freq[1], "mutations)\n")
cat("   • Most abundant miRNA:", rpm_summary$miRNA[1], "(", round(rpm_summary$avg_rpm[1], 1), "RPM)\n")
cat("   • Most mutated miRNA:", vaf_summary$miRNA[1], "(", round(vaf_summary$total_vaf[1], 1), "total VAF)\n")
cat("   • G>T mutations:", gt_count, "(", gt_pct, "% of all SNVs)\n")
cat("   • G>T in seed region:", gt_seed_count, "(", gt_seed_pct, "% of all SNVs)\n")

cat("\n📁 OUTPUT FILES:\n")
cat("   • Plots: outputs/plots/initial_analysis/\n")
cat("   • Data: outputs/initial_analysis/\n")
cat("   • Summary tables: CSV files with detailed statistics\n")

cat("\n✅ Analysis complete! Ready for next phase.\n")
