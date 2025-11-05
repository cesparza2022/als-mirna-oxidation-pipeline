# 🔍 CLARIFICACIONES Y CORRECCIONES - FEEDBACK

## ❓ **TUS PREGUNTAS - MIS RESPUESTAS**

### **FIGURA 1 - Panel A:**
**Tu pregunta:** ¿Los números son VAF, counts, SNVs por miRNA, o SNVs totales?

**Mi respuesta:**
- **Raw Entries:** 68,968 = FILAS en el archivo original (cada fila puede tener múltiples mutaciones)
- **Individual SNVs:** 110,199 = SNVs INDIVIDUALES después de split y filtrar PM
- **Top 10 mutation types:** COUNTS totales (número de veces que aparece cada tipo)

**CORRECCIÓN NECESARIA:**
✅ Hacer labels más explícitos:
- "68,968 rows" (not just numbers)
- "110,199 individual SNVs"  
- "Count" en eje Y de mutation types (no solo números)

---

### **FIGURA 2 - Panel A (G-content):**
**Tu pregunta:** ¿Qué es "número de Gs por posición"?

**Mi respuesta (ACTUAL - confuso):**
- Es el número de Guaninas en la región SEED (posiciones 2-8)
- NO es por posición individual, es TOTAL en seed
- Eje X: 0, 1, 2, 3... 7 Guaninas en SEED
- Eje Y: % de miRNAs que tienen G>T

**EJEMPLO:**
- miRNA con seed = "UGGCGAU" tiene 3 G's
- miRNA con seed = "AAAAAAA" tiene 0 G's
- Plot muestra: miRNAs con más G's → más % oxidados

**CORRECCIÓN NECESARIA:**
✅ Label más claro: "Number of G nucleotides in seed region (positions 2-8)"
✅ Subtitle: "More G's in seed → Higher oxidation susceptibility"

---

### **FIGURA 2 - Panel C (Specificity):**
**Tu corrección:** G>T debe ser ROJO (oxidación)

**ERROR ACTUAL:**
- Estoy usando naranja para G>T ❌
- En Tier 1 usé naranja (neutral)
- Pero tienes razón: G>T = oxidación = ROJO

**CORRECCIÓN:**
✅ G>T = #D62728 (ROJO)
✅ G>A = Azul
✅ G>C = Verde
✅ Consistente con Figura 3

---

### **FIGURA 2 - Panel D (Frequency):**
**Tu pregunta:** ¿Estamos viendo VAF o counts? ¿Con estadística?

**RESPUESTA ACTUAL:**
- Estoy mostrando COUNTS de G>T por posición
- NO estoy usando VAF
- NO tengo estadística (solo descriptivo)

**LO QUE DEBERÍA SER (según tu feedback):**
- Si tengo VAF → Usar VAF con estadística (como tu ejemplo)
- Si NO tengo VAF → Usar counts pero dejar CLARO que son counts
- Agregar estadística si comparo grupos

**PROBLEMA:**
- En Figura 2 (Tier 1) NO tengo grupos todavía
- Solo puedo mostrar distribución global
- Estadística por posición viene en Figura 3 (con grupos)

**CORRECCIÓN:**
✅ Label claro: "G>T count by position" (no "frequency")
✅ G>T en ROJO (no naranja)
✅ Dejar claro que es descriptivo (no test estadístico aún)
✅ O mover este panel a Figura 3 donde SÍ hay estadística

---

## 🔧 **CORRECCIONES A IMPLEMENTAR**

### **Prioridad 1: COLORES - G>T siempre ROJO**
```r
# CAMBIAR en TODAS las figuras:
G>T color: "#D62728"  # ROJO (oxidación)

# NO usar:
G>T color: "#FF7F00"  # Naranja ❌
```

**Afecta:**
- Figura 1 Panel C
- Figura 2 Panel C, D
- Figura 3 (ya está bien)

---

### **Prioridad 2: LABELS CLAROS**

**Figura 1 Panel A:**
```r
# ANTES (confuso):
"68,968"
"110,199"

# DESPUÉS (claro):
"68,968 rows (original file)"
"110,199 individual SNVs"
"Count" en eje Y
```

**Figura 2 Panel A:**
```r
# ANTES (confuso):
"Number of G's in seed"

# DESPUÉS (claro):
"Number of G nucleotides in seed region (positions 2-8)"
subtitle: "Hypothesis: More G's → Higher oxidation risk"
```

**Figura 2 Panel D:**
```r
# ANTES (confuso):
"G>T frequency by position"

# DESPUÉS (claro):
"G>T count by position"
y-axis: "Count of G>T mutations"
subtitle: "Descriptive (no statistical test - see Figure 3 for group comparison)"
```

---

### **Prioridad 3: USO DE VAF**

**DECISIÓN CRÍTICA:**
- ¿Tenemos VAF en los datos? SÍ (columnas de muestras)
- ¿Lo estamos usando? NO (solo counts)
- ¿Deberíamos usarlo? DEPENDE

**Para Figura 3 Panel B (tu favorito):**
```r
# OPCIÓN A: Usar VAF (más riguroso)
y-axis: "Mean VAF of G>T"
subtitle: "Wilcoxon test per position (VAF comparison)"

# OPCIÓN B: Usar counts (más simple)
y-axis: "G>T count"
subtitle: "Wilcoxon test per position (count comparison)"
```

**¿Cuál prefieres para Panel B?**

---

## 🚀 **PLAN DE CORRECCIÓN INMEDIATO**

Voy a corregir AHORA:

1. ✅ **G>T = ROJO** en todas las figuras
2. ✅ **Labels explícitos** (counts, VAF, rows, etc.)
3. ✅ **Figura 2 Panel A** - Label claro de "# G's in seed region"
4. ✅ **Figura 2 Panel D** - Aclarar que es count, no test
5. ✅ **Regenerar todas las figuras** con correcciones
6. ✅ **Actualizar HTML viewer**

**Tiempo:** 30 minutos

**¿Procedemos con las correcciones? Y para Panel B (tu favorito), ¿prefieres VAF o counts?** 🚀

