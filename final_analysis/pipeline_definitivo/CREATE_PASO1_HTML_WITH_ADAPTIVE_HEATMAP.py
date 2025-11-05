#!/usr/bin/env python3
"""
Script para generar HTML completo del Paso 1 con heatmap adaptativo
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path
import warnings
warnings.filterwarnings('ignore')

# Configuración
BASE_DIR = Path("/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/pipeline_definitivo")
DATA_DIR = BASE_DIR / "01_analisis_inicial" / "tables"
OUTPUT_FILE = BASE_DIR / "PASO_1_ANALISIS_COMPLETO_CON_HEATMAP_ADAPTATIVO.html"

print("📊 Generando HTML del Paso 1 con heatmap adaptativo...")

# Cargar datos
print("📊 Cargando datos...")
data = pd.read_csv(DATA_DIR / "mutaciones_gt_detalladas.csv")

# Extraer miRNA y posición
data['miRNA'] = data['miRNA name']
data['Position'] = data['pos:mut'].str.split(':').str[0].astype(int)

# Calcular conteos de G>T por miRNA y posición
gt_counts = data.groupby(['miRNA', 'Position']).size().reset_index(name='Count')

# Crear matriz para heatmap
heatmap_data = gt_counts.pivot(index='miRNA', columns='Position', values='Count')
heatmap_data = heatmap_data.fillna(0)

# Análisis estadístico para escala adaptativa
stats = {
    'max': heatmap_data.values.max(),
    'mean': heatmap_data.values.mean(),
    'median': np.median(heatmap_data.values),
    'pct_zeros': (heatmap_data.values == 0).sum() / heatmap_data.values.size * 100,
    'q75': np.percentile(heatmap_data.values, 75),
    'q90': np.percentile(heatmap_data.values, 90),
    'q95': np.percentile(heatmap_data.values, 95)
}

print(f"📊 Estadísticas:")
print(f"   Máximo: {stats['max']:.0f}")
print(f"   Media: {stats['mean']:.2f}")
print(f"   Mediana: {stats['median']:.0f}")
print(f"   % Ceros: {stats['pct_zeros']:.1f}%")

# Decidir estrategia de escala
if stats['pct_zeros'] > 80:
    method = "percentile"
    breaks = [0, 1, 2, 3, 5, 8, 12, 18, 25, 35, stats['max']]
elif stats['max'] > 100:
    method = "logarithmic"
    breaks = [0, 1, 2, 4, 8, 16, 32, 64, 128, stats['max']]
else:
    method = "linear"
    breaks = np.linspace(0, stats['max'], 11)

print(f"🎯 Estrategia: {method}")
print(f"📊 Breaks: {len(breaks)} niveles")

# Generar heatmap adaptativo
print("🎨 Generando heatmap...")
fig, ax = plt.subplots(figsize=(14, 10))

# Crear heatmap con escala adaptativa
if method == "percentile":
    cmap = sns.color_palette("YlOrRd", as_cmap=True)
elif method == "logarithmic":
    cmap = sns.color_palette("rocket", as_cmap=True)
else:
    cmap = sns.color_palette("Blues", as_cmap=True)

# Limitar número de miRNAs si hay muchos (mostrar solo top por total)
if len(heatmap_data) > 100:
    top_mirnas = heatmap_data.sum(axis=1).nlargest(100).index
    heatmap_data_plot = heatmap_data.loc[top_mirnas]
    note = f"Mostrando top 100 miRNAs de {len(heatmap_data)}"
else:
    heatmap_data_plot = heatmap_data
    note = f"Mostrando todos los {len(heatmap_data)} miRNAs"

sns.heatmap(
    heatmap_data_plot,
    cmap=cmap,
    vmin=breaks[0],
    vmax=breaks[-1],
    cbar_kws={'label': 'G>T Count'},
    linewidths=0.1,
    linecolor='white',
    ax=ax
)

ax.set_xlabel('Position', fontsize=12, fontweight='bold')
ax.set_ylabel('miRNA', fontsize=12, fontweight='bold')
ax.set_title(f'G>T Positional Distribution (Adaptive {method} scale)\n{note}', 
             fontsize=14, fontweight='bold', pad=20)

plt.xticks(rotation=45, ha='right')
plt.yticks(fontsize=7)
plt.tight_layout()

# Guardar figura
fig_path = BASE_DIR / "01_analisis_inicial" / "figures" / "HEATMAP_ADAPTIVE.png"
fig_path.parent.mkdir(parents=True, exist_ok=True)
plt.savefig(fig_path, dpi=150, bbox_inches='tight')
plt.close()

print(f"✅ Heatmap guardado: {fig_path.name}")

# Buscar todas las figuras del paso 1
print("\n📊 Buscando figuras del Paso 1...")
figures_dir = BASE_DIR / "01_analisis_inicial" / "figures"
all_figures = list(figures_dir.glob("*.png")) if figures_dir.exists() else []

# Organizar figuras
key_figures = {
    'heatmap': str(fig_path),
    'overview': None,
    'spectrum': None,
    'positional': None,
    'seed': None
}

# Buscar figuras específicas
for fig in all_figures:
    fig_lower = fig.name.lower()
    if 'overview' in fig_lower or 'panel_a' in fig_lower:
        key_figures['overview'] = str(fig)
    elif 'spectrum' in fig_lower or 'panel_c' in fig_lower or 'panel_f' in fig_lower:
        key_figures['spectrum'] = str(fig)
    elif 'positional' in fig_lower or 'panel_d' in fig_lower:
        key_figures['positional'] = str(fig)
    elif 'seed' in fig_lower:
        key_figures['seed'] = str(fig)

print(f"✅ Encontradas {len([v for v in key_figures.values() if v])} figuras clave")

# Generar HTML
print("\n🎨 Generando HTML...")

html_content = f"""
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Paso 1: Análisis Inicial Completo</title>
    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}
        
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            line-height: 1.6;
            color: #333;
            background: #f5f7fa;
            padding: 20px;
        }}
        
        .container {{
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            border-radius: 12px;
            box-shadow: 0 2px 20px rgba(0,0,0,0.1);
            overflow: hidden;
        }}
        
        header {{
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 40px;
            text-align: center;
        }}
        
        header h1 {{
            font-size: 2.5rem;
            margin-bottom: 10px;
            font-weight: 700;
        }}
        
        header p {{
            font-size: 1.1rem;
            opacity: 0.95;
        }}
        
        .section {{
            padding: 40px;
            border-bottom: 1px solid #e1e8ed;
        }}
        
        .section:last-child {{
            border-bottom: none;
        }}
        
        .section-title {{
            font-size: 1.8rem;
            color: #667eea;
            margin-bottom: 25px;
            font-weight: 700;
            display: flex;
            align-items: center;
            gap: 10px;
        }}
        
        .figure-container {{
            margin: 30px 0;
            background: #f8f9fa;
            border-radius: 8px;
            padding: 20px;
        }}
        
        .figure-title {{
            font-size: 1.3rem;
            color: #2c3e50;
            margin-bottom: 15px;
            font-weight: 600;
        }}
        
        .figure-img {{
            width: 100%;
            height: auto;
            border-radius: 8px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
        }}
        
        .stats-grid {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin: 20px 0;
        }}
        
        .stat-card {{
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 8px;
            text-align: center;
        }}
        
        .stat-value {{
            font-size: 2.5rem;
            font-weight: 700;
            margin: 10px 0;
        }}
        
        .stat-label {{
            font-size: 0.9rem;
            opacity: 0.9;
            text-transform: uppercase;
            letter-spacing: 1px;
        }}
        
        .note {{
            background: #fff3cd;
            border-left: 4px solid #ffc107;
            padding: 15px;
            margin: 20px 0;
            border-radius: 4px;
        }}
        
        .note strong {{
            color: #856404;
        }}
        
        footer {{
            background: #2c3e50;
            color: white;
            padding: 20px;
            text-align: center;
        }}
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>📊 Paso 1: Análisis Inicial Completo</h1>
            <p>Caracterización Global del Dataset de G>T en miRNAs</p>
        </header>
        
        <div class="section">
            <div class="section-title">📈 Estadísticas del Heatmap Adaptativo</div>
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-label">Estrategia</div>
                    <div class="stat-value">{method.upper()}</div>
                </div>
                <div class="stat-card">
                    <div class="stat-label">Máximo</div>
                    <div class="stat-value">{stats['max']:.0f}</div>
                </div>
                <div class="stat-card">
                    <div class="stat-label">Media</div>
                    <div class="stat-value">{stats['mean']:.2f}</div>
                </div>
                <div class="stat-card">
                    <div class="stat-label">% Ceros</div>
                    <div class="stat-value">{stats['pct_zeros']:.1f}%</div>
                </div>
            </div>
            
            <div class="note">
                <strong>⚠️ Importante:</strong> La escala se ajusta automáticamente según los datos. 
                Con {stats['pct_zeros']:.1f}% de ceros, se usa una escala <strong>{method}</strong> 
                para maximizar el contraste y la visibilidad de patrones.
            </div>
        </div>
        
        <div class="section">
            <div class="section-title">🔥 Heatmap Adaptativo: Distribución Posicional de G>T</div>
            <div class="figure-container">
                <div class="figure-title">A. Distribución G>T por miRNA y Posición (Escala {method.capitalize()})</div>
                <img src="{fig_path.relative_to(BASE_DIR)}" class="figure-img" alt="Heatmap Adaptativo">
            </div>
"""

# Agregar figuras adicionales si existen
if key_figures['overview']:
    html_content += f"""
        </div>
        
        <div class="section">
            <div class="section-title">📊 Visión General del Dataset</div>
            <div class="figure-container">
                <div class="figure-title">B. Overview del Dataset</div>
                <img src="{Path(key_figures['overview']).relative_to(BASE_DIR)}" class="figure-img" alt="Overview">
            </div>
"""

if key_figures['spectrum']:
    html_content += f"""
            <div class="figure-container">
                <div class="figure-title">C. Espectro de Mutaciones</div>
                <img src="{Path(key_figures['spectrum']).relative_to(BASE_DIR)}" class="figure-img" alt="Spectrum">
            </div>
"""

if key_figures['positional']:
    html_content += f"""
            <div class="figure-container">
                <div class="figure-title">D. Análisis Posicional</div>
                <img src="{Path(key_figures['positional']).relative_to(BASE_DIR)}" class="figure-img" alt="Positional">
            </div>
"""

if key_figures['seed']:
    html_content += f"""
            <div class="figure-container">
                <div class="figure-title">E. Análisis de la Región Seed</div>
                <img src="{Path(key_figures['seed']).relative_to(BASE_DIR)}" class="figure-img" alt="Seed">
            </div>
"""

# Cerrar HTML
html_content += """
        </div>
        
        <footer>
            <p><strong>Pipeline Definitivo</strong> | Paso 1: Análisis Inicial Completo</p>
            <p>Sistema de Escalas Adaptativas Implementado</p>
        </footer>
    </div>
</body>
</html>
"""

# Guardar HTML
with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
    f.write(html_content)

print(f"\n✅ HTML generado: {OUTPUT_FILE.name}")
print(f"\n📁 Ubicación: {OUTPUT_FILE}")
print("\n✨ ¡Listo! Abre el archivo HTML para ver el resultado.")

