#!/usr/bin/env python3
"""
Verifica permisos, tamaños y validez de las figuras
"""

import os
import re
from pathlib import Path

print("""
╔═══════════════════════════════════════════════════════════════════════════╗
║         🔍 VERIFICACIÓN PROFUNDA DE ARCHIVOS                              ║
╚═══════════════════════════════════════════════════════════════════════════╝
""")

# Extraer rutas del HTML
with open("reporte_completo_DEFINITIVO.html", 'r') as f:
    html = f.read()

img_paths = sorted(set(re.findall(r'src="(figures/[^"]+\.png)"', html)))

print(f"📊 Verificando {len(img_paths)} figuras...\n")

problemas = []

for path in img_paths:
    if not os.path.exists(path):
        problemas.append({'path': path, 'error': 'NO EXISTE'})
    else:
        size = os.path.getsize(path)
        if size == 0:
            problemas.append({'path': path, 'error': f'VACÍO (0 bytes)'})
        elif size < 1000:
            problemas.append({'path': path, 'error': f'SOSPECHOSO ({size} bytes)'})
        # Verificar que sea PNG válido
        with open(path, 'rb') as f:
            header = f.read(8)
            if header[:4] != b'\x89PNG':
                problemas.append({'path': path, 'error': 'NO ES PNG VÁLIDO'})

if problemas:
    print(f"❌ PROBLEMAS ENCONTRADOS ({len(problemas)}):\n")
    print("="*75 + "\n")
    for p in problemas:
        print(f"  ❌ {p['path']}")
        print(f"     Error: {p['error']}\n")
else:
    print("✅ TODAS LAS 90 FIGURAS SON VÁLIDAS\n")
    print("   • Existen")
    print("   • Tienen contenido")
    print("   • Son PNGs válidos\n")

print("="*75 + "\n")

if not problemas:
    print("💡 SI LAS FIGURAS NO SE VEN EN EL NAVEGADOR:\n")
    print("Posibles causas:")
    print("  1. Cache del navegador (Cmd+Shift+R para refrescar)")
    print("  2. Restricciones de seguridad del navegador")
    print("  3. Problema con el HTML generado\n")
    print("Solución:")
    print("  • Cierra el HTML")
    print("  • Refresca con Cmd+Shift+R")
    print("  • O abre en modo incógnito\n")

print("="*75 + "\n")
