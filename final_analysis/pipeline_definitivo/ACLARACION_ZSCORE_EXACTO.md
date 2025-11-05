# 🔬 ACLARACIÓN EXACTA: CÓMO SE CALCULA EL Z-SCORE

**Fecha:** 2025-10-24

---

## ⚠️ **CORRECCIÓN IMPORTANTE:**

**El Z-score NO es la diferencia entre ALS y Control**

Déjame mostrarte EXACTAMENTE qué hace:

---

## 📐 **CÁLCULO REAL DEL Z-SCORE (Paso a paso):**

### **PASO 1: Crear matriz RAW**

**Para ALS:**
```
        Posición:  1      2      3      4      5      6      7   ...  22
miR-107          0.000  0.000  0.000  0.000  0.0006 0.000  0.000... 0.001
miR-9            0.002  0.000  0.003  0.001  0.000  0.002  0.001... 0.000
miR-21           0.001  0.001  0.000  0.002  0.000  0.001  0.000... 0.000
...
```

**Para Control:**
```
        Posición:  1      2      3      4      5      6      7   ...  22
miR-107          0.000  0.000  0.000  0.000  0.0000 0.000  0.000... 0.000
miR-9            0.003  0.001  0.004  0.002  0.001  0.003  0.002... 0.001
...
```

**Cada valor en la matriz =** VAF promedio de ese miRNA en esa posición en ese grupo

---

### **PASO 2: COMBINAR (APILAR) las dos matrices**

```
        Posición:  1      2      3      4      5      6      7   ...  22
────────────────────────────────────────────────────────────────────────
Fila 1:  miR-107 ALS      0.000  0.000  0.000  0.000  0.0006 0.000  0.000... 0.001
Fila 2:  miR-9 ALS        0.002  0.000  0.003  0.001  0.000  0.002  0.001... 0.000
...
Fila 50: miR-X ALS        ...
────────────────────────────────────────────────────────────────────────
Fila 51: miR-107 Control  0.000  0.000  0.000  0.000  0.000  0.000  0.000... 0.000
Fila 52: miR-9 Control    0.003  0.001  0.004  0.002  0.001  0.003  0.002... 0.001
...
Fila 100: miR-X Control   ...
```

**Ahora tienes 100 filas × 22 columnas**

---

### **PASO 3: Calcular Z-score POR FILA (INDEPENDIENTEMENTE)**

**Para CADA FILA por separado:**

```r
zscore_matrix <- t(scale(t(combined_matrix)))
```

**Lo que hace `scale(t(combined_matrix))`:**
- Transpone (filas → columnas)
- scale() normaliza cada COLUMNA
- Transpone de vuelta
- **Resultado:** Normaliza cada FILA

---

### **EJEMPLO FILA 1 (miR-107 ALS):**

```
Valores originales (22 posiciones):
[0.000, 0.000, 0.000, 0.000, 0.000633, 0.000, 0.000, 0.000, 0.000, 0.000068, ...]

PASO A: Calcular estadísticas de SOLO ESTA FILA (no se toca Control)
   Media = mean([0.000, 0.000, ..., 0.000633, ...])
         = 0.000029
   
   SD = sd([0.000, 0.000, ..., 0.000633, ...])
      = 0.000135

PASO B: Para cada valor de esta fila, calcular Z:
   Pos 1: Z = (0.000 - 0.000029) / 0.000135 = -0.21
   Pos 2: Z = (0.000 - 0.000029) / 0.000135 = -0.21
   Pos 5: Z = (0.000633 - 0.000029) / 0.000135 = +4.47 ← Rojo intenso
   Pos 10: Z = (0.000068 - 0.000029) / 0.000135 = +0.29
   ...

Nueva fila 1 (Z-scores):
[-0.21, -0.21, -0.21, -0.21, +4.47, -0.21, -0.21, -0.21, -0.21, +0.29, ...]
```

---

### **EJEMPLO FILA 51 (miR-107 Control, EL MISMO miRNA):**

```
Valores originales:
[0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000005, ...]

PASO A: Calcular estadísticas de SOLO ESTA FILA (independiente de ALS)
   Media = 0.000001
   SD = 0.000003

PASO B: Calcular Z para cada valor:
   Pos 1: Z = (0.000 - 0.000001) / 0.000003 = -0.33
   Pos 5: Z = (0.000 - 0.000001) / 0.000003 = -0.33
   ...

Nueva fila 51 (Z-scores):
[-0.33, -0.33, -0.33, -0.33, -0.33, -0.33, ...]
```

---

## 🔥 **PUNTO CRÍTICO:**

**Fila 1 (miR-107 ALS) y Fila 51 (miR-107 Control) se normalizan INDEPENDIENTEMENTE**

```
Fila 1 (ALS):
   Pos 5 tiene VAF = 0.000633
   Z-score = +4.47 (rojo intenso)

Fila 51 (Control):
   Pos 5 tiene VAF = 0.000000 (cero)
   Z-score = -0.33 (azul claro)
```

**PERO:**
```
El Z-score NO te dice que ALS > Control

Solo te dice:
   - En ALS, pos 5 es outlier DENTRO de miR-107(ALS)
   - En Control, pos 5 es normal DENTRO de miR-107(Control)
```

---

## ❌ **LO QUE EL Z-SCORE NO ES:**

**NO es:**
```
Z-score ≠ (VAF_ALS - VAF_Control)  ❌
Z-score ≠ diferencia entre grupos  ❌
```

**ES:**
```
Z-score de ALS = (VAF_ALS - Media_ALS) / SD_ALS
Z-score de Control = (VAF_Control - Media_Control) / SD_Control

Cada uno se calcula SEPARADO
```

---

## 🎯 **ENTONCES, ¿PODEMOS USAR TODOS LOS miRNAs?**

### **SÍ, absolutamente!**

**Tu sugerencia es correcta:**

Usar TODOS los 301 miRNAs con G>T en seed (no solo top 50)

**Cambios necesarios:**
```r
# En vez de:
top50 <- head(seed_gt_summary, 50)

# Hacer:
all_mirnas <- seed_gt_summary$miRNA_name  # Todos los 301
```

**Resultado:**
- Heatmap: 602 filas × 22 columnas
  - Filas 1-301: ALS
  - Filas 302-602: Control
- Más grande pero manejable
- USA TODOS los datos

**Ventaja:**
- No arbitrario (no corta en 50)
- Información completa
- Sin nombres (demasiados de todos modos)

---

## 📊 **CÓMO HICIMOS LAS DEMÁS FIGURAS:**

### **Resumen de datasets usados:**

```
Fig 2.1: TODAS las muestras (415)
   → 313 ALS, 102 Control
   → TODOS los SNVs por muestra
   ✅ Usa TODO

Fig 2.2: TODAS las muestras (415)
   → Distribución completa
   ✅ Usa TODO

Fig 2.3: TODOS los miRNAs analizables
   → SEED: 293 miRNAs (8 excluidos por n<5)
   → ALL: 707 miRNAs
   ✅ Usa TODO (con filtro estadístico mínimo)

Fig 2.4A: TODOS los 301 miRNAs
   → Sin nombres, patrón completo
   ✅ Usa TODO

Fig 2.4B: TODOS los 301 miRNAs (agregado)
   → Promedio por posición
   ✅ Usa TODO
```

**Conclusión:**
- Todas las figuras anteriores usan TODOS los datos disponibles
- Solo Fig 2.5 usa "top 50" arbitrario

---

## 💡 **PROPUESTA FINAL:**

### **Generar Fig 2.5 con TODOS los 301 miRNAs:**

**Opciones:**

### **Opción A: Z-score con TODOS (actual lógica, todos los datos)**
```
602 filas (301 miRNAs × 2 grupos)
22 columnas (posiciones)
Z-score por fila (normalización independiente)
Sin nombres (demasiados)
```

**PROS:**
- ✅ Usa TODOS los datos
- ✅ No arbitrario
- ✅ Patrón completo

**CONTRAS:**
- ❌ No compara ALS vs Control directamente
- ❌ Duplicación (602 filas para 301 miRNAs)

---

### **Opción B: DIFERENCIA DIRECTA con TODOS** ⭐⭐⭐
```
301 filas (miRNAs, SIN duplicar)
22 columnas (posiciones)
Valor = VAF_ALS - VAF_Control (DIRECTAMENTE)
Sin nombres
```

**PROS:**
- ✅ Usa TODOS los datos (301 miRNAs)
- ✅ Compara directamente ALS vs Control
- ✅ Sin duplicación
- ✅ Interpretación clara

**CONTRAS:**
- Ninguno significativo

---

### **Opción C: ELIMINAR Fig 2.5**
```
Ya tenemos Fig 2.4B que usa TODOS los datos agregados
```

---

## 🎯 **MI RECOMENDACIÓN:**

**Generar Opción B: Diferencia Directa con TODOS los 301 miRNAs** ⭐

**Porque:**
1. Usa TODOS los datos (como pediste)
2. Compara directamente grupos
3. Sin duplicación
4. Más útil que Z-score por fila

**Título:**
"Differential G>T Burden: ALS vs Control (All 301 miRNAs)"

---

**¿Te quedó claro cómo se calcula el Z-score?**
- Por fila (independiente)
- NO es diferencia entre grupos
- Se normaliza separado para ALS y Control

**¿Quieres que genere la Opción B (Diferencia con TODOS)?** 🚀

