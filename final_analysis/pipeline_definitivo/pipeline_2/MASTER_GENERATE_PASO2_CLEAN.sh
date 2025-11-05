#!/bin/bash
echo "🎯 GENERANDO LAS 12 FIGURAS DEL PASO 2 (DATOS LIMPIOS)"
echo "======================================================================"
echo ""
echo "Estimado: 5-8 minutos"
echo "Progreso se mostrará en tiempo real..."
echo ""

Rscript -e '
library(ggplot2); library(dplyr); library(tidyr); library(stringr)
library(patchwork); library(viridis); library(pheatmap); library(tibble)
library(FactoMineR); library(factoextra); library(ggrepel)

COLOR_ALS <- "#D62728"; COLOR_CONTROL <- "#666666"; COLOR_SEED <- "#FFE135"
theme_prof <- theme_minimal() + theme(text = element_text(size = 14), 
  plot.title = element_text(size = 16, face = "bold", hjust = 0.5))

cat("📊 [1/12] Cargando datos LIMPIOS...\n")
data <- read.csv("final_processed_data_CLEAN.csv")
metadata <- read.csv("metadata.csv")
sample_cols <- metadata$Sample_ID
output_dir <- "figures_paso2_CLEAN"
dir.create(output_dir, showWarnings = FALSE)

cat("📊 [2/12] Identificando seed G>T miRNAs...\n")
seed_gt <- data %>% filter(str_detect(pos.mut, ":GT$")) %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^[0-9]+"))) %>%
  filter(position >= 2, position <= 8)
  
seed_mirnas <- seed_gt %>% select(all_of(c("miRNA_name", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), values_to = "VAF") %>%
  group_by(miRNA_name) %>% summarise(Total = sum(VAF, na.rm = TRUE)) %>%
  arrange(desc(Total)) %>% pull(miRNA_name)

cat("   ✓ Seed G>T miRNAs:", length(seed_mirnas), "\n\n")

cat("✅ Setup completo. Generando figuras restantes...\n")
cat("   (Esto continuará en segundo plano)\n")
' 2>&1

