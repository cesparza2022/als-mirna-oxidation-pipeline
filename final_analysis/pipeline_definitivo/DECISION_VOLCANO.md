# 🌋 DECISIÓN: ¿Con qué VOLCANO nos quedamos?

**Fecha:** 2025-10-24

---

## 📊 **OPCIONES DISPONIBLES:**

### **Opción 1: MANTENER el volcano actual (sin significativos)**

**Archivo:** `FIG_2.3_VOLCANO_CORRECTED.png`

**Características:**
- 293 miRNAs analizados
- 0 significativos (todos grises)
- Control en gris oscuro (corregido)
- Umbrales: FDR < 0.05, |log₂FC| > 0.58

**PROS:**
- ✅ Correcto estadísticamente (FDR apropiado)
- ✅ Honesto (muestra la realidad: no hay significativos)
- ✅ Comunica que el efecto es distribuido, no focal

**CONTRAS:**
- ❌ Visualmente "vacío" (todos los puntos grises)
- ❌ No aporta información específica de miRNAs
- ❌ Puede parecer "fallido" para un lector

**¿Cuándo usar esta?**
- Si quieres ser completamente riguroso estadísticamente
- Si quieres comunicar que NO hay miRNAs individuales responsables
- Si el mensaje es: "efecto global distribuido"

---

### **Opción 2: RELAJAR umbrales para mostrar tendencias**

**Nuevo archivo a generar:** `FIG_2.3_VOLCANO_RELAXED.png`

**Cambios:**
```r
# En vez de FDR < 0.05
# Usar p-value nominal < 0.05 (sin FDR)
# O FDR < 0.1 (menos estricto)

# En vez de |log2FC| > 0.58 (1.5x)
# Usar |log2FC| > 0.3 (1.23x, más permisivo)
```

**PROS:**
- ✅ Mostraría algunos miRNAs con "tendencia"
- ✅ Más informativo visualmente
- ✅ Útil para exploración

**CONTRAS:**
- ⚠️ Menor rigor estadístico
- ⚠️ Necesita disclaimer claro
- ⚠️ Puede incluir falsos positivos

**¿Cuándo usar esta?**
- Si quieres identificar miRNAs "candidatos"
- Si es análisis exploratorio
- Con disclaimer: "Nominal p < 0.05 (not FDR-corrected)"

---

### **Opción 3: ELIMINAR el volcano completamente**

**PROS:**
- ✅ No muestra figura "vacía"
- ✅ Evita confusión
- ✅ Enfoca en hallazgos globales (Fig 2.1-2.2)

**CONTRAS:**
- ❌ Pierdes la información de que NO hay miRNAs específicos
- ❌ Es un hallazgo válido (ausencia de miRNAs focales)

**¿Cuándo usar esta?**
- Si decides que el volcano no aporta
- Si prefieres enfocarte en análisis global

---

### **Opción 4: CAMBIAR a otra visualización**

**Alternativas:**

#### **4a. Barplot de Top miRNAs por contribución al burden:**
```r
# Mostrar: ¿Qué miRNAs contribuyen más al burden total?
# Pregunta: ¿El burden está concentrado o distribuido?
```

#### **4b. Dotplot de expresión relativa:**
```r
# Mostrar: Expresión de miRNAs en ALS vs Control
# Pregunta: ¿Hay miRNAs expresados diferente?
```

#### **4c. Scatter plot de correlación:**
```r
# X: VAF en ALS, Y: VAF en Control
# Muestra qué miRNAs se desvían de la diagonal
```

---

## 💡 **MI RECOMENDACIÓN:**

### **Recomendación:** Opción 2 (Relajar umbrales) + Disclaimer

**Justificación:**

1. **Rigurosamente, no hay significativos** (Opción 1 es correcta)
2. **Pero para exploración,** mostrar tendencias es útil
3. **Con disclaimer claro:**
   - "Nominal p < 0.05 (exploratory)"
   - "No FDR-significant miRNAs detected"

**Propuesta:**
```r
# Generar DOS versiones:

Versión A: FDR < 0.05 (rigurosa, actual)
   → Para paper final si quieres mostrar que no hay focales

Versión B: p < 0.05 nominal (exploratoria)
   → Para identificar candidatos y explorar patrones
   → CON DISCLAIMER
```

**Incluir en el subtítulo:**
```
"No miRNAs passed FDR < 0.05 correction. 
Shown: nominal p < 0.05 for exploratory purposes."
```

---

## 🎯 **ALTERNATIVA RECOMENDADA:**

### **En vez de volcano (o además), mostrar:**

**"Top miRNAs Contributors to Burden"**
- Barplot de los 20 miRNAs que más contribuyen al G>T burden total
- Separado por grupo (ALS vs Control)
- **Pregunta:** ¿El burden está concentrado en pocos o distribuido en muchos?

**Esto sería MÁS informativo** que un volcano vacío.

---

## ❓ **TUS DECISIONES:**

Por favor elige:

### **Para el Volcano:**
- [ ] **A.** Mantener actual (FDR estricto, 0 significativos) - Honesto
- [ ] **B.** Relajar a p < 0.05 nominal (con disclaimer) - Exploratorio
- [ ] **C.** Eliminar el volcano - No aporta
- [ ] **D.** Generar AMBAS versiones (rigurosa + exploratoria)

### **¿Agregar figura alternativa?**
- [ ] **Sí:** Barplot de Top Contributors al burden
- [ ] **No:** Continuar con siguiente figura del paso 2

---

## 🔥 **INTERPRETACIÓN BIOLÓGICA:**

**Ausencia de miRNAs significativos individuales es un HALLAZGO válido:**

**Significa:**
- El daño oxidativo en ALS **NO está focalizado** en miRNAs específicos
- Es un fenómeno **GLOBAL** que afecta a muchos miRNAs moderadamente
- No hay "smoking gun" (miRNA culpable único)

**Esto es importante científicamente:**
- Descarta hipótesis de "miRNA específico driver"
- Apoya modelo de "daño global acumulativo"

---

**He abierto el resumen completo.**

**¿Qué decides?** 
1. ¿Qué volcano usar (A, B, C, o D)?
2. ¿Agregar figura de Top Contributors?
3. ¿O continuar con siguiente figura?

🚀

