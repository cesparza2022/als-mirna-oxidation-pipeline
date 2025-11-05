# ============================================================================
# VOLCANO PLOT CORRECTO - MÉTODO POR MUESTRA
# Cada punto = 1 miRNA
# Comparación basada en VAF promedio POR MUESTRA (no valores mezclados)
# ============================================================================

library(ggplot2)
library(dplyr)
library(tidyr)
library(stringr)
library(ggrepel)

COLOR_ALS <- "#D62728"
COLOR_CONTROL <- "#666666"

theme_professional <- theme_minimal() +
  theme(
    text = element_text(size = 14, family = "Helvetica"),
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray40"),
    axis.title = element_text(size = 14, face = "bold"),
    axis.text = element_text(size = 12),
    panel.grid.major = element_line(color = "gray90", linewidth = 0.5),
    panel.border = element_rect(color = "gray30", fill = NA, linewidth = 1)
  )

cat("🎯 GENERANDO VOLCANO PLOT CON MÉTODO CORRECTO\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

# Cargar datos
cat("📊 Cargando datos limpios...\n")
data <- read.csv("final_processed_data_CLEAN.csv")
metadata <- read.csv("metadata.csv")
seed_ranking <- read.csv("SEED_GT_miRNAs_CLEAN_RANKING.csv")
sample_cols <- metadata$Sample_ID

# Lista de miRNAs con G>T en seed
all_seed_gt_mirnas <- seed_ranking$miRNA_name

cat("✅ Datos cargados\n")
cat("   miRNAs a testear:", length(all_seed_gt_mirnas), "\n\n")

# Preparar datos de G>T
vaf_gt_all <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  select(all_of(c("miRNA_name", "pos.mut", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  left_join(metadata, by = "Sample_ID")

cat("📊 MÉTODO: PROMEDIO POR MUESTRA\n")
cat(paste(rep("-", 70), collapse = ""), "\n")
cat("Para cada miRNA:\n")
cat("  1. Calcular VAF total de G>T por MUESTRA (suma de todos los SNVs)\n")
cat("  2. Comparar las 313 muestras ALS vs 102 muestras Control\n")
cat("  3. Cada muestra pesa IGUAL (sin sesgo por # de SNVs)\n\n")

# Calcular volcano plot
cat("📊 Calculando Fold Change y p-values para", length(all_seed_gt_mirnas), "miRNAs...\n\n")

volcano_data <- data.frame()
pb <- txtProgressBar(min = 0, max = length(all_seed_gt_mirnas), style = 3)

for (i in seq_along(all_seed_gt_mirnas)) {
  mirna <- all_seed_gt_mirnas[i]
  
  # Extraer datos del miRNA
  mirna_data <- vaf_gt_all %>% filter(miRNA_name == mirna)
  
  # MÉTODO CORRECTO: Calcular VAF total POR MUESTRA
  per_sample <- mirna_data %>%
    group_by(Sample_ID, Group) %>%
    summarise(Total_GT_VAF = sum(VAF, na.rm = TRUE), .groups = "drop")
  
  # Separar por grupo (ahora son valores por muestra, no por SNV)
  als_vals <- per_sample %>% filter(Group == "ALS") %>% pull(Total_GT_VAF)
  ctrl_vals <- per_sample %>% filter(Group == "Control") %>% pull(Total_GT_VAF)
  
  # Verificar suficientes muestras (no valores)
  if (length(als_vals) > 10 && length(ctrl_vals) > 10) {
    # Calcular medias (cada muestra pesa igual)
    mean_als <- mean(als_vals, na.rm = TRUE)
    mean_ctrl <- mean(ctrl_vals, na.rm = TRUE)
    
    # Evitar log2(0)
    if (mean_als == 0) mean_als <- 0.0001
    if (mean_ctrl == 0) mean_ctrl <- 0.0001
    
    # Fold Change
    fc <- log2(mean_als / mean_ctrl)
    
    # Test estadístico (comparando muestras)
    test_result <- tryCatch({
      wilcox.test(als_vals, ctrl_vals)
    }, error = function(e) {
      list(p.value = 1)
    })
    
    # Guardar resultados
    volcano_data <- rbind(volcano_data, data.frame(
      miRNA = mirna,
      log2FC = fc,
      pvalue = test_result$p.value,
      Mean_ALS = mean_als,
      Mean_Control = mean_ctrl,
      N_ALS_samples = length(als_vals),
      N_Control_samples = length(ctrl_vals)
    ))
  }
  
  setTxtProgressBar(pb, i)
}
close(pb)

cat("\n\n✅ Cálculos completados para", nrow(volcano_data), "miRNAs\n\n")

# Ajustar p-values por FDR
cat("📊 Aplicando corrección FDR...\n")
volcano_data$padj <- p.adjust(volcano_data$pvalue, method = "fdr")
volcano_data$neg_log10_padj <- -log10(volcano_data$padj)

# Clasificar por significancia
volcano_data$Significance <- "NS"
volcano_data$Significance[volcano_data$log2FC > 0.58 & volcano_data$padj < 0.05] <- "ALS enriched"
volcano_data$Significance[volcano_data$log2FC < -0.58 & volcano_data$padj < 0.05] <- "Control enriched"

# Contar por categoría
sig_summary <- volcano_data %>%
  group_by(Significance) %>%
  summarise(Count = n())

cat("\n📊 RESULTADOS:\n")
print(sig_summary)
cat("\n")

# Top miRNAs para etiquetar
top_labels <- volcano_data %>%
  filter(Significance != "NS") %>%
  arrange(padj) %>%
  head(20)

cat("🔝 TOP 20 miRNAs SIGNIFICATIVOS:\n")
if (nrow(top_labels) > 0) {
  print(top_labels %>% select(miRNA, log2FC, padj, Significance))
} else {
  cat("   Ningún miRNA alcanza los thresholds de significancia\n")
}
cat("\n")

# Crear volcano plot
cat("📊 Creando Volcano Plot...\n")

figure_volcano <- ggplot(volcano_data, aes(x = log2FC, y = neg_log10_padj, color = Significance)) +
  geom_point(alpha = 0.6, size = 2.5) +
  geom_hline(yintercept = -log10(0.05), linetype = "dashed", color = "gray50", linewidth = 1) +
  geom_vline(xintercept = c(-0.58, 0.58), linetype = "dashed", color = "gray50", linewidth = 1) +
  scale_color_manual(
    values = c(
      "ALS enriched" = COLOR_ALS, 
      "Control enriched" = "steelblue",
      "NS" = "gray70"
    ),
    labels = c(
      "ALS enriched" = paste0("ALS enriched (n=", sum(volcano_data$Significance == "ALS enriched"), ")"),
      "Control enriched" = paste0("Control enriched (n=", sum(volcano_data$Significance == "Control enriched"), ")"),
      "NS" = paste0("Not significant (n=", sum(volcano_data$Significance == "NS"), ")")
    )
  ) +
  labs(
    title = "Volcano Plot: miRNAs with G>T in SEED (Per-Sample Method)",
    subtitle = paste0("n=", nrow(volcano_data), " miRNAs | Method: VAF per sample → mean per group → test"),
    x = "log2(Fold Change): log2(mean_ALS / mean_Control)",
    y = "-log10(FDR-adjusted p-value)",
    color = "Category"
  ) +
  annotate("text", x = Inf, y = Inf, 
           label = "Each point = 1 miRNA\nComparing per-sample VAF\n(313 ALS vs 102 Control)",
           hjust = 1.1, vjust = 1.5, size = 3.5, color = "gray30", fontface = "italic") +
  theme_professional +
  theme(legend.position = "bottom")

# Añadir labels para top miRNAs
if (nrow(top_labels) > 0) {
  figure_volcano <- figure_volcano +
    geom_text_repel(
      data = top_labels, 
      aes(label = miRNA), 
      size = 3, 
      max.overlaps = 25, 
      color = "black",
      box.padding = 0.5,
      point.padding = 0.3
    )
}

# Guardar
output_dir <- "figures_paso2_CLEAN"
ggsave(file.path(output_dir, "FIG_2.3_VOLCANO_PER_SAMPLE_METHOD.png"), 
       plot = figure_volcano, width = 14, height = 11, dpi = 300)

cat("✅ VOLCANO PLOT GENERADO\n")
cat("📁 Archivo:", file.path(output_dir, "FIG_2.3_VOLCANO_PER_SAMPLE_METHOD.png"), "\n")
cat("📊 miRNAs testeados:", nrow(volcano_data), "\n")
cat("   - ALS enriched:", sum(volcano_data$Significance == "ALS enriched"), "\n")
cat("   - Control enriched:", sum(volcano_data$Significance == "Control enriched"), "\n")
cat("   - No significativo:", sum(volcano_data$Significance == "NS"), "\n\n")

# Guardar datos del volcano plot
write.csv(volcano_data, "VOLCANO_PLOT_DATA_PER_SAMPLE.csv", row.names = FALSE)
cat("📋 Datos guardados en: VOLCANO_PLOT_DATA_PER_SAMPLE.csv\n")
cat("   (Útil para revisar FC y p-values de cada miRNA)\n\n")

cat("🎯 MÉTODO USADO: Promedio por muestra (Opción B)\n")
cat("✅ Registrado en: METODO_VOLCANO_PLOT.md\n")

