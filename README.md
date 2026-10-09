# live_island

[English](README.en.md)

Actividades en vivo con **una sola API en Dart**:

- **iOS:** Live Activities en la Dynamic Island (compacta, mínima y expandida), la pantalla de bloqueo, StandBy, el Apple Watch y CarPlay.
- **Android:** notificaciones en curso que Android 16 o superior **promueve a Live Update** (chip en la barra de estado, arriba del panel y en la pantalla de bloqueo).

Tú defines tus datos y tu diseño (textos, colores, íconos o imágenes, barra de progreso, el ícono que avanza sobre la barra, etapas, botones, el chip de Android) **sin escribir Swift ni Kotlin**. El código nativo vive dentro del plugin; `dart run live_island:setup` agrega lo necesario al proyecto de Xcode.

| Taxi | Estacionamiento | Delivery |
| --- | --- | --- |
| ![Taxi](https://raw.githubusercontent.com/VMichael1999/live_island/main/docs/assets/taxi.gif) | ![Estacionamiento](https://raw.githubusercontent.com/VMichael1999/live_island/main/docs/assets/estacionamiento.gif) | ![Delivery](https://raw.githubusercontent.com/VMichael1999/live_island/main/docs/assets/delivery.gif) |

*Vista previa de Flutter (`LiveIslandPreview`) de cada preset: la isla compacta y la tarjeta de la pantalla de bloqueo, con el avance y la cuenta regresiva.*

> **Estado:** versión previa (0.1.0 sin publicar). La API puede cambiar hasta publicarla.

## Requisitos

| | Mínimo | Notas |
| --- | --- | --- |
| iOS | 16.1 (push-to-start: 17.2; botones: 17) | Xcode 15 o superior; con Xcode 27 el destino mínimo de la app es iOS 15.0 |
| Android | API 26 (Live Update: API 36) | Por debajo de Android 16 se muestra una notificación en curso con barra estándar |
| Flutter | 3.29 | |

## Instalación

```bash
flutter pub add live_island
dart run live_island:setup
```

`setup` agrega a `ios/` el Widget Extension, el App Group y `NSSupportsLiveActivities`, y se puede repetir para actualizar el renderer. Solo falta, una vez, elegir tu equipo de desarrollo en los targets *Runner* y *LiveIslandExtension* de Xcode. Con `--push` también agrega el permiso de push (ver [docs/push.md](docs/push.md)).

En Android el plugin declara los permisos `POST_NOTIFICATIONS` y `POST_PROMOTED_NOTIFICATIONS`; pide el de notificaciones con `LiveIsland.requestPermission()` antes de iniciar.

## Uso

Hay tres niveles, del más rápido al más libre. Los tres terminan en el mismo `LiveLayout`.

### 1. Un preset

Quince casos listos (taxi, delivery, estacionamiento, vuelo…), cada uno con sus datos de ejemplo:

```dart
final actividad = await LiveIsland.start(
  layout: const ParkingPreset().build(),
  state: {
    'titulo': 'Estacionamiento activo',
    'subtitulo': 'Zona azul · Av. Larco 400',
    'nombre': 'Placa ABC-123',
    'llegaA': DateTime.now().add(const Duration(minutes: 45)),
    'progreso': 0.0,
  },
);

await actividad.update({'progreso': 0.5}); // solo viaja lo que cambia
await actividad.end(dismiss: const LiveDismiss.after(Duration(minutes: 5)));
```

Cada preset acepta sus parámetros más comunes: `accent`, `icon`, `appLogo`, `androidSmallIcon`, `lockBackground`, `buttons`, `chip` y, según el caso, `stages`, `tracker`, `endIcon` o `avatarText`.

### 2. Un preset con `.override`

Cambia una región y deja el resto:

```dart
final layout = const TripPreset(
  accent: Color(0xFFD81B60),
  stages: ['Pedido', 'En camino', 'Llegó'],
).override(
  // La isla compacta muestra la placa en lugar de la cuenta regresiva.
  compactTrailing: LiveText.from(
    const LiveText(LiveBind('placa')),
    size: 15,
    weight: 600,
    accent: true,
  ),
);
```

`override` también reemplaza una sola zona de la isla expandida (`expandedLeading`, `expandedCenter`, `expandedTrailing`, `expandedBottom`) o el bloque de Android (`android:`).

### 3. Un diseño desde cero

```dart
final layout = LiveLayout(
  theme: const LiveTheme(accent: Color(0xFF00897B)),
  compactLeading: const LiveIcon.symbol('timer', accent: true),
  compactTrailing: LiveText.from(
    LiveText.countdown(bind('termina')),
    size: 15, weight: 600, accent: true,
  ),
  minimal: const LiveIcon.symbol('timer', accent: true),
  expanded: LiveExpanded(
    leading: const LiveBox(
      child: LiveIcon.symbol('timer', accent: true),
      size: 46, radius: 14, tint: 0.22,
    ),
    center: const LiveColumn([
      LiveText(LiveBind('titulo'), size: 15, weight: 600),
      LiveText(LiveBind('detalle'), size: 13, muted: true),
    ]),
    trailing: LiveText.from(
      LiveText.countdown(bind('termina')),
      size: 22, weight: 700, accent: true,
    ),
    bottom: LiveProgress.bar(value: bind('progreso')),
  ),
  lockScreen: const LiveLockScreen.sameAsExpanded(),
  android: LiveAndroid(
    title: bind('titulo'),
    text: const LiveText.format('{detalle}'),
    chip: LiveChip.countdown(bind('termina')),
  ),
);
```

El **diseño** viaja una sola vez, al iniciar; en cada actualización solo viaja el **estado** (los datos), para quedar bajo los 4 KB que permite iOS. Los textos, contadores y barras se enlazan al estado con `bind('campo')`.

### Barra de progreso editable

Todo en la barra es opcional y ajustable:

```dart
DeliveryPreset(
  showLabels: false,   // sin "Preparando · Paso 2 de 4"
  showPoints: true,    // puntos de etapa
  showTracker: true,   // ícono que avanza
  showEndIcon: false,  // sin marcador final
  progressStyle: LiveProgressStyle(
    height: 12, color: Color(0xFFC62828), trackColor: Color(0xFF3A2A2A),
    gap: 2, pointSize: 16, trackerSize: 32,
  ),
);
```

Lo mismo con `LiveProgress.bar(style: ...)` y `LiveSegments(style: ..., showLabels: ...)`. En Android solo cambian el color de la barra y de los puntos; el sistema decide el resto.

## Íconos e imágenes

Donde va un ícono puedes poner uno del sistema o una imagen tuya (logo de la app o del cliente, foto, ilustración):

```dart
LiveIcon.symbol('car.fill', android: 'assets/live/car.png') // SF Symbol en iOS, PNG en Android
LiveImage.asset('assets/logo.png', fit: LiveFit.cover, shape: LiveShape.rounded)
LiveImage.network(url, shape: LiveShape.circle)
```

La imagen se reduce al tamaño con que se muestra antes de copiarse al dispositivo y nunca se deforma. Android pinta el ícono pequeño de la barra de estado como silueta de un solo color: pasa `androidSmallIcon` con una versión en silueta de tu logo.

## Botones

```dart
LiveIsland.onAction((id) { /* el id del LiveButton tocado */ });
```

Los botones aparecen en la **tarjeta de la pantalla de bloqueo** (iOS 17 o superior, sin abrir la app) y en la **notificación de Android**. La isla expandida de iOS no los dibuja: tocar la isla siempre abre la app. Si la app estaba cerrada, la acción se entrega cuando vuelves a escuchar `onAction`; recupera las actividades vivas con `LiveIsland.activeActivities()`.

## Push

Actualizar e iniciar actividades desde el servidor, con APNs en iOS y FCM en Android: ver [docs/push.md](docs/push.md).

## Probar sin compilar la extensión

`LiveIslandPreview` dibuja en Flutter las mismas superficies (isla compacta, mínima y expandida, tarjeta de bloqueo y notificación de Android):

```dart
LiveIslandPreview(layout: layout, state: estado, appName: 'Mi app')
```

`LiveIsland.check(layout, estado)` valida el diseño con los mismos avisos del panel del prototipo (peso del estado, texto largo en la isla compacta, chip de Android, si Android lo promueve…).

## Los presets

| Preset | Caso |
| --- | --- |
| `TripPreset` | Taxi |
| `DeliveryPreset` | Comida a domicilio |
| `CourierPreset` | Paquete en ruta |
| `PickupPreset` | Pedido para recoger |
| `QueuePreset` | Turno en un banco |
| `FlightPreset` | Vuelo |
| `ParkingPreset` | Estacionamiento |
| `EvChargingPreset` | Carga de auto eléctrico |
| `WorkoutPreset` | Entrenamiento |
| `CookingTimerPreset` | Temporizador de cocina |
| `UploadPreset` | Subida de un archivo |
| `TechnicianPreset` | Técnico a domicilio |
| `TransitPreset` | Transporte público |
| `WaitingRoomPreset` | Sala de espera médica |
| `ScorePreset` | Marcador deportivo |

La app de [`example/`](example) tiene una pantalla por preset y un editor que parte de uno de ellos.

## Qué no entra

- Música (el sistema ya usa *Now Playing* y `MediaSession`) y llamadas (CallKit y `CallStyle`).
- Dibujar widgets arbitrarios de Flutter en la isla: no es posible; solo los componentes del paquete.

## Más documentación

- [`docs/contract/`](docs/contract): el contrato JSON entre Dart, Swift y Kotlin y sus reglas de render.
- [`docs/design/DESVIACIONES.md`](docs/design/DESVIACIONES.md): en qué se diferencian iOS y Android del prototipo.
- [`docs/push.md`](docs/push.md): formato de los push de APNs y FCM.

### Barra en vivo: sigue la señal del conductor

La barra lee `progreso` del estado, así que basta con actualizarlo. `LiveRoute` convierte una posición en avance y `follow` mantiene la actividad al día sin saturar al sistema:

```dart
final ruta = LiveRoute.straight(origen, destino); // o LiveRoute([a, b, c, ...])

actividad.follow(
  posicionesDelConductor, // Stream<LiveLatLng> de tu mapa, socket o servidor
  (p) => {
    'progreso': ruta.progressAt(p),
    'etapa': ruta.stageAt(p, 4),
  },
  minInterval: const Duration(seconds: 5), // envía como máximo una cada 5 s
);
```

Los puntos de etapa también son tuyos: cuántos (`stages`, con o sin texto: `''`), su forma (`LiveProgressStyle(pointShape: LivePointShape.square)`) y su tamaño. Para eventos (pedido confirmado, llegó) usa el mismo `follow` o `actividad.update({...})`.
