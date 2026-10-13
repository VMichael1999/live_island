## 0.1.0

Primera versión publicada.

* API única en Dart (`LiveIsland.start/update/end`) para Live Activities de iOS y Live Updates de Android 16+.
* Contrato JSON v1 (diseño una vez, estado ≤ 4 096 bytes) compartido por Dart, Swift y Kotlin.
* iOS: Widget Extension genérico en SwiftUI (isla compacta, expandida y mínima, pantalla de bloqueo, StandBy), botones con `LiveActivityIntent` (iOS 17+), push tokens y push-to-start (iOS 17.2).
* Android: `Notification.ProgressStyle`, chip, promoción a Live Update, botones, cola de acciones y entrada de push FCM.
* `dart run live_island:setup` configura el proyecto de Xcode (`--push` para APNs).
* Componentes: texto, contadores, íconos e imágenes, avatar, barra, anillo, etapas, tracker, botones.
* Barra de progreso editable: color, grosor, puntos, etiquetas, ícono que avanza y marcador final (`LiveProgressStyle`).
* Puntos de etapa a gusto: cantidad, con o sin texto, y forma (`LivePointShape`: círculo, cuadrado, redondeado).
* Barra en vivo: `LiveRoute` convierte la posición en avance y `LiveActivity.follow` mantiene la actividad al día con un `Stream`, espaciando las actualizaciones.
* `LiveIslandMorph`: la isla suelta una gota que se abre en tarjeta (vista previa y aviso dentro de la app), con descarte por gesto.
* iOS: manifiesto de privacidad que declara el uso de `UserDefaults` del App Group (motivo `1C8F.1`), empaquetado con el plugin y copiado a la extensión por `dart run live_island:setup`; el podspec toma la versión del paquete.
* Actividades con id propio: `start(customId:)` crea o actualiza, `LiveIsland.activity(customId)` las encuentra tras reabrir la app, `LiveIsland.endAll()` las termina y `activeActivities()` trae su `customId`. Los push de Android aceptan `customId` en `start` y como `id` en `update`/`end`.
* Avisos: `update(alert: LiveAlert(...))` expande la isla y suena en iOS; en Android usa un canal con sonido y sale como emergente. El push de Android acepta `"alert": true`.
* Estado desactualizado: `LiveBind.stale` (campo reservado `$stale`) cambia el diseño al pasar `staleAfter` sin push (iOS 16.2+).
* Ejemplo: iniciar un caso termina el anterior y usa `relevance: 100`, para que la isla muestre siempre el que se acaba de iniciar (iOS solo muestra una actividad en la isla).
* Fin programado: `LiveActivity.scheduleEnd(at)` y `LiveDismiss.at(DateTime)`. En Android la notificación sigue viva y el sistema la retira a esa hora; en iOS termina ya y la tarjeta se queda hasta esa hora.
* iOS: soporte de Swift Package Manager (`ios/live_island/Package.swift`), además de CocoaPods; ambos usan las mismas fuentes. Probado con Flutter 3.29, 3.41 y 3.47.
* Diseños de referencia (`RidePickupPreset` clara y oscura, `StorePickupPreset`, `RunPreset`, `MatchPreset`) y una línea de tren hecha con `TransitPreset`: tarjetas más elaboradas como punto de partida. Imágenes propias y genéricas (`car_top.png`, `car_side.png`).
* `LiveProgressStyle.dashed`: lo que falta de la barra, como trazo discontinuo.
* `LiveIsland.check()` valida el diseño y el estado con los mismos avisos que el HTML de prototipos.
* `LiveIslandPreview`: vista previa en Flutter de la isla, la pantalla de bloqueo y la notificación de Android.
* 15 presets listos (`TripPreset`, `DeliveryPreset`, `CourierPreset`…) y app de ejemplo.

Limitaciones conocidas: en Android el grosor, la separación y las etiquetas de la barra los decide el sistema; los botones no se dibujan en la isla expandida de iOS; sin snapshot tests de SwiftUI.
