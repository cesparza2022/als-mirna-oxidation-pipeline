# 🌐 SIMPLE MASTER VIEWER - PARA REVISAR TODO

rm(list = ls())

base_dir <- "/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/pipeline_definitivo/pipeline_2"

# Check which figures exist
fig1 <- file.exists(file.path(base_dir, "figures/figure_1_v5_updated_colors.png"))
fig2 <- file.exists(file.path(base_dir, "figures/figure_2_mechanistic_validation.png"))
fig3 <- file.exists(file.path(base_dir, "figures/figure_3_group_comparison_REAL.png"))
  fig3_panels <- file.exists(file.path(base_dir, "figures/panel_b_position_delta_REAL.png"))
  fig3_improved <- file.exists(file.path(base_dir, "figures/panel_b_position_delta_IMPROVED.png"))

cat("🌐 Creating Simple Master Viewer...\n")
cat("Figures available:\n")
cat("  • Figure 1:", ifelse(fig1, "✅", "❌"), "\n")
cat("  • Figure 2:", ifelse(fig2, "✅", "❌"), "\n")
cat("  • Figure 3:", ifelse(fig3_improved, "✅ IMPROVED", ifelse(fig3, "✅ REAL", ifelse(fig3_panels, "🔄 Panels", "❌"))), "\n\n")

html <- '<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Pipeline_2 - Master Viewer</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            background: #0f172a; 
            color: #e2e8f0; 
            padding: 40px; 
            margin: 0;
        }
        .header { 
            text-align: center; 
            padding: 40px; 
            background: #1e293b; 
            border-radius: 15px; 
            margin-bottom: 40px;
        }
        h1 { 
            color: #3b82f6; 
            font-size: 3em; 
            margin: 0;
        }
        .progress { 
            background: #334155; 
            height: 30px; 
            border-radius: 15px; 
            margin: 20px 0;
        }
        .progress-bar { 
            background: linear-gradient(90deg, #10b981, #3b82f6); 
            height: 100%; 
            width: 63%; 
            border-radius: 15px; 
            text-align: center; 
            line-height: 30px; 
            font-weight: bold;
        }
        .section { 
            background: #1e293b; 
            padding: 30px; 
            margin: 30px 0; 
            border-radius: 15px;
        }
        h2 { 
            color: #10b981; 
            border-bottom: 2px solid #10b981; 
            padding-bottom: 10px;
        }
        img { 
            max-width: 100%; 
            border-radius: 10px; 
            margin: 20px 0; 
            cursor: zoom-in;
            box-shadow: 0 5px 15px rgba(0,0,0,0.5);
        }
        .colors { 
            background: rgba(59, 130, 246, 0.1); 
            padding: 20px; 
            border-left: 4px solid #3b82f6; 
            border-radius: 8px; 
            margin: 20px 0;
        }
        .grid { 
            display: grid; 
            grid-template-columns: 1fr 1fr; 
            gap: 20px;
        }
        .badge { 
            display: inline-block; 
            padding: 8px 15px; 
            border-radius: 5px; 
            margin: 5px; 
            font-weight: bold;
        }
        .badge-success { background: #10b981; }
        .badge-warning { background: #f59e0b; }
        .badge-info { background: #3b82f6; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🚀 PIPELINE_2 Master Viewer</h1>
        <p style="font-size: 1.3em;">miRNA G>T Oxidative Stress Analysis</p>
        <div>
            <span class="badge badge-success">v0.4.0</span>
            <span class="badge badge-info">3 Figures</span>
            <span class="badge badge-warning">10/16 Questions (63%)</span>
        </div>
        <div class="progress">
            <div class="progress-bar">63% Complete</div>
        </div>
    </div>

    <div class="colors">
        <h3>🎨 Color Scheme</h3>
        <p><strong>Tier 1 (Figures 1-2):</strong> 🟠 Orange=G>T, 🟡 Gold=Seed</p>
        <p><strong>Tier 2 (Figure 3):</strong> 🔴 RED=ALS, 🔵 BLUE=Control, ⭐ Stars=Significance</p>
    </div>'

# Figure 1
if (fig1) {
  html <- paste0(html, '
    <div class="section">
        <h2>FIGURE 1: Dataset Characterization ✅</h2>
        <p><em>Questions: SQ1.1, SQ1.2, SQ1.3</em></p>
        <img src="figures/figure_1_v5_updated_colors.png">
    </div>')
}

# Figure 2
if (fig2) {
  html <- paste0(html, '
    <div class="section">
        <h2>FIGURE 2: Mechanistic Validation ✅</h2>
        <p><em>Questions: SQ3.1, SQ3.2, SQ3.3 | G-content r=0.347</em></p>
        <img src="figures/figure_2_mechanistic_validation.png">
    </div>')
}

# Figure 3
if (fig3) {
  html <- paste0(html, '
    <div class="section">
        <h2>FIGURE 3: Group Comparison ✅ REAL DATA</h2>
        <p><em>Questions: SQ2.1, SQ2.2, SQ2.3, SQ2.4 | 🔴 ALS vs 🔵 Control</em></p>
        <img src="figures/figure_3_group_comparison_REAL.png">
        
        <div class="grid" style="margin-top: 30px;">
            <div>
                <h4>⭐ Panel B: Position Delta (YOUR FAVORITE)</h4>
                <img src="figures/panel_b_position_delta_REAL.png">
            </div>
            <div>
                <h4>Panel D: Volcano Plot</h4>
                <img src="figures/panel_d_volcano_REAL.png">
            </div>
        </div>
    </div>')
} else if (fig3_improved) {
  html <- paste0(html, '
    <div class="section">
        <h2>FIGURE 3: Group Comparison ✅ (Improved Style)</h2>
        <p><em>Panel B with your preferred visualization style</em></p>
        
        <div style="background: rgba(214, 39, 40, 0.1); padding: 20px; border-left: 4px solid #D62728; border-radius: 8px; margin: 20px 0;">
            <h4 style="margin-top: 0;">🎨 Style Improvements Applied:</h4>
            <ul>
                <li><strong>theme_classic()</strong> - Cleaner, more professional</li>
                <li><strong>Grey60</strong> for Control (neutral baseline)</li>
                <li><strong>#D62728</strong> for ALS (darker red, better contrast)</li>
                <li><strong>Grey shading</strong> for seed (subtle, not competing)</li>
                <li><strong>Legend top-right</strong> (integrated in plot)</li>
                <li><strong>Asterisks on ALS bars</strong> only where p_adj < 0.05</li>
            </ul>
        </div>
        
        <div>
            <h3>⭐ Panel B: Position Delta (YOUR FAVORITE - IMPROVED STYLE)</h3>
            <img src="figures/panel_b_position_delta_IMPROVED.png" style="border: 3px solid #D62728;">
            <p style="text-align: center; margin-top: 15px; color: #10b981;">
                <strong>✅ Side-by-side comparison | Seed region (2-8) shaded | * indicates p_adj < 0.05</strong>
            </p>
        </div>
        
        <div class="grid" style="margin-top: 30px;">
            <div>
                <h4>Panel A: Global Burden</h4>
                <img src="figures/panel_a_global_burden_REAL.png">
            </div>
            <div>
                <h4>Panel C: Seed Interaction</h4>
                <img src="figures/panel_c_seed_interaction_REAL.png">
            </div>
        </div>
    </div>')
} else if (fig3_panels) {
  html <- paste0(html, '
    <div class="section">
        <h2>FIGURE 3: Group Comparison 🔄 (Panels Ready)</h2>
        <p><em>Combined figure generating... Individual panels available</em></p>
        <div class="grid">
            <div>
                <h4>⭐ Panel B: Position Delta (REAL DATA)</h4>
                <img src="figures/panel_b_position_delta_REAL.png">
            </div>
        </div>
    </div>')
} else {
  html <- paste0(html, '
    <div class="section">
        <h2>FIGURE 3: Group Comparison 🔄</h2>
        <p style="text-align: center; padding: 40px; color: #f59e0b;">
            ⏳ Generating with REAL data... Refresh page when complete
        </p>
    </div>')
}

html <- paste0(html, '
</body>
</html>')

# Save
html_file <- file.path(base_dir, "MASTER_VIEWER.html")
writeLines(html, html_file)

cat("✅ Master Viewer created:", html_file, "\n")
cat("🌐 Opening...\n")
browseURL(html_file)
cat("\n🎉 You can now review ALL figures in one place!\n")
