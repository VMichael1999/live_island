import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/services.dart';

/// An image ready to send to the device, with the limit it must be reduced
/// to (in pixels).
class LiveImagePayload {
  const LiveImagePayload({
    required this.id,
    required this.bytes,
    required this.maxWidth,
    required this.maxHeight,
  });

  final String id;
  final Uint8List bytes;
  final int maxWidth, maxHeight;

  Map<String, Object?> toMap() => {
    'id': id,
    'bytes': bytes,
    'maxWidth': maxWidth,
    'maxHeight': maxHeight,
  };
}

/// An iOS push token (ActivityKit).
class LivePushToken {
  const LivePushToken({required this.token, this.activityId});

  /// Token in hexadecimal, ready to send to the server.
  final String token;

  /// The activity it belongs to. `null` = push-to-start token (iOS 17.2),
  /// used to start activities from the server.
  final String? activityId;

  bool get isPushToStart => activityId == null;

  @override
  String toString() =>
      'LivePushToken(${activityId ?? 'push-to-start'}: $token)';
}

/// Events the platform sends about push.
sealed class LivePushEvent {
  const LivePushEvent();
}

/// A new token arrived (from an activity or from push-to-start).
class LivePushTokenEvent extends LivePushEvent {
  const LivePushTokenEvent(this.token);
  final LivePushToken token;
}

/// An activity started from a push (iOS push-to-start, Android `handlePush`).
class LivePushStartedEvent extends LivePushEvent {
  const LivePushStartedEvent(this.activityId);
  final String activityId;
}

/// Where an activity is in its life.
enum LiveActivityState {
  /// Showing and accepting updates.
  active,

  /// Its content is out of date: `staleAfter` passed without an update (iOS).
  stale,

  /// The app (or the server) ended it. It can still be on screen, with its
  /// last state, until it is dismissed.
  ended,

  /// It left the screen: the user swiped it away, or the system or the
  /// dismissal time removed it.
  dismissed,
}

/// An activity changed [state]. See [LiveIsland.stateChanges].
class LiveActivityStateChange {
  const LiveActivityStateChange(this.id, this.state, {this.customId});

  /// Platform id of the activity.
  final String id;

  /// The id the app gave it when starting it, if any.
  final String? customId;

  final LiveActivityState state;

  @override
  bool operator ==(Object other) =>
      other is LiveActivityStateChange &&
      other.id == id &&
      other.customId == customId &&
      other.state == state;

  @override
  int get hashCode => Object.hash(id, customId, state);

  @override
  String toString() => 'LiveActivityStateChange($id, $state)';
}

/// An activity changed state (see [LiveActivityState]).
class LivePushStateEvent extends LivePushEvent {
  const LivePushStateEvent(this.change);
  final LiveActivityStateChange change;
}

/// An alert that accompanies an update: on iOS the island expands for a
/// moment (or a banner appears on the lock screen) with [title] and
/// [body], and plays a sound; on Android the notification sounds and shows as
/// a heads-up.
///
/// ```dart
/// await activity.update(
///   {'status': 'arrived'},
///   alert: const LiveAlert(title: 'Your driver arrived', body: 'Toyota Yaris · ABC-123'),
/// );
/// ```
class LiveAlert {
  const LiveAlert({required this.title, required this.body, this.sound});

  /// Title of the alert (iOS). Android shows the activity's content.
  final String title;

  /// Text of the alert (iOS).
  final String body;

  /// Name of a sound file in the app's bundle (`alert.caf`).
  /// With `null` the default sound plays.
  final String? sound;

  Map<String, Object?> toMap() => {
    'title': title,
    'body': body,
    if (sound != null) 'sound': sound,
  };

  @override
  bool operator ==(Object other) =>
      other is LiveAlert &&
      other.title == title &&
      other.body == body &&
      other.sound == sound;

  @override
  int get hashCode => Object.hash(title, body, sound);
}

/// How an activity is dismissed when it ends.
class LiveDismiss {
  const LiveDismiss._(this.type, this.after, [this.at]);

  /// Disappears at once.
  static const immediate = LiveDismiss._('immediate', Duration.zero);

  /// Stays until the user dismisses it or a few hours pass (iOS: 4 h).
  static const byDefault = LiveDismiss._('default', Duration.zero);

  /// Stays visible for [delay] with its last state and then disappears
  /// (iOS limits it to 4 hours).
  const LiveDismiss.after(Duration delay) : this._('after', delay);

  /// Stays visible with its last state until [when] and then disappears.
  /// If [when] has already passed, it is equivalent to [immediate]. iOS limits
  /// it to 4 hours after it ends.
  const LiveDismiss.at(DateTime when) : this._('after', Duration.zero, when);

  final String type;
  final Duration after;

  /// Absolute time of [LiveDismiss.at]; `null` for the others.
  final DateTime? at;

  /// The wait until dismissal, computed now: for [at] it is the distance
  /// to that time.
  Duration afterFromNow([DateTime? now]) {
    final target = at;
    if (target == null) return after;
    final d = target.difference(now ?? DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }
}

/// A live activity: its platform id and, if the app gave one when starting
/// it, its own id.
class LiveActivityInfo {
  const LiveActivityInfo(this.id, {this.customId});

  final String id;
  final String? customId;

  @override
  bool operator ==(Object other) =>
      other is LiveActivityInfo && other.id == id && other.customId == customId;

  @override
  int get hashCode => Object.hash(id, customId);
}

/// Platform error while handling an activity.
class LiveIslandException implements Exception {
  const LiveIslandException(this.code, this.message);

  /// `unsupported`, `disabled`, `not_configured`, `not_found`, `start_failed`…
  final String code;
  final String message;

  @override
  String toString() => 'LiveIslandException($code): $message';
}

/// What each platform (iOS, Android) implements.
abstract class LiveIslandPlatform {
  /// Does this platform need the `LiveIcon.android` PNGs? (Android only.)
  bool get needsAndroidIcons;

  /// Can the app show activities? (iOS: `areActivitiesEnabled`;
  /// Android: notifications allowed and, on Android 16+, promoted.)
  Future<bool> areEnabled();

  /// The activities that are still alive (also those started before the app
  /// was closed or by a push), with their own id if they have one.
  Future<List<LiveActivityInfo>> activeActivities();

  /// Ends all of the app's live activities.
  Future<void> endAll({LiveDismiss dismiss = LiveDismiss.immediate});

  /// Id of each button the user taps in the activity. Actions that arrived
  /// with the app closed are delivered when you start listening.
  Stream<String> get actions;

  /// Push tokens and activities started by push.
  Stream<LivePushEvent> get pushEvents;

  /// Saves a named design on the device. It is needed to start activities from
  /// a push, which cannot carry the design.
  Future<void> registerLayout({
    required String name,
    required String layoutJson,
    required List<LiveImagePayload> images,
  });

  /// Processes the data of an FCM push (Android). Returns the id of the
  /// affected activity. On iOS it does nothing: APNs goes straight to ActivityKit.
  Future<String?> handlePush(Map<String, Object?> data);

  /// Asks for the notification permission (Android 13+). On iOS it does nothing
  /// and returns whether activities are enabled.
  Future<bool> requestPermission();

  /// Opens the settings where the user allows notifications promoted to
  /// Live Update (Android 16+). Returns `false` if they do not exist.
  Future<bool> openPromotionSettings();

  /// Starts an activity and returns its id.
  Future<String> start({
    required String layoutJson,
    required String stateJson,
    required List<LiveImagePayload> images,
    String? deepLink,
    Duration? staleAfter,
    double relevance = 0,
    bool requestPushToken = false,
    String? customId,
  });

  Future<void> update(
    String id,
    String stateJson, {
    Duration? staleAfter,
    LiveAlert? alert,
  });

  Future<void> end(
    String id, {
    String? stateJson,
    LiveDismiss dismiss = LiveDismiss.byDefault,
  });

  /// Schedules the end of the activity for `at` (see [LiveActivity.scheduleEnd]).
  /// [secondsFromNow] is already the distance from now, greater than zero.
  Future<void> scheduleEnd(
    String id, {
    required double secondsFromNow,
    String? stateJson,
  });
}

/// Method channel implementation (`live_island`).
class MethodChannelLiveIslandPlatform implements LiveIslandPlatform {
  MethodChannelLiveIslandPlatform([MethodChannel? channel])
    : _channel = channel ?? const MethodChannel('live_island');

  final MethodChannel _channel;
  static const _actionsChannel = EventChannel('live_island/actions');
  static const _pushChannel = EventChannel('live_island/push');

  Future<T?> _call<T>(String method, [Map<String, Object?>? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on PlatformException catch (e) {
      throw LiveIslandException(e.code, e.message ?? e.code);
    } on MissingPluginException {
      throw const LiveIslandException(
        'unsupported',
        'live_island is not available on this platform yet.',
      );
    }
  }

  @override
  Future<List<LiveActivityInfo>> activeActivities() async => [
    for (final e in await _call<List<Object?>>('activeActivities') ?? const [])
      if (e is Map)
        LiveActivityInfo(
          e['id']! as String,
          customId:
              (e['customId'] as String?)?.isEmpty ?? true
                  ? null
                  : e['customId'] as String?,
        )
      else
        LiveActivityInfo(e! as String),
  ];

  @override
  Future<void> endAll({LiveDismiss dismiss = LiveDismiss.immediate}) =>
      _call<void>('endAll', {
        'dismiss': dismiss.type,
        'dismissAfter': dismiss.afterFromNow().inMilliseconds / 1000,
      });

  // Cada `receiveBroadcastStream()` abre una suscripción nueva en el lado nativo y
  // esa reemplaza a la anterior: con dos oyentes (por ejemplo `stateChanges` y
  // `activity.states`) uno dejaba de recibir. Se comparte una sola suscripción.
  late final Stream<String> _actions =
      _actionsChannel
          .receiveBroadcastStream()
          .map((e) => e as String)
          .asBroadcastStream();

  late final Stream<LivePushEvent> _pushEvents =
      _pushChannel
          .receiveBroadcastStream()
          .map(_decodePushEvent)
          .asBroadcastStream();

  @override
  Stream<String> get actions => _actions;

  @override
  Stream<LivePushEvent> get pushEvents => _pushEvents;

  static LivePushEvent _decodePushEvent(Object? e) {
    final m = Map<String, Object?>.from(e as Map);
    return switch (m['type']) {
      'started' => LivePushStartedEvent(m['activityId']! as String),
      'state' => LivePushStateEvent(
        LiveActivityStateChange(
          m['activityId']! as String,
          LiveActivityState.values.asNameMap()[m['state']] ??
              LiveActivityState.active,
          customId:
              (m['customId'] as String?)?.isEmpty ?? true
                  ? null
                  : m['customId'] as String?,
        ),
      ),
      _ => LivePushTokenEvent(
        LivePushToken(
          token: m['token']! as String,
          activityId: m['activityId'] as String?,
        ),
      ),
    };
  }

  @override
  Future<void> registerLayout({
    required String name,
    required String layoutJson,
    required List<LiveImagePayload> images,
  }) => _call<void>('registerLayout', {
    'name': name,
    'layout': layoutJson,
    'images': [for (final i in images) i.toMap()],
  });

  @override
  Future<String?> handlePush(Map<String, Object?> data) =>
      _call<String>('handlePush', {'data': data});

  @override
  bool get needsAndroidIcons => defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<bool> areEnabled() async => await _call<bool>('areEnabled') ?? false;

  @override
  Future<bool> requestPermission() async =>
      await _call<bool>('requestPermission') ?? false;

  @override
  Future<bool> openPromotionSettings() async =>
      await _call<bool>('openPromotionSettings') ?? false;

  @override
  Future<String> start({
    required String layoutJson,
    required String stateJson,
    required List<LiveImagePayload> images,
    String? deepLink,
    Duration? staleAfter,
    double relevance = 0,
    bool requestPushToken = false,
    String? customId,
  }) async {
    final id = await _call<String>('start', {
      'customId': customId,
      'layout': layoutJson,
      'state': stateJson,
      'images': [for (final i in images) i.toMap()],
      'deepLink': deepLink,
      'staleAfter':
          staleAfter?.inMilliseconds == null
              ? null
              : staleAfter!.inMilliseconds / 1000,
      'relevance': relevance,
      'requestPushToken': requestPushToken,
    });
    if (id == null) {
      throw const LiveIslandException(
        'start_failed',
        'The platform did not return an id.',
      );
    }
    return id;
  }

  @override
  Future<void> update(
    String id,
    String stateJson, {
    Duration? staleAfter,
    LiveAlert? alert,
  }) => _call<void>('update', {
    'id': id,
    'alert': alert?.toMap(),
    'state': stateJson,
    'staleAfter': staleAfter == null ? null : staleAfter.inMilliseconds / 1000,
  });

  @override
  Future<void> end(
    String id, {
    String? stateJson,
    LiveDismiss dismiss = LiveDismiss.byDefault,
  }) => _call<void>('end', {
    'id': id,
    'state': stateJson,
    'dismiss': dismiss.type,
    'dismissAfter': dismiss.afterFromNow().inMilliseconds / 1000,
  });

  @override
  Future<void> scheduleEnd(
    String id, {
    required double secondsFromNow,
    String? stateJson,
  }) => _call<void>('scheduleEnd', {
    'id': id,
    'state': stateJson,
    'dismissAfter': secondsFromNow,
  });
}
