library(dplyr)
library(stringr)
library(tidyr)
library(readr)
library(pheatmap)
library(RColorBrewer)
library(ggplot2)
library(gridExtra)

cat("🔍 ANÁLISIS DE LISTA ESPECÍFICA DE miRNAs\n")
cat(paste(rep("=", 50), collapse=""), "\n")

# Lista específica de miRNAs proporcionada
specific_mirnas <- c(
  "hsa-miR-432-5p", "hsa-miR-486-5p", "hsa-miR-584-5p", "hsa-miR-93-5p", 
  "hsa-miR-206", "hsa-miR-191-5p", "hsa-miR-122-5p", "hsa-miR-16-5p", 
  "hsa-miR-151a-3p", "hsa-miR-152-3p", "hsa-miR-134-5p", "hsa-miR-1-3p", 
  "hsa-miR-126-3p", "hsa-miR-195-5p", "hsa-miR-92a-3p", "hsa-miR-339-5p", 
  "hsa-miR-30d-5p", "hsa-let-7b-5p", "hsa-miR-3168", "hsa-miR-6134", 
  "hsa-miR-17-5p", "hsa-miR-1307-3p", "hsa-miR-6129", "hsa-let-7a-5p", 
  "hsa-let-7i-5p", "hsa-miR-26a-5p", "hsa-let-7f-5p", "hsa-miR-4317", 
  "hsa-miR-146a-5p", "hsa-miR-26b-5p", "hsa-miR-326", "hsa-miR-423-5p", 
  "hsa-miR-103a-3p", "hsa-miR-24-3p", "hsa-miR-1297", "hsa-miR-21-5p", 
  "hsa-miR-382-5p", "hsa-miR-483-5p", "hsa-miR-423-3p", "hsa-miR-20a-5p", 
  "hsa-miR-30a-5p", "hsa-miR-25-3p", "hsa-miR-126-5p", "hsa-miR-196a-5p", 
  "hsa-miR-328-3p", "hsa-miR-6130", "hsa-miR-30e-5p", "hsa-miR-4279", 
  "hsa-miR-223-3p", "hsa-miR-146b-5p", "hsa-miR-22-3p", "hsa-miR-143-3p", 
  "hsa-miR-99b-5p", "hsa-miR-125b-5p", "hsa-miR-221-3p", "hsa-miR-23a-3p", 
  "hsa-miR-6131", "hsa-miR-484", "hsa-miR-196b-5p", "hsa-miR-339-3p", 
  "hsa-miR-15a-5p", "hsa-miR-140-3p", "hsa-let-7c-5p", "hsa-miR-493-3p", 
  "hsa-miR-10a-5p", "hsa-miR-320a-3p", "hsa-miR-27b-3p", "hsa-let-7d-5p", 
  "hsa-miR-101-3p", "hsa-miR-503-5p", "hsa-miR-324-5p", "hsa-miR-744-5p", 
  "hsa-miR-451a", "hsa-miR-30e-3p", "hsa-miR-148a-3p", "hsa-miR-150-5p", 
  "hsa-miR-370-3p", "hsa-miR-190b-5p", "hsa-miR-6852-5p"
)

cat("📋 Lista de miRNAs específicos:", length(specific_mirnas), "\n")

# Load the processed dataset
cat("\n📁 Cargando dataset procesado...\n")
df_processed <- read_tsv("outputs/processed_mirna_dataset_simple.tsv")

cat("   📊 Dataset procesado:", nrow(df_processed), "x", ncol(df_processed), "\n")

# Define column ranges
snv_cols <- colnames(df_processed)[3:417]
total_cols <- colnames(df_processed)[418:832]

cat("   📊 Columnas SNV:", length(snv_cols), "\n")
cat("   📊 Columnas TOTAL:", length(total_cols), "\n")

# Check which miRNAs from the list are present in the dataset
cat("\n🔍 Verificando miRNAs en el dataset...\n")
available_mirnas <- df_processed %>%
  filter(miRNA.name %in% specific_mirnas) %>%
  distinct(miRNA.name) %>%
  pull(miRNA.name)

missing_mirnas <- setdiff(specific_mirnas, available_mirnas)

cat("   📊 miRNAs encontrados:", length(available_mirnas), "\n")
cat("   📊 miRNAs no encontrados:", length(missing_mirnas), "\n")

if (length(missing_mirnas) > 0) {
  cat("   📋 miRNAs no encontrados:\n")
  print(missing_mirnas)
}

# Calculate library size for each sample
cat("\n🔧 Calculando library size por muestra...\n")
library_sizes <- df_processed %>%
  select(all_of(total_cols)) %>%
  summarise(across(everything(), ~ sum(.x, na.rm = TRUE))) %>%
  unlist()

# Filter for specific miRNAs with G>T mutations in seed region (positions 2-8)
cat("\n🔧 Filtrando miRNAs específicos con mutaciones G>T en región semilla...\n")
specific_seed_gt <- df_processed %>%
  filter(miRNA.name %in% available_mirnas) %>%
  filter(str_detect(pos.mut, "GT")) %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^\\d+"))) %>%
  filter(position >= 2 & position <= 8)

cat("   📊 Mutaciones G>T en región semilla para miRNAs específicos:", nrow(specific_seed_gt), "\n")
cat("   📊 miRNAs específicos con mutaciones G>T en semilla:", length(unique(specific_seed_gt$miRNA.name)), "\n")

# Calculate VAF for each mutation
cat("\n🔧 Calculando VAF por mutación...\n")
vaf_data <- specific_seed_gt

# Calculate VAF matrix using base R
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

# Add VAF statistics
vaf_data$mean_vaf <- rowMeans(vaf_matrix, na.rm = TRUE)
vaf_data$max_vaf <- apply(vaf_matrix, 1, max, na.rm = TRUE)

# Filter out high VAF mutations (>50%)
cat("\n🔧 Filtrando mutaciones con VAF > 50%...\n")
vaf_filtered <- vaf_data %>%
  filter(max_vaf <= 0.5)

cat("   📊 Mutaciones después de filtrar VAF > 50%:", nrow(vaf_data) - nrow(vaf_filtered), "removidas\n")
cat("   📊 Mutaciones restantes:", nrow(vaf_filtered), "\n")

# Calculate RPM for each miRNA
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

vaf_filtered$mean_rpm <- rowMeans(rpm_matrix, na.rm = TRUE)

# Filter for RPM mean > 1
cat("\n🔧 Filtrando por RPM promedio > 1...\n")
rpm_filtered <- vaf_filtered %>%
  filter(mean_rpm > 1)

cat("   📊 Mutaciones después de filtrar por RPM promedio > 1:", nrow(rpm_filtered), "\n")
cat("   📊 miRNAs después de filtrar por RPM promedio > 1:", length(unique(rpm_filtered$miRNA.name)), "\n")

# Analyze the specific miRNAs
cat("\n🔧 Analizando miRNAs específicos...\n")

# Summary by miRNA
mirna_summary <- rpm_filtered %>%
  group_by(miRNA.name) %>%
  summarise(
    total_gt_counts = sum(across(all_of(snv_cols), ~ sum(.x, na.rm = TRUE))),
    mean_rpm = mean(mean_rpm, na.rm = TRUE),
    mean_vaf = mean(mean_vaf, na.rm = TRUE),
    max_vaf = max(max_vaf, na.rm = TRUE),
    mutation_count = n(),
    positions = paste(sort(unique(position)), collapse = ","),
    .groups = "drop"
  ) %>%
  arrange(desc(total_gt_counts))

cat("\n📊 Top 10 miRNAs específicos por cuentas G>T:\n")
print(head(mirna_summary, 10))

# Create VAF matrix for heatmap
cat("\n🔧 Creando matriz VAF para heatmap...\n")
vaf_heatmap_data <- matrix(0, nrow = length(snv_cols), ncol = nrow(rpm_filtered))
colnames(vaf_heatmap_data) <- paste0(rpm_filtered$miRNA.name, "_", rpm_filtered$pos.mut)
rownames(vaf_heatmap_data) <- snv_cols

for (i in 1:nrow(rpm_filtered)) {
  for (j in 1:length(snv_cols)) {
    snv_count <- as.numeric(rpm_filtered[i, snv_cols[j]])
    total_count <- as.numeric(rpm_filtered[i, total_cols[j]])
    if (total_count > 0) {
      vaf_heatmap_data[j, i] <- snv_count / total_count
    }
  }
}

# Create sample annotation
cat("\n🔧 Creando anotación de muestras...\n")
sample_annotation <- data.frame(
  group = ifelse(str_detect(snv_cols, "Control"), "Control", "ALS"),
  stringsAsFactors = FALSE
)
rownames(sample_annotation) <- snv_cols

# Create color mapping for groups
group_colors <- c("ALS" = "#E31A1C", "Control" = "#1F78B4")
annotation_colors <- list(group = group_colors)

# Create heatmap
cat("\n🎨 Creando heatmap para miRNAs específicos...\n")
png("outputs/figures/specific_mirnas_vaf_heatmap.png", width = 1400, height = 900)
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
  main = "VAF Heatmap - Specific miRNAs G>T Mutations in Seed Region",
  fontsize = 12,
  border_color = NA
)
dev.off()

# Generate summary plots
cat("\n🎨 Creando gráficos de resumen...\n")

# Plot 1: Distribution of total G>T counts per miRNA
p1 <- ggplot(mirna_summary, aes(x = reorder(miRNA.name, -total_gt_counts), y = total_gt_counts)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  theme_minimal() +
  labs(title = "Specific miRNAs by Total G>T Counts in Seed Region", 
       x = "miRNA Name", y = "Total G>T Counts") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 8))

# Plot 2: Distribution of mean VAF for specific miRNAs
p2 <- ggplot(mirna_summary, aes(x = reorder(miRNA.name, -mean_vaf), y = mean_vaf)) +
  geom_bar(stat = "identity", fill = "darkred") +
  theme_minimal() +
  labs(title = "Specific miRNAs by Mean VAF in Seed Region", 
       x = "miRNA Name", y = "Mean VAF") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 8))

# Plot 3: Distribution of mean RPM for specific miRNAs
p3 <- ggplot(mirna_summary, aes(x = reorder(miRNA.name, -mean_rpm), y = mean_rpm)) +
  geom_bar(stat = "identity", fill = "darkgreen") +
  theme_minimal() +
  labs(title = "Specific miRNAs by Mean RPM", 
       x = "miRNA Name", y = "Mean RPM") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 8))

# Plot 4: Scatter plot of Mean VAF vs Mean RPM
p4 <- ggplot(mirna_summary, aes(x = mean_rpm, y = mean_vaf, color = total_gt_counts)) +
  geom_point(alpha = 0.7, size = 3) +
  scale_color_viridis_c(option = "C") +
  theme_minimal() +
  labs(title = "Mean VAF vs Mean RPM for Specific miRNAs", 
       x = "Mean RPM", y = "Mean VAF", color = "Total G>T Counts") +
  geom_text(aes(label = miRNA.name), vjust = -0.5, hjust = 0.5, size = 3, check_overlap = TRUE)

# Save plots
ggsave("outputs/figures/specific_mirnas_gt_counts.png", p1, width = 14, height = 8)
ggsave("outputs/figures/specific_mirnas_mean_vaf.png", p2, width = 14, height = 8)
ggsave("outputs/figures/specific_mirnas_mean_rpm.png", p3, width = 14, height = 8)
ggsave("outputs/figures/specific_mirnas_vaf_vs_rpm.png", p4, width = 12, height = 8)

# Save results
cat("\n💾 Guardando resultados...\n")
write_tsv(mirna_summary, "outputs/specific_mirnas_summary.tsv")
write_tsv(rpm_filtered, "outputs/specific_mirnas_vaf_data.tsv")
write_tsv(sample_annotation, "outputs/specific_mirnas_sample_annotation.tsv")

# Create comprehensive report
cat("\n📋 Creando reporte de miRNAs específicos...\n")

report_content <- paste0(
"# ANÁLISIS DE LISTA ESPECÍFICA DE miRNAs

## Resumen del Análisis
- **miRNAs en lista**: ", length(specific_mirnas), "
- **miRNAs encontrados en dataset**: ", length(available_mirnas), "
- **miRNAs no encontrados**: ", length(missing_mirnas), "
- **Mutaciones G>T en región semilla**: ", nrow(specific_seed_gt), "
- **Después de filtrar VAF > 50%**: ", nrow(vaf_filtered), "
- **Después de filtrar RPM promedio > 1**: ", nrow(rpm_filtered), "
- **miRNAs finales con datos**: ", length(unique(rpm_filtered$miRNA.name)), "

## Top 10 miRNAs por Cuentas G>T
", paste(
  sapply(1:min(10, nrow(mirna_summary)), function(i) {
    mirna <- mirna_summary[i, ]
    paste0(i, ". ", mirna$miRNA.name, " (", mirna$total_gt_counts, " cuentas, RPM ", 
           round(mirna$mean_rpm, 2), ", VAF ", formatC(mirna$mean_vaf, format = "e", digits = 2), 
           ", posiciones: ", mirna$positions, ")\n")
  }),
  collapse = ""
),
"
## miRNAs No Encontrados
", if(length(missing_mirnas) > 0) paste(missing_mirnas, collapse = ", ") else "Ninguno",
"

## Archivos Generados
- `outputs/specific_mirnas_summary.tsv`: Resumen de miRNAs específicos
- `outputs/specific_mirnas_vaf_data.tsv`: Datos VAF de miRNAs específicos
- `outputs/specific_mirnas_sample_annotation.tsv`: Anotación de muestras
- `outputs/figures/specific_mirnas_*`: Gráficos y heatmap
- `outputs/specific_mirnas_analysis_report.md`: Este reporte
"
)

writeLines(report_content, "outputs/specific_mirnas_analysis_report.md")

cat("\n🎉 Análisis de miRNAs específicos completado!\n")
cat("   📊 Archivos generados:\n")
cat("   - outputs/specific_mirnas_summary.tsv\n")
cat("   - outputs/specific_mirnas_vaf_data.tsv\n")
cat("   - outputs/specific_mirnas_sample_annotation.tsv\n")
cat("   - outputs/specific_mirnas_analysis_report.md\n")
cat("   - outputs/figures/specific_mirnas_*\n")

