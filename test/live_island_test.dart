import 'package:flutter_test/flutter_test.dart';
import 'package:live_island/live_island.dart';
import 'package:live_island/live_island_platform_interface.dart';
import 'package:live_island/live_island_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockLiveIslandPlatform
    with MockPlatformInterfaceMixin
    implements LiveIslandPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final LiveIslandPlatform initialPlatform = LiveIslandPlatform.instance;

  test('$MethodChannelLiveIsland is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelLiveIsland>());
  });

  test('getPlatformVersion', () async {
    LiveIsland liveIslandPlugin = LiveIsland();
    MockLiveIslandPlatform fakePlatform = MockLiveIslandPlatform();
    LiveIslandPlatform.instance = fakePlatform;

    expect(await liveIslandPlugin.getPlatformVersion(), '42');
  });
}
