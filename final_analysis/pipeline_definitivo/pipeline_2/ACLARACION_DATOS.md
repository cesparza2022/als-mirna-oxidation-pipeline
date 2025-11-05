# 📊 ACLARACIÓN: EVOLUCIÓN DEL DATASET

## ❓ **¿Por qué hay MÁS SNVs después del procesamiento?**

Esta es una pregunta excelente que refleja una comprensión cuidadosa de los datos. Aquí está la explicación completa:

---

## 📈 **ETAPAS DEL PROCESAMIENTO**

### 1️⃣ **ARCHIVO ORIGINAL: 68,968 entradas**
- **¿Qué son?** Filas en el archivo `miRNA_count.Q33.txt`
- **Estructura:** Cada fila representa un miRNA en una muestra específica
- **Campo `pos:mut`:** Puede contener:
  - Una sola mutación: `7:AT`
  - Múltiples mutaciones: `2:TC,3:AG,4:TC,5:AG,6:CT` (separadas por comas)
  - Sin mutaciones: `PM` (Perfect Match)

**Ejemplo real del archivo:**
```
miRNA name          pos:mut
hsa-let-7a-3p       PM
hsa-let-7a-3p       2:TC,3:AG,4:TC,5:AG,6:CT
hsa-let-7a-2-3p     7:AT
hsa-let-7a-2-3p     18:TC
```

### 2️⃣ **DESPUÉS DEL SPLIT: 111,785 entradas**
- **Proceso:** `separate_rows()` divide las mutaciones múltiples en filas individuales
- **Resultado:** Cada mutación ahora ocupa su propia fila

**El mismo ejemplo después del split:**
```
miRNA name          pos:mut
hsa-let-7a-3p       PM
hsa-let-7a-3p       2:TC
hsa-let-7a-3p       3:AG
hsa-let-7a-3p       4:TC
hsa-let-7a-3p       5:AG
hsa-let-7a-3p       6:CT
hsa-let-7a-2-3p     7:AT
hsa-let-7a-2-3p     18:TC
```

### 3️⃣ **DESPUÉS DEL FILTRADO: 110,199 SNVs válidos**
- **Proceso:** Eliminar entradas "PM" (Perfect Match)
- **Resultado:** Solo mutaciones reales

---

## 🔍 **ANÁLISIS DE LOS NÚMEROS**

| Etapa | Cantidad | Descripción |
|-------|----------|-------------|
| **Raw Entries** | 68,968 | Filas en el archivo original |
| **After Split** | 111,785 | Mutaciones individualizadas (incluye PM) |
| **Valid SNVs** | 110,199 | Mutaciones reales (sin PM) |
| **G>T Mutations** | 8,033 | Mutaciones específicas de interés (7.3%) |

---

## 💡 **¿POR QUÉ ES CORRECTO?**

**El aumento de 68,968 → 110,199 NO es un error, sino el resultado esperado de:**
1. **Descomprimir datos comprimidos**: Las filas con múltiples mutaciones se "expanden"
2. **Formato más analizable**: Cada SNV individual ahora es una fila independiente
3. **Filtrado de ruido**: Eliminación de entradas "PM" que no son mutaciones

---

## 📐 **CÁLCULO PROMEDIO**

Si dividimos el total de SNVs individuales entre las entradas originales:
```
110,199 SNVs válidos / 68,968 entradas originales ≈ 1.60 mutaciones por entrada
```

Esto significa que, **en promedio**, cada entrada del archivo original contenía aproximadamente **1.6 mutaciones** (considerando que muchas entradas tienen `PM` = 0 mutaciones, y otras tienen múltiples).

---

## 🎯 **CONCLUSIÓN**

**Las etiquetas actualizadas en la Figura 1 ahora reflejan esto correctamente:**
- **"Raw Entries (Original File)"** = 68,968 filas del archivo
- **"Individual SNVs (Processed)"** = 110,199 mutaciones únicas procesadas

**Esto es científicamente correcto y representa el procesamiento estándar de datos de secuenciación donde múltiples variantes pueden ser detectadas en una misma lectura o región.**

