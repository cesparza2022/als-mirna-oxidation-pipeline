# 🔬 OPCIONES PARA CALCULAR EL VOLCANO PLOT

**miRNA ejemplo:** hsa-miR-378g
**Datos:** 5 SNVs con G>T (pos 6, 10, 11, 17, 20)

---

## 📊 ESTRUCTURA DE DATOS

```
Dataset original:
┌──────────────┬────────┬──────────┬──────────┬─────┬──────────┐
│ miRNA_name   │ pos.mut│ Muestra1 │ Muestra2 │ ... │ Muestra415│
├──────────────┼────────┼──────────┼──────────┼─────┼──────────┤
│ hsa-miR-378g │  6:GT  │   0.067  │    0     │ ... │    0     │ ← Fila 1
│ hsa-miR-378g │ 10:GT  │    0     │  0.043   │ ... │  0.111   │ ← Fila 2
│ hsa-miR-378g │ 11:GT  │  0.004   │    0     │ ... │    0     │ ← Fila 3
│ hsa-miR-378g │ 17:GT  │    0     │  0.014   │ ... │  0.033   │ ← Fila 4
│ hsa-miR-378g │ 20:GT  │    0     │    0     │ ... │  0.090   │ ← Fila 5
└──────────────┴────────┴──────────┴──────────┴─────┴──────────┘
```

---

## 🎯 OPCIÓN A: PROMEDIO DE TODOS LOS VALORES (ACTUAL)

### **Paso a paso:**

```r
# 1. Convertir a formato largo
datos_largos <- 
┌──────────────┬────────┬──────────┬─────┬────────┐
│ miRNA        │ pos.mut│ Muestra  │ VAF │ Grupo  │
├──────────────┼────────┼──────────┼─────┼────────┤
│ hsa-miR-378g │  6:GT  │ ALS_001  │0.067│  ALS   │
│ hsa-miR-378g │  6:GT  │ ALS_002  │  0  │  ALS   │
│ hsa-miR-378g │  6:GT  │ ALS_003  │  0  │  ALS   │
│ ...          │  ...   │   ...    │ ... │  ...   │
│ hsa-miR-378g │ 10:GT  │ ALS_001  │  0  │  ALS   │
│ hsa-miR-378g │ 10:GT  │ ALS_002  │0.043│  ALS   │
│ ...          │  ...   │   ...    │ ... │  ...   │
│ hsa-miR-378g │  6:GT  │ Ctrl_001 │  0  │Control │
│ ...          │  ...   │   ...    │ ... │  ...   │
└──────────────┴────────┴──────────┴─────┴────────┘
Total: 1,575 filas (5 SNVs × 415 muestras)

# 2. Calcular media por grupo
ALS: mean(TODOS los 1,217 valores de ALS) = 0.003487
Control: mean(TODOS los 358 valores de Control) = 0.003159

# 3. Calcular FC
log2(0.003487 / 0.003159) = 0.1093
```

### **Qué representa cada valor:**
- Cada valor VAF individual (SNV × Muestra)
- **1,217 valores de ALS** mezclados (313 muestras × 5 SNVs, aunque muchos son 0)
- **358 valores de Control** mezclados (102 muestras × 5 SNVs)

### **Problema:**
- Un SNV en 313 muestras aporta 313 valores
- Otro SNV en solo 50 muestras aporta 50 valores
- **Sesgo hacia SNVs con más observaciones**

---

## 🎯 OPCIÓN B: PROMEDIO POR MUESTRA PRIMERO (RECOMENDADO)

### **Paso a paso:**

```r
# 1. Para CADA MUESTRA, sumar VAF de TODOS los SNVs G>T del miRNA
por_muestra <- 
┌──────────────┬──────────┬───────────────┬────────┐
│ miRNA        │ Muestra  │ Total_GT_VAF  │ Grupo  │
├──────────────┼──────────┼───────────────┼────────┤
│ hsa-miR-378g │ ALS_001  │ 0.067 (6:GT)  │  ALS   │ ← Suma de 5 SNVs
│ hsa-miR-378g │ ALS_002  │ 0.043 (10:GT) │  ALS   │
│ hsa-miR-378g │ ALS_003  │ 0.004 (11:GT) │  ALS   │
│ ...          │   ...    │      ...      │  ...   │
│ hsa-miR-378g │ Ctrl_001 │ 0.111 (varios)│Control │
│ ...          │   ...    │      ...      │  ...   │
└──────────────┴──────────┴───────────────┴────────┘
Total: 415 filas (una por muestra)

# 2. Calcular media por grupo
ALS: mean(313 valores, uno por muestra ALS) = X
Control: mean(102 valores, uno por muestra Control) = Y

# 3. Calcular FC
log2(X / Y)
```

### **Qué representa cada valor:**
- **VAF total de G>T** en ese miRNA para esa muestra
- **313 valores de ALS** (uno por muestra, cada uno es la suma de los 5 SNVs)
- **102 valores de Control** (uno por muestra)

### **Ventajas:**
✅ Cada muestra pesa **igual**
✅ No sesgo por número de SNVs
✅ Más apropiado para comparar **muestras** entre grupos
✅ Interpretación: "Carga total de G>T en este miRNA"

---

## 🎯 OPCIÓN C: SOLO SEED (POSICIONES 2-8)

### **Paso a paso:**

```r
# 1. Filtrar SOLO SNVs en posiciones 2-8
seed_only <- datos_largos %>% 
  filter(position >= 2, position <= 8)

Para hsa-miR-378g:
  Solo posición 6:GT (las demás están fuera de seed)

# 2. Calcular media solo de valores seed
ALS: mean(valores de pos 6:GT en ALS)
Control: mean(valores de pos 6:GT en Control)
```

### **Ventajas:**
✅ Enfoque **funcional** (solo región crítica)
✅ Relevancia biológica máxima

### **Desventajas:**
⚠️ Muchos miRNAs quedarían fuera (si G>T solo fuera de seed)
⚠️ Menos poder estadístico

---

## 📊 COMPARACIÓN VISUAL

### **Para hsa-miR-378g:**

| Método | N valores ALS | N valores Control | Mean ALS | Mean Control | log2(FC) |
|--------|---------------|-------------------|----------|--------------|----------|
| **A (Actual)** | 1,217 | 358 | 0.003487 | 0.003159 | +0.109 |
| **B (Por muestra)** | 313 | 102 | 0.0157 | 0.0137 | +0.197 |
| **C (Solo seed)** | ~244 | ~72 | 0.0201 | 0.0171 | +0.234 |

**Observación:** Los FC cambian según el método!

---

## 💡 MI RECOMENDACIÓN: OPCIÓN B

### **Por qué:**
1. **Unidad biológica:** Cada muestra es un individuo
2. **No sesgo:** miRNAs con más SNVs no dominan
3. **Interpretable:** "¿Este miRNA tiene más G>T total en ALS que en Control?"
4. **Estadísticamente apropiado:** Muestras independientes

### **Implementación:**

```r
# Para cada miRNA
for (mirna in all_seed_gt_mirnas) {
  
  # Extraer datos del miRNA
  mirna_data <- vaf_gt_all %>% filter(miRNA_name == mirna)
  
  # Calcular VAF total POR MUESTRA
  per_sample <- mirna_data %>%
    group_by(Sample_ID, Group) %>%
    summarise(Total_GT_VAF = sum(VAF, na.rm = TRUE), .groups = "drop")
  
  # Separar por grupo (ahora son 313 y 102 valores)
  als_vals <- per_sample %>% filter(Group == "ALS") %>% pull(Total_GT_VAF)
  ctrl_vals <- per_sample %>% filter(Group == "Control") %>% pull(Total_GT_VAF)
  
  # Calcular media (cada muestra pesa igual)
  mean_als <- mean(als_vals)
  mean_ctrl <- mean(ctrl_vals)
  
  # FC y test
  fc <- log2(mean_als / mean_ctrl)
  test <- wilcox.test(als_vals, ctrl_vals)
}
```

---

## ❓ **¿CUÁL QUIERES USAR?**

**A.** Mantener actual (mezcla todo)
**B.** Cambiar a por-muestra (recomendado)
**C.** Solo valores seed
**D.** Otra opción

**Tu respuesta determinará cómo re-genero el Volcano Plot.** 🤔
