import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import 'preview_config.dart';
import 'preview_surfaces.dart';

double _clamp(double v, double a, double b) => math.min(b, math.max(a, v));
double _mix(double t, double a, double b) => a + (b - a) * t;

/// Shape of the drop and the neck at an instant of the animation.
///
/// It is the geometry of the "drop" effect: the island lets go of a drop that
/// falls, stretches, leaves a neck that thins until it breaks, and the drop
/// opens into a card. It is a pure function: the painter and the tests use it.
class LiveMorphGeometry {
  const LiveMorphGeometry({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.radius,
    required this.neckX,
    required this.neckY,
    required this.neckWidth,
    required this.neckHeight,
    required this.neck,
    required this.offsetY,
    required this.widthRatio,
  });

  final double x, y, width, height, radius;
  final double neckX, neckY, neckWidth, neckHeight;

  /// 0 to 1: how much neck there is (peak halfway through the fall).
  final double neck;

  /// How far the drop's center is from the final card's.
  final double offsetY;
  final double widthRatio;

  /// [drop] and [expand] go from 0 to 1 (they may overshoot a little because of the spring).
  factory LiveMorphGeometry.compute({
    required double drop,
    required double expand,
    required double centerX,
    required double islandBottom,
    required double islandHeight,
    required double dropSize,
    required double neckMaxWidth,
    required double cardWidth,
    required double cardHeight,
    required double cardRadius,
    required double cardCenterY,
    required double canvasWidth,
    double edgeMargin = 10,
  }) {
    final grow = 1 - math.pow(1 - _clamp(drop / 0.7, 0, 1), 1.25).toDouble();
    final neck = neckProfile(drop / 0.82, 1.6, 1.4);
    final stretch = 1 + 0.38 * neck;
    final droplet = dropSize * grow;
    // El resorte puede pasarse de 0 un poco: nada de medidas negativas.
    final width = math.max(
      0.0,
      math.min(
        _mix(expand, droplet / stretch, cardWidth),
        canvasWidth - edgeMargin * 2,
      ),
    );
    final height = math.max(0.0, _mix(expand, droplet * stretch, cardHeight));
    final radius = math.max(
      0.0,
      math.min(
        _mix(expand, droplet * 0.5, cardRadius),
        math.min(width, height) / 2,
      ),
    );
    final originY = islandBottom - islandHeight * 0.34;
    final centerY = _mix(drop, originY, cardCenterY);
    final neckWidth = math.min(neckMaxWidth, width) * neck;
    final neckY = islandBottom - islandHeight * 0.5;
    return LiveMorphGeometry(
      x: centerX - width / 2,
      y: centerY - height / 2,
      width: width,
      height: height,
      radius: radius,
      neckX: centerX - neckWidth / 2,
      neckY: neckY,
      neckWidth: neckWidth,
      neckHeight: math.max(centerY - neckY, 0),
      neck: neck,
      offsetY: centerY - cardCenterY,
      widthRatio: cardWidth > 0 ? width / cardWidth : 0,
    );
  }

  /// Width of the neck: it rises, thins and disappears (`t^rise · (1-t)^fall`,
  /// normalized so the peak is 1).
  static double neckProfile(double progress, double rise, double fall) {
    final t = _clamp(progress, 0, 1);
    if (t <= 0 || t >= 1) return 0;
    final peak = rise / (rise + fall);
    final normal = math.pow(peak, rise) * math.pow(1 - peak, fall);
    return (math.pow(t, rise) * math.pow(1 - t, fall) / normal).toDouble();
  }
}

/// Dynamic Island that lets go of a drop and opens into a card with [child].
///
/// With [visible] set to `true` the island lowers the drop, the drop opens and
/// the content appears; with `false` it folds back into the island. Tapping the
/// card calls [onTap] and closes it; swiping it up dismisses it.
///
/// It is only the preview's animation (or a notice inside your app): the real
/// island is drawn by the system and cannot be animated this way.
class LiveIslandMorph extends StatefulWidget {
  const LiveIslandMorph({
    super.key,
    required this.child,
    this.visible = true,
    this.cardHeight,
    this.cardWidth = 340,
    this.islandSize = const Size(126, 37),
    this.islandTop = 12,
    this.gap = 28,
    this.dropSize = 52,
    this.neckWidth = 60,
    this.blur = 10,
    this.gain = 22,
    this.threshold = 0.43,
    this.islandColor = const Color(0xFF000000),
    this.cardColor = const Color(0xFF1C1C1E),
    this.timeScale = 1,
    this.onTap,
    this.onDismissed,
  });

  /// Content of the card (drawn over the shape).
  final Widget child;
  final bool visible;

  /// Height of the card. `null` measures it from [child].
  final double? cardHeight;
  final double cardWidth;
  final Size islandSize;
  final double islandTop;

  /// Space between the island and the card.
  final double gap;
  final double dropSize;
  final double neckWidth;

  /// Radius of the blur that fuses the shapes.
  final double blur;

  /// Gain and threshold of the filter that hardens the edge again.
  final double gain;
  final double threshold;
  final Color islandColor;
  final Color cardColor;

  /// 1 = normal speed; 3 = three times slower.
  final double timeScale;
  final VoidCallback? onTap;
  final VoidCallback? onDismissed;

  /// Variant that draws a design's expanded island.
  static Widget preview(
    LivePreviewConfig config, {
    Key? key,
    bool visible = true,
    double? cardHeight,
    VoidCallback? onTap,
    VoidCallback? onDismissed,
  }) => LiveIslandMorph(
    key: key,
    visible: visible,
    cardHeight: cardHeight,
    onTap: onTap,
    onDismissed: onDismissed,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: LiveExpandedBody(config),
    ),
  );

  @override
  State<LiveIslandMorph> createState() => _LiveIslandMorphState();
}

class _Spring {
  _Spring(TickerProvider vsync, this.duration, this.ratio)
    : controller = AnimationController.unbounded(vsync: vsync, value: 0);

  final AnimationController controller;
  final double duration;
  final double ratio;
  double get value => controller.value;

  void to(double target, double scale) {
    final w = 2 * math.pi / (duration / 1000 * scale) * 0.55;
    final spec = SpringDescription.withDampingRatio(
      mass: 1,
      stiffness: w * w,
      ratio: ratio,
    );
    controller.animateWith(
      SpringSimulation(spec, controller.value, target, controller.velocity),
    );
  }

  void jump(double v) => controller.value = v;
  void dispose() => controller.dispose();
}

class _LiveIslandMorphState extends State<LiveIslandMorph>
    with TickerProviderStateMixin {
  late final _drop = _Spring(this, 1150, 0.82);
  late final _expand = _Spring(this, 1000, 0.8);
  late final _reveal = _Spring(this, 700, 1);
  late final _tint = _Spring(this, 700, 1);
  final _timers = <Timer>[];
  final _measure = GlobalKey();
  double? _measured;
  double _dragY = 0;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    if (widget.visible) _enter();
  }

  @override
  void didUpdateWidget(LiveIslandMorph old) {
    super.didUpdateWidget(old);
    if (widget.visible != old.visible) {
      widget.visible ? _enter() : _exit();
    }
  }

  void _later(int ms, VoidCallback f) {
    final d = Duration(milliseconds: (ms * widget.timeScale).round());
    if (d == Duration.zero) return f();
    _timers.add(Timer(d, f));
  }

  void _cancel() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }

  void _enter() {
    _cancel();
    _closing = false;
    _dragY = 0;
    for (final s in [_drop, _expand, _reveal, _tint]) {
      s.jump(0);
    }
    final k = widget.timeScale;
    _drop.to(1, k);
    _later(110, () => _tint.to(1, k));
    _later(340, () => _expand.to(1, k));
    _later(560, () => _reveal.to(1, k));
  }

  void _exit() {
    _cancel();
    _closing = true;
    final k = widget.timeScale;
    _reveal.to(0, k);
    _later(100, () => _expand.to(0, k));
    _later(280, () {
      _tint.to(0, k);
      _drop.to(0, k);
    });
    _later((280 + 1150 * 0.8).round(), () {
      if (_closing && mounted) widget.onDismissed?.call();
    });
  }

  @override
  void dispose() {
    _cancel();
    for (final s in [_drop, _expand, _reveal, _tint]) {
      s.dispose();
    }
    super.dispose();
  }

  void _afterLayout() {
    final box = _measure.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize && box.size.height != _measured) {
      setState(() => _measured = box.size.height);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardH = widget.cardHeight ?? _measured ?? 96;
    if (widget.cardHeight == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _afterLayout();
      });
    }
    final top = widget.islandTop;
    final ih = widget.islandSize.height;
    final cardTop = top + ih + widget.gap;
    final height = cardTop + cardH + 40;

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.hasBoundedWidth ? c.maxWidth : widget.cardWidth + 32;
        final cardW = math.min(widget.cardWidth, w - 16);
        return SizedBox(
          width: w,
          height: height,
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _drop.controller,
              _expand.controller,
              _reveal.controller,
              _tint.controller,
            ]),
            builder: (context, _) {
              final g = LiveMorphGeometry.compute(
                drop: _drop.value,
                expand: _expand.value,
                centerX: w / 2,
                islandBottom: top + ih,
                islandHeight: ih,
                dropSize: widget.dropSize,
                neckMaxWidth: widget.neckWidth,
                cardWidth: cardW,
                cardHeight: cardH,
                cardRadius: math.min(40.0, cardH / 2),
                cardCenterY: cardTop + cardH / 2,
                canvasWidth: w,
              );
              final reveal = _clamp(_reveal.value, 0, 1);
              final scale =
                  _mix(reveal, 0.88, 1) +
                  _clamp(g.widthRatio - 1, 0, 0.2) * reveal;
              final blur = 12 * (1 - reveal);
              Widget card = SizedBox(
                key: _measure,
                width: cardW,
                child: widget.child,
              );
              if (blur > 0.3) {
                card = ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                  child: card,
                );
              }
              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragUpdate:
                    (d) => setState(
                      () => _dragY = _clamp(_dragY + d.delta.dy, -120, 24),
                    ),
                onVerticalDragEnd: (d) {
                  final thrown =
                      _dragY < -18 || d.velocity.pixelsPerSecond.dy < -420;
                  if (thrown) {
                    _dragY = 0;
                    widget.onDismissed?.call();
                  } else {
                    setState(() => _dragY = 0);
                  }
                },
                onTap: widget.onTap,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _GooPainter(
                          g: g,
                          expand: _expand.value,
                          tint: _clamp((_tint.value - 0.06) / 0.82, 0, 1),
                          island: Rect.fromLTWH(
                            (w - widget.islandSize.width) / 2,
                            top,
                            widget.islandSize.width,
                            ih,
                          ),
                          blur: widget.blur,
                          gain: widget.gain,
                          threshold: widget.threshold,
                          islandColor: widget.islandColor,
                          cardColor: widget.cardColor,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: ClipPath(
                        clipper: _ShapeClipper(
                          RRect.fromRectAndRadius(
                            Rect.fromLTWH(
                              g.x,
                              g.y + _dragY,
                              math.max(g.width, 0),
                              math.max(g.height, 0),
                            ),
                            Radius.circular(g.radius),
                          ),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: (w - cardW) / 2,
                              top: cardTop,
                              width: cardW,
                              height: cardH,
                              child: Transform.translate(
                                offset: Offset(0, g.offsetY + _dragY),
                                child: Transform.scale(
                                  scale: scale,
                                  child: Opacity(
                                    opacity: reveal,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        math.min(40, cardH / 2),
                                      ),
                                      child: OverflowBox(
                                        alignment: Alignment.topCenter,
                                        minHeight: 0,
                                        maxHeight: double.infinity,
                                        child: card,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _GooPainter extends CustomPainter {
  _GooPainter({
    required this.g,
    required this.expand,
    required this.tint,
    required this.island,
    required this.blur,
    required this.gain,
    required this.threshold,
    required this.islandColor,
    required this.cardColor,
  });

  final LiveMorphGeometry g;
  final double expand, tint, blur, gain, threshold;
  final Rect island;
  final Color islandColor, cardColor;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final drop = Color.lerp(islandColor, cardColor, tint)!;

    final shade = _clamp(expand, 0, 1);
    if (shade > 0 && g.width > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(g.x, g.y + 10, g.width, g.height),
          Radius.circular(g.radius),
        ),
        Paint()
          ..color = Color.fromRGBO(0, 0, 0, 0.35 * shade)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    // Capa externa: endurece el borde (umbral sobre el alfa).
    canvas.saveLayer(
      bounds,
      Paint()
        ..colorFilter = ColorFilter.matrix([
          1, 0, 0, 0, 0, //
          0, 1, 0, 0, 0,
          0, 0, 1, 0, 0,
          0, 0, 0, gain, -gain * threshold * 255,
        ]),
    );
    // Capa interna: difumina las formas para que se fundan.
    canvas.saveLayer(
      bounds,
      Paint()..imageFilter = ImageFilter.blur(sigmaX: blur, sigmaY: blur),
    );
    final inset = blur * 0.26;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        island.deflate(inset),
        Radius.circular(math.max(island.height / 2 - inset, 0)),
      ),
      Paint()..color = islandColor,
    );
    if (g.neckWidth > 0.5 && g.neckHeight > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(g.neckX, g.neckY, g.neckWidth, g.neckHeight),
          Radius.circular(g.neckWidth / 2),
        ),
        Paint()..color = islandColor,
      );
    }
    if (g.width > 0.5 && g.height > 0.5) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(g.x, g.y, g.width, g.height),
          Radius.circular(g.radius),
        ),
        Paint()..color = drop,
      );
    }
    canvas.restore();
    canvas.restore();

    // La isla nítida va encima.
    canvas.drawRRect(
      RRect.fromRectAndRadius(island, Radius.circular(island.height / 2)),
      Paint()..color = islandColor,
    );
  }

  @override
  bool shouldRepaint(_GooPainter o) =>
      o.g != g ||
      o.tint != tint ||
      o.blur != blur ||
      o.gain != gain ||
      o.threshold != threshold ||
      o.island != island;
}

class _ShapeClipper extends CustomClipper<Path> {
  _ShapeClipper(this.rrect);

  final RRect rrect;

  @override
  Path getClip(Size size) => Path()..addRRect(rrect);

  @override
  bool shouldReclip(_ShapeClipper old) => old.rrect != rrect;
}
