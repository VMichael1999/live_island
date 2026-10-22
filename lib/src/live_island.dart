import 'dart:async';
import 'dart:convert';

import 'core/check.dart';
import 'core/layout.dart';
import 'core/state.dart';
import 'platform/image_loader.dart';
import 'platform/live_island_platform.dart';

/// An activity in progress. It is obtained with [LiveIsland.start].
class LiveActivity {
  LiveActivity._(this.id, this._platform, {this.customId});

  /// Platform identifier (ActivityKit on iOS).
  final String id;

  /// The app's own id given in [LiveIsland.start] (`customId`), if any.
  final String? customId;
  final LiveIslandPlatform _platform;

  /// Changes only the indicated fields; the rest of the state is kept. It is
  /// the only thing that travels with each update (iOS limits it to 4,096 bytes).
  ///
  /// [staleAfter] marks the content as out of date after that time
  /// (see [LiveBind.stale]). [alert] draws attention: it expands the island and
  /// plays a sound on iOS; on Android the notification sounds and shows as a heads-up.
  Future<void> update(
    Map<String, Object?> state, {
    Duration? staleAfter,
    LiveAlert? alert,
  }) => _platform.update(
    id,
    jsonEncode(LiveState.normalize(state)),
    staleAfter: staleAfter,
    alert: alert,
  );

  /// Keeps the activity up to date from a live data source: the driver's
  /// position, an order's status, a timer… Each event of [source] goes through
  /// [toState] and the result is sent with [update].
  ///
  /// To avoid spending the system's update budget, it sends at most one every
  /// [minInterval] (the last one always arrives) and skips those that change
  /// nothing. It returns the subscription: cancel it (or call [end]) to stop
  /// following.
  ///
  /// ```dart
  /// activity.follow(
  ///   positions, // Stream<LiveLatLng> from your map or your server
  ///   (p) => {'progress': route.progressAt(p), 'stage': route.stageAt(p, 4)},
  /// );
  /// ```
  StreamSubscription<T> follow<T>(
    Stream<T> source,
    Map<String, Object?> Function(T event) toState, {
    Duration minInterval = const Duration(seconds: 5),
  }) {
    Map<String, Object?>? last;
    Map<String, Object?>? pending;
    Timer? timer;
    DateTime? sentAt;

    Future<void> flush() async {
      timer = null;
      final next = pending;
      pending = null;
      if (next == null) return;
      sentAt = DateTime.now();
      last = {...?last, ...next};
      await update(next);
    }

    final sub = source.listen((event) {
      final next = toState(event);
      final merged = {...?pending, ...next};
      final base = {...?last};
      if (merged.entries.every(
        (e) => base.containsKey(e.key) && base[e.key] == e.value,
      )) {
        return;
      }
      pending = merged;
      final wait =
          sentAt == null
              ? Duration.zero
              : minInterval - DateTime.now().difference(sentAt!);
      if (wait <= Duration.zero) {
        timer?.cancel();
        flush();
      } else {
        timer ??= Timer(wait, flush);
      }
    }, onDone: () => timer?.cancel());
    return sub;
  }

  /// Push tokens of this activity (iOS; they start arriving shortly after
  /// [LiveIsland.start] with `requestPushToken: true`). Send them to your
  /// server to update or end it through APNs.
  Stream<String> get pushTokens => _platform.pushEvents
      .where((e) => e is LivePushTokenEvent && e.token.activityId == id)
      .map((e) => (e as LivePushTokenEvent).token.token);

  /// Changes in this activity's life: [LiveActivityState.active],
  /// [LiveActivityState.stale], [LiveActivityState.ended] and
  /// [LiveActivityState.dismissed] (the user swiped it away or it was removed).
  /// See [LiveIsland.stateChanges] for the details of what each platform reports.
  Stream<LiveActivityState> get states => _platform.pushEvents
      .where((e) => e is LivePushStateEvent && e.change.id == id)
      .map((e) => (e as LivePushStateEvent).change.state);

  /// Schedules the activity to disappear at [at].
  ///
  /// The behavior depends on the platform, because ActivityKit has no
  /// "end later" for a live activity:
  ///
  /// - **iOS:** the activity **ends now** (it leaves the island and can no
  ///   longer be updated) and the lock screen card stays with [state] until
  ///   [at]; iOS removes it at most 4 hours later.
  /// - **Android:** the notification **stays alive and can be updated**, and
  ///   the system removes it by itself at [at], even if the app is closed.
  ///
  /// If [at] has already passed, it ends immediately.
  Future<void> scheduleEnd(DateTime at, {Map<String, Object?>? state}) {
    final wait = at.difference(DateTime.now());
    if (wait <= Duration.zero) {
      return end(state: state, dismiss: LiveDismiss.immediate);
    }
    return _platform.scheduleEnd(
      id,
      secondsFromNow: wait.inMilliseconds / 1000,
      stateJson: state == null ? null : jsonEncode(LiveState.normalize(state)),
    );
  }

  /// Ends the activity. With [state] it leaves a final visible state.
  Future<void> end({
    Map<String, Object?>? state,
    LiveDismiss dismiss = LiveDismiss.byDefault,
  }) => _platform.end(
    id,
    stateJson: state == null ? null : jsonEncode(LiveState.normalize(state)),
    dismiss: dismiss,
  );
}

/// Entry point of the package.
abstract final class LiveIsland {
  static LiveIslandPlatform _platform = MethodChannelLiveIslandPlatform();
  static LiveImageReader _imageReader = defaultImageReader;
  static LiveAssetReader _assetReader = defaultAssetReader;

  /// Replaces the platform (for tests). With `null` it goes back to the real one.
  static void debugOverride({
    LiveIslandPlatform? platform,
    LiveImageReader? imageReader,
    LiveAssetReader? assetReader,
  }) {
    _platform = platform ?? MethodChannelLiveIslandPlatform();
    _imageReader = imageReader ?? defaultImageReader;
    _assetReader = assetReader ?? defaultAssetReader;
  }

  /// Can the app show activities now? On iOS it is
  /// `ActivityAuthorizationInfo.areActivitiesEnabled`.
  static Future<bool> areEnabled() => _platform.areEnabled();

  /// Asks for the notification permission (Android 13 or later). Call it
  /// before [start]; if the user refuses, [start] throws `disabled`. On iOS
  /// it does nothing.
  static Future<bool> requestPermission() => _platform.requestPermission();

  /// Opens the settings where the user allows the app to post Live
  /// Updates (Android 16 or later). Returns `false` if they do not exist.
  static Future<bool> openPromotionSettings() =>
      _platform.openPromotionSettings();

  /// The activities that are still alive, for example after reopening the app
  /// or when an action arrived with the app closed, so you can update them.
  static Future<List<LiveActivity>> activeActivities() async => [
    for (final a in await _platform.activeActivities())
      LiveActivity._(a.id, _platform, customId: a.customId),
  ];

  /// The live activity that was started with [customId], or `null` if it does
  /// not exist (it already ended or the user dismissed it). Useful after
  /// reopening the app, without storing the platform's id.
  static Future<LiveActivity?> activity(String customId) async {
    for (final a in await _platform.activeActivities()) {
      if (a.customId == customId) {
        return LiveActivity._(a.id, _platform, customId: customId);
      }
    }
    return null;
  }

  /// Ends all of the app's live activities (for example when signing out).
  /// With [dismiss] `immediate` they disappear at once.
  static Future<void> endAll({LiveDismiss dismiss = LiveDismiss.immediate}) =>
      _platform.endAll(dismiss: dismiss);

  /// Each time the user taps a button of an activity its `id` (the one from
  /// `LiveButton(id: ...)`) arrives here. Actions that happened with the app
  /// closed are delivered when you start listening.
  static Stream<String> get actions => _platform.actions;

  /// Shortcut for [actions]: calls [callback] with the id of each tapped button.
  /// Cancel the returned subscription when you no longer need it.
  static StreamSubscription<String> onAction(
    void Function(String id) callback,
  ) => _platform.actions.listen(callback);

  /// iOS push tokens: those of each activity (with `requestPushToken`) and
  /// the push-to-start one (iOS 17.2), which has no `activityId`.
  static Stream<LivePushToken> get pushTokens => _platform.pushEvents
      .where((e) => e is LivePushTokenEvent)
      .map((e) => (e as LivePushTokenEvent).token);

  /// Every change in the life of the app's activities, with the id of the
  /// activity: it started (`active`), its content went out of date (`stale`),
  /// it ended (`ended`) or it left the screen (`dismissed`).
  ///
  /// - **iOS** reports all four, also for activities started by a push or
  ///   before the app was opened (from the moment you listen).
  /// - **Android** reports `active`, `ended` and `dismissed` (the user swiped
  ///   the notification away, or it timed out); it has no `stale`.
  ///
  /// Events arrive only while someone listens; to know the current activities
  /// use [activeActivities].
  static Stream<LiveActivityStateChange> get stateChanges => _platform
      .pushEvents
      .where((e) => e is LivePushStateEvent)
      .map((e) => (e as LivePushStateEvent).change);

  /// Activities that started from a push (push-to-start on iOS; [handlePush]
  /// with `event: start` on Android).
  static Stream<LiveActivity> get startedByPush => _platform.pushEvents
      .where((e) => e is LivePushStartedEvent)
      .map(
        (e) =>
            LiveActivity._((e as LivePushStartedEvent).activityId, _platform),
      );

  /// Saves [layout] on the device under the name [name]. An activity started
  /// from a push uses that design by its name, because a push cannot carry the
  /// design. Call it again if the design changes.
  static Future<void> registerLayout(String name, LiveLayout layout) async {
    final images = await loadLayoutImages(
      layout,
      reader: _imageReader,
      androidIcons: _platform.needsAndroidIcons,
      assetReader: _assetReader,
    );
    await _platform.registerLayout(
      name: name,
      layoutJson: jsonEncode(layout.toJson()),
      images: images,
    );
  }

  /// Processes the data of an FCM message (Android) to start, update or end an
  /// activity; see `doc/push.md`. Call it from your `firebase_messaging`
  /// handler. Returns the id of the affected activity. On iOS it does nothing:
  /// APNs goes straight to ActivityKit.
  static Future<String?> handlePush(Map<String, Object?> data) =>
      _platform.handlePush(data);

  /// Starts an activity with its [layout] (which travels only once) and its
  /// initial state [state].
  ///
  /// [customId] is your app's own id (`'trip-42'`). If a live activity with
  /// that id already exists, another is not created: its state is updated and
  /// the same one is returned. It can be found afterwards with [activity].
  ///
  /// [deepLink] opens when the activity is tapped. [staleAfter] marks the
  /// content as out of date after that time. It throws [LiveIslandException]
  /// if the platform cannot (`disabled`, `not_configured`…) and [StateError]
  /// if the design has errors according to [check].
  static Future<LiveActivity> start({
    required LiveLayout layout,
    required Map<String, Object?> state,
    String? deepLink,
    Duration? staleAfter,
    double relevance = 0,
    bool requestPushToken = false,
    String? customId,
  }) async {
    if (customId != null && customId.isEmpty) {
      throw ArgumentError.value(customId, 'customId', 'Cannot be empty');
    }
    final normalized = LiveState.normalize(state);
    final report = check(layout, normalized, androidPromotable: true);
    final blocking = report.items.where(
      (c) => c.code == 'statePayload' && c.severity == LiveSeverity.bad,
    );
    if (blocking.isNotEmpty) {
      throw StateError(blocking.first.message);
    }
    final images = await loadLayoutImages(
      layout,
      reader: _imageReader,
      androidIcons: _platform.needsAndroidIcons,
      assetReader: _assetReader,
    );
    final id = await _platform.start(
      layoutJson: jsonEncode(layout.toJson()),
      stateJson: jsonEncode(normalized),
      images: images,
      deepLink: deepLink,
      staleAfter: staleAfter,
      relevance: relevance,
      requestPushToken: requestPushToken,
      customId: customId,
    );
    return LiveActivity._(id, _platform, customId: customId);
  }

  /// Validates [layout] with [state] using the same criteria as the
  /// "Validation" panel of the prototype HTML (`doc/design/live_island_prototipos.html`).
  ///
  /// [androidPromotable] must be `false` for cases Google does not promote to
  /// Live Update (ads, chats, activities the user did not start).
  static LiveReport check(
    LiveLayout layout,
    Map<String, Object?> state, {
    DateTime? now,
    bool androidPromotable = true,
  }) => checkLayout(
    layout,
    state,
    now: now,
    androidPromotable: androidPromotable,
  );
}
