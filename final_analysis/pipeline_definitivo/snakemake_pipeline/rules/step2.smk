# ============================================================================
# SNAKEMAKE RULES: STEP 2 - Statistical Comparisons (ALS vs Control)
# ============================================================================
# Rules for comparing ALS vs Control groups
# ============================================================================

# Load configuration
configfile: "config/config.yaml"

# ============================================================================
# COMMON PATHS AND PARAMETERS
# ============================================================================

# Input data (from Step 1.5 - VAF filtered)
# Note: Path is relative to snakemake_dir
STEP1_5_DATA_DIR = config["paths"]["snakemake_dir"] + "/" + config["paths"]["outputs"]["step1_5"]
INPUT_DATA_VAF_FILTERED = STEP1_5_DATA_DIR + "/data/ALL_MUTATIONS_VAF_FILTERED.csv"

# Alternative: use processed clean data if VAF filtered not available
INPUT_DATA_FALLBACK = config["paths"]["data"]["processed_clean"]

# Output directories
OUTPUT_STEP2 = config["paths"]["outputs"]["step2"]
OUTPUT_FIGURES = OUTPUT_STEP2 + "/figures"
OUTPUT_TABLES = OUTPUT_STEP2 + "/tables"
OUTPUT_LOGS = OUTPUT_STEP2 + "/logs"

# Scripts directories
SCRIPTS_STEP2 = config["paths"]["snakemake_dir"] + "/" + config["paths"]["scripts"]["step2"]
SCRIPTS_UTILS = config["paths"]["snakemake_dir"] + "/" + config["paths"]["scripts"]["utils"]

# Common parameters
FUNCTIONS_COMMON = SCRIPTS_UTILS + "/functions_common.R"
GROUP_FUNCTIONS = SCRIPTS_UTILS + "/group_comparison.R"

# ============================================================================
# RULE: Statistical Comparisons
# ============================================================================

rule step2_statistical_comparisons:
    input:
        data = INPUT_DATA_FALLBACK,  # Use processed clean data for now
        functions = FUNCTIONS_COMMON
    output:
        table = OUTPUT_TABLES + "/step2_statistical_comparisons.csv"
    params:
        functions = FUNCTIONS_COMMON,
        group_functions = GROUP_FUNCTIONS
    log:
        OUTPUT_LOGS + "/statistical_comparisons.log"
    script:
        SCRIPTS_STEP2 + "/01_statistical_comparisons.R"

# ============================================================================
# RULE: Volcano Plot
# ============================================================================

rule step2_volcano_plot:
    input:
        comparisons = OUTPUT_TABLES + "/step2_statistical_comparisons.csv",
        functions = FUNCTIONS_COMMON
    output:
        figure = OUTPUT_FIGURES + "/step2_volcano_plot.png"
    params:
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/volcano_plot.log"
    script:
        SCRIPTS_STEP2 + "/02_volcano_plots.R"

# ============================================================================
# RULE: Effect Size Analysis
# ============================================================================

rule step2_effect_size:
    input:
        comparisons = OUTPUT_TABLES + "/step2_statistical_comparisons.csv",
        functions = FUNCTIONS_COMMON
    output:
        table = OUTPUT_TABLES + "/step2_effect_sizes.csv",
        figure = OUTPUT_FIGURES + "/step2_effect_size_distribution.png"
    params:
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/effect_size.log"
    script:
        SCRIPTS_STEP2 + "/03_effect_size_analysis.R"

# ============================================================================
# AGGREGATE RULE: All Step 2 outputs
# ============================================================================

rule all_step2:
    input:
        OUTPUT_TABLES + "/step2_statistical_comparisons.csv",
        OUTPUT_FIGURES + "/step2_volcano_plot.png",
        OUTPUT_TABLES + "/step2_effect_sizes.csv",
        OUTPUT_FIGURES + "/step2_effect_size_distribution.png"

