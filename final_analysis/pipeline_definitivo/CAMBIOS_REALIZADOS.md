# Cambios Realizados en el Pipeline Definitivo

## Resumen de Correcciones

### 1. Corrección de Rutas de Datos
- **Archivo**: `config_pipeline.R`
- **Cambio**: Actualizada la ruta del archivo de datos crudos a la ubicación correcta:
  ```r
  raw_data = "/Users/cesaresparza/New_Desktop/UCSD/8OG/results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt"
  ```

### 2. Corrección de la Lógica de Split-Collapse
- **Archivo**: `functions_pipeline.R` - función `apply_split_collapse()`
- **Cambio**: 
  - Identificación correcta de columnas según la estructura real del dataset
  - **NO recálculo de totales** - los totales se mantienen igual como especificó el usuario
  - Uso de `first(.x)` para mantener el primer total en lugar de recalcular

### 3. Corrección del Cálculo de VAFs
- **Archivo**: `functions_pipeline.R` - función `calculate_vafs()`
- **Cambio**:
  - Identificación correcta de columnas de cuentas vs totales usando regex
  - Cálculo correcto: `count / total` para cada muestra correspondiente
  - Aprovechamiento de la estructura existente del dataset con columnas `(PM+1MM+2MM)`

### 4. Actualización del RMarkdown
- **Archivo**: `01_analisis_inicial_dataset.Rmd`
- **Cambios**:
  - Carga de configuración centralizada
  - Uso de funciones del pipeline en lugar de código duplicado
  - Identificación correcta de la estructura del dataset
  - Carga de funciones auxiliares

### 5. Actualización del Script de Ejecución
- **Archivo**: `run_initial_analysis.R`
- **Cambios**:
  - Uso de configuración centralizada
  - Verificación de existencia del archivo de datos
  - Referencias correctas a las rutas

## Estructura del Dataset Confirmada

Según el análisis del archivo `36_comprehensive_data_preprocessing_documentation.R`:

```r
# Columnas de metadatos
meta_cols <- c("miRNA.name", "pos.mut")

# Columnas de cuentas SNV (muestras individuales)
count_cols <- names(data)[!grepl("(PM\\+1MM\\+2MM|\\.\\.PM\\.1MM\\.2MM\\.)$", names(data)) & 
                          !names(data) %in% meta_cols]

# Columnas de totales miRNA
total_cols <- names(data)[grepl("(PM\\+1MM\\+2MM|\\.\\.PM\\.1MM\\.2MM\\.)$", names(data))]
```

## Validaciones Implementadas

1. **Verificación de estructura**: Las funciones ahora identifican correctamente los tipos de columnas
2. **Preservación de totales**: Los totales originales se mantienen sin recálculo
3. **Cálculo correcto de VAFs**: Usando la estructura real del dataset
4. **Manejo de errores**: Verificación de existencia de archivos y columnas

## Próximos Pasos

1. Ejecutar el análisis inicial para validar las correcciones
2. Continuar con los pasos 2-6 del pipeline
3. Generar documentación completa del proceso
4. Crear presentación HTML final

## Archivos Modificados

- `config_pipeline.R` - Rutas corregidas
- `functions_pipeline.R` - Lógica corregida para split-collapse y VAFs
- `01_analisis_inicial_dataset.Rmd` - Uso de funciones centralizadas
- `run_initial_analysis.R` - Configuración centralizada

## Archivos Creados

- `CAMBIOS_REALIZADOS.md` - Este archivo de documentación








