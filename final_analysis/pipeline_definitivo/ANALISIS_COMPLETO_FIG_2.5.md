# 🔍 ANÁLISIS COMPLETO: FIGURA 2.5 - LÓGICA Y ESTRUCTURA

**Fecha:** 2025-10-24

---

## 📋 **ESTRUCTURA ACTUAL:**

### **Datos:**
- 50 miRNAs (top por burden)
- 22 posiciones
- **100 filas** (50 miRNAs × 2 grupos)

### **Procesamiento:**
```r
1. Crear matriz ALS (50 × 22)
2. Crear matriz Control (50 × 22)
3. Combinar: rbind(ALS, Control) → 100 × 22
4. Calcular Z-score POR FILA
5. Graficar con clustering
```

---

## ⚠️ **PROBLEMAS LÓGICOS IDENTIFICADOS:**

### **Problema 1: Normalización independiente**

**Qué hace:**
```
Para cada fila (cada miRNA en cada grupo):
   Z-score = (VAF - media_de_esa_fila) / SD_de_esa_fila
```

**Consecuencia:**
```
let-7a(ALS): Media = 0.001, normalizado
let-7a(Control): Media = 0.010, normalizado

AMBOS tienen media Z-score = 0 después de normalizar
```

**Problema:**
- NO puedes comparar let-7a(ALS) vs let-7a(Control)
- La magnitud absoluta se pierde
- Rojo en ALS ≠ Rojo en Control

---

### **Problema 2: Duplicación confusa**

**Estructura:**
```
Fila 1: miR-107 (ALS)
Fila 2: miR-128 (ALS)
...
Fila 50: miR-X (ALS)
─────────────────────
Fila 51: miR-107 (Control)  ← MISMO miRNA, lejos
Fila 52: miR-128 (Control)
...
```

**Problema:**
- Cada miRNA aparece 2 veces
- El clustering puede separarlos
- Difícil seguir el mismo miRNA entre grupos

---

### **Problema 3: ¿Qué pregunta responde?**

**Pregunta confusa:**
```
"Para cada miRNA en cada grupo, ¿qué posiciones
se desvían de su propio promedio?"
```

**Problemas:**
- No compara ALS vs Control directamente
- No compara entre miRNAs
- Solo muestra desviaciones internas

---

## 📊 **HALLAZGO DEL ANÁLISIS:**

### **Hotspots detectados:**

**ALS (posiciones con más desviación):**
1. Posición 7: Mean |Z| = 1.19
2. Posición 6: Mean |Z| = 1.04
3. Posición 22: Mean |Z| = 0.91

**Control:**
1. Posición 7: Mean |Z| = 0.80
2. Posición 6: Mean |Z| = 0.78
3. Posición 8: Mean |Z| = 0.68

**Interpretación:**
- Posiciones 6-7 (seed) tienen más variabilidad
- Algunos miRNAs tienen hotspots ahí

---

## 💡 **ALTERNATIVAS MEJORES:**

### **Alternativa 1: DIFERENCIA DIRECTA (ALS - Control)** ⭐⭐⭐

**Lógica:**
```r
Para cada miRNA y posición:
   Diff = VAF_ALS - VAF_Control

Heatmap:
   50 filas (miRNAs)
   22 columnas (posiciones)
   Color: Azul (Control mayor), Blanco (igual), Rojo (ALS mayor)
```

**Ventajas:**
- ✅ Compara DIRECTAMENTE ALS vs Control
- ✅ Una fila por miRNA (no duplicación)
- ✅ Muestra diferencias absolutas
- ✅ Pregunta clara: "¿Dónde ALS > Control?"

---

### **Alternativa 2: FOLD CHANGE (log₂)** ⭐⭐

**Lógica:**
```r
Para cada miRNA y posición:
   FC = log₂(VAF_ALS / VAF_Control)

Heatmap:
   50 filas (miRNAs)
   22 columnas (posiciones)
   Color: Azul (Control mayor), Blanco (igual), Rojo (ALS mayor)
```

**Ventajas:**
- ✅ Normaliza por magnitud (fold change)
- ✅ Compara ALS vs Control
- ✅ Escala simétrica

---

### **Alternativa 3: Z-SCORE POR COLUMNA** ⭐

**Lógica:**
```r
Para cada POSICIÓN (no por miRNA):
   Z-score = (VAF - media_posición) / SD_posición

Compara entre miRNAs DENTRO de cada posición
```

**Ventajas:**
- ✅ Detecta qué miRNAs son outliers en cada posición
- ✅ Mantiene separación ALS vs Control

---

### **Alternativa 4: ELIMINAR**

**Si:**
- No aporta información nueva
- Fig 2.4 ya muestra los patrones
- Complica en vez de clarificar

---

## 🎯 **MI RECOMENDACIÓN:**

### **Opción RECOMENDADA: Alternat 1 (DIFERENCIA DIRECTA)** ⭐

**Nueva Figura 2.5:**
```
Título: "Differential G>T: ALS vs Control by Position"

Heatmap:
   - 50 filas (miRNAs, sin duplicación)
   - 22 columnas (posiciones)
   - Valores: VAF_ALS - VAF_Control
   - Color: 
      Azul oscuro: Control mucho mayor
      Blanco: Sin diferencia
      Rojo oscuro: ALS mucho mayor
   - Seed region marcada
```

**Pregunta que responde:**
"¿Qué miRNAs y posiciones muestran diferencias ALS vs Control?"

**Ventajas:**
- Comparación DIRECTA entre grupos
- Sin duplicación (50 filas, no 100)
- Interpretación clara
- Complementa Fig 2.4 (que muestra valores absolutos)

---

## ❓ **TU DECISIÓN:**

**¿Qué prefieres?**

**[A]** ELIMINAR Fig 2.5 (redundante, confusa)

**[B]** MANTENER actual (normalización por fila)

**[C]** CAMBIAR a Diferencia Directa (ALS - Control) ⭐⭐⭐

**[D]** CAMBIAR a Fold Change (log₂ ratio)

**[E]** CAMBIAR a Z-score por columna (otra normalización)

---

**Mi recomendación fuerte: Opción C (Diferencia Directa)**

**Porque:**
- ✅ Clara y directa
- ✅ Compara grupos
- ✅ Sin duplicación
- ✅ Complementa Fig 2.4

**¿Qué decides?** 🔬

