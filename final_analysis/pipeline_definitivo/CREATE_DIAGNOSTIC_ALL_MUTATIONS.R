#!/usr/bin/env Rscript

# ============================================================================
# 🎯 FIGURAS DIAGNÓSTICAS: TODAS LAS MUTACIONES (No solo G>T)
# ============================================================================
# Objetivo: Contexto completo del dataset
# - Tipos de mutación por muestra (SNVs, counts, stats)
# - Tipos de mutación por posición (SNVs, counts, stats)

library(ggplot2)
library(dplyr)
library(tidyr)
library(patchwork)
library(tibble)

cat("╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║     🎯 ANÁLISIS DIAGNÓSTICO: TODAS LAS MUTACIONES                   ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

# ============================================================================
# 1. CARGAR DATOS ORIGINALES (con todas las mutaciones)
# ============================================================================

cat("📊 Cargando datos originales...\n")
data_path <- "/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/tercer_intento/step_by_step_analysis/step1_original_data.csv"

data <- read.csv(data_path, check.names = FALSE)

cat(sprintf("   ✅ Datos cargados: %d filas\n", nrow(data)))

# Extraer información
data_clean <- data %>%
  filter(`pos:mut` != "PM") %>%  # Eliminar filas PM
  mutate(
    miRNA = `miRNA name`,
    pos_mut = `pos:mut`,
    Position = as.numeric(gsub(":.*", "", pos_mut)),
    Mutation_Type = gsub(".*:", "", pos_mut),
    Mutation_Type = gsub('"', '', Mutation_Type),  # Limpiar comillas
    Region = ifelse(Position >= 2 & Position <= 8, "Seed", "Non-Seed")
  ) %>%
  filter(!is.na(Position), Mutation_Type != "")

cat(sprintf("   ✅ Filas limpias: %d\n", nrow(data_clean)))
cat(sprintf("   ✅ Tipos de mutación únicos: %d\n", length(unique(data_clean$Mutation_Type))))

# Ver distribución de tipos
cat("\n📊 DISTRIBUCIÓN DE TIPOS DE MUTACIÓN:\n")
type_dist <- data_clean %>%
  group_by(Mutation_Type) %>%
  summarise(N = n(), .groups = "drop") %>%
  arrange(desc(N))

print(head(type_dist, 15))

# Obtener nombres de muestras
sample_cols <- setdiff(names(data), c("miRNA name", "pos:mut"))
cat(sprintf("\n   ✅ Muestras: %d\n", length(sample_cols)))

# ============================================================================
# 2. PREPARAR DATOS POR MUESTRA Y TIPO
# ============================================================================

cat("\n📊 Preparando análisis por muestra...\n")

# Convertir a formato largo
data_long <- data_clean %>%
  select(miRNA, Position, Mutation_Type, Region, all_of(sample_cols)) %>%
  pivot_longer(
    cols = all_of(sample_cols),
    names_to = "Sample",
    values_to = "Count"
  ) %>%
  filter(!is.na(Count), Count > 0)

cat(sprintf("   ✅ Datos en formato largo: %d filas\n", nrow(data_long)))

# Métricas por muestra y tipo
sample_metrics <- data_long %>%
  group_by(Sample, Mutation_Type) %>%
  summarise(
    N_SNVs = n(),
    Total_Counts = sum(Count),
    Mean_Count = mean(Count),
    Median_Count = median(Count),
    SD_Count = sd(Count),
    Max_Count = max(Count),
    .groups = "drop"
  )

cat(sprintf("   ✅ Métricas por muestra: %d filas\n", nrow(sample_metrics)))

# ============================================================================
# 3. PREPARAR DATOS POR POSICIÓN Y TIPO
# ============================================================================

cat("\n📊 Preparando análisis por posición...\n")

# Métricas por posición y tipo
position_metrics <- data_long %>%
  group_by(Position, Mutation_Type) %>%
  summarise(
    N_SNVs = n(),
    Total_Counts = sum(Count),
    Mean_Count = mean(Count),
    SD_Count = sd(Count),
    Max_Count = max(Count),
    .groups = "drop"
  )

cat(sprintf("   ✅ Métricas por posición: %d filas\n", nrow(position_metrics)))

# ============================================================================
# 4. FIGURA 1: ANÁLISIS POR MUESTRA (SNVs y Counts)
# ============================================================================

cat("\n🎨 Generando FIGURA 1: Análisis por Muestra...\n")

# Destacar G>T
sample_metrics <- sample_metrics %>%
  mutate(
    Is_GT = ifelse(Mutation_Type == "GT", "G>T", "Otras"),
    Color_Group = ifelse(Mutation_Type == "GT", "#D62728", "#1F77B4")
  )

# Panel A: SNVs por muestra y tipo (boxplot)
top_types <- sample_metrics %>%
  group_by(Mutation_Type) %>%
  summarise(Total = sum(N_SNVs)) %>%
  arrange(desc(Total)) %>%
  slice(1:10) %>%
  pull(Mutation_Type)

sample_top <- sample_metrics %>% filter(Mutation_Type %in% top_types)

p1a <- ggplot(sample_top, aes(x = reorder(Mutation_Type, -N_SNVs), y = N_SNVs, fill = Is_GT)) +
  geom_boxplot(alpha = 0.8, outlier.size = 1) +
  scale_fill_manual(values = c("G>T" = "#D62728", "Otras" = "gray60"), name = "") +
  theme_classic(base_size = 12) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold"),
    axis.title = element_text(face = "bold"),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 13),
    legend.position = "top"
  ) +
  labs(
    title = "A. SNVs por Muestra (Top 10 Tipos)",
    x = "Tipo de Mutación",
    y = "N° SNVs por Muestra"
  )

# Panel B: Counts promedio por muestra y tipo
p1b <- ggplot(sample_top, aes(x = reorder(Mutation_Type, -Mean_Count), y = Mean_Count, fill = Is_GT)) +
  geom_boxplot(alpha = 0.8, outlier.size = 1) +
  scale_fill_manual(values = c("G>T" = "#D62728", "Otras" = "gray60"), name = "") +
  theme_classic(base_size = 12) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold"),
    axis.title = element_text(face = "bold"),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 13),
    legend.position = "top"
  ) +
  labs(
    title = "B. Counts Promedio por Muestra",
    x = "Tipo de Mutación",
    y = "Counts Promedio"
  )

# Panel C: Counts máximos
p1c <- ggplot(sample_top, aes(x = reorder(Mutation_Type, -Max_Count), y = Max_Count, fill = Is_GT)) +
  geom_boxplot(alpha = 0.8, outlier.size = 1) +
  scale_fill_manual(values = c("G>T" = "#D62728", "Otras" = "gray60"), name = "") +
  scale_y_log10() +
  theme_classic(base_size = 12) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold"),
    axis.title = element_text(face = "bold"),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 13),
    legend.position = "top"
  ) +
  labs(
    title = "C. Counts Máximos por Muestra (log scale)",
    x = "Tipo de Mutación",
    y = "Counts Máximo"
  )

# Combinar Figura 1
fig1 <- (p1a / p1b / p1c) +
  plot_annotation(
    title = "FIGURA 1: Análisis por Muestra - Todas las Mutaciones",
    subtitle = sprintf("Top 10 tipos de mutación más frecuentes | G>T destacado en rojo"),
    theme = theme(
      plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 11, hjust = 0.5, color = "gray40")
    )
  )

output_dir <- "/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/pipeline_definitivo/01_analisis_inicial/figures"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

ggsave(file.path(output_dir, "FIG1_TODAS_MUTACIONES_POR_MUESTRA.png"), 
       fig1, width = 14, height = 12, dpi = 150)
cat("   ✅ Guardado: FIG1_TODAS_MUTACIONES_POR_MUESTRA.png\n")

# ============================================================================
# 5. FIGURA 2: ANÁLISIS POR POSICIÓN
# ============================================================================

cat("\n🎨 Generando FIGURA 2: Análisis por Posición...\n")

# Panel A: SNVs por posición (top tipos)
position_top <- position_metrics %>% filter(Mutation_Type %in% top_types)

position_top <- position_top %>%
  mutate(Is_GT = ifelse(Mutation_Type == "GT", "G>T", "Otras"))

p2a <- ggplot(position_top, aes(x = factor(Position), y = N_SNVs, fill = Mutation_Type)) +
  geom_bar(stat = "identity", position = "dodge", alpha = 0.8) +
  scale_fill_manual(
    values = c("GT" = "#D62728", "TC" = "#1F77B4", "AG" = "#2CA02C",
               "GA" = "#FF7F0E", "CT" = "#9467BD", "TA" = "#8C564B",
               "TG" = "#E377C2", "AT" = "#7F7F7F", "AC" = "#BCBD22", "CA" = "#17BECF"),
    name = "Tipo"
  ) +
  theme_classic(base_size = 11) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    axis.title = element_text(face = "bold"),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 13),
    legend.position = "right"
  ) +
  labs(
    title = "A. SNVs por Posición (Top 10 Tipos)",
    x = "Posición",
    y = "N° SNVs"
  )

# Panel B: Counts totales por posición
p2b <- ggplot(position_top, aes(x = factor(Position), y = Total_Counts, fill = Mutation_Type)) +
  geom_bar(stat = "identity", position = "dodge", alpha = 0.8) +
  scale_fill_manual(
    values = c("GT" = "#D62728", "TC" = "#1F77B4", "AG" = "#2CA02C",
               "GA" = "#FF7F0E", "CT" = "#9467BD", "TA" = "#8C564B",
               "TG" = "#E377C2", "AT" = "#7F7F7F", "AC" = "#BCBD22", "CA" = "#17BECF"),
    name = "Tipo"
  ) +
  scale_y_log10() +
  theme_classic(base_size = 11) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    axis.title = element_text(face = "bold"),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 13),
    legend.position = "right"
  ) +
  labs(
    title = "B. Counts Totales por Posición (log scale)",
    x = "Posición",
    y = "Total Counts"
  )

# Panel C: Counts promedio por posición
p2c <- ggplot(position_top, aes(x = factor(Position), y = Mean_Count, fill = Mutation_Type)) +
  geom_bar(stat = "identity", position = "dodge", alpha = 0.8) +
  scale_fill_manual(
    values = c("GT" = "#D62728", "TC" = "#1F77B4", "AG" = "#2CA02C",
               "GA" = "#FF7F0E", "CT" = "#9467BD", "TA" = "#8C564B",
               "TG" = "#E377C2", "AT" = "#7F7F7F", "AC" = "#BCBD22", "CA" = "#17BECF"),
    name = "Tipo"
  ) +
  theme_classic(base_size = 11) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    axis.title = element_text(face = "bold"),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 13),
    legend.position = "right"
  ) +
  labs(
    title = "C. Counts Promedio por Posición",
    x = "Posición",
    y = "Counts Promedio"
  )

# Combinar Figura 2
fig2 <- (p2a / p2b / p2c) +
  plot_annotation(
    title = "FIGURA 2: Análisis por Posición - Todas las Mutaciones",
    subtitle = "Comparación de tipos de mutación a través de las posiciones | G>T en rojo",
    theme = theme(
      plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 11, hjust = 0.5, color = "gray40")
    )
  )

ggsave(file.path(output_dir, "FIG2_TODAS_MUTACIONES_POR_POSICION.png"), 
       fig2, width = 14, height = 13, dpi = 150)
cat("   ✅ Guardado: FIG2_TODAS_MUTACIONES_POR_POSICION.png\n")

# ============================================================================
# 6. FIGURA 3: ESPECIFICIDAD DE G>T
# ============================================================================

cat("\n🎨 Generando FIGURA 3: Especificidad de G>T...\n")

# Solo transversiones de G
g_transversions <- position_metrics %>%
  filter(Mutation_Type %in% c("GT", "GA", "GC")) %>%
  group_by(Position) %>%
  mutate(
    Total_G_SNVs = sum(N_SNVs),
    Fraction_SNVs = N_SNVs / Total_G_SNVs * 100,
    Total_G_Counts = sum(Total_Counts),
    Fraction_Counts = Total_Counts / Total_G_Counts * 100
  )

# Panel A: SNVs (G>T vs G>A vs G>C)
p3a <- ggplot(g_transversions, aes(x = factor(Position), y = N_SNVs, fill = Mutation_Type)) +
  geom_bar(stat = "identity", position = "dodge", alpha = 0.85) +
  scale_fill_manual(
    values = c("GT" = "#D62728", "GA" = "#1F77B4", "GC" = "#2CA02C"),
    labels = c("GT" = "G>T (Oxidación)", "GA" = "G>A", "GC" = "G>C"),
    name = "Transversión"
  ) +
  theme_classic(base_size = 12) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    axis.title = element_text(face = "bold"),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 13),
    legend.position = "bottom"
  ) +
  labs(
    title = "A. Comparación: G>T vs G>A vs G>C (SNVs)",
    x = "Posición",
    y = "N° SNVs"
  )

# Panel B: % de SNVs que son G>T
gt_fraction_snvs <- g_transversions %>% filter(Mutation_Type == "GT")

p3b <- ggplot(gt_fraction_snvs, aes(x = Position, y = Fraction_SNVs)) +
  geom_bar(stat = "identity", fill = "#D62728", alpha = 0.8) +
  geom_hline(yintercept = 50, linetype = "dashed", color = "gray40", size = 1) +
  geom_hline(yintercept = 70, linetype = "dashed", color = "gray60", size = 0.8) +
  annotate("text", x = 20, y = 53, label = "50%", color = "gray40", size = 4) +
  annotate("text", x = 20, y = 73, label = "70%", color = "gray60", size = 3.5) +
  theme_classic(base_size = 12) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    axis.title = element_text(face = "bold"),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 13)
  ) +
  labs(
    title = "B. % G>T del Total de Transversiones de G (SNVs)",
    x = "Posición",
    y = "% G>T"
  ) +
  ylim(0, 100)

# Panel C: Counts (G>T vs otros)
p3c <- ggplot(g_transversions, aes(x = factor(Position), y = Total_Counts, fill = Mutation_Type)) +
  geom_bar(stat = "identity", position = "dodge", alpha = 0.85) +
  scale_fill_manual(
    values = c("GT" = "#D62728", "GA" = "#1F77B4", "GC" = "#2CA02C"),
    labels = c("GT" = "G>T (Oxidación)", "GA" = "G>A", "GC" = "G>C"),
    name = "Transversión"
  ) +
  scale_y_log10() +
  theme_classic(base_size = 12) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    axis.title = element_text(face = "bold"),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 13),
    legend.position = "bottom"
  ) +
  labs(
    title = "C. Comparación: G>T vs G>A vs G>C (Counts, log scale)",
    x = "Posición",
    y = "Total Counts"
  )

# Combinar Figura 3
fig3 <- (p3a / p3b / p3c) +
  plot_annotation(
    title = "FIGURA 3: Especificidad de G>T (Firma Oxidativa)",
    subtitle = "Validación de G>T como mutación predominante en transversiones de G",
    theme = theme(
      plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 11, hjust = 0.5, color = "gray40")
    )
  )

ggsave(file.path(output_dir, "FIG3_ESPECIFICIDAD_GT.png"), 
       fig3, width = 14, height = 13, dpi = 150)
cat("   ✅ Guardado: FIG3_ESPECIFICIDAD_GT.png\n")

# ============================================================================
# 7. GUARDAR TABLAS RESUMEN
# ============================================================================

cat("\n💾 Guardando tablas resumen...\n")

write.csv(sample_metrics, 
          file.path(output_dir, "../tables/ALL_MUTATIONS_sample_metrics.csv"), 
          row.names = FALSE)

write.csv(position_metrics, 
          file.path(output_dir, "../tables/ALL_MUTATIONS_position_metrics.csv"), 
          row.names = FALSE)

write.csv(type_dist, 
          file.path(output_dir, "../tables/ALL_MUTATIONS_type_distribution.csv"), 
          row.names = FALSE)

cat("   ✅ ALL_MUTATIONS_sample_metrics.csv\n")
cat("   ✅ ALL_MUTATIONS_position_metrics.csv\n")
cat("   ✅ ALL_MUTATIONS_type_distribution.csv\n")

# ============================================================================
# 8. RESUMEN FINAL
# ============================================================================

cat("\n╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║          ✅ ANÁLISIS DE TODAS LAS MUTACIONES COMPLETADO             ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

cat("📊 FIGURAS GENERADAS:\n")
cat("   • FIG1_TODAS_MUTACIONES_POR_MUESTRA.png (3 paneles)\n")
cat("   • FIG2_TODAS_MUTACIONES_POR_POSICION.png (3 paneles)\n")
cat("   • FIG3_ESPECIFICIDAD_GT.png (3 paneles)\n\n")

cat("📊 ESTADÍSTICAS CLAVE:\n")
cat(sprintf("   • Tipos de mutación: %d\n", nrow(type_dist)))
cat(sprintf("   • Top tipo: %s (%d SNVs)\n", type_dist$Mutation_Type[1], type_dist$N[1]))
cat(sprintf("   • G>T rank: #%d\n", which(type_dist$Mutation_Type == "GT")))

# Calcular % G>T del total
gt_pct <- (type_dist %>% filter(Mutation_Type == "GT") %>% pull(N)) / sum(type_dist$N) * 100
cat(sprintf("   • G>T del total: %.1f%%\n", gt_pct))

# Calcular % G>T de transversiones de G
g_trans_total <- type_dist %>% filter(Mutation_Type %in% c("GT", "GA", "GC")) %>% pull(N) %>% sum()
gt_of_g <- (type_dist %>% filter(Mutation_Type == "GT") %>% pull(N)) / g_trans_total * 100
cat(sprintf("   • G>T de transversiones de G: %.1f%%\n\n", gt_of_g))

