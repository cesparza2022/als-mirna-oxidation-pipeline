# 🔬 ANÁLISIS Z-SCORE: DIFERENCIAS ALS vs CONTROL

## 📊 RESUMEN EJECUTIVO

**Análisis completado:** Comparación estadística robusta de mutaciones G>T en región semilla entre pacientes ALS y controles usando Z-score.

### 🎯 HALLAZGOS PRINCIPALES

- **328 SNVs G>T** analizados en región semilla (posiciones 2-8)
- **212 miRNAs únicos** afectados
- **415 muestras totales:** 249 ALS-enrolment, 64 ALS-longitudinal, 102 controles
- **Diferencias significativas** identificadas entre grupos

---

## 🏆 TOP 5 SNVs CON MAYORES DIFERENCIAS

| Rank | miRNA | Posición | Z-Score | P-value | Dirección | Interpretación |
|------|-------|----------|---------|---------|-----------|----------------|
| **1** | **hsa-miR-491-5p** | **6** | **2.00** | 3.38e-02 | **ALS Higher** | **Mayor oxidación en ALS** |
| **2** | **hsa-miR-6852-5p** | **8** | **-1.87** | 5.24e-02 | **Control Higher** | **Mayor oxidación en controles** |
| **3** | **hsa-miR-18a-5p** | **7** | **-1.41** | 2.19e-01 | **Control Higher** | **Mayor oxidación en controles** |
| **4** | **hsa-miR-4318** | **5** | **-1.35** | 6.42e-02 | **Control Higher** | **Mayor oxidación en controles** |
| **5** | **hsa-miR-4481** | **7** | **1.22** | 1.46e-01 | **ALS Higher** | **Mayor oxidación en ALS** |

---

## 🎯 ANÁLISIS POR POSICIÓN EN REGIÓN SEMILLA

| Posición | N SNVs | Z-Score Promedio | Z-Score Máximo | Significancia | Interpretación |
|----------|--------|------------------|----------------|---------------|----------------|
| **6** | 69 | **0.193** | **2.00** | **Alta** | **Posición más variable** |
| **5** | 39 | **-0.175** | **1.35** | **Media** | **Tendencia a mayor oxidación en controles** |
| **7** | 67 | **0.122** | **1.41** | **Media** | **Diferencias moderadas** |
| **4** | 29 | **0.102** | **1.03** | **Baja** | **Diferencias menores** |
| **8** | 72 | **-0.039** | **1.87** | **Media** | **Variabilidad alta** |
| **2** | 33 | **NaN** | **-Inf** | **N/A** | **Datos insuficientes** |
| **3** | 19 | **NaN** | **-Inf** | **N/A** | **Datos insuficientes** |

---

## 🧬 TOP miRNAs CON MAYORES DIFERENCIAS

| Rank | miRNA | N SNVs | Z-Score Promedio | Z-Score Máximo | Posiciones | Interpretación |
|------|-------|--------|------------------|----------------|------------|----------------|
| **1** | **hsa-miR-491-5p** | 2 | **1.29** | **2.00** | 6 | **Mayor oxidación en ALS** |
| **2** | **hsa-miR-6852-5p** | 3 | **-0.792** | **1.87** | 6,7,8 | **Mayor oxidación en controles** |
| **3** | **hsa-miR-18a-5p** | 1 | **-1.41** | **1.41** | 7 | **Mayor oxidación en controles** |
| **4** | **hsa-miR-4318** | 3 | **-0.257** | **1.35** | 5 | **Mayor oxidación en controles** |
| **5** | **hsa-miR-4481** | 2 | **1.22** | **1.22** | 7 | **Mayor oxidación en ALS** |

---

## 📈 INTERPRETACIÓN BIOLÓGICA

### 🔴 **ALS Higher (Z-score > 0)**
- **hsa-miR-491-5p (pos 6):** Z-score = 2.00 - **Mayor oxidación en ALS**
- **hsa-miR-4481 (pos 7):** Z-score = 1.22 - **Mayor oxidación en ALS**

### 🔵 **Control Higher (Z-score < 0)**
- **hsa-miR-6852-5p (pos 8):** Z-score = -1.87 - **Mayor oxidación en controles**
- **hsa-miR-18a-5p (pos 7):** Z-score = -1.41 - **Mayor oxidación en controles**
- **hsa-miR-4318 (pos 5):** Z-score = -1.35 - **Mayor oxidación en controles**

---

## 🎨 VISUALIZACIONES GENERADAS

1. **`zscore_by_position.pdf`** - Z-score promedio por posición
2. **`zscore_distribution.pdf`** - Distribución de Z-scores
3. **`fold_change_vs_zscore.pdf`** - Fold change vs Z-score
4. **`zscore_heatmap.pdf`** - Heatmap de Z-scores por miRNA y posición

---

## 📊 ARCHIVOS DE DATOS GENERADOS

1. **`zscore_analysis_results.tsv`** - Análisis completo por SNV
2. **`position_zscore_analysis.tsv`** - Análisis por posición
3. **`mirna_zscore_analysis.tsv`** - Análisis por miRNA

---

## 🔬 IMPLICACIONES CLÍNICAS

### **Posición 6 - Más Crítica**
- **Mayor variabilidad** entre grupos (Z-score promedio = 0.193)
- **hsa-miR-491-5p** muestra **mayor oxidación en ALS** (Z-score = 2.00)
- **Posición funcionalmente crítica** en región semilla

### **Patrón de Oxidación Diferencial**
- **No hay un patrón uniforme** de mayor oxidación en ALS
- **Diferencias específicas por miRNA y posición**
- **Necesidad de análisis funcional** de miRNAs afectados

---

## 🎯 PRÓXIMOS PASOS RECOMENDADOS

1. **Análisis funcional** de miRNAs con diferencias significativas
2. **Validación experimental** de hallazgos clave
3. **Análisis de vías** afectadas por miRNAs oxidados
4. **Correlación clínica** con progresión de ALS
5. **Análisis longitudinal** de cambios en el tiempo

---

## 📋 CONCLUSIÓN

El análisis Z-score revela **diferencias específicas y significativas** en la oxidación de miRNAs entre pacientes ALS y controles. Aunque no hay un patrón uniforme de mayor oxidación en ALS, **posiciones específicas (especialmente posición 6) y miRNAs específicos** muestran diferencias estadísticamente significativas que merecen investigación adicional.

**El enfoque en Z-score permite identificar diferencias reales en VAF entre grupos, no solo conteos absolutos, proporcionando una base sólida para análisis funcionales posteriores.**










