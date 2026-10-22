# live_island_kit

<p align="center"><img src="https://raw.githubusercontent.com/VMichael1999/live_island_kit/main/doc/assets/banner.es.png" alt="live_island_kit: Live Activities y Live Updates 100 % en Dart" width="100%"></p>

[English](README.md)

**Live Activities de iOS y Live Updates de Android con una sola API en Dart, y 100 % editables desde Dart.** Tú defines los datos y el diseño de la isla dinámica, de la pantalla de bloqueo y de la notificación de Android (textos, colores, íconos o imágenes, barras, gráficas, botones…) **sin escribir Swift ni Kotlin**: el código nativo vive dentro del plugin.

- **iOS:** Dynamic Island (compacta, mínima y expandida), pantalla de bloqueo, StandBy, Apple Watch y CarPlay.
- **Android:** notificaciones en curso que Android 16 o superior **promueve a Live Update** (chip en la barra de estado, arriba del panel y en la pantalla de bloqueo).

| Recogida de viaje | Marcador de partido | Cotización en bolsa |
| --- | --- | --- |
| <img src="https://raw.githubusercontent.com/VMichael1999/live_island_kit/main/doc/assets/galeria/recogida_clara.png" width="300" alt="Recogida de viaje"> | <img src="https://raw.githubusercontent.com/VMichael1999/live_island_kit/main/doc/assets/galeria/marcador.png" width="300" alt="Marcador de partido"> | <img src="https://raw.githubusercontent.com/VMichael1999/live_island_kit/main/doc/assets/galeria/bolsa.png" width="300" alt="Cotización en bolsa"> |
| **Pedido en tienda** | **Sala de espera médica** | **Carga de auto eléctrico** |
| <img src="https://raw.githubusercontent.com/VMichael1999/live_island_kit/main/doc/assets/galeria/tienda.png" width="300" alt="Pedido en tienda"> | <img src="https://raw.githubusercontent.com/VMichael1999/live_island_kit/main/doc/assets/galeria/sala_medica.png" width="300" alt="Sala de espera médica"> | <img src="https://raw.githubusercontent.com/VMichael1999/live_island_kit/main/doc/assets/galeria/carga.png" width="300" alt="Carga con cable luminoso"> |
| **Vuelo con ruta curva** | **Inicio de viaje con PIN** | **Pedido a domicilio** |
| <img src="https://raw.githubusercontent.com/VMichael1999/live_island_kit/main/doc/assets/galeria/vuelo.png" width="300" alt="Vuelo"> | <img src="https://raw.githubusercontent.com/VMichael1999/live_island_kit/main/doc/assets/galeria/pin.png" width="300" alt="Inicio de viaje con PIN"> | <img src="https://raw.githubusercontent.com/VMichael1999/live_island_kit/main/doc/assets/galeria/pedido.png" width="300" alt="Pedido a domicilio"> |

*Cada imagen muestra la isla compacta, la isla expandida y la tarjeta de la pantalla de bloqueo. Son la vista previa de Flutter (`LiveIslandPreview`), salvo la carga, que es una captura del simulador de iOS (la vista previa no dibuja el brillo). Todos son diseños de ejemplo, con nombres e imágenes inventados, y cada texto, color e imagen se cambia desde Dart.*

## Por qué live_island_kit

- **Una sola API.** `LiveIsland.start / update / end` hace lo mismo en iOS y en Android.
- **Diseño en Dart.** Un diseño es un árbol de componentes (`LiveText`, `LiveRow`, `LiveProgress`, `LiveSparkline`…) que se enlaza a los datos con `bind('campo')`. Lo dibuja SwiftUI en iOS y `Notification.ProgressStyle` en Android.
- **Presets y diseños de ejemplo.** 15 presets listos y 10 diseños más elaborados (los de arriba) como punto de partida: se usan tal cual o se modifican.
- **Vista previa sin compilar.** `LiveIslandPreview` dibuja las mismas superficies dentro de tu app de Flutter, y `LiveIsland.check()` avisa de lo que no cabe o no funciona en cada plataforma.
- **Datos ligeros.** El diseño viaja una vez; en cada actualización solo viaja el estado (menos de 4 KB, el límite de iOS).
- **Push.** Actualizar e iniciar actividades desde el servidor con APNs y FCM.

> **Estado:** 0.1.0, primera versión. La API puede evolucionar antes de la 1.0.

## Requisitos

| | Mínimo | Notas |
| --- | --- | --- |
| iOS | 16.1 (push-to-start: 17.2; botones: 17) | Xcode 15 o superior; con Xcode 27 el destino mínimo de la app es iOS 15.0 |
| Android | API 26 (Live Update: API 36) | Por debajo de Android 16 se muestra una notificación en curso con barra estándar |
| Flutter | 3.29 | iOS con CocoaPods o con Swift Package Manager (probado en 3.29, 3.41 y 3.47) |

## Instalación

```bash
flutter pub add live_island_kit
dart run live_island_kit:setup
```

`setup` agrega a `ios/` el Widget Extension, el App Group y `NSSupportsLiveActivities`, y se puede repetir para actualizar el renderer. Solo falta, una vez, elegir tu equipo de desarrollo en los targets *Runner* y *LiveIslandExtension* de Xcode. Con `--push` también agrega el permiso de push (ver [doc/push.md](doc/push.md)).

En Android el plugin declara los permisos `POST_NOTIFICATIONS` y `POST_PROMOTED_NOTIFICATIONS`; pide el de notificaciones con `LiveIsland.requestPermission()` antes de iniciar.

## Uso

Hay tres niveles, del más rápido al más libre. Los tres terminan en el mismo `LiveLayout`.

### 1. Un preset

Quince casos listos (taxi, delivery, estacionamiento, vuelo…) y diez diseños más elaborados (ver [Los presets](#los-presets)), cada uno con sus datos de ejemplo:

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

### Actividades con id propio

Dale a cada actividad un id de tu app y olvídate del id de la plataforma:

```dart
// Crea la actividad; si ya hay una con ese id, la actualiza en vez de duplicarla.
final viaje = await LiveIsland.start(
  customId: 'viaje-42',
  layout: layout,
  state: estado,
);

// Tras reabrir la app (aunque el proceso muriera):
final a = await LiveIsland.activity('viaje-42'); // null si ya terminó
await a?.update({'progreso': 0.8});

// Cerrar sesión, cambiar de cuenta…
await LiveIsland.endAll();
```

El id es tuyo y puede repetirse entre actividades que terminaron. `LiveIsland.activeActivities()` lista las vivas con su `customId`.

### Varias actividades a la vez

iOS muestra **una sola** actividad en la isla: la de mayor `relevance` (con el mismo valor, la más antigua). Las demás quedan en la pantalla de bloqueo. Por eso, si inicias un caso nuevo y otro sigue vivo, la isla seguirá mostrando el anterior. Dale más `relevance` a la que quieres ver, o termina la anterior:

```dart
await LiveIsland.start(layout: layout, state: estado, relevance: 100);
await LiveIsland.endAll(); // o termina solo las que ya no hacen falta
```

La app de ejemplo termina las demás al iniciar un caso, para que cada uno se vea en la isla.

### Terminar a una hora

```dart
// Desaparece a las 18:30; la tarjeta se queda con este último estado hasta entonces.
await actividad.scheduleEnd(
  DateTime(2026, 10, 12, 18, 30),
  state: {'estado': 'entregado'},
);

// O al terminar ahora, con descarte a una hora (en vez de una espera):
await actividad.end(dismiss: LiveDismiss.at(DateTime(2026, 10, 12, 18, 30)));
```

Cambia según la plataforma, porque ActivityKit no puede «terminar más tarde» una actividad viva:

| | `scheduleEnd(at)` |
| --- | --- |
| iOS | Termina **ya** (sale de la isla y no se actualiza más); la tarjeta de bloqueo se queda hasta `at` (iOS la quita, como mucho, 4 h después) |
| Android | Sigue **viva y actualizable**; el sistema la retira solo a las `at`, aunque la app esté cerrada |

Si `at` ya pasó, termina de inmediato.

### Saber qué pasó con una actividad

`LiveIsland.stateChanges` avisa de cada cambio en la vida de tus actividades, y `activity.states` los de una sola actividad:

```dart
LiveIsland.stateChanges.listen((c) {
  // c.id, c.customId, c.state
  if (c.state == LiveActivityState.dismissed) {
    // El usuario descartó la tarjeta (o se retiró): deja de seguir al conductor.
  }
});
```

| Estado | Significa | iOS | Android |
| --- | --- | --- | --- |
| `active` | Se muestra y acepta actualizaciones | Sí | Sí |
| `stale` | Pasó `staleAfter` sin una actualización | Sí | No |
| `ended` | La app o el servidor la terminó (puede seguir en pantalla con su último estado) | Sí | Sí |
| `dismissed` | Salió de la pantalla: el usuario la descartó, o la retiró el sistema o el plazo de cierre | Sí | Sí |

Los eventos llegan mientras escuchas, también de actividades iniciadas por un push o antes de abrir la app (iOS); para saber cuáles siguen vivas ahora usa `LiveIsland.activeActivities()`.

### Avisos y estado desactualizado

```dart
// Llama la atención: la isla se expande y suena (iOS); en Android suena y sale emergente.
await actividad.update(
  {'estado': 'llegó'},
  alert: const LiveAlert(title: 'Tu conductor llegó', body: 'Toyota Yaris · ABC-123'),
);

// Pasada la fecha, el sistema vuelve a dibujar la actividad con `stale` en true,
// sin push ni actualización: muestra ahí el estado final.
final actividad = await LiveIsland.start(
  layout: layout.copyWith(...),     // con LiveIf(LiveBind.stale.isTrue, ...)
  state: estado,
  staleAfter: const Duration(minutes: 15),
);
```

`LiveBind.stale` solo existe en iOS 16.2 o superior y en la vista previa (`LiveIslandPreview(stale: true)`). En Android siempre es `false`: ahí cambia el estado con `update`.

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

## Gráficas y efectos

Además de textos, íconos y barras, el diseño admite gráficas y efectos. Todos viajan en el mismo contrato JSON y se dibujan igual en iOS y en la vista previa. En Android se degradan como indica la tabla de [compatibilidad](#compatibilidad).

```dart
// Gráfica de línea: la serie viaja en el estado como texto ("212,214.5,213").
LiveSparkline(series: bind('serie'), height: 44, color: Color(0xFF30D158));
update({'serie': liveSeries([212, 214.5, 213.2, 219.4])});

// Medidor de arco con un punto que avanza (una órbita, un parquímetro…).
LiveGauge(value: bind('progreso'), size: 96, sweep: 180);

// Ruta curva con un ícono que avanza (un vuelo, un envío).
LiveFlightPath(value: bind('progreso'), tracker: LiveIcon.symbol('airplane'));

// Barra partida en tramos de color, en proporción a valores del estado.
LiveSplitBar([
  LiveSplitPart(bind('base'), Color(0xFFFFFFFF)),
  LiveSplitPart(bind('propina'), Color(0xFF30D158)),
]);

// Cable luminoso, marcadores y trazo punteado en una barra.
LiveProgress.bar(
  value: bind('progreso'),
  style: LiveProgressStyle(
    glow: 10, dashed: true, markers: [.6, 1], pointShape: LivePointShape.ring,
  ),
);

// Borde con brillo y cursiva.
LiveBox(border: Color(0xFF30D158), glow: 10, child: LiveText.literal('Run', italic: true));
```

### Tus propias imágenes

Los diseños de ejemplo usan dibujos propios del paquete. Pon los tuyos (logo, foto del conductor, auto, escudos…) con `LiveImage.asset(...)`:

```dart
RidePickupPreset(
  brand: 'Mi app',
  // Una imagen ancha sin fondo (conductor + auto): alto fijo, ancho según su proporción.
  headerImage: LiveImage.asset('assets/conductor_y_auto.png', width: 760, height: 308, fixedHeight: 40),
  driverPhoto: LiveImage.asset('assets/foto.png', size: 34, shape: LiveShape.circle),
  trackerImage: LiveImage.asset('assets/auto_cenital.png', width: 88, height: 46),
);
```

Toda imagen se dibuja en un cuadrado de `size` salvo que uses `fixedHeight` (o `withHeight(n)`), que fija el alto y deja libre el ancho. Usa PNG con fondo transparente para que no se vea un recuadro.

### Medidas de la tarjeta de bloqueo

iOS limita la tarjeta de la pantalla de bloqueo a unos **160 pt de alto** con el relleno del sistema, así que tu diseño dispone de unos 125 pt: lo que sobre se recorta. Reduce márgenes y tamaños antes que añadir filas, y revisa el resultado en un dispositivo o simulador además de la vista previa. En la isla compacta usa textos de una palabra.

## Íconos e imágenes

Donde va un ícono puedes poner uno del sistema o una imagen tuya (logo de la app o del cliente, foto, ilustración):

```dart
LiveIcon.symbol('car.fill', android: 'assets/live/car.png') // SF Symbol en iOS, PNG en Android
LiveImage.asset('assets/logo.png', fit: LiveFit.cover, shape: LiveShape.rounded)
LiveImage.network(url, shape: LiveShape.circle)
```

La imagen se reduce al tamaño con que se muestra antes de copiarse al dispositivo y nunca se deforma. Android pinta el ícono pequeño de la barra de estado como silueta de un solo color: pasa `androidSmallIcon` con una versión en silueta de tu logo.

### Animación de la isla (gota)

`LiveIslandMorph` dibuja la isla soltando una gota que se abre en tarjeta, con el contenido de tu diseño. Sirve en la vista previa y como aviso dentro de tu app; la isla real la dibuja el sistema y no se anima así.

![Gota](https://raw.githubusercontent.com/VMichael1999/live_island_kit/main/doc/assets/gota.gif)

```dart
LiveIslandMorph.preview(
  LivePreviewConfig(layout: layout, state: state),
  visible: mostrar,
  onTap: () => abrirViaje(),
  onDismissed: () => setState(() => mostrar = false),
);
```

Deslizar hacia arriba la descarta; `blur`, `gain`, `threshold`, `dropSize` y `timeScale` ajustan lo líquido y la velocidad.

## Botones

```dart
LiveIsland.onAction((id) { /* el id del LiveButton tocado */ });
```

Los botones aparecen en la **tarjeta de la pantalla de bloqueo** (iOS 17 o superior, sin abrir la app) y en la **notificación de Android**. La isla expandida de iOS no los dibuja: tocar la isla siempre abre la app. Si la app estaba cerrada, la acción se entrega cuando vuelves a escuchar `onAction`; recupera las actividades vivas con `LiveIsland.activeActivities()`.

## Push

Actualizar e iniciar actividades desde el servidor, con APNs en iOS y FCM en Android: ver [doc/push.md](doc/push.md).

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

### Diseños de ejemplo

Más elaborados que los presets, con isla y tarjeta de bloqueo propias; se usan igual (`.build()`, `.sampleState()`, `.override(...)`):

| Diseño | Qué muestra | Lo que más se personaliza |
| --- | --- | --- |
| `RidePickupPreset` | Recogida de un viaje, tarjeta clara u oscura | `brand`, `headerImage`, `driverPhoto`, `trackerImage`, `compactIcon`, `bar` (`RideBar.dotted` o `.line`) |
| `RideArrivalPreset` | Hora de llegada, pago y auto con su placa | `brand`, `carImage`, `accent` |
| `RideTripPreset` | Viaje con fase, destino, categoría, pago y barra | `brand`, `driverPhoto`, `accent` |
| `DeliveryOrderPreset` | Pedido a domicilio en cuatro etapas con íconos | `brand`, `accent` |
| `RidePinPreset` | Inicio de viaje con el código PIN, foto del conductor y barra | `brand`, `driverPhoto`, `accent` |
| `RideStopPreset` | Conductor con una parada previa numerada, auto con placa | `brand`, `stopAt`, `carImage` |
| `RideDestinationPreset` | Rumbo al destino: hora, dirección y barra con cuadrado final | `brand`, `accent` |
| `TrainPreset` | Línea de tren con estaciones y el tren sobre la barra | `stages`, `trainImage`, `accent` |
| `StorePickupPreset` | Pedido para recoger, con tres pasos | `store`, `brandLogo`, `stepColor` |
| `RunPreset` | Carrera: distancia, tiempo y meta | `brand`, `unit`, `timeLabel` |
| `MatchPreset` | Marcador de un partido | `homeCrest`, `awayCrest`, `homeLabel`, `link` |
| `StockPreset` | Cotización con gráfica de línea | `brandLogo`, `accent` |
| `FlightPathPreset` | Vuelo con la ruta curva | `carrier`, `accent` |
| `OrbitPreset` | Arco con un punto que avanza | `sweep`, `accent` |
| `ChargePreset` | Carga con cable luminoso | `glow`, `accent` |
| `FareSplitPreset` | Tarifa partida en base, servicio y propina | `brand`, `accent` |

La app de [`example/`](example) tiene una pantalla por preset y diseño, y un editor que parte de uno de ellos.

### Android: Live Update o tarjeta

Los diseños de ejemplo usan la **tarjeta** por defecto, para que Android dibuje lo mismo que iOS; con `androidStyle: LiveAndroidStyle.liveUpdate` vuelves al estilo nativo. Ese estilo (`LiveAndroidStyle.liveUpdate`, el de `LiveAndroid` si no indicas otro): título, texto, barra, una imagen grande y el chip de la barra de estado, y Android 16 lo **promueve a Live Update**. Si necesitas más libertad (dos escudos enfrentados, un marcador grande, una gráfica), pide la **tarjeta**: se dibuja con tu diseño, pero Android **no la promueve ni muestra chip**.

```dart
LiveAndroid(
  style: LiveAndroidStyle.card,   // por defecto: LiveAndroidStyle.liveUpdate
  card: miTarjeta,                // opcional: si falta, la tarjeta de bloqueo propia
  title: const LiveText.literal('Marcador'),
)
// o con un preset:
MatchPreset(androidStyle: LiveAndroidStyle.liveUpdate)
```

La tarjeta pide Android 12 o más (antes se usa el estilo nativo). Detalles en [`doc/design/DESVIACIONES.md`](doc/design/DESVIACIONES.md).

## Solución de problemas

**No aparece nada en el iPhone.** Revisa, en orden: `await LiveIsland.areEnabled()` es `true` (el usuario puede apagar las Live Activities por app en Ajustes); los targets *Runner* y *LiveIslandExtension* tienen **el mismo** App Group; `NSSupportsLiveActivities` está en `YES` en `ios/Runner/Info.plist`; la extensión está incrustada en la app y tiene equipo de desarrollo; y `LiveIsland.check(layout, state)` no da errores. Volver a correr `dart run live_island_kit:setup` repara los tres primeros.

**`pod install` dice «requires a higher minimum iOS deployment version».** El plugin necesita iOS 15. `setup` sube `platform :ios` en el `Podfile` y en el proyecto de Xcode a 15.0; si editas el `Podfile` a mano, pon `platform :ios, '15.0'` y vuelve a correr `pod install`.

**El build de Android falla con «minSdkVersion 24 cannot be smaller than version 26».** El plugin necesita API 26. `setup` sube `minSdk` en `android/app/build.gradle(.kts)` a 26 (y nunca baja un valor mayor); también puedes ponerlo tú.

**Flutter avisa de que `live_island_kit` «applies Kotlin Gradle Plugin».** Por ahora es solo un aviso: el build funciona.

**Códigos de `LiveIslandException`.** `disabled`: el usuario apagó las Live Activities (iOS) o las notificaciones (Android); en Android llama antes a `LiveIsland.requestPermission()`. `unsupported`: el dispositivo no tiene Live Activities (iOS anterior a 16.1, iPad, Mac). `not_found`: la actividad ya terminó o el id no existe. `not_configured`: falta el App Group; corre `dart run live_island_kit:setup` y compila de nuevo. `start_failed`: el sistema se negó a iniciarla; el mensaje de la excepción trae el motivo. `LiveIsland.check()` avisa antes de un estado de más de 4.096 bytes.

**La actividad se queda en un valor viejo.** iOS limita cada cuánto puede actualizarse una actividad y la termina a las ocho horas. Define `staleAfter` para que la tarjeta muestre que está desactualizada y actualiza por push ([doc/push.md](doc/push.md)).

**El chip de Live Update no aparece en Android.** Necesita Android 16 y que el usuario permita las notificaciones promovidas de la app: `LiveIsland.openPromotionSettings()` abre esa pantalla. Antes de Android 16 se muestra una notificación estándar con barra.

## Compatibilidad

| | iOS | Android 16+ |
| --- | --- | --- |
| Isla dinámica (compacta, mínima, expandida) | Sí | No existe |
| Pantalla de bloqueo con diseño propio | Sí (`LiveLockScreen.custom`) | Notificación estándar |
| Texto, íconos e imágenes | Sí | Título, texto, chip e íconos |
| Barra, etapas y puntos | Sí, con todo su estilo | Color y marcadores; el grosor lo decide el sistema |
| Trazo punteado, cable luminoso, borde con brillo | Sí | Se ignoran |
| Anillo y medidor de arco | Sí | Se muestran como barra |
| Ruta curva | Sí | Barra con el mismo ícono |
| Gráfica de línea y barra partida | Sí | Se omiten |
| Diseño propio completo | Sí | Con `style: card` (sin chip ni Live Update) |
| Botones | Pantalla de bloqueo (iOS 17+); la isla abre la app | En la notificación |
| Estado desactualizado (`stale`) | iOS 16.2+ | Siempre `false` |

Si algo no se puede mostrar en Android, `LiveIsland.check()` lo avisa antes de publicar.

## Qué no entra

- Música (el sistema ya usa *Now Playing* y `MediaSession`) y llamadas (CallKit y `CallStyle`).
- Dibujar widgets arbitrarios de Flutter en la isla: no es posible; solo los componentes del paquete.

## Más documentación

- [`doc/contract/`](doc/contract): el contrato JSON entre Dart, Swift y Kotlin y sus reglas de render.
- [`doc/design/DESVIACIONES.md`](doc/design/DESVIACIONES.md): en qué se diferencian iOS y Android del prototipo.
- [`doc/push.md`](doc/push.md): formato de los push de APNs y FCM.
