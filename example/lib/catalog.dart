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
    'Pickup · light card',
    (a, b) => RidePickupPreset(
      accent: _a(a, const RidePickupPreset().accent),
      headerImage: _runHeader,
      driverPhoto: _runAvatar,
    ),
  ),
  CatalogEntry(
    'ride_dark',
    'Pickup · dark card',
    (a, b) => RidePickupPreset(
      dark: true,
      accent: _a(a, const RidePickupPreset().accent),
      headerImage: _runHeader,
      driverPhoto: _runAvatar,
    ),
  ),
  CatalogEntry(
    'ride_arrival',
    'Arrival · dark blue',
    (a, b) =>
        RideArrivalPreset(accent: _a(a, const RideArrivalPreset().accent)),
  ),
  CatalogEntry(
    'ride_trip',
    'Trip · purple detail',
    (a, b) => RideTripPreset(
      accent: _a(a, const RideTripPreset().accent),
      driverPhoto: _runAvatar,
    ),
  ),
  CatalogEntry(
    'ride_pin',
    'Trip start · PIN code',
    (a, b) => RidePinPreset(
      accent: _a(a, const RidePinPreset().accent),
      driverPhoto: _runAvatar,
    ),
  ),
  CatalogEntry(
    'ride_stop',
    'Driver with a stop first',
    (a, b) => RideStopPreset(accent: _a(a, const RideStopPreset().accent)),
  ),
  CatalogEntry(
    'ride_destination',
    'Heading to the destination',
    (a, b) => RideDestinationPreset(
      accent: _a(a, const RideDestinationPreset().accent),
    ),
  ),
  CatalogEntry(
    'delivery_order',
    'Delivery order · four stages',
    (a, b) =>
        DeliveryOrderPreset(accent: _a(a, const DeliveryOrderPreset().accent)),
  ),
  CatalogEntry(
    'charge',
    'Charge · glowing cable',
    (a, b) => ChargePreset(accent: _a(a, const ChargePreset().accent)),
  ),
  CatalogEntry(
    'fare',
    'Fare · colored segments',
    (a, b) => FareSplitPreset(accent: _a(a, const FareSplitPreset().accent)),
  ),
  CatalogEntry(
    'store',
    'Store order',
    (a, b) =>
        StorePickupPreset(accent: _a(a, const StorePickupPreset().accent)),
  ),
  CatalogEntry(
    'run',
    'Run',
    (a, b) => RunPreset(accent: _a(a, const RunPreset().accent)),
  ),
  CatalogEntry(
    'match',
    'Match scoreboard',
    (a, b) => MatchPreset(accent: _a(a, const MatchPreset().accent)),
  ),
  CatalogEntry(
    'stock',
    'Stocks · chart',
    (a, b) => StockPreset(accent: _a(a, const StockPreset().accent)),
  ),
  CatalogEntry(
    'flightpath',
    'Flight · curved route',
    (a, b) => FlightPathPreset(accent: _a(a, const FlightPathPreset().accent)),
  ),
  CatalogEntry(
    'orbit',
    'Orbit · arc',
    (a, b) => OrbitPreset(accent: _a(a, const OrbitPreset().accent)),
  ),
  // Un preset de la galería con la barra reestilizada: así queda una línea de tren.
  CatalogEntry(
    'train_line',
    'Train · green line',
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
    'Food delivery',
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
    'Order for pickup',
    (a, b) => PickupPreset(
      accent: _a(a, const PickupPreset().accent),
      lockBackground: b ?? LiveBackground.system,
    ),
  ),
  CatalogEntry(
    'queue',
    'Bank queue',
    (a, b) => QueuePreset(
      accent: _a(a, const QueuePreset().accent),
      lockBackground: b ?? LiveBackground.system,
    ),
  ),
  CatalogEntry(
    'flight',
    'Flight',
    (a, b) => FlightPreset(
      accent: _a(a, const FlightPreset().accent),
      lockBackground: b ?? LiveBackground.system,
    ),
  ),
  CatalogEntry(
    'parking',
    'Parking',
    (a, b) => ParkingPreset(
      accent: _a(a, const ParkingPreset().accent),
      lockBackground: b ?? LiveBackground.system,
    ),
  ),
  CatalogEntry(
    'ev',
    'Electric car charging',
    (a, b) => EvChargingPreset(
      accent: _a(a, const EvChargingPreset().accent),
      lockBackground: b ?? LiveBackground.system,
    ),
  ),
  CatalogEntry(
    'workout',
    'Workout',
    (a, b) => WorkoutPreset(
      accent: _a(a, const WorkoutPreset().accent),
      lockBackground: b ?? LiveBackground.system,
    ),
  ),
  CatalogEntry(
    'cooking',
    'Kitchen timer',
    (a, b) => CookingTimerPreset(
      accent: _a(a, const CookingTimerPreset().accent),
      lockBackground: b ?? LiveBackground.system,
    ),
  ),
  CatalogEntry(
    'upload',
    'File upload',
    (a, b) => UploadPreset(
      accent: _a(a, const UploadPreset().accent),
      lockBackground: b ?? LiveBackground.system,
    ),
  ),
  CatalogEntry(
    'technician',
    'Home technician',
    (a, b) => TechnicianPreset(
      accent: _a(a, const TechnicianPreset().accent),
      lockBackground: b ?? LiveBackground.system,
    ),
  ),
  CatalogEntry(
    'transit',
    'Public transport',
    (a, b) => TransitPreset(
      accent: _a(a, const TransitPreset().accent),
      lockBackground: b ?? LiveBackground.system,
    ),
  ),
  CatalogEntry(
    'waiting',
    'Medical waiting room',
    (a, b) => WaitingRoomPreset(
      accent: _a(a, const WaitingRoomPreset().accent),
      lockBackground: b ?? LiveBackground.system,
    ),
  ),
  CatalogEntry(
    'score',
    'Sports score',
    (a, b) => ScorePreset(
      accent: _a(a, const ScorePreset().accent),
      lockBackground: b ?? LiveBackground.system,
    ),
  ),
];
