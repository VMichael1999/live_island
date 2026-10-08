import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'live_island_platform_interface.dart';

/// An implementation of [LiveIslandPlatform] that uses method channels.
class MethodChannelLiveIsland extends LiveIslandPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('live_island');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
