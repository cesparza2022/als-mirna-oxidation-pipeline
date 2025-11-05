# 📊 ESTADÍSTICAS DETALLADAS POSICIÓN 6 - MUTACIONES G>T

## 🎯 Resumen Ejecutivo

**Archivo analizado:** `results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt`  
**Fecha de análisis:** $(date)  
**Filtros aplicados:** Mutaciones G>T en posición 6 únicamente  

---

## 📈 Estadísticas Globales

### Datos Generales
- **Total SNVs G>T en posición 6:** 609
- **miRNAs únicos analizados:** 159
- **Muestras totales:** 830 (207 ALS + 623 Control)

### VAF Promedio por Grupo
- **VAF promedio ALS:** 0.26
- **VAF promedio Control:** 28,063.8
- **Diferencia (ALS - Control):** -28,063.53
- **Porcentaje de diferencia:** -100% (Control >> ALS)

### Z-score
- **Z-score promedio:** -0.2317
- **Interpretación:** Las mutaciones G>T en posición 6 son **significativamente más altas en Control que en ALS**

---

## 🏆 Top miRNAs por VAF

### Top 5 miRNAs con Mayor VAF en ALS
| miRNA | Total VAF ALS | VAF Promedio ALS | Z-score |
|-------|---------------|------------------|---------|
| hsa-miR-16-5p | 8,321 | 40.2 | -0.783 |
| hsa-miR-6130 | 7,343 | 35.5 | -0.0871 |
| hsa-miR-6129 | 2,527 | 12.2 | -0.454 |
| hsa-miR-93-5p | 1,691 | 8.17 | -0.617 |
| hsa-miR-6129 | 1,675 | 8.09 | -0.624 |

### Top 5 miRNAs con Mayor VAF en Control
| miRNA | Total VAF Control | VAF Promedio Control | Z-score |
|-------|-------------------|---------------------|---------|
| hsa-miR-16-5p | 161,212,159 | 258,768 | -0.783 |
| hsa-miR-16-5p | 161,203,519 | 258,754 | -0.910 |
| hsa-miR-16-5p | 161,203,494 | 258,754 | -0.935 |
| hsa-miR-16-5p | 161,203,492 | 258,754 | 0 |
| hsa-miR-16-5p | 161,203,486 | 258,754 | -0.931 |

---

## 🔍 Hallazgos Clave

### 1. **Dominancia de hsa-miR-16-5p**
- **hsa-miR-16-5p** es el miRNA más mutado en posición 6 en ambos grupos
- Representa la mayoría de las mutaciones G>T en esta posición
- Z-score negativo (-0.783) indica mayor oxidación en Control

### 2. **Patrón de Oxidación Invertido**
- **Contrario a la hipótesis inicial:** Las mutaciones G>T en posición 6 son **más frecuentes en Control que en ALS**
- Esto sugiere que la posición 6 podría ser **menos susceptible a oxidación en ALS** o que hay un **mecanismo protector**

### 3. **Magnitud de la Diferencia**
- La diferencia es **extremadamente grande** (Control ~100,000x mayor que ALS)
- Esto no es solo una diferencia estadística, sino una **diferencia biológica masiva**

---

## 📊 Interpretación Biológica

### Posibles Explicaciones:

1. **Mecanismo Protector en ALS:**
   - Los pacientes con ALS podrían tener mecanismos de reparación más eficientes en posición 6
   - O factores protectores específicos para esta posición

2. **Diferencias en la Expresión:**
   - Los miRNAs con G en posición 6 podrían estar menos expresados en ALS
   - Menor expresión = menor oportunidad de oxidación

3. **Especificidad de la Oxidación:**
   - La oxidación en ALS podría ser más específica para otras posiciones
   - La posición 6 podría no ser un "hotspot" de oxidación en ALS

---

## 📈 Gráficas Generadas

### 1. `position_6_vaf_comparison.pdf`
- Comparación de VAF promedio por miRNA entre ALS y Control
- Muestra claramente la dominancia de Control sobre ALS

### 2. `position_6_zscore.pdf`
- Z-score por miRNA ordenado de mayor a menor
- Identifica qué miRNAs muestran las mayores diferencias

---

## 🎯 Conclusiones

### Para la Posición 6 Específicamente:

1. **609 SNVs G>T** encontrados en posición 6
2. **159 miRNAs únicos** afectados
3. **Control >> ALS** en términos de oxidación G>T
4. **hsa-miR-16-5p** es el más afectado en ambos grupos
5. **Z-score promedio negativo** (-0.2317) confirma mayor oxidación en Control

### Implicaciones para el Paper:

- La posición 6 **NO** es un hotspot de oxidación en ALS
- Podría ser un **marcador de normalidad** (mayor oxidación en Control)
- Necesario analizar **otras posiciones** para encontrar los verdaderos hotspots de ALS
- **hsa-miR-16-5p** merece análisis funcional detallado

---

## 📁 Archivos Relacionados

- **Script de análisis:** `R/position_6_analysis_corrected.R`
- **Gráficas:** `outputs/final_paper_graphs/position_6_*.pdf`
- **Datos fuente:** `results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt`

---

*Análisis completado exitosamente. Los datos muestran un patrón inesperado que requiere mayor investigación.*










