#!/usr/bin/env python3
"""
==============================================================================
GENERADOR HTML V3 - RUTAS CORRECTAS DE FIGURAS
==============================================================================

Corrección crítica: Usar rutas relativas correctas desde el HTML
==============================================================================
"""

import re
import os
from pathlib import Path
from glob import glob

print("""
╔═══════════════════════════════════════════════════════════════════════════╗
║         🚀 GENERANDO HTML V3 - RUTAS CORREGIDAS                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
""")

# ==============================================================================
# FUNCIONES AUXILIARES
# ==============================================================================

def find_figures_for_step(step_name):
    """Encuentra todas las figuras para un paso específico"""
    figures = []
    
    # Buscar en carpetas organizadas (RUTAS RELATIVAS DESDE HTML)
    paso_dirs = [
        f"figures/{step_name}/",
        f"figures/paso{step_name}/",
    ]
    
    for pdir in paso_dirs:
        # Buscar desde el directorio actual (donde está el script)
        search_path = f"../../{pdir}"
        if os.path.exists(search_path):
            pngs = glob(f"{search_path}*.png")
            for png in pngs:
                # Usar ruta relativa desde el HTML
                fig_name = Path(png).stem
                figures.append({
                    'path': pdir + Path(png).name,  # Ruta relativa desde HTML
                    'name': fig_name.replace('_', ' ').title(),
                    'file': Path(png).name
                })
    
    # Buscar figuras sueltas que empiecen con ese paso
    sueltas = glob(f"../../figures/{step_name}*.png")
    for png in sueltas:
        fig_name = Path(png).stem
        figures.append({
            'path': f"figures/{Path(png).name}",  # Ruta relativa desde HTML
            'name': fig_name.replace('_', ' ').title(),
            'file': Path(png).name
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
    <img src="{fig['path']}" alt="{fig['name']}" class="result-figure" loading="lazy" onerror="this.onerror=null; this.src='data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 width=%22400%22 height=%22300%22%3E%3Crect fill=%22%23f0f0f0%22 width=%22400%22 height=%22300%22/%3E%3Ctext x=%2250%25%22 y=%2250%25%22 text-anchor=%22middle%22 fill=%22%23999%22%3EImage not found%3C/text%3E%3C/svg%3E';">
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

# Mapa de secciones Results a carpetas de figuras
section_to_figures = {
    '3.1': ['paso1_evolucion_dataset', 'paso1_snvs_por_region', 'paso1_top_mirnas', 'paso1_top_posiciones'],
    '3.2': ['paso2_tipos_mutacion', 'paso2_gt_por_region', 'paso2_gt_por_posicion', 'paso2_gt_por_mirna'],
    '3.3': ['paso3_histograma_vafs', 'paso3_distribucion_categorias_vaf', 'paso3c_vafs_region'],
    '3.4': ['paso4a_significancia'],
    '4.1': ['paso5a_outliers_muestras', 'paso5a_profundizar_outliers'],
    '4.2': ['paso6a_metadatos'],
    '4.3': ['paso7a_temporal'],
    '5.1': ['paso8_mirnas_gt_semilla', 'paso8b_comparativo_detallado', 'paso8c_visualizaciones_avanzadas'],
    '5.2': ['paso9_motivos_secuencia'],
    '5.3': ['paso9b_motivos_completo', 'paso9c_semilla_completa', 'paso9d_secuencias_similares', 'paso10a_let7_vs_mir4500', 'paso10b_resistentes', 'paso10c_comutaciones_let7', 'paso10d_motivos_extendidos'],
    '6.1': ['paso11_pathway'],
}

figures_count = 0
for section, steps in section_to_figures.items():
    for step in steps:
        figs = find_figures_for_step(step)
        figures_count += len(figs)

print(f"   ✅ Encontradas {figures_count} figuras para insertar\n")

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
        # Escape HTML in code
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
        # Process table
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
                    # Process bold in cells
                    cell = re.sub(r'\*\*(.*?)\*\*', r'<strong>\1</strong>', cell)
                    html_output.append(f'  <td>{cell}</td>\n')
                html_output.append('</tr>\n')
        html_output.append('</tbody></table></div>\n\n')
        in_table = False
        table_lines = []
    
    # Detect section changes and insert figures
    if line.startswith('### ') and ('Step' in line or 'step' in line.lower()):
        # Extract section number
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
        
        # Close previous section if open
        if i > 0:
            html_output.append('</section>\n\n')
        
        html_output.append(f'<section id="{section_id}" class="section">\n')
        html_output.append(f'<h2>{text}</h2>\n')
        continue
    elif line.startswith('### '):
        text = line[4:]
        section_id = re.sub(r'[^a-z0-9]+', '-', text.lower()).strip('-')
        html_output.append(f'<h3 id="{section_id}">{text}</h3>\n')
        
        # Insertar figuras después del h3 si es un Step
        if current_section and not figures_inserted_in_section and current_section in section_to_figures:
            all_figs = []
            for step in section_to_figures[current_section]:
                figs = find_figures_for_step(step)
                all_figs.extend(figs)
            
            if all_figs:
                html_output.append(create_figure_gallery(all_figs, f"Figures for Section {current_section}"))
                figures_inserted_in_section = True
                print(f"   📊 Insertadas {len(all_figs)} figuras en sección {current_section}")
        
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
        # Process bold, italic, code
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
    <p>Pipeline: 01_analisis_inicial | Version: intento01_figuras_español</p>
</footer>

<script>
// Smooth scroll para navegación
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
    });
});

// Highlight TOC activo
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

// Zoom de figuras al click
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

// Log de imágenes que no cargan (para debugging)
document.querySelectorAll('.result-figure').forEach(img => {
    img.addEventListener('error', function() {
        console.error('Failed to load image:', this.src);
    });
    img.addEventListener('load', function() {
        console.log('Successfully loaded:', this.src);
    });
});
</script>

</body>
</html>
""")

# ==============================================================================
# PASO 4: Guardar HTML
# ==============================================================================

print("\n💾 Paso 4: Guardando HTML con rutas corregidas...")

html_file = Path("reporte_completo_FINAL.html")
with open(html_file, 'w', encoding='utf-8') as f:
    f.writelines(html_output)

file_size = os.path.getsize(html_file) // 1024
print(f"   ✅ HTML guardado: {html_file}")
print(f"   📊 Tamaño: {file_size} KB\n")

# ==============================================================================
# PASO 5: Resumen
# ==============================================================================

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
print("✅ HTML V3 GENERADO CON RUTAS CORREGIDAS\n")
print("📄 Archivo: reporte_completo_FINAL.html")
print(f"📊 Tamaño: {file_size} KB\n")
print("🎨 Características:")
print("   • Rutas relativas correctas (figures/...)")
print("   • Fallback para imágenes no encontradas")
print("   • Console logging para debugging")
print(f"   • ~{figures_count} figuras con rutas corregidas\n")
print("🌐 Para abrir:")
print("   open reporte_completo_FINAL.html\n")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")








