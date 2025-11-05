# ============================================================================
# SNAKEMAKE RULES: STEP 5 - Expression vs Oxidation Correlation
# ============================================================================
# Purpose: Analyze correlation between miRNA expression levels and oxidation
# Execution: Runs after Step 3 (clustering), in parallel with Steps 4, 6
#            Can use clustering context for expression analysis
# ============================================================================

# Load configuration
configfile: "config/config.yaml"

# ============================================================================
# COMMON PATHS
# ============================================================================

# Scripts paths
# For script: directive (resolved from rules/ directory), use relative path
SCRIPTS_STEP5_SCRIPT = "../scripts/step5"  # For script: (resolved from rules/)
SCRIPTS_UTILS_SCRIPT = "../scripts/utils"  # For script: (resolved from rules/)
# For input: directive (resolved from Snakefile), use config path
SCRIPTS_STEP5 = config["paths"]["scripts"]["step5"]  # For input: (resolved from Snakefile)
SCRIPTS_UTILS = config["paths"]["scripts"]["utils"]  # For input: (resolved from Snakefile)
FUNCTIONS_COMMON = SCRIPTS_UTILS + "/functions_common.R"  # For input: (resolved from Snakefile)

# Output directories (using full paths)
OUTPUT_STEP5 = config["paths"]["outputs"]["step5"]
OUTPUT_FIGURES = OUTPUT_STEP5 + "/figures"
OUTPUT_TABLES_CORRELATION = OUTPUT_STEP5 + "/tables/correlation"
OUTPUT_LOGS = OUTPUT_STEP5 + "/logs"

# Inputs from previous steps (using full paths)
STEP2_DATA_DIR = config["paths"]["snakemake_dir"] + "/" + config["paths"]["outputs"]["step2"]
STEP1_5_DATA_DIR = config["paths"]["snakemake_dir"] + "/" + config["paths"]["outputs"]["step1_5"]
INPUT_STEP2_STATS = STEP2_DATA_DIR + "/tables/statistical_results/S2_statistical_comparisons.csv"
INPUT_STEP1_5_FILTERED_DATA = STEP1_5_DATA_DIR + "/tables/filtered_data/ALL_MUTATIONS_VAF_FILTERED.csv"
# Need raw expression data (RPM) - use step1 original or processed data
INPUT_EXPRESSION_DATA = config["paths"]["data"]["raw"]
# Note: Step 5 currently doesn't use cluster assignments, but could in future versions
# For now, clusters are not included as input to avoid unnecessary dependency

# ============================================================================
# RULE: Expression-Oxidation Correlation Analysis
# ============================================================================

rule step5_correlation_analysis:
    input:
        comparisons = INPUT_STEP2_STATS,
        filtered_data = INPUT_STEP1_5_FILTERED_DATA,
        expression_data = INPUT_EXPRESSION_DATA,
        functions = FUNCTIONS_COMMON
    output:
        correlation_table = OUTPUT_TABLES_CORRELATION + "/S5_expression_oxidation_correlation.csv",
        expression_summary = OUTPUT_TABLES_CORRELATION + "/S5_expression_summary.csv"
    params:
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/correlation_analysis.log"
    script:
        SCRIPTS_STEP5_SCRIPT + "/01_expression_oxidation_correlation.R"

# ============================================================================
# RULE: Correlation Visualization
# ============================================================================

rule step5_correlation_visualization:
    input:
        correlation_table = OUTPUT_TABLES_CORRELATION + "/S5_expression_oxidation_correlation.csv",
        expression_summary = OUTPUT_TABLES_CORRELATION + "/S5_expression_summary.csv",
        functions = FUNCTIONS_COMMON
    output:
        figure_a = OUTPUT_FIGURES + "/step5_panelA_expression_vs_oxidation.png",
        figure_b = OUTPUT_FIGURES + "/step5_panelB_expression_groups_comparison.png"
    params:
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/correlation_visualization.log"
    script:
        SCRIPTS_STEP5_SCRIPT + "/02_correlation_visualization.R"

# ============================================================================
# AGGREGATE RULE: All Step 5 outputs
# ============================================================================

rule all_step5:
    input:
        # DEPENDENCY: Step 5 requires Step 2 (statistical comparisons) and Step 3 (clustering)
        rules.all_step2.output,
        rules.all_step3.output,
        # Correlation analysis tables
        OUTPUT_TABLES_CORRELATION + "/S5_expression_oxidation_correlation.csv",
        OUTPUT_TABLES_CORRELATION + "/S5_expression_summary.csv",
        # Figures
        OUTPUT_FIGURES + "/step5_panelA_expression_vs_oxidation.png",
        OUTPUT_FIGURES + "/step5_panelB_expression_groups_comparison.png"

