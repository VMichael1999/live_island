import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:live_island_kit/live_island_kit.dart';

/// Los tres intérpretes del JSON (Flutter, SwiftUI y la tarjeta de Android)
/// deben conocer cada tipo de nodo que emiten los presets: si Dart agrega uno
/// y una plataforma no lo dibuja, esta prueba falla antes de que lo vea un
/// usuario.
void main() {
  final presets = <LivePreset>[
    const TripPreset(),
    const DeliveryPreset(),
    const CourierPreset(),
    const PickupPreset(),
    const QueuePreset(),
    const FlightPreset(),
    const ParkingPreset(),
    const EvChargingPreset(),
    const WorkoutPreset(),
    const CookingTimerPreset(),
    const UploadPreset(),
    const TechnicianPreset(),
    const TransitPreset(),
    const WaitingRoomPreset(),
    const ScorePreset(),
    const RidePickupPreset(),
    const RidePickupPreset(dark: true),
    const RideArrivalPreset(),
    const RideTripPreset(),
    const RidePinPreset(),
    const RideStopPreset(),
    const RideDestinationPreset(),
    const TrainPreset(),
    const DeliveryOrderPreset(),
    const StorePickupPreset(),
    const RunPreset(),
    const MatchPreset(),
    const StockPreset(),
    const FlightPathPreset(),
    const OrbitPreset(),
    const ChargePreset(),
    const FareSplitPreset(),
  ];

  void recoger(Object? v, Set<String> tipos) {
    if (v is Map) {
      final t = v['t'];
      if (t is String) tipos.add(t);
      v.values.forEach((e) => recoger(e, tipos));
    } else if (v is List) {
      v.forEach((e) => recoger(e, tipos));
    }
  }

  final tipos = <String>{};
  for (final p in presets) {
    recoger(jsonDecode(jsonEncode(p.build().toJson())), tipos);
  }

  final swift =
      File(
        'ios/LiveIslandExtension/Renderer/LiveRenderer.swift',
      ).readAsStringSync();
  final kotlin = ['CardRenderer.kt', 'CardBitmaps.kt']
      .map(
        (f) => File('android/src/main/kotlin/com/vmichael1999/live_island/$f'),
      )
      .map((f) => f.readAsStringSync())
      .join('\n');

  // La tarjeta de Android no dibuja los botones como vistas del diseño: salen
  // como acciones de la notificación.
  const soloIos = {'button', 'toggle'};

  test('los presets usan tipos de nodo conocidos', () {
    expect(tipos, isNotEmpty);
    expect(tipos, containsAll(<String>['row', 'col', 'text', 'bar', 'image']));
  });

  for (final t in tipos.toList()..sort()) {
    test('SwiftUI dibuja el nodo "$t"', () {
      expect(
        swift.contains('"$t"'),
        isTrue,
        reason: 'falta "$t" en LiveRenderer.swift',
      );
    });
    if (!soloIos.contains(t)) {
      test('la tarjeta de Android dibuja el nodo "$t"', () {
        expect(
          kotlin.contains('"$t"'),
          isTrue,
          reason: 'falta "$t" en CardRenderer/CardBitmaps',
        );
      });
    }
  }
}
