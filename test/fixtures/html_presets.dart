import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Color;

import 'package:live_island/live_island.dart';

/// Un preset del HTML de prototipos, tal como lo dejó `tool/extract_html_checks.js`.
class HtmlPreset {
  HtmlPreset(this.raw);

  final Map<String, dynamic> raw;

  String get id => raw['id'] as String;
  String get title => raw['title'] as String;
  bool get isCountdown => raw['hlMode'] == 'countdown';
  bool get pShow => raw['pShow'] as bool;
  String get pType => raw['pType'] as String;
  double get v01 => ((raw['pValue'] as num) / 100).clamp(0, 1).toDouble();
  List<String> get stages =>
      (raw['stages'] as String)
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
  bool get androidOk => raw['androidOk'] as bool;
}

class HtmlFixtures {
  HtmlFixtures._(this.now, this.sf, this.presets, this.checks);

  final DateTime now;
  final Map<String, String> sf;
  final List<HtmlPreset> presets;
  final Map<String, List<({String sev, String text})>> checks;

  static HtmlFixtures load() {
    final data =
        jsonDecode(File('test/fixtures/html_presets.json').readAsStringSync())
            as Map<String, dynamic>;
    final checks = (jsonDecode(
              File('test/fixtures/html_checks.json').readAsStringSync(),
            )
            as Map<String, dynamic>)
        .map(
          (k, v) => MapEntry(k, [
            for (final r in v as List)
              (sev: r['sev'] as String, text: r['text'] as String),
          ]),
        );
    return HtmlFixtures._(
      DateTime.parse(data['now'] as String),
      (data['sf'] as Map).cast<String, String>(),
      [
        for (final p in data['presets'] as List)
          HtmlPreset((p as Map).cast<String, dynamic>()),
      ],
      checks,
    );
  }

  /// Datos que viajan en cada actualización (mismo payload que mide el HTML).
  Map<String, Object?> stateOf(HtmlPreset p) {
    final st = p.stages;
    final progreso = double.parse(p.v01.toStringAsFixed(2));
    return {
      'titulo': p.raw['title'],
      'subtitulo': p.raw['subtitle'],
      'nombre': p.raw['name'],
      if (!p.isCountdown) 'destacado': p.raw['highlight'],
      if (p.isCountdown) 'llegaA': p.raw['deadline'],
      'progreso':
          progreso == progreso.roundToDouble() ? progreso.toInt() : progreso,
      if (st.isNotEmpty) 'etapa': (p.v01 * (st.length - 1)).floor(),
    };
  }

  LiveIcon? _sym(Object? name) {
    if (name == null || name == 'none') return null;
    final sfName = sf[name as String] ?? name;
    return LiveIcon.symbol(
      sfName,
      android: 'assets/live/${name.toLowerCase()}.png',
    );
  }

  LiveImage _image(Map<String, dynamic> m, String file, {LiveShape? shape}) =>
      LiveImage.asset(
        'assets/live/$file',
        fit: LiveFit.values.byName(m['fit'] as String),
        shape:
            shape ??
            (m['shape'] == null
                ? LiveShape.rounded
                : LiveShape.values.byName(m['shape'] as String)),
        byteSize: (m['kb'] as int) * 1024,
      );

  /// Reproduce el "Código Dart generado" del HTML (`renderCode`).
  /// Con [withSmallIcon] en `false` omite `androidSmallIcon`, que es el caso
  /// en que el HTML (y `check()`) avisan de la silueta.
  LiveLayout layoutOf(HtmlPreset p, {bool withSmallIcon = true}) {
    final r = p.raw;
    final accent = _hex(r['accent'] as String);
    final bool showAvatar = r['showAvatar'] as bool;
    final logo = r['logoImg'] as Map<String, dynamic>?;
    final mainImg = r['mainImg'] as Map<String, dynamic>?;
    final avatarImg = r['avatarImg'] as Map<String, dynamic>?;
    final trackerImg = r['trackerImg'] as Map<String, dynamic>?;
    final icon = _sym(r['icon'])!;

    final LiveVisual lead =
        showAvatar
            ? (avatarImg != null
                ? _image(avatarImg, 'foto.jpg', shape: LiveShape.circle)
                : LiveAvatar(r['avatarText'] as String))
            : (mainImg != null ? _image(mainImg, 'icono.png') : icon);

    final highlight =
        p.isCountdown
            ? LiveText.countdown(bind('llegaA'))
            : LiveText(bind('destacado'));

    LiveNode? progress;
    if (p.pShow) {
      final LiveTrackerSource? tracker =
          trackerImg != null
              ? LiveTracker(
                _image(trackerImg, 'auto.png'),
                height: 24,
                background:
                    (r['trackerCircle'] as bool)
                        ? LiveTrackerBackground.accentCircle
                        : LiveTrackerBackground.none,
              )
              : _sym(r['tracker']);
      final start = _sym(r['startIcon']);
      final end = _sym(r['endIcon']);
      if (p.pType == 'segments' && p.stages.length > 1) {
        progress = LiveSegments(
          value: bind('progreso'),
          labels: p.stages,
          points: r['showPoints'] as bool,
          tracker: tracker,
          startIcon: start,
          endIcon: end,
        );
      } else if (p.pType == 'ring') {
        progress = LiveProgress.ring(value: bind('progreso'));
      } else {
        progress = LiveProgress.bar(
          value: bind('progreso'),
          tracker: tracker,
          startIcon: start,
          endIcon: end,
        );
      }
    }

    final buttons = <LiveButton>[
      for (final (label, ic) in [
        (r['a1Label'] as String, r['a1Icon']),
        (r['a2Label'] as String, r['a2Icon']),
      ])
        if (label.isNotEmpty)
          LiveButton(id: _buttonId(label), label: label, icon: _sym(ic)),
    ];

    final chipMode = r['chipMode'] as String;
    final LiveChip chip = switch (chipMode) {
      'countdown' => LiveChip.countdown(bind('llegaA')),
      'text' => LiveChip.text(r['chipText'] as String),
      _ => const LiveChip.icon(),
    };

    return LiveLayout(
      theme: LiveTheme(
        accent: accent,
        background: switch (r['lockBg']) {
          'dark' => LiveBackground.system,
          final String b => LiveBackground.values.byName(b),
          _ => LiveBackground.system,
        },
      ),
      appLogo: logo != null ? _image(logo, 'logo.png') : icon,
      androidSmallIcon:
          logo != null && withSmallIcon
              ? LiveImage.asset('assets/live/logo_silueta.png')
              : null,
      compactLeading: lead,
      compactTrailing: highlight,
      minimal:
          p.pShow && p.pType == 'ring'
              ? LiveProgress.ring(value: bind('progreso'), child: icon)
              : icon,
      expanded: LiveExpanded(
        leading:
            (showAvatar || mainImg != null)
                ? lead
                : LiveBox(child: icon, size: 46, radius: 14, tint: 0.22),
        center: LiveColumn([
          LiveText(bind('titulo'), weight: 600),
          LiveText(bind('subtitulo'), muted: true),
        ]),
        trailing: LiveColumn([
          LiveText.from(highlight, size: 22, weight: 700, accent: true),
          LiveText(bind('nombre'), muted: true),
        ], align: LiveAlign.end),
        bottom: LiveColumn([
          if (progress != null) progress,
          if (buttons.isNotEmpty) LiveRow(buttons),
        ]),
      ),
      lockScreen: const LiveLockScreen.sameAsExpanded(),
      android: LiveAndroid(
        title: bind('titulo'),
        text: const LiveText.format('{subtitulo} · {nombre}'),
        chip: chip,
        colorized: r['colorized'] as bool,
      ),
    );
  }

  static Color _hex(String h) =>
      Color(0xFF000000 | int.parse(h.substring(1), radix: 16));

  static String _buttonId(String label) {
    final id = label
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return id.isEmpty ? 'accion' : id;
  }
}
