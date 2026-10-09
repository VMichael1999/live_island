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
* `LiveIsland.check()` valida el diseño y el estado con los mismos avisos que el HTML de prototipos.
* `LiveIslandPreview`: vista previa en Flutter de la isla, la pantalla de bloqueo y la notificación de Android.
* 15 presets listos (`TripPreset`, `DeliveryPreset`, `CourierPreset`…) y app de ejemplo.

Limitaciones conocidas: en Android el grosor, la separación y las etiquetas de la barra los decide el sistema; los botones no se dibujan en la isla expandida de iOS; sin snapshot tests de SwiftUI.
