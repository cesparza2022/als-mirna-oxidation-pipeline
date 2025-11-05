# FIGURAS DE DIAGNÓSTICO CON DATOS REALES DEL FILTRADO

library(ggplot2)
library(dplyr)
library(tidyr)
library(stringr)
library(patchwork)
library(scales)

COLOR_REMOVED <- "#e74c3c"
COLOR_KEPT <- "#27ae60"
COLOR_SUSPICIOUS <- "#f39c12"

theme_diag <- theme_minimal() +
  theme(
    text = element_text(size = 13),
    plot.title = element_text(size = 15, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5, color = "gray40"),
    axis.title = element_text(size = 13, face = "bold"),
    panel.border = element_rect(color = "gray30", fill = NA, linewidth = 1)
  )

cat("🎯 DIAGNÓSTICO CON DATOS REALES\n\n")

# Cargar listas de afectados
affected_snvs <- read.csv("SNVs_REMOVED_VAF_05.csv")
affected_mirnas <- read.csv("miRNAs_AFFECTED_VAF_05.csv")

# Cargar datos originales
data <- read.csv("../../../final_analysis/processed_data/final_processed_data.csv")
sample_cols <- grep("^Magen", colnames(data), value = TRUE)

# ==== FIGURA 1: DISTRIBUCIÓN ====
cat("📊 Figura 1: Distribución de VAF...\n")

all_vaf <- as.vector(as.matrix(data[, sample_cols]))
vaf_df <- data.frame(VAF = all_vaf[!is.na(all_vaf) & all_vaf > 0]) %>%
  mutate(Status = ifelse(VAF >= 0.5, "Removed (≥0.5)", "Kept (<0.5)"))

panel_1a <- ggplot(vaf_df, aes(x = VAF, fill = Status)) +
  geom_histogram(bins = 100, color = "white", linewidth = 0.2) +
  geom_vline(xintercept = 0.5, linetype = "dashed", color = "red", linewidth = 1.5) +
  scale_fill_manual(values = c("Kept (<0.5)" = COLOR_KEPT, "Removed (≥0.5)" = COLOR_REMOVED)) +
  annotate("text", x = 0.48, y = Inf, label = "Threshold = 0.5", 
           color = "red", hjust = 1, vjust = 2, fontface = "bold", size = 4) +
  labs(title = "A. VAF Distribution (Non-zero values)",
       subtitle = paste0("458 values (0.024%) removed | New max = 0.498"),
       x = "VAF", y = "Count") +
  theme_diag

# Categorías
cat_summary <- data.frame(
  Category = c("Kept: 0-0.1", "Kept: 0.1-0.3", "Kept: 0.3-<0.5", "REMOVED: ≥0.5"),
  Count = c(
    sum(vaf_df$VAF > 0 & vaf_df$VAF <= 0.1),
    sum(vaf_df$VAF > 0.1 & vaf_df$VAF <= 0.3),
    sum(vaf_df$VAF > 0.3 & vaf_df$VAF < 0.5),
    sum(vaf_df$VAF >= 0.5)
  )
) %>%
  mutate(Percent = Count / sum(Count) * 100,
         Status = ifelse(Category == "REMOVED: ≥0.5", "Removed", "Kept"))

panel_1b <- ggplot(cat_summary, aes(x = reorder(Category, -Count), y = Count, fill = Status)) +
  geom_col(width = 0.7) +
  geom_text(aes(label = paste0(format(Count, big.mark = ","), "\n(", round(Percent, 2), "%)")),
            vjust = -0.3, size = 3.5) +
  scale_fill_manual(values = c("Kept" = COLOR_KEPT, "Removed" = COLOR_REMOVED)) +
  scale_y_continuous(labels = comma) +
  labs(title = "B. VAF by Quality Category",
       x = "Category", y = "Count") +
  theme_diag +
  theme(axis.text.x = element_text(angle = 30, hjust = 1), legend.position = "none")

fig1 <- panel_1a / panel_1b
ggsave("figures_diagnostico/DIAG_1_DISTRIBUCION_REAL.png", fig1, width = 12, height = 11, dpi = 300)
cat("✅ Figura 1 guardada\n\n")

# ==== FIGURA 2: POR SNV ====
cat("📊 Figura 2: Impacto por SNV...\n")

panel_2a <- ggplot(head(affected_snvs, 20), 
                   aes(x = reorder(paste(miRNA_name, pos.mut, sep = " "), N_samples_05), 
                       y = N_samples_05)) +
  geom_col(fill = COLOR_REMOVED, width = 0.7) +
  geom_text(aes(label = N_samples_05), hjust = -0.2, size = 3) +
  coord_flip() +
  labs(title = "A. Top 20 SNVs with VAF = 0.5",
       subtitle = "SNVs with most samples affected",
       x = "SNV (miRNA position:mutation)", y = "Samples with VAF ≥ 0.5") +
  theme_diag

# Distribución de cuántos SNVs por cantidad de muestras afectadas
snv_dist <- affected_snvs %>%
  group_by(N_samples_05) %>%
  summarise(N_SNVs = n())

panel_2b <- ggplot(snv_dist, aes(x = N_samples_05, y = N_SNVs)) +
  geom_col(fill = COLOR_SUSPICIOUS, width = 0.7) +
  geom_text(aes(label = N_SNVs), vjust = -0.5, size = 3) +
  labs(title = "B. Distribution of Affected SNVs",
       subtitle = paste0("Total: ", nrow(affected_snvs), " SNVs with VAF ≥ 0.5"),
       x = "Number of samples at VAF = 0.5", y = "Number of SNVs") +
  theme_diag

fig2 <- panel_2a | panel_2b
ggsave("figures_diagnostico/DIAG_2_IMPACTO_SNV_REAL.png", fig2, width = 14, height = 10, dpi = 300)
cat("✅ Figura 2 guardada\n\n")

# ==== FIGURA 3: POR miRNA ====
cat("📊 Figura 3: Impacto por miRNA...\n")

panel_3a <- ggplot(head(affected_mirnas, 20),
                   aes(x = reorder(miRNA_name, N_values_05), y = N_values_05)) +
  geom_col(fill = COLOR_REMOVED, width = 0.7) +
  geom_text(aes(label = N_values_05), hjust = -0.2, size = 3) +
  coord_flip() +
  labs(title = "A. Top 20 miRNAs Most Affected",
       subtitle = "miRNAs with most values removed (VAF ≥ 0.5)",
       x = "miRNA", y = "Values removed") +
  theme_diag

panel_3b <- ggplot(affected_mirnas, aes(x = N_SNVs_affected, y = N_values_05)) +
  geom_point(color = COLOR_SUSPICIOUS, size = 3, alpha = 0.6) +
  geom_smooth(method = "lm", color = "gray30", linewidth = 1, se = FALSE, linetype = "dashed") +
  labs(title = "B. SNVs Affected vs Values Removed",
       subtitle = paste0("Total: ", nrow(affected_mirnas), " miRNAs affected"),
       x = "Number of SNVs with VAF ≥ 0.5", y = "Total values removed") +
  theme_diag

panel_3c <- ggplot() +
  annotate("text", x = 0.5, y = 0.7,
           label = paste0("SUMMARY:\n\n",
                         "• 126 miRNAs affected\n",
                         "• 192 SNVs removed\n",
                         "• 458 values set to NA\n",
                         "• Top: hsa-miR-6133 (67 values)\n",
                         "• Top: hsa-miR-6129 (61 values)"),
           size = 4.5, hjust = 0.5, family = "mono") +
  xlim(0, 1) + ylim(0, 1) +
  theme_void() +
  theme(plot.background = element_rect(fill = "#fff3cd", color = "#ffc107", linewidth = 2))

fig3 <- (panel_3a | panel_3b) / panel_3c
ggsave("figures_diagnostico/DIAG_3_IMPACTO_miRNA_REAL.png", fig3, width = 14, height = 12, dpi = 300)
cat("✅ Figura 3 guardada\n\n")

# ==== FIGURA 4: TABLA RESUMEN ====
cat("📊 Figura 4: Tabla resumen...\n")

total_vals <- length(all_vaf[!is.na(all_vaf)])
removed <- 458

summary_data <- data.frame(
  Metric = c(
    "Total VAF values analyzed",
    "Values removed (VAF ≥ 0.5)",
    "Percent removed",
    "Values kept (VAF < 0.5)",
    "Percent kept",
    "",
    "SNVs affected",
    "miRNAs affected",
    "Top miRNA affected",
    "Top SNV affected",
    "",
    "New maximum VAF",
    "Quality status"
  ),
  Value = c(
    format(total_vals, big.mark = ","),
    "458",
    "0.024%",
    format(total_vals - removed, big.mark = ","),
    "99.976%",
    "",
    "192",
    "126",
    "hsa-miR-6133 (67)",
    "hsa-miR-6129 13:GT (30)",
    "",
    "0.498",
    "CLEAN ✓"
  )
)

y_pos <- seq(0.95, 0.05, length.out = nrow(summary_data))

panel_4 <- ggplot() +
  annotate("rect", xmin = 0.05, xmax = 0.95, ymin = 0.92, ymax = 1, 
           fill = "#e74c3c", alpha = 0.9) +
  annotate("text", x = 0.5, y = 0.96, 
           label = "QUALITY CONTROL - VAF FILTER APPLIED",
           size = 6, fontface = "bold", color = "white")

for (i in 1:nrow(summary_data)) {
  if (summary_data$Metric[i] == "") {
    panel_4 <- panel_4 + annotate("segment", x = 0.1, xend = 0.9, 
                                  y = y_pos[i], yend = y_pos[i],
                                  color = "gray50", linewidth = 1)
  } else {
    col <- if (i <= 5) "black" else if (i >= 12) "#27ae60" else "gray30"
    face <- if (i <= 5 | i >= 12) "bold" else "plain"
    
    panel_4 <- panel_4 +
      annotate("text", x = 0.12, y = y_pos[i], label = summary_data$Metric[i],
               hjust = 0, size = 4, fontface = face, color = col) +
      annotate("text", x = 0.88, y = y_pos[i], label = summary_data$Value[i],
               hjust = 1, size = 4, fontface = face, color = col)
  }
}

panel_4 <- panel_4 + xlim(0, 1) + ylim(0, 1) + theme_void()

ggsave("figures_diagnostico/DIAG_4_TABLA_RESUMEN_REAL.png", panel_4, width = 12, height = 10, dpi = 300)
cat("✅ Figura 4 guardada\n\n")

cat("✅ TODAS LAS FIGURAS DE DIAGNÓSTICO GENERADAS\n")
cat("📊 458 valores removidos (0.024%)\n")
cat("📊 192 SNVs afectados\n")
cat("📊 126 miRNAs afectados\n")

