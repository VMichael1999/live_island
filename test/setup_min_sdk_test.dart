import 'package:flutter_test/flutter_test.dart';
import 'package:live_island_kit/src/setup/android_min_sdk.dart';

void main() {
  test(
    'Kotlin DSL: flutter.minSdkVersion se sube a 26 sin bajar el de Flutter',
    () {
      const src =
          '    defaultConfig {\n        minSdk = flutter.minSdkVersion\n    }\n';
      expect(
        raiseAndroidMinSdk(src),
        '    defaultConfig {\n        minSdk = maxOf(flutter.minSdkVersion, 26)\n    }\n',
      );
    },
  );

  test('Groovy: minSdkVersion flutter.minSdkVersion usa Math.max', () {
    expect(
      raiseAndroidMinSdk('        minSdkVersion flutter.minSdkVersion\n'),
      '        minSdkVersion Math.max(flutter.minSdkVersion, 26)\n',
    );
  });

  test('un número menor se sube a 26', () {
    expect(
      raiseAndroidMinSdk('        minSdk = 21\n'),
      '        minSdk = 26\n',
    );
    expect(
      raiseAndroidMinSdk('        minSdkVersion 23\n'),
      '        minSdkVersion 26\n',
    );
  });

  test('un número igual o mayor no se toca', () {
    expect(raiseAndroidMinSdk('        minSdk = 26\n'), isNull);
    expect(raiseAndroidMinSdk('        minSdk = 29\n'), isNull);
  });

  test('si ya está en maxOf o no hay minSdk, no cambia nada', () {
    expect(
      raiseAndroidMinSdk('        minSdk = maxOf(flutter.minSdkVersion, 26)\n'),
      isNull,
    );
    expect(raiseAndroidMinSdk('android { }\n'), isNull);
  });

  test('volver a correrlo no cambia nada', () {
    final once =
        raiseAndroidMinSdk('        minSdk = flutter.minSdkVersion\n')!;
    expect(raiseAndroidMinSdk(once), isNull);
  });
}
