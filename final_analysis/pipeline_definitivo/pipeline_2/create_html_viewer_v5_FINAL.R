# 🌐 HTML VIEWER V5 - FINAL (Updated colors + Panel B fix)

rm(list = ls())

library(tidyverse)
library(scales)

source("config/config_pipeline_2.R")

# File paths - using v5 versions
figure_1_v5 <- "figures/figure_1_v5_updated_colors.png"
panel_a_v5 <- "figures/panel_a_overview_v5.png"
panel_b_v5 <- "figures/panel_b_gt_analysis_v5.png"
panel_c_v5 <- "figures/panel_c_spectrum_v5.png"
panel_d_v5 <- "figures/panel_d_placeholder_v5.png"

# Output
html_output <- file.path(base_dir, "figure_1_viewer_v5_FINAL.html")

# Data
original_snvs <- 68968
processed_snvs <- 110199
unique_mirnas <- 1462
gt_mutations <- 8033

cat("🌐 Generating FINAL HTML Viewer (v5 - Updated Colors)...\n\n")

html_content <- paste0('<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Pipeline_2: Figure 1 - Dataset Characterization (v5 FINAL)</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg-color: #1a202c;
            --card-bg: #2d3748;
            --text-color: #e2e8f0;
            --primary-color: #63b3ed;
            --secondary-color: #4fd1c5;
            --accent-color: #f6e05e;
            --success-color: #48bb78;
            --orange-color: #FF7F00;
            --gold-color: #FFD700;
        }
        body {
            font-family: "Inter", sans-serif;
            background-color: var(--bg-color);
            color: var(--text-color);
            margin: 0;
            padding: 20px;
            line-height: 1.6;
        }
        .container {
            max-width: 1600px;
            margin: 0 auto;
            background: var(--card-bg);
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.5);
        }
        .header {
            background: linear-gradient(135deg, #242d3a 0%, #1a365d 100%);
            padding: 40px;
            text-align: center;
            border-bottom: 1px solid #4a5568;
        }
        .header h1 {
            font-size: 2.8em;
            margin-bottom: 10px;
            color: var(--primary-color);
        }
        .color-note {
            background: rgba(255, 127, 0, 0.1);
            border-left: 4px solid var(--orange-color);
            padding: 15px;
            margin: 20px 0;
            border-radius: 8px;
        }
        .color-note h3 {
            color: var(--orange-color);
            margin-top: 0;
        }
        .figure-container {
            padding: 40px;
            text-align: center;
        }
        .figure-container img {
            max-width: 100%;
            height: auto;
            border-radius: 8px;
            box-shadow: 0 8px 20px rgba(0, 0, 0, 0.3);
            cursor: zoom-in;
        }
        .panel-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 30px;
            padding: 40px;
        }
        .panel-card {
            background: var(--bg-color);
            padding: 25px;
            border-radius: 10px;
            border: 1px solid #4a5568;
        }
        .panel-card h3 {
            color: var(--secondary-color);
            margin-bottom: 15px;
        }
        .panel-card img {
            width: 100%;
            border-radius: 8px;
            margin-top: 15px;
            cursor: zoom-in;
        }
        .modal {
            display: none;
            position: fixed;
            z-index: 1000;
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
        }
        .close {
            position: absolute;
            top: 30px;
            right: 45px;
            color: #f1f1f1;
            font-size: 50px;
            cursor: pointer;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 FIGURE 1: Dataset Characterization</h1>
            <p style="font-size: 1.2em; margin: 10px 0;">G>T Oxidative Stress Landscape</p>
            <p style="opacity: 0.8;">Pipeline_2 v0.2.1 | Updated Color Scheme</p>
        </div>

        <div class="color-note">
            <h3>🎨 Color Scheme (Updated)</h3>
            <p><strong>🟠 Orange:</strong> G>T mutations (oxidative signature, neutral)</p>
            <p><strong>🟡 Gold:</strong> Seed region (positions 2-8, functionally critical)</p>
            <p><strong>⚪ Grey:</strong> Non-seed regions</p>
            <p style="margin-top: 10px; padding-top: 10px; border-top: 1px solid rgba(255,255,255,0.1);">
                <strong>🔴 Red is RESERVED for ALS</strong> (will be used in Figure 3 for group comparisons)
            </p>
        </div>

        <div class="figure-container">
            <h2 style="color: var(--primary-color); margin-bottom: 25px;">Complete Figure</h2>
            <img src="', figure_1_v5, '" alt="Figure 1 v5" id="mainFigure">
            <p style="margin-top: 20px; color: var(--text-color); opacity: 0.8;">
                Click on any image to zoom
            </p>
        </div>

        <div class="panel-grid">
            <div class="panel-card">
                <h3>Panel A: Dataset Evolution & Mutation Types</h3>
                <p>Left: Dataset processing from ', comma(original_snvs), ' raw entries to ', comma(processed_snvs), ' individual SNVs.</p>
                <p>Right: Distribution of mutation types showing G>T represents 7.3% of all mutations.</p>
                <img src="', panel_a_v5, '" alt="Panel A">
            </div>

            <div class="panel-card">
                <h3>Panel B: G>T Positional Analysis</h3>
                <p><strong>Top:</strong> Heatmap showing G>T frequency across 22 miRNA positions.</p>
                <p><strong>Bottom:</strong> Comparison of G>T in Seed (🟡 gold) vs Non-Seed (⚪ grey) regions.</p>
                <p style="color: var(--success-color); font-weight: bold;">✓ Panel B is now visible with updated colors</p>
                <img src="', panel_b_v5, '" alt="Panel B" style="border: 2px solid var(--gold-color);">
            </div>

            <div class="panel-card">
                <h3>Panel C: Mutation Spectrum</h3>
                <p><strong>Left:</strong> Stacked bars showing G>X mutation proportions per position (🟠 G>T, 🔵 G>A, 🟢 G>C).</p>
                <p><strong>Right:</strong> Top 10 most frequent mutation types across entire dataset.</p>
                <img src="', panel_c_v5, '" alt="Panel C">
            </div>

            <div class="panel-card">
                <h3>Panel D: Advanced Analysis</h3>
                <p>Reserved for future miRNA-specific analysis.</p>
                <p style="opacity: 0.7;">Focus remains on initial characterization steps.</p>
                <img src="', panel_d_v5, '" alt="Panel D">
            </div>
        </div>

        <div style="background: var(--bg-color); padding: 30px; margin: 20px;">
            <h2 style="color: var(--success-color); text-align: center;">✅ Key Findings</h2>
            <ul style="line-height: 2; font-size: 1.1em;">
                <li><strong>Dataset Quality:</strong> ', comma(processed_snvs), ' valid SNVs from ', comma(unique_mirnas), ' miRNAs</li>
                <li><strong>G>T Prevalence:</strong> ', comma(gt_mutations), ' mutations identified (7.3% of total)</li>
                <li><strong>Positional Patterns:</strong> Non-random distribution with seed region involvement</li>
                <li><strong>Color Convention:</strong> 🟠 Orange=G>T, 🟡 Gold=Seed, 🔴 Red reserved for ALS</li>
            </ul>
        </div>
    </div>

    <div id="myModal" class="modal">
        <span class="close">&times;</span>
        <img class="modal-content" id="img01">
    </div>

    <script>
        var modal = document.getElementById("myModal");
        var modalImg = document.getElementById("img01");
        var span = document.getElementsByClassName("close")[0];

        document.querySelectorAll("img").forEach(item => {
            item.onclick = function(){
                modal.style.display = "block";
                modalImg.src = this.src;
            }
        });

        span.onclick = function() { modal.style.display = "none"; }
        modal.onclick = function(event) {
            if (event.target == modal) modal.style.display = "none";
        }
    </script>
</body>
</html>')

writeLines(html_content, html_output)

cat("✅ HTML Viewer v5 FINAL generated\n")
cat("📁 Location:", html_output, "\n")
cat("🎨 Features:\n")
cat("   • Updated color scheme (Orange=G>T, Gold=Seed)\n")
cat("   • Panel B explicitly highlighted\n")
cat("   • All panels use v5 versions\n")
cat("   • Color note explaining scheme\n\n")

cat("🌐 Opening in browser...\n")
browseURL(html_output)
cat("✅ Done!\n")

