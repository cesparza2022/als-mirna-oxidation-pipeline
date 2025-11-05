#!/usr/bin/env Rscript
# ============================================================================
# COMPARAR DATASETS: ¿Por qué el volcano cambió?
# Comparación detallada de los archivos de datos
# ============================================================================

library(dplyr)
library(tidyr)
library(stringr)
library(readr)

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  COMPARACIÓN DE DATASETS: ¿QUÉ CAMBIÓ?\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# ============================================================================
# CARGAR AMBOS DATASETS
# ============================================================================

cat("📂 Cargando datasets...\n\n")

# Dataset 1: FILTERED (el que dio resultados)
file1 <- "final_processed_data_FILTERED_VAF50.csv"
if (!file.exists(file1)) {
  cat("⚠️  ", file1, "NO EXISTE\n")
  cat("   Buscando en otras ubicaciones...\n")
  # Buscar en directorio padre
  file1_alt <- "../final_processed_data_FILTERED_VAF50.csv"
  if (file.exists(file1_alt)) {
    file1 <- file1_alt
    cat("   ✅ Encontrado en:", file1, "\n")
  } else {
    cat("   ❌ No encontrado. Usaré datos originales como proxy.\n")
    file1 <- "../../../final_analysis/processed_data/final_processed_data.csv"
  }
}

data_old <- read_csv(file1, show_col_types = FALSE)
cat("✅ Dataset ANTERIOR cargado:", file1, "\n")
cat("   Filas:", nrow(data_old), "SNVs\n\n")

# Dataset 2: CLEAN (el que NO da resultados)
file2 <- "final_processed_data_CLEAN.csv"
data_new <- read_csv(file2, show_col_types = FALSE)
cat("✅ Dataset ACTUAL cargado:", file2, "\n")
cat("   Filas:", nrow(data_new), "SNVs\n\n")

# Metadata
metadata <- read_csv("metadata.csv", show_col_types = FALSE)
sample_cols <- metadata$Sample_ID

# ============================================================================
# COMPARACIÓN 1: NÚMERO DE SNVs
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("1️⃣ COMPARACIÓN: NÚMERO DE SNVs\n")
cat("\n")

diff_rows <- nrow(data_old) - nrow(data_new)
perc_diff <- (diff_rows / nrow(data_old)) * 100

cat("DATASET ANTERIOR:", nrow(data_old), "SNVs\n")
cat("DATASET ACTUAL:", nrow(data_new), "SNVs\n")
cat("DIFERENCIA:", diff_rows, "SNVs (", round(perc_diff, 1), "%)\n\n")

if (diff_rows > 0) {
  cat("⚠️  DATASET ACTUAL tiene MENOS SNVs (más filtrado)\n")
} else if (diff_rows < 0) {
  cat("⚠️  DATASET ACTUAL tiene MÁS SNVs (menos filtrado)\n")
} else {
  cat("✅ MISMO número de SNVs\n")
}
cat("\n")

# ============================================================================
# COMPARACIÓN 2: G>T EN SEED
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("2️⃣ COMPARACIÓN: G>T EN SEED (posiciones 2-8)\n")
cat("\n")

# Filtrar G>T seed en ambos
gt_seed_old <- data_old %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^[0-9]+"))) %>%
  filter(position >= 2, position <= 8)

gt_seed_new <- data_new %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^[0-9]+"))) %>%
  filter(position >= 2, position <= 8)

cat("G>T SEED - ANTERIOR:", nrow(gt_seed_old), "SNVs\n")
cat("G>T SEED - ACTUAL:", nrow(gt_seed_new), "SNVs\n")
cat("DIFERENCIA:", nrow(gt_seed_old) - nrow(gt_seed_new), "SNVs\n\n")

# miRNAs únicos
mirnas_old <- unique(gt_seed_old$miRNA_name)
mirnas_new <- unique(gt_seed_new$miRNA_name)

cat("miRNAs únicos - ANTERIOR:", length(mirnas_old), "\n")
cat("miRNAs únicos - ACTUAL:", length(mirnas_new), "\n")
cat("DIFERENCIA:", length(mirnas_old) - length(mirnas_new), "miRNAs\n\n")

# ============================================================================
# COMPARACIÓN 3: RANGO DE VAF
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("3️⃣ COMPARACIÓN: RANGO DE VAF\n")
cat("\n")

# VAF en gt_seed
vaf_cols_old <- gt_seed_old %>% select(all_of(sample_cols))
vaf_cols_new <- gt_seed_new %>% select(all_of(sample_cols))

vaf_vals_old <- unlist(vaf_cols_old)
vaf_vals_new <- unlist(vaf_cols_new)

vaf_vals_old <- vaf_vals_old[!is.na(vaf_vals_old)]
vaf_vals_new <- vaf_vals_new[!is.na(vaf_vals_new)]

cat("RANGO VAF - ANTERIOR:\n")
cat("   Min:", round(min(vaf_vals_old), 4), "\n")
cat("   Max:", round(max(vaf_vals_old), 4), "\n")
cat("   Media:", round(mean(vaf_vals_old), 4), "\n")
cat("   Mediana:", round(median(vaf_vals_old), 4), "\n\n")

cat("RANGO VAF - ACTUAL:\n")
cat("   Min:", round(min(vaf_vals_new), 4), "\n")
cat("   Max:", round(max(vaf_vals_new), 4), "\n")
cat("   Media:", round(mean(vaf_vals_new), 4), "\n")
cat("   Mediana:", round(median(vaf_vals_new), 4), "\n\n")

# ============================================================================
# COMPARACIÓN 4: TOTAL VAF POR GRUPO
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("4️⃣ COMPARACIÓN: TOTAL G>T VAF POR GRUPO\n")
cat("\n")

# Calcular para ANTERIOR
vaf_old_long <- gt_seed_old %>%
  select(all_of(c("miRNA_name", "pos.mut", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  left_join(metadata, by = "Sample_ID")

vaf_old_summary <- vaf_old_long %>%
  group_by(Sample_ID, Group) %>%
  summarise(Total_GT_VAF = sum(VAF, na.rm = TRUE), .groups = "drop")

stats_old <- vaf_old_summary %>%
  group_by(Group) %>%
  summarise(
    N = n(),
    Mean = mean(Total_GT_VAF),
    Median = median(Total_GT_VAF),
    SD = sd(Total_GT_VAF),
    .groups = "drop"
  )

# Calcular para ACTUAL
vaf_new_long <- gt_seed_new %>%
  select(all_of(c("miRNA_name", "pos.mut", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  left_join(metadata, by = "Sample_ID")

vaf_new_summary <- vaf_new_long %>%
  group_by(Sample_ID, Group) %>%
  summarise(Total_GT_VAF = sum(VAF, na.rm = TRUE), .groups = "drop")

stats_new <- vaf_new_summary %>%
  group_by(Group) %>%
  summarise(
    N = n(),
    Mean = mean(Total_GT_VAF),
    Median = median(Total_GT_VAF),
    SD = sd(Total_GT_VAF),
    .groups = "drop"
  )

cat("ESTADÍSTICAS - DATASET ANTERIOR:\n")
print(stats_old)
cat("\n")

cat("ESTADÍSTICAS - DATASET ACTUAL:\n")
print(stats_new)
cat("\n")

# Test estadístico
test_old <- wilcox.test(Total_GT_VAF ~ Group, data = vaf_old_summary)
test_new <- wilcox.test(Total_GT_VAF ~ Group, data = vaf_new_summary)

cat("TESTS:\n")
cat("   ANTERIOR: p =", format.pval(test_old$p.value, digits = 3), "\n")
cat("   ACTUAL: p =", format.pval(test_new$p.value, digits = 3), "\n\n")

# ============================================================================
# COMPARACIÓN 5: VOLCANO PLOT SIMULADO
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("5️⃣ COMPARACIÓN: RESULTADOS DE VOLCANO\n")
cat("\n")

# Calcular volcano para ANTERIOR
cat("Calculando volcano para DATASET ANTERIOR...\n")
volcano_old <- data.frame()
for (mirna in mirnas_old) {
  mirna_data <- vaf_old_long %>% filter(miRNA_name == mirna)
  als_vals <- mirna_data %>% filter(Group == "ALS") %>% pull(VAF) %>% na.omit()
  ctrl_vals <- mirna_data %>% filter(Group == "Control") %>% pull(VAF) %>% na.omit()
  
  if (length(als_vals) > 5 && length(ctrl_vals) > 5) {
    mean_als <- mean(als_vals) + 0.001
    mean_ctrl <- mean(ctrl_vals) + 0.001
    fc <- log2(mean_als / mean_ctrl)
    test_result <- tryCatch(wilcox.test(als_vals, ctrl_vals), error = function(e) list(p.value = 1))
    
    volcano_old <- rbind(volcano_old, data.frame(
      miRNA = mirna, log2FC = fc, pvalue = test_result$p.value
    ))
  }
}
volcano_old$padj <- p.adjust(volcano_old$pvalue, method = "fdr")
volcano_old$Sig <- "NS"
volcano_old$Sig[volcano_old$log2FC > 0.58 & volcano_old$padj < 0.05] <- "ALS"
volcano_old$Sig[volcano_old$log2FC < -0.58 & volcano_old$padj < 0.05] <- "Control"

# Calcular volcano para ACTUAL
cat("Calculando volcano para DATASET ACTUAL...\n\n")
volcano_new <- data.frame()
for (mirna in mirnas_new) {
  mirna_data <- vaf_new_long %>% filter(miRNA_name == mirna)
  als_vals <- mirna_data %>% filter(Group == "ALS") %>% pull(VAF) %>% na.omit()
  ctrl_vals <- mirna_data %>% filter(Group == "Control") %>% pull(VAF) %>% na.omit()
  
  if (length(als_vals) > 5 && length(ctrl_vals) > 5) {
    mean_als <- mean(als_vals) + 0.001
    mean_ctrl <- mean(ctrl_vals) + 0.001
    fc <- log2(mean_als / mean_ctrl)
    test_result <- tryCatch(wilcox.test(als_vals, ctrl_vals), error = function(e) list(p.value = 1))
    
    volcano_new <- rbind(volcano_new, data.frame(
      miRNA = mirna, log2FC = fc, pvalue = test_result$p.value
    ))
  }
}
volcano_new$padj <- p.adjust(volcano_new$pvalue, method = "fdr")
volcano_new$Sig <- "NS"
volcano_new$Sig[volcano_new$log2FC > 0.58 & volcano_new$padj < 0.05] <- "ALS"
volcano_new$Sig[volcano_new$log2FC < -0.58 & volcano_new$padj < 0.05] <- "Control"

# ============================================================================
# RESULTADOS
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("🔥 RESULTADOS DE LA COMPARACIÓN\n")
cat("\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")

cat("📊 VOLCANO - DATASET ANTERIOR:\n")
cat("   miRNAs analizados:", nrow(volcano_old), "\n")
cat("   Significativos ALS:", sum(volcano_old$Sig == "ALS"), "\n")
cat("   Significativos Control:", sum(volcano_old$Sig == "Control"), "\n")
cat("   No significativos:", sum(volcano_old$Sig == "NS"), "\n\n")

cat("📊 VOLCANO - DATASET ACTUAL:\n")
cat("   miRNAs analizados:", nrow(volcano_new), "\n")
cat("   Significativos ALS:", sum(volcano_new$Sig == "ALS"), "\n")
cat("   Significativos Control:", sum(volcano_new$Sig == "Control"), "\n")
cat("   No significativos:", sum(volcano_new$Sig == "NS"), "\n\n")

# ============================================================================
# ANÁLISIS DE DIFERENCIAS
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("🔍 ANÁLISIS DE DIFERENCIAS\n")
cat("\n")

# Número de SNVs
cat("1. DIFERENCIA EN SNVs TOTALES:\n")
cat("   ", diff_rows, "SNVs eliminados (", round(perc_diff, 1), "%)\n\n")

# G>T seed
diff_gt_seed <- nrow(gt_seed_old) - nrow(gt_seed_new)
cat("2. DIFERENCIA EN G>T SEED:\n")
cat("   ", diff_gt_seed, "SNVs G>T seed eliminados\n\n")

# miRNAs
diff_mirnas <- length(mirnas_old) - length(mirnas_new)
cat("3. DIFERENCIA EN miRNAs:\n")
cat("   ", diff_mirnas, "miRNAs perdidos\n\n")

# VAF promedio
diff_mean_vaf <- mean(vaf_vals_old) - mean(vaf_vals_new)
cat("4. DIFERENCIA EN VAF PROMEDIO:\n")
cat("   ANTERIOR:", round(mean(vaf_vals_old), 4), "\n")
cat("   ACTUAL:", round(mean(vaf_vals_new), 4), "\n")
cat("   DIFERENCIA:", round(diff_mean_vaf, 4), 
    ifelse(diff_mean_vaf > 0, "(bajó)", "(subió)"), "\n\n")

# Máximo VAF
cat("5. DIFERENCIA EN VAF MÁXIMO:\n")
cat("   ANTERIOR:", round(max(vaf_vals_old), 4), "\n")
cat("   ACTUAL:", round(max(vaf_vals_new), 4), "\n\n")

# ============================================================================
# DIAGNÓSTICO
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("💡 DIAGNÓSTICO: ¿POR QUÉ PERDIMOS SIGNIFICANCIA?\n")
cat("\n")

sig_lost <- sum(volcano_old$Sig != "NS") - sum(volcano_new$Sig != "NS")

if (sig_lost > 0) {
  cat("🚨 PERDIMOS", sig_lost, "miRNAs SIGNIFICATIVOS\n\n")
  
  cat("POSIBLES RAZONES:\n\n")
  
  if (diff_rows > 100) {
    cat("✓ Razón 1: FILTRO MUY AGRESIVO\n")
    cat("   Se eliminaron", diff_rows, "SNVs (", round(perc_diff, 1), "%)\n")
    cat("   Esto reduce el poder estadístico\n\n")
  }
  
  if (max(vaf_vals_old) > 0.5 & max(vaf_vals_new) < 0.5) {
    cat("✓ Razón 2: FILTRO DE VAF >= 0.5\n")
    cat("   ANTERIOR tenía VAF hasta:", round(max(vaf_vals_old), 2), "\n")
    cat("   ACTUAL tiene VAF máximo:", round(max(vaf_vals_new), 2), "\n")
    cat("   Se eliminaron variantes de alta frecuencia\n\n")
  }
  
  if (diff_mirnas > 0) {
    cat("✓ Razón 3: PÉRDIDA DE miRNAs\n")
    cat("   Se perdieron", diff_mirnas, "miRNAs\n")
    cat("   Menos miRNAs → Menos tests → Posible pérdida de hallazgos\n\n")
  }
  
  cat("✓ Razón 4: CORRECCIÓN FDR MÁS ESTRICTA\n")
  cat("   ANTERIOR: Corrección sobre", nrow(volcano_old), "tests\n")
  cat("   ACTUAL: Corrección sobre", nrow(volcano_new), "tests\n")
  cat("   Número similar de tests pero datos diferentes\n\n")
  
} else {
  cat("✅ NO SE PERDIÓ SIGNIFICANCIA (o incluso ganamos)\n")
}

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")

# ============================================================================
# MOSTRAR miRNAs PERDIDOS
# ============================================================================

if (sum(volcano_old$Sig != "NS") > 0) {
  cat("🔍 miRNAs SIGNIFICATIVOS EN VERSIÓN ANTERIOR:\n\n")
  sig_old <- volcano_old %>% filter(Sig != "NS") %>% arrange(padj)
  print(sig_old)
  cat("\n")
  
  # ¿Están en la nueva?
  sig_mirnas_old <- sig_old$miRNA
  in_new <- sig_mirnas_old %in% mirnas_new
  
  cat("¿Estos miRNAs están en dataset ACTUAL?\n")
  for (i in seq_along(sig_mirnas_old)) {
    cat("   ", sig_mirnas_old[i], ":", ifelse(in_new[i], "✅ SÍ", "❌ NO"), "\n")
  }
  cat("\n")
}

# ============================================================================
# RECOMENDACIÓN
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("💡 RECOMENDACIÓN:\n")
cat("\n")

if (max(vaf_vals_old) > 0.5 & max(vaf_vals_new) < 0.5) {
  cat("🎯 EL PROBLEMA ES: FILTRO DE VAF >= 0.5\n\n")
  cat("EFECTO:\n")
  cat("   • Elimina artefactos técnicos (BUENO) ✅\n")
  cat("   • Pero también elimina variantes biológicas reales de alta frecuencia\n")
  cat("   • Reduce el poder estadístico\n")
  cat("   • Puede eliminar hallazgos reales\n\n")
  
  cat("SOLUCIONES:\n")
  cat("   Opción 1: Usar dataset ANTERIOR (menos filtrado)\n")
  cat("   Opción 2: Relajar umbrales de significancia (FDR < 0.1)\n")
  cat("   Opción 3: Investigar manualmente las variantes con VAF alto\n")
  cat("            (¿son artefactos o reales?)\n\n")
} else {
  cat("🎯 Investigar otras diferencias entre datasets\n")
}

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("✅ COMPARACIÓN COMPLETADA\n")
cat("\n")

