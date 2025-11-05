# EXPLICACIÓN DETALLADA: ¿POR QUÉ PERDEMOS TANTO G>T CON OUTLIERS?

## 🎯 **RESUMEN DEL PROBLEMA**

**Hallazgo:**
- 84 muestras outliers (20.2% del total)
- Si las eliminamos, perdemos 280 mutaciones G>T (12.77%)
- Y 419 G>T más se verían afectadas (19.11%)
- **Total afectado: 699 G>T (31.88%)**

**Pregunta clave:** ¿Por qué perdemos TANTO con solo 20% de muestras?

---

## 📊 **CRITERIOS USADOS PARA IDENTIFICAR OUTLIERS**

### **4 Criterios Independientes (Percentiles 5% y 95%)**

```
Criterio 1: COUNTS TOTALES
├─ Suma de todos los SNVs detectados en cada muestra
├─ Outlier BAJO: < 211,499 counts (5% inferior)
├─ Outlier ALTO: > 5,637,282 counts (5% superior)
└─ Resultado: 21 bajas + 21 altas = 42 muestras

Criterio 2: TOTALES PROMEDIO
├─ Promedio de reads de miRNA por muestra
├─ Outlier BAJO: < 447 reads (5% inferior)
├─ Outlier ALTO: > 11,935 reads (5% superior)
└─ Resultado: 21 bajas + 21 altas = 42 muestras

Criterio 3: PCA (Separación Multivariada)
├─ Distancia euclidiana al centro del PCA
├─ Outlier: > percentil 95 de distancia
└─ Resultado: 21 muestras (TODAS ALS)

Criterio 4: PERFIL DE VAFs
├─ VAF promedio por muestra
├─ Outlier BAJO: VAF < p5 (VAFs muy bajos)
├─ Outlier ALTO: VAF > p95 (VAFs muy altos)
└─ Resultado: 21 bajas + 21 altas = 42 muestras
```

**Total consolidado:** 84 muestras (con al menos 1 criterio)

---

## 🔍 **¿POR QUÉ PERDEMOS TANTO G>T?**

### **HALLAZGO CRÍTICO 1: Mutaciones G>T RARAS**

**Las 280 mutaciones G>T que perdemos están en:**
```
241 mutaciones (86%) → Solo en 1 muestra
 25 mutaciones (9%)  → Solo en 2 muestras
  7 mutaciones (2%)  → Solo en 3 muestras
  7 mutaciones (3%)  → En 4-14 muestras
```

**Conclusión:**
> **86% de las mutaciones G>T que perdemos son ULTRA-RARAS**
> (Solo en 1 muestra en todo el dataset)

**¿Por qué sucede esto?**

**Hipótesis 1: Muestras outliers tienen mayor sensibilidad de detección**
```
Outliers ALTOS (counts altos):
├─ Tienen más cobertura
├─ Detectan mutaciones de muy baja frecuencia
└─ Mutaciones que en otras muestras están por debajo del umbral de detección

Resultado: Mutaciones "únicas" de estas muestras
```

**Hipótesis 2: Muestras outliers son casos clínicos extremos**
```
Outliers PCA (perfil diferente):
├─ Pueden ser subtipo clínico diferente (ej. Bulbar severo)
├─ Tienen perfil de mutaciones único
└─ Sus mutaciones G>T son específicas de ese subtipo

Resultado: Mutaciones específicas de subtipo
```

---

### **HALLAZGO CRÍTICO 2: Distribución Desigual de G>T**

**Ejemplo visual:**
```
Mutación: hsa-let-7a-5p, posición 2:GT
├─ Total muestras con esta mutación: 44
├─ Muestras normales: 21 (47.7%)
├─ Muestras outliers: 23 (52.3%)
└─ Clasificación: "Mostly in outliers" (más en outliers que en normales)

Mutación: hsa-let-7c-5p, posición 2:GT
├─ Total muestras con esta mutación: 2
├─ Muestras normales: 0 (0%)
├─ Muestras outliers: 2 (100%)
└─ Clasificación: "Only in outliers" (se perdería si eliminamos outliers)
```

**Patrón general:**
```
Mutaciones G>T comunes (presentes en muchas muestras):
└─ Están en muestras normales Y outliers
    └─ NO se pierden si eliminamos outliers ✅

Mutaciones G>T raras (presentes en pocas muestras):
└─ Tienden a estar SOLO en outliers
    └─ SE PIERDEN si eliminamos outliers ❌
```

---

### **HALLAZGO CRÍTICO 3: Posiciones Específicas**

Déjame analizar qué posiciones se pierden más:

<function_calls>
<invoke name="run_terminal_cmd">
<parameter name="command">cd /Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/pipeline_definitivo/01_analisis_inicial/outputs/paso5a_outliers_muestras && awk -F',' '$6=="TRUE" {print $2}' paso5a_gt_impacto_outliers.csv | sed 's/:GT$//' | sed 's/^.*://' | sort | uniq -c | sort -rn








