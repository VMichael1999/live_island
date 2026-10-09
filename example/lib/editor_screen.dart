import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:live_island/live_island.dart';

import 'catalog.dart';
import 'main.dart';

/// Editor parecido al del HTML de prototipos: parte de un preset, cambia
/// textos, color, fondo y avance, y muestra el resultado y el código.
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  static const swatches = [
    Color(0xFF1F6FEB),
    Color(0xFFE4572E),
    Color(0xFF2E7D32),
    Color(0xFF00897B),
    Color(0xFFC62828),
    Color(0xFFF57C00),
    Color(0xFF6D4C41),
    Color(0xFFD81B60),
    Color(0xFF5E35B1),
    Color(0xFF0277BD),
  ];

  CatalogEntry entry = catalog.first;
  Color? accent;
  LiveBackground background = LiveBackground.system;
  late Map<String, Object?> state = entry.preset.sampleState();
  late final title = TextEditingController(text: state['titulo'] as String);
  late final subtitle = TextEditingController(
    text: state['subtitulo'] as String,
  );
  late final name = TextEditingController(text: state['nombre'] as String);

  // Barra de progreso (solo en los presets de etapas con ícono que avanza).
  bool showLabels = true;
  bool showPoints = true;
  bool showTracker = true;
  bool showEndIcon = true;
  double barHeight = 6;
  double pointSize = 10;
  double gap = 4;
  Color? barColor;
  LivePointShape pointShape = LivePointShape.circle;
  int stageCount = 0; // 0 = las del preset

  bool get hasBarEditor =>
      const {'trip', 'delivery', 'courier'}.contains(entry.id);

  LiveProgressStyle? get barStyle {
    final st = LiveProgressStyle(
      height: barHeight == 6 ? null : barHeight,
      pointSize: pointSize == 10 ? null : pointSize,
      gap: gap == 4 ? null : gap,
      color: barColor,
      pointShape: pointShape == LivePointShape.circle ? null : pointShape,
    );
    return st.isEmpty ? null : st;
  }

  /// Con 0 se usan las etapas del preset; con otro número se reparten esa
  /// cantidad de puntos (con texto solo el primero y el último).
  List<String> _stages(List<String> preset) {
    if (stageCount == 0 || stageCount == preset.length) return preset;
    return [
      for (var i = 0; i < stageCount; i++)
        i == 0
            ? preset.first
            : i == stageCount - 1
            ? preset.last
            : '',
    ];
  }

  LivePreset get preset {
    if (!hasBarEditor) {
      return entry.make(accent: accent, background: background);
    }
    final base = entry.preset as dynamic;
    final a = accent ?? base.accent as Color;
    final style = barStyle;
    final stages = _stages(base.stages as List<String>);
    return switch (entry.id) {
      'trip' => TripPreset(
        accent: a,
        lockBackground: background,
        showLabels: showLabels,
        showPoints: showPoints,
        showTracker: showTracker,
        showEndIcon: showEndIcon,
        progressStyle: style,
        stages: stages,
      ),
      'delivery' => DeliveryPreset(
        accent: a,
        lockBackground: background,
        showLabels: showLabels,
        showPoints: showPoints,
        showTracker: showTracker,
        showEndIcon: showEndIcon,
        progressStyle: style,
        stages: stages,
      ),
      _ => CourierPreset(
        accent: a,
        lockBackground: background,
        showLabels: showLabels,
        showPoints: showPoints,
        showTracker: showTracker,
        showEndIcon: showEndIcon,
        progressStyle: style,
        stages: stages,
      ),
    };
  }

  void _pick(CatalogEntry e) => setState(() {
    entry = e;
    accent = null;
    showLabels = showPoints = showTracker = showEndIcon = true;
    barHeight = 6;
    pointSize = 10;
    gap = 4;
    barColor = null;
    pointShape = LivePointShape.circle;
    stageCount = 0;
    state = e.preset.sampleState();
    title.text = state['titulo'] as String;
    subtitle.text = state['subtitulo'] as String;
    name.text = state['nombre'] as String;
  });

  void _set(String key, Object? value) =>
      setState(() => state = {...state, key: value});

  String _hex(Color c) =>
      'Color(0xFF${c.toARGB32().toRadixString(16).substring(2).toUpperCase()})';

  String get code {
    final p = preset;
    final cls = p.runtimeType.toString();
    final args = [
      if (accent != null) 'accent: ${_hex(accent!)}',
      if (background != LiveBackground.system)
        'lockBackground: LiveBackground.${background.name}',
      if (hasBarEditor) ...[
        if (!showLabels) 'showLabels: false',
        if (!showPoints) 'showPoints: false',
        if (!showTracker) 'showTracker: false',
        if (!showEndIcon) 'showEndIcon: false',
        if (barStyle != null)
          'progressStyle: LiveProgressStyle(${[if (barHeight != 6) 'height: ${barHeight.round()}', if (pointSize != 10) 'pointSize: ${pointSize.round()}', if (gap != 4) 'gap: ${gap.round()}', if (barColor != null) 'color: ${_hex(barColor!)}'].join(', ')})',
      ],
    ].join(', ');
    String q(Object? v) => "'${'$v'.replaceAll("'", "\\'")}'";
    return [
      "import 'package:live_island/live_island.dart';",
      '',
      'final preset = $cls($args);',
      'final layout = preset.build(); // o preset.override(compactTrailing: ...)',
      '',
      'final estado = {',
      "  'titulo': ${q(state['titulo'])},",
      "  'subtitulo': ${q(state['subtitulo'])},",
      "  'nombre': ${q(state['nombre'])},",
      "  'progreso': ${(state['progreso'] as num).toStringAsFixed(2)},",
      '};',
      '',
      'final actividad = await LiveIsland.start(layout: layout, state: estado);',
    ].join('\n');
  }

  Widget _slider(
    String label,
    double v,
    double min,
    double max,
    ValueChanged<double> on,
  ) => Row(
    children: [
      SizedBox(width: 110, child: Text(label)),
      Expanded(
        child: Slider(
          value: v,
          min: min,
          max: max,
          divisions: (max - min).round(),
          onChanged: (x) => setState(() => on(x)),
        ),
      ),
      Text('${v.round()}'),
    ],
  );

  List<Widget> _barControls() => [
    const SizedBox(height: 8),
    Text('Barra de progreso', style: Theme.of(context).textTheme.titleSmall),
    SwitchListTile(
      dense: true,
      title: const Text('Etiquetas de etapa'),
      value: showLabels,
      onChanged: (v) => setState(() => showLabels = v),
    ),
    SwitchListTile(
      dense: true,
      title: const Text('Puntos de etapa'),
      value: showPoints,
      onChanged: (v) => setState(() => showPoints = v),
    ),
    SwitchListTile(
      dense: true,
      title: const Text('Ícono que avanza'),
      value: showTracker,
      onChanged: (v) => setState(() => showTracker = v),
    ),
    SwitchListTile(
      dense: true,
      title: const Text('Marcador final'),
      value: showEndIcon,
      onChanged: (v) => setState(() => showEndIcon = v),
    ),
    _slider('Grosor', barHeight, 2, 16, (x) => barHeight = x),
    _slider('Tamaño de puntos', pointSize, 6, 20, (x) => pointSize = x),
    _slider('Separación', gap, 0, 8, (x) => gap = x),
    Wrap(
      spacing: 8,
      children: [
        GestureDetector(
          onTap: () => setState(() => barColor = null),
          child: const CircleAvatar(
            radius: 14,
            child: Icon(Icons.format_color_reset, size: 16),
          ),
        ),
        for (final c in swatches)
          GestureDetector(
            onTap: () => setState(() => barColor = c),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: c,
              child:
                  barColor == c
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
            ),
          ),
      ],
    ),
    const SizedBox(height: 12),
  ];

  @override
  Widget build(BuildContext context) {
    final p = preset;
    final layout = p.build();
    final report = LiveIsland.check(
      layout,
      state,
      androidPromotable: p.androidPromotable,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Editor')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<CatalogEntry>(
            value: entry,
            decoration: const InputDecoration(labelText: 'Caso de uso'),
            items: [
              for (final e in catalog)
                DropdownMenuItem(value: e, child: Text(e.label)),
            ],
            onChanged: (e) => e == null ? null : _pick(e),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: title,
            decoration: const InputDecoration(labelText: 'Título'),
            onChanged: (v) => _set('titulo', v),
          ),
          TextField(
            controller: subtitle,
            decoration: const InputDecoration(labelText: 'Subtítulo'),
            onChanged: (v) => _set('subtitulo', v),
          ),
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Nombre visible'),
            onChanged: (v) => _set('nombre', v),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final c in swatches)
                GestureDetector(
                  onTap: () => setState(() => accent = c),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: c,
                    child:
                        (accent ?? p.spec.accent) == c
                            ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                            : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<LiveBackground>(
            segments: const [
              ButtonSegment(
                value: LiveBackground.system,
                label: Text('Sistema'),
              ),
              ButtonSegment(value: LiveBackground.light, label: Text('Claro')),
              ButtonSegment(
                value: LiveBackground.accent,
                label: Text('Acento'),
              ),
            ],
            selected: {background},
            onSelectionChanged: (s) => setState(() => background = s.first),
          ),
          Row(
            children: [
              const Text('Avance'),
              Expanded(
                child: Slider(
                  value: (state['progreso'] as num).toDouble(),
                  onChanged:
                      (v) =>
                          _set('progreso', double.parse(v.toStringAsFixed(2))),
                ),
              ),
              Text('${((state['progreso'] as num) * 100).round()} %'),
            ],
          ),
          if (hasBarEditor) ..._barControls(),
          FilledButton(
            onPressed: () => model.start(entry, layout, state),
            child: const Text('Iniciar con estos datos'),
          ),
          const SizedBox(height: 16),
          LiveIslandPreview(
            layout: layout,
            state: state,
            appName: p.appName,
            androidPromotable: p.androidPromotable,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Código Dart',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Clipboard.setData(ClipboardData(text: code)),
                child: const Text('Copiar'),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF14201D),
            child: SelectableText(
              code,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Color(0xFFD9EDE7),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Validación', style: Theme.of(context).textTheme.titleMedium),
          for (final c in report.items)
            ListTile(
              dense: true,
              leading: Icon(switch (c.severity) {
                LiveSeverity.ok => Icons.check_circle_outline,
                LiveSeverity.warn => Icons.warning_amber,
                LiveSeverity.bad => Icons.error_outline,
              }),
              title: Text(c.message),
            ),
        ],
      ),
    );
  }
}
