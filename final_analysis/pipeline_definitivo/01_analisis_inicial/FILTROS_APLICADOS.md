# FILTROS APLICADOS AL DATASET

## 🔄 TRANSFORMACIONES Y FILTROS DETALLADOS

### **DATASET ORIGINAL**
```
Archivo: miRNA_count.Q33.txt
Dimensiones: 68,968 filas × 832 columnas
Contenido: Conteos de SNVs en miRNAs
```

**Características:**
- **Filas:** Cada fila puede contener **mutaciones múltiples** en `pos:mut` (ej. "4:TC,18:TC")
- **Columnas:** 
  - 2 metadata: `miRNA name`, `pos:mut`
  - ~415 count columns: Conteos de SNVs por muestra
  - ~415 total columns: Totales de miRNA por muestra (terminan en `(PM+1MM+2MM)`)

**FILTRO PREVIO (YA APLICADO EN EL ARCHIVO ORIGINAL):**
- ✅ **Q33:** Calidad de secuenciación mínima (Phred score ≥ 33)
  - Probabilidad de error < 0.05%
  - **Este filtro YA viene aplicado en el archivo que recibimos**

---

## 📋 FILTROS QUE HEMOS APLICADO NOSOTROS:

### **FILTRO 1: SPLIT-COLLAPSE** ✅
**Objetivo:** Separar mutaciones múltiples y consolidar duplicados

**¿Qué hace?**
```r
# SPLIT: Separar filas con múltiples mutaciones
# Ejemplo:
# Antes: hsa-let-7a-3p | 4:TC,18:TC | counts...
# Después: 
#   hsa-let-7a-3p | 4:TC  | counts...
#   hsa-let-7a-3p | 18:TC | counts...

# COLLAPSE: Sumar counts de SNVs duplicados (mismo miRNA + posición)
# - Suma counts de SNVs
# - Mantiene totales ORIGINALES (NO suma)
```

**Resultado:**
- **Antes:** 68,968 filas
- **Después split:** 111,785 filas (↑ 62%)
- **Después collapse:** 29,254 filas (↓ 58% del original)

**¿Qué eliminó?**
- ❌ Nada. Solo reorganiza los datos
- ✅ Convierte mutaciones múltiples en filas individuales
- ✅ Consolida duplicados sumando sus counts

**Criterio de filtrado:** NINGUNO (es una transformación, no un filtro)

---

### **FILTRO 2: CÁLCULO DE VAFs** ✅
**Objetivo:** Calcular frecuencias alélicas variantes

**¿Qué hace?**
```r
# VAF = count / total
# Para cada muestra:
# VAF_muestra = count_SNV / total_miRNA
```

**Resultado:**
- **Antes:** 29,254 filas × 832 columnas
- **Después:** 29,254 filas × 1,247 columnas
- **Nuevas columnas:** ~415 columnas VAF (una por muestra)

**¿Qué eliminó?**
- ❌ Nada. Solo añade columnas nuevas

**Criterio de filtrado:** NINGUNO (es un cálculo, no un filtro)

---

### **FILTRO 3: FILTRADO VAF > 50%** ⚠️
**Objetivo:** Eliminar VAFs artificialmente altos (probable error técnico)

**¿Qué hace?**
```r
# Si VAF > 0.5 (50%), convertir a NaN
# Justificación: VAFs > 50% en miRNAs circulantes son 
# biológicamente improbables (indicarían variante mayoritaria)
```

**Resultado:**
- **Antes:** 29,254 filas × 1,247 columnas
- **Después:** 29,254 filas × 1,247 columnas (mismo número de filas)
- **NaNs generados:** 210,118 valores convertidos a NaN
  - Promedio: 506.31 NaNs por muestra
  - Máximo: 2,000+ NaNs en algunas muestras

**¿Qué eliminó?**
- ❌ NO elimina filas
- ✅ Convierte VAFs > 50% a NaN (valores inválidos)
- ⚠️ Estos valores NO se usan en análisis posteriores

**Criterio de filtrado:** 
```
VAF > 0.5 → NaN
```

**Impacto:**
- **En total:** 0.51% de valores convertidos a NaN
- **En G>T:** 0.71% de valores convertidos a NaN (6,466 NaNs)

---

## 📌 **FILTROS QUE NO HEMOS APLICADO (AÚN)**

### **Filtros típicos en análisis de SNVs que NO hemos usado:**

❌ **Filtro de counts mínimos**
- Ejemplo: `count < 10` → eliminar
- Estado: NO APLICADO

❌ **Filtro de totales mínimos**
- Ejemplo: `total < 100` → eliminar
- Estado: NO APLICADO

❌ **Filtro de VAF mínimo**
- Ejemplo: `VAF < 0.001` (0.1%) → eliminar
- Estado: NO APLICADO

❌ **Filtro de muestras con datos válidos**
- Ejemplo: Eliminar SNVs con < 10 muestras válidas
- Estado: NO APLICADO

❌ **Filtro de outliers**
- Ejemplo: Eliminar muestras con perfil anómalo
- Estado: NO APLICADO

❌ **Filtro de batch effect**
- Ejemplo: Eliminar muestras de lotes problemáticos
- Estado: NO APLICADO

❌ **Filtro por región funcional**
- Ejemplo: Analizar solo región semilla
- Estado: NO APLICADO

❌ **Filtro por tipo de mutación**
- Ejemplo: Analizar solo G>T
- Estado: NO APLICADO (aunque sí hacemos análisis separados)

---

## 🎯 **DATASET ACTUAL: ¿QUÉ CONTIENE?**

### **Filas (SNVs):**
```
Total: 29,254 SNVs únicos
├── Con mutaciones G>T: 2,193 (7.5%)
├── Con otras mutaciones: 27,061 (92.5%)
└── Distribución por región:
    ├── Semilla: 6,959 SNVs (23.8%)
    ├── Central: 9,649 SNVs (33.0%)
    ├── 3': 9,871 SNVs (33.7%)
    └── Otro: 2,775 SNVs (9.5%)
```

### **Columnas (Variables):**
```
Total: 1,247 columnas
├── Metadata: 2 (miRNA name, pos:mut)
├── Counts: ~415 (conteos de SNVs)
├── Totales: ~415 (totales de miRNA, NO MODIFICADOS)
└── VAFs: ~415 (frecuencias alélicas calculadas)
    └── Con NaNs: 210,118 valores (VAF > 50%)
```

### **Muestras:**
```
Total: 415 muestras
├── ALS: 313 muestras (75.4%)
│   ├── Enrolment: mayoría
│   └── Longitudinal: seguimiento
└── Control: 102 muestras (24.6%)
```

### **Valores:**
```
Total de observaciones: ~12 millones (29,254 SNVs × 415 muestras)
├── Valores válidos: ~11.9 millones
├── NaNs (VAF > 50%): 210,118 (1.7%)
└── Ceros (sin mutación): ~10 millones (83%)
```

---

## 🔍 **CARACTERÍSTICAS IMPORTANTES DEL DATASET ACTUAL:**

### **Lo que SÍ tiene:**
✅ Todos los SNVs detectados (sin eliminar ninguno)
✅ Todas las muestras (sin eliminar ninguna)
✅ Todos los miRNAs (sin eliminar ninguno)
✅ VAFs calculados correctamente (count/total)
✅ Totales de miRNA preservados (NO modificados)

### **Lo que NO tiene (filtrado):**
❌ VAFs > 50% (convertidos a NaN)
❌ Ningún SNV eliminado por counts bajos
❌ Ninguna muestra eliminada por calidad
❌ Ningún miRNA eliminado

### **Lo que NO sabemos aún:**
❓ Distribución de counts (¿hay muchos counts muy bajos?)
❓ Distribución de totales (¿hay muestras con muy pocos reads?)
❓ Calidad por muestra (¿hay muestras problemáticas?)
❓ Efecto de batch (¿hay diferencias entre lotes?)
❓ Outliers (¿hay muestras o SNVs anómalos?)

---

## 💡 **RESUMEN EJECUTIVO:**

**Con qué trabajamos ahora:**
> Un dataset de **29,254 SNVs únicos** en **1,728 miRNAs**, medidos en **415 muestras** (313 ALS, 102 Control), con VAFs calculados y **solo VAFs > 50% eliminados**.

**Filtros aplicados:**
> **MÍNIMOS.** Solo hemos aplicado:
> 1. Split-collapse (transformación)
> 2. Cálculo de VAFs (transformación)
> 3. Filtrado VAF > 50% (filtro muy permisivo)

**¿Por qué tan permisivos?**
> Porque estamos en **FASE EXPLORATORIA**. Queremos ver TODO el dataset antes de decidir qué filtrar.

---

## 🚀 **PRÓXIMOS PASOS PROPUESTOS:**

### **Opción A: Seguir explorando SIN más filtros**
- Continuar con análisis de patrones
- Incorporar metadatos clínicos
- Identificar outliers y problemas

### **Opción B: Aplicar filtros de calidad AHORA**
- Filtrar counts bajos (ej. count < 10)
- Filtrar totales bajos (ej. total < 100)
- Eliminar muestras problemáticas
- Luego repetir análisis con dataset filtrado

### **Opción C: Análisis paralelo**
- Mantener dataset actual para exploración
- Crear dataset filtrado para análisis estadísticos
- Comparar resultados

---

**¿Qué prefieres hacer?** 
1. ¿Seguir con el dataset actual (muy permisivo) e incorporar metadatos?
2. ¿Aplicar filtros de calidad adicionales primero?
3. ¿Hacer análisis exploratorio de calidad de datos antes de decidir filtros?








