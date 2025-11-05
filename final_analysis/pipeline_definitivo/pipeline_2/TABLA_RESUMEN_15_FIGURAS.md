# 📊 TABLA RESUMEN - 15 FIGURAS PASO 2

---

## **GRUPO A: GLOBAL COMPARISONS** (¿HAY DIFERENCIA?)

| # | Nombre | Qué Muestra | Hallazgo Clave | Script |
|---|--------|-------------|----------------|--------|
| **2.1** | VAF Comparison | Violin plots ALS vs Control | **Control > ALS** (p < 0.001) | `generate_FIG_2.1_*.R` |
| **2.2** | Distributions | Density plots, CDF | Distribuciones diferentes | `generate_FIG_2.2_*.R` |
| **2.3** | Volcano Plot | 620 miRNAs tested | **301 diferenciales** (FDR < 0.05) | `generate_FIG_2.3_*.R` |

---

## **GRUPO B: POSITIONAL ANALYSIS** (¿DÓNDE?)

| # | Nombre | Qué Muestra | Hallazgo Clave | Script |
|---|--------|-------------|----------------|--------|
| **2.4** | Heatmap RAW | 301 miRNAs × 23 pos (absoluto) | Valores raw, hotspot 22-23 | `generate_FIG_2.4_*.R` |
| **2.5** | Heatmap Z-Score | 301 miRNAs × 23 pos (normalizado) | **100 outliers**, 94 en non-seed | `generate_FIG_2.5_*.R` ⭐ |
| **2.6** | Positional Profiles | Line plots con CI | Control > ALS en mayoría | `generate_FIG_2.6_*.R` |
| **2.13** | Density ALS | Density heatmap + barplot | ALS: 43,312 SNVs, hotspot 22 | `generate_FIG_2.13-15_*.R` |
| **2.14** | Density Control | Density heatmap + barplot | Control: 18,579 SNVs | `generate_FIG_2.13-15_*.R` |
| **2.15** | Density Combined | Side-by-side comparison | Hotspots compartidos | `generate_FIG_2.13-15_*.R` |

---

## **GRUPO C: HETEROGENEITY ANALYSIS** (¿QUÉ TAN VARIABLES?)

| # | Nombre | Qué Muestra | Hallazgo Clave | Script |
|---|--------|-------------|----------------|--------|
| **2.7** | PCA + PERMANOVA | Multivariate space | **R² = 2%** (grupos NO separados) | `generate_FIG_2.7_*.R` |
| **2.8** | Clustering | Hierarchical clustering | Clustering mixto (no perfecto) | `generate_FIG_2.8_*.R` |
| **2.9** | CV Analysis | Coefficient of Variation | **ALS +35% heterogéneo** ⭐⭐ | `generate_FIG_2.9_*.R` |

---

## **GRUPO D: SPECIFICITY & ENRICHMENT** (¿QUÉ MECANISMO? ¿QUÉ VALIDAR?)

| # | Nombre | Qué Muestra | Hallazgo Clave | Script |
|---|--------|-------------|----------------|--------|
| **2.10** | G>T Ratio | G>T / todas G>X | **87% de G>X son G>T** | `generate_FIG_2.10_*.R` |
| **2.11** | Mutation Spectrum | 12 mutation types | **Ts/Tv = 0.12** (NO aging) ⭐⭐⭐ | `generate_FIG_2.11_*.R` |
| **2.12** | Enrichment | Biomarker candidates | **112 candidates** identificados | `generate_FIG_2.12_*.R` |

---

## 🎯 **ORGANIZACIÓN POR DATOS USADOS**

| Figuras | Datos de Entrada | N° Observaciones |
|---------|------------------|------------------|
| 2.1, 2.2 | Total VAF per sample | 415 samples |
| 2.3 | Contingency tables per miRNA | 620 miRNAs |
| 2.4, 2.5, 2.6 | 301 miRNAs × 23 positions | 1,377 SNVs |
| 2.13-2.15 | All SNVs by position | 61,891 observations |
| 2.7, 2.8 | Full matrix | 415 samples × 1,377 SNVs |
| 2.9 | VAF per miRNA | 620 miRNAs |
| 2.10 | G mutations only | G>T, G>A, G>C |
| 2.11 | All 12 mutation types | 5,448 SNVs |
| 2.12 | Burden + CV metrics | 620 miRNAs filtered |

---

## 🔄 **FLUJO DE EJECUCIÓN**

```
ORDEN RECOMENDADO (como está en RUN_COMPLETE_PIPELINE_PASO2.R):

1. Fig 2.1  → Establece diferencia global
2. Fig 2.2  → Valida con distribuciones
3. Fig 2.3  → Identifica miRNAs diferenciales
   ↓
4. Fig 2.4  → Mapea absolutos por posición
5. Fig 2.5  → Identifica outliers (normalizado)
6. Fig 2.6  → Muestra trends posicionales
7. Fig 2.13 → Density ALS
8. Fig 2.14 → Density Control
9. Fig 2.15 → Density combined
   ↓
10. Fig 2.7  → PCA multivariate
11. Fig 2.8  → Clustering jerárquico
12. Fig 2.9  → CV heterogeneidad
    ↓
13. Fig 2.10 → G>T specificity
14. Fig 2.11 → Mutation spectrum
15. Fig 2.12 → Biomarker candidates

✅ Este orden tiene LÓGICA científica
✅ Cada figura construye sobre las anteriores
✅ Responde preguntas en secuencia natural
```

---

## 📈 **OUTPUTS POR SCRIPT**

```
UN SCRIPT = UNA O MÁS FIGURAS

Scripts con 1 figura (11 scripts):
  • generate_FIG_2.1_*.R  → 1 PNG
  • generate_FIG_2.2_*.R  → 1 PNG
  • generate_FIG_2.3_*.R  → 1 PNG
  • generate_FIG_2.4_*.R  → 1 PNG
  • generate_FIG_2.5_*.R  → 1 PNG
  • generate_FIG_2.6_*.R  → 1 PNG
  • generate_FIG_2.7_*.R  → 1 PNG
  • generate_FIG_2.8_*.R  → 1 PNG
  • generate_FIG_2.9_*.R  → 1 PNG (combinado de 4 panels)
  • generate_FIG_2.10_*.R → 1 PNG (combinado de 4 panels)
  • generate_FIG_2.11_*.R → 1 PNG (combinado de 4 panels)
  • generate_FIG_2.12_*.R → 1 PNG (combinado de 4 panels)

Scripts con múltiples figuras (1 script):
  • generate_FIG_2.13-15_*.R → 3 PNGs
    ├── FIG_2.13 (ALS)
    ├── FIG_2.14 (Control)
    └── FIG_2.15 (Combined)
```

---

## 🎯 **PROPÓSITO DE CADA FIGURA**

```
ESTABLECER FENÓMENO (Figs 2.1-2.3):
  → ¿Existe diferencia? → SÍ
  → ¿Qué miRNAs? → 301 identificados
  
CARACTERIZAR ESPACIALMENTE (Figs 2.4-2.6, 2.13-15):
  → ¿Dónde? → Hotspots 22-23
  → ¿Outliers? → 100 detectados
  → ¿Trends? → Control > ALS consistente
  → ¿Distribución? → Mayoría VAF bajo-medio
  
EXPLICAR VARIABILIDAD (Figs 2.7-2.9):
  → ¿Por qué diferencia pequeña? → Heterogeneidad
  → ¿Grupos separados? → NO (R² = 2%)
  → ¿Cuánta heterogeneidad? → ALS +35%
  
VALIDAR MECANISMO (Figs 2.10-2.12):
  → ¿Es oxidación? → SÍ (87% G>T, Ts/Tv=0.12)
  → ¿Qué validar? → 112 candidates
```

---

## 📚 **ARCHIVOS DE SOPORTE**

```
MASTER SCRIPT:
  📄 RUN_COMPLETE_PIPELINE_PASO2.R
     → Ejecuta los 15 scripts en orden
     → Valida inputs
     → Genera summary

HTML VIEWER:
  🌐 PASO_2_VIEWER_COMPLETO_FINAL.html
     → Muestra las 15 figuras
     → Organizado por grupos (A, B, C, D)
     → Hallazgos destacados

DOCUMENTACIÓN:
  📄 PIPELINE_PASO2_100_COMPLETO.md
     → Status del pipeline
  
  📄 QUE_ES_EL_PIPELINE_EXPLICACION.md
     → Explicación técnica completa
  
  📄 DIAGRAMA_PIPELINE_VISUAL.md
     → Diagramas de flujo
  
  📄 ORGANIZACION_15_FIGURAS_COMPLETA.md
     → Lógica y dependencias (este archivo)
  
  📄 TABLA_RESUMEN_15_FIGURAS.md
     → Tabla simple de referencia rápida
```

---

## 🎨 **VISUALIZACIÓN DE LA ORGANIZACIÓN**

```
┌─────────────────────────────────────────────────────────────┐
│                    PASO 2 (15 Figuras)                      │
└─────────────────────────────────────────────────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
   ┌────────┐         ┌────────┐        ┌────────┐
   │GRUPO A │         │GRUPO B │        │GRUPO C │
   │(¿HAY?) │         │(¿DÓNDE)│        │(¿POR   │
   │        │         │        │        │ QUÉ?)  │
   │3 figs  │         │6 figs  │        │3 figs  │
   └────────┘         └────────┘        └────────┘
                           │
                      ┌────────┐
                      │GRUPO D │
                      │(¿QUÉ   │
                      │HACER?) │
                      │3 figs  │
                      └────────┘

FLUJO CIENTÍFICO:
  A → ¿Hay fenómeno? → SÍ
  B → ¿Dónde está? → Posiciones 22-23
  C → ¿Por qué pequeño? → Heterogeneidad
  D → ¿Qué hacer? → Validar 112 candidates
```

---

**¿Ahora está más claro cómo se organizan las 15 figuras?** 📖

**¿Quieres que probemos ejecutar el pipeline completo?** 🧪

