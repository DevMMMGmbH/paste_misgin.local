#!/usr/bin/env python3
"""
make_icon.py — Erzeugt AppIcon.icns für ClipFlow
Design: macOS-Stil, blau-indigo Gradient, weißes Clipboard-Symbol
"""

import math
import os
import subprocess
import struct
import zlib
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFilter, ImageFont
except ImportError:
    import sys
    subprocess.run([sys.executable, "-m", "pip", "install", "Pillow", "--quiet"])
    from PIL import Image, ImageDraw, ImageFilter

SCRIPT_DIR = Path(__file__).parent
ICONSET_DIR = SCRIPT_DIR / "AppIcon.iconset"
ICNS_OUT    = SCRIPT_DIR / "Sources" / "ClipboardManager" / "Resources" / "AppIcon.icns"

# ---------------------------------------------------------------------------
# Hilfsfunktionen
# ---------------------------------------------------------------------------

def rounded_rect_mask(size: int, radius_frac: float = 0.225) -> Image.Image:
    """Erzeugt eine weiche Maske für macOS-Rounded-Square."""
    r = int(size * radius_frac)
    mask = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle([0, 0, size - 1, size - 1], radius=r, fill=255)
    return mask

def gradient_background(size: int) -> Image.Image:
    """Blau-Indigo Gradient (oben links hell → unten rechts dunkel)."""
    img = Image.new("RGBA", (size, size), 0)
    pixels = img.load()

    # Farb-Stopps (RGBA)
    top_left     = (82, 130, 255, 255)   # helles Blau
    bottom_right = (90,  50, 210, 255)   # tiefes Indigo

    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * (size - 1))
            r = int(top_left[0] + t * (bottom_right[0] - top_left[0]))
            g = int(top_left[1] + t * (bottom_right[1] - top_left[1]))
            b = int(top_left[2] + t * (bottom_right[2] - top_left[2]))
            pixels[x, y] = (r, g, b, 255)
    return img

def draw_clipboard(draw: ImageDraw.Draw, size: int):
    """Zeichnet ein stilisiertes Clipboard-Symbol (weiß, leicht transparent)."""
    s = size
    pad = s * 0.18          # Außenabstand

    # --- Haupt-Clipboard-Körper ---
    bx0 = pad
    by0 = pad * 1.3
    bx1 = s - pad
    by1 = s - pad * 0.9
    br  = s * 0.07          # Eckenradius des Körpers

    draw.rounded_rectangle(
        [bx0, by0, bx1, by1],
        radius=br,
        fill=(255, 255, 255, 210)
    )

    # --- Klemme (Clip) oben zentriert ---
    cw = s * 0.28
    ch = s * 0.12
    cx0 = (s - cw) / 2
    cy0 = pad * 0.55
    cx1 = cx0 + cw
    cy1 = cy0 + ch
    cr  = s * 0.04

    # Klemmen-Hintergrund (etwas dunkler, damit sie über dem Body sichtbar ist)
    draw.rounded_rectangle(
        [cx0, cy0, cx1, cy1],
        radius=cr,
        fill=(200, 215, 255, 255)
    )
    # Inneres Loch der Klemme
    hole_margin = s * 0.025
    draw.rounded_rectangle(
        [cx0 + hole_margin, cy0 + hole_margin, cx1 - hole_margin, cy1 - hole_margin],
        radius=max(1, cr - 2),
        fill=(120, 155, 255, 200)
    )

    # --- Zeilen-Linien im Clipboard ---
    lx0 = bx0 + s * 0.1
    lx1 = bx1 - s * 0.1
    line_color = (130, 160, 230, 180)
    lw = max(2, int(s * 0.025))

    line_y_start = by0 + ch * 1.4 + s * 0.09
    line_gap     = s * 0.1

    for i in range(3):
        ly = line_y_start + i * line_gap
        # letzte Zeile kürzer (halbe Breite)
        end_x = lx1 if i < 2 else lx0 + (lx1 - lx0) * 0.5
        draw.rounded_rectangle(
            [lx0, ly, end_x, ly + lw],
            radius=lw // 2,
            fill=line_color
        )

    # --- Kleines "V"-Häkchen unten rechts (Paste-Symbol) ---
    tick_cx = bx1 - s * 0.14
    tick_cy = by1 - s * 0.14
    tr       = s * 0.11
    draw.ellipse(
        [tick_cx - tr, tick_cy - tr, tick_cx + tr, tick_cy + tr],
        fill=(70, 200, 140, 240)   # grüner Kreis
    )
    # Häkchen selbst
    hw = tr * 0.55
    hh = tr * 0.38
    tx = tick_cx - hw * 0.5
    ty = tick_cy - hh * 0.1
    pts = [
        (tx,          ty + hh * 0.5),
        (tx + hw * 0.4, ty + hh),
        (tx + hw,     ty - hh * 0.4),
    ]
    draw.line(pts, fill=(255, 255, 255, 255), width=max(2, int(tr * 0.35)))


def make_icon(size: int) -> Image.Image:
    """Erzeugt ein einzelnes quadratisches Icon in der gewünschten Größe."""
    # 2× intern rendern, dann runterskalieren → schärfere Kanten
    render_size = size * 2

    base = gradient_background(render_size)

    overlay = Image.new("RGBA", (render_size, render_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    draw_clipboard(draw, render_size)

    combined = Image.alpha_composite(base, overlay)

    # Rounded mask anwenden
    mask = rounded_rect_mask(render_size)
    result = Image.new("RGBA", (render_size, render_size), (0, 0, 0, 0))
    result.paste(combined, mask=mask)

    # Leichter Innen-Glanz (weißes Highlight oben)
    glow = Image.new("RGBA", (render_size, render_size), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    glow_h = int(render_size * 0.45)
    for gy in range(glow_h):
        alpha = int(40 * (1 - gy / glow_h) * math.sin(math.pi * gy / glow_h))
        gd.line([(0, gy), (render_size, gy)], fill=(255, 255, 255, alpha))
    glow_mask = rounded_rect_mask(render_size)
    glow_masked = Image.new("RGBA", (render_size, render_size), (0, 0, 0, 0))
    glow_masked.paste(glow, mask=glow_mask)
    result = Image.alpha_composite(result, glow_masked)

    # Auf Zielgröße runterskalieren
    return result.resize((size, size), Image.LANCZOS)


# ---------------------------------------------------------------------------
# Iconset erzeugen
# ---------------------------------------------------------------------------

SIZES = [
    ("icon_16x16.png",      16),
    ("icon_16x16@2x.png",   32),
    ("icon_32x32.png",      32),
    ("icon_32x32@2x.png",   64),
    ("icon_128x128.png",   128),
    ("icon_128x128@2x.png",256),
    ("icon_256x256.png",   256),
    ("icon_256x256@2x.png",512),
    ("icon_512x512.png",   512),
    ("icon_512x512@2x.png",1024),
]

print("🎨  Erzeuge Icon-Varianten …")
ICONSET_DIR.mkdir(exist_ok=True)

# Rendere 1024 einmal, skaliere dann herunter (schneller + konsistenter)
base_icon = make_icon(1024)

for filename, px in SIZES:
    icon = base_icon.resize((px, px), Image.LANCZOS) if px < 1024 else base_icon
    out = ICONSET_DIR / filename
    icon.save(out, "PNG")
    print(f"   ✓  {filename}  ({px}×{px})")

# ---------------------------------------------------------------------------
# .icns erzeugen
# ---------------------------------------------------------------------------

print("\n💾  Konvertiere zu AppIcon.icns …")
ICNS_OUT.parent.mkdir(parents=True, exist_ok=True)

result = subprocess.run(
    ["iconutil", "-c", "icns", str(ICONSET_DIR), "-o", str(ICNS_OUT)],
    capture_output=True, text=True
)
if result.returncode != 0:
    print("❌  iconutil Fehler:", result.stderr)
    raise SystemExit(1)

print(f"✅  Icon gespeichert: {ICNS_OUT}")
print(f"   Iconset:           {ICONSET_DIR}")
