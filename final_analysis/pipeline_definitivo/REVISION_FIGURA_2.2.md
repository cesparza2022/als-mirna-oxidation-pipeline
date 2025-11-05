# 📊 REVISIÓN FIGURA 2.2 - VAF DISTRIBUTIONS

**Fecha:** 2025-10-24  
**Estado:** Revisión para aprobación

---

## 🎯 **FIGURA 2.2: DISTRIBUCIONES DE G>T VAF**

### **Composición actual:**

**Panel A: Violin Plot**
- Muestra distribución de Total G>T VAF por grupo
- Incluye boxplot superpuesto
- Escala: LOG10 (y-axis)
- Estadística: Comparación ALS vs Control

**Panel B: Density Plot**
- Distribución como curvas de densidad
- Permite comparar formas de las distribuciones
- Escala: LOG10 (x-axis)
- Transparencia para ver superposición

---

## 📋 **CÓDIGO ACTUAL:**

```r
# Total G>T VAF por muestra
vaf_summary <- vaf_gt_all %>%
  group_by(Sample_ID, Group) %>%
  summarise(Total_GT_VAF = sum(VAF, na.rm = TRUE), .groups = "drop")

# Panel A: Violin + Boxplot
p2a <- ggplot(vaf_summary, aes(x = Group, y = Total_GT_VAF, fill = Group)) +
  geom_violin(alpha = 0.7) + 
  geom_boxplot(width = 0.1, alpha = 0.5) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  scale_y_log10() + 
  labs(title = "A. Violin Plot", y = "Total G>T VAF") +
  theme_professional + 
  theme(legend.position = "none")

# Panel B: Density
p2b <- ggplot(vaf_summary, aes(x = Total_GT_VAF, fill = Group)) +
  geom_density(alpha = 0.5) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  scale_x_log10() + 
  labs(title = "B. Density", x = "Total G>T VAF") +
  theme_professional

# Combinar
fig_2_2 <- p2a | p2b
```

---

## 🤔 **PREGUNTAS PARA REVISAR:**

### **1. Escalas:**
- ¿Mantener LOG scale en ambos paneles?
- ¿O cambiar a linear (como decidiste para Fig 2.1)?

### **2. Contenido:**
- ¿Te gusta la combinación Violin + Density?
- ¿O prefieres otras visualizaciones? (histogram, ridgeline, etc.)

### **3. Estadísticas:**
- ¿Agregar p-value al Violin plot?
- ¿Agregar medias/medianas marcadas?

### **4. Estética:**
- ¿Los títulos son claros?
- ¿Los colores son correctos (rojo para ALS)?
- ¿Falta alguna anotación?

### **5. Interpretación:**
- ¿Qué pregunta responde esta figura?
- ¿Es complementaria a la 2.1 o redundante?

---

## 💡 **OPCIONES DE MEJORA:**

### **Opción 1: Agregar estadísticas**
```r
# Agregar p-value y efecto
test_result <- wilcox.test(Total_GT_VAF ~ Group, data = vaf_summary)
p_text <- format.pval(test_result$p.value, digits = 3)

p2a <- p2a + 
  annotate("text", x = 1.5, y = ..., 
           label = paste0("p = ", p_text), 
           size = 4)
```

### **Opción 2: Cambiar a linear scale**
```r
# Quitar scale_y_log10() y scale_x_log10()
# Para consistencia con Fig 2.1
```

### **Opción 3: Agregar más información**
```r
# Marcar medias con puntos
# Agregar líneas de referencia
# Mostrar outliers explícitamente
```

### **Opción 4: Simplificar**
```r
# ¿Solo violin plot?
# ¿Solo density?
# ¿Eliminar uno de los paneles?
```

---

## 🎯 **RELACIÓN CON FIGURA 2.1:**

### **Figura 2.1 (la que acabamos de aprobar):**
- Muestra 3 métricas: Total VAF, G>T VAF, G>T Ratio
- Formato: Boxplots simples
- Escala: Linear (decidido)

### **Figura 2.2 (actual):**
- Muestra solo: G>T VAF
- Formato: Violin + Density
- Escala: LOG (inconsistente con 2.1)

### **¿Hay redundancia?**
- 2.1 Panel B ya muestra G>T VAF como boxplot
- 2.2 Panel A es violin plot del mismo dato
- **¿Son complementarias o duplicadas?**

---

## 🔍 **SUGERENCIAS:**

### **Opción A: Mantener pero mejorar**
- Cambiar a linear scale (consistencia con 2.1)
- Agregar p-value
- Justificar: "Las distribuciones completas aportan info que boxplot no muestra"

### **Opción B: Reemplazar con algo nuevo**
- En vez de repetir G>T VAF, mostrar otra cosa
- Ejemplos:
  - Distribución por miRNA específico
  - Distribución por posición
  - Variabilidad intra-grupo

### **Opción C: Eliminar**
- Si es redundante con 2.1, eliminar
- Pasar directo a Fig 2.3 (Volcano)

---

## ❓ **TUS DECISIONES:**

**Por favor responde:**

1. **¿Te gusta la figura como está?**
   - ✅ Sí, aprobar y continuar
   - ⚠️ Necesita mejoras (¿cuáles?)
   - ❌ Eliminar o reemplazar

2. **Si te gusta, ¿cambiar a linear scale?**
   - Para consistencia con Fig 2.1

3. **¿Agregar estadísticas explícitas?**
   - p-value en el gráfico
   - Medias/medianas marcadas

4. **¿Es redundante con Fig 2.1 Panel B?**
   - ¿O aporta información adicional valiosa?

---

**He abierto la figura para que la revises.**

**Dime qué decides y continuamos con la siguiente!** 🚀

