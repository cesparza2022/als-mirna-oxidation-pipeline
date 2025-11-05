# 🎯 PLAN FINAL PANEL E - Triple-Metric G-Content Landscape

**Fecha:** 2025-10-24  
**Objetivo:** Crear figura compleja pero completa con 3 métricas de G

---

## 📊 **LAS 3 MÉTRICAS DEFINIDAS:**

### **MÉTRICA 1: G-Content Total (Cuentas totales de miRNAs con G)**
**¿Qué es?**
```r
Para cada posición:
  Sumar TODAS las cuentas (reads) de TODOS los miRNAs que tienen G en esa posición
```

**Ejemplo:**
- Posición 6: 
  - miR-let-7a tiene G en pos 6 → Sumar todas sus cuentas (ej. 50,000 reads)
  - miR-9 tiene G en pos 6 → Sumar todas sus cuentas (ej. 20,000 reads)
  - miR-196a tiene G en pos 6 → Sumar todas sus cuentas (ej. 10,000 reads)
  - **Total pos 6: 80,000 cuentas**

**¿Cómo lo representamos?**
- **Barras (altura)** - Verde oscuro
- Y-axis principal: "Total counts of miRNAs with G at position"

**¿Qué nos dice?**
- Magnitud REAL del substrate (ponderado por abundancia)
- Posiciones con más "material G" disponible

---

### **MÉTRICA 2: Número de cuentas de SNVs G>T por posición**
**¿Qué es?**
```r
Para cada posición:
  Sumar TODAS las cuentas (reads) de mutaciones G>T
```

**Ejemplo:**
- Posición 6:
  - miR-let-7a pos 6:GT → 1,200 cuentas
  - miR-9 pos 6:GT → 500 cuentas
  - miR-196a pos 6:GT → 300 cuentas
  - **Total G>T pos 6: 2,000 cuentas**

**¿Cómo lo representamos?**
- **Bubbles (tamaño)** - Rojo
- Leyenda: "G>T mutation counts"

**¿Qué nos dice?**
- Burden REAL de oxidación (ponderado por abundancia)
- Cuánta oxidación ocurrió en esa posición

---

### **MÉTRICA 3: Número de miRNAs únicos con G en esa posición**
**¿Qué es?**
```r
Para cada posición:
  Contar cuántos miRNAs DIFERENTES tienen G
```

**Ejemplo:**
- Posición 6:
  - miR-let-7a tiene G ✓
  - miR-9 tiene G ✓
  - miR-196a tiene G ✓
  - ... (más miRNAs)
  - **Total: 99 miRNAs únicos**

**¿Cómo lo representamos?**
- **Bubble color (intensidad)** - Gradiente verde a rojo
- O **Texto label** en las barras
- Leyenda: "Number of unique miRNAs"

**¿Qué nos dice?**
- Diversidad del substrate (cuántos miRNAs diferentes)
- NO ponderado por abundancia

---

## 🎨 **DISEÑO VISUAL PROPUESTO:**

```
┌─────────────────────────────────────────────────────────┐
│  E. G-Content Landscape: Substrate and Oxidation Burden │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Y-axis (left):  Total G counts                        │
│  Y-axis (right): G>T mutation counts                   │
│                                                         │
│     ███                                                 │
│     ███ 🔴 (85)  ← Bubble: G>T count (size)           │
│     ███           Number inside: unique miRNAs         │
│     ███ 99        Color: Could show specificity        │
│  ^  ███                                                 │
│  │   │                                                  │
│  │   ├─── Position 6 (example)                         │
│  │                                                      │
│  └────────────────────────────► Position (1-22)        │
│                                                         │
│  🟡 Seed region (2-8) highlighted                      │
└─────────────────────────────────────────────────────────┘
```

**Elementos:**
1. **Barras verdes:** Total cuentas de miRNAs con G (MÉTRICA 1)
2. **Bubbles rojos (tamaño):** Total cuentas G>T (MÉTRICA 2)
3. **Número en bubbles:** miRNAs únicos con G (MÉTRICA 3)
4. **Color de bubbles (opcional):** G>T specificity o intensidad

---

## 💭 **CLARIFICACIONES IMPORTANTES:**

### **Pregunta 1: Para MÉTRICA 1 (G-content total)**
**¿Cómo sabemos qué miRNAs tienen G en cada posición?**

**Opción A (Estimado):**
- Si vemos una mutación G>X (GT, GC, GA) en pos 6 → Sabemos que HAY una G ahí
- Sumamos TODAS las cuentas de ese miRNA (no solo las mutadas)

**Opción B (Conservador):**
- Solo sumamos las cuentas de los SNVs G>X observados
- Subestima el G-content real

**¿Cuál prefieres?** 
- Opción A es más representativa del G-content total
- Opción B es más conservadora pero más precisa con los datos que tenemos

---

### **Pregunta 2: Para las cuentas**
**¿Sumamos todas las columnas de muestras?**

```r
# ¿Esto?
total_counts = rowSums(data[, sample_columns])

# ¿O promedio?
mean_counts = rowMeans(data[, sample_columns])
```

**Recomiendo:** Sumar TODAS (refleja burden total del dataset)

---

### **Pregunta 3: Escalas duales**
**¿Usamos dos ejes Y?**

**Opción A: Dual Y-axis**
- Left Y: Total G counts (barras)
- Right Y: Total G>T counts (bubbles)
- **Problema:** Puede confundir (diferentes escalas)

**Opción B: Single Y-axis con normalización**
- Normalizar ambas métricas a 0-100%
- **Problema:** Pierdes la magnitud real

**Opción C: Keep bubble size para G>T**
- Y-axis: Solo G counts (barras)
- Bubble size: G>T counts (visual, sin eje)
- **Ventaja:** Más claro, menos confuso

**Recomiendo:** Opción C

---

## 🔧 **IMPLEMENTACIÓN TÉCNICA:**

### **Código que voy a usar:**

```r
# MÉTRICA 1: Total G counts por posición
g_counts_by_pos <- data %>%
  filter(str_detect(pos.mut, "^\\d+:G[TCAG]")) %>%  # miRNAs con G
  mutate(Position = as.numeric(str_extract(pos.mut, "^\\d+"))) %>%
  group_by(Position) %>%
  summarise(
    # Sumar TODAS las cuentas de TODAS las muestras
    total_G_counts = sum(across(starts_with("Magen")), na.rm = TRUE),
    .groups = 'drop'
  )

# MÉTRICA 2: Total G>T counts por posición
gt_counts_by_pos <- data %>%
  filter(str_detect(pos.mut, "^\\d+:GT$")) %>%  # Solo G>T
  mutate(Position = as.numeric(str_extract(pos.mut, "^\\d+"))) %>%
  group_by(Position) %>%
  summarise(
    total_GT_counts = sum(across(starts_with("Magen")), na.rm = TRUE),
    .groups = 'drop'
  )

# MÉTRICA 3: miRNAs únicos con G
unique_mirnas_by_pos <- data %>%
  filter(str_detect(pos.mut, "^\\d+:G[TCAG]")) %>%
  mutate(Position = as.numeric(str_extract(pos.mut, "^\\d+"))) %>%
  group_by(Position) %>%
  summarise(
    n_unique_miRNAs = n_distinct(miRNA_name),
    .groups = 'drop'
  )

# Combinar las 3 métricas
panel_e_data <- g_counts_by_pos %>%
  left_join(gt_counts_by_pos, by = "Position") %>%
  left_join(unique_mirnas_by_pos, by = "Position")
```

### **Plot final:**

```r
ggplot(panel_e_data, aes(x = Position)) +
  # BARRAS: Total G counts (substrate)
  geom_col(aes(y = total_G_counts), fill = "#2E7D32", alpha = 0.7) +
  
  # BUBBLES: G>T counts (product)
  geom_point(aes(y = total_G_counts * 0.7,  # Posicionar en 70% de la barra
                 size = total_GT_counts),
             color = "#D62728", fill = "#D62728", 
             alpha = 0.7, shape = 21, stroke = 1.5) +
  
  # LABELS: Número de miRNAs únicos
  geom_text(aes(y = total_G_counts * 0.7, 
                label = n_unique_miRNAs),
            color = "white", fontface = "bold", size = 3) +
  
  # Seed region
  annotate("rect", xmin = 1.5, xmax = 8.5, 
           ymin = 0, ymax = Inf, 
           fill = "yellow", alpha = 0.2) +
  
  scale_size_continuous(name = "G>T Counts", range = c(3, 20))
```

---

## ✅ **CONFIRMACIÓN FINAL:**

**Antes de generar el código final, confirma:**

1. ✅ **MÉTRICA 1:** Total cuentas de miRNAs con G (sumando todas las muestras) → Barras
2. ✅ **MÉTRICA 2:** Total cuentas de SNVs G>T → Bubble size
3. ✅ **MÉTRICA 3:** Número de miRNAs únicos con G → Número dentro del bubble

**¿Esto es correcto? ¿O quieres ajustar algo?**

Si confirmas, genero el código y la figura final. 🚀
