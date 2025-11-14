# ============================================================================
# SNAKEMAKE RULES: STEP 4 - Functional Analysis
# ============================================================================
# Purpose: Functional interpretation of miRNA oxidation patterns
#          Target prediction, GO/KEGG enrichment, pathway analysis
#          Interprets the structure discovered in Step 3 (clustering)
# Execution: Runs after Step 3 (clustering), in parallel with Steps 5, 6
#            Uses clustering results to perform functional analysis on clusters
# ============================================================================

# Load configuration
configfile: "config/config.yaml"

# ============================================================================
# COMMON PATHS
# ============================================================================

# Scripts paths
# For script: directive (resolved from rules/ directory), use relative path
SCRIPTS_STEP4_SCRIPT = "../scripts/step4"  # For script: (resolved from rules/)
SCRIPTS_UTILS_SCRIPT = "../scripts/utils"  # For script: (resolved from rules/)
# For input: directive (resolved from Snakefile), use config path
SCRIPTS_STEP4 = config["paths"]["scripts"]["step4"]  # For input: (resolved from Snakefile)
SCRIPTS_UTILS = config["paths"]["scripts"]["utils"]  # For input: (resolved from Snakefile)
FUNCTIONS_COMMON = SCRIPTS_UTILS + "/functions_common.R"  # For input: (resolved from Snakefile)

# Output directories (using full paths)
OUTPUT_STEP4 = config["paths"]["outputs"]["step4"]
OUTPUT_FIGURES = OUTPUT_STEP4 + "/figures"
OUTPUT_TABLES_FUNCTIONAL = OUTPUT_STEP4 + "/tables/functional"
OUTPUT_LOGS = OUTPUT_STEP4 + "/logs"

# Inputs from previous steps (using full paths)
STEP2_DATA_DIR = config["paths"]["outputs"]["step2"]
STEP3_DATA_DIR = config["paths"]["outputs"]["step3"]
STEP1_5_DATA_DIR = config["paths"]["outputs"]["step1_5"]
INPUT_STEP2_STATS = STEP2_DATA_DIR + "/tables/statistical_results/S2_statistical_comparisons.csv"
INPUT_STEP3_CLUSTERS = STEP3_DATA_DIR + "/tables/clusters/S3_cluster_assignments.csv"
INPUT_STEP1_5_FILTERED_DATA = STEP1_5_DATA_DIR + "/tables/filtered_data/ALL_MUTATIONS_VAF_FILTERED.csv"

# ============================================================================
# RULE: Functional Target Analysis
# ============================================================================

rule step4_functional_target_analysis:
    input:
        statistical_results = INPUT_STEP2_STATS,
        cluster_assignments = INPUT_STEP3_CLUSTERS,
        filtered_data = INPUT_STEP1_5_FILTERED_DATA,
        functions = FUNCTIONS_COMMON
    output:
        targets = OUTPUT_TABLES_FUNCTIONAL + "/S4_target_analysis.csv",
        als_genes = OUTPUT_TABLES_FUNCTIONAL + "/S4_als_relevant_genes.csv",
        target_comparison = OUTPUT_TABLES_FUNCTIONAL + "/S4_target_comparison.csv"
    params:
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/functional_target_analysis.log"
    script:
        SCRIPTS_STEP4_SCRIPT + "/01_functional_target_analysis.R"

# ============================================================================
# RULE: Pathway Enrichment Analysis
# ============================================================================

rule step4_pathway_enrichment:
    input:
        targets = OUTPUT_TABLES_FUNCTIONAL + "/S4_target_analysis.csv",
        functions = FUNCTIONS_COMMON
    output:
        go_enrichment = OUTPUT_TABLES_FUNCTIONAL + "/S4_go_enrichment.csv",
        kegg_enrichment = OUTPUT_TABLES_FUNCTIONAL + "/S4_kegg_enrichment.csv",
        als_pathways = OUTPUT_TABLES_FUNCTIONAL + "/S4_als_pathways.csv",
        heatmap = OUTPUT_FIGURES + "/step4_pathway_enrichment_heatmap.png"
    params:
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/pathway_enrichment.log"
    script:
        SCRIPTS_STEP4_SCRIPT + "/02_pathway_enrichment_analysis.R"

# ============================================================================
# RULE: Complex Functional Visualization
# ============================================================================

rule step4_complex_functional_visualization:
    input:
        targets = OUTPUT_TABLES_FUNCTIONAL + "/S4_target_analysis.csv",
        go_enrichment = OUTPUT_TABLES_FUNCTIONAL + "/S4_go_enrichment.csv",
        kegg_enrichment = OUTPUT_TABLES_FUNCTIONAL + "/S4_kegg_enrichment.csv",
        als_genes = OUTPUT_TABLES_FUNCTIONAL + "/S4_als_relevant_genes.csv",
        target_comparison = OUTPUT_TABLES_FUNCTIONAL + "/S4_target_comparison.csv",
        functions = FUNCTIONS_COMMON
    output:
        figure_a = OUTPUT_FIGURES + "/step4_functional_panelA_target_network.png",
        figure_b = OUTPUT_FIGURES + "/step4_functional_panelB_go_enrichment.png",
        figure_c = OUTPUT_FIGURES + "/step4_functional_panelC_kegg_enrichment.png",
        figure_d = OUTPUT_FIGURES + "/step4_functional_panelD_als_pathways.png"
    params:
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/complex_functional_visualization.log"
    script:
        SCRIPTS_STEP4_SCRIPT + "/03_complex_functional_visualization.R"

# ============================================================================
# AGGREGATE RULE: All Step 4 outputs
# ============================================================================

rule all_step4:
    input:
        # DEPENDENCY: Step 4 requires Step 2 (statistical comparisons) and Step 3 (clustering)
        rules.all_step2.output,
        rules.all_step3.output,
        # Functional analysis tables
        OUTPUT_TABLES_FUNCTIONAL + "/S4_target_analysis.csv",
        OUTPUT_TABLES_FUNCTIONAL + "/S4_als_relevant_genes.csv",
        OUTPUT_TABLES_FUNCTIONAL + "/S4_target_comparison.csv",
        OUTPUT_TABLES_FUNCTIONAL + "/S4_go_enrichment.csv",
        OUTPUT_TABLES_FUNCTIONAL + "/S4_kegg_enrichment.csv",
        OUTPUT_TABLES_FUNCTIONAL + "/S4_als_pathways.csv",
        # Functional analysis figures
        OUTPUT_FIGURES + "/step4_pathway_enrichment_heatmap.png",
        OUTPUT_FIGURES + "/step4_functional_panelA_target_network.png",
        OUTPUT_FIGURES + "/step4_functional_panelB_go_enrichment.png",
        OUTPUT_FIGURES + "/step4_functional_panelC_kegg_enrichment.png",
        OUTPUT_FIGURES + "/step4_functional_panelD_als_pathways.png"
