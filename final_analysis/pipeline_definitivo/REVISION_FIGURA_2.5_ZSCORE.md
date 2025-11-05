# 📊 REVISIÓN FIGURA 2.5 - Z-SCORE HEATMAP

**Fecha:** 2025-10-24

---

## 🎯 **¿QUÉ ES Y QUÉ MUESTRA?**

**Pregunta que responde:**
"¿Qué miRNAs y posiciones se desvían más del promedio en cada grupo?"

---

## 📐 **¿QUÉ ES UN Z-SCORE?**

### **Definición:**
```
Z-score = (valor - media) / desviación_estándar

Z-score normaliza los valores para comparar en la misma escala
```

### **Interpretación:**
```
Z-score = 0  → Valor promedio
Z-score = +1 → 1 SD por arriba del promedio
Z-score = +2 → 2 SD por arriba del promedio
Z-score = -1 → 1 SD por debajo del promedio
```

### **Escala típica:**
```
Z < -3  → MUY por debajo (azul oscuro)
Z = -2  → Moderadamente bajo (azul claro)
Z = 0   → Promedio (blanco)
Z = +2  → Moderadamente alto (rojo claro)
Z > +3  → MUY por arriba (rojo oscuro)
```

---

## 🔍 **¿CÓMO SE CALCULA PARA ESTE HEATMAP?**

### **PASO 1: Crear matriz (igual que Fig 2.4)**

```
Entrada: Top 50 miRNAs (de Fig 2.4)
Matriz combinada (ALS + Control):
   
   ┌──────────┬────┬────┬────┬─────┬─────┐
   │ miRNA    │ p1 │ p2 │ p3 │ ... │ p22 │
   ├──────────┼────┼────┼────┼─────┼─────┤
   │ let-7a   │0.01│0.02│0.01│ ... │0.00 │
   │ miR-9    │0.02│0.00│0.03│ ... │0.00 │
   │ ...      │... │... │... │ ... │ ... │
   └──────────┴────┴────┴────┴─────┴─────┘
```

---

### **PASO 2: Calcular Z-score POR FILA (por miRNA)**

**Método:**
```r
zscore_matrix <- t(scale(t(combined_matrix)))
```

**¿Qué hace `scale()` por fila?**

Para cada miRNA:
```
let-7a en posiciones 1-22:
   Valores: [0.01, 0.02, 0.01, 0.00, 0.03, ...]
   
   Media = 0.015
   SD = 0.008
   
   Z-scores:
   Pos 1: (0.01 - 0.015) / 0.008 = -0.625
   Pos 2: (0.02 - 0.015) / 0.008 = +0.625
   Pos 3: (0.01 - 0.015) / 0.008 = -0.625
   ...
```

**Resultado:**
- Cada fila (miRNA) ahora tiene media = 0, SD = 1
- Permite comparar DENTRO del miRNA (qué posiciones destacan)

---

## 💡 **¿QUÉ INFORMACIÓN APORTA EL Z-SCORE?**

### **Diferencia con Fig 2.4 (VAF raw):**

**Fig 2.4 (VAF raw):**
- Muestra valores absolutos de VAF
- Color rojo = VAF alto (ej: 0.05)
- Compara magnitudes absolutas

**Fig 2.5 (Z-score):**
- Muestra desviaciones relativas del promedio de cada miRNA
- Color rojo = Posición con VAF MÁS ALTO para ese miRNA (relativo)
- Compara posiciones DENTRO de cada miRNA

---

## 🔬 **EJEMPLO CONCRETO:**

### **Dos miRNAs con patrones diferentes:**

**miRNA-A:**
```
Posiciones:  1    2    3    4    5    6    7    8    9   ...
VAF raw:     0.01 0.02 0.01 0.01 0.50 0.01 0.01 0.01 0.01
Media = 0.06

Z-scores:    -0.5 -0.3 -0.5 -0.5 +8.0 -0.5 -0.5 -0.5 -0.5
                                  ↑ MUY alto (rojo intenso)
```

**miRNA-B:**
```
Posiciones:  1    2    3    4    5    6    7    8    9   ...
VAF raw:     0.03 0.03 0.03 0.03 0.03 0.03 0.03 0.03 0.03
Media = 0.03

Z-scores:    0    0    0    0    0    0    0    0    0
                            ↑ Todo uniforme (blanco)
```

**En Fig 2.4 (raw):**
- miRNA-A posición 5 = rojo muy oscuro (VAF = 0.50)
- miRNA-B todo = naranja claro (VAF = 0.03)

**En Fig 2.5 (Z-score):**
- miRNA-A posición 5 = rojo intenso (Z = +8, outlier)
- miRNA-B todo = blanco (Z = 0, uniforme)

**Ventaja del Z-score:**
- Detecta posiciones "hotspot" DENTRO de cada miRNA
- Normaliza para miRNAs con VAF muy diferentes

---

## 🎯 **¿QUÉ PREGUNTA RESPONDE?**

**Fig 2.4:** "¿Qué posiciones tienen más G>T en valor absoluto?"

**Fig 2.5:** "¿Qué posiciones son 'outliers' relativo al comportamiento de cada miRNA?"

---

## 🤔 **PREGUNTAS DE REVISIÓN:**

### **1. ¿Es redundante con Fig 2.4?**

**Análisis:**
- Fig 2.4: Valores absolutos
- Fig 2.5: Valores normalizados (z-score)

**¿Son complementarias o duplicadas?**
- Si los patrones son idénticos → Redundante
- Si Z-score revela patrones ocultos → Complementaria

---

### **2. ¿Qué nos dice el Z-score que no vimos en raw?**

**Posibles hallazgos:**
- Posiciones específicas consistentemente elevadas
- Clustering de miRNAs por patrón posicional
- Outliers que dominan ciertas posiciones

---

### **3. ¿Tiene sentido usar top 50 de nuevo?**

**Igual que Fig 2.4:**
- Usa top 50 miRNAs
- Mismo subset de datos

**¿Deberíamos?**
- Mantener top 50 (consistencia con 2.4)
- Cambiar a ALL 301 (usar todos los datos)
- O eliminar si es redundante

---

### **4. ¿El estilo es profesional?**

**Elementos a revisar:**
- Colores (azul-blanco-rojo)
- Etiquetas en inglés
- Escala clara (-3 a +3)
- Título descriptivo
- Clustering activado/desactivado

---

## 💡 **POSIBLES PROBLEMAS:**

### **Problema 1: Escala de Z-score puede ser engañosa**

Si un miRNA tiene VAF muy uniforme (todas las posiciones = 0.001):
- Z-scores serían todos ≈ 0 (blanco)
- PERO si UNA posición = 0.002 (el doble):
  - Z-score de esa posición sería alto (rojo)
  - Aunque 0.002 es un valor absolutamente bajo

**Resultado:** Posiciones "rojas" pueden no ser biológicamente relevantes

---

### **Problema 2: Puede ser redundante**

Si Fig 2.4 (raw) ya muestra los patrones claramente:
- Z-score puede no agregar información nueva
- Solo normaliza la visualización

---

## 🎯 **DECISIONES NECESARIAS:**

### **Decisión 1: ¿Mantener esta figura?**

**Opciones:**
- [A] Mantener (aporta normalización)
- [B] Eliminar (redundante con 2.4)
- [C] Combinar con 2.4 en una figura compuesta

---

### **Decisión 2: Si la mantenemos, ¿qué usar?**

**Opciones:**
- [A] Top 50 (actual, consistencia con 2.4)
- [B] ALL 301 (usar todos los datos)
- [C] Solo seed region (enfocado)

---

### **Decisión 3: ¿Mejorar el estilo?**

**Mejoras posibles:**
- Hacerla más profesional (ggplot en vez de pheatmap)
- Agregar estadísticas
- Marcar región seed
- Etiquetas en inglés mejoradas

---

## 🔍 **ANÁLISIS QUE NECESITO HACER:**

**Para ayudarte a decidir, déjame:**

1. **Ver la figura actual** (ya abierta)
2. **Analizar si aporta información nueva vs Fig 2.4**
3. **Revisar el estilo** (profesional o no)
4. **Proponer mejoras** si decides mantenerla

---

**He abierto FIG_2.5_HEATMAP_ZSCORE_CLEAN.png**

**Revísala y dime:**
- ¿Te gusta como está?
- ¿Es redundante con Fig 2.4?
- ¿Mantener, mejorar, o eliminar?
- ¿Qué cambios necesita?

🔬

