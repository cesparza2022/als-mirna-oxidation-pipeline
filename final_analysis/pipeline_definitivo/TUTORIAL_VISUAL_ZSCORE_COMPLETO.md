# 📚 TUTORIAL VISUAL COMPLETO: Z-SCORE EN HEATMAP

**Fecha:** 2025-10-24

---

## 🎯 **TUS PREGUNTAS:**

1. **¿Qué representa cada celda del heatmap?**
2. **¿Qué representa la escala del Z-score?**
3. **¿Por qué solo con top miRNAs y no con TODOS los SNVs G>T del seed?**

---

## 📐 **RESPUESTA 1: ¿QUÉ REPRESENTA CADA CELDA?**

### **EJEMPLO CON DATOS REALES:**

Voy a seguir **1 celda específica** desde el inicio:

**Celda elegida:** miR-107 (ALS), Posición 5

---

### **ORIGEN DEL VALOR:**

#### **A. Datos originales (final_processed_data_CLEAN.csv):**

```
Fila del CSV:
┌────────────┬─────────┬──────────┬──────────┬──────────┬─────┐
│ miRNA_name │ pos.mut │ ALS1     │ ALS2     │ ALS3     │ ... │
├────────────┼─────────┼──────────┼──────────┼──────────┼─────┤
│ miR-107    │ 5:GT    │ 0.000100 │ 0.000000 │ 0.000200 │ ... │
└────────────┴─────────┴──────────┴──────────┴──────────┴─────┘
                           ↑         ↑         ↑
                     Muestra 1  Muestra 2  Muestra 3
```

**Esta fila contiene:**
- VAF de miR-107 posición 5:GT
- En las 313 muestras ALS (313 columnas)

---

#### **B. Calcular promedio (para el heatmap):**

```
VAF_promedio_ALS = mean(0.000100, 0.000000, 0.000200, ..., [313 valores])
                 = 0.000633

Este es el VALOR RAW que va en el heatmap pre-zscore
```

**Mismo proceso para Control:**
```
VAF_promedio_Control = mean([102 valores de muestras Control])
                     = 0.000000 (en este ejemplo)
```

---

#### **C. Crear matriz para heatmap:**

**Matriz RAW (antes de Z-score):**
```
┌──────────────┬────────┬────────┬────────┬────────┬──────────┬────────┬─────┐
│ miRNA        │ p1     │ p2     │ p3     │ p4     │ p5       │ p6     │ ... │
├──────────────┼────────┼────────┼────────┼────────┼──────────┼────────┼─────┤
│ miR-107 ALS  │ 0.000  │ 0.000  │ 0.000  │ 0.000  │ 0.000633 │ 0.000  │ ... │
│ miR-9 ALS    │ 0.002  │ 0.000  │ 0.003  │ 0.001  │ 0.000    │ 0.002  │ ... │
│ ...          │ ...    │ ...    │ ...    │ ...    │ ...      │ ...    │ ... │
│ miR-107 Ctrl │ 0.000  │ 0.000  │ 0.000  │ 0.000  │ 0.000    │ 0.000  │ ... │
│ miR-9 Ctrl   │ 0.003  │ 0.001  │ 0.004  │ 0.002  │ 0.001    │ 0.003  │ ... │
└──────────────┴────────┴────────┴────────┴────────┴──────────┴────────┴─────┘
                                                        ↑
                                           Esta es nuestra celda objetivo
```

**Valor en celda (miR-107 ALS, pos 5):** 0.000633

---

#### **D. Calcular Z-score POR FILA:**

**Para la fila de miR-107 (ALS):**

```
Valores de todas las 22 posiciones:
[0.000, 0.000, 0.000, 0.000, 0.000633, 0.000, 0.000, 0.000, 0.000, 0.000068, ...]

Estadísticas de ESTA FILA:
   Media_fila = mean([0.000, 0.000, ..., 0.000633, ...])
              = 0.000029
   
   SD_fila = sd([0.000, 0.000, ..., 0.000633, ...])
           = 0.000135
```

**Calcular Z-score de la celda (pos 5):**
```
Z-score = (Valor - Media_fila) / SD_fila

Z = (0.000633 - 0.000029) / 0.000135
Z = 0.000604 / 0.000135
Z = +4.47
```

**Este Z-score (+4.47) es lo que se GRAFICA en el heatmap**

---

## 🎨 **RESPUESTA 2: ¿QUÉ REPRESENTA LA ESCALA?**

### **Escala visual:**

```
     Color:        Azul      →    Blanco    →      Rojo
     Z-score:      -3        -2    -1    0    +1    +2        +3
     Significado:  Muy bajo  ←  Promedio  →          Muy alto
```

---

### **Interpretación numérica:**

```
Z-score = -3  → Este valor es 3 SD MÁS BAJO que el promedio de esa fila
              → Solo ~0.1% de valores normales son tan bajos
              → OUTLIER bajo

Z-score = -1  → 1 SD más bajo
              → ~16% de valores son así de bajos
              → Moderadamente bajo

Z-score = 0   → PROMEDIO de esa fila
              → 50% de valores arriba, 50% abajo

Z-score = +1  → 1 SD más alto
              → ~16% de valores son así de altos
              → Moderadamente alto

Z-score = +3  → 3 SD MÁS ALTO que el promedio
              → Solo ~0.1% de valores normales son tan altos
              → OUTLIER alto
```

---

### **Para nuestra celda (Z = +4.47):**

```
Z = +4.47  → ¡4.47 SD arriba del promedio!
           → Extremadamente alto (outlier)
           → Solo ~0.0001% esperado por azar
           → Rojo MUY intenso en el heatmap
```

**Interpretación biológica:**
"En miR-107 (ALS), la posición 5 tiene un VAF EXCEPCIONALMENTE alto comparado con las otras posiciones de ese mismo miRNA"

---

## ❓ **RESPUESTA 3: ¿POR QUÉ NO TODOS LOS SNVs?**

### **Razón 1: VISUALIZACIÓN IMPOSIBLE**

**Si usamos TODOS los 473 SNVs × 2 grupos:**

```
Heatmap: 946 filas × 22 columnas

Tamaño necesario:
   Para ver nombres: ~47 pulgadas de alto
   Para PDF normal: Letra de 0.05 pulgadas (ilegible)
```

**Resultado:** Imposible de visualizar útilmente

---

### **Razón 2: MATRIZ MUY VACÍA (SPARSE)**

**Cada SNV solo tiene valor en 1 posición:**

```
SNV "let-7a 6:GT":
   Posiciones 1-5: 0 (vacío)
   Posición 6: VAF (único valor)
   Posiciones 7-22: 0 (vacío)

21 de 22 celdas = VACÍAS
```

**Heatmap resultante:**
```
946 filas × 22 columnas = 20,812 celdas
Solo ~946 celdas con valores (4.5%)
95.5% del heatmap = VACÍO (blanco/cero)
```

**Resultado:** Información muy dispersa, difícil de interpretar

---

### **Razón 3: REDUNDANCIA ENTRE SNVs DEL MISMO miRNA**

**miRNAs con múltiples SNVs en seed:**

```
let-7a tiene 4 SNVs seed:
   2:GT → Fila 1
   4:GT → Fila 2
   5:GT → Fila 3
   6:GT → Fila 4

Estos 4 SNVs están en el MISMO miRNA
   → Correlacionados biológicamente
   → Información parcialmente redundante
```

**Mejor:**
```
Resumir let-7a en 1 fila:
   Valor pos 2 = VAF de let-7a 2:GT
   Valor pos 4 = VAF de let-7a 4:GT
   Valor pos 5 = VAF de let-7a 5:GT
   Valor pos 6 = VAF de let-7a 6:GT
   Resto = 0

Ahora 1 fila resume los 4 SNVs ✅
```

---

## 💡 **PERO SÍ PODEMOS USAR TODOS LOS DATOS**

### **Propuesta: Heatmap agregado por posición**

**Incluir TODOS los 473 SNVs sin mostrarlos individualmente:**

```
Para cada posición:
   Valor_ALS = Promedio de VAF de TODOS los miRNAs en esa posición
   Valor_Control = Promedio de VAF de TODOS los miRNAs en esa posición

Heatmap resultante:
┌──────────┬──────┬──────┬──────┬──────┬─────┐
│ Group    │ p1   │ p2   │ p3   │ p4   │ ... │
├──────────┼──────┼──────┼──────┼──────┼─────┤
│ ALS      │ 0.01 │ 0.02 │ 0.01 │ 0.03 │ ... │
│ Control  │ 0.02 │ 0.03 │ 0.02 │ 0.04 │ ... │
└──────────┴──────┴──────┴──────┴──────┴─────┘

Dimensiones: 2 × 22 (pequeño y claro)
Datos usados: TODOS los 473 SNVs
```

**Esto es exactamente la Fig 2.4B que YA aprobaste!** ✅

---

## 🔍 **ENTONCES, ¿QUÉ HACE REALMENTE EL Z-SCORE?**

### **Visualización del proceso:**

**MATRIZ RAW (ejemplo simplificado con 3 miRNAs, 5 posiciones):**

```
           p1     p2     p3     p4     p5     │ Media │  SD
miR-A ALS  0.001  0.002  0.001  0.001  0.050  │ 0.011 │0.022
miR-B ALS  0.010  0.020  0.010  0.010  0.010  │ 0.012 │0.004
miR-C ALS  0.000  0.000  0.001  0.000  0.002  │ 0.001 │0.001
```

**MATRIZ Z-SCORE (normalizando POR FILA):**

```
Para miR-A:
   p1: (0.001 - 0.011) / 0.022 = -0.45  (azul claro)
   p2: (0.002 - 0.011) / 0.022 = -0.41  (azul claro)
   p5: (0.050 - 0.011) / 0.022 = +1.77  (rojo) ← Hotspot!

Para miR-B:
   p1: (0.010 - 0.012) / 0.004 = -0.50  (azul claro)
   p2: (0.020 - 0.012) / 0.004 = +2.00  (rojo) ← Hotspot!
   p5: (0.010 - 0.012) / 0.004 = -0.50  (azul claro)

Para miR-C:
   p5: (0.002 - 0.001) / 0.001 = +1.00  (rojo claro)
```

**Resultado visual:**
```
         p1    p2    p3    p4    p5
miR-A   [azul][azul][azul][azul][ROJO]  ← p5 es hotspot
miR-B   [azul][ROJO][azul][azul][azul]  ← p2 es hotspot
miR-C   [gris][gris][blan][gris][rojo]  ← p5 ligeramente alto
```

**Lo que MUESTRA:**
- miR-A tiene hotspot en p5 (0.050 muy alto para ese miRNA)
- miR-B tiene hotspot en p2 (0.020 muy alto para ese miRNA)

**Lo que OCULTA:**
- miR-A p5 (0.050) es MÁS alto que miR-B p2 (0.020) en valor absoluto
- Pero AMBOS se ven "rojos" (normalizados)
- Se pierde la comparación de magnitud entre miRNAs

---

## 🔢 **RESPUESTA 2: ESCALA DEL Z-SCORE**

### **¿Qué es Z-score?**

**Definición matemática:**
```
Z = (X - μ) / σ

Donde:
   X = valor de la celda
   μ = promedio de la fila
   σ = desviación estándar de la fila
```

**Unidad:**
```
Z-score está en unidades de "desviaciones estándar"

No es VAF (0-1)
No es porcentaje (0-100%)
Es "cuántas SDs alejado del promedio"
```

---

### **Distribución normal de referencia:**

```
                    Distribución Normal
                    
    Frecuencia
        ↑
        │         ╱‾‾‾╲
        │        ╱     ╲
        │       ╱       ╲
        │      ╱         ╲
        │     ╱           ╲___
        │____╱                 ╲____
        └─────────────────────────────→ Z-score
           -3  -2  -1   0  +1  +2  +3

Porcentajes:
   68% de datos entre -1 y +1
   95% de datos entre -2 y +2
   99.7% de datos entre -3 y +3
```

---

### **Interpretación de valores:**

```
Z = 0      → Valor típico (promedio)
           → 50% de valores son mayores, 50% menores

Z = +1     → Moderadamente alto
           → Solo 16% de valores son más altos
           → Color: Rojo claro

Z = +2     → Alto
           → Solo 2.5% de valores son más altos
           → Color: Rojo medio

Z = +3     → Muy alto (outlier)
           → Solo 0.1% de valores son más altos
           → Color: Rojo oscuro

Z = +4.47  → EXTREMADAMENTE alto ← Nuestra celda
           → Solo 0.0004% esperado por azar
           → Color: Rojo muy intenso
           → OUTLIER claro
```

---

## 📊 **RESPUESTA 3: ¿POR QUÉ NO TODOS LOS SNVs?**

### **Diferencia conceptual:**

#### **NIVEL miRNA (lo que hace ahora):**

**1 fila = 1 miRNA**

```
miR-107 tiene varios SNVs:
   - 5:GT (VAF = 0.000633)
   - Otros en otras posiciones

Heatmap muestra:
   Fila "miR-107 (ALS)":
      p1  p2  p3  p4    p5       p6  ...
      0   0   0   0   0.000633   0   ...
                        ↑
            Valor de miR-107 5:GT promedio en ALS
```

**Ventajas:**
- 1 fila por miRNA (condensado)
- Muestra patrón del miRNA completo
- Varias posiciones pueden tener valores

---

#### **NIVEL SNV (lo que propones):**

**1 fila = 1 SNV específico**

```
SNV "miR-107 5:GT":
   Fila en heatmap:
      p1  p2  p3  p4    p5       p6  p7  ...  p22
      0   0   0   0   0.000633   0   0   ...  0
                        ↑
            Solo esta celda tiene valor
```

**Problema:**
- Cada fila solo tiene 1 valor (en su posición específica)
- 21 de 22 celdas = VACÍAS (0)
- Heatmap 95% vacío

---

### **COMPARACIÓN VISUAL:**

**NIVEL miRNA (50 top):**
```
Heatmap: 100 filas × 22 columnas = 2,200 celdas
Celdas con valores: ~500-800 (23-36%)
Visualizable: ✅ Sí (con top 50)
```

**NIVEL SNV (TODOS los 473):**
```
Heatmap: 946 filas × 22 columnas = 20,812 celdas
Celdas con valores: ~946 (4.5%)
Celdas vacías: ~19,866 (95.5%)
Visualizable: ❌ Sparse y enorme
```

---

### **PERO SÍ USAMOS TODOS LOS DATOS:**

**Ya lo hicimos en Fig 2.4B (Summary)!**

```
Fig 2.4B:
   - Promedia TODOS los 301 miRNAs (473 SNVs)
   - 2 filas (ALS y Control)
   - 22 columnas (posiciones)
   - USA TODA la información
   - Visualización clara
```

**Esa figura SÍ usa TODOS los SNVs G>T del seed** ✅

---

## 🎯 **RESUMEN DE TUS PREGUNTAS:**

### **1. ¿Qué representa cada celda?**

**Respuesta:**
```
Celda = Z-score normalizado POR FILA

Proceso:
   Valor raw (VAF promedio) 
      → Normalizar por media y SD de esa fila
      → Z-score

Interpretación:
   Cuántas SD esa posición se desvía del promedio del miRNA
```

---

### **2. ¿Qué representa la escala?**

**Respuesta:**
```
Escala: -3 a +3 (desviaciones estándar)

-3 (azul): 3 SD bajo (outlier bajo)
0 (blanco): Promedio
+3 (rojo): 3 SD alto (outlier alto)

Unidad: "Número de desviaciones estándar"
```

---

### **3. ¿Por qué solo top y no TODOS?**

**Respuesta:**
```
A. Nivel miRNA (actual):
   - Top 50 por visualización (100 filas manejables)
   - Cada miRNA puede tener valores en múltiples posiciones
   
B. Nivel SNV (propuesto):
   - 473 SNVs = 946 filas (demasiado)
   - Cada SNV solo 1 posición (heatmap 95% vacío)
   - Visualización impráctica

C. Agregado (Fig 2.4B):
   - USA TODOS los 473 SNVs
   - Agregado por posición
   - Visualización clara (2 × 22)
   ✅ Ya lo tienes aprobado!
```

---

## ✅ **CONCLUSIÓN:**

**Fig 2.4B ya usa TODOS los datos agregados** ✅

**Fig 2.5 actual:**
- Usa solo top 50 miRNAs
- Normalización por fila (confusa)
- No compara grupos directamente

**Recomendación:**
- **ELIMINAR Fig 2.5** (redundante y confusa)
- **O CAMBIAR** a Diferencia Directa (ALS - Control)

---

**¿Te quedó claro?**
- Cada celda = Z-score por fila
- Escala = Desviaciones estándar
- TODOS los datos ya están en Fig 2.4B (agregado)

**¿Eliminamos Fig 2.5 o la modificamos?** 🤔

