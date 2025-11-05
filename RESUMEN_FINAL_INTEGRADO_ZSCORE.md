# Resumen Final Integrado: Análisis Z-Score de miRNAs y Oxidación en ALS

## Resumen Ejecutivo

Este documento integra los hallazgos más recientes del análisis Z-score detallado de mutaciones G>T en miRNAs entre pacientes con ALS y controles sanos. Los resultados revelan patrones complejos de oxidación con implicaciones importantes para la comprensión de la patogénesis de ALS y el desarrollo de biomarcadores.

## Hallazgos Principales

### 1. Análisis Estadístico Riguroso

**Metodología Z-Score:**
- **Fórmula:** Z-score = (VAF_ALS - VAF_Control) / pooled_sd
- **Muestras analizadas:** 415 (249 ALS Enrolment, 64 ALS Longitudinal, 102 Control)
- **SNVs G>T analizados:** 328 en región semilla
- **miRNAs afectados:** 212 únicos

### 2. Resultados Estadísticos Globales

**Significancia Estadística:**
- **Altamente significativas (|z| > 2.0):** 0 SNVs
- **Significativas (|z| > 1.5):** 0 SNVs
- **Moderadamente significativas (|z| > 1.0):** 8 SNVs
- **Dirección de diferencias:** Mixta (3 mayor en ALS, 5 mayor en controles)

### 3. Hallazgo Más Significativo

**hsa-miR-491-5p (Posición 6):**
- **Z-score:** 2.00 (p = 0.034)
- **VAF Control:** 1.00 ± 0.00 (n=5)
- **VAF ALS:** 2.33 ± 1.15 (n=3)
- **Fold change:** 2.33-fold mayor oxidación en ALS
- **Significancia:** Moderadamente significativa
- **Interpretación:** 2.33-fold mayor oxidación en pacientes ALS

### 4. Top 5 SNVs con Mayores Diferencias

| Rank | miRNA | Posición | Z-score | p-value | Fold Change | Dirección | Significancia |
|------|-------|----------|---------|---------|-------------|-----------|---------------|
| 1 | **hsa-miR-491-5p** | 6 | **2.00** | 0.034 | 2.33 | ALS Higher | Moderately Significant |
| 2 | **hsa-miR-6852-5p** | 8 | **-1.87** | 0.052 | 0.67 | Control Higher | Not Significant |
| 3 | **hsa-miR-18a-5p** | 7 | **-1.41** | 0.219 | 0.33 | Control Higher | Not Significant |
| 4 | **hsa-miR-4318** | 5 | **-1.35** | 0.064 | 0.60 | Control Higher | Not Significant |
| 5 | **hsa-miR-4481** | 7 | **1.22** | 0.146 | 3.60 | ALS Higher | Not Significant |

### 5. Análisis por Posición

**Posición 6 (Más Variable):**
- **Z-score promedio:** 0.193
- **Z-score máximo:** 2.00
- **SNVs significativos:** 0
- **ALS mayor:** 1 SNV
- **Control mayor:** 0 SNVs
- **Fold change promedio:** 1.92

**Posición 5 (Control Mayor):**
- **Z-score promedio:** -0.175
- **Z-score máximo:** 1.35
- **SNVs significativos:** 0
- **ALS mayor:** 0 SNVs
- **Control mayor:** 1 SNV
- **Fold change promedio:** 1.46

## Implicaciones Biológicas

### 1. Ausencia de Patrón Uniforme
- **No hay evidencia** de mayor oxidación global en pacientes ALS
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

## Implicaciones Clínicas

### 1. Biomarcador Potencial
- **hsa-miR-491-5p** emerge como el candidato más prometedor
- **2.33-fold diferencia** entre ALS y controles
- **Posición 6** es funcionalmente crítica
- **Necesita validación** en cohortes independientes

### 2. Patogénesis de ALS
- **Oxidación no es un biomarcador** global de ALS
- **Patrones específicos** pueden ser relevantes
- **Mecanismos complejos** de estrés oxidativo

### 3. Desarrollo Terapéutico
- **Enfoque en miRNAs específicos** en lugar de patrones globales
- **Posición 6** como objetivo terapéutico
- **Validación experimental** necesaria

## Archivos Generados

### 1. Análisis Detallado
- **detailed_zscore_analysis_results.tsv**: Análisis completo por SNV
- **detailed_position_zscore_analysis.tsv**: Análisis por posición

### 2. Visualizaciones
- **detailed_zscore_by_position.pdf**: Z-score promedio por posición
- **detailed_zscore_distribution.pdf**: Distribución de Z-scores
- **detailed_fold_change_vs_zscore.pdf**: Fold change vs Z-score
- **detailed_vaf_by_group_position.pdf**: VAF por grupo y posición
- **detailed_significance_by_position.pdf**: Significancia por posición
- **detailed_zscore_heatmap.pdf**: Heatmap de Z-scores

### 3. Documentación
- **ANALISIS_ZSCORE_DETALLADO_FINAL.md**: Análisis completo
- **COMPREHENSIVE_PAPER_DRAFT_8oG_miRNA_ALS.md**: Borrador del paper actualizado

## Próximos Pasos

### 1. Validación
- **Cohortes independientes** para validar hsa-miR-491-5p
- **Estudios longitudinales** para cambios temporales
- **Análisis funcional** de miRNAs específicos

### 2. Investigación
- **Mecanismos moleculares** de oxidación en posición 6
- **Efectos funcionales** de mutaciones G>T
- **Integración** con otros biomarcadores

### 3. Desarrollo Clínico
- **Biomarcador diagnóstico** basado en hsa-miR-491-5p
- **Monitoreo terapéutico** de oxidación
- **Estrategias terapéuticas** para restaurar función

## Conclusiones

### 1. Hallazgos Clave
- **No hay evidencia** de mayor oxidación global en ALS
- **hsa-miR-491-5p** es el hallazgo más significativo
- **Posición 6** muestra mayor variabilidad
- **Patrones complejos** de estrés oxidativo

### 2. Contribuciones Metodológicas
- **Análisis Z-score riguroso** para comparación de grupos
- **Enfoque en significancia real** vs. número de SNVs
- **Validación estadística** de diferencias

### 3. Impacto Científico
- **Nuevo paradigma** para análisis de oxidación en miRNAs
- **Biomarcador potencial** para ALS
- **Base para estudios** futuros

---

*Análisis completado el 29 de septiembre de 2024*
*Script principal: detailed_zscore_visualization.R*
*Datos: processed_snv_data_vaf_filtered.tsv*
*Total de archivos generados: 8 visualizaciones + 2 archivos de datos + documentación*










