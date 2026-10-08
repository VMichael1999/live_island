# Desviaciones respecto al HTML

Aquí se documenta cada cosa que el HTML dibuja y que iOS o Android no permiten (con captura, motivo y alternativa). Ver `docs/PROMPT.md` §2.1.

Vacío por ahora (Fase 0). Las candidatas que ya se ven desde la lectura:

| Tema | Por qué podría diferir | Alternativa prevista |
| --- | --- | --- |
| Anillo en Android | `ProgressStyle` no tiene anillo | Se muestra como barra (ya lo avisa `check()`) |
| Tracker sin fondo en Android | Depende de `setProgressTrackerIcon` con `Icon.createWithBitmap` | Se confirma en fase 4 con Android 16 |
| Ícono pequeño de Android | El sistema lo pinta en un solo color | `androidSmallIcon` o silueta generada |
| Desenfoque de la tarjeta de bloqueo | En iOS lo decide el sistema | Se usa el fondo del sistema |
