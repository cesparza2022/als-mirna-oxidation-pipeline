#!/usr/bin/env python3
"""
Identifica EXACTAMENTE qué figuras el HTML pide pero no existen
"""

import os
import re
from pathlib import Path

print("""
╔═══════════════════════════════════════════════════════════════════════════╗
║         🔍 DIAGNÓSTICO: FIGURAS QUE FALLAN                                ║
╚═══════════════════════════════════════════════════════════════════════════╝
""")

# 1. Leer HTML y extraer TODAS las rutas de imágenes
print("📄 Paso 1: Extrayendo rutas del HTML...\n")

with open("reporte_completo_DEFINITIVO.html", 'r') as f:
    html = f.read()

img_paths = re.findall(r'src="(figures/[^"]+\.png)"', html)
img_paths = sorted(set(img_paths))

print(f"   ✅ {len(img_paths)} rutas únicas en el HTML\n")

# 2. Verificar cuáles EXISTEN
print("🔍 Paso 2: Verificando existencia...\n")

existentes = []
faltantes = []

for path in img_paths:
    if os.path.exists(path):
        existentes.append(path)
    else:
        faltantes.append(path)

print(f"   ✅ Existen: {len(existentes)}")
print(f"   ❌ Faltan: {len(faltantes)}\n")

# 3. Mostrar las faltantes
if faltantes:
    print("="*75)
    print(f"\n❌ FIGURAS QUE EL HTML PIDE PERO NO EXISTEN ({len(faltantes)}):\n")
    print("="*75 + "\n")
    
    for i, path in enumerate(faltantes, 1):
        print(f"{i:2d}. {path}")
    
    print("\n" + "="*75 + "\n")
    
    # Agrupar por tipo
    print("📊 Agrupadas por carpeta:\n")
    carpetas = {}
    for path in faltantes:
        parts = Path(path).parts
        if len(parts) > 2:  # figures/carpeta/archivo.png
            carpeta = parts[1]
            if carpeta not in carpetas:
                carpetas[carpeta] = []
            carpetas[carpeta].append(Path(path).name)
        else:  # figures/archivo.png
            if 'sueltos' not in carpetas:
                carpetas['sueltos'] = []
            carpetas['sueltos'].append(Path(path).name)
    
    for carpeta in sorted(carpetas.keys()):
        print(f"  📁 {carpeta}: {len(carpetas[carpeta])} faltantes")
        for archivo in carpetas[carpeta][:3]:
            print(f"     • {archivo}")
        if len(carpetas[carpeta]) > 3:
            print(f"     ... y {len(carpetas[carpeta])-3} más")
        print()
    
else:
    print("✅ ¡TODAS LAS FIGURAS DEL HTML EXISTEN!\n")

print("="*75 + "\n")
print("💡 SOLUCIÓN:\n")
print("Si hay faltantes, necesitamos:")
print("  1. Verificar si existen con otro nombre")
print("  2. Copiarlas desde ../../figures/")
print("  3. O eliminar las referencias del HTML\n")
print("="*75 + "\n")
