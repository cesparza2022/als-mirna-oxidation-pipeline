# 🎯 INTEGRACIÓN COMPLETA - PIPELINE_2 v0.2.0

## 📊 **CÓMO SE INTEGRA TODO EN EL PIPELINE**

### **PRINCIPIO FUNDAMENTAL:**
**"Análisis progresivo: Descriptivo → Mecanístico → Comparativo"**

---

## 🔬 **FASE 1: CARACTERIZACIÓN** (Sin grupos, sin estadística)

### **FIGURA 1: Dataset Characterization** ✅
**Pregunta:** "¿Qué tenemos?"

**Análisis:**
- Descriptivo puro (NO tests estadísticos)
- Frecuencias y proporciones
- Identificación de patrones

**Paneles:**
- **A:** Evolución del dataset + Tipos de mutación
- **B:** Distribución posicional de G>T + Seed vs Non-seed
- **C:** Espectro de mutaciones G>X + Top 10 tipos
- **D:** Placeholder

**Colores sugeridos (NEUTRAL):**
- 🟠 Naranja para G>T (oxidativo pero neutro)
- 🟡 Dorado para región seed
- 🔵 Azul para otras mutaciones
- ⚪ Gris para non-seed

**Preguntas respondidas:**
- SQ1.1: ¿Estructura del dataset? → 110,199 SNVs
- SQ1.2: ¿Distribución de G>T? → Mapeada
- SQ1.3: ¿Tipos de mutaciones? → 12 tipos

**Estadística:** NINGUNA (es correcto así) ✅

---

### **FIGURA 2: Mechanistic Validation** ✅
**Pregunta:** "¿Por qué G>T es oxidativo?"

**Análisis:**
- Validación mecanística
- Correlaciones (Spearman)
- Especificidad (proporciones)
- NO comparación de grupos

**Paneles:**
- **A:** Correlación G-content vs Oxidación (r = 0.347)
- **B:** Contexto de secuencia (placeholder)
- **C:** Especificidad G>T (31.6% de G>X)
- **D:** Frecuencia G>T por posición

**Colores sugeridos (NEUTRAL):**
- 🟠 Naranja para G>T
- 🟡 Dorado para seed
- 🟢 Verde para low oxidation
- 🔴 Rojo oscuro para high oxidation (concepto de nivel, NO grupo)

**Preguntas respondidas:**
- SQ3.1: ¿G-content correlaciona? → SÍ (r=0.347)
- SQ3.2: ¿G>T específico? → SÍ (31.6% de G>X)
- SQ3.3: ¿Patrones oxidativos? → SÍ (dosis-respuesta)

**Estadística:** Solo correlaciones (NO tests de grupos) ✅

---

## 🔬 **FASE 2: COMPARACIÓN** (Con grupos, CON estadística)

### **FIGURA 3: Group Comparison** 🔧 TEMPLATE
**Pregunta:** "¿HAY diferencias entre ALS y Control?"

**Análisis:**
- **AQUÍ SÍ van tests estadísticos**
- Wilcoxon rank-sum test
- FDR correction (Benjamini-Hochberg)
- Effect sizes (Cohen's d, Odds Ratio)

**Paneles propuestos:**

**Panel A: Global G>T Burden**
```r
# Violin/boxplot por grupo
# Test: Wilcoxon rank-sum
# Output: p-value, effect size
# Colores: 🔴 ALS, 🔵 Control
```

**Panel B: Position Delta Curve** ⭐ TU FAVORITA
```r
# Barras por posición, ALS vs Control
# Test: Wilcoxon por cada posición
# FDR correction across positions
# Estrellas: * p<0.05, ** p<0.01, *** p<0.001
# Región seed sombreada
# Colores: 🔴 ALS, 🔵 Control
```

**Panel C: Seed vs Non-Seed by Group**
```r
# 2×2 comparison (Seed/Non-seed × ALS/Control)
# Test: Fisher's exact
# Output: OR, CI, p-value
# Interacción: ¿Seed es MÁS afectado en ALS?
```

**Panel D: Differential miRNAs**
```r
# Volcano plot
# Test: Per-miRNA Fisher + FDR
# Top miRNAs labeled
# Threshold lines (p<0.05, FC>2)
```

**Colores (CON GRUPOS):**
- 🔴 **ROJO para ALS** ⭐⭐⭐
- 🔵 **AZUL para Control**
- 🟡 **Dorado para seed region** (sombreado)

**Estadística:**
- ✅ Wilcoxon test (global y por posición)
- ✅ Fisher's exact test (seed vs non-seed × group)
- ✅ FDR correction (Benjamini-Hochberg)
- ✅ Effect sizes (Cohen's d, OR)
- ✅ Visualización con estrellas

**Preguntas a responder:**
- SQ2.1: ¿G>T enriquecido en ALS?
- SQ2.2: ¿Diferencias posicionales?
- SQ2.3: ¿miRNAs específicos?
- SQ2.4: ¿Seed más vulnerable en ALS?

**Requiere:** `sample_groups.csv` del usuario

---

## 🎨 **ESQUEMA DE COLORES CORREGIDO**

### **TIER 1 (Figuras 1-2): COLORES NEUTRALES**
```r
# Sin grupos → colores descriptivos
COLOR_GT <- "#FF7F00"        # Naranja (G>T)
COLOR_GA <- "#3498db"        # Azul (G>A)
COLOR_GC <- "#2ecc71"        # Verde (G>C)
COLOR_SEED <- "#FFD700"      # Dorado (seed region)
COLOR_NONSEED <- "#B0B0B0"   # Gris (non-seed)
COLOR_LOW_OX <- "#2ecc71"    # Verde (baja oxidación)
COLOR_HIGH_OX <- "#d35400"   # Naranja oscuro (alta oxidación)
```

### **TIER 2 (Figuras 3-4): COLORES DE GRUPO**
```r
# Con grupos → colores por condición
COLOR_ALS <- "#E31A1C"       # 🔴 ROJO para ALS ⭐
COLOR_CONTROL <- "#1F78B4"   # 🔵 AZUL para Control
COLOR_SEED_SHADE <- "#FFD70040"  # Dorado transparente (sombreado)
COLOR_SIGNIFICANT <- "#000000"   # Negro (estrellas *)
```

---

## 📊 **INTEGRACIÓN: DÓNDE VA CADA COSA**

| Elemento | Figura 1-2 | Figura 3+ | Justificación |
|----------|------------|-----------|---------------|
| **Frecuencias** | ✅ Sí | ✅ Sí | Descriptivo siempre |
| **Tests estadísticos** | ❌ NO | ✅ SÍ | Solo con grupos |
| **Estrellas (*, **)** | ❌ NO | ✅ SÍ | Solo significancia |
| **Rojo = ALS** | ❌ NO | ✅ SÍ | Solo con grupos |
| **Naranja = G>T** | ✅ Sí | ❌ NO | Solo sin grupos |
| **FDR correction** | ❌ NO | ✅ SÍ | Solo tests múltiples |
| **Effect sizes** | ❌ NO | ✅ SÍ | Solo comparaciones |

---

## 🔍 **TU PDF DE REFERENCIA: `distribucion_por_posicion_filtrado.pdf`**

**Lo que probablemente muestra:**
- Barras por posición (1-22 o más)
- **Dos colores:** ALS vs Control (rojo vs azul)
- **Tests estadísticos** por posición
- **Estrellas** donde es significativo
- **Región seed** probablemente marcada

**Esto es EXACTAMENTE Figura 3, Panel B:**
```
Position-Specific Comparison (ALS vs Control)

Posición:  1    2    3    4    5    6    7    8    9   10 ...
          ┌────┬────┬────┬────┬────┬────┬────┬────┬────┬────┐
     15%  │    │ ** │    │ ***│    │ ***│ ** │    │    │    │
          │    │🔴  │    │🔴  │    │🔴  │🔴  │    │    │    │
     10%  │    │🔴  │    │🔴  │    │🔴  │🔴  │    │    │    │
          │🔵  │🔵  │🔵  │🔵  │🔵  │🔵  │🔵  │🔵  │🔵  │🔵  │
      0%  └────┴────┴────┴────┴────┴────┴────┴────┴────┴────┘
           └────────── SEED (shaded) ──────────┘

     🔴 = ALS (rojo)
     🔵 = Control (azul)
     ** = p < 0.01 (FDR corrected)
    *** = p < 0.001 (FDR corrected)
```

**ESTE análisis requiere:**
- Sample groups (ALS vs Control labels)
- Tests estadísticos por posición
- FDR correction
- **Es Figura 3, Panel B - NO Figura 1**

---

## ✅ **CONFIRMACIÓN DE TU FEEDBACK**

### **✅ CORRECTO:**
1. Falta análisis estadístico → **Correcto, va en Figura 3 (con grupos)**
2. Rojo para ALS → **Correcto, lo aplicaremos en Figura 3**
3. Estadística por posición si hay grupos → **Exacto, Figura 3 Panel B**

### **🔧 A CORREGIR:**
1. Cambiar rojo→naranja en Figuras 1-2 (reservar rojo para ALS)
2. Verificar por qué Panel B no aparece en tu vista
3. Mejorar explicación de cada panel

### **📋 PRÓXIMO PASO:**
Implementar Figura 3 con:
- Template de grupos
- Tests estadísticos por posición
- Esquema de colores ALS (rojo) vs Control (azul)
- Estrellas de significancia

---

## 🎊 **RESUMEN FINAL**

**LO QUE TENEMOS:**
- ✅ Figura 1: Caracterización (descriptiva, colores neutrales)
- ✅ Figura 2: Validación mecanística (descriptiva, colores neutrales)

**LO QUE VIENE:**
- 📋 Figura 3: Comparación de grupos (estadística, rojo=ALS, azul=Control)
- 💡 Figura 4: Confounders (opcional)

**TODO INTEGRADO:**
1. Sin grupos → Descriptivo, sin tests, colores neutrales
2. Con grupos → Comparativo, con tests, rojo=ALS azul=Control

**¿Te queda claro la integración? ¿Qué parte necesitas que aclare más? 🚀**

