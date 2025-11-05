# Análisis final simple con datos procesados correctamente
# Usar el dataset procesado que preserva pos.mut

library(dplyr)
library(stringr)
library(tidyr)
library(readr)
library(ggplot2)
library(pheatmap)
library(RColorBrewer)

cat("🚀 ANÁLISIS FINAL SIMPLE VAF Y RPM\n")
cat(paste(rep("=", 50), collapse=""), "\n")

# Load the processed dataset
cat("📁 Cargando dataset procesado...\n")
df_processed <- read_tsv("outputs/processed_mirna_dataset_simple.tsv")

cat("   📊 Dataset procesado:", nrow(df_processed), "x", ncol(df_processed), "\n")

# Define column ranges
snv_cols <- colnames(df_processed)[3:417]
total_cols <- colnames(df_processed)[418:832]

cat("   📊 Columnas SNV:", length(snv_cols), "\n")
cat("   📊 Columnas TOTAL:", length(total_cols), "\n")

# Calculate library size for each sample
cat("\n🔧 Calculando library size por muestra...\n")
library_sizes <- df_processed %>%
  summarise(across(all_of(total_cols), ~ sum(.x, na.rm = TRUE))) %>%
  unlist()

cat("   📊 Library sizes calculados para", length(library_sizes), "muestras\n")
cat("   📊 Rango de library size:", min(library_sizes), "-", max(library_sizes), "\n")

# Filter for G>T mutations in seed region (positions 2-8)
cat("\n🔧 Filtrando mutaciones G>T en región semilla...\n")
seed_gt_mutations <- df_processed %>%
  filter(str_detect(pos.mut, "GT")) %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^\\d+"))) %>%
  filter(position >= 2 & position <= 8)

cat("   📊 Mutaciones G>T en región semilla:", nrow(seed_gt_mutations), "\n")
cat("   📊 miRNAs con mutaciones G>T en semilla:", length(unique(seed_gt_mutations$miRNA.name)), "\n")

# Calculate VAF for each mutation using base R approach
cat("\n🔧 Calculando VAF por mutación...\n")
vaf_data <- seed_gt_mutations

# Calculate VAF for each sample using base R
vaf_matrix <- matrix(0, nrow = nrow(vaf_data), ncol = length(snv_cols))
for (i in 1:nrow(vaf_data)) {
  for (j in 1:length(snv_cols)) {
    snv_count <- as.numeric(vaf_data[i, snv_cols[j]])
    total_count <- as.numeric(vaf_data[i, total_cols[j]])
    if (total_count > 0) {
      vaf_matrix[i, j] <- snv_count / total_count
    }
  }
}

# Add VAF statistics to the data
vaf_data$mean_vaf <- rowMeans(vaf_matrix, na.rm = TRUE)
vaf_data$max_vaf <- apply(vaf_matrix, 1, max, na.rm = TRUE)

# Filter out high VAF mutations (>50%)
cat("\n🔧 Filtrando mutaciones con VAF > 50%...\n")
vaf_filtered <- vaf_data %>%
  filter(max_vaf <= 0.5)

cat("   📊 Mutaciones después de filtrar VAF > 50%:", nrow(vaf_filtered), "\n")
cat("   📊 Mutaciones removidas:", nrow(vaf_data) - nrow(vaf_filtered), "\n")

# Calculate RPM for each miRNA using base R approach
cat("\n🔧 Calculando RPM por miRNA...\n")
rpm_matrix <- matrix(0, nrow = nrow(vaf_filtered), ncol = length(total_cols))
for (i in 1:nrow(vaf_filtered)) {
  for (j in 1:length(total_cols)) {
    total_count <- as.numeric(vaf_filtered[i, total_cols[j]])
    lib_size <- library_sizes[total_cols[j]]
    if (lib_size > 0) {
      rpm_matrix[i, j] <- (total_count / lib_size) * 1e6
    }
  }
}

# Add RPM statistics to the data
vaf_filtered$mean_rpm <- rowMeans(rpm_matrix, na.rm = TRUE)

# Select top miRNAs by G>T counts in seed region
cat("\n🔧 Seleccionando top miRNAs por cuentas G>T en región semilla...\n")
top_mirnas <- vaf_filtered %>%
  group_by(miRNA.name) %>%
  summarise(
    total_gt_counts = sum(across(all_of(snv_cols), ~ sum(.x, na.rm = TRUE))),
    mean_rpm = mean(mean_rpm, na.rm = TRUE),
    mean_vaf = mean(mean_vaf, na.rm = TRUE),
    mutation_count = n(),
    .groups = "drop"
  ) %>%
  arrange(desc(total_gt_counts)) %>%
  head(50)  # Top 50 miRNAs

cat("   📊 Top miRNAs seleccionados:", nrow(top_mirnas), "\n")

# Create VAF matrix for heatmap
cat("\n🔧 Creando matriz VAF para heatmap...\n")
if (nrow(vaf_filtered) > 0) {
  # Select top SNVs by mean VAF
  top_snvs <- vaf_filtered %>%
    filter(miRNA.name %in% top_mirnas$miRNA.name) %>%
    arrange(desc(mean_vaf)) %>%
    head(100)  # Top 100 SNVs
  
  # Create VAF matrix for heatmap using base R
  vaf_heatmap_data <- matrix(0, nrow = length(snv_cols), ncol = nrow(top_snvs))
  colnames(vaf_heatmap_data) <- paste0(top_snvs$miRNA.name, "_", top_snvs$pos.mut)
  rownames(vaf_heatmap_data) <- snv_cols
  
  for (i in 1:nrow(top_snvs)) {
    for (j in 1:length(snv_cols)) {
      snv_count <- as.numeric(top_snvs[i, snv_cols[j]])
      total_count <- as.numeric(top_snvs[i, total_cols[j]])
      if (total_count > 0) {
        vaf_heatmap_data[j, i] <- snv_count / total_count
      }
    }
  }
  
  # Create sample annotation (ALS vs Control)
  cat("\n🔧 Creando anotación de muestras...\n")
  sample_annotation <- data.frame(
    group = ifelse(str_detect(snv_cols, "Control"), "Control", "ALS"),
    stringsAsFactors = FALSE
  )
  rownames(sample_annotation) <- snv_cols
  
  # Create color mapping for groups
  group_colors <- c("ALS" = "#E31A1C", "Control" = "#1F78B4")
  
  # Create annotation colors
  annotation_colors <- list(
    group = group_colors
  )
  
  # Create heatmap
  cat("\n🎨 Creando heatmap...\n")
  png("outputs/figures/simple_final_vaf_heatmap.png", width = 1200, height = 800)
  pheatmap(
    vaf_heatmap_data,
    cluster_rows = TRUE,
    cluster_cols = TRUE,
    clustering_method = "ward.D2",
    color = colorRampPalette(c("white", "red"))(100),
    annotation_row = sample_annotation,
    annotation_colors = annotation_colors,
    show_rownames = FALSE,
    show_colnames = FALSE,
    main = "VAF Heatmap - G>T Mutations in Seed Region (Simple Final Analysis)"
  )
  dev.off()
  
  cat("   ✅ Heatmap guardado: outputs/figures/simple_final_vaf_heatmap.png\n")
}

# Create summary plots
cat("\n🎨 Creando gráficos de resumen...\n")

# VAF distribution
png("outputs/figures/simple_final_vaf_distribution.png", width = 800, height = 600)
ggplot(vaf_filtered, aes(x = mean_vaf)) +
  geom_histogram(bins = 50, fill = "lightcoral", alpha = 0.7) +
  labs(
    title = "Distribution of Mean VAF per Mutation (Simple Final Analysis)",
    x = "Mean VAF",
    y = "Count"
  ) +
  theme_minimal()
dev.off()

# RPM distribution
png("outputs/figures/simple_final_rpm_distribution.png", width = 800, height = 600)
ggplot(vaf_filtered, aes(x = mean_rpm)) +
  geom_histogram(bins = 50, fill = "skyblue", alpha = 0.7) +
  scale_x_log10() +
  labs(
    title = "Distribution of Mean RPM per miRNA (Simple Final Analysis)",
    x = "Mean RPM (log10)",
    y = "Count"
  ) +
  theme_minimal()
dev.off()

# Top miRNAs by G>T counts
png("outputs/figures/simple_final_top_mirnas.png", width = 1000, height = 600)
ggplot(top_mirnas[1:20, ], aes(x = reorder(miRNA.name, total_gt_counts), y = total_gt_counts)) +
  geom_col(fill = "steelblue", alpha = 0.7) +
  coord_flip() +
  labs(
    title = "Top 20 miRNAs by G>T Counts in Seed Region (Simple Final Analysis)",
    x = "miRNA",
    y = "Total G>T Counts"
  ) +
  theme_minimal()
dev.off()

# Position distribution of G>T mutations
png("outputs/figures/simple_final_position_distribution.png", width = 800, height = 600)
ggplot(seed_gt_mutations, aes(x = position)) +
  geom_histogram(bins = 7, fill = "darkgreen", alpha = 0.7) +
  labs(
    title = "Distribution of G>T Mutations by Position in Seed Region",
    x = "Position (2-8)",
    y = "Count"
  ) +
  theme_minimal()
dev.off()

# Save results
cat("\n💾 Guardando resultados...\n")
write_tsv(top_mirnas, "outputs/simple_final_top_mirnas.tsv")
write_tsv(vaf_filtered, "outputs/simple_final_vaf_data.tsv")
write_tsv(sample_annotation, "outputs/simple_final_sample_annotation.tsv")

# Create summary report
cat("\n📋 Creando reporte de resumen...\n")
report <- paste0(
  "# ANÁLISIS FINAL SIMPLE VAF Y RPM - REPORTE\n\n",
  "## Resumen del Procesamiento\n",
  "- **Dataset procesado**: ", nrow(df_processed), " miRNAs\n",
  "- **Mutaciones G>T en región semilla**: ", nrow(seed_gt_mutations), "\n",
  "- **Después de filtrar VAF > 50%**: ", nrow(vaf_filtered), "\n",
  "- **Top miRNAs seleccionados**: ", nrow(top_mirnas), "\n\n",
  "## Top 10 miRNAs por Cuentas G>T\n",
  paste0(1:nrow(top_mirnas[1:10, ]), ". ", top_mirnas$miRNA.name[1:10], 
         " (", top_mirnas$total_gt_counts[1:10], " cuentas)\n", collapse = ""),
  "\n## Archivos Generados\n",
  "- `outputs/simple_final_top_mirnas.tsv`: Top miRNAs\n",
  "- `outputs/simple_final_vaf_data.tsv`: Datos VAF\n",
  "- `outputs/simple_final_sample_annotation.tsv`: Anotación de muestras\n",
  "- `outputs/figures/simple_final_*`: Gráficos y heatmap\n"
)

writeLines(report, "outputs/simple_final_analysis_report.md")

cat("\n🎉 Análisis final simple completado!\n")
cat("   📊 Archivos generados:\n")
cat("   - outputs/simple_final_top_mirnas.tsv\n")
cat("   - outputs/simple_final_vaf_data.tsv\n")
cat("   - outputs/simple_final_sample_annotation.tsv\n")
cat("   - outputs/simple_final_analysis_report.md\n")
cat("   - outputs/figures/simple_final_*\n")
