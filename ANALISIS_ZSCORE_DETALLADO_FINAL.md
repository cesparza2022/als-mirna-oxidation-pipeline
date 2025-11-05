# Análisis Z-Score Detallado: Patrones de Oxidación G>T en miRNAs entre ALS y Control

## Resumen Ejecutivo

Este análisis detallado de Z-scores examina las diferencias estadísticas en mutaciones G>T (oxidación) en la región semilla de miRNAs entre pacientes con ALS y controles sanos. Utilizamos un enfoque estadístico robusto para identificar patrones de oxidación específicos y evaluar su significancia biológica.

## Metodología del Z-Score

### Cálculo del Z-Score
El Z-score se calcula utilizando la siguiente fórmula:

```
Z-score = (VAF_ALS - VAF_Control) / pooled_sd
```

Donde:
- **VAF_ALS**: Variant Allele Frequency promedio en pacientes ALS
- **VAF_Control**: Variant Allele Frequency promedio en controles
- **pooled_sd**: Desviación estándar combinada de ambos grupos

### Desviación Estándar Combinada
```
pooled_sd = √[((n_control - 1) × sd_control² + (n_als - 1) × sd_als²) / (n_control + n_als - 2)]
```

### Interpretación
- **Z-score > 0**: Mayor oxidación en pacientes ALS
- **Z-score < 0**: Mayor oxidación en controles
- **|Z-score| > 1.5**: Diferencia significativa
- **|Z-score| > 2.0**: Diferencia altamente significativa

## Datos Analizados

### Distribución de Muestras
- **Total de muestras**: 415
  - **ALS Enrolment**: 249 muestras
  - **ALS Longitudinal**: 64 muestras  
  - **Control**: 102 muestras

### Mutaciones G>T en Región Semilla
- **Total SNVs G>T analizados**: 328
- **miRNAs únicos afectados**: 212
- **Posiciones cubiertas**: 2, 3, 4, 5, 6, 7, 8

## Resultados Principales

### 1. Significancia Estadística Global

#### SNVs con Diferencias Significativas
- **Altamente significativas (|z| > 2, p < 0.001)**: 0 SNVs
- **Significativas (|z| > 1.5, p < 0.01)**: 0 SNVs
- **Moderadamente significativas (|z| > 1.0, p < 0.05)**: 8 SNVs

#### Dirección de las Diferencias
- **SNVs con mayor VAF en ALS**: 3 SNVs
- **SNVs con mayor VAF en Control**: 5 SNVs

### 2. Top 5 SNVs con Mayores Diferencias

#### 1. hsa-miR-491-5p (Posición 6)
- **Z-score**: 2.00 (p = 3.38e-02)
- **VAF Control**: 1.00 ± 0.00 (n=5)
- **VAF ALS**: 2.33 ± 1.15 (n=3)
- **Fold change**: 2.33 (log2: 1.22)
- **Dirección**: ALS Higher
- **Significancia**: Moderately Significant
- **Interpretación**: 2.33-fold mayor oxidación en ALS

#### 2. hsa-miR-6852-5p (Posición 8)
- **Z-score**: -1.87 (p = 5.24e-02)
- **VAF Control**: 1.50 ± 0.71 (n=2)
- **VAF ALS**: 1.00 ± 0.00 (n=7)
- **Fold change**: 0.67 (log2: -0.58)
- **Dirección**: Control Higher
- **Significancia**: Not Significant

#### 3. hsa-miR-18a-5p (Posición 7)
- **Z-score**: -1.41 (p = 2.19e-01)
- **VAF Control**: 3.00 ± 1.73 (n=3)
- **VAF ALS**: 1.00 ± 0.00 (n=2)
- **Fold change**: 0.33 (log2: -1.58)
- **Dirección**: Control Higher
- **Significancia**: Not Significant

#### 4. hsa-miR-4318 (Posición 5)
- **Z-score**: -1.35 (p = 6.42e-02)
- **VAF Control**: 1.67 ± 1.15 (n=3)
- **VAF ALS**: 1.00 ± 0.00 (n=10)
- **Fold change**: 0.60 (log2: -0.74)
- **Dirección**: Control Higher
- **Significancia**: Not Significant

#### 5. hsa-miR-4481 (Posición 7)
- **Z-score**: 1.22 (p = 1.46e-01)
- **VAF Control**: 2.00 ± 1.00 (n=3)
- **VAF ALS**: 7.20 ± 5.17 (n=5)
- **Fold change**: 3.60 (log2: 1.85)
- **Dirección**: ALS Higher
- **Significancia**: Not Significant

### 3. Análisis por Posición en Región Semilla

| Posición | N SNVs | Z-score Medio | Z-score Máximo | SNVs Significativos | ALS Mayor | Control Mayor |
|----------|--------|---------------|----------------|-------------------|-----------|---------------|
| **6** | 69 | 0.193 | 2.00 | 0 | 1 | 0 |
| **5** | 39 | -0.175 | 1.35 | 0 | 0 | 1 |
| **7** | 67 | 0.122 | 1.41 | 0 | 1 | 3 |
| **4** | 29 | 0.102 | 1.03 | 0 | 1 | 0 |
| **8** | 72 | -0.039 | 1.87 | 0 | 0 | 1 |
| **2** | 33 | NaN | -Inf | 0 | 0 | 0 |
| **3** | 19 | NaN | -Inf | 0 | 0 | 0 |

### 4. Patrones de VAF por Posición

#### Posición 6 (Más Variable)
- **Z-score promedio**: 0.193
- **VAF promedio Control**: 3.09
- **VAF promedio ALS**: 4.10
- **Fold change promedio**: 1.92
- **Interpretación**: Mayor variabilidad y tendencia hacia mayor oxidación en ALS

#### Posición 5 (Control Mayor)
- **Z-score promedio**: -0.175
- **VAF promedio Control**: 1.72
- **VAF promedio ALS**: 5.56
- **Fold change promedio**: 1.46
- **Interpretación**: Mayor oxidación en controles

## Implicaciones Biológicas

### 1. Ausencia de Patrón Uniforme
- **No hay evidencia** de un patrón uniforme de mayor oxidación en pacientes ALS
- **Diferencias individuales** son más pronunciadas que patrones globales
- **Direccionalidad mixta** sugiere mecanismos complejos de estrés oxidativo

### 2. Posición 6 como Punto Crítico
- **Mayor variabilidad** en posición 6 (Z-score máximo: 2.00)
- **Funcionalmente crítica** en la región semilla
- **hsa-miR-491-5p** muestra la diferencia más significativa

### 3. Limitaciones Estadísticas
- **Poder estadístico limitado** debido a tamaños de muestra pequeños
- **Efectos pequeños** en la mayoría de SNVs
- **Necesidad de validación** en cohortes más grandes

## Visualizaciones Generadas

### 1. Gráficos de Análisis
- **detailed_zscore_by_position.pdf**: Z-score promedio por posición
- **detailed_zscore_distribution.pdf**: Distribución de Z-scores
- **detailed_fold_change_vs_zscore.pdf**: Fold change vs Z-score
- **detailed_vaf_by_group_position.pdf**: VAF por grupo y posición
- **detailed_significance_by_position.pdf**: Significancia por posición

### 2. Heatmap
- **detailed_zscore_heatmap.pdf**: Heatmap de Z-scores por miRNA y posición

## Archivos de Datos Generados

### 1. Resultados Detallados
- **detailed_zscore_analysis_results.tsv**: Análisis completo por SNV
- **detailed_position_zscore_analysis.tsv**: Análisis por posición

### 2. Métricas Incluidas
- Z-score, p-value, significancia
- VAF promedio por grupo
- Fold change y log2 fold change
- Tamaños de muestra por grupo
- Dirección de la diferencia
- Tamaño del efecto

## Conclusiones

### 1. Hallazgos Principales
- **No hay evidencia** de mayor oxidación global en ALS
- **Diferencias específicas** en miRNAs individuales
- **Posición 6** muestra mayor variabilidad
- **hsa-miR-491-5p** es el caso más significativo

### 2. Implicaciones Clínicas
- **Oxidación no es un biomarcador** global de ALS
- **Patrones específicos** pueden ser relevantes
- **Necesidad de estudios** más amplios para validación

### 3. Próximos Pasos
- **Validación** en cohortes independientes
- **Análisis funcional** de miRNAs específicos
- **Estudios longitudinales** para cambios temporales
- **Integración** con otros biomarcadores

## Referencias Metodológicas

- **Z-score calculation**: Método estándar para comparación de grupos
- **Pooled standard deviation**: Para varianzas iguales
- **Multiple testing correction**: FDR para control de falsos positivos
- **Effect size**: Cohen's d para magnitud de diferencias

---

*Análisis realizado el 29 de septiembre de 2024*
*Script: detailed_zscore_visualization.R*
*Datos: processed_snv_data_vaf_filtered.tsv*










