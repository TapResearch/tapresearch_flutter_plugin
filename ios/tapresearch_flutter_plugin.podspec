#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint tapresearch_flutter_plugin.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'tapresearch_flutter_plugin'
  s.version          = '3.8.0--beta01'
  s.summary          = 'In-app Monetization SDK (iOS & Android) via Surveys by TapResearch'
  s.description      = <<-DESC
In-app Monetization SDK via Surveys by TapResearch (iOS & Android)
                       DESC
  s.homepage         = 'https://www.tapresearch.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'TapResearch' => 'support@tapresearch.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'TapResearch', '3.8.0--beta03'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  s.resource_bundles = {
    'tapresearch_flutter_plugin_privacy' => ['Resources/PrivacyInfo.xcprivacy']
  }
end
