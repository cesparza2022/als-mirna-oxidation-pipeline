# ✅ NUEVA FIGURA 2.5 - DIFFERENTIAL HEATMAP

**Fecha:** 2025-10-24  
**Generada con TODOS los 301 miRNAs**

---

## 🎯 **QUÉ MUESTRA:**

**Pregunta:**
"¿Qué miRNAs y posiciones muestran diferencias entre ALS y Control?"

**Método:**
```
Para cada celda:
   Valor = VAF_ALS - VAF_Control

Interpretación:
   Positivo (rojo) → ALS tiene más G>T
   Negativo (azul) → Control tiene más G>T
   Cero (blanco) → Sin diferencia
```

---

## 📊 **ESTRUCTURA:**

**Dimensiones:**
- **301 filas** (TODOS los miRNAs con G>T en seed)
- **22 columnas** (posiciones 1-22)
- Sin nombres (demasiados para legibilidad)

**Escala de color:**
```
Azul oscuro ← → Blanco → → Rojo oscuro
(Control mayor)  (igual)  (ALS mayor)
```

**Elementos:**
- Seed region marcada (líneas azules, pos 2-8)
- Escala simétrica centrada en 0

---

## 🔥 **HALLAZGOS DEL ANÁLISIS:**

### **1. Patrón global:**
```
Mean differential: -0.000288
→ Control > ALS en promedio ✅
→ Consistente con Fig 2.1-2.2
```

### **2. Distribución:**
```
60.1% de celdas: ALS > Control (levemente)
36.2% de celdas: Control > ALS
```

**Pero el promedio es negativo (Control mayor) porque:**
- Las celdas "Control > ALS" tienen MAYOR magnitud
- Consistente con burden global

---

### **3. Posiciones con mayor diferencia:**

**Elevadas en ALS:**
- Posición 12: +0.000171
- Posición 10: +0.000126
- Posición 18: +0.000109

**Elevadas en Control:**
- **Posición 16: -0.00243** (muy alto!)
- **Posición 22: -0.00156**
- Posición 17: -0.000875

**Observación:**
- Diferencias mayores en posiciones NO-seed (16, 22, 17)
- Consistente con hallazgo "seed protegida"

---

### **4. Seed vs Non-seed:**
```
Seed (2-8): Mean diff = -0.000087
Non-seed: Mean diff = -0.000415

→ Mayor diferencial en NON-SEED (5x más)
→ Confirma: Seed está protegida
```

---

### **5. miRNAs con mayor diferencial:**

**ALS > Control:**
- hsa-miR-6866-5p: +0.00585
- hsa-miR-4781-5p: +0.00568
- hsa-miR-4488: +0.00412

**Control > ALS:**
- **hsa-miR-6133: -0.0521** (ENORME!)
- hsa-miR-1908-3p: -0.0207
- hsa-miR-4669: -0.0171

---

## 💡 **INTERPRETACIÓN:**

### **Hallazgo importante:**

**miR-6133 tiene diferencial MASIVO (Control > ALS, -0.052)**

Este miRNA puede ser uno de los responsables de que Control > ALS globalmente!

**Verificar:**
- ¿Este miRNA apareció en volcano (Fig 2.3)?
- ¿Es uno de los 8 significativos en ALL?

---

## 🎨 **COMPARACIÓN CON FIG 2.4:**

```
┌──────────┬─────────────────┬──────────────────┐
│ Aspecto  │ Fig 2.4A        │ Fig 2.5 (nueva)  │
├──────────┼─────────────────┼──────────────────┤
│ Valores  │ VAF absolutos   │ Diferencia       │
│          │ (ALS y Control  │ (ALS - Control)  │
│          │ separados)      │                  │
├──────────┼─────────────────┼──────────────────┤
│ Pregunta │ ¿Cuánto G>T     │ ¿Dónde ALS >     │
│          │ hay?            │ Control?         │
├──────────┼─────────────────┼──────────────────┤
│ Filas    │ 301 × 2 paneles │ 301 (una vez)    │
├──────────┼─────────────────┼──────────────────┤
│ Compara  │ Visual (2       │ Directo (un      │
│ grupos   │ paneles)        │ heatmap)         │
└──────────┴─────────────────┴──────────────────┘
```

**SON COMPLEMENTARIAS:**
- 2.4A: Magnitudes absolutas
- 2.5: Diferencias relativas

---

## ✅ **VENTAJAS DE LA NUEVA FIG 2.5:**

1. ✅ Usa TODOS los 301 miRNAs (no solo 50)
2. ✅ Compara directamente ALS vs Control
3. ✅ Sin duplicación (301 filas, no 602)
4. ✅ Interpretación clara (diferencia directa)
5. ✅ Identifica miRNAs con mayor diferencial
6. ✅ Consistente con hallazgo global (Control > ALS)
7. ✅ Profesional y en inglés

---

## 🔍 **HALLAZGO ADICIONAL:**

**hsa-miR-6133 domina la diferencia:**
- Differential: -0.052 (Control MUCHO mayor)
- Este miRNA podría explicar por qué Control > ALS globalmente

**Siguiente paso:**
- Verificar si miR-6133 es uno de los 9 significativos del volcano ALL
- Investigar su función biológica

---

**He abierto la nueva FIG_2.5_DIFFERENTIAL_ALL301_PROFESSIONAL.png**

**¿Te gusta esta versión?**
- Usa TODOS los 301 miRNAs ✅
- Compara directamente grupos ✅
- Identifica miR-6133 como candidato clave

**¿Aprobamos y continuamos con Fig 2.6?** 🚀

