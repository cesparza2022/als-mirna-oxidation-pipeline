# ============================================================================
# SNAKEMAKE RULES: STEP 0 - Dataset Overview
# ============================================================================
# Purpose:
#   Generate descriptive statistics and figures that characterise the processed
#   dataset before applying oxidation-specific analyses.
# ============================================================================

configfile: "config/config.yaml"

INPUT_DATA_CLEAN = config["paths"]["data"]["processed_clean"]

OUTPUT_STEP0 = config["paths"]["outputs"]["step0"]
OUTPUT_FIGURES = OUTPUT_STEP0 + "/figures"
OUTPUT_TABLES = OUTPUT_STEP0 + "/tables"
OUTPUT_LOGS = OUTPUT_STEP0 + "/logs"

SCRIPTS_STEP0 = config["paths"]["snakemake_dir"] + "/" + config["paths"]["scripts"]["step0"]
SCRIPTS_UTILS = config["paths"]["snakemake_dir"] + "/" + config["paths"]["scripts"]["utils"]
FUNCTIONS_COMMON = SCRIPTS_UTILS + "/functions_common.R"

rule step0_overview:
    input:
        data = INPUT_DATA_CLEAN
    output:
        fig_samples = OUTPUT_FIGURES + "/step0_fig_samples_snv_counts.png",
        fig_samples_box = OUTPUT_FIGURES + "/step0_fig_samples_snv_boxplot.png",
        fig_samples_group = OUTPUT_FIGURES + "/step0_fig_samples_group_pie.png",
        fig_miRNA = OUTPUT_FIGURES + "/step0_fig_miRNA_snv_counts.png",
        fig_mutation_bar = OUTPUT_FIGURES + "/step0_fig_mutation_type_distribution.png",
        fig_mutation_pie_snvs = OUTPUT_FIGURES + "/step0_fig_mutation_type_pie_snvs.png",
        fig_mutation_pie_counts = OUTPUT_FIGURES + "/step0_fig_mutation_type_pie_counts.png",
        fig_coverage = OUTPUT_FIGURES + "/step0_fig_dataset_coverage.png", # Replaces positional density
        table_samples = OUTPUT_TABLES + "/step0_sample_summary.csv",
        table_sample_group = OUTPUT_TABLES + "/step0_sample_group_summary.csv",
        table_miRNA = OUTPUT_TABLES + "/step0_miRNA_summary.csv",
        table_mutation = OUTPUT_TABLES + "/step0_mutation_type_counts.csv"
    params:
        functions = FUNCTIONS_COMMON
    log:
        OUTPUT_LOGS + "/overview.log"
    script:
        SCRIPTS_STEP0 + "/01_generate_overview.R"

rule all_step0:
    input:
        OUTPUT_FIGURES + "/step0_fig_samples_snv_counts.png",
        OUTPUT_FIGURES + "/step0_fig_samples_snv_boxplot.png",
        OUTPUT_FIGURES + "/step0_fig_samples_group_pie.png",
        OUTPUT_FIGURES + "/step0_fig_miRNA_snv_counts.png",
        OUTPUT_FIGURES + "/step0_fig_mutation_type_distribution.png",
        OUTPUT_FIGURES + "/step0_fig_mutation_type_pie_snvs.png",
        OUTPUT_FIGURES + "/step0_fig_mutation_type_pie_counts.png",
        OUTPUT_FIGURES + "/step0_fig_dataset_coverage.png", # Replaces positional density
        OUTPUT_TABLES + "/step0_sample_summary.csv",
        OUTPUT_TABLES + "/step0_sample_group_summary.csv",
        OUTPUT_TABLES + "/step0_miRNA_summary.csv",
        OUTPUT_TABLES + "/step0_mutation_type_counts.csv"
