# Changelog: Implementación del Pipeline Optimizado

**Fecha**: 13 de Noviembre, 2025  
**Versión**: Pipeline Reorganizado y Optimizado

## Resumen Ejecutivo

Se ha completado una reorganización exhaustiva del pipeline de análisis de oxidación de miRNAs, optimizando la secuencia lógica de los pasos, corrigiendo errores críticos relacionados con el manejo de datos, y asegurando la robustez del pipeline ante casos de datos vacíos.

---

## Cambios Estructurales Principales

### 1. Reorganización de Pasos del Pipeline

#### **Antes** (GitHub):
- Step 1: Exploratory Analysis
- Step 1.5: VAF Filtering
- Step 2: Statistical Comparisons
- Step 3: Clustering + Functional Analysis (mezclado)
- Step 4: Biomarker Analysis
- Step 5: Family Analysis
- Step 6: Expression Correlation + Functional (mezclado)
- Step 7: Clustering (duplicado)

#### **Después** (Local Optimizado):
- **Step 0**: Overview - Análisis general sin bias G>T (NUEVO)
- **Step 1**: Exploratory Analysis - Análisis exploratorio con counts
- **Step 1.5**: VAF Filtering - Filtrado de calidad VAF
- **Step 2**: Statistical Comparisons - Comparaciones estadísticas
- **Step 3**: Clustering Analysis - Análisis de clustering (SOLO clustering)
- **Step 4**: Functional Analysis - Análisis funcional (movido desde Step 3)
- **Step 5**: Family Analysis - Análisis de familias de miRNAs
- **Step 6**: Expression vs Oxidation Correlation - Correlación expresión-oxidación (simplificado)
- **Step 7**: Biomarker Analysis - Análisis de biomarcadores (movido desde Step 4)

### 2. Nuevo Step 0 - Overview

**Propósito**: Análisis inicial del dataset sin sesgo hacia mutaciones G>T, proporcionando una visión general de:
- Distribución de miRNAs
- Distribución de muestras
- Distribución de SNVs por tipo
- Análisis posicional
- Tablas de resumen

**Archivos creados**:
- `scripts/step0/01_generate_overview.R`
- `scripts/utils/build_step0_viewer.R`
- `rules/step0.smk` (nuevo)

---

## Correcciones Críticas de Datos

### Problema: Matriz de 830 columnas (415 SNV + 415 total counts)

**Causa**: Step 1.5 estaba generando un archivo con columnas duplicadas (SNV counts + total counts), causando confusión en pasos downstream.

**Solución**:
1. **Modificado `scripts/step1_5/01_apply_vaf_filter.R`**:
   - Ahora solo genera 415 columnas de SNV counts (más 2 columnas de metadata)
   - Eliminadas las columnas redundantes de total counts del output principal

2. **Creado `scripts/utils/data_loading_helpers.R`**:
   - Función `identify_snv_count_columns()`: Identifica robustamente columnas de SNV counts
   - Función `identify_total_count_columns()`: Identifica columnas de total counts
   - Función `identify_vaf_columns()`: Identifica columnas de VAF

3. **Integrado en todos los pasos downstream**:
   - Step 2: `scripts/step2/01_statistical_comparisons.R`
   - Step 3: `scripts/step3/01_clustering_analysis.R` y `02_clustering_visualization.R`
   - Step 7: `scripts/step7/01_biomarker_roc_analysis.R` y `02_biomarker_signature_heatmap.R`

### Problema: Error "variable names are limited to 10000 bytes"

**Causa**: R/dplyr tiene limitaciones internas cuando se procesan data frames con muchas columnas (415 muestras en este caso).

**Solución**: Reemplazo sistemático de operaciones `dplyr` con equivalentes en base R:

1. **Step 6** (`scripts/step6/01_expression_oxidation_correlation.R`):
   - Reemplazado `dplyr::mutate()` con `across()` por `rowSums()` y `aggregate()` de base R
   - Reemplazado `dplyr::semi_join()` por subsetting con base R (`which(vaf_keys %in% gt_keys)`)
   - Reemplazado `dplyr::inner_join()` por `merge()` de base R
   - Reemplazado `dplyr::rename()` por `names(data)[names(data) == old] <- new`
   - Corregido manejo de fórmulas en `aggregate()` para columnas con espacios

2. **Step 7** (`scripts/step7/01_biomarker_roc_analysis.R`):
   - Uso de índices de columnas en lugar de `select()`
   - Subsetting directo con base R: `vaf_data[, keep_indices, drop = FALSE]`

3. **Utilidades** (`scripts/utils/group_comparison.R`):
   - `extract_sample_groups()`: Procesa muestras en chunks para datasets grandes (>200 columnas)
   - Uso de `lapply()` y `data.frame()` en lugar de `tibble()` y `mutate(case_when())`

---

## Manejo de Datos Vacíos

### Problema: Scripts fallaban cuando no había mutaciones G>T significativas

**Solución**: Agregadas verificaciones al inicio de scripts de visualización:

1. **Step 6** (`scripts/step6/02_correlation_visualization.R`):
   - Verifica si `correlation_data` está vacío
   - Genera figuras placeholder con mensaje informativo

2. **Step 7**:
   - `scripts/step7/01_biomarker_roc_analysis.R`: Verifica `significant_gt` vacío, genera outputs vacíos y figura placeholder
   - `scripts/step7/02_biomarker_signature_heatmap.R`: Verifica `roc_table` vacío, genera figura placeholder

---

## Reorganización de Scripts

### Scripts Movidos:

1. **Functional Analysis** (Step 3 → Step 4):
   - `scripts/step3/01_functional_target_analysis.R` → `scripts/step4/01_functional_target_analysis.R`
   - `scripts/step3/02_pathway_enrichment.R` → `scripts/step4/02_pathway_enrichment.R`
   - `scripts/step3/03_complex_functional_visualization.R` → `scripts/step4/03_complex_functional_visualization.R`

2. **Biomarker Analysis** (Step 4 → Step 7):
   - `scripts/step4/01_biomarker_roc_analysis.R` → `scripts/step7/01_biomarker_roc_analysis.R`
   - `scripts/step4/02_biomarker_signature_heatmap.R` → `scripts/step7/02_biomarker_signature_heatmap.R`

### Scripts Actualizados:

1. **Step 3** - Ahora solo contiene clustering:
   - `scripts/step3/01_clustering_analysis.R`
   - `scripts/step3/02_clustering_visualization.R`

2. **Step 4** - Ahora contiene functional analysis:
   - `scripts/step4/01_functional_target_analysis.R` (actualizado para usar cluster assignments de Step 3)
   - `scripts/step4/02_pathway_enrichment.R`
   - `scripts/step4/03_complex_functional_visualization.R`

3. **Step 5** - Family Analysis:
   - `scripts/step5/01_family_identification.R` (actualizado para usar cluster assignments de Step 3)
   - `scripts/step5/02_family_comparison_visualization.R`

4. **Step 6** - Expression Correlation (simplificado):
   - `scripts/step6/01_expression_oxidation_correlation.R` (corregido para usar base R)
   - `scripts/step6/02_correlation_visualization.R` (agregado manejo de datos vacíos)

5. **Step 7** - Biomarker Analysis:
   - `scripts/step7/01_biomarker_roc_analysis.R` (movido desde Step 4, corregido para usar base R)
   - `scripts/step7/02_biomarker_signature_heatmap.R` (movido desde Step 4, agregado manejo de datos vacíos)

---

## Actualización de Snakemake Rules

### Rules Modificadas:

1. **`rules/step0.smk`** (NUEVO):
   - `step0_overview`: Genera análisis general del dataset

2. **`rules/step3.smk`**:
   - **ANTES**: Contenía clustering + functional analysis
   - **DESPUÉS**: Solo contiene clustering analysis
   - Eliminadas reglas de functional analysis

3. **`rules/step4.smk`**:
   - **ANTES**: Contenía biomarker analysis
   - **DESPUÉS**: Contiene functional analysis
   - Nuevas dependencias: `S3_cluster_assignments.csv` (de Step 3)

4. **`rules/step5.smk`**:
   - Agregadas dependencias: `S3_cluster_assignments.csv` (de Step 3)

5. **`rules/step6.smk`**:
   - Simplificado: Solo contiene expression correlation
   - Eliminadas reglas de functional analysis (duplicadas)

6. **`rules/step7.smk`**:
   - **ANTES**: Contenía clustering (duplicado)
   - **DESPUÉS**: Contiene biomarker analysis
   - Movidas reglas desde Step 4

7. **`rules/viewers.smk`**:
   - Agregada regla `generate_step0_viewer`
   - Actualizadas reglas para Steps 3-7 con nuevas dependencias

### `Snakefile` Principal:
- Actualizado orden de `include` directives
- Actualizado `all` rule para reflejar nueva estructura

---

## Actualización de Viewers HTML

### Viewers Modificados:

1. **`scripts/utils/build_step0_viewer.R`** (NUEVO):
   - Genera viewer para Step 0 con todas las figuras y tablas de overview

2. **`scripts/utils/build_step3_viewer.R`**:
   - Actualizado para mostrar solo resultados de clustering
   - Eliminadas referencias a functional analysis

3. **`scripts/utils/build_step4_viewer.R`**:
   - Actualizado para mostrar functional analysis results
   - Carga `S3_cluster_assignments.csv` para contexto

4. **`scripts/utils/build_step5_viewer.R`**:
   - Actualizado para mostrar family analysis results
   - Usa cluster assignments de Step 3

5. **`scripts/utils/build_step6_viewer.R`**:
   - Actualizado para mostrar expression correlation results
   - Simplificado (sin functional analysis)

6. **`scripts/utils/build_step7_viewer.R`**:
   - Actualizado para mostrar biomarker analysis results
   - Carga ROC tables y signature data

---

## Correcciones de Detección de Grupos

### Problema: Hardcoded group names ("ALS", "Control")

**Solución**: Implementada detección dinámica de grupos:

1. **`scripts/utils/group_comparison.R`**:
   - `extract_sample_groups()`: Detecta grupos automáticamente desde nombres de columnas o metadata
   - `load_sample_groups_from_metadata()`: Carga grupos desde archivo de metadata si existe
   - Procesa en chunks para datasets grandes

2. **Scripts actualizados para usar grupos dinámicos**:
   - `scripts/step2/01_statistical_comparisons.R`: Usa `group1_name` y `group2_name` dinámicos
   - `scripts/step3/01_clustering_analysis.R`: Usa grupos dinámicos en cluster summary
   - `scripts/step3/02_clustering_visualization.R`: Usa grupos dinámicos en heatmap
   - `scripts/step4/02_biomarker_signature_heatmap.R`: Usa grupos dinámicos en colores
   - `scripts/step7/01_biomarker_roc_analysis.R`: Usa grupos dinámicos en ROC analysis

---

## Correcciones de Column Names

### Problema: Inconsistencias en nombres de columnas (`miRNA name` vs `miRNA_name`, `pos:mut` vs `pos.mut`)

**Solución**: Funciones helper para estandarización:

1. **`scripts/utils/data_loading_helpers.R`**:
   - `standardize_mirna_col()`: Detecta y estandariza columna de miRNA name
   - `standardize_posmut_col()`: Detecta y estandariza columna de pos:mut

2. **Integrado en scripts críticos**:
   - `scripts/step3/02_clustering_visualization.R`: Usa funciones de estandarización
   - Todos los scripts de visualización normalizan nombres antes de procesar

---

## Estado de Ejecución

### Pasos Completados Exitosamente:

- ✅ **Step 0**: Overview - Generado correctamente
- ✅ **Step 1**: Exploratory Analysis - Generado correctamente
- ✅ **Step 1.5**: VAF Filtering - Generado correctamente (415 columnas SNV)
- ✅ **Step 2**: Statistical Comparisons - Generado correctamente
- ✅ **Step 3**: Clustering Analysis - Generado correctamente
- ✅ **Step 4**: Functional Analysis - Generado correctamente
- ✅ **Step 5**: Family Analysis - Generado correctamente
- ✅ **Step 6**: Expression Correlation - Generado correctamente (con manejo de datos vacíos)
- ✅ **Step 7**: Biomarker Analysis - Generado correctamente (con manejo de datos vacíos)

### Nota sobre Datos Vacíos:

En este dataset específico, no se encontraron mutaciones G>T significativas en la región seed (posiciones 2-8), por lo que:
- Step 6 generó outputs vacíos (esperado)
- Step 7 generó outputs vacíos (esperado)

Los scripts manejan correctamente estos casos generando archivos vacíos y figuras placeholder con mensajes informativos.

---

## Archivos de Configuración

### `config/config.yaml.example`:
- Actualizado con todas las rutas necesarias para Steps 0-7
- Eliminados bloques duplicados (`batch_correction`, `confounders`)
- Agregadas rutas para `pipeline_info`, `summary`, `validation`

---

## Mejoras de Robustez

1. **Manejo de errores mejorado**:
   - Todos los scripts verifican existencia de datos antes de procesar
   - Mensajes de error más informativos
   - Logging detallado en cada paso

2. **Validación de inputs**:
   - Verificación de existencia de archivos de input
   - Validación de estructura de datos
   - Verificación de columnas requeridas

3. **Compatibilidad**:
   - Manejo robusto de diferentes formatos de nombres de columnas
   - Detección automática de grupos de muestras
   - Fallbacks cuando metadata no está disponible

---

## Próximos Pasos Recomendados

1. **Testing**:
   - Ejecutar pipeline completo con datos de prueba
   - Verificar todos los viewers HTML
   - Validar outputs de cada paso

2. **Documentación**:
   - Actualizar README.md con nueva estructura
   - Documentar cambios en lógica de datos
   - Crear guía de troubleshooting

3. **Optimización**:
   - Revisar tiempos de ejecución
   - Optimizar scripts más lentos
   - Considerar paralelización adicional

---

## Archivos Clave Modificados

### Scripts R:
- `scripts/step0/01_generate_overview.R` (NUEVO)
- `scripts/step1_5/01_apply_vaf_filter.R` (MODIFICADO)
- `scripts/step2/01_statistical_comparisons.R` (MODIFICADO)
- `scripts/step3/01_clustering_analysis.R` (MODIFICADO)
- `scripts/step3/02_clustering_visualization.R` (MODIFICADO)
- `scripts/step4/01_functional_target_analysis.R` (MOVIDO Y MODIFICADO)
- `scripts/step5/01_family_identification.R` (MODIFICADO)
- `scripts/step6/01_expression_oxidation_correlation.R` (MODIFICADO EXTENSIVAMENTE)
- `scripts/step6/02_correlation_visualization.R` (MODIFICADO)
- `scripts/step7/01_biomarker_roc_analysis.R` (MOVIDO Y MODIFICADO)
- `scripts/step7/02_biomarker_signature_heatmap.R` (MOVIDO Y MODIFICADO)

### Utilidades:
- `scripts/utils/data_loading_helpers.R` (NUEVO)
- `scripts/utils/group_comparison.R` (MODIFICADO)
- `scripts/utils/build_step0_viewer.R` (NUEVO)
- `scripts/utils/build_step3_viewer.R` (MODIFICADO)
- `scripts/utils/build_step4_viewer.R` (MODIFICADO)
- `scripts/utils/build_step5_viewer.R` (MODIFICADO)
- `scripts/utils/build_step6_viewer.R` (MODIFICADO)
- `scripts/utils/build_step7_viewer.R` (MODIFICADO)

### Snakemake Rules:
- `rules/step0.smk` (NUEVO)
- `rules/step3.smk` (MODIFICADO)
- `rules/step4.smk` (MODIFICADO)
- `rules/step5.smk` (MODIFICADO)
- `rules/step6.smk` (MODIFICADO)
- `rules/step7.smk` (MODIFICADO)
- `rules/viewers.smk` (MODIFICADO)
- `Snakefile` (MODIFICADO)

### Configuración:
- `config/config.yaml.example` (MODIFICADO)

---

**Fin del Changelog**

