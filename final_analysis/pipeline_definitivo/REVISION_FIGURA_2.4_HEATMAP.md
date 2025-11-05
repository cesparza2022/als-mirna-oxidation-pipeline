# 🔥 REVISIÓN FIGURA 2.4 - HEATMAP POSICIONAL (Top 50 miRNAs)

**Fecha:** 2025-10-24

---

## 🎯 **¿QUÉ MUESTRA ESTA FIGURA?**

**Pregunta que responde:**
**"¿Cómo se distribuye el G>T a lo largo de las posiciones del miRNA en los top 50 miRNAs con más G>T?"**

---

## 📊 **ESTRUCTURA:**

### **Formato:**
- **Dos heatmaps lado a lado** (ALS vs Control)
- **Filas:** Top 50 miRNAs (ordenados por burden total de G>T)
- **Columnas:** Posiciones 1-22 del miRNA
- **Color:** Intensidad = Mean VAF en esa posición

---

## 📐 **¿CÓMO SE CONSTRUYE?**

### **PASO 1: Seleccionar top 50 miRNAs**

```r
# De los 301 miRNAs con G>T en seed
# Ordenar por Total G>T VAF (sum de todas las posiciones y muestras)
# Tomar los primeros 50
```

**Criterio de ranking:**
```
miRNA_1: Total VAF = 150 (top 1)
miRNA_2: Total VAF = 120 (top 2)
...
miRNA_50: Total VAF = 15 (top 50)
```

---

### **PASO 2: Para cada miRNA y posición, calcular Mean VAF por grupo**

```r
# Para cada combinación:
# - miRNA (50 miRNAs)
# - Posición (1-22)
# - Grupo (ALS o Control)

# Calcular:
Mean_VAF = promedio(VAF de todas las muestras de ese grupo)
```

**Ejemplo:**
```
let-7a, posición 6, grupo ALS:
   VAF muestra ALS-1: 0.02
   VAF muestra ALS-2: 0.01
   VAF muestra ALS-3: 0.03
   ...
   VAF muestra ALS-313: 0.015
   
   Mean_VAF_ALS_pos6 = promedio(0.02, 0.01, 0.03, ..., 0.015)
                     = 0.018
```

---

### **PASO 3: Crear matriz para cada grupo**

```
MATRIZ ALS:
   ┌─────────┬─────┬─────┬─────┬─────┬─────┬─────┐
   │ miRNA   │ p1  │ p2  │ p3  │ ... │ p22 │
   ├─────────┼─────┼─────┼─────┼─────┼─────┼─────┤
   │ let-7a  │ 0.0 │ 0.02│ 0.01│ ... │ 0.0 │
   │ miR-9   │ 0.01│ 0.0 │ 0.03│ ... │ 0.0 │
   │ ...     │ ... │ ... │ ... │ ... │ ... │
   │ miR-50  │ 0.0 │ 0.0 │ 0.01│ ... │ 0.0 │
   └─────────┴─────┴─────┴─────┴─────┴─────┴─────┘
```

**Mismo proceso para Control**

---

### **PASO 4: Colorear según intensidad**

```r
color = colorRampPalette(c("white", rojo_ALS))(100)

Escala:
   Blanco = 0 (sin mutación)
   Rojo claro = VAF bajo (~0.01)
   Rojo oscuro = VAF alto (~0.05+)
```

---

## 🔍 **¿QUÉ INFORMACIÓN APORTA?**

### **1. Distribución posicional:**

**¿En qué posiciones hay más G>T?**
- Si columnas 2-8 (seed) son más rojas → G>T concentrado en seed
- Si todas las columnas similares → G>T distribuido uniformemente

---

### **2. Comparación ALS vs Control:**

**¿Qué grupo tiene más intensidad?**
- Si heatmap Control más rojo → Control > ALS (consistente con Fig 2.1-2.2)
- Si heatmap ALS más rojo → ALS > Control

---

### **3. Hotspots posicionales:**

**¿Hay posiciones "calientes"?**
- Si columna 6 muy roja en ambos → Posición 6 vulnerable
- Si filas específicas muy rojas → Esos miRNAs muy afectados

---

### **4. Patrones de clustering:**

**¿miRNAs similares se agrupan?**
- Si el clustering agrupa miRNAs de misma familia → Patrón familiar
- Si dispersos → Efecto independiente del tipo de miRNA

---

## 🤔 **PREGUNTAS DE REVISIÓN:**

### **1. ¿Top 50 es apropiado?**
- ¿O mostrar top 30 (más legible)?
- ¿O top 100 (más completo)?

### **2. ¿Dos heatmaps separados o uno combinado?**
- **Actual:** Dos lado a lado (ALS | Control)
- **Alternativa:** Uno combinado con anotación de grupo

### **3. ¿Clustering está activado?**
- Si sí → Filas reordenadas por similitud
- Si no → Filas en orden de ranking (top 1, top 2, ...)

### **4. ¿Escala de color correcta?**
- **Actual:** Blanco → Rojo (para ALS), Blanco → Gris (para Control)
- ¿O usar misma escala para ambos para comparar directamente?

### **5. ¿Se ve la región seed claramente?**
- ¿Necesita marcador visual para posiciones 2-8?
- ¿O se distingue bien?

---

## 💡 **POSIBLES MEJORAS:**

### **Opción 1: Marcar región seed**
```r
# Agregar rectángulo o líneas verticales
# En columnas 2-8
# Para enfatizar seed vs no-seed
```

### **Opción 2: Escala compartida**
```r
# Usar MISMO rango de color para ALS y Control
# Permite comparación directa de intensidad
# Ejemplo: 0 a 0.05 para ambos
```

### **Opción 3: Anotaciones de grupo**
```r
# En vez de dos heatmaps
# Un heatmap con todas las muestras
# Anotación lateral: ALS vs Control
```

### **Opción 4: Reducir a top 30**
```r
# Más legible
# Nombres de miRNA visibles
# Menos saturado
```

---

## 🎨 **ELEMENTOS VISUALES:**

### **Actual:**
- Dos paneles (ALS | Control)
- 50 filas (miRNAs)
- 22 columnas (posiciones)
- Clustering por filas (?)
- Nombres de miRNA en eje Y

### **¿Se ve bien?**
- ¿Nombres legibles?
- ¿Patrones claros?
- ¿Diferencias visibles entre ALS y Control?

---

## 🔥 **RELACIÓN CON OTRAS FIGURAS:**

### **Con Fig 2.1-2.2:**
- Sabemos: Control > ALS globalmente
- Heatmap debería mostrar: Control más rojo que ALS

### **Con Fig 2.3 (Volcano):**
- Sabemos: No hay miRNAs específicos significativos en seed
- Heatmap debería mostrar: Seed relativamente uniforme entre grupos

---

## ✅ **DECISIONES NECESARIAS:**

1. **¿Te gusta como está?**
   - Aprobar y continuar
   - O hacer modificaciones

2. **¿Cambios sugeridos?**
   - Reducir número de miRNAs (top 30)
   - Marcar región seed visualmente
   - Escala compartida para comparación
   - Cambiar formato (combinado en vez de separado)

3. **¿Se ve claramente?**
   - ¿Nombres legibles?
   - ¿Patrones evidentes?

---

**He abierto FIG_2.4_HEATMAP_TOP50_CLEAN.png**

**Revísala y dime:**
- ¿Aprobar como está?
- ¿Qué cambios necesita?
- ¿O continuar con siguiente?

🔥

