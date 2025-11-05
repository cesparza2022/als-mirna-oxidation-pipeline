# 🚀 Pipeline 2 - miRNA G>T Analysis

## 📝 Descripción

Pipeline automatizado para análisis completo de mutaciones G>T en miRNAs, generando figuras de alta calidad, tablas estadísticas, y un HTML viewer interactivo.

---

## 🎯 Input & Output

### **Input:**
- **Archivo:** `miRNA_count.Q33.txt` (o cualquier archivo similar)
- **Formato:** Archivo TSV con:
  - Columna `miRNA name`
  - Columna `pos:mut` (mutaciones concatenadas)
  - Columnas de muestras (conteos)

### **Output:**
- **Figuras:** 12+ paneles de análisis (PNG de alta resolución)
- **Tablas:** 4 tablas CSV con estadísticas detalladas
- **HTML Viewer:** Navegador interactivo de todas las figuras y tablas

---

## 🚀 Uso Rápido

### **1. Configuración (primera vez):**

```bash
# Editar config/config_pipeline_2.R
# Verificar ruta del archivo de datos:
data_dir <- "/ruta/a/tu/data"
```

### **2. Ejecutar pipeline completo:**

```bash
cd pipeline_2/
Rscript RUN_COMPLETE_PIPELINE.R
```

### **3. Ver resultados:**

```bash
open VIEWER_FINAL_COMPLETO.html
```

**¡Eso es todo!** 🎉

---

## 📊 Figuras Generadas

### **Figura 1 COMPLETE (6 paneles):**
1. **Panel A:** Dataset Evolution + Mutation COUNTS + STATISTICS
2. **Panel B:** G>T COUNT by Position + STATISTICS (Seed vs Non-Seed)
3. **Panel C:** G>X Spectrum (proporción por posición)
4. **Panel D:** Top miRNAs with G>T
5. **Panel E:** Total SNV COUNT by Position
6. **Panel F:** SNV COUNT per miRNA - ALL mutations

### **Figura 1.5 PRELIMINARES (4 paneles):**
1. **Panel A:** SNV COUNT per miRNA - TOP 25 (DETAILED)
2. **Panel B:** G>T SNV COUNT per miRNA - TOP 20
3. **Panel C:** G>T SNV COUNT per Sample - TOP 15
4. **Panel D:** SNV COUNT by Position - ALL vs G>T

### **Figura 2 (Panel A):**
- G-Content vs Oxidation (scatter + bar chart)

### **Figura 3 (opcional):**
- Group comparison (requiere metadatos de grupos)

---

## 📋 Tablas Generadas

1. **`tabla_top_25_mirnas_snv_1_5.csv`**
   - Top 25 miRNAs con más SNVs
   - Columns: Rank, miRNA, Total SNVs, Percentage (%)

2. **`tabla_top_20_mirnas_gt_1_5.csv`**
   - Top 20 miRNAs con más G>T
   - Columns: Rank, miRNA, G>T Count, Percentage (%)

3. **`tabla_top_15_samples_gt_1_5.csv`**
   - Top 15 muestras con más G>T
   - Columns: Sample, G>T Count, Percentage (%)

4. **`tabla_position_stats_1_5.csv`**
   - Estadísticas por posición
   - Columns: Position, Total SNVs, G>T Count, G>T %, Region

---

## ⚙️ Configuración Avanzada

### **Archivo de configuración:**
`config/config_pipeline_2.R`

```r
# Rutas
data_dir <- "/path/to/your/data"
figures_dir <- "figures"

# Colores
COLOR_GT <- "#D62728"      # Rojo para G>T
COLOR_CONTROL <- "grey60"  # Gris para Control
COLOR_ALS <- "#D62728"     # Rojo para ALS

# Parámetros
seed_start <- 2   # Inicio de región seed
seed_end <- 8     # Fin de región seed
```

### **Ejecutar figuras individuales:**

```bash
# Solo Figura 1
Rscript generate_figure_1_COMPLETE.R

# Solo Figura 1.5 + Tablas
Rscript generate_figure_1_5_PRELIMINARES.R

# Solo Figura 2 Panel A
Rscript generate_figure_2_CORRECTED_PANEL_A.R
```

---

## 📁 Estructura de Archivos

```
pipeline_2/
├── RUN_COMPLETE_PIPELINE.R           # ⭐ SCRIPT PRINCIPAL
├── README_PIPELINE.md                # Este archivo
├── ORGANIZACION_COMPLETA.md          # Documentación detallada
├── VIEWER_FINAL_COMPLETO.html        # HTML viewer interactivo
│
├── config/
│   └── config_pipeline_2.R           # Configuración principal
│
├── scripts/                           # Scripts individuales
│   ├── generate_figure_1_COMPLETE.R
│   ├── generate_figure_1_5_PRELIMINARES.R
│   ├── generate_figure_2_CORRECTED_PANEL_A.R
│   └── generate_figure_3_OPTIMIZED.R
│
└── figures/                           # Outputs generados
    ├── panel_a_*.png                  # Figuras
    ├── panel_b_*.png
    ├── ...
    └── tabla_*.csv                    # Tablas
```

---

## 🔧 Requisitos

### **R Packages:**
```r
install.packages(c(
  "ggplot2", "dplyr", "tidyr", "stringr", 
  "readr", "purrr", "scales", "patchwork", 
  "tictoc"
))
```

### **R Version:**
- R >= 4.0.0

---

## 📊 Estadísticas Incluidas

En **TODOS** los paneles:
- ✅ Mean, SD, median, percentages
- ✅ Peak positions identificadas
- ✅ Top contributors
- ✅ Seed vs Non-Seed comparisons
- ✅ Números explícitos en barras
- ✅ Subtítulos con estadísticas clave

---

## 🎨 Personalización

### **Cambiar colores:**
Editar `config/config_pipeline_2.R`:

```r
COLOR_GT <- "#YOUR_COLOR"      # Color para G>T
COLOR_CONTROL <- "#YOUR_COLOR" # Color para Control
```

### **Cambiar región seed:**
```r
seed_start <- 2   # Tu inicio
seed_end <- 8     # Tu fin
```

### **Cambiar número de tops:**
En los scripts individuales, buscar y modificar:
```r
head(25)  # Cambiar a tu número deseado
```

---

## ⏱️ Tiempos de Ejecución

Con dataset de ~70,000 SNVs:

- **Figura 1 COMPLETE:** ~30 segundos
- **Figura 1.5 + Tablas:** ~45 segundos
- **Figura 2 Panel A:** ~15 segundos
- **Figura 3 (opcional):** ~2-5 minutos (transformación de datos)

**Total pipeline completo:** ~4-6 minutos

---

## 🐛 Troubleshooting

### **Error: "No se encontró el archivo de input"**
- Verificar ruta en `config/config_pipeline_2.R`
- Verificar que el archivo existe y tiene el formato correcto

### **Error: "missing package"**
```r
install.packages("nombre_del_paquete")
```

### **Figuras vacías o incorrectas:**
- Verificar formato del archivo de input
- Verificar que columna `pos:mut` tiene formato correcto: `1:GT,5:AG,...`
- Verificar que hay datos para el análisis

### **HTML viewer no se abre:**
```bash
# Abrir manualmente
open VIEWER_FINAL_COMPLETO.html

# O desde navegador
# Navegar a: pipeline_2/VIEWER_FINAL_COMPLETO.html
```

---

## 📖 Documentación Adicional

- **`ORGANIZACION_COMPLETA.md`**: Estructura detallada del proyecto
- **`DEFINICIONES_METRICAS.md`**: Definiciones de métricas y cálculos
- **`STYLE_GUIDE.md`**: Guía de estilo para figuras

---

## 🔄 Actualizar con Nuevos Datos

```bash
# 1. Colocar nuevo archivo en directorio de datos
# 2. Actualizar ruta en config (si es necesario)
# 3. Ejecutar pipeline
Rscript RUN_COMPLETE_PIPELINE.R

# 4. Ver nuevos resultados
open VIEWER_FINAL_COMPLETO.html
```

---

## ✅ Checklist de Uso

- [ ] Instalar R packages requeridos
- [ ] Configurar ruta de datos en `config/config_pipeline_2.R`
- [ ] Verificar formato de archivo de input
- [ ] Ejecutar `Rscript RUN_COMPLETE_PIPELINE.R`
- [ ] Abrir `VIEWER_FINAL_COMPLETO.html`
- [ ] Revisar figuras generadas en `figures/`
- [ ] Revisar tablas generadas en `figures/`

---

## 📞 Contacto & Soporte

Para preguntas o issues:
1. Revisar documentación en `ORGANIZACION_COMPLETA.md`
2. Verificar formato de input
3. Revisar mensajes de error en console

---

**Última actualización:** 16 Octubre 2025
**Versión:** 1.0
**Status:** ✅ Production Ready

