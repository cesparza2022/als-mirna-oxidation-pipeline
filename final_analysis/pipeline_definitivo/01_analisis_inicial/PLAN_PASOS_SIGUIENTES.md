# PLAN DE PASOS SIGUIENTES - ANÁLISIS PIPELINE DEFINITIVO

## 📋 **ESTADO ACTUAL**

**Completado hasta ahora:**
- ✅ Paso 1: Estructura del dataset (1A, 1B, 1C)
- ✅ Paso 2: Análisis profundo de oxidación G>T (2A, 2B, 2C)
- ✅ Paso 3: Análisis de VAFs (3A, 3B, 3C)
- ✅ Paso 4: Análisis estadístico inicial (4A)

**Dataset actual:**
- 29,254 SNVs únicos × 1,247 columnas × 415 muestras
- 2,193 mutaciones G>T (7.5%)
- 819 SNVs significativos ALS vs Control (2.8%)

---

## 🎯 **PRÓXIMOS PASOS**

### **PASO 5: EVALUACIÓN DE CALIDAD (QC ESTADÍSTICO) - SIN LIMPIAR**
**Objetivo:** Identificar y reportar outliers y batch effects, pero **SIN eliminar datos**. Evaluar impacto potencial en mutaciones G>T.

#### **Paso 5A: Identificación de Outliers en Muestras**
**Archivos a generar:**
- `paso5a_outliers_muestras.csv` - Lista de muestras outliers
- `paso5a_distribucion_counts_por_muestra.csv` - Estadísticas de counts
- `paso5a_distribucion_totales_por_muestra.csv` - Estadísticas de totales
- `paso5a_outliers_pca.png` - PCA para identificar muestras anómalas
- `paso5a_distribucion_counts_boxplot.png` - Boxplot de counts
- `paso5a_distribucion_totales_boxplot.png` - Boxplot de totales

**Análisis específicos:**
1. Muestras con total de counts muy bajo (<10th percentile)
2. Muestras con total de counts muy alto (>90th percentile)
3. Muestras con perfil de VAFs anómalo
4. PCA para identificar muestras que se separan del grupo

**Reporte de impacto:**
- ¿Cuántas muestras serían outliers?
- ¿Cuántas son ALS vs Control?
- Si eliminamos outliers, ¿cuántos G>T perdemos?
- ¿Cuántos SNVs significativos perdemos?

**🔑 CRITERIO:** **REPORTAR, NO ELIMINAR**

---

#### **Paso 5B: Identificación de Outliers en SNVs**
**Archivos a generar:**
- `paso5b_outliers_snvs.csv` - Lista de SNVs outliers
- `paso5b_snvs_ubicuos.csv` - SNVs presentes en >95% de muestras
- `paso5b_snvs_raros.csv` - SNVs presentes en <5 muestras
- `paso5b_snvs_vaf_extremo.csv` - SNVs con VAFs extremos
- `paso5b_distribucion_prevalencia_snvs.png` - Distribución de prevalencia
- `paso5b_vaf_extremos_scatter.png` - Scatter de VAFs extremos

**Análisis específicos:**
1. SNVs presentes en >95% de muestras (posibles artefactos técnicos)
2. SNVs presentes en <5 muestras (muy raros, baja potencia estadística)
3. SNVs con VAFs extremadamente altos consistentemente
4. SNVs con patrón de presencia/ausencia sospechoso

**Reporte de impacto:**
- ¿Cuántos SNVs serían outliers?
- ¿Cuántos de estos son G>T?
- Si eliminamos SNVs ubicuos, ¿cuántos G>T perdemos?
- Si eliminamos SNVs raros, ¿cuántos G>T perdemos?
- ¿Cuántos SNVs significativos se verían afectados?

**🔑 CRITERIO:** **REPORTAR, NO ELIMINAR**

---

#### **Paso 5C: Análisis de Batch Effects**
**Archivos a generar:**
- `paso5c_batch_analisis.csv` - Estadísticas por batch
- `paso5c_batch_confounding.csv` - Análisis de confusión batch-cohort
- `paso5c_batch_pca.png` - PCA coloreado por batch
- `paso5c_batch_heatmap.png` - Heatmap de VAFs por batch
- `paso5c_batch_comparacion_als_control.png` - Comparación por batch

**Análisis específicos:**
1. PCA para ver si muestras se agrupan por batch
2. Comparación de VAFs promedio por batch
3. Análisis de confusión: ¿batches correlacionan con cohort?
4. Test de batch effect (ANOVA)
5. Análisis específico de G>T por batch

**Reporte de impacto:**
- ¿Hay batch effects significativos?
- ¿Los batches están balanceados entre ALS y Control?
- ¿Los G>T varían por batch?
- Si corregimos batch, ¿cuántos SNVs significativos cambian?
- ¿Necesitamos corrección de batch (ComBat, limma)?

**🔑 CRITERIO:** **REPORTAR, NO CORREGIR (todavía)**

---

#### **Paso 5D: Reporte de Impacto de Filtros Potenciales**
**Archivos a generar:**
- `paso5d_impacto_filtros_potenciales.csv` - Tabla resumen
- `paso5d_impacto_en_gt.csv` - Impacto específico en G>T
- `paso5d_decision_filtros.md` - Reporte ejecutivo para tomar decisiones

**Simulación de filtros:**
1. **Filtro de counts mínimos:**
   - Criterio: count < 5, 10, 20
   - Impacto: ¿Cuántos SNVs eliminamos? ¿Cuántos G>T?

2. **Filtro de totales mínimos:**
   - Criterio: total < 100, 500, 1000
   - Impacto: ¿Cuántas muestras eliminamos?

3. **Filtro de VAF mínimo:**
   - Criterio: VAF < 0.001, 0.01, 0.05
   - Impacto: ¿Cuántos valores se vuelven NaN? ¿Cuántos G>T?

4. **Filtro de prevalencia:**
   - Criterio: SNV en <5 muestras
   - Impacto: ¿Cuántos SNVs eliminamos? ¿Cuántos G>T?

5. **Filtro de outliers:**
   - Criterio: Eliminar muestras/SNVs identificados como outliers
   - Impacto: ¿Cuántos datos perdemos?

**Tabla de impacto ejemplo:**
```
Filtro              | SNVs perdidos | G>T perdidos | % G>T | SNVs sig. perdidos
--------------------|---------------|--------------|-------|-------------------
count < 5           | 5,234         | 421          | 8.0%  | 45
count < 10          | 8,912         | 678          | 7.6%  | 123
total < 100         | 0 (muestras)  | -            | -     | -
VAF < 0.001         | 12,345 (vals) | 1,234        | 10%   | 234
SNV en < 5 muestras | 3,456         | 289          | 8.4%  | 67
Outliers muestras   | 0 (filas)     | 0            | 0%    | 0
Outliers SNVs       | 234           | 12           | 5.1%  | 8
```

**🔑 OBJETIVO:** Ver qué perdemos ANTES de decidir si vale la pena filtrar

---

### **PASO 6: INTEGRACIÓN DE METADATOS CLÍNICOS**

#### **Paso 6A: Preparación de Metadatos**
**Archivos a generar:**
- `paso6a_metadatos_completos.csv` - Metadatos integrados
- `paso6a_mapeo_muestras.csv` - Mapeo sample ID → metadatos
- `paso6a_resumen_metadatos.csv` - Estadísticas descriptivas

**Tareas:**
1. Cargar metadatos del estudio original (GSE168714)
2. Mapear IDs de muestras (SRR → BLT/BUH/UCH/TST)
3. Limpiar y estandarizar variables
4. Verificar completitud de datos

**Variables a incluir:**
```
Demográficas:
├─ sex (M/F)
├─ Age_at_onset
└─ Age_enrolment

Clínicas:
├─ onset (Bulbar/Non-bulbar) 🔥
├─ ALSFRS (severidad) 🔥
├─ slope (velocidad progresión) 🔥
├─ FVC (capacidad pulmonar)
├─ cognitive (estado cognitivo)
└─ C9ORF72 (genética)

Técnicas:
├─ batch (SRR ID)
└─ timepoint (Enrolment/Longitudinal)

Supervivencia:
├─ survival_enrolment 🔥
├─ status (vivo/fallecido) 🔥
└─ miR_181_numeric (biomarcador) 🔥
```

#### **Paso 6B: Análisis Exploratorio de Metadatos**
**Archivos a generar:**
- `paso6b_distribucion_variables_clinicas.csv`
- `paso6b_correlaciones_metadatos.csv`
- `paso6b_distribucion_sexo_onset.png`
- `paso6b_distribucion_alsfrs_slope.png`
- `paso6b_supervivencia_kaplan_meier_simple.png`

**Análisis:**
1. Distribuciones de variables clínicas
2. Correlaciones entre variables
3. Balance ALS vs Control por subgrupo
4. Datos faltantes por variable

#### **Paso 6C: Vincular Metadatos con SNVs/VAFs**
**Archivos a generar:**
- `paso6c_datos_integrados.rds` - Dataset completo con metadatos
- `paso6c_estructura_final.md` - Documentación de estructura

**Tareas:**
1. Crear dataset integrado (SNVs + VAFs + metadatos)
2. Verificar integridad del vínculo
3. Preparar para análisis por subgrupos

---

### **PASO 7: ANÁLISIS POR SUBGRUPOS CLÍNICOS**

#### **Paso 7A: Análisis Bulbar vs Non-bulbar**
**Archivos a generar:**
- `paso7a_gt_bulbar_vs_nonbulbar.csv`
- `paso7a_vafs_bulbar_vs_nonbulbar.csv`
- `paso7a_comparacion_bulbar_nonbulbar.png`

**Análisis:**
1. Mutaciones G>T en ALS Bulbar vs Non-bulbar
2. VAFs comparativos
3. SNVs diferencialmente expresados
4. Patrones específicos por subtipo

#### **Paso 7B: Análisis por Severidad (ALSFRS)**
**Archivos a generar:**
- `paso7b_gt_por_alsfrs.csv`
- `paso7b_correlacion_alsfrs_gt.png`

**Análisis:**
1. Correlación G>T vs ALSFRS
2. Categorización por severidad (leve, moderado, severo)
3. SNVs asociados a severidad

#### **Paso 7C: Análisis por Velocidad de Progresión (slope)**
**Archivos a generar:**
- `paso7c_gt_por_slope.csv`
- `paso7c_correlacion_slope_gt.png`

**Análisis:**
1. Correlación G>T vs slope (progresión rápida vs lenta)
2. Categorización por velocidad
3. Biomarcadores de progresión rápida

#### **Paso 7D: Análisis Temporal (Enrolment vs Longitudinal)**
**Archivos a generar:**
- `paso7d_gt_temporal.csv`
- `paso7d_cambios_longitudinales.png`

**Análisis:**
1. Cambios en G>T en muestras longitudinales
2. Progresión de oxidación en el tiempo
3. Patrones dinámicos

---

### **PASO 8: ANÁLISIS DE BIOMARCADORES**

#### **Paso 8A: miR-181 como Biomarcador (Replicar Paper)**
**Archivos a generar:**
- `paso8a_mir181_analisis.csv`
- `paso8a_mir181_supervivencia.png`
- `paso8a_mir181_replicacion_paper.md`

**Análisis:**
1. Replicar análisis del paper original
2. miR-181 alto vs bajo en supervivencia
3. Validar biomarcador

#### **Paso 8B: G>T como Biomarcador de Oxidación**
**Archivos a generar:**
- `paso8b_gt_como_biomarcador.csv`
- `paso8b_gt_supervivencia.png`
- `paso8b_gt_categorizacion.csv`

**Análisis:**
1. Categorizar pacientes por nivel de G>T
2. Alto G>T vs Bajo G>T en supervivencia
3. G>T como predictor

#### **Paso 8C: Combinaciones de Biomarcadores**
**Archivos a generar:**
- `paso8c_combinaciones_biomarcadores.csv`
- `paso8c_mir181_gt_interaccion.png`

**Análisis:**
1. miR-181 + G>T combinados
2. Otros biomarcadores + G>T
3. Modelos de combinación

---

### **PASO 9: ANÁLISIS DE SUPERVIVENCIA**

#### **Paso 9A: Kaplan-Meier**
**Archivos a generar:**
- `paso9a_kaplan_meier_cohort.png` - ALS vs Control
- `paso9a_kaplan_meier_onset.png` - Bulbar vs Non-bulbar
- `paso9a_kaplan_meier_gt.png` - Alto G>T vs Bajo G>T
- `paso9a_kaplan_meier_mir181.png` - Alto miR-181 vs Bajo

#### **Paso 9B: Cox Regression**
**Archivos a generar:**
- `paso9b_cox_univariado.csv`
- `paso9b_cox_multivariado.csv`
- `paso9b_forest_plot.png`

**Análisis:**
1. Cox univariado para cada variable
2. Cox multivariado ajustado
3. Hazard ratios para G>T

#### **Paso 9C: G>T y Supervivencia**
**Archivos a generar:**
- `paso9c_gt_supervivencia_detallado.csv`
- `paso9c_gt_por_region_supervivencia.png`
- `paso9c_gt_por_posicion_supervivencia.png`

**Análisis:**
1. ¿G>T predice supervivencia?
2. ¿Qué regiones/posiciones G>T predicen mejor?
3. ¿G>T es independiente de otros factores?

---

### **PASO 10: MODELOS MULTIVARIADOS**

#### **Paso 10A: GLMM para Control de Confusores**
**Archivos a generar:**
- `paso10a_glmm_batch.csv`
- `paso10a_glmm_edad_sexo.csv`
- `paso10a_efectos_confusores.png`

**Análisis:**
1. Modelo con batch como efecto aleatorio
2. Ajuste por edad y sexo
3. Efectos de confusión

#### **Paso 10B: Corrección de Batch Effects (si es necesario)**
**Archivos a generar:**
- `paso10b_datos_corregidos_batch.rds`
- `paso10b_antes_despues_correccion.png`
- `paso10b_validacion_correccion.csv`

**Análisis:**
1. ComBat o limma para corrección
2. Validación de corrección
3. Re-análisis de SNVs significativos

---

## 📊 **ESTRUCTURA DEL PASO 5 (DETALLADO)**

### **Paso 5A: Outliers en Muestras**

**Script:** `paso5a_outliers_muestras.R`

**Análisis 1: Distribución de counts totales**
```r
# Para cada muestra, calcular:
# - Total de counts (suma de todos los SNVs)
# - Percentiles 5%, 25%, 50%, 75%, 95%
# - Identificar outliers (< p5 o > p95)
# - Clasificar por cohort (ALS vs Control)
```

**Análisis 2: Distribución de totales**
```r
# Para cada muestra, calcular:
# - Total promedio de miRNA
# - Identificar muestras con totales muy bajos
# - Clasificar por cohort
```

**Análisis 3: PCA de VAFs**
```r
# PCA de matriz de VAFs (muestras × SNVs)
# Identificar muestras que se separan del grupo
# Colorear por:
# - Cohort (ALS/Control)
# - Batch
# - Onset (si disponible)
```

**Análisis 4: Perfiles de VAFs anómalos**
```r
# Identificar muestras con:
# - VAFs sistemáticamente muy altos
# - VAFs sistemáticamente muy bajos
# - Patrón de VAFs inconsistente con su grupo
```

**Reporte de impacto:**
```
TABLA DE IMPACTO - OUTLIERS EN MUESTRAS
────────────────────────────────────────────────────────────
Criterio          | N muestras | ALS | Control | G>T perdidos
────────────────────────────────────────────────────────────
Counts < p5       | XX         | XX  | XX      | ~XXX
Counts > p95      | XX         | XX  | XX      | ~XXX
Totales < 100     | XX         | XX  | XX      | ~XXX
PCA outliers      | XX         | XX  | XX      | ~XXX
VAF anómalos      | XX         | XX  | XX      | ~XXX
────────────────────────────────────────────────────────────
TOTAL ÚNICO       | XX         | XX  | XX      | ~XXX
────────────────────────────────────────────────────────────

⚠️  DECISIÓN PENDIENTE: ¿Eliminar estas muestras?
```

---

### **Paso 5B: Outliers en SNVs**

**Script:** `paso5b_outliers_snvs.R`

**Análisis 1: SNVs ubicuos**
```r
# Identificar SNVs presentes en >95% de muestras
# ¿Son artefactos técnicos o variantes comunes?
# Verificar si son G>T
```

**Análisis 2: SNVs raros**
```r
# Identificar SNVs presentes en <5 muestras
# ¿Son ruido o variantes raras reales?
# Verificar si son G>T
# Baja potencia estadística
```

**Análisis 3: VAFs extremos**
```r
# Identificar SNVs con VAFs consistentemente muy altos
# (después de filtrar >50%)
# ¿Son reales o artefactos?
```

**Reporte de impacto:**
```
TABLA DE IMPACTO - OUTLIERS EN SNVs
────────────────────────────────────────────────────────────
Criterio          | N SNVs | G>T | % G>T total | SNVs sig.
────────────────────────────────────────────────────────────
Prevalencia >95%  | XX     | XX  | XX%         | XX
Prevalencia <5    | XX     | XX  | XX%         | XX
VAF extremo       | XX     | XX  | XX%         | XX
Patrón anómalo    | XX     | XX  | XX%         | XX
────────────────────────────────────────────────────────────
TOTAL ÚNICO       | XX     | XX  | XX%         | XX
────────────────────────────────────────────────────────────

⚠️  DECISIÓN PENDIENTE: ¿Eliminar estos SNVs?
```

---

### **Paso 5C: Batch Effects**

**Script:** `paso5c_batch_effects.R`

**Análisis 1: PCA por batch**
```r
# PCA de VAFs coloreado por batch
# ¿Las muestras se agrupan por batch?
# ¿O se agrupan por cohort (ALS/Control)?
```

**Análisis 2: Confusión batch-cohort**
```r
# Tabla de contingencia:
#          ALS | Control
# Batch 1   XX |   XX
# Batch 2   XX |   XX
# ...
# ¿Están balanceados los batches?
```

**Análisis 3: VAFs por batch**
```r
# Comparación de VAFs promedio por batch
# ANOVA: ¿hay diferencias significativas?
# Específico para G>T
```

**Reporte de impacto:**
```
TABLA DE IMPACTO - BATCH EFFECTS
────────────────────────────────────────────────────────────
Análisis              | Resultado | Interpretación
────────────────────────────────────────────────────────────
PCA agrupa por batch  | Sí/No     | Hay/No hay batch effect
Confusión batch-ALS   | r = X.XX  | Alta/Baja confusión
ANOVA VAFs            | p < 0.05  | Batch effect significativo
G>T varía por batch   | p = X.XX  | Sí/No varía
────────────────────────────────────────────────────────────

⚠️  DECISIÓN PENDIENTE: 
    ¿Necesitamos corrección de batch (ComBat, limma)?
    ¿Incluir batch como covariable en modelos?
```

---

### **Paso 5D: Reporte Ejecutivo de Decisión**

**Script:** `paso5d_reporte_decision_filtros.R`

**Genera:** `paso5d_decision_filtros.md`

**Contenido:**
```markdown
# REPORTE EJECUTIVO - DECISIÓN DE FILTROS

## RESUMEN DE OUTLIERS IDENTIFICADOS

### Muestras Outliers:
- Total: XX muestras (X.X%)
- ALS: XX
- Control: XX
- Impacto en G>T: -XX mutaciones

### SNVs Outliers:
- Total: XX SNVs (X.X%)
- G>T: XX (X.X% de todos los G>T)
- Impacto en análisis: -XX SNVs significativos

### Batch Effects:
- Efecto detectado: Sí/No
- Magnitud: Leve/Moderado/Severo
- Necesita corrección: Sí/No

## RECOMENDACIONES

### Opción 1: Dataset Permisivo (Actual)
**Ventajas:**
- Máxima información
- No perdemos G>T raros
- Bueno para exploración

**Desventajas:**
- Posibles artefactos incluidos
- Menor poder estadístico
- Batch effects no corregidos

### Opción 2: Dataset Filtrado Estricto
**Ventajas:**
- Mayor confianza en resultados
- Mejor poder estadístico
- Batch effects corregidos

**Desventajas:**
- Perdemos XX SNVs (XX G>T)
- Menor muestra
- Posible pérdida de señal biológica

### Opción 3: Dos Datasets Paralelos
**Ventajas:**
- Comparar resultados
- Validación cruzada
- Mejor interpretación

**Desventajas:**
- Más trabajo
- Más archivos
- Más complejo

## DECISIÓN SUGERIDA
[A completar después del análisis]
```

---

## 🎯 **PLAN ACTUALIZADO CON TU ENFOQUE**

### **Filosofía del Paso 5:**
> **REPORTAR TODO, NO LIMPIAR NADA (todavía)**
> 
> Objetivo: Tener información completa para tomar decisiones informadas
> 
> Enfoque especial: ¿Cuántos G>T perdemos con cada filtro?

### **Orden de ejecución:**
```
Paso 5A: Outliers en muestras (reportar)
   ↓
Paso 5B: Outliers en SNVs (reportar)
   ↓
Paso 5C: Batch effects (reportar)
   ↓
Paso 5D: Reporte ejecutivo de impacto
   ↓
[PAUSA PARA DECISIÓN]
   ↓
Paso 6: Integración de metadatos
   ↓
Paso 7-10: Análisis clínicos avanzados
```

---

## 📌 **PRÓXIMA ACCIÓN INMEDIATA:**

**¿Empezamos con Paso 5A: Identificación y reporte de outliers en muestras?**

Este paso generará:
1. Lista de muestras outliers (sin eliminarlas)
2. Caracterización de estas muestras
3. **Impacto estimado en mutaciones G>T**
4. Visualizaciones (PCA, boxplots)

**Tiempo estimado:** 15-20 minutos

**¿Procedemos?**









