import 'dart:ui' show Color;

import 'package:live_island/live_island.dart';

/// Un preset del catálogo, con la forma de construirlo cambiando su acento y
/// el fondo de la tarjeta de bloqueo.
class CatalogEntry {
  const CatalogEntry(this.id, this.label, this._make);

  /// Nombre con el que se registra el diseño (`registerLayout`) y que usan los push.
  final String id;
  final String label;
  final LivePreset Function(Color? accent, LiveBackground? background) _make;

  LivePreset make({Color? accent, LiveBackground? background}) =>
      _make(accent, background);

  /// El preset con sus valores por defecto.
  LivePreset get preset => _make(null, null);
}

Color _a(Color? c, Color d) => c ?? d;

/// Los 15 presets de la galería.
final catalog = <CatalogEntry>[
  CatalogEntry(
    'trip',
    'Taxi',
    (a, b) => TripPreset(
      accent: _a(a, const TripPreset().accent),
      lockBackground: b ?? LiveBackground.system,
    ),
  ),
  CatalogEntry(
    'delivery',
    'Delivery de comida',
    (a, b) => DeliveryPreset(
      accent: _a(a, const DeliveryPreset().accent),
      lockBackground: b ?? LiveBackground.system,
    ),
  ),
  CatalogEntry(
    'courier',
    'Courier',
    (a, b) => CourierPreset(
      accent: _a(a, const CourierPreset().accent),
      lockBackground: b ?? LiveBackground.system,
    ),
  ),
  CatalogEntry(
    'pickup',
    'Pedido para recoger',
    (a, b) => PickupPreset(
      accent: _a(a, const PickupPreset().accent),
      lockBackground: b ?? LiveBackground.system,
    ),
  ),
  CatalogEntry(
    'queue',
    'Turno en banco',
    (a, b) => QueuePreset(
      accent: _a(a, const QueuePreset().accent),
      lockBackground: b ?? LiveBackground.system,
    ),
  ),
  CatalogEntry(
    'flight',
    'Vuelo',
    (a, b) => FlightPreset(
      accent: _a(a, const FlightPreset().accent),
      lockBackground: b ?? LiveBackground.system,
    ),
  ),
  CatalogEntry(
    'parking',
    'Estacionamiento',
    (a, b) => ParkingPreset(
      accent: _a(a, const ParkingPreset().accent),
      lockBackground: b ?? LiveBackground.system,
    ),
  ),
  CatalogEntry(
    'ev',
    'Carga de auto eléctrico',
    (a, b) => EvChargingPreset(
      accent: _a(a, const EvChargingPreset().accent),
      lockBackground: b ?? LiveBackground.system,
    ),
  ),
  CatalogEntry(
    'workout',
    'Entrenamiento',
    (a, b) => WorkoutPreset(
      accent: _a(a, const WorkoutPreset().accent),
      lockBackground: b ?? LiveBackground.system,
    ),
  ),
  CatalogEntry(
    'cooking',
    'Temporizador de cocina',
    (a, b) => CookingTimerPreset(
      accent: _a(a, const CookingTimerPreset().accent),
      lockBackground: b ?? LiveBackground.system,
    ),
  ),
  CatalogEntry(
    'upload',
    'Subida de archivo',
    (a, b) => UploadPreset(
      accent: _a(a, const UploadPreset().accent),
      lockBackground: b ?? LiveBackground.system,
    ),
  ),
  CatalogEntry(
    'technician',
    'Técnico a domicilio',
    (a, b) => TechnicianPreset(
      accent: _a(a, const TechnicianPreset().accent),
      lockBackground: b ?? LiveBackground.system,
    ),
  ),
  CatalogEntry(
    'transit',
    'Transporte público',
    (a, b) => TransitPreset(
      accent: _a(a, const TransitPreset().accent),
      lockBackground: b ?? LiveBackground.system,
    ),
  ),
  CatalogEntry(
    'waiting',
    'Sala de espera médica',
    (a, b) => WaitingRoomPreset(
      accent: _a(a, const WaitingRoomPreset().accent),
      lockBackground: b ?? LiveBackground.system,
    ),
  ),
  CatalogEntry(
    'score',
    'Marcador deportivo',
    (a, b) => ScorePreset(
      accent: _a(a, const ScorePreset().accent),
      lockBackground: b ?? LiveBackground.system,
    ),
  ),
];
