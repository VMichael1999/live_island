"""Genera la cabecera del README y de pub.dev: doc/assets/banner.png (inglés, la
principal) y doc/assets/banner.es.png (español, para README.es.md).

Uso: python3 tool/make_banner.py [nombre_del_paquete]
Usa las imágenes de doc/assets/galeria/ (que genera test/readme_gallery_test.dart).
"""
import sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

NAME = sys.argv[1] if len(sys.argv) > 1 else 'live_island_kit'
W, H = 1600, 560
GAL = 'doc/assets/galeria/'
FONT = '/System/Library/Fonts/Avenir Next.ttc'


def font(size, bold=False):
    # Avenir Next.ttc: 0 = Bold, 7 = Medium
    return ImageFont.truetype(FONT, size, index=0 if bold else 7)


def gradient():
    top, bottom = (0x1B, 0x2B, 0x44), (0x08, 0x0C, 0x14)
    im = Image.new('RGB', (W, H))
    px = im.load()
    for y in range(H):
        for x in range(W):
            t = min(1, (x / W) * 0.6 + (y / H) * 0.5)
            px[x, y] = tuple(round(a + (b - a) * t) for a, b in zip(top, bottom))
    return im


def card(name, width):
    """Una captura de la galería sin su fondo liso, con esquinas redondeadas."""
    im = Image.open(GAL + name + '.png').convert('RGBA')
    w, h = im.size
    im = im.crop((int(w * .02), int(h * .02), int(w * .98), int(h * .98)))
    im = im.resize((width, round(im.size[1] * width / im.size[0])), Image.LANCZOS)
    mask = Image.new('L', im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, im.size[0] - 1, im.size[1] - 1), 36, fill=255)
    im.putalpha(mask)
    shadow = Image.new('RGBA', (im.size[0] + 80, im.size[1] + 80), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle((40, 52, im.size[0] + 40, im.size[1] + 52), 36, fill=(0, 0, 0, 150))
    shadow = shadow.filter(ImageFilter.GaussianBlur(18))
    shadow.alpha_composite(im, (40, 40))
    return shadow


TEXTOS = {
    'en': {
        'out': 'doc/assets/banner.png',
        'lineas': ['iOS Live Activities and Android', 'Live Updates, 100 % in Dart.'],
        'insignias': ['No Swift', 'No Kotlin', '100 % editable'],
        'pie': 'Dynamic Island · Lock Screen · Android Live Updates',
    },
    'es': {
        'out': 'doc/assets/banner.es.png',
        'lineas': ['Live Activities de iOS y Live Updates', 'de Android, 100 % en Dart.'],
        'insignias': ['Sin Swift', 'Sin Kotlin', '100 % editable'],
        'pie': 'Isla dinámica · Pantalla de bloqueo · Live Updates de Android',
    },
}


def main(lang):
    t = TEXTOS[lang]
    canvas = gradient().convert('RGBA')
    # Capturas a la derecha, solapadas.
    for name, x, y, w in [('marcador', 900, 28, 400), ('recogida_clara', 1150, 235, 400)]:
        c = card(name, w)
        canvas.alpha_composite(c, (x - 40, y - 40))
    d = ImageDraw.Draw(canvas)
    d.text((90, 110), NAME, font=font(86, True), fill=(255, 255, 255))
    d.text((92, 225), t['lineas'][0], font=font(36), fill=(210, 222, 240))
    d.text((92, 272), t['lineas'][1], font=font(36), fill=(210, 222, 240))
    # Insignias (sobre una capa aparte para que la transparencia se mezcle)
    layer = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    x = 92
    for text in t['insignias']:
        f = font(26, True)
        w = ld.textlength(text, font=f) + 44
        ld.rounded_rectangle((x, 360, x + w, 412), 26, fill=(48, 209, 88, 40), outline=(48, 209, 88, 255), width=2)
        ld.text((x + 22, 372), text, font=f, fill=(130, 240, 160, 255))
        x += w + 18
    canvas.alpha_composite(layer)
    d = ImageDraw.Draw(canvas)
    d.text((92, 470), t['pie'], font=font(24), fill=(150, 170, 200))
    canvas.convert('RGB').save(t['out'], optimize=True)


for idioma in TEXTOS:
    main(idioma)
