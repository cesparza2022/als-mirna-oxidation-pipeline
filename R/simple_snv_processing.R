# Script simple para procesar SNVs múltiples preservando pos:mut

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

# Verificar que la columna pos:mut existe
cat("   📊 Columnas disponibles:", paste(colnames(df_original)[1:5], collapse = ", "), "\n")

# Filtrar solo filas con SNVs (no PM) usando base R
cat("\n🔧 Filtrando SNVs (no PM)...\n")
df_snvs <- df_original[df_original[["pos.mut"]] != "PM", ]
cat("   📊 Filas con SNVs:", nrow(df_snvs), "\n")

# Verificar algunos valores de pos:mut
cat("   📋 Ejemplos de pos:mut:\n")
print(head(df_original[["pos.mut"]], 10))

# Identificar filas con múltiples SNVs (contienen coma)
cat("\n🔧 Identificando SNVs múltiples...\n")
multiple_snv_indices <- grep(",", df_snvs[["pos.mut"]])
cat("   📊 Filas con SNVs múltiples:", length(multiple_snv_indices), "\n")

if (length(multiple_snv_indices) > 0) {
  cat("   📋 Ejemplos de SNVs múltiples:\n")
  print(head(df_snvs[multiple_snv_indices, c("miRNA.name", "pos.mut")], 5))
  
  # Separar múltiples SNVs
  cat("\n🔧 Separando SNVs múltiples...\n")
  separated_rows_list <- list()
  
  for (i in multiple_snv_indices) {
    row <- df_snvs[i, ]
    snv_list <- str_split(row[["pos.mut"]], ",")[[1]]
    snv_list <- str_trim(snv_list)
    
    # Crear una fila para cada SNV
    for (snv in snv_list) {
      new_row <- row
      new_row[["pos.mut"]] <- snv
      separated_rows_list[[length(separated_rows_list) + 1]] <- new_row
    }
  }
  
  # Convertir lista a data frame
  separated_rows <- do.call(rbind, separated_rows_list)
  cat("   📊 Filas separadas:", nrow(separated_rows), "\n")
  
  # Filas con SNVs únicos (sin coma)
  single_snv_indices <- setdiff(1:nrow(df_snvs), multiple_snv_indices)
  single_snv_rows <- df_snvs[single_snv_indices, ]
  cat("   📊 Filas con SNVs únicos:", nrow(single_snv_rows), "\n")
  
  # Combinar filas únicas y separadas
  df_combined <- rbind(single_snv_rows, separated_rows)
  cat("   📊 Total filas después de separación:", nrow(df_combined), "\n")
  
} else {
  cat("   ✅ No hay SNVs múltiples para separar\n")
  df_combined <- df_snvs
}

# Ahora usar dplyr para agrupar y sumar
cat("\n🔧 Agrupando y sumando cuentas por miRNA y SNV...\n")
df_processed <- df_combined %>%
  group_by(!!sym("miRNA.name"), !!sym("pos.mut")) %>%
  summarise(
    # Sumar columnas SNV
    across(all_of(snv_cols), ~ sum(.x, na.rm = TRUE)),
    # Tomar primer valor de totales (no sumar)
    across(all_of(total_cols), ~ first(.x)),
    .groups = "drop"
  )

cat("   ✅ Procesamiento completado!\n")
cat("   📊 Filas originales:", nrow(df_original), "\n")
cat("   📊 Filas procesadas:", nrow(df_processed), "\n")
cat("   📊 miRNAs únicos:", n_distinct(df_processed[["miRNA.name"]]), "\n")

# Guardar el dataset procesado
output_path <- "/Users/cesaresparza/New_Desktop/UCSD/8OG/outputs/processed_mirna_dataset_simple.tsv"
cat("\n💾 Guardando dataset procesado...\n")
write.table(df_processed, output_path, sep = "\t", row.names = FALSE, quote = FALSE)

# Verificar que pos:mut se preservó
cat("\n🔍 Verificando preservación de pos:mut...\n")
cat("   📊 Columnas en dataset procesado:", ncol(df_processed), "\n")
cat("   📊 Primeras columnas:", paste(colnames(df_processed)[1:5], collapse = ", "), "\n")

# Mostrar algunos ejemplos de pos:mut
cat("\n📋 Ejemplos de pos:mut preservados:\n")
print(head(df_processed[c("miRNA.name", "pos.mut")], 10))

# Contar tipos de mutaciones
mutation_types <- df_processed %>%
  separate(!!sym("pos.mut"), into = c("position", "mutation_type"), sep = ":", remove = FALSE) %>%
  count(mutation_type, sort = TRUE)

cat("\n📊 Tipos de mutaciones encontradas:\n")
print(mutation_types)

cat("\n🎉 Procesamiento simple completado!\n")
cat("   Archivo guardado: outputs/processed_mirna_dataset_simple.tsv\n")
