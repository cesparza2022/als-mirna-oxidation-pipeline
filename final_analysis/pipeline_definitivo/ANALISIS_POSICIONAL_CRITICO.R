#!/usr/bin/env Rscript
# ============================================================================
# ANÁLISIS CRÍTICO: ¿HAY ENRIQUECIMIENTO POR POSICIÓN?
# Responde: "¿Se agrupan en oxidación por posición?"
# ============================================================================

library(dplyr)
library(readr)
library(stringr)
library(tidyr)
library(purrr)

cat("\n")
cat("╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║     🔬 ANÁLISIS POSICIONAL: ¿Posiciones específicas enriquecidas?   ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

# ============================================================================
# CARGAR DATOS
# ============================================================================

data <- read_csv("pipeline_2/final_processed_data_CLEAN.csv", show_col_types = FALSE)
metadata <- read_csv("pipeline_2/metadata.csv", show_col_types = FALSE)

# Filtrar solo G>T en seed
data_gt_seed <- data %>%
  filter(str_detect(pos.mut, "^[2-8]:GT$"))

cat(sprintf("📊 Total SNVs G>T en seed: %d\n", nrow(data_gt_seed)))
cat(sprintf("📊 Total miRNAs: %d\n\n", n_distinct(data_gt_seed$miRNA_name)))

# ============================================================================
# ANÁLISIS POR POSICIÓN
# ============================================================================

cat("🎯 ANALIZANDO CADA POSICIÓN (2-8):\n")
cat(paste(rep("═", 70), collapse = ""), "\n\n")

# Convertir a long format
data_long <- data_gt_seed %>%
  mutate(Position = as.integer(str_extract(pos.mut, "^\\d+"))) %>%
  pivot_longer(cols = -c(miRNA_name, pos.mut, Position), 
               names_to = "Sample_ID", 
               values_to = "VAF") %>%
  filter(!is.na(VAF)) %>%
  left_join(metadata, by = "Sample_ID")

# Test por posición
position_results <- map_df(2:8, function(pos) {
  
  cat(sprintf("Posición %d:\n", pos))
  cat(paste(rep("─", 70), collapse = ""), "\n")
  
  # Datos de esta posición
  pos_data <- data_long %>% filter(Position == pos)
  
  # Separar por grupo
  als_vals <- pos_data %>% filter(Group == "ALS") %>% pull(VAF)
  ctrl_vals <- pos_data %>% filter(Group == "Control") %>% pull(VAF)
  
  # Test
  if (length(als_vals) > 0 && length(ctrl_vals) > 0) {
    test <- wilcox.test(als_vals, ctrl_vals)
    
    result <- data.frame(
      Position = pos,
      N_miRNAs = n_distinct(pos_data$miRNA_name),
      N_SNVs = nrow(data_gt_seed %>% filter(str_detect(pos.mut, paste0("^", pos, ":")))),
      Mean_ALS = mean(als_vals, na.rm = TRUE),
      Mean_Control = mean(ctrl_vals, na.rm = TRUE),
      FC = mean(als_vals, na.rm = TRUE) / mean(ctrl_vals, na.rm = TRUE),
      p_value = test$p.value,
      N_ALS_samples = length(als_vals),
      N_Control_samples = length(ctrl_vals)
    )
    
    cat(sprintf("   miRNAs: %d | SNVs: %d\n", result$N_miRNAs, result$N_SNVs))
    cat(sprintf("   Mean ALS: %.5f | Mean Control: %.5f\n", result$Mean_ALS, result$Mean_Control))
    cat(sprintf("   FC: %.2fx | p-value: %.4f", result$FC, result$p_value))
    
    if (result$p_value < 0.05) {
      cat(" ✅ SIGNIFICATIVO\n")
    } else {
      cat(" ❌ No significativo\n")
    }
    cat("\n")
    
    return(result)
  } else {
    cat("   ⚠️ Sin datos suficientes\n\n")
    return(NULL)
  }
})

# Limpiar NULLs
position_results <- bind_rows(position_results)

# ============================================================================
# RESULTADOS
# ============================================================================

cat(paste(rep("═", 70), collapse = ""), "\n")
cat("✅ RESUMEN POR POSICIÓN\n")
cat(paste(rep("═", 70), collapse = ""), "\n\n")

position_results <- position_results %>%
  mutate(
    Significant = ifelse(p_value < 0.05, "✅", "❌"),
    log2FC = round(log2(FC), 2)
  ) %>%
  arrange(Position)

print(position_results %>% select(Position, N_miRNAs, N_SNVs, FC, p_value, Significant))

# Identificar posiciones enriquecidas
enriched_positions <- position_results %>%
  filter(p_value < 0.05, FC > 1.2)

cat("\n")
cat(paste(rep("═", 70), collapse = ""), "\n")
cat("🔥 POSICIONES ENRIQUECIDAS EN ALS:\n")
cat(paste(rep("═", 70), collapse = ""), "\n\n")

if (nrow(enriched_positions) > 0) {
  cat("✅ Encontradas", nrow(enriched_positions), "posiciones enriquecidas:\n\n")
  
  for (i in 1:nrow(enriched_positions)) {
    pos <- enriched_positions[i, ]
    cat(sprintf("Posición %d:\n", pos$Position))
    cat(sprintf("   • %d miRNAs afectados\n", pos$N_miRNAs))
    cat(sprintf("   • FC %.2fx (ALS > Control)\n", pos$FC))
    cat(sprintf("   • p = %.4f ✅\n", pos$p_value))
    cat("\n")
  }
  
  cat("💡 INTERPRETACIÓN:\n")
  cat("   → Hay PATRÓN POSICIONAL específico\n")
  cat("   → La oxidación NO es aleatoria\n")
  cat("   → Posiciones", paste(enriched_positions$Position, collapse = ", "), "son vulnerables\n\n")
  
  cat("🎯 RECOMENDACIÓN:\n")
  cat("   → Priorizar miRNAs con G>T en posiciones:", paste(enriched_positions$Position, collapse = ", "), "\n")
  cat("   → Analizar secuencias alrededor de estas posiciones\n")
  cat("   → Buscar motivos conservados (GpG, CpG)\n\n")
  
} else {
  cat("⚠️ NO se encontraron posiciones específicamente enriquecidas\n\n")
  cat("💡 INTERPRETACIÓN:\n")
  cat("   → La oxidación es uniforme por toda la seed\n")
  cat("   → O la muestra es pequeña para detectar diferencias\n\n")
  
  cat("🎯 RECOMENDACIÓN:\n")
  cat("   → Usar Volcano Plot a nivel miRNA (método actual)\n")
  cat("   → No filtrar por posición\n\n")
}

# ============================================================================
# GUARDAR RESULTADOS
# ============================================================================

write_csv(position_results, "POSITIONAL_ENRICHMENT_RESULTS.csv")

cat(paste(rep("═", 70), collapse = ""), "\n")
cat("📁 Resultados guardados en: POSITIONAL_ENRICHMENT_RESULTS.csv\n")
cat(paste(rep("═", 70), collapse = ""), "\n\n")

cat("🚀 SIGUIENTE:\n")
cat("   Si hay posiciones enriquecidas:\n")
cat("     → Crear filtro adicional por posición\n")
cat("     → Analizar contexto de secuencia (GpG)\n\n")

