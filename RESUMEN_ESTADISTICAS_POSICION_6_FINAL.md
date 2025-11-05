# 📊 ESTADÍSTICAS FINALES POSICIÓN 6 - MUTACIONES G>T

## 🎯 Resumen Ejecutivo

**Archivo analizado:** `results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt`  
**Fecha de análisis:** $(date)  
**Filtros aplicados:** Mutaciones G>T en posición 6 únicamente  
**Muestras identificadas correctamente:** 830 (626 ALS + 204 Control)

---

## 📈 Estadísticas Globales

### Datos Generales
- **Total SNVs G>T en posición 6:** 340
- **miRNAs únicos afectados:** 96
- **Muestras totales:** 830 (626 ALS + 204 Control)

### VAF Promedio por Grupo
- **VAF promedio ALS:** 27,530.72
- **VAF promedio Control:** 27,670.52
- **Diferencia (ALS - Control):** -139.8
- **Porcentaje de diferencia:** -0.51% (Control ligeramente mayor)

### Z-score
- **Z-score promedio:** 0.0362
- **Interpretación:** Las mutaciones G>T en posición 6 son **muy similares entre ALS y Control**, con una diferencia mínima

---

## 🏆 Top miRNAs por VAF Total

### Top 5 miRNAs con Mayor VAF Total en ALS
1. **hsa-miR-16-5p** - 121,920,695 total VAF (194,761 promedio)
2. **hsa-miR-16-5p** - 121,908,177 total VAF (194,741 promedio)
3. **hsa-miR-16-5p** - 121,908,145 total VAF (194,741 promedio)
4. **hsa-miR-16-5p** - 121,908,138 total VAF (194,741 promedio)
5. **hsa-miR-16-5p** - 121,908,132 total VAF (194,741 promedio)

### Top 5 miRNAs con Mayor VAF Total en Control
1. **hsa-miR-16-5p** - 39,299,785 total VAF (192,646 promedio)
2. **hsa-miR-16-5p** - 39,295,383 total VAF (192,624 promedio)
3. **hsa-miR-16-5p** - 39,295,373 total VAF (192,624 promedio)
4. **hsa-miR-16-5p** - 39,295,369 total VAF (192,624 promedio)
5. **hsa-miR-16-5p** - 39,295,368 total VAF (192,624 promedio)

---

## 🔍 Observaciones Clave

### 1. Dominancia de hsa-miR-16-5p
- **hsa-miR-16-5p** es el miRNA más afectado por mutaciones G>T en posición 6
- Aparece en múltiples variantes (diferentes SNVs en la misma posición)
- VAFs extremadamente altas tanto en ALS como en Control

### 2. Diferencias Mínimas entre Grupos
- La diferencia en VAF promedio es solo del 0.51%
- Z-score promedio de 0.0362 indica diferencias estadísticamente insignificantes
- Ambos grupos muestran patrones muy similares de oxidación en posición 6

### 3. Patrón de Múltiples SNVs
- hsa-miR-16-5p tiene múltiples SNVs G>T en posición 6
- Esto sugiere que esta posición es particularmente susceptible a oxidación
- Los valores de VAF son consistentemente altos en todas las variantes

---

## 📈 Gráficas Generadas

- **VAF Promedio: ALS vs Control (Posición 6, G>T)**: `outputs/final_paper_graphs/position_6_vaf_comparison_final.pdf`
- **Distribución de Z-scores (Posición 6, G>T)**: `outputs/final_paper_graphs/position_6_zscore_distribution_final.pdf`

---

## 📝 Conclusiones

### Biológicas
1. **Posición 6 es altamente susceptible** a mutaciones G>T en hsa-miR-16-5p
2. **No hay diferencias significativas** entre ALS y Control en esta posición específica
3. **hsa-miR-16-5p** parece ser particularmente vulnerable a oxidación en posición 6

### Estadísticas
1. **340 SNVs G>T** encontrados en posición 6
2. **96 miRNAs únicos** afectados
3. **Diferencias mínimas** entre grupos (0.51% de diferencia en VAF)

### Clínicas
1. La posición 6 de miRNAs no parece ser un **marcador diferencial** entre ALS y Control
2. La alta frecuencia de mutaciones G>T en hsa-miR-16-5p podría ser un **marcador general de estrés oxidativo**
3. Se requieren análisis en otras posiciones para identificar diferencias específicas de ALS

---

## 🔬 Próximos Pasos Recomendados

1. **Análisis de otras posiciones** (especialmente 2-8 para región semilla)
2. **Análisis funcional** de hsa-miR-16-5p y su papel en ALS
3. **Comparación con regiones no-semilla** para identificar patrones diferenciales
4. **Análisis de clustering** para identificar miRNAs con patrones similares de oxidación

---

*Análisis generado por: R/position_6_analysis_final.R*  
*Archivos de datos: results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt*










