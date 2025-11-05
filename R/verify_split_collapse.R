#!/usr/bin/env Rscript

# =============================================================================
# VERIFICAR SI EL SPLIT Y COLLAPSE SE HICIERON CORRECTAMENTE
# =============================================================================

library(dplyr)
library(readr)
library(stringr)
library(tidyr)

cat("=== VERIFICACIÓN DE SPLIT Y COLLAPSE ===\n\n")

# --- PASO 1: Cargar datos ---
cat("PASO 1: Cargando datos\n")
cat("==========================================\n")

df_main <- read_tsv("results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt", show_col_types = FALSE)
df_main <- df_main[-1, ]  # Remover metadatos

sample_cols <- names(df_main)[!names(df_main) %in% c("miRNA name", "pos:mut")]

cat(paste0("  - Muestras totales: ", length(sample_cols), "\n"))
cat(paste0("  - Filas originales: ", nrow(df_main), "\n\n"))

# --- PASO 2: Identificar filas con múltiples mutaciones ---
cat("PASO 2: Identificando filas con múltiples mutaciones\n")
cat("==========================================\n")

# Buscar filas que contienen comas (múltiples mutaciones)
multi_mutation_rows <- df_main %>%
  filter(str_detect(`pos:mut`, ","))

cat(paste0("  - Filas con múltiples mutaciones: ", nrow(multi_mutation_rows), "\n"))

if (nrow(multi_mutation_rows) > 0) {
  cat("  - Ejemplos de filas con múltiples mutaciones:\n")
  print(multi_mutation_rows %>% 
    select(`miRNA name`, `pos:mut`) %>% 
    head(5))
}

# --- PASO 3: Verificar el proceso de SPLIT ---
cat("\nPASO 3: Verificando el proceso de SPLIT\n")
cat("==========================================\n")

# Función para hacer split correcto
split_mutations <- function(row_data) {
  pos_mut <- row_data$`pos:mut`
  miRNA_name <- row_data$`miRNA name`
  
  # Dividir por comas
  mutations <- str_split(pos_mut, ",")[[1]]
  mutations <- str_trim(mutations)
  
  if (length(mutations) == 1) {
    # Solo una mutación, devolver la fila original
    return(row_data)
  } else {
    # Múltiples mutaciones, crear una fila para cada una
    result_rows <- list()
    for (mut in mutations) {
      new_row <- row_data
      new_row$`pos:mut` <- mut
      result_rows[[length(result_rows) + 1]] <- new_row
    }
    return(bind_rows(result_rows))
  }
}

# Aplicar split a todas las filas
df_split_list <- list()
for (i in 1:nrow(df_main)) {
  split_result <- split_mutations(df_main[i, ])
  df_split_list[[length(df_split_list) + 1]] <- split_result
}

df_split <- bind_rows(df_split_list)
cat(paste0("  - Filas después del SPLIT: ", nrow(df_split), "\n"))
cat(paste0("  - Incremento: +", nrow(df_split) - nrow(df_main), " filas\n"))

# Verificar que no hay más comas
remaining_commas <- sum(str_detect(df_split$`pos:mut`, ","))
cat(paste0("  - Filas con comas restantes: ", remaining_commas, "\n"))

# --- PASO 4: Verificar el proceso de COLLAPSE ---
cat("\nPASO 4: Verificando el proceso de COLLAPSE\n")
cat("==========================================\n")

# Contar combinaciones únicas de miRNA + pos:mut antes del collapse
unique_combinations_before <- df_split %>%
  select(`miRNA name`, `pos:mut`) %>%
  distinct() %>%
  nrow()

cat(paste0("  - Combinaciones únicas miRNA+pos:mut antes del collapse: ", unique_combinations_before, "\n"))

# Aplicar collapse
df_collapsed <- df_split %>%
  group_by(`miRNA name`, `pos:mut`) %>%
  summarise(
    across(all_of(sample_cols), ~ sum(as.numeric(.x), na.rm = TRUE)),
    .groups = "drop"
  )

cat(paste0("  - Filas después del COLLAPSE: ", nrow(df_collapsed), "\n"))
cat(paste0("  - Reducción: -", nrow(df_split) - nrow(df_collapsed), " filas\n"))

# Verificar que el número de filas después del collapse es igual al número de combinaciones únicas
if (nrow(df_collapsed) == unique_combinations_before) {
  cat("  ✅ COLLAPSE CORRECTO: Número de filas = número de combinaciones únicas\n")
} else {
  cat("  ❌ ERROR EN COLLAPSE: Número de filas ≠ número de combinaciones únicas\n")
}

# --- PASO 5: Verificar con ejemplos específicos ---
cat("\nPASO 5: Verificando con ejemplos específicos\n")
cat("==========================================\n")

# Buscar un miRNA que tenga múltiples mutaciones
example_miRNA <- df_main %>%
  filter(str_detect(`pos:mut`, ",")) %>%
  slice(1) %>%
  pull(`miRNA name`)

if (!is.na(example_miRNA)) {
  cat(paste0("  - Ejemplo con miRNA: ", example_miRNA, "\n"))
  
  # Mostrar filas originales
  original_rows <- df_main %>%
    filter(`miRNA name` == example_miRNA)
  
  cat("  - Filas originales:\n")
  print(original_rows %>% select(`miRNA name`, `pos:mut`))
  
  # Mostrar filas después del split
  split_rows <- df_split %>%
    filter(`miRNA name` == example_miRNA)
  
  cat("  - Filas después del SPLIT:\n")
  print(split_rows %>% select(`miRNA name`, `pos:mut`))
  
  # Mostrar filas después del collapse
  collapsed_rows <- df_collapsed %>%
    filter(`miRNA name` == example_miRNA)
  
  cat("  - Filas después del COLLAPSE:\n")
  print(collapsed_rows %>% select(`miRNA name`, `pos:mut`))
  
  # Verificar que las sumas son correctas
  cat("  - Verificando sumas de conteos:\n")
  for (i in 1:nrow(collapsed_rows)) {
    pos_mut <- collapsed_rows$`pos:mut`[i]
    split_counts <- split_rows %>%
      filter(`pos:mut` == pos_mut) %>%
      select(all_of(sample_cols[1:3]))  # Solo primeras 3 muestras para verificar
    
    collapsed_counts <- collapsed_rows %>%
      filter(`pos:mut` == pos_mut) %>%
      select(all_of(sample_cols[1:3]))
    
    cat(paste0("    ", pos_mut, ":\n"))
    for (col in sample_cols[1:3]) {
      split_sum <- sum(split_counts[[col]], na.rm = TRUE)
      collapsed_val <- collapsed_counts[[col]]
      if (split_sum == collapsed_val) {
        cat(paste0("      ✅ ", col, ": ", split_sum, " = ", collapsed_val, "\n"))
      } else {
        cat(paste0("      ❌ ", col, ": ", split_sum, " ≠ ", collapsed_val, "\n"))
      }
    }
  }
}

# --- PASO 6: Resumen final ---
cat("\nPASO 6: Resumen final\n")
cat("==========================================\n")

cat("VERIFICACIÓN COMPLETA:\n")
cat(paste0("- Filas originales: ", nrow(df_main), "\n"))
cat(paste0("- Filas después del SPLIT: ", nrow(df_split), "\n"))
cat(paste0("- Filas después del COLLAPSE: ", nrow(df_collapsed), "\n"))
cat(paste0("- Combinaciones únicas: ", unique_combinations_before, "\n"))
cat(paste0("- Filas con comas restantes: ", remaining_commas, "\n\n"))

if (nrow(df_collapsed) == unique_combinations_before && remaining_commas == 0) {
  cat("✅ PROCESO DE SPLIT Y COLLAPSE CORRECTO\n")
} else {
  cat("❌ ERROR EN EL PROCESO DE SPLIT Y COLLAPSE\n")
}

cat("\n=== VERIFICACIÓN COMPLETADA ===\n")










