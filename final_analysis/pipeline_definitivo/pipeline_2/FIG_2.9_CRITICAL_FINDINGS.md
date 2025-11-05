# 🔥 FIGURE 2.9 CV - CRITICAL FINDINGS

**Date:** 2025-10-27  
**Status:** ✅ **MAJOR DISCOVERY**

---

## 🚨 **HALLAZGO CRÍTICO: ALS ES MÁS HETEROGÉNEO**

### **Resultado Principal:**

```
ALS:     Mean CV = 1015% (SD = 539%)
Control: Mean CV = 753% (SD = 414%)

Diferencia: 262% (35% más heterogéneo)

Estadística:
  F-test:      p = 9.45e-08 (highly significant!)
  Levene's:    p = 5.39e-05 (robust confirmation)
  Wilcoxon:    p = 2.08e-13 (median difference)

CONCLUSIÓN: ✅ ALS es SIGNIFICATIVAMENTE más heterogéneo
```

---

## 💡 **¿QUÉ SIGNIFICA ESTO BIOLÓGICAMENTE?**

### **Interpretación:**

**ALS es más variable:**
```
Dentro del grupo ALS:
  • Algunos pacientes tienen G>T MUY ALTO
  • Otros pacientes tienen G>T MUY BAJO
  • Variabilidad 35% mayor que Control
  
Implicaciones:
  → Subtipos de ALS (heterogeneidad clínica)
  → Diferentes etapas de enfermedad
  → Diferentes mecanismos subyacentes
  → Respuesta variable a tratamientos
```

**Control es más uniforme:**
```
Dentro del grupo Control:
  • Menor dispersión en G>T burden
  • Muestras más homogéneas
  • Proceso más consistente
  
Implicaciones:
  → Controles bien caracterizados
  → Menor variabilidad basal
  → Más predecibles
```

---

## 🔬 **SEGUNDO HALLAZGO: CORRELACIÓN NEGATIVA**

### **CV vs Mean VAF:**

```
ALS:     r = -0.333 (p = 6.03e-14)
Control: r = -0.363 (p = 2.64e-13)

AMBOS grupos muestran correlación NEGATIVA!

Interpretación:
  → miRNAs con BAJO VAF medio = ALTA variabilidad (CV alto)
  → miRNAs con ALTO VAF medio = BAJA variabilidad (CV bajo)
```

---

### **¿Por qué es esto importante?**

**Patrón inesperado:**
```
Esperado (típicamente):
  High mean → High CV (rico se hace más rico)
  
Observado:
  High mean → LOW CV (¡lo opuesto!)
  
Explicación posible:
  → miRNAs con alto burden son CONSISTENTEMENTE altos
  → miRNAs con bajo burden son VARIABLES
  
  Razones:
    a) miRNAs de bajo burden = cerca del límite de detección
       → Ruido técnico domina
       → Alta variabilidad relativa
    
    b) miRNAs de alto burden = señal biológica real
       → Consistente entre muestras
       → Baja variabilidad relativa
```

---

## 📊 **HALLAZGO 3: CV EXTREMADAMENTE ALTOS**

### **Top miRNAs más variables:**

**ALS:**
```
1. hsa-miR-1843:      CV = 3506% (35x variabilidad!)
2. hsa-miR-5187-5p:   CV = 3136%
3. hsa-miR-1255b-5p:  CV = 2992%
4. hsa-miR-1275:      CV = 2903%
5. hsa-miR-127-5p:    CV = 2761%
```

**Control:**
```
1. hsa-miR-342-5p:    CV = 2035%
2. hsa-miR-181a-2-3p: CV = 1904%
3. hsa-miR-4433b-3p:  CV = 1883%
4. hsa-miR-1275:      CV = 1852% ← También en ALS top 5!
5. hsa-miR-361-3p:    CV = 1785%
```

---

### **¿Por qué CVs TAN altos?**

**CV > 1000% es EXTREMO!**

```
CV normal en biología: 20-100%
CV que observamos: 1000-3500%

Posibles razones:

1. CERCA DEL LÍMITE DE DETECCIÓN:
   Mean VAF muy bajo (~0.0001)
   SD relativamente grande (~0.003)
   → CV = 0.003 / 0.0001 = 3000%
   
   Interpretación: Ruido técnico en bajo burden

2. PRESENCIA/AUSENCIA BINARIA:
   Algunos samples = 0
   Otros samples = 0.01
   → Alta variabilidad relativa
   
   Interpretación: Detección intermitente

3. BIOLÓGICAMENTE VARIABLE:
   Expresión muy variable entre personas
   → Algunos expresan, otros no
   
   Interpretación: Regulación individual
```

---

## 🎯 **IMPLICACIONES**

### **1. ALS es Heterogéneo (Subtypes?)**

```
ALS Mean CV = 1015% > Control 753%
p < 1e-07

Posibles explicaciones:

A) SUBTIPOS DE ALS:
   • ALS esporádico vs familiar
   • ALS bulbar vs espinal
   • Progresión rápida vs lenta
   → Diferentes perfiles de G>T

B) ETAPAS DE ENFERMEDAD:
   • Temprano vs tardío
   • Activo vs estable
   → Variabilidad temporal

C) FACTORES AMBIENTALES:
   • Exposiciones variables
   • Estilo de vida
   → Heterogeneidad ambiental
```

---

### **2. miRNAs de Bajo Burden = Ruido Técnico**

```
Correlación negativa (r = -0.33):
  Low mean → High CV
  
Interpretación:
  → miRNAs con bajo VAF son menos confiables
  → Cerca del límite de detección
  → CV alto = ruido técnico, no biológico
  
Acción:
  → Filtrar miRNAs con Mean < threshold
  → Enfocarse en miRNAs de alto burden
  → Son más consistentes y confiables
```

---

### **3. Identificar Candidatos a Filtrar**

```
miRNAs con CV > 2000%:
  → Probablemente técnicamente problemáticos
  → Considerar excluir de análisis downstream
  → O: Requieren validación especial (qPCR)
```

---

## ✅ **CONSISTENCIA CON OTRAS FIGURAS**

### **Figura 2.7 (PCA):**
```
PCA mostró: R² = 2% (98% variación individual)

Fig 2.9 confirma:
  ✓ Alta heterogeneidad (CV > 1000%)
  ✓ ALS más heterogéneo
  ✓ Variación individual domina
  
CONSISTENTE! ✅
```

### **Figura 2.1-2.2:**
```
Control > ALS en mean burden

Fig 2.9 muestra:
  Control CV = 753% (menor que ALS)
  
Interpretación:
  → Control tiene higher mean BUT lower CV
  → Control es más consistentemente alto
  → ALS es más variable (algunos altos, algunos bajos)
  
HACE SENTIDO! ✅
```

---

## 📊 **VISUALIZACIÓN: QUÉ ESPERAR**

### **Figura 2.9A (Mean CV):**
```
Barplot con error bars:
  ALS bar = ~1015% (más alto)
  Control bar = ~753% (más bajo)
  Asteriscos = *** (altamente significativo)
```

### **Figura 2.9B (Distributions):**
```
Violin + Boxplot:
  ALS box shifted UP
  ALS violin más ANCHO
  Control más COMPACTO
  
Diferencia visual clara!
```

### **Figura 2.9C (CV vs Mean):**
```
Scatter plot con líneas de fit:
  AMBAS líneas con pendiente NEGATIVA
  A la izquierda (low mean): puntos ARRIBA (high CV)
  A la derecha (high mean): puntos ABAJO (low CV)
  
Patrón claro de correlación negativa!
```

### **Figura 2.9D (Top Variable):**
```
Barplot horizontal:
  Top 20 miRNAs más variables
  Mix de ALS y Control
  CVs > 1700%
  
Identifica candidatos problemáticos!
```

---

## 🎯 **RECOMENDACIONES**

### **1. Para el Paper:**

**Main Finding:**
```
"ALS patients show 35% higher heterogeneity in G>T burden
 compared to Controls (p < 1e-07), suggesting disease subtypes
 or variable stages within the ALS cohort."
```

**Include:**
- Fig 2.9B (Distribution) - Shows clear difference
- Fig 2.9C (Correlation) - Shows technical pattern
- Table of top variable miRNAs

---

### **2. Para Análisis Downstream:**

**Filter miRNAs:**
```r
# Remove highly variable (CV > 2000%)
# Likely technical noise
reliable_mirnas <- cv_data %>%
  filter(CV < 2000) %>%
  pull(miRNA_name)

# Use only these for:
#   - Biomarker development
#   - Validation studies
#   - Clinical testing
```

---

### **3. Para Investigación Futura:**

**Stratify ALS:**
```
High CV in ALS suggests subtypes
→ Cluster ALS patients by G>T profile
→ Correlate with clinical features
→ Personalized treatment strategies
```

---

## 📋 **OUTPUTS GENERADOS**

### **Figuras (5):**
```
✅ FIG_2.9A_MEAN_CV.png             - Comparación mean CV
✅ FIG_2.9B_CV_DISTRIBUTION.png     - Distribuciones completas
✅ FIG_2.9C_CV_VS_MEAN.png          - Correlación (¡negativa!)
✅ FIG_2.9D_TOP_VARIABLE.png        - Top 20 más variables
✅ FIG_2.9_COMBINED_IMPROVED.png    - Combinada ⭐ RECOMENDADA
```

### **Tablas (5):**
```
✅ TABLE_2.9_CV_summary.csv               - Stats por grupo
✅ TABLE_2.9_CV_all_miRNAs.csv            - Todos los CV values
✅ TABLE_2.9_statistical_tests.csv        - 3 tests estadísticos
✅ TABLE_2.9_top_variable_miRNAs.csv      - Top 10 por grupo
✅ TABLE_2.9_CV_Mean_correlations.csv     - Correlaciones
```

---

## 🔥 **TRES HALLAZGOS CRÍTICOS**

### **1. ALS > Control en Heterogeneidad**
```
35% más heterogéneo (p < 1e-07)
→ Subtipos de ALS
→ Medicina personalizada necesaria
```

### **2. Correlación Negativa (CV ~ Mean)**
```
r = -0.33 (ambos grupos)
→ Low-burden miRNAs = noise
→ High-burden miRNAs = reliable
```

### **3. CVs Extremos (> 3000%)**
```
→ Algunos miRNAs MUY variables
→ Probablemente ruido técnico
→ Candidatos a filtrar
```

---

**Status:** ✅ **APPROVED con hallazgos mayores**

**Figura recomendada:** `FIG_2.9_COMBINED_IMPROVED.png`

---

**¡4 figuras abiertas para revisar!** 🚀

