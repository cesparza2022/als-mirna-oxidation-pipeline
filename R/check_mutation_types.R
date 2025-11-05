# =============================================================================
# VERIFICAR TIPOS DE MUTACIONES DISPONIBLES
# =============================================================================
# Script para verificar qué tipos de mutaciones están disponibles en los datos
# =============================================================================

# Cargar librerías
library(dplyr)
library(stringr)

cat("🔍 VERIFICACIÓN DE TIPOS DE MUTACIONES\n")
cat("=====================================\n\n")

# --- 1. CARGAR DATOS ---
cat("📊 1. CARGANDO DATOS\n")
cat("===================\n")

# Cargar datos principales
df_main <- read.csv("organized/04_results/alex_df.csv", stringsAsFactors = FALSE)

cat("✅ Datos cargados:\n")
cat("   - df_main:", nrow(df_main), "filas\n")
cat("   - Columnas:", ncol(df_main), "\n\n")

# --- 2. VERIFICAR COLUMNAS ---
cat("📋 2. VERIFICAR COLUMNAS\n")
cat("=======================\n")

cat("Primeras 10 columnas:\n")
print(names(df_main)[1:10])

cat("\nÚltimas 10 columnas:\n")
print(names(df_main)[(ncol(df_main)-9):ncol(df_main)])

# --- 3. VERIFICAR TIPOS DE MUTACIONES ---
cat("\n🧬 3. VERIFICAR TIPOS DE MUTACIONES\n")
cat("===================================\n")

# Verificar si existe la columna pos.mut
if ("pos.mut" %in% names(df_main)) {
  cat("✅ Columna 'pos.mut' encontrada\n")
  
  # Mostrar algunos ejemplos
  cat("\nPrimeros 10 ejemplos de pos.mut:\n")
  print(head(df_main$pos.mut, 10))
  
  # Extraer tipos de mutaciones
  mutation_types <- df_main %>%
    mutate(mutation = str_extract(pos.mut, "[A-Z]>[A-Z]$")) %>%
    filter(!is.na(mutation)) %>%
    count(mutation, sort = TRUE)
  
  cat("\n📊 TIPOS DE MUTACIONES ENCONTRADAS:\n")
  print(mutation_types)
  
  # Verificar si hay G>T
  gt_count <- mutation_types %>% filter(mutation == "G>T") %>% pull(n)
  if (length(gt_count) > 0) {
    cat("\n✅ Mutaciones G>T encontradas:", gt_count, "\n")
  } else {
    cat("\n❌ NO se encontraron mutaciones G>T\n")
  }
  
} else {
  cat("❌ Columna 'pos.mut' NO encontrada\n")
  
  # Buscar columnas similares
  similar_cols <- names(df_main)[str_detect(names(df_main), "pos|mut")]
  cat("\nColumnas similares encontradas:\n")
  print(similar_cols)
}

# --- 4. VERIFICAR ESTRUCTURA DE DATOS ---
cat("\n🔍 4. VERIFICAR ESTRUCTURA DE DATOS\n")
cat("===================================\n")

cat("Primeras 5 filas del dataset:\n")
print(head(df_main, 5))

cat("\nEstructura del dataset:\n")
str(df_main)

cat("\n✅ Verificación completada!\n")










