# ============================================================================
# SNAKEMAKE RULES: OUTPUT STRUCTURE
# ============================================================================
# Purpose: Ensure output directories are created automatically
# ============================================================================

# Load configuration
configfile: "config/config.yaml"

# ============================================================================
# COMMON PATHS
# ============================================================================

SCRIPTS_UTILS = config["paths"]["snakemake_dir"] + "/" + config["paths"]["scripts"]["utils"]

# ============================================================================
# RULE: Create Output Structure
# ============================================================================

rule create_output_structure:
    output:
        structure_created = touch("results/.structure_created")
    params:
        script = SCRIPTS_UTILS + "/create_output_structure.R"
    shell:
        """
        # Create output structure using R script or fallback
        if command -v Rscript &> /dev/null; then
            if ! Rscript {params.script} results; then
                echo "Rscript failed, using fallback method..."
                bash -c '
                    set -e
                    mkdir -p results/step1/final/figures
                    mkdir -p results/step1/final/tables/summary
                    mkdir -p results/step1/final/logs/benchmarks
                    mkdir -p results/step1/final/logs
                    mkdir -p results/step1/intermediate
                    mkdir -p results/step1_5/final/figures
                    mkdir -p results/step1_5/final/tables/filtered_data
                    mkdir -p results/step1_5/final/tables/filter_report
                    mkdir -p results/step1_5/final/tables/statistics
                    mkdir -p results/step1_5/final/logs/benchmarks
                    mkdir -p results/step1_5/final/logs
                    mkdir -p results/step1_5/intermediate
                    mkdir -p results/step2/final/figures
                    mkdir -p results/step2/final/figures_clean
                    mkdir -p results/step2/final/tables/statistical_results
                    mkdir -p results/step2/final/tables/summary
                    mkdir -p results/step2/final/logs/benchmarks
                    mkdir -p results/step2/final/logs
                    mkdir -p results/step2/intermediate
                    mkdir -p results/step3/final/figures
                    mkdir -p results/step3/final/tables/functional
                    mkdir -p results/step3/final/logs/benchmarks
                    mkdir -p results/step3/final/logs
                    mkdir -p results/step3/intermediate
                    mkdir -p results/step4/final/figures
                    mkdir -p results/step4/final/tables/biomarkers
                    mkdir -p results/step4/final/logs/benchmarks
                    mkdir -p results/step4/final/logs
                    mkdir -p results/step4/intermediate
                    mkdir -p results/step5/final/figures
                    mkdir -p results/step5/final/tables/families
                    mkdir -p results/step5/final/logs/benchmarks
                    mkdir -p results/step5/final/logs
                    mkdir -p results/step5/intermediate
                    mkdir -p results/step6/final/figures
                    mkdir -p results/step6/final/tables/correlation
                    mkdir -p results/step6/final/tables/functional
                    mkdir -p results/step6/final/logs/benchmarks
                    mkdir -p results/step6/final/logs
                    mkdir -p results/step6/intermediate
                    mkdir -p results/pipeline_info
                    mkdir -p results/summary
                    mkdir -p results/validation
                    mkdir -p results/viewers
                '
            fi
        else
            echo "Creating output structure manually..."
            bash -c '
                set -e
                mkdir -p results/step1/final/figures
                mkdir -p results/step1/final/tables/summary
                mkdir -p results/step1/final/logs/benchmarks
                mkdir -p results/step1/final/logs
                mkdir -p results/step1/intermediate
                mkdir -p results/step1_5/final/figures
                mkdir -p results/step1_5/final/tables/filtered_data
                mkdir -p results/step1_5/final/tables/filter_report
                mkdir -p results/step1_5/final/tables/statistics
                mkdir -p results/step1_5/final/logs/benchmarks
                mkdir -p results/step1_5/final/logs
                mkdir -p results/step1_5/intermediate
                mkdir -p results/step2/final/figures
                mkdir -p results/step2/final/figures_clean
                mkdir -p results/step2/final/tables/statistical_results
                mkdir -p results/step2/final/tables/summary
                mkdir -p results/step2/final/logs/benchmarks
                mkdir -p results/step2/final/logs
                mkdir -p results/step2/intermediate
                mkdir -p results/step3/final/figures
                mkdir -p results/step3/final/tables/functional
                mkdir -p results/step3/final/logs/benchmarks
                mkdir -p results/step3/final/logs
                mkdir -p results/step3/intermediate
                mkdir -p results/step4/final/figures
                mkdir -p results/step4/final/tables/biomarkers
                mkdir -p results/step4/final/logs/benchmarks
                mkdir -p results/step4/final/logs
                mkdir -p results/step4/intermediate
                mkdir -p results/step5/final/figures
                mkdir -p results/step5/final/tables/families
                mkdir -p results/step5/final/logs/benchmarks
                mkdir -p results/step5/final/logs
                mkdir -p results/step5/intermediate
                mkdir -p results/step6/final/figures
                mkdir -p results/step6/final/tables/correlation
                mkdir -p results/step6/final/tables/functional
                mkdir -p results/step6/final/logs/benchmarks
                mkdir -p results/step6/final/logs
                mkdir -p results/step6/intermediate
                mkdir -p results/pipeline_info
                mkdir -p results/summary
                mkdir -p results/validation
                mkdir -p results/viewers
            '
        fi
        touch {output.structure_created}
        echo "✅ Output structure created successfully"
        """

