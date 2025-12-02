#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
#
Pod::Spec.new do |s|
  s.name             = 'kgiton_ble_sdk'
  s.version          = '1.0.0'
  s.summary          = 'Minimal BLE SDK for KGiTON Scale'
  s.description      = <<-DESC
Open source BLE SDK for KGiTON Scale devices.
                       DESC
  s.homepage         = 'https://github.com/kuldii/flutter-ble-sdk'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'PT KGiTON' => 'support@kgiton.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
