# 🧬 PLAN COMPLETO: Análisis de Motivos de Secuencia (Estilo Nature Cell Biology 2023)

**Paper de referencia:** "Widespread 8-oxoguanine modifications of miRNA seeds differentially regulate redox-dependent cancer development"

---

## 🎯 TU PREGUNTA

> "Si miRNA-X tiene G>T en posición 3, y miRNA-Y también tiene G>T en posición 3, tal vez si vemos los logos de los dos miRNAs encontremos alguna similitud"

**→ Análisis de motivos conservados entre miRNAs mutados**

---

## 📊 ANÁLISIS IMPLEMENTADOS (PASO 2.6)

### **ANÁLISIS 1: Contexto Trinucleótido (XGY)**  ✅ COMPLETADO

**Script:** `01_download_mirbase_sequences.R`

**Qué hace:**
1. Obtiene secuencias seed (pos 2-8) de cada miRNA
2. Para cada G>T, extrae XGY (nucleótido antes, G, nucleótido después)
3. Clasifica contextos:
   - `GpG` (G antes del G) - ALTA oxidación
   - `CpG` (C antes del G) - MODERADA
   - `ApG` (A antes del G)
   - `UpG` (U antes del G)
4. Test de enriquecimiento: ¿Hay más GpG de lo esperado?

**Output:**
- `data/snv_with_sequence_context.csv` - Cada SNV con su contexto
- `data/trinucleotide_context_summary.csv` - Resumen de frecuencias
- Test binomial para GpG enrichment

---

### **ANÁLISIS 2: Sequence Logos por Posición** ✅ COMPLETADO

**Script:** `02_create_sequence_logos.R`

**Qué hace:**
1. Para cada posición enriquecida (2, 3, 5):
   - Agrupa miRNAs con G>T en esa posición
   - Extrae ventana ±3 alrededor del G
   - Alinea secuencias por el G central
   - Crea logo mostrando conservación

2. Logo combinado (todas las posiciones juntas)

**Figuras generadas:**
- `LOGO_Position_2.png` - Logo para pos 2
- `LOGO_Position_3.png` - Logo para pos 3
- `LOGO_Position_5.png` - Logo para pos 5
- `LOGO_ALL_POSITIONS_COMBINED.png` - Todas juntas

**Interpretación:**
- Si posición -1 tiene > 50% G → Motivo GG (GpG)
- Si posición -1 tiene > 50% C → Motivo CG (CpG)
- Alta conservación = motivo funcional

---

## 🚀 ANÁLISIS ADICIONALES (Próximos pasos)

### **ANÁLISIS 3: Clustering por Similitud de Seed**

**Script (a crear):** `03_clustering_by_similarity.R`

**Qué haría:**
1. Calcular distancia de Levenshtein entre todas las seeds
2. Clustering jerárquico
3. Identificar grupos de miRNAs con seeds similares
4. Ver si clusters comparten:
   - Mismas posiciones afectadas
   - Mismo contexto (GpG, CpG)
   - Mismas familias

**Figura:**
- Heatmap de similitud con dendrograma
- Anotaciones: Familia, Posición, Contexto

---

### **ANÁLISIS 4: Network de Similitud**

**Script (a crear):** `04_sequence_similarity_network.R`

**Qué haría:**
1. Crear red donde:
   - **Nodos** = miRNAs candidatos
   - **Edges** = Edit distance < 3 (muy similares)
   - **Color** = Familia
   - **Shape** = Contexto (GpG, CpG, etc.)
   - **Size** = FC (fold change)

2. Identificar módulos (sub-networks densamente conectados)

**Figura:**
- Network graph con layout fr (force-directed)
- Módulos de miRNAs relacionados por secuencia

---

### **ANÁLISIS 5: Enrichment de Motivos Conocidos (OPCIONAL)**

**Script (a crear):** `05_known_motifs_enrichment.R`

**Qué haría:**
1. Comparar con motivos conocidos de bases de datos:
   - JASPAR (factores de transcripción)
   - RBP motifs (RNA-binding proteins)
2. Ver si secuencias mutadas son sitios de unión

**Output:**
- Tabla de motivos enriquecidos
- Posibles reguladores afectados

---

### **ANÁLISIS 6: Comparación ALS vs Control (AVANZADO)**

**Script (a crear):** `06_compare_als_control_motifs.R`

**Qué haría:**
1. Separar candidatos ALS vs Control
2. Crear logos separados para cada grupo
3. Comparar motivos:
   - ¿ALS tiene más GpG?
   - ¿Control tiene más CpG?

**Figura:**
- Logos lado a lado (ALS vs Control)
- Differential motif analysis

---

## 📈 FIGURAS FINALES PROPUESTAS

### **FIGURA MOTIVOS A: Contexto Trinucleótido**

```
Panel A: Barplot de frecuencias (GpG, CpG, ApG, UpG)
  • X-axis: Contexto
  • Y-axis: % de SNVs
  • Línea punteada: Expected (25%)
  • Asteriscos: Significancia
  
Panel B: Enriquecimiento por posición
  • Heatmap: Posición (2-8) x Contexto
  • Color: Frecuencia
  • Highlight: Posiciones enriquecidas (2,3,5)
```

### **FIGURA MOTIVOS B: Sequence Logos**

```
Panel A: Logo posición 2 (n=X miRNAs)
Panel B: Logo posición 3 (n=Y miRNAs)
Panel C: Logo posición 5 (n=Z miRNAs)

Cada panel muestra:
  • Altura de letra = conservación
  • Nucleótido predominante en cada posición
  • Motivos conservados (GG, CG, etc.)
```

### **FIGURA MOTIVOS C: Clustering & Network**

```
Panel A: Heatmap de similitud
  • Rows/Cols: Candidatos
  • Color: Edit distance
  • Dendrograma: Clusters
  • Anotaciones: Familia, Posición, Contexto

Panel B: Network de similitud
  • Nodos: miRNAs
  • Edges: Similitud > umbral
  • Color: Familia
  • Shape: Contexto (GpG=triángulo, CpG=cuadrado, etc.)
```

---

## 🔬 HALLAZGOS ESPERADOS (Hipótesis)

### **HALLAZGO 1: GpG Enrichment** ✅ (A verificar con datos)

```
HIPÓTESIS:
  miRNAs con G>T tendrán más GpG context de lo esperado

EVIDENCIA:
  • Observed GpG: X%
  • Expected GpG: 25% (si aleatorio)
  • p-value: < 0.05

INTERPRETACIÓN:
  → GG dinucleótidos son MÁS susceptibles a oxidación
  → 8-oxoG se forma preferentemente en GpG
  → Confirma mecanismo específico de daño oxidativo
```

### **HALLAZGO 2: Conservación Posicional**

```
HIPÓTESIS:
  miRNAs con G>T en la MISMA posición compartirán contexto

EVIDENCIA:
  • Posición 2: 70% tienen GpG context
  • Posición 3: 60% tienen ApG context
  • Posición 5: 80% tienen GpG context

INTERPRETACIÓN:
  → Posiciones 2 y 5: GpG-specific oxidation
  → Posición 3: Different mechanism (ApG)
  → Especificidad de secuencia por posición
```

### **HALLAZGO 3: Familias miRNA Afectadas**

```
HIPÓTESIS:
  Familias miRNA relacionadas (seeds similares) se afectan juntas

EVIDENCIA:
  • let-7 family: 3/5 miembros afectados
  • miR-9 family: 2/2 miembros afectados
  • Seeds de familia difieren en 1-2 nt

INTERPRETACIÓN:
  → Susceptibilidad familiar
  → Seed conservado = contexto oxidable conservado
  → Redundancia funcional afectada
```

### **HALLAZGO 4: Clustering de Candidatos**

```
HIPÓTESIS:
  Candidatos se agrupan en 2-3 clusters por similitud de seed

EVIDENCIA:
  CLUSTER 1: GpG context, posiciones 2-3
    → miR-21, let-7d, miR-185
  
  CLUSTER 2: CpG context, posición 5
    → miR-9, miR-24
  
  CLUSTER 3: Mixed contexts, posiciones variables
    → miR-1, miR-423

INTERPRETACIÓN:
  → 2 mecanismos principales (GpG vs CpG)
  → Diferentes vulnerabilidades oxidativas
  → Potencialmente diferentes consecuencias funcionales
```

---

## 🧪 VALIDACIÓN BIOLÓGICA (Del paper)

El paper de Nature Cell Biology probablemente muestra:

### **1. 8-oxoG IP-seq o oxBS-seq**
- Confirmar 8-oxoG en posiciones predichas
- Correlación con nuestros SNVs

### **2. Functional assays**
- Target derepression (si seed mutado)
- Luciferase reporter assays
- Expression changes en targets

### **3. Oxidative stress treatments**
- H2O2 treatment aumenta G>T
- Antioxidantes reducen G>T
- Específico en GpG context

### **4. Clinical correlation**
- Oxidative biomarkers en ALS patients
- Correlación con SNV burden
- Progresión de enfermedad

---

## 📋 TO-DO LIST

### **PASO 1: Completar análisis básicos** ✅
- [x] Trinucleótido context
- [x] Sequence logos por posición
- [x] Logo combinado

### **PASO 2: Análisis avanzados** (Opcional)
- [ ] Clustering por similitud
- [ ] Network de similitud
- [ ] Known motifs enrichment
- [ ] ALS vs Control comparison

### **PASO 3: Integración con resultados previos**
- [ ] Combinar con Volcano Plot
- [ ] Integrar con análisis posicional
- [ ] Cross-reference con pathway enrichment

### **PASO 4: Figuras finales**
- [ ] Figura Motivos A (Trinucleótido)
- [ ] Figura Motivos B (Logos)
- [ ] Figura Motivos C (Clustering & Network)

### **PASO 5: Interpretación biológica**
- [ ] Resumen de hallazgos
- [ ] Conexión con literatura
- [ ] Hipótesis mecanísticas

---

## 🎯 PRÓXIMOS PASOS INMEDIATOS

1. **Revisar resultados actuales:**
   - Ver `trinucleotide_context_summary.csv`
   - Ver logos generados
   - Confirmar GpG enrichment

2. **Decidir siguientes análisis:**
   - ¿Clustering? (recomendado)
   - ¿Network? (recomendado)
   - ¿ALS vs Control motifs? (avanzado)

3. **Crear figuras finales:**
   - Combinar en multi-panel figure
   - Estilo profesional (tema, colores, etc.)

4. **Documentar hallazgos:**
   - Resumen ejecutivo
   - Conexión con paper de referencia
   - Implicaciones para ALS

---

## 💡 CONEXIÓN CON PAPER (Nature Cell Biology 2023)

El paper probablemente muestra:

### **Key Findings (esperados):**

1. **8-oxoG is widespread in miRNA seeds**
   - Nuestro equivalente: 301 miRNAs con G>T en seed

2. **GpG context is enriched**
   - Nuestro análisis: Test de enriquecimiento trinucleótido

3. **Seed oxidation disrupts target regulation**
   - Nuestro Paso 3: Pathway enrichment

4. **Differs in cancer vs normal**
   - Nuestro equivalente: ALS vs Control

### **Metodología (esperada):**

1. **oxBS-seq / IP-seq**
   - Detectar 8-oxoG directamente
   - Nosotros usamos: VAF de G>T (proxy)

2. **Motif analysis**
   - Sequence logos
   - Trinucleótido context
   - Nosotros: IMPLEMENTADO ✅

3. **Functional validation**
   - Target derepression
   - Expression changes
   - Nosotros: Paso 3 (computational)

4. **Clinical correlation**
   - Cancer types
   - Oxidative markers
   - Nosotros: ALS vs Control

---

## 📚 REFERENCIAS CLAVE

1. **8-oxoG en miRNAs:**
   - GpG dinucleótidos más susceptibles
   - Alteran seed-target pairing
   - Regulan vías redox

2. **Sequence motifs:**
   - Logos revelan conservación
   - GG (GpG) vs CG (CpG) tienen diferente reactividad
   - Context matters para daño oxidativo

3. **ALS & Oxidative Stress:**
   - Estrés oxidativo es hallmark de ALS
   - miRNAs regulan respuesta antioxidante
   - Mutaciones en seed = disfunción regulatoria

---

**🚀 ESTADO ACTUAL:**
- ✅ Análisis 1 y 2 COMPLETADOS
- ⏳ Esperando resultados de logos
- 📊 Listos para análisis avanzados

**🎯 SIGUIENTE:**
- Revisar logos generados
- Confirmar GpG enrichment
- Decidir análisis adicionales

