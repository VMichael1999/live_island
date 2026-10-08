import '../components/progress.dart';
import '../components/visuals.dart';
import 'enums.dart';
import 'layout.dart';
import 'node.dart';

/// Una ranura de imagen del diseño y el tamaño al que se reduce antes de
/// copiarse al dispositivo (tamaño mostrado × 3).
class LiveImageSlot {
  const LiveImageSlot(
    this.label,
    this.px,
    this.image,
    this.maxWidth,
    this.maxHeight,
  );

  /// Nombre de la ranura, como en el editor del HTML.
  final String label;

  /// Tamaño final, para los avisos de `check()`.
  final String px;
  final LiveImage image;

  /// Límite en píxeles; la imagen se reduce sin deformarse ni agrandarse.
  final int maxWidth, maxHeight;
}

/// Tamaño de reducción de una imagen que no está en ninguna ranura conocida.
const liveDefaultImageMax = 138;

/// Las cuatro ranuras de imagen del editor del HTML, en su mismo orden.
List<LiveImageSlot> imageSlots(LiveLayout layout) {
  final slots = <LiveImageSlot>[];
  final logo = layout.appLogo;
  if (logo is LiveImage) {
    slots.add(LiveImageSlot('Logo de la app', '120 × 120 px', logo, 120, 120));
  }
  LiveImage? main, avatar;
  final leads = [
    layout.compactLeading,
    layout.minimal,
    layout.expanded?.leading,
  ];
  for (final root in leads) {
    if (root == null) continue;
    for (final n in root.descendants) {
      if (n is LiveAvatar && n.photo != null) {
        avatar ??= n.photo;
      } else if (n is LiveImage) {
        if (n.shape == LiveShape.circle) {
          avatar ??= n;
        } else {
          main ??= n;
        }
      }
    }
  }
  if (main != null) {
    slots.add(
      LiveImageSlot(
        'Imagen del ícono principal',
        '138 × 138 px',
        main,
        138,
        138,
      ),
    );
  }
  if (avatar != null) {
    slots.add(
      LiveImageSlot('Foto del avatar', '138 × 138 px', avatar, 138, 138),
    );
  }
  LiveNode? progress;
  for (final n in layout.allNodes) {
    if (n is LiveProgress || n is LiveSegments) {
      progress = n;
      break;
    }
  }
  final tracker = switch (progress) {
    LiveProgress p => p.tracker,
    LiveSegments s => s.tracker,
    _ => null,
  };
  if (tracker?.visual is LiveImage) {
    // 56 pt de ancho máximo y 24 pt de alto, por 3.
    slots.add(
      LiveImageSlot(
        'Imagen que avanza en la barra',
        '72 px de alto',
        tracker!.visual as LiveImage,
        168,
        72,
      ),
    );
  }
  return slots;
}

/// Límite de reducción de cada imagen del diseño, por id. Si una imagen se usa
/// en varias ranuras gana el límite más grande.
Map<String, ({int maxWidth, int maxHeight})> imageLimits(LiveLayout layout) {
  final out = <String, ({int maxWidth, int maxHeight})>{};
  for (final s in imageSlots(layout)) {
    final cur = out[s.image.id];
    out[s.image.id] = (
      maxWidth:
          cur == null || s.maxWidth > cur.maxWidth ? s.maxWidth : cur.maxWidth,
      maxHeight:
          cur == null || s.maxHeight > cur.maxHeight
              ? s.maxHeight
              : cur.maxHeight,
    );
  }
  for (final img in layout.images) {
    out.putIfAbsent(
      img.id,
      () => (maxWidth: liveDefaultImageMax, maxHeight: liveDefaultImageMax),
    );
  }
  return out;
}
