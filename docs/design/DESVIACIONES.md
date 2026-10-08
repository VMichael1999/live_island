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
