import 'dart:math' as math;

/// A geographic position in degrees.
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

/// A route (origin, optional stops and destination) that turns the current
/// position into progress from 0 to 1 for the progress bar.
///
/// ```dart
/// final route = LiveRoute.straight(origin, destination);
/// activity.update({'progress': route.progressAt(driverPosition)});
/// ```
///
/// The position is projected onto the nearest segment, so a driver who
/// strays a little does not make the bar jump back. Progress is the distance
/// traveled over the total distance of the path. It does not depend on any
/// map plugin: you pass the coordinates you already receive.
class LiveRoute {
  /// [path] has at least two points: origin, intermediate points and destination.
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

  /// Straight line between [start] and [end].
  LiveRoute.straight(LiveLatLng start, LiveLatLng end) : this([start, end]);

  final List<LiveLatLng> path;
  late final List<double> _cum;

  /// Total length of the path, in meters.
  double get totalMeters => _cum.last;

  /// Progress from 0 to 1 of [position] along the path.
  double progressAt(LiveLatLng position) {
    if (totalMeters == 0) return 1;
    return (_alongMeters(position) / totalMeters).clamp(0.0, 1.0);
  }

  /// Meters left to the destination, following the path.
  double remainingMeters(LiveLatLng position) =>
      math.max(0, totalMeters - _alongMeters(position));

  /// Straight-line distance to the destination, in meters.
  double metersToEnd(LiveLatLng position) => _meters(position, path.last);

  /// Stage (0 to [stages] - 1) [position] is in if the path is split into
  /// [stages] equal stages. It matches the stage the bar draws with that many
  /// labels.
  int stageAt(LiveLatLng position, int stages) {
    final f = progressAt(position);
    return math.min(stages - 1, (f * (stages - 1) + 1e-6).floor());
  }

  /// Is [position] within [meters] of the destination?
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
