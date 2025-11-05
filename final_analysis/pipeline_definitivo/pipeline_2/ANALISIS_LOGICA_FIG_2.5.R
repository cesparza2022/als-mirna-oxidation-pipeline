#!/usr/bin/env Rscript
# ============================================================================
# ANÁLISIS DE LÓGICA Y ESTRUCTURA - FIGURA 2.5 (Z-SCORE HEATMAP)
# Revisar qué está haciendo exactamente y si tiene sentido
# ============================================================================

library(dplyr)
library(tidyr)
library(readr)
library(stringr)
library(tibble)

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  ANÁLISIS DE LÓGICA: FIGURA 2.5 Z-SCORE HEATMAP\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# ============================================================================
# CARGAR Y PREPARAR DATOS (igual que la figura original)
# ============================================================================

cat("📂 PASO 1: CARGAR DATOS\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

data <- read_csv("final_processed_data_CLEAN.csv", show_col_types = FALSE)
metadata <- read_csv("metadata.csv", show_col_types = FALSE)
sample_cols <- metadata$Sample_ID

# Ranking
seed_gt_data <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^[0-9]+"))) %>%
  filter(position >= 2, position <= 8)

seed_gt_summary <- seed_gt_data %>%
  select(all_of(c("miRNA_name", "pos.mut", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  group_by(miRNA_name) %>%
  summarise(Total_VAF = sum(VAF, na.rm = TRUE), .groups = "drop") %>%
  arrange(desc(Total_VAF))

top50 <- head(seed_gt_summary, 50)$miRNA_name

cat("✅ Top 50 miRNAs seleccionados\n\n")

# ============================================================================
# PASO 2: CREAR MATRICES RAW (como Fig 2.4)
# ============================================================================

cat("📊 PASO 2: CREAR MATRICES RAW (IGUAL QUE FIG 2.4)\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

# Todos los G>T (1-22) para top 50
vaf_gt_all <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^[0-9]+"))) %>%
  filter(!is.na(position), position <= 22) %>%
  filter(miRNA_name %in% top50) %>%
  select(all_of(c("miRNA_name", "position", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  left_join(metadata, by = "Sample_ID") %>%
  group_by(miRNA_name, position, Group) %>%
  summarise(Mean_VAF = mean(VAF, na.rm = TRUE), .groups = "drop")

# Crear matrices separadas ALS y Control
create_matrix <- function(group_name) {
  matrix_data <- vaf_gt_all %>%
    filter(Group == group_name) %>%
    select(miRNA_name, position, Mean_VAF) %>%
    pivot_wider(names_from = position, values_from = Mean_VAF, values_fill = 0) %>%
    column_to_rownames("miRNA_name")
  
  all_positions <- as.character(1:22)
  for (pos in setdiff(all_positions, colnames(matrix_data))) {
    matrix_data[[pos]] <- 0
  }
  matrix_data <- matrix_data[, all_positions]
  return(as.matrix(matrix_data))
}

mat_als <- create_matrix("ALS")
mat_ctrl <- create_matrix("Control")

cat("MATRIZ ALS:\n")
cat("   Dimensiones:", nrow(mat_als), "miRNAs ×", ncol(mat_als), "posiciones\n")
cat("   Rango de valores:", round(min(mat_als), 6), "a", round(max(mat_als), 6), "\n\n")

cat("MATRIZ CONTROL:\n")
cat("   Dimensiones:", nrow(mat_ctrl), "miRNAs ×", ncol(mat_ctrl), "posiciones\n")
cat("   Rango de valores:", round(min(mat_ctrl), 6), "a", round(max(mat_ctrl), 6), "\n\n")

# Ejemplo de una fila
cat("EJEMPLO - Primera fila (", rownames(mat_als)[1], "):\n")
cat("   ALS VAF raw:", paste(round(mat_als[1, 1:10], 6), collapse = ", "), "...\n")
cat("   Control VAF raw:", paste(round(mat_ctrl[1, 1:10], 6), collapse = ", "), "...\n\n")

# ============================================================================
# PASO 3: COMBINAR MATRICES (CRÍTICO PARA ENTENDER)
# ============================================================================

cat("🔍 PASO 3: COMBINAR MATRICES ALS + CONTROL\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

combined_matrix <- rbind(mat_als, mat_ctrl)

cat("MATRIZ COMBINADA:\n")
cat("   Dimensiones:", nrow(combined_matrix), "filas ×", ncol(combined_matrix), "columnas\n")
cat("   Estructura:\n")
cat("      Filas 1-50: miRNAs en ALS\n")
cat("      Filas 51-100: MISMOS miRNAs en Control\n\n")

cat("   Ejemplo visual:\n")
cat("   ┌──────────────┬────┬────┬────┬─────┐\n")
cat("   │ miRNA        │ p1 │ p2 │ p3 │ ... │\n")
cat("   ├──────────────┼────┼────┼────┼─────┤\n")
cat("   │ let-7a (ALS) │0.01│0.02│0.01│ ... │  ← Fila 1\n")
cat("   │ miR-9 (ALS)  │0.02│0.00│0.03│ ... │  ← Fila 2\n")
cat("   │ ...          │... │... │... │ ... │\n")
cat("   │ let-7a(Ctrl) │0.02│0.03│0.02│ ... │  ← Fila 51 (MISMO miRNA)\n")
cat("   │ miR-9 (Ctrl) │0.03│0.01│0.04│ ... │  ← Fila 52\n")
cat("   └──────────────┴────┴────┴────┴─────┘\n\n")

cat("⚠️  OBSERVACIÓN CRÍTICA:\n")
cat("   Cada miRNA aparece DOS veces:\n")
cat("      - Una vez para ALS\n")
cat("      - Una vez para Control\n\n")

# ============================================================================
# PASO 4: CALCULAR Z-SCORE
# ============================================================================

cat("🔢 PASO 4: CALCULAR Z-SCORE\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

cat("CÓDIGO USADO:\n")
cat("   zscore_matrix <- t(scale(t(combined_matrix)))\n\n")

cat("DESGLOSANDO:\n")
cat("   1. t(combined_matrix)     → Transponer (filas ↔ columnas)\n")
cat("   2. scale(...)             → Calcular Z-score por COLUMNA\n")
cat("   3. t(...)                 → Transponer de vuelta\n\n")

cat("RESULTADO FINAL:\n")
cat("   scale() se aplica por FILA (por miRNA)\n\n")

# Calcular Z-score
zscore_matrix <- t(scale(t(combined_matrix)))
zscore_matrix[is.na(zscore_matrix) | is.infinite(zscore_matrix)] <- 0

cat("MATRIZ Z-SCORE:\n")
cat("   Dimensiones:", nrow(zscore_matrix), "filas ×", ncol(zscore_matrix), "columnas\n")
cat("   Rango de valores:", round(min(zscore_matrix), 2), "a", round(max(zscore_matrix), 2), "\n\n")

# Ejemplo de transformación
cat("EJEMPLO - Primera fila (", rownames(combined_matrix)[1], " ALS):\n")
cat("   VAF raw:    ", paste(round(combined_matrix[1, 1:10], 6), collapse = ", "), "...\n")
cat("   Z-scores:   ", paste(round(zscore_matrix[1, 1:10], 2), collapse = ", "), "...\n\n")

# Verificar media y SD
row_mean <- mean(zscore_matrix[1, ])
row_sd <- sd(zscore_matrix[1, ])
cat("   Verificación:\n")
cat("      Media de Z-scores:", round(row_mean, 6), "(debería ser ≈0)\n")
cat("      SD de Z-scores:", round(row_sd, 6), "(debería ser ≈1)\n\n")

# ============================================================================
# PASO 5: ANÁLISIS DE LA LÓGICA
# ============================================================================

cat("🔍 PASO 5: ANÁLISIS DE LA LÓGICA\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

cat("❓ PREGUNTA 1: ¿Qué normaliza el Z-score?\n\n")

cat("   RESPUESTA:\n")
cat("   El Z-score se calcula POR FILA (por cada miRNA)\n\n")

cat("   Esto significa:\n")
cat("      • Para let-7a (ALS): Normaliza entre posiciones 1-22 de let-7a en ALS\n")
cat("      • Para let-7a (Control): Normaliza entre posiciones 1-22 de let-7a en Control\n\n")

cat("   ⚠️  CRÍTICO:\n")
cat("      • let-7a(ALS) y let-7a(Control) se normalizan INDEPENDIENTEMENTE\n")
cat("      • NO se comparan entre sí directamente\n")
cat("      • Cada uno tiene su propia media = 0, SD = 1\n\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

cat("❓ PREGUNTA 2: ¿Qué información pierde la normalización?\n\n")

cat("   RESPUESTA:\n")
cat("   Pierde MAGNITUDES ABSOLUTAS\n\n")

cat("   Ejemplo:\n")
cat("      miRNA-A (ALS): VAF = [0.001, 0.002, 0.001, ...]\n")
cat("                     Media = 0.0013, SD = 0.0004\n")
cat("                     Z-scores: [-0.75, +1.25, -0.75, ...]\n\n")

cat("      miRNA-B (ALS): VAF = [0.100, 0.200, 0.100, ...]\n")
cat("                     Media = 0.13, SD = 0.04\n")
cat("                     Z-scores: [-0.75, +1.25, -0.75, ...] ← IDÉNTICOS!\n\n")

cat("   RESULTADO:\n")
cat("      • Dos miRNAs con VAF MUY diferentes (0.001 vs 0.100)\n")
cat("      • Pueden tener Z-scores IDÉNTICOS\n")
cat("      • Se pierde la información de MAGNITUD\n\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

cat("❓ PREGUNTA 3: ¿Qué compara entonces?\n\n")

cat("   RESPUESTA:\n")
cat("   Compara PATRONES RELATIVOS dentro de cada miRNA\n\n")

cat("   Pregunta que responde:\n")
cat("      'Para ESTE miRNA específico, ¿qué posiciones tienen\n")
cat("       VAF más alto/bajo relativo a su propio promedio?'\n\n")

cat("   NO responde:\n")
cat("      'Entre miRNAs, ¿cuál tiene más G>T?'\n")
cat("      'Entre ALS y Control, ¿cuál tiene más G>T?'\n\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

# ============================================================================
# ANÁLISIS DE ESTRUCTURA
# ============================================================================

cat("🏗️  PASO 6: ANÁLISIS DE ESTRUCTURA\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

cat("ESTRUCTURA DE LA FIGURA ACTUAL:\n\n")

cat("   Filas (100 total):\n")
cat("      1-50:   Top 50 miRNAs en ALS\n")
cat("      51-100: MISMOS 50 miRNAs en Control\n\n")

cat("   Columnas (22):\n")
cat("      1-22: Posiciones del miRNA\n\n")

cat("   Colores:\n")
cat("      Azul  (-3): Muy por debajo del promedio del miRNA\n")
cat("      Blanco (0): Promedio del miRNA\n")
cat("      Rojo  (+3): Muy por arriba del promedio del miRNA\n\n")

cat("   Clustering:\n")
cat("      cluster_cols = FALSE (posiciones NO reordenadas)\n")
cat("      cluster_rows = TRUE (miRNAs SÍ reordenados por similitud)\n\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

# ============================================================================
# PROBLEMAS LÓGICOS IDENTIFICADOS
# ============================================================================

cat("⚠️  PASO 7: PROBLEMAS LÓGICOS DETECTADOS\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

cat("PROBLEMA 1: NORMALIZACIÓN INDEPENDIENTE POR FILA\n\n")

cat("   Cada fila (miRNA en un grupo) se normaliza independientemente:\n")
cat("      • let-7a(ALS) normalizado a media=0, SD=1\n")
cat("      • let-7a(Control) normalizado a media=0, SD=1\n\n")

cat("   CONSECUENCIA:\n")
cat("      • NO puedes comparar directamente let-7a(ALS) vs let-7a(Control)\n")
cat("      • Rojo en ALS puede significar 0.002 (bajo absoluto)\n")
cat("      • Rojo en Control puede significar 0.020 (alto absoluto)\n")
cat("      • Pero ambos se ven igual de 'rojos' (Z-score alto)\n\n")

cat("   ¿ES ESTO UN PROBLEMA?\n")
cat("      ✓ Sí, si queremos comparar ALS vs Control\n")
cat("      ✓ No, si solo queremos ver patrones posicionales DENTRO de cada grupo\n\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

cat("PROBLEMA 2: DUPLICACIÓN DE miRNAs\n\n")

cat("   Cada miRNA aparece DOS veces (100 filas para 50 miRNAs):\n")
cat("      • Fila 1: let-7a en ALS\n")
cat("      • Fila 51: let-7a en Control (después de clustering)\n\n")

cat("   CONSECUENCIA:\n")
cat("      • El clustering puede separar let-7a(ALS) de let-7a(Control)\n")
cat("      • Dificulta comparación directa del MISMO miRNA entre grupos\n")
cat("      • Puede agrupar miRNAs diferentes si tienen patrón similar\n\n")

cat("   ¿ES ESTO UN PROBLEMA?\n")
cat("      ✓ Sí, si queremos ver ALS vs Control lado a lado\n")
cat("      ✓ No, si queremos clustering basado en patrón posicional\n\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

cat("PROBLEMA 3: ¿QUÉ PREGUNTA RESPONDE EXACTAMENTE?\n\n")

cat("   La figura actual responde:\n")
cat("      'Para cada miRNA en cada grupo, ¿qué posiciones tienen VAF\n")
cat("       desviado del promedio de ese miRNA?'\n\n")

cat("   PERO esto es complicado porque:\n")
cat("      • Mezcla información de ALS y Control en mismo heatmap\n")
cat("      • No compara directamente entre grupos\n")
cat("      • El clustering puede romper la correspondencia\n\n")

cat("   ¿Sería mejor responder?\n")
cat("      'Para cada posición, ¿qué miRNAs tienen VAF desviado?'\n")
cat("      O: 'Entre ALS y Control, ¿hay diferencias en patrones posicionales?'\n\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

# ============================================================================
# ANÁLISIS CUANTITATIVO
# ============================================================================

cat("📊 PASO 8: ANÁLISIS CUANTITATIVO DE Z-SCORES\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

# Separar Z-scores de ALS y Control
zscore_als <- zscore_matrix[1:50, ]
zscore_ctrl <- zscore_matrix[51:100, ]

cat("Z-SCORES ALS:\n")
cat("   Media global:", round(mean(zscore_als), 4), "(debería ser ≈0)\n")
cat("   SD global:", round(sd(zscore_als), 4), "\n")
cat("   Min:", round(min(zscore_als), 2), "\n")
cat("   Max:", round(max(zscore_als), 2), "\n\n")

cat("Z-SCORES CONTROL:\n")
cat("   Media global:", round(mean(zscore_ctrl), 4), "(debería ser ≈0)\n")
cat("   SD global:", round(sd(zscore_ctrl), 4), "\n")
cat("   Min:", round(min(zscore_ctrl), 2), "\n")
cat("   Max:", round(max(zscore_ctrl), 2), "\n\n")

# Hotspots por posición
cat("HOTSPOTS POR POSICIÓN (promedio de |Z-score|):\n\n")

pos_zscore_summary <- data.frame()
for (pos_idx in 1:22) {
  als_col <- abs(zscore_als[, pos_idx])
  ctrl_col <- abs(zscore_ctrl[, pos_idx])
  
  pos_zscore_summary <- rbind(pos_zscore_summary, data.frame(
    Position = pos_idx,
    Mean_absZ_ALS = mean(als_col, na.rm = TRUE),
    Mean_absZ_Control = mean(ctrl_col, na.rm = TRUE)
  ))
}

cat("Posiciones con mayor desviación (top 5):\n\n")
cat("ALS:\n")
top_als_pos <- pos_zscore_summary %>% arrange(desc(Mean_absZ_ALS)) %>% head(5)
print(top_als_pos)
cat("\n")

cat("Control:\n")
top_ctrl_pos <- pos_zscore_summary %>% arrange(desc(Mean_absZ_Control)) %>% head(5)
print(top_ctrl_pos)
cat("\n")

# ============================================================================
# EVALUACIÓN DE UTILIDAD
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("💡 EVALUACIÓN: ¿ESTA FIGURA ES ÚTIL?\n")
cat("\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

cat("VENTAJAS:\n")
cat("   ✓ Normaliza para comparar miRNAs con VAF muy diferentes\n")
cat("   ✓ Detecta patrones posicionales consistentes\n")
cat("   ✓ Útil para clustering basado en PATRÓN (no magnitud)\n\n")

cat("DESVENTAJAS:\n")
cat("   ✗ NO compara directamente ALS vs Control\n")
cat("   ✗ Pierde información de magnitud absoluta\n")
cat("   ✗ Puede ser confuso (100 filas para 50 miRNAs)\n")
cat("   ✗ Normalización independiente dificulta interpretación\n\n")

cat("REDUNDANCIA CON FIG 2.4:\n")
if (cor(as.vector(combined_matrix), as.vector(zscore_matrix), use = "complete.obs") > 0.9) {
  cat("   ⚠️  ALTA correlación con Fig 2.4 (raw values)\n")
  cat("   → Los patrones son muy similares\n")
  cat("   → Posiblemente redundante\n\n")
} else {
  cat("   ✓ BAJA correlación con Fig 2.4\n")
  cat("   → Z-score revela patrones diferentes\n")
  cat("   → Complementaria\n\n")
}

# ============================================================================
# RECOMENDACIONES
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("🎯 RECOMENDACIONES:\n")
cat("\n")

cat("OPCIÓN 1: ELIMINAR ESTA FIGURA\n")
cat("   • Si es redundante con Fig 2.4\n")
cat("   • Si no aporta información nueva\n")
cat("   • Si complica la interpretación\n\n")

cat("OPCIÓN 2: MODIFICAR LA LÓGICA\n")
cat("   • Calcular Z-score POR COLUMNA (por posición)\n")
cat("   • En vez de por fila (por miRNA)\n")
cat("   • Permitiría comparar ALS vs Control directamente\n\n")

cat("OPCIÓN 3: SIMPLIFICAR\n")
cat("   • Z-score del resumen agregado (1 fila ALS, 1 fila Control)\n")
cat("   • En vez de 100 filas\n")
cat("   • Más claro y directo\n\n")

cat("OPCIÓN 4: CAMBIAR A DIFERENCIA (ALS - Control)\n")
cat("   • En vez de Z-score por fila\n")
cat("   • Calcular: VAF_ALS - VAF_Control por posición y miRNA\n")
cat("   • Muestra DIRECTAMENTE las diferencias entre grupos\n\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("✅ ANÁLISIS COMPLETADO\n")
cat("\n")
cat("PROBLEMAS IDENTIFICADOS:\n")
cat("   1. Normalización independiente por fila\n")
cat("   2. Duplicación de miRNAs (100 filas para 50 miRNAs)\n")
cat("   3. No compara directamente ALS vs Control\n")
cat("   4. Posible redundancia con Fig 2.4\n\n")

cat("DECISIÓN NECESARIA:\n")
cat("   ¿Eliminar, modificar, o mantener?\n")
cat("\n")

