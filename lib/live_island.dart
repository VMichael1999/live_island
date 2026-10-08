
import 'live_island_platform_interface.dart';

class LiveIsland {
  Future<String?> getPlatformVersion() {
    return LiveIslandPlatform.instance.getPlatformVersion();
  }
}
