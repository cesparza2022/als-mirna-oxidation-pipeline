# 🧬 MECHANISTIC VALIDATION FUNCTIONS - PIPELINE_2
# Functions for validating G>T as oxidative signature (no metadata required)

library(ggplot2)
library(dplyr)
library(tidyr)
library(stringr)
library(patchwork)
library(viridis)
library(scales)

## ═══════════════════════════════════════════════════════════════════════════
## COLOR PALETTE (NEUTRAL - NO GROUPS) - Updated v5
## ═══════════════════════════════════════════════════════════════════════════

COLOR_GT <- "#FF7F00"        # 🟠 ORANGE for G>T (neutral)
COLOR_GA <- "#3498DB"        # 🔵 BLUE for G>A
COLOR_GC <- "#2ECC71"        # 🟢 GREEN for G>C
COLOR_SEED <- "#FFD700"      # 🟡 GOLD for seed region
COLOR_NONSEED <- "#B0B0B0"   # ⚪ GREY for non-seed

# Oxidation levels (for Panel A)
COLOR_NO_OX <- "#95A5A6"     # ⚪ GREY (none)
COLOR_LOW_OX <- "#2ECC71"    # 🟢 GREEN (low)
COLOR_MED_OX <- "#F39C12"    # 🟡 YELLOW (medium)
COLOR_HIGH_OX <- "#E67E22"   # 🟠 DARK ORANGE (high, NOT red)

# NOTE: RED (#E31A1C) RESERVED for ALS in Figure 3+

## ═══════════════════════════════════════════════════════════════════════════
## PANEL A: G-CONTENT VS OXIDATION SUSCEPTIBILITY
## ═══════════════════════════════════════════════════════════════════════════

#' Create G-Content vs Oxidation Panel
#' 
#' Shows that miRNAs with more G's in seed region are more susceptible to G>T
#' 
#' @param gcontent_file Path to G-content analysis CSV
#' @return ggplot object
create_gcontent_vs_oxidation <- function(gcontent_file) {
  
  cat("📊 Panel A: G-Content vs Oxidation...\n")
  
  # Load data
  data <- read.csv(gcontent_file)
  
  # Calculate correlation
  cor_test <- cor.test(data$n_g_in_seed, data$perc_oxidados, method = "spearman")
  
  # Categorize oxidation level
  data <- data %>%
    mutate(
      oxidation_level = case_when(
        perc_oxidados == 0 ~ "None",
        perc_oxidados < 10 ~ "Low",
        perc_oxidados < 15 ~ "Medium",
        TRUE ~ "High"
      ),
      oxidation_level = factor(oxidation_level, 
                               levels = c("None", "Low", "Medium", "High"))
    )
  
  # Create plot
  p <- ggplot(data, aes(x = n_g_in_seed, y = perc_oxidados)) +
    # Trend line (UPDATED: Orange instead of red)
    geom_smooth(method = "loess", se = TRUE, color = COLOR_HIGH_OX, 
                fill = COLOR_HIGH_OX, alpha = 0.2, linewidth = 1.2) +
    
    # Points
    geom_point(aes(size = n_mirnas, fill = oxidation_level), 
               shape = 21, color = "black", alpha = 0.8, stroke = 1.2) +
    
    # Annotations for extreme points
    geom_text(data = data %>% filter(perc_oxidados > 15 | n_g_in_seed >= 5),
              aes(label = paste0(n_g_in_seed, "G: ", round(perc_oxidados, 1), "%")),
              vjust = -1.5, size = 3, fontface = "bold") +
    
    # Scales
    scale_size_continuous(
      range = c(3, 15),
      name = "Number of\nmiRNAs",
      breaks = c(100, 300, 500, 700),
      labels = comma
    ) +
    
    scale_fill_manual(
      values = c(
        "None" = COLOR_NO_OX,
        "Low" = COLOR_LOW_OX,
        "Medium" = COLOR_MED_OX,
        "High" = COLOR_HIGH_OX  # Orange, not red
      ),
      name = "Oxidation\nLevel"
    ) +
    
    scale_x_continuous(breaks = 0:7) +
    scale_y_continuous(breaks = seq(0, 25, by = 5), limits = c(0, 25)) +
    
    # Labels
    labs(
      title = "G-Content Determines Oxidation Susceptibility",
      subtitle = sprintf("Spearman's r = %.3f (p %s)", 
                        cor_test$estimate, 
                        ifelse(cor_test$p.value < 0.001, "< 0.001", 
                               sprintf("= %.3f", cor_test$p.value))),
      x = "Number of G's in Seed Region (positions 2-8)",
      y = "Percentage of miRNAs with G>T (%)"
    ) +
    
    # Theme
    theme_minimal(base_size = 11) +
    theme(
      plot.title = element_text(face = "bold", size = 12, hjust = 0.5),
      plot.subtitle = element_text(size = 10, hjust = 0.5, color = "gray40"),
      legend.position = "right",
      legend.title = element_text(face = "bold", size = 10),
      legend.text = element_text(size = 9),
      axis.title = element_text(face = "bold", size = 10),
      panel.grid.minor = element_blank()
    )
  
  cat("  ✅ Panel A created (r = ", round(cor_test$estimate, 3), ")\n")
  
  return(p)
}

## ═══════════════════════════════════════════════════════════════════════════
## PANEL B: SEQUENCE CONTEXT ANALYSIS
## ═══════════════════════════════════════════════════════════════════════════

#' Analyze Sequence Context Around G>T Sites
#' 
#' Examines what nucleotides flank G>T mutations (expected: GG, GC enrichment)
#' 
#' @param processed_data Processed mutation data with positions
#' @param mirna_sequences Optional: miRNA sequences for context extraction
#' @return ggplot object
analyze_sequence_context <- function(processed_data, mirna_sequences = NULL) {
  
  cat("📊 Panel B: Sequence Context...\n")
  
  # Filter G>T mutations
  gt_data <- processed_data %>%
    filter(`pos:mut` != "PM") %>%
    separate(`pos:mut`, into = c("position", "mutation_type"), sep = ":", remove = FALSE) %>%
    filter(mutation_type == "GT") %>%
    mutate(position = as.numeric(position)) %>%
    filter(position >= 2 & position <= 21) # Need ±1 position available
  
  if (nrow(gt_data) == 0) {
    cat("  ⚠️  No G>T mutations found for context analysis\n")
    return(ggplot() + 
           annotate("text", x = 0.5, y = 0.5, 
                    label = "Sequence context analysis requires miRNA sequences", 
                    size = 4) +
           labs(title = "B. Sequence Context (Pending)") +
           theme_void())
  }
  
  # For now, create a placeholder showing we need sequences
  # In a future version, this will extract actual sequence context
  
  cat("  ⚠️  Sequence context analysis requires miRNA reference sequences\n")
  cat("  💡 Future: Will show enrichment of GG, GC contexts around G>T\n")
  
  # Placeholder visualization
  p <- ggplot() +
    annotate("text", x = 0.5, y = 0.5, 
             label = paste0("Sequence Context Analysis\n\n",
                           "Pending: Requires miRNA sequences\n",
                           nrow(gt_data), " G>T sites ready for analysis"),
             size = 5, color = "darkgrey", fontface = "bold") +
    labs(title = "B. Sequence Context Around G>T Sites",
         subtitle = "Expected: Enrichment of GG, GC contexts (8-oxoG signature)") +
    theme_void() +
    theme(plot.title = element_text(size = 12, face = "bold", hjust = 0.5),
          plot.subtitle = element_text(size = 10, hjust = 0.5, color = "gray50"))
  
  return(p)
}

## ═══════════════════════════════════════════════════════════════════════════
## PANEL C: G>T SPECIFICITY ANALYSIS
## ═══════════════════════════════════════════════════════════════════════════

#' Calculate G>T Specificity
#' 
#' Shows that G>T is specifically enriched, not all G>X mutations equally
#' 
#' @param processed_data Processed mutation data
#' @return ggplot object
calculate_gt_specificity <- function(processed_data) {
  
  cat("📊 Panel C: G>T Specificity...\n")
  
  # Process data for all G>X mutations
  gx_data <- processed_data %>%
    filter(`pos:mut` != "PM") %>%
    separate(`pos:mut`, into = c("position", "mutation_type"), sep = ":", remove = FALSE) %>%
    filter(str_detect(mutation_type, "^G")) %>%  # G>T, G>A, G>C
    mutate(
      position = as.numeric(position),
      mutation_type_formatted = case_when(
        mutation_type == "GT" ~ "G>T",
        mutation_type == "GA" ~ "G>A", 
        mutation_type == "GC" ~ "G>C",
        TRUE ~ mutation_type
      )
    ) %>%
    filter(position >= 1 & position <= 22)
  
  if (nrow(gx_data) == 0) {
    return(ggplot() + theme_void() + labs(title = "C. G>T Specificity"))
  }
  
  # Calculate fractions per position
  specificity_data <- gx_data %>%
    count(position, mutation_type_formatted) %>%
    group_by(position) %>%
    mutate(
      total_gx = sum(n),
      fraction = n / total_gx,
      percentage = fraction * 100
    ) %>%
    ungroup()
  
  # Create plot - Stacked bars showing G>T dominance
  p <- ggplot(specificity_data, aes(x = factor(position), y = percentage, 
                                    fill = mutation_type_formatted)) +
    geom_col(position = "stack", color = "white", linewidth = 0.3) +
    
    # Highlight G>T specifically (UPDATED: Orange, not red)
    scale_fill_manual(
      values = c(
        "G>T" = COLOR_GT,   # 🟠 Orange for G>T
        "G>A" = COLOR_GA,   # 🔵 Blue
        "G>C" = COLOR_GC    # 🟢 Green
      ),
      name = "G>X Type"
    ) +
    
    # Add percentage labels for G>T
    geom_text(
      data = specificity_data %>% filter(mutation_type_formatted == "G>T"),
      aes(label = ifelse(percentage > 15, paste0(round(percentage, 0), "%"), "")),
      position = position_stack(vjust = 0.5),
      size = 3, color = "white", fontface = "bold"
    ) +
    
    scale_y_continuous(breaks = seq(0, 100, by = 25), 
                      labels = function(x) paste0(x, "%")) +
    
    labs(
      title = "G>T Specificity: Proportion of G>X Mutations",
      subtitle = "Red = G>T (oxidative signature) | Blue = G>A | Green = G>C",
      x = "Position in miRNA",
      y = "Percentage of G>X Mutations"
    ) +
    
    theme_minimal(base_size = 11) +
    theme(
      plot.title = element_text(face = "bold", size = 12, hjust = 0.5),
      plot.subtitle = element_text(size = 9, hjust = 0.5, color = "gray40"),
      axis.text.x = element_text(angle = 45, hjust = 1, size = 9),
      legend.title = element_text(face = "bold", size = 10),
      legend.text = element_text(size = 9),
      panel.grid.minor = element_blank()
    )
  
  # Calculate overall G>T fraction
  overall_gt_frac <- specificity_data %>%
    group_by(mutation_type_formatted) %>%
    summarise(total_n = sum(n), .groups = 'drop') %>%
    mutate(overall_frac = total_n / sum(total_n)) %>%
    filter(mutation_type_formatted == "G>T") %>%
    pull(overall_frac)
  
  cat("  ✅ Panel C created (Overall G>T: ", round(overall_gt_frac * 100, 1), "% of G>X)\n")
  
  return(p)
}

## ═══════════════════════════════════════════════════════════════════════════
## PANEL D: POSITION-LEVEL G-CONTENT CORRELATION
## ═══════════════════════════════════════════════════════════════════════════

#' Position-Level G-Content Analysis
#' 
#' Shows correlation between G-richness and G>T frequency at each position
#' 
#' @param processed_data Processed mutation data
#' @return ggplot object
position_gcontent_correlation <- function(processed_data) {
  
  cat("📊 Panel D: Position-Level G-Content...\n")
  
  # Calculate G>T frequency per position
  gt_per_position <- processed_data %>%
    filter(`pos:mut` != "PM") %>%
    separate(`pos:mut`, into = c("position", "mutation_type"), sep = ":", remove = FALSE) %>%
    mutate(position = as.numeric(position)) %>%
    filter(position >= 1 & position <= 22) %>%
    count(position, mutation_type) %>%
    group_by(position) %>%
    mutate(
      total_at_pos = sum(n),
      is_gt = mutation_type == "GT"
    ) %>%
    filter(is_gt) %>%
    mutate(gt_fraction = n / total_at_pos * 100) %>%
    ungroup() %>%
    select(position, gt_fraction, n_gt = n)
  
  # Complete missing positions with 0
  gt_per_position <- gt_per_position %>%
    complete(position = 1:22, fill = list(gt_fraction = 0, n_gt = 0))
  
  # Mark seed region
  gt_per_position <- gt_per_position %>%
    mutate(region = ifelse(position >= 2 & position <= 8, "Seed", "Non-Seed"))
  
  # Create barplot (UPDATED: Gold for seed)
  p <- ggplot(gt_per_position, aes(x = factor(position), y = gt_fraction, fill = region)) +
    geom_col(alpha = 0.8, color = "black", linewidth = 0.3) +
    
    scale_fill_manual(
      values = c("Seed" = COLOR_SEED, "Non-Seed" = COLOR_NONSEED),
      name = "miRNA Region"
    ) +
    
    scale_y_continuous(
      breaks = seq(0, max(gt_per_position$gt_fraction) + 5, by = 2),
      labels = function(x) paste0(x, "%"),
      expand = expansion(mult = c(0, 0.1))
    ) +
    
    labs(
      title = "G>T Frequency by Position",
      subtitle = "Seed region (2-8) highlighted in orange",
      x = "Position in miRNA",
      y = "G>T as % of All Mutations at Position"
    ) +
    
    theme_minimal(base_size = 11) +
    theme(
      plot.title = element_text(face = "bold", size = 12, hjust = 0.5),
      plot.subtitle = element_text(size = 9, hjust = 0.5, color = "gray40"),
      axis.text.x = element_text(size = 9),
      legend.position = "right",
      legend.title = element_text(face = "bold", size = 10),
      panel.grid.minor = element_blank()
    )
  
  cat("  ✅ Panel D created\n")
  
  return(p)
}

## ═══════════════════════════════════════════════════════════════════════════
## MAIN FUNCTION: CREATE FIGURE 2 (MECHANISTIC VALIDATION)
## ═══════════════════════════════════════════════════════════════════════════

#' Create Complete Figure 2: Mechanistic Validation
#' 
#' Combines all mechanistic validation panels
#' 
#' @param processed_data Processed data from Step 1
#' @param gcontent_file Path to G-content analysis CSV
#' @param output_dir Directory to save figure
#' @return Combined figure (patchwork object)
create_figure_2_mechanistic <- function(processed_data, gcontent_file, output_dir) {
  
  cat("\n🎨 ═══════════════════════════════════════════════════════════\n")
  cat("   GENERATING FIGURE 2: MECHANISTIC VALIDATION\n")
  cat("   ═══════════════════════════════════════════════════════════\n\n")
  
  # Create output directory
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  
  # Generate panels
  panel_a <- create_gcontent_vs_oxidation(gcontent_file)
  panel_b <- analyze_sequence_context(processed_data, mirna_sequences = NULL)
  panel_c <- calculate_gt_specificity(processed_data)
  panel_d <- position_gcontent_correlation(processed_data)
  
  cat("\n")
  
  # Combine panels
  figure_2 <- (panel_a | panel_b) / (panel_c | panel_d) +
    plot_annotation(
      title = "FIGURE 2: Mechanistic Validation of G>T as Oxidative Signature",
      subtitle = "Evidence that G>T mutations reflect 8-oxoguanine damage patterns",
      theme = theme(
        plot.title = element_text(size = 18, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray30")
      )
    )
  
  # Save complete figure
  ggsave(
    filename = file.path(output_dir, "figure_2_mechanistic_validation.png"),
    plot = figure_2,
    width = 20, height = 16, dpi = 300, bg = "white"
  )
  
  # Save individual panels
  ggsave(file.path(output_dir, "panel_a_gcontent.png"), 
         plot = panel_a, width = 10, height = 8, dpi = 300, bg = "white")
  ggsave(file.path(output_dir, "panel_b_context.png"), 
         plot = panel_b, width = 10, height = 8, dpi = 300, bg = "white")
  ggsave(file.path(output_dir, "panel_c_specificity.png"), 
         plot = panel_c, width = 10, height = 8, dpi = 300, bg = "white")
  ggsave(file.path(output_dir, "panel_d_position.png"), 
         plot = panel_d, width = 10, height = 8, dpi = 300, bg = "white")
  
  cat("\n✅ FIGURE 2 GENERATED SUCCESSFULLY\n")
  cat("📁 Main figure: ", file.path(output_dir, "figure_2_mechanistic_validation.png"), "\n")
  cat("📁 Individual panels also saved\n\n")
  
  return(figure_2)
}

## ═══════════════════════════════════════════════════════════════════════════
## HELPER FUNCTIONS
## ═══════════════════════════════════════════════════════════════════════════

#' Summary Statistics for Mechanistic Validation
#' 
#' @param processed_data Processed mutation data
#' @param gcontent_file Path to G-content analysis CSV
#' @return List of summary statistics
mechanistic_summary_stats <- function(processed_data, gcontent_file) {
  
  # G-content correlation
  gcontent <- read.csv(gcontent_file)
  cor_test <- cor.test(gcontent$n_g_in_seed, gcontent$perc_oxidados, 
                      method = "spearman")
  
  # G>T vs other G>X
  gx_data <- processed_data %>%
    filter(`pos:mut` != "PM") %>%
    separate(`pos:mut`, into = c("position", "mutation_type"), sep = ":", remove = FALSE) %>%
    filter(str_detect(mutation_type, "^G")) %>%
    count(mutation_type) %>%
    mutate(fraction = n / sum(n))
  
  gt_fraction_of_gx <- gx_data %>%
    filter(mutation_type == "GT") %>%
    pull(fraction)
  
  # Compile summary
  summary <- list(
    gcontent_correlation = cor_test$estimate,
    gcontent_pvalue = cor_test$p.value,
    gt_fraction_of_gx = gt_fraction_of_gx,
    total_gx_mutations = sum(gx_data$n),
    gt_mutations = gx_data %>% filter(mutation_type == "GT") %>% pull(n)
  )
  
  return(summary)
}
