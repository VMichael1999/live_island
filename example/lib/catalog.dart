import 'dart:ui' show Color;

import 'package:live_island_kit/live_island_kit.dart';

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

/// Imagen propia de `assets/run/` (sin fondo), de [size] pt (cuadrada) o,
/// con [height], de ese alto y el ancho según su proporción.
LiveImage _img(String file, int pxW, int pxH, {double? size, double? height}) =>
    LiveImage.asset(
      'assets/run/$file',
      width: pxW,
      height: pxH,
      size: size,
      fixedHeight: height,
      shape: LiveShape.square,
    );

/// Conductor y auto en una sola imagen, y el avatar suelto para la isla.
LiveImage get _runHeader => _img('header.png', 760, 308, height: 40);
LiveImage get _runAvatar => _img('avatar.png', 200, 205, size: 34);

/// Los 15 presets de la galería.
final catalog = <CatalogEntry>[
  // --- Diseños de referencia (lib/src/presets/designs.dart) ---
  // Los textos y las imágenes son de ejemplo: cámbialos con los parámetros
  // (brand, brandLogo, trackerImage, compactIcon, driverPhoto…).
  CatalogEntry(
    'ride_light',
    'Recogida · tarjeta clara',
    (a, b) => RidePickupPreset(
      accent: _a(a, const RidePickupPreset().accent),
      headerImage: _runHeader,
      driverPhoto: _runAvatar,
    ),
  ),
  CatalogEntry(
    'ride_dark',
    'Recogida · tarjeta oscura',
    (a, b) => RidePickupPreset(
      dark: true,
      accent: _a(a, const RidePickupPreset().accent),
      headerImage: _runHeader,
      driverPhoto: _runAvatar,
    ),
  ),
  CatalogEntry(
    'ride_arrival',
    'Llegada · azul oscuro',
    (a, b) =>
        RideArrivalPreset(accent: _a(a, const RideArrivalPreset().accent)),
  ),
  CatalogEntry(
    'ride_trip',
    'Viaje · detalle en morado',
    (a, b) => RideTripPreset(
      accent: _a(a, const RideTripPreset().accent),
      driverPhoto: _runAvatar,
    ),
  ),
  CatalogEntry(
    'ride_pin',
    'Inicio de viaje · código PIN',
    (a, b) => RidePinPreset(
      accent: _a(a, const RidePinPreset().accent),
      driverPhoto: _runAvatar,
    ),
  ),
  CatalogEntry(
    'ride_stop',
    'Conductor con parada previa',
    (a, b) => RideStopPreset(accent: _a(a, const RideStopPreset().accent)),
  ),
  CatalogEntry(
    'ride_destination',
    'Rumbo al destino',
    (a, b) => RideDestinationPreset(
      accent: _a(a, const RideDestinationPreset().accent),
    ),
  ),
  CatalogEntry(
    'delivery_order',
    'Pedido a domicilio · cuatro etapas',
    (a, b) =>
        DeliveryOrderPreset(accent: _a(a, const DeliveryOrderPreset().accent)),
  ),
  CatalogEntry(
    'charge',
    'Carga · cable luminoso',
    (a, b) => ChargePreset(accent: _a(a, const ChargePreset().accent)),
  ),
  CatalogEntry(
    'fare',
    'Tarifa · tramos de color',
    (a, b) => FareSplitPreset(accent: _a(a, const FareSplitPreset().accent)),
  ),
  CatalogEntry(
    'store',
    'Pedido en tienda',
    (a, b) =>
        StorePickupPreset(accent: _a(a, const StorePickupPreset().accent)),
  ),
  CatalogEntry(
    'run',
    'Carrera',
    (a, b) => RunPreset(accent: _a(a, const RunPreset().accent)),
  ),
  CatalogEntry(
    'match',
    'Marcador de partido',
    (a, b) => MatchPreset(accent: _a(a, const MatchPreset().accent)),
  ),
  CatalogEntry(
    'stock',
    'Bolsa · gráfica',
    (a, b) => StockPreset(accent: _a(a, const StockPreset().accent)),
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
    (a, b) => TrainPreset(accent: _a(a, const TrainPreset().accent)),
  ),

  // --- Los 15 presets de la galería ---
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
