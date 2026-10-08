# Push: actualizar e iniciar actividades desde el servidor

Un push solo lleva **datos** (el estado), nunca el diseño. Por eso el diseño se guarda antes en el dispositivo con un nombre:

```dart
await LiveIsland.registerLayout('taxi', diseno); // vuelve a llamarlo si el diseño cambia
```

El `id` de un botón (`LiveButton(id: 'llamar')`) es lo que llega a `LiveIsland.onAction`. Si una app tiene varias actividades a la vez, usa ids distintos por actividad (`llamar_viaje42`): solo admiten minúsculas, números y `_`.

## iOS (APNs)

APNs llega directo a ActivityKit: no hace falta código en la app, solo los tokens.

1. `dart run live_island:setup --push` agrega el permiso `aps-environment` (requiere una cuenta de desarrollador con la capacidad *Push Notifications*).
2. Para **actualizar** una actividad: `LiveIsland.start(..., requestPushToken: true)` y envía a tu servidor `actividad.pushTokens` (hexadecimal).
3. Para **iniciar** una actividad desde el servidor (iOS 17.2+): envía a tu servidor los tokens de `LiveIsland.pushTokens` que no tienen `activityId` (son los de push-to-start).

Cabeceras: `apns-push-type: liveactivity`, `apns-topic: <bundle id>.push-type.liveactivity`.

### Actualizar o terminar

```json
{
  "aps": {
    "timestamp": 1760000000,
    "event": "update",
    "content-state": { "values": { "progreso": 0.8, "titulo": "Casi llegamos" } }
  }
}
```

`"event": "end"` termina la actividad (con `"dismissal-date"` opcional). Solo viajan los campos que cambian; el límite es de 4 096 bytes.

### Iniciar (push-to-start)

```json
{
  "aps": {
    "timestamp": 1760000000,
    "event": "start",
    "content-state": { "values": { "titulo": "Tu conductor está en camino", "progreso": 0.1, "llegaA": "2026-10-08T15:06:00Z" } },
    "attributes-type": "LiveIslandAttributes",
    "attributes": { "layoutId": "tpl_taxi", "deepLink": "miapp://viaje/1" },
    "alert": { "title": "Tu viaje", "body": "Tu conductor está en camino" }
  }
}
```

El `layoutId` es `tpl_` más el nombre usado en `registerLayout`. Las fechas van en ISO 8601 UTC. La actividad nueva llega a Dart por `LiveIsland.startedByPush`, junto con su token.

## Android (FCM)

El plugin no depende de Firebase. Envía un mensaje **de datos** (no de notificación) con el campo `live_island` como JSON en texto, y pásalo al plugin desde tu manejador:

```dart
// firebase_messaging
FirebaseMessaging.onBackgroundMessage(_alRecibir);

@pragma('vm:entry-point')
Future<void> _alRecibir(RemoteMessage m) => LiveIsland.handlePush(m.data);
```

O, sin Dart, desde tu `FirebaseMessagingService`:

```kotlin
override fun onMessageReceived(message: RemoteMessage) {
    LiveIslandPush.handle(applicationContext, message.data)
}
```

### Mensajes

```json
{ "live_island": "{\"event\":\"start\",\"template\":\"taxi\",\"state\":{\"titulo\":\"Hola\",\"progreso\":0.1},\"deepLink\":\"miapp://viaje/1\"}" }
{ "live_island": "{\"event\":\"update\",\"id\":\"<id de la actividad>\",\"state\":{\"progreso\":0.8}}" }
{ "live_island": "{\"event\":\"end\",\"id\":\"<id>\",\"state\":{\"titulo\":\"Llegó\"},\"dismiss\":\"after\",\"dismissAfter\":300}" }
```

- `start` usa el diseño registrado con `template` y devuelve el id de la actividad nueva (llega a Dart por `LiveIsland.startedByPush`).
- `update` y `end` necesitan el `id`; la app lo envía a tu servidor (`LiveActivity.id`) o lo recupera con `LiveIsland.activeActivities()`.
- `dismiss`: `immediate`, `default` o `after` (con `dismissAfter` en segundos).
- También se aceptan los campos sueltos (`event`, `id`, `template`, `state` como JSON en texto).

Android 12+ limita lo que una app en segundo plano puede hacer al recibir un mensaje: usa prioridad **alta** (`"priority": "high"`).
