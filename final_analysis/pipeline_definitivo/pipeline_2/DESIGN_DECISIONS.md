# 🎨 DECISIONES DE DISEÑO - PIPELINE_2

## 📋 **PROPÓSITO DE ESTE DOCUMENTO**
Registrar todas las decisiones de diseño importantes para:
1. **Justificar** elecciones metodológicas
2. **Documentar** cambios respecto al pipeline original
3. **Facilitar** modificaciones futuras
4. **Mantener** coherencia científica

---

## 🔬 **DECISIONES CIENTÍFICAS**

### **DS-001: Enfoque en Mutaciones G>T Exclusivamente**
- **Fecha:** 2025-01-16
- **Decisión:** Priorizar análisis de mutaciones G>T sobre otros tipos
- **Justificación:**
  - G>T es el marcador primario de estrés oxidativo (8-oxoguanina)
  - Paper de referencia muestra dominancia de G>T en contexto oxidativo
  - Reduce complejidad del análisis inicial
- **Impacto:** Figura 1 Panel B/C, Figura 2 completa
- **Referencias:** 
  - Paper de referencia (imagen proporcionada)
  - Literatura sobre 8-oxoG → mutaciones G>T

### **DS-002: Análisis Posicional (1-22 nucleótidos)**
- **Fecha:** 2025-01-16
- **Decisión:** Limitar análisis a posiciones 1-22 de miRNAs
- **Justificación:**
  - Región funcional más importante (seed: 2-8)
  - Mayoría de miRNAs tiene longitud ~22nt
  - Datos más confiables en región 5' (mejor cobertura)
- **Impacto:** Todos los análisis posicionales
- **Limitaciones:** Pierde información de miRNAs más largos (>22nt)

### **DS-003: Región Seed Definida como Posiciones 2-8**
- **Fecha:** 2025-01-16
- **Decisión:** Definir seed region como posiciones 2-8
- **Justificación:**
  - Consenso en literatura de miRNAs
  - Región crítica para reconocimiento de targets
  - Mutaciones aquí tienen mayor impacto funcional
- **Impacto:** Figura 3 Panel A
- **Referencias:** Bartel, D.P. (2009) Cell, miRNA biogenesis

### **DS-004: VAF Threshold = 0.5 (50%)**
- **Fecha:** 2025-01-16
- **Decisión:** Mantener umbral VAF > 0.5 como límite superior
- **Justificación:**
  - VAFs muy altos (>50%) sugieren errores técnicos o contaminación
  - Coherencia con pipeline original
  - Filtro conservador para calidad
- **Impacto:** Todos los análisis de VAFs
- **Crítica:** Arbitrario; podría probarse con otros umbrales (0.6, 0.7)
- **Acción futura:** Análisis de sensibilidad con diferentes umbrales

---

## 📊 **DECISIONES DE VISUALIZACIÓN**

### **DV-001: Multi-panel Layout (2x2)**
- **Fecha:** 2025-01-16
- **Decisión:** Usar layout 2x2 para figuras principales
- **Justificación:**
  - Balance entre información y claridad
  - Estándar en papers de alto impacto
  - Permite comparaciones lado a lado
- **Impacto:** Todas las figuras principales
- **Alternativas consideradas:**
  - 1x4 (descartado: muy horizontal)
  - 3x2 (descartado: demasiado denso)

### **DV-002: Heatmap Posicional Horizontal**
- **Fecha:** 2025-01-16
- **Decisión:** Usar heatmap horizontal (1 fila x 22 columnas)
- **Justificación:**
  - **Inspirado en paper de referencia** (Panel B de imagen)
  - Muestra claramente distribución lineal de posiciones
  - Evita ocupar espacio vertical innecesario
  - Facilita comparación con otras gráficas posicionales
- **Impacto:** Figura 1 Panel B
- **Mejora respecto al original:** 
  - Original: múltiples gráficas de barras por posición (redundante)
  - Nuevo: información más densa y clara

### **DV-003: Barras Apiladas para Tipos de Mutación**
- **Fecha:** 2025-01-16
- **Decisión:** Usar barras apiladas para G→X por posición
- **Justificación:**
  - **Inspirado en paper de referencia** (Panel C de imagen)
  - Muestra fracciones relativas claramente
  - Revela dominancia de G>T visualmente
  - Detecta patrones posicionales
- **Impacto:** Figura 1 Panel C
- **Alternativas consideradas:**
  - Barras lado a lado (descartado: difícil comparar fracciones)
  - Líneas (descartado: menos claro para categorías)

### **DV-004: Paleta de Colores Viridis por Defecto**
- **Fecha:** 2025-01-16
- **Decisión:** Usar paleta Viridis para continuo, Set1/2 para categorías
- **Justificación:**
  - Colorblind-friendly
  - Perceptualmente uniforme
  - Estándar en publicaciones científicas
  - Imprime bien en blanco y negro
- **Impacto:** Todas las figuras
- **Excepciones:**
  - ALS vs Control: RdBu (rojo/azul) por convención
  - Significancia: gradiente rojo para p-valores

### **DV-005: Inclusión de Estadísticas en Paneles**
- **Fecha:** 2025-01-16
- **Decisión:** Incluir p-valores, IC, tamaños de efecto directamente en paneles
- **Justificación:**
  - Transparencia estadística
  - Evita remitir a tablas suplementarias
  - Facilita interpretación
- **Impacto:** Figura 2 (principalmente)
- **Formato:** "p = 0.001 (FDR), d = 0.32"

---

## 🔧 **DECISIONES TÉCNICAS**

### **DT-001: Uso de patchwork para Multi-panel**
- **Fecha:** 2025-01-16
- **Decisión:** Usar paquete `patchwork` para combinar paneles
- **Justificación:**
  - Sintaxis simple y limpia
  - Mejor que `gridExtra` o `cowplot`
  - Control fino de spacing y alineación
- **Impacto:** Todas las funciones de figuras multi-panel
- **Ejemplo:**
  ```r
  (panel_a | panel_b) / (panel_c | panel_d)
  ```

### **DT-002: Dimensiones Estándar 16" x 12"**
- **Fecha:** 2025-01-16
- **Decisión:** Figuras principales 16x12 pulgadas a 300 DPI
- **Justificación:**
  - Tamaño estándar para publicaciones
  - Proporciones 4:3 (balance)
  - 300 DPI = calidad publicación
- **Impacto:** config_pipeline_2.R
- **Tamaño final:** ~4800 x 3600 pixels

### **DT-003: Estructura Modular de Funciones**
- **Fecha:** 2025-01-16
- **Decisión:** Una función por panel + función wrapper
- **Justificación:**
  - Facilita debugging individual
  - Permite reutilización de paneles
  - Testing más fácil
- **Impacto:** visualization_functions.R
- **Patrón:**
  ```r
  create_panel_a() + create_panel_b() + ... 
  → create_figure_1()
  ```

### **DT-004: Sistema de Configuración Centralizado**
- **Fecha:** 2025-01-16
- **Decisión:** Parámetros en config/, no hardcoded
- **Justificación:**
  - Facilita cambios globales
  - Documentación clara de parámetros
  - Reproducibilidad
- **Impacto:** config_pipeline_2.R, parameters.R
- **Beneficio:** Cambiar `vaf_threshold` en un solo lugar

---

## ❌ **DECISIONES DE QUÉ NO HACER**

### **DN-001: No Crear 117 Figuras Individuales**
- **Fecha:** 2025-01-16
- **Decisión:** Reducir de 117 a ~20 figuras complejas
- **Razones:**
  - Redundancia masiva en pipeline original
  - Información duplicada
  - Difícil de mantener
  - No agrega valor científico
- **Impacto:** Arquitectura completa del pipeline_2
- **Eliminado:** Figuras repetitivas de:
  - G>T por región (8 versiones → 1)
  - VAFs por grupo (6 versiones → 1)
  - Top miRNAs (4 versiones → 1)

### **DN-002: No Usar Tests Paramétricos por Defecto**
- **Fecha:** 2025-01-16
- **Decisión:** Preferir tests no-paramétricos (Wilcoxon, Mann-Whitney)
- **Razones:**
  - Datos de VAFs típicamente no-normales
  - Más robusto a outliers
  - No asume distribución específica
- **Impacto:** statistical_functions.R (futuro)
- **Excepción:** Si datos claramente normales (verificar con Shapiro-Wilk)

### **DN-003: No Generar Archivos Markdown Individuales por Tarea**
- **Fecha:** 2025-01-16
- **Decisión:** No usar sistema de tareas del pipeline original
- **Razones:**
  - Overhead innecesario para pipeline_2
  - Más simple mantener scripts R + documentación
  - Enfoque en figuras finales, no pasos intermedios
- **Impacto:** No hay directorio `tasks/`

---

## 🔄 **DECISIONES PENDIENTES (A RESOLVER)**

### **DP-001: Análisis de Confounders**
- **Pregunta:** ¿Incluir análisis de edad, sexo, medicamentos?
- **Opciones:**
  - A) Figura dedicada (Figura 5)
  - B) Panel adicional en Figura 2
  - C) Análisis suplementario (no en figuras principales)
- **Consideraciones:**
  - Depende de disponibilidad de metadata
  - Importante para validez del estudio
- **Decisión:** **Pendiente** - Revisar metadata disponible primero

### **DP-002: Análisis de Pathways**
- **Pregunta:** ¿Qué base de datos usar? (KEGG, Reactome, GO)
- **Opciones:**
  - A) Solo KEGG (más simple)
  - B) Múltiples bases (más completo)
  - C) Análisis manual de targets
- **Consideraciones:**
  - Tiempo de computación
  - Calidad de predicciones
- **Decisión:** **Pendiente** - Empezar con KEGG, expandir si necesario

### **DP-003: Validación Experimental**
- **Pregunta:** ¿Qué evidencia experimental incluir?
- **Opciones:**
  - A) Solo predicciones in silico
  - B) Datos de literatura publicada
  - C) Experimentos propios (si disponibles)
- **Consideraciones:**
  - Disponibilidad de datos
  - Tiempo de búsqueda
- **Decisión:** **Pendiente** - Discutir con el equipo

---

## 📝 **PLANTILLA PARA NUEVAS DECISIONES**

```markdown
### **[CÓDIGO]: [TÍTULO BREVE]**
- **Fecha:** YYYY-MM-DD
- **Decisión:** Qué se decidió hacer/no hacer
- **Justificación:**
  - Razón 1
  - Razón 2
  - Razón 3
- **Impacto:** Qué afecta esta decisión
- **Alternativas consideradas:**
  - Opción A (descartada: razón)
  - Opción B (descartada: razón)
- **Referencias:** Papers/fuentes (si aplica)
- **Crítica/Limitaciones:** Debilidades conocidas
- **Acción futura:** Qué revisar más adelante
```

### **Códigos de categorías:**
- **DS-XXX:** Decisiones Científicas
- **DV-XXX:** Decisiones de Visualización
- **DT-XXX:** Decisiones Técnicas
- **DN-XXX:** Decisiones de NO hacer
- **DP-XXX:** Decisiones Pendientes

