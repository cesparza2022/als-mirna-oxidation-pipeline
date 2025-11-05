library(dplyr)
library(stringr)
library(tidyr)
library(readr)
library(pheatmap)
library(RColorBrewer)
library(ggplot2)
library(gridExtra)

cat("🧬 ANÁLISIS DE FAMILIA let-7 - OXIDACIÓN G>T\n")
cat(paste(rep("=", 60), collapse=""), "\n")

# Lista específica de miRNAs let-7 de la familia
let7_family_list <- c(
  "hsa-let-7a-5p",
  "hsa-let-7b-5p", 
  "hsa-let-7c-5p",
  "hsa-let-7d-5p",
  "hsa-let-7f-5p",
  "hsa-let-7i-5p"
)

cat("📋 Familia let-7 identificada:", length(let7_family_list), "miRNAs\n")
cat("   -", paste(let7_family_list, collapse = "\n   - "), "\n")

# Cargar dataset procesado
cat("\n📁 Cargando dataset procesado...\n")
df_processed <- read_tsv("outputs/processed_mirna_dataset_simple.tsv")

cat("   📊 Dataset procesado:", nrow(df_processed), "x", ncol(df_processed), "\n")

# Definir rangos de columnas
snv_cols <- colnames(df_processed)[3:417]
total_cols <- colnames(df_processed)[418:832]

cat("   📊 Columnas SNV:", length(snv_cols), "\n")
cat("   📊 Columnas TOTAL:", length(total_cols), "\n")

# Filtrar solo miRNAs let-7
cat("\n🔧 Filtrando familia let-7...\n")
let7_data <- df_processed %>%
  filter(miRNA.name %in% let7_family_list)

cat("   📊 miRNAs let-7 encontrados:", nrow(let7_data), "\n")
cat("   📊 miRNAs únicos let-7:", length(unique(let7_data$miRNA.name)), "\n")

# Verificar cobertura
coverage <- length(unique(let7_data$miRNA.name)) / length(let7_family_list) * 100
cat("   📊 Cobertura de familia let-7:", round(coverage, 1), "%\n")

# Filtrar mutaciones G>T en TODAS las posiciones (1-22)
cat("\n🔧 Filtrando mutaciones G>T en todas las posiciones...\n")
gt_mutations <- let7_data %>%
  filter(str_detect(pos.mut, "GT")) %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^\\d+"))) %>%
  filter(position >= 1 & position <= 22)  # TODAS las posiciones

cat("   📊 Mutaciones G>T en familia let-7:", nrow(gt_mutations), "\n")
cat("   📊 Posiciones cubiertas:", length(unique(gt_mutations$position)), "\n")
cat("   📊 Rango de posiciones:", min(gt_mutations$position), "-", max(gt_mutations$position), "\n")

# Calcular library size
cat("\n🔧 Calculando library size...\n")
library_sizes <- df_processed %>%
  select(all_of(total_cols)) %>%
  summarise(across(everything(), ~ sum(.x, na.rm = TRUE))) %>%
  unlist()

cat("   📊 Library sizes calculados para", length(library_sizes), "muestras\n")

# Calcular VAF para cada mutación
cat("\n🔧 Calculando VAF por mutación...\n")
vaf_data <- gt_mutations

# Calcular VAF usando base R para mayor robustez
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

# Agregar estadísticas VAF
vaf_data$mean_vaf <- rowMeans(vaf_matrix, na.rm = TRUE)
vaf_data$max_vaf <- apply(vaf_matrix, 1, max, na.rm = TRUE)

# Filtrar mutaciones con VAF > 50%
cat("\n🔧 Filtrando mutaciones con VAF > 50%...\n")
vaf_filtered <- vaf_data %>%
  filter(max_vaf <= 0.5)

cat("   📊 Mutaciones removidas (VAF > 50%):", nrow(vaf_data) - nrow(vaf_filtered), "\n")
cat("   📊 Mutaciones restantes:", nrow(vaf_filtered), "\n")

# Calcular RPM para cada miRNA
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

# Agregar estadísticas RPM
vaf_filtered$mean_rpm <- rowMeans(rpm_matrix, na.rm = TRUE)

# Filtrar por RPM promedio > 1
cat("\n🔧 Filtrando por RPM promedio > 1...\n")
rpm_filtered <- vaf_filtered %>%
  filter(mean_rpm > 1)

cat("   📊 Mutaciones después de filtrar RPM > 1:", nrow(rpm_filtered), "\n")
cat("   📊 miRNAs let-7 después de filtrar RPM > 1:", length(unique(rpm_filtered$miRNA.name)), "\n")

# Análisis por miembro de la familia
cat("\n🔧 Analizando por miembro de la familia let-7...\n")
family_analysis <- rpm_filtered %>%
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

cat("   📊 Análisis por miembro completado\n")
print(family_analysis)

# Crear matriz VAF para heatmap
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

# Crear anotación de muestras (ALS vs Control)
cat("\n🔧 Creando anotación de muestras...\n")
sample_annotation <- data.frame(
  group = ifelse(str_detect(snv_cols, "Control"), "Control", "ALS"),
  stringsAsFactors = FALSE
)
rownames(sample_annotation) <- snv_cols

# Colores para grupos
group_colors <- c("ALS" = "#E31A1C", "Control" = "#1F78B4")
annotation_colors <- list(group = group_colors)

# Crear heatmap
cat("\n🎨 Creando heatmap de familia let-7...\n")
png("outputs/figures/let7_family_heatmap.png", width = 1400, height = 900)
pheatmap(
  vaf_heatmap_data,
  cluster_rows = TRUE,
  cluster_cols = TRUE,
  clustering_method = "ward.D2",
  color = colorRampPalette(c("white", "red"))(100),
  annotation_row = sample_annotation,
  annotation_colors = annotation_colors,
  show_rownames = FALSE,
  show_colnames = TRUE,
  main = "VAF Heatmap - let-7 Family G>T Mutations (All Positions)",
  fontsize = 8,
  fontsize_col = 6
)
dev.off()
cat("   ✅ Heatmap guardado: outputs/figures/let7_family_heatmap.png\n")

# Crear gráficos de análisis
cat("\n🎨 Creando gráficos de análisis...\n")

# Gráfico 1: Distribución de cuentas G>T por miembro de la familia
p1 <- ggplot(family_analysis, aes(x = reorder(miRNA.name, -total_gt_counts), y = total_gt_counts)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  theme_minimal() +
  labs(title = "let-7 Family: Total G>T Counts by Member", 
       x = "let-7 Family Member", y = "Total G>T Counts") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
ggsave("outputs/figures/let7_family_gt_counts.png", p1, width = 10, height = 6)

# Gráfico 2: VAF promedio por miembro de la familia
p2 <- ggplot(family_analysis, aes(x = reorder(miRNA.name, -mean_vaf), y = mean_vaf)) +
  geom_bar(stat = "identity", fill = "darkred") +
  theme_minimal() +
  labs(title = "let-7 Family: Mean VAF by Member", 
       x = "let-7 Family Member", y = "Mean VAF") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
ggsave("outputs/figures/let7_family_mean_vaf.png", p2, width = 10, height = 6)

# Gráfico 3: RPM promedio por miembro de la familia
p3 <- ggplot(family_analysis, aes(x = reorder(miRNA.name, -mean_rpm), y = mean_rpm)) +
  geom_bar(stat = "identity", fill = "darkgreen") +
  theme_minimal() +
  labs(title = "let-7 Family: Mean RPM by Member", 
       x = "let-7 Family Member", y = "Mean RPM") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
ggsave("outputs/figures/let7_family_mean_rpm.png", p3, width = 10, height = 6)

# Gráfico 4: Análisis por posición
position_analysis <- rpm_filtered %>%
  group_by(position) %>%
  summarise(
    total_gt_counts = sum(across(all_of(snv_cols), ~ sum(.x, na.rm = TRUE))),
    mean_vaf = mean(mean_vaf, na.rm = TRUE),
    mutation_count = n(),
    .groups = "drop"
  ) %>%
  arrange(position)

p4 <- ggplot(position_analysis, aes(x = position, y = total_gt_counts)) +
  geom_bar(stat = "identity", fill = "orange") +
  theme_minimal() +
  labs(title = "let-7 Family: G>T Counts by Position", 
       x = "Position", y = "Total G>T Counts") +
  scale_x_continuous(breaks = 1:22)
ggsave("outputs/figures/let7_family_position_analysis.png", p4, width = 12, height = 6)

# Gráfico 5: VAF vs RPM scatter plot
p5 <- ggplot(family_analysis, aes(x = mean_rpm, y = mean_vaf, color = total_gt_counts)) +
  geom_point(size = 4, alpha = 0.7) +
  scale_color_viridis_c(option = "C") +
  theme_minimal() +
  labs(title = "let-7 Family: Mean VAF vs Mean RPM", 
       x = "Mean RPM", y = "Mean VAF", color = "Total G>T Counts") +
  geom_text(aes(label = miRNA.name), vjust = -0.5, hjust = 0.5, size = 3)
ggsave("outputs/figures/let7_family_vaf_vs_rpm.png", p5, width = 10, height = 8)

# Guardar resultados
cat("\n💾 Guardando resultados...\n")
write_tsv(family_analysis, "outputs/let7_family_analysis.tsv")
write_tsv(rpm_filtered, "outputs/let7_family_vaf_data.tsv")
write_tsv(position_analysis, "outputs/let7_family_position_analysis.tsv")
write_tsv(sample_annotation, "outputs/let7_family_sample_annotation.tsv")

# Crear reporte
cat("\n📋 Creando reporte de familia let-7...\n")
report_content <- c(
  "# ANÁLISIS DE FAMILIA let-7 - REPORTE\n",
  "## Resumen del Procesamiento\n",
  paste0("- **miRNAs let-7 identificados**: ", length(unique(rpm_filtered$miRNA.name)), " de ", length(let7_family_list), " esperados\n"),
  paste0("- **Mutaciones G>T en todas las posiciones**: ", nrow(gt_mutations), "\n"),
  paste0("- **Después de filtrar VAF > 50%**: ", nrow(vaf_filtered), "\n"),
  paste0("- **Después de filtrar RPM promedio > 1**: ", nrow(rpm_filtered), "\n"),
  paste0("- **Posiciones cubiertas**: ", length(unique(rpm_filtered$position)), " de 22\n\n"),
  
  "## Análisis por Miembro de la Familia\n",
  paste(
    sapply(1:nrow(family_analysis), function(i) {
      member <- family_analysis[i, ]
      paste0("- **", member$miRNA.name, "**: ", member$total_gt_counts, " cuentas G>T, RPM ", round(member$mean_rpm, 2), ", VAF ", formatC(member$mean_vaf, format = "e", digits = 2), ", posiciones ", member$positions, "\n")
    }),
    collapse = ""
  ),
  
  "\n## Análisis por Posición\n",
  paste(
    sapply(1:nrow(position_analysis), function(i) {
      pos <- position_analysis[i, ]
      paste0("- **Posición ", pos$position, "**: ", pos$total_gt_counts, " cuentas G>T, VAF ", formatC(pos$mean_vaf, format = "e", digits = 2), "\n")
    }),
    collapse = ""
  ),
  
  "\n## Archivos Generados\n",
  "- `outputs/let7_family_analysis.tsv`: Análisis por miembro\n",
  "- `outputs/let7_family_vaf_data.tsv`: Datos VAF detallados\n",
  "- `outputs/let7_family_position_analysis.tsv`: Análisis por posición\n",
  "- `outputs/figures/let7_family_*`: Gráficos y heatmap\n",
  "- `outputs/let7_family_report.md`: Este reporte\n"
)
writeLines(report_content, "outputs/let7_family_report.md")

cat("\n🎉 Análisis de familia let-7 completado!\n")
cat("   📊 Archivos generados:\n")
cat("   - outputs/let7_family_analysis.tsv\n")
cat("   - outputs/let7_family_vaf_data.tsv\n")
cat("   - outputs/let7_family_position_analysis.tsv\n")
cat("   - outputs/let7_family_report.md\n")
cat("   - outputs/figures/let7_family_*\n")
