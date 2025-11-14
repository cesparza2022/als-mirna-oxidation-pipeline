# ============================================================================
# SNAKEMAKE RULES: STEP 6 - Expression vs Oxidation Correlation Analysis
# ============================================================================
# Purpose: Analyze correlation between miRNA expression levels and oxidation patterns
#          Examines the relationship between expression and oxidation
# Execution: Runs after Step 2 (statistical comparisons), in parallel with Steps 4, 5
#            Independent analysis that does not require clustering
# ============================================================================

# Load configuration
configfile: "config/config.yaml"

# ============================================================================
# COMMON PATHS
# ============================================================================

# Scripts paths
# For script: directive (resolved from rules/ directory), use relative path
SCRIPTS_STEP6_SCRIPT = "../scripts/step6"  # For script: (resolved from rules/)
SCRIPTS_UTILS_SCRIPT = "../scripts/utils"  # For script: (resolved from rules/)
# For input: directive (resolved from Snakefile), use config path
SCRIPTS_STEP6 = config["paths"]["scripts"]["step6"]  # For input: (resolved from Snakefile)
SCRIPTS_UTILS = config["paths"]["scripts"]["utils"]  # For input: (resolved from Snakefile)
FUNCTIONS_COMMON = SCRIPTS_UTILS + "/functions_common.R"  # For input: (resolved from Snakefile)

# Output directories (using full paths)
OUTPUT_STEP6 = config["paths"]["outputs"]["step6"]
OUTPUT_FIGURES = OUTPUT_STEP6 + "/figures"
OUTPUT_TABLES_CORRELATION = OUTPUT_STEP6 + "/tables/correlation"
OUTPUT_LOGS = OUTPUT_STEP6 + "/logs"

# Inputs from previous steps (using full paths)
STEP2_DATA_DIR = config["paths"]["outputs"]["step2"]
STEP1_5_DATA_DIR = config["paths"]["outputs"]["step1_5"]
INPUT_STEP2_STATS = STEP2_DATA_DIR + "/tables/statistical_results/S2_statistical_comparisons.csv"
INPUT_STEP1_5_FILTERED_DATA = STEP1_5_DATA_DIR + "/tables/filtered_data/ALL_MUTATIONS_VAF_FILTERED.csv"
# Need raw expression data (RPM) - use step1 original or processed data
INPUT_EXPRESSION_DATA = config["paths"]["data"]["raw"]

# ============================================================================
# RULE: Expression-Oxidation Correlation Analysis
# ============================================================================

rule step6_correlation_analysis:
    input:
        comparisons = INPUT_STEP2_STATS,
        filtered_data = INPUT_STEP1_5_FILTERED_DATA,
        expression_data = INPUT_EXPRESSION_DATA,
        functions = FUNCTIONS_COMMON
    output:
        correlation_table = OUTPUT_TABLES_CORRELATION + "/S6_expression_oxidation_correlation.csv",
        expression_summary = OUTPUT_TABLES_CORRELATION + "/S6_expression_summary.csv"
    params:
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/correlation_analysis.log"
    script:
        SCRIPTS_STEP6_SCRIPT + "/01_expression_oxidation_correlation.R"

# ============================================================================
# RULE: Correlation Visualization
# ============================================================================

rule step6_correlation_visualization:
    input:
        correlation_table = OUTPUT_TABLES_CORRELATION + "/S6_expression_oxidation_correlation.csv",
        expression_summary = OUTPUT_TABLES_CORRELATION + "/S6_expression_summary.csv",
        functions = FUNCTIONS_COMMON
    output:
        figure_a = OUTPUT_FIGURES + "/step6_panelA_expression_vs_oxidation.png",
        figure_b = OUTPUT_FIGURES + "/step6_panelB_expression_groups_comparison.png"
    params:
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/correlation_visualization.log"
    script:
        SCRIPTS_STEP6_SCRIPT + "/02_correlation_visualization.R"

# ============================================================================
# AGGREGATE RULE: All Step 6 outputs
# ============================================================================

rule all_step6:
    input:
        # DEPENDENCY: Step 6 requires Step 2 (statistical comparisons)
        rules.all_step2.output,
        # Correlation analysis tables
        OUTPUT_TABLES_CORRELATION + "/S6_expression_oxidation_correlation.csv",
        OUTPUT_TABLES_CORRELATION + "/S6_expression_summary.csv",
        # Correlation figures
        OUTPUT_FIGURES + "/step6_panelA_expression_vs_oxidation.png",
        OUTPUT_FIGURES + "/step6_panelB_expression_groups_comparison.png"
