# 📋 LISTA DE ARCHIVOS CRÍTICOS DEL PIPELINE

**Para commit a GitHub**  
**Fecha:** 2025-01-20

---

## ✅ ARCHIVOS CRÍTICOS DEL PIPELINE SNAKEMAKE

### 🔴 MÁXIMA PRIORIDAD - Pipeline Core

#### Scripts R del Pipeline

**Scripts Utils (9 archivos):**
```
final_analysis/pipeline_definitivo/snakemake_pipeline/scripts/utils/functions_common.R
final_analysis/pipeline_definitivo/snakemake_pipeline/scripts/utils/generate_pipeline_info.R
final_analysis/pipeline_definitivo/snakemake_pipeline/scripts/utils/generate_summary_report.R
final_analysis/pipeline_definitivo/snakemake_pipeline/scripts/utils/build_step1_viewer.R
final_analysis/pipeline_definitivo/snakemake_pipeline/scripts/utils/build_step1_5_viewer.R
final_analysis/pipeline_definitivo/snakemake_pipeline/scripts/utils/build_step2_viewer.R
final_analysis/pipeline_definitivo/snakemake_pipeline/scripts/utils/group_comparison.R
final_analysis/pipeline_definitivo/snakemake_pipeline/scripts/utils/logging.R
final_analysis/pipeline_definitivo/snakemake_pipeline/scripts/utils/validate_input.R
```

**Scripts Step 1 (6 archivos):**
```
final_analysis/pipeline_definitivo/snakemake_pipeline/scripts/step1/01_panel_b_gt_count_by_position.R
final_analysis/pipeline_definitivo/snakemake_pipeline/scripts/step1/02_panel_c_gx_spectrum.R
final_analysis/pipeline_definitivo/snakemake_pipeline/scripts/step1/03_panel_d_positional_fraction.R
final_analysis/pipeline_definitivo/snakemake_pipeline/scripts/step1/04_panel_e_gcontent.R (MODIFICADO)
final_analysis/pipeline_definitivo/snakemake_pipeline/scripts/step1/05_panel_f_seed_vs_nonseed.R (MODIFICADO)
final_analysis/pipeline_definitivo/snakemake_pipeline/scripts/step1/06_panel_g_gt_specificity.R (MODIFICADO)
```

**Scripts Step 1.5 (2 archivos):**
```
final_analysis/pipeline_definitivo/snakemake_pipeline/scripts/step1_5/01_apply_vaf_filter.R (MODIFICADO)
final_analysis/pipeline_definitivo/snakemake_pipeline/scripts/step1_5/02_generate_diagnostic_figures.R (MODIFICADO)
```

**Scripts Step 2 (4 archivos):**
```
final_analysis/pipeline_definitivo/snakemake_pipeline/scripts/step2/01_statistical_comparisons.R (MODIFICADO)
final_analysis/pipeline_definitivo/snakemake_pipeline/scripts/step2/02_volcano_plots.R (MODIFICADO)
final_analysis/pipeline_definitivo/snakemake_pipeline/scripts/step2/03_effect_size_analysis.R (MODIFICADO)
final_analysis/pipeline_definitivo/snakemake_pipeline/scripts/step2/04_generate_summary_tables.R (NUEVO)
```

**Otros Scripts:**
```
final_analysis/pipeline_definitivo/snakemake_pipeline/scripts/validate_config.R (MODIFICADO)
```

**Total Scripts R:** 21 archivos

#### Rules Snakemake (7 archivos)

```
final_analysis/pipeline_definitivo/snakemake_pipeline/Snakefile (MODIFICADO)
final_analysis/pipeline_definitivo/snakemake_pipeline/rules/step1.smk (MODIFICADO)
final_analysis/pipeline_definitivo/snakemake_pipeline/rules/step1_5.smk (MODIFICADO)
final_analysis/pipeline_definitivo/snakemake_pipeline/rules/step2.smk (MODIFICADO)
final_analysis/pipeline_definitivo/snakemake_pipeline/rules/viewers.smk (MODIFICADO)
final_analysis/pipeline_definitivo/snakemake_pipeline/rules/pipeline_info.smk (NUEVO)
final_analysis/pipeline_definitivo/snakemake_pipeline/rules/summary.smk (NUEVO)
```

#### Configuración (4 archivos)

```
final_analysis/pipeline_definitivo/snakemake_pipeline/config/config.yaml.example (MODIFICADO)
final_analysis/pipeline_definitivo/snakemake_pipeline/environment.yaml (MODIFICADO)
final_analysis/pipeline_definitivo/snakemake_pipeline/setup.sh (MODIFICADO)
final_analysis/pipeline_definitivo/snakemake_pipeline/setup_github.sh (MODIFICADO)
```

#### Metadata y Summary (9 archivos - Requiere `-f`)

```
final_analysis/pipeline_definitivo/snakemake_pipeline/results/pipeline_info/execution_info.yaml
final_analysis/pipeline_definitivo/snakemake_pipeline/results/pipeline_info/software_versions.yml
final_analysis/pipeline_definitivo/snakemake_pipeline/results/pipeline_info/config_used.yaml
final_analysis/pipeline_definitivo/snakemake_pipeline/results/pipeline_info/provenance.json
final_analysis/pipeline_definitivo/snakemake_pipeline/results/pipeline_info/README.md
final_analysis/pipeline_definitivo/snakemake_pipeline/results/summary/summary_report.html
final_analysis/pipeline_definitivo/snakemake_pipeline/results/summary/summary_statistics.json
final_analysis/pipeline_definitivo/snakemake_pipeline/results/summary/key_findings.md
final_analysis/pipeline_definitivo/snakemake_pipeline/results/INDEX.md
```

---

## 🟡 IMPORTANTE - Documentación Principal

```
final_analysis/pipeline_definitivo/snakemake_pipeline/README.md
final_analysis/pipeline_definitivo/snakemake_pipeline/SETUP.md
final_analysis/pipeline_definitivo/snakemake_pipeline/QUICK_START.md
final_analysis/pipeline_definitivo/.gitignore (CORREGIDO)
```

---

## 📊 RESUMEN

### Archivos Críticos del Pipeline
- **Scripts R:** 21 archivos
- **Rules Snakemake:** 7 archivos
- **Configuración:** 4 archivos
- **Metadata:** 9 archivos
- **Documentación principal:** 4 archivos

**Total crítico:** 45 archivos

### Archivos Adicionales (Opcional)
- ~60 archivos de documentación técnica adicional
- ~333 archivos del proyecto general (análisis, papers, etc.)

---

## 🚀 SCRIPT PARA COMMIT SELECTIVO

```bash
# Commit 1: Corrección .gitignore
git add final_analysis/pipeline_definitivo/.gitignore
git commit -m "fix: Clean up .gitignore for pipeline"

# Commit 2: Scripts Utils Nuevos
git add final_analysis/pipeline_definitivo/snakemake_pipeline/scripts/utils/functions_common.R
git add final_analysis/pipeline_definitivo/snakemake_pipeline/scripts/utils/generate_pipeline_info.R
git add final_analysis/pipeline_definitivo/snakemake_pipeline/scripts/utils/generate_summary_report.R
git commit -m "feat: Add missing utils scripts"

# Commit 3: Rules Nuevas
git add final_analysis/pipeline_definitivo/snakemake_pipeline/rules/pipeline_info.smk
git add final_analysis/pipeline_definitivo/snakemake_pipeline/rules/summary.smk
git commit -m "feat: Add metadata and summary rules"

# Commit 4: Metadata (requiere -f)
git add -f final_analysis/pipeline_definitivo/snakemake_pipeline/results/pipeline_info/
git add -f final_analysis/pipeline_definitivo/snakemake_pipeline/results/summary/
git add -f final_analysis/pipeline_definitivo/snakemake_pipeline/results/INDEX.md
git commit -m "feat: Add pipeline metadata and summary"

# Commit 5: Pipeline Core Actualizado
git add final_analysis/pipeline_definitivo/snakemake_pipeline/Snakefile
git add final_analysis/pipeline_definitivo/snakemake_pipeline/rules/*.smk
git add final_analysis/pipeline_definitivo/snakemake_pipeline/scripts/
git commit -m "feat: Update pipeline core with improvements"

# Commit 6: Configuración
git add final_analysis/pipeline_definitivo/snakemake_pipeline/config/
git add final_analysis/pipeline_definitivo/snakemake_pipeline/environment.yaml
git add final_analysis/pipeline_definitivo/snakemake_pipeline/setup*.sh
git commit -m "feat: Update configuration and setup"

# Commit 7: Documentación Principal
git add final_analysis/pipeline_definitivo/snakemake_pipeline/README.md
git add final_analysis/pipeline_definitivo/snakemake_pipeline/SETUP.md
git add final_analysis/pipeline_definitivo/snakemake_pipeline/QUICK_START.md
git commit -m "docs: Update main documentation"
```

---

**Total estimado:** ~45 archivos críticos + documentación principal = **~50 archivos**

