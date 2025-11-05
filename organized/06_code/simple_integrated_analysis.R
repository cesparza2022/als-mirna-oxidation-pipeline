# Análisis integrado simple de VAF y RPM con datos procesados
# Usar el dataset procesado para análisis de VAF y RPM

library(dplyr)
library(stringr)
library(tidyr)
library(readr)
library(ggplot2)
library(pheatmap)
library(RColorBrewer)

cat("🚀 ANÁLISIS INTEGRADO SIMPLE VAF Y RPM\n")
cat(paste(rep("=", 50), collapse=""), "\n")

# Load the processed dataset
cat("📁 Cargando dataset procesado...\n")
df_processed <- read_tsv("outputs/processed_mirna_dataset.tsv")

cat("   📊 Dataset procesado:", nrow(df_processed), "x", ncol(df_processed), "\n")

# Define column ranges
snv_cols <- colnames(df_processed)[2:416]
total_cols <- colnames(df_processed)[417:831]

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
  filter(str_detect(df_processed[["pos.mut"]], "GT")) %>%
  mutate(position = as.numeric(str_extract(df_processed[["pos.mut"]], "^\\d+"))) %>%
  filter(position >= 2 & position <= 8)

cat("   📊 Mutaciones G>T en región semilla:", nrow(seed_gt_mutations), "\n")
cat("   📊 miRNAs con mutaciones G>T en semilla:", length(unique(seed_gt_mutations$miRNA.name)), "\n")

# Calculate VAF for each mutation
cat("\n🔧 Calculando VAF por mutación...\n")
vaf_data <- seed_gt_mutations %>%
  rowwise() %>%
  mutate(
    # Calculate VAF for each sample
    vaf_values = list(
      sapply(1:length(snv_cols), function(i) {
        snv_count <- .data[[snv_cols[i]]]
        total_count <- .data[[total_cols[i]]]
        if (total_count > 0) snv_count / total_count else 0
      })
    ),
    mean_vaf = mean(unlist(vaf_values), na.rm = TRUE),
    max_vaf = max(unlist(vaf_values), na.rm = TRUE)
  ) %>%
  ungroup()

# Filter out high VAF mutations (>50%)
cat("\n🔧 Filtrando mutaciones con VAF > 50%...\n")
vaf_filtered <- vaf_data %>%
  filter(max_vaf <= 0.5)

cat("   📊 Mutaciones después de filtrar VAF > 50%:", nrow(vaf_filtered), "\n")
cat("   📊 Mutaciones removidas:", nrow(vaf_data) - nrow(vaf_filtered), "\n")

# Select top miRNAs by G>T counts in seed region
cat("\n🔧 Seleccionando top miRNAs por cuentas G>T en región semilla...\n")
top_mirnas <- vaf_filtered %>%
  group_by(miRNA.name) %>%
  summarise(
    total_gt_counts = sum(across(all_of(snv_cols), ~ sum(.x, na.rm = TRUE))),
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
  
  # Create VAF matrix for heatmap
  vaf_heatmap_data <- top_snvs %>%
    select(miRNA.name, pos.mut, all_of(snv_cols)) %>%
    rowwise() %>%
    mutate(
      vaf_row = list(
        sapply(1:length(snv_cols), function(i) {
          snv_count <- .data[[snv_cols[i]]]
          total_count <- .data[[total_cols[i]]]
          if (total_count > 0) snv_count / total_count else 0
        })
      )
    ) %>%
    ungroup() %>%
    select(miRNA.name, pos.mut, vaf_row) %>%
    unnest(vaf_row) %>%
    pivot_wider(
      names_from = c(miRNA.name, pos.mut),
      values_from = vaf_row,
      values_fill = 0
    ) %>%
    as.data.frame()
  
  rownames(vaf_heatmap_data) <- snv_cols
  
  # Create sample annotation (ALS vs Control)
  cat("\n🔧 Creando anotación de muestras...\n")
  sample_annotation <- data.frame(
    sample = snv_cols,
    group = ifelse(str_detect(snv_cols, "Control"), "Control", "ALS"),
    stringsAsFactors = FALSE
  )
  
  # Create heatmap
  cat("\n🎨 Creando heatmap...\n")
  png("outputs/figures/simple_integrated_vaf_heatmap.png", width = 1200, height = 800)
  pheatmap(
    vaf_heatmap_data,
    cluster_rows = TRUE,
    cluster_cols = TRUE,
    clustering_method = "ward.D2",
    color = colorRampPalette(c("white", "red"))(100),
    annotation_row = sample_annotation,
    show_rownames = FALSE,
    show_colnames = FALSE,
    main = "VAF Heatmap - G>T Mutations in Seed Region"
  )
  dev.off()
  
  cat("   ✅ Heatmap guardado: outputs/figures/simple_integrated_vaf_heatmap.png\n")
}

# Create summary plots
cat("\n🎨 Creando gráficos de resumen...\n")

# VAF distribution
png("outputs/figures/simple_integrated_vaf_distribution.png", width = 800, height = 600)
ggplot(vaf_filtered, aes(x = mean_vaf)) +
  geom_histogram(bins = 50, fill = "lightcoral", alpha = 0.7) +
  labs(
    title = "Distribution of Mean VAF per Mutation",
    x = "Mean VAF",
    y = "Count"
  ) +
  theme_minimal()
dev.off()

# Top miRNAs by G>T counts
png("outputs/figures/simple_integrated_top_mirnas.png", width = 1000, height = 600)
ggplot(top_mirnas[1:20, ], aes(x = reorder(miRNA.name, total_gt_counts), y = total_gt_counts)) +
  geom_col(fill = "steelblue", alpha = 0.7) +
  coord_flip() +
  labs(
    title = "Top 20 miRNAs by G>T Counts in Seed Region",
    x = "miRNA",
    y = "Total G>T Counts"
  ) +
  theme_minimal()
dev.off()

# Save results
cat("\n💾 Guardando resultados...\n")
write_tsv(top_mirnas, "outputs/simple_integrated_top_mirnas.tsv")
write_tsv(vaf_filtered, "outputs/simple_integrated_vaf_data.tsv")
write_tsv(sample_annotation, "outputs/simple_integrated_sample_annotation.tsv")

# Create summary report
cat("\n📋 Creando reporte de resumen...\n")
report <- paste0(
  "# ANÁLISIS INTEGRADO SIMPLE VAF Y RPM - REPORTE\n\n",
  "## Resumen del Procesamiento\n",
  "- **Dataset procesado**: ", nrow(df_processed), " miRNAs\n",
  "- **Mutaciones G>T en región semilla**: ", nrow(seed_gt_mutations), "\n",
  "- **Después de filtrar VAF > 50%**: ", nrow(vaf_filtered), "\n",
  "- **Top miRNAs seleccionados**: ", nrow(top_mirnas), "\n\n",
  "## Top 10 miRNAs por Cuentas G>T\n",
  paste0(1:nrow(top_mirnas[1:10, ]), ". ", top_mirnas$miRNA.name[1:10], 
         " (", top_mirnas$total_gt_counts[1:10], " cuentas)\n", collapse = ""),
  "\n## Archivos Generados\n",
  "- `outputs/simple_integrated_top_mirnas.tsv`: Top miRNAs\n",
  "- `outputs/simple_integrated_vaf_data.tsv`: Datos VAF\n",
  "- `outputs/simple_integrated_sample_annotation.tsv`: Anotación de muestras\n",
  "- `outputs/figures/simple_integrated_*`: Gráficos y heatmap\n"
)

writeLines(report, "outputs/simple_integrated_analysis_report.md")

cat("\n🎉 Análisis integrado simple completado!\n")
cat("   📊 Archivos generados:\n")
cat("   - outputs/simple_integrated_top_mirnas.tsv\n")
cat("   - outputs/simple_integrated_vaf_data.tsv\n")
cat("   - outputs/simple_integrated_sample_annotation.tsv\n")
cat("   - outputs/simple_integrated_analysis_report.md\n")
cat("   - outputs/figures/simple_integrated_*\n")
