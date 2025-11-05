# 🔥 ANÁLISIS DE CONSISTENCIA: Fig 2.1-2.2 vs Fig 2.3

**Fecha:** 2025-10-24  
**Hallazgo crítico detectado**

---

## 📊 **RESULTADOS ENCONTRADOS:**

### **Figuras 2.1-2.2 (Burden Global):**
- **Control > ALS** en G>T VAF
- Control: 3.69 (mean)
- ALS: 2.58 (mean)
- **p = 2.5e-13** (altamente significativo)

### **Figura 2.3 (Volcano - miRNAs individuales):**
- **NO hay miRNAs significativos** (0 ALS, 0 Control)
- **Pero:** 67.9% de miRNAs tienen dirección ALS > Control
- Media log₂FC = 0.073 (leve tendencia hacia ALS)
- Mediana log₂FC = 0.012 (casi neutral)

---

## ❓ **¿POR QUÉ LA APARENTE INCONSISTENCIA?**

### **Hallazgo global vs hallazgo miRNA-específico:**

```
Fig 2.1-2.2: SUMA total de VAF
   Control: 3.69 (total)
   ALS: 2.58 (total)
   → Control > ALS ✅

Fig 2.3: PROMEDIO por miRNA
   67.9% de miRNAs: ALS > Control
   32.1% de miRNAs: Control > ALS
   → Tendencia ALS ⚠️
```

**¿Cómo pueden ser diferentes?**

---

## 💡 **EXPLICACIÓN (Reconciliación):**

### **Escenario más probable:**

**Control tiene POCOS miRNAs con VAF MUY ALTO:**

Ejemplo hipotético:

**Control:**
- miR-1: VAF = 2.0 (MUY alto)
- miR-2: VAF = 1.5 (alto)
- miR-3: VAF = 0.19 (bajo)
- **Total:** 2.0 + 1.5 + 0.19 = **3.69** ✅

**ALS:**
- miR-1: VAF = 0.8 (moderado)
- miR-2: VAF = 0.9 (moderado)
- miR-3: VAF = 0.88 (moderado)
- **Total:** 0.8 + 0.9 + 0.88 = **2.58** ✅

**Volcano (Fold Changes por miRNA):**
- miR-1: log₂(0.8/2.0) = -1.32 → **Control > ALS**
- miR-2: log₂(0.9/1.5) = -0.74 → **Control > ALS**
- miR-3: log₂(0.88/0.19) = +2.21 → **ALS > Control**

**Resultado:**
- **Global:** Control (3.69) > ALS (2.58) → Fig 2.1-2.2 ✅
- **Individual:** 2 de 3 miRNAs Control > ALS, pero 1 miRNA ALS >> Control
- **Volcano:** Muestra la heterogeneidad miRNA-específica

---

## 🎯 **LO QUE ESTO SIGNIFICA:**

### **Hallazgo 1: El burden global de Control NO está uniformemente distribuido**
- Algunos miRNAs dominan el burden en Control
- ALS tiene burden más distribuido entre miRNAs

### **Hallazgo 2: NO hay miRNAs significativos individuales**
- **0 miRNAs ALS-específicos**
- **0 miRNAs Control-específicos**
- Umbrales: FDR < 0.05 Y |log₂FC| > 0.58

**¿Por qué NO hay significativos?**

Posibles razones:
1. **Alta variabilidad intra-grupo** → p-values altos
2. **Fold changes pequeños** → No alcanzan umbral de 1.5x
3. **Corrección FDR muy estricta** → 293 tests simultáneos
4. **Poder estadístico bajo** → Pocas muestras por miRNA

---

## 🔍 **INVESTIGACIÓN NECESARIA:**

### **Para entender la inconsistencia:**

1. **¿Cuántos miRNAs únicos hay en cada muestra?**
   - Si Control tiene más miRNAs expresados → Mayor burden total

2. **¿Qué miRNAs dominan el burden?**
   - Top 10 miRNAs por contribución al burden total
   - ¿Son los mismos en ALS vs Control?

3. **¿Hay outliers dominantes?**
   - ¿Algunos miRNAs tienen VAF extremadamente alto?
   - ¿Solo en Control?

4. **Expresión basal:**
   - ¿Control expresan más miRNAs en general?
   - Mayor expresión → más oportunidad de mutaciones

---

## ⚠️ **PROBLEMA CRÍTICO DETECTADO:**

**NO HAY miRNAs SIGNIFICATIVOS en el volcano!**

**Esto es preocupante porque:**
- Fig 2.1-2.2 muestran diferencias **ALTAMENTE significativas** globales (p < 1e-12)
- Pero a nivel de miRNAs individuales: **ninguno pasa FDR < 0.05**

**Posibles soluciones:**

### **Opción 1: Relajar umbrales**
```r
# Actual: FDR < 0.05 Y |log2FC| > 0.58
# Probar: FDR < 0.1 Y |log2FC| > 0.3
# O usar p-value sin ajuste (solo para exploración)
```

### **Opción 2: Usar métrica diferente**
```r
# En vez de VAF promedio por miRNA
# Usar: Frecuencia de muestras con ese miRNA mutado
# (presencia/ausencia en vez de magnitud)
```

### **Opción 3: Agregar más contexto**
```r
# Colorear puntos por:
# - Expresión basal del miRNA
# - Posición específica en seed
# - Familia de miRNA
```

### **Opción 4: Eliminar esta figura**
```r
# Si no hay significativos, tal vez no es informativa
# Mejor pasar a análisis de posición o familia
```

---

## 🤔 **PREGUNTAS PARA TI:**

1. **¿Por qué crees que NO hay miRNAs individuales significativos?**
   - Alta variabilidad
   - Poder estadístico bajo
   - Efecto distribuido entre muchos miRNAs

2. **¿Quieres investigar qué miRNAs dominan el burden global?**
   - Para entender por qué Control > ALS globalmente
   - Pero no a nivel individual

3. **¿Relajar umbrales o eliminar esta figura?**
   - Si no hay nada significativo, ¿vale la pena mostrarla?
   - O cambiar a otra visualización

4. **¿Agregar análisis de expresión basal?**
   - Para ver si Control simplemente expresan más miRNAs

---

## ✅ **RESUMEN:**

**HALLAZGO CLAVE:**
- **Global:** Control > ALS (Fig 2.1-2.2) ✅
- **Individual:** Mayoría de miRNAs ALS > Control (67.9%) ⚠️
- **Significancia:** NO hay miRNAs individuales significativos 🚨

**INTERPRETACIÓN:**
- El burden global de Control está dominado por **POCOS miRNAs con VAF alto**
- ALS tiene burden distribuido entre **MUCHOS miRNAs con VAF moderado**
- Necesitamos investigar **¿cuáles miRNAs dominan?**

---

**He abierto FIG_2.3_VOLCANO_CORRECTED.png (Control en gris oscuro)**

**¿Qué decides?**
1. ¿Investigar qué miRNAs dominan el burden?
2. ¿Relajar umbrales para ver significativos?
3. ¿Eliminar/reemplazar esta figura?
4. ¿Continuar con siguiente figura?

🤔

