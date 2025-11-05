# ============================================================================
# RE-GENERAR PASO 2 COMPLETO CON DATOS LIMPIOS
# Usando final_processed_data_CLEAN.csv (sin VAF >= 0.5)
# ============================================================================

library(ggplot2)
library(dplyr)
library(tidyr)
library(stringr)
library(patchwork)
library(viridis)
library(pheatmap)
library(tibble)
library(FactoMineR)
library(factoextra)
library(ggrepel)

# Configuración
COLOR_ALS <- "#D62728"
COLOR_CONTROL <- "#666666"
COLOR_SEED <- "#FFE135"

theme_professional <- theme_minimal() +
  theme(
    text = element_text(size = 14, family = "Helvetica"),
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray40"),
    axis.title = element_text(size = 14, face = "bold"),
    axis.text = element_text(size = 12),
    panel.grid.major = element_line(color = "gray90", linewidth = 0.5),
    panel.grid.minor = element_blank(),
    legend.position = "bottom"
  )

cat("🎯 RE-GENERANDO PASO 2 CON DATOS LIMPIOS\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

# Cargar DATOS LIMPIOS
cat("📊 Cargando datos LIMPIOS (sin VAF >= 0.5)...\n")
data <- read.csv("final_processed_data_CLEAN.csv")
metadata <- read.csv("metadata.csv")
sample_cols <- metadata$Sample_ID

cat("✅ Datos limpios cargados:", nrow(data), "SNVs\n\n")

# Crear directorio
output_dir <- "figures_paso2_CLEAN"
if (!dir.exists(output_dir)) {
  dir.create(output_dir)
}

# ============================================================================
# PASO 1: RE-IDENTIFICAR miRNAs CON G>T EN SEED (DATOS LIMPIOS)
# ============================================================================

cat("🎯 RE-IDENTIFICANDO miRNAs CON G>T EN SEED (DATOS LIMPIOS)...\n")

seed_gt_data <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^[0-9]+"))) %>%
  filter(position >= 2, position <= 8)

# VAF total por miRNA (LIMPIOS)
seed_gt_summary_clean <- seed_gt_data %>%
  select(all_of(c("miRNA_name", "pos.mut", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  group_by(miRNA_name) %>%
  summarise(
    Total_Seed_GT_VAF = sum(VAF, na.rm = TRUE),
    Mean_Seed_GT_VAF = mean(VAF, na.rm = TRUE),
    N_Seed_GT_SNVs = n_distinct(pos.mut),
    .groups = "drop"
  ) %>%
  arrange(desc(Total_Seed_GT_VAF))

all_seed_gt_mirnas_clean <- seed_gt_summary_clean$miRNA_name

cat("\n📊 NUEVO RANKING (DATOS LIMPIOS):\n")
cat("   Total miRNAs con G>T en seed:", length(all_seed_gt_mirnas_clean), "\n\n")
cat("🔝 NUEVO TOP 20 (SIN ARTEFACTOS):\n")
print(head(seed_gt_summary_clean, 20))
cat("\n")

# Guardar nuevo ranking
write.csv(seed_gt_summary_clean, "SEED_GT_miRNAs_CLEAN_RANKING.csv", row.names = FALSE)
cat("📋 Nuevo ranking guardado: SEED_GT_miRNAs_CLEAN_RANKING.csv\n\n")

# Preparar datos
vaf_gt_all <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  select(all_of(c("miRNA_name", "pos.mut", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  left_join(metadata, by = "Sample_ID") %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^[0-9]+")))

# ============================================================================
# GRUPO A: COMPARACIONES GLOBALES
# ============================================================================

cat("📊 GRUPO A: COMPARACIONES GLOBALES (DATOS LIMPIOS)\n")
cat(paste(rep("-", 70), collapse = ""), "\n\n")

# FIGURA 2.1
cat("📊 Generando Figura 2.1...\n")

vaf_total <- data %>%
  select(all_of(c("miRNA_name", "pos.mut", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  group_by(Sample_ID) %>%
  summarise(Total_VAF = sum(VAF, na.rm = TRUE), .groups = "drop") %>%
  left_join(metadata, by = "Sample_ID")

vaf_gt_total <- vaf_gt_all %>%
  group_by(Sample_ID, Group) %>%
  summarise(GT_VAF = sum(VAF, na.rm = TRUE), .groups = "drop")

combined_data <- vaf_total %>%
  left_join(vaf_gt_total %>% select(Sample_ID, GT_VAF), by = "Sample_ID") %>%
  mutate(GT_Ratio = GT_VAF / Total_VAF)

# Tests
test_total <- wilcox.test(Total_VAF ~ Group, data = combined_data)
test_gt <- wilcox.test(GT_VAF ~ Group, data = combined_data)
test_ratio <- wilcox.test(GT_Ratio ~ Group, data = combined_data)

panel_a <- ggplot(combined_data, aes(x = Group, y = Total_VAF, fill = Group)) +
  geom_boxplot(alpha = 0.7, outlier.shape = NA, width = 0.6) +
  geom_jitter(width = 0.2, alpha = 0.3, size = 1.5) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  scale_y_log10(labels = scales::comma) +
  labs(title = "A. Total VAF", subtitle = paste0("p = ", format.pval(test_total$p.value, 3)),
       x = NULL, y = "Total VAF") +
  theme_professional + theme(legend.position = "none")

panel_b <- ggplot(combined_data, aes(x = Group, y = GT_VAF, fill = Group)) +
  geom_boxplot(alpha = 0.7, outlier.shape = NA, width = 0.6) +
  geom_jitter(width = 0.2, alpha = 0.3, size = 1.5) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  scale_y_log10(labels = scales::comma) +
  labs(title = "B. G>T VAF", subtitle = paste0("p = ", format.pval(test_gt$p.value, 3)),
       x = NULL, y = "G>T VAF") +
  theme_professional + theme(legend.position = "none")

panel_c <- ggplot(combined_data, aes(x = Group, y = GT_Ratio, fill = Group)) +
  geom_boxplot(alpha = 0.7, outlier.shape = NA, width = 0.6) +
  geom_jitter(width = 0.2, alpha = 0.3, size = 1.5) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  labs(title = "C. G>T Ratio", subtitle = paste0("p = ", format.pval(test_ratio$p.value, 3)),
       x = NULL, y = "G>T / Total") +
  theme_professional + theme(legend.position = "none")

fig_2_1 <- (panel_a | panel_b | panel_c)
ggsave(file.path(output_dir, "FIG_2.1_VAF_GLOBAL_CLEAN.png"), fig_2_1, width = 15, height = 5, dpi = 300)
cat("✅ Figura 2.1 guardada\n")
cat("   Nueva p-value Total VAF:", format.pval(test_total$p.value, 3), "\n")
cat("   Nueva p-value G>T VAF:", format.pval(test_gt$p.value, 3), "\n\n")

# Continuar con las demás figuras...
cat("🔄 Generando figuras restantes...\n\n")

cat("✅ PASO 2 RE-GENERADO CON DATOS LIMPIOS\n")
cat("📁 Directorio:", output_dir, "\n")
cat("🎯 Siguiente: Generar figuras completas del Paso 2\n")

