# 📊 COMPARACIÓN: ¿CÓMO USAMOS LOS DATOS EN CADA FIGURA DEL PASO 2?

**Fecha:** 2025-10-24  
**Objetivo:** Ver cómo cada figura usa los datos

---

## 🗂️ **DATOS DISPONIBLES:**

```
Total SNVs G>T en seed (pos 2-8): 473
Total miRNAs con G>T en seed: 301
Total muestras: 415 (313 ALS + 102 Control)
```

---

## 📋 **COMPARACIÓN FIGURA POR FIGURA:**

### **FIGURA 2.1: VAF Comparisons**

**Nivel de análisis:** MUESTRA (por individuo)

**Datos usados:**
```
Para cada muestra:
   Total_VAF = SUMA de todos los VAF de esa muestra
   GT_VAF = SUMA de VAF de G>T de esa muestra

Ejemplo ALS-1:
   Total_VAF = 0.02 + 0.01 + 0.03 + ... (todos los SNVs)
             = 3.5
   
   GT_VAF = 0.02 + 0.01 + ... (solo G>T)
          = 2.5
```

**Gráfico:**
- Boxplot
- X: Grupo (ALS vs Control)
- Y: Total VAF o GT VAF
- **Puntos:** 415 muestras

**¿Cuántos datos?** TODOS (415 muestras, todos sus SNVs)

---

### **FIGURA 2.2: Distributions**

**Nivel de análisis:** MUESTRA (distribución)

**Datos usados:**
```
MISMOS que Fig 2.1:
   415 valores de GT_VAF (uno por muestra)
```

**Gráfico:**
- Density plot
- X: GT VAF
- Y: Densidad
- Curvas: ALS vs Control

**¿Cuántos datos?** TODOS (415 muestras)

---

### **FIGURA 2.3: Volcano Plot**

**Nivel de análisis:** miRNA (comparación entre grupos)

**Datos usados:**
```
Para cada miRNA:
   Todos los VAF de ese miRNA en todas las muestras ALS
   Todos los VAF de ese miRNA en todas las muestras Control
   
   Ejemplo let-7a (tiene 4 SNVs en seed):
      ALS: 4 SNVs × 313 muestras = 1,252 valores
      Control: 4 SNVs × 102 muestras = 408 valores
   
   Calcular:
      Mean_ALS = mean(1,252 valores)
      Mean_Control = mean(408 valores)
      log2FC = log2(Mean_ALS / Mean_Control)
      Test: wilcox.test(1,252 valores vs 408 valores)
```

**Gráfico:**
- Scatter plot
- X: log2FC
- Y: -log10(p-value)
- **Puntos:** 293 miRNAs (TODOS los que tienen n>5)

**¿Cuántos datos?** TODOS los miRNAs analizables (293 de 301)

---

### **FIGURA 2.4A: Heatmap ALL miRNAs**

**Nivel de análisis:** miRNA × Posición (patrón posicional)

**Datos usados:**
```
Para cada combinación (miRNA, posición, grupo):
   Mean_VAF = promedio de VAF en esas condiciones

Ejemplo let-7a, pos 6, ALS:
   VAF de let-7a 6:GT en muestra ALS-1: 0.02
   VAF de let-7a 6:GT en muestra ALS-2: 0.01
   ...
   VAF de let-7a 6:GT en muestra ALS-313: 0.015
   
   Mean_VAF_ALS_let7a_p6 = mean(0.02, 0.01, ..., 0.015)
                         = 0.018
```

**Gráfico:**
- Heatmap
- Filas: 301 miRNAs (TODOS)
- Columnas: 22 posiciones
- 2 paneles: ALS | Control
- Valores: Mean VAF

**¿Cuántos datos?** TODOS los 301 miRNAs

---

### **FIGURA 2.4B: Summary Heatmap**

**Nivel de análisis:** Posición (agregado global)

**Datos usados:**
```
Para cada posición y grupo:
   Mean_VAF = promedio de TODOS los miRNAs en esa posición

Ejemplo posición 6, ALS:
   TODOS los miRNAs que tienen mutación en pos 6
      let-7a 6:GT: VAF_promedio_ALS = 0.018
      miR-9 6:GT: VAF_promedio_ALS = 0.020
      miR-21 6:GT: VAF_promedio_ALS = 0.015
      ... (más miRNAs)
   
   Mean_VAF_pos6_ALS = mean(0.018, 0.020, 0.015, ...)
                     = 0.0176
```

**Gráfico:**
- Heatmap
- Filas: 2 (ALS y Control)
- Columnas: 22 posiciones
- Valores: Mean VAF agregado

**¿Cuántos datos?** TODOS los 301 miRNAs agregados

---

### **FIGURA 2.5: Z-score Heatmap (ACTUAL)**

**Nivel de análisis:** miRNA × Posición (normalizado por miRNA)

**Datos usados:**
```
MISMO proceso que Fig 2.4A hasta crear matriz
Luego: Normalizar POR FILA

Para cada fila (miRNA en grupo):
   Valores de 22 posiciones
   Calcular media y SD de SOLO esa fila
   Transformar cada valor a Z-score
```

**Gráfico:**
- Heatmap
- Filas: 100 (50 miRNAs × 2 grupos) ← Solo top 50
- Columnas: 22 posiciones
- Valores: Z-score (normalizado por fila)

**¿Cuántos datos?** Solo top 50 miRNAs (arbitrario)

---

## 🔍 **COMPARACIÓN DIRECTA:**

```
┌─────────┬──────────────┬───────────┬───────────────┬─────────────┐
│ Figura  │ Nivel        │ Datos     │ ¿Compara      │ ¿Todos los  │
│         │              │ agregados │ ALS vs Ctrl?  │ datos?      │
├─────────┼──────────────┼───────────┼───────────────┼─────────────┤
│ 2.1     │ Muestra      │ Por       │ ✅ Sí         │ ✅ Sí (415) │
│         │              │ muestra   │ (boxplot)     │             │
├─────────┼──────────────┼───────────┼───────────────┼─────────────┤
│ 2.2     │ Muestra      │ Por       │ ✅ Sí         │ ✅ Sí (415) │
│         │              │ muestra   │ (density)     │             │
├─────────┼──────────────┼───────────┼───────────────┼─────────────┤
│ 2.3     │ miRNA        │ Por       │ ✅ Sí         │ ✅ Sí (293) │
│         │              │ miRNA     │ (volcano)     │             │
├─────────┼──────────────┼───────────┼───────────────┼─────────────┤
│ 2.4A    │ miRNA×Pos    │ Por       │ ⚠️  Visual    │ ✅ Sí (301) │
│         │              │ grupo     │ (2 paneles)   │             │
├─────────┼──────────────┼───────────┼───────────────┼─────────────┤
│ 2.4B    │ Posición     │ Global    │ ✅ Sí         │ ✅ Sí (301) │
│         │              │ agregado  │ (directo)     │             │
├─────────┼──────────────┼───────────┼───────────────┼─────────────┤
│ 2.5     │ miRNA×Pos    │ Por       │ ❌ NO         │ ❌ Solo 50  │
│ actual  │              │ fila      │ (normaliz     │             │
│         │              │ (Z-score) │ independ.)    │             │
└─────────┴──────────────┴───────────┴───────────────┴─────────────┘
```

---

## 🔥 **PROBLEMA IDENTIFICADO:**

**Fig 2.5 es la ÚNICA que:**
1. No usa todos los datos (solo top 50)
2. No compara directamente grupos
3. Tiene lógica diferente (normalización independiente)

**INCONSISTENTE con las demás figuras**

---

## 💡 **SOLUCIÓN PROPUESTA:**

### **Nueva Fig 2.5: Diferencia Directa (TODOS los 301 miRNAs)**

**Lógica:**
```
Para cada miRNA y posición:
   Diff = VAF_ALS - VAF_Control

Heatmap:
   301 filas (TODOS los miRNAs)
   22 columnas (posiciones)
   Color: Azul (Control mayor) → Blanco (igual) → Rojo (ALS mayor)
```

**Consistente con:**
- Fig 2.3 (usa todos los miRNAs)
- Fig 2.4A-B (usan todos los miRNAs)
- Compara grupos directamente (como 2.1-2.2)

---

## ✅ **RESUMEN:**

**Entendiste correctamente:**
- VAF promedio por posición y grupo ✅
- Eje X = posiciones, Eje Y = miRNAs ✅

**Pero Z-score actual NO es diferencia entre grupos:**
- Z-score se calcula POR FILA (independiente)
- NO compara ALS vs Control directamente

**Mi propuesta:**
- Cambiar a DIFERENCIA DIRECTA (VAF_ALS - VAF_Control)
- Usar TODOS los 301 miRNAs (como las demás figuras)
- Consistencia con el resto del paso

---

**¿Genero la nueva Fig 2.5 con diferencia directa y TODOS los miRNAs?** 🚀

