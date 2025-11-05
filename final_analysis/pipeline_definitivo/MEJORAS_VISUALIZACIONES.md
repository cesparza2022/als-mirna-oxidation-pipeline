# 🎨 MEJORAS DE VISUALIZACIONES - PIPELINE miRNA

## 📊 INSPIRACIÓN DEL PAPER

### **Figura de Referencia:**
- **Panel B**: Distribución posicional de SNVs con heatmap y fracción posicional
- **Panel C**: Análisis de tipos de mutación G→X con fracciones por rank

### **Adaptaciones Propuestas:**

#### **FIGURA 1: CARACTERIZACIÓN DEL DATASET (4 PANELES)**
- **Panel A**: Evolución del dataset (mantener actual)
- **Panel B**: Heatmap posicional de SNVs G>T (inspirado en Panel B)
- **Panel C**: Tipos de mutación G→X por posición (inspirado en Panel C)
- **Panel D**: Top miRNAs con más mutaciones G>T

#### **FIGURA 2: ANÁLISIS G>T EXCLUSIVO ALS vs CONTROL (4 PANELES)**
- **Panel A**: Heatmap de VAFs G>T por miRNA y muestra
- **Panel B**: Distribución de VAFs G>T por grupo
- **Panel C**: Significancia estadística (volcano plot)
- **Panel D**: miRNAs más diferenciales

## 🔧 FUNCIONES NUEVAS A IMPLEMENTAR

### **1. create_positional_heatmap()**
```r
create_positional_heatmap <- function(data, mutation_type = "G>T") {
  # Crear heatmap de distribución posicional
  # Incluir comparación ALS vs Control
  # Marcar región seed (posición 8)
  # Identificar hotspots con significancia
}
```

### **2. analyze_mutation_types()**
```r
analyze_mutation_types <- function(data) {
  # Análisis de tipos de mutación G→X
  # G>T vs G>C vs G>A por posición
  # Incluir significancia estadística
  # Mostrar fracciones por rank
}
```

### **3. analyze_gt_exclusive()**
```r
analyze_gt_exclusive <- function(data, group_data) {
  # Análisis específico de mutaciones G>T
  # Comparación ALS vs Control
  # Estadísticas robustas (Wilcoxon, t-test)
  # Corrección FDR
}
```

## 📋 IMPLEMENTACIÓN

### **Paso 1**: Crear funciones nuevas en `functions_pipeline.R`
### **Paso 2**: Modificar `run_initial_analysis()` para incluir nuevas figuras
### **Paso 3**: Actualizar `config_pipeline.R` con nuevos parámetros
### **Paso 4**: Probar con datos actuales
### **Paso 5**: Documentar resultados

## 🎯 OBJETIVOS

1. **Reducir redundancia**: De 117 figuras a ~20 figuras complejas
2. **Aumentar información**: Cada figura debe responder múltiples preguntas
3. **Mejorar claridad**: Visualizaciones más profesionales y comprensibles
4. **Mantener rigor**: Estadísticas robustas en cada análisis

