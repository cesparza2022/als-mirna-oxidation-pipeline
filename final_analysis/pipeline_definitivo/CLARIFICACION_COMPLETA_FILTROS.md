# 🔬 CLARIFICACIÓN COMPLETA: ¿QUÉ ESTAMOS FILTRANDO Y CÓMO?

**Fecha:** 2025-10-17 04:35
**Propósito:** Entender EXACTAMENTE qué hacemos y hacerlo adaptativo

---

## 🎯 TU PREGUNTA CLAVE

> "¿Cómo lo podemos hacer ajustable pero REAL, que funcione solo si el dataset tiene información valiosa o significativa y no si no?"

**Mi respuesta:** Sistema de filtrado **adaptativo** basado en la distribución de los datos, NO umbrales fijos arbitrarios.

---

## 📊 ¿QUÉ ESTAMOS FILTRANDO ACTUALMENTE?

### **NIVEL 1: POR miRNA (NO por SNV individual)**

**Actualmente calculamos TODO a nivel de miRNA completo:**

```R
# Para cada miRNA:
# 1. Sumar TODOS sus SNVs G>T en seed por muestra
mirna_vaf_per_sample <- data %>%
  filter(miRNA == "miR-X", str_detect(pos.mut, "^[2-8]:GT$")) %>%
  pivot_longer(cols = samples) %>%
  group_by(Sample_ID) %>%
  summarise(Total_VAF = sum(VAF))  # ← SUMA de TODOS los SNVs

# 2. Calcular promedios por grupo
Mean_ALS <- mean(mirna_vaf_per_sample[ALS])     # ej: 0.0162
Mean_Control <- mean(mirna_vaf_per_sample[Control])  # ej: 0.0047

# 3. Comparar grupos
FC = Mean_ALS / Mean_Control  # ej: 3.44x
p = wilcox.test(ALS, Control)  # ej: 0.0022
```

**IMPORTANTE:** 
- ✅ Comparamos miRNAs completos
- ❌ NO comparamos SNVs individuales
- ✅ Suma de G>T por miRNA
- ❌ NO separamos por posición (2 vs 3 vs 4, etc.)

---

## 🚨 PROBLEMA QUE DETECTASTE

### **No estamos analizando a nivel de SECUENCIA/POSICIÓN**

**Ejemplo actual:**
```
miR-196a-5p tiene:
  - 1 SNV en posición 3 (3:GT)
  - VAF alto
  - p significativo
  
→ Lo incluimos

PERO NO sabemos:
  - ¿Hay otros miRNAs con SNV en posición 3?
  - ¿Es la posición 3 especialmente vulnerable?
  - ¿Hay secuencia conservada alrededor?
  - ¿Contexto trinucleótido (GGT, CGT, etc.)?
```

**Tu sugerencia:**
> "podría ser un patrón a otro nivel, a nivel secuencia de la región afectada"

**EXACTO.** Deberíamos también buscar:
1. **Patrones posicionales:** ¿Posición 2-3 más afectada?
2. **Motivos de secuencia:** ¿GG context más oxidado?
3. **Clustering por similitud:** ¿miRNAs con seeds parecidos?

---

## 💡 PROPUESTA: SISTEMA DE FILTRADO ADAPTATIVO

### **PASO A: ANÁLISIS EXPLORATORIO AUTOMÁTICO**

Antes de aplicar filtros, el pipeline **analiza la distribución de los datos**:

```R
# 1. Calcular percentiles de FC y p-value
fc_percentiles <- quantile(volcano$log2FC, probs = c(0.75, 0.90, 0.95))
p_percentiles <- quantile(volcano$padj, probs = c(0.05, 0.10, 0.25))

# Ejemplo resultado:
#   FC 75th: 0.45 (FC 1.36x)
#   FC 90th: 0.85 (FC 1.80x)
#   FC 95th: 1.20 (FC 2.30x)
#
#   p 5th: 0.002
#   p 10th: 0.008
#   p 25th: 0.045

# 2. Evaluar calidad del dataset
signal_quality <- list(
  has_strong_candidates = sum(volcano$log2FC > 1.0 & volcano$padj < 0.01) > 0,
  has_moderate_candidates = sum(volcano$log2FC > 0.58 & volcano$padj < 0.05) >= 3,
  median_fc = median(volcano$log2FC),
  median_p = median(volcano$padj)
)

# 3. DECIDIR UMBRALES BASADO EN DATOS
if (signal_quality$has_strong_candidates) {
  # Dataset ROBUSTO → Ser estricto
  threshold_fc <- fc_percentiles["95%"]  # Top 5%
  threshold_p <- 0.01
  cat("✅ Dataset robusto → Umbrales estrictos\n")
  
} else if (signal_quality$has_moderate_candidates) {
  # Dataset MODERADO → Balance
  threshold_fc <- fc_percentiles["90%"]  # Top 10%
  threshold_p <- 0.05
  cat("⚠️ Dataset moderado → Umbrales balanceados\n")
  
} else {
  # Dataset DÉBIL → Ser permisivo o ADVERTIR
  threshold_fc <- fc_percentiles["75%"]  # Top 25%
  threshold_p <- 0.10
  cat("⚠️ Dataset débil → Umbrales permisivos\n")
  cat("   Considerar si hay señal real\n")
}
```

**Ventajas:**
- ✅ Se adapta automáticamente a cada dataset
- ✅ No usa umbrales arbitrarios
- ✅ Basado en distribución real de los datos
- ✅ Advierte si el dataset es débil

---

### **PASO B: FILTRADO MULTI-NIVEL**

**No solo 1 filtro, sino CASCADA de filtros con diferentes niveles:**

```
┌─────────────────────────────────────────────────────────┐
│ PASO 1: Todos los 301 con G>T en seed                  │
│         → Sin filtros                                   │
│         → BASELINE                                      │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ NIVEL 1: Filtro estadístico ADAPTATIVO                 │
│                                                         │
│ IF dataset robusto:                                     │
│   FC > 95th percentile AND p < 0.01                    │
│                                                         │
│ IF dataset moderado:                                    │
│   FC > 90th percentile AND p < 0.05                    │
│                                                         │
│ IF dataset débil:                                       │
│   FC > 75th percentile OR p < 0.10                     │
│                                                         │
│ → CANDIDATOS ESTADÍSTICOS: ~5-20 miRNAs                │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ NIVEL 2: Filtro de CALIDAD (anti-artefactos)           │
│                                                         │
│ Aplicar SIEMPRE:                                        │
│   • Presente en ≥ 10% de muestras ALS                  │
│   • Mean VAF > 0.0005 (0.05%)                          │
│   • Coef. Variación < 5 (no ultra-variable)            │
│                                                         │
│ → CANDIDATOS LIMPIOS: ~3-15 miRNAs                     │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ NIVEL 3: Análisis de PATRONES (Paso 2.5)               │
│                                                         │
│ Buscar:                                                 │
│   • ¿Se agrupan por posición? (pos 2-3 vs 5-6)        │
│   • ¿Comparten familias? (let-7, miR-9)               │
│   • ¿Clustering de muestras?                           │
│   • ¿Motivos de secuencia conservados?                │
│                                                         │
│ → VALIDACIÓN DE PATRONES                               │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ NIVEL 4: Análisis FUNCIONAL (Paso 3)                   │
│                                                         │
│ Solo si pasan los 3 niveles anteriores:                │
│   • Targets (genes)                                    │
│   • Pathways (GO, KEGG)                                │
│   • Networks                                           │
│                                                         │
│ → CANDIDATOS FINALES: ~3-5 miRNAs ultra-robustos       │
└─────────────────────────────────────────────────────────┘
```

---

## 🔍 TU PREGUNTA ESPECÍFICA: ¿QUÉ ES EL VOLCANO PLOT?

### **Volcano Plot ACTUAL:**

**Unidad de análisis:** miRNA completo (NO SNV individual)

**Cada punto en el Volcano Plot es:**
```
1 punto = 1 miRNA

Coordenadas:
  X (log2FC) = log2(Mean_ALS / Mean_Control)
  Y (-log10p) = -log10(p-value)

Donde:
  Mean_ALS = Promedio de VAF del miRNA en las 313 muestras ALS
  Mean_Control = Promedio de VAF del miRNA en las 102 muestras Control
  
  VAF del miRNA = SUMA de VAF de TODOS sus SNVs G>T en seed
```

**Ejemplo concreto:**
```
miR-196a-5p:
  
PASO 1: Identificar SNVs G>T en seed
  → Tiene 1 SNV: posición 3:GT

PASO 2: Calcular VAF por muestra
  Sample 1 (ALS): VAF = 0.02
  Sample 2 (ALS): VAF = 0.03
  ...
  Sample 313 (ALS): VAF = 0.01
  
  Sample 314 (Control): VAF = 0.005
  ...
  Sample 415 (Control): VAF = 0.003

PASO 3: Promediar
  Mean_ALS = 0.0162
  Mean_Control = 0.0047
  
PASO 4: Calcular FC y p
  FC = 0.0162 / 0.0047 = 3.44x
  log2FC = 1.78
  
  p-value = wilcox.test(ALS_vals, Control_vals) = 0.0022
  
PASO 5: Plotear
  Punto en Volcano: X=1.78, Y=-log10(0.0022)=2.66
```

**CRÍTICO:** Si un miRNA tiene **múltiples SNVs** en seed, los **sumamos todos**.

---

## 🚨 LO QUE NO ESTAMOS HACIENDO (TU PREOCUPACIÓN)

### **Análisis a nivel de SNV individual:**

**Actualmente NO hacemos:**
```
miR-X tiene 3 SNVs en seed:
  - SNV1: posición 2:GT
  - SNV2: posición 3:GT
  - SNV3: posición 7:GT

Pregunta: ¿Estos 3 SNVs tienen DIFERENTE comportamiento?
  - ¿SNV en pos 2 más frecuente que pos 7?
  - ¿SNV en pos 3 más intenso?
  - ¿Solo pos 2-3 son significativos?
  
ACTUALMENTE: Los sumamos todos y comparamos el TOTAL
```

### **Análisis a nivel de POSICIÓN:**

**Actualmente NO hacemos:**
```
Posición 2 del seed:
  - 50 miRNAs tienen G>T en posición 2
  - ¿Estos 50 tienen algo en común?
  - ¿Secuencia conservada alrededor?
  - ¿Contexto GG, CG, AG?
  
ACTUALMENTE: No agrupamos por posición para el filtro
```

### **Análisis de MOTIVOS DE SECUENCIA:**

**Actualmente NO hacemos:**
```
miRNAs con G>T en seed tienen secuencias:
  - miR-A: ...CGGT... (posición 3)
  - miR-B: ...AGGT... (posición 3)
  - miR-C: ...GGGT... (posición 3)
  
Pregunta: ¿El contexto GG (GpG) es más oxidable?
  
ACTUALMENTE: No analizamos contexto de secuencia
```

---

## 💡 PROPUESTA: SISTEMA ADAPTATIVO MULTI-NIVEL

### **ENFOQUE 1: Volcano Plot Actual + Filtros de Calidad Adaptativos**

```R
# ═══════════════════════════════════════════════════════════
# PASO 1: ANÁLISIS EXPLORATORIO (Identifica si hay señal)
# ═══════════════════════════════════════════════════════════

assess_dataset_quality <- function(volcano_data) {
  
  # 1. Distribución de FC
  fc_dist <- summary(volcano_data$log2FC)
  fc_95 <- quantile(volcano_data$log2FC, 0.95, na.rm=TRUE)
  fc_90 <- quantile(volcano_data$log2FC, 0.90, na.rm=TRUE)
  
  # 2. Distribución de p-values
  p_dist <- summary(volcano_data$padj)
  p_10 <- quantile(volcano_data$padj, 0.10, na.rm=TRUE)
  
  # 3. Contar candidatos potenciales
  n_strong <- sum(volcano_data$log2FC > 1.0 & volcano_data$padj < 0.01)
  n_moderate <- sum(volcano_data$log2FC > 0.58 & volcano_data$padj < 0.05)
  n_weak <- sum(volcano_data$log2FC > 0.32 & volcano_data$padj < 0.10)
  
  # 4. DECISIÓN AUTOMÁTICA
  if (n_strong >= 1) {
    quality <- "EXCELLENT"
    strategy <- "strict"
    fc_threshold <- 1.0
    p_threshold <- 0.01
    message <- "Dataset has strong signal → Use strict thresholds"
    
  } else if (n_moderate >= 3) {
    quality <- "GOOD"
    strategy <- "moderate"
    fc_threshold <- 0.58
    p_threshold <- 0.05
    message <- "Dataset has moderate signal → Balanced thresholds"
    
  } else if (n_weak >= 5) {
    quality <- "FAIR"
    strategy <- "permissive"
    fc_threshold <- 0.32
    p_threshold <- 0.10
    message <- "Dataset has weak signal → Permissive thresholds"
    
  } else {
    quality <- "POOR"
    strategy <- "exploratory"
    fc_threshold <- fc_90  # Usar percentiles del dataset
    p_threshold <- 0.20
    message <- "⚠️ Dataset has very weak signal → Consider if real"
  }
  
  return(list(
    quality = quality,
    strategy = strategy,
    fc_threshold = fc_threshold,
    p_threshold = p_threshold,
    n_candidates_expected = switch(quality,
      "EXCELLENT" = n_strong,
      "GOOD" = n_moderate,
      "FAIR" = n_weak,
      "POOR" = sum(volcano_data$log2FC > fc_threshold & volcano_data$padj < p_threshold)
    ),
    message = message
  ))
}
```

**Ventajas:**
- ✅ Se adapta automáticamente
- ✅ Advierte si no hay señal real
- ✅ No usa umbrales fijos
- ✅ Basado en distribución de TU dataset

---

### **ENFOQUE 2: Análisis de PATRONES POSICIONALES**

**NUEVO - Lo que falta:**

```R
# ═══════════════════════════════════════════════════════════
# ANÁLISIS POSICIONAL: ¿Hay posiciones específicas afectadas?
# ═══════════════════════════════════════════════════════════

analyze_positional_patterns <- function(data) {
  
  # 1. Agrupar SNVs por POSICIÓN (no por miRNA)
  pos_analysis <- data %>%
    filter(str_detect(pos.mut, "^[2-8]:GT$")) %>%
    mutate(Position = as.integer(str_extract(pos.mut, "^\\d+"))) %>%
    pivot_longer(cols = samples, names_to = "Sample_ID", values_to = "VAF") %>%
    left_join(metadata) %>%
    group_by(Position, Group) %>%
    summarise(
      N_SNVs = n(),
      N_miRNAs = n_distinct(miRNA_name),
      Mean_VAF = mean(VAF, na.rm=TRUE),
      Total_VAF = sum(VAF, na.rm=TRUE)
    )
  
  # 2. Test por posición
  position_tests <- map_df(2:8, function(pos) {
    pos_data <- data %>% 
      filter(str_detect(pos.mut, paste0("^", pos, ":GT$")))
    
    # Test ALS vs Control en esta posición
    als <- get_vaf_by_group(pos_data, "ALS")
    ctrl <- get_vaf_by_group(pos_data, "Control")
    
    test <- wilcox.test(als, ctrl)
    
    data.frame(
      Position = pos,
      N_miRNAs = length(unique(pos_data$miRNA_name)),
      FC = mean(als) / mean(ctrl),
      p_value = test$p.value
    )
  })
  
  # 3. ¿Hay posiciones específicas enriquecidas?
  enriched_positions <- position_tests %>%
    filter(p_value < 0.05, FC > 1.2)
  
  if (nrow(enriched_positions) > 0) {
    cat("🔥 HALLAZGO: Posiciones específicas afectadas:\n")
    print(enriched_positions)
    cat("\n→ Hay patrón posicional REAL\n")
    return(enriched_positions$Position)
  } else {
    cat("⚠️ No hay patrón posicional claro\n")
    return(NULL)
  }
}
```

**Esto responde:**
- ¿Es la oxidación específica de posición? (ej: solo pos 2-3)
- ¿O distribuida por toda la seed?
- **Si hay posiciones específicas → enfocarse en miRNAs con SNVs ahí**

---

### **ENFOQUE 3: Análisis de CONTEXTO DE SECUENCIA**

**NUEVO - Análisis de motivos:**

```R
# ═══════════════════════════════════════════════════════════
# ANÁLISIS DE SECUENCIA: ¿Hay contexto específico (GpG, CpG)?
# ═══════════════════════════════════════════════════════════

# NOTA: Esto REQUIERE secuencias de miRBase
# Por ahora, usamos proxy basado en datos

analyze_sequence_context <- function(candidates) {
  
  # Para cada candidato, extraer seed sequence de miRBase
  # (esto es un script separado que descarga de miRBase)
  
  # 1. Obtener secuencias
  seeds <- get_seed_sequences(candidates$miRNA)  # ej: "AGGAGCU"
  
  # 2. Extraer contexto trinucleótido
  trinuc_context <- map_df(1:nrow(candidates), function(i) {
    mirna <- candidates$miRNA[i]
    seed <- seeds[[mirna]]
    snv_pos <- candidates$Position[i]
    
    # Contexto XGY
    if (snv_pos > 1 && snv_pos < 7) {
      context <- substr(seed, snv_pos-1, snv_pos+1)
      x <- substr(context, 1, 1)
      g <- "G"
      y <- substr(context, 3, 3)
      
      trinuc <- paste0(x, "G", y)
      
      return(data.frame(
        miRNA = mirna,
        Position = snv_pos,
        Trinucleotide = trinuc,
        Is_GpG = (x == "G"),
        Is_CpG = (x == "C")
      ))
    }
  })
  
  # 3. Test de enriquecimiento
  pct_GpG <- mean(trinuc_context$Is_GpG)
  pct_CpG <- mean(trinuc_context$Is_CpG)
  
  expected_GpG <- 0.25  # Si fuera aleatorio
  
  if (pct_GpG > expected_GpG * 1.5) {
    cat("🔥 HALLAZGO: Enriquecimiento de GpG context\n")
    cat(sprintf("   Observado: %.1f%% vs Esperado: %.1f%%\n", 
                pct_GpG*100, expected_GpG*100))
    cat("   → Confirma susceptibilidad a oxidación en GG\n")
  }
  
  return(trinuc_context)
}
```

**Esto responde:**
- ¿Los G oxidados están en contexto GG (más susceptible)?
- ¿O en CG (islas CpG)?
- **Si hay contexto específico → mecanismo molecular claro**

---

## 🎯 SISTEMA COMPLETO PROPUESTO

### **Flujo de Filtrado Adaptativo:**

```
ENTRADA: Dataset con 301 miRNAs con G>T en seed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ETAPA 1: EVALUACIÓN AUTOMÁTICA
├─ Analizar distribución de FC y p-value
├─ Calcular percentiles
├─ Contar candidatos potenciales por tier
└─ DECIDIR: ¿Dataset EXCELLENT, GOOD, FAIR, o POOR?

ETAPA 2: FILTRO ESTADÍSTICO ADAPTATIVO
├─ IF EXCELLENT: FC > 2.0x AND p < 0.01 → ~1-2 miRNAs
├─ IF GOOD: FC > 1.5x AND p < 0.05 → ~3-5 miRNAs
├─ IF FAIR: FC > 1.25x AND p < 0.10 → ~10-15 miRNAs
└─ IF POOR: ADVERTIR + usar percentiles → ~5-10 miRNAs

ETAPA 3: FILTROS DE CALIDAD (SIEMPRE)
├─ Frecuencia: ≥ 10% muestras ALS con VAF > 0
├─ VAF mínimo: Mean VAF > 0.0005
├─ Variabilidad: CV < 5.0
└─ RESULTADO: Candidatos limpios (sin artefactos)

ETAPA 4: ANÁLISIS DE PATRONES (Paso 2.5)
├─ ¿Se agrupan por POSICIÓN? → Posiciones 2-3 vs 4-8
├─ ¿Se agrupan por FAMILIA? → let-7, miR-9, etc.
├─ ¿Separan muestras? → Clustering, PCA
└─ ¿Contexto de secuencia? → GpG, CpG enrichment

ETAPA 5: DECISIÓN FINAL
├─ IF hay patrón posicional → Enfocarse en esas posiciones
├─ IF hay familia enriquecida → Priorizar esa familia
├─ IF clustering separa ALS → Buenos biomarcadores
└─ RESULTADO: Candidatos validados para Paso 3

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SALIDA: 3-15 candidatos robustos y validados
```

---

## 🔬 ANÁLISIS ADICIONAL NECESARIO

### **1. Análisis Posicional Detallado**

**Script nuevo:** `ANALYZE_POSITIONAL_ENRICHMENT.R`

```R
# Para cada posición de la seed (2-8):
# ¿Hay enriquecimiento de G>T en ALS vs Control?

for (pos in 2:8) {
  
  # Todos los miRNAs con SNV en esta posición
  mirnas_pos <- data %>%
    filter(str_detect(pos.mut, paste0("^", pos, ":GT$")))
  
  # Comparar ALS vs Control
  test <- compare_groups(mirnas_pos)
  
  if (test$p < 0.05) {
    cat(sprintf("✅ Posición %d: %d miRNAs, FC %.2fx, p %.4f\n",
                pos, length(unique(mirnas_pos$miRNA_name)), 
                test$FC, test$p))
  }
}

# Resultado:
# ✅ Posición 2: 45 miRNAs, FC 1.8x, p 0.003
# ✅ Posición 3: 52 miRNAs, FC 2.1x, p 0.0001
# ⚠️ Posición 7: 20 miRNAs, FC 1.1x, p 0.34 (NS)
```

**Interpretación:**
- Si posiciones 2-3 son significativas → **Enfocarse en miRNAs con G>T en pos 2-3**
- Si todas las posiciones son NS → No hay patrón posicional

---

### **2. Clustering por Similitud de Secuencia**

**Script nuevo:** `CLUSTER_BY_SEED_SIMILARITY.R`

```R
# Agrupar candidatos por:
# 1. Similitud de secuencia seed
# 2. Posiciones afectadas
# 3. Contexto trinucleótido

# ¿Forman clusters coherentes?
# Cluster 1: GG context, posición 2-3, familia let-7
# Cluster 2: CG context, posición 5-6, familia miR-30
# Cluster 3: Random (no patrón)

# Si hay clusters → Validación de mecanismo
# Si no hay clusters → Eventos independientes
```

---

### **3. Volcano Plot a NIVEL DE SNV (Alternativo)**

**Para complementar el actual:**

```R
# ═══════════════════════════════════════════════════════════
# VOLCANO PLOT: 1 punto = 1 SNV (no 1 miRNA)
# ═══════════════════════════════════════════════════════════

snv_volcano <- data %>%
  filter(str_detect(pos.mut, "^[2-8]:GT$")) %>%
  mutate(SNV_ID = paste0(miRNA_name, "_", pos.mut)) %>%
  pivot_longer(cols = samples) %>%
  left_join(metadata) %>%
  group_by(SNV_ID, Group) %>%
  summarise(Mean_VAF = mean(VAF, na.rm=TRUE)) %>%
  pivot_wider(names_from = Group, values_from = Mean_VAF) %>%
  mutate(
    log2FC = log2(ALS / Control),
    p_value = map_dbl(SNV_ID, ~ wilcox_test_snv(.))
  )

# Plot: Cada PUNTO es un SNV
# Color por posición
# Shape por familia miRNA
# Tamaño por número de muestras

# Permite ver:
# - ¿SNVs en pos 2-3 se agrupan arriba? (más significativos)
# - ¿SNVs de let-7 family se agrupan?
# - ¿Hay outliers (SNVs individuales muy fuertes)?
```

---

## 🎯 TU CASO ESPECÍFICO

### **Para TU dataset actual:**

**Evaluación:**
```
✅ GOOD quality dataset
   - 3 candidatos con FC > 1.5x AND p < 0.05
   - 15 candidatos con FC > 1.25x AND p < 0.10
   - No hay candidatos con FC > 2.0x AND p < 0.01
```

**Recomendación:**
```
USAR: MODERATE como base (3 candidatos robustos)

PERO también investigar:
  1. ¿Posiciones 2-3 enriquecidas? (análisis posicional)
  2. ¿Familias específicas? (let-7, miR-9) ✅ Ya hecho
  3. ¿Contexto GpG? (análisis de secuencia) - PENDIENTE
  4. ¿miR-9-3p (FC 7x, p 0.099) es real? (análisis de distribución)
```

---

## 📋 PLAN DE ACCIÓN

### **OPCIÓN A: IMPLEMENTAR SISTEMA ADAPTATIVO COMPLETO**

**Scripts a crear:**
1. `01_ASSESS_DATASET_QUALITY.R` - Evalúa calidad automáticamente
2. `02_ADAPTIVE_FILTERING.R` - Aplica umbrales adaptativos
3. `03_POSITIONAL_ENRICHMENT.R` - Análisis por posición
4. `04_SEQUENCE_CONTEXT.R` - Análisis GpG, CpG
5. `05_SNV_LEVEL_VOLCANO.R` - Volcano de SNVs individuales

**Tiempo:** ~1.5 horas de implementación

**Resultado:** Pipeline adaptativo que funciona con cualquier dataset

---

### **OPCIÓN B: MEJORAR FILTROS ACTUALES (MÁS RÁPIDO)**

**Añadir solo:**
1. Filtro de frecuencia (≥ 10% muestras)
2. Filtro de VAF mínimo (> 0.0005)
3. Análisis posicional (¿pos 2-3 enriquecidas?)
4. Análisis de miR-9-3p (¿outlier o real?)

**Tiempo:** ~30 minutos

**Resultado:** Mejora del sistema actual

---

## ❓ PREGUNTAS PARA TI

### **1. NIVEL DE ANÁLISIS:**

¿Quieres quedarte con análisis a nivel de miRNA (actual)?
- ✅ **SÍ** - Más simple, más robusto, suficiente para publicación
- ❌ **NO** - Añadir análisis a nivel SNV y posición

### **2. SISTEMA ADAPTATIVO:**

¿Implementar sistema que decide umbrales automáticamente?
- ✅ **SÍ** - Pipeline genérico, funciona con cualquier dataset
- ❌ **NO** - Mantener umbrales fijos pero razonables

### **3. ANÁLISIS POSICIONAL:**

¿Quieres analizar si hay posiciones específicas (2-3 vs 4-8) enriquecidas?
- ✅ **SÍ** - Puede revelar mecanismo específico
- ❌ **NO** - Asumimos que cualquier posición es relevante

### **4. CONTEXTO DE SECUENCIA:**

¿Analizar contexto trinucleótido (GpG, CpG)?
- ✅ **SÍ** - Confirma mecanismo oxidativo (GpG más susceptible)
- ❌ **NO** - No es crítico para primera publicación

### **5. CASO miR-9-3p:**

miR-9-3p: FC 7.05x, p 0.0993 (casi 0.10)
- ✅ **INCLUIR** - FC 7x es demasiado alto para ignorar
- ❌ **EXCLUIR** - p-value no cumple umbral
- 🔍 **INVESTIGAR** - Ver distribución y frecuencia primero

---

## 💬 MI RECOMENDACIÓN

**Para TU caso (pipeline genérico):**

### **Implementar OPCIÓN B (mejoras rápidas) + OPCIÓN A (parcial):**

1. **Ahora (30 min):**
   - Añadir filtros de calidad (frecuencia, VAF mínimo)
   - Análisis posicional básico
   - Investigar miR-9-3p

2. **Después (si interesa):**
   - Sistema adaptativo completo
   - Análisis de secuencia (GpG, CpG)
   - Volcano a nivel SNV

**Resultado:**
- Pipeline robusto para TU dataset actual
- Extensible para futuros análisis
- No sobre-ingenierizado

---

## 🚀 SIGUIENTE PASO

**¿Qué prefieres hacer AHORA?**

**A)** Implementar filtros de calidad + análisis posicional (~30 min)
**B)** Crear sistema adaptativo completo (~1.5 hr)
**C)** Investigar solo miR-9-3p (¿incluir o no?) (~10 min)
**D)** Discutir más - revisar ejemplos específicos primero

**Dime qué prefieres y empezamos.** 🔬

