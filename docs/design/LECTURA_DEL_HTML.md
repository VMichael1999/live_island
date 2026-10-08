# Lectura de `live_island_prototipos.html`

Resumen de lo que entendí por superficie, sacado del `<script>` y del CSS del HTML (v0.2). Es el checklist de fidelidad: cada línea es un requisito, salvo que `DESVIACIONES.md` diga lo contrario.

Capturas de referencia en `docs/design/capturas/` (se generan con Chrome headless a 2×):
`<preset>_ios.png`, `<preset>_android.png`, `<preset>_validacion.png`, `<preset>_codigo.png` para los 15 presets, más `galeria.png`, `seccion_{editable,medidas,componentes,fidelidad}.png` y `pagina_completa.png`.

---

## 0. Modelo de datos del editor (`state`)

Estos campos del editor son los que el paquete debe poder expresar. Entre paréntesis, el nombre en el HTML.

| Grupo | Campos |
| --- | --- |
| Contenido | título (`title`), subtítulo (`subtitle`), nombre visible (`name`), ícono principal (`icon`), avatar sí/no (`showAvatar`), iniciales (`avatarText`, 2 caracteres), dato destacado: `hlMode` = `text` o `countdown`, `highlight` (texto), `minutes` (cuenta regresiva) |
| Imágenes (4 ranuras) | `logoImg` (120 px), `mainImg` (138 px), `avatarImg` (138 px), `trackerImg` (72 px de alto). Cada una con `fit` = `contain`/`cover` y `shape` = `rounded`/`circle`/`square`. El tracker además tiene `trackerCircle` (fondo circular de acento sí/no) |
| Estilo | `accent` (hex), `lockBg` = `dark`/`light`/`accent` |
| Progreso | `pShow`, `pType` = `bar`/`segments`/`ring`, `pValue` 0–100, `tracker` (ícono), `startIcon`, `endIcon`, `stages` (lista separada por comas), `showPoints` |
| Botones | `a1Label`/`a1Icon`, `a2Label`/`a2Icon` (máximo 2; etiqueta vacía = botón oculto) |
| Android | `chipMode` = `countdown`/`text`/`icon`, `chipText`, `colorized`, `androidOk` (solo en presets; `false` = caso que Google no promueve), `app` (nombre de la app) |

Íconos: 49 íconos Lucide en el HTML con su equivalente SF Symbol (`SF`) y etiqueta en español (`ICON_LABELS`). Al implementar, el SF Symbol es el nombre en iOS y el `android:` es un PNG (`assets/live/<nombre>.png`).

Valores derivados:
- `v01 = clamp(pValue/100, 0, 1)`.
- `remaining(deadline)` en segundos; `mmss` da `m:ss` o `h:mm:ss`.
- Dato destacado mostrado (`hl`): cuenta regresiva → `mmss(remaining)`; si no, el texto.
- Etapa actual: `cur = min(n-1, floor(v*(n-1) + 1e-6))`, con `n` = número de etapas.

---

## 1. iOS · Compact (`compactHTML`)

- Contenedor: negro, `236 × 37 pt`, radio 19, relleno `0 12 0 10`, dos extremos (`space-between`).
- **Izquierda** (`.lead`, ancho máx. 72): `lead(s, 22)`:
  1. avatar activo + foto → imagen circular 22 pt;
  2. avatar apagado + imagen del ícono principal → imagen 22 pt;
  3. avatar activo → círculo de acento 22 pt con iniciales (fuente 42 % del tamaño, 600, blanco);
  4. si no → ícono de 18 pt (82 % de 22), trazo 2.2, **color de acento**.
- **Derecha** (`.trail`, ancho máx. 72): dato destacado, **15 pt, semibold 600, cifras tabulares, color de acento**, una línea, `overflow:hidden` + elipsis, alineado a la derecha.
- Regla de las medidas: el dato destacado ≤ 7 caracteres.

## 2. iOS · Minimal (`minimalHTML`)

- Círculo negro `37 × 37 pt`, centrado. Junto a él se dibuja una segunda actividad ficticia (círculo negro 37 pt, opacidad .55, ícono de temporizador gris `#999` de 16 pt) para mostrar el caso "dos actividades".
- Contenido:
  - Si hay progreso **y** `pType = ring`: anillo de 33 pt con el ícono dentro (`inner`): imagen principal de 16 pt, o ícono de 14 pt (trazo 2.4, acento). Si hay avatar, el interior queda vacío.
  - Si no: `lead(s, 24)` si hay avatar o imagen principal, o `lead(s, 22)` si es ícono.
- Anillo (`ring`): círculo de fondo `rgba(255,255,255,.22)`, trazo 3, arco en acento, `stroke-linecap: round`, empieza arriba (rotado −90°).

## 3. iOS · Expandida (`expandedHTML`)

Contenedor: negro, ancho `min(360, 100 %)`, **radio 44**, relleno `16 20 18`, separación vertical 12. Tres bloques en este orden:

1. **Fila superior** (rejilla `auto | 1fr | auto`, separación 12, centrada vertical):
   - **Leading, 46 pt**: si hay avatar o imagen principal → `lead(s, 46)`; si no, caja de 46 pt, radio 14, fondo `acento al 22 %`, ícono de 24 pt en acento (trazo 2.2).
   - **Centro**: título (**15 pt, 600**, interlínea 1.25, puede ocupar 2 líneas) y subtítulo (**13 pt**, `rgba(255,255,255,.62)`, una línea con elipsis).
   - **Trailing** (ancho máx. 130, alineado a la derecha, una línea): dato destacado (**22 pt, 700, tabular, acento**) y debajo el nombre (**12 pt**, blanco al 62 %). Con anillo: en lugar de ambos va un anillo de 46 pt sin contenido.
2. **Progreso** (`progress(s,'dark')`) si no es anillo. Si es anillo, en su lugar una línea centrada de 12 pt: `"<dato> · <nombre>"`.
3. **Botones** (`iosActions`).

## 4. iOS · Pantalla de bloqueo (`lockCardHTML`)

- Alrededor: reloj de 64 pt (600, tabular) y fecha de 15 pt (solo decorativo en el prototipo; no es parte del paquete).
- Tarjeta: ancho completo (máx. 360), **radio 22**, relleno `14 16`, separación 12. Tres fondos:
  - `dark` (`system`): `rgba(22,22,24,.78)`, texto blanco, desenfoque 18.
  - `light`: `rgba(250,250,252,.86)`, texto `#111`, desenfoque 18.
  - `accent`: fondo = color de acento sólido, texto blanco.
- Subtítulos con opacidad .68.
- **Fila superior** (`auto | 1fr | auto`):
  - **Ícono de app, 40 pt, radio 11**, por prioridad: `logoImg` (40) → avatar con foto (40, círculo) → avatar con iniciales (círculo 40, 16 pt; en modo `accent` fondo `rgba(255,255,255,.25)`) → ícono de 22 pt blanco sobre cuadrado de acento (en modo `accent`, fondo `rgba(255,255,255,.22)`).
  - **Centro**: título **15 pt, 600, máx. 2 líneas** (`line-clamp: 2`) y subtítulo 13 pt con elipsis.
  - **Derecha** (ancho máx. 124): dato destacado **22 pt 700** y el nombre debajo (13 pt, opacidad .68). Color del dato: acento (blanco en modo `accent`). Con anillo: anillo de 40 pt (blanco en modo `accent`) y el dato en **15 pt** debajo.
- Progreso (`progress(s, lockBg)`) si no es anillo, y botones.

## 5. Barra de progreso (`progress`)

- No se dibuja si `pShow = false`.
- **Colores por superficie**:
  - Fondo del tramo vacío: `rgba(255,255,255,.2)` (`dark` y `accent`), `rgba(0,0,0,.12)` (`light`).
  - Relleno: acento (blanco en `accent`).
  - Tracker: círculo de acento con ícono blanco; en `accent`, círculo blanco con ícono de acento.
  - Íconos de inicio y fin: blanco (`#333` en `light`), 16 pt.
- **Pista**: alto **6 pt**, radio 3, separación **4 pt** entre tramos.
- **Tramos**: `segments` con ≥ 2 etapas → `n = etapas − 1` tramos iguales; cada tramo se rellena `clamp((v − i/n)·n, 0, 1)`. Si no, un único tramo relleno hasta `v`.
  - En Android también se usan tramos si hay ≥ 2 etapas y el tipo no es `bar` (el anillo se convierte antes en `bar`, así que no).
- **Puntos** (`showPoints` y ≥ 2 etapas): uno por etapa en `k/(n−1)`, círculo de 10 pt con borde de 2; completado (`p ≤ v`) relleno de acento, pendiente relleno `#1c1c1e` (`#fff` en `light`) con borde del color del tramo vacío.
- **Tracker**: centrado en `left = v·100 %` sobre la pista, con transición `left .25 s linear` (se desactiva con `prefers-reduced-motion`).
  - Ícono: círculo **26 pt**, sombra `0 1 3 rgba(0,0,0,.35)`, ícono de 15 pt.
  - Imagen con círculo: círculo 26 pt con imagen cuadrada de 17 pt dentro.
  - Imagen sin círculo (`bare`): alto 24 pt, ancho automático (máx. 56), con sombra `drop-shadow` (así se ve el auto de 2:1).
- **Íconos de inicio y fin**: a los lados de la pista, 16 pt, opacidad .9, separación 8.
- **Etiquetas** (solo si ≥ 2 etapas y `pType = segments` o `showPoints`):
  - **≤ 3 etapas**: cada etiqueta en `left = k/(n−1)`; la primera alineada a la izquierda, la última a la derecha, las del medio centradas. Fuente 11.5 pt. Etapa actual: **600** y color fuerte; las demás 400 y color atenuado (`rgba(255,255,255,.6)` / `rgba(0,0,0,.55)`). Margen lateral de 24 pt si hay ícono de inicio/fin.
  - **> 3 etapas**: una sola línea: etapa actual en 600 a la izquierda y `Paso k de n` a la derecha (11.5 pt).

## 6. Botones iOS (`iosActions`)

Máximo dos, píldora, **13 pt 600**, relleno `7 12`, ícono de 15 pt + etiqueta, separación 8.

| Superficie | Botón 1 | Botón 2 |
| --- | --- | --- |
| `dark` (isla y bloqueo `system`) | fondo acento, texto blanco | fondo `rgba(255,255,255,.14)`, texto blanco |
| `light` | fondo acento, texto blanco | fondo `rgba(0,0,0,.08)`, texto `#111` |
| `accent` | fondo **blanco**, texto de acento | fondo `rgba(255,255,255,.22)`, texto blanco |

## 7. Android (`androidHTML`)

Maqueta de 3 bloques sobre fondo `#141218`, radio 22:

1. **Barra de estado**: hora `9:41` y, **solo si la notificación se promueve**, el **chip**; a la derecha, señal/wifi/batería.
   - Chip: alto **24 dp**, ancho máx. **96 dp**, radio 12, relleno `0 9 0 7`, fondo = acento, texto blanco 13 pt 500, ícono pequeño de 14 pt + texto (`only` = solo ícono, relleno 7).
   - `chipInfo`: `countdown` → `max(1, ceil(restante/60)) + " min"`; `text` → `chipText`; `icon` → vacío. Longitud en puntos de código: **vacío → solo ícono; > 12 → solo ícono; 8–12 → primeros 6 caracteres + "…"; ≤ 7 → completo**.
2. **Tarjeta** (`#2B2930`, radio 24, relleno `14 16`):
   - **Cabecera** (12 pt, `#CAC4D0`): círculo de 22 pt de acento con el ícono pequeño de 13 pt, luego `"<app> · <cuándo>"`. `cuándo` = `mm:ss` si el dato es cuenta regresiva; si no, `"ahora"`.
   - **Cuerpo** (`1fr | auto`): título (15 pt 500) — se le añade `" · <destacado>"` si el dato es texto — y texto (14 pt) = `subtítulo · nombre` (sin vacíos). A la derecha el **ícono grande** de 40 pt: avatar (foto o círculo con iniciales) → `logoImg` → `mainImg` → nada.
   - **Progreso** (`progress(...,'android')`; anillo → barra). Etiquetas con colores de superficie `dark`.
   - **Acciones**: texto 14 pt 500, sin fondo, en color de acento + ícono de 16 pt.
   - Si `colorized`: fondo de la tarjeta = acento, texto blanco (y por eso Android no promueve).
3. **Pie** (12 pt): aviso `"Promovida a Live Update: chip en la barra de estado, arriba del panel y en la pantalla de bloqueo."` o `"No se promueve: se ve como notificación en curso normal, sin chip."`.

- **Promovida** ⇔ `!colorized && androidOk && title ≠ ""`.
- **Ícono pequeño** (cabecera y chip): silueta blanca de un solo color. Si hay `logoImg` se pinta con `brightness(0) invert(1)`, por lo que un logo opaco se ve como cuadrado blanco (el efecto que el aviso de validación describe). Si no, el ícono principal.

## 8. Validación (`renderChecks`) → `LiveIsland.check()`

Punto de color: `ok` (verde), `warn` (ámbar), `bad` (rojo). Reglas, en este orden:

1. **ok** — Estado por actualización: N bytes de 4 096 (iOS), con barra de uso. El payload medido incluye: `titulo, subtitulo, nombre, destacado | llegaA, progreso (2 decimales), etapa`. *(El HTML nunca marca error si pasa de 4 096. Ver "Aclaraciones" abajo.)*
2. **warn / ok** — El dato destacado tiene > 7 caracteres → "…se recorta en la isla compacta. Usa 7 o menos." Si no: "cabe en la isla compacta".
3. **ok / warn** — Chip de Android: completo (N caracteres) / recortado ("“texto” tiene N caracteres (máximo 7 para verse completo)") / solo ícono ("el texto es demasiado largo" si había texto).
4. **bad / ok** — Promoción: `!androidOk` → "Android no promueve este caso: no lo inició el usuario como actividad con inicio y fin"; `colorized` → "no promueve notificaciones con setColorized(true)"; sin título → "Android exige un título (setContentTitle)"; si no, **ok** "la promueve a Live Update (estilo nativo, sin RemoteViews)".
5. **warn** — Anillo: "no existe en Android: se muestra como barra de ProgressStyle".
6. **warn** — Segmentos con < 2 etapas: "escribe al menos dos etapas".
7. **warn** — Hay `logoImg`: "el ícono pequeño se ve como silueta de un solo color… conviene `androidSmallIcon`".
8. **ok**, por cada imagen cargada: `<ranura>: N KB, se reduce a <px> antes de copiarse al App Group (iOS). Proporción respetada con fit "<fit>"`.
9. **warn** — Tracker (ícono o imagen) con la barra oculta: "solo se ve si la barra está visible".

## 9. Código Dart generado (`renderCode`) = forma de la API

Estructura fija de salida: (1) mapa `estado` con claves en español elegidas por el usuario (`titulo, subtitulo, nombre, llegaA | destacado, progreso`), (2) `LiveLayout(...)`, (3) `LiveIsland.start / update / onAction / end`.

Nombres de API que aparecen en el código del HTML y **no** están en el resumen del prompt (los tomo como parte de la API):
`LiveText.from(widget, size:, weight:, accent:)`, `LiveAlign.end`, `LiveBox(child:, size:, radius:, tint:)`, `LiveTracker(visual, height:, background:)`, `LiveTrackerBackground.accentCircle | none`, `LiveFit.contain | cover`, `LiveShape.rounded | circle | square`, `LiveBackground.system | light | accent`, `LiveChip.countdown | text | icon`, `LiveAvatar('CM')`, `LiveImage.asset(path, fit:, shape:)`.

Reglas de generación que condicionan la API:
- `appLogo` siempre se emite (logo o ícono principal); `androidSmallIcon` solo si hay logo.
- `minimal` = `LiveProgress.ring(value:, child: ícono)` si hay anillo.
- El `id` de cada `LiveButton` sale de la etiqueta en minúsculas con guiones bajos (`"Ver código"` → `ver_codigo`).
- `android.title: bind('titulo')`, `android.text: LiveText.format('{subtitulo} · {nombre}')`.

## 10. Los 15 presets (`PRESETS`)

| id | Patrones | Acento | Progreso | Dato | Notas |
| --- | --- | --- | --- | --- | --- |
| taxi | 1,2,6 | `#1F6FEB` | segmentos 45 %, 3 etapas, puntos | cuenta regresiva 6 min | logo `TY`, **imagen de auto sin círculo**, avatar `CM`, fin MapPin, 2 botones, chip cuenta regresiva |
| delivery | 1,2 | `#E4572E` | segmentos 62 %, 4 etapas, puntos | cuenta regresiva 12 | tracker Bike, fin House |
| courier | 1,2,5 | `#6D4C41` | segmentos 40 %, 4 etapas | texto "3 paradas" | tracker Truck, chip texto "3 más" |
| pickup | 1,6 | `#8D5B3A` | segmentos 50 %, 3 etapas | texto "#47" | sin tracker, chip "#47" |
| queue | 5,6 | `#00897B` | barra 70 % | texto "4 antes" | tracker User, chip "B-027" |
| flight | 1,3,6 | `#2D5BD7` | segmentos 35 %, 3 etapas | cuenta regresiva 25 | tracker Plane |
| parking | 3 | `#0277BD` | anillo 35 % | cuenta regresiva 45 | 2 botones, anillo en minimal |
| ev | 3,4 | `#2E7D32` | barra 68 % | texto "68 %" | tracker Zap |
| workout | 3,4 | `#D81B60` | segmentos 50 %, 4 etapas ("1,2,3,4"), sin puntos | cuenta regresiva 1,5 | etiquetas con "Paso k de n" |
| cooking | 1,3 | `#F57C00` | anillo 40 % | cuenta regresiva 15 | |
| upload | 4 | `#5E35B1` | barra 42 % | texto "42 %" | |
| tech | 1,2 | `#00838F` | segmentos 30 %, 4 etapas, puntos | cuenta regresiva 20 | avatar `JR`, tracker Car |
| transit | 2,5 | `#C62828` | segmentos 55 %, 5 etapas, puntos | texto "3 paradas" | tracker Bus, fin Flag, sin botones |
| clinic | 3,5 | `#00796B` | barra 80 % | texto "2 antes" | tracker User |
| score | 4 | `#1B5E20` | **sin progreso** | texto "78'" | `androidOk: false` → sin Live Update, el único caso `bad` |

Patrones (`PAT_NAMES`): 1 Etapas, 2 Llegada, 3 Cuenta regresiva, 4 Métrica, 5 Cola, 6 Código.

## 11. Cosas que el HTML dibuja y NO son requisitos del paquete

Son parte de la maqueta, no de la API: reloj y fecha de la pantalla de bloqueo, la segunda actividad ficticia en minimal, la hora `9:41` y los íconos de señal/wifi/batería en Android, el texto de pie de la tarjeta Android, y el fondo degradado del "wallpaper".

## 12. Aclaraciones y huecos que encontré (para decidir contigo)

Ninguno bloquea la fase 0, pero afectan el contrato y los avisos de `check()`:

1. **`MetricStyle` / `LiveMetric`**: aparece en la tabla de componentes y en el prompt, pero ningún preset lo usa ni el HTML lo dibuja. Lo dejo en el contrato como nodo opcional; su render se define en fase 3/4.
2. **`LiveToggle`, `LiveStack`, `LivePadding`, `LiveSpacer`, `LiveIf`** tampoco se dibujan en el HTML (solo se listan). Entran al contrato; la vista previa los renderiza según la lógica SwiftUI equivalente.
3. **Payload de 4 096 bytes**: el HTML siempre muestra "ok" aunque se pase, y mide `etapa` aunque `renderCode` no la envíe. En `check()` propongo marcar `bad` a partir de 4 096 y `warn` a partir de ~3 500, y medir solo lo que el estado real contiene. Es una ampliación; el caso normal da el mismo resultado.
4. **Botones (`id`)**: se derivan de la etiqueta, pero en el paquete el `id` es obligatorio y explícito; el HTML solo lo infiere al generar.
5. **Cuenta regresiva**: el HTML la dibuja con `mm:ss` en vivo; en el paquete el estado lleva `llegaA` (ISO 8601 UTC) y cada plataforma cuenta sola (`Text(timerInterval:)` / cronómetro de Android).
6. **Texto de `compactLeading` del prompt**: dice "~44 pt por lado"; el HTML dibuja el contenedor compacto completo en 236 × 37 pt. Uso 44 pt como zona de cada lado y 37 pt de alto, como indica la tabla de medidas.
