# 🔧 GUÍA DE ACTUALIZACIÓN Y MANTENIMIENTO - PIPELINE_2

## 📋 **PROPÓSITO**
Esta guía explica cómo actualizar, editar y mantener el pipeline_2 de manera organizada y con registro completo de cambios.

---

## 🚀 **FLUJO DE TRABAJO PARA CAMBIOS**

### **Paso 1: Identificar el cambio necesario**
1. ¿Qué necesita cambiarse?
2. ¿Por qué es necesario el cambio?
3. ¿Qué impacto tendrá?

### **Paso 2: Documentar ANTES de hacer cambios**
1. Abrir `CHANGELOG.md` y crear nueva entrada
2. Abrir `DESIGN_DECISIONS.md` si es una decisión importante
3. Anotar versión actual y cambio planeado

### **Paso 3: Realizar el cambio**
1. Hacer modificaciones en archivos correspondientes
2. Probar cambios
3. Verificar que no rompe funcionalidad existente

### **Paso 4: Documentar DESPUÉS del cambio**
1. Completar entrada en `CHANGELOG.md`
2. Actualizar `FIGURE_LAYOUTS.md` si afecta visualizaciones
3. Actualizar `README.md` si cambia estructura general

### **Paso 5: Versionar**
1. Incrementar número de versión según severidad:
   - **Major (X.0.0)**: Cambios que rompen compatibilidad
   - **Minor (0.X.0)**: Nuevas funcionalidades
   - **Patch (0.0.X)**: Correcciones de bugs

---

## 📝 **CÓMO ACTUALIZAR CADA TIPO DE COMPONENTE**

### **1. Agregar nuevo panel a figura existente**

#### **Ejemplo: Agregar Panel E a Figura 1**

**Archivos a modificar:**
- `functions/visualization_functions.R`
- `FIGURE_LAYOUTS.md`
- `CHANGELOG.md`

**Pasos:**

1. **Crear función del panel:**
```r
# En visualization_functions.R
create_panel_e_nuevo <- function(data) {
  # Código del nuevo panel
  p <- ggplot(data, aes(...)) + ...
  return(p)
}
```

2. **Modificar función wrapper:**
```r
# Modificar create_figure_1_dataset_characterization()
create_figure_1_dataset_characterization <- function(data, output_dir) {
  panel_a <- create_dataset_evolution_panel(...)
  panel_b <- create_positional_heatmap_panel(...)
  panel_c <- create_mutation_types_panel(...)
  panel_d <- create_top_mirnas_panel(...)
  panel_e <- create_panel_e_nuevo(...)  # NUEVO
  
  # Cambiar layout de 2x2 a 2x3 o 3x2
  figure_1 <- (panel_a | panel_b | panel_c) / (panel_d | panel_e)
  
  # ... resto del código
}
```

3. **Documentar en FIGURE_LAYOUTS.md:**
```markdown
### **Panel E: [Título del Panel]**
- **Tipo:** [Tipo de gráfica]
- **Ejes:**
  - X: [Descripción]
  - Y: [Descripción]
- **Información mostrada:**
  - [Info 1]
  - [Info 2]
- **Pregunta respondida:** "[Pregunta]"
```

4. **Actualizar CHANGELOG.md:**
```markdown
### [Versión 0.2.0] - YYYY-MM-DD

#### ✅ Agregado
- **Figura 1 Panel E**: [Descripción]
  - Responde pregunta: "[Pregunta]"
  - Ubicación: `visualization_functions.R:123`
```

---

### **2. Modificar parámetro de visualización**

#### **Ejemplo: Cambiar paleta de colores**

**Archivos a modificar:**
- `config/config_pipeline_2.R`
- `CHANGELOG.md`
- `DESIGN_DECISIONS.md`

**Pasos:**

1. **Modificar config:**
```r
# En config_pipeline_2.R
viz_params <- list(
  color_palette = "viridis"  # ANTES: "plasma"
)
```

2. **Documentar decisión:**
```markdown
# En DESIGN_DECISIONS.md
### **DV-XXX: Cambio de Paleta a Viridis**
- **Fecha:** YYYY-MM-DD
- **Decisión:** Cambiar de plasma a viridis
- **Justificación:**
  - Mejor contraste
  - Más colorblind-friendly
- **Impacto:** Todas las figuras continuas
```

3. **Actualizar CHANGELOG:**
```markdown
### [Versión 0.1.1] - YYYY-MM-DD

#### 🔧 Modificado
- **Paleta de colores**: Cambiada de plasma a viridis
  - Razón: Mejor contraste y accesibilidad
  - Archivos afectados: visualization_functions.R (todas las funciones)
```

---

### **3. Agregar nueva figura completa**

#### **Ejemplo: Crear Figura 4 (Análisis Temporal)**

**Archivos a modificar:**
- `functions/visualization_functions.R`
- `FIGURE_LAYOUTS.md`
- `run_pipeline_2.R`
- `CHANGELOG.md`

**Pasos:**

1. **Diseñar layout en FIGURE_LAYOUTS.md primero:**
```markdown
## 📊 **FIGURA 4: ANÁLISIS TEMPORAL**

### **Layout: 2x2 Grid (16" x 12")**

### **Panel A: [Descripción]**
[Detalles completos]

### **Panel B: [Descripción]**
[Detalles completos]

[... etc ...]
```

2. **Crear funciones en visualization_functions.R:**
```r
### **Panel A: [Título]**
create_temporal_panel_a <- function(data) {
  # Código
}

### **Función Principal: Crear Figura 4 Completa**
create_figure_4_temporal <- function(data, output_dir) {
  panel_a <- create_temporal_panel_a(...)
  # ... más paneles ...
  
  figure_4 <- (panel_a | panel_b) / (panel_c | panel_d)
  
  ggsave(file.path(output_dir, "figura_4_temporal.png"), 
         figure_4, width = 16, height = 12, dpi = 300)
  
  return(figure_4)
}
```

3. **Agregar al script principal:**
```r
# En run_pipeline_2.R
## 🎨 CREAR FIGURA 4: ANÁLISIS TEMPORAL
cat("🎨 Creando Figura 4: Análisis Temporal\n")
figure_4 <- create_figure_4_temporal(processed_data, figures_dir)
```

4. **Documentar:**
```markdown
### [Versión 0.3.0] - YYYY-MM-DD

#### ✅ Agregado
- **Figura 4: Análisis Temporal**
  - Panel A: Evolución de VAFs
  - Panel B: Progresión de síntomas
  - Panel C: Clustering temporal
  - Panel D: Predicción
  - Responde: "¿Cómo evolucionan las mutaciones?"
```

---

### **4. Cambiar test estadístico**

#### **Ejemplo: De Wilcoxon a t-test**

**Archivos a modificar:**
- `functions/statistical_functions.R`
- `DESIGN_DECISIONS.md`
- `CHANGELOG.md`

**Pasos:**

1. **Modificar función estadística:**
```r
# En statistical_functions.R
compare_groups_statistical <- function(data, group_col) {
  # ANTES: test_result <- wilcox.test(...)
  # DESPUÉS:
  test_result <- t.test(data ~ group, data = data)
  # ... resto del código
}
```

2. **Documentar razón:**
```markdown
# En DESIGN_DECISIONS.md
### **DN-004: Cambio a Test Paramétrico**
- **Fecha:** YYYY-MM-DD
- **Decisión:** Usar t-test en lugar de Wilcoxon
- **Justificación:**
  - Datos verificados como normales (Shapiro-Wilk: p=0.3)
  - Mayor poder estadístico
  - Mejores IC paramétricos
- **Impacto:** Figura 2 Panel B/C
- **Crítica:** Menos robusto a outliers
```

3. **Actualizar CHANGELOG:**
```markdown
### [Versión 0.4.0] - YYYY-MM-DD

#### 🔧 Modificado
- **Test estadístico**: Wilcoxon → t-test
  - Razón: Datos normales confirmados
  - Impacto: p-valores pueden cambiar ligeramente
  - Archivos: statistical_functions.R:45
```

---

## 🔄 **ESQUEMA DE VERSIONADO**

### **Semántico: MAJOR.MINOR.PATCH**

#### **MAJOR (X.0.0) - Cambios incompatibles**
Incrementar cuando:
- Cambias estructura de datos de entrada
- Eliminas funciones principales
- Cambias nombres de archivos de salida
- Cambias significativamente metodología

**Ejemplo:**
```
v0.5.0 → v1.0.0
Cambio: Estructura de tasks.json modificada (incompatible con v0.x)
```

#### **MINOR (0.X.0) - Nuevas funcionalidades**
Incrementar cuando:
- Agregas nuevas figuras
- Agregas nuevos paneles
- Agregas nuevas funciones estadísticas
- Mejoras significativas (compatible)

**Ejemplo:**
```
v0.3.0 → v0.4.0
Cambio: Agregada Figura 4 (Análisis Temporal)
```

#### **PATCH (0.0.X) - Correcciones**
Incrementar cuando:
- Corriges bugs
- Mejoras documentación
- Optimizas código existente
- Cambios cosméticos

**Ejemplo:**
```
v0.3.2 → v0.3.3
Cambio: Corregido bug en cálculo de p-valores
```

---

## 📁 **ESTRUCTURA DE ARCHIVOS Y QUÉ MODIFICAR**

### **config/**
- `config_pipeline_2.R` - Parámetros técnicos (rutas, dimensiones)
- `parameters.R` - Preguntas científicas, layouts

**Cuándo modificar:**
- Cambiar rutas de datos
- Ajustar parámetros de visualización
- Modificar umbrales estadísticos

### **functions/**
- `visualization_functions.R` - Funciones de gráficas
- `statistical_functions.R` - Funciones estadísticas (futuro)
- `functions_pipeline_2.R` - Funciones generales (futuro)

**Cuándo modificar:**
- Agregar/modificar paneles
- Cambiar tests estadísticos
- Agregar nuevos análisis

### **Documentación/**
- `README.md` - Visión general
- `CHANGELOG.md` - Historial de cambios
- `FIGURE_LAYOUTS.md` - Diseño de figuras
- `DESIGN_DECISIONS.md` - Decisiones importantes
- `MAINTENANCE_GUIDE.md` - Esta guía

**Cuándo modificar:**
- **CHANGELOG**: Cada cambio
- **FIGURE_LAYOUTS**: Cambios en visualizaciones
- **DESIGN_DECISIONS**: Decisiones importantes
- **README**: Cambios estructurales

---

## ✅ **CHECKLIST PRE-CAMBIO**

Antes de hacer cualquier cambio:

- [ ] ¿Entiendo completamente qué voy a cambiar?
- [ ] ¿He documentado el estado actual?
- [ ] ¿He identificado todos los archivos afectados?
- [ ] ¿He determinado la nueva versión?
- [ ] ¿Tengo backup del código actual?

## ✅ **CHECKLIST POST-CAMBIO**

Después de hacer un cambio:

- [ ] ¿El cambio funciona como esperado?
- [ ] ¿He actualizado CHANGELOG.md?
- [ ] ¿He actualizado documentación relevante?
- [ ] ¿He probado que no rompe funcionalidad existente?
- [ ] ¿He incrementado el número de versión?
- [ ] ¿He documentado la justificación (si aplica)?

---

## 🐛 **DEBUGGING WORKFLOW**

### **Si algo no funciona:**

1. **Identificar el error:**
   - ¿Qué mensaje de error aparece?
   - ¿En qué función/línea?
   - ¿Con qué datos?

2. **Revisar cambios recientes:**
   - Consultar CHANGELOG.md
   - ¿Qué se modificó desde la última versión funcional?

3. **Aislar el problema:**
   - Probar funciones individualmente
   - Verificar entrada/salida de cada paso

4. **Documentar la solución:**
   - Agregar entrada en CHANGELOG (Corregido)
   - Si es un bug recurrente, agregar a DESIGN_DECISIONS

---

## 📊 **EJEMPLO COMPLETO: CAMBIO DE PRINCIPIO A FIN**

### **Escenario: Agregar subpanel de significancia a Figura 1C**

#### **1. Planificación**
```
¿Qué?: Agregar asteriscos de significancia en barras apiladas
¿Por qué?: Mostrar cuáles posiciones tienen dominancia significativa de G>T
¿Impacto?: Figura 1 Panel C, función create_mutation_types_panel()
Versión: 0.1.0 → 0.1.1 (PATCH, no agrega funcionalidad nueva)
```

#### **2. Documentación PRE-cambio**
```markdown
# CHANGELOG.md
### [Versión 0.1.1] - 2025-01-17

#### 🔧 Modificado (en progreso)
- **Figura 1 Panel C**: Agregando significancia estadística
  - Test: Chi-cuadrado por posición
  - Anotación: Asteriscos (***, **, *)
```

#### **3. Implementación**
```r
# En visualization_functions.R
create_mutation_types_panel <- function(data) {
  # ... código existente ...
  
  # NUEVO: Calcular significancia
  signif_by_position <- mutation_fractions %>%
    group_by(position) %>%
    do(chisq = chisq.test(.$count)) %>%
    mutate(p_value = chisq$p.value,
           signif = case_when(
             p_value < 0.001 ~ "***",
             p_value < 0.01 ~ "**",
             p_value < 0.05 ~ "*",
             TRUE ~ ""
           ))
  
  # MODIFICADO: Agregar anotaciones
  p <- ggplot(...) +
    geom_col(...) +
    geom_text(data = signif_by_position,
              aes(x = position, y = 1.05, label = signif),
              size = 5) +  # NUEVO
    # ... resto del código
}
```

#### **4. Pruebas**
```r
# Probar función individualmente
test_data <- load_data()
panel_c <- create_mutation_types_panel(test_data)
print(panel_c)  # Verificar que se vea bien
```

#### **5. Documentación POST-cambio**
```markdown
# CHANGELOG.md
### [Versión 0.1.1] - 2025-01-17

#### 🔧 Modificado
- **Figura 1 Panel C**: Agregada significancia estadística
  - Test: Chi-cuadrado por posición
  - Anotación: Asteriscos (***: p<0.001, **: p<0.01, *: p<0.05)
  - Ubicación: visualization_functions.R:78-95
  - Impacto: Ayuda identificar posiciones con G>T dominante significativo

# DESIGN_DECISIONS.md
### **DV-006: Anotaciones de Significancia en Barras**
- **Fecha:** 2025-01-17
- **Decisión:** Agregar asteriscos de significancia en Panel C
- **Justificación:**
  - Muestra claramente qué posiciones tienen diferencia significativa
  - Estándar en visualizaciones científicas
- **Impacto:** Figura 1 Panel C
```

---

## 🚀 **COMANDOS ÚTILES**

### **Ver historial de cambios:**
```bash
cat CHANGELOG.md | grep "Versión"
```

### **Buscar decisiones sobre tema específico:**
```bash
grep -n "paleta\|color" DESIGN_DECISIONS.md
```

### **Ver última versión:**
```bash
head -20 CHANGELOG.md
```

### **Contar funciones en visualization_functions.R:**
```bash
grep "^[a-z_].*<- function" functions/visualization_functions.R | wc -l
```

---

## 📞 **CONTACTO Y SOPORTE**

Si tienes dudas sobre cómo actualizar algo:

1. Revisa esta guía primero
2. Consulta FIGURE_LAYOUTS.md para diseño
3. Consulta DESIGN_DECISIONS.md para justificaciones
4. Si aún hay dudas, documenta la pregunta en DESIGN_DECISIONS.md como "Decisión Pendiente"

