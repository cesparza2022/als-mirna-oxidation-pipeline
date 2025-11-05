# 📐 DEFINICIONES Y MÉTRICAS - QUÉ MIDE CADA COSA

**Versión:** 0.5.1  
**Objetivo:** Aclarar EXACTAMENTE qué estamos midiendo en cada panel

---

## 📊 **DATOS ORIGINALES - ESTRUCTURA**

### **Archivo:** `miRNA_count.Q33.txt`

**Formato:**
```
miRNA name | pos:mut              | Sample1 | Sample2 | Sample3 | ...
────────────────────────────────────────────────────────────────
let-7a-5p  | 3:GT,5:GA,PM        | 0.15    | 0.23    | 0.08    | ...
miR-16-5p  | 2:TC,PM             | 0.45    | 0.12    | 0.31    | ...
```

**Columnas:**
- `miRNA name`: Nombre del miRNA
- `pos:mut`: Posiciones y mutaciones separadas por comas
  - Formato: `posición:tipo_mutación`
  - Ejemplo: `3:GT` = posición 3, mutación G→T
  - `PM` = Perfect Match (sin mutación)
- `Sample1, Sample2, ...`: 830 columnas de muestras
  - **Valores = VAF** (Variant Allele Frequency)
  - Rango: 0 a 1 (o 0% a 100%)

**Filas:** 68,968 filas (cada fila = un miRNA)

---

## 🔢 **MÉTRICAS USADAS - DEFINICIONES CLARAS**

### **1. RAW ENTRIES (Entradas crudas)**
```
QUÉ ES: Número de FILAS en el archivo original
VALOR: 68,968
SIGNIFICADO: Cada fila puede contener múltiples mutaciones
LABEL CORRECTO: "68,968 rows in original file"
```

### **2. INDIVIDUAL SNVs (SNVs individuales)**
```
QUÉ ES: Total de mutaciones después de:
  1. Separar por comas (split "3:GT,5:GA" → dos filas)
  2. Filtrar "PM" (Perfect Match = no mutación)
  
VALOR: 110,199
SIGNIFICADO: Cada mutación individual lista para análisis
LABEL CORRECTO: "110,199 individual SNVs (after split & PM filter)"
```

### **3. COUNT (Cuenta/Frecuencia absoluta)**
```
QUÉ ES: Número de veces que aparece algo
EJEMPLO: G>T count = 7,528
SIGNIFICADO: Hay 7,528 mutaciones G>T en total
USO: Figuras descriptivas, histogramas
LABEL CORRECTO: "Count" o "Number of mutations"
```

### **4. FRACTION (Fracción/Proporción)**
```
QUÉ ES: Count / Total
EJEMPLO: G>T fraction = 7,528 / 99,672 = 7.6%
SIGNIFICADO: G>T representa 7.6% de todas las mutaciones
USO: Comparaciones relativas
LABEL CORRECTO: "Fraction (%)" o "Percentage"
```

### **5. VAF (Variant Allele Frequency)** - NO USADO AÚN
```
QUÉ ES: Frecuencia alélica por muestra
VALORES: 0 - 1 (o 0% - 100%)
EJEMPLO: Sample1 tiene VAF = 0.15 para mutación en posición 3
SIGNIFICADO: 15% de los reads tienen esa mutación
USO: Análisis per-sample (Figura 3 cuando hagamos REAL)
LABEL CORRECTO: "VAF (%)" o "Variant Allele Frequency"
```

### **6. POSITIONAL FRACTION (Fracción posicional)**
```
QUÉ ES: Proporción de mutaciones en cada posición
CÁLCULO: (G>T en posición X) / (Total G>T)
EJEMPLO: Posición 22 tiene 1,193 G>T / 7,528 total = 15.8%
SIGNIFICADO: La posición 22 tiene el 15.8% de TODOS los G>T
USO: Ver dónde se concentran las mutaciones
LABEL CORRECTO: "Positional fraction (%)" o "% of total G>T"
```

---

## 🎨 **FIGURA 1 - QUÉ MIDE CADA PANEL**

### **Panel A: Dataset Evolution**

**Left subplot (barras):**
```
Métrica: COUNT de filas/SNVs
Eje Y: "Number of entries"
Valores:
  - "68,968 rows (original file)"
  - "110,199 individual SNVs"
```

**Right subplot (horizontal bars):**
```
Métrica: COUNT de cada tipo de mutación
Eje X: "Count"
Eje Y: Tipo de mutación
Labels: "19,410 (19.5%)" formato
```

---

### **Panel B: G>T Positional**

```
Métrica: COUNT de G>T por posición
Eje X: "Position in miRNA (1-22)"
Eje Y: "G>T count"
Valores: Count absoluto (ej: 1,193 en posición 22)
Color: ROJO para seed (#FFD700 shading)
```

---

### **Panel C: G>X Spectrum**

```
Métrica: COUNT de G>A, G>T, G>C
Eje X: "Count"
Eje Y: Tipo de mutación
G>T destacado en ROJO (#D62728) ← CORRECCIÓN
```

---

### **Panel D: Top miRNAs**

```
Métrica: COUNT de G>T por miRNA
Eje X: "G>T count"
Eje Y: miRNA name
Valores: Count total de G>T en ese miRNA
Color: ROJO (#D62728) ← CORRECCIÓN
```

---

## 🔬 **FIGURA 2 - QUÉ MIDE CADA PANEL**

### **Panel A: G-Content Correlation**

```
Eje X: "Number of G nucleotides in seed region (positions 2-8)"
  Valores: 0, 1, 2, 3, 4, 5, 6, 7
  Significado: Cuántas Guaninas tiene ese miRNA en posiciones 2-8
  
Eje Y: "Percentage of miRNAs with G>T (%)"
  Cálculo: (miRNAs con ≥1 G>T) / (total miRNAs con N G's) × 100
  Ejemplo: De 687 miRNAs con 1 G en seed, 9.8% tienen G>T
  
Tamaño punto: Number of miRNAs (cuántos miRNAs tienen N G's)

Interpretación: 
  - miRNAs con más G's en seed → mayor % tiene G>T
  - Evidencia de susceptibilidad oxidativa
```

---

### **Panel B: Sequence Context**
```
Estado: Placeholder (requiere secuencias de referencia)
```

---

### **Panel C: G>T Specificity**

```
Métrica: FRACCIÓN de cada tipo dentro de G>X
Eje X: "Position in miRNA (1-22)"
Eje Y: "Proportion of G>X mutations (%)"
Cálculo por posición:
  - G>T / (G>T + G>A + G>C) × 100
  
Interpretación:
  - ¿Qué % de mutaciones G>X son específicamente G>T?
  - Valida que G>T no es random, es específico
  
Color: G>T en ROJO (#D62728) ← CORRECCIÓN
```

---

### **Panel D: Position G-Content** (CONFUSO - NECESITA CLARIFICACIÓN)

**OPCIÓN A (lo que estoy mostrando AHORA - confuso):**
```
Métrica: COUNT de G>T por posición
Problema: Es lo mismo que Figura 1 Panel B
Duplicado: SÍ ❌
```

**OPCIÓN B (mejor - positional fraction):**
```
Métrica: FRACCIÓN posicional de G>T
Cálculo: (G>T en posición X) / (Total G>T) × 100
Eje Y: "% of total G>T"
Interpretación: Dónde se concentran los G>T
```

**OPCIÓN C (mover a Figura 3):**
```
Eliminar este panel de Figura 2
Usar ese espacio para algo más útil
Panel D de Figura 2 → análisis diferente
```

**¿Cuál prefieres para Panel D de Figura 2?**

---

## 🔴 **FIGURA 3 - QUÉ MIDE CADA PANEL**

### **Panel A: Global Burden**

```
Métrica: COUNT o VAF de G>T per-sample
Eje X: Groups (Control, ALS)
Eje Y: "G>T count per sample" O "Mean G>T VAF (%)"
Test: Wilcoxon rank-sum (ALS vs Control)
```

---

### **Panel B: Position Delta** ⭐ TU FAVORITO

**DECISIÓN CRÍTICA - ¿Qué métrica usar?**

**OPCIÓN A: POSITIONAL FRACTION (como tu ejemplo):**
```r
# Cálculo:
Por cada posición:
  - ALS: (G>T en pos X en ALS) / (Total SNVs en pos X en ALS)
  - Control: (G>T en pos X en Control) / (Total SNVs en pos X en Control)

Eje Y: "Positional fraction"
Interpretación: Proporción de SNVs que son G>T en cada posición
Test: Wilcoxon per position (22 tests)
FDR: Benjamini-Hochberg
```

**OPCIÓN B: COUNT:**
```r
# Cálculo:
Por cada posición:
  - ALS: Count de G>T en posición X
  - Control: Count de G>T en posición X
  
Eje Y: "G>T count"
Test: Wilcoxon per position
```

**Tu ejemplo dice "Positional fraction" → Suena a OPCIÓN A**

---

## ✅ **CORRECCIONES CONFIRMADAS**

### **1. COLORES - G>T = ROJO siempre**
```r
COLOR_GT <- "#D62728"  # ROJO para oxidación

Aplicar en:
✅ Figura 1 Panel C (spectrum)
✅ Figura 1 Panel D (top miRNAs)
✅ Figura 2 Panel C (specificity)
✅ Figura 2 Panel D (position)
✅ Figura 3 Panel B (ya está)
```

---

### **2. LABELS EXPLÍCITOS**

**Figura 1 Panel A:**
```r
# Evolution bars:
labels: "68,968 rows (original file)"
        "110,199 individual SNVs"

# Mutation types:
y-axis: "Mutation type"
x-axis: "Count of mutations"
labels: "19,410 (19.5%)" format
```

**Figura 2 Panel A:**
```r
x-axis: "Number of G nucleotides in seed region (positions 2-8)"
y-axis: "Percentage of miRNAs with ≥1 G>T mutation (%)"
subtitle: "Hypothesis: More G's → Higher oxidation susceptibility"
```

---

## ❓ **DECISIONES PENDIENTES - NECESITO TU INPUT**

### **DECISIÓN 1: Panel B Figura 3 (tu favorito)**
¿Usar **POSITIONAL FRACTION** (como tu ejemplo) o **COUNT**?

### **DECISIÓN 2: Panel D Figura 2**
¿Mantener como está, cambiar a fraction, o eliminar/reemplazar?

### **DECISIÓN 3: Orden de implementación**
¿Corrijo colores primero (rápido) o hago análisis de fraction completo (más tiempo)?

---

## 🚀 **PRÓXIMO PASO SUGERIDO**

**MIENTRAS DECIDES sobre VAF/fraction:**

Voy a corregir lo OBVIO ya:
1. ✅ G>T = ROJO en todas las figuras
2. ✅ Labels explícitos (counts, %, etc.)
3. ✅ Figura 2 Panel A - clarificar "G's in seed region"
4. ✅ Regenerar figuras

**Luego implementamos fraction/VAF según decidas**

**¿Procedo con las correcciones obvias mientras decides sobre fraction vs count?** 🚀

