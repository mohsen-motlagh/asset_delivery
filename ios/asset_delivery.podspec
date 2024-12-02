#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint asset_delivery.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'asset_delivery'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter plugin project.'
  s.description      = <<-DESC
This plugin helps deliver assets dynamically for iOS and Android..
                       DESC
  s.homepage         = 'https://github.com/mohsen-motlagh/asset_delivery/tree/main'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Mohsen Motlagh' => 'mohsenmotlagh@outlook.com' }
  s.source           = { :path => 'https://github.com/mohsen-motlagh/asset_delivery/tree/main/ios' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'asset_delivery_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
