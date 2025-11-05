# 🔍 REVISIÓN CRÍTICA DETALLADA - PANEL 2.1 (VAF Global)

**Panel:** Figure 2.1 - Global VAF Comparison (ALS vs Control)  
**Archivo:** `FIG_2.1_VAF_GLOBAL_CLEAN.png`  
**Script:** `generate_FIGURA_2.1_EJEMPLO.R`  
**Fecha de revisión:** 2025-10-24

---

## 📊 **¿QUÉ ES ESTE PANEL?**

**Propósito:** Comparar la carga global de VAF entre ALS y Control

**Diseño:** 3 sub-paneles lado a lado (A | B | C)

---

## 🔬 **ANÁLISIS DE LÓGICA - PANEL POR PANEL**

### **PANEL A: Total VAF per Sample**

#### **Cálculo (Líneas 38-48):**
```r
vaf_total <- data %>%
  pivot_longer(cols = sample_cols, names_to = "Sample_ID", values_to = "VAF") %>%
  group_by(Sample_ID) %>%
  summarise(Total_VAF = sum(VAF, na.rm = TRUE))
```

**¿Qué calcula?**
- Para cada muestra: Suma TODOS los valores de VAF de TODOS los SNVs

**Interpretación:**
- "Sample X tiene 0.5 de VAF total"
- Esto significa: La suma de todas las frecuencias de variantes en esa muestra

**✅ LÓGICA CORRECTA:**
- Representa la "carga total de mutaciones" en la muestra
- Valores más altos = Más mutaciones detectadas

**❓ PREGUNTA CRÍTICA:**
- ¿Está ponderado por la abundancia del miRNA?
- ¿O solo suma VAF sin considerar expresión?

**Respuesta:** Solo suma VAF (no pondera por abundancia)
- VAF = count_variant / count_total_miRNA
- Es una proporción, ya está "normalizada" por miRNA

**✅ ESTO ES CORRECTO** para comparar burden de mutaciones

---

#### **Test Estadístico (Líneas 90):**
```r
test_total <- wilcox.test(Total_VAF ~ Group, data = combined_data)
```

**¿Qué pregunta responde?**
- ¿Las muestras ALS tienen diferente carga total de VAF que Control?

**✅ CORRECTO:**
- Wilcoxon es apropiado (no asume normalidad)
- Compara distribuciones de muestras entre grupos

**⚠️ CONSIDERACIÓN:**
- ¿Hay confounders? (edad, sexo, batch)
- No se controla por variables confusoras

---

#### **Visualización (Líneas 100-114):**
```r
geom_boxplot() +
geom_jitter() +
scale_y_log10()
```

**Elementos:**
- Boxplot: Muestra mediana, Q1, Q3, outliers
- Jitter: Muestra puntos individuales (cada muestra)
- Log scale: Para manejar rango amplio de valores

**✅ VISUALIZACIÓN APROPIADA:**
- Boxplot + jitter es estándar para este tipo de comparación
- Log scale es razonable si hay outliers altos

**❓ PREGUNTA:**
- ¿La escala log es necesaria?
- Si la mayoría de valores están en rango estrecho, linear scale podría ser mejor

---

### **PANEL B: G>T VAF per Sample**

#### **Cálculo (Líneas 51-60):**
```r
vaf_gt <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%  # SOLO G>T
  pivot_longer(cols = sample_cols, names_to = "Sample_ID", values_to = "VAF") %>%
  group_by(Sample_ID) %>%
  summarise(GT_VAF = sum(VAF, na.rm = TRUE))
```

**¿Qué calcula?**
- Para cada muestra: Suma solo los VAF de mutaciones G>T

**✅ LÓGICA CORRECTA:**
- Filtra primero por ":GT$" (solo G>T)
- Suma por muestra
- Representa "carga específica de oxidación"

**💡 EXCELENTE:**
- Separa G>T de otras mutaciones
- Permite comparar oxidation burden específicamente

---

#### **Relación con Panel A:**
```r
GT_VAF ≤ Total_VAF  (siempre)
```

**✅ COHERENCIA:**
- Panel A = TOTAL (todas las mutaciones)
- Panel B = SUBSET (solo G>T)
- Panel B debería ser ≤ Panel A siempre

---

### **PANEL C: G>T Fraction (G>T / Total)**

#### **Cálculo (Líneas 63-68):**
```r
combined_data <- vaf_total %>%
  left_join(vaf_gt) %>%
  mutate(GT_Ratio = GT_VAF / Total_VAF)
```

**¿Qué calcula?**
- Proporción de VAF que es G>T vs total VAF
- Ejemplo: 0.8 = 80% del burden de mutaciones es G>T

**✅ LÓGICA CORRECTA:**
- Normaliza por el total de mutaciones
- Muestra "especificidad" de G>T en cada muestra

**💡 MUY ÚTIL:**
- Si ALS tiene mayor GT_Ratio → Oxidación es más específica en ALS
- Si similar → Oxidación es general, no específica de enfermedad

---

## 🎯 **COHERENCIA ENTRE LOS 3 PANELES**

### **Relaciones lógicas:**

```
Panel A (Total VAF) = Panel B (GT VAF) + Other_VAF
Panel C (GT Ratio) = Panel B / Panel A
```

**✅ MATEMÁTICAMENTE COHERENTE:**
- Los 3 paneles están relacionados
- No son independientes, son complementarios

### **Narrativa:**
1. **Panel A:** ¿Cuánta mutación hay en total? (burden global)
2. **Panel B:** ¿Cuánta de esa es G>T? (burden oxidativo)
3. **Panel C:** ¿Qué proporción es G>T? (especificidad)

**✅ NARRATIVA CLARA Y PROGRESIVA**

---

## 📊 **ANÁLISIS ESTADÍSTICO**

### **Test usado: Wilcoxon (Líneas 90-92)**

**✅ APROPIADO PORQUE:**
- No paramétrico (no asume normalidad)
- Robusto a outliers
- Apropiado para datos biológicos

**⚠️ LIMITACIONES:**
- No controla por confounders (edad, sexo, batch)
- Asume independencia de muestras (¿hay muestras longitudinales?)
- Comparación univariada (una métrica a la vez)

---

## 🎨 **ANÁLISIS DE ESTILO**

### **Colores (Líneas 10-11):**
```r
COLOR_ALS <- "#D62728"      # Rojo
COLOR_CONTROL <- "#666666"  # Gris
```

**✅ EXCELENTE ELECCIÓN:**
- Rojo para ALS (indica "problema/enfermedad")
- Gris para Control (neutral)
- Consistente con convenciones científicas

---

### **Escala Y: Log10 (Líneas 104, 122)**
```r
scale_y_log10(labels = scales::comma)
```

**❓ PREGUNTA CRÍTICA:**
- ¿Es necesaria la escala log?
- ¿O es porque hay outliers extremos?

**Para decidir:**
- Si la mayoría de valores están en rango 0.001-0.1 → Linear está bien
- Si hay valores de 0.0001 a 10 → Log es necesario

**Recomendación:** Revisar la distribución en la figura

---

### **Outliers: outlier.shape = NA (Líneas 101, 119)**
```r
geom_boxplot(outlier.shape = NA)
```

**⚠️ PROBLEMA POTENCIAL:**
- Oculta los outliers del boxplot
- Pero los muestra con jitter (línea siguiente)

**✅ ESTO ES CORRECTO:**
- Evita duplicar outliers (boxplot + jitter)
- Los outliers siguen visibles en el jitter

---

### **Anotación de significancia (Líneas 112-114, 130-132):**
```r
annotate("text", ..., 
         label = ifelse(test$p.value < 0.05, "***", "ns"))
```

**✅ BUENA PRÁCTICA:**
- Muestra significancia visual (asteriscos)
- Estándar en publicaciones

**⚠️ POSIBLE MEJORA:**
- Usar escala de asteriscos: * p<0.05, ** p<0.01, *** p<0.001
- Actualmente solo usa *** para cualquier p<0.05

---

## ❌ **PROBLEMAS IDENTIFICADOS**

### **PROBLEMA 1: Ruta de datos hardcodeada (Línea 32)**
```r
data <- read.csv("../../../final_analysis/processed_data/final_processed_data.csv")
```

**Problema:**
- ❌ Ruta absoluta/relativa hardcodeada
- ❌ No funciona si se mueve el script
- ❌ No es genérico

**Solución:** Usar variable de configuración

---

### **PROBLEMA 2: No reporta tamaño de efecto**

**Test actual:** Solo p-value (Wilcoxon)

**Falta:**
- Effect size (Cohen's d o similar)
- Difference in medians
- Confidence intervals

**Solución:** Añadir:
```r
# Effect size
cohens_d <- (mean(als) - mean(ctrl)) / pooled_sd
```

---

### **PROBLEMA 3: No valida supuestos**

**No verifica:**
- Distribución de datos (normalidad)
- Homogeneidad de varianzas
- Outliers extremos

**Solución:** Añadir checks o justificar por qué Wilcoxon es apropiado

---

## ✅ **LO QUE ESTÁ MUY BIEN**

1. **✅ Cálculo claro y correcto**
   - Suma VAF por muestra (lógica apropiada)
   - Filtra G>T correctamente (regex ":GT$")
   - Calcula ratio G>T/Total correctamente

2. **✅ Test estadístico apropiado**
   - Wilcoxon para datos no-normales
   - Comparación directa ALS vs Control

3. **✅ Visualización profesional**
   - Boxplot + jitter (muestra distribución + puntos)
   - Colores consistentes (rojo ALS, gris Control)
   - Significancia anotada (asteriscos)

4. **✅ Coherencia entre paneles**
   - A, B, C están relacionados matemáticamente
   - Narrativa progresiva (total → G>T → ratio)

5. **✅ Escala log apropiada** (si hay rango amplio)

---

## 🤔 **PREGUNTAS PARA DISCUTIR**

### **1. Sobre el cálculo:**
**¿El "Total VAF" debe incluir TODOS los tipos de mutación o solo G>X?**
- Actualmente: Incluye todas (12 tipos)
- Alternativa: Solo mutaciones de G (GT, GC, GA)

**Mi opinión:** Está bien incluir todas (da contexto general)

---

### **2. Sobre la escala:**
**¿La escala log es necesaria?**
- Depende de la distribución de valores
- Necesito ver la figura para decidir

---

### **3. Sobre la interpretación:**
**¿Qué esperamos ver?**

**Hipótesis 1:** ALS > Control en Total VAF
- Indicaría más mutaciones en general

**Hipótesis 2:** ALS > Control en G>T VAF
- Indicaría específicamente más oxidación

**Hipótesis 3:** ALS > Control en GT_Ratio
- Indicaría que la PROPORCIÓN de oxidación es mayor (no solo burden)

**¿Cuál es la hipótesis biológica?**

---

### **4. Sobre confounders:**
**¿Hay variables que deberíamos controlar?**
- Edad (¿ALS son mayores?)
- Sexo (¿distribución diferente?)
- Batch (¿efectos técnicos?)
- Tiempo de almacenamiento de muestras

**Actualmente:** No se controlan

---

## 🎯 **RECOMENDACIONES**

### **ALTA PRIORIDAD:**

1. **✅ Mantener como está** - La lógica es correcta

2. **Añadir effect size:**
```r
# Después del test
effect_size <- median(als_values) / median(ctrl_values)
subtitle = paste0("Wilcoxon p = ..., Fold = ", round(effect_size, 2), "x")
```

3. **Verificar necesidad de log scale:**
   - Ver distribución de valores
   - Si rango es <100x, usar linear

---

### **MEDIA PRIORIDAD:**

4. **Mejorar anotación de significancia:**
```r
sig_label <- case_when(
  p < 0.001 ~ "***",
  p < 0.01 ~ "**",
  p < 0.05 ~ "*",
  TRUE ~ "ns"
)
```

5. **Añadir N de muestras en eje X:**
```r
x_labels <- c(paste0("ALS\n(n=", n_als, ")"),
              paste0("Control\n(n=", n_ctrl, ")"))
```

---

### **BAJA PRIORIDAD:**

6. **Añadir tabla de stats:**
   - Mean, Median, SD para cada grupo
   - Debajo de los boxplots

7. **Control por confounders:**
   - Análisis estratificado
   - Regresión múltiple

---

## 💡 **INTERPRETACIÓN ESPERADA**

### **Si vemos en la figura:**

**Panel A: ALS > Control (Total VAF)**
- Interpretación: ALS tiene más mutaciones en general
- Podría ser: Mayor daño celular global

**Panel B: ALS > Control (G>T VAF)**
- Interpretación: ALS tiene específicamente más G>T
- Sugiere: Mayor estrés oxidativo en ALS

**Panel C: ALS > Control (GT Ratio)**
- Interpretación: Mayor PROPORCIÓN de G>T en ALS
- **MÁS FUERTE:** Indica selectividad, no solo burden
- Sugiere: Oxidación es proceso específico aumentado en ALS

**Panel C: ALS = Control (GT Ratio) PERO Panel B: ALS > Control**
- Interpretación: ALS tiene más mutaciones (Panel A) pero misma proporción G>T
- Sugiere: Daño global aumentado, pero no selectividad oxidativa

---

## 🔍 **PREGUNTAS ESPECÍFICAS PARA REVISAR LA FIGURA**

Cuando veas la figura `FIG_2.1_VAF_GLOBAL_CLEAN.png`, responde:

### **1. Escala:**
- ¿La escala log es necesaria o confunde?
- ¿Los valores van de 0.001 a 1.0 o más?

### **2. Distribución:**
- ¿Las distribuciones de ALS y Control se solapan mucho?
- ¿O están claramente separadas?

### **3. Significancia:**
- ¿Qué paneles muestran ***?
- ¿A, B, y C todos significativos?
- ¿O solo algunos?

### **4. Outliers:**
- ¿Hay outliers extremos?
- ¿Son biológicamente plausibles o artefactos?

### **5. Interpretación:**
- **Panel A vs Panel B:** ¿Cuál muestra mayor diferencia?
  - Si A > B → Diferencia es global (no solo G>T)
  - Si B > A → Diferencia es específica de G>T
- **Panel C:** ¿GT_Ratio es diferente?
  - Si SÍ → Especificidad oxidativa diferente
  - Si NO → Solo burden total diferente

---

## 📋 **CHECKLIST DE VALIDACIÓN**

**Antes de aceptar Panel 2.1, verificar:**

- [ ] Las 3 métricas están bien calculadas (Total, G>T, Ratio)
- [ ] Test estadístico apropiado (Wilcoxon)
- [ ] P-values reportados correctamente
- [ ] Escala apropiada (log vs linear)
- [ ] Colores consistentes (rojo ALS, gris Control)
- [ ] Significancia anotada (asteriscos)
- [ ] Jitter no oculta boxplot
- [ ] Títulos claros
- [ ] No hay duplicación con otras figuras

---

## 🎯 **DECISIÓN FINAL**

### **¿Este panel es necesario?**

**SÍ** ✅ **PORQUE:**
1. Responde pregunta fundamental: ¿ALS ≠ Control?
2. Muestra burden global Y específico (G>T)
3. Calcula especificidad (ratio)
4. Es la base para justificar análisis más detallados

### **¿Está bien hecho?**

**MAYORMENTE SÍ** ✅ **PERO:**
- Lógica correcta
- Código limpio
- Visualización apropiada

**MEJORABLE:**
- Añadir effect size
- Verificar necesidad de log scale
- Considerar confounders (futuro)

---

## 📊 **PRÓXIMOS PASOS**

1. **Revisar la figura visual** (¿se ve bien?)
2. **Verificar valores** (¿tiene sentido?)
3. **Confirmar interpretación** (¿qué nos dice?)
4. **Decidir ajustes** (¿cambiar algo?)
5. **Pasar a Panel 2.2** (Distribuciones)

---

**¿Has visto la figura 2.1? ¿Qué observas?**  
**¿Procedemos con este panel o necesita correcciones?** 🔍

