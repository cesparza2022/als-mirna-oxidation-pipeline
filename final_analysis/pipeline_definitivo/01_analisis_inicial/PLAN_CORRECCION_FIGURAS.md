# Plan de Corrección de Figuras para HTML Final

## 📋 Problemas Identificados

### 1. **Idioma Mixto (Español/Inglés)**
- Muchas figuras tienen etiquetas en español
- El HTML está en inglés
- **Solución:** Regenerar figuras críticas en inglés

### 2. **Calidad Visual**
- Etiquetas saturadas (no se pueden leer)
- Colores que no combinan
- Leyendas sobrepuestas
- **Solución:** Ajustar parámetros de ggplot2

### 3. **Coherencia Interpretación**
- Algunas interpretaciones no coinciden con lo que muestra la gráfica
- **Solución:** Revisar y corregir descripciones

### 4. **Figuras Faltantes**
- Algunas figuras críticas no están embebidas
- **Solución:** Verificar y agregar

---

## 🎯 Estrategia de Corrección

### Opción A: Regenerar Figuras Críticas en Inglés (RECOMENDADO)
**Figuras a regenerar (prioridad alta):**

1. **Paso 10A (let-7 vs miR-4500)** - 5 figuras ⭐⭐⭐
   - `paso10a_let7_heatmap_posiciones.png`
   - `paso10a_vaf_comparacion.png`
   - `paso10a_let7_gt_por_posicion.png`
   - `paso10a_tipos_snv_comparacion.png`
   - `paso10a_als_vs_control_scatter.png`

2. **Paso 8C (Heatmaps)** - 3 figuras ⭐⭐⭐
   - `paso8c_heatmap_vaf_completo.png`
   - `paso8c_heatmap_zscore.png`
   - `paso8c_diferencias_posicionales.png`

3. **Paso 9C (Secuencias)** - 4 figuras ⭐⭐
   - `paso9c_heatmap_oxidacion.png`
   - `paso9c_contenido_g_oxidados.png`
   - Sequence logos (ya están en inglés)

4. **Paso 11 (Pathways)** - 3 figuras ⭐⭐
   - `paso11_pathway_enrichment.png`
   - `paso11_network_mirnas.png`
   - `paso11_targets_als_genes.png`

5. **Paso 7A (Temporal)** - 2 figuras ⭐
   - `paso7a_cambios_gt.png`
   - `paso7a_gt_cambios_por_region.png`

**Total a regenerar: ~17 figuras críticas**

---

### Opción B: Traducir Etiquetas en HTML
- Mantener figuras actuales
- Agregar notas en inglés en captions
- Más rápido pero menos profesional

---

### Opción C: Híbrida (ÓPTIMA)
1. Regenerar solo las 5-7 figuras MÁS críticas en inglés
2. Para las demás, mejorar captions en HTML
3. Corregir interpretaciones

---

## 🔧 Correcciones Específicas Necesarias

### Problemas de Calidad Visual Detectados:

1. **Heatmaps:**
   - Etiquetas de muestras (415) ilegibles
   - **Solución:** Remover etiquetas individuales, usar solo grupos

2. **Barplots:**
   - Colores saturados
   - **Solución:** Usar paleta profesional (viridis, RColorBrewer)

3. **Scatter plots:**
   - Puntos sobrepuestos
   - **Solución:** Agregar transparencia (alpha=0.5)

4. **Leyendas:**
   - Texto pequeño
   - **Solución:** Aumentar tamaño (theme(legend.text = element_text(size=12)))

---

## 🎯 Recomendación

**OPCIÓN C (Híbrida):**

1. **Regenerar 7 figuras CRÍTICAS en inglés con calidad mejorada:**
   - paso10a_let7_heatmap_posiciones.png ⭐⭐⭐
   - paso10a_vaf_comparacion.png ⭐⭐⭐
   - paso8c_heatmap_zscore.png ⭐⭐⭐
   - paso9c_heatmap_oxidacion.png ⭐⭐
   - paso11_pathway_enrichment.png ⭐⭐
   - paso7a_cambios_gt.png ⭐
   - paso8c_diferencias_posicionales.png ⭐

2. **Corregir interpretaciones en HTML** donde no coincidan

3. **Mejorar captions** para figuras en español (agregar contexto en inglés)

---

## ⏱️ Tiempo Estimado

- Regenerar 7 figuras: ~10-15 minutos
- Corregir HTML: ~5 minutos
- **Total: ~20 minutos**

---

## ❓ ¿Qué prefieres?

A) **Regenerar las 7 figuras críticas** (mejor resultado, más tiempo)
B) **Solo corregir HTML** (más rápido, menos profesional)
C) **Regenerar TODAS las figuras** (~17 figuras, ~30-40 min)
D) **Revisar juntos figura por figura** y decidir cuáles regenerar








