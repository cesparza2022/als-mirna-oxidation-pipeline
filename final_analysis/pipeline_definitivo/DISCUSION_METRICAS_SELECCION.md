# 🔬 DISCUSIÓN: MÉTRICAS Y FILTROS PARA SELECCIÓN DE CANDIDATOS

**Fecha:** 2025-10-17 04:30
**Versión:** 1.0.0 - Para Discusión

---

## 🎯 OBJETIVO DE ESTA DISCUSIÓN

Definir **EXACTAMENTE**:
1. ¿Qué métricas usamos para seleccionar candidatos?
2. ¿Qué umbrales aplicamos y por qué?
3. ¿Son los correctos para nuestra pregunta biológica?
4. ¿Podemos mejorarlos o cambiarlos?

---

## 📊 MÉTRICAS ACTUALES (PASO 2 - VOLCANO PLOT)

### **Métrica 1: Fold Change (FC)**

**¿Qué mide?**
```
FC = Mean(VAF_ALS) / Mean(VAF_Control)

Ejemplo:
  miR-196a-5p:
    Mean ALS = 0.0162
    Mean Control = 0.0047
    FC = 0.0162 / 0.0047 = 3.44x
    log2(FC) = 1.78
```

**Umbral actual:**
- **MODERATE:** FC > 1.5x (log2FC > 0.58)
- **PERMISSIVE:** FC > 1.25x (log2FC > 0.32)

**❓ PREGUNTAS PARA DISCUTIR:**
1. ¿Es 1.5x suficiente o muy estricto?
2. ¿1.25x (permissive) es biológicamente relevante?
3. ¿Deberíamos considerar también FC absoluto (diferencia)?

**Alternativas:**
- **Opción A:** FC relativo (actual) → 1.5x, 1.25x
- **Opción B:** Diferencia absoluta → ΔVA F > 0.01
- **Opción C:** Combinación → FC > 1.3x **Y** ΔVAF > 0.005

---

### **Métrica 2: p-value (Significancia Estadística)**

**¿Qué mide?**
```
Wilcoxon rank-sum test:
  H0: VAF_ALS = VAF_Control
  H1: VAF_ALS ≠ VAF_Control

Luego: FDR correction (Benjamini-Hochberg)
  → padj (p-value ajustado por comparaciones múltiples)
```

**Umbral actual:**
- **MODERATE:** padj < 0.05 (5% FDR)
- **PERMISSIVE:** padj < 0.10 (10% FDR)

**❓ PREGUNTAS PARA DISCUTIR:**
1. ¿FDR 5% es muy estricto para dataset exploratorio?
2. ¿10% es aceptable o muy permisivo?
3. ¿Deberíamos usar p-value sin corrección para exploración?
4. ¿Wilcoxon es el test correcto (no-paramétrico)?

**Alternativas:**
- **Opción A:** FDR < 0.05 (actual moderate)
- **Opción B:** FDR < 0.10 (actual permissive)
- **Opción C:** p-value raw < 0.01 (sin FDR)
- **Opción D:** Permutation test (más robusto)

---

### **Métrica 3: Método de Cálculo del VAF**

**Método actual: "Average VAF per Sample"**

```R
# Para cada miRNA:
# 1. Sumar VAF de TODOS sus SNVs G>T por muestra
mirna_vaf_per_sample <- data %>%
  filter(miRNA == "miR-X") %>%
  group_by(Sample_ID) %>%
  summarise(Total_VAF = sum(VAF))

# 2. Comparar distribuciones ALS vs Control
als_vals <- mirna_vaf_per_sample %>% filter(Group == "ALS")
ctrl_vals <- mirna_vaf_per_sample %>% filter(Group == "Control")

# 3. Test
wilcox.test(als_vals, ctrl_vals)
```

**❓ PREGUNTAS PARA DISCUTIR:**
1. ¿Sumar VAF de todos los SNVs es correcto?
2. ¿O deberíamos usar VAF promedio?
3. ¿O VAF máximo por muestra?
4. ¿O número de SNVs (presencia/ausencia)?

**Alternativas:**
- **Opción A:** Sum(VAF) por muestra (actual) ← Carga total
- **Opción B:** Mean(VAF) por muestra ← Intensidad promedio
- **Opción C:** Max(VAF) por muestra ← SNV más fuerte
- **Opción D:** Count(SNVs > threshold) ← Presencia/ausencia

---

## 🔍 FILTROS ADICIONALES POTENCIALES

### **Filtro 4: Número de Muestras Afectadas**

**¿Qué mide?**
```
¿En cuántas muestras ALS aparece el miRNA con G>T?

Ejemplo:
  miR-196a-5p: 
    Presente en 150/313 muestras ALS (48%)
    Presente en 20/102 muestras Control (20%)
```

**Umbral potencial:**
- **Al menos 20% de muestras ALS** con VAF > 0

**❓ PREGUNTAS:**
1. ¿Deberíamos filtrar miRNAs que solo aparecen en pocas muestras?
2. ¿Qué % mínimo es aceptable? (10%, 20%, 50%?)
3. ¿O incluir cualquier miRNA sin importar frecuencia?

**Pros de aplicar:**
- ✅ Asegura que el hallazgo no sea de 1-2 muestras outlier
- ✅ Más robusto y reproducible

**Contras:**
- ❌ Puede eliminar candidatos raros pero reales
- ❌ Sesgo hacia miRNAs abundantes

---

### **Filtro 5: VAF Absoluto Mínimo**

**¿Qué mide?**
```
¿El VAF promedio es suficientemente alto para ser biológicamente relevante?

Ejemplo:
  miR-X:
    Mean ALS VAF = 0.0001 (0.01%)
    → Muy bajo, aunque sea significativo
```

**Umbral potencial:**
- **Mean VAF > 0.001** (0.1% mínimo)
- **Mean VAF > 0.005** (0.5% mínimo)

**❓ PREGUNTAS:**
1. ¿Hay un VAF mínimo "detectable" o "relevante"?
2. ¿0.1% es suficiente o demasiado bajo?
3. ¿Depende del método de secuenciación?

**Pros de aplicar:**
- ✅ Elimina hits de ruido técnico
- ✅ Enfoca en señal fuerte

**Contras:**
- ❌ Puede eliminar eventos raros pero reales
- ❌ Sesgo hacia alta abundancia

---

### **Filtro 6: Consistencia entre SNVs**

**¿Qué mide?**
```
Si un miRNA tiene múltiples SNVs G>T en seed:
  ¿Todos van en la misma dirección (ALS > Control)?
  ¿O algunos son ALS y otros Control?
```

**Umbral potencial:**
- **Al menos 70% de SNVs** con FC en la misma dirección

**❓ PREGUNTAS:**
1. ¿Importa que todos los SNVs del miRNA vayan en la misma dirección?
2. ¿O el promedio es suficiente?

---

### **Filtro 7: Número de SNVs en Seed**

**¿Qué mide?**
```
¿Cuántos SNVs G>T tiene el miRNA en la seed?

Ejemplo:
  miR-196a-5p: 1 SNV en seed
  miR-3195: 2 SNVs en seed
```

**Umbral potencial:**
- **Al menos 1 SNV** (actual - incluye todos)
- **Al menos 2 SNVs** (más robusto)

**❓ PREGUNTAS:**
1. ¿miRNAs con 1 solo SNV son suficientes?
2. ¿O preferimos múltiples SNVs (más evidencia)?

**Pros de ≥ 2 SNVs:**
- ✅ Más evidencia de oxidación
- ✅ Menos probabilidad de error

**Contras:**
- ❌ Excluye el 40-50% de candidatos
- ❌ 1 SNV puede ser suficiente si es fuerte

---

## 🎯 PREGUNTAS CRÍTICAS PARA DECIDIR

### **1. ¿Qué es más importante: FC o p-value?**

**Escenario A:**
```
miRNA-A: FC 5.0x, p 0.08
miRNA-B: FC 1.6x, p 0.001
```

**¿Cuál prefieres?**
- **miRNA-A:** Efecto biológico GRANDE pero borderline estadístico
- **miRNA-B:** Estadísticamente ROBUSTO pero efecto menor

**Mi opinión actual:** Ambos importan, pero depende del objetivo:
- **Para publicación:** Ambos deben cumplir (FC > 1.5x **Y** p < 0.05)
- **Para exploración:** Permitir uno u otro (FC > 2x **O** p < 0.01)

---

### **2. ¿Deberíamos considerar dirección (ALS > Control vs Control > ALS)?**

**Actualmente:**
- Analizamos **SOLO** ALS > Control
- Ignoramos los 22 con Control > ALS

**Alternativa:**
- Analizar **AMBAS** direcciones
- Los 22 Control pueden ser igualmente interesantes

**❓ PREGUNTAS:**
1. ¿Los 22 Control son ruido o hallazgo real?
2. ¿Mecanismo protector en Control?
3. ¿Deberíamos analizarlos también en Paso 3?

---

### **3. ¿Qué métrica de VAF usar?**

**Opciones disponibles:**

| Métrica | Qué mide | Ventajas | Desventajas |
|---------|----------|----------|-------------|
| **Sum(VAF)** | Carga total | Captura efecto acumulativo | Sesgo hacia múltiples SNVs |
| **Mean(VAF)** | Intensidad promedio | Normaliza por # SNVs | Pierde info de cantidad |
| **Max(VAF)** | SNV más fuerte | Enfoca en driver | Ignora otros SNVs |
| **Count(SNVs)** | Número de eventos | Simple, robusto | Ignora intensidad |

**Actual:** Sum(VAF) - Carga total de G>T

**❓ PREGUNTAS:**
1. ¿Sum es la mejor opción?
2. ¿Deberíamos normalizar por longitud del miRNA?
3. ¿Combinar múltiples métricas?

---

### **4. ¿Filtrar por frecuencia en muestras?**

**Escenario:**
```
miRNA-A: 
  - Presente en 200/313 muestras ALS (64%)
  - Mean VAF alto, p significativo
  
miRNA-B:
  - Presente en 5/313 muestras ALS (1.6%)
  - Mean VAF ALTÍSIMO en esas 5, p significativo
```

**¿Cuál es más interesante?**
- **miRNA-A:** Común en ALS (generalizable)
- **miRNA-B:** Subtipo específico de ALS

**❓ PREGUNTAS:**
1. ¿Filtrar por frecuencia mínima (ej: >10% muestras)?
2. ¿O aceptar hallazgos raros pero intensos?
3. ¿Analizar separado: común vs raro?

---

## 💡 PROPUESTAS DE MEJORA

### **PROPUESTA 1: Multi-métrica Scoring**

En vez de solo FC + p-value, usar **score combinado:**

```R
score <- (
  0.4 * log2(FC) +           # 40% peso a FC
  0.3 * (-log10(padj)) +     # 30% peso a significancia
  0.2 * log10(Mean_ALS) +    # 20% peso a intensidad
  0.1 * Pct_Samples_ALS      # 10% peso a frecuencia
)

# Ordenar por score
# Top N candidatos
```

**Ventajas:**
- ✅ Considera múltiples aspectos
- ✅ Balanceo ajustable (pesos)
- ✅ Más comprehensivo

**Desventajas:**
- ❌ Más complejo de interpretar
- ❌ Pesos arbitrarios

---

### **PROPUESTA 2: Filtros Secuenciales**

En vez de umbrales simultáneos, aplicar **filtros en cascada:**

```
PASO 1: Filtro estadístico estricto
  → padj < 0.05
  → Resultado: ~20 candidatos

PASO 2: Filtro de efecto biológico
  → De los 20, FC > 1.5x
  → Resultado: ~8 candidatos

PASO 3: Filtro de frecuencia
  → De los 8, presentes en >15% muestras
  → Resultado: ~5 candidatos finales
```

**Ventajas:**
- ✅ Más transparente
- ✅ Puedes ver efecto de cada filtro
- ✅ Fácil de ajustar

---

### **PROPUESTA 3: Análisis Estratificado**

Separar candidatos en **categorías:**

```
CATEGORÍA 1: ROBUSTOS (Tier 1)
  - FC > 2.0x AND p < 0.01
  - Para validación experimental prioritaria
  - Actualmente: 1 candidato (miR-196a-5p)

CATEGORÍA 2: FUERTES (Tier 2)
  - FC > 1.5x AND p < 0.05
  - Para análisis funcional completo
  - Actualmente: 3 candidatos

CATEGORÍA 3: PROMETEDORES (Tier 3)
  - FC > 1.25x AND p < 0.10
  - Para exploración y generación de hipótesis
  - Actualmente: 15 candidatos

CATEGORÍA 4: EXPLORATORIOS (Tier 4)
  - FC > 1.0x OR p < 0.20
  - Para análisis comprehensivo
  - Actualmente: 48 candidatos
```

**Ventajas:**
- ✅ No hay "corte" arbitrario
- ✅ Priorizas pero no excluyes
- ✅ Diferentes análisis por tier

---

## 📋 MÉTRICAS ALTERNATIVAS A CONSIDERAR

### **A. EFECTO DE TAMAÑO (Effect Size)**

**Cohen's d:**
```R
d = (Mean_ALS - Mean_Control) / SD_pooled

Interpretación:
  d > 0.2 = efecto pequeño
  d > 0.5 = efecto mediano
  d > 0.8 = efecto grande
```

**Ventaja:** Cuantifica magnitud del efecto independiente de p-value

---

### **B. ÁREA BAJO LA CURVA (AUC-ROC)**

**¿Qué mide?**
```
¿Qué tan bien el miRNA discrimina ALS de Control?

AUC:
  0.5 = aleatorio (no discrimina)
  0.7 = aceptable
  0.8 = bueno
  0.9 = excelente
```

**Ventaja:** Mide capacidad de biomarcador directamente

---

### **C. ODDS RATIO**

**¿Qué mide?**
```
Probabilidad de tener G>T alto dado que eres ALS vs Control

OR > 1 = más probable en ALS
OR > 2 = 2x más probable
```

**Ventaja:** Interpretación clínica directa

---

## 🔥 MIS RECOMENDACIONES ACTUALES

### **Para EXPLORACIÓN (lo que estamos haciendo ahora):**

**Preset PERMISSIVE es CORRECTO:**
```
FC > 1.25x (25% más en ALS)
p < 0.10 (10% FDR)

→ 15 candidatos
→ Incluye conocidos (let-7, miR-21)
→ Balance cobertura/robustez
```

**Razón:** Estamos en fase exploratoria, queremos ver patrones.

---

### **Para VALIDACIÓN EXPERIMENTAL:**

**Usar MODERATE o STRICT:**
```
MODERATE: FC > 1.5x, p < 0.05 → 3 candidatos
STRICT: FC > 2.0x, p < 0.01 → 1 candidato

→ Ultra-robustos
→ Máxima probabilidad de replicar
```

**Razón:** qPCR es caro, enfocarse en los mejores.

---

### **Para PUBLICACIÓN:**

**Estrategia de 2 capas:**
```
MAIN FINDINGS: 3 candidatos MODERATE
  - miR-196a-5p, miR-9-5p, miR-142-5p
  - Análisis profundo (targets, pathways, validación)
  - Figuras principales

SUPPLEMENTARY: 12 adicionales PERMISSIVE
  - Análisis básico
  - Tabla suplementaria
  - Mencionar en discusión
```

**Razón:** Robustez en main + cobertura en supp.

---

## ❓ PREGUNTAS ESPECÍFICAS PARA TI

### **1. SOBRE FOLD CHANGE:**

**¿Qué FC te parece biológicamente relevante?**

- [ ] **A.** FC > 2.0x (100% más en ALS) - Muy conservador
- [ ] **B.** FC > 1.5x (50% más en ALS) - Conservador (actual moderate)
- [ ] **C.** FC > 1.25x (25% más en ALS) - Balanceado (actual permissive)
- [ ] **D.** FC > 1.0x (cualquier aumento) - Permisivo

**O combinación:**
- [ ] **E.** FC > 1.3x **Y** ΔVAF > 0.005 (diferencia absoluta)

---

### **2. SOBRE p-value:**

**¿Qué nivel de significancia prefieres?**

- [ ] **A.** padj < 0.01 (1% FDR) - Muy estricto
- [ ] **B.** padj < 0.05 (5% FDR) - Estándar (actual moderate)
- [ ] **C.** padj < 0.10 (10% FDR) - Permisivo (actual permissive)
- [ ] **D.** p-value raw < 0.05 (sin FDR) - Exploratorio

---

### **3. SOBRE FRECUENCIA EN MUESTRAS:**

**¿Deberíamos filtrar por frecuencia?**

- [ ] **A.** SÍ - Al menos 10% de muestras ALS
- [ ] **B.** SÍ - Al menos 20% de muestras ALS
- [ ] **C.** NO - Aceptar cualquier frecuencia
- [ ] **D.** Estratificar - Analizar separado: comunes vs raros

---

### **4. SOBRE VAF MÍNIMO:**

**¿Hay un VAF mínimo aceptable?**

- [ ] **A.** SÍ - Mean VAF > 0.001 (0.1%)
- [ ] **B.** SÍ - Mean VAF > 0.005 (0.5%)
- [ ] **C.** NO - Cualquier VAF detectable
- [ ] **D.** Depende - Si p-value muy bajo, aceptar VAF bajo

---

### **5. SOBRE DIRECCIÓN:**

**¿Qué hacer con los 22 candidatos Control?**

- [ ] **A.** Ignorarlos - Enfocarse solo en ALS
- [ ] **B.** Analizarlos separado - Paso 3 para Control también
- [ ] **C.** Compararlos - Ver si son mecanismos opuestos
- [ ] **D.** Combinarlos - Análisis bidireccional

---

## 🔬 CASOS ESPECÍFICOS PARA DISCUTIR

### **CASO 1: hsa-miR-9-3p**
```
FC: 7.05x (MUY ALTO - el más alto de todos)
p-value: 0.0993 (borderline, no pasa 0.05 ni 0.10)
Mean ALS: 0.0015
Mean Control: 0.0002

ACTUALMENTE: NO incluido en PERMISSIVE (p > 0.10)
```

**❓ ¿Deberíamos incluirlo por el FC altísimo?**
- **Opción A:** NO - p-value no cumple
- **Opción B:** SÍ - FC > 5x es demasiado alto para ignorar
- **Opción C:** Tier especial - "High FC, borderline p"

---

### **CASO 2: hsa-miR-1-3p**
```
FC: 1.30x (bajo)
p-value: 0.0008 (MUY BAJO - altamente significativo)
Mean ALS: 0.0010
Mean Control: 0.0008

ACTUALMENTE: Incluido en PERMISSIVE
```

**❓ ¿Es el FC suficiente o muy bajo?**
- **Opción A:** SÍ - p-value excelente compensa FC bajo
- **Opción B:** NO - FC 1.3x es biológicamente irrelevante
- **Opción C:** Tier 3 - Explorar pero no priorizar

---

### **CASO 3: hsa-miR-6129**
```
FC: -2.67x (CONTROL > ALS)
p-value: 0.0001 (MUY significativo)
Mean Control: 0.1724 (¡ALTÍSIMO!)
Mean ALS: 0.0844

Top 1 del Paso 1 (mayor VAF total)
```

**❓ ¿Qué hacemos con este?**
- **Opción A:** Ignorar - No es ALS
- **Opción B:** Analizar - Mecanismo protector en Control
- **Opción C:** Investigar - ¿Por qué Control tiene tanto G>T?

---

## 🎯 PROPUESTA DE DISCUSIÓN

**Definamos juntos:**

### **1. CRITERIOS PRINCIPALES (Obligatorios)**
```
¿Qué DEBE cumplir un candidato para ser incluido?

Propuesta actual:
  - Tener G>T en seed (pos 2-8) ✅
  - FC > ??? (TÚ DECIDES)
  - p-value < ??? (TÚ DECIDES)
```

### **2. CRITERIOS SECUNDARIOS (Opcionales)**
```
¿Qué es DESEABLE pero no obligatorio?

Propuesta:
  - Frecuencia en muestras > ???%
  - VAF mínimo > ???
  - Número de SNVs ≥ ???
```

### **3. CASOS ESPECIALES**
```
¿Cómo manejar:
  - FC alto pero p borderline? (miR-9-3p)
  - p bajo pero FC bajo? (miR-1-3p)
  - Control > ALS? (los 22)
```

---

## 📊 MI RECOMENDACIÓN FINAL

**Para TU caso específico (pipeline ajustable):**

### **Configuración ÓPTIMA:**

**TIER 1 (Robustos - Para validar):**
```
FC > 2.0x AND padj < 0.01
→ 1-2 candidatos
→ Prioridad máxima
```

**TIER 2 (Fuertes - Para analizar):**
```
FC > 1.5x AND padj < 0.05
→ 3-5 candidatos
→ Análisis funcional completo
```

**TIER 3 (Prometedores - Para explorar):**
```
(FC > 1.25x AND padj < 0.10) OR (FC > 3.0x AND padj < 0.15)
→ 10-15 candidatos
→ Incluye FC altos borderline
```

**TIER 4 (Exploratorios):**
```
FC > 1.0x OR padj < 0.20
→ 40-50 candidatos
→ Análisis comprehensivo
```

---

## ✅ SIGUIENTE PASO

**¿Qué prefieres hacer?**

1. **Discutir y ajustar los umbrales actuales**
   - Revisar cada métrica
   - Decidir valores óptimos
   - Actualizar CONFIG_THRESHOLDS.json

2. **Mantener los actuales pero añadir filtros**
   - Frecuencia en muestras
   - VAF mínimo
   - Casos especiales

3. **Crear sistema de scoring multi-métrica**
   - Combinar FC, p-value, frecuencia, VAF
   - Ranking continuo en vez de corte

4. **Analizar casos específicos**
   - miR-9-3p (FC 7x, p 0.099)
   - Los 22 Control
   - Decidir qué hacer con ellos

---

**¿Por dónde quieres empezar la discusión?** 🤔

Podemos revisar métrica por métrica, o casos específicos, o crear un sistema nuevo desde cero.
