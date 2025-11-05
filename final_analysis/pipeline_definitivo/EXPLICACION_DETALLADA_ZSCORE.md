# 🔬 EXPLICACIÓN DETALLADA: Z-SCORE EN EL HEATMAP

**Fecha:** 2025-10-24  
**Tus preguntas:** ¿Qué representa cada celda? ¿Por qué solo top?

---

## 📐 **¿QUÉ REPRESENTA CADA CELDA?**

### **PASO A PASO CON EJEMPLO REAL:**

Voy a usar **hsa-miR-107** (primer miRNA del análisis) como ejemplo:

---

### **PASO 1: Valores RAW (antes de Z-score)**

**miR-107 en ALS, posiciones 1-22:**
```
Posición:  1      2      3      4      5         6      7      8      9         10     ...
VAF raw:   0.000  0.000  0.000  0.000  0.000633  0.000  0.000  0.000  0.000  0.000068  ...
```

**Estos son los VAF PROMEDIO** de ese miRNA en esa posición en todas las muestras ALS:
```
Posición 5 (VAF = 0.000633):
   = Promedio de VAF de miR-107 pos 5:GT en 313 muestras ALS
   = (VAF_ALS1 + VAF_ALS2 + ... + VAF_ALS313) / 313
```

---

### **PASO 2: Calcular estadísticas de ESA FILA**

**Para miR-107 en ALS (toda la fila de 22 posiciones):**
```
Valores: [0.000, 0.000, 0.000, 0.000, 0.000633, 0.000, ...]

Cálculos:
   Media de la fila = 0.000029  (promedio de las 22 posiciones)
   SD de la fila = 0.000135     (desviación estándar de las 22 posiciones)
```

**Esta media y SD se calculan SOLO para este miRNA en ALS**

---

### **PASO 3: Calcular Z-score para CADA CELDA**

**Fórmula:**
```
Z-score = (Valor - Media_fila) / SD_fila
```

**Para cada posición de miR-107 en ALS:**

```
Posición 1:
   Valor = 0.000
   Z = (0.000 - 0.000029) / 0.000135 = -0.21
   Interpretación: Ligeramente bajo (cerca del promedio)

Posición 5:
   Valor = 0.000633
   Z = (0.000633 - 0.000029) / 0.000135 = +4.47
   Interpretación: MUY ALTO (4.47 SD arriba del promedio)

Posición 10:
   Valor = 0.000068
   Z = (0.000068 - 0.000029) / 0.000135 = +0.29
   Interpretación: Ligeramente alto
```

---

### **PASO 4: Lo mismo para Control**

**miR-107 en Control:**
```
Posición:  1      2      3      4      5      6      7      8      9      10     ...
VAF raw:   0.000  0.000  0.000  0.000  0.000  0.000  0.000  0.000  0.000  0.000005 ...

Media de esta fila Control = 0.000001
SD de esta fila Control = 0.000003

Z-scores:
Pos 1: (0.000 - 0.000001) / 0.000003 = -0.33
Pos 5: (0.000 - 0.000001) / 0.000003 = -0.33  (también cerca de 0)
...
```

---

## 🎨 **INTERPRETACIÓN DE COLORES:**

### **Escala del Z-score:**

```
Z-score:    -3      -2      -1       0       +1      +2      +3
Color:    [Azul ················· Blanco ················· Rojo]
          oscuro                                            oscuro

Significado:
   Z = -3  → 3 SD POR DEBAJO del promedio de ese miRNA
   Z = -2  → 2 SD por debajo
   Z = -1  → 1 SD por debajo
   Z = 0   → Promedio de ese miRNA
   Z = +1  → 1 SD por arriba
   Z = +2  → 2 SD por arriba
   Z = +3  → 3 SD POR ARRIBA del promedio de ese miRNA
```

---

## 🔍 **EJEMPLO CONCRETO DE UNA CELDA:**

### **Celda: miR-107 (ALS), Posición 5**

**Valor en heatmap:** Rojo intenso (Z ≈ +4.5)

**¿Qué significa?**

```
1. VAF raw en esta celda: 0.000633

2. Promedio de miR-107(ALS) en TODAS sus 22 posiciones: 0.000029

3. Esta celda es: 0.000633 / 0.000029 = 21.8x MÁS que el promedio

4. En términos de desviaciones estándar:
   Z = +4.47 → 4.47 SD arriba del promedio
   
5. Color: Rojo muy intenso
```

**Interpretación:**
"En miR-107 (ALS), la posición 5 tiene un VAF MUCHO más alto que las otras posiciones de ese mismo miRNA"

---

## ❓ **¿POR QUÉ NO USAR TODOS LOS SNVs EN VEZ DE miRNAs?**

### **Tu pregunta:** "¿Por qué solo top miRNAs? ¿No se puede con todos los SNVs G>T del seed?"

**Diferencia clave:**

### **Lo que se está haciendo AHORA:**
```
Nivel: miRNA
Unidad: 1 fila = 1 miRNA (promediado en todas sus mutaciones)

Ejemplo:
   let-7a tiene 4 mutaciones G>T en seed:
      - 2:GT
      - 4:GT
      - 5:GT
      - 6:GT
   
   Para posición 2 en heatmap:
      Valor = VAF promedio de "let-7a 2:GT" en todas las muestras
```

---

### **Lo que PODRÍAS hacer (cada SNV):**
```
Nivel: SNV individual
Unidad: 1 fila = 1 SNV específico

Ejemplo:
   Fila 1: let-7a 2:GT
   Fila 2: let-7a 4:GT  
   Fila 3: let-7a 5:GT
   Fila 4: let-7a 6:GT
   Fila 5: miR-9 3:GT
   ...
```

---

## 🤔 **¿POR QUÉ NO SE USA TODOS LOS SNVs?**

### **Problema 1: DIMENSIONALIDAD**

**Con miRNAs (actual):**
```
50 miRNAs × 2 grupos = 100 filas
Heatmap: 100 × 22
```

**Con TODOS los SNVs:**
```
473 SNVs G>T en seed × 2 grupos = 946 filas
Heatmap: 946 × 22  ← ENORME!
```

**Resultado:**
- Heatmap gigantesco
- Ilegible
- Imposible de interpretar

---

### **Problema 2: INFORMACIÓN REDUNDANTE**

**Si usas todos los SNVs de un miRNA:**

```
let-7a tiene 4 SNVs en seed:
   let-7a 2:GT: VAF = 0.001
   let-7a 4:GT: VAF = 0.002
   let-7a 5:GT: VAF = 0.001
   let-7a 6:GT: VAF = 0.0015

Estos 4 SNVs están CORRELACIONADOS (mismo miRNA)
   → Información parcialmente redundante
```

**Si promedias por miRNA:**
```
let-7a (todas las posiciones seed): Patrón general
   → Resume la información de los 4 SNVs
   → Menos redundante
```

---

### **Problema 3: ¿QUÉ MOSTRARÍAS EN CADA COLUMNA?**

**Con miRNAs (actual):**
```
Heatmap tiene 22 columnas (posiciones 1-22)
Cada celda = VAF promedio en esa posición

Ejemplo, columna 6:
   Muestra VAF de TODOS los miRNAs que tienen mutación en posición 6
```

**Con SNVs individuales:**
```
Cada SNV es UNA mutación específica en UNA posición

Ejemplo: "let-7a 6:GT"
   → Solo tiene valor en columna 6
   → Columnas 1-5, 7-22 están VACÍAS (0)

Heatmap resultante:
   ┌──────────────┬────┬────┬────┬────┬────┬─────┐
   │ SNV          │ p1 │ p2 │ p3 │ p4 │ p5 │ p6  │
   ├──────────────┼────┼────┼────┼────┼────┼─────┤
   │ let-7a 2:GT  │ 0  │ VAF│ 0  │ 0  │ 0  │ 0   │
   │ let-7a 4:GT  │ 0  │ 0  │ 0  │ VAF│ 0  │ 0   │
   │ let-7a 5:GT  │ 0  │ 0  │ 0  │ 0  │ VAF│ 0   │
   │ let-7a 6:GT  │ 0  │ 0  │ 0  │ 0  │ 0  │ VAF │
   └──────────────┴────┴────┴────┴────┴────┴─────┘
                       ↑ Solo 1 celda llena por fila
```

**Resultado:**
- Heatmap MUY VACÍO (sparse)
- Solo 1 valor por fila
- Inutilizable

---

## 💡 **ALTERNATIVA: SÍ USAR TODOS LOS DATOS**

### **¿Cómo incluir TODOS los 473 SNVs sin hacer heatmap gigante?**

**Solución: AGREGAR por posición**

```
En vez de:
   1 fila por SNV (473 filas) ❌

Hacer:
   1 fila por POSICIÓN (22 filas) ✅
   
Para cada posición (ej: posición 6):
   Valor = Promedio de VAF de TODOS los SNVs en posición 6
```

**Ejemplo:**
```
Posición 6 en ALS:
   Todos los miRNAs que tienen 6:GT
      let-7a 6:GT: VAF = 0.001
      miR-9 6:GT: VAF = 0.002
      miR-21 6:GT: VAF = 0.0015
      ... (más miRNAs)
   
   Promedio = mean(0.001, 0.002, 0.0015, ...) = 0.0014

Z-score:
   Z = (0.0014 - media_de_todas_las_posiciones) / SD
```

**Resultado:**
- Heatmap pequeño (22 × 2)
- Usa TODOS los SNVs
- Compara directamente ALS vs Control

---

## 🎯 **RESUMEN DE OPCIONES:**

### **Opción actual (Fig 2.5):**
- 100 filas (50 miRNAs duplicados)
- Z-score por fila
- No compara grupos ❌
- Solo usa top 50 miRNAs

---

### **Opción A: DIFERENCIA DIRECTA por miRNA** ⭐
```
50 filas (miRNAs)
22 columnas (posiciones)
Valor = VAF_ALS - VAF_Control
Solo usa top 50
```

---

### **Opción B: AGREGAR POR POSICIÓN (TODOS los datos)** ⭐⭐⭐
```
22 filas (posiciones)
2 columnas (ALS y Control)
Valor = Promedio de TODOS los miRNAs en esa posición
USA TODOS los 473 SNVs (301 miRNAs)
```

---

**¿Quieres que genere estas alternativas para que compares?**

O primero dime:
- ¿Te quedó claro qué es cada celda en el actual?
- ¿Entiendes por qué solo top 50 (visualización)?
- ¿Prefieres ver alternativas que usen TODOS los datos?

🔬
