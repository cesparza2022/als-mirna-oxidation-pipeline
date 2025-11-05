# 📊 MÉTODO IMPLEMENTADO: VOLCANO PLOT

**Fecha:** 2025-10-17 01:25
**Método Seleccionado:** **OPCIÓN B - Promedio por Muestra**

---

## 🎯 MÉTODO IMPLEMENTADO

### **Cada punto del Volcano Plot representa:**
🔴 **UN miRNA completo**

### **Cálculo del Eje X (log2 Fold Change):**

```r
# Para cada miRNA:

# 1. Calcular VAF total de G>T POR MUESTRA
per_sample <- mirna_data %>%
  group_by(Sample_ID, Group) %>%
  summarise(Total_GT_VAF = sum(VAF, na.rm = TRUE))

# Resultado: 415 valores (uno por muestra)
# - 313 valores para ALS (uno por muestra ALS)
# - 102 valores para Control (uno por muestra Control)

# 2. Calcular media por grupo
mean_ALS <- mean(Total_GT_VAF[Group == "ALS"])      # Promedio de 313 muestras
mean_Control <- mean(Total_GT_VAF[Group == "Control"]) # Promedio de 102 muestras

# 3. Fold Change
log2FC <- log2(mean_ALS / mean_Control)
```

### **Cálculo del Eje Y (-log10 p-value):**

```r
# 4. Test estadístico comparando los 415 valores (uno por muestra)
als_sample_vals <- Total_GT_VAF[Group == "ALS"]      # 313 valores
ctrl_sample_vals <- Total_GT_VAF[Group == "Control"] # 102 valores

test_result <- wilcox.test(als_sample_vals, ctrl_sample_vals)
pvalue <- test_result$p.value

# 5. Ajuste por múltiples comparaciones (FDR)
# (Se hace al final con los ~295 tests de todos los miRNAs)
padj <- p.adjust(pvalue, method = "fdr")

# 6. Transformar para el eje Y
neg_log10_padj <- -log10(padj)
```

---

## 📊 QUÉ REPRESENTA CADA VALOR

### **Para el miRNA hsa-miR-378g:**

#### **Paso 1: VAF total por muestra**
```
Muestra ALS_001: suma(VAF de pos 6, 10, 11, 17, 20) = 0.067
Muestra ALS_002: suma(VAF de pos 6, 10, 11, 17, 20) = 0.043
Muestra ALS_003: suma(VAF de pos 6, 10, 11, 17, 20) = 0.004
...
Muestra ALS_313: suma(VAF de pos 6, 10, 11, 17, 20) = X

→ 313 valores (uno por muestra ALS)

Muestra Control_001: suma(VAF de pos 6, 10, 11, 17, 20) = 0.111
Muestra Control_002: suma(VAF de pos 6, 10, 11, 17, 20) = 0.036
...
Muestra Control_102: suma(VAF de pos 6, 10, 11, 17, 20) = Y

→ 102 valores (uno por muestra Control)
```

#### **Paso 2: Promedio por grupo**
```
mean_ALS = mean(313 valores) ≈ 0.0157
mean_Control = mean(102 valores) ≈ 0.0137

log2FC = log2(0.0157 / 0.0137) = +0.197
```

#### **Paso 3: Test estadístico**
```
Wilcoxon test comparando:
  - 313 valores de ALS (uno por muestra)
  - 102 valores de Control (uno por muestra)

p-value = (calculado)
-log10(p-adj) = posición Y en el plot
```

---

## ✅ VENTAJAS DE ESTE MÉTODO

1. **Cada muestra pesa igual:**
   - Muestra con 1 SNV G>T = 1 valor
   - Muestra con 5 SNVs G>T = 1 valor (suma de los 5)
   - **No sesgo** por número de SNVs

2. **Interpretación clara:**
   - "¿Este miRNA tiene mayor CARGA TOTAL de G>T en ALS vs Control?"
   - Cada valor = "Cuánto G>T tiene este miRNA en esta muestra"

3. **Estadísticamente apropiado:**
   - Compara **muestras independientes** entre grupos
   - 313 vs 102 (tamaño de muestra correcto)
   - Test robusto con suficiente poder

4. **Biológicamente relevante:**
   - Responde: "¿Qué miRNAs están más oxidados en ALS?"
   - Considera el **efecto acumulativo** de todas las posiciones G>T

---

## 🔄 DIFERENCIAS CON MÉTODO ANTERIOR

### **Antes (Opción A):**
- 1,217 valores ALS mezclados (313 muestras × ~4-5 SNVs)
- 358 valores Control mezclados
- **Sesgo:** miRNAs con más SNVs contribuyen más al promedio

### **Ahora (Opción B):**
- 313 valores ALS (uno por muestra)
- 102 valores Control (uno por muestra)
- **Sin sesgo:** Cada muestra cuenta igual

### **Impacto en resultados:**
- Fold Changes serán **diferentes** (más o menos según el miRNA)
- P-values serán **diferentes** (pueden cambiar significativamente)
- Algunos miRNAs podrían volverse **más significativos**
- Otros podrían volverse **menos significativos**

---

## 📋 REGISTRO DE IMPLEMENTACIÓN

### **Archivo modificado:**
`GENERATE_ALL_12_FIGURES_CLEAN.R` - Volcano Plot (Figura 2.3)

### **Cambio específico:**
```r
# ANTES:
als_vals <- mirna_data %>% filter(Group == "ALS") %>% pull(VAF)
ctrl_vals <- mirna_data %>% filter(Group == "Control") %>% pull(VAF)

# AHORA:
per_sample <- mirna_data %>%
  group_by(Sample_ID, Group) %>%
  summarise(Total_GT_VAF = sum(VAF, na.rm = TRUE), .groups = "drop")

als_vals <- per_sample %>% filter(Group == "ALS") %>% pull(Total_GT_VAF)
ctrl_vals <- per_sample %>% filter(Group == "Control") %>% pull(Total_GT_VAF)
```

### **Aplicado a:**
- ✅ Figura 2.3 (Volcano Plot)
- ✅ Figura 2.1 (ya usaba este método correctamente)
- ✅ Figura 2.2 (ya usaba este método correctamente)

---

## 🎯 SIGUIENTE PASO

Re-generar Figura 2.3 (Volcano Plot) con el método correcto de promedio por muestra.

---

**Método documentado:** 2025-10-17 01:25
**Implementación:** Opción B - Promedio por muestra
**Justificación:** Estadísticamente apropiado, sin sesgos, interpretable

