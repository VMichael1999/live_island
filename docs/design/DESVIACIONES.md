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
