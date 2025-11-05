#!/usr/bin/env Rscript
# ============================================================================
# DOS VOLCANOS: SEED vs ALL POSITIONS
# Comparar si el efecto es específico del seed o global
# ============================================================================

library(ggplot2)
library(dplyr)
library(tidyr)
library(readr)
library(stringr)
library(ggrepel)
library(patchwork)

# Colores
COLOR_ALS <- "#D62728"
COLOR_CONTROL <- "#404040"
COLOR_NS <- "gray80"

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  COMPARACIÓN: VOLCANO SEED vs VOLCANO ALL\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# ============================================================================
# LOAD DATA
# ============================================================================

cat("📂 Cargando datos...\n")
data <- read_csv("final_processed_data_CLEAN.csv", show_col_types = FALSE)
metadata <- read_csv("metadata.csv", show_col_types = FALSE)
sample_cols <- metadata$Sample_ID

cat("   ✅ Datos cargados\n\n")

# ============================================================================
# FUNCIÓN PARA GENERAR VOLCANO
# ============================================================================

generate_volcano <- function(gt_data, title_suffix, filename) {
  
  # Transformar a formato largo
  vaf_long <- gt_data %>%
    select(all_of(c("miRNA_name", "pos.mut", sample_cols))) %>%
    pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
    left_join(metadata, by = "Sample_ID")
  
  # miRNAs únicos
  all_mirnas <- unique(gt_data$miRNA_name)
  
  # Calcular volcano data
  volcano_data <- data.frame()
  for (mirna in all_mirnas) {
    mirna_data <- vaf_long %>% filter(miRNA_name == mirna)
    als_vals <- mirna_data %>% filter(Group == "ALS") %>% pull(VAF) %>% na.omit()
    ctrl_vals <- mirna_data %>% filter(Group == "Control") %>% pull(VAF) %>% na.omit()
    
    if (length(als_vals) > 5 && length(ctrl_vals) > 5) {
      mean_als <- mean(als_vals) + 0.001
      mean_ctrl <- mean(ctrl_vals) + 0.001
      fc <- log2(mean_als / mean_ctrl)
      test_result <- tryCatch(wilcox.test(als_vals, ctrl_vals), error = function(e) list(p.value = 1))
      
      volcano_data <- rbind(volcano_data, data.frame(
        miRNA = mirna,
        log2FC = fc,
        pvalue = test_result$p.value,
        Mean_ALS = mean_als - 0.001,
        Mean_Control = mean_ctrl - 0.001
      ))
    }
  }
  
  # Ajuste FDR
  volcano_data$padj <- p.adjust(volcano_data$pvalue, method = "fdr")
  volcano_data$neg_log10_padj <- -log10(volcano_data$padj)
  
  # Clasificar
  volcano_data$Sig <- "NS"
  volcano_data$Sig[volcano_data$log2FC > 0.58 & volcano_data$padj < 0.05] <- "ALS"
  volcano_data$Sig[volcano_data$log2FC < -0.58 & volcano_data$padj < 0.05] <- "Control"
  
  # Reportar
  n_sig_als <- sum(volcano_data$Sig == "ALS")
  n_sig_ctrl <- sum(volcano_data$Sig == "Control")
  n_ns <- sum(volcano_data$Sig == "NS")
  
  cat("   📊", title_suffix, ":\n")
  cat("      miRNAs analizados:", nrow(volcano_data), "\n")
  cat("      Sig ALS:", n_sig_als, "\n")
  cat("      Sig Control:", n_sig_ctrl, "\n")
  cat("      NS:", n_ns, "\n\n")
  
  # Top labels
  top_labels <- volcano_data %>%
    filter(Sig != "NS") %>%
    arrange(padj) %>%
    head(15)
  
  # Plot
  theme_prof <- theme_classic(base_size = 13) +
    theme(
      plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
      plot.subtitle = element_text(size = 10, hjust = 0.5, color = "gray40"),
      axis.title = element_text(face = "bold", size = 11),
      axis.text = element_text(size = 10),
      legend.position = "bottom",
      legend.background = element_rect(fill = "white", color = "gray80"),
      panel.grid.major = element_line(color = "gray90", linewidth = 0.3)
    )
  
  fig <- ggplot(volcano_data, aes(x = log2FC, y = neg_log10_padj, color = Sig)) +
    geom_point(alpha = 0.6, size = 2) +
    geom_hline(yintercept = -log10(0.05), linetype = "dashed", color = "gray50", linewidth = 0.5) +
    geom_vline(xintercept = c(-0.58, 0.58), linetype = "dashed", color = "gray50", linewidth = 0.5) +
    scale_color_manual(
      values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL, "NS" = COLOR_NS),
      labels = c("ALS" = paste0("ALS (n=", n_sig_als, ")"),
                 "Control" = paste0("Control (n=", n_sig_ctrl, ")"),
                 "NS" = paste0("NS (n=", n_ns, ")"))
    ) +
    labs(
      title = paste0("Volcano Plot: G>T ", title_suffix),
      subtitle = paste0("Total miRNAs: ", nrow(volcano_data), " | FDR < 0.05, |log₂FC| > 0.58"),
      x = "log₂(Fold Change) [ALS vs Control]",
      y = "-log₁₀(FDR p-value)",
      color = NULL
    ) +
    theme_prof
  
  # Agregar etiquetas si hay significativos
  if (nrow(top_labels) > 0) {
    fig <- fig +
      geom_text_repel(
        data = top_labels,
        aes(label = miRNA),
        size = 2.5,
        max.overlaps = 20,
        color = "black",
        box.padding = 0.5,
        segment.color = "gray60",
        segment.size = 0.3
      )
  }
  
  ggsave(paste0("figures_paso2_CLEAN/", filename), fig, 
         width = 10, height = 8, dpi = 300, bg = "white")
  
  return(volcano_data)
}

# ============================================================================
# VOLCANO 1: SEED ONLY (posiciones 2-8)
# ============================================================================

cat("🌋 GENERANDO VOLCANO 1: SEED ONLY (posiciones 2-8)\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

gt_seed <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^[0-9]+"))) %>%
  filter(position >= 2, position <= 8)

cat("Datos SEED:\n")
cat("   SNVs G>T en seed:", nrow(gt_seed), "\n")
cat("   miRNAs únicos:", length(unique(gt_seed$miRNA_name)), "\n\n")

volcano_seed <- generate_volcano(gt_seed, "in SEED Region (2-8)", "FIG_2.3_VOLCANO_SEED.png")

cat("   ✅ Volcano SEED guardado\n\n")

# ============================================================================
# VOLCANO 2: ALL POSITIONS
# ============================================================================

cat("🌋 GENERANDO VOLCANO 2: ALL POSITIONS (1-22)\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

gt_all <- data %>%
  filter(str_detect(pos.mut, ":GT$"))  # Solo G>T, todas las posiciones

cat("Datos ALL:\n")
cat("   SNVs G>T en total:", nrow(gt_all), "\n")
cat("   miRNAs únicos:", length(unique(gt_all$miRNA_name)), "\n\n")

volcano_all <- generate_volcano(gt_all, "in ALL Positions", "FIG_2.3_VOLCANO_ALL.png")

cat("   ✅ Volcano ALL guardado\n\n")

# ============================================================================
# COMPARACIÓN
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("📊 COMPARACIÓN: SEED vs ALL\n")
cat("\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")

comparison <- data.frame(
  Metric = c("miRNAs analizados", "Sig ALS", "Sig Control", "NS"),
  SEED = c(nrow(volcano_seed),
           sum(volcano_seed$Sig == "ALS"),
           sum(volcano_seed$Sig == "Control"),
           sum(volcano_seed$Sig == "NS")),
  ALL = c(nrow(volcano_all),
          sum(volcano_all$Sig == "ALS"),
          sum(volcano_all$Sig == "Control"),
          sum(volcano_all$Sig == "NS"))
)

print(comparison)
cat("\n")

# Dirección global
mean_seed <- mean(volcano_seed$log2FC)
mean_all <- mean(volcano_all$log2FC)

cat("DIRECCIÓN GLOBAL (media log2FC):\n")
cat("   SEED:", round(mean_seed, 4), ifelse(mean_seed > 0, "→ ALS", "→ Control"), "\n")
cat("   ALL:", round(mean_all, 4), ifelse(mean_all > 0, "→ ALS", "→ Control"), "\n\n")

# Proporción hacia Control
prop_ctrl_seed <- sum(volcano_seed$log2FC < 0) / nrow(volcano_seed) * 100
prop_ctrl_all <- sum(volcano_all$log2FC < 0) / nrow(volcano_all) * 100

cat("PROPORCIÓN DIRECCIÓN CONTROL:\n")
cat("   SEED:", round(prop_ctrl_seed, 1), "% de miRNAs\n")
cat("   ALL:", round(prop_ctrl_all, 1), "% de miRNAs\n\n")

# ============================================================================
# INTERPRETACIÓN
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("💡 INTERPRETACIÓN:\n")
cat("\n")

if (sum(volcano_seed$Sig != "NS") > 0 | sum(volcano_all$Sig != "NS") > 0) {
  cat("✅ HAY DIFERENCIAS:\n\n")
  
  if (sum(volcano_seed$Sig != "NS") > sum(volcano_all$Sig != "NS")) {
    cat("   → MÁS significativos en SEED que en ALL\n")
    cat("   → Efecto ESPECÍFICO del seed region\n")
    cat("   → G>T en seed es más diferencial entre grupos\n\n")
  } else if (sum(volcano_all$Sig != "NS") > sum(volcano_seed$Sig != "NS")) {
    cat("   → MÁS significativos en ALL que en SEED\n")
    cat("   → Efecto GLOBAL (no específico del seed)\n")
    cat("   → G>T fuera del seed también importa\n\n")
  } else {
    cat("   → MISMO número de significativos\n")
    cat("   → Efecto distribuido uniformemente\n\n")
  }
  
} else {
  cat("⚠️  NO HAY SIGNIFICATIVOS EN NINGUNO:\n\n")
  cat("   → Efecto distribuido en ambos casos\n")
  cat("   → No hay miRNAs focales ni en seed ni fuera\n\n")
  
  # Comparar tendencias
  if (abs(mean_seed) > abs(mean_all)) {
    cat("   PERO: Tendencia más fuerte en SEED\n")
    cat("      Media log2FC SEED (", round(mean_seed, 3), ") > ALL (", round(mean_all, 3), ")\n\n")
  } else if (abs(mean_all) > abs(mean_seed)) {
    cat("   PERO: Tendencia más fuerte en ALL\n")
    cat("      Media log2FC ALL (", round(mean_all, 3), ") > SEED (", round(mean_seed, 3), ")\n\n")
  }
}

cat("PREGUNTA RESPONDIDA:\n")
cat("   '¿El efecto de G>T es específico del SEED o es GLOBAL?'\n\n")

if (abs(mean_seed - mean_all) < 0.1 & abs(prop_ctrl_seed - prop_ctrl_all) < 10) {
  cat("   RESPUESTA: SIMILAR en ambos\n")
  cat("      → G>T en seed y no-seed se comportan igual\n")
  cat("      → No hay especificidad funcional del seed\n\n")
} else {
  cat("   RESPUESTA: DIFERENTE\n")
  if (abs(mean_seed) > abs(mean_all)) {
    cat("      → Efecto MÁS FUERTE en seed\n")
    cat("      → Sugiere relevancia funcional del seed\n\n")
  } else {
    cat("      → Efecto MÁS FUERTE fuera del seed\n")
    cat("      → Seed no es especialmente vulnerable\n\n")
  }
}

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")

# ============================================================================
# GENERAR FIGURA COMBINADA
# ============================================================================

cat("🎨 Generando figura combinada SEED vs ALL...\n\n")

# Preparar datos para combinación
volcano_seed_plot <- volcano_seed %>% mutate(Region = "SEED (2-8)")
volcano_all_plot <- volcano_all %>% mutate(Region = "ALL (1-22)")

combined_volcano <- rbind(volcano_seed_plot, volcano_all_plot)

# Top labels por región
top_seed <- volcano_seed %>% filter(Sig != "NS") %>% arrange(padj) %>% head(10) %>% mutate(Region = "SEED (2-8)")
top_all <- volcano_all %>% filter(Sig != "NS") %>% arrange(padj) %>% head(10) %>% mutate(Region = "ALL (1-22)")
top_combined <- rbind(top_seed, top_all)

theme_prof <- theme_classic(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 13, hjust = 0.5),
    plot.subtitle = element_text(size = 9, hjust = 0.5, color = "gray40"),
    axis.title = element_text(face = "bold", size = 10),
    axis.text = element_text(size = 9),
    legend.position = "bottom",
    legend.title = element_text(face = "bold", size = 9),
    panel.grid.major = element_line(color = "gray90", linewidth = 0.3),
    strip.background = element_rect(fill = "gray95", color = "gray80"),
    strip.text = element_text(face = "bold", size = 11)
  )

fig_combined <- ggplot(combined_volcano, aes(x = log2FC, y = neg_log10_padj, color = Sig)) +
  geom_point(alpha = 0.5, size = 1.8) +
  geom_hline(yintercept = -log10(0.05), linetype = "dashed", color = "gray50", linewidth = 0.5) +
  geom_vline(xintercept = c(-0.58, 0.58), linetype = "dashed", color = "gray50", linewidth = 0.5) +
  scale_color_manual(
    values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL, "NS" = COLOR_NS),
    labels = c("ALS" = "Elevated in ALS", "Control" = "Elevated in Control", "NS" = "Not Significant")
  ) +
  facet_wrap(~Region, ncol = 2) +
  labs(
    title = "Comparison: G>T in SEED vs ALL Positions",
    subtitle = "FDR < 0.05, |log₂FC| > 0.58",
    x = "log₂(Fold Change) [ALS vs Control]",
    y = "-log₁₀(FDR p-value)",
    color = "Significance"
  ) +
  theme_prof

# Etiquetas si hay
if (nrow(top_combined) > 0) {
  fig_combined <- fig_combined +
    geom_text_repel(
      data = top_combined,
      aes(label = miRNA),
      size = 2.5,
      max.overlaps = 15,
      color = "black",
      box.padding = 0.3,
      segment.size = 0.2
    )
}

ggsave("figures_paso2_CLEAN/FIG_2.3_VOLCANO_SEED_VS_ALL_COMBINED.png", 
       fig_combined, width = 14, height = 7, dpi = 300, bg = "white")

cat("   ✅ Figura combinada guardada\n\n")

# ============================================================================
# RESUMEN FINAL
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("✅ TRES VOLCANOS GENERADOS:\n")
cat("\n")
cat("   1. FIG_2.3_VOLCANO_SEED.png\n")
cat("      → Solo G>T en posiciones 2-8 (seed)\n")
cat("      → ", nrow(volcano_seed), "miRNAs\n")
cat("      → Significativos:", sum(volcano_seed$Sig != "NS"), "\n\n")

cat("   2. FIG_2.3_VOLCANO_ALL.png\n")
cat("      → G>T en TODAS las posiciones (1-22)\n")
cat("      → ", nrow(volcano_all), "miRNAs\n")
cat("      → Significativos:", sum(volcano_all$Sig != "NS"), "\n\n")

cat("   3. FIG_2.3_VOLCANO_SEED_VS_ALL_COMBINED.png\n")
cat("      → Comparación lado a lado\n")
cat("      → Facilita ver diferencias entre seed y all\n\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("📊 Abre las tres figuras para compararlas!\n")
cat("\n")

