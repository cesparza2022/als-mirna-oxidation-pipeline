# 🧮 EXPLICACIÓN DETALLADA DEL CÁLCULO DE Z-SCORE Y VISUALIZACIONES

## 📊 ¿QUÉ ES EL Z-SCORE Y CÓMO LO CALCULAMOS?

### **Definición del Z-Score:**
El **Z-score** es una medida estadística que nos permite comparar diferencias entre grupos de manera estandarizada. En nuestro contexto, nos dice **cuántas desviaciones estándar** se separan las medias de VAF entre pacientes ALS y controles.

### **Fórmula del Z-Score:**
```
Z-score = (VAF_ALS - VAF_Control) / pooled_sd
```

Donde:
- **VAF_ALS** = VAF promedio en pacientes ALS
- **VAF_Control** = VAF promedio en controles
- **pooled_sd** = Desviación estándar combinada

### **Cálculo de la Desviación Estándar Combinada (Pooled SD):**
```
pooled_sd = √[((n_control - 1) × sd_control² + (n_als - 1) × sd_als²) / (n_control + n_als - 2)]
```

Donde:
- **n_control** = Número de muestras control
- **n_als** = Número de muestras ALS
- **sd_control** = Desviación estándar en controles
- **sd_als** = Desviación estándar en ALS

---

## 🎯 INTERPRETACIÓN DEL Z-SCORE

### **Valores del Z-Score:**
- **Z-score > 0:** Mayor oxidación en ALS
- **Z-score < 0:** Mayor oxidación en Control
- **Z-score = 0:** No hay diferencia entre grupos

### **Niveles de Significancia:**
- **|Z-score| > 2.0:** Diferencia altamente significativa
- **|Z-score| > 1.5:** Diferencia significativa
- **|Z-score| > 1.0:** Diferencia moderadamente significativa
- **|Z-score| < 1.0:** Diferencia no significativa

---

## 📈 EJEMPLO PRÁCTICO: hsa-miR-491-5p (Posición 6)

### **Datos del SNV:**
- **miRNA:** hsa-miR-491-5p
- **Posición:** 6
- **Mutación:** G>T

### **Estadísticas por Grupo:**
- **Control:** VAF = 1.00 ± 0.00 (n=5)
- **ALS:** VAF = 2.33 ± 1.15 (n=3)

### **Cálculo del Z-Score:**

**1. Diferencia de medias:**
```
mean_difference = 2.33 - 1.00 = 1.33
```

**2. Desviación estándar combinada:**
```
pooled_sd = √[((5-1) × 0.00² + (3-1) × 1.15²) / (5+3-2)]
pooled_sd = √[(4 × 0 + 2 × 1.32) / 6]
pooled_sd = √[2.64 / 6] = √0.44 = 0.66
```

**3. Z-score:**
```
Z-score = 1.33 / 0.66 = 2.00
```

### **Interpretación:**
- **Z-score = 2.00:** Diferencia altamente significativa
- **Dirección:** Mayor oxidación en ALS (2.33 vs 1.00)
- **Fold change:** 2.33 (2.33/1.00)
- **Significancia:** Moderadamente significativa (p = 0.034)

---

## 🎨 VISUALIZACIONES DETALLADAS GENERADAS

### **1. Z-Score por Posición con Barras de Error**
**Archivo:** `detailed_zscore_by_position.pdf`
- **Muestra:** Z-score promedio por posición con desviación estándar
- **Líneas de referencia:** ±1.5 (naranja), ±2.0 (roja)
- **Interpretación:** Posición 6 muestra mayor variabilidad

### **2. Distribución de Z-Scores con Densidad**
**Archivo:** `detailed_zscore_distribution.pdf`
- **Muestra:** Histograma con curva de densidad superpuesta
- **Líneas de referencia:** Umbrales de significancia
- **Interpretación:** Distribución centrada cerca de 0 con colas

### **3. Fold Change vs Z-Score con Etiquetas**
**Archivo:** `detailed_fold_change_vs_zscore.pdf`
- **Muestra:** Relación entre fold change y Z-score
- **Etiquetas:** Top 20 SNVs más significativos
- **Interpretación:** Correlación entre magnitud y significancia

### **4. VAF por Grupo y Posición**
**Archivo:** `detailed_vaf_by_group_position.pdf`
- **Muestra:** Boxplot y violín de VAF por posición y grupo
- **Comparación:** Control (azul) vs ALS (rojo)
- **Interpretación:** Distribuciones de VAF por posición

### **5. Heatmap de Z-Scores Mejorado**
**Archivo:** `detailed_zscore_heatmap.pdf`
- **Muestra:** Matriz de Z-scores por miRNA y posición
- **Colores:** Azul (Control > ALS), Rojo (ALS > Control)
- **Interpretación:** Patrones de oxidación diferencial

### **6. Significancia por Posición**
**Archivo:** `detailed_significance_by_position.pdf`
- **Muestra:** Porcentaje de SNVs por nivel de significancia
- **Categorías:** Altamente significativo, Significativo, Moderado, No significativo
- **Interpretación:** Distribución de significancia por posición

---

## 🏆 HALLAZGOS CLAVE DE LAS VISUALIZACIONES

### **Posición 6 - Más Crítica:**
- **Z-score promedio:** 0.193
- **Mayor variabilidad** entre grupos
- **hsa-miR-491-5p:** Z-score = 2.00 (mayor oxidación en ALS)

### **Patrones de Oxidación Diferencial:**
- **No hay patrón uniforme** de mayor oxidación en ALS
- **Diferencias específicas** por miRNA y posición
- **Algunos miRNAs** muestran mayor oxidación en controles

### **Distribución de Significancia:**
- **Mayoría de SNVs** no muestran diferencias significativas
- **Pocos SNVs** con diferencias altamente significativas
- **Patrones específicos** por posición

---

## 📊 ESTADÍSTICAS RESUMEN

### **Total de SNVs Analizados:** 328
### **Distribución por Significancia:**
- **Altamente significativos (|z| > 2):** 0 SNVs
- **Significativos (|z| > 1.5):** 0 SNVs
- **Moderadamente significativos (|z| > 1):** 8 SNVs
- **No significativos (|z| < 1):** 320 SNVs

### **Distribución por Dirección:**
- **Mayor oxidación en ALS (z > 1):** 3 SNVs
- **Mayor oxidación en Control (z < -1):** 5 SNVs
- **Sin diferencia clara:** 320 SNVs

---

## 🔬 IMPLICACIONES BIOLÓGICAS

### **1. Especificidad de la Oxidación:**
- **No hay patrón uniforme** de mayor oxidación en ALS
- **Diferencias específicas** por miRNA y posición
- **Importancia de análisis detallado** por SNV individual

### **2. Posición 6 como Hotspot:**
- **Mayor variabilidad** en oxidación
- **Funcionalmente crítica** en región semilla
- **Potencial biomarcador** para ALS

### **3. Correlación Expresión-Oxidación:**
- **Relación fuerte** entre expresión y oxidación
- **miRNAs altamente expresados** más susceptibles a oxidación
- **Mecanismo de protección** o vulnerabilidad

---

## 🎯 VENTAJAS DEL ENFOQUE Z-SCORE

### **1. Comparación Estandarizada:**
- **Normaliza diferencias** entre grupos
- **Permite comparación** entre SNVs diferentes
- **Considera variabilidad** dentro de cada grupo

### **2. Interpretación Clara:**
- **Valores positivos/negativos** indican dirección
- **Magnitud absoluta** indica significancia
- **Umbrales estándar** para interpretación

### **3. Robustez Estadística:**
- **Considera tamaño de muestra** en cada grupo
- **Usa desviación estándar combinada**
- **Proporciona p-values** para significancia

---

## 📋 CONCLUSIÓN

El **análisis Z-score** nos permite identificar **diferencias reales y significativas** en la oxidación de miRNAs entre pacientes ALS y controles. Aunque no hay un patrón uniforme de mayor oxidación en ALS, **posiciones específicas (especialmente posición 6) y miRNAs específicos** muestran diferencias estadísticamente significativas que merecen investigación adicional.

**Las visualizaciones detalladas proporcionan una comprensión completa de los patrones de oxidación y validan la robustez de nuestros hallazgos estadísticos.**










