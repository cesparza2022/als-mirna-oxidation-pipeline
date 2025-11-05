# 🔬 EXPLICACIÓN DETALLADA: Cálculo de Métricas

**Fecha:** 2025-10-17 04:50

---

## ✅ CONFIRMACIÓN: Solo Región Semilla

**SÍ**, ya estamos usando **SOLO** posiciones 2-8 de la seed:

```R
# Filtro que aplicamos SIEMPRE:
data_seed_only <- data %>%
  filter(str_detect(pos.mut, "^[2-8]:GT$"))
#               Regex: ^[2-8]  = Posiciones 2,3,4,5,6,7,8
#                      :GT$    = Solo mutaciones G>T
```

**NO** incluimos posiciones 1, 9, 10+ (fuera de seed).

---

## 📊 CÁLCULO DE MÉTRICAS: Paso a Paso

### **MÉTRICA 1: VAF (Variant Allele Frequency)**

**¿Qué es?**
```
VAF = Cuentas de la variante / Total de cuentas

Ejemplo de 1 SNV en 1 muestra:
  miR-X, posición 3:GT, muestra ALS_001
  
  Reads totales en esa posición: 1000
  Reads con G (referencia): 900
  Reads con T (variante): 100
  
  VAF = 100 / 1000 = 0.10 (10%)
```

**En tu dataset:**
- Ya viene calculado (columnas de muestras tienen VAF directamente)
- Rango: 0.0 a 0.5 (0% a 50%)
- Ya filtramos VAF >= 0.5 (artefactos)

**Para un miRNA con MÚLTIPLES SNVs:**
```
miR-3195 tiene 2 SNVs en seed:
  - SNV1: posición 2:GT
  - SNV2: posición 5:GT

En muestra ALS_001:
  SNV1_VAF = 0.02
  SNV2_VAF = 0.03
  
TOTAL_VAF_miR3195_ALS001 = 0.02 + 0.03 = 0.05

→ Sumamos VAF de TODOS los SNVs del miRNA
```

---

### **MÉTRICA 2: p-value (Wilcoxon Rank-Sum Test)**

**¿Qué compara?**
```
H0 (hipótesis nula): VAF_ALS = VAF_Control (no hay diferencia)
H1 (hipótesis alternativa): VAF_ALS ≠ VAF_Control (hay diferencia)
```

**Cálculo paso a paso:**

```R
# Ejemplo: miR-196a-5p

# PASO 1: Obtener VAF por muestra
# ────────────────────────────────────────────────────────────

# Para cada muestra, calcular VAF total del miRNA
# (sumando TODOS sus SNVs G>T en seed)

mirna_data <- data %>%
  filter(miRNA_name == "hsa-miR-196a-5p",
         str_detect(pos.mut, "^[2-8]:GT$"))

# Convertir a long format
mirna_long <- mirna_data %>%
  pivot_longer(cols = samples, names_to = "Sample_ID", values_to = "VAF")

# Unir con metadata para saber qué es ALS y qué Control
mirna_long <- mirna_long %>%
  left_join(metadata)

# Si el miRNA tiene múltiples SNVs, SUMAR por muestra
mirna_per_sample <- mirna_long %>%
  group_by(Sample_ID, Group) %>%
  summarise(Total_VAF = sum(VAF, na.rm = TRUE))

# PASO 2: Separar por grupo
# ────────────────────────────────────────────────────────────

# Vectores de VAF por grupo
als_vals <- mirna_per_sample %>%
  filter(Group == "ALS") %>%
  pull(Total_VAF)

# Ejemplo de valores:
# als_vals = c(0.02, 0.03, 0.01, 0.04, 0.02, 0.03, ...)
# Longitud: 313 valores (una por muestra ALS)

ctrl_vals <- mirna_per_sample %>%
  filter(Group == "Control") %>%
  pull(Total_VAF)

# Ejemplo de valores:
# ctrl_vals = c(0.005, 0.008, 0.003, 0.006, ...)
# Longitud: 102 valores (una por muestra Control)

# PASO 3: Test estadístico
# ────────────────────────────────────────────────────────────

# Wilcoxon rank-sum test (también llamado Mann-Whitney U)
# Es un test NO-PARAMÉTRICO (no asume normalidad)

test_result <- wilcox.test(als_vals, ctrl_vals)

# p-value crudo
p_value_raw <- test_result$p.value
# Ejemplo: 0.0022

# PASO 4: Corrección por comparaciones múltiples
# ────────────────────────────────────────────────────────────

# Como estamos comparando 301 miRNAs, necesitamos FDR correction
# Método: Benjamini-Hochberg

all_p_values <- c(p_miR1, p_miR2, ..., p_miR301)

padj <- p.adjust(all_p_values, method = "BH")

# p-value ajustado
# Ejemplo: 0.0022 → 0.0022 (si es muy bajo, casi no cambia)
#          0.049 → 0.068 (si es borderline, puede aumentar)
```

**Interpretación del p-value:**
```
p < 0.01: Probabilidad < 1% de que la diferencia sea por azar
p < 0.05: Probabilidad < 5% de que la diferencia sea por azar
p < 0.10: Probabilidad < 10% de que la diferencia sea por azar
p > 0.10: No suficientemente significativo
```

**¿Por qué Wilcoxon y no t-test?**
- ✅ No asume distribución normal (VAF no es normal)
- ✅ Robusto a outliers
- ✅ Funciona con muestras de diferente tamaño (313 vs 102)
- ✅ Estándar en bioinformática

---

### **MÉTRICA 3: Z-score (Effect Size Normalizado)**

**¿Qué mide?**
```
Z-score = (Diferencia entre grupos) / (Variabilidad pooled)

En otras palabras:
  "¿Qué tan grande es la diferencia, relativo a cuánto varían los datos?"
```

**Cálculo paso a paso:**

```R
# Ejemplo: miR-196a-5p

# PASO 1: Calcular media y SD por grupo
# ────────────────────────────────────────────────────────────

# Grupo ALS
Mean_ALS <- mean(als_vals)     # ej: 0.0162
SD_ALS <- sd(als_vals)          # ej: 0.0254

# Grupo Control
Mean_Control <- mean(ctrl_vals) # ej: 0.0047
SD_Control <- sd(ctrl_vals)     # ej: 0.0089

# PASO 2: Calcular diferencia
# ────────────────────────────────────────────────────────────

Delta <- Mean_ALS - Mean_Control
# Ejemplo: 0.0162 - 0.0047 = 0.0115

# PASO 3: Calcular varianza pooled (combinada)
# ────────────────────────────────────────────────────────────

# Promedio de las dos varianzas
SD_pooled <- sqrt((SD_ALS^2 + SD_Control^2) / 2)
# Ejemplo: sqrt((0.0254^2 + 0.0089^2) / 2)
#        = sqrt((0.000645 + 0.000079) / 2)
#        = sqrt(0.000362)
#        = 0.0190

# PASO 4: Calcular Z-score
# ────────────────────────────────────────────────────────────

Z_score <- Delta / SD_pooled
# Ejemplo: 0.0115 / 0.0190 = 0.605

# Si Z_score = 0.605 → La diferencia es 0.6 SDs
# Si Z_score = 2.0 → La diferencia es 2 SDs (grande)
# Si Z_score = 3.0 → La diferencia es 3 SDs (muy grande)
```

**Interpretación del Z-score:**
```
Z > 3.0: Efecto MUY GRANDE (diferencia > 3 desviaciones estándar)
Z > 2.0: Efecto GRANDE (diferencia > 2 SDs) ← Umbral común
Z > 1.0: Efecto MEDIANO
Z ≈ 0: No hay diferencia
Z < -2.0: Control > ALS (efecto grande en dirección opuesta)
```

**Ventajas del Z-score:**
- ✅ Normaliza por variabilidad (accounts for noise)
- ✅ Independiente de unidades (adimensional)
- ✅ Detecta efectos grandes aunque p-value sea alto
- ✅ Detecta cuando p-value es bajo por sample size grande (no por efecto)

**Relación con p-value:**
```
Z-score y p-value NO siempre correlacionan:

CASO A: Z alto, p alto
  → Efecto grande PERO muy variable
  → Pocas muestras o alta varianza
  → Ejemplo: miR-9-3p (FC 7x, p 0.099)

CASO B: Z bajo, p bajo
  → Efecto pequeño PERO muy consistente
  → Muchas muestras o baja varianza
  → Ejemplo: miR-1-3p (FC 1.3x, p 0.0008)

CASO C: Z alto, p bajo ← IDEAL
  → Efecto grande Y significativo
  → Alta confianza
  → Ejemplo: (ninguno en este dataset)
```

---

## 🎯 EJEMPLO CONCRETO: miR-196a-5p

### **Datos reales:**

```
miR-196a-5p:
  • Tiene 1 SNV: posición 7:GT
  
Muestra por muestra (313 ALS + 102 Control):
  
  ALS muestras:
    Muestra 1: VAF = 0.02
    Muestra 2: VAF = 0.03
    Muestra 3: VAF = 0.01
    ...
    Muestra 313: VAF = 0.02
    
    Mean = 0.0162
    SD = 0.0254
  
  Control muestras:
    Muestra 1: VAF = 0.005
    Muestra 2: VAF = 0.008
    ...
    Muestra 102: VAF = 0.003
    
    Mean = 0.0047
    SD = 0.0089

CÁLCULOS:
  
  1. VAF (promedio):
     Mean_ALS = 0.0162 (1.62%)
  
  2. Fold Change:
     FC = 0.0162 / 0.0047 = 3.44x
     log2(FC) = 1.78
  
  3. p-value:
     wilcox.test(als_vals, ctrl_vals)
     p = 0.0022
     padj (FDR) = 0.0022 (casi no cambia, muy bajo)
  
  4. Z-score:
     Delta = 0.0162 - 0.0047 = 0.0115
     SD_pooled = sqrt((0.0254^2 + 0.0089^2)/2) = 0.0190
     Z = 0.0115 / 0.0190 = 0.605
     
     → Efecto pequeño-mediano en términos de SDs
       (aunque FC es 3.4x, la varianza es alta)
  
  5. Counts:
     Total observaciones (todas las muestras con VAF > 0)
     Ejemplo: 3 observaciones
     (Solo 3 muestras tienen este SNV detectado)
```

---

## 🔍 EJEMPLO CONCRETO: miR-1-3p

### **Datos reales:**

```
miR-1-3p:
  • Tiene SNVs en posiciones: 2:GT, 3:GT, 7:GT
  
PARA CADA MUESTRA:
  
  Muestra ALS_001:
    SNV pos 2: VAF = 0.0005
    SNV pos 3: VAF = 0.0003
    SNV pos 7: VAF = 0.0002
    ──────────────────────────
    TOTAL VAF = 0.0010
  
  Muestra ALS_002:
    SNV pos 2: VAF = 0.0008
    SNV pos 3: VAF = 0.0004
    SNV pos 7: VAF = 0.0001
    ──────────────────────────
    TOTAL VAF = 0.0013
  
  ... (repetir para 313 muestras ALS)
  
  Resultado:
    als_vals = c(0.0010, 0.0013, 0.0009, ...)
    Mean_ALS = 0.000989

PARA CONTROL (mismoroceso):
  
  ctrl_vals = c(0.0007, 0.0008, ...)
  Mean_Control = 0.000758

CÁLCULOS:
  
  1. Fold Change:
     FC = 0.000989 / 0.000758 = 1.30x
     log2(FC) = 0.38
  
  2. p-value:
     wilcox.test(als_vals, ctrl_vals)
     
     ¿Cómo funciona Wilcoxon?
     • Ordena TODOS los valores (ALS + Control) de menor a mayor
     • Asigna ranks (1, 2, 3, ...)
     • Suma ranks de ALS y de Control
     • Si ALS tiene ranks más altos → ALS > Control
     • Calcula probabilidad de que esto sea por azar
     
     p = 0.000784 (0.078%)
     → MUY significativo
  
  3. Z-score:
     Delta = 0.000989 - 0.000758 = 0.000231
     SD_pooled = sqrt((SD_ALS^2 + SD_Control^2)/2)
     
     Supongamos:
       SD_ALS = 0.0015
       SD_Control = 0.0012
       SD_pooled = sqrt((0.0015^2 + 0.0012^2)/2) = 0.00136
     
     Z = 0.000231 / 0.00136 = 0.17
     
     → Efecto PEQUEÑO en términos de SDs
       (aunque p-value es excelente, el efecto es pequeño
        porque la varianza es grande relativo a la diferencia)
  
  4. Counts:
     Total_Counts = 210 observaciones
     → Muchas muestras tienen este miRNA con VAF > 0
     → Por eso p-value es tan bajo (mucho poder estadístico)
```

---

## 📊 COMPARACIÓN: miR-196a vs miR-1

| Métrica | miR-196a-5p | miR-1-3p | ¿Cuál es mejor? |
|---------|-------------|----------|-----------------|
| **FC** | 3.44x | 1.30x | miR-196a ✅ |
| **p-value** | 0.0022 | 0.0008 | miR-1 ✅ |
| **VAF (ALS)** | 0.0162 (1.6%) | 0.00099 (0.1%) | miR-196a ✅ |
| **Counts** | 3 | 210 | miR-1 ✅ |
| **Z-score** | 0.6 | 0.17 | miR-196a ✅ |
| **Posición** | 7 (NO enriched) | 2,3,7 (HAS enriched) | miR-1 ✅ |

**Interpretación:**
- **miR-196a:** Efecto GRANDE pero RARO (3 muestras)
- **miR-1:** Efecto PEQUEÑO pero FRECUENTE (210 observaciones)

**¿Cuál escoger?**
- **Para validar mecanismo:** miR-196a (efecto más claro)
- **Para biomarcador:** miR-1 (más prevalente)
- **IDEAL:** Ambos (diferentes aspectos)

---

## 🔥 POR QUÉ Z-score Y p-value NO SIEMPRE COINCIDEN

### **Factores que afectan p-value:**
1. **Tamaño del efecto** (diferencia entre grupos)
2. **Variabilidad** (SD)
3. **Tamaño de muestra** (N)
4. **Distribución de los datos**

### **Factores que afectan Z-score:**
1. **Tamaño del efecto** (diferencia entre grupos)
2. **Variabilidad** (SD)
3. ~~Tamaño de muestra~~ (NO afecta directamente)

### **Escenarios:**

**ESCENARIO 1: Z alto, p alto**
```
Diferencia grande, pero muy variable

Ejemplo:
  ALS: 0.10, 0.15, 0.00, 0.20, 0.05 (Mean = 0.10, SD = 0.08)
  Control: 0.01, 0.02, 0.00, 0.01 (Mean = 0.01, SD = 0.008)
  
  Delta = 0.10 - 0.01 = 0.09 (grande)
  SD_pooled = 0.06 (alta varianza)
  Z = 0.09 / 0.06 = 1.5 (mediano)
  
  p-value: 0.15 (NO significativo)
  
  ¿Por qué?
    • Pocas muestras (N = 5 vs 4)
    • Alta varianza en ALS
    • Overlap entre grupos
```

**ESCENARIO 2: Z bajo, p bajo**
```
Diferencia pequeña, pero muy consistente

Ejemplo:
  ALS: 0.010, 0.011, 0.010, 0.011, ... (100 muestras)
       Mean = 0.0105, SD = 0.0005
  Control: 0.009, 0.008, 0.009, ... (100 muestras)
           Mean = 0.0085, SD = 0.0005
  
  Delta = 0.0105 - 0.0085 = 0.002 (pequeño)
  SD_pooled = 0.0005 (baja varianza)
  Z = 0.002 / 0.0005 = 4.0 (¡grande!)
  
  p-value: 0.00001 (MUY significativo)
  
  ¿Por qué?
    • Muchas muestras (N = 100 vs 100)
    • Baja varianza (muy consistente)
    • No overlap entre grupos
```

**ESCENARIO 3: Z alto, p bajo** ← **IDEAL**
```
Diferencia grande Y consistente

  → Alto poder estadístico
  → Efecto biológico claro
  → Alta confianza
```

---

## 💡 APLICACIÓN A TU PREGUNTA

### **¿Qué candidatos son mejores?**

**Según Z-score alto (efecto grande):**
```
Top 5 por Z-score (en posiciones enriquecidas 2,3,5):
  → miRNAs con diferencia grande relativa a varianza
  → Efecto biológico claro
  → PERO pueden tener p-value alto si N pequeño
```

**Según p-value bajo (significancia):**
```
Top 5 por p-value:
  → miRNAs con diferencia muy consistente
  → Alta confianza estadística
  → PERO efecto puede ser pequeño
```

**COMBINACIÓN (Z > 2 AND p < 0.05):**
```
Candidatos con:
  → Efecto grande (Z > 2 SDs)
  → Significativo (p < 0.05)
  → Alta VAF
  → Muchos counts
  
→ Los MEJORES candidatos
```

---

## 🎯 RESUMEN DE CÁLCULOS

### **Para CADA miRNA:**

```
1. Identificar SNVs G>T en seed (pos 2-8)
   ↓
2. Para cada muestra, SUMAR VAF de todos sus SNVs
   → Vector ALS: 313 valores
   → Vector Control: 102 valores
   ↓
3. Calcular estadísticas:
   • Mean_ALS, Mean_Control
   • SD_ALS, SD_Control
   • N_Samples_ALS, N_Samples_Control
   • Total_Counts (observaciones con VAF > 0)
   ↓
4. Calcular métricas derivadas:
   • FC = Mean_ALS / Mean_Control
   • p-value = wilcox.test(ALS, Control)
   • Z-score = (Mean_ALS - Mean_Control) / SD_pooled
   • Counts = Total observaciones
   • Prevalencia = % muestras con VAF > 0
   ↓
5. Anotar posiciones afectadas:
   • ¿Tiene G>T en pos 2,3,5? (enriquecidas)
   • ¿O solo en pos 4,6,7,8?
```

---

## ❓ PREGUNTAS PARA VALIDAR QUE ENTENDISTE

**1. Si un miRNA tiene 2 SNVs en seed (pos 2:GT y 5:GT):**

¿Cómo calculamos VAF para muestra ALS_001?
- [ ] A. Promedio de los 2 SNVs
- [ ] B. Máximo de los 2 SNVs
- [ ] C. SUMA de los 2 SNVs ✅ (CORRECTO)

**2. ¿Qué test usamos para p-value?**
- [ ] A. t-test (asume normalidad)
- [ ] B. Wilcoxon rank-sum ✅ (CORRECTO, no-paramétrico)
- [ ] C. Chi-squared

**3. ¿Qué significa Z-score = 3.0?**
- [ ] A. FC de 3.0x
- [ ] B. p-value de 0.003
- [ ] C. Diferencia de 3 desviaciones estándar ✅ (CORRECTO)

**4. Si miR-X tiene p < 0.01 pero FC = 1.1x:**
- [ ] A. Es un buen candidato (p muy bajo)
- [ ] B. NO es buen candidato (FC muy bajo) ✅ (CORRECTO)
- [ ] C. Depende del Z-score

---

## 🚀 SIGUIENTE PASO

**Ahora que entiendes los cálculos, dime:**

1. ¿Tiene sentido el sistema de métricas?
2. ¿Prefieres priorizar Z-score o p-value?
3. ¿VAF y Counts son importantes para tu filtro?
4. ¿Los umbrales actuales (FC > 1.5x, p < 0.05) te parecen correctos?

**Y lo más importante:**

¿Quieres ver las **figuras multi-métricas** para decidir qué candidatos seleccionar? Ya están generadas y abiertas. 🔬

