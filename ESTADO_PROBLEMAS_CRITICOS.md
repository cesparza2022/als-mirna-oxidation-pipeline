# 📊 ESTADO DE CORRECCIÓN DE PROBLEMAS CRÍTICOS

**Fecha:** 2025-01-21  
**Versión:** v1.0.1

---

## ✅ PROBLEMA #1: INCONSISTENCIA EN ARCHIVOS DE ENTRADA (STEP 1) - **CORREGIDO**

### Estado: ✅ **RESUELTO**

### Cambios Aplicados:
- ✅ Todos los paneles (B, C, D, E, F, G) ahora usan `processed_clean.csv`
- ✅ `rules/step1.smk` actualizado: Paneles C y D ahora usan `INPUT_DATA_CLEAN`
- ✅ Scripts actualizados: `02_panel_c_gx_spectrum.R` y `03_panel_d_positional_fraction.R` usan `processed_clean`
- ✅ Comentarios agregados: "Load processed_clean data (same as other panels for consistency"

### Evidencia:
- `rules/step1.smk`: Líneas 60, 80 - Comentarios indican uso de `processed_clean`
- `scripts/step1/02_panel_c_gx_spectrum.R`: Línea 43 - Usa `processed_clean`
- `scripts/step1/03_panel_d_positional_fraction.R`: Línea 44 - Usa `processed_clean`

---

## 🟡 PROBLEMA #2: INCONSISTENCIA EN MÉTRICAS (STEP 1) - **PARCIALMENTE CORREGIDO**

### Estado: 🟡 **MEJORADO** (Documentación agregada, pero métricas siguen siendo diferentes por diseño)

### Cambios Aplicados:
- ✅ Panel C: Agregado caption explicando que cuenta SNVs, no suma reads (línea 94)
  - Caption: "Shows percentage of G>X SNVs (unique events) at each position, not read counts"
- ✅ Panel G: Usa suma de reads (diseño intencional para mostrar "percentage of G mutation reads")
- ✅ Paneles B, E, F: Usan suma de reads (diseño intencional)

### Análisis:
**Las métricas diferentes son INTENCIONALES y APROPIADAS:**
- **Panel C** (SNVs únicos): Muestra qué tipos de mutaciones G>X ocurren más frecuentemente como eventos únicos
- **Panel G** (Suma de reads): Muestra qué porcentaje de reads de mutaciones G son G>T (medida de abundancia)

**Estas métricas son complementarias, no contradictorias:**
- SNVs únicos = diversidad de eventos
- Suma de reads = abundancia de eventos

### Recomendación Final:
✅ **No requiere corrección adicional** - Las métricas diferentes son apropiadas y ahora están bien documentadas.

---

## ✅ PROBLEMA #3: MÉTRICA 1 DEL PANEL E (G-CONTENT LANDSCAPE) - **CORREGIDO**

### Estado: ✅ **RESUELTO**

### Cambios Aplicados:
- ✅ **Lógica corregida:** Ahora suma solo los reads de esa posición específica, no todos los reads del miRNA
- ✅ **Código actualizado:** Líneas 76-87 en `04_panel_e_gcontent.R`
  - Antes: Sumaba `total_miRNA_counts` (todos los reads del miRNA)
  - Ahora: Suma `position_specific_counts` (solo reads de esa posición)

### Código Corregido:
```r
# ✅ CORREGIDO: Sumar solo los reads de esa posición específica
total_copies_by_position <- data %>%
  filter(str_detect(pos.mut, "^\\d+:G[TCAG]")) %>%
  mutate(Position = as.numeric(str_extract(pos.mut, "^\\d+"))) %>%
  rowwise() %>%
  mutate(position_specific_counts = sum(c_across(all_of(sample_cols)), na.rm = TRUE)) %>%  # Solo esta posición
  ungroup() %>%
  group_by(Position) %>%
  summarise(
    total_G_copies = sum(position_specific_counts, na.rm = TRUE),  # ✅ Solo reads de esa posición
    .groups = 'drop'
  )
```

### Documentación Mejorada:
- ✅ Caption actualizado: "Y-axis: Total read counts for G mutations at position | ..."
- ✅ Caption específica: "Each bubble represents a position. Y-position = total read counts for G mutations at that SPECIFIC position (not all reads from miRNAs with G)."

---

## ✅ PROBLEMA #4: DATOS NO UTILIZADOS EN FIGURAS - **CORREGIDO**

### Estado: ✅ **RESUELTO**

### Cambios Aplicados:

#### Panel B (Step 1):
- ✅ `n_SNVs` y `n_miRNAs` eliminados del cálculo (comentario línea 103)
- ✅ Solo se calcula `total_GT_count` que es lo que se muestra

#### Panel F (Step 1):
- ✅ `n_SNVs` eliminado del cálculo (comentario línea 85)
- ✅ Solo se calcula `total_mutations` que es lo que se muestra

#### Step 0:
- ℹ️ `total_read_counts` y `n_samples_with_snv` en Figuras 4 y 5 se calculan porque se usan en otras figuras (Figuras 6 y 7)
- ✅ **No requiere corrección** - Los cálculos son necesarios para otras visualizaciones

---

## ✅ PROBLEMA #5: ASUNCIÓN SOBRE ESTRUCTURA DE DATOS (STEP 0) - **DOCUMENTADO**

### Estado: ✅ **DOCUMENTADO Y VALIDADO**

### Cambios Aplicados:
- ✅ **Documentación agregada:** Líneas 74-79 en `01_generate_overview.R`
  - Explica claramente qué contiene `processed_clean.csv`
  - Especifica que las columnas de muestras contienen SNV counts (no total counts)
- ✅ **Validación mejorada:** Línea 94 - Log indica claramente qué contienen las columnas
- ✅ **Comentarios clarificadores:** Explican que `counts_matrix` contiene SNV counts

### Documentación Agregada:
```r
# ✅ DOCUMENTADO: processed_clean.csv contains:
#   - miRNA_name, pos.mut: Identification columns
#   - Sample columns: SNV counts (number of reads supporting each specific SNV)
#   - VAF_* columns: Variant Allele Frequency (if present)
# IMPORTANT: Sample columns contain SNV counts (not total miRNA counts)
# Each row represents one unique SNV event, and sample columns contain read counts for that specific SNV
```

### Validación:
- ✅ Log muestra claramente qué se detectó: "Detected X count columns and Y VAF columns"
- ✅ Log explica: "NOTE: Count columns contain SNV counts (reads supporting each specific SNV), not total miRNA counts"

---

## 📊 RESUMEN FINAL

| # | Problema | Estado | Acción Requerida |
|---|----------|--------|------------------|
| 1 | Inconsistencia en archivos de entrada | ✅ CORREGIDO | Ninguna |
| 2 | Inconsistencia en métricas | 🟡 MEJORADO | Ninguna (diferentes métricas son apropiadas) |
| 3 | Métrica 1 Panel E | ✅ CORREGIDO | Ninguna |
| 4 | Datos no utilizados | ✅ CORREGIDO | Ninguna |
| 5 | Asunción sobre estructura de datos | ✅ DOCUMENTADO | Ninguna |

---

## ✅ CONCLUSIÓN

**Todos los problemas críticos identificados han sido abordados:**

- **3 problemas completamente corregidos** (Problemas 1, 3, 4)
- **1 problema mejorado con documentación** (Problema 2 - diferentes métricas son apropiadas)
- **1 problema documentado y validado** (Problema 5 - estructura de datos clarificada)

### Próximos Pasos:
1. ✅ **Probar el pipeline** con todas las correcciones aplicadas
2. ✅ **Actualizar README** si es necesario
3. ✅ **Crear tag de release v1.0.1**

---

**Última actualización:** 2025-01-21

