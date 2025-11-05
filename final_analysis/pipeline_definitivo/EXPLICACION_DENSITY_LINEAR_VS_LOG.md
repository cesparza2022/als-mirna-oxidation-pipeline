# 🔍 ¿POR QUÉ LA DENSIDAD SE VE DIFERENTE EN LINEAR vs LOG?

**Fecha:** 2025-10-24  
**Tu pregunta:** "¿Por qué en uno se ve más densidad en ALS y en el otro menos?"

---

## 🎯 **RESPUESTA CORTA:**

**Sí, dicen lo mismo**, pero la **compresión/expansión del eje X** hace que las curvas se vean diferentes.

Es como ver el mismo paisaje con lentes diferentes:
- Linear scale = lentes normales
- Log scale = lentes de gran angular (comprime distancias grandes)

---

## 📐 **EXPLICACIÓN TÉCNICA:**

### **El problema con LOG SCALE:**

Cuando usas `scale_x_log10()`, el eje X se **COMPRIME** de forma no uniforme:

```
LINEAR SCALE (distancias iguales):
|----1----|----2----|----3----|----4----|----5----|

LOG SCALE (distancias comprimidas):
|--1--|---2---|------3------|-----------4-----------|
      ↑ comprimido            ↑ expandido
```

**En escala log:**
- Distancia entre 1 y 2 = 0.3 unidades (log₁₀(2) - log₁₀(1))
- Distancia entre 2 y 4 = 0.3 unidades (log₁₀(4) - log₁₀(2))
- Distancia entre 4 y 8 = 0.3 unidades (log₁₀(8) - log₁₀(4))

**Todas iguales en log, pero muy diferentes en linear!**

---

## 🎨 **EFECTO EN LAS CURVAS DE DENSIDAD:**

### **CURVA DE DENSIDAD:**
```
Density(x) = número de muestras cerca de x / total de muestras
```

**PERO** la densidad se calcula en el **espacio transformado**.

### **En LINEAR scale:**
```
Datos ALS concentrados en 1-3 (rango estrecho)
→ Muchas muestras en espacio pequeño
→ DENSIDAD ALTA (pico alto)
```

### **En LOG scale:**
```
Datos ALS: log(1)=0 a log(3)=0.48 (rango expandido en log)
→ Las mismas muestras ahora ocupan MÁS espacio en la escala log
→ DENSIDAD BAJA (pico más bajo)
```

---

## 📊 **EJEMPLO NUMÉRICO:**

Imagina 10 muestras ALS con valores:
```
1.5, 1.8, 2.0, 2.1, 2.2, 2.3, 2.5, 2.8, 3.0, 10.0
```

### **LINEAR SCALE:**
```
Rango: 1.5 a 3.0 = 1.5 unidades
9 muestras en 1.5 unidades → DENSIDAD ALTA
1 muestra en 7.0 unidades (3-10) → DENSIDAD BAJA
```

**Resultado:** Pico alto en 2-3, cola larga hacia 10

### **LOG SCALE:**
```
Rango log: log(1.5)=0.18 a log(3.0)=0.48 = 0.30 unidades
Las mismas 9 muestras ahora en 0.30 unidades log
→ Pero la escala visual es diferente
```

**Resultado:** Pico MÁS ANCHO y BAJO (mismas muestras, escala diferente)

---

## 🔬 **¿POR QUÉ ALS SE VE "MÁS DENSO" EN LINEAR Y "MENOS" EN LOG?**

### **DATOS REALES DE TU ANÁLISIS:**

**ALS:**
- Mediana: 2.19
- Q25-Q75: 1.57 - 3.06
- Rango: 0.397 - 23.0

**Observa:**
- **75% de los datos** están entre 1.57 y 3.06 (rango de 1.5 unidades)
- **25% restante** se extiende de 3.06 a 23.0 (rango de 20 unidades!)

### **EN LINEAR SCALE:**
```
Eje X: [0 -------- 5 -------- 10 -------- 15 -------- 20 -------- 25]
        ↑ 75% de ALS aquí (1.57-3.06)
        (espacio pequeño)
        → DENSIDAD MUY ALTA

                                                    ↑ 25% restante
                                                    (espacio MUY grande)
                                                    → densidad baja (cola)
```

**Resultado:** Pico ALTO y ESTRECHO + cola larga

### **EN LOG SCALE:**
```
Eje X (log): [0.1 -- 1 ------ 10 ----------- 100]
              ↑ 75% de ALS (1.57-3.06)
              En log: 0.20 a 0.49
              (proporcionalmente MÁS espacio en la escala visual)
              → DENSIDAD MENOR (visualmente)
```

**Resultado:** Pico más BAJO y ANCHO

---

## 🎯 **LA CLAVE:**

**NO es que haya más o menos muestras.**

**Es que la escala LOG "estira" los valores bajos y "comprime" los valores altos:**

```
LINEAR:
0----1----2----3----4----5----10----15----20----25
|<- aquí está todo ALS ->|

LOG:
0.1---1--------10----------100
    |<- aquí está todo ALS expandido ->|
```

---

## 💡 **ENTONCES, ¿SON IGUALES O NO?**

### **SÍ, representan los MISMOS DATOS:**
- Mismas muestras
- Mismos valores
- Misma distribución

### **PERO se VEN diferentes porque:**
- El eje X está transformado
- La densidad se calcula en el espacio transformado
- Lo que cambia es la **"anchura"** relativa del pico

---

## 📊 **ANALOGÍA SIMPLE:**

Imagina una calle con 10 casas:

**LINEAR (vista normal):**
```
Casa1--Casa2--Casa3--Casa4--Casa5--Casa6--Casa7--Casa8--Casa9---[espacio vacío]---Casa10

← 9 casas juntas →                                              ← 1 casa lejos →
  DENSIDAD ALTA                                                  densidad baja
```

**LOG (vista con teleobjetivo que comprime distancias):**
```
Casa1-Casa2-Casa3-Casa4-Casa5-Casa6-Casa7-Casa8-Casa9-Casa10

← todas más "espaciadas" visualmente →
  densidad MEDIA en todas
```

**Siguen siendo las mismas 10 casas**, pero las **ves distribuidas diferente**.

---

## 🤔 **¿CUÁL ES "CORRECTA"?**

**AMBAS son correctas**, pero muestran cosas diferentes:

### **LINEAR scale:**
- ✅ Muestra densidad "real" en valores absolutos
- ✅ Mejor para distribuciones normales o simétricas
- ✅ Más intuitiva para el lector
- ⚠️ Problema: Si hay outliers muy alejados, la mayoría se "aplasta" al inicio

### **LOG scale:**
- ✅ Mejor para datos con cola larga (como ALS)
- ✅ Da igual "peso visual" a valores bajos y altos
- ✅ Muestra mejor las diferencias en todo el rango
- ⚠️ Problema: Menos intuitiva, difícil de interpretar

---

## 🎯 **PARA TU CASO ESPECÍFICO:**

### **Tus datos ALS:**
- Muy sesgados (skewness = 5.26)
- Cola larga a la derecha
- 75% entre 1.57-3.06, pero máximo es 23.0

### **Recomendación:**

**Para publicación científica:**
- Usa **LOG scale** si quieres mostrar que ALS tiene cola larga
- Usa **LINEAR scale** si quieres enfatizar que Control tiene valores más altos

**Para consistencia con Fig 2.1:**
- Usa **LINEAR scale** (como ya decidiste para Fig 2.1)

**Mi sugerencia final:**
- **LINEAR** para este paper
- Incluye una nota: "ALS distribution is right-skewed (skewness=5.26)"
- Así el lector sabe que la distribución NO es normal

---

## ✅ **RESUMEN:**

1. **Sí, dicen lo mismo** (mismos datos)
2. **Se ven diferentes** por la transformación del eje X
3. **Linear scale**: Muestra densidad "real", pico alto en ALS
4. **Log scale**: Expande valores bajos, pico más bajo pero más ancho
5. **Para ti**: Linear es mejor (consistencia + interpretación)

---

**¿Te quedó claro por qué se ven diferentes pero son los mismos datos?** 🤔

**Si sí, ¿aprobamos la versión LINEAR y seguimos?** 🚀

