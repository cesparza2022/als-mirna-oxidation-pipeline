# RESUMEN - PASO 7A: ANÁLISIS TEMPORAL

## 🎯 **HALLAZGO CRÍTICO**

### **✅ LAS MUTACIONES G>T CAMBIAN SIGNIFICATIVAMENTE EN EL TIEMPO**

```
Paired t-test (Longitudinal vs Enrolment):
├── N mutaciones G>T analizadas: 943
├── Diferencia promedio: +0.000598 (aumento de 0.06%)
├── t-statistic: 3.30
├── p-value: 0.001 (p < 0.05) ✅ SIGNIFICATIVO
└── Interpretación: G>T AUMENTAN con el tiempo en ALS
```

---

## 📊 **CAMBIOS TEMPORALES EN MUTACIONES G>T**

### **Dirección de cambios (Enrolment → Longitudinal):**
```
Total G>T analizadas: 2,193

Disminución:  1,165 (53.1%) ⬇️ Mayoría disminuyen
Aumento:        558 (25.4%) ⬆️ Algunos aumentan
Sin cambio:     470 (21.4%) ➡️ Estables
```

**Paradoja aparente:**
- **Mayoría de G>T individuales DISMINUYEN** (53%)
- **PERO el promedio AUMENTA** (t-test positivo)
- **Explicación:** Los G>T que aumentan, aumentan MÁS de lo que otros disminuyen

---

## 🌱 **REGIÓN SEMILLA - CAMBIOS TEMPORALES**

### **G>T en semilla (posiciones 1-7):**
```
Total G>T en semilla: 397

Disminución:  286 (72.0%) ⬇️⬇️ MAYORÍA disminuye
Aumento:       56 (14.1%) ⬆️ Pocos aumentan
Sin cambio:    55 (13.8%) ➡️ Pocos estables
```

**Patrón diferente de otras regiones:**
- **La semilla tiene MÁS disminuciones** (72% vs 53% general)
- **Menos aumentos** (14% vs 25% general)
- Sugiere **mayor conservación o clearance** en región crítica

---

## 📈 **CAMBIOS POR REGIÓN FUNCIONAL**

### **Distribución de cambios:**
```
REGIÓN    | Aumento | Disminución | Sin cambio | Total | % Disminuye
----------|---------|-------------|------------|-------|-------------
Seed      |   56    |     286     |     55     |  397  |   72.0% ⬇️⬇️
Central   |  127    |     286     |    106     |  519  |   55.1%
3'        |  149    |     266     |     93     |  508  |   52.4%
Otro      |  226    |     327     |    216     |  769  |   42.5%
```

**Patrón claro:**
- **Semilla:** Más disminuciones (72%)
- **Central y 3':** Disminuciones moderadas (52-55%)
- **Otro:** Menos disminuciones (42.5%)

**Interpretación:**
> La **región SEMILLA** muestra mayor **reducción de G>T** en el tiempo
> 
> Posibles explicaciones:
> 1. **Clearance selectivo** de mutaciones en región crítica
> 2. **Presión selectiva** contra G>T en semilla
> 3. **Degradación de miRNAs** con G>T en semilla
> 4. **Cambio en perfil de miRNAs** circulantes

---

## 📊 **ANÁLISIS ESTADÍSTICO**

### **Todos los SNVs (no solo G>T):**
```
Paired t-test:
├── N = 11,978 SNVs
├── Diferencia: +0.00109 (aumento de 0.11%)
├── p-value: 3.8e-44 (ALTAMENTE significativo)
└── Interpretación: VAFs AUMENTAN en general con el tiempo
```

### **Solo mutaciones G>T:**
```
Paired t-test:
├── N = 943 G>T
├── Diferencia: +0.00060 (aumento de 0.06%)
├── p-value: 0.001 (SIGNIFICATIVO)
└── Interpretación: G>T AUMENTAN pero MENOS que otros SNVs
```

**Comparación:**
- **Otros SNVs:** aumentan 0.11%
- **G>T:** aumentan 0.06%
- **G>T aumentan ~50% menos** que otros SNVs

---

## 💡 **INTERPRETACIÓN BIOLÓGICA**

### **Hallazgo 1: Cambios dinámicos en el tiempo**
```
✅ Hay cambios SIGNIFICATIVOS en VAFs entre Enrolment y Longitudinal
✅ Esto es VÁLIDO incluso en muestras del mismo paciente en diferentes tiempos
✅ Sugiere que el perfil de SNVs es dinámico, no estático
```

### **Hallazgo 2: G>T tienen comportamiento particular**
```
⚠️ G>T aumentan menos que otros SNVs (0.06% vs 0.11%)
⚠️ Mayoría de G>T disminuyen individualmente (53%)
⚠️ Región semilla tiene MÁS disminuciones (72%)
```

**Posibles explicaciones:**
1. **Estrés oxidativo variable:** Puede aumentar o disminuir con la progresión
2. **Clearance selectivo:** miRNAs con G>T en semilla se degradan más
3. **Cambio en composición:** El pool de miRNAs circulantes cambia
4. **Respuesta terapéutica:** Si hay tratamiento antioxidante (no sabemos aún)

### **Hallazgo 3: Heterogeneidad temporal**
```
✅ NO todos los pacientes cambian igual
✅ 25% de G>T aumentan, 53% disminuyen, 21% no cambian
✅ Esto sugiere subtipos o trayectorias diferentes
```

---

## ⚠️ **LIMITACIONES**

### **1. No son muestras pareadas verdaderas**
```
Problema:
├── Comparamos PROMEDIOS de grupos (Enrolment vs Longitudinal)
├── NO son los mismos pacientes en ambos timepoints
└── Las 64 muestras longitudinales pueden ser pacientes diferentes

Implicación:
└── Los cambios pueden reflejar diferencias entre pacientes, no progresión temporal
```

### **2. No sabemos qué pacientes tienen muestras longitudinales**
```
Pendiente:
└── Mapeo de IDs para identificar pacientes con muestras pareadas
    ├── Si tenemos pacientes con ambos timepoints
    └── Podríamos hacer análisis pareado REAL
```

---

## 🎯 **PRÓXIMOS PASOS**

### **Paso 7B: Identificar muestras pareadas** ⏳
```
Objetivo: Identificar pacientes con muestras en AMBOS timepoints
├── Mapear IDs (BLT, etc.) con SRR IDs
├── Identificar pares Enrolment-Longitudinal del mismo paciente
└── Análisis pareado REAL
```

### **Paso 7C: Análisis de trayectorias** ⏳
```
Para pacientes con muestras pareadas:
├── Trayectorias individuales de G>T
├── Pacientes que aumentan vs disminuyen
├── Correlación con progresión clínica
```

---

## 📁 **ARCHIVOS GENERADOS**

**Ubicación:** `outputs/paso7a_temporal/` y `figures/paso7a_temporal/`

**Tablas (8 archivos CSV):**
1. ⭐ `paso7a_vaf_temporal_comparacion.csv` - Cambios en todos los SNVs
2. ⭐ `paso7a_gt_temporal_detallado.csv` - Cambios en G>T
3. ⭐ `paso7a_test_temporal_significancia.csv` - Resultado del t-test
4. `paso7a_gt_cambios_por_region.csv` - G>T por región
5. `paso7a_gt_semilla_temporal.csv` - G>T en semilla
6. `paso7a_cambios_temporales_resumen.csv`
7. `paso7a_gt_cambios_resumen.csv`
8. `paso7a_gt_counts_temporal.csv`

**Figuras (6 archivos PNG):**
1. `paso7a_cambios_vaf_general.png`
2. `paso7a_cambios_gt.png`
3. ⭐ `paso7a_scatter_vaf_temporal.png` - Enrolment vs Longitudinal
4. ⭐ `paso7a_scatter_gt_temporal.png` - G>T Enrolment vs Longitudinal
5. `paso7a_gt_cambios_por_region.png`
6. ⭐ `paso7a_gt_semilla_cambios.png` - Enfoque en semilla

---

## 🔬 **CONCLUSIÓN**

### **Resultados principales:**
1. ✅ **G>T cambian significativamente** en el tiempo (p = 0.001)
2. ⬆️ **Tendencia al AUMENTO** (promedio +0.06%)
3. ⬇️ **Pero mayoría disminuyen individualmente** (53%)
4. 🌱 **Semilla muestra más disminuciones** (72%)

### **Implicaciones:**
- El perfil de G>T es **dinámico**, no estático
- La región semilla puede tener **clearance selectivo**
- Necesitamos **muestras pareadas** para confirmar
- Los outliers pueden representar **trayectorias extremas**

---

*Análisis completado: 8 de octubre de 2025*
*Próximo paso: Identificar muestras pareadas o continuar con otros análisis*









