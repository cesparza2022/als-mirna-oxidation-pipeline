# 🔍 REVISIÓN PRE-COMMIT: Archivos que se Agregarán

**Fecha:** 2025-01-20  
**Repositorio:** https://github.com/cesparza2022/als-mirna-oxidation-pipeline.git

---

## ⚠️ PROBLEMA DETECTADO

### `.gitignore` está bloqueando metadata importante

El `.gitignore` actual tiene `results/` en la línea 139, lo que significa que **TODOS** los archivos en `results/` están siendo ignorados, incluyendo:
- ❌ `results/pipeline_info/` - Metadata importante para reproducibilidad
- ❌ `results/summary/` - Summary reports consolidados
- ❌ `results/INDEX.md` - Índice navegable

**Esto es incorrecto.** Estos archivos DEBEN ir a GitHub para reproducibilidad.

---

## 📊 ANÁLISIS DE ARCHIVOS

### 🔴 CRÍTICO - Archivos que DEBEN ir a GitHub

#### 1. Scripts del Pipeline (Modificados/Actualizados)

**Scripts Utils (9 archivos):**
- ✅ `scripts/utils/functions_common.R` - **NUEVO** - Funciones compartidas
- ✅ `scripts/utils/generate_pipeline_info.R` - **NUEVO** - Genera metadata
- ✅ `scripts/utils/generate_summary_report.R` - **NUEVO** - Genera summary reports
- ✅ `scripts/utils/build_step1_viewer.R` - Modificado
- ✅ `scripts/utils/build_step1_5_viewer.R` - Modificado
- ✅ `scripts/utils/build_step2_viewer.R` - Modificado
- ✅ `scripts/utils/group_comparison.R` - Modificado
- ✅ `scripts/utils/logging.R` - Modificado
- ✅ `scripts/utils/validate_input.R` - Modificado

**Scripts Step 1 (3 archivos modificados):**
- ✅ `scripts/step1/04_panel_e_gcontent.R` - Modificado
- ✅ `scripts/step1/05_panel_f_seed_vs_nonseed.R` - Modificado
- ✅ `scripts/step1/06_panel_g_gt_specificity.R` - Modificado

**Scripts Step 1.5 (2 archivos modificados):**
- ✅ `scripts/step1_5/01_apply_vaf_filter.R` - Modificado
- ✅ `scripts/step1_5/02_generate_diagnostic_figures.R` - Modificado

**Scripts Step 2 (3 archivos modificados):**
- ✅ `scripts/step2/01_statistical_comparisons.R` - Modificado
- ✅ `scripts/step2/02_volcano_plots.R` - Modificado
- ✅ `scripts/step2/03_effect_size_analysis.R` - Modificado

**Otros Scripts:**
- ✅ `scripts/validate_config.R` - Modificado

**Total scripts R:** 18 archivos modificados + 3 nuevos = **21 archivos**

#### 2. Rules Snakemake (5 archivos modificados)

- ✅ `Snakefile` - Modificado (nuevas rules)
- ✅ `rules/step1.smk` - Modificado
- ✅ `rules/step1_5.smk` - Modificado
- ✅ `rules/step2.smk` - Modificado
- ✅ `rules/viewers.smk` - Modificado

**Nuevos Rules (2 archivos):**
- ✅ `rules/pipeline_info.smk` - **NUEVO** - Genera metadata
- ✅ `rules/summary.smk` - **NUEVO** - Genera summary reports

**Total rules:** 5 modificados + 2 nuevos = **7 archivos**

#### 3. Configuración (3 archivos)

- ✅ `config/config.yaml.example` - Modificado (nuevos parámetros)
- ✅ `environment.yaml` - Modificado (nuevas dependencias)
- ✅ `setup.sh` - Modificado
- ✅ `setup_github.sh` - Modificado

#### 4. Metadata y Summary Reports ⚠️ **REQUIERE CORRECCIÓN DE .gitignore**

**Pipeline Info (5 archivos):**
- ✅ `results/pipeline_info/execution_info.yaml` - Metadata de ejecución
- ✅ `results/pipeline_info/software_versions.yml` - Versiones de software
- ✅ `results/pipeline_info/config_used.yaml` - Configuración usada
- ✅ `results/pipeline_info/provenance.json` - Tracking de datos
- ✅ `results/pipeline_info/README.md` - Documentación

**Summary Reports (3 archivos):**
- ✅ `results/summary/summary_report.html` - Reporte consolidado HTML
- ✅ `results/summary/summary_statistics.json` - Estadísticas en JSON
- ✅ `results/summary/key_findings.md` - Resumen ejecutivo

**Index:**
- ✅ `results/INDEX.md` - Índice navegable

**Total metadata:** 9 archivos (pequeños, ~20KB total)

---

### 🟡 IMPORTANTE - Documentación (67 archivos modificados)

#### Documentación Técnica del Pipeline
- `README.md` - Principal
- `SETUP.md` - Instalación
- `QUICK_START.md` - Inicio rápido
- `GUIA_USO_PASO_A_PASO.md` - Guía detallada
- Y ~60 archivos más de documentación técnica

#### Documentación de Fases
- `FASE1_IMPLEMENTACION_COMPLETADA.md`
- `FASE2_IMPLEMENTACION_COMPLETADA.md`
- `FASE3_IMPLEMENTACION_COMPLETADA.md`
- `PASO_1_COMPLETADO.md`
- `PASO_2_COMPLETADO.md`
- Y más...

---

### 🟢 ADICIONAL - Archivos del Proyecto General (333 archivos sin trackear)

**Estos NO son críticos para el pipeline de Snakemake, pero son parte del proyecto:**

#### Scripts R de Análisis Exploratorios (~100 archivos)
- Scripts en `R/` - Análisis previos al pipeline
- Scripts en `final_analysis/` - Análisis intermedios
- No necesarios para ejecutar el pipeline Snakemake

#### Documentación Científica (~150 archivos)
- `COMPREHENSIVE_PAPER_DRAFT_8oG_miRNA_ALS.md` - Borrador del paper
- `MANUSCRIPT_*.md` - Documentos del manuscrito
- `ANALISIS_*.md` - Análisis específicos
- Reportes y resúmenes científicos

#### Archivos de Configuración y Organización (~33 archivos)
- `PROJECT_INDEX.md` - Índice del proyecto
- `ESTADO_GITHUB_VS_LOCAL.md` - Este análisis
- Otros archivos de organización

---

## 🎯 PLAN DE ACCIÓN

### FASE 1: Corregir `.gitignore` (CRÍTICO)

**Problema:** El `.gitignore` ignora todo `results/`, incluyendo metadata importante.

**Solución:** Modificar `.gitignore` para:
1. ✅ Ignorar `results/step*/` (figuras, tablas grandes, logs)
2. ✅ Ignorar `results/intermediate/`
3. ✅ **PERMITIR** `results/pipeline_info/`
4. ✅ **PERMITIR** `results/summary/`
5. ✅ **PERMITIR** `results/INDEX.md`

### FASE 2: Commits Organizados

#### Commit 1: Corrección .gitignore + Metadata
```bash
# Corregir .gitignore
git add final_analysis/pipeline_definitivo/.gitignore

# Agregar metadata (después de corregir .gitignore)
git add final_analysis/pipeline_definitivo/snakemake_pipeline/results/pipeline_info/
git add final_analysis/pipeline_definitivo/snakemake_pipeline/results/summary/
git add final_analysis/pipeline_definitivo/snakemake_pipeline/results/INDEX.md

git commit -m "fix: Allow pipeline metadata in results/ directory

- Update .gitignore to allow results/pipeline_info/ and results/summary/
- Add execution metadata (execution_info, software_versions, provenance)
- Add consolidated summary reports (HTML, JSON, MD)
- Add navigable results index"
```

#### Commit 2: Scripts Utils Nuevos
```bash
git add final_analysis/pipeline_definitivo/snakemake_pipeline/scripts/utils/functions_common.R
git add final_analysis/pipeline_definitivo/snakemake_pipeline/scripts/utils/generate_pipeline_info.R
git add final_analysis/pipeline_definitivo/snakemake_pipeline/scripts/utils/generate_summary_report.R

git commit -m "feat: Add missing utils scripts for metadata and summary

- Add functions_common.R with shared utilities
- Add generate_pipeline_info.R for execution metadata
- Add generate_summary_report.R for consolidated reports"
```

#### Commit 3: Rules Nuevas
```bash
git add final_analysis/pipeline_definitivo/snakemake_pipeline/rules/pipeline_info.smk
git add final_analysis/pipeline_definitivo/snakemake_pipeline/rules/summary.smk

git commit -m "feat: Add pipeline metadata and summary generation rules

- Add pipeline_info rule for execution tracking
- Add summary rule for consolidated reporting
- Enable reproducibility tracking"
```

#### Commit 4: Actualización Scripts y Rules Existentes
```bash
git add final_analysis/pipeline_definitivo/snakemake_pipeline/Snakefile
git add final_analysis/pipeline_definitivo/snakemake_pipeline/rules/step*.smk
git add final_analysis/pipeline_definitivo/snakemake_pipeline/rules/viewers.smk
git add final_analysis/pipeline_definitivo/snakemake_pipeline/scripts/

git commit -m "feat: Update pipeline scripts and rules with improvements

- Enhance error handling and logging
- Update viewer builders with latest features
- Improve group comparison functions
- Update all step scripts with bug fixes"
```

#### Commit 5: Configuración y Setup
```bash
git add final_analysis/pipeline_definitivo/snakemake_pipeline/config/config.yaml.example
git add final_analysis/pipeline_definitivo/snakemake_pipeline/environment.yaml
git add final_analysis/pipeline_definitivo/snakemake_pipeline/setup.sh
git add final_analysis/pipeline_definitivo/snakemake_pipeline/setup_github.sh

git commit -m "feat: Update configuration and setup scripts

- Add new configuration parameters
- Update dependencies in environment.yaml
- Enhance setup scripts with better error handling"
```

#### Commit 6: Documentación Principal
```bash
git add final_analysis/pipeline_definitivo/snakemake_pipeline/README.md
git add final_analysis/pipeline_definitivo/snakemake_pipeline/SETUP.md
git add final_analysis/pipeline_definitivo/snakemake_pipeline/QUICK_START.md

git commit -m "docs: Update main documentation

- Update README with latest features
- Enhance SETUP.md with detailed instructions
- Improve QUICK_START.md"
```

#### Commit 7: Documentación Técnica (Opcional - se puede hacer después)
```bash
# Agregar el resto de documentación en un commit separado
git add final_analysis/pipeline_definitivo/snakemake_pipeline/*.md

git commit -m "docs: Add comprehensive technical documentation

- Document all implementation phases
- Add usage guides and tutorials
- Add analysis and optimization documentation"
```

---

## ✅ VERIFICACIÓN FINAL

### Archivos que NO deben ir (verificar)
- ❌ `outputs/` - Muy grandes (201MB), ignorado por .gitignore
- ❌ `results/step*/final/figures/*.png` - Figuras grandes, ignoradas
- ❌ `results/step*/final/tables/*.csv` - Tablas grandes, ignoradas
- ❌ `results/step*/final/logs/*.log` - Logs, ignorados
- ❌ `config/config.yaml` - Configuración con rutas absolutas (solo .example)

### Archivos que SÍ deben ir
- ✅ Scripts R (todos los `.R`)
- ✅ Rules Snakemake (todos los `.smk`)
- ✅ `Snakefile`
- ✅ Configuración (`.yaml.example`, `environment.yaml`)
- ✅ Setup scripts (`.sh`)
- ✅ Metadata pequeña (`results/pipeline_info/`, `results/summary/`)
- ✅ Documentación (`.md`)

---

## 📊 ESTADÍSTICAS

### Tamaño Estimado
- **Scripts R:** ~200KB (21 archivos)
- **Rules Snakemake:** ~50KB (7 archivos)
- **Metadata:** ~20KB (9 archivos)
- **Documentación pipeline:** ~2MB (67 archivos)
- **Total estimado:** ~2.3MB

### Archivos que se Excluyen (por .gitignore)
- **Outputs:** 201MB (ignorado)
- **Results grandes:** 193MB (ignorado)
- **Total ignorado:** ~394MB ✅ Correcto

---

## 🚀 SIGUIENTE PASO

1. **Primero:** Corregir `.gitignore` para permitir metadata
2. **Segundo:** Verificar qué archivos se agregarían después de corregir
3. **Tercero:** Hacer commits organizados según el plan

¿Proceder con la corrección del `.gitignore`?

