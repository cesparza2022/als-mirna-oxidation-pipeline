#!/usr/bin/env python3
"""
==============================================================================
GENERADOR HTML V4 - DEFINITIVO CON BÚSQUEDA COMPLETA
==============================================================================

Basado en MAPA_FIGURAS_COMPLETO.md:
- 40 archivos PNG sueltos
- 18 carpetas con 77 PNGs
- TOTAL: 117 figuras

Estrategia:
1. Buscar archivos sueltos: figures/pasoX_*.png
2. Buscar en carpetas: figures/pasoX_*/*.png
3. Usar rutas relativas correctas desde el HTML

==============================================================================
"""

import re
import os
from pathlib import Path
from glob import glob

print("""
╔═══════════════════════════════════════════════════════════════════════════╗
║         🚀 GENERADOR HTML V4 - DEFINITIVO                                 ║
╚═══════════════════════════════════════════════════════════════════════════╝
""")

# ==============================================================================
# FUNCIONES AUXILIARES
# ==============================================================================

def find_all_figures_for_step(step_name):
    """
    Encuentra TODAS las figuras para un paso, buscando en:
    1. Archivos sueltos que empiecen con step_name
    2. Carpetas que empiecen con step_name
    """
    figures = []
    base_path = "../../figures"
    
    # 1. Buscar archivos PNG sueltos
    pattern1 = f"{base_path}/{step_name}*.png"
    for png_path in glob(pattern1):
        png_file = Path(png_path)
        figures.append({
            'path': f"figures/{png_file.name}",
            'name': png_file.stem.replace('_', ' ').title(),
            'file': png_file.name,
            'type': 'suelto'
        })
    
    # 2. Buscar carpetas que empiecen con step_name
    pattern2 = f"{base_path}/{step_name}*"
    for dir_path in glob(pattern2):
        if os.path.isdir(dir_path):
            # Buscar PNGs dentro de esta carpeta
            for png_path in glob(f"{dir_path}/*.png"):
                png_file = Path(png_path)
                dir_name = Path(dir_path).name
                figures.append({
                    'path': f"figures/{dir_name}/{png_file.name}",
                    'name': png_file.stem.replace('_', ' ').title(),
                    'file': png_file.name,
                    'type': 'carpeta'
                })
    
    return figures

def create_figure_gallery(figures, title=""):
    """Crea una galería HTML de figuras"""
    if not figures:
        return ""
    
    html = f'\n<div class="figure-gallery">\n'
    if title:
        html += f'<h4 class="gallery-title">{title}</h4>\n'
    
    for fig in figures:
        html += f'''
<figure class="gallery-item">
    <img src="{fig['path']}" alt="{fig['name']}" class="result-figure" loading="lazy" onerror="console.error('Failed to load:', this.src); this.style.border='2px solid red';">
    <figcaption>{fig['name']}</figcaption>
</figure>
'''
    
    html += '</div>\n\n'
    return html

# ==============================================================================
# PASO 1: Leer Markdown
# ==============================================================================

print("📖 Paso 1: Leyendo REPORTE_CIENTIFICO_COMPLETO.md...")

md_path = Path("../../REPORTE_CIENTIFICO_COMPLETO.md")
with open(md_path, 'r', encoding='utf-8') as f:
    md_lines = f.readlines()

print(f"   ✅ Leídas {len(md_lines)} líneas\n")

# ==============================================================================
# PASO 2: Mapear secciones a figuras
# ==============================================================================

print("🎨 Paso 2: Mapeando figuras a secciones...")

# Mapa de secciones Results a prefijos de figuras
section_to_figures = {
    '3.1': ['paso1'],
    '3.2': ['paso2'],
    '3.3': ['paso3'],
    '3.4': ['paso4'],
    '4.1': ['paso5'],
    '4.2': ['paso6'],
    '4.3': ['paso7'],
    '5.1': ['paso8'],
    '5.2': ['paso9'],
    '5.3': ['paso9', 'paso10'],  # Incluye paso9 y paso10
    '6.1': ['paso11'],
}

# Contar figuras
figures_count = 0
section_figures = {}
for section, prefixes in section_to_figures.items():
    all_figs = []
    for prefix in prefixes:
        figs = find_all_figures_for_step(prefix)
        all_figs.extend(figs)
    section_figures[section] = all_figs
    figures_count += len(all_figs)
    print(f"   📊 Sección {section}: {len(all_figs)} figuras")

print(f"\n   ✅ Total: {figures_count} figuras encontradas\n")

# ==============================================================================
# PASO 3: Generar HTML con figuras
# ==============================================================================

print("🔨 Paso 3: Generando HTML con figuras insertadas...")

html_output = []

# HTML Header
html_output.append("""<!DOCTYPE html>
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
        <h3>📚 Table of Contents</h3>
        <ul>
            <li><a href="#abstract">Abstract</a></li>
            <li><a href="#introduction">1. Introduction</a></li>
            <li><a href="#methods">2. Materials and Methods</a></li>
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

# Procesar línea por línea
in_code_block = False
in_table = False
table_lines = []
current_section = None
figures_inserted_in_section = False

for i, line in enumerate(md_lines):
    line = line.rstrip()
    
    # Title (first line)
    if i == 0:
        html_output.append(f'<header class="main-header">\n<h1 class="title">{line[2:]}</h1>\n</header>\n\n')
        continue
    
    # Authors/Date info
    if line.startswith('**Authors:**') or line.startswith('**Date:**') or line.startswith('**Dataset:**'):
        html_output.append(f'<p class="metadata">{line}</p>\n')
        continue
    
    # Code blocks
    if line.startswith('```'):
        if in_code_block:
            html_output.append('</code></pre>\n\n')
            in_code_block = False
        else:
            lang = line[3:].strip() or 'r'
            html_output.append(f'<pre class="code-block"><code class="language-{lang}">\n')
            in_code_block = True
        continue
    
    if in_code_block:
        line = line.replace('<', '&lt;').replace('>', '&gt;')
        html_output.append(line + '\n')
        continue
    
    # Tables
    if line.startswith('|') and '|' in line[1:]:
        if not in_table:
            in_table = True
            table_lines = []
        table_lines.append(line)
        continue
    elif in_table:
        html_output.append('<div class="table-wrapper"><table class="data-table">\n')
        for ti, tline in enumerate(table_lines):
            if '---' in tline:
                continue
            cells = [c.strip() for c in tline.split('|')[1:-1]]
            if ti == 0:
                html_output.append('<thead><tr>\n')
                for cell in cells:
                    html_output.append(f'  <th>{cell}</th>\n')
                html_output.append('</tr></thead>\n<tbody>\n')
            else:
                html_output.append('<tr>\n')
                for cell in cells:
                    cell = re.sub(r'\*\*(.*?)\*\*', r'<strong>\1</strong>', cell)
                    html_output.append(f'  <td>{cell}</td>\n')
                html_output.append('</tr>\n')
        html_output.append('</tbody></table></div>\n\n')
        in_table = False
        table_lines = []
    
    # Detect section changes
    if line.startswith('### ') and ('Step' in line or 'step' in line.lower()):
        match = re.search(r'(\d+\.\d+)', line)
        if match:
            new_section = match.group(1)
            if new_section != current_section:
                current_section = new_section
                figures_inserted_in_section = False
    
    # Headers with IDs
    if line.startswith('## '):
        text = line[3:]
        section_id = re.sub(r'[^a-z0-9]+', '-', text.lower()).strip('-')
        
        if i > 0:
            html_output.append('</section>\n\n')
        
        html_output.append(f'<section id="{section_id}" class="section">\n')
        html_output.append(f'<h2>{text}</h2>\n')
        continue
    elif line.startswith('### '):
        text = line[4:]
        section_id = re.sub(r'[^a-z0-9]+', '-', text.lower()).strip('-')
        html_output.append(f'<h3 id="{section_id}">{text}</h3>\n')
        
        # Insertar figuras después del h3
        if current_section and not figures_inserted_in_section and current_section in section_figures:
            figs = section_figures[current_section]
            if figs:
                html_output.append(create_figure_gallery(figs, f"Figures for Section {current_section}"))
                figures_inserted_in_section = True
        
        continue
    elif line.startswith('#### '):
        html_output.append(f'<h4>{line[5:]}</h4>\n')
        continue
    
    # Horizontal rules
    if line == '---':
        html_output.append('<hr class="divider">\n')
        continue
    
    # Lists
    if line.startswith('- '):
        if i == 0 or not md_lines[i-1].strip().startswith('- '):
            html_output.append('<ul class="styled-list">\n')
        content = line[2:]
        content = re.sub(r'\*\*(.*?)\*\*', r'<strong>\1</strong>', content)
        html_output.append(f'<li>{content}</li>\n')
        if i >= len(md_lines)-1 or not md_lines[i+1].strip().startswith('- '):
            html_output.append('</ul>\n')
        continue
    
    # Numbered lists
    if re.match(r'^\d+\.', line):
        if i == 0 or not re.match(r'^\d+\.', md_lines[i-1].strip()):
            html_output.append('<ol class="styled-list">\n')
        content = re.sub(r'^\d+\.\s*', '', line)
        content = re.sub(r'\*\*(.*?)\*\*', r'<strong>\1</strong>', content)
        html_output.append(f'<li>{content}</li>\n')
        if i >= len(md_lines)-1 or not re.match(r'^\d+\.', md_lines[i+1].strip()):
            html_output.append('</ol>\n')
        continue
    
    # Regular paragraphs
    if line.strip():
        line = re.sub(r'\*\*(.*?)\*\*', r'<strong>\1</strong>', line)
        line = re.sub(r'\*(.*?)\*', r'<em>\1</em>', line)
        line = re.sub(r'`(.*?)`', r'<code>\1</code>', line)
        html_output.append(f'<p>{line}</p>\n')

# Close final section
html_output.append('</section>\n\n')

# Footer
html_output.append("""
    </main>
</div>

<footer class="main-footer">
    <p><strong>Generated:</strong> October 14, 2025 | <strong>Dataset:</strong> GSE168714 | <strong>Analysis:</strong> Comprehensive SNV Oxidation Patterns in miRNAs</p>
    <p>Pipeline: 01_analisis_inicial | Version: intento01_figuras_español | <strong>117 figures included</strong></p>
</footer>

<script>
// Smooth scroll
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
    });
});

// Highlight TOC
window.addEventListener('scroll', () => {
    const sections = document.querySelectorAll('section[id]');
    const scrollPos = window.scrollY + 100;
    
    sections.forEach(section => {
        const top = section.offsetTop;
        const height = section.offsetHeight;
        const id = section.getAttribute('id');
        
        if (scrollPos >= top && scrollPos < top + height) {
            document.querySelectorAll('#toc a').forEach(a => a.classList.remove('active'));
            const activeLink = document.querySelector(`#toc a[href="#${id}"]`);
            if (activeLink) activeLink.classList.add('active');
        }
    });
});

// Zoom figuras
document.querySelectorAll('.result-figure').forEach(img => {
    img.style.cursor = 'pointer';
    img.addEventListener('click', function() {
        if (this.classList.contains('zoomed')) {
            this.classList.remove('zoomed');
        } else {
            document.querySelectorAll('.result-figure').forEach(i => i.classList.remove('zoomed'));
            this.classList.add('zoomed');
        }
    });
});

// Logging de carga
let loaded = 0, failed = 0;
document.querySelectorAll('.result-figure').forEach(img => {
    img.addEventListener('load', function() {
        loaded++;
        console.log(`✅ Loaded (${loaded}):`, this.src);
    });
    img.addEventListener('error', function() {
        failed++;
        console.error(`❌ Failed (${failed}):`, this.src);
    });
});

// Resumen final
setTimeout(() => {
    console.log(`\n📊 RESUMEN DE CARGA:\n✅ Loaded: ${loaded}\n❌ Failed: ${failed}\n`);
}, 5000);
</script>

</body>
</html>
""")

# ==============================================================================
# PASO 4: Guardar HTML
# ==============================================================================

print("\n💾 Paso 4: Guardando HTML DEFINITIVO...")

html_file = Path("reporte_completo_DEFINITIVO.html")
with open(html_file, 'w', encoding='utf-8') as f:
    f.writelines(html_output)

file_size = os.path.getsize(html_file) // 1024
print(f"   ✅ HTML guardado: {html_file}")
print(f"   📊 Tamaño: {file_size} KB\n")

# ==============================================================================
# PASO 5: Resumen
# ==============================================================================

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
print("✅ HTML V4 DEFINITIVO GENERADO\n")
print("📄 Archivo: reporte_completo_DEFINITIVO.html")
print(f"📊 Tamaño: {file_size} KB\n")
print("🎨 Figuras insertadas:")
for section, figs in section_figures.items():
    print(f"   • Sección {section}: {len(figs)} figuras")
print(f"\n   TOTAL: {figures_count} figuras\n")
print("🔍 Debugging:")
print("   • Abre DevTools (F12)")
print("   • Ve a Console")
print("   • Verás resumen de carga después de 5 segundos\n")
print("🌐 Para abrir:")
print("   open reporte_completo_DEFINITIVO.html\n")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")









