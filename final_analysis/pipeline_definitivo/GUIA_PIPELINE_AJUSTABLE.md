# 🔧 GUÍA: PIPELINE AJUSTABLE DE ANÁLISIS miRNA-ALS

**Fecha:** 2025-10-17 04:00
**Versión:** 1.0.0

---

## 🎯 PROBLEMA RESUELTO

**Antes:** Pipeline rígido con 3 candidatos fijos.

**Ahora:** Pipeline **completamente ajustable** con 4 presets + configuración personalizada.

---

## 📊 PRESETS DISPONIBLES

### **1. STRICT** (Ultra-conservador)
```
Umbrales:
  • FC > 2.0x (100% más en ALS)
  • p-value < 0.01

Resultado: 1 candidato
  → hsa-miR-196a-5p (el más robusto)

Uso: Para publicación con máxima confianza
```

### **2. MODERATE** (Balanceado) ⭐ ACTUAL
```
Umbrales:
  • FC > 1.5x (50% más en ALS)
  • p-value < 0.05

Resultado: 3 candidatos
  → hsa-miR-196a-5p
  → hsa-miR-9-5p
  → hsa-miR-142-5p

Uso: Balance entre robustez y cobertura
```

### **3. PERMISSIVE** (Exploratorio)
```
Umbrales:
  • FC > 1.25x (25% más en ALS)
  • p-value < 0.10

Resultado: 15 candidatos
  → Incluye let-7d-5p, miR-21-5p, miR-20a-5p, etc.

Uso: Exploración inicial o análisis comprehensivo
```

### **4. EXPLORATORY** (Máxima cobertura)
```
Umbrales:
  • FC > 1.0x (cualquier aumento en ALS)
  • p-value < 0.20

Resultado: ~48 candidatos

Uso: Análisis exploratorio completo
```

---

## 🚀 CÓMO USAR EL PIPELINE AJUSTABLE

### **OPCIÓN 1: Usar un preset**

```bash
# Desde pipeline_definitivo/
Rscript RUN_WITH_THRESHOLDS.R moderate      # 3 candidatos
Rscript RUN_WITH_THRESHOLDS.R permissive    # 15 candidatos
Rscript RUN_WITH_THRESHOLDS.R exploratory   # 48 candidatos
Rscript RUN_WITH_THRESHOLDS.R strict        # 1 candidato
```

### **OPCIÓN 2: Configuración personalizada**

**Paso 1:** Editar `CONFIG_THRESHOLDS.json`
```json
{
  "paso2_volcano_thresholds": {
    "custom": {
      "log2FC_threshold": 0.40,     ← Cambiar esto
      "fc_threshold": 1.32,          ← Esto se calcula: 2^0.40
      "pvalue_threshold": 0.08       ← Cambiar esto
    }
  }
}
```

**Paso 2:** Ejecutar con custom
```bash
Rscript RUN_WITH_THRESHOLDS.R custom
```

---

## 📊 TABLA COMPARATIVA DE RESULTADOS

| Preset | FC Threshold | p-value | # Candidatos | Tiempo Paso 3 |
|--------|--------------|---------|--------------|---------------|
| **strict** | > 2.0x | < 0.01 | **1** | ~6 min |
| **moderate** | > 1.5x | < 0.05 | **3** ⭐ | ~20 min |
| **permissive** | > 1.25x | < 0.10 | **15** | ~1.5 hr |
| **exploratory** | > 1.0x | < 0.20 | **48** | ~4 hr |

---

## 🔍 CANDIDATOS POR PRESET

### **STRICT (1):**
```
1. hsa-miR-196a-5p (FC 3.4x, p 0.002)
```

### **MODERATE (3):**
```
1. hsa-miR-196a-5p (FC 3.4x, p 0.002)
2. hsa-miR-9-5p    (FC 1.6x, p 0.006)
3. hsa-miR-142-5p  (FC 3.7x, p 0.024)
```

### **PERMISSIVE (15):**
```
Los 3 anteriores +
 4. hsa-miR-1-3p     (FC 1.3x, p 0.001)
 5. hsa-miR-20a-5p   (FC 1.4x, p 0.001)
 6. hsa-miR-425-5p   (FC 1.3x, p 0.003)
 7. hsa-miR-21-5p    (FC 1.5x, p 0.008)
 8. hsa-let-7d-5p    (FC 1.3x, p 0.018)
 9. hsa-miR-423-3p   (FC 1.3x, p 0.030)
10. hsa-miR-361-5p   (FC 1.3x, p 0.035)
11. hsa-miR-185-5p   (FC 1.4x, p 0.037)
12. hsa-miR-24-3p    (FC 1.3x, p 0.040)
13. hsa-miR-30e-3p   (FC 2.0x, p 0.069)
14. hsa-miR-6721-5p  (FC 1.3x, p 0.099)
15. hsa-miR-9-3p     (FC 7.0x, p 0.099)
```

---

## 💡 RECOMENDACIONES POR ESCENARIO

### **Para EXPLORACIÓN inicial:**
```bash
Rscript RUN_WITH_THRESHOLDS.R permissive

→ 15 candidatos
→ Ver si hay convergencia funcional
→ Identificar sub-módulos
```

### **Para PUBLICACIÓN:**
```bash
Rscript RUN_WITH_THRESHOLDS.R moderate
# o
Rscript RUN_WITH_THRESHOLDS.R strict

→ 1-3 candidatos ultra-robustos
→ Análisis profundo
→ Máxima confianza estadística
```

### **Para VALIDACIÓN experimental:**
```bash
Rscript RUN_WITH_THRESHOLDS.R permissive

→ 15 candidatos para qPCR
→ Priorizar por FC o p-value
→ Validar top 5-10
```

---

## 🔄 WORKFLOW COMPLETO AJUSTABLE

### **1. Exploración inicial (Permissive):**
```bash
# Identificar todos los candidatos posibles
Rscript RUN_WITH_THRESHOLDS.R permissive

# Ejecutar Paso 3 con los 15
cd pipeline_3/
cp ../results_threshold_permissive/ALS_candidates.csv data/
Rscript RUN_PASO3_COMPLETE.R

# Revisar convergencia funcional
# ¿Cuántos genes compartidos?
# ¿Hay sub-módulos?
```

### **2. Refinamiento (Moderate):**
```bash
# Filtrar a los más robustos
Rscript RUN_WITH_THRESHOLDS.R moderate

# Análisis profundo de los 3
cd pipeline_3/
cp ../results_threshold_moderate/ALS_candidates.csv data/
Rscript RUN_PASO3_COMPLETE.R
```

### **3. Publicación (Strict):**
```bash
# Solo el candidato principal
Rscript RUN_WITH_THRESHOLDS.R strict

# Análisis exhaustivo del miR-196a-5p
```

---

## 📂 ESTRUCTURA DE OUTPUTS

```
pipeline_definitivo/
├── CONFIG_THRESHOLDS.json          ← Configuración
├── RUN_WITH_THRESHOLDS.R           ← Script maestro
│
├── results_threshold_strict/       ← 1 candidato
│   ├── ALS_candidates.csv
│   └── COMPARACION_PRESETS.png
│
├── results_threshold_moderate/     ← 3 candidatos ⭐
│   ├── ALS_candidates.csv
│   └── COMPARACION_PRESETS.png
│
├── results_threshold_permissive/   ← 15 candidatos
│   ├── ALS_candidates.csv
│   └── COMPARACION_PRESETS.png
│
└── results_threshold_exploratory/  ← 48 candidatos
    ├── ALS_candidates.csv
    └── COMPARACION_PRESETS.png
```

---

## 🎯 COMPARACIÓN: 3 vs 15 CANDIDATOS

### **CON 3 CANDIDATOS (MODERATE):**

**Ventajas:**
- ✅ Ultra-robustos estadísticamente
- ✅ FC alto (1.6-3.7x)
- ✅ Análisis rápido (~20 min)
- ✅ 1,207 genes compartidos (convergencia fuerte)

**Desventajas:**
- ❌ Puede perder candidatos borderline
- ❌ Menos cobertura biológica

---

### **CON 15 CANDIDATOS (PERMISSIVE):**

**Ventajas:**
- ✅ Mayor cobertura biológica
- ✅ Incluye let-7d, miR-21, miR-20a (conocidos)
- ✅ Puede identificar sub-módulos
- ✅ Más genes totales (> 10,000 targets)

**Desventajas:**
- ❌ Algunos con FC bajo (1.25-1.4x)
- ❌ Algunos con p-value borderline (0.08-0.10)
- ❌ Análisis más lento (1-2 horas)

---

## 🔥 MI RECOMENDACIÓN

### **ESTRATEGIA DE 2 PASOS:**

**PASO 1: Exploración (Permissive)**
```bash
# Ejecuta con 15 candidatos
Rscript RUN_WITH_THRESHOLDS.R permissive

# Ejecuta Paso 3
cd pipeline_3/
cp ../results_threshold_permissive/ALS_candidates.csv data/
Rscript RUN_PASO3_COMPLETE.R

# PREGUNTA: ¿Cuántos genes compartidos hay?
# Si > 500 genes compartidos entre todos → hay convergencia
# Si no → son hallazgos independientes
```

**PASO 2: Refinamiento (Moderate o Strict)**
```bash
# Basándote en los hallazgos, filtra a los más robustos
Rscript RUN_WITH_THRESHOLDS.R moderate

# Análisis profundo para publicación
```

---

## 🎯 EJEMPLOS DE USO

### **Ejemplo 1: "Quiero ver si hay más candidatos interesantes"**
```bash
Rscript RUN_WITH_THRESHOLDS.R permissive
# → 15 candidatos
# → Incluye let-7d, miR-21, miR-20a
# → Paso 3 ~1.5 horas
```

### **Ejemplo 2: "Quiero solo el más robusto para validar"**
```bash
Rscript RUN_WITH_THRESHOLDS.R strict
# → 1 candidato (miR-196a-5p)
# → FC 3.4x, p 0.002
# → Paso 3 ~6 minutos
```

### **Ejemplo 3: "Quiero umbrales personalizados"**
```bash
# Editar CONFIG_THRESHOLDS.json:
# "log2FC_threshold": 0.45  (FC ~1.37x)
# "pvalue_threshold": 0.08

Rscript RUN_WITH_THRESHOLDS.R custom
# → ~8-10 candidatos
```

---

## 📊 ANÁLISIS DE SENSIBILIDAD

### **Probemos los 4 presets:**

```bash
# Generar resultados para todos
for preset in strict moderate permissive exploratory; do
  Rscript RUN_WITH_THRESHOLDS.R $preset
done

# Comparar convergencia funcional
# ¿Los 15 de 'permissive' tienen convergencia?
# ¿O solo los 3 de 'moderate'?
```

---

## 🔍 CÓMO DECIDIR QUÉ PRESET USAR

### **Pregúntate:**

**1. ¿Cuál es tu objetivo?**
- Publicación → **strict** o **moderate**
- Exploración → **permissive**
- Generación de hipótesis → **exploratory**

**2. ¿Cuánto tiempo tienes?**
- < 30 min → **strict** o **moderate**
- 1-2 horas → **permissive**
- Varias horas → **exploratory**

**3. ¿Qué tan robustos quieres los hits?**
- Ultra-robustos → **strict** (FC > 2x)
- Robustos → **moderate** (FC > 1.5x)
- Exploratorios → **permissive** (FC > 1.25x)

---

## 🎯 RECOMENDACIÓN ESPECÍFICA PARA TU CASO

**Sugerencia: Empezar con PERMISSIVE (15 candidatos)**

**Razones:**
1. ✅ Te da más contexto biológico
2. ✅ Incluye miRNAs bien conocidos (let-7d, miR-21, miR-20a)
3. ✅ Puedes ver si hay sub-módulos o clusters
4. ✅ Tiempo razonable (~1.5 horas)
5. ✅ Luego puedes filtrar a moderate para profundizar

**Workflow:**
```bash
# 1. Exploración (15 candidatos)
Rscript RUN_WITH_THRESHOLDS.R permissive
cd pipeline_3/
cp ../results_threshold_permissive/ALS_candidates.csv data/
Rscript RUN_PASO3_COMPLETE.R

# 2. Revisar resultados
# ¿Cuántos genes compartidos entre los 15?
# ¿Hay sub-grupos?

# 3. Refinamiento (si es necesario)
cd ..
Rscript RUN_WITH_THRESHOLDS.R moderate
# Análisis profundo de los top 3
```

---

## 📋 MODIFICAR UMBRALES MANUALMENTE

### **Editar `CONFIG_THRESHOLDS.json`:**

```json
{
  "paso2_volcano_thresholds": {
    "custom": {
      "description": "Mis umbrales personalizados",
      "log2FC_threshold": 0.40,      ← Cambiar aquí
      "fc_threshold": 1.32,          ← O aquí (2^0.40)
      "pvalue_threshold": 0.08,      ← Cambiar aquí
      "min_samples_per_group": 5
    }
  }
}
```

**Luego ejecutar:**
```bash
Rscript RUN_WITH_THRESHOLDS.R custom
```

---

## 🔄 FLUJO ITERATIVO RECOMENDADO

```
┌─────────────────────────────────────────┐
│ 1. EXPLORAR (permissive)                │
│    → 15 candidatos                      │
│    → Ver panorama completo              │
└────────────┬────────────────────────────┘
             ↓
┌─────────────────────────────────────────┐
│ 2. ANALIZAR convergencia                │
│    → ¿Cuántos genes compartidos?        │
│    → ¿Hay módulos?                      │
└────────────┬────────────────────────────┘
             ↓
┌─────────────────────────────────────────┐
│ 3. REFINAR (moderate o custom)          │
│    → Filtrar a los más robustos         │
│    → Análisis profundo                  │
└────────────┬────────────────────────────┘
             ↓
┌─────────────────────────────────────────┐
│ 4. PUBLICAR (strict)                    │
│    → Solo el mejor candidato            │
│    → Máxima confianza                   │
└─────────────────────────────────────────┘
```

---

## 📊 OUTPUTS GENERADOS

### **Para cada preset se genera:**

```
results_threshold_<preset>/
├── ALS_candidates.csv          ← Candidatos seleccionados
├── COMPARACION_PRESETS.png     ← Figura comparativa
└── (luego del Paso 3)
    ├── targets/                ← Targets de esos candidatos
    ├── pathways/               ← Pathways enriquecidos
    ├── network/                ← Network analysis
    └── figures/                ← Figuras del Paso 3
```

---

## 🎯 EJEMPLO COMPLETO: PERMISSIVE → MODERATE

### **Fase 1: Exploración (Permissive)**

```bash
# Seleccionar 15 candidatos
Rscript RUN_WITH_THRESHOLDS.R permissive

# Ejecutar Paso 3
cd pipeline_3/
cp ../results_threshold_permissive/ALS_candidates.csv data/
Rscript RUN_PASO3_COMPLETE.R

# Revisar HTML
open PASO_3_ANALISIS_FUNCIONAL.html
```

**Preguntas a responder:**
- ¿Cuántos genes compartidos entre los 15?
- ¿Hay clusters de miRNAs (sub-módulos)?
- ¿Todos convergen en oxidación o hay otros procesos?

---

### **Fase 2: Refinamiento (Moderate)**

```bash
# Si viste convergencia en 8-10 miRNAs, ajusta umbrales
# Editar CONFIG_THRESHOLDS.json para un custom intermedio

# O usa moderate para los top 3
cd ..
Rscript RUN_WITH_THRESHOLDS.R moderate

# Re-ejecutar Paso 3 con los 3 más robustos
cd pipeline_3/
cp ../results_threshold_moderate/ALS_candidates.csv data/
Rscript RUN_PASO3_COMPLETE.R
```

---

## 🔧 VENTAJAS DEL SISTEMA AJUSTABLE

### **Flexibilidad:**
- ✅ Cambias umbrales en 1 archivo
- ✅ Re-ejecutas en segundos
- ✅ Comparas múltiples escenarios

### **Reproducibilidad:**
- ✅ Todo documentado en JSON
- ✅ Fácil de compartir configuración
- ✅ Puedes volver a configuraciones previas

### **Exploración:**
- ✅ Prueba diferentes hipótesis
- ✅ Análisis de sensibilidad
- ✅ Identifica candidatos robustos vs borderline

---

## 📖 ARCHIVOS CLAVE

### **Configuración:**
- `CONFIG_THRESHOLDS.json` ← Umbrales ajustables
- `RUN_WITH_THRESHOLDS.R` ← Script maestro

### **Documentación:**
- `GUIA_PIPELINE_AJUSTABLE.md` ← Este documento
- `LOGICA_COMPLETA_PIPELINE.md` ← Flujo general
- `DE_DONDE_VIENEN_LOS_CANDIDATOS.md` ← Explicación

### **Datos originales:**
- `pipeline_2/VOLCANO_PLOT_DATA_PER_SAMPLE.csv` ← 301 miRNAs testeados

---

## 🚀 PRÓXIMO PASO SUGERIDO

**Te recomiendo:**

```bash
# 1. Ejecutar con permissive para explorar
Rscript RUN_WITH_THRESHOLDS.R permissive

# 2. Ver los 15 candidatos
cat results_threshold_permissive/ALS_candidates.csv

# 3. Decidir:
#    - ¿Los 15 parecen interesantes? → Ejecutar Paso 3 con ellos
#    - ¿Prefieres los 3 robustos? → Quedarte con moderate
#    - ¿Quieres un punto intermedio? → Custom con FC 1.35x, p 0.08
```

---

## ✅ RESUMEN

**ANTES:**
- Pipeline rígido
- 3 candidatos fijos
- No ajustable

**AHORA:**
- ✅ 4 presets + custom
- ✅ 1 a 48 candidatos según necesites
- ✅ Completamente documentado
- ✅ Re-ejecutable en segundos
- ✅ Ideal para exploración y publicación

---

**Documentado:** 2025-10-17 04:00  
**Sistema:** Completamente ajustable  
**Presets:** 4 (strict, moderate, permissive, exploratory)  
**Recomendación:** Empezar con permissive (15 candidatos)

