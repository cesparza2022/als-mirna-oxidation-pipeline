# ============================================================================
# SNAKEMAKE RULES: STEP 5 - miRNA Family Analysis
# ============================================================================
# Purpose: Compare data-driven clusters (from Step 3) with biological miRNA families
#          Analyzes oxidation patterns by miRNA families and compares with discovered clusters
# Execution: Runs after Step 3 (clustering), in parallel with Steps 4, 6
#            Uses clustering results to compare with known biological families
# ============================================================================

# Load configuration
configfile: "config/config.yaml"

# ============================================================================
# COMMON PATHS
# ============================================================================

SCRIPTS_STEP5_SCRIPT = "../scripts/step5"  # For script: (resolved from rules/)
SCRIPTS_UTILS_SCRIPT = "../scripts/utils"  # For script: (resolved from rules/)
SCRIPTS_UTILS = config["paths"]["scripts"]["utils"]  # For input paths (resolved from Snakefile)
FUNCTIONS_COMMON = SCRIPTS_UTILS + "/functions_common.R"

# Output directories
OUTPUT_STEP5 = config["paths"]["outputs"]["step5"]
OUTPUT_FIGURES = OUTPUT_STEP5 + "/figures"
OUTPUT_TABLES_FAMILIES = OUTPUT_STEP5 + "/tables/families"
OUTPUT_LOGS = OUTPUT_STEP5 + "/logs"

# Inputs from previous steps (using full paths)
STEP2_DATA_DIR = config["paths"]["outputs"]["step2"]
STEP3_DATA_DIR = config["paths"]["outputs"]["step3"]
STEP1_5_DATA_DIR = config["paths"]["outputs"]["step1_5"]
INPUT_STEP2_STATS = STEP2_DATA_DIR + "/tables/statistical_results/S2_statistical_comparisons.csv"
INPUT_STEP3_CLUSTERS = STEP3_DATA_DIR + "/tables/clusters/S3_cluster_assignments.csv"
INPUT_STEP1_5_FILTERED_DATA = STEP1_5_DATA_DIR + "/tables/filtered_data/ALL_MUTATIONS_VAF_FILTERED.csv"

# ============================================================================
# RULE: Family Identification and Summary
# ============================================================================

rule step5_family_identification:
    input:
        comparisons = INPUT_STEP2_STATS,
        cluster_assignments = INPUT_STEP3_CLUSTERS,
        filtered_data = INPUT_STEP1_5_FILTERED_DATA,
        functions = FUNCTIONS_COMMON
    output:
        family_summary = OUTPUT_TABLES_FAMILIES + "/S5_family_summary.csv",
        family_comparison = OUTPUT_TABLES_FAMILIES + "/S5_family_comparison.csv"
    params:
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/family_identification.log"
    script:
        SCRIPTS_STEP5_SCRIPT + "/01_family_identification.R"

# ============================================================================
# RULE: Family Comparison Visualization
# ============================================================================

rule step5_family_visualization:
    input:
        family_summary = OUTPUT_TABLES_FAMILIES + "/S5_family_summary.csv",
        family_comparison = OUTPUT_TABLES_FAMILIES + "/S5_family_comparison.csv",
        cluster_assignments = INPUT_STEP3_CLUSTERS,
        functions = FUNCTIONS_COMMON
    output:
        figure_a = OUTPUT_FIGURES + "/step5_panelA_family_oxidation_comparison.png",
        figure_b = OUTPUT_FIGURES + "/step5_panelB_family_heatmap.png"
    params:
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/family_visualization.log"
    script:
        SCRIPTS_STEP5_SCRIPT + "/02_family_comparison_visualization.R"

# ============================================================================
# AGGREGATE RULE: All Step 5 outputs
# ============================================================================

rule all_step5:
    input:
        # DEPENDENCY: Step 5 requires Step 2 (statistical comparisons) and Step 3 (clustering)
        rules.all_step2.output,
        rules.all_step3.output,
        # Family analysis tables
        OUTPUT_TABLES_FAMILIES + "/S5_family_summary.csv",
        OUTPUT_TABLES_FAMILIES + "/S5_family_comparison.csv",
        # Figures
        OUTPUT_FIGURES + "/step5_panelA_family_oxidation_comparison.png",
        OUTPUT_FIGURES + "/step5_panelB_family_heatmap.png"
