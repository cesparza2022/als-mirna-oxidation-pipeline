#!/usr/bin/env Rscript
# ============================================================================
# GENERAR OPCIONES DE HEATMAP: Top30, Top50, Resumen Agregado
# Para que el usuario compare y decida
# ============================================================================

library(ggplot2)
library(dplyr)
library(tidyr)
library(readr)
library(stringr)
library(pheatmap)
library(tibble)
library(viridis)

# Colores
COLOR_ALS <- "#D62728"
COLOR_CONTROL <- "#404040"

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  GENERANDO OPCIONES DE HEATMAP POSICIONAL\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# ============================================================================
# LOAD DATA
# ============================================================================

cat("📂 Cargando datos...\n")
data <- read_csv("final_processed_data_CLEAN.csv", show_col_types = FALSE)
metadata <- read_csv("metadata.csv", show_col_types = FALSE)
sample_cols <- metadata$Sample_ID

# Filtrar G>T en seed
seed_gt_data <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^[0-9]+"))) %>%
  filter(position >= 2, position <= 8)

# Calcular ranking
seed_gt_summary <- seed_gt_data %>%
  select(all_of(c("miRNA_name", "pos.mut", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  group_by(miRNA_name) %>%
  summarise(Total_Seed_GT_VAF = sum(VAF, na.rm = TRUE), .groups = "drop") %>%
  arrange(desc(Total_Seed_GT_VAF))

cat("   ✅ Datos cargados\n")
cat("   ✅ Total miRNAs con G>T en seed:", nrow(seed_gt_summary), "\n\n")

# ============================================================================
# PREPARAR DATOS PARA HEATMAP
# ============================================================================

# Filtrar TODOS los G>T (no solo seed, para mostrar posiciones 1-22)
vaf_gt_all_pos <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^[0-9]+"))) %>%
  filter(!is.na(position), position <= 22)

# Transformar a largo
vaf_matrix_data <- vaf_gt_all_pos %>%
  select(all_of(c("miRNA_name", "position", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  left_join(metadata, by = "Sample_ID") %>%
  group_by(miRNA_name, position, Group) %>%
  summarise(Mean_VAF = mean(VAF, na.rm = TRUE), .groups = "drop")

# Función para crear matriz
create_heatmap_matrix <- function(group_name, mirna_list) {
  matrix_data <- vaf_matrix_data %>%
    filter(Group == group_name, miRNA_name %in% mirna_list) %>%
    select(miRNA_name, position, Mean_VAF) %>%
    pivot_wider(names_from = position, values_from = Mean_VAF, values_fill = 0) %>%
    column_to_rownames("miRNA_name")
  
  # Asegurar todas las posiciones 1-22
  all_positions <- as.character(1:22)
  for (pos in setdiff(all_positions, colnames(matrix_data))) {
    matrix_data[[pos]] <- 0
  }
  
  matrix_data <- matrix_data[, all_positions]
  return(as.matrix(matrix_data))
}

# ============================================================================
# OPCIÓN 1: TOP 30
# ============================================================================

cat("🎨 [1/4] Generando OPCIÓN A: Top 30 miRNAs...\n")

top30 <- head(seed_gt_summary, 30)$miRNA_name

png("figures_paso2_CLEAN/OPCION_A_HEATMAP_TOP30.png", 
    width = 14, height = 12, units = "in", res = 300)
par(mfrow = c(1, 2), mar = c(5, 4, 4, 2))

mat_als_30 <- create_heatmap_matrix("ALS", top30)
pheatmap(mat_als_30,
         main = "ALS - Top 30 miRNAs",
         color = colorRampPalette(c("white", COLOR_ALS))(100),
         cluster_cols = FALSE,
         fontsize = 10,
         silent = TRUE)

mat_ctrl_30 <- create_heatmap_matrix("Control", top30)
pheatmap(mat_ctrl_30,
         main = "Control - Top 30 miRNAs",
         color = colorRampPalette(c("white", COLOR_CONTROL))(100),
         cluster_cols = FALSE,
         fontsize = 10,
         silent = TRUE)

dev.off()
cat("   ✅ OPCIÓN A guardada (Top 30 - MÁS LEGIBLE)\n\n")

# ============================================================================
# OPCIÓN 2: TOP 50 (actual)
# ============================================================================

cat("🎨 [2/4] Generando OPCIÓN B: Top 50 miRNAs (actual)...\n")

top50 <- head(seed_gt_summary, 50)$miRNA_name

png("figures_paso2_CLEAN/OPCION_B_HEATMAP_TOP50.png", 
    width = 14, height = 14, units = "in", res = 300)
par(mfrow = c(1, 2), mar = c(5, 4, 4, 2))

mat_als_50 <- create_heatmap_matrix("ALS", top50)
pheatmap(mat_als_50,
         main = "ALS - Top 50 miRNAs",
         color = colorRampPalette(c("white", COLOR_ALS))(100),
         cluster_cols = FALSE,
         fontsize = 8,
         silent = TRUE)

mat_ctrl_50 <- create_heatmap_matrix("Control", top50)
pheatmap(mat_ctrl_50,
         main = "Control - Top 50 miRNAs",
         color = colorRampPalette(c("white", COLOR_CONTROL))(100),
         cluster_cols = FALSE,
         fontsize = 8,
         silent = TRUE)

dev.off()
cat("   ✅ OPCIÓN B guardada (Top 50 - BALANCE)\n\n")

# ============================================================================
# OPCIÓN 3: TODOS (301) sin nombres
# ============================================================================

cat("🎨 [3/4] Generando OPCIÓN C: TODOS (301) sin nombres...\n")

all_mirnas <- seed_gt_summary$miRNA_name

png("figures_paso2_CLEAN/OPCION_C_HEATMAP_ALL301_NO_LABELS.png", 
    width = 14, height = 16, units = "in", res = 300)
par(mfrow = c(1, 2), mar = c(5, 4, 4, 2))

mat_als_all <- create_heatmap_matrix("ALS", all_mirnas)
pheatmap(mat_als_all,
         main = "ALS - ALL 301 miRNAs",
         color = colorRampPalette(c("white", COLOR_ALS))(100),
         cluster_cols = FALSE,
         show_rownames = FALSE,  # Sin nombres (ilegibles)
         fontsize = 8,
         silent = TRUE)

mat_ctrl_all <- create_heatmap_matrix("Control", all_mirnas)
pheatmap(mat_ctrl_all,
         main = "Control - ALL 301 miRNAs",
         color = colorRampPalette(c("white", COLOR_CONTROL))(100),
         cluster_cols = FALSE,
         show_rownames = FALSE,
         fontsize = 8,
         silent = TRUE)

dev.off()
cat("   ✅ OPCIÓN C guardada (ALL 301 - SIN NOMBRES)\n\n")

# ============================================================================
# OPCIÓN 4: RESUMEN AGREGADO (promedio de TODOS)
# ============================================================================

cat("🎨 [4/4] Generando OPCIÓN D: Resumen agregado (TODOS los miRNAs)...\n")

# Calcular promedio por posición y grupo (TODOS los miRNAs)
summary_data <- vaf_matrix_data %>%
  group_by(position, Group) %>%
  summarise(Mean_VAF = mean(Mean_VAF, na.rm = TRUE), .groups = "drop")

# Crear matriz para ggplot
summary_matrix <- summary_data %>%
  pivot_wider(names_from = position, values_from = Mean_VAF, values_fill = 0)

# Plot con ggplot (más control)
plot_data <- summary_data %>%
  mutate(position = factor(position, levels = 1:22))

fig_summary <- ggplot(plot_data, aes(x = position, y = Group, fill = Mean_VAF)) +
  geom_tile(color = "white", linewidth = 0.5) +
  geom_text(aes(label = ifelse(Mean_VAF > 0.0001, 
                                sprintf("%.4f", Mean_VAF), "")), 
            size = 2.5, color = "white", fontface = "bold") +
  scale_fill_gradient2(
    low = "white", 
    mid = "#FFA500",
    high = COLOR_ALS, 
    midpoint = max(plot_data$Mean_VAF) * 0.3,
    name = "Mean VAF\n(all miRNAs)"
  ) +
  # Marcar región seed
  annotate("rect", xmin = 1.5, xmax = 8.5, ymin = 0.5, ymax = 2.5,
           fill = NA, color = "blue", linewidth = 1.2, linetype = "dashed") +
  annotate("text", x = 5, y = 2.7, label = "SEED REGION", 
           color = "blue", fontface = "bold", size = 4) +
  labs(
    title = "Average G>T VAF Across All Positions",
    subtitle = paste0("Aggregated from ALL ", nrow(seed_gt_summary), " miRNAs with G>T in seed"),
    x = "Position in miRNA",
    y = NULL
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", hjust = 0.5, size = 16),
    plot.subtitle = element_text(hjust = 0.5, color = "gray40", size = 11),
    axis.text = element_text(size = 12),
    axis.text.y = element_text(face = "bold", size = 13),
    axis.title = element_text(face = "bold", size = 13),
    legend.position = "right",
    panel.grid = element_blank()
  )

ggsave("figures_paso2_CLEAN/OPCION_D_HEATMAP_SUMMARY_ALL.png", 
       fig_summary, width = 14, height = 5, dpi = 300, bg = "white")

cat("   ✅ OPCIÓN D guardada (RESUMEN TODOS - SIMPLE Y CLARO)\n\n")

# ============================================================================
# RESUMEN
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("✅ CUATRO OPCIONES GENERADAS:\n")
cat("\n")
cat("   A. OPCION_A_HEATMAP_TOP30.png\n")
cat("      → Top 30 miRNAs\n")
cat("      → MÁS legible\n")
cat("      → Enfocado en los más importantes\n")
cat("      → Nombres identificables\n\n")

cat("   B. OPCION_B_HEATMAP_TOP50.png\n")
cat("      → Top 50 miRNAs\n")
cat("      → Balance entre detalle y legibilidad\n")
cat("      → Versión actual\n\n")

cat("   C. OPCION_C_HEATMAP_ALL301_NO_LABELS.png\n")
cat("      → TODOS los 301 miRNAs\n")
cat("      → SIN nombres (ilegibles)\n")
cat("      → Muestra patrón general\n")
cat("      → No identifica miRNAs específicos\n\n")

cat("   D. OPCION_D_HEATMAP_SUMMARY_ALL.png ⭐\n")
cat("      → Resumen de TODOS los 301 miRNAs\n")
cat("      → 1 fila por grupo (ALS y Control)\n")
cat("      → Muestra patrón posicional GLOBAL\n")
cat("      → Simple, claro, usa TODA la información\n")
cat("      → Región seed marcada con rectángulo azul\n\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("💡 RECOMENDACIÓN:\n")
cat("\n")
cat("   Usar AMBAS:\n")
cat("      • OPCIÓN A (Top 30): Para mostrar miRNAs específicos\n")
cat("      • OPCIÓN D (Summary): Para mostrar patrón posicional global\n")
cat("\n")
cat("   O si solo una:\n")
cat("      • OPCIÓN D es la más informativa (usa TODOS los datos)\n")
cat("\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("📁 Directorio: figures_paso2_CLEAN/\n")
cat("\n")

