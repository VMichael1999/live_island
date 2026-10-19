"""Genera las imágenes genéricas de los presets de diseño (assets/presets/).

Son dibujos propios, sin marcas ni fotos de terceros.
Uso: python3 tool/make_design_assets.py
"""
from PIL import Image, ImageDraw, ImageFilter
import os

OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'presets')
K = 4  # supermuestreo


def top_car():
    w, h = 176, 92
    im = Image.new('RGBA', (w * K, h * K), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    s = lambda *a: [v * K for v in a]
    # sombra suave
    sh = Image.new('RGBA', im.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle(s(8, 18, 172, 80), radius=30 * K, fill=(0, 0, 0, 28))
    im.alpha_composite(sh.filter(ImageFilter.GaussianBlur(4 * K)))
    d.rounded_rectangle(s(6, 12, 170, 76), radius=30 * K, fill=(245, 245, 247, 255), outline=(150, 152, 158, 255), width=2 * K)
    d.rounded_rectangle(s(38, 22, 66, 66), radius=8 * K, fill=(32, 34, 40, 255))      # luneta trasera
    d.rounded_rectangle(s(100, 22, 128, 66), radius=8 * K, fill=(32, 34, 40, 255))    # parabrisas
    d.rounded_rectangle(s(68, 24, 98, 64), radius=6 * K, fill=(252, 252, 253, 255))   # techo
    d.arc(s(8, 14, 40, 74), 100, 260, fill=(240, 120, 90, 255), width=5 * K)          # luces traseras
    d.ellipse(s(128, 8, 140, 16), fill=(30, 30, 34, 255))                              # espejos
    d.ellipse(s(128, 72, 140, 80), fill=(30, 30, 34, 255))
    return im.resize((w * 2, h * 2), Image.LANCZOS)


def side_car():
    w, h = 200, 84
    im = Image.new('RGBA', (w * K, h * K), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    s = lambda *a: [v * K for v in a]
    sh = Image.new('RGBA', im.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).ellipse(s(12, 66, 190, 80), fill=(0, 0, 0, 70))
    im.alpha_composite(sh.filter(ImageFilter.GaussianBlur(4 * K)))
    body = [(8, 58), (10, 44), (34, 38), (58, 20), (66, 14), (126, 14), (150, 36), (186, 42), (194, 52), (194, 62), (8, 62)]
    d.polygon([(x * K, y * K) for x, y in body], fill=(248, 248, 250, 255), outline=(150, 152, 158, 255))
    d.line([(x * K, y * K) for x, y in body + [body[0]]], fill=(150, 152, 158, 255), width=2 * K, joint='curve')
    win = [(64, 22), (70, 17), (122, 17), (140, 36), (60, 36)]
    d.polygon([(x * K, y * K) for x, y in win], fill=(40, 46, 58, 255))
    d.line([(96 * K, 17 * K), (96 * K, 36 * K)], fill=(248, 248, 250, 255), width=3 * K)
    d.rectangle(s(180, 48, 194, 52), fill=(255, 240, 200, 255))                          # faro
    for cx in (50, 156):
        d.ellipse(s(cx - 15, 50, cx + 15, 80), fill=(24, 26, 30, 255))
        d.ellipse(s(cx - 7, 58, cx + 7, 72), fill=(150, 154, 164, 255))
    return im.resize((w * 2, h * 2), Image.LANCZOS)


def crest(top, bottom, accent, name):
    """Escudo genérico: mitad superior de un color, inferior de otro y una estrella."""
    w, h = 120, 140
    im = Image.new('RGBA', (w * K, h * K), (0, 0, 0, 0))
    s = lambda *a: [v * K for v in a]
    shape = Image.new('L', im.size, 0)
    sd = ImageDraw.Draw(shape)
    pts = [(8, 8), (112, 8), (112, 70), (100, 100), (60, 132), (20, 100), (8, 70)]
    sd.polygon([(x * K, y * K) for x, y in pts], fill=255)
    art = Image.new('RGBA', im.size, top)
    ad = ImageDraw.Draw(art)
    ad.rectangle(s(0, 70, 120, 140), fill=bottom)
    ad.rectangle(s(52, 8, 68, 140), fill=accent)
    star = []
    import math
    cx, cy, R, r = 60, 44, 22, 9
    for i in range(10):
        a = -math.pi / 2 + i * math.pi / 5
        rad = R if i % 2 == 0 else r
        star.append(((cx + rad * math.cos(a)) * K, (cy + rad * math.sin(a)) * K))
    ad.polygon(star, fill=(255, 255, 255, 255))
    im.paste(art, (0, 0), shape)
    d = ImageDraw.Draw(im)
    d.line([(x * K, y * K) for x, y in pts + [pts[0]]], fill=(255, 255, 255, 255), width=4 * K, joint='curve')
    return im.resize((w * 2, h * 2), Image.LANCZOS)


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    top_car().save(os.path.join(OUT, 'car_top.png'), optimize=True)
    side_car().save(os.path.join(OUT, 'car_side.png'), optimize=True)
    crest((16, 58, 140, 255), (200, 30, 50, 255), (240, 240, 245, 255), 'a').save(
        os.path.join(OUT, 'crest_a.png'), optimize=True)
    crest((250, 200, 20, 255), (20, 40, 110, 255), (20, 40, 110, 255), 'b').save(
        os.path.join(OUT, 'crest_b.png'), optimize=True)
    print('listo')
