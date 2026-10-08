# Desviaciones respecto al HTML

Aquí se documenta cada cosa que el HTML dibuja y que iOS o Android no permiten (con captura, motivo y alternativa). Ver `docs/PROMPT.md` §2.1.

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
| Aviso de silueta de Android | Se muestra siempre que hay logo, aunque el código generado ya incluya `androidSmallIcon` | Solo si hay logo propio **y no hay** `androidSmallIcon` | `docs/PROMPT.md` §5.1 lo pide solo en los casos 3 y 4. Los tests usan `withSmallIcon: false` para reproducir el caso del HTML |
| Tracker sin barra visible | `warn` | No existe | En Dart el tracker es un parámetro de la barra: no puede haber tracker sin barra |
| Caso que Google no promueve | Campo `androidOk` del preset | Parámetro `androidPromotable` de `check()` (por defecto `true`) | El contrato JSON v1 no lleva ese dato. Si se quiere guardar en el diseño habrá que proponer un campo nuevo en `docs/contract/` |
| Qué se mide como "estado" | Un objeto que incluye `etapa` aunque `renderCode` no lo envía | El estado real que recibe `check()` | Mide lo que de verdad viaja |

## Vista previa de Flutter frente al HTML (Fase 2)

`LiveIslandPreview` dibuja las mismas superficies a partir de un `LiveLayout`. La comparación lado a lado de los 15 presets está en `docs/design/comparaciones/` (se genera con `tool/compare_html.js`). Estructura, jerarquía, tamaños y colores coinciden; estas son las diferencias:

| Tema | HTML | Vista previa | Motivo |
| --- | --- | --- | --- |
| Tipografía | San Francisco en iOS y Roboto en Android | La fuente por defecto de la plataforma (Roboto en las pruebas) | SF Pro no se puede redistribuir. En un iPhone la vista previa usa SF; en las pruebas de golden usa Roboto, que pesa más: algunos textos se recortan antes |
| Anillo en la tarjeta de bloqueo | Anillo de 40 pt con el dato debajo | Anillo de 46 pt a la derecha y el dato en la línea de abajo | Con `lockScreen: sameAsExpanded` la tarjeta reutiliza la zona derecha de la isla expandida; el HTML tiene un diseño propio para ese caso |
| Nombre bajo el dato en la tarjeta de bloqueo | 13 pt | 12 pt | Mismo motivo: reutiliza el 12 pt de la expandida |
| Modo claro | Solo dibuja modo oscuro | `brightness: Brightness.light` aclara la tarjeta `system` y la notificación de Android | Lo pide `docs/PROMPT.md` §9 (goldens en claro y oscuro). La isla sigue negra |
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
| Entrega de los botones a Dart | — | Los botones envían su `id` por un `EventChannel` (`live_island/actions`) | El callback de Dart (`LiveIsland.onAction`) llega en la Fase 5 |
