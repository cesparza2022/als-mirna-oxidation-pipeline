# 📋 Instrucciones para Usar el Pipeline Definitivo

## 🚀 Inicio Rápido

### 1. **Preparación**
```bash
# Navegar al directorio del pipeline
cd /Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/pipeline_definitivo

# Verificar que tienes los archivos necesarios
ls -la
```

### 2. **Configurar Rutas de Datos**
Editar el archivo `config_pipeline.R` y ajustar la ruta del archivo de datos:
```r
# En la línea ~15, cambiar:
raw_data = "../../processed_data/miRNA_count.Q33.txt"
# Por la ruta real de tu archivo de datos
```

### 3. **Ejecutar Análisis Inicial**
```r
# Opción 1: Ejecutar solo el análisis inicial
cd 01_analisis_inicial
Rscript run_initial_analysis.R

# Opción 2: Ejecutar desde RStudio
source("01_analisis_inicial/run_initial_analysis.R")
```

### 4. **Ver Resultados**
Los resultados se guardarán en:
- `01_analisis_inicial/outputs/` - Datos procesados
- `01_analisis_inicial/figures/` - Gráficas
- `01_analisis_inicial/tables/` - Tablas

---

## 📊 Análisis Incluidos en el Paso 1

### **Procesamiento de Datos**
1. **Split-Collapse**: Separación de mutaciones múltiples y colapso de duplicados
2. **Cálculo de VAFs**: Variant Allele Frequency para cada muestra
3. **Filtrado VAF > 50%**: Conversión a NaN para evitar artefactos

### **Análisis Exploratorio**
1. **Distribución de tipos de mutación**
2. **Análisis de cobertura de SNVs**
3. **Top miRNAs más mutados**
4. **Análisis por posiciones**
5. **Comparaciones ALS vs Control**

### **Gráficas Generadas**
1. `01_mutation_types_distribution.png` - Tipos de mutación
2. `02_nans_distribution.png` - Distribución de NaNs
3. `03_snv_coverage_distribution.png` - Cobertura de SNVs
4. `04_top_mirnas_comparison.png` - Top miRNAs
5. `05_position_analysis.png` - Análisis por posición

---

## 🔧 Configuración Avanzada

### **Parámetros de Filtrado**
En `config_pipeline.R`, puedes ajustar:
```r
filtering_params <- list(
  vaf_threshold = 0.5,    # VAFs > 50% → NaN
  min_coverage = 0.1,     # Mínimo 10% de muestras
  min_samples = 10,       # Mínimo 10 muestras por SNV
  min_mirna_snvs = 5,     # Mínimo 5 SNVs por miRNA
  min_position_snvs = 3   # Mínimo 3 SNVs por posición
)
```

### **Parámetros Estadísticos**
```r
statistical_params <- list(
  alpha = 0.05,           # Nivel de significancia
  multiple_correction = "BH",  # Corrección de Benjamini-Hochberg
  power_threshold = 0.8,  # Umbral de potencia
  n_bootstrap = 1000      # Número de bootstrap
)
```

---

## 📁 Estructura de Archivos

```
pipeline_definitivo/
├── README.md                           # Documentación principal
├── INSTRUCCIONES.md                    # Este archivo
├── config_pipeline.R                   # Configuración centralizada
├── run_pipeline.R                      # Script maestro
├── 01_analisis_inicial/                # Paso 1: Análisis inicial
│   ├── 01_analisis_inicial_dataset.Rmd # Análisis en RMarkdown
│   ├── functions_pipeline.R            # Funciones auxiliares
│   ├── run_initial_analysis.R          # Script de ejecución
│   ├── outputs/                        # Datos procesados
│   ├── figures/                        # Gráficas
│   └── tables/                         # Tablas
├── 02_preprocesamiento/                # Paso 2: (En desarrollo)
├── 03_analisis_exploratorio/           # Paso 3: (En desarrollo)
├── 04_analisis_estadistico/            # Paso 4: (En desarrollo)
├── 05_analisis_funcional/              # Paso 5: (En desarrollo)
└── 06_presentacion_final/              # Paso 6: (En desarrollo)
```

---

## 🎯 Próximos Pasos

### **Paso 2: Preprocesamiento**
- Filtrado por cobertura mínima
- Detección de batch effects
- Normalización de datos
- Control de calidad

### **Paso 3: Análisis Exploratorio**
- Análisis de clustering
- PCA y análisis de componentes
- Análisis de correlaciones
- Identificación de outliers

### **Paso 4: Análisis Estadístico**
- Tests estadísticos apropiados
- Control de múltiples comparaciones
- Análisis de potencia
- Validación de resultados

### **Paso 5: Análisis Funcional**
- Análisis de pathways
- Enriquecimiento funcional
- Análisis de redes
- Correlaciones clínicas

### **Paso 6: Presentación Final**
- Consolidación de resultados
- Creación de dashboard interactivo
- Documentación completa
- Visualizaciones finales

---

## 🐛 Solución de Problemas

### **Error: Archivo de datos no encontrado**
```r
# Verificar la ruta en config_pipeline.R
# Ajustar la variable raw_data a la ruta correcta
```

### **Error: Librerías no encontradas**
```r
# Instalar librerías necesarias
install.packages(c("tidyverse", "ggplot2", "dplyr", "readr", 
                   "stringr", "reshape2", "corrplot", "RColorBrewer", 
                   "pheatmap", "VennDiagram", "gridExtra", "knitr", "DT"))
```

### **Error: Permisos de escritura**
```bash
# Verificar permisos en el directorio
chmod 755 pipeline_definitivo/
```

---

## 📞 Soporte

Para preguntas o problemas:
1. Revisar este archivo de instrucciones
2. Verificar la configuración en `config_pipeline.R`
3. Revisar los logs de ejecución
4. Contactar al autor: César Esparza

---

## 📝 Notas Importantes

- **Rutas**: Ajustar todas las rutas según tu sistema
- **Metadatos**: Necesarios para identificación de grupos ALS vs Control
- **Parámetros**: Documentar cualquier cambio en filtros y umbrales
- **Reproducibilidad**: Mantener versiones de código y configuración

---

**¡Listo para comenzar el análisis!** 🚀








