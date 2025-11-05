library(dplyr)
library(stringr)
library(tidyr)
library(readr)
library(ggplot2)
library(gridExtra)
library(RColorBrewer)
library(pheatmap)

cat("🧬 ANÁLISIS FUNCIONAL COMPUTACIONAL - GENES ALS\n")
cat(paste(rep("=", 60), collapse=""), "\n")

# 1. CARGAR DATOS PROCESADOS
cat("\n📁 Cargando datos procesados...\n")
df_processed <- read_tsv("outputs/processed_mirna_dataset_simple.tsv")
cat("   📊 Dataset procesado:", nrow(df_processed), "x", ncol(df_processed), "\n")

# 2. DEFINIR GENES RELACIONADOS CON ALS
cat("\n🧬 Definindo genes relacionados con ALS...\n")
als_genes <- c(
  # Genes principales de ALS
  "SOD1", "TARDBP", "FUS", "C9ORF72", "OPTN", "VCP", "UBQLN2", "SQSTM1",
  "PFN1", "TUBA4A", "CHCHD10", "TBK1", "NEK1", "KIF5A", "C21ORF2", "MATR3",
  "CHMP2B", "DCTN1", "PRPH", "NEFH", "SETX", "ALS2", "SPG11", "FIG4",
  
  # Genes relacionados con neurodegeneración
  "APP", "PSEN1", "PSEN2", "MAPT", "APOE", "SNCA", "LRRK2", "PARK2",
  "PINK1", "DJ1", "ATP13A2", "PLA2G6", "FBXO7", "VPS35", "EIF4G1",
  
  # Genes de respuesta al estrés oxidativo
  "NQO1", "GSTP1", "CAT", "GPX1", "SOD2", "PRDX1", "PRDX2", "PRDX3",
  "TXNRD1", "GSR", "GCLC", "GCLM", "HMOX1", "HMOX2",
  
  # Genes de autofagia y proteostasis
  "BECN1", "ATG5", "ATG7", "ATG12", "LC3B", "SQSTM1", "OPTN", "TBK1",
  "ULK1", "ULK2", "FIP200", "VPS34", "AMBRA1", "WIPI1", "WIPI2",
  
  # Genes de inflamación y glía
  "IL1B", "IL6", "TNF", "NFKB1", "RELA", "STAT3", "JAK2", "SOCS3",
  "GFAP", "S100B", "IBA1", "CD68", "CD11B", "TLR4", "TLR2", "MYD88",
  
  # Genes de transporte axonal
  "DYNC1H1", "KIF1A", "KIF1B", "KIF5A", "KIF5B", "KIF5C", "DCTN1",
  "DYNLL1", "DYNLL2", "DYNLRB1", "DYNLRB2", "DYNLT1", "DYNLT3",
  
  # Genes de sinapsis y neurotransmisión
  "SYN1", "SYN2", "SYN3", "SNAP25", "STX1A", "STX1B", "VAMP1", "VAMP2",
  "SYP", "PSD95", "GRIN1", "GRIN2A", "GRIN2B", "GABRA1", "GABRB1",
  
  # Genes de metabolismo energético
  "ATP5A1", "ATP5B", "ATP5C1", "ATP5D", "ATP5E", "ATP5F1", "ATP5G1",
  "ATP5G2", "ATP5G3", "ATP5H", "ATP5I", "ATP5J", "ATP5J2", "ATP5K",
  "ATP5L", "ATP5O", "ATP5S", "ATP6V0A1", "ATP6V0A2", "ATP6V0A4",
  
  # Genes de reparación de ADN
  "PARP1", "PARP2", "XRCC1", "XRCC3", "XRCC4", "XRCC5", "XRCC6",
  "BRCA1", "BRCA2", "ATM", "ATR", "CHEK1", "CHEK2", "TP53", "MDM2",
  
  # Genes de apoptosis
  "BAX", "BAK1", "BCL2", "BCL2L1", "BCL2L2", "BCL2L11", "BID", "BIM",
  "PUMA", "NOXA", "MCL1", "BCL2A1", "BCL2L10", "BCL2L12", "BCL2L13",
  
  # Genes de estrés del retículo endoplásmico
  "ATF4", "ATF6", "XBP1", "DDIT3", "ERN1", "EIF2AK3", "EIF2S1",
  "PPP1R15A", "PPP1R15B", "DNAJB9", "DNAJB11", "HSPA5", "HSP90B1"
)

cat("   📊 Genes ALS identificados:", length(als_genes), "\n")

# 3. CARGAR DATOS DE MUTACIONES G>T EN REGIÓN SEMILLA
cat("\n🔧 Cargando mutaciones G>T en región semilla...\n")
df_seed_gt <- df_processed %>%
  filter(str_detect(pos.mut, "GT")) %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^\\d+"))) %>%
  filter(position >= 2 & position <= 8)  # Región semilla

cat("   📊 Mutaciones G>T en región semilla:", nrow(df_seed_gt), "\n")
cat("   📊 miRNAs únicos con mutaciones:", length(unique(df_seed_gt$miRNA.name)), "\n")

# 4. DEFINIR COLUMNAS
snv_cols <- colnames(df_processed)[3:417]
total_cols <- colnames(df_processed)[418:832]

# 5. CALCULAR VAF Y FILTRAR
cat("\n🔧 Calculando VAF y filtrando...\n")
vaf_matrix <- matrix(0, nrow = nrow(df_seed_gt), ncol = length(snv_cols))
for (i in 1:nrow(df_seed_gt)) {
  for (j in 1:length(snv_cols)) {
    snv_count <- as.numeric(df_seed_gt[i, snv_cols[j]])
    total_count <- as.numeric(df_seed_gt[i, total_cols[j]])
    if (total_count > 0) {
      vaf_matrix[i, j] <- snv_count / total_count
    }
  }
}

df_seed_gt$mean_vaf <- rowMeans(vaf_matrix, na.rm = TRUE)
df_seed_gt$max_vaf <- apply(vaf_matrix, 1, max, na.rm = TRUE)

# Filtrar VAF > 50%
df_filtered <- df_seed_gt %>%
  filter(max_vaf <= 0.5)

cat("   📊 Después de filtrar VAF > 50%:", nrow(df_filtered), "\n")

# 6. CALCULAR RPM
cat("\n🔧 Calculando RPM...\n")
library_sizes <- df_processed %>%
  select(all_of(total_cols)) %>%
  summarise(across(everything(), ~ sum(.x, na.rm = TRUE))) %>%
  unlist()

rpm_matrix <- matrix(0, nrow = nrow(df_filtered), ncol = length(total_cols))
for (i in 1:nrow(df_filtered)) {
  for (j in 1:length(total_cols)) {
    total_count <- as.numeric(df_filtered[i, total_cols[j]])
    lib_size <- library_sizes[total_cols[j]]
    if (lib_size > 0) {
      rpm_matrix[i, j] <- (total_count / lib_size) * 1e6
    }
  }
}
df_filtered$mean_rpm <- rowMeans(rpm_matrix, na.rm = TRUE)

# Filtrar RPM > 1
df_final <- df_filtered %>%
  filter(mean_rpm > 1)

cat("   📊 Después de filtrar RPM > 1:", nrow(df_final), "\n")
cat("   📊 miRNAs finales:", length(unique(df_final$miRNA.name)), "\n")

# 7. ANÁLISIS FUNCIONAL COMPUTACIONAL
cat("\n🧬 Iniciando análisis funcional computacional...\n")

# 7.1 Análisis por posición en región semilla
position_analysis <- df_final %>%
  group_by(position) %>%
  summarise(
    total_mutations = n(),
    unique_mirnas = n_distinct(miRNA.name),
    mean_vaf = mean(mean_vaf, na.rm = TRUE),
    mean_rpm = mean(mean_rpm, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(position)

cat("   📊 Análisis por posición completado\n")

# 7.2 Análisis por miRNA
mirna_analysis <- df_final %>%
  group_by(miRNA.name) %>%
  summarise(
    total_mutations = n(),
    positions = paste(sort(unique(position)), collapse = ","),
    mean_vaf = mean(mean_vaf, na.rm = TRUE),
    mean_rpm = mean(mean_rpm, na.rm = TRUE),
    max_vaf = max(max_vaf, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(total_mutations))

cat("   📊 Análisis por miRNA completado\n")

# 7.3 Predicción de impacto funcional computacional
cat("\n🔬 Predicción de impacto funcional...\n")

# Función para calcular score de impacto basado en posición y conservación
calculate_impact_score <- function(position, vaf, rpm) {
  # Score basado en posición (mayor impacto en posiciones más críticas)
  position_weights <- c(2, 3, 2.5, 2, 1.5, 1, 0.5)  # Posiciones 2-8
  pos_weight <- position_weights[position - 1]
  
  # Score basado en VAF (mayor VAF = mayor impacto)
  vaf_score <- vaf * 1000  # Escalar VAF
  
  # Score basado en expresión (mayor RPM = mayor impacto)
  rpm_score <- log10(rpm + 1)  # Log scale para RPM
  
  # Score combinado
  impact_score <- pos_weight * vaf_score * rpm_score
  
  return(impact_score)
}

# Aplicar función de impacto
df_final$impact_score <- mapply(calculate_impact_score, 
                               df_final$position, 
                               df_final$mean_vaf, 
                               df_final$mean_rpm)

# Clasificar impacto
df_final$impact_level <- case_when(
  df_final$impact_score >= 10 ~ "High",
  df_final$impact_score >= 5 ~ "Medium", 
  df_final$impact_score >= 1 ~ "Low",
  TRUE ~ "Very Low"
)

cat("   📊 Scores de impacto calculados\n")

# 7.4 Análisis de genes diana potenciales
cat("\n🎯 Análisis de genes diana potenciales...\n")

# Base de datos simplificada de genes diana (basada en literatura)
mirna_targets <- list(
  "hsa-miR-16-5p" = c("BCL2", "CCND1", "CCND3", "CCNE1", "CDK6", "WEE1", "ATM", "CHEK1"),
  "hsa-miR-21-5p" = c("PDCD4", "PTEN", "TPM1", "SPRY1", "SPRY2", "BTG2", "RECK", "TIMP3"),
  "hsa-miR-122-5p" = c("ALDOA", "PKM2", "LDHA", "PFKP", "G6PD", "TALDO1", "GPI", "ENO1"),
  "hsa-miR-126-3p" = c("VEGFA", "PIK3R2", "SPRED1", "VCAM1", "EGFL7", "CRK", "PTPN9", "SLC7A5"),
  "hsa-miR-146a-5p" = c("TRAF6", "IRAK1", "IRAK2", "CFH", "ROCK1", "NUMB", "NOTCH1", "STAT1"),
  "hsa-miR-155-5p" = c("SOCS1", "SHIP1", "C/EBPβ", "TP53INP1", "BACH1", "FOXO3A", "JARID2", "ZNF652"),
  "hsa-miR-200c-3p" = c("ZEB1", "ZEB2", "CDH1", "FN1", "VIM", "TUBB3", "BMI1", "SUZ12"),
  "hsa-let-7a-5p" = c("HMGA2", "KRAS", "NRAS", "MYC", "CCND1", "CCND2", "CDK6", "CDC25A"),
  "hsa-let-7b-5p" = c("HMGA2", "KRAS", "NRAS", "MYC", "CCND1", "CCND2", "CDK6", "CDC25A"),
  "hsa-let-7c-5p" = c("HMGA2", "KRAS", "NRAS", "MYC", "CCND1", "CCND2", "CDK6", "CDC25A"),
  "hsa-let-7d-5p" = c("HMGA2", "KRAS", "NRAS", "MYC", "CCND1", "CCND2", "CDK6", "CDC25A"),
  "hsa-let-7f-5p" = c("HMGA2", "KRAS", "NRAS", "MYC", "CCND1", "CCND2", "CDK6", "CDC25A"),
  "hsa-let-7i-5p" = c("HMGA2", "KRAS", "NRAS", "MYC", "CCND1", "CCND2", "CDK6", "CDC25A")
)

# Identificar genes diana para miRNAs mutados
target_analysis <- data.frame()
for (mirna in unique(df_final$miRNA.name)) {
  if (mirna %in% names(mirna_targets)) {
    targets <- mirna_targets[[mirna]]
    als_targets <- intersect(targets, als_genes)
    
    if (length(als_targets) > 0) {
      target_analysis <- rbind(target_analysis, data.frame(
        miRNA = mirna,
        total_targets = length(targets),
        als_targets = length(als_targets),
        als_target_list = paste(als_targets, collapse = ","),
        stringsAsFactors = FALSE
      ))
    }
  }
}

cat("   📊 Análisis de genes diana completado\n")
cat("   📊 miRNAs con genes diana ALS:", nrow(target_analysis), "\n")

# 8. ANÁLISIS DE PATHWAYS
cat("\n🛤️ Análisis de pathways...\n")

# Definir pathways relacionados con ALS
als_pathways <- list(
  "Oxidative Stress" = c("SOD1", "SOD2", "CAT", "GPX1", "NQO1", "GSTP1", "PRDX1", "PRDX2", "PRDX3", "TXNRD1", "GSR", "GCLC", "GCLM", "HMOX1", "HMOX2"),
  "Autophagy" = c("BECN1", "ATG5", "ATG7", "ATG12", "LC3B", "SQSTM1", "OPTN", "TBK1", "ULK1", "ULK2", "FIP200", "VPS34", "AMBRA1", "WIPI1", "WIPI2"),
  "Protein Aggregation" = c("TARDBP", "FUS", "SOD1", "C9ORF72", "VCP", "UBQLN2", "SQSTM1", "OPTN", "TBK1"),
  "Axonal Transport" = c("DYNC1H1", "KIF1A", "KIF1B", "KIF5A", "KIF5B", "KIF5C", "DCTN1", "DYNLL1", "DYNLL2", "DYNLRB1", "DYNLRB2", "DYNLT1", "DYNLT3"),
  "Inflammation" = c("IL1B", "IL6", "TNF", "NFKB1", "RELA", "STAT3", "JAK2", "SOCS3", "GFAP", "S100B", "IBA1", "CD68", "CD11B", "TLR4", "TLR2", "MYD88"),
  "Apoptosis" = c("BAX", "BAK1", "BCL2", "BCL2L1", "BCL2L11", "BID", "BIM", "PUMA", "NOXA", "MCL1", "TP53", "MDM2"),
  "DNA Repair" = c("PARP1", "PARP2", "XRCC1", "XRCC3", "XRCC4", "XRCC5", "XRCC6", "BRCA1", "BRCA2", "ATM", "ATR", "CHEK1", "CHEK2", "TP53", "MDM2"),
  "ER Stress" = c("ATF4", "ATF6", "XBP1", "DDIT3", "ERN1", "EIF2AK3", "EIF2S1", "PPP1R15A", "PPP1R15B", "DNAJB9", "DNAJB11", "HSPA5", "HSP90B1"),
  "Energy Metabolism" = c("ATP5A1", "ATP5B", "ATP5C1", "ATP5D", "ATP5E", "ATP5F1", "ATP5G1", "ATP5G2", "ATP5G3", "ATP5H", "ATP5I", "ATP5J", "ATP5J2", "ATP5K", "ATP5L", "ATP5O", "ATP5S", "ATP6V0A1", "ATP6V0A2", "ATP6V0A4"),
  "Synaptic Function" = c("SYN1", "SYN2", "SYN3", "SNAP25", "STX1A", "STX1B", "VAMP1", "VAMP2", "SYP", "PSD95", "GRIN1", "GRIN2A", "GRIN2B", "GABRA1", "GABRB1")
)

# Análisis de enriquecimiento de pathways
pathway_analysis <- data.frame()
for (pathway_name in names(als_pathways)) {
  pathway_genes <- als_pathways[[pathway_name]]
  
  # Contar genes diana en este pathway
  pathway_targets <- 0
  affected_mirnas <- c()
  
  for (i in 1:nrow(target_analysis)) {
    mirna_targets <- str_split(target_analysis$als_target_list[i], ",")[[1]]
    mirna_targets <- str_trim(mirna_targets)
    overlap <- intersect(mirna_targets, pathway_genes)
    
    if (length(overlap) > 0) {
      pathway_targets <- pathway_targets + length(overlap)
      affected_mirnas <- c(affected_mirnas, target_analysis$miRNA[i])
    }
  }
  
  if (pathway_targets > 0) {
    pathway_analysis <- rbind(pathway_analysis, data.frame(
      pathway = pathway_name,
      total_genes = length(pathway_genes),
      affected_genes = pathway_targets,
      affected_mirnas = length(unique(affected_mirnas)),
      mirna_list = paste(unique(affected_mirnas), collapse = ","),
      enrichment_ratio = pathway_targets / length(pathway_genes),
      stringsAsFactors = FALSE
    ))
  }
}

pathway_analysis <- pathway_analysis %>%
  arrange(desc(enrichment_ratio))

cat("   📊 Análisis de pathways completado\n")
cat("   📊 Pathways afectados:", nrow(pathway_analysis), "\n")

# 9. VISUALIZACIONES
cat("\n🎨 Creando visualizaciones...\n")

# Plot 1: Impacto funcional por posición
p1 <- ggplot(df_final, aes(x = factor(position), y = impact_score, fill = impact_level)) +
  geom_boxplot(alpha = 0.7) +
  scale_fill_manual(values = c("High" = "#E31A1C", "Medium" = "#FF7F00", "Low" = "#1F78B4", "Very Low" = "#33A02C")) +
  labs(title = "Functional Impact Score by Seed Region Position",
       x = "Position in Seed Region", y = "Impact Score", fill = "Impact Level") +
  theme_minimal() +
  theme(legend.position = "bottom")
ggsave("outputs/figures/functional_impact_by_position.png", p1, width = 10, height = 6)

# Plot 2: Top miRNAs por impacto funcional
top_mirnas <- df_final %>%
  group_by(miRNA.name) %>%
  summarise(
    max_impact = max(impact_score),
    mean_impact = mean(impact_score),
    total_mutations = n(),
    .groups = "drop"
  ) %>%
  arrange(desc(max_impact)) %>%
  head(15)

p2 <- ggplot(top_mirnas, aes(x = reorder(miRNA.name, max_impact), y = max_impact)) +
  geom_bar(stat = "identity", fill = "steelblue", alpha = 0.7) +
  coord_flip() +
  labs(title = "Top 15 miRNAs by Maximum Functional Impact Score",
       x = "miRNA", y = "Maximum Impact Score") +
  theme_minimal()
ggsave("outputs/figures/top_mirnas_impact.png", p2, width = 10, height = 8)

# Plot 3: Pathways enriquecidos
p3 <- ggplot(pathway_analysis, aes(x = reorder(pathway, enrichment_ratio), y = enrichment_ratio)) +
  geom_bar(stat = "identity", fill = "darkred", alpha = 0.7) +
  coord_flip() +
  labs(title = "ALS-Related Pathways Enrichment",
       x = "Pathway", y = "Enrichment Ratio") +
  theme_minimal()
ggsave("outputs/figures/pathway_enrichment.png", p3, width = 10, height = 8)

# Plot 4: Distribución de impacto funcional
p4 <- ggplot(df_final, aes(x = impact_level, fill = impact_level)) +
  geom_bar(alpha = 0.7) +
  scale_fill_manual(values = c("High" = "#E31A1C", "Medium" = "#FF7F00", "Low" = "#1F78B4", "Very Low" = "#33A02C")) +
  labs(title = "Distribution of Functional Impact Levels",
       x = "Impact Level", y = "Number of Mutations") +
  theme_minimal() +
  theme(legend.position = "none")
ggsave("outputs/figures/impact_level_distribution.png", p4, width = 8, height = 6)

# 10. GUARDAR RESULTADOS
cat("\n💾 Guardando resultados...\n")

write_tsv(df_final, "outputs/functional_analysis_mutations.tsv")
write_tsv(position_analysis, "outputs/functional_position_analysis.tsv")
write_tsv(mirna_analysis, "outputs/functional_mirna_analysis.tsv")
write_tsv(target_analysis, "outputs/functional_target_analysis.tsv")
write_tsv(pathway_analysis, "outputs/functional_pathway_analysis.tsv")

# 11. CREAR REPORTE
cat("\n📋 Creando reporte funcional...\n")

report_content <- c(
  "# ANÁLISIS FUNCIONAL COMPUTACIONAL - GENES ALS\n\n",
  "## Resumen del Análisis\n",
  paste0("- **Mutaciones G>T en región semilla analizadas**: ", nrow(df_final), "\n"),
  paste0("- **miRNAs únicos afectados**: ", length(unique(df_final$miRNA.name)), "\n"),
  paste0("- **Genes ALS identificados**: ", length(als_genes), "\n"),
  paste0("- **miRNAs con genes diana ALS**: ", nrow(target_analysis), "\n"),
  paste0("- **Pathways afectados**: ", nrow(pathway_analysis), "\n\n"),
  
  "## Análisis por Posición en Región Semilla\n",
  paste(
    sapply(1:nrow(position_analysis), function(i) {
      pos_data <- position_analysis[i, ]
      paste0("- **Posición ", pos_data$position, "**: ", pos_data$total_mutations, " mutaciones, ", pos_data$unique_mirnas, " miRNAs únicos, VAF ", formatC(pos_data$mean_vaf, format = "e", digits = 2), "\n")
    }),
    collapse = ""
  ),
  "\n## Top miRNAs por Impacto Funcional\n",
  paste(
    sapply(1:min(10, nrow(mirna_analysis)), function(i) {
      mirna_data <- mirna_analysis[i, ]
      paste0("- **", mirna_data$miRNA.name, "**: ", mirna_data$total_mutations, " mutaciones, posiciones ", mirna_data$positions, ", VAF ", formatC(mirna_data$mean_vaf, format = "e", digits = 2), "\n")
    }),
    collapse = ""
  ),
  "\n## Genes Diana ALS Identificados\n",
  if (nrow(target_analysis) > 0) {
    paste(
      sapply(1:nrow(target_analysis), function(i) {
        target_data <- target_analysis[i, ]
        paste0("- **", target_data$miRNA, "**: ", target_data$als_targets, " genes ALS (", target_data$als_target_list, ")\n")
      }),
      collapse = ""
    )
  } else {
    "- No se identificaron genes diana ALS específicos\n"
  },
  "\n## Pathways Más Afectados\n",
  paste(
    sapply(1:min(5, nrow(pathway_analysis)), function(i) {
      pathway_data <- pathway_analysis[i, ]
      paste0("- **", pathway_data$pathway, "**: ", pathway_data$affected_genes, " genes afectados, ratio ", round(pathway_data$enrichment_ratio, 3), "\n")
    }),
    collapse = ""
  ),
  "\n## Archivos Generados\n",
  "- `outputs/functional_analysis_mutations.tsv`: Mutaciones con scores de impacto\n",
  "- `outputs/functional_position_analysis.tsv`: Análisis por posición\n",
  "- `outputs/functional_mirna_analysis.tsv`: Análisis por miRNA\n",
  "- `outputs/functional_target_analysis.tsv`: Genes diana identificados\n",
  "- `outputs/functional_pathway_analysis.tsv`: Análisis de pathways\n",
  "- `outputs/figures/functional_*`: Visualizaciones\n",
  "- `outputs/functional_analysis_report.md`: Este reporte\n"
)

writeLines(report_content, "outputs/functional_analysis_report.md")

cat("\n🎉 Análisis funcional computacional completado!\n")
cat("   📊 Archivos generados:\n")
cat("   - outputs/functional_analysis_mutations.tsv\n")
cat("   - outputs/functional_position_analysis.tsv\n")
cat("   - outputs/functional_mirna_analysis.tsv\n")
cat("   - outputs/functional_target_analysis.tsv\n")
cat("   - outputs/functional_pathway_analysis.tsv\n")
cat("   - outputs/functional_analysis_report.md\n")
cat("   - outputs/figures/functional_*\n")











