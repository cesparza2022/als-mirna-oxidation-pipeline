# 📊 ¿QUÉ NOS DICE LA FIGURA 2.2 (DENSITY PLOT)?

**Fecha:** 2025-10-24  
**Figura:** Distribución de G>T VAF por grupo

---

## 🎯 **PREGUNTA QUE RESPONDE:**

**"¿Cómo se distribuyen los valores de G>T VAF en cada grupo?"**

Esta figura va MÁS ALLÁ del boxplot (Fig 2.1), mostrando la **forma completa** de la distribución.

---

## 📊 **INFORMACIÓN QUE APORTA:**

### **1. FORMA DE LA DISTRIBUCIÓN**

**¿Es normal? ¿Sesgada? ¿Tiene múltiples picos?**

**RESULTADO:**
- **ALS:** Muy sesgada a la derecha (skewness = 5.26)
- **Control:** Casi simétrica (skewness = 0.6)

**Interpretación:**
- ALS tiene una **cola larga** hacia valores altos
- Significa: Mayoría de ALS tiene valores bajos, pero algunos tienen valores MUY altos
- Control es más "normal"

---

### **2. POSICIÓN DE LOS PICOS**

**¿Dónde está el máximo de cada curva?**

**RESULTADO:**
- **ALS:** Pico alrededor de ~2.2 (mediana)
- **Control:** Pico alrededor de ~3.4 (mediana)

**Interpretación:**
- Control tiene el pico más a la **DERECHA** (valores mayores)
- Confirma: Control tiene mayor G>T VAF (hallazgo de Fig 2.1)

---

### **3. DISPERSIÓN (SPREAD)**

**¿Qué tan ancha es cada distribución?**

**RESULTADO:**
- **ALS:** CV = 69.6% (muy variable)
- **Control:** CV = 40.6% (menos variable)

**Interpretación:**
- ALS es **MÁS HETEROGÉNEO** (más disperso)
- Control es más **HOMOGÉNEO** (más consistente)
- Posible explicación: ALS tiene múltiples subtipos o estados de progresión

---

### **4. SUPERPOSICIÓN**

**¿Cuánto se sobreponen las dos distribuciones?**

**RESULTADO:**
- Superposición: ~30%

**Interpretación:**
- Las distribuciones están **MODERADAMENTE SEPARADAS**
- 70% de "separación" indica que los grupos son diferentes
- Pero 30% de overlap indica que hay algunas muestras similares

---

## 🔥 **HALLAZGOS CLAVE:**

### **Hallazgo 1: Control > ALS (confirmado)**
- Control tiene pico más alto (~3.4 vs ~2.2)
- p = 2.5e-13 (altamente significativo)

### **Hallazgo 2: ALS más heterogéneo**
- Variabilidad ALS (69.6%) >> Control (40.6%)
- Distribución ALS muy sesgada (skew = 5.26)
- **Interpretación biológica:** 
  - ¿ALS tiene subgrupos?
  - ¿Diferentes estadios de enfermedad?
  - ¿Respuesta variable al estrés oxidativo?

### **Hallazgo 3: Curtosis extrema en ALS**
- Kurtosis ALS = 52.16 (PICO MUY AGUDO)
- Kurtosis Control = -0.38 (pico normal/plano)
- **Interpretación:**
  - Mayoría de ALS concentrada en valores bajos
  - Pero algunos outliers MUY altos (cola larga)

---

## 🤔 **DIFERENCIA CON BOXPLOT (Fig 2.1 Panel B):**

| Aspecto | Boxplot (Fig 2.1 Panel B) | Density Plot (Fig 2.2) |
|---------|---------------------------|------------------------|
| **Información básica** | Mediana, Q25, Q75, outliers | TODA la forma |
| **Detecta bimodalidad** | ❌ No | ✅ Sí |
| **Detecta asimetría** | ❌ Solo parcialmente | ✅ Claramente |
| **Muestra colas** | ❌ Solo outliers | ✅ Toda la cola |
| **Simplicidad** | ✅ Muy simple | ⚠️ Más complejo |
| **Comparación visual** | ✅ Fácil | ✅ Muy clara |

**CONCLUSIÓN:**
- Boxplot: Resumen simple y claro
- Density: Información detallada de la forma
- **SON COMPLEMENTARIAS** (no redundantes)

---

## 📈 **ESCALAS: LINEAR vs LOG**

### **Análisis del rango:**
- Rango: 0.397 a 22.96 → **58-fold difference**

### **Recomendación técnica:**
⚠️ **LOG SCALE probablemente mejor**
- Rango moderado (10-100 fold)
- Linear funcionaría pero log muestra mejor las diferencias

### **PERO...**
- Si quieres **consistencia con Fig 2.1** → LINEAR
- Si quieres **ver mejor las diferencias** → LOG

**Mi sugerencia:** 
- Usa **LINEAR** para consistencia con Fig 2.1
- Y porque el hallazgo principal (Control > ALS) se ve claro en ambas

---

## 🎯 **INTERPRETACIÓN BIOLÓGICA:**

### **¿Por qué Control > ALS en G>T?**

**Hipótesis 1: Edad**
- ¿Control son más viejos? → Acumulación de mutaciones

**Hipótesis 2: Expresión basal**
- ¿Control expresan más miRNAs? → Mayor oportunidad de mutaciones

**Hipótesis 3: Profundidad técnica**
- ¿Control secuenciados más profundo? → Detectan más variantes raras

**Hipótesis 4: Factor protector en ALS**
- ¿ALS tienen algún mecanismo compensatorio?
- ¿O simplemente menor expresión general?

### **¿Por qué ALS más heterogéneo?**

**Posibilidades:**
1. **Subtipos de ALS** (esporádico, familiar, SOD1+, C9orf72+)
2. **Estadios de progresión** (temprano vs avanzado)
3. **Respuesta variable** al estrés oxidativo
4. **Factores ambientales** diversos

---

## ✅ **CONCLUSIÓN:**

**Esta figura COMPLEMENTA Fig 2.1 Panel B porque:**

1. **Confirma** que Control > ALS
2. **REVELA** que ALS es mucho más heterogéneo
3. **MUESTRA** la forma sesgada de ALS (no es normal)
4. **DETECTA** que hay muestras ALS con valores muy altos (outliers)

**NO es redundante** - Aporta información sobre la **forma** de la distribución que el boxplot no muestra.

---

**He abierto las DOS versiones (linear y log).**

**¿Cuál prefieres para mantener consistencia con Fig 2.1?** 🤔

