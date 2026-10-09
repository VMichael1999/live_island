import 'dart:math' as math;

/// Una posición geográfica en grados.
class LiveLatLng {
  const LiveLatLng(this.lat, this.lng);

  final double lat;
  final double lng;

  @override
  bool operator ==(Object other) =>
      other is LiveLatLng && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);

  @override
  String toString() => 'LiveLatLng($lat, $lng)';
}

/// Un recorrido (origen, paradas opcionales y destino) que convierte la
/// posición actual en avance de 0 a 1 para la barra de progreso.
///
/// ```dart
/// final ruta = LiveRoute.straight(origen, destino);
/// actividad.update({'progreso': ruta.progressAt(posicionDelConductor)});
/// ```
///
/// La posición se proyecta sobre el tramo más cercano, así que un conductor
/// que se desvía un poco no hace retroceder la barra de golpe. El avance es la
/// distancia recorrida sobre la distancia total del trazado. No depende de
/// ningún plugin de mapas: tú pasas las coordenadas que ya recibes.
class LiveRoute {
  /// [path] tiene al menos dos puntos: origen, puntos intermedios y destino.
  LiveRoute(List<LiveLatLng> path) : path = List.unmodifiable(path) {
    if (path.length < 2) {
      throw ArgumentError.value(path, 'path', 'Se necesitan al menos 2 puntos');
    }
    var acc = 0.0;
    final cum = <double>[0];
    for (var i = 1; i < path.length; i++) {
      acc += _meters(path[i - 1], path[i]);
      cum.add(acc);
    }
    _cum = cum;
  }

  /// Línea recta entre [start] y [end].
  LiveRoute.straight(LiveLatLng start, LiveLatLng end) : this([start, end]);

  final List<LiveLatLng> path;
  late final List<double> _cum;

  /// Largo total del trazado, en metros.
  double get totalMeters => _cum.last;

  /// Avance de 0 a 1 de [position] sobre el trazado.
  double progressAt(LiveLatLng position) {
    if (totalMeters == 0) return 1;
    return (_alongMeters(position) / totalMeters).clamp(0.0, 1.0);
  }

  /// Metros que faltan hasta el destino, siguiendo el trazado.
  double remainingMeters(LiveLatLng position) =>
      math.max(0, totalMeters - _alongMeters(position));

  /// Distancia en línea recta hasta el destino, en metros.
  double metersToEnd(LiveLatLng position) => _meters(position, path.last);

  /// Etapa (0 a [stages] - 1) en la que está [position] si el trazado se
  /// reparte en [stages] etapas iguales. Coincide con la etapa que dibuja la
  /// barra con ese número de etiquetas.
  int stageAt(LiveLatLng position, int stages) {
    final f = progressAt(position);
    return math.min(stages - 1, (f * (stages - 1) + 1e-6).floor());
  }

  /// ¿Está [position] a menos de [meters] del destino?
  bool hasArrived(LiveLatLng position, {double meters = 50}) =>
      metersToEnd(position) <= meters;

  double _alongMeters(LiveLatLng p) {
    var best = double.infinity;
    var along = 0.0;
    for (var i = 1; i < path.length; i++) {
      final a = path[i - 1], b = path[i];
      // Proyección en un plano local (válida para distancias de ciudad).
      final cos = math.cos(a.lat * math.pi / 180);
      final bx = (b.lng - a.lng) * cos, by = b.lat - a.lat;
      final px = (p.lng - a.lng) * cos, py = p.lat - a.lat;
      final len2 = bx * bx + by * by;
      final t = len2 == 0 ? 0.0 : ((px * bx + py * by) / len2).clamp(0.0, 1.0);
      final proj = LiveLatLng(
        a.lat + by * t,
        a.lng + bx * t / (cos == 0 ? 1 : cos),
      );
      final d = _meters(p, proj);
      if (d < best) {
        best = d;
        along = _cum[i - 1] + (_cum[i] - _cum[i - 1]) * t;
      }
    }
    return along;
  }

  static double _meters(LiveLatLng a, LiveLatLng b) {
    const r = 6371000.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(b.lat - a.lat), dLng = rad(b.lng - a.lng);
    final h =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(a.lat)) *
            math.cos(rad(b.lat)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * r * math.asin(math.min(1, math.sqrt(h)));
  }
}
