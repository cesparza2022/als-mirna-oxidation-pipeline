# 🌐 PROFESSIONAL VIEWER - FIGURES + TABLES

rm(list = ls())

library(tidyverse)

base_dir <- "/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/pipeline_definitivo/pipeline_2"

cat("🌐 Creating PROFESSIONAL Master Viewer (Figures + Tables)...\n\n")

## Load tables for embedding
table1 <- read.csv(file.path(base_dir, "tables/table1_dataset_summary.csv"))
table2 <- read.csv(file.path(base_dir, "tables/table2_mutation_types.csv"))
table3 <- read.csv(file.path(base_dir, "tables/table3_gt_by_position.csv"))
table4 <- read.csv(file.path(base_dir, "tables/table4_seed_vs_nonseed.csv"))
table5 <- read.csv(file.path(base_dir, "tables/table5_top_mirnas.csv"))
table6 <- read.csv(file.path(base_dir, "tables/table6_gcontent_correlation.csv"))

## Convert tables to HTML
table_to_html <- function(df, caption) {
  html_table <- '<table class="data-table">'
  html_table <- paste0(html_table, '<caption>', caption, '</caption>')
  html_table <- paste0(html_table, '<thead><tr>')
  
  # Headers
  for (col in names(df)) {
    html_table <- paste0(html_table, '<th>', col, '</th>')
  }
  html_table <- paste0(html_table, '</tr></thead><tbody>')
  
  # Rows
  for (i in 1:nrow(df)) {
    html_table <- paste0(html_table, '<tr>')
    for (col in names(df)) {
      html_table <- paste0(html_table, '<td>', df[i, col], '</td>')
    }
    html_table <- paste0(html_table, '</tr>')
  }
  
  html_table <- paste0(html_table, '</tbody></table>')
  return(html_table)
}

cat("📊 Converting tables to HTML...\n")

html_t1 <- table_to_html(table1, "TABLE 1: Dataset Summary Statistics")
html_t2 <- table_to_html(head(table2, 10), "TABLE 2: Mutation Type Distribution (Top 10)")
html_t3 <- table_to_html(table3, "TABLE 3: G>T Distribution by Position")
html_t4 <- table_to_html(table4, "TABLE 4: Seed vs Non-Seed Summary")
html_t5 <- table_to_html(head(table5, 15), "TABLE 5: Top 15 miRNAs with G>T")
html_t6 <- table_to_html(table6, "TABLE 6: G-Content vs Oxidation Correlation")

cat("✅ Tables converted\n\n")

## Generate complete HTML
html_content <- paste0('<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Pipeline_2 Professional Viewer</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600;700&display=swap" rel="stylesheet">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: "Inter", -apple-system, sans-serif; 
            background: #f8fafc; 
            color: #1e293b; 
        }
        
        .header {
            background: linear-gradient(135deg, #1e293b 0%, #334155 100%);
            color: white;
            padding: 60px 40px;
            text-align: center;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        
        .header h1 {
            font-size: 3em;
            margin-bottom: 15px;
            font-weight: 700;
        }
        
        .nav {
            background: white;
            display: flex;
            justify-content: center;
            padding: 0;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            position: sticky;
            top: 0;
            z-index: 1000;
        }
        
        .nav-btn {
            padding: 20px 40px;
            border: none;
            background: white;
            color: #475569;
            font-size: 1em;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s;
            border-bottom: 3px solid transparent;
        }
        
        .nav-btn:hover {
            background: #f1f5f9;
            color: #0f172a;
        }
        
        .nav-btn.active {
            color: #3b82f6;
            border-bottom-color: #3b82f6;
            background: #eff6ff;
        }
        
        .content {
            max-width: 1400px;
            margin: 0 auto;
            padding: 40px 20px;
        }
        
        .tab-pane {
            display: none;
        }
        
        .tab-pane.active {
            display: block;
        }
        
        .figure-section {
            background: white;
            border-radius: 12px;
            padding: 40px;
            margin-bottom: 40px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.08);
        }
        
        .figure-section h2 {
            color: #0f172a;
            margin-bottom: 25px;
            font-size: 1.8em;
            border-bottom: 3px solid #3b82f6;
            padding-bottom: 15px;
        }
        
        .figure-section img {
            width: 100%;
            border-radius: 8px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
            margin: 20px 0;
            cursor: zoom-in;
            transition: transform 0.2s;
        }
        
        .figure-section img:hover {
            transform: scale(1.01);
        }
        
        .panel-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 25px;
            margin-top: 30px;
        }
        
        .panel-item {
            background: #f8fafc;
            padding: 20px;
            border-radius: 8px;
            border: 1px solid #e2e8f0;
        }
        
        .panel-item h4 {
            color: #0f172a;
            margin-bottom: 10px;
        }
        
        .data-table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
            background: white;
            box-shadow: 0 2px 8px rgba(0,0,0,0.05);
        }
        
        .data-table caption {
            font-size: 1.3em;
            font-weight: 700;
            color: #0f172a;
            margin-bottom: 15px;
            text-align: left;
        }
        
        .data-table th {
            background: #3b82f6;
            color: white;
            padding: 15px;
            text-align: left;
            font-weight: 600;
        }
        
        .data-table td {
            padding: 12px 15px;
            border-bottom: 1px solid #e2e8f0;
        }
        
        .data-table tbody tr:hover {
            background: #f1f5f9;
        }
        
        .data-table tr:nth-child(even) {
            background: #f8fafc;
        }
        
        .highlight-row {
            background: #fef3c7 !important;
            font-weight: 600;
        }
        
        .badge {
            display: inline-block;
            padding: 6px 14px;
            border-radius: 20px;
            font-size: 0.9em;
            font-weight: 600;
            margin: 5px;
        }
        
        .badge-success { background: #10b981; color: white; }
        .badge-info { background: #3b82f6; color: white; }
        .badge-warning { background: #f59e0b; color: white; }
        
        .download-btn {
            background: #3b82f6;
            color: white;
            padding: 10px 20px;
            border-radius: 6px;
            text-decoration: none;
            display: inline-block;
            margin: 10px 5px;
            font-weight: 600;
            transition: background 0.3s;
        }
        
        .download-btn:hover {
            background: #2563eb;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🎨 Pipeline_2 Professional Report</h1>
        <p style=\"font-size: 1.3em; margin-top: 10px;\">miRNA G>T Oxidative Stress Analysis</p>
        <div style=\"margin-top: 20px;\">
            <span class=\"badge badge-success\">v0.4.1 Professional</span>
            <span class=\"badge badge-info\">3 Figures + 6 Tables</span>
            <span class=\"badge badge-warning\">10/16 Questions (63%)</span>
        </div>
    </div>

    <nav class=\"nav\">
        <button class=\"nav-btn active\" onclick=\"showTab(\'fig1\')\">📊 Figure 1</button>
        <button class=\"nav-btn\" onclick=\"showTab(\'fig2\')\">🔬 Figure 2</button>
        <button class=\"nav-btn\" onclick=\"showTab(\'fig3\')\">🔴 Figure 3</button>
        <button class=\"nav-btn\" onclick=\"showTab(\'tables\')\">📋 Tables</button>
    </nav>

    <div class=\"content\">
        
        <!-- FIGURE 1 -->
        <div id=\"fig1\" class=\"tab-pane active\">
            <div class=\"figure-section\">
                <h2>FIGURE 1: Dataset Characterization</h2>
                <p><em>Baseline characterization | Questions: SQ1.1, SQ1.2, SQ1.3</em></p>
                
                <div class=\"panel-grid\">
                    <div class=\"panel-item\">
                        <h4>Panel A: Dataset Evolution + Mutation Types</h4>
                        <p>✅ Improved: Pie → Horizontal bars (more readable)</p>
                        <img src=\"figures/panel_a_overview_PROFESSIONAL.png\">
                    </div>
                    <div class=\"panel-item\">
                        <h4>Panel B: G>T Positional Distribution</h4>
                        <p>Professional style with seed region highlighted</p>
                        <img src=\"figures/panel_b_positional_PROFESSIONAL.png\">
                    </div>
                    <div class=\"panel-item\">
                        <h4>Panel C: G>X Mutation Spectrum</h4>
                        <p>Horizontal bars, G>T highlighted in orange</p>
                        <img src=\"figures/panel_c_spectrum_PROFESSIONAL.png\">
                    </div>
                    <div class=\"panel-item\">
                        <h4>Panel D: Top 15 miRNAs with G>T (NEW!)</h4>
                        <p>✨ Biomarker candidates</p>
                        <img src=\"figures/panel_d_top_mirnas_PROFESSIONAL.png\">
                    </div>
                </div>
            </div>
        </div>

        <!-- FIGURE 2 -->
        <div id=\"fig2\" class=\"tab-pane\">
            <div class=\"figure-section\">
                <h2>FIGURE 2: Mechanistic Validation</h2>
                <p><em>G>T as oxidative signature | Questions: SQ3.1, SQ3.2, SQ3.3</em></p>
                
                <div class=\"panel-grid\">
                    <div class=\"panel-item\">
                        <h4>Panel A: G-Content Correlation</h4>
                        <p>✅ Professional style | Spearman r = 0.347</p>
                        <img src=\"figures/panel_a_gcontent_PROFESSIONAL.png\">
                    </div>
                    <div class=\"panel-item\">
                        <h4>Panel B: Sequence Context</h4>
                        <p>Placeholder (requires reference sequences)</p>
                        <img src=\"figures/panel_b_context.png\">
                    </div>
                    <div class=\"panel-item\">
                        <h4>Panel C: G>T Specificity</h4>
                        <p>31.6% of all G>X mutations</p>
                        <img src=\"figures/panel_c_specificity.png\">
                    </div>
                    <div class=\"panel-item\">
                        <h4>Panel D: Position G-Content</h4>
                        <p>Seed region highlighted</p>
                        <img src=\"figures/panel_d_position.png\">
                    </div>
                </div>
            </div>
        </div>

        <!-- FIGURE 3 -->
        <div id=\"fig3\" class=\"tab-pane\">
            <div class=\"figure-section\">
                <h2>FIGURE 3: Group Comparison (ALS vs Control)</h2>
                <p><em>Statistical comparison with FDR correction | Questions: SQ2.1-2.4 | 🔴 ALS vs ⚪ Control</em></p>
                
                <div class=\"panel-grid\">
                    <div class=\"panel-item\">
                        <h4>Panel A: Global G>T Burden</h4>
                        <p>Violin + boxplot | Wilcoxon test</p>
                        <img src=\"figures/panel_a_global_burden_PROFESSIONAL.png\">
                    </div>
                    <div class=\"panel-item\" style=\"border: 3px solid #D62728;\">
                        <h4>⭐ Panel B: Position Delta (YOUR FAVORITE)</h4>
                        <p><strong>Professional style</strong> | theme_classic | Grey shading | Asterisks</p>
                        <img src=\"figures/panel_b_position_delta_IMPROVED.png\">
                    </div>
                    <div class=\"panel-item\">
                        <h4>Panel C: Seed Interaction</h4>
                        <p>Fisher\'s exact test for region × group</p>
                        <img src=\"figures/panel_c_seed_interaction_PROFESSIONAL.png\">
                    </div>
                    <div class=\"panel-item\">
                        <h4>Panel D: Differential miRNAs</h4>
                        <p>Volcano plot with q-value thresholds</p>
                        <img src=\"figures/panel_d_volcano_PROFESSIONAL.png\">
                    </div>
                </div>
            </div>
        </div>

        <!-- TABLES -->
        <div id=\"tables\" class=\"tab-pane\">
            <div class=\"figure-section\">
                <h2>📋 Supplementary Tables</h2>
                <p><em>Publication-ready tables (CSV format available for download)</em></p>
                
                <div style=\"margin: 20px 0;\">
                    <a href=\"tables/table1_dataset_summary.csv\" class=\"download-btn\" download>⬇ Download All Tables (ZIP)</a>
                </div>
                
                ', html_t1, '
                ', html_t2, '
                ', html_t3, '
                ', html_t4, '
                ', html_t5, '
                ', html_t6, '
            </div>
        </div>
        
    </div>

    <script>
        function showTab(tabName) {
            document.querySelectorAll(\'.tab-pane\').forEach(pane => pane.classList.remove(\'active\'));
            document.querySelectorAll(\'.nav-btn\').forEach(btn => btn.classList.remove(\'active\'));
            
            document.getElementById(tabName).classList.add(\'active\');
            event.target.classList.add(\'active\');
        }

        // Click to zoom images
        document.querySelectorAll(\'img\').forEach(img => {
            img.onclick = function() {
                window.open(this.src, \'_blank\');
            }
        });
    </script>
</body>
</html>')

## Save
html_file <- file.path(base_dir, "PROFESSIONAL_VIEWER.html")
writeLines(html_content, html_file)

cat("✅ PROFESSIONAL VIEWER created\n")
cat("📁 Location:", html_file, "\n")
cat("🌐 Opening in browser...\n\n")

browseURL(html_file)

cat("🎉 COMPLETE!\n")
cat("   • 3 Figures (professional style)\n")
cat("   • 6 Tables (integrated)\n")
cat("   • All in one HTML file\n\n")

