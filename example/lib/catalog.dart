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

/// Imagen de referencia de `assets/reference/` (recorte o logotipo de terceros;
/// solo para esta app de ejemplo).
LiveImage _ref(String file, double w, double h) => LiveImage.asset(
  'assets/reference/$file',
  width: w.round(),
  height: h.round(),
  size: w,
  shape: LiveShape.square,
);

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

  // --- Diseños de referencia (lib/src/presets/designs.dart) ---
  CatalogEntry(
    'ride_light',
    'Recogida · tarjeta clara',
    (a, b) => RidePickupPreset(
      accent: _a(a, const RidePickupPreset().accent),
      brandLogo: _ref('uber.png', 70, 24),
      headerImage: _ref('ride_head_light.png', 102, 42),
      trackerImage: _ref('ride_car_light.png', 46, 26),
    ),
  ),
  CatalogEntry(
    'ride_dark',
    'Recogida · tarjeta oscura',
    (a, b) => RidePickupPreset(
      dark: true,
      accent: _a(a, const RidePickupPreset().accent),
      brandLogo: _ref('uber_white.png', 64, 22),
      headerImage: _ref('ride_head_dark.png', 118, 47),
      trackerImage: _ref('ride_car_dark.png', 44, 24),
    ),
  ),
  CatalogEntry(
    'store',
    'Pedido en tienda',
    (a, b) => StorePickupPreset(
      accent: _a(a, const StorePickupPreset().accent),
      brandLogo: _ref('starbucks.png', 28, 28),
    ),
  ),
  CatalogEntry(
    'run',
    'Carrera',
    (a, b) => RunPreset(
      accent: _a(a, const RunPreset().accent),
      brandMark: _ref('nike.png', 56, 20),
    ),
  ),
  CatalogEntry(
    'match',
    'Marcador de partido',
    (a, b) => MatchPreset(
      accent: _a(a, const MatchPreset().accent),
      homeCrest: _ref('psg.png', 84, 84),
      awayCrest: _ref('chelsea.png', 84, 84),
    ),
  ),
  CatalogEntry(
    'stock',
    'Bolsa · gráfica',
    (a, b) => StockPreset(
      accent: _a(a, const StockPreset().accent),
      brandLogo: _ref('tesla.png', 28, 28),
    ),
  ),
  CatalogEntry(
    'flightpath',
    'Vuelo · ruta curva',
    (a, b) => FlightPathPreset(accent: _a(a, const FlightPathPreset().accent)),
  ),
  CatalogEntry(
    'orbit',
    'Órbita · arco',
    (a, b) => OrbitPreset(accent: _a(a, const OrbitPreset().accent)),
  ),
  // Un preset de la galería con la barra reestilizada: así queda una línea de tren.
  CatalogEntry(
    'train_line',
    'Tren · línea verde',
    (a, b) => TransitPreset(
      accent: _a(a, const Color(0xFFA7F060)),
      lockBackground: b ?? LiveBackground.system,
      stages: const ['Harajuku', 'Shibuya', 'Ebisu'],
      showTracker: false,
      showEndIcon: false,
      progressStyle: LiveProgressStyle(
        height: 16,
        color: _a(a, const Color(0xFFA7F060)),
        trackColor: const Color(0xFF2F6A12),
        pointSize: 12,
        pointColor: const Color(0xFF000000),
        gap: 0,
      ),
    ),
  ),
];
