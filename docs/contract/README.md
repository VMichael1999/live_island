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
