# Cargar librerías
library(dplyr)
library(tidyr)
library(stringr)

# Cargar datos iniciales
cat('📊 CARGANDO DATOS INICIALES\n')
cat('==========================\n')

# Leer el archivo original
data <- read.csv('/Users/cesaresparza/New_Desktop/UCSD/8OG/results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt', 
                 sep = '\t', stringsAsFactors = FALSE)

cat('Datos iniciales cargados:\n')
cat(paste0('  - Filas: ', nrow(data), '\n'))
cat(paste0('  - Columnas: ', ncol(data), '\n'))
cat(paste0('  - Nombres de columnas: ', paste(names(data)[1:5], collapse = ', '), '...\n\n'))

# Mostrar primeras filas
cat('Primeras 3 filas:\n')
print(head(data, 3))
cat('\n')

# Identificar columnas de conteo y total
count_cols <- names(data)[grepl('^[^.]+\\.(PM|1MM|2MM)$', names(data))]
total_cols <- names(data)[grepl('^[^.]+\\.(PM|1MM|2MM)\\.$', names(data))]

cat('Columnas identificadas:\n')
cat(paste0('  - Columnas de conteo: ', length(count_cols), '\n'))
cat(paste0('  - Columnas de total: ', length(total_cols), '\n'))
cat(paste0('  - Ejemplos conteo: ', paste(count_cols[1:3], collapse = ', '), '\n'))
cat(paste0('  - Ejemplos total: ', paste(total_cols[1:3], collapse = ', '), '\n\n'))

# Verificar estructura de miRNA_name y pos.mut
cat('Estructura de datos:\n')
cat(paste0('  - miRNA_name: ', class(data$miRNA_name), '\n'))
cat(paste0('  - pos.mut: ', class(data$pos.mut), '\n'))
cat(paste0('  - Valores únicos miRNA_name: ', length(unique(data$miRNA_name)), '\n'))
cat(paste0('  - Valores únicos pos.mut: ', length(unique(data$pos.mut)), '\n\n'))

# Mostrar ejemplos de pos.mut
cat('Ejemplos de pos.mut:\n')
print(head(unique(data$pos.mut), 10))
cat('\n')

# Verificar si hay valores G>T en pos.mut
gt_mutations <- data$pos.mut[grepl('G>T', data$pos.mut)]
cat('Mutations G>T encontradas:\n')
cat(paste0('  - Total G>T: ', length(gt_mutations), '\n'))
cat(paste0('  - Únicas G>T: ', length(unique(gt_mutations)), '\n'))
if(length(gt_mutations) > 0) {
  cat('  - Ejemplos: ', paste(head(unique(gt_mutations), 5), collapse = ', '), '\n')
}
cat('\n')

# Verificar estructura de pos.mut más detalladamente
cat('Análisis detallado de pos.mut:\n')
pos_mut_examples <- head(unique(data$pos.mut), 20)
for(i in 1:length(pos_mut_examples)) {
  cat(paste0('  ', i, ': "', pos_mut_examples[i], '"\n'))
}
cat('\n')

# Verificar si hay múltiples mutaciones en una fila (separadas por comas)
multi_mut <- data$pos.mut[grepl(',', data$pos.mut)]
cat('Filas con múltiples mutaciones:\n')
cat(paste0('  - Total: ', length(multi_mut), '\n'))
if(length(multi_mut) > 0) {
  cat('  - Ejemplos: ', paste(head(unique(multi_mut), 5), collapse = ', '), '\n')
}
cat('\n')









