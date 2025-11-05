# 🎯 MÉTRICAS A DEFINIR - ANTES DE CONTINUAR

## ✅ **LO QUE SÍ ESTÁ CLARO (No cambiar):**

### **Tier 1 (Figuras 1-2) - Descriptivo sin grupos:**

**FIGURA 1:**
- ✅ Panel A Left: **68,968 rows** → **110,199 SNVs** (claro)
- ✅ Panel A Right: **Count** de mutation types (claro)
- ✅ Panel B: **Count** de G>T por posición (claro)
- ✅ Panel D: **Count** de G>T por miRNA (claro)

**FIGURA 2:**
- ✅ Panel A: Correlación G-content (claro concepto, mejorar label)

---

## ❓ **LO QUE NECESITAMOS DEFINIR:**

### **PREGUNTA 1: ¿Qué color para G>T en Tier 1?**

**Tu feedback:** "G>T es rojo porque es oxidación"

**Opciones:**
- **A) ROJO en todo** (Tier 1 y Tier 2)
  - Ventaja: Consistencia total
  - Desventaja: En Tier 1 no hay grupos, rojo puede confundir
  
- **B) Naranja en Tier 1, Rojo en Tier 2**
  - Ventaja: Rojo queda reservado para ALS
  - Desventaja: Inconsistencia entre figuras

**MI SUGERENCIA:** Opción A - ROJO siempre para G>T
- Es oxidación en ambos casos
- Tier 1: Rojo = oxidación (proceso)
- Tier 2: Rojo = ALS (tiene más oxidación)

**¿Estás de acuerdo?** ✅ = Rojo siempre, ❌ = Naranja Tier 1

---

### **PREGUNTA 2: Panel D de Figura 2 - ¿Qué mostrar?**

**Opciones:**

**A) Eliminar (es repetitivo con Fig 1 Panel B)**
- Usar espacio para algo más útil

**B) Cambiar a "Positional fraction of G>T"**
```r
Eje Y: "% of total G>T"
Muestra: Dónde se concentran los G>T
Ejemplo: Posición 22 = 15.8% de todos los G>T
```

**C) Cambiar a "G>T enrichment by region"**
```r
Comparación: Seed vs Non-Seed
Barras: % G>T en seed vs % G>T en non-seed
Más informativo que solo counts
```

**¿Cuál prefieres?** A, B, o C

---

### **PREGUNTA 3: Figura 3 Panel B - ¿Count o Fraction?**

**Tu ejemplo usa:** "Positional fraction"

**Interpretación:**
```r
# Por cada posición:
Numerador: Count de G>T en esa posición (en ese grupo)
Denominador: Total de SNVs en esa posición (en ese grupo)
Resultado: Fracción (%)

Ejemplo:
Posición 5 en ALS: 80 G>T / 500 total SNVs = 16%
Posición 5 en Control: 50 G>T / 480 total SNVs = 10.4%
```

**¿Es correcto este entendimiento?** ✅ o ❌

**Si es correcto, significa:**
- NO es VAF (que sería per-sample)
- ES fracción de SNVs que son G>T en esa posición
- Per-group (ALS vs Control)

---

## 📊 **RESUMEN DE DECISIONES PENDIENTES**

```
DECISIÓN 1: Color G>T
├── Opción A: ROJO siempre (#D62728)
└── Opción B: Naranja Tier 1, Rojo Tier 2

DECISIÓN 2: Panel D Figura 2
├── Opción A: Eliminar (repetitivo)
├── Opción B: Positional fraction
└── Opción C: Seed vs Non-seed enrichment

DECISIÓN 3: Panel B Figura 3 métrica
├── Opción A: Positional fraction (G>T / Total SNVs) por grupo
└── Opción B: Simple count por grupo
```

---

## ✅ **CORRECCIONES QUE HARÉ SIN IMPORTAR TUS DECISIONES:**

1. ✅ Labels más explícitos en TODAS las figuras
2. ✅ "rows", "SNVs", "count", "fraction" claramente distinguidos
3. ✅ Figura 2 Panel A: "Number of G nucleotides in seed region (2-8)"
4. ✅ Subtítulos explicativos en cada panel
5. ✅ Unidades en ejes (%, count, etc.)

---

## 🎯 **LO QUE NECESITO DE TI:**

**Por favor responde:**

1. **G>T color:** ¿ROJO siempre? (mi recomendación: SÍ)

2. **Panel D Figura 2:** ¿Opción A, B, o C?

3. **Panel B Figura 3:** ¿Mi interpretación de "positional fraction" es correcta?
   - G>T en posición X / Total SNVs en posición X (por grupo)

**Con estas 3 respuestas, corrijo TODO en ~30 minutos** ✅

---

## 📝 **MIENTRAS TANTO**

Estoy guardando TODO en:
- `DEFINICIONES_METRICAS.md` (explicaciones detalladas)
- `METRICAS_A_DEFINIR.md` (este documento - decisiones)
- `CLARIFICACIONES_Y_CORRECCIONES.md` (feedback tuyo)

**TODO organizado y listo para implementar correcciones** 🚀

