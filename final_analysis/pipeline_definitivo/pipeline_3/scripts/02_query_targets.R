# ============================================================================
# PASO 3.2: TARGET PREDICTION
# Consulta bases de datos para identificar genes regulados por los 3 miRNAs
# ============================================================================

library(dplyr)
library(tidyr)
library(stringr)
library(multiMiR)
library(httr)
library(jsonlite)

cat("🎯 PASO 3.2: TARGET PREDICTION\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

# Cargar candidatos
candidates <- readRDS("data/candidates_als.rds")
config <- read_json("data/paso3_config.json")

cat("📊 Candidatos a analizar:", nrow(candidates), "\n")
for (i in 1:nrow(candidates)) {
  cat(sprintf("   %d. %s\n", i, candidates$miRNA[i]))
}
cat("\n")

# ============================================================================
# FUNCIÓN PARA QUERY DE TARGETS
# ============================================================================

query_targets_for_mirna <- function(mirna_name) {
  cat("📊 Consultando targets para:", mirna_name, "...\n")
  
  # Query a múltiples bases de datos
  targets_raw <- tryCatch({
    multiMiR::get_multimir(
      mirna = mirna_name,
      summary = TRUE,
      table = "all"  # validated + predicted
    )
  }, error = function(e) {
    cat("   ⚠️  Error en query:", e$message, "\n")
    return(NULL)
  })
  
  if (is.null(targets_raw) || nrow(targets_raw@data) == 0) {
    cat("   ❌ No se encontraron targets\n\n")
    return(data.frame())
  }
  
  # Procesar resultados
  targets_df <- targets_raw@data %>%
    as.data.frame() %>%
    dplyr::select(
      database, target_symbol, target_entrez, target_ensembl,
      experiment = matches("experiment|validation"),
      pubmed_id = matches("pubmed"),
      score = matches("score")
    ) %>%
    mutate(miRNA = mirna_name)
  
  cat("   ✅", nrow(targets_df), "targets encontrados\n")
  
  # Clasificar por confianza
  targets_processed <- targets_df %>%
    mutate(
      Evidence_Level = case_when(
        database == "mirecords" | database == "mirtarbase" ~ "Validated",
        database == "targetscan" ~ "Strong_Prediction",
        TRUE ~ "Prediction"
      ),
      Confidence_Score = case_when(
        Evidence_Level == "Validated" ~ 3,
        Evidence_Level == "Strong_Prediction" ~ 2,
        TRUE ~ 1
      )
    ) %>%
    filter(!is.na(target_symbol), target_symbol != "", trimws(target_symbol) != "") %>%
    group_by(target_symbol) %>%
    summarise(
      miRNA = dplyr::first(miRNA),
      N_Databases = n(),
      Databases = paste(unique(database), collapse = ", "),
      Max_Confidence = max(Confidence_Score),
      Evidence_Level = dplyr::first(Evidence_Level[which.max(Confidence_Score)]),
      target_entrez = dplyr::first(target_entrez),
      .groups = "drop"
    ) %>%
    arrange(desc(Max_Confidence), desc(N_Databases))
  
  # Filtrar high confidence (>=2 DBs o validados)
  targets_high_conf <- targets_processed %>%
    filter(N_Databases >= config$thresholds$min_databases | 
           Evidence_Level == "Validated")
  
  cat("   ✅", nrow(targets_high_conf), "targets high-confidence\n")
  cat("   📊 Validados:", sum(targets_processed$Evidence_Level == "Validated"), "\n\n")
  
  return(list(
    all = targets_processed,
    high_confidence = targets_high_conf
  ))
}

# ============================================================================
# QUERY PARA CADA CANDIDATO
# ============================================================================

all_targets <- list()
high_conf_targets <- list()

for (i in 1:nrow(candidates)) {
  mirna <- candidates$miRNA[i]
  cat(paste(rep("-", 70), collapse = ""), "\n")
  cat(sprintf("[%d/%d] %s\n", i, nrow(candidates), mirna))
  cat(paste(rep("-", 70), collapse = ""), "\n")
  
  result <- query_targets_for_mirna(mirna)
  
  if (nrow(result$all) > 0) {
    all_targets[[mirna]] <- result$all
    high_conf_targets[[mirna]] <- result$high_confidence
    
    # Guardar individual
    safe_name <- str_replace_all(mirna, "-", "_")
    write.csv(result$all, 
              paste0("data/targets/targets_", safe_name, "_all.csv"), 
              row.names = FALSE)
    write.csv(result$high_confidence, 
              paste0("data/targets/targets_", safe_name, "_highconf.csv"), 
              row.names = FALSE)
  }
  
  # Pausa para no sobrecargar API
  Sys.sleep(2)
}

# ============================================================================
# CONSOLIDAR RESULTADOS
# ============================================================================

cat("\n", paste(rep("=", 70), collapse = ""), "\n")
cat("📊 CONSOLIDANDO RESULTADOS\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

# Combinar todos los targets
all_targets_combined <- bind_rows(all_targets)
high_conf_combined <- bind_rows(high_conf_targets)

cat("✅ Total targets (all):", nrow(all_targets_combined), "\n")
cat("✅ Total targets (high-conf):", nrow(high_conf_combined), "\n\n")

# Identificar targets compartidos
shared_targets <- high_conf_combined %>%
  group_by(target_symbol) %>%
  summarise(
    N_miRNAs = n(),
    miRNAs = paste(unique(miRNA), collapse = ", "),
    N_Databases_Total = sum(N_Databases),
    Max_Confidence = max(Max_Confidence),
    .groups = "drop"
  ) %>%
  filter(N_miRNAs >= 2) %>%
  arrange(desc(N_miRNAs), desc(Max_Confidence))

cat("🔗 Targets compartidos (2+ miRNAs):", nrow(shared_targets), "\n")
if (nrow(shared_targets) > 0) {
  cat("\n🔝 TOP 10 SHARED TARGETS:\n")
  print(head(shared_targets, 10))
}
cat("\n")

# Guardar archivos consolidados
write.csv(all_targets_combined, "data/targets/targets_all_combined.csv", row.names = FALSE)
write.csv(high_conf_combined, "data/targets/targets_highconf_combined.csv", row.names = FALSE)
write.csv(shared_targets, "data/targets/targets_shared.csv", row.names = FALSE)

# ============================================================================
# ESTADÍSTICAS POR miRNA
# ============================================================================

cat("📊 ESTADÍSTICAS POR miRNA:\n")
cat(paste(rep("-", 70), collapse = ""), "\n")

stats_summary <- high_conf_combined %>%
  group_by(miRNA) %>%
  summarise(
    N_Targets = n(),
    N_Validated = sum(Evidence_Level == "Validated"),
    N_Predicted = sum(Evidence_Level != "Validated"),
    Pct_Validated = round(N_Validated / N_Targets * 100, 1),
    .groups = "drop"
  )

print(stats_summary)
cat("\n")

write.csv(stats_summary, "data/targets/summary_by_mirna.csv", row.names = FALSE)

# ============================================================================
# RESUMEN FINAL
# ============================================================================

cat(paste(rep("=", 70), collapse = ""), "\n")
cat("✅ TARGET PREDICTION COMPLETADO\n")
cat(paste(rep("=", 70), collapse = ""), "\n\n")

cat("📁 ARCHIVOS GENERADOS:\n")
cat("   • ALS_candidates.csv\n")
cat("   • paso3_config.json\n")
cat("   • candidates_als.rds\n")
cat("   • targets/targets_*_all.csv (", nrow(candidates), " archivos)\n")
cat("   • targets/targets_*_highconf.csv (", nrow(candidates), " archivos)\n")
cat("   • targets/targets_all_combined.csv\n")
cat("   • targets/targets_highconf_combined.csv\n")
cat("   • targets/targets_shared.csv\n")
cat("   • targets/summary_by_mirna.csv\n\n")

cat("📊 RESUMEN:\n")
cat("   Total targets (all):", nrow(all_targets_combined), "\n")
cat("   Total targets (high-conf):", nrow(high_conf_combined), "\n")
cat("   Targets compartidos:", nrow(shared_targets), "\n")
cat("   Targets únicos:", length(unique(high_conf_combined$target_symbol)), "\n\n")

cat("🚀 SIGUIENTE: Pathway Enrichment\n")
cat("   Rscript scripts/03_pathway_enrichment.R\n\n")

cat("💾 Datos guardados para análisis downstream\n")

