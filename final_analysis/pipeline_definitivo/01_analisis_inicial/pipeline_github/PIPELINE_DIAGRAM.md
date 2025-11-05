# Pipeline Diagram: SNV Analysis in miRNAs for ALS

```
╔═══════════════════════════════════════════════════════════════════════════╗
║                     MIRNA SNV ANALYSIS PIPELINE                           ║
║                  Oxidation Biomarkers in ALS                              ║
╚═══════════════════════════════════════════════════════════════════════════╝

                                  ┌─────────────────────┐
                                  │   INPUT DATA        │
                                  ├─────────────────────┤
                                  │ miRNA_count.Q33.txt │
                                  │ (TSV format)        │
                                  │ ~200K rows          │
                                  └──────────┬──────────┘
                                             │
                         ┌───────────────────┴───────────────────┐
                         │                                       │
                  ┌──────▼──────┐                        ┌──────▼──────┐
                  │  METADATA   │                        │ RAW COUNTS  │
                  ├─────────────┤                        ├─────────────┤
                  │ • Sample    │                        │ • miRNA     │
                  │ • Cohort    │                        │ • Position  │
                  │ • Clinical  │                        │ • Mutation  │
                  │ • Timepoint │                        │ • Samples   │
                  └──────┬──────┘                        └──────┬──────┘
                         │                                       │
                         │              ┌────────────────────────┘
                         │              │
                         │     ┌────────▼────────┐
                         │     │ PHASE 1         │
                         │     │ PREPROCESSING   │
                         │     ├─────────────────┤
                         │     │ 1. Split        │
                         │     │    Collapse     │
                         │     │ 2. Calculate    │
                         │     │    VAFs         │
                         │     │ 3. Filter       │
                         │     │    (VAF>50%→NA) │
                         │     └────────┬────────┘
                         │              │
                         │     ┌────────▼────────┐
                         └────►│ PHASE 2         │
                               │ METADATA INT.   │
                               ├─────────────────┤
                               │ 4. Map IDs      │
                               │ 5. Integrate    │
                               │ 6. Longitudinal │
                               └────────┬────────┘
                                        │
                               ┌────────▼────────┐
                               │ PHASE 3         │
                               │ QUALITY CONTROL │
                               ├─────────────────┤
                               │ 7. Outliers     │
                               │    (PCA)        │
                               │ 8. Batch FX     │
                               │ 9. Metrics      │
                               └────────┬────────┘
                                        │
                               ┌────────▼────────┐
                               │ PHASE 4         │
                               │ CORE ANALYSIS   │
                               ├─────────────────┤
                               │ 10. G>T         │
                               │     Mutations   │
                               │ 11. Seed Region │
                               │     (pos 2-8)   │
                               │ 12. Positional  │
                               │ 13. Statistics  │
                               │     (ALS vs C)  │
                               └────────┬────────┘
                                        │
                         ┌──────────────┴──────────────┐
                         │                             │
                ┌────────▼────────┐           ┌────────▼────────┐
                │ PHASE 5         │           │ PHASE 7         │
                │ SEQUENCE        │           │ TEMPORAL        │
                │ ANALYSIS        │           │ (optional)      │
                ├─────────────────┤           ├─────────────────┤
                │ 14. Motifs      │           │ 19. Pairwise    │
                │ 15. Logos       │           │ 20. Progression │
                │ 16. Families    │           │                 │
                └────────┬────────┘           └────────┬────────┘
                         │                             │
                ┌────────▼────────┐                    │
                │ PHASE 6         │                    │
                │ FUNCTIONAL      │                    │
                ├─────────────────┤                    │
                │ 17. Pathways    │                    │
                │ 18. Targets     │                    │
                └────────┬────────┘                    │
                         │                             │
                         └──────────────┬──────────────┘
                                        │
                               ┌────────▼────────┐
                               │ PHASE 8         │
                               │ REPORTING       │
                               ├─────────────────┤
                               │ • HTML Report   │
                               │ • Figures (117) │
                               │ • Tables        │
                               │ • Statistics    │
                               └────────┬────────┘
                                        │
                               ┌────────▼────────┐
                               │   OUTPUTS       │
                               ├─────────────────┤
                               │ • HTML          │
                               │ • Figures/      │
                               │ • Tables/       │
                               │ • Stats/        │
                               └─────────────────┘
}
")

# Guardar como HTML
htmlwidgets::saveWidget(pipeline_diagram, "pipeline_diagram.html", selfcontained = TRUE)

cat("\n✅ Pipeline diagram created: pipeline_diagram.html\n")
cat("   Open in browser to view interactive diagram\n\n")

# Guardar también como texto
writeLines(c(
  "PIPELINE OVERVIEW",
  "=================",
  "",
  "INPUT → PREPROCESSING → METADATA → QC → CORE ANALYSIS → SEQUENCE/TEMPORAL → FUNCTIONAL → REPORTING",
  "",
  "Phases:",
  "  1. Preprocessing: Split-Collapse, VAF calculation, Filtering",
  "  2. Metadata: Sample mapping, Clinical integration",
  "  3. QC: Outliers, Batch effects, Metrics",
  "  4. Core: G>T analysis, Seed region, Statistics",
  "  5. Sequence: Motifs, Logos, Families",
  "  6. Functional: Pathways, Targets",
  "  7. Temporal: Longitudinal analysis (optional)",
  "  8. Reporting: HTML, Figures, Tables",
  "",
  "Total: 20 steps organized in 8 phases"
), "pipeline_summary.txt")

cat("✅ Text summary created: pipeline_summary.txt\n\n")








