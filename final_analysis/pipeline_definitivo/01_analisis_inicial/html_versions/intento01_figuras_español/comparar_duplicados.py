#!/usr/bin/env python3
"""
Compara figuras para detectar posibles duplicados por nombre/tamaño
"""

import os
from pathlib import Path
from glob import glob

print("🔍 Buscando posibles duplicados por nombre...\n")

# Listar todas las figuras
all_figs = glob("figures/*.png") + glob("figures/*/*.png")

# Agrupar por nombre base (sin prefijo paso)
import re

base_names = {}
for fig in all_figs:
    fname = Path(fig).stem
    # Quitar prefijos como paso1_, paso2_, 01_, 02_, gt_
    base = re.sub(r'^(paso\d+[a-z]?_|0?\d+_|gt_)', '', fname)
    
    if base not in base_names:
        base_names[base] = []
    base_names[base].append(fig)

# Mostrar posibles duplicados
duplicates = {k: v for k, v in base_names.items() if len(v) > 1}

if duplicates:
    print(f"⚠️  Posibles duplicados encontrados ({len(duplicates)} grupos):\n")
    for base, figs in sorted(duplicates.items())[:10]:
        print(f"  📊 {base}:")
        for fig in figs:
            size = os.path.getsize(fig) // 1024
            print(f"     • {Path(fig).name} ({size} KB)")
        print()
    
    if len(duplicates) > 10:
        print(f"  ... y {len(duplicates)-10} grupos más\n")
else:
    print("✅ No se detectaron duplicados obvios\n")

print("="*75 + "\n")
print("💡 RECOMENDACIÓN:\n")
print("Las figuras sin prefijo 'pasoX_' probablemente son versiones antiguas.")
print("El HTML actual tiene las figuras organizadas con prefijos 'pasoX_'.\n")
print("Opciones:")
print("  1. Dejar el HTML así (90 figuras organizadas)")
print("  2. Agregar las 27 faltantes también")
print("\n")
