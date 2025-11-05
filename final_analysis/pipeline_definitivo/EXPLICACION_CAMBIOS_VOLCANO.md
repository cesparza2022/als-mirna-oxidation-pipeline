# 🔍 ¿QUÉ CAMBIÓ EN EL VOLCANO PLOT?

**Fecha:** 2025-10-24  
**Tu pregunta:** "¿Por qué antes sí salían resultados y ahora no?"

---

## 📊 **COMPARACIÓN: ANTES vs AHORA**

### **VERSIÓN ANTERIOR (con resultados significativos):**

**Archivo:** `figures_paso2_ALL_SEED/FIGURA_2.3_VOLCANO_ALL_SEED_GT.png`

**Datos usados:**
```r
if (file.exists("final_processed_data_FILTERED_VAF50.csv")) {
  data <- read.csv("final_processed_data_FILTERED_VAF50.csv")
  # ← DATOS FILTRADOS (solo VAF < 0.5)
}
```

**Procesamiento:**
- Usa `final_processed_data_FILTERED_VAF50.csv` si existe
- Fallback a datos originales si no existe

---

### **VERSIÓN ACTUAL (sin resultados significativos):**

**Archivo:** `FIG_2.3_VOLCANO_CORRECTED.png`

**Datos usados:**
```r
data <- read_csv("final_processed_data_CLEAN.csv", show_col_types = FALSE)
# ← DATOS LIMPIOS (diferentes!)
```

**Procesamiento:**
- Usa directamente `final_processed_data_CLEAN.csv`

---

## 🔥 **EL CAMBIO CRÍTICO:**

### **LA DIFERENCIA ESTÁ EN LOS DATOS DE ENTRADA:**

```
ANTES:
final_processed_data_FILTERED_VAF50.csv
   ↓
[Volcano con resultados significativos]

AHORA:
final_processed_data_CLEAN.csv
   ↓
[Volcano SIN resultados significativos]
```

---

## 🤔 **¿CUÁL ES LA DIFERENCIA ENTRE ESTOS DOS ARCHIVOS?**

Necesito verificar, pero las opciones son:

### **Opción 1: Diferentes filtros de VAF**
```r
# FILTERED_VAF50: Filtra VAF >= 0.5 (quita artefactos)
# CLEAN: Puede tener filtro diferente o adicional
```

### **Opción 2: Diferentes métodos de procesamiento**
```r
# FILTERED: Resultado del filtro de calidad QC
# CLEAN: Resultado de limpieza más agresiva
```

### **Opción 3: Diferentes números de SNVs**
```r
# Si CLEAN tiene MENOS SNVs → Menos poder estadístico
# Menos poder → No alcanza significancia
```

---

## 📋 **ANÁLISIS NECESARIO:**

Voy a crear un script que compare ambos archivos para ver **EXACTAMENTE** qué cambió:

```r
# 1. Número de filas (SNVs)
# 2. Rango de VAF
# 3. Número de miRNAs
# 4. Promedio de VAF por grupo
```

---

## 🎯 **HIPÓTESIS:**

### **Hipótesis 1: CLEAN es más restrictivo**
- Filtró más SNVs
- Perdió variantes significativas
- → No alcanza significancia estadística

### **Hipótesis 2: CLEAN tiene menos muestras**
- Si algunas muestras fueron excluidas
- → Menos poder estadístico

### **Hipótesis 3: CLEAN normalizó diferente**
- Si los valores fueron re-normalizados
- → Cambió las distribuciones

---

## ⚠️ **IMPACTO:**

### **Si CLEAN eliminó demasiado:**
- Perdemos hallazgos reales
- Volcano no es informativo
- **Solución:** Usar versión menos restrictiva

### **Si CLEAN corrigió artefactos:**
- La versión anterior tenía falsos positivos
- Volcano actual es más correcto (aunque vacío)
- **Solución:** Aceptar que no hay miRNAs individuales significativos

---

## 🔬 **VAMOS A INVESTIGAR:**

Déjame crear un script que compare ambos archivos para ver:

1. **¿Cuántos SNVs tiene cada uno?**
2. **¿Cuántos miRNAs tiene cada uno?**
3. **¿Qué diferencias hay en VAF?**
4. **¿Por qué uno da significativos y otro no?**

---

**Momento, voy a crear el análisis comparativo...**

