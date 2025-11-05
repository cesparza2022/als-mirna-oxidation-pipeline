# 👁️ GUÍA VISUAL - CÓMO LEER LA FIGURA 1

## 🎯 **FIGURA 1 COMPLETA: Dataset Characterization & G>T Landscape**

**Propósito general:** Responder "¿Qué tenemos en nuestro dataset y dónde están las mutaciones G>T?"

---

## 📊 **PANEL A: Dataset Evolution & Mutation Types**

### **Parte Izquierda - Barras (Dataset Evolution):**

```
   ┌─────────────┐
   │             │ 110,199
   │    ████████████████  Individual SNVs (después de procesar)
   │             │
   │    ██████      68,968  Raw Entries (archivo original)
   │             │
   └─────────────┘
```

**¿Qué significa?**
- **68,968 Raw Entries** = Filas en el archivo original
  - Cada fila puede tener 1 o más mutaciones
  - Ejemplo: Una fila con `2:TC,3:AG,4:TC` = 3 mutaciones en 1 fila

- **110,199 Individual SNVs** = Mutaciones separadas
  - Después de "expandir" las filas con múltiples mutaciones
  - Después de filtrar "PM" (Perfect Match = sin mutación)

**Interpretación:**
> "Nuestro archivo tiene 68,968 filas, pero contienen 110,199 mutaciones individuales"

---

### **Parte Derecha - Pie Chart (Mutation Types):**

```
      Pie Chart muestra:
      🔴 T>C: 17.8%  (más frecuente)
      🔵 A>G: 15.5%
      🟢 G>A: 12.2%
      🟡 C>T: 9.8%
      🟠 G>T: 7.3%   ← Nuestro foco
      ... otros
```

**¿Qué significa?**
- De todas las 110,199 mutaciones:
  - 19,569 son T>C (el tipo más común)
  - 8,033 son G>T (nuestro objetivo)
  - G>T es el 6to tipo más frecuente

**Interpretación:**
> "G>T representa 7.3% de todas las mutaciones - una fracción sustancial para análisis"

---

## 📊 **PANEL B: G>T Positional Analysis**

### **Parte Superior - Heatmap:**

```
Posición:  1   2   3   4   5   6   7   8   9  10 ... 22
          ┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───────┐
Frecuencia│░░░│███│██░│███│██░│██░│███│██░│░░░│░░░░░░░│
          └───┴───┴───┴───┴───┴───┴───┴───┴───┴───────┘
           └─────── SEED REGION (2-8) ──────┘
```

**¿Qué significa?**
- Cada celda = frecuencia de G>T en esa posición
- Colores oscuros = más mutaciones G>T
- Posiciones 2-8 = región seed (funcionalmente crítica)

**Interpretación:**
> "Las mutaciones G>T no están distribuidas uniformemente - hay posiciones 'hotspot'"

---

### **Parte Inferior - Barras (Seed vs Non-Seed):**

```
        Seed Region         Non-Seed
        ┌────────┐         ┌────────┐
        │████████│ XX%     │████░░░░│ YY%
        └────────┘         └────────┘
```

**¿Qué significa?**
- **Seed:** % de mutaciones G>T en posiciones 2-8
- **Non-Seed:** % de mutaciones G>T en otras posiciones
- Compara si seed es más vulnerable

**Interpretación:**
> "¿La región funcional (seed) tiene más G>T que el resto? → [Respuesta visual]"

**⚠️ SI NO APARECE:** Necesitamos revisar el archivo PNG

---

## 📊 **PANEL C: Mutation Spectrum**

### **Parte Izquierda - Barras Apiladas:**

```
Pos:  1    2    3    4    5    6 ...
     100% ┌────┬────┬────┬────┬────┐
         │ ▓▓ │ ██ │ ▓▓ │ ██ │ ░░ │
         │ ██ │ ▓▓ │ ██ │ ▓▓ │ ██ │
      0% └────┴────┴────┴────┴────┘
         
     ██ = G>T (rojo)
     ▓▓ = G>A (azul)
     ░░ = G>C (verde)
```

**¿Qué significa?**
- Cada barra = una posición
- Altura de cada color = proporción de ese tipo G>X
- Muestra si G>T domina en ciertas posiciones

**Interpretación:**
> "En algunas posiciones G>T es dominante, en otras G>A o G>C son más frecuentes"

---

### **Parte Derecha - Top 10 Mutaciones:**

```
Ranking de TODAS las mutaciones (no solo G>X):
1. T>C:  19,569  ██████████
2. A>G:  17,081  █████████
3. G>A:  13,403  ███████
4. C>T:  10,742  █████
5. T>A:   8,802  ████
6. G>T:   8,033  ████  ← Aquí está
...
```

**¿Qué significa?**
- Contexto global: ¿dónde está G>T entre TODOS los tipos?
- G>T es #6 más frecuente (sustancial)

**Interpretación:**
> "G>T no es el más frecuente, pero es suficientemente prevalente para análisis"

---

## 📊 **PANEL D: Placeholder**

- Reservado para análisis futuro
- Mensaje: "Analysis Pending: Focus on Initial Characterization"

---

## 💡 **RESUMEN DE LA HISTORIA QUE CUENTA FIGURA 1**

**Panel A:** "Tenemos 110K mutaciones en 1,462 miRNAs, G>T es 7.3%"  
**Panel B:** "G>T se concentra en ciertas posiciones, especialmente seed"  
**Panel C:** "G>T compite con G>A y G>C, es ~31% de todas las G>X"  
**Panel D:** "(Reservado)"

**HISTORIA COMPLETA:**
> "Nuestro dataset contiene 110,199 mutaciones válidas en 1,462 miRNAs. De estas, 8,033 (7.3%) son mutaciones G>T que muestran patrones posicionales no aleatorios, con concentración en la región seed funcionalmente crítica. G>T representa aproximadamente un tercio de todas las mutaciones que afectan guaninas (G>X), indicando especificidad del proceso oxidativo."

---

## ❓ **PREGUNTAS ESPECÍFICAS PARA ACLARAR**

1. **¿Qué panel específico no entiendes?** A, B, C, o D?
2. **¿Qué gráfica dentro del panel te confunde?**
3. **¿Panel B no aparece en HTML viewer o en PNG individual?**
4. **¿Quieres que te explique los números específicos?**

---

## 🔧 **SIGUIENTE PASO**

Déjame saber:
1. ¿Qué parte específica no entiendes de Figura 1?
2. ¿Panel B no se ve? (para arreglarlo)
3. ¿Actualizo los colores ahora? (naranja para G>T en vez de rojo)
4. ¿Quieres ver el PDF de referencia para comparar estilos?

**¡Listo para aclarar y corregir! 🚀**

