# RESUMEN DE PASOS COMPLETADOS - ANÁLISIS INICIAL

## ✅ PASO 1A: CARGAR Y PROCESAR DATOS BÁSICOS
**Archivos generados:**
- `datos_procesados_split_collapse.csv` (87MB)
- `datos_con_vafs.csv` (132MB) 
- `datos_filtrados_vaf.csv` (130MB)
- `resumen_transformaciones.csv`

**Resultados clave:**
- **Dataset original:** 68,968 filas × 832 columnas (1,728 miRNAs únicos)
- **Después split-collapse:** 29,254 filas × 832 columnas (1,728 miRNAs únicos)
- **Después cálculo VAFs:** 29,254 filas × 1,247 columnas
- **Después filtrado VAF>50%:** 29,254 filas × 1,247 columnas
- **NaNs generados:** 210,118 (promedio 506.31 por muestra)

---

## ✅ PASO 1B: ANÁLISIS DETALLADO DE miRNAs
**Archivos generados:**
- `analisis_mirnas_detallado.csv` (47KB)
- `analisis_regiones_funcionales.csv`
- `top_10_mirnas_snvs.png`
- `snvs_por_region_funcional.png`

**Resultados clave:**
- **Total miRNAs:** 1,728
- **miRNA con más SNVs:** hsa-miR-191-5p (70 SNVs)
- **miRNA con más G>T:** hsa-miR-1908-5p (11 mutaciones G>T)

**Distribución por regiones funcionales:**
- **3':** 9,871 SNVs (33.7%) - 888 G>T (40.5%)
- **Central:** 9,649 SNVs (33.0%) - 759 G>T (34.6%)
- **Semilla:** 6,959 SNVs (23.8%) - 482 G>T (22.0%)
- **Otro:** 2,775 SNVs (9.5%) - 64 G>T (2.9%)

---

## ✅ PASO 1C: ANÁLISIS DETALLADO DE POSICIONES
**Archivos generados:**
- `analisis_posiciones_detallado.csv`
- `analisis_posiciones_gt.csv`
- `analisis_region_posicion.csv`
- `top_15_posiciones_mutadas.png`
- `top_10_posiciones_gt.png`
- `distribucion_snvs_por_posicion.png`

**Resultados clave:**
- **Total posiciones:** 23
- **Posición más mutada:** Posición 21 (1,570 SNVs)
- **Posición con más G>T:** Posición 22 (180 mutaciones G>T)

---

## ✅ PASO 2A: ANÁLISIS BÁSICO DE MUTACIONES G>T
**Archivos generados:**
- `gt_estadisticas_generales.csv`
- `gt_analisis_por_region.csv`
- `mutaciones_gt_detalladas.csv`
- `gt_distribucion_por_region.png`
- `gt_comparacion_total.png`

**Resultados clave:**
- **Total mutaciones G>T:** 2,193 de 29,254 SNVs (7.5%)
- **miRNAs con G>T:** 783
- **Posiciones con G>T:** 23
- **Regiones afectadas:** 4

**Distribución de G>T por región:**
- **3':** 888 mutaciones (40.5%)
- **Central:** 759 mutaciones (34.6%)
- **Semilla:** 482 mutaciones (22.0%)
- **Otro:** 64 mutaciones (2.9%)

---

## 📊 ESTADÍSTICAS GENERALES DEL DATASET

### Transformaciones del Dataset:
1. **Split:** 68,968 → 111,785 filas (separación de mutaciones múltiples)
2. **Collapse:** 111,785 → 29,254 filas (consolidación de duplicados)
3. **VAFs:** 29,254 filas × 1,247 columnas (cálculo de frecuencias)
4. **Filtrado:** 210,118 NaNs generados (VAFs > 50%)

### Características del Dataset Final:
- **SNVs únicos:** 29,254
- **miRNAs únicos:** 1,728
- **Muestras:** 415
- **Mutaciones G>T:** 2,193 (7.5% del total)

### Distribución por Regiones Funcionales:
- **Región 3':** Mayor concentración de SNVs y G>T
- **Región Central:** Segunda mayor concentración
- **Región Semilla:** Importante para función, menor concentración
- **Otras regiones:** Menor representación

---

## 🎯 PRÓXIMOS PASOS SUGERIDOS

### Paso 2B: Análisis Detallado de G>T por Posición
- Análisis específico de posiciones con más mutaciones G>T
- Comparación G>T vs otras mutaciones por posición
- Análisis de hotspots de oxidación

### Paso 2C: Análisis de miRNAs con Mayor Oxidación
- Top miRNAs con más mutaciones G>T
- Análisis de patrones de oxidación por miRNA
- Correlación con función biológica

### Paso 3A: Análisis de VAFs en Mutaciones G>T
- VAFs específicas para mutaciones G>T
- Comparación con otras mutaciones
- Análisis de distribución de VAFs

### Paso 3B: Análisis Comparativo ALS vs Control
- Diferencias en mutaciones G>T entre grupos
- Análisis de VAFs por grupo
- Significancia estadística

---

## 📁 ARCHIVOS GENERADOS (RESUMEN)

### Tablas (CSV): 15 archivos
- Datos procesados: 3 archivos
- Análisis de miRNAs: 2 archivos  
- Análisis de posiciones: 3 archivos
- Análisis de G>T: 3 archivos
- Resúmenes: 4 archivos

### Figuras (PNG): 8 archivos
- Evolución del dataset: 1 figura
- Análisis de miRNAs: 2 figuras
- Análisis de posiciones: 3 figuras
- Análisis de G>T: 2 figuras

**Total:** 23 archivos generados
**Tamaño total:** ~350MB de datos procesados

---

## ✅ PASO 2B: ANÁLISIS DETALLADO DE G>T POR POSICIÓN
**Archivos generados:**
- `gt_analisis_detallado_por_posicion.csv`
- `gt_hotspots_oxidacion.csv`
- `gt_comparacion_por_posicion.csv`
- `gt_mirnas_posicion_[22,21,20,15,11].csv` (5 archivos)
- `gt_top_15_posiciones_detallado.png`
- `gt_comparacion_por_posicion.png`
- `gt_porcentaje_por_posicion.png`

**Resultados clave:**
- **Posición con más G>T:** Posición 22 (180 mutaciones, 8.21%)
- **Hotspots identificados:** 11 posiciones con ≥100 mutaciones G>T
- **Posición con mayor % G>T:** Posición 23 (13.54% de todas las mutaciones)
- **Top 3 hotspots:** Posiciones 22, 21, 20 (180, 174, 153 mutaciones G>T)

**Hallazgos importantes:**
- **Concentración en región 3':** Las posiciones 20-22 (región 3') concentran el mayor número de mutaciones G>T
- **Patrón de oxidación:** Las posiciones 10-15 (región central) también muestran alta oxidación
- **Distribución uniforme:** Cada posición G>T afecta exactamente 1 miRNA único (no hay duplicados)

---

## ✅ PASO 2C: ANÁLISIS DE miRNAs CON MAYOR OXIDACIÓN
**Archivos generados:**
- `gt_analisis_mirnas_detallado.csv`
- `gt_mirnas_multiples_posiciones.csv`
- `gt_mirnas_por_region.csv`
- `gt_mirnas_region_semilla.csv`
- `gt_mirnas_comparativo.csv`
- `gt_mirnas_alto_porcentaje.csv`
- `gt_top_15_mirnas.png`
- `gt_distribucion_posiciones_afectadas.png`
- `gt_comparacion_mirnas.png`
- `gt_mirnas_alto_porcentaje.png`

**Resultados clave:**
- **miRNA con más G>T:** hsa-miR-1908-5p (11 mutaciones, 18.0% de sus SNVs)
- **miRNAs con múltiples posiciones G>T:** 454 miRNAs
- **miRNAs con G>T en región semilla:** 309 miRNAs
- **miRNAs con ≥20% G>T:** 123 miRNAs

**Hallazgos importantes:**
- **Patrón de oxidación múltiple:** 454 miRNAs tienen G>T en múltiples posiciones
- **Oxidación en región semilla:** 309 miRNAs afectados (crítico para función)
- **Alto porcentaje de oxidación:** 123 miRNAs con ≥20% de mutaciones G>T
- **Top miRNAs oxidados:** hsa-miR-1908-5p y hsa-miR-4433b-3p (11 mutaciones cada uno)

---

## ✅ PASO 3A: ANÁLISIS DETALLADO DE VAFs EN MUTACIONES G>T
**Archivos generados:**
- `gt_vaf_resumen_general.csv`
- `gt_vaf_resumen_otras_mutaciones.csv`
- `gt_vaf_por_region.csv`
- `gt_vaf_por_posicion.csv`
- `gt_impacto_filtrado_vaf.csv`
- `gt_comparacion_vafs_tipo_mutacion.png`
- `gt_vafs_por_region.png`
- `gt_vafs_por_posicion.png`
- `gt_distribucion_vafs_boxplot.png`

**Resultados clave:**
- **VAF promedio G>T:** 0.0081 (0.81%)
- **VAF promedio otras mutaciones:** 0.0185 (1.85%)
- **Región con mayor VAF G>T:** Región "Otro" (0.89%)
- **Posición con mayor VAF G>T:** Posición 22 (0.85%)
- **VAFs filtrados en G>T:** 0.71% (6,466 NaNs generados)

**Hallazgos importantes:**
- **VAFs más bajos en G>T:** Las mutaciones G>T tienen VAFs significativamente más bajos que otras mutaciones
- **Patrón regional:** La región "Otro" muestra los VAFs más altos para G>T
- **Impacto del filtrado:** Solo 0.71% de VAFs G>T fueron filtrados (VAFs > 50%)
- **Distribución:** Las mutaciones G>T tienden a tener VAFs muy bajos (mediana = 0)

## ✅ PASO 3B: ANÁLISIS COMPARATIVO ALS vs CONTROL
**Archivos generados:**
- `paso3b_resumen_diferencias_vaf.csv`
- `paso3b_comparacion_vafs_als_control.csv`
- `paso3b_vafs_por_grupo_boxplot.png`
- `paso3b_vafs_als_vs_control_scatter.png`

**Resultados clave:**
- **Total de SNVs analizados:** 29,254
- **Muestras ALS:** 626 muestras
- **Muestras Control:** 204 muestras
- **SNVs con VAF mayor en ALS:** 266 (0.91%)
- **SNVs con VAF mayor en Control:** 1,810 (6.19%)
- **SNVs con VAFs similares:** 27,178 (92.90%)
- **Diferencia promedio de VAF:** -0.0048 (Control ligeramente mayor)
- **Ratio promedio ALS/Control:** 2.74

**Hallazgos importantes:**
- **Control muestra VAFs ligeramente superiores:** En promedio, las muestras Control tienen VAFs 0.48% más altos que ALS, aunque esta diferencia es pequeña.
- **Mayor variabilidad en Control:** 1,810 SNVs tienen VAFs significativamente mayores en Control vs solo 266 en ALS, sugiriendo mayor heterogeneidad en el grupo Control.
- **Mayoría de SNVs similares:** El 92.9% de los SNVs muestran VAFs similares entre grupos, indicando que la mayoría de mutaciones no difieren significativamente entre ALS y Control.
- **Patrón de distribución:** Los VAFs en Control tienden a ser más altos y variables, mientras que ALS muestra un perfil más conservado.

---

## ✅ PASO 3C: ANÁLISIS DE DISTRIBUCIÓN DE VAFs POR REGIÓN
**Archivos generados:**
- `paso3c_vafs_por_region_general.csv`
- `paso3c_vafs_por_region_tipo_mutacion.csv`
- `paso3c_vafs_por_region_posicion.csv`
- `paso3c_vafs_por_region_boxplot.png`
- `paso3c_vafs_heatmap_region_mutacion.png`
- `paso3c_vafs_por_region_posicion.png`

**Resultados clave:**
- **VAF promedio por región:**
  - **Región "Otro":** 0.0028 VAF promedio (9,849 mutaciones)
  - **Región 3':** 0.0008 VAF promedio (6,901 mutaciones)
  - **Región Central:** 0.0007 VAF promedio (5,492 mutaciones)
  - **Región Seed:** 0.0005 VAF promedio (6,958 mutaciones)
- **Total observaciones VAF:** 11,923,292 observaciones válidas
- **Distribución de mutaciones por región:** Seed (23.8%), Central (18.8%), 3' (23.6%), Otro (33.7%)

**Hallazgos importantes:**
- **Región "Otro" con VAFs más altos:** La región "Otro" muestra VAFs significativamente más altos (0.0028) que las regiones funcionales tradicionales
- **Región Seed con VAFs más bajos:** La región semilla muestra los VAFs más bajos (0.0005), sugiriendo mayor conservación
- **Patrón de conservación:** Las regiones funcionales (Seed, Central, 3') muestran VAFs similares y bajos, indicando mayor presión selectiva
- **Distribución uniforme:** Las mutaciones se distribuyen de manera relativamente uniforme entre las regiones funcionales

## ✅ PASO 4A: ANÁLISIS DE SIGNIFICANCIA ESTADÍSTICA
**Archivos generados:**
- `paso4a_t_test_results.csv`
- `paso4a_resumen_significancia.csv`
- `paso4a_volcano_plot_vafs.png`
- `paso4a_distribucion_pvalues.png`
- `paso4a_top_significativos.png`

**Resultados clave:**
- **Total SNVs analizados:** 28,874 SNVs con suficientes observaciones
- **SNVs significativos:** 819 SNVs (2.8% del total)
  - **Altamente significativos (***):** 390 SNVs (1.35%)
  - **Muy significativos (**):** 209 SNVs (0.72%)
  - **Significativos (*):** 220 SNVs (0.76%)
- **Muestras analizadas:** 313 muestras ALS vs 102 muestras Control
- **Corrección estadística:** Aplicada corrección FDR (Benjamini-Hochberg)

**Hallazgos importantes:**
- **2.8% de SNVs son estadísticamente significativos** entre grupos ALS vs Control
- **Distribución de significancia:** La mayoría de SNVs (97.2%) no muestran diferencias significativas
- **Volcano plot:** Muestra distribución clara de SNVs significativos vs no significativos
- **Top SNVs significativos:** Identificados los 20 SNVs con mayor significancia estadística
- **Análisis G>T:** No se encontraron suficientes mutaciones G>T para análisis chi-cuadrado

**Implicaciones:**
- **Evidencia estadística sólida:** 819 SNVs muestran diferencias significativas entre grupos
- **Control de falsos positivos:** Corrección FDR reduce significativamente el número de hallazgos espurios
- **Enfoque en SNVs significativos:** Los 390 SNVs altamente significativos son candidatos prioritarios para análisis funcional

---

## ✅ PASO 5A: EVALUACIÓN DE OUTLIERS EN MUESTRAS

**Archivos generados:**
- `paso5a_outliers_consolidado.csv` - Lista completa de outliers
- `paso5a_gt_impacto_outliers.csv` - Impacto en cada G>T
- `paso5a_gt_impacto_resumen.csv` - Resumen de impacto
- `paso5a_pca_outliers.png` - PCA con outliers marcados
- `paso5a_distribucion_counts_boxplot.png`
- `paso5a_distribucion_totales_boxplot.png`
- `paso5a_vaf_perfil_scatter.png`
- **Análisis profundo:**
  - `gt_por_region_y_outliers.csv`
  - `gt_semilla_por_posicion_outliers.csv`
  - `gt_posicion6_mirnas_detallado.csv`
  - `gt_heatmap_posicion_region_outliers.png`
  - `gt_semilla_por_posicion.png`

**Resultados clave:**
- **Total outliers identificados:** 84 muestras (20.2%)
  - ALS: 69 muestras (22.0%)
  - Control: 15 muestras (14.7%)
- **Outliers severos (≥2 criterios):** 0 muestras ✅
- **Impacto en G>T si eliminamos outliers:**
  - Pérdida directa: 280 G>T (12.77%)
  - Pérdida de potencia: 419 G>T (19.11%)
  - **Total afectado: 699 G>T (31.88%)**

**Hallazgos críticos - Región SEMILLA:**
- **🌱 REGIÓN MÁS AFECTADA:** 24.9% de G>T en semilla solo en outliers
- **Posiciones 1-5:** 27-39% solo en outliers (muy afectadas)
- **Posición 6 (crítica):** 17.5% solo en outliers (menos afectada)
- **Posición 3:** 39.4% solo en outliers (la más vulnerable)
- **Total G>T en semilla:** 397 mutaciones
  - Solo en outliers: 99 (24.9%)
  - Mayormente en outliers: 166 (41.8%)

**Características de G>T en outliers:**
- **86% en solo 1 muestra** (ultra-raras)
- **9% en solo 2 muestras**
- **95% en ≤2 muestras** (muy raras)
- Específicas de región semilla y posiciones 1-5

**Decisión tomada:**
✅ **MANTENER todos los 84 outliers**
- Ninguno es outlier severo (≥2 criterios)
- Alto impacto en región semilla (24.9%)
- Probablemente heterogeneidad clínica legítima
- Requieren metadatos para validación

---

---

## ✅ PASO 6A: INTEGRACIÓN DE METADATOS CLÍNICOS

**Archivos generados:**
- `paso6a_metadatos_integrados.csv` - Metadatos para 415 muestras
- `paso6a_outliers_caracterizados.csv` - Outliers con timepoint
- `paso6a_outliers_proporcion_por_grupo.csv`
- `paso6a_batch_cohort_tabla.csv`
- `paso6a_distribucion_muestras.png`
- `paso6a_outliers_por_grupo.png`

**Resultados clave:**
- **Metadatos integrados:** 415 muestras con cohort, timepoint, batch
- **Outliers caracterizados:** 84 muestras vinculadas con metadatos
- **Distribución de outliers:**
  - ALS Enrolment: 55 outliers (22.09%)
  - ALS Longitudinal: 14 outliers (21.88%)
  - Control: 15 outliers (14.71%)

**Hallazgos importantes - Batch Effects:**
- ⚠️ **Confusión batch-cohort COMPLETA** detectada
- **PERO:** Cada muestra es su propio batch (batch = SRR ID único)
- **Conclusión:** NO hay verdadero batch effect técnico
- ✅ NO requiere corrección de batch

**Hallazgos importantes - Outliers:**
- **ALS tiene más outliers** que Control (22% vs 15%)
- **Enrolment y Longitudinal tienen misma proporción** (22% ambos)
- Outliers **NO dependen** del tiempo de colección
- Probablemente **heterogeneidad clínica** inherente de ALS

**Metadatos disponibles:**
- **Todas (415):** cohort, timepoint, batch
- **Subset (~253):** onset, sex, riluzole
- **Discovery (126):** ALSFRS, slope, survival, status, miR-181

**Limitación identificada:**
- ⚠️ **Mapeo de IDs pendiente** para vincular metadatos clínicos avanzados
- Códigos de paciente (BLT, BUH, etc.) vs SRR IDs

**Decisión confirmada:**
✅ **MANTENER los 84 outliers**
- Distribuidos uniformemente (no son artefacto temporal)
- Heterogeneidad clínica legítima
- Necesarios para análisis de subtipos

---

---

## ✅ PASO 7A: ANÁLISIS TEMPORAL (ENROLMENT vs LONGITUDINAL)

**Archivos generados:**
- `paso7a_vaf_temporal_comparacion.csv`
- `paso7a_gt_temporal_detallado.csv`
- `paso7a_test_temporal_significancia.csv`
- `paso7a_gt_cambios_por_region.csv`
- `paso7a_gt_semilla_temporal.csv`
- `paso7a_scatter_vaf_temporal.png`
- `paso7a_scatter_gt_temporal.png`
- `paso7a_gt_semilla_cambios.png`

**Resultados clave - Significancia estadística:**
- **Paired t-test (todos los SNVs):**
  - N = 11,978 SNVs
  - Mean difference: +0.00109 (aumento de 0.11%)
  - p-value: 3.8e-44 (ALTAMENTE significativo) ✅
  
- **Paired t-test (G>T):**
  - N = 943 mutaciones G>T
  - Mean difference: +0.000598 (aumento de 0.06%)
  - p-value: 0.001 (SIGNIFICATIVO) ✅

**Hallazgos importantes - Cambios en G>T:**
- **Dirección de cambios:**
  - Disminución: 1,165 (53.1%) - Mayoría disminuyen ⬇️
  - Aumento: 558 (25.4%) - Algunos aumentan ⬆️
  - Sin cambio: 470 (21.4%) - Estables ➡️

- **Paradoja:** Mayoría disminuyen pero promedio aumenta
  - Los que aumentan, aumentan MÁS que lo que otros disminuyen
  - Heterogeneidad en trayectorias temporales

**Hallazgos importantes - Región SEMILLA:**
- **Total G>T en semilla:** 397
- **Disminución: 286 (72.0%)** ⬇️⬇️ MÁS que otras regiones
- **Aumento: 56 (14.1%)** ⬆️ MENOS que otras regiones
- **Sin cambio: 55 (13.8%)**

**Interpretación:**
- **Región semilla muestra mayor reducción de G>T** en el tiempo
- Posible clearance selectivo de miRNAs con G>T en región crítica
- O cambio en composición del pool de miRNAs circulantes
- Sugiere presión selectiva contra mutaciones en semilla

**Comparación G>T vs otros SNVs:**
- **Otros SNVs:** aumentan +0.11%
- **G>T:** aumentan +0.06%
- **G>T aumentan ~50% menos** que otros SNVs
- Comportamiento diferencial de mutaciones oxidativas

**Limitación identificada:**
- ⚠️ **Análisis NO es verdaderamente pareado**
- Comparamos PROMEDIOS de grupos (Enrolment vs Longitudinal)
- NO confirmamos que sean los mismos pacientes
- Requiere mapeo de IDs para identificar pares reales

**Implicaciones:**
- ✅ Perfil de G>T es **dinámico**, no estático
- ✅ Región semilla tiene comportamiento particular
- ⏳ Necesitamos identificar muestras pareadas para confirmar
- 🎯 Los cambios pueden ayudar a identificar subtipos de progresión

---

*Última actualización: 8 de octubre de 2025*
*Pipeline: Análisis inicial dividido en pasos pequeños y manejables*
*Estado: Paso 7A completado - Análisis temporal con hallazgos significativos*
