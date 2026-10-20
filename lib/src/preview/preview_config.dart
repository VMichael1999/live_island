import 'dart:async';
// En Flutter 3.29 `Brightness` solo sale de dart:ui; las versiones nuevas ya
// la reexportan desde widgets.dart y marcarían el import como innecesario.
// ignore: unnecessary_import
import 'dart:ui' show Brightness;

import 'package:flutter/widgets.dart';

import '../core/layout.dart';
import '../core/state.dart';

/// Builds the glyph of an SF Symbol the preview does not ship drawn.
typedef LiveSymbolBuilder =
    Widget Function(String symbol, double size, Color color);

/// Everything the preview needs to draw an activity.
class LivePreviewConfig {
  LivePreviewConfig({
    required this.layout,
    required Map<String, Object?> state,
    this.now,
    this.images = const {},
    this.brightness = Brightness.dark,
    this.appName = 'Mi app',
    this.androidPromotable = true,
    this.symbolBuilder,
    this.blur = true,
    this.stale = false,
  }) : state = {...LiveState.normalize(state), if (stale) r'$stale': true};

  final LiveLayout layout;

  /// Already-normalized state (dates in ISO 8601 UTC).
  final Map<String, Object?> state;

  /// Fixed instant for counters. With `null` the preview runs live.
  final DateTime? now;

  /// Images by `LiveImage` id. Any that are missing are read from their origin
  /// (asset, network, file or memory).
  final Map<String, ImageProvider> images;

  /// With [Brightness.light] the `system` lock screen card and the Android
  /// notification use their light versions. The island is always black.
  final Brightness brightness;

  /// Name of the app in the Android notification's header.
  final String appName;

  /// `false` for cases Android does not promote to a Live Update.
  final bool androidPromotable;

  /// Draws the SF Symbols the preview does not include.
  final LiveSymbolBuilder? symbolBuilder;

  /// Draws the activity as the user would see it after its `staleAfter`:
  /// `LiveBind.stale` is `true`.
  final bool stale;

  /// Blurs the lock screen card's background (`BackdropFilter`). Turn it off if
  /// your GPU rejects it (for example, Impeller with OpenGL ES on some emulators).
  final bool blur;
}

/// Delivers the current time to [builder]; if [fixed] is `null` it updates every
/// second so the countdowns run.
class LivePreviewClock extends StatefulWidget {
  const LivePreviewClock({super.key, this.fixed, required this.builder});

  final DateTime? fixed;
  final Widget Function(BuildContext context, DateTime now) builder;

  @override
  State<LivePreviewClock> createState() => _LivePreviewClockState();
}

class _LivePreviewClockState extends State<LivePreviewClock> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(LivePreviewClock old) {
    super.didUpdateWidget(old);
    if ((old.fixed == null) != (widget.fixed == null)) _sync();
  }

  void _sync() {
    _timer?.cancel();
    _timer =
        widget.fixed != null
            ? null
            : Timer.periodic(const Duration(seconds: 1), (_) {
              if (mounted) setState(() {});
            });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, (widget.fixed ?? DateTime.now()).toUtc());
}
