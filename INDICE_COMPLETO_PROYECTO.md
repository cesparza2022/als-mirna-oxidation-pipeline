# 📋 ÍNDICE COMPLETO DEL PROYECTO miRNAs y Oxidación

## 🎯 ARCHIVOS PRINCIPALES (Raíz del proyecto)

### 📄 Documentos de Investigación
- **`COMPREHENSIVE_PAPER_DRAFT_8oG_miRNA_ALS.md`** - Borrador completo del paper científico (~7,200 palabras, 12 figuras, 8 tablas)
- **`MANUSCRIPT_8oG_miRNA_ALS.md`** - Versión inicial del manuscrito
- **`MANUSCRIPT_FIGURES_AND_TABLES.md`** - Especificaciones detalladas de figuras y tablas
- **`MANUSCRIPT_PUBLICATION_STRATEGY.md`** - Estrategia de publicación
- **`MANUSCRIPT_REFERENCES.md`** - Referencias bibliográficas

### 📊 Reportes de Análisis
- **`COMPREHENSIVE_ANALYSIS_REPORT.md`** - Reporte de análisis comprensivo
- **`COMPREHENSIVE_INITIAL_ANALYSIS_RESULTS.md`** - Resultados del análisis inicial
- **`GT_SEED_REGION_STATISTICAL_ANALYSIS_RESULTS.md`** - Análisis estadístico de mutaciones G>T en región semilla
- **`ZSCORE_ANALYSIS_POSITIONS_5_6_RESULTS.md`** - Análisis de z-score para posiciones 5-6
- **`FUNCTIONAL_ANALYSIS_COMPREHENSIVE_REPORT.md`** - Análisis funcional detallado
- **`SEED_REGION_GT_ANALYSIS_SUMMARY.md`** - Resumen del análisis de región semilla G>T

### 📋 Documentación de Proceso
- **`RESEARCH_CHRONOLOGY_AND_DECISIONS.md`** - Cronología completa de decisiones de investigación
- **`DATA_PROCESSING_PIPELINE_DEFINITIVE.md`** - Pipeline definitivo de procesamiento de datos
- **`MASTER_REPORT_INDEX.md`** - Índice maestro de reportes
- **`PROJECT_INDEX.md`** - Índice del proyecto
- **`ORGANIZATION_SUMMARY.md`** - Resumen de organización
- **`QUICK_ACCESS.md`** - Acceso rápido a archivos importantes

### 📈 Reportes Específicos
- **`EXECUTIVE_SUMMARY_GT_SEED_ANALYSIS.md`** - Resumen ejecutivo del análisis G>T
- **`TOP_10_PERCENT_ANALYSIS_REPORT.md`** - Análisis del top 10% de miRNAs
- **`TOP_MIRNAS_SELECTION_JUSTIFICATION.md`** - Justificación de selección de miRNAs top
- **`FIGURE_GALLERY_AND_DESCRIPTIONS.md`** - Galería y descripciones de figuras
- **`DATASET_SEARCH_RESULTS.md`** - Resultados de búsqueda de datasets
- **`MULTI_DATASET_STRATEGY.md`** - Estrategia de múltiples datasets

### 📄 Documentos de Configuración
- **`PRD_8oG.txt`** - Product Requirements Document
- **`PROJECT_CONFIG.json`** - Configuración del proyecto
- **`data_schema.json`** - Esquema de datos
- **`config.yaml`** - Configuración YAML

---

## 📁 CARPETA ORGANIZED/ (Estructura Organizada)

### 📚 01_documentation/
- **`PRD_8oG.txt`** - Documento de requisitos del producto
- **`PROJECT_INDEX.md`** - Índice del proyecto
- **`README.md`** - Documentación principal
- **`config.yaml`** - Configuración
- **`data_schema.json`** - Esquema de datos

### 🗃️ 02_data/ (Datos Originales y Procesados)
- **`Magen_ALS-bloodplasma/`** - Dataset principal de ALS (19 archivos)
  - `miRNA_count.Q33.txt` - Datos principales de conteo de miRNAs
  - Archivos de metadatos y reportes de calidad
- **`ALS-treatments/`** - Datos de tratamientos ALS
- **`ALS-trial/`** - Datos de ensayos clínicos
- **`GDC-LGG-miRNA/`** - Datos de GDC para LGG
- **`SOD1_paper1/`** - Datos del paper SOD1
- **`cont/`**, **`PE/`**, **`PE_IP/`** - Datos experimentales

### 🔬 03_analysis/ (Análisis)
- (Carpeta vacía - análisis en carpeta R/)

### 📊 04_results/ (Resultados)
- 159 archivos (121 PNG, 37 CSV, 1 MD)
- Figuras, tablas y reportes generados

### 📚 05_literature/ (Literatura)
- 18 archivos PDF de papers científicos
- Incluye papers sobre ALS, miRNAs, oxidación

### 💻 06_code/ (Código)
- 69 archivos R (68 scripts + 1 MD)
- Scripts de análisis y procesamiento

### 📋 07_reports/ (Reportes)
- (Carpeta vacía - reportes en raíz)

---

## 💻 CARPETA R/ (Scripts de Análisis)

### 🔧 Scripts de Procesamiento de Datos
- **`data_preprocessing_pipeline_v2.R`** - Pipeline definitivo de preprocesamiento
- **`data_preprocessing_pipeline.R`** - Pipeline inicial
- **`snv_processing_functions.R`** - Funciones de procesamiento SNV
- **`snv_processing_functions_fixed.R`** - Versión corregida

### 📊 Scripts de Análisis Principal
- **`comprehensive_initial_analysis.R`** - Análisis inicial comprensivo
- **`comprehensive_control_als_comparison.R`** - Comparación robusta Control vs ALS
- **`analyze_gt_mutations_seed_region.R`** - Análisis G>T región semilla
- **`analyze_zscore_positions_5_6_fixed.R`** - Análisis z-score posiciones 5-6
- **`functional_analysis_detailed.R`** - Análisis funcional detallado
- **`target_genes_pathway_analysis.R`** - Análisis de genes diana y vías

### 🔍 Scripts de Análisis Específicos
- **`seed_region_gt_analysis.R`** - Análisis específico región semilla
- **`statistical_analysis_gt_seed_region.R`** - Análisis estadístico
- **`vaf_heatmap_analysis.R`** - Análisis de heatmaps VAF
- **`clustering_analysis.R`** - Análisis de clustering
- **`positional_analysis.R`** - Análisis posicional
- **`expression_oxidation_relationship.R`** - Análisis relación expresión-oxidación
- **`real_significance_analysis.R`** - Análisis de significancia real (VAF-based)
- **`zscore_als_control_analysis.R`** - Análisis Z-score ALS vs Control
- **`detailed_zscore_visualization.R`** - Visualizaciones detalladas Z-score

### 🛠️ Scripts de Debugging y Verificación
- **`debug_vaf_filter.R`** - Debug del filtro VAF
- **`step_by_step_debug.R`** - Debug paso a paso
- **`verify_snv_counts_and_proportions.R`** - Verificación de conteos
- **`vaf_filter_summary.R`** - Resumen del filtro VAF

### 📈 Scripts de Visualización
- **`plots.R`** - Funciones de plotting
- **`heatmap_analysis_comprehensive.R`** - Análisis de heatmaps
- **`simple_heatmap_analysis.R`** - Heatmaps simples

---

## 📁 CARPETA OUTPUTS/ (Resultados Generados)

### 📊 Datos Procesados
- **`processed_snv_data_vaf_filtered.tsv`** - Datos SNV filtrados por VAF (DEFINITIVO)
- **`processed_snv_data_final.tsv`** - Datos SNV finales
- **`processed_mirna_dataset.tsv`** - Dataset de miRNAs procesado

### 📈 Figuras Principales
- **`gt_seed_region_vaf_heatmap.pdf`** - Heatmap VAF región semilla G>T
- **`gt_seed_region_vaf_distribution.pdf`** - Distribución VAF región semilla
- **`zscore_heatmap_positions_5_6_fixed.pdf`** - Heatmap z-score posiciones 5-6
- **`zscore_distribution_positions_5_6.pdf`** - Distribución z-score
- **`functional_analysis_clustering.pdf`** - Clustering análisis funcional
- **`functional_analysis_position_matrix.pdf`** - Matriz de posiciones
- **`functional_analysis_integrated_heatmap.pdf`** - Heatmap integrado
- **`target_genes_interaction_heatmap.pdf`** - Heatmap interacciones genes diana
- **`connectivity_analysis.pdf`** - Análisis de conectividad

### 📋 Reportes de Análisis
- **`analysis_diary.md`** - Diario de análisis
- **`bitacora_analysis_summary.txt`** - Resumen de bitácora
- **`executive_summary_complete.md`** - Resumen ejecutivo completo
- **`functional_analysis_report.md`** - Reporte análisis funcional
- **`ANALISIS_SIGNIFICANCIA_REAL_GT_SEMILLA.md`** - Análisis de significancia real
- **`RESUMEN_ANALISIS_SIGNIFICANCIA_REAL.md`** - Resumen del análisis de significancia
- **`ANALISIS_ZSCORE_ALS_CONTROL.md`** - Análisis Z-score ALS vs Control
- **`OUTLINE_PAPER_CON_ZSCORE.md`** - Outline del paper con Z-score
- **`EXPLICACION_ZSCORE_Y_VISUALIZACIONES.md`** - Explicación detallada del Z-score y visualizaciones

### 📊 Datos de Análisis
- **`clean_heatmap_vaf_matrix.tsv`** - Matriz VAF para heatmaps
- **`seed_region_vaf_matrix.tsv`** - Matriz VAF región semilla
- **`functional_analysis_mutations.tsv`** - Mutaciones análisis funcional
- **`functional_target_analysis.tsv`** - Análisis genes diana
- **`vaf_zscore_position_analysis.tsv`** - Análisis z-score posicional

---

## 🎯 ARCHIVOS CLAVE POR FUNCIÓN

### 🔬 **Análisis Principal**
- `COMPREHENSIVE_PAPER_DRAFT_8oG_miRNA_ALS.md` - Paper principal
- `comprehensive_control_als_comparison.R` - Comparación Control vs ALS
- `processed_snv_data_vaf_filtered.tsv` - Datos procesados definitivos

### 📊 **Visualizaciones Clave**
- `gt_seed_region_vaf_heatmap.pdf` - Heatmap principal G>T
- `zscore_heatmap_positions_5_6_fixed.pdf` - Análisis z-score
- `functional_analysis_integrated_heatmap.pdf` - Análisis funcional

### 📋 **Documentación de Proceso**
- `RESEARCH_CHRONOLOGY_AND_DECISIONS.md` - Cronología completa
- `DATA_PROCESSING_PIPELINE_DEFINITIVE.md` - Pipeline definitivo
- `analysis_diary.md` - Diario de análisis

### 🗃️ **Datos Originales**
- `organized/02_data/Magen_ALS-bloodplasma/miRNA_count.Q33.txt` - Dataset principal
- `outputs/processed_snv_data_vaf_filtered.tsv` - Datos procesados

---

## 📍 UBICACIONES IMPORTANTES

### 🎯 **Para Continuar el Análisis:**
- **Scripts principales:** `/R/comprehensive_control_als_comparison.R`
- **Datos procesados:** `/outputs/processed_snv_data_vaf_filtered.tsv`
- **Paper en progreso:** `/COMPREHENSIVE_PAPER_DRAFT_8oG_miRNA_ALS.md`

### 📊 **Para Ver Resultados:**
- **Figuras principales:** `/outputs/` (archivos PDF)
- **Reportes:** Archivos `.md` en raíz del proyecto
- **Datos:** Archivos `.tsv` en `/outputs/`

### 🔧 **Para Modificar Análisis:**
- **Scripts R:** Carpeta `/R/`
- **Pipeline:** `DATA_PROCESSING_PIPELINE_DEFINITIVE.md`
- **Configuración:** `PROJECT_CONFIG.json`

---

*Última actualización: $(date)*
*Total de archivos principales: ~300+ archivos*
*Estructura: 7 carpetas principales + archivos de raíz*
