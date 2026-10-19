"""Compone doc/assets/galeria/carga.png: la isla compacta y la expandida de la
vista previa (build/galeria/carga_base.png, que genera
`GENERAR_GALERIA=1 flutter test test/readme_gallery_test.dart`) y, debajo, la
tarjeta de carga de una captura del simulador de iOS, con su brillo, que la
vista previa de Flutter no dibuja. Mismo lienzo que las demás imágenes.

Uso: python3 tool/compose_carga.py captura_de_la_tarjeta.png
"""
import sys
from PIL import Image

W, H = 1260, 1140  # igual que las imágenes que genera test/readme_gallery_test.dart
TOP, BOTTOM = (0x2F, 0x48, 0x61), (0x0E, 0x15, 0x20)


def gradient():
    im = Image.new('RGB', (W, H))
    px = im.load()
    for y in range(H):
        for x in range(W):
            t = (x / W + y / H) / 2  # diagonal, como el fondo de las otras
            px[x, y] = tuple(round(a + (b - a) * t) for a, b in zip(TOP, BOTTOM))
    return im


def rounded(im, radius):
    from PIL import ImageDraw
    mask = Image.new('L', im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, im.size[0] - 1, im.size[1] - 1), radius, fill=255)
    out = im.copy()
    out.putalpha(mask)
    return out


def main(src):
    canvas = Image.open('build/galeria/carga_base.png').convert('RGBA')
    card = Image.open(src).convert('RGBA')
    # Recorta el borde de la captura para quedarse con la tarjeta y su halo.
    w, h = card.size
    card = rounded(card.crop((round(w * 0.019), round(h * 0.012), round(w * 0.981), round(h * 0.925))), 58)
    target = round(W * 0.93)
    card = card.resize((target, round(card.size[1] * target / card.size[0])), Image.LANCZOS)
    canvas.alpha_composite(card, ((W - card.size[0]) // 2, H - card.size[1] - round(H * 0.045)))
    canvas.convert('RGB').save('doc/assets/galeria/carga.png', optimize=True)


if __name__ == '__main__':
    main(sys.argv[1])
