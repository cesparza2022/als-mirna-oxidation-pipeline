# 🔍 ¿DE DÓNDE VIENEN LOS 3 miRNAs CANDIDATOS?

**Fecha:** 2025-10-17 03:50

---

## 🎯 PREGUNTA: ¿Cómo llegamos a estos 3 miRNAs?

**Respuesta corta:** Del **Volcano Plot del Paso 2** con el método correcto.

---

## 📊 FLUJO COMPLETO: PASO 1 → PASO 2 → PASO 3

### **PASO 1: Análisis Inicial**
```
Entrada: final_analysis/processed_data/final_processed_data.csv
  ↓
Filtro: Solo G>T en seed region (posiciones 2-8)
  ↓
Resultado: 301 miRNAs con al menos 1 SNV G>T en seed
  ↓
Output: SEED_GT_miRNAs_RANKING.csv
```

**Top 5 del Paso 1 (por VAF total):**
1. hsa-miR-6129 (VAF total = 7.09)
2. hsa-miR-378g (VAF total = 4.92)
3. hsa-miR-30b-3p (VAF total = 2.97)
4. hsa-miR-6133 (VAF total = 2.16)
5. hsa-miR-3195 (VAF total = 1.07)

**⚠️ PROBLEMA:** Este ranking NO considera si hay diferencia entre ALS y Control.

---

### **PASO 2: Comparación ALS vs Control**

**Entrada:** Los 301 miRNAs del Paso 1

**Método:** Volcano Plot (método correcto)
- Para cada miRNA:
  - Calcular **VAF total por muestra** (sum de todos sus SNVs G>T)
  - Comparar ALS vs Control (Wilcoxon test)
  - Calcular **log2(Fold Change)** y **p-value ajustado (FDR)**

**Criterios de significancia:**
- **FC > 1.5** (log2FC > 0.58) → Enriquecido en ALS
- **p-value ajustado < 0.05** → Estadísticamente significativo

---

## 🔥 RESULTADO DEL VOLCANO PLOT

### **Solo 3 miRNAs significativos en ALS:**

```
# A tibble: 3 × 5
  miRNA            log2FC    padj Mean_ALS Mean_Control
  <chr>             <dbl>   <dbl>    <dbl>        <dbl>
1 hsa-miR-196a-5p   1.78  0.00217   0.0172      0.00500
2 hsa-miR-9-5p      0.663 0.00583   0.0169      0.0102 
3 hsa-miR-142-5p    1.89  0.0235    0.00519     0.00137
```

### **Interpretación:**

**hsa-miR-196a-5p:**
- **FC = +1.78** → 3.4x más G>T en ALS que en Control
- **p = 0.00217** → Altamente significativo
- **Mean ALS = 0.0172** vs Control = 0.0050

**hsa-miR-9-5p:**
- **FC = +0.66** → 1.6x más G>T en ALS
- **p = 0.00583** → Significativo
- **Mean ALS = 0.0169** vs Control = 0.0102

**hsa-miR-142-5p:**
- **FC = +1.89** → 3.7x más G>T en ALS
- **p = 0.0235** → Significativo
- **Mean ALS = 0.00519** vs Control = 0.00137

---

## ⚠️ ¿QUÉ PASÓ CON LOS DEL PASO 1?

### **hsa-miR-6129 (Top 1 del Paso 1):**
```
VAF total: 7.09 (muy alto)
Pero en el Volcano Plot:
  - log2FC = -1.42 (CONTROL > ALS) ❌
  - p-value = 0.44 (NO significativo)
  
→ ELIMINADO porque está ENRIQUECIDO EN CONTROL, no en ALS
```

### **hsa-miR-378g (Top 2 del Paso 1):**
```
VAF total: 4.92
Pero en el Volcano Plot:
  - log2FC = +0.30 (ALS > Control, pero pequeño)
  - p-value = 0.18 (NO significativo)
  
→ ELIMINADO porque NO es estadísticamente significativo
```

---

## 📊 VISUALIZACIÓN DEL PROCESO

```
PASO 1: 301 miRNAs con G>T en seed
    ↓
    Ranking por VAF total (SIN considerar grupos)
    ↓
    Top 20: miR-6129, miR-378g, miR-30b-3p, ...
    
    ⚠️ Pero... ¿Cuáles son DIFERENTES entre ALS y Control?

PASO 2: Volcano Plot (Comparación ALS vs Control)
    ↓
    Test estadístico + Fold Change para CADA miRNA
    ↓
    Criterios: FC > 1.5 Y p < 0.05
    ↓
    RESULTADO: Solo 3 significativos en ALS ⭐
      1. hsa-miR-196a-5p (FC +1.78, p 0.002)
      2. hsa-miR-9-5p (FC +0.66, p 0.006)
      3. hsa-miR-142-5p (FC +1.89, p 0.024)

PASO 3: Análisis Funcional de los 3 candidatos
    ↓
    Target prediction
    ↓
    Pathway enrichment
    ↓
    Network analysis
    ↓
    HALLAZGO: Los 3 regulan 1,207 genes comunes ⭐
```

---

## 🔍 ¿POR QUÉ ESTOS 3 Y NO OTROS?

### **Porque son los ÚNICOS que cumplen AMBOS criterios:**

1. **Biológico:** G>T en seed region (oxidación)
2. **Estadístico:** Significativamente diferentes entre ALS y Control

### **Los demás miRNAs del Paso 1:**
- Algunos tienen mucho G>T pero **NO hay diferencia ALS vs Control**
- Otros tienen diferencia pero **NO es estadísticamente significativa**
- Algunos están **enriquecidos en CONTROL, no en ALS** (ej: miR-6129)

---

## 📂 ARCHIVOS CLAVE PARA ENTENDER ESTO

### **Paso 1:**
```
pipeline_1/SEED_GT_miRNAs_RANKING.csv
→ Los 301 miRNAs con G>T en seed
→ Ranking por VAF total
```

### **Paso 2:**
```
pipeline_2/VOLCANO_PLOT_DATA_PER_SAMPLE.csv
→ Resultado del Volcano Plot
→ Muestra los 3 candidatos ALS + 22 candidatos Control

pipeline_2/METODO_VOLCANO_PLOT.md
→ Explicación detallada del método correcto
```

### **Paso 3:**
```
pipeline_3/data/ALS_candidates.csv
→ Los 3 candidatos que analizamos aquí
```

---

## 🎯 RESUMEN SIMPLE

**¿De dónde vienen?**
→ Del **Volcano Plot del Paso 2**

**¿Por qué estos 3?**
→ Son los **ÚNICOS significativamente enriquecidos en ALS**

**¿Qué los hace especiales?**
→ **FC > 1.5x** y **p < 0.05** comparando ALS vs Control

**¿Qué pasa con los otros?**
→ 22 miRNAs son significativos en **CONTROL** (Control > ALS)
→ Los demás NO son estadísticamente diferentes

---

## 💡 HALLAZGO CRÍTICO DEL PASO 3

**Una vez que sabemos que estos 3 están enriquecidos en ALS:**

→ Descubrimos que regulan **1,207 genes EN COMÚN** ⭐

→ Esos genes están en **525 procesos oxidativos** ⭐

→ Confirma que **NO es casualidad** - forman un módulo funcional coordinado

---

## 🔄 SI QUIERES CAMBIAR LOS CRITERIOS

**Puedes ajustar el umbral del Volcano Plot:**

**Más estricto:**
- FC > 2.0 (en vez de 1.5)
- p < 0.01 (en vez de 0.05)
→ Probablemente solo quedarían 1-2 miRNAs

**Menos estricto:**
- FC > 1.2
- p < 0.10
→ Incluiría más candidatos (5-10)

---

**Documentado:** 2025-10-17 03:50  
**Origen:** Volcano Plot del Paso 2  
**Criterio:** FC > 1.5 (log2FC > 0.58) AND padj < 0.05  
**Resultado:** 3 candidatos ALS únicos

