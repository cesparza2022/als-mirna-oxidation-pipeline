# 🧹 PLAN DE LIMPIEZA - HTML VIEWERS

**Objetivo:** Organizar y mantener solo las versiones FINALES y LIMPIAS

## 📊 ANÁLISIS DE HTML VIEWERS ACTUALES (35 archivos)

### ✅ **VERSIONES FINALES IDENTIFICADAS:**

#### **PASO 1: Análisis Inicial**
- **FINAL:** `PASO_1_COMPLETO_VAF_FINAL.html` (10.5 KB, Oct 16 23:56)
- **DESCARTAR:** 
  - `PASO_1_COMPLETO_FINAL.html` (6.1 KB, más antiguo)
  - `PASO_1_COMPLETO_MEJORADO_FINAL.html` (7.8 KB, intermedio)
  - `PASO_1_COMPLETO_MEJORADO_V2.html` (10.4 KB, intermedio)
  - `PASO_1_MULTIPLES_FIGURAS.html` (10.7 KB, intermedio)

#### **PASO 2: Análisis Comparativo**
- **FINAL:** `PASO_2_COMPLETO_FINAL.html` (633 KB, Oct 17 11:36) ⭐ MÁS RECIENTE Y COMPLETO
- **DESCARTAR:**
  - `PASO_2_COMPLETO.html` (11.1 KB, más antiguo)
  - `PASO_2_SIMPLE.html` (5.7 KB, versión simple)
  - `PASO_2_VIEWER.html` (5.4 KB, versión básica)

#### **PASO 2.5: Análisis Específicos**
- **FINAL:** `PASO_2_FINAL_ALL_SEED_GT.html` (11.5 KB, Oct 17 08:44) ⭐ MÁS RECIENTE
- **DESCARTAR:**
  - `PASO_2_COMPLETO_SEED_GT.html` (11.9 KB, versión anterior)
  - `PASO_2_INTEGRADO_QC_ANALISIS.html` (10.9 KB, versión intermedia)

#### **FIGURA 1: Análisis Inicial (Individual)**
- **FINAL:** `VIEWER_FIGURA_1_INICIAL.html` (12.2 KB, Oct 16 22:08) ⭐ MÁS RECIENTE
- **DESCARTAR:**
  - `figura_1_viewer.html` (12.7 KB, más antiguo)
  - `figure_1_viewer_v2.html` (12.7 KB, v2)
  - `figure_1_viewer_v4.html` (17.0 KB, v4)
  - `figure_1_viewer_v5_FINAL.html` (7.9 KB, v5)
  - `VIEWER_FIGURA_1_SIMPLE_CLEAN.html` (987 KB, muy pesado)

#### **FIGURA 2: Análisis Mecanístico (Individual)**
- **FINAL:** `figure_2_viewer.html` (17.6 KB, Oct 16 00:28) ⭐ ÚNICO

### 🗑️ **ARCHIVOS A DESCARTAR (Versiones Intermedias/Repetidas):**

#### **Viewers Genéricos/Repetidos:**
- `FIGURAS_COMPARACION_COMPLETA.html`
- `FIGURAS_CORRECTED_VIEWER.html`
- `FIGURAS_CORREGIDAS_FINAL.html`
- `FIGURAS_SELECCIONADAS_ANALISIS.html`
- `GALERIA_COMPLETA_98_GRAFICAS.html`
- `GLOSARIO_INTERACTIVO_TODAS_LAS_FIGURAS.html`
- `MASTER_VIEWER.html`
- `MEJORES_ANTIGUAS_COMPARACION.html`
- `PROFESSIONAL_VIEWER.html`
- `REVISION_COMPLETA_TODAS_GRAFICAS.html`
- `TODAS_LAS_GRAFICAS_COMPLETO.html`
- `VIEWER_AVANZADO.html`
- `VIEWER_BALANCED.html`
- `VIEWER_COMPARATIVO_TODAS_VERSIONES.html`
- `VIEWER_FINAL_COMPLETO.html`
- `VIEWER_MEJORAS_PEER_REVIEW.html`

#### **Diagnósticos (Mantener solo si son útiles):**
- `DIAGNOSTICO_FILTRO_VAF.html` (4.5 KB)
- `DIAGNOSTICO_VAF_REAL.html` (5.3 KB)

## 🎯 **ESTRUCTURA FINAL PROPUESTA:**

```
HTML_VIEWERS_FINALES/
├── PASO_1_ANALISIS_INICIAL.html          (PASO_1_COMPLETO_VAF_FINAL.html)
├── PASO_2_ANALISIS_COMPARATIVO.html     (PASO_2_COMPLETO_FINAL.html)
├── PASO_2.5_ANALISIS_SEED_GT.html       (PASO_2_FINAL_ALL_SEED_GT.html)
├── FIGURA_1_INDIVIDUAL.html             (VIEWER_FIGURA_1_INICIAL.html)
├── FIGURA_2_INDIVIDUAL.html              (figure_2_viewer.html)
└── DIAGNOSTICOS/
    ├── DIAGNOSTICO_FILTRO_VAF.html
    └── DIAGNOSTICO_VAF_REAL.html
```

## 📋 **PLAN DE ACCIÓN:**

1. **Crear directorio `HTML_VIEWERS_FINALES/`**
2. **Copiar solo las versiones finales**
3. **Mover archivos antiguos a `HTML_VIEWERS_ARCHIVO/`**
4. **Crear índice con descripción de cada viewer**
5. **Limpiar directorio principal**

## ✅ **BENEFICIOS:**
- Solo 5-6 HTML viewers finales
- Estructura clara y organizada
- Fácil navegación
- Sin duplicados
- Versiones archivadas por seguridad
