import '../components/progress.dart';
import '../components/visuals.dart';
import 'enums.dart';
import 'layout.dart';
import 'node.dart';

/// An image slot of the design and the size it is reduced to before being
/// copied to the device (displayed size × 3).
class LiveImageSlot {
  const LiveImageSlot(
    this.label,
    this.px,
    this.image,
    this.maxWidth,
    this.maxHeight,
  );

  /// Name of the slot, as in the HTML editor.
  final String label;

  /// Final size, for the `check()` warnings.
  final String px;
  final LiveImage image;

  /// Limit in pixels; the image is reduced without being distorted or enlarged.
  final int maxWidth, maxHeight;
}

/// Reduction size of an image that is not in any known slot.
const liveDefaultImageMax = 138;

/// The four image slots of the HTML editor, in the same order.
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
    // 130 pt de ancho máximo (un tren) y 24 pt de alto, por 3.
    slots.add(
      LiveImageSlot(
        'Imagen que avanza en la barra',
        '72 px de alto',
        tracker!.visual as LiveImage,
        390,
        72,
      ),
    );
  }
  return slots;
}

/// Reduction limit of each image in the design, by id. If an image is used
/// in several slots, the largest limit wins.
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
