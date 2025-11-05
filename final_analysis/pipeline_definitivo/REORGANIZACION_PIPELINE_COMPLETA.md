# 🔄 REORGANIZACIÓN COMPLETA DEL PIPELINE

**Fecha:** 2025-10-20  
**Objetivo:** Integrar correctamente el nuevo Paso 1.5 (VAF Quality Control) en la estructura existente

---

## 📊 ESTRUCTURA ACTUAL vs NUEVA

### **ESTRUCTURA ACTUAL:**
```
pipeline_definitivo/
├── 01_analisis_inicial/           ← Paso 1 (Split-Collapse)
├── 01.5_vaf_quality_control/      ← Paso 1.5 (VAF Filter) ⭐ NUEVO
├── pipeline_2/                     ← Paso 2 (G>T Seed Analysis)
├── pipeline_2.5/                   ← Paso 2.5 (Pattern Analysis)
├── pipeline_2.6_sequence_motifs/  ← Paso 2.6 (Sequence Motifs)
└── pipeline_3/                    ← Paso 3 (Functional Analysis)
```

### **ESTRUCTURA PROPUESTA (REORGANIZADA):**
```
pipeline_definitivo/
├── 01_analisis_inicial/           ← Paso 1: Split-Collapse + Diagnóstico
├── 02_vaf_quality_control/        ← Paso 2: VAF Filter + Diagnóstico (RENOMBRAR)
├── 03_gt_seed_analysis/           ← Paso 3: G>T Seed Analysis (RENOMBRAR)
├── 04_pattern_analysis/           ← Paso 4: Pattern Analysis (RENOMBRAR)
├── 05_sequence_motifs/            ← Paso 5: Sequence Motifs (RENOMBRAR)
└── 06_functional_analysis/        ← Paso 6: Functional Analysis (RENOMBRAR)
```

---

## 🎯 QUÉ CONTIENE CADA PASO ACTUAL

### **PASO 1: `01_analisis_inicial/`**
- **Input:** `step1_original_data.csv` (177 MB, crudo)
- **Proceso:** Split-Collapse
- **Output:** Counts limpios (12 tipos, 23 pos)
- **Figuras:** 7 diagnósticas (datos raw)
- **HTML:** `STEP1_DIAGNOSTIC_FIGURES_VIEWER.html`

### **PASO 1.5: `01.5_vaf_quality_control/`** ⭐ NUEVO
- **Input:** `step1_original_data.csv` (necesita columnas de totales)
- **Proceso:** VAF Filter (>= 0.5 → NaN)
- **Output:** `ALL_MUTATIONS_VAF_FILTERED.csv` (12 tipos, 23 pos, clean)
- **Figuras:** 4 QC + 7 diagnósticas (VAF-filtered)
- **HTML:** `STEP1.5_VAF_QC_VIEWER.html`

### **PASO 2: `pipeline_2/`** (ACTUAL)
- **Input:** Dataset G>T seed
- **Proceso:** Análisis avanzado G>T
- **Output:** 12 figuras avanzadas
- **HTML:** Viewer existente

### **PASO 2.5: `pipeline_2.5/`** (ACTUAL)
- **Input:** Candidatos del Paso 2
- **Proceso:** Análisis de patrones
- **Output:** 13 figuras de patrones
- **HTML:** `PASO_2.5_PATRONES.html`

### **PASO 2.6: `pipeline_2.6_sequence_motifs/`** (ACTUAL)
- **Input:** Candidatos del Paso 2
- **Proceso:** Análisis de motivos de secuencia
- **Output:** Sequence logos, contextos trinucleótido
- **HTML:** Viewer existente

### **PASO 3: `pipeline_3/`** (ACTUAL)
- **Input:** Candidatos del Paso 2
- **Proceso:** Análisis funcional (targets, pathways, networks)
- **Output:** 6 figuras funcionales
- **HTML:** `PASO_3_VIEWER_SIMPLE.html`

---

## 🔄 PLAN DE REORGANIZACIÓN

### **OPCIÓN A: RENOMBRAR CARPETAS (RECOMENDADA)**
```bash
# Renombrar carpetas existentes
mv pipeline_2 03_gt_seed_analysis
mv pipeline_2.5 04_pattern_analysis  
mv pipeline_2.6_sequence_motifs 05_sequence_motifs
mv pipeline_3 06_functional_analysis

# Renombrar nueva carpeta
mv 01.5_vaf_quality_control 02_vaf_quality_control
```

### **OPCIÓN B: MANTENER NUMERACIÓN ACTUAL**
- Mantener `pipeline_2`, `pipeline_2.5`, etc.
- Solo renombrar `01.5_vaf_quality_control` → `pipeline_1.5`

---

## 🎯 FLUJO CORRECTO DEL PIPELINE

### **PASO 1: Split-Collapse + Diagnóstico**
```
Input:  step1_original_data.csv (177 MB, crudo)
Process: Split (PM/1MM/2MM) + Collapse (agrupar)
Output: Counts limpios (12 tipos, 23 pos)
Figures: 7 diagnósticas (datos raw)
```

### **PASO 2: VAF Quality Control + Diagnóstico** ⭐ NUEVO
```
Input:  step1_original_data.csv (necesita totales para VAF)
Process: VAF Filter (>= 0.5 → NaN)
Output: ALL_MUTATIONS_VAF_FILTERED.csv (12 tipos, 23 pos, clean)
Figures: 4 QC + 7 diagnósticas (VAF-filtered)
```

### **PASO 3: G>T Seed Analysis** (ACTUAL pipeline_2)
```
Input:  ALL_MUTATIONS_VAF_FILTERED.csv (del Paso 2)
Process: Filtrar SOLO G>T en seed (pos 2-8)
Output: Dataset G>T específico
Figures: 12 análisis avanzado
```

### **PASO 4: Pattern Analysis** (ACTUAL pipeline_2.5)
```
Input:  Candidatos del Paso 3
Process: Clustering, familias, motivos, contextos
Output: 13 figuras de patrones
```

### **PASO 5: Sequence Motifs** (ACTUAL pipeline_2.6)
```
Input:  Candidatos del Paso 3
Process: Sequence logos, contextos trinucleótido
Output: Logos, análisis de conservación
```

### **PASO 6: Functional Analysis** (ACTUAL pipeline_3)
```
Input:  Candidatos del Paso 3
Process: Targets, pathways, networks
Output: 6 figuras funcionales
```

---

## 🔧 INTEGRACIÓN DEL NUEVO PASO 2

### **Cambios Necesarios en pipeline_2 (futuro Paso 3):**

1. **Input:** Cambiar de dataset original a `ALL_MUTATIONS_VAF_FILTERED.csv`
2. **Ventaja:** Ya tiene filtro VAF aplicado
3. **Proceso:** Filtrar SOLO G>T en seed region (pos 2-8)
4. **Output:** Dataset específico para análisis G>T

### **Scripts a Modificar:**
- `pipeline_2/scripts/01_setup_and_verify.R`
- Cambiar path de input
- Verificar que funciona con datos VAF-filtered

---

## 📋 CHECKLIST DE REORGANIZACIÓN

### **Inmediato:**
- [ ] Decidir si renombrar carpetas (Opción A) o mantener numeración (Opción B)
- [ ] Renombrar `01.5_vaf_quality_control` → `02_vaf_quality_control` o `pipeline_1.5`
- [ ] Actualizar documentación

### **Integración:**
- [ ] Modificar `pipeline_2` para usar `ALL_MUTATIONS_VAF_FILTERED.csv` como input
- [ ] Verificar que todos los scripts funcionan con datos VAF-filtered
- [ ] Actualizar READMEs y documentación

### **Documentación:**
- [ ] Crear índice maestro actualizado
- [ ] Actualizar diagramas de flujo
- [ ] Documentar cambios en cada paso

---

## 🎯 VENTAJAS DE LA REORGANIZACIÓN

### **1. Flujo Lógico:**
- Paso 1: Datos raw → Counts limpios
- Paso 2: Counts → VAF-filtered (clean)
- Paso 3: Clean → G>T seed específico
- Pasos 4-6: Análisis especializados

### **2. Modularidad:**
- Cada paso tiene input/output claro
- Fácil validación entre pasos
- Reutilizable para otros análisis

### **3. Comparabilidad:**
- Paso 1 vs Paso 2: Impacto del filtro VAF
- Datos raw vs clean en cada análisis
- Validación de robustez de patrones

---

## 🚀 PRÓXIMOS PASOS

### **Decisión Inmediata:**
¿Prefieres la **Opción A** (renombrar todo) o **Opción B** (mantener numeración actual)?

### **Después de Decidir:**
1. Ejecutar renombrado
2. Modificar `pipeline_2` para usar datos VAF-filtered
3. Actualizar documentación
4. Validar que todo funciona

---

**¿Cuál opción prefieres para la reorganización?**

