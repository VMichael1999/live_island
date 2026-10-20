## Sin publicar

* iOS: la zona derecha de la isla expandida lleva 4 pt de margen, para que la curva de la isla no recorte el «78'» del marcador deportivo.
* iOS: en la isla expandida, un texto de una línea se encoge hasta un 65 % antes de cortarse con «…» (Transporte público, Sala de espera y Subida de archivo ya no pierden «3 paradas», «Te llaman pronto» ni «3 min restantes»).
* iOS: se corrige un cierre de la app al iniciar una actividad (carrera de datos al vigilar los tokens de push de ActivityKit).
* Diseños nuevos de «Run»: `RideArrivalPreset` (llegada, con un sedán y su placa), `RideTripPreset` (viaje con fase, destino y pago) y `DeliveryOrderPreset` (pedido a domicilio en cuatro etapas con íconos).
* Barra: `LiveProgressStyle.endMarker` pega un aro o un cuadrado al final de la barra, con el auto encima, y `LiveSegments.stageIcons` pone un ícono por etapa (gris hasta que llega y de color después).
* Tarjeta de bloqueo: si la raíz es una caja con color opaco, ese color es el fondo de toda la tarjeta (un solo contenedor) en iOS y en la vista previa.
* La vista previa corta con «…» el texto largo junto a un espaciador, como SwiftUI.
* Android: todos los diseños de ejemplo usan la tarjeta (`LiveAndroidStyle.card`) por defecto, así que Android dibuja el mismo diseño que iOS desde el mismo JSON. Con `androidStyle: LiveAndroidStyle.liveUpdate` se vuelve a la plantilla nativa (y a la promoción a Live Update).
* Se quita `RideDriverPreset` (viaje visto por el conductor): los diseños nuevos lo reemplazan.

## 0.1.1

* Sin avisos del analizador en Flutter 3.47 (imports de `dart:ui` marcados como innecesarios).
* El repositorio pasa a llamarse `live_island_kit`: se actualizan `repository`, `issue_tracker` y los enlaces de las imágenes del README.

## 0.1.0

Primera versión publicada.

* API única en Dart (`LiveIsland.start/update/end`) para Live Activities de iOS y Live Updates de Android 16+.
* Contrato JSON v1 (diseño una vez, estado ≤ 4 096 bytes) compartido por Dart, Swift y Kotlin.
* iOS: Widget Extension genérico en SwiftUI (isla compacta, expandida y mínima, pantalla de bloqueo, StandBy), botones con `LiveActivityIntent` (iOS 17+), push tokens y push-to-start (iOS 17.2).
* Android: `Notification.ProgressStyle`, chip, promoción a Live Update, botones, cola de acciones y entrada de push FCM.
* `dart run live_island_kit:setup` configura el proyecto de Xcode (`--push` para APNs).
* Componentes: texto, contadores, íconos e imágenes, avatar, barra, anillo, etapas, tracker, botones.
* Barra de progreso editable: color, grosor, puntos, etiquetas, ícono que avanza y marcador final (`LiveProgressStyle`).
* Puntos de etapa a gusto: cantidad, con o sin texto, y forma (`LivePointShape`: círculo, cuadrado, redondeado).
* Barra en vivo: `LiveRoute` convierte la posición en avance y `LiveActivity.follow` mantiene la actividad al día con un `Stream`, espaciando las actualizaciones.
* `LiveIslandMorph`: la isla suelta una gota que se abre en tarjeta (vista previa y aviso dentro de la app), con descarte por gesto.
* iOS: manifiesto de privacidad que declara el uso de `UserDefaults` del App Group (motivo `1C8F.1`), empaquetado con el plugin y copiado a la extensión por `dart run live_island_kit:setup`; el podspec toma la versión del paquete.
* Actividades con id propio: `start(customId:)` crea o actualiza, `LiveIsland.activity(customId)` las encuentra tras reabrir la app, `LiveIsland.endAll()` las termina y `activeActivities()` trae su `customId`. Los push de Android aceptan `customId` en `start` y como `id` en `update`/`end`.
* Avisos: `update(alert: LiveAlert(...))` expande la isla y suena en iOS; en Android usa un canal con sonido y sale como emergente. El push de Android acepta `"alert": true`.
* Estado desactualizado: `LiveBind.stale` (campo reservado `$stale`) cambia el diseño al pasar `staleAfter` sin push (iOS 16.2+).
* Ejemplo: iniciar un caso termina el anterior y usa `relevance: 100`, para que la isla muestre siempre el que se acaba de iniciar (iOS solo muestra una actividad en la isla).
* Fin programado: `LiveActivity.scheduleEnd(at)` y `LiveDismiss.at(DateTime)`. En Android la notificación sigue viva y el sistema la retira a esa hora; en iOS termina ya y la tarjeta se queda hasta esa hora.
* iOS: soporte de Swift Package Manager (`ios/live_island_kit/Package.swift`), además de CocoaPods; ambos usan las mismas fuentes. Probado con Flutter 3.29, 3.41 y 3.47.
* Diseños de referencia con nombres e imágenes propios, en español: `RidePickupPreset` (clara y oscura, barra `RideBar.dotted` o `RideBar.line`), `RideDriverPreset` (vista del conductor), `StorePickupPreset`, `RunPreset`, `MatchPreset`, y una línea de tren hecha con `TransitPreset`.
* `LiveProgressStyle.dashed` (lo que falta, como trazo discontinuo), `LiveProgressStyle.markers` (marcadores sobre la barra), `LivePointShape.ring`, `LiveImage.withSize` y `LiveImage.withHeight` (alto fijo para imágenes anchas).
* `LiveIsland.check()` valida el diseño y el estado con los mismos avisos que el HTML de prototipos.
* `LiveIslandPreview`: vista previa en Flutter de la isla, la pantalla de bloqueo y la notificación de Android.
* 15 presets listos (`TripPreset`, `DeliveryPreset`, `CourierPreset`…) y app de ejemplo.
* Android: modo tarjeta (`LiveAndroidStyle.card`): tu diseño completo con `RemoteViews` (dos escudos, marcador grande, gráfica), sin chip ni Live Update; `MatchPreset` y `StockPreset` lo usan por defecto.
* Android: `LiveAndroid(largeIcon, subText)`, barra partida como tramos de color y marcadores como puntos de `ProgressStyle`; los diseños de ejemplo ponen su imagen, subtexto y textos propios.
* Efectos: `LiveProgressStyle.glow` (cable luminoso), `LiveBox(border, borderWidth, glow)` (borde con brillo), `LiveSplitBar` (tramos de color en proporción) y `LiveText(italic: true)`; con `ChargePreset` y `FareSplitPreset`.
* Gráficas: `LiveSparkline` (línea con área y punto final), `LiveGauge` (arco con punto que avanza) y `LiveFlightPath` (ruta curva con ícono que avanza); con `StockPreset`, `FlightPathPreset` y `OrbitPreset`. En Android el arco y la ruta son una barra y la línea se omite.

Limitaciones conocidas: en Android el grosor, la separación y las etiquetas de la barra los decide el sistema; los botones no se dibujan en la isla expandida de iOS; sin snapshot tests de SwiftUI.
