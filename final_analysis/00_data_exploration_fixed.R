# Cargar librerías
library(dplyr)
library(tidyr)
library(stringr)

# Cargar datos iniciales
cat('📊 CARGANDO DATOS INICIALES (CORREGIDO)\n')
cat('=======================================\n')

# Leer el archivo original con header=FALSE para ver la estructura real
data_raw <- read.csv('/Users/cesaresparza/New_Desktop/UCSD/8OG/results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt', 
                     sep = '\t', stringsAsFactors = FALSE, header = FALSE)

cat('Datos raw cargados:\n')
cat(paste0('  - Filas: ', nrow(data_raw), '\n'))
cat(paste0('  - Columnas: ', ncol(data_raw), '\n\n'))

# Ver las primeras filas para entender la estructura
cat('Primeras 5 filas (raw):\n')
print(head(data_raw, 5))
cat('\n')

# Leer con header=TRUE para ver si funciona
data_header <- read.csv('/Users/cesaresparza/New_Desktop/UCSD/8OG/results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt', 
                        sep = '\t', stringsAsFactors = FALSE, header = TRUE)

cat('Datos con header cargados:\n')
cat(paste0('  - Filas: ', nrow(data_header), '\n'))
cat(paste0('  - Columnas: ', ncol(data_header), '\n'))
cat(paste0('  - Nombres de columnas: ', paste(names(data_header)[1:5], collapse = ', '), '\n\n'))

# Ver las primeras filas
cat('Primeras 3 filas (con header):\n')
print(head(data_header, 3))
cat('\n')

# Verificar si hay columna miRNA_name
if('miRNA_name' %in% names(data_header)) {
  cat('✅ Columna miRNA_name encontrada\n')
  cat(paste0('  - Valores únicos: ', length(unique(data_header$miRNA_name)), '\n'))
} else {
  cat('❌ Columna miRNA_name NO encontrada\n')
  cat('  - Columnas disponibles: ', paste(names(data_header)[1:10], collapse = ', '), '\n')
}

# Verificar columna pos.mut
if('pos.mut' %in% names(data_header)) {
  cat('✅ Columna pos.mut encontrada\n')
  cat(paste0('  - Valores únicos: ', length(unique(data_header$pos.mut)), '\n'))
} else {
  cat('❌ Columna pos.mut NO encontrada\n')
}

# Buscar mutaciones G>T
if('pos.mut' %in% names(data_header)) {
  gt_mutations <- data_header$pos.mut[grepl('G>T', data_header$pos.mut)]
  cat(paste0('  - Mutations G>T: ', length(gt_mutations), '\n'))
  if(length(gt_mutations) > 0) {
    cat('  - Ejemplos G>T: ', paste(head(unique(gt_mutations), 5), collapse = ', '), '\n')
  }
}

cat('\n')









