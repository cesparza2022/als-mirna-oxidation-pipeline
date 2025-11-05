#!/usr/bin/env Rscript

# ============================================================================
# 🎯 FIGURAS DIAGNÓSTICAS CRÍTICAS DEL PASO 1
# ============================================================================
# Objetivo: Caracterización completa del dataset
# - SNVs vs Counts por muestra y tipo
# - SNVs vs Counts por posición y tipo
# - G-content y especificidad de G>T

library(ggplot2)
library(dplyr)
library(tidyr)
library(patchwork)
library(tibble)

setwd("/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/pipeline_definitivo/01_analisis_inicial")

cat("╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║          🎯 FIGURAS DIAGNÓSTICAS CRÍTICAS - PASO 1                  ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

# ============================================================================
# 1. CARGAR Y PREPARAR DATOS
# ============================================================================

cat("📊 Cargando datos...\n")
data <- read.csv("tables/mutaciones_gt_detalladas.csv")

# Extraer información clave
data_clean <- data %>%
  mutate(
    miRNA = `miRNA.name`,
    Position = as.numeric(gsub(":.*", "", pos.mut)),
    Mutation_Type = gsub(".*:", "", pos.mut),
    Region = ifelse(Position >= 2 & Position <= 8, "Seed", "Non-Seed")
  )

# Obtener nombres de muestras (todas las columnas que no son miRNA/pos/mut)
sample_cols <- setdiff(names(data), c("miRNA.name", "pos.mut", "position", "region"))

cat(sprintf("   ✅ Datos: %d filas\n", nrow(data_clean)))
cat(sprintf("   ✅ Muestras: %d\n", length(sample_cols)))
cat(sprintf("   ✅ Tipos de mutación: %d\n", length(unique(data_clean$Mutation_Type))))

# ============================================================================
# 2. PREPARAR DATOS POR MUESTRA
# ============================================================================

cat("\n📊 Preparando datos por muestra...\n")

# Convertir a formato largo para análisis por muestra
data_long <- data_clean %>%
  select(miRNA, Position, Mutation_Type, Region, all_of(sample_cols)) %>%
  pivot_longer(
    cols = all_of(sample_cols),
    names_to = "Sample",
    values_to = "Count"
  ) %>%
  filter(!is.na(Count), Count > 0)

# Calcular métricas por muestra y tipo
sample_metrics <- data_long %>%
  group_by(Sample, Mutation_Type) %>%
  summarise(
    N_SNVs = n(),
    Total_Counts = sum(Count),
    Mean_Count = mean(Count),
    Median_Count = median(Count),
    .groups = "drop"
  )

cat(sprintf("   ✅ Métricas calculadas: %d filas (muestra x tipo)\n", nrow(sample_metrics)))

# ============================================================================
# 3. PREPARAR DATOS POR POSICIÓN
# ============================================================================

cat("\n📊 Preparando datos por posición...\n")

# Métricas por posición y tipo
position_metrics <- data_long %>%
  group_by(Position, Mutation_Type) %>%
  summarise(
    N_SNVs = n(),
    Total_Counts = sum(Count),
    Mean_Count = mean(Count),
    .groups = "drop"
  )

cat(sprintf("   ✅ Métricas calculadas: %d filas (posición x tipo)\n", nrow(position_metrics)))

# ============================================================================
# 4. FIGURA 1: ANÁLISIS POR MUESTRA
# ============================================================================

cat("\n🎨 Generando Figura 1: Análisis por Muestra...\n")

# Panel A: SNVs por muestra y tipo
p1a <- ggplot(sample_metrics, aes(x = Mutation_Type, y = N_SNVs, fill = Mutation_Type)) +
  geom_boxplot(alpha = 0.8, outlier.alpha = 0.5) +
  scale_fill_manual(
    values = c("GT" = "#D62728", "GA" = "#1F77B4", "GC" = "#2CA02C", 
               "AT" = "#FF7F0E", "AC" = "#9467BD", "CT" = "#8C564B", 
               "CA" = "#E377C2", "TA" = "#7F7F7F", "TC" = "#BCBD22", "TG" = "#17BECF"),
    breaks = c("GT", "GA", "GC", "AT", "AC", "CT", "CA", "TA", "TC", "TG")
  ) +
  theme_classic(base_size = 14) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold"),
    axis.title = element_text(face = "bold"),
    legend.position = "none",
    plot.title = element_text(face = "bold", hjust = 0.5)
  ) +
  labs(
    title = "A. SNVs por Muestra",
    x = "Tipo de Mutación",
    y = "N° SNVs por Muestra"
  )

# Panel B: Counts promedio por muestra y tipo
p1b <- ggplot(sample_metrics, aes(x = Mutation_Type, y = Mean_Count, fill = Mutation_Type)) +
  geom_boxplot(alpha = 0.8, outlier.alpha = 0.5) +
  scale_fill_manual(
    values = c("GT" = "#D62728", "GA" = "#1F77B4", "GC" = "#2CA02C", 
               "AT" = "#FF7F0E", "AC" = "#9467BD", "CT" = "#8C564B", 
               "CA" = "#E377C2", "TA" = "#7F7F7F", "TC" = "#BCBD22", "TG" = "#17BECF"),
    breaks = c("GT", "GA", "GC", "AT", "AC", "CT", "CA", "TA", "TC", "TG")
  ) +
  theme_classic(base_size = 14) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold"),
    axis.title = element_text(face = "bold"),
    legend.position = "none",
    plot.title = element_text(face = "bold", hjust = 0.5)
  ) +
  labs(
    title = "B. Counts Promedio por Muestra",
    x = "Tipo de Mutación",
    y = "Counts Promedio"
  )

# Panel C: Relación SNVs vs Total Counts
sample_totals <- sample_metrics %>%
  group_by(Sample) %>%
  summarise(
    Total_SNVs = sum(N_SNVs),
    Total_Counts_Sum = sum(Total_Counts),
    .groups = "drop"
  )

# Agregar proporción de G>T
sample_gt_fraction <- sample_metrics %>%
  filter(Mutation_Type == "GT") %>%
  select(Sample, GT_SNVs = N_SNVs) %>%
  right_join(sample_totals, by = "Sample") %>%
  mutate(
    GT_SNVs = replace_na(GT_SNVs, 0),
    GT_Fraction = GT_SNVs / Total_SNVs
  )

p1c <- ggplot(sample_gt_fraction, aes(x = Total_SNVs, y = Total_Counts_Sum, color = GT_Fraction)) +
  geom_point(alpha = 0.7, size = 3) +
  scale_color_gradient2(
    low = "#1F77B4", mid = "#FF7F0E", high = "#D62728",
    midpoint = 0.5,
    name = "Fracción\nG>T"
  ) +
  geom_smooth(method = "lm", se = TRUE, color = "gray30", linetype = "dashed") +
  theme_classic(base_size = 14) +
  theme(
    axis.title = element_text(face = "bold"),
    plot.title = element_text(face = "bold", hjust = 0.5),
    legend.position = "right"
  ) +
  labs(
    title = "C. Relación SNVs vs Counts por Muestra",
    x = "Total SNVs",
    y = "Total Counts"
  )

# Combinar Figura 1
fig1 <- (p1a | p1b) / p1c +
  plot_annotation(
    title = "FIGURA 1: Análisis por Muestra (SNVs y Counts por Tipo)",
    theme = theme(plot.title = element_text(size = 18, face = "bold", hjust = 0.5))
  )

ggsave("figures/FIG1_ANALISIS_POR_MUESTRA.png", fig1, width = 14, height = 10, dpi = 150)
cat("   ✅ Guardado: FIG1_ANALISIS_POR_MUESTRA.png\n")

# ============================================================================
# 5. FIGURA 2: ANÁLISIS POR POSICIÓN
# ============================================================================

cat("\n🎨 Generando Figura 2: Análisis por Posición...\n")

# Panel A: SNVs por posición (stacked bar)
p2a <- ggplot(position_metrics, aes(x = factor(Position), y = N_SNVs, fill = Mutation_Type)) +
  geom_bar(stat = "identity", position = "stack") +
  scale_fill_manual(
    values = c("GT" = "#D62728", "GA" = "#1F77B4", "GC" = "#2CA02C", 
               "AT" = "#FF7F0E", "AC" = "#9467BD", "CT" = "#8C564B", 
               "CA" = "#E377C2", "TA" = "#7F7F7F", "TC" = "#BCBD22", "TG" = "#17BECF"),
    name = "Tipo"
  ) +
  theme_classic(base_size = 12) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    axis.title = element_text(face = "bold"),
    plot.title = element_text(face = "bold", hjust = 0.5),
    legend.position = "right"
  ) +
  labs(
    title = "A. SNVs por Posición",
    x = "Posición",
    y = "N° SNVs"
  )

# Panel B: Counts por posición (stacked bar)
p2b <- ggplot(position_metrics, aes(x = factor(Position), y = Total_Counts, fill = Mutation_Type)) +
  geom_bar(stat = "identity", position = "stack") +
  scale_fill_manual(
    values = c("GT" = "#D62728", "GA" = "#1F77B4", "GC" = "#2CA02C", 
               "AT" = "#FF7F0E", "AC" = "#9467BD", "CT" = "#8C564B", 
               "CA" = "#E377C2", "TA" = "#7F7F7F", "TC" = "#BCBD22", "TG" = "#17BECF"),
    name = "Tipo"
  ) +
  theme_classic(base_size = 12) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    axis.title = element_text(face = "bold"),
    plot.title = element_text(face = "bold", hjust = 0.5),
    legend.position = "right"
  ) +
  labs(
    title = "B. Counts Totales por Posición",
    x = "Posición",
    y = "Total Counts"
  )

# Panel C: Fracción de G>T por posición
position_fractions <- position_metrics %>%
  group_by(Position) %>%
  mutate(
    Total_SNVs_Pos = sum(N_SNVs),
    Fraction = N_SNVs / Total_SNVs_Pos
  ) %>%
  filter(Mutation_Type == "GT")

p2c <- ggplot(position_fractions, aes(x = Position, y = Fraction * 100)) +
  geom_line(color = "#D62728", size = 1.5) +
  geom_point(color = "#D62728", size = 3) +
  geom_ribbon(aes(ymin = 0, ymax = Fraction * 100), fill = "#D62728", alpha = 0.2) +
  geom_hline(yintercept = 50, linetype = "dashed", color = "gray40") +
  annotate("text", x = 20, y = 55, label = "50% threshold", color = "gray40", size = 4) +
  theme_classic(base_size = 12) +
  theme(
    axis.title = element_text(face = "bold"),
    plot.title = element_text(face = "bold", hjust = 0.5)
  ) +
  labs(
    title = "C. Fracción de G>T por Posición",
    x = "Posición",
    y = "% G>T (del total en esa posición)"
  ) +
  ylim(0, 100)

# Combinar Figura 2
fig2 <- p2a / p2b / p2c +
  plot_annotation(
    title = "FIGURA 2: Análisis por Posición (SNVs y Counts por Tipo)",
    theme = theme(plot.title = element_text(size = 18, face = "bold", hjust = 0.5))
  )

ggsave("figures/FIG2_ANALISIS_POR_POSICION.png", fig2, width = 14, height = 12, dpi = 150)
cat("   ✅ Guardado: FIG2_ANALISIS_POR_POSICION.png\n")

# ============================================================================
# 6. FIGURA 3: G-CONTENT Y ESPECIFICIDAD
# ============================================================================

cat("\n🎨 Generando Figura 3: G-content y Especificidad...\n")

# Necesitamos calcular el número de Gs por posición
# Esto requiere las secuencias completas de los miRNAs
# Por ahora, vamos a estimar basándonos en los datos disponibles

# Panel A: Total de mutaciones de G por posición (aproximación al G-content)
g_mutations <- position_metrics %>%
  filter(Mutation_Type %in% c("GT", "GA", "GC")) %>%
  group_by(Position) %>%
  summarise(
    Total_G_Mutations = sum(N_SNVs),
    .groups = "drop"
  )

p3a <- ggplot(g_mutations, aes(x = factor(Position), y = Total_G_Mutations)) +
  geom_bar(stat = "identity", fill = "#667eea", alpha = 0.8) +
  theme_classic(base_size = 12) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    axis.title = element_text(face = "bold"),
    plot.title = element_text(face = "bold", hjust = 0.5)
  ) +
  labs(
    title = "A. Mutaciones de G por Posición",
    subtitle = "Aproximación al G-content (G>T + G>A + G>C)",
    x = "Posición",
    y = "Total Mutaciones de G"
  )

# Panel B: Especificidad de transversiones de G
g_transversions <- position_metrics %>%
  filter(Mutation_Type %in% c("GT", "GA", "GC")) %>%
  group_by(Position) %>%
  mutate(
    Total_G = sum(N_SNVs),
    Fraction = N_SNVs / Total_G * 100
  )

p3b <- ggplot(g_transversions, aes(x = factor(Position), y = N_SNVs, fill = Mutation_Type)) +
  geom_bar(stat = "identity", position = "dodge") +
  scale_fill_manual(
    values = c("GT" = "#D62728", "GA" = "#1F77B4", "GC" = "#2CA02C"),
    labels = c("GT" = "G>T (Oxidación)", "GA" = "G>A", "GC" = "G>C"),
    name = "Transversión"
  ) +
  theme_classic(base_size = 12) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    axis.title = element_text(face = "bold"),
    plot.title = element_text(face = "bold", hjust = 0.5),
    legend.position = "bottom"
  ) +
  labs(
    title = "B. Especificidad: G>T vs G>A vs G>C (SNVs)",
    x = "Posición",
    y = "N° SNVs"
  )

# Panel C: Proporción de G>T del total de transversiones de G
p3c <- ggplot(g_transversions %>% filter(Mutation_Type == "GT"), 
              aes(x = factor(Position), y = Fraction)) +
  geom_bar(stat = "identity", fill = "#D62728", alpha = 0.8) +
  geom_hline(yintercept = 50, linetype = "dashed", color = "gray40") +
  geom_hline(yintercept = 70, linetype = "dashed", color = "gray60") +
  annotate("text", x = 20, y = 53, label = "50%", color = "gray40", size = 3.5) +
  annotate("text", x = 20, y = 73, label = "70%", color = "gray60", size = 3.5) +
  theme_classic(base_size = 12) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    axis.title = element_text(face = "bold"),
    plot.title = element_text(face = "bold", hjust = 0.5)
  ) +
  labs(
    title = "C. % G>T del Total de Transversiones de G",
    x = "Posición",
    y = "% G>T (de G>T + G>A + G>C)"
  ) +
  ylim(0, 100)

# Combinar Figura 3
fig3 <- p3a / p3b / p3c +
  plot_annotation(
    title = "FIGURA 3: G-content y Especificidad de G>T",
    theme = theme(plot.title = element_text(size = 18, face = "bold", hjust = 0.5))
  )

ggsave("figures/FIG3_GCONTENT_Y_ESPECIFICIDAD.png", fig3, width = 14, height = 12, dpi = 150)
cat("   ✅ Guardado: FIG3_GCONTENT_Y_ESPECIFICIDAD.png\n")

# ============================================================================
# 7. GUARDAR TABLAS DE RESUMEN
# ============================================================================

cat("\n💾 Guardando tablas de resumen...\n")

write.csv(sample_metrics, "tables/DIAGNOSTIC_sample_metrics.csv", row.names = FALSE)
write.csv(position_metrics, "tables/DIAGNOSTIC_position_metrics.csv", row.names = FALSE)
write.csv(g_transversions, "tables/DIAGNOSTIC_g_transversions.csv", row.names = FALSE)

cat("   ✅ DIAGNOSTIC_sample_metrics.csv\n")
cat("   ✅ DIAGNOSTIC_position_metrics.csv\n")
cat("   ✅ DIAGNOSTIC_g_transversions.csv\n")

# ============================================================================
# 8. RESUMEN FINAL
# ============================================================================

cat("\n╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║          ✅ FIGURAS DIAGNÓSTICAS COMPLETADAS                         ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

cat("📊 FIGURAS GENERADAS:\n")
cat("   • FIG1_ANALISIS_POR_MUESTRA.png (3 paneles)\n")
cat("   • FIG2_ANALISIS_POR_POSICION.png (3 paneles)\n")
cat("   • FIG3_GCONTENT_Y_ESPECIFICIDAD.png (3 paneles)\n\n")

cat("📊 TABLAS GENERADAS:\n")
cat("   • DIAGNOSTIC_sample_metrics.csv\n")
cat("   • DIAGNOSTIC_position_metrics.csv\n")
cat("   • DIAGNOSTIC_g_transversions.csv\n\n")

cat("🎯 PREGUNTAS RESPONDIDAS:\n")
cat("   ✅ ¿Cuántos SNVs y counts por muestra?\n")
cat("   ✅ ¿G>T es el tipo más frecuente por muestra?\n")
cat("   ✅ ¿Relación entre SNVs y counts?\n")
cat("   ✅ ¿Distribución de tipos por posición?\n")
cat("   ✅ ¿G>T domina en todas las posiciones?\n")
cat("   ✅ ¿Especificidad de G>T vs G>A y G>C?\n\n")

