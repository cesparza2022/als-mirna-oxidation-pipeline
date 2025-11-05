# 📋 BITÁCORA DE CAMBIOS DEL PIPELINE

Registro cronológico de modificaciones, mejoras y ajustes realizados en el pipeline de análisis G>T.

---

## 2025-01-28 - Consolidación y Automatización del Pipeline

### Cambios en Paso 2:

✅ **Estructura estandarizada:**
- Migrado a `step2/` con estructura: `scripts/`, `viewers/`, `outputs/` (figures, figures_clean, tables, logs)
- Creado `run_step2.R` como orquestador principal
- Creado `scripts/build_step2_viewers.R` para generación automática de viewers HTML

✅ **Viewers embebidos:**
- Creado `STEP2_EMBED.html` con todas las imágenes embebidas (base64) para garantizar visibilidad
- Mantenido `STEP2.html` con rutas relativas como alternativa

✅ **Golden copies de density heatmaps:**
- Identificadas y registradas las versiones correctas de 2.13, 2.14, 2.15
- Fuente canónica: `pipeline_2/HTML_VIEWERS_FINALES/figures_paso2_CLEAN/FIG_2.13/14/15_*.png`
- Sincronización automática al ejecutar `run_step2.R` → `step2/outputs/figures_clean/`

✅ **Documentación:**
- Actualizado `ORGANIZACION_PIPELINE.md` con estructura completa de los 3 pasos
- Creado `BITACORA_PIPELINE.md` (este archivo) para registro de cambios

### Figuras del Paso 2 (15 total):
- 2.1-2.12: Generadas por scripts individuales → `step2/outputs/figures/`
- 2.13-2.15: Sincronizadas desde golden copies → `step2/outputs/figures_clean/`

### Próximos pasos sugeridos:
- [x] Migrar Paso 1 a estructura `step1/` estandarizada ✅ **COMPLETADO 2025-01-30**
- [x] Migrar Paso 1.5 a estructura `step1_5/` estandarizada ✅ **COMPLETADO 2025-01-30**
- [x] Crear `run_pipeline_completo.R` que ejecute todos los pasos en secuencia ✅ **COMPLETADO 2025-01-30**

---

## 2025-01-30 - Creación del Runner Maestro

### Cambios realizados:

✅ **Runner maestro creado:**
- `run_pipeline_completo.R` creado en la raíz del pipeline
- Ejecuta Paso 1 → Paso 1.5 → Paso 2 en secuencia
- Muestra tiempos de ejecución para cada paso
- Resumen final con ubicación de viewers

✅ **Funcionalidad:**
- Detecta automáticamente la raíz del pipeline
- Manejo de errores por paso (si uno falla, continúa con los siguientes)
- Muestra progreso y tiempos de ejecución
- Lista viewers HTML generados al final

### Uso:
```bash
Rscript run_pipeline_completo.R
```

### Nota:
- Cada paso se ejecuta independientemente
- Los errores en un paso no detienen el pipeline completo
- Los viewers HTML se listan al finalizar

---

## 2025-01-30 - Estandarización Paso 1.5

### Cambios realizados:

✅ **Estructura estandarizada:**
- Creado `step1_5/` con estructura idéntica a `step1/` y `step2/`
- Directorios: `scripts/`, `viewers/`, `outputs/` (figures, tables, logs)
- Scripts copiados desde `01.5_vaf_quality_control/` y adaptados

✅ **Scripts adaptados:**
- `01_apply_vaf_filter.R`: Rutas actualizadas, outputs a `outputs/tables/`
- `02_generate_diagnostic_figures.R`: Rutas actualizadas, figuras a `outputs/figures/`
- Input: Calculado dinámicamente desde estructura relativa
- Outputs: Redirigidos a estructura estandarizada

✅ **Orquestador creado:**
- `run_step1_5.R` creado (similar a `run_step1.R`)
- Ejecuta ambos scripts en orden
- Genera logs en `outputs/logs/`

✅ **Documentación:**
- Creado `step1_5/README.md` con guía de uso
- Actualizado `BITACORA_PIPELINE.md`

### Scripts migrados:
- `01_apply_vaf_filter.R` → Aplica filtro VAF >= 0.5
- `02_generate_diagnostic_figures.R` → Genera 11 figuras (4 QC + 7 diagnóstico)

### Nota:
- `01.5_vaf_quality_control/` se mantiene como referencia/backup
- Viewer HTML copiado a `step1_5/viewers/STEP1_5.html`
- Figuras y tablas existentes copiadas a `step1_5/outputs/` como referencia inicial

---

## 2025-01-30 - Estandarización Paso 1

### Cambios realizados:

✅ **Estructura estandarizada:**
- Creado `step1/` con estructura idéntica a `step2/`
- Directorios: `scripts/`, `viewers/`, `outputs/` (figures, tables, logs)
- Scripts copiados desde `STEP1_ORGANIZED/scripts/` y adaptados

✅ **Scripts adaptados:**
- Rutas actualizadas para usar estructura relativa desde `step1/scripts/`
- Salidas redirigidas a `step1/outputs/figures/` y `step1/outputs/tables/`
- Datos de entrada referencian rutas absolutas calculadas dinámicamente

✅ **Orquestador creado:**
- `run_step1.R` creado (similar a `run_step2.R`)
- Ejecuta todos los scripts en orden
- Genera logs en `outputs/logs/`

✅ **Documentación:**
- Creado `step1/README.md` con guía de uso
- Actualizado `BITACORA_PIPELINE.md`

### Scripts migrados:
- `02_gt_count_by_position.R` → Panel B
- `03_gx_spectrum.R` → Panel C
- `04_positional_fraction.R` → Panel D
- `05_gcontent_FINAL_VERSION.R` → Panel E (renombrado a `05_gcontent.R`)
- `06_seed_vs_nonseed.R` → Panel F
- `07_gt_specificity.R` → Panel G

### Nota:
- `STEP1_ORGANIZED/` se mantiene como referencia/backup
- Viewer HTML copiado a `step1/viewers/STEP1.html`
- Figuras y tablas existentes copiadas a `step1/outputs/` como referencia inicial

---

## Formato para nuevas entradas:

### YYYY-MM-DD - Título del cambio

**Qué se modificó:**
- Cambio específico 1
- Cambio específico 2

**Por qué:**
- Razón del cambio

**Impacto:**
- Qué scripts/viewers/outputs se vieron afectados

---

**Nota:** Agregar nuevas entradas al principio del archivo, manteniendo orden cronológico descendente.

