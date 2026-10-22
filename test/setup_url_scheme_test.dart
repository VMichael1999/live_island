import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:live_island_kit/src/setup/android_url_scheme.dart';

const _manifest = '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application android:label="app">
        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <meta-data android:name="flutterEmbedding" android:value="2" />
    </application>
</manifest>
''';

void main() {
  group('Android: intent-filter del esquema', () {
    test('se agrega a la actividad principal', () {
      final out = addAndroidUrlScheme(_manifest, 'miapp')!;
      expect(out, contains('<data android:scheme="miapp" />'));
      expect(out, contains('android.intent.action.VIEW'));
      expect(out, contains('android.intent.category.BROWSABLE'));
      // Dentro de la actividad, antes de su cierre, y el resto queda igual.
      expect(
        out.indexOf('android:scheme="miapp"'),
        lessThan(out.indexOf('</activity>')),
      );
      expect(out, contains('<meta-data android:name="flutterEmbedding"'));
    });

    test('si el esquema ya está, no cambia nada', () {
      final once = addAndroidUrlScheme(_manifest, 'miapp')!;
      expect(addAndroidUrlScheme(once, 'miapp'), isNull);
    });

    test('otro esquema se suma al anterior', () {
      final once = addAndroidUrlScheme(_manifest, 'miapp')!;
      final twice = addAndroidUrlScheme(once, 'otra')!;
      expect(twice, contains('android:scheme="miapp"'));
      expect(twice, contains('android:scheme="otra"'));
    });

    test('sin actividad de lanzamiento no cambia nada', () {
      expect(
        addAndroidUrlScheme('<manifest><application/></manifest>', 'miapp'),
        isNull,
      );
    });
  });

  group('iOS: CFBundleURLTypes del Info.plist', () {
    String correr(String ruby) {
      final r = Process.runSync('ruby', [
        '-e',
        "require './bin/url_scheme'; $ruby",
      ]);
      expect(r.exitCode, 0, reason: '${r.stderr}');
      return (r.stdout as String).trim();
    }

    test('agrega el esquema una sola vez', () {
      expect(
        correr(
          "i = {}; a = add_url_scheme!(i, 'miapp'); b = add_url_scheme!(i, 'miapp'); "
          'puts [a, b, i["CFBundleURLTypes"].length, i["CFBundleURLTypes"][0]["CFBundleURLSchemes"].inspect].join(",")',
        ),
        'true,false,1,["miapp"]',
      );
    });

    test('respeta los esquemas que ya había', () {
      expect(
        correr(
          "i = {'CFBundleURLTypes' => [{'CFBundleURLSchemes' => ['viejo']}]}; "
          "add_url_scheme!(i, 'nuevo'); puts i['CFBundleURLTypes'].map { |t| t['CFBundleURLSchemes'][0] }.join(',')",
        ),
        'viejo,nuevo',
      );
    });
  });
}
