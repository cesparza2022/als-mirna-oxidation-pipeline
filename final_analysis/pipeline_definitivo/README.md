# Pipeline Definitivo - Análisis de SNVs en miRNAs para ALS

## 🎯 Objetivo

Este pipeline consolida y define el proceso completo de análisis de mutaciones puntuales (SNVs) en miRNAs para el estudio de Esclerosis Lateral Amiotrófica (ALS), estableciendo un flujo de trabajo reproducible y bien documentado.

## 📁 Estructura del Pipeline

```
pipeline_definitivo/
├── README.md                           # Este archivo
├── 01_analisis_inicial/                # Paso 1: Exploración de datos crudos
│   ├── 01_analisis_inicial_dataset.Rmd # Análisis inicial completo
│   ├── outputs/                        # Datos procesados
│   ├── figures/                        # Gráficas generadas
│   └── tables/                         # Tablas de resultados
├── 02_preprocesamiento/                # Paso 2: Preprocesamiento robusto
├── 03_analisis_exploratorio/           # Paso 3: Análisis exploratorio
├── 04_analisis_estadistico/            # Paso 4: Análisis estadístico
├── 05_analisis_funcional/              # Paso 5: Análisis funcional
└── 06_presentacion_final/              # Paso 6: Presentación HTML
```

## 🔬 Pasos del Pipeline

### **Paso 1: Análisis Inicial** ✅
- **Objetivo**: Exploración completa de datos crudos
- **Procesos**:
  - Carga de datos originales
  - Aplicación de split-collapse
  - Cálculo de VAFs
  - Filtrado VAF > 50%
  - Análisis de cobertura y NaNs
  - Identificación de patrones en SNVs, miRNAs y posiciones
  - Comparaciones ALS vs Control

### **Paso 2: Preprocesamiento** (Próximo)
- **Objetivo**: Limpieza y normalización de datos
- **Procesos**:
  - Filtrado por cobertura mínima
  - Detección y corrección de batch effects
  - Normalización de datos
  - Control de calidad

### **Paso 3: Análisis Exploratorio** (Próximo)
- **Objetivo**: Exploración profunda de patrones
- **Procesos**:
  - Análisis de clustering
  - PCA y análisis de componentes
  - Análisis de correlaciones
  - Identificación de outliers

### **Paso 4: Análisis Estadístico** (Próximo)
- **Objetivo**: Comparaciones estadísticas robustas
- **Procesos**:
  - Tests estadísticos apropiados
  - Control de múltiples comparaciones
  - Análisis de potencia
  - Validación de resultados

### **Paso 5: Análisis Funcional** (Próximo)
- **Objetivo**: Interpretación biológica
- **Procesos**:
  - Análisis de pathways
  - Enriquecimiento funcional
  - Análisis de redes
  - Correlaciones clínicas

### **Paso 6: Presentación Final** (Próximo)
- **Objetivo**: Presentación HTML interactiva
- **Procesos**:
  - Consolidación de resultados
  - Creación de dashboard interactivo
  - Documentación completa
  - Visualizaciones finales

## 📊 Metodología Establecida

### **Split-Collapse Process**
1. **Split**: Separar mutaciones múltiples en filas individuales
2. **Collapse**: Agrupar por miRNA + posición + mutación y sumar cuentas
3. **Recalcular**: Totales después del collapse

### **Filtrado VAF**
- **Criterio**: VAF > 50% → NaN
- **Justificación**: Evitar artefactos de secuenciación
- **Cuantificación**: Análisis de NaNs por muestra

### **Análisis por Posición**
- **Enfoque**: Posiciones 1-23 en miRNAs
- **Especial**: Posición 6 (región seed)
- **Métricas**: Frecuencia de mutaciones por posición

### **Comparaciones ALS vs Control**
- **Métricas**: VAFs, cobertura, frecuencia
- **Estadísticas**: Medias, medianas, tests apropiados
- **Visualización**: Gráficas comparativas

## 🎨 Gráficas Clave

1. **Distribución de tipos de mutación**
2. **Distribución de NaNs por muestra**
3. **Cobertura de SNVs**
4. **Top miRNAs más mutados**
5. **Distribución por posiciones**
6. **Comparaciones ALS vs Control**

## 📈 Métricas de Calidad

- **Cobertura de SNVs**: % de muestras sin NaNs
- **Distribución de NaNs**: Por muestra y por SNV
- **Consistencia**: Entre grupos ALS vs Control
- **Reproducibilidad**: Validación de resultados

## 🚀 Cómo Usar

1. **Ejecutar paso a paso**: Cada carpeta contiene un análisis completo
2. **Revisar outputs**: Datos procesados para siguiente paso
3. **Validar figuras**: Gráficas clave para cada análisis
4. **Documentar cambios**: Modificaciones al pipeline

## 📝 Notas Importantes

- **Rutas de archivos**: Ajustar según ubicación real de datos
- **Metadatos**: Necesarios para identificación de grupos
- **Parámetros**: Documentar cambios en filtros y umbrales
- **Reproducibilidad**: Mantener versiones de código

## 🔄 Iteraciones y Mejoras

Este pipeline se basa en múltiples iteraciones de análisis previos:
- **version2**: Análisis inicial exploratorio
- **final_analysis**: Análisis principal estructurado
- **tercer_intento**: Refinamiento metodológico

Cada paso incorpora las mejores prácticas identificadas en iteraciones anteriores.








