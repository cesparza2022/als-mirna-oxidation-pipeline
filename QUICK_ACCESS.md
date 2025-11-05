# ⚡ ACCESO RÁPIDO - PROYECTO miRNAs Y OXIDACIÓN

## 🎯 **COMANDOS RÁPIDOS**

### **📊 Ver Resultados Principales**
```bash
# Ver heatmap principal
open outputs/figures/simple_final_vaf_heatmap.png

# Ver análisis familia let-7
open outputs/figures/let7_family_heatmap.png

# Ver clustering
open outputs/figures/clustering_analysis_heatmap.png
```

### **📋 Ver Datos Principales**
```bash
# Ver top miRNAs
head -20 outputs/simple_final_top_mirnas.tsv

# Ver SNVs significativos
head -20 outputs/vaf_zscore_top_significant.tsv

# Ver análisis familia let-7
head -20 outputs/let7_family_analysis.tsv
```

### **🔬 Ejecutar Análisis**
```bash
# Análisis completo
Rscript R/simple_final_analysis.R

# Análisis familia let-7
Rscript R/let7_family_analysis.R

# Análisis funcional
Rscript R/functional_analysis_als.R
```

## 📁 **RUTAS PRINCIPALES**

### **🎯 Archivos Más Importantes**
```
📄 PROJECT_INDEX.md                    # Índice maestro del proyecto
📄 outputs/ANALISIS_COMPLETO_FINAL.md  # Análisis completo
📄 outputs/executive_summary_complete.md # Resumen ejecutivo
📄 outputs/bitacora_resumen_final.md   # Resumen de bitácora
```

### **📊 Resultados Clave**
```
📊 outputs/figures/simple_final_vaf_heatmap.png     # Heatmap principal
📊 outputs/figures/let7_family_heatmap.png          # Familia let-7
📊 outputs/figures/clustering_analysis_heatmap.png  # Clustering
📋 outputs/simple_final_top_mirnas.tsv              # Top miRNAs
📋 outputs/vaf_zscore_top_significant.tsv           # SNVs significativos
```

### **💻 Código Principal**
```
💻 R/simple_final_analysis.R           # Análisis principal
💻 R/let7_family_analysis.R            # Familia let-7
💻 R/functional_analysis_als.R         # Análisis funcional
💻 R/bitacora_functions.R              # Funciones principales
```

## 🚀 **ACCESO POR CATEGORÍAS**

### **📊 VISUALIZACIONES**
```bash
# Ver todas las figuras
ls -la outputs/figures/

# Ver figuras específicas
open outputs/figures/simple_final_vaf_heatmap.png
open outputs/figures/let7_family_heatmap.png
open outputs/figures/clustering_analysis_heatmap.png
```

### **📋 DATOS**
```bash
# Ver tablas principales
ls -la outputs/tables/

# Ver datos procesados
head -20 outputs/processed_mirna_dataset_simple.tsv
head -20 outputs/simple_final_top_mirnas.tsv
```

### **📝 REPORTES**
```bash
# Ver reportes principales
open outputs/ANALISIS_COMPLETO_FINAL.md
open outputs/executive_summary_complete.md
open outputs/bitacora_resumen_final.md
```

## 🔍 **BÚSQUEDAS RÁPIDAS**

### **🔍 Buscar miRNAs Específicos**
```bash
# Buscar miR-16
grep -i "miR-16" outputs/simple_final_top_mirnas.tsv

# Buscar familia let-7
grep -i "let-7" outputs/let7_family_analysis.tsv

# Buscar SNVs significativos
grep -i "significant" outputs/vaf_zscore_top_significant.tsv
```

### **🔍 Buscar en Código**
```bash
# Buscar funciones específicas
grep -r "function" R/

# Buscar análisis estadístico
grep -r "t.test\|wilcox" R/

# Buscar visualizaciones
grep -r "ggplot\|pheatmap" R/
```

## 📈 **MÉTRICAS RÁPIDAS**

### **📊 Estadísticas Principales**
- **Total SNVs**: 27,668
- **SNVs significativos**: 570 (p < 0.05)
- **SNVs altamente significativos**: 284 (p < 0.001)
- **Muestras**: 830 (626 ALS + 204 Control)
- **miRNAs únicos**: 1,728

### **🎯 Top miRNAs**
1. **hsa-miR-16-5p**: 19,038 cuentas G>T
2. **hsa-miR-423-5p**: Más significativo
3. **hsa-miR-1-3p**: Segundo más afectado
4. **Familia let-7**: Patrones consistentes

## 🎯 **PRÓXIMOS PASOS**

### **1. Análisis Funcional Avanzado** ⭐
```bash
# Ejecutar análisis funcional
Rscript R/functional_analysis_als.R

# Ver resultados
open outputs/functional_analysis_report.md
```

### **2. Validación Estadística** ⭐
```bash
# Ejecutar validación
Rscript R/statistical_validation.R

# Ver resultados
open outputs/statistical_validation_report.md
```

### **3. Preparación de Manuscrito**
```bash
# Generar reporte para publicación
Rscript R/generate_manuscript_figures.R

# Ver figuras finales
open outputs/manuscript_figures/
```

## 📞 **CONTACTO**
- **Investigador**: César Esparza
- **Institución**: UCSD
- **Proyecto**: Estancia de investigación 2025

---

**💡 TIP**: Usa este archivo para acceder rápidamente a cualquier parte del proyecto sin navegar por la estructura completa.










