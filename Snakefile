# ============================================================================
# SNAKEMAKE PIPELINE: miRNA Oxidation Analysis
# ============================================================================
# Main orchestrator for the complete analysis pipeline
#
# Usage:
#   snakemake -j 1              # Run all
#   snakemake -j 1 all_step1    # Run only Step 1
#   snakemake -n                # Dry-run (see what would run)
# ============================================================================

# Load configuration
configfile: "config/config.yaml"

# Include step-specific rule files
include: "rules/output_structure.smk"  # Auto-create output directories
include: "rules/step0.smk"
include: "rules/step1.smk"
include: "rules/step1_5.smk"  # VAF Quality Control
include: "rules/step2.smk"    # Statistical Comparisons (ALS vs Control)
include: "rules/step2_figures.smk"  # Additional detailed Step 2 figures (16 figures)
# Logical flow after statistical comparisons
include: "rules/step3.smk"    # Clustering Analysis (structure discovery)
include: "rules/step4.smk"    # Functional Analysis (target prediction, GO/KEGG, pathways - interprets clusters)
include: "rules/step5.smk"    # miRNA Family Analysis (compares clusters with biological families)
include: "rules/step6.smk"    # Expression vs Oxidation Correlation Analysis
include: "rules/step7.smk"    # Biomarker Analysis (ROC, AUC, diagnostic signatures - final clinical application)
include: "rules/viewers.smk"  # HTML viewers for each step
include: "rules/pipeline_info.smk"  # FASE 2: Pipeline metadata generation
include: "rules/summary.smk"  # FASE 3: Consolidated summary reports
include: "rules/validation.smk"  # Output validation and final checks

# ============================================================================
# DEFAULT TARGET (when running just 'snakemake')
# ============================================================================

rule all:
    input:
        rules.create_output_structure.output,  # Ensure output directories exist
        rules.all_step0.output,
        rules.all_step1.output,
        rules.all_step1_5.output,  # VAF Quality Control
        rules.all_step2.output,    # Statistical Comparisons
        rules.all_step2_figures.output,  # Additional detailed Step 2 figures (16 figures)
        # Logical flow - structure discovery before functional interpretation
        rules.all_step3.output,    # Clustering Analysis (structure discovery)
        rules.all_step4.output,    # Functional Analysis (targets, GO/KEGG, pathways - interprets clusters)
        rules.all_step5.output,    # miRNA Family Analysis (compares clusters with biological families)
        rules.all_step6.output,    # Expression Correlation Analysis
        rules.all_step7.output,    # Biomarker Analysis (ROC, AUC, diagnostic signatures - final step)
        rules.generate_pipeline_info.output,  # FASE 2: Pipeline metadata
        rules.generate_summary_report.output,  # FASE 3: Summary reports
        rules.validate_pipeline_completion.output  # Final validation report


