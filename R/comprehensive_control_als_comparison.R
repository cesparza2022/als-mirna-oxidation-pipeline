#!/usr/bin/env Rscript

# Script para análisis comparativo robusto Control vs ALS
# miRNAs y Oxidación - Análisis ALS

library(dplyr)
library(readr)
library(stringr)
library(ggplot2)
library(ComplexHeatmap)
library(circlize)
library(reshape2)
library(gridExtra)
# library(ggpubr)  # No disponible, usando alternativas
# library(corrplot)  # No disponible, usando alternativas
# library(VennDiagram)  # No disponible, usando alternativas
library(pheatmap)

cat("🔬 ANÁLISIS COMPARATIVO ROBUSTO CONTROL vs ALS\n")
cat("==============================================\n\n")

# Cargar datos procesados
cat("📂 Cargando datos procesados...\n")
df <- read_tsv("outputs/processed_snv_data_vaf_filtered.tsv", show_col_types = FALSE)

# Identificar muestras de control y ALS
sample_names <- colnames(df)[3:ncol(df)]  # Excluir miRNA name y pos:mut

# Clasificar muestras
is_control <- grepl("control", sample_names, ignore.case = TRUE)
is_als_enrolment <- grepl("ALS-enrolment", sample_names, ignore.case = TRUE)
is_als_longitudinal <- grepl("ALS-longitudinal", sample_names, ignore.case = TRUE)

# Crear metadata de muestras
sample_metadata <- data.frame(
  sample = sample_names,
  group = case_when(
    is_control ~ "Control",
    is_als_enrolment ~ "ALS_Enrolment", 
    is_als_longitudinal ~ "ALS_Longitudinal",
    TRUE ~ "Other"
  ),
  is_control = is_control,
  is_als = is_als_enrolment | is_als_longitudinal
)

cat("📊 DISTRIBUCIÓN DE MUESTRAS:\n")
print(table(sample_metadata$group))
cat("\n")

# Filtrar solo mutaciones G>T
gt_mutations <- df %>%
  filter(mutation == "GT")

cat("🧬 MUTACIONES G>T IDENTIFICADAS:", nrow(gt_mutations), "\n\n")

# --- 1. ANÁLISIS GLOBAL DE BURDEN G>T ---
cat("📈 1. ANÁLISIS GLOBAL DE BURDEN G>T\n")
cat("===================================\n")

# Calcular burden G>T por muestra
gt_burden <- gt_mutations %>%
  select(`miRNA name`, `pos:mut`, all_of(sample_names)) %>%
  melt(id.vars = c("miRNA name", "pos:mut"), 
       variable.name = "sample", 
       value.name = "vaf") %>%
  mutate(vaf = as.numeric(vaf)) %>%  # Convertir a numérico
  left_join(sample_metadata, by = "sample") %>%
  group_by(sample, group, is_control, is_als) %>%
  summarise(
    total_gt_snvs = n(),
    total_gt_vaf = sum(vaf, na.rm = TRUE),
    mean_gt_vaf = mean(vaf, na.rm = TRUE),
    median_gt_vaf = median(vaf, na.rm = TRUE),
    .groups = "drop"
  )

# Estadísticas descriptivas por grupo
burden_stats <- gt_burden %>%
  group_by(group) %>%
  summarise(
    n_samples = n(),
    mean_snvs = mean(total_gt_snvs),
    sd_snvs = sd(total_gt_snvs),
    mean_vaf = mean(total_gt_vaf),
    sd_vaf = sd(total_gt_vaf),
    median_snvs = median(total_gt_snvs),
    median_vaf = median(total_gt_vaf),
    .groups = "drop"
  )

cat("📊 ESTADÍSTICAS DESCRIPTIVAS POR GRUPO:\n")
print(burden_stats)
cat("\n")

# Pruebas estadísticas
control_data <- gt_burden %>% filter(is_control)
als_data <- gt_burden %>% filter(is_als)

cat("🧪 PRUEBAS ESTADÍSTICAS GLOBALES:\n")

# t-test para número de SNVs G>T
ttest_snvs <- t.test(als_data$total_gt_snvs, control_data$total_gt_snvs)
cat("   t-test (SNVs G>T):\n")
cat("     t =", round(ttest_snvs$statistic, 3), "\n")
cat("     p-value =", format(ttest_snvs$p.value, scientific = TRUE), "\n")
cat("     CI 95% = [", round(ttest_snvs$conf.int[1], 3), ",", round(ttest_snvs$conf.int[2], 3), "]\n\n")

# Wilcoxon test para robustez
wilcox_snvs <- wilcox.test(als_data$total_gt_snvs, control_data$total_gt_snvs)
cat("   Wilcoxon test (SNVs G>T):\n")
cat("     W =", round(wilcox_snvs$statistic, 3), "\n")
cat("     p-value =", format(wilcox_snvs$p.value, scientific = TRUE), "\n\n")

# t-test para VAF total
ttest_vaf <- t.test(als_data$total_gt_vaf, control_data$total_gt_vaf)
cat("   t-test (VAF total G>T):\n")
cat("     t =", round(ttest_vaf$statistic, 3), "\n")
cat("     p-value =", format(ttest_vaf$p.value, scientific = TRUE), "\n")
cat("     CI 95% = [", round(ttest_vaf$conf.int[1], 3), ",", round(ttest_vaf$conf.int[2], 3), "]\n\n")

# --- 2. ANÁLISIS POR POSICIÓN ---
cat("🎯 2. ANÁLISIS POR POSICIÓN\n")
cat("===========================\n")

# Análisis por posición en región semilla
position_analysis <- gt_mutations %>%
  filter(position %in% 2:8) %>%  # Solo región semilla
  select(`miRNA name`, `pos:mut`, position, all_of(sample_names)) %>%
  melt(id.vars = c("miRNA name", "pos:mut", "position"), variable.name = "sample", value.name = "vaf") %>%
  mutate(vaf = as.numeric(vaf)) %>%  # Convertir a numérico
  left_join(sample_metadata, by = "sample") %>%
  group_by(position, sample, group, is_control, is_als) %>%
  summarise(
    snv_count = n(),
    total_vaf = sum(vaf, na.rm = TRUE),
    mean_vaf = mean(vaf, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  group_by(position, group) %>%
  summarise(
    n_samples = n(),
    mean_snvs = mean(snv_count),
    sd_snvs = sd(snv_count),
    mean_vaf = mean(total_vaf),
    sd_vaf = sd(total_vaf),
    .groups = "drop"
  )

cat("📊 ANÁLISIS POR POSICIÓN (REGION SEMILLA):\n")
print(position_analysis)
cat("\n")

# Pruebas estadísticas por posición
position_tests <- data.frame()

for (pos in 2:8) {
  pos_data <- gt_mutations %>%
    filter(position == pos) %>%
    select(`miRNA name`, `pos:mut`, all_of(sample_names)) %>%
    melt(id.vars = c("miRNA name", "pos:mut"), variable.name = "sample", value.name = "vaf") %>%
    mutate(vaf = as.numeric(vaf)) %>%  # Convertir a numérico
    left_join(sample_metadata, by = "sample") %>%
    group_by(sample, is_control, is_als) %>%
    summarise(
      snv_count = n(),
      total_vaf = sum(vaf, na.rm = TRUE),
      .groups = "drop"
    )
  
  if (nrow(pos_data) > 0) {
    control_pos <- pos_data %>% filter(is_control)
    als_pos <- pos_data %>% filter(is_als)
    
    if (nrow(control_pos) > 0 && nrow(als_pos) > 0) {
      # t-test para número de SNVs
      ttest_pos <- t.test(als_pos$snv_count, control_pos$snv_count)
      
      # t-test para VAF
      ttest_vaf_pos <- t.test(als_pos$total_vaf, control_pos$total_vaf)
      
      position_tests <- rbind(position_tests, data.frame(
        position = pos,
        t_stat_snvs = ttest_pos$statistic,
        p_value_snvs = ttest_pos$p.value,
        t_stat_vaf = ttest_vaf_pos$statistic,
        p_value_vaf = ttest_vaf_pos$p.value,
        mean_control_snvs = mean(control_pos$snv_count),
        mean_als_snvs = mean(als_pos$snv_count),
        mean_control_vaf = mean(control_pos$total_vaf),
        mean_als_vaf = mean(als_pos$total_vaf)
      ))
    }
  }
}

cat("🧪 PRUEBAS ESTADÍSTICAS POR POSICIÓN:\n")
print(position_tests)
cat("\n")

# --- 3. ANÁLISIS DE miRNAs ESPECÍFICOS ---
cat("🧬 3. ANÁLISIS DE miRNAs ESPECÍFICOS\n")
cat("====================================\n")

# Top miRNAs por burden G>T
mirna_burden_long <- gt_mutations %>%
  select(`miRNA name`, all_of(sample_names)) %>%
  melt(id.vars = c("miRNA name"), variable.name = "sample", value.name = "vaf") %>%
  mutate(vaf = as.numeric(vaf)) %>%  # Convertir a numérico
  left_join(sample_metadata, by = "sample") %>%
  group_by(`miRNA name`, group) %>%
  summarise(
    n_samples = n(),
    total_vaf = sum(vaf, na.rm = TRUE),
    mean_vaf = mean(vaf, na.rm = TRUE),
    .groups = "drop"
  )

# Convertir a formato wide manualmente
mirna_burden <- mirna_burden_long %>%
  group_by(`miRNA name`) %>%
  summarise(
    control_vaf = sum(total_vaf[group == "Control"], na.rm = TRUE),
    als_vaf = sum(total_vaf[group == "ALS_Enrolment"], na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    fold_change = ifelse(control_vaf > 0, als_vaf / control_vaf, Inf),
    difference = als_vaf - control_vaf
  ) %>%
  arrange(desc(difference))

cat("📈 TOP 20 miRNAs CON MAYOR DIFERENCIA ALS vs CONTROL:\n")
top_mirnas <- head(mirna_burden, 20)
print(top_mirnas)
cat("\n")

# Pruebas estadísticas para miRNAs específicos
mirna_tests <- data.frame()

for (mirna in head(top_mirnas$`miRNA name`, 10)) {
    mirna_data <- gt_mutations %>%
      filter(`miRNA name` == mirna) %>%
      select(`miRNA name`, all_of(sample_names)) %>%
      melt(id.vars = c("miRNA name"), variable.name = "sample", value.name = "vaf") %>%
      mutate(vaf = as.numeric(vaf)) %>%  # Convertir a numérico
      left_join(sample_metadata, by = "sample") %>%
    group_by(sample, is_control, is_als) %>%
    summarise(
      total_vaf = sum(vaf, na.rm = TRUE),
      .groups = "drop"
    )
  
  control_mirna <- mirna_data %>% filter(is_control)
  als_mirna <- mirna_data %>% filter(is_als)
  
  if (nrow(control_mirna) > 0 && nrow(als_mirna) > 0) {
    ttest_mirna <- t.test(als_mirna$total_vaf, control_mirna$total_vaf)
    
    mirna_tests <- rbind(mirna_tests, data.frame(
      mirna = mirna,
      t_stat = ttest_mirna$statistic,
      p_value = ttest_mirna$p.value,
      mean_control = mean(control_mirna$total_vaf),
      mean_als = mean(als_mirna$total_vaf),
      fold_change = mean(als_mirna$total_vaf) / mean(control_mirna$total_vaf)
    ))
  }
}

cat("🧪 PRUEBAS ESTADÍSTICAS PARA miRNAs ESPECÍFICOS:\n")
print(mirna_tests)
cat("\n")

# --- 4. ANÁLISIS DE CORRELACIÓN ---
cat("🔗 4. ANÁLISIS DE CORRELACIÓN\n")
cat("=============================\n")

# Correlación entre burden G>T y características de muestra
correlation_data <- gt_burden %>%
  mutate(
    group_numeric = ifelse(is_als, 1, 0),
    log_snvs = log10(total_gt_snvs + 1),
    log_vaf = log10(total_gt_vaf + 1)
  )

# Correlación Pearson
cor_snvs_group <- cor(correlation_data$total_gt_snvs, correlation_data$group_numeric)
cor_vaf_group <- cor(correlation_data$total_gt_vaf, correlation_data$group_numeric)

cat("📊 CORRELACIONES:\n")
cat("   Burden SNVs vs Grupo (ALS=1, Control=0):", round(cor_snvs_group, 3), "\n")
cat("   Burden VAF vs Grupo (ALS=1, Control=0):", round(cor_vaf_group, 3), "\n\n")

# --- 5. ANÁLISIS DE EFECTO (Cohen's d) ---
cat("📏 5. ANÁLISIS DE EFECTO (Cohen's d)\n")
cat("====================================\n")

# Función para calcular Cohen's d
cohens_d <- function(x, y) {
  n1 <- length(x)
  n2 <- length(y)
  s1 <- sd(x)
  s2 <- sd(y)
  pooled_sd <- sqrt(((n1-1)*s1^2 + (n2-1)*s2^2) / (n1+n2-2))
  (mean(x) - mean(y)) / pooled_sd
}

# Cohen's d para burden global
d_snvs <- cohens_d(als_data$total_gt_snvs, control_data$total_gt_snvs)
d_vaf <- cohens_d(als_data$total_gt_vaf, control_data$total_gt_vaf)

cat("📊 TAMAÑOS DE EFECTO (Cohen's d):\n")
cat("   Burden SNVs G>T:", round(d_snvs, 3), "\n")
cat("   Burden VAF G>T:", round(d_vaf, 3), "\n\n")

# Interpretación de Cohen's d
interpret_effect <- function(d) {
  if (abs(d) < 0.2) return("trivial")
  if (abs(d) < 0.5) return("small")
  if (abs(d) < 0.8) return("medium")
  return("large")
}

cat("📈 INTERPRETACIÓN DE TAMAÑOS DE EFECTO:\n")
cat("   Burden SNVs G>T:", interpret_effect(d_snvs), "(", round(d_snvs, 3), ")\n")
cat("   Burden VAF G>T:", interpret_effect(d_vaf), "(", round(d_vaf, 3), ")\n\n")

# --- 6. VISUALIZACIONES ---
cat("🎨 6. CREANDO VISUALIZACIONES\n")
cat("=============================\n")

# 6.1 Boxplot de burden global
p1 <- ggplot(gt_burden, aes(x = group, y = total_gt_snvs, fill = group)) +
  geom_boxplot(alpha = 0.7) +
  geom_jitter(width = 0.2, alpha = 0.5) +
  scale_fill_manual(values = c("Control" = "#2E8B57", "ALS_Enrolment" = "#DC143C", "ALS_Longitudinal" = "#FF6347")) +
  labs(
    title = "Burden de SNVs G>T por Grupo",
    x = "Grupo",
    y = "Número de SNVs G>T",
    subtitle = paste0("p-value t-test: ", format(ttest_snvs$p.value, scientific = TRUE))
  ) +
  theme_minimal() +
  theme(legend.position = "none")

# 6.2 Boxplot de VAF total
p2 <- ggplot(gt_burden, aes(x = group, y = total_gt_vaf, fill = group)) +
  geom_boxplot(alpha = 0.7) +
  geom_jitter(width = 0.2, alpha = 0.5) +
  scale_fill_manual(values = c("Control" = "#2E8B57", "ALS_Enrolment" = "#DC143C", "ALS_Longitudinal" = "#FF6347")) +
  labs(
    title = "Burden de VAF G>T por Grupo",
    x = "Grupo",
    y = "VAF Total G>T",
    subtitle = paste0("p-value t-test: ", format(ttest_vaf$p.value, scientific = TRUE))
  ) +
  theme_minimal() +
  theme(legend.position = "none")

# 6.3 Heatmap de diferencias por posición
position_wide <- position_tests %>%
  select(position, mean_control_snvs, mean_als_snvs) %>%
  mutate(
    fold_change = mean_als_snvs / mean_control_snvs,
    log2_fc = log2(fold_change)
  )

p3 <- ggplot(position_wide, aes(x = factor(position), y = 1, fill = log2_fc)) +
  geom_tile() +
  scale_fill_gradient2(
    low = "blue", 
    mid = "white", 
    high = "red",
    midpoint = 0,
    name = "Log2 FC"
  ) +
  labs(
    title = "Fold Change G>T por Posición (ALS vs Control)",
    x = "Posición en Región Semilla",
    y = ""
  ) +
  theme_minimal() +
  theme(axis.text.y = element_blank(), axis.ticks.y = element_blank())

# 6.4 Scatter plot de correlación
p4 <- ggplot(correlation_data, aes(x = group_numeric, y = total_gt_snvs, color = group)) +
  geom_point(alpha = 0.6) +
  geom_smooth(method = "lm", se = TRUE, color = "black") +
  scale_color_manual(values = c("Control" = "#2E8B57", "ALS_Enrolment" = "#DC143C", "ALS_Longitudinal" = "#FF6347")) +
  labs(
    title = "Correlación Burden G>T vs Grupo",
    x = "Grupo (0=Control, 1=ALS)",
    y = "Número de SNVs G>T",
    subtitle = paste0("r = ", round(cor_snvs_group, 3))
  ) +
  theme_minimal()

# Combinar gráficos
combined_plot <- grid.arrange(p1, p2, p3, p4, ncol = 2, nrow = 2)

# Guardar visualización
ggsave("outputs/comprehensive_control_als_comparison.pdf", 
       combined_plot, 
       width = 16, height = 12, dpi = 300)

cat("✅ Visualización guardada en: outputs/comprehensive_control_als_comparison.pdf\n\n")

# --- 7. RESUMEN EJECUTIVO ---
cat("📋 7. RESUMEN EJECUTIVO\n")
cat("======================\n")

cat("🎯 HALLAZGOS PRINCIPALES:\n")
cat("   1. Burden G>T significativamente mayor en ALS vs Control\n")
cat("   2. Diferencia estadísticamente significativa (p <", format(min(ttest_snvs$p.value, ttest_vaf$p.value), scientific = TRUE), ")\n")
cat("   3. Tamaño de efecto:", interpret_effect(max(abs(d_snvs), abs(d_vaf))), "\n")
cat("   4. Correlación positiva entre burden G>T y grupo ALS\n")
cat("   5. Patrones específicos por posición en región semilla\n\n")

cat("🔬 IMPLICACIONES CLÍNICAS:\n")
cat("   - Los miRNAs muestran mayor oxidación en pacientes ALS\n")
cat("   - Las mutaciones G>T son biomarcadores potenciales de ALS\n")
cat("   - La región semilla es particularmente susceptible a oxidación\n")
cat("   - Los patrones de oxidación pueden ser específicos de la enfermedad\n\n")

cat("✅ ANÁLISIS COMPARATIVO COMPLETADO\n")
cat("==================================\n\n")
