# 💡 CLARIFICACIÓN COMPLETA - PANEL 2.1

**Fecha:** 2025-10-24  
**Tus preguntas respondidas**

---

## ❓ **TUS PREGUNTAS:**

### **1. "¿Qué nos dice la suma de todos los VAFs?" (Panel A)**

**Respuesta corta:** El **burden total de mutaciones** en esa muestra.

**Explicación detallada:**

```
VAF (individual) = count_variant / count_total_miRNA
```

Por ejemplo:
- miR-let-7a posición 6:GT → VAF = 0.02 (2% de las moléculas tienen esta mutación)
- miR-9 posición 3:AC → VAF = 0.01 (1%)
- miR-196a posición 8:GT → VAF = 0.015 (1.5%)

**Total_VAF = SUMA de TODOS estos VAF**
```
Total_VAF = 0.02 + 0.01 + 0.015 + ... (todos los SNVs)
          = 3.5 (por ejemplo)
```

**¿Qué significa "3.5"?**
- NO es un porcentaje (no es 3.5%)
- Es la **suma acumulada** de frecuencias de variantes
- Muestra con valor alto = Muchas mutaciones O mutaciones frecuentes O ambas

**Interpretación biológica:**
- Mayor Total_VAF = Mayor "carga mutacional global"
- Refleja inestabilidad genómica general

---

### **2. "¿Cuál es la diferencia entre Panel C y Panel B?"**

**Respuesta corta:** 
- **Panel B** = Cantidad absoluta de G>T (suma)
- **Panel C** = Proporción relativa de G>T (fracción)

**Explicación con ejemplo:**

**Muestra ALS-1:**
- Total_VAF = 10.0 (muchas mutaciones)
- GT_VAF = 8.0 (mucho G>T)
- GT_Ratio = 8.0 / 10.0 = **0.8 (80%)**

**Muestra Control-1:**
- Total_VAF = 2.0 (pocas mutaciones)
- GT_VAF = 1.5 (poco G>T)
- GT_Ratio = 1.5 / 2.0 = **0.75 (75%)**

**Comparación:**

| Métrica | ALS-1 | Control-1 | Interpretación |
|---------|-------|-----------|----------------|
| **Panel A (Total)** | 10.0 | 2.0 | ALS tiene 5x MÁS mutaciones totales |
| **Panel B (G>T)** | 8.0 | 1.5 | ALS tiene 5.3x MÁS G>T |
| **Panel C (Ratio)** | 0.8 | 0.75 | ALS tiene 80% G>T, Control 75% → Similar especificidad |

**Conclusión de este ejemplo:**
- ALS tiene MÁS burden (Paneles A y B)
- PERO especificidad similar (Panel C)
- Indica: Más daño global, no selectividad oxidativa aumentada

---

### **3. "¿G>T / Total no es literalmente solo el VAF?"**

**Respuesta:** **NO**, y esta es la confusión clave.

**VAF individual** (de UN SNV):
```
VAF = count_de_ese_SNV / count_total_del_miRNA
Ejemplo: miR-let-7a 6:GT tiene VAF = 0.02
```

**GT_Ratio** (Panel C):
```
GT_Ratio = SUMA(todos_los_VAF_de_G>T) / SUMA(todos_los_VAF_de_todo)
```

**Son DIFERENTES porque:**

**Ejemplo numérico:**

Una muestra tiene 3 SNVs:
1. miR-let-7a 6:GT → VAF = 0.5
2. miR-9 3:GT → VAF = 0.3
3. miR-196a 8:AC → VAF = 0.2

**Cálculos:**
```
Total_VAF = 0.5 + 0.3 + 0.2 = 1.0
GT_VAF = 0.5 + 0.3 = 0.8 (solo G>T)
GT_Ratio = 0.8 / 1.0 = 0.8 (80%)
```

**Interpretación:**
- El 80% del burden total es G>T
- Esto NO es el VAF de ningún SNV individual
- Es la fracción de la carga mutacional que es G>T

---

## 📊 **RESULTADOS REALES DEL ANÁLISIS:**

### **Estadísticas encontradas:**

| Grupo | N | Mean Total VAF | Mean G>T VAF | Mean GT Ratio |
|-------|---|----------------|--------------|---------------|
| **ALS** | 313 | 3.63 | 2.58 | ~71% |
| **Control** | 102 | 4.97 | 3.69 | ~74% |

### **🔥 HALLAZGO SORPRENDENTE:**

**Control tiene MAYOR VAF que ALS!**
- Total_VAF: Control (4.97) > ALS (3.63)
- GT_VAF: Control (3.69) > ALS (2.58)

**Pero todos son altamente significativos:**
- p = 2e-11 (Total)
- p = 2.5e-13 (G>T)
- p = 6e-05 (Ratio)

**¿Qué significa esto?**
- Control tiene MAYOR burden de mutaciones (inesperado!)
- Pero la especificidad G>T es similar (71% vs 74%)

**Posibles explicaciones:**
1. Edad: ¿Control son más viejos?
2. Expresión: ¿Control tienen más miRNA expresados?
3. Profundidad de secuenciación: ¿Control secuenciados más profundo?
4. Otro factor técnico o biológico

---

## 📏 **ESCALA: LOG vs LINEAR**

### **Rango de valores:**
- Total VAF: 0.55 a 27.56 → **50-fold difference**
- G>T VAF: 0.40 a 22.96 → **58-fold difference**

**Recomendación del análisis:**
> "LOG SCALE recomendada pero no esencial"
> "Rango 10-100 fold - Linear funcionaría pero log es más claro"

**He generado AMBAS versiones:**
- `FIG_2.1_LINEAR_SCALE.png`
- `FIG_2.1_LOG_SCALE.png`

**Compáralas y decide cuál es más clara.**

---

## 🎯 **RESUMEN DE LAS DIFERENCIAS**

### **Panel A (Total VAF):**
- **Qué es:** Suma de todos los VAF de todos los SNVs
- **Interpreta:** Burden total de mutaciones
- **Pregunta:** ¿ALS tiene más mutaciones en general?

### **Panel B (G>T VAF):**
- **Qué es:** Suma de VAF solo de SNVs G>T
- **Interpreta:** Burden específico de oxidación
- **Pregunta:** ¿ALS tiene más G>T específicamente?
- **Relación con A:** Panel B ≤ Panel A (es subset)

### **Panel C (GT Ratio):**
- **Qué es:** (Panel B) / (Panel A) = Fracción
- **Interpreta:** Especificidad/selectividad de G>T
- **Pregunta:** ¿Qué PROPORCIÓN del daño es G>T?
- **NO es VAF:** Es la fracción del burden total que es G>T

---

## 🔥 **HALLAZGO CRÍTICO A DISCUTIR:**

**Control > ALS en burden (inesperado!)**

**¿Esto tiene sentido biológicamente?**
- ❓ ¿Hay variables confusoras?
- ❓ ¿Es un artefacto técnico?
- ❓ ¿O es un hallazgo real?

**Necesitamos investigar:**
1. Edad de los grupos (¿Control son mayores?)
2. Profundidad de secuenciación (¿Control tienen más reads?)
3. Expresión de miRNAs (¿Control expresan más miRNAs?)

---

**He abierto las DOS versiones (linear y log).**

**Ahora dime:**
1. ¿Cuál escala prefieres?
2. ¿Qué piensas del hallazgo Control > ALS?
3. ¿Tiene sentido o es preocupante?

🤔

