# PRESENTACIÓN COMPLETA: ANÁLISIS DE SNVs EN miRNAs

## Slides Generados:

1. **01_titulo_objetivos.png** - Título y Objetivos del Estudio
2. **02_preprocesamiento.png** - Proceso de Preprocesamiento de Datos
3. **03_analisis_posicion.png** - Análisis por Posición en miRNAs
4. **04_validez_vafs_zscores.png** - Discusión sobre Validez de VAFs y Z-scores
5. **05_hallazgos_principales.png** - Hallazgos Principales del Estudio
6. **06_conclusiones.png** - Conclusiones y Perspectivas Futuras

## Resumen del Análisis:

### Datos Analizados:
- 415 muestras (313 ALS + 102 Control)
- 4,472 SNVs después de preprocesamiento
- 1,247 miRNAs únicos

### Hallazgos Principales:
- Diferencias significativas en patrones de oxidación
- Control: Mayor carga oxidativa que ALS
- Región seed (pos 2-6): Mayor diferenciación
- Posición 6: Punto caliente de oxidación

### Metodología:
- Preprocesamiento robusto con filtros de calidad
- Análisis por posición con normalización RPM
- Clustering jerárquico y análisis PCA
- Validación técnica de artefactos

### Validez:
- Tests estadísticos apropiados
- Corrección múltiple de comparaciones
- Validación cruzada de resultados
- Exclusión de artefactos técnicos

### Discusión sobre VAFs vs Z-scores:
- VAFs: Valores absolutos, útiles para presencia y magnitud
- Z-scores: Valores relativos, útiles para patrones diferenciales
- Ambos enfoques son válidos y complementarios
- La combinación permite interpretación más robusta
