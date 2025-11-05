# 🌋 REVISIÓN FIGURA 2.3 - VOLCANO PLOT

**Fecha:** 2025-10-24  
**Figura:** Volcano Plot de miRNAs con G>T en seed region

---

## 🎯 **¿QUÉ ES UN VOLCANO PLOT?**

Un **volcano plot** es una visualización estándar en biología para mostrar:
1. **Magnitud del cambio** (eje X)
2. **Significancia estadística** (eje Y)

**Nombre:** Se llama "volcano" porque los puntos significativos se ven como "erupción" en las esquinas superiores.

---

## 📊 **EJES DEL GRÁFICO:**

### **Eje X: log₂(Fold Change)**
```
log₂(FC) = log₂(Mean_ALS / Mean_Control)
```

**Interpretación:**
- **0** = Sin cambio (ALS = Control)
- **> 0** = Mayor en ALS
- **< 0** = Mayor en Control
- **+1** = ALS tiene 2x más que Control (2^1 = 2)
- **-1** = Control tiene 2x más que ALS

**Umbrales comunes:**
- |log₂FC| > 0.58 → Cambio de al menos 1.5x (2^0.58 ≈ 1.5)

### **Eje Y: -log₁₀(p-value ajustado)**
```
-log₁₀(FDR p-value)
```

**Interpretación:**
- **Valores altos** = Más significativo
- **> 1.3** → p < 0.05 (significativo)
- **> 2** → p < 0.01 (muy significativo)
- **> 3** → p < 0.001 (altamente significativo)

---

## 🎨 **CÓDIGO ACTUAL:**

```r
# Para cada miRNA con G>T en seed:
for (mirna in all_seed_gt_mirnas_clean) {
  # Extraer valores ALS y Control
  als_vals <- ... (VAFs de todas las muestras ALS)
  ctrl_vals <- ... (VAFs de todas las muestras Control)
  
  # Calcular Fold Change
  mean_als <- mean(als_vals)
  mean_ctrl <- mean(ctrl_vals)
  fc <- log2(mean_als / mean_ctrl)
  
  # Test estadístico
  test_result <- wilcox.test(als_vals, ctrl_vals)
  pvalue <- test_result$p.value
}

# Ajuste por múltiples comparaciones
padj <- p.adjust(pvalue, method = "fdr")

# Clasificar puntos
Sig <- "NS" (no significativo)
if (log2FC > 0.58 && padj < 0.05) → "ALS" (elevado en ALS)
if (log2FC < -0.58 && padj < 0.05) → "Control" (elevado en Control)
```

---

## 🔍 **¿QUÉ NOS DICE ESTA FIGURA?**

### **Pregunta principal:**
**"¿Qué miRNAs tienen G>T diferencial entre ALS y Control?"**

### **Información que muestra:**

#### **1. miRNAs elevados en ALS (esquina superior derecha):**
- log₂FC > 0.58 (al menos 1.5x más en ALS)
- FDR p < 0.05 (significativo)
- **Color:** Rojo
- **Interpretación:** Estos miRNAs tienen más G>T en ALS

#### **2. miRNAs elevados en Control (esquina superior izquierda):**
- log₂FC < -0.58 (al menos 1.5x más en Control)
- FDR p < 0.05 (significativo)
- **Color:** Azul
- **Interpretación:** Estos miRNAs tienen más G>T en Control

#### **3. miRNAs no significativos (abajo en el centro):**
- No alcanzan umbrales
- **Color:** Gris
- **Interpretación:** Sin diferencia clara entre grupos

---

## 📋 **ELEMENTOS DEL GRÁFICO:**

### **Actual:**
- **Puntos:** Cada miRNA con G>T en seed
- **Colores:** Rojo (ALS), Azul (Control), Gris (NS)
- **Líneas punteadas:**
  - Horizontal: FDR p = 0.05 (umbral de significancia)
  - Verticales: log₂FC = ±0.58 (umbral de magnitud, 1.5x)
- **Etiquetas:** Top 15 miRNAs más significativos

---

## 🤔 **PREGUNTAS DE REVISIÓN:**

### **1. Umbrales:**
- ¿Te parece bien 1.5x (log₂FC = 0.58)?
- ¿O prefieres 2x (log₂FC = 1.0)?

### **2. Colores:**
- **Problema:** Control está en AZUL
- **Pero:** Decidimos que ROJO es para ALS
- ¿Cambiar Control a otro color? (gris oscuro, negro, verde?)

### **3. Etiquetas:**
- Muestra top 15 miRNAs
- ¿Es suficiente?
- ¿O mostrar menos/más?

### **4. Contexto biológico:**
- Basado en Fig 2.1-2.2: **Control > ALS** en burden total
- ¿Esperarías ver más puntos AZULES (Control) en volcano?
- ¿O más ROJOS (ALS)?

### **5. Interpretación:**
- ¿Qué te dice esta figura sobre miRNAs específicos?
- ¿Complementa las figuras anteriores?
- ¿O necesita más contexto?

---

## 💡 **POSIBLES MEJORAS:**

### **Opción 1: Cambiar color de Control**
```r
# De azul a gris oscuro o negro
scale_color_manual(values = c(
  "ALS" = "#D62728",      # Rojo (mantener)
  "Control" = "#2C2C2C",  # Gris oscuro (nuevo)
  "NS" = "gray80"         # Gris claro
))
```

### **Opción 2: Ajustar umbrales**
```r
# Si quieres ser más estricto:
# log2FC threshold: 1.0 (2x fold change)
# FDR threshold: 0.01 (más estricto)
```

### **Opción 3: Agregar información de magnitud**
```r
# Tamaño del punto = magnitud del efecto
# Más grande = más diferencia
geom_point(aes(size = abs(log2FC)), alpha = 0.6)
```

### **Opción 4: Separar por región**
```r
# Volcano separado para seed vs no-seed
# O indicar con forma del punto
```

---

## 🎯 **HALLAZGO ESPERADO vs ACTUAL:**

### **De Figuras 2.1-2.2 sabemos:**
- **Control > ALS** en G>T burden global
- Control: Mean = 3.69
- ALS: Mean = 2.58

### **Entonces en Volcano esperaríamos:**
- **Más puntos AZULES** (Control) → Más miRNAs elevados en Control
- **Menos puntos ROJOS** (ALS)

### **¿Es lo que vemos en la figura?**
- Revisa la figura que acabo de abrir
- ¿Hay más azules o más rojos?
- ¿Coincide con el hallazgo previo?

---

## ✅ **DECISIONES NECESARIAS:**

1. **Color de Control:** ¿Cambiar de azul a gris oscuro?
2. **Umbrales:** ¿Mantener 1.5x o cambiar a 2x?
3. **Etiquetas:** ¿Top 15 está bien?
4. **Interpretación:** ¿Los resultados tienen sentido dado Fig 2.1-2.2?

---

**He abierto FIG_2.3_VOLCANO_CLEAN.png**

**¿Qué observas? ¿Coincide con lo esperado? ¿Necesita cambios?** 🌋

