# 🎯 CLARIFICACIÓN EXACTA - Panel E Metrics

**Fecha:** 2025-10-24

---

## 📊 **LAS 3 MÉTRICAS EXACTAS:**

### **MÉTRICA 1: Total de copias de miRNAs con G en esa posición**
```r
Para posición 6:
  1. Identificar TODOS los miRNAs que tienen G en pos 6
     (detectado porque vemos mutaciones G>X: GT, GC, GA)
  
  2. Para cada uno de esos miRNAs:
     Sumar TODAS sus cuentas en TODAS las muestras
     (NO solo las cuentas de la fila con la mutación, 
      sino TODAS las cuentas de ese miRNA en el dataset)
  
  3. Sumar todo
  
Ejemplo:
  - miR-let-7a tiene G en pos 6 (vemos 6:GT) 
    → Buscar miR-let-7a en TODAS las filas
    → Sumar todas sus cuentas (ej. 50,000 total)
  - miR-9 tiene G en pos 6 (vemos 6:GC)
    → Buscar miR-9 en TODAS las filas
    → Sumar todas sus cuentas (ej. 20,000 total)
  
  Total pos 6: 70,000 copias de miRNAs con G
```

**Y-axis (principal):** Total miRNA copies with G at position  
**Escala:** Absoluta (puede ser log si es necesario)

---

### **MÉTRICA 2: Suma de SNVs G>T EN ESA POSICIÓN ESPECÍFICA**
```r
Para posición 6:
  1. Filtrar SOLO las filas que son "6:GT"
  
  2. Sumar las cuentas de ESAS filas específicas
  
Ejemplo:
  - miR-let-7a 6:GT → 1,200 cuentas
  - miR-9 6:GT → 500 cuentas
  - miR-196a 6:GT → 300 cuentas
  
  Total SNVs G>T en pos 6: 2,000 cuentas
```

**⚠️ IMPORTANTE:** Solo cuentas de la posición específica (6:GT)  
**NO** todas las mutaciones G>T de esos miRNAs

**Representación:** Color rojo (intensidad o escala secundaria)

---

### **MÉTRICA 3: Cantidad de miRNAs únicos con G en esa posición**
```r
Para posición 6:
  Contar cuántos miRNAs DIFERENTES tienen alguna mutación G>X en pos 6
  
Ejemplo:
  - miR-let-7a (tiene 6:GT) ✓
  - miR-9 (tiene 6:GC) ✓
  - miR-196a (tiene 6:GT) ✓
  ... 99 miRNAs en total
```

**Representación:** Tamaño de bubble (o color, o número)

---

## 🎨 **TU PROPUESTA DE BUBBLE PLOT:**

```
X-axis: Posición (1-22)
Y-axis: Total copias de miRNAs con G (MÉTRICA 1)
Bubble SIZE: Número de miRNAs únicos (MÉTRICA 3)
Bubble COLOR (intensidad roja): Cuentas de SNVs G>T específicos (MÉTRICA 2)
```

**Interpretación:**
- **Bubble alto y grande y rojo oscuro** = 
  - Muchas copias de miRNAs con G (alto)
  - Muchos miRNAs diferentes (grande)
  - Muchas mutaciones G>T específicas (rojo)
  - = HOTSPOT COMPLETO

- **Bubble bajo, pequeño, rojo claro** = 
  - Pocas copias
  - Pocos miRNAs
  - Pocas mutaciones
  - = Posición poco importante

---

## ✅ **CONFIRMACIÓN:**

**¿Esto es correcto?**

**MÉTRICA 1 (Y-axis):**
- Sumar TODAS las cuentas de cada miRNA que tiene G en esa posición
- Ejemplo: Si miR-let-7a tiene G en pos 6, sumo TODAS las cuentas de let-7a de TODAS sus filas
- ✅ SÍ o ❌ NO?

**MÉTRICA 2 (Color rojo):**
- Sumar SOLO las cuentas de las filas "Pos:GT" específicas
- Ejemplo: Solo las filas "6:GT", NO otras posiciones del mismo miRNA
- ✅ SÍ o ❌ NO?

**MÉTRICA 3 (Tamaño):**
- Contar miRNAs únicos con G en esa posición
- ✅ SÍ o ❌ NO?

---

## 🎨 **OPCIONES ADICIONALES:**

### **Variante 1: Bubble plot con barra de fondo**
```
- Barras grises de fondo (Métrica 1)
- Bubbles encima (tamaño = Métrica 3, color = Métrica 2)
- Más claro que solo bubbles
```

### **Variante 2: Dual-axis mejorado**
```
- Barras (Métrica 1)
- Línea roja (Métrica 2)
- Grosor de línea = Métrica 3
- Tres métricas, dos elementos visuales
```

### **Variante 3: Barras con dos capas**
```
- Barra verde (Métrica 1 - total G)
- Barra roja superpuesta (Métrica 2 - G>T)
- Número arriba (Métrica 3 - miRNAs)
- Stacked o overlapping
```

**¿Cuál de estas variantes te atrae?**

---

## ❓ **ÚLTIMA PREGUNTA CRÍTICA:**

**Para MÉTRICA 1**, cuando dices "copias de miRNAs con G":

**¿Quieres?**

**A) Suma de TODAS las cuentas del miRNA completo**
```
miR-let-7a tiene G en pos 6
→ Sumar TODAS las cuentas de let-7a (todas sus filas: 6:GT, 7:AC, 8:TG, etc.)
→ Total: 50,000
```

**B) Suma SOLO de las filas con G en esa posición**
```
miR-let-7a tiene G en pos 6
→ Sumar SOLO las cuentas de las filas con G en pos 6: 6:GT, 6:GC, 6:GA
→ Total: 1,500
```

**Opción A** = Cuántas copias totales del miRNA (que sabemos tiene G ahí)  
**Opción B** = Cuántas copias con variantes de G en esa posición

**¿Cuál tiene más sentido biológicamente?**

Yo creo que **Opción B** es más precisa (solo las copias donde vimos G mutarse).

Confirma y genero la versión final! 🚀

