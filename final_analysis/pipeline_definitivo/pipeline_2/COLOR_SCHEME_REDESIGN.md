# 🎨 COLOR SCHEME REDESIGN - PIPELINE_2

## 🎯 **PRINCIPIO FUNDAMENTAL**

**"Rojo es para ALS, no para conceptos genéricos"**

---

## 📊 **ESQUEMA DE COLORES ACTUALIZADO**

### **TIER 1: FIGURAS SIN GRUPOS** (Figuras 1-2)
**Contexto:** Análisis descriptivo, sin comparación de grupos

#### **Mutaciones:**
```r
# Tipos de mutación G>X
COLOR_GT <- "#FF7F00"        # 🟠 NARANJA para G>T (oxidativo, neutro)
COLOR_GA <- "#3498DB"        # 🔵 AZUL CLARO para G>A
COLOR_GC <- "#2ECC71"        # 🟢 VERDE para G>C

# Otras mutaciones
COLOR_TC <- "#9B59B6"        # 🟣 PÚRPURA para T>C (más frecuente)
COLOR_AG <- "#1ABC9C"        # 🔷 TURQUESA para A>G
COLOR_OTHER <- "#95A5A6"     # ⚪ GRIS para otras
```

#### **Regiones:**
```r
# Regiones funcionales de miRNA
COLOR_SEED <- "#FFD700"      # 🟡 DORADO para región seed (2-8)
COLOR_NONSEED <- "#B0B0B0"   # ⚪ GRIS para non-seed
COLOR_SEED_SHADE <- "#FFD70030"  # Dorado transparente (sombreado)
```

#### **Niveles de oxidación:**
```r
# Para Panel A de Figura 2 (G-content correlation)
COLOR_NO_OX <- "#95A5A6"     # ⚪ GRIS (sin oxidación)
COLOR_LOW_OX <- "#2ECC71"    # 🟢 VERDE (baja)
COLOR_MED_OX <- "#F39C12"    # 🟡 AMARILLO (media)
COLOR_HIGH_OX <- "#E67E22"   # 🟠 NARANJA OSCURO (alta)
# NO usar rojo aquí - reservado para ALS
```

---

### **TIER 2: FIGURAS CON GRUPOS** (Figuras 3-4)
**Contexto:** Comparación ALS vs Control, análisis estadístico

#### **Grupos principales:**
```r
# COLORES DE GRUPO (CRÍTICO)
COLOR_ALS <- "#E31A1C"       # 🔴 ROJO INTENSO para ALS ⭐⭐⭐
COLOR_CONTROL <- "#1F78B4"   # 🔵 AZUL para Control

# Variantes con transparencia
COLOR_ALS_LIGHT <- "#E31A1C80"     # Rojo semitransparente
COLOR_CONTROL_LIGHT <- "#1F78B480" # Azul semitransparente
```

#### **Significancia estadística:**
```r
# Elementos de tests
COLOR_SIGNIFICANT <- "#000000"     # ⚫ NEGRO para estrellas (*, **, ***)
COLOR_NS <- "#CCCCCC"              # ⚪ GRIS CLARO para no significativo
COLOR_FDR_LINE <- "#E74C3C"        # Línea de threshold FDR
```

#### **Elementos adicionales:**
```r
# Seed region en contexto de grupos
COLOR_SEED_SHADE_GROUP <- "#FFD70020"  # Dorado muy transparente
# Para no opacar los colores de grupo

# Confounders (Figura 4)
COLOR_AGE <- "#9B59B6"         # 🟣 PÚRPURA para edad
COLOR_SEX_M <- "#3498DB"       # 🔵 AZUL para masculino
COLOR_SEX_F <- "#E91E63"       # 🌸 ROSA para femenino
COLOR_BATCH <- "#F39C12"       # 🟡 AMARILLO para batch
```

---

## 🎨 **EJEMPLOS VISUALES**

### **FIGURA 1 (Actualizada - Sin grupos):**

**Panel A - Dataset Evolution:**
```
Barras de evolución:
  Raw Entries:      🟦 AZUL VIRIDIS (neutro)
  Individual SNVs:  🟩 VERDE VIRIDIS (neutro)
```

**Panel A - Mutation Types (Pie):**
```
  T>C: 🟣 PÚRPURA
  A>G: 🔷 TURQUESA
  G>A: 🔵 AZUL CLARO
  G>T: 🟠 NARANJA ← Cambiado de rojo
  Otros: colores variados
```

**Panel B - G>T Positional:**
```
Heatmap: 
  Gradiente azul oscuro → amarillo (viridis)
  
Seed vs Non-seed:
  Seed:     🟡 DORADO
  Non-Seed: ⚪ GRIS
```

**Panel C - Mutation Spectrum:**
```
Barras apiladas por posición:
  G>T: 🟠 NARANJA
  G>A: 🔵 AZUL
  G>C: 🟢 VERDE
```

---

### **FIGURA 2 (Actualizada - Sin grupos):**

**Panel A - G-Content Correlation:**
```
Puntos por nivel de oxidación:
  None:   ⚪ GRIS
  Low:    🟢 VERDE
  Medium: 🟡 AMARILLO
  High:   🟠 NARANJA OSCURO
  
Línea de tendencia: 🟠 NARANJA (no rojo)
```

**Panel C - G>T Specificity:**
```
Barras apiladas:
  G>T: 🟠 NARANJA
  G>A: 🔵 AZUL
  G>C: 🟢 VERDE
```

**Panel D - Position Frequency:**
```
  Seed:     🟡 DORADO
  Non-Seed: ⚪ GRIS
```

---

### **FIGURA 3 (Futura - CON grupos):**

**Panel B - Position Delta (TU FAVORITA):**
```
         G>T Frequency
    15% ┌────────────────────────────┐
        │         ***                 │
    10% │    **   🔴ALS  **          │
        │   🔴   🔴🔴   🔴           │
     5% │  🔵   🔵🔵   🔵Control    │
        │ 🔵                          │
     0% └────────────────────────────┘
        1  2  3  4  5  6  7  8  9 ...
        └─── SEED (dorado shade) ───┘

Colores:
  🔴 ROJO = ALS
  🔵 AZUL = Control
  ⭐ NEGRO = Estrellas significancia
  🟡 DORADO transparente = Seed region
```

---

## 🔧 **IMPLEMENTACIÓN DE CORRECCIONES**

### **PASO 1: Actualizar Figuras 1-2** 📋
```r
# Cambiar en visualization_functions_v4.R:
# - Rojo → Naranja para G>T
# - Usar dorado para seed
# - Reservar rojo para futuro

# Regenerar:
# - figure_1_corrected.png
# - figure_2_mechanistic_validation.png
```

### **PASO 2: Arreglar Panel B en HTML** 🔧
```r
# Verificar ruta en HTML
# Asegurar que panel_b_gt_analysis.png es accesible
# Regenerar HTML viewer si es necesario
```

### **PASO 3: Diseñar Figura 3** 📋
```r
# Usar esquema de colores de grupo:
# - Rojo para ALS
# - Azul para Control
# - Tests estadísticos incluidos
```

---

## ✅ **¿PROCEDO CON LAS CORRECCIONES?**

**Voy a:**
1. ✅ Actualizar esquema de colores (naranja para G>T)
2. ✅ Verificar y arreglar Panel B en HTML
3. ✅ Regenerar figuras con nuevos colores
4. ✅ Actualizar documentación

**¿Te parece bien? 🎨**

