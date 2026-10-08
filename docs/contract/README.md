# Contrato JSON (v1)

Lo leen por igual el núcleo Dart (que lo escribe), el renderer SwiftUI y el traductor Kotlin (que lo leen). Si cambia, se cambia aquí, en un PR aparte, y se avisa.

| Archivo | Qué es | Cuándo viaja |
| --- | --- | --- |
| `layout.schema.json` | Diseño: tema, regiones, nodos, bloque Android, manifiesto de imágenes | Una vez, en `LiveIsland.start()` |
| `state.schema.json` | Datos: mapa plano de tipos simples, ≤ 4 096 bytes | En cada `update()` y en cada push |
| `examples/` | `taxi` (completo, con imagen de auto) y `score` (sin progreso, sin Live Update) | — |

Se validan con JSON Schema 2020-12 (probado con `ajv`).

## Decisiones de diseño

1. **Una región = un árbol de nodos.** Cada nodo es un objeto con `t` (tipo). `row`, `col`, `stack`, `box`, `padding` y `if` contienen otros nodos; el resto son hojas.
2. **Enlace por nombre.** Los textos, cuentas regresivas y barras leen del estado con `bind`. El diseño nunca contiene datos que cambien.
3. **Imágenes por id.** El layout no lleva bytes: `{t:"image", img:"auto"}` apunta a `layout.images.auto`, que el plugin llena después de reducir la imagen (logo 120 px, ícono/avatar 138 px, tracker 72 px de alto). `w`/`h` permiten mantener la proporción sin decodificar. Las imágenes de red las descarga la app, nunca el extension.
4. **Íconos con dos nombres.** `{t:"icon", sf:"car.fill", android:"assets/live/car.png"}`: SF Symbol para iOS, PNG para Android.
5. **Fechas** en el estado: ISO 8601 UTC con `Z`. `countdown`, `stopwatch` y `relative` leen un campo con esa fecha; cada plataforma cuenta sola.
6. **Condiciones** (`if`): `{bind, <un operador>}` con `eq`, `neq`, `gt`, `gte`, `lt`, `lte`, `truthy`. Es la forma serializada de `bind('etapa').equals(2)`.
7. **`lockScreen`** puede ser `{same:"expanded"}` (reutiliza la expandida) o un nodo propio.
8. **Bloque `android`**: usa `title`, `text`, `chip`, `colorized`. `progress` y `actions` son opcionales; si faltan, el traductor Kotlin los toma de `expanded.bottom` (primer nodo de progreso y botones). Así el caso normal no duplica información.
9. **Botones**: `id` obligatorio (`[a-z0-9_]+`). Con `action` ausente o `custom` llegan a `LiveIsland.onAction(id)`.
10. **`extra` desconocido se rechaza** (`additionalProperties: false`) para que los errores de tipeo salgan en Dart, no en el dispositivo.

## Diferencias con el JSON "orientativo" del prompt

| Prompt | Contrato |
| --- | --- |
| `"tracker": {"sf": ..., "asset": ...}` | `"tracker": {"visual": <icon|image>, "height", "background"}` (el HTML tiene `LiveTracker(visual, height:, background:)`) |
| `"minimal": {"t":"icon","sf":..., "asset":"car.png"}` | `icon` lleva `android:` (ruta) y `image` va aparte con `img:` (id); no hay un nodo híbrido |
| `"end": {"sf":"mappin"}` | `"end": {"t":"icon","sf":"mappin"}` (mismo tipo que los demás íconos) |
| `"row"` con botones sin `gap` | `row` y `col` aceptan `gap` y `align` |
| `box` con `child` | igual, con `size`, `radius`, `tint`, `color` |
| — | `images` (manifiesto), `appLogo`, `androidSmallIcon` (los exige §5.1) |

## Cómo se evalúa el espacio de 4 KB

Solo cuenta `state`. Un taxi típico (ejemplo) pesa ~170 bytes. `LiveIsland.check()` lo mide con el mismo criterio (ver `docs/design/LECTURA_DEL_HTML.md` §8 y §12).

## Reglas de render por defecto

Estas reglas las comparten la vista previa de Flutter, el renderer SwiftUI y el traductor Kotlin. Salen del HTML de prototipos (`docs/design/LECTURA_DEL_HTML.md`); la vista previa (`lib/src/preview/`) es su implementación de referencia.

**Estilo.** Un texto sin `size` mide 15 pt, sin `w` pesa 400, sin `lines` ocupa una línea con elipsis. `muted` usa blanco al 62 % en la isla y al 68 % en la tarjeta de bloqueo (negro al 68 % en fondo claro). `accent` usa el acento, o blanco si la tarjeta de bloqueo tiene fondo `accent`. Los contadores (`countdown`, `stopwatch`) llevan cifras tabulares.

**Tamaño según la zona.** Un `icon`, `image` o `avatar` sin `size` toma el de su zona:

| Zona | Cuadro | Glifo de un ícono |
| --- | --- | --- |
| `compactLeading` | 22 pt | 18 pt |
| `minimal` | 24 pt (anillo: 33 pt) | 18 pt (dentro del anillo: 14 pt) |
| `expanded.leading` | 46 pt | 38 pt |
| `box` | el del cuadro | 52 % del cuadro |
| Íconos de botones | — | 15 pt |
| Íconos de inicio y fin de la barra | — | 16 pt |

**Valores por defecto de estructura.** `row`: separación 8 y centrado; `col`: separación 2 y alineado al inicio. Una `row` que contiene botones salta de línea si no cabe. Un `spacer` sin tamaño es flexible solo dentro de una `row`.

**Botones.** El primer botón de una superficie es el principal (acento); los demás son secundarios. En fondo `accent` el primero se invierte (blanco con texto de acento). **La isla expandida de iOS no dibuja botones** (ni las filas que solo contienen botones): tocar la isla siempre abre la app, así que ahí no tienen función. Sí aparecen en la tarjeta de bloqueo y en la notificación de Android.

**Contadores.** Un `countdown` o `stopwatch` ocupa el ancho exacto de sus dígitos y se alinea al borde de su zona (derecha en la isla compacta). Sin eso el contador de iOS (`Text(timerInterval:)`) ocupa todo el ancho disponible y alarga la isla.

**Tarjeta de bloqueo con `{same: "expanded"}`.** Usa `center`, `trailing` y `bottom` de la isla expandida. La zona izquierda es el ícono de app de 40 pt (radio 11), que sale de, en este orden: `appLogo` si es imagen; el `avatar` o la imagen de `expanded.leading`; el ícono de `appLogo` o el del `box` de `expanded.leading` sobre un cuadro de acento. Con `lockScreen` propio el diseño es el del nodo, sin esta regla.

**Fondo `system` de la tarjeta de bloqueo.** Sigue el modo del sistema: oscuro translúcido en modo oscuro, claro translúcido en modo claro. `light` y `accent` no cambian.

**Notificación de Android.** Se arma con el bloque `android`; lo que no trae sale de la isla expandida:

- Barra: `android.progress`, o el primer `bar`/`segments`/`ring` de la expandida (el anillo se dibuja como barra).
- Botones: `android.actions`, o los `button` de la expandida.
- Ícono pequeño (silueta de un color): `androidSmallIcon`, si no `appLogo`.
- Ícono grande: el `avatar` de la expandida, si no `appLogo` si es imagen, si no la imagen de `leading`.
- Título: si `compactTrailing` es un texto que no es contador, se le agrega ` · <texto>`. El encabezado muestra `<app> · <mm:ss>` si es cuenta regresiva y `ahora` si no.
- Se promueve si no es `colorized` y el título no está vacío (el plugin pide la promoción; que Android la conceda depende del usuario y de que el caso sea elegible). `androidPromotable` solo existe en `LiveIsland.check()`.
- Etapas: cada par de etapas es un tramo de 100 y la etapa actual va como subtexto del encabezado (Android no dibuja las etiquetas).
- Chip: `countdown` usa el cronómetro del sistema (cuenta regresiva en vivo); `text` sigue la regla de 7/12 caracteres.
- Íconos: un `LiveIcon` se dibuja con el PNG de su campo `android` (se envía junto al diseño); sin él se omite.
