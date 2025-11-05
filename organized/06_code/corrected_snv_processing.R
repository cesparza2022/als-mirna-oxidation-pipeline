# Script corregido para procesar SNVs múltiples preservando pos:mut

library(dplyr)
library(stringr)
library(tidyr)

# Cargar el dataset original
cat("📁 Cargando dataset original...\n")
df_original <- read.delim("/Users/cesaresparza/New_Desktop/UCSD/8OG/results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt", 
                         stringsAsFactors = FALSE)

cat("   📊 Dataset original:", nrow(df_original), "x", ncol(df_original), "\n")

# Definir columnas
snv_cols <- colnames(df_original)[3:417]  # SNV counts
total_cols <- colnames(df_original)[418:832]  # Total counts

cat("   📊 Columnas SNV:", length(snv_cols), "\n")
cat("   📊 Columnas TOTAL:", length(total_cols), "\n")

# Función corregida para separar SNVs múltiples preservando pos:mut
separate_multiple_snvs_corrected <- function(df) {
  cat("🔧 Separando SNVs múltiples preservando pos:mut...\n")
  
  # Filtrar solo filas con SNVs (no PM)
  df_snvs <- df %>%
    filter(df[["pos:mut"]] != "PM")
  
  # Identificar filas con múltiples SNVs (contienen coma)
  multiple_snv_rows <- df_snvs %>%
    filter(str_detect(df[["pos:mut"]], ","))
  
  cat("   📊 Filas con SNVs múltiples:", nrow(multiple_snv_rows), "\n")
  
  if (nrow(multiple_snv_rows) == 0) {
    cat("   ✅ No hay SNVs múltiples para separar\n")
    return(df_snvs)
  }
  
  # Separar múltiples SNVs
  separated_rows <- multiple_snv_rows %>%
    separate_rows(!!sym("pos:mut"), sep = ",") %>%
    mutate(!!sym("pos:mut") := str_trim(!!sym("pos:mut")))  # Limpiar espacios
  
  # Filas con SNVs únicos (sin coma)
  single_snv_rows <- df_snvs %>%
    filter(!str_detect(df[["pos:mut"]], ","))
  
  # Combinar filas únicas y separadas
  result <- bind_rows(single_snv_rows, separated_rows) %>%
    arrange(!!sym("miRNA name"), !!sym("pos:mut"))
  
  cat("   ✅ SNVs separados exitosamente\n")
  cat("   📊 Total filas después de separación:", nrow(result), "\n")
  
  return(result)
}

# Función corregida para sumar cuentas de SNVs por miRNA
sum_snv_counts_by_mirna_corrected <- function(df) {
  cat("🔧 Sumando cuentas de SNVs por miRNA...\n")
  
  # Agrupar por miRNA y sumar solo columnas SNV
  result <- df %>%
    group_by(!!sym("miRNA name"), !!sym("pos:mut")) %>% # Agrupar por miRNA y SNV para sumar cuentas de cada SNV único
    summarise(
      # Sumar columnas SNV
      across(all_of(snv_cols), ~ sum(.x, na.rm = TRUE)),
      # Tomar primer valor de totales (no sumar)
      across(all_of(total_cols), ~ first(.x)),
      .groups = "drop"
    )
  
  cat("   ✅ Cuentas sumadas exitosamente\n")
  cat("   📊 miRNAs únicos:", n_distinct(result[["miRNA name"]]), "\n")
  cat("   📊 SNVs únicos:", nrow(result), "\n")
  
  return(result)
}

# Procesar el dataset
cat("\n🚀 Procesando dataset completo...\n")

# Paso 1: Separar SNVs múltiples
df_separated <- separate_multiple_snvs_corrected(df_original)

# Paso 2: Sumar cuentas de SNVs por miRNA
df_processed <- sum_snv_counts_by_mirna_corrected(df_separated)

cat("\n✅ Procesamiento completado!\n")
cat("   📊 Filas originales:", nrow(df_original), "\n")
cat("   📊 Filas procesadas:", nrow(df_processed), "\n")
cat("   📊 miRNAs únicos:", n_distinct(df_processed[["miRNA name"]]), "\n")

# Guardar el dataset procesado
output_path <- "/Users/cesaresparza/New_Desktop/UCSD/8OG/outputs/processed_mirna_dataset_corrected.tsv"
cat("\n💾 Guardando dataset procesado corregido...\n")
write.table(df_processed, output_path, sep = "\t", row.names = FALSE, quote = FALSE)

# Verificar que pos:mut se preservó
cat("\n🔍 Verificando preservación de pos:mut...\n")
cat("   📊 Columnas en dataset procesado:", ncol(df_processed), "\n")
cat("   📊 Primeras columnas:", paste(colnames(df_processed)[1:5], collapse = ", "), "\n")

# Mostrar algunos ejemplos de pos:mut
cat("\n📋 Ejemplos de pos:mut preservados:\n")
print(head(df_processed[c("miRNA name", "pos:mut")], 10))

# Contar tipos de mutaciones
mutation_types <- df_processed %>%
  separate(!!sym("pos:mut"), into = c("position", "mutation_type"), sep = ":", remove = FALSE) %>%
  count(mutation_type, sort = TRUE)

cat("\n📊 Tipos de mutaciones encontradas:\n")
print(mutation_types)

cat("\n🎉 Procesamiento corregido completado!\n")
cat("   Archivo guardado: outputs/processed_mirna_dataset_corrected.tsv\n")
