# 🔥 HALLAZGOS DEL VOLCANO PLOT (MÉTODO CORRECTO)

**Fecha:** 2025-10-17 01:25
**Método:** Promedio por muestra (Opción B)
**Datos:** Limpios (sin VAF ≥ 0.5)

---

## 📊 RESULTADOS GENERALES

### **miRNAs Testeados:** 301 (con G>T en seed)

### **Clasificación:**
- **ALS enriched:** 3 miRNAs (FC > 1.5x, FDR < 0.05)
- **Control enriched:** 22 miRNAs (FC < 0.67x, FDR < 0.05)
- **No significativo:** 276 miRNAs

---

## 🔝 TOP miRNAs DIFERENCIALMENTE AFECTADOS

### **🔵 ENRIQUECIDOS EN CONTROL (22 miRNAs):**

| Ranking | miRNA | log2(FC) | FDR p-value | Interpretación |
|---------|-------|----------|-------------|----------------|
| #1 | **hsa-miR-503-5p** | -1.14 | **2.55e-07** | Control 2.2x > ALS |
| #2 | **hsa-miR-877-5p** | -2.03 | 4.33e-06 | Control 4.1x > ALS |
| #3 | **hsa-miR-6129** | -1.03 | 1.37e-04 | Control 2.0x > ALS ⚠️ |
| #4 | **hsa-miR-28-3p** | -0.74 | 1.57e-04 | Control 1.7x > ALS |
| #5 | **hsa-miR-339-3p** | -0.64 | 2.67e-04 | Control 1.6x > ALS |
| #6 | hsa-miR-92b-5p | -1.31 | 6.02e-04 | Control 2.5x > ALS |
| #7 | hsa-miR-20b-5p | -1.24 | 6.02e-04 | Control 2.4x > ALS |
| #8 | hsa-let-7e-5p | -0.63 | 8.93e-04 | Control 1.5x > ALS |
| #9 | hsa-miR-4508 | -0.95 | 1.98e-03 | Control 1.9x > ALS |
| #10 | hsa-miR-1908-3p | -1.91 | 1.98e-03 | Control 3.8x > ALS |

### **🔴 ENRIQUECIDOS EN ALS (3 miRNAs):**

| Ranking | miRNA | log2(FC) | FDR p-value | Interpretación |
|---------|-------|----------|-------------|----------------|
| #1 | **hsa-miR-196a-5p** | +1.78 | 2.17e-03 | ALS 3.4x > Control |
| #2 | **hsa-miR-9-5p** | +0.66 | 5.83e-03 | ALS 1.6x > Control |
| #3 | hsa-miR-4746-5p | +0.91 | 2.92e-02 | ALS 1.9x > Control |

---

## ⚠️ HALLAZGO CRÍTICO

### **hsa-miR-6129 está ENRIQUECIDO EN CONTROL**

- **Ranking por VAF total:** #1 (7.09)
- **Pero en Volcano Plot:** **CONTROL > ALS** (FC = -1.03, p = 1.37e-04)

**Interpretación:**
- Tiene el **mayor VAF total** (suma de todas las muestras)
- Pero **Control tiene más** que ALS cuando se compara muestra por muestra
- Consistente con el hallazgo global de "Control > ALS"

---

## 🎯 CANDIDATOS REALES PARA VALIDACIÓN

### **Enriquecidos en ALS (Estrés Oxidativo):**
1. ⭐ **hsa-miR-196a-5p** - ALS 3.4x > Control (p = 2.17e-03)
2. ⭐ **hsa-miR-9-5p** - ALS 1.6x > Control (p = 5.83e-03)
3. hsa-miR-4746-5p - ALS 1.9x > Control (p = 2.92e-02)

**Estos son los ÚNICOS 3 miRNAs con:**
- G>T en región seed
- Mayor VAF en ALS que en Control
- Diferencia estadísticamente significativa (FDR < 0.05)

### **Protegidos en Control (Menor Oxidación):**
1. ⭐ **hsa-miR-503-5p** - Control 2.2x > ALS (p = 2.55e-07)
2. **hsa-miR-877-5p** - Control 4.1x > ALS
3. **hsa-miR-6129** - Control 2.0x > ALS

---

## 💡 INTERPRETACIÓN BIOLÓGICA

### **¿Por qué Control > ALS en la mayoría?**

#### **Hipótesis 1: Efecto Técnico (Más Probable)**
- **Batch effect** entre estudios ALS y Control
- Diferencias en **profundidad de secuenciación**
- Protocolos de **extracción/procesamiento** diferentes
- **Calidad de muestra** diferente

#### **Hipótesis 2: Biológica (Menos Probable)**
- **Heterogeneidad** natural mayor en Control
- **Filtros de calidad** más estrictos en ALS
- Diferencias en **edad/características** demográficas

#### **Acción Recomendada:**
1. **Normalizar** por library size/profundidad
2. **Corrección por batch** si es posible
3. **Usar proporciones** (G>T/Total) en vez de VAF absoluto
4. **Análisis de confounders** (edad, sexo, batch)

---

## 📊 DIFERENCIAS CON MÉTODO ANTERIOR

### **Método A (Mezclado) vs Método B (Por Muestra):**

**Resultados pueden diferir porque:**
- Método A da más peso a miRNAs con más SNVs
- Método B trata cada muestra igual
- Fold Changes calculados diferente
- P-values diferentes

**Método B es más apropiado porque:**
- Unidad de comparación = **muestra** (individuo)
- Sin sesgo técnico
- Interpretación biológica clara
- Estadísticamente robusto

---

## ✅ ARCHIVOS GENERADOS

### **Figuras:**
- `FIG_2.3_VOLCANO_PER_SAMPLE_METHOD.png` - Volcano plot correcto

### **Datos:**
- `VOLCANO_PLOT_DATA_PER_SAMPLE.csv` - Todos los FC y p-values
  - 301 miRNAs
  - log2FC, pvalue, padj, clasificación
  - Mean ALS, Mean Control
  - N de muestras por grupo

### **Documentación:**
- `METODO_VOLCANO_PLOT.md` - Método explicado
- `EXPLICACION_VOLCANO_PLOT.md` - Lógica paso a paso
- `OPCIONES_CALCULO_VOLCANO.md` - Comparación de métodos
- `HALLAZGOS_VOLCANO_CORRECTO.md` - Este documento

---

## 🚀 SIGUIENTE PASO

Con este método correcto implementado, ahora debemos:
1. ✅ Verificar el Volcano Plot generado
2. ✅ Revisar los 3 miRNAs enriquecidos en ALS
3. ✅ Considerar normalización por batch/profundidad
4. ⏭️ Completar figuras restantes (2.4, 2.5, 2.7, 2.8, 2.11)
5. ⏭️ Planificar Paso 3 enfocado en los 3 miRNAs ALS

---

**Método implementado:** 2025-10-17 01:25
**Archivo:** FIG_2.3_VOLCANO_PER_SAMPLE_METHOD.png
**Hallazgo clave:** Solo 3 miRNAs enriquecidos en ALS

