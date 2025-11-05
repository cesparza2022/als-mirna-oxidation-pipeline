#!/usr/bin/env python3
"""
Verifica qué figuras REALMENTE existen vs cuáles el HTML intenta cargar
"""

import os
from pathlib import Path
from glob import glob
import re

print("""
╔═══════════════════════════════════════════════════════════════════════════╗
║         🔍 VERIFICACIÓN DE FIGURAS                                        ║
╚═══════════════════════════════════════════════════════════════════════════╝
""")

# 1. Listar TODAS las figuras que EXISTEN
print("📊 Paso 1: Figuras que EXISTEN en figures/...\n")

existing_figures = []

# PNGs sueltos
for png in glob("figures/*.png"):
    existing_figures.append(Path(png).relative_to("figures"))

# PNGs en carpetas
for png in glob("figures/*/*.png"):
    existing_figures.append(Path(png).relative_to("figures"))

existing_figures = sorted(set(existing_figures))

print(f"✅ Total de figuras existentes: {len(existing_figures)}\n")

# Agrupar por paso
pasos = {}
for fig in existing_figures:
    match = re.match(r'(paso\d+[a-z]?)', str(fig))
    if match:
        paso = match.group(1)
        if paso not in pasos:
            pasos[paso] = []
        pasos[paso].append(str(fig))

print("Agrupadas por paso:\n")
for paso in sorted(pasos.keys()):
    print(f"  {paso}: {len(pasos[paso])} figuras")

print("\n" + "="*75 + "\n")

# 2. Listar figuras que el HTML INTENTA cargar
print("📄 Paso 2: Figuras que el HTML INTENTA cargar...\n")

with open("reporte_completo_DEFINITIVO.html", 'r') as f:
    html_content = f.read()

# Buscar todos los src="figures/..."
img_refs = re.findall(r'src="(figures/[^"]+\.png)"', html_content)
img_refs = sorted(set(img_refs))

print(f"✅ Total de referencias en HTML: {len(img_refs)}\n")

# 3. Comparar
print("="*75 + "\n")
print("🔍 Paso 3: Comparando...\n")

# Convertir a sets para comparar
existing_set = set(str(f) for f in existing_figures)
html_set = set(ref.replace('figures/', '') for ref in img_refs)

# Figuras que existen pero NO están en HTML
missing_in_html = existing_set - html_set
if missing_in_html:
    print(f"⚠️  Figuras que EXISTEN pero NO están en HTML ({len(missing_in_html)}):\n")
    for fig in sorted(missing_in_html)[:20]:
        print(f"   • {fig}")
    if len(missing_in_html) > 20:
        print(f"   ... y {len(missing_in_html)-20} más")
else:
    print("✅ Todas las figuras existentes están en el HTML\n")

print("\n" + "-"*75 + "\n")

# Figuras que el HTML pide pero NO EXISTEN
missing_files = html_set - existing_set
if missing_files:
    print(f"❌ Figuras que el HTML pide pero NO EXISTEN ({len(missing_files)}):\n")
    for fig in sorted(missing_files):
        print(f"   • {fig}")
else:
    print("✅ Todas las figuras del HTML existen\n")

print("\n" + "="*75 + "\n")

# 4. Resumen
print("📊 RESUMEN:\n")
print(f"  Figuras existentes: {len(existing_figures)}")
print(f"  Referencias en HTML: {len(img_refs)}")
print(f"  Faltantes en HTML: {len(missing_in_html)}")
print(f"  Archivos no encontrados: {len(missing_files)}")

if len(missing_files) == 0 and len(missing_in_html) == 0:
    print("\n✅ ¡PERFECTO! Todas las figuras coinciden\n")
else:
    print(f"\n⚠️  Hay discrepancias que resolver\n")

print("="*75 + "\n")
