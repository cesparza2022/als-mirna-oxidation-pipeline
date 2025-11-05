# 🌐 HTML MASTER VIEWER - TODAS LAS FIGURAS EN UN SOLO LUGAR

rm(list = ls())

library(tidyverse)

## ═══════════════════════════════════════════════════════════════════════════
## CONFIGURATION
## ═══════════════════════════════════════════════════════════════════════════

base_dir <- "/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/pipeline_definitivo/pipeline_2"

# Figure paths
figures <- list(
  fig1_main = "figures/figure_1_v5_updated_colors.png",
  fig2_main = "figures/figure_2_mechanistic_validation.png",
  fig3_main = "figures/figure_3_group_comparison_REAL.png",
  
  # Figure 1 panels
  fig1_a = "figures/panel_a_overview_v5.png",
  fig1_b = "figures/panel_b_gt_analysis_v5.png",
  fig1_c = "figures/panel_c_spectrum_v5.png",
  fig1_d = "figures/panel_d_placeholder_v5.png",
  
  # Figure 2 panels
  fig2_a = "figures/panel_a_gcontent.png",
  fig2_b = "figures/panel_b_context.png",
  fig2_c = "figures/panel_c_specificity.png",
  fig2_d = "figures/panel_d_position.png",
  
  # Figure 3 panels (REAL)
  fig3_a = "figures/panel_a_global_burden_REAL.png",
  fig3_b = "figures/panel_b_position_delta_REAL.png",
  fig3_c = "figures/panel_c_seed_interaction_REAL.png",
  fig3_d = "figures/panel_d_volcano_REAL.png"
)

# Check which figures exist
figures_exist <- sapply(figures, function(f) file.exists(file.path(base_dir, f)))

cat("🌐 Creating Master HTML Viewer...\n")
cat("─────────────────────────────────────────────────────────\n")
cat("Figures available:\n")
cat("  • Figure 1:", ifelse(figures_exist["fig1_main"], "✅", "❌"), "\n")
cat("  • Figure 2:", ifelse(figures_exist["fig2_main"], "✅", "❌"), "\n")
cat("  • Figure 3:", ifelse(figures_exist["fig3_main"], "✅ REAL DATA", "🔄 Generating..."), "\n\n")

## ═══════════════════════════════════════════════════════════════════════════
## HTML GENERATION
## ═══════════════════════════════════════════════════════════════════════════

html_content <- paste0('<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Pipeline_2: Master Viewer - All Figures</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg-dark: #0f172a;
            --bg-card: #1e293b;
            --text-light: #e2e8f0;
            --primary: #3b82f6;
            --success: #10b981;
            --orange: #FF7F00;
            --red-als: #E31A1C;
            --blue-ctrl: #1F78B4;
            --gold: #FFD700;
        }
        
        body {
            font-family: "Inter", sans-serif;
            background: var(--bg-dark);
            color: var(--text-light);
            margin: 0;
            padding: 0;
        }
        
        .header {
            background: linear-gradient(135deg, #1e293b 0%, #0f172a 100%);
            padding: 60px 40px;
            text-align: center;
            border-bottom: 3px solid var(--primary);
        }
        
        .header h1 {
            font-size: 3.5em;
            margin: 0;
            background: linear-gradient(135deg, var(--primary), var(--success));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        
        .header .subtitle {
            font-size: 1.4em;
            margin-top: 15px;
            color: rgba(255,255,255,0.7);
        }
        
        .progress-bar {
            background: var(--bg-card);
            padding: 30px;
            margin: 30px auto;
            max-width: 1400px;
            border-radius: 15px;
        }
        
        .progress {
            background: #334155;
            height: 40px;
            border-radius: 20px;
            overflow: hidden;
            margin-top: 15px;
        }
        
        .progress-fill {
            background: linear-gradient(90deg, var(--success), var(--primary));
            height: 100%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
            font-size: 1.1em;
            transition: width 0.5s ease;
        }
        
        .nav-tabs {
            background: var(--bg-card);
            display: flex;
            justify-content: center;
            padding: 20px;
            gap: 15px;
            position: sticky;
            top: 0;
            z-index: 100;
            box-shadow: 0 4px 6px rgba(0,0,0,0.3);
        }
        
        .tab-btn {
            padding: 15px 35px;
            border: none;
            background: #334155;
            color: var(--text-light);
            font-size: 1.1em;
            font-weight: 600;
            border-radius: 10px;
            cursor: pointer;
            transition: all 0.3s;
        }
        
        .tab-btn:hover {
            background: var(--primary);
            transform: translateY(-2px);
        }
        
        .tab-btn.active {
            background: var(--primary);
            box-shadow: 0 0 20px rgba(59, 130, 246, 0.5);
        }
        
        .tab-content {
            display: none;
            padding: 40px;
            max-width: 1600px;
            margin: 0 auto;
        }
        
        .tab-content.active {
            display: block;
        }
        
        .figure-card {
            background: var(--bg-card);
            border-radius: 15px;
            padding: 30px;
            margin-bottom: 40px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.5);
        }
        
        .figure-card h2 {
            color: var(--primary);
            margin-top: 0;
            font-size: 2em;
            border-bottom: 2px solid var(--primary);
            padding-bottom: 15px;
        }
        
        .figure-card img {
            width: 100%;
            border-radius: 10px;
            margin: 20px 0;
            cursor: zoom-in;
            transition: transform 0.3s;
        }
        
        .figure-card img:hover {
            transform: scale(1.02);
        }
        
        .panel-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 25px;
            margin-top: 30px;
        }
        
        .panel-item {
            background: var(--bg-dark);
            padding: 20px;
            border-radius: 10px;
            border: 1px solid #334155;
        }
        
        .panel-item h4 {
            color: var(--success);
            margin-top: 0;
        }
        
        .panel-item img {
            width: 100%;
            border-radius: 8px;
            margin-top: 15px;
        }
        
        .color-legend {
            background: rgba(59, 130, 246, 0.1);
            border-left: 4px solid var(--primary);
            padding: 20px;
            border-radius: 8px;
            margin: 20px 0;
        }
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 20px;
            margin: 30px 0;
        }
        
        .stat-card {
            background: var(--bg-dark);
            padding: 20px;
            border-radius: 10px;
            text-align: center;
            border: 2px solid var(--success);
        }
        
        .stat-value {
            font-size: 2.5em;
            font-weight: bold;
            color: var(--success);
        }
        
        .stat-label {
            font-size: 0.9em;
            opacity: 0.8;
            margin-top: 10px;
        }
        
        .modal {
            display: none;
            position: fixed;
            z-index: 9999;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(0, 0, 0, 0.95);
        }
        
        .modal-content {
            margin: 2% auto;
            display: block;
            max-width: 95%;
            max-height: 95%;
            border-radius: 10px;
        }
        
        .close {
            position: absolute;
            top: 30px;
            right: 50px;
            color: #fff;
            font-size: 60px;
            font-weight: bold;
            cursor: pointer;
            transition: color 0.3s;
        }
        
        .close:hover {
            color: var(--primary);
        }
        
        .badge {
            display: inline-block;
            padding: 5px 12px;
            border-radius: 5px;
            font-size: 0.85em;
            font-weight: bold;
            margin: 0 5px;
        }
        
        .badge-success { background: var(--success); color: white; }
        .badge-warning { background: #f59e0b; color: white; }
        .badge-info { background: var(--primary); color: white; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🚀 PIPELINE_2 MASTER VIEWER</h1>
        <div class="subtitle">Comprehensive miRNA G>T Oxidative Stress Analysis</div>
        <div style="margin-top: 20px;">
            <span class="badge badge-success">v0.4.0</span>
            <span class="badge badge-info">3 Figures</span>
            <span class="badge badge-warning">10/16 Questions</span>
        </div>
    </div>

    <div class="progress-bar">
        <h3 style="margin-top: 0; text-align: center;">Scientific Progress</h3>
        <div class="progress">
            <div class="progress-fill" style="width: 63%;">63% Complete (10/16 Questions)</div>
        </div>
    </div>

    <div class="nav-tabs">
        <button class="tab-btn active" onclick="showTab(\'overview\')">📊 Overview</button>
        <button class="tab-btn" onclick="showTab(\'figure1\')">Figure 1</button>
        <button class="tab-btn" onclick="showTab(\'figure2\')">Figure 2</button>
        <button class="tab-btn" onclick="showTab(\'figure3\')">Figure 3 🔴🔵</button>
    </div>

    <!-- OVERVIEW TAB -->
    <div id="overview" class="tab-content active">
        <div class="figure-card">
            <h2>📊 Project Overview</h2>
            
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-value">110,199</div>
                    <div class="stat-label">Valid SNVs</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value">1,462</div>
                    <div class="stat-label">miRNAs Analyzed</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value">8,033</div>
                    <div class="stat-label">G>T Mutations</div>
                </div>
            </div>

            <div class="color-legend">
                <h3 style="margin-top: 0;">🎨 Color Scheme Guide</h3>
                <p><strong>Tier 1 (Figures 1-2 - No Groups):</strong></p>
                <ul>
                    <li>🟠 <strong>Orange:</strong> G>T mutations (oxidative signature, neutral)</li>
                    <li>🟡 <strong>Gold:</strong> Seed region (positions 2-8, functionally critical)</li>
                    <li>🔵 <strong>Blue:</strong> G>A mutations</li>
                    <li>🟢 <strong>Green:</strong> G>C mutations</li>
                </ul>
                <p><strong>Tier 2 (Figure 3 - Group Comparison):</strong></p>
                <ul>
                    <li>🔴 <strong>RED:</strong> ALS group (disease)</li>
                    <li>🔵 <strong>BLUE:</strong> Control group (healthy)</li>
                    <li>🟡 <strong>Gold shading:</strong> Seed region highlight</li>
                    <li>⭐ <strong>Black stars:</strong> Statistical significance (*, **, ***)</li>
                </ul>
            </div>

            <h3>📋 Questions Answered</h3>
            <ul style="line-height: 2;">
                <li><strong>SQ1.1-1.3:</strong> Dataset structure & characterization ✅</li>
                <li><strong>SQ3.1-3.3:</strong> Mechanistic validation (G-content, specificity) ✅</li>
                <li><strong>SQ2.1-2.4:</strong> Group comparison (ALS vs Control) ', 
                ifelse(figures_exist["fig3_main"], '✅ REAL DATA', '🔄 Generating...'), '</li>
            </ul>
        </div>
    </div>

    <!-- FIGURE 1 TAB -->
    <div id="figure1" class="tab-content">
        <div class="figure-card">
            <h2>FIGURE 1: Dataset Characterization & G>T Landscape</h2>
            <p><em>Baseline characterization without group labels</em></p>
            
            ', ifelse(figures_exist["fig1_main"], 
                     paste0('<img src="', figures$fig1_main, '" alt="Figure 1">'),
                     '<p style="color: #f59e0b;">⚠️ Figure 1 not found</p>'), '
            
            <div class="panel-grid">
                <div class="panel-item">
                    <h4>Panel A: Dataset Evolution</h4>
                    <p>Raw entries → Individual SNVs + Mutation types distribution</p>
                    ', ifelse(figures_exist["fig1_a"], 
                             paste0('<img src="', figures$fig1_a, '">'), 
                             '<p>Panel not available</p>'), '
                </div>
                
                <div class="panel-item">
                    <h4>Panel B: G>T Positional Analysis</h4>
                    <p>Heatmap + Seed vs Non-Seed comparison</p>
                    ', ifelse(figures_exist["fig1_b"], 
                             paste0('<img src="', figures$fig1_b, '">'), 
                             '<p>Panel not available</p>'), '
                </div>
                
                <div class="panel-item">
                    <h4>Panel C: Mutation Spectrum</h4>
                    <p>G>X types by position + Top 10 mutations</p>
                    ', ifelse(figures_exist["fig1_c"], 
                             paste0('<img src="', figures$fig1_c, '">'), 
                             '<p>Panel not available</p>'), '
                </div>
                
                <div class="panel-item">
                    <h4>Panel D: Placeholder</h4>
                    <p>Reserved for future analysis</p>
                    ', ifelse(figures_exist["fig1_d"], 
                             paste0('<img src="', figures$fig1_d, '">'), 
                             '<p>Panel not available</p>'), '
                </div>
            </div>
        </div>
    </div>

    <!-- FIGURE 2 TAB -->
    <div id="figure2" class="tab-content">
        <div class="figure-card">
            <h2>FIGURE 2: Mechanistic Validation</h2>
            <p><em>Evidence that G>T reflects oxidative damage patterns</em></p>
            
            ', ifelse(figures_exist["fig2_main"], 
                     paste0('<img src="', figures$fig2_main, '" alt="Figure 2">'),
                     '<p style="color: #f59e0b;">⚠️ Figure 2 not found</p>'), '
            
            <div class="color-legend">
                <h4>🔬 Key Findings</h4>
                <ul>
                    <li><strong>G-content correlation:</strong> r = 0.347 (p < 0.001)</li>
                    <li><strong>G>T specificity:</strong> 31.6% of all G>X mutations</li>
                    <li><strong>Dose-response:</strong> 0-1 G = 5% oxidized, 5-6 G = 17% oxidized</li>
                </ul>
            </div>
            
            <div class="panel-grid">
                <div class="panel-item">
                    <h4>Panel A: G-Content Correlation</h4>
                    <p>More G in seed → More oxidation</p>
                    ', ifelse(figures_exist["fig2_a"], 
                             paste0('<img src="', figures$fig2_a, '">'), 
                             '<p>Panel not available</p>'), '
                </div>
                
                <div class="panel-item">
                    <h4>Panel B: Sequence Context</h4>
                    <p>Placeholder for GG, GC enrichment</p>
                    ', ifelse(figures_exist["fig2_b"], 
                             paste0('<img src="', figures$fig2_b, '">'), 
                             '<p>Panel not available</p>'), '
                </div>
                
                <div class="panel-item">
                    <h4>Panel C: G>T Specificity</h4>
                    <p>G>T vs other G>X mutations</p>
                    ', ifelse(figures_exist["fig2_c"], 
                             paste0('<img src="', figures$fig2_c, '">'), 
                             '<p>Panel not available</p>'), '
                </div>
                
                <div class="panel-item">
                    <h4>Panel D: Position G-Content</h4>
                    <p>G>T frequency with seed highlighted</p>
                    ', ifelse(figures_exist["fig2_d"], 
                             paste0('<img src="', figures$fig2_d, '">'), 
                             '<p>Panel not available</p>'), '
                </div>
            </div>
        </div>
    </div>

    <!-- FIGURE 3 TAB -->
    <div id="figure3" class="tab-content">
        <div class="figure-card">
            <h2>FIGURE 3: Group Comparison (ALS vs Control) ', 
            ifelse(figures_exist["fig3_main"], '✅ REAL DATA', '🔄 Generating...'), '</h2>
            <p><em>Statistical comparison with FDR correction</em></p>
            
            <div class="color-legend" style="border-left-color: var(--red-als);">
                <h4>🎨 Group Colors</h4>
                <p><strong>🔴 RED (#E31A1C):</strong> ALS patients (disease group)</p>
                <p><strong>🔵 BLUE (#1F78B4):</strong> Control samples (healthy group)</p>
                <p><strong>🟡 GOLD shading:</strong> Seed region (2-8) functional area</p>
                <p><strong>⭐ Stars:</strong> Statistical significance (* q<0.05, ** q<0.01, *** q<0.001)</p>
            </div>
            
            ', ifelse(figures_exist["fig3_main"], 
                     paste0('<img src="', figures$fig3_main, '" alt="Figure 3">'),
                     '<div style="text-align: center; padding: 60px; background: rgba(245, 158, 11, 0.1); border-radius: 10px;">
                        <h3>🔄 Figure 3 is being generated with REAL data...</h3>
                        <p>Transformation and statistical tests in progress (~5-10 minutes)</p>
                        <p>Refresh this page when generation completes</p>
                     </div>'), '
            
            ', ifelse(figures_exist["fig3_a"], '
            <div class="panel-grid">
                <div class="panel-item">
                    <h4>Panel A: Global G>T Burden</h4>
                    <p>Violin plot + Wilcoxon test (REAL DATA)</p>
                    <img src="', figures$fig3_a, '">
                </div>
                
                <div class="panel-item" style="border: 3px solid var(--gold);">
                    <h4>⭐ Panel B: Position Delta (YOUR FAVORITE - REAL DATA)</h4>
                    <p>Side-by-side comparison with significance stars</p>
                    <img src="', figures$fig3_b, '">
                </div>
                
                <div class="panel-item">
                    <h4>Panel C: Seed Interaction</h4>
                    <p>Is seed MORE affected in ALS? Fisher test</p>
                    <img src="', figures$fig3_c, '">
                </div>
                
                <div class="panel-item">
                    <h4>Panel D: Differential miRNAs</h4>
                    <p>Volcano plot with top candidates</p>
                    <img src="', figures$fig3_d, '">
                </div>
            </div>', ''), '
        </div>
    </div>

    <div id="myModal" class="modal">
        <span class="close">&times;</span>
        <img class="modal-content" id="img01">
    </div>

    <script>
        function showTab(tabName) {
            // Hide all tabs
            document.querySelectorAll(\'.tab-content\').forEach(tab => {
                tab.classList.remove(\'active\');
            });
            document.querySelectorAll(\'.tab-btn\').forEach(btn => {
                btn.classList.remove(\'active\');
            });
            
            // Show selected tab
            document.getElementById(tabName).classList.add(\'active\');
            event.target.classList.add(\'active\');
        }

        // Modal functionality
        var modal = document.getElementById("myModal");
        var modalImg = document.getElementById("img01");
        var span = document.getElementsByClassName("close")[0];

        document.querySelectorAll("img").forEach(item => {
            if (item.id !== \'img01\') {
                item.onclick = function(){
                    modal.style.display = "block";
                    modalImg.src = this.src;
                }
            }
        });

        span.onclick = function() { modal.style.display = "none"; }
        modal.onclick = function(event) {
            if (event.target == modal) modal.style.display = "none";
        }
    </script>
</body>
</html>')

## ═══════════════════════════════════════════════════════════════════════════
## SAVE HTML
## ═══════════════════════════════════════════════════════════════════════════

html_output <- file.path(base_dir, "MASTER_VIEWER.html")
writeLines(html_content, html_output)

cat("✅ Master HTML Viewer created\n")
cat("📁 Location:", html_output, "\n")
cat("🌐 Opening in browser...\n\n")

browseURL(html_output)

cat("🎉 Done! You can now:\n")
cat("   • View all figures in one place\n")
cat("   • Click any image to zoom\n")
cat("   • Switch between tabs\n")
cat("   • Refresh when Figure 3 completes\n\n")

