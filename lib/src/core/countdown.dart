/// Segundos que faltan para la fecha ISO 8601 [date] (0 si ya pasó o es inválida).
int remainingSeconds(Object? date, DateTime now) {
  final dl = date is String ? DateTime.tryParse(date) : null;
  if (dl == null) return 0;
  final ms = dl.difference(now).inMilliseconds;
  // Igual que Math.round de JavaScript: la mitad sube.
  final s = (ms / 1000 + 0.5).floor();
  return s < 0 ? 0 : s;
}

/// Minutos que faltan, redondeados hacia arriba y nunca menos de 1.
int remainingMinutes(Object? date, DateTime now) {
  final m = (remainingSeconds(date, now) / 60).ceil();
  return m < 1 ? 1 : m;
}

/// Segundos transcurridos desde la fecha ISO 8601 [date] (0 si es futura).
int elapsedSeconds(Object? date, DateTime now) {
  final start = date is String ? DateTime.tryParse(date) : null;
  if (start == null) return 0;
  final s = now.difference(start).inSeconds;
  return s < 0 ? 0 : s;
}

/// `m:ss` o `h:mm:ss`.
String formatCountdown(int seconds) {
  final h = seconds ~/ 3600, m = seconds % 3600 ~/ 60, s = seconds % 60;
  final ss = s.toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$ss' : '$m:$ss';
}
