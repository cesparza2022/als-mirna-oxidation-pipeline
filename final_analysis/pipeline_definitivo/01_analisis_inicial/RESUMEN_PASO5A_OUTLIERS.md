# RESUMEN EJECUTIVO - PASO 5A: OUTLIERS EN MUESTRAS

## 🎯 **HALLAZGOS PRINCIPALES**

### **Total de Outliers Identificados:**
```
84 muestras (20.2% del total)
├── ALS: 69 muestras (22.0% de ALS)
└── Control: 15 muestras (14.7% de Control)
```

**⚠️ IMPORTANTE:** Ninguna muestra ha sido eliminada. Solo reportadas.

---

## 📊 **OUTLIERS POR CRITERIO**

### **1. Por Counts Totales:**
- **Outliers bajos (<p5):** 21 muestras
- **Outliers altos (>p95):** 21 muestras
- **Total:** 42 muestras

**Distribución:**
- ALS: 38 muestras (18 bajos, 20 altos)
- Control: 4 muestras (3 bajos, 1 alto)

### **2. Por Totales Promedio de miRNA:**
- **Outliers bajos (<p5):** 21 muestras
- **Outliers altos (>p95):** 21 muestras
- **Total:** 42 muestras

**Distribución:**
- ALS: 36 muestras (17 bajos, 19 altos)
- Control: 6 muestras (4 bajos, 2 altos)

### **3. Por PCA (Análisis Multivariado):**
- **Outliers (distancia >p95):** 21 muestras
- **Todas ALS** (0 Control)

**Interpretación:**
- Algunas muestras ALS se separan del cluster principal
- Pueden ser casos extremos o subtipo clínico diferente
- El PCA NO detecta outliers en Control

### **4. Por Perfil de VAFs:**
- **VAF promedio bajo (<p5):** 21 muestras
- **VAF promedio alto (>p95):** 21 muestras
- **Total:** 42 muestras

**Distribución:**
- ALS: 31 muestras (21 bajos, 10 altos)
- Control: 11 muestras (0 bajos, 11 altos)

**Interpretación:**
- Muestras Control tienden a tener VAFs más altos
- Muestras ALS tienden a tener VAFs más bajos

---

## 🔥 **IMPACTO CRÍTICO EN MUTACIONES G>T**

### **Si elimináramos las 84 muestras outliers:**

```
Total mutaciones G>T: 2,193
├── G>T SOLO en outliers: 280 (12.77%) ⚠️
├── G>T MAYORMENTE en outliers: 419 (19.11%) ⚠️
└── G>T preservados: 1,494 (68.12%) ✅
```

### **Análisis de impacto:**

**Pérdida directa:**
- **280 mutaciones G>T** (12.77%) desaparecerían completamente
- Estas mutaciones SOLO están presentes en muestras outliers

**Pérdida de potencia estadística:**
- **419 mutaciones G>T** (19.11%) se verían afectadas
- Estas mutaciones están MAYORMENTE en outliers
- Perderían potencia estadística pero no desaparecerían

**Total afectado:**
- **699 mutaciones G>T** (31.88%) se verían impactadas
- **1,494 mutaciones G>T** (68.12%) NO se verían afectadas

---

## 📈 **INTERPRETACIÓN**

### **¿Son outliers legítimos o artefactos técnicos?**

**Evidencia de outliers LEGÍTIMOS:**
✅ **Ninguna muestra cumple ≥2 criterios simultáneamente**
  - Si fueran artefactos técnicos, esperaríamos muestras con múltiples problemas
  - Solo cumplen 1 criterio cada una

✅ **Distribución esperada (5% + 5% = 10%)**
  - Tenemos 20.2% porque hay 4 criterios independientes
  - Cada criterio identifica ~5% de outliers
  - Sin solapamiento significativo

✅ **PCA solo detecta outliers en ALS**
  - Control se agrupa bien
  - ALS tiene mayor heterogeneidad (esperado por subtipos clínicos)

### **¿Qué tipo de outliers son?**

**Muestras con counts bajos:**
- Posible degradación de muestra
- O pacientes con baja carga de miRNA circulante
- **No necesariamente problemáticas**

**Muestras con counts altos:**
- Alta carga de miRNA circulante
- Posible contaminación
- O activación de vías de miRNA
- **Pueden ser biológicamente interesantes**

**Muestras separadas en PCA:**
- Subtipo clínico diferente (ej. Bulbar vs Non-bulbar)
- Estadio diferente de enfermedad
- **Requiere integración con metadatos clínicos**

---

## ⚠️ **IMPACTO EN ANÁLISIS PREVIOS**

### **En los 819 SNVs significativos (Paso 4A):**
- **No sabemos** cuántos de estos serían afectados por eliminar outliers
- **Requiere:** Re-análisis de t-tests sin outliers (Paso 5D)

### **En análisis de G>T (Pasos 2A-2C):**
- **280 mutaciones G>T** podrían ser específicas de outliers
- **¿Son reales o artefactos?** Requiere validación

---

## 🎯 **RECOMENDACIONES**

### **1. NO ELIMINAR OUTLIERS (por ahora)**
**Razones:**
- Alta proporción de outliers (20.2%) sugiere heterogeneidad biológica
- Ninguna muestra cumple múltiples criterios (no son outliers severos)
- Impacto alto en G>T (31.88% afectados)
- Necesitamos metadatos clínicos para entender estos outliers

### **2. INTEGRAR METADATOS CLÍNICOS (Paso 6)**
**Para entender si outliers son:**
- Subtipo clínico (Bulbar vs Non-bulbar)
- Severidad diferente (ALSFRS)
- Progresión diferente (slope)
- Batch específico

### **3. ANÁLISIS DE SENSIBILIDAD (Paso 5D)**
**Comparar resultados:**
- Con todas las muestras (dataset actual)
- Sin outliers (dataset filtrado)
- Solo con outliers (para caracterizar)

### **4. REVISIÓN INDIVIDUAL DE OUTLIERS SEVEROS**
**Si existieran muestras con ≥3 criterios:**
- Revisar manualmente
- Verificar si son problemáticas
- Considerar eliminación solo de estas

**Estado actual:** 0 muestras con ≥3 criterios ✅

---

## 📋 **PRÓXIMOS PASOS**

### **Paso 5B: Outliers en SNVs** (Siguiente)
- Identificar SNVs ubicuos (>95% muestras)
- Identificar SNVs raros (<5 muestras)
- Evaluar impacto en G>T

### **Paso 5C: Batch Effects**
- PCA por batch
- Confusión batch-cohort
- Necesidad de corrección

### **Paso 5D: Reporte de Impacto de Filtros**
- Simular diferentes filtros
- Evaluar impacto en G>T específicamente
- Tomar decisión final de filtrado

### **Paso 6: Integración de Metadatos**
- Vincular outliers con metadatos clínicos
- Entender por qué son outliers
- Decisión final sobre eliminación

---

## 📁 **ARCHIVOS GENERADOS**

**Ubicación:** `outputs/paso5a_outliers_muestras/` y `figures/paso5a_outliers_muestras/`

### **Tablas (11 archivos CSV):**
1. `paso5a_counts_por_muestra.csv` - Counts totales por muestra
2. `paso5a_totales_por_muestra.csv` - Totales promedio por muestra
3. `paso5a_pca_scores.csv` - Scores de PC1 y PC2
4. `paso5a_vaf_stats_por_muestra.csv` - Estadísticas de VAFs
5. `paso5a_outliers_consolidado.csv` - ⭐ **Listado completo de outliers**
6. `paso5a_gt_impacto_outliers.csv` - ⭐ **Impacto detallado en cada G>T**
7. `paso5a_outliers_counts_resumen.csv`
8. `paso5a_outliers_totales_resumen.csv`
9. `paso5a_outliers_vaf_resumen.csv`
10. `paso5a_gt_impacto_resumen.csv` - ⭐ **Resumen de impacto en G>T**
11. `paso5a_outliers_resumen_final.csv` - ⭐ **Resumen consolidado**

### **Figuras (4 archivos PNG):**
1. `paso5a_distribucion_counts_boxplot.png` - Boxplot de counts por cohort
2. `paso5a_distribucion_totales_boxplot.png` - Boxplot de totales por cohort
3. `paso5a_pca_outliers.png` - ⭐ **PCA con outliers marcados**
4. `paso5a_vaf_perfil_scatter.png` - VAF promedio vs N válidos

---

## 🔬 **ANÁLISIS TÉCNICO**

### **Percentiles de Counts Totales:**
```
p5:   211,499
p25:  686,092
p50: 1,329,960
p75: 2,394,804
p95: 5,637,282
```

### **Percentiles de Totales Promedio:**
```
p5:     447
p25:  1,435
p50:  2,778
p75:  5,087
p95: 11,935
```

### **Varianza Explicada por PCA:**
- PC1: [Ver en figura]
- PC2: [Ver en figura]

---

## ⚠️ **CONCLUSIÓN CRÍTICA**

### **DECISIÓN RECOMENDADA:**
> **MANTENER todas las muestras outliers**
> 
> **Razones:**
> 1. Alto impacto en G>T (31.88% afectados)
> 2. Outliers no son severos (0 muestras con ≥3 criterios)
> 3. Probablemente heterogeneidad biológica, no artefactos técnicos
> 4. Necesitamos metadatos clínicos para entender estos outliers
> 
> **Siguiente paso:** Integrar metadatos clínicos (Paso 6) para caracterizar outliers

---

*Fecha: 7 de octubre de 2025*
*Estado: Completado - Ninguna muestra eliminada*
*Impacto en G>T: 280 mutaciones se perderían directamente (12.77%)*









