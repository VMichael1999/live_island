# Prompt para Claude Code: paquete Flutter `live_island`

> Copia todo este archivo como primer mensaje en Claude Code, dentro de la carpeta del repositorio del paquete.
> Antes, coloca el archivo `live_island_prototipos.html` en `docs/design/` del repositorio.

---

## 1. Tu rol y el objetivo

Eres el desarrollador principal de **`live_island`**, un paquete de Flutter publicado en pub.dev que muestra actividades en vivo:

- En **iOS**: Live Activities en la Dynamic Island (compact, minimal y expandida), en la pantalla de bloqueo, en StandBy, en el Apple Watch y en CarPlay.
- En **Android**: notificaciones en curso que, en Android 16 o superior, el sistema **promueve a Live Update** (chip en la barra de estado, arriba del panel y en la pantalla de bloqueo).

Todo se controla con **una sola API en Dart**. La idea central es que el paquete sea **100 % editable**: el desarrollador que lo use define sus propios datos y su propio diseño (textos, colores, íconos, barra de progreso, ícono que avanza sobre la barra, etapas, botones, chip de Android) **sin escribir Swift ni Kotlin**.

Vamos a trabajar **en paralelo**: yo (Michael) reviso, pruebo en equipos reales y trabajo en algunas ramas; tú implementas por fases y te detienes en cada punto de control para que revise.

**Esto es un paquete de Flutter.** Se publica en pub.dev, se instala con `flutter pub add live_island` y quien lo usa **solo escribe Dart**. El Swift y el Kotlin existen únicamente **dentro del plugin**, porque Apple obliga a que la isla sea SwiftUI en un Widget Extension y Android obliga a construir la notificación con su API nativa. El desarrollador nunca abre esos archivos; el comando `dart run live_island:setup` agrega lo necesario al proyecto.

## 2. Documentos de referencia

- **`docs/investigacion.md`**: la investigación técnica (qué permiten iOS y Android, límites, competencia, catálogo de casos de uso y fuentes). Léela completa antes de empezar, para entender el **porqué** de cada decisión.
- **`docs/design/live_island_prototipos.html`**: la referencia visual y de comportamiento (sección siguiente).
- **Este prompt**: la especificación final.

**Si hay contradicciones**, manda este orden: 1) este prompt, 2) el HTML, 3) la investigación. La investigación se escribió antes de algunas decisiones finales; por ejemplo, ahí aparecen nombres como `TripTemplate` que ahora son `TripPreset`, y una fase de React Native que por ahora queda fuera del alcance.

## 2.1 Fuente de verdad visual: el HTML de prototipos

El archivo **`docs/design/live_island_prototipos.html`** es la referencia visual y funcional. Trátalo como si fuera **feedback de diseño detallado**: cada cosa que se ve ahí es un requisito.

**Antes de escribir código:**

1. Abre el HTML en un navegador (usa Playwright o Chromium headless) y toma capturas de: el editor en vivo con cada uno de los 15 ejemplos de la galería, y las secciones "Qué es editable", "Medidas", "Componentes" y "Reglas de fidelidad".
2. Lee el `<script>` del HTML: las funciones `compactHTML`, `minimalHTML`, `expandedHTML`, `lockCardHTML`, `androidHTML`, `progress`, `chipInfo`, `renderChecks` y `renderCode` describen exactamente qué va en cada región, en qué orden, con qué tamaño y con qué color. El arreglo `PRESETS` tiene los datos de los 15 ejemplos.
3. Escribe en `docs/design/LECTURA_DEL_HTML.md` un resumen de lo que entendiste por cada superficie (qué elemento, dónde, tamaño, color). Ese resumen es tu checklist de fidelidad.

**Reglas de fidelidad (obligatorias):**

- **Estructura idéntica por superficie.** Qué va a la izquierda y qué a la derecha, qué texto es más grande, qué se recorta con elipsis. Ejemplo: en la isla compacta, a la izquierda va el ícono (o avatar) en color de acento y a la derecha el dato destacado en 15 pt semibold con cifras tabulares, en color de acento.
- **Medidas** según la tabla "Medidas de cada superficie": compact ~44 pt por lado, minimal 37 × 37 pt, expandida con esquinas de 44 pt y relleno de 16–20 pt, tarjeta de bloqueo con esquinas de 22 pt, ícono de app de 40 pt con radio 11, barra de 6 pt de alto con 4 pt de separación entre tramos, tracker de 26 pt, chip de Android de 24 dp de alto y 96 dp como máximo.
- **Uso del color de acento** exactamente como en el HTML: ícono compacto, dato destacado, relleno de la barra, puntos completados, círculo del tracker, botón principal y chip de Android. El botón secundario usa blanco al 14 % sobre fondo oscuro.
- **Fondo de la tarjeta de bloqueo**: tres modos (`system` oscuro translúcido, `light` claro translúcido, `accent` color sólido con texto blanco y el primer botón invertido en blanco).
- **Ícono que avanza (tracker)**: puede ser un ícono dentro de un círculo de color de acento, o una **imagen propia** (por ejemplo, la foto o ilustración de un auto) sin fondo o con el círculo. Va centrado sobre la posición del avance y se mueve cuando cambia el progreso. En iOS y en Android (`setProgressTrackerIcon` con `Icon.createWithBitmap`). Debe comportarse como el botón "Simular recorrido" del HTML; el preset de Taxi trae la imagen del auto para probarlo.
- **Imágenes propias en cualquier ranura**: revisa el grupo "Logo e imágenes" del editor. Ver la sección 5.1.
- **Etiquetas de etapas**: con 3 etapas o menos, cada etiqueta va en su posición sobre la barra (la primera alineada a la izquierda, la última a la derecha) y la etapa actual en negrita. Con más de 3 etapas se muestra una sola línea: la etapa actual en negrita a la izquierda y "Paso k de n" a la derecha.
- **Anillo** (`LiveProgress.ring`): en minimal va el anillo con el ícono dentro; en la expandida y en el bloqueo va a la derecha. En Android se muestra como barra.
- **Chip de Android**: 7 caracteres o menos se ve completo; de 8 a 12 se recorta a 6 caracteres más "…"; más de 12 o vacío, solo ícono. En modo cuenta regresiva muestra los minutos ("6 min").
- **Validación**: los mismos avisos del panel "Validación" del HTML deben salir en `LiveIsland.check()`, con el mismo criterio y textos equivalentes.
- **Forma de la API**: el "Código Dart generado" del HTML es la forma esperada de la API pública. Si necesitas cambiar un nombre, **primero actualiza el HTML** (`renderCode`) y después el código, y avísame.
- Si el sistema operativo impide algo que el HTML muestra, no lo inventes: documenta la diferencia en `docs/design/DESVIACIONES.md` con captura, motivo y alternativa.

## 3. Alcance

**Entra:**

- Plugin Flutter para iOS 16.1+ y Android API 26+ (Live Update en API 36+, `MetricStyle` en API 37+ con guarda de versión).
- Núcleo en Dart con modelo de datos libre, componentes de diseño, bindings, validación y serialización.
- Renderer SwiftUI genérico dentro de un Widget Extension que el desarrollador **no** tiene que editar.
- Traductor Kotlin del modelo a estilos nativos de notificación (no `RemoteViews` para la notificación promovida).
- Comando de configuración `dart run live_island:setup`.
- Push: tokens de actualización y push-to-start en iOS (17.2+); en Android, un handler de FCM que recibe el mismo formato de datos.
- Ejemplos listos (presets) construidos con el núcleo, uno por cada caso de la galería del HTML.
- Widget de vista previa en Flutter (`LiveIslandPreview`) que dibuja las superficies igual que el HTML, para probar sin compilar el extension.
- App de ejemplo y documentación.

**No entra:** reproducción de música (el sistema ya usa Now Playing y `MediaSession`) y llamadas (CallKit y `CallStyle`). No dibujar widgets arbitrarios de Flutter en la isla: no es posible, solo los componentes del paquete.

## 4. Arquitectura

```
Tu app Flutter (LiveLayout + estado)
        │
Núcleo Dart (lib/src/core): modelos, bindings, validación, JSON
        │  mismo modelo
 ┌──────┴────────────────────────┐
Puente iOS (Swift)              Puente Android (Kotlin)
ActivityKit, App Group, APNs    Traduce a Notification.Builder
        │                                │
Widget Extension:               ProgressStyle / MetricStyle / estándar
renderer SwiftUI lee el JSON    + chip, acciones, cronómetro
        │                                │
Dynamic Island, bloqueo,        Live Update promovida
StandBy, Watch, CarPlay         (chip, panel, bloqueo, always-on)
```

**Regla clave:** el **diseño** (layout) viaja una vez al iniciar la actividad y se guarda en el App Group (iOS) o en memoria del servicio (Android). En cada actualización solo viaja el **estado** (los datos), para quedarse bajo los 4 KB de iOS.

### Contrato JSON (defínelo primero, en `docs/contract/`)

Antes de separar el trabajo de iOS y Android, crea `docs/contract/layout.schema.json` y `docs/contract/state.schema.json` con ejemplos. Los tres equipos (Dart, Swift, Kotlin) leen el mismo contrato. Forma orientativa:

```json
{
  "v": 1,
  "theme": { "accent": "#1F6FEB", "background": "system" },
  "regions": {
    "compactLeading":  { "t": "avatar", "text": "CM" },
    "compactTrailing": { "t": "countdown", "bind": "llegaA" },
    "minimal":         { "t": "icon", "sf": "car.fill", "asset": "car.png" },
    "expanded": {
      "leading":  { "t": "box", "size": 46, "radius": 14, "tint": 0.22, "child": { "t": "icon", "sf": "car.fill" } },
      "center":   { "t": "col", "c": [ { "t": "text", "bind": "titulo", "w": 600 }, { "t": "text", "bind": "subtitulo", "muted": true } ] },
      "trailing": { "t": "col", "align": "end", "c": [ { "t": "countdown", "bind": "llegaA", "size": 22, "w": 700, "accent": true }, { "t": "text", "bind": "nombre", "muted": true } ] },
      "bottom":   { "t": "col", "c": [
        { "t": "segments", "bind": "progreso", "labels": ["Asignado", "En camino", "Llegó"], "points": true,
          "tracker": { "sf": "car.fill", "asset": "car.png" }, "end": { "sf": "mappin" } },
        { "t": "row", "c": [ { "t": "button", "id": "llamar", "label": "Llamar", "icon": { "sf": "phone.fill" } } ] }
      ] }
    },
    "lockScreen": { "same": "expanded" }
  },
  "android": { "title": { "bind": "titulo" }, "text": { "fmt": "{subtitulo} · {nombre}" },
               "chip": { "t": "countdown", "bind": "llegaA" }, "colorized": false }
}
```

Estado de ejemplo (lo único que viaja en cada actualización):

```json
{ "titulo": "Tu conductor está en camino", "subtitulo": "Toyota Yaris gris · ABC-123",
  "nombre": "Carlos M.", "llegaA": "2026-10-04T15:06:00Z", "progreso": 0.45 }
```

## 5. API pública esperada (Dart)

Debe coincidir con el código que genera el HTML. Resumen:

```dart
// Ciclo de vida
final act = await LiveIsland.start(layout: diseno, state: estado, deepLink: 'miapp://viaje/1');
await act.update({'progreso': 0.8});
await act.end(dismiss: LiveDismiss.after(const Duration(minutes: 5)));
LiveIsland.onAction((id) { ... });
final report = LiveIsland.check(diseno, estado); // misma lógica que el panel "Validación"
final enabled = await LiveIsland.areEnabled();    // iOS: areActivitiesEnabled · Android: canPostPromotedNotifications
await LiveIsland.openPromotionSettings();          // Android 16+

// Diseño
LiveLayout(theme:, compactLeading:, compactTrailing:, minimal:, expanded: LiveExpanded(leading:, center:, trailing:, bottom:), lockScreen:, android: LiveAndroid(title:, text:, chip:, colorized:))
LiveTheme(accent: Color, background: LiveBackground.system | .light | .accent)
LiveLockScreen.sameAsExpanded()

// Componentes
LiveRow, LiveColumn, LiveStack, LiveSpacer, LivePadding, LiveBox, LiveIf
LiveText(bind('x'), size:, weight:, muted:, accent:), LiveText.format('{a} · {b}'), LiveText.countdown(...), LiveText.stopwatch(...), LiveText.relative(...)
LiveIcon.symbol('car.fill', android: 'assets/live/car.png'), LiveImage.asset/.network/.memory, LiveAvatar('CM')
LiveProgress.bar(value:, tracker:, startIcon:, endIcon:), LiveProgress.ring(value:, child:), LiveSegments(value:, labels:, points:, tracker:, startIcon:, endIcon:)
LiveMetric(value:, unit:, label:)
LiveButton(id:, label:, icon:), LiveToggle(...), LiveAction.deepLink/.call/.custom
LiveChip.countdown(bind('x')) | .text('B-027') | .icon()

// Datos
bind('campo'), y en LiveIf: bind('etapa').equals(2)
```

### 5.1 Íconos e imágenes: todo es editable

Regla: **toda ranura donde va un ícono acepta también una imagen propia**. El desarrollador decide qué pone: el logo de su app, el logo de un cliente (apps multi-cliente o white label), la foto del conductor, la ilustración de un auto, o un ícono del sistema. No hay ningún ícono fijo en el código nativo.

```dart
// Tipo común para cualquier ranura visual
sealed class LiveVisual {}
LiveIcon.symbol('car.fill', android: 'assets/live/car.png')   // ícono del sistema
LiveImage.asset('assets/logo.png', fit: LiveFit.cover, shape: LiveShape.rounded)
LiveImage.network(url, fit: LiveFit.contain)
LiveImage.file(File(...)) / LiveImage.memory(bytes)
LiveAvatar('CM') / LiveImage.network(fotoUrl, shape: LiveShape.circle)

// Ranuras que aceptan LiveVisual
LiveLayout(
  appLogo: LiveImage.asset('assets/logo_cliente.png'),          // tarjeta de bloqueo + ícono grande en Android
  androidSmallIcon: LiveImage.asset('assets/logo_silueta.png'), // opcional: silueta para la barra de estado
  compactLeading: LiveImage.asset('assets/logo.png'),
  ...
)
LiveSegments(tracker: LiveTracker(LiveImage.asset('assets/auto.png'), height: 24, background: LiveTrackerBackground.none))
LiveButton(id: 'llamar', label: 'Llamar', icon: LiveImage.asset('assets/tel.png'))
```

Requisitos:

- **Respetar la proporción.** Nunca deformar. `fit: contain` (no recorta) o `cover` (rellena y recorta), y `shape: rounded | circle | square`. El tracker con imagen mantiene su relación de aspecto (alto fijo, ancho automático, como el auto de 2:1 del HTML).
- **Reducir antes de copiar.** El plugin redimensiona cada imagen al tamaño en que se muestra × 3 (logo 120 px, ícono y avatar 138 px, tracker 72 px de alto) antes de copiarla al App Group. El Widget Extension tiene poca memoria (~30 MB) y no debe decodificar imágenes grandes. Las imágenes de red las descarga la app, nunca el extension.
- **Por cliente.** El logo y los colores pueden cambiar en cada `start()`, para que una misma app sirva a varios clientes o flavors.
- **Android funciona distinto a iOS, y debe quedar así:**
    - **Ícono pequeño** (barra de estado, chip y encabezado): el sistema lo pinta como **silueta de un color**, nunca a color. Orden para elegirlo: 1) `androidSmallIcon` si el desarrollador lo pasa; 2) el ícono de notificación de la app que configure `setup` (por ejemplo `@drawable/ic_stat_live_island`); 3) una silueta generada desde el canal alfa del `appLogo`; 4) como último recurso, el ícono del launcher de la app. En los casos 3 y 4, `check()` avisa que conviene una silueta propia (un logo cuadrado y opaco se ve como un cuadrado blanco).
    - **Ícono grande** (`setLargeIcon`, a color, a la derecha del texto): la foto del avatar si está activo; si no, el `appLogo`; si no, la imagen del ícono principal.
    - **Isla compacta y minimal**: no existen en Android. La imagen del ícono principal solo llega a Android como ícono grande.
    - **Tracker e íconos de inicio y fin** de `ProgressStyle`: sí se muestran a color y con la imagen que el desarrollador quiera.
    - El HTML ya dibuja exactamente este comportamiento en la tarjeta de Android: úsalo como referencia.
- **Validación:** `check()` informa el peso de cada imagen y a qué tamaño se reducirá, igual que el panel del HTML.

Presets: `TripPreset`, `DeliveryPreset`, `CourierPreset`, `PickupPreset`, `QueuePreset`, `FlightPreset`, `ParkingPreset`, `EvChargingPreset`, `WorkoutPreset`, `CookingTimerPreset`, `UploadPreset`, `TechnicianPreset`, `TransitPreset`, `WaitingRoomPreset`, `ScorePreset`. Cada preset devuelve un `LiveLayout` normal y acepta `.override(region: ...)` para reemplazar cualquier parte.

## 6. Detalles técnicos por plataforma

**iOS**

- `ActivityAttributes` genérico con el layout como `String` JSON en los atributos estáticos y el estado como diccionario en `ContentState` (codificado con tipos simples).
- Renderer recursivo en SwiftUI que interpreta el JSON. Cuentas regresivas con `Text(timerInterval:)` para que corran solas.
- Imágenes: copiarlas al App Group y reducirlas al tamaño de visualización; el extension tiene ~30 MB de memoria.
- Botones con `LiveActivityIntent` (iOS 17+) que reenvían el `id` a Dart.
- `staleDate`, `relevanceScore` y `dismissalPolicy` expuestos en Dart.
- Soporte de `isDynamicIslandLimitedInWidth`, `activityFamily == .small` (Watch y CarPlay) y `showsWidgetContainerBackground` (StandBy).
- Tokens de push por actividad y push-to-start con `Stream` en Dart.

**Android**

- Construir la notificación con estilos nativos: `ProgressStyle` (segmentos, puntos, tracker, íconos de inicio y fin), estándar o `BigTextStyle`, y `MetricStyle` con guarda de API 37.
- Para promover: `POST_PROMOTED_NOTIFICATIONS`, `setRequestPromotedOngoing(true)`, `setOngoing(true)`, título obligatorio, sin `RemoteViews`, sin `setColorized(true)` y canal con importancia mayor que mínima.
- Chip: `setShortCriticalText` o cuenta regresiva con `setWhen` + `setUsesChronometer` + `setChronometerCountDown`.
- Por debajo de API 36: notificación en curso con `NotificationCompat` y barra de progreso estándar, sin chip.
- `setDeleteIntent` para detectar que el usuario la cerró y no volver a publicarla.
- Advertir en `check()` los casos que Google no permite (publicidad, chats, actividades que no inició el usuario).

## 7. Estructura del repositorio

```
live_island/
  lib/
    live_island.dart
    src/core/        (modelos, bindings, JSON, validación)
    src/components/  (LiveText, LiveProgress, ...)
    src/presets/
    src/preview/     (LiveIslandPreview, réplica del HTML en Flutter)
    src/platform/    (method channels)
  ios/Classes/                  (plugin)
  ios/LiveIslandExtension/      (plantilla del Widget Extension + renderer)
  android/src/main/kotlin/...   (plugin + traductor de estilos)
  bin/setup.dart                (dart run live_island:setup)
  example/                      (una pantalla por preset + editor parecido al HTML)
  docs/design/live_island_prototipos.html
  docs/design/LECTURA_DEL_HTML.md
  docs/design/DESVIACIONES.md
  docs/contract/*.schema.json
  test/
```

## 8. Plan por fases y puntos de control

Trabaja en una rama por fase o por área. Al terminar cada fase **detente**, muéstrame capturas lado a lado (HTML vs. implementación) y espera mi visto bueno.

| Fase | Entregable | Criterio de aceptación |
| --- | --- | --- |
| 0. Lectura | `LECTURA_DEL_HTML.md`, capturas del HTML, contrato JSON | Yo apruebo el contrato antes de seguir |
| 1. Núcleo Dart | Modelos, componentes, `bind`, JSON, `check()` con tests | Tests de serialización; `check()` da los mismos avisos que el HTML para los 15 presets |
| 2. Vista previa Flutter | `LiveIslandPreview` + golden tests | Las goldens de los 15 presets se ven como la galería del HTML |
| 3. iOS | Plugin, extension, renderer, setup | Taxi, Delivery y Estacionamiento en simulador iguales al HTML en compact, minimal, expandida y bloqueo |
| 4. Android | Traductor a estilos nativos, chip, acciones | Taxi y Courier promovidos a Live Update en un Pixel o emulador con Android 16; tracker moviéndose |
| 5. Interacción y push | Botones con callback, APNs, push-to-start, FCM | Un botón cambia el estado desde la isla y desde Android; actualización por push en ambos |
| 6. Presets y ejemplo | 15 presets, app de ejemplo, README con GIFs | Cada preset coincide con su tarjeta de la galería |
| 7. Publicación | `pana` sin avisos, CHANGELOG, versión 0.1.0 | Puntuación máxima posible en pana |

**Trabajo en paralelo:** después de la fase 0 se pueden abrir a la vez `feat/core-dart`, `feat/ios` y `feat/android`, porque las tres partes dependen solo del contrato JSON. Si el contrato tiene que cambiar, se cambia en `docs/contract/` en un PR aparte y se avisa.

## 9. Pruebas

- Unitarias de Dart: serialización, bindings, `LiveIf`, tamaño del estado (< 4 096 bytes) y todas las reglas de `check()`.
- Golden tests de `LiveIslandPreview` para cada preset, en claro y oscuro.
- iOS: snapshot tests del renderer SwiftUI con los JSON de los presets.
- Android: tests del traductor (qué estilo, qué flags, si es promovible) y prueba manual en un equipo con Android 16.
- Comparación visual: script en `tool/compare.dart` o Playwright que captura el HTML con el mismo preset y lo pone al lado de la captura de la implementación.

## 10. Definición de terminado

- Ninguna propiedad visible está fija en Swift o Kotlin; todo lo de la tabla "Qué es editable" del HTML se controla desde Dart.
- Cualquier ranura de ícono acepta una imagen propia (logo de la app o del cliente, foto, ilustración) y la muestra con su proporción correcta en iOS y Android.
- Las capturas de cada superficie coinciden con el HTML en estructura, jerarquía, tamaños y colores; las diferencias inevitables están en `DESVIACIONES.md`.
- `check()` reproduce el panel "Validación".
- README en español e inglés, con ejemplos de los niveles: preset, preset con `.override` y `LiveLayout` desde cero.

## 11. Cómo trabajar conmigo

- Escribe en español.
- Antes de cada fase, dime en pocas líneas qué vas a hacer y qué archivos vas a tocar.
- Si algo del HTML no es posible en iOS o Android, no lo cambies por tu cuenta: avísame con la razón y una alternativa.
- Si cambias la API, actualiza primero `renderCode` en el HTML para que la referencia y el código no se separen.
- No publiques en pub.dev ni hagas push a `main` sin mi confirmación.
