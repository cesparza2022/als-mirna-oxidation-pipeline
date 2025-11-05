#!/usr/bin/env Rscript
# =============================================================================
# DIAGRAMA DE FLUJO DEL PIPELINE
# =============================================================================

library(DiagrammeR)

cat("Creating pipeline flowchart...\n")

# Crear diagrama
pipeline_diagram <- grViz("
digraph pipeline {
  
  # Graph attributes
  graph [rankdir = TB, fontsize = 12, fontname = 'Arial']
  node [shape = box, style = 'filled,rounded', fontname = 'Arial']
  edge [fontname = 'Arial', fontsize = 10]
  
  # Input
  input [label = 'INPUT\\nmiRNA_count.Q33.txt\\n(Raw counts)', fillcolor = '#E8F5E9', shape = folder]
  meta1 [label = 'METADATA\\nSample info\\nClinical data', fillcolor = '#E3F2FD', shape = folder]
  
  # FASE 1: Preprocessing
  subgraph cluster_0 {
    label = 'PHASE 1: Preprocessing'
    style = filled
    fillcolor = '#FFF3E0'
    
    step1 [label = '1. Split-Collapse\\n(miRNA+pos+mut per row)', fillcolor = '#FFECB3']
    step2 [label = '2. Calculate VAFs\\n(Count / Total × 100)', fillcolor = '#FFECB3']
    step3 [label = '3. Filter VAFs\\n(Remove > 50%)', fillcolor = '#FFECB3']
  }
  
  # FASE 2: Metadata
  subgraph cluster_1 {
    label = 'PHASE 2: Metadata Integration'
    style = filled
    fillcolor = '#E1F5FE'
    
    step4 [label = '4. Map Sample IDs', fillcolor = '#B3E5FC']
    step5 [label = '5. Integrate Clinical', fillcolor = '#B3E5FC']
    step6 [label = '6. Identify Longitudinal', fillcolor = '#B3E5FC']
  }
  
  # FASE 3: QC
  subgraph cluster_2 {
    label = 'PHASE 3: Quality Control'
    style = filled
    fillcolor = '#FCE4EC'
    
    step7 [label = '7. Outlier Detection\\n(PCA, distributions)', fillcolor = '#F8BBD0']
    step8 [label = '8. Batch Assessment', fillcolor = '#F8BBD0']
    step9 [label = '9. Sample QC Metrics', fillcolor = '#F8BBD0']
  }
  
  # FASE 4: Core Analysis
  subgraph cluster_3 {
    label = 'PHASE 4: Core Analysis'
    style = filled
    fillcolor = '#F3E5F5'
    
    step10 [label = '10. G>T Mutations\\n(Oxidation signature)', fillcolor = '#E1BEE7']
    step11 [label = '11. Seed Region\\n(Positions 2-8)', fillcolor = '#E1BEE7']
    step12 [label = '12. Positional Patterns', fillcolor = '#E1BEE7']
    step13 [label = '13. Statistical Tests\\n(ALS vs Control)', fillcolor = '#E1BEE7']
  }
  
  # FASE 5: Sequence
  subgraph cluster_4 {
    label = 'PHASE 5: Sequence Analysis'
    style = filled
    fillcolor = '#E8F5E9'
    
    step14 [label = '14. Motif Discovery', fillcolor = '#C8E6C9']
    step15 [label = '15. Sequence Logos', fillcolor = '#C8E6C9']
    step16 [label = '16. Family Clustering', fillcolor = '#C8E6C9']
  }
  
  # FASE 6: Functional
  subgraph cluster_5 {
    label = 'PHASE 6: Functional Analysis'
    style = filled
    fillcolor = '#FFF9C4'
    
    step17 [label = '17. Pathway Enrichment', fillcolor = '#FFF59D']
    step18 [label = '18. Target Genes', fillcolor = '#FFF59D']
  }
  
  # FASE 7: Temporal (opcional)
  subgraph cluster_6 {
    label = 'PHASE 7: Temporal (optional)'
    style = filled
    fillcolor = '#E0F2F1'
    
    step19 [label = '19. Pairwise Comparison\\n(enrollment vs follow-up)', fillcolor = '#B2DFDB']
    step20 [label = '20. Progression Patterns', fillcolor = '#B2DFDB']
  }
  
  # Output
  output [label = 'OUTPUT\\nHTML Report\\nFigures\\nTables', fillcolor = '#C5CAE9', shape = folder]
  
  # Connections - PHASE 1
  input -> step1
  step1 -> step2
  step2 -> step3
  
  # PHASE 2
  meta1 -> step4
  step3 -> step4
  step4 -> step5
  step5 -> step6
  
  # PHASE 3
  step6 -> step7
  step7 -> step8
  step8 -> step9
  
  # PHASE 4
  step9 -> step10
  step10 -> step11
  step11 -> step12
  step12 -> step13
  
  # PHASE 5
  step13 -> step14
  step14 -> step15
  step15 -> step16
  
  # PHASE 6
  step16 -> step17
  step17 -> step18
  
  # PHASE 7 (optional)
  step6 -> step19 [style = dashed, label = 'if longitudinal']
  step19 -> step20 [style = dashed]
  
  # Final
  step18 -> output
  step20 -> output [style = dashed]
}
")

# Guardar
cat("Saving pipeline diagram...\n")

# Como HTML interactivo
htmlwidgets::saveWidget(pipeline_diagram, "pipeline_diagram.html", selfcontained = TRUE)

# Como PNG (requiere webshot2)
if (requireNamespace("webshot2", quietly = TRUE)) {
  webshot2::webshot("pipeline_diagram.html", "pipeline_diagram.png", 
                    vwidth = 1200, vheight = 1800)
  cat("✅ Diagram saved as PNG\n")
}

cat("✅ Pipeline diagram created:\n")
cat("   - pipeline_diagram.html (interactive)\n")
if (file.exists("pipeline_diagram.png")) {
  cat("   - pipeline_diagram.png\n")
}
cat("\n")








