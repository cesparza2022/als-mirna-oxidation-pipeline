#!/usr/bin/env python3
"""
==============================================================================
GENERADOR HTML - Intento 01 (Figuras en Español)
==============================================================================

Objetivo: Convertir REPORTE_CIENTIFICO_COMPLETO.md a HTML bonito
Fecha: 14 octubre 2025
Versión: intento01

==============================================================================
"""

import re
import os
from pathlib import Path

print("""
╔═══════════════════════════════════════════════════════════════════════════╗
║         🚀 GENERANDO HTML - PYTHON APPROACH                               ║
╚═══════════════════════════════════════════════════════════════════════════╝
""")

# ==============================================================================
# PASO 1: Leer Markdown
# ==============================================================================

print("📖 Paso 1: Leyendo REPORTE_CIENTIFICO_COMPLETO.md...")

md_path = Path("../../REPORTE_CIENTIFICO_COMPLETO.md")
with open(md_path, 'r', encoding='utf-8') as f:
    md_lines = f.readlines()

print(f"   ✅ Leídas {len(md_lines)} líneas\n")

# ==============================================================================
# PASO 2: Convertir Markdown básico a HTML
# ==============================================================================

print("🔄 Paso 2: Convirtiendo Markdown a HTML...")

html_content = []

# HTML Header
html_content.append("""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Comprehensive Analysis of SNVs in miRNAs - ALS Oxidative Stress Biomarkers</title>
    <link rel="stylesheet" href="custom_styles.css">
    <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;600;700&family=Open+Sans:wght@300;400;600&family=Fira+Code&display=swap" rel="stylesheet">
</head>
<body>

<div class="container">
    <nav id="toc" class="sticky-toc">
        <h3>📚 Contents</h3>
        <ul>
            <li><a href="#abstract">Abstract</a></li>
            <li><a href="#introduction">1. Introduction</a></li>
            <li><a href="#methods">2. Methods</a></li>
            <li><a href="#results-phase1">3. Results - Phase 1</a></li>
            <li><a href="#results-phase2">4. Results - Phase 2</a></li>
            <li><a href="#results-phase3">5. Results - Phase 3</a></li>
            <li><a href="#results-phase4">6. Results - Phase 4</a></li>
            <li><a href="#discussion">7. Discussion</a></li>
            <li><a href="#conclusions">8. Conclusions</a></li>
            <li><a href="#supplementary">9. Supplementary</a></li>
        </ul>
    </nav>

    <main class="content">
""")

in_code_block = False
in_table = False
table_lines = []

for i, line in enumerate(md_lines):
    line = line.rstrip()
    
    # Skip first title (will be in header)
    if i == 0:
        html_content.append(f'<header class="main-header"><h1>{line[2:]}</h1></header>\n')
        continue
    
    # Code blocks
    if line.startswith('```'):
        if in_code_block:
            html_content.append('</code></pre>\n')
            in_code_block = False
        else:
            lang = line[3:].strip() or 'r'
            html_content.append(f'<pre class="code-block"><code class="language-{lang}">\n')
            in_code_block = True
        continue
    
    if in_code_block:
        html_content.append(line + '\n')
        continue
    
    # Tables
    if line.startswith('|'):
        if not in_table:
            in_table = True
            table_lines = []
        table_lines.append(line)
        continue
    elif in_table:
        # End of table, process it
        html_content.append('<table class="data-table">\n')
        for ti, tline in enumerate(table_lines):
            if ti == 0:
                # Header row
                cells = [c.strip() for c in tline.split('|')[1:-1]]
                html_content.append('<thead><tr>\n')
                for cell in cells:
                    html_content.append(f'  <th>{cell}</th>\n')
                html_content.append('</tr></thead>\n<tbody>\n')
            elif ti == 1 and '---' in tline:
                # Separator row, skip
                continue
            else:
                # Data rows
                cells = [c.strip() for c in tline.split('|')[1:-1]]
                html_content.append('<tr>\n')
                for cell in cells:
                    html_content.append(f'  <td>{cell}</td>\n')
                html_content.append('</tr>\n')
        html_content.append('</tbody></table>\n\n')
        in_table = False
        table_lines = []
    
    # Headers
    if line.startswith('# '):
        html_content.append(f'<h1>{line[2:]}</h1>\n')
    elif line.startswith('## '):
        # Create section divs with IDs
        text = line[3:]
        section_id = text.lower().replace(' ', '-').replace('.', '').replace(':', '')
        html_content.append(f'<section id="{section_id}" class="section">\n<h2>{text}</h2>\n')
    elif line.startswith('### '):
        html_content.append(f'<h3>{line[4:]}</h3>\n')
    elif line.startswith('#### '):
        html_content.append(f'<h4>{line[5:]}</h4>\n')
    
    # Horizontal rules
    elif line.startswith('---'):
        html_content.append('<hr class="divider">\n')
    
    # Lists
    elif line.startswith('- '):
        if i > 0 and not md_lines[i-1].strip().startswith('- '):
            html_content.append('<ul class="styled-list">\n')
        html_content.append(f'<li>{line[2:]}</li>\n')
        if i < len(md_lines)-1 and not md_lines[i+1].strip().startswith('- '):
            html_content.append('</ul>\n')
    
    # Numbered lists
    elif re.match(r'^\d+\.', line):
        if i > 0 and not re.match(r'^\d+\.', md_lines[i-1].strip()):
            html_content.append('<ol class="styled-list">\n')
        content = re.sub(r'^\d+\.\s*', '', line)
        html_content.append(f'<li>{content}</li>\n')
        if i < len(md_lines)-1 and not re.match(r'^\d+\.', md_lines[i+1].strip()):
            html_content.append('</ol>\n')
    
    # Bold
    elif '**' in line:
        line = re.sub(r'\*\*(.*?)\*\*', r'<strong>\1</strong>', line)
        if line.strip():
            html_content.append(f'<p>{line}</p>\n')
    
    # Regular paragraphs
    elif line.strip():
        html_content.append(f'<p>{line}</p>\n')
    
    # Empty lines
    else:
        html_content.append('\n')

# Close sections and main
html_content.append('</section>\n')
html_content.append("""
    </main>
</div>

<footer class="main-footer">
    <p>Generated: October 14, 2025 | Dataset: GSE168714 | Analysis: Comprehensive SNV Oxidation Patterns</p>
</footer>

</body>
</html>
""")

print("   ✅ Contenido HTML procesado\n")

# ==============================================================================
# PASO 3: Guardar HTML
# ==============================================================================

print("💾 Paso 3: Guardando HTML...")

html_file = Path("reporte_completo_basico.html")
with open(html_file, 'w', encoding='utf-8') as f:
    f.writelines(html_content)

print(f"   ✅ HTML guardado: {html_file}\n")

# ==============================================================================
# PASO 4: Resumen
# ==============================================================================

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
print("✅ HTML GENERADO EXITOSAMENTE\n")
print("📄 Archivo: reporte_completo_basico.html")
print("📊 Tamaño:", os.path.getsize(html_file) // 1024, "KB\n")
print("🌐 Para abrir:")
print("   open reporte_completo_basico.html\n")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")








