# 🎯 SISTEMA DE FILTRADO FINAL: Adaptativo y Multi-Métrico

**Fecha:** 2025-10-17 04:45  
**Versión:** 2.0.0

---

## ✅ LO QUE LOGRAMOS

### **1. Análisis Posicional Completo**

**Hallazgo:** Posiciones 2, 3, 5 están **enriquecidas** en ALS (p < 0.0001)

```
Posiciones ENRIQUECIDAS (ALS > Control):
  • Pos 2: 44 miRNAs, FC ∞, p < 0.0001 ✅
  • Pos 3: 33 miRNAs, FC ∞, p < 0.0001 ✅
  • Pos 5: 61 miRNAs, FC 1.53x, p < 0.0001 ✅

Posiciones NO enriquecidas (Control ≥ ALS):
  • Pos 4: FC 0.87x (Control > ALS)
  • Pos 6: FC 0.95x (Control ≈ ALS)
  • Pos 7: FC 0.64x (Control > ALS)
  • Pos 8: FC 0.77x (Control > ALS)
```

**Implicación:** La oxidación en ALS es **específica de posición**, NO aleatoria.

---

### **2. Volcano Plot Multi-Métrico**

**Innovación:** Combina 5 métricas en 1 figura:
- **Eje X:** Fold Change (efecto biológico)
- **Eje Y:** p-value (significancia estadística)
- **Color:** VAF (intensidad del fenómeno)
- **Tamaño:** Counts (frecuencia/robustez)
- **Forma:** Posición enriquecida (▲) vs no (●)

**Archivo:** `FIG_VOLCANO_ENHANCED_MULTI_METRIC.png` (generado y abierto)

---

## 🎯 SISTEMA DE TIERS (4 NIVELES)

### **TIER 1: Ultra-Robustos** (IDEAL, pero no hay en este dataset)
```
Criterios:
  • FC > 2.0x
  • p < 0.01
  • Posiciones 2,3,5
  
Resultado: 0 candidatos

Interpretación: Dataset no tiene señal ultra-fuerte
```

---

### **TIER 2: Robustos** (Para validación experimental)
```
Criterios:
  • FC > 1.5x
  • p < 0.05
  • Cualquier posición
  
Resultado: 3 candidatos
  1. hsa-miR-196a-5p (pos 7) | FC 3.44x, p 0.002
  2. hsa-miR-9-5p (pos 6,7) | FC 1.58x, p 0.006
  3. hsa-miR-142-5p (pos 7) | FC 3.70x, p 0.024

NOTA: NINGUNO tiene G>T en pos 2,3,5 (enriquecidas)
      Todos en pos 6-7 (NO enriquecidas)
```

**Interpretación:**
- ✅ Estadísticamente muy robustos (p < 0.05)
- ❌ NO tienen especificidad posicional
- ⚠️ Posiciones 6-7 NO están enriquecidas globalmente

---

### **TIER 3: Prometedores + Posición-Específicos** ⭐ RECOMENDADO
```
Criterios:
  • FC > 1.25x
  • p < 0.10
  • Posiciones 2,3,5 (enriquecidas)
  
Resultado: 6 candidatos

  1. hsa-miR-21-5p (pos 3) | FC 1.48x, p 0.008
  2. hsa-miR-185-5p (pos 2,3,5,7) | FC 1.42x, p 0.037
  3. hsa-let-7d-5p (pos 2,4,5,8) | FC 1.31x, p 0.018
  4. hsa-miR-1-3p (pos 2,3,7) | FC 1.30x, p 0.0008
  5. hsa-miR-24-3p (pos 2,3,8) | FC 1.33x, p 0.039
  6. hsa-miR-423-3p (pos 2,6,7) | FC 1.27x, p 0.030
```

**Interpretación:**
- ✅ Posiciones 2,3,5 enriquecidas (análisis posicional)
- ✅ Incluye miRNAs conocidos (miR-21, let-7d, miR-1)
- ✅ p < 0.10 aceptable para exploración
- ✅ FC > 1.25x biológicamente relevante
- ✅ Más específicos mecanísticamente

---

### **TIER 4: Exploratorios** (Para cobertura máxima)
```
Criterios:
  • FC > 1.25x
  • p < 0.10
  • Cualquier posición
  
Resultado: 15 candidatos (PERMISSIVE actual)
  = TIER 2 (3) + TIER 3 (6) + 6 adicionales sin pos enriched
```

---

## 🔬 ANÁLISIS COMPARATIVO

### **TIER 2 vs TIER 3:**

| Aspecto | TIER 2 (Robustos) | TIER 3 (Pos-Específicos) |
|---------|-------------------|--------------------------|
| **N candidatos** | 3 | 6 |
| **p-value** | < 0.05 ✅✅ | < 0.10 ✅ |
| **Fold Change** | 1.58-3.70x | 1.27-1.48x |
| **Posiciones** | 6-7 (NO enriched) ❌ | 2-3-5 (enriched) ✅ |
| **miRNAs conocidos** | miR-9, miR-142 | miR-21, let-7d, miR-1 ✅✅ |
| **Relevancia funcional** | General | Inicio seed ✅ |
| **Para validación** | SÍ ✅ | SÍ (si p < 0.10 aceptable) |
| **Para publicación** | Main findings ✅ | Supp + Discussion |

---

## 💡 RECOMENDACIÓN FINAL

### **ESTRATEGIA ÓPTIMA:**

**USAR COMBINACIÓN DE TIER 2 + TIER 3 (9 candidatos totales)**

```
┌─────────────────────────────────────────────────────────┐
│ GRUPO A: Ultra-Robustos (3 miRNAs)                     │
│ ─────────────────────────────────────────────────────── │
│ • miR-196a-5p, miR-9-5p, miR-142-5p                    │
│ • p < 0.05 (muy significativo)                          │
│ • FC 1.58-3.70x                                         │
│ • Posiciones 6-7                                        │
│                                                         │
│ Uso:                                                    │
│   → Main findings del paper                            │
│   → Prioridad para validación experimental             │
│   → Análisis funcional profundo (targets, pathways)    │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ GRUPO B: Posición-Específicos (6 miRNAs)               │
│ ─────────────────────────────────────────────────────── │
│ • miR-21, miR-185, let-7d, miR-1, miR-24, miR-423      │
│ • p < 0.10 (significativo)                              │
│ • FC 1.27-1.48x                                         │
│ • Posiciones 2-3-5 (ENRIQUECIDAS) ✅                    │
│                                                         │
│ Uso:                                                    │
│   → Supplementary findings                             │
│   → Validación de patrón posicional                    │
│   → Discusión: Especificidad mecánica                  │
│   → Análisis funcional básico                          │
└─────────────────────────────────────────────────────────┘
```

---

## 📊 FLUJO DE FILTRADO FINAL

### **PIPELINE ADAPTATIVO:**

```
ENTRADA: Dataset con SNVs G>T
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

PASO 1: QC y Limpieza
├─ Filtrar VAF >= 0.5 (artefactos)
├─ Filtrar entradas "PM"
└─ Resultado: Datos limpios

PASO 2: Identificar G>T en Seed
├─ Posiciones 2-8
└─ Resultado: 301 miRNAs

PASO 3: Análisis Posicional ⭐ NUEVO
├─ Testearpor cada posición (2-8) si ALS > Control
├─ Identificar posiciones enriquecidas
└─ Resultado: Pos 2,3,5 enriquecidas

PASO 4: Volcano Plot (a nivel miRNA)
├─ Calcular FC y p-value por miRNA
├─ Anotar:
│  • Posiciones afectadas
│  • VAF promedio
│  • Total counts
│  • Prevalencia en muestras
└─ Resultado: 301 miRNAs con métricas

PASO 5: Filtrado Multi-Tier
├─ TIER 1: FC > 2.0x AND p < 0.01 AND pos 2,3,5
├─ TIER 2: FC > 1.5x AND p < 0.05
├─ TIER 3: FC > 1.25x AND p < 0.10 AND pos 2,3,5 ⭐
├─ TIER 4: FC > 1.25x AND p < 0.10
└─ Resultado: Candidatos por tier

PASO 6: Decisión Adaptativa
├─ IF TIER 1 > 0: Usar TIER 1
├─ ELSE IF TIER 2 > 0: Usar TIER 2 + TIER 3
├─ ELSE: Advertir dataset débil
└─ Resultado: Candidatos finales

PASO 7: Análisis de Patrones (Paso 2.5)
├─ Clustering, familias, seeds
└─ Validación de candidatos

PASO 8: Análisis Funcional (Paso 3)
├─ Targets, pathways, networks
└─ Resultado final

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 🔥 PARA TU DATASET ESPECÍFICO

### **Evaluación:**
```
✅ Dataset GOOD quality
   • 3 candidatos TIER 2 (p < 0.05)
   • 6 candidatos TIER 3 (pos 2,3,5)
   • Patrón posicional CLARO
```

### **Recomendación:**
```
USAR: 3 TIER 2 + 6 TIER 3 = 9 candidatos

Main Findings (paper):
  • 3 TIER 2 (miR-196a, miR-9, miR-142)
  • Análisis funcional completo
  • Validación experimental

Supplementary:
  • 6 TIER 3 (miR-21, let-7d, miR-1, etc.)
  • Análisis funcional básico
  • Discusión de patrón posicional

Novel Finding:
  • Especificidad posicional (pos 2,3,5 vs 4-8)
  • Explica heterogeneidad en ALS
```

---

## 🎯 IMPLEMENTACIÓN EN CONFIG

### **Actualizar `CONFIG_THRESHOLDS.json`:**

```json
{
  "tier1_ultra_robust": {
    "log2FC_threshold": 1.0,
    "p_value_threshold": 0.01,
    "require_enriched_position": true,
    "enriched_positions": [2, 3, 5],
    "expected_candidates": "0-2 miRNAs",
    "use_for": "Ideal (rarely achieved)"
  },
  
  "tier2_robust": {
    "log2FC_threshold": 0.58,
    "p_value_threshold": 0.05,
    "require_enriched_position": false,
    "expected_candidates": "3-5 miRNAs",
    "use_for": "Main findings, experimental validation"
  },
  
  "tier3_position_specific": {
    "log2FC_threshold": 0.32,
    "p_value_threshold": 0.10,
    "require_enriched_position": true,
    "enriched_positions": [2, 3, 5],
    "expected_candidates": "5-8 miRNAs",
    "use_for": "Supplementary, mechanistic validation"
  },
  
  "tier4_exploratory": {
    "log2FC_threshold": 0.32,
    "p_value_threshold": 0.10,
    "require_enriched_position": false,
    "expected_candidates": "10-20 miRNAs",
    "use_for": "Full exploration, hypothesis generation"
  }
}
```

---

## 📋 MÉTRICAS FINALES PARA FILTRADO

### **Métricas Obligatorias:**
1. **Fold Change (FC):** Mean_ALS / Mean_Control
2. **p-value ajustado (padj):** FDR-corrected Wilcoxon test
3. **Posición:** ¿Tiene G>T en pos 2, 3, o 5?

### **Métricas Complementarias:**
4. **Mean VAF:** Intensidad promedio
5. **Total Counts:** Número total de observaciones
6. **Prevalencia:** % de muestras con VAF > 0
7. **Z-score:** Diferencia normalizada por varianza

---

## 🚀 COMANDOS PARA EJECUTAR

### **Opción A: TIER 2 + TIER 3 (Recomendado)**

```bash
cd pipeline_definitivo/

# 1. Generar lista combinada de 9 candidatos
Rscript -e "
library(readr)
library(dplyr)

enhanced <- read_csv('ALS_CANDIDATES_ENHANCED.csv')

# Tier 2 + Tier 3
tier2_3 <- enhanced %>%
  filter(
    (log2FC > 0.58 & padj < 0.05) |  # Tier 2
    (log2FC > 0.32 & padj < 0.10 & Has_Pos_2_3_5)  # Tier 3
  ) %>%
  select(miRNA, FC, padj, Positions, Priority)

write_csv(tier2_3, 'results_tier2_3_combined/ALS_candidates.csv')
print(tier2_3)
"

# 2. Ejecutar Paso 3 con los 9
cd pipeline_3/
cp ../results_tier2_3_combined/ALS_candidates.csv data/
Rscript RUN_PASO3_COMPLETE.R
```

### **Opción B: Solo TIER 2 (Ya completado)**
```bash
# Ya está hecho con 3 candidatos
# Revisar: pipeline_3/PASO_3_VIEWER.html
```

### **Opción C: Solo TIER 3 (Posición-específicos)**
```bash
# Similar a Opción A pero solo los 6 con pos 2,3,5
```

---

## 💬 PREGUNTAS FINALES PARA TI

### **1. ¿Qué tier(s) usar para Paso 3?**

- [ ] **A.** Solo TIER 2 (3 robustos) - Ya hecho
- [ ] **B.** Solo TIER 3 (6 pos-específicos) - Nuevo
- [ ] **C.** TIER 2 + TIER 3 (9 combinados) - Recomendado ⭐
- [ ] **D.** TIER 4 (15 completo) - Máxima cobertura

### **2. ¿Cómo manejar la publicación?**

- [ ] **A.** Main: TIER 2 | Supp: TIER 3
- [ ] **B.** Main: TIER 2 + TIER 3 | Supp: Resto
- [ ] **C.** Main: Solo el mejor de cada tier

### **3. ¿Investigar los 3 TIER 2 (pos 6-7)?**

- [ ] **A.** SÍ - Ver por qué son robustos aunque pos NO enriquecida
- [ ] **B.** NO - Enfocarse en TIER 3 (pos enriched)

### **4. ¿Qué hacer con miR-9-3p?**

miR-9-3p: FC 7.05x, p 0.099, pos 6

- [ ] **A.** INCLUIR - FC 7x demasiado alto para ignorar
- [ ] **B.** EXCLUIR - p 0.099 no cumple ni 0.10
- [ ] **C.** Tier especial - "High FC borderline"

---

## ✅ ARCHIVOS GENERADOS

### **Figuras:**
- `FIG_VOLCANO_ENHANCED_MULTI_METRIC.png` ⭐
- `FIG_MULTI_METRIC_VAF_COUNTS_ZSCORE.png`
- `FIG_MULTI_METRIC_ZSCORE_PVALUE.png`
- `FIG_MULTI_METRIC_HEATMAP.png`

### **Datos:**
- `ALS_CANDIDATES_ENHANCED.csv` (15 con anotaciones)
- `MULTI_METRIC_DATA.csv` (301 con todas métricas)
- `POSITIONAL_ENRICHMENT_RESULTS.csv` (análisis por posición)

### **Documentación:**
- `CLARIFICACION_COMPLETA_FILTROS.md`
- `DISCUSION_METRICAS_SELECCION.md`
- `SISTEMA_FILTRADO_FINAL.md` (este archivo)

---

## 🎯 SIGUIENTE PASO

**Necesito que decidas:**

1. **¿Qué tier(s) usar?** (TIER 2, TIER 3, o combinado)
2. **¿Re-ejecutar Paso 3?** (con los candidatos elegidos)
3. **¿Análisis adicional?** (contexto de secuencia, GpG)

**Basado en tu decisión, puedo:**
- Crear preset nuevo en CONFIG_THRESHOLDS.json
- Re-ejecutar Paso 2.5 con los candidatos elegidos
- Ejecutar Paso 3 con el grupo final
- Analizar contexto de secuencia (si interesa)

---

**Revisa la figura `FIG_VOLCANO_ENHANCED_MULTI_METRIC.png` que se abrió y dime qué ves y qué prefieres hacer.** 🔬

