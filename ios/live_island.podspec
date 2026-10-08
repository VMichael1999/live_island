#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint live_island.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'live_island'
  s.version          = '0.0.1'
  s.summary          = 'Live Activities (iOS) y Live Updates (Android) con una sola API en Dart, 100 % editable.'
  s.description      = <<-DESC
Live Activities (iOS) y Live Updates (Android) con una sola API en Dart, 100 % editable.
                       DESC
  s.homepage         = 'https://github.com/VMichael1999/live_island'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'VMichael1999' => 'https://github.com/VMichael1999' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*', 'LiveIslandExtension/Shared/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'
  s.weak_frameworks = 'ActivityKit'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'live_island_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
