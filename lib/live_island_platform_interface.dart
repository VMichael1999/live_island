import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'live_island_method_channel.dart';

abstract class LiveIslandPlatform extends PlatformInterface {
  /// Constructs a LiveIslandPlatform.
  LiveIslandPlatform() : super(token: _token);

  static final Object _token = Object();

  static LiveIslandPlatform _instance = MethodChannelLiveIsland();

  /// The default instance of [LiveIslandPlatform] to use.
  ///
  /// Defaults to [MethodChannelLiveIsland].
  static LiveIslandPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [LiveIslandPlatform] when
  /// they register themselves.
  static set instance(LiveIslandPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
