#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint live_island.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'live_island'
  s.version          = '0.1.0'
  s.summary          = 'Live Activities (iOS) y Live Updates (Android) con una sola API en Dart, sin Swift ni Kotlin.'
  s.description      = <<-DESC
Live Activities (iOS) y Live Updates (Android) con una sola API en Dart. Isla dinámica,
pantalla de bloqueo, 15 presets y vista previa; sin escribir Swift ni Kotlin.
                       DESC
  s.homepage         = 'https://github.com/VMichael1999/live_island'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'VMichael1999' => 'https://github.com/VMichael1999' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*', 'LiveIslandExtension/Shared/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'
  s.weak_frameworks = 'ActivityKit', 'AppIntents'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # Manifiesto de privacidad: el plugin lee el UserDefaults del App Group
  # (cola de acciones de los botones). Motivo 1C8F.1.
  s.resource_bundles = {'live_island_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
