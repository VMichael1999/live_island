/// Ajuste de una imagen dentro de su espacio. Nunca se deforma.
enum LiveFit { contain, cover }

/// Forma del recorte de una imagen.
enum LiveShape { rounded, circle, square }

/// Fondo de la tarjeta de la pantalla de bloqueo.
enum LiveBackground { system, light, accent }

/// Alineación de hijos en filas, columnas y textos.
enum LiveAlign { start, center, end }

/// Forma de los puntos de etapa de una barra.
enum LivePointShape { circle, square, rounded }

/// Fondo del ícono que avanza sobre la barra.
enum LiveTrackerBackground { accentCircle, none }

/// Busca un valor de [values] por su nombre; si no existe devuelve [fallback].
T enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}
