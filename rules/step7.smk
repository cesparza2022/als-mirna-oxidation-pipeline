# ============================================================================
# SNAKEMAKE RULES: STEP 7 - Biomarker Analysis
# ============================================================================
# Purpose: Biomarker identification and diagnostic potential evaluation
#          ROC curve analysis, AUC calculation, multi-miRNA diagnostic signatures
#          This is the final clinical application step, integrating insights from previous steps
# Execution: Runs LAST, after Steps 2-6
#            Primarily uses statistical results from Step 2, can optionally use Steps 3-6 insights
# ============================================================================

# Load configuration
configfile: "config/config.yaml"

# ============================================================================
# COMMON PATHS
# ============================================================================

# Scripts paths
# For script: directive (resolved from rules/ directory), use relative path
SCRIPTS_STEP7_SCRIPT = "../scripts/step7"  # For script: (resolved from rules/)
SCRIPTS_UTILS_SCRIPT = "../scripts/utils"  # For script: (resolved from rules/)
# For input: directive (resolved from Snakefile), use config path
SCRIPTS_STEP7 = config["paths"]["scripts"]["step7"]  # For input: (resolved from Snakefile)
SCRIPTS_UTILS = config["paths"]["scripts"]["utils"]  # For input: (resolved from Snakefile)
FUNCTIONS_COMMON = SCRIPTS_UTILS + "/functions_common.R"  # For input: (resolved from Snakefile)

# Output directories (using full paths)
OUTPUT_STEP7 = config["paths"]["outputs"]["step7"]
OUTPUT_FIGURES = OUTPUT_STEP7 + "/figures"
OUTPUT_TABLES_BIOMARKERS = OUTPUT_STEP7 + "/tables/biomarkers"
OUTPUT_LOGS = OUTPUT_STEP7 + "/logs"

# Inputs from previous steps (using full paths)
STEP2_DATA_DIR = config["paths"]["outputs"]["step2"]
STEP1_5_DATA_DIR = config["paths"]["outputs"]["step1_5"]
INPUT_STEP2_STATS = STEP2_DATA_DIR + "/tables/statistical_results/S2_statistical_comparisons.csv"
INPUT_STEP1_5_FILTERED_DATA = STEP1_5_DATA_DIR + "/tables/filtered_data/ALL_MUTATIONS_VAF_FILTERED.csv"

# ============================================================================
# RULE: ROC Analysis
# ============================================================================

rule step7_roc_analysis:
    input:
        statistical_results = INPUT_STEP2_STATS,
        vaf_filtered = INPUT_STEP1_5_FILTERED_DATA,
        functions = FUNCTIONS_COMMON
    output:
        roc_table = OUTPUT_TABLES_BIOMARKERS + "/S7_roc_analysis.csv",
        signatures = OUTPUT_TABLES_BIOMARKERS + "/S7_biomarker_signatures.csv",
        roc_figure = OUTPUT_FIGURES + "/step7_roc_curves.png"
    params:
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/roc_analysis.log"
    script:
        SCRIPTS_STEP7_SCRIPT + "/01_biomarker_roc_analysis.R"

# ============================================================================
# RULE: Biomarker Signature Heatmap
# ============================================================================

rule step7_biomarker_heatmap:
    input:
        roc_table = OUTPUT_TABLES_BIOMARKERS + "/S7_roc_analysis.csv",
        vaf_filtered = INPUT_STEP1_5_FILTERED_DATA,
        functions = FUNCTIONS_COMMON
    output:
        heatmap = OUTPUT_FIGURES + "/step7_biomarker_signature_heatmap.png"
    params:
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/biomarker_heatmap.log"
    script:
        SCRIPTS_STEP7_SCRIPT + "/02_biomarker_signature_heatmap.R"

# ============================================================================
# AGGREGATE RULE: All Step 7 outputs
# ============================================================================

rule all_step7:
    input:
        # DEPENDENCY: Step 7 requires Step 2 (statistical comparisons)
        # Can optionally use Steps 3-6, but Step 2 is the primary requirement
        rules.all_step2.output,
        # Biomarker tables
        OUTPUT_TABLES_BIOMARKERS + "/S7_roc_analysis.csv",
        OUTPUT_TABLES_BIOMARKERS + "/S7_biomarker_signatures.csv",
        # Figures
        OUTPUT_FIGURES + "/step7_roc_curves.png",
        OUTPUT_FIGURES + "/step7_biomarker_signature_heatmap.png"
