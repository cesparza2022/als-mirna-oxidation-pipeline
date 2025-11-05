# 🤔 DISCUSIÓN: ¿Qué queremos analizar en Panel E (G-Content)?

**Fecha:** 2025-10-24  
**Propósito:** Clarificar ANTES de crear la gráfica

---

## 🎯 **PREGUNTA CENTRAL: ¿Qué buscamos responder?**

### **Opción 1: Disponibilidad de Substrate (G-content puro)**
**Pregunta:** ¿Cuántas Guaninas HAY en cada posición del miRNA?

**Por qué importa:**
- Las Gs son el **substrate** para la oxidación (8-oxoG)
- Más Gs → Más sitios potenciales para oxidarse
- Si una posición NO tiene Gs, NO puede tener G>T

**Lo que mediríamos:**
- Número de nucleótidos G en la secuencia de referencia
- Esto es INDEPENDIENTE de mutaciones

**Problema:**
- No tenemos las secuencias de referencia de los miRNAs
- Solo tenemos datos de mutaciones (pos:mut)

---

### **Opción 2: G-Content Estimado (basado en mutaciones observadas)**
**Pregunta:** ¿En cuántos miRNAs vemos mutaciones de G en cada posición?

**Por qué importa:**
- Si vemos mutaciones G>T, G>C, G>A → Sabemos que HAY una G en esa posición
- Es un **proxy** del G-content real

**Lo que mediríamos:**
- Número de miRNAs con AL MENOS una mutación de G (GT, GC, o GA) en cada posición

**Ventaja:**
- Podemos calcularlo con los datos que tenemos
- Es un estimado razonable del G-content

---

### **Opción 3: Relación Substrate-Product**
**Pregunta:** ¿Las posiciones con más Gs tienen más mutaciones G>T?

**Por qué importa:**
- Valida la hipótesis de que G-content predice G>T burden
- Si alta G-content NO correlaciona con alto G>T → Hay otros factores

**Lo que necesitaríamos mostrar:**
- G-content (cuántos Gs hay)
- G>T count (cuántos G>T hay)
- **Comparación directa** en la misma figura

---

## 📊 **¿QUÉ MÉTRICAS TIENE SENTIDO INCLUIR?**

### **Métrica A: Número de miRNAs con G en cada posición**
```r
miRNAs_with_G = n_distinct(miRNA_name[tiene_G_mutation])
# Ejemplo: Posición 6 → 99 miRNAs tienen G
```

**¿Sirve?** 
- ✅ SÍ - Estima cuántos miRNAs tienen G (substrate)
- ✅ Podemos calcularlo con los datos
- ❓ Pero no es el G-content TOTAL, solo miRNAs únicos

**¿Qué nos dice?**
- "99 miRNAs diferentes tienen una G en posición 6"
- NO nos dice cuántas Gs TOTALES hay sumando todos los miRNAs

---

### **Métrica B: Número total de cuentas (reads) de G>T**
```r
total_GT_counts = sum(all_sample_columns[is_GT_mutation])
# Ejemplo: Posición 6 → 1,500 cuentas totales de G>T
```

**¿Sirve?**
- ✅ SÍ - Muestra la **magnitud real** de G>T (ponderado por abundancia)
- ✅ Refleja tanto frecuencia como abundancia de miRNAs
- ⚠️ Está influenciado por la abundancia del miRNA (let-7 tiene más reads)

**¿Qué nos dice?**
- "En posición 6 hay 1,500 cuentas de G>T en total"
- Incorpora que algunos miRNAs son mucho más abundantes

---

### **Métrica C: Proporción de cuentas G>T vs total de cuentas**
```r
GT_fraction = sum(GT_counts) / sum(all_counts)
# Ejemplo: Posición 6 → 15% de todas las cuentas son G>T
```

**¿Sirve?**
- ✅ SÍ - Normaliza por abundancia total
- ✅ Muestra qué tan importante es G>T en ese contexto
- ❓ Pero mezcla G-content con mutation rate

**¿Qué nos dice?**
- "El 15% de TODAS las lecturas en posición 6 son G>T"
- Refleja tanto G-content como tasa de mutación

---

### **Métrica D: G>T specificity (% de mutaciones G que son G>T)**
```r
GT_specificity = (total_GT / total_G_mutations) * 100
# Ejemplo: Posición 6 → 85% de mutaciones G son G>T
```

**¿Sirve?**
- ✅ SÍ - Muestra selectividad oxidativa
- ✅ Independiente de cuántos Gs hay (normalizado)
- ✅ Firma de daño oxidativo (alto % → oxidación)

**¿Qué nos dice?**
- "Del total de mutaciones de G, el 85% son G>T"
- Indica predominancia de oxidación vs otras mutaciones de G

---

## 🤔 **PREGUNTAS PARA DECIDIR QUÉ GRAFICAR:**

### **Pregunta 1: ¿Qué es más importante para ti?**

A. **Ver cuántos Gs HAY** (substrate puro)
   - Métrica: miRNAs con G
   - Interpretación: Disponibilidad de substrate

B. **Ver cuánto G>T OCURRE** (product puro)
   - Métrica: Total de cuentas G>T
   - Interpretación: Carga de oxidación real

C. **Ver la RELACIÓN substrate → product**
   - Métricas: Ambas juntas
   - Interpretación: ¿G-content predice G>T?

---

### **Pregunta 2: ¿Qué escala importa más?**

A. **Número de miRNAs únicos** (binario: tiene G o no)
   - Ejemplo: "99 miRNAs tienen G en posición 6"
   - No pondera por abundancia

B. **Suma de cuentas (reads)** (ponderado por abundancia)
   - Ejemplo: "1,500 cuentas de G>T en posición 6"
   - Refleja que algunos miRNAs son mucho más abundantes

C. **Ambos** (mostrar las dos escalas)
   - Barras = miRNAs únicos
   - Bubbles = cuentas totales

---

### **Pregunta 3: ¿Qué comparación es más relevante?**

A. **G-content vs G>T burden**
   - ¿Posiciones con más Gs → más G>T?
   - Valida hipótesis substrate → product

B. **G>T count vs G>T specificity**
   - ¿Posiciones con más G>T también tienen alta selectividad?
   - Identifica hotspots (alto burden + alta especificidad)

C. **Seed vs Non-Seed**
   - ¿La región seed tiene diferente G-content o selectividad?
   - Enfoque funcional

---

## 💡 **MI SUGERENCIA (Pero quiero tu opinión):**

### **Opción A: G-Content Simple (Substrate Only)**
```
- Barras: Número de miRNAs con G en cada posición
- NO bubbles, NO color extra
- Limpio, directo, fácil de interpretar
- Responde: "¿Dónde hay Gs?"
```

**Ventajas:** Claro, directo  
**Desventajas:** Poca información

---

### **Opción B: G-Content + G>T Burden (Substrate + Product)**
```
- Barras: Número de miRNAs con G (substrate)
- Bubbles (tamaño): Total cuentas G>T (product)
- Color de bubbles: G>T specificity (selectivity)
```

**Ventajas:** Muestra relación substrate → product  
**Desventajas:** Más complejo

---

### **Opción C: G-Content + Mutation Burden Total**
```
- Barras: Número de miRNAs con G
- Bubbles (tamaño): TOTAL de cuentas (no solo G>T)
- Color de bubbles: % que son G>T
```

**Ventajas:** Muestra contexto completo  
**Desventajas:** Podría ser redundante con otros paneles

---

### **Opción D: Dual-Axis Plot**
```
- Eje Y izquierdo: Número de miRNAs con G (barras)
- Eje Y derecho: Total cuentas G>T (línea)
- Dos escalas diferentes pero relacionadas
```

**Ventajas:** Claridad de dos métricas distintas  
**Desventajas:** Dual-axis plots pueden confundir

---

## ❓ **PREGUNTAS ESPECÍFICAS PARA TI:**

### **1. ¿Qué pregunta biológica quieres responder con Panel E?**

A. "¿Dónde hay más Gs?" (substrate distribution)  
B. "¿Dónde hay más G>T?" (product distribution)  
C. "¿G-content predice G>T burden?" (substrate → product)  
D. "¿Qué posiciones combinan alto substrate + alto product?" (hotspots)

---

### **2. ¿Cuál de estas comparaciones es MÁS importante?**

A. **miRNAs únicos con G** (binario)
   - Pros: Simple, claro
   - Contras: No refleja abundancia

B. **Total de cuentas (reads)**
   - Pros: Refleja abundancia real
   - Contras: Sesgado por miRNAs abundantes

C. **Ambas** (barras + bubbles)
   - Pros: Información completa
   - Contras: Más complejo

---

### **3. ¿La especificidad G>T es información relevante aquí?**

- **SÍ:** Ayuda a identificar posiciones con firma oxidativa clara
- **NO:** Ya lo vemos en Panel G, sería redundante
- **DEPENDE:** Solo si comparamos G-content con selectividad

---

### **4. ¿Qué te confunde del bubble plot actual?**

- ¿Son demasiadas dimensiones juntas?
- ¿No está claro qué información aporta cada capa?
- ¿Prefieres algo más simple y directo?
- ¿O prefieres mantener la información pero con mejor explicación?

---

## 🎨 **PROPUESTAS ALTERNATIVAS:**

### **Propuesta 1: SIMPLE - Solo G-content**
```r
Barras verdes: miRNAs con G por posición
Eso es todo. Limpio y claro.
```

### **Propuesta 2: DUAL-METRIC - G-content + G>T Count**
```r
Barras verdes: miRNAs con G (substrate)
Línea roja sobre las barras: Total cuentas G>T (product)
Muestra relación directa
```

### **Propuesta 3: BUBBLE - Multi-dimensional (actual)**
```r
Barras: miRNAs con G
Bubbles (tamaño): G>T count
Bubbles (color): G>T specificity
```

### **Propuesta 4: HEATMAP - Dos métricas lado a lado**
```r
Panel E.1: G-content por posición (barras)
Panel E.2: G>T burden por posición (barras rojas)
Dos subpaneles para comparación directa
```

---

## 💭 **MIS PREGUNTAS PARA TI:**

1. **¿Qué información es CRÍTICA para el análisis inicial?**
   - Solo substrate (Gs)
   - Solo product (G>T)
   - Relación substrate-product

2. **¿Prefieres simplicidad o información densa?**
   - Simple: Una métrica, fácil de entender
   - Denso: Múltiples métricas, más insights

3. **¿El Panel E debe ser independiente o complementar otros paneles?**
   - Independiente: Información única que no esté en otros lados
   - Complementario: Añade contexto a Panel B, C, D

4. **¿Qué NO está claro del bubble plot que generé?**
   - ¿Qué representa cada elemento?
   - ¿Por qué es importante cada métrica?
   - ¿Cómo se relacionan las 3 dimensiones?

---

## 🔬 **ANÁLISIS: ¿Qué aporta cada métrica?**

### **Si medimos: Número de miRNAs con G**
```
Position 6: 99 miRNAs tienen G
```
**¿Qué aprendemos?**
- ✅ Diversidad: Muchos miRNAs diferentes tienen G ahí
- ❌ NO sabemos cuántos Gs en TOTAL (sumando todos los miRNAs)
- ❌ NO sabemos si esos miRNAs son abundantes o raros

**¿Es suficiente para Panel E?**
- Si el objetivo es ver "diversidad de substrate" → SÍ
- Si el objetivo es ver "cantidad total de Gs" → NO

---

### **Si medimos: Total de cuentas con G>T**
```
Position 6: 1,500 cuentas de G>T
```
**¿Qué aprendemos?**
- ✅ Burden real de oxidación (ponderado por abundancia)
- ✅ Refleja impacto biológico (miRNAs abundantes importan más)
- ❌ NO nos dice nada sobre G-content (substrate)

**¿Es suficiente para Panel E?**
- Si el objetivo es ver "burden de G>T" → Ya está en Panel B
- Si el objetivo es ver "substrate" → NO

---

### **Si medimos: Proporción de cuentas G>T / total cuentas**
```
Position 6: 15% de todas las cuentas son G>T
```
**¿Qué aprendemos?**
- ✅ Importancia relativa de G>T en esa posición
- ❌ Mezcla G-content con mutation rate
- ❌ Difícil de interpretar (¿es alto por Gs o por oxidación?)

**¿Es suficiente para Panel E?**
- Confuso: No separa substrate de product

---

## 🎯 **ENTONCES, ¿QUÉ DEBE MOSTRAR PANEL E?**

### **Mi recomendación (pero TÚ decides):**

**PANEL E debe mostrar SUBSTRATE (G-content), NO product (G>T)**

**Razón:**
- Panel B ya muestra G>T count (product)
- Panel C ya muestra espectro G>X (product)
- Panel D ya muestra fracción posicional (product)
- Panel G ya muestra G>T specificity (product)

**Panel E debe ser ÚNICO:**
- Mostrar el SUBSTRATE (Gs disponibles)
- Permitir comparar con Panel B: ¿Alto G → Alto G>T?

---

## 📋 **OPCIONES FINALES PARA TU DECISIÓN:**

### **OPCIÓN 1: SIMPLE (Solo G-content estimado)**
```
Gráfica: Barras verdes
Y-axis: Número de miRNAs con G en cada posición
X-axis: Posición (1-22)
Seed region: Highlighted

¿Qué muestra?
- Distribución de Gs (substrate)
- Simple, directo, claro

¿Qué NO muestra?
- G>T burden
- Especificidad
- Relación substrate-product
```

---

### **OPCIÓN 2: DUAL-METRIC (G-content + G>T para comparación)**
```
Gráfica: Barras verdes + Línea roja sobrepuesta
Y-axis izquierdo: Número de miRNAs con G
Y-axis derecho: Total cuentas G>T
X-axis: Posición (1-22)

¿Qué muestra?
- G-content (substrate) en barras
- G>T burden (product) en línea
- Comparación visual directa

¿Qué NO muestra?
- Especificidad G>T
- Otros tipos de mutación
```

---

### **OPCIÓN 3: BUBBLE PLOT (Multi-dimensional - más información)**
```
Gráfica: Barras + Bubbles con color
- Barras: miRNAs con G (substrate)
- Bubble size: Total G>T cuentas (product)
- Bubble color: G>T specificity (selectivity)

¿Qué muestra?
- Substrate, product, y selectivity
- Relación completa
- Hotspots (alto en todo)

¿Qué NO muestra?
- Puede ser complejo de interpretar
- Requiere caption largo
```

---

### **OPCIÓN 4: TWO-PANEL (G-content vs G>T lado a lado)**
```
Panel E.1: G-content (barras verdes)
Panel E.2: G>T burden (barras rojas)
Uno al lado del otro para comparación directa

¿Qué muestra?
- Comparación lado a lado
- Muy claro qué es substrate y qué es product
- Fácil identificar si correlacionan

¿Qué NO muestra?
- Ocupa más espacio (dos paneles)
```

---

## ❓ **PREGUNTAS CONCRETAS PARA TI:**

### **A. Sobre el objetivo:**
1. ¿Panel E debe mostrar SOLO G-content (substrate)?
2. ¿O debe mostrar la RELACIÓN entre G-content y G>T?

### **B. Sobre la métrica:**
3. ¿Prefieres número de miRNAs únicos (diversidad) o total de cuentas (abundancia)?
4. ¿O ambos son importantes?

### **C. Sobre la complejidad:**
5. ¿Prefieres un plot simple y claro, o uno con más información aunque sea más complejo?

### **D. Sobre la interpretación:**
6. ¿Qué pregunta biológica específica debe responder Panel E?
   - "¿Dónde hay más Gs?" → Simple bar chart
   - "¿G-content predice G>T?" → Dual metric
   - "¿Qué posiciones son hotspots completos?" → Bubble plot

### **E. Sobre redundancia:**
7. ¿Te preocupa que Panel E se solape con Panel B (G>T count)?
8. ¿O está bien que se complementen (uno substrate, otro product)?

---

## 🎨 **MI RECOMENDACIÓN FINAL:**

**Para el Paso 1 (análisis inicial), creo que Panel E debería:**

1. **Mostrar SOLO G-content** (substrate)
   - Barras verdes simples
   - Y-axis: "Number of miRNAs with G nucleotide"
   - Limpio, claro, único

2. **NO incluir G>T count** (ya está en Panel B)

3. **Permitir comparación mental con Panel B**
   - Usuario puede comparar Panel E (Gs) con Panel B (G>T)
   - Si correlacionan → G-content predice G>T ✅

4. **Opcionalmente: Añadir SOLO una métrica extra**
   - Bubble color: G>T specificity
   - Esto SÍ añade info (no está en Panel B)
   - Muestra si posiciones con más Gs también tienen alta selectividad

**Entonces:**
```
- Barras verdes: miRNAs con G (substrate)
- Bubble color (opcional): G>T specificity
- NO bubble size (eso sería redundante con Panel B)
```

---

## 🤝 **TU TURNO - DECIDE:**

**Responde:**
1. ¿Qué pregunta debe responder Panel E?
2. ¿Simple (solo barras) o con info adicional (+ color)?
3. ¿Prefieres miRNAs únicos o total de cuentas?
4. ¿El bubble plot actual tiene sentido o es demasiado?

**Con tus respuestas, haré la versión FINAL correcta.** 🎯

