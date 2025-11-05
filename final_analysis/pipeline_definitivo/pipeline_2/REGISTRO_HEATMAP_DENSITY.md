# 📊 HEATMAP DE DENSIDAD G>T - REGISTRO

**Fecha:** 2025-10-17 02:35
**Propósito:** Visualizar densidad de SNVs G>T por posición (puente Paso 2 → Paso 3)

---

## 🎯 QUÉ MUESTRA ESTA FIGURA

### **Concepto:**
- **Cada columna** = 1 posición del miRNA (1-22)
- **Cada fila** = 1 SNV único (ordenado por VAF descendente)
- **Color** = Intensidad del VAF promedio
- **Barplot inferior** = Total de SNVs por posición

### **Utilidad:**
- ✅ Identificar **hotspots posicionales** (columnas con más SNVs)
- ✅ Ver **distribución de intensidad** (VAF alto vs bajo)
- ✅ Comparar **densidad ALS vs Control**
- ✅ Detectar **patrones posicionales** no evidentes en otros análisis

---

## 📊 RESULTADOS

### **ALS:**
- **1,774 SNVs únicos** con G>T
- **22 posiciones** con al menos 1 SNV
- **Máximo:** 133 SNVs en una sola posición
- **Archivo:** `FIG_2.13_DENSITY_HEATMAP_ALS.png`

### **Control:**
- **1,237 SNVs únicos** con G>T
- **20 posiciones** con al menos 1 SNV
- **Máximo:** 122 SNVs en una sola posición
- **Archivo:** `FIG_2.14_DENSITY_HEATMAP_CONTROL.png`

### **Combinado:**
- **ALS y Control lado a lado** para comparación directa
- **Archivo:** `FIG_2.15_DENSITY_COMBINED.png` ⭐

---

## 🔬 INTERPRETACIÓN

### **Lo que esperamos ver:**
- **Seed region (2-8):** Posiblemente más SNVs y/o VAF más alto
- **Posiciones no-seed:** Menor densidad
- **Diferencias ALS vs Control:** Patrones de distribución

### **Hotspots a investigar:**
Las posiciones con:
- **Mayor número de SNVs** (barplot alto)
- **VAF más intenso** (colores más rojos/grises)
- **Diferencias entre ALS y Control**

---

## 🎨 MÉTODO DE CONSTRUCCIÓN

### **Proceso:**
```r
# 1. Para cada posición (1-22):
#    - Extraer todos los SNVs G>T en esa posición
#    - Calcular VAF promedio por SNV
#    - Ordenar por VAF (descendente)

# 2. Crear matriz:
#    - Columnas = posiciones
#    - Filas = SNVs (rellenando con NA si necesario)
#    - Cada celda = VAF promedio de ese SNV

# 3. Visualizar:
#    - Heatmap con ComplexHeatmap
#    - Barplot inferior = número de SNVs
#    - Escala de color adaptada al rango de VAF
```

### **Ventajas sobre otros heatmaps:**
- ✅ Muestra **todos los SNVs**, no solo top miRNAs
- ✅ Revela **distribución completa** de intensidad por posición
- ✅ Barplot integrado muestra **carga total** por posición
- ✅ Comparación **ALS vs Control** más visual

---

## 📂 ARCHIVOS GENERADOS

1. `FIG_2.13_DENSITY_HEATMAP_ALS.png` (16×12 in, 300 DPI)
2. `FIG_2.14_DENSITY_HEATMAP_CONTROL.png` (16×12 in, 300 DPI)
3. `FIG_2.15_DENSITY_COMBINED.png` (20×12 in, 300 DPI) ⭐

**Script:** `generate_HEATMAP_DENSITY_GT.R`

---

## 🎯 USO EN EL PIPELINE

### **Posición en el flujo:**
```
PASO 2 (Análisis Comparativo)
├── Figuras 2.1-2.12 (análisis estadístico)
├── Figuras 2.13-2.15 (densidad posicional) ⭐ NUEVAS
└── Transición a PASO 3 (análisis funcional)
```

### **Cuándo generar:**
- **Después** de las 12 figuras principales
- **Antes** del Paso 3
- Útil para identificar posiciones de interés para análisis downstream

### **Parámetros configurables:**
- `max_position`: 22 (default, ajustable)
- `group_colors`: ALS y Control colores
- `vaf_scale`: Escala de colores (puede ajustarse)

---

## 💡 PREGUNTAS QUE RESPONDE

1. **¿Qué posiciones tienen más SNVs G>T?**
   → Ver barplot inferior (altura de barras)

2. **¿Qué posiciones tienen SNVs con VAF más alto?**
   → Ver color de las primeras filas (top del heatmap)

3. **¿Hay diferencias de densidad ALS vs Control?**
   → Comparar barplots y distribución de colores

4. **¿La seed region tiene más SNVs?**
   → Comparar columnas 2-8 vs resto

---

## 🚀 PRÓXIMO PASO

Con estas figuras adicionales, podemos:
1. ✅ Identificar posiciones críticas
2. ✅ Priorizar targets para Paso 3
3. ✅ Ver patrones no detectables en análisis agregados

---

**Registrado:** 2025-10-17 02:35
**Figuras:** 3 (ALS, Control, Combinado)
**Estado:** ✅ COMPLETADO
**Siguiente:** Incorporar al HTML y planificar Paso 3

