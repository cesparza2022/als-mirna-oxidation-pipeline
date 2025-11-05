#!/usr/bin/env python3
"""
Lista TODAS las figuras que están en el HTML, agrupadas por sección
"""

import re
from pathlib import Path

with open("reporte_completo_DEFINITIVO.html", 'r') as f:
    html = f.read()

# Extraer figuras con contexto
sections = re.split(r'<h3[^>]*>([^<]+)</h3>', html)

print("""
╔═══════════════════════════════════════════════════════════════════════════╗
║         📋 LISTA DE FIGURAS EN EL HTML                                    ║
╚═══════════════════════════════════════════════════════════════════════════╝
""")

current_section = None
total = 0

for i in range(1, len(sections), 2):
    section_title = sections[i]
    section_content = sections[i+1] if i+1 < len(sections) else ""
    
    # Buscar figuras en esta sección
    figs = re.findall(r'src="(figures/[^"]+\.png)"', section_content)
    
    if figs:
        # Extraer número de sección si existe
        match = re.search(r'(\d+\.\d+)', section_title)
        if match:
            print(f"\n{'='*75}")
            print(f"📊 {section_title}")
            print(f"{'='*75}\n")
            
            for j, fig in enumerate(figs, 1):
                fname = Path(fig).name
                print(f"  {j:2d}. {fname}")
                total += 1
            
            print(f"\n   Subtotal: {len(figs)} figuras")

print(f"\n{'='*75}")
print(f"\n✅ TOTAL: {total} figuras en el HTML\n")
print("="*75 + "\n")
