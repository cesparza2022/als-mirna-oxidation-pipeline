# PIPELINE DE TRANSFORMACIONES Y FILTROS (VISUAL)

## 📊 FLUJO COMPLETO DE DATOS

```
┌─────────────────────────────────────────────────────────────────┐
│                    DATASET ORIGINAL                              │
│                  miRNA_count.Q33.txt                             │
│                                                                  │
│  68,968 filas × 832 columnas                                    │
│  1,728 miRNAs únicos                                            │
│                                                                  │
│  FILTRO PREVIO: Q33 (Phred score ≥ 33) ✅                       │
│  └─ Error probability < 0.05%                                   │
│                                                                  │
│  CONTENIDO:                                                     │
│  ├─ Mutaciones múltiples en pos:mut (ej. "4:TC,18:TC")        │
│  ├─ Conteos por muestra (~415 columnas)                        │
│  └─ Totales por muestra (~415 columnas)                        │
└─────────────────────────────────────────────────────────────────┘
                            │
                            │ TRANSFORMACIÓN 1: SPLIT
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                    DESPUÉS DE SPLIT                              │
│                                                                  │
│  111,785 filas × 832 columnas  (+62% filas)                    │
│  1,728 miRNAs únicos                                            │
│                                                                  │
│  CAMBIOS:                                                       │
│  ├─ Cada mutación en su propia fila                            │
│  ├─ pos:mut ahora tiene 1 mutación (ej. "4:TC")                │
│  ├─ Counts DUPLICADOS para cada mutación                       │
│  └─ Totales DUPLICADOS (sin cambios)                           │
│                                                                  │
│  NO SE ELIMINA NADA ✅                                          │
└─────────────────────────────────────────────────────────────────┘
                            │
                            │ TRANSFORMACIÓN 2: COLLAPSE
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                   DESPUÉS DE COLLAPSE                            │
│              (processed_data / split_collapse_data)              │
│                                                                  │
│  29,254 filas × 832 columnas  (-58% vs original)               │
│  1,728 miRNAs únicos                                            │
│                                                                  │
│  CAMBIOS:                                                       │
│  ├─ Agrupa por: miRNA name + pos:mut                           │
│  ├─ SUMA counts de SNVs duplicados                             │
│  ├─ Mantiene PRIMER total (first(.x)) - NO SUMA                │
│  └─ Resultado: 1 fila por SNV único                            │
│                                                                  │
│  NO SE ELIMINA NADA ✅                                          │
│  Solo se consolidan duplicados                                  │
└─────────────────────────────────────────────────────────────────┘
                            │
                            │ TRANSFORMACIÓN 3: CALCULAR VAFs
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                    DESPUÉS DE CALCULAR VAFs                      │
│                        (vaf_data)                                │
│                                                                  │
│  29,254 filas × 1,247 columnas  (+415 columnas)                │
│  1,728 miRNAs únicos                                            │
│                                                                  │
│  CAMBIOS:                                                       │
│  ├─ Nueva columna VAF por cada muestra                         │
│  ├─ VAF_muestra = count / total                                │
│  ├─ Valores: 0 a 1 (0% a 100%)                                 │
│  └─ NAs convertidos a 0                                         │
│                                                                  │
│  ESTRUCTURA:                                                    │
│  ├─ 2 metadata cols                                             │
│  ├─ 415 count cols (originales)                                │
│  ├─ 415 total cols (originales, NO MODIFICADOS)                │
│  └─ 415 VAF cols (NUEVAS)                                       │
│                                                                  │
│  NO SE ELIMINA NADA ✅                                          │
└─────────────────────────────────────────────────────────────────┘
                            │
                            │ FILTRO ÚNICO: VAF > 50%
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│              DATASET FINAL (FILTRADO)                            │
│                   (filtered_data)                                │
│                                                                  │
│  29,254 filas × 1,247 columnas  (IGUAL)                        │
│  1,728 miRNAs únicos                                            │
│                                                                  │
│  FILTRO APLICADO:                                               │
│  └─ VAF > 0.5 → NaN                                             │
│     └─ 210,118 valores convertidos (1.7% del total)            │
│                                                                  │
│  DISTRIBUCIÓN DE NaNs:                                          │
│  ├─ Promedio por muestra: 506.31 NaNs                          │
│  ├─ Máximo en una muestra: 2,000+ NaNs                         │
│  └─ En G>T: 6,466 NaNs (0.71% de VAFs G>T)                     │
│                                                                  │
│  CARACTERÍSTICAS:                                               │
│  ├─ Todas las filas preservadas ✅                              │
│  ├─ Todas las muestras preservadas ✅                           │
│  ├─ Todos los miRNAs preservados ✅                             │
│  ├─ Counts originales intactos ✅                               │
│  ├─ Totales originales intactos ✅                              │
│  └─ Solo VAFs > 50% marcados como inválidos ✅                  │
└─────────────────────────────────────────────────────────────────┘
                            │
                            │ ESTE ES NUESTRO DATASET ACTUAL
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                 ANÁLISIS REALIZADOS                              │
│                                                                  │
│  ✅ Paso 1: Estructura del dataset                              │
│     ├─ 1A: Transformaciones y resumen                           │
│     ├─ 1B: Análisis de miRNAs                                   │
│     └─ 1C: Análisis de posiciones                               │
│                                                                  │
│  ✅ Paso 2: Análisis de oxidación (G>T)                         │
│     ├─ 2A: Estadísticas generales                               │
│     ├─ 2B: Análisis por posición                                │
│     └─ 2C: Análisis por miRNA                                   │
│                                                                  │
│  ✅ Paso 3: Análisis de VAFs                                    │
│     ├─ 3A: VAFs en mutaciones G>T                               │
│     ├─ 3B: Comparativo ALS vs Control                           │
│     └─ 3C: VAFs por región funcional                            │
│                                                                  │
│  ✅ Paso 4: Análisis estadístico                                │
│     └─ 4A: t-tests y FDR (819 SNVs significativos)             │
│                                                                  │
│  ⏸️  PAUSA ESTRATÉGICA                                          │
│     └─ Integración de metadatos clínicos                        │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📈 **RESUMEN DE NÚMEROS**

### **Reducción del dataset:**
```
68,968 SNVs originales
   ↓ (split)
111,785 SNVs temporales
   ↓ (collapse)
29,254 SNVs únicos finales
   ↓ (filtrado VAF)
29,254 SNVs (MISMO NÚMERO, solo NaNs en VAFs)
```

**Reducción neta:** 57.6% (68,968 → 29,254)
**Causa:** Consolidación de mutaciones múltiples y duplicados
**Pérdida de datos:** 0% (solo reorganización)

### **Expansión de columnas:**
```
832 columnas originales
   ↓ (calcular VAFs)
1,247 columnas finales
```

**Aumento:** +415 columnas (VAFs)

---

## ⚠️ **FILTROS CRÍTICOS QUE DEBERÍAMOS CONSIDERAR:**

### **Antes de análisis estadísticos avanzados:**

**1. Filtro de calidad de datos**
```r
# Eliminar SNVs con muy pocos datos válidos
# Ejemplo: SNVs con < 10 muestras con VAF válido
filtered_data %>%
  filter(n_valid_samples >= 10)
```

**2. Filtro de counts mínimos**
```r
# Eliminar counts muy bajos (ruido técnico)
# Ejemplo: count < 5
filtered_data %>%
  mutate(across(count_cols, ~ifelse(.x < 5, NA, .x)))
```

**3. Filtro de totales mínimos**
```r
# Eliminar muestras con muy pocos reads
# Ejemplo: total < 100
filtered_data %>%
  select(where(~mean(as.numeric(.x), na.rm=TRUE) >= 100))
```

**4. Filtro de VAF mínimo**
```r
# Eliminar VAFs muy bajos (ruido biológico)
# Ejemplo: VAF < 0.001 (0.1%)
filtered_data %>%
  mutate(across(vaf_cols, ~ifelse(.x < 0.001, NA, .x)))
```

---

## 🎯 **ESTADO ACTUAL Y SIGUIENTE PASO:**

**ESTADO:**
> Tenemos un dataset **MUY LIMPIO pero MUY PERMISIVO**
> - Solo 1 filtro aplicado (VAF > 50%)
> - Todos los SNVs preservados
> - Todas las muestras preservadas
> - Listo para análisis exploratorios

**PRÓXIMO PASO CRÍTICO:**
> **Decidir estrategia de filtrado** antes de continuar:
> 1. ¿Aplicar filtros de calidad adicionales?
> 2. ¿Incorporar metadatos clínicos primero?
> 3. ¿Hacer análisis de calidad de datos (QC)?

---

*Documento generado: 8 de octubre de 2024*
*Estado: Dataset listo para decisión de filtrado*









