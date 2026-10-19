# Desviaciones respecto al HTML

Aquí se documenta cada cosa que el HTML dibuja y que iOS o Android no permiten (con captura, motivo y alternativa). Ver `doc/PROMPT.md` §2.1.

Vacío por ahora (Fase 0). Las candidatas que ya se ven desde la lectura:

| Tema | Por qué podría diferir | Alternativa prevista |
| --- | --- | --- |
| Anillo en Android | `ProgressStyle` no tiene anillo | Se muestra como barra (ya lo avisa `check()`) |
| Tracker sin fondo en Android | Depende de `setProgressTrackerIcon` con `Icon.createWithBitmap` | Se confirma en fase 4 con Android 16 |
| Ícono pequeño de Android | El sistema lo pinta en un solo color | `androidSmallIcon` o silueta generada |
| Desenfoque de la tarjeta de bloqueo | En iOS lo decide el sistema | Se usa el fondo del sistema |

## `LiveIsland.check()` frente al panel "Validación" del HTML (Fase 1)

Con el estado y el diseño de los 15 presets, `check()` da los mismos avisos (misma gravedad y mismo texto) que el panel del HTML; lo comprueba `test/check_test.dart` contra `test/fixtures/html_checks.json`. Estas son las diferencias deliberadas:

| Tema | HTML | `check()` | Motivo |
| --- | --- | --- | --- |
| Estado de más de 4 096 bytes | Siempre `ok` | `bad` | El límite de ActivityKit es duro; avisar solo cuando sobra espacio no sirve |
| Aviso de silueta de Android | Se muestra siempre que hay logo, aunque el código generado ya incluya `androidSmallIcon` | Solo si hay logo propio **y no hay** `androidSmallIcon` | `doc/PROMPT.md` §5.1 lo pide solo en los casos 3 y 4. Los tests usan `withSmallIcon: false` para reproducir el caso del HTML |
| Tracker sin barra visible | `warn` | No existe | En Dart el tracker es un parámetro de la barra: no puede haber tracker sin barra |
| Caso que Google no promueve | Campo `androidOk` del preset | Parámetro `androidPromotable` de `check()` (por defecto `true`) | El contrato JSON v1 no lleva ese dato. Si se quiere guardar en el diseño habrá que proponer un campo nuevo en `doc/contract/` |
| Qué se mide como "estado" | Un objeto que incluye `etapa` aunque `renderCode` no lo envía | El estado real que recibe `check()` | Mide lo que de verdad viaja |

## Vista previa de Flutter frente al HTML (Fase 2)

`LiveIslandPreview` dibuja las mismas superficies a partir de un `LiveLayout`. La comparación lado a lado de los 15 presets está en `doc/design/comparaciones/` (se genera con `tool/compare_html.js`). Estructura, jerarquía, tamaños y colores coinciden; estas son las diferencias:

| Tema | HTML | Vista previa | Motivo |
| --- | --- | --- | --- |
| Tipografía | San Francisco en iOS y Roboto en Android | La fuente por defecto de la plataforma (Roboto en las pruebas) | SF Pro no se puede redistribuir. En un iPhone la vista previa usa SF; en las pruebas de golden usa Roboto, que pesa más: algunos textos se recortan antes |
| Anillo en la tarjeta de bloqueo | Anillo de 40 pt con el dato debajo | Anillo de 46 pt a la derecha y el dato en la línea de abajo | Con `lockScreen: sameAsExpanded` la tarjeta reutiliza la zona derecha de la isla expandida; el HTML tiene un diseño propio para ese caso |
| Nombre bajo el dato en la tarjeta de bloqueo | 13 pt | 12 pt | Mismo motivo: reutiliza el 12 pt de la expandida |
| Modo claro | Solo dibuja modo oscuro | `brightness: Brightness.light` aclara la tarjeta `system` y la notificación de Android | Lo pide `doc/PROMPT.md` §9 (goldens en claro y oscuro). La isla sigue negra |
| Desenfoque de la tarjeta de bloqueo | `backdrop-filter` | `BackdropFilter` con el mismo radio | — |
| SF Symbols | Íconos Lucide | Los 49 íconos del HTML se dibujan; un SF Symbol que no esté en esa lista muestra un recuadro, o lo que devuelva `symbolBuilder` | No hay forma de dibujar un SF Symbol arbitrario desde Flutter |
| Tipo de `LiveText` en `compactTrailing` | `compact .trail` fijo | Estilo explícito (`size: 15, weight: 600, accent: true`) | El código generado del HTML ahora lo escribe así (ver abajo) |

### Cambios al HTML (`renderCode`)

Para que la API describa exactamente lo que se ve, el "Código Dart generado" ahora escribe de forma explícita lo que antes quedaba implícito en el dibujo:

- Íconos de la isla con `accent: true`; textos con `size`, `weight` y `lines` (título 15/600 a 2 líneas, subtítulo 13, nombre 12, dato 22/700 en la expandida y 15/600 en la compacta).
- El anillo va en `expanded.trailing` (`LiveProgress.ring(..., size: 46)`) y debajo una línea con el dato y el nombre, como en el prototipo.
- `minimal` usa el avatar o la imagen principal si los hay, igual que el dibujo.
- `bottom` lleva `gap: 12`.

## iOS real frente al HTML (Fase 3)

Verificado en el simulador de iPhone 17 Pro (iOS 26.5) con los casos Taxi, Delivery y Estacionamiento. Los que importan:

| Tema | HTML | iPhone | Motivo |
| --- | --- | --- | --- |
| Botones en la isla expandida | Dos botones debajo | **No se dibujan** | Tocar la isla abre la app, así que los botones no tendrían función. Decisión de Michael. Siguen en la tarjeta de bloqueo y en Android |
| Distribución de la isla expandida | Una fila a todo el ancho: ícono, texto y dato | ActivityKit la reparte en `leading`, `center`, `trailing` y `bottom` y el sistema decide el espacio | Es la API de Apple; el contenido y su orden son los mismos |
| Alto de la isla expandida | ~160 pt | El sistema la limita a 160 pt; sin botones todo cabe | — |
| Ancho de la isla compacta | 236 pt fijos | Lo decide el sistema (~200 pt en iPhone 17 Pro); el contador queda pegado al borde derecho | El contador de SwiftUI ocupaba todo el ancho y alargaba la isla; ahora mide lo que sus dígitos |
| Minimal | Junto a una segunda actividad ficticia | Solo lo muestra iOS cuando hay dos actividades de apps distintas | — |
| Fondo de la tarjeta de bloqueo `system` | Oscuro translúcido | Lo pone el sistema (claro u oscuro según el modo) | `activityBackgroundTint(nil)` |
| Permiso | — | La primera vez iOS pregunta "¿Permitir actividades de <app>?" en la pantalla de bloqueo | Lo muestra el sistema; no se puede evitar |
| Destino mínimo de la app | — | Xcode 27 solo compila para iOS 15.0 o superior; el plugin pide 15.0 | `live_island.podspec` |

## Android real frente al HTML (Fase 4)

Verificado en un emulador Android 17 (API 37, Pixel 10 Pro XL) con Taxi y Courier: `dumpsys notification` marca ambos como `PROMOTED_ONGOING` con `ProgressStyle`, el chip aparece en la barra de estado y el tracker avanza con el valor de progreso (90/200 → 150/200 en el Taxi).

| Tema | HTML | Android | Motivo |
| --- | --- | --- | --- |
| Etiquetas de etapas bajo la barra | Texto bajo cada punto | No existen | `ProgressStyle` solo tiene tramos y puntos. La etapa actual va en `setSubText` ("Asignado", "En camino"…) |
| Chip con cuenta regresiva | "6 min" | Cuenta regresiva en vivo `05:43` | Es el cronómetro del sistema (`setWhen` + `setUsesChronometer` + `setChronometerCountDown`); un texto fijo quedaría desactualizado |
| Chip de texto | ≤7 caracteres completo, 8–12 recortado, más solo ícono | Igual | `LiveSpec.chipFor`, mismo criterio que `check()` |
| Tracker con círculo de acento | Círculo de 26 pt con ícono | El ícono se dibuja tal cual | `setProgressTrackerIcon` no admite fondo. `LiveTracker.background` solo se aplica en iOS |
| Anillo | Anillo | Barra de `ProgressStyle` | No existe en Android (ya lo avisa `check()`) |
| Íconos de la barra y de los botones | SF Symbols / Lucide | PNG indicado en `LiveIcon.symbol(android: ...)` | Android no tiene SF Symbols; el PNG viaja desde Dart. Sin `android:` el ícono se omite |
| Ícono de los botones | Se dibuja junto al texto | Android lo ignora en este estilo | Lo decide el sistema |
| Ícono pequeño | Silueta del logo | `androidSmallIcon`, si no el alfa del `appLogo`, si no el ícono de la app | Android lo pinta en un solo color; un logo opaco se ve como cuadro (`check()` lo avisa) |
| `staleAfter` y `relevance` | — | Se ignoran | Android no tiene equivalente |
| `LiveMetric` | — | No se traduce | `MetricStyle` es de API 37 y aún no está en un SDK estable de compilación |
| Por debajo de Android 16 | — | Notificación en curso con barra estándar, sin chip ni puntos | Sin verificar en emulador (solo hay imagen de API 37) |
| Promoción | — | Se pide con el extra `android.requestPromotedOngoing` | `Notification.Builder#setRequestPromotedOngoing` existe desde el SDK 36.1 y solo escribe ese extra; así el plugin compila con el SDK 36 |
| Permisos | — | `POST_NOTIFICATIONS` (13+, se pide con `LiveIsland.requestPermission()`) y `POST_PROMOTED_NOTIFICATIONS` (normal, se concede al instalar) | El usuario además puede quitar la promoción en Ajustes (`LiveIsland.openPromotionSettings()`) |
| Entrega de los botones a Dart | — | `LiveIsland.onAction`; con la app cerrada la acción queda en una cola en disco y se entrega al reabrir | Android no arranca Flutter desde un `BroadcastReceiver`; no hay motor sin proceso de la app |

## Interacción y push (Fase 5)

| Tema | Comportamiento | Motivo |
| --- | --- | --- |
| Botones en iOS | Solo la tarjeta de bloqueo (iOS 17+, `LiveActivityIntent`). Antes de iOS 17 se dibujan sin acción. La isla expandida no tiene botones | Decisión de Michael (fase 3) |
| Acciones con la app cerrada | Se guardan (App Group en iOS, disco en Android) y se entregan a Dart al empezar a escuchar `onAction`. No se arranca un motor de Flutter sin interfaz | Evita un motor en segundo plano; la lógica de la app corre al abrirla |
| Id de botón | Es el de `LiveButton(id:)`, no identifica la actividad | Con varias actividades hay que usar ids distintos |
| Push en Android | `LiveIsland.handlePush` o `LiveIslandPush.handle` desde tu `FirebaseMessagingService`; formato en `doc/push.md` | El plugin no depende de Firebase |
| Iniciar por push | Solo con un diseño registrado (`registerLayout`) | Un push no lleva el diseño |
| `staleAfter` | Se envía pero Android lo ignora | Android no tiene equivalente |

## Barra de progreso editable (Fase 6)

`LiveProgressStyle` (grosor, color, color del fondo, separación entre tramos, radio, tamaño y color de los puntos, tamaño de etiquetas y del ícono que avanza) se aplica a `LiveProgress.bar`, `LiveProgress.ring` y `LiveSegments`. Además cada parte es opcional: `showLabels`, `points`, `tracker`, `endIcon`. Los presets de etapas (`TripPreset`, `DeliveryPreset`, `CourierPreset`…) lo exponen como parámetros.

| Opción | Vista previa | iOS | Android |
| --- | --- | --- | --- |
| Color de la barra | Sí | Sí | Sí (`color` del tramo) |
| Color de los puntos | Sí | Sí | Sí |
| Grosor, separación, radio | Sí | Sí | **Se ignora**: lo decide `ProgressStyle` |
| Etiquetas de etapa | Sí | Sí | No existen (la etapa va en el subtexto) |
| Tamaño de los puntos | Sí | Sí | **Se ignora** |
| Ícono que avanza y marcador final | Sí, opcionales | Sí, opcionales | Sin tracker ni marcador, no se dibujan |

`pointShape` (círculo, cuadrado, redondeado) se dibuja en la vista previa y en iOS; Android no dibuja puntos propios y lo ignora. `LiveRoute` y `LiveActivity.follow` son solo Dart: el avance viaja como cualquier otro campo del estado.

## Animación de la gota (`LiveIslandMorph`)

Idea y geometría tomadas de `rit3zh/expo-dynamic-notifications` (MIT): tres formas (isla, cuello y gota) se difuminan y un umbral sobre el alfa las funde. Aquí está escrita desde cero con `saveLayer` (desenfoque y `ColorFilter.matrix`). Es solo Dart: no cambia el contrato ni lo que viaja al sistema, y en el dispositivo real la isla la anima el sistema, no el plugin.

## Actividades con id propio

| Tema | iOS | Android |
| --- | --- | --- |
| Dónde vive el `customId` | En los `ActivityAttributes` (opcional; las actividades antiguas o de un push sin él no lo traen) | En el `meta.json` de la actividad |
| `start` con un `customId` vivo | Actualiza el estado (y `staleAfter`) y devuelve el mismo id; **no cambia el diseño** | Igual |
| Push | `attributes.customId` en push-to-start; las actualizaciones van por token (APNs) | `customId` en `start`; `id` acepta el id o el `customId` |
| `endAll` | Termina todas con la política indicada y borra sus diseños si es inmediata | Cancela y borra las notificaciones vivas de la app |

## Avisos (`alert`) y estado desactualizado (`$stale`)

| Tema | iOS | Android |
| --- | --- | --- |
| `LiveAlert` | `AlertConfiguration` (16.2+): la isla se expande, banner y sonido con `title` y `body` | Sonido y aviso emergente del canal `live_island_alerts` (importancia alta). No muestra `title` ni `body`: se ve el contenido de la actividad |
| Sonido propio | `sound: 'x.caf'` del paquete de la app | El del canal; no se cambia por aviso (Android fija el sonido al crear el canal) |
| `LiveBind.stale` | `ActivityViewContext.isStale` (16.2+); lo dispara el sistema al llegar `staleAfter` | **Siempre `false`**: Android no tiene el concepto. Usa `update` para cambiar el estado |
| Push | `alert` del `aps` (documentado en `doc/push.md`) | `"alert": true` en `update` |

## Fin programado (`scheduleEnd`)

| Tema | iOS | Android |
| --- | --- | --- |
| Qué hace | `end(dismissalPolicy: .after(at))`: la actividad **termina ya** y no se puede actualizar | `setTimeoutAfter` sobre la notificación viva: sigue activa y se actualiza hasta `at` |
| Quién la retira | El sistema, a `at` (tope de 4 h después de terminar) | El sistema, a `at`, aunque la app esté cerrada |
| Persistencia | — | La hora se guarda con la actividad: las actualizaciones posteriores conservan el tiempo restante |
| Hora pasada | Termina de inmediato | Termina de inmediato |

## Swift Package Manager

| Tema | Detalle |
| --- | --- |
| Estructura | `ios/live_island/Package.swift` y `ios/live_island/Sources/live_island/` (plugin, `Shared/` y `PrivacyInfo.xcprivacy`). El podspec lee las mismas fuentes |
| Extensión | `Renderer/` y `Widget/` siguen en `ios/LiveIslandExtension/`; `dart run live_island:setup` copia `Shared/` desde las fuentes del plugin |
| `FlutterFramework` | Flutter 3.38+ pide depender de él; el manifiesto lo enlaza solo si existe junto al paquete, así las versiones anteriores no fallan al resolver |
| Frameworks débiles | `ActivityKit` y `AppIntents` se enlazan con `-weak_framework` (como `weak_frameworks` del podspec), por eso hay `unsafeFlags`: es válido en paquetes locales, que es lo que usa Flutter |
| Destino mínimo | iOS 15.0 |

## Diseños de referencia, barra punteada y marcadores

| Tema | Detalle |
| --- | --- |
| Origen | Ideas de tarjetas de recogida de viaje, pedido en tienda, carrera, marcador, bolsa, vuelo y órbita, rehechas con nodos del contrato |
| Marcas e imágenes | Ningún diseño usa marcas ni fotos de terceros. El paquete trae dibujos propios (`car_top.png`, `car_side.png`, `crest_a.png`, `crest_b.png`, generados con `tool/make_design_assets.py`) y los nombres son inventados («Run», «Sprint», «Voltio S.A.»). Quien lo use pasa sus propias imágenes con `LiveImage.asset(...)` |
| Idioma | Los textos de ejemplo están en español y son parámetros o campos del estado; un test impide que se mezclen con inglés |
| Isla y tarjeta | La isla es siempre negra; la tarjeta de bloqueo es propia (`LiveLockScreen.custom`), clara, oscura o de color |
| Barra de recogida | `RideBar.dotted` (trazo punteado y marcadores) o `RideBar.line` (línea continua y marcador final) |
| `dashed` | iOS y vista previa dibujan lo que falta como trazo discontinuo. Android lo ignora: `ProgressStyle` usa tramos sólidos |
| `markers` | Posiciones 0 a 1 de marcadores sobre la barra, con la forma de `pointShape` (`ring` es un círculo suave con un punto). El ya recorrido y el siguiente van de color; los demás, apagados. Android los ignora |
| Un tamaño por superficie | `LiveImage.withSize(n)` usa la misma imagen grande en la tarjeta y pequeña en la isla compacta |
| Imágenes anchas | Toda imagen se dibuja en un cuadrado de `size`. Para una imagen ancha sin fondo (un conductor con su auto) usa `LiveImage.withHeight(n)` o `fixedHeight`: alto fijo y ancho según su proporción, sin cuadrado vacío |
| Altura de la tarjeta de bloqueo | iOS limita la tarjeta a unos 160 pt con el relleno del sistema, así que cada diseño tiene unos 125 pt útiles; lo que sobre se recorta. Los diseños de ejemplo están medidos para caber |
| Cable luminoso | `LiveProgressStyle.glow`: halo del color de lo avanzado. Android lo ignora. En las pruebas de Flutter (`flutter test`) las sombras no se dibujan, así que los goldens no muestran el brillo; en la app y en iOS sí |
| Borde con brillo | `LiveBox(border:, borderWidth:, glow:)`. El halo va solo en el fondo de la caja, no difumina el texto de dentro |
| Tramos de color | `LiveSplitBar` (JSON `split`): tramos de distinto color repartidos en proporción a valores del estado (tarifa, servicio y propina). Android la omite |
| Cursiva | `LiveText(italic: true)` (JSON `i`) |

## Gráficas: línea, arco y ruta curva

| Nodo | Dart | JSON | Android |
| --- | --- | --- | --- |
| Gráfica de línea | `LiveSparkline` | `spark` | Se omite |
| Medidor de arco | `LiveGauge` | `gauge` | Barra de progreso |
| Ruta curva con ícono | `LiveFlightPath` | `path` | Barra con el mismo ícono |

* La serie de la gráfica viaja como texto de números separados por comas (`liveSeries([1, 2.5])` → `"1,2.5"`), así el estado sigue siendo de tipos simples.
* El avión de `LiveFlightPath` no gira siguiendo la curva: queda horizontal.
* Presets de ejemplo: `StockPreset`, `FlightPathPreset` y `OrbitPreset`.
