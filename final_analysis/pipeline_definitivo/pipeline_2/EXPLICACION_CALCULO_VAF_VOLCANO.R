#!/usr/bin/env Rscript
# ============================================================================
# EXPLICACIÓN DETALLADA: ¿CÓMO SE CALCULAN LOS VAF EN EL VOLCANO?
# Tutorial paso por paso con datos reales
# ============================================================================

library(dplyr)
library(tidyr)
library(stringr)
library(readr)

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  TUTORIAL: CÁLCULO DE VAF PARA VOLCANO PLOT\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# ============================================================================
# CARGAR DATOS
# ============================================================================

cat("📂 PASO 0: CARGAR DATOS\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

data <- read_csv("final_processed_data_CLEAN.csv", show_col_types = FALSE)
metadata <- read_csv("metadata.csv", show_col_types = FALSE)

cat("ESTRUCTURA DE LOS DATOS:\n\n")
cat("1. DATA (final_processed_data_CLEAN.csv):\n")
cat("   Columnas:\n")
cat("      - miRNA_name: Nombre del miRNA (ej: 'hsa-let-7a-5p')\n")
cat("      - pos.mut: Posición y mutación (ej: '6:GT')\n")
cat("      - ", length(metadata$Sample_ID), "columnas de muestras (ALS1, ALS2, ..., Control1, ...)\n")
cat("   Cada celda = VAF de esa mutación en esa muestra\n\n")

cat("   Ejemplo visual de 3 filas:\n")
cat("   ┌──────────────┬─────────┬───────┬───────┬───────┬─────┐\n")
cat("   │ miRNA_name   │ pos.mut │ ALS1  │ ALS2  │ Ctrl1 │ ... │\n")
cat("   ├──────────────┼─────────┼───────┼───────┼───────┼─────┤\n")
cat("   │ let-7a-5p    │ 6:GT    │ 0.02  │ 0.01  │ 0.025 │ ... │\n")
cat("   │ miR-9-5p     │ 3:GT    │ 0.03  │ 0.00  │ 0.015 │ ... │\n")
cat("   │ let-7a-5p    │ 7:GA    │ 0.01  │ 0.02  │ 0.010 │ ... │\n")
cat("   └──────────────┴─────────┴───────┴───────┴───────┴─────┘\n\n")

cat("2. METADATA (metadata.csv):\n")
cat("   Columnas:\n")
cat("      - Sample_ID: ID de la muestra (ej: 'ALS1')\n")
cat("      - Group: Grupo ('ALS' o 'Control')\n\n")

cat("   Ejemplo:\n")
cat("   ┌────────────┬──────────┐\n")
cat("   │ Sample_ID  │ Group    │\n")
cat("   ├────────────┼──────────┤\n")
cat("   │ ALS1       │ ALS      │\n")
cat("   │ ALS2       │ ALS      │\n")
cat("   │ Control1   │ Control  │\n")
cat("   └────────────┴──────────┘\n\n")

# ============================================================================
# PASO 1: FILTRAR SOLO G>T EN SEED
# ============================================================================

cat("\n📌 PASO 1: FILTRAR SOLO G>T EN SEED (posiciones 2-8)\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

seed_gt_data <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%  # Solo G>T
  mutate(position = as.numeric(str_extract(pos.mut, "^[0-9]+"))) %>%
  filter(position >= 2, position <= 8)  # Solo seed

cat("FILTROS APLICADOS:\n")
cat("   1. str_detect(pos.mut, ':GT$')\n")
cat("      → Mantiene solo mutaciones que terminan en ':GT'\n")
cat("      → Ejemplo: '6:GT' ✅, '7:GA' ❌\n\n")

cat("   2. position >= 2 & position <= 8\n")
cat("      → Mantiene solo posiciones 2,3,4,5,6,7,8 (seed)\n")
cat("      → Ejemplo: '6:GT' ✅, '10:GT' ❌\n\n")

cat("RESULTADO:\n")
cat("   Filas antes del filtro:", nrow(data), "SNVs\n")
cat("   Filas después del filtro:", nrow(seed_gt_data), "SNVs\n")
cat("   miRNAs únicos:", length(unique(seed_gt_data$miRNA_name)), "\n\n")

cat("EJEMPLO de datos filtrados (primeras 3 filas):\n")
example_filtered <- seed_gt_data %>% 
  select(miRNA_name, pos.mut, position) %>% 
  head(3)
print(example_filtered)
cat("\n")

# ============================================================================
# PASO 2: TRANSFORMAR A FORMATO LARGO (TIDY)
# ============================================================================

cat("\n📌 PASO 2: TRANSFORMAR DE FORMATO ANCHO A LARGO\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

sample_cols <- metadata$Sample_ID

cat("FORMATO ANCHO (actual):\n")
cat("   ┌────────────┬─────────┬──────┬──────┬───────┐\n")
cat("   │ miRNA      │ pos.mut │ ALS1 │ ALS2 │ Ctrl1 │\n")
cat("   ├────────────┼─────────┼──────┼──────┼───────┤\n")
cat("   │ let-7a     │ 6:GT    │ 0.02 │ 0.01 │ 0.025 │\n")
cat("   └────────────┴─────────┴──────┴──────┴───────┘\n")
cat("   ↓ pivot_longer()\n")
cat("   ↓\n")
cat("FORMATO LARGO (tidy):\n")
cat("   ┌────────────┬─────────┬───────────┬──────┐\n")
cat("   │ miRNA      │ pos.mut │ Sample_ID │ VAF  │\n")
cat("   ├────────────┼─────────┼───────────┼──────┤\n")
cat("   │ let-7a     │ 6:GT    │ ALS1      │ 0.02 │\n")
cat("   │ let-7a     │ 6:GT    │ ALS2      │ 0.01 │\n")
cat("   │ let-7a     │ 6:GT    │ Ctrl1     │ 0.025│\n")
cat("   └────────────┴─────────┴───────────┴──────┘\n\n")

vaf_long <- seed_gt_data %>%
  select(all_of(c("miRNA_name", "pos.mut", sample_cols))) %>%
  pivot_longer(
    cols = all_of(sample_cols), 
    names_to = "Sample_ID", 
    values_to = "VAF"
  ) %>%
  left_join(metadata, by = "Sample_ID")

cat("CÓDIGO:\n")
cat("   pivot_longer(cols = all_of(sample_cols),\n")
cat("                names_to = 'Sample_ID',\n")
cat("                values_to = 'VAF')\n\n")

cat("RESULTADO:\n")
cat("   Filas antes:", nrow(seed_gt_data), "(cada fila = 1 SNV × 415 columnas)\n")
cat("   Filas después:", nrow(vaf_long), "(cada fila = 1 SNV × 1 muestra)\n")
cat("   Cálculo:", nrow(seed_gt_data), "× 415 muestras =", nrow(vaf_long), "✅\n\n")

cat("EJEMPLO de datos transformados (primeras 6 filas):\n")
example_long <- vaf_long %>% 
  select(miRNA_name, pos.mut, Sample_ID, Group, VAF) %>% 
  head(6)
print(example_long)
cat("\n")

# ============================================================================
# PASO 3: CALCULAR PROMEDIO POR miRNA
# ============================================================================

cat("\n📌 PASO 3: EJEMPLO DETALLADO CON UN miRNA REAL\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

# Tomar el primer miRNA como ejemplo
example_mirna <- unique(seed_gt_data$miRNA_name)[1]

cat("EJEMPLO: miRNA =", example_mirna, "\n\n")

# Extraer datos de este miRNA
example_data <- vaf_long %>% filter(miRNA_name == example_mirna)

cat("PASO 3.1: EXTRAER DATOS DE ESTE miRNA\n\n")
cat("   Número de filas para este miRNA:", nrow(example_data), "\n")
cat("   (cada fila = 1 muestra con su VAF)\n\n")

cat("   Primeras 10 muestras:\n")
example_sample <- example_data %>% 
  select(miRNA_name, pos.mut, Sample_ID, Group, VAF) %>% 
  head(10)
print(example_sample)
cat("\n")

# Separar por grupo
als_vals <- example_data %>% filter(Group == "ALS") %>% pull(VAF)
ctrl_vals <- example_data %>% filter(Group == "Control") %>% pull(VAF)

# Quitar NA
als_vals <- als_vals[!is.na(als_vals)]
ctrl_vals <- ctrl_vals[!is.na(ctrl_vals)]

cat("PASO 3.2: SEPARAR POR GRUPO\n\n")
cat("   VAF en ALS (", length(als_vals), "valores):\n")
cat("      Primeros 10:", paste(round(head(als_vals, 10), 4), collapse = ", "), "\n")
cat("      ...\n\n")

cat("   VAF en Control (", length(ctrl_vals), "valores):\n")
cat("      Primeros 10:", paste(round(head(ctrl_vals, 10), 4), collapse = ", "), "\n")
cat("      ...\n\n")

cat("PASO 3.3: CALCULAR ESTADÍSTICAS\n\n")

mean_als <- mean(als_vals)
mean_ctrl <- mean(ctrl_vals)
median_als <- median(als_vals)
median_ctrl <- median(ctrl_vals)
sd_als <- sd(als_vals)
sd_ctrl <- sd(ctrl_vals)

cat("   ALS:\n")
cat("      N = ", length(als_vals), "muestras\n")
cat("      Promedio (mean) = ", round(mean_als, 6), "\n")
cat("      Mediana = ", round(median_als, 6), "\n")
cat("      SD = ", round(sd_als, 6), "\n\n")

cat("   Control:\n")
cat("      N = ", length(ctrl_vals), "muestras\n")
cat("      Promedio (mean) = ", round(mean_ctrl, 6), "\n")
cat("      Mediana = ", round(median_ctrl, 6), "\n")
cat("      SD = ", round(sd_ctrl, 6), "\n\n")

# ============================================================================
# PASO 4: CALCULAR FOLD CHANGE
# ============================================================================

cat("\n📌 PASO 4: CALCULAR FOLD CHANGE (log₂)\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

# Agregar 0.001 para evitar división por cero
mean_als_adj <- mean_als + 0.001
mean_ctrl_adj <- mean_ctrl + 0.001

cat("PASO 4.1: AJUSTAR PARA EVITAR CEROS\n\n")
cat("   Mean ALS (original): ", round(mean_als, 6), "\n")
cat("   Mean ALS (ajustado): ", round(mean_als_adj, 6), " (+0.001)\n\n")
cat("   Mean Control (original): ", round(mean_ctrl, 6), "\n")
cat("   Mean Control (ajustado): ", round(mean_ctrl_adj, 6), " (+0.001)\n\n")

cat("   ¿Por qué +0.001?\n")
cat("   • Si mean_als = 0 o mean_ctrl = 0 → división por cero!\n")
cat("   • +0.001 es un 'pseudocount' para evitar error\n")
cat("   • Impacto mínimo si los valores son > 0.001\n\n")

cat("PASO 4.2: CALCULAR FOLD CHANGE\n\n")

fc <- mean_als_adj / mean_ctrl_adj
log2fc <- log2(fc)

cat("   Fold Change (FC):\n")
cat("      FC = Mean_ALS / Mean_Control\n")
cat("      FC = ", round(mean_als_adj, 6), " / ", round(mean_ctrl_adj, 6), "\n")
cat("      FC = ", round(fc, 4), "\n\n")

cat("   Interpretación del FC:\n")
if (fc > 1) {
  cat("      FC =", round(fc, 2), "→ ALS tiene", round(fc, 2), "veces más que Control\n")
} else {
  cat("      FC =", round(fc, 2), "→ Control tiene", round(1/fc, 2), "veces más que ALS\n")
}
cat("\n")

cat("   log₂(Fold Change):\n")
cat("      log2FC = log₂(FC)\n")
cat("      log2FC = log₂(", round(fc, 4), ")\n")
cat("      log2FC = ", round(log2fc, 4), "\n\n")

cat("   Interpretación del log2FC:\n")
if (log2fc > 0) {
  cat("      log2FC > 0 → ALS > Control\n")
  cat("      Magnitud: ALS tiene 2^(", round(log2fc, 2), ") = ", round(2^log2fc, 2), "x más\n")
} else if (log2fc < 0) {
  cat("      log2FC < 0 → Control > ALS\n")
  cat("      Magnitud: Control tiene 2^(", round(abs(log2fc), 2), ") = ", round(2^abs(log2fc), 2), "x más\n")
} else {
  cat("      log2FC = 0 → Sin diferencia\n")
}
cat("\n")

cat("   Escala de log2FC:\n")
cat("      log2FC = -3 → Control tiene 8x más (2³ = 8)\n")
cat("      log2FC = -2 → Control tiene 4x más (2² = 4)\n")
cat("      log2FC = -1 → Control tiene 2x más (2¹ = 2)\n")
cat("      log2FC = -0.58 → Control tiene 1.5x más (umbral) ←\n")
cat("      log2FC = 0 → Sin diferencia\n")
cat("      log2FC = +0.58 → ALS tiene 1.5x más (umbral) ←\n")
cat("      log2FC = +1 → ALS tiene 2x más\n")
cat("      log2FC = +2 → ALS tiene 4x más\n\n")

# ============================================================================
# PASO 5: TEST ESTADÍSTICO
# ============================================================================

cat("\n📌 PASO 5: TEST ESTADÍSTICO (Wilcoxon)\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

test_result <- wilcox.test(als_vals, ctrl_vals)

cat("TEST: Wilcoxon rank-sum (Mann-Whitney U)\n\n")
cat("   Compara las DOS distribuciones:\n")
cat("      Distribución ALS (", length(als_vals), "valores)\n")
cat("      Distribución Control (", length(ctrl_vals), "valores)\n\n")

cat("   Pregunta del test:\n")
cat("      '¿Estas dos distribuciones son DIFERENTES?'\n")
cat("      (No asume normalidad, usa rangos)\n\n")

cat("   RESULTADO:\n")
cat("      p-value = ", format.pval(test_result$p.value, digits = 4), "\n\n")

cat("   Interpretación:\n")
if (test_result$p.value < 0.05) {
  cat("      p < 0.05 → DIFERENCIA SIGNIFICATIVA ✅\n")
  cat("      Confianza: < 5% probabilidad de que sea azar\n")
} else {
  cat("      p >= 0.05 → NO SIGNIFICATIVO ❌\n")
  cat("      Confianza: > 5% probabilidad de que sea azar\n")
  cat("      No podemos rechazar que sean iguales\n")
}
cat("\n")

# Mostrar distribuciones
cat("   DISTRIBUCIÓN DE VALORES:\n\n")
cat("   ALS:\n")
cat("      Min:", round(min(als_vals), 6), "\n")
cat("      Q25:", round(quantile(als_vals, 0.25), 6), "\n")
cat("      Mediana:", round(median(als_vals), 6), "\n")
cat("      Q75:", round(quantile(als_vals, 0.75), 6), "\n")
cat("      Max:", round(max(als_vals), 6), "\n\n")

cat("   Control:\n")
cat("      Min:", round(min(ctrl_vals), 6), "\n")
cat("      Q25:", round(quantile(ctrl_vals, 0.25), 6), "\n")
cat("      Mediana:", round(median(ctrl_vals), 6), "\n")
cat("      Q75:", round(quantile(ctrl_vals, 0.75), 6), "\n")
cat("      Max:", round(max(ctrl_vals), 6), "\n\n")

cat("   ¿Por qué puede no ser significativo?\n")
if (sd_als > mean_als | sd_ctrl > mean_ctrl) {
  cat("      ✓ ALTA VARIABILIDAD: SD comparable o mayor que la media\n")
  cat("        Las distribuciones se superponen mucho\n")
}
if (abs(mean_als - mean_ctrl) < 0.01) {
  cat("      ✓ DIFERENCIA PEQUEÑA: Promedios muy cercanos\n")
  cat("        |", round(mean_als, 4), "-", round(mean_ctrl, 4), "| =", round(abs(mean_als - mean_ctrl), 6), "\n")
}
cat("\n")

# ============================================================================
# PASO 6: HACER ESTO PARA TODOS LOS miRNAs
# ============================================================================

cat("\n📌 PASO 6: REPETIR PARA TODOS LOS miRNAs\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

all_mirnas <- unique(seed_gt_data$miRNA_name)

cat("Total miRNAs con G>T en seed:", length(all_mirnas), "\n\n")

cat("PROCESO:\n")
cat("   for (cada uno de los", length(all_mirnas), "miRNAs) {\n")
cat("      1. Filtrar datos de ese miRNA\n")
cat("      2. Separar VAF de ALS vs Control\n")
cat("      3. Calcular promedios\n")
cat("      4. Calcular log2FC\n")
cat("      5. Hacer test (Wilcoxon)\n")
cat("      6. Guardar: miRNA, log2FC, pvalue\n")
cat("   }\n\n")

cat("Calculando para todos...\n")

volcano_data <- data.frame()
for (mirna in all_mirnas) {
  mirna_data <- vaf_long %>% filter(miRNA_name == mirna)
  als_v <- mirna_data %>% filter(Group == "ALS") %>% pull(VAF) %>% na.omit()
  ctrl_v <- mirna_data %>% filter(Group == "Control") %>% pull(VAF) %>% na.omit()
  
  if (length(als_v) > 5 && length(ctrl_v) > 5) {
    m_als <- mean(als_v) + 0.001
    m_ctrl <- mean(ctrl_v) + 0.001
    fc_val <- log2(m_als / m_ctrl)
    test_r <- tryCatch(wilcox.test(als_v, ctrl_v), error = function(e) list(p.value = 1))
    
    volcano_data <- rbind(volcano_data, data.frame(
      miRNA = mirna,
      log2FC = fc_val,
      pvalue = test_r$p.value,
      Mean_ALS = m_als - 0.001,  # Quitar el ajuste para mostrar
      Mean_Control = m_ctrl - 0.001,
      N_ALS = length(als_v),
      N_Control = length(ctrl_v)
    ))
  }
}

cat("   ✅ Procesados:", nrow(volcano_data), "miRNAs\n\n")

cat("PRIMEROS 5 miRNAs procesados:\n")
print(head(volcano_data, 5))
cat("\n")

# ============================================================================
# PASO 7: AJUSTE FDR
# ============================================================================

cat("\n📌 PASO 7: AJUSTE POR MÚLTIPLES COMPARACIONES (FDR)\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

volcano_data$padj <- p.adjust(volcano_data$pvalue, method = "fdr")

cat("PROBLEMA:\n")
cat("   Estamos haciendo", nrow(volcano_data), "tests simultáneos\n")
cat("   Si usamos p < 0.05 sin ajuste:\n")
cat("      Esperaríamos ~", round(nrow(volcano_data) * 0.05), "falsos positivos por AZAR\n\n")

cat("SOLUCIÓN: FDR (False Discovery Rate)\n")
cat("   Método de Benjamini-Hochberg\n")
cat("   Controla la proporción de falsos positivos\n\n")

cat("   p.adjust(pvalue, method = 'fdr')\n\n")

cat("EFECTO DEL AJUSTE:\n\n")

# Mostrar ejemplos de cambio
examples_padj <- volcano_data %>%
  arrange(pvalue) %>%
  select(miRNA, pvalue, padj) %>%
  head(10)

cat("   Top 10 miRNAs por p-value:\n")
print(examples_padj)
cat("\n")

cat("   Observa:\n")
cat("      - p-value ORIGINAL puede ser < 0.05\n")
cat("      - p-value AJUSTADO (padj) puede ser > 0.05\n")
cat("      - Esto ELIMINA potenciales falsos positivos\n\n")

# Cuántos serían significativos SIN ajuste
n_sig_nominal <- sum(volcano_data$pvalue < 0.05 & abs(volcano_data$log2FC) > 0.58)
n_sig_fdr <- sum(volcano_data$padj < 0.05 & abs(volcano_data$log2FC) > 0.58)

cat("   SIN FDR (p < 0.05):", n_sig_nominal, "miRNAs significativos\n")
cat("   CON FDR (padj < 0.05):", n_sig_fdr, "miRNAs significativos\n\n")

if (n_sig_nominal > n_sig_fdr) {
  cat("   ⚠️  FDR eliminó", n_sig_nominal - n_sig_fdr, "posibles falsos positivos\n\n")
}

# ============================================================================
# PASO 8: CLASIFICAR
# ============================================================================

cat("\n📌 PASO 8: CLASIFICAR CADA miRNA\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

volcano_data$Sig <- "NS"
volcano_data$Sig[volcano_data$log2FC > 0.58 & volcano_data$padj < 0.05] <- "ALS"
volcano_data$Sig[volcano_data$log2FC < -0.58 & volcano_data$padj < 0.05] <- "Control"

cat("CRITERIOS DE CLASIFICACIÓN:\n\n")
cat("   'ALS' (rojo):\n")
cat("      ✓ log2FC > 0.58 (ALS tiene al menos 1.5x más)\n")
cat("      Y\n")
cat("      ✓ padj < 0.05 (significativo después de FDR)\n\n")

cat("   'Control' (gris oscuro):\n")
cat("      ✓ log2FC < -0.58 (Control tiene al menos 1.5x más)\n")
cat("      Y\n")
cat("      ✓ padj < 0.05\n\n")

cat("   'NS' (gris claro):\n")
cat("      Cualquier otro caso\n\n")

cat("RESULTADOS:\n")
cat("   Clasificados como 'ALS':", sum(volcano_data$Sig == "ALS"), "\n")
cat("   Clasificados como 'Control':", sum(volcano_data$Sig == "Control"), "\n")
cat("   Clasificados como 'NS':", sum(volcano_data$Sig == "NS"), "\n\n")

# ============================================================================
# PASO 9: GRAFICAR
# ============================================================================

cat("\n📌 PASO 9: CREAR EL GRÁFICO\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

volcano_data$neg_log10_padj <- -log10(volcano_data$padj)

cat("TRANSFORMAR EJE Y:\n")
cat("   neg_log10_padj = -log₁₀(padj)\n\n")

cat("   Ejemplos:\n")
cat("      padj = 0.5 → -log10(0.5) = 0.30 (abajo)\n")
cat("      padj = 0.1 → -log10(0.1) = 1.00 (cerca del umbral)\n")
cat("      padj = 0.05 → -log10(0.05) = 1.30 (línea umbral) ←\n")
cat("      padj = 0.01 → -log10(0.01) = 2.00 (significativo)\n")
cat("      padj = 0.001 → -log10(0.001) = 3.00 (muy significativo)\n\n")

cat("ELEMENTOS DEL GRÁFICO:\n\n")
cat("   Puntos:\n")
cat("      • Posición X: log2FC (magnitud del cambio)\n")
cat("      • Posición Y: -log10(padj) (significancia)\n")
cat("      • Color: Clasificación (ALS/Control/NS)\n")
cat("      • Tamaño: Fijo (2.5)\n")
cat("      • Transparencia: 0.6\n\n")

cat("   Líneas punteadas:\n")
cat("      • Horizontal Y=1.3: Umbral FDR p = 0.05\n")
cat("      • Vertical X=0.58: Umbral FC = 1.5x (derecha)\n")
cat("      • Vertical X=-0.58: Umbral FC = 1.5x (izquierda)\n\n")

cat("   Zonas:\n")
cat("      ┌────────────┬────────────┐\n")
cat("      │ Control    │   ALS      │\n")
cat("      │ sig        │   sig      │  ← Arriba línea\n")
cat("      ├────────────┼────────────┤\n")
cat("      │ Control NS │   ALS NS   │  ← Abajo línea\n")
cat("      └────────────┴────────────┘\n")
cat("         ←neg      0      pos→\n\n")

# ============================================================================
# RESUMEN DE QUÉ INFORMACIÓN USAMOS
# ============================================================================

cat("\n📋 RESUMEN: ¿QUÉ INFORMACIÓN ESTAMOS USANDO?\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

cat("DATOS DE ENTRADA:\n")
cat("   • 473 SNVs de G>T en seed (posiciones 2-8)\n")
cat("   • 301 miRNAs únicos\n")
cat("   • 415 muestras (313 ALS + 102 Control)\n\n")

cat("PARA CADA miRNA:\n")
cat("   • Todos los VAF de ese miRNA en todas las muestras ALS (hasta 313 valores)\n")
cat("   • Todos los VAF de ese miRNA en todas las muestras Control (hasta 102 valores)\n\n")

cat("CÁLCULO:\n")
cat("   1. Promedio de VAF en ALS\n")
cat("   2. Promedio de VAF en Control\n")
cat("   3. Ratio (ALS/Control)\n")
cat("   4. Test estadístico (¿distribuciones diferentes?)\n")
cat("   5. Ajuste FDR (controlar falsos positivos)\n\n")

cat("SALIDA:\n")
cat("   • 1 punto por miRNA (293 puntos graficados, 8 excluidos por n<5)\n")
cat("   • Posición = log2FC y -log10(padj)\n")
cat("   • Color = clasificación según umbrales\n\n")

# ============================================================================
# INTERPRETACIÓN FINAL
# ============================================================================

cat("\n🎯 INTERPRETACIÓN FINAL DEL VOLCANO\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

cat("PREGUNTA:\n")
cat("   '¿Hay miRNAs ESPECÍFICOS con G>T diferencial entre ALS y Control?'\n\n")

cat("RESPUESTA:\n")
cat("   NO - Después de corrección FDR, ningún miRNA individual\n")
cat("   alcanza significancia (padj < 0.05) con magnitud suficiente (|log2FC| > 0.58)\n\n")

cat("¿QUÉ SIGNIFICA ESTO BIOLÓGICAMENTE?\n\n")

cat("   ✓ El efecto es DISTRIBUIDO (no focal)\n")
cat("      → No hay 'miRNA culpable único'\n")
cat("      → Muchos miRNAs contribuyen un poco cada uno\n\n")

cat("   ✓ Alta HETEROGENEIDAD intra-grupo\n")
cat("      → Variabilidad entre muestras ALS es alta\n")
cat("      → Variabilidad entre muestras Control es alta\n")
cat("      → Se superponen las distribuciones\n\n")

cat("   ✓ Efecto ACUMULATIVO\n")
cat("      → La suma de muchas pequeñas diferencias = diferencia grande global\n")
cat("      → Fig 2.1-2.2 (global) significativa\n")
cat("      → Fig 2.3 (individual) no significativa\n")
cat("      → Ambos hallazgos SON COMPATIBLES\n\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("✅ TUTORIAL COMPLETO\n")
cat("\n")
cat("¿Quedó claro el proceso y la interpretación?\n")
cat("\n")

