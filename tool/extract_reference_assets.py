"""Extrae las imágenes de referencia de docs/design/referencias_islas.html a
example/assets/reference/ (logotipos y recortes con el fondo transparente).

Son marcas y fotos de terceros: solo van en la app de ejemplo y en el
repositorio, no en el paquete publicado (ver .pubignore).
Uso: python3 tool/extract_reference_assets.py
"""
import base64, io, json, os, re
from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), '..')
HTML = os.path.join(ROOT, 'docs', 'design', 'referencias_islas.html')
OUT = os.path.join(ROOT, 'example', 'assets', 'reference')


def data_uri(s):
    return Image.open(io.BytesIO(base64.b64decode(s.split(',', 1)[1]))).convert('RGBA')


def feather(im, px):
    """Difumina los bordes del recorte (alfa) para que no se vea el rectángulo
    sobre el fondo de la tarjeta."""
    w, h = im.size
    a = im.getchannel('A')
    mask = Image.new('L', (w, h), 255)
    m = mask.load()
    for y in range(h):
        for x in range(w):
            d = min(x, y, w - 1 - x, h - 1 - y)
            t = min(1.0, d / px)
            m[x, y] = int(255 * t * t * (3 - 2 * t))
    out = im.copy()
    out.putalpha(Image.composite(a, Image.new('L', (w, h), 0), mask).point(lambda v: v))
    # alfa final = alfa original * máscara
    from PIL import ImageChops
    out.putalpha(ImageChops.multiply(a, mask))
    return out


def main():
    html = open(HTML, encoding='utf8').read()
    img = json.loads(re.search(r'const IMG = (\{.*?\});\nconst esc', html, re.S).group(1))
    assets = json.loads(re.search(r'const ASSETS = (\{.*?\});\nconst bez', html, re.S).group(1))
    os.makedirs(OUT, exist_ok=True)
    for name in ['uber', 'starbucks', 'nike', 'tesla', 'psg', 'chelsea']:
        data_uri(img[name]).save(os.path.join(OUT, f'{name}.png'), optimize=True)
    # logotipo en blanco (para tarjetas oscuras)
    from PIL import ImageOps
    u = data_uri(img['uber'])
    r, g, b, a = u.split()
    white = Image.merge('RGBA', (r.point(lambda v: 255), g.point(lambda v: 255), b.point(lambda v: 255), a))
    white.save(os.path.join(OUT, 'uber_white.png'), optimize=True)
    # recortes de capturas: bordes difuminados para que no se vea el rectángulo
    feather(data_uri(assets['u1head']), 12).save(os.path.join(OUT, 'ride_head_light.png'), optimize=True)
    feather(data_uri(assets['u1car']), 8).save(os.path.join(OUT, 'ride_car_light.png'), optimize=True)
    feather(data_uri(assets['u2head']), 14).save(os.path.join(OUT, 'ride_head_dark.png'), optimize=True)
    feather(data_uri(assets['u2car']), 8).save(os.path.join(OUT, 'ride_car_dark.png'), optimize=True)
    print(sorted(os.listdir(OUT)))


if __name__ == '__main__':
    main()
