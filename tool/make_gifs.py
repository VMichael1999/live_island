"""Une los cuadros de test/gifs_test.dart en GIF (docs/assets/).

Uso: LIVE_ISLAND_GIFS=/tmp/frames flutter test test/gifs_test.dart
     python3 tool/make_gifs.py /tmp/frames
"""
import glob, os, sys
from PIL import Image

src = sys.argv[1]
out = os.path.join(os.path.dirname(__file__), '..', 'docs', 'assets')
os.makedirs(out, exist_ok=True)
for d in sorted(glob.glob(os.path.join(src, '*'))):
    frames = [Image.open(f).convert('RGB') for f in sorted(glob.glob(os.path.join(d, '*.png')))]
    if not frames:
        continue
    w = 400
    frames = [f.resize((w, round(f.height * w / f.width)), Image.LANCZOS) for f in frames]
    pal = [f.quantize(colors=128, method=Image.MEDIANCUT, dither=Image.NONE) for f in frames]
    name = os.path.join(out, os.path.basename(d) + '.gif')
    pal[0].save(name, save_all=True, append_images=pal[1:] + pal[-1:] * 6, duration=110, loop=0, optimize=True)
    print(name, os.path.getsize(name) // 1024, 'KB', len(frames), 'cuadros')
