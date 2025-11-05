# 📋 PLAN: FDR-Controlled Positional Tests Export

## 🎯 OBJETIVO

Exportar tabla completa de tests estadísticos por posición con:
- Tests múltiples (Wilcoxon, t-test)
- Corrección FDR
- Efecto tamaño (Cohen's d)
- Resultados claros y exportables a CSV

---

## 📊 PASO 1: QUÉ YA EXISTE

✅ El script `generate_FIG_2.6_POSITIONAL.R` YA hace:
- Tests Wilcoxon por posición (líneas 93-116)
- Corrección FDR (línea 120)
- Calcula significancia (línea 121)

❌ LO QUE FALTA:
- Exportar tabla de resultados a CSV
- Incluir más tests (t-test)
- Calcular efecto tamaño (Cohen's d)
- Incluir estadísticas descriptivas completas
- Tabla formateada para publicación

---

## 🔧 PASO 2: QUÉ VAMOS A AGREGAR

### A. Mejorar los tests estadísticos:

1. **Wilcoxon test** (ya existe) ✅
2. **T-test** (agregar) ➕
3. **Cohen's d** (efecto tamaño) ➕
4. **Estadísticas descriptivas** (mejorar) ➕

### B. Tabla de resultados completa:

```
Columna          | Descripción
-----------------|------------------------------------------
position         | Posición en miRNA (1-23)
mean_ALS         | Media VAF en ALS
mean_Control     | Media VAF en Control
median_ALS       | Mediana VAF en ALS
median_Control   | Mediana VAF en Control
sd_ALS           | Desviación estándar ALS
sd_Control       | Desviación estándar Control
n_ALS            | Número de muestras ALS
n_Control        | Número de muestras Control
wilcoxon_p       | P-value Wilcoxon (sin corregir)
t_test_p         | P-value t-test (sin corregir)
cohens_d         | Efecto tamaño (Cohen's d)
wilcoxon_padj    | P-value Wilcoxon (FDR corregido)
t_test_padj      | P-value t-test (FDR corregido)
wilcoxon_sig     | Significativo? (padj < 0.05) ★/ns
t_test_sig       | Significativo? (padj < 0.05) ★/ns
effect_direction | Control > ALS o ALS > Control
```

### C. Exportar 2 archivos:

1. `TABLE_2.6_positional_tests_COMPLETE.csv` (tabla completa)
2. `TABLE_2.6_positional_tests_SIGNIFICANT.csv` (solo significativos)

---

## 📝 PASO 3: IMPLEMENTACIÓN

**Archivo a modificar:**
- `generate_FIG_2.6_POSITIONAL.R`

**Cambios:**
1. Agregar cálculo de t-test (línea ~115)
2. Agregar cálculo de Cohen's d (línea ~120)
3. Expandir tabla con todas las columnas (línea ~125)
4. Agregar exportación a CSV (después de línea 125)
5. Mostrar resumen en consola (línea ~126)

**NO cambiar:**
- La generación de la figura (sigue igual)
- El formato de la figura (sigue igual)

---

## ✅ PASO 4: VALIDACIÓN

Después de implementar, verificar:
- [ ] Tabla CSV generada
- [ ] Todas las columnas presentes
- [ ] FDR correcto (23 posiciones = 23 tests)
- [ ] Números razonables
- [ ] Figura no afectada

---

## 🚀 RESULTADO ESPERADO

```
📁 figures_paso2_CLEAN/
   ├── FIG_2.6_POSITIONAL_ANALYSIS.png  (ya existe)
   ├── TABLE_2.6_positional_tests_COMPL新人.csv  (NUEVO)
   └── TABLE_2.6_positional_tests_SIGNIFICANT.csv  (NUEVO)
```

---

**¿Procedemos con la implementación?** 🎯

