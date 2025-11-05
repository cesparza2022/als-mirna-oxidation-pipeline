# 🔥 Re-definición del Paso 1: Dataset Pre-Filtrado para G>T

## ⚠️ HALLAZGO CRÍTICO

**El dataset solo contiene mutaciones G>T** (2,193 filas, todas tipo "GT")

Esto significa que:
- ✅ El dataset YA está filtrado para la firma oxidativa
- ✅ NO podemos comparar G>T vs. otros tipos (no existen en los datos)
- ✅ Las preguntas diagnósticas deben cambiar

---

## 📊 PREGUNTAS DIAGNÓSTICAS APROPIADAS (Solo G>T)

### 🔥 **CRÍTICAS** (Responder en Paso 1)

1. **¿Cómo evoluciona el dataset?**
   - Split vs. Collapse
   - ✅ YA RESPONDIDA: `paso1_evolucion_dataset.png`

2. **¿Cuántos SNVs G>T por muestra?**
   - Distribución, media, outliers
   - Calidad de datos
   - ❌ FALTA (pero YA GENERADA: `FIG1_ANALISIS_POR_MUESTRA.png`)

3. **¿Cuántos Counts G>T por muestra?**
   - Profundidad de secuenciación
   - Relación SNVs vs Counts
   - ❌ FALTA (pero YA GENERADA: `FIG1_ANALISIS_POR_MUESTRA.png`)

4. **¿Cuántos SNVs G>T por posición?**
   - ¿Qué posiciones tienen más mutaciones?
   - ✅ PARCIALMENTE: múltiples versiones redundantes

5. **¿Cuántos Counts G>T por posición?**
   - ¿Las posiciones con más SNVs también tienen más profundidad?
   - ❌ FALTA (pero YA GENERADA: `FIG2_ANALISIS_POR_POSICION.png`)

6. **¿Cuántos miRNAs y familias están afectados?**
   - Total de miRNAs únicos con G>T
   - Familias representadas
   - ⚠️ PARCIAL: hay figuras de "top miRNAs" (demasiado específico)

7. **¿Seed vs. Non-Seed?**
   - Enriquecimiento de G>T en seed
   - Test estadístico
   - ✅ PARCIALMENTE: `02_gt_por_region.png` (mejorar con stats)

8. **¿Distribución de VAFs?**
   - Rango, outliers, categorías
   - ✅ YA RESPONDIDA: múltiples versiones

### ⭐ **IMPORTANTES** (Contexto adicional)

9. **¿G>T por región de los miRNAs?**
   - Seed, 3' UTR, loop, etc.
   - ✅ YA RESPONDIDA

10. **¿Patrones posicionales de G>T?**
    - Posiciones específicas más afectadas
    - ✅ YA RESPONDIDA

---

## ❌ PREGUNTAS QUE **NO PODEMOS** RESPONDER

1. **¿G>T vs. G>A vs. G>C?**
   - NO hay otros tipos en el dataset
   - Dataset pre-filtrado

2. **¿Especificidad de G>T?**
   - NO podemos calcular sin otros tipos
   - Asumir que el pre-filtrado validó esto

3. **¿Comparación entre tipos de mutación?**
   - NO aplicable

---

## 🎯 FIGURAS APROPIADAS PARA PASO 1 (Solo G>T)

### **FIGURA 1: Calidad y Distribución por Muestra** ✅ YA GENERADA
```
Panel A: SNVs G>T por muestra (boxplot único)
Panel B: Counts promedio G>T por muestra (boxplot único)
Panel C: SNVs vs Counts (scatter + tendencia)
```
**Responde**: Calidad de datos, outliers, relación SNVs-Counts

### **FIGURA 2: Distribución Posicional de G>T** ✅ YA GENERADA (pero simplificar)
```
Panel A: SNVs G>T por posición (bar chart simple)
Panel B: Counts G>T por posición (bar chart simple)
Panel C: Fracción G>T en seed vs non-seed (ya no tiene sentido sin otros tipos)
```
**Responde**: Posiciones más afectadas, relación SNVs-Counts posicional

### **FIGURA 3: Caracterización Global** (RE-DISEÑAR)
```
Panel A: Evolución del dataset (split/collapse)
Panel B: N° miRNAs y familias afectadas
Panel C: Distribución de VAFs
Panel D: Seed vs Non-Seed (con estadística)
```
**Responde**: Overview completo del dataset G>T

---

## 🚀 ACCIÓN RECOMENDADA

### **OPCIÓN 1: Usar figuras generadas (con limitaciones)**
- FIG1 está bien (muestra distribución por muestra)
- FIG2 está bien (pero sin comparación de tipos)
- FIG3 NO tiene sentido (no hay G>A ni G>C para comparar)

### **OPCIÓN 2: Re-diseñar FIG3 para contexto apropiado**
- Panel A: Evolución dataset
- Panel B: miRNAs y familias
- Panel C: VAFs
- Panel D: Seed vs Non-seed

### **OPCIÓN 3: Buscar datos originales CON todos los tipos**
- ¿Existe un archivo con G>A, G>C, A>T, etc.?
- Usar ese para comparaciones de especificidad
- Filtrar G>T para análisis posteriores

---

## 🤔 PREGUNTA PARA EL USUARIO

**¿Existe un archivo de datos original que incluya TODOS los tipos de mutación (no solo G>T)?**

Si SÍ → Podemos hacer la comparación G>T vs. otros tipos  
Si NO → Debemos re-diseñar las figuras para enfocarnos solo en G>T

---

¿Qué prefieres?
1. Usar FIG1 y FIG2 (están bien), eliminar FIG3, re-diseñar figura de overview
2. Buscar datos originales con todos los tipos
3. Continuar con las figuras actuales y ajustar el HTML


