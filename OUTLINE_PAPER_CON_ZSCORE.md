# 📋 OUTLINE ESTRATÉGICO DEL PAPER - miRNAs y Oxidación en ALS

## 🎯 OBJETIVOS PRINCIPALES

### **Pregunta Central:**
¿Existen diferencias significativas en la oxidación de miRNAs (especialmente mutaciones G>T) entre pacientes con ALS y controles sanos, y cuáles son las implicaciones funcionales?

### **Hipótesis:**
1. **Hipótesis Principal:** Los pacientes con ALS muestran patrones distintivos de oxidación de miRNAs en la región semilla
2. **Hipótesis Secundaria:** Las diferencias en oxidación se correlacionan con la expresión de miRNAs y afectan vías biológicas relevantes para ALS

---

## 📖 ESTRUCTURA DEL PAPER

### **1. INTRODUCTION**
- **Contexto:** ALS como enfermedad neurodegenerativa
- **Importancia de miRNAs:** Regulación post-transcripcional
- **Oxidación de miRNAs:** 8-oxoG y mutaciones G>T
- **Gap de conocimiento:** Falta de estudios sistemáticos de oxidación de miRNAs en ALS
- **Objetivos:** Análisis comparativo ALS vs controles

### **2. METHODS**

#### **2.1 Dataset y Muestras**
- **Dataset Magen ALS-bloodplasma:** 415 muestras (249 ALS-enrolment, 64 ALS-longitudinal, 102 controles)
- **Criterios de inclusión/exclusión**
- **Características demográficas**

#### **2.2 Procesamiento de Datos**
- **Pipeline de limpieza:** Split, collapse, filtro de representación
- **Filtros de calidad:** RPM >1, VAF-based representation filter
- **Identificación de mutaciones G>T en región semilla (posiciones 2-8)**

#### **2.3 Análisis Estadístico**
- **Análisis descriptivo:** Conteos, proporciones, distribuciones
- **Análisis comparativo:** Z-score, t-test, fold change
- **Corrección múltiple:** FDR, Bonferroni
- **Análisis de correlación:** Expresión vs oxidación

#### **2.4 Análisis Funcional**
- **Análisis de vías:** KEGG, GO
- **Predicción de targets:** TargetScan
- **Análisis de redes:** PPI, miRNA-target networks

### **3. RESULTS**

#### **3.1 Caracterización del Dataset**
- **Distribución de muestras por grupo**
- **Calidad de datos post-procesamiento**
- **Cobertura de miRNAs y SNVs**

#### **3.2 Análisis Descriptivo Global**
- **Total de SNVs identificados:** 21,526
- **Mutaciones G>T en región semilla:** 328 SNVs, 212 miRNAs únicos
- **Distribución por posición:** Posiciones 2-8 cubiertas
- **Patrones de mutación:** T>C más frecuente (14.09%), G>T (7.2%)

#### **3.3 Análisis Comparativo ALS vs Control (Z-SCORE)**
- **Metodología Z-score:** Comparación estadística robusta
- **Top SNVs con diferencias significativas:**
  - **hsa-miR-491-5p (pos 6):** Z-score = 2.00, mayor oxidación en ALS
  - **hsa-miR-6852-5p (pos 8):** Z-score = -1.87, mayor oxidación en controles
  - **hsa-miR-18a-5p (pos 7):** Z-score = -1.41, mayor oxidación en controles

#### **3.4 Análisis por Posición**
- **Posición 6:** Mayor variabilidad (Z-score promedio = 0.193)
- **Posición 5:** Tendencia a mayor oxidación en controles (Z-score = -0.175)
- **Posiciones 2-3:** Datos insuficientes para análisis robusto

#### **3.5 Análisis por miRNA**
- **Top miRNAs con diferencias significativas**
- **Patrones de oxidación diferencial**
- **Correlación expresión-oxidación:** r = 0.8363 (p < 1.03 × 10⁻⁵⁶)

#### **3.6 Análisis Funcional**
- **Vías afectadas por miRNAs oxidados**
- **Targets predichos y validados**
- **Implicaciones biológicas**

### **4. DISCUSSION**

#### **4.1 Interpretación de Hallazgos Principales**
- **Diferencias específicas vs patrones uniformes**
- **Importancia de posición 6 en región semilla**
- **Correlación expresión-oxidación**

#### **4.2 Implicaciones Biológicas**
- **Mecanismos de oxidación en ALS**
- **Impacto funcional de mutaciones G>T**
- **Vías de señalización afectadas**

#### **4.3 Comparación con Literatura**
- **Estudios previos de oxidación en neurodegeneración**
- **Diferencias metodológicas**
- **Novedad de nuestros hallazgos**

#### **4.4 Limitaciones**
- **Tamaño de muestra**
- **Análisis transversal vs longitudinal**
- **Validación experimental**

#### **4.5 Implicaciones Clínicas**
- **Biomarcadores potenciales**
- **Dianas terapéuticas**
- **Estrategias de intervención**

### **5. CONCLUSIONES**
- **Resumen de hallazgos clave**
- **Contribuciones al campo**
- **Direcciones futuras**

---

## 🎨 FIGURAS PRINCIPALES

### **Figura 1: Pipeline de Análisis**
- Diagrama de flujo del procesamiento de datos
- Filtros aplicados y criterios de calidad

### **Figura 2: Caracterización Global**
- Distribución de mutaciones por tipo
- Cobertura por posición en región semilla
- Distribución de muestras por grupo

### **Figura 3: Análisis Z-Score (PRINCIPAL)**
- Heatmap de Z-scores por miRNA y posición
- Gráficos de distribución de Z-scores
- Top SNVs con diferencias significativas

### **Figura 4: Análisis por Posición**
- Z-score promedio por posición
- Significancia estadística por posición
- Interpretación biológica

### **Figura 5: Correlación Expresión-Oxidación**
- Scatter plot de RPM vs oxidación G>T
- Análisis por categorías de expresión
- Top miRNAs con alta expresión y oxidación

### **Figura 6: Análisis Funcional**
- Red de miRNAs oxidados y sus targets
- Enriquecimiento de vías
- Implicaciones biológicas

---

## 📊 TABLAS PRINCIPALES

### **Tabla 1: Características del Dataset**
- Distribución de muestras
- Criterios de inclusión
- Características demográficas

### **Tabla 2: Top SNVs con Diferencias Significativas**
- Z-score, p-value, fold change
- Interpretación biológica
- Significancia estadística

### **Tabla 3: Análisis por Posición**
- Estadísticas por posición
- Significancia comparativa
- Interpretación funcional

### **Tabla 4: Top miRNAs Afectados**
- Métricas de oxidación
- Posiciones afectadas
- Correlación con expresión

### **Tabla 5: Análisis Funcional**
- Vías enriquecidas
- Targets predichos
- Implicaciones biológicas

---

## 🔬 ANÁLISIS ESTADÍSTICO CLAVE

### **Métricas Principales:**
1. **Z-score:** Diferencia estandarizada entre grupos
2. **Fold change:** Razón ALS/Control
3. **P-value:** Significancia estadística
4. **Correlación:** Expresión vs oxidación

### **Umbrales de Significancia:**
- **Z-score > 1.5:** Moderadamente significativo
- **Z-score > 2.0:** Altamente significativo
- **P-value < 0.05:** Estadísticamente significativo
- **FDR < 0.05:** Corrección múltiple

---

## 🎯 MENSAJES CLAVE

1. **Diferencias Específicas:** No hay patrón uniforme de mayor oxidación en ALS
2. **Posición 6 Crítica:** Mayor variabilidad y significancia biológica
3. **Correlación Expresión-Oxidación:** Relación fuerte y significativa
4. **Implicaciones Funcionales:** miRNAs específicos con impacto biológico
5. **Metodología Robusta:** Z-score permite identificar diferencias reales

---

## 📈 IMPACTO ESPERADO

- **Contribución científica:** Primer análisis sistemático de oxidación de miRNAs en ALS
- **Metodología:** Pipeline robusto para análisis comparativo
- **Hallazgos:** Identificación de miRNAs específicos con diferencias significativas
- **Aplicaciones:** Biomarcadores potenciales y dianas terapéuticas
- **Futuro:** Base para estudios funcionales y validación experimental

---

## 🔄 INTEGRACIÓN CON ANÁLISIS PREVIOS

Este outline integra:
- **Análisis de significancia real** (VAF-based)
- **Análisis Z-score** (diferencias ALS vs Control)
- **Análisis de correlación** (expresión vs oxidación)
- **Análisis funcional** (vías y targets)
- **Metodología robusta** (pipeline de limpieza)

**El enfoque en Z-score y diferencias reales entre grupos proporciona la base estadística sólida para un paper de alto impacto.**










