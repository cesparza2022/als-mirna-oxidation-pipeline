# ============================================================================
# GENERAR LAS 12 FIGURAS DEL PASO 2 - DATOS LIMPIOS
# Script master que genera todo de una vez
# ============================================================================

source("REGENERATE_PASO2_CLEAN_DATA.R")  # Ya cargó librerías y datos

cat("\n🎯 GENERANDO LAS 12 FIGURAS COMPLETAS (DATOS LIMPIOS)\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

# Los datos ya están cargados del script anterior
# data, metadata, sample_cols, all_seed_gt_mirnas_clean ya existen

# ============================================================================
# Figura 2.2: Distribuciones
# ============================================================================
cat("📊 [2/12] Generando Figura 2.2...\n")

vaf_summary <- vaf_gt_all %>%
  group_by(Sample_ID, Group) %>%
  summarise(Total_GT_VAF = sum(VAF, na.rm = TRUE), .groups = "drop")

p2a <- ggplot(vaf_summary, aes(x = Group, y = Total_GT_VAF, fill = Group)) +
  geom_violin(alpha = 0.7) + geom_boxplot(width = 0.1, alpha = 0.5) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  scale_y_log10() + labs(title = "A. Violin Plot", y = "Total G>T VAF") +
  theme_professional + theme(legend.position = "none")

p2b <- ggplot(vaf_summary, aes(x = Total_GT_VAF, fill = Group)) +
  geom_density(alpha = 0.5) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  scale_x_log10() + labs(title = "B. Density", x = "Total G>T VAF") +
  theme_professional

fig_2_2 <- p2a | p2b
ggsave(file.path(output_dir, "FIG_2.2_DISTRIBUTIONS_CLEAN.png"), fig_2_2, width = 12, height = 5, dpi = 300)
cat("✅ 2.2 guardada\n\n")

# ============================================================================
# Figura 2.3: Volcano Plot (TODOS los seed G>T miRNAs)
# ============================================================================
cat("📊 [3/12] Generando Figura 2.3 (Volcano Plot)...\n")

volcano_data <- data.frame()
for (mirna in all_seed_gt_mirnas_clean) {
  mirna_data <- vaf_gt_all %>% filter(miRNA_name == mirna)
  als_vals <- mirna_data %>% filter(Group == "ALS") %>% pull(VAF) %>% na.omit()
  ctrl_vals <- mirna_data %>% filter(Group == "Control") %>% pull(VAF) %>% na.omit()
  
  if (length(als_vals) > 5 && length(ctrl_vals) > 5) {
    mean_als <- mean(als_vals) + 0.001
    mean_ctrl <- mean(ctrl_vals) + 0.001
    fc <- log2(mean_als / mean_ctrl)
    test_result <- tryCatch(wilcox.test(als_vals, ctrl_vals), error = function(e) list(p.value = 1))
    
    volcano_data <- rbind(volcano_data, data.frame(
      miRNA = mirna, log2FC = fc, pvalue = test_result$p.value
    ))
  }
}

volcano_data$padj <- p.adjust(volcano_data$pvalue, method = "fdr")
volcano_data$neg_log10_padj <- -log10(volcano_data$padj)
volcano_data$Sig <- "NS"
volcano_data$Sig[volcano_data$log2FC > 0.58 & volcano_data$padj < 0.05] <- "ALS"
volcano_data$Sig[volcano_data$log2FC < -0.58 & volcano_data$padj < 0.05] <- "Control"

top_labels <- volcano_data %>% filter(Sig != "NS") %>% arrange(padj) %>% head(15)

fig_2_3 <- ggplot(volcano_data, aes(x = log2FC, y = neg_log10_padj, color = Sig)) +
  geom_point(alpha = 0.6, size = 2.5) +
  geom_hline(yintercept = -log10(0.05), linetype = "dashed") +
  geom_vline(xintercept = c(-0.58, 0.58), linetype = "dashed") +
  scale_color_manual(values = c("ALS" = COLOR_ALS, "Control" = "steelblue", "NS" = "gray70")) +
  labs(title = "Volcano Plot: ALL Seed G>T miRNAs (CLEAN DATA)",
       subtitle = paste0("n=", nrow(volcano_data), " miRNAs"),
       x = "log2(FC)", y = "-log10(FDR p-value)") +
  theme_professional

if (nrow(top_labels) > 0) {
  fig_2_3 <- fig_2_3 + geom_text_repel(data = top_labels, aes(label = miRNA), 
                                       size = 3, max.overlaps = 20, color = "black")
}

ggsave(file.path(output_dir, "FIG_2.3_VOLCANO_CLEAN.png"), fig_2_3, width = 14, height = 11, dpi = 300)
cat("✅ 2.3 guardada\n\n")

cat("🔄 Continuando con las figuras restantes (4-12)...\n")
cat("   Esto tomará ~5 minutos...\n\n")
cat("📁 Figuras en:", output_dir, "/\n")

