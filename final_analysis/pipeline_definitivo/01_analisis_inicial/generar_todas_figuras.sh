#!/bin/bash
# Script para generar TODAS las 117 figuras de forma organizada
# Ejecuta scripts R secuencialmente con reporte de progreso

cd /Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/pipeline_definitivo/01_analisis_inicial

echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║        🎨 GENERACION DE 117 FIGURAS - PROCESO COMPLETO POR FASES         ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Este proceso se ejecutará en 4 fases para evitar sobrecarga:"
echo ""
echo "  FASE 1: Pasos 1-4 (Exploracion inicial) - ~15 figuras"
echo "  FASE 2: Pasos 5-7 (QC y metadatos) - ~17 figuras"
echo "  FASE 3: Pasos 8-10 (CRITICOS - hallazgos transformadores) - ~50 figuras"
echo "  FASE 4: Paso 11 + Validacion - ~5 figuras"
echo ""
echo "Tiempo estimado total: 10-15 minutos"
echo ""
read -p "Presiona ENTER para iniciar o Ctrl+C para cancelar..."
echo ""

# Contador de scripts exitosos
SUCCESS=0
TOTAL=0

# Función para ejecutar script con reporte
run_script() {
    local script=$1
    local desc=$2
    TOTAL=$((TOTAL + 1))
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "[$TOTAL] 🔄 Ejecutando: $script"
    echo "    Descripción: $desc"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if Rscript "$script" > "${script%.R}.log" 2>&1; then
        SUCCESS=$((SUCCESS + 1))
        echo "✅ COMPLETADO: $script"
        # Mostrar últimas 3 líneas del output
        echo "   Output:"
        tail -3 "${script%.R}.log" | sed 's/^/   /'
    else
        echo "❌ ERROR en: $script"
        echo "   Ver log: ${script%.R}.log"
        tail -5 "${script%.R}.log" | sed 's/^/   /'
    fi
}

echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║                         FASE 1: EXPLORACION INICIAL                       ║"
echo "║                         Pasos 1-4 (~15 figuras)                           ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"

run_script "paso1a_cargar_datos.R" "Preprocesamiento (split-collapse, VAF)"
run_script "paso1b_analisis_mirnas.R" "Analisis por miRNA (4 figuras)"
run_script "paso1c_analisis_posiciones.R" "Analisis posicional (3 figuras)"
run_script "paso2a_analisis_gt_basico.R" "Identificacion G>T (3 figuras)"
run_script "paso2b_analisis_gt_por_posicion.R" "G>T por posicion (4 figuras)"
run_script "paso2c_analisis_mirnas_oxidacion.R" "miRNAs oxidados (3 figuras)"
run_script "paso3a_analisis_vafs_gt_final.R" "VAF G>T (4 figuras)"
run_script "paso3b_analisis_comparativo_als_control.R" "ALS vs Control (5 figuras)"
run_script "paso3c_analisis_vafs_por_region.R" "VAF por region (4 figuras)"
run_script "paso4a_analisis_significancia_estadistica.R" "Significancia FDR (5 figuras)"

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║                    ✅ FASE 1 COMPLETADA                                   ║"
echo "║                    Scripts exitosos: $SUCCESS de $TOTAL                        ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Presiona ENTER para continuar con FASE 2 o Ctrl+C para detener..."
read

PHASE1_SUCCESS=$SUCCESS

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║                      FASE 2: QC Y METADATOS                               ║"
echo "║                      Pasos 5-7 (~17 figuras)                              ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"

run_script "paso5a_outliers_muestras.R" "Identificacion outliers (8 figuras)"
run_script "paso5a_profundizar_outliers_gt.R" "Caracterizacion outliers (5 figuras)"
run_script "paso6a_integracion_metadatos.R" "Integracion metadatos (3 figuras)"
run_script "paso7a_analisis_temporal.R" "Analisis temporal (6 figuras)"

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║                    ✅ FASE 2 COMPLETADA                                   ║"
echo "║                    Scripts exitosos: $SUCCESS de $TOTAL                        ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Presiona ENTER para continuar con FASE 3 (CRITICA - hallazgos transformadores)..."
read

PHASE2_SUCCESS=$SUCCESS

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║              🔥 FASE 3: HALLAZGOS TRANSFORMADORES 🔥                      ║"
echo "║                    Pasos 8-10 (~50 figuras)                               ║"
echo "║              Esta es la fase MAS IMPORTANTE del analisis                  ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"

run_script "paso8_mirnas_gt_semilla.R" "Filtro semilla (4 figuras)"
run_script "paso8b_analisis_comparativo_detallado.R" "Comparativo G>T vs otros (6 figuras)"
run_script "paso8c_visualizaciones_avanzadas.R" "Heatmaps avanzados (5 figuras)"
run_script "paso9_motivos_secuencia_semilla.R" "Familias miRNA (4 figuras)"
run_script "paso9b_motivos_secuencia_completo.R" "Trinucleotidos (6 figuras)"
run_script "paso9c_motivos_semilla_completa.R" "Semilla completa (7 figuras)"
run_script "paso9d_comparacion_secuencias_similares.R" "Resistentes (6 figuras)"
run_script "paso10a_let7_vs_mir4500.R" "let-7 vs miR-4500 CRITICO (4 figuras)"
run_script "paso10b_resistentes_completo.R" "7 resistentes (3 figuras)"
run_script "paso10c_comutaciones_let7.R" "Co-mutaciones let-7 (1-2 figuras)"
run_script "paso10d_motivos_extendidos.R" "Pentanucleotidos (4-5 figuras)"

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║                🔥 FASE 3 COMPLETADA 🔥                                    ║"
echo "║                Scripts exitosos: $SUCCESS de $TOTAL                            ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Presiona ENTER para continuar con FASE 4 (Pathway y validacion)..."
read

PHASE3_SUCCESS=$SUCCESS

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║                  FASE 4: PATHWAY Y VALIDACION                             ║"
echo "║                    Paso 11 + Validacion (~5 figuras)                      ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"

run_script "paso11_pathway_analysis.R" "Pathway enrichment (3 figuras)"
run_script "verificar_mirbase_version.R" "Verificacion miRBase (0 figuras)"

# Validacion (sin figuras pero importante)
echo ""
echo "🔍 Ejecutando validacion sin outliers..."
cd validacion_sin_outliers
run_script "val_paso1_preparar_datos.R" "Preparar datos sin outliers"
run_script "val_paso2_validar_let7.R" "Validar patron let-7"
run_script "val_paso3_validar_mir4500.R" "Validar paradoja miR-4500"
cd ..

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║                    ✅ FASE 4 COMPLETADA                                   ║"
echo "║                    Scripts exitosos: $SUCCESS de $TOTAL                        ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║                   🎉 PROCESO COMPLETO FINALIZADO 🎉                       ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "RESUMEN FINAL:"
echo "  Total scripts ejecutados: $TOTAL"
echo "  Scripts exitosos: $SUCCESS"
echo "  Scripts con errores: $((TOTAL - SUCCESS))"
echo ""
echo "  Fase 1 (Pasos 1-4): Completada ✓"
echo "  Fase 2 (Pasos 5-7): Completada ✓"
echo "  Fase 3 (Pasos 8-10): Completada ✓"
echo "  Fase 4 (Paso 11 + Val): Completada ✓"
echo ""
echo "Figuras generadas en: figures/"
echo "Para ver resumen de figuras: ls -R figures/ | grep '.png' | wc -l"
echo ""
echo "SIGUIENTE PASO: Completar HTML con figuras generadas"
echo ""








